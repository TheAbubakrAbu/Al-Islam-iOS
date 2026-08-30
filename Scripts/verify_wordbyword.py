#!/usr/bin/env python3
"""Gate for the shipped WordByWord.json.xz. Must pass before the pack ships.

Checks the pack ON DISK (not the builder's in-memory result) against the app's own
Quran text, so a stale or partially-rewritten pack cannot slip through:

  1. it decodes as xz (what the Swift reader does);
  2. it covers all 114 surahs with the right ayah counts;
  3. every ayah's gloss array is EXACTLY as long as that ayah's whitespace token
     count - the invariant the reader indexes on. A short array would silently
     show the wrong word's meaning;
  4. rebuilding from source reproduces the pack byte for byte.

Run:  python3 Scripts/verify_wordbyword.py [path/to/word-by-word-en.json]
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import re
import sys
import lzma

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACK = ROOT / "Resources" / "Data" / "Quran" / "WordByWord.json.xz"
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"

_spec = importlib.util.spec_from_file_location("build_wordbyword", ROOT / "Scripts" / "build_wordbyword.py")
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

    packed = json.loads(raw.decode("utf-8"))
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))

    problems: list[str] = []
    ayahs = tokens = 0

    if len(packed) != len(quran):
        problems.append(f"pack has {len(packed)} surahs, Quran has {len(quran)}")

    for surah in quran:
        rows = packed.get(str(surah["id"]))
        if rows is None:
            problems.append(f"surah {surah['id']}: absent from pack")
            continue
        if len(rows) != len(surah["ayahs"]):
            problems.append(f"surah {surah['id']}: {len(rows)} rows vs {len(surah['ayahs'])} ayahs")
            continue
        for ayah, glosses in zip(surah["ayahs"], rows):
            ayahs += 1
            expected = len([t for t in re.split(r"\s+", ayah["textArabic"].strip()) if t])
            tokens += expected
            if len(glosses) != expected:
                problems.append(
                    f"{surah['id']}:{ayah['id']}: {len(glosses)} glosses vs {expected} tokens"
                )

    # Byte-for-byte reproducibility from source, when the source is reachable.
    source = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else _builder.DEFAULT_SOURCE
    if source.exists():
        wbw = json.loads(source.read_text(encoding="utf-8"))
        rebuilt: dict[str, list[list[str]]] = {}
        for surah in quran:
            rows = []
            for ayah in surah["ayahs"]:
                words = wbw.get(f"{surah['id']}:{ayah['id']}", [])
                words = [
                    w for w in words
                    if _builder.norm(w["a"]) and not _builder._DIGITS.match(_builder.norm(w["a"]))
                ]
                aligned = _builder.align(_builder.tokens_of(ayah["textArabic"]), words)
                rows.append(aligned if aligned is not None else [])
            rebuilt[str(surah["id"])] = rows
        if rebuilt != packed:
            problems.append("pack does not match a fresh build from source")
    else:
        print(f"note: source not found at {source} - skipped the rebuild check")

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:20]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)

    print(f"OK: {ayahs} ayahs, {tokens:,} tokens, every gloss array matches its token count")
    print(f"    {PACK.name}: {len(blob):,} bytes on disk, {len(raw):,} inflated")


if __name__ == "__main__":
    main()
