#!/usr/bin/env python3
"""Islamweb riwayah-PDF → glyph streams → learned glyph→Unicode map → per-ayah JSON.

Phases:
  segment <slug>          → data/<slug>.surahs.json   (surah→[ayah glyph token seqs])
  learn <bridge...>       → data/glyphmap.json        (votes from app-known riwayat)
  apply <slug>            → data/<slug>.text.json     (+ unmapped report)
"""
import fitz, json, sys, os, collections, pathlib, re, difflib

BASE = pathlib.Path(__file__).resolve().parent
PDFS = BASE.parent / "pdfs"
DATA = BASE / "data"
DATA.mkdir(exist_ok=True)
APP = pathlib.Path("/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS")

MSH_IMALAH_GID = 38   # see page_tokens: the red imalah dot in the Khalaf volume
# The same layer carries the FARSH TEXT - the letters where this riwayah departs from
# Hafs, printed in magenta per the volumes' own legend (magenta = الكلمة المخالفة لحفص,
# blue = idgham, red = imalah, cyan = sakt, orange = ishmam). The HQPB body layer leaves a
# zero-width spacer where each one goes, so dropping this layer silently deletes exactly
# the letters that make a riwayah a riwayah: `جَبۡرَءِيلَ` lost its ء (2:97, 2:98, 66:4) and
# `وَلِيَسۡتَبِينَ` lost its ي (6:55). ~160 glyphs across the three Kufi volumes.
# Every INKED non-furniture glyph in that layer (the blank spacers and the two rosette
# gids 155/156 are excluded). Determined by outline bounds, not by eye.
MSH_TEXT_GIDS = frozenset({7, 8, 9, 10, 13, 16, 17, 29, 30, 33, 36, 39, 40, 41, 43, 44,
                           45, 46, 49, 52, 54, 55, 58, 60, 70, 72, 73, 74, 78, 87, 88, 96,
                           97, 98, 99, 101, 119, 170, 178, 210, 211, 217, 221})
# Which gids are INKED is per volume, because each embeds its own subset of the font: 39
# and 49 draw nothing in the Hamzah volumes, 13 draws nothing in the Al-Kisai ones but is
# a real mark in the Shami pair. So this set is the union, and a gid that is blank in a
# given volume simply never appears there. Only 155/156, the banner rosette, are excluded
# outright; the banner's stray body-size glyphs are cut by MSH_BANNER_RATIO instead.

SEP_WINDOW = (115.0, 772.0)
# Word separators live in the Times/Arial layer, but so do the running header, the footer
# and the margin numbers, and THEIR spaces are not word breaks. This is the y band in
# which a chrome space counts as a separator - a floor, not the whole answer. The two
# constants were read off the older volumes, whose text block starts at y=127 and ends at
# y=653. Abu Ja'far's volumes set their block tighter: on 61 Ibn Wardan pages and 26 Ibn
# Jammaz pages the top line lands at y=113.9-114.4, just under the 115 floor, so every
# space on it was thrown away and the whole line printed as one word - 60 and 27 ayahs,
# e.g. 4:7 `لِّلرِّجَالِنَصِيبٞمِّمَّاتَرَكَالۡوَٰلِدَٰنِ...`, concentrated in surahs 4-6 and 12-18.
#
# So the band is widened per page to whatever the Quran faces (HQPB*/Hamd*) actually
# cover, plus 4pt of slack for the separator's own baseline offset. It only ever grows,
# and it grows off the body text itself, so the furniture cannot creep in with it: the
# header is drawn in the MSH layer and the footer in DecoType, neither of which is
# consulted here. Measured over all 17 volumes, this admits 628 spaces in Ibn Wardan and
# 289 in Ibn Jammaz and changes nothing at all anywhere else - no volume loses a space,
# and all five bridges are byte-identical.
SEP_SLACK = 4.0
BODY_FACES = ("HQPB", "Hamd")

MSH_BANNER_RATIO = 1.10
# The MSH layer draws the surah-name banner larger than the body, and only the banner. What
# sits above the body size is the rosette (155/156) and the stray alef (101) left over from
# the banner line; everything at body size or below is real text, so gid 101 stays available
# as the real alef it is in the body (74:33 `إِذَا دَبَرَ`).
#
# The threshold has to be RELATIVE. It used to be an absolute 18pt, read off the Kufi
# volumes (body 12-14pt, banner 20pt). The Madani and Basri volumes set their body at
# 16-18.5pt, so that constant silently deleted their whole MSH layer wherever a page happened
# to be typeset at 18pt - and in those volumes MSH carries the AYAH NUMBERS (gids 19-28 are
# the digits 0-9). Ibn Wardan lost the numbers of 24 ayahs that way, nine of them consecutive
# at the head of Maryam, which left `segment` unable to see the surah boundary at all and
# merged al-Kahf and Maryam into one 203-ayah block.
#
# Measured MSH-size / dominant-body-size across every volume: text sits at 0.86-1.03 and the
# banner at 1.14 (shubah), 1.29 and 1.43 (khalaf). Nothing lands between 1.03 and 1.14.

def _is_msh_text(fontkey):
    """Real text in the MSH layer. See MSH_TEXT_GIDS."""
    base, _, gid = str(fontkey).rpartition("#")
    return base.startswith(("MSH", "Msh")) and gid.isdigit() and int(gid) in MSH_TEXT_GIDS

def _is_imalah_dot(fontkey):
    """Every spelling of the same mark: HQPB5 gid 20 (most volumes), HQPB7 gid 20, and
    MSH-Quraan1 gid 38 (the Khalaf volume's red dot). Normalised to the first downstream.

    HQPB7#20 is the same outline as HQPB5#20 - bounds (298,-1052,767,-600) in both, a blob
    well below the baseline - just carried in another of the font's embedded subsets, and
    the page range it covers happens to include six surah openings. Missing it cost the
    imalah dot of `طسم` at 28:1 in Khalaf, Abu al-Harith, ad-Duri an-Kisai, Ishaq and Idris
    (Khallad spells the same dot Hamd2#172, which the detmap already knew, so the pair
    disagreed with itself), plus 12-89 marks per volume elsewhere. The learner had scored
    the key as "draws nothing" and the shipped bridge text was papering over the gap.
    """
    base, _, gid = str(fontkey).rpartition("#")
    if base in ("HQPB5", "HQPB7") and gid == "20":
        return True
    return base.startswith(("MSH", "Msh")) and gid == str(MSH_IMALAH_GID)

LETTER_FONTS = {"HQPB1", "HQPB3", "HQPB5", "Hamd1", "Hamd2", "Hamd3"}
MARK_FONTS = {"HQPB2", "HQPB4", "HQPB6", "HQPB7"}
DROP_PREFIX = ("Times", "PTBold", "Arial", "DTPNaskh", "MSH", "Msh", "ArabicTransparent")
MARKER_RE = re.compile(r"^∩[^∩∪]{1,4}∪$")
DIGITS = {"⊃": 0, "⊇": 1, "⊄": 2, "⊂": 3, "⊆": 4, "∈": 5, "∉": 6, "∠": 7, "∇": 8, "∆": 9, "": 9,
          "0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9}

def marker_value(txt):
    v = 0
    for ch in txt[1:-1]:
        if ch not in DIGITS: return None
        v = v * 10 + DIGITS[ch]
    return v


def _gid(key):
    try:
        return int(str(key).rsplit("#", 1)[1])
    except Exception:
        return -1

def _is_hqpb2(key):
    return str(key).startswith("HQPB2#")

def _bracket_kind(key):
    if not _is_hqpb2(key): return None
    g = _gid(key)
    if g == 167: return "open"
    if g == 168: return "close"
    return None

def _digit_val(key):
    """HQPB2 gids 169-178 are the ten Arabic-Indic digits, 0 first. 179 is NOT a digit.

    Gid 179 is a body letter (the ya of `شَيۡءٖ`, among others), and the range has always
    run to 179, so it scores as a spurious "10". Narrowing the range is nonetheless WRONG
    to do on its own: `is_markerish` also keys off this function to hold a glyph out of the
    x-overlap clustering, so gid 179 has been learned as the standalone key `HQPB2#179|©`
    in every detmap. Narrow it and the glyph starts joining clusters under keys nothing has
    ever seen: shubah's round-trip falls from 90.56% to 75.84% on 1,286 UNMAPPED.

    It is harmless where it stands because a digit only ever gets consumed when it sits
    inside or within three characters of an ayah rosette, which measured zero times in the
    Kufi and Madani volumes. Left as-is deliberately; fixing it means relearning the map.
    """
    if not _is_hqpb2(key): return None
    g = _gid(key)
    return g - 169 if 169 <= g <= 179 else None

# ---------------------------------------------------------------- extraction

def rgb_int(color):
    """get_texttrace() fill colour -> 0xRRGGBB. Every one of the twenty volumes draws
    its text as opaque RGB fills (colorspace 3, type 0, opacity 1.0; 97 stroke-only
    spans in ~386k carry their colour in the same field), so no other space is handled."""
    if not color:
        return 0
    r, g, b = (color + (0.0, 0.0, 0.0))[:3]
    return (int(round(r * 255)) << 16) | (int(round(g * 255)) << 8) | int(round(b * 255))


def page_tokens(page):
    """All body tokens of one page, in reading order, from get_texttrace() - the ONLY
    extraction that exposes GLYPH IDs. The PDFs' ToUnicode tables collapse distinct
    glyphs onto shared chars (one 'char' served plain alef, wasla-alef, and a lillah
    ligature), so tokens are keyed on font#gid. The Unicode field is kept ONLY for
    structural detection (ayah-number brackets, digits, spaces).

    Tokens are grouped into x-overlap clusters per line; each cluster becomes one
    order-free multiset token (base letter + its floating marks)."""
    body = []
    CHROME = ("PTBold", "Arial", "DTPNaskh", "ArabicTransparent")
    # The page's own body size, for the relative MSH banner test; see MSH_BANNER_RATIO.
    _sizes = collections.Counter()
    _texty = []
    for sp in page.get_texttrace():
        f = sp.get("font", "?")
        if f.startswith("HQPB"):
            _sizes[round(sp.get("size", 0), 1)] += len(sp.get("chars", []))
        if f.startswith(BODY_FACES):
            _texty += [(c[3][1] + c[3][3]) / 2 for c in sp.get("chars", [])]
    body_size = _sizes.most_common(1)[0][0] if _sizes else 0
    # This page's own separator band; see SEP_WINDOW.
    sep_lo, sep_hi = SEP_WINDOW
    if _texty:
        sep_lo = min(sep_lo, min(_texty) - SEP_SLACK)
        sep_hi = max(sep_hi, max(_texty) + SEP_SLACK)
    for sp in page.get_texttrace():
        f = sp.get("font", "?")
        col = rgb_int(sp.get("color"))
        for uni, gid, org, bbox in sp.get("chars", []):
            x0, y0, x1, y1 = bbox
            yc = (y0 + y1) / 2
            ch = chr(uni)
            is_spacey = (ch == " " or uni in (32, 160))
            chrome = any(f.startswith(p) for p in CHROME) or f.startswith("Times")
            if is_spacey and chrome:
                # word separators live in the Times layer; body-font "spaces" are real
                # glyphs whose bogus ToUnicode maps to 32 (the ayah digit NINE, e.g.)
                if sep_lo < yc < sep_hi:
                    body.append((yc, x0, x1, "sp", None, col))
                continue
            if chrome:
                continue
            if f.startswith(("MSH", "Msh")):
                if body_size and sp.get("size", 0) > MSH_BANNER_RATIO * body_size:
                    continue        # surah-banner furniture; see MSH_BANNER_RATIO
                # This layer is mostly page furniture, but the Khalaf volume draws its
                # imalah dot here: gid 38, inked red, a below-baseline dot (font bounds
                # 118,-1300..587,-848). 2,846 of them in khalaf against 24 in khallad.
                # Dropping the whole layer silently cost ~500 imalah marks.
                if ch.isdigit() or gid == MSH_IMALAH_GID or gid in MSH_TEXT_GIDS:
                    body.append((yc, x0, x1, "g", (f"{f}#{gid}", ch), col))
                continue
            # everything else is body text/sign layers (HQPB*, Hamd*, DecoType*, ...)
            body.append((yc, x0, x1, "g", (f"{f}#{gid}", ch), col))
    if not body:
        return []
    ys = sorted(t[0] for t in body if t[3] != "sp")
    bands = []
    for y in ys:
        if bands and y - bands[-1][1] <= 9:
            bands[-1][1] = y
        else:
            bands.append([y, y])
    def band_of(y):
        best, bd = None, 1e9
        for i, (lo, hi) in enumerate(bands):
            if lo - 15 <= y <= hi + 15:
                d = abs(y - (lo + hi) / 2)
                if d < bd: best, bd = i, d
        return best
    per_band = collections.defaultdict(list)
    for yc, x0, x1, kind, payload, col in body:
        bi = band_of(yc)
        if bi is not None:
            per_band[bi].append((yc, x0, x1, kind, payload, col))
    MARKERISH = set("∩∪⊃⊇⊄⊂⊆∈∉∠∇") | {""}
    out = []
    for bi in sorted(per_band):
        toks = per_band[bi]
        # Bracket exclusion zones: everything with its x-center between a paired ∩..∪
        # is the ayah number's digits (whatever font/charset) and must stay OUT of
        # clusters so bracket assembly can consume it char-by-char.
        brackets = [t for t in toks if t[3] == "g" and ("∩" in t[4][1] or "∪" in t[4][1])]
        zones = []
        op = [t for t in brackets if "∩" in t[4][1]]
        cl = [t for t in brackets if "∪" in t[4][1] and "∩" not in t[4][1]]
        used = set()
        for o in op:
            best, bd = None, 24.0
            for k, c in enumerate(cl):
                if k in used: continue
                d = abs(((c[1] + c[2]) - (o[1] + o[2])) / 2)
                if d < bd: best, bd = k, d
            if best is not None:
                used.add(best)
                c = cl[best]
                zones.append((min(o[1], c[1]) - 2, max(o[2], c[2]) + 2))
        def in_zone(t):
            xc = (t[1] + t[2]) / 2
            return any(lo <= xc <= hi for lo, hi in zones)
        # Only real text glyphs cluster. sp / matched markers / marker-fragment spans /
        # MSH digit spans / bracket-zone digits stay singletons.
        def is_markerish(t):
            if t[3] != "g": return True
            f, txt = t[4]
            if f.startswith(("MSH", "Msh")):
                # the imalah dot and the standalone hamza are real text and must cluster
                return not (_is_imalah_dot(f) or _is_msh_text(f))
            if _bracket_kind(f) is not None or _digit_val(f) is not None: return True
            if all(ch in MARKERISH for ch in txt): return True
            return in_zone(t)
        gs = [t for t in toks if not is_markerish(t)]
        others = [t for t in toks if is_markerish(t)]
        # The imalah dot (HQPB5 gid 20) sits BELOW the baseline and rarely overlaps its
        # letter's bbox, so x-overlap clustering left it a stray singleton and its letter
        # attribution was guessed downstream ("dot on the wrong letter", "two dots").
        # Geometric truth instead: pull the dots out, merge the stroke/fill/color layer
        # copies (identical position), and attach each REAL dot to the letter cluster
        # whose span contains it.
        dots = [t for t in gs if _is_imalah_dot(t[4][0])]
        gs = [t for t in gs if not _is_imalah_dot(t[4][0])]
        gs.sort(key=lambda t: -((t[1] + t[2]) / 2))
        clusters = []
        for t in gs:
            placed = False
            if clusters:
                c = clusters[-1]
                lo = max(t[1], c["x0"]); hi = min(t[2], c["x1"])
                w = min(t[2] - t[1], c["x1"] - c["x0"])
                if hi - lo > 0.62 * max(w, 0.1) and len(c["toks"]) < 4:
                    c["toks"].append(t)
                    c["x0"] = min(c["x0"], t[1]); c["x1"] = max(c["x1"], t[2])
                    placed = True
            if not placed:
                clusters.append({"x0": t[1], "x1": t[2], "toks": [t]})
        if dots and clusters:
            uniq = []
            for t in sorted(dots, key=lambda t: (t[1] + t[2]) / 2):
                xc = (t[1] + t[2]) / 2
                if uniq and abs(xc - uniq[-1][0]) <= 2.5:
                    # A layer copy of the same dot. The copies are drawn one per colour
                    # layer, so a black copy and a red copy sit at the same x; the print
                    # shows the inked one, and taking whichever sorted first would have
                    # reported half the imalah dots as black.
                    if uniq[-1][1] == 0:
                        uniq[-1][1] = t[5]
                    continue
                uniq.append([xc, t[5]])
            for xc, dotcol in uniq:
                best = min(clusters, key=lambda c: 0 if c["x0"] <= xc <= c["x1"]
                           else min(abs(xc - c["x0"]), abs(xc - c["x1"])))
                if not any(_is_imalah_dot(m[4][0]) for m in best["toks"]):
                    best["toks"].append((0, xc, xc, "g", ("HQPB5#20", "1"), dotcol))
        # ONE token per cluster: an order-free multiset key. Mark-stack z-order was the
        # purity killer - inside a multiset there is no order to get wrong. Members are
        # kept in the key (joined by ||) so a fallback can decompose unseen combinations.
        items = []
        for c in clusters:
            # Sorted PAIRS, so the colour list stays index-aligned with the key's members
            # after the sort that makes the key order-free.
            pairs = sorted((f"{t[4][0]}|{t[4][1]}", t[5]) for t in c["toks"])
            members = [k for k, _ in pairs]
            xc = -(c["x0"] + c["x1"]) / 2
            items.append((xc, "g", ("CL", "||".join(members), [v for _, v in pairs])))
        for t in others:
            payload = t[4] if t[4] is None else (t[4][0], t[4][1], [t[5]])
            items.append((-(t[1] + t[2]) / 2, t[3], payload))
        items.sort(key=lambda z: z[0])
        for _, kind, payload in items:
            out.append((bi, kind, payload))
    return out

MARKER_CHARS = set("∩∪") | set(DIGITS)

# The PDFs are filed qiraah-first (`03-ibn-kathir-qunbul.pdf`) so the folder sorts into
# the ten readings, two riwayat under each. Everything below still speaks the short slugs.
PDF_NAMES = {
    # qiraah-first, numbered in the app's own Settings.Riwayah `order` sequence.
    "hafs": "01-asim-hafs", "shubah": "01-asim-shubah",
    "warsh": "02-nafi-warsh", "qaloon": "02-nafi-qalun",
    "warsh-asbahani": "02-nafi-warsh-tariq-al-asbahani",
    "bazzi": "03-ibn-kathir-al-bazzi", "qunbul": "03-ibn-kathir-qunbul",
    "duriabiamr": "04-abu-amr-ad-duri", "susi": "04-abu-amr-as-susi",
    "hisham": "05-ibn-amir-hisham", "ibndhakwan": "05-ibn-amir-ibn-dhakwan",
    "khalaf": "06-hamzah-khalaf", "khallad": "06-hamzah-khallad",
    "abuharith": "07-al-kisai-abu-al-harith", "durikisai": "07-al-kisai-ad-duri",
    "ibnwardan": "08-abu-jafar-ibn-wardan", "ibnjammaz": "08-abu-jafar-ibn-jammaz",
    "ibnjammaz-alt": "08-abu-jafar-ibn-jammaz-second-copy",
    "ruways": "09-yaqub-ruways", "rawh": "09-yaqub-rawh",
    "ishaq": "10-khalaf-al-ashir-ishaq", "idris": "10-khalaf-al-ashir-idris",
}


def pdf_path(slug):
    """The volume for a slug, from pipeline/../pdfs/<name>.pdf.

    DO NOT substitute `Resources/Mushaf PDFs/<name>.pdf.xz`. Those ship in the app and are
    display-only: the size optimisation that produced them merged text spans, destroying
    ~12,000 inter-word space tokens per volume. The glyphs survive, so a page still LOOKS
    right and still segments to the correct 6236 ayahs - but words run together, which
    silently corrupts the extracted text (1,201 of khalaf's 6,236 ayahs differ, and the
    Shubah bridge round-trip falls from 89.09% to 71.87%).

    Set QIRAAT_ALLOW_SHIPPED_PDFS=1 to use them anyway for a quick structural check; never
    for text you intend to keep.
    """
    for name in (PDF_NAMES.get(slug, slug), slug):
        candidate = PDFS / f"{name}.pdf"
        if candidate.exists():
            return candidate
    name = PDF_NAMES.get(slug, slug)
    packed = APP / "Resources/Mushaf PDFs" / f"{name}.pdf.xz"
    if packed.exists() and os.environ.get("QIRAAT_ALLOW_SHIPPED_PDFS") == "1":
        import lzma
        cache = BASE / "pdfcache"
        cache.mkdir(exist_ok=True)
        out = cache / f"{name}.pdf"
        if not out.exists() or out.stat().st_size == 0:
            print(f"  !! DEGRADED SOURCE: decompressing shipped {packed.name}; "
                  f"word spacing is lossy, text from this run is NOT trustworthy")
            out.write_bytes(lzma.decompress(packed.read_bytes()))
        return out
    hint = ""
    if packed.exists():
        hint = (f"\n  ({packed.name} exists but is the display-only shipped copy; it loses "
                f"word spaces.\n   Set QIRAAT_ALLOW_SHIPPED_PDFS=1 only for a structural check.)")
    raise FileNotFoundError(
        f"no extraction PDF for {slug!r}: put {name}.pdf in {PDFS}\n"
        f"  Source: https://archive.org/details/quran-islamweb.net (see pdfs/README.md){hint}"
    )


def extract_stream(slug):
    """Char-level stream. Marker glyphs (∩ digits ∪) can arrive as one span or split
    across several; assemble them from the exploded char run regardless."""
    doc = fitz.open(pdf_path(slug))
    chars = []  # ("sp",) | ("c", font, ch, [colour, ...])
    for page in doc:
        last_band = None
        for bi, kind, payload in page_tokens(page):
            if last_band is not None and bi != last_band:
                chars.append(("sp", None, None, None))
            last_band = bi
            if kind == "sp":
                chars.append(("sp", None, None, None))
            elif kind == "mark":  # pre-matched single-span marker: carry the decoded value through
                chars.append(("mk", payload, None, None))
            elif payload[0] == "CL":
                chars.append(("c", "CL", payload[1], payload[2]))
            else:
                f, t, cols = payload
                for ch in t:
                    chars.append(("c", f, ch, cols))
        chars.append(("sp", None, None, None))
    # assemble markers from char runs - SYMMETRIC bracket pairing: kerning jitter means
    # ∪ sometimes sorts before ∩N, so pair each ∩ with its nearest ∪ in EITHER direction,
    # take the digit chars positionally between them as the number, and leave every other
    # in-between char (neighboring diacritics) as ordinary glyphs.
    n = len(chars)
    opens = [i for i, k in enumerate(chars) if k[0] == "c" and _bracket_kind(k[1]) == "open"]
    closes = [i for i, k in enumerate(chars) if k[0] == "c" and _bracket_kind(k[1]) == "close"]
    used_close = set()
    consumed = {}          # index -> ("bracket"|"digit", pair_id)
    marker_at = {}         # first(index of pair) -> value
    pid = 0
    for oi in opens:
        best, bd = None, 99
        for ci in closes:
            if ci in used_close: continue
            d = abs(ci - oi)
            if d <= 30 and d < bd:
                best, bd = ci, d
        if best is None:
            continue
        used_close.add(best)
        lo, hi = min(oi, best), max(oi, best)
        digits = []
        for j in range(lo + 1, hi):
            cj = chars[j]
            if cj[0] == "c" and (_digit_val(cj[1]) is not None or (not str(cj[1]).startswith("HQPB") and cj[2] in "0123456789")):
                digits.append((j, cj[1], cj[2]))
        j = lo - 1
        while j >= 0 and lo - j <= 3:
            cj = chars[j]
            if cj[0] == "c" and _digit_val(cj[1]) is not None and j not in consumed:
                digits.append((j, cj[1], cj[2])); j -= 1
            else:
                break
        j = hi + 1
        while j < n and j - hi <= 3:
            cj = chars[j]
            if cj[0] == "c" and _digit_val(cj[1]) is not None and j not in consumed:
                digits.append((j, cj[1], cj[2])); j += 1
            else:
                break
        digits.sort()
        if len(digits) > 4:
            continue
        val = None
        if digits:
            val = 0
            # stream order is right-to-left; the number itself is written LTR
            for _, kf, c in reversed(digits):
                d = _digit_val(kf)
                if d is None:
                    d = DIGITS.get(c)
                if d is None:
                    val = None; break
                val = val * 10 + d
        consumed[oi] = ("bracket", pid); consumed[best] = ("bracket", pid)
        for j, _, _ in digits:
            consumed[j] = ("digit", pid)
        marker_at[lo] = val
        pid += 1
    stream = []
    for i, k in enumerate(chars):
        if i in marker_at:
            stream.append(("mark", marker_at[i]))
        if i in consumed:
            continue
        if k[0] == "sp":
            if stream and stream[-1][0] != "sp":
                stream.append(("sp", None))
        elif k[0] == "mk":
            stream.append(("mark", k[1]))
        else:
            # MSH digits that didn't get consumed by a bracket pair are margin numbers
            # (juz/hizb) - never body text.
            if k[1].startswith(("MSH", "Msh")):
                continue
            stream.append(("g", (k[1], k[2], k[3])))
    return stream

def _build_raw(slug):
    """Stream → (glyph_seq, marker_value) list plus an index-aligned colour list.

    The colours live in their OWN cache so `<slug>.raw.json` stays byte-for-byte what it
    was: the text pipeline and its five bridge roundtrips cannot be perturbed by the
    colour work, and `python3 extract.py verifyraw` proves it.
    """
    stream = extract_stream(slug)
    raw, cols, cur, curc = [], [], [], []
    for kind, payload in stream:
        if kind == "g":
            cur.append(list(payload[:2])); curc.append(payload[2])
        elif kind == "sp":
            if cur and cur[-1][0] != "sp":
                cur.append(["sp", " "]); curc.append(None)
        elif kind == "mark":
            while cur and cur[-1][0] == "sp":
                cur.pop(); curc.pop()
            raw.append((cur, payload)); cols.append(curc)
            cur, curc = [], []
    return raw, cols


def raw_ayahs(slug):
    """Stream → flat list of (glyph_seq, marker_value). Disk-cached (PDF parse ~1 min)."""
    cache = DATA / f"{slug}.raw.json"
    if cache.exists():
        d = json.loads(cache.read_text())
        return [(g, v) for g, v in d]
    raw, cols = _build_raw(slug)
    cache.write_text(json.dumps(raw, ensure_ascii=False))
    (DATA / f"{slug}.colors.json").write_text(json.dumps(cols))
    return raw


def raw_colors(slug):
    """Per-glyph 0xRRGGBB fill colour, one list per ayah, index-aligned with raw_ayahs().

    A cluster token is one key but several glyphs, so its entry is a LIST of colours,
    ordered to match the `||`-joined members of the key. A `["sp", " "]` entry is None."""
    cache = DATA / f"{slug}.colors.json"
    if cache.exists():
        return json.loads(cache.read_text())
    raw, cols = _build_raw(slug)
    (DATA / f"{slug}.raw.json").write_text(json.dumps(raw, ensure_ascii=False))
    cache.write_text(json.dumps(cols))
    return cols

def keyseq(glyphs):
    return [f"{f}|{c}" for f, c in glyphs if f != "sp"]

import unicodedata

def skeleton(text):
    """Letters only: no combining marks, no tatweel, wasla→alef, no spaces/unknowns."""
    out = []
    for ch in text:
        if unicodedata.combining(ch): continue
        if ch in " ـ�": continue
        out.append("ا" if ch == "ٱ" else ch)
    return "".join(out)

def is_basmalah_start(text):
    """Rendered segment begins with the basmalah? Variant glyphs may render as � (they
    are stripped); tolerate one substitution in the letter skeleton."""
    sk = skeleton(text)[:8]
    ref = "بسمالله"
    if len(sk) < 6: return False
    miss = sum(1 for a, b in zip(sk, ref) if a != b) + max(0, len(ref) - len(sk))
    return miss <= 1

def is_surah_start(text):
    """A rendered segment opens a new surah when its head carries the surah HEADER
    ('سورة ... وآياتها ...') and/or the basmalah within the first stretch."""
    sk = skeleton(text)
    if is_basmalah_start(text):
        return True
    head = sk[:44]
    if head.startswith("سورة") or "وءاياتها" in head or "واياتها" in head or "ءاياتها" in head:
        return True
    return "بسمالله" in head

def strip_surah_header(t):
    """Cut the printed surah banner: «سُورَةُ X مَكِّيَّةٌ وَءَايَاتُهَا N».

    Tolerant of the print noise around it: unresolved-glyph tokens (juz medallions)
    can precede or interleave the banner, and «وءاياتها» itself occasionally prints
    split across tokens - so the terminal word is matched on the skeleton stream with
    splits allowed, and «سورة» may carry ✗ pollution. No real ayah opens with a
    «سورة ... اياتها» pair, so the cut stays unambiguous (an-Nur's real «سُورَةٌ
    أَنزَلۡنَٰهَا» has no «اياتها» after it).
    """
    words = t.split()
    if not words:
        return t
    sks = [skeleton(w).strip("✗") for w in words]
    W = min(len(words), 22)
    surah_at = next((j for j in range(W) if sks[j].startswith("سور")), None)
    if surah_at is None:
        return t
    banner_end = None
    for i in range(surah_at + 1, W):
        sk = sks[i]
        if "اياتها" in sk:
            banner_end = i
            break
        # split print: '...يا' + 'تها' or 'ا' + 'ياتها' etc.
        if i + 1 < W and "اياتها" in (sk + sks[i + 1]):
            banner_end = i + 1
            break
    if banner_end is None:
        return t
    cut = banner_end + 1
    while cut < len(words):
        w, sk = words[cut], sks[cut]
        if w.isdigit() or sk.isdigit() or not sk or set(w) <= {"✗"}:
            cut += 1                      # the ayah count (digits, or lost to ✗)
        else:
            break
    return " ".join(words[cut:])

def strip_header_and_basmalah(t, keep_basmalah=False, tawbah=False):
    t = strip_surah_header(t)          # banner-first layouts
    """Cut the surah header (everything before the basmalah) and, unless kept, the
    basmalah's four words. Tawbah has no basmalah: cut through the 'وآياتها N' tail."""
    words = t.split()
    sks = [skeleton(w) for w in words]
    if tawbah:
        return strip_surah_header(t)
    for i in range(0, min(len(words) - 3, 12)):
        if sks[i].startswith("بسم") and i + 3 < len(words) and sks[i + 1] in ("الله", "اللە") :
            start = i if keep_basmalah else i + 4
            rest = " ".join(words[start:])
            # the banner can print before OR after the basmalah depending on the volume
            return strip_surah_header(rest) if not keep_basmalah else rest
    return strip_surah_header(t)

def segment(slug, bootstrap=False, det=False):
    """Bootstrap (shubah): marker-value resets - exact for its clean single-span vintage.
    Everyone else: render each raw segment with the current glyph map and cut surah
    boundaries where the TEXT begins with the basmalah (variant-glyph-proof). Tawbah is
    split from the Anfal superblock by the three textbook Anfal lengths vs marker units."""
    raw = raw_ayahs(slug)
    if bootstrap:
        surahs, current = [], []
        for i, (g, v) in enumerate(raw):
            is_reset = False
            if v == 1 and current:
                nxt = [raw[j][1] for j in range(i + 1, min(i + 4, len(raw)))]
                follow = sum(1 for k, x in enumerate(nxt) if x == k + 2)
                if follow >= 1 or not nxt:
                    is_reset = True
            if is_reset:
                surahs.append(current); current = []
            current.append(g)
        if current: surahs.append(current)
    else:
        if det:
            # The bootstrap glyphmap is a Kufi-era artifact and covers al-Bazzi's font
            # subset so poorly that not one surah header rendered readably: the volume
            # segmented to a single 6,220-ayah block. The deterministic map that the rest
            # of the pipeline already uses finds all 114 (and the same per-surah counts as
            # its Makki twin Qunbul), so this path renders with that instead.
            import final as _f
            _fam = _f.FAMILY.get(slug, "makki")
            _dm = _f.build_detmap(_fam)
            _cp = DATA / f"ctxdet-{_fam}.json"
            _cx = json.loads(_cp.read_text()) if _cp.exists() else None
            _render = lambda g: _f.render_det(g, _dm, None, family=_fam, ctx=_cx, slug=slug)
        else:
            mapping = json.loads((DATA / "glyphmap.json").read_text())
            rules = json.loads((DATA / "ctxrules.json").read_text()) if (DATA / "ctxrules.json").exists() else None
            _render = lambda g: render(g, mapping, rules=rules)
        bounds = [0]
        for i in range(1, len(raw)):
            if raw[i][0] and is_surah_start(_render(raw[i][0])):
                bounds.append(i)
        blocks = [[raw[j] for j in range(bounds[k], bounds[k + 1] if k + 1 < len(bounds) else len(raw))]
                  for k in range(len(bounds))]
        if len(blocks) == 113:
            sup = blocks[7]
            choice = None
            for cand in (75, 76, 77):
                if cand >= len(sup): continue
                prev_v, at_v = sup[cand - 1][1], sup[cand][1]
                score = 0
                if at_v == 1 or (at_v is not None and at_v % 10 == 1): score += 1
                if prev_v is not None and prev_v % 10 == cand % 10: score += 1
                nxt = [sup[j][1] for j in range(cand + 1, min(cand + 3, len(sup)))]
                score += sum(1 for k, x in enumerate(nxt) if x is not None and x % 10 == (k + 2) % 10)
                if choice is None or score > choice[1]:
                    choice = (cand, score)
            cand = choice[0]
            blocks = blocks[:7] + [sup[:cand], sup[cand:]] + blocks[8:]
            print(f"   Tawbah split: Anfal={cand} (score {choice[1]})")
        elif len(blocks) != 114:
            print(f"   WARN: {len(blocks)} blocks (expect 113 pre-Tawbah-split / 114)")
        surahs = [[g for g, v in b] for b in blocks]
    # A zero-glyph ayah is never real text, only a doubled ayah marker. The two Shami
    # volumes produce 59 and 60 of them; every other volume produces none, and dropping
    # them lands hisham/ibndhakwan on the 6222 that `shami_fix.py` expects before it
    # recovers the 4 markers lost across page boundaries. Left in, they inflate the count
    # to 6281/6282 and shift every later ayah id by one.
    dropped_empty = sum(1 for su in surahs for a in su if not a)
    if dropped_empty:
        surahs = [[a for a in su if a] for su in surahs]
        print(f"   dropped {dropped_empty} zero-glyph ayahs (doubled markers)")

    out = {"slug": slug, "surahs": [len(s) for s in surahs], "data": surahs}
    (DATA / f"{slug}.surahs.json").write_text(json.dumps(out, ensure_ascii=False))
    total = sum(len(s) for s in surahs)
    print(f"{slug}: {len(surahs)} surahs, {total} ayahs")
    print("   counts:", [len(s) for s in surahs][:15], "...")
    return out

# ---------------------------------------------------------------- learning

def overlay(name):
    # Hafs is not an overlay file - it is the app's primary text, and the only bridge whose
    # every ayah is KFGQPC-verified AND whose Kufi count (6236) matches the Kufi volumes
    # ayah-for-ayah, so no surah is ever skipped for a count mismatch.
    if name == "__quran__":
        d = json.loads((APP / "Resources/JSONs-Deprecated/Quran.json").read_text())
        return {s["id"]: [(a["id"], a["textArabic"]) for a in s["ayahs"]] for s in d}
    d = json.loads((APP / f"Resources/JSONs-Deprecated/Qiraat/{name}.json").read_text())
    return {int(k): [(a["id"], a["text"]) for a in v] for k, v in d.items()}

BRIDGES = {
    "hafs": "__quran__",
    "shubah": "QiraahShubah",
    "qaloon": "QiraahQaloon",
    "warsh": "QiraahWarsh",
    "duriabiamr": "QiraahDuri",
    "susi": "QiraahSusi",
    "qunbul": "QiraahQunbul",
    # al-Bazzi subsets its fonts into an entirely different gid range from its Makki twin
    # (#222-235 against Qunbul's), so 98% of its glyphs were unknown to a map learned from
    # Qunbul alone and 42% of its text rendered as nothing. It has a verified text of its
    # own, so it learns like any other bridge.
    "bazzi": "QiraahBuzzi",
}

def glyph_words(glyphs):
    w, out = [], []
    for f, c in glyphs:
        if f == "sp":
            if w: out.append(w); w = []
        else:
            w.append((f, c))
    if w: out.append(w)
    return out

def _pairing_skeleton(t):
    """Consonant skeleton used only to test whether two ayahs are THE SAME ayah.
    Marks, pause signs and spacing all differ between a render and its app text even
    when the pairing is perfect, so none of them may take part in the decision."""
    return "".join(c for c in t if not unicodedata.combining(c)
                   and c not in " \u0640\u06d6\u06d7\u06d8\u06d9\u06da\u06db\u06de\u06e9")


PAIR_CUTOFF = 0.75
# Skeleton similarity below which a (glyphs, text) pair is NOT the same ayah.
#
# Equal ayah COUNTS in a surah do not imply equal ayah BOUNDARIES, which is what the
# positional zip below silently assumes. Surah 3 of the Basri volumes has 200 ayahs and
# so does the app's Duri text, but they split ayah 48 differently, so every pair from
# there on was handing the learner one volume's glyphs beside a different ayah's text.
# 329 of duriabiamr's 3,374 pairs (9.8%) were wrong that way, and the learner has no way
# to notice: it just accumulates the mis-emissions as evidence.
#
# Measured separation, with the family's own detmap doing the rendering: shubah scores
# >=0.90 on 6,122 of 6,122 pairs, and the drifted Basri pairs land at 0.33-0.63. Nothing
# sits between, so 0.75 discards drift without touching a single genuine pair - including
# the badly-rendered ones, which are exactly the learning signal we must not lose.


def _ayah_alignment(vol_sk, app_sk, band=8):
    """Banded Needleman-Wunsch over two ayah lists. Returns [(vol_i, app_j, sim), ...].

    The volume and the app text do not always cut a surah in the same places, and when
    they do not, the whole surah used to be discarded. They still agree about almost
    every ayah in it, though: al-Zalzalah is 8 ayahs in the printed Qaloon and 9 in the
    app because the app splits `يومئذ يصدر الناس أشتاتا` from `ليروا أعمالهم`, and the
    other seven correspond exactly. Aligning instead of zipping keeps those seven.

    A gap is what a merge or a split looks like from here, so gaps are cheap; aligning
    two ayahs that are not the same ayah is the error this exists to prevent, so a
    sub-0.6 match scores worse than any number of gaps.
    """
    n, m = len(vol_sk), len(app_sk)
    if abs(n - m) > band:
        return None
    GAP, FLOOR = -0.35, 0.60
    sm = difflib.SequenceMatcher(autojunk=False)
    sim = {}
    for jj in range(m):
        sm.set_seq2(app_sk[jj])           # cached by SequenceMatcher, so set b outermost
        for ii in range(max(0, jj - band), min(n, jj + band + 1)):
            sm.set_seq1(vol_sk[ii])
            q = sm.quick_ratio()
            # quick_ratio ignores order and only ever over-estimates, so a real ratio is
            # worth computing exactly where it might clear the bar.
            sim[(ii, jj)] = sm.ratio() if q >= PAIR_CUTOFF - 0.10 else q
    NEG = float("-inf")
    best = [[NEG] * (m + 1) for _ in range(n + 1)]
    back = [[None] * (m + 1) for _ in range(n + 1)]
    best[0][0] = 0.0
    for ii in range(n + 1):
        for jj in range(m + 1):
            b = best[ii][jj]
            if b == NEG or abs(ii - jj) > band + 1:
                continue
            s_ = sim.get((ii, jj))
            if s_ is not None:
                v = b + (s_ if s_ >= FLOOR else -1.0)
                if v > best[ii + 1][jj + 1]:
                    best[ii + 1][jj + 1] = v; back[ii + 1][jj + 1] = (ii, jj, True)
            if ii < n and b + GAP > best[ii + 1][jj]:
                best[ii + 1][jj] = b + GAP; back[ii + 1][jj] = (ii, jj, False)
            if jj < m and b + GAP > best[ii][jj + 1]:
                best[ii][jj + 1] = b + GAP; back[ii][jj + 1] = (ii, jj, False)
    if best[n][m] == NEG:
        return None
    out, ii, jj = [], n, m
    while (ii, jj) != (0, 0):
        pi, pj, matched = back[ii][jj]
        if matched:
            out.append((pi, pj, sim[(pi, pj)]))
        ii, jj = pi, pj
    out.reverse()
    return out


def collect_pairs(bridge_slugs, skip_first=True, render=None):
    """Pair each volume ayah with its app text.

    `render(glyphs) -> str` enables the correspondence check described at PAIR_CUTOFF
    and the realignment described at _ayah_alignment. Pass it whenever a detmap already
    exists; without it the pairing is taken on trust and a surah whose counts disagree
    is dropped whole, which is only safe while bootstrapping a family that has no map.
    """
    pair_bank = []
    for slug in bridge_slugs:
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        ov = overlay(BRIDGES[slug])
        if len(seg["data"]) != 114:
            print(f"{slug}: SKIP whole volume, {len(seg['data'])} surah blocks")
            continue
        used = skipped = dropped = realigned = 0
        for sid in range(1, 115):
            vol = seg["data"][sid - 1]
            app_ayahs = ov[sid]
            start = 1 if skip_first else 0

            if render is None:
                if len(vol) != len(app_ayahs):
                    skipped += 1
                    continue
                for k in range(start, len(vol)):
                    aid, text = app_ayahs[k]
                    pair_bank.append((vol[k], text, slug, sid, aid, k == 0))
                used += 1
                continue

            rend = [_pairing_skeleton(render(g)) for g in vol]
            apps = [_pairing_skeleton(t) for _, t in app_ayahs]
            # Ayah 1 is always ayah 1: a merge or a split further down cannot move it,
            # and its glyphs carry the surah header and the basmalah, so it scores far
            # too low to survive an alignment. Align the tails and re-attach it.
            pairs = None
            if len(vol) == len(app_ayahs):
                fast = [(k, k, difflib.SequenceMatcher(None, rend[k], apps[k]).quick_ratio())
                        for k in range(1, len(vol))]
                if all(s >= PAIR_CUTOFF for _, _, s in fast):
                    pairs = fast
            if pairs is None:
                pairs = _ayah_alignment(rend[1:], apps[1:])
                if pairs is None:
                    skipped += 1
                    continue
                pairs = [(a + 1, b + 1, s) for a, b, s in pairs]
                realigned += 1
            if not skip_first:
                pairs = [(0, 0, 1.0)] + pairs

            for vi, aj, s in pairs:
                if s < PAIR_CUTOFF:
                    dropped += 1
                    continue
                aid, text = app_ayahs[aj]
                pair_bank.append((vol[vi], text, slug, sid, aid, vi == 0))
            dropped += (len(vol) - start) - len(pairs)
            used += 1
        note = f" realigned={realigned} unpaired={dropped}" if render is not None else ""
        print(f"{slug}: surahs used={used} skipped={skipped}{note}")
    return pair_bank

def learn(bridge_slugs, iters=6):
    """Decipherment EM: monotonic banded DP where each glyph token emits 0..4 chars of
    the known Unicode text. Emission stats accumulate across iterations; spaces are soft
    anchors ('sp|' strongly prefers ' ')."""
    import math
    pair_bank = collect_pairs(bridge_slugs)
    print(f"pairs for EM: {len(pair_bank)}")
    seeds = {}
    seedfile = DATA / "glyphmap.json"
    if seedfile.exists():
        seeds = json.loads(seedfile.read_text())
    counts = collections.defaultdict(collections.Counter)
    for k, v in seeds.items():
        counts[k][v] += 50
    LEN_PRIOR = {0: math.log(1e-4), 1: math.log(2e-3), 2: math.log(4e-4), 3: math.log(1e-4),
                 4: math.log(3e-5), 5: math.log(8e-6), 6: math.log(2e-6), 7: math.log(6e-7),
                 8: math.log(2e-7), 9: math.log(6e-8), 10: math.log(2e-8)}
    MAXL = 10
    BAND = 40

    ecache = {}
    totals = {}

    def emis_logp(key, e):
        ck = (key, e)
        v = ecache.get(ck)
        if v is not None:
            return v
        c = counts.get(key)
        if c:
            n = c.get(e, 0)
            if n:
                tot = totals.get(key)
                if tot is None:
                    tot = sum(c.values()); totals[key] = tot
                v = math.log(n / (tot + 2))
                ecache[ck] = v
                return v
        if key == "sp| ":
            v = math.log(0.85) if e == " " else (math.log(0.1) if e == "" else -18.0)
        else:
            v = LEN_PRIOR[len(e)]
        ecache[ck] = v
        return v

    def align(keys, Y):
        m, n = len(keys), len(Y)
        NEG = -1e18
        prev = [NEG] * (n + 1)
        prev[0] = 0.0
        back = [[0] * (n + 1) for _ in range(m + 1)]
        ratio = n / max(m, 1)
        for i in range(1, m + 1):
            curr = [NEG] * (n + 1)
            key = keys[i - 1]
            center = ratio * i
            jlo = max(0, int(center) - BAND)
            jhi = min(n, int(center) + BAND)
            for j in range(jlo, jhi + 1):
                best, bl = NEG, 0
                for L in range(0, MAXL + 1):
                    if j - L < 0: break
                    p = prev[j - L]
                    if p <= NEG / 2: continue
                    s = p + emis_logp(key, Y[j - L:j])
                    if s > best:
                        best, bl = s, L
                curr[j] = best
                back[i][j] = bl
            prev = curr
        if prev[n] <= NEG / 2:
            return None
        # backtrace
        out = []
        j = n
        for i in range(m, 0, -1):
            L = back[i][j]
            out.append((keys[i - 1], Y[j - L:j]))
            j -= L
        out.reverse()
        return out

    def keys_of(glyphs):
        return [("sp| " if f == "sp" else f"{f}|{c}") for f, c in glyphs]

    import random
    rng = random.Random(7)
    subset = pair_bank if len(pair_bank) < 4200 else rng.sample(pair_bank, 4200)
    for it in range(iters):
        bank = subset if it < iters - 2 else pair_bank
        ecache.clear(); totals.clear()
        new = collections.defaultdict(collections.Counter)
        aligned = failed = 0
        for glyphs, text, slug, sid, aid, first in bank:
            keys = keys_of(glyphs)
            path = align(keys, text)
            if path is None:
                failed += 1
                continue
            aligned += 1
            for k, e in path:
                new[k][e] += 1
        for k, v in seeds.items():
            new[k][v] += 30
        counts = new
        print(f"  EM iter {it}: bank={len(bank)} aligned={aligned} failed={failed} keys={len(counts)}")
    mapping, fuzzy = {}, {}
    for k, ctr in counts.items():
        e, n = ctr.most_common(1)[0]
        tot = sum(ctr.values())
        if (n >= 3 and n / tot >= 0.85) or (n == 2 and n / tot >= 0.99) or (tot == 1):
            mapping[k] = e
        else:
            fuzzy[k] = ctr.most_common(4)
    mapping["sp| "] = " "
    print(f"mapping: {len(mapping)} keys, fuzzy: {len(fuzzy)} → learning context rules")

    # Context pass: fuzzy keys usually co-vary with a NEIGHBOR (a kasra that sometimes
    # rides the next letter's cluster). Re-align everything once more and bucket each
    # fuzzy key's emissions by (next key) then (prev key); pure buckets become rules.
    ecache.clear(); totals.clear()
    ctx_next = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
    ctx_prev = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
    for glyphs, text, slug, sid, aid, first in pair_bank:
        keys = keys_of(glyphs)
        if not any(k in fuzzy for k in keys):
            continue
        path = align(keys, text)
        if path is None: continue
        for idx, (k, e) in enumerate(path):
            if k in fuzzy:
                nk = path[idx + 1][0] if idx + 1 < len(path) else "$"
                pk = path[idx - 1][0] if idx > 0 else "^"
                ctx_next[k][nk][e] += 1
                ctx_prev[k][pk][e] += 1
    rules = {}
    resolved = 0
    for k in fuzzy:
        r = {}
        for tag, table in (("n", ctx_next.get(k, {})), ("p", ctx_prev.get(k, {}))):
            for nb, ctr in table.items():
                e, n = ctr.most_common(1)[0]
                if n >= 2 and n / sum(ctr.values()) >= 0.85:
                    r[f"{tag}:{nb}"] = e
        # global fallback: overall majority even if impure (better than losing the token)
        allc = collections.Counter()
        for ctr in ctx_next.get(k, {}).values(): allc.update(ctr)
        if allc:
            e, n = allc.most_common(1)[0]
            if n / sum(allc.values()) >= 0.6:
                r["*"] = e
        if r: resolved += 1
        rules[k] = r
    import os
    _fam = os.environ.get("EXTRACT_FAMILY", "")
    _cname = f"glyphcounts-{_fam}.json" if _fam else "glyphcounts.json"
    (DATA / _cname).write_text(json.dumps(
        {k: dict(v) for k, v in counts.items()}, ensure_ascii=False, sort_keys=True))
    (DATA / "glyphmap.json").write_text(json.dumps(mapping, ensure_ascii=False, indent=1, sort_keys=True))
    (DATA / "ctxrules.json").write_text(json.dumps(rules, ensure_ascii=False, indent=1, sort_keys=True))
    (DATA / "glyphfuzzy.json").write_text(json.dumps(fuzzy, ensure_ascii=False, indent=1, sort_keys=True, default=str))
    print(f"context rules for {resolved}/{len(fuzzy)} fuzzy keys")
    # round-trip on the full bank WITH rules
    ok = diff = shown = 0
    for glyphs, text, slug, sid, aid, first in pair_bank:
        r = render2(glyphs, mapping, rules=rules)
        if r == text:
            ok += 1
        else:
            diff += 1
            if shown < 6:
                shown += 1
                print(f"  ≠ {slug} {sid}:{aid}\n    got {r[:100]!r}\n    exp {text[:100]!r}")
    print(f"round-trip: {ok} exact, {diff} diff  ({ok/max(ok+diff,1):.1%})")

def render2(glyphs, mapping, missing=None, rules=None):
    keys = ["sp| " if f == "sp" else f"{f}|{c}" for f, c in glyphs]
    out = []
    for i, k in enumerate(keys):
        v = mapping.get(k)
        if v is None and rules is not None:
            r = rules.get(k)
            if r:
                nk = keys[i + 1] if i + 1 < len(keys) else "$"
                pk = keys[i - 1] if i > 0 else "^"
                v = r.get(f"n:{nk}")
                if v is None: v = r.get(f"p:{pk}")
                if v is None: v = r.get("*")
        if v is None:
            if missing is not None: missing[k] += 1
            out.append("�")
        else:
            out.append(v)
    return re.sub(r"\s+", " ", "".join(out)).strip()

def render(glyphs, mapping, missing=None, rules=None):
    return render2(glyphs, mapping, missing, rules)

def strip_basmalah(t):
    """Drop the leading basmalah by WORD COUNT - robust even when a variant glyph in it
    rendered as � (exact string matching would miss those)."""
    words = t.split()
    if len(words) > 4 and is_basmalah_start(t):
        return " ".join(words[4:])
    return t

def apply(slug):
    seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
    mapping = json.loads((DATA / "glyphmap.json").read_text())
    rules = json.loads((DATA / "ctxrules.json").read_text()) if (DATA / "ctxrules.json").exists() else None
    missing = collections.Counter()
    out = {}
    if len(seg["data"]) != 114:
        print(f"{slug}: WARN {len(seg['data'])} surah blocks (expect 114)")
    for sid, surah in enumerate(seg["data"], 1):
        ayahs = []
        for aid, glyphs in enumerate(surah, 1):
            t = render(glyphs, mapping, missing, rules)
            t = re.sub(r"\s+", " ", t).strip()
            if aid == 1:
                if sid == 9:
                    t = strip_header_and_basmalah(t, tawbah=True)
                elif sid == 1:
                    # Keep the basmalah, drop the header; Kufi volumes then have it as
                    # ayah 1 (basmalah-only segment). Non-Kufi (basmalah + alhamdu in
                    # one segment) drop it too.
                    t = strip_header_and_basmalah(t, keep_basmalah=True)
                    if len(t.split()) > 5:
                        t = strip_header_and_basmalah(t, keep_basmalah=False)
                else:
                    t = strip_header_and_basmalah(t, keep_basmalah=False)
            ayahs.append({"id": aid, "text": t})
        out[str(sid)] = ayahs
    (DATA / f"{slug}.text.json").write_text(json.dumps(out, ensure_ascii=False))
    n_missing = sum(missing.values())
    print(f"{slug}: rendered; unmapped glyph occurrences={n_missing} unique={len(missing)}")
    for k, n in missing.most_common(20):
        print(f"   MISSING {k!r} ×{n}")
    return out

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "segment":
        for s in sys.argv[2:]: segment(s)
    elif cmd == "segmentdet":
        for s in sys.argv[2:]: segment(s, det=True)
    elif cmd == "bootstrap":
        segment(sys.argv[2], bootstrap=True)
    elif cmd == "learn":
        learn(sys.argv[2:])
    elif cmd == "apply":
        for s in sys.argv[2:]: apply(s)
    elif cmd == "verifyraw":
        # Phase-1 gate for the colour work: rebuild the glyph stream from the PDF and
        # prove it is byte-for-byte the cached raw.json, so nothing the text pipeline
        # reads has moved. Writes the colour cache as a side effect.
        bad = 0
        for s in sys.argv[2:]:
            was = (DATA / f"{s}.raw.json").read_text()
            raw, cols = _build_raw(s)
            now = json.dumps(raw, ensure_ascii=False)
            ok = (now == was)
            nglyph = sum(len(c) for c in cols)
            ninked = sum(1 for c in cols for e in c if e and any(v for v in e))
            print(f"{s:<12} raw {'IDENTICAL' if ok else '*** CHANGED ***'}  "
                  f"ayahs={len(raw)} glyph-slots={nglyph} inked-slots={ninked}")
            if ok:
                (DATA / f"{s}.colors.json").write_text(json.dumps(cols))
            else:
                bad += 1
        sys.exit(1 if bad else 0)
