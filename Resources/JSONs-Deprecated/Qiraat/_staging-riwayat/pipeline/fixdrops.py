"""Resolve the glyphs that `emit` was silently discarding.

Two very different things were being lumped together as "unresolved":

* **Page furniture** - the decorative basmalah drawn at the head of every surah (Hamd2
  gids 198/199/200, 112 of each = one per surah) and the rosette that flanks the surah-name
  banner (HQPB2 193/194). These SHOULD vanish, but leaving them unmapped inflated the
  "unresolved" count to ~400 per volume and hid the handful of real losses underneath.
  They go in `droplist.json`, which exists for exactly this.

* **Real text** - chiefly HQPB4 gid 7, the maddah of the muqatta'at: `ٱلٓم✗` should be
  `الٓمٓ`. 10 occurrences per volume.

Run after `segment`, then re-`emit`.
"""
import json, os, pathlib, collections, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import final, extract

DATA = pathlib.Path(__file__).resolve().parent / "data"
FAM = os.environ.get("QIRAAT_FAMILY", "kufi")
# Override per family: QIRAAT_FAMILY=madani python3 fixdrops.py ibnwardan ibnjammaz

# gid -> emission for real marks that were being dropped
REAL = {
    "HQPB4#7":   "ٓ",        # maddah (U+0653); the muqatta'at's second maddah
    "HQPB1#149": "ش",         # letter sheen, dropped from ٱنشَقَّتۡ (84:1, both volumes)
    "HQPB2#13":  "ق",         # letter qaf, same word
    "HQPB5#113": "َ",        # fatha: gives Hamzah's سَكۡرىٰ (22:2) and يَكُن (18:43)
    "HQPB5#112": "َ",        # fatha, one stack step taller than #113 (h 1841 vs 1479):
                              # Al-Kisai's لَمۡ يَكُن فِتۡنَتَهُمۡ (6:23), printed magenta
    "HQPB4#38":  "ِۭ",      # kasra + small low meem (U+0650 U+06ED): خَوۡفِۭ (106:4),
                              # مُّمَدَّدَةِۭ (104:9). Drawn as two layer copies; the
                              # doubled-mark collapse downstream folds them back to one.

    # --- Abu Jafar (Madani). Every one of these was corroborated against the app's
    # KFGQPC-verified Qaloon text, the other Madani riwayah, word for word.
    "Hamd2#54":  "ُۥ",      # SILAT MEEM AL-JAM', the defining Abu Jafar feature: the
    "Hamd2#53":  "ُۥ",      # plural meem read as a full waw, لَهُمُۥ. The print draws it
    "Hamd2#60":  "ُۥ",      # RED, which its own page legend calls صلة ميم الجمع, as ONE
                              # composite glyph carrying both the damma above the meem and
                              # the waw below (outline bounds run -1035..1462, i.e. ink on
                              # both sides of the baseline). Three gids, one job, differing
                              # only in advance width (429/435/549) as the line is fitted.
                              #
                              # The meem carries no other vowel: `عَلَيۡهِم` extracts as
                              # ع َ ل َ ي ۡ ه ِ م and then this glyph, nothing else. So the
                              # same rule as the ishmam dot applies - it has to come out as
                              # the vowel it replaced, or the word ships unvocalised, which
                              # is exactly the defect in the shipped QiraahIbnWardan and
                              # QiraahIbnJammaz: 5,786 bare meems each.
    "HQPB2#91":  "لۡأ",    # the لأ ligature of ٱلۡأٓخِرَةِ / ٱلۡأٓخِرِ. Shipped drops it
                              # outright (`وَبِآخِرَةِ` for `وَبِٱلۡأٓخِرَةِ`); Qaloon prints
                              # `وَبِالۡأٓخِرَةِ`, which is what this restores. 271 per volume.
    "HQPB2#159": "ۧ",       # SMALL HIGH YEH (U+06E7) of ٱلنَّبِيِّۧنَ. Shipped keeps it in
                              # exactly one word of 14 and loses it in the other 13.
    "Hamd2#52":  "ُۥ",      # a FOURTH advance-width variant of the same silah composite,
                              # and it happens to be the one al-Fatihah uses (1:6, 1:7).
    "Hamd2#64":  "اٰ۬",     # the other tasheel spelling, the one whose hamza is printed
                              # separately: `ءَ` + this = `ءَاٰ۬مَنتُمۡ` (7:122), again the
                              # Qaloon spelling exactly, marks in that order.
    "HQPB3#28":  "يٰ",      # ya + dagger alef: `يُلَقَّيٰهُ` (17:13) and `دَسَّيٰهَا` (91:10),
                              # both matching Qaloon; the Madani rasm writes these with a ya
                              # where Hafs writes an alef maqsura.
    "Hamd2#75":  "أْ",      # hamza-on-alef + jazm of `فَٱدَّٰرَأْتُمۡ` (2:71).
    "HQPB2#192": "ض",         # letter dad, dropped from `لِبَعۡضٖ` (25:20).
    "Hamd2#132": "لِإِ",     # the `لِإِ` of `لِإِيلَٰفِ` (106:1).
    # --- Yaqub (Basri). Both are drawn in the volumes' own coloured layers, and NEITHER
    # exists anywhere in the Basri bridge volumes (Duri and Susi print neither mark), so
    # no amount of learning can reach them: they have to be stated. Both are RUWAYS ONLY.
    # Rawh's volume contains neither glyph, which is the documented split between Yaqub's
    # two rawis and the strongest corroboration available that these read correctly.
    "Hamd2#44":  "صِۜ",    # MAGENTA (the legend's the-letter-differing-from-Hafs): a sad
    "Hamd2#45":  "صِّۜ",   # carrying a small seen above it, the standing notation for
                              # reading al-siraat as al-siraat with sin. U+06DC SMALL HIGH
                              # SEEN is the app's own spelling of it: the verified
                              # QiraahQunbul, the other riwayah that reads sin here, writes
                              # it exactly that way, 49 times.
                              # #44 is the bare word (39x); #45 only ever follows the
                              # article and so carries the assimilation shadda (6x).
                              # 39 + 6 = 45, the Quran's exact count of that word.
    "Hamdy2#207": "ٜ",     # RED (the legend's imalah) - a FILLED dot below the baseline,
    "Hamdy2#204": "ٜ",     # which is imalah kubra rather than the hollow taqlil dot.
    "Hamdy2#149": "ٜ",     # Four gids, one mark, differing only in advance width, all
    "Hamdy2#201": "ٜ",     # 89 of them on the kaf of al-kaafireen - and the Basri bridge
                              # spells that exact word with U+065C there. Shipped
                              # QiraahRuways carries ZERO U+065C, so all 89 are lost today.
    # --- Khalaf al-Ashir (Kufi). The two volumes draw a handful of glyphs in `Hamdy4`,
    # a font neither Hamzah nor Al-Kisai nor Ibn Amir uses, so nothing in the family has
    # ever seen them. Everything else these volumes were losing was a known glyph behind
    # an unfamiliar cmap code and is handled by `final.GIDFALLBACK` instead; these five
    # are the genuine residue.
    "Hamdy4#172": "ٜ",     # a filled dot below the baseline: imalah kubra on the jeem of
                              # `جَآءَكُم` (2:92) and `فَجَآءَهَا` (7:4), which is Hamzah's
                              # reading and so Khalaf al-Ashir's. Same mark as Hamd2#170.
    "Hamdy4#106": "ل",       # the lam of `لَّأَذَقۡنَٰكَ` (17:75),
    "Hamdy4#107": "ا",       # its alef,
    "Hamdy4#10":  "\u0654",  # and the hamza that belongs ON that alef - emitted as the
                              # COMBINING hamza, not a standalone ء, so `compose_hamza`
                              # folds ا + ٔ into أ. Emitting ء instead leaves a bare `اَ`
                              # for the الله rule to expand, which is the
                              # `لَّٱللَّءَذَقۡنَٰكَ` corruption of §3c all over again.
    "Hamd2#76":  "ءَٰا۬",  # the TASHEEL cluster of the `ءَأَ` interrogatives, printed
                              # MAGENTA (the legend's الحرف المخالف لحفص). Qaloon spells
                              # these `ءَٰا۬نتُمۡ` / `ءَٰا۬نذَرۡتَهُمۡ` / `ءَٰا۬سۡلَمۡتُمۡ`,
                              # and all 13 distinct words carrying this glyph appear in that
                              # list, so the five-character emission is the source's own.
}

# Whole CLUSTER keys, for the cases where the decision is not a property of one gid.
# `REAL` above is keyed on `font#gid` and so cannot reach a multi-member cluster; the
# geometric dot-attachment in `extract` normalises the HQPB5 imalah dot into its own token
# but leaves a dot drawn in another font sitting INSIDE the letter's cluster, where it has
# to be read as one glyph with the letter.
REAL_KEYS = {
    # ش carrying a filled below-baseline dot: `شَآءَ` at 81:28, read with imalah exactly as
    # `جَآءَ` is. Hamd2#145 is the same dot outline as Hamd2#170/#172 and Hamdy4#172.
    "CL|HQPB1#137|©||Hamd2#145|©": "شٜ",
}

# Glyphs with NO outline at all. These are the body layer's zero-width spacers, the ones
# it leaves where a farsh glyph from the MSH layer goes (see the module docstring of
# mshmap.py). Unmapped they render as a dropped-glyph marker in the middle of the word and,
# worse, they hide the base letter from `final.ishmam_dot`, which walks back through the
# emitted text to decide what the ishmam dot caps. That is why `قِيلَ` stayed broken in
# Hisham after the dot itself was mapped: HQPB7#3 sits between the qaf and the dot, 204
# times in that volume alone. Verified blank by BoundsPen in every volume that embeds them.
SPACER_GIDS = {
    "HQPB7#3",
    "HQPB4#6",   # 0.02pt wide in all 55/52/1 of its hisham/ibndhakwan/shubah occurrences,
                 # so it prints nothing anywhere. The EM still gave it a confident
                 # three-character emission, `\u0650\u06e6\u06da`, and since the glyph is
                 # drawn twice that put a junk word `ِۦِۚۦۚ` after 21 muqatta'at ayahs.
                 # A zero-width glyph is never text, whatever its outline says.
}

# gid prefixes that are page furniture and must render as nothing
FURNITURE_GIDS = {
    "Hamd2#198", "Hamd2#199", "Hamd2#200",   # decorative basmalah, 1 per surah
    "Hamd2#100", "Hamd2#105",                # its لأ / لإ ligature pieces
    "Hamd2#111", "Hamd2#174", "Hamd2#193", "Hamd2#169",
    "HQPB2#193", "HQPB2#194",                # surah-banner rosette
    "HQPB3#72", "HQPB3#73", "HQPB3#74",      # the Al-Kisai volumes draw the decorative
                                             # basmalah here instead of in Hamd2: three
                                             # stretched pieces (4460, 7353 and 10411 units
                                             # wide), 112 of each, one per surah
}

def main(slugs=("khalaf", "khallad")):
    detmap = final.build_detmap(FAM)
    ctx = json.loads((DATA / f"ctxdet-{FAM}.json").read_text())
    seen = collections.Counter()
    for slug in slugs:
        p = DATA / f"{slug}.surahs.json"
        if not p.exists():
            print(f"  (no {p.name}; run `extract.py segment {slug}` first)")
            continue
        seg = json.loads(p.read_text())
        miss = collections.Counter()
        for surah in seg["data"]:
            for g in surah:
                final.render_det(g, detmap, miss, FAM, ctx)
        seen.update(miss)

    manual = json.loads((DATA / "manualmap.json").read_text())
    drops = set(json.loads((DATA / "droplist.json").read_text()))
    nreal = nfurn = 0
    for key in seen:
        if key in REAL_KEYS:
            manual[f"{FAM}:{key}"] = REAL_KEYS[key]; nreal += 1
            print(f"  REAL      {key:14} x{seen[key]:<4} -> {REAL_KEYS[key]!r}")
            continue
        body = key[3:] if key.startswith("CL|") else key
        gid = body.rsplit("|", 1)[0]
        if gid in REAL:
            # Scoped to the family being run; see the manualmap loader in final.build_detmap.
            manual[f"{FAM}:{key}"] = REAL[gid]; nreal += 1
            print(f"  REAL      {gid:14} x{seen[key]:<4} -> {REAL[gid]!r}")
        elif gid in FURNITURE_GIDS or gid in SPACER_GIDS:
            drops.add(key); nfurn += 1
            kind = "SPACER" if gid in SPACER_GIDS else "FURNITURE"
            print(f"  {kind:9} {gid:14} x{seen[key]:<4} -> dropped explicitly")
        else:
            print(f"  LEFT      {gid:14} x{seen[key]:<4} (needs a decision)")
    # SPACER_GIDS must be forced: unlike the others they usually carry a (bogus) detmap
    # entry, so they never show up as "unresolved" and the loop above never sees them.
    nforced = 0
    for slug in slugs:
        p = DATA / f"{slug}.surahs.json"
        if not p.exists():
            continue
        for surah in json.loads(p.read_text())["data"]:
            for glyphs in surah:
                for f, c in glyphs:
                    if f == "sp":
                        continue
                    key = f"{f}|{c}"
                    body = key[3:] if key.startswith("CL|") else key
                    if body.rsplit("|", 1)[0] in SPACER_GIDS and key not in drops:
                        drops.add(key); nforced += 1
                        print(f"  SPACER    {body.rsplit('|', 1)[0]:14} -> forced into droplist")

    (DATA / "manualmap.json").write_text(
        json.dumps(manual, ensure_ascii=False, indent=1, sort_keys=True))
    (DATA / "droplist.json").write_text(
        json.dumps(sorted(drops), ensure_ascii=False, indent=1))
    print(f"mapped {nreal} real, {nfurn} furniture; "
          f"manualmap={len(manual)} droplist={len(drops)}")

if __name__ == "__main__":
    main(sys.argv[1:] or ("khalaf", "khallad"))
