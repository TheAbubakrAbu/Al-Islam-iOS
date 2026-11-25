#!/usr/bin/env python3
"""Build Resources/Data/Hadith/HadithLexicon.bin: an Arabic to English dictionary learned from the
hadith shelf's own two languages.

The cross-language search highlight (CrossLanguageWordHighlight, iPhone/Quran/Words/WordByWord.swift)
lights the English words of a hadith when Arabic is typed, and the Arabic words when English is.
A hadith has no word-by-word gloss, so it used to borrow the dictionary the Quran's gloss pack
yields: Quran vocabulary, Quran spelling. A narrator's name, الوضوء, السواك and every word the
Quran does not use lit nothing. This is the same idea trained where it is used: every row of the
shelf that carries both languages is a pair, and a translation model (IBM Model 1) reads which
English word comes with which Arabic word.

An entry is kept when the Arabic word was seen in MIN_ROWS rows, the two were seen together in
MIN_TOGETHER, and the model gives the English word FIRST_PROBABILITY of the Arabic one (a second
to fourth word MORE_PROBABILITY: "ablution, wudu", "aisha, aishah"). The words of every chain
(those in more than COMMON_SHARE of all rows: قال, عن, حدثنا) need COMMON_PROBABILITY, which only
a true pair like نبي and "prophet" reaches. Glue, function and scaffolding words are never a
value, and "Allah" only on the word that is Allah.

The probabilities were set by reading pairs by hand on 2026-11-14: at 0.12 for every word about
half of a random sample was right (rare words collect whatever stands beside them), at these 63
of 70. Docs/Product/Cross-Language Highlight Design.md has the numbers.

    python3 Scripts/build_hadith_lexicon.py             build, report, write the pack
    python3 Scripts/build_hadith_lexicon.py --check     rebuild and compare with the pack on disk
    python3 Scripts/build_hadith_lexicon.py --evaluate  train without 800 rows and measure on them

KEY: the app's search fold of the word, direction marks dropped, with the article and its prefixes
off (`key_of`; CrossLanguageWordHighlight.hadithKey is the same rule). VALUE: up to MAX_WORDS
English words, each the most frequent spelling of its stem. Rerun after a hadith book is added or
its translation changes. The build is deterministic: the same shelf gives the same bytes.
"""
from __future__ import annotations

import argparse
import random
import re
import struct
import sys
import unicodedata
from collections import Counter
from functools import lru_cache
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from compress_shipped import read_shipped, write_shipped  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "Scripts"))
from islam_packs import HADITH_DIR, Hadith  # noqa: E402

PACK = HADITH_DIR / "HadithLexicon.bin"
MAGIC = 0x31584C48      # "HLX1"
FORMAT = 1

EM_ITERATIONS = 5
MAX_ARABIC, MAX_ENGLISH = 120, 220      # distinct words a row may have and still be a training pair
MIN_ROWS = 3
MIN_TOGETHER = 3
FIRST_PROBABILITY = 0.30
MORE_PROBABILITY = 0.20
COMMON_SHARE = 0.15
COMMON_PROBABILITY = 0.50
MAX_WORDS = 4
HELD_OUT = 800
# --check fails when a pin is missing, or the table shrinks below this.
MIN_KEYS = 7000
PINS = {"الوضوء": "ablution", "عائشة": "aisha", "الجنة": "paradise", "الصلاة": "prayer", "رمضان": "ramadan"}

WHITESPACE = set(" \t\n\r\u00a0\u2009\u200a\u202f")
FORMAT_MARKS = set("\u200b\u200c\u200d\u200e\u200f\u202a\u202b\u202c\u202d\u202e\u2060\u2066\u2067\u2068\u2069\u061c\ufeff")
ARABIC_FOLD = {
    "\u0670": "ا", "ٱ": "ا", "أ": "ا", "إ": "ا", "آ": "ا", "ٲ": "ا", "ٳ": "ا", "ٵ": "ا",
    "ؤ": "و", "ئ": "ي", "ء": "", "ٴ": "", "ٶ": "و", "ٷ": "و", "ٸ": "ي",
    "ۥ": "و", "ۦ": "ي", "\u06E7": "ي", "ى": "ا", "ة": "ه", "\u0640": "",
}
ARABIC_LETTER = re.compile(r"[ء-يٱ-ۓ]")
ARTICLE_PREFIXES = ("وبال", "فبال", "وكال", "فكال", "وال", "فال", "بال", "كال", "ولل", "فلل", "لل", "ال")
ALLAH_FORMS = {"الله", "لله", "اللهم", "تالله"}

# CrossLanguageWordHighlight.glueWords, and the function words no dictionary entry should carry.
GLUE = {
    "the", "and", "for", "with", "that", "this", "those", "these", "not", "nor",
    "who", "whom", "what", "which", "will", "shall", "was", "were", "are", "has",
    "have", "had", "his", "her", "him", "its", "their", "them", "they", "you",
    "your", "then", "than", "but", "from", "into", "unto", "upon", "when", "there",
    "indeed", "surely", "verily", "any", "all", "one",
    "our", "she", "may", "can", "been", "being", "would", "should", "could", "might",
    "did", "does", "ones", "most",
}
FUNCTION_WORDS = {
    "about", "above", "across", "after", "again", "against", "almost", "along", "already", "also",
    "although", "always", "amid", "among", "amongst", "another", "anyone", "anything", "because",
    "before", "behind", "below", "beneath", "between", "beyond", "both", "certainly", "concerning",
    "despite", "during", "each", "either", "else", "even", "ever", "except", "fact", "here", "how",
    "however", "instead", "just", "less", "more", "much", "neither", "never", "nothing", "now",
    "often", "once", "only", "onto", "other", "others", "otherwise", "own", "perhaps", "rather",
    "really", "regarding", "same", "since", "someone", "something", "soon", "still", "such",
    "thereafter", "thereby", "therefore", "therein", "thereof", "though", "through", "throughout",
    "thus", "till", "too", "toward", "towards", "truly", "under", "unless", "until", "very",
    "whatever", "whenever", "where", "whereby", "wherein", "wherever", "whether", "while", "whoever",
    "whomever", "whose", "why", "within", "without", "yet",
}
# The translators' scaffolding around a narration. These stay IN the training (so قال has "said" to
# go to, and حدثنا "narrated": left without them the commonest words of a chain took "messenger"
# and "prophet") and are never a value.
SCAFFOLDING = {
    "said", "say", "says", "saying", "narrated", "reported", "related", "told", "heard", "asked",
    "replied", "authority", "peace", "blessings", "pbuh", "saw", "upon",
}


SCAFFOLDING_STEMS: set[str] = set()   # filled once english_stem exists, below


def tokens(text: str) -> list[str]:
    out, current = [], []
    for ch in text:
        if ch in WHITESPACE:
            if current:
                out.append("".join(current))
                current = []
        else:
            current.append(ch)
    if current:
        out.append("".join(current))
    return out


@lru_cache(maxsize=None)
def fold_arabic(token: str) -> str:
    """The app's search fold of one Arabic word, with the invisible direction marks dropped
    (CrossLanguageWordHighlight.lookupFold)."""
    out = []
    for ch in token:
        if ch in FORMAT_MARKS:
            continue
        ch = ARABIC_FOLD.get(ch, ch)
        if ch and unicodedata.category(ch)[0] not in "PSMZC":
            out.append(ch)
    return "".join(out)


@lru_cache(maxsize=None)
def fold_english(part: str) -> str:
    out = []
    for ch in unicodedata.normalize("NFD", part):
        category = unicodedata.category(ch)
        if category[0] not in "PSMZC" and category != "Lm":
            out.append(ch)
    return "".join(out).lower()


def english_stem(word: str) -> str:
    """CrossLanguageWordHighlight.englishStem."""
    for suffix in ("ingly", "fully", "ings", "ers", "ies", "ing", "est", "ed", "er", "ly", "es", "s"):
        if word.endswith(suffix) and len(word) - len(suffix) >= 3:
            stem = word[: -len(suffix)]
            return stem[:-1] + "y" if stem.endswith("i") else stem
    return word


SCAFFOLDING_STEMS.update(english_stem(word) for word in SCAFFOLDING)


def key_of(folded: str) -> str:
    """A folded word minus the article and what is written onto it, three letters left at least.
    CrossLanguageWordHighlight.hadithKey is this same rule."""
    for prefix in ARTICLE_PREFIXES:
        if folded.startswith(prefix) and len(folded) - len(prefix) >= 3:
            return folded[len(prefix):]
    return folded


def names_allah(folded: str) -> bool:
    if folded in ALLAH_FORMS:
        return True
    stem = folded
    while stem and stem[0] in "وفبلك" and len(stem) - 1 >= 3:
        stem = stem[1:]
        if stem in ALLAH_FORMS:
            return True
    return False


def arabic_keys(text: str) -> list[str]:
    out = []
    for token in tokens(text):
        if not ARABIC_LETTER.search(token):
            continue
        folded = fold_arabic(token)
        if len(folded) >= 2:
            out.append("الله" if names_allah(folded) else key_of(folded))
    return out


def english_words(text: str) -> list[tuple[str, str]]:
    """(stem, word) for every word a dictionary entry could carry."""
    out = []
    for token in tokens(text.replace("\u2014", " ").replace("\u2013", " ")):
        for part in token.replace("-", " ").split(" "):
            word = fold_english(part)
            if len(word) >= 3 and word.isalpha() and word.isascii() \
                    and (word in SCAFFOLDING or (word not in GLUE and word not in FUNCTION_WORDS)):
                out.append((english_stem(word), word))
    return out


def load_rows() -> list[tuple[list[str], list[tuple[str, str]]]]:
    rows = []
    for path in sorted(HADITH_DIR.glob("*.hpk")):
        book = Hadith(path.stem)
        for index in range(len(book.rows)):
            item = book.item(index)
            english = (item.narrator + " " + item.text).strip()
            if not item.arabic.strip() or len(english) < 20:
                continue
            arabic = arabic_keys(item.arabic)
            words = english_words(english)
            if len(arabic) >= 3 and words:
                rows.append((arabic, words))
    return rows


def train(rows) -> tuple[list[dict[int, float]], dict[str, int], dict[str, int], Counter, Counter, Counter, Counter]:
    """t(english stem | arabic key) by IBM Model 1, on each row's DISTINCT words weighted by how
    often it has them (the same model as one position per word, at a fraction of the cost)."""
    arabic_ids: dict[str, int] = {"<null>": 0}
    english_ids: dict[str, int] = {}
    arabic_rows, english_rows, together = Counter(), Counter(), Counter()
    surface = Counter()
    pairs = []
    for arabic, words in rows:
        arabic_count = Counter(arabic)
        english_count = Counter(stem for stem, _ in words)
        surface.update(words)
        if len(arabic_count) > MAX_ARABIC or len(english_count) > MAX_ENGLISH:
            continue
        a_ids = [0] + [arabic_ids.setdefault(key, len(arabic_ids)) for key in sorted(arabic_count)]
        a_weight = [1.0] + [float(arabic_count[key]) for key in sorted(arabic_count)]
        e_ids = [english_ids.setdefault(stem, len(english_ids)) for stem in sorted(english_count)]
        e_weight = [float(english_count[stem]) for stem in sorted(english_count)]
        pairs.append((a_ids, a_weight, e_ids, e_weight))
        arabic_rows.update(a_ids[1:])
        english_rows.update(e_ids)
        for a in a_ids[1:]:
            for e in e_ids:
                together[(a, e)] += 1

    table: list[dict[int, float]] = [dict() for _ in arabic_ids]
    for a_ids, _, e_ids, _ in pairs:
        for a in a_ids:
            seen = table[a]
            for e in e_ids:
                seen[e] = 1.0
    for seen in table:
        if seen:
            share = 1.0 / len(seen)
            for e in seen:
                seen[e] = share

    for _ in range(EM_ITERATIONS):
        counts: list[dict[int, float]] = [dict() for _ in arabic_ids]
        for a_ids, a_weight, e_ids, e_weight in pairs:
            tables = [table[a] for a in a_ids]
            for e, weight in zip(e_ids, e_weight):
                probabilities = [w * t.get(e, 0.0) for t, w in zip(tables, a_weight)]
                total = sum(probabilities)
                if total <= 0:
                    continue
                scale = weight / total
                for a, probability in zip(a_ids, probabilities):
                    if probability:
                        row_counts = counts[a]
                        row_counts[e] = row_counts.get(e, 0.0) + probability * scale
        table = []
        for row_counts in counts:
            total = sum(row_counts.values())
            table.append({e: c / total for e, c in row_counts.items() if c / total > 1e-5} if total else {})
    return table, arabic_ids, english_ids, arabic_rows, english_rows, together, surface


def dictionary(rows) -> dict[str, list[str]]:
    table, arabic_ids, english_ids, arabic_rows, english_rows, together, surface = train(rows)
    stems = {index: stem for stem, index in english_ids.items()}
    # The most frequent spelling of each stem, ties broken by the alphabet so the build is stable.
    spelling: dict[str, tuple[int, str]] = {}
    for (stem, word), count in surface.items():
        best = spelling.get(stem)
        if best is None or (count, best[1]) > (best[0], word):
            spelling[stem] = (count, word)
    out: dict[str, list[str]] = {}
    for key, a in arabic_ids.items():
        if a == 0 or arabic_rows[a] < MIN_ROWS:
            continue
        is_allah = key == "الله"
        common = arabic_rows[a] > COMMON_SHARE * len(rows)
        words = []
        for e, probability in sorted(table[a].items(), key=lambda item: (-item[1], stems[item[0]])):
            needed = COMMON_PROBABILITY if common else (MORE_PROBABILITY if words else FIRST_PROBABILITY)
            if probability < needed or len(words) == MAX_WORDS:
                break
            stem = stems[e]
            if together[(a, e)] < MIN_TOGETHER:
                continue
            word = spelling[stem][1]
            if word in SCAFFOLDING or stem in SCAFFOLDING_STEMS:
                continue
            if (word == "allah") != is_allah and (word == "allah" or is_allah):
                continue
            words.append(word)
        if words:
            out[key] = words
    return out


def encode(table: dict[str, list[str]]) -> bytes:
    data = bytearray(struct.pack("<III", MAGIC, FORMAT, len(table)))
    for key in sorted(table):
        key_bytes = key.encode("utf-8")
        data += struct.pack("<H", len(key_bytes)) + key_bytes + bytes([len(table[key])])
        for word in table[key]:
            word_bytes = word.encode("utf-8")
            data += bytes([len(word_bytes)]) + word_bytes
    return bytes(data)


def lookup(table: dict[str, list[str]], word: str) -> list[str]:
    folded = fold_arabic(word)
    return table.get("الله" if names_allah(folded) else key_of(folded), [])


def evaluate(rows) -> None:
    order = list(range(len(rows)))
    random.Random(21).shuffle(order)
    held = [rows[i] for i in sorted(order[:HELD_OUT])]
    table = dictionary([rows[i] for i in sorted(order[HELD_OUT:])])
    english_cases = english_lit = arabic_cases = arabic_lit = 0
    frequency = Counter(key for arabic, _ in held for key in set(arabic))
    common = {key for key, _ in frequency.most_common(120)}
    for arabic, words in held:
        stems_in_row = {stem for stem, _ in words}
        values = {key: {english_stem(w) for w in table.get(key, [])} for key in set(arabic)}
        for stem in stems_in_row:
            english_cases += 1
            english_lit += any(stem in found for found in values.values())
        for key in set(arabic):
            if len(key) < 3 or key in common:
                continue
            arabic_cases += 1
            arabic_lit += bool(values[key] & stems_in_row)
    print(f"held out {len(held)} rows: English typed, an Arabic word is lit {english_lit / english_cases:.1%}; "
          f"Arabic typed, an English word is lit {arabic_lit / arabic_cases:.1%}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--check", action="store_true", help="rebuild and compare with the pack on disk")
    parser.add_argument("--evaluate", action="store_true", help="train without 800 rows and measure on them")
    arguments = parser.parse_args()

    rows = load_rows()
    print(f"{len(rows)} rows carry both languages")
    if arguments.evaluate:
        evaluate(rows)
        return

    table = dictionary(rows)
    data = encode(table)
    print(f"{len(table)} Arabic words, {sum(len(v) for v in table.values())} pairs, {len(data):,} bytes")
    failed = []
    if len(table) < MIN_KEYS:
        failed.append(f"only {len(table)} words (floor {MIN_KEYS})")
    for arabic, english in PINS.items():
        found = lookup(table, arabic)
        print(f"   {arabic}: {', '.join(found) or 'nothing'}")
        if english not in found:
            failed.append(f"{arabic} should give {english}")
    if arguments.check:
        shipped = read_shipped(PACK)
        if shipped is None:
            failed.append(f"no pack at {PACK} (or its compressed form)")
        elif shipped != data:
            failed.append("the pack on disk is not what the shelf builds: rerun without --check")
    for line in failed:
        print("FAIL", line)
    if failed:
        sys.exit(1)
    if not arguments.check:
        write_shipped(PACK, data)  # ships compressed (Scripts/compress_shipped.py)
        print(f"wrote {PACK.relative_to(ROOT)}")
    print("OK")


if __name__ == "__main__":
    main()
