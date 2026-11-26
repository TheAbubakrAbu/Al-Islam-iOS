#!/usr/bin/env python3
"""Build Resources/Data/Hadith/HadithSearchWords.bin: the words of every narration in the eight
major collections, for Ask AI's described-passage search (2026-11-25).

"The hadith about the woman who went to hell because of a cat" is a description, and the hadith
search field's engine wants the typed words themselves, every one of them. `HadithDescribedSearch`
(iPhone/Helpers/AskAI/AskAIPassageSearch.swift) scores each narration on how rare the words it
shares with the description are, each word standing for its concept (hell, Fire; kill, slay). That
needs to know which narrations hold which words without opening them: 36,116 narrations are 60 MB
of text in 8 compressed packs, seconds of work on a phone, where this file unpacks in milliseconds.

Same layout as TafsirKeywords.bin (Scripts/build_tafsir_keywords.py), with no ayah table: an
"edition" is a collection, a "passage" a narration, in the collection's own row order (the order of
`HadithBookData.hadiths`). The app checks each collection's row count against the pack it opens and
leaves a collection out when they differ, so a stale file costs coverage, never a wrong citation.

    ./Scripts/build_hadith_search_words.py            # writes HadithSearchWords.bin.lzfse
    ./Scripts/build_hadith_search_words.py --check    # rebuilds in memory and compares with the shipped file

Run it after any rebuild of the .hpk packs.
"""
import struct
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reblock_packs as rp          # the .hpk reader
import compress_shipped as shipped  # Apple's LZFSE, the codec the app unpacks
from build_tafsir_keywords import MAGIC, words

ROOT = Path(__file__).resolve().parent.parent
HADITH = ROOT / "Resources" / "Data" / "Hadith"
OUT = HADITH / "HadithSearchWords.bin"
# The collections Ask AI's ranked hadith lane reads (`AskAIRetriever.keywordBookOrder`), in its order.
BOOKS = ["bukhari", "muslim", "nawawi40", "riyad_assalihin", "tirmidhi", "abudawud", "nasai", "ibnmajah"]
# A narration's distinct words past this many are its rarest-used tail; the longest run to thousands.
KEEP = 160


def build() -> bytes:
    vocabulary = {}
    books = []
    for slug in BOOKS:
        pack = rp.Hpk((HADITH / f"{slug}.hpk").read_bytes())
        rows = []
        for texts in pack.text_rows():
            # The narrator line and the narration: who told it is part of how a reader remembers it.
            counts = Counter(words(texts[1].decode("utf-8") + " " + texts[2].decode("utf-8")))
            top = sorted(counts.items(), key=lambda item: (-item[1], item[0]))[:KEEP]
            rows.append((min(sum(counts.values()), 65535),
                         [(vocabulary.setdefault(word, len(vocabulary)), min(tf, 255)) for word, tf in top]))
        books.append((slug, rows))

    if len(vocabulary) >= 1 << 24:
        sys.exit("vocabulary too large for 24 bits")
    out = bytearray()
    out += struct.pack("<IHHI", MAGIC, 1, len(books), len(vocabulary))
    for word, _ in sorted(vocabulary.items(), key=lambda kv: kv[1]):
        raw = word.encode("ascii")[:255]
        out += bytes([len(raw)]) + raw
    for slug, rows in books:
        raw = slug.encode("ascii")
        out += bytes([len(raw)]) + raw
        out += struct.pack("<II", len(rows), 0)
        for length, entry in rows:
            out += struct.pack("<HH", length, len(entry))
            for word, tf in entry:
                out += struct.pack("<I", word | (tf << 24))
    return bytes(out)


def main():
    blob = build()
    if "--check" in sys.argv:
        if shipped.read_shipped(OUT) != blob:
            sys.exit("HadithSearchWords.bin is stale: rebuild with ./Scripts/build_hadith_search_words.py")
        print(f"HadithSearchWords.bin is current ({len(blob):,} bytes unpacked)")
        return
    # Written plain, then compressed with the codec Scripts/compress_shipped.py lists for it (LZFSE).
    shipped.write_shipped(OUT, blob)


if __name__ == "__main__":
    main()
