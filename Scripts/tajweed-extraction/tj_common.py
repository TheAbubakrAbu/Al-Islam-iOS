"""Shared data for the tajweed extraction: Hafs page map (quran.qpk),
riwayah texts (qiraat.qpk / beta deflates), Hafs<->riwayah ayah alignment."""
import struct, lzma, zlib, json

BASE = '/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS'

def _dec(blob):
    try: return lzma.decompress(blob)
    except lzma.LZMAError: return lzma.decompress(blob, format=lzma.FORMAT_ALONE)

class R:
    def __init__(s, b): s.b = b; s.c = 0
    def u8(s): v = s.b[s.c]; s.c += 1; return v
    def u16(s): v = struct.unpack_from('<H', s.b, s.c)[0]; s.c += 2; return v
    def u32(s): v = struct.unpack_from('<I', s.b, s.c)[0]; s.c += 4; return v
    def s_(s):
        n = s.u32(); v = s.b[s.c:s.c+n].decode('utf-8'); s.c += n; return v

def _container_eager(path):
    data = open(path, 'rb').read()
    hdr = struct.unpack_from('<IHBBHHIIIII', data, 0)
    blockCount, eOff, eCLen = hdr[4], hdr[8], hdr[9]
    table = [struct.unpack_from('<IIII', data, 48 + 16*i) for i in range(blockCount)]
    return data, table, _dec(data[eOff:eOff+eCLen])

def hafs_meta():
    """returns (surah metas, page map). page_map: page -> [(surah, ayah)] in order."""
    data, table, eager = _container_eager(BASE + '/Resources/Data/Quran/quran.qpk')
    r = R(eager)
    surahCount = r.u32()
    metas = []
    for _ in range(surahCount):
        sid = r.u32(); r.u8()
        for _ in range(4): r.s_()
        numberOfAyahs = r.u32(); pageStart = r.u32(); pageEnd = r.u32(); _np = r.u32()
        for _ in range(3): r.u32()
        wc = r.u32(); lc = r.u32(); r.u8()
        for _ in range(r.u32()): r.u32()
        for _ in range(r.u32()): r.s_()
        firstRow = r.u32()
        metas.append({'id': sid, 'ayahs': numberOfAyahs, 'pageStart': pageStart, 'pageEnd': pageEnd, 'firstRow': firstRow})
    ayahCount = r.u32()
    rows = []
    for _ in range(ayahCount):
        aid = r.u32(); juz = r.u16(); page = r.u16(); wc = r.u32(); lc = r.u32(); blk = r.u16()
        rows.append({'id': aid, 'page': page, 'words': wc})
    # attribute rows to surahs via firstRow
    page_map = {}
    for si, m in enumerate(metas):
        lo = m['firstRow']
        hi = metas[si+1]['firstRow'] if si+1 < len(metas) else len(rows)
        for row in rows[lo:hi]:
            page_map.setdefault(row['page'], []).append((m['id'], row['id']))
    return metas, page_map, rows

def hafs_texts():
    """surah -> ayah -> arabic text, from quran.qpk blocks (4 strings per row; arabic first)."""
    data, table, eager = _container_eager(BASE + '/Resources/Data/Quran/quran.qpk')
    metas, page_map, rows = hafs_meta()
    # rows have block ids; block layout: rows in order, each row = 4 strings
    # need block id per row again:
    r = R(eager)
    surahCount = r.u32()
    for _ in range(surahCount):
        r.u32(); r.u8()
        for _ in range(4): r.s_()
        for _ in range(7): r.u32()
        r.u32(); r.u32(); r.u8()
        for _ in range(r.u32()): r.u32()
        for _ in range(r.u32()): r.s_()
        r.u32()
    ayahCount = r.u32()
    blocks_of_rows = []
    for _ in range(ayahCount):
        r.u32(); r.u16(); r.u16(); r.u32(); r.u32(); blocks_of_rows.append(r.u16())
    texts = []
    cache = {}
    for row, blk in enumerate(blocks_of_rows):
        if blk not in cache:
            f_, off, cl, rl = table[blk]
            raw = _dec(data[off:off+cl])
            br = R(raw)
            strings = []
            while br.c < len(raw):
                strings.append(br.s_())
            cache[blk] = strings
        # find row slot: rows are sequential within block
        first = blocks_of_rows.index(blk)
        slot = row - first
        texts.append(cache[blk][slot * 4])
    out = {}
    for si, m in enumerate(metas):
        lo = m['firstRow']
        hi = metas[si+1]['firstRow'] if si+1 < len(metas) else len(texts)
        out[m['id']] = {rows[i]['id']: texts[i] for i in range(lo, hi)}
    return out

def riwayah_texts(key):
    """packed riwayah key (e.g. 'susi') -> surah -> [(ayahId, text)] in order."""
    data, table, eager = _container_eager(BASE + '/Resources/Data/Quran/qiraat.qpk')
    r = R(eager)
    for _ in range(r.u32()):
        k = r.s_(); sc = r.u32(); order = []; counts = {}
        for _ in range(sc):
            sid = r.u32(); cnt = r.u32(); order.append(sid); counts[sid] = cnt
        blk = r.u16()
        if k != key: continue
        f_, off, cl, rl = table[blk]
        raw = _dec(data[off:off+cl])
        br = R(raw)
        out = {}
        for sid in order:
            lst = []
            for _ in range(counts[sid]):
                aid = br.u32(); lst.append((aid, br.s_()))
            out[sid] = lst
        return out
    raise KeyError(key)

DEFLATE_NAMES = {
    'hisham': 'QiraahHisham', 'ibndhakwan': 'QiraahIbnDhakwan',
    'khalaf': 'QiraahKhalaf', 'khallad': 'QiraahKhallad',
    'abuharith': 'QiraahAbuHarith', 'durikisai': 'QiraahDuriKisai',
    'ibnwardan': 'QiraahIbnWardan', 'ibnjammaz': 'QiraahIbnJammaz',
    'ruways': 'QiraahRuways', 'rawh': 'QiraahRawh',
    'ishaq': 'QiraahIshaq', 'idris': 'QiraahIdris',
}

def riwayah_texts_any(key):
    """boxdir key -> surah -> [(ayahId, text)]; qpk for the 7 packed riwayat,
    beta json.deflate for the other 12."""
    if key in DEFLATE_NAMES:
        raw = zlib.decompress(open(BASE + f'/Resources/Data/Quran/{DEFLATE_NAMES[key]}.json.deflate', 'rb').read(), -15)
        d = json.loads(raw)
        return {int(s): [(a['id'], a['text']) for a in lst] for s, lst in d.items()}
    return riwayah_texts(key)

LETTERS = set(range(0x621, 0x64B)) | {0x671, 0x66E, 0x6CC, 0x649, 0x67E}

def base_letters(word):
    return sum(1 for c in word if ord(c) in LETTERS)

def words_of(text):
    # split on space AND nbsp so rub-el-hizb becomes its own token
    return [w for w in text.replace('\xa0', ' ').split(' ') if w and base_letters(w) > 0 or w in ('۞',)]

def align_hafs_riwayah(hafs_words_per_ayah, riw_ayat):
    """Map riwayah ayah list -> consecutive hafs ayah spans, by word-count DP.
    hafs_words_per_ayah: [(ayahId, wordCount)]; riw_ayat: [(ayahId, wordCount)].
    Returns list of (riwAyahId, [hafsAyahIds])."""
    n, m = len(hafs_words_per_ayah), len(riw_ayat)
    INF = float('inf')
    # dp[j][i]: cost covering first i hafs ayat with first j riwayah ayat
    dp = [[INF] * (n + 1) for _ in range(m + 1)]
    back = [[None] * (n + 1) for _ in range(m + 1)]
    dp[0][0] = 0
    for j in range(1, m + 1):
        rw = riw_ayat[j - 1][1]
        for i in range(j - 1 if j - 1 <= n else n, n + 1):
            if dp[j - 1][i] is INF: pass
            for k in (1, 2, 3):  # a riwayah ayah covers 1..3 hafs ayat (or 0 hafs -> split, cost rw)
                if i + k > n: break
                hw = sum(h[1] for h in hafs_words_per_ayah[i:i + k])
                c = dp[j - 1][i] + abs(rw - hw) + (0 if k == 1 else 2)
                if c < dp[j][i + k]:
                    dp[j][i + k] = c; back[j][i + k] = (i, k)
            # riwayah-only extra ayah (split beyond hafs): covers 0
            c0 = dp[j - 1][i] + rw + 4
            if c0 < dp[j][i]:
                dp[j][i] = c0; back[j][i] = (i, 0)
    if dp[m][n] is INF or dp[m][n] > 60:
        pass
    # walk back
    res = []
    i, j = n, m
    while j > 0:
        pi, k = back[j][i]
        res.append((riw_ayat[j - 1][0], [hafs_words_per_ayah[x][0] for x in range(pi, pi + k)]))
        i = pi; j -= 1
    res.reverse()
    return res
