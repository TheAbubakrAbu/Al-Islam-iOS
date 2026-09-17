"""Locate a piece of Quran text inside an ayah of THIS app's text, as token spans.

The packs never store a copy of an ayah or of a phrase from one: a builder that receives one
(a similar-ayah phrase, a tajweed lesson's example word, an article's quoted words) looks it up
here and stores the 0-based inclusive whitespace-token range instead, so the reader renders the
words from the app's own text and a copy can never drift from it (the sukoon marks did, once).

The comparison folds both sides the way the other builders fold (marks off, the dagger alif
with them, alif and hamza seats on their base letter, alif maqsura and yaa one letter), so a
source that spells the same word differently (Quran.com's فِى and مُوسَى against the mushaf's
فِي and مُوسَىٰ) still lands on the token it meant.

    from quran_spans import fold, locate, locate_fragment
    locate(["ٱلۡحَمۡدُ", "لِلَّهِ"], ayah_tokens)   -> [(0, 1)]   every non-overlapping occurrence
    locate_fragment("لنَّاسِ", ayah_tokens)          -> (2, 2)    the token(s) a sub-word piece sits in
"""

from __future__ import annotations

import re

_MARKS = re.compile("[ً-ٰٟۖ-ۭـ࣓-ࣿؐ-ؚ‏‎]")
_ALIFS = re.compile("[ٱأإآ]")


def fold(token: str) -> str:
    """The comparison form of a token: what is left when spelling conventions are set aside."""
    t = _MARKS.sub("", token)
    t = _ALIFS.sub("ا", t)
    t = t.replace("ى", "ي").replace("ؤ", "و").replace("ئ", "ي").replace("ء", "")
    return t


def locate(words: list[str], tokens: list[str]) -> list[tuple[int, int]]:
    """Every non-overlapping occurrence of `words` in `tokens`, exact first, folded otherwise."""
    if not words:
        return []
    for key in (lambda w: w, fold):
        target = [key(w) for w in words]
        if not all(target):
            continue
        hay = [key(t) for t in tokens]
        n = len(target)
        found: list[tuple[int, int]] = []
        i = 0
        while i <= len(hay) - n:
            if hay[i:i + n] == target:
                found.append((i, i + n - 1))
                i += n
            else:
                i += 1
        if found:
            return found
    return []


def locate_fragment(text: str, tokens: list[str]) -> tuple[int, int] | None:
    """The token range a piece of text sits in when it is not whole words (`لنَّاسِ`, the tail of
    a word, a word and the head of the next): a folded substring search over the joined tokens,
    mapped back onto the tokens it touches. None when the piece is not in the ayah at all."""
    needle = fold(text).replace(" ", "")
    if not needle:
        return None
    folded = [fold(t) for t in tokens]
    joined = "".join(folded)
    at = joined.find(needle)
    if at < 0:
        return None
    # Which tokens cover [at, at + len(needle)).
    start = end = None
    pos = 0
    for index, piece in enumerate(folded):
        nxt = pos + len(piece)
        if start is None and nxt > at:
            start = index
        if start is not None and nxt >= at + len(needle):
            end = index
            break
        pos = nxt
    if start is None or end is None:
        return None
    return (start, end)


def locate_slice(words: list[str], tokens: list[str]) -> tuple[int, int] | None:
    """The first token range for `words`: whole tokens when they are whole tokens, else the tokens
    the piece sits in."""
    spans = locate(words, tokens)
    if spans:
        return spans[0]
    return locate_fragment(" ".join(words), tokens)
