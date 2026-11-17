"""Build Resources/Data/Quran/QuranVocabulary.json.xz: the Quran's most common words, ranked, with
the figures the Quran Words page and the "Words of the Quran" article quote, and how often each
tajweed rule colours a letter in Hafs. Design: Docs/Product/Quran Words Design.md.

SOURCES
-------
- The Quranic Arabic Corpus morphology (Kais Dukes), the revised file kept at
  github.com/mustafa0x/quran-morphology, pinned below by commit and SHA-256 and cached under
  build/sources/ (git-ignored; downloaded on first run). It is the COUNTING source: every word has
  its segments, and every stem its dictionary form (lemma). QUL's lemma table (the app's
  Morphology.json.xz) leaves about 1,600 content words without one (كَانَ 290 times) and folds
  مَن into مِن, so its ranks would be wrong.
- QUL's word-lemma table (Quran-Tajweed-Engine/sources/QUL): the headword's Arabic spelling (its
  dictionary forms are closer to the mushaf's) and, for three lumped lemmas, the split a learner
  meets (SPLIT_BY_QUL).
- QUL's word-root table: the root count (the table Word Study uses).
- The app's Hafs text (Quran-Tajweed-Engine/sources/Quran.json): the word count, the spellings
  count, and each headword's first occurrence as a token index in THIS app's order.
- Scripts/quran_vocabulary_words.tsv: the reviewed Arabic and meaning of every listed headword.
- The engine's Hafs tajweed annotations (Quran-Tajweed-Engine/data/tajweed).

HEADWORDS
---------
Each Quran word belongs to ONE headword, so headword counts add up and the coverage meter is a
plain sum: its first stem's lemma; or, when its only stem is a pronoun (هُوَ, لَهُمۡ, بِهِۦ), the
pronoun entry for that person (PRON:3MS ...). The disjointed letters (الٓمٓ) belong to none.
`count` = words a headword heads (the coverage share); `uses` = every word with the lemma in any
stem (مِمَّا is a use of مَا too), which is the number the page shows.

RUN
---
    python3 Scripts/build_quran_vocabulary.py            build the pack
    python3 Scripts/build_quran_vocabulary.py --draft    append suggested rows for unreviewed headwords
                                                         to Scripts/quran_vocabulary_words.draft.tsv
    python3 Scripts/build_quran_vocabulary.py --check    rebuild in memory, fail if the pack differs
"""

from __future__ import annotations

import hashlib
import json
import lzma
import pathlib
import re
import sqlite3
import sys
import tempfile
import urllib.request
import zipfile
from collections import Counter, defaultdict

ROOT = pathlib.Path(__file__).resolve().parent.parent
ENGINE = ROOT.parent / "Quran-Tajweed-Engine"
SOURCES = ENGINE / "sources"
QURAN_JSON = SOURCES / "Quran.json"
QUL = SOURCES / "QUL"
TAJWEED_DIR = ENGINE / "data" / "tajweed"
WORD_BY_WORD = ROOT / "Resources" / "Data" / "Quran" / "WordByWord.json.xz"
WORDS_TSV = ROOT / "Scripts" / "quran_vocabulary_words.tsv"
DRAFT_TSV = ROOT / "Scripts" / "quran_vocabulary_words.draft.tsv"
OUT = ROOT / "Resources" / "Data" / "Quran" / "QuranVocabulary.json.xz"

QAC_COMMIT = "8f38b39016824284f9ed16ae15069ff9102c4acf"
QAC_URL = f"https://raw.githubusercontent.com/mustafa0x/quran-morphology/{QAC_COMMIT}/quran-morphology.txt"
QAC_SHA256 = "742bfac59941b2cb09736d5b7aae694af50792261fb8450cbf6afafcc340645f"
QAC_CACHE = ROOT / "build" / "sources" / "qac" / f"quran-morphology-{QAC_COMMIT[:7]}.txt"

LISTED = 500
TIER_SIZE = 100

# The corpus files these under one lemma; a learner meets them as different words. Their words
# take the QUL lemma at their location instead (ذا = ذَٰلِكَ, هَٰذَا, أُولَٰٓئِكَ ...; أَيّ = أَيّ and
# يَٰٓأَيُّهَا; يَوْم = يَوۡم and يَوۡمَئِذٍ).
SPLIT_BY_QUL = {"ذا", "أَيّ", "يَوْم"}

LETTER = re.compile(r"[\u0621-\u063A\u0641-\u064A\u0671-\u06D3\u06FA-\u06FF]")
WAQF = re.compile(r"[\u06D6-\u06DC\u06DE\u06E9]")
MARKS = re.compile(r"[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]")


# MARK: - Inputs

def qac_lines() -> list[str]:
    if not QAC_CACHE.exists():
        QAC_CACHE.parent.mkdir(parents=True, exist_ok=True)
        print(f"  downloading the corpus file ({QAC_COMMIT[:7]})")
        with urllib.request.urlopen(QAC_URL, timeout=60) as response:
            data = response.read()
        if hashlib.sha256(data).hexdigest() != QAC_SHA256:
            raise SystemExit("the corpus download does not match its pinned SHA-256")
        QAC_CACHE.write_bytes(data)
    data = QAC_CACHE.read_bytes()
    if hashlib.sha256(data).hexdigest() != QAC_SHA256:
        raise SystemExit(f"{QAC_CACHE} does not match its pinned SHA-256; delete it to download again")
    return data.decode("utf-8").splitlines()


def open_sqlite(path: pathlib.Path) -> sqlite3.Connection:
    with zipfile.ZipFile(path) as archive:
        names = [n for n in archive.namelist() if n.endswith(".db")]
        if len(names) != 1:
            raise SystemExit(f"{path.name}: expected one .db inside, found {names}")
        data = archive.read(names[0])
    handle = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    handle.write(data)
    handle.close()
    return sqlite3.connect(handle.name)


class Segment:
    __slots__ = ("form", "tag", "lemma", "root", "affix", "features")

    def __init__(self, form: str, features: list[str]):
        self.form = form
        self.tag = features[0]
        self.lemma = next((f[4:] for f in features if f.startswith("LEM:")), None)
        self.root = next((f[5:] for f in features if f.startswith("ROOT:")), None)
        self.affix = "PREF" in features or "SUFF" in features
        self.features = features


def load_corpus() -> dict[tuple[int, int, int], list[Segment]]:
    words: dict[tuple[int, int, int], list[Segment]] = defaultdict(list)
    for line in qac_lines():
        if not line or line.startswith("#"):
            continue
        location, form, _kind, features = line.split("\t")
        s, a, w, _g = map(int, location.split(":"))
        words[(s, a, w)].append(Segment(form, features.split("|")))
    return dict(words)


def load_quran():
    """(ayah key -> raw tokens), word count, distinct spellings with marks, without."""
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    tokens: dict[tuple[int, int], list[str]] = {}
    for surah in quran:
        for ayah in surah["ayahs"]:
            tokens[(surah["id"], ayah["id"])] = ayah["textArabic"].split()
    words = [WAQF.sub("", t) for ts in tokens.values() for t in ts if LETTER.search(t)]
    return tokens, len(words), len(set(words)), len({MARKS.sub("", w) for w in words})


def load_glosses() -> dict[tuple[int, int], list[str]]:
    data = json.loads(lzma.open(WORD_BY_WORD).read())
    return {(int(s), i + 1): row for s, ayahs in data["en"].items() for i, row in enumerate(ayahs)}


def load_tsv() -> dict[str, tuple[str, str]]:
    rows: dict[str, tuple[str, str]] = {}
    if not WORDS_TSV.exists():
        return rows
    for number, line in enumerate(WORDS_TSV.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) != 3 or not all(p.strip() for p in parts):
            raise SystemExit(f"{WORDS_TSV.name}:{number}: expected key<TAB>arabic<TAB>meaning")
        key, arabic, meaning = (p.strip() for p in parts)
        if key in rows:
            raise SystemExit(f"{WORDS_TSV.name}:{number}: {key} listed twice")
        if "\u2014" in meaning:
            raise SystemExit(f"{WORDS_TSV.name}:{number}: no em dashes")
        rows[key] = (arabic, meaning)
    return rows


# MARK: - Spelling

def uthmani(text: str) -> str:
    """A QUL dictionary form in the mushaf's marks, changed mark by mark only: the Uthmani sukoon,
    hamzatul wasl on a word-initial bare alif, and yaa (not alif maqsurah) inside a word or after
    a kasra."""
    text = text.replace("\u0652", "\u06E1")
    # A shadda on the first letter is the assimilation of the word before it (ٱلنَّاس, لَّيۡسَ),
    # written before or after that letter's vowel.
    if len(text) > 1 and text[1] == "\u0651":
        text = text[0] + text[2:]
    elif len(text) > 2 and text[2] == "\u0651" and MARKS.match(text[1]):
        text = text[:2] + text[3:]
    # A word-initial آ (precomposed or alif + madd sign) is ءَا in the mushaf (ءَامَنَ, ءَاتَىٰ).
    if text.startswith("\u0622"):
        text = "\u0621\u064E\u0627" + text[1:]
    elif text.startswith("\u0627\u0653"):
        text = "\u0621\u064E\u0627" + text[2:]
    text = text.replace("\u0622", "\u0627\u0653")
    if text.startswith("\u0627") and (len(text) == 1 or not MARKS.match(text[1])):
        text = "\u0671" + text[1:]
    out = []
    for i, ch in enumerate(text):
        if ch == "\u0649":
            nxt = text[i + 1:]
            later_letter = bool(LETTER.search(nxt))
            after_kasra = i > 0 and text[i - 1] == "\u0650"
            if later_letter or after_kasra and not nxt.startswith("\u0670"):
                ch = "\u064A"
        out.append(ch)
    return "".join(out)


def skeleton(text: str) -> str:
    """The letters alone, hamza seats and alif forms folded: قَالَ and قالَ, ٱللَّهِ and اللَّه match."""
    text = MARKS.sub("", WAQF.sub("", text))
    return re.sub("[\u0623\u0625\u0622\u0671]", "\u0627", text).replace("\u0649", "\u064A")


def root_letters(root: str | None) -> str:
    return " ".join(root) if root else ""


# MARK: - Build

def kind(segment: Segment) -> str:
    """V a verb, R a noun or adjective with a root, P a particle."""
    if segment.tag in ("PERF", "IMPF", "IMPV"):
        return "V"
    return "R" if segment.root else "P"


def mixed_lemmas(corpus: dict[tuple[int, int, int], list[Segment]]) -> set[str]:
    """Lemmas the corpus spells alike for two different words of different kinds: عَصا is the
    staff and the verb disobeyed, \u0646\u064E\u0639\u064E\u0645 is yes and cattle (\u0623\u064E\u0646\u06E1\u0639\u064E\u0670\u0645). They become one headword per
    kind (key#V, key#R, key#P)."""
    kinds: dict[str, set[str]] = defaultdict(set)
    for segments in corpus.values():
        for s in segments:
            if s.lemma and not s.affix:
                kinds[s.lemma].add(kind(s))
    return {lemma for lemma, found in kinds.items() if len(found) > 1}


def headword(segments: list[Segment], qul_lemma: str | None, mixed: set[str]) -> tuple[str | None, str | None]:
    """(headword key, root) for one word."""
    stems = [s for s in segments if not s.affix]
    for s in stems:
        if s.lemma:
            if s.lemma in SPLIT_BY_QUL and qul_lemma:
                return f"QUL:{qul_lemma}", s.root
            if s.lemma in mixed:
                return f"{s.lemma}#{kind(s)}", s.root
            return s.lemma, s.root
    for s in stems:
        if s.tag == "PRON":
            person = next((f for f in s.features[1:] if re.fullmatch(r"[123][MF]?[SDP]", f)), None)
            if person:
                return f"PRON:{person}", None
    return None, None


def build() -> tuple[bytes, list[dict]]:
    corpus = load_corpus()
    tokens, word_count, spellings, bare_spellings = load_quran()
    glosses = load_glosses()
    reviewed = load_tsv()

    lemma_db = open_sqlite(QUL / "word-lemma.db.zip")
    names = dict(lemma_db.execute("select id, text from lemmas"))
    qul_at = {tuple(map(int, loc.split(":"))): names[i]
              for i, loc in lemma_db.execute("select lemma_id, word_location from lemma_words")}
    root_db = open_sqlite(QUL / "word-root.db.zip")
    root_count = root_db.execute("select count(*) from roots").fetchone()[0]

    # Corpus word -> this app's raw token index, where the ayah's words line up one to one (all
    # but seven ayahs; see the design doc). Unaligned ayahs never supply a first occurrence.
    corpus_words_per_ayah = Counter((s, a) for (s, a, _w) in corpus)
    token_of: dict[tuple[int, int, int], int] = {}
    for key, raw in tokens.items():
        letter_indices = [i for i, t in enumerate(raw) if LETTER.search(t)]
        if len(letter_indices) == corpus_words_per_ayah[key]:
            for w, index in enumerate(letter_indices, 1):
                token_of[(key[0], key[1], w)] = index

    mixed = mixed_lemmas(corpus)
    count, uses, root_of, first, first_bare, first_same = Counter(), Counter(), {}, {}, {}, {}
    headword_skeleton = {key: skeleton(row[0]) for key, row in reviewed.items()}
    qul_spelling: dict[str, Counter] = defaultdict(Counter)
    gloss_votes: dict[str, Counter] = defaultdict(Counter)
    lemma_uses = Counter()
    for location in sorted(corpus):
        segments = corpus[location]
        qul_lemma = qul_at.get(location)
        key, root = headword(segments, qul_lemma, mixed)
        lemmas_here = {s.lemma for s in segments if not s.affix and s.lemma}
        for lemma in lemmas_here:
            lemma_uses[lemma] += 1
            # A second stem's lemma (مَا in مِمَّا) is a use of that word too. Split and mixed
            # lemmas count only where they head the word: their other headwords are other words.
            if lemma not in SPLIT_BY_QUL and lemma not in mixed and lemma != (key or ""):
                uses[lemma] += 1
        if key is None:
            continue
        count[key] += 1
        uses[key] += 1
        if root and key not in root_of:
            root_of[key] = root
        if qul_lemma and not key.startswith("PRON:"):
            qul_spelling[key][qul_lemma] += 1
        if key not in first and location in token_of:
            first[key] = (location[0], location[1], token_of[location])
        # The example a row opens: the first word spelled like the headword (قَالَ itself, not يَقُولُ
        # or فَقَالَ), else the first that stands alone, else the first in any form.
        if location in token_of and key not in first_same:
            here = (location[0], location[1], token_of[location])
            if skeleton(tokens[location[:2]][here[2]]) == headword_skeleton.get(key):
                first_same[key] = here
            elif len(segments) == 1 and key not in first_bare:
                first_bare[key] = here
        if len(segments) == 1 and location in token_of:
            row = glosses.get(location[:2], [])
            index = token_of[location]
            if index < len(row) and row[index]:
                gloss_votes[key][row[index]] += 1

    ranked = sorted(count, key=lambda k: (-uses[k], -count[k], k))[:LISTED]
    total = sum(1 for _ in corpus)

    missing = [k for k in ranked if k not in reviewed]
    if missing:
        if "--draft" in sys.argv:
            with DRAFT_TSV.open("w", encoding="utf-8") as handle:
                for k in missing:
                    spelling = (qul_spelling[k].most_common(1)[0][0] if qul_spelling[k]
                                else k.split(":", 1)[-1])
                    votes = " | ".join(f"{g} ({n})" for g, n in gloss_votes[k].most_common(3))
                    handle.write(f"{k}\t{uthmani(spelling)}\t{votes}\n")
            print(f"  wrote {len(missing)} draft rows to {DRAFT_TSV.relative_to(ROOT)}")
            raise SystemExit(0)
        raise SystemExit(f"{len(missing)} listed headwords have no reviewed row in {WORDS_TSV.name} "
                         f"(first: {missing[:5]}); run with --draft")

    entries = []
    running = 0
    for rank, key in enumerate(ranked, 1):
        arabic, meaning = reviewed[key]
        if key not in first:
            raise SystemExit(f"{key}: no occurrence in an aligned ayah")
        running += count[key]
        s, a, t = first_same.get(key) or first_bare.get(key) or first[key]
        entries.append({"rank": rank, "key": key, "arabic": arabic, "meaning": meaning,
                        "root": root_letters(root_of.get(key)), "count": count[key], "uses": uses[key],
                        "first": [s, a, t], "coverage": round(100 * running / total, 2)})

    def coverage(n: int) -> float:
        return round(100 * sum(count[k] for k in ranked[:n]) / total, 1)

    tajweed = Counter()
    for path in sorted(TAJWEED_DIR.glob("*.json")):
        for ayah in json.loads(path.read_text(encoding="utf-8")):
            for mark in ayah["annotations"]:
                tajweed[mark["rule"]] += 1

    lemma_count = len(lemma_uses)
    pack = {
        "v": 1,
        "source": f"Quranic Arabic Corpus morphology (mustafa0x/quran-morphology {QAC_COMMIT[:7]}); "
                  "spellings and roots from QUL; this app's Hafs text; meanings reviewed by hand",
        "totals": {
            "words": word_count,
            "corpusWords": total,
            "lemmas": lemma_count,
            "roots": root_count,
            "spellings": spellings,
            "bareSpellings": bare_spellings,
            "usedOnce": sum(1 for n in lemma_uses.values() if n == 1),
            "tajweedMarks": sum(tajweed.values()),
        },
        "milestones": [[n, coverage(n)] for n in (10, 50, 100, 200, 300, 500)],
        "tierSize": TIER_SIZE,
        # rank order: [key, arabic, meaning, root, count, uses, surah, ayah, token]. The key is the
        # corpus headword: what the app stores for a known or missed word, so it survives a rebuild
        # that reorders or respells the list.
        "words": [[e["key"], e["arabic"], e["meaning"], e["root"], e["count"], e["uses"], *e["first"]] for e in entries],
        "tajweed": [[rule, n] for rule, n in sorted(tajweed.items(), key=lambda item: (-item[1], item[0]))],
    }
    data = lzma.compress(json.dumps(pack, ensure_ascii=False, separators=(",", ":")).encode("utf-8"),
                         preset=9 | lzma.PRESET_EXTREME)
    return data, entries


def main() -> None:
    data, entries = build()
    if "--check" in sys.argv:
        shipped = json.loads(lzma.open(OUT).read())
        fresh = json.loads(lzma.decompress(data))
        if shipped != fresh:
            raise SystemExit("QuranVocabulary.json.xz is stale: rebuild it")
        print("  QuranVocabulary.json.xz matches a fresh build")
        return
    OUT.write_bytes(data)
    pack = json.loads(lzma.decompress(data))
    print(f"  wrote {OUT.relative_to(ROOT)} ({len(data):,} bytes): {len(entries)} words, "
          f"totals {pack['totals']}, milestones {pack['milestones']}")


if __name__ == "__main__":
    main()
