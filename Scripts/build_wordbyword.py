#!/usr/bin/env python3
"""Build Resources/Data/Quran/WordByWord.json.xz - the per-word English gloss and
Latin transliteration pack that backs "tap a word" in the reader.

WHY A BUILD-TIME ALIGNMENT AND NOT A RUNTIME ONE
------------------------------------------------
The upstream word-by-word corpus (Quran.com's QDC API, mirrored in the sibling
Tilawa app at assets/quran/word-by-word-en.json) tokenizes a handful of ayahs
differently than this app's Hafs text does:

  * 199 ayahs: the rub-el-hizb mark (U+06DE) is a token of its own here, but is
    glued onto the following word upstream ("۞ إِنَّ").
  * 3 ayahs: upstream splits a word this app keeps joined - 15:7 لَّوۡمَا,
    27:20 مَالِيَ, 36:22 وَمَالِيَ.
  * 3 ayahs: the reverse - this app splits what upstream keeps as one word.

Resolving that at runtime would mean shipping the Arabic of every word (~2 MB)
and re-deriving the mapping on every ayah render, with a silent-wrong-gloss
failure mode. Instead the alignment happens HERE, once, and the pack stores one
gloss per token IN THIS APP'S OWN TOKEN ORDER. The reader then splits the ayah
on whitespace and indexes straight in - no matching, no normalization, no drift.

A token that has no gloss of its own (the ۞ mark; the tail of a word upstream
merged) stores "" and the reader shows no card for it.

OUTPUT FORMAT
-------------
xz (what iPhone/Quran/WordByWord.swift's inflate and
Apple's COMPRESSION_ZLIB expect, matching the Qiraah*/Tajweed* payloads) over:

    {"v": 2,
     "en": {"1": [["In (the) name", "(of) Allah", ...], ...], ..., "114": [...]},
     "tr": {"1": [["bis'mi", "l-lahi", ...], ...], ..., "114": [...]}}

  layer -> surah id (string) -> ayahs in id order -> one entry per token.

Both layers are aligned by the SAME walk against the SAME app tokens, so index n
means the same word in both - the reader can show either or both without a second
lookup. Version 1 packs (English only, surah ids at the top level) are still read
by the app; this builder only ever writes version 2.

RUN
---
    python3 Scripts/build_wordbyword.py [path/to/word-by-word-en.json] [path/to/word-by-word-translit.json]

Defaults to ../Tilawa/assets/quran/word-by-word-en.json and, beside it,
word-by-word-translit.json (fetch that one with Scripts/fetch_wordbyword.py).
Verification is part of the build: every one of the 6236 ayahs must align
token-for-token in BOTH layers or the script exits non-zero and writes nothing.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys
import lzma


def xz_compress(body: bytes) -> bytes:
    """xz stream, preset 9e, dictionary no larger than the payload needs (the app decodes it with
    Apple's Compression framework, COMPRESSION_LZMA, which reads the xz container directly)."""
    dict_size = 1 << 16
    while dict_size < len(body) and dict_size < (1 << 26):
        dict_size <<= 1
    filters = [{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME, "dict_size": dict_size}]
    return lzma.compress(body, format=lzma.FORMAT_XZ, check=lzma.CHECK_CRC32, filters=filters)

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
OUT = ROOT / "Resources" / "Data" / "Quran" / "WordByWord.json.xz"
DEFAULT_SOURCE = ROOT.parent / "Tilawa" / "assets" / "quran" / "word-by-word-en.json"
DEFAULT_TRANSLIT_SOURCE = DEFAULT_SOURCE.with_name("word-by-word-translit.json")

# Everything that carries no consonantal identity: harakat, sukun/madda variants,
# superscript alef, the small high marks (waqf signs, U+06D6-U+06ED), tatweel, and
# the rub-el-hizb / sajdah ornaments. Stripped from BOTH sides before comparing, so
# the two corpora's differing orthography (U+0652 sukun vs U+06E1 small high sukun,
# hamza seat spellings) can never split an otherwise identical word.
_STRIP = re.compile(
    "["
    "ؐ-ؚ"      # honorifics
    "ً-ٟ"      # tanween, harakat, sukun, shadda, madda above
    "ٰ"             # superscript alef
    "ۖ-ۭ"      # small high marks, waqf signs, rub-el-hizb (06DE), sajdah (06E9)
    "ـ"             # tatweel
    "​-‏"      # zero-width / bidi marks
    "ﹰ-ﹿ"      # presentation-form diacritics
    "\\s"
    "]"
)

# Orthographic variants that differ between the two corpora but are the same letter.
# The three weak letters collapse into ONE class rather than folding pairwise: the
# corpora disagree in both directions - upstream writes فِى where this app writes
# فِي (ى~ي), and writes افْتَرَاهُ where this app writes ٱفۡتَرَىٰهُ (ى~ا after the
# superscript alif is stripped). Any pairwise rule fixes one and breaks the other.
# Over-merging is harmless here: this is sequence alignment between two spellings
# of the SAME ayah walked in order, not a dictionary lookup.
_FOLD = str.maketrans({
    "أ": "ا",  # أ -> ا
    "إ": "ا",  # إ -> ا
    "آ": "ا",  # آ -> ا
    "ٱ": "ا",  # ٱ -> ا
    "ى": "ا",  # ى -> ا
    "ی": "ا",  # ی -> ا
    "ي": "ا",  # ي -> ا
    "ة": "ه",  # ة -> ه
    "ؤ": "و",  # ؤ -> و
    "ئ": "ا",  # ئ -> ا
    "ء": "",        # bare hamza: seat-only difference between corpora
})

# Arabic-Indic digits. The upstream corpus occasionally leaks an ayah-number word
# past its own char_type filter (2:181 carries a trailing "١٨١"); this app's text
# never contains the number - the reader appends it as a styled suffix - so those
# words are dropped before aligning rather than being matched against nothing.
_DIGITS = re.compile("^[٠-٩0-9]+$")

# How many tokens/words a single counterpart may span. The real data never needs
# more than 2; 3 is headroom that still keeps the greedy walk from wandering.
MAX_SPAN = 3


def norm(text: str) -> str:
    """Consonantal skeleton - the only thing the two corpora agree on exactly."""
    return _STRIP.sub("", text).translate(_FOLD)


def tokens_of(ayah_text: str) -> list[str]:
    """Exactly how the app splits an ayah for display - plain whitespace."""
    return [t for t in re.split(r"\s+", ayah_text.strip()) if t]


def align(tokens: list[str], words: list[dict], key: str = "e") -> list[str] | None:
    """One value per token, or None when the two sides cannot be reconciled.

    `key` picks the layer being carried across: "e" for the English gloss, "t"
    for the transliteration. The walk itself only ever looks at "a" (the upstream
    Arabic), so both layers align identically as long as their word lists do.

    Greedy two-pointer with bounded lookahead in both directions: a token may
    absorb several upstream words (their values join), and several tokens may
    share one upstream word (the first takes the value, the rest take "").
    """
    out: list[str] = []
    i = j = 0

    while i < len(tokens):
        tok = norm(tokens[i])

        # Ornament-only token (۞, a lone waqf mark): no word, no gloss.
        if not tok:
            out.append("")
            i += 1
            continue

        if j >= len(words):
            return None

        if tok == norm(words[j]["a"]):
            out.append(words[j][key])
            i += 1
            j += 1
            continue

        # One token spanning several upstream words.
        merged = None
        for span in range(2, MAX_SPAN + 1):
            if j + span > len(words):
                break
            if tok == norm("".join(w["a"] for w in words[j:j + span])):
                merged = span
                break
        if merged:
            joined = [w[key] for w in words[j:j + merged] if w[key]]
            out.append(" ".join(joined))
            i += 1
            j += merged
            continue

        # One upstream word spanning several tokens.
        split = None
        for span in range(2, MAX_SPAN + 1):
            if i + span > len(tokens):
                break
            if norm("".join(tokens[i:i + span])) == norm(words[j]["a"]):
                split = span
                break
        if split:
            out.append(words[j][key])
            out.extend([""] * (split - 1))
            i += split
            j += 1
            continue

        return None

    # Every upstream word must have been consumed; a leftover means the walk
    # drifted and the glosses after it would be off by one.
    return out if j == len(words) else None


def build_layer(quran: list, source: dict, key: str, label: str) -> tuple[dict, list[str], int, int]:
    """Align one layer against the app's tokens. Returns (packed, failures, tokens, filled)."""
    packed: dict[str, list[list[str]]] = {}
    failures: list[str] = []
    total_tokens = filled = 0

    for surah in quran:
        rows: list[list[str]] = []
        for ayah in surah["ayahs"]:
            ref = f"{surah['id']}:{ayah['id']}"
            toks = tokens_of(ayah["textArabic"])
            words = source.get(ref)
            if words is None:
                failures.append(f"{label} {ref}: absent from source")
                rows.append([""] * len(toks))
                continue
            words = [w for w in words if norm(w["a"]) and not _DIGITS.match(norm(w["a"]))]
            aligned = align(toks, words, key)
            if aligned is None or len(aligned) != len(toks):
                failures.append(f"{label} {ref}: {len(toks)} tokens vs {len(words)} words - no alignment")
                rows.append([""] * len(toks))
                continue
            total_tokens += len(aligned)
            filled += sum(1 for value in aligned if value)
            rows.append(aligned)
        packed[str(surah["id"])] = rows

    return packed, failures, total_tokens, filled


def main() -> None:
    source = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SOURCE
    translit_source = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_TRANSLIT_SOURCE
    if not source.exists():
        raise SystemExit(f"word-by-word source not found: {source}")
    if not translit_source.exists():
        raise SystemExit(
            f"transliteration source not found: {translit_source}\n"
            "Fetch it once with: python3 Scripts/fetch_wordbyword.py"
        )

    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    english_source = json.loads(source.read_text(encoding="utf-8"))
    latin_source = json.loads(translit_source.read_text(encoding="utf-8"))

    english, en_failures, tokens, glossed = build_layer(quran, english_source, "e", "english")
    latin, tr_failures, _, transliterated = build_layer(quran, latin_source, "t", "translit")

    failures = en_failures + tr_failures
    if failures:
        print(f"FAILED: {len(failures)} ayahs did not align", file=sys.stderr)
        for line in failures[:20]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)

    body = json.dumps({"v": 2, "en": english, "tr": latin},
                      ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    blob = xz_compress(body)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(blob)

    ayahs = sum(len(surah["ayahs"]) for surah in quran)
    print(f"{ayahs} ayahs aligned in both layers, {tokens:,} tokens "
          f"({glossed:,} glossed, {transliterated:,} transliterated)")
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} xz")


if __name__ == "__main__":
    main()
