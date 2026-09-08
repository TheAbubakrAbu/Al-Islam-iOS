#!/usr/bin/env python3
"""Build Resources/Data/Islam/DailyReminders.json.xz: the Reminder of the Day corpus.

    ./Scripts/build_daily_reminders.py [/path/to/Tilawa]

SOURCE: Tilawa's src/data/dailyReminders.ts (Jamil Hammoudeh, ported with permission): 180
date-stable cards in six types (ayah, hadith, sunnah, dua, dhikr, name), interleaved on purpose so
consecutive days differ in kind. Every hadith citation there is sahih or hasan.

WHAT THIS APP KEEPS: for an `ayah` card only the reference: the app renders the ayah from its own
Hafs text and Saheeh International translation, never a copied string. Hadith and dua Arabic and
English are carried exactly as written (never re-punctuated). Tilawa-authored lines (the sunnah,
dhikr and name cards, the `short` headline of non-scripture cards, every `source`) have their
spaced hyphens and em dashes re-punctuated, the app's house rule. Deep links are re-targeted to
this app's own screens.

Pack: {"version": 1, "entries": [{"id", "type", "ar", "tr"?, "short", "en", "source", "target"?,
"s"?, "a"?, "repeat"?, "hadith"?}]} in the source's own order. `target` is a QuranOpenTarget
encoding ("ayah:2:152") or one of "hadith", "duas", "adhkar", "names:<n>"; `hadith` is
"<slug>:<citation>" when the card's narration is on this app's shelf.
"""
from __future__ import annotations

import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from tilawa_ts import eval_consts, load_softener, xz_compress  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
ENGINE = ROOT.parent / "Hadith-JSON-Engine" / "db" / "by_book" / "the_9_books"
OUT = ROOT / "Resources" / "Data" / "Islam" / "DailyReminders.json.xz"
TILAWA = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Tilawa"

SCRIPTURE = {"ayah", "hadith", "dua"}

_citations: dict[str, set[str]] = {}


BOOK_SLUGS = {"bukhari": "bukhari", "muslim": "muslim", "tirmidhi": "tirmidhi", "abu dawud": "abudawud",
              "nasai": "nasai", "an-nasai": "nasai", "ibn majah": "ibnmajah", "malik": "malik", "ahmad": "ahmed",
              "darimi": "darimi"}


def shelf_link(source: str) -> str | None:
    """"Bukhari 9, Muslim 36" -> "<slug>:<citation>" for the first citation the shelf carries. A bare
    Muslim number resolves to its first lettered narration ("2699" -> "2699a"): the engine numbers
    Muslim's repeated chains that way, and the first is the one the citation names."""
    for part in source.split(","):
        m = re.match(r"^\s*([A-Za-z' -]+?)\s+(\d+[a-z]?)\s*(?:-.*)?$", part)
        if not m:
            continue
        slug = BOOK_SLUGS.get(m.group(1).strip().lower())
        if not slug:
            continue
        citations = engine_citations(slug)
        for candidate in (m.group(2), m.group(2) + "a"):
            if candidate in citations:
                return f"{slug}:{candidate}"
    return None


def engine_citations(slug: str) -> set[str]:
    if slug not in _citations:
        path = ENGINE / f"{slug}.json"
        if not path.exists():
            _citations[slug] = set()
        else:
            book = json.loads(path.read_text(encoding="utf-8"))
            _citations[slug] = {str(h.get("citation") or "") for h in book["hadiths"]}
    return _citations[slug]


def source_line(text: str) -> str:
    # "Tirmidhi 1956 - Sahih (al-Albani)" is a citation and its grading, not two clauses: the app
    # joins those with a middle dot everywhere else.
    return re.sub(r"\s+[-\u2013\u2014]\s+", " \u00b7 ", text).strip()


def main() -> None:
    soften = load_softener()
    source = TILAWA / "src" / "data" / "dailyReminders.ts"
    if not source.exists():
        raise SystemExit(f"source not found: {source}")
    reminders = eval_consts(source, ["DAILY_REMINDERS"])["DAILY_REMINDERS"]

    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    counts = {int(s["id"]): len(s["ayahs"]) for s in quran}

    entries = []
    problems = []
    kinds: dict[str, int] = {}
    hadith_links = 0
    unlinked: list[str] = []
    for row in reminders:
        kind = row["type"]
        kinds[kind] = kinds.get(kind, 0) + 1
        entry = {"id": row["id"], "type": kind}
        link = row.get("deepLink", "")

        if kind == "ayah":
            s, a = int(row["surahId"]), int(row["ayahNumber"])
            if s not in counts or not 1 <= a <= counts[s]:
                problems.append(f"{row['id']}: no ayah {s}:{a}")
                continue
            entry.update({"s": s, "a": a, "target": f"ayah:{s}:{a}"})
            entry["short"] = row["short"]
            entry["en"] = row["english"]
            entry["ar"] = ""
            entry["source"] = source_line(row["source"])
        else:
            entry["ar"] = row["arabic"]
            entry["en"] = row["english"]
            entry["short"] = row["short"]
            entry["source"] = source_line(row["source"])
            if row.get("transliteration"):
                entry["tr"] = row["transliteration"]
            if row.get("repeatCount"):
                entry["repeat"] = int(row["repeatCount"])
            if kind not in SCRIPTURE:
                entry["en"] = soften(entry["en"])
                entry["short"] = soften(entry["short"])

            m = re.match(r"^/islam/hadith-detail/([a-z]+)-(\d+[a-z]?)$", link)
            if m:
                slug, citation = m.group(1), m.group(2)
                if citation in engine_citations(slug):
                    entry["hadith"] = f"{slug}:{citation}"
                    hadith_links += 1
                else:
                    problems.append(f"{row['id']}: {slug} {citation} is not on the shelf")
            elif link.startswith("/islam/hadith"):
                entry["target"] = "hadith"
                # Tilawa's generic hadith door; the source line still names the narration, and when
                # the shelf carries it the card opens that hadith instead of the door.
                if kind == "hadith" and (linked := shelf_link(entry.get("source", ""))):
                    entry["hadith"] = linked
                    hadith_links += 1
                elif kind == "hadith":
                    unlinked.append(f"{row['id']}: {entry.get('source', '')}")
            elif link.startswith("/islam/duas"):
                entry["target"] = "duas"
            elif link.startswith("/islam/athkar"):
                entry["target"] = "adhkar"
            elif (m := re.match(r"^/islam/names/(\d+)$", link)):
                entry["target"] = f"names:{m.group(1)}"
            elif (m := re.match(r"^/read/(\d+)\?ayah=(\d+)$", link)):
                entry["target"] = f"ayah:{m.group(1)}:{m.group(2)}"
                entry["s"], entry["a"] = int(m.group(1)), int(m.group(2))
        for key in ("short", "en", "source", "tr"):
            if key in entry and ("\u2014" in entry[key] or " - " in entry[key]) and kind not in SCRIPTURE:
                problems.append(f"{row['id']}: dash left in {key}: {entry[key][:60]}")
        entries.append(entry)

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:40]:
            print("  " + line, file=sys.stderr)
        raise SystemExit(1)

    body = json.dumps({"version": 1, "entries": entries}, ensure_ascii=False,
                      separators=(",", ":"), sort_keys=True).encode("utf-8")
    blob = xz_compress(body)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(blob)
    print(f"{len(entries)} entries {dict(sorted(kinds.items()))}, {hadith_links} shelf links")
    for line in unlinked:
        print(f"  hadith card without a shelf link: {line}")
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} xz")


if __name__ == "__main__":
    main()
