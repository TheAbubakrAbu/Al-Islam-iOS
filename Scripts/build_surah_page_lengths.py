#!/usr/bin/env python3
"""Regenerates Surah.pageLengthTwelfths in iPhone/Quran/Models/QuranData.swift.

Abu, 2026-10-11: "For surahs I don't want just x integer and .5 I want .25, .33, .5, .66, .75, 1 so
recalculate all the surahs ... try to have it where if we add them all it works properly."

Source of truth: the KFGQPC 15-line layout (1441H print, the 604 pages the app's ayah.page numbers
come from), as Tilawa ships it: ~/Downloads/Islam/Tilawa/assets/quran/qpc-v4-layout.json. Every page
lists its line slots; an empty slot is a surah's title or basmala line and belongs to the surah that
starts below it. Pages 1 and 2 have 8 slots, every other page 15. A surah's exact length is the sum,
over its pages, of (its slots on the page / the page's slots), so the 114 lengths add up to 604.

A length is shown on a grid of quarters and thirds (0, 1/4, 1/3, 1/2, 2/3, 3/4 past the whole pages),
stored in twelfths. Rounding every surah UP overshoots the Quran by more than five pages, so each surah
takes the grid mark just below or just above its exact length, chosen (by a small dynamic program) for
the least total error with the 114 summing to exactly 604 pages. Surahs of the same exact length round
the same way, and no surah is shorter than 1/4.

The script first checks the layout against the app's own quran.qpk: every ayah's first word must sit
on the page the pack says, or the lengths would describe a different mushaf. It refuses to write if not.

Usage: python3 Scripts/build_surah_page_lengths.py          (rewrites the region, prints a summary)
       python3 Scripts/build_surah_page_lengths.py --check  (computes and verifies only)
"""
import json
import lzma
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LAYOUT = ROOT.parent / "Tilawa" / "assets" / "quran" / "qpc-v4-layout.json"
PACK = ROOT / "Resources" / "Data" / "Quran" / "quran.qpk"
TARGET = ROOT / "iPhone" / "Quran" / "Models" / "QuranData.swift"
BEGIN = "    // BEGIN GENERATED SURAH PAGE LENGTHS\n"
END = "    // END GENERATED SURAH PAGE LENGTHS\n"
GRID = [0, 3, 4, 6, 8, 9, 12]  # twelfths past the whole pages
TOTAL_PAGES = 604


def layout_lengths(pages):
    """Exact length of each surah in pages, and the page each ayah's first word sits on."""
    share = {s: 0.0 for s in range(1, 115)}
    first_page = {}
    for pn in range(1, TOTAL_PAGES + 1):
        lines = pages[str(pn)]["lines"]
        keys = sorted(lines, key=int)
        owners = [None] * len(keys)
        for i, k in enumerate(keys):
            words = lines[k]
            if not words:
                continue
            surahs = {w["verseKey"].split(":")[0] for w in words}
            if len(surahs) != 1:
                sys.exit(f"page {pn} line {k} holds two surahs: {sorted(surahs)}")
            owners[i] = int(surahs.pop())
            for w in words:
                first_page.setdefault(w["verseKey"], pn)
        following = None
        for i in range(len(owners) - 1, -1, -1):
            if owners[i] is None:
                owners[i] = following
            else:
                following = owners[i]
        if None in owners:
            sys.exit(f"page {pn} ends on an empty line no surah claims")
        for owner in owners:
            share[owner] += 1 / len(owners)
    return share, first_page


def pack_ayah_pages():
    """(surah, ayah) -> page from quran.qpk's eager section (layout in QuranPack.swift)."""
    raw = PACK.read_bytes()
    eager = lzma.LZMADecompressor().decompress(raw[raw.find(b"\xfd7zXZ\x00"):])
    pos = 0

    def u32():
        nonlocal pos
        value = struct.unpack_from("<I", eager, pos)[0]
        pos += 4
        return value

    def string():
        nonlocal pos
        n = u32()
        pos += n

    counts = []
    for _ in range(u32()):
        sid = u32()
        pos += 1
        for _ in range(4):
            string()
        ayahs = u32()
        for _ in range(8):  # pages start/end/count, juz first/last, revelation order, words, letters
            u32()
        pos += 1
        for _ in range(u32()):
            u32()
        for _ in range(u32()):
            string()
        u32()
        counts.append((sid, ayahs))
    rows = u32()
    out = {}
    row = 0
    for sid, ayahs in counts:
        for ayah in range(1, ayahs + 1):
            out[(sid, ayah)] = struct.unpack_from("<IHHIIH", eager, pos + 18 * row)[2]
            row += 1
    if row != rows:
        sys.exit(f"quran.qpk row count {rows} != {row}")
    return out


def neighbours(exact):
    """The grid marks just below and just above an exact length, in twelfths (never below 1/4)."""
    t = exact * 12
    whole = int(t // 12) * 12
    for lo, hi in zip(GRID, GRID[1:]):
        if whole + lo - 1e-9 <= t <= whole + hi + 1e-9:
            if abs(t - (whole + lo)) < 1e-9:
                return [max(3, whole + lo)]
            if abs(t - (whole + hi)) < 1e-9:
                return [whole + hi]
            return sorted({max(3, whole + lo), whole + hi})
    sys.exit(f"no grid mark around {exact}")


def balanced(share):
    """Least total |error| with the lengths summing to exactly 604 pages. Surahs of the same exact
    length are rounded together, so two four-line surahs never show different lengths."""
    target = TOTAL_PAGES * 12
    groups = {}
    for s in range(1, 115):
        groups.setdefault(round(share[s] * 12, 6), []).append(s)
    best = {0: (0.0, {})}
    for exact, members in groups.items():
        nxt = {}
        for total, (err, picks) in best.items():
            for choice in neighbours(exact / 12):
                key = total + choice * len(members)
                if key > target:
                    continue
                cand = err + abs(choice - exact) * len(members)
                if key not in nxt or cand < nxt[key][0] - 1e-9:
                    nxt[key] = (cand, {**picks, **{m: choice for m in members}})
        best = nxt
    if target not in best:
        sys.exit("no rounding sums to 604 pages")
    picks = best[target][1]
    return [picks[s] for s in range(1, 115)]


def label(twelfths):
    whole, part = divmod(twelfths, 12)
    glyph = {0: "", 3: "¼", 4: "⅓", 6: "½", 8: "⅔", 9: "¾"}[part]
    return f"{whole if whole else ''}{glyph}"


def main():
    pages = json.loads(LAYOUT.read_text())["pages"]
    share, first_page = layout_lengths(pages)
    if abs(sum(share.values()) - TOTAL_PAGES) > 1e-6:
        sys.exit(f"layout lengths sum to {sum(share.values())}, not {TOTAL_PAGES}")
    mismatched = [(k, p, first_page.get(f"{k[0]}:{k[1]}")) for k, p in pack_ayah_pages().items()
                  if first_page.get(f"{k[0]}:{k[1]}") != p]
    if mismatched:
        sys.exit(f"{len(mismatched)} ayahs sit on a different page than quran.qpk says: {mismatched[:5]}")

    picks = balanced(share)
    assert sum(picks) == TOTAL_PAGES * 12
    worst = max(range(114), key=lambda i: abs(picks[i] - share[i + 1] * 12))
    print(f"114 surahs, {sum(picks) / 12:g} pages; largest rounding: surah {worst + 1} "
          f"{share[worst + 1]:.3f} -> {label(picks[worst])}")
    if "--check" in sys.argv:
        return

    rows = []
    for start in range(0, 114, 12):
        rows.append("        " + ", ".join(str(t) for t in picks[start:start + 12]) + ",")
    region = (BEGIN
              + "    /// Each surah's length in twelfths of a page, index = surah id - 1. Generated by\n"
              + "    /// Scripts/build_surah_page_lengths.py from the KFGQPC 15-line layout; do not edit by hand.\n"
              + "    static let pageLengthTwelfths: [Int] = [\n"
              + "\n".join(rows) + "\n"
              + "    ]\n"
              + END)
    source = TARGET.read_text()
    if BEGIN not in source or END not in source:
        sys.exit(f"{TARGET.name} has no generated region markers")
    head, rest = source.split(BEGIN, 1)
    _, tail = rest.split(END, 1)
    TARGET.write_text(head + region + tail)
    print(f"wrote {TARGET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
