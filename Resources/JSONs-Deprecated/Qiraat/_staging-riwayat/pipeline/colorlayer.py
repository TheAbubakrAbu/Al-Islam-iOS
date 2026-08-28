"""Per-letter PRINT COLOUR for the tajweed layer.

The twenty mushaf volumes draw their tajweed colouring as ordinary coloured text in the
PDF content stream: one RGB fill per glyph, no rasterisation anywhere (PyMuPDF finds zero
images on all 604 pages of every volume). So the colouring does not have to be measured
off ink at all. `extract.raw_colors()` carries each glyph's fill alongside the glyph
stream, `render_det(..., cols=, trace=)` carries it through to the pre-normalisation
string, and this module aligns that string to the EMITTED text so that every coloured
letter lands on an exact character range in the shipped ayah.

That makes the colour layer exact by construction rather than inferred: no ink threshold,
no first-to-last span, no whole-word fallback.

    python3 colorlayer.py check <slug>...     # alignment coverage, per volume
    python3 colorlayer.py legend <slug>...    # the colours a volume actually uses
    python3 colorlayer.py build <slug>...     # write data/<slug>.colorlayer.json
"""
import sys, os, json, collections, unicodedata, pathlib
from difflib import SequenceMatcher

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import extract, final

DATA = pathlib.Path(__file__).resolve().parent / "data"

# final.FAMILY was built for the twelve staged volumes plus the bridges; al-Bazzi is the
# one shipped riwayah it never needed, and it reads with Qunbul's Makki orthography.
FAMILY = dict(final.FAMILY, bazzi="makki")

# al-Bazzi reads with Qunbul's Makki orthography but cannot share its glyph counts: its
# volume is a reprocessed copy that re-subset every font, so the same key means different
# things in the two books. bazzi.py files al-Bazzi's keys in an overlay that only its own
# renders read; Qunbul's half of the family is untouched.
COUNTS_OVERLAY = {"bazzi": "glyphcounts-bazzi.json"}


def is_base(ch):
    return not unicodedata.combining(ch) and ch != " "


def ayah_color_index(slug):
    """seg["data"] position -> that ayah's per-slot colour list.

    Matching is by CONSUMING one flat glyph stream, not by zipping ayah for ayah. The
    segmentation is not always a 1:1 relabelling of raw_ayahs(): it drops zero-glyph
    ayahs (the doubled markers), re-blocks Tawbah, and for the two Shami volumes
    `shami_fix` SPLITS four ayahs whose markers were lost across a page boundary. All of
    those preserve glyph ORDER, so walking the two streams together with an equality
    check at every glyph handles the lot, and a real mismatch still stops the run rather
    than silently painting the wrong ayah.
    """
    raw = extract.raw_ayahs(slug)
    cols = extract.raw_colors(slug)
    if len(raw) != len(cols):
        raise SystemExit(f"{slug}: raw/colors length {len(raw)} vs {len(cols)}")
    flatg, flatc = [], []
    for (g, _v), c in zip(raw, cols):
        for x, y in zip(g, c):
            flatg.append(tuple(x)); flatc.append(y)
    seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
    # The segmented stream is a SUBSEQUENCE of the raw one: `shami_fix` splits four
    # merged Shami ayahs at the unpaired bracket glyph and drops the bracket run itself.
    # So consume glyph by glyph, skipping raw glyphs the segmentation deleted.
    SKIP_MAX = 64
    idx, pos, skipped = {}, 0, 0
    for si, su in enumerate(seg["data"]):
        for ai, g in enumerate(su):
            here = []
            for t in g:
                tt = tuple(t)
                n = 0
                while pos < len(flatg) and flatg[pos] != tt and n < SKIP_MAX:
                    pos += 1; n += 1
                if pos >= len(flatg) or flatg[pos] != tt:
                    raise SystemExit(f"{slug}: glyph {tt!r} not found at surah {si+1} "
                                     f"ayah {ai+1} (stream offset {pos})")
                skipped += n
                here.append(flatc[pos]); pos += 1
            idx[(si, ai)] = here
    if skipped:
        print(f"   {slug}: skipped {skipped} raw glyphs the segmentation dropped",
              file=sys.stderr)
    return seg, idx


def emitted(slug, fam, detmap, ctx, sid, aid, glyphs, ac):
    """Render one ayah exactly as `final.py emit` does, with the colour trace."""
    trace = {}
    t = final.render_det(glyphs, detmap, None, family=fam, ctx=ctx, slug=slug,
                         cols=ac, trace=trace)
    if aid == 1:
        if sid == 9:
            t = extract.strip_header_and_basmalah(t, tawbah=True)
        elif sid == 1:
            t = extract.strip_header_and_basmalah(t, keep_basmalah=True)
            if len(t.split()) > 5:
                t = extract.strip_header_and_basmalah(t, keep_basmalah=False)
        else:
            t = extract.strip_header_and_basmalah(t, keep_basmalah=False)
    t = t.replace("✗", "").strip()
    if aid <= 2:
        t = final.apply_muqattaat(t, slug, sid, aid)
    import re
    return re.sub(r"\s+", " ", t), trace


# For ALIGNMENT ONLY. Every fold here is a rewrite the emit chain itself performs, so
# folding them keeps a letter matched to the letter it became: apply_wasla_rule turns a
# bare alef into ٱ, maqsura_rule swaps ى and ي, and compose_hamza fuses a carrier with its
# hamza into a single codepoint. Without the folds those letters read as deletions and the
# print's colour fell off them.
_FOLD = {"\u0671": "\u0627", "\u0623": "\u0627", "\u0625": "\u0627",
         "\u0622": "\u0627", "\u0649": "\u064a", "\u0626": "\u064a",
         "\u0624": "\u0648", "\u0640": ""}


# Neither of these is a letter: U+FDD0 is final.WASL_MARK, a noncharacter the render
# carries to say "a wasl sign belongs HERE" and the chain then resolves away, and ✗ is an
# unmapped glyph the emit strips. Left on the spine they read as letters the emitted text
# deleted, and the colour of the real letter beside them fell off.
_OFFSPINE = "\ufdd0\u2717"


def units(text):
    """Split into LETTER UNITS: one base letter with the marks that ride on it.

    The colour belongs to the letter, not to the codepoint sequence: the chain between the
    render and the emitted text reorders marks freely (shadda before vowel, dagger after
    maddah) but never touches the letter spine, so the spine is what can be aligned.
    Returns [(folded_base, lo, hi)] with lo/hi inclusive character offsets.
    """
    out = []
    for i, ch in enumerate(text):
        if ch == " ":
            out.append((" ", i, i)); continue
        if is_base(ch) and ch not in _OFFSPINE:
            out.append((_FOLD.get(ch, ch), i, i))
        elif out and out[-1][0] != " ":
            out[-1] = (out[-1][0], out[-1][1], i)
        else:
            out.append(("", i, i))   # a mark with no letter under it yet
    return out


def transfer(pre, precol, text):
    """Print colour per character of `text`, carried across on the letter spine.

    Returns (colours, units_coloured_in_pre, units_placed) so the caller can report what
    did NOT land instead of quietly painting an approximation.
    """
    pu, tu = units(pre), units(text)
    pcol = []
    for _b, lo, hi in pu:
        pcol.append(next((c for c in precol[lo:hi + 1] if c), 0))
    out = [0] * len(text)
    sm = SequenceMatcher(None, [u[0] for u in pu], [u[0] for u in tu], autojunk=False)
    placed = 0
    for i, j, n in sm.get_matching_blocks():
        for k in range(n):
            c = pcol[i + k]
            if not c:
                continue
            lo, hi = tu[j + k][1], tu[j + k][2]
            for x in range(lo, hi + 1):
                out[x] = c
            placed += 1
    return out, sum(1 for c in pcol if c), placed


def runs_of(colour):
    """[0,0,c,c,0,d] -> [(2, 3, c), (5, 5, d)]: maximal same-colour character runs."""
    out, i = [], 0
    while i < len(colour):
        c = colour[i]
        if not c:
            i += 1; continue
        j = i
        while j + 1 < len(colour) and colour[j + 1] == c:
            j += 1
        out.append((i, j, c)); i = j + 1
    return out


def build(slug):
    """-> ({surah: {ayah: rendered_text}}, {surah: {ayah: [[lo, hi, colour], ...]}}).

    Coordinates are over the RENDERED text, which is what the PDF actually says. Mapping
    those onto the SHIPPED text is the tajweed builder's job: it owns the tokenizer, and
    for the seven non-beta riwayat the shipped text is not this pipeline's output.
    """
    fam = FAMILY[slug]
    detmap = final.build_detmap(fam, extra=COUNTS_OVERLAY.get(slug))
    ctxp = DATA / f"ctxdet-{fam}.json"
    ctx = json.loads(ctxp.read_text()) if ctxp.exists() else None
    seg, idx = ayah_color_index(slug)
    texts, runs, st = {}, {}, collections.Counter()
    for si, surah in enumerate(seg["data"]):
        tp, rp = {}, {}
        for ai, glyphs in enumerate(surah):
            text, trace = emitted(slug, fam, detmap, ctx, si + 1, ai + 1,
                                  glyphs, idx[(si, ai)])
            colour, want, got = transfer(trace["pre"], trace["precol"], text)
            st["letters-pre"] += want
            st["letters-placed"] += got
            r = runs_of(colour)
            tp[str(ai + 1)] = text
            if r:
                rp[str(ai + 1)] = [list(x) for x in r]
                st["runs"] += len(r)
                st["ayahs"] += 1
        texts[str(si + 1)] = tp
        if rp:
            runs[str(si + 1)] = rp
    return texts, runs, st


def main():
    cmd = sys.argv[1]
    slugs = sys.argv[2:]
    for slug in slugs:
        texts, data, st = build(slug)
        if cmd == "build":
            (DATA / f"{slug}.colorlayer.json").write_text(json.dumps(
                {"slug": slug, "text": texts, "runs": data}, ensure_ascii=False))
        if cmd in ("build", "check"):
            pre, placed = st["letters-pre"], st["letters-placed"]
            pct = 100.0 * placed / pre if pre else 100.0
            print(f"{slug:<12} coloured-letters={pre:<7} placed={placed:<7} {pct:6.2f}%  "
                  f"ayahs={st['ayahs']:<5} runs={st['runs']}")
        elif cmd == "legend":
            cc = collections.Counter()
            for su in data.values():
                for r in su.values():
                    for lo, hi, c in r:
                        cc[c] += hi - lo + 1
            print(f"== {slug} ==")
            for c, n in cc.most_common():
                print("   #%06x  %7d chars" % (c, n))


if __name__ == "__main__":
    main()
