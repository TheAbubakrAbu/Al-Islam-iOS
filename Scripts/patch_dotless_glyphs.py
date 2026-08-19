#!/usr/bin/env python3
"""Give the bundled Quran faces real dotless-skeleton letters, in place.

WHY: "Hide Arabic Dots" maps letters to the Unicode skeleton codepoints
(U+06A1 dotless feh, U+066F dotless qaf, U+06BA dotless noon, U+066E dotless
beh), but the KFGQPC faces either omitted them from the cmap (Warsh, Indopak)
or - worse - mapped them to junk glyphs (Uthmani points U+06A1 at a FOOTNOTE
MARKER composite and U+066F at a sign shape, which also blocks system-font
fallback because a cmap hit suppresses it). The app therefore forced the
system face whenever dots were hidden. This script builds proper dotless
glyphs so the classical faces can render the skeleton text themselves:

  * every needed positional form (isol/init/medi/fina) of feh, qaf, and noon
    is CLONED from the font's own dotted glyph with its dot contour(s)
    deleted - the contour indices below were verified visually per glyph
    (Scripts note: dots are always separate contours in these faces; the
    small mid-glyph contours are the head-loop holes and must be kept);
  * where the font already draws a dotless form (Uthmani bsa/bsi/bsm/bsf,
    Warsh's Maghribi-style dotless isolated feh/qaf and uniFBE8/9/_252,
    Indopak's complete u066E set), the existing glyph is reused;
  * cmap entries for U+06A1 / U+066F / U+06BA are added (or repointed off
    the junk glyphs), and init/medi/fina single-substitution mappings are
    added so the letters join correctly mid-word;
  * U+066E gains the final form both Uthmani (bsa->bsf) and Warsh
    (uni066E->_252) always had glyphs for but never mapped.

Idempotent: a font that already has the marker glyph name is skipped.
Run:  python3 Scripts/patch_dotless_glyphs.py
Then REBOOT the simulator before visual verification - in-place ttf edits
poison the sim's font cache (stale mixed glyphs until reboot).
"""

import sys
from pathlib import Path

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
FONTS_DIR = ROOT / "Resources" / "Fonts"

MARKER = "dotlessFeh"  # presence of this glyph name = font already patched

# Per font: strip-clones, straight clones, glyph reuses, cmap, and GSUB adds.
# strip = (source glyph, contour indices to DELETE, new glyph name)
SPECS = {
    "Uthmani.ttf": {
        "strip": [
            ("afii57441", [0], "dotlessFeh"),
            ("afii57441.init", [2], "dotlessFeh.init"),
            ("afii57441.zz03", [2], "dotlessFeh.medi"),
            ("afii57441.zz04", [2], "dotlessFeh.fina"),
            ("afii57442", [0], "dotlessQaf"),
            ("afii57442.init", [2], "dotlessQaf.init"),
            ("afii57442.zz03", [2], "dotlessQaf.medi"),
            ("afii57442.zz04", [2], "dotlessQaf.fina"),
            ("afii57446", [0], "dotlessNoon"),
            ("afii57446.zz04", [1], "dotlessNoon.fina"),
        ],
        "clone": [],
        "cmap": {0x06A1: "dotlessFeh", 0x066F: "dotlessQaf", 0x06BA: "dotlessNoon"},
        "gsub": {
            "init": {"dotlessFeh": "dotlessFeh.init", "dotlessQaf": "dotlessQaf.init",
                     "dotlessNoon": "bsi"},
            "medi": {"dotlessFeh": "dotlessFeh.medi", "dotlessQaf": "dotlessQaf.medi",
                     "dotlessNoon": "bsm"},
            "fina": {"dotlessFeh": "dotlessFeh.fina", "dotlessQaf": "dotlessQaf.fina",
                     "dotlessNoon": "dotlessNoon.fina", "bsa": "bsf"},
        },
    },
    "Warsh.ttf": {
        # Isolated/final feh and qaf (and noon) are already dotless in this
        # Maghribi face - clone them so no glyph-keyed rule ever diverges.
        "strip": [
            ("uniFED3", [2], "dotlessFeh.init"),
            ("uniFED4", [2], "dotlessFeh.medi"),
            ("uniFED7", [0], "dotlessQaf.init"),
            ("uniFED8", [0], "dotlessQaf.medi"),
        ],
        "clone": [
            ("feh", "dotlessFeh"),
            ("uniFED2", "dotlessFeh.fina"),
            ("qaf", "dotlessQaf"),
            ("uniFED6", "dotlessQaf.fina"),
            ("noon", "dotlessNoon"),
            ("uniFEE6", "dotlessNoon.fina"),
        ],
        "cmap": {0x06A1: "dotlessFeh", 0x066F: "dotlessQaf", 0x06BA: "dotlessNoon"},
        "gsub": {
            "init": {"dotlessFeh": "dotlessFeh.init", "dotlessQaf": "dotlessQaf.init",
                     "dotlessNoon": "uniFBE8"},
            "medi": {"dotlessFeh": "dotlessFeh.medi", "dotlessQaf": "dotlessQaf.medi",
                     "dotlessNoon": "uniFBE9"},
            "fina": {"dotlessFeh": "dotlessFeh.fina", "dotlessQaf": "dotlessQaf.fina",
                     "dotlessNoon": "dotlessNoon.fina", "uni066E": "_252"},
        },
    },
    "Indopak.ttf": {
        "strip": [
            ("u0641", [0], "dotlessFeh"),
            ("uFED3", [1], "dotlessFeh.init"),
            ("uFED4", [0], "dotlessFeh.medi"),
            ("uFED2", [1], "dotlessFeh.fina"),
            ("u0642", [0, 1], "dotlessQaf"),
            ("uFED7", [0], "dotlessQaf.init"),
            ("uFED8", [0], "dotlessQaf.medi"),
            ("uFED6", [0], "dotlessQaf.fina"),
            ("u0646", [1], "dotlessNoon"),
            ("uFEE6", [1], "dotlessNoon.fina"),
        ],
        "clone": [],
        "cmap": {0x06A1: "dotlessFeh", 0x066F: "dotlessQaf", 0x06BA: "dotlessNoon"},
        "gsub": {
            "init": {"dotlessFeh": "dotlessFeh.init", "dotlessQaf": "dotlessQaf.init",
                     "dotlessNoon": "u0649.init"},
            "medi": {"dotlessFeh": "dotlessFeh.medi", "dotlessQaf": "dotlessQaf.medi",
                     "dotlessNoon": "u0649.medi"},
            # u066E already maps to u066E.fina in this font; nothing to add there.
            "fina": {"dotlessFeh": "dotlessFeh.fina", "dotlessQaf": "dotlessQaf.fina",
                     "dotlessNoon": "dotlessNoon.fina"},
        },
    },
}


def rebuilt_without_contours(glyf_table, source_name, remove):
    """A new simple Glyph = `source_name`'s outline minus the given contours."""
    from fontTools.ttLib.tables._g_l_y_f import Glyph, GlyphCoordinates

    src = glyf_table[source_name]
    assert not src.isComposite(), f"{source_name} is composite; strip needs a simple glyph"
    coords, ends, flags = src.getCoordinates(glyf_table)

    new_coords, new_flags, new_ends = [], [], []
    start = 0
    for idx, end in enumerate(ends):
        pts = list(coords[start:end + 1])
        fls = list(flags[start:end + 1])
        start = end + 1
        if idx in remove:
            continue
        new_coords.extend(pts)
        new_flags.extend(fls)
        new_ends.append(len(new_coords) - 1)

    from fontTools.ttLib.tables import ttProgram

    glyph = Glyph()
    glyph.numberOfContours = len(new_ends)
    glyph.coordinates = GlyphCoordinates(new_coords)
    glyph.flags = bytearray(new_flags)
    glyph.endPtsOfContours = new_ends
    glyph.program = ttProgram.Program()
    glyph.program.fromBytecode(b"")
    glyph.recalcBounds(glyf_table)
    return glyph


def clone_glyph(glyf_table, source_name):
    """A deep copy of a glyph (simple or composite) via decompile/compile."""
    from fontTools.ttLib.tables._g_l_y_f import Glyph

    src = glyf_table[source_name]
    data = src.compile(glyf_table)
    out = Glyph(data)
    out.expand(glyf_table)
    return out


def add_glyph(font, name, glyph, metrics_source):
    glyf = font["glyf"]
    hmtx = font["hmtx"]
    order = font.getGlyphOrder()
    if name in order:
        raise SystemExit(f"glyph {name} already exists")
    font.setGlyphOrder(order + [name])
    glyf[name] = glyph
    hmtx[name] = hmtx[metrics_source]
    # New letters behave like their dotted sources for shaping classification.
    if "GDEF" in font:
        gdef = font["GDEF"].table
        if gdef.GlyphClassDef:
            classes = gdef.GlyphClassDef.classDefs
            if metrics_source in classes:
                classes[name] = classes[metrics_source]


def feature_lookup_with(font, feature_tag, existing_key):
    """The SingleSubst subtable of `feature_tag` that already maps `existing_key`
    (so new entries land in a lookup that is actually applied for the script)."""
    gsub = font["GSUB"].table
    for record in gsub.FeatureList.FeatureRecord:
        if record.FeatureTag != feature_tag:
            continue
        for lookup_index in record.Feature.LookupListIndex:
            lookup = gsub.LookupList.Lookup[lookup_index]
            for subtable in lookup.SubTable:
                if subtable.LookupType == 7:  # Extension
                    subtable = subtable.ExtSubTable
                mapping = getattr(subtable, "mapping", None)
                if mapping is not None and existing_key in mapping:
                    return mapping
    return None


def patch(path, spec):
    font = TTFont(str(path))
    if MARKER in font.getGlyphOrder():
        print(f"  {path.name}: already patched, skipping")
        return False

    glyf = font["glyf"]
    for source, remove, new_name in spec["strip"]:
        add_glyph(font, new_name, rebuilt_without_contours(glyf, source, set(remove)), source)
    for source, new_name in spec["clone"]:
        add_glyph(font, new_name, clone_glyph(glyf, source), source)

    for table in font["cmap"].tables:
        if not table.isUnicode():
            continue
        for codepoint, name in spec["cmap"].items():
            table.cmap[codepoint] = name

    # The init/medi/fina lookups key on the BASE (isolated) glyph; anchor the
    # insert on feh's own entry so new mappings land in the lookup the script
    # system actually applies.
    feh_base = font.getBestCmap()[0x0641]

    for tag, additions in spec["gsub"].items():
        mapping = feature_lookup_with(font, tag, feh_base)
        if mapping is None:
            raise SystemExit(f"{path.name}: no {tag} SingleSubst lookup found for feh")
        for key, value in additions.items():
            mapping[key] = value

    font.save(str(path))
    print(f"  {path.name}: patched ({len(spec['strip'])} stripped, "
          f"{len(spec['clone'])} cloned, cmap +{len(spec['cmap'])})")
    return True


def main():
    changed = 0
    for filename, spec in SPECS.items():
        path = FONTS_DIR / filename
        if not path.exists():
            sys.exit(f"missing font: {path}")
        if patch(path, spec):
            changed += 1
    print(f"done: {changed} font(s) patched")


if __name__ == "__main__":
    main()
