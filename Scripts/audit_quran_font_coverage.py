#!/usr/bin/env python3
"""Audit every bundled Quran face against every Quran text the app can display.

Decodes quran.qpk (Hafs), qiraat.qpk (the seven KFGQPC riwayat) and qiraah.solidpack (the
twelve beta riwayat) straight from Resources/Data/Quran, adds the codepoints the runtime
dotless transform produces, and reports for each face (Uthmani, Warsh, Indopak, Kufi, Hijazi)
every required codepoint that is MISSING from the cmap, maps to an EMPTY glyph, or is a
combining mark with no GDEF mark class / no GPOS mark anchor (which usually means the face
positions it by a pre-offset outline instead - check visually before "fixing").

Run:  python3 Scripts/audit_quran_font_coverage.py [fonts-dir]
Read the flags with the per-face notes in Scripts/patch_quran_font_coverage.py in mind:
Uthmani's U+06DF/U+06E4 are spacing signs by design, Warsh's unanchored small letters and
Indopak's pre-offset waqf signs render correctly, Hijazi's U+200D/U+200F are format controls.
"""
import struct, lzma, json, sys, os, pathlib, tempfile
ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROOT/'Resources/Data/Quran'
OUT = pathlib.Path(tempfile.mkdtemp(prefix='quran-texts-'))

class R:
    def __init__(s,b,c=0): s.b=b; s.c=c
    def u8(s): v=s.b[s.c]; s.c+=1; return v
    def u16(s): v=struct.unpack_from('<H',s.b,s.c)[0]; s.c+=2; return v
    def u32(s): v=struct.unpack_from('<I',s.b,s.c)[0]; s.c+=4; return v
    def u64(s): v=struct.unpack_from('<Q',s.b,s.c)[0]; s.c+=8; return v
    def str(s):
        n=s.u32(); v=s.b[s.c:s.c+n].decode('utf-8'); s.c+=n; return v
    def rem(s): return len(s.b)-s.c

def decode(blob, codec, rlen):
    if codec == 0: return blob
    if codec == 2: return lzma.decompress(blob)
    # codec 1 = LZFSE: not decodable in pure python
    raise SystemExit(f'codec {codec} unsupported')

def container(path):
    b = open(path,'rb').read()
    h = R(b)
    magic = b[:4]; h.c = 4
    ver = h.u16(); ecodec = h.u8(); bcodec = h.u8(); nblocks = h.u16(); h.u16()
    nrec = h.u32(); nunit = h.u32(); eoff = h.u32(); elen = h.u32(); eraw = h.u32()
    print(path.name, magic, 'ver', ver, 'codecs', ecodec, bcodec, 'blocks', nblocks, 'rec', nrec, 'units', nunit)
    blocks = []
    for i in range(nblocks):
        blocks.append(struct.unpack_from('<IIII', b, 48+16*i))
    eager = decode(b[eoff:eoff+elen], ecodec, eraw)
    def block(i):
        fr, off, cl, rl = blocks[i]
        return decode(b[off:off+cl], bcodec, rl)
    return eager, block, nblocks

# --- quran.qpk (Hafs) ---
eager, block, nblocks = container(DATA/'quran.qpk')
r = R(eager)
surahs = []
n = r.u32()
for _ in range(n):
    sid = r.u32(); r.u8(); nameAr = r.str(); r.str(); r.str(); r.str()
    nAyahs = r.u32(); r.u32(); r.u32(); r.u32(); r.u32(); r.u32(); r.u32(); r.u32(); r.u32(); r.u8()
    jc = r.u32(); [r.u32() for _ in range(jc)]
    sc = r.u32(); [r.str() for _ in range(sc)]
    firstRow = r.u32()
    surahs.append((sid, nameAr, nAyahs, firstRow))
na = r.u32()
ayahs = []
for _ in range(na):
    ayahs.append((r.u32(), r.u16(), r.u16(), r.u32(), r.u32(), r.u16()))
print('surahs', len(surahs), 'ayahs', len(ayahs))
blockFirst = {}
for row,(aid,juz,page,wc,lc,blk) in enumerate(ayahs):
    blockFirst.setdefault(blk,row)
hafs = {}
cache = {}
for row,(aid,juz,page,wc,lc,blk) in enumerate(ayahs):
    if blk not in cache:
        rr = R(block(blk)); out=[]
        while rr.rem() >= 4: out.append(rr.str())
        cache[blk]=out
    slot = (row-blockFirst[blk])*4
    hafs[str(row)] = cache[blk][slot]
json.dump(hafs, open(OUT/'Hafs.json','w'), ensure_ascii=False)
json.dump({str(s[0]): s[1] for s in surahs}, open(OUT/'SurahNames.json','w'), ensure_ascii=False)
print('Hafs ayahs', len(hafs), 'sample 1:', hafs['1'][:60])

# --- qiraat.qpk ---
eager, block, nblocks = container(DATA/'qiraat.qpk')
r = R(eager)
n = r.u32()
readings = []
for _ in range(n):
    key = r.str(); sc = r.u32(); order=[]
    for _ in range(sc):
        sid=r.u32(); cnt=r.u32(); order.append((sid,cnt))
    blk = r.u16()
    readings.append((key, order, blk))
for key, order, blk in readings:
    rr = R(block(blk)); texts={}
    for sid,cnt in order:
        for _ in range(cnt):
            aid = rr.u32(); texts[f'{sid}:{aid}'] = rr.str()
    json.dump(texts, open(OUT/f'{key}.json','w'), ensure_ascii=False)
    print('reading', key, len(texts))

# --- qiraah.solidpack (12 beta) ---
d = open(DATA/'qiraah.solidpack','rb').read()
body = lzma.decompress(d)
n = struct.unpack('<I', body[:4])[0]
idx = json.loads(body[4:4+n]); base = 4+n
for e in idx['entries']:
    raw = body[base+e['offset']: base+e['offset']+e['length']]
    j = json.loads(raw)
    if e['name'] == 'QiraahAbuHarith':
        print('beta json top-level type', type(j).__name__, (list(j.keys())[:5] if isinstance(j,dict) else str(j[0])[:300]))
    # flatten: try common shapes
    texts = {}
    for sid, rows in j.items():
        for row in rows:
            texts[f"{sid}:{row['id']}"] = row['text']
    if not texts:
        # dump a sample of structure for inspection
        print('  could not flatten', e['name'], str(j)[:500])
    json.dump(texts, open(OUT/f"{e['name']}.json",'w'), ensure_ascii=False)
    print('beta', e['name'], len(texts))

# ---------------------------------------------------------------------------
import json, pathlib, sys, unicodedata
from collections import Counter, defaultdict
from fontTools.ttLib import TTFont
FDIR = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT/'Resources/Fonts'
FONTS = {
 'Uthmani': FDIR/'Uthmani.ttf',
 'Warsh': FDIR/'Warsh.ttf',
 'Indopak': FDIR/'Indopak.ttf',
 'Kufi': FDIR/'Kufi.ttf',
 'Hijazi': FDIR/'Hijazi.ttf',
}
DOTLESS = {0x0623:0x0627,0x0625:0x0627,0x0624:0x0621,0x0626:0x0621,0x0622:0x0627,0x0671:0x0627,
 0x0628:0x066E,0x062A:0x066E,0x062B:0x066E,0x0646:0x06BA,0x064A:0x0649,0x062C:0x062D,0x062E:0x062D,
 0x0630:0x062F,0x0632:0x0631,0x0634:0x0633,0x0636:0x0635,0x0638:0x0637,0x063A:0x0639,0x0641:0x06A1,
 0x0642:0x066F,0x0629:0x0647}
# per-source counters
per_source = {}
for f in sorted(OUT.glob('*.json')):
    texts = json.load(open(f))
    c = Counter()
    for t in texts.values(): c.update(ord(ch) for ch in t)
    per_source[f.stem] = c
# runtime dotless outputs, counted from every text
dot = Counter()
for name, c in per_source.items():
    if name == 'SurahNames': continue
    for cp, n in c.items():
        if cp in DOTLESS: dot[DOTLESS[cp]] += n
per_source['(runtime dotless)'] = dot
union = Counter()
for c in per_source.values(): union.update(c)

def uname(cp):
    try: return unicodedata.name(chr(cp))
    except: return '?'

def font_report(name, path):
    t = TTFont(str(path))
    cmap = t.getBestCmap()
    glyf = t['glyf'] if 'glyf' in t else None
    gdef = t['GDEF'].table.GlyphClassDef.classDefs if 'GDEF' in t and t['GDEF'].table.GlyphClassDef else {}
    # collect glyphs covered as marks in GPOS MarkBase/MarkMark/MarkLig lookups
    markcov = set()
    if 'GPOS' in t:
        for lk in t['GPOS'].table.LookupList.Lookup:
            for st in lk.SubTable:
                if st.LookupType == 9: st = st.ExtSubTable
                if st.LookupType in (4,5):
                    markcov.update(st.MarkCoverage.glyphs)
                elif st.LookupType == 6:
                    markcov.update(st.Mark1Coverage.glyphs)
    def empty(g):
        if glyf is None: return False
        gl = glyf[g]
        return (not gl.isComposite()) and gl.numberOfContours == 0
    rows = []
    for cp in sorted(union):
        if cp in (0x20, 0x0A): continue
        cat = unicodedata.category(chr(cp))
        g = cmap.get(cp)
        status = []
        if g is None: status.append('MISSING')
        else:
            if empty(g) and cat.startswith('M'): status.append('EMPTY-GLYPH')
            elif empty(g) and cat not in ('Zs',): status.append('EMPTY-GLYPH')
            if cat.startswith('Mn'):
                if gdef.get(g) != 3: status.append(f'GDEF={gdef.get(g)}')
                if g not in markcov: status.append('NO-MARK-ANCHOR')
        if status:
            srcs = [(s, c[cp]) for s, c in per_source.items() if c.get(cp)]
            rows.append((cp, g, status, srcs))
    print(f'\n=== {name} ({path.name}): cmap {len(cmap)}, {len(union)} codepoints required, {len(rows)} flagged')
    for cp, g, status, srcs in rows:
        srcs_s = ', '.join(f'{s}:{n}' for s, n in sorted(srcs, key=lambda x:-x[1])[:6])
        more = '' if len(srcs) <= 6 else f' (+{len(srcs)-6} more)'
        print(f'  U+{cp:04X} {uname(cp)[:34]:34} glyph={g!s:18} {"/".join(status):24} total={union[cp]:7}  {srcs_s}{more}')

print('Required codepoints (union over all sources):')
for cp in sorted(union):
    print(f'  U+{cp:04X} {uname(cp)[:40]:40} {union[cp]:8}  in {sum(1 for c in per_source.values() if c.get(cp))} sources')
for name, path in FONTS.items():
    font_report(name, path)
