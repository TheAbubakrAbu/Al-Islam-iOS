#!/usr/bin/env python3
"""Gate for the shipped WordByWord.json.xz. Must pass before the pack ships.

Checks the pack ON DISK (not the builder's in-memory result) against the app's own
Quran text, so a stale or partially-rewritten pack cannot slip through:

  1. it decodes as xz (what the Swift reader does);
  2. it is a version-2 pack carrying BOTH layers ("en" glosses, "tr" transliteration);
  3. it covers all 114 surahs with the right ayah counts, in both layers;
  4. every ayah's array is EXACTLY as long as that ayah's whitespace token count -
     the invariant the reader indexes on. A short array would silently show the
     wrong word's meaning or the wrong word's transliteration;
  5. the two layers agree token for token on which entries are empty, so a word
     that has a gloss also has a transliteration and vice versa;
  6. rebuilding from source reproduces the pack byte for byte.

Run:  python3 Scripts/verify_wordbyword.py [word-by-word-en.json] [word-by-word-translit.json]
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

    if packed.get("v") != 2:
        raise SystemExit(f"pack is version {packed.get('v')!r}, expected 2 (rebuild it)")
    layers = {name: packed.get(name) for name in ("en", "tr")}
    for name, layer in layers.items():
        if not isinstance(layer, dict):
            raise SystemExit(f"pack is missing its {name!r} layer")
        if len(layer) != len(quran):
            problems.append(f"{name}: pack has {len(layer)} surahs, Quran has {len(quran)}")

    for surah in quran:
        rows = {name: layer.get(str(surah["id"])) for name, layer in layers.items()}
        if any(row is None for row in rows.values()):
            problems.append(f"surah {surah['id']}: absent from pack")
            continue
        if any(len(row) != len(surah["ayahs"]) for row in rows.values()):
            counts = ", ".join(f"{name} {len(row)}" for name, row in rows.items())
            problems.append(f"surah {surah['id']}: {counts} rows vs {len(surah['ayahs'])} ayahs")
            continue
        for index, ayah in enumerate(surah["ayahs"]):
            ayahs += 1
            expected = len([t for t in re.split(r"\s+", ayah["textArabic"].strip()) if t])
            tokens += expected
            entries = {name: row[index] for name, row in rows.items()}
            for name, values in entries.items():
                if len(values) != expected:
                    problems.append(
                        f"{surah['id']}:{ayah['id']}: {len(values)} {name} entries vs {expected} tokens"
                    )
            glosses, latin = entries["en"], entries["tr"]
            if len(glosses) == len(latin):
                for position, (gloss, translit) in enumerate(zip(glosses, latin)):
                    if bool(gloss) != bool(translit):
                        problems.append(
                            f"{surah['id']}:{ayah['id']} token {position + 1}: "
                            f"gloss {gloss!r} but transliteration {translit!r}"
                        )

    # Byte-for-byte reproducibility from source, when the source is reachable.
    source = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else _builder.DEFAULT_SOURCE
    translit_source = (pathlib.Path(sys.argv[2]) if len(sys.argv) > 2
                       else _builder.DEFAULT_TRANSLIT_SOURCE)
    if source.exists() and translit_source.exists():
        english, en_failures, _, _ = _builder.build_layer(
            quran, json.loads(source.read_text(encoding="utf-8")), "e", "english")
        latin, tr_failures, _, _ = _builder.build_layer(
            quran, json.loads(translit_source.read_text(encoding="utf-8")), "t", "translit")
        for line in en_failures + tr_failures:
            problems.append(f"rebuild: {line}")
        if {"v": 2, "en": english, "tr": latin} != packed:
            problems.append("pack does not match a fresh build from source")
    else:
        missing = [str(p) for p in (source, translit_source) if not p.exists()]
        print(f"note: source not found ({', '.join(missing)}) - skipped the rebuild check")

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:20]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)

    print(f"OK: {ayahs} ayahs, {tokens:,} tokens, both layers match their token counts")
    print(f"    {PACK.name}: {len(blob):,} bytes on disk, {len(raw):,} inflated")


if __name__ == "__main__":
    main()
