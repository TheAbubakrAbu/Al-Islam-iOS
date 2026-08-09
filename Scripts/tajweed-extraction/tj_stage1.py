"""Stage 1: rasterize every page of a riwayah mushaf PDF and emit raw
line/word-box data with per-color pixel counts. Output: one JSON per page.

Usage: tj_stage1.py <pdf> <outdir> [first] [last] [X0 X1 Y0 Y1]
"""
import sys, os, json, subprocess, tempfile, multiprocessing
import numpy as np
from PIL import Image

PDF = sys.argv[1]
OUT = sys.argv[2]
FIRST = int(sys.argv[3]) if len(sys.argv) > 3 else 1
LAST = int(sys.argv[4]) if len(sys.argv) > 4 else 604
os.makedirs(OUT, exist_ok=True)

DPI = 150
# content window at 150dpi (page ~1240x1754): inside the green border, above legend/footer
X0, X1, Y0, Y1 = 80, 1160, 140, 1408
# star-border editions (Yaqub pair) need x inside the star columns, y below the
# title/logo band and above the legend box
if len(sys.argv) > 8:
    X0, X1, Y0, Y1 = (int(a) for a in sys.argv[5:9])
LINE_MIN_DARK = 8       # dark px per row to count as text
LINE_GAP = 8            # merge line bands separated by < this
LINE_MIN_H = 20
WORD_GAP = 11           # column gap that separates words
WORD_MIN_W = 10

def classify(im):
    a = np.asarray(im, dtype=np.int16)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    # Only two GREEN-DOMINANT inks are text: warsh's vivid rāʾ-green (1,255,0)
    # and its olive madd-līn (153,204,0). Everything else green-dominant is
    # the page frame / ornaments - core (0,128,0) AND all its anti-aliased
    # shades (dark yellowish ones and near-white light ones alike), which
    # must never count as ink or frame slivers glue onto text lines and
    # wreck the narrow-line/basmalah detection.
    green = (g > 200) & (r < 110) & (b < 110)    # (1,255,0) raa muraqqaqah
    olive = (r > 110) & (r < 200) & (g > 160) & (b < 90)  # (153,204,0) madd leen
    border_green = (g > r + 25) & (g > b + 25) & ~green & ~olive
    dark = (r + g + b < 660) & ~border_green     # any ink
    magenta = (r > 140) & (b > 140) & (g < r - 50) & (g < b - 50)
    orange = (r > 190) & (g > 90) & (g < 185) & (b < 90) & (r - b > 110)
    red = (r > 140) & (r - g > 60) & (r - b > 60) & ~magenta & ~orange
    royal = (b > 180) & (g > 60) & (g < 165) & (r > 15) & (r < 125) & (b - g > 60)  # (51,102,255) lamat
    blue = (b > 130) & (b - r > 50) & (b - g > 50) & ~royal
    cyan = (b > 150) & (g > 160) & (r < 110)     # (0,204,255) madd badal / sakt / ghunnah
    return dark, {'red': red, 'blue': blue, 'magenta': magenta, 'cyan': cyan,
                  'orange': orange, 'green': green, 'royal': royal, 'olive': olive}

def page_boxes(png):
    im = Image.open(png).convert('RGB').crop((X0, Y0, X1, Y1))
    dark, colors = classify(im)
    rowsum = dark.sum(axis=1)
    bands = []
    y = 0
    H = dark.shape[0]
    while y < H:
        if rowsum[y] > LINE_MIN_DARK:
            y0 = y
            gap = 0
            y2 = y
            while y2 < H and gap < LINE_GAP:
                if rowsum[y2] > LINE_MIN_DARK: gap = 0
                else: gap += 1
                y2 += 1
            y1 = y2 - gap
            if y1 - y0 >= LINE_MIN_H:
                bands.append((y0, y1))
            y = y2
        else:
            y += 1
    lines = []
    for (y0, y1) in bands:
        band = dark[y0:y1]
        colsum = band.sum(axis=0)
        # runs of ink separated by any whitespace at all
        runs = []
        x = 0
        W = band.shape[1]
        while x < W:
            if colsum[x] > 0:
                x0 = x
                while x < W and colsum[x] > 0: x += 1
                runs.append((x0, x))
            else:
                x += 1
        if not runs:
            continue
        # emit raw runs (RTL order) with per-run color counts; stage 2 groups
        # them into words by aligning against the expected token stream.
        out = []
        for (x0, xe) in runs:
            seg = band[:, x0:xe]
            ys = np.where(seg.any(axis=1))[0]
            ph = int(ys[-1] - ys[0] + 1) if len(ys) else 0
            ink = int(seg.sum())
            dens = round(ink / max(1, (xe - x0) * ph), 3)
            run = {'x0': int(x0), 'x1': int(xe), 'ink': ink, 'ph': ph, 'dens': dens}
            for cname, cmask in colors.items():
                n = int(cmask[y0:y1, x0:xe].sum())
                if n > 4: run[cname] = n
            out.append(run)
        out.sort(key=lambda b: -b['x0'])  # RTL
        lines.append({'y0': int(y0), 'y1': int(y1), 'runs': out})
    return lines

def one(page):
    out = os.path.join(OUT, f'p{page:03d}.json')
    if os.path.exists(out): return page
    with tempfile.TemporaryDirectory() as td:
        base = os.path.join(td, 'pg')
        subprocess.run(['pdftoppm', '-f', str(page), '-l', str(page), '-r', str(DPI), '-png', PDF, base],
                       check=True, capture_output=True)
        pngs = [f for f in os.listdir(td) if f.endswith('.png')]
        lines = page_boxes(os.path.join(td, pngs[0]))
    json.dump({'page': page, 'lines': lines}, open(out, 'w'))
    return page

if __name__ == '__main__':
    pages = list(range(FIRST, LAST + 1))
    with multiprocessing.Pool(10) as p:
        for i, pg in enumerate(p.imap_unordered(one, pages)):
            if i % 50 == 0: print(f'{i}/{len(pages)}', flush=True)
    print('done', flush=True)
