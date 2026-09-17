#!/usr/bin/env python3
"""Sukoon marks the way the app's own Uthmani text writes them.

Two codepoints both read as "sukoon", and this app's Quran text (KFGQPC) uses them for two
different things:

    U+06E1  SMALL HIGH DOTLESS HEAD OF KHAH   a real sukoon: the letter is a consonant with no
                                              vowel (يَتَفَطَّرۡنَ, إِلَيۡهِمۡ). The shape the mushaf prints.
    U+0652  ARABIC SUKUN                      a SILENT letter: written, not pronounced. The
                                              plural waw's alif (كَانُواْ), the waw of أُوْلَٰٓئِكَ,
                                              the yaa of وَمَلَإِيْهِۦ.

Quran.com's qiraat matrix, which `build_qiraat_variants.py` packs, does not keep the two apart:
its rows for surahs 1 to 18 write every sukoon as U+0652, and from surah 19 on the two are mixed
even inside one word (يَنْفَطِرۡنَ). Set beside the app's own ayah text in one sheet, the difference
shows. It also types a sukoon onto long vowels (يُشْرِكُوْنَ), which Uthmani orthography leaves bare.

`normalize_sukoon` makes a word follow the app's convention, and it is deliberately not
"replace U+0652 with U+06E1": that would turn every silent letter into a consonant. Each mark
is classified by the letter it sits on:

    a consonant      U+0652 -> U+06E1
    a silent letter  left exactly as it is
    a long vowel     the mark removed, whichever of the two it was

An alif is never a consonant, so its mark is never changed; that also leaves a sukoon typed onto
a long-vowel alif (وَلَاْ) alone, because the same shape is a real silent alif in سَلَٰسِلَاْ and
ثَمُودَاْ and only the word tells them apart. A waw or yaa is a consonant only in the diphthong
(يَوۡم, بَيۡت), and the diphthong needs a fatha on the letter before it; the rule looks for that
fatha through a silent or long-vowel alif (تَاْيۡـَٔسُ, مَحۡيَآيۡ) but never through one carrying
another Quranic mark (Qunbul's ا۬وْلَٰٓئِكَ eases the hamza with U+06EC, and the waw behind it is
the historical silent one). A waw after a damma is a long vowel unless the letter before it is
أ, which is the whole silent-waw family in the text; a yaa after a kasra is a long vowel unless
the letter before it is a word-internal إ (the silent-yaa family: وَمَلَإِيْهِۦ, أَفَإِيْن) or a
bare hamza (the sākin yaa of Qaloon's print, whose mark is the point). A letter carrying a
combining hamza (U+0654, U+0655; how some riwayah texts write ئ and أ) is a hamza, a consonant,
whatever letter sits under it. Anything the rule is not sure of stays as it was.

The guarantee, and how to check it:

    python3 Scripts/sukoon.py

It reads the app's own Hafs text (Resources/JSONs-Deprecated/Quran.json), 77,629 words that
already follow the convention, and demands two things of every word: that the rule changes
nothing (so no silent letter ever loses its mark), and that damaging the word the way the
matrix is damaged (every U+06E1 written as U+0652) and then applying the rule gives the
original back byte for byte. Both were zero failures when the rule was written (2026-09-16).
"""

from __future__ import annotations

import json
import pathlib
import sys

SUKUN = "ْ"
UTHMANI = "ۡ"
FATHA, DAMMA, KASRA = "َ", "ُ", "ِ"
MADDA = "ٓ"
HAMZA_ABOVE, HAMZA_BELOW = "ٔ", "ٕ"
ROUNDED_ZERO = "۟"
ALIF, WAW, YAA, ALIF_MAQSURA, ALIF_WASLA = "ا", "و", "ي", "ى", "ٱ"
HAMZA, ALIF_HAMZA_ABOVE, ALIF_HAMZA_BELOW = "ء", "أ", "إ"

# The alifs an eye reads as one letter; a sukoon on any of them is never a consonant's.
_ALIFS = (ALIF, ALIF_MAQSURA, ALIF_WASLA)
# What a silent or long-vowel alif may carry and still be looked through for the diphthong's
# fatha. Anything else on it (the eased hamza, a small letter) means it is not that alif.
_LOOK_THROUGH = (SUKUN, UTHMANI, MADDA, ROUNDED_ZERO)


def is_mark(c: str) -> bool:
    """A combining mark of Arabic script: tashkeel, the Quranic annotation range, tatweel."""
    o = ord(c)
    return (0x064B <= o <= 0x065F or o == 0x0670 or 0x06D6 <= o <= 0x06ED
            or o == 0x0640 or 0x08D3 <= o <= 0x08FF or 0x0610 <= o <= 0x061A)


def normalize_sukoon(word: str) -> str:
    """The word with its sukoon marks following the app's Uthmani text. See the module doc."""
    chars = list(word)
    for i, c in enumerate(chars):
        if c not in (SUKUN, UTHMANI):
            continue
        j = i - 1
        seat = []
        while j >= 0 and is_mark(chars[j]):
            seat.append(chars[j])
            j -= 1
        if j < 0:
            continue
        base = chars[j]
        if HAMZA_ABOVE in seat or HAMZA_BELOW in seat:
            chars[i] = UTHMANI
            continue
        if base in _ALIFS:
            continue
        if base in (WAW, YAA):
            if _fatha_before(chars, j):
                chars[i] = UTHMANI
            elif _long_vowel(chars, j):
                chars[i] = ""
            continue
        if c == SUKUN:
            chars[i] = UTHMANI
    return "".join(chars)


def _preceding(chars: list, j: int) -> tuple[int, list]:
    """The index of the base letter before chars[j] (or -1) and the marks between them."""
    k = j - 1
    marks = []
    while k >= 0 and is_mark(chars[k]):
        marks.append(chars[k])
        k -= 1
    return k, marks


def _fatha_before(chars: list, j: int) -> bool:
    """Whether the letter before chars[j] carries a fatha, looking through a bare alif."""
    k, marks = _preceding(chars, j)
    if FATHA in marks:
        return True
    if k < 0 or chars[k] != ALIF or any(m in (FATHA, DAMMA, KASRA) for m in marks):
        return False
    if any(m not in _LOOK_THROUGH for m in marks):
        return False
    k, marks = _preceding(chars, k)
    return FATHA in marks


def _long_vowel(chars: list, j: int) -> bool:
    """Whether the waw or yaa at chars[j] is a long vowel rather than a silent letter."""
    k, marks = _preceding(chars, j)
    if k < 0:
        return False
    prev = chars[k]
    if chars[j] == WAW:
        return DAMMA in marks and prev != ALIF_HAMZA_ABOVE
    if KASRA not in marks:
        return False
    if prev == ALIF_HAMZA_BELOW:
        # Word-initial إِي is always the long vowel (إِيمَٰن); inside a word it is the silent family.
        return k == 0 or chars[k - 1].isspace()
    return prev != HAMZA


def main() -> None:
    """The proof: the app's own Hafs text must survive the rule untouched and round-trip."""
    root = pathlib.Path(__file__).resolve().parent.parent
    quran = json.loads((root / "Resources" / "JSONs-Deprecated" / "Quran.json").read_text(encoding="utf-8"))
    words = changed = failed = 0
    for surah in quran:
        for ayah in surah["ayahs"]:
            for w in ayah["textArabic"].split():
                words += 1
                if normalize_sukoon(w) != w:
                    changed += 1
                    print(f"  changed  {surah['id']}:{ayah['id']}  {w} -> {normalize_sukoon(w)}")
                damaged = w.replace(UTHMANI, SUKUN)
                if normalize_sukoon(damaged) != w:
                    failed += 1
                    print(f"  no round trip  {surah['id']}:{ayah['id']}  {w} -> {normalize_sukoon(damaged)}")
    print(f"{words:,} words: {changed} changed by the rule, {failed} failed to round-trip")
    if changed or failed:
        raise SystemExit("ERROR: the sukoon rule does not preserve the app's own Hafs text")
    stray = riwayah_strays(root)
    print(f"{len(RIWAYAH_TEXTS(root))} riwayah texts: {len(stray)} words the rule would change")
    for name, where, word, fixed in stray:
        print(f"  {name}  {where}  {word} -> {fixed}")
    if stray:
        raise SystemExit("ERROR: a riwayah text carries a sukoon outside the convention - run Scripts/patch_riwayah_sukoon.py")


def RIWAYAH_TEXTS(root: pathlib.Path) -> list[pathlib.Path]:
    """The 19 other riwayah texts as the app ships them: the 12 beta deflates behind
    qiraah.solidpack and the 7 KFGQPC texts behind qiraat.qpk (their JSON sources)."""
    return sorted((root / "Resources" / "Data" / "Quran").glob("Qiraah*.json.deflate")) + \
        sorted((root / "Resources" / "JSONs-Deprecated" / "Qiraat").glob("Qiraah*.json"))


def riwayah_text(path: pathlib.Path) -> dict:
    """{surah: [{"id", "text"}, ...]} whichever wrapping the file uses."""
    import zlib
    raw = path.read_bytes()
    if path.name.endswith(".deflate"):
        raw = zlib.decompressobj(-zlib.MAX_WBITS).decompress(raw)
    return json.loads(raw)


def riwayah_strays(root: pathlib.Path) -> list[tuple[str, str, str, str]]:
    """Every word of the 19 riwayah texts the rule would change: (file, surah:ayah, word, fixed).
    Their notation is the app's, so this is 0 once Scripts/patch_riwayah_sukoon.py has run; the
    stray the texts carried was فَٱدَّٰرَأْتُمۡ (2:71/72) with U+0652 on the hamza, one word each."""
    out = []
    for path in RIWAYAH_TEXTS(root):
        for surah, ayahs in riwayah_text(path).items():
            for ayah in ayahs:
                for w in ayah["text"].split():
                    fixed = normalize_sukoon(w)
                    if fixed != w:
                        out.append((path.name, f"{surah}:{ayah['id']}", w, fixed))
    return out


if __name__ == "__main__":
    main()
