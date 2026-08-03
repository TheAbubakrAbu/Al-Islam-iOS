#!/usr/bin/env python3
"""Validation + final emit for extracted riwayah texts.

  validate            → all checks over data/<slug>.text.json
  emit                → write QiraahX.json files into the app's JSONs folder
"""
import json, sys, collections, pathlib, unicodedata

BASE = pathlib.Path(__file__).resolve().parent
DATA = BASE / "data"
APP = pathlib.Path("/Users/theabubakrabu/Library/Mobile Documents/com~apple~CloudDocs/Projects/(1) iOS/Al-Islam-iOS")
OUTDIR = APP / "Resources/JSONs-Deprecated/Qiraat"

TARGETS = {
    # slug → (output name, qiraah family, counting)
    "hisham":     ("QiraahHisham",     "ibn-amir",  "dimashqi"),
    "ibndhakwan": ("QiraahIbnDhakwan", "ibn-amir",  "dimashqi"),
    "khalaf":     ("QiraahKhalaf",     "hamzah",    "kufi"),
    "khallad":    ("QiraahKhallad",    "hamzah",    "kufi"),
    "abuharith":  ("QiraahAbuHarith",  "kisai",     "kufi"),
    "durikisai":  ("QiraahDuriKisai",  "kisai",     "kufi"),
    "ibnwardan":  ("QiraahIbnWardan",  "abujafar",  "madani-first"),
    "ibnjammaz":  ("QiraahIbnJammaz",  "abujafar",  "madani-first"),
    "ruways":     ("QiraahRuways",     "yaqub",     "basri"),
    "rawh":       ("QiraahRawh",       "yaqub",     "basri"),
    "ishaq":      ("QiraahIshaq",      "khalaf10",  "kufi"),
    "idris":      ("QiraahIdris",      "khalaf10",  "kufi"),
}
TOTALS = {"kufi": 6236, "dimashqi": 6226, "madani-first": 6214, "basri": 6204}

def skeleton(text):
    out = []
    for ch in text:
        if unicodedata.combining(ch): continue
        if ch in " ـ�": continue
        out.append("ا" if ch == "ٱ" else ch)
    return "".join(out)

def load(slug):
    return json.loads((DATA / f"{slug}.text.json").read_text())

def hafs():
    q = json.loads((APP / "Resources/JSONs-Deprecated/Quran.json").read_text())
    return {int(s["id"]): [a["textArabic"] for a in s["ayahs"]] for s in q}

def counts(d):
    return [len(d[str(i)]) for i in range(1, 115)]

def validate():
    H = hafs()
    hc = [len(H[i]) for i in range(1, 115)]
    ok = True
    loaded = {}
    for slug in TARGETS:
        p = DATA / f"{slug}.text.json"
        if not p.exists():
            print(f"{slug}: NOT EXTRACTED YET"); ok = False; continue
        loaded[slug] = load(slug)

    # 1) totals + garbage scan
    for slug, d in loaded.items():
        c = counts(d)
        tot = sum(c)
        want = TOTALS[TARGETS[slug][2]]
        bad = sum(t.count("�") for v in d.values() for a in v for t in [a["text"]])
        empty = sum(1 for v in d.values() for a in v if not a["text"].strip())
        flag = "OK " if (tot == want and bad == 0 and empty == 0) else "FAIL"
        print(f"[{flag}] {slug:<11} total={tot} (want {want})  unmapped_chars={bad}  empty={empty}")
        if flag == "FAIL": ok = False

    # 2) kufi targets: per-surah counts must equal Hafs exactly
    for slug, d in loaded.items():
        if TARGETS[slug][2] != "kufi": continue
        c = counts(d)
        diffs = [(i + 1, a, b) for i, (a, b) in enumerate(zip(c, hc)) if a != b]
        if diffs:
            ok = False
            print(f"[FAIL] {slug}: kufi per-surah mismatches vs Hafs: {diffs[:6]}")

    # 3) family twins: identical counting ⇒ identical per-surah counts
    fams = collections.defaultdict(list)
    for slug in loaded: fams[TARGETS[slug][1]].append(slug)
    for fam, slugs in fams.items():
        if len(slugs) != 2: continue
        a, b = slugs
        ca, cb = counts(loaded[a]), counts(loaded[b])
        diffs = [(i + 1, x, y) for i, (x, y) in enumerate(zip(ca, cb)) if x != y]
        stat = "OK " if not diffs else "FAIL"
        if diffs: ok = False
        print(f"[{stat}] twins {a} ≡ {b}: per-surah count diffs = {diffs[:6] if diffs else 'none'}")

    # 4) farsh spot-check: Fatiha malik/maalik (dagger alef U+0670 on the first word)
    MAALIK = {"abuharith", "durikisai", "ruways", "rawh", "ishaq", "idris"}   # + Hafs/Shubah
    MALIK = {"hisham", "ibndhakwan", "khalaf", "khallad", "ibnwardan", "ibnjammaz"}
    for slug, d in loaded.items():
        fat = d["1"]
        hit = None
        for a in fat:
            if skeleton(a["text"]).startswith("ملك") or skeleton(a["text"]).startswith("مالك"):
                hit = a; break
        if hit is None:
            print(f"[FAIL] {slug}: no malik ayah found in Fatiha"); ok = False; continue
        w = hit["text"].split()[0]
        has_alef = ("ٰ" in w) or ("مَا" in w) or ("مَا" in w)
        want_alef = slug in MAALIK
        stat = "OK " if has_alef == want_alef else "FAIL"
        if has_alef != want_alef: ok = False
        print(f"[{stat}] {slug:<11} Fatiha {hit['id']}: {w}  (maalik={has_alef}, expected {want_alef})")

    # 5) word-diff ratio vs Hafs for kufi targets (sane band 1..12%)
    for slug, d in loaded.items():
        if TARGETS[slug][2] != "kufi": continue
        tot = difn = 0
        for sid in range(1, 115):
            for a, htext in zip(d[str(sid)], H[sid]):
                aw, hw = a["text"].split(), htext.split()
                if len(aw) == len(hw):
                    for x, y in zip(aw, hw):
                        tot += 1
                        if skeleton(x) != skeleton(y): difn += 1
        pct = 100.0 * difn / max(tot, 1)
        stat = "OK " if 0.05 <= pct <= 15 else "WARN"
        print(f"[{stat}] {slug:<11} rasm-diff vs Hafs: {pct:.2f}% of aligned words")

    print("\nVALIDATION", "PASSED" if ok else "HAS FAILURES")
    return ok

def emit():
    for slug, (name, _, _) in TARGETS.items():
        d = load(slug)
        out = OUTDIR / f"{name}.json"
        out.write_text(json.dumps(d, ensure_ascii=False, separators=(",", ":")))
        print(f"wrote {out.name}: {sum(len(v) for v in d.values())} ayahs, {out.stat().st_size:,} bytes")

if __name__ == "__main__":
    if sys.argv[1] == "validate":
        validate()
    elif sys.argv[1] == "emit":
        emit()
