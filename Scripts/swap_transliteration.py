#!/usr/bin/env python3
"""Replace the ayah transliteration in quran.qpk (and the deprecated Quran.json it was built
from) with QUL's natural-reading scheme.

The pack shipped the Tanzil-style transliteration ("Bismi Allahi alrrahmani alrraheemi"),
which spells the assimilated definite article letter by letter. The replacement is QUL's
"English Transliteration (Tajweed)" (Resources/JSONs-Deprecated/QUL/
english-transliteration-tajweed.json.zip): "Bismil laahir Rahmaanir Raheem", written the way
the ayah is actually recited - long vowels doubled, the article assimilated, a hyphen between
a particle and its word, and on 389 ayahs the case ending that is dropped at a pause shown in
parentheses ("ghishaa-wa(tunw)").

Only the second of an ayah's four strings changes; every block keeps its rows, so the eager
table's block indices are untouched. The rewritten pack is re-read through the same record
walk the app uses and every string compared before anything is written, and the manifest's
size and hash are refreshed.

    python3 Scripts/swap_transliteration.py
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACK = ROOT / "Resources" / "Data" / "Quran" / "quran.qpk"
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
SOURCE = ROOT / "Resources" / "JSONs-Deprecated" / "QUL" / "english-transliteration-tajweed.json.zip"

_spec = importlib.util.spec_from_file_location("reblock_packs", ROOT / "Scripts" / "reblock_packs.py")
_rb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_rb)


def read_source() -> dict[str, str]:
    with zipfile.ZipFile(SOURCE) as archive:
        names = [n for n in archive.namelist() if n.endswith(".json")]
        if len(names) != 1:
            raise SystemExit(f"{SOURCE.name}: expected one .json inside, found {names}")
        raw = json.loads(archive.read(names[0]).decode("utf-8"))
    return {key: " ".join(str(value).split()) for key, value in raw.items()}


def main() -> None:
    translit = read_source()
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    order = [f"{s['id']}:{a['id']}" for s in quran for a in s["ayahs"]]
    missing = [key for key in order if not translit.get(key)]
    if missing or len(translit) != len(order):
        raise SystemExit(f"source covers {len(translit)} ayahs, {len(missing)} missing: {missing[:5]}")

    pack = _rb.Qpk(PACK.read_bytes(), "quran")
    records = pack.records()
    if len(records) != len(order):
        raise SystemExit(f"pack holds {len(records)} rows, the Quran has {len(order)}")

    changed = 0
    new_rows = []
    for key, record in zip(order, records):
        replacement = translit[key].encode("utf-8")
        if replacement != record[1]:
            changed += 1
        new_rows.append((record[0], replacement, record[2], record[3]))

    rows_by_block: dict[int, list[int]] = {}
    for row, block in enumerate(pack.entries):
        rows_by_block.setdefault(block, []).append(row)
    for index, block in enumerate(pack.blocks):
        rows = rows_by_block.get(index, [])
        if not rows or rows != list(range(rows[0], rows[0] + len(rows))) or block["first"] != rows[0]:
            raise SystemExit(f"block {index} does not hold a contiguous row range starting at its first row")
        block["raw"] = b"".join(_rb.string_field(field) for row in rows for field in new_rows[row])

    data = pack.serialize()
    check = _rb.Qpk(data, "quran")
    if [tuple(r) for r in check.records()] != new_rows:
        raise SystemExit("the rewritten pack does not read back as written - nothing changed on disk")
    if check.surahs != pack.surahs:
        raise SystemExit("surah table changed - nothing written")

    PACK.write_bytes(data)
    for surah in quran:
        for ayah in surah["ayahs"]:
            ayah["textTransliteration"] = translit[f"{surah['id']}:{ayah['id']}"]
    QURAN_JSON.write_text(json.dumps(quran, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    manifest_path = PACK.parent / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    _rb.update_manifest(PACK, data, len(pack.blocks), manifest.get("blockTargetBytes", 0))
    manifest = json.loads(manifest_path.read_text())
    for entry in manifest.get("packs", []):
        if entry.get("name") == "quran":
            entry["sourceBytes"] = QURAN_JSON.stat().st_size
    manifest["transliterationNote"] = ("Ayah transliteration replaced 2026-09-07 by Scripts/swap_transliteration.py "
                                       "with QUL's English Transliteration (Tajweed).")
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print(f"{changed} of {len(order)} transliterations replaced; quran.qpk {len(data):,} bytes, {len(pack.blocks)} blocks")


if __name__ == "__main__":
    main()
