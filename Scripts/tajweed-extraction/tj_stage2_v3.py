"""Stage 2 v3: skip-line DP alignment of stage-1 runs to riwayah text.

Changes vs v2:
- narrow (centered-width) lines stay in the stream and are consumable OR
  whole-line skippable inside the DP -> banners/basmalahs get skipped by cost,
  short centered content lines (Fatiha, surah 112...) get consumed.
- segment->surah assignment by ink width + Madinah surah-start page anchors
  (surah start pages match across editions; marker counts are too FP-noisy).
  A segment holding several surahs is aligned jointly and split at markers.
- page-header lines dropped by signature (first band, <=2 runs, wide
  single-run title or red-dominant), never by blanket y threshold: four
  editions have content as the page's first band.
- dynamic justified right edge per riwayah (rawh's measure differs).
- pass 2 re-alignment with per-line width calibration from pass 1.
- outputs: annotations, ayah->page map (pagination fix), khilaf-marker flags,
  legend color union, per-surah costs, red-vs-marks QA.

Usage: tj_stage2_v3.py <key> [boxdir] [outdir]
"""
import sys, os, json, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tj_common as tc

KEY = sys.argv[1]
BOXDIR = sys.argv[2] if len(sys.argv) > 2 else f'boxes/{KEY}'
OUTDIR = sys.argv[3] if len(sys.argv) > 3 else 'out'
os.makedirs(OUTDIR, exist_ok=True)
COLORS = ('red', 'blue', 'magenta', 'cyan', 'orange', 'green', 'royal', 'olive')

riw = tc.riwayah_texts_any(KEY)

W_CLS = {}
for ch in 'ال': W_CLS[ch] = 0.55
for ch in 'دذرزوبتثنيءأإآٱى': W_CLS[ch] = 0.85
for ch in 'حجخهةمعغفقطظ': W_CLS[ch] = 1.25
for ch in 'سشصضك': W_CLS[ch] = 1.75

def letter_units(w):
    return sum(W_CLS.get(c, 1.0) for c in w if ord(c) in tc.LETTERS)

HARAK_ANCH = set(chr(c) for c in range(0x64B, 0x653)) | {chr(0x670)}
def _marked(w):
    """word carries an imaalah (065C) or non-wasl taqlil (06EA) mark -> printed red/ringed"""
    for i, ch in enumerate(w):
        if ch == chr(0x65C): return True
        if ch == chr(0x6EA):
            j = i - 1
            while j >= 0 and w[j] in HARAK_ANCH: j -= 1
            if j >= 0 and w[j] not in ('ا', 'ٱ'): return True
    return False

def surah_tokens(sid):
    toks = []
    for aid, text in riw[sid]:
        ws = [w for w in text.replace('\xa0', ' ').split(' ') if w]
        for wi, w in enumerate(ws):
            if w == '۞':
                toks.append({'t': 'rub'}); continue
            bl = tc.base_letters(w)
            if bl == 0: continue
            toks.append({'t': 'w', 's': sid, 'a': aid, 'wi': wi, 'bl': bl, 'w': w,
                         'mk': _marked(w), 'lu': letter_units(w)})
        toks.append({'t': 'm', 's': sid, 'a': aid})
    return toks

HAS_MARKS = sum(1 for sid in riw for (_a, t) in riw[sid]
                for w in t.replace('\xa0', ' ').split(' ') if w and _marked(w)) > 50

pages = {}
for f in sorted(os.listdir(BOXDIR)):
    if f.endswith('.json'):
        d = json.load(open(os.path.join(BOXDIR, f)))
        pages[d['page']] = d['lines']

# ---- dynamic justified right edge: mode of line right-edges over busy lines
xr_hist = collections.Counter()
for pg in range(1, 605):
    for line in pages.get(pg, []):
        if len(line['runs']) >= 6:
            xr_hist[max(r['x1'] for r in line['runs']) // 8 * 8] += 1
REDGE = max(xr_hist, key=lambda x: xr_hist[x] * (x ** 0.5)) + 8  # bias to the wide mode
WIDE_MIN = REDGE - 60
print(f'{KEY}: right edge ~{REDGE}, wide >= {WIDE_MIN}')

def markerish(r):
    """loose: medallion candidate for marker-token bonuses; magenta allowed
    (khilaf-numbering medallions carry a magenta ring)"""
    w = r['x1'] - r['x0']
    return (26 <= w <= 46 and 24 <= r['ph'] <= 42 and 0.20 <= r['dens'] <= 0.38
            and not any(c in r for c in ('red', 'blue', 'cyan', 'orange', 'green', 'royal', 'olive')))

def markerish_strict(r):
    """v2-compatible: word spans must not absorb a colorless medallion"""
    return markerish(r) and 'magenta' not in r

def is_header_band(line, first_on_page):
    """page-title line: first band, <=2 runs, underlined wide single run or
    red-dominant. Titles are right-aligned; a top-of-page BASMALAH (star
    editions have no in-crop title) is centered - never drop it."""
    if not first_on_page or line['y1'] > 120 or len(line['runs']) > 2:
        return False
    ink = sum(r['ink'] for r in line['runs'])
    red = sum(r.get('red', 0) for r in line['runs'])
    if red > 0.25 * ink:
        return True
    if len(line['runs']) != 1:
        return False
    run = line['runs'][0]
    xc = (run['x0'] + run['x1']) // 2
    return (run['x1'] - run['x0']) > 220 and run['x1'] >= REDGE - 140 and xc >= 620

# ---- line stream
stream = []  # dicts: pg, li, runs, kind
for pg in range(1, 605):
    first = True
    # bottom junk: the floating legend box. Some editions draw its outline
    # dark (a continuous >=600px run - no text line produces one); others
    # draw it too light to register as ink, and only the LABELS + DOTS row
    # enters. The dots are small near-solid colored circles (fill ~ pi/4),
    # which no colored text glyph matches. Cut from the first such line down.
    def _legend_dot(r):
        w = r['x1'] - r['x0']
        return (14 <= w <= 30 and 12 <= r['ph'] <= 30 and r['dens'] >= 0.6
                and any(c in r for c in COLORS))
    cut = None
    for li, line in enumerate(pages.get(pg, [])):
        if line['y0'] < 900: continue
        if (any(r['x1'] - r['x0'] >= 600 for r in line['runs'])
                or sum(1 for r in line['runs'] if _legend_dot(r)) >= 2):
            cut = li
            break
    plines = pages.get(pg, []) if cut is None else pages[pg][:cut]
    for li, line in enumerate(plines):
        if line['y0'] <= 3 and (line['y1'] - line['y0']) < 45:
            continue  # header residue sliver at crop top
        if not line['runs']:
            continue
        # surah-name cartouche in star-border editions: a huge multi-line-tall
        # ornament band with only a few giant outline runs
        if (line['y1'] - line['y0']) >= 90 and len(line['runs']) <= 5:
            continue
        if is_header_band(line, first):
            first = False
            continue
        first = False
        xr = max(r['x1'] for r in line['runs'])
        kind = 'wide' if xr >= WIDE_MIN else 'narrow'
        stream.append({'pg': pg, 'li': li, 'runs': line['runs'], 'kind': kind})

metas, hafs_page_map, hafs_rows = tc.hafs_meta()
HAFS_START = {m['id']: m['pageStart'] for m in metas}

# ---- surah-header-block boundaries. Header lines (banner / ayah count /
# basmalah in ligature or text form) are narrow lines centered on the measure;
# a surah's closing short line is centered too and sits right above the next
# header, so clusters of adjacent centered lines form "blocks". The boundary
# is the LAST line of a block: the basmalah, which always directly precedes
# content. Blocks are matched to surahs 2..114 globally (drift-tolerant DP
# against the Madinah start pages), so one missed header can't cascade.
cands0 = []
for i, L in enumerate(stream):
    if L['kind'] != 'narrow' or len(L['runs']) > 16: continue
    xl = min(r['x0'] for r in L['runs']); xr = max(r['x1'] for r in L['runs'])
    span = xr - xl
    if 150 <= span <= 620:
        cands0.append((i, span, (xl + xr) // 2))
bounds = {}
if cands0:
    buckets = collections.Counter()
    for i, span, xc in cands0:
        buckets[xc // 24] += 1
    bx = max(buckets, key=lambda k: buckets[k])
    centered = [(i, span) for (i, span, xc) in cands0 if abs(xc // 24 - bx) <= 1]
    # The basmalah comes in two constant-span forms: calligraphic ligature
    # (short span, few runs) and text line (long span, many runs). Find each
    # form's span mode in its zone.
    def runs_of(i):
        return len(stream[i]['runs'])
    histA = collections.Counter(span // 8 for (i, span) in centered
                                if 200 <= span <= 350 and runs_of(i) <= 6)
    histB = collections.Counter(span // 16 for (i, span) in centered
                                if 480 <= span <= 620 and 9 <= runs_of(i) <= 15)
    cand_b = []
    zones = []
    if histA:
        a, ca = histA.most_common(1)[0]
        if ca >= 8: zones.append((a * 8 - 14, a * 8 + 22, 0, 6))
    if histB:
        b_, cb = histB.most_common(1)[0]
        if cb >= 8: zones.append((b_ * 16 - 18, b_ * 16 + 34, 9, 15))
    spans_of = {}
    for i, span in centered:
        nr = runs_of(i)
        if any(lo <= span <= hi and rlo <= nr <= rhi for (lo, hi, rlo, rhi) in zones):
            cand_b.append(i)
            spans_of[i] = span
    # Merge candidates whose gap contains no wide line (banner/count/basmalah
    # of one header block; a closing short line right above a block). The
    # boundary is the LAST line of the merged block -- the basmalah, which
    # directly precedes content. A wide line in between means distinct blocks.
    blocks = []
    for i in cand_b:
        if blocks and all(stream[k]['kind'] == 'narrow' for k in range(blocks[-1] + 1, i)):
            blocks[-1] = i
        else:
            blocks.append(i)
    B = len(blocks)
    # how basmalah-like each block is (span distance from its zone's mode);
    # tiebreaks matching toward true basmalahs over shape-coincident closings
    zone_c = [(lo + hi) / 2 for (lo, hi, _r0, _r1) in zones]
    qual = {i: (min(abs(spans_of.get(i, 0) - zc) for zc in zone_c) * 0.012 if zone_c else 0.0)
            for i in blocks}
    surs = [s for s in range(2, 115) if s != 9]
    INF = float('inf')
    SKIP_B, SKIP_S = 1.6, 2.6
    D = [[INF] * (len(surs) + 1) for _ in range(B + 1)]
    BK = [[None] * (len(surs) + 1) for _ in range(B + 1)]
    D[0][0] = 0.0
    for b in range(B + 1):
        for si in range(len(surs) + 1):
            if D[b][si] is INF: continue
            v = D[b][si]
            if b < B and si < len(surs):
                d = abs(stream[blocks[b]]['pg'] - HAFS_START[surs[si]])
                # gentle slope past +-2: star-border editions drift several
                # pages from the Madinah layout mid-book; a drifted match must
                # stay cheaper than skip-block + skip-surah (4.2)
                pc = (d * 0.15 if d <= 2 else 0.6 + 0.18 * min(d, 14)) + qual[blocks[b]]
                if v + pc < D[b + 1][si + 1]:
                    D[b + 1][si + 1] = v + pc; BK[b + 1][si + 1] = 'm'
            if b < B and v + SKIP_B < D[b + 1][si]:
                D[b + 1][si] = v + SKIP_B; BK[b + 1][si] = 'b'
            if si < len(surs) and v + SKIP_S < D[b][si + 1]:
                D[b][si + 1] = v + SKIP_S; BK[b][si + 1] = 's'
    b, si = B, len(surs)
    while b > 0 or si > 0:
        mv = BK[b][si]
        if mv == 'm':
            bounds[surs[si - 1]] = blocks[b - 1]; b -= 1; si -= 1
        elif mv == 'b':
            b -= 1
        else:
            si -= 1
print(f'{KEY}: header-block boundaries matched: {len(bounds)}/112')

if len(bounds) >= 100:
    # block = [bound .. next bound); pre-block = surah 1; a surah without a
    # boundary of its own (9 always; rare undetected headers) shares the
    # previous surah's block and is aligned jointly.
    segments = []
    groups = []
    cur_surahs = [1]
    cur_lo = 0
    for s in range(2, 115):
        if s in bounds:
            segments.append((cur_lo, bounds[s]))
            groups.append((cur_surahs, [len(segments) - 1], 'bas'))
            cur_surahs = [s]; cur_lo = bounds[s]
        else:
            cur_surahs.append(s)
    segments.append((cur_lo, len(stream)))
    groups.append((cur_surahs, [len(segments) - 1], 'bas'))
    HARD = True
else:
    # fallback: split where a narrow group follows wide lines
    segments = []
    lo = 0
    prev = 'narrow'
    for i, L in enumerate(stream):
        if L['kind'] == 'narrow' and prev == 'wide':
            segments.append((lo, i)); lo = i
        prev = L['kind']
    segments.append((lo, len(stream)))
    HARD = False
print(f'{KEY}: {len(segments)} segments (114 surahs), hard={HARD}')

# ---- expected widths
all_tokens = {sid: surah_tokens(sid) for sid in riw}
UNITS = {sid: sum(t['lu'] if t['t'] == 'w' else 2.2 for t in toks)
         for sid, toks in all_tokens.items()}
wide_w = sum(r['x1'] - r['x0'] for L in stream if L['kind'] == 'wide' for r in L['runs'])
wide_u = sum(UNITS.values()) * (wide_w / max(1, sum(
    r['x1'] - r['x0'] for L in stream for r in L['runs'])))
PXL = wide_w / max(1.0, wide_u)  # px per letter-unit, from wide lines share
print(f'{KEY}: PXL={PXL:.2f}')

def seg_width(g):
    lo, hi = segments[g]
    return sum(r['x1'] - r['x0'] for L in stream[lo:hi] for r in L['runs'])

def seg_page(g):
    lo, hi = segments[g]
    return stream[lo]['pg'] if lo < hi else 0

# ---- assignment DP (fallback only): contiguous segments <-> contiguous surahs
E = {s: UNITS[s] * PXL for s in range(1, 115)}
assign_cost = 0.0
if not HARD:
    G, S = len(segments), 114
    INF = float('inf')
    def anchor_cost(g, s):
        d = abs(seg_page(g) - HAFS_START[s])
        return 0.0 if d <= 1 else min(d, 8) * 1.5

    dp = [[INF] * (S + 1) for _ in range(G + 1)]
    bk = [[None] * (S + 1) for _ in range(G + 1)]
    dp[0][0] = 0.0
    for g in range(G + 1):
        for s in range(S + 1):
            if dp[g][s] is INF: continue
            base = dp[g][s]
            if g < G and s < S:
                # surah s+1 takes segments g..g+k-1
                w = 0.0
                for k in range(1, 6):
                    if g + k > G: break
                    w += seg_width(g + k - 1)
                    c = base + abs(w - E[s + 1]) / max(E[s + 1], 1500) * 3.0 + anchor_cost(g, s + 1) + (0.4 if k > 1 else 0)
                    if c < dp[g + k][s + 1]:
                        dp[g + k][s + 1] = c; bk[g + k][s + 1] = (g, s, 'take')
                # segment g holds surahs s+1..s+j
                ew = 0.0
                for j in range(2, 10):
                    if s + j > S: break
                    ew = sum(E[x] for x in range(s + 1, s + j + 1))
                    c = base + abs(seg_width(g) - ew) / max(ew, 1500) * 3.0 + anchor_cost(g, s + 1) + 0.4 * j
                    if c < dp[g + 1][s + j]:
                        dp[g + 1][s + j] = c; bk[g + 1][s + j] = (g, s, 'joint')
    if dp[G][S] is INF:
        print(f'{KEY}: ASSIGNMENT FAILED'); sys.exit(1)
    groups = []  # (surah list, seg list)
    g, s = G, S
    while g > 0 or s > 0:
        pg_, ps_, kind = bk[g][s]
        groups.append((list(range(ps_ + 1, s + 1)), list(range(pg_, g)), kind))
        g, s = pg_, ps_
    groups.reverse()
    assign_cost = dp[G][S]
njoint = sum(1 for gr in groups if len(gr[0]) > 1)
nmulti = sum(1 for gr in groups if len(gr[1]) > 1)
print(f'{KEY}: groups={len(groups)} joint={njoint} multiseg={nmulti} assign_cost={assign_cost:.2f}')

# ---- aligner with whole-line skip moves
def align(tokens, lines, scales=None):
    flat = []
    line_start = []
    for li, L in enumerate(lines):
        line_start.append(len(flat))
        for ri, r in enumerate(L['runs']):
            flat.append((li, ri, r, markerish(r), markerish_strict(r)))
    line_start.append(len(flat))
    start_of = {line_start[li]: li for li in range(len(lines))}
    n, m = len(tokens), len(flat)
    if n == 0 or m == 0: return None
    BAND = 110
    SKIP = 0.32
    # Band centers from CUMULATIVE ink vs expected widths, not a uniform
    # run/token ratio: in giant windows (a star edition's surah 2 is ~19k
    # runs) non-uniform token widths made the uniform estimate drift past
    # the band and misattribute everything after. Width tracking is exact
    # under systematic scale error, so BAND only covers local noise.
    import bisect as _bisect
    wpref = [0.0]
    for (_li, _ri, r, _mk, _mks) in flat:
        wpref.append(wpref[-1] + (r['x1'] - r['x0']))
    epref = [0.0]
    for tok in tokens:
        ew0 = 34.0 if tok['t'] == 'm' else 26.0 if tok['t'] == 'rub' else max(9.0, tok['lu'] * PXL)
        epref.append(epref[-1] + ew0)
    wescale = wpref[-1] / max(1.0, epref[-1])
    centers = [_bisect.bisect_left(wpref, epref[ti] * wescale) for ti in range(n)]

    def closure(cells):
        for fi in sorted(cells):
            li = start_of.get(fi)
            if li is None or lines[li]['kind'] != 'narrow': continue
            nxt = line_start[li + 1]
            c = cells[fi][0] + SKIP
            cur = cells.get(nxt)
            if cur is None or c < cur[0]:
                cells[nxt] = (c, ('eps', fi))

    dp = [dict() for _ in range(n + 1)]
    dp[0][0] = (0.0, None)
    closure(dp[0])
    for ti in range(n):
        tok = tokens[ti]
        is_m = tok['t'] in ('m', 'rub')
        base_ew = 34.0 if tok['t'] == 'm' else 26.0 if tok['t'] == 'rub' else max(9.0, tok['lu'] * PXL)
        center = centers[ti]
        for fi, (cost, _) in list(dp[ti].items()):
            if fi >= m or fi > center + BAND or fi < center - BAND: continue
            li0 = flat[fi][0]
            sc = scales[li0] if scales else 1.0
            ew = base_ew * sc if not is_m else base_ew
            w = 0.0
            maxk = 1 if is_m else 10
            for k in range(1, maxk + 1):
                if fi + k - 1 >= m: break
                lij, rij, r, mk, mks = flat[fi + k - 1]
                if lij != li0: break
                if k == 1:
                    w = r['x1'] - r['x0']
                else:
                    prev = flat[fi + k - 2][2]
                    w += (r['x1'] - r['x0']) + max(0, prev['x0'] - r['x1']) * 0.3
                c = cost + abs(w - ew) / max(ew, 16)
                if is_m:
                    c += -1.2 if mk else 3.0
                elif mks:
                    c += 2.2
                if tok['t'] == 'w' and HAS_MARKS:
                    red = 0
                    for kk in range(k):
                        red += flat[fi + kk][2].get('red', 0)
                    if tok.get('mk'):
                        c += -1.4 if red > 20 else 0.6
                    elif red > 40:
                        c += 1.3
                nfi = fi + k
                cur = dp[ti + 1].get(nfi)
                if cur is None or c < cur[0]:
                    dp[ti + 1][nfi] = (c, ('tok', fi))
        closure(dp[ti + 1])
    # tail: unconsumed wide runs are expensive, narrow leftovers cheap
    wide_after = [0] * (m + 1)
    for fi in range(m - 1, -1, -1):
        wide_after[fi] = wide_after[fi + 1] + (1 if lines[flat[fi][0]]['kind'] == 'wide' else 0)
    best = None
    for fi, v in dp[n].items():
        pen = wide_after[fi] * 0.8 + (m - fi - wide_after[fi]) * 0.03
        if best is None or v[0] + pen < best[2]:
            best = (fi, v, v[0] + pen)
    if best is None: return None
    endfi = best[0]
    spans = [None] * n
    ti, fi = n, endfi
    while ti > 0:
        cost, back = dp[ti][fi]
        while back and back[0] == 'eps':
            fi = back[1]
            cost, back = dp[ti][fi]
        if back is None: return None
        kind, pfi = back
        spans[ti - 1] = (pfi, fi)
        ti, fi = ti - 1, pfi
        # eps chain below this token
        cost, back = dp[ti][fi]
        while back and back[0] == 'eps':
            fi = back[1]
            cost, back = dp[ti][fi]
    return best[2] / max(1, n), spans, flat

def line_scales(tokens, spans, flat, lines):
    sw = collections.defaultdict(float); se = collections.defaultdict(float)
    for tok, sp in zip(tokens, spans):
        if tok['t'] != 'w' or sp is None: continue
        lo, hi = sp
        li = flat[lo][0]
        w = sum(flat[x][2]['x1'] - flat[x][2]['x0'] for x in range(lo, hi))
        sw[li] += w; se[li] += max(9.0, tok['lu'] * PXL)
    return [max(0.7, min(1.4, sw[li] / se[li])) if se[li] > 60 else 1.0
            for li in range(len(lines))]

# ---- letter extents: the print colors exact LETTERS, and the word's ink
# runs are its connected letter segments. Splitting the word text by Arabic
# joining rules gives the same segments in reading order (runs are stored
# right-to-left = reading order), so colored runs map back to base-letter
# index ranges. Count mismatch (glyph overlap merged two segments) falls back
# to width-proportional mapping; total failure -> whole word.
NONJOIN = set('اأإآٱدذرزوؤةىء')

def word_segments(word):
    bases = [ch for ch in word if ord(ch) in tc.LETTERS]
    segs = []
    start = 0
    for i, ch in enumerate(bases):
        if ch in NONJOIN or i == len(bases) - 1:
            segs.append((start, i + 1))
            start = i + 1
    return bases, segs

def letter_extent(word, runs, rule):
    """(baseLo, baseHi) of the colored letters, or None for whole-word."""
    bases, segs = word_segments(word)
    if not bases or not segs or not runs:
        return None
    colored = [i for i, r in enumerate(runs) if r.get(rule, 0) > 10]
    if not colored:
        return None
    if colored[0] == 0 and colored[-1] == len(runs) - 1:
        return None   # whole word colored
    if len(runs) == len(segs):
        lo = segs[colored[0]][0]
        hi = segs[colored[-1]][1]
    else:
        # width-proportional: place each colored run's span onto the segment
        # scale by cumulative widths (run px vs segment letter-units)
        seg_units = [sum(W_CLS.get(bases[j], 1.0) for j in range(s, e)) for (s, e) in segs]
        tot_u = sum(seg_units) or 1.0
        seg_cum = [0.0]
        for u in seg_units: seg_cum.append(seg_cum[-1] + u / tot_u)
        run_w = [r['x1'] - r['x0'] for r in runs]
        tot_w = sum(run_w) or 1
        run_cum = [0.0]
        for w in run_w: run_cum.append(run_cum[-1] + w / tot_w)
        def seg_at(frac):
            for si in range(len(segs)):
                if frac < seg_cum[si + 1] + 1e-9:
                    return si
            return len(segs) - 1
        lo = segs[seg_at(run_cum[colored[0]] + 0.001)][0]
        hi = segs[seg_at(run_cum[colored[-1] + 1] - 0.001)][1]
    if lo <= 0 and hi >= len(bases):
        return None
    return (lo, hi)

annos = collections.defaultdict(dict)
khilaf_markers = collections.defaultdict(list)
page_of_ayah = {}
end_page_of_ayah = {}
qa_status = []
for surahs, segs, kind in groups:
    lo = segments[segs[0]][0]
    hi = segments[segs[-1]][1]
    # window extends into the NEXT separator's narrow prefix (closing lines /
    # next banner are skippable there)
    j = hi
    while j < len(stream) and stream[j]['kind'] == 'narrow':
        j += 1
    lines = stream[lo:j]
    tokens = []
    for s in surahs:
        tokens.extend(all_tokens[s])
    r1 = align(tokens, lines)
    if r1 is None:
        qa_status.append((surahs, 'FAIL')); continue
    cost1, spans1, flat = r1
    scales = line_scales(tokens, spans1, flat, lines)
    r2 = align(tokens, lines, scales)
    if r2 is not None and r2[0] < cost1:
        cost, spans, flat = r2
    else:
        cost, spans, flat = r1
    qa_status.append((surahs, round(cost, 3)))
    seen_ayah_page = {}
    for tok, sp in zip(tokens, spans):
        if sp is None: continue
        lo_, hi_ = sp
        li = flat[lo_][0]
        pg = lines[li]['pg']
        if tok['t'] == 'm':
            run = flat[lo_][2]
            if run.get('magenta', 0) > 40:
                khilaf_markers[tok['s']].append(tok['a'])
            end_page_of_ayah[(tok['s'], tok['a'])] = pg
            continue
        if tok['t'] != 'w': continue
        key = (tok['s'], tok['a'])
        if key not in seen_ayah_page:
            seen_ayah_page[key] = pg
            page_of_ayah[key] = pg
        runs = [flat[x][2] for x in range(lo_, hi_)]
        cols = {}
        for c in COLORS:
            v = sum(rr.get(c, 0) for rr in runs)
            if v > 12: cols[c] = v
        if cols:
            rule = max(cols, key=cols.get)
            ext = letter_extent(tok['w'], runs, rule)
            annos[key][tok['wi']] = rule if ext is None else [rule, ext[0], ext[1]]

# ---- page-gap fill: an ayah is assigned its START page, so a page whose
# whole content is the INTERIOR of one long ayah (2:282...) gets no ayah at
# all and vanishes from the reader's pagination ("Page 604 / 603"). When the
# next ayah starts 2+ pages later and this ayah's end (its marker) reaches
# into the gap, move the spanning ayah onto the gap page - which is also
# where the print effectively shows it.
ordered = sorted(page_of_ayah.keys())
changed = True
while changed:
    changed = False
    for i in range(len(ordered) - 1):
        cur, nxt = ordered[i], ordered[i + 1]
        pc, pn = page_of_ayah[cur], page_of_ayah[nxt]
        if pn - pc >= 2 and end_page_of_ayah.get(cur, pc) >= pc + 1:
            page_of_ayah[cur] = pc + 1
            changed = True

# ---- red snap: the imaalah/taqlil text marks are ground truth for where red
# ink lives. If a marked word got no red but an unmarked neighbor did, the
# span drifted by one word: move the red (the neighbor keeps nothing unless
# it had another color).
def rule_of(v):
    return v if isinstance(v, str) else v[0]

for sid in riw:
    for aid, text in riw[sid]:
        key = (sid, aid)
        d = annos.get(key)
        if not d: continue
        ws = [w for w in text.replace('\xa0', ' ').split(' ') if w]
        marked = {wi for wi, w in enumerate(ws) if _marked(w)}
        for wi in sorted(marked):
            if wi in d and rule_of(d[wi]) == 'red': continue
            for nb in (wi - 1, wi + 1):
                if nb in d and rule_of(d[nb]) == 'red' and nb not in marked:
                    del d[nb]
                    d[wi] = 'red'
                    break

fails = [q for q in qa_status if q[1] == 'FAIL']
oks = [q for q in qa_status if q[1] != 'FAIL']
print(f'{KEY}: aligned groups={len(oks)} failed={fails}')
print(f'{KEY}: worst costs:', sorted(oks, key=lambda t: -t[1])[:8])

out = {}
for (s, a), d in sorted(annos.items()):
    out.setdefault(str(s), {})[str(a)] = d
json.dump(out, open(f'{OUTDIR}/{KEY}-annotations.json', 'w'), ensure_ascii=False)
pm = {}
for (s, a), pg in sorted(page_of_ayah.items()):
    pm.setdefault(str(s), {})[str(a)] = pg
json.dump(pm, open(f'{OUTDIR}/{KEY}-pagemap.json', 'w'))
legend = collections.Counter()
for d in annos.values():
    for rule in d.values(): legend[rule_of(rule)] += 1
meta = {'legend': dict(legend), 'khilafAyahMarkers': {str(s): sorted(set(v)) for s, v in khilaf_markers.items()},
        'segments': len(segments), 'assignCost': round(assign_cost, 2), 'hard': HARD,
        'costs': [(s, c) for s, c in [(q[0][0] if len(q[0]) == 1 else q[0], q[1]) for q in qa_status]]}
json.dump(meta, open(f'{OUTDIR}/{KEY}-meta.json', 'w'))
print(f'{KEY}: legend={dict(legend)} words={sum(len(d) for d in annos.values())}')

# ---- QA: red words vs imaalah/taqlil text marks
tp = 0; fn_list = []; fp_list = []
for sid in riw:
    for aid, text in riw[sid]:
        ws = [w for w in text.replace('\xa0', ' ').split(' ') if w]
        marked = {wi for wi, w in enumerate(ws) if _marked(w)}
        redw = {wi for wi, rule in annos.get((sid, aid), {}).items() if rule_of(rule) == 'red'}
        tp += len(marked & redw)
        for wi in marked - redw: fn_list.append((sid, aid, wi))
        for wi in redw - marked: fp_list.append((sid, aid, wi))
tot = tp + len(fn_list)
pct = 100.0 * tp / max(1, tot)
print(f'{KEY}: QA red-vs-marks matched={tp} FN={len(fn_list)} FP={len(fp_list)}  recall={pct:.1f}%')
json.dump({'tp': tp, 'fn': fn_list[:200], 'fp': fp_list[:200], 'recall': round(pct, 2)},
          open(f'{OUTDIR}/{KEY}-qa.json', 'w'))
