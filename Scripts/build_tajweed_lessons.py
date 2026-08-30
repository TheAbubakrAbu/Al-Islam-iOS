#!/usr/bin/env python3
"""Build Resources/Data/Quran/TajweedLessons.json.xz - the structured tajweed
course behind Islam tab -> Tajweed -> Structured Lessons.

SOURCE
------
Tilawa's src/data/tajweedLessons.ts: a hand-authored curriculum by Jamil
Hammoudeh (chapters -> lessons, each with body paragraphs, curated example
ayahs, Qaida-Noorania-style drills, and a mushaf-style reference card).
Ported with his permission; see CreditsView.

The .ts file is data plus TypeScript dressing. Rather than hand-copying 1,200
lines of prose (which would drift from Tilawa), this script slices out the
TAJWEED_CHAPTERS literal, strips its type annotation, evaluates it with node,
and re-emits it as JSON - so a Tilawa content fix is a rebuild away.

VALIDATION (build fails, writing nothing, if violated)
------------------------------------------------------
* every example's (surahId, ayahNumber) exists in this app's Quran;
* every lesson has an id, English title, and at least one body paragraph;
* lesson ids are unique across chapters.

OUTPUT: xz over {"chapters": [...]} in the source's own order, fields
        exactly as authored (titleEn/titleAr/color/summary/body/examples/
        drills/mushafCard; narrationUrl dropped - no recordings exist).

RUN:  python3 Scripts/build_tajweed_lessons.py [tilawa-root]
"""

from __future__ import annotations

import json
import pathlib
import subprocess
import sys
import lzma


def xz_compress(body: bytes) -> bytes:
    """xz stream, preset 9e, dictionary no larger than the payload needs (the app decodes it with
    Apple's Compression framework, COMPRESSION_LZMA, which reads the xz container directly)."""
    dict_size = 1 << 16
    while dict_size < len(body) and dict_size < (1 << 26):
        dict_size <<= 1
    filters = [{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME, "dict_size": dict_size}]
    return lzma.compress(body, format=lzma.FORMAT_XZ, check=lzma.CHECK_CRC32, filters=filters)

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
OUT = ROOT / "Resources" / "Data" / "Quran" / "TajweedLessons.json.xz"
DEFAULT_TILAWA = ROOT.parent / "Tilawa"


def ayah_counts() -> dict[int, int]:
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    return {s["id"]: len(s["ayahs"]) for s in quran}


def extract_chapters(ts_path: pathlib.Path) -> list:
    """Evaluate the TAJWEED_CHAPTERS literal with node and return it as Python data."""
    source = ts_path.read_text(encoding="utf-8")
    marker = "export const TAJWEED_CHAPTERS"
    start = source.index(marker)
    # The literal ends at the first export AFTER the array (findLesson).
    end = source.index("export function findLesson", start)
    literal = source[start:end]
    # "export const TAJWEED_CHAPTERS: TajweedChapter[] = [" -> "const TAJWEED_CHAPTERS = ["
    literal = literal.replace(marker + ": TajweedChapter[] =", "const TAJWEED_CHAPTERS =", 1)

    script = literal + "\nprocess.stdout.write(JSON.stringify(TAJWEED_CHAPTERS));\n"
    result = subprocess.run(["node", "-"], input=script.encode("utf-8"),
                            capture_output=True, check=True)
    return json.loads(result.stdout.decode("utf-8"))


def main() -> None:
    tilawa = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_TILAWA
    ts_path = tilawa / "src" / "data" / "tajweedLessons.ts"
    if not ts_path.exists():
        raise SystemExit(f"source not found: {ts_path}")

    counts = ayah_counts()
    chapters = extract_chapters(ts_path)

    problems: list[str] = []
    seen_ids: set[str] = set()
    lessons = examples = drills = 0

    for chapter in chapters:
        for lesson in chapter.get("lessons", []):
            lessons += 1
            lid = lesson.get("id", "")
            if not lid or not lesson.get("titleEn") or not lesson.get("body"):
                problems.append(f"lesson {lid or '<missing id>'}: missing id/title/body")
            if lid in seen_ids:
                problems.append(f"duplicate lesson id {lid}")
            seen_ids.add(lid)
            lesson.pop("narrationUrl", None)
            for example in lesson.get("examples", []):
                examples += 1
                surah, ayah = example.get("surahId"), example.get("ayahNumber")
                if surah not in counts or not 1 <= (ayah or 0) <= counts[surah]:
                    problems.append(f"lesson {lid}: bad example {surah}:{ayah}")
            drills += len(lesson.get("drills", []))

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:20]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)

    body = json.dumps({"chapters": chapters}, ensure_ascii=False,
                      separators=(",", ":"), sort_keys=True).encode("utf-8")
    blob = xz_compress(body)
    OUT.write_bytes(blob)

    print(f"{len(chapters)} chapters, {lessons} lessons, {examples} examples, {drills} drills")
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} xz")


if __name__ == "__main__":
    main()
