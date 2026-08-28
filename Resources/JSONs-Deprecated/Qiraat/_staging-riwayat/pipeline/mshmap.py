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
import os, sys, json, pathlib, collections, difflib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import final, extract

DATA = pathlib.Path(__file__).resolve().parent / "data"
FAM = "kufi"
VOLUMES = tuple(os.environ.get("QIRAAT_MSH_VOLUMES", "shubah khalaf khallad").split())
# Override per family: QIRAAT_MSH_VOLUMES="shubah abuharith durikisai" python3 mshmap.py …

# gid -> emission. Commented with the word that settles it.
GID_EMIT = {
    # --- letters
    96:  "ي",    # وَلِيَسۡتَبِينَ 6:55   (Hafs: وَلِتَسۡتَبِينَ)
    221: "ي",    # يَأۡتِهِم 20:133      (Hafs: تَأۡتِهِم)
    97:  "ل",    # تَوَلَّاهُ 22:4, ٱلرَّسُولَا۠ 33:66, ٱلۡإِنفِطَارِ 82:1
    98:  "ا",    # same three words: the alef #97's lam leans on
    119: "ح",    # نُوحًا 71:1
    170: "ف",    # ٱلۡمُنَٰفِقُونَ 63:1, ٱلۡكَٰفِرُونَ 109:1
    101: "ا",    # alef: Al-Kisai's إِذَا دَبَرَ 74:33 (Hafs: إِذۡ أَدۡبَرَ). Its other 40
                 # occurrences are the banner line's stray alef, dropped by size and never
                 # by key - see extract.MSH_BANNER_RATIO.
    46:  "\u0654",  # hamza ABOVE (font bounds y 1440..1981, clear of the baseline), not a
                 # standalone ء: it belongs ON the alef beside it. Emitted as the combining
                 # hamza so `compose_hamza` below folds ا + ٔ into أ - which also stops the
                 # الله rule from seeing a bare `اَ` and expanding `لَّأَذَقۡنَٰكَ` (17:75) into
                 # `لَّٱللَّءَذَقۡنَٰكَ`. دَأۡبٗا 12:47, ءَأَٰمَنتُم 7:123.
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
    44:  "\u06e5",  # SMALL WAW: the pronoun silah after a damma. Ibn Amir reads
                 # `نُورَهُۥ` 61:8, `أَمۡرَهُۥ` 65:3, `يَرۡضَهُۥ` 39:8, `وَقِيلَهُۥ` 43:87 where
                 # Hafs has a bare kasra-ha. Outline is the small waw, confirmed against
                 # the black `لِيُظۡهِرَهُۥ` printed two lines below it on the same page.
    16:  "\u06e6",  # SMALL YEH: the same silah after a kasra. `وَنِصۡفِهِۦ` and
                 # `وَثُلُثِهِۦ` 73:20, `ٱقۡتَدِهِۦ` 6:90. Flat wide hook (944 x 430) against
                 # #44's upright comma, and the vowel before it decides which is drawn.
    72:  "",       # a long diagonal kashida stroke (1,481 units) inside the magenta redraw
                 # of `ٱلۡمُخۡلِصِينَ` 37:40/160/169; a connector, not a letter. Cf. #55.
    33:  "ۭ",   # small low meem: أُمَّةِۭ 40:5
    36:  "ۜ",   # small high seen: بَصۜۡطَةٗ 7:69
    41:  "ۨ",   # small high noon: نُـۨجِي 21:88, فَنُـۨجِي 12:110
    70:  "ٌ",   # dammatain: مَلَكٌ 11:12
    54:  "ُ",   # damma: ذُنُوبِهُمُ 28:78 - Hamzah's pronoun damma, magenta on the page
    60:  "ِ",   # kasra: غَيۡرِهِۦ 7:85 - the magenta layer redraws the whole differing word,
                 # so this one lands on top of the black kasra and folds away
    # --- inked but not text
    39:  "\u0650",  # ISHMAM. A filled dot printed where the kasra belongs, on exactly the
                 # seven-word set the readers blend toward damma: قِيلَ x34, وَقِيلَ x15,
                 # سِيٓءَ, وَسِيقَ, وَغِيضَ, وَحِيلَ, جِيٓءَ, سِيٓـَٔتۡ, وَجِيٓءَ. Al-Kisai and
                 # Ibn Amir print it; Hamzah does not, which is why the gid is absent from
                 # the Khalaf volumes. The dot REPLACES the kasra on the page, so dropping
                 # this layer left the letter with no vowel at all: shipped QiraahAbuHarith,
                 # QiraahDuriKisai and QiraahHisham all read a bare `قيلَ`. The vowel really
                 # is a kasra (ishmam is a manner of pronouncing it, not a different vowel),
                 # so the text gets U+0650 and the ishmam itself is recorded separately in
                 # data/ishmam-kasr.json for the tajweed layer to draw.
    49:  "\u06e0",  # SMALL HIGH UPRIGHT RECTANGULAR ZERO: the ha of يَتَسَنَّهۡ 2:259 and
                 # ٱقۡتَدِهۡ 6:90, which Hamzah and Al-Kisai drop in wasl and pronounce in
                 # waqf - precisely what that mark means. Printed as an upright oval
                 # (389 x 454 units), so not the round zero U+06DF.
    55:  "",         # a baseline slab, a kashida filler in رِسَٰلَٰتِهِۦ; prints no letter
}
# 7, 8, 9 and 13 are the waqf signs and are handled separately: see PAUSE_EMIT.
PAUSE_EMIT = {7: "ۖ", 8: "ۗ", 9: "ۚ", 13: "ۙ"}
# 8 is قلى U+06D7 (ٱلۡأٓخِرَةِۗ 3:148); 13 is لا U+06D9, the Shami pair's no-stop sign.

def _is_msh(key):
    """The farsh layer, under either spelling of its font name.

    The Kufi volumes of Hamzah, Al-Kisai and Ibn Amir call it `MSH-Quraan1`; the two Khalaf
    al-Ashir volumes call it `MshQuraan1`. A case-sensitive test on "MSH" silently mapped
    NOTHING for the latter, which reads as "this volume has no farsh layer" rather than as
    a miss - and its 2,900 glyphs would have gone on being dropped. `extract.DROP_PREFIX`
    and `_is_msh_text` already accept both; this had been left behind.
    """
    return "MSH" in key or "Msh" in key


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
                    if not _is_msh(key) or "||" in key:
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
                    hit = {k for k in ks if _is_msh(k) and "#38|" not in k}
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
