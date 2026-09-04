"""Readers for the app's own packs, for content work: hadith .hpk (LZMA/xz blocks, the layout in
iPhone/Hadith/HadithPack.swift) and the Quran JSON (Uthmani Arabic + Saheeh International).

The Pillars & Beliefs / How-to articles quote ayat and hadith with `ScriptureQuote(text:arabic:)`;
the Arabic must come from these packs, never be retyped. This is the reader that pulls it.

    python3 Scripts/islam_packs.py bukhari 631      # every row cited 631 (or 631a...), grades, matn segments

    from packs import Hadith, quran_ayah
    for h in Hadith('bukhari').find('631'): print(h.arabic, h.grades)
"""
import json
import lzma
import re
import struct
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HADITH_DIR = ROOT / 'Resources/Data/Hadith'
QURAN_JSON = ROOT / 'Resources/JSONs-Deprecated/Quran.json'


@dataclass
class Row:
    id: int
    idInBook: int
    chapterId: int
    citation: str
    block: int


@dataclass
class Item:
    citation: str
    arabic: str
    narrator: str
    text: str
    grades: list


class _Cursor:
    def __init__(self, b, pos=0):
        self.b, self.pos = b, pos

    def u8(self):
        v = self.b[self.pos]; self.pos += 1; return v

    def u16(self):
        v = struct.unpack_from('<H', self.b, self.pos)[0]; self.pos += 2; return v

    def u32(self):
        v = struct.unpack_from('<I', self.b, self.pos)[0]; self.pos += 4; return v

    def i32(self):
        v = struct.unpack_from('<i', self.b, self.pos)[0]; self.pos += 4; return v

    def u64(self):
        v = struct.unpack_from('<Q', self.b, self.pos)[0]; self.pos += 8; return v

    def string(self):
        n = self.u32()
        s = self.b[self.pos:self.pos + n].decode('utf-8', 'replace'); self.pos += n; return s

    @property
    def remaining(self):
        return len(self.b) - self.pos


def _decompress(buf, codec):
    if codec == 2:
        return lzma.decompress(buf)
    raise ValueError(f'codec {codec} (lzfse) is not readable from Python')


class Hadith:
    def __init__(self, slug):
        self.slug = slug
        self.data = (HADITH_DIR / f'{slug}.hpk').read_bytes()
        c = _Cursor(self.data)
        assert self.data[:4] == b'HDPK', 'not an hpk'
        c.pos = 4
        self.version = c.u16()
        self.eager_codec, self.text_codec, self.search_codec, _ = c.u8(), c.u8(), c.u8(), c.u8()
        block_count = c.u16()
        c.u32(); c.u32()  # chapter count, hadith count
        eo, el, er = c.u32(), c.u32(), c.u32()
        c.u64(); c.u64()
        assert c.pos == 48
        self.blocks = []
        for _ in range(block_count):
            self.blocks.append(dict(firstRow=c.u32(), textOffset=c.u32(), textLength=c.u32(), textRaw=c.u32(),
                                    searchOffset=c.u32(), searchLength=c.u32(), searchRaw=c.u32()))
        eager = _decompress(self.data[eo:eo + el], self.eager_codec)
        e = _Cursor(eager)
        self.arabic_title, self.arabic_author, self.english_title, self.english_author = e.string(), e.string(), e.string(), e.string()
        chapter_count = e.u32()
        self.chapters = []
        for _ in range(chapter_count):
            cid, first, count = e.i32(), e.u32(), e.u32()
            ar, en, far, fen = e.string(), e.string(), e.string(), e.string()
            self.chapters.append(dict(id=cid, firstRow=first, rowCount=count, arabic=ar, english=en))
        n = e.u32()
        self.rows = []
        for _ in range(n):
            rid, idb, ch, base = e.u32(), e.u32(), e.i32(), e.u32()
            suffix, block, flags = e.u8(), e.u16(), e.u8()
            cit = '' if base == 0 else str(base) + ('' if suffix == 0 else chr(ord('a') + suffix - 1))
            self.rows.append(Row(rid, idb, ch, cit, block))
        self._blocks = {}

    def _text_block(self, i):
        if i not in self._blocks:
            b = self.blocks[i]
            raw = _decompress(self.data[b['textOffset']:b['textOffset'] + b['textLength']], self.text_codec)
            c = _Cursor(raw)
            out = []
            while c.remaining >= 4:
                out.append(c.string())
            self._blocks[i] = out
        return self._blocks[i]

    def item(self, row_index):
        r = self.rows[row_index]
        strings = self._text_block(r.block)
        slot = (row_index - self.blocks[r.block]['firstRow']) * 4
        arabic, narrator, text, grades = strings[slot:slot + 4]
        gl = []
        for rec in grades.split('\x1e'):
            if not rec:
                continue
            parts = rec.split('\x1f', 1)
            gl.append((parts[0], parts[1]) if len(parts) == 2 else ('', parts[0]))
        return Item(r.citation, arabic, narrator, text, gl)

    def find(self, citation):
        """Rows whose sunnah.com citation is N or N<letter>."""
        pat = re.compile(rf'^{re.escape(str(citation))}[a-z]?$')
        return [self.item(i) for i, r in enumerate(self.rows) if pat.match(r.citation)]

    def grep(self, regex):
        rx = re.compile(regex)
        out = []
        for i in range(len(self.rows)):
            it = self.item(i)
            if rx.search(strip_marks(it.arabic)) or rx.search(it.text):
                out.append(it)
        return out


def strip_marks(s):
    return re.sub(r'[ؐ-ًؚ-ٰٟۖ-ۭـ]', '', s)


@lru_cache(maxsize=None)
def _quran():
    return json.load(open(QURAN_JSON))


def quran_ayah(surah, ayah):
    s = _quran()[surah - 1]
    a = s['ayahs'][ayah - 1]
    return a['textArabic'], a['textEnglishSaheeh']


def quran_range(surah, a, b):
    return ' ۝ '.join(quran_ayah(surah, i)[0] for i in range(a, b + 1)), ' '.join(quran_ayah(surah, i)[1] for i in range(a, b + 1))


def matn_segments(arabic):
    """Quoted segments "..." of a hadith's Arabic (the matn is normally inside quotes)."""
    return re.findall(r'"([^"]+)"', arabic)


def is_weak(grades):
    return [g for g in grades if re.search(r"da'?if|ضعيف|weak|munkar|mawdu|fabricat", g[1], re.I)]


if __name__ == '__main__':
    import sys
    slug, cit = sys.argv[1], sys.argv[2]
    for it in Hadith(slug).find(cit):
        print('==', slug, it.citation, it.grades)
        print(it.narrator)
        print(it.text)
        print(it.arabic)
        for k, seg in enumerate(matn_segments(it.arabic)):
            print(f'  seg[{k}]: {seg}')
