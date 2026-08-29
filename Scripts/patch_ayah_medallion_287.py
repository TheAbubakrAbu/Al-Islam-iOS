#!/usr/bin/env python3
"""Add the ayah-number medallion for 287 to the KFGQPC faces, in place.
WHY: the faces draw every ayah number as ONE pre-built medallion glyph - a
composite of uni06DD (the ornament) and small digit glyphs at hand-placed
offsets - selected by an `rlig` ligature over the plain digits, and the set
stops at 286, Hafs' largest ayah number. The Basri count gives al-Baqarah
287 ayahs, so the four riwayat on that count (ad-Duri, as-Susi, Ruways,
Rawh) printed 2:287 as TWO medallions, "٢٨" and "٧" (the longest ligature
match, then the leftover digit). The page reader and the list rows both set
the number in the Hafs face; the Maghribi script style sets the whole Quran
in the Warsh face, so both get the glyph.
HOW: 287 = a copy of the 286 composite with its last component swapped for
the small 7, placed 312 units right of the 8 - the 8-to-7 spacing the face
itself uses in 187 - which lands the digit group's centre where 286's is.
One ligature entry (2 8 7 -> the new glyph) goes in FRONT of the two-digit
"2 8" entry of the same lookup, so the longer match wins.
Idempotent: a face is skipped when the glyph already exists.
Run:  python3 Scripts/patch_ayah_medallion_287.py [fonts-dir]
Then REBOOT the simulator before visual verification (in-place ttf edits
poison the sim's font cache).
"""
import copy
import sys
from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import otTables

FONTS_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "Resources" / "Fonts"
NEW_NUMBER = 287
EIGHT_TO_SEVEN = 312  # the face's own 8->7 offset (187: a008@531, a007@843)


def digit_glyphs(font):
    cmap = font.getBestCmap()
    return {d: cmap[0x0660 + d] for d in range(10)}


def number_ligatures(font):
    """number -> (lookup index, subtable, ligature) for every all-digit ligature."""
    digits = digit_glyphs(font)
    by_glyph = {g: d for d, g in digits.items()}
    found = {}
    for li, lookup in enumerate(font["GSUB"].table.LookupList.Lookup):
        for st in lookup.SubTable:
            if lookup.LookupType == 7:
                st = st.ExtSubTable
            if st.__class__.__name__ != "LigatureSubst":
                continue
            for first, ligs in st.ligatures.items():
                if first not in by_glyph:
                    continue
                for lig in ligs:
                    if all(c in by_glyph for c in lig.Component):
                        num = int(str(by_glyph[first]) + "".join(str(by_glyph[c]) for c in lig.Component))
                        found[num] = (li, st, lig)
    return found


def patch(font, label):
    digits = digit_glyphs(font)
    ligs = number_ligatures(font)
    if NEW_NUMBER in ligs:
        return False
    if 286 not in ligs or 187 not in ligs:
        raise SystemExit(f"{label}: no 286/187 medallion ligature - not a KFGQPC number face")
    li, subtable, lig286 = ligs[286]
    base = font["glyf"][lig286.LigGlyph]
    if not base.isComposite() or len(base.components) != 4:
        raise SystemExit(f"{label}: unexpected 286 glyph shape")
    order = font.getGlyphOrder()
    # Name it the way the face names its neighbours (..._<8>_<6> -> ..._<8>_<7>) where the 286
    # name ends in the digit glyph's name (Uthmani: a002_a008_a007); otherwise suffix "_287".
    name = lig286.LigGlyph[: -len(digits[6])] + digits[7] if lig286.LigGlyph.endswith(digits[6]) else lig286.LigGlyph + "_287"
    if name in order:
        raise SystemExit(f"{label}: glyph {name} exists but no 287 ligature points at it")

    glyph = copy.deepcopy(base)
    eight = next(c for c in glyph.components if c.glyphName == digits[8])
    last = next(c for c in glyph.components if c.glyphName == digits[6])
    last.glyphName = digits[7]
    last.x = eight.x + EIGHT_TO_SEVEN
    last.y = eight.y
    font.setGlyphOrder(order + [name])
    font["glyf"][name] = glyph
    glyph.recalcBounds(font["glyf"])
    font["hmtx"][name] = font["hmtx"][lig286.LigGlyph]
    classes = font["GDEF"].table.GlyphClassDef.classDefs
    if lig286.LigGlyph in classes:
        classes[name] = classes[lig286.LigGlyph]
    font.getReverseGlyphMap(rebuild=True)

    new = otTables.Ligature()
    new.Component = [digits[8], digits[7]]
    new.LigGlyph = name
    ligature_set = subtable.ligatures[digits[2]]
    ligature_set.insert(0, new)  # ahead of the shorter "2 8" entry: the longer match must win
    print(f"  {label}: {name} = {', '.join(f'{c.glyphName}@({c.x},{c.y})' for c in glyph.components)} in lookup {li}")
    return True


def main():
    fonts = {name: FONTS_DIR / f"{name}.ttf" for name in ("Uthmani", "Warsh")}
    for path in fonts.values():
        if not path.exists():
            sys.exit(f"missing font: {path}")
    changed = 0
    for label, path in fonts.items():
        font = TTFont(str(path))
        if patch(font, label):
            font.save(str(path))
            changed += 1
            print(f"  {label}.ttf: patched")
        else:
            print(f"  {label}.ttf: already patched, skipping")
    print(f"done: {changed} font(s) patched")


if __name__ == "__main__":
    main()
