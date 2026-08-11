#!/usr/bin/env python3
"""Gate for the shipped SimilarAyahs.json.deflate. Must pass before it ships.

Checks the pack ON DISK: raw-deflate inflates; every source key and every
target reference is a real ayah of this app's Quran; no ayah lists itself; rows
have the documented shape; and (when the Tilawa sources are reachable) a fresh
build reproduces the pack byte for byte.

Run:  python3 Scripts/verify_similar_ayahs.py [tilawa-root]
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import subprocess
import sys
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACK = ROOT / "Resources" / "Data" / "Quran" / "SimilarAyahs.json.deflate"

_spec = importlib.util.spec_from_file_location("b", ROOT / "Scripts" / "build_similar_ayahs.py")
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

    packed = json.loads(raw.decode("utf-8"))
    counts = _builder.ayah_counts()

    problems: list[str] = []
    rows = verified = 0
    for key, matches in packed.items():
        source = _builder.parse_key(key)
        if source is None or source[0] not in counts or not 1 <= source[1] <= counts[source[0]]:
            problems.append(f"bad source key {key}")
            continue
        if not matches or len(matches) > _builder.MAX_MATCHES:
            problems.append(f"{key}: {len(matches)} rows (must be 1..{_builder.MAX_MATCHES})")
        for row in matches:
            rows += 1
            if not (4 <= len(row) <= 5) or row[3] not in (0, 1) or not isinstance(row[2], str):
                problems.append(f"{key}: malformed row {row[:4]}")
                continue
            verified += row[3]
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

    print(f"OK: {len(packed)} source ayahs, {rows} rows ({verified} verified), all references valid")


if __name__ == "__main__":
    main()
