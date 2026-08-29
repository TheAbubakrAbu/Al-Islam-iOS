#!/usr/bin/env python3
"""Stage 2 of the printed-line tables: map each print line start onto the app's own tokens.

Inputs
  data/<slug>.lines.json   stage 1 (printlines.py): every page's lines as w/m sequences
  data/printtokens.json    the app's dump (`-dumpPrintTokens`): every riwayah's pages, each ayah
                           as [surah, id, tokenCount] - the composer's token model, so the tables
                           index exactly what the page will set
  the app's texts          to tell a sign-only token (۞, a lone pause sign) from a word: the
                           prints draw those as ornaments, never as a word of their own

Method: the n-th ayah marker of the print IS the n-th ayah of the app's riwayah sequence (both
run the whole mushaf in order), so a print line that starts after the j-th word of an ayah maps
onto that ayah's j-th content word in the app. Ayah and marker boundaries map exactly; inside an
ayah whose print word count disagrees with the app's (a handful per volume - a print word split or
joined) the offset is scaled proportionally and the ayah is listed in the report.

Output: Resources/Data/Quran/Lines<Name>.json.deflate (raw deflate), one per riwayah:
    {"v": 1, "s": {"<surah>": {"<ayah>": [offset*2 + full, ...]}}}
`offset` counts the ayah's composed tokens (words; offset == wordCount is the ayah-number
ornament itself), `full` = 1 when the printed line fills the measure (so the app justifies it),
0 for the print's short right-aligned closing lines. Then: python3 Scripts/build_solidpacks.py

    python3 printlines_build.py            # all twenty
    python3 printlines_build.py hafs shubah
"""
import collections
import json
import lzma
import pathlib
import re
import statistics
import struct
import sys
import zlib

HERE = pathlib.Path(__file__).resolve().parent
DATA = HERE / "data"
REPO = HERE.parents[4]
APPDATA = REPO / "Resources" / "Data" / "Quran"

KEYS = {"hafs": "Hafs", "shubah": "Shubah", "qaloon": "Qaloon", "warsh": "Warsh", "bazzi": "Bazzi",
        "qunbul": "Qunbul", "duriabiamr": "Duri", "susi": "Susi", "hisham": "Hisham",
        "ibndhakwan": "IbnDhakwan", "khalaf": "Khalaf", "khallad": "Khallad",
        "abuharith": "AbuHarith", "durikisai": "DuriKisai", "ibnwardan": "IbnWardan",
        "ibnjammaz": "IbnJammaz", "ruways": "Ruways", "rawh": "Rawh", "ishaq": "Ishaq", "idris": "Idris"}
QPK_BLOCKS = {"warsh": 0, "qaloon": 1, "duriabiamr": 2, "susi": 3, "bazzi": 4, "qunbul": 5, "shubah": 6}
LETTER = re.compile(r"[ؠ-يٮٯٱ-ۓۺ-ۼ]")
FULL_RATIO = 0.985


def app_sequence(dump_pages):
    """[(surah, ayah, tokens, page)] in mushaf order, from the app dump."""
    out = []
    for page, ayahs in dump_pages:
        for surah, ayah, tokens in ayahs:
            out.append((surah, ayah, tokens, page))
    return out


def app_texts(slug, sequence):
    """{(surah, ayah): text} from the app's own data files."""
    if slug in KEYS and KEYS[slug] not in ("Hafs",) and slug not in QPK_BLOCKS:
        raw = json.loads(zlib.decompress((APPDATA / f"Qiraah{KEYS[slug]}.json.deflate").read_bytes(), -15))
        return {(int(s), e["id"]): e["text"] for s, entries in raw.items() for e in entries}
    if slug == "hafs":
        b = (APPDATA / "quran.qpk").read_bytes()
        nb = struct.unpack_from("<H", b, 8)[0]
        texts = []
        for i in range(nb):
            fr, off, clen, rlen = struct.unpack_from("<IIII", b, 48 + 16 * i)
            raw = lzma.decompress(b[off:off + clen])
            p, k = 0, 0
            while p + 4 <= len(raw):
                n = struct.unpack_from("<I", raw, p)[0]
                p += 4
                if p + n > len(raw):
                    break
                s = raw[p:p + n].decode("utf-8")
                p += n
                if k % 4 == 0:
                    texts.append(s)
                k += 1
        assert len(texts) == len(sequence), (len(texts), len(sequence))
        return {(s, a): t for (s, a, _, _), t in zip(sequence, texts)}
    b = (APPDATA / "qiraat.qpk").read_bytes()
    blk = QPK_BLOCKS[slug]
    fr, off, clen, rlen = struct.unpack_from("<IIII", b, 48 + 16 * blk)
    raw = lzma.decompress(b[off:off + clen])
    p, records = 0, []
    while p + 8 <= len(raw):
        aid, n = struct.unpack_from("<II", raw, p)
        p += 8
        records.append((aid, raw[p:p + n].decode("utf-8")))
        p += n
    assert len(records) == len(sequence), (slug, len(records), len(sequence))
    out = {}
    for (s, a, _, _), (aid, t) in zip(sequence, records):
        assert aid == a, (slug, s, a, aid)
        out[(s, a)] = t
    return out


def content_map(text):
    """Token index of each CONTENT word (a token with a letter); sign-only tokens attach to
    their neighbour and never start a line of their own. Index 0 is always the ayah start."""
    tokens = [t for t in text.split(" ") if t]
    idx = [i for i, t in enumerate(tokens) if LETTER.search(t)]
    if idx and idx[0] != 0:
        idx[0] = 0
    return tokens, idx


def align(print_words, app_words):
    """Match print spans (ayahs as the print numbers them) to app ayahs by word count: 1:1, a
    print span holding two or three app ayahs (the Basri print merges 13 the app's count splits),
    or two print spans inside one app ayah. Returns [(print_index_range, app_index_range)]."""
    n, m = len(print_words), len(app_words)
    INF = float("inf")
    cost = [[INF] * (m + 1) for _ in range(n + 1)]
    back = [[None] * (m + 1) for _ in range(n + 1)]
    cost[0][0] = 0
    for i in range(n + 1):
        for k in range(m + 1):
            c = cost[i][k]
            if c == INF:
                continue
            for di, dk, pen in ((1, 1, 0), (1, 2, 1), (1, 3, 2), (2, 1, 1), (3, 1, 2)):
                if i + di > n or k + dk > m:
                    continue
                wp = sum(print_words[i:i + di])
                wc = sum(app_words[k:k + dk])
                nc = c + abs(wp - wc) + pen
                if nc < cost[i + di][k + dk]:
                    cost[i + di][k + dk] = nc
                    back[i + di][k + dk] = (di, dk)
    if cost[n][m] == INF:
        return None
    groups = []
    i, k = n, m
    while i > 0 or k > 0:
        di, dk = back[i][k]
        groups.append(((i - di, i), (k - dk, k)))
        i, k = i - di, k - dk
    return groups[::-1]


def build(slug, dump, report):
    key = KEYS[slug]
    lines = json.loads((DATA / f"{slug}.lines.json").read_text())
    sequence = app_sequence(dump[key])
    texts = app_texts(slug, sequence)

    # the app's token model must be ours (the dump's counts are the arbiter)
    tokens_of = {}
    for s, a, n, _ in sequence:
        toks, cmap = content_map(texts[(s, a)])
        if len(toks) != n:
            toks, cmap = [""] * n, list(range(n))
        tokens_of[(s, a)] = (toks, cmap)

    # the print's measure: median of the pages' widest lines
    page_max = [max((ln["x1"] - ln["x0"]) for ln in page) for page in lines["pages"] if page]
    measure = statistics.median(page_max)

    # per-page marker check (page disagreements are informational: the table is keyed by ayah)
    app_per_page = collections.Counter(pg for _, _, _, pg in sequence)
    page_diffs = []
    for pno, page in enumerate(lines["pages"], start=1):
        marks = sum(ln["seq"].count("m") for ln in (page or []))
        if marks != app_per_page.get(pno, 0):
            page_diffs.append((pno, marks, app_per_page.get(pno, 0)))
    total_marks = sum(ln["seq"].count("m") for page in lines["pages"] if page for ln in page)
    report.append(f"  markers {total_marks} vs app ayahs {len(sequence)}; pages disagreeing: {len(page_diffs)}")

    # the print stream, cut into surahs at the heading/basmalah/banner breaks
    app_surahs = []
    for s, a, n, pg in sequence:
        if not app_surahs or app_surahs[-1][0] != s:
            app_surahs.append((s, []))
        app_surahs[-1][1].append((a, n, pg))
    app_counts = [len(ayahs) for _, ayahs in app_surahs]

    streams = []          # each: list of tokens (kind, line_start_info or None)
    current = None
    marks_in_stream = 0
    last_value = None
    for pno, page in enumerate(lines["pages"], start=1):
        for ln in page or []:
            if ln.get("sb") or current is None:
                current = []
                streams.append(current)
                marks_in_stream, last_value = 0, None
            full = (ln["x1"] - ln["x0"]) >= FULL_RATIO * measure
            values = list(ln["vals"])
            for t, ch in enumerate(ln["seq"]):
                if ch == "m":
                    value = values.pop(0) if values else None
                    # A surah whose start carries neither basmalah nor a text heading (at-Tawbah in
                    # the scaled volumes, whose banners are vector art): its numbers restart at 1.
                    # Only a restart that lands where the app's count says a surah ends is trusted.
                    expected = app_counts[len(streams) - 1] if len(streams) - 1 < len(app_counts) else None
                    # Trusted only when the numbers say the surah just ended: the previous marker
                    # read as the surah's last number and the count agrees (al-Bazzi's re-subset
                    # digits misread often enough that a looser rule cut 25 phantom surahs).
                    if (value == 1 and expected is not None and marks_in_stream == expected
                            and last_value == expected):
                        current = []
                        streams.append(current)
                        marks_in_stream, last_value = 0, None
                        # the line start that opened this marker's line belongs to the new surah
                        if t == 0:
                            pass
                    marks_in_stream += 1
                    last_value = value if value is not None else last_value
                current.append((ch, (full, pno) if t == 0 else None))
    if len(streams) != len(app_surahs):
        # fall back: the surah break tells failed somewhere - split at the app's marker counts
        report.append(f"  !! {len(streams)} print surah streams vs {len(app_surahs)} app surahs - "
                      f"splitting the print stream by marker counts instead")
        flat = [tok for st in streams for tok in st]
        streams, cursor = [], 0
        for s, ayahs in app_surahs:
            need = len(ayahs)
            seg, seen = [], 0
            while cursor < len(flat) and seen < need:
                seg.append(flat[cursor])
                if flat[cursor][0] == "m":
                    seen += 1
                cursor += 1
            streams.append(seg)
        if cursor != len(flat):
            report.append(f"  !! {len(flat) - cursor} print tokens left over after the last surah")

    starts = collections.defaultdict(list)
    count_mismatch, merges, splits, page_mismatch, unaligned = [], 0, 0, 0, []
    for (s, ayahs), stream in zip(app_surahs, streams):
        # print spans: words between markers, with the line starts inside them
        spans = []          # {"w": count, "starts": [(j_or_None, full, page)]}
        cur = {"w": 0, "starts": []}
        for ch, info in stream:
            if info is not None:
                cur["starts"].append((None if ch == "m" else cur["w"], info[0], info[1]))
            if ch == "w":
                cur["w"] += 1
            else:
                spans.append(cur)
                cur = {"w": 0, "starts": []}
        if cur["w"] or cur["starts"]:
            spans.append(cur)      # words after the last marker (should not happen)
        app_words = [len(tokens_of[(s, a)][1]) for a, _, _ in ayahs]
        groups = align([sp["w"] for sp in spans], app_words)
        if groups is None:
            unaligned.append(s)
            continue
        for (i0, i1), (k0, k1) in groups:
            if k1 - k0 > 1:
                merges += 1
            if i1 - i0 > 1:
                splits += 1
            # cumulative print positions of the group's line starts
            wp = sum(sp["w"] for sp in spans[i0:i1])
            wc = sum(app_words[k0:k1])
            if wp != wc:
                count_mismatch.append((s, ayahs[k0][0], wp, wc))
            # app content words of the group, cumulative -> (ayah index, token offset)
            positions = []       # cumulative content index -> (k, token offset)
            for k in range(k0, k1):
                toks, cmap = tokens_of[(s, ayahs[k][0])]
                for off in cmap:
                    positions.append((k, off))
            base = 0
            for i in range(i0, i1):
                sp = spans[i]
                for j, full, pno in sp["starts"]:
                    if j is None:
                        # the line opens with a marker: the app's number ornament if this print
                        # span closes an app ayah, else the position after the span's words
                        x = base + sp["w"]
                        if x >= wp and k1 - k0 >= 1:
                            k = k1 - 1
                            offset = len(tokens_of[(s, ayahs[k][0])][0])
                        else:
                            xp = round(x * wc / wp) if wp else 0
                            xp = min(max(xp, 0), len(positions) - 1)
                            k, offset = positions[xp] if positions else (k0, 0)
                    else:
                        x = base + j
                        xp = x if wp == wc else round(x * wc / wp) if wp else 0
                        xp = min(max(xp, 0), len(positions) - 1)
                        k, offset = positions[xp] if positions else (k0, 0)
                    a, n, app_page = ayahs[k]
                    starts[(s, a)].append(offset * 2 + (1 if full else 0))
                    if pno != app_page:
                        page_mismatch += 1
                base += sp["w"]
    report.append(f"  merges {merges}, splits {splits}, unaligned surahs {unaligned}, "
                  f"line starts on another app page {page_mismatch}")
    report.append(f"  ayah groups whose print word count differs from the app's: {len(count_mismatch)} "
                  f"{count_mismatch[:10]}")

    table = {"v": 1, "s": {}}
    n_lines = 0
    for (surah, ayah), offs in sorted(starts.items()):
        uniq = sorted({o for o in offs}, key=lambda v: (v // 2, v))
        # one start per offset: if the same offset was recorded twice with different flags, full wins
        by_off = {}
        for o in uniq:
            by_off[o // 2] = max(by_off.get(o // 2, 0), o)
        table["s"].setdefault(str(surah), {})[str(ayah)] = [by_off[o] for o in sorted(by_off)]
        n_lines += len(by_off)
    raw = json.dumps(table, separators=(",", ":")).encode()
    comp = zlib.compressobj(9, zlib.DEFLATED, -15)
    blob = comp.compress(raw) + comp.flush()
    (APPDATA / f"Lines{key}.json.deflate").write_bytes(blob)
    (DATA / f"{slug}.lines.report.json").write_text(json.dumps(
        {"count_mismatch": count_mismatch, "page_diffs": page_diffs, "unaligned": unaligned}, ensure_ascii=False))
    report.append(f"  wrote Lines{key}.json.deflate: {n_lines} line starts, {len(raw):,} raw -> {len(blob):,} B")
    return table


if __name__ == "__main__":
    dump = json.loads((DATA / "printtokens.json").read_text())
    slugs = [a for a in sys.argv[1:] if not a.startswith("--")] or list(KEYS)
    for slug in slugs:
        report = [f"== {slug}"]
        try:
            build(slug, dump, report)
        except Exception as e:  # keep going, the report says which volume broke
            report.append(f"  ERROR {e!r}")
        print("\n".join(report), flush=True)
