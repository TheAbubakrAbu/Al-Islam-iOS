#!/usr/bin/env python3
"""Build Resources/Data/Hadith/HadithTopics.json.xz: the curated topic library.

    ./Scripts/build_hadith_topics.py [/path/to/Tilawa]

SOURCE: Tilawa's src/data/generated/hadithDatabase.ts (Jamil Hammoudeh, with permission): 365
narrations from Bukhari, Muslim, Abu Dawud and at-Tirmidhi, each given a title and filed under
one of 21 topics in seven lanes, so the same subject can be read as Bukhari words it next to
Muslim next to Tirmidhi. The text itself is NOT copied: every entry is reduced to its citation and
resolved at runtime from this app's own hadith packs, which come from the same meeAtif dataset.
A citation that is not on this app's shelf fails the build rather than shipping a dead row.

Pack: {"version": 1, "lanes": [{"id", "label", "subtitle"}], "topics": [{"id", "label",
"subtitle", "lane"}], "entries": [{"id", "title", "topic", "lane", "slug", "citation", "tags",
"rank"}]} in the source's own order.
"""
from __future__ import annotations

import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from tilawa_ts import eval_consts, load_softener, xz_compress  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
ENGINE = ROOT.parent / "Hadith-JSON-Engine" / "db" / "by_book" / "the_9_books"
OUT = ROOT / "Resources" / "Data" / "Hadith" / "HadithTopics.json.xz"
TILAWA = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Tilawa"

_citations: dict[str, set[str]] = {}


def engine_citations(slug: str) -> set[str]:
    if slug not in _citations:
        path = ENGINE / f"{slug}.json"
        if not path.exists():
            raise SystemExit(f"engine book missing: {path}")
        book = json.loads(path.read_text(encoding="utf-8"))
        _citations[slug] = {str(h.get("citation") or "") for h in book["hadiths"]}
    return _citations[slug]


def main() -> None:
    soften = load_softener()
    source = TILAWA / "src" / "data" / "generated" / "hadithDatabase.ts"
    if not source.exists():
        raise SystemExit(f"source not found: {source}")
    data = eval_consts(source, ["HADITH_TOPICS", "HADITH_LANES", "HADITH_DATABASE"])

    lanes = [{"id": l["id"], "label": soften(l["label"]), "subtitle": soften(l["subtitle"])}
             for l in data["HADITH_LANES"]]
    topics = [{"id": t["id"], "label": soften(t["label"]), "subtitle": soften(t["subtitle"]),
               "lane": t["laneId"]} for t in data["HADITH_TOPICS"]]
    lane_ids = {l["id"] for l in lanes}
    topic_ids = {t["id"] for t in topics}

    entries = []
    problems = []
    seen = set()
    for row in data["HADITH_DATABASE"]:
        ref = row.get("reference", "")
        m = re.match(r"^https://sunnah\.com/([a-z]+):(\d+[a-z]?)$", ref)
        if not m:
            m = re.match(r"^([a-z]+)-(\d+[a-z]?)$", row["id"])
        if not m:
            problems.append(f"{row['id']}: no citation in {ref!r}")
            continue
        slug, citation = m.group(1), m.group(2)
        if citation not in engine_citations(slug):
            problems.append(f"{row['id']}: {slug} {citation} is not on the shelf")
            continue
        if row["topicId"] not in topic_ids:
            problems.append(f"{row['id']}: unknown topic {row['topicId']}")
        if row["laneId"] not in lane_ids:
            problems.append(f"{row['id']}: unknown lane {row['laneId']}")
        key = (slug, citation, row["topicId"])
        if key in seen:
            problems.append(f"{row['id']}: duplicate of {slug} {citation} under {row['topicId']}")
            continue
        seen.add(key)
        entries.append({
            "id": row["id"],
            "title": soften(row["title"]),
            "topic": row["topicId"],
            "lane": row["laneId"],
            "slug": slug,
            "citation": citation,
            "tags": [t for t in row.get("tags", []) if t],
            "rank": int(row.get("rank", 0)),
        })

    for text in [e["title"] for e in entries] + [t["subtitle"] for t in topics] + [l["subtitle"] for l in lanes]:
        if "\u2014" in text or " - " in text:
            problems.append(f"dash left in: {text[:60]}")

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:40]:
            print("  " + line, file=sys.stderr)
        raise SystemExit(1)

    pack = {"version": 1, "lanes": lanes, "topics": topics, "entries": entries}
    body = json.dumps(pack, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    blob = xz_compress(body)
    OUT.write_bytes(blob)
    by_slug = {}
    for e in entries:
        by_slug[e["slug"]] = by_slug.get(e["slug"], 0) + 1
    print(f"{len(entries)} entries, {len(topics)} topics, {len(lanes)} lanes: {by_slug}")
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} xz")


if __name__ == "__main__":
    main()
