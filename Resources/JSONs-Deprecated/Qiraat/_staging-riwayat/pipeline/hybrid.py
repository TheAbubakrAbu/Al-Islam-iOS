#!/usr/bin/env python3
"""Template-guided hybrid decoding.

Per surah: concatenate the volume's ayah glyph streams (remembering marker cut points),
align the whole token sequence against the TEMPLATE text (the app's closest sibling
riwayah) with the EM emission model, then cut the aligned template at the marker
positions. Where the alignment is confident the template text is emitted VERBATIM -
inheriting the app's exact orthographic conventions. Contiguous low-confidence spans
(real riwayah differences, farsh) are re-decoded from emissions + char-LM and logged
to a deviations report for human review.

  eval   : warsh + qaloon volumes decoded via the HAFS template, scored against the
           app's own Warsh/Qaloon texts (the exact cross-riwayah scenario the targets face)
  apply  : decode the 12 targets → data/<slug>.text.json + data/<slug>.deviations.json
"""
import json, sys, math, collections, pathlib, re, difflib

BASE = pathlib.Path(__file__).resolve().parent
DATA = BASE / "data"
APP = pathlib.Path("/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS")
sys.path.insert(0, str(BASE))
from extract import overlay, BRIDGES, strip_header_and_basmalah, skeleton
from decode import LM, load_emissions, decode_ayah, hafs_text

TEMPLATES = {
    # target slug → (template source: "hafs" | overlay name)
    "khalaf": "hafs", "khallad": "hafs", "abuharith": "hafs", "durikisai": "hafs",
    "ishaq": "hafs", "idris": "hafs",
    "hisham": "hafs", "ibndhakwan": "hafs",          # Dimashqi: surah-level flex
    "ibnwardan": "QiraahQaloon", "ibnjammaz": "QiraahQaloon",   # Madani-first ≈ Madani-last
    "ruways": "QiraahDuri", "rawh": "QiraahDuri",    # Basri ≈ the app's Duri counts
    # bridge-eval entries
    "warsh": "hafs", "qaloon": "hafs",
}

def template_texts(name):
    if name == "hafs":
        return {sid: [t for _, t in ayahs] for sid, ayahs in hafs_text().items()}
    ov = overlay(name)
    return {sid: [t for _, t in ayahs] for sid, ayahs in ov.items()}

def keys_of(glyphs):
    return [("sp| " if f == "sp" else f"{f}|{c}") for f, c in glyphs]

FAMILY = {
    "khalaf": "kufi", "khallad": "kufi", "abuharith": "kufi", "durikisai": "kufi",
    "ishaq": "kufi", "idris": "kufi", "hisham": "kufi", "ibndhakwan": "kufi",
    "ibnwardan": "madani", "ibnjammaz": "madani",
    "ruways": "basri", "rawh": "basri",
    "shubah": "kufi", "qaloon": "madani", "warsh": "madani",
    "duriabiamr": "basri", "susi": "basri", "qunbul": "makki",
}
FALLBACK_ORDER = ["kufi", "madani", "basri", "makki"]

def load_family_counts(fam):
    merged = {}
    for other in reversed([f for f in FALLBACK_ORDER if f != fam]):
        pth = DATA / f"glyphcounts-{other}.json"
        if pth.exists():
            for k, v in json.loads(pth.read_text()).items():
                merged[k] = v          # fallback keys (own family will overwrite)
    own = DATA / f"glyphcounts-{fam}.json"
    if own.exists():
        for k, v in json.loads(own.read_text()).items():
            merged[k] = v              # own-family emissions always win per key
    return merged

class Emissions:
    def __init__(self, fam=None):
        if fam:
            counts = load_family_counts(fam)
        else:
            counts = json.loads((DATA / "glyphcounts.json").read_text())
        self.p = {}
        for k, dist in counts.items():
            tot = sum(dist.values())
            self.p[k] = {e: math.log(n / (tot + 2)) for e, n in dist.items()}
    def logp(self, key, e):
        d = self.p.get(key)
        if d is not None:
            v = d.get(e)
            if v is not None:
                return v
        if key == "sp| ":
            return math.log(0.8) if e == " " else (math.log(0.15) if e == "" else -16.0)
        # unseen key: mild length prior so alignment can still pass through
        L = len(e)
        return (-7.5, -6.2, -8.5, -10.5, -12.5)[L] if L <= 4 else -13.5 - L

def align_surah(keys, Y, band):
    """Monotonic DP: token i emits 0..10 chars of Y. Returns per-token (start, end,
    logp) into Y, or None."""
    NEG = -1e18
    m, n = len(keys), len(Y)
    EM = ALIGN_EM
    prev = [NEG] * (n + 1)
    prev[0] = 0.0
    back = [None] * (m + 1)
    backrows = []
    ratio = n / max(m, 1)
    for i in range(1, m + 1):
        curr = [NEG] * (n + 1)
        row = [0] * (n + 1)
        key = keys[i - 1]
        center = ratio * i
        jlo = max(0, int(center) - band)
        jhi = min(n, int(center) + band)
        for j in range(jlo, jhi + 1):
            best, bl = NEG, 0
            maxL = min(10, j)
            for L in range(0, maxL + 1):
                p = prev[j - L]
                if p <= NEG / 2: continue
                s = p + EM.logp(key, Y[j - L:j])
                if s > best:
                    best, bl = s, L
            curr[j] = best
            row[j] = bl
        prev = curr
        backrows.append(row)
    if prev[n] <= NEG / 2:
        return None
    spans = [None] * m
    j = n
    for i in range(m, 0, -1):
        L = backrows[i - 1][j]
        spans[i - 1] = (j - L, j)
        j -= L
    return spans

ALIGN_EM = None
_LM = None

def hybrid_surah(segments, template_ayahs, band=60, conf=-4.5):
    """segments: list of glyph seqs (one per volume ayah). Returns (texts, deviations).
    Template gets joined; alignment spans map tokens→template; marker cut points give
    per-segment template slices. Low-confidence token runs are re-decoded via beam."""
    global ALIGN_EM, _LM
    keys = []
    cuts = [0]
    for seg in segments:
        keys.extend(keys_of(seg))
        cuts.append(len(keys))
    Y = " ".join(" ".join(t.split()) for t in template_ayahs)
    spans = align_surah(keys, Y, band)
    if spans is None:
        return None, [{"reason": "align-failed"}]
    # per-token confidence
    confs = [ALIGN_EM.logp(keys[i], Y[spans[i][0]:spans[i][1]]) for i in range(len(keys))]
    texts, devs = [], []
    for si in range(len(segments)):
        a, b = cuts[si], cuts[si + 1]
        if a == b:
            texts.append(""); continue
        lo = spans[a][0]
        hi = spans[b - 1][1]
        # low-confidence runs inside [a,b)
        out = []
        i = a
        while i < b:
            if confs[i] >= conf or keys[i] == "sp| ":
                out.append(Y[spans[i][0]:spans[i][1]])
                i += 1
            else:
                j = i
                while j < b and (confs[j] < conf and keys[j] != "sp| "):
                    j += 1
                seg_glyphs = []
                for t in range(i, j):
                    k = keys[t]
                    seg_glyphs.append(["sp", " "] if k == "sp| " else k.split("|", 1))
                rep = decode_ayah(seg_glyphs, DEC_EM, _LM)
                tmpl_bit = Y[spans[i][0]:spans[j - 1][1]]
                out.append(rep)
                devs.append({"ayah_index": si + 1, "template": tmpl_bit, "decoded": rep})
                i = j
        t = re.sub(r"\s+", " ", "".join(out)).strip()
        texts.append(t)
    return texts, devs

DEC_EM = None

def dec_em_from(align_em):
    em = {}
    for k, dist in align_em.p.items():
        cands = sorted(dist.items(), key=lambda x: -x[1])[:5]
        em[k] = [(e, lp) for e, lp in cands]
    return em

def run(slugs, mode, template_override=None):
    global ALIGN_EM, _LM, DEC_EM
    _LM = LM()
    for slug in slugs:
        fam = FAMILY.get(slug)
        ALIGN_EM = Emissions(fam)
        DEC_EM = dec_em_from(ALIGN_EM)
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        tmpl_name = template_override or TEMPLATES[slug]
        T = template_texts(tmpl_name)
        out = {}
        all_devs = {}
        for sid in range(1, 115):
            segments = seg["data"][sid - 1]
            texts, devs = hybrid_surah(segments, T[sid])
            if texts is None:
                print(f"{slug} s{sid}: ALIGN FAILED"); texts = [""] * len(segments)
            ayahs = []
            for aid, t in enumerate(texts, 1):
                if aid == 1:
                    if sid == 9:
                        t = strip_header_and_basmalah(t, tawbah=True)
                    elif sid == 1:
                        t = strip_header_and_basmalah(t, keep_basmalah=True)
                        if len(t.split()) > 5:
                            t = strip_header_and_basmalah(t, keep_basmalah=False)
                    else:
                        t = strip_header_and_basmalah(t, keep_basmalah=False)
                ayahs.append({"id": aid, "text": t})
            out[str(sid)] = ayahs
            if devs: all_devs[str(sid)] = devs
        if mode == "apply":
            (DATA / f"{slug}.text.json").write_text(json.dumps(out, ensure_ascii=False))
            (DATA / f"{slug}.deviations.json").write_text(json.dumps(all_devs, ensure_ascii=False, indent=1))
            ndev = sum(len(v) for v in all_devs.values())
            print(f"{slug}: decoded via template {tmpl_name}; deviation spans: {ndev}")
        else:
            truth = overlay(BRIDGES[slug])
            ok = diff = 0
            chars_ok = chars_tot = 0
            shown = 0
            for sid in range(1, 115):
                tv = truth[sid]
                ov_texts = [t for _, t in tv]
                got_ayahs = [a["text"] for a in out[str(sid)]]
                if len(got_ayahs) != len(ov_texts):
                    continue
                for aid, (g, e) in enumerate(zip(got_ayahs, ov_texts), 1):
                    if aid == 1 and sid != 1: continue
                    if g == e: ok += 1
                    else:
                        diff += 1
                        if shown < 6:
                            shown += 1
                            print(f"  ≠ {slug} {sid}:{aid}\n    got {g[:100]!r}\n    exp {e[:100]!r}")
                    sm = difflib.SequenceMatcher(None, g, e)
                    chars_ok += sum(bl.size for bl in sm.get_matching_blocks())
                    chars_tot += max(len(g), len(e))
            ndev = sum(len(v) for v in all_devs.values())
            print(f"{slug} (via {tmpl_name} template): exact {ok}/{ok+diff} ({ok/max(ok+diff,1):.2%})  "
                  f"char-acc {chars_ok/max(chars_tot,1):.3%}  deviations={ndev}")

if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("mode")
    ap.add_argument("slugs", nargs="+")
    ap.add_argument("--template", default=None)
    a = ap.parse_args()
    run(a.slugs, a.mode, template_override=a.template)
