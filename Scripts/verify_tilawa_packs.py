#!/usr/bin/env python3
"""Gate for every pack the Tilawa port ships (Tilawa Guide, Phase 9 step 1).

Checks the packs ON DISK, the way verify_tajweed_lessons.py checks its own:

  * DailyReminders.json.xz   every hadith card resolves on the app's shelf (the 9-books engine JSON,
                             slug + citation) and every verse card's surah:ayah exists; version 2:
                             a card's words are word ranges into its bundled narration (.hpk) or
                             its Fortress entry, inside those texts, never a copy beside a reference
  * HadithTopics.json.xz     every citation resolves; gradings are reported where the engine carries one
  * NamesDetails.json.xz     every verse exists and its tinted tokens sit inside the ayah; the
                             unmatched-verse count is printed
  * WordOfDay.json.xz        every occurrence's token indices sit inside the ayah, and the count on the
                             card equals the sum of its occurrences
  * QiraatVariantAudio.json.xz  every source URL is https and every row has six numbers; with --head,
                             one clip per source is HEAD-requested
  * Miracles.json.xz         every image path is a plain relative path and the image base is https
  * HisnDuas.json.xz         every audio URL is https
  * HadeethEnc.henc          the on-demand container decodes block by block, the header's light
                             rows match the blocks, every topic is in the tree, 2,328 narrations
  * HadithVocabulary.txt.xz  the shipped typo vocabulary was exported for the packs on disk
  * registration             every pack name appears in project.pbxproj (an unregistered pack is
                             silently absent from the bundle: "0 narrations")
  * the dash rule            no em dash, and no spaced hyphen standing in for one, in the
                             Tilawa-authored fields (Quran text, hadith text and the encyclopedia's
                             narrations are excluded by design) or in the port's Swift string literals

Run:  python3 Scripts/verify_tilawa_packs.py [--head]

Exit status 1 on any hard error; the dash census and the unmatched counts are reported, not fatal,
because they are the content's, not the pipeline's.

Upstream sync (the whole port, in order): `git -C ~/Downloads/Islam/Tilawa pull`, then
build_daily_reminders.py, build_word_of_day.py, build_hadith_topics.py, build_names_details.py,
build_qiraat_variant_audio.py, build_tajweed_lessons.py, build_miracles_pack.py, build_hisn_duas.py,
build_hadeethenc_pack.py (needs node for brotli), then this script and verify_tajweed_lessons.py,
then `git diff --stat Resources/Data`, a Debug build, and a screenshot of every surface (the recipes
are in docs/Tilawa Guide.md, section 17). The place index is exported from the app itself
(`-exportQiraatPlaces`), not built here.
"""

from __future__ import annotations

import json
import lzma
import pathlib
import re
import sys
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from islam_packs import Hadith  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROOT / "Resources" / "Data"
PBXPROJ = ROOT / "Al-Islam.xcodeproj" / "project.pbxproj"
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
ENGINE = ROOT.parent / "Hadith-JSON-Engine" / "db" / "by_book" / "the_9_books"

PACKS = {
    "DailyReminders": DATA / "Islam" / "DailyReminders.json.xz",
    "HadithTopics": DATA / "Hadith" / "HadithTopics.json.xz",
    "NamesDetails": DATA / "Islam" / "NamesDetails.json.xz",
    "WordOfDay": DATA / "Quran" / "WordOfDay.json.xz",
    "QiraatVariantAudio": DATA / "Quran" / "QiraatVariantAudio.json.xz",
    "QiraatPlaces": DATA / "Quran" / "QiraatPlaces.json.xz",
    "TajweedLessons": DATA / "Quran" / "TajweedLessons.json.xz",
    "Miracles": DATA / "Islam" / "Miracles.json.xz",
    "HisnDuas": DATA / "Islam" / "HisnDuas.json.xz",
    "HadeethEnc": DATA / "Hadith" / "HadeethEnc.henc",
}

PORT_SWIFT = [
    "iPhone/Islam/DailyReminders.swift", "iPhone/Quran/WordOfDay.swift", "iPhone/Quran/SunnahReminders.swift",
    "iPhone/Quran/ReminderKinds.swift", "iPhone/Settings/ActivityLog.swift", "iPhone/Settings/ProfileDashboard.swift",
    "iPhone/Quran/QiraatExplorer.swift", "iPhone/Quran/QiraatVariantAudio.swift", "iPhone/Quran/ThemeHighlights.swift",
    "iPhone/Quran/ShareBackdrop.swift", "iPhone/Quran/QuranRankedSearch.swift", "iPhone/Hadith/HadithRankedSearch.swift",
    "iPhone/Hadith/HadeethEncView.swift", "iPhone/Hadith/HadithTopics.swift", "iPhone/Islam/MiraclesView.swift",
    "iPhone/Islam/JournalView.swift", "iPhone/Islam/NamesDepth.swift", "iPhone/Islam/TajweedLessons.swift",
    "iPhone/Settings/DailyRollover.swift", "iPhone/Helpers/RemovalConfirmation.swift", "Widget/Quran/DailyWidgets.swift",
    "iPhone/Islam/DuaView.swift",
]

# SunnahReminders.swift's presets, in file order: Mulk (Tirmidhi 2891), Ikhlas x3 (Bukhari 5009, Muslim 808),
# morning and evening adhkar (Abu Dawud 5082, Tirmidhi 3575), Kahf on Friday (Bukhari 891, Muslim 879),
# the last two of al-Baqarah (Bukhari 4569, Muslim 256). The engine numbers Muslim's chains with letters.
SUNNAH_PRESET_CITATIONS = [("tirmidhi", "2891"), ("bukhari", "5009"), ("muslim", "808a"), ("abudawud", "5082"),
                           ("tirmidhi", "3575"), ("bukhari", "891"), ("muslim", "879a"), ("bukhari", "4569"),
                           ("muslim", "256")]

EM_DASH = "\u2014"  # written as an escape so the dash sweep never rewrites the constant itself
SPACED_HYPHEN = re.compile(r"[^\W\d_] - [^\W\d_]")

errors: list[str] = []
notes: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


def load(name: str) -> dict:
    path = PACKS[name]
    if not path.exists():
        fail(f"{name}: pack missing at {path}")
        return {}
    try:
        return json.loads(lzma.decompress(path.read_bytes()).decode("utf-8"))
    except (lzma.LZMAError, ValueError) as error:
        fail(f"{name}: pack does not decode: {error}")
        return {}


def saheeh() -> dict[tuple[int, int], str]:
    """(surah, ayah) -> the Saheeh International translation, the English a verse card shows."""
    rows = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    return {(int(s["id"]), int(a["id"])): a.get("textEnglishSaheeh", "")
            for s in rows for a in s["ayahs"]}


def quran() -> dict[int, dict[int, int]]:
    """surah -> ayah -> whitespace token count of the raw Hafs text."""
    rows = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    table: dict[int, dict[int, int]] = {}
    for surah in rows:
        counts = {}
        for ayah in surah["ayahs"]:
            text = ayah.get("textHafs") or ayah.get("textArabic") or ayah.get("text") or ""
            counts[int(ayah["id"])] = len(text.split())
        table[int(surah["id"])] = counts
    return table


def engine_citations(slug: str) -> dict[str, dict]:
    path = ENGINE / f"{slug}.json"
    if not path.exists():
        return {}
    book = json.loads(path.read_text(encoding="utf-8"))
    return {str(h.get("citation", "")): h for h in book.get("hadiths", [])}


def grade_of(hadith: dict) -> str:
    for key in ("grade", "grading", "gradings"):
        value = hadith.get(key)
        if isinstance(value, str) and value:
            return value
        if isinstance(value, list) and value:
            return "; ".join(str(g.get("grade", g)) if isinstance(g, dict) else str(g) for g in value)
    english = hadith.get("english")
    if isinstance(english, dict):
        for key in ("grade", "grading"):
            if english.get(key):
                return str(english[key])
    return ""


def dash_census(label: str, strings: list[str]) -> None:
    em = sum(s.count(EM_DASH) for s in strings)
    spaced = sum(len(SPACED_HYPHEN.findall(s)) for s in strings)
    line = f"{label}: {em} em dash(es), {spaced} spaced hyphen(s) between words"
    if em:
        fail(line)
    else:
        notes.append(line)


def main() -> None:
    head = "--head" in sys.argv
    tokens = quran()
    if not ENGINE.exists():
        notes.append(f"engine JSON not found at {ENGINE}: citation checks skipped")
    citations: dict[str, dict[str, dict]] = {}

    def hadith(slug: str, citation: str) -> dict | None:
        if not ENGINE.exists():
            return {}
        if slug not in citations:
            citations[slug] = engine_citations(slug)
        return citations[slug].get(citation)

    # Daily reminders.
    daily = load("DailyReminders")
    authored: list[str] = []
    linked = unlinked = 0
    for entry in daily.get("entries", []):
        kind = entry.get("type")
        if kind == "hadith":
            ref = entry.get("hadith") or ""
            slug, _, citation = ref.partition(":")
            if not ref:
                # Tilawa linked the generic door and the source line names nothing on the shelf: the
                # card opens the Hadith tab. Allowed, reported.
                unlinked += 1
                notes.append(f"DailyReminders {entry.get('id')}: no shelf link ({entry.get('source', '')})")
            elif hadith(slug, citation) is None:
                fail(f"DailyReminders {entry.get('id')}: hadith {ref} not on the shelf")
            else:
                linked += 1
        elif kind == "ayah":
            s, a = entry.get("s"), entry.get("a")
            if s not in tokens or a not in tokens[s]:
                fail(f"DailyReminders {entry.get('id')}: verse {s}:{a} does not exist")
        # The dash rule covers what Tilawa wrote, not the Saheeh translation or the hadith's text.
        if kind == "ayah":
            authored.append(entry.get("source", ""))
        elif kind == "hadith":
            authored += [entry.get("short", ""), entry.get("source", "")]
        else:
            authored += [entry.get("en", ""), entry.get("short", ""), entry.get("source", "")]
    notes.append(f"DailyReminders: {len(daily.get('entries', []))} cards, {linked} hadith cards open their hadith, "
                 f"{unlinked} open the Hadith tab")
    dash_census("DailyReminders authored lines", authored)

    # Version 3: a card's words are references (word ranges into its shelf narration or its Fortress
    # entry, or an ayah), never a copy beside a reference, and its headline is a range into the very
    # English the card shows (`shortWords`) wherever it is that English's own words. Checked against
    # the packs ON DISK: the bundled .hpk the app reads (islam_packs.py), HisnDuas.json.xz, and the
    # app's own Quran (a verse card's headline is cut from the Saheeh translation the app renders).
    if daily.get("version") != 3:
        fail(f"DailyReminders: pack version {daily.get('version')!r}, expected 3 (words and headlines as references)")
    fortress = {row["id"]: row for row in load("HisnDuas").get("entries", [])}
    translations = saheeh()
    shelf_packs: dict[str, object] = {}

    def shelf_texts(link: str) -> tuple[str, str] | None:
        slug, _, citation = link.partition(":")
        if slug not in shelf_packs:
            shelf_packs[slug] = Hadith(slug)
        if citation.startswith("#"):
            row = shelf_packs[slug].find_id(int(citation[1:]))
        else:
            rows = shelf_packs[slug].find(citation)
            row = next((r for r in rows if r.citation == citation), rows[0] if rows else None)
        return None if row is None else (row.arabic, row.text)

    def shelf_tokens(link: str) -> tuple[int, int] | None:
        texts = shelf_texts(link)
        return None if texts is None else (len(texts[0].split()), len(texts[1].split()))

    def headline_source(entry: dict) -> tuple[str, str] | None:
        """The very text the app cuts a card's headline from, and what it is: the Saheeh translation
        of the verse for a verse card, the narration's or the Fortress entry's translation for a card
        whose English is a range into it, the card's own `en` otherwise. None when there is none."""
        s, a = entry.get("s"), entry.get("a")
        if s is not None and a is not None and entry.get("type") == "ayah":
            verse = translations.get((s, a))
            return (verse, f"the Saheeh translation of {s}:{a}") if verse else None
        if entry.get("enWords") is not None:
            if entry.get("dua") is not None:
                dua = fortress.get(entry["dua"])
                return (dua["translation"], f"Fortress entry {entry['dua']}") if dua else None
            if entry.get("hadith"):
                texts = shelf_texts(entry["hadith"])
                return (texts[1], f"the translation of {entry['hadith']}") if texts else None
            return None
        return (entry["en"], "the card's own English") if entry.get("en") else None

    referenced = copies = headlines = 0
    for entry in daily.get("entries", []):
        eid = entry.get("id")
        ar_words, en_words = entry.get("arWords"), entry.get("enWords")
        if ar_words is not None and entry.get("ar"):
            fail(f"DailyReminders {eid}: carries Arabic beside a word range")
        if en_words is not None and entry.get("en"):
            fail(f"DailyReminders {eid}: carries English beside a word range")
        if entry.get("dua") is not None:
            dua = fortress.get(entry["dua"])
            if dua is None:
                fail(f"DailyReminders {eid}: Fortress entry {entry['dua']} does not exist")
            elif entry.get("ar"):
                fail(f"DailyReminders {eid}: carries Arabic beside its Fortress entry")
            elif ar_words is not None and not 0 <= ar_words[0] <= ar_words[1] < len(dua["arabic"].split()):
                fail(f"DailyReminders {eid}: arWords {ar_words} outside Fortress entry {entry['dua']}")
            referenced += 1
        elif ar_words is not None or en_words is not None:
            if not entry.get("hadith"):
                fail(f"DailyReminders {eid}: word ranges without a shelf link")
            else:
                sizes = shelf_tokens(entry["hadith"])
                if sizes is None:
                    fail(f"DailyReminders {eid}: {entry['hadith']} is not in the bundled packs")
                else:
                    if ar_words is not None and not 0 <= ar_words[0] <= ar_words[1] < sizes[0]:
                        fail(f"DailyReminders {eid}: arWords {ar_words} outside {entry['hadith']} ({sizes[0]} words)")
                    if en_words is not None and not 0 <= en_words[0] <= en_words[1] < sizes[1]:
                        fail(f"DailyReminders {eid}: enWords {en_words} outside {entry['hadith']} ({sizes[1]} words)")
            referenced += 1
        elif entry.get("type") in ("hadith", "sunnah", "dua") and entry.get("ar"):
            copies += 1

        # The headline: a range into the English the card shows, or Tilawa's own line, never both.
        short_words = entry.get("shortWords")
        if short_words is not None and entry.get("short"):
            fail(f"DailyReminders {eid}: carries a headline beside a headline range")
        if short_words is None and not entry.get("short"):
            fail(f"DailyReminders {eid}: no headline (the widget's line) at all")
        if short_words is not None:
            source = headline_source(entry)
            if source is None:
                fail(f"DailyReminders {eid}: shortWords but no English to cut it from")
            elif not 0 <= short_words[0] <= short_words[1] < len(source[0].split()):
                fail(f"DailyReminders {eid}: shortWords {short_words} outside {source[1]} "
                     f"({len(source[0].split())} words)")
            else:
                headlines += 1

        # A verse card renders its translation from the Quran, so a copy of it would be a second one.
        if entry.get("type") == "ayah" and entry.get("en"):
            fail(f"DailyReminders {eid}: a verse card carries a translation the app never shows")
    notes.append(f"DailyReminders: {referenced} cards read their words from the shelf, the Fortress or the Quran; "
                 f"{copies} keep Tilawa's own wording")
    notes.append(f"DailyReminders headlines: {headlines} cut from the English the card shows, "
                 f"{len(daily.get('entries', [])) - headlines} written by Tilawa")

    # The Sunnah reminder presets are Swift (SunnahReminders.swift), so their citations are pinned here
    # and checked the same way; a preset edit there needs an edit here.
    for slug, citation in SUNNAH_PRESET_CITATIONS:
        if hadith(slug, citation) is None:
            fail(f"Sunnah preset citation {slug} {citation} is not on the shelf")
    notes.append(f"Sunnah presets: {len(SUNNAH_PRESET_CITATIONS)} citations on the shelf")

    # Hadith topics.
    topics = load("HadithTopics")
    weak = 0
    graded = 0
    for entry in topics.get("entries", []):
        found = hadith(entry.get("slug", ""), str(entry.get("citation", "")))
        if found is None:
            fail(f"HadithTopics {entry.get('id')}: {entry.get('slug')} {entry.get('citation')} not on the shelf")
            continue
        grade = grade_of(found).lower()
        if grade:
            graded += 1
            if any(word in grade for word in ("da'if", "daif", "weak", "mawdu", "fabricat")):
                weak += 1
                notes.append(f"HadithTopics {entry.get('id')}: graded '{grade[:40]}'")
    notes.append(f"HadithTopics: {len(topics.get('entries', []))} citations, {len(topics.get('topics', []))} subjects, "
                 f"{graded} with an engine grade, {weak} graded weak")
    dash_census("HadithTopics titles and subjects",
                [e.get("title", "") for e in topics.get("entries", [])]
                + [t.get("label", "") + " " + t.get("subtitle", "") for t in topics.get("topics", [])]
                + [l.get("label", "") + " " + l.get("subtitle", "") for l in topics.get("lanes", [])])

    # Names details.
    names = load("NamesDetails")
    matched = unmatched = 0
    for number, row in names.get("names", {}).items():
        for verse in row.get("verses", []):
            if len(verse) != 4:
                fail(f"NamesDetails {number}: malformed verse {verse}")
                continue
            s, a, start, count = verse
            if s not in tokens or a not in tokens[s]:
                fail(f"NamesDetails {number}: verse {s}:{a} does not exist")
                continue
            if start < 0:
                unmatched += 1
            elif start + count > tokens[s][a]:
                fail(f"NamesDetails {number}: tokens {start}+{count} run past {s}:{a} ({tokens[s][a]} words)")
            else:
                matched += 1
    notes.append(f"NamesDetails: {len(names.get('names', {}))} names, {matched} verses tinted, {unmatched} named in another form")
    dash_census("NamesDetails explanations and living lines",
                [row.get("explanation", "") + " " + row.get("living", "") for row in names.get("names", {}).values()])

    # Word of the day.
    words = load("WordOfDay")
    if words.get("version") != 2:
        fail(f"WordOfDay: pack version {words.get('version')!r}, expected 2 (the form is the app's token, not carried)")
    for word in words.get("words", []):
        if "ar" in word:
            fail(f"WordOfDay {word.get('id')}: carries a copy of the word; the form is the token at the anchor")
        total = 0
        for occurrence in word.get("occ", []):
            if len(occurrence) != 3:
                fail(f"WordOfDay {word.get('id')}: malformed occurrence {occurrence}")
                continue
            s, a, indices = occurrence
            if s not in tokens or a not in tokens[s]:
                fail(f"WordOfDay {word.get('id')}: verse {s}:{a} does not exist")
                continue
            for index in indices:
                if index < 0 or index >= tokens[s][a]:
                    fail(f"WordOfDay {word.get('id')}: token {index} outside {s}:{a} ({tokens[s][a]} words)")
            total += len(indices)
        if total != word.get("n"):
            fail(f"WordOfDay {word.get('id')}: count {word.get('n')} but {total} occurrences")
    notes.append(f"WordOfDay: {len(words.get('words', []))} words")
    dash_census("WordOfDay glosses", [w.get("en", "") for w in words.get("words", [])])

    # Qiraat clips.
    clips = load("QiraatVariantAudio")
    sources = clips.get("sources", [])
    for source in sources:
        for key in ("hafsBase", "riwayahBase"):
            if not str(source.get(key, "")).startswith("https://"):
                fail(f"QiraatVariantAudio: source {source.get('reciter')} {key} is not https")
    rows = 0
    for tag, surahs in clips.get("riwayat", {}).items():
        for surah, entries in surahs.items():
            for row in entries:
                rows += 1
                if len(row) != 6 or not (0 <= row[1] < len(sources)):
                    fail(f"QiraatVariantAudio {tag} {surah}: malformed row {row}")
    notes.append(f"QiraatVariantAudio: {len(sources)} sources, {rows} places")
    if head:
        for source in sources:
            path = source["riwayahBase"] + ("001.mp3" if source.get("kind") == "span" else "/001001.mp3")
            request = urllib.request.Request(path, method="HEAD")
            try:
                with urllib.request.urlopen(request, timeout=15) as response:
                    notes.append(f"HEAD {path}: {response.status}")
            except Exception as error:  # noqa: BLE001
                fail(f"HEAD {path}: {error}")

    # Miracles.
    miracles = load("Miracles")
    if not str(miracles.get("imageBase", "")).startswith("https://"):
        fail("Miracles: imageBase is not https")
    images = 0
    prose: list[str] = []
    for article in miracles.get("articles", []):
        prose.append(article.get("title", ""))
        for block in article.get("blocks", []):
            if block.get("kind") == "image":
                images += 1
                path = str(block.get("path", ""))
                if not path or path.startswith("/") or "://" in path or " " in path:
                    fail(f"Miracles {article.get('slug')}: image path '{path}' is not a plain relative path")
            elif block.get("kind") in ("claim", "lead", "text", "closer"):
                prose.append(block.get("text", ""))
    notes.append(f"Miracles: {len(miracles.get('articles', []))} articles, {images} images")
    dash_census("Miracles prose", prose)

    # Hisn.
    hisn = load("HisnDuas")
    for entry in hisn.get("entries", []):
        audio = str(entry.get("audio", ""))
        if audio and not audio.startswith("https://"):
            fail(f"HisnDuas {entry.get('id')}: audio '{audio}' is not https")
    notes.append(f"HisnDuas: {len(hisn.get('entries', []))} duas, {len(hisn.get('categories', []))} situations")
    dash_census("HisnDuas titles and notes", [e.get("title", "") + " " + e.get("notes", "") for e in hisn.get("entries", [])])

    # Encyclopedia: the container decodes through the builder's reader (the app's layout), every
    # block's narrations line up with the header's light rows, and the count holds.
    if not PACKS["HadeethEnc"].exists():
        fail(f"HadeethEnc: pack missing at {PACKS['HadeethEnc']}")
    else:
        sys.path.insert(0, str(ROOT / "Scripts"))
        import build_hadeethenc_pack as henc
        try:
            encyclopedia = henc.read_pack(PACKS["HadeethEnc"])
        except (AssertionError, lzma.LZMAError, ValueError) as error:
            fail(f"HadeethEnc: pack does not decode: {error!r}")
            encyclopedia = {"tree": [], "entries": [], "full": []}
        count = len(encyclopedia["full"])
        if count < 2000:
            fail(f"HadeethEnc: only {count} entries")
        for light, full in zip(encyclopedia["entries"], encyclopedia["full"]):
            if light[0] != full["id"] or light[2] != full["en"]["title"] or light[1] != ",".join(full["cats"]):
                fail(f"HadeethEnc: header row {light[0]} does not match block entry {full['id']}")
                break
        topic_ids = {node["id"] for node in encyclopedia["tree"]}
        stray = sum(1 for full in encyclopedia["full"] for cat in full["cats"] if cat not in topic_ids)
        if stray:
            fail(f"HadeethEnc: {stray} narration topics are not in the tree")
        empty = sum(1 for full in encyclopedia["full"] if not full["ar"]["body"] or not full["en"]["body"])
        if empty:
            fail(f"HadeethEnc: {empty} narrations lack a body")
        notes.append(f"HadeethEnc: {count} narrations, {len(encyclopedia['tree'])} topics, "
                     f"{encyclopedia['entriesPerBlock']} per block")
        dash_census("HadeethEnc English commentary",
                    [full["en"].get("explanation", "") for full in encyclopedia["full"]]
                    + [b for full in encyclopedia["full"] for b in full["en"].get("benefits", [])])
        paragraphs = sum(full["en"].get("explanation", "").count("\n\n") for full in encyclopedia["full"])
        notes.append(f"HadeethEnc explanations: {paragraphs} paragraph breaks kept")
        # The dash filter re-punctuates; it must not move a word or lose a paragraph. It did both
        # once (2026-09-08): the sentence split was rejoined with a single space, so every blank
        # line in a dash-bearing explanation went with it. This probe is that bug, kept.
        probe = ("He raised his hands to his knees, the Sunnah, and then paused.\n\n"
                 "The Prophet (peace be upon him) said: pray as you have seen me pray.")
        softened = henc.soften(probe)
        if softened.count("\n\n") != probe.count("\n\n"):
            fail("HadeethEnc: soften() drops paragraph breaks")
        if re.findall(r"[^\W_]+", softened.lower()) != re.findall(r"[^\W_]+", probe.lower()):
            fail(f"HadeethEnc: soften() changes the wording: {softened!r}")
        if EM_DASH in softened:
            fail("HadeethEnc: soften() leaves an em dash behind")

    # The hadith typo vocabulary: shipped, and built for the packs on disk (decision B).
    vocabulary = DATA / "Hadith" / "HadithVocabulary.txt.xz"
    if not vocabulary.exists():
        fail(f"HadithVocabulary: missing at {vocabulary} (run -exportHadithVocabulary, then build_hadith_vocabulary.py)")
    else:
        sys.path.insert(0, str(ROOT / "Scripts"))
        import build_hadith_vocabulary as vocab_builder
        stamped, words = vocab_builder.read_shipped(vocabulary)
        expected = vocab_builder.shelf_fingerprint()
        if stamped != expected:
            fail(f"HadithVocabulary: built for shelf {stamped or '(none)'}, the packs on disk are {expected}")
        if len(words) < 10_000 or words != sorted(set(words)):
            fail(f"HadithVocabulary: {len(words)} words, not a sorted unique list")
        notes.append(f"HadithVocabulary: {len(words)} words for shelf {expected}")

    # Tajweed course prose.
    course = load("TajweedLessons")
    lesson_text: list[str] = []
    for chapter in course.get("chapters", []):
        for lesson in chapter.get("lessons", []):
            for value in lesson.values():
                if isinstance(value, str):
                    lesson_text.append(value)
                elif isinstance(value, list):
                    lesson_text += [v if isinstance(v, str) else json.dumps(v, ensure_ascii=False) for v in value]
    dash_census("TajweedLessons prose", lesson_text)

    # Registration.
    project = PBXPROJ.read_text(encoding="utf-8")
    for name, path in PACKS.items():
        if path.name not in project:
            fail(f"{name}: {path.name} is not registered in project.pbxproj (it will not be in the bundle)")
    notes.append("registration: every pack name appears in project.pbxproj")

    # The port's Swift string literals.
    literals: list[str] = []
    for relative in PORT_SWIFT:
        path = ROOT / relative
        if not path.exists():
            continue
        for literal in re.findall(r'"((?:[^"\\]|\\.)*)"', path.read_text(encoding="utf-8")):
            # Arithmetic inside an interpolation ("\(next - current)") is not punctuation.
            literals.append(re.sub(r"\\\([^)]*\)", "", literal))
    dash_census("Swift string literals of the port", literals)

    for note in notes:
        print("  " + note)
    if errors:
        print(f"\nFAILED: {len(errors)} error(s)")
        for error in errors:
            print("  " + error)
        raise SystemExit(1)
    print("\nOK: every Tilawa pack passes")


if __name__ == "__main__":
    main()
