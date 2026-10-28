#!/usr/bin/env python3
"""Read the chain of narrators (isnad) out of every hadith on the app's shelf that carries one, and
ship it as token ranges into that hadith's own Arabic: Resources/Data/Hadith/HadithChains.qpk.

Abu, 2026-10-27: "for each Hadith ... see chain and then we show the chain in Arabic and then write an
image that we can share". The app draws each chain with the isnad diagram (IsnadDiagram.swift): every
narrator exactly as the narration names him, and above him the word by which he received it
(حدثنا, أخبرنا, عن, سمعت). Nothing here copies a hadith: a node is a range of the row's whitespace
tokens (Python's str.split(), which the app mirrors by splitting on whitespace scalars), so the names
on screen are the shelf's own words.

How a chain is read (`parse`): the transmission words mark where each narrator begins; asides between
dashes or tatweels, "يعني ...", "وهو ...", "واللفظ له" and the honorifics are set aside; narrators joined
by "و" after a comma before "قالا/قالوا/كلاهما/جميعا", and "عن X وعن Y", are one generation; a tahwil
(ح) starts another road, and the roads are merged where they meet (`merge`): at the first road's last
narrator found again in the final road, or at the narrator after "كلاهما/جميعا عن". The chain ends at
the Prophet (peace and blessings be upon him) only when the transmission itself names him ("عن النبي",
"قال رسول الله", "أن رسول الله", "سمعت رسول الله"), or when the last narrator's report names him in its
first three words ("قال نهى رسول الله"); otherwise it ends at the last narrator, as written. A chain
that ends "بهذا الإسناد" / "مثله" refers back to the narration before it and is not drawn.

What is NOT drawn, on purpose (precision over coverage: a wrong chain under an authentic hadith is worse
than none): any chain with a piece that is not a name (a stop word, more than eight words), any road
that cannot be merged, and any chain naming someone who appears fewer than three times across all the
chains on the shelf (a misread piece of matn never recurs; a real narrator does). Measured 2026-10-27:
about 70% of al-Bukhari, 50-60% of the other books; every audited sample matched its text.

    python3 Scripts/build_hadith_chains.py            # writes the pack and UnitTests/HadithChainSamples.swift
    python3 Scripts/build_hadith_chains.py --stats    # coverage per book, nothing written

The pack is the app's pack container (the .qpk layout of QuranPack.swift; `write_pack` has the
details): one LZMA block per book, so the app maps the file, reads a header naming the eleven books,
and decompresses a book's chains only when that book opens (2 ms for al-Bukhari's, off the main
thread), then searches them in place. Measured 2026-10-27 against the JSON this replaced: 27-35 ms and
about 3.2 MB for every chain at once became one book at a time, 1.5 MB with all eleven open.

The narrators (Abu, 2026-10-27, later the same day: "click on each person in the chain and see where
else they are mentioned and see how many they are in, how many sahih, daif, etc and how many Hadiths
they narrated and show all of them"; "all chains that are the exact same"; "all of this preprocessed"):
every node of every accepted chain is given a narrator id ("@id" on the node in the code), one id per
distinct name as the shelf writes it (`narrator_key`: the fold above, a leading article and the case
of a leading "أبو" set aside; "أبيه" and the other kin words are a relation, not a person, and get no
id), and every chain whose narrators are exactly another's, generation by generation, shares a
group id with it ("~id" at the end of the code). Resources/Data/Hadith/HadithNarrators.qpk then
carries, per narrator, the name as most often written, how many narrations name him, in how many he
narrates from the Prophet ﷺ himself, in how many he is the compiler's own teacher, the count by grade
(`grade_category`: the verdict words of each grader; the two Sahihs count as sahih, as the
collections are) and by book, and the list of every narration (book, row, role, grade); and, per
group, its members. The app reads a profile and its list; it compares nothing. Names are matched as
written, so a narrator cited two ways (ابن شهاب and الزهري) has two profiles; nothing here guesses
that two spellings are one man.
"""
import json, re, struct, sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "Scripts"))
from islam_packs import Hadith, strip_marks  # noqa: E402
import reblock_packs as packs  # noqa: E402

OUT = ROOT / "Resources/Data/Hadith/HadithChains.qpk"
SAMPLES = ROOT / "UnitTests/HadithChainSamples.swift"

# The books whose rows carry their chains, and who stands at the foot of each: the compiler who says
# the first "حدثنا" (for the Muwatta', its narrator Yahya al-Laythi, who says "حدثني عن مالك").
BOOKS = {
    "bukhari": ("al-Bukhari", "البُخَارِيُّ"),
    "muslim": ("Muslim", "مُسلِمٌ"),
    "abudawud": ("Abu Dawud", "أَبُو دَاوُدَ"),
    "tirmidhi": ("at-Tirmidhi", "التِّرمِذِيُّ"),
    "nasai": ("an-Nasa'i", "النَّسَائِيُّ"),
    "ibnmajah": ("Ibn Majah", "ابنُ مَاجَه"),
    "malik": ("Yahya al-Laythi", "يَحيَى بنُ يَحيَى اللَّيثِيُّ"),
    "darimi": ("ad-Darimi", "الدَّارِمِيُّ"),
    "ahmed": ("Ahmad ibn Hanbal", "أَحمَدُ بنُ حَنبَلٍ"),
    "aladab_almufrad": ("al-Bukhari", "البُخَارِيُّ"),
    "shamail_muhammadiyah": ("at-Tirmidhi", "التِّرمِذِيُّ"),
}
MIN_SEEN = 3

# MARK: - Reading one chain

PUNCT = re.compile(r'[،,:;"“”‏‎.؛۔\'‘’()\[\]{}«»\u2013\u2014\-ـ!?؟]')

def key(tok):
    k = strip_marks(tok)
    k = PUNCT.sub('', k)
    for a in 'أإآٱ': k = k.replace(a, 'ا')
    return k.replace('ى', 'ي').replace('ة', 'ه')

STRONG = {'حدثنا','حدثني','اخبرنا','اخبرني','انبانا','انباني','نبانا','ثنا','حدثناه','حدثنيه','اخبرناه','اخبرنيه',
          'حدثه','اخبره','حدثهم','اخبرهم','حدثاه','حدثتني','اخبرتني','حدثتنا','اخبرتنا','حدثها','اخبرها','حدثهما',
          'سمعت','سمع','سمعنا','سمعا','سمعته','سمعاه','قرات','قرئ','قراه','قرانا',
          'اخبرهما','حدثاه','اخبراه','حدثوه','اخبروه','حدثتهم','اخبرتهم','حدثتهما','اخبرته','حدثته','حدثوهم','حدثونا','اخبرونا'}
for w in list(STRONG): STRONG.add('و' + w); STRONG.add('ف' + w)
ANN = {'عن','ان','انه','انها','انهم','انهما'}
SAY = {'قال','قالت','قالا','قالوا','يقول','تقول','يقولان','يحدث','تحدث','يخبر','يحدثه','فقال','يذكر','ذكر'}
JOINT_END = {'قالا','قالوا','جميعا','كلاهما','كلهم','ثلاثتهم','اربعتهم'}
TAHWIL = {'ح'}
REFERS = {'نحوه','مثله','بمثله','بنحوه','بمعناه'}
ASIDE_START = {'يعني','وهو','هو','وهي','يعنى','ابن'}  # 'ابن' only after a dash
STOP = {'يا','يرويه','يرفعه','رفعه','يبلغ','يبلغه','يبلغ به','وقال','وقالت','يرفع','بلغ','بلغت','بلغني','بلغه','بلغني','بلغنا','بلغهم','كان','كانت','كنا','كنت','اذا','لما','ما','لا','في','الي','من','ثم','قد','هذا','هذه','ذلك','تلك','رجل','رجلا',
        'امراه','صلي','جاء','جاءت','دخل','خرج','سئل','سالت','سال','قلت','فقلت','فقال','يوم','ليله','اتي','اتت','بينما','بينا',
        'مر','رايت','راي','نهي','امر','بعث','كتب','اخذ','قام','جلس','بهذا','بمثله','بمثل','نحوه','مثله','بنحوه','الاسناد',
        'بهذاالاسناد','وزاد','زاد','وذكر','فذكر','بمعناه','معناه','لفظ','واللفظ','حديث','الحديث','نحو','مثل','قيل','اول',
        'عليه','عليها','وسلم','الله','رسول','النبي','نبي','صلي','وهم','انا','نحن','هم','اني','انه','كل','بعض','اذ','حين','حتي'}
STOP_ALLOW_IN_NAME = {'الله'}  # عبد الله, رضي الله handled separately

# "عن عمه، واسع بن حبان": after one of these the comma names him, it does not add a second narrator.
KIN = {'ابيه','عمه','جده','امه','خاله','اخيه','ابنه','مولاه','مولاته','عمته','خالته','اخته','جدته','ابيها','امها','عمها'}
EPITHET = {'زوج','مولي','صاحب','خادم','بنت','ابنه','عم','امراه','ربيب','ربيبه','سفينه','ابن','اخت'}

def prophet_after(keys, i, reach=4):
    """(index where "قال (سمعت|قال)? رسول الله" begins, its verb) within `reach` words of i, or None."""
    for j in range(i + 1, min(len(keys), i + reach + 1)):
        if keys[j] in SAY:
            k = j + 1
            while k < len(keys) and not keys[k]: k += 1
            if k < len(keys) and is_prophet(keys, k): return j, j
            if k < len(keys) and (keys[k] in STRONG or keys[k] in SAY) and is_prophet(keys, k + 1): return j, k
            return None
        if keys[j] in STRONG or keys[j] in ANN: return None
    return None


def is_prophet(keys, i):
    k = keys[i] if i < len(keys) else ''
    nxt = keys[i+1] if i + 1 < len(keys) else ''
    if k in ('النبي', 'للنبي', 'بالنبي'): return 1
    if k in ('رسول', 'برسول', 'لرسول') and nxt.startswith('الله'): return 2
    if k == 'نبي' and nxt == 'الله': return 2
    return 0

def honorific(keys, i):
    """'رضي الله عنه' / 'رضى الله عنهما' / 'صلى الله عليه وسلم' / 'عليه السلام' -> its length."""
    k = keys[i]
    if k in ('رضي',) and i + 2 < len(keys) and keys[i+1] == 'الله' and keys[i+2].startswith('عن'): return 3
    if k == 'صلي' and i + 3 < len(keys) and keys[i+1] == 'الله' and keys[i+2] == 'عليه' and keys[i+3] == 'وسلم': return 4
    if k == 'عليه' and i + 1 < len(keys) and keys[i+1] == 'السلام': return 2
    return 0

DELIMS = ('-', '–', 'ـ')

class Node:
    def __init__(self, first, last, verb):
        self.first, self.last, self.verb = first, last, verb
        self.aside = None
        self.joint = False
        self.beside = False
    def key(self, keys): return ' '.join(k for k in keys[self.first:self.last+1] if k)

def parse(arabic, max_scan=140):
    raw = arabic.split()
    keys = [key(t) for t in raw]
    n = len(raw)
    roads = []            # list of lists of Node (layers may hold several Nodes: joint narrators)
    road = []             # current road: list of layers (list of Node)
    i = 0
    verb = None           # index of the verb before the next name
    prophet_verb = None
    ended = None
    joint_at = {}
    restate = None
    while i < n and i < max_scan:
        k = keys[i]
        if raw[i].strip('‏‎') in DELIMS:
            # an aside between dashes or tatweels: attach it to the last node (an honorific is dropped)
            j = i + 1
            while j < n and raw[j].strip('‏‎') not in DELIMS and j < i + 12: j += 1
            if j < n and raw[j].strip('‏‎') in DELIMS:
                inner = [x for x in keys[i+1:j] if x]
                if road and road[-1] and inner and not honorific(keys, i + 1):
                    road[-1][-1].aside = (i + 1, j - 1)
                i = j + 1; continue
            return None, 'dash'
        if not k:
            i += 1; continue
        h = honorific(keys, i)
        if h:
            i += h; continue
        if k in TAHWIL:
            if road: roads.append(road)
            road = []; verb = None; i += 1; continue
        if k in ('يعني', 'يعنى', 'وهو', 'هو') and road:
            j = i + 1
            while j < n and keys[j] not in STRONG and keys[j] not in ANN and keys[j] not in SAY and j < i + 7: j += 1
            road[-1][-1].aside = (i, j - 1)
            i = j; continue
        if k in ('واللفظ', 'اللفظ'):
            j = i + 1
            while j < n and keys[j] not in STRONG and keys[j] not in ANN and j < i + 6: j += 1
            i = j; continue
        if k in STRONG and k[0] == 'و' and road and verb is None:
            # al-Bukhari's second road without a ح: "حدثنا A حدثنا B وحدثني C حدثنا B ..."
            roads.append(road)
            road = []
        if k in STRONG:
            verb = i; i += 1
            if k in ('قرات','وقرات') and i < n and keys[i] in ('علي',): i += 1
            continue
        if k in ANN:
            if is_prophet(keys, i + 1):
                prophet_verb = i; ended = 'prophet'; break
            verb = i; i += 1; continue
        if k in SAY:
            # who-said-what clause: قال يحيى أخبرنا وقال الآخران حدثنا
            if k == 'قال' and road and i + 2 < n and keys[i+2] in STRONG and keys[i+1] not in STRONG:
                j = i + 3
                if j < n and keys[j] == 'وقال':
                    j += 1
                    while j < n and keys[j] not in STRONG and j < i + 8: j += 1
                    if j < n and keys[j] in STRONG:
                        verb = j; i = j + 1; continue
            nxt = i + 1
            while nxt < n and not keys[nxt]: nxt += 1
            if nxt < n and (keys[nxt] in STRONG):
                i = nxt; continue
            if road and k == 'قال':
                # "كلاهما عن حفص، قال أبو بكر حدثنا حفص بن غياث": one of the narrators gives his exact
                # word, and the name again, in full. Read on, and let the full name replace the short one.
                j = nxt
                while j < n and j < nxt + 4 and keys[j] and keys[j] not in STRONG and keys[j] not in ANN and keys[j] not in SAY:
                    j += 1
                if j < n and keys[j] in STRONG and j > nxt:
                    said_by = ' '.join(keys[nxt:j])
                    if any(' '.join(x for x in keys[m.first:m.last + 1] if x).startswith(said_by) for m in road[-1]) \
                       or (len(road) > 1 and any(' '.join(x for x in keys[m.first:m.last + 1] if x).startswith(said_by) for m in road[-2])):
                        restate = len(road)
                        verb = j; i = j + 1; continue
            if road and nxt < n and keys[nxt] in SAY and not is_prophet(keys, nxt + 1):
                # "أنه قال قال أنس بن مالك": he reports from Anas
                after = nxt + 1
                while after < n and not keys[after]: after += 1
                if after < n and keys[after] not in STOP and keys[after] not in SAY and keys[after] not in ANN:
                    verb = nxt; i = after; continue
            if nxt < n and keys[nxt] in ANN and road:
                if is_prophet(keys, nxt + 1):
                    prophet_verb = nxt; ended = 'prophet'; break
                i = nxt; continue
            if nxt < n and keys[nxt] in SAY and is_prophet(keys, nxt + 1):
                prophet_verb = i; ended = 'prophet'; break
            if nxt < n and is_prophet(keys, nxt):
                prophet_verb = i; ended = 'prophet'; break
            if k in JOINT_END and road:   # قالا حدثنا
                joint_at.setdefault(id(road), len(road))
                i += 1; continue
            if not road and verb is not None:
                i += 1; continue
            ended = 'say'; break
        if is_prophet(keys, i):
            if verb is not None and road and road[-1][-1].last < verb:
                prophet_verb = verb
            ended = 'prophet'; break
        if k in JOINT_END:
            if road: joint_at.setdefault(id(road), len(road))
            i += 1; continue
        # a name: read until the next marker
        if verb is None:
            # "سمعت عمر بن الخطاب على المنبر قال سمعت رسول الله": a few words of circumstance, then
            # the report from the Prophet. The words are an aside on the narrator.
            found = prophet_after(keys, i) if road else None
            if found is not None:
                stop_at, prophet_verb = found
                road[-1][-1].aside = (i, stop_at - 1)
                i = stop_at
                ended = 'prophet'; break
            ended = 'text'; break
        start = i
        names = []
        kinds = ['first']
        verbs_joint = []
        epithet_aside = []
        cur_start = i
        while i < n:
            kk = keys[i]
            if raw[i].strip('‏‎') in DELIMS: break
            if not kk: i += 1; continue
            if kk == 'وعن':
                # "from X, and from Y": a second source beside X, the same generation
                j = i + 1
                while j < n and not keys[j]: j += 1
                names.append((cur_start, i - 1)); cur_start = j; verbs_joint.append(i); kinds.append('an'); i = j; continue
            if is_prophet(keys, i) and i > cur_start and keys[i-1] in EPITHET:
                # the epithet is an aside, not the end of the chain
                names.append((cur_start, i - 2)); aside_from = i - 1
                j = i + is_prophet(keys, i)
                h2 = honorific(keys, j) if j < n else 0
                epithet_aside.append((aside_from, j + h2 - 1))
                i = j + h2
                cur_start = None
                break
            if kk in JOINT_END:
                break
            if kk in STRONG or kk in ANN or kk in SAY or kk in TAHWIL or honorific(keys, i) or is_prophet(keys, i) \
               or kk in ('يعني','يعنى','وهو','هو','واللفظ') or raw[i] in ('-','–'):
                break
            # a second narrator joined by و after a comma: "أبو بكر بن أبي شيبة، وأبو كريب"
            if kk.startswith('و') and i > cur_start and raw[i-1].endswith(('،', ',')) \
               and not (i - cur_start == 1 and keys[cur_start] in KIN) and kk not in ('وكيع','وهب','واصل','وائل','ورقاء','وهيب','واقد','وبرة','وراد'):
                names.append((cur_start, i - 1)); cur_start = i; kinds.append('waw')
            i += 1
        if cur_start is not None:
            names.append((cur_start, i - 1))
        layer = []
        an_seen = 0
        for idx, (a, b) in enumerate(names):
            kind = kinds[idx] if idx < len(kinds) else 'waw'
            node_verb = verb
            if kind == 'an':
                node_verb = verbs_joint[an_seen] if an_seen < len(verbs_joint) else verb
                an_seen += 1
            while b >= a and not keys[b]: b -= 1
            if b >= a:
                node = Node(a, b, node_verb)
                # Only a name joined by "، و" carries the conjunction in its first word.
                node.joint = kind == 'waw'
                node.beside = idx > 0
                layer.append(node)
        if epithet_aside and layer: layer[-1].aside = epithet_aside[0]
        if not layer: return None, 'empty'
        if restate is not None and road and len(layer) == 1:
            full = ' '.join(x for x in keys[layer[0].first:layer[0].last + 1] if x)
            short = road[-1]
            if len(short) == 1:
                short_key = ' '.join(x for x in keys[short[0].first:short[0].last + 1] if x)
                if full.startswith(short_key) or short_key.startswith(full):
                    layer[0].verb = short[0].verb
                    road[-1] = layer
                    restate = None
                    verb = None
                    continue
        restate = None
        road.append(layer)
        verb = None
    if road: roads.append(road)
    if not roads: return None, 'none'
    joints = [joint_at.get(id(r)) for r in roads]
    implied = False
    if ended == 'say':
        j = i + 1
        seen = 0
        while j < n and seen < 3:
            if not keys[j] or honorific(keys, j): j += 1; continue
            if is_prophet(keys, j): implied = True; prophet_verb = i; break
            seen += 1; j += 1
    # a chain that ends "similarly" refers back to the narration before it and has no top of its own
    for j in range(i, min(n, i + 10)):
        if keys[j] in ('بهذا', 'باسناده', 'باسناد', 'الاسناد'): return None, 'refers'
        if keys[j] in REFERS and ended != 'prophet' and not implied: return None, 'refers'
    return {'roads': roads, 'joints': joints, 'prophet': ended == 'prophet' or implied, 'explicit': ended == 'prophet',
            'prophet_verb': prophet_verb, 'ended': ended, 'end_at': i}, 'ok'

def validate(chain, keys, raw):
    """Shape checks; returns reason or None."""
    for road in chain['roads']:
        for layer in road:
            for node in layer:
                ks = [k for k in keys[node.first:node.last+1] if k]
                if not ks or len(ks) > 8: return 'length'
                if any(k in STOP for k in ks if k not in STOP_ALLOW_IN_NAME) and not (len(ks) >= 2 and ks[0] == 'عبد'): return 'stop:' + ' '.join(ks)
    return None


# MARK: - Roads, names and the pack

def norm_name(k):
    """"الليث" and "ليث" are one narrator: compare without a leading article ("الله" keeps its)."""
    return ' '.join(w[2:] if w.startswith('ال') and len(w) > 3 and w != 'الله' else w for w in k.split())


def node_key(node, keys):
    k = ' '.join(k for k in keys[node.first:node.last + 1] if k)
    if node.joint and k.startswith('و'):
        k = k[1:]
    return norm_name(k)


def with_conjunction_key(node, keys):
    return norm_name(' '.join(k for k in keys[node.first:node.last + 1] if k))


GENERIC = {'عبد', 'ابو', 'ابي', 'ابا', 'ابن', 'بن', 'ام', 'بنت', 'مولي'}


NAME_PARTS = {'بن', 'ابن', 'بنت', 'ابي', 'ابو', 'ابا', 'ام', 'عبد'}


def known(name, counts, vocabulary):
    """A narrator met elsewhere: the name recurs among the chains at least MIN_SEEN times, or its
    leading words do ("الحميدي" of "الحميدي عبد الله بن الزبير") and every word after them is a part
    of a name (بن, أبي) or a word found in the names that do recur ("راشد", "الهمداني"). So a word of
    the report that ran on after a name ("نهانا", "يرفعه") never passes. A lone generic word never counts."""
    words = name.split()
    if counts[name] >= MIN_SEEN:
        return True
    for length in range(len(words) - 1, 0, -1):
        prefix = ' '.join(words[:length])
        if length == 1 and prefix in GENERIC:
            continue
        if counts[prefix] >= MIN_SEEN:
            rest = words[length:]
            for k, w in enumerate(rest):
                before = rest[k - 1] if k > 0 else words[length - 1]
                # "ابن نمير وأبو أسامة": a و after a whole name joins a second narrator; after بن it is
                # a name ("عبد الله بن وهب").
                if w.startswith('و') and before not in NAME_PARTS:
                    return False
                if not (w in NAME_PARTS or w in vocabulary):
                    return False
            return True
    return False


def merge(chain, keys):
    """The roads of a tahwil, merged where they meet: (shared layers upward, branches, top verbs) or None."""
    roads, joints = chain['roads'], chain['joints']
    if len(roads) == 1:
        return roads[0], [], []
    final = roads[-1]
    final_keys = [[node_key(n, keys) for n in layer] for layer in final]
    meets = []
    for road in roads[:-1]:
        lk = node_key(road[-1][0], keys)
        m = next((idx for idx, layer in enumerate(final_keys) if lk in layer), None)
        if m is not None:
            meets.append((m, road[:-1], road[-1][0].verb))
        elif joints[-1] is not None:
            m = joints[-1]
            meets.append((m, road, final[m][0].verb if m < len(final) else None))
        else:
            return None
    if len({m for m, _, _ in meets}) != 1:
        return None
    m = meets[0][0]
    shared = final[m:]
    if not shared:
        return None
    branches = [below for _, below, _ in meets] + [final[:m]]
    tops = [verb for _, _, verb in meets] + [shared[0][0].verb]
    if any(not b for b in branches):
        return None
    return shared, branches, tops


def encode_node(node, narrator_id=None):
    s = f"{node.first}.{node.last}.{node.verb}"
    if node.aside:
        s += f".{node.aside[0]}.{node.aside[1]}"
    if node.joint:
        s += "j"
    if narrator_id:
        s += f"@{narrator_id}"
    return s


def encode_layers(layers, ids):
    return '|'.join('+'.join(encode_node(n, ids.get(n)) for n in layer) for layer in layers)


def encode(shared, branches, tops, chain, token_count, ids=None, group=None):
    """"<tokens>:<branch>^<verb>#<branch>^<verb>=<shared>!<prophet verb>~<group>": the row's token count
    (the app skips a chain whose row no longer has it, so a rebuilt pack can never misplace a name),
    then the layers upward, "|" between generations, "+" between narrators of one generation, a node
    "first.last.verb[.aside.aside][j][@narrator]", and last the id of the group of chains this one is
    the same as, when it has one (HadithNarrators.qpk)."""
    ids = ids or {}
    out = f"{token_count}:"
    if branches:
        out += '#'.join(f"{encode_layers(b, ids)}^{'' if t is None else t}" for b, t in zip(branches, tops)) + '='
    out += encode_layers(shared, ids)
    if chain['prophet']:
        out += '!' + ('' if chain['prophet_verb'] is None else str(chain['prophet_verb']))
    if group:
        out += f"~{group}"
    return out


def read_all():
    rows, counts = {}, Counter()
    for slug in BOOKS:
        h = Hadith(slug)
        out = []
        for index in range(len(h.rows)):
            it = h.item(index)
            raw = it.arabic.split()
            keys = [key(t) for t in raw]
            chain, why = parse(it.arabic)
            if chain:
                bad = validate(chain, keys, raw)
                if bad:
                    chain, why = None, bad.split(':')[0]
            if chain and slug == 'malik':
                first = chain['roads'][0][0][0]
                if node_key(first, keys) == 'يحيي':
                    chain['roads'][0] = chain['roads'][0][1:]
                    if not chain['roads'][0]:
                        chain, why = None, 'short'
            if chain:
                merged = merge(chain, keys)
                if merged is None:
                    chain, why = None, 'no-meet'
                else:
                    chain['merged'] = merged
                    for road in chain['roads']:
                        for layer in road:
                            for node in layer:
                                counts[node_key(node, keys)] += 1
            out.append((it, raw, keys, chain, why))
        rows[slug] = out
    return rows, counts


def accepted(rows, counts):
    books, stats = {}, {}
    vocabulary = {w for name, c in counts.items() if c >= MIN_SEEN for w in name.split()}
    for slug, out in rows.items():
        c = Counter()
        codes = {}
        for it, raw, keys, chain, why in out:
            if chain is None:
                c[why] += 1
                continue
            if not chain['prophet'] and chain['ended'] != 'say':
                c['no-end'] += 1
                continue
            if not all(known(node_key(n, keys), counts, vocabulary) for road in chain['roads'] for layer in road for n in layer):
                c['rare'] += 1
                continue
            # "عن عمه، واسع بن حبان": his uncle IS Wasi' ibn Habban, one man, not two. A split stands only
            # when the name without the و is a narrator met elsewhere, and more often than with it.
            if any(n.joint and counts[with_conjunction_key(n, keys)] >= counts[node_key(n, keys)]
                   for road in chain['roads'] for layer in road for n in layer):
                c['apposition'] += 1
                continue
            if sum(len(r) for r in chain['roads']) < 2:
                c['short'] += 1
                continue
            chain['keys'] = keys
            codes[str(it.id_in_book)] = (None, it, raw, chain)
            c['ok'] += 1
        books[slug] = codes
        stats[slug] = (len(out), c)
    return books, stats


# MARK: - The narrators and the chains they share (HadithNarrators.qpk)

NARRATORS_OUT = ROOT / "Resources/Data/Hadith/HadithNarrators.qpk"
NARRATOR_SAMPLES = ROOT / "UnitTests/HadithNarratorSamples.swift"
GRADE_SAHIH, GRADE_HASAN, GRADE_DAIF, GRADE_DIFFER, GRADE_OTHER, GRADE_NONE = range(6)
GRADE_NAMES = ('sahih', 'hasan', "da'if", 'graders differ', 'other', 'none')
ROLE_LINK, ROLE_TOP, ROLE_TEACHER = 0, 1, 2
WEAK = re.compile(r"da'?if|daeef|weak|munkar|mawdu|maudu|fabricat|batil|shadh", re.I)
# "his father", "her mother", "his client": a relation to the narrator before, not a person of his own.
RELATIVE = KIN | {'ابي', 'ابيها', 'امها', 'جدته', 'اخته', 'عمته', 'خالته', 'ابنه', 'ابنته', 'مولاه', 'مولاته', 'زوجها',
                  'زوجته', 'جدها', 'عمها', 'خالها', 'اخيها', 'اخوه', 'جديه', 'ابويه', 'امراته', 'امراه'}
SHARD = 256
BOOK_SLUGS = list(BOOKS)
NARRATOR_RECORD = struct.Struct('<BIBB')
MEMBER_RECORD = struct.Struct('<BI')


def grade_category(slug, grades):
    """One of the six grade counts a narration adds to: the strongest word of each grader's verdict
    ("Hasan Sahih" is sahih, "Mauquf Da'if" is da'if), and "graders differ" when they disagree. The
    two Sahihs carry no grade line by design and count as sahih, as the collections are."""
    if slug in ('bukhari', 'muslim'):
        return GRADE_SAHIH
    if not grades:
        return GRADE_NONE
    found = set()
    for _, verdict in grades:
        if WEAK.search(verdict):
            found.add(GRADE_DAIF)
        elif 'sahih' in verdict.lower():
            found.add(GRADE_SAHIH)
        elif 'hasan' in verdict.lower():
            found.add(GRADE_HASAN)
        else:
            found.add(GRADE_OTHER)
    return found.pop() if len(found) == 1 else GRADE_DIFFER


def narrator_key(k):
    """The identity a node's name is filed under, or None for a relation ("أبيه"): `node_key`'s fold
    with a leading "أبي"/"أبا" read as "أبو", so the case the sentence puts him in does not split him."""
    words = k.split()
    if not words or k in RELATIVE:
        return None
    if words[0] in ('ابي', 'ابا'):
        words[0] = 'ابو'
    return ' '.join(words)


def chain_nodes(chain):
    """Every node of the merged chain with its role: the top generation (who narrates from the Prophet
    ﷺ when the chain reaches him), the compiler's own teachers (the foot of each road), or a link."""
    shared, branches, tops = chain['merged']
    top = shared[-1]
    feet = [b[0] for b in branches] if branches else [shared[0]]
    out = []
    for layers in [shared] + branches:
        for layer in layers:
            role = ROLE_TOP if layer is top else (ROLE_TEACHER if any(layer is foot for foot in feet) else ROLE_LINK)
            for node in layer:
                out.append((node, role))
    return out


def signature(chain, keys):
    """The chain as its people: generations upward, "+" between the narrators of one, the roads after
    the shared part. Two chains with one signature are the same chain, written in whatever words."""
    shared, branches, tops = chain['merged']
    parts = []
    for layers in [shared] + branches:
        parts.append('|'.join('+'.join(sorted(narrator_key(node_key(n, keys)) or node_key(n, keys) for n in layer))
                              for layer in layers))
    return '#'.join(parts)


def annotate(books):
    """Number the narrators and the groups of equal chains, write every chain's code with them, and
    return (narrators, groups): a narrator is {'key', 'name', 'refs': [(book, id, role, grade)], ...},
    a group a list of (book, id)."""
    mentions = Counter()
    forms = defaultdict(Counter)
    by_signature = defaultdict(list)
    for slug, codes in books.items():
        book = BOOK_SLUGS.index(slug)
        for id_text, (_, it, raw, chain) in codes.items():
            keys = chain['keys']
            for node, _ in chain_nodes(chain):
                k = narrator_key(node_key(node, keys))
                if k:
                    mentions[k] += 1
                    forms[k][node_text(raw, node)] += 1
            by_signature[signature(chain, keys)].append((book, int(id_text)))
    ordered = sorted(mentions, key=lambda k: (-mentions[k], k))
    ids = {k: n + 1 for n, k in enumerate(ordered)}
    narrators = [{'id': ids[k], 'key': k, 'name': forms[k].most_common(1)[0][0], 'refs': [], 'from_prophet': 0,
                  'teacher': 0, 'grades': [0] * 6, 'books': [0] * len(BOOK_SLUGS)} for k in ordered]
    groups = sorted((members for members in by_signature.values() if len(members) > 1), key=lambda m: (-len(m), m))
    group_of = {member: n + 1 for n, members in enumerate(groups) for member in members}
    for slug, codes in books.items():
        book = BOOK_SLUGS.index(slug)
        for id_text, (_, it, raw, chain) in codes.items():
            keys = chain['keys']
            grade = grade_category(slug, it.grades)
            node_ids = {}
            roles = {}
            for node, role in chain_nodes(chain):
                k = narrator_key(node_key(node, keys))
                if not k:
                    continue
                node_ids[node] = ids[k]
                # A man met twice on one chain (two roads) is one narration of his, in his higher role.
                roles[ids[k]] = max(roles.get(ids[k], ROLE_LINK), role, key=lambda r: (r == ROLE_TOP, r == ROLE_TEACHER))
            for narrator_id, role in roles.items():
                entry = narrators[narrator_id - 1]
                entry['refs'].append((book, int(id_text), role, grade))
                entry['from_prophet'] += role == ROLE_TOP and chain['prophet']
                entry['teacher'] += role == ROLE_TEACHER
                entry['grades'][grade] += 1
                entry['books'][book] += 1
            shared, branches, tops = chain['merged']
            code = encode(shared, branches, tops, chain, len(raw), node_ids, group_of.get((book, int(id_text))))
            codes[id_text] = (code, it, raw, chain)
    for entry in narrators:
        entry['refs'].sort()
    return narrators, groups


def row_block(entries):
    """A `HadithRowBlock` (HadithChains.swift): u32 ids ascending, u32 offsets (one more than the
    rows) into the payloads, then the payloads back to back."""
    entries = sorted(entries)
    offsets = [0]
    body = bytearray()
    for _, payload in entries:
        body += payload
        offsets.append(len(body))
    return (struct.pack(f'<{len(entries)}I', *(i for i, _ in entries))
            + struct.pack(f'<{len(offsets)}I', *offsets) + bytes(body))


def write_container(path, eager, blocks, records, units):
    """One .qpk (QuranPackContainer): the header, the block table, the LZFSE eager section, the LZMA blocks."""
    eager_blob = packs.encode(packs.CODEC_LZFSE, bytes(eager))
    eager_offset = 48 + 16 * len(blocks)
    cursor = eager_offset + len(eager_blob)
    table, payloads = [], []
    for index, raw in enumerate(blocks):
        blob = packs.encode(packs.CODEC_LZMA, raw)
        table.append(struct.pack('<IIII', index, cursor, len(blob), len(raw)))
        payloads.append(blob)
        cursor += len(blob)
    header = struct.pack(packs.QPK_HEADER, packs.QPK_MAGIC, 1, packs.CODEC_LZFSE, packs.CODEC_LZMA, len(blocks), 0,
                         records, units, eager_offset, len(eager_blob), len(eager), fnv1a64(b''.join(blocks)), 0)
    path.write_bytes(header + b''.join(table) + eager_blob + b''.join(payloads))


def read_container(path):
    """(eager bytes, [raw block bytes], header fields) of a .qpk, through Apple's decoder: what the app reads."""
    data = path.read_bytes()
    fields = struct.unpack_from(packs.QPK_HEADER, data, 0)
    (magic, version, eager_codec, block_codec, block_count, _, records, units, eager_offset, eager_length,
     eager_raw, _, _) = fields
    assert (magic, version, eager_codec, block_codec) == (packs.QPK_MAGIC, 1, packs.CODEC_LZFSE, packs.CODEC_LZMA)
    eager = packs.apple_decode(data[eager_offset:eager_offset + eager_length], eager_raw, packs.COMPRESSION_LZFSE)
    blocks = []
    for index in range(block_count):
        first, offset, length, raw_length = struct.unpack_from('<IIII', data, 48 + 16 * index)
        assert first == index
        blocks.append(packs.apple_decode(data[offset:offset + length], raw_length, packs.COMPRESSION_LZMA))
    return eager, blocks, fields


def narrator_payload(entry):
    name = entry['name'].encode('utf-8')
    out = struct.pack('<I', len(name)) + name
    out += struct.pack('<III', len(entry['refs']), entry['from_prophet'], entry['teacher'])
    out += struct.pack('<6I', *entry['grades'])
    out += struct.pack(f'<B{len(BOOK_SLUGS)}I', len(BOOK_SLUGS), *entry['books'])
    return out


def write_narrators_pack(narrators, groups):
    """HadithNarrators.qpk (QuranPackContainer, QuranPack.swift):

      header (48), block table (16 per block); records = blocks, units = narrators
      eager (LZFSE)   u32 books, then per book: string slug (a ref names its book by this index);
                      u32 narrators, u32 shard size, u32 shards, u32 groups
      block 0 (LZMA)  the narrators: a row block by narrator id (1-based, by mentions descending):
                      string name, u32 narrations, u32 from the Prophet, u32 the compiler's teacher,
                      u32 x 6 by grade (sahih, hasan, da'if, graders differ, other, none),
                      u8 books, u32 narrations per book
      block 1..S      the narrations naming each narrator: a row block by id, shard k holding the ids
                      k*SHARD+1 ... (k+1)*SHARD; a row's payload is its refs, 7 bytes each:
                      u8 book, u32 idInBook, u8 role (0 link, 1 top, 2 the compiler's teacher), u8 grade
      block S+1       the groups of equal chains: a row block by group id (1-based, largest first), a
                      row's payload its members, 5 bytes each: u8 book, u32 idInBook

    Then reads the file back as the app will and checks every row."""
    eager = bytearray(struct.pack('<I', len(BOOK_SLUGS)))
    for slug in BOOK_SLUGS:
        data = slug.encode('utf-8')
        eager += struct.pack('<I', len(data)) + data
    shards = (len(narrators) + SHARD - 1) // SHARD
    eager += struct.pack('<IIII', len(narrators), SHARD, shards, len(groups))
    blocks = [row_block([(e['id'], narrator_payload(e)) for e in narrators])]
    for shard in range(shards):
        members = narrators[shard * SHARD:(shard + 1) * SHARD]
        blocks.append(row_block([(e['id'], b''.join(NARRATOR_RECORD.pack(*ref) for ref in e['refs'])) for e in members]))
    blocks.append(row_block([(n + 1, b''.join(MEMBER_RECORD.pack(*m) for m in members)) for n, members in enumerate(groups)]))
    write_container(NARRATORS_OUT, eager, blocks, len(blocks), len(narrators))
    verify_narrators_pack(narrators, groups)
    return sum(len(b) for b in blocks)


def rows_of(raw, count):
    ids = struct.unpack_from(f'<{count}I', raw, 0)
    offsets = struct.unpack_from(f'<{count + 1}I', raw, 4 * count)
    base = 8 * count + 4
    assert base + offsets[-1] == len(raw)
    return [(ids[n], raw[base + offsets[n]:base + offsets[n + 1]]) for n in range(count)]


def verify_narrators_pack(narrators, groups):
    eager, blocks, fields = read_container(NARRATORS_OUT)
    assert fields[6] == len(blocks) and fields[7] == len(narrators)
    pos = 0
    count = struct.unpack_from('<I', eager, pos)[0]
    pos += 4
    assert count == len(BOOK_SLUGS)
    for slug in BOOK_SLUGS:
        length = struct.unpack_from('<I', eager, pos)[0]
        assert eager[pos + 4:pos + 4 + length].decode('utf-8') == slug
        pos += 4 + length
    total, shard, shards, group_count = struct.unpack_from('<IIII', eager, pos)
    pos += 16
    assert pos == len(eager) and total == len(narrators) and shard == SHARD and group_count == len(groups)
    assert len(blocks) == shards + 2
    table = rows_of(blocks[0], len(narrators))
    for (row_id, payload), entry in zip(table, narrators):
        assert row_id == entry['id'] and payload == narrator_payload(entry), entry['key']
    for k in range(shards):
        members = narrators[k * SHARD:(k + 1) * SHARD]
        for (row_id, payload), entry in zip(rows_of(blocks[1 + k], len(members)), members):
            assert row_id == entry['id'] and len(payload) == 7 * len(entry['refs'])
            assert [NARRATOR_RECORD.unpack_from(payload, 7 * n) for n in range(len(entry['refs']))] == entry['refs']
    for (row_id, payload), members in zip(rows_of(blocks[-1], len(groups)), groups):
        assert [MEMBER_RECORD.unpack_from(payload, 5 * n) for n in range(len(members))] == members


def write_narrator_samples(narrators, groups, books):
    """A few narrators and groups exactly as the pack holds them (HadithNarratorsTests), and the
    narrator ids of a few chains in the order their names stand on the page."""
    picks = [narrators[0], narrators[1], narrators[2], narrators[49], narrators[499], narrators[-1]]
    lines = ['// GENERATED by Scripts/build_hadith_chains.py: do not edit. A few narrators and groups of equal',
             '// chains exactly as HadithNarrators.qpk holds them (HadithNarratorsTests).',
             '', 'enum HadithNarratorSamples {',
             '    struct Ref { let slug: String; let idInBook: Int; let role: Int; let grade: Int }',
             '    struct Narrator { let id: Int; let name: String; let narrations: Int; let fromProphet: Int; let teacher: Int;'
             ' let grades: [Int]; let books: [Int]; let firstRefs: [Ref] }',
             '    struct Group { let id: Int; let members: [(slug: String, idInBook: Int)] }',
             f'    static let narratorCount = {len(narrators)}',
             f'    static let groupCount = {len(groups)}',
             f'    static let books = [{", ".join(json.dumps(s) for s in BOOK_SLUGS)}]',
             '    static let narrators: [Narrator] = [']
    for e in picks:
        refs = ', '.join(f'Ref(slug: "{BOOK_SLUGS[b]}", idInBook: {i}, role: {r}, grade: {g})' for b, i, r, g in e['refs'][:5])
        lines.append(f'        Narrator(id: {e["id"]}, name: {json.dumps(e["name"], ensure_ascii=False)}, narrations: {len(e["refs"])}, '
                     f'fromProphet: {e["from_prophet"]}, teacher: {e["teacher"]}, grades: {e["grades"]}, books: {e["books"]}, '
                     f'firstRefs: [{refs}]),')
    lines += ['    ]', '    static let groups: [Group] = [']
    for n in (0, 1, len(groups) // 2, len(groups) - 1):
        members = ', '.join(f'(slug: "{BOOK_SLUGS[b]}", idInBook: {i})' for b, i in groups[n])
        lines.append(f'        Group(id: {n + 1}, members: [{members}]),')
    lines += ['    ]', '}', '']
    NARRATOR_SAMPLES.write_text('\n'.join(lines), encoding='utf-8')


# MARK: - What the app shows (mirrored in HadithChains.swift; the samples test holds the two together)

STRIP = set('،,‏‎"“”:؛;.')
MARKS = re.compile(r'[ً-ٰٟ]')


def clean(text):
    text = ''.join(ch for ch in text if ch not in STRIP)
    return ' '.join(text.split())


def drop_conjunction(text):
    """"وَحَرْمَلَةُ" -> "حَرْمَلَةُ": the و that joined a second narrator, with its vowel."""
    if text.startswith('و') or text.startswith('ف'):
        rest = text[1:]
        i = 0
        while i < len(rest) and MARKS.match(rest[i]):
            i += 1
        return rest[i:]
    return text


def verb_text(raw, index):
    """The word of transmission, without the و or ف that joins it to the sentence ("وَحَدَّثَنَا",
    "فَقَالَ"): no word of transmission begins with either letter."""
    text = clean(raw[index]) if index is not None and 0 <= index < len(raw) else ''
    return drop_conjunction(text)


def node_text(raw, node):
    text = clean(' '.join(raw[node.first:node.last + 1]))
    return drop_conjunction(text) if node.joint else text


def aside_text(raw, node):
    return clean(' '.join(raw[node.aside[0]:node.aside[1] + 1])) if node.aside else ''


def layers_top_down(raw, code_parts):
    """(title, [names]) top to bottom, the compiler left out: what the samples test compares."""
    shared, branches, tops, chain = code_parts
    def column(layers, top_verb):
        out = []
        for i, layer in enumerate(layers):
            above = layers[i + 1][0].verb if i + 1 < len(layers) else top_verb
            out.append((verb_text(raw, above), [node_text(raw, n) for n in layer]))
        return list(reversed(out))
    top = column(shared, chain['prophet_verb'] if chain['prophet'] else None)
    return top, [column(b, t) for b, t in zip(branches, tops)]


def write_samples(books):
    picks = []
    for slug in ('bukhari', 'muslim', 'abudawud', 'nasai', 'malik', 'tirmidhi'):
        codes = books[slug]
        ids = sorted(codes, key=int)
        linear = [i for i in ids if '=' not in codes[i][0]][:3]
        multi = [i for i in ids if '=' in codes[i][0]][:1]
        joint = [i for i in ids if 'j' in codes[i][0] and i not in linear][:1]
        for i in linear + multi + joint:
            picks.append((slug, i))
    lines = ['// GENERATED by Scripts/build_hadith_chains.py: do not edit. Chains read from the shelf, as the',
             '// app must draw them (HadithChainsTests). Each layer is "verb|name+name", top to bottom.',
             '', 'enum HadithChainSamples {',
             '    struct Sample { let slug: String; let idInBook: Int; let code: String; let top: [String]; let branches: [[String]] }',
             '    static let all: [Sample] = [']
    for slug, i in picks:
        code, it, raw, chain = books[slug][i]
        top, branches = layers_top_down(raw, chain['merged'] + (chain,))
        enc = lambda col: '[' + ', '.join(json.dumps(f"{t}|{'+'.join(ns)}", ensure_ascii=False) for t, ns in col) + ']'
        lines.append(f'        Sample(slug: "{slug}", idInBook: {i}, code: {json.dumps(code)}, top: {enc(top)}, '
                     f'branches: [{", ".join(enc(b) for b in branches)}]),')
    lines += ['    ]', '}', '']
    SAMPLES.write_text('\n'.join(lines), encoding='utf-8')


def fnv1a64(data: bytes) -> int:
    value = 0xcbf29ce484222325
    for byte in data:
        value = ((value ^ byte) * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
    return value


def book_block(codes):
    """One book's block: u32 idInBook per chain (ascending), u32 offset per chain plus one into the codes,
    then the codes (ASCII) back to back. The app binary-searches the ids where they lie."""
    rows = sorted((int(i), v[0].encode('ascii')) for i, v in codes.items())
    offsets = [0]
    for _, code in rows:
        offsets.append(offsets[-1] + len(code))
    return (struct.pack(f'<{len(rows)}I', *(i for i, _ in rows)) + struct.pack(f'<{len(offsets)}I', *offsets)
            + b''.join(code for _, code in rows)), rows


def write_pack(books):
    """HadithChains.qpk, in the app's pack container (QuranPackContainer, QuranPack.swift):

      header (48), block table (16 per book): the .qpk header; records = books, units = chains
      eager (LZFSE)   u32 books, then per book: string slug, string compiler (Arabic), u32 chains
      block n (LZMA)  book n's `book_block`

    Then reads the file back as the app will, Apple's decoder included, and checks every chain."""
    order = [slug for slug in BOOKS if books.get(slug)]
    eager = bytearray(struct.pack('<I', len(order)))
    blocks, expected = [], {}
    for slug in order:
        raw, rows = book_block(books[slug])
        blocks.append(raw)
        expected[slug] = rows
        for text in (slug, BOOKS[slug][1]):
            data = text.encode('utf-8')
            eager += struct.pack('<I', len(data)) + data
        eager += struct.pack('<I', len(rows))
    total = sum(len(rows) for rows in expected.values())
    eager_blob = packs.encode(packs.CODEC_LZFSE, bytes(eager))
    eager_offset = 48 + 16 * len(blocks)
    cursor = eager_offset + len(eager_blob)
    table, payloads = [], []
    for index, raw in enumerate(blocks):
        blob = packs.encode(packs.CODEC_LZMA, raw)
        table.append(struct.pack('<IIII', index, cursor, len(blob), len(raw)))
        payloads.append(blob)
        cursor += len(blob)
    header = struct.pack(packs.QPK_HEADER, packs.QPK_MAGIC, 1, packs.CODEC_LZFSE, packs.CODEC_LZMA, len(blocks), 0,
                         len(order), total, eager_offset, len(eager_blob), len(eager), fnv1a64(b''.join(blocks)), 0)
    OUT.write_bytes(header + b''.join(table) + eager_blob + b''.join(payloads))
    verify_pack(expected)
    return total, sum(len(b) for b in blocks)


def verify_pack(expected):
    data = OUT.read_bytes()
    (magic, version, eager_codec, block_codec, block_count, _, records, units, eager_offset, eager_length,
     eager_raw, _, _) = struct.unpack_from(packs.QPK_HEADER, data, 0)
    assert (magic, version, eager_codec, block_codec) == (packs.QPK_MAGIC, 1, packs.CODEC_LZFSE, packs.CODEC_LZMA)
    assert block_count == records == len(expected) and units == sum(len(r) for r in expected.values())
    eager = packs.apple_decode(data[eager_offset:eager_offset + eager_length], eager_raw, packs.COMPRESSION_LZFSE)
    pos = 4
    assert struct.unpack_from('<I', eager, 0)[0] == len(expected)
    for index, (slug, rows) in enumerate(expected.items()):
        fields = []
        for _ in range(2):
            length = struct.unpack_from('<I', eager, pos)[0]
            fields.append(eager[pos + 4:pos + 4 + length].decode('utf-8'))
            pos += 4 + length
        count = struct.unpack_from('<I', eager, pos)[0]
        pos += 4
        assert fields == [slug, BOOKS[slug][1]] and count == len(rows), (slug, fields, count)
        first, offset, length, raw_length = struct.unpack_from('<IIII', data, 48 + 16 * index)
        raw = packs.apple_decode(data[offset:offset + length], raw_length, packs.COMPRESSION_LZMA)
        ids = struct.unpack_from(f'<{count}I', raw, 0)
        offsets = struct.unpack_from(f'<{count + 1}I', raw, 4 * count)
        base = 8 * count + 4
        assert first == index and base + offsets[-1] == len(raw), slug
        assert list(ids) == [i for i, _ in rows] and list(ids) == sorted(set(ids)), slug
        for n, (_, code) in enumerate(rows):
            assert raw[base + offsets[n]:base + offsets[n + 1]] == code, (slug, ids[n])
    assert pos == len(eager)


def main():
    rows, counts = read_all()
    books, stats = accepted(rows, counts)
    for slug, (n, c) in stats.items():
        print(f"{slug:22} {n:6} drawn={c['ok']:5} ({100 * c['ok'] / n:4.1f}%)  " +
              ' '.join(f'{k}={v}' for k, v in c.most_common(6) if k != 'ok'))
    narrators, groups = annotate(books)
    refs = sum(len(e['refs']) for e in narrators)
    grades = Counter()
    for e in narrators:
        for _, _, _, g in e['refs']:
            grades[g] += 1
    print(f"{len(narrators)} narrators named in {refs} narration mentions; by grade: "
          + ' '.join(f'{GRADE_NAMES[g]}={grades[g]}' for g in range(6)))
    print(f"{len(groups)} groups of equal chains, {sum(len(g) for g in groups)} chains in them, the largest {len(groups[0])}")
    for e in narrators[:8]:
        print(f"   {len(e['refs']):5} {e['name']}  (from the Prophet {e['from_prophet']}, teacher {e['teacher']})")
    if '--stats' in sys.argv:
        return
    total, raw = write_pack(books)
    print(f"{OUT.relative_to(ROOT)}: {total} chains, {raw} -> {OUT.stat().st_size} bytes, read back and verified")
    write_samples(books)
    print(f"{SAMPLES.relative_to(ROOT)} written")
    raw = write_narrators_pack(narrators, groups)
    print(f"{NARRATORS_OUT.relative_to(ROOT)}: {len(narrators)} narrators, {len(groups)} groups, "
          f"{raw} -> {NARRATORS_OUT.stat().st_size} bytes, read back and verified")
    write_narrator_samples(narrators, groups, books)
    print(f"{NARRATOR_SAMPLES.relative_to(ROOT)} written")


if __name__ == '__main__':
    main()
