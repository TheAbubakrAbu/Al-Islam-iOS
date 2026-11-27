"""Long vowels for a recitation line, read off its own Arabic (or a macron transliteration).

The line is aligned to a phonetic stream of the source (a global alignment that lets the source run on
past either end of the line), and each Latin vowel that lands on a long vowel of the source is marked.
"""
import re

FATHA, DAMMA, KASRA = 'َ', 'ُ', 'ِ'
FATHATAN, DAMMATAN, KASRATAN = 'ً', 'ٌ', 'ٍ'
SUKUN, SHADDA, DAGGER = 'ْ', 'ّ', 'ٰ'
SMALL_WAW, SMALL_YAA = 'ۥ', 'ۦ'
MADDA = 'ٓ'

# ح ص ط ض ظ are their own symbols (Ḥ Ṣ Ṭ P Z), so a line can write them as H S T D Z
CONS = {'ب': 'b', 'ت': 't', 'ث': 'T', 'ج': 'j', 'ح': 'Ḥ', 'خ': 'K', 'د': 'd', 'ذ': 'D', 'ر': 'r', 'ز': 'z',
        'س': 's', 'ش': 'S', 'ص': 'Ṣ', 'ض': 'P', 'ط': 'Ṭ', 'ظ': 'Z', 'ع': '‘', 'غ': 'G', 'ف': 'f', 'ق': 'q',
        'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n', 'ه': 'h', 'و': 'w', 'ي': 'y', 'ة': 'H',
        'ء': '’', 'أ': '’', 'إ': '’', 'ؤ': '’', 'ئ': '’', 'آ': '’', 'ٱ': '', 'ا': '', 'ى': ''}
VOWEL = {FATHA: 'a', DAMMA: 'u', KASRA: 'i', FATHATAN: 'a', DAMMATAN: 'u', KASRATAN: 'i'}
LONG = {'a': 'ā', 'i': 'ī', 'u': 'ū'}


def _letters(word):
    """[(base letter, set of marks)]"""
    # an alif maqsurah inside a word is a yaa written the Egyptian way (شَىْءٍ, عَلَىْكَ)
    word = re.sub('ى(?=[\u0621-\u064A])', 'ي', word)
    out = []
    for ch in word:
        if 'ً' <= ch <= 'ٟ' or ch in (DAGGER, SMALL_WAW, SMALL_YAA, MADDA) or 'ۖ' <= ch <= 'ۭ':
            if out:
                out[-1][1].append(ch)
        elif ch == 'ـ':
            continue
        elif ch in CONS:
            out.append((ch, []))
    return out


PROCLITIC = set('وفبكل')
# words the script writes without the alif they are read with (hadha, ilah, dhalika, lakin): the letter
# after which the alif is read, counted in letters from 0
HIDDEN_ALIF = {'هذا': [0], 'هذه': [0], 'هذان': [0], 'هؤلاء': [0], 'ذلك': [0], 'ذلكم': [0], 'لكن': [0],
               'إله': [1], 'اله': [1], 'إلها': [1], 'الرحمن': [4], 'رحمن': [2], 'السموات': [3, 4], 'سموات': [1, 2],
               'أولئك': [2], 'كذلك': [1], 'لهذا': [1], 'بهذا': [1], 'وهذا': [1], 'فذلك': [1], 'وذلك': [1],
               'إسحق': [3], 'وإله': [2], 'وإلهكم': [2], 'إلهكم': [1], 'إلهنا': [1]}
_HARAKAT = re.compile('[ً-ٰٟۖ-ۭـ]')


def _restore_alif(word):
    bare = _HARAKAT.sub('', word)
    targets = list(HIDDEN_ALIF.get(bare, []))
    if not targets or DAGGER in word:
        return word
    res, li = [], -1
    for i, ch in enumerate(word):
        res.append(ch)
        if not _HARAKAT.match(ch):
            li += 1
        nxt = word[i + 1] if i + 1 < len(word) else ''
        if li in targets and (not nxt or not _HARAKAT.match(nxt)):
            res.append(DAGGER)
            targets.remove(li)
    return ''.join(res)


def arabic_stream(text):
    """Symbols for a vocalized (or partly vocalized) Arabic text, one list per word.

    Symbols: consonant classes (b t T j h K d D r z s S P Z ‘ G f q k l m n w y H ’ L), vowels a i u,
    long vowels ā ī ū, the ambiguous A W Y (a bare alif/waw/yaa after an unvowelled letter: long vowel
    or nothing / consonant), and O (an opening vowel that may or may not be said: hamzat al-wasl)."""
    words = []
    for w in re.findall(r'[ء-ٰٟ-ۭـ]+', text):
        L = _letters(_restore_alif(w))
        syms = []
        prev_vowel = None          # the vowel on the previous letter: 'a' 'i' 'u', '' (sukun), None (bare)
        for idx, (ch, marks) in enumerate(L):
            vowel = next((VOWEL[m] for m in marks if m in VOWEL), None)
            tanwin = any(m in (FATHATAN, DAMMATAN, KASRATAN) for m in marks)
            sukun = SUKUN in marks
            shadda = SHADDA in marks
            dagger = DAGGER in marks
            start = idx == 0
            if ch == 'ا' and idx == 1 and L[0][0] in PROCLITIC and not shadda and (
                    idx + 1 < len(L) and (SUKUN in L[idx + 1][1] or SHADDA in L[idx + 1][1]
                                          or not any(m in VOWEL for m in L[idx + 1][1]))):
                syms.append('O'); prev_vowel = None; continue          # wa-l, fa-ghfir: the hamzat al-wasl
            if ch == 'ا' and not start and FATHATAN in marks:
                syms += ['a', 'n']; prev_vowel = 'a'; continue          # خيراً: the tanween written on its seat
            if ch == 'ا' and not start and vowel == 'a' and prev_vowel is None:
                syms.append('ā'); prev_vowel = 'ā'; continue            # لاَ: the fatha written on the alif
            if ch in ('ا', 'ى') and not vowel and not shadda:
                if start:
                    syms.append('O')
                elif idx == len(L) - 1 and syms and syms[-1] == 'w' and prev_vowel in ('u', None):
                    pass                                  # the silent alif after the plural waw
                elif syms and syms[-1] == 'n' and len(syms) >= 2 and syms[-2] == 'a' and L[idx - 1][1] and FATHATAN in L[idx - 1][1]:
                    pass                                  # the seat of a fathatan
                elif prev_vowel == 'a' and syms and syms[-1] == 'a':
                    syms[-1] = 'ā'
                elif prev_vowel is None:
                    syms.append('A')
                elif dagger:
                    syms.append('ā')
                prev_vowel = 'ā'
                continue
            if ch == 'ٱ':
                syms.append('O'); prev_vowel = None; continue
            if ch == 'آ':
                syms += ['’', 'ā']; prev_vowel = 'ā'; continue
            before_alif = idx + 1 < len(L) and L[idx + 1][0] in ('ا', 'ى')
            if ch in ('و', 'ي') and not vowel and not shadda and not start and not before_alif:
                short, long_ = ('u', 'ū') if ch == 'و' else ('i', 'ī')
                if prev_vowel == short and syms and syms[-1] == short:
                    syms[-1] = long_; prev_vowel = long_; continue
                if (prev_vowel is None or prev_vowel in ('ā', 'ī', 'ū')) and not sukun:
                    syms.append('W' if ch == 'و' else 'Y'); prev_vowel = long_; continue   # داود, unvowelled
            sym = CONS[ch]
            if idx == 1 and sym == 'l' and syms[:1] == ['O']:
                sym = 'L'                                  # the article's lam (silent before a sun letter)
            elif idx >= 2 and sym == 'l' and syms[-1:] == ['O'] and len(syms) >= 2:
                sym = 'L'                                  # wa-l, bi-l, fa-l, ka-l
            if sym:
                syms.append(sym)
                if shadda:
                    syms.append(sym)
            if dagger and not vowel:
                syms.append('ā')
            elif vowel:
                syms.append(LONG[vowel] if dagger else vowel)
                if tanwin:
                    syms.append('n')
            if SMALL_WAW in marks and vowel == 'u':
                syms[-1] = 'ū'
            if SMALL_YAA in marks and vowel == 'i':
                syms[-1] = 'ī'
            prev_vowel = (LONG[vowel] if dagger else vowel) if vowel else ('' if (sukun or shadda) else None)
            if dagger and not vowel:
                prev_vowel = 'ā'
        words.append(syms)
    # a long vowel that ends a word is written single there (Rabbana, inni) and said short before the next
    # word's hamzat al-wasl (fid-dunya), so it is never marked long
    for w in words:
        if w and w[-1] in FINAL_SHORT:
            w[-1] = FINAL_SHORT[w[-1]]
    return words


FINAL_SHORT = {'ā': 'a', 'ī': 'i', 'ū': 'u', 'A': 'a', 'W': 'w~', 'Y': 'y~'}


MACRON_CONS = str.maketrans({'ḥ': 'Ḥ', 'ṣ': 'Ṣ', 'ḍ': 'P', 'ṭ': 'Ṭ', 'ẓ': 'Z', 'ʿ': '‘', 'ʾ': '’'})


def macron_stream(words):
    """Symbols for a macron transliteration (the Quran tab's word by word: 'l-raḥmāni', 'māliki')."""
    out = []
    for w in words:
        w = w.lower().translate(MACRON_CONS)
        # the Uthmani script writes these alifs as a waw; the word by word lost their length
        w = re.sub(r'(s|z|h|n|gh|mishk)alat', lambda m: m.group(1) + 'alāt', w)
        syms = []
        i = 0
        while i < len(w):
            two = w[i:i + 2]
            if two in ('th', 'kh', 'dh', 'sh', 'gh'):
                syms.append({'th': 'T', 'kh': 'K', 'dh': 'D', 'sh': 'S', 'gh': 'G'}[two]); i += 2; continue
            ch = w[i]
            if ch in 'aiuāīū':
                syms.append(ch)
            elif ch == "'":
                syms.append('’?')
            elif ch == '-':
                pass
            elif ch.isalpha() or ch in '‘’P':
                syms.append(ch)
            i += 1
        out.append(syms)
    for w in out:
        if w and w[-1] in FINAL_SHORT:
            w[-1] = FINAL_SHORT[w[-1]]
    return out


def latin_units(text):
    """[(symbol, index of its first char in text)] for a Latin line; punctuation and spaces skipped."""
    out = []
    low = text.lower()
    i = 0
    while i < len(low):
        two = low[i:i + 2]
        if two in ('th', 'kh', 'dh', 'sh', 'gh'):
            out.append(({'th': 'T', 'kh': 'K', 'dh': 'D', 'sh': 'S', 'gh': 'G'}[two], i)); i += 2; continue
        ch = low[i]
        if ch in 'aiueo':
            out.append(({'e': 'i', 'o': 'u'}.get(ch, ch), i))
        elif ch in '‘’':
            out.append((ch, i))
        elif ch.isalpha():
            out.append((ch, i))
        i += 1
    return out


VOWELS = set('aiu')
# a Latin letter and the source symbol it writes exactly (the heavy letters, and a waw or yaa read as one)
SAME_LETTER = {('w', 'W'), ('y', 'Y'), ('h', 'Ḥ'), ('s', 'Ṣ'), ('t', 'Ṭ'), ('d', 'P'), ('z', 'Z')}
# the source symbols written with a capital: ح ص ط ض ظ
HEAVY = {'Ḥ': 'h', 'Ṣ': 's', 'Ṭ': 't', 'P': 'd', 'Z': 'z'}
SRC_VOWEL = {'a': 'a', 'i': 'i', 'u': 'u', 'ā': 'a', 'ī': 'i', 'ū': 'u', 'A': 'a', 'W': 'u', 'Y': 'i'}
EQUIV = {('z', 'Z'), ('D', 'Z'), ('d', 'P'), ('D', 'P'), ('z', 'D'), ('t', 'H'), ('h', 'H'), ('l', 'L'),
         ('w', 'W'), ('y', 'Y'), ('s', 'S')}


def _sub(l, s):
    """Cost of aligning Latin symbol l to source symbol s."""
    if s == 'O':
        return 0.0 if l in VOWELS else None
    if l in VOWELS:
        sv = SRC_VOWEL.get(s)
        if sv is None:
            return None
        return 0.0 if sv == l else 0.8
    if s == '’?':
        return 0.0 if l == '’' else None
    if s == 'w~':
        return 0.1 if l in ('w', 'u') else None
    if s == 'y~':
        return 0.1 if l in ('y', 'i') else None
    if l == s or (l, s) in SAME_LETTER:
        return 0.0
    if (l, s) in EQUIV:
        return 0.3
    if s in SRC_VOWEL or s == 'O':
        return None
    return 1.6


def _del_src(s):
    """Cost of a source symbol with nothing in the line."""
    if s in ('O', 'L', '’?', 'H'):
        return 0.1
    if s in ('’', 'A'):
        return 0.35
    if s in ('a', 'i', 'u'):
        return 0.6          # a case ending dropped in pause, or a vowel the line elides
    if s in ('ā', 'ī', 'ū'):
        return 0.9
    if s in ('W', 'Y', 'n', 'w~', 'y~'):
        return 0.8
    if s == '‘':
        return 0.9
    return 1.0


def _ins_lat(l):
    """Cost of a Latin symbol with nothing in the source."""
    if l in VOWELS:
        return 0.6          # an unvowelled source has no short vowels to match
    if l in ('’', '‘', 'h'):
        return 0.6
    return 1.0


def align(lat, src):
    """Semi-global alignment: every Latin unit is placed, the source may run on at both ends.
    Returns, per Latin unit index, the source symbol it was aligned to (or None)."""
    n, m = len(lat), len(src)
    INF = float('inf')
    # dp[i][j]: best cost with i Latin units and j source symbols consumed
    prev = [0.0] * (m + 1)              # free leading source gap
    back = [[0] * (m + 1) for _ in range(n + 1)]
    for j in range(1, m + 1):
        back[0][j] = 3
    rows = [prev]
    for i in range(1, n + 1):
        cur = [INF] * (m + 1)
        l = lat[i - 1]
        ins = _ins_lat(l)
        cur[0] = prev[0] + ins
        back[i][0] = 2
        bi = back[i]
        for j in range(1, m + 1):
            s = src[j - 1]
            best, how = prev[j] + ins, 2
            c = _sub(l, s)
            if c is not None and prev[j - 1] + c < best:
                best, how = prev[j - 1] + c, 1
            d = cur[j - 1] + _del_src(s)
            if d < best:
                best, how = d, 3
            cur[j] = best
            bi[j] = how
        rows.append(cur)
        prev = cur
    # free trailing source gap
    j = min(range(m + 1), key=lambda k: prev[k])
    i = n
    got = [None] * n
    at = [None] * n
    while i > 0:
        how = back[i][j]
        if how == 1:
            got[i - 1] = src[j - 1]; at[i - 1] = j - 1; i -= 1; j -= 1
        elif how == 2:
            i -= 1
        else:
            j -= 1
    align.last_at = at
    return got, prev[min(range(m + 1), key=lambda k: prev[k])]


LONG_SRC = {'ā', 'ī', 'ū', 'A', 'W', 'Y'}


def long_positions(text, src_words, skip=frozenset()):
    """Indices (into text) of the vowels that are long in the source. `skip`: indices of text left out of
    the alignment (an English note inside the line)."""
    pos, heavy, cost = positions(text, src_words, skip)
    return pos, cost


def positions(text, src_words, skip=frozenset()):
    """(long vowels, heavy letters, cost): indices into text of the vowels long in the source, and of the
    single letters h s t d z that write ح ص ط ض ظ there. A letter just before a hyphen is the article's
    (as-Salaah, minas-Saadiqeen) and keeps its plain form."""
    src = [s for w in src_words for s in w]
    lat = [u for u in latin_units(text) if u[1] not in skip]
    if not lat or not src:
        return set(), set(), 0.0
    got, cost = align([u[0] for u in lat], src)
    at = align.last_at
    pos, heavy = set(), set()
    for k, ((sym, idx), s) in enumerate(zip(lat, got)):
        if sym in VOWELS and s in LONG_SRC and SRC_VOWEL[s] == sym:
            initial = idx == 0 or not (text[idx - 1].isalpha() or text[idx - 1] in '‘’')
            on_hamza = at[k] is not None and at[k] > 0 and src[at[k] - 1] == '’'
            if initial and s not in ('ā', 'ī', 'ū') and not on_hamza:
                continue          # a word's opening vowel is long only where the Arabic says so plainly (آمنا)
            if text[idx + 1:idx + 5].lower() == 'llah':
                continue          # illallah, Hasbunallah: the vowel before Allah's elided alif is short
            pos.add(idx)
        elif s in HEAVY and HEAVY[s] == sym and text[idx + 1:idx + 2] != '-':
            heavy.add(idx)
    return pos, heavy, cost / max(1, len(lat))


DOUBLE = {'a': 'aa', 'i': 'ee', 'u': 'oo', 'A': 'Aa', 'I': 'Ee', 'U': 'Oo'}


def lengthen(text, positions, heavy=frozenset()):
    """Write the long vowels doubled, except a long vowel that ends a word (Rabbana, inni, Abu) and the
    a of Allah (Allahumma, bismillah, illallah); and the heavy letters as capitals (Hasanah, SubHaana)."""
    out = []
    for i, ch in enumerate(text):
        if i in positions and ch in DOUBLE:
            nxt = text[i + 1:i + 2]
            final = not nxt or not (nxt.isalpha() or nxt in '‘’')
            allah = ch in 'aA' and text[max(0, i - 2):i].lower() == 'll' and text[i + 1:i + 2].lower() == 'h'
            if final or allah:
                out.append(ch)
            else:
                out.append(DOUBLE[ch])
        elif i in heavy:
            out.append(ch.upper())
        else:
            out.append(ch)
    return ''.join(out)
