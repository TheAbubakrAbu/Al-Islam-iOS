"""Map the MSH-Quraan1 farsh layer, gid by gid, from what the words say.

The volumes' own legend (printed at the foot of every page) reads:
    magenta = الكلمة المخالفة لحفص   blue = الإدغام   red = الإمالة
    cyan    = السكت                  orange = إشمام الصاد صوت الزاي

The magenta layer is where a riwayah departs from Hafs, and the HQPB body layer leaves a
zero-width spacer for each of its glyphs. Dropping this layer therefore deletes exactly the
letters that make a riwayah a riwayah: `جَبۡرَءِيلَ` lost its ء, `وَلِيَسۡتَبِينَ` its ي,
`تَوَلَّاهُ` its لا, `نُوحًا` its ح.

Every entry below was read off the rendered word beside its Hafs counterpart
(`python3 mshmap.py --evidence`), not inferred from the outline alone: the four dagger-alef
gids are one stroke at four stack heights, and the outline cannot tell a dagger alef from
an alef on its own.

    python3 mshmap.py             # write the mappings into manualmap.json
    python3 mshmap.py --evidence  # print the words each gid lands in, with Hafs beside
"""
import sys, json, pathlib, collections, difflib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import final, extract

DATA = pathlib.Path(__file__).resolve().parent / "data"
FAM = "kufi"
VOLUMES = ("shubah", "khalaf", "khallad")

# gid -> emission. Commented with the word that settles it.
GID_EMIT = {
    # --- letters
    96:  "ي",    # وَلِيَسۡتَبِينَ 6:55   (Hafs: وَلِتَسۡتَبِينَ)
    221: "ي",    # يَأۡتِهِم 20:133      (Hafs: تَأۡتِهِم)
    97:  "ل",    # تَوَلَّاهُ 22:4, ٱلرَّسُولَا۠ 33:66, ٱلۡإِنفِطَارِ 82:1
    98:  "ا",    # same three words: the alef #97's lam leans on
    119: "ح",    # نُوحًا 71:1
    170: "ف",    # ٱلۡمُنَٰفِقُونَ 63:1, ٱلۡكَٰفِرُونَ 109:1
    46:  "ء",    # دَأَبٗا 12:47, ءَامَنتُم 7:123
    210: "ء",    # جَبۡرَءِيلَ 2:97/2:98/66:4, زَكَرِيَّآءَ 19:2
    # --- marks
    17:  "ٰ",   # dagger alef: بِمَفَازَٰتِهِمۡ 39:61
    43:  "ٰ",   # dagger alef: رِسَٰلَٰتِهِۦ 6:124, لِلۡكِتَٰبِ 21:104
    78:  "ٰ",   # dagger alef: فَٱنتَهَىٰ 2:275
    87:  "ٰ",   # dagger alef: رِسَٰلَٰتِهِۦ 5:67, 6:124
    29:  "ٓ",   # maddah: قَدَّرۡنَآ 15:60, قٓ 50:1
    30:  "ٓ",   # maddah: أَجۡرِيٓ 10:72/11:29, طسٓ 27:1
    58:  "َ",   # fatha: بِمَفَازَٰتِهِمۡ 39:61
    73:  "َ",   # fatha: يَٰبُنَيَّ 31:13/31:16/31:17
    33:  "ۭ",   # small low meem: أُمَّةِۭ 40:5
    36:  "ۜ",   # small high seen: بَصۜۡطَةٗ 7:69
    41:  "ۨ",   # small high noon: نُـۨجِي 21:88, فَنُـۨجِي 12:110
    70:  "ٌ",   # dammatain: مَلَكٌ 11:12
    54:  "ُ",   # damma: ذُنُوبِهُمُ 28:78 - Hamzah's pronoun damma, magenta on the page
    60:  "ِ",   # kasra: غَيۡرِهِۦ 7:85 - the magenta layer redraws the whole differing word,
                 # so this one lands on top of the black kasra and folds away
    # --- inked but not text
    55:  "",         # a baseline slab, a kashida filler in رِسَٰلَٰتِهِۦ; prints no letter
}
# 7 and 9 are the two waqf signs and are handled separately: see PAUSE_EMIT.
PAUSE_EMIT = {7: "ۖ", 9: "ۚ"}

def keys_by_gid():
    """The live cluster keys, harvested from the segments - never transcribed by hand."""
    out = collections.defaultdict(set)
    for slug in VOLUMES:
        p = DATA / f"{slug}.surahs.json"
        if not p.exists():
            continue
        for surah in json.loads(p.read_text())["data"]:
            for glyphs in surah:
                for f, c in glyphs:
                    key = "sp| " if f == "sp" else f"{f}|{c}"
                    if "MSH" not in key or "||" in key:
                        continue        # multi-member clusters need their own decision
                    head = key.rsplit("|", 1)[0]      # CL|MSH-Quraan1#210
                    gid = head.rpartition("#")[2]
                    if gid.isdigit():
                        out[int(gid)].add(key)
    return out

def evidence():
    detmap = final.build_detmap(FAM)
    ctx = json.loads((DATA / f"ctxdet-{FAM}.json").read_text())
    H = json.loads((extract.APP / "Resources/JSONs-Deprecated/Quran.json").read_text())
    hafs = {s["id"]: {a["id"]: a["textArabic"] for a in s["ayahs"]} for s in H}
    rows = collections.defaultdict(list)
    for slug in VOLUMES:
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        for sid, surah in enumerate(seg["data"], 1):
            for aid, glyphs in enumerate(surah, 1):
                for w in extract.glyph_words(glyphs):
                    ks = [f"{f}|{c}" for f, c in w if f != "sp"]
                    hit = {k for k in ks if "MSH" in k and "#38|" not in k}
                    if not hit:
                        continue
                    r = final.render_det(w, detmap, None, FAM, ctx)
                    exp = hafs.get(sid, {}).get(aid, "").split()
                    m = difflib.get_close_matches(r.replace("✗", ""), exp, n=1, cutoff=0.2)
                    for k in hit:
                        rows[k].append((slug, sid, aid, r, m[0] if m else ""))
    for k in sorted(rows, key=lambda x: -len(rows[x])):
        print(f"=== {k}  x{len(rows[k])}")
        for slug, sid, aid, r, near in rows[k][:6]:
            print(f"    {slug:8}{sid}:{aid:<5} got={r!r:26} hafs~={near!r}")

def main():
    if "--evidence" in sys.argv:
        evidence(); return
    emit = dict(GID_EMIT)
    if "--with-pauses" in sys.argv:
        emit.update(PAUSE_EMIT)
    live = keys_by_gid()
    manual = json.loads((DATA / "manualmap.json").read_text())
    n = 0
    for gid, val in sorted(emit.items()):
        for key in sorted(live.get(gid, ())):
            manual[key] = val
            n += 1
            print(f"  MSH#{gid:<5} {key!r:34} -> {val!r}")
    (DATA / "manualmap.json").write_text(
        json.dumps(manual, ensure_ascii=False, indent=1, sort_keys=True))
    print(f"wrote {n} MSH entries; manualmap={len(manual)}")

if __name__ == "__main__":
    main()
