#!/usr/bin/env python3
"""Re-block the bundled .hpk / .tpk / .qpk packs in place, losslessly.

The packs are block-compressed (the readers decompress ONE block per read, see
iPhone/Hadith/HadithPack.swift, iPhone/Quran/TafsirPack.swift and iPhone/Quran/QuranPack.swift
for the byte layouts). Their builders live in other repos (Hadith-JSON-Engine, Tafsir-Corpus,
Quran-Tajweed-Engine) and wrote 256 KB blocks. Bigger blocks compress better because LZMA gets
a longer history to match against, and the readers are table-driven, so the block size is a
DATA decision: this script decodes every block, concatenates consecutive ones up to a target
raw size (or into one solid block), re-encodes, patches every stored block index, and rewrites
the file. Nothing about the content changes - `--verify` (on by default) re-reads the written
pack through the same record walk the app does and compares every string against the original.

    python3 Scripts/reblock_packs.py                   # all packs, 1 MiB text blocks, qiraat solid
    python3 Scripts/reblock_packs.py --dry-run         # sizes only, nothing written
    python3 Scripts/reblock_packs.py --target-bytes 2097152 Resources/Data/Hadith/bukhari.hpk

What changes per format
  .hpk  text + search payloads of consecutive blocks are merged (the search payload is
        re-serialised: count / lengths / NUL-terminated folds), the eager section's per-hadith
        u16 block index is patched and re-encoded. Codecs are kept (text LZMA, search LZFSE).
  .tpk  passage records are back to back in id order, so a merged block is a plain
        concatenation; the index section is copied verbatim.
  .qpk  quran: per-ayah block indices patched; qiraat: one solid block (the seven readings are
        ~97% identical text, which only a shared LZMA history can exploit; the reader walks past
        the readings stored before the one asked for); surahinfos: blocks merged, the reader
        walks past the entries stored before the surah asked for.

LZMA blocks are written by Python's lzma (xz container, preset 9e) with the dictionary sized to
the block's raw length, so a decoder never allocates more than the block needs. LZFSE goes
through libcompression itself (ctypes), which is also what re-checks every LZMA block: the
verify pass decodes each written block with Apple's decoder, the one the app uses.
"""
import argparse
import ctypes
import hashlib
import json
import lzma
import os
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "Resources" / "Data"

CODEC_LZFSE = 1
CODEC_LZMA = 2
COMPRESSION_LZFSE = 0x801
COMPRESSION_LZMA = 0x306

_lib = ctypes.CDLL("/usr/lib/libcompression.dylib")
_lib.compression_decode_buffer.restype = ctypes.c_size_t
_lib.compression_decode_buffer.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p,
                                           ctypes.c_size_t, ctypes.c_void_p, ctypes.c_int]
_lib.compression_encode_buffer.restype = ctypes.c_size_t
_lib.compression_encode_buffer.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p,
                                           ctypes.c_size_t, ctypes.c_void_p, ctypes.c_int]


def apple_decode(blob: bytes, raw_len: int, algorithm: int) -> bytes:
    dst = ctypes.create_string_buffer(raw_len)
    n = _lib.compression_decode_buffer(dst, raw_len, blob, len(blob), None, algorithm)
    if n != raw_len:
        raise ValueError(f"libcompression decoded {n} of {raw_len} bytes")
    return dst.raw


def apple_encode(raw: bytes, algorithm: int) -> bytes:
    cap = len(raw) + 65536
    dst = ctypes.create_string_buffer(cap)
    n = _lib.compression_encode_buffer(dst, cap, raw, len(raw), None, algorithm)
    if n == 0:
        raise ValueError("libcompression encode failed")
    return dst.raw[:n]


def xz_encode(raw: bytes) -> bytes:
    # Dictionary = the smallest power of two that holds the whole block (LZMA can never match
    # further back than the input anyway); floor 64 KiB, ceiling 64 MiB (xz's own maximum preset).
    dict_size = 1 << 16
    while dict_size < len(raw) and dict_size < (1 << 26):
        dict_size <<= 1
    filters = [{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME, "dict_size": dict_size}]
    return lzma.compress(raw, format=lzma.FORMAT_XZ, check=lzma.CHECK_CRC32, filters=filters)


def decode(codec: int, blob: bytes, raw_len: int) -> bytes:
    if codec == CODEC_LZMA:
        out = lzma.decompress(blob)
        if len(out) != raw_len:
            raise ValueError(f"xz decoded {len(out)} of {raw_len}")
        return out
    if codec == CODEC_LZFSE:
        return apple_decode(blob, raw_len, COMPRESSION_LZFSE)
    raise ValueError(f"unknown codec {codec}")


def encode(codec: int, raw: bytes) -> bytes:
    if codec == CODEC_LZMA:
        blob = xz_encode(raw)
        # The app decodes with libcompression, not liblzma - prove the stream is one it accepts.
        if apple_decode(blob, len(raw), COMPRESSION_LZMA) != raw:
            raise ValueError("Apple's LZMA decoder disagrees with liblzma on a written block")
        return blob
    if codec == CODEC_LZFSE:
        blob = apple_encode(raw, COMPRESSION_LZFSE)
        if apple_decode(blob, len(raw), COMPRESSION_LZFSE) != raw:
            raise ValueError("LZFSE round trip failed")
        return blob
    raise ValueError(f"unknown codec {codec}")


class Cursor:
    """Little-endian reader over bytes, mirroring the app's PackReader / QuranPackReader."""

    def __init__(self, data: bytes, pos: int = 0):
        self.d = data
        self.p = pos

    @property
    def remaining(self) -> int:
        return len(self.d) - self.p

    def u8(self) -> int:
        v = self.d[self.p]
        self.p += 1
        return v

    def u16(self) -> int:
        v = struct.unpack_from("<H", self.d, self.p)[0]
        self.p += 2
        return v

    def u32(self) -> int:
        v = struct.unpack_from("<I", self.d, self.p)[0]
        self.p += 4
        return v

    def i32(self) -> int:
        v = struct.unpack_from("<i", self.d, self.p)[0]
        self.p += 4
        return v

    def u64(self) -> int:
        v = struct.unpack_from("<Q", self.d, self.p)[0]
        self.p += 8
        return v

    def string(self) -> bytes:
        n = self.u32()
        v = self.d[self.p:self.p + n]
        self.p += n
        return v


def string_field(s: bytes) -> bytes:
    return struct.pack("<I", len(s)) + s


def group_blocks(raw_sizes, target, solid):
    """Consecutive runs of old block indices whose raw total stays within target."""
    if solid:
        return [list(range(len(raw_sizes)))]
    groups, current, total = [], [], 0
    for i, size in enumerate(raw_sizes):
        if current and total + size > target:
            groups.append(current)
            current, total = [], 0
        current.append(i)
        total += size
    if current:
        groups.append(current)
    return groups


# MARK: - .hpk

HPK_HEADER = "<IHBBBBHIIIIIQQ"
HPK_MAGIC = 0x4B50_4448


class Hpk:
    def __init__(self, data: bytes):
        (magic, version, self.eager_codec, self.text_codec, self.search_codec, _reserved,
         block_count, self.chapter_count, self.hadith_count, eager_off, eager_len, self.eager_raw_len,
         self.fold_fp, self.blocked_fp) = struct.unpack_from(HPK_HEADER, data, 0)
        if magic != HPK_MAGIC or version != 4:
            raise ValueError("not an .hpk v4")
        self.version = version
        table = [struct.unpack_from("<IIIIIII", data, 48 + 28 * i) for i in range(block_count)]
        self.blocks = []
        for first_row, t_off, t_len, t_raw, s_off, s_len, s_raw in table:
            self.blocks.append({
                "first_row": first_row,
                "text": decode(self.text_codec, data[t_off:t_off + t_len], t_raw),
                "search": decode(self.search_codec, data[s_off:s_off + s_len], s_raw),
            })
        self.eager = bytearray(decode(self.eager_codec, data[eager_off:eager_off + eager_len],
                                      self.eager_raw_len))
        self._parse_eager()

    def _parse_eager(self):
        c = Cursor(self.eager)
        self.titles = [c.string() for _ in range(4)]
        chapter_count = c.u32()
        self.chapters = []
        for _ in range(chapter_count):
            cid = c.i32()
            first_row = c.u32()
            row_count = c.u32()
            strings = [c.string() for _ in range(4)]
            self.chapters.append((cid, first_row, row_count, strings))
        hadith_count = c.u32()
        self.hadith_records_offset = c.p
        if c.remaining != 20 * hadith_count:
            raise ValueError(f"eager hadith table is {c.remaining} bytes for {hadith_count} rows")
        self.rows = []
        for i in range(hadith_count):
            at = self.hadith_records_offset + 20 * i
            hid, id_in_book, chapter_id, citation, suffix, block, flags = struct.unpack_from("<IIiIBHB", self.eager, at)
            self.rows.append((hid, id_in_book, chapter_id, citation, suffix, block, flags))

    def set_row_block(self, row: int, block: int):
        # u32 id, u32 idInBook, i32 chapterId, u32 citationBase, u8 suffix, u16 block, u8 flags
        at = self.hadith_records_offset + 20 * row + 17
        struct.pack_into("<H", self.eager, at, block)

    # The walks the app does, for verification.
    def text_rows(self):
        parsed = [parse_strings(b["text"]) for b in self.blocks]
        out = []
        for row, rec in enumerate(self.rows):
            block = rec[5]
            slot = (row - self.blocks[block]["first_row"]) * 4
            out.append(tuple(parsed[block][slot:slot + 4]))
        return out

    def search_rows(self):
        parsed = [parse_search(b["search"]) for b in self.blocks]
        out = []
        for row, rec in enumerate(self.rows):
            block = rec[5]
            slot = row - self.blocks[block]["first_row"]
            arabic, english = parsed[block]
            out.append((arabic[slot], english[slot]))
        return out

    def reblock(self, target: int):
        groups = group_blocks([len(b["text"]) for b in self.blocks], target, solid=False)
        remap = {}
        new_blocks = []
        for new_index, group in enumerate(groups):
            for old in group:
                remap[old] = new_index
            new_blocks.append({
                "first_row": self.blocks[group[0]]["first_row"],
                "text": b"".join(self.blocks[i]["text"] for i in group),
                "search": merge_search([self.blocks[i]["search"] for i in group]),
            })
        for row, rec in enumerate(self.rows):
            self.set_row_block(row, remap[rec[5]])
        self.blocks = new_blocks
        self._parse_eager()

    def serialize(self) -> bytes:
        eager_blob = encode(self.eager_codec, bytes(self.eager))
        table_size = 28 * len(self.blocks)
        eager_off = 48 + table_size
        cursor = eager_off + len(eager_blob)
        table = []
        payloads = []
        for b in self.blocks:
            t = encode(self.text_codec, b["text"])
            s = encode(self.search_codec, b["search"])
            table.append(struct.pack("<IIIIIII", b["first_row"], cursor, len(t), len(b["text"]),
                                     cursor + len(t), len(s), len(b["search"])))
            payloads.append(t + s)
            cursor += len(t) + len(s)
        header = struct.pack(HPK_HEADER, HPK_MAGIC, self.version, self.eager_codec, self.text_codec,
                             self.search_codec, 0, len(self.blocks), self.chapter_count, self.hadith_count,
                             eager_off, len(eager_blob), len(self.eager), self.fold_fp, self.blocked_fp)
        return header + b"".join(table) + eager_blob + b"".join(payloads)


def parse_strings(raw: bytes):
    c = Cursor(raw)
    out = []
    while c.remaining >= 4:
        out.append(c.string())
    return out


def parse_search(raw: bytes):
    c = Cursor(raw)
    count = c.u32()
    arabic_section = c.u32()
    arabic_lengths = [c.u32() for _ in range(count)]
    english_lengths = [c.u32() for _ in range(count)]
    arabic = []
    p = c.p
    for n in arabic_lengths:
        arabic.append(raw[p:p + n])
        if raw[p + n] != 0:
            raise ValueError("search record not NUL-terminated")
        p += n + 1
    if p != c.p + arabic_section:
        raise ValueError("arabic section length mismatch")
    english = []
    for n in english_lengths:
        english.append(raw[p:p + n])
        if raw[p + n] != 0:
            raise ValueError("search record not NUL-terminated")
        p += n + 1
    if p != len(raw):
        raise ValueError("search payload has trailing bytes")
    return arabic, english


def merge_search(payloads):
    arabic, english = [], []
    for p in payloads:
        a, e = parse_search(p)
        arabic += a
        english += e
    a_section = b"".join(s + b"\0" for s in arabic)
    e_section = b"".join(s + b"\0" for s in english)
    head = struct.pack("<II", len(arabic), len(a_section))
    lengths = b"".join(struct.pack("<I", len(s)) for s in arabic) + b"".join(struct.pack("<I", len(s)) for s in english)
    return head + lengths + a_section + e_section


# MARK: - .tpk

TPK_HEADER = "<IHBBHHIIIIIQQ"
TPK_MAGIC = 0x4B50_4654


class Tpk:
    def __init__(self, data: bytes):
        (magic, version, codec, _r1, block_count, _r2, self.ayah_count, self.passage_count,
         index_off, index_len, self.index_raw_len, self.fingerprint, _r3) = struct.unpack_from(TPK_HEADER, data, 0)
        if magic != TPK_MAGIC or version != 1 or codec != CODEC_LZMA:
            raise ValueError("not a .tpk v1 / LZMA")
        self.version, self.codec = version, codec
        self.index_blob = data[index_off:index_off + index_len]
        if len(lzma.decompress(self.index_blob)) != self.index_raw_len:
            raise ValueError("index raw length mismatch")
        table = [struct.unpack_from("<IIII", data, 48 + 16 * i) for i in range(block_count)]
        self.blocks = [{"first": first, "raw": decode(codec, data[off:off + length], raw_len)}
                       for first, off, length, raw_len in table]

    def passages(self):
        out = []
        for b in self.blocks:
            c = Cursor(b["raw"])
            slot = 0
            while c.remaining >= 5:
                flags = c.u8()
                group = c.string() if flags & 1 else None
                out.append((b["first"] + slot, flags, group, c.string()))
                slot += 1
        return out

    def reblock(self, target: int):
        groups = group_blocks([len(b["raw"]) for b in self.blocks], target, solid=False)
        self.blocks = [{"first": self.blocks[g[0]]["first"],
                        "raw": b"".join(self.blocks[i]["raw"] for i in g)} for g in groups]

    def serialize(self) -> bytes:
        table_size = 16 * len(self.blocks)
        index_off = 48 + table_size
        cursor = index_off + len(self.index_blob)
        table, payloads = [], []
        for b in self.blocks:
            blob = encode(self.codec, b["raw"])
            table.append(struct.pack("<IIII", b["first"], cursor, len(blob), len(b["raw"])))
            payloads.append(blob)
            cursor += len(blob)
        header = struct.pack(TPK_HEADER, TPK_MAGIC, self.version, self.codec, 0, len(self.blocks), 0,
                             self.ayah_count, self.passage_count, index_off, len(self.index_blob),
                             self.index_raw_len, self.fingerprint, 0)
        return header + b"".join(table) + self.index_blob + b"".join(payloads)


# MARK: - .qpk

QPK_HEADER = "<IHBBHHIIIIIQQ"
QPK_MAGIC = 0x4B50_5251


class Qpk:
    def __init__(self, data: bytes, kind: str):
        (magic, version, self.eager_codec, self.block_codec, block_count, _r1, self.record_count,
         self.unit_count, eager_off, eager_len, eager_raw, self.fingerprint, _r2) = struct.unpack_from(QPK_HEADER, data, 0)
        if magic != QPK_MAGIC or version != 1:
            raise ValueError("not a .qpk v1")
        self.version, self.kind = version, kind
        table = [struct.unpack_from("<IIII", data, 48 + 16 * i) for i in range(block_count)]
        self.blocks = [{"first": first, "raw": decode(self.block_codec, data[off:off + length], raw_len)}
                       for first, off, length, raw_len in table]
        self.eager = bytearray(decode(self.eager_codec, data[eager_off:eager_off + eager_len], eager_raw))
        self._parse_eager()

    def _parse_eager(self):
        """Locate every stored block index (its byte offset in the eager section) per pack kind."""
        c = Cursor(self.eager)
        self.block_fields = []      # (offset of the u16, value)
        self.entries = []           # kind-specific descriptors used by the verification walks
        if self.kind == "quran":
            surah_count = c.u32()
            self.surahs = []
            for _ in range(surah_count):
                sid = c.u32()
                c.u8()
                for _ in range(4):
                    c.string()
                for _ in range(9):
                    c.u32()
                c.u8()
                for _ in range(c.u32()):
                    c.u32()
                for _ in range(c.u32()):
                    c.string()
                first_row = c.u32()
                self.surahs.append((sid, first_row))
            ayah_count = c.u32()
            if c.remaining != 18 * ayah_count:
                raise ValueError("ayah table size mismatch")
            for i in range(ayah_count):
                at = c.p + 18 * i
                block = struct.unpack_from("<H", self.eager, at + 16)[0]
                self.block_fields.append((at + 16, block))
                self.entries.append(block)
            c.p += 18 * ayah_count
        elif self.kind == "qiraat":
            count = c.u32()
            for _ in range(count):
                key = c.string()
                surah_count = c.u32()
                counts = []
                for _ in range(surah_count):
                    sid = c.u32()
                    counts.append((sid, c.u32()))
                at = c.p
                block = c.u16()
                self.block_fields.append((at, block))
                self.entries.append((key, counts, block))
        elif self.kind == "surahinfos":
            count = c.u32()
            for _ in range(count):
                sid = c.u32()
                names = [c.string() for _ in range(c.u32())]
                at = c.p
                block = c.u16()
                self.block_fields.append((at, block))
                self.entries.append((sid, names, block))
        else:
            raise ValueError(f"unknown qpk kind {self.kind}")
        if c.remaining != 0:
            raise ValueError("eager section has trailing bytes")

    # Verification walks, mirroring QuranPack / QiraatPack / SurahInfoPack (including the
    # "skip the entries stored before this one in a shared block" rule the readers now apply).
    def records(self):
        if self.kind == "quran":
            parsed = [parse_strings(b["raw"]) for b in self.blocks]
            first_row = {}
            for row, block in enumerate(self.entries):
                first_row.setdefault(block, row)
            return [tuple(parsed[block][(row - first_row[block]) * 4:(row - first_row[block]) * 4 + 4])
                    for row, block in enumerate(self.entries)]
        if self.kind == "qiraat":
            out = []
            cursors = {}
            for key, counts, block in self.entries:
                c = cursors.setdefault(block, Cursor(self.blocks[block]["raw"]))
                ayahs = []
                for sid, n in counts:
                    for _ in range(n):
                        ayahs.append((sid, c.u32(), c.string()))
                out.append((key, ayahs))
            return out
        out = []
        cursors = {}
        for sid, names, block in self.entries:
            c = cursors.setdefault(block, Cursor(self.blocks[block]["raw"]))
            out.append((sid, [(name, c.string()) for name in names]))
        return out

    def reblock(self, target: int, solid: bool):
        old_blocks = [f[1] for f in self.block_fields]
        if any(b > a for a, b in zip(old_blocks[1:], old_blocks)):
            raise ValueError("stored block indices are not in eager order; a shared block would be walked wrong")
        groups = group_blocks([len(b["raw"]) for b in self.blocks], target, solid)
        remap = {}
        for new_index, g in enumerate(groups):
            for old in g:
                remap[old] = new_index
        for offset, old in self.block_fields:
            struct.pack_into("<H", self.eager, offset, remap[old])
        self.blocks = [{"first": self.blocks[g[0]]["first"],
                        "raw": b"".join(self.blocks[i]["raw"] for i in g)} for g in groups]
        self._parse_eager()

    def serialize(self) -> bytes:
        eager_blob = encode(self.eager_codec, bytes(self.eager))
        table_size = 16 * len(self.blocks)
        eager_off = 48 + table_size
        cursor = eager_off + len(eager_blob)
        table, payloads = [], []
        for b in self.blocks:
            blob = encode(self.block_codec, b["raw"])
            table.append(struct.pack("<IIII", b["first"], cursor, len(blob), len(b["raw"])))
            payloads.append(blob)
            cursor += len(blob)
        header = struct.pack(QPK_HEADER, QPK_MAGIC, self.version, self.eager_codec, self.block_codec,
                             len(self.blocks), 0, self.record_count, self.unit_count, eager_off,
                             len(eager_blob), len(self.eager), self.fingerprint, 0)
        return header + b"".join(table) + eager_blob + b"".join(payloads)


# MARK: - Driver

def load(path: Path):
    data = path.read_bytes()
    if path.suffix == ".hpk":
        return Hpk(data)
    if path.suffix == ".tpk":
        return Tpk(data)
    if path.suffix == ".qpk":
        return Qpk(data, path.stem)
    raise ValueError(f"unsupported pack {path}")


def snapshot(pack):
    if isinstance(pack, Hpk):
        return {"titles": pack.titles, "chapters": pack.chapters,
                "rows": [r[:5] + r[6:] for r in pack.rows], "text": pack.text_rows(), "search": pack.search_rows()}
    if isinstance(pack, Tpk):
        return {"index": pack.index_blob, "passages": pack.passages()}
    # Block indices are exactly what changes, so the eager comparison drops them.
    fixed = pack.surahs if pack.kind == "quran" else [e[:-1] for e in pack.entries]
    return {"records": pack.records(), "entries": fixed}


def update_manifest(path: Path, new_bytes: bytes, block_count: int, target: int):
    manifest_path = path.parent / "manifest.json"
    if not manifest_path.exists():
        return
    manifest = json.loads(manifest_path.read_text())
    digest = hashlib.sha256(new_bytes).hexdigest()
    key = "books" if "books" in manifest else "packs"
    for entry in manifest.get(key, []):
        name = entry.get("slug") or entry.get("name")
        if name == path.stem:
            entry["bytes"] = len(new_bytes)
            entry["sha256"] = digest
            if "blocks" in entry:
                entry["blocks"] = block_count
    if "blockTargetBytes" in manifest:
        manifest["blockTargetBytes"] = target
    if "blockTargetKB" in manifest:
        manifest["blockTargetKB"] = target // 1024
    if "totalBytes" in manifest:
        manifest["totalBytes"] = sum(e.get("bytes", 0) for e in manifest.get(key, []))
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("packs", nargs="*", type=Path, help="pack files (default: every bundled hpk/tpk/qpk)")
    ap.add_argument("--target-bytes", type=int, default=1 << 20, help="raw bytes per merged block (default 1 MiB)")
    ap.add_argument("--solid", default="qiraat", help="comma-separated pack stems to write as ONE block (default: qiraat)")
    ap.add_argument("--dry-run", action="store_true", help="report sizes, write nothing")
    ap.add_argument("--no-verify", action="store_true")
    args = ap.parse_args()

    packs = args.packs or sorted([*DATA.glob("Hadith/*.hpk"), *DATA.glob("Tafsir/*.tpk"),
                                  DATA / "Quran" / "quran.qpk", DATA / "Quran" / "qiraat.qpk",
                                  DATA / "Quran" / "surahinfos.qpk"])
    solid = set(filter(None, args.solid.split(",")))
    total_before = total_after = 0
    for path in packs:
        before = path.stat().st_size
        pack = load(path)
        reference = snapshot(pack) if not args.no_verify else None
        old_blocks = len(pack.blocks)
        if isinstance(pack, Qpk):
            pack.reblock(args.target_bytes, solid=path.stem in solid)
        else:
            pack.reblock(args.target_bytes)
        out = pack.serialize()
        if not args.no_verify:
            reread = (Hpk(out) if isinstance(pack, Hpk) else Tpk(out) if isinstance(pack, Tpk) else Qpk(out, pack.kind))
            if snapshot(reread) != reference:
                raise SystemExit(f"VERIFY FAILED for {path.name}: re-read content differs from the original")
        total_before += before
        total_after += len(out)
        print(f"{path.name:32} {old_blocks:4} -> {len(pack.blocks):3} blocks  {before:>10,} -> {len(out):>10,} bytes"
              f"  ({100.0 * (len(out) - before) / before:+.1f}%)")
        if not args.dry_run:
            tmp = path.with_suffix(path.suffix + ".tmp")
            tmp.write_bytes(out)
            os.replace(tmp, path)
            update_manifest(path, out, len(pack.blocks), args.target_bytes)
    print(f"{'TOTAL':32} {total_before:>10,} -> {total_after:>10,} bytes ({(total_after - total_before) / 1048576:+.2f} MB)")


if __name__ == "__main__":
    main()
