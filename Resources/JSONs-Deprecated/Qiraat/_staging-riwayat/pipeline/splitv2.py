#!/usr/bin/env python3
"""Value-driven surah splitting for ALL volumes - marker values decode exactly now.

- New surah ⇔ marker value 1 whose successors continue 2,3 (exact values, no units
  guessing). Value-less (None) markers that BREAK the running v==prev+1 continuity are
  PHANTOMS (ornaments reusing bracket gids): their segment is merged into the next
  real segment's text (the glyphs are kept - they are body signs, not ayah ends).
- Verifies per-volume: 114 surahs and canonical totals.
"""
import json, sys, pathlib

BASE = pathlib.Path(__file__).resolve().parent
DATA = BASE / "data"
sys.path.insert(0, str(BASE))
from extract import raw_ayahs

EXPECT = {"hisham": 6226, "ibndhakwan": 6226, "khalaf": 6236, "khallad": 6236,
          "abuharith": 6236, "durikisai": 6236, "ibnwardan": 6214, "ibnjammaz": 6214,
          "ruways": 6204, "rawh": 6206, "ishaq": 6236, "idris": 6236,
          "shubah": 6236, "qaloon": 6214, "warsh": 6213, "duriabiamr": 6204,
          "susi": 6204, "qunbul": 6222}

def collapse_doubled(v):
    """66→6, 9900→90, 9966→96: digits duplicated pairwise (stroke+fill double-draw)."""
    if v is None: return None
    s = str(v)
    if len(s) % 2 == 0 and all(s[i] == s[i + 1] for i in range(0, len(s), 2)):
        return int(s[0::2])
    return None

def split(slug):
    raw = raw_ayahs(slug)
    # Shami-volume repair: some markers are drawn twice (doubled digits AND doubled
    # bracket pairs). Both fixes are gated on the expected-value counter so genuine
    # values like 22 are never touched.
    fixed = []
    expected = 1
    dbl = dropped = 0
    for glyphs, v in raw:
        if v is not None:
            prev_v = fixed[-1][1] if fixed else None
            # duplicate pair for the SAME ayah (raw or doubled form) with near-empty
            # text between the two draws: merge back into the previous ayah
            if prev_v is not None and len(glyphs) < 10 and (
                    v == prev_v or collapse_doubled(v) == prev_v):
                g_prev, _ = fixed[-1]
                fixed[-1] = (g_prev + [["sp", " "]] + glyphs, prev_v)
                dropped += 1
                continue
            # doubled digits (stroke+fill double-draw): only when the collapsed value
            # is what continuity expects - a genuine 22/33/... never collapses
            if v != expected and v != 1:
                c = collapse_doubled(v)
                if c is not None and (c == expected or c == 1):
                    v = c; dbl += 1
        fixed.append((glyphs, v))
        if v is not None:
            expected = v + 1
    # equal-neighbor smoothing: [n, n, n+2] → middle marker is n+1 (its own digits
    # were overprinted by the doubled layer of the neighbor)
    for i in range(1, len(fixed) - 1):
        a, b, c = fixed[i - 1][1], fixed[i][1], fixed[i + 1][1]
        if a is not None and b == a and c == a + 2:
            fixed[i] = (fixed[i][0], a + 1); dbl += 1
    if dbl or dropped:
        print(f"   {slug}: doubled-digit fixes={dbl}, duplicate-pair merges={dropped}")
    raw = fixed
    # 1) phantom repair: walk with expected counter; a None-valued marker that breaks
    #    continuity (next real value continues as if this segment didn't exist) merges
    #    forward into the following segment.
    repaired = []   # list of (glyphs, value)
    i = 0
    expected = 1
    carry = []
    merges = 0
    while i < len(raw):
        glyphs, v = raw[i]
        if v is None:
            nxt = raw[i + 1][1] if i + 1 < len(raw) else None
            # keep a None marker only when it plausibly IS the expected ayah
            # (its successor continues expected+1); else it's a phantom.
            if nxt is not None and nxt == expected + 1:
                repaired.append((carry + glyphs, None))
                carry = []
                expected += 1
            else:
                carry = carry + glyphs + [["sp", " "]]
                merges += 1
            i += 1
            continue
        if v == 1 and expected != 1:
            # candidate surah start; verified in phase 2 - just reset the counter
            follow = [raw[j][1] for j in range(i + 1, min(i + 3, len(raw)))]
            if any(x == k + 2 for k, x in enumerate(follow)):
                expected = 1
        if v == expected:
            repaired.append((carry + glyphs, v))
            carry = []
            expected += 1
        else:
            # continuity break with a real value: trust the value stream
            repaired.append((carry + glyphs, v))
            carry = []
            expected = v + 1
        i += 1
    if carry:
        if repaired:
            g, v = repaired[-1]
            repaired[-1] = (g + carry, v)
    # 2) surah boundaries: value==1 with follow 2,3
    surahs, current = [], []
    for idx, (glyphs, v) in enumerate(repaired):
        is_reset = False
        if v == 1 and current:
            follow = [repaired[j][1] for j in range(idx + 1, min(idx + 4, len(repaired)))]
            if sum(1 for k, x in enumerate(follow) if x == k + 2) >= 1 or not follow:
                is_reset = True
        if is_reset:
            surahs.append(current); current = []
        current.append(glyphs)
    if current:
        surahs.append(current)
    out = {"slug": slug, "surahs": [len(s) for s in surahs], "data": surahs}
    (DATA / f"{slug}.surahs.json").write_text(json.dumps(out, ensure_ascii=False))
    total = sum(len(s) for s in surahs)
    want = EXPECT.get(slug)
    ok = "OK " if (len(surahs) == 114 and total == want) else "FAIL"
    print(f"[{ok}] {slug}: {len(surahs)} surahs, {total} ayahs (want {want}), phantom-merges={merges}")
    if len(surahs) != 114:
        print("   counts:", [len(s) for s in surahs][:20])
    return len(surahs) == 114 and total == want

if __name__ == "__main__":
    allok = True
    for s in sys.argv[1:]:
        allok = split(s) and allok
    print("ALL OK" if allok else "SOME FAILED")
