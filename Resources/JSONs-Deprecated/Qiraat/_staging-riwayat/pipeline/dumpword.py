"""Dump the glyph keys of one word in one ayah, with each key's detmap emission."""
import sys, json
sys.path.insert(0, ".")
import final, extract

FAM = "kufi"

def main():
    slug, sid, aid, needle = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    detmap = final.build_detmap(FAM)
    ctx = json.loads(open(f"data/ctxdet-{FAM}.json").read())
    seg = json.loads(open(f"data/{slug}.surahs.json").read())
    glyphs = seg["data"][sid - 1][aid - 1]
    truth = extract.overlay(extract.BRIDGES[slug]) if slug in extract.BRIDGES else None
    if truth:
        exp = dict(truth[sid]).get(aid, "")
        print("expected:", exp)
    for w in extract.glyph_words(glyphs):
        r = final.render_det(w, detmap, None, FAM, ctx)
        if needle not in r:
            continue
        print("rendered:", repr(r))
        for f, c in w:
            key = "sp| " if f == "sp" else f"{f}|{c}"
            print(f"   {key!r:44} -> {detmap.get(key)!r}")
        print()

if __name__ == "__main__":
    main()
