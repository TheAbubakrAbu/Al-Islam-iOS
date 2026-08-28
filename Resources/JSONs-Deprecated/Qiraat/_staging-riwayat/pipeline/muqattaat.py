#!/usr/bin/env python3
"""Rebuild data/muqattaat.json - the opening letters of the 29 fawatih, per VOLUME.

Why a table at all: the fawatih are set with ligature glyphs and stacked maddahs that the
learned map reads only approximately, so the emitted word needs a canonical spelling.

Why per volume and not per family: the marks on them ARE the reading. The old code copied
the family bridge's spelling wholesale, which handed each volume the BRIDGE's reading.
Hisham was given Shubah's imalah dot on حم, although his own print sets `حَمٓ` plain and
Ibn Dhakwan's sets it dotted - that pair really does differ there, and the copy erased it.
Ruways was given ad-Duri's dots although his print has none, and it hid a genuine
Ruways/Rawh split at 36:1, where Rawh's ي is red with a dot under it and Ruways' is black.
The Abu Ja'far pair got Qaloon's `أَلَٓمِّٓ`, whose shadda is precisely the idgham that
Abu Ja'far replaces with sakt.

So: keep each volume's own dots, and canonicalise nothing but the spelling.

  ا ر ه ي ط ح  never carry a maddah;  ل م ص ك س ع ق ن  always do.
  Those same six are the only letters that can carry the imalah dot, which is why a dot
  the geometry attached to a neighbour (Ishaq and Idris set the dot of 26:1 between the
  ط and the س) can be put back without a hand-written exception.
That rule reproduces all seven shipped texts' fawatih exactly, so it is theirs, not ours.

  python3 muqattaat.py <slug>...        (all 19 if none given)
"""
import json, sys, pathlib, unicodedata

BASE = pathlib.Path(__file__).resolve().parent
DATA = BASE / "data"
sys.path.insert(0, str(BASE))
import final, extract

DOT = "ٜ"          # the imalah/taqlil dot the volumes draw under a letter
MADDAH = "ٓ"
NO_MADDAH = set("اٱرهيطح")
DOTTABLE = set("رهيطح")
PAUSE = set("ۖۗۘۙۚۛۜ")

# The letters each surah opens with, in rasm. Two words only in 42, and only for the
# volumes that count `حم عسق` as one ayah; the Kufi count puts عسق in ayah 2.
CANON = {2: ["الم"], 3: ["الم"], 7: ["المص"], 10: ["الر"], 11: ["الر"], 12: ["الر"],
         13: ["المر"], 14: ["الر"], 15: ["الر"], 19: ["كهيعص"], 20: ["طه"],
         26: ["طسم"], 27: ["طس"], 28: ["طسم"], 29: ["الم"], 30: ["الم"], 31: ["الم"],
         32: ["الم"], 36: ["يس"], 38: ["ص"], 40: ["حم"], 41: ["حم"], 42: ["حم", "عسق"],
         43: ["حم"], 44: ["حم"], 45: ["حم"], 46: ["حم"], 50: ["ق"], 68: ["ن"]}


def _skeleton(w):
    return "".join("ا" if c == "ٱ" else c
                   for c in w if not unicodedata.combining(c) and c not in PAUSE)


def canonical(letters, dotted, tail=""):
    """Spell one fawatih word: letter + its dot (if the print drew one) + its maddah."""
    out = []
    for i, ch in enumerate(letters):
        out.append(ch)
        if i in dotted:
            out.append(DOT)
        if ch not in NO_MADDAH:
            out.append(MADDAH)
    return "".join(out) + tail


def read_volume(slug):
    """Render each fawatih ayah from this volume's own page and read its dots off it."""
    fam = final.FAMILY[slug]
    detmap = final.build_detmap(fam)
    cp = DATA / f"ctxdet-{fam}.json"
    ctx = json.loads(cp.read_text()) if cp.exists() else {}
    seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
    out = {}
    for sid, words in CANON.items():
        for aid in (1, 2):
            if aid > len(seg["data"][sid - 1]):
                continue
            glyphs = seg["data"][sid - 1][aid - 1]
            t = final.render_det(glyphs, detmap, None, family=fam, ctx=ctx, slug=slug)
            if aid == 1:
                t = extract.strip_header_and_basmalah(t, keep_basmalah=False)
            t = t.replace("✗", "").strip()
            got, rest = [], t.split()
            for want in words:
                if not rest or _skeleton(rest[0]) != want:
                    break
                got.append(rest.pop(0))
            if not got:
                continue
            spelled = []
            for want, w in zip(words, got):
                # which letters did the print dot? A dot that landed on a letter that
                # never takes one belongs to the word's dottable letter instead.
                dotted, letters = set(), []
                for ch in w:
                    if ch in (DOT, "۪"):
                        if letters:
                            dotted.add(len(letters) - 1)
                    elif not unicodedata.combining(ch) and ch not in PAUSE:
                        letters.append("ا" if ch == "ٱ" else ch)
                ok = {i for i in dotted if want[i] in DOTTABLE}
                for i in dotted - ok:
                    near = sorted((j for j, c in enumerate(want) if c in DOTTABLE),
                                  key=lambda j: abs(j - i))
                    if near:
                        ok.add(near[0])
                tail = "".join(c for c in w if c in PAUSE)
                spelled.append(canonical(want, ok, tail))
            out[f"{sid}:{aid}"] = " ".join(spelled)
            words = words[len(got):]
            if not words:
                break   # the fawatih sit in ayah 1, except the Kufi count's 42:2
    return out


def main(slugs):
    path = DATA / "muqattaat.json"
    tab = json.loads(path.read_text()) if path.exists() else {}
    for slug in slugs:
        if not (DATA / f"{slug}.surahs.json").exists():
            print(f"{slug}: not segmented here, skipped")
            continue
        tab[slug] = read_volume(slug)
        print(slug, json.dumps(tab[slug], ensure_ascii=False))
    path.write_text(json.dumps(tab, ensure_ascii=False, indent=1, sort_keys=True))
    print(f"wrote {path} ({len(tab)} volumes)")


if __name__ == "__main__":
    main(sys.argv[1:] or sorted(final.FAMILY))
