#!/usr/bin/env python3
"""Render the FREE PALESTINE phone wallpaper.

The wallpaper that shipped through 4.6.5 was a stock photo composite of the Dome of the Rock
carrying two pieces of Arabic burned into the pixels: the ayah of hope (2:214) beside the dome and
a large "فلسطين" over the flag. Abu asked for it regenerated WITHOUT Arabic (2026-09-18), and a
photo composite cannot have text lifted back out of it, so the wallpaper is redrawn here from
scratch in the same vector language as `Palestine Poster` (its sibling, added 2026-09-16): the
flag's four fields, the Dome of the Rock in silhouette-clean geometry, an olive branch, and the
ayah of hope in ENGLISH only, cited.

Output: Resources/Images.xcassets/Wallpapers/Palestine Wallpaper.dataset/Free Palestine.jpg
at 1893x4096 - the size of the asset it replaces, which is 19.5:9 phone-shaped with room to spare.

Deterministic: same input, same bytes. Re-run after any edit here.

    python3 Scripts/build_palestine_wallpaper.py
"""

from __future__ import annotations

import math
import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# ---------------------------------------------------------------------------- canvas

W, H = 1893, 4096
SS = 2  # supersample factor: draw at 2x and downsample, so every curve lands smooth

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "Resources/Images.xcassets/Wallpapers/Palestine Wallpaper.dataset/Free Palestine.jpg"

# ---------------------------------------------------------------------------- palette
# The flag's own colours, the poster's exact values so the two read as one pair.

BLACK = (26, 26, 26)
CREAM = (242, 240, 232)
GREEN = (0, 145, 62)
RED = (206, 43, 46)

DOME_GOLD_TOP = (243, 205, 92)
DOME_GOLD_MID = (226, 170, 41)
DOME_GOLD_LOW = (176, 125, 20)
DRUM_BLUE = (22, 70, 145)
DRUM_BLUE_DARK = (14, 48, 104)
BASE_BLUE = (18, 60, 128)
ARCH_DARK = (11, 38, 86)
STONE = (232, 226, 210)

# ---------------------------------------------------------------------------- fonts

FONT_DIRS = [
    pathlib.Path("/System/Library/Fonts/Supplemental"),
    pathlib.Path("/System/Library/Fonts"),
]


def font(name: str, size: int, index: int = 0) -> ImageFont.FreeTypeFont:
    for directory in FONT_DIRS:
        candidate = directory / name
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size, index=index)
    raise FileNotFoundError(name)


def futura(size: int, bold: bool = True) -> ImageFont.FreeTypeFont:
    # Futura.ttc: 0 = Medium, 1 = Medium Italic, 2 = Condensed Medium, 3 = Condensed ExtraBold.
    return font("Futura.ttc", size, index=3 if bold else 0)


def avenir(size: int, index: int) -> ImageFont.FreeTypeFont:
    return font("Avenir Next.ttc", size, index=index)


# ---------------------------------------------------------------------------- helpers


def centered(draw: ImageDraw.ImageDraw, y: int, text: str, fnt, fill, tracking: int = 0) -> int:
    """Draw `text` centred on the canvas at top `y`, with optional letter tracking.

    Returns the y below the drawn line.
    """
    if tracking == 0:
        box = draw.textbbox((0, 0), text, font=fnt)
        draw.text(((W * SS - (box[2] - box[0])) / 2 - box[0], y), text, font=fnt, fill=fill)
        return y + (box[3] - box[1])

    widths = [draw.textbbox((0, 0), ch, font=fnt)[2] - draw.textbbox((0, 0), ch, font=fnt)[0] for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x = (W * SS - total) / 2
    top = draw.textbbox((0, 0), text, font=fnt)[1]
    height = draw.textbbox((0, 0), text, font=fnt)[3] - top
    for ch, width in zip(text, widths):
        box = draw.textbbox((0, 0), ch, font=fnt)
        draw.text((x - box[0], y - top), ch, font=fnt, fill=fill)
        x += width + tracking
    return y + height


def vertical_gradient(size: tuple[int, int], top: tuple, bottom: tuple) -> Image.Image:
    """A one-pixel-wide gradient stretched to `size` - cheaper and smoother than per-row draws."""
    width, height = size
    strip = Image.new("RGB", (1, height))
    pixels = strip.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        pixels[0, y] = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
    return strip.resize(size, Image.BILINEAR)


# ---------------------------------------------------------------------------- the flag fields


def draw_flag_fields(draw: ImageDraw.ImageDraw) -> None:
    """The Palestinian flag as the wallpaper's ground: three horizontal bands and the hoist triangle.

    The bands are unequal on purpose - the black band is given the top third so the wordmark has a
    quiet field to sit in, and the green band takes the foot so the ayah reads on it.
    """
    w, h = W * SS, H * SS
    black_to = int(h * 0.318)
    cream_to = int(h * 0.742)

    draw.rectangle([0, 0, w, black_to], fill=BLACK)
    draw.rectangle([0, black_to, w, cream_to], fill=CREAM)
    draw.rectangle([0, cream_to, w, h], fill=GREEN)

    # The hoist triangle, laid along the left edge and pointing in - the flag's chevron, kept
    # narrow so it frames the art without crowding it.
    draw.polygon([(0, 0), (int(w * 0.175), int(h * 0.245)), (0, int(h * 0.49))], fill=RED)
    draw.polygon(
        [(0, int(h * 0.49)), (int(w * 0.175), int(h * 0.245)), (int(w * 0.175), int(h * 0.245))],
        fill=RED,
    )


# ---------------------------------------------------------------------------- the Dome of the Rock


def draw_dome(canvas: Image.Image, cx: int, base_y: int, width: int) -> None:
    """The Dome of the Rock: the golden dome on its drum, over the octagon's arcaded base.

    Drawn flat-vector (no photograph), so it stays crisp at any size and carries no Arabic - the
    real building's frieze is covered in it, and a legible frieze here would be exactly the text
    this wallpaper is meant to drop.
    """
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    base_w = width
    base_h = int(width * 0.30)
    drum_w = int(width * 0.60)
    drum_h = int(width * 0.26)
    dome_w = int(width * 0.56)
    dome_h = int(width * 0.34)

    base_top = base_y - base_h
    drum_top = base_top - drum_h
    dome_base = drum_top

    # --- the octagonal base, with its arcade
    draw.rectangle([cx - base_w // 2, base_top, cx + base_w // 2, base_y], fill=BASE_BLUE)
    # A pale string course along the top of the base, the building's stone banding.
    draw.rectangle([cx - base_w // 2, base_top, cx + base_w // 2, base_top + int(base_h * 0.10)], fill=STONE)

    arches = 7
    span = base_w / (arches + 0.6)
    arch_w = span * 0.60
    arch_h = base_h * 0.62
    arch_top = base_top + int(base_h * 0.26)
    for i in range(arches):
        ax = cx - base_w / 2 + span * (i + 0.8)
        left, right = ax - arch_w / 2, ax + arch_w / 2
        draw.rectangle([left, arch_top + arch_w / 2, right, arch_top + arch_h], fill=ARCH_DARK)
        draw.pieslice(
            [left, arch_top, right, arch_top + arch_w],
            start=180,
            end=360,
            fill=ARCH_DARK,
        )

    # --- the drum the dome sits on, with its own shorter arcade of windows
    draw.rectangle([cx - drum_w // 2, drum_top, cx + drum_w // 2, base_top], fill=DRUM_BLUE)
    draw.rectangle(
        [cx - drum_w // 2, base_top - int(drum_h * 0.12), cx + drum_w // 2, base_top],
        fill=DRUM_BLUE_DARK,
    )

    windows = 5
    wspan = drum_w / (windows + 0.8)
    win_w = wspan * 0.52
    win_h = drum_h * 0.54
    win_top = drum_top + int(drum_h * 0.26)
    for i in range(windows):
        wx = cx - drum_w / 2 + wspan * (i + 0.9)
        left, right = wx - win_w / 2, wx + win_w / 2
        draw.rectangle([left, win_top + win_w / 2, right, win_top + win_h], fill=ARCH_DARK)
        draw.pieslice([left, win_top, right, win_top + win_w], start=180, end=360, fill=ARCH_DARK)

    # --- the dome itself: a gradient half-ellipse, ribbed, on a narrow gold cornice
    dome_box = [cx - dome_w // 2, dome_base - dome_h, cx + dome_w // 2, dome_base + dome_h]
    dome_mask = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(dome_mask).pieslice(dome_box, start=180, end=360, fill=255)
    gold = vertical_gradient(canvas.size, DOME_GOLD_TOP, DOME_GOLD_LOW).convert("RGBA")
    layer.paste(gold, (0, 0), dome_mask)

    # Ribs: meridians drawn as thin darker arcs, fading toward the dome's edge.
    ribs = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    rib_draw = ImageDraw.Draw(ribs)
    for i in range(-5, 6):
        t = i / 5
        rib_w = dome_w * abs(t)
        if rib_w < 2:
            rib_draw.line(
                [(cx, dome_base - dome_h), (cx, dome_base)],
                fill=(*DOME_GOLD_MID, 150),
                width=max(2 * SS, 2),
            )
            continue
        box = [cx - rib_w / 2, dome_base - dome_h, cx + rib_w / 2, dome_base + dome_h]
        rib_draw.arc(box, start=180, end=360, fill=(*DOME_GOLD_MID, 130), width=max(2 * SS, 2))
    layer.alpha_composite(Image.composite(ribs, Image.new("RGBA", canvas.size, (0, 0, 0, 0)), dome_mask))

    # The cornice the dome springs from.
    draw.rectangle(
        [cx - dome_w // 2 - int(width * 0.02), dome_base - int(width * 0.012),
         cx + dome_w // 2 + int(width * 0.02), dome_base + int(width * 0.012)],
        fill=DOME_GOLD_LOW,
    )

    # --- the finial: the spire and its crescent
    spire_h = int(width * 0.13)
    spire_top = dome_base - dome_h - spire_h
    draw.line(
        [(cx, dome_base - dome_h), (cx, spire_top)],
        fill=DOME_GOLD_MID,
        width=max(int(width * 0.012), 2),
    )
    r = int(width * 0.038)
    cy = spire_top - int(r * 0.7)
    crescent = Image.new("L", canvas.size, 0)
    cd = ImageDraw.Draw(crescent)
    cd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    cd.ellipse([cx - r + r * 0.62, cy - r * 0.94, cx + r + r * 0.62, cy + r * 0.94], fill=0)
    layer.paste(Image.new("RGBA", canvas.size, (*DOME_GOLD_TOP, 255)), (0, 0), crescent)

    canvas.alpha_composite(layer)


# ---------------------------------------------------------------------------- the olive branch


def draw_olive_arc(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int) -> None:
    """A single olive branch swept in an arc under the dome - peace, and the land's own tree."""
    leaf_fill = CREAM
    start, end = math.radians(200), math.radians(340)
    steps = 26
    stem: list[tuple[float, float]] = []
    for i in range(steps + 1):
        a = start + (end - start) * i / steps
        stem.append((cx + radius * math.cos(a), cy + radius * 0.42 * math.sin(a)))
    draw.line(stem, fill=leaf_fill, width=max(int(radius * 0.012), 2), joint="curve")

    for i in range(1, steps):
        if i % 2:
            continue
        x, y = stem[i]
        px, py = stem[i - 1]
        angle = math.atan2(y - py, x - px)
        for side in (-1, 1):
            la = angle + side * math.radians(48)
            length = radius * 0.135
            wide = radius * 0.044
            # A leaf is an almond: two arcs meeting in points at both ends. Built as a Bezier-ish
            # polygon sampled off a unit lens, then rotated onto the stem - a plain quadrilateral
            # reads as a paper flag, which is what the first pass drew.
            points = []
            for t in range(21):
                u = t / 20
                px = u * length
                py = wide * math.sin(math.pi * u)
                points.append((px, py))
            for t in range(20, -1, -1):
                u = t / 20
                px = u * length
                py = -wide * math.sin(math.pi * u)
                points.append((px, py))
            cos_a, sin_a = math.cos(la), math.sin(la)
            draw.polygon(
                [(x + px * cos_a - py * sin_a, y + px * sin_a + py * cos_a) for px, py in points],
                fill=leaf_fill,
            )
        if i % 6 == 0:
            r = radius * 0.020
            draw.ellipse([x - r, y - r, x + r, y + r], fill=DOME_GOLD_MID)


# ---------------------------------------------------------------------------- compose


def build() -> Image.Image:
    canvas = Image.new("RGBA", (W * SS, H * SS), CREAM)
    draw = ImageDraw.Draw(canvas)

    draw_flag_fields(draw)

    w, h = W * SS, H * SS

    # --- the wordmark, in the black band. English only: this is the whole point of the redraw.
    centered(draw, int(h * 0.118), "FREE", futura(int(230 * SS)), CREAM, tracking=int(14 * SS))
    centered(draw, int(h * 0.192), "PALESTINE", futura(int(158 * SS)), CREAM, tracking=int(10 * SS))

    rule_w = int(w * 0.34)
    rule_y = int(h * 0.262)
    draw.rectangle(
        [(w - rule_w) // 2, rule_y, (w + rule_w) // 2, rule_y + int(7 * SS)],
        fill=RED,
    )

    # --- the Dome of the Rock, standing on the line where the cream band meets the green
    draw_dome(canvas, cx=w // 2, base_y=int(h * 0.742), width=int(w * 0.72))

    # --- the olive branch, arcing across the green band under the building
    draw_olive_arc(draw, cx=w // 2, cy=int(h * 0.828), radius=int(w * 0.40))

    # --- the ayah of hope, in English, cited. The Arabic it replaces is exactly what came out.
    y = int(h * 0.884)
    y = centered(draw, y, "INDEED, THE HELP", futura(int(96 * SS)), CREAM, tracking=int(7 * SS))
    centered(draw, y + int(34 * SS), "OF ALLAH IS NEAR", futura(int(96 * SS)), CREAM, tracking=int(7 * SS))
    centered(
        draw,
        int(h * 0.946),
        "AL-BAQARAH 2:214",
        avenir(int(52 * SS), index=1),
        (208, 232, 214),
        tracking=int(11 * SS),
    )

    flat = canvas.convert("RGB")
    # A whisper of blur before the downsample kills the last of the polygon stair-stepping.
    flat = flat.filter(ImageFilter.GaussianBlur(radius=0.4))
    return flat.resize((W, H), Image.LANCZOS)


def main() -> None:
    image = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, "JPEG", quality=92, optimize=True, progressive=True)
    print(f"wrote {OUT} ({OUT.stat().st_size / 1024:.0f} KiB, {image.width}x{image.height})")


if __name__ == "__main__":
    main()
