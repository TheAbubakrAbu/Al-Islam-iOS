#!/usr/bin/env python3
"""Close the Quran-codepoint gaps in the bundled classical faces, in place.

WHY: every Quran text the app can show (Hafs, the seven KFGQPC riwayat, the
twelve beta riwayat, the runtime dotless skeletons) was audited against each
bundled face's cmap and mark anchoring (2026-08-26). A codepoint a face lacks
falls back to the system font mid-word: a thin Geeza Pro glyph in a KFGQPC
line. The gaps, and what this script does about them:

  Uthmani.ttf  U+0622 (alef madda, 8 uses: Ibn Wardan, Duri, Susi, "Aal
               Imran") had no cmap entry although the font carries the glyph
               (afii57410 + its final form). cmap only.
  Warsh.ttf    U+0671 alef wasla (13,500 per Hafs-style text) - the Maghribi
               face never needed it because the KFGQPC Warsh text writes wasl
               as alef + U+06EC dot. Built as composites (alef + the face's
               own wasl dot) with a final form and lam-alef ligature forms.
               U+06DA/U+06DB (waqf jeem / three dots) and U+06ED (iqlab low
               meem) - outlines borrowed from the sister KFGQPC Hafs face,
               anchored like the face's own uni06D6 / dot-below marks.
               U+06E4 (sajdah overline) had an outline but no anchor and so
               never showed - anchored at waqf height.
  Indopak.ttf  U+065E (the sequential fathatan, ~1,800 per text) missing -
               drawn as the face's fathatan, the way IndoPak mushafs print
               it. U+065C (imaalah kubra dot below) missing - the beh's own
               dot placed like the kasra. U+06DF (rounded zero) was an
               EMPTY glyph - a smaller copy of the round sukun. U+00A0 - cmap.
  Kufi.ttf     U+06EC (wasl / filled high dot, ~10,000 per dot-wasl text)
               missing - the face's own dot-below raised to sukun height.

Idempotent: each face is skipped when its marker is already present.
Run:  python3 Scripts/patch_quran_font_coverage.py [fonts-dir]
Then REBOOT the simulator before visual verification (in-place ttf edits
poison the sim's font cache).
"""

import copy
import sys
from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._g_l_y_f import Glyph, GlyphCoordinates, GlyphComponent
from fontTools.ttLib.tables import ttProgram

ROOT = Path(__file__).resolve().parent.parent
FONTS_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "Resources" / "Fonts"


# ----------------------------------------------------------------------------
# glyph helpers

def simple_glyph(contours):
    """A simple Glyph from [(points, flags), ...]; points are (x, y) ints."""
    coords, flags, ends = [], [], []
    for pts, fls in contours:
        coords.extend(pts)
        flags.extend(fls)
        ends.append(len(coords) - 1)
    g = Glyph()
    g.numberOfContours = len(ends)
    g.coordinates = GlyphCoordinates([(int(round(x)), int(round(y))) for x, y in coords])
    g.flags = bytearray(flags)
    g.endPtsOfContours = ends
    g.program = ttProgram.Program()
    g.program.fromBytecode(b"")
    return g


def contours_of(glyf, name, dx=0, dy=0, scale=1.0, cx=0, cy=0, keep=None):
    """[(points, flags)] of a glyph's outline (components resolved), optionally
    scaled about (cx, cy) and translated; `keep` = contour indices to keep."""
    src = glyf[name]
    coords, ends, flags = src.getCoordinates(glyf)
    out, start = [], 0
    for idx, end in enumerate(ends):
        pts = [(cx + (x - cx) * scale + dx, cy + (y - cy) * scale + dy)
               for x, y in coords[start:end + 1]]
        fls = list(flags[start:end + 1])
        start = end + 1
        if keep is None or idx in keep:
            out.append((pts, fls))
    return out


def composite_glyph(parts):
    """A composite Glyph from [(componentName, dx, dy), ...]."""
    g = Glyph()
    g.numberOfContours = -1
    g.components = []
    for name, dx, dy in parts:
        c = GlyphComponent()
        c.glyphName = name
        c.x, c.y = int(dx), int(dy)
        c.flags = 0x0004 | 0x0200  # ROUND_XY_TO_GRID | UNSCALED_COMPONENT_OFFSET
        g.components.append(c)
    g.program = ttProgram.Program()
    g.program.fromBytecode(b"")
    return g


def add_glyph(font, name, glyph, advance, lsb, gdef_class):
    order = font.getGlyphOrder()
    if name in order:
        raise SystemExit(f"glyph {name} already exists")
    font.setGlyphOrder(order + [name])
    font["glyf"][name] = glyph
    if glyph.isComposite():
        glyph.recalcBounds(font["glyf"])
    else:
        glyph.recalcBounds(font["glyf"])
    font["hmtx"][name] = (int(advance), int(lsb))
    classes = font["GDEF"].table.GlyphClassDef.classDefs
    classes[name] = gdef_class
    # keep fontTools' name<->id caches coherent after a glyph-order change
    font.getReverseGlyphMap(rebuild=True)


def bbox(glyf, name):
    g = glyf[name]
    g.recalcBounds(glyf)
    return g.xMin, g.yMin, g.xMax, g.yMax


# ----------------------------------------------------------------------------
# GPOS helpers (coverage arrays must stay sorted by glyph id, records parallel)

def _subtables(gpos, types):
    for li, lookup in enumerate(gpos.LookupList.Lookup):
        for st in lookup.SubTable:
            if st.LookupType == 9:
                st = st.ExtSubTable
            if st.LookupType in types:
                yield li, st


def _sorted_insert(font, coverage, records, name, record):
    gid = font.getGlyphID(name)
    ids = [font.getGlyphID(g) for g in coverage.glyphs]
    pos = len(ids)
    for i, other in enumerate(ids):
        if other > gid:
            pos = i
            break
    coverage.glyphs.insert(pos, name)
    records.insert(pos, record)


def clone_mark_records(font, source, new, anchor_xy=None):
    """Give `new` the same mark class as `source` in every MarkBase / MarkLig /
    MarkMark (mark1) subtable that covers `source`, with the source's anchor
    (or `anchor_xy`). Returns the number of subtables touched."""
    gpos = font["GPOS"].table
    touched = 0
    for _, st in _subtables(gpos, (4, 5)):
        if source in st.MarkCoverage.glyphs:
            rec = copy.deepcopy(st.MarkArray.MarkRecord[st.MarkCoverage.glyphs.index(source)])
            if anchor_xy is not None:
                rec.MarkAnchor.XCoordinate, rec.MarkAnchor.YCoordinate = anchor_xy
            _sorted_insert(font, st.MarkCoverage, st.MarkArray.MarkRecord, new, rec)
            touched += 1
    for _, st in _subtables(gpos, (6,)):
        if source in st.Mark1Coverage.glyphs:
            rec = copy.deepcopy(st.Mark1Array.MarkRecord[st.Mark1Coverage.glyphs.index(source)])
            if anchor_xy is not None:
                rec.MarkAnchor.XCoordinate, rec.MarkAnchor.YCoordinate = anchor_xy
            _sorted_insert(font, st.Mark1Coverage, st.Mark1Array.MarkRecord, new, rec)
            touched += 1
    return touched


def clone_mark2_records(font, source, new, anchor_xy=None):
    """Mark-to-mark: let other marks stack on `new` the way they stack on `source`."""
    gpos = font["GPOS"].table
    touched = 0
    for _, st in _subtables(gpos, (6,)):
        if source in st.Mark2Coverage.glyphs:
            rec = copy.deepcopy(st.Mark2Array.Mark2Record[st.Mark2Coverage.glyphs.index(source)])
            if anchor_xy is not None:
                for a in rec.Mark2Anchor:
                    if a is not None:
                        a.XCoordinate, a.YCoordinate = anchor_xy
            _sorted_insert(font, st.Mark2Coverage, st.Mark2Array.Mark2Record, new, rec)
            touched += 1
    return touched


def clone_ligature_attach(font, source, new):
    """MarkLig: `new` (a composite over `source`) takes the source ligature's
    per-component anchors."""
    gpos = font["GPOS"].table
    touched = 0
    for _, st in _subtables(gpos, (5,)):
        if source in st.LigatureCoverage.glyphs:
            att = copy.deepcopy(st.LigatureArray.LigatureAttach[st.LigatureCoverage.glyphs.index(source)])
            _sorted_insert(font, st.LigatureCoverage, st.LigatureArray.LigatureAttach, new, att)
            touched += 1
    return touched


def clone_base_records(font, source, new):
    gpos = font["GPOS"].table
    touched = 0
    for _, st in _subtables(gpos, (4,)):
        if source in st.BaseCoverage.glyphs:
            rec = copy.deepcopy(st.BaseArray.BaseRecord[st.BaseCoverage.glyphs.index(source)])
            _sorted_insert(font, st.BaseCoverage, st.BaseArray.BaseRecord, new, rec)
            touched += 1
    return touched


def mark_record(font, mark, lookup_index):
    """(class, (x, y)) of `mark` in the given MarkBase/MarkLig lookup."""
    gpos = font["GPOS"].table
    for li, st in _subtables(gpos, (4, 5)):
        if li == lookup_index and mark in st.MarkCoverage.glyphs:
            rec = st.MarkArray.MarkRecord[st.MarkCoverage.glyphs.index(mark)]
            return rec.Class, (rec.MarkAnchor.XCoordinate, rec.MarkAnchor.YCoordinate)
    raise SystemExit(f"{mark} not a mark in lookup {lookup_index}")


def base_anchor(font, base, lookup_index, klass):
    gpos = font["GPOS"].table
    for li, st in _subtables(gpos, (4,)):
        if li == lookup_index and base in st.BaseCoverage.glyphs:
            a = st.BaseArray.BaseRecord[st.BaseCoverage.glyphs.index(base)].BaseAnchor[klass]
            return (a.XCoordinate, a.YCoordinate) if a else None
    return None


def ligature_component_anchor(font, lig, mark, component):
    """Anchor of `component` on ligature `lig` for the class `mark` belongs to,
    from the first MarkLig subtable covering both."""
    gpos = font["GPOS"].table
    for _, st in _subtables(gpos, (5,)):
        if mark in st.MarkCoverage.glyphs and lig in st.LigatureCoverage.glyphs:
            klass = st.MarkArray.MarkRecord[st.MarkCoverage.glyphs.index(mark)].Class
            att = st.LigatureArray.LigatureAttach[st.LigatureCoverage.glyphs.index(lig)]
            a = att.ComponentRecord[component].LigatureAnchor[klass]
            if a is not None:
                return (a.XCoordinate, a.YCoordinate)
    return None


# ----------------------------------------------------------------------------
# GSUB helpers

def single_subst_mapping(font, feature_tag, existing_key):
    gsub = font["GSUB"].table
    for record in gsub.FeatureList.FeatureRecord:
        if record.FeatureTag != feature_tag:
            continue
        for li in record.Feature.LookupListIndex:
            for st in gsub.LookupList.Lookup[li].SubTable:
                if st.LookupType == 7:
                    st = st.ExtSubTable
                mapping = getattr(st, "mapping", None)
                if mapping is not None and existing_key in mapping:
                    return mapping
    raise SystemExit(f"no {feature_tag} SingleSubst maps {existing_key}")


def ligature_set(font, feature_tag, first, existing_component):
    """The LigatureSubst `ligatures` dict of the lookup that already ligates
    `first` + `existing_component`."""
    from fontTools.ttLib.tables import otTables
    gsub = font["GSUB"].table
    for record in gsub.FeatureList.FeatureRecord:
        if record.FeatureTag != feature_tag:
            continue
        for li in record.Feature.LookupListIndex:
            for st in gsub.LookupList.Lookup[li].SubTable:
                if st.LookupType == 7:
                    st = st.ExtSubTable
                ligs = getattr(st, "ligatures", None)
                if ligs and first in ligs and any(l.Component == [existing_component] for l in ligs[first]):
                    return ligs
    raise SystemExit(f"no {feature_tag} ligature {first}+{existing_component}")


def add_ligature(ligatures, first, components, lig_glyph):
    from fontTools.ttLib.tables import otTables
    lig = otTables.Ligature()
    lig.Component = list(components)
    lig.CompCount = len(components) + 1
    lig.LigGlyph = lig_glyph
    # longer sequences must precede shorter ones with the same prefix; ours is one component
    ligatures.setdefault(first, []).append(lig)


def set_cmap(font, codepoint, name):
    for table in font["cmap"].tables:
        if table.isUnicode():
            table.cmap[codepoint] = name


# ----------------------------------------------------------------------------
# per-face patches

def patch_uthmani(font):
    if 0x0622 in font.getBestCmap():
        return False
    set_cmap(font, 0x0622, "afii57410")  # alef madda; fina form already mapped in GSUB
    return True


def patch_warsh(font, hafs):
    glyf = font["glyf"]
    if "uni0671" in font.getGlyphOrder():
        return False
    hglyf = hafs["glyf"]

    # --- U+0671: alef + the face's own wasl dot ("up" = U+06EC) ---------------
    up_class, up_anchor = mark_record(font, "up", 2)
    for base, new in (("arabicalef", "uni0671"), ("uniFE8E", "uni0671.fina")):
        ba = base_anchor(font, base, 2, up_class)
        adv, lsb = font["hmtx"][base]
        add_glyph(font, new, composite_glyph([(base, 0, 0), ("up", ba[0] - up_anchor[0], ba[1] - up_anchor[1])]),
                  adv, lsb, 1)
        clone_base_records(font, base, new)
    set_cmap(font, 0x0671, "uni0671")
    single_subst_mapping(font, "fina", "arabicalef")["uni0671"] = "uni0671.fina"
    # lam + alef wasla ligates like lam + alef, with the dot over the alef stem
    for lam, lig in (("uniFEDF", "uniFEFB"), ("uniFEE0", "uniFEFC")):
        anchor = ligature_component_anchor(font, lig, "up", 1)
        if anchor is None:
            x0, y0, x1, y1 = bbox(glyf, lig)
            anchor = (x0 + 110, y1 + 60)
        adv, lsb = font["hmtx"][lig]
        new = lig + ".wasl"
        add_glyph(font, new, composite_glyph([(lig, 0, 0), ("up", anchor[0] - up_anchor[0], anchor[1] - up_anchor[1])]),
                  adv, lsb, 2)
        clone_ligature_attach(font, lig, new)
        add_ligature(ligature_set(font, "liga", lam, "uniFE8E"), lam, ["uni0671.fina"], new)

    # --- U+06DA / U+06DB / U+06E4 at waqf height (like uni06D6) ---------------
    waqf_class, waqf_anchor = mark_record(font, "uni06D6", 2)
    for cp, name, hafs_lookup in ((0x06DA, "uni06DA", 6), (0x06DB, "uni06DB", 6)):
        _, hanchor = mark_record(hafs, name, hafs_lookup)
        dx, dy = waqf_anchor[0] - hanchor[0], waqf_anchor[1] - hanchor[1]
        g = simple_glyph(contours_of(hglyf, name, dx, dy))
        add_glyph(font, name, g, 0, g.xMin if hasattr(g, "xMin") else 0, 3)
        font["hmtx"][name] = (0, bbox(glyf, name)[0])
        clone_mark_records(font, "uni06D6", name)
        set_cmap(font, cp, name)
    # the sajdah overline already has an outline (96..555 x 643..819); anchor its bottom-centre
    x0, y0, x1, y1 = bbox(glyf, "uni06E4")
    clone_mark_records(font, "uni06D6", "uni06E4", anchor_xy=((x0 + x1) // 2, y0))

    # --- U+06ED iqlab low meem, hung below like the face's dot-below ---------
    down_class, down_anchor = mark_record(font, "down", 2)
    x0, y0, x1, y1 = bbox(hglyf, "uni06ED")
    dx = down_anchor[0] - (x0 + x1) // 2
    dy = (down_anchor[1] - 40) - y1
    g = simple_glyph(contours_of(hglyf, "uni06ED", dx, dy))
    add_glyph(font, "uni06ED", g, 0, 0, 3)
    font["hmtx"]["uni06ED"] = (0, bbox(glyf, "uni06ED")[0])
    clone_mark_records(font, "down", "uni06ED")
    set_cmap(font, 0x06ED, "uni06ED")
    return True


def patch_indopak(font):
    glyf = font["glyf"]
    if "u065E" in font.getGlyphOrder():
        return False
    cmap = font.getBestCmap()
    set_cmap(font, 0x00A0, cmap[0x0020])

    # U+065E sequential fathatan := the face's fathatan (IndoPak mushafs draw one tanween)
    g = simple_glyph(contours_of(glyf, "u064B"))
    add_glyph(font, "u065E", g, *font["hmtx"]["u064B"], 3)
    clone_mark_records(font, "u064B", "u065E")
    clone_mark2_records(font, "u064B", "u065E")
    set_cmap(font, 0x065E, "u065E")

    # U+065C imaalah dot below := the beh's dot, centred where the kasra sits
    bx0, by0, bx1, by1 = bbox(glyf, "u0628")
    dot = contours_of(glyf, "u0628", keep={1})
    (dxs, dys) = zip(*[p for pts, _ in dot for p in pts])
    dcx, dcy = (min(dxs) + max(dxs)) / 2, (min(dys) + max(dys)) / 2
    kx0, ky0, kx1, ky1 = bbox(glyf, "u0650")
    kcx, kcy = (kx0 + kx1) / 2, (ky0 + ky1) / 2
    g = simple_glyph(contours_of(glyf, "u0628", kcx - dcx, kcy - dcy, keep={1}))
    add_glyph(font, "u065C", g, 0, 0, 3)
    font["hmtx"]["u065C"] = (0, bbox(glyf, "u065C")[0])
    clone_mark_records(font, "u0650", "u065C")
    clone_mark2_records(font, "u0650", "u065C")
    set_cmap(font, 0x065C, "u065C")

    # U+06DF rounded zero: the empty glyph gets a 70% copy of the round sukun
    sx0, sy0, sx1, sy1 = bbox(glyf, "u0652")
    scx, scy = (sx0 + sx1) / 2, (sy0 + sy1) / 2
    glyf["u06DF"] = simple_glyph(contours_of(glyf, "u0652", scale=0.7, cx=scx, cy=scy))
    glyf["u06DF"].recalcBounds(glyf)
    font["hmtx"]["u06DF"] = (0, glyf["u06DF"].xMin)
    return True


def patch_kufi(font):
    glyf = font["glyf"]
    if 0x06EC in font.getBestCmap():
        return False
    sx0, sy0, sx1, sy1 = bbox(glyf, "uni0652")
    dx0, dy0, dx1, dy1 = bbox(glyf, "uni065C")
    g = simple_glyph(contours_of(glyf, "uni065C", 0, sy0 - dy0))
    add_glyph(font, "uni06EC", g, 0, 0, 3)
    font["hmtx"]["uni06EC"] = (0, bbox(glyf, "uni06EC")[0])
    top = bbox(glyf, "uni06EC")[3]
    clone_mark_records(font, "uni0652", "uni06EC")
    clone_mark2_records(font, "uni0652", "uni06EC", anchor_xy=(0, top + 5))
    set_cmap(font, 0x06EC, "uni06EC")
    return True


def main():
    fonts = {name: FONTS_DIR / f"{name}.ttf" for name in ("Uthmani", "Warsh", "Indopak", "Kufi")}
    for path in fonts.values():
        if not path.exists():
            sys.exit(f"missing font: {path}")
    loaded = {name: TTFont(str(path)) for name, path in fonts.items()}
    changed = []
    if patch_uthmani(loaded["Uthmani"]):
        changed.append("Uthmani")
    if patch_warsh(loaded["Warsh"], TTFont(str(fonts["Uthmani"]))):
        changed.append("Warsh")
    if patch_indopak(loaded["Indopak"]):
        changed.append("Indopak")
    if patch_kufi(loaded["Kufi"]):
        changed.append("Kufi")
    for name in changed:
        loaded[name].save(str(fonts[name]))
        print(f"  {name}.ttf: patched")
    for name in fonts:
        if name not in changed:
            print(f"  {name}.ttf: already patched, skipping")
    print(f"done: {len(changed)} font(s) patched")


if __name__ == "__main__":
    main()
