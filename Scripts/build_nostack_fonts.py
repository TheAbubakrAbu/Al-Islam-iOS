#!/usr/bin/env python3
"""Build "NoStack" twins of the Quran faces whose OpenType rules stack a letter
above a following jeem/hah/khah (بحـ تجـ نخـ يحـ ثجـ لحـ مح), for a side-by-side
comparison of each face WITH and WITHOUT the stacking. The shipped fonts in
Resources/Fonts are never modified; the twins land BESIDE them in Resources/Fonts/ and
SHIP: since 2026-09-22 they are the faces the non-Quran Arabic screens read in
(`Settings.IslamArabicFace.fontName`, `hafsUthmaniNoStackFontName`,
`HijaziMarkStyle.noStackFontName`), while the Quran reader keeps the originals.
Rerun after any change to the source fonts (dotless patches, coverage patches).

WHAT IS NEUTRALISED (found by tracing every haa-context word of the Hafs text
through HarfBuzz, one lookup at a time, on 2026-09-22):

  Uthmani.ttf (KFGQPC HAFS Uthmanic Script)
    'calt' chain lookups 56, 57, 58, 59 are the ONLY rules that emit the
    raised/lowered stacking glyphs TJ014..TJ027:
      56 -> single-subst 122: initial ب ت ث ئ م ن ي before medial ج/ح/خ
            become the raised initials TJ014..TJ020
      57 -> single-subst 123: that medial ج/ح/خ becomes the lowered TJ021..TJ023
      58 -> single-subst 124: initial ل before medial ج/ح/خ becomes TJ024
      59 -> single-subst 125: that medial ج/ح/خ becomes TJ025..TJ027
    Deliberately KEPT (different ligatures, not "letter above haa"):
      60/61 the حمـ tucked-meem form (TJ028..TJ031), 62..67 the بر / سر / بن /
      لب forms, 45..54 the final-yeh swashes, 21..26 kaf and lam-alef forms,
      7/71 the ".zz09" dagger-alef variants (side-by-side drawings).
    Note the font only stacks INITIAL letters: medial ones (سبح, فتح, أنجيناكم)
    always sit beside the haa, so a "-NoStack" twin changes nothing there.

  Hijazi.ttf, Hijazi3.ttf, Hijazi4.ttf (Al-Islam Hijazi; byte-identical GSUB)
    'calt' chain lookup 8 (-> single-substs 9 and 10) turns initial
    ب ت ث ن ي ئ ى ل into the *initonjhk glyphs and the following medial/final
    ج/ح/خ into the *belowkrl glyphs. Lookup 6 (the raised "tooth after tooth"
    .high forms) is unrelated and kept. Its LookupFlag does not ignore marks,
    so the rule only ever fires on unvowelled text (نحن stacks, نَحۡنُ does not).

  Indopak.ttf (Al_Mushaf): the stacking is baked into the drawing of the
    medial/final haa glyphs (uFEA4 etc., the same uFE91 beh is used before
    seen and before haa) and no GSUB rule is involved, so no twin is possible.
  Kufi.ttf (Noto Kufi Arabic): never stacks, no twin needed.

HOW: the chain lookups' indices are removed from every FeatureRecord's
LookupListIndex list (the lookups, their single-substs and the TJ/onjhk
glyphs stay in the file, so nothing else can break), the name table gets a
" NoStack" / "-NoStack" suffix on IDs 1, 3, 4, 6 and 16 (17 is the style name
"Regular" and is left alone; neither face carries 16/17 anyway) so the twin
installs beside the original, and Uthmani's now-invalid DSIG is dropped.

Idempotent: always rebuilds from the shipped source fonts, overwriting.
Run:     python3 Scripts/build_nostack_fonts.py
Verify:  python3 Scripts/build_nostack_fonts.py --verify
         (needs uharfbuzz; shapes every distinct word of
         Resources/JSONs-Deprecated/Quran.json, vowelled and bare, with both
         fonts and proves the only differences are haa-context words whose
         twin output carries no stacking glyph)
"""

import json
import re
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
FONTS_DIR = ROOT / "Resources" / "Fonts"
OUT_DIR = ROOT / "Resources" / "Fonts"
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"

# face -> (chain lookups to neutralise, regex matching its stacking glyph names,
#          expected outputs of the sub-lookups those chains call: a guard against
#          a rebuilt font whose lookup indices shifted)
FACES = {
    "Uthmani": {
        "lookups": [56, 57, 58, 59],
        "stack_glyph": r"^TJ0(1[4-9]|2[0-7])$",
        "expect_outputs": {"TJ014", "TJ017", "TJ020", "TJ021", "TJ022", "TJ023",
                           "TJ024", "TJ025", "TJ026", "TJ027"},
    },
    "Hijazi": {
        "lookups": [8],
        "stack_glyph": r"(initonjhk|belowkrl)$",
        "expect_outputs": {"bainitonjhk", "laminitonjhk", "nooninitonjhk",
                           "hhamedibelowkrl", "jeemfinabelowkrl", "khafinabelowkrl"},
    },
}
FACES["Hijazi3"] = FACES["Hijazi"]
FACES["Hijazi4"] = FACES["Hijazi"]

SUFFIX_IDS = {1: " NoStack", 3: " NoStack", 4: " NoStack", 6: "-NoStack", 16: " NoStack"}


def chain_outputs(font, lookup_index):
    """Glyph names emitted by the single-substs that a chain lookup calls."""
    lookups = font["GSUB"].table.LookupList.Lookup
    outs = set()
    for st in lookups[lookup_index].SubTable:
        if st.LookupType == 7:
            st = st.ExtSubTable
        assert st.LookupType == 6, f"lookup {lookup_index} is type {st.LookupType}, not a chain"
        records = list(getattr(st, "SubstLookupRecord", None) or [])
        for rs in getattr(st, "ChainSubRuleSet", None) or []:
            for r in rs.ChainSubRule:
                records += r.SubstLookupRecord
        for cs in getattr(st, "ChainSubClassSet", None) or []:
            if cs is not None:
                for r in cs.ChainSubClassRule:
                    records += r.SubstLookupRecord
        for rec in records:
            for sub in lookups[rec.LookupListIndex].SubTable:
                if sub.LookupType == 1:
                    outs.update(sub.mapping.values())
    return outs


def build(name, spec):
    src = FONTS_DIR / f"{name}.ttf"
    dst = OUT_DIR / f"{name}-NoStack.ttf"
    font = TTFont(src)
    gsub = font["GSUB"].table

    # guard: the indices must still point at the stacking chains
    outs = set()
    for li in spec["lookups"]:
        outs |= chain_outputs(font, li)
    missing = spec["expect_outputs"] - outs
    if missing:
        sys.exit(f"{name}: lookups {spec['lookups']} no longer emit {sorted(missing)}; "
                 "the font changed, re-trace before rebuilding")

    removed = []
    for fr in gsub.FeatureList.FeatureRecord:
        before = list(fr.Feature.LookupListIndex)
        after = [i for i in before if i not in spec["lookups"]]
        if after != before:
            removed.append((fr.FeatureTag, sorted(set(before) - set(after))))
            fr.Feature.LookupListIndex = after
            fr.Feature.LookupCount = len(after)
    if not removed:
        sys.exit(f"{name}: none of {spec['lookups']} is referenced by a feature")

    for rec in font["name"].names:
        suffix = SUFFIX_IDS.get(rec.nameID)
        if suffix is None:
            continue
        value = rec.toUnicode()
        if not value.endswith(suffix):
            rec.string = value + suffix
    if "DSIG" in font:
        del font["DSIG"]

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    font.save(dst)
    ps = next(r.toUnicode() for r in font["name"].names if r.nameID == 6)
    print(f"{name}: removed {removed} -> {dst.relative_to(ROOT)}  (PostScript name {ps})")
    return dst


MARKS = ({chr(c) for c in range(0x610, 0x061B)} | {chr(c) for c in range(0x64B, 0x660)}
         | {chr(c) for c in range(0x6D6, 0x6EE)} | {"ٰ", "ۡ"})
HAA = set("جحخ")
NON_JOINERS = set("اأإآءدذرزوؤةٱى")


def haa_context(word):
    """True when a joining letter directly precedes (marks aside) a ج/ح/خ."""
    letters = [c for c in word if c not in MARKS]
    return any(letters[i] in HAA and letters[i - 1] not in NON_JOINERS
               for i in range(1, len(letters)))


def verify(name, spec, dst):
    import uharfbuzz as hb

    def shaper(path):
        face = hb.Face(hb.Blob.from_file_path(str(path)))
        hbfont = hb.Font(face)
        names = TTFont(path, lazy=True).getGlyphOrder()

        def shape(text):
            buf = hb.Buffer()
            buf.add_str(text)
            buf.guess_segment_properties()
            hb.shape(hbfont, buf)
            return [names[g.codepoint] for g in buf.glyph_infos]
        return shape

    orig, twin = shaper(FONTS_DIR / f"{name}.ttf"), shaper(dst)
    stack = re.compile(spec["stack_glyph"])
    words = set()
    for surah in json.load(open(QURAN_JSON)):
        for ayah in surah["ayahs"]:
            words.update(ayah["textArabic"].split())
    bare = {"".join(c for c in w if c not in MARKS) for w in words}
    for label, sample in (("vowelled", sorted(words)), ("bare", sorted(bare))):
        differ = ctx = stacked_before = bad_ctx = bad_left = 0
        examples = []
        for w in sample:
            a, b = orig(w), twin(w)
            if any(stack.search(g) for g in a):
                stacked_before += 1
            if a == b:
                continue
            differ += 1
            if haa_context(w):
                ctx += 1
            else:
                bad_ctx += 1
                examples.append(w)
            if any(stack.search(g) for g in b):
                bad_left += 1
                examples.append(w)
        print(f"{name} {label}: {len(sample)} distinct words, {stacked_before} stacked in the "
              f"original, {differ} shape differently in the twin ({ctx} of them haa-context), "
              f"{bad_ctx} differ outside a haa context, {bad_left} still carry a stacking glyph"
              + (f"  PROBLEMS: {examples[:8]}" if examples else "  OK"))


if __name__ == "__main__":
    do_verify = "--verify" in sys.argv
    for face_name, face_spec in FACES.items():
        out = build(face_name, face_spec)
        if do_verify:
            verify(face_name, face_spec, out)
