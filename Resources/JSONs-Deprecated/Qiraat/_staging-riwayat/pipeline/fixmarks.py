"""Correct mark glyphs whose learned emission is wrong, verified by rendering the
glyph outline and reading it: several HQPB4 marks are COMBINED shadda+vowel glyphs
(or a bare shadda) that the EM alignment collapsed onto the vowel alone - or, for
gid 71, onto a kasra, which is what produced the `فَجٍِ` for `فَجٍّ` corruption.

Keys are looked up by font#gid prefix because the trailing ToUnicode char is often a
control character that cannot be typed literally.
"""
import json, pathlib, sys

DATA = pathlib.Path(__file__).resolve().parent / "data"

SHADDA = "ّ"
WANT = {
    "HQPB4#117": SHADDA + "ُ",   # shadda + damma
    "HQPB4#112": SHADDA + "ُ",   # shadda + damma
    "HQPB4#130": SHADDA + "َ",   # shadda + fatha
}

WANT["HQPB4#71"] = SHADDA          # bare shadda, was mapped to kasra

# NOT auto-forced: HQPB4 gids 65,67,68,69,70,73,74,75,76,77,79,80,81,82 are all the same
# "shadda" outline at climbing stack heights (ink y-min 666 -> 2554), and every one is
# mapped to kasra even though kasra is drawn BELOW the baseline and these sit above it.
# They are still wrong - but they are not uniformly wrong. Forcing the whole family:
#     -> bare shadda      55.55%  (kills the kasra these words also need)
#     -> shadda + kasra   78.00%  (doubles the kasra where another glyph supplies it)
#     -> left alone       88.91%
# Whether the kasra arrives with the shadda or from a separate glyph is positional, which
# is what ctxdet learns per neighbour-pair. Fix these by re-running ctxpass over the
# corrected base map, never by a blanket override.

def main():
    counts = json.loads((DATA / "glyphcounts-kufi.json").read_text())
    manual = json.loads((DATA / "manualmap.json").read_text())
    hits = 0
    for key in counts:
        body = key[3:] if key.startswith("CL|") else key
        gid = body.rsplit("|", 1)[0]
        if gid in WANT:
            manual[key] = WANT[gid]
            hits += 1
            print(f"  {gid:12} -> {WANT[gid]!r}   (key repr {key!r})")
    (DATA / "manualmap.json").write_text(
        json.dumps(manual, ensure_ascii=False, indent=1, sort_keys=True))
    print(f"patched {hits} keys; manualmap now {len(manual)} entries")

if __name__ == "__main__":
    main()
