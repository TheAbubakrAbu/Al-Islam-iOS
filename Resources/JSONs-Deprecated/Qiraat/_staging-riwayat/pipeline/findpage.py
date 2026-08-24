"""Locate the printed page holding a given ayah, and render it (or a crop) to PNG.

The pipeline flattens all 604 pages into one glyph stream, so nothing downstream knows
where an ayah sits on paper. This walks pages counting ayah-end markers, which is the only
page-anchored signal in the volumes, and stops at the Nth marker.

    python3 findpage.py khallad 2 62 /tmp/p.png          whole page
    python3 findpage.py khallad 2 62 /tmp/p.png 0.55 0.8  crop between those height fractions
"""
import sys, json, pathlib
import fitz
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import extract

def ordinal(sid, aid):
    """Absolute ayah index (1-based) in a 6236-count volume."""
    counts = json.loads(
        (extract.APP / "Resources/JSONs-Deprecated/Quran.json").read_text())
    n = 0
    for s in counts:
        if s["id"] == sid:
            return n + aid
        n += len(s["ayahs"])
    raise ValueError(sid)

def main():
    slug, sid, aid, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    y0 = float(sys.argv[5]) if len(sys.argv) > 5 else 0.0
    y1 = float(sys.argv[6]) if len(sys.argv) > 6 else 1.0
    target = ordinal(sid, aid)
    doc = fitz.open(extract.pdf_path(slug))
    seen = 0
    for pno in range(doc.page_count):
        page = doc[pno]
        # Ayah numbers are drawn as ∩digits∪; extract_stream assembles them across the
        # whole document, so count the page-anchored OPEN BRACKET glyph instead.
        marks = 0
        for _, kind, payload in extract.page_tokens(page):
            if kind == "mark":
                marks += 1
            elif kind not in ("sp",) and isinstance(payload, tuple) and len(payload) == 2:
                if extract._bracket_kind(payload[0]) == "open":
                    marks += 1
        if seen + marks >= target:
            print(f"{slug} {sid}:{aid} -> ayah #{target}, page index {pno} "
                  f"(printed page ~{pno + 1}); this page holds ayahs "
                  f"#{seen + 1}..#{seen + marks}")
            r = page.rect
            clip = fitz.Rect(r.x0, r.y0 + (r.y1 - r.y0) * y0,
                             r.x1, r.y0 + (r.y1 - r.y0) * y1)
            page.get_pixmap(dpi=200, clip=clip).save(out)
            print("wrote", out)
            return
        seen += marks
    print("not found")

if __name__ == "__main__":
    main()
