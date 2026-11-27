#!/usr/bin/env python3
"""The Islam tab's one transliteration style, and the pass that holds the tab to it.

Abu, 2026-11-26: "Let's be consistent with our transliteration in all of Islam tab". The style below
is not invented: it is what most of the tab was already written in (counted over every string in
iPhone/Islam on that day), applied to the places that drifted from it.

THE HOUSE STYLE

Abu, the same day, on the first version (single vowels): "Should be Qiblah I like aqeedah. Should be Maajid
versus Majid hmm I lowkey like i for kasra and ee for yaa and u for dammah and oo for waw and a for fatha and
aa for alif ... Follow Arabic alphabet pattern". So the vowels follow the Arabic letters:

  * A short vowel (a harakah) is one letter: a for fathah, i for kasrah, u for dammah.
  * A long vowel (a letter) is two: aa for alif, ee for yaa, oo for waw: Tawheed, Saheeh, Aqeedah,
    Ibraaheem, Daawood, al-Bukhaari, Ar-Raheem, Al-Ghafoor, Al-Maajid (الماجد) beside Al-Majeed (المجيد).
  * A long vowel that ENDS a word is written single: Abu, Ali, Moosa, al-Bukhaari, Rabbana, inni, dunya.
    Nothing short can end a word there to be mistaken for it, and the doubled ends (Aboo, Alee, Moosaa)
    read as misspellings to most readers. One switch (`render_long`) writes them doubled too.
  * ay and aw are diphthongs, not long vowels: Shaykh, Hurayrah, Quraysh, yawm.

Names and terms in prose (articles, stories, libraries, citations, the 99 Names):
  * No macrons or dots.
  * ʿayn is ‘ and hamza is ’ (curly, never a straight ' or a backtick): Sa‘eed, Ismaa‘eel, Ka‘bah,
    Jaami‘; Aa’ishah, Israa’eel, an-Nasaa’i.
  * Neither is written at the START of a name or term: Umar, Ali, Abdullah, al-Azeem, al-Aqeedah.
    ‘Ad keeps its mark: bare, the people of Hood read as the English word "Ad".
  * ʿayn at the END is written (Jaami‘, Majmoo‘); a final hamza is left as each name had it.
  * Ta marbutah is -ah: Faatimah, Koofah, Basrah, Hijrah, Qiblah.
  * The article joins sun letters: at-Tirmidhi, an-Nawawi, ash-Shaafi‘i, as-Sunnah, ar-Rahmaan.
  * ظ is z (al-Azeem, Haafiz); ذ is dh. Dhuhr keeps its dh: the app's prayer name everywhere.
  * Words English already owns keep their English form: Allah (and every name built on it: Abdullah,
    Allahumma, bismillah), Islam, Muslim, Quran, hadith (the Hadith tab), Sunnah, Sunni, Shia, imam,
    Ramadan, Eid, Hajj, dua, dawah, jinn, Sufi, hijab, niqab, jihad, Makkah, Madinah, adhan (the Adhan
    tab), and the prayer names Fajr, Dhuhr, Asr, Maghrib, Isha, Jumuah.
  * Left exactly as they are: "Saheeh International" (the translation's own name, now in step), names
    as their owners or the Bible spell them (Deedat, Jamal Badawi, Beersheba), and the tajweed and qiraat
    vocabulary the Quran tab shares (Tajweed, Sukoon, Tanween, Ikhfaa, Qalqalah, Ghunnah, Qiraat, the
    letter names). The Arabic and Tajweed lessons keep their teaching spellings.
  * Where one spelling is two words, the context decides (`AMBIGUOUS`): Imam Maalik / Abd al-Malik,
    al-Haakim (the hadith scholar) / Hisham ibn Hakeem, Haajar (the mother of Ismaa‘eel) / Ibn Hajar,
    Fath al-Qadeer / Abd al-Qaadir, the amen (aameen) / al-Ameen.

Recitation lines (the transliteration under a dua, a dhikr or a Hisn al-Muslim entry):
  * The same letters and marks, with every ʿayn written, at the start too: wa ‘alaykum, a‘oodhu.
    A hamza is written inside or at the end of a word, never at its start: as’aluka, shay’in.
  * Long vowels are read off the line's own Arabic (the Quran's word by word for an ayah, the hadith's
    words for a hadith, the entry's Arabic for Hisn al-Muslim) by `transliteration_vowels.py`, and every
    word is then held to one spelling across all the lines (`recite` in the lexicon).
  * A long vowel before the next word's hamzat al-wasl is said short and written short: fid-dunya,
    Hasbunallah, minal-kufri. The article joins the word before it, as it is read.

Where the long vowels come from: `Scripts/transliteration_lexicon.json`. "prose" maps each Arabic word of
the tab, as written with single vowels, to its spelling with macrons (sahīh, bukhārī, ibrāhīm); null marks a
word that is not Arabic or is spelled as its owner spells it. "recite" maps each recitation word to its
settled spelling.

USE
    python3 Scripts/transliteration.py --check     # list what is off-style, change nothing
    python3 Scripts/transliteration.py --write     # rewrite the Islam tab's sources and packs
The pack builders (build_hisn_duas.py, build_names_details.py, build_miracles_pack.py,
build_daily_reminders.py) import `prose` / `recitation` so a rebuild lands in this style too.
"""
import json
import lzma
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
import transliteration_vowels as V  # noqa: E402

# ---------------------------------------------------------------------------------------------
# Shared

ARABIC_MARKS = str.maketrans({
    'ā': 'a', 'ī': 'i', 'ū': 'u', 'Ā': 'A', 'Ī': 'I', 'Ū': 'U', 'ḥ': 'h', 'Ḥ': 'H', 'ṣ': 's', 'Ṣ': 'S',
    'ḍ': 'd', 'Ḍ': 'D', 'ṭ': 't', 'Ṭ': 'T', 'ẓ': 'z', 'Ẓ': 'Z', 'ĥ': 'h', 'đ': 'd', 'Đ': 'D', 'ʿ': '‘', 'ʾ': '’',
})

TOKEN = re.compile(r"[A-Za-zÀ-ɏḀ-ỿ'‘’`ʿʾ]+(?:-[A-Za-zÀ-ɏḀ-ỿ'‘’`ʿʾ]+)*")

_ENGLISH = None


def english(word):
    """True for an English word or an inflection of one (books, deeds, freed, fleeing)."""
    global _ENGLISH
    if _ENGLISH is None:
        try:
            _ENGLISH = set(w.strip().lower() for w in open('/usr/share/dict/words'))
        except OSError:
            _ENGLISH = set()
        _ENGLISH |= {'feet', 'teeth', 'geese', 'cooperation', 'coordinate', 'woollen', 'sightseeing',
                     'servanthood', 'neighbourhood', 'neighbourhoods', 'reenacted', 'fullscreen',
                     'forsook', 'foreseen', 'rooftop', 'homoousios', 'greece', 'poorest'}
    w = word.lower().strip("'‘’")
    cands = {w}
    for suf, rep in (('s', ''), ('es', ''), ('ed', ''), ('ed', 'e'), ('d', ''), ('ing', ''),
                     ('ing', 'e'), ('er', ''), ('ers', ''), ('est', ''), ('ly', ''), ('ness', ''),
                     ('ful', ''), ('ment', ''), ('ments', ''), ('ies', 'y'), ('ied', 'y')):
        if w.endswith(suf) and len(w) - len(suf) >= 3:
            cands.add(w[:-len(suf)] + rep)
    return any(c in _ENGLISH for c in cands)


QUOTE_OPENERS = set("""we this so may author did it leave am do the my what believe an a i he she they you if in
    on to and but not no yes our your his her their that there then when who why how where be say said let""".split())


def exact_english(word):
    """An English word that opens a quotation here (‘This, ‘We): its ‘ is a quote mark, not an ʿayn."""
    return word.lower() in QUOTE_OPENERS


def match_case(src, dst):
    letters = ''.join(ch for ch in src if ch.isalpha() and ch not in 'ʿʾ')
    if len(letters) > 1 and letters.isupper():
        return dst.upper()
    if letters[:1].isupper():
        i = next((k for k, ch in enumerate(dst) if ch.isalpha()), 0)
        return dst[:i] + dst[i].upper() + dst[i + 1:]
    return dst


# ---------------------------------------------------------------------------------------------
# Long vowels: aa for alif, ee for yaa, oo for waw (single at a word's end)

_LEX = None


def lexicon():
    global _LEX
    if _LEX is None:
        _LEX = json.loads((ROOT / 'Scripts/transliteration_lexicon.json').read_text())
    return _LEX


# Words English already owns, kept as English writes them (see the docstring).
ENGLISH_OWNED = set('''allah islam islamic islamically muslim muslims quran quranic quranist quranists hadith hadiths
    sunnah sunnahs sunni sunnis shia ramadan imam imams imamate dua duas eid eids hajj makkah makkan madinah madinan
    dawah jumuah isha adhan fajr dhuhr asr maghrib jinn jinns sufi sufis sufism hijab hijabs niqab niqabs jihad
    iraq iraqi islamqa tilawa mecca medina qurans surah surahs surat abbasid abbasids'''.split())
# An English word built on an Arabic one (Kharijites, Uthmanic, Fatimids) stays English.
DERIVED = re.compile(r'(?:ites?|isms?|ists?|ids|ic|ical|ically)$')
FINAL_DOUBLED = False     # True writes a word's last long vowel doubled too (Aboo, Alee, Moosaa)


def collapse(word):
    """A word with its long vowels single again (the key the lexicon is written in)."""
    w = re.sub('ee', 'i', word); w = re.sub('Ee', 'I', w); w = re.sub('EE', 'I', w)
    w = re.sub('oo', 'u', w); w = re.sub('Oo', 'U', w); w = re.sub('OO', 'U', w)
    w = re.sub('aa', 'a', w); w = re.sub('Aa', 'A', w); w = re.sub('AA', 'A', w)
    w = re.sub('ii', 'i', w); w = re.sub('uu', 'u', w)
    return w


def render_long(m, medial_end=False, plural=False):
    """A spelling with macrons (sahīh) in the house style (saheeh). `medial_end`: a mark follows the
    word (Samee‘, asmaa’), so its last vowel is not at the end. `plural`: an English -s on a word that ends
    in its long vowel (Salafis, Hanbalis), which stays at the end."""
    m = re.sub('llāh', 'llah', m)          # Allah, and every name built on it, as English writes it
    out = []
    for i, ch in enumerate(m):
        if ch in 'āīū':
            rest = m[i + 1:]
            final = (rest == '' or re.fullmatch(r"['’][sS]", rest) is not None or (plural and rest in ('s', 'S'))) \
                and not medial_end and not FINAL_DOUBLED
            out.append({'ā': 'a', 'ī': 'i', 'ū': 'u'}[ch] if final else {'ā': 'aa', 'ī': 'ee', 'ū': 'oo'}[ch])
        else:
            out.append(ch)
    return ''.join(out)


def long_part(p, teaching=False):
    """One word part (no hyphens), its long vowels written as the lexicon says."""
    lead = re.match(r"^[‘’']*", p).group(0)
    trail = re.search(r"[‘’']*$", p).group(0)
    core = p[len(lead):len(p) - len(trail)]
    if not core or not re.search('[aeiouAEIOU]', core) or re.search(r'[a-z][A-Z]', core):
        return p
    if teaching and not core[:1].isupper():
        return p
    low = core.lower()
    if low in ENGLISH_OWNED or low in KEEP or collapse(low) in ENGLISH_OWNED:
        return p
    lex = lexicon()['prose']
    if low in lex:
        m = lex[low]
    elif not english(low) and collapse(low) in lex:
        m = lex[collapse(low)]
    else:
        return p
    if not m or DERIVED.search(low) or (re.search(r'ans?$', low) and re.sub(r'ans?$', 'ah', low) in lex):
        return p
    # an English plural of a word that ends in its long vowel: Salafis (salafī + s), not Idrees (idrīs)
    plural = low.endswith('s') and isinstance(lex.get(low[:-1]), str) and lex[low[:-1]] == m[:-1]
    return lead + match_case(core, render_long(m, medial_end=bool(trail), plural=plural)) + trail


def _tol(word):
    """A regex for a word written either way (Hajar / Haajar)."""
    swap = {'a': 'a{1,2}', 'A': 'Aa?', 'i': '(?:i|ee)', 'I': '(?:I|Ee)', 'u': '(?:u|oo)', 'U': '(?:U|Oo)'}
    return ''.join(swap.get(ch, re.escape(ch)) for ch in word)


# One spelling, two words: the reading the context shows, where it is not the lexicon's. Each pattern
# names the word in group w; the lexicon's reading is the default everywhere else.
AMBIGUOUS = [(re.compile(p), form) for p, form in [
    # āhād, the hadith term (Ahad, the Name, and "Qul huwallahu ahad" keep the short a)
    (rf'{_tol("Akhbar")} al-(?P<w>{_tol("Ahad")})\b', 'āhād'),
    (rf'\b(?P<w>{_tol("ahad")}|{_tol("Ahad")})(?=\s+(?:report|hadith|narration|chain)s?\b)', 'āhād'),
    (rf'\b(?:is|are|called|each) (?P<w>{_tol("ahad")})\b', 'āhād'),
    (rf'\((?P<w>{_tol("ahad")})\)', 'āhād'),
    (rf'\b(?P<w>{_tol("ahad")}|{_tol("Ahad")})(?=\*{{0,2}} \(آحَاد\))', 'āhād'),
    (rf'\b(?P<w>{_tol("Ahad")})(?= is (?:a count|not a grade|proof))', 'āhād'),
    # Aayat al-Kursi: one ayah (aayaat, ayahs, elsewhere)
    (rf'\b(?P<w>{_tol("Ayat")}|{_tol("ayat")}|AYAT|AAYAT)(?= [Aa]l-{_tol("Kursi")}| AL-KURSI)', 'āyat'),
    # Ali Imran
    (rf'\b(?P<w>{_tol("Ali")})(?= ‘?{_tol("Imran")})', 'āli'),
    # ālim, a scholar
    (rf'\*\*(?P<w>{_tol("Alim")})(?= \(عَالِم\))', 'ālim'),
    # āmīn, the amen (al-Ameen is the Prophet\'s name)
    (rf'\bwa (?P<w>{_tol("amin")})(?= raw)', 'āmin'),
    (rf'(?<![A-Za-z-])(?P<w>{_tol("amin")})\b', 'āmīn'),
    (rf'\bsay (?P<w>{_tol("Amin")})\b', 'āmīn'),
    # amīr, the title
    (rf'\b(?P<w>{_tol("Amir")}|{_tol("amir")})(?= al-Mu’min)', 'amīr'),
    (rf'\b(?P<w>Anwar)(?= Shah)', 'anwar'),
    (rf'\b[Aa]l-(?P<w>{_tol("Aqib")})\b', 'āqib'),
    (rf'{_tol("Wafayat")} al-(?P<w>{_tol("A‘yan")})', 'a‘yān'),
    # al-Baaqi, the Name (and Abd al-Baaqi); al-Baqee‘, the cemetery
    (rf'\b[Aa]l-(?P<w>{_tol("Baqi")})(?=[‘’\'])', 'baqī'),
    (rf'\b[Aa]l-(?P<w>{_tol("Baqi")})\b(?![‘’\'])', 'bāqī'),
    (rf'read it (?P<w>{_tol("farihin")}), with a long a', 'fārihīn'),
    # Haajar, the mother of Ismaa‘eel; Ibn Hajar and al-Hajar al-Aswad keep the short a
    (rf'(?<![Ii]bn )(?<!al-)(?<!Al-)\b(?P<w>{_tol("Hajar")})\b(?! [Aa]l-{_tol("Aswad")})(?! al-{_tol("Asqalani")})', 'hājar'),
    # Hakeem: Hisham ibn Hakeem, Umm Hakeem, al-Azeez al-Hakeem; the hadith scholar is al-Haakim
    (rf'\b(?:ibn|bin|Umm|Ibn|Bahz ibn) (?P<w>{_tol("Hakim")})\b', 'hakīm'),
    (rf'(?i){_tol("azizul")}-(?P<w>{_tol("hakim")})', 'hakīm'),
    (rf'\b(?:entrusted|and) (?P<w>{_tol("Hamid")})(?= with a pledge| kept)', 'hāmid'),
    # the Haram, a sanctuary (haraam is the forbidden, and Masjid al-Haraam)
    (rf'\bthe (?P<w>{_tol("Haram")})\b', 'haram'),
    (rf'(?i)\b(?P<w>{_tol("haram")})(?= with sacred)', 'haram'),
    (rf'plural of (?P<w>{_tol("haram")})', 'haram'),
    (rf'\b(?P<w>{_tol("Haram")})(?= [Aa]sh-{_tol("Sharif")}| of {_tol("Makkah")})', 'haram'),
    (rf'Asma (?P<w>Hilali)', 'hilali'),
    (rf'\b[Aa]l-(?P<w>{_tol("Hira")})\b', 'hīra'),
    (rf'(?P<w>Jamil)(?= Hammoudeh)', 'jamil'),
    (rf'(?P<w>Khalili)(?= Collection)', 'khalili'),
    # Al-Malik, the Name, and Abd al-Malik; Imam Maalik everywhere else
    (rf'\b[Aa]l-(?P<w>{_tol("Malik")}|{_tol("malik")})\b(?!ul)', 'malik'),
    (rf'Ali (?P<w>Nuri)', 'nuri'),
    (rf'{_tol("Fath")} al-(?P<w>{_tol("Qadir")})', 'qadīr'),
    (rf'(?:\b[Aa]l-|Abdul-)(?P<w>{_tol("Qadir")})\b', 'qādir'),
    # rahim, the womb and kinship (Ar-Raheem is the Name)
    (rf'(?<![A-Za-z])(?P<w>{_tol("rahim")})\b', 'rahim'),
    (rf'\b[Aa]r-(?P<w>{_tol("Rashid")})\b', 'rashīd'),
    (rf'rajulun (?P<w>{_tol("rashid")})', 'rashīd'),
    (rf"\b(?P<w>Sami)(?=['‘’] Allahu)", 'sami'),
    (rf'destitute of (?P<w>Sara)', 'sara'),
    (rf'Irfan (?P<w>Shahid)', 'shahid'),
    (rf'(?<![A-Za-z-])(?P<w>{_tol("shahid")})\b', 'shāhid'),
    (rf'\bfrom (?P<w>sharika)\b', 'sharika'),
    (rf'(?P<w>sharika)(?=, “to share)', 'sharika'),
]]


def _ambiguous(text, hold, teaching=False):
    """The words AMBIGUOUS settles, written and held so the word pass leaves them. A lesson only lends
    its capitalised names."""
    for pat, form in AMBIGUOUS:
        def sub(m):
            w = m.group('w')
            if teaching and not w[:1].isupper():
                return m.group(0)
            after = m.string[m.end('w'):m.end('w') + 1]
            r = match_case(w, render_long(form, medial_end=after in '‘’\''))
            return m.string[m.start():m.start('w')] + hold(r) + m.string[m.end('w'):m.end()]
        text = pat.sub(sub, text)
    return text


# ---------------------------------------------------------------------------------------------
# Prose: names and terms

# ʿayn (‘) or hamza (’) at each mark, decided by the Arabic, for every name and term the tab wrote
# with a straight ', a backtick, or both curly marks. Key: lower case, every mark as "?".
MARKS = {
    '?a?ishah': 'a’ishah', 'a?in': 'a’in', '?a?in': 'a’in', 'a?ishah': 'a’ishah', 'a?immah': 'a’immah', 'a?inni': 'a‘inni',
    'a?izz': 'a‘izz', 'a?izzah': 'a‘izzah', 'a?la': 'a‘la', 'a?lam': 'a‘lam', 'a?mash': 'a‘mash',
    'a?raf': 'a‘raf', 'a?sam': 'a‘sam', 'a?tayt': 'a‘tayt', 'a?udhu': 'a‘udhu', 'a?yan': 'a‘yan',
    'abu?u': 'abu’u', 'af?al': 'af‘al', 'akhta?na': 'akhta’na', 'alja?tu': 'alja’tu',
    'allahummaj?alhu': 'allahummaj‘alhu', 'an?am': 'an‘am', 'arfa?uh': 'arfa‘uh', 'arna?ut': 'arna’ut',
    'as?aluka': 'as’aluka', 'as?alullaha': 'as’alullaha', 'as?alullahal': 'as’alullahal',
    'at?amani': 'at‘amani', 'at?imna': 'at‘imna', 'ba?adta': 'ba‘adta', 'ba?d': 'ba‘d', 'ba?da': 'ba‘da',
    'ba?daha': 'ba‘daha', 'ba?id': 'ba‘id', 'ba?ith': 'ba‘ith', 'ba?l': 'ba‘l', 'ba?sa': 'ba’sa',
    'baha?i': 'baha’i', 'balta?ah': 'balta‘ah', 'bay?ah': 'bay‘ah', 'bi?thah': 'bi‘thah',
    'bid?ah': 'bid‘ah', 'bini?matika': 'bini‘matika', 'bu?dah': 'bu‘dah', 'da?if': 'da‘if',
    'da?ifah': 'da‘ifah', 'da?imah': 'da’imah', 'da?wati': 'da‘wati', 'dala?il': 'dala’il',
    'du?ali': 'du’ali', 'fa?fu': 'fa‘fu', 'fada?il': 'fada’il', 'fawa?id': 'fawa’id',
    'fir?awn': 'fir‘awn', 'i?jam': 'i‘jam', 'i?jaz': 'i‘jaz', 'i?lam': 'i‘lam', 'i?tidal': 'i‘tidal',
    'i?tikaf': 'i‘tikaf', 'i?tiqad': 'i‘tiqad', 'i?tisam': 'i‘tisam', 'isma?il': 'isma‘il',
    'isra?il': 'isra’il', 'isra?iliyyat': 'isra’iliyyat', 'isti?ab': 'isti‘ab', 'isti?adhah': 'isti‘adhah',
    'isti?dhan': 'isti’dhan', 'ja?alana': 'ja‘alana', 'ja?far': 'ja‘far', 'jama?a': 'jama‘a',
    'jama?ah': 'jama‘ah', 'jana?iz': 'jana’iz', 'ju?shum': 'ju‘shum', 'ka?abatil': 'ka’abatil',
    'ka?b': 'ka‘b', 'ka?bah': 'ka‘bah', 'ka?bayn': 'ka‘bayn', 'khaba?ith': 'khaba’ith',
    'khath?am': 'khath‘am', 'lalaka?i': 'lalaka’i', 'lu?lu?ah': 'lu’lu’ah', 'lum?at': 'lum‘at',
    'ma?ad': 'ma‘ad', 'ma?ani': 'ma‘ani', 'ma?bad': 'ma‘bad', 'ma?bud': 'ma‘bud',
    'ma?dikarib': 'ma‘dikarib', 'ma?i': 'ma‘i', 'ma?idah': 'ma’idah', 'ma?in': 'ma‘in',
    'ma?mun': 'ma’mun', 'ma?na': 'ma‘na', 'ma?rifat': 'ma‘rifat', 'ma?ruf': 'ma‘ruf',
    'ma?thur': 'ma’thur', 'mada?in': 'mada’in', 'mala?ikah': 'mala’ikah', 'mala?ikati': 'mala’ikati',
    'malja?a': 'malja’a', 'mana?t': 'mana‘t', 'mani?a': 'mani‘a', 'mar?ah': 'mar’ah', 'mas?ud': 'mas‘ud',
    'mastata?tu': 'mastata‘tu', 'mawdu?at': 'mawdu‘at', 'mi?raj': 'mi‘raj', 'mu?adh': 'mu‘adh',
    'mu?adhdhin': 'mu’adhdhin', 'mu?adhin': 'mu’adhin', 'mu?akkadah': 'mu’akkadah',
    'mu?allafat': 'mu’allafat', 'mu?allaqat': 'mu‘allaqat', 'mu?aradah': 'mu‘aradah',
    'mu?awiyah': 'mu‘awiyah', 'mu?awwidhat': 'mu‘awwidhat', 'mu?awwidhatayn': 'mu‘awwidhatayn',
    'mu?ayt': 'mu‘ayt', 'mu?izz': 'mu‘izz', 'mu?jam': 'mu‘jam', 'mu?jizah': 'mu‘jizah', 'mu?min': 'mu’min',
    'mu?minina': 'mu’minina', 'mu?minun': 'mu’minun', 'mu?tah': 'mu’tah', 'mu?tazilah': 'mu‘tazilah',
    'mu?tazili': 'mu‘tazili', 'mu?tiya': 'mu‘tiya', 'muqatta?ah': 'muqatta‘ah', 'muqatta?at': 'muqatta‘at',
    'murji?ah': 'murji’ah', 'mus?ab': 'mus‘ab', 'musi?un': 'musi’un', 'mut?im': 'mut‘im',
    'mut?ah': 'mut‘ah', 'muttaki?an': 'muttaki’an', 'muwaqqi?in': 'muwaqqi‘in', 'nafi?ah': 'nafi‘ah',
    'nafi?an': 'nafi‘an', 'nakha?i': 'nakha‘i', 'nas?aluka': 'nas’aluka', 'nasa?i': 'nasa’i',
    'nazi?at': 'nazi‘at', 'nu?aym': 'nu‘aym', 'nu?man': 'nu‘man', 'qa?dah': 'qa‘dah', 'qa?imah': 'qa’imah',
    'qa?iman': 'qa’iman', 'qara?a': 'qara’a', 'qawa?id': 'qawa‘id', 'qira?at': 'qira’at', 'ra?d': 'ra‘d',
    'ra?y': 'ra’y', 'rabi?ah': 'rabi‘ah', 'rafi?ah': 'rafi‘ah', 'raji?un': 'raji‘un', 'rak?ah': 'rak‘ah',
    'rak?ahs': 'rak‘ahs', 'rasa?il': 'rasa’il', 'ru?b': 'ru‘b', 'ru?ya': 'ru’ya', 'sa?adah': 'sa‘adah',
    'sa?ah': 'sa‘ah', 'sa?d': 'sa‘d', 'sa?di': 'sa‘di', 'sa?i': 'sa‘i', 'sa?id': 'sa‘id',
    'sa?idah': 'sa‘idah', 'sa?imun': 'sa’imun', 'sa?y': 'sa‘y', 'sab?ah': 'sab‘ah', 'sam?ahu': 'sam‘ahu',
    'sam?an': 'sam‘an', 'sam?ani': 'sam‘ani', 'sami?a': 'sami‘a', 'san?a': 'san‘a', 'sana?a': 'san‘a',
    'sana?tu': 'sana‘tu', 'sha?ban': 'sha‘ban', 'sha?ir': 'sha‘ir', 'shafa?ah': 'shafa‘ah',
    'shafi?i': 'shafi‘i', 'shafi?iyyah': 'shafi‘iyyah', 'shari?ah': 'shari‘ah', 'sharee?ah': 'shari‘ah',
    'shay?in': 'shay’in', 'shi?r': 'shi‘r', 'shu?ara': 'shu‘ara', 'shu?ayb': 'shu‘ayb',
    'shu?bah': 'shu‘bah', 'su?il': 'su’il', 'suni?a': 'suni‘a', 'ta?al': 'ta‘al', 'ta?ala': 'ta‘ala',
    'ta?amakumul': 'ta‘amakumul', 'ta?arud': 'ta‘arud', 'ta?awwudh': 'ta‘awwudh', 'ta?bir': 'ta‘bir',
    'ta?ibuna': 'ta’ibuna', 'ta?if': 'ta’if', 'ta?khir': 'ta’khir', 'ta?khudhuhu': 'ta’khudhuhu',
    'ta?min': 'ta’min', 'ta?wil': 'ta’wil', 'tabi?i': 'tabi‘i', 'tabi?in': 'tabi‘in', 'tabi?un': 'tabi‘un',
    'tis?iniyyah': 'tis‘iniyyah', 'tu?akhidhna': 'tu’akhidhna', 'u?idhuka': 'u‘idhuka',
    'u?idhuki': 'u‘idhuki', 'u?idhukuma': 'u‘idhukuma', 'wa?adtah': 'wa‘adtah', 'wa?dah': 'wa‘dah',
    'wa?dika': 'wa‘dika', 'wa?il': 'wa’il', 'wa?tha?is': 'wa‘tha’is', 'wab?athhu': 'wab‘athhu',
    'wada?tu': 'wada‘tu', 'ya?mar': 'ya‘mar', 'ya?muru': 'ya’muru', 'ya?qub': 'ya‘qub',
    'ya?uduhu': 'ya’uduhu', 'yada?ti': 'yada‘ti', 'yanfa?u': 'yanfa‘u', 'zam?ah': 'zam‘ah',
    'zama?u': 'zama’u', 'zawa?id': 'zawa’id', 'mu?ammal': 'mu’ammal', 'rabi?': 'rabi‘',
    'jami?': 'jami‘', 'majmu?': 'majmu‘', 'nafi?': 'nafi‘', 'tarji?': 'tarji‘', 'bada?i?': 'bada’i‘',
    'mawdu?': 'mawdu‘', 'marfu?': 'marfu‘', 'maqtu?': 'maqtu‘', 'munqati?': 'munqati‘', 'yasa?': 'yasa‘',
    'darda?': 'darda’', 'riqa?': 'riqa‘', 'zawra?': 'zawra’', 'ashari': 'ashari', 'bara?': 'bara’', 'asma?': 'asma’', 'awliya?': 'awliya’', 'fuqaha?': 'fuqaha’',
    'khulafa?': 'khulafa’', 'nisa?': 'nisa’', 'shifa?': 'shifa’', 'anbiya?': 'anbiya’',
}

# Whole words, matched case-insensitively on each hyphen-separated part (the possessive set aside).
WORDS = {
    # long vowels single
    'saheeh': 'sahih', 'tawheed': 'tawhid', 'aqeedah': 'aqidah', 'seerah': 'sirah', 'hadeeth': 'hadith',
    'tafseer': 'tafsir', 'taraweeh': 'tarawih', 'suhoor': 'suhur', 'sujood': 'sujud', 'tasleem': 'taslim',
    'yaqeen': 'yaqin', 'uthaymeen': 'uthaymin', 'masaajid': 'masajid', 'maaliki': 'maliki',
    'shaaban': 'sha‘ban', 'rasoolullah': 'rasulullah', 'rasool': 'rasul', 'rasoola': 'rasula',
    'muqattaat': 'muqatta‘at', 'wahhaab': 'wahhab', 'wahhaabis': 'wahhabis', 'mutawaatir': 'mutawatir',
    'iqaamah': 'iqamah', 'ashoora': 'ashura', 'tajdeed': 'tajdid', 'aqeeqah': 'aqiqah',
    'tahneek': 'tahnik', 'jibreel': 'jibril', 'ghurabaa': 'ghuraba', 'ibaadah': 'ibadah',
    'uloohiyyah': 'uluhiyyah', 'shafaah': 'shafa‘ah', 'qaloon': 'qalun', 'idrees': 'idris',
    'ibraheem': 'ibrahim', 'ibraaheem': 'ibrahim', 'mutabaah': 'mutaba‘ah', 'uboodiyyah': 'ubudiyyah',
    'tafweed': 'tafwid', 'waajib': 'wajib', 'ahzaab': 'ahzab', 'sahaabah': 'sahabah',
    'siddeeq': 'siddiq', 'haneefah': 'hanifah', 'faqeeh': 'faqih', 'tareeqahs': 'tariqahs',
    'kaafir': 'kafir', 'shahaadah': 'shahadah', 'muhajireen': 'muhajirin', 'deen': 'din', 'duaa': 'dua',
    'allaah': 'Allah', 'aallahu': 'Allahu', 'akbaar': 'akbar', 'masoomeen': 'ma‘sumin',
    'masumeen': 'ma‘sumin', 'masoomin': 'ma‘sumin', 'maasoomeen': 'ma‘sumin', 'maarif': 'ma‘arif',
    'maarouf': 'ma‘ruf', 'jahjaah': 'jahjah', 'abideen': 'abidin', 'maazif': 'ma‘azif', 'shaarib': 'sharib',
    'rabbanaa': 'rabbana', 'adheem': 'azim', 'adheemi': 'azimi', 'adhim': 'azim', 'azeem': 'azim',
    'azeez': 'aziz', 'raheem': 'rahim', 'raheeq': 'rahiq', 'rahmaan': 'rahman', 'hakeem': 'hakim',
    'kareem': 'karim', 'aleem': 'alim', 'ameen': 'amin', 'salaam': 'salam', 'salaamu': 'salamu',
    'salaah': 'salah', 'ghafoor': 'ghafur', 'kabeer': 'kabir', 'hafeez': 'hafiz', 'hafidh': 'hafiz',
    'muqeet': 'muqit', 'haseeb': 'hasib', 'jaleel': 'jalil', 'mujeeb': 'mujib', 'majeed': 'majid',
    'maajid': 'majid', 'zaahir': 'zahir', 'baatin': 'batin', 'jalaali': 'jalali', 'israa': 'isra',
    'shuraa': 'shura', 'sifaat': 'sifat', 'quraan': 'Quran',
    "qur'aan": 'Quran', 'qur’aan': 'Quran', "qur'an": 'Quran', 'qur’an': 'Quran', 'qurʾān': 'Quran',
    "qur'anic": 'Quranic', 'qur’anic': 'Quranic', "qur'aaniyyeen": 'Quraniyyin',
    "i'tikaaf": 'i‘tikaf', "da'eef": 'da‘if',
    # ta marbutah -ah
    'kufa': 'kufah', 'basra': 'basrah', 'fatima': 'fatimah', 'khadija': 'khadijah', 'talha': 'talhah',
    'umra': 'umrah', 'hijra': 'hijrah', 'sahaba': 'sahabah', 'qibla': 'qiblah', 'fitra': 'fitrah',
    'iqama': 'iqamah', 'ruqya': 'ruqyah', 'sharia': 'shari‘ah', 'shariah': 'shari‘ah',
    'shahada': 'shahadah', 'qalqala': 'qalqalah', 'awra': 'awrah', 'istikhara': 'istikharah',
    'khalifa': 'khalifah', 'rahma': 'rahmah', 'waraqa': 'waraqah', 'ahmadiyya': 'ahmadiyyah',
    'ahmadiya': 'ahmadiyyah', 'mutazila': 'mu‘tazilah', 'mutazilah': 'mu‘tazilah', 'muawiyah': 'mu‘awiyah',
    'arafa': 'arafah', 'hanifa': 'hanifah', 'sumayya': 'sumayyah', 'umayya': 'umayyah', 'urwa': 'urwah',
    'fatiha': 'fatihah', 'taymiyah': 'taymiyyah', 'taymiyya': 'taymiyyah', 'hudhaifa': 'hudhayfah',
    'hudaybiyyah': 'hudaybiyah', 'mihna': 'mihnah', 'udhiya': 'udhiyah',
    # ay, not ai / ei
    'hurairah': 'hurayrah', 'huraira': 'hurayrah', 'quraish': 'quraysh', 'zaid': 'zayd',
    'sulaiman': 'sulayman', 'suleiman': 'sulayman', 'shuaib': 'shu‘ayb', "shu'aib": 'shu‘ayb',
    'shuayb': 'shu‘ayb', 'khaibar': 'khaybar', 'sheikh': 'shaykh', 'shaikh': 'shaykh', 'husain': 'husayn',
    'hussain': 'husayn', 'hussein': 'husayn', 'zubair': 'zubayr', 'usaid': 'usayd', 'uwais': 'uways',
    'sulaim': 'sulaym', 'zainab': 'zaynab', 'qais': 'qays', 'juraij': 'jurayj', 'hunain': 'hunayn',
    'khair': 'khayr', 'ubaidah': 'ubaydah', 'baina': 'bayna', 'shaitaan': 'shaytan', 'musailima': 'musaylimah',
    # marks the tab wrote without, where it writes them everywhere else
    'masud': 'mas‘ud', 'yaqub': 'ya‘qub', 'ismail': 'isma‘il', 'israil': 'isra’il',
    'israiliyyat': 'isra’iliyyat', 'muadh': 'mu‘adh', 'bidah': 'bid‘ah', 'kabah': 'ka‘bah',
    'kaaba': 'ka‘bah', 'aisha': 'a’ishah', 'aishah': 'a’ishah', 'rakah': 'rak‘ah', 'rakahs': 'rak‘ahs',
    'itikaf': 'i‘tikaf', 'shafii': 'shafi‘i', 'jafar': 'ja‘far', 'abi\'l': 'abil', 'san‘a’': 'san‘a',
    'musab': 'mus‘ab', 'mutim': 'mut‘im', 'tabiun': 'tabi‘un', 'tabii': 'tabi‘i', 'kisai': 'kisa’i',
    'shaban': 'sha‘ban', 'miraj': 'mi‘raj', 'ijaz': 'i‘jaz', 'taif': 'ta’if', 'mutah': 'mu’tah',
    'tawil': 'ta’wil', 'daif': 'da‘if', 'rabiah': 'rabi‘ah', 'istila': 'isti‘la',
    # English forms the tab uses for these everywhere else
    "jumu'ah": 'jumuah', 'jumu’ah': 'jumuah', 'jumu‘ah': 'jumuah', 'jumu`ah': 'jumuah', 'jummah': 'jumuah',
    "du'a": 'dua', 'du‘a': 'dua', 'du`a': 'dua', 'du‘as': 'duas', "du'as": 'duas',
    "da'wah": 'dawah', 'da‘wah': 'dawah', "shi'ah": 'Shia', 'shi‘ah': 'Shia', 'shiah': 'Shia',
    'isha‘': 'isha', "isha'": 'isha', 'zuhr': 'dhuhr',
    # one spelling of wudu (ض is d; the final hamza as most of the tab leaves it)
    'ijma': 'ijma‘', 'wudhu': 'wudu', 'wudu’': 'wudu', "wudu'": 'wudu', 'wudhu’': 'wudu', "wudhu'": 'wudu',
}

# Never touched in prose: owned spellings, and the tajweed/qiraat vocabulary the Quran tab shares.
KEEP = set(w.lower() for w in '''Tajweed Tashkeel Sukoon Tanween Ikhfaa Idghaam Iqlaab Idhaar Izhaar Qalqalah
    Ghunnah Madd Maqsoorah Marbootah Marbuutah Makhaarij Qiraat Qiraah Riwayaat Harakaat Tafkheem Tarqeeq
    Istifaal Leen Muttasil Munfasil Alif Baa Taa Thaa Jeem Haa Khaa Daal Dhaal Raa Zaay Seen Sheen Saad Daad
    Dhaa Ayn Ghayn Faa Qaaf Kaaf Laam Meem Noon Waaw Yaa Hamzah Hamza Fatha Kasra Damma Fathah Kasrah Dammah
    Shaddah Maddah Deedat Adbeel Beersheba Zeboiim Barlaam Noorani Masroor Aaron Canaan Isaac Baal Saad
    Ahmed Jamaatkhana Dawoodibohra Ithnaashari Ithnaasheri Shujaee Khaddaat Imaanxlogy'''.split())
KEEP_MARKED = {'‘Ad', '‘AD'}
AD = {"'ad": '‘Ad', "'aad": '‘Ad', '‘aad': '‘Ad', 'aad': '‘Ad'}   # the people of Hud: bare, it reads "ad"

SUN = re.compile(r'^([Aa])l-(Th|Dh|Sh|[TDRZSN])(?=[a-z‘’])')
DHIKR_LESSONS = ('runs together as', 'Ash-hadu an la ilaha illa Allah, wa ash-hadu')
PROTECT = re.compile(r'Saheeh International|Sahih International|\b[\w.-]+\.(?:com|org|net|io|info)\b')


def _prose_part(p, teaching=False):
    if not p or p.lower() in KEEP or p.lower().strip("‘’'`ʿ") in KEEP:
        return p
    if p.lower() in AD:
        return AD[p.lower()].upper() if p.isupper() else AD[p.lower()]
    if teaching and p.lower().strip("‘’'`ʿ") in ('sifaat', 'sifat', 'ayn', 'ain'):
        return p
    if teaching:
        # the lessons keep their own marks and long vowels; only names follow the house style
        if not p[:1].isupper() and not p[:2] in ("‘A", "’A", "'A"):
            return p
    else:
        p = p.translate(ARABIC_MARKS)
        # a backtick is an ʿayn wherever it touches a letter
        p = re.sub(r'(?<=[A-Za-z])`|`(?=[A-Za-z])', '‘', p)
    low = p.lower()
    if low in WORDS:
        return match_case(p, WORDS[low])
    key = re.sub(r"['‘’]", '?', low)
    if '?' in key and key in MARKS:
        p = match_case(p, MARKS[key])
    elif '?' in key and key.lstrip('?') in MARKS and key[0] == '?':
        p = match_case(p[1:], MARKS[key.lstrip('?')])
    # a straight ' opening a lowercase Arabic word inside prose is an ʿayn (‘indakum, ‘alaykum)
    if (len(p) > 2 and p[0] == "'" and p[1].islower() and not english(p[1:]) and not p.endswith("'")):
        p = '‘' + p[1:]
    # no mark at the start of a name or term (‘Umar, al-‘Azim -> Umar, al-Azim)
    if (len(p) > 2 and p[0] in "‘’'" and p[1].isupper() and p not in KEEP_MARKED
            and not exact_english(p[1:].rstrip("’'")) and not (p[0] == "'" and p.endswith("'"))):
        p = p[1:]
        low = p.lower()
        if low in WORDS:
            return match_case(p, WORDS[low])
    return p


def prose_token(tok, teaching=False):
    m = re.match(r"^(.*?)((?:[’'])s)?$", tok)
    core, poss = m.group(1), m.group(2) or ''
    if not core:
        return tok
    # code names inside strings (ShiaAnswerView) and quote-wrapped words (‘how’) stay
    if re.search(r'[a-z][A-Z]', core) and not re.match(r'^[Aa][a-z]?-', core):
        return tok
    inner = core[1:-1]
    if core[0] == '‘' and core.endswith('’') and (exact_english(inner) or (inner[:1].islower() and english(inner))):
        return tok
    parts = core.split('-')
    out = '-'.join(long_part(_prose_part(p, teaching), teaching) for p in parts)
    out = SUN.sub(lambda m: f"{m.group(1)}{m.group(2)[0].lower()}{m.group(2)[1:].lower()}-{m.group(2)}", out)
    return out + poss


def prose(text, teaching=False):
    """One string of prose in the house style. Safe on any English text: only transliterations move.
    `teaching`: an Arabic or Tajweed lesson, where only capitalised names are restyled."""
    if not text:
        return text
    held = []

    def hold(m):
        held.append(m.group(0))
        return f'\x00{len(held) - 1}\x00'

    def keep(written):
        held.append(written)
        return f'\x00{len(held) - 1}\x00'
    lesson = any(collapse(x) in collapse(text) for x in DHIKR_LESSONS)
    text = re.sub(r'https?://\S+', hold, text)
    text = PROTECT.sub(hold, text)
    # the opening mark of a quoted phrase ('La ta'khudhuhu sinatun', ‘How the Quran’) is a quote mark
    text = re.sub(r"(?<![A-Za-z])['‘](?=(?:[^'‘’\n]|(?<=[A-Za-z])['’](?=[A-Za-z]))*?\s"
                  r"(?:[^'‘’\n]|(?<=[A-Za-z])['’](?=[A-Za-z]))*?[A-Za-z.!?,]['’](?![A-Za-z]))", hold, text)
    text = _ambiguous(text, keep, teaching)
    text = TOKEN.sub(lambda m: prose_token(m.group(0), teaching), text)
    # one name per book (Sunan at-Tirmidhi is the same Jaami‘)
    text = re.sub(r'\b(?:Sunan|Ja{1,2}mi‘?) at-Tirmidhi\b', 'Jaami‘ at-Tirmidhi', text)
    # the four dearest words, named the way the Dhikr rows write them (the shahadah lesson that
    # contrasts the written "illa Allah" with the spoken "illallah" keeps both)
    if not lesson:
        text = re.sub(r'\b(?:Subha{1,2}n Allah|Subha{1,2}nallah|subha{1,2}n Allah)(?=\b|i\b|il\b|il-|i )', 'SubhaanAllah', text)
        text = re.sub(r'\b(?:[Aa]l-hamdu lillah|Alhamdu lillah)\b(?!i)', 'Alhamdulillah', text)
        text = re.sub(r'\b([Ll])a ila{1,2}ha illa Allah\b', r'\1a ilaaha illallah', text)
        text = re.sub(r'\bAllahu akbar\b', 'Allahu Akbar', text)
    text = re.sub(r'\bSubha{1,2}nAllah', 'SubhaanAllah', text)
    while '\x00' in text:
        text = re.sub(r'\x00(\d+)\x00', lambda m: held[int(m.group(1))], text)
    return text


# ---------------------------------------------------------------------------------------------
# Recitation lines

# The hand-written lines use a straight ' for both letters. These are the hamzas; every other ' is
# an ʿayn. Keyed by the word as written (lower case, punctuation stripped).
HAMZA_WORDS = {
    "aba'ihim", "abu'u", "adhhibil-ba's", "alja'tu", "as'aluka", "as'alukal-'afiyah", "as'alukal-'afiyata",
    "as'alukal-'afwa", "as'alullahal-'azim", "bishay'in", "da'in", "dhahabaz-zama'u", "fis-sama'i",
    "fuja'ati", "ista'tharta", "jila'a", "ka'abatil-manzari", "lil-mu'minina", "lilmu'mineena",
    "maaa'idatam", "malja'a", "mu'minan", "mu'wi", "nas'aluka", "qada'uka", "ra'oofur", "saaa'at",
    "saiyi'at", "samaaa'i", "shai'in", "shai'ir", "shay'in", "shay'un", "shifa'a", "shifa'an", "shifa'uk",
    "su'an", "su'il-munqalabi", "ta'ibuna", "ta'khudhuhu", "tu'aakhiznaaa", "wal-mu'minat", "ya'uduhu",
    "yu'dhik", "taj'alal-qur'ana", "wa'tha'is-safari", "mu'min", "mu'minin", "mu'minun", "ma'idah",
    "bi'r", "ra's", "sa'altu", "as'al", "qur'an", "qur'ana", "shu'm", "mu'w", "sha'n", "shay'a",
    "haiyi'", "sha'", "sha'a", "ja'a", "sa'a",
}
# words that mix the two letters: the marks in order
MIXED = {"as'alukal-'afiyah": "as’alukal-‘afiyah", "as'alukal-'afiyata": "as’alukal-‘afiyata",
         "as'alukal-'afwa": "as’alukal-‘afwa", "as'alullahal-'azim": "as’alullahal-‘azim",
         "taj'alal-qur'ana": "taj‘alal-qur’ana", "wa'tha'is-safari": "wa‘tha’is-safari"}
# Tanzil-style spellings in the Quranic duas: ذ written z, ظ written dh
RECITE_WORDS = {"tu'aakhiznaaa": "tu’akhidhna", "'adheemi": "‘azimi", "'adheem": "‘azim",
                "'adhim": "‘azim", "adheem": "azim", "al-‘adhim": "al-‘azim", "dhaalimiin": "zalimin",
                "dhaalimiina": "zalimina", "zaalimeen": "zalimin", "shayin": "shay’in", "shay'in": "shay’in"}


def _single_vowels(w):
    w = re.sub(r'(?i)a{2,}', lambda m: m.group(0)[0], w)
    w = re.sub(r'(?i)e{2,}', lambda m: 'I' if m.group(0)[0].isupper() else 'i', w)
    w = re.sub(r'(?i)i{2,}', lambda m: m.group(0)[0], w)
    w = re.sub(r'(?i)o{2,}', lambda m: 'U' if m.group(0)[0].isupper() else 'u', w)
    w = re.sub(r'(?i)u{2,}', lambda m: m.group(0)[0], w)
    # Tanzil's ai for the diphthong: raib, alainaa, shai'in -> rayb, alayna, shay’in
    w = re.sub(r'(?i)a(i)(?=[^aeiou\s-]|$)', lambda m: m.group(0)[0] + ('Y' if m.group(1).isupper() else 'y'), w)
    return w


def recitation(text, source='hand', arabic=None, words=None):
    """One recitation line in the house style.

    source='hand': the app's own lines (a straight ' for both letters; HAMZA_WORDS tells them apart).
    source='hisn': Hisn al-Muslim's import (` is ʿayn, ' is hamza, and ' or ‘ before "l-" marks the
    article's elided hamza: "huwa ‘l-Hayyu", "ash-shaytani 'r-rajim").
    """
    if not text or text.strip('-') == '':
        return text
    if words is None and arabic:
        words = V.arabic_stream(arabic)
    if source == 'hisn' and not re.search(r"[`'\u0100-\u024F\u1E00-\u1EFF]", text):
        # already in the house style: its ‘ are settled, and the Arabic check would reopen them
        return long_vowels(re.sub(r'\bSubha{1,2}nallah', 'SubhanAllah', text), words)
    if source == 'hisn':
        text = text.replace('ḍh', 'd').replace('Ḍh', 'D')          # the import's ض as ḍh
        text = re.sub(r'\bardh(i?)\b', r'ard\1', text)             # and as dh in al-ardh
        text = re.sub(r'(\w)\s+`([aiu])\b', r'\1`\2', text)        # wasi `a: a stray space
    t = text.translate(ARABIC_MARKS)
    if source == 'hisn':
        # the elided article joins the word before it, as it is read
        t = re.sub(r"(\w)\s+['‘’](l|r|n|s|sh|t|th|d|dh|z)-", r'\1\2-', t)
        t = re.sub(r"(?<=[aiu])['‘’](?=(?:l|r|n|s|sh|t|th|d|dh|z)-)", '', t)   # huwal-`Aliyyu‘l-`Azim
        t = re.sub(r"(\w)\s+['‘’](l|r|n|s|sh|t|th|d|dh|z)(?=[A-Z])", r'\1\2-', t)
        t = t.translate(str.maketrans({'ş': 's', 'Ş': 'S', 'ţ': 't', 'Ţ': 'T', 'ḩ': 'h', 'á': 'a', 'í': 'i',
                                       'ú': 'u', 'â': 'a', 'î': 'i', 'û': 'u', 'ẖ': 'h', 'ž': 'z', 'Ž': 'Z'}))
        t = re.sub(r"\s'm-m", ' m', t)                       # maqaman 'm-mahmudan: tanween before m
        # a mark before two consonants is the elided hamza of the next word: Allahumma'ghfir
        c = r'(?:th|kh|dh|sh|gh|(?![tkdsg]h)[bcdfghjklmnpqrstvwxyz])'
        t = re.sub(r"(?<=[A-Za-z])['‘’](?=" + c + c + ')', '', t)
        # an apostrophe between two consonants only kept letters apart: wagh'fir, thabbit'h
        t = re.sub(r"am['‘’]m", 'an m', t)
        t = re.sub(r"(?<=[tkdsg])['‘’](?=h)", '-', t)
        t = re.sub(r"(?<=[bcdfghjklmnpqrstvwxyz])['‘’](?=[bcdfghjklmnpqrstvwxyz])", '', t)
        t = re.sub(r'Allahum-ma', 'Allahumma', t)
        # a word whose opening vowel is elided joins the word before it: wa ‘llahu, Allahumma ‘ghfir
        t = re.sub(r"(\w)\s+['‘](?=[bcdfghjklmnpqrstvwxyz])", r'\1', t)
        t = t.replace('`', '\x01')     # the import's sure ʿayn; ‘ and ' are read off the Arabic below
        t = re.sub(r"(?<=[A-Za-z])'(?=[A-Za-z])", '’', t)  # hamza inside a word
        t = re.sub(r"(?<=[A-Za-z])'(?=[\s,.;:!?)]|$)", '’', t)
        t = re.sub(r"(^|[\s(])[’](?=[A-Za-z])", r'\1', t)  # no hamza written at a word's start
    else:
        def fix(m):
            w = m.group(0)
            low = w.lower()
            if low in RECITE_WORDS:
                return match_case(w, RECITE_WORDS[low])
            if '-' in w and any(p.lower() in RECITE_WORDS for p in w.split('-')):
                return '-'.join(fix(re.match(r'.*', p, re.S)) if p else p for p in w.split('-'))
            if low in MIXED:
                marks = iter([c for c in MIXED[low] if c in '‘’'])
                return ''.join(next(marks) if c == "'" else c for c in w)
            mark = '’' if low in HAMZA_WORDS else '‘'
            return w.replace("'", mark).replace('`', '‘')
        t = re.sub(r"[A-Za-z'‘’`]+(?:-[A-Za-z'‘’`]+)*", fix, t)
    # long vowels single, word by word (an English sentence inside a Hisn line keeps its words)
    arabic_too = {'fee', 'feeh', 'feehi', 'bee', 'lee', 'mee', 'see'}

    def vowels(m):
        w = m.group(0)
        if source == 'hisn' and english(w) and w.lower() not in arabic_too:
            return w
        return _single_vowels(w)
    t = re.sub(r"[A-Za-z‘’]+", vowels, t)
    if source == 'hisn':
        t = hisn_marks(t, arabic or '')
    # Allah keeps its capital inside the glorification, as the Dhikr rows write it
    t = re.sub(r'\bSubhanallah', 'SubhanAllah', t)
    return long_vowels(t.replace('\x01', '‘'), words)


# --- long vowels in a recitation line ------------------------------------------------------------

RECITE_WORD = re.compile(r"[A-Za-z‘’']+")
# Arabic words of the lines that the English word list also carries
ARABIC_IN_DICT = {'nar', 'kafirin', 'kana', 'amin', 'mali', 'ansar', 'hakim', 'malik', 'tabu', 'ati', 'darr', 'kitab',
                  'mannan', 'sha', 'din', 'ada', 'kan'}
ALIGNED = 0.4      # a line whose Arabic fits it worse than this (per letter) takes only the settled words
# what no alignment can see: the import's own slips (th for dh, a stray ‘), and the lengths a shaddah or
# a diphthong rules out
RECITE_FIXUPS = [(r'ee(?=yy)', 'i'), (r'oo(?=ww)', 'u'), (r'aa(?=[yw](?:[’‘bcdfghjklmnpqrstvxz]|\b))', 'a'),
                 (r'\bDaawud\b', 'Daawood'), (r'(?<![A-Za-z])‘(a‘oodhu|ilaaha)', r'\1'), (r'\ba‘oothu', 'a‘oodhu'),
                 (r'\bu‘eethukuma', 'u‘eedhukuma'), (r'\bhaathal-', 'haadhal-'), (r'Sami ‘ul-', 'Samee‘ul-')]


def _apply_settled(orig, settled):
    """orig (single vowels) written with the settled spelling's long vowels."""
    out, j = [], 0
    for c in orig:
        d = V.DOUBLE.get(c.lower())
        if d and settled[j:j + 2] == d and settled[j:j + 1] != settled[j + 2:j + 3]:
            out.append(V.DOUBLE[c] if c in V.DOUBLE else d); j += 2
        else:
            out.append(c); j += 1
    return ''.join(out)


def long_vowels(line, words=None):
    """A recitation line with its long vowels doubled: read off its Arabic where it has one (`words`, a
    stream from transliteration_vowels), then every word held to the spelling the lexicon settled."""
    if not line:
        return line
    english_line = len(_ENGLISH_LINE.findall(line)) >= 3
    skip = set()

    def single(m):
        w = m.group(0)
        bare = w.strip("‘’'")
        if english(bare) and bare.lower() not in ARABIC_IN_DICT and (english_line or len(bare) > 3):
            skip.update(range(m.start(), m.end()))
            return w
        return collapse(w)
    # single vowels first, so a line already written long comes out the same
    t = RECITE_WORD.sub(single, line)
    skip.clear()
    for m in RECITE_WORD.finditer(t):
        bare = m.group(0).strip("‘’'")
        if english(bare) and bare.lower() not in ARABIC_IN_DICT and (english_line or len(bare) > 3):
            skip.update(range(m.start(), m.end()))
    aligned, cost = t, 1.0
    if words:
        pos, cost = V.long_positions(t, words, frozenset(skip) if english_line else frozenset())
        aligned = V.lengthen(t, pos - skip)
    settled = lexicon().get('recite', {})
    res, last = [], 0
    for m, nw in zip(RECITE_WORD.finditer(t), RECITE_WORD.findall(aligned)):
        ow = m.group(0)
        if ow.lower() in settled:
            fin = _apply_settled(ow, settled[ow.lower()])
        elif cost <= ALIGNED:
            fin = nw
        else:
            fin = ow
        res.append(t[last:m.start()]); res.append(fin); last = m.end()
    res.append(t[last:])
    out = ''.join(res)
    for a, b in RECITE_FIXUPS:
        out = re.sub(a, b, out)
    return out


# Hisn al-Muslim's import is not consistent with itself: it writes ` for ʿayn, but also a plain ' for
# some (Allāhummaj'al, bā'id) and none at all for others (alayna, wa an yamini). Each entry carries its
# Arabic, so each mark is read off the letters around it there.

_AR_CLASS = {'ب': 'b', 'ت': 't', 'ط': 't', 'ة': 't', 'ث': 'T', 'ج': 'j', 'ح': 'h', 'ه': 'h', 'خ': 'K', 'د': 'd',
             'ض': 'd', 'ذ': 'D', 'ظ': 'D', 'ر': 'r', 'ز': 'z', 'س': 's', 'ص': 's', 'ش': 'S', 'غ': 'G', 'ف': 'f',
             'ق': 'q', 'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n', 'و': 'w', 'ي': 'y', 'ى': '', 'ا': '', 'ٱ': '',
             'ع': 'A', 'ء': 'H', 'أ': 'H', 'إ': 'H', 'آ': 'H', 'ؤ': 'H', 'ئ': 'H'}
_LAT_CLASS = [('th', 'T'), ('kh', 'K'), ('dh', 'D'), ('sh', 'S'), ('gh', 'G')]


def _arabic_words(arabic):
    out = []
    for w in re.findall(r'[ء-يٱ]+', re.sub(r'[ً-ٰٟۖ-ۭـ]', '', arabic or '')):
        out.append(''.join(_AR_CLASS.get(ch, '') for ch in w))
    return out


def _arabic_variants(words):
    """Each Arabic word, also without its article and one-letter particles (wa-, fa-, bi-, li-, ka-)."""
    out = set()
    for w in words:
        forms = {w}
        for f in list(forms):
            if f[:1] in 'wfblk' and len(f) > 3:
                forms.add(f[1:])
        for f in list(forms):
            if f.startswith('l') and len(f) > 3:
                forms.add(f[1:])          # al- (its alif is dropped already)
        out |= forms
    return out


def _units(part):
    """A Latin word part as units: ('c', class), ('v', ''), ('m', index into the part)."""
    units, i = [], 0
    low = part.lower()
    while i < len(low):
        two = low[i:i + 2]
        hit = next((b for a, b in _LAT_CLASS if two == a), None)
        if hit:
            units.append(('c', hit)); i += 2; continue
        ch = low[i]
        if ch in "‘’'\x01":
            units.append(('m', i))
        elif ch in 'aeiou':
            units.append(('v', ''))
        elif ch.isalpha():
            units.append(('c', ch))
        i += 1
    return units


_CLS = {'z': '[zD]', 'D': '[Dz]'}


def _word_pattern(units, initial_slot=False):
    """A Latin word part as a regex over one Arabic word's letter classes: each consonant (doubled ones
    once, for the shaddah), each mark a captured [AH], each vowel an optional long-vowel letter."""
    out, last = ['^'], None
    if initial_slot:
        out.append('([AH])?')
    elif units and units[0][0] == 'v':
        out.append('H?')                # the alif that carries a word's opening vowel
    for kind, val in units:
        if kind == 'c':
            if val == last:
                continue
            out.append('[wy]?' + _CLS.get(val, re.escape(val)))
            last = val
        elif kind == 'm':
            out.append('[wy]?([AH])'); last = None
        else:
            last = None
    out.append('[wy]?(?:t|h|n)?$')
    return re.compile(''.join(out))


_ENGLISH_LINE = re.compile(r'\b(the|of|to|you|is|he|say|said|then|when|this|that|with|for)\b', re.I)


def hisn_marks(translit, arabic):
    words = _arabic_variants(_arabic_words(arabic))
    if not words:
        return translit
    english_line = len(_ENGLISH_LINE.findall(translit)) >= 3

    def readings(units, initial_slot=False):
        pat = _word_pattern(units, initial_slot)
        found = set()
        for aw in words:
            m = pat.match(aw)
            if m:
                found.add(m.groups())
        return found

    def fix_part(part, last=True):
        if not part or (english_line and english(part.strip("‘’'"))):
            return part
        if not last and len(part) <= 3:
            return part                   # an article joined to the word after it (ad-danasi)
        units = _units(part)
        marks = [u for u in units if u[0] == 'm']
        found = readings(units)
        if marks and len(found) == 1:
            got = next(iter(found))
            chars = list(part)
            for (_, i), kind in zip(marks, got):
                at_start = i == 0
                if chars[i] == '\x01':
                    continue                 # the import's backtick: an ʿayn for certain
                if kind == 'A':
                    chars[i] = '‘'
                elif at_start:
                    chars[i] = ''        # a hamza at a word's start is never written
                else:
                    chars[i] = '’'
            return ''.join(chars)
        if marks:
            # no single Arabic word to read it from. A mark opening the word goes when the Arabic word
            # starts with the letter after it (the article's elided hamza: ‘asqina, 'r-rajim), and the
            # import's straight ' there is a hamza, never written at a word's start.
            if part[0] in "‘'" and readings(units[1:]):
                return part[1:]
            if part[0] == "'":
                return part[1:]
            return part
        # an ʿayn the import left out at a word's start
        if units and units[0][0] == 'v' and (not english(part) or part.lower() in ('an', 'ala', 'ani')):
            got = readings(units, initial_slot=True)
            if got and all(g and g[0] == 'A' for g in got):
                return '‘' + part
        return part

    return re.sub(r"[A-Za-z‘’'\x01]+(?:-[A-Za-z‘’'\x01]+)*",
                  lambda m: '-'.join(fix_part(p, i == len(ps) - 1) for ps in [m.group(0).split('-')]
                                     for i, p in enumerate(ps)), translit)


# ---------------------------------------------------------------------------------------------
# The 99 Names (namesofallah.qpk, mirrored in NamesOfAllahFallback.swift)

NAMES_99 = {
    1: 'Ar-Rahmaan', 2: 'Ar-Raheem', 3: 'Al-Malik', 4: 'Al-Quddoos', 5: 'As-Salaam', 6: 'Al-Mu’min',
    7: 'Al-Muhaymin', 8: 'Al-Azeez', 9: 'Al-Jabbaar', 10: 'Al-Mutakabbir', 11: 'Al-Khaaliq', 12: 'Al-Baari',
    13: 'Al-Musawwir', 14: 'Al-Ghaffaar', 15: 'Al-Qahhaar', 16: 'Al-Wahhaab', 17: 'Ar-Razzaaq', 18: 'Al-Fattaah',
    19: 'Al-Aleem', 20: 'Al-Qaabid', 21: 'Al-Baasit', 22: 'Al-Khaafid', 23: 'Ar-Raafi‘', 24: 'Al-Mu‘izz',
    25: 'Al-Mudhill', 26: 'As-Samee‘', 27: 'Al-Baseer', 28: 'Al-Hakam', 29: 'Al-Adl', 30: 'Al-Lateef',
    31: 'Al-Khabeer', 32: 'Al-Haleem', 33: 'Al-Azeem', 34: 'Al-Ghafoor', 35: 'Ash-Shakoor', 36: 'Al-Aliyy',
    37: 'Al-Kabeer', 38: 'Al-Hafeez', 39: 'Al-Muqeet', 40: 'Al-Haseeb', 41: 'Al-Jaleel', 42: 'Al-Kareem',
    43: 'Ar-Raqeeb', 44: 'Al-Mujeeb', 45: 'Al-Waasi‘', 46: 'Al-Hakeem', 47: 'Al-Wadood', 48: 'Al-Majeed',
    49: 'Al-Baa‘ith', 50: 'Ash-Shaheed', 51: 'Al-Haqq', 52: 'Al-Wakeel', 53: 'Al-Qawiyy', 54: 'Al-Mateen',
    55: 'Al-Waliyy', 56: 'Al-Hameed', 57: 'Al-Muhsi', 58: 'Al-Mubdi', 59: 'Al-Mu‘eed', 60: 'Al-Muhyi',
    61: 'Al-Mumeet', 62: 'Al-Hayy', 63: 'Al-Qayyoom', 64: 'Al-Waajid', 65: 'Al-Maajid', 66: 'Al-Waahid',
    67: 'Al-Ahad', 68: 'As-Samad', 69: 'Al-Qaadir', 70: 'Al-Muqtadir', 71: 'Al-Muqaddim', 72: 'Al-Mu’akhkhir',
    73: 'Al-Awwal', 74: 'Al-Aakhir', 75: 'Az-Zaahir', 76: 'Al-Baatin', 77: 'Al-Waali', 78: 'Al-Muta‘aali',
    79: 'Al-Barr', 80: 'At-Tawwaab', 81: 'Al-Muntaqim', 82: 'Al-Afuww', 83: 'Ar-Ra’oof', 84: 'Maalikul-Mulk',
    85: 'Dhul-Jalaali wal-Ikraam', 86: 'Al-Muqsit', 87: 'Al-Jaami‘', 88: 'Al-Ghaniyy', 89: 'Al-Mughni',
    90: 'Al-Maani‘', 91: 'Ad-Daarr', 92: 'An-Naafi‘', 93: 'An-Noor', 94: 'Al-Haadi', 95: 'Al-Badee‘',
    96: 'Al-Baaqi', 97: 'Al-Waarith', 98: 'Ar-Rasheed', 99: 'As-Saboor',
}


# ---------------------------------------------------------------------------------------------
# The pass over the Islam tab

sys.path.insert(0, str(ROOT / 'Scripts'))

TEACHING = ('iPhone/Islam/Arabic/', 'iPhone/Islam/Tajweed/', 'iPhone/Islam/Qiraat/')
SKIP_FILES = {'iPhone/Islam/Names/NamesOfAllahFallback.swift',
              # the Quran tab's riwayah picker and Qiraat Explorer read these: its names (ad-Duri, Qalun)
              'iPhone/Islam/Qiraat/QiraatProfiles.swift', 'iPhone/Islam/Qiraat/RiwayatColorCode.swift',
              'iPhone/Islam/Library/ProphetFacts.swift'}  # generated: build_prophet_facts.py restyles it
PROTECTED_ARRAYS = re.compile(r'\b(aliases|keywords|names|spellings|tags|terms)\s*:\s*\[\s*$')
PROTECTED_LABELS = re.compile(r'\b(id|key|systemName|systemImage|named|url|lessonID|article|forKey|slug|image|'
                              r'icon|symbol|asset|identifier|tag|door|hadith|quran|resource|withExtension|'
                              r'storageKey|defaultsKey|category|kind|style)\s*:\s*$')
RECITE_LABELS = re.compile(r'\b(transliteration|translit)\s*:\s*$')
LESSON_LABELS = re.compile(r'\b(reading|specimen|example|letters)\s*:\s*$')


def swift_literals(src):
    """(start, end, body) of each string literal body, in order; comments skipped."""
    i, n = 0, len(src)
    while i < n:
        if src.startswith('//', i):
            j = src.find('\n', i); i = n if j < 0 else j; continue
        if src.startswith('/*', i):
            j = src.find('*/', i + 2); i = n if j < 0 else j + 2; continue
        m = re.match(r'(#+)("""|")', src[i:i + 12])
        if m:
            close = m.group(2) + m.group(1)
            s0 = i + len(m.group(0)); e = src.find(close, s0)
            if e < 0: return
            yield s0, e, 'raw'
            i = e + len(close); continue
        if src.startswith('"""', i):
            s0 = j = i + 3
            while True:
                e = src.find('"""', j)
                if e < 0: return
                k, bs = e - 1, 0
                while k >= 0 and src[k] == '\\': bs += 1; k -= 1
                if bs % 2 == 0: break
                j = e + 1
            yield s0, e, 'multi'
            i = e + 3; continue
        if src[i] == '"':
            s0 = j = i + 1
            while j < n:
                ch = src[j]
                if ch == '\\':
                    if j + 1 < n and src[j + 1] == '(':
                        k, d = j + 2, 1
                        while k < n and d:
                            if src[k] == '(': d += 1
                            elif src[k] == ')': d -= 1
                            elif src[k] == '"':
                                k += 1
                                while k < n and src[k] != '"':
                                    if src[k] == '\\': k += 1
                                    k += 1
                            k += 1
                        j = k; continue
                    j += 2; continue
                if ch == '"' or ch == '\n': break
                j += 1
            yield s0, j, 'plain'
            i = j + 1; continue
        i += 1


def _restyle_segments(body, fn):
    """Apply fn to the text of a literal outside its interpolations."""
    out, i = [], 0
    for m in re.finditer(r'\\\(', body):
        if m.start() < i: continue
        k, d = m.end(), 1
        while k < len(body) and d:
            if body[k] == '(': d += 1
            elif body[k] == ')': d -= 1
            k += 1
        out.append(fn(body[i:m.start()])); out.append(body[m.start():k]); i = k
    out.append(fn(body[i:]))
    return ''.join(out)


_WBW = None


def quran_words(ref):
    """The Quran tab's word-by-word transliteration (macrons) of the ayahs a reference names ("7:89",
    "10:85-86"), as a stream: the line is aligned inside it, so a part of an ayah needs no range."""
    global _WBW
    if _WBW is None:
        _WBW = json.loads(lzma.decompress((ROOT / 'Resources/Data/Quran/WordByWord.json.xz').read_bytes()))['tr']
    sura, _, ayahs = ref.partition(':')
    first, _, last = ayahs.partition('-')
    words = []
    for ayah in range(int(first), int(last or first) + 1):
        words += _WBW[sura][ayah - 1]
    return V.macron_stream(words)


def hadith_words(link, ranges):
    """The Arabic words of a narration on the app's shelf ("bukhari:5743", [(37, 52)]), as a stream."""
    import hadith_spans as hs
    slug, _, citation = link.partition(':')
    row = hs.row(slug, citation)
    return V.arabic_stream(hs.words(row.arabic, ranges)) if row is not None else None


def swift_recitation_source(src, s0):
    """The Arabic behind the transliteration literal at s0: its DuaItem's ayah or hadith, or the Arabic
    written beside it."""
    start = max(src.rfind('DuaItem(', 0, s0), src.rfind('CommonDhikr(', 0, s0), src.rfind('(arabicText:', 0, s0))
    if start < 0:
        return None
    head = src[start:s0]
    m = re.search(r'quran: "([0-9:\-]+)"', head)
    if m:
        return quran_words(m.group(1))
    m = re.search(r'hadith: "(\w+:[^"]+)".*?arabic: (\d+)\.\.\.(\d+)', head, re.S)
    if m:
        return hadith_words(m.group(1), [(int(m.group(2)), int(m.group(3)))])
    found = re.findall(r'arabic(?:Text)?: "([^"]+)"', head)
    return V.arabic_stream(found[-1]) if found else None


def restyle_swift(path, rel):
    src = path.read_text()
    teaching = rel.startswith(TEACHING)
    edits = []
    name_rows = [0]
    for s0, e, kind in swift_literals(src):
        body = src[s0:e]
        before = src[max(0, s0 - 80):s0].rstrip('#"')
        if '://' in body or not re.search(r'[A-Za-z]', body):
            continue
        if not re.search(r'\s', body) and re.fullmatch(r'[a-z0-9_:./\-]+', body):
            continue
        if PROTECTED_LABELS.search(before) or PROTECTED_ARRAYS.search(before) or LESSON_LABELS.search(before):
            continue
        tail = src[max(0, s0 - 600):s0]
        lb, rb = tail.rfind('['), tail.rfind(']')
        if lb > rb and PROTECTED_ARRAYS.search(tail[:lb + 1]):
            continue
        # a short lower-case string in an array is something to match (search aliases, the masjid
        # locator's exclusions), not something to read: its variant spellings are the point
        list_element = (lb > rb) or src[max(0, s0 - 40):s0].rstrip('#"').rstrip().endswith((',', '['))
        if list_element and not any(c.isupper() for c in body) and len(body.split()) <= 6:
            continue
        if RECITE_LABELS.search(before):
            if teaching:
                continue
            words = swift_recitation_source(src, s0)
            new = _restyle_segments(body, lambda t: recitation(t, 'hand', words=words))
        else:
            new = _restyle_segments(body, lambda t: prose(t, teaching))
        if rel.endswith('ArabicReadingBank.swift'):
            # the 99 Names rows are the list's own spellings (Al-Maajid, Al-Malik), not the word pass's
            def row(m):
                name_rows[0] += 1
                return f'{m.group(1)}{NAMES_99.get(name_rows[0], m.group(2))}{m.group(3)}'
            new = re.sub(r'^(    name\|[^|\n]*\|[^|\n]*\|)([^|\n]*)(\|)', row, new, flags=re.M)
        if new != body:
            edits.append((s0, e, body, new))
    if edits:
        out = src
        for s0, e, old, new in reversed(edits):
            out = out[:s0] + new + out[e:]
        path.write_text(out)
    return edits


# --- packs ---------------------------------------------------------------------------------

def _xz_json(path):
    return json.loads(lzma.decompress(path.read_bytes()).decode('utf-8'))


def _write_xz_json(path, obj):
    raw = json.dumps(obj, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
    path.write_bytes(lzma.compress(raw, preset=9))


def restyle_hisn(root):
    for c in root.get('categories', []):
        c['label'] = prose(c['label'])
    for c in root.get('collections', []):
        c['label'] = prose(c['label']); c['subtitle'] = prose(c['subtitle'])
    for e in root.get('entries', []):
        e['transliteration'] = recitation(e.get('transliteration', ''), 'hisn', e.get('arabic', ''))
        for k in ('title', 'notes', 'benefits', 'reference'):
            if e.get(k):
                e[k] = prose(e[k])
    return root


def restyle_names_details(root):
    for v in root.get('names', {}).values():
        for k in ('explanation', 'living'):
            if v.get(k):
                v[k] = prose(v[k])
    return root


def restyle_miracles(root):
    for a in root.get('articles', []):
        a['title'] = prose(a['title'])
        for b in a.get('blocks', []):
            # a quote is someone else's words: left as written
            if b.get('kind') != 'quote' and isinstance(b.get('text'), str):
                b['text'] = prose(b['text'])
    return root


def _skeleton(text):
    return re.sub(r'[^a-z]', '', collapse(text.lower()))


def restyle_daily(root, hisn=None):
    """The Reminder of the Day pack: each line read against its own Arabic (an ayah, a hadith's words, the
    entry's Arabic, or the Hisn al-Muslim entry it copies), a Name of Allah written as the list writes it."""
    if hisn is None:
        hisn = _xz_json(ROOT / 'Resources/Data/Islam/HisnDuas.json.xz')
    by_id = {e['id']: e for e in hisn.get('entries', [])}
    for e in root.get('entries', []):
        if e.get('source'):
            e['source'] = prose(e['source'])
        target = str(e.get('target', ''))
        if e.get('type') == 'name' and target.startswith('names:'):
            name = NAMES_99[int(target.split(':')[1])]
            e['tr'] = name
            if e.get('short') and ':' in e['short']:
                e['short'] = name + e['short'][e['short'].index(':'):]
            continue
        if not e.get('tr'):
            continue
        words = None
        if e.get('hadith') and e.get('arWords'):
            rng = e['arWords']
            words = hadith_words(e['hadith'], [tuple(rng)] if isinstance(rng[0], int) else [tuple(x) for x in rng])
        elif e.get('s') and e.get('a'):
            words = quran_words(f"{e['s']}:{e['a']}")
        elif e.get('ar'):
            words = V.arabic_stream(e['ar'])
        elif str(e.get('dua', '')) in by_id:
            entry = by_id[e['dua']]
            # a copy of the Hisn line (an older import of it, its elisions marked ‘l-): the Hisn wording
            import difflib
            if difflib.SequenceMatcher(None, _skeleton(e['tr']), _skeleton(entry.get('transliteration', ''))).ratio() > 0.97:
                e['tr'] = recitation(entry['transliteration'], 'hisn', entry.get('arabic', ''))
                continue
            words = V.arabic_stream(entry.get('arabic', ''))
        e['tr'] = recitation(e['tr'], 'hand', words=words)
    return root


def restyle_name_record(rec):
    rec['transliteration'] = NAMES_99.get(rec['number'], rec['transliteration'])
    for k in ('found', 'meaning', 'desc'):
        if rec.get(k):
            rec[k] = _names_in(prose(rec[k]), rec['number'])
    rec['otherNames'] = [prose(x) for x in rec.get('otherNames', [])]
    return rec


def _names_in(text, number=None):
    """A name of Allah mentioned in passing, spelled as the list spells it: the record's own name (Al-Maajid
    in its own entry, where the word pass would read Al-Majeed), and the two whose last ʿayn was dropped."""
    if number in NAMES_99:
        own = NAMES_99[number]
        text = re.sub(_tol(collapse(own).replace('‘', '')) + '‘?' + r'(?![A-Za-z])', own, text)
    for name in ('An-Naafi‘', 'Ad-Daarr'):
        text = re.sub(_tol(collapse(name).replace('‘', '')) + r'(?![‘A-Za-z])', name, text)
    return text


def restyle_names_pack(path):
    d = bytearray(path.read_bytes())
    (magic, ver, ec, bc, blocks, _r, rc, uc, eo, el, er, fp, res) = struct.unpack_from('<IHBBHHIIIIIQQ', d, 0)
    assert magic == 0x4B505251 and blocks == 0 and ec == 2
    eager = lzma.decompress(bytes(d[eo:eo + el]))
    pos = 0

    def u32():
        nonlocal pos
        v = struct.unpack_from('<I', eager, pos)[0]; pos += 4; return v

    def string():
        nonlocal pos
        n = u32(); v = eager[pos:pos + n].decode('utf-8'); pos += n; return v
    recs = []
    for _ in range(u32()):
        r = {'number': u32(), 'name': string(), 'transliteration': string(), 'found': string(),
             'meaning': string(), 'desc': string()}
        r['otherNames'] = [string() for _ in range(u32())]
        recs.append(restyle_name_record(r))
    assert pos == len(eager)
    out = bytearray(struct.pack('<I', len(recs)))

    def put(sv):
        b = sv.encode('utf-8'); out.extend(struct.pack('<I', len(b))); out.extend(b)
    for r in recs:
        out.extend(struct.pack('<I', r['number']))
        for k in ('name', 'transliteration', 'found', 'meaning', 'desc'):
            put(r[k])
        out.extend(struct.pack('<I', len(r['otherNames'])))
        for x in r['otherNames']:
            put(x)
    comp = lzma.compress(bytes(out), format=lzma.FORMAT_XZ, preset=9)
    header = struct.pack('<IHBBHHIIIIIQQ', magic, ver, ec, bc, 0, 0, len(recs), uc, 48, len(comp), len(out), fp, res)
    path.write_bytes(header + comp)
    return recs


def restyle_names_fallback(path, recs):
    src = path.read_text()
    m = re.search(r'#"""\n(.*?)\n"""#', src, re.S)
    data = json.loads(m.group(1))
    by = {r['number']: r for r in recs}
    for d in data:
        r = by[d['number']]
        for k in ('transliteration', 'found', 'meaning', 'desc', 'otherNames'):
            d[k] = r[k]
    body = json.dumps(data, ensure_ascii=False, separators=(',', ':'))
    path.write_text(src[:m.start(1)] + body + src[m.end(1):])


def restyle_reading_bank(path):
    src = path.read_text()
    n = 0

    def row(m):
        nonlocal n
        n += 1
        return f'{m.group(1)}{NAMES_99[n]}{m.group(3)}'
    out = re.sub(r'^(    name\|[^|\n]*\|[^|\n]*\|)([^|\n]*)(\|)', row, src, flags=re.M)
    assert n == 99, n
    path.write_text(out)


# --- the string catalog ----------------------------------------------------------------------

def _catalog_key(body):
    """A Swift literal body as Xcode keys it: escapes resolved, interpolations as placeholders."""
    body = re.sub(r'\\\((?:[^()]|\([^()]*\))*\)', '\x01', body)
    body = body.replace('\\"', '"').replace('\\n', '\n').replace('\\t', '\t').replace('\\\\', '\\')
    body = re.sub(r'\\u\{([0-9A-Fa-f]+)\}', lambda m: chr(int(m.group(1), 16)), body)
    return body


def rename_catalog_keys(pairs, all_swift_text):
    path = ROOT / 'Resources/Localizable.xcstrings'
    cat = json.loads(path.read_text())
    strings = cat['strings']
    by_pattern = {}
    for k in strings:
        if '%' in k:
            pat = re.sub(r'%(\d+\$)?(lld|ld|d|@|f|\.\d+f|u|llu)', '\x01', k)
            by_pattern.setdefault(pat, []).append(k)
    renamed = 0
    for old_body, new_body in pairs:
        old, new = _catalog_key(old_body), _catalog_key(new_body)
        if old == new:
            continue
        keys = [old] if old in strings and '\x01' not in old else by_pattern.get(old, [])
        for key in keys:
            if key not in strings:
                continue   # renamed already, by an earlier literal with the same words
            if f'"{old_body}"' in all_swift_text:
                continue   # still written somewhere else as it was: that key stays
            placeholders = re.findall(r'%(?:\d+\$)?(?:lld|ld|d|@|f|\.\d+f|u|llu)', key)
            new_key = new
            for ph in placeholders:
                new_key = new_key.replace('\x01', ph, 1)
            if new_key in strings:
                if not strings[new_key].get('localizations') and strings[key].get('localizations'):
                    strings[new_key] = strings[key]
            else:
                strings[new_key] = strings[key]
            del strings[key]
            renamed += 1
    cat['strings'] = dict(sorted(strings.items(), key=lambda kv: kv[0]))
    path.write_text(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ' : ')) + '\n')
    return renamed


def main():
    write = '--write' in sys.argv
    if not write and '--check' not in sys.argv:
        print(__doc__); return
    import tempfile, shutil
    changes = []
    swift_pairs = []
    base = ROOT
    if not write:
        tmp = Path(tempfile.mkdtemp())
        shutil.copytree(ROOT / 'iPhone/Islam', tmp / 'iPhone/Islam')
        base = tmp
    for path in sorted((base / 'iPhone/Islam').rglob('*.swift')):
        rel = str(path.relative_to(base))
        if rel in SKIP_FILES:
            continue
        for s0, e, old, new in restyle_swift(path, rel):
            changes.append((rel, old, new)); swift_pairs.append((old, new))
    if not write:
        for rel, old, new in changes:
            print(f'{rel}\n  - {old[:160]}\n  + {new[:160]}')
        print(f'{len(changes)} strings would change'); return
    all_swift = '\n'.join(p.read_text() for p in (ROOT / 'iPhone').rglob('*.swift'))
    renamed = rename_catalog_keys(swift_pairs, all_swift)
    data = ROOT / 'Resources/Data/Islam'
    for name, fn in (('HisnDuas', restyle_hisn), ('NamesDetails', restyle_names_details),
                     ('Miracles', restyle_miracles), ('DailyReminders', restyle_daily)):
        p = data / f'{name}.json.xz'
        _write_xz_json(p, fn(_xz_json(p)))
    recs = restyle_names_pack(ROOT / 'Resources/Data/namesofallah.qpk')
    restyle_names_fallback(ROOT / 'iPhone/Islam/Names/NamesOfAllahFallback.swift', recs)
    restyle_reading_bank(ROOT / 'iPhone/Islam/Arabic/ArabicReadingBank.swift')
    print(f'{len(changes)} strings restyled in {len({c[0] for c in changes})} files; {renamed} catalog keys renamed;'
          f' 4 packs, the 99 Names, the reading bank')


if __name__ == '__main__':
    main()
