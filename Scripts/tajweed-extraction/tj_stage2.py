"""Stage 2 v2: marker-anchored alignment of stage-1 runs to riwayah text.

Key idea: ayah medallions are visually classifiable (width ~26-44, ink height
~26-40 within a ~48px band, stroke density ~0.20-0.36), and there is exactly one
per ayah. The DP gets strong bonuses/penalties for matching marker tokens to
marker-like runs, so word attribution can never drift across an ayah boundary.
Surah slicing is marker-count driven, cursor advances to the line holding the
surah's final marker.
"""
import sys, os, json, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tj_common as tc

BOXDIR = sys.argv[1] if len(sys.argv) > 1 else 'susi-boxes'
RIWAYAH = sys.argv[2] if len(sys.argv) > 2 else 'susi'
OUTFILE = sys.argv[3] if len(sys.argv) > 3 else 'susi-annotations.json'
CONTENT_W = 1160 - 80
COLORS = ('red', 'blue', 'magenta', 'cyan', 'orange')

riw = tc.riwayah_texts(RIWAYAH)

W_CLS = {}
for ch in 'ال': W_CLS[ch] = 0.55
for ch in 'دذرزوبتثنيءأإآٱى': W_CLS[ch] = 0.85
for ch in 'حجخهةمعغفقطظ': W_CLS[ch] = 1.25
for ch in 'سشصضك': W_CLS[ch] = 1.75

def letter_units(w):
    return sum(W_CLS.get(c, 1.0) for c in w if ord(c) in __import__('tj_common').LETTERS)

HARAK_ANCH = set(chr(c) for c in range(0x64B, 0x653)) | {chr(0x670)}
def _marked(w):
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
                         'mk': _marked(w)})
        toks.append({'t': 'm', 's': sid, 'a': aid})
    return toks

pages = {}
for f in sorted(os.listdir(BOXDIR)):
    if f.endswith('.json'):
        d = json.load(open(os.path.join(BOXDIR, f)))
        pages[d['page']] = d['lines']

RIGHT_EDGE = 972   # measured: content lines end at ~962-976; centered lines at <= 820

def line_kind(line):
    runs = line['runs']
    if not runs: return 'empty'
    x_right = max(r['x1'] for r in runs)
    if x_right < RIGHT_EDGE - 60:
        return 'centered'
    return 'content'

def markerish(r, bandh):
    w = r['x1'] - r['x0']
    return (26 <= w <= 46 and 24 <= r['ph'] <= 42 and 0.20 <= r['dens'] <= 0.38
            and not any(c in r for c in COLORS))

# Build the full line stream, then split into surah segments at centered
# header groups (surah name / ayah-count / basmalah lines are all centered;
# content lines are justified or right-aligned).
all_lines = []
for pg in range(1, 605):
    for li, line in enumerate(pages.get(pg, [])):
        # page-header residue bleeding into the crop top: a shallow band at y0
        if line['y0'] <= 3 and (line['y1'] - line['y0']) < 45: continue
        k = line_kind(line)
        if k == 'empty': continue
        all_lines.append((pg, li, line['runs'], line['y1'] - line['y0'], k))

segments = []   # list of (startPage, [ (pg, li, runs, bandh) ... ])
cur = None
prev_kind = None
for (pg, li, runs, bandh, k) in all_lines:
    if k == 'centered':
        if prev_kind != 'centered':
            if cur is not None and cur[1]: segments.append(cur)
            cur = (pg, [])
    else:
        if cur is None: cur = (pg, [])
        cur[1].append((pg, li, runs, bandh))
    prev_kind = k
if cur is not None and cur[1]: segments.append(cur)
print('segments found:', len(segments), '(want 114)')
if len(segments) != 114:
    for i, (pg, ls) in enumerate(segments[:120]):
        print(' seg', i, 'startPage', pg, 'lines', len(ls))

stream = [ln for (_pg, ls) in segments for ln in ls]

total_w = sum(r['x1'] - r['x0'] for (_pg, _li, runs, _bh) in stream for r in runs)
_units = 0.0
for sid in riw:
    for tok in surah_tokens(sid):
        if tok['t'] == 'w':
            tok['lu'] = letter_units(tok['w'])
            _units += tok['lu']
        else:
            _units += 2.2
PXL = total_w / max(1.0, _units)

def exp_width(tok):
    if tok['t'] == 'm': return 34.0
    if tok['t'] == 'rub': return 26.0
    return max(9.0, tok.get('lu', tok['bl']) * PXL)

def align(tokens, lines):
    """lines: list of (runs, bandh). DP over flattened runs with line-boundary
    constraint. Returns (avgcost, spans) spans[i] = (lineIdx, runLo, runHi)."""
    flat = []
    for li, (runs, bandh) in enumerate(lines):
        for ri, r in enumerate(runs):
            flat.append((li, ri, r, markerish(r, bandh)))
    n, m = len(tokens), len(flat)
    if n == 0 or m == 0: return None
    BAND = 80
    ratio = m / n
    dp = [dict() for _ in range(n + 1)]
    dp[0][0] = (0.0, -1)
    for ti in range(n):
        tok = tokens[ti]
        if tok['t'] == 'w' and 'lu' not in tok:
            tok['lu'] = letter_units(tok['w'])
        ew = exp_width(tok)
        is_m = tok['t'] in ('m', 'rub')
        center = int(ti * ratio)
        for fi, (cost, _) in list(dp[ti].items()):
            if fi >= m or fi > center + BAND or fi < center - BAND: continue
            li0 = flat[fi][0]
            w = 0.0
            maxk = 1 if is_m else 10
            for k in range(1, maxk + 1):
                if fi + k - 1 >= m: break
                lij, rij, r, mk = flat[fi + k - 1]
                if lij != li0: break
                if k == 1:
                    w = r['x1'] - r['x0']
                else:
                    prev = flat[fi + k - 2][2]
                    w += (r['x1'] - r['x0']) + max(0, prev['x0'] - r['x1']) * 0.3
                c = cost + abs(w - ew) / max(ew, 16)
                # marker discipline
                if is_m:
                    c += -1.2 if mk else 3.0
                elif mk:
                    c += 2.2
                # imaalah-mark anchoring: red ink belongs on marked words
                if tok['t'] == 'w':
                    red = 0
                    for kk in range(k):
                        red += flat[fi + kk][2].get('red', 0)
                    if tok.get('mk'):
                        c += -0.9 if red > 20 else 0.35
                    elif red > 40:
                        c += 0.9
                nfi = fi + k
                cur = dp[ti + 1].get(nfi)
                if cur is None or c < cur[0]:
                    dp[ti + 1][nfi] = (c, fi)
    # surah's final token is its last marker; it must end near m (allow small tail)
    best = None
    for fi, v in dp[n].items():
        pen = (m - fi) * 0.8 if fi <= m else 99
        if best is None or v[0] + pen < best[2]:
            best = (fi, v, v[0] + pen)
    if best is None: return None
    endfi, endv, _ = best
    spans = [None] * n
    fi = endfi
    for ti in range(n, 0, -1):
        cost, pfi = dp[ti][fi]
        spans[ti - 1] = (pfi, fi)
        fi = pfi
    out = []
    for ti, (lo, hi) in enumerate(spans):
        li = flat[lo][0]
        out.append((li, flat[lo][1], flat[hi - 1][1]))
    return endv[0] / max(1, n), out

metas, page_map, hafs_rows = tc.hafs_meta()
sur_page = {mm['id']: (mm['pageStart'], mm['pageEnd']) for mm in metas}

annos = collections.defaultdict(dict)
qa_status = []
use_segments = len(segments) == 114
for sid in range(1, 115):
    tokens = surah_tokens(sid)
    if not use_segments:
        qa_status.append((sid, 'NOSEG')); continue
    lines = [(runs, bandh) for (_pg, _li, runs, bandh) in segments[sid - 1][1]]
    r = align(tokens, lines)
    if r is None:
        qa_status.append((sid, 'FAIL'))
        continue
    cost, spans = r
    qa_status.append((sid, round(cost, 3)))
    for tok, sp in zip(tokens, spans):
        if tok['t'] != 'w': continue
        li, rlo, rhi = sp
        runs = lines[li][0][rlo:rhi + 1]
        cols = {}
        for c in COLORS:
            v = sum(rr.get(c, 0) for rr in runs)
            if v > 12: cols[c] = v
        if cols:
            rule = max(cols, key=cols.get)
            annos[(tok['s'], tok['a'])][tok['wi']] = rule

fails = [q for q in qa_status if q[1] == 'FAIL']
oks = [q for q in qa_status if q[1] != 'FAIL']
print('aligned surahs:', len(oks), 'failed:', fails)
print('worst costs:', sorted(oks, key=lambda t: -t[1])[:10])

out = {}
for (s, a), d in sorted(annos.items()):
    out.setdefault(str(s), {})[str(a)] = d
json.dump(out, open(OUTFILE, 'w'), ensure_ascii=False)
print('annotated words:', sum(len(d) for d in annos.values()), '->', OUTFILE)

# QA vs text marks
HARAKAT = set(chr(c) for c in range(0x64B, 0x653)) | {'ٰ'}
def word_has_mark(w):
    for i, ch in enumerate(w):
        if ch == 'ٜ': return True
        if ch == '۪':
            j = i - 1
            while j >= 0 and w[j] in HARAKAT: j -= 1
            if j >= 0 and w[j] not in ('ا', 'ٱ'): return True
    return False

tp = 0
fn_list, fp_list = [], []
for sid in riw:
    for aid, text in riw[sid]:
        ws = [w for w in text.replace('\xa0', ' ').split(' ') if w]
        marked = {wi for wi, w in enumerate(ws) if word_has_mark(w)}
        redw = {wi for wi, rule in annos.get((sid, aid), {}).items() if rule == 'red'}
        tp += len(marked & redw)
        for wi in marked - redw: fn_list.append((sid, aid, wi, ws[wi] if wi < len(ws) else '?'))
        for wi in redw - marked: fp_list.append((sid, aid, wi, ws[wi] if wi < len(ws) else '?'))
print(f'QA red-vs-marks: matched {tp}, mark-not-red {len(fn_list)}, red-not-marked {len(fp_list)}')
print('sample mark-not-red:', fn_list[:12])
print('sample red-not-marked:', fp_list[:12])
