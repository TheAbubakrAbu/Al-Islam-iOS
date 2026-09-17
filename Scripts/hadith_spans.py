#!/usr/bin/env python3
"""Word ranges into the app's own hadith shelf, for every pack and article that quotes a narration.

The rule (2026-09-16): nothing the app ships carries a copy of a hadith the bundled collections
already hold. A quote stores the row (`bukhari:6306`) and 0-based inclusive ranges of the row's
whitespace tokens, the Arabic's counted with its chain of narrators, the English's over the
translation alone, and the app slices the row's text at render time (`WordRange` in
iPhone/Islam/HadithQuote.swift, `DailyReminderStore.resolveReferences`). The only text a pack may
keep is text the shelf does not have in those words: an abridgement, or its own translation.

    shelf_link("Sahih al-Bukhari 6306")   -> ("bukhari", "6306")
    row("bukhari", "6306")                -> islam_packs.Item, or None
    locate_arabic(quote, row.arabic)      -> (first, last) token range, or None
    locate_english(quote, row.text)       -> [(first, last), ...] one per ellipsis-separated piece, or None
    words(text, ranges)                   -> the very string the app renders for those ranges

Matching is by key, not by byte: an Arabic token's key is its letters after `quran_spans.fold`
(marks off, alif and hamza seats folded, alif maqsura as yaa) with punctuation, quotes and tatweel
dropped, so the articles' fully vowelled matn finds the shelf's lightly vowelled one and a comma
glued to a word does not hide it. An English token's key is its letters and digits, lower-cased,
so "[that which is]" and "(ﷺ)" fall away as the article's own brackets do. Tokens whose key is
empty (a lone quote mark, an ornament) are skipped when matching but stay inside the range, so
the rendered slice is the row's text verbatim.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from islam_packs import Hadith  # noqa: E402
from quran_spans import fold  # noqa: E402

# The books as the articles, the reminder cards and the Dua screen cite them, lower-cased.
BOOKS = {
    "sahih al-bukhari": "bukhari", "sahih bukhari": "bukhari", "al-bukhari": "bukhari", "bukhari": "bukhari",
    "sahih muslim": "muslim", "muqaddimah of sahih muslim": "muslim", "muslim": "muslim",
    "sunan abi dawud": "abudawud", "sunan abu dawud": "abudawud", "abu dawud": "abudawud", "abi dawud": "abudawud",
    "sunan al-tirmidhi": "tirmidhi", "sunan at-tirmidhi": "tirmidhi", "jami' at-tirmidhi": "tirmidhi",
    "jami at-tirmidhi": "tirmidhi", "at-tirmidhi": "tirmidhi", "al-tirmidhi": "tirmidhi", "tirmidhi": "tirmidhi",
    "sunan ibn majah": "ibnmajah", "ibn majah": "ibnmajah",
    "sunan an-nasa'i": "nasai", "sunan al-nasa'i": "nasai", "an-nasa'i": "nasai", "al-nasa'i": "nasai",
    "nasa'i": "nasai", "nasai": "nasai",
    "sunan al-darimi": "darimi", "sunan ad-darimi": "darimi", "al-darimi": "darimi", "darimi": "darimi",
    "musnad ahmad": "ahmed", "ahmad": "ahmed",
    "muwatta malik": "malik", "muwatta' malik": "malik", "malik": "malik",
    "riyad as-salihin": "riyad_assalihin", "riyad al-salihin": "riyad_assalihin",
    "al-adab al-mufrad": "aladab_almufrad", "adab al-mufrad": "aladab_almufrad",
    "bulugh al-maram": "bulugh_almaram", "mishkat al-masabih": "mishkat_almasabih",
    "shama'il muhammadiyah": "shamail_muhammadiyah", "shamail muhammadiyah": "shamail_muhammadiyah",
    "40 hadith nawawi": "nawawi40", "nawawi 40": "nawawi40", "an-nawawi's forty": "nawawi40",
    "40 hadith qudsi": "qudsi40", "hadith qudsi": "qudsi40",
}

_CITATION = re.compile(r"^\s*([A-Za-z' .-]+?)\s+(\d+[a-z]?)\b")
_ELLIPSIS = re.compile(r"…|\.\.\.")
_ARABIC_LETTER = re.compile(r"[ء-يٱٹ-ۓ]")
_EN_KEY = re.compile(r"[^a-z0-9]")


def shelf_link(citation: str) -> tuple[str, str] | None:
    """"Sahih al-Bukhari 6306", "Sahih Muslim 1163a", "Bukhari 742 · Sahih" -> (slug, citation)."""
    m = _CITATION.match(citation.replace("’", "'"))
    if not m:
        return None
    slug = BOOKS.get(m.group(1).strip().lower())
    return (slug, m.group(2)) if slug else None


_books: dict[str, Hadith] = {}


def book(slug: str) -> Hadith:
    if slug not in _books:
        _books[slug] = Hadith(slug)
    return _books[slug]


def rows(slug: str, citation: str) -> list:
    """Every shelf row a citation can mean: the one row "#N" names by its number in the book, the
    one variant when the citation names it ("1163a"), all of them ("1163") otherwise, in sunnah.com's
    order; and, in a book without citations (Muwatta Malik, most of Bulugh al-Maram), the row
    numbered N, the app's own fallback."""
    if citation.startswith("#"):
        item = book(slug).find_id(int(citation[1:]))
        return [item] if item else []
    items = book(slug).find(re.sub(r"[a-z]$", "", citation))
    if citation and citation[-1].isalpha():
        return [item for item in items if item.citation == citation]
    if not items and citation.isdigit():
        item = book(slug).find_id(int(citation))
        return [item] if item else []
    return items


def row(slug: str, citation: str):
    """The shelf row a link names, the way the app reads it (`HadithQuoteSource`): the row whose
    citation is exactly this string when there is one ("26" is the Muqaddimah's 26, not 26a), else
    the first variant of the base number ("1163" -> 1163a)."""
    items = rows(slug, citation)
    for item in items:
        if item.citation == citation:
            return item
    return items[0] if items else None


def link(slug: str, item) -> str:
    """The reference to store for a row: "slug:citation" when that citation string names exactly
    one row of the book, else "slug:#N" by the row's number, which is never shared (Tirmidhi and
    Bulugh carry duplicate citation strings; Muwatta Malik has none)."""
    if item.citation and sum(1 for r in book(slug).rows if r.citation == item.citation) == 1:
        return f"{slug}:{item.citation}"
    return f"{slug}:#{item.id_in_book}"


def match(slug: str, citation: str, arabic: str = "", english: str = ""):
    """The variant whose text carries the quote: (row, arabic range or None, english ranges or None),
    the first variant where the Arabic locates (or, with no Arabic, the English), else the first
    variant with nothing located; None when the citation is not on the shelf. A quote cited
    "Sahih Muslim 2435" whose words are only in 2435b resolves to 2435b, and the reference the caller
    stores must name that variant (`row.citation`) so the app reads the same row."""
    candidates = rows(slug, citation)
    if not candidates:
        return None
    fallback = None
    for item in candidates:
        ar = locate_arabic(arabic, item.arabic) if arabic else None
        en = locate_english(english, item.text) if english else None
        if ar is not None or (not arabic and en is not None):
            return item, ar, en
        if fallback is None and en is not None:
            fallback = (item, None, en)
    return fallback or (candidates[0], None, None)


def arabic_key(token: str) -> str:
    return "".join(_ARABIC_LETTER.findall(fold(token)))


def english_key(token: str) -> str:
    return _EN_KEY.sub("", token.replace("’", "'").replace("‘", "'").lower())


def _keyed(tokens: list[str], key) -> list[tuple[int, str]]:
    out = []
    for index, token in enumerate(tokens):
        k = key(token)
        if k:
            out.append((index, k))
    return out


def _find(needle: list[str], hay: list[tuple[int, str]], start_after: int = -1) -> tuple[int, int] | None:
    """First run of `hay` keys equal to `needle`, beginning past token `start_after`."""
    n = len(needle)
    if n == 0:
        return None
    keys = [k for _, k in hay]
    for i in range(len(hay) - n + 1):
        if hay[i][0] <= start_after:
            continue
        if keys[i:i + n] == needle:
            return hay[i][0], hay[i + n - 1][0]
    return None


def locate_arabic(quote: str, arabic: str) -> tuple[int, int] | None:
    """The quote's words as one contiguous token range of the row's Arabic, or None."""
    needle = [k for k in (arabic_key(t) for t in quote.split()) if k]
    return _find(needle, _keyed(arabic.split(), arabic_key)) if needle else None


def english_pieces(quote: str) -> list[str]:
    """The quote without its quote marks, split where an ellipsis skips part of the narration."""
    text = quote.strip().strip('"“”').strip()
    return [p.strip(" .\"',;:“”") for p in _ELLIPSIS.split(text) if p.strip(" .\"',;:“”")]


def locate_english(quote: str, text: str) -> list[tuple[int, int]] | None:
    """One token range per piece of the quote, in order, all inside the row's translation; None
    when any piece is not there word for word."""
    hay = _keyed(text.split(), english_key)
    ranges = []
    after = -1
    for piece in english_pieces(quote):
        needle = [k for k in (english_key(t) for t in piece.split()) if k]
        if not needle:
            continue
        found = _find(needle, hay, after)
        if found is None:
            return None
        ranges.append(found)
        after = found[1]
    return ranges or None


def words(text: str, ranges) -> str:
    """The slice the app renders: whitespace tokens, ranges joined by an ellipsis."""
    if isinstance(ranges, tuple):
        ranges = [ranges]
    tokens = text.split()
    out = []
    for first, last in ranges:
        if 0 <= first <= last < len(tokens):
            out.append(" ".join(tokens[first:last + 1]))
    return " … ".join(out)


def token_count(text: str) -> int:
    return len(text.split())
