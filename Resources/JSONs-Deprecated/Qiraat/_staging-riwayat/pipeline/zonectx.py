"""Zone-audit the CONTEXT map, not just the detmap.

`zoneaudit.py` checks `detmap`, but `render_det` consults `ctxdet-<family>.json` FIRST, so a
glyph can be zone-correct in the detmap and still render as the wrong mark. That is exactly
what the HQPB4 shadda ladder does:

    مِّن  =  [HQPB4#176 kasra-stroke, ink BELOW]  [HQPB4#75 shadda, ink ABOVE]

The print emits the pair in that order; Unicode writes shadda first. Rather than reorder,
the learner simply **swapped the two emissions** (#176 -> shadda, #75 -> kasra), which
produces the right string for the pair and nonsense for every ladder glyph that appears
without its partner.

This reports, per key, what fraction of its ctx rules emit a mark whose zone contradicts
the glyph's ink.

    python3 zonectx.py            # report
    python3 zonectx.py --write    # write data/zoneflip.json for final.py to consume
"""
import sys, io, json, pathlib, collections
import fitz
from fontTools.ttLib import TTFont
from fontTools.pens.boundsPen import BoundsPen

HERE = pathlib.Path(__file__).resolve().parent
DATA = HERE / "data"
sys.path.insert(0, str(HERE))
from extract import pdf_path
import zoneaudit

ABOVE, BELOW = zoneaudit.ABOVE, zoneaudit.BELOW
FAM = "kufi"

def zone_of(gsets, font, gid):
    if font not in gsets:
        return None
    gs, order = gsets[font]
    b = zoneaudit.bounds(gs, order, gid)
    if not b:
        return None
    ymin, ymax = b[1], b[3]
    if ymin >= 0:
        return "above"
    if ymax <= 0:
        return "below"
    return "spans"

def mark_zone(emit):
    """above / below / None for a pure-mark emission."""
    if not emit or any(c not in ABOVE and c not in BELOW for c in emit):
        return None
    if any(c in BELOW for c in emit) and not any(c in ABOVE for c in emit):
        return "below"
    if any(c in ABOVE for c in emit) and not any(c in BELOW for c in emit):
        return "above"
    return None      # mixed (shadda+kasra) is legitimately both

def main():
    gsets = zoneaudit.glyphsets()
    ctx = json.loads((DATA / f"ctxdet-{FAM}.json").read_text())
    rows = []
    for key, rules in ctx.items():
        body = key[3:] if key.startswith("CL|") else key
        if "||" in body:
            continue
        head = body.rsplit("|", 1)[0]
        if "#" not in head:
            continue
        font, gid = head.split("#", 1)
        if not gid.isdigit():
            continue
        z = zone_of(gsets, font, int(gid))
        if z in (None, "spans"):
            continue
        bad = collections.Counter()
        good = 0
        for _, emit in rules.items():
            mz = mark_zone(emit)
            if mz is None:
                continue
            if mz != z:
                bad[emit] += 1
            else:
                good += 1
        if bad:
            rows.append((font, int(gid), key, z, sum(bad.values()), good, dict(bad)))
    rows.sort(key=lambda r: -r[4])
    print(f"keys whose ctx emits a zone-contradicting mark: {len(rows)}")
    for font, gid, key, z, nbad, ngood, bad in rows:
        print(f"  {font}#{gid:<4} ink {z:5}  {nbad:4} contradicting / {ngood:4} consistent  {bad}")
    if "--write" not in sys.argv:
        return
    # Resolve each contradicting key to ONE zone-consistent emission.
    #
    #   ink above -> the bare shadda. Every ink-above row here is the same shadda outline
    #                drawn at a different stack height (rendered and eyeballed, all 15).
    #   ink below -> that key's own majority zone-consistent emission, which is the kasra
    #                it really is; the shadda votes are the paired-context flip.
    out, skipped = {}, []
    for font, gid, key, z, nbad, ngood, bad in rows:
        if z == "above":
            out[key] = "\u0651"
            continue
        good = collections.Counter()
        for _, emit in ctx[key].items():
            if mark_zone(emit) == z:
                good[emit] += 1
        if not good:
            skipped.append(f"{font}#{gid}")
            continue
        out[key] = good.most_common(1)[0][0]
    (DATA / "zoneflip.json").write_text(json.dumps(out, ensure_ascii=False, indent=1, sort_keys=True))
    print(f"wrote {DATA/'zoneflip.json'} ({len(out)} keys)")
    if skipped:
        print(f"  no zone-consistent evidence, left alone: {', '.join(skipped)}")

if __name__ == "__main__":
    main()
