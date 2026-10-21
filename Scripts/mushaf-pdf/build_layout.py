"""raw quran.com page JSON -> layout.json for the generator.
Per page: 15 lines, each {type: ayah|surah|basmalah, centered: bool, words: [[surah, ayah, position], ...],
ends: [[surah, ayah]]  (ayah-number markers that sit on this line, in order)}.
Positions are the app's whitespace tokens (Quran.json), aligned to the API's word positions."""
import sys, os, json, glob, collections, re
def skel(t):
    # rasm-ish skeleton: letters only; quran.com writes some ya as alef maqsura (فى) and the app as ya
    t = t.replace("\u0671", "\u0627").replace("\u0640", "").replace("\u0649", "\u064A")
    return re.sub(r"[^\u0621-\u064A]", "", t)
raw_dir, quran_json, out = sys.argv[1], sys.argv[2], sys.argv[3]
quran = json.load(open(quran_json))
app_words = {}
for s in quran:
    for a in s["ayahs"]:
        toks = s_text = a["textArabic"].replace(" ", " ").split()
        app_words[(s["id"], a["id"])] = toks
api_counts = {}
pages = {}
mism = []
align_fail = []
for f in sorted(glob.glob(os.path.join(raw_dir, "*.json"))):
    p = int(os.path.basename(f)[:3]); d = json.load(open(f))
    lines = collections.defaultdict(list); ends = collections.defaultdict(list)
    for v in d["verses"]:
        s, a = map(int, v["verse_key"].split(":"))
        ws = [w for w in v["words"] if w["char_type_name"] == "word"]
        es = [w for w in v["words"] if w["char_type_name"] == "end"]
        # positions are 1-based and contiguous for words; "end" has its own position
        n_api = len(ws)
        if (s, a) in api_counts: api_counts[(s, a)] = max(api_counts[(s, a)], n_api)
        else: api_counts[(s, a)] = n_api
        # Align the API's words to the app's tokens by rasm skeleton: 1:1 normally; an API word may hold
        # TWO app tokens ("بَعۡدَ مَا", "إِلۡ يَاسِينَ"); two API words may be ONE app token ("لَّوۡمَا", "مَالِيَ").
        app = app_words.get((s, a), [])
        rub = 1 if app and app[0] == "\u06de" else 0
        app = app[rub:]
        api_sk = [skel(w["text_uthmani"]) for w in ws]
        app_sk = [skel(t) for t in app]
        i = j = 0; mapping = [[] for _ in ws]; ok = True
        while i < len(ws) and j < len(app):
            if api_sk[i] == app_sk[j]:
                mapping[i] = [j]; i += 1; j += 1
            elif j + 1 < len(app) and api_sk[i] == app_sk[j] + app_sk[j + 1]:
                mapping[i] = [j, j + 1]; i += 1; j += 2
            elif i + 1 < len(ws) and api_sk[i] + api_sk[i + 1] == app_sk[j]:
                mapping[i] = [j]; mapping[i + 1] = []; i += 2; j += 1
            else:
                ok = False; break
        if not ok or i != len(ws) or j != len(app):
            align_fail.append((s, a, i, len(ws), j, len(app))); mapping = [[k] if k < len(app) else [] for k in range(len(ws))]
        for w, toks in zip(ws, mapping):
            for n, k in enumerate(toks):
                lines[w["line_number"]].append((s, a, k + 1, w["text_uthmani"] if n == 0 else ""))
        for e in es:
            ends[e["line_number"]].append((s, a))
    pages[p] = (lines, ends, d)
# word-count audit
for key, n in api_counts.items():
    m = len(app_words.get(key, []))
    if m != n: mism.append((key, m, n))
print("ayahs seen", len(api_counts), "count mismatches app vs api:", len(mism), "alignment failures:", align_fail[:10])

surah_first_page = {}
layout = {}
carry_headers = {}
for p in sorted(pages):
    lines, ends, d = pages[p]
    used = sorted(lines)
    out_lines = {}
    for ln in used:
        out_lines[ln] = {"type": "ayah", "centered": False,
                         "words": [[s, a, pos] for s, a, pos, t in lines[ln]], "ends": [list(e) for e in ends.get(ln, [])]}
    # ends that fall on lines with no words (shouldn't happen) -> attach
    for ln, es in ends.items():
        if ln not in out_lines: out_lines[ln] = {"type": "ayah", "centered": False, "words": [], "ends": [list(e) for e in es]}
    # surah starts on this page: first word of ayah 1 position 1
    for ln in used:
        for s, a, pos, t in lines[ln]:
            if a == 1 and pos == 1:
                hdr = ln - 1 if s in (1, 9) else ln - 2
                header = {"type": "surah", "centered": True, "surah": s, "words": [], "ends": []}
                if hdr >= 1:
                    out_lines[hdr] = header
                else:
                    # The print sets the banner on the LAST line of the previous page (an-Nisa on
                    # page 76) and the basmalah opens this page.
                    carry_headers.setdefault(p - 1, []).append((15 + hdr, header))
                if s not in (1, 9): out_lines[ln - 1] = {"type": "basmalah", "centered": True, "words": [], "ends": []}
    # centered: pages 1-2 entirely; the line holding a surah's last ayah marker
    for ln, L in out_lines.items():
        if p <= 2: L["centered"] = True
        for s, a in L["ends"]:
            if a == quran[s - 1]["numberOfAyahs"]: L["centered"] = True
    for ln, header in carry_headers.get(p, []):
        out_lines[ln] = header
    missing = [ln for ln in range(1, 16) if ln not in out_lines]
    extra = [ln for ln in out_lines if ln < 1 or ln > 15]
    layout[p] = [out_lines.get(ln, {"type": "empty", "centered": False, "words": [], "ends": []}) for ln in range(1, 16)]
    if missing or extra:
        print(f"page {p}: missing lines {missing} extra {extra}")
for p, items in carry_headers.items():
    if p in layout:
        for ln, header in items:
            layout[p][ln - 1] = header
bad_lines = 0
for p in sorted(pages):
    lines, ends, d = pages[p]
    for ln, ws in lines.items():
        api_sk = "".join(skel(t) for s, a, pos, t in ws)
        app_sk = "".join(skel(app_words[(s, a)][pos - 1 + (1 if app_words[(s, a)][0] == "\u06de" else 0)]) for s, a, pos, t in ws)
        api_sk = "".join(skel(t) for s, a, pos, t in ws)
        if api_sk != app_sk:
            bad_lines += 1
            if bad_lines <= 6: print("SKELETON MISMATCH page", p, "line", ln, api_sk[:40], "|", app_sk[:40])
print("lines audited; skeleton mismatches:", bad_lines)
json.dump({"pages": layout}, open(out, "w"), ensure_ascii=False)
print("pages written", len(layout))
