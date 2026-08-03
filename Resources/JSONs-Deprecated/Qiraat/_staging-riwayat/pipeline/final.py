#!/usr/bin/env python3
"""Deterministic rendering + verification loop. No LM, no beams - every character
must come from (a) a high-purity glyph emission, (b) a deterministic rule, or be a
visible ✗ that fails validation.

  rules      : verify the wasla rule + mark-order stats against app texts
  detmap     : build data/detmap-<family>.json from glyphcounts-<family>.json
  roundtrip <bridge...> : render bridge volumes deterministically, diff vs app texts,
                          print a CLASS HISTOGRAM of every difference
"""
import json, sys, math, collections, pathlib, re, unicodedata, difflib

BASE = pathlib.Path(__file__).resolve().parent
DATA = BASE / "data"
APP = pathlib.Path("/Users/theabubakrabu/Library/Mobile Documents/com~apple~CloudDocs/Projects/(1) iOS/Al-Islam-iOS")
sys.path.insert(0, str(BASE))
from extract import overlay, BRIDGES
from hybrid import FAMILY, template_texts

def app_texts_all():
    out = []
    from decode import hafs_text
    for sid, ayahs in hafs_text().items():
        out += [t for _, t in ayahs]
    for name in ["QiraahShubah", "QiraahWarsh", "QiraahQaloon", "QiraahDuri",
                 "QiraahSusi", "QiraahBuzzi", "QiraahQunbul"]:
        d = json.loads((APP / f"Resources/JSONs-Deprecated/Qiraat/{name}.json").read_text())
        for v in d.values():
            out += [a["text"] for a in v]
    return out

# ---------------------------------------------------------------- normalization

def normalize_marks(text):
    """Canonical combining-mark order per base: sort each base's mark run by
    (combining class, codepoint). Deterministic; applied to BOTH app text (during
    learning/diffing) and our renders, so stack-order noise can never be a diff."""
    out = []
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        out.append(ch)
        j = i + 1
        marks = []
        while j < n and unicodedata.combining(text[j]):
            marks.append(text[j]); j += 1
        if marks:
            marks.sort(key=lambda c: (unicodedata.combining(c), ord(c)))
            out += marks
        i = j
    return "".join(out)

WASLA = "ٱ"

def apply_wasla_rule(text):
    """Word-initial bare alef → ٱ (the app's Uthmani convention has no word-initial
    plain ا). Word-internal ٱ after وَ/فَ/بِ/لِ/كَ prefixes is already word-initial at
    the ORTHOGRAPHIC word level - the rule is applied per whitespace token to its
    first LETTER only."""
    words = text.split(" ")
    out = []
    for w in words:
        if w.startswith("ا"):
            w = WASLA + w[1:]
        out.append(w)
    return " ".join(out)

def verify_rules():
    texts = app_texts_all()
    initial_plain = initial_wasla = internal_wasla = internal_plain = 0
    for t in texts:
        for w in t.split():
            if not w: continue
            if w[0] == "ا": initial_plain += 1
            if w[0] == WASLA: initial_wasla += 1
            internal_wasla += w[1:].count(WASLA)
            internal_plain += w[1:].count("ا")
    print(f"word-initial plain ا: {initial_plain}   word-initial ٱ: {initial_wasla}")
    print(f"internal ٱ: {internal_wasla}   internal ا: {internal_plain}")
    # mark-order check: how often does app text deviate from our canonical order?
    dev = tot = 0
    for t in texts[:20000]:
        nt = normalize_marks(t)
        tot += 1
        if nt != t: dev += 1
    print(f"ayahs whose app text ≠ canonical mark order: {dev}/{tot}")

# ---------------------------------------------------------------- deterministic map

def build_detmap(fam, bridges_counts=("kufi", "madani", "basri", "makki")):
    own = json.loads((DATA / f"glyphcounts-{fam}.json").read_text())
    merged = {}
    for other in reversed([f for f in bridges_counts if f != fam]):
        p = DATA / f"glyphcounts-{other}.json"
        if p.exists():
            for k, v in json.loads(p.read_text()).items():
                merged.setdefault(k, v)
    for k, v in own.items():
        merged[k] = v
    detmap, amb = {}, {}
    for k, dist in merged.items():
        items = sorted(dist.items(), key=lambda x: -x[1])
        tot = sum(dist.values())
        e, n = items[0]
        if e in ("", " ") and n / tot < 0.90:
            nonnull = [(e2, n2) for e2, n2 in items if e2 not in ("", " ")]
            if not nonnull:
                detmap[k] = ""
                continue
            e, n = nonnull[0]
            nn_tot = sum(x for _, x in nonnull)
            if n / nn_tot >= 0.55 or nn_tot <= 3:
                detmap[k] = e
            else:
                amb[k] = items[:5]
            continue
        purity = n / tot
        if purity >= 0.55 or tot <= 3:
            detmap[k] = e
        elif len(items) >= 2 and items[1][0] == e * 2:
            detmap[k] = e
        else:
            amb[k] = items[:5]
    manual_p = DATA / "manualmap.json"
    if manual_p.exists():
        detmap.update(json.loads(manual_p.read_text()))
    drop_p = DATA / "droplist.json"
    drops = set(json.loads(drop_p.read_text())) if drop_p.exists() else set()
    for k in drops:
        detmap[k] = ""
    (DATA / f"detmap-{fam}.json").write_text(json.dumps(detmap, ensure_ascii=False, sort_keys=True))
    (DATA / f"detamb-{fam}.json").write_text(json.dumps(amb, ensure_ascii=False, indent=1, sort_keys=True))
    print(f"{fam}: detmap {len(detmap)} keys, ambiguous {len(amb)}")
    return detmap

def collapse_doubled_marks(text):
    """No app text ever repeats the identical combining mark consecutively - doubled
    marks are stroke+fill double-draw artifacts."""
    out = []
    for ch in text:
        if out and ch == out[-1] and unicodedata.combining(ch):
            continue
        out.append(ch)
    return "".join(out)

def attach_orphan_marks(text):
    """A whitespace-separated token that is ONLY combining marks (a pause sign whose
    space slipped in) belongs to the previous word."""
    words = text.split(" ")
    out = []
    for w in words:
        if w and all(unicodedata.combining(c) for c in w) and out:
            out[-1] += w
        else:
            out.append(w)
    return " ".join(out)

def render_det(glyphs, detmap, missing=None, family="kufi", ctx=None):
    keys = [("sp| " if f == "sp" else f"{f}|{c}") for f, c in glyphs]
    out = []
    for i, k in enumerate(keys):
        if k == "sp| ":
            out.append(("sp", " ")); continue
        v = None
        if ctx is not None and k in ctx:
            r = ctx[k]
            pv = keys[i - 1] if i > 0 else "^"
            nx = keys[i + 1] if i + 1 < len(keys) else "$"
            v = r.get(f"b:{pv}|{nx}")
            if v is None: v = r.get(f"p:{pv}")
            if v is None: v = r.get(f"n:{nx}")
            if v is None: v = r.get("*")
        if v is None:
            v = detmap.get(k)
        if v is None and k.startswith(("CL|TraditionalArabic", "CL|DecoType")):
            v = ""    # aux layer with zero aligned evidence = margin furniture
        if v and k.startswith(("CL|TraditionalArabic", "CL|DecoType")) and all(c in "َُِٗany" or c in "ًٌٍَُِ" for c in v):
            v = ""    # aux layers never draw tashkeel; those votes are alignment slop
        if v is None:
            if missing is not None: missing[k] += 1
            out.append((k, "✗"))
        else:
            out.append((k, v))
    # SAME-key consecutive identical mark = stroke+fill double-draw → drop the copy.
    # DIFFERENT keys emitting the same single vowel adjacently = kasra+shadda pair
    # whose shadda glyph was EM-confused with the vowel → the second IS the shadda.
    VOWELS = {"ِ", "َ", "ُ"}
    fixed = []
    for k, v in out:
        if fixed:
            pk, pv2 = fixed[-1]
            if v == pv2 and v and unicodedata.combining(v[0]) and len(v) == 1:
                if k == pk:
                    continue                    # double-draw artifact
                if v in VOWELS:
                    fixed[-1] = (pk, "ّ" + pv2)  # shadda glyph + vowel; app orders shadda FIRST
                    continue
        fixed.append((k, v))
    t = re.sub(r"\s+", " ", "".join(v for _, v in fixed)).strip()
    for dg in ("ٱا", "اٱ", "ٱٱ"):
        t = t.replace(dg, "ٱ")       # wasla-sign glyph + bare-alef glyph = ONE ٱ
    # الله/لله ligature: the lam strokes are VECTOR ART (not text glyphs); only the
    # alef/heh print as text. 'ٱَ' and a standalone 'هِ' word cannot otherwise occur.
    ALLAH_LL = "\u0644\u0644\u0651\u064e"          # ل ل ّ َ  (shadda before vowel)
    for pat in ("\u0671\u064e", "\u0627\u064e"):     # ٱَ / اَ - impossible except in الله
        t = t.replace(pat, "\u0671" + ALLAH_LL)         # always-wasl ٱللَّ
    for pat in ("\u0671\u06e1", "\u0627\u06e1"):     # ٱۡ / اۡ - sukun of the INVISIBLE lam
        t = t.replace(pat, "\u0671\u0644\u06e1")      # ٱلۡ
    LILLAH_CORE = "\u0644\u0650" + ALLAH_LL + "\u0647"   # لِلَّه
    words = t.split(" ")
    LILLAH = {"هِ": LILLAH_CORE + "\u0650",
              "وَهِ": "\u0648\u064e" + LILLAH_CORE + "\u0650",
              "فَهِ": "\u0641\u064e" + LILLAH_CORE + "\u0650",
              "هُ": LILLAH_CORE + "\u064f",
              "هَ": LILLAH_CORE + "\u064e"}
    t = " ".join(LILLAH.get(w, w) for w in words)
    t = t.replace("\u0644\u0650\u0644\u0644", "\u0644\u0650\u0644")  # لِلل → لِل
    t = t.replace("\u0657\u0627\u0627", "\u0657\u0627").replace("\u064b\u0627\u0627", "\u064b\u0627").replace("\u0648\u0627\u0627", "\u0648\u0627")
    t = collapse_doubled_marks(t)
    t = attach_orphan_marks(t)
    if family == "kufi":
        t = apply_wasla_rule(t)   # kufi convention: word-initial bare alef is ٱ
    return t


# ---------------------------------------------------------------- context pass

def ctxpass(fam, bridge_slugs):
    """Deterministic neighbor-conditioned rules for keys the flat map can't decide
    (coupled pairs like kasra/shadda, ya-skeleton/dots, ligature layers). Learned by
    re-aligning bridge volumes against their app texts with the current emissions,
    then keeping only high-purity (prev,key,next)-conditioned emissions."""
    import math
    from extract import overlay, BRIDGES
    counts = json.loads((DATA / f"glyphcounts-{fam}.json").read_text())
    detmap = build_detmap(fam)
    # target keys: anything ambiguous, unmapped-in-render, or from the aux layers
    targets = set()
    amb = json.loads((DATA / f"detamb-{fam}.json").read_text())
    targets |= set(amb.keys())
    for k in counts:
        if k.startswith(("CL|TraditionalArabic", "CL|DecoType", "CL|Hamd")):
            targets.add(k)
    # low-purity flat keys too
    for k, dist in counts.items():
        items = sorted(dist.items(), key=lambda x: -x[1])
        tot = sum(dist.values())
        if len(items) >= 2 and items[0][1] / tot < 0.90:
            targets.add(k)

    class _EM:
        def __init__(self, c):
            self.p = {}
            for k, dist in c.items():
                tot = sum(dist.values())
                self.p[k] = {e: math.log(n / (tot + 2)) for e, n in dist.items()}
        def logp(self, key, e):
            d = self.p.get(key)
            if d is not None and e in d:
                return d[e]
            if key == "sp| ":
                return math.log(0.8) if e == " " else (math.log(0.15) if e == "" else -16.0)
            L = len(e)
            return (-7.5, -6.2, -8.5, -10.5, -12.5)[L] if L <= 4 else -13.5 - L

    import hybrid
    old_em = hybrid.ALIGN_EM
    hybrid.ALIGN_EM = _EM(counts)
    obs = collections.defaultdict(collections.Counter)   # (key,prev,next) -> emissions
    flat = collections.defaultdict(collections.Counter)
    for slug in bridge_slugs:
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        truth = overlay(BRIDGES[slug])
        for sid in range(1, 115):
            vol = seg["data"][sid - 1]
            app_ayahs = truth[sid]
            if len(vol) != len(app_ayahs): continue
            for k_i, (glyphs, (aid, text)) in enumerate(zip(vol, app_ayahs)):
                if k_i == 0: continue
                keys = [("sp| " if f == "sp" else f"{f}|{c}") for f, c in glyphs]
                if not any(k in targets for k in keys):
                    continue
                spans = hybrid.align_surah(keys, text, band=50)
                if spans is None: continue
                for i, k in enumerate(keys):
                    if k not in targets: continue
                    e = text[spans[i][0]:spans[i][1]]
                    pv = keys[i - 1] if i > 0 else "^"
                    nx = keys[i + 1] if i + 1 < len(keys) else "$"
                    obs[(k, pv, nx)][e] += 1
                    flat[k][e] += 1
    hybrid.ALIGN_EM = old_em
    rules = {}
    for k in targets:
        r = {}
        pv_tab = collections.defaultdict(collections.Counter)
        nx_tab = collections.defaultdict(collections.Counter)
        for (kk, pv, nx), ctr in obs.items():
            if kk != k: continue
            e, n = ctr.most_common(1)[0]
            if n >= 1 and n / sum(ctr.values()) >= 0.85:
                r[f"b:{pv}|{nx}"] = e            # exact-pair rule (strongest)
            pv_tab[pv].update(ctr)
            nx_tab[nx].update(ctr)
        for tag, tab in (("p", pv_tab), ("n", nx_tab)):
            for nb, ctr in tab.items():
                e, n = ctr.most_common(1)[0]
                if n >= 2 and n / sum(ctr.values()) >= 0.85:
                    r[f"{tag}:{nb}"] = e
        if flat[k]:
            e, n = flat[k].most_common(1)[0]
            if n / sum(flat[k].values()) >= 0.70:
                r["*"] = e
        if r:
            rules[k] = r
    (DATA / f"ctxdet-{fam}.json").write_text(json.dumps(rules, ensure_ascii=False, sort_keys=True))
    print(f"{fam}: ctx rules for {len(rules)}/{len(targets)} target keys")
    return rules
# ---------------------------------------------------------------- roundtrip loop

def word_diff_classes(got, exp):
    """Yield (class, got_word, exp_word) for aligned word diffs."""
    gw, ew = got.split(), exp.split()
    sm = difflib.SequenceMatcher(None, gw, ew)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal": continue
        for g, e in zip(gw[i1:i2] + [""] * max(0, (j2 - j1) - (i2 - i1)),
                        ew[j1:j2] + [""] * max(0, (i2 - i1) - (j2 - j1))):
            sk_g = "".join(ch for ch in g if not unicodedata.combining(ch) and ch != "✗")
            sk_e = "".join(ch for ch in e if not unicodedata.combining(ch))
            PAUSE = set("\u06d6\u06d7\u06d8\u06d9\u06da\u06db\u06dc\u06d9")
            if "✗" in g:
                yield ("UNMAPPED", g, e)
            elif sk_g == sk_e and set(g) ^ set(e) and (set(g) ^ set(e)) <= PAUSE:
                yield ("PAUSE-EDITION", g, e)
            elif sk_g == sk_e:
                # same letters, different marks: show the mark delta
                mg = [hex(ord(c)) for c in g if unicodedata.combining(c)]
                me = [hex(ord(c)) for c in e if unicodedata.combining(c)]
                delta = f"marks {'+'.join(sorted(set(me)-set(mg)))or'-'}|{'+'.join(sorted(set(mg)-set(me)))or'-'}"
                yield (delta, g, e)
            else:
                yield ("RASM", g, e)

def roundtrip(slugs):
    for slug in slugs:
        fam = FAMILY[slug]
        detmap = build_detmap(fam)
        ctxp = DATA / f"ctxdet-{fam}.json"
        ctx = json.loads(ctxp.read_text()) if ctxp.exists() else None
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        truth = overlay(BRIDGES[slug])
        missing = collections.Counter()
        classes = collections.Counter()
        samples = collections.defaultdict(list)
        ok = tot = 0
        for sid in range(1, 115):
            vol = seg["data"][sid - 1]
            app_ayahs = truth[sid]
            if len(vol) != len(app_ayahs): continue
            for k, (glyphs, (aid, text)) in enumerate(zip(vol, app_ayahs)):
                if k == 0: continue
                got = render_det(glyphs, detmap, missing, family=fam, ctx=ctx)
                exp = text
                tot += 1
                if got == exp:
                    ok += 1
                    continue
                for cls, g, e in word_diff_classes(got, exp):
                    classes[cls] += 1
                    if len(samples[cls]) < 3:
                        samples[cls].append((f"{sid}:{aid}", g, e))
        print(f"\n=== {slug} deterministic roundtrip: {ok}/{tot} exact ({ok/max(tot,1):.2%}) ===")
        print("diff classes (top 25):")
        for cls, n in classes.most_common(25):
            print(f"  ×{n:<6} {cls}")
            for loc, g, e in samples[cls]:
                print(f"        {loc}: {g!r} ⇢ {e!r}")
        print("unmapped keys (top 15):")
        for k, n in missing.most_common(15):
            print(f"  ×{n:<6} {k}")


def emit_targets(slugs):
    import zlib
    from extract import strip_header_and_basmalah
    OUT = DATA
    APPOUT = APP / "Resources/Data/Quran"
    APPOUT.mkdir(parents=True, exist_ok=True)
    NAMES = {"hisham":"QiraahHisham","ibndhakwan":"QiraahIbnDhakwan","khalaf":"QiraahKhalaf",
             "khallad":"QiraahKhallad","abuharith":"QiraahAbuHarith","durikisai":"QiraahDuriKisai",
             "ibnwardan":"QiraahIbnWardan","ibnjammaz":"QiraahIbnJammaz","ruways":"QiraahRuways",
             "rawh":"QiraahRawh","ishaq":"QiraahIshaq","idris":"QiraahIdris"}
    for slug in slugs:
        fam = FAMILY[slug]
        detmap = build_detmap(fam)
        ctxp = DATA / f"ctxdet-{fam}.json"
        ctx = json.loads(ctxp.read_text()) if ctxp.exists() else None
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        missing = collections.Counter()
        out = {}
        for sid, surah in enumerate(seg["data"], 1):
            ayahs = []
            for aid, glyphs in enumerate(surah, 1):
                t = render_det(glyphs, detmap, missing, family=fam, ctx=ctx)
                if aid == 1:
                    if sid == 9:
                        t = strip_header_and_basmalah(t, tawbah=True)
                    elif sid == 1:
                        t = strip_header_and_basmalah(t, keep_basmalah=True)
                        if len(t.split()) > 5:
                            t = strip_header_and_basmalah(t, keep_basmalah=False)
                    else:
                        t = strip_header_and_basmalah(t, keep_basmalah=False)
                t = t.replace("✗", "").strip()
                ayahs.append({"id": aid, "text": re.sub(r"\s+", " ", t)})
            out[str(sid)] = ayahs
        name = NAMES[slug]
        raw = json.dumps(out, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        (OUT / f"{slug}.final.json").write_text(raw.decode("utf-8"))
        co = zlib.compressobj(9, zlib.DEFLATED, -15)
        blob = co.compress(raw) + co.flush()
        (APPOUT / f"{name}.json.deflate").write_bytes(blob)
        tot = sum(len(v) for v in out.values())
        unm = sum(missing.values())
        print(f"{slug} → {name}: {tot} ayahs, unresolved-glyph occurrences dropped={unm}, deflate={len(blob):,}B")
if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "rules":
        verify_rules()
    elif cmd == "detmap":
        for fam in ("kufi", "madani", "basri", "makki"):
            build_detmap(fam)
    elif cmd == "roundtrip":
        roundtrip(sys.argv[2:])
    elif cmd == "ctxpass":
        ctxpass(sys.argv[2], sys.argv[3:])
    elif cmd == "emit":
        emit_targets(sys.argv[2:])
