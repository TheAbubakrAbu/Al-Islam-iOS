#!/usr/bin/env python3
"""Build Resources/Fonts/Hijazi.ttf ("Al-Islam Hijazi") from Scripts/fonts/hijazi-upstream.ttf.

UPSTREAM: https://github.com/khalidalabdullah/hijazifont - Khalid Alabdullah's digital model
of the historical Hijazi script (the hand of the earliest mushafs). Licensed CC BY-NC 4.0; the
licence is declared inside the font's own name table (ids 13/14), not in the repository.

WHY A BUILD: the upstream face is faithful to the manuscripts - dotless letters, no hamza, and
every tashkeel / Quranic-annotation codepoint mapped to an EMPTY glyph - so vocalised Quran text
renders as bare rasm and the dotless skeleton codepoints fall back to the system font. The app
offers the full Quran character set in every face it ships, so this build ADDS, drawing every
new shape from the face's own stems or as scaled copies of its own letters (nothing is imported
from another font, which keeps the whole file under the one upstream licence):

  * harakat, both tanween sets (stacked + the KFGQPC sequential forms U+0656/0657/065E),
    shadda, both sukuns, maddah, dagger alef, hamza above/below, imaalah dots, wasl dot
  * the annotation set U+06D6-U+06ED (waqf signs, small high letters, sajdah, rub el hizb,
    zeros, the small waw / ya)
  * a standalone hamza (U+0621) and hamza on its carriers (U+0623/0624/0625/0626) as composites,
    alef madda (U+0622), the wasl sign on U+0671 (with lam-alef ligature forms)
  * the dotless skeleton codepoints U+066E/066F/06A1/06BA (the face is dotless already, so they
    share the letters' glyphs), the Arabic-Indic digits, NBSP
  * GPOS mark-to-base and mark-to-mark positioning (the upstream has none), anchors computed
    from every base glyph's outline

Always rebuilds from the upstream file (idempotent by construction).
Run:  python3 Scripts/build_hijazi_font.py [--variant N] [out.ttf]

MARK STYLES (--variant; all three ship as one typeface, "Hijazi", to the app's pickers, the
style being chosen on the row beneath the Quran font picker; the letters are identical in all
three, only the marks differ):
  2  the default build described above, light monoline marks -> Hijazi.ttf, AlIslamHijazi-Regular
  3  the same build with the marks at the letters' own stroke weight
                                                          -> Hijazi3.ttf, AlIslamHijazi3-Regular
  4  the vowels as the dots of the earliest vocalised mushafs (Abu al-Aswad's system: a dot
     above = fatha, below = kasra, before the letter = damma, doubled for tanween); shadda,
     sukun, madd and hamza stay as in 2 so the text stays readable
                                                          -> Hijazi4.ttf, AlIslamHijazi4-Regular
(Variant 1 of the 2026-08-26 comparison set, the upstream as drawn, was dropped: with every
mark an empty glyph it can never show tashkeel. The unmodified upstream remains this script's
input at Scripts/fonts/hijazi-upstream.ttf, so nothing of it is lost.)
Then REBOOT the simulator before visual verification (font-cache poisoning on ttf edits).
"""

import math
import sys
from pathlib import Path

from fontTools.otlLib import builder as otl
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import otTables as ot
from fontTools.ttLib.tables import ttProgram
from fontTools.ttLib.tables._g_l_y_f import Glyph, GlyphComponent, GlyphCoordinates

ROOT = Path(__file__).resolve().parent.parent
UPSTREAM = ROOT / "Scripts" / "fonts" / "hijazi-upstream.ttf"

_args = sys.argv[1:]
VARIANT = 2
if "--variant" in _args:
    _i = _args.index("--variant")
    VARIANT = int(_args[_i + 1])
    del _args[_i:_i + 2]
if VARIANT not in (2, 3, 4):
    sys.exit("--variant must be 2, 3 or 4")
FILE_NAME = "Hijazi.ttf" if VARIANT == 2 else f"Hijazi{VARIANT}.ttf"
OUT = Path(_args[0]) if _args else ROOT / "Resources" / "Fonts" / FILE_NAME

FAMILY = "Al-Islam Hijazi" if VARIANT == 2 else f"Al-Islam Hijazi {VARIANT}"
PS_NAME = "AlIslamHijazi-Regular" if VARIANT == 2 else f"AlIslamHijazi{VARIANT}-Regular"
VERSION = "Version 1.100"
VARIANT_NOTE = {2: "", 3: "; variant 3: marks at the letters' own weight",
                4: "; variant 4: dot vowels (Abu al-Aswad's system)"}[VARIANT]
HEAVY = VARIANT == 3   # marks at the letters' own weight
DOTS = VARIANT == 4    # dot vowels

T = 100 if HEAVY else 58          # mark stroke thickness (letters are ~130)
GAP_ABOVE = 80 if HEAVY else 70   # clearance between a base's top and an above-mark
GAP_BELOW = 70 if HEAVY else 60
STACK_GAP = 40 if HEAVY else 34   # clearance between stacked marks
FATHA_LEN = 300 if HEAVY else 250  # fatha / kasra length
DAMMA_S = 0.44 if HEAVY else 0.35  # damma = the face's own waw at this scale
DOT_R = 58 if HEAVY else 46        # imaalah / wasl dot radius
VOWEL_R = 54                       # variant 4's vowel dots
SMALL = 1.15 if HEAVY else 1.0     # small-letter / annotation sign scale multiplier
HAMZA_S = 0.82 if HEAVY else 0.70  # hamza-above/below scale
RING_W = 52 if HEAVY else 42       # sukun ring wall


# ----------------------------------------------------------------------------
# outline primitives - a contour is [(x, y, onCurve), ...], clockwise when filled

def _cw(points):
    area = sum(x0 * y1 - x1 * y0 for (x0, y0), (x1, y1) in zip(points, points[1:] + points[:1]))
    return points if area < 0 else points[::-1]


def poly(points):
    return [[(x, y, 1) for x, y in _cw(points)]]


def circle(cx, cy, r, hole=False):
    k = r / math.cos(math.pi / 8)
    pts = []
    for i in range(8):
        a = -i * math.pi / 4           # clockwise
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a), 1))
        b = a - math.pi / 8
        pts.append((cx + k * math.cos(b), cy + k * math.sin(b), 0))
    return [pts[::-1] if hole else pts]


def ring(cx, cy, r_out, r_in):
    return circle(cx, cy, r_out) + circle(cx, cy, r_in, hole=True)


def rect(x0, y0, x1, y1):
    return poly([(x0, y0), (x0, y1), (x1, y1), (x1, y0)])


def rect_ring(x0, y0, x1, y1, w):
    outer = poly([(x0, y0), (x0, y1), (x1, y1), (x1, y0)])[0]
    inner = poly([(x0 + w, y0 + w), (x0 + w, y1 - w), (x1 - w, y1 - w), (x1 - w, y0 + w)])[0]
    return [outer, inner[::-1]]


def stroke(points, w=T, closed=False):
    """Round-capped, round-joined stroke of a polyline: overlapping clockwise pieces."""
    out = []
    segs = list(zip(points, points[1:] + ([points[0]] if closed else [])))
    for (x0, y0), (x1, y1) in segs:
        dx, dy = x1 - x0, y1 - y0
        n = math.hypot(dx, dy) or 1.0
        px, py = -dy / n * w / 2, dx / n * w / 2
        out += poly([(x0 + px, y0 + py), (x1 + px, y1 + py), (x1 - px, y1 - py), (x0 - px, y0 - py)])
    for x, y in points:
        out += circle(x, y, w / 2)
    return out


def arc_points(cx, cy, r, a0, a1, n=10):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def translate(contours, dx, dy):
    return [[(x + dx, y + dy, f) for x, y, f in c] for c in contours]


def scale(contours, s, cx=0, cy=0):
    return [[(cx + (x - cx) * s, cy + (y - cy) * s, f) for x, y, f in c] for c in contours]


def bounds(contours):
    xs = [x for c in contours for x, _, _ in c]
    ys = [y for c in contours for _, y, _ in c]
    return min(xs), min(ys), max(xs), max(ys)


def glyph_from(contours):
    coords, flags, ends = [], [], []
    for c in contours:
        for x, y, f in c:
            coords.append((int(round(x)), int(round(y))))
            flags.append(1 if f else 0)
        ends.append(len(coords) - 1)
    g = Glyph()
    g.numberOfContours = len(ends)
    g.coordinates = GlyphCoordinates(coords)
    g.flags = bytearray(flags)
    g.endPtsOfContours = ends
    g.program = ttProgram.Program()
    g.program.fromBytecode(b"")
    return g


def mark_mark_subtable(marks, stack, glyph_map, class_count):
    """MarkMarkPos format 1 (fontTools has no one-call builder for it)."""
    st = ot.MarkMarkPos()
    st.Format = 1
    st.ClassCount = class_count
    st.Mark1Coverage = otl.buildCoverage(marks, glyph_map)
    st.Mark1Array = otl.buildMarkArray(marks, glyph_map)
    mark2 = sorted(stack, key=glyph_map.__getitem__)
    st.Mark2Coverage = otl.buildCoverage(mark2, glyph_map)
    st.Mark2Array = ot.Mark2Array()
    st.Mark2Array.Mark2Record = [otl.buildMark2Record([stack[g].get(c) for c in range(class_count)]) for g in mark2]
    st.Mark2Array.Mark2Count = len(mark2)
    return st


def composite(parts):
    g = Glyph()
    g.numberOfContours = -1
    g.components = []
    for name, dx, dy in parts:
        c = GlyphComponent()
        c.glyphName = name
        c.x, c.y = int(round(dx)), int(round(dy))
        c.flags = 0x0004 | 0x0200  # ROUND_XY_TO_GRID | UNSCALED_COMPONENT_OFFSET
        g.components.append(c)
    g.program = ttProgram.Program()
    g.program.fromBytecode(b"")
    return g


# ----------------------------------------------------------------------------
# the build

class Build:
    def __init__(self):
        self.font = TTFont(str(UPSTREAM))
        self.glyf = self.font["glyf"]
        self.hmtx = self.font["hmtx"]
        self.gdef = self.font["GDEF"].table.GlyphClassDef.classDefs
        self.cmap_tables = [t for t in self.font["cmap"].tables if t.isUnicode()]
        self.marks = {}      # glyph name -> ("above" | "below", top_or_bottom_for_stacking)
        self.pending_bases = {}   # glyph name -> custom anchor overrides

    # -- glyph access ------------------------------------------------------------
    def outline(self, name):
        """[(x, y, on)] contours of an existing glyph, components resolved."""
        g = self.glyf[name]
        coords, ends, flags = g.getCoordinates(self.glyf)
        out, start = [], 0
        for end in ends:
            out.append([(x, y, f & 1) for (x, y), f in zip(coords[start:end + 1], flags[start:end + 1])])
            start = end + 1
        return out

    def copy_of(self, name, s, dx=0, dy=0):
        return translate(scale(self.outline(name), s), dx, dy)

    def small_above(self, name, s):
        """A letter shrunk to a small high sign: centred, bottom resting GAP-free at y=20."""
        c = scale(self.outline(name), s)
        x0, y0, x1, y1 = bounds(c)
        return translate(c, -(x0 + x1) / 2, 20 - y0)

    def small_below(self, name, s):
        c = scale(self.outline(name), s)
        x0, y0, x1, y1 = bounds(c)
        return translate(c, -(x0 + x1) / 2, -20 - y1)

    def word_above(self, names, s):
        """Several positional glyphs set as one small RTL word (first glyph rightmost)."""
        x, contours = 0, []
        for name in reversed(names):
            contours += translate(self.outline(name), x, 0)
            x += self.hmtx[name][0]
        c = scale(contours, s)
        x0, y0, x1, y1 = bounds(c)
        return translate(c, -(x0 + x1) / 2, 20 - y0)

    # -- registration ------------------------------------------------------------
    def set_cmap(self, cp, name):
        for t in self.cmap_tables:
            t.cmap[cp] = name

    def put(self, name, contours, advance=0, gdef=3, cp=None, kind=None):
        """Create or replace a simple glyph."""
        g = glyph_from(contours)
        new = name not in self.font.getGlyphOrder()
        if new:
            self.font.setGlyphOrder(self.font.getGlyphOrder() + [name])
        self.glyf[name] = g
        g.recalcBounds(self.glyf)
        self.hmtx[name] = (advance, g.xMin if g.numberOfContours else 0)
        self.gdef[name] = gdef
        if cp is not None:
            self.set_cmap(cp, name)
        if kind:
            self.marks[name] = kind
        return g

    def put_composite(self, name, parts, advance, gdef, cp=None):
        g = composite(parts)
        if name not in self.font.getGlyphOrder():
            self.font.setGlyphOrder(self.font.getGlyphOrder() + [name])
        self.glyf[name] = g
        g.recalcBounds(self.glyf)
        self.hmtx[name] = (advance, g.xMin)
        self.gdef[name] = gdef
        if cp is not None:
            self.set_cmap(cp, name)

    # -- anchors -----------------------------------------------------------------
    def base_anchors(self, name):
        """(above, below) anchors from the outline: above the head (top region centre),
        below whatever ink sits under that head."""
        pts = [(x, y) for c in self.outline(name) for x, y, _ in c]
        if not pts:
            return None
        xs, ys = zip(*pts)
        y_min, y_max = min(ys), max(ys)
        h = y_max - y_min
        top = [x for x, y in pts if y >= y_max - 0.30 * h] or list(xs)
        ax = (min(top) + max(top)) / 2
        band = [y for x, y in pts if abs(x - ax) <= 170] or list(ys)
        return (ax, y_max + GAP_ABOVE), (ax, min(band) - GAP_BELOW)

    def alef_stem_x(self, lig):
        """x-centre of the alef (the LEFT stem) in a lam-alef ligature."""
        pts = [(x, y) for c in self.outline(lig) for x, y, _ in c]
        x0, x1 = min(x for x, _ in pts), max(x for x, _ in pts)
        left = [x for x, y in pts if y > 650 and x < (x0 + x1) / 2] or [x0]
        return (min(left) + max(left)) / 2


# ----------------------------------------------------------------------------
# mark shapes (origin = attachment point: bottom-centre for above, top-centre for below)

def fatha(dx=0, dy=0, length=None):
    length = FATHA_LEN if length is None else length
    return stroke([(dx + length / 2, dy + 15 + T / 2), (dx - length / 2, dy + 15 + T / 2 + 88)])


def kasra(dx=0, dy=0, length=None):
    length = FATHA_LEN if length is None else length
    return stroke([(dx + length / 2, dy - 15 - T / 2 - 88), (dx - length / 2, dy - 15 - T / 2)])


def hamza_shape():
    return stroke([(100, 210), (30, 245), (-60, 225), (-100, 165), (-95, 100), (-45, 62),
                   (30, 52), (92, 58), (128, 18)])


def main():
    b = Build()
    f = b.font
    glyf = b.glyf

    # --- harakat ---------------------------------------------------------------
    damma = b.copy_of("wawisolated", DAMMA_S)
    x0, y0, x1, y1 = bounds(damma)
    damma = translate(damma, -(x0 + x1) / 2, 15 - y0)
    seq = int(FATHA_LEN * 0.68)
    stack_dy = 130 if HEAVY else 110
    if DOTS:
        # Abu al-Aswad's dots: above = fatha, below = kasra, before (left of) the head = damma,
        # doubled side by side for tanween. The KFGQPC sequential forms are the same signs.
        r = VOWEL_R
        above = circle(0, 15 + r, r)
        below = circle(0, -15 - r, r)
        front = circle(-(r + 70), 15 + r - 40, r)
        pair = lambda c, dx: translate(c, dx, 0) + translate(c, -dx, 0)
        b.put("uni064E", above, cp=0x064E, kind="above")
        b.put("uni0650", below, cp=0x0650, kind="below")
        b.put("uni064F", front, cp=0x064F, kind="above")
        b.put("uni064B", pair(above, r + 20), cp=0x064B, kind="above")
        b.put("uni064D", pair(below, r + 20), cp=0x064D, kind="below")
        b.put("uni064C", front + translate(front, -(2 * r + 40), 0), cp=0x064C, kind="above")
        b.put("uni065E", pair(above, r + 20), cp=0x065E, kind="above")
        b.put("uni0656", pair(below, r + 20), cp=0x0656, kind="below")
        b.put("uni0657", front + translate(front, -(2 * r + 40), 0), cp=0x0657, kind="above")
    else:
        b.put("uni064E", fatha(), cp=0x064E, kind="above")
        b.put("uni0650", kasra(), cp=0x0650, kind="below")
        b.put("uni064F", damma, cp=0x064F, kind="above")
        b.put("uni064B", fatha() + fatha(dy=stack_dy), cp=0x064B, kind="above")
        b.put("uni064D", kasra() + kasra(dy=-stack_dy), cp=0x064D, kind="below")
        b.put("uni064C", damma + translate(damma, -60, stack_dy), cp=0x064C, kind="above")
        # KFGQPC sequential tanween: two signs side by side (0657 = damma with its twin)
        b.put("uni065E", fatha(dx=100, length=seq) + fatha(dx=-100, length=seq), cp=0x065E, kind="above")
        b.put("uni0656", kasra(dx=100, length=seq) + kasra(dx=-100, length=seq), cp=0x0656, kind="below")
        b.put("uni0657", translate(damma, 80, 0) + translate(damma, -80, 0), cp=0x0657, kind="above")
    # shadda: three teeth on a base stroke (the head of sheen)
    zig = [(-126, 36), (-84, 140), (-42, 36), (0, 140), (42, 36), (84, 140), (126, 36)]
    if HEAVY:
        zig = [(x * 1.45, 36 + (y - 36) * 1.45) for x, y in zig]
    b.put("uni0651", stroke(zig) + stroke([zig[0], zig[-1]]), cp=0x0651, kind="above")
    rs = 74 if HEAVY else 66
    b.put("uni0652", ring(0, 22 + rs, rs, rs - RING_W), cp=0x0652, kind="above")        # round sukun
    b.put("uni06E1", stroke(arc_points(0, 100 if HEAVY else 92, 78 if HEAVY else 66, 205, -25)),
          cp=0x06E1, kind="above")                                                     # head of khah
    mw, ma, ms = (190, 40, 38) if HEAVY else (160, 36, 32)
    b.put("uni0653", stroke([(x, 88 + ma * math.sin(2 * math.pi * (x + mw) / (2 * mw))) for x in range(-mw, mw + 1, ms)], T * 0.9),
          cp=0x0653, kind="above")                                                     # maddah
    b.put("uni0670", stroke([(0, 48), (0, 380 if HEAVY else 340)]), cp=0x0670, kind="above")  # dagger alef
    hz = hamza_shape()
    hx0, hy0, hx1, hy1 = bounds(hz)
    hz_above = translate(scale(hz, HAMZA_S), -HAMZA_S * (hx0 + hx1) / 2, 15 - HAMZA_S * hy0)
    hz_below = translate(scale(hz, HAMZA_S), -HAMZA_S * (hx0 + hx1) / 2, -15 - HAMZA_S * hy1)
    b.put("uni0654", hz_above, cp=0x0654, kind="above")
    b.put("uni0655", hz_below, cp=0x0655, kind="below")
    b.put("uni065C", circle(0, -(32 + DOT_R), DOT_R), cp=0x065C, kind="below")   # imaalah kubra dot
    b.put("uni06EA", ring(0, -(34 + 52 * SMALL), 52 * SMALL, 20 * SMALL), cp=0x06EA, kind="below")  # taqlil / wasl ring
    b.put("uni06EC", circle(0, 32 + DOT_R, DOT_R), cp=0x06EC, kind="above")     # wasl dot (Warsh-style texts)

    # --- Quranic annotation marks ------------------------------------------------
    b.put("uni06D6", b.word_above(["sadinit", "lammedi", "maqsurafinal"], 0.25 * SMALL), cp=0x06D6, kind="above")
    b.put("uni06D7", b.word_above(["qafinit", "lammedi", "maqsurafinal"], 0.25 * SMALL), cp=0x06D7, kind="above")
    b.put("uni06D8", b.small_above("meeminit", 0.38 * SMALL), cp=0x06D8, kind="above")
    b.put("uni06DA", b.small_above("jeemisol", 0.28 * SMALL), cp=0x06DA, kind="above")
    b.put("uni06DB", circle(-66 * SMALL, 52 * SMALL, 32 * SMALL) + circle(66 * SMALL, 52 * SMALL, 32 * SMALL)
          + circle(0, 156 * SMALL, 32 * SMALL), cp=0x06DB, kind="above")
    b.put("uni06DC", b.small_above("seenisol", 0.28 * SMALL), cp=0x06DC, kind="above")
    b.put("uni06DF", ring(0, 82, 54 * SMALL, 20 * SMALL), cp=0x06DF, kind="above")
    b.put("uni06E0", rect_ring(-48 * SMALL, 20, 48 * SMALL, 190 * SMALL, 36 * SMALL), cp=0x06E0, kind="above")
    b.put("uni06E2", b.small_above("meemisol", 0.38 * SMALL), cp=0x06E2, kind="above")
    b.put("uni06E4", rect(-230, 40, 230, 100 if HEAVY else 88), cp=0x06E4, kind="above")
    b.put("uni06E7", b.small_above("maqsuraisol", 0.28 * SMALL), cp=0x06E7, kind="above")
    b.put("uni06E8", b.small_above("noonisol", 0.32 * SMALL), cp=0x06E8, kind="above")
    b.put("uni06ED", b.small_below("meemisol", 0.38 * SMALL), cp=0x06ED, kind="below")
    b.put("waslsign", b.small_above("sadinit", 0.27 * SMALL), kind="above")

    # --- spacing signs and letters -----------------------------------------------
    sw = b.copy_of("wawisolated", 0.5)
    x0, y0, x1, y1 = bounds(sw)
    b.put("uni06E5", translate(sw, 40 - x0, 100), advance=int(x1 - x0 + 80), gdef=1, cp=0x06E5)
    sy = b.copy_of("maqsuraisol", 0.42)
    x0, y0, x1, y1 = bounds(sy)
    b.put("uni06E6", translate(sy, 20 - x0, 60), advance=int(x1 - x0 + 40), gdef=1, cp=0x06E6)
    mihrab = stroke([(-90, 0), (-90, 300), (0, 400), (90, 300), (90, 0)], 56, closed=True) + circle(0, 150, 40)
    b.put("uni06E9", translate(mihrab, 150, 0), advance=300, gdef=1, cp=0x06E9)
    sq = 165
    star = (stroke([(-sq, -sq), (-sq, sq), (sq, sq), (sq, -sq)], 50, closed=True)
            + stroke([(0, -230), (-230, 0), (0, 230), (230, 0)], 50, closed=True) + circle(0, 0, 45))
    b.put("uni06DE", translate(star, 240, 270), advance=480, gdef=1, cp=0x06DE)
    hz_big = translate(scale(hz, 1.05), 30 - 1.05 * hx0, -1.05 * hy0)
    b.put("uni0621", hz_big, advance=int(1.05 * (hx1 - hx0) + 60), gdef=1, cp=0x0621)

    # Arabic-Indic digits, monoline like the letters
    W = 100
    digits = {
        0: circle(150, 110, 75),
        1: stroke([(150, 0), (150, 650)], W),
        2: stroke([(290, 0), (290, 540), (240, 640), (130, 640), (60, 560), (60, 470)], W),
        3: stroke([(290, 0), (290, 540), (240, 640), (170, 590), (100, 640), (40, 560)], W),
        4: stroke([(90, 650), (290, 650), (180, 400), (290, 380), (290, 60), (80, 0)], W),
        5: ring(170, 330, 200, 100),
        6: stroke([(40, 640), (290, 640), (290, 0)], W),
        7: stroke([(40, 650), (170, 0), (300, 650)], W),
        8: stroke([(40, 0), (170, 650), (300, 0)], W),
        9: ring(170, 470, 150, 60) + stroke([(300, 470), (300, 0)], W),
    }
    for d, contours in digits.items():
        b.put(f"uni{0x0660 + d:04X}", contours, advance=360, gdef=1, cp=0x0660 + d)

    # --- dotless skeleton codepoints: the face is dotless already ----------------
    for cp, base in ((0x066E, "uni0628"), (0x066F, "uni0642"), (0x06A1, "uni0641"), (0x06BA, "uni0646")):
        b.set_cmap(cp, base)
    b.set_cmap(0x00A0, "space")

    # --- hamza / madda / wasl carriers as composites ----------------------------
    def attach_above(base, mark):
        (ax, ay), _ = b.base_anchors(base)
        return [(base, 0, 0), (mark, ax, ay)]

    def attach_below(base, mark):
        _, (bx, by) = b.base_anchors(base)
        return [(base, 0, 0), (mark, bx, by)]

    carriers = {
        "alefhamzaaboveisol": ("alefisol", "uni0654", attach_above),
        "alefhamzaabovefina": ("aleffina", "uni0654", attach_above),
        "alefhamzabelowisol": ("alefisol", "uni0655", attach_below),
        "alefhamzabelowfina": ("aleffina", "uni0655", attach_below),
        "alefmeddaisol": ("alefisol", "uni0653", attach_above),
        "alefmeddafina": ("aleffina", "uni0653", attach_above),
        "wawhamzaisol": ("wawisolated", "uni0654", attach_above),
        "wawhamzafina": ("wawfina", "uni0654", attach_above),
        "yahamzaisol": ("yaisolated", "uni0654", attach_above),
        "yahamzainit": ("yainit", "uni0654", attach_above),
        "yahamzamedi": ("yamedi", "uni0654", attach_above),
        "yahamzafina": ("yafina", "uni0654", attach_above),
        "yahamzamedi.high": ("yamedi.high", "uni0654", attach_above),
        "yahamzainitonjhk": ("yainitonjhk", "uni0654", attach_above),
        "uni0671": ("alefisol", "waslsign", attach_above),
    }
    for name, (base, mark, how) in carriers.items():
        adv, _ = b.hmtx[base]
        b.put_composite(name, how(base, mark), adv, 1)
    b.put_composite("uni0671.fina", attach_above("aleffina", "waslsign"), b.hmtx["aleffina"][0], 1)

    # positional lookups: 0 init, 1 medi, 2 fina, 3 isol (all SingleSubst)
    gsub = f["GSUB"].table
    singles = [gsub.LookupList.Lookup[i].SubTable[0].mapping for i in (0, 1, 2, 3)]
    singles[1]["uni0671"] = "uni0671.fina"
    singles[2]["uni0671"] = "uni0671.fina"
    singles[0]["uni0671"] = "uni0671"
    singles[3]["uni0671"] = "uni0671"

    # lam-alef ligatures keep the alef's sign (the plain ligature would drop it)
    lig_variants = {"alefmeddafina": ("madda", "uni0653", "above"),
                    "alefhamzaabovefina": ("hamza", "uni0654", "above"),
                    "alefhamzabelowfina": ("hamzabelow", "uni0655", "below"),
                    "uni0671.fina": ("wasl", "waslsign", "above")}
    for lookup_index, first, lig in ((4, "laminit", "lamalefisol"), (5, "lammedi", "lamaleffina")):
        ligatures = gsub.LookupList.Lookup[lookup_index].SubTable[0].ligatures
        stem_x = b.alef_stem_x(lig)
        (_, ay), (_, by) = b.base_anchors(lig)
        for component, (suffix, mark, side) in lig_variants.items():
            new = f"{lig}.{suffix}"
            y = ay if side == "above" else by
            b.put_composite(new, [(lig, 0, 0), (mark, stem_x, y)], b.hmtx[lig][0], 2)
            existing = [l for l in ligatures.get(first, []) if l.Component == [component]]
            if existing:
                existing[0].LigGlyph = new
            else:
                l = ot.Ligature()
                l.Component = [component]
                l.CompCount = 2
                l.LigGlyph = new
                ligatures.setdefault(first, []).append(l)

    # --- GPOS: mark-to-base for every inked base / ligature, mark-to-mark stacking -
    glyph_map = f.getReverseGlyphMap(rebuild=True)
    classes = {"above": 0, "below": 1}
    marks = {}
    stack = {}
    for name, kind in b.marks.items():
        marks[name] = (classes[kind], otl.buildAnchor(0, 0))
        x0, y0, x1, y1 = bounds(b.outline(name))
        stack[name] = {classes[kind]: otl.buildAnchor(0, int(y1 + STACK_GAP) if kind == "above" else int(y0 - STACK_GAP))}
    bases = {}
    for name in f.getGlyphOrder():
        if name in b.marks or b.gdef.get(name) not in (1, 2):
            continue
        anchors = b.base_anchors(name)
        if anchors is None:
            continue
        (ax, ay), (bx, by) = anchors
        bases[name] = {0: otl.buildAnchor(int(ax), int(ay)), 1: otl.buildAnchor(int(bx), int(by))}
    gpos = f["GPOS"].table
    mark_lookup = otl.buildLookup([otl.buildMarkBasePosSubtable(marks, bases, glyph_map)], flags=0)
    mkmk_lookup = otl.buildLookup([mark_mark_subtable(marks, stack, glyph_map, len(classes))], flags=0)
    lookups = gpos.LookupList.Lookup
    lookups.extend([mark_lookup, mkmk_lookup])
    gpos.LookupList.LookupCount = len(lookups)
    for tag, index in (("mark", len(lookups) - 2), ("mkmk", len(lookups) - 1)):
        fr = ot.FeatureRecord()
        fr.FeatureTag = tag
        fr.Feature = ot.Feature()
        fr.Feature.FeatureParams = None
        fr.Feature.LookupListIndex = [index]
        fr.Feature.LookupCount = 1
        gpos.FeatureList.FeatureRecord.append(fr)
        gpos.FeatureList.FeatureCount = len(gpos.FeatureList.FeatureRecord)
        fi = gpos.FeatureList.FeatureCount - 1
        for sr in gpos.ScriptList.ScriptRecord:
            for ls in [sr.Script.DefaultLangSys] + [r.LangSys for r in sr.Script.LangSysRecord]:
                if ls is not None:
                    ls.FeatureIndex.append(fi)
                    ls.FeatureCount = len(ls.FeatureIndex)

    # --- names, metrics, housekeeping ---------------------------------------------
    name = f["name"]
    copyright_ = str(name.getName(0, 3, 1))
    for nid, value in ((1, FAMILY), (3, f"{PS_NAME};{VERSION}"), (4, FAMILY), (6, PS_NAME),
                       (5, f"{VERSION};Al-Islam build of hijazifont 1.00 (tashkeel, annotation marks, "
                           f"hamza, digits and mark positioning added){VARIANT_NOTE}"),
                       (0, copyright_ + " Modified for the Al-Islam app (added marks and positioning); "
                           "the original is at https://github.com/khalidalabdullah/hijazifont"),
                       (13, "Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0). "
                            "Adapted from Khalid Alabdullah's hijazifont; changes: tashkeel, Quranic annotation "
                            "marks, hamza, Arabic-Indic digits and OpenType mark positioning added.")):
        name.setName(value, nid, 3, 1, 0x409)
    if "DSIG" in f:
        del f["DSIG"]
    # room for a sign stacked over a haraka over an alef (~1500 units)
    f["hhea"].ascent = 1350
    f["OS/2"].sTypoAscender = 1350
    f["OS/2"].usWinAscent = 1350
    f["OS/2"].usWinDescent = 700
    f["hhea"].descent = -700
    f["OS/2"].sTypoDescender = -700

    OUT.parent.mkdir(parents=True, exist_ok=True)
    f.save(str(OUT))
    print(f"wrote {OUT} ({OUT.stat().st_size} bytes, {len(f.getGlyphOrder())} glyphs, "
          f"{len(marks)} marks, {len(bases)} bases)")


if __name__ == "__main__":
    main()
