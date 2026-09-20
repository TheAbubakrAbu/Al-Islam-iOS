#!/usr/bin/env python3
"""Repair surah names in quran.qpk whose Arabic is missing a vowel mark.

Abu spotted al-Kawthar's header rendering as الكَوثر, with no fatha on the thaa, while the ayah text
in the very same screen writes ٱلۡكَوۡثَرَ. An audit of all 114 names against the Quran's own text
found exactly two such defects:

    108  الكَوثر   -> الكَوثَر     (thaa needs its fatha; the ayah has 062B 064E)
    102  التَّكاثُر -> التَّكَاثُر  (kaaf needs its fatha; the ayah has 0643 064E 0627)

Nothing else is wrong. The other ~140 "bare" letters the first pass flagged are either the definite
article's lam or genuine sukoon positions (al-Fajr's jeem really is silent), and this dataset's
convention is that sukoon is never written on a surah name. The two above are different: a letter
followed by a long-vowel carrier MUST carry a vowel, and these did not.

The names live in the pack's `eager` block, so patching them means rewriting that block: each string
is a u32 byte-length followed by UTF-8, and adding a fatha grows the string by two bytes. The header
carries the eager block's offset, compressed length and raw length, and the block table that follows
it holds absolute offsets into the file, so everything after the eager block shifts and every block
offset has to be rewritten. That is all this script does; no text other than the two names changes.

Idempotent: run it twice and the second run reports nothing to do.
"""

import struct
import sys
import lzma
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACK = ROOT / "Resources/Data/Quran/quran.qpk"

FATHA = "َ"

# (surah id, what the pack currently holds, what it should hold)
FIXES = [
    (108, "الكَوثر",
          "الكَوثَر"),
    (102, "التَّكاثُر",
          "التَّكَاثُر"),
]

LZFSE, LZMA = 1, 2


def decompress(blob: bytes, codec: int, raw_length: int) -> bytes:
    # Codec 2 is Apple's COMPRESSION_LZMA, which on this platform frames as an .xz stream - the
    # block really does start with the xz magic FD 37 7A 58 5A, not with LZMA-alone's header.
    if codec == LZMA:
        return lzma.decompress(blob, format=lzma.FORMAT_XZ)
    raise SystemExit(f"eager block uses codec {codec}; only LZMA is handled here")


def compress(blob: bytes, codec: int) -> bytes:
    if codec == LZMA:
        return lzma.compress(blob, format=lzma.FORMAT_XZ, preset=6)
    raise SystemExit(f"eager block uses codec {codec}; only LZMA is handled here")


def patch_eager(eager: bytes) -> tuple[bytes, list[str]]:
    """Rewrite the two names inside the decompressed eager block."""
    out = bytearray(eager)
    notes: list[str] = []
    for surah_id, old, new in FIXES:
        old_b, new_b = old.encode("utf-8"), new.encode("utf-8")
        # A length-prefixed string: find the u32 length immediately before the bytes.
        needle = struct.pack("<I", len(old_b)) + old_b
        already = struct.pack("<I", len(new_b)) + new_b
        if already in out:
            notes.append(f"  {surah_id}: already correct")
            continue
        count = out.count(needle)
        if count != 1:
            raise SystemExit(f"surah {surah_id}: expected exactly 1 occurrence of {old!r}, found {count}")
        out = bytearray(out.replace(needle, already))
        notes.append(f"  {surah_id}: {old} -> {new}")
    return bytes(out), notes


def main() -> None:
    data = bytearray(PACK.read_bytes())
    if bytes(data[:4]) != b"QRPK":
        raise SystemExit("not a quran pack")

    (magic, version, eager_codec, block_codec, block_count, _pad,
     record_count, unit_count, eager_off, eager_len, eager_raw,
     fingerprint, _reserved) = struct.unpack_from("<IHBBHHIIIIIQQ", data, 0)

    eager = decompress(bytes(data[eager_off:eager_off + eager_len]), eager_codec, eager_raw)
    if len(eager) != eager_raw:
        raise SystemExit(f"eager raw length mismatch: header {eager_raw}, decoded {len(eager)}")

    patched, notes = patch_eager(eager)
    print("\n".join(notes))
    if patched == eager:
        print("nothing to do")
        return

    new_blob = compress(patched, eager_codec)
    delta = len(new_blob) - eager_len

    # Read the block table (16 bytes per entry, starting at 48) before anything moves.
    blocks = []
    for i in range(block_count):
        blocks.append(list(struct.unpack_from("<IIII", data, 48 + i * 16)))

    # Rebuild the file: everything before the eager block, the new eager block, everything after.
    tail_start = eager_off + eager_len
    rebuilt = bytearray(data[:eager_off]) + bytearray(new_blob) + bytearray(data[tail_start:])

    # Fix the header's eager length and raw length. Offset 24, NOT 20: the header is
    # u32 magic / u16 version / u8 eagerCodec / u8 blockCodec / u16 blockCount / u16 pad /
    # u32 recordCount / u32 unitCount / u32 eagerOffset / u32 eagerLength / u32 eagerRawLength,
    # which puts eagerOffset at 20 and eagerLength at 24. Writing at 20 clobbers the OFFSET and
    # the pack stops opening at all (done once while writing this; the verify pass below is why
    # it was caught rather than shipped).
    struct.pack_into("<II", rebuilt, 24, len(new_blob), len(patched))

    # Every block offset at or after the eager block shifts by the size delta.
    for i, (first_record, offset, comp_len, raw_len) in enumerate(blocks):
        if offset >= tail_start:
            offset += delta
        elif offset >= eager_off:
            raise SystemExit(f"block {i} starts inside the eager block; refusing to guess")
        struct.pack_into("<IIII", rebuilt, 48 + i * 16, first_record, offset, comp_len, raw_len)

    verify(bytes(rebuilt))
    PACK.write_bytes(bytes(rebuilt))
    print(f"wrote {PACK} ({len(data)} -> {len(rebuilt)} bytes, eager {eager_len} -> {len(new_blob)})")


def verify(blob: bytes) -> None:
    """Re-open the rebuilt pack the way the app does, before it is written to disk.

    Checks the eager block decodes to its declared raw length, that all 114 surah records parse
    (a shifted offset shows up here as garbage or a crash), that the two names now read correctly,
    and that every ayah block still decompresses at its recorded offset.
    """
    (_magic, _version, eager_codec, _block_codec, block_count, _pad,
     record_count, _unit_count, eager_off, eager_len, eager_raw,
     _fp, _res) = struct.unpack_from("<IHBBHHIIIIIQQ", blob, 0)

    eager = decompress(blob[eager_off:eager_off + eager_len], eager_codec, eager_raw)
    if len(eager) != eager_raw:
        raise SystemExit(f"verify: eager raw {len(eager)} != header {eager_raw}")

    cursor = 0

    def u32() -> int:
        nonlocal cursor
        value = struct.unpack_from("<I", eager, cursor)[0]
        cursor += 4
        return value

    def u8() -> int:
        nonlocal cursor
        value = eager[cursor]
        cursor += 1
        return value

    def text() -> str:
        nonlocal cursor
        n = u32()
        if n <= 0:
            return ""
        value = eager[cursor:cursor + n].decode("utf-8")
        cursor += n
        return value

    count = u32()
    if count != record_count:
        raise SystemExit(f"verify: surah count {count} != header {record_count}")
    found = {}
    for _ in range(count):
        sid = u32(); u8()
        name = text(); text(); text(); text()
        for _ in range(9):
            u32()
        u8()
        for _ in range(u32()):
            u32()
        for _ in range(u32()):
            text()
        u32()
        found[sid] = name
    for surah_id, _old, new in FIXES:
        if found.get(surah_id) != new:
            raise SystemExit(f"verify: surah {surah_id} reads {found.get(surah_id)!r}, expected {new!r}")

    for i in range(block_count):
        _first, offset, comp_len, raw_len = struct.unpack_from("<IIII", blob, 48 + i * 16)
        decoded = decompress(blob[offset:offset + comp_len], eager_codec, raw_len)
        if len(decoded) != raw_len:
            raise SystemExit(f"verify: block {i} raw {len(decoded)} != {raw_len}")

    print(f"verified: {count} surahs, {block_count} blocks, both names correct")


if __name__ == "__main__":
    main()
