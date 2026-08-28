#!/usr/bin/env python3
"""al-Bazzi's glyph map, learned from its own verified text.

The al-Bazzi volume is the one PDF in the set that is a REPROCESSED copy: its producer is
"eDocument Library version 2.6 PDF Filter" where every other volume says Acrobat
Distiller. The filter did two things that broke the pipeline.

  1. It re-subset every embedded font into its own glyph order, so 98% of al-Bazzi's
     glyph keys were unknown to a Makki map learned from Qunbul and 42% of the volume
     rendered as nothing.
  2. It DROPPED the invisible Times separator layer. Qunbul draws 79,415 space glyphs;
     al-Bazzi draws 8,086, none of them between words. Word breaks are not recoverable
     from geometry either: measured against Qunbul's own separators, a third of the real
     breaks have no horizontal gap at all (the tail of a word-final ن or ي sweeps back
     under the next word), so a gap test caps at 74% recall no matter where it is set.
     al-Bazzi therefore renders WITHOUT spaces, and its word boundaries come from the
     shipped text at alignment time.

(1) is fixable exactly and without statistics. The two volumes' fonts hold the same
drawings, so matching them by OUTLINE recovers the re-coding: 968 of al-Bazzi's 999
glyphs have a shape twin in Qunbul (`shapemap`). That renders 86% of its tokens. The rest
are letterforms Qunbul's text never needs - the lafz al-jalalah ligature above all - and
those are learned here, supervised, from al-Bazzi's own verified text: bootstrap-render an
ayah, align it to the known text, and wherever exactly ONE unknown glyph faces a run of
unexplained characters, that run is what the glyph says. Nothing ambiguous is guessed.

The counts are merged into glyphcounts-makki.json under al-Bazzi's OWN keys, never the
translated ones, so Qunbul's half of the family is left byte-identical and the ordinary
`final.build_detmap` / `render_det` chain needs no al-Bazzi special case.

    python3 bazzi.py shapemap      # rebuild data/bazzi-shapemap.json from the two PDFs
    python3 bazzi.py learn         # merge al-Bazzi's keys into glyphcounts-makki.json
    python3 bazzi.py check         # render accuracy against QiraahBuzzi, space-blind
"""
import sys, os, io, json, hashlib, collections, warnings, difflib, pathlib, unicodedata
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
warnings.filterwarnings("ignore")
import extract, final

DATA = pathlib.Path(__file__).resolve().parent / "data"
TWIN = "qunbul"
COUNTS = "glyphcounts-bazzi.json"      # overlay, never merged into the Makki family
FACES = ("HQPB", "Hamd", "DecoType", "MSH")
UNK = "�"


# ------------------------------------------------------------------ shape bridge

def _shapes(slug):
    """family -> {gid: outline hash}, folded over every subset the volume embeds.

    A gid whose subsets disagree is dropped rather than guessed; in practice none do.
    """
    import fitz
    from fontTools.ttLib import TTFont
    from fontTools.pens.recordingPen import RecordingPen
    d = fitz.open(extract.pdf_path(slug))
    xrefs = {}
    for pno in range(d.page_count):
        for f in d[pno].get_fonts(full=True):
            fam = f[3].split("+")[-1]
            if fam.startswith(FACES):
                xrefs[(fam, f[0])] = None
    out = collections.defaultdict(lambda: collections.defaultdict(set))
    for fam, xref in xrefs:
        try:
            _n, _e, _t, buf = d.extract_font(xref)
            tt = TTFont(io.BytesIO(buf), lazy=True)
            gs, order = tt.getGlyphSet(), tt.getGlyphOrder()
            upem = tt["head"].unitsPerEm
        except Exception:
            continue
        for gid, gn in enumerate(order):
            try:
                p = RecordingPen(); gs[gn].draw(p)
            except Exception:
                continue
            if not p.value:
                continue
            out[fam][gid].add(hashlib.sha1(
                ("%d|" % upem + repr(p.value)).encode()).hexdigest()[:16])
    return {fam: {g: next(iter(h)) for g, h in m.items() if len(h) == 1}
            for fam, m in out.items()}


def _gid_chars(slug):
    """font#gid -> the volume's own cmap char, so a translated key is spelled the way
    the twin spells it (the detmap key carries the char, not just the gid)."""
    raw = json.loads((DATA / f"{slug}.raw.json").read_text())
    c = collections.defaultdict(collections.Counter)
    for ay in raw:
        for f, txt in ay[0]:
            if f != "CL":
                continue
            for m in txt.split("||"):
                fg, _, ch = m.rpartition("|")
                c[fg][ch] += 1
    return {k: v.most_common(1)[0][0] for k, v in c.items()}


def build_shapemap():
    b, q = _shapes("bazzi"), _shapes(TWIN)
    qch = _gid_chars(TWIN)
    detmap = final.build_detmap("makki")
    solo = {}
    for k, v in detmap.items():
        if k.startswith("CL|") and "||" not in k[3:]:
            fg, _, _ch = k[3:].rpartition("|")
            solo.setdefault(fg, set()).add(v)
    cand = collections.defaultdict(list)
    for fam in set(b) & set(q):
        qh = collections.defaultdict(list)
        for g, h in q[fam].items():
            qh[h].append(g)
        for g, h in b[fam].items():
            for tg in qh.get(h, []):
                cand[f"{fam}#{g}"].append(f"{fam}#{tg}")
    gidmap, amb = {}, 0
    for src, tgts in cand.items():
        if len(tgts) == 1:
            gidmap[src] = tgts[0]; continue
        # The same drawing at several gids is still one letter, so long as every
        # candidate says the same thing in the twin's map.
        ems = [solo.get(t) for t in tgts]
        known = [e for e in ems if e]
        if known and all(e == known[0] for e in known) and len(known[0]) == 1:
            gidmap[src] = tgts[ems.index(known[0])]
        else:
            amb += 1
    out = {"gid": gidmap, "qchar": {g: qch.get(g, "") for g in set(gidmap.values())}}
    (DATA / "bazzi-shapemap.json").write_text(
        json.dumps(out, ensure_ascii=False, indent=1, sort_keys=True))
    print(f"shapemap: {len(gidmap)} glyphs bridged to {TWIN}, {amb} ambiguous")
    return out


def shapemap():
    p = DATA / "bazzi-shapemap.json"
    if not p.exists():
        return build_shapemap()
    return json.loads(p.read_text())


def translate(glyphs, sm):
    """al-Bazzi glyph list -> the same list spelled in the twin's gids, for BOOTSTRAP
    rendering only. The learned counts are always filed under the original keys."""
    gid, qch = sm["gid"], sm["qchar"]
    out = []
    for f, c in glyphs:
        if f != "CL":
            out.append([f, c]); continue
        ms = []
        for m in c.split("||"):
            fg, _, ch = m.rpartition("|")
            t = gid.get(fg)
            ms.append(f"{t}|{qch.get(t, ch)}" if t else m)
        out.append([f, "||".join(sorted(ms))])
    return out


# ------------------------------------------------------------------ supervised learn

def _key(f, c):
    return "sp| " if f == "sp" else f"{f}|{c}"


def detmap():
    """The Makki map with al-Bazzi's own keys overlaid. Qunbul is unaffected."""
    return final.build_detmap("makki", extra=COUNTS)


def slot_render(glyphs, dm, tmap):
    """Per-glyph emissions, keeping slot boundaries. `tmap` is the bootstrap detmap keyed
    by translated keys; `detmap` is the real one, keyed by al-Bazzi's own."""
    slots = []
    for f, c in glyphs:
        k = _key(f, c)
        if k == "sp| ":
            v = " "
        elif final.is_marginalia(k):
            # The running footer and the printed legend are set in Naskh note faces;
            # render_det drops them, so they are KNOWN to say nothing, not unknown.
            v = ""
        else:
            v = dm.get(k)
            if v is None:
                v = tmap.get(k)
        slots.append((k, v))
    return slots


def _strip(text):
    return final.normalize_marks(text).replace(" ", "")


# The two orthographic choices the render cannot make without word boundaries, plus the
# hamza carriers the emit chain composes. Identical to colorlayer._FOLD, and for the same
# reason: it is the letter spine that has to be right.
_FOLD = {"\u0671": "\u0627", "\u0623": "\u0627", "\u0625": "\u0627",
         "\u0622": "\u0627", "\u0649": "\u064a", "\u0626": "\u064a",
         "\u0624": "\u0648", "\u0640": ""}


def _spine(text):
    return "".join(_FOLD.get(c, c) for c in text if not unicodedata.combining(c))


def learn_pass(dm, tmap, sm, pairs):
    """One supervised pass: bootstrap-render, align to the known text, and read off what
    each still-unknown glyph must be saying.

    Only a run of unexplained characters facing exactly ONE unknown slot is learned. Two
    unknowns side by side carry no evidence about which of them owns which characters,
    and a wrong split there would be indistinguishable from a right one downstream.
    """
    counts = collections.defaultdict(collections.Counter)
    for glyphs, text in pairs:
        slots = slot_render(glyphs, dm, tmap)
        own = [_key(f, c) for f, c in glyphs]
        pre, spans = [], []
        for (_k, v) in slots:
            lo = len(pre)
            pre.extend(v if v is not None else UNK)
            spans.append((lo, len(pre)))
        pre = "".join(pre)
        tgt = _strip(text)
        sm2 = difflib.SequenceMatcher(None, pre, tgt, autojunk=False)
        for tag, i1, i2, j1, j2 in sm2.get_opcodes():
            if tag == "equal":
                continue
            hit = [s for s, (lo, hi) in enumerate(spans) if lo < i2 and hi > i1]
            if any(spans[s][0] < i1 or spans[s][1] > i2 for s in hit):
                continue                 # a slot straddles the region edge: no evidence
            unk = [s for s in hit if slots[s][1] is None]
            if len(unk) != 1:
                continue
            u = unk[0]
            pre_k = "".join(slots[s][1] for s in hit if s < u)
            suf_k = "".join(slots[s][1] for s in hit if s > u)
            got = tgt[j1:j2]
            if not got.startswith(pre_k) or not got.endswith(suf_k):
                continue                 # the known neighbours do not line up
            counts[own[u]][got[len(pre_k):len(got) - len(suf_k) or None]] += 1
    return counts


def bridge_pairs():
    """(glyphs, text) for every al-Bazzi ayah that pairs with its verified text.

    Pairing uses the bootstrap render so a surah whose ayah counts disagree is realigned
    rather than dropped whole - `collect_pairs` documents why that check matters.
    """
    sm = shapemap()
    tmap = final.build_detmap("makki")
    dm = detmap()
    def render(g):
        return final.render_det(g, dm, family="makki", slug="bazzi")
    bank = extract.collect_pairs(["bazzi"], render=render)
    return [(g, t) for g, t, _s, _sid, _aid, _f in bank], tmap, sm


def alias(sm):
    """Every shape-bridged al-Bazzi key, carrying the twin's count distribution.

    Filing the bridge as COUNTS rather than as a rendering-time key rewrite means
    render_det, colorlayer and the tajweed builder need no al-Bazzi branch: they only
    have to build the detmap with the overlay. build_detmap then applies exactly the same
    purity test to these keys as to every other.
    """
    gid, qch = sm["gid"], sm["qchar"]
    merged = {}
    for other in ("kufi", "madani", "basri", "makki"):
        p = DATA / f"glyphcounts-{other}.json"
        if p.exists():
            for k, v in json.loads(p.read_text()).items():
                merged.setdefault(k, v)
    raw = json.loads((DATA / "bazzi.raw.json").read_text())
    keys = collections.Counter()
    for ay in raw:
        for f, c in ay[0]:
            if f == "CL":
                keys["CL|" + c] += 1
    out, hit, miss = {}, 0, 0
    for k, n in keys.items():
        ms = []
        for m in k[3:].split("||"):
            fg, _, ch = m.rpartition("|")
            t = gid.get(fg)
            if t is None:
                ms = None; break
            ms.append(f"{t}|{qch.get(t, ch)}")
        dist = merged.get("CL|" + "||".join(sorted(ms))) if ms else None
        if dist is None:
            miss += n; continue
        out[k] = dict(dist); hit += n
    print(f"shape aliases: {len(out)} keys, {hit} tokens bridged, {miss} left to learn "
          f"(of which the note faces render as nothing by rule)")
    return out


def learn(rounds=4):
    # The aliases have to exist before the pairing runs: collect_pairs realigns a surah by
    # RENDERING it, and with an empty overlay al-Bazzi renders as nothing, which drops
    # 6,012 of its 6,106 ayahs.
    sm = shapemap()
    own = alias(sm)
    path = DATA / COUNTS
    path.write_text(json.dumps(own, ensure_ascii=False, sort_keys=True))
    pairs, tmap, sm = bridge_pairs()
    print(f"pairs: {len(pairs)}")
    learned = {}
    for r in range(rounds):
        dm = detmap()
        counts = learn_pass(dm, {}, sm, pairs)
        new = 0
        for k, ctr in counts.items():
            # Vote on the LETTER SPINE, not the spelling. What is being learned is which
            # letter a glyph draws; whether that letter comes out `ي` or `ى`, `ا` or `ٱ`,
            # and which vowel rides on it, is decided later by maqsura_rule and the wasla
            # rule - and those two need word boundaries, which this volume does not have.
            # Folding first keeps the 3,153 occurrences of the ya glyph (1,775 `ي`, 1,378
            # `ى`) as one piece of evidence instead of two competing ones, which is the
            # difference between the key resolving and staying ambiguous.
            cls = collections.Counter()
            for e, c in ctr.items():
                cls[_spine(e)] += c
            top, n = cls.most_common(1)[0]
            tot = sum(cls.values())
            if not (tot >= 3 and n / tot >= 0.9) and not (tot >= 2 and n == tot):
                continue
            raw = collections.Counter({e: c for e, c in ctr.items() if _spine(e) == top})
            e = raw.most_common(1)[0][0]
            if own.get(k) == {e: n}:
                continue
            learned[k] = e
            own[k] = {e: n}
            new += 1
        print(f"  round {r + 1}: {len(counts)} keys had evidence, {new} taken "
              f"({len(learned)} total)")
        path.write_text(json.dumps(own, ensure_ascii=False, sort_keys=True))
        if not new:
            break
    (DATA / "bazzi-learned.json").write_text(
        json.dumps(learned, ensure_ascii=False, indent=1, sort_keys=True))
    print(f"wrote {len(own)} al-Bazzi keys to data/{COUNTS} "
          f"({len(learned)} of them read off the text)")


def spaces():
    """Restore the word separators the reprocessing threw away, from al-Bazzi's own text.

    This is not cosmetic. The lam strokes of the lafz al-jalalah are VECTOR ART in these
    volumes - only the alef and the heh print as glyphs - so `لِلَّهِ` is reconstructed by a
    rule that matches a bare `هِ` WORD (render_det, LILLAH). maqsura_rule and the wasla
    rule are word-scoped for the same kind of reason. With no separators al-Bazzi is one
    word per ayah and all three rules go silent: 2,580 ayahs lost `لل`, and every
    word-final ya came out as the wrong one of `ي`/`ى`.

    Geometry cannot supply them (see the module docstring), but the volume's own verified
    text can: align the glyph stream to it and every space in the text falls between two
    known glyphs. The separators are written into the cached stream - raw, colours and
    segmentation together, so the three stay index-aligned - and from that point al-Bazzi
    goes through the ordinary chain with no special case at all.
    """
    sm = shapemap()
    for name in ("raw", "colors", "surahs"):
        bak = DATA / f"bazzi.{name}.nosep.json"
        if not bak.exists():
            bak.write_text((DATA / f"bazzi.{name}.json").read_text())
    total = 0
    for it in range(6):
        n = _sep_pass()
        total += n
        print(f"  pass {it + 1}: {n} separators")
        if not n:
            break
    print(f"separators restored: {total}  (originals kept as bazzi.*.nosep.json)")


def _sep_pass():
    """One incremental pass. Each pass renders with the separators found so far, which
    lets the word-scoped rules fire and makes the next alignment sharper, so the passes
    converge instead of all having to be right at once."""
    dm = detmap()
    ov = extract.overlay(extract.BRIDGES["bazzi"])
    seg = json.loads((DATA / "bazzi.surahs.json").read_text())
    raw = json.loads((DATA / "bazzi.raw.json").read_text())
    cols = json.loads((DATA / "bazzi.colors.json").read_text())

    def render(g):
        return final.render_det(g, dm, family="makki", slug="bazzi")

    plan, placed = {}, 0
    for si, surah in enumerate(seg["data"]):
        app = ov[si + 1]
        rend = [extract._pairing_skeleton(render(g)) for g in surah]
        apps = [extract._pairing_skeleton(t) for _, t in app]
        pairs = None
        if len(surah) == len(app):
            fast = [(k, k, difflib.SequenceMatcher(None, rend[k], apps[k]).quick_ratio())
                    for k in range(1, len(surah))]
            if all(sc >= extract.PAIR_CUTOFF for _, _, sc in fast):
                pairs = fast
        if pairs is None:
            al = extract._ayah_alignment(rend[1:], apps[1:])
            pairs = [(a + 1, b + 1, sc) for a, b, sc in al] if al else []
        for vi, aj, sc in pairs:
            if sc < extract.PAIR_CUTOFF:
                continue
            slots = slot_render(seg["data"][si][vi], dm, {})
            pre, spans = [], []
            for _k, v in slots:
                lo = len(pre)
                pre.extend(v if v is not None else UNK)
                spans.append((lo, len(pre)))
            pre = "".join(pre)
            tgt = final.normalize_marks(app[aj][1])
            at = []
            for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(
                    None, pre, tgt, autojunk=False).get_opcodes():
                if tag not in ("insert", "replace"):
                    continue
                for off, ch in enumerate(tgt[j1:j2]):
                    if ch != " ":
                        continue
                    # where in the pre-region the break falls: exactly i1 for an
                    # insert, and proportionally inside a replace
                    span = i2 - i1
                    want = i1 + (round(span * off / max(j2 - j1, 1)) if span else 0)
                    cut = next((k for k, (lo, hi) in enumerate(spans)
                                if lo >= want and hi > lo), None)
                    if cut is None or cut == 0:
                        continue
                    if slots[cut - 1][0] == "sp| " or slots[cut][0] == "sp| ":
                        continue                 # already broken here
                    at.append(cut)
            if at:
                plan[(si, vi)] = sorted(set(at)); placed += len(at)
    if not placed:
        return 0

    # raw / colours / segmentation are index-aligned by construction and every consumer
    # relies on that, so all three move together.
    flatg = []
    for g, _v in raw:
        flatg.extend(tuple(x) for x in g)
    marks, pos = [], 0
    for si, su in enumerate(seg["data"]):
        cuts = {ai: set(plan.get((si, ai), ())) for ai in range(len(su))}
        for ai, g in enumerate(su):
            for k, t in enumerate(g):
                tt = tuple(t)
                n = 0
                while pos < len(flatg) and flatg[pos] != tt and n < 64:
                    pos += 1; n += 1
                if pos >= len(flatg) or flatg[pos] != tt:
                    raise SystemExit(f"bazzi: lost the stream at {si + 1}:{ai + 1}")
                if k in cuts[ai]:
                    marks.append(pos)
                pos += 1
    marks = set(marks)

    def insert(lst, at):
        out = []
        for i, x in enumerate(lst):
            if i in at:
                out.append(["sp", " "])
            out.append(x)
        return out

    for (si, ai), cut in plan.items():
        seg["data"][si][ai] = insert(seg["data"][si][ai], set(cut))
    (DATA / "bazzi.surahs.json").write_text(json.dumps(seg, ensure_ascii=False))
    out_raw, out_col, gi = [], [], 0
    for (g, v), c in zip(raw, cols):
        ng, nc = [], []
        for x, y in zip(g, c):
            if gi in marks:
                ng.append(["sp", " "]); nc.append(None)
            ng.append(x); nc.append(y); gi += 1
        out_raw.append([ng, v]); out_col.append(nc)
    (DATA / "bazzi.raw.json").write_text(json.dumps(out_raw, ensure_ascii=False))
    (DATA / "bazzi.colors.json").write_text(json.dumps(out_col))
    return placed


def check(limit=None):
    pairs, tmap, sm = bridge_pairs()
    dm = detmap()
    if limit:
        pairs = pairs[:limit]
    ex = exs = 0
    ratios, spine = [], []
    for glyphs, text in pairs:
        r = final.render_det(glyphs, dm, family="makki", slug="bazzi").replace(" ", "")
        t = _strip(text)
        ex += r == t
        ratios.append(difflib.SequenceMatcher(None, r, t, autojunk=False).ratio())
        a, b = _spine(r), _spine(t)
        exs += a == b
        spine.append(difflib.SequenceMatcher(None, a, b, autojunk=False).ratio())
    ratios.sort(); spine.sort()
    n = len(ratios)
    print(f"al-Bazzi space-blind: {ex}/{n} exact ({100 * ex / n:.2f}%)  "
          f"median {ratios[n // 2]:.4f}  p05 {ratios[n // 20]:.4f}")
    # The spine is the metric that governs the colour layer: colorlayer.transfer aligns
    # letter units under the same fold, so `ى` against `ي` and `ٱ` against `ا` - the two
    # calls this volume cannot make without word boundaries - are not misses there.
    print(f"al-Bazzi letter spine: {exs}/{n} exact ({100 * exs / n:.2f}%)  "
          f"median {spine[n // 2]:.4f}  p05 {spine[n // 20]:.4f}")


if __name__ == "__main__":
    cmd = sys.argv[1] if sys.argv[1:] else "check"
    if cmd == "shapemap":
        build_shapemap()
    elif cmd == "learn":
        learn()
    elif cmd == "spaces":
        spaces()
    elif cmd == "check":
        check()
