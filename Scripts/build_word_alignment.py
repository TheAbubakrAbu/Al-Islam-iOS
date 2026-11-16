#!/usr/bin/env python3
"""Build Resources/Data/Quran/WordAlignment.bin: which Arabic word each English word renders.

The cross-language search highlight (CrossLanguageWordHighlight, iPhone/Quran/Words/WordByWord.swift)
lights the English words of a result when Arabic is typed, and the Arabic words when English is.
It used to guess them at search time from the word-by-word gloss, which is a literal rendering and
not the translation on screen ("All-Aware" where Saheeh says "Acquainted"). This pack is the answer
worked out once, offline: for every ayah and each shipped translation (Saheeh International, Mustafa
Khattab), one byte per English word naming the Arabic word it renders, or 255 for none. An English
word is what whitespace or a long dash ends; an Arabic word is what whitespace ends.

How a pair is decided. Five steps, each working only on what the ones before left unexplained:

  1. GLOSS. An English word that is a word of an Arabic word's own gloss is that word's. Position
     picks between two Arabic words with the same gloss (Arabic and English run in roughly the
     same order inside an ayah), and the second of two such English words goes to the Arabic word
     still unexplained.
  2. GLOSSARY. A word the same lemma is glossed with in another ayah (خَبِير is "All-Aware" here and
     "Acquainted" there), or, more weakly, the same root.
  3. THE RESIDUE MODEL. IBM Model 1, both directions multiplied, trained ONLY on the words steps 1
     and 2 left over, with the lemma as the Arabic unit; three rounds, each on what the last left.
     Over whole ayahs the model cannot credit a frequent word with a rare rendering: قَالَ is "said"
     1,500 times and "responded" 60, and the rare word beside it took "responded". Among the
     leftovers alone the pairing is plain. A pair must have been left over together in two ayahs.
  4. SECOND WORDS. The second English word of an Arabic word that already has one, within NEAR
     tokens of the first ("put" beside the "forth" of قَدَّمَتۡ), refused while an unexplained Arabic
     word stands beside it ("eternal home" is دَارُ ٱلۡخُلۡدِ: the adjective is the neighbour's).
  5. THE LAST PAIR. One unexplained Arabic word and one unplaced English word, alone between the
     same explained neighbours on both sides. No count can decide a pairing seen once; position can.

Rules that hold throughout, each added for a class of wrong pair found reading the output by hand:
an English function word is placed by the gloss or not at all ("This is HOW We rewarded them" is
not جَزَيۡنَٰهُم), and "Allah" only on the word that is Allah; steps 2 to 5 place nothing on a particle,
a pronoun or a helper word (كَانَ, بَعۡدَ, دُونَ); a hyphenated token is one word; an Arabic word keeps
at most CAP English words; glue words and the translator's own insertions ([...] in Saheeh, the
corner brackets in Khattab) are never aligned.

Checked two ways. Automatically: the glosses of a twelfth of the roots are hidden and the pairs the
later steps make for those words are scored against the gloss (step 3 scores 96 to 99 in 100). By
hand (--sample): 100 pairs that are not the gloss's own, on a fresh seed after every change. On
2026-11-15 the final build read 98 of 100 right for Saheeh and 95 of 100 for Khattab, the freer
translation (the first build, one model over whole ayahs, read 95 and 89, on half as many pairs
for Khattab). The gloss's own pairs are not in those counts. Details are in
Docs/Product/Cross-Language Highlight Design.md.

    python3 Scripts/build_word_alignment.py            build, report, write the pack
    python3 Scripts/build_word_alignment.py --check    rebuild and compare with the pack on disk
    python3 Scripts/build_word_alignment.py --dry-run  build and report, write nothing
    python3 Scripts/build_word_alignment.py --sample 100 --seed 1 --translation mustafa [--kind model,root]

The pack is stamped with quran.qpk's fingerprint and the app refuses one stamped with another text,
so rerun this after any change to the Hafs text, either translation, the gloss pack or the
morphology pack. The build is deterministic: the same inputs give the same bytes.
"""
from __future__ import annotations

import argparse
import json
import lzma
import math
import random
import re
import struct
import sys
import unicodedata
from collections import Counter, defaultdict
from functools import lru_cache
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
QURAN_JSON = REPO.parent / "Quran-Tajweed-Engine" / "sources" / "Quran.json"
DATA = REPO / "Resources" / "Data" / "Quran"
PACK = DATA / "WordAlignment.bin"

MAGIC = 0x314C4158      # "XAL1"
FORMAT = 1
NONE = 255
TRANSLATIONS = (("saheeh", "textEnglishSaheeh"), ("mustafa", "textEnglishMustafa"))

EM_ITERATIONS = 6
DIAGONAL = 4.0          # the position prior's strength
CAP = 3                 # English words one Arabic word may own
ANCHOR_BOOST = 4.0
ANCHOR_FLOOR = 0.2
IMPLIED_BOOST = 2.0     # a gloss word in parentheses: "(belongs) to Allah"
PASSENGER = 3           # times rarer in its lemma's glosses than in the other word's: a phrase gloss's passenger
UNEXPLAINED_FIRST = 0.4 # of the best score, for an unexplained word with the same gloss to be preferred
NEAR = 2                # tokens apart at most, for a second English word of one Arabic word
LEMMA_SHARE = 0.02      # of a lemma's glosses must name the word, for the lemma glossary to count
ROOT_SEEN = 2           # tokens of the root glossed with the word, for the root glossary to count,
ROOT_SHARE = 0.01       # and the share of the root's glosses they must be
ROUNDS = 3              # times the residue model is trained, each on what the last one left
LEFTOVER_SHARED = 2     # explained neighbours a last pair must share: both sides (one side read 16 of 25 right)
# What ties an English word to an Arabic word, weakest first.
LEFTOVER, SECOND, MODEL, ROOT, LEMMA, IMPLIED, GLOSS = range(7)
KINDS = ("leftover", "second", "model", "root", "lemma", "implied", "gloss")
# Per translation. "joint" and "together": the product of the two directions a pair of the residue
# model must reach, and the ayahs it must have been left over together in. The rest gate a second word: the
# share of the probability it must win, the least the model must give it, the dice gate and the
# ayahs the pair must share. Khattab is the freer translation and is held tighter.
THRESHOLDS = {
    "saheeh": {"joint": 0.30, "together": 2, "accept": 0.40, "min_p": 0.02, "dice": 0.04, "second_together": 2},
    "mustafa": {"joint": 0.30, "together": 2, "accept": 0.50, "min_p": 0.02, "dice": 0.05, "second_together": 3},
}
# --check fails below these (the accepted build's numbers, rounded down).
FLOORS = {
    "saheeh": {"english": 0.915, "arabic": 0.92},
    "mustafa": {"english": 0.785, "arabic": 0.845},
}
ANCHOR_AGREEMENT_FLOOR = 0.99

# What WordTokens (WordByWord.swift) splits on. The pack's Arabic indices are these tokens.
WHITESPACE = set(" \t\n\r\u00a0\u2009\u200a\u202f")

# CrossLanguageWordHighlight.glueWords: never aligned, never lit on their own.
GLUE = {
    "the", "and", "for", "with", "that", "this", "those", "these", "not", "nor",
    "who", "whom", "what", "which", "will", "shall", "was", "were", "are", "has",
    "have", "had", "his", "her", "him", "its", "their", "them", "they", "you",
    "your", "then", "than", "but", "from", "into", "unto", "upon", "when", "there",
    "indeed", "surely", "verily", "any", "all", "one",
    "our", "she", "may", "can", "been", "being", "would", "should", "could", "might",
    "did", "does", "ones", "most",
}

# An English word also ends at an em or en dash: Khattab joins clauses with one and no space
# ("life", the dash, "made sacred by Allah"), and the two halves render two Arabic words.
# WordAlignmentStore.englishTokenRanges (WordAlignment.swift) splits the same way.
DASHES = "\u2014\u2013"


def english_tokens(text: str) -> list[str]:
    return tokens(text, DASHES)


ARABIC_FOLD = {
    "\u0670": "ا", "ٱ": "ا", "أ": "ا", "إ": "ا", "آ": "ا", "ٲ": "ا", "ٳ": "ا", "ٵ": "ا",
    "ؤ": "و", "ئ": "ي", "ء": "", "ٴ": "", "ٶ": "و", "ٷ": "و", "ٸ": "ي",
    "ۥ": "و", "ۦ": "ي", "\u06E7": "ي", "ى": "ا", "ة": "ه", "\u0640": "",
}
ARABIC_LETTER = re.compile(r"[ء-يٱ-ۓ]")
NON_WORD = re.compile(r"[^0-9A-Za-zÀ-ɏ؀-ۿ]+")
PARENTHESES = re.compile(r"\([^)]*\)")
ALLAH_FORMS = {"الله", "لله", "اللهم", "تالله"}
OPEN_INSERTION, CLOSE_INSERTION = "[\u02f9", "]\u02fa"


def tokens(text: str, also: str = "") -> list[str]:
    out, current = [], []
    for ch in text:
        if ch in WHITESPACE or ch in also:
            if current:
                out.append("".join(current))
                current = []
        else:
            current.append(ch)
    if current:
        out.append("".join(current))
    return out


@lru_cache(maxsize=None)
def fold(text: str) -> str:
    """The app's search fold, near enough for stems and units (nothing here is looked up by the app)."""
    if not ARABIC_LETTER.search(text):
        out = []
        for ch in unicodedata.normalize("NFD", text):
            category = unicodedata.category(ch)
            if ch in "\u2013\u2014":
                out.append(" ")
            elif category[0] not in "PSM" and category != "Lm":
                out.append(ch)
        return "".join(out).lower().strip()
    out = []
    for ch in text:
        ch = ARABIC_FOLD.get(ch, ch)
        if ch and unicodedata.category(ch)[0] not in "PSMZC":
            out.append(ch)
    return "".join(out)


def english_stem(word: str) -> str:
    """CrossLanguageWordHighlight.englishStem, with two repairs it needs here, where a stem is
    compared for equality: a final "e" goes ("tire" must meet "tires", "believe" "believed",
    "give" "giving") and a doubled consonant before a suffix is undone ("stopped", "sinners")."""
    stem = word
    for suffix in ("ingly", "fully", "ings", "ers", "ies", "ing", "est", "ed", "er", "ly", "es", "s"):
        if word.endswith(suffix) and len(word) - len(suffix) >= 3:
            stem = word[: -len(suffix)]
            if stem.endswith("i"):
                stem = stem[:-1] + "y"
            elif len(stem) >= 4 and stem[-1] == stem[-2] and stem[-1] not in "aeioulsfz":
                stem = stem[:-1]
            break
    return stem[:-1] if len(stem) >= 4 and stem.endswith("e") else stem


def names_allah(folded: str) -> bool:
    """CrossLanguageWordHighlight.namesAllah: the word, or the word with a و ف ب ل ك peeled off."""
    if folded in ALLAH_FORMS:
        return True
    stem = folded
    while stem and stem[0] in "وفبلك" and len(stem) - 1 >= 3:
        stem = stem[1:]
        if stem in ALLAH_FORMS:
            return True
    return False


def gloss_stems(gloss: str, folded_token: str) -> list[str]:
    """What a word's gloss names, as stems. The pack repeats a phrase gloss on each of its words
    ("Allah accepts repentance" on both يتوب and الله), so "Allah" stays only on the Name, which
    then names nothing else."""
    words = [w for w in NON_WORD.split(PARENTHESES.sub("", gloss).lower()) if len(w) >= 3 and w not in GLUE]
    if "allah" in words:
        words = ["allah"] if names_allah(folded_token) else [w for w in words if w != "allah"]
    return sorted({english_stem(w) for w in words})


def implied_stems(gloss: str, named: list[str]) -> list[str]:
    """The gloss words in parentheses or brackets: "(belongs) to Allah", "(lying) on his side". The
    translation often writes them out, and then they are this word's."""
    inside = " ".join(re.findall(r"[(\[]([^)\]]*)[)\]]", gloss)).lower()
    stems = {english_stem(w) for w in NON_WORD.split(inside) if len(w) >= 3 and w not in GLUE and w != "allah"}
    return sorted(stems - set(named))


def english_units(text: str) -> list[tuple[int, str, str, bool]]:
    """(token index, stem, folded word, inside a translator's insertion) for every alphabetic part
    of every token. "All-Knowing" is one token with two parts."""
    out, depth = [], 0
    for index, raw in enumerate(english_tokens(text)):
        opened = sum(raw.count(c) for c in OPEN_INSERTION)
        closed = sum(raw.count(c) for c in CLOSE_INSERTION)
        inserted = depth > 0 or opened > 0
        depth = max(0, depth + opened - closed)
        for part in raw.replace("-", " ").split(" "):
            word = fold(part)
            if word and word.isalpha():
                out.append((index, english_stem(word), word, inserted))
    return out


# Not glue to the highlighter, but never a word's rendering here: "never discounts" is لَا يُضِيعُ,
# and the model gave the verb its negation.
NEVER_ALIGNED = GLUE | {"never"}

# English function words. The gloss may place one ("except" on إِلَّا); the model alone may not, on any
# word: read by hand, these were the pairs it got wrong ("This is HOW We rewarded them" on
# جَزَيۡنَٰهُم, "brought ONLY a few coins" on إِنَّ) and the ones nobody searches for when it got them
# right. The particles of phrasal verbs are left out on purpose: "sent down" is one word, أَنزَلَ.
FUNCTION_WORDS = {
    "about", "above", "across", "after", "again", "against", "almost", "along", "already", "also",
    "although", "always", "amid", "among", "amongst", "another", "anyone", "anything", "because",
    "before", "behind", "below", "beneath", "between", "beyond", "both", "certainly", "concerning",
    "despite", "during", "each", "either", "else", "even", "ever",
    "except", "fact", "here", "how", "however", "instead", "just", "less", "more", "much", "neither",
    "nothing", "now", "often", "once", "only", "onto", "other", "others", "otherwise", "own",
    "perhaps", "rather", "really", "regarding", "same", "since", "someone", "something", "soon",
    "still", "such", "thereafter", "thereby", "therefore", "therein", "thereof", "though", "through",
    "throughout",
    "thus", "till", "too", "toward", "towards", "truly", "under", "unless",
    "until", "very", "whatever", "whenever", "where", "whereby", "wherein", "wherever", "whether",
    "while", "whoever", "whomever", "whose", "why", "within", "without", "yet",
    # Khattab's emphasis and joining words: they render a particle or nothing ("as WELL as").
    "well", "totally", "definitely", "simply", "merely", "actually", "around", "according", "cannot", "over",
    "whereas", "moreover",
    # Reflexives: أَنفُسَهُمۡ when the gloss says so, an English idiom otherwise ("submit yourselves").
    "myself", "yourself", "himself", "herself", "itself", "ourselves", "yourselves", "themselves",
    # Gloss words for particles (بَلۡ, كَلَّا, أَلَآ): with these here, such a word is not a content word.
    "nay", "unquestionably", "behold",
}


# Arabic helper words that have a root: auxiliaries and the nouns Arabic uses as prepositions. Their
# own gloss may place a word on them ("before" on قَبۡلَ); the residue model and the last-pair rule
# may not ("fear an ATTACK by the disbelievers" is not كَانُواْ). By lemma, as Morphology.json.xz spells it.
HELPER_LEMMAS = {
    "كان", "ليس", "عسى", "كل", "بعض", "غير", "سوى", "بين", "قبل", "بعد", "عند", "دون", "مع",
    "فوق", "تحت", "حول", "لدى", "لدي", "لدن", "حيث", "كيف", "اي", "اى", "ايها", "ذو", "ذات",
}


LIGHT_WORDS = {"and", "so", "then", "or", "but", "o", "the", "a", "an", "of", "in", "to", "at", "on", "by"}


def names_something(gloss: str) -> bool:
    """Whether a rootless word's gloss is one or two content words and nothing else, once the
    parentheses, a leading conjunction, the article and a short preposition are set aside."""
    words = [w for w in NON_WORD.split(PARENTHESES.sub("", gloss).lower()) if w and w not in LIGHT_WORDS]
    return 1 <= len(words) <= 2 and all(
        len(w) >= 3 and w not in NEVER_ALIGNED and w not in FUNCTION_WORDS for w in words)


def alignable(word: str, inserted: bool) -> bool:
    return not inserted and len(word) >= 3 and word not in NEVER_ALIGNED


def load_rows() -> list[dict]:
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    glosses = json.loads(lzma.open(DATA / "WordByWord.json.xz").read())["en"]
    morphology = json.loads(lzma.open(DATA / "Morphology.json.xz").read())
    lemma_text = morphology["lemmas"]       # lemma id - 1 -> [vowelled, plain]
    rows = []
    spelled: dict[str, Counter] = defaultdict(Counter)      # folded word -> the lemmas it carries
    for surah in quran:
        key = str(surah["id"])
        for ayah in surah["ayahs"]:
            words = tokens(ayah["textArabic"])
            if len(words) >= NONE:
                sys.exit(f"{surah['id']}:{ayah['id']} has {len(words)} words; an index is one byte")
            gloss = glosses[key][ayah["id"] - 1]
            lemmas = list(morphology["l"][key][ayah["id"] - 1])
            roots = morphology["r"][key][ayah["id"] - 1]
            if not (len(words) == len(gloss) == len(lemmas) == len(roots)):
                sys.exit(f"{surah['id']}:{ayah['id']}: the text, the gloss pack and the morphology pack disagree on its word count")
            folded = [fold(w) for w in words]
            for word, lemma in zip(folded, lemmas):
                if lemma:
                    spelled[word][lemma] += 1
            rows.append({
                "surah": surah["id"], "ayah": ayah["id"], "words": words, "folded": folded,
                "gloss": gloss, "roots": roots, "lemmas": lemmas,
                "saheeh": ayah["textEnglishSaheeh"], "mustafa": ayah["textEnglishMustafa"],
            })
    for row in rows:
        folded, gloss, roots, lemmas = row["folded"], row["gloss"], row["roots"], row["lemmas"]
        count = len(folded)
        # The morphology pack leaves some 1,600 rooted words without a lemma (كَانَ 102 times). Each
        # takes the lemma its spelling carries most often elsewhere, so it counts with its lemma.
        for i in range(count):
            if not lemmas[i] and roots[i] and folded[i] in spelled:
                lemmas[i] = min(spelled[folded[i]], key=lambda lemma: (-spelled[folded[i]][lemma], lemma))
        helper = [bool(l) and lemma_text[l - 1][1] in HELPER_LEMMAS for l in lemmas]
        stems = [gloss_stems(gloss[i], folded[i]) for i in range(count)]
        row["units"] = [f"L{lemmas[i]}" if lemmas[i] else f"T{folded[i]}" for i in range(count)]
        row["helper"] = helper
        row["stems"] = stems
        row["implied"] = [implied_stems(gloss[i], stems[i]) for i in range(count)]
        # What the model may place a word on: a word with a root that is not a helper, or a
        # rootless word whose whole gloss is a word of its own (the names: مُوسَىٰ "Musa",
        # وَيَعۡقُوبَ "and Yaqub", جَهَنَّمَ "Hell"). The rest are particles and pronouns, and a
        # particle glossed inside a phrase ("And your Lord is not" on وَمَا) is still a particle.
        row["content"] = [not helper[i] if roots[i] else names_something(gloss[i]) for i in range(count)]
    return rows


def train(pairs: list[tuple[list[str], list[str]]]) -> dict[str, dict[str, float]]:
    """IBM Model 1: t(target | source) over (sources, targets) pairs."""
    table: dict[str, dict[str, float]] = defaultdict(dict)
    for sources, targets in pairs:
        for source in sources:
            seen = table[source]
            for target in targets:
                seen[target] = 1.0
    for seen in table.values():
        share = 1.0 / len(seen)
        for target in seen:
            seen[target] = share

    for _ in range(EM_ITERATIONS):
        counts: dict[str, dict[str, float]] = defaultdict(dict)
        for sources, targets in pairs:
            tables = [table[source] for source in sources]
            for target in targets:
                probabilities = [t.get(target, 0.0) for t in tables]
                total = sum(probabilities)
                if total <= 0:
                    continue
                for source, probability in zip(sources, probabilities):
                    if probability:
                        row_counts = counts[source]
                        row_counts[target] = row_counts.get(target, 0.0) + probability / total
        table = defaultdict(dict)
        for source, row_counts in counts.items():
            total = sum(row_counts.values())
            table[source] = {target: c / total for target, c in row_counts.items() if c / total > 1e-6}
    return table


NULL = "<null>"


class Model:
    """t(english stem | arabic unit) over whole ayahs, plus the ayah-level counts the dice gate reads.
    It scores the gloss's own words against each other and decides the second word of a phrase."""

    def __init__(self, rows: list[dict]):
        pairs: list[tuple[list[str], list[str]]] = []
        self.arabic_count: Counter = Counter()
        self.english_count: Counter = Counter()
        self.together: Counter = Counter()
        self.ayahs_together: Counter = Counter()
        for row in rows:
            in_ayah = sorted({stem for name, _ in TRANSLATIONS for (_, stem, _, _) in english_units(row[name])})
            for unit in sorted(set(row["units"])):
                for stem in in_ayah:
                    self.ayahs_together[(unit, stem)] += 1
            for name, _ in TRANSLATIONS:
                english = [stem for (_, stem, _, _) in english_units(row[name])]
                if not english:
                    continue
                pairs.append(([NULL] + row["units"], english))
                units, stems = sorted(set(row["units"])), sorted(set(english))
                self.arabic_count.update(units)
                self.english_count.update(stems)
                for unit in units:
                    for stem in stems:
                        self.together[(unit, stem)] += 1
            # Each word with its own gloss, twice: the evidence that pins a rare lemma.
            for unit, stems in zip(row["units"], row["stems"]):
                if stems:
                    pairs.append(([unit], stems))
                    pairs.append(([unit], stems))
        self.table = train(pairs)

    def probability(self, unit: str, stem: str) -> float:
        return self.table[unit].get(stem, 0.0) if unit in self.table else 0.0

    def dice(self, unit: str, stem: str) -> float:
        total = self.arabic_count[unit] + self.english_count[stem]
        return 2 * self.together.get((unit, stem), 0) / total if total else 0.0


class Glossary:
    """Every word a lemma, and a root, is glossed with anywhere in the Quran. خَبِير is "All-Aware" in
    one ayah and "Acquainted" in another: a translation that says "Acquainted" where this ayah's
    gloss says "All-Aware" is still naming that word."""

    def __init__(self, rows: list[dict]):
        self.by_lemma: dict[str, Counter] = defaultdict(Counter)
        self.by_root: dict[int, Counter] = defaultdict(Counter)
        self.tokens: Counter = Counter()
        self.root_tokens: Counter = Counter()
        for row in rows:
            for index, unit in enumerate(row["units"]):
                self.tokens[unit] += 1
                self.root_tokens[row["roots"][index]] += 1
                for stem in row["stems"][index]:
                    self.by_lemma[unit][stem] += 1
                    if row["roots"][index]:
                        self.by_root[row["roots"][index]][stem] += 1

    def share(self, unit: str, stem: str) -> float:
        """The share of the lemma's glosses that name the stem."""
        return self.by_lemma[unit].get(stem, 0) / self.tokens[unit] if unit in self.by_lemma else 0.0

    def names(self, unit: str, stem: str) -> bool:
        """The lemma is glossed with the stem, in at least LEMMA_SHARE of its glosses: قَالَ has 1,600
        and one of them says "let"."""
        if unit not in self.by_lemma:
            return False
        seen = self.by_lemma[unit].get(stem, 0)
        return seen >= 1 and seen >= LEMMA_SHARE * self.tokens[unit]

    def root_names(self, root: int, stem: str) -> bool:
        """The same for the root, held to a count as well: a root's glosses are many lemmas' and
        carry more stray words (ع م ل has "let" twice in 360)."""
        if not root or root not in self.by_root:
            return False
        seen = self.by_root[root].get(stem, 0)
        return seen >= ROOT_SEEN and seen >= ROOT_SHARE * self.root_tokens[root]


class Line:
    """One ayah in one translation while it is being aligned."""

    def __init__(self, row: dict, name: str):
        self.row, self.name = row, name
        self.units = english_units(row[name])
        self.arabic_count = len(row["units"])
        self.placed: dict[int, tuple[float, int, int]] = {}     # position in units -> (score, Arabic index, kind)
        self.owns: dict[int, list[int]] = defaultdict(list)     # Arabic index -> its English tokens
        self.taken: set[int] = set()                            # English tokens with a part placed
        self.stems: dict[int, set[str]] = defaultdict(set)      # Arabic index -> the stems it owns

    def prior(self, position: int, index: int) -> float:
        return math.exp(-DIAGONAL * abs((index + 0.5) / self.arabic_count - (position + 0.5) / len(self.units)))

    def place(self, position: int, score: float, index: int, kind: int) -> None:
        self.placed[position] = (score, index, kind)
        self.owns[index].append(self.units[position][0])
        self.taken.add(self.units[position][0])
        self.stems[index].add(self.units[position][1])

    def open_words(self) -> list[int]:
        """The English words nothing has placed yet and the model may place. A hyphenated token is
        one word on screen: once a part of "alms-tax" is placed, the other part is not open."""
        return [position for position, (token, stem, word, inserted) in enumerate(self.units)
                if token not in self.taken and alignable(word, inserted)
                and word not in FUNCTION_WORDS and stem != "allah"]

    def open_arabic(self) -> list[int]:
        """The Arabic words that own no English word yet and the model may place one on."""
        return [index for index in range(self.arabic_count)
                if not self.owns[index] and self.row["content"][index]]

    def result(self) -> dict[int, tuple[int, int]]:
        """English token -> (Arabic index, kind): one Arabic word per token (the best of a hyphenated
        token's parts), CAP tokens per Arabic word, the surest kept."""
        per_token: dict[int, tuple[int, float, int]] = {}
        for position, (score, index, kind) in self.placed.items():
            token = self.units[position][0]
            if token not in per_token or (kind, score) > (per_token[token][2], per_token[token][1]):
                per_token[token] = (index, score, kind)
        per_arabic: dict[int, list[tuple[int, float, int]]] = defaultdict(list)
        for token, (index, score, kind) in per_token.items():
            per_arabic[index].append((kind, score, token))
        out: dict[int, tuple[int, int]] = {}
        for index in sorted(per_arabic):
            for kind, score, token in sorted(per_arabic[index], key=lambda item: (-item[0], -item[1], item[2]))[:CAP]:
                out[token] = (index, kind)
        return out


def place_gloss(line: Line, model: Model, glossary: Glossary) -> None:
    """Step 1. An English word that is a word of an Arabic word's own gloss is that word's.

    The gloss pack repeats a phrase gloss on each of its words ("O mankind" on both يَٰٓأَيُّهَا and
    ٱلنَّاسُ, "your forefathers" on both ءَابَآئِكُمُ and ٱلۡأَوَّلِينَ). The word belongs to the content
    word before the particle, and of two content words to the one whose lemma is glossed so
    elsewhere too: the other is a passenger.

    A word the English says as often as the Arabic carries it ("you would KNOW them ... you will
    surely KNOW them ... Allah KNOWS") is paired in order. Otherwise position picks, and a repeat
    of a word its Arabic word already owns goes to one still unexplained ("distress upon
    distress", غَمَّۢا بِغَمّٖ), unless that one is far off."""
    row = line.row
    candidates: dict[int, list[tuple[float, int, int]]] = {}
    named_at: dict[int, list[int]] = {}
    said: dict[str, list[int]] = defaultdict(list)
    for position, (_, stem, word, inserted) in enumerate(line.units):
        if not alignable(word, inserted):
            continue
        named, implied = [], []
        for index, unit in enumerate(row["units"]):
            if stem in row["stems"][index]:
                named.append((max(model.probability(unit, stem), ANCHOR_FLOOR) * ANCHOR_BOOST * line.prior(position, index), index, GLOSS))
            elif stem in row["implied"][index]:
                implied.append((max(model.probability(unit, stem), ANCHOR_FLOOR) * IMPLIED_BOOST * line.prior(position, index), index, IMPLIED))
        if len(named) > 1:
            # Passengers: only among words that carry the very same gloss text.
            groups: dict[str, list] = defaultdict(list)
            for c in named:
                groups[row["gloss"][c[1]]].append(c)
            named = []
            for group in groups.values():
                if len(group) > 1:
                    group = [c for c in group if row["content"][c[1]]] or group
                    share = {c[1]: glossary.share(row["units"][c[1]], stem) for c in group}
                    most = max(share.values())
                    group = [c for c in group if share[c[1]] * PASSENGER >= most]
                named += group
            named.sort(key=lambda c: c[1])
        if named or implied:
            candidates[position] = named + implied
        if named:
            named_at[position] = sorted(c[1] for c in named)
            said[stem].append(position)
    in_order: dict[int, int] = {}
    for stem, positions in said.items():
        carried = named_at[positions[0]]
        if len(positions) >= 2 and len(carried) == len(positions) and all(named_at[p] == carried for p in positions):
            in_order.update(zip(positions, carried))
    for position in sorted(candidates):
        found, stem = candidates[position], line.units[position][1]
        if position in in_order:
            best = next(c for c in found if c[1] == in_order[position] and c[2] == GLOSS)
        else:
            best = max(found, key=lambda c: (c[0], -c[1]))
            if stem in line.stems[best[1]]:
                unexplained = [c for c in found if not line.owns[c[1]] and c[0] >= UNEXPLAINED_FIRST * best[0]]
                if unexplained:
                    best = max(unexplained, key=lambda c: (c[0], -c[1]))
        line.place(position, *best)


def place_glossary(line: Line, glossary: Glossary) -> None:
    """Step 2. A word the lemma (or, more weakly, the root) is glossed with elsewhere, onto an Arabic
    word nothing has explained yet. Between the two stands a word of the lemma's glossary right
    beside what an explained word already owns: "knows best" is أَعۡلَمُ whole, and "best" is not the
    عِلۡم further along that merely shares the root. The surest first, one English word each."""
    row = line.row
    found = []
    for position in line.open_words():
        token, stem = line.units[position][0], line.units[position][1]
        for index in range(line.arabic_count):
            # A word with a root only: a particle's "glossary" is the phrases it was glossed inside.
            if not row["roots"][index]:
                continue
            named = glossary.names(row["units"][index], stem)
            if line.owns[index]:
                if not named or min(abs(token - other) for other in line.owns[index]) > NEAR:
                    continue
                kind, rank = SECOND, 1
            elif named:
                kind, rank = LEMMA, 2
            elif not row["helper"][index] and glossary.root_names(row["roots"][index], stem):
                kind, rank = ROOT, 0
            else:
                continue
            found.append((rank, line.prior(position, index), position, index, kind))
    for rank, prior, position, index, kind in sorted(found, key=lambda c: (-c[0], -c[1], c[2], c[3])):
        if line.units[position][0] not in line.taken and (kind == SECOND or not line.owns[index]):
            line.place(position, prior, index, kind)


class Residue:
    """Step 3's model: IBM Model 1 both ways over ONLY what steps 1 and 2 left unexplained.

    Over whole ayahs the model cannot credit a frequent word with a rare rendering: قَالَ is "said"
    1,500 times and "responded" 60, so t(responded | قَالَ) is nothing, and the rare word standing
    beside it takes "responded" instead. With every explained pair taken out of both sides, the
    "responded" lines hold a قَالَ nothing has explained and little else, and the pairing is plain.
    The two directions are multiplied: a pair must be the English word's best Arabic word AND the
    Arabic word's best English word."""

    def __init__(self, lines: list[Line]):
        forward, backward = [], []
        ayahs: dict[tuple[str, str], set] = defaultdict(set)
        for line in lines:
            arabic = [line.row["units"][index] for index in line.open_arabic()]
            english = [line.units[position][1] for position in line.open_words()]
            if english:
                forward.append(([NULL] + arabic, english))
            if arabic:
                backward.append(([NULL] + english, arabic))
            for unit in sorted(set(arabic)):
                for stem in sorted(set(english)):
                    ayahs[(unit, stem)].add((line.row["surah"], line.row["ayah"]))
        self.together = {pair: len(seen) for pair, seen in ayahs.items()}
        self.table = train(forward)
        self.reverse = train(backward)

    def links(self, line: Line, limits: dict) -> list[tuple[float, int, int]]:
        """(joint, position, Arabic index) for every pair this line should gain, one to one."""
        row = line.row
        words, arabic = line.open_words(), line.open_arabic()
        if not words or not arabic:
            return []
        forward: dict[tuple[int, int], float] = {}
        backward: dict[tuple[int, int], float] = {}
        forward_total = {p: self.table[NULL].get(line.units[p][1], 0.0) for p in words}
        backward_total = {i: self.reverse[NULL].get(row["units"][i], 0.0) for i in arabic}
        for p in words:
            stem = line.units[p][1]
            given_english = self.reverse.get(stem, {})
            for i in arabic:
                unit = row["units"][i]
                prior = line.prior(p, i)
                f = self.table[unit].get(stem, 0.0) * prior if unit in self.table else 0.0
                b = given_english.get(unit, 0.0) * prior
                forward_total[p] += f
                backward_total[i] += b
                if f and b:
                    forward[(p, i)], backward[(p, i)] = f, b
        scored = []
        for (p, i), f in forward.items():
            joint = (f / forward_total[p]) * (backward[(p, i)] / backward_total[i])
            if joint >= limits["joint"] and self.together.get((row["units"][i], line.units[p][1]), 0) >= limits["together"]:
                scored.append((joint, p, i))
        out, used_tokens, used_arabic = [], set(), set()
        for joint, p, i in sorted(scored, key=lambda c: (-c[0], c[1], c[2])):
            if line.units[p][0] not in used_tokens and i not in used_arabic:
                out.append((joint, p, i))
                used_tokens.add(line.units[p][0])
                used_arabic.add(i)
        return out


def place_second(line: Line, model: Model, limits: dict) -> None:
    """Step 4. The second English word of an Arabic word that already has one ("put" beside the
    "forth" of قَدَّمَتۡ): within NEAR tokens of the first, only when no unexplained Arabic word was in
    the running for it, and refused while an unexplained word stands beside ("eternal home" is
    دَارُ ٱلۡخُلۡدِ: the adjective is the neighbour's, not a second word of دَار)."""
    row = line.row
    waiting = []
    for position in line.open_words():
        token, stem = line.units[position][0], line.units[position][1]
        found, fresh = [], False
        for index, unit in enumerate(row["units"]):
            probability = model.probability(unit, stem)
            if probability < limits["min_p"] or model.dice(unit, stem) < limits["dice"] \
                    or model.ayahs_together[(unit, stem)] < limits["second_together"]:
                continue
            if not line.owns[index]:
                fresh = True
            elif min(abs(token - other) for other in line.owns[index]) <= NEAR:
                found.append((probability * line.prior(position, index), index))
        if found and not fresh:
            best = max(found, key=lambda c: (c[0], -c[1]))
            share = best[0] / (sum(c[0] for c in found) + model.probability(NULL, stem))
            waiting.append((share, position, best))
    for share, position, (score, index) in sorted(waiting, key=lambda w: (-w[0], w[1])):
        beside = [n for n in (index - 1, index + 1) if 0 <= n < line.arabic_count]
        if share >= limits["accept"] and not any(row["roots"][n] and not line.owns[n] for n in beside):
            line.place(position, score, index, SECOND)


def place_leftover(line: Line) -> None:
    """Step 5. One unexplained Arabic word and one unplaced English word, alone between the same
    explained neighbours: "This is the ultimate triumph", where "triumph" is ٱلۡفَوۡزُ and the only
    words left are "ultimate" and ٱلۡعَظِيمُ. No count can decide a pairing seen once; position can."""
    row = line.row
    words = set(line.open_words())
    # English, in order: the placed words and the open ones. An open word is alone when neither
    # neighbour in that sequence is open; its bounds are the Arabic words its neighbours render.
    sequence = [p for p in range(len(line.units)) if p in line.placed or p in words]
    english: dict[int, set] = {}
    for at, p in enumerate(sequence):
        if p not in words:
            continue
        before = sequence[at - 1] if at > 0 else None
        after = sequence[at + 1] if at + 1 < len(sequence) else None
        if before in words or after in words:
            continue
        english[p] = {line.placed[n][1] if n is not None else edge
                      for n, edge in ((before, -1), (after, line.arabic_count))}
    # Arabic, in order: the words that own something and the unexplained content words.
    # A word glossed with no word of its own ("they do" on يَعۡمَلُونَ) is rendered by English too
    # light to place, and would take the wrong neighbour here.
    order = [i for i in range(line.arabic_count) if line.owns[i] or (row["content"][i] and row["stems"][i])]
    arabic: dict[int, set] = {}
    for at, i in enumerate(order):
        if line.owns[i]:
            continue
        before = order[at - 1] if at > 0 else -1
        after = order[at + 1] if at + 1 < len(order) else line.arabic_count
        if (before >= 0 and not line.owns[before]) or (after < line.arabic_count and not line.owns[after]):
            continue
        arabic[i] = {before, after}
    edges = {-1, line.arabic_count}
    wanted: dict[int, list[tuple[int, int]]] = defaultdict(list)
    for p, bounds in english.items():
        for i, others in arabic.items():
            shared = bounds & others
            if shared - edges:
                wanted[p].append((len(shared), i))
    claims: dict[int, list[tuple[int, int]]] = defaultdict(list)
    for p, found in wanted.items():
        top = max(n for n, _ in found)
        best = [i for n, i in found if n == top]
        if len(best) == 1:
            claims[best[0]].append((top, p))
    for i in sorted(claims):
        top = max(n for n, _ in claims[i])
        best = [p for n, p in claims[i] if n == top]
        if len(best) == 1 and top >= LEFTOVER_SHARED:
            line.place(best[0], float(top), i, LEFTOVER)


def align_all(rows: list[dict], model: Model) -> dict[str, list[Line]]:
    """Every ayah in both translations, through the five steps."""
    glossary = Glossary(rows)
    lines = {name: [Line(row, name) for row in rows] for name, _ in TRANSLATIONS}
    everything = [line for name, _ in TRANSLATIONS for line in lines[name]]
    for line in everything:
        place_gloss(line, model, glossary)
    for line in everything:
        place_glossary(line, glossary)
    for _ in range(ROUNDS):
        residue = Residue(everything)
        found = [(line, residue.links(line, THRESHOLDS[line.name])) for line in everything]
        for line, links in found:
            for joint, position, index in links:
                line.place(position, joint, index, MODEL)
    for line in everything:
        place_second(line, model, THRESHOLDS[line.name])
        place_leftover(line)
    return lines


def build(rows: list[dict], model: Model):
    """The pack's bytes, the per-translation report, and every pair by kind (for --sample)."""
    report = {name: Counter() for name, _ in TRANSLATIONS}
    pairs = {name: [] for name, _ in TRANSLATIONS}
    lines = align_all(rows, model)
    records = []
    for number, row in enumerate(rows):
        record = bytearray([len(row["words"])])
        for name, _ in TRANSLATIONS:
            line = lines[name][number]
            alignment, units = line.result(), line.units
            english = english_tokens(row[name])
            if len(english) > 0xFFFF:
                sys.exit(f"{row['surah']}:{row['ayah']} {name}: too many words for a u16 count")
            record += struct.pack("<H", len(english))
            record += bytes(alignment[i][0] if i in alignment else NONE for i in range(len(english)))

            stats = report[name]
            owned = defaultdict(set)
            for token, (index, kind) in alignment.items():
                owned[index].add(token)
                stats[KINDS[kind]] += 1
                pairs[name].append((row, index, token, kind))
            asked: dict[str, list[int]] = {}
            for token, _, word, inserted in units:
                if alignable(word, inserted):
                    asked.setdefault(word, []).append(token)
            for word, positions in asked.items():
                stats["english_cases"] += 1
                stats["english_aligned"] += any(p in alignment for p in positions)
            seen = set()
            stem_count = Counter(stem for (_, stem, _, inserted) in units if not inserted)
            for index, folded in enumerate(row["folded"]):
                if row["roots"][index] == 0 or len(folded) < 3 or folded in seen:
                    continue
                seen.add(folded)
                same = [k for k, other in enumerate(row["folded"]) if other == folded]
                lit = set().union(*(owned[k] for k in same))
                stats["arabic_cases"] += 1
                stats["arabic_aligned"] += bool(lit)
                stats["english_words_lit"] += len(lit)
                # The easy cases: the gloss names one word, the line has it once, no other word's gloss has it.
                stems = row["stems"][index]
                if len(stems) == 1 and len(same) == 1 and stem_count[stems[0]] == 1 \
                        and not any(stems[0] in other for k, other in enumerate(row["stems"]) if k != index):
                    target = next(t for (t, stem, _, inserted) in units if stem == stems[0] and not inserted)
                    stats["anchors"] += 1
                    if target in alignment:
                        stats["anchors_placed"] += 1
                        stats["anchors_agree"] += alignment[target][0] == index
        records.append(bytes(record))

    surah_starts, ordinal, previous = [], 0, None
    for row in rows:
        if row["surah"] != previous:
            surah_starts.append(ordinal)
            previous = row["surah"]
        ordinal += 1
    fingerprint = struct.unpack_from("<Q", (DATA / "quran.qpk").read_bytes()[:48], 32)[0]
    header = struct.pack("<IIQII", MAGIC, FORMAT, fingerprint, len(rows), len(surah_starts))
    header += struct.pack(f"<{len(surah_starts)}I", *surah_starts)
    offsets, cursor = [], len(header) + 4 * (len(rows) + 1)
    for record in records:
        offsets.append(cursor)
        cursor += len(record)
    offsets.append(cursor)
    data = header + struct.pack(f"<{len(offsets)}I", *offsets) + b"".join(records)
    return data, report, pairs


def summary(report) -> dict:
    out = {}
    for name, _ in TRANSLATIONS:
        s = report[name]
        out[name] = {
            "english": s["english_aligned"] / s["english_cases"],
            "arabic": s["arabic_aligned"] / s["arabic_cases"],
            "per_word": s["english_words_lit"] / max(1, s["arabic_aligned"]),
            "anchors": s["anchors"],
            "placed": s["anchors_placed"] / max(1, s["anchors"]),
            "agree": s["anchors_agree"] / max(1, s["anchors_placed"]),
            "kinds": {kind: s[kind] for kind in reversed(KINDS)},
        }
    return out


def print_summary(numbers: dict) -> None:
    for name, _ in TRANSLATIONS:
        n = numbers[name]
        print(f"{name:8s} English typed, an Arabic word is aligned: {n['english']:6.1%}   "
              f"Arabic typed, English is aligned: {n['arabic']:6.1%}   "
              f"English words per Arabic word: {n['per_word']:.2f}")
        print(f"{'':8s} one-to-one gloss anchors: {n['anchors']}, placed {n['placed']:.1%}, agreeing {n['agree']:.2%}")
        print(f"{'':8s} pairs by kind: " + ", ".join(f"{kind} {count}" for kind, count in n["kinds"].items()))


def problems(numbers: dict) -> list[str]:
    out = []
    for name, _ in TRANSLATIONS:
        n = numbers[name]
        if n["agree"] < ANCHOR_AGREEMENT_FLOOR:
            out.append(f"{name}: anchor agreement {n['agree']:.2%} is under {ANCHOR_AGREEMENT_FLOOR:.0%}")
        for side in ("english", "arabic"):
            if n[side] < FLOORS[name][side]:
                out.append(f"{name}: {side} coverage {n[side]:.1%} is under its floor {FLOORS[name][side]:.1%}")
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--check", action="store_true", help="rebuild and compare with the pack on disk")
    parser.add_argument("--dry-run", action="store_true", help="build and report, write nothing")
    parser.add_argument("--sample", type=int, default=0, help="print this many pairs to read by hand")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--kind", default="model,second,leftover,root,lemma",
                        help="which pairs --sample draws from: " + ", ".join(KINDS))
    parser.add_argument("--translation", choices=[name for name, _ in TRANSLATIONS], default="saheeh")
    arguments = parser.parse_args()

    rows = load_rows()
    model = Model(rows)
    data, report, pairs = build(rows, model)
    numbers = summary(report)
    print_summary(numbers)

    if arguments.sample:
        wanted = [KINDS.index(kind) for kind in arguments.kind.split(",")]
        pool = [pair for pair in pairs[arguments.translation] if pair[3] in wanted]
        picks = random.Random(arguments.seed).sample(pool, min(arguments.sample, len(pool)))
        for number, (row, index, token, kind) in enumerate(picks, 1):
            english = english_tokens(row[arguments.translation])
            low, high = max(0, token - 9), min(len(english), token + 10)
            marked = " ".join(f"<<{w}>>" if k == token else w for k, w in enumerate(english[low:high], low))
            print(f"{number}. {row['surah']}:{row['ayah']} {KINDS[kind]}  {row['words'][index]} ({row['gloss'][index]})  ->  {english[token]}")
            print(f"   {marked}")
        return

    failed = problems(numbers)
    if arguments.check:
        if not PACK.exists():
            failed.append(f"no pack at {PACK}")
        elif PACK.read_bytes() != data:
            failed.append("the pack on disk is not what these inputs build: rerun without --check")
    for line in failed:
        print("FAIL", line)
    if failed:
        sys.exit(1)
    if not arguments.check and not arguments.dry_run:
        PACK.write_bytes(data)
        print(f"wrote {PACK.relative_to(REPO)} ({len(data):,} bytes, {len(rows)} ayahs)")
    print("OK")


if __name__ == "__main__":
    main()
