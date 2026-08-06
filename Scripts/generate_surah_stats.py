#!/usr/bin/env python3
"""One-off generator for Resources/Data/Quran/surah-stats.json.

Reads the app's bundled Quran source JSON (Resources/JSONs-Deprecated/Quran.json -
the exact text the shipped quran.qpk was packed from) and computes, per surah:

  - ayahs:   ayah count
  - words:   Arabic word count (whitespace-split over the Uthmani text)
  - letters: Arabic LETTER count - diacritics/harakat, Quranic annotation signs,
             and superscript alef are excluded; only base letters (Unicode
             category Lo inside the Arabic blocks) are counted
  - juz:     the juz numbers the surah spans, computed from the standard
             30-juz start table (Kufi/Hafs numbering, as used by tanzil.net)
  - type:    revelation type ("makkan"/"madinan"), carried over from the source

Output is one compact JSON object keyed by surah number ("1".."114").

Run:  python3 Scripts/generate_surah_stats.py
"""

import json
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
OUTPUT = ROOT / "Resources" / "Data" / "Quran" / "surah-stats.json"

# The standard 30-juz start table (surah, ayah), Kufi ayah numbering (Hafs).
JUZ_STARTS = [
    (1, 1, 1), (2, 2, 142), (3, 2, 253), (4, 3, 93), (5, 4, 24),
    (6, 4, 148), (7, 5, 82), (8, 6, 111), (9, 7, 88), (10, 8, 41),
    (11, 9, 93), (12, 11, 6), (13, 12, 53), (14, 15, 1), (15, 17, 1),
    (16, 18, 75), (17, 21, 1), (18, 23, 1), (19, 25, 21), (20, 27, 56),
    (21, 29, 46), (22, 33, 31), (23, 36, 28), (24, 39, 32), (25, 41, 47),
    (26, 46, 1), (27, 51, 31), (28, 58, 1), (29, 67, 1), (30, 78, 1),
]

ARABIC_BLOCKS = (
    (0x0600, 0x06FF),  # Arabic
    (0x0750, 0x077F),  # Arabic Supplement
    (0x08A0, 0x08FF),  # Arabic Extended-A
    (0xFB50, 0xFDFF),  # Presentation Forms-A
    (0xFE70, 0xFEFF),  # Presentation Forms-B
)


def is_arabic_letter(ch: str) -> bool:
    """A base Arabic letter: in an Arabic block AND general category Lo.
    Harakat / sukun / Quranic signs are Mn (marks), tatweel is Lm - all excluded."""
    cp = ord(ch)
    if not any(lo <= cp <= hi for lo, hi in ARABIC_BLOCKS):
        return False
    return unicodedata.category(ch) == "Lo"


def juz_of(surah: int, ayah: int) -> int:
    """The juz containing surah:ayah, from the hardcoded start table."""
    result = 1
    for juz, s, a in JUZ_STARTS:
        if (surah, ayah) >= (s, a):
            result = juz
        else:
            break
    return result


def main() -> None:
    surahs = json.loads(SOURCE.read_text(encoding="utf-8"))

    stats = {}
    mismatches = []
    for surah in surahs:
        sid = surah["id"]
        words = 0
        letters = 0
        juz_set = set()
        for ayah in surah["ayahs"]:
            text = ayah["textArabic"]
            words += len(text.split())
            letters += sum(1 for ch in text if is_arabic_letter(ch))
            juz_set.add(juz_of(sid, ayah["id"]))
            # Cross-check the hardcoded table against the source's own per-ayah juz.
            if juz_of(sid, ayah["id"]) != ayah["juz"]:
                mismatches.append((sid, ayah["id"], juz_of(sid, ayah["id"]), ayah["juz"]))

        stats[str(sid)] = {
            "ayahs": len(surah["ayahs"]),
            "words": words,
            "letters": letters,
            "juz": sorted(juz_set),
            "type": surah["type"],
        }

    OUTPUT.write_text(
        json.dumps(stats, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )

    # Spot checks.
    total_ayahs = sum(s["ayahs"] for s in stats.values())
    print(f"Wrote {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size} bytes)")
    print(f"Surahs: {len(stats)}, total ayahs: {total_ayahs}")
    print(f"Al-Fatihah (1): {stats['1']}")
    print(f"Al-Baqarah (2): ayahs={stats['2']['ayahs']} juz={stats['2']['juz']}")
    print(f"Al-Ikhlas (112): {stats['112']}")
    if mismatches:
        print(f"WARNING: {len(mismatches)} juz mismatches vs source data, first 5: {mismatches[:5]}")
    else:
        print("Juz table matches the source's per-ayah juz field for all 6236 ayahs.")

    # Compare word/letter counts against the counts already embedded in the source JSON.
    for sid in ("1", "2", "112"):
        src = next(s for s in surahs if s["id"] == int(sid))
        print(f"Surah {sid}: computed words={stats[sid]['words']} letters={stats[sid]['letters']} "
              f"| source wordCount={src.get('wordCount')} letterCount={src.get('letterCount')}")


if __name__ == "__main__":
    main()
