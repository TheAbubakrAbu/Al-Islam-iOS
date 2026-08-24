"""Map the Khallad volume's imalah dots.

The Khalaf volume draws its imalah dot as HQPB5 gid 20 (~3 layered strokes per dot),
which the pipeline knows. The Khallad volume draws the SAME mark in a supplementary
font, Hamd2, as a single filled dot below the baseline - gids 166/170/171/172. The
pipeline has no Hamd2 mapping at all, so every one of those ~1,737 dots was resolved
to nothing and silently dropped by emit's `t.replace("✗","")`.

That is what made Khallad look like a volume that does not mark imalah (152 emitted
marks against Khalaf's 1,345). It is an extraction gap, not an edition difference.

Hamd2 gids 198/199/200 are the decorative basmalah calligraphy at ~112 occurrences
each (one per surah header) and stay dropped.
"""
import json, pathlib, sys, collections
sys.path.insert(0, ".")
import final, extract

DATA = pathlib.Path(__file__).resolve().parent / "data"
IMALAH = "ٜ"
DOT_GIDS = {166, 170, 171, 172}

def main():
    fam = "kufi"
    detmap = final.build_detmap(fam)
    ctx = json.loads((DATA / f"ctxdet-{fam}.json").read_text())
    # discover the exact key strings (their ToUnicode char is U+FFFD and cannot be typed)
    found = collections.Counter()
    for slug in ("khalaf", "khallad"):
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        missing = collections.Counter()
        for surah in seg["data"]:
            for glyphs in surah:
                final.render_det(glyphs, detmap, missing, fam, ctx)
        for key, n in missing.items():
            body = key[3:] if key.startswith("CL|") else key
            head = body.rsplit("|", 1)[0]
            if not head.startswith("Hamd2#"):
                continue
            gid = head.split("#", 1)[1]
            if gid.isdigit() and int(gid) in DOT_GIDS:
                found[key] += n
    manual = json.loads((DATA / "manualmap.json").read_text())
    for key, n in found.items():
        manual[key] = IMALAH
        print(f"  {key!r} x{n} -> U+065C imalah")
    (DATA / "manualmap.json").write_text(
        json.dumps(manual, ensure_ascii=False, indent=1, sort_keys=True))
    print(f"mapped {len(found)} Hamd2 dot keys; manualmap now {len(manual)} entries")

if __name__ == "__main__":
    main()
