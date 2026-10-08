#!/usr/bin/env python3
"""Remove the baked ٱللَّه (Allah) word-ligature from Uthmani.ttf, in place.
WHY: the face bakes the whole name into ONE glyph (`Allah`), reached by a
ligature in the `calt` lookup 5 over three contextual variants:
    afii57444.init + afii57444.zz03 + afii57470.zz04  ->  Allah
While the name is a single glyph it cannot be addressed letter by letter, so
the laam of Allah cannot be painted on its own - which is what the heavy/light
laam (tafkheem vs tarqeeq) tajweed rule needs: the laam is heavy after a
fatha or damma (ٱللَّهُ) and light after a kasra (بِٱللَّهِ). Dropping the bake
makes the name shape from its component letters, each with its own range.
HOW: the ligature's three components are all UNENCODED contextual variants
already produced by other `calt` lookups (the init/medial/final forms of laam
and heh), so removing only this one ligature entry leaves the shaping intact -
the name renders from the same variant glyphs, just unmerged. The `Allah`
glyph itself is left in the font: nothing else reaches it once the ligature is
gone, and keeping it avoids touching the glyph order (which `patch_dotless_
glyphs.py` and the medallion patches index into).
Only Uthmani.ttf carries this bake; the other seven faces have no `Allah`
glyph at all, so they are skipped.
NOTE: the components are 1946 units wide against the ligature's 1746, so every
word carrying the name gets ~10% wider. That moves the mushaf page fits, so
`MushafReader.fitterVersion` must be bumped in the same change or pages keep
serving fits measured against the merged glyph.
Idempotent: a face with no `Allah` ligature is reported and left alone.
Run:  python3 Scripts/patch_allah_ligature.py [fonts-dir]
Then REBOOT the simulator before visual verification (in-place ttf edits
poison the sim's font cache).
"""
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

FONTS_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "Resources" / "Fonts"
TARGET = "Allah"


def allah_ligatures(font):
    """(lookup index, first glyph, subtable, ligature) for every ligature building `Allah`."""
    found = []
    try:
        gsub = font["GSUB"].table
    except KeyError:
        return found
    for index, lookup in enumerate(gsub.LookupList.Lookup):
        if lookup.LookupType != 4:  # ligature substitution
            continue
        for subtable in lookup.SubTable:
            for first, ligatures in getattr(subtable, "ligatures", {}).items():
                for ligature in ligatures:
                    if ligature.LigGlyph == TARGET:
                        found.append((index, first, subtable, ligature))
    return found


def strip(path):
    font = TTFont(path)
    matches = allah_ligatures(font)
    if not matches:
        if TARGET in font.getGlyphOrder():
            print(f"{path.name}: has the {TARGET} glyph but no ligature reaches it - already patched")
        else:
            print(f"{path.name}: no {TARGET} bake, skipped")
        return False

    for index, first, subtable, ligature in matches:
        components = " + ".join((first,) + tuple(ligature.Component))
        subtable.ligatures[first] = [lig for lig in subtable.ligatures[first] if lig is not ligature]
        if not subtable.ligatures[first]:
            del subtable.ligatures[first]
        print(f"{path.name}: removed lookup {index}  {components} -> {TARGET}")

    font.save(path)
    return True


def main():
    if not FONTS_DIR.is_dir():
        sys.exit(f"not a directory: {FONTS_DIR}")
    patched = [path for path in sorted(FONTS_DIR.glob("*.ttf")) if strip(path)]
    print(f"\npatched {len(patched)} face(s)")
    if patched:
        print("Now bump MushafReader.fitterVersion - the name's glyph advance changed.")


if __name__ == "__main__":
    main()
