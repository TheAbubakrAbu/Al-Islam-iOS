"""Record where the volumes PRINT the bayna-bayna dot, for the tajweed layer to draw.

One dot glyph does two jobs (see `final.ishmam_dot`), and the TEXT can only carry one of
them honestly:

* **ishmam** - the dot stands in the vowel slot of `قِيلَ` and its six companions, so the
  text gets the U+0650 it replaced. Correct as text, but the fact that the print marked
  the word is then invisible.
* **tasheel** - the dot annotates the softened second hamza of the `ءَأَ` interrogatives,
  whose letters are all written already, so the text gets nothing at all.

Either way the annotation is lost unless it is written down here.
`Scripts/build_tajweed_v2.py` already carries an `ishmam_sad` rule for the orange
صراط/زاي blend and reads its flags as (surah, ayah, word index); these rows use the same
shape, so `ishmam_kasr` and `tasheel_hamz` companions can consume them directly.

Rows are MERGED into the existing file, so a volume whose segments are not currently built
keeps whatever was recorded for it last time.

    python3 ishmam.py hisham ibndhakwan       # -> data/ishmam-kasr.json
"""
import sys, json, pathlib, collections
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import final, extract

# The family is per VOLUME, not a constant: the Yaqub pair draws this dot too (glyph
# Hamdy4#98), and rendering their words through the Kufi map wrote `قِيلا` into the
# snapshot where the volume itself reads `قِيلَ`.
DATA = pathlib.Path(__file__).resolve().parent / "data"
OUT = DATA / "ishmam-kasr.json"

def main(slugs):
    maps, ctxs = {}, {}
    out = json.loads(OUT.read_text()) if OUT.exists() else {}
    for slug in slugs:
        FAM = final.FAMILY[slug]
        if FAM not in maps:
            maps[FAM] = final.build_detmap(FAM)
            ctxs[FAM] = json.loads((DATA / f"ctxdet-{FAM}.json").read_text())
        detmap, ctx = maps[FAM], ctxs[FAM]
        p = DATA / f"{slug}.surahs.json"
        if not p.exists():
            keep = len(out.get(slug, {}).get("ishmam", [])) + \
                   len(out.get(slug, {}).get("tasheel", []))
            print(f"  {slug:12} no segments; keeping {keep} recorded row(s)")
            continue
        rows = {"ishmam": [], "tasheel": []}
        forms = collections.defaultdict(collections.Counter)
        for sid, surah in enumerate(json.loads(p.read_text())["data"], 1):
            for aid, glyphs in enumerate(surah, 1):
                for wi, w in enumerate(extract.glyph_words(glyphs)):
                    hits = [i for i, (f, c) in enumerate(w)
                            if f != "sp" and any(g in f"{f}|{c}"
                                                 for g in final.ISHMAM_GIDS)]
                    if not hits:
                        continue
                    word = final.render_det(w, detmap, None, FAM, ctx, slug)
                    # Ask the SAME question `final.ishmam_dot` asks, on the same prefix:
                    # what letter does the first dot actually cap? Matching on the whole
                    # word instead would call `ءَاعۡجَمِيّٞ` ishmam for the jeem in its
                    # middle, which is the wrong letter entirely.
                    prefix = final.render_det(w[:hits[0]], detmap, None, FAM, ctx, slug)
                    kind = "ishmam" if final.ishmam_dot([("", prefix)]) else "tasheel"
                    rows[kind].append([sid, aid, wi, word])
                    forms[kind][word] += 1
        out[slug] = rows
        for kind in ("ishmam", "tasheel"):
            top = ", ".join(f"{w} x{n}" for w, n in forms[kind].most_common(6))
            print(f"  {slug:12} {kind:8} {len(rows[kind]):>3} words   {top}")
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1))
    tot = sum(len(v[k]) for v in out.values() for k in ("ishmam", "tasheel"))
    print(f"wrote {OUT.relative_to(OUT.parent.parent)} ({tot} rows over {len(out)} volumes)")

if __name__ == "__main__":
    main(sys.argv[1:] or ("hisham", "ibndhakwan"))
