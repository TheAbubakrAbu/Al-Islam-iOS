#!/usr/bin/env python3
"""Build Resources/Data/Quran/QiraatVariants.json.xz: the annotated variant readings of the
1,409 ayahs that carry them, from the Quran.com qiraat matrix (Quran Foundation), kept as one
compacted source at Resources/JSONs-Deprecated/Qiraat/quran-com-qiraat.json.xz.

Each ayah lists its JUNCTURES (the word or words read differently), and each juncture the
READINGS: the reading's text, a transliteration, an English rendering, an explanation where
the source gives one, and WHO reads it - the imams (readers) and, where the two transmitters
of one imam differ, the transmitters. Transmitter ids are mapped onto this app's riwayah tags
so the reader's current riwayah can be picked out.

Junctures are located inside THIS APP's Hafs tokens at build time (the source's `position` is
not a word index): the juncture's words are matched by rasm skeleton against the ayah's
tokens, exactly the way the audit that vetted the source did, and stored as 0-based inclusive
token ranges (-1 when a segment could not be placed, which the UI tolerates).

The source is a scrape of Quran.com's own page data, not a published API: the factual layer
(which imam reads what) is classical scholarship, but the English renderings and explanations
are Quran.com's editorial text - clear their use with the Quran Foundation before a release.

    python3 Scripts/build_qiraat_variants.py
"""

from __future__ import annotations

import difflib
import json
import lzma
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "Resources" / "JSONs-Deprecated" / "Qiraat" / "quran-com-qiraat.json.xz"
OUT = ROOT / "Resources" / "Data" / "Quran" / "QiraatVariants.json.xz"
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"

# Quran.com transmitter id -> this app's riwayah tag (Settings.Riwayah). Hafs is the empty tag.
TRANSMITTER_TAGS = {
    1: "", 2: "Shubah an Asim",
    3: "Qalun an Nafi", 4: "Warsh an Nafi",
    5: "al-Bazzi an Ibn Kathir", 6: "Qunbul an Ibn Kathir",
    7: "ad-Duri an Abi Amr", 8: "as-Susi an Abi Amr",
    9: "Hisham an Ibn Amir", 10: "Ibn Dhakwan an Ibn Amir",
    11: "Khalaf an Hamzah", 12: "Khallad an Hamzah",
    13: "ad-Duri an al-Kisai", 14: "Abu al-Harith an al-Kisai",
    15: "Ibn Wardan an Abi Jafar", 16: "Ibn Jammaz an Abi Jafar",
    17: "Ruways an Yaqub", 18: "Rawh an Yaqub",
    19: "Ishaq an Khalaf al-Ashir", 20: "Idris an Khalaf al-Ashir",
}

_MARKS = re.compile(r"[ً-ٰۖ-ۭؐ-ؚ࣓-ࣿ]")


def xz_compress(body: bytes) -> bytes:
    dict_size = 1 << 16
    while dict_size < len(body) and dict_size < (1 << 26):
        dict_size <<= 1
    filters = [{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME, "dict_size": dict_size}]
    return lzma.compress(body, format=lzma.FORMAT_XZ, check=lzma.CHECK_CRC32, filters=filters)


def skeleton(word: str) -> str:
    """The rasm skeleton the audit compared on: marks off, hamza seats folded, the plural waw's
    silent alef dropped, tatweel gone."""
    w = word.replace("ٰ", "ا").replace("ـ", "")
    w = _MARKS.sub("", w)
    w = re.sub(r"وا$", "و", w)
    w = re.sub("[ٱأإآٲٳ]", "ا", w).replace("ة", "ه").replace("ى", "ي").replace("ئ", "ي").replace("ؤ", "و").replace("ء", "")
    w = w.replace("ک", "ك").replace("ی", "ي").replace("ھ", "ه").replace("ں", "ن")
    return re.sub(r"[^ء-ي]", "", w)


def locate(words: list[str], tokens: list[str]) -> tuple[int, int] | None:
    """The token range carrying `words` (skeletons), or None."""
    target = [skeleton(w) for w in words if skeleton(w)]
    if not target:
        return None
    haystack = [skeleton(t) for t in tokens]
    n = len(target)
    for i in range(len(haystack) - n + 1):
        if haystack[i:i + n] == target:
            return (i, i + n - 1)
    if n == 1:
        for i, tok in enumerate(haystack):
            if tok and (tok.startswith(target[0]) or tok.endswith(target[0]) or target[0] in tok):
                return (i, i)
    joined = " ".join(target)
    best = (0.0, None)
    for i in range(len(haystack)):
        for length in range(1, min(n + 1, len(haystack) - i) + 1):
            ratio = difflib.SequenceMatcher(a=joined, b=" ".join(haystack[i:i + length])).ratio()
            if ratio > best[0]:
                best = (ratio, (i, i + length - 1))
    return best[1] if best[0] >= 0.72 else None


def main() -> None:
    source = json.loads(lzma.decompress(SRC.read_bytes()).decode("utf-8"))
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    tokens_by_key = {f"{s['id']}:{a['id']}": a["textArabic"].split() for s in quran for a in s["ayahs"]}

    readers = {}
    for rid, reader in source["readers"].items():
        readers[rid] = {"n": reader["name"], "a": reader["abbreviation"], "c": reader["city"], "p": reader["position"]}
    transmitters = {}
    for tid, transmitter in source["transmitters"].items():
        if int(tid) not in TRANSMITTER_TAGS:
            raise SystemExit(f"transmitter {tid} has no riwayah tag")
        transmitters[tid] = {"n": transmitter["name"], "r": transmitter["readerId"], "tag": TRANSMITTER_TAGS[int(tid)]}

    ayahs = {}
    junctures = readings = placed = unplaced = 0
    for key, record in source["ayahs"].items():
        if key not in tokens_by_key:
            raise SystemExit(f"{key} is not an ayah of this app")
        packed = []
        for juncture in record["junctures"]:
            segments = []
            for segment in juncture.get("segments") or []:
                seg_key = segment.get("verseKey") or key
                seg_tokens = tokens_by_key.get(seg_key, [])
                span = locate((segment.get("text") or "").split(), seg_tokens)
                if span is None:
                    unplaced += 1
                    segments.append([seg_key, -1, -1])
                else:
                    placed += 1
                    segments.append([seg_key, span[0], span[1]])
            if not segments:
                span = locate((juncture.get("text") or "").split(), tokens_by_key[key])
                segments.append([key, span[0], span[1]] if span else [key, -1, -1])
                placed += 1 if span else 0
                unplaced += 0 if span else 1
            rows = []
            for reading in juncture["readings"]:
                cells = reading.get("matrix") or {}
                row = {
                    "t": reading.get("textUthmani") or reading.get("text") or "",
                    "tr": reading.get("transliteration") or "",
                    "en": reading.get("translation") or "",
                    "ex": ((reading.get("explanation") or {}).get("text") or "").strip(),
                    "rd": sorted(int(r) for r in (cells.get("readers") or [])),
                    "tm": sorted(int(t) for t in (cells.get("transmitters") or [])),
                }
                if reading.get("grammaticalForm"):
                    row["gf"] = reading["grammaticalForm"]
                if reading.get("rootLetters"):
                    row["rt"] = reading["rootLetters"]
                rows.append(row)
                readings += 1
            packed.append({
                "t": juncture.get("text") or "",
                "c": juncture.get("category") or "",
                "seg": segments,
                "readings": rows,
                "note": (juncture.get("commentary") or "").strip(),
            })
            junctures += 1
        if packed:
            ayahs[key] = packed

    body = json.dumps({"v": 1, "readers": readers, "transmitters": transmitters, "ayahs": ayahs},
                      ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    blob = xz_compress(body)
    OUT.write_bytes(blob)
    print(f"{len(ayahs)} ayahs, {junctures} junctures ({placed} segments placed, {unplaced} unplaced), {readings} readings")
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} xz")


if __name__ == "__main__":
    main()
