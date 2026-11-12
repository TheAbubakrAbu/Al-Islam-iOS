#!/usr/bin/env python3
"""Ship quran.com's per-word recitation timings, so the recited-word highlight asks nothing of the network.
    ./Scripts/build_word_timings.py [--cache DIR] [--reciters 7,9,...] [--quran Quran.json] [--stats]
The reader lights the word being recited (WordHighlight.swift, 2026-11-02) from the word segments quran.com
publishes for its reciters (`audio_files?segments=true`: `[position, fromMs, toMs]` per word, in the surah
file). Fetching them one surah at a time worked, but every first play of a surah waited on a request and
nothing lit offline. This packs them ahead of time, for every reciter the app maps to a quran.com id
(`qdcReciterID` in iPhone/Quran/Models/QuranStructs.swift), into Resources/Data/Quran/WordTimings.bin.
What is stored is exactly what the app's own parser (`AyahWordTimingStore.parse`) would have kept from the
same response: only `[position, from, to]` triples with to > from and position >= 1; a position the API
repeats (a word recorded in two pieces) merged to its first start and last end; a verse without any word
left out. Whole milliseconds (some reciters' values arrive as floats and are rounded).
The file (little-endian):
  "AIWT0001"  u32 header length  header JSON {"built", "source", "reciters": [{"id", "offset", "length",
  "surahs", "verses", "words"}]}  then one xz stream per reciter at `offset` from the end of the header.
A reciter's stream inflates to:
  u8 1 (version)  u8 114 (surahs)  u32 x 115 section offsets from the end of this table (the last = end)
  per surah: varint verses; per verse (ascending): varint ayah step, zigzag from - previous verse's to,
  varint to - from, varint words; per word: varint position step - 1, zigzag start - previous end (the
  verse's from before the first word), varint end - start.
ShippedWordTimings (WordHighlight.swift) reads the index, inflates one reciter when first played, and decodes
a surah on demand. Register the file once with Scripts/xcode_register.py; rerun this after adding a reciter.
The responses are cached under --cache (default build/qdc-cache, not in git) so a rerun is offline.
"""
import argparse, json, lzma, os, re, struct, sys, time, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Resources/Data/Quran/WordTimings.bin"
STRUCTS = ROOT / "iPhone/Quran/Models/QuranStructs.swift"
API = "https://api.qurancdn.com/api/qdc/audio/reciters/{r}/audio_files?chapter={c}&segments=true"
HEADERS = {"User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AlIslam/4.6.7"}
MAGIC = b"AIWT0001"
SURAHS = 114


def reciter_ids():
    ids = {int(m) for m in re.findall(r"qdcReciterID:\s*(\d+)", STRUCTS.read_text(encoding="utf-8"))}
    return sorted(ids)


def fetch(reciter, chapter, cache):
    path = cache / f"r{reciter}c{chapter}.json"
    if path.exists() and path.stat().st_size > 200:
        return json.loads(path.read_text(encoding="utf-8"))
    for attempt in range(4):
        try:
            req = urllib.request.Request(API.format(r=reciter, c=chapter), headers=HEADERS)
            with urllib.request.urlopen(req, timeout=40) as response:
                data = response.read()
            doc = json.loads(data)
            path.write_bytes(data)
            time.sleep(0.35)
            return doc
        except Exception as error:  # noqa: BLE001
            print(f"  retry {reciter}/{chapter}: {error}", file=sys.stderr)
            time.sleep(4 * (attempt + 1))
    return None


def millis(value):
    """An int or an integral-or-not float as whole milliseconds; anything else (a bool, a string) is None."""
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, float) and value == value:
        return int(round(value))
    return None


def parse(doc, surah):
    """`AyahWordTimingStore.parse`, in Python: {ayah: (from, to, [(position, start, end)])}."""
    files = doc.get("audio_files") or []
    if not files:
        return {}
    verses = {}
    for entry in files[0].get("verse_timings") or []:
        key = entry.get("verse_key")
        frm, to = millis(entry.get("timestamp_from")), millis(entry.get("timestamp_to"))
        if not isinstance(key, str) or frm is None or to is None:
            continue
        parts = key.split(":")
        if len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit() or int(parts[0]) != surah:
            continue
        ayah = int(parts[1])
        by_position = {}
        for segment in entry.get("segments") or []:
            # Some reciters' segments come as floats ("6520.0"); the app rounds them the same way.
            if not (isinstance(segment, list) and len(segment) == 3):
                continue
            position, start, end = (millis(x) for x in segment)
            if position is None or start is None or end is None or position < 1 or end <= start:
                continue
            if position in by_position:
                old = by_position[position]
                by_position[position] = (min(old[0], start), max(old[1], end))
            else:
                by_position[position] = (start, end)
        words = [(p, by_position[p][0], by_position[p][1]) for p in sorted(by_position)]
        if words:
            verses[ayah] = (min(frm, to), max(frm, to), words)
    return verses


def varint(value, out):
    assert value >= 0, value
    while True:
        byte = value & 0x7F
        value >>= 7
        if value:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return


def zigzag(value, out):
    varint((value << 1) ^ (value >> 63), out)


def encode_reciter(tables):
    """tables: {surah: {ayah: (from, to, words)}} -> the inflated stream."""
    sections = []
    for surah in range(1, SURAHS + 1):
        out = bytearray()
        verses = tables.get(surah) or {}
        varint(len(verses), out)
        previous_ayah, previous_to = 0, 0
        for ayah in sorted(verses):
            frm, to, words = verses[ayah]
            varint(ayah - previous_ayah, out)
            zigzag(frm - previous_to, out)
            varint(to - frm, out)
            varint(len(words), out)
            previous_position, previous_end = 0, frm
            for position, start, end in words:
                varint(position - previous_position - 1, out)
                zigzag(start - previous_end, out)
                varint(end - start, out)
                previous_position, previous_end = position, end
            previous_ayah, previous_to = ayah, to
        sections.append(bytes(out))
    offsets, total = [], 0
    for section in sections:
        offsets.append(total)
        total += len(section)
    offsets.append(total)
    return bytes([1, SURAHS]) + struct.pack(f"<{SURAHS + 1}I", *offsets) + b"".join(sections)


def decode_reciter(blob):
    """The inverse, for the round-trip check."""
    assert blob[0] == 1 and blob[1] == SURAHS
    offsets = struct.unpack_from(f"<{SURAHS + 1}I", blob, 2)
    base = 2 + 4 * (SURAHS + 1)
    tables = {}

    def reader(start, end):
        p = [start]

        def read():
            result, shift = 0, 0
            while True:
                byte = blob[p[0]]
                p[0] += 1
                result |= (byte & 0x7F) << shift
                if not byte & 0x80:
                    return result
                shift += 7

        def read_zigzag():
            v = read()
            return (v >> 1) ^ -(v & 1)

        return read, read_zigzag, lambda: p[0] == end

    for surah in range(1, SURAHS + 1):
        read, read_zigzag, done = reader(base + offsets[surah - 1], base + offsets[surah])
        verses = {}
        ayah, previous_to = 0, 0
        for _ in range(read()):
            ayah += read()
            frm = previous_to + read_zigzag()
            to = frm + read()
            words, position, previous_end = [], 0, frm
            for _ in range(read()):
                position += read() + 1
                start = previous_end + read_zigzag()
                end = start + read()
                previous_end = end
                words.append((position, start, end))
            verses[ayah] = (frm, to, words)
            previous_to = to
        assert done(), surah
        if verses:
            tables[surah] = verses
    return tables


def expected_counts(quran_path):
    """Hafs word counts per ayah as QuranWords counts them (tokens carrying an Arabic letter)."""
    if not quran_path or not Path(quran_path).exists():
        return None
    letter = re.compile(r"[ء-يٮ-ۓەۮۯۺ-ۼۿٱ]")
    counts = {}
    for surah in json.loads(Path(quran_path).read_text(encoding="utf-8")):
        for ayah in surah["ayahs"]:
            text = ayah.get("textArabic") or ayah.get("textHafs") or ""
            counts[(surah["id"], ayah["id"])] = sum(1 for token in text.split() if letter.search(token))
    return counts


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--cache", default=str(ROOT / "build/qdc-cache"))
    ap.add_argument("--reciters", help="comma-separated quran.com ids (default: every qdcReciterID in QuranStructs.swift)")
    ap.add_argument("--quran", default=str(ROOT.parent / "Quran-Tajweed-Engine/sources/Quran.json"),
                    help="Hafs text, for the word-count report only")
    ap.add_argument("--out", default=str(OUT))
    ap.add_argument("--stats", action="store_true", help="report only, write nothing")
    args = ap.parse_args()

    cache = Path(args.cache)
    cache.mkdir(parents=True, exist_ok=True)
    ids = [int(x) for x in args.reciters.split(",")] if args.reciters else reciter_ids()
    counts = expected_counts(args.quran)

    blobs, index = [], []
    offset = 0
    for reciter in ids:
        tables, verses, words, exact, missing = {}, 0, 0, 0, 0
        for chapter in range(1, SURAHS + 1):
            doc = fetch(reciter, chapter, cache)
            if doc is None:
                print(f"reciter {reciter}: surah {chapter} could not be fetched", file=sys.stderr)
                missing += 1
                continue
            parsed = parse(doc, chapter)
            if not parsed:
                missing += 1
                continue
            tables[chapter] = parsed
            for ayah, (_, _, ws) in parsed.items():
                verses += 1
                words += len(ws)
                if counts and counts.get((chapter, ayah)) == len(ws) == ws[-1][0]:
                    exact += 1
        raw = encode_reciter(tables)
        assert decode_reciter(raw) == tables, f"round trip failed for reciter {reciter}"
        packed = lzma.compress(raw, format=lzma.FORMAT_XZ, preset=9 | lzma.PRESET_EXTREME)
        coverage = f"{exact}/{verses} verses count as the text does" if counts else f"{verses} verses"
        print(f"reciter {reciter:>3}: {len(tables):>3} surahs, {verses:>5} verses, {words:>6} words, "
              f"{missing:>3} surahs without, {len(raw):>7} B raw, {len(packed):>7} B xz; {coverage}")
        if not tables:
            continue
        index.append({"id": reciter, "offset": offset, "length": len(packed), "surahs": len(tables),
                      "verses": verses, "words": words})
        blobs.append(packed)
        offset += len(packed)

    header = json.dumps({"built": time.strftime("%Y-%m-%d"), "source": "api.qurancdn.com audio_files?segments=true",
                         "reciters": index}, separators=(",", ":")).encode("utf-8")
    data = MAGIC + struct.pack("<I", len(header)) + header + b"".join(blobs)
    print(f"{len(index)} reciters, {len(data):,} bytes")
    if args.stats:
        return
    Path(args.out).write_bytes(data)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
