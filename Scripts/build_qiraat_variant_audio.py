#!/usr/bin/env python3
"""Build Resources/Data/Quran/QiraatVariantAudio.json.xz: paired clips for hearing a variant.

    ./Scripts/build_qiraat_variant_audio.py [/path/to/Tilawa]

SOURCE: Tilawa's generated src/data/generated/riwayahVariantAudio.ts (Jamil Hammoudeh, with
permission): for every place one of four riwayat reads a word differently from Hafs, the SAME
reciter reading the verse both ways, so the two clips differ in the reading and in nothing else.
Warsh, Qalun, ad-Duri and Shubah are covered; al-Bazzi, Qunbul and as-Susi have no reciter who
published both sides with timings, so they carry no audio.

A clip is either a whole per-verse file (EveryAyah, offsets -1) or a span inside a full-surah
recording (mp3quran, offsets in ms). URLs are built from the source row:
    kind "file" -> base + "/" + SSS + AAA + ".mp3" (AAA is the HAFS number)
    kind "span" -> base + SSS + ".mp3", then seek to the offsets.

Pack: {"version": 1, "sources": [{"reciter", "kind", "hafsBase", "riwayahBase"}],
       "riwayat": {"<this app's riwayah tag>": {"<surah>": [[hafsAyah, sourceIndex,
                    hafsStartMs, hafsEndMs, riwayahStartMs, riwayahEndMs], ...]}}}
"""
from __future__ import annotations

import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from tilawa_ts import eval_consts, xz_compress  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
OUT = ROOT / "Resources" / "Data" / "Quran" / "QiraatVariantAudio.json.xz"
TILAWA = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Tilawa"

# Tilawa's riwayah ids -> this app's riwayah tags (Settings.Riwayah).
TAGS = {
    "warsh": "Warsh an Nafi",
    "qaloun": "Qalun an Nafi",
    "douri": "ad-Duri an Abi Amr",
    "shuba": "Shubah an Asim",
}


def main() -> None:
    source = TILAWA / "src" / "data" / "generated" / "riwayahVariantAudio.ts"
    if not source.exists():
        raise SystemExit(f"source not found: {source}")
    data = eval_consts(source, ["VARIANT_AUDIO_SOURCES", "RIWAYAH_VARIANT_AUDIO"])
    sources = data["VARIANT_AUDIO_SOURCES"]
    table = data["RIWAYAH_VARIANT_AUDIO"]

    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    counts = {int(s["id"]): len(s["ayahs"]) for s in quran}

    riwayat = {}
    problems = []
    places = 0
    per_tag = {}
    for tilawa_id, by_surah in table.items():
        tag = TAGS.get(tilawa_id)
        if tag is None:
            problems.append(f"unknown riwayah id {tilawa_id}")
            continue
        out = {}
        for surah_key, rows in by_surah.items():
            surah = int(surah_key)
            if surah not in counts:
                problems.append(f"{tilawa_id}: no surah {surah}")
                continue
            clean = []
            for row in rows:
                if len(row) != 6:
                    problems.append(f"{tilawa_id} {surah}: malformed row {row}")
                    continue
                ayah, src = int(row[0]), int(row[1])
                if not 1 <= ayah <= counts[surah]:
                    problems.append(f"{tilawa_id}: no ayah {surah}:{ayah}")
                    continue
                if not 0 <= src < len(sources):
                    problems.append(f"{tilawa_id} {surah}:{ayah}: source {src} out of range")
                    continue
                kind = sources[src]["kind"]
                if kind == "span" and (row[2] < 0 or row[3] <= row[2] or row[4] < 0 or row[5] <= row[4]):
                    problems.append(f"{tilawa_id} {surah}:{ayah}: bad span offsets {row[2:]}")
                    continue
                clean.append([ayah, src, int(row[2]), int(row[3]), int(row[4]), int(row[5])])
            if clean:
                out[str(surah)] = clean
                places += len(clean)
                per_tag[tag] = per_tag.get(tag, 0) + len(clean)
        riwayat[tag] = out

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:40]:
            print("  " + line, file=sys.stderr)
        raise SystemExit(1)

    pack = {
        "version": 1,
        "sources": [{"reciter": s["reciter"], "kind": s["kind"],
                     "hafsBase": s["hafsBase"], "riwayahBase": s["riwayahBase"]} for s in sources],
        "riwayat": riwayat,
    }
    body = json.dumps(pack, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    blob = xz_compress(body)
    OUT.write_bytes(blob)
    print(f"{places} places across {len(riwayat)} riwayat: " + ", ".join(f"{k} {v}" for k, v in per_tag.items()))
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} xz")


if __name__ == "__main__":
    main()
