#!/usr/bin/env python3
"""Compress a data file the app ships, in place: FILE becomes FILE.xz or FILE.lzfse (2026-11-23).

The App Store's install size counts every bundle byte uncompressed. These files were shipped raw:

    Resources/Data/Quran/quran-search.qsp         11.6 MB -> 1.6 MB  xz     unpacked once per app build into
                                                                           Caches and mapped (it stays mapped
                                                                           for lookups)
    Resources/Data/Quran/CrossLanguageLexicon.bin  0.47 -> 0.16      lzfse  unpacked in memory on load
    Resources/Data/Quran/WordAlignment.bin         0.37 -> 0.14      lzfse  unpacked in memory on load
    Resources/Data/Hadith/HadithLexicon.bin        0.16 -> 0.06      lzfse  unpacked in memory on load
    Resources/Data/Semantic/*.svec                 one byte per      lzfse  unpacked in memory on the first AI
                                                   component                search of every launch

The codec follows how often the app unpacks a file. xz is the smallest and the slowest to unpack, so it is
kept for the one file unpacked once per install. Everything unpacked on every launch is LZFSE, which Apple's
decoder unpacks about ten times faster (the three .bin together: 10 ms as xz, under 1 ms as LZFSE, on a Mac)
for a few tens of KB more. Abu, 2026-11-23: speed before storage.

The app finds a file in any of its three forms (`ShippedFile` in iPhone/Quran/Models/QuranPack.swift), so a
builder may keep writing the plain file and run this after it. Each written file is decoded again here with
Apple's own libcompression, the decoder the app uses, and must give back the original bytes exactly; only
then is the plain file deleted.

    ./Scripts/compress_shipped.py [--codec xz|lzfse] FILE [FILE ...]
    ./Scripts/compress_shipped.py --all       # every file above that is plain on disk right now
"""
import ctypes
import lzma
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(REPO, "Resources", "Data")
# The shipped set and each one's codec.
SHIPPED = {
    os.path.join(DATA, "Quran", "quran-search.qsp"): "xz",
    os.path.join(DATA, "Quran", "CrossLanguageLexicon.bin"): "lzfse",
    os.path.join(DATA, "Quran", "WordAlignment.bin"): "lzfse",
    os.path.join(DATA, "Hadith", "HadithLexicon.bin"): "lzfse",
    os.path.join(DATA, "Semantic", "quran-en.svec"): "lzfse",
    os.path.join(DATA, "Semantic", "hadith-all.svec"): "lzfse",
}

COMPRESSION_LZMA = 0x306
COMPRESSION_LZFSE = 0x801
_lib = ctypes.CDLL("/usr/lib/libcompression.dylib")
for _fn in (_lib.compression_encode_buffer, _lib.compression_decode_buffer):
    _fn.restype = ctypes.c_size_t
    _fn.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p,
                    ctypes.c_int]


def apple_decode(blob, raw_len, algorithm):
    dst = ctypes.create_string_buffer(raw_len + 1)
    n = _lib.compression_decode_buffer(dst, raw_len + 1, blob, len(blob), None, algorithm)
    return dst.raw[:n]


def encode(raw, codec):
    if codec == "xz":
        # CRC32 and a dictionary no larger than the file: what Apple's LZMA decoder takes (memory note
        # qpk-pack-rebuild, and every .xz the app already ships).
        dict_size = 1 << 16
        while dict_size < len(raw) and dict_size < (1 << 26):
            dict_size <<= 1
        filters = [{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME, "dict_size": dict_size}]
        return lzma.compress(raw, format=lzma.FORMAT_XZ, check=lzma.CHECK_CRC32, filters=filters), COMPRESSION_LZMA
    if codec == "lzfse":
        cap = len(raw) + 65536
        dst = ctypes.create_string_buffer(cap)
        n = _lib.compression_encode_buffer(dst, cap, raw, len(raw), None, COMPRESSION_LZFSE)
        if n == 0:
            sys.exit(f"lzfse encode failed")
        return dst.raw[:n], COMPRESSION_LZFSE
    sys.exit(f"unknown codec {codec}")


def compress(path, codec):
    raw = open(path, "rb").read()
    blob, algorithm = encode(raw, codec)
    if apple_decode(blob, len(raw), algorithm) != raw:
        sys.exit(f"{path}: libcompression does not give back the original bytes; nothing written")
    out = f"{path}.{codec}"
    for stale in (f"{path}.xz", f"{path}.lzfse"):
        if os.path.exists(stale) and stale != out:
            os.remove(stale)
    with open(out + ".tmp", "wb") as f:
        f.write(blob)
    os.replace(out + ".tmp", out)
    os.remove(path)
    print(f"{os.path.relpath(out, REPO)}: {len(raw) / 1e6:.2f} MB -> {len(blob) / 1e6:.2f} MB")


def read_shipped(path):
    """The bytes of a shipped file in whichever form is on disk (plain, .xz or .lzfse); None if absent.
    For builders that compare what they build with what ships (`--check`)."""
    path = str(path)
    if os.path.exists(path):
        return open(path, "rb").read()
    if os.path.exists(path + ".xz"):
        return lzma.decompress(open(path + ".xz", "rb").read())
    if os.path.exists(path + ".lzfse"):
        blob = open(path + ".lzfse", "rb").read()
        # LZFSE carries no total size up front; the files here inflate well under 50x.
        out = apple_decode(blob, len(blob) * 50, COMPRESSION_LZFSE)
        return out or None
    return None


def write_shipped(path, data):
    """Write a shipped file the way it ships: plain, then compressed with its codec (SHIPPED)."""
    path = os.path.abspath(str(path))
    with open(path, "wb") as f:
        f.write(data)
    compress(path, SHIPPED.get(path, "xz"))


def main(argv):
    if argv == ["--all"]:
        todo = [(p, c) for p, c in SHIPPED.items() if os.path.exists(p)]
        if not todo:
            print("every shipped file is already compressed")
        for path, codec in todo:
            compress(path, codec)
        return
    codec = None
    if argv[:1] == ["--codec"]:
        codec, argv = argv[1], argv[2:]
    if not argv:
        sys.exit(__doc__)
    for path in argv:
        path = os.path.abspath(path)
        compress(path, codec or SHIPPED.get(path, "xz"))


if __name__ == "__main__":
    main(sys.argv[1:])
