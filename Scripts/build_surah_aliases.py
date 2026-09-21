#!/usr/bin/env python3
"""Regenerates the SurahSpelling tables in iPhone/Quran/QuranStructs.swift.

Source of truth: Scripts/surah_aliases.json, keyed "1".."114":
    {"standard": "...", "latin": [...], "arabic": [...], "notes": "..."}

The app folds PHONETIC spelling on its own (SpellingFold in Globals.swift), so the JSON holds only
what a fold cannot derive: different names, other languages' romanizations, Biblical names, second
Arabic names.

The one hard rule: an alias identifies ONE surah. A name two surahs share is refused here, because
a wrong alias sends the reader to the wrong surah, and that is worse than finding nothing. The
check compares aliases the way the app does (lowercased, punctuation and spaces dropped), so
"Al-Mu'min" and "al mumin" count as the same name.

Usage: python3 Scripts/build_surah_aliases.py          (rewrites the region, prints a summary)
       python3 Scripts/build_surah_aliases.py --check  (validates only, writes nothing)
"""
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "Scripts" / "surah_aliases.json"
TARGET = ROOT / "iPhone" / "Quran" / "QuranStructs.swift"
BEGIN = "    // BEGIN GENERATED SURAH ALIASES\n"
END = "    // END GENERATED SURAH ALIASES\n"
EM_DASH = chr(0x2014)  # spelled as a code point so this file holds no em dash itself


def compact(text: str) -> str:
    """How the app compares two names: no case, accents, punctuation or spaces."""
    decomposed = unicodedata.normalize("NFD", text.lower())
    return "".join(c for c in decomposed if c.isalnum())


def swift_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main() -> int:
    check_only = "--check" in sys.argv
    data = json.loads(SOURCE.read_text(encoding="utf-8"))

    problems = []
    missing = [str(n) for n in range(1, 115) if str(n) not in data]
    if missing:
        problems.append(f"missing surahs: {', '.join(missing)}")

    owners = {}
    for number in range(1, 115):
        entry = data.get(str(number), {})
        for field in ("latin", "arabic"):
            for alias in entry.get(field, []):
                if EM_DASH in alias:
                    problems.append(f"{number}: em dash in {alias!r}")
                key = compact(alias)
                if not key:
                    problems.append(f"{number}: empty alias {alias!r}")
                    continue
                owners.setdefault(key, set()).add(number)

    # A surah's own STANDARD name must never be another surah's alias either.
    for number in range(1, 115):
        standard = data.get(str(number), {}).get("standard", "")
        key = compact(standard)
        for other in owners.get(key, set()) - {number}:
            problems.append(f"{other}: alias equals the standard name of surah {number} ({standard})")

    for key, numbers in sorted(owners.items()):
        if len(numbers) > 1:
            problems.append(f"alias {key!r} is shared by surahs {sorted(numbers)}")

    if problems:
        print("REFUSED, nothing written:")
        for problem in problems:
            print("  -", problem)
        return 1

    def table(field: str) -> str:
        lines = [f"    static let {field}: [Int: [String]] = ["]
        rows = []
        for number in range(1, 115):
            seen, aliases = set(), []
            for alias in data[str(number)].get(field, []):
                if compact(alias) not in seen:
                    seen.add(compact(alias))
                    aliases.append(alias)
            if aliases:
                rows.append(f"        {number}: [{', '.join(swift_string(a) for a in aliases)}]")
        lines.append(",\n".join(rows) if rows else "        :")
        lines.append("    ]")
        if not rows:
            return f"    static let {field}: [Int: [String]] = [:]"
        return "\n".join(lines)

    region = BEGIN + table("latin") + "\n" + table("arabic") + "\n" + END
    source = TARGET.read_text(encoding="utf-8")
    pattern = re.compile(re.escape(BEGIN) + ".*?" + re.escape(END), re.S)
    if len(pattern.findall(source)) != 1:
        print("REFUSED: the generated region markers were not found exactly once in", TARGET)
        return 1

    latin = sum(len(data[str(n)].get("latin", [])) for n in range(1, 115))
    arabic = sum(len(data[str(n)].get("arabic", [])) for n in range(1, 115))
    bare = [n for n in range(1, 115) if not data[str(n)].get("latin") and not data[str(n)].get("arabic")]
    print(f"{latin} latin + {arabic} arabic aliases, no collisions; surahs with none: {bare or 'none'}")
    if check_only:
        return 0
    TARGET.write_text(pattern.sub(lambda _: region, source), encoding="utf-8")
    print("wrote", TARGET.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
