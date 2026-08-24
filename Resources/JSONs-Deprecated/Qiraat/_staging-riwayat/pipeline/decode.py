#!/usr/bin/env python3
"""LM-guided beam decoding of glyph streams into text.

The EM's per-key emission DISTRIBUTIONS (glyphcounts.json) stay ambiguous on purpose
(one alef glyph serves both ا and ٱ; a fused ya+meem cluster offers both م and يم).
A character 5-gram LM trained on the app's OWN 8 riwayah texts picks the right emission
per instance - the same disambiguation the EM's DP did during learning, minus the need
for ground truth.

  eval <bridge...>   decode bridge volumes and score against the app's overlay texts
  apply <slug...>    decode target volumes → data/<slug>.text.json
"""
import json, sys, math, collections, pathlib, re

BASE = pathlib.Path(__file__).resolve().parent
DATA = BASE / "data"
APP = pathlib.Path("/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS")

sys.path.insert(0, str(BASE))
from extract import (BRIDGES, overlay, strip_header_and_basmalah,
                     is_basmalah_start, skeleton, is_surah_start)

def hafs_text():
    q = json.loads((APP / "Resources/JSONs-Deprecated/Quran.json").read_text())
    return {int(s["id"]): [(int(a["id"]), a["textArabic"]) for a in s["ayahs"]] for s in q}

# ------------------------------------------------------------------ LM

N = 5
def build_lm():
    cachef = DATA / "charlm.json"
    if cachef.exists():
        d = json.loads(cachef.read_text())
        return ({tuple(k.split("")): v for k, v in d["g"].items()}, d["v"])
    texts = []
    for sid, ayahs in hafs_text().items():
        for _, t in ayahs: texts.append(t)
    for name in ["QiraahShubah", "QiraahWarsh", "QiraahQaloon", "QiraahDuri",
                 "QiraahSusi", "QiraahBuzzi", "QiraahQunbul"]:
        d = json.loads((APP / f"Resources/JSONs-Deprecated/Qiraat/{name}.json").read_text())
        for v in d.values():
            for a in v: texts.append(a["text"])
    grams = collections.defaultdict(collections.Counter)
    vocab = set()
    for t in texts:
        s = "^" + t + "$"
        vocab.update(s)
        for i in range(1, len(s)):
            for order in (5, 3, 2):
                ctx = s[max(0, i - order + 1):i]
                grams[ctx][s[i]] += 1
    out_g = {}
    for ctx, ctr in grams.items():
        tot = sum(ctr.values())
        out_g["".join(ctx)] = {ch: math.log(n / tot) for ch, n in ctr.items() if n >= 1}
    cachef.write_text(json.dumps({"g": out_g, "v": len(vocab)}, ensure_ascii=False))
    return ({tuple(k.split("")): v for k, v in out_g.items()}, len(vocab))

class LM:
    def __init__(self):
        self.g, self.V = build_lm()
        # convert back: keys are char tuples of the context string
        self.tbl = {}
        for ctx, dist in self.g.items():
            self.tbl["".join(ctx)] = dist
    def logp(self, hist, ch):
        for order in (4, 2, 1):
            ctx = hist[-order:] if order <= len(hist) else None
            if ctx is not None:
                d = self.tbl.get(ctx)
                if d and ch in d:
                    return d[ch]
        return -11.0

# ------------------------------------------------------------------ candidates

def load_emissions():
    counts = json.loads((DATA / "glyphcounts.json").read_text())
    em = {}
    for k, dist in counts.items():
        tot = sum(dist.values())
        cands = sorted(dist.items(), key=lambda x: -x[1])[:5]
        em[k] = [(e, math.log(n / tot)) for e, n in cands if n / tot > 0.02 or n >= 2]
    return em

def component_candidates(key, em):
    """Unseen cluster key: synthesize candidates from member components (letters first,
    then marks), letting the LM choose between orderings."""
    if not key.startswith("CL|"):
        return None
    members = key[3:].split("||")
    parts = []
    for m in members:
        k1 = "CL|" + m
        if k1 in em and em[k1]:
            parts.append([e for e, _ in em[k1][:2]])
        else:
            return None
    # cartesian, capped
    outs = [""]
    for choices in parts:
        outs = [o + c for o in outs for c in choices][:12]
    seen = []
    import unicodedata
    for o in outs:
        letters = [c for c in o if not unicodedata.combining(c)]
        marks = [c for c in o if unicodedata.combining(c)]
        seen.append("".join(letters) + "".join(marks))
        seen.append(o)
    uniq = list(dict.fromkeys(seen))[:8]
    return [(e, math.log(0.1)) for e in uniq]

def decode_ayah(glyphs, em, lm, lam=1.0, beam=10, missing=None):
    keys = ["sp| " if f == "sp" else f"{f}|{c}" for f, c in glyphs]
    beams = [("", 0.0)]
    for i, k in enumerate(keys):
        cands = em.get(k)
        if cands is None:
            cands = component_candidates(k, em)
        if k == "sp| ":
            cands = [(" ", 0.0)]
        if not cands:
            if missing is not None: missing[k] += 1
            cands = [("�", -2.0)]
        nxt = {}
        for text, score in beams:
            for e, elp in cands:
                s = score + lam * elp
                t = text
                for ch in e:
                    if ch == " " and (not t or t.endswith(" ")):
                        continue
                    s += lm.logp(t[-4:], ch)
                    t = t + ch
                cur = nxt.get(t)
                if cur is None or s > cur:
                    nxt[t] = s
        beams = sorted(nxt.items(), key=lambda x: -x[1])[:beam]
    best = beams[0][0]
    return re.sub(r"\s+", " ", best).strip()

# ------------------------------------------------------------------ drivers

def eval_bridges(slugs):
    em = load_emissions()
    lm = LM()
    for slug in slugs:
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        ov = overlay(BRIDGES[slug])
        ok = diff = 0
        chars_ok = chars_tot = 0
        shown = 0
        for sid in range(1, 115):
            vol = seg["data"][sid - 1]
            app_ayahs = ov[sid]
            if len(vol) != len(app_ayahs): continue
            for k, (glyphs, (aid, text)) in enumerate(zip(vol, app_ayahs)):
                if k == 0: continue
                got = decode_ayah(glyphs, em, lm)
                if got == text: ok += 1
                else:
                    diff += 1
                    if shown < 8:
                        shown += 1
                        print(f"  ≠ {slug} {sid}:{aid}\n    got {got[:100]!r}\n    exp {text[:100]!r}")
                import difflib
                sm = difflib.SequenceMatcher(None, got, text)
                chars_ok += sum(b.size for b in sm.get_matching_blocks())
                chars_tot += max(len(got), len(text))
        print(f"{slug}: exact {ok}/{ok+diff} ({ok/max(ok+diff,1):.2%})  char-acc {chars_ok/max(chars_tot,1):.3%}")

def apply_targets(slugs):
    lm = LM()
    from hybrid import FAMILY, Emissions, dec_em_from
    for slug in slugs:
        fam = FAMILY.get(slug)
        em = dec_em_from(Emissions(fam)) if fam else load_emissions()
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        missing = collections.Counter()
        out = {}
        for sid, surah in enumerate(seg["data"], 1):
            ayahs = []
            for aid, glyphs in enumerate(surah, 1):
                t = decode_ayah(glyphs, em, lm, missing=missing)
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
        (DATA / f"{slug}.text.json").write_text(json.dumps(out, ensure_ascii=False))
        print(f"{slug}: decoded; unmapped keys={len(missing)} occurrences={sum(missing.values())}")
        for k, n in missing.most_common(12):
            print(f"   MISSING {k[:80]!r} ×{n}")

if __name__ == "__main__":
    if sys.argv[1] == "eval":
        eval_bridges(sys.argv[2:])
    elif sys.argv[1] == "apply":
        apply_targets(sys.argv[2:])
