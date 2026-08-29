#!/usr/bin/env python3
"""Rebuild the .solidpack bundles from the loose .json.deflate sources.

A solidpack is ONE xz stream over ALL of a family's raw JSONs concatenated,
which is what makes it small: the 12 beta qiraah JSONs are ~97% identical to
each other, so solid compression collapses 17.6 MB of JSON (3.5 MB as
individual deflates) to ~0.44 MB. Individual per-file compression can never
see that redundancy.

Decompressed layout (what iPhone/Quran/QuranPack.swift's SolidPack reads):
    4 bytes  little-endian length N of the index JSON
    N bytes  index JSON: {"entries": [{"name", "offset", "length"}, ...]}
             offsets are relative to the byte right after the index
    payload  the raw (inflated) JSONs back to back

Run after the tajweed pipeline regenerates any Qiraah*/Tajweed* deflate:
    python3 Scripts/build_solidpacks.py
"""

import json
import lzma
import pathlib
import struct
import zlib

DATA = pathlib.Path(__file__).resolve().parent.parent / "Resources" / "Data" / "Quran"

FAMILIES = {
    "qiraah.solidpack": "Qiraah*.json.deflate",
    "tajweed.solidpack": "Tajweed*.json.deflate",
    # The printed-line tables (pipeline/printlines_build.py): where each riwayah's Islamweb
    # print breaks its lines, so page mode can set the same lines.
    "lines.solidpack": "Lines*.json.deflate",
}


def inflate(blob: bytes) -> bytes:
    # The pipeline writes raw deflate streams (no zlib header); older files may
    # carry the header, so try both.
    try:
        return zlib.decompress(blob)
    except zlib.error:
        return zlib.decompress(blob, -15)


def build(out_name: str, pattern: str) -> None:
    files = sorted(DATA.glob(pattern))
    if not files:
        raise SystemExit(f"no {pattern} files found in {DATA}")

    entries, payload = [], bytearray()
    for f in files:
        raw = inflate(f.read_bytes())
        entries.append({"name": f.name.removesuffix(".json.deflate"),
                        "offset": len(payload), "length": len(raw)})
        payload += raw

    index = json.dumps({"entries": entries}, separators=(",", ":")).encode()
    body = struct.pack("<I", len(index)) + index + bytes(payload)
    packed = lzma.compress(body, format=lzma.FORMAT_XZ,
                           preset=9 | lzma.PRESET_EXTREME)

    out = DATA / out_name
    out.write_bytes(packed)
    print(f"{out_name}: {len(files)} files, {len(body):,} raw -> {len(packed):,} packed")


if __name__ == "__main__":
    for out_name, pattern in FAMILIES.items():
        build(out_name, pattern)
