#!/usr/bin/env python3
"""Build the v2 tajweed packs for the 7 non-beta (KFGQPC) riwayat.

v2 rules come from the ORIGINAL texts' own marks, letter-exact:
  imalah 065C / taqlil 06EA / silah 06E5-06E6 / the idgham bare+shadda and
  initial-shadda orthography / Warsh naql-badal-raa-lam-leen patterns / khilaf
  letters via normalized diff against the aligned Hafs token.
The v1 extraction packs (Scripts/tajweed-extraction/v1-extraction-packs/,
print-ink word flags from the Islamweb mushaf PDFs) contribute the khilaf word
flags and Warsh's print-listed idgham; everything else is text-derived.

Run from anywhere:  python3 Scripts/build_tajweed_v2.py --write
then:               python3 Scripts/build_solidpacks.py
Validation report prints either way; --write also replaces
Resources/Data/Quran/Tajweed<Name>.json.deflate.
"""
import json, zlib, sys, os, struct, lzma
from collections import Counter, defaultdict
from difflib import SequenceMatcher

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
V1DIR = os.path.join(ROOT, "Scripts", "tajweed-extraction", "v1-extraction-packs")
WRITE = "--write" in sys.argv

# ---------------- the 7 riwayah texts, straight from qiraat.qpk ----------------
def _decompress(codec, blob, rlen):
    if codec == 2:
        return lzma.decompress(blob)
    if codec == 1:
        return zlib.decompress(blob, -15)
    return blob

def load_qiraat_qpk():
    d = open(os.path.join(ROOT, "Resources", "Data", "Quran", "qiraat.qpk"), "rb").read()
    magic, ver, ecodec, bcodec, bcount, _res, _rec, _unit, eoff, eclen, erlen = struct.unpack_from("<IHBBHHIIIII", d, 0)
    table = [struct.unpack_from("<IIII", d, 48 + 16 * i) for i in range(bcount)]
    eager = _decompress(ecodec, d[eoff:eoff + eclen], erlen)
    pos = 0
    def u32():
        nonlocal pos
        v = struct.unpack_from("<I", eager, pos)[0]; pos += 4; return v
    def u16():
        nonlocal pos
        v = struct.unpack_from("<H", eager, pos)[0]; pos += 2; return v
    out = {}
    for _ in range(u32()):
        klen = u32()
        key = eager[pos:pos + klen].decode(); pos += klen
        surahs = [(u32(), u32()) for _ in range(u32())]
        bidx = u16()
        first, offset, clen, rlen = table[bidx]
        blob = _decompress(bcodec, d[offset:offset + clen], rlen)
        p2 = 0
        texts = defaultdict(dict)
        for sid, acount in surahs:
            for _ in range(acount):
                aid, tlen = struct.unpack_from("<II", blob, p2); p2 += 8
                texts[str(sid)][str(aid)] = blob[p2:p2 + tlen].decode(); p2 += tlen
        out[key] = dict(texts)
    return out

qpk = load_qiraat_qpk()
quran = json.load(open(os.path.join(ROOT, "Resources", "JSONs-Deprecated", "Quran.json")))

HAFS_T = defaultdict(dict)
for s in quran:
    for a in s["ayahs"]:
        HAFS_T[int(s["id"])][int(a["id"])] = a["textArabic"]

def is_base(cp):
    return 0x0621 <= cp <= 0x064A or cp in (0x0671, 0x0649, 0x066E, 0x06CC, 0x067E)

def tokens(text):
    return [t for t in text.replace(" ", " ").split(" ") if t]

def clusterize(tok):
    out = []
    cur = None
    for ch in tok:
        if is_base(ord(ch)):
            cur = (ch, [])
            out.append(cur)
        elif cur is not None:
            cur[1].append(ch)
    return out

SHADDA = "ّ"; SUKOON = "ۡ"; FATHA = "َ"; KASRA = "ِ"; DAMMA = "ُ"
DAGGER = "ٰ"; MADDAH = "ٓ"; SMALL_WAW = "ۥ"; SMALL_YEH = "ۦ"
FATHATAN = "ً"; DAMMATAN = "ٌ"; KASRATAN = "ٍ"
TAN_OPEN_K = "ٖ"; TAN_OPEN_D = "ٗ"; TAN_OPEN_F = "ٞ"
IMALAH = "ٜ"; RING = "۪"; HIGHDOT = "۬"; SEEN_ABOVE = "ۜ"
HAMZA_ABOVE = "ٔ"; HAMZA_BELOW = "ٕ"
VOCAL = {FATHA, KASRA, DAMMA, FATHATAN, DAMMATAN, KASRATAN, SHADDA, "ْ",
         SUKOON, DAGGER, TAN_OPEN_K, TAN_OPEN_D, TAN_OPEN_F, HAMZA_ABOVE, HAMZA_BELOW}
HAMZA_BASES = set("ءأإؤئ")  # ء أ إ ؤ ئ
ISTILA = set("خصضطظغق")
YARMALOON = set("يرملون")

def skel(tok, norm_hamza=False):
    s = "".join(ch for ch in tok if is_base(ord(ch))).replace("ٱ", "ا")
    if norm_hamza:
        for a, b in [("أ", "ا"), ("إ", "ا"), ("ؤ", "و"),
                     ("ئ", "ي"), ("ء", "")]:
            s = s.replace(a, b)
    return s

def texts_of(key):
    if key == "hafs":
        return {str(s): {str(a): t for a, t in v.items()} for s, v in HAFS_T.items()}
    return qpk[key]

TOKS = {}
CLS = {}
for key in ["hafs", "susi", "duri", "shubah", "warsh", "qaloon", "bazzi", "qunbul"]:
    t = defaultdict(dict)
    c = defaultdict(dict)
    for s, ayat in texts_of(key).items():
        for a, text in ayat.items():
            tk = tokens(text)
            t[int(s)][int(a)] = tk
            c[int(s)][int(a)] = [clusterize(x) for x in tk]
    TOKS[key] = t
    CLS[key] = c

def marks(c):
    return set(c[1])

def bare(c):
    return not (marks(c) & VOCAL)

# ---------------- v1 packs (extraction originals, restored from git HEAD -
# the Resources copies are the v2 output of this very script) ----------------
def load_v1(name):
    blob = open(os.path.join(V1DIR, f"{name}.json.deflate"), "rb").read()
    return json.loads(zlib.decompress(blob, -15))

V1 = {k: load_v1(n) for k, n in [
    ("warsh", "TajweedWarsh"), ("qaloon", "TajweedQaloon"), ("duri", "TajweedDuri"),
    ("susi", "TajweedSusi"), ("bazzi", "TajweedBazzi"), ("qunbul", "TajweedQunbul"),
    ("shubah", "TajweedShubah")]}

def v1_words(key):
    d = V1[key]
    keyOf = {e["c"]: e.get("k", e["c"]) for e in d.get("legend", [])}
    words = defaultdict(dict)
    for s, ayahs in d.get("rules", {}).items():
        for a, ws in ayahs.items():
            for wi, v in ws.items():
                c = v if isinstance(v, str) else v[0]
                words[keyOf.get(c, c)][(int(s), int(a), int(wi))] = v
    return words

V1W = {k: v1_words(k) for k in V1}

# ---------------- hafs token alignment (per surah, via SequenceMatcher on skeletons) ----------------
# maps riwayah (s, a, wi) -> hafs token string, for khilaf letter-diff extents.
ALIGNED = {}

def build_alignment(key):
    m = {}
    for s in TOKS[key]:
        r_flat = []   # (a, wi, skel)
        for a in sorted(TOKS[key][s]):
            for wi, tok in enumerate(TOKS[key][s][a]):
                r_flat.append((a, wi, skel(tok, norm_hamza=False)))
        h_flat = []
        for a in sorted(TOKS["hafs"][s]):
            for wi, tok in enumerate(TOKS["hafs"][s][a]):
                h_flat.append((a, wi, skel(tok, norm_hamza=False)))
        sm = SequenceMatcher(None, [x[2] for x in r_flat], [x[2] for x in h_flat], autojunk=False)
        for tag, i1, i2, j1, j2 in sm.get_opcodes():
            if tag == "equal":
                for k in range(i2 - i1):
                    ra, rwi, _ = r_flat[i1 + k]
                    ha, hwi, _ = h_flat[j1 + k]
                    m[(s, ra, rwi)] = (ha, hwi)
            elif tag == "replace" and (i2 - i1) == (j2 - j1):
                for k in range(i2 - i1):
                    ra, rwi, _ = r_flat[i1 + k]
                    ha, hwi, _ = h_flat[j1 + k]
                    m[(s, ra, rwi)] = (ha, hwi)
    return m

def hafs_tok(key, s, a, wi):
    hit = ALIGNED[key].get((s, a, wi))
    if not hit:
        return None
    ha, hwi = hit
    return TOKS["hafs"][s][ha][hwi]

# ---------------- rule extractors ----------------
def add(rules, s, a, wi, c, lo, hi):
    rules[s][a].setdefault(wi, []).append([c, lo, hi])

def new_rules():
    return defaultdict(lambda: defaultdict(dict))

def inclined_extent(cl, ci):
    """marked cluster + following bare inclined vowel (alef/maqsura)."""
    if ci + 1 < len(cl) and cl[ci + 1][0] in "اىٱ" and bare(cl[ci + 1]):
        return ci, ci + 1
    return ci, ci

def extract_imalah(key, rules, letter):
    n = 0
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                for ci, c in enumerate(cl):
                    if IMALAH in c[1]:
                        lo, hi = inclined_extent(cl, ci)
                        add(rules, s, a, wi, letter, lo, hi)
                        n += 1
    return n

def extract_taqlil(key, rules, letter):
    n = 0
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                for ci, c in enumerate(cl):
                    if RING in c[1] and not (ci == 0 and c[0] == "ا"):
                        lo, hi = inclined_extent(cl, ci)
                        add(rules, s, a, wi, letter, lo, hi)
                        n += 1
    return n

def extract_silah_meem(key, rules, letter):
    n = 0
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                for ci, c in enumerate(cl):
                    if c[0] == "م" and SMALL_WAW in c[1]:
                        add(rules, s, a, wi, letter, ci, ci)
                        n += 1
    return n

def extract_ha_dhamir(key, rules, letter):
    # ha with silah letter, word-shape unknown to hafs (global skeleton set)
    hafs_ha = set()
    for s, ayat in CLS["hafs"].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                if any(c[0] == "ه" and (SMALL_WAW in c[1] or SMALL_YEH in c[1]) for c in cl):
                    hafs_ha.add(skel(TOKS["hafs"][s][a][wi]))
    n = 0
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                for ci, c in enumerate(cl):
                    if c[0] == "ه" and (SMALL_WAW in c[1] or SMALL_YEH in c[1]):
                        if skel(TOKS[key][s][a][wi]) in hafs_ha:
                            continue
                        add(rules, s, a, wi, letter, ci, ci)
                        n += 1
    return n

# ---- idgham (kabir + khilaf saghir), susi/duri/shubah/warsh ----
def hafs_idgham_keys():
    within = set()  # (skel, b1, b2)
    cross = set()   # (prevskel, skel) both hamza-normalized
    for s, ayat in CLS["hafs"].items():
        for a, toks in ayat.items():
            tlist = TOKS["hafs"][s][a]
            for wi, cl in enumerate(toks):
                for ci in range(len(cl) - 1):
                    if bare(cl[ci]) and SHADDA in cl[ci + 1][1]:
                        within.add((skel(tlist[wi]), cl[ci][0].replace("ٱ", "ا"), cl[ci + 1][0]))
                if cl and SHADDA in cl[0][1]:
                    prev = tlist[wi - 1] if wi > 0 else None
                    if prev is None and a - 1 in TOKS["hafs"][s]:
                        prev = TOKS["hafs"][s][a - 1][-1]
                    if prev is not None:
                        cross.add((skel(prev, True), skel(tlist[wi], True)))
    return within, cross

H_WITHIN, H_CROSS = hafs_idgham_keys()

def extract_idgham(key, rules, letter):
    sites = 0
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            tlist = TOKS[key][s][a]
            for wi, cl in enumerate(toks):
                if not cl:
                    continue
                # (a) within-token: bare + shadda next (not sun-lam after initial alef)
                for ci in range(len(cl) - 1):
                    if bare(cl[ci]) and SHADDA in cl[ci + 1][1] and cl[ci][0] not in "اوىٱ":
                        if ci == 1 and cl[0][0] in "اٱ" and cl[ci][0] == "ل":
                            continue  # definite article sun-lam
                        k = (skel(tlist[wi]), cl[ci][0].replace("ٱ", "ا"), cl[ci + 1][0])
                        if k in H_WITHIN:
                            continue
                        add(rules, s, a, wi, letter, ci, ci + 1)
                        sites += 1
                # (b) word-initial shadda
                if SHADDA in cl[0][1]:
                    if wi > 0:
                        prev = (s, a, wi - 1)
                    elif a - 1 in TOKS[key][s]:
                        prev = (s, a - 1, len(TOKS[key][s][a - 1]) - 1)
                    else:
                        prev = None
                    if prev is None:
                        continue
                    ptok = TOKS[key][prev[0]][prev[1]][prev[2]]
                    pcl = CLS[key][prev[0]][prev[1]][prev[2]]
                    if not pcl:
                        continue
                    # ordinary noon-sakinah/tanwin idgham written with shadda (Maghribi orthography)
                    plast = pcl[-1]
                    tanwin = marks(plast) & {FATHATAN, DAMMATAN, KASRATAN, TAN_OPEN_K, TAN_OPEN_D, TAN_OPEN_F}
                    if cl[0][0] in YARMALOON and ((plast[0] == "ن" and bare(plast)) or tanwin):
                        continue
                    if (skel(ptok, True), skel(tlist[wi], True)) in H_CROSS:
                        continue
                    add(rules, s, a, wi, letter, 0, 0)
                    add(rules, prev[0], prev[1], prev[2], letter, len(pcl) - 1, len(pcl) - 1)
                    sites += 1
    return sites

# ---- warsh derived ----
def is_hamza_cluster(c):
    return c[0] in HAMZA_BASES or c[0] == "آ" or HAMZA_ABOVE in c[1] or HAMZA_BELOW in c[1]

def extract_warsh_badal(rules, letter):
    key = "warsh"
    n = 0
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                for ci, c in enumerate(cl):
                    if not is_hamza_cluster(c):
                        continue
                    if c[0] == "آ":
                        add(rules, s, a, wi, letter, ci, ci); n += 1; continue
                    if DAGGER in c[1]:
                        add(rules, s, a, wi, letter, ci, ci); n += 1; continue
                    if ci + 1 >= len(cl):
                        continue
                    nb = cl[ci + 1]
                    madd = ((nb[0] == "ا" and bare(nb))
                            or (nb[0] == "و" and bare(nb) and DAMMA in c[1])
                            or (nb[0] == "ي" and bare(nb) and KASRA in c[1]))
                    if not madd:
                        continue
                    if ci + 2 < len(cl) and is_hamza_cluster(cl[ci + 2]):
                        continue  # muttasil
                    add(rules, s, a, wi, letter, ci, ci + 1)
                    n += 1
    # naql (hamza's vowel moved onto the preceding sakin, hamza dropped) - the
    # print colors these cyan with the badal family (p3: عذابٌ اَليم / في الَارض).
    TANWIN = {FATHATAN, DAMMATAN, KASRATAN, TAN_OPEN_K, TAN_OPEN_D, TAN_OPEN_F}
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                ht = hafs_tok(key, s, a, wi)
                if ht is None or not any(ch in "أإ" for ch in ht):
                    continue  # hafs counterpart must carry the (seat) hamza
                # Only the STANDALONE naql is colored in the print (عذابٌ اَليم p3);
                # the article kind (الَارض) is systematic and stays black there.
                # Context: word-initial voweled alef, previous word ends in tanwin
                # or its final letter is voweled here where Hafs has sukoon (قَدَ اَفۡلَحَ).
                c0 = cl[0]
                if not (c0[0] == "ا" and (marks(c0) & {FATHA, KASRA, DAMMA})
                        and RING not in c0[1] and HIGHDOT not in c0[1]):
                    continue
                if not (ht[0] in "أإ"):
                    continue
                if wi > 0:
                    ps, pa, pwi = s, a, wi - 1
                elif a - 1 in TOKS[key][s]:
                    ps, pa, pwi = s, a - 1, len(TOKS[key][s][a - 1]) - 1
                else:
                    continue
                pcl = CLS[key][ps][pa][pwi]
                if not pcl:
                    continue
                plast = pcl[-1]
                naql_ctx = bool(marks(plast) & TANWIN)
                if not naql_ctx and (marks(plast) & {FATHA, KASRA, DAMMA}):
                    hp = hafs_tok(key, ps, pa, pwi)
                    if hp is not None:
                        hpcl = clusterize(hp)
                        if hpcl and SUKOON in hpcl[-1][1]:
                            naql_ctx = True
                if naql_ctx:
                    add(rules, s, a, wi, letter, 0, 0)
                    n += 1
    return n

def extract_warsh_leen(rules, letter):
    key = "warsh"
    n = 0
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                for ci in range(1, len(cl)):
                    c = cl[ci]
                    if c[0] not in "وي" or SUKOON not in c[1]:
                        continue
                    if FATHA not in cl[ci - 1][1]:
                        continue
                    if HAMZA_ABOVE in c[1] or HAMZA_BELOW in c[1] \
                       or (ci + 1 < len(cl) and is_hamza_cluster(cl[ci + 1])):
                        add(rules, s, a, wi, letter, ci - 1, ci)
                        n += 1
    return n

def extract_warsh_lam(rules, letter):
    key = "warsh"
    n = 0
    LVOWELS = {FATHA, FATHATAN, TAN_OPEN_D, TAN_OPEN_F}
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                for ci in range(1, len(cl)):
                    c = cl[ci]
                    if c[0] != "ل" or not (marks(c) & LVOWELS):
                        continue
                    p = cl[ci - 1]
                    if p[0] not in "صطظ":
                        continue
                    pm = marks(p)
                    if (pm & {FATHA, SUKOON, SHADDA}) and not (pm & {KASRA, DAMMA, KASRATAN, DAMMATAN}):
                        add(rules, s, a, wi, letter, ci, ci)
                        n += 1
    return n

AAJAMI = ["اسرءيل",  # اسرءيل
          "ابرهيم", "ابرهم",  # ابرهيم ابرهم
          "عمرن"]  # عمرن

MUQATTAAT = {"الم", "المص", "الر", "المر", "كهيعص", "طه", "طسم", "طس",
             "يس", "ص", "حم", "عسق", "ق", "ن"}

def extract_warsh_raa(rules, letter, pack_words):
    key = "warsh"
    n = 0
    RA_TARGET = {FATHA, DAMMA, FATHATAN, DAMMATAN, TAN_OPEN_D, TAN_OPEN_F}
    core_sites = {}
    khulf_sites = {}
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                wsk = skel(TOKS[key][s][a][wi])
                for ci, c in enumerate(cl):
                    if c[0] != "ر" or not (marks(c) & RA_TARGET):
                        continue
                    if any(x in wsk for x in AAJAMI):
                        continue
                    # istila later in the word blocks tarqiq
                    if any(cl[j][0] in ISTILA for j in range(ci + 1, len(cl))):
                        continue
                    # doubled ra later in the word -> khulf bucket
                    doubled = any(cl[j][0] == "ر" for j in range(ci + 1, len(cl)))
                    if ci == 0:
                        continue
                    p = cl[ci - 1]
                    pm = marks(p)
                    light = False
                    khulf = False
                    if KASRA in pm:
                        light = True
                    elif p[0] == "ي" and (SUKOON in pm or bare(p)):
                        light = True
                    elif ci > 1 and (SUKOON in pm or bare(p)):
                        pp = cl[ci - 2]
                        if KASRA in marks(pp):
                            if p[0] in ISTILA:
                                khulf = True
                            else:
                                light = True
                    if not (light or khulf):
                        continue
                    if doubled:
                        khulf, light = True, False
                    if light:
                        core_sites[(s, a, wi, ci)] = True
                    elif khulf:
                        khulf_sites[(s, a, wi, ci)] = True
    packset = set(pack_words)
    for (s, a, wi, ci) in core_sites:
        add(rules, s, a, wi, letter, ci, ci)
        n += 1
    for (s, a, wi, ci) in khulf_sites:
        if (s, a, wi) in packset:
            add(rules, s, a, wi, letter, ci, ci)
            n += 1
    return n

# ---- khilaf from v1 pack + mark refinement + hafs-diff extents ----
def mark_khilaf_extent(key, cl):
    """Clusters whose marks are khilaf evidence for THIS riwayah's orthography:
    seen-above always; the hamza-tashil dots/rings depending on how the edition
    uses them (wasl dots and taqlil rings are NOT khilaf)."""
    out = []
    for ci, c in enumerate(cl):
        ms = set(c[1])
        if SEEN_ABOVE in ms:
            out.append(ci)
            continue
        if not (RING in ms or HIGHDOT in ms):
            continue
        if key in ("bazzi", "qunbul"):
            out.append(ci)  # no wasl-dot system: every dot/ring is a hamza mark
        elif key == "qaloon":
            if ci > 0:      # word-initial = wasl dot; mid-word = tashil/ikhtilas
                out.append(ci)
        else:  # warsh/duri/susi: rings are taqlil; only mid-word HIGH dots are tashil
            if ci > 0 and HIGHDOT in ms:
                out.append(ci)
    return out

def hafs_diff_extent(key, s, a, wi, cl):
    ht = hafs_tok(key, s, a, wi)
    if ht is None:
        return None
    hcl = clusterize(ht)
    rb = [c[0].replace("ٱ", "ا") for c in cl]
    hb = [c[0].replace("ٱ", "ا") for c in hcl]
    if rb == hb:
        # marks-only diff
        if len(cl) == len(hcl):
            diff = [ci for ci in range(len(cl))
                    if set(cl[ci][1]) - {RING, HIGHDOT} != set(hcl[ci][1]) - {RING, HIGHDOT}]
            if diff:
                return min(diff), max(diff)
        return None
    lo = 0
    while lo < len(rb) and lo < len(hb) and rb[lo] == hb[lo]:
        lo += 1
    hi_r, hi_h = len(rb) - 1, len(hb) - 1
    while hi_r >= lo and hi_h >= lo and rb[hi_r] == hb[hi_h]:
        hi_r -= 1
        hi_h -= 1
    if hi_r < lo:
        hi_r = lo
    if hi_r >= len(rb):
        return None
    # a converted bare madd letter sounds through its predecessor's vowel
    # (مُو of بمومنين): include the vowel-carrying letter in the paint.
    if lo > 0 and all(cl[j][0] in "ويا" and bare(cl[j]) for j in range(lo, hi_r + 1)):
        lo -= 1
    return lo, min(hi_r, len(rb) - 1)

# Marks that are layout/orthography, not reading: wasl dots & rings (tashil is
# handled by the mark rules), waqf signs, the silent-letter zeros, iqlab meems
# (context hints), and the madd wave (length hint, not a letter difference).
NONREADING = {RING, HIGHDOT, "ۖ", "ۗ", "ۘ", "ۚ", "ۛ", "۟", "۠", "ۢ", "ۭ", MADDAH}

def norm_clusters(cl, word_initial_hamza=True):
    """(base, markset) pairs normalized so orthography-only conventions do not
    read as differences between these editions and Hafs:
      - ٱ=ا, and word-initial أ/إ=ا (qat' hamza written as plain voweled alef)
      - a word-initial wasl alef (dot-marked) drops its ibtida vowel
      - the definite-article/لل lam drops ALL its marks (their الذين family
        and لله are written without shadda; naql puts a vowel there)
      - hamza seats fold: ئ=(ى+ٔ), ؤ=(و+ٔ); hamza-below counts as hamza-above
      - NONREADING marks are stripped."""
    skl = "".join(c[0] for c in cl).replace("ٱ", "ا")
    art_lam = None
    for pref in ("ال", "وال", "فال", "بال", "كال", "تال", "لل", "ولل", "فلل"):
        if skl.startswith(pref):
            art_lam = len(pref) - 1
            break
    out = []
    for ci, c in enumerate(cl):
        b = c[0].replace("ٱ", "ا")
        ms = set(c[1]) - NONREADING
        if b == "ئ":
            b = "ى"; ms.add(HAMZA_ABOVE)
        elif b == "ؤ":
            b = "و"; ms.add(HAMZA_ABOVE)
        elif b == "ء":
            b = "ى"; ms.add(HAMZA_ABOVE)
        if HAMZA_BELOW in ms:
            ms.discard(HAMZA_BELOW); ms.add(HAMZA_ABOVE)
        if ci == 0 and word_initial_hamza and b in "أإ":
            b = "ا"; ms.discard(HAMZA_ABOVE)
        wasl = b == "ا" and (c[0] == "ٱ" or RING in c[1] or HIGHDOT in c[1] or "۟" in c[1]
                             or (art_lam is not None and ci == art_lam - 1))
        if wasl:
            ms -= {FATHA, KASRA, DAMMA}   # wasl alef: ibtida hint, not reading
        if ci == art_lam and b == "ل":
            ms.clear()
        out.append((b, ms))
    # tanwin written on the trailing alef instead of its letter (اَبَداَۢ) - move it back
    if len(out) >= 2 and out[-1][0] == "ا" and FATHATAN in out[-1][1]:
        out[-1] = ("ا", out[-1][1] - {FATHATAN})
        out[-2] = (out[-2][0], out[-2][1] | {FATHATAN})
    return out

def expand_daggers(norm):
    """Canonicalize the dagger alef to a full bare alef so غَمَٰم == غَمَام.
    Returns (expanded list, map expanded-index -> original-index)."""
    out = []
    idx = []
    for ci, (b, ms) in enumerate(norm):
        if DAGGER in ms:
            out.append((b, ms - {DAGGER}))
            idx.append(ci)
            out.append(("ا", set()))
            idx.append(ci)
        else:
            out.append((b, ms))
            idx.append(ci)
    return out, idx

def markdiff_extent(r, h):
    """Equal-skeleton compare; sukoon-vs-nothing is a writing convention."""
    diff = []
    for ci in range(len(r)):
        rm, hm = r[ci][1], h[ci][1]
        if rm == hm:
            continue
        if rm ^ hm == {SUKOON}:
            continue
        diff.append(ci)
    return diff

def article_naql_equal(r, h):
    """True when the words differ ONLY as the article-naql spelling: Hafs
    ..لۡ + أَ/إِX.. vs the riwayah ..لَ/لِ + bare-ا X.. (the print leaves these
    black; the naql rule colors only the standalone kind)."""
    if len(r) != len(h):
        return False
    for i in range(len(r) - 1):
        if h[i][0] == "ل" and h[i + 1][0] in "أإ" and r[i][0] == "ل" and r[i + 1][0] == "ا":
            rr = list(r)
            hh = list(h)
            rr[i] = ("ل", r[i][1] - {FATHA, KASRA, DAMMA})
            hh[i] = ("ل", h[i][1] - {SUKOON})
            rr[i + 1] = ("ا", r[i + 1][1])
            hh[i + 1] = ("ا", h[i + 1][1] - {FATHA, KASRA, DAMMA})
            return rr == hh
    return False

def idgham_orthography_equal(key, s, a, wi, r, h):
    """True when the only difference is the shadda these editions write on
    ordinary noon-sakinah/tanwin idgham (مَن يَّقُولُ vs Hafs مَن يَقُولُ)."""
    if len(r) != len(h) or not r:
        return False
    if r[0][1] - {SHADDA} != h[0][1] or SHADDA not in r[0][1] or SHADDA in h[0][1]:
        return False
    if any(r[i] != h[i] for i in range(1, len(r))):
        return False
    # previous word must end in bare noon or tanwin
    if wi > 0:
        pcl = CLS[key][s][a][wi - 1]
    elif a - 1 in CLS[key][s]:
        pcl = CLS[key][s][a - 1][-1]
    else:
        return False
    if not pcl:
        return False
    plast = pcl[-1]
    tanwin = marks(plast) & {FATHATAN, DAMMATAN, KASRATAN, TAN_OPEN_K, TAN_OPEN_D, TAN_OPEN_F}
    return bool(tanwin) or (plast[0] == "ن" and (bare(plast) or marks(plast) & VOCAL <= {SUKOON}))

def reading_diff(key, s, a, wi, cl):
    """None when no aligned Hafs token; else (identical, lo, hi) where lo/hi is
    the differing cluster extent in ORIGINAL cluster indexes (None, None when
    identical or when there is no local letter to paint)."""
    ht = hafs_tok(key, s, a, wi)
    if ht is None:
        return None
    hcl = clusterize(ht)
    r = norm_clusters(cl)
    h = norm_clusters(hcl)
    if article_naql_equal(r, h):
        return (True, None, None)
    if [x[0] for x in r] == [x[0] for x in h]:
        diff = markdiff_extent(r, h)
        if not diff:
            return (True, None, None)
        if idgham_orthography_equal(key, s, a, wi, r, h):
            return (True, None, None)
        return (False, min(diff), max(diff))
    # unequal skeletons: canonicalize dagger alefs and retry
    re_, rmap = expand_daggers(r)
    he, _ = expand_daggers(h)
    rb = [x[0] for x in re_]
    hb = [x[0] for x in he]
    if rb == hb:
        diff = markdiff_extent(re_, he)
        if not diff:
            return (True, None, None)
        return (False, rmap[min(diff)], rmap[max(diff)])
    lo = 0
    while lo < len(rb) and lo < len(hb) and rb[lo] == hb[lo] \
            and (re_[lo][1] == he[lo][1] or re_[lo][1] ^ he[lo][1] == {SUKOON}):
        lo += 1
    hi_r, hi_h = len(rb) - 1, len(hb) - 1
    while hi_r >= lo and hi_h >= lo and rb[hi_r] == hb[hi_h] \
            and (re_[hi_r][1] == he[hi_h][1] or re_[hi_r][1] ^ he[hi_h][1] == {SUKOON}):
        hi_r -= 1
        hi_h -= 1
    if hi_r < lo:
        hi_r = lo
    if hi_r >= len(rb):
        return (False, None, None)  # pure deletion vs hafs: no local letter to paint
    olo, ohi = rmap[lo], rmap[min(hi_r, len(rb) - 1)]
    if olo > 0 and all(cl[j][0] in "ويا" and not (set(cl[j][1]) & VOCAL) for j in range(olo, ohi + 1)):
        olo -= 1  # converted bare madd sounds through its predecessor's vowel
    return (False, olo, ohi)

def identical_to_hafs(key, s, a, wi, cl):
    d = reading_diff(key, s, a, wi, cl)
    return d is not None and d[0]

def merge_khilaf(key, rules, letter, v1_key, whole_word_edition):
    v1 = V1W[key].get(v1_key, {})
    stats = Counter()
    for (s, a, wi), v in v1.items():
        toks = CLS[key][s].get(a)
        if toks is None or wi >= len(toks):
            stats["dropped-oob"] += 1
            continue
        cl = toks[wi]
        if not cl:
            stats["dropped-empty"] += 1
            continue
        if identical_to_hafs(key, s, a, wi, cl):
            stats["dropped-identical"] += 1
            continue
        if whole_word_edition:
            add(rules, s, a, wi, letter, -1, -1)
            stats["whole"] += 1
            continue
        if isinstance(v, list) and len(v) == 3 and isinstance(v[1], int):
            lo, hi = v[1], min(v[2], len(cl))
            if 0 <= lo < hi:
                add(rules, s, a, wi, letter, lo, hi - 1)  # v1 hi is exclusive
                stats["v1-extent"] += 1
                continue
        mk = mark_khilaf_extent(key, cl)
        if mk:
            add(rules, s, a, wi, letter, min(mk), max(mk))
            stats["mark-extent"] += 1
            continue
        d = reading_diff(key, s, a, wi, cl)
        if d is not None and not d[0] and d[1] is not None:
            add(rules, s, a, wi, letter, d[1], d[2])
            stats["hafs-diff-extent"] += 1
        else:
            add(rules, s, a, wi, letter, -1, -1)
            stats["whole"] += 1
    # Words the extraction missed. Two text-derived sources, both letter-exact:
    #  * mark-attested khilaf (seen-sub, tashil dots) hafs doesn't share
    #  * any remaining READING difference vs the aligned Hafs token - the print
    #    colors every khilaf, so a diff the pack lacks is an extraction miss.
    for s, ayat in CLS[key].items():
        for a, toksl in ayat.items():
            for wi, cl in enumerate(toksl):
                if (s, a, wi) in v1 or not cl:
                    continue
                if rules[s][a].get(wi):
                    continue  # already carries a rule (silah/ha/imalah/...)
                mk = mark_khilaf_extent(key, cl)
                if mk:
                    ht = hafs_tok(key, s, a, wi)
                    if ht is not None:
                        hcl = clusterize(ht)
                        hmk = {ci for ci, c in enumerate(hcl)
                               if SEEN_ABOVE in c[1] or RING in c[1] or HIGHDOT in c[1]}
                        if set(mk) <= hmk:
                            continue
                    if whole_word_edition:
                        add(rules, s, a, wi, letter, -1, -1)
                    else:
                        add(rules, s, a, wi, letter, min(mk), max(mk))
                    stats["mark-added"] += 1
                    continue
                # muqatta'at carry vocalization these editions spell out - not khilaf
                sk = skel(TOKS[key][s][a][wi])
                if wi == 0 and a <= 2 and sk in MUQATTAAT:
                    continue
                # the moved-vowel side of a naql pair (وَإِذَ اَخَذۡنَا): the cyan
                # naql alef next door is the signal; do not double-flag the prev word
                if wi + 1 < len(toksl):
                    nx = toksl[wi + 1]
                    if nx and nx[0][0] == "ا" and (marks(nx[0]) & {FATHA, KASRA, DAMMA}) \
                       and RING not in nx[0][1] and HIGHDOT not in nx[0][1]:
                        hn = hafs_tok(key, s, a, wi + 1)
                        if hn and hn[0] in "أإ":
                            d0 = reading_diff(key, s, a, wi, cl)
                            if d0 is not None and not d0[0] and d0[1] == len(cl) - 1 \
                               and d0[2] == len(cl) - 1:
                                continue
                d = reading_diff(key, s, a, wi, cl)
                if d is not None and not d[0] and d[1] is not None:
                    if whole_word_edition:
                        add(rules, s, a, wi, letter, -1, -1)
                    else:
                        add(rules, s, a, wi, letter, d[1], d[2])
                    stats["diff-added"] += 1
    return stats

def idgham_from_pack(key, rules, letter):
    """Print-flagged idgham words (warsh: the قد ضّل / أخذتّم family, incl. ones
    Hafs shares) with letter-exact extents recomputed from the text."""
    v1 = V1W[key].get("idgham", {})
    n = 0
    flagged = set(v1)
    for (s, a, wi) in v1:
        toks = CLS[key][s].get(a)
        if toks is None or wi >= len(toks) or not toks[wi]:
            continue
        cl = toks[wi]
        lo = hi = None
        if SHADDA in cl[0][1]:
            lo = hi = 0
        else:
            for ci in range(len(cl) - 1):
                if bare(cl[ci]) and SHADDA in cl[ci + 1][1] and cl[ci][0] not in "اوىٱ":
                    lo, hi = ci, ci + 1
                    break
            if lo is None and bare(cl[-1]) and (s, a, wi + 1) in flagged:
                lo = hi = len(cl) - 1
        if lo is None:
            add(rules, s, a, wi, letter, -1, -1)
        else:
            add(rules, s, a, wi, letter, lo, hi)
        n += 1
    return n

# ---------------- per-riwayah build ----------------
LGD = {
    "khilaf_harf": ("الحرف المخالف لحفص", "Letter differing from Ḥafṣ"),
    "khilaf_word": ("الكلمة المخالفة لحفص", "Word differing from Ḥafṣ"),
    "idgham": ("الإدغام", "Idghām (merging)"),
    "imalah": ("الإمالة", "Imālah (full inclination)"),
    "taqlil": ("التقليل", "Taqlīl (slight inclination)"),
    "silah_meem": ("صلة ميم الجمع", "Ṣilat mīm al-jamʿ"),
    "ha_dhamir": ("هاء الضمير المخالفة لحفص", "Pronoun hāʾ differing from Ḥafṣ"),
    "madd_badal": ("مد البدل", "Madd al-badal"),
    "madd_leen": ("مد اللين", "Madd al-līn"),
    "raa_muraqqaqah": ("الراءات المرققة", "Light (muraqqaq) rāʾ"),
    "lam_mughallazah": ("اللامات المغلظة", "Heavy (mughallaẓ) lām"),
}

def legend_entry(c, k):
    ar, en = LGD[k]
    return {"c": c, "k": k, "ar": ar, "en": en}

REPORT = []

def build(key, name):
    rules = new_rules()
    rep = {"riwayah": key}
    if key == "warsh":
        legend = [legend_entry("m", "khilaf_harf"), legend_entry("b", "idgham"),
                  legend_entry("r", "taqlil"), legend_entry("c", "madd_badal"),
                  legend_entry("g", "raa_muraqqaqah"), legend_entry("l", "lam_mughallazah"),
                  legend_entry("o", "silah_meem"), legend_entry("y", "madd_leen")]
        rep["idgham_words"] = idgham_from_pack(key, rules, "b")
        rep["taqlil"] = extract_taqlil(key, rules, "r")
        rep["badal"] = extract_warsh_badal(rules, "c")
        rep["raa"] = extract_warsh_raa(rules, "g", V1W[key].get("raa_muraqqaqah", {}))
        rep["lam"] = extract_warsh_lam(rules, "l")
        rep["silah"] = extract_silah_meem(key, rules, "o")
        rep["leen"] = extract_warsh_leen(rules, "y")
        rep["khilaf"] = dict(merge_khilaf(key, rules, "m", "khilaf_harf", False))
    elif key == "qaloon":
        legend = [legend_entry("m", "khilaf_word"), legend_entry("r", "imalah")]
        rep["imalah"] = extract_imalah(key, rules, "r")
        rep["khilaf"] = dict(merge_khilaf(key, rules, "m", "khilaf_word", True))
    elif key == "duri":
        legend = [legend_entry("m", "khilaf_word"), legend_entry("b", "idgham"),
                  legend_entry("r", "imalah"), legend_entry("o", "taqlil")]
        rep["idgham_sites"] = extract_idgham(key, rules, "b")
        rep["imalah"] = extract_imalah(key, rules, "r")
        rep["taqlil"] = extract_taqlil(key, rules, "o")
        rep["khilaf"] = dict(merge_khilaf(key, rules, "m", "khilaf_word", True))
    elif key == "susi":
        # the susi print's own legend box reads "الحرف المخالف لحفص" (letter, not
        # word - PDF p1) even though v1 transcribed it as khilaf_word.
        legend = [legend_entry("m", "khilaf_harf"), legend_entry("b", "idgham"),
                  legend_entry("r", "imalah"), legend_entry("o", "taqlil")]
        rep["idgham_sites"] = extract_idgham(key, rules, "b")
        rep["imalah"] = extract_imalah(key, rules, "r")
        rep["taqlil"] = extract_taqlil(key, rules, "o")
        rep["khilaf"] = dict(merge_khilaf(key, rules, "m", "khilaf_word", False))
    elif key in ("bazzi", "qunbul"):
        legend = [legend_entry("m", "khilaf_harf"), legend_entry("b", "ha_dhamir"),
                  legend_entry("r", "silah_meem")]
        rep["ha"] = extract_ha_dhamir(key, rules, "b")
        rep["silah"] = extract_silah_meem(key, rules, "r")
        rep["khilaf"] = dict(merge_khilaf(key, rules, "m", "khilaf_harf", False))
    elif key == "shubah":
        legend = [legend_entry("m", "khilaf_harf"), legend_entry("b", "idgham"),
                  legend_entry("r", "imalah")]
        rep["idgham_sites"] = extract_idgham(key, rules, "b")
        rep["imalah"] = extract_imalah(key, rules, "r")
        rep["khilaf"] = dict(merge_khilaf(key, rules, "m", "khilaf_harf", False))

    # order entries per word: whole-word first, then letter extents
    out_rules = {}
    total_entries = 0
    for s in sorted(rules):
        so = {}
        for a in sorted(rules[s]):
            ao = {}
            for wi, entries in rules[s][a].items():
                entries.sort(key=lambda e: (0 if e[1] < 0 else 1, 0 if e[0] == 'm' else 1, e[1]))
                ao[str(wi)] = entries
                total_entries += len(entries)
            so[str(a)] = ao
        out_rules[str(s)] = so
    rep["total_entries"] = total_entries
    REPORT.append(rep)

    pack = {"v": 2, "legend": legend, "rules": out_rules,
            "pages": V1[key].get("pages", {}), "khilafMarkers": V1[key].get("khilafMarkers", {})}
    if WRITE:
        raw = json.dumps(pack, ensure_ascii=False, separators=(",", ":")).encode()
        co = zlib.compressobj(9, zlib.DEFLATED, -15)
        blob = co.compress(raw) + co.flush()
        with open(os.path.join(ROOT, "Resources", "Data", "Quran", f"{name}.json.deflate"), "wb") as f:
            f.write(blob)
        rep["bytes"] = len(blob)
    return pack

print("building alignments...")
for key in ["warsh", "susi", "bazzi", "qunbul", "shubah", "duri", "qaloon"]:
    ALIGNED[key] = build_alignment(key)
    print(f"  {key}: {len(ALIGNED[key])} tokens aligned")

for key, name in [("warsh", "TajweedWarsh"), ("qaloon", "TajweedQaloon"),
                  ("duri", "TajweedDuri"), ("susi", "TajweedSusi"),
                  ("bazzi", "TajweedBazzi"), ("qunbul", "TajweedQunbul"),
                  ("shubah", "TajweedShubah")]:
    build(key, name)

print(f"\n{'WRITTEN' if WRITE else 'DRY RUN'}")
for rep in REPORT:
    print(json.dumps(rep, ensure_ascii=False, indent=1))
