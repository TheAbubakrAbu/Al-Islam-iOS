#!/usr/bin/env python3
"""Remove the baked بِـَٔا (baa, kasra, tatweel, hamza, fatha, alif) ligature from Uthmani.ttf, in place.
WHY: the face draws بِـَٔا (بِـَٔايَٰتِ and its family, 119 places) as ONE glyph, `gly025`,
reached by a ligature in GSUB lookup 4:
    afii57416.init + afii57456 + afii57440 + uni0654 + afii57454 + afii57415.zz04  ->  gly025
A glyph takes one colour, so the madd of the alif inside it either vanished (4.6.5: the glyph
showed the plain baa's colour) or spread over the baa as well (4.6.6 Save 9:
`FontGlyphs.colourWholeGlyphs` gave the whole glyph the madd colour). Abu, 2026-10-31: the
gold baa looked wrong. Unbaked, the baa stays plain and only the hamza and alif carry the madd.
HOW: every component is a glyph the face already produces on its own, and the unmerged word
draws in the same shape (checked with CoreText side by side). The `gly025` glyph is left in the
font: nothing reaches it once the ligature is gone, and keeping it leaves the glyph order alone
(which `patch_dotless_glyphs.py` and the medallion patches index into).
NOT the lam-alif madd bakes (laa02..laa06, لۡأٓ of ٱلۡأٓخِرَةِ): unbaked, their maddah stacks
above the hamza and the word draws taller; Abu kept them baked.
Only Uthmani.ttf carries this bake; the other faces are reported and skipped.
Idempotent: a face with no `gly025` ligature is reported and left alone.
Run:  python3 Scripts/patch_bi_hamza_alif_ligature.py [fonts-dir]
Then bump `MushafReader.fitterVersion` and REBOOT the simulator before visual verification
(in-place ttf edits poison the sim's font cache).
"""
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

FONTS_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "Resources" / "Fonts"
TARGET = "gly025"


def target_ligatures(font):
    """(lookup index, first glyph, subtable, ligature) for every ligature building `gly025`."""
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
    matches = target_ligatures(font)
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
        print("Now bump MushafReader.fitterVersion - the word's glyph advances changed.")


if __name__ == "__main__":
    main()
