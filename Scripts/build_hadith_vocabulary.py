#!/usr/bin/env python3
"""Pack the hadith typo vocabulary the app exported into Resources/Data/Hadith/HadithVocabulary.txt.xz.

    ./Scripts/build_hadith_vocabulary.py <exported hadith-vocabulary.txt>

The list is built by the app itself, never by this script: "-exportHadithVocabulary" on the
simulator walks every book's English search folds (every 4-24 letter lowercase word, sorted) and
writes Documents/hadith-vocabulary.txt behind a first line naming the shelf it came from
("#shelf <fingerprint>"). Shipping the app's own walk is what keeps the list and the runtime rule
from ever disagreeing (Tilawa Guide, decision B, 2026-09-07). This script checks that first line
against the packs on disk (FNV-1a over "slug:bytes" of the .hpk files in slug order, the app's
`HadithVocabulary.shelfFingerprint`) and refuses a list built for other packs, then writes the xz.
Re-run the export and this script after any .hpk changes; Scripts/verify_tilawa_packs.py and
"-auditPacks" both say when the shipped list no longer matches the shelf.

Recipe (the iPhone 17 Pro simulator, Debug build installed):
    xcrun simctl launch <udid> com.Quran.Elmallah.Islamic-Pillars -exportHadithVocabulary -skipNotificationPrompt
    # wait for Documents/hadith-vocabulary.txt in the app container (xcrun simctl get_app_container <udid> <bundle> data)
    ./Scripts/build_hadith_vocabulary.py <container>/Documents/hadith-vocabulary.txt
"""
import lzma, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HADITH = ROOT / "Resources/Data/Hadith"
OUT = HADITH / "HadithVocabulary.txt.xz"
HEADER = "#shelf "


def shelf_fingerprint(folder: Path = HADITH) -> str:
    """FNV-1a 64 over "slug:bytes\\n" for every .hpk, by slug: `HadithVocabulary.shelfFingerprint`."""
    value = 0xCBF29CE484222325
    for pack in sorted(folder.glob("*.hpk"), key=lambda p: p.stem):
        for byte in f"{pack.stem}:{pack.stat().st_size}\n".encode("utf-8"):
            value ^= byte
            value = (value * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return format(value, "x")


def read_shipped(path: Path = OUT) -> tuple[str, list[str]]:
    """(fingerprint line's value, words) of a shipped or exported list; the fingerprint is "" when
    the first line is not a header."""
    raw = path.read_bytes()
    if path.suffix == ".xz":
        raw = lzma.decompress(raw)
    lines = [line for line in raw.decode("utf-8").split("\n") if line]
    if lines and lines[0].startswith(HEADER):
        return lines[0][len(HEADER):], lines[1:]
    return "", lines


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    source = Path(sys.argv[1])
    stamped, words = read_shipped(source)
    expected = shelf_fingerprint()
    if stamped != expected:
        sys.exit(f"{source}: built for shelf {stamped or '(none)'}, the packs on disk are {expected}; re-run the export")
    if len(words) < 10_000 or words != sorted(set(words)):
        sys.exit(f"{source}: {len(words)} words, expected a sorted, unique list of tens of thousands")
    text = HEADER + expected + "\n" + "\n".join(words) + "\n"
    raw = text.encode("utf-8")
    OUT.write_bytes(lzma.compress(raw, format=lzma.FORMAT_XZ, preset=9 | lzma.PRESET_EXTREME))
    print(f"{len(words)} words for shelf {expected}; {len(raw):,} bytes raw -> {OUT.stat().st_size:,} bytes xz at {OUT}")


if __name__ == "__main__":
    main()
