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
TANWIN = {FATHATAN, DAMMATAN, KASRATAN, TAN_OPEN_K, TAN_OPEN_D, TAN_OPEN_F}

def skel(tok, norm_hamza=False):
    s = "".join(ch for ch in tok if is_base(ord(ch))).replace("ٱ", "ا")
    if norm_hamza:
        for a, b in [("أ", "ا"), ("إ", "ا"), ("ؤ", "و"),
                     ("ئ", "ي"), ("ء", "")]:
            s = s.replace(a, b)
    return s

# The 12 beta riwayat: machine-extracted texts shipping as loose deflates.
# These MAY be corrected later - rerun this script afterwards; everything is
# re-derived from the current text, and print flags re-attach by word skeleton.
BETA_Q = {
    "hisham": "QiraahHisham", "ibndhakwan": "QiraahIbnDhakwan",
    "khalaf": "QiraahKhalaf", "khallad": "QiraahKhallad",
    "abuharith": "QiraahAbuHarith", "durikisai": "QiraahDuriKisai",
    "ibnwardan": "QiraahIbnWardan", "ibnjammaz": "QiraahIbnJammaz",
    "ruways": "QiraahRuways", "rawh": "QiraahRawh",
    "ishaq": "QiraahIshaq", "idris": "QiraahIdris",
}

def load_beta_text(qname):
    blob = open(os.path.join(ROOT, "Resources", "Data", "Quran", f"{qname}.json.deflate"), "rb").read()
    d = json.loads(zlib.decompress(blob, -15))
    return {s: {str(a["id"]): a["text"] for a in ayat} for s, ayat in d.items()}

BETA_T = {k: load_beta_text(q) for k, q in BETA_Q.items()}

def texts_of(key):
    if key == "hafs":
        return {str(s): {str(a): t for a, t in v.items()} for s, v in HAFS_T.items()}
    if key in BETA_T:
        return BETA_T[key]
    return qpk[key]

NONBETA = ["susi", "duri", "shubah", "warsh", "qaloon", "bazzi", "qunbul"]
ALL_RIWAYAT = NONBETA + list(BETA_Q)

TOKS = {}
CLS = {}
for key in ["hafs"] + ALL_RIWAYAT:
    t = defaultdict(dict)
    c = defaultdict(dict)
    for s, ayat in texts_of(key).items():
        for a, text in ayat.items():
            tk = tokens(text)
            t[int(s)][int(a)] = tk
            c[int(s)][int(a)] = [clusterize(x) for x in tk]
    TOKS[key] = t
    CLS[key] = c

# ---- khilaf ayah markers, derived rather than measured ----------------------------------
def derive_khilaf_markers(key):
    """Ayahs whose NUMBERING parts from Hafs: {surah: [ayah, ...]}.

    The prints ring such an ayah's medallion magenta and stage 2 read that ring off the page
    with an ink threshold (`magenta > 40`). Audited against the texts, that rule found only
    about a third of them: 20 of Qaloon's 59, 15 of ad-Duri's 57, and it rang 3 ayahs in
    Shubah, who shares Hafs's Kufi numbering exactly and has none at all.

    The fact itself does not need measuring. Align the surah's words against Hafs's, map every
    ayah boundary through the alignment, and an ayah whose end does not land on a Hafs boundary
    is a khilaf number - exact by construction, and it cannot miss one or invent one.
    """
    out = {}
    for s in sorted(TOKS[key]):
        if s not in TOKS["hafs"]:
            continue
        # Ornament-only tokens are dropped first. The rub-el-hizb `\u06de` stands as its own token
        # in these texts and the editions disagree wildly on how many they print (199 in Hafs,
        # 433 in ad-Duri), so leaving them in breaks the alignment at every extra one and
        # reports 45 ayahs per volume as renumbered when only their ornaments moved.
        def real(toks):
            return [t for t in toks if any(is_base(ord(ch)) for ch in t)]
        hafs_ayat = [real(TOKS["hafs"][s][a]) for a in sorted(TOKS["hafs"][s])]
        ours_ids = sorted(TOKS[key][s])
        ours = [real(TOKS[key][s][a]) for a in ours_ids]
        hb, n = set(), 0
        for toks in hafs_ayat:
            n += len(toks); hb.add(n)
        # A normalisation loose enough that the ALIGNMENT never breaks on a spelling
        # difference: hamza seats, alef maqsura against ya, and the silah waw/ya all fold
        # away. A word the alignment fails on looks like a boundary shift and would be
        # reported as a khilaf number that is not one.
        def nk(w):
            return skel(w, True).replace("ى", "ي").replace("ۥ", "").replace("ۦ", "").replace("ـ", "")
        a_words = [nk(w) for toks in hafs_ayat for w in toks]
        b_words = [nk(w) for toks in ours for w in toks]
        sm = SequenceMatcher(None, a_words, b_words, autojunk=False)
        b2a = {}
        for blk in sm.get_matching_blocks():
            for k in range(blk.size + 1):
                b2a[blk.b + k] = blk.a + k
        hits, n = [], 0
        for aid, toks in zip(ours_ids, ours):
            n += len(toks)
            mapped = b2a.get(n)
            if mapped is None or mapped not in hb:
                hits.append(aid)
        if hits:
            out[str(s)] = hits
    return out


def marks(c):
    return set(c[1])

def bare(c):
    return not (marks(c) & VOCAL)

def noon_sakinah(c):
    """A noon carrying no vowel: written bare (Maghribi) or with sukoon."""
    return c[0] == "ن" and marks(c) & VOCAL <= {SUKOON}

# Maghribi-orthography texts write the wasl dots and the shadda on ordinary
# noon/tanwin idgham into ي/و; for them that shadda is spelling, not khilaf.
# (Khalaf's ي/و shaddas are NOT in this set on purpose: his idgham there is
# بلا غنة - a real reading difference the print colors blue.)
# DECLARED, not inferred: this set drives extraction semantics (imalah ring
# interpretation), so a text-correction pass must never silently reclassify a
# riwayah. The dot-count assertion below fails the build instead - if it fires,
# either the correction really changed the text's orthography (update the set)
# or it broke the wasl dots (fix the text).
MAGHRIBI = {"warsh", "qaloon", "duri", "susi",
            "ibnwardan", "ibnjammaz", "ruways", "rawh"}

def _dot_count(key):
    n = 0
    for s, ayat in texts_of(key).items():
        for a, t in ayat.items():
            n += t.count(HIGHDOT)
    return n

for _k in ALL_RIWAYAT:
    assert (_k in MAGHRIBI) == (_dot_count(_k) > 5000), \
        f"orthography class changed for {_k}: dots={_dot_count(_k)}, declared MAGHRIBI={_k in MAGHRIBI}"

PACK_NAME = {
    "warsh": "TajweedWarsh", "qaloon": "TajweedQaloon", "duri": "TajweedDuri",
    "susi": "TajweedSusi", "bazzi": "TajweedBazzi", "qunbul": "TajweedQunbul",
    "shubah": "TajweedShubah",
    **{k: "Tajweed" + q[6:] for k, q in BETA_Q.items()},
}

# ---------------- v1 packs (extraction originals, pinned in the repo -
# the Resources copies are the v2 output of this very script) ----------------
def load_v1(name):
    blob = open(os.path.join(V1DIR, f"{name}.json.deflate"), "rb").read()
    return json.loads(zlib.decompress(blob, -15))

V1 = {k: load_v1(n) for k, n in PACK_NAME.items()}

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

# ---------------- print flags, pinned by WORD SKELETON not position ----------------
# The v1 packs address words by token index against the texts as they were when
# the flags snapshot was taken. Texts (especially the beta ones) may be corrected
# later; print-flags.json re-keys every flag as (surah, ayah, skeleton,
# nth-occurrence [, v1 ink extent]) so a rerun re-attaches flags to the right
# words - or drops them cleanly when a word's letters changed. The file is
# generated ONCE from the pinned v1 packs + the texts current at pin time and
# should be committed; delete it only to re-pin against the current texts.
FLAGS_PATH = os.path.join(ROOT, "Scripts", "tajweed-extraction", "print-flags.json")

def _skel_occ(key, s, a, wi):
    tks = TOKS[key][s].get(a)
    if tks is None or wi >= len(tks):
        return None
    sk = skel(tks[wi])
    occ = sum(1 for j in range(wi) if skel(tks[j]) == sk)
    return sk, occ

def pin_flags():
    out = {}
    for key in ALL_RIWAYAT:
        rw = {}
        for rule, words in v1_words(key).items():
            rows = []
            for (s, a, wi), v in sorted(words.items()):
                so = _skel_occ(key, s, a, wi)
                if so is None:
                    continue
                lo, hi = (v[1], v[2]) if isinstance(v, list) and len(v) == 3 else (-1, -1)
                rows.append([s, a, so[0], so[1], lo, hi])
            rw[rule] = rows
        out[key] = rw
    return out

if os.path.exists(FLAGS_PATH):
    PINNED = json.load(open(FLAGS_PATH))
else:
    PINNED = pin_flags()
    with open(FLAGS_PATH, "w") as f:
        json.dump(PINNED, f, ensure_ascii=False)
    print(f"pinned print flags -> {FLAGS_PATH}")

def flags_for(key, rule):
    """Pinned flags resolved against the CURRENT text: {(s,a,wi): (lo,hi)}.
    A flag whose word skeleton no longer exists at its occurrence is dropped."""
    out = {}
    dropped = 0
    for s, a, sk, occ, lo, hi in PINNED.get(key, {}).get(rule, []):
        tks = TOKS[key][s].get(a)
        if tks is None:
            dropped += 1
            continue
        n = -1
        hit = None
        for wi, t in enumerate(tks):
            if skel(t) == sk:
                n += 1
                if n == occ:
                    hit = wi
                    break
        if hit is None:
            dropped += 1
            continue
        out[(s, a, hit)] = (lo, hi)
    return out, dropped

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
                    # Ordinary noon-sakinah/tanwin idgham written with shadda is a
                    # spelling convention shared with Hafs - never a khilaf - so it
                    # is skipped for EVERY riwayah, not only where H_CROSS happens to
                    # match (a khilaf letter in either word changes the skeleton-pair
                    # key, and gating this skip on the orthography class let those
                    # sites leak through as false blue idgham that then suppressed
                    # merge_khilaf's magenta - the Shubah 6:139 تَكُن regression).
                    # The ONE real exception: Khalaf and Khallad merge noon into ي/و
                    # WITHOUT ghunnah (بلا غنة) - a reading difference their prints
                    # color blue, and their Mashriqi texts write that shadda only
                    # where it is real (Hafs's naqis ي/و idgham carries no shadda,
                    # so H_CROSS never hides these).
                    plast = pcl[-1]
                    bila_ghunnah = key in ("khalaf", "khallad") and cl[0][0] in "يو"
                    if not bila_ghunnah and cl[0][0] in YARMALOON \
                       and (noon_sakinah(plast) or marks(plast) & TANWIN):
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
    return bool(marks(plast) & TANWIN) or noon_sakinah(plast)

def _runs(indexes):
    """[3, 4, 7] -> [(3, 4), (7, 7)]."""
    out = []
    for i in sorted(indexes):
        if out and i == out[-1][1] + 1:
            out[-1][1] = i
        else:
            out.append([i, i])
    return [tuple(x) for x in out]


def reading_diff(key, s, a, wi, cl):
    """None when no aligned Hafs token; else (identical, lo, hi, runs).

    lo/hi is the differing cluster extent in ORIGINAL cluster indexes (None, None when
    identical or when there is no local letter to paint). `runs` is the same information
    split into CONTIGUOUS stretches: a word differing at letters 1 and 5 has runs
    [(1,1),(5,5)] where lo/hi alone says 1..5, and the span washed the three letters
    between them that the print leaves black. Callers that can emit several extents per
    word use `runs`; `lo`/`hi` stay for the ones that cannot."""
    ht = hafs_tok(key, s, a, wi)
    if ht is None:
        return None
    hcl = clusterize(ht)
    r = norm_clusters(cl)
    h = norm_clusters(hcl)
    if article_naql_equal(r, h):
        return (True, None, None, [])
    if [x[0] for x in r] == [x[0] for x in h]:
        diff = markdiff_extent(r, h)
        if not diff:
            return (True, None, None, [])
        if idgham_orthography_equal(key, s, a, wi, r, h):
            return (True, None, None, [])
        return (False, min(diff), max(diff), _runs(diff))
    # unequal skeletons: canonicalize dagger alefs and retry
    re_, rmap = expand_daggers(r)
    he, _ = expand_daggers(h)
    rb = [x[0] for x in re_]
    hb = [x[0] for x in he]
    if rb == hb:
        diff = markdiff_extent(re_, he)
        if not diff:
            return (True, None, None, [])
        return (False, rmap[min(diff)], rmap[max(diff)], _runs([rmap[i] for i in diff]))
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
        return (False, None, None, [])  # pure deletion vs hafs: no local letter to paint
    olo, ohi = rmap[lo], rmap[min(hi_r, len(rb) - 1)]
    if olo > 0 and all(cl[j][0] in "ويا" and not (set(cl[j][1]) & VOCAL) for j in range(olo, ohi + 1)):
        olo -= 1  # converted bare madd sounds through its predecessor's vowel
    return (False, olo, ohi, [(olo, ohi)])

def identical_to_hafs(key, s, a, wi, cl):
    d = reading_diff(key, s, a, wi, cl)
    return d is not None and d[0]

def substitution_shaped(key, s, a, wi, cl):
    """For the machine-extracted beta texts, an unflagged diff earns a khilaf
    color only when it looks like a READING substitution: same letter skeleton,
    and every differing cluster swaps marks rather than merely lacking them.
    (A missing haraka/shadda is an extraction gap, not a khilaf; the one
    legitimate omission is the hamza mark - the ibdal readings.) Words that
    lost or gained letters are extraction dropouts; their real khilaf coverage
    comes from the print flags."""
    ht = hafs_tok(key, s, a, wi)
    if ht is None:
        return False
    r = norm_clusters(cl)
    h = norm_clusters(clusterize(ht))
    if [x[0] for x in r] != [x[0] for x in h]:
        return False
    for ci in markdiff_extent(r, h):
        rm, hm = r[ci][1], h[ci][1]
        omitted = hm - rm
        extra = rm - hm
        # purely-omitted marks (no replacement) = extraction gap, except the
        # hamza mark whose absence IS the ibdal reading. Extra marks are fine:
        # noise drops marks, readings add them (يُكَذِّبُونَ's shadda).
        if not extra and omitted - {HAMZA_ABOVE}:
            return False
    return True

def merge_khilaf(key, rules, letter, v1_key, whole_word_edition, strict_additions=False):
    v1, dropped = flags_for(key, v1_key)
    stats = Counter()
    if dropped:
        stats["flag-unmatched"] = dropped
    for (s, a, wi), (vlo, vhi) in v1.items():
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
        if vlo >= 0:
            lo, hi = vlo, min(vhi, len(cl))
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
            # One entry per CONTIGUOUS run, not one span from the first difference to
            # the last: the span washed 1,771 letters across 1,150 words that the print
            # leaves black, which is the bleeding into neighbouring letters.
            for lo_, hi_ in (d[3] or [(d[1], d[2])]):
                add(rules, s, a, wi, letter, lo_, hi_)
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
                if strict_additions and not substitution_shaped(key, s, a, wi, cl):
                    continue
                d = reading_diff(key, s, a, wi, cl)
                if d is not None and not d[0] and d[1] is not None:
                    if whole_word_edition:
                        add(rules, s, a, wi, letter, -1, -1)
                    else:
                        for lo_, hi_ in (d[3] or [(d[1], d[2])]):
                            add(rules, s, a, wi, letter, lo_, hi_)
                    stats["diff-added"] += 1
    return stats

def idgham_from_pack(key, rules, letter, skip_existing=False):
    """Print-flagged idgham words (the قد ضّل / أخذتّم families, incl. ones
    Hafs shares) with letter-exact extents recomputed from the text. With
    skip_existing, words the text-pattern extractor already colored are left
    alone (used when a riwayah runs both sources)."""
    v1, _ = flags_for(key, "idgham")
    n = 0
    flagged = set(v1)
    for (s, a, wi) in v1:
        toks = CLS[key][s].get(a)
        if toks is None or wi >= len(toks) or not toks[wi]:
            continue
        if skip_existing and any(e[0] == letter for e in rules[s][a].get(wi, [])):
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

# ---------------- beta-specific extractors (all locked to the text) ----------------
def extract_imalah_with_flags(key, rules, letter, use_rings):
    """Imalah for the beta editions: exact letters from the text's own 065C
    (and hollow rings on non-wasl letters for the Mashriqi Hamzah pair), PLUS
    the print's imalah word flags for words the text leaves unmarked (Yaqub,
    most of Khallad, half of Kisai...) - extent falls back to the final
    inclined-vowel cluster, the same resolution the print's reader performs."""
    n = 0
    done = set()
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                for ci, c in enumerate(cl):
                    hit = IMALAH in c[1] or (use_rings and RING in c[1] and not (ci == 0 and c[0] == "ا"))
                    if hit:
                        lo, hi = inclined_extent(cl, ci)
                        add(rules, s, a, wi, letter, lo, hi)
                        done.add((s, a, wi))
                        n += 1
    flags, _ = flags_for(key, "imalah")
    for (s, a, wi) in flags:
        if (s, a, wi) in done:
            continue
        toks = CLS[key][s].get(a)
        if toks is None or wi >= len(toks) or not toks[wi]:
            continue
        cl = toks[wi]
        idx = None
        for ci in range(len(cl) - 1, -1, -1):
            if cl[ci][0] in "اىٱ" and bare(cl[ci]):
                idx = ci
                break
            if DAGGER in cl[ci][1]:
                idx = ci
                break
        if idx is None:
            continue  # no inclined vowel to lean = the flag is extraction noise
        add(rules, s, a, wi, letter, max(0, idx - 1), idx)
        n += 1
    return n

def extract_sakt(key, rules, letter, scope):
    """Khalaf pauses on ANY sakin before hamza (joined and separated); Khallad
    only on the article lam and on شيء. Both are fully text-derivable, so a
    future text fix just needs a rerun."""
    n = 0
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                if not cl:
                    continue
                for ci in range(len(cl) - 1):
                    if SUKOON not in cl[ci][1] or not is_hamza_cluster(cl[ci + 1]):
                        continue
                    if scope == "khallad":
                        is_article = cl[ci][0] == "ل" and ci >= 1 and cl[ci - 1][0] in "اٱ"
                        is_shay = cl[ci][0] == "ي" and ci >= 1 and cl[ci - 1][0] == "ش"
                        if not (is_article or is_shay):
                            continue
                    add(rules, s, a, wi, letter, ci, ci + 1)
                    n += 1
                if scope == "khalaf":
                    last = cl[-1]
                    if SUKOON in last[1] and wi + 1 < len(toks) and toks[wi + 1] \
                       and is_hamza_cluster(toks[wi + 1][0]):
                        add(rules, s, a, wi, letter, len(cl) - 1, len(cl) - 1)
                        add(rules, s, a, wi + 1, letter, 0, 0)
                        n += 1
    return n

def extract_ishmam_flags(key, rules, letter):
    """Print-flagged ishmam words (صراط blended toward zay); the ص is the rule's
    letter by definition."""
    flags, _ = flags_for(key, "ishmam_sad")
    n = 0
    for (s, a, wi) in flags:
        toks = CLS[key][s].get(a)
        if toks is None or wi >= len(toks) or not toks[wi]:
            continue
        cl = toks[wi]
        sads = [ci for ci, c in enumerate(cl) if c[0] == "ص"]
        if sads:
            for ci in sads:
                add(rules, s, a, wi, letter, ci, ci)
        else:
            add(rules, s, a, wi, letter, -1, -1)
        n += 1
    return n

def extract_ghunnah_kha_ghayn(key, rules, letter):
    """Abu Jafar keeps the ghunnah before خ and غ - deterministic: every noon
    sakinah / tanwin met by خ/غ, in-word or across words."""
    n = 0
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            for wi, cl in enumerate(toks):
                for ci, c in enumerate(cl):
                    nxt = None
                    if ci + 1 < len(cl):
                        nxt = cl[ci + 1][0]
                    elif wi + 1 < len(toks) and toks[wi + 1]:
                        nxt = toks[wi + 1][0][0]
                    if nxt not in ("خ", "غ"):
                        continue
                    if noon_sakinah(c) or marks(c) & TANWIN:
                        add(rules, s, a, wi, letter, ci, ci)
                        n += 1
    return n

def extract_silah_pronoun(key, rules, letter):
    """Abu Jafar's plural-mim silah. His texts do NOT write the small waw the
    Ibn Kathir texts use, so the rule is structural: a final sukooned م whose
    seat is the pronoun (preceded by ه / ت / suffix ك), joined to a following
    word (silah never applies at the ayah's end, and iltiqa positions carry a
    vowel instead of sukoon)."""
    n = 0
    for s, ayat in CLS[key].items():
        for a, toks in ayat.items():
            last_wi = len(toks) - 1
            for wi, cl in enumerate(toks):
                if wi == last_wi or len(cl) < 2:
                    continue
                lastc = cl[-1]
                # silah'd mim is sakin: written bare (Maghribi) or with sukoon;
                # a voweled mim is the iltiqa/i'rab form and takes no silah.
                if lastc[0] != "م" or (marks(lastc) & VOCAL) - {SUKOON}:
                    continue
                p = cl[-2]
                if p[0] not in "هكت":
                    continue
                # The question word كَمۡ always writes its fathah (كَمۡ، وَكَمۡ، فَكَم -
                # the old 2-cluster test missed the prefixed forms), while the
                # pronoun كُم carries a dammah or is written bare (وَلَكم) - never
                # a fathah.
                if p[0] == "ك" and FATHA in p[1]:
                    continue
                # A SAKIN حۡ directly before كُم makes the م a root radical - the
                # jussive/imperative of حكم (يَحۡكُم، فَٱحۡكُم، وَلۡيَحۡكُمۡ). A genuine
                # pronoun host ending in ح carries its case vowel (رِيحُكُمۡ).
                if p[0] == "ك" and len(cl) >= 3 and cl[-3][0] == "ح" and SUKOON in cl[-3][1]:
                    continue
                add(rules, s, a, wi, letter, len(cl) - 1, len(cl) - 1)
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
    "sakt": ("السكت", "Sakt (breathless pause)"),
    "ishmam_sad": ("إشمام الصاد صوت الزاي", "Ṣād blended toward zāy"),
    "ghunnah_kha_ghayn": ("الغنة مع الخاء والغين", "Ghunnah kept before khāʾ/ghayn"),
    "tashdid_ta": ("تشديد التاء", "Doubled tāʾ joined to the word before"),
    "ibtida_wasl": ("الابتداء بهمزة الوصل", "Beginning on the waṣl hamzah"),
}

def legend_entry(c, k):
    ar, en = LGD[k]
    return {"c": c, "k": k, "ar": ar, "en": en}

# ================= the print's own colour layer =========================================
# Every one of the nineteen volumes draws its tajweed colouring as ordinary coloured text
# in the PDF content stream - one RGB fill per glyph, no raster anywhere. So the rules are
# not inferred here at all: `pipeline/colorlayer.py` carries each glyph's fill through the
# deterministic renderer and writes the coloured ayah, and `pipeline/legend.py` reads each
# volume's own printed key. This function only moves those runs onto the shipped text.
#
# What it replaces: an ink threshold over rasterised pages (which supplied an extent for
# just 34% of flagged words), a Hafs-diff fallback for the other 71%, and a whole-word
# fallback for the rest. Hafs has no colour layer and is not built here.
PIPE = os.path.join(ROOT, "Resources", "JSONs-Deprecated", "Qiraat",
                    "_staging-riwayat", "pipeline", "data")

# The builder's key for ad-Duri Abu Amr; every other key is the pipeline slug already.
PIPE_SLUG = {"duri": "duriabiamr"}

# The print's key colour -> the pack's colour letter. QiraahTajweed.swift renders these as
# the same eight colours the volumes print, so the letter IS the print's colour.
PACK_LETTER = {0xff00ff: "m", 0x0000ff: "b", 0xff0000: "r", 0x00ccff: "c",
               0xff6600: "o", 0x00ff00: "g", 0x3366ff: "l", 0x99cc00: "y",
               # a SECOND green, in the two Abu Ja'far volumes only: bright green is
               # their sakt on the fawatih, this deeper one is the wasl-hamzah dot. The
               # print separates them by shade, so the app does too.
               0x00b050: "e"}

# legend.py's rule slug -> this script's legend key
PACK_RULE = {"khilaf-letter": "khilaf_harf", "khilaf-word": "khilaf_word",
             "khilaf-ha": "ha_dhamir", "idgham": "idgham", "imalah": "imalah",
             "taqlil": "taqlil", "badal": "madd_badal", "raa": "raa_muraqqaqah",
             "lam": "lam_mughallazah", "silah": "silah_meem", "leen": "madd_leen",
             "sakt": "sakt", "ishmam": "ishmam_sad", "ghunnah": "ghunnah_kha_ghayn",
             "tashdid-ta": "tashdid_ta", "ibtida-wasl": "ibtida_wasl"}

RULE_ORDER = ["khilaf-letter", "khilaf-word", "khilaf-ha", "idgham", "imalah", "taqlil",
              "sakt", "tashdid-ta", "ibtida-wasl", "badal", "raa", "lam", "leen",
              "silah", "ishmam", "ghunnah"]

_LEGEND_JSON = json.load(open(os.path.join(PIPE, "legend.json"), encoding="utf-8"))

# For ALIGNMENT ONLY, and every fold is a rewrite the emit chain itself performs.
_FOLD = {"ٱ": "ا", "أ": "ا", "إ": "ا", "آ": "ا",
         "ى": "ي", "ئ": "ي", "ؤ": "و", "ـ": ""}
_OFFSPINE = "﷐✗"


def _units(text):
    """Letter units: one base letter with the marks riding on it -> [(folded, lo, hi)]."""
    out = []
    for i, ch in enumerate(text):
        if ch == " ":
            out.append((" ", i, i))
        elif is_base(ord(ch)) and ch not in _OFFSPINE:
            out.append((_FOLD.get(ch, ch), i, i))
        elif out and out[-1][0] != " ":
            out[-1] = (out[-1][0], out[-1][1], i)
    return out


def _nearest_key(col, keys):
    def dist(a, b):
        return sum((((a >> sh) & 255) - ((b >> sh) & 255)) ** 2 for sh in (16, 8, 0))
    best = min(keys, key=lambda k: dist(col, k))
    # 45 per channel: the key and the ink round differently (#99cc00 keyed against
    # #9acc00 inked; Khallad's 1,578 sakt marks are #33cccc against a #00ccff key), and
    # 45 still leaves the closest DIFFERENT pair in any volume (#ff6600 / #ff0000) apart.
    return best if dist(col, best) <= 3 * 45 * 45 else None


def _wskel(w):
    """A word's letter spine, for matching one text's words against another's."""
    k = "".join(_FOLD.get(c, c) for c in w if is_base(ord(c)) and c not in _OFFSPINE)
    return k or w          # ۞ and other markless tokens match each other, not letters


def _pairs(rw, sw):
    """Pair the render's words to the shipped text's, per surah.

    Pairing by ayah id does NOT work: the volume's own numbering and the shipped text's
    disagree by design (Susi renders 6,204 ayahs against a 6,217-ayah text), and pairing
    by id put 26% of Susi's colour on the wrong ayah entirely. Aligning the surah's WORD
    stream instead makes the numbering irrelevant. Words the alignment marks as replaced
    are exactly the khilaf words - the ones that matter most - so they are paired
    positionally inside the replaced block rather than dropped.
    """
    sm = SequenceMatcher(None, [_wskel(w[0]) for w in rw], [_wskel(w[0]) for w in sw],
                         autojunk=False)
    out = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag in ("equal", "replace"):
            n = min(i2 - i1, j2 - j1)
            out += [(i1 + k, j1 + k) for k in range(n)]
    return out


def print_rules(key, rules):
    """Paint every rule this volume's print inks, at the letter the print inks it.

    The colour runs are in the RENDERED text's coordinates; the pack must be in the
    SHIPPED text's. The two differ (for the seven non-beta riwayat the shipped text is not
    this pipeline's output at all), so the transfer runs on the LETTER SPINE: the emit
    chain reorders marks freely but never touches the letters, and a letter that does not
    align is counted rather than painted.
    """
    slug = PIPE_SLUG.get(key, key)
    cl = json.load(open(os.path.join(PIPE, f"{slug}.colorlayer.json"), encoding="utf-8"))
    spec = _LEGEND_JSON[slug]
    keys = {int(c[1:], 16): v["rule"] for c, v in spec["keys"].items()}
    word_unit = spec["unit"] == "word"
    st = Counter()
    for s in sorted(TOKS[key]):
        rt_s = cl["text"].get(str(s))
        if not rt_s:
            st["no-rendered-surah"] += 1
            continue
        runs_s = cl["runs"].get(str(s), {})
        rw = []                                  # (word, [colour per char])
        for a_ in sorted(rt_s, key=int):
            text = rt_s[a_]
            col = [0] * len(text)
            for lo, hi, c in runs_s.get(a_, []):
                for x in range(lo, min(hi + 1, len(text))):
                    col[x] = c
            pos = 0
            for w in text.split(" "):
                if w:
                    rw.append((w, col[pos:pos + len(w)]))
                pos += len(w) + 1
        sw = []                                  # (word, ayah, word index)
        for a in sorted(TOKS[key][s]):
            for wi, tok in enumerate(TOKS[key][s][a]):
                sw.append((tok, a, wi))
        # count LETTERS, like `letters-placed`, so the two are the same unit
        for _w, c in rw:
            st["letters-inked"] += sum(1 for _b, lo, hi in _units(_w)
                                       if any(c[lo:hi + 1]))
        for ri, si in _pairs(rw, sw):
            rword, rcol = rw[ri]
            if not any(rcol):
                continue
            tok, a, wi = sw[si]
            pu, su = _units(rword), _units(tok)
            pcol = [next((c for c in rcol[lo:hi + 1] if c), 0) for _b, lo, hi in pu]
            # cluster index of each shipped unit (marks ride on their letter)
            sci, ci = [], -1
            for _b, lo, _hi in su:
                if is_base(ord(tok[lo])):
                    ci += 1
                sci.append(max(ci, 0))
            hits = defaultdict(set)
            m = SequenceMatcher(None, [u[0] for u in pu], [u[0] for u in su],
                                autojunk=False)
            for i, j, n in m.get_matching_blocks():
                for k in range(n):
                    c = pcol[i + k]
                    if not c:
                        continue
                    st["letters-placed"] += 1
                    kc = _nearest_key(c, keys)
                    if kc is None:
                        st["unlisted-colour"] += 1
                        continue
                    hits[(PACK_LETTER[kc], keys[kc])].add(sci[j + k])
            for (letter, rule), cis in sorted(hits.items()):
                if word_unit and rule == "khilaf-word":
                    add(rules, s, a, wi, letter, -1, -1)
                    st["whole-word"] += 1
                    continue
                # one entry per CONTIGUOUS run of letters, never one span from the first
                # inked letter to the last: that is what bled into the letters between.
                run = []
                for x in sorted(cis):
                    if run and x == run[-1][1] + 1:
                        run[-1][1] = x
                    else:
                        run.append([x, x])
                for lo, hi in run:
                    add(rules, s, a, wi, letter, lo, hi)
                    st["letter-extent"] += 1
    return st


def print_legend(key):
    spec = _LEGEND_JSON[PIPE_SLUG.get(key, key)]
    seen = {v["rule"]: int(c[1:], 16) for c, v in spec["keys"].items()}
    return [legend_entry(PACK_LETTER[seen[r]], PACK_RULE[r])
            for r in RULE_ORDER if r in seen]


REPORT = []

def build(key, name):
    rules = new_rules()
    rep = {"riwayah": key}
    # Every riwayah is built the same way now: whatever its own print inks, where it
    # inks it. The per-riwayah extractor lists that used to sit here (text patterns for
    # idgham/imalah/taqlil/badal/raa/lam/leen/silah/sakt/ishmam plus `merge_khilaf`) were
    # each a reconstruction of a rule the page already states in colour.
    legend = print_legend(key)
    rep["print"] = dict(print_rules(key, rules))

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
            "pages": V1[key].get("pages", {}), "khilafMarkers": derive_khilaf_markers(key)}
    if WRITE:
        raw = json.dumps(pack, ensure_ascii=False, separators=(",", ":")).encode()
        co = zlib.compressobj(9, zlib.DEFLATED, -15)
        blob = co.compress(raw) + co.flush()
        with open(os.path.join(ROOT, "Resources", "Data", "Quran", f"{name}.json.deflate"), "wb") as f:
            f.write(blob)
        rep["bytes"] = len(blob)
    return pack

print(f"maghribi-orthography texts: {sorted(MAGHRIBI)}")
print("building alignments...")
for key in ALL_RIWAYAT:
    ALIGNED[key] = build_alignment(key)
    print(f"  {key}: {len(ALIGNED[key])} tokens aligned")

for key in ALL_RIWAYAT:
    build(key, PACK_NAME[key])

print(f"\n{'WRITTEN' if WRITE else 'DRY RUN'}")
for rep in REPORT:
    print(json.dumps(rep, ensure_ascii=False, indent=1))
