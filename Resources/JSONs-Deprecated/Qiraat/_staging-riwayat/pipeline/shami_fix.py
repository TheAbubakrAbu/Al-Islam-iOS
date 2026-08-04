#!/usr/bin/env python3
"""Recover the 4 lost Shami ayah markers.

Four bracket pairs in hisham/ibndhakwan split across page boundaries, so pairing
failed and the volumes segment to 6222 instead of 6226. The unpaired bracket glyphs
themselves (HQPB2 gid 167/168) still flow through the token stream - each marks the
exact split point inside a merged double-ayah. Split there, renumber, rewrite."""
import json, sys, pathlib
BASE = pathlib.Path(__file__).resolve().parent
DATA = BASE / "data"

def is_bracket(f, c):
    k = f + "|" + c
    return "HQPB2#167" in k or "HQPB2#168" in k

def fix(slug, want):
    seg = json.load(open(DATA / f"{slug}.surahs.json"))
    total_before = sum(len(s) for s in seg["data"])
    splits = 0
    for sidx, surah in enumerate(seg["data"]):
        out = []
        for ayah in surah:
            hits = [i for i, (f, c) in enumerate(ayah) if is_bracket(f, c)]
            # split at bracket runs (a lost marker may leave 1-2 adjacent bracket
            # tokens; digits of the lost value may sit between - drop them with it)
            if not hits:
                out.append(ayah)
                continue
            i = hits[0]
            j = i
            while j < len(ayah) and (is_bracket(*ayah[j]) or ayah[j][0] == "sp"
                                     or "HQPB2#1" in ayah[j][0] + "|" + ayah[j][1][:0]):
                j += 1
            left, right = ayah[:i], ayah[j:]
            if len(left) >= 4 and len(right) >= 4:
                out.append(left)
                out.append(right)
                splits += 1
            else:
                out.append([t for k2, t in enumerate(ayah) if not is_bracket(*t)])
        seg["data"][sidx] = out
    seg["surahs"] = [len(s) for s in seg["data"]]
    total = sum(seg["surahs"])
    json.dump(seg, open(DATA / f"{slug}.surahs.json", "w"), ensure_ascii=False)
    print(f"{slug}: {total_before} → {total} ayahs (want {want}), splits={splits}")
    return total == want

if __name__ == "__main__":
    ok = fix("hisham", 6226) & fix("ibndhakwan", 6226)
    print("SHAMI OK" if ok else "SHAMI STILL OFF")
