#!/usr/bin/env python3
"""Gate for the shipped TajweedLessons.json.deflate.

Checks the pack ON DISK: it inflates as raw deflate; every lesson carries an
id, English title, and body; lesson ids are unique; every example references a
real ayah; and (when Tilawa is reachable) a fresh build reproduces the pack
byte for byte.

Run:  python3 Scripts/verify_tajweed_lessons.py [tilawa-root]
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import subprocess
import sys
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACK = ROOT / "Resources" / "Data" / "Quran" / "TajweedLessons.json.deflate"

_spec = importlib.util.spec_from_file_location("b", ROOT / "Scripts" / "build_tajweed_lessons.py")
_builder = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_builder)


def main() -> None:
    if not PACK.exists():
        raise SystemExit(f"pack missing: {PACK}")

    blob = PACK.read_bytes()
    try:
        raw = zlib.decompress(blob, -15)
    except zlib.error as error:
        raise SystemExit(f"pack is not a raw deflate stream: {error}")

    chapters = json.loads(raw.decode("utf-8")).get("chapters", [])
    counts = _builder.ayah_counts()

    problems: list[str] = []
    seen: set[str] = set()
    lessons = examples = 0
    for chapter in chapters:
        if not chapter.get("id") or not chapter.get("title"):
            problems.append(f"chapter {chapter.get('id')}: missing id/title")
        for lesson in chapter.get("lessons", []):
            lessons += 1
            lid = lesson.get("id", "")
            if not lid or not lesson.get("titleEn") or not lesson.get("body"):
                problems.append(f"lesson {lid or '<missing>'}: missing id/title/body")
            if lid in seen:
                problems.append(f"duplicate lesson id {lid}")
            seen.add(lid)
            for example in lesson.get("examples", []):
                examples += 1
                surah, ayah = example.get("surahId"), example.get("ayahNumber")
                if surah not in counts or not 1 <= (ayah or 0) <= counts[surah]:
                    problems.append(f"lesson {lid}: bad example {surah}:{ayah}")

    tilawa = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else _builder.DEFAULT_TILAWA
    if (tilawa / "src" / "data" / "tajweedLessons.ts").exists():
        before = blob
        subprocess.run([sys.executable, str(ROOT / "Scripts" / "build_tajweed_lessons.py"), str(tilawa)],
                       check=True, capture_output=True)
        if PACK.read_bytes() != before:
            problems.append("pack does not match a fresh build from source")
    else:
        print(f"note: Tilawa source not found at {tilawa} - skipped the rebuild check")

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:20]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)

    print(f"OK: {len(chapters)} chapters, {lessons} lessons, {examples} examples, all ids unique, all refs valid")


if __name__ == "__main__":
    main()
