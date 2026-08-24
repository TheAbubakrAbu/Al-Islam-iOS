import fitz, io, sys, json
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from extract import pdf_path
d=fitz.open(pdf_path(__import__('os').environ.get('GLYPH_VOLUME','shubah')))

def font_xrefs(doc, wanted=("HQPB1", "HQPB2", "HQPB3", "HQPB4", "HQPB5", "Hamd2")):
    """Resolve embedded-font xrefs BY NAME.

    They must never be hardcoded: the repo's `Resources/Mushaf PDFs/*.pdf.xz` copies were
    re-serialised by the size optimisation, so their xref numbering differs from the
    archive.org originals even though the glyphs are identical.
    """
    out = {}
    for pno in range(min(doc.page_count, 120)):
        for f in doc[pno].get_fonts(full=True):
            xref, base = f[0], f[3]
            short = base.split("+", 1)[-1]
            if short in wanted and short not in out:
                out[short] = xref
        if len(out) == len(wanted):
            break
    return out

cache={}
def gsfor(f):
    if f not in cache:
        fn,ext,typ,buf=d.extract_font(font_xrefs(d)[f]); ft=TTFont(io.BytesIO(buf))
        cache[f]=(ft.getGlyphSet(), ft.getGlyphOrder())
    return cache[f]
spec=json.loads(sys.argv[1]); out=sys.argv[2]
cols=6; cw=300; ch=340
rows=(len(spec)+cols-1)//cols
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{cols*cw}" height="{rows*ch}"><rect width="100%" height="100%" fill="white"/>']
for i,(f,g,note) in enumerate(spec):
    gs,order=gsfor(f)
    cx=(i%cols)*cw; cy=(i//cols)*ch
    base=cy+170
    pen=SVGPathPen(gs); gs[order[g]].draw(pen)
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
