#!/usr/bin/env python3
"""Build the two theme packs behind "Browse by Theme" and the surah outlines:

    Resources/Data/Quran/ThematicTopics.json.deflate
    Resources/Data/Quran/SurahSections.json.deflate

SOURCES (bundled in the sibling Tilawa app, ported with permission)
-------------------------------------------------------------------
* thematic-topics.json - the QSAC corpus (Quran Semantic Annotation Corpus,
  CC BY 4.0): 323 topics, each with a description, a domain/category, and the
  ayahs it annotates.
* surah-sections.json  - Quranpedia's per-surah passage outlines (an Arabic
  title + English translation per passage, plus a whole-surah overview row).

OUTPUT FORMATS (raw deflate, like the other Data/Quran payloads)
----------------------------------------------------------------
ThematicTopics: {"topics": [ {id, name, description, domain, category,
                              ayahs: ["2:22", ...]} ... ]}   - topic order kept.
SurahSections:  {"1": {"overview": "<english overview or ''>",
                       "sections": [[start, end, "<english>", "<arabic>"], ...]},
                 ...}                                        - sections in order.

RUN:  python3 Scripts/build_quran_themes.py [tilawa-root]
Fails, writing nothing, on any ayah reference outside this app's Quran.
"""

from __future__ import annotations

import json
import pathlib
import sys
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
OUT_TOPICS = ROOT / "Resources" / "Data" / "Quran" / "ThematicTopics.json.deflate"
OUT_SECTIONS = ROOT / "Resources" / "Data" / "Quran" / "SurahSections.json.deflate"
DEFAULT_TILAWA = ROOT.parent / "Tilawa"


def ayah_counts() -> dict[int, int]:
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    return {s["id"]: len(s["ayahs"]) for s in quran}


def deflate(obj) -> tuple[bytes, bytes]:
    body = json.dumps(obj, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    compressor = zlib.compressobj(9, zlib.DEFLATED, -15)
    return body, compressor.compress(body) + compressor.flush()


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
                # The whole-surah summary reads as a lead paragraph, not a range row.
                overview = english or overview
                continue
            if not english and not arabic:
                continue
            body.append([start, end, english, arabic])
            section_rows += 1
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
          f"({len(raw_t):,} raw -> {len(blob_t):,} deflated)")
    print(f"sections: {len(sections_out)} surahs, {section_rows} passage rows "
          f"({len(raw_s):,} raw -> {len(blob_s):,} deflated)")


if __name__ == "__main__":
    main()
