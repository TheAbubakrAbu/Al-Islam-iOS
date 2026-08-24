#!/usr/bin/env python3
"""Islamweb riwayah-PDF → glyph streams → learned glyph→Unicode map → per-ayah JSON.

Phases:
  segment <slug>          → data/<slug>.surahs.json   (surah→[ayah glyph token seqs])
  learn <bridge...>       → data/glyphmap.json        (votes from app-known riwayat)
  apply <slug>            → data/<slug>.text.json     (+ unmapped report)
"""
import fitz, json, sys, os, collections, pathlib, re

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
MSH_TEXT_GIDS = frozenset({7, 9, 17, 29, 30, 33, 36, 41, 43, 46, 54, 55, 58, 60, 70, 73,
                           78, 87, 96, 97, 98, 119, 170, 178, 210, 221})

def _is_msh_text(fontkey):
    """Real text in the MSH layer. See MSH_TEXT_GIDS."""
    base, _, gid = str(fontkey).rpartition("#")
    return base.startswith(("MSH", "Msh")) and gid.isdigit() and int(gid) in MSH_TEXT_GIDS

def _is_imalah_dot(fontkey):
    """Both spellings of the same mark: HQPB5 gid 20 (most volumes) and MSH-Quraan1
    gid 38 (the Khalaf volume's red dot). Normalised to the former downstream."""
    if fontkey == "HQPB5#20":
        return True
    base, _, gid = str(fontkey).rpartition("#")
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
    if not _is_hqpb2(key): return None
    g = _gid(key)
    return g - 169 if 169 <= g <= 179 else None

# ---------------------------------------------------------------- extraction

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
    for sp in page.get_texttrace():
        f = sp.get("font", "?")
        for uni, gid, org, bbox in sp.get("chars", []):
            x0, y0, x1, y1 = bbox
            yc = (y0 + y1) / 2
            ch = chr(uni)
            is_spacey = (ch == " " or uni in (32, 160))
            chrome = any(f.startswith(p) for p in CHROME) or f.startswith("Times")
            if is_spacey and chrome:
                # word separators live in the Times layer; body-font "spaces" are real
                # glyphs whose bogus ToUnicode maps to 32 (the ayah digit NINE, e.g.)
                if 115 < yc < 772:
                    body.append((yc, x0, x1, "sp", None))
                continue
            if chrome:
                continue
            if f.startswith(("MSH", "Msh")):
                # This layer is mostly page furniture, but the Khalaf volume draws its
                # imalah dot here: gid 38, inked red, a below-baseline dot (font bounds
                # 118,-1300..587,-848). 2,846 of them in khalaf against 24 in khallad.
                # Dropping the whole layer silently cost ~500 imalah marks.
                if ch.isdigit() or gid == MSH_IMALAH_GID or gid in MSH_TEXT_GIDS:
                    body.append((yc, x0, x1, "g", (f"{f}#{gid}", ch)))
                continue
            # everything else is body text/sign layers (HQPB*, Hamd*, DecoType*, ...)
            body.append((yc, x0, x1, "g", (f"{f}#{gid}", ch)))
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
    for yc, x0, x1, kind, payload in body:
        bi = band_of(yc)
        if bi is not None:
            per_band[bi].append((yc, x0, x1, kind, payload))
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
                if uniq and abs(xc - uniq[-1]) <= 2.5:
                    continue                     # a layer copy of the same dot
                uniq.append(xc)
            for xc in uniq:
                best = min(clusters, key=lambda c: 0 if c["x0"] <= xc <= c["x1"]
                           else min(abs(xc - c["x0"]), abs(xc - c["x1"])))
                if not any(_is_imalah_dot(m[4][0]) for m in best["toks"]):
                    best["toks"].append((0, xc, xc, "g", ("HQPB5#20", "1")))
        # ONE token per cluster: an order-free multiset key. Mark-stack z-order was the
        # purity killer - inside a multiset there is no order to get wrong. Members are
        # kept in the key (joined by ||) so a fallback can decompose unseen combinations.
        items = []
        for c in clusters:
            members = sorted(f"{t[4][0]}|{t[4][1]}" for t in c["toks"])
            xc = -(c["x0"] + c["x1"]) / 2
            items.append((xc, "g", ("CL", "||".join(members))))
        for t in others:
            items.append((-(t[1] + t[2]) / 2, t[3], t[4]))
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
    chars = []  # ("sp",) | ("c", font, ch)
    for page in doc:
        last_band = None
        for bi, kind, payload in page_tokens(page):
            if last_band is not None and bi != last_band:
                chars.append(("sp", None, None))
            last_band = bi
            if kind == "sp":
                chars.append(("sp", None, None))
            elif kind == "mark":  # pre-matched single-span marker: carry the decoded value through
                chars.append(("mk", payload, None))
            elif payload[0] == "CL":
                chars.append(("c", "CL", payload[1]))
            else:
                f, t = payload
                for ch in t:
                    chars.append(("c", f, ch))
        chars.append(("sp", None, None))
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
            stream.append(("g", (k[1], k[2])))
    return stream

def raw_ayahs(slug):
    """Stream → flat list of (glyph_seq, marker_value). Disk-cached (PDF parse ~1 min)."""
    cache = DATA / f"{slug}.raw.json"
    if cache.exists():
        d = json.loads(cache.read_text())
        return [(g, v) for g, v in d]
    stream = extract_stream(slug)
    raw, cur = [], []
    for kind, payload in stream:
        if kind == "g":
            cur.append(list(payload))
        elif kind == "sp":
            if cur and cur[-1][0] != "sp":
                cur.append(["sp", " "])
        elif kind == "mark":
            while cur and cur[-1][0] == "sp": cur.pop()
            raw.append((cur, payload))
            cur = []
    cache.write_text(json.dumps(raw, ensure_ascii=False))
    return raw

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

def segment(slug, bootstrap=False):
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
        mapping = json.loads((DATA / "glyphmap.json").read_text())
        rules = json.loads((DATA / "ctxrules.json").read_text()) if (DATA / "ctxrules.json").exists() else None
        bounds = [0]
        for i in range(1, len(raw)):
            if is_surah_start(render(raw[i][0], mapping, rules=rules)):
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

def collect_pairs(bridge_slugs, skip_first=True):
    pair_bank = []
    for slug in bridge_slugs:
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        ov = overlay(BRIDGES[slug])
        if len(seg["data"]) != 114:
            print(f"{slug}: SKIP whole volume, {len(seg['data'])} surah blocks")
            continue
        used = skipped = 0
        for sid in range(1, 115):
            vol = seg["data"][sid - 1]
            app_ayahs = ov[sid]
            if len(vol) != len(app_ayahs):
                skipped += 1
                continue
            for k, (glyphs, (aid, text)) in enumerate(zip(vol, app_ayahs)):
                first = (k == 0)
                if first and skip_first:
                    # surah header + unnumbered basmalah prefix the glyphs; text has neither
                    continue
                pair_bank.append((glyphs, text, slug, sid, aid, first))
            used += 1
        print(f"{slug}: surahs used={used} count-mismatch={skipped}")
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
    elif cmd == "bootstrap":
        segment(sys.argv[2], bootstrap=True)
    elif cmd == "learn":
        learn(sys.argv[2:])
    elif cmd == "apply":
        for s in sys.argv[2:]: apply(s)
