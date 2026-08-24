"""Show every word containing a given font#gid, with the expected Hafs word beside it.

    python3 findglyph.py khalaf HQPB1#149 HQPB2#13 HQPB4#7

Use it before mapping an unresolved glyph: seeing the word it lands in, next to Hafs,
usually settles what the glyph must be.
"""
import sys, json, pathlib, difflib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import final, extract

FAM = "kufi"

def hafs():
    d = json.loads((extract.APP / "Resources/JSONs-Deprecated/Quran.json").read_text())
    return {s["id"]: {a["id"]: a["textArabic"] for a in s["ayahs"]} for s in d}

def main():
    slug, wanted = sys.argv[1], sys.argv[2:]
    detmap = final.build_detmap(FAM)
    ctx = json.loads((pathlib.Path("data") / f"ctxdet-{FAM}.json").read_text())
    seg = json.loads((pathlib.Path("data") / f"{slug}.surahs.json").read_text())
    H = hafs()
    for sid, surah in enumerate(seg["data"], 1):
        for aid, glyphs in enumerate(surah, 1):
            words = extract.glyph_words(glyphs)
            rendered = [final.render_det(w, detmap, None, FAM, ctx) for w in words]
            for i, w in enumerate(words):
                keys = [f"{f}|{c}" for f, c in w if f != "sp"]
                hit = [g for g in wanted if any(f"{g}|" in k for k in keys)]
                if not hit:
                    continue
                exp = H.get(sid, {}).get(aid, "").split()
                near = ""
                if exp:
                    m = difflib.get_close_matches(rendered[i], exp, n=1, cutoff=0.3)
                    near = m[0] if m else ""
                print(f"  {sid}:{aid:<4} {','.join(hit):14} got={rendered[i]!r:26} hafs~={near!r}")

if __name__ == "__main__":
    main()
