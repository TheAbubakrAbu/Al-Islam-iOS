#!/usr/bin/env python3
"""Transliterate a fully vocalised Arabic name into plain English letters, the way the app's shelf
writes its titles ("Sahih al-Bukhari", "Abu Dawud", "at-Tirmidhi"): no macrons or dots, the hamza and
the 'ayn as an apostrophe inside a word and dropped at its start, the case ending dropped (the pausal
form), the article "al-" assimilated to the sun letters ("az-Zuhri", "ar-Rahman").

Used by Scripts/build_hadith_chains.py for the narrators' English names (Abu, 2026-10-31: "would be
fire if we can also translate the chain for English"), shipped in HadithNarrators.qpk. The names it
reads carry every short vowel, so the rules below are enough for the names of the shelf; a handful
of spellings no rule can know (the silent waw of عمرو, the long vowels of a few Prophets' names) are
spelt out in OVERRIDES by their unvocalised skeleton.

    python3 Scripts/arabic_translit.py "عَبْدِ اللَّهِ بْنِ مَسْعُودٍ"     # prints the transliteration
"""
import sys
import unicodedata

FATHA, DAMMA, KASRA = 'َ', 'ُ', 'ِ'
FATHATAN, DAMMATAN, KASRATAN = 'ً', 'ٌ', 'ٍ'
SHADDA, SUKUN, DAGGER = 'ّ', 'ْ', 'ٰ'
SHORT = {FATHA: 'a', DAMMA: 'u', KASRA: 'i', FATHATAN: 'a', DAMMATAN: 'u', KASRATAN: 'i'}
TANWEEN = {FATHATAN, DAMMATAN, KASRATAN}
MARKS = set(SHORT) | {SHADDA, SUKUN, DAGGER}

ALEF, ALEF_WASL, ALEF_MAQSURAH, TA_MARBUTA, WAW, YA = 'ا', 'ٱ', 'ى', 'ة', 'و', 'ي'
HAMZAS = {'ء': None, 'أ': 'a', 'إ': 'i', 'آ': 'a', 'ؤ': None, 'ئ': None}
CONSONANTS = {
    'ب': 'b', 'ت': 't', 'ث': 'th', 'ج': 'j', 'ح': 'h', 'خ': 'kh', 'د': 'd', 'ذ': 'dh', 'ر': 'r', 'ز': 'z',
    'س': 's', 'ش': 'sh', 'ص': 's', 'ض': 'd', 'ط': 't', 'ظ': 'z', 'ع': "'", 'غ': 'gh', 'ف': 'f', 'ق': 'q',
    'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n', 'ه': 'h', 'و': 'w', 'ي': 'y',
}
SUN = set('تثدذرزسشصضطظلن')

# Whole words by their skeleton (marks and hamza seats set aside): the words of a name that have one
# English spelling whatever case the sentence puts them in.
WORDS = {
    'بن': 'ibn', 'ابن': 'ibn', 'بنت': 'bint', 'ابنه': 'ibnah',
    'ابو': 'Abu', 'ابي': 'Abu', 'ابا': 'Abu',
    'ام': 'Umm', 'الله': 'Allah', 'مولي': 'mawla', 'عبد': 'Abd',
}
# Spellings the rules cannot reach: the silent waw of 'Amr, the long vowel the rasm leaves out in a
# few names of Prophets, the English the shelf's readers know.
OVERRIDES = {
    'عمرو': 'Amr', 'داود': 'Dawud', 'داوود': 'Dawud', 'طاوس': 'Tawus', 'موسي': 'Musa', 'عيسي': 'Isa',
    'يحيي': 'Yahya', 'اسماعيل': "Isma'il", 'ابراهيم': 'Ibrahim', 'اسحاق': 'Ishaq', 'اسحق': 'Ishaq',
    'سليمان': 'Sulaiman', 'هارون': 'Harun', 'الرحمن': 'ar-Rahman', 'عائشه': "A'ishah", 'الزهري': 'az-Zuhri',
    'المؤمنين': "al-Mu'minin", 'عبيد': 'Ubaid', 'عبيده': 'Ubaidah', 'الخطاب': 'al-Khattab', 'النبي': 'an-Nabi',
    'رسول': 'Rasul', 'هريره': 'Hurairah',
}


def skeleton(word):
    """The word without its marks, every hamza seat and alef read as the bare letter, ى as ي, ة as ه."""
    out = []
    for ch in word:
        if ch in MARKS:
            continue
        if ch in ('أ', 'إ', 'آ', 'ٱ'):
            ch = 'ا'
        elif ch == 'ى':
            ch = 'ي'
        elif ch == 'ة':
            ch = 'ه'
        out.append(ch)
    return ''.join(out)


def units(word):
    """[(letter, marks)]: each letter with the marks written on it."""
    out = []
    for ch in word:
        if ch in MARKS and out:
            out[-1][1].append(ch)
        elif ch not in MARKS:
            out.append([ch, []])
    return [(letter, set(marks)) for letter, marks in out]


def vowel_of(marks):
    for mark in marks:
        if mark in SHORT:
            return SHORT[mark]
    return None


def capitalise(text):
    """The first letter upper-case, an apostrophe before it left alone ("'Amr" stays "'Amr")."""
    for index, ch in enumerate(text):
        if ch.isalpha():
            return text[:index] + ch.upper() + text[index + 1:]
    return text


def transliterate_word(word, after_ibn=False, first=False):
    sk = skeleton(word)
    if sk in OVERRIDES:
        return OVERRIDES[sk]
    if sk in WORDS:
        out = WORDS[sk]
        if out == 'Abu' and after_ibn:
            out = 'Abi'
        if out in ('ibn', 'bint', 'mawla') and first:
            out = capitalise(out)
        return out
    parts = units(word)
    if not parts:
        return ''
    # The last letter's case ending is not spoken: the vowel and the tanween go, and the alef the
    # tanween of the accusative is written on ("أَنَسًا" is Anas).
    if len(parts) > 1 and parts[-1][0] == ALEF and parts[-2][1] & {FATHATAN}:
        parts = parts[:-1]
    last_letter, last_marks = parts[-1]
    parts[-1] = (last_letter, {m for m in last_marks if m not in SHORT})

    prefix = ''
    start = 0
    # The article: alef, lam without a vowel, and more letters after them.
    if len(parts) > 2 and parts[0][0] in (ALEF, ALEF_WASL) and parts[1][0] == 'ل' and not vowel_of(parts[1][1]):
        letter, marks = parts[2]
        if letter in SUN and SHADDA in marks:
            prefix = 'a' + CONSONANTS[letter] + '-'
            parts[2] = (letter, marks - {SHADDA})
        else:
            prefix = 'al-'
        start = 2

    out = []
    previous_vowel = None
    for index in range(start, len(parts)):
        letter, marks = parts[index]
        vowel = vowel_of(marks)
        is_first = index == start
        is_last = index == len(parts) - 1
        doubled = SHADDA in marks
        if letter in HAMZAS:
            # A hamza opens a word with its vowel alone; inside a word it is heard as a stop.
            seat = HAMZAS[letter]
            if is_first:
                out.append(vowel or seat or 'a')
                if letter == 'آ' and out[-1] == 'a':
                    pass
            else:
                out.append("'")
                if letter == 'آ':
                    out.append('a')
                elif vowel:
                    out.append(vowel)
            previous_vowel = out[-1] if out[-1] in 'aiu' else None
            continue
        if letter in (ALEF, ALEF_WASL):
            if is_first:
                out.append(vowel or 'i')
                previous_vowel = out[-1]
            else:
                # The long a: the fatha before it already said it.
                if previous_vowel != 'a':
                    out.append('a')
                previous_vowel = 'a'
            continue
        if letter == ALEF_MAQSURAH:
            if previous_vowel != 'a':
                out.append('a')
            previous_vowel = 'a'
            continue
        if letter == TA_MARBUTA:
            # The pausal "ah": the fatha before it is the a ("Salamah", never "Salamaah").
            if is_last:
                out.append('h' if previous_vowel == 'a' else 'ah')
            else:
                out.append('t' + (vowel or ''))
            previous_vowel = vowel
            continue
        if DAGGER in marks:
            vowel = None
        if letter == WAW and not vowel and not doubled:
            # A long u after a damma, a diphthong after a fatha, a consonant otherwise.
            if previous_vowel == 'u':
                pass
            elif previous_vowel == 'a':
                out.append('w')
            else:
                out.append('w')
            previous_vowel = None if previous_vowel != 'u' else 'u'
            continue
        if letter == YA and not vowel and not doubled:
            if previous_vowel == 'i':
                pass
            elif previous_vowel == 'a':
                out.append('i')
            else:
                out.append('y')
            previous_vowel = 'i' if previous_vowel in ('i', 'a') else None
            continue
        if letter == YA and doubled and is_last:
            # The nisba's doubled ya ("الزهري", "الأنصاري") and the final of 'Ali: one long i.
            if previous_vowel != 'i':
                out.append('i')
            previous_vowel = 'i'
            continue
        consonant = CONSONANTS.get(letter, '')
        if not consonant:
            continue
        if is_first and consonant == "'":
            # The 'ayn that opens a word is not written: Umar, Ali, Abdullah, Uthman.
            consonant = ''
        out.append(consonant * (2 if doubled and consonant else 1))
        if DAGGER in marks:
            out.append('a')
            previous_vowel = 'a'
        elif vowel:
            out.append(vowel)
            previous_vowel = vowel
        else:
            previous_vowel = None
    body = ''.join(out)
    return prefix + capitalise(body) if prefix else capitalise(body)


def transliterate(name):
    """The whole name, word by word: "عَبْدِ اللَّهِ بْنِ مَسْعُودٍ" is "Abdullah ibn Mas'ud"."""
    words = name.split()
    out = []
    index = 0
    while index < len(words):
        word = words[index]
        sk = skeleton(word)
        after_ibn = bool(out) and out[-1].lower() in ('ibn', 'bint')
        if sk in ('عبد', 'عبيد') and index + 1 < len(words):
            following = skeleton(words[index + 1])
            if following == 'الله':
                out.append('Abdullah' if sk == 'عبد' else 'Ubaidullah')
                index += 2
                continue
            if sk == 'عبد' and following.startswith('ال'):
                out.append('Abd')
                out.append(transliterate_word(words[index + 1]))
                index += 2
                continue
        out.append(transliterate_word(word, after_ibn=after_ibn, first=not out))
        index += 1
    return ' '.join(part for part in out if part)


if __name__ == '__main__':
    for argument in sys.argv[1:]:
        print(transliterate(argument))
