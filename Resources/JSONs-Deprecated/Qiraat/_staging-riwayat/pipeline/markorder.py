#!/usr/bin/env python3
"""Derive the canonical order of tashkeel WITHIN one letter from the verified texts.

The page stacks marks over a letter in whatever order the typesetter's layers happen to
emit, and the cluster keeps that order, so the same letter ships `دّٜ` here and `دّٜ` there.
Unicode has a canonical combining class for some of these but not for the Quranic signs,
so NFC will not settle it either.

The eight KFGQPC texts settle it empirically. Count every ordered pair of marks that share
a letter across all of them; where one direction accounts for essentially all of the
evidence, that direction is the convention:

    shadda   before fatha     125,440 : 0        dot U+065C before dagger alef   260 : 0
    fatha    before dagger     58,376 : 0        dagger alef before maddah     5,614 : 0
    shadda   before U+065C        370 : 0        small high seen before kasra     45 : 0
    kasra    before U+06ED        399 : 0

Pairs the texts genuinely write both ways are LEFT ALONE - fatha/U+06D6 is 19,960 : 190 and
fatha/hamza-above 22 : 2,669, and neither is a rule we get to invent. Threshold: at least
20 observations and at least 99.5% of them in one direction.

    python3 markorder.py        ->  data/markorder.json
"""
import json, pathlib, unicodedata, collections

BASE = pathlib.Path(__file__).resolve().parent
APP = pathlib.Path("/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS")
VER = APP / "Resources/JSONs-Deprecated/Qiraat"
MIN_N, MIN_RATIO = 20, 0.995


def verified_words():
    q = json.loads((APP / "Resources/JSONs-Deprecated/Quran.json").read_text())
    for s in q:
        for a in s["ayahs"]:
            yield from a["textArabic"].split()
    for f in sorted(VER.glob("Qiraah*.json")):
        for _, ays in json.loads(f.read_text()).items():
            for a in ays:
                yield from a["text"].split()


def main():
    pair = collections.Counter()
    for w in verified_words():
        cl = []
        for c in w:
            if unicodedata.combining(c) and cl:
                cl[-1] += c
            else:
                cl.append("")
        for marks in cl:
            for i in range(len(marks)):
                for j in range(i + 1, len(marks)):
                    pair[(marks[i], marks[j])] += 1
    rules, skipped = [], []
    for (a, b), n in pair.items():
        rev = pair.get((b, a), 0)
        if n + rev < MIN_N:
            continue
        if n / (n + rev) >= MIN_RATIO:
            rules.append([a, b, n, rev])
        elif n > rev:
            skipped.append((a, b, n, rev))
    rules.sort(key=lambda r: -r[2])
    (BASE / "data" / "markorder.json").write_text(
        json.dumps(rules, ensure_ascii=False, indent=1))
    print(f"{len(pair)} ordered pairs seen; {len(rules)} confident rules, "
          f"{len(skipped)} pairs left free")
    for a, b, n, rev in skipped:
        print(f"   free: U+{ord(a):04X} / U+{ord(b):04X}  {n} vs {rev}")


if __name__ == "__main__":
    main()
