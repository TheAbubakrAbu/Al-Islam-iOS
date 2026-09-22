#!/usr/bin/env python3
"""Build iPhone/Islam/ArabicReadingBank.swift: the graded word bank behind the Reading Test
(Arabic Alphabet > Reading Test).

WHY A BUILD STEP
----------------
The test asks a learner to choose how a word is READ, so every reading has to be right. None of
them is typed. Each word is cut from the app's own Hafs text (Resources/JSONs-Deprecated/Quran.json)
and read by a strict rule-based reader (`read_word` below) that REFUSES any word outside the small
grammar it was written for. What it accepts is then cross-checked, sound by sound, against the
word-by-word transliteration the app already ships (Resources/Data/Quran/WordByWord.json.xz, the
Quran.com corpus). A word enters the bank only when the two agree. The two schemes differ on
purpose in three places, and the comparison allows exactly those:

  * the corpus never doubles a shaddah letter and never assimilates the article (l-shamsi);
  * it never lengthens the small waaw / yaa of the pronoun (lahu for lahuu);
  * it keeps a hamzat al-wasl's vowel after a prefix (wa-ittaqu for wattaqu).

The Name of Allah is written without its long alif, so no rule can read it: its forms are listed
by hand (`NAME_FORMS`). The seven nouns that open with a hamzat al-wasl take a kasra whatever
their case ending is, which the corpus gets wrong (us'mu): they are listed by hand as well.

READING SCHEME (what the app's letter pages already use, made unambiguous)
    b t th j H kh d dh r z s sh S D T Dh gh f q k l m n h w y
    capital = the heavy twin (S D T Dh) or the deep one (H); ' = hamza; the half ring = 'ayn
    aa ii uu = long vowels; aaaa iiii uuuu = a long vowel under the madd sign, held longer (the
    spelling the app's own letter tables use); a doubled letter = shaddah; a hyphen only splits
    letters that would otherwise read as one sound (as-hala) and marks the article (al-qamaru,
    ash-shamsu).

THE UNMARKED TIERS
    "Without tashkeel" is how Arabic is printed outside the mushaf, so those words must be spelled
    the way ordinary Arabic spells them. The mushaf's spelling differs in places (one laam in the
    word for night, a waaw in the word for prayer), so an unmarked word is kept only when its bare
    spelling is attested in the hadith corpus next door (../Hadith-JSON-Engine/db/by_book).

RUN
    python3 Scripts/build_reading_test.py            # writes the Swift file, prints the report
    python3 Scripts/build_reading_test.py --review   # also writes a readable review file
"""
from __future__ import annotations

import collections
import glob
import json
import lzma
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
NAMES_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "NamesOfAllah.json"
WBW_PACK = ROOT / "Resources" / "Data" / "Quran" / "WordByWord.json.xz"
HADITH_DB = ROOT.parent / "Hadith-JSON-Engine" / "db" / "by_book"
OUT = ROOT / "iPhone" / "Islam" / "ArabicReadingBank.swift"

# --------------------------------------------------------------------------------------------
# The reader
# --------------------------------------------------------------------------------------------

FATHA, DAMMA, KASRA = "\u064E", "\u064F", "\u0650"
FATHATAN, DAMMATAN, KASRATAN = "\u064B", "\u064C", "\u064D"
# This encoding's sequential tanween (the form printed before idgham and ikhfa).
SEQ_FATHATAN, SEQ_DAMMATAN, SEQ_KASRATAN = "\u0657", "\u065E", "\u0656"
SHADDA = "\u0651"
SUKOON = "\u06E1"          # the pronounced sukoon (the head of a khaa)
SILENT = "\u0652"          # in this encoding: the small circle, "written and never read"
DAGGER = "\u0670"
MADDAH = "\u0653"
SMALL_WAW, SMALL_YAA = "\u06E5", "\u06E6"
IQLAB_HIGH, IQLAB_LOW = "\u06E2", "\u06ED"
WASLA = "\u0671"
ALIF, WAW, YAA, MAQSURA, TAA_MARBUTA = "\u0627", "\u0648", "\u064A", "\u0649", "\u0629"
LAM, NOON, HAA, MEEM = "\u0644", "\u0646", "\u0647", "\u0645"
HAMZA_ON_ALIF, HAMZA_UNDER_ALIF = "\u0623", "\u0625"

WAQF = set("\u06D6\u06D7\u06D8\u06D9\u06DA\u06DB\u06DC\u06DE\u06E9")
REJECT = set("\u0640\u0654\u0655\u06E7\u06E8\u06E0\u06E4\u06EA\u06EB\u06EC\u00A0")

AYN = "\u02BF"
CONS = {
    "\u0621": "'", "\u0623": "'", "\u0624": "'", "\u0625": "'", "\u0626": "'",
    "\u0628": "b", "\u062A": "t", "\u062B": "th", "\u062C": "j", "\u062D": "H", "\u062E": "kh",
    "\u062F": "d", "\u0630": "dh", "\u0631": "r", "\u0632": "z", "\u0633": "s", "\u0634": "sh",
    "\u0635": "S", "\u0636": "D", "\u0637": "T", "\u0638": "Dh", "\u0639": AYN, "\u063A": "gh",
    "\u0641": "f", "\u0642": "q", "\u0643": "k", "\u0644": "l", "\u0645": "m", "\u0646": "n",
    "\u0647": "h", "\u0648": "w", "\u064A": "y", "\u0629": "t",
}
VOWEL = {FATHA: "a", DAMMA: "u", KASRA: "i"}
TANWEEN = {FATHATAN: "an", DAMMATAN: "un", KASRATAN: "in",
           SEQ_FATHATAN: "an", SEQ_DAMMATAN: "un", SEQ_KASRATAN: "in"}
STANDARD_TANWEEN = {SEQ_FATHATAN: FATHATAN, SEQ_DAMMATAN: DAMMATAN, SEQ_KASRATAN: KASRATAN}
MARKS = {FATHA, DAMMA, KASRA, SHADDA, SUKOON, SILENT, DAGGER, MADDAH, IQLAB_HIGH, IQLAB_LOW} | set(TANWEEN)
SUN = set("\u062A\u062B\u062F\u0630\u0631\u0632\u0633\u0634\u0635\u0636\u0637\u0638\u0644\u0646")

# ism, ibn, ibnah, imru', imra'ah, ithnaan, ithnataan: keyed on the letters after the wasl alif.
WASL_NOUN_STEMS = ("\u0633\u06E1\u0645", "\u0628\u06E1\u0646", "\u0645\u06E1\u0631", "\u062B\u06E1\u0646")
# The five verbs whose third-letter damma is incidental (the waaw of the plural put it there), so
# they open with a kasra against the rule: imshuu, iqDuu, ibnuu, imDuu (and i'tuu, refused anyway).
WASL_KASRA_EXCEPTIONS = ("\u0645\u06E1\u0634\u064F", "\u0642\u06E1\u0636\u064F", "\u0628\u06E1\u0646\u064F", "\u0645\u06E1\u0636\u064F")


def clean(word: str) -> str:
    """The word as the test shows it: pause signs off, tanween in its standard stacked form."""
    s = "".join(STANDARD_TANWEEN.get(ch, ch) for ch in word if ch not in WAQF)
    return (s.replace(FATHA + IQLAB_HIGH, FATHATAN).replace(DAMMA + IQLAB_HIGH, DAMMATAN)
             .replace(KASRA + IQLAB_LOW, KASRATAN))


def canonical(word: str) -> str:
    """Mark order made uniform (shaddah before its vowel), so string tables can be matched."""
    for v in (FATHA, DAMMA, KASRA, FATHATAN, DAMMATAN, KASRATAN):
        word = word.replace(v + SHADDA, SHADDA + v)
    return word


def units(word: str):
    res = []
    for ch in word:
        if ch in MARKS:
            if not res:
                return None
            res[-1][1].append(ch)
        else:
            res.append([ch, []])
    return [(b, m) for b, m in res]


def join_latin(parts):
    """Concatenate sound pieces, hyphenating where two letters would otherwise read as one digraph."""
    out = ""
    for p in parts:
        if out and p and p[0] == "h" and out[-1] in "tsdkgDT" \
                and not out.endswith(("th", "sh", "dh", "kh", "gh", "Dh")):
            out += "-"
        out += p
    return out


class Reject(Exception):
    pass


_NAME_CORE = LAM + SHADDA + FATHA + HAA
NAME_FORMS = {}
for _mark, _v in VOWEL.items():
    NAME_FORMS[WASLA + LAM + _NAME_CORE + _mark] = "allaah" + _v
    for _pre, _lat in (("\u0648" + FATHA, "wa"), ("\u0641" + FATHA, "fa"),
                       ("\u0628" + KASRA, "bi"), ("\u062A" + FATHA, "ta")):
        NAME_FORMS[_pre + WASLA + LAM + _NAME_CORE + _mark] = _lat + "llaah" + _v
NAME_FORMS[LAM + KASRA + _NAME_CORE + KASRA] = "lillaahi"
NAME_FORMS["\u0648" + FATHA + LAM + KASRA + _NAME_CORE + KASRA] = "walillaahi"
NAME_FORMS["\u0641" + FATHA + LAM + KASRA + _NAME_CORE + KASRA] = "falillaahi"
NAME_FORMS[WASLA + LAM + _NAME_CORE + DAMMA + MEEM + SHADDA + FATHA] = "allaahumma"


def read_word(word: str):
    """(reading, features, syllables) for a cleaned word. Raises Reject outside the grammar.

    `syllables` is the word sounded out: [(arabic, reading)] groups, each opening on a letter that
    carries a vowel and taking the vowel-less letters after it (a sukoon letter, a madd letter, a
    letter never read). It is what the test shows once a question is answered."""
    if any(ch in REJECT for ch in word):
        raise Reject("char")
    canon = canonical(word)
    if canon in NAME_FORMS:
        return NAME_FORMS[canon], {"name-of-allah", "shaddah"}, []

    us = units(word)
    if not us:
        raise Reject("units")
    n = len(us)
    feats = set()
    spans = []             # [first unit, one past the last, reading piece, opens a syllable]
    sun_pending = False    # the article was just read before a sun letter: the next letter is doubled
    prev_vowel = None      # what the previous letter ended on: 'a' | 'i' | 'u' | 'an' | None
    i = 0

    def emit(piece, first, past, opens):
        spans.append([first, past, piece, opens])

    while i < n:
        base, marks = us[i]
        last = i == n - 1

        # ---- hamzat al-wasl -------------------------------------------------------------------
        if base == WASLA:
            if marks:
                raise Reject("wasla marks")
            if i > 1 or (i == 1 and len(us[0][1]) != 1):
                raise Reject("wasla deep")      # only a one-letter prefix may stand before it
            nxt = us[i + 1] if i + 1 < n else None
            if nxt is None:
                raise Reject("wasla last")
            if nxt[0] == LAM:
                after = us[i + 2] if i + 2 < n else None
                if nxt[1] == [SUKOON] and after is not None:
                    feats.add("al-moon")
                    emit(("a" if i == 0 else "") + "l-", i, i + 2, i == 0)
                    prev_vowel = None
                    i += 2
                    continue
                if SHADDA in nxt[1]:
                    # the mushaf writes ONE laam for the article's and the word's own
                    feats.update(("al-sun", "one-laam"))
                    emit("a" if i == 0 else "", i, i + 1, i == 0)
                    sun_pending = True
                    prev_vowel = None
                    i += 1
                    continue
                if nxt[1] == [] and after is not None and SHADDA in after[1]:
                    if after[0] not in SUN:
                        raise Reject("article+shaddah on a moon letter")
                    feats.add("al-sun")
                    emit("a" if i == 0 else "", i, i + 2, i == 0)
                    sun_pending = True
                    prev_vowel = None
                    i += 2
                    continue
                raise Reject("article shape")
            if not (SUKOON in nxt[1] or SHADDA in nxt[1]):
                raise Reject("wasla shape")
            if CONS.get(nxt[0]) == "'":
                # started on, that hamza turns into a madd letter: not a beginner's word
                raise Reject("wasla+hamza")
            feats.add("wasl")
            if i == 0:
                stem = "".join(b + "".join(m) for b, m in us[1:3])
                if stem.startswith(WASL_NOUN_STEMS):
                    v = "i"
                    feats.add("wasl-noun")
                elif canonical(stem).startswith(WASL_KASRA_EXCEPTIONS):
                    v = "i"
                else:
                    third = nxt if SHADDA in nxt[1] else (us[i + 2] if i + 2 < n else None)
                    v = "u" if third is not None and DAMMA in third[1] else "i"
                emit(v, i, i + 1, True)
                feats.add("wasl-" + v)
            else:
                emit("", i, i + 1, False)
            prev_vowel = None
            i += 1
            continue

        # ---- written and never read -----------------------------------------------------------
        if SILENT in marks:
            if marks != [SILENT]:
                raise Reject("silent+")
            if base == ALIF and i > 0 and us[i - 1][0] == WAW and last:
                if us[i - 1][1] not in ([], [MADDAH], [SUKOON]):
                    raise Reject("connected waw")    # a helping damma: not an isolated reading
                feats.add("silent-alif")
                emit("", i, i + 1, False)
                i += 1
                continue
            if base == WAW and i == 1 and prev_vowel == "u" and us[0][0] == HAMZA_ON_ALIF:
                feats.add("silent-waw")
                emit("", i, i + 1, False)
                i += 1
                continue
            raise Reject("silent other")

        # ---- the madd letters, bare -----------------------------------------------------------
        if base == ALIF:
            if i == 0:
                raise Reject("bare alif first")
            if [m for m in marks if m != MADDAH]:
                raise Reject("alif marks")
            if MADDAH in marks:
                feats.add("maddah")
            if prev_vowel == "a":
                emit("aaa" if MADDAH in marks else "a", i, i + 1, False); feats.add("long-a"); prev_vowel = None
            elif prev_vowel == "an":
                emit("", i, i + 1, False)
                prev_vowel = None           # the alif that seats a fathatayn
            else:
                raise Reject("alif after non-fatha")
            i += 1
            continue

        if base == MAQSURA:
            if [m for m in marks if m not in (MADDAH, DAGGER)]:
                raise Reject("maqsura marks")
            if MADDAH in marks:
                feats.add("maddah")
            if prev_vowel == "a":
                emit("aaa" if MADDAH in marks else "a", i, i + 1, False); feats.add("maqsura"); prev_vowel = None
            elif prev_vowel == "an":
                emit("", i, i + 1, False)
                feats.add("maqsura"); prev_vowel = None
            else:
                raise Reject("maqsura after non-fatha")
            i += 1
            continue

        if base in (WAW, YAA) and not [m for m in marks if m != MADDAH]:
            want = "u" if base == WAW else "i"
            if prev_vowel != want:
                raise Reject("bare waw/yaa")
            emit(want * 3 if MADDAH in marks else want, i, i + 1, False)
            feats.add("long-u" if base == WAW else "long-i")
            if MADDAH in marks:
                feats.add("maddah")
            prev_vowel = None
            i += 1
            continue

        if base in (SMALL_WAW, SMALL_YAA):
            want = "u" if base == SMALL_WAW else "i"
            if [m for m in marks if m != MADDAH]:
                raise Reject("small marks")
            if prev_vowel != want or not last:
                raise Reject("small letter place")
            if MADDAH in marks:
                feats.add("maddah")
            emit(want * 3 if MADDAH in marks else want, i, i + 1, False); feats.add("small-letter"); prev_vowel = None
            i += 1
            continue

        if base not in CONS:
            raise Reject("unknown base %04X" % ord(base))

        # ---- a consonant ----------------------------------------------------------------------
        sound = CONS[base]
        if sound == "'":
            if i == 0 and base in (HAMZA_ON_ALIF, HAMZA_UNDER_ALIF):
                feats.add("hamza-initial")
            else:
                feats.add("hamza-seat")
            if i == 0 or (spans and spans[-1][2].endswith("l-")):
                sound = ""          # an opening hamza is not written in the reading (nor after al-)
        if base == TAA_MARBUTA:
            if not last:
                raise Reject("taa marbuta inside")
            feats.add("taa-marbuta")

        ms = list(marks)
        held = MADDAH in ms
        if held:
            if DAGGER not in ms:
                raise Reject("maddah on consonant")
            ms.remove(MADDAH)
            feats.add("maddah")

        if not ms:
            if base == NOON and 0 < i < n - 1 and us[i + 1][0] in CONS and SHADDA not in us[i + 1][1]:
                # ikhfa inside a word: the mushaf leaves the noon bare, and it is still read
                feats.add("bare-noon")
                emit("n", i, i + 1, False)
                prev_vowel = None
                i += 1
                continue
            raise Reject("bare consonant")

        doubled = SHADDA in ms
        if doubled:
            ms.remove(SHADDA)
            feats.add("shaddah")
            if i == 0:
                raise Reject("shaddah on first letter")     # idgham from the word before
        dagger = DAGGER in ms
        if dagger:
            ms.remove(DAGGER)

        lead = ""
        if sun_pending:
            sun_pending = False
            if not doubled:
                raise Reject("sun without shaddah")
            lead = sound + "-"
            doubled = False         # the first copy is the one just written

        if len(ms) != 1:
            raise Reject("marks")
        m = ms[0]
        piece = sound + sound if doubled else sound
        opens = True
        if m in VOWEL:
            v = VOWEL[m]
            piece += v
            prev_vowel = v
            feats.add({"a": "fatha", "i": "kasra", "u": "damma"}[v])
            if dagger:
                if v != "a":
                    raise Reject("dagger after non-fatha")
                piece += "aaa" if held else "a"; feats.add("dagger"); prev_vowel = None
        elif m in TANWEEN:
            if dagger:
                raise Reject("dagger+tanween")
            t = TANWEEN[m]
            tail = us[i + 1:]
            if t == "an":
                ok = (not tail) or (len(tail) == 1 and tail[0][0] in (ALIF, MAQSURA) and not tail[0][1])
            else:
                ok = not tail
            if not ok:
                raise Reject("tanween inside")
            piece += t
            prev_vowel = "an" if t == "an" else None
            feats.add("tanween")
        elif m == SUKOON:
            if dagger or doubled:
                raise Reject("sukoon+")
            if base in (WAW, YAA) and prev_vowel == "a":
                feats.add("leen")
            else:
                feats.add("sukoon-other")
            prev_vowel = None
            feats.add("sukoon")
            opens = False
        else:
            raise Reject("mark %04X" % ord(m))
        if lead:
            spans[-1][2] += lead        # ash- belongs to the article it was read from
        emit(piece, i, i + 1, opens)
        i += 1

    if sun_pending:
        raise Reject("dangling sun")
    latin = join_latin([s[2] for s in spans])
    if not latin or latin.endswith("-"):
        raise Reject("empty")

    # ---- sounded out --------------------------------------------------------------------------
    groups = []            # [[first unit, one past the last, [pieces]]]
    for first, past, piece, opens in spans:
        if opens or not groups:
            if groups and not any(g_opens for g_opens in groups[-1][3]):
                # nothing in the group so far carries a vowel (a sun-letter article): keep filling it
                groups[-1][1] = past; groups[-1][2].append(piece); groups[-1][3].append(opens)
                continue
            groups.append([first, past, [piece], [opens]])
        else:
            groups[-1][1] = past; groups[-1][2].append(piece); groups[-1][3].append(opens)
    syllables = []
    for first, past, pieces, _ in groups:
        arabic = "".join(b + "".join(m) for b, m in us[first:past])
        syllables.append((arabic, join_latin(pieces)))
    return latin, feats, syllables


def pausal(latin: str, feats) -> str:
    """How the word is read when the reader STOPS on it."""
    if "taa-marbuta" in feats:
        for end in ("tan", "tin", "tun", "ta", "ti", "tu"):
            if latin.endswith(end):
                return latin[: -len(end)] + "h"
        return latin
    if "small-letter" in feats:
        return latin.rstrip(latin[-1])       # lahuu -> lah, bihii -> bih (and the held bihiiii)
    if latin.endswith("an") and "tanween" in feats:
        return latin[:-2] + "aa"
    if latin.endswith(("un", "in")) and "tanween" in feats:
        return latin[:-2]
    if latin.endswith(("aa", "ii", "uu")):
        return latin
    if latin[-1] in "aiu":
        return latin[:-1]
    return latin


# --------------------------------------------------------------------------------------------
# The cross-check against the shipped word-by-word transliteration
# --------------------------------------------------------------------------------------------

QDC_MAP = {"ā": "aa", "ī": "ii", "ū": "uu", "ḥ": "H", "ṣ": "S", "ḍ": "D", "ṭ": "T", "ẓ": "Dh",
           "ʿ": AYN, "ʾ": "'", "Ā": "aa", "Ī": "ii", "Ū": "uu", "Ḥ": "H", "Ṣ": "S", "Ḍ": "D",
           "Ṭ": "T", "Ẓ": "Dh", "o": "u"}
DIGRAPHS = ("th", "sh", "dh", "kh", "gh", "Dh")


def latin_tokens(s: str):
    out, i = [], 0
    while i < len(s):
        if s[i:i + 2] in DIGRAPHS:
            out.append(s[i:i + 2]); i += 2
        else:
            out.append(s[i]); i += 1
    return out


def loose(s: str) -> str:
    """Doubling, separators and hamza marks off: what the two schemes must still agree on."""
    out = []
    for t in latin_tokens(s.replace("-", "").replace("'", "")):
        if out and out[-1] == t and t not in "aiu":
            continue
        if t in "aiu" and out[-2:] == [t, t]:
            continue                        # aaaa (the madd sign) is the corpus's plain long vowel
        out.append(t)
    return "".join(out)


def qdc_norm(s: str) -> str:
    return "".join(QDC_MAP.get(ch, ch) for ch in s)


def agrees(latin: str, feats, qdcs) -> bool:
    if "name-of-allah" in feats:
        return True
    article = "al-sun" in feats or "al-moon" in feats
    if article and "one-laam" not in feats:
        head, _, stem = latin.partition("-")
        # head is al / aX / wal / waX: what stands before the article is all but its last two letters
        # at the start of the word (a + l), or its last one after a prefix
        pre = "" if head[0] == "a" and len(latin_tokens(head)) == 2 else head[: -len(latin_tokens(head)[-1])]
        mine = loose(pre + stem)
    else:
        mine = loose(latin)
    for q in qdcs:
        qn = qdc_norm(q)
        if article and "one-laam" not in feats:
            h, sep, st = qn.partition("-")
            if not sep:
                continue
            if h in ("l", "al"):
                h = ""
            elif h.endswith("l"):
                h = h[:-1]
            theirs = loose(h + st)
        elif "wasl" in feats and "wasl-i" not in feats and "wasl-u" not in feats:
            theirs = loose(re.sub(r"-[iu]", "", qn, count=1))      # wa-ittaqu -> wattaqu
        elif "one-laam" in feats:
            theirs = loose(re.sub(r"-a(?=l)", "", qn, count=1))    # wa-alladhi -> walladhi
        else:
            theirs = loose(qn)
        if theirs == mine:
            return True
        if "small-letter" in feats and theirs == mine[:-1]:
            return True                                           # loose() already folded a held one
        if "wasl-noun" in feats and theirs[1:] == mine[1:]:
            return True                                           # the corpus reads ism as "usmu"
    return False


# --------------------------------------------------------------------------------------------
# Collecting the forms
# --------------------------------------------------------------------------------------------

def load_forms():
    quran = json.loads(QURAN_JSON.read_text())
    wbw = json.loads(lzma.open(WBW_PACK).read())
    forms = collections.OrderedDict()
    for s in quran:
        for a in s["ayahs"]:
            toks = a["textArabic"].split()
            en = wbw["en"][str(s["id"])][a["id"] - 1]
            tr = wbw["tr"][str(s["id"])][a["id"] - 1]
            if len(en) != len(toks):
                sys.exit(f"word-by-word pack out of step at {s['id']}:{a['id']}")
            for k, w in enumerate(toks):
                c = clean(w)
                if not c:
                    continue
                e = forms.get(c)
                if e is None:
                    e = forms[c] = {"count": 0, "ref": f"{s['id']}:{a['id']}", "gloss": en[k], "qdc": set()}
                e["count"] += 1
                if tr[k]:
                    e["qdc"].add(tr[k])
    accepted = collections.OrderedDict()
    refused = collections.Counter()
    disagreed = []
    for w, e in forms.items():
        try:
            latin, feats, syllables = read_word(w)
        except Reject as r:
            refused[str(r)] += 1
            continue
        if not agrees(latin, feats, e["qdc"]):
            disagreed.append((w, latin, sorted(e["qdc"]), e["count"]))
            continue
        e.update(latin=latin, feats=feats, pausal=pausal(latin, feats), letters=len(units(w)), syllables=syllables)
        accepted[w] = e
    for w in [w for w in accepted if is_positional_variant(w, forms)]:
        del accepted[w]
    return quran, forms, accepted, refused, disagreed


def is_positional_variant(w: str, forms) -> bool:
    """True for a spelling that exists only because of the word AFTER it in the ayah.

    The mushaf writes connected speech, so one word turns up in several spellings: with a helping
    vowel before a hamzat al-wasl (quli, mina, humu for qul, min, hum), with the pronoun's long vowel
    dropped before one (lahu, bihi), with the alif maqsurah's dagger dropped before one, and with a
    madd sign when a hamza follows. Read alone, each is its plain twin, and the plain twin is what a
    learner should meet, so the variant is dropped whenever the twin exists."""
    last = w[-1]
    if last in (FATHA, DAMMA, KASRA):
        if w[:-1] + SUKOON in forms:
            return True
        if w[-2:-1] == HAA and (w + SMALL_WAW in forms or w + SMALL_YAA in forms):
            return True
    if last == MAQSURA and w + DAGGER in forms:
        return True
    if MADDAH in w and w.replace(MADDAH, "") in forms:
        return True
    return False


# --------------------------------------------------------------------------------------------
# Tiers
# --------------------------------------------------------------------------------------------

BASIC = {"fatha", "kasra", "damma", "hamza-initial"}
LONG = {"long-a", "long-i", "long-u"}
SMALL = {"dagger", "small-letter", "maqsura"}

# id, the feature(s) a word must show, everything it may show, letter bounds, how many to keep
TIERS = [
    ("spaced",  None,                              BASIC,                                                  (2, 3), 40),
    ("vowels",  None,                              BASIC,                                                  (3, 5), 48),
    ("tanween", {"tanween"},                       BASIC | {"tanween", "taa-marbuta"},                     (2, 5), 40),
    ("long",    LONG,                              BASIC | LONG | {"tanween", "taa-marbuta"},              (2, 6), 56),
    ("small",   SMALL,                             BASIC | LONG | SMALL | {"tanween", "taa-marbuta"},      (2, 6), 48),
    ("leen",    {"leen"},                          BASIC | LONG | SMALL | {"tanween", "taa-marbuta", "leen", "sukoon"}, (2, 6), 40),
    ("sukoon",  {"sukoon-other"},                  BASIC | LONG | SMALL | {"tanween", "taa-marbuta", "leen", "sukoon", "sukoon-other"}, (2, 7), 64),
    ("shaddah", {"shaddah"},                       BASIC | LONG | SMALL | {"tanween", "taa-marbuta", "leen", "sukoon", "sukoon-other", "shaddah"}, (2, 7), 64),
    ("mixed",   {"maddah", "hamza-seat"},          BASIC | LONG | SMALL | {"tanween", "taa-marbuta", "leen", "sukoon", "sukoon-other", "shaddah", "maddah", "hamza-seat"}, (3, 8), 56),
    ("article", {"al-moon", "al-sun", "name-of-allah"}, None,                                              (3, 9), 64),
    ("wasl",    {"wasl"},                          None,                                                   (3, 9), 48),
    ("silent",  {"silent-alif", "silent-waw", "bare-noon"}, None,                                          (3, 8), 48),
]
LATE = {"al-moon", "al-sun", "one-laam", "name-of-allah", "wasl", "wasl-i", "wasl-u", "wasl-noun",
        "silent-alif", "silent-waw", "bare-noon"}
STRIP_MARKS = re.compile("[\u064B-\u065F\u0670\u06E1\u0653]")


def skeleton(word: str) -> str:
    return STRIP_MARKS.sub("", word)


def pick(accepted, used, need, allowed, bounds, limit, *, also_forbid=frozenset()):
    rows = []
    for w, e in accepted.items():
        f = e["feats"]
        if w in used:
            continue
        if need is not None and not (f & need):
            continue
        if allowed is not None and not f <= allowed:
            continue
        if f & also_forbid:
            continue
        if not (bounds[0] <= e["letters"] <= bounds[1]):
            continue
        if len(e["latin"]) > 16:
            continue
        rows.append((w, e))
    rows.sort(key=lambda r: (-r[1]["count"], r[1]["letters"]))
    chosen, per_skeleton = [], collections.Counter()
    for w, e in rows:
        sk = skeleton(w)
        if per_skeleton[sk] >= 2:
            continue
        per_skeleton[sk] += 1
        chosen.append((w, e))
        if len(chosen) == limit:
            break
    return chosen


def build_tiers(accepted):
    tiers, used = collections.OrderedDict(), set()
    for tier_id, need, allowed, bounds, limit in TIERS:
        forbid = frozenset()
        if tier_id == "article":
            forbid = frozenset({"wasl", "silent-alif", "silent-waw", "bare-noon"})
        elif tier_id == "wasl":
            forbid = frozenset({"silent-waw", "bare-noon"})
        # The letter-by-letter tier and the joined tier teach the same words on purpose (the second is
        # the first with the spaces closed, plus longer ones), so "vowels" picks from everything.
        chosen = pick(accepted, set() if tier_id == "vowels" else used, need, allowed, bounds, limit, also_forbid=forbid)
        tiers[tier_id] = chosen
        used.update(w for w, _ in chosen)
    return tiers


def stops_cleanly(e) -> bool:
    """False where stopping does more than drop the ending (huwa -> huu, liya -> lii)."""
    return not e["pausal"].endswith(("uw", "iy"))


def build_waqf(accepted, tiers):
    """Words whose stopped reading differs from the written one, a spread of every ending."""
    seen, pool = set(), []
    for rows in tiers.values():
        for w, e in rows:
            if w in seen or e["pausal"] == e["latin"] or not stops_cleanly(e):
                continue
            seen.add(w)
            pool.append((w, e))
    kinds = collections.OrderedDict((k, []) for k in ("taa", "an", "un-in", "silah", "vowel"))
    for w, e in pool:
        f, latin = e["feats"], e["latin"]
        if "taa-marbuta" in f:
            kinds["taa"].append((w, e))
        elif "small-letter" in f:
            kinds["silah"].append((w, e))
        elif "tanween" in f and latin.endswith("an"):
            kinds["an"].append((w, e))
        elif "tanween" in f:
            kinds["un-in"].append((w, e))
        else:
            kinds["vowel"].append((w, e))
    # taa marbuutah words are rare in the tiers above: top them up straight from the accepted set
    have = {w for w, _ in kinds["taa"]}
    extra = [(w, e) for w, e in accepted.items()
             if "taa-marbuta" in e["feats"] and w not in have and not (e["feats"] & LATE) and e["letters"] <= 6]
    extra.sort(key=lambda r: -r[1]["count"])
    kinds["taa"] += extra[:12]
    out = []
    # the plain-vowel kind is where ayat end: whole words, not two-letter particles
    kinds["vowel"] = [(w, e) for w, e in kinds["vowel"] if e["letters"] >= 4]
    for kind, quota in (("taa", 12), ("an", 10), ("un-in", 10), ("silah", 6), ("vowel", 18)):
        rows = sorted(kinds[kind], key=lambda r: -r[1]["count"])[:quota]
        out += rows
    return out


# --------------------------------------------------------------------------------------------
# Short ayat, read connectedly
# --------------------------------------------------------------------------------------------

def build_phrases(quran, accepted, limit=44):
    rows = []
    for s in quran:
        for a in s["ayahs"]:
            raw = a["textArabic"].split()
            if not (2 <= len(raw) <= 5):
                continue
            words = [clean(w) for w in raw]
            if any(w not in accepted for w in words):
                continue
            ok, latin = True, []
            for k, w in enumerate(words):
                e = accepted[w]
                is_last = k == len(words) - 1
                # a tanween that is not printed in its stacked (izhaar) form blends into the next word
                if not is_last and any(ch in raw[k] for ch in (SEQ_FATHATAN, SEQ_DAMMATAN, SEQ_KASRATAN, IQLAB_HIGH, IQLAB_LOW)):
                    ok = False; break
                if is_last and not stops_cleanly(e):
                    ok = False; break
                reading = e["pausal"] if is_last else e["latin"]
                if k > 0 and w.startswith(WASLA):
                    before = latin[-1]
                    # The wasl alif drops only after a SHORT vowel: a long vowel would shorten and a
                    # sukoon would need a helping vowel, neither of which a beginner should be marked
                    # on. Only the article and the Name: a verb read without its opening vowel
                    # ("qaala dkhuluu") is right and unreadable.
                    if not (e["feats"] & {"al-moon", "al-sun", "name-of-allah"}):
                        ok = False; break
                    if before.endswith(("aa", "ii", "uu")) or before[-1] not in "aiu" \
                            or "tanween" in accepted[words[k - 1]]["feats"]:
                        ok = False; break
                    reading = reading[1:]           # al-Hamdu -> l-Hamdu, allaahi -> llaahi
                latin.append(reading)
            if not ok:
                continue
            text = " ".join(words)
            if len(" ".join(latin)) > 44:
                continue
            familiar = s["id"] == 1 or s["id"] >= 78
            rows.append((familiar, s["id"], a["id"], text, " ".join(latin), a["textEnglishSaheeh"]))
    # familiar short surahs first, then a spread from the rest
    rows.sort(key=lambda r: (not r[0], r[1], r[2]))
    familiar = [r for r in rows if r[0]]
    rest = [r for r in rows if not r[0]]
    step = max(1, len(rest) // max(1, limit - min(len(familiar), limit * 2 // 3)))
    chosen = familiar[: limit * 2 // 3] + rest[::step]
    return chosen[:limit], len(rows)


# --------------------------------------------------------------------------------------------
# Without tashkeel
# --------------------------------------------------------------------------------------------

HADITH_STRIP = re.compile("[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]")
HADITH_TOKEN = re.compile("[\u0621-\u063A\u0641-\u064A\u0671]+")


def hadith_lexicon():
    if not HADITH_DB.is_dir():
        sys.exit(f"{HADITH_DB} is missing: the unmarked tiers are validated against it")
    words, text = collections.Counter(), []
    for path in sorted(glob.glob(str(HADITH_DB / "*" / "*.json"))):
        for h in json.loads(pathlib.Path(path).read_text())["hadiths"]:
            bare = HADITH_STRIP.sub("", h.get("arabic") or "")
            toks = HADITH_TOKEN.findall(bare)
            words.update(toks)
            text.append(" ".join(toks))
    return words, "  ".join(text)


def bare_spelling(word: str) -> str:
    """The word as ordinary Arabic prints it: no marks, and a plain alif for the wasl alif."""
    return re.sub("[\u064B-\u065F\u0670\u06E1\u0653\u0652]", "", word).replace(WASLA, ALIF)


# Bare spellings whose everyday reading is NOT the one the accepted Quran forms give: the pronoun
# "I" is written like the Quran's "that we", and its own Quranic spelling carries a mark the reader
# refuses, so the bank would teach the rare reading for the common word.
UNMARKED_TRAPS = {"\u0623\u0646\u0627"}


def build_unmarked(accepted, lexicon, limit=64):
    forbidden = {"dagger", "small-letter", "maddah", "silent-alif", "silent-waw", "bare-noon", "one-laam",
                 "name-of-allah", "wasl"}
    # every stopped reading each bare spelling can have, across ALL accepted words: a spelling with
    # two (alaa / allaa) is left out, so the answer the test calls right is the only one there is
    readings = collections.defaultdict(set)
    for w, e in accepted.items():
        readings[bare_spelling(w)].add(e["pausal"])
    candidates = {}
    for w, e in accepted.items():
        f = e["feats"]
        if f & forbidden or not (3 <= e["letters"] <= 7) or not stops_cleanly(e):
            continue
        if not (f & (LONG | {"maqsura", "leen"})):
            continue                    # a long vowel or a soft letter gives the bare spelling something to read
        bare = bare_spelling(w)
        if bare in UNMARKED_TRAPS or len(readings[bare]) != 1 or lexicon.get(bare, 0) < 25:
            continue
        if bare not in candidates or e["count"] > candidates[bare][1]["count"]:
            candidates[bare] = (w, e)
    rows = []
    for bare, (w, e) in candidates.items():
        # wa-, fa-, bi-, ka-, li- in front of a word the Quran also has on its own (wa-laa, bi-maa):
        # the particle adds nothing to read, and the list is short
        if bare[0] in "\u0648\u0641\u0628\u0643\u0644" and bare[1:] in readings:
            continue
        rows.append((bare, w, e))
    rows.sort(key=lambda r: -(r[2]["count"] + min(lexicon[r[0]], 2000) / 100))
    return rows[:limit]


def build_names(quran):
    rows = []
    for s in quran:
        rows.append(("surah", bare_spelling(s["nameArabic"]), s["nameArabic"], s["nameTransliteration"], s["nameEnglish"]))
    for n in json.loads(NAMES_JSON.read_text()):
        rows.append(("name", bare_spelling(n["name"]), n["name"], n["transliteration"], n["meaning"]))
    return rows


# The spellings are the standard ones; each is CHECKED against the hadith corpus below (a phrase the
# corpus never prints is dropped, loudly), so nothing here is taken on trust.
EVERYDAY = [
    ("بسم الله", "Bismillah", "In the name of Allah"),
    ("الحمد لله", "Alhamdulillah", "All praise is for Allah"),
    ("سبحان الله", "Subhan Allah", "Glory be to Allah"),
    ("الله أكبر", "Allahu Akbar", "Allah is the Greatest"),
    ("لا إله إلا الله", "La ilaha illa Allah", "There is no god but Allah"),
    ("أستغفر الله", "Astaghfirullah", "I seek Allah's forgiveness"),
    ("إن شاء الله", "In sha Allah", "If Allah wills"),
    ("ما شاء الله", "Ma sha Allah", "What Allah has willed"),
    ("السلام عليكم", "As-salamu alaykum", "Peace be upon you"),
    ("وعليكم السلام", "Wa alaykum as-salam", "And upon you be peace"),
    ("جزاك الله خيرا", "Jazak Allahu khayran", "May Allah reward you with good"),
    ("بارك الله فيك", "Barak Allahu feek", "May Allah bless you"),
    ("لا حول ولا قوة إلا بالله", "La hawla wa la quwwata illa billah", "There is no might or power except with Allah"),
    ("إنا لله وإنا إليه راجعون", "Inna lillahi wa inna ilayhi raji'un", "We belong to Allah, and to Him we return"),
    ("صلى الله عليه وسلم", "Salla Allahu alayhi wa sallam", "May Allah send blessings and peace upon him"),
    ("رضي الله عنه", "Radi Allahu anhu", "May Allah be pleased with him"),
    ("سبحان الله وبحمده", "Subhan Allahi wa bihamdih", "Glory and praise be to Allah"),
    ("سبحان الله العظيم", "Subhan Allah al-Adheem", "Glory be to Allah, the Magnificent"),
    ("سبحان ربي العظيم", "Subhana Rabbiyal-Adheem", "Glory be to my Lord, the Magnificent"),
    ("سبحان ربي الأعلى", "Subhana Rabbiyal-A'la", "Glory be to my Lord, the Most High"),
    ("ربنا ولك الحمد", "Rabbana wa lakal-hamd", "Our Lord, and to You is all praise"),
    ("سمع الله لمن حمده", "Sami' Allahu liman hamidah", "Allah hears the one who praises Him"),
    ("الله أعلم", "Allahu a'lam", "Allah knows best"),
    ("أعوذ بالله من الشيطان الرجيم", "A'udhu billahi min ash-shaytan ir-rajeem", "I seek refuge in Allah from Satan, the outcast"),
    ("حسبنا الله ونعم الوكيل", "Hasbuna Allahu wa ni'mal-wakeel", "Allah is enough for us, and the best to rely on"),
    ("اللهم صل على محمد", "Allahumma salli ala Muhammad", "O Allah, send blessings upon Muhammad"),
    ("يرحمك الله", "Yarhamuk Allah", "May Allah have mercy on you"),
]


def build_everyday(corpus_text):
    kept, dropped = [], []
    for arabic, latin, meaning in EVERYDAY:
        (kept if f" {arabic} " in f" {corpus_text} " or arabic in corpus_text else dropped).append((arabic, latin, meaning))
    return kept, dropped


# --------------------------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------------------------

def swift_block(lines):
    body = "\n".join("    " + line.replace("\\", "\\\\").replace('"""', "'''") for line in lines)
    return '"""\n' + body + '\n    """'


def field(s: str) -> str:
    return s.replace("|", "/").replace("\n", " ").strip()


def main():
    review = "--review" in sys.argv
    quran, forms, accepted, refused, disagreed = load_forms()
    tiers = build_tiers(accepted)
    waqf = build_waqf(accepted, tiers)
    phrases, phrase_pool = build_phrases(quran, accepted)
    lexicon, corpus_text = hadith_lexicon()
    unmarked = build_unmarked(accepted, lexicon)
    names = build_names(quran)
    everyday, dropped = build_everyday(corpus_text)

    def sounded(e):
        return " ".join(f"{a}={l}" for a, l in e["syllables"])

    word_lines = []
    for tier_id, rows in tiers.items():
        for w, e in rows:
            word_lines.append("|".join([tier_id, w, e["latin"], e["pausal"], e["ref"], field(e["gloss"]), sounded(e)]))
    for w, e in waqf:
        word_lines.append("|".join(["waqf", w, e["latin"], e["pausal"], e["ref"], field(e["gloss"]), sounded(e)]))
    phrase_lines = ["|".join([text, latin, f"{s}:{a}", field(english)]) for _, s, a, text, latin, english in phrases]
    unmarked_lines = ["|".join([bare, e["pausal"], w, e["ref"], field(e["gloss"]), sounded(e)]) for bare, w, e in unmarked]
    name_lines = ["|".join([kind, bare, marked, field(latin), field(meaning)]) for kind, bare, marked, latin, meaning in names]
    everyday_lines = ["|".join([arabic, latin, meaning]) for arabic, latin, meaning in everyday]

    out = f'''// GENERATED by Scripts/build_reading_test.py. Do not edit by hand: rerun the script.
//
// The Reading Test's word bank. Every Quranic word here was cut from the app's own Hafs text, read
// by a strict rule-based reader, and kept only where that reading agrees with the word-by-word
// transliteration the app ships. The unmarked words are kept only where their bare spelling is
// attested in the hadith corpus. See the script's module doc for the rules and the reading scheme.
//
// Words carry the mushaf's own marks: U+06E1 is the sukoon and U+0652 the "never read" circle.
// `ReadingTestText` turns them into whichever sukoon the reader has chosen before they are drawn.

import Foundation

enum ArabicReadingBank {{
    /// tier | word | reading | reading when stopped on | surah:ayah | gloss of that occurrence |
    /// the word sounded out, as "letters=reading" groups (empty for the Name, which no rule reads)
    static let words = {swift_block(word_lines)}

    /// ayah text | connected reading, stopped on the last word | surah:ayah | Saheeh International
    static let ayat = {swift_block(phrase_lines)}

    /// bare spelling | reading (stopped) | the same word with its marks | surah:ayah | gloss | sounded out
    static let unmarked = {swift_block(unmarked_lines)}

    /// kind (surah, name) | bare spelling | with marks | the familiar English spelling | meaning
    static let names = {swift_block(name_lines)}

    /// bare spelling | the familiar English spelling | meaning
    static let everyday = {swift_block(everyday_lines)}
}}
'''
    OUT.write_text(out)

    print(f"forms {len(forms)}  accepted+agreed {len(accepted)}  disagreed {len(disagreed)}  refused {sum(refused.values())}")
    for tier_id, rows in tiers.items():
        print(f"  {tier_id:8s} {len(rows)}")
    print(f"  waqf     {len(waqf)}")
    print(f"  ayat     {len(phrases)} of {phrase_pool} candidates")
    print(f"  unmarked {len(unmarked)}")
    print(f"  names    {len(names)}")
    print(f"  everyday {len(everyday)}" + (f"  DROPPED (not in the hadith corpus): {[d[0] for d in dropped]}" if dropped else ""))
    print(f"wrote {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB)")

    if review:
        path = pathlib.Path(sys.argv[sys.argv.index("--review") + 1]) if len(sys.argv) > sys.argv.index("--review") + 1 else pathlib.Path("reading_test_review.txt")
        with path.open("w") as fh:
            for tier_id, rows in tiers.items():
                fh.write(f"\n== {tier_id} ({len(rows)})\n")
                for w, e in rows:
                    fh.write(f"{w}\t{e['latin']}\t{e['pausal']}\t{e['count']}\t{e['ref']}\t{e['gloss']}\t{sorted(e['qdc'])}\n")
            fh.write(f"\n== waqf ({len(waqf)})\n")
            for w, e in waqf:
                fh.write(f"{w}\t{e['latin']}\t-> {e['pausal']}\n")
            fh.write(f"\n== ayat ({len(phrases)})\n")
            for _, s, a, text, latin, english in phrases:
                fh.write(f"{s}:{a}\t{text}\t{latin}\n")
            fh.write(f"\n== unmarked ({len(unmarked)})\n")
            for bare, w, e in unmarked:
                fh.write(f"{bare}\t{e['pausal']}\t{w}\t{lexicon[bare]}\n")
            fh.write(f"\n== disagreed ({len(disagreed)})\n")
            for row in sorted(disagreed, key=lambda r: -r[3])[:200]:
                fh.write(f"{row}\n")
        print(f"review -> {path}")


if __name__ == "__main__":
    main()
