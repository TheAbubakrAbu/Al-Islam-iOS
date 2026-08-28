"""Audit every mark emission against the glyph's real ink position.

Arabic tashkeel splits cleanly by zone: fatha, damma, shadda, sukoon, fathatain,
dammatain, maddah and the dagger alef are drawn ABOVE the baseline; kasra and
kasratain are drawn BELOW it. So a glyph whose outline sits entirely above the
baseline can never be a kasra, and vice versa. Any detmap entry that violates this
is mismapped - which is exactly how a shadda became a kasra and produced `فَجٍِ`
for `فَجٍّ` in the shipped text.

Reports violations; --render writes a contact sheet so each one can be eyeballed.
"""
import sys, io, json, pathlib
import fitz
from fontTools.ttLib import TTFont
from fontTools.pens.boundsPen import BoundsPen

DATA = pathlib.Path(__file__).resolve().parent / "data"
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from extract import pdf_path
BRIDGE = "shubah"   # any Kufi volume embeds the same HQPB font programs

ABOVE = set("ًٌَُّْٰٓٗ")
BELOW = set("ٍِٖ")


def font_xrefs(doc, wanted=("HQPB1", "HQPB2", "HQPB3", "HQPB4", "HQPB5", "Hamd2")):
    """Resolve embedded-font xrefs BY NAME, keeping EVERY subset of each name.

    They must never be hardcoded: the repo's `Resources/Mushaf PDFs/*.pdf.xz` copies were
    re-serialised by the size optimisation, so their xref numbering differs from the
    archive.org originals even though the glyphs are identical.

    A volume embeds each font several times over, one subset per page range, and a subset
    carries an outline only for the gids its own pages draw. Reading the first subset alone
    reports every glyph drawn later in the book as having no outline, which this audit
    cannot tell apart from a genuine spacer - so it would silently skip them. Collect them
    all; `bounds` takes the first that has ink.
    """
    out = {}
    for pno in range(doc.page_count):
        for f in doc[pno].get_fonts(full=True):
            xref, base = f[0], f[3]
            short = base.split("+", 1)[-1]
            if short in wanted and xref not in out.setdefault(short, []):
                out[short].append(xref)
    return out

def glyphsets():
    """{font name: [(glyf table, glyph order), ...]}, one entry per embedded subset."""
    doc = fitz.open(pdf_path(BRIDGE))
    out = {}
    for name, xrefs in font_xrefs(doc).items():
        subs = []
        for xref in xrefs:
            try:
                _, _, _, buf = doc.extract_font(xref)
                # Outlines need no advance widths, and a subset whose `hmtx` is short of
                # what `hhea` promises cannot build a glyph set at all - so read `glyf`.
                ft = TTFont(io.BytesIO(buf), ignoreDecompileErrors=True)
                subs.append((ft["glyf"], ft.getGlyphOrder()))
            except Exception as exc:
                print(f"  (subset {xref} of {name} unreadable: {exc})")
        if subs:
            out[name] = subs
        else:
            print(f"  (no font for {name})")
    return out

def draw(subsets, gid, pen):
    """Draw gid from the first subset that inks it; True if any did."""
    for glyf, order in subsets:
        if gid >= len(order):
            continue
        bp = BoundsPen(None)
        glyf[order[gid]].draw(bp, glyf)
        if bp.bounds:
            glyf[order[gid]].draw(pen, glyf)
            return True
    return False

def bounds(subsets, gid):
    pen = BoundsPen(None)
    return pen.bounds if draw(subsets, gid, pen) else None

def main():
    gsets = glyphsets()
    # build it rather than reading a stale artefact: detmap-*.json is generated output
    import final
    detmap = final.build_detmap("kufi")
    violations = []
    for key, emit in detmap.items():
        if not emit or not isinstance(emit, str):
            continue
        body = key[3:] if key.startswith("CL|") else key
        if "||" in body:
            continue                      # cluster glyph: several marks, zone test n/a
        head = body.rsplit("|", 1)[0]
        if "#" not in head:
            continue
        font, gid = head.split("#", 1)
        if font not in gsets or not gid.isdigit():
            continue
        marks = [c for c in emit if c in ABOVE or c in BELOW]
        if not marks or any(c not in ABOVE and c not in BELOW for c in emit):
            continue                      # letters present: not a pure mark glyph
        b = bounds(gsets[font], int(gid))
        if not b:
            continue
        ymin, ymax = b[1], b[3]
        zone = "above" if ymin >= 0 else ("below" if ymax <= 0 else "spans")
        if zone == "spans":
            continue
        wants_above = any(c in ABOVE for c in marks)
        wants_below = any(c in BELOW for c in marks)
        if zone == "above" and wants_below and not wants_above:
            violations.append((key, emit, zone, ymin, ymax, font, int(gid)))
        elif zone == "below" and wants_above and not wants_below:
            violations.append((key, emit, zone, ymin, ymax, font, int(gid)))
    print(f"zone violations: {len(violations)}")
    for key, emit, zone, ymin, ymax, font, gid in sorted(violations, key=lambda v: (v[5], v[6])):
        print(f"  {font}#{gid:<4} ink {zone:5} (y {ymin:.0f}..{ymax:.0f})  maps to {emit!r}   key={key!r}")
    (DATA / "zonebad.json").write_text(
        json.dumps(sorted(v[0] for v in violations), ensure_ascii=False, indent=1))
    print(f"wrote {DATA/'zonebad.json'}")
    if "--render" in sys.argv and violations:
        spec = [[v[5], v[6], f"maps to {v[1]!r}"] for v in violations]
        (DATA / "zonespec.json").write_text(json.dumps(spec, ensure_ascii=False))
        print(f"\nwrote {DATA/'zonespec.json'} ({len(spec)} glyphs) for rendering")

if __name__ == "__main__":
    main()
