#!/usr/bin/env python3
"""Build Resources/Data/Quran/TafsirKeywords.bin: what the three English tafsirs say about each
ayah, boiled down to search words, for Ask AI's described-passage search (2026-11-25).

A reader who half remembers a verse describes it in their own words ("the verse about fathers
killing their children out of shame"), and those are often the commentary's words rather than the
translation's: 16:58-59 says "bury it in the ground" and "humiliation", Ibn Kathir on it says
"daughters", "bury them alive", "dishonor". So each tafsir passage contributes its most telling
words (the KEEP highest by tf-idf, with how often each occurs) to the ayahs it covers, and
`QuranDescribedSearch` (iPhone/Helpers/AskAI/AskAIPassageSearch.swift) scores them as a second field
beside the translations. Measured on 40 described verses: the right verse in the first 14 for 37
with the translations alone and 39 with these words added.

Why a pack and not the tafsirs themselves at run time: indexing 22 MB of commentary on the phone
takes seconds of work and about 18 MB of memory; this file is unpacked in a few milliseconds.

The words are stored as they are written (lower case, letters only). The app stems them on load, so
the stemmer lives in one place.

FILE LAYOUT (little-endian)
    u32  magic "QSKW"
    u16  version (1)
    u16  edition count
    u32  vocabulary count
    vocabulary: per word, u8 length + ASCII bytes
    per edition:
        u8 slug length + slug bytes
        u32 passage count
        u32 ayah count, then per ayah: u8 surah, u16 ayah, u16 passage index
        per passage: u16 content-word count (capped), u16 kept-word count,
                     then per kept word: u32 vocabulary index (low 24 bits) | tf << 24 (tf capped at 255)

    ./Scripts/build_tafsir_keywords.py            # writes TafsirKeywords.bin.lzfse
    ./Scripts/build_tafsir_keywords.py --check    # rebuilds in memory and compares with the shipped file

Register a first build with ./Scripts/xcode_register.py (the project uses classic groups).
"""
import lzma
import math
import re
import struct
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reblock_packs as rp          # the .tpk reader
import compress_shipped as shipped  # Apple's LZFSE, the codec the app unpacks

ROOT = Path(__file__).resolve().parent.parent
TAFSIR = ROOT / "Resources" / "Data" / "Tafsir"
OUT = ROOT / "Resources" / "Data" / "Quran" / "TafsirKeywords.bin"
EDITIONS = ["en-tafsir-ibn-kathir", "en-tafsir-maarif-ul-quran", "en-tafsir-tazkirul-quran"]
KEEP = 120
MAGIC = 0x574B5351  # "QSKW"

# Words that say nothing about a passage. The app drops its own list again after stemming.
STOP = set("""a an the and or of to in on at by for with from as is are was were be been being it its this that
these those he she they them his her their you your we our i me my who whom whose which what when where why how do
does did not no nor so if then than there here have has had will would shall should can could may might must about
into out up down over under again also only very just one any all each some such both but because while s t d ll
re ve m o him us said say says saying upon unto thus thy thee thou ye shall hath verse verses ayah surah allah
""".split())

WORD = re.compile(r"[a-z]+")
TAG = re.compile(r"<[^>]+>")


def words(text: str):
    text = TAG.sub(" ", text).lower().replace("’", "'")
    return [w for w in WORD.findall(text) if len(w) > 2 and w not in STOP]


def read_edition(slug: str):
    pack = rp.Tpk((TAFSIR / f"{slug}.tpk").read_bytes())
    index = lzma.decompress(pack.index_blob)
    cursor = rp.Cursor(index)
    cursor.string()
    cursor.string()
    count = cursor.u32()
    table = []
    for _ in range(count):
        surah, ayah, passage, _start, _end = struct.unpack_from("<HHIHH", index, cursor.p)
        cursor.p += 12
        table.append((surah, ayah, passage))
    passages = {pid: content.decode("utf-8") for pid, _flags, _group, content in pack.passages()}
    return table, passages


def build() -> bytes:
    vocabulary = {}
    editions = []
    for slug in EDITIONS:
        table, passages = read_edition(slug)
        ids = sorted(passages)
        position = {pid: i for i, pid in enumerate(ids)}
        counts = [Counter(words(passages[pid])) for pid in ids]
        df = Counter()
        for c in counts:
            df.update(c.keys())
        n = len(ids)
        kept = []
        for c in counts:
            def weight(item):
                word, tf = item
                idf = math.log(1 + (n - df[word] + 0.5) / (df[word] + 0.5))
                return (tf / (tf + 1.5)) * idf
            # Ties broken by the word itself, so two builds of the same sources are the same bytes.
            top = sorted(c.items(), key=lambda item: (-weight(item), item[0]))[:KEEP]
            entry = []
            for word, tf in top:
                entry.append((vocabulary.setdefault(word, len(vocabulary)), min(tf, 255)))
            kept.append((min(sum(c.values()), 65535), entry))
        ayahs = [(surah, ayah, position[pid]) for surah, ayah, pid in table if pid in position]
        editions.append((slug, kept, ayahs))

    if len(vocabulary) >= 1 << 24:
        sys.exit("vocabulary too large for 24 bits")
    out = bytearray()
    out += struct.pack("<IHHI", MAGIC, 1, len(editions), len(vocabulary))
    for word, _ in sorted(vocabulary.items(), key=lambda kv: kv[1]):
        raw = word.encode("ascii")[:255]
        out += bytes([len(raw)]) + raw
    for slug, kept, ayahs in editions:
        raw = slug.encode("ascii")
        out += bytes([len(raw)]) + raw
        out += struct.pack("<I", len(kept))
        out += struct.pack("<I", len(ayahs))
        for surah, ayah, passage in ayahs:
            out += struct.pack("<BHH", surah, ayah, passage)
        for length, entry in kept:
            out += struct.pack("<HH", length, len(entry))
            for word, tf in entry:
                out += struct.pack("<I", word | (tf << 24))
    return bytes(out)


def main():
    blob = build()
    if "--check" in sys.argv:
        if shipped.read_shipped(OUT) != blob:
            sys.exit("TafsirKeywords.bin is stale: rebuild with ./Scripts/build_tafsir_keywords.py")
        print(f"TafsirKeywords.bin is current ({len(blob):,} bytes unpacked)")
        return
    # Written plain, then compressed with the codec Scripts/compress_shipped.py lists for it (LZFSE).
    shipped.write_shipped(OUT, blob)


if __name__ == "__main__":
    main()
