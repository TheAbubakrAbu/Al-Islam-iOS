"""Every word that still renders with an unresolved-glyph marker, beside the Hafs word.

`emit` deletes those markers ("✗") silently, so a dropped LETTER leaves two vowels stacked
and a dropped MARK just vanishes. This lists what is actually being lost, which is the only
honest way to decide whether a leftover glyph matters.

    python3 showdrops.py khalaf khallad
"""
import sys, json, pathlib, difflib, collections
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import final, extract

FAM = "kufi"
DATA = pathlib.Path(__file__).resolve().parent / "data"

def hafs():
    d = json.loads((extract.APP / "Resources/JSONs-Deprecated/Quran.json").read_text())
    return {s["id"]: {a["id"]: a["textArabic"] for a in s["ayahs"]} for s in d}

def main():
    detmap = final.build_detmap(FAM)
    ctx = json.loads((DATA / f"ctxdet-{FAM}.json").read_text())
    H = hafs()
    for slug in sys.argv[1:]:
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        print(f"=== {slug}")
        byglyph = collections.Counter()
        rows = []
        for sid, surah in enumerate(seg["data"], 1):
            for aid, glyphs in enumerate(surah, 1):
                for w in extract.glyph_words(glyphs):
                    r = final.render_det(w, detmap, None, FAM, ctx)
                    if "✗" not in r:
                        continue
                    keys = [f"{f}|{c}" for f, c in w if f != "sp"]
                    bad = [k for k in keys if detmap.get(k) is None and "HQPB5#20|1" not in k]
                    for k in bad:
                        byglyph[k] += 1
                    exp = H.get(sid, {}).get(aid, "").split()
                    m = difflib.get_close_matches(r.replace("✗", ""), exp, n=1, cutoff=0.25)
                    rows.append((sid, aid, r, m[0] if m else "", bad))
        print(f"  words containing a dropped glyph: {len(rows)}")
        for sid, aid, r, near, bad in rows[:25]:
            print(f"   {sid}:{aid:<4} got={r!r:24} hafs~={near!r:22} {[b.split('|')[0] for b in bad]}")
        if len(rows) > 25:
            print(f"   ... {len(rows) - 25} more")
        print("  by glyph:", byglyph.most_common(10))

if __name__ == "__main__":
    main()
