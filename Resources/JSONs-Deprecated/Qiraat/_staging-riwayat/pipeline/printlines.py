#!/usr/bin/env python3
"""Stage 1 of the printed-line tables: read each volume's LINE structure off its PDF.

For every page, every body line in reading order, as a token sequence of words (`w`) and
ayah markers (`m`), plus the line's ink extent - so stage 2 (`printlines_build.py`) can turn
"the print breaks its line after the k-th word of ayah N" into the app's own token indices.

What counts as a body line: a y-band of glyphs in the body faces (HQPB*/Hamd*) at the page's
body size. Surah-heading lines are set larger (16pt over a 14pt body) and drop out on size;
the basmalah ornament is three HQPB3 glyphs on a band of their own and drops out on that
shape; the running header, footer, legend box and margin numbers are chrome faces (Times,
DecoType, ArabicTransparent, MSH) and never enter a band.

Ayah markers are bracket-glyph pairs in HQPB2: gids 167/168 in nineteen volumes, and the
Hafs volume's own subset codes them as gids 20/18 with its digits at U+F0C9..U+F0D2. A lone
marker CAN open a line (al-Ikhlas's last number sits alone on page 604), so a marker is a
token of its own, exactly as the app's composer treats it.

    python3 printlines.py hafs shubah        # data/<slug>.lines.json
    python3 printlines.py --all
    python3 printlines.py hafs --pages 1,2,50 --debug
"""
import collections
import json
import pathlib
import sys
import time

import fitz

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from extract import pdf_path, BODY_FACES, DIGITS, _digit_val, PDF_NAMES  # noqa: E402

DATA = HERE / "data"
CHROME_SPACE_FACES = ("Times", "Arial", "PTBold", "ArabicTransparent", "DecoType")
SLUGS = ["hafs", "shubah", "qaloon", "warsh", "bazzi", "qunbul", "duriabiamr", "susi",
         "hisham", "ibndhakwan", "khalaf", "khallad", "abuharith", "durikisai",
         "ibnwardan", "ibnjammaz", "ruways", "rawh", "ishaq", "idris"]

# (open gid, close gid) of the HQPB2 marker brackets; the Hafs subset is coded differently.
BRACKETS = {"hafs": (20, 18)}
DEFAULT_BRACKETS = (167, 168)
GAP_SEGMENTED = {"bazzi"}
SCALED = {"ibnwardan", "ibnjammaz", "ruways", "rawh", "ishaq", "idris"}
HAFS_DIGIT_BASE = 0xF0C9   # U+F0C9 = ٠ ... U+F0D2 = ٩ in the Hafs volume's HQPB2 subset


def page_lines(page, slug, pno=0, nominal=None):
    """[(line_dict), ...] for one page: seq/vals/x0/x1/y, plus the skipped bands for debugging."""
    rows = []
    for sp in page.get_texttrace():
        f = sp.get("font", "?")
        size = round(sp.get("size", 0), 1)
        for uni, gid, org, bbox in sp.get("chars", []):
            x0, y0, x1, y1 = bbox
            rows.append(((y0 + y1) / 2, x0, x1, f, size, uni, gid))
    body = [r for r in rows if r[3].startswith(BODY_FACES) and r[5] not in (32, 160)]
    if not body:
        return [], []
    sizes = collections.Counter(r[4] for r in body)
    body_size = sizes.most_common(1)[0][0]
    # the VOLUME's body size decides "oversize": a page set half at 16pt (Qunbul 267) still
    # has 14pt headings-vs-body semantics
    nominal = nominal or body_size
    # The 14pt volumes nudge a line to 13.5/14.5 to justify it, and their surah headings sit a
    # full 2pt above the body. The six SCALED volumes (Abu Ja'far, Ya'qub, Khalaf al-Ashir)
    # justify by re-sizing EVERY line - 14 to 18.5pt on a 16pt body - and put their surah
    # names in the MSH banner, so there the whole range is body.
    # Every body-face size is body: the six SCALED volumes re-size every line (14-18.5pt on a
    # 16pt body) and the 14pt volumes do it on a few pages too (Qunbul page 267 sets half its
    # lines at 16pt). Surah headings are told apart by GEOMETRY below, not by size.
    glyphs = [r for r in body if 11.5 <= r[4] <= 21.0]
    bigger = []
    # MSH banner furniture (the surah-name banner of the SCALED volumes) marks a surah break.
    # (Not in the SCALED volumes: their banners are vector art, and their MSH ornaments at
    # 18pt on a 16pt page read as banners and cut phantom surahs.)
    banner_ys = [] if slug in SCALED else [
        r[0] for r in rows if r[3].startswith(("MSH", "Msh")) and body_size and r[4] > 1.1 * body_size]
    spaces = [r for r in rows
              if r[5] in (32, 160) and any(r[3].startswith(p) for p in CHROME_SPACE_FACES)]
    # Chrome-face INK (digits, parentheses, ornate brackets in Times/DecoType/Arial): only the
    # surah-name and ayah-count lines carry it, never a body line.
    chrome_ink = [r for r in rows
                  if r[5] not in (32, 160) and any(r[3].startswith(p) for p in CHROME_SPACE_FACES)]
    # The Madani/Basri volumes draw the ayah digits in the MSH layer (gids 19-28), not in HQPB2;
    # they only feed the marker VALUE, which is a sanity check, never the token sequence.
    msh_digits = [r for r in rows if r[3].startswith(("MSH", "Msh")) and chr(r[5]).isdigit()]

    # y-bands of the body-size glyphs (9pt merge, like extract.page_tokens)
    ys = sorted(r[0] for r in glyphs)
    bands = []
    for y in ys:
        if bands and y - bands[-1][1] <= 9:
            bands[-1][1] = y
        else:
            bands.append([y, y])

    open_gid, close_gid = BRACKETS.get(slug, DEFAULT_BRACKETS)

    def is_bracket(r, gid):
        return r[3] == "HQPB2" and r[6] == gid

    def digit_of(r):
        if slug == "hafs":
            if r[3] == "HQPB2" and HAFS_DIGIT_BASE <= r[5] <= HAFS_DIGIT_BASE + 9:
                return r[5] - HAFS_DIGIT_BASE
            return None
        d = _digit_val(f"{r[3]}#{r[6]}")
        if d is not None:
            return d
        ch = chr(r[5])
        if ch.isdigit():
            return int(ch)
        return DIGITS.get(ch)

    lines, skipped = [], []
    # The page's right margin: body lines start flush against it (RTL), headings sit centered
    # well inside it. Read off the widest band so a page of short lines still has a margin.
    right_margin = max(r[2] for r in glyphs) if glyphs else 0
    left_margin = min(r[1] for r in glyphs) if glyphs else 0
    surah_break = False
    consumed_banners = set()
    for lo, hi in bands:
        # a banner ABOVE this band (and below the previous one) opens a surah
        for i, y in enumerate(banner_ys):
            if i not in consumed_banners and y < lo:
                consumed_banners.add(i)
                surah_break = True
        toks = [r for r in glyphs if lo - 0.1 <= r[0] <= hi + 0.1]
        if not toks:
            continue
        faces = collections.Counter(r[3] for r in toks)
        # The basmalah ornament: three (or four) glyphs of one face - HQPB3 in most volumes,
        # a Hamd face in Khalaf's and Khallad's.
        if len(faces) == 1 and len(toks) <= 4 and (set(faces) == {"HQPB3"} or next(iter(faces)).startswith("Hamd")):
            skipped.append(("basmalah", round(lo, 1), len(toks)))
            surah_break = True
            continue
        # A surah-name / ayah-count line (fixed-size volumes only: the SCALED volumes set their
        # names as vector-art banners). Narrow, carries no ayah marker, and shows one of two tells
        # a body line never has: ink from a chrome face (the ayah count's Times digits and
        # parentheses, the name's DecoType/Times ornate brackets) or glyphs a size step above the
        # volume's body (16pt names on a 14pt body, Khalaf's 20pt HQPB2 brackets). Geometry alone
        # is NOT a tell: the prints center the lines of a short surah (al-Ikhlas) and of pages 1-2.
        x0 = min(r[1] for r in toks)
        x1 = max(r[2] for r in toks)
        narrow = (x1 - x0) < 0.7 * max(right_margin - left_margin, 1)
        has_marker = any(is_bracket(r, open_gid) for r in toks)
        if slug not in SCALED and narrow and not has_marker:
            has_chrome = any(lo - 12 <= r[0] <= hi + 12 for r in chrome_ink)
            oversize = any(r[4] > nominal + 1.05 for r in toks)
            if has_chrome or oversize:
                skipped.append(("heading", round(lo, 1), len(toks)))
                surah_break = True
                continue
        seps = [r for r in spaces if lo - 6 <= r[0] <= hi + 6]

        # marker zones: pair each open bracket with the nearest unused close bracket
        opens = [r for r in toks if is_bracket(r, open_gid)]
        closes = [r for r in toks if is_bracket(r, close_gid)]
        used = set()
        zones = []
        for o in sorted(opens, key=lambda r: -(r[1] + r[2])):
            # bracket-to-bracket distance grows with the marker's size (three digits at 18pt)
            best, bd = None, 24.0 * max(o[4], 14.0) / 14.0 + 2.0
            for k, c in enumerate(closes):
                if k in used:
                    continue
                d = abs(((c[1] + c[2]) - (o[1] + o[2])) / 2)
                if d < bd:
                    best, bd = k, d
            if best is None:
                continue
            used.add(best)
            c = closes[best]
            zones.append([min(o[1], c[1]) - 2, max(o[2], c[2]) + 2])

        def zone_of(r):
            xc = (r[1] + r[2]) / 2
            for i, (a, b) in enumerate(zones):
                if a <= xc <= b:
                    return i
            return None

        items = []
        for r in toks:
            items.append((-(r[1] + r[2]) / 2, "g", r))
        if slug in GAP_SEGMENTED:
            # No Times-layer spaces in this volume (the al-Bazzi PDF is a reprocessed copy whose
            # separator layer was dropped), so word breaks are read off the ink: between two
            # consecutive base glyphs (positive width, reading order) a gap over 0.21 em is a
            # space - within-word gaps stay under 0.19 em, justified spaces never shrink below
            # the natural 0.25 em. Checked against Qunbul's near-identical page 50 line by line.
            # (Not used elsewhere: the other prints float a standalone hamza with a gap either
            # side, and the rule split every إِسۡرَٰٓءِيلَ.)
            bases = sorted((r for r in toks if r[2] - r[1] > 0.3), key=lambda r: -r[2])
            size_here = collections.Counter(r[4] for r in bases).most_common(1)[0][0] if bases else body_size
            for a, b in zip(bases, bases[1:]):
                if a[1] - b[2] > 0.21 * size_here:
                    xm = (a[1] + b[2]) / 2
                    items.append((-xm, "sp", (a[0], xm, xm)))
        for r in msh_digits:
            if lo - 8 <= r[0] <= hi + 8 and zone_of(r) is not None:
                items.append((-(r[1] + r[2]) / 2, "g", r))
        for r in seps:
            items.append((-(r[1] + r[2]) / 2, "sp", r))
        items.sort(key=lambda t: t[0])

        # A word is a run of glyphs between separators - but only a run that contains a BASE
        # letter. The prints set the pause signs (ۛ ۚ ۖ ...) as glyphs of their own between two
        # spaces, and the mark glyphs of the HQPB faces carry a zero advance (their bbox has no
        # width), so a run made of zero-width glyphs only is a floating sign, which the app's
        # texts attach to the word before it. Such a run is not counted (`s` in the sequence
        # only for the debug listing).
        seq, vals = [], []
        run = None          # glyphs of the run being read, or None between words
        seen_zone = set()
        zone_digits = collections.defaultdict(list)

        def close_run():
            nonlocal run
            if run is None:
                return
            bases = [g for g in run if g[2] - g[1] > 0.3]
            marks = len(run) - len(bases)
            # A run with no base glyph is a floating sign. So is a run of ONE base glyph and no
            # mark: no Arabic word is a single bare letter (the fawatih and lam-alef ligatures
            # always carry a mark), but the prints set several pause signs as a base-width glyph
            # of their own between two spaces, and the app's texts attach them to a word.
            if bases and not (len(bases) == 1 and marks == 0):
                seq.append("w")
            else:
                signs.append(len(seq))
            run = None

        signs = []
        for _, kind, r in items:
            if kind == "sp":
                close_run()
                continue
            z = zone_of(r)
            if z is not None:
                close_run()
                if z not in seen_zone:
                    seen_zone.add(z)
                    seq.append("m")
                d = digit_of(r)
                if d is not None and not is_bracket(r, open_gid) and not is_bracket(r, close_gid):
                    zone_digits[z].append((r[1], d))
                continue
            if run is None:
                run = []
            run.append(r)
        close_run()
        # digits read left-to-right (Arabic-Indic numerals run LTR)
        for z in range(len(zones)):
            ds = sorted(zone_digits.get(z, []))
            vals.append(int("".join(str(d) for _, d in ds)) if ds else None)
        if not seq:
            continue
        x0 = min(r[1] for r in toks)
        x1 = max(r[2] for r in toks)
        lines.append({"y": round(lo, 1), "x0": round(x0, 1), "x1": round(x1, 1),
                      "seq": "".join(seq), "vals": vals, "signs": len(signs), "sb": surah_break,
                      "narrow": narrow})
        surah_break = False
    # A surah-name line whose brackets sit too far from the band to count as its ink (al-Bazzi's
    # page 1) shows up as a marker-free stub of a few words right above a heading/basmalah band:
    # fold it into the heading.
    heading_ys = sorted(y for kind, y, n in skipped if kind in ("heading", "basmalah"))
    kept = []
    for ln in lines:
        stub = (ln["narrow"] and "m" not in ln["seq"] and ln["seq"].count("w") <= 4
                and any(0 < hy - ln["y"] < 60 for hy in heading_ys) and slug not in SCALED)
        if stub:
            skipped.append(("heading-stub", ln["y"], ln["seq"].count("w")))
            # the break the stub would have carried moves to the next line
            continue
        kept.append(ln)
    if len(kept) < len(lines):
        # the line after a folded stub opens the surah
        first_after = {}
        for ln in lines:
            pass
        for i, ln in enumerate(kept):
            if any(hy < ln["y"] for hy in [s[1] for s in skipped if s[0] == "heading-stub"]) and not ln["sb"]:
                prev_y = kept[i - 1]["y"] if i else -1
                if any(prev_y < sy < ln["y"] for sy in [s[1] for s in skipped if s[0] == "heading-stub"]):
                    ln["sb"] = True
    for ln in kept:
        ln.pop("narrow", None)
    return kept, skipped


def nominal_size(doc):
    """The volume's body size: the modal body-face size over a sample of pages."""
    c = collections.Counter()
    for pno in range(10, doc.page_count, 23):
        for sp in doc[pno].get_texttrace():
            if sp.get("font", "?").startswith(BODY_FACES):
                c[round(sp.get("size", 0), 1)] += len(sp.get("chars", []))
    return c.most_common(1)[0][0] if c else None


def extract(slug, pages=None, debug=False):
    doc = fitz.open(pdf_path(slug))
    nominal = nominal_size(doc)
    out = {"slug": slug, "pdf": PDF_NAMES[slug], "pagecount": doc.page_count, "pages": []}
    t0 = time.time()
    for pno in range(doc.page_count):
        if pages and (pno + 1) not in pages:
            out["pages"].append(None)
            continue
        lines, skipped = page_lines(doc[pno], slug, pno + 1, nominal)
        out["pages"].append(lines)
        if debug:
            print(f"--- {slug} p{pno + 1}: {len(lines)} lines, skipped {skipped}")
            for ln in lines:
                print(f"   y={ln['y']:6.1f} x={ln['x0']:5.0f}-{ln['x1']:5.0f} "
                      f"w={ln['seq'].count('w'):2d} m={ln['seq'].count('m')} {ln['seq']} {ln['vals']}")
    if not pages:
        DATA.mkdir(exist_ok=True)
        (DATA / f"{slug}.lines.json").write_text(json.dumps(out, separators=(",", ":")))
        n_lines = sum(len(p) for p in out["pages"] if p)
        n_marks = sum(ln["seq"].count("m") for p in out["pages"] if p for ln in p)
        n_words = sum(ln["seq"].count("w") for p in out["pages"] if p for ln in p)
        print(f"{slug}: {doc.page_count} pages, {n_lines} lines, {n_words} words, "
              f"{n_marks} markers, {time.time() - t0:.0f}s", flush=True)
    return out


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    pages = None
    if "--pages" in sys.argv:
        pages = {int(x) for x in sys.argv[sys.argv.index("--pages") + 1].split(",")}
        args = [a for a in args if a != sys.argv[sys.argv.index("--pages") + 1]]
    slugs = SLUGS if "--all" in sys.argv else args
    for slug in slugs:
        extract(slug, pages=pages, debug="--debug" in sys.argv)
