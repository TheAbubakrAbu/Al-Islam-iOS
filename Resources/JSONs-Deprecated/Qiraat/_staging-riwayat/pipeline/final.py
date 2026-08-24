#!/usr/bin/env python3
"""Deterministic rendering + verification loop. No LM, no beams - every character
must come from (a) a high-purity glyph emission, (b) a deterministic rule, or be a
visible ✗ that fails validation.

  rules      : verify the wasla rule + mark-order stats against app texts
  detmap     : build data/detmap-<family>.json from glyphcounts-<family>.json
  roundtrip <bridge...> : render bridge volumes deterministically, diff vs app texts,
                          print a CLASS HISTOGRAM of every difference
"""
import json, sys, os, math, collections, pathlib, re, unicodedata, difflib

BASE = pathlib.Path(__file__).resolve().parent
DATA = BASE / "data"
APP = pathlib.Path("/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS")
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

# Zone-corrected mark emissions, from `zonectx.py --write`.
#
# This print draws a doubled letter as [kasra stroke][shadda], in that stream order, and
# Unicode writes the shadda first. Instead of reordering, the EM learner simply SWAPPED the
# two emissions: the below-baseline kasra glyph (HQPB4#176 and friends) learned to emit a
# shadda, and the above-baseline shadda ladder (HQPB4#65/67/68/69/70/71/73..77/79..82, one
# outline at fifteen stack heights) learned to emit a kasra.
#
# That produces the right string for the PAIR and nonsense for every ladder glyph appearing
# without its kasra partner, which is where `جَبۡرَِيل` for `جَبۡرَئِيل` came from. Here each
# glyph emits the mark its ink actually is, and `reorder_shadda` below puts the pair back
# into Unicode order, so an unpaired ladder glyph now yields a bare shadda instead of a
# spurious kasra.
ZONEFLIP = json.loads((DATA / "zoneflip.json").read_text()) \
    if (DATA / "zoneflip.json").exists() else {}

SHADDA = "\u0651"
# tanween, fatha, damma, kasra, and the dagger alef: everything a shadda can cap
_CAPPABLE = "\u064b\u064c\u064d\u064e\u064f\u0650\u0670\u0656"

def reorder_shadda(text):
    """[vowel][shadda] -> [shadda][vowel]. See ZONEFLIP: the page stacks the shadda after
    the vowel it caps; Unicode and the app both write it first."""
    return re.sub("([" + _CAPPABLE + "])" + SHADDA, lambda m: SHADDA + m.group(1), text)

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
    marks are stroke+fill double-draw artifacts.

    Also folds a repeated mark SEQUENCE, not just a repeated character: a glyph that
    carries two marks at once (HQPB4 gid 38 is kasra + small low meem) double-draws as
    `ِِۭۭ`, where no two adjacent characters are equal and the per-character rule above
    sees nothing to remove."""
    out = []
    for ch in text:
        if out and ch == out[-1] and unicodedata.combining(ch):
            continue
        out.append(ch)
    # second pass: within each maximal run of combining marks, XY XY -> XY
    res, i, n = [], 0, len(out)
    while i < n:
        if not unicodedata.combining(out[i]):
            res.append(out[i]); i += 1
            continue
        j = i
        while j < n and unicodedata.combining(out[j]):
            j += 1
        run = out[i:j]
        half = len(run) // 2
        if len(run) % 2 == 0 and half and run[:half] == run[half:]:
            run = run[:half]
        res.extend(run)
        i = j
    return "".join(res)

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
        if k == "CL|HQPB5#20|1":
            out.append((k, ""))   # placeholder; the imalah pass above rewrites runs
            continue
        if k.startswith("CL|") and "HQPB5#20|1" in k and k != "CL|HQPB5#20|1":
            # letter cluster carrying its imalah dot (geometric attachment): resolve
            # the letter without the dot, then put the dot right after it
            members = [m for m in k[3:].split("||") if m != "HQPB5#20|1"]
            base_key = "CL|" + "||".join(members)
            bv = None
            if ctx is not None and base_key in ctx:
                r = ctx[base_key]
                pv = keys[i - 1] if i > 0 else "^"
                nx = keys[i + 1] if i + 1 < len(keys) else "$"
                bv = r.get(f"b:{pv}|{nx}") or r.get(f"p:{pv}") or r.get(f"n:{nx}") or r.get("*")
            if bv is None:
                bv = detmap.get(base_key)
            if bv is not None:
                out.append((k, bv + "\u065c"))
                continue
        if k == "CL|HQPB5#7|$" and family != "kufi":
            out.append((k, ""))   # wasl sign; family word-repair restores vowel+dot
            continue
        v = None
        if ctx is not None and k in ctx:
            r = ctx[k]
            pv = keys[i - 1] if i > 0 else "^"
            nx = keys[i + 1] if i + 1 < len(keys) else "$"
            v = r.get(f"b:{pv}|{nx}")
            if v is None: v = r.get(f"p:{pv}")
            if v is None: v = r.get(f"n:{nx}")
            if v is None: v = r.get("*")
        if k in ZONEFLIP:
            v = ZONEFLIP[k]          # geometry beats the learner; see ZONEFLIP
        if v == "" and k != "sp| ":
            # A ctx rule may blank a MARK (a stray layer copy) but never a LETTER: a letter
            # that is printed is a letter that is read. Across the Kufi map only 34 rules on
            # 14 letter keys do this, against 1,800+ that keep the letter, and they cost
            # real words: 3 of HQPB2#179's 117 rules deleted the ya of `يَٰبُنَيَّ`.
            base = detmap.get(k)
            if base and not any(unicodedata.combining(c) for c in base):
                v = base
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
    # Imalah dot (U+065C): glyph HQPB5 gid 20, drawn in ~3 layers per dot. A run of
    # tokens = round(len/3) dots, belonging UNDER the letters immediately before the
    # run (the print stacks them after the word's letters in x-order). Handled before
    # the dup-collapse below, which would otherwise eat the whole run.
    IMALAH_KEY = "CL|HQPB5#20|1"
    if any(k == IMALAH_KEY for k, _ in out):
        merged = []
        i = 0
        while i < len(out):
            if out[i][0] == IMALAH_KEY:
                j = i
                while j < len(out) and out[j][0] == IMALAH_KEY:
                    j += 1
                ndots = max(1, round((j - i) / 3))
                placed = 0
                p = len(merged) - 1
                while p >= 0 and placed < ndots:
                    vv = merged[p][1]
                    if vv and vv != " " and not unicodedata.combining(vv[0]):
                        merged.insert(p + 1, (IMALAH_KEY, "\u065c"))
                        placed += 1
                    p -= 1
                if placed == 0:
                    merged.append((IMALAH_KEY, "\u065c"))
                i = j
            else:
                merged.append(out[i])
                i += 1
        out = merged

    # SAME-key consecutive identical mark = stroke+fill double-draw → drop the copy.
    # DIFFERENT keys emitting the same single vowel adjacently = kasra+shadda pair
    # whose shadda glyph was EM-confused with the vowel → the second IS the shadda.
    VOWELS = {"ِ", "َ", "ُ"}
    fixed = []
    for k, v in out:
        if fixed:
            pk, pv2 = fixed[-1]
            # The MSH farsh layer double-draws its LETTERS too (stroke then fill), which the
            # combining-only rule below cannot see: `جَبۡرَءِيلَ` came out `جَبۡرَءءِيلَ`.
            if k == pk and v == pv2 and v and "MSH" in k:
                continue
            if v == pv2 and v and unicodedata.combining(v[0]) and len(v) == 1:
                if k == pk:
                    continue                    # double-draw artifact
                if v in VOWELS:
                    fixed[-1] = (pk, "ّ" + pv2)  # shadda glyph + vowel; app orders shadda FIRST
                    continue
        fixed.append((k, v))
    t = reorder_shadda(re.sub(r"\s+", " ", "".join(v for _, v in fixed)).strip())
    if family == "kufi":
        for dg in ("ٱا", "اٱ", "ٱٱ"):
            t = t.replace(dg, "ٱ")   # wasla-sign glyph + bare-alef glyph = ONE ٱ
        # الله/لله ligature: the lam strokes are VECTOR ART (not text glyphs); only the
        # alef/heh print as text. 'ٱَ' and a standalone 'هِ' word cannot otherwise occur.
        ALLAH_LL = "\u0644\u0644\u0651\u064e"          # ل ل ّ َ  (shadda before vowel)
        for pat in ("\u0671\u064e", "\u0627\u064e"):     # ٱَ / اَ - impossible except in الله
            t = t.replace(pat, "\u0671" + ALLAH_LL)         # always-wasl ٱللَّ
        for pat in ("\u0671\u06e1", "\u0627\u06e1"):     # ٱۡ / اۡ - sukun of the INVISIBLE lam
            t = t.replace(pat, "\u0671\u0644\u06e1")      # ٱلۡ
        # `وَلَٰكِنِ ٱللَّهُ` (8:17) is a Hamzah farsh word, so the print highlights it and draws
        # the lam's shadda-fatha as its own glyph ON TOP of the ٱَ pair the rule above
        # already expands to للَّ. That leaves the heh carrying two vowels; it carries one,
        # and the second is the real one (the page reads ٱللَّهُ, not ٱللَّهَ).
        t = re.sub("(\u0671\u0644\u0644\u0651\u064e\u0647)[\u064b-\u0650]([\u064b-\u0650])",
                   r"\1\2", t)
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
    else:
        t = apply_family_conventions(t, family)
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
    # Glyphs the zone audit proved are mismapped: their ink sits on the wrong side of
    # the baseline for the mark they emit (a kasra is drawn below, a shadda above), so a
    # high "purity" score here only means the EM learned one wrong answer confidently.
    # They MUST be targets, otherwise the pinning below freezes the error in place.
    zb = DATA / "zonebad.json"
    if zb.exists():
        bad = set(json.loads(zb.read_text()))
        targets |= bad
        print(f"{fam}: +{len(bad)} zone-violating keys forced into the target set")

    # low-purity flat keys too
    for k, dist in counts.items():
        items = sorted(dist.items(), key=lambda x: -x[1])
        tot = sum(dist.values())
        if len(items) >= 2 and items[0][1] / tot < 0.90:
            targets.add(k)

    class _EM:
        def __init__(self, c, pinned=None):
            self.p = {}
            self.pinned = pinned or {}
            for k, dist in c.items():
                tot = sum(dist.values())
                self.p[k] = {e: math.log(n / (tot + 2)) for e, n in dist.items()}
        def logp(self, key, e):
            # a key the deterministic map already solved is PINNED: aligning it to
            # anything else is heavily punished, which snaps the whole alignment tight
            # around the few genuinely unknown keys
            v = self.pinned.get(key)
            if v is not None and v != "":
                return -0.05 if e == v else -13.0
            d = self.p.get(key)
            if d is not None and e in d:
                return d[e]
            if key == "sp| ":
                return math.log(0.8) if e == " " else (math.log(0.15) if e == "" else -16.0)
            L = len(e)
            return (-7.5, -6.2, -8.5, -10.5, -12.5)[L] if L <= 4 else -13.5 - L

    import hybrid
    old_em = hybrid.ALIGN_EM
    pinned = {k: v for k, v in detmap.items() if k not in targets}
    hybrid.ALIGN_EM = _EM(counts, pinned=pinned)
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

# ------------------------------------------------- family conventions (madani/basri)

FAMILY_BRIDGE_TEXT = {"madani": "QiraahQaloon", "basri": "QiraahDuri", "makki": "QiraahQunbul"}
_conv_cache = {}
_WASL_SIGNS = "\u06ec\u06ea"          # ۬ dot-above, ۪ dot-below
_PAUSE_SET = set("\u06d6\u06d7\u06d8\u06d9\u06da\u06db")

def _family_tables(family):
    """Learn, from the family's OWN verified app text: (a) wasl-alef prefix forms keyed
    by (previous word's final char, rest-of-word), (b) Allah-word forms by skeleton,
    (c) nun-idgham junction forms keyed by (bare-final word, next word's first letter)."""
    if family in _conv_cache:
        return _conv_cache[family]
    import collections as _c
    name = FAMILY_BRIDGE_TEXT[family]
    d = json.loads((APP / f"Resources/JSONs-Deprecated/Qiraat/{name}.json").read_text())
    wasl = _c.defaultdict(_c.Counter)      # (prev_last, stripped) -> full word
    allah = _c.defaultdict(_c.Counter)     # skeleton -> full word
    idgh = _c.defaultdict(_c.Counter)      # (prev_stripped_suffix, next_first) -> (prev_full, next_prefix)
    def _sk(w):
        return "".join("ا" if ch in "اٱأإآ" else ch for ch in w
                       if not unicodedata.combining(ch) and ch not in "ـ" and ch not in _WASL_SIGNS)
    for v in d.values():
        for a in v:
            ws = a["text"].split()
            for i, w in enumerate(ws):
                prev = ws[i - 1] if i else ""
                prev_last = prev[-1] if prev else "^"
                wp = "".join(ch for ch in w if ch not in _PAUSE_SET)
                if wp and wp[0] == "ا" and len(wp) > 2 and (wp[1] in "\u064e\u064f\u0650" and wp[2] in _WASL_SIGNS):
                    stripped = "ا" + wp[3:]
                    wasl[(prev_last, stripped)][wp] += 1
                    wasl[("*", stripped)][wp] += 1
                # madd-before-hamza: the app writes a trailing ٓ the print omits
                if "\u0653" in w[-3:]:
                    bare = w.replace("\u0653", "")
                    nxt0 = ws[i + 1][0] if i + 1 < len(ws) else "$"
                    idgh[("MADD", bare, nxt0)][(w, "")] += 1
                # prefixed wasl (وَا فَا بِا كَا): vowel-on-alef, no dot
                if len(w) > 3 and w[0] in "وفبكت" and w[1] == "\u064e" and w[2] == "ا" and w[3] in "\u064e\u064f\u0650":
                    stripped = w[:3] + w[4:]
                    wasl[("*", "".join(ch for ch in stripped if ch not in _PAUSE_SET))][
                        "".join(ch for ch in w if ch not in _PAUSE_SET)] += 1
                sk = _sk(w)
                if sk in ("الله", "لله", "بالله", "والله", "تالله", "فالله", "ولله", "فلله", "ابالله"):
                    # the print draws the lam pair as vector art: key by what the
                    # RENDER produces (lamless skeleton + the final vowel)
                    lamless = sk.replace("لل", "", 1)
                    final = next((ch for ch in reversed(wp) if True), "")
                    allah[(lamless, wp[-1] if wp else "")][wp] += 1
                # nun/tanwin idgham junction: word ends bare ن + next starts doubled letter
                if i + 1 < len(ws):
                    nxt = ws[i + 1]
                    if w.endswith("\u0646\u06e1") and len(nxt) > 2 and nxt[1] == "\u0651":
                        idgh[(w[:-1], nxt[0])][(w, nxt[:2])] += 1
                    elif w.endswith("\u0646") and len(nxt) > 2 and nxt[1] == "\u0651":
                        idgh[(w, nxt[0])][(w, nxt[:2])] += 1
    tables = (
        {k: c.most_common(1)[0][0] for k, c in wasl.items()},
        {k: c.most_common(1)[0][0] for k, c in allah.items()},
        {k: c.most_common(1)[0][0] for k, c in idgh.items()},
    )
    _conv_cache[family] = tables
    return tables

def rep_pref(w, wasl_tab):
    return wasl_tab.get(("*", w))

def apply_family_conventions(t, family):
    if family not in FAMILY_BRIDGE_TEXT:
        return t
    wasl_tab, allah_tab, idgh_tab = _family_tables(family)
    # wasl-signs re-enter only via the learned tables; stray ones are print noise
    t = t.replace("\u06ec", "").replace("\u06ea", "")
    words = t.split(" ")
    def _sk(w):
        return "".join("ا" if ch in "اٱأإآ" else ch for ch in w
                       if not unicodedata.combining(ch) and ch not in "ـ" and ch not in _WASL_SIGNS)
    out = []
    for i, w in enumerate(words):
        # Allah-family words (lams are vector art in the print); the final vowel
        # disambiguates against ordinary words sharing the lamless skeleton (لَهُ)
        if "ه" in w and w:
            tail = "".join(ch for ch in w if ch in _PAUSE_SET)
            wp = "".join(ch for ch in w if ch not in _PAUSE_SET)
            rep = allah_tab.get((_sk(wp), wp[-1] if wp else ""))
            if rep and len(wp) < len(rep):
                out.append(rep + tail)
                continue
        # the lam of ال before a hamza letter is vector art: 'اأ/اإ/اءا' never occur
        for hz in ("\u0623", "\u0625", "\u0622"):
            w = w.replace("ا" + hz, "ا\u0644\u06e1" + hz)
        # wasl-alef prefix: rendered form is bare 'ا' + rest; the app form carries
        # naql vowel + dot chosen by the PRECEDING word's ending
        if w and w[0] == "ا" and (len(w) < 2 or w[1] not in "\u064e\u064f\u0650"):
            prev_last = out[-1][-1] if out and out[-1] else "^"
            rep = wasl_tab.get((prev_last, w)) or wasl_tab.get(("*", w))
            if rep:
                out.append(rep)
                continue
        if w and w[0] in "وفبكت" and rep_pref(w, wasl_tab) is not None:
            out.append(rep_pref(w, wasl_tab))
            continue
        out.append(w)
    # madd-before-hamza junctions
    for i in range(len(out)):
        nxt0 = out[i + 1][0] if i + 1 < len(out) and out[i + 1] else "$"
        rep = idgh_tab.get(("MADD", out[i], nxt0))
        if rep:
            out[i] = rep[0]
    # nun-idgham junctions: the print writes plain ن + plain next initial; the app
    # convention writes نۡ + shadda on the next word's first letter. Learned pairs
    # are keyed by (the bare word, next word's first letter).
    for i in range(len(out) - 1):
        w, nxt = out[i], out[i + 1]
        if w.endswith("\u0646") and nxt:
            rep = idgh_tab.get((w, nxt[0]))
            if rep:
                full_prev, next_prefix = rep
                out[i] = full_prev
                if len(nxt) > 1 and nxt[1] != "\u0651":
                    out[i + 1] = next_prefix + nxt[1:]
    return " ".join(out)

# ------------------------------------------------- muqatta'at repair

# The prints write the opening letter-sequences bare (الم); the app's KFGQPC texts
# spell them with their pronunciation marks (Hafs-style الٓمٓ, Madani أَلَٓمِّٓ). A closed
# set - repaired verbatim from each family's own bridge text, keyed by (surah, ayah).
_MUQ_SURAHS = {2,3,7,10,11,12,13,14,15,19,20,26,27,28,29,30,31,32,36,38,40,41,42,43,44,45,46,50,68}
_MUQ_LETTERS = set("اٱلمصركهيعطسحقنو")
_MUQ_BRIDGE = {"kufi": "QiraahShubah", "madani": "QiraahQaloon",
               "basri": "QiraahDuri", "makki": "QiraahQunbul"}
_muq_cache = {}

def _muq_table(family):
    if family in _muq_cache:
        return _muq_cache[family]
    d = json.loads((APP / f"Resources/JSONs-Deprecated/Qiraat/{_MUQ_BRIDGE[family]}.json").read_text())
    tab = {}
    for sid in _MUQ_SURAHS:
        for aid in (1, 2):
            ayahs = d.get(str(sid), [])
            entry = next((a for a in ayahs if a["id"] == aid), None)
            if not entry or not entry["text"]:
                continue
            w = entry["text"].split()[0]
            w = "".join(ch for ch in w if ch not in _PAUSE_SET)
            core = "".join(ch for ch in w if not unicodedata.combining(ch))
            if core and set(core) <= _MUQ_LETTERS and len(core) <= 5:
                tab[(sid, aid)] = w
    _muq_cache[family] = tab
    return tab

def apply_muqattaat(t, family, sid, aid):
    rep = _muq_table(family).get((sid, aid))
    if not rep:
        return t
    words = t.split()
    if not words:
        return t
    first_core = "".join(ch for ch in words[0] if not unicodedata.combining(ch))
    rep_core = "".join(ch for ch in rep if not unicodedata.combining(ch))
    fc = first_core.replace("ٱ", "ا")
    rc = rep_core.replace("ٱ", "ا").replace("أ", "ا")
    def subseq(a, b):
        it = iter(b)
        return all(ch in it for ch in a)
    if first_core and set(fc) <= _MUQ_LETTERS and len(fc) <= len(rc) + 2 and subseq(rc, fc):
        words[0] = rep
        return " ".join(words)
    return t

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
    # Emit destination. Defaults to pipeline/emit/ so a pipeline run can NEVER overwrite
    # the shipped .json.deflate by accident; point QIRAAT_EMIT_DIR at
    # Resources/Data/Quran only when you have reviewed the diff and mean to ship it.
    APPOUT = pathlib.Path(os.environ.get("QIRAAT_EMIT_DIR", BASE / "emit"))
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
                if aid <= 2:
                    t = apply_muqattaat(t, fam, sid, aid)
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
