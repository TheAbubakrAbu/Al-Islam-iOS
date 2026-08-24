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
import json, pathlib, collections, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import final, extract

DATA = pathlib.Path(__file__).resolve().parent / "data"
FAM = "kufi"

# gid -> emission for real marks that were being dropped
REAL = {
    "HQPB4#7":   "ٓ",        # maddah (U+0653); the muqatta'at's second maddah
    "HQPB1#149": "ش",         # letter sheen, dropped from ٱنشَقَّتۡ (84:1, both volumes)
    "HQPB2#13":  "ق",         # letter qaf, same word
    "HQPB5#113": "َ",        # fatha: gives Hamzah's سَكۡرىٰ (22:2) and يَكُن (18:43)
    "HQPB4#38":  "ِۭ",      # kasra + small low meem (U+0650 U+06ED): خَوۡفِۭ (106:4),
                              # مُّمَدَّدَةِۭ (104:9). Drawn as two layer copies; the
                              # doubled-mark collapse downstream folds them back to one.
}

# gid prefixes that are page furniture and must render as nothing
FURNITURE_GIDS = {
    "Hamd2#198", "Hamd2#199", "Hamd2#200",   # decorative basmalah, 1 per surah
    "Hamd2#100", "Hamd2#105",                # its لأ / لإ ligature pieces
    "Hamd2#111", "Hamd2#174", "Hamd2#193", "Hamd2#169",
    "HQPB2#193", "HQPB2#194",                # surah-banner rosette
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
        body = key[3:] if key.startswith("CL|") else key
        gid = body.rsplit("|", 1)[0]
        if gid in REAL:
            manual[key] = REAL[gid]; nreal += 1
            print(f"  REAL      {gid:14} x{seen[key]:<4} -> {REAL[gid]!r}")
        elif gid in FURNITURE_GIDS:
            drops.add(key); nfurn += 1
            print(f"  FURNITURE {gid:14} x{seen[key]:<4} -> dropped explicitly")
        else:
            print(f"  LEFT      {gid:14} x{seen[key]:<4} (needs a decision)")
    (DATA / "manualmap.json").write_text(
        json.dumps(manual, ensure_ascii=False, indent=1, sort_keys=True))
    (DATA / "droplist.json").write_text(
        json.dumps(sorted(drops), ensure_ascii=False, indent=1))
    print(f"mapped {nreal} real, {nfurn} furniture; "
          f"manualmap={len(manual)} droplist={len(drops)}")

if __name__ == "__main__":
    main(sys.argv[1:] or ("khalaf", "khallad"))
