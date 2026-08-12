#!/usr/bin/env python3
"""Repair missing word spaces in the beta riwayah texts.

The islamweb extractions glued runs of words together in hundreds of ayahs of
six texts (hisham, ibndhakwan, ibnjammaz, ibnwardan, rawh, ruways): the letters
and marks are all present, only the U+0020 separators were lost. This script
puts them back:

  * Per surah, align TOKEN SKELETONS against Hafs (the same alignment the pack
    builder uses - fast). Equal blocks are healthy; a mismatched block whose
    concatenated skeletons are letter-identical to Hafs's is a pure division
    defect and gets Hafs's word boundaries re-inserted; a mismatched block with
    khilaf letters inside is char-aligned locally (short strings) and only
    boundaries inside EQUAL sub-runs are inserted.
  * A boundary is skipped when any CLEAN beta text (abuharith, durikisai,
    ishaq, idris - same print family, undamaged) writes the words joined at
    the aligned spot: genuine rasm joins (identical-letter maqtu/mawsul sites)
    stay joined.
  * Only spaces are inserted, never anything removed: per-ayah, the text with
    spaces stripped must be byte-identical before and after (asserted).
  * Pinned print flags (print-flags.json) that addressed a glued word are
    re-keyed onto the sub-word their base-letter extent lands in, so the pack
    rebuild re-attaches them instead of dropping them.

Run:  python3 Scripts/fix_beta_spaces.py --write
then: python3 Scripts/build_tajweed_v2.py --write && python3 Scripts/build_solidpacks.py
"""
import json, zlib, os, sys
from difflib import SequenceMatcher
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WRITE = "--write" in sys.argv

DAMAGED = ["hisham", "ibndhakwan", "ibnjammaz", "ibnwardan", "rawh", "ruways"]
CLEAN_REFS = ["abuharith", "durikisai", "ishaq", "idris"]
QNAME = {
    "hisham": "QiraahHisham", "ibndhakwan": "QiraahIbnDhakwan",
    "ibnjammaz": "QiraahIbnJammaz", "ibnwardan": "QiraahIbnWardan",
    "rawh": "QiraahRawh", "ruways": "QiraahRuways",
    "abuharith": "QiraahAbuHarith", "durikisai": "QiraahDuriKisai",
    "ishaq": "QiraahIshaq", "idris": "QiraahIdris",
}
FLAGS_PATH = os.path.join(ROOT, "Scripts", "tajweed-extraction", "print-flags.json")

def is_base(cp):
    return 0x0621 <= cp <= 0x064A or cp in (0x0671, 0x0649, 0x066E, 0x06CC, 0x067E)

# Light fold for ALIGNMENT ONLY (never written back): hamza seats and alef
# variants differ per orthography without being different words.
FOLD = str.maketrans({"ٱ": "ا", "أ": "ا", "إ": "ا", "آ": "ا", "ؤ": "و", "ئ": "ي", "ى": "ي"})

def skel(tok):
    return "".join(ch for ch in tok if is_base(ord(ch))).translate(FOLD)

def raw_skel(tok):
    """Unfolded skeleton, matching build_tajweed_v2's - for print-flag keys."""
    return "".join(ch for ch in tok if is_base(ord(ch))).replace("ٱ", "ا")

def load_deflate(qname):
    blob = open(os.path.join(ROOT, "Resources", "Data", "Quran", f"{qname}.json.deflate"), "rb").read()
    return json.loads(zlib.decompress(blob, -15))

def write_deflate(qname, obj):
    raw = json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode()
    co = zlib.compressobj(9, zlib.DEFLATED, -15)
    with open(os.path.join(ROOT, "Resources", "Data", "Quran", f"{qname}.json.deflate"), "wb") as f:
        f.write(co.compress(raw) + co.flush())

quran = json.load(open(os.path.join(ROOT, "Resources", "JSONs-Deprecated", "Quran.json")))
HAFS = {str(s["id"]): [(a["id"], a["textArabic"]) for a in s["ayahs"]] for s in quran}

def surah_tokens(ayat):
    """Flat token list of a surah with per-token (ayah_index, char_start)."""
    toks, where = [], []
    for ai, (aid, text) in enumerate(ayat):
        pos = 0
        for t in text.replace(" ", " ").split(" "):
            if t:
                start = text.index(t, pos)
                toks.append(t)
                where.append((ai, start))
                pos = start + len(t)
    return toks, where

# ---- clean-family denial sets -------------------------------------------------
# denied[s] = set of Hafs global token indexes t such that some clean text joins
# H[t] onto its previous word (so a missing boundary there is rasm, not damage).
denied = defaultdict(set)
for ref in CLEAN_REFS:
    rdata = load_deflate(QNAME[ref])
    for s, hafs_ayat in HAFS.items():
        if s not in rdata:
            continue
        Ht, _ = surah_tokens(hafs_ayat)
        Rt, _ = surah_tokens([(a["id"], a["text"]) for a in rdata[s]])
        Hs = [skel(t) for t in Ht]
        Rs = [skel(t) for t in Rt]
        sm = SequenceMatcher(None, Hs, Rs, autojunk=False)
        for tag, i1, i2, j1, j2 in sm.get_opcodes():
            if tag == "equal":
                continue
            # a join/split shows as a block whose concatenated letters agree
            if "".join(Hs[i1:i2]) == "".join(Rs[j1:j2]) and (i2 - i1) != (j2 - j1):
                for i in range(i1 + 1, i2):
                    denied[s].add(i)

# ---- repair -------------------------------------------------------------------
flags = json.load(open(FLAGS_PATH))
flag_stats = defaultdict(int)
REPORT = []

# Hand-verified letter repairs (the ONLY letter edits this tool makes): three
# ibnwardan sites where the print's madda-alef came out as alef+lam+sukoon
# mid-word (إِنَّالۡأَوۡحَيۡنَ - impossible Arabic; Hafs shows إِنَّآ أَوۡحَيۡنَآ). Applied
# BEFORE any alignment so the space passes see the corrected letters. Tokens
# are selected by base-letter skeleton - never by pattern over the whole ayah,
# which would also hit legitimate articles (وَالۡأَسۡبَاطِ sits in the same ayah).
# The family writes madda-alef DECOMPOSED (alef + U+0653), matched here.
import re as _re
MADDA_IN_TOKEN = _re.compile(r'َالۡ(?=[أإ])')
MADDA_FIX = {   # riwayah -> (surah, ayah) -> glued-token skeletons to mend
    "ibnwardan": {
        ("4", 162): {"إنالأوحينالإليككمالأوحينالإلىنوحوالنبينمن"},
        ("5", 11): {"بـايتنالأولئك"},
    },
}

for key in DAMAGED:
    data = load_deflate(QNAME[key])
    inserts = defaultdict(list)          # (surah, ayah_index) -> char positions
    total_spaces = 0
    fixed_ayahs = set()

    for (s, aid), skels in MADDA_FIX.get(key, {}).items():
        for a in data.get(s, []):
            if a["id"] != aid:
                continue
            toks = a["text"].replace(" ", " ").split(" ")
            out = []
            for t in toks:
                if raw_skel(t) in skels:
                    t2, n = MADDA_IN_TOKEN.subn("َآ ", t)
                    if n:
                        flag_stats[f"{key}:madda-letter-repair"] += n
                        fixed_ayahs.add((s, aid))
                        t = t2
                out.append(t)
            a["text"] = " ".join(out)

    for s, hafs_ayat in HAFS.items():
        if s not in data:
            continue
        beta_ayat = [(a["id"], a["text"]) for a in data[s]]
        Ht, _ = surah_tokens(hafs_ayat)
        Bt, Bw = surah_tokens(beta_ayat)
        Hs = [skel(t) for t in Ht]
        Bs = [skel(t) for t in Bt]
        sm = SequenceMatcher(None, Hs, Bs, autojunk=False)

        def base_starts(tok):
            """char offsets of each base letter within tok."""
            return [ci for ci, ch in enumerate(tok) if is_base(ord(ch))]

        for tag, i1, i2, j1, j2 in sm.get_opcodes():
            if tag == "equal" or j2 <= j1 or i2 <= i1:
                continue
            joinedH = "".join(Hs[i1:i2])
            joinedB = "".join(Bs[j1:j2])
            # Case A: letters identical, division differs - a glue defect
            # (unless every interior boundary is rasm-denied).
            if joinedH == joinedB:
                if (j2 - j1) >= (i2 - i1):
                    continue          # beta splits MORE than hafs: not our defect
                # walk beta tokens, inserting hafs boundaries by base count
                hlens = [len(Hs[i]) for i in range(i1, i2)]
                bidx = j1
                consumed = 0          # bases consumed inside current beta token
                starts = base_starts(Bt[bidx])
                hbase = 0
                for hi, hl in enumerate(hlens[:-1]):
                    hbase += hl
                    # advance to the beta token containing base index hbase
                    while hbase - consumed > len(starts) - 1 and bidx < j2 - 1 \
                            and hbase - consumed >= len(starts):
                        consumed += len(starts)
                        bidx += 1
                        starts = base_starts(Bt[bidx])
                    local = hbase - consumed
                    if local <= 0 or local >= len(starts):
                        continue      # boundary coincides with an existing one
                    if (i1 + hi + 1) in denied[s]:
                        continue
                    ai, tstart = Bw[bidx]
                    ci = tstart + starts[local]
                    inserts[(s, ai)].append(ci)
                    total_spaces += 1
                    fixed_ayahs.add((s, beta_ayat[ai][0]))
                continue
            # Case B: khilaf letters inside - char-align the short local strings.
            cm = SequenceMatcher(None, joinedH, joinedB, autojunk=False)
            # base-offset -> (hafs token ordinal, is_word_start)
            hstartset = set()
            acc = 0
            for i in range(i1, i2):
                if i > i1:
                    hstartset.add((acc, i))
                acc += len(Hs[i])
            # beta base-offset -> (beta token index, local base ordinal)
            bmap = []
            for j in range(j1, j2):
                for k in range(len(Bs[j])):
                    bmap.append((j, k))
            for t2, a1, a2, b1, b2 in cm.get_opcodes():
                if t2 != "equal":
                    continue
                for off in range(a2 - a1):
                    ha = a1 + off
                    bb = b1 + off
                    match = next(((o, i) for (o, i) in hstartset if o == ha), None)
                    if match is None or off == 0:
                        continue
                    if match[1] in denied[s]:
                        continue
                    bj, bk = bmap[bb]
                    if bk == 0:
                        continue      # already a word start
                    ai, tstart = Bw[bj]
                    ci = tstart + base_starts(Bt[bj])[bk]
                    inserts[(s, ai)].append(ci)
                    total_spaces += 1
                    fixed_ayahs.add((s, beta_ayat[ai][0]))

    # ---- pass 2: monster tokens the token-level alignment missed ----
    # A long glued token in an ayah with REPEATED phrases can steal its twin's
    # alignment (an-Nisa 7: the loose "نصيب مما ترك..." matched Hafs's first
    # occurrence, squeezing the glued copy into a 1:1 replace). Align any token
    # still holding 13+ base letters directly against its surah's Hafs
    # base-letter stream and project boundaries from equal runs.
    for s, hafs_ayat in HAFS.items():
        if s not in data:
            continue
        Lh = []
        starts_h = set()
        for aid, text in hafs_ayat:
            for t in text.replace(" ", " ").split(" "):
                if not t:
                    continue
                starts_h.add(len(Lh))
                Lh.extend(skel(t))
        joinedHs = "".join(Lh)
        for ai, a in enumerate(data[s]):
            text = a["text"]
            pos = 0
            for tok in text.replace(" ", " ").split(" "):
                if not tok:
                    continue
                tstart = text.index(tok, pos)
                pos = tstart + len(tok)
                bases_in_tok = [ci for ci, ch in enumerate(tok) if is_base(ord(ch))]
                if len(bases_in_tok) < 13:
                    continue
                tsk = skel(tok)
                cm = SequenceMatcher(None, joinedHs, tsk, autojunk=False)
                for t2, a1, a2, b1, b2 in cm.get_opcodes():
                    if t2 != "equal":
                        continue
                    for off in range(a2 - a1):
                        if off == 0:
                            continue
                        hpos = a1 + off
                        if hpos not in starts_h:
                            continue
                        bk = b1 + off
                        if bk <= 0 or bk >= len(bases_in_tok):
                            continue
                        ci = tstart + bases_in_tok[bk]
                        if ci not in inserts[(s, ai)]:
                            inserts[(s, ai)].append(ci)
                            total_spaces += 1
                            fixed_ayahs.add((s, a["id"]))

    # ---- apply + validate ----
    old_token_tables = {}
    for (s, ai), positions in sorted(inserts.items()):
        a = data[s][ai]
        old = a["text"]
        new = old
        for ci in sorted(set(positions), reverse=True):
            new = new[:ci] + " " + new[ci:]
        assert new.replace(" ", "") == old.replace(" ", ""), f"{key} {s}:{a['id']} letters changed!"
        old_token_tables[(s, ai)] = old.replace(" ", " ").split(" ")
        a["text"] = new

    # ---- pass 3: hand-verified letter repairs (extraction wrote آ as الۡ) ----
    # The ONLY letter edits this script makes: three ibnwardan tokens where the
    # print's madda-alef came out as alef+lam+sukoon mid-phrase (إِنَّالۡأَوۡحَيۡنَ -
    # impossible Arabic; Hafs shows the madda at the aligned spot: إِنَّآ أَوۡحَيۡنَآ).
    # Exact-token replacements only - a pattern rule would also hit legitimate
    # articles (وَالۡأَسۡبَاطِ in this very ayah). The family writes madda-alef
    # DECOMPOSED (alef + U+0653), matching the rest of the text. Idempotent:
    # once repaired, the glued token no longer exists.
    if key == "ibnwardan":
        TOKEN_FIX = [
            ("4", 162, "إِنَّالۡأَوۡحَيۡنَالۡإِلَيۡكَ", "إِنَّآ أَوۡحَيۡنَآ إِلَيۡكَ"),
            ("4", 162, "كَمَالۡأَوۡحَيۡنَالۡإِلَىٰ", "كَمَآ أَوۡحَيۡنَآ إِلَىٰ"),
            ("5", 11, "بِـَٔايَٰتِنَالۡأُوْلَٰٓئِكَ", "بِـَٔايَٰتِنَآ أُوْلَٰٓئِكَ"),
        ]
        for s, aid, old_tok, new_tok in TOKEN_FIX:
            for a in data.get(s, []):
                if a["id"] != aid:
                    continue
                if old_tok in a["text"]:
                    a["text"] = a["text"].replace(old_tok, new_tok)
                    fixed_ayahs.add((s, aid))
                    flag_stats[f"{key}:madda-letter-repair"] += 1

    # ---- re-key pinned print flags on split words ----
    def token_base_count(tok):
        return sum(1 for ch in tok if is_base(ord(ch)))

    by_surah_ai = defaultdict(dict)
    for (s, ai), toks in old_token_tables.items():
        by_surah_ai[s][data[s][ai]["id"]] = (ai, toks)

    for rule, rows in flags.get(key, {}).items():
        new_rows = []
        for row in rows:
            s, aid, sk, occ, lo, hi = row
            entry = by_surah_ai.get(str(s), {}).get(aid)
            if entry is None:
                new_rows.append(row)
                continue
            ai, old_toks = entry
            n = -1
            wi = None
            for w, t in enumerate(old_toks):
                if raw_skel(t) == sk:
                    n += 1
                    if n == occ:
                        wi = w
                        break
            if wi is None:
                new_rows.append(row)
                continue
            old_tok = old_toks[wi]
            new_toks = data[str(s)][ai]["text"].replace(" ", " ").split(" ")
            if any(raw_skel(t) == sk for t in new_toks):
                # the word survived intact; occurrence ordering also survives
                # because splits only create SHORTER skeletons
                new_rows.append(row)
                continue
            if lo < 0:
                flag_stats[f"{key}:{rule}:dropped-wholeword-split"] += 1
                continue
            # locate old_tok's char span in the repaired ayah (it is the
            # concatenation of consecutive new tokens)
            target = None
            for start in range(len(new_toks)):
                cat = ""
                base_off = 0
                for t in new_toks[start:]:
                    cat += t
                    if cat == old_tok:
                        # found the run new_toks[start:...]; map lo into it
                        boff = 0
                        for tt in new_toks[start:]:
                            nb = token_base_count(tt)
                            if boff <= lo < boff + nb:
                                nl = lo - boff
                                nh = min(hi - boff, nb - 1)
                                target = (tt, nl, max(nl, nh))
                                break
                            boff += nb
                        break
                    if not old_tok.startswith(cat):
                        break
                if target or cat == old_tok:
                    break
            if target is None:
                flag_stats[f"{key}:{rule}:dropped-unmappable"] += 1
                continue
            tt, nl, nh = target
            tsk = raw_skel(tt)
            n = -1
            new_occ = None
            for t in new_toks:
                if raw_skel(t) == tsk:
                    n += 1
                if t is tt:
                    new_occ = n
                    break
            if new_occ is None:
                flag_stats[f"{key}:{rule}:dropped-unmappable"] += 1
                continue
            new_rows.append([s, aid, tsk, new_occ, nl, nh])
            flag_stats[f"{key}:{rule}:rekeyed"] += 1
        flags[key][rule] = new_rows

    REPORT.append((key, len(fixed_ayahs), total_spaces))
    if WRITE:
        write_deflate(QNAME[key], data)

if WRITE:
    with open(FLAGS_PATH, "w") as f:
        json.dump(flags, f, ensure_ascii=False)

print(f"{'WRITTEN' if WRITE else 'DRY RUN'}")
for key, ayahs, spaces in REPORT:
    print(f"  {key:12} ayahs fixed: {ayahs:4}  spaces inserted: {spaces:5}")
for k in sorted(flag_stats):
    print(f"  flag {k}: {flag_stats[k]}")
