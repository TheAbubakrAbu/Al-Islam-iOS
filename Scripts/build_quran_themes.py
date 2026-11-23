#!/usr/bin/env python3
"""Build the two theme packs behind "Browse by Theme" and the surah outlines:

    Resources/Data/Quran/ThematicTopics.json.xz
    Resources/Data/Quran/SurahSections.json.xz

SOURCES (bundled in the sibling Tilawa app, ported with permission)
-------------------------------------------------------------------
* thematic-topics.json - the QSAC corpus (Quran Semantic Annotation Corpus,
  CC BY 4.0): 323 topics, each with a description, a domain/category, and the
  ayahs it annotates.
* surah-sections.json  - Quranpedia's per-surah passage outlines (an Arabic
  title + English translation per passage, plus a whole-surah overview row).

OUTPUT FORMATS (xz, like the other Data/Quran payloads)
----------------------------------------------------------------
ThematicTopics: {"topics": [ {id, name, description, domain, category,
                              ayahs: ["2:22", ...]} ... ]}   - topic order kept.
SurahSections:  {"1": {"overview": "<english overview or ''>",
                       "sections": [[start, end, "<english>", "<arabic>"], ...]},
                 ...}                                        - sections in order.
                 A fifth element, 1, marks the whole-surah row of a surah that has no other
                 passage (1, 42, 44): the wash and the passage list use it, the outline skips it.
                 A fifth element, 2, marks a passage this app added where the outline left an
                 ayah out (GAP_FILLS); the app gives it an id of its own, so the source rows'
                 ids (their positions) never move.
                 A fifth element, 3, marks a source passage this app widened to take such an
                 ayah in, followed by the range the source gave it:
                 [start, end, "<english>", "<arabic>", 3, source start, source end].

Every ayah sits in a passage: "Highlight Every Passage" washes by passage, and an ayah
in none stayed bare (76:4, 2026-11-21). verify_quran_themes.py holds that.

The wash and the passage list read rows 2 and 3 as they stand. The outline in About this
Surah is shown as Quranpedia's, so it prints the source's own: no row 2, and a row 3 at
the range the source gave it.

RUN:  python3 Scripts/build_quran_themes.py [tilawa-root]
Fails, writing nothing, on any ayah reference outside this app's Quran.
"""

from __future__ import annotations

import json
import pathlib
import sys
import lzma


def xz_compress(body: bytes) -> bytes:
    """xz stream, preset 9e, dictionary no larger than the payload needs (the app decodes it with
    Apple's Compression framework, COMPRESSION_LZMA, which reads the xz container directly)."""
    dict_size = 1 << 16
    while dict_size < len(body) and dict_size < (1 << 26):
        dict_size <<= 1
    filters = [{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME, "dict_size": dict_size}]
    return lzma.compress(body, format=lzma.FORMAT_XZ, check=lzma.CHECK_CRC32, filters=filters)

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT.parent / "Quran-Tajweed-Engine" / "sources" / "Quran.json"
OUT_TOPICS = ROOT / "Resources" / "Data" / "Quran" / "ThematicTopics.json.xz"
OUT_SECTIONS = ROOT / "Resources" / "Data" / "Quran" / "SurahSections.json.xz"
DEFAULT_TILAWA = ROOT.parent / "Tilawa"

# Quranpedia's placeholder where a surah has no written overview, and the title the whole-surah
# passage wears in its place (Tilawa's "reader.sections.kindOverview" label). The classifier reads
# "overview" as the signs of Allah, so the wash matches Tilawa's.
GENERIC_OVERVIEW = "surah overview"
WHOLE_SURAH_TITLE = "Surah Overview"

# The fifth element of a passage this app added, and of a source passage it widened (see the
# format above).
ADDED_ROW = 2
WIDENED_ROW = 3

# The 20 ayahs (13 surahs) Quranpedia's outline puts in no passage, and where each goes.
# "prev" / "next": the ayah joins that neighbouring passage, whose range grows to take it in.
# The side is the one QUL's passage themes (Resources/Data/Quran/AyahThemes.json.xz) group it
# with: 12:58 (the brothers arrive) opens the passage after it, 5:64 (the Jews' slander)
# closes the one before.
#
# A tuple is a passage of its own, where neither neighbour is about the ayah: 17:1 would have
# read "Honoring our Master Moses", 73:20 "Threatening the disbelievers", and 76:4 (the chains
# and the blaze prepared for the disbelievers) "The reward of the righteous", in the believers'
# green. Their titles are this app's, from the ayahs' own words, and worded so the classifier
# (ThemeColorGuide) reads them as the Prophet (green), as worship (brown) and as Hellfire (red;
# 76:4 scores level with "the disbelievers" and takes red on the classifier's tie order).
# The build fails if an entry stops being a gap (a new source would need a look).
GAP_FILLS: dict[tuple[int, int, int], str | tuple[str, str]] = {
    (5, 11, 11): "prev",
    (5, 64, 64): "prev",
    (5, 89, 89): "prev",
    (6, 21, 21): "next",
    (12, 58, 58): "next",
    (16, 65, 65): "prev",
    (17, 1, 1): ("The Night Journey of the Prophet, peace be upon him", "الإسراء بالنبي صلى الله عليه وسلم"),
    (21, 107, 112): "prev",
    (24, 61, 61): "prev",
    (39, 21, 21): "prev",
    (49, 18, 18): "prev",
    (71, 28, 28): "prev",
    (73, 20, 20): ("Lightening the night prayer", "التخفيف في صلاة الليل"),
    (76, 4, 4): ("The torment prepared for the disbelievers", "ما أُعِدَّ للكافرين من السلاسل والأغلال والسعير"),
    (84, 6, 6): "next",
}


def fill_gaps(surah: int, body: list[list], problems: list[str]) -> list[list]:
    """`body` with this surah's GAP_FILLS applied, in reading order."""
    for (s, first, last), fill in GAP_FILLS.items():
        if s != surah:
            continue
        if any(row[0] <= ayah <= row[1] for row in body for ayah in range(first, last + 1)):
            problems.append(f"surah {surah}: {first}-{last} is in a passage now, drop its GAP_FILLS entry")
            continue
        if isinstance(fill, tuple):
            english, arabic = fill
            body.append([first, last, english, arabic, ADDED_ROW])
            continue
        if fill == "prev":
            hits = [row for row in body if row[1] == first - 1]
        else:
            hits = [row for row in body if row[0] == last + 1]
        if len(hits) != 1:
            problems.append(f"surah {surah}: {first}-{last} has {len(hits)} '{fill}' passages to join")
            continue
        row = hits[0]
        if len(row) == 4:
            # The range the source gave it rides along, for the outline (see the format above).
            row += [WIDENED_ROW, row[0], row[1]]
        elif row[4] != WIDENED_ROW:
            problems.append(f"surah {surah}: {first}-{last} would widen a row that is not the source's")
            continue
        if fill == "prev":
            row[1] = last
        else:
            row[0] = first
    # Stable: rows that share a start (surah 18's two "Two Gardens") keep the source's order.
    body.sort(key=lambda row: row[0])
    return body


def ayah_counts() -> dict[int, int]:
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    return {s["id"]: len(s["ayahs"]) for s in quran}


def deflate(obj) -> tuple[bytes, bytes]:
    body = json.dumps(obj, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    return body, xz_compress(body)


def main() -> None:
    tilawa = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_TILAWA
    topics_path = tilawa / "assets" / "quran" / "thematic-topics.json"
    sections_path = tilawa / "assets" / "quran" / "surah-sections.json"
    for p in (topics_path, sections_path):
        if not p.exists():
            raise SystemExit(f"source not found: {p}")

    counts = ayah_counts()
    problems: list[str] = []

    def valid_key(key: str) -> bool:
        parts = key.split(":")
        if len(parts) != 2:
            return False
        try:
            surah, ayah = int(parts[0]), int(parts[1])
        except ValueError:
            return False
        return surah in counts and 1 <= ayah <= counts[surah]

    # --- Topics ---------------------------------------------------------------
    src = json.loads(topics_path.read_text(encoding="utf-8"))
    topics_out = []
    assignments = 0
    for topic in src.get("topics", []):
        ayahs = [a for a in topic.get("ayahIds", []) if valid_key(a)]
        bad = len(topic.get("ayahIds", [])) - len(ayahs)
        if bad:
            problems.append(f"topic {topic.get('id')}: {bad} invalid ayah refs")
        if not ayahs:
            continue
        assignments += len(ayahs)
        topics_out.append({
            "id": topic["id"],
            "name": topic["name"],
            "description": topic.get("description", ""),
            "domain": topic.get("domain", ""),
            "category": topic.get("category", ""),
            "ayahs": ayahs,
        })

    # --- Sections -------------------------------------------------------------
    src = json.loads(sections_path.read_text(encoding="utf-8"))
    sections_out: dict[str, dict] = {}
    section_rows = 0
    for surah_key, rows in src.get("surahs", {}).items():
        try:
            surah = int(surah_key)
        except ValueError:
            problems.append(f"bad surah key {surah_key}")
            continue
        if surah not in counts:
            problems.append(f"unknown surah {surah}")
            continue
        overview = ""
        body: list[list] = []
        whole: list | None = None
        # Sorted by position, not the source's `order`: quranpedia occasionally numbers a
        # thematically-grouped passage out of reading order (surah 7), and an outline is read
        # top to bottom against the text.
        for row in sorted(rows, key=lambda r: (r.get("ayahStart", 0), r.get("order", 0))):
            start, end = row.get("ayahStart"), row.get("ayahEnd")
            if not (isinstance(start, int) and isinstance(end, int)
                    and 1 <= start <= end <= counts[surah]):
                problems.append(f"surah {surah}: bad range {start}-{end}")
                continue
            english = (row.get("titleEn") or "").strip()
            arabic = (row.get("title") or "").strip()
            if row.get("kind") == "overview":
                # The whole-surah summary reads as a lead paragraph, not a range row. The source's
                # placeholder ("Surah overview", in both languages) says nothing and is dropped.
                if english.lower() == GENERIC_OVERVIEW:
                    english = ""
                if arabic.lower() == GENERIC_OVERVIEW or arabic.isascii():
                    arabic = ""
                overview = english or overview
                whole = [start, end, english or WHOLE_SURAH_TITLE, arabic, 1]
                continue
            if not english and not arabic:
                continue
            body.append([start, end, english, arabic])
            section_rows += 1
        if not body and whole is not None:
            # A surah whose ONLY row is its overview (al-Fatihah, ash-Shura, ad-Dukhan) is one
            # passage in Tilawa, and its thematic highlighting washes it as one. Dropping the row
            # left these three surahs with no passage at all, so "Highlight Every Passage" skipped
            # them. The trailing 1 marks the row as the whole-surah one: the outline already leads
            # with the overview, so it does not print the row again.
            body.append(whole)
            section_rows += 1
        before = len(body)
        body = fill_gaps(surah, body, problems)
        section_rows += len(body) - before
        if overview or body:
            sections_out[str(surah)] = {"overview": overview, "sections": body}

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:20]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)

    raw_t, blob_t = deflate({"topics": topics_out})
    OUT_TOPICS.write_bytes(blob_t)
    raw_s, blob_s = deflate(sections_out)
    OUT_SECTIONS.write_bytes(blob_s)

    print(f"topics: {len(topics_out)} topics, {assignments:,} ayah assignments "
          f"({len(raw_t):,} raw -> {len(blob_t):,} xz)")
    print(f"sections: {len(sections_out)} surahs, {section_rows} passage rows "
          f"({len(raw_s):,} raw -> {len(blob_s):,} xz)")


if __name__ == "__main__":
    main()
