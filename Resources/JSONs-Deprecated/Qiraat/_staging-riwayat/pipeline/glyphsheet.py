import fitz, io, sys, json
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.boundsPen import BoundsPen
import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from extract import pdf_path
d=fitz.open(pdf_path(__import__('os').environ.get('GLYPH_VOLUME','shubah')))

def font_xrefs(doc, wanted=("HQPB1", "HQPB2", "HQPB3", "HQPB4", "HQPB5", "HQPB6",
                            "HQPB7", "Hamd2", "Hamdy2", "Hamdy4", "Hamdy5", "MSH-Quraan1",
                            "MshQuraan1")):
    """Resolve embedded-font xrefs BY NAME, and keep EVERY subset of each name.

    They must never be hardcoded: the repo's `Resources/Mushaf PDFs/*.pdf.xz` copies were
    re-serialised by the size optimisation, so their xref numbering differs from the
    archive.org originals even though the glyphs are identical.

    A volume embeds the same font several times over (six subsets of each in the Khalaf
    al-Ashir volumes, one per page range), and a subset carries an outline only for the
    gids its own pages draw. Reading the FIRST subset alone therefore reports a glyph as
    blank whenever it happens to be drawn later in the book - which is indistinguishable
    from the genuine spacers of `fixdrops.SPACER_GIDS` and would retire a real letter as
    page furniture. Collect them all and let `gsfor` take the first one that has ink.
    """
    out = {}
    for pno in range(doc.page_count):
        for f in doc[pno].get_fonts(full=True):
            xref, base = f[0], f[3]
            short = base.split("+", 1)[-1]
            if short in wanted and xref not in out.setdefault(short, []):
                out[short].append(xref)
    return out

cache={}
def gsfor(f):
    """Every embedded subset of font `f`, in page order, as (glyf, glyphOrder) pairs."""
    if f not in cache:
        out=[]
        for xref in font_xrefs(d)[f]:
            fn,ext,typ,buf=d.extract_font(xref)
            ft=TTFont(io.BytesIO(buf), ignoreDecompileErrors=True)
            # Outlines need no advance widths, and a subset whose `hmtx` is short of what
            # `hhea` promises cannot build a glyph set at all - so draw off `glyf` direct.
            out.append((ft["glyf"], ft.getGlyphOrder()))
        cache[f]=out
    return cache[f]

def draw_glyph(f, g, pen):
    """Draw gid `g` from the first subset that actually inks it. See font_xrefs.

    An empty cell therefore means the gid has no outline in ANY subset, which is the real
    spacer test - see `fixdrops.SPACER_GIDS`.
    """
    for glyf, order in gsfor(f):
        if g >= len(order):
            continue
        bp = BoundsPen(None)
        glyf[order[g]].draw(bp, glyf)
        if bp.bounds:
            glyf[order[g]].draw(pen, glyf)
            return True
    return False

spec=json.loads(sys.argv[1]); out=sys.argv[2]
cols=6; cw=300; ch=340
rows=(len(spec)+cols-1)//cols
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{cols*cw}" height="{rows*ch}"><rect width="100%" height="100%" fill="white"/>']
for i,(f,g,note) in enumerate(spec):
    cx=(i%cols)*cw; cy=(i//cols)*ch
    base=cy+170
    pen=SVGPathPen(None); draw_glyph(f,g,pen)
    svg.append(f'<rect x="{cx+2}" y="{cy+2}" width="{cw-6}" height="{ch-6}" fill="none" stroke="#ccc"/>')
    svg.append(f'<line x1="{cx+15}" y1="{base}" x2="{cx+cw-15}" y2="{base}" stroke="red" stroke-width="1.5"/>')
    svg.append(f'<g transform="translate({cx+110},{base}) scale(0.075,-0.075)"><path d="{pen.getCommands()}" fill="black"/></g>')
    svg.append(f'<text x="{cx+12}" y="{cy+ch-40}" font-size="26" font-family="monospace">{f}#{g}</text>')
    svg.append(f'<text x="{cx+12}" y="{cy+ch-14}" font-size="22" font-family="monospace" fill="#0066cc">{note}</text>')
svg.append('</svg>')
open('/tmp/g.svg','w').write(''.join(svg))
doc=fitz.open('pdf', fitz.open('/tmp/g.svg').convert_to_pdf())
doc[0].get_pixmap(dpi=100).save(out)
print('wrote', out)
