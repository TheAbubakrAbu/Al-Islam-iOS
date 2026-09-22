#!/usr/bin/env python3
"""Build Resources/Data/Islam/DailyReminders.json.xz: the Reminder of the Day corpus.

    ./Scripts/build_daily_reminders.py [/path/to/Tilawa]

SOURCE: Tilawa's src/data/dailyReminders.ts (Jamil Hammoudeh, ported with permission): 180
date-stable cards in six types (ayah, hadith, sunnah, dua, dhikr, name), interleaved on purpose so
consecutive days differ in kind. Every hadith citation there is sahih or hasan.

WHAT THIS APP KEEPS: references, not copies, wherever the app already has the text (version 3,
2026-09-16). For an `ayah` card only the reference: the app renders the ayah from its own Hafs
text and Saheeh International translation, so the card carries neither. For a hadith or sunnah card
whose narration is on this app's shelf, the card's Arabic and English excerpts are located in that
narration's own text (the bundled .hpk, read through islam_packs.py, matched by hadith_spans.py's
keys: marks, a comma glued to a word, a tatweel dash standing alone and the excerpt's Quran-style
orthography are all set aside) and stored as WORD RANGES (`arWords`, `enWords`, 0-based inclusive
indices into the narration's whitespace tokens) with the excerpt itself dropped, so the card shows
the shelf's words and can never drift from them. An excerpt Tilawa worded differently from the
shelf (an abridgement, a variant narration, a conjunction dropped from the first word: ranges are
whole words) stays as written, and so does an English rendering that is Tilawa's own rather than
the shelf's translation: a different translation is a different text. The build log names every
card that keeps a copy beside its reference, with the shelf's own words next to it. For a dua card
that is a Fortress of the Muslim entry (HisnDuas.json.xz) the card carries the entry's id (`dua`,
plus `arWords` when it quotes part of it) and no Arabic, and `enWords` into the entry's translation
when its English is that translation or a slice of it; a dua that is a hadith is linked to the
shelf like a hadith card; a dua that is an ayah carries `s`/`a` (its English, Tilawa's own wording
with a note, is what the app shows, so it stays). The `short` headline follows the same rule: when
it is a verbatim slice (or the whole) of the English the card shows (the Saheeh translation of a
verse; the narration's or the Fortress entry's translation for an `enWords` card; the card's own
`en` otherwise: the same words, with case, punctuation and the translation's [brackets] set aside)
it is stored as `shortWords`, a range into THAT text, and the app derives the line from it
(DailyReminders.swift, `headline`); a headline Tilawa wrote itself stays as `short`. Never both.
Tilawa-authored lines (the sunnah, dhikr and name cards, a kept `short`, every `source`) have their
spaced hyphens and em dashes re-punctuated, the app's house rule. Deep links are re-targeted to
this app's own screens.

Pack: {"version": 3, "entries": [{"id", "type", "ar"?, "tr"?, "short"?, "shortWords"?, "en"?,
"source", "target"?, "s"?, "a"?, "repeat"?, "hadith"?, "arWords"?, "enWords"?, "dua"?}]} in the
source's own order. `target` is a QuranOpenTarget encoding ("ayah:2:152") or one of "hadith",
"duas", "adhkar", "names:<n>"; `hadith` is "<slug>:<citation>" when the card's narration is on
this app's shelf; `arWords`/`enWords` index the narration's Arabic and translation (`hadith`) or the
Fortress entry's (`dua`); `shortWords` indexes the English the card shows (see above). The app
materializes a referenced card's words and headline once, off the main thread, when the pack loads
(DailyReminders.swift, `resolveReferences`), and a verse card's headline at render time, together
with the translation it is cut from (`texts(for:)`).
"""
from __future__ import annotations

import collections
import difflib
import json
import lzma
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from hadith_spans import arabic_key as shelf_key, english_key, locate_arabic, locate_english  # noqa: E402
from islam_packs import Hadith  # noqa: E402
from tilawa_ts import eval_consts, load_softener, xz_compress  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
ENGINE = ROOT.parent / "Hadith-JSON-Engine" / "db" / "by_book" / "the_9_books"
OUT = ROOT / "Resources" / "Data" / "Islam" / "DailyReminders.json.xz"
HISN = ROOT / "Resources" / "Data" / "Islam" / "HisnDuas.json.xz"
TILAWA = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Tilawa"

SCRIPTURE = {"ayah", "hadith", "dua"}

_citations: dict[str, set[str]] = {}

# Every card that keeps a copy beside its reference, with why: printed at the end of the build.
KEPT: list[str] = []


BOOK_SLUGS = {"bukhari": "bukhari", "muslim": "muslim", "tirmidhi": "tirmidhi", "abu dawud": "abudawud",
              "nasai": "nasai", "an-nasai": "nasai", "ibn majah": "ibnmajah", "malik": "malik", "ahmad": "ahmed",
              "darimi": "darimi",
              # The dua cards cite the books by their full names.
              "sahih al-bukhari": "bukhari", "sahih muslim": "muslim", "sunan abi dawud": "abudawud",
              "sunan abu dawud": "abudawud", "jami' at-tirmidhi": "tirmidhi", "sunan at-tirmidhi": "tirmidhi",
              "sunan an-nasa'i": "nasai", "sunan ibn majah": "ibnmajah"}

_MARKS = re.compile("[ً-ٰٟۖ-ۭـ࣓-ࣿؐ-ؚ]")


def arabic_key(word: str) -> str:
    """The Fortress match's key: a word with its spelling conventions set aside (marks off, alif and
    hamza seats on their base letter, ta marbuta as ha, nothing but letters). The SHELF match uses
    hadith_spans's key instead; the Fortress keeps this one and the strict token walk under it
    (`locate_words`) because its entries carry ornaments (﴿ ﴾ *) and notes as tokens of their own,
    which hadith_spans's walk steps over: under it a card would leave its shelf narration for a
    Fortress slice with the ornaments inside (dua-al-islam-travel-1, Muslim 1342)."""
    w = _MARKS.sub("", word)
    w = re.sub("[ٱأإآ]", "ا", w)
    w = w.replace("ى", "ي").replace("ؤ", "و").replace("ئ", "ي").replace("ء", "").replace("ة", "ه")
    return re.sub("[^ء-ي]", "", w)


def locate_words(excerpt: str, text: str, key) -> list[int] | None:
    """The 0-based inclusive range of whitespace tokens of `text` that spell `excerpt`, every token
    in the range one of the excerpt's words, or None."""
    target = [k for k in (key(w) for w in excerpt.split()) if k]
    if not target:
        return None
    hay = [key(w) for w in text.split()]
    n = len(target)
    for i in range(len(hay) - n + 1):
        if hay[i:i + n] == target:
            return [i, i + n - 1]
    return None


def _alifless(token: str) -> str:
    return shelf_key(token).replace("ا", "")


def locate_shelf_arabic(excerpt: str, arabic: str) -> tuple[list[int], str] | None:
    """The excerpt as a token range of the narration's Arabic, and which key found it: hadith_spans's
    keys first; failing those, the same walk with every alif set aside (the shelf writes السَّمَوَاتِ
    where the excerpt writes السَّمَاوَاتِ: one spelling of one word, the shelf's words all the same;
    hadith_spans has no such fallback, so it lives here). A phrase of the narration's own words
    cannot land elsewhere in that narration under either key."""
    span = locate_arabic(excerpt, arabic)
    if span:
        return [span[0], span[1]], "shelf"
    needle = [k for k in (_alifless(t) for t in excerpt.split()) if k]
    hay = [(i, k) for i, k in ((i, _alifless(t)) for i, t in enumerate(arabic.split())) if k]
    n = len(needle)
    for i in range(len(hay) - n + 1):
        if [k for _, k in hay[i:i + n]] == needle:
            return [hay[i][0], hay[i + n - 1][0]], "alif"
    return None


def locate_one(quote: str, text: str) -> list[int] | None:
    """`quote` as ONE contiguous token range of `text` (hadith_spans's English keys: case,
    punctuation and bracketed words set aside), or None. A quote that skips part of the text with
    an ellipsis is not a slice of it."""
    spans = locate_english(quote, text)
    return [spans[0][0], spans[0][1]] if spans and len(spans) == 1 else None


def nearest_words(excerpt: str, text: str, key) -> tuple[list[str], list[str]]:
    """The run of `text`'s tokens the excerpt comes closest to (its longest common run of keys,
    widened by a token on the left and two on the right), and those tokens' keys: what the build
    log shows beside a copy the shelf does not have in those words."""
    needle = [k for k in (key(t) for t in excerpt.split()) if k]
    tokens = text.split()
    keyed = [(i, k) for i, k in ((i, key(t)) for i, t in enumerate(tokens)) if k]
    hay = [k for _, k in keyed]
    if not needle or not hay:
        return [], []
    m = difflib.SequenceMatcher(None, hay, needle, autojunk=False).find_longest_match(0, len(hay), 0, len(needle))
    if m.size == 0:
        return [], []
    start = max(0, m.a - m.b - 1)
    end = min(len(keyed), start + len(needle) + 3)
    return [tokens[i] for i, _ in keyed[start:end]], [k for _, k in keyed[start:end]]


def why_kept(excerpt: str, text: str, key) -> str:
    """Why an excerpt is not a range: the shelf's own words next to it."""
    words, keys = nearest_words(excerpt, text, key)
    if not words:
        return "none of its words are in the narration"
    needle = [k for k in (key(t) for t in excerpt.split()) if k]
    for j in range(len(keys) - len(needle) + 1):
        if keys[j + 1:j + len(needle)] == needle[1:] and keys[j] != needle[0] and keys[j].endswith(needle[0]):
            return f"whole words only: the shelf's first word is {words[j]} (the card drops its conjunction)"
    return "worded differently; the shelf reads: " + " ".join(words)


_packs: dict[str, Hadith] = {}


def shelf_row(link: str):
    """The bundled narration a "<slug>:<citation>" link names, from the app's own .hpk."""
    slug, _, citation = link.partition(":")
    if slug not in _packs:
        _packs[slug] = Hadith(slug)
    rows = _packs[slug].find(citation)
    return next((r for r in rows if r.citation == citation), rows[0] if rows else None)


def reference_shelf_words(entry: dict, counts: dict[str, int]) -> None:
    """Replace the card's copied excerpts with word ranges into its shelf narration, where they are
    that narration's words; leave what Tilawa worded differently, and say so."""
    row = shelf_row(entry["hadith"])
    if row is None:
        return
    link = entry["hadith"]
    if entry.get("ar"):
        found = locate_shelf_arabic(entry["ar"], row.arabic)
        if found:
            entry["arWords"], how = found
            del entry["ar"]
            counts["arabic from the shelf" + (" (an alif's spelling set aside)" if how == "alif" else "")] += 1
        else:
            counts["arabic kept: worded differently from the shelf"] += 1
            KEPT.append(f"{entry['id']} ({link}): ar kept, {why_kept(entry['ar'], row.arabic, shelf_key)}")
    if entry.get("en"):
        spans = locate_english(entry["en"], row.text)
        if spans and len(spans) == 1:
            entry["enWords"] = [spans[0][0], spans[0][1]]
            del entry["en"]
            counts["english from the shelf"] += 1
        else:
            counts["english kept: Tilawa's own rendering"] += 1
            reason = ("skips part of the narration (an ellipsis): one range cannot hold it" if spans else
                      "Tilawa's own rendering; the shelf reads: " + " ".join(nearest_words(entry["en"], row.text, english_key)[0]))
            KEPT.append(f"{entry['id']} ({link}): en kept, {reason}")


_hisn: dict | None = None


def hisn_entries() -> list[dict]:
    """The Fortress of the Muslim, as the app ships it."""
    global _hisn
    if _hisn is None:
        _hisn = json.loads(lzma.decompress(HISN.read_bytes()).decode("utf-8"))
    return _hisn["entries"]


def hisn_entry(dua_id: str) -> dict:
    return next(d for d in hisn_entries() if d["id"] == dua_id)


def reference_fortress_english(entry: dict, dua: dict, counts: dict[str, int]) -> None:
    """The card's English as a range into its Fortress entry's translation when it is that
    translation or a slice of it; a rendering of Tilawa's own (other words, a note in parentheses)
    stays, and the log says so."""
    if not entry.get("en"):
        return
    span = locate_one(entry["en"], dua["translation"])
    if span:
        entry["enWords"] = span
        del entry["en"]
        counts["english from the Fortress"] += 1
    else:
        counts["english kept beside a Fortress entry: Tilawa's own rendering"] += 1
        KEPT.append(f"{entry['id']} ({dua['id']}): en kept, Tilawa's own rendering; the Fortress reads: "
                    + " ".join(nearest_words(entry["en"], dua["translation"], english_key)[0]))


def reference_hisn(entry: dict, counts: dict[str, int]) -> bool:
    """A dua card that IS a Fortress entry (or part of one) carries the entry's id instead of the text."""
    wanted = "".join(arabic_key(w) for w in entry.get("ar", "").split())
    if not wanted:
        return False
    for dua in hisn_entries():
        have = "".join(arabic_key(w) for w in dua["arabic"].split())
        if have == wanted:
            entry["dua"] = dua["id"]
            del entry["ar"]
            counts["dua from the Fortress"] += 1
            reference_fortress_english(entry, dua, counts)
            return True
    for dua in hisn_entries():
        have = "".join(arabic_key(w) for w in dua["arabic"].split())
        if wanted in have:
            span = locate_words(entry["ar"], dua["arabic"], arabic_key)
            if span:
                entry["dua"] = dua["id"]
                entry["arWords"] = span
                del entry["ar"]
                counts["dua from the Fortress (part of an entry)"] += 1
                reference_fortress_english(entry, dua, counts)
                return True
    return False


def shown_english(entry: dict, saheeh: dict[tuple[int, int], str]) -> tuple[str, str]:
    """The English the app shows for a card (what a headline range indexes), and its name."""
    if entry["type"] == "ayah":
        return saheeh[(entry["s"], entry["a"])], "the Saheeh translation"
    if entry.get("enWords") is not None:
        if entry.get("dua"):
            return hisn_entry(entry["dua"])["translation"], "the Fortress entry's translation"
        return shelf_row(entry["hadith"]).text, "the narration's translation"
    return entry.get("en", ""), "the card's own English"


def reference_headline(entry: dict, counts: dict[str, int], saheeh: dict[tuple[int, int], str]) -> None:
    """`short` as a word range into the English the card shows, when it is a verbatim slice (or the
    whole) of it; a headline Tilawa wrote itself stays as written."""
    text, label = shown_english(entry, saheeh)
    span = locate_one(entry["short"], text) if text else None
    if span:
        entry["shortWords"] = span
        del entry["short"]
        counts[f"headline from {label}"] += 1
    else:
        counts["headline kept: Tilawa's own"] += 1


def shelf_link(source: str) -> str | None:
    """"Bukhari 9, Muslim 36" -> "<slug>:<citation>" for the first citation the shelf carries. A bare
    Muslim number resolves to its first lettered narration ("2699" -> "2699a"): the engine numbers
    Muslim's repeated chains that way, and the first is the one the citation names."""
    for part in source.split(","):
        # "Tirmidhi 1956 · Sahih (al-Albani)": the grading after the number (a dash in the source,
        # a middle dot once `source_line` has run) is not part of the citation.
        m = re.match(r"^\s*([A-Za-z' -]+?)\s+(\d+[a-z]?)\s*(?:[-·].*)?$", part)
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
    return re.sub(r"\s+[-–, ]\s+", " · ", text).strip()


def main() -> None:
    soften = load_softener()
    source = TILAWA / "src" / "data" / "dailyReminders.ts"
    if not source.exists():
        raise SystemExit(f"source not found: {source}")
    reminders = eval_consts(source, ["DAILY_REMINDERS"])["DAILY_REMINDERS"]

    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    counts = {int(s["id"]): len(s["ayahs"]) for s in quran}
    saheeh = {(int(s["id"]), int(a["id"])): a["textEnglishSaheeh"] for s in quran for a in s["ayahs"]}

    entries = []
    problems = []
    kinds: dict[str, int] = {}
    hadith_links = 0
    unlinked: list[str] = []
    references: dict[str, int] = collections.Counter()
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
            # Neither `ar` nor `en`: the app reads the ayah and its translation from the Quran.
            entry.update({"s": s, "a": a, "target": f"ayah:{s}:{a}"})
            entry["short"] = row["short"]
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
                if kind in ("hadith", "sunnah") and (linked := shelf_link(entry.get("source", ""))):
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
        # References in place of copies: the shelf's words for a linked narration, the Fortress's
        # for a dua it carries, the Quran's for a dua that is an ayah.
        if kind == "dua" and not reference_hisn(entry, references):
            m = re.match(r"^Quran\s+(\d+):(\d+)$", entry.get("source", ""))
            if m and int(m.group(1)) in counts and 1 <= int(m.group(2)) <= counts[int(m.group(1))]:
                entry["s"], entry["a"] = int(m.group(1)), int(m.group(2))
                del entry["ar"]
                references["dua from the Quran"] += 1
            elif linked := shelf_link(entry.get("source", "")):
                entry["hadith"] = linked
                hadith_links += 1
            else:
                references["dua kept: not in the Fortress or on the shelf"] += 1
        if kind in ("hadith", "sunnah", "dua") and entry.get("hadith"):
            reference_shelf_words(entry, references)
        # The headline last: it indexes the English the card shows, which the references decide.
        reference_headline(entry, references, saheeh)
        for key in ("short", "en", "source", "tr"):
            # The em dash is an escape here: the dash sweep once rewrote the literal into ", ",
            # which made every ordinary comma a "dash left" and blocked the build.
            if key in entry and ("\u2014" in entry[key] or " - " in entry[key]) and kind not in SCRIPTURE:
                problems.append(f"{row['id']}: dash left in {key}: {entry[key][:60]}")
        if ("short" in entry) == ("shortWords" in entry):
            problems.append(f"{row['id']}: a card carries either a headline or a headline range")
        entries.append(entry)

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:40]:
            print("  " + line, file=sys.stderr)
        raise SystemExit(1)

    body = json.dumps({"version": 3, "entries": entries}, ensure_ascii=False,
                      separators=(",", ":"), sort_keys=True).encode("utf-8")
    blob = xz_compress(body)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(blob)
    print(f"{len(entries)} entries {dict(sorted(kinds.items()))}, {hadith_links} shelf links")
    for line in unlinked:
        print(f"  hadith card without a shelf link: {line}")
    for what, n in sorted(references.items()):
        print(f"  {n:3d} {what}")
    if KEPT:
        print(f"  {len(KEPT)} copies kept beside a reference (the shelf or the Fortress does not have those words):")
        for line in KEPT:
            print(f"    {line}")
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} xz")


if __name__ == "__main__":
    main()
