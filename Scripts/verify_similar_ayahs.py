#!/usr/bin/env python3
"""Gate for the shipped SimilarAyahs.json.xz. Must pass before it ships.

Checks the pack ON DISK: it decodes as xz and is version 2; every source key and
every target reference is a real ayah of this app's Quran; no ayah lists itself;
rows have the documented shape, every span sits inside its target ayah's tokens,
and no row carries text (the shared wording is spans into the app's own text,
never a copy); and (when the Tilawa sources are reachable) a fresh build
reproduces the pack byte for byte.

Run:  python3 Scripts/verify_similar_ayahs.py [tilawa-root]
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import subprocess
import sys
import lzma

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACK = ROOT / "Resources" / "Data" / "Quran" / "SimilarAyahs.json.xz"

_spec = importlib.util.spec_from_file_location("b", ROOT / "Scripts" / "build_similar_ayahs.py")
_builder = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_builder)


def main() -> None:
    if not PACK.exists():
        raise SystemExit(f"pack missing: {PACK}")

    blob = PACK.read_bytes()
    try:
        raw = lzma.decompress(blob)
    except lzma.LZMAError as error:
        raise SystemExit(f"pack is not a raw deflate stream: {error}")

    pack = json.loads(raw.decode("utf-8"))
    if not isinstance(pack, dict) or pack.get("v") != 2 or not isinstance(pack.get("ayahs"), dict):
        raise SystemExit("pack is not a version-2 SimilarAyahs pack ({\"v\": 2, \"ayahs\": {...}})")
    packed = pack["ayahs"]
    counts = _builder.ayah_counts()
    quran = json.loads(_builder.QURAN_JSON.read_text(encoding="utf-8"))
    token_counts = {(s["id"], a["id"]): len(a["textArabic"].split()) for s in quran for a in s["ayahs"]}

    problems: list[str] = []
    rows = verified = tinted = 0
    for key, matches in packed.items():
        source = _builder.parse_key(key)
        if source is None or source[0] not in counts or not 1 <= source[1] <= counts[source[0]]:
            problems.append(f"bad source key {key}")
            continue
        if not matches or len(matches) > _builder.MAX_MATCHES:
            problems.append(f"{key}: {len(matches)} rows (must be 1..{_builder.MAX_MATCHES})")
        for row in matches:
            rows += 1
            # row = [targetSurah, targetAyah, verifiedFlag, spans, labels, score]
            if (len(row) != 6 or not isinstance(row[0], int) or not isinstance(row[1], int)
                    or row[2] not in (0, 1) or not isinstance(row[3], list) or not isinstance(row[4], list)):
                problems.append(f"{key}: malformed row {row[:4]}")
                continue
            if not all(isinstance(label, str) for label in row[4]):
                problems.append(f"{key}: malformed labels {row[4]}")
            target_tokens = token_counts.get((row[0], row[1]), 0)
            for span in row[3]:
                if len(span) != 2 or not 0 <= span[0] <= span[1] < target_tokens:
                    problems.append(f"{key}: span {span} outside {row[0]}:{row[1]} ({target_tokens} tokens)")
            if row[5] is not None and (not isinstance(row[5], int) or not 0 <= row[5] <= 100):
                problems.append(f"{key}: score {row[5]!r} is not 0..100 or null")
            if any(isinstance(cell, str) for cell in row[:4]) or any(isinstance(cell, str) for cell in row[3]):
                problems.append(f"{key}: a row carries text; the shared wording must be spans")
            verified += row[2]
            tinted += 1 if row[3] else 0
            target = (row[0], row[1])
            if target[0] not in counts or not 1 <= target[1] <= counts[target[0]]:
                problems.append(f"{key}: bad target {target}")
            if target == source:
                problems.append(f"{key}: lists itself")

    tilawa = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else _builder.DEFAULT_TILAWA
    if (tilawa / "assets" / "quran" / "verified-similar-verses.json").exists():
        before = blob
        subprocess.run([sys.executable, str(ROOT / "Scripts" / "build_similar_ayahs.py"), str(tilawa)],
                       check=True, capture_output=True)
        if PACK.read_bytes() != before:
            problems.append("pack does not match a fresh build from source")
    else:
        print(f"note: Tilawa sources not found at {tilawa} - skipped the rebuild check")

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:20]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)

    print(f"OK: {len(packed)} source ayahs, {rows} rows ({verified} verified, {tinted} with spans), all references valid, no text")


if __name__ == "__main__":
    main()
