#!/usr/bin/env python3
"""Gate for ThematicTopics.json.xz + SurahSections.json.xz.

Checks the packs ON DISK: they inflate as raw deflate; every topic ayah ref and
every section range is a real ayah of this app's Quran; sections stay in order;
and (when the Tilawa sources are reachable) a fresh build reproduces both packs
byte for byte.

Run:  python3 Scripts/verify_quran_themes.py [tilawa-root]
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import subprocess
import sys
import lzma

ROOT = pathlib.Path(__file__).resolve().parent.parent

_spec = importlib.util.spec_from_file_location("b", ROOT / "Scripts" / "build_quran_themes.py")
_builder = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_builder)


def inflate(path: pathlib.Path):
    blob = path.read_bytes()
    return blob, json.loads(lzma.decompress(blob).decode("utf-8"))


def main() -> None:
    for p in (_builder.OUT_TOPICS, _builder.OUT_SECTIONS):
        if not p.exists():
            raise SystemExit(f"pack missing: {p}")

    counts = _builder.ayah_counts()
    problems: list[str] = []

    blob_t, topics = inflate(_builder.OUT_TOPICS)
    assignments = 0
    for topic in topics.get("topics", []):
        for field in ("id", "name", "ayahs"):
            if not topic.get(field):
                problems.append(f"topic {topic.get('id')}: missing {field}")
        for key in topic.get("ayahs", []):
            assignments += 1
            parts = key.split(":")
            try:
                surah, ayah = int(parts[0]), int(parts[1])
            except (ValueError, IndexError):
                problems.append(f"topic {topic.get('id')}: bad ref {key}")
                continue
            if surah not in counts or not 1 <= ayah <= counts[surah]:
                problems.append(f"topic {topic.get('id')}: unknown ayah {key}")

    blob_s, sections = inflate(_builder.OUT_SECTIONS)
    rows = 0
    for surah_key, entry in sections.items():
        surah = int(surah_key)
        if surah not in counts:
            problems.append(f"unknown surah {surah_key}")
            continue
        last_start = 0
        for row in entry.get("sections", []):
            rows += 1
            start, end = row[0], row[1]
            if not 1 <= start <= end <= counts[surah]:
                problems.append(f"surah {surah}: bad range {start}-{end}")
            if start < last_start:
                problems.append(f"surah {surah}: sections out of order at {start}")
            last_start = start
            if not (row[2] or row[3]):
                problems.append(f"surah {surah}: titleless section {start}-{end}")

    tilawa = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else _builder.DEFAULT_TILAWA
    if (tilawa / "assets" / "quran" / "thematic-topics.json").exists():
        before = (blob_t, blob_s)
        subprocess.run([sys.executable, str(ROOT / "Scripts" / "build_quran_themes.py"), str(tilawa)],
                       check=True, capture_output=True)
        if (_builder.OUT_TOPICS.read_bytes(), _builder.OUT_SECTIONS.read_bytes()) != before:
            problems.append("packs do not match a fresh build from source")
    else:
        print(f"note: Tilawa sources not found at {tilawa} - skipped the rebuild check")

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:20]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)

    print(f"OK: {len(topics['topics'])} topics / {assignments:,} refs; "
          f"{len(sections)} surahs / {rows} section rows; all references valid")


if __name__ == "__main__":
    main()
