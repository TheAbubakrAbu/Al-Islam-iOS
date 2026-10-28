#!/usr/bin/env python3
"""Find, for every hadith on the shelf, the other narrations that carry the same text, and the ones
that say nearly the same thing, and ship the answer: Resources/Data/Hadith/SimilarHadiths.qpk.

Abu, 2026-10-27: "Add similar Hadiths option to menu and context menu where it opens a sheet that
analyzes everything and shows exact matches whether that be chain and Arabic or just Arabic (and you
can even look at English I guess but secondary), then similar [ones] where they're not the exact same
but really similar ... make all of this preprocessed and efficient and done so beforehand".

Every comparison happens here, once, over all 17 books (50,884 rows); the app only reads a row's
list. Three tiers, in the order the sheet shows them:

  0  same text and chain  the whole Arabic is the same, vowel marks and punctuation set aside
  1  same text            the words after the chain of narrators are the same, the chain differs
  2  similar wording      the two share enough phrases to be the same narration in other words, or
                          one is wholly inside the other; scored 40-100

How the text is compared (`fold`): each whitespace token loses its vowel and recitation marks, tatweel, punctuation, quote marks and footnote
digits; hamza carriers become a bare alef, final ى becomes ي and ة becomes ه. The honorifics
(صلى الله عليه وسلم, رضي الله عنه, عليه السلام) and عز وجل / تعالى are left out of every comparison,
so a narration is not "different" for carrying one.

Where the chain ends: the isnad parser of Scripts/build_hadith_chains.py (`parse`), which places the
end of the chain for 94% of the main books' rows; a row it cannot read is tried once more with a
leading "وعن" read as "عن" (the compilations' habit: Riyad as-Salihin, Mishkat, Bulugh al-Maram),
and a row still unread keeps its whole text as its "text" (it can then only match tier 0, and tier 2).
A compilation's closing attribution ("رواه مسلم", "متفق عليه", "أخرجه ...") is cut off the text when
it falls in the row's second half, so Riyad's copy of a Muslim narration matches Muslim's text.

Similar wording: a text's word bigrams and trigrams (after the fold, honorifics out). A pair is
"similar" when it shares at least MIN_SHARED_TRIGRAMS trigrams (candidates come from an inverted
index of trigrams, a trigram found in more than SHINGLE_CAP rows being a formula, not a fingerprint)
and at least MIN_SHARED_BIGRAMS bigrams, and its score, the share of the SHORTER text's bigrams found
in the other, is at least MIN_SCORE. The report's opening formula ("قال: قال رسول الله ﷺ") and any
word pair found in more than BIGRAM_CAP rows are left out of the scoring, so a short narration is not
"similar" to every other that opens or ends the same way. The shorter side sets the denominator on purpose: a short
narration quoted whole inside a long one is the same narration. A text of fewer than MIN_WORDS words
(the forty of Shah Waliullah are mostly two to four) is matched instead as a phrase: every row whose
text carries those words in that order, score 100. Each row keeps its best MAX_SIMILAR.

The English translation is a secondary signal only: a match whose English body is the same (letters
and digits, case folded) carries FLAG_SAME_ENGLISH, and nothing is matched on English alone.

What the two share is found here too (Abu, later on 2026-10-27: "I don't want you doing any
calculations when the app is open ... which parts match and highlight the matched parts"): every
record carries the runs of the MATCHED narration's own text to tint, as UTF-16 offsets into it (the
text as the app decodes it, آ in its canonical two parts), so the sheet only paints. Same text and chain: nothing (the whole row is the same). Same text: the
matched row's text after its chain, one run. Similar wording: every word of the matched row that sits
in a two-word run the other narration also carries, neighbouring words joined into one run; pairs,
not single words, so a common word alone ("قال", "الله") never lights up.

    python3 Scripts/build_similar_hadiths.py            # writes the pack and UnitTests/SimilarHadithSamples.swift
    python3 Scripts/build_similar_hadiths.py --stats    # coverage and tier counts per book, nothing written
    python3 Scripts/build_similar_hadiths.py --inspect bukhari:1 muslim:1907   # a row's matches, with their words

The pack is the app's pack container (the .qpk layout of QuranPack.swift, `write_pack`): the eager
section names the books in the catalog's order (a match names its book by that index), and book n's
block holds its rows that have matches, sorted by idInBook: u32 ids, u32 byte offsets (one more than
the rows), then the match records back to back: u8 book index, u32 idInBook, u8 tier, u8 score, u8
flags, then the runs to tint as LEB128 varints: their count, and per run the gap from the end of the
run before (from 0 for the first) and the length, in UTF-16 units. The app maps the file, inflates a book's block when that book opens (off the main thread), and
binary-searches the ids where they lie. Rerun after any .hpk rebuild (the texts, and so the matches,
can change); the samples test holds the pack to what the script found.
"""
import json
import re
import struct
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "Scripts"))
from islam_packs import Hadith  # noqa: E402
import build_hadith_chains as chains  # noqa: E402
import reblock_packs as packs  # noqa: E402

OUT = ROOT / "Resources/Data/Hadith/SimilarHadiths.qpk"
SAMPLES = ROOT / "UnitTests/SimilarHadithSamples.swift"

# The shelf in the catalog's order (HadithCatalogBook.all): a match names its book by this index.
SLUGS = ["bukhari", "muslim", "ibnmajah", "abudawud", "tirmidhi", "nasai", "malik", "ahmed", "darimi",
         "qudsi40", "nawawi40", "shahwaliullah40", "aladab_almufrad", "shamail_muhammadiyah",
         "riyad_assalihin", "mishkat_almasabih", "bulugh_almaram"]

TIER_SAME_ALL, TIER_SAME_TEXT, TIER_SIMILAR = 0, 1, 2
FLAG_SAME_ENGLISH = 1

SHINGLE_CAP = 1000
MIN_SHARED_TRIGRAMS = 2
MIN_SHARED_BIGRAMS = 4
MIN_SCORE = 45
MAX_SIMILAR = 40
MAX_EXACT = 60
MIN_WORDS = 5
PHRASE_CAP = 200
# A word pair in more rows than this is a formula ("رسول الله", "لا اله الا"): no evidence either way.
BIGRAM_CAP = 1500
RECORD = struct.Struct('<BIBBB')


def varint(n):
    out = bytearray()
    while True:
        byte = n & 0x7F
        n >>= 7
        if n:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return bytes(out)


def read_varint(data, pos):
    value, shift = 0, 0
    while True:
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return value, pos
        shift += 7


def pack_record(book, id_in_book, tier, score, flags, runs):
    out = bytearray(RECORD.pack(book, id_in_book, tier, score, flags)) + varint(len(runs))
    end = 0
    for start, length in runs:
        assert start >= end and length > 0, (start, length, end)
        out += varint(start - end) + varint(length)
        end = start + length
    return bytes(out)


def unpack_record(data, pos):
    book, id_in_book, tier, score, flags = RECORD.unpack_from(data, pos)
    pos += RECORD.size
    count, pos = read_varint(data, pos)
    runs, end = [], 0
    for _ in range(count):
        gap, pos = read_varint(data, pos)
        length, pos = read_varint(data, pos)
        runs.append((end + gap, length))
        end += gap + length
    return (book, id_in_book, tier, score, flags, runs), pos


def token_offsets(text):
    """(UTF-16 start, UTF-16 end) of every whitespace token of `text`, as `str.split()` cuts them: the
    offsets the app's attributed text takes."""
    out = []
    start = None
    offset = 0
    for ch in text:
        if ch.isspace():
            if start is not None:
                out.append((start, offset))
                start = None
        elif start is None:
            start = offset
        offset += 1 if ord(ch) <= 0xFFFF else 2
    if start is not None:
        out.append((start, offset))
    return out

# MARK: - The fold (HadithSimilarity.fold in SimilarHadiths.swift is this, character for character)

MARKS = set(range(0x0610, 0x061B)) | set(range(0x064B, 0x0660)) | {0x0670} | set(range(0x06D6, 0x06EE)) | {0x0640}
PUNCT = set(map(ord, '،,:;"“”‏‎.؛۔\'‘’()[]{}«»\u2013\u2014-!?؟*')) | set(map(ord, '0123456789٠١٢٣٤٥٦٧٨٩'))
LETTERS = {0x0623: 'ا', 0x0625: 'ا', 0x0622: 'ا', 0x0671: 'ا', 0x0649: 'ي', 0x0629: 'ه'}
# Said of Allah, of the Prophet and of the Companions: no narration is "different" for carrying these.
DROP = {'عز', 'وجل', 'تعالي', 'وتعالي', 'سبحانه', 'تبارك', 'ﷺ'}
# The words a report opens with ("قال: قال رسول الله ﷺ", "أن النبي ﷺ قال"): left out of the SCORING so a short
# narration is not "similar" to every other one that opens the same way. They stay in the text itself.
LEAD_IN = {'قال', 'قالت', 'قالا', 'قالوا', 'يقول', 'تقول', 'يحدث', 'سمعت', 'سمع', 'ان', 'انه', 'انها', 'انهم', 'عن',
           'رسول', 'الله', 'النبي', 'نبي', 'لرسول', 'للنبي', 'برسول', 'بالنبي', 'فقال', 'وقال', 'ثم', 'انا', 'كان', 'كانت'}
# The words of the honorifics and of praise: a two-word run made of these alone is never tinted.
NOISE = {'صلي', 'الله', 'عليه', 'وسلم', 'و', 'سلم', 'رضي', 'عنه', 'عنها', 'عنهم', 'عنهما', 'السلام', 'عز', 'وجل',
         'تعالي', 'سبحانه', 'وتعالي', 'تبارك'}
# A compilation's closing attribution, cut off the text when it falls in the row's second half.
ATTRIBUTION = {'رواه', 'ورواه', 'اخرجه', 'واخرجه', 'متفق', 'رواهما', 'اخرجاه', 'واخرجاه'}


def fold(token):
    out = []
    for ch in token:
        o = ord(ch)
        if o in MARKS or o in PUNCT:
            continue
        out.append(LETTERS.get(o, ch))
    return ''.join(out)


def content_keys(keys, start, end):
    """The folded words of keys[start:end] with the honorifics and the words of praise left out."""
    out = []
    i = start
    while i < end:
        k = keys[i]
        if not k:
            i += 1
            continue
        h = chains.honorific(keys, i)
        if h:
            i += h
            continue
        # "صلى الله عليه و سلم" with its و set apart (the forty of an-Nawawi): the same honorific.
        if k == 'صلي' and keys[i + 1:i + 5] == ['الله', 'عليه', 'و', 'سلم']:
            i += 5
            continue
        if k in DROP:
            i += 1
            continue
        out.append(k)
        i += 1
    return out


# MARK: - Where the chain ends

def lenient(raw):
    """The compilations open "وعن أبي هريرة ..." ("and from ..."): read the و away, and turn a leading
    dash or mark into a comma the parser skips, keeping every token in place."""
    tokens = list(raw)
    i = 0
    while i < len(tokens) and fold(tokens[i]) == '':
        tokens[i] = '،'
        i += 1
    if i < len(tokens):
        k = chains.key(tokens[i])
        if k == 'وعن':
            tokens[i] = 'عَنْ'
        elif k == 'وعنه':
            tokens[i] = 'عَنْهُ'
    return tokens


def boundary(raw):
    """(first token of the text, how it was found): the parser's end of the isnad, else the whole row."""
    chain, _ = chains.parse(' '.join(raw))
    if chain and chain['end_at'] < len(raw) - 1:
        return chain['end_at'], 'parsed'
    chain, _ = chains.parse(' '.join(lenient(raw)))
    if chain and chain['end_at'] < len(raw) - 1:
        return chain['end_at'], 'lenient'
    return 0, 'whole'


def attribution_cut(keys, start, n):
    floor = start + max(3, (n - start) // 2)
    for j in range(floor, n):
        if keys[j] in ATTRIBUTION:
            return j
    return n


# MARK: - Reading the shelf

class Row:
    __slots__ = ('book', 'slug', 'id', 'raw', 'keys', 'offsets', 'pairs', 'start', 'end', 'how', 'content', 'full',
                 'text', 'english', 'bi', 'tri', 'matches')

    def __init__(self, book, slug, item):
        self.book, self.slug, self.id = book, slug, item.id_in_book
        # The text as the app holds it: it decodes آ into its canonical parts once per block
        # (`decomposingAlefMadda`), one UTF-16 unit more per آ, and the runs are offsets into THAT.
        arabic = item.arabic.replace('\u0622', '\u0627\u0653')
        self.raw = arabic.split()
        self.keys = [fold(t) for t in self.raw]
        self.offsets = token_offsets(arabic)
        assert len(self.offsets) == len(self.raw), (slug, item.id_in_book)
        assert not self.offsets or self.offsets[-1][1] < 65536, (slug, item.id_in_book)
        words = [k for k in self.keys if k]
        # Every two-word run of the whole narration, for the tint of the rows matched to this one; a
        # pair of honorific words alone ("صلى الله", "عليه وسلم") is in nearly every row and tints nothing.
        self.pairs = {(a, b) for a, b in zip(words, words[1:]) if not (a in NOISE and b in NOISE)}
        n = len(self.raw)
        self.start, self.how = boundary(self.raw) if n else (0, 'whole')
        self.end = attribution_cut(self.keys, self.start, n)
        self.content = content_keys(self.keys, self.start, self.end)
        self.full = ' '.join(content_keys(self.keys, 0, n))
        self.text = ' '.join(self.content)
        self.english = re.sub(r'[^a-z0-9]+', ' ', item.text.lower()).strip()
        self.bi = self.tri = None
        self.matches = {}


def read_shelf():
    rows = []
    for book, slug in enumerate(SLUGS):
        shelf = Hadith(slug)
        for index in range(len(shelf.rows)):
            rows.append(Row(book, slug, shelf.item(index)))
    return rows


# MARK: - The tiers

def add(rows, a, b, tier, score):
    """Record the pair both ways; a row keeps the best tier (and score) it has for the other."""
    for x, y in ((a, b), (b, a)):
        current = rows[x].matches.get(y)
        if current is None or (tier, -score) < (current[0], -current[1]):
            rows[x].matches[y] = (tier, score)


def exact_tiers(rows):
    by_full, by_text = defaultdict(list), defaultdict(list)
    for gid, row in enumerate(rows):
        if row.full:
            by_full[row.full].append(gid)
        if row.text:
            by_text[row.text].append(gid)
    for group in by_full.values():
        for i, a in enumerate(group):
            for b in group[i + 1:]:
                add(rows, a, b, TIER_SAME_ALL, 100)
    for group in by_text.values():
        for i, a in enumerate(group):
            for b in group[i + 1:]:
                if b not in rows[a].matches:
                    add(rows, a, b, TIER_SAME_TEXT, 100)


def shingles(words, n):
    return {tuple(words[i:i + n]) for i in range(len(words) - n + 1)}


def scoring_words(content):
    """The content past its opening formula, when enough is left to compare."""
    i = 0
    while i < len(content) and content[i] in LEAD_IN:
        i += 1
    return content[i:] if len(content) - i >= 3 else content


def similar_tier(rows):
    index = defaultdict(list)
    bigram_df = Counter()
    for gid, row in enumerate(rows):
        if len(row.content) >= MIN_WORDS:
            words = scoring_words(row.content)
            row.bi = shingles(words, 2)
            row.tri = shingles(words, 3)
            bigram_df.update(row.bi)
            for gram in row.tri:
                index[gram].append(gid)
    index = {gram: ids for gram, ids in index.items() if len(ids) <= SHINGLE_CAP}
    formulas = {gram for gram, df in bigram_df.items() if df > BIGRAM_CAP}
    for row in rows:
        if row.bi is not None:
            row.bi -= formulas
            if len(row.bi) < MIN_SHARED_BIGRAMS:
                row.bi = row.tri = None
    pairs = 0
    for gid, row in enumerate(rows):
        if row.tri is None:
            continue
        counts = Counter()
        for gram in row.tri:
            for other in index.get(gram, ()):
                if other > gid:
                    counts[other] += 1
        for other, shared_tri in counts.items():
            if shared_tri < MIN_SHARED_TRIGRAMS or other in row.matches:
                continue
            that = rows[other]
            if that.bi is None:
                continue
            shared = len(row.bi & that.bi)
            if shared < MIN_SHARED_BIGRAMS:
                continue
            score = round(100 * shared / min(len(row.bi), len(that.bi)))
            if score < MIN_SCORE:
                continue
            add(rows, gid, other, TIER_SIMILAR, score)
            pairs += 1
    return pairs


def phrase_tier(rows):
    """A narration too short for shingles is matched whole: every row that carries its words in order.
    Only a row that IS that short (the forty of Shah Waliullah: "الحرب خدعة"), never one whose text came
    out short because its chain ended late, and never a phrase so common it is a formula ("قال رسول
    الله" sits in thousands of rows), which would list the whole shelf."""
    short = [gid for gid, row in enumerate(rows) if row.how == 'whole' and 2 <= len(row.content) < MIN_WORDS]
    if not short:
        return 0
    first = defaultdict(list)
    for gid, row in enumerate(rows):
        if len(row.content) >= 2:
            for i in range(len(row.content) - 1):
                first[(row.content[i], row.content[i + 1])].append((gid, i))
    pairs = 0
    for gid in short:
        words = rows[gid].content
        found = [other for other, at in first.get((words[0], words[1]), ())
                 if other != gid and rows[other].content[at:at + len(words)] == words]
        if len(found) > PHRASE_CAP:
            continue
        for other in found:
            if other not in rows[gid].matches:
                add(rows, gid, other, TIER_SIMILAR, 100)
                pairs += 1
    return pairs


def english_flags(rows):
    by_english = defaultdict(list)
    for gid, row in enumerate(rows):
        if len(row.english) >= 20:
            by_english[row.english].append(gid)
    same = {gid: set(group) for group in by_english.values() if len(group) > 1 for gid in group}
    return same


# MARK: - What to tint

def runs_of_text(that):
    """The matched row's text after its chain (the attribution cut off), as one run."""
    if that.end <= that.start:
        return []
    return [(that.offsets[that.start][0], that.offsets[that.end - 1][1] - that.offsets[that.start][0])]


def runs_shared(this, that):
    """The words of `that` in a two-word run `this` also carries, neighbours joined into one run; a
    punctuation-only token between two words breaks the run (it stays unpainted)."""
    if not this.pairs:
        return []
    content = [i for i, k in enumerate(that.keys) if k]
    marked = [False] * len(that.keys)
    for a, b in zip(content, content[1:]):
        if (that.keys[a], that.keys[b]) in this.pairs:
            marked[a] = marked[b] = True
    runs = []
    i, n = 0, len(marked)
    while i < n:
        if not marked[i]:
            i += 1
            continue
        j = i
        while j + 1 < n and marked[j + 1]:
            j += 1
        runs.append((that.offsets[i][0], that.offsets[j][1] - that.offsets[i][0]))
        i = j + 1
    return runs


def runs_for(this, that, tier):
    if tier == TIER_SAME_ALL:
        return []
    if tier == TIER_SAME_TEXT:
        return runs_of_text(that)
    return runs_shared(this, that)


def ordered(rows, gid, same_english):
    """A row's records in the sheet's default order: tier, then score, then the shelf's order, each
    with the runs of the matched row's text to tint."""
    out = []
    for other, (tier, score) in rows[gid].matches.items():
        that = rows[other]
        flags = FLAG_SAME_ENGLISH if other in same_english.get(gid, ()) else 0
        out.append((tier, -score, that.book, that.id, flags, other))
    out.sort()
    kept, exact, similar = [], 0, 0
    for tier, negative, book, id_in_book, flags, other in out:
        if tier == TIER_SIMILAR:
            if similar >= MAX_SIMILAR:
                continue
            similar += 1
        else:
            if exact >= MAX_EXACT:
                continue
            exact += 1
        kept.append((book, id_in_book, tier, -negative, flags, runs_for(rows[gid], rows[other], tier)))
    return kept


# MARK: - The pack

def fnv1a64(data):
    value = 0xcbf29ce484222325
    for byte in data:
        value = ((value ^ byte) * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
    return value


def book_block(entries):
    """One book's block: u32 idInBook per row (ascending), u32 byte offset per row plus one, then the
    rows' records back to back. The app binary-searches the ids where they lie."""
    entries = sorted(entries)
    offsets = [0]
    body = bytearray()
    for _, records in entries:
        for record in records:
            body += pack_record(*record)
        offsets.append(len(body))
    return (struct.pack(f'<{len(entries)}I', *(i for i, _ in entries))
            + struct.pack(f'<{len(offsets)}I', *offsets) + bytes(body)), entries


def write_pack(lists):
    """SimilarHadiths.qpk (QuranPackContainer, QuranPack.swift):

      header (48), block table (16 per book); records = books, units = rows with matches
      eager (LZFSE)   u32 books, then per book: string slug, u32 rows with matches
      block n (LZMA)  book n's `book_block` (the records' layout is in the header above)

    Then reads the file back as the app will, Apple's decoder included, and checks every record."""
    eager = bytearray(struct.pack('<I', len(SLUGS)))
    blocks, expected = [], {}
    for book, slug in enumerate(SLUGS):
        raw, entries = book_block(lists.get(slug, []))
        assert entries, f'{slug}: no row has a match'
        blocks.append(raw)
        expected[slug] = entries
        data = slug.encode('utf-8')
        eager += struct.pack('<I', len(data)) + data + struct.pack('<I', len(entries))
    total = sum(len(entries) for entries in expected.values())
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
                         len(SLUGS), total, eager_offset, len(eager_blob), len(eager), fnv1a64(b''.join(blocks)), 0)
    OUT.write_bytes(header + b''.join(table) + eager_blob + b''.join(payloads))
    verify_pack(expected)
    return total, sum(len(b) for b in blocks)


def verify_pack(expected):
    data = OUT.read_bytes()
    (magic, version, eager_codec, block_codec, block_count, _, records, units, eager_offset, eager_length,
     eager_raw, _, _) = struct.unpack_from(packs.QPK_HEADER, data, 0)
    assert (magic, version, eager_codec, block_codec) == (packs.QPK_MAGIC, 1, packs.CODEC_LZFSE, packs.CODEC_LZMA)
    assert block_count == records == len(SLUGS) and units == sum(len(e) for e in expected.values())
    eager = packs.apple_decode(data[eager_offset:eager_offset + eager_length], eager_raw, packs.COMPRESSION_LZFSE)
    assert struct.unpack_from('<I', eager, 0)[0] == len(SLUGS)
    pos = 4
    for index, slug in enumerate(SLUGS):
        length = struct.unpack_from('<I', eager, pos)[0]
        assert eager[pos + 4:pos + 4 + length].decode('utf-8') == slug, slug
        pos += 4 + length
        count = struct.unpack_from('<I', eager, pos)[0]
        pos += 4
        entries = expected[slug]
        assert count == len(entries), (slug, count)
        first, offset, length, raw_length = struct.unpack_from('<IIII', data, 48 + 16 * index)
        raw = packs.apple_decode(data[offset:offset + length], raw_length, packs.COMPRESSION_LZMA)
        ids = struct.unpack_from(f'<{count}I', raw, 0)
        offsets = struct.unpack_from(f'<{count + 1}I', raw, 4 * count)
        base = 8 * count + 4
        assert first == index and base + offsets[-1] == len(raw), slug
        assert list(ids) == [i for i, _ in entries] and list(ids) == sorted(set(ids)), slug
        for n, (_, records) in enumerate(entries):
            chunk = raw[base + offsets[n]:base + offsets[n + 1]]
            at, found = 0, []
            while at < len(chunk):
                record, at = unpack_record(chunk, at)
                found.append(record)
            assert at == len(chunk) and found == records, (slug, ids[n])
    assert pos == len(eager)


# MARK: - Samples (SimilarHadithsTests holds the app to these)

SAMPLE_ROWS = [("bukhari", 1), ("bukhari", 54), ("muslim", 1907), ("tirmidhi", 1), ("nasai", 1), ("darimi", 1),
               ("nawawi40", 1), ("shahwaliullah40", 2), ("riyad_assalihin", 2), ("bulugh_almaram", 2),
               ("mishkat_almasabih", 3)]


def write_samples(rows, lists, by_key):
    lines = ['// GENERATED by Scripts/build_similar_hadiths.py: do not edit. A few rows with the matches the',
             '// script found for them, exactly as the pack holds them, runs to tint included (SimilarHadithsTests).',
             '', 'enum SimilarHadithSamples {',
             '    struct Match { let slug: String; let idInBook: Int; let tier: Int; let score: Int; let flags: Int; let runs: [[Int]] }',
             '    struct Sample { let slug: String; let idInBook: Int; let matches: [Match] }',
             '    static let all: [Sample] = [']
    for slug, id_in_book in SAMPLE_ROWS:
        gid = by_key.get((slug, id_in_book))
        if gid is None:
            raise SystemExit(f'sample {slug} {id_in_book} is not on the shelf')
        records = dict(lists.get(slug, [])).get(id_in_book, [])
        matches = ', '.join(f'Match(slug: "{SLUGS[b]}", idInBook: {i}, tier: {t}, score: {s}, flags: {f}, '
                            f'runs: [{", ".join(f"[{a}, {n}]" for a, n in r)}])'
                            for b, i, t, s, f, r in records)
        lines.append(f'        Sample(slug: "{slug}", idInBook: {id_in_book}, matches: [{matches}]),')
    lines += ['    ]', '}', '']
    SAMPLES.write_text('\n'.join(lines), encoding='utf-8')


# MARK: - Main

def main():
    started = time.time()
    rows = read_shelf()
    by_key = {(row.slug, row.id): gid for gid, row in enumerate(rows)}
    print(f'{len(rows)} rows read in {time.time() - started:.0f} s; chain end: '
          + ' '.join(f'{k}={v}' for k, v in Counter(r.how for r in rows).most_common()))
    exact_tiers(rows)
    similar_pairs = similar_tier(rows)
    phrase_pairs = phrase_tier(rows)
    same_english = english_flags(rows)
    print(f'{similar_pairs} similar pairs, {phrase_pairs} phrase pairs, {len(same_english)} rows with the same English '
          f'as another ({time.time() - started:.0f} s)')

    lists = defaultdict(list)
    tiers = Counter()
    for gid, row in enumerate(rows):
        records = ordered(rows, gid, same_english)
        if records:
            lists[row.slug].append((row.id, records))
            for _, _, tier, _, _, _ in records:
                tiers[tier] += 1
    runs = Counter()
    for slug in SLUGS:
        total = sum(1 for r in rows if r.slug == slug)
        entries = lists.get(slug, [])
        with_matches = len(entries)
        count = sum(len(records) for _, records in entries)
        kinds = Counter(t for _, records in entries for _, _, t, _, _, _ in records)
        runs.update(min(len(r), 30) // 5 * 5 for _, records in entries for _, _, t, _, _, r in records if t == TIER_SIMILAR)
        print(f'{slug:22} rows={total:5} with matches={with_matches:5} ({100 * with_matches / total:4.1f}%) '
              f'records={count:6} same={kinds[0]:5} text={kinds[1]:5} similar={kinds[2]:6}')
    print(f'records: same text and chain {tiers[0]}, same text {tiers[1]}, similar {tiers[2]}')
    print('runs per similar record: ' + ' '.join(f'{k}+={v}' for k, v in sorted(runs.items())))
    scores = Counter((s // 10) * 10 for row in rows for t, s in row.matches.values() if t == TIER_SIMILAR)
    print('similar scores: ' + ' '.join(f'{k}s={v // 2}' for k, v in sorted(scores.items())))
    if '--inspect' in sys.argv:
        for target in sys.argv[sys.argv.index('--inspect') + 1:]:
            slug, number = target.split(':')
            gid = by_key.get((slug, int(number)))
            if gid is None:
                print(f'{target}: not on the shelf')
                continue
            row = rows[gid]
            print(f'== {target} [{row.how}] {" ".join(row.content[:14])}')
            for book, id_in_book, tier, score, flags, runs in ordered(rows, gid, same_english):
                that = rows[by_key[(SLUGS[book], id_in_book)]]
                text = ' '.join(that.raw)
                units = text.encode('utf-16-le')
                painted = ' / '.join(units[2 * a:2 * (a + n)].decode('utf-16-le') for a, n in runs)
                print(f'   tier {tier} {score:3}% {"EN " if flags else "   "}{SLUGS[book]}:{id_in_book:<5} '
                      f'{" ".join(that.content[:14])}')
                if runs:
                    print(f'        tint: {painted[:200]}')
        return
    if '--stats' in sys.argv:
        return
    total, raw = write_pack(lists)
    print(f'{OUT.relative_to(ROOT)}: {total} rows, {raw} -> {OUT.stat().st_size} bytes, read back and verified')
    write_samples(rows, lists, by_key)
    print(f'{SAMPLES.relative_to(ROOT)} written ({time.time() - started:.0f} s)')


if __name__ == '__main__':
    main()
