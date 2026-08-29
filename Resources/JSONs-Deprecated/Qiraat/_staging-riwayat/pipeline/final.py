#!/usr/bin/env python3
"""Deterministic rendering + verification loop. No LM, no beams - every character
must come from (a) a high-purity glyph emission, (b) a deterministic rule, or be a
visible ✗ that fails validation.

  rules      : verify the wasla rule + mark-order stats against app texts
  detmap     : build data/detmap-<family>.json from glyphcounts-<family>.json
  roundtrip <bridge...> : render bridge volumes deterministically, diff vs app texts,
                          print a CLASS HISTOGRAM of every difference
"""
import json, sys, os, math, collections, pathlib, re, unicodedata, difflib

BASE = pathlib.Path(__file__).resolve().parent
DATA = BASE / "data"
APP = pathlib.Path("/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS")
sys.path.insert(0, str(BASE))
from extract import overlay, BRIDGES
from hybrid import FAMILY, template_texts

def app_texts_all():
    out = []
    from decode import hafs_text
    for sid, ayahs in hafs_text().items():
        out += [t for _, t in ayahs]
    for name in ["QiraahShubah", "QiraahWarsh", "QiraahQaloon", "QiraahDuri",
                 "QiraahSusi", "QiraahBuzzi", "QiraahQunbul"]:
        d = json.loads((APP / f"Resources/JSONs-Deprecated/Qiraat/{name}.json").read_text())
        for v in d.values():
            out += [a["text"] for a in v]
    return out

# ---------------------------------------------------------------- normalization

def normalize_marks(text):
    """Canonical combining-mark order per base: sort each base's mark run by
    (combining class, codepoint). Deterministic; applied to BOTH app text (during
    learning/diffing) and our renders, so stack-order noise can never be a diff."""
    out = []
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        out.append(ch)
        j = i + 1
        marks = []
        while j < n and unicodedata.combining(text[j]):
            marks.append(text[j]); j += 1
        if marks:
            marks.sort(key=lambda c: (unicodedata.combining(c), ord(c)))
            out += marks
        i = j
    return "".join(out)

WASLA = "ٱ"

def apply_wasla_rule(text):
    """Word-initial bare alef → ٱ (the app's Uthmani convention has no word-initial
    plain ا). Word-internal ٱ after وَ/فَ/بِ/لِ/كَ prefixes is already word-initial at
    the ORTHOGRAPHIC word level - the rule is applied per whitespace token to its
    first LETTER only."""
    words = text.split(" ")
    out = []
    for w in words:
        if w.startswith("ا"):
            w = WASLA + w[1:]
        out.append(w)
    return " ".join(out)

def verify_rules():
    texts = app_texts_all()
    initial_plain = initial_wasla = internal_wasla = internal_plain = 0
    for t in texts:
        for w in t.split():
            if not w: continue
            if w[0] == "ا": initial_plain += 1
            if w[0] == WASLA: initial_wasla += 1
            internal_wasla += w[1:].count(WASLA)
            internal_plain += w[1:].count("ا")
    print(f"word-initial plain ا: {initial_plain}   word-initial ٱ: {initial_wasla}")
    print(f"internal ٱ: {internal_wasla}   internal ا: {internal_plain}")
    # mark-order check: how often does app text deviate from our canonical order?
    dev = tot = 0
    for t in texts[:20000]:
        nt = normalize_marks(t)
        tot += 1
        if nt != t: dev += 1
    print(f"ayahs whose app text ≠ canonical mark order: {dev}/{tot}")

# Zone-corrected mark emissions, from `zonectx.py --write`.
#
# This print draws a doubled letter as [kasra stroke][shadda], in that stream order, and
# Unicode writes the shadda first. Instead of reordering, the EM learner simply SWAPPED the
# two emissions: the below-baseline kasra glyph (HQPB4#176 and friends) learned to emit a
# shadda, and the above-baseline shadda ladder (HQPB4#65/67/68/69/70/71/73..77/79..82, one
# outline at fifteen stack heights) learned to emit a kasra.
#
# That produces the right string for the PAIR and nonsense for every ladder glyph appearing
# without its kasra partner, which is where `جَبۡرَِيل` for `جَبۡرَئِيل` came from. Here each
# glyph emits the mark its ink actually is, and `reorder_shadda` below puts the pair back
# into Unicode order, so an unpaired ladder glyph now yields a bare shadda instead of a
# spurious kasra.
#
# BOTH ladders have to be listed in full, and the kasra one was short by six entries.
# HQPB4 gids 165-176 are one kasra outline at twelve stack heights (the higher the letter
# it nests under, the higher the slant sits); only 165/169/170/173/174/176 were pinned,
# leaving 166/167/168/171/172/175 free for the context pass to mislearn - which it did,
# giving 166 twenty-seven shadda rules and 175 twenty-nine. When such a glyph renders a
# shadda next to its partner ladder glyph, which ZONEFLIP correctly pins to a shadda,
# `collapse_doubled_marks` folds the two into one and the KASRA IS GONE: `رَبِّ` shipped
# as `رَبّ`, 1,076 words of it in Ruways alone. Completing the ladder is worth
# +6.9 points on duriabiamr and +5.1 on susi, and costs kufi nothing (90.80 -> 90.84).
# gids 66, 72 and 78 are absent from every volume, so the shadda ladder's gaps are real.
ZONEFLIP = json.loads((DATA / "zoneflip.json").read_text()) \
    if (DATA / "zoneflip.json").exists() else {}

# The MSH farsh layer draws ONE dot glyph for two different jobs, so its emission cannot
# be a constant and cannot live in `manualmap.json` (both jobs share a cluster key).
#
#   * on the seven ishmam words the dot stands IN the vowel slot of a letter that carries
#     no other vowel - `قِيلَ` is printed as a bare qaf plus the dot - so it has to come
#     out as the kasra it replaced, or the word ships unvocalised (which is exactly the
#     defect in QiraahHisham, QiraahAbuHarith and QiraahDuriKisai);
#   * on the `ءَأَ` interrogatives (`ءَأَنتُمۡ`, `ءَأَسۡلَمۡتُمۡ`, `ءَأَنذَرۡتَهُم`) it annotates
#     the softened second hamza, whose alef is already written in full, so it has to come
#     out as nothing. Inventing a vowel there would be fabrication.
#
# The base letter separates the two cleanly and without a word list: ishmam only ever caps
# ق س غ ح ج. Al-Kisai draws the dot at gid 39 and Ibn Amir at gid 40 (the same font, but
# each volume embeds its own subset), and both obey this rule.
# ---------------------------------------------------------------- pinned ctx rules
# Neighbour-conditioned emissions the bridge learner cannot reach, read off the printed
# page and pinned by hand. `ctxpass` REWRITES data/ctxdet-<fam>.json wholesale, so a rule
# that must survive a relearn cannot live there; these are applied last, after ctx,
# ZONEFLIP and the blank-a-letter guard, and they win over all of them.
#
# The lam-alef-hamza ligature. HQPB2#95 is one glyph drawing `لإ`, and which vowels sit on
# its two letters is carried entirely by the mark glyph that follows it:
#   #53  sukoon + kasra  -> `ٱلۡإِنسَٰنُ`   (the article; the lam already arrives from the
#                                          wasla alef's own `اۡ` -> `ٱلۡ` rule)
#   #66  fatha  + kasra  -> `لَإِلَى` 3:158, `لَإِبۡرَٰهِيمَ` 37:83, `لَإِحۡدَى` 74:35
#   #68  kasra  + kasra  -> `لِإِخۡوَٰنِهِمۡ` 3:156/3:168/33:18, `لِإِبۡرَٰهِيمَ` 22:26,
#                           `وَلِإِخۡوَٰنِنَا` 59:10, `لِإِخۡوَٰنِهِمُ` 59:11, `لِإِيلَٰفِ` 106:1
#   #74  shadda + kasra  -> `لِّإِثۡمٖ` 5:3 (the tanween's idgham into the lam)
# With no alef in the word nothing supplied the lam and eight volumes shipped `إِلَى` for
# `لَإِلَى`. #68 occurs 7-8 times per volume and follows #95 every single time; #66 also
# serves the OTHER ligature glyph (#96, `مَلَإِ`), so its pin is scoped to #95.
def _lam_alef_hamza(*codings):
    """The `\u0644\u0625` ligature's pins for one volume's coding of the two vowel glyphs.

    Every volume embeds its own font SUBSET, so the same three outlines arrive under
    different gids: the Kufi books and Duri Abu Amr code them #53/#66/#68, the Yaqub and
    Abu Ja'far books #48/#61/#63. The article's own rung (#53/#48, sukoon + kasra) needs no
    pin - there the wasla alef's `\u0627\u06e1` -> `\u0671\u0644\u06e1` rule already supplies the lam.
    """
    out = {"CL|HQPB2#95|}": {}, "CL|HQPB5#74|b": {}}
    for kasra_key, fatha_key in codings:
        out["CL|HQPB2#95|}"][f"n:{kasra_key}"] = "\u0644"
        out["CL|HQPB2#95|}"][f"n:{fatha_key}"] = "\u0644"
        out["CL|HQPB5#74|b"][f"p:{kasra_key}"] = ""
        out[kasra_key] = {"b:CL|HQPB2#95|}|CL|HQPB5#74|b": "\u0650\u0651\u0625\u0650",
                          "p:CL|HQPB2#95|}": "\u0650\u0625\u0650"}
        out[fatha_key] = {"p:CL|HQPB2#95|}": "\u064e\u0625\u0650"}
    return out


CTXPIN = {
    "kufi": dict(_lam_alef_hamza(("CL|HQPB5#68|\\", "CL|HQPB5#66|Z")), **{
        # `\u064a\u064e\u0670\u0628\u064f\u0646\u064e\u064a\u0650\u0651` (31:13, 31:16, 31:17). The farsh layer draws its magenta shadda and
        # kasra, and this is the kasra: Khallad prints the identical page and reads the
        # word with a kasra, and the three volumes that carry this glyph were the only ones
        # reading a fatha. Its sister glyph in the body layer, HQPB4#69, is the shadda.
        "CL|MSH-Quraan1#73|\u03b3": {"*": "\u0650"},
        # Rendered alone HQPB5#134 is a FATHA, above the baseline, nowhere near an alef.
        # The learner read it as the alef of `\u0644\u064e\u0627` because the lam-alef ligature beside it
        # prints that alef without a glyph of its own; now that the ligature carries it
        # (see _weld_ligature_alef) the mark can say what it is, and `\u0643\u064e\u0641\u064e\u0631\u064f\u0648\u0627\u06e1` stops
        # coming out `\u0643\u0627\u0641\u064e\u0631\u064f\u0648\u0627\u06e1` in the two Khalaf al-Ashir volumes. It costs shubah two
        # ayahs and buys eighteen words back; a flat pin on #133, its shadda twin, costs
        # 82 and is left to its context rules.
        "CL|HQPB5#134|\u0178": {"*": "\u064e"},
        # HQPB5#129 is the same mark in the Khallad, Abu al-Harith and Duri al-Kisai
        # subsets: 11 of its 15 uses are `\u0644\u064e\u0627` words where the ligature draws the alef,
        # and the other four shipped `\u0642\u064e\u0628\u06e1\u0644\u0627`, `\u0641\u064e\u0631\u0650\u064a\u0636\u0627\u0629\u0657` and `\u0671\u0644\u0632\u0651\u064e\u0643\u0627\u0648\u0670\u0629\u064e`.
        "CL|HQPB5#129|\u0178": {"*": "\u064e"},
        # ...except in `\u0623\u064e\u0643\u0651\u064e\u0670\u0644\u064f\u0648\u0646\u064e` (5:42) and `\u0671\u0644\u0636\u0651\u064e\u0623\u06e1\u0646\u0650` (6:143), where #133's context rules
        # read the shadda as that same phantom alef. Both are single sites.
        "CL|HQPB5#133|\uf09e": {
            "b:CL|HQPB2#21|2|CL|HQPB2#155|\u2248": "\u0651",
            "b:CL|HQPB1#178|\xd2|CL|HQPB1#10|'": "\u0651",
        },
        # Khalaf and Khallad draw the same ligature from their own Hamd2 subset, where it
        # arrives as one cluster with no separate mark glyph at all: `لِإِيلَٰفِ` 106:1.
        "CL|Hamd2#100|\ufffd": {"*": "\u0644\u0650\u0625\u0650"},
        # `\u0671\u0644\u06e1\u0623\u064e\u0631\u06e1\u0636\u064e` 2:22, 2:25, 2:27. The article's lam is one of Hamzah's sakt
        # places, so Khallad's book draws `\u0671\u0644\u06e1\u0623` in the sakt colour - and that coloured
        # run sets the wasl alef as a plain HQPB1#6 instead of the HQPB5#7 that carries
        # the raised lam in the other 7,587 sites. Emitting the lam's sukoon here puts the
        # word back on the path apply_wasla_rule already knows.
        "CL|HQPB2#93|{": {"b:CL|HQPB1#6|#|CL|HQPB5#46|F": "\u06e1\u0623"},
        # HQPB5#3 is a dagger alef in 19 of its 45 uses and nothing at all in the rest.
        # A dagger alef cannot precede a sukoon and cannot sit between a fatha and a kaf,
        # and Khalaf's own page prints `\u0623\u064e\u0643\u06e1\u0628\u064e\u0631\u064f` (2:217) with one plain fatha; the two
        # neighbours below separate the 27 bad uses from the good ones with no overlap.
        # `\u0621\u064e\u0623\u064e\u0670\u0645\u0646\u062a\u064f\u0645` and `\u0641\u064e\u0671\u0644\u0632\u0651\u064e\u0670\u062c\u0650\u0631\u064e\u0670\u0653\u062a` keep theirs.
        "CL|HQPB5#3| ": {"p:CL|HQPB4#215|\xf6": "", "n:CL|HQPB2#17|.": ""},
        # `\u064a\u064e\u0670\u0635\u064e\u0670\u062d\u0650\u0628\u064e\u064a\u0650` 12:39 and 12:41. HQPB3#28 draws `\u0649\u0670` in 984 of its 1,000 uses,
        # every one of them at a word's end before a pronoun suffix; here it is mid-word
        # before a haa, and the page prints a bare dagger alef over the sad.
        "CL|HQPB3#28|9": {"b:CL|HQPB5#100|||CL|HQPB1#85|s": "\u0670"},
    }),
    # The iqlab ladder: HQPB4 41-52 is ONE fatha-plus-small-meem outline drawn at ten
    # stack heights (see the note in ctxpass). Every rung reads `\u064e\u06ed` in the Kufi, Basri
    # and Makki maps; in the Madani one three rungs came out of the learner as `\u0627\u064e` /
    # `\u0627\u064e\u06ed`, which is the exact failure ctxpass already documents for #52 - and it
    # shipped `\u0642\u064e\u0648\u06e1\u0645\u0627\u064e\u0627` for `\u0642\u064e\u0648\u06e1\u0645\u064e\u06e2\u0627` in 40 words of Ibn Wardan and Ibn Jammaz.
    # The word's own alef is a separate glyph (HQPB1#7) in all 40, so the rung carries
    # the marks only.
    "madani": dict(_lam_alef_hamza(("CL|HQPB5#63|\\", "CL|HQPB5#61|Z")),
        **{k: {"*": "\u064e\u06e2"} for k in (
        "CL|HQPB4#41|G", "CL|HQPB4#43|I", "CL|HQPB4#44|J", "CL|HQPB4#45|K",
        "CL|HQPB4#46|L", "CL|HQPB4#47|M", "CL|HQPB4#48|N", "CL|HQPB4#49|O",
        "CL|HQPB4#50|P", "CL|HQPB4#52|R")},
        # ...and the alef that follows a rung is an alef. While the rungs read `اَ` the
        # learner had to make this glyph carry the missing meem to balance the word, so
        # five of its 412 rules emit `ۢ` or nothing after a rung; with the rungs fixed
        # those rules delete the accusative alef of `أَبَداَۢ` and `شَهِيداَۢ`.
        **{f"CL|HQPB1#6|#": {f"p:CL|HQPB4#{g}|{c}": "\u0627" for g, c in (
            (41, "G"), (43, "I"), (44, "J"), (45, "K"), (46, "L"), (47, "M"),
            (48, "N"), (49, "O"), (50, "P"), (52, "R"))}}),
    # The Yaqub volumes code the ligature's vowels like the Abu Ja'far ones; Duri Abu Amr,
    # in the same family, codes them like the Kufi books.
    "basri": dict(_lam_alef_hamza(("CL|HQPB5#63|\\", "CL|HQPB5#61|Z"),
                                  ("CL|HQPB5#68|\\", "CL|HQPB5#66|Z")),
        # `\u0648\u064e\u0644\u064e\u0623\u0653\u0645\u064f\u0631\u064e\u0646\u0651\u064e\u0647\u064f\u0645\u06e1` 4:118. HQPB2#91 is the Basri books' `\u0644\u0623` ligature, and
        # every one of its 544 uses takes its lam from a context rule; this pair of
        # neighbours (the waw's fatha, then the maddah) is the only one the learner never
        # saw with a lam, so the two occurrences in each Yaqub volume lost it.
        **{"CL|HQPB2#91|\u03c8": {"b:CL|HQPB5#88|u|CL|HQPB5#56|U": "\u0644\u064e\u0623"}},
        # HQPB1#85 is a haa everywhere; one of its 152 context rules turns it into an ayn,
        # fires at exactly one site, and turns `\u0671\u0644\u0633\u0651\u064e\u0670\u0653\u0626\u0650\u062d\u0648\u0646\u064e` (9:113) into a word that
        # does not exist.
        **{"CL|HQPB1#85|s": {"b:CL|HQPB4#174|\xcd|CL|HQPB4#192|\xdf": "\u062d"}}),
}


# HQPB2#89 and #90 are the lam-alef LIGATURE: one outline drawing `\u0644\u0627`, the same way the
# jalalah's two lams and the `\u0644\u0625` ligature are drawn as one shape. The learner reads them
# `\u0644\u064e` because in most words the alef is ALSO printed as its own glyph and the pair comes
# out right; where it is not, the alef was simply lost - `\u0641\u064e\u0644\u064e` for `\u0641\u064e\u0644\u064e\u0627` (2:172),
# `\u0628\u064e\u0644\u064e\u0653\u0621\u065e` for `\u0628\u064e\u0644\u064e\u0627\u0653\u0621\u065e` (2:48), `\u062f\u064e\u0644\u0650\u064a\u0644\u064e` for `\u062f\u064e\u0644\u0650\u064a\u0644\u0657\u0627` (25:45).
# ---- residue pins, 2026-08-28 (each read off the glyph outline and the printed page) ----
def _pin(fam, key, rules):
    CTXPIN.setdefault(fam, {}).setdefault(key, {}).update(rules)

for _f in ("kufi", "madani", "basri"):
    # HQPB2#197 is a dagger alef from a rarely used subset (outline: a short raised stroke).
    # It closes `يُفۡتَرَىٰ`, `وَنَخۡزَىٰ`, `عَلَىٰٓ إِلۡ`, `إِلَىٰٓ أُمِّ مُوسَىٰٓ`,
    # `ٱلۡقُرَىٰ` (7:101, drawn three times) and `أُخۡرَىٰ` (35:18), and the learner had it
    # as nothing in kufi and basri and blanked by six context rules in madani.
    _pin(_f, "CL|HQPB2#197|\u2211", {"*": "\u0670"})
    # HQPB7#85 is the fatha (HQPB5#85's twin in another subset); blank, it cost Rawh the
    # second hamza's vowel in `ءَأَذۡهَبۡتُمۡ` (46:20) and ad-Duri/Susi two words each.
    _pin(_f, "CL|HQPB7#85|r", {"*": "\u064e"})
# HQPB5#21 is the Madani books' dagger alef on ayah-final `ى` words (`وَبُشۡرَىٰ`, `نَادَىٰ`); two
# of its six context rules had learned Qaloon's ayah-final `ۖ` instead, 16 words a volume.
_pin("madani", "CL|HQPB5#21|2", {"*": "\u0670"})
# The wide-fatha glyph before the `لَّآ` ligature is a fatha: `كَلَّآ` 74:54, the only one of
# the thirteen `كَلَّآ` in the volume set with this glyph, shipped `كالَّا`.
_pin("madani", "CL|HQPB5#129|\u0178", {"n:CL|Hamd2#18|\uf02f": "\u064e"})
# The Yaqub books' shadda-fatha-meem stacks (iqlab on a doubled letter). Learned with the
# Madani alef baked in (`ّاَۢ`) because the bridge texts spell `غَمّاَۢ`; the alef glyph
# follows anyway, so `غَمَّۢا` / `لَيَّۢا` / `وَبَرَّۢا` / `مَنَّۢا` doubled it and
# `كُلَّۢا` (7:45) doubled the lam too. Zero uses in the two Basri bridges.
_pin("basri", "CL|HQPB5#38|C", {"*": "\u0651\u064e\u06e2"})
_pin("basri", "CL|HQPB5#39|D", {"*": "\u0651\u064e\u06e2"})
# HQPB5#50 is the Yaqub subset's copy of HQPB5#55 (the books number that subset five
# lower): the ring the print draws on a letter dropped in wasl - `أَنَا۠`, and the heh of
# `ٱقۡتَدِه۠` (6:90) / `يَتَسَنَّه۠` (2:259) that Ya'qub reads without. It emitted a space.
_pin("basri", "CL|HQPB5#50|O", {"*": "\u06e0"})
# Hamd2#9 under this cmap code is the eased-hamza alef of Ruways' `ءَا۬قۡرَرۡتُمۡ` (3:81),
# `ٱلسُّفَهَآءَ ا۬مۡوَٰلَكُمُ` (4:5) and `جَآءَ ا۬حَدٌ` (4:43); learned as `ءَٰا۬` off ad-Duri's idkhal
# spelling, it doubled the hamza (`ءَءَٰاقۡرَرۡتُمۡ`).
_pin("basri", "CL|Hamd2#9|\uf026", {"*": "\u0627\u06ec"})
# HQPB7#11 is HQPB5#11's twin, the silent-alef oval; its learned value was `ِۗ إِنَّ`.
_pin("basri", "CL|HQPB7#11|(", {"*": "\u0652"})
# The dagger alefs of `وَٱلسَّٰبِقُونَ` (9:100) and `ٱلرَّٰكِعُونَ` (9:112): two learned rules
# blanked HQPB2#155/#154 in exactly these two contexts, which occur nowhere else in the four
# Basri volumes, and every verified text (the two bridges included) writes the dagger.
_pin("basri", "CL|HQPB2#155|\u2248", {"b:CL|HQPB4#130|\u00a1|CL|HQPB1#25|6": "\u0670"})
_pin("basri", "CL|HQPB2#154|\u2261", {"b:CL|HQPB4#136|\u00a7|CL|HQPB2#21|2": "\u0670"})
# Khalaf's volume alone inserts the dotted alef of Hamd2#3 after the hamza of `أَكَلَ` (5:3),
# `فَسَأَكۡتُبُهَا` (7:156), `وَأَكُن` (12:33) and `ذَرَأَكُمۡ` (67:24). Khallad's, Abu
# al-Harith's and Ishaq's pages set the identical words without it, no reading exists,
# and every verified text writes the plain hamza: a typesetting artifact, dropped.
_pin("kufi", "CL|Hamd2#3| ", {"*": ""})
_pin("kufi", "CL|Hamd2#3|\uf020", {"*": ""})
# Khallad's sakt-site `ٱلۡأَرۡضَ` (2:22, 2:27): the farsh layer's wasl sign MSH-Quraan1#35
# now sits between the alef and the `أ` ligature, so the pin above that hands the
# ligature its lam has to know this neighbour too.
_pin("kufi", "CL|HQPB2#93|{", {"b:CL|MSH-Quraan1#35|\u2245|CL|HQPB5#46|F": "\u06e1\u0623"})

# The `لأ` ligature (HQPB2#93) in the BASRI books: like `لإ`, the vowels of BOTH letters
# arrive as the next glyph, one rung per pair. Read off Ruways against Hafs and confirmed
# on ad-Duri's own coding, which numbers the same subset five higher:
#   Yaqub #47 / Duri #52  kasra + fatha   `لِأَنفُسِكُمۡ`      (39 / 38 words)
#   Yaqub #57 / Duri #62  fatha + fatha   `لَأَعۡنَتَكُمۡ`     (35 / 35)
#   Yaqub #55 / Duri #60  kasra + damma   `لِأُنذِرَكُم`, and `لِّأُوْلِي` with the
#                                          second damma glyph read as its shadda
#   Yaqub #59 / Duri #64  kasra-shadda + fatha `لِّأَيۡمَٰنِكُمۡ` (10 / 10)
#   Yaqub #66 / Duri #71  fatha + damma   `لَأُكَفِّرَنَّ`     (8 / 8)
#   Yaqub #67 / Duri #72  fatha-shadda + fatha `لَّأَسۡمَعَهُمۡ` (3 / 3)
#   Yaqub #70 / Duri #75  fatha-shadda + damma `لَّأُكَفِّرَنَّ` 5:13
# The learner had #93 itself as `۬لۡأ` in the Yaqub books (no bridge codes it), so ~100
# words a volume shipped with a sukoon on a lam that opens the word (`لۡأَنفُسِكُم`).
for _lig in ("CL|HQPB2#93|{",):
    for _gid, _lam, _hz in ((47, "\u0644\u0650\u0623", "\u064e"), (52, "\u0644\u0650\u0623", "\u064e"),
                            (57, "\u0644\u064e\u0623", "\u064e"), (62, "\u0644\u064e\u0623", "\u064e"),
                            (55, "\u0644\u0650\u0623", "\u064f"), (60, "\u0644\u0650\u0623", "\u064f"),
                            (59, "\u0644\u0651\u0650\u0623", "\u064e"), (64, "\u0644\u0651\u0650\u0623", "\u064e"),
                            (66, "\u0644\u064e\u0623", "\u064f"), (71, "\u0644\u064e\u0623", "\u064f"),
                            (67, "\u0644\u0651\u064e\u0623", "\u064e"), (72, "\u0644\u0651\u064e\u0623", "\u064e"),
                            (70, "\u0644\u0651\u064e\u0623", "\u064f"), (75, "\u0644\u0651\u064e\u0623", "\u064f")):
        _ch = {47: "L", 52: "L", 57: "V", 62: "V", 55: "T", 60: "T", 59: "X", 64: "X",
               66: "_", 71: "_", 67: "`", 72: "`", 70: "c", 75: "c"}[_gid]
        _rung = f"CL|HQPB5#{_gid}|{_ch}"
        _pin("basri", _lig, {f"n:{_rung}": _lam})
        _pin("basri", _rung, {f"p:{_lig}": _hz})

# The Abu Ja'far books set `لَأَتَوۡهَا` (33:14, the qasr reading Nafi' shares) as the `لأ`
# ligature + the hamza's fatha (#80, their numbering of #85) + the wide fatha glyph #129
# for the lam; the learner read #129 as an alef and shipped `لۡأَاتَوۡهَا`.
_pin("madani", "CL|HQPB2#93|{", {"n:CL|HQPB5#80|m": "\u0644\u064e\u0623"})
_pin("madani", "CL|HQPB5#129|\u0178", {"b:CL|HQPB5#80|m|CL|HQPB1#34|?": ""})

_LAM_MARKS = set("\u064b\u064c\u064d\u064e\u064f\u0650\u0651\u0652\u06e1\u06e2\u06ed\u0656\u0657\u065e")
_PAUSE_ALL = set("\u06d6\u06d7\u06d8\u06d9\u06da\u06db\u06dc\u06dd\u06de\u06e9")
_DARATUM_RX = re.compile("(\u0670\u0631\u064e\u0623)\u06e1(\u062a\u064f\u0645)")
_HAMZA_SHADDA_RX = re.compile("\u0644([\u064e\u0650])\u0623([\u064e\u064f\u0650]*)\u0651([\u064e\u064f\u0650]*)")
_EASED_ALEF_RX = re.compile("^(\u0627(?:[\u064e\u064f\u0650]?[\u06ec\u06df]|[\u06ec\u06df][\u064e\u064f\u0650]?))\u0627")

# ---- site patches: print errors, corrected by hand and listed in data/sitepatch.json ----
_sitepatch_cache = {}

def apply_sitepatch(t, slug, sid, aid):
    """Replace one word at one site. Only for a PRINT error - a word the page itself sets
    wrong against every reading and its own sister volume - never for a reading. The file
    keys slug -> "surah:ayah" -> [[word index, printed form, corrected form, why], ...] and
    a patch whose printed form is not what the render produced is reported, not applied."""
    if not _sitepatch_cache:
        sp = DATA / "sitepatch.json"
        _sitepatch_cache.update(json.loads(sp.read_text()) if sp.exists() else {"_": {}})
    rules = _sitepatch_cache.get(slug, {}).get(f"{sid}:{aid}")
    if not rules:
        return t
    ws = t.split(" ")
    for idx, frm, to, why in rules:
        if idx < len(ws) and ws[idx] == frm:
            ws[idx] = to
        else:
            print(f"sitepatch {slug} {sid}:{aid} w{idx}: expected {frm!r}, found "
                  f"{ws[idx] if idx < len(ws) else None!r} - NOT applied", file=sys.stderr)
    return " ".join(ws)

LAM_ALEF_LIGATURE = ("CL|HQPB2#89|\u03c9", "CL|HQPB2#90|\u03be")


def _weld_ligature_alef(out):
    """Give the lam-alef ligature its alef back where nothing else printed one."""
    for i, (k, v) in enumerate(out):
        # `k.split("||")[0]`, not `k`: where a mark sits on the ligature the two arrive as
        # ONE composite key (`CL|HQPB2#90|\u03be||HQPB5#20|1`, the taqlil dot on `\u0643\u0650\u0644\u064e\u0627\u0647\u064f\u0645\u064e\u0627`
        # 17:23), and an exact match left those outside the weld with their alef gone.
        if k.split("||")[0] not in LAM_ALEF_LIGATURE or not v or "\u0644" not in v or "\u0627" in v:
            continue
        nxt = ""
        for _k2, v2 in out[i + 1:]:
            nxt = "".join(c for c in (v2 or "") if not unicodedata.combining(c))
            if nxt:
                break
        if nxt[:1] in ("\u0627", "\u0671", "\u0622"):
            continue          # the word prints its alef as a glyph of its own
        out[i] = (k, v + "\u0627")
        # The vowel the ligature already carries is often ALSO drawn as its own glyph on
        # the next slot (`\u0641\u064e\u0644\u064e\u0627\u064e`, `\u0631\u0650\u062c\u064e\u0627\u0644\u0657\u0627\u0657`); a mark that adds nothing the ligature
        # does not already say is that second copy, and only that - a maddah or a hamza
        # after the alef is a different mark and stays.
        if i + 1 < len(out):
            k2, v2 = out[i + 1]
            if v2 and all(unicodedata.combining(c) for c in v2) and set(v2) <= set(v):
                out[i + 1] = (k2, "")
    # The marks of the ligature's LAM can arrive as their own glyph AFTER the ligature,
    # i.e. after the alef it already carries: the Yaqub books draw `لَّازِبِۢ` (37:11) as
    # the ligature + a shadda-fatha glyph, and `كُلَّۢا` (7:45) as the ligature + the
    # shadda-fatha-meem stack, which shipped `لَاَّزِبِۢ` and `كُلَالّاَۢ`. A vowel,
    # tanween, shadda, sukoon or small meem can only sit on the lam, so those go in front
    # of the alef; a maddah, a hamza or a silent-alef sign stays on the alef.
    for i, (k, v) in enumerate(out):
        if k.split("||")[0] not in LAM_ALEF_LIGATURE or not v or "\u0627" not in v:
            continue
        ai = v.rfind("\u0627")
        head, tail = v[:ai], v[ai + 1:]
        j, lam_marks, consumed = i + 1, [], []
        while j < len(out):
            k2, v2 = out[j]
            if k2 == "sp" or not v2 or not all(unicodedata.combining(c) for c in v2):
                break
            for c in v2:
                if c in _LAM_MARKS:
                    lam_marks.append(c)
                else:
                    tail += c
            consumed.append(j); j += 1
        if not consumed:
            continue
        add = [c for c in lam_marks if c not in head]
        if add or tail != v[ai + 1:]:
            out[i] = (k, head + "".join(add) + "\u0627" + tail)
        for j2 in consumed:               # moved, or a repeat of what the ligature says
            out[j2] = (out[j2][0], "")
    return out


def ctxpin(fam, key, prev, nxt):
    r = CTXPIN.get(fam, {}).get(key)
    if not r:
        return None
    for kk in (f"b:{prev}|{nxt}", f"p:{prev}", f"n:{nxt}", "*"):
        if kk in r:
            return r[kk]
    return None


ISHMAM_GIDS = ("MSH-Quraan1#39|", "MSH-Quraan1#40|", "HQPB7#7|", "Hamdy4#98|")
# Hamdy4#98 is the Yaqub volumes' copy of it, and its outline sits high above the
# baseline rather than low, but it does the same job: on `وَقِيلَ` 75:26 it stands in
# the qaf's empty vowel slot. Every one of the seven verified texts writes that word
# with a plain kasra and leaves the ishmam to the tajweed layer, so it resolves the
# same way the other three do.
# HQPB7#7 is the BODY layer's own copy of the same dot (an identical small filled
# oval), drawn beside the farsh layer's on the tasheel words only. Same rule, and
# since its base is always the alef of a `ءَأَ` word it always resolves to nothing.
ISHMAM_BASES = set("\u0642\u0633\u063a\u062d\u062c")   # ق س غ ح ج

def ishmam_dot(out):
    """Kasra if this dot caps an ishmam consonant, nothing if it annotates an alef."""
    for _, prev in reversed(out):
        for ch in reversed(prev):
            if not unicodedata.combining(ch):
                return "\u0650" if ch in ISHMAM_BASES else ""
    return ""

SHADDA = "\u0651"
# tanween, fatha, damma, kasra, and the dagger alef: everything a shadda can cap.
# The imalah/taqlil dot belongs here too. It is not a vowel, it REPLACES one, and the page
# stacks it after the shadda exactly as it stacks a fatha - but because it was missing from
# this set the pair came out `دّٜ` instead of `دّٜ` in 970 words across seven volumes. The
# verified texts are unanimous on the order: ad-Duri writes `اَ۬لنّٜاسِ` 325 times, Warsh
# `فَسَوّ۪يٰهُنَّ` 235, Susi 146, Shubah `رّٜءٜا` 3, and not one of the eight ever writes the
# dot first.
_CAPPABLE = "\u064b\u064c\u064d\u064e\u064f\u0650\u0670\u0656\u065c\u06ea"

def compose_hamza(text):
    """Fold a combining hamza back onto the alef it sits on: ا + ٔ -> أ, ا + ٕ -> إ.

    The MSH farsh layer draws the hamza as its own glyph and the page stacks it AFTER the
    alef's vowel, so the two are not adjacent in stream order. Skip back over the vowels,
    compose, and let NFC pick the right precomposed letter."""
    def fold(m):
        return unicodedata.normalize("NFC", m.group(1) + m.group(3)) + m.group(2)
    # The mark class includes the Basri/Madani tanween forms (U+0656/57/5E): `هُزُوٗ` + the
    # farsh layer's hamza is `وٗٔ`, and a class that stopped at U+0652 never composed it.
    text = re.sub("([\u0627\u0648\u064a\u0649])([\u064b-\u0652\u0656\u0657\u065e\u0670]*)([\u0654\u0655])",
                  fold, text)
    # ...and a hamza stacked on a letter that already carries one is the farsh layer
    # redrawing what the body layer drew (ad-Duri's `هُزُؤٗا` 2:231: MSH#47 over a waw the
    # learner had already read as `ؤ`). Nothing to compose; drop it.
    return re.sub("([\u0623\u0624\u0626])([\u064b-\u0652\u0656\u0657\u065e\u0670]*)[\u0654\u0655]", r"\1\2", text)

def reorder_dagger(text):
    """[dagger alef][vowel] -> [vowel][dagger alef].

    Same stacking problem as the shadda below: the page draws the dagger over the letter and
    the vowel wherever it fits, and clustering keeps whatever order the stream had. The
    eight verified texts write the vowel first 7,215-7,494 times each and the dagger first
    not once, so `فَأَزَٰلَهُمَا` for `فَأَزَالَهُمَا` is ours, not the edition's."""
    return re.sub("\u0670([\u064b-\u0650])", lambda m: m.group(1) + "\u0670", text)


def reorder_shadda(text):
    """[vowel][shadda] -> [shadda][vowel]. See ZONEFLIP: the page stacks the shadda after
    the vowel it caps; Unicode and the app both write it first."""
    return re.sub("([" + _CAPPABLE + "])" + SHADDA, lambda m: SHADDA + m.group(1), text)

# ---------------------------------------------------------------- deterministic map

# family -> {gid signature: emission}, filled in by build_detmap; see the comment there.
GIDFALLBACK = {}

def gid_signature(key):
    """A cluster key with every cmap char stripped, leaving only the gids.

    `CL|HQPB1#123|>||HQPB5#20|1` becomes `CL|HQPB1#123||HQPB5#20`. Two volumes that draw
    the same glyphs share this even when they code them differently.
    """
    if not key or key == "sp| ":
        return None
    body = key[3:] if key.startswith("CL|") else key
    parts = [p.rsplit("|", 1)[0] for p in body.split("||")]
    if not all(parts):
        return None
    return ("CL|" if key.startswith("CL|") else "") + "||".join(parts)


# Six Hamd2 glyphs the learner scored as U+06ED, the small LOW meem of iqlab. They are not
# that: their outlines measure 469x452, to the unit the same blob as HQPB5#20, HQPB7#20 and
# MSH-Quraan1#38 - the imalah dot - while the real iqlab glyphs in the very same books
# (HQPB5#138-140 at 505-632 wide, HQPB4#38) are half again as tall. The confusion is an
# easy one to make, because BOTH marks are drawn below the baseline, so the zone audit that
# catches a shadda-turned-kasra cannot see it; and it survived because U+06ED is a legal
# mark that no downstream rule flags. Hamd2#170-172, the same dot in the same run of gids,
# were learned correctly, which is what makes these six stand out as a mistake rather than
# an edition convention.
#
# Cost: 1,164 marks in duriabiamr and 1,050 in susi - both BRIDGES, so it was quietly
# holding their roundtrip down - plus 61 in khalaf and 30 in khallad, where it printed
# `ٱلتَّوۡرۭىٰةَ` for `ٱلتَّوۡرٜىٰةَ`. Across the eight verified texts U+06ED never appears
# except directly after a kasra or a tanween, which is the check that found it.
_DOT_MISREAD = {"Hamd2#40", "Hamd2#41", "Hamd2#164",
                "Hamd2#165", "Hamd2#167", "Hamd2#168"}

def _key_gids(k):
    return {seg for part in k.split("||") for seg in part.split("|") if "#" in seg}


def build_detmap(fam, bridges_counts=("kufi", "madani", "basri", "makki"), extra=None):
    """`extra` overlays one more counts file at the highest priority and suppresses the
    detmap-<fam>.json write.

    It exists for al-Bazzi, whose volume is a reprocessed copy that re-subset every font
    into its own glyph order (see bazzi.py). Its keys therefore mean different things from
    the same keys in its Makki twin - `HQPB5#129` is one glyph in Qunbul and another in
    al-Bazzi - so they cannot live in the shared family counts without moving Qunbul. As
    an overlay they are read only when al-Bazzi is the volume being rendered, and
    `glyphcounts-makki.json` stays byte-identical.
    """
    own = json.loads((DATA / f"glyphcounts-{fam}.json").read_text())
    merged = {}
    for other in reversed([f for f in bridges_counts if f != fam]):
        p = DATA / f"glyphcounts-{other}.json"
        if p.exists():
            for k, v in json.loads(p.read_text()).items():
                merged.setdefault(k, v)
    for k, v in own.items():
        merged[k] = v
    if extra:
        ep = DATA / extra
        if ep.exists():
            for k, v in json.loads(ep.read_text()).items():
                merged[k] = v
    detmap, amb = {}, {}
    for k, dist in merged.items():
        items = sorted(dist.items(), key=lambda x: -x[1])
        tot = sum(dist.values())
        e, n = items[0]
        if e in ("", " ") and n / tot < 0.90:
            nonnull = [(e2, n2) for e2, n2 in items if e2 not in ("", " ")]
            if not nonnull:
                detmap[k] = ""
                continue
            e, n = nonnull[0]
            nn_tot = sum(x for _, x in nonnull)
            if n / nn_tot >= 0.55 or nn_tot <= 3:
                detmap[k] = e
            else:
                amb[k] = items[:5]
            continue
        purity = n / tot
        if purity >= 0.55 or tot <= 3:
            detmap[k] = e
        elif len(items) >= 2 and items[1][0] == e * 2:
            detmap[k] = e
        else:
            amb[k] = items[:5]
    manual_p = DATA / "manualmap.json"
    if manual_p.exists():
        # A manual entry may be scoped to one family by prefixing its key with `<fam>:`.
        # Gid numbering is stable across volumes but MEANING is not always: HQPB2#91 is the
        # لأ ligature of `ٱلۡأٓخِرَةِ` in the Madani volumes and something else entirely in
        # the Kufi ones, and forcing the Madani reading on all of them cost shubah 1.7
        # points (90.56% to 88.86%) across three keys. Unscoped entries still apply
        # everywhere, which is what the 139 older ones want.
        for k, v in json.loads(manual_p.read_text()).items():
            scope, sep, rest = k.partition(":")
            if sep and scope in ("kufi", "madani", "basri", "makki"):
                if scope == fam:
                    detmap[rest] = v
            else:
                detmap[k] = v
    drop_p = DATA / "droplist.json"
    # `CL|MSH-Quraan1#13|\u2217` was learned as the U+06D9 no-stop sign and is the only
    # codepoint the twelve carried that no verified text uses. It belongs to MSH-Quraan1,
    # the farsh COLOUR layer, always comes in runs of two or three, and lands on words that
    # every one of the eight verified texts writes with no waqf sign at all. It marks the
    # differing word for the reader; it is not scripture.
    drops = set(json.loads(drop_p.read_text())) if drop_p.exists() else set()
    for k in drops:
        detmap[k] = ""
    for k, v in list(detmap.items()):
        if v == "\u06ed" and _key_gids(k) & _DOT_MISREAD:
            detmap[k] = imalah_mark(fam)   # see _DOT_MISREAD
    # ---- char-blind fallback, keyed on the gids alone -----------------------------
    # A detmap key is `font#gid|char`, where the char is the volume's own cmap code for
    # that glyph - and a volume embeds its own font SUBSET, so the same outline can arrive
    # under a different code in a different book. The two Khalaf al-Ashir volumes re-code
    # nearly every one of them: `HQPB2#179` is the ya that Shubah writes as `©` and they
    # write as `\uf6d9`, so 1,294 ya letters fell out of `شَيۡء`, `ٱلَّتِي`, `مُوسَىٰ` and
    # `بَنِيٓ` with nothing learned to catch them. Sixteen gids were affected, ~1,600 words.
    #
    # The gid is what identifies the OUTLINE, and the outline is what identifies the glyph,
    # so where a family's learned keys for one gid signature all agree, that emission is a
    # property of the glyph rather than of the code it arrived under, and an unseen code
    # for it can safely take the same answer. Unanimity is the whole guard: a gid whose
    # learned keys disagree teaches nothing here and is left to miss, exactly as before.
    # It is scoped per family for the same reason manual entries are (see the loader
    # above): gid numbering is stable across volumes but MEANING is not always.
    sig = collections.defaultdict(collections.Counter)
    for k, v in detmap.items():
        g = gid_signature(k)
        if g:
            sig[g][v] += 1
    GIDFALLBACK[fam] = {g: next(iter(c)) for g, c in sig.items() if len(c) == 1}
    if not extra:
        (DATA / f"detmap-{fam}.json").write_text(json.dumps(detmap, ensure_ascii=False, sort_keys=True))
        (DATA / f"detamb-{fam}.json").write_text(json.dumps(amb, ensure_ascii=False, indent=1, sort_keys=True))
    print(f"{fam}{'+' + extra.split('-')[-1].split('.')[0] if extra else ''}: "
          f"detmap {len(detmap)} keys, ambiguous {len(amb)}")
    return detmap

# U+0656 and U+0657 belong here too: in this orthography they are the subscript-alef
# kasra of `\u0646\u0651\u064e\u0628\u0650\u064a\u0651\u0656` and the inverted-damma tanween of `\u0642\u064e\u0644\u0650\u064a\u0644\u0657\u0627`, so a letter carries one of
# them OR a plain vowel, never both - zero co-occurrences across the eight verified
# texts, against 12 in the twelve.
_VOWEL_SET = set("\u064b\u064c\u064d\u064e\u064f\u0650\u0656\u0657")
_SUKOON_SET = set("\u0652\u06e1")

def strip_impossible_marks(text, keep="last"):
    """Drop mark combinations that no verified text ever writes on one letter.

    Checked over all eight KFGQPC texts (Hafs + the seven qiraat), every one of these is
    zero-occurrence, so a hit is an extraction artifact and not an edition convention:

      the same mark drawn twice     `ءَايََٰتُۢ` - the farsh layer redraws a glyph and both
                                    copies survive clustering
      two different vowels          `مُّؤۡمََِنةٌ` (fatha AND kasra), `ٱللَّهَُّ` (fatha AND damma)
      a vowel beside the imalah dot the dot REPLACES the vowel; `جٜآءَ` never carries one
      a sukoon beside the dot       a letter with a sukoon has no vowel to bend, so the dot
                                    is its neighbour's - move it on rather than delete it
      a doubled alef                `وَّتَفۡرِيقاا`

    The one exception the texts DO write is a dot on a word-INITIAL alef that also carries
    a vowel (`اُ۪هۡدِنَا`, 667-673 times in Qaloon/Warsh/Duri/Susi). That dot is the wasl
    sign, not imalah, and it is left alone.
    """
    out = []
    for w in text.split(" "):
        cl = []
        for c in w:
            if unicodedata.combining(c) and cl:
                cl[-1][1] += c
            else:
                cl.append([c, ""])
        for i in range(len(cl)):
            base, marks = cl[i]
            seen, m = set(), []
            for c in marks:
                if c in seen:
                    continue                       # the same mark drawn twice
                seen.add(c)
                m.append(c)
            vows = [c for c in m if c in _VOWEL_SET]
            if len(vows) > 1:
                # The page stacks a correction ON TOP of what it is correcting, so the last
                # one drawn is the one meant. Measured against the five bridges.
                win = vows[-1] if keep == "last" else vows[0]
                kept = False
                m2 = []
                for c in m:
                    if c in _VOWEL_SET:
                        if c == win and not kept:
                            kept = True
                            m2.append(c)
                        continue
                    m2.append(c)
                m = m2
            dots = [c for c in m if c in _DOT_SET]
            if dots and not (base in _BARE_ALEF and i == 0):
                if any(c in _SUKOON_SET for c in m) and i + 1 < len(cl):
                    m = [c for c in m if c not in _DOT_SET]
                    cl[i + 1][1] += dots[0]        # the dot is the next letter's
                else:
                    m = [c for c in m if c not in _VOWEL_SET]
            cl[i][1] = "".join(m)
        out.append("".join(b + mm for b, mm in cl))
    return " ".join(out).replace("\u0627\u0627", "\u0627")


# The canonical order of tashkeel within one letter, derived from the eight verified texts
# by markorder.py (87 rules, and the 10 pairs those texts genuinely write both ways are
# deliberately absent so nothing invents a convention for them). This subsumes and
# generalises reorder_shadda and reorder_dagger above: the page stacks marks in whatever
# order its layers emit, Unicode assigns no combining class to the Quranic signs, so the
# only authority for the order is what the real texts do.
_MARK_ORDER = None

def _mark_before():
    global _MARK_ORDER
    if _MARK_ORDER is None:
        p = DATA / "markorder.json"
        _MARK_ORDER = {(a, b) for a, b, *_ in json.loads(p.read_text())} if p.exists() \
            else set()
    return _MARK_ORDER

def canonical_mark_order(text):
    """Sort each letter's marks into the order the verified texts write them in."""
    before = _mark_before()
    if not before:
        return text
    out = []
    for w in text.split(" "):
        cl = []
        for c in w:
            if unicodedata.combining(c) and cl:
                cl[-1][1] += c
            else:
                cl.append([c, ""])
        for cell in cl:
            m = list(cell[1])
            if len(m) < 2:
                continue
            # bubble, because the relation is a partial order: only adjacent marks the
            # table has an opinion about ever move, everything else keeps its position
            for _ in range(len(m)):
                swapped = False
                for i in range(len(m) - 1):
                    if (m[i + 1], m[i]) in before:
                        m[i], m[i + 1] = m[i + 1], m[i]
                        swapped = True
                if not swapped:
                    break
            cell[1] = "".join(m)
        out.append("".join(b + mm for b, mm in cl))
    return " ".join(out)


def maqsura_rule(text, family="kufi"):
    """Word-final ya: `ي` or the alef maqsura `ى`, decided by what precedes it.

    The print draws ONE glyph for both - `HQPB2#179` is the same outline in `شَيۡءٖ` and in
    `مُوسَىٰ` - so the extractor cannot tell them apart and emits the ya. Where a dagger
    alef follows, the ligature rules downstream already fold it; where nothing follows, the
    word shipped `مُوسَي` for `مُوسَى`, 56 words a volume.

    The orthography decides it, and it decides it exactly. Over every one of the 3,417
    word-final ya/maqsura in the app's KFGQPC-verified Hafs, with the identical split in
    the verified Shubah:

        carries a sukoon           -> `ي`   17 (`ٱثۡنَيۡ`, `ٱبۡنَيۡ`, `يَدَيۡ`: the -ay diphthong)
        else preceded by a kasra   -> `ي`   2,829 (`فِي`, `ٱلَّتِي`, `أَخِي`)
        else                       -> `ى`   2,571 (`عَلَىٰ`, `إِلَى`, `هُدٗى`, `رَمٜىٰ`)

    No word contradicts it there, nor in the verified Qaloon (5,294 of 5,294), so its
    violation count reads as an error count anywhere else - method 9 in the handoff.

    One clause of it IS an edition convention rather than orthography, and the Basri texts
    take the other side: where an imalah or taqlil dot precedes, they write the ya.

        QiraahDuri  `مُوس۪يٰ` `وَاَلنَّصَٰرٜيٰ`   605 words - and it is 605 of the 605 that
        QiraahSusi  the same                       disagree, so nothing else divides them
        QiraahShubah `رَمٜىٰ` `أَعۡمٜىٰ`            5 words the other way

    Applied blind that clause alone cost susi 2.4 points, so it is scoped to the family.

    A ya carrying its OWN vowel is a consonant and is never touched (`نِعۡمَتِيَ`): only a
    trailing dagger alef, maddah, sukoon or pause sign may stand between it and the end.
    """
    TAIL = "\u0670\u0653\u06e1\u0652"       # dagger alef, maddah, the two sukoons
    # An alef maqsura is a long vowel and cannot be doubled, so a ya carrying a SHADDA is a
    # consonant wherever it stands. The eight verified texts write 1,058-1,702 shadda'd ya
    # between them and not one shadda'd maqsura. The walk-back below only ever inspects the
    # LAST letter of a word, so it never saw `إِلَىَّ`/`عَلَىَّ` for `إِلَيَّ`/`عَلَيَّ` -
    # 39 words each in Ruways and Rawh.
    text = text.replace("\u0649\u0651", "\u064a\u0651")
    out = []
    for w in text.split(" "):
        core = w.rstrip("".join(_PAUSE_SET))
        pause = w[len(core):]
        i = len(core) - 1
        while i >= 0 and core[i] in TAIL:
            i -= 1
        if i < 0 or core[i] not in ("\u064a", "\u0649"):
            out.append(w)
            continue
        tail = core[i + 1:]
        if "\u06e1" in tail or "\u0652" in tail:
            want = "\u064a"
        else:
            prev = None
            for c in reversed(core[:i]):
                if c in "\u064b\u064c\u064d\u064e\u064f\u0650\u065c\u06ea":
                    prev = c
                    break
                if not unicodedata.combining(c):
                    break
            if prev == "\u0650":
                want = "\u064a"
            elif family == "basri" and prev in ("\u065c", "\u06ea"):
                want = "\u064a"       # the Basri edition writes `مُوس۪يٰ`; see above
            else:
                want = "\u0649"
        out.append(core[:i] + want + tail + pause)
    return " ".join(out)


def pause_to_word_end(text):
    """A waqf sign never sits inside a word, so move a stray one to the end of its word.

    The farsh layer redraws a whole differing word, its waqf sign included, and the redraw
    is clustered by x-overlap with the letters rather than trailed after them - so the sign
    arrives before the word's last letter or its final vowel: `بِهِمَۚا` for `بِهِمَاۚ`
    (2:158), `أَجۡرًۖا` for `أَجۡرًاۖ` (6:90), `ٱلۡأٓخِرَۗةِ` for `ٱلۡأٓخِرَةِۗ` (3:148).

    Where the black body layer prints the same sign too, the two then sit apart and
    `collapse_doubled_marks` cannot see them as a pair, so the word ships `ۚۚ`. Moved to
    the end they become adjacent and fold, which is why this has to run BEFORE the collapse.
    """
    out = []
    for w in text.split(" "):
        n = sum(1 for c in w if c in _PAUSE_SET)
        if not n or all(c in _PAUSE_SET for c in w[len(w) - n:]):
            out.append(w)
            continue
        out.append("".join(c for c in w if c not in _PAUSE_SET)
                   + "".join(c for c in w if c in _PAUSE_SET))
    return " ".join(out)


def collapse_doubled_marks(text):
    """No app text ever repeats the identical combining mark consecutively - doubled
    marks are stroke+fill double-draw artifacts.

    Also folds a repeated mark SEQUENCE, not just a repeated character: a glyph that
    carries two marks at once (HQPB4 gid 38 is kasra + small low meem) double-draws as
    `ِِۭۭ`, where no two adjacent characters are equal and the per-character rule above
    sees nothing to remove."""
    out = []
    for ch in text:
        if out and ch == out[-1] and unicodedata.combining(ch):
            continue
        out.append(ch)
    # second pass: within each maximal run of combining marks, XY XY -> XY
    res, i, n = [], 0, len(out)
    while i < n:
        if not unicodedata.combining(out[i]):
            res.append(out[i]); i += 1
            continue
        j = i
        while j < n and unicodedata.combining(out[j]):
            j += 1
        run = out[i:j]
        half = len(run) // 2
        if len(run) % 2 == 0 and half and run[:half] == run[half:]:
            run = run[:half]
        res.extend(run)
        i = j
    return "".join(res)

_VERIFIED_WORDS = None


def verified_words():
    """Every word spelling that occurs in one of the eight KFGQPC texts.

    Used only as an arbiter where the page's glyph order is ambiguous - never to rewrite a
    reading, since most farsh words are legitimately absent from all eight.
    """
    global _VERIFIED_WORDS
    if _VERIFIED_WORDS is None:
        pause = set("\u06d6\u06d7\u06d8\u06d9\u06da\u06db\u06dc\u06dd\u06de\u06e9")
        out = set()
        q = json.loads((APP / "Resources/JSONs-Deprecated/Quran.json").read_text())
        for s in q:
            for a in s["ayahs"]:
                out.update(unicodedata.normalize("NFD", "".join(c for c in w if c not in pause))
                           for w in a["textArabic"].split())
        for f in sorted((APP / "Resources/JSONs-Deprecated/Qiraat").glob("Qiraah*.json")):
            for _, ays in json.loads(f.read_text()).items():
                for a in ays:
                    out.update(unicodedata.normalize("NFD", "".join(c for c in w if c not in pause))
                               for w in a["text"].split())
        _VERIFIED_WORDS = out
    return _VERIFIED_WORDS


def weld_bare_alef(text):
    """A lone `\u0627` is never a word: it is an alef the page drew outside its own word.

    Four survive across the twelve and the alef lands in a different place in each - the END
    of the NEXT word in `\u0627 \u0648\u064e\u0644\u064e` for `\u0648\u064e\u0644\u064e\u0627`, the end of the PREVIOUS one in
    `\u0645\u064f\u0648\u0633\u064e\u0649 \u0627` for `\u0645\u064f\u0648\u0633\u064e\u0649\u0670`, where it is really the dagger. So try each landing and
    keep it only when exactly one produces a word the verified texts know; anything
    ambiguous is left alone rather than guessed at.
    """
    if " \u0627 " not in f" {text} ":
        return text
    ws = text.split()
    known = verified_words()
    out, i = [], 0
    while i < len(ws):
        if ws[i] != "\u0627":
            out.append(ws[i]); i += 1; continue
        nxt = ws[i + 1] if i + 1 < len(ws) else None
        cands = []
        if out:
            for tail in ("\u0627", "\u0670", "\u0653"):
                cands.append(("prev", out[-1] + tail))
            # ...or the alef is a maddah stroke the page set apart from the dagger it
            # belongs over: `\u0647\u064e\u0670\u0624\u064f\u0644\u064e\u0627\u0653\u0621\u0650 \u0627` is `\u0647\u064e\u0670\u0653\u0624\u064f\u0644\u064e\u0627\u0653\u0621\u0650`.
            for j, ch in enumerate(out[-1]):
                if ch == "\u0670":
                    cands.append(("prev", out[-1][:j + 1] + "\u0653" + out[-1][j + 1:]))
        if nxt:
            cands.append(("next", nxt + "\u0627"))
        # NFD both sides: `\u0622` and `\u0627\u0653` are the same spelling, and the twelve write the
        # precomposed form where the verified texts write the pair.
        hit = [c for c in cands if unicodedata.normalize("NFD", c[1]) in known]
        if not hit:
            # No landing makes a word: the alef is a stray copy (ruways 35:11 draws the
            # fatha-alef glyph of `وَلَا` a second time, as its own token). A lone alef is
            # never a word, so an alef that fits nowhere is dropped rather than shipped.
            i += 1; continue
        if len(hit) != 1:
            out.append(ws[i]); i += 1; continue
        where, word = hit[0]
        if where == "prev":
            out[-1] = word
        else:
            out.append(word); i += 1
        i += 1
    return " ".join(out)


def attach_orphan_marks(text):
    """A whitespace-separated token that is ONLY combining marks (a pause sign whose
    space slipped in) belongs to the previous word."""
    words = text.split(" ")
    out = []
    for w in words:
        # The sajdah sign is not a combining character, but it behaves like one: all seven
        # verified texts write it welded to the last word of the ayah (`يَسۡجُدُونَۤ۩`,
        # `ٱلۡأٓصَالِ۩`) and none of them as a token of its own. The rub-el-hizb `۞` is the
        # opposite - standalone in all seven, 199 to 440 times - so only ۩ is absorbed.
        if w and (all(unicodedata.combining(c) for c in w) or w == "\u06e9") and out and out[-1]:
            tail = "".join(c for c in w if c in _PAUSE_ALL or c == "\u06e9")
            core = "".join(c for c in w if c not in _PAUSE_ALL and c != "\u06e9")
            last = out[-1][-1]
            # A waqf sign always lands. A letter mark lands only where the previous word can
            # take it: on a bare letter, a shadda over a vowel, a vowel over a shadda, a
            # dagger after a fatha, a maddah after a long letter. Anything else is the page
            # redrawing a mark the word already has, and welding it used to hand
            # `strip_impossible_marks` a second vowel to "correct" the real one with.
            ok = (not core
                  or not unicodedata.combining(last)
                  or (core[0] == "\u0651" and last in "\u064e\u064f\u0650")
                  or (last == "\u0651" and core[0] in "\u064b\u064c\u064d\u064e\u064f\u0650\u0670\u0656\u0657\u065e")
                  or (core[0] == "\u0670" and last == "\u064e")
                  or (core[0] == "\u0653" and last in "\u0627\u0648\u064a\u0649\u0670"))
            out[-1] += w if ok else tail
        else:
            out.append(w)
    return " ".join(out)

def _verified(s):
    return unicodedata.normalize("NFD", "".join(c for c in s if c not in _PAUSE_ALL)) in verified_words()


_DAGGER_AFTER_IU = re.compile("([\u0650\u064f])\u0670")

def seat_dagger(text):
    """A dagger alef after a kasra or a damma belongs to the letter BEFORE.

    The dagger is a long /a:/, so it can only follow a fatha (or a bare letter); the seven
    verified texts write `ِٰ` and `ُٰ` zero times against 7,200+ `َٰ`. Like the imalah dot
    it is its own glyph and clusters with whichever letter it overlaps, and on a tight
    line that is the NEXT one: Hisham's farsh layer draws the idkhal alif of `أَٰءِنَّا`
    between the two hamzas and the stream hands it to the second (`أَءِٰنَّا`), the plural
    `رِسَٰلَٰتِهِۦ` came out `رِسَٰلَتِٰهِۦ`, `سَادَٰتِنَا` as `سَادَتِٰنَا`. Moved back one
    letter, after that letter's own marks. A doubled dagger that results (the body layer
    had already drawn one) folds in collapse_doubled_marks.
    """
    out = []
    for w in text.split(" "):
        while True:
            m = _DAGGER_AFTER_IU.search(w)
            if not m:
                break
            # the letter carrying the kasra/damma
            j = m.start() - 1
            while j >= 0 and unicodedata.combining(w[j]):
                j -= 1
            # the letter before THAT one, and the end of its marks
            i = j - 1
            while i >= 0 and unicodedata.combining(w[i]):
                i -= 1
            if i < 0:
                w = w[:m.start() + 1] + w[m.end():]      # nothing before it: drop the dagger
                continue
            k = i + 1
            while k < len(w) and unicodedata.combining(w[k]) and k < j:
                k += 1
            w = w[:k] + "\u0670" + w[k:m.start() + 1] + w[m.end():]
        out.append(w)
    return " ".join(out)


def repair_broken_tokens(text, family):
    """A token that BEGINS with a combining mark is a word the separator layer cut.

    Three different defects wear that one symptom, so no single repair fits: a space inside
    a word (`لِلد ِّينِ` 10:105, `وَجُن ُودٗا` 33:9), a space one mark too early
    (`غَيۡر ِٱللَّهِ` 35:3 - joining would fuse two words), and the ring of an eased second
    hamza drawn before the alef it sits on (`جَآءَ ۟الَ` 15:61, `هَٰؤُلَآءِ َ۟الِهَةٗ` 21:98).
    The verified texts decide where they can: a whole-join that is a known word wins, then a
    split that leaves two known words. Where neither is known the SHAPE decides - a previous
    word ending on a bare letter takes the marks (and the rest joins unless it is a word of
    its own), a dagger follows a fatha, and a mark nothing can carry is dropped
    (`فَبِهُدٜىٰهُمُ ٰٱقۡتَدِه۠` 6:90, a doubled dagger).
    The ring: Warsh and Qunbul write `جَآءَ ا۟لَ` and every Madani/Makki text `اَ۟لِهَةٗ`
    where the Basri two write `اَ۬لِهَةٗ`; the print draws the same magenta dot for both.
    """
    ws = text.split(" ")
    out = []
    for w in ws:
        # EASE_MARK rides the glyph's emission and is not a mark; work on the bare word
        # and put the flag back on whatever token the word ends up in.
        marked = EASE_MARK in w
        w = w.replace(EASE_MARK, "")
        # The ring glyph of an eased hamza resolves to `ا۬` where the bridge spells it so
        # (ad-Duri's `اَ۬لِهَةٗ`), and the page's own alef glyph then follows it: `اَ۬ا`.
        # One alef, marked so the conventions keep the dot.
        m = _EASED_ALEF_RX.match(w)
        if m:
            w = m.group(1) + w[m.end():]; marked = True
        flag = EASE_MARK if marked else ""
        if not w or not unicodedata.combining(w[0]) or not out or not out[-1]:
            out.append(w + flag); continue
        j = 0
        while j < len(w) and unicodedata.combining(w[j]):
            j += 1
        lead, rest = w[:j], w[j:]
        prev = out[-1]
        if _verified(prev + w):
            out[-1] = prev + w + flag; continue
        if rest and _verified(prev + lead) and _verified(rest):
            out[-1] = prev + lead; out.append(rest + flag); continue
        if rest and rest[0] == "\u0627" and "\u06df" in lead and set(lead) <= {"\u06df", "\u064e"}:
            if "\u064e" in lead:
                dot = "\u06ec" if family == "basri" else "\u06df"
                out.append("\u0627\u064e" + dot + rest[1:] + EASE_MARK)
            else:
                out.append("\u0627\u06df" + rest[1:] + EASE_MARK)
            continue
        last = prev[-1]
        # A previous word that is already a complete verified word takes nothing: the
        # marks were drawn before the NEXT word's first letter (the Yaqub `لأ` ligature
        # emits its wasl-style dot first). Joining fused `أَغۡوَيۡتَنِي لَأُزَيِّنَنَّ` into
        # one 27-character token.
        if rest and len([c for c in rest if not unicodedata.combining(c)]) >= 2 and _verified(prev):
            out.append(rest[0] + lead + rest[1:] + flag); continue
        if not unicodedata.combining(last):
            if rest and _verified(rest):
                out[-1] = prev + lead; out.append(rest + flag)
            else:
                out[-1] = prev + w + flag
            continue
        if (lead[0] == "\u0670" and last == "\u064e") or (lead[0] == "\u0653" and last in "\u0627\u0648\u064a\u0649\u0670"):
            out[-1] = prev + w + flag; continue
        if rest:
            out.append(rest + flag)       # the leading marks fit nowhere: dropped
    return " ".join(out)


# The imalah/taqlil dot annotates a BENT VOWEL, so it belongs to the letter whose vowel
# bends - never to the alef that vowel leans towards. Across all seven KFGQPC-verified
# qiraat texts there is not one dot on a bare alef and not one on a word-final alef
# maqsura: Warsh writes `أَبۡصٰ۪رِهِمۡ`, ad-Duri `مُوس۪يٰ`, Shubah `رَمٜىٰ`. (The 692 dots
# those texts DO put on an alef are U+06EA on a word-INITIAL alef, which is the wasl sign
# and a different mark entirely.)
#
# The extractor cannot know that. A dot is a separate glyph and it gets clustered with
# whichever letter it overlaps, so on a tight line it lands one letter late and the same
# word ships two ways in one volume: khalaf writes `ٱلدُّنۡيٜا` 108 times and `ٱلدُّنۡياٜ`
# 6 more, ibn Dhakwan splits `جٜآءَ`/`جآٜءَ` 28 against 28. That is 427 words over eight
# volumes, and in comparison mode it reads as two riwayat differing where they do not.
#
# Two seats can never be right, so both are moved back one letter:
#   a bare alef (ا ٱ آ) that is not word-initial - a word-initial one is the wasl dot;
#   a word-final ya CARRYING A DAGGER ALEF, i.e. a real alef maqsura. The dagger is what
#   makes this safe: Abu Jafar's `اُ۬لَّٰٓيٜ` ends in a dotted ya with no dagger of its own,
#   and that ya is a genuine seat the Madani texts keep.
# Runs before `maqsura_rule` so that rule reads the dot as the letter's own mark, which is
# what puts the Basri clause (`مُوس۪يٰ`) on the right side of its ya/maqsura choice.
_DOT_SET = "\u065c\u06ea"
_BARE_ALEF = "\u0627\u0671\u0622"
_DAGGER = "\u0670"
_VOWELS = "\u064b\u064c\u064d\u064e\u064f\u0650\u0670\u0656\u0657\u065e"

def seat_imalah_dot(text):
    out = []
    for w in text.split(" "):
        cl = []                      # [letter, marks] per base letter, in order
        for c in w:
            if unicodedata.combining(c) and cl:
                cl[-1][1] += c
            else:
                cl.append([c, ""])
        moved = False
        for i, (base, marks) in enumerate(cl):
            if not any(d in marks for d in _DOT_SET):
                continue
            # One dot read twice. `رَّءَاهُ` at 96:7 draws the shadda between the two
            # copies, so `collapse_doubled_marks` never sees them as a pair and the word
            # ships `رّٜٜءٜاهُ`. A letter's vowel bends once.
            seen, keep2 = set(), []
            for c in marks:
                if c in _DOT_SET:
                    if c in seen:
                        continue
                    seen.add(c)
                keep2.append(c)
            if len(keep2) != len(marks):
                marks = cl[i][1] = "".join(keep2)
                moved = True
            if i == 0:
                continue
            # A ya or waw carrying a dagger alef is usually that alef itself
            # (`ءَاتٜىٰهُمُ`, `ٱلرِّبٜوٰاْ`) and cannot seat the dot either - but not always:
            # ad-Duri writes `دِيٰٜرِكُمۡ` and Warsh `خَطَٰيٰ۪كُمۡ`, where the ya is a real
            # consonant and the dagger is the alef after it. What separates them is the
            # letter before: it owns a vowel in the consonant reading (`دِ`) and is bare in
            # the alef reading (`ءَاتـ`), because there the dot IS its vowel. A shadda or a
            # sukoon is not a vowel, so `يَتَوَفّٜىٰهُنَّ` still moves.
            maqsura = (base in "\u064a\u0649\u0648" and _DAGGER in marks
                       and not any(c in _VOWELS for c in cl[i - 1][1]))
            if base not in _BARE_ALEF and not maqsura:
                continue
            keep = "".join(c for c in marks if c not in _DOT_SET)
            dots = "".join(c for c in marks if c in _DOT_SET)
            cl[i][1] = keep
            prev = cl[i - 1][1]
            for d in dots:
                if d not in prev:            # `رّٜٜانَ`: the same dot read twice
                    prev += d
            cl[i - 1][1] = prev
            moved = True
        out.append("".join(b + m for b, m in cl) if moved else w)
    return " ".join(out)


# The dot under a bent vowel: U+065C where the reading is imalah kubra and U+06EA where
# it is taqlil (bayna bayna). The print draws ONE dot for both - it is the same phonetic
# annotation, and only the riwayah says how far the vowel actually bends - so the choice
# cannot come from the glyph and has to come from the family.
#
# Madani is unambiguous: Warsh and Abu Jafar both read taqlil, and across the app's own
# Qaloon and Warsh texts there are 3,264 U+06EA against a single U+065C, which is a typo.
# Emitting U+065C there was 1,482 diffs in warsh alone, every one of them this swap.
# Kufi keeps U+065C (Hamzah and al-Kisai read imalah kubra: 1,884 and 1,941 of them).
# Basri writes BOTH and cannot be decided this way, so it is left on the kufi default and
# `apply_family_conventions` continues to repair the taqlil words from the bridge text.
IMALAH_MARK = {"madani": "\u06ea"}

def imalah_mark(family):
    return IMALAH_MARK.get(family, "\u065c")

_ZONE_ABOVE = set("\u064b\u064c\u064e\u064f\u0651\u0652\u0670\u0653\u0657\u06e1")
_ZONE_BELOW = set("\u064d\u0650\u0656")

def _zone_of_emission(v):
    """below / above / None, judged on the VOWELS in an emission and nothing else.

    A pause sign or a small letter riding along with the vowel does not change which side
    of the baseline the vowel is drawn: `ٍۖ` is a below emission, exactly as `ٍ` is.
    """
    if not v or any(not unicodedata.combining(c) for c in v):
        return None
    above = any(c in _ZONE_ABOVE for c in v)
    below = any(c in _ZONE_BELOW for c in v)
    if above == below:
        return None
    return "above" if above else "below"


def _repeat_cluster(key, detmap):
    """The value of `CL|X||X||X`, which is the value of `CL|X`. None if not that shape."""
    body = key[3:] if key.startswith("CL|") else key
    parts = body.split("||")
    if len(parts) < 2 or len(set(parts)) != 1:
        return None
    return detmap.get(("CL|" if key.startswith("CL|") else "") + parts[0])


# The Islamweb pages carry marginal prose - a running footer, the farsh legend, footnotes -
# typeset in Naskh faces the Quranic text never uses. Nearly every glyph of it already
# resolves to nothing, but three keys learned a letter anyway: the footer alone put a stray
# `ل` word into 603 warsh ayahs and a stray fatha into 3,615 ayahs across the other volumes,
# which is 531 of warsh's 1,162 rasm diffs on its own. Scripture is only ever set in the
# HQPB*, Hamd*, Hamdy* and MSH* faces, so a glyph in a note face is not text.
NOTE_FACES = ("DecoType", "DTnaskh", "TraditionalArabic")


def is_marginalia(key):
    """True when a glyph key's face is one of the page's note faces."""
    parts = key.split("||", 1)[0].split("|")
    return len(parts) > 1 and parts[1].startswith(NOTE_FACES)


_PAUSE_RX = re.compile("[\u06d6-\u06db]")

def _is_pause_glyph(k, detmap):
    b = detmap.get(k)
    return bool(b) and all(c in _PAUSE_SET for c in b)

def _sane_rule(k, val, detmap):
    """A waqf sign may only come from a glyph that IS a waqf sign.

    The Madani learner was taught from QiraahQaloon, whose waqf layer is degenerate: 9,942
    U+06D6 and nothing else, one on nearly every ayah-final word. So it learned 170 rules
    of the form "this letter, at the end of the ayah, is `ىۖ`" and both Abu Ja'far
    volumes shipped with a `ۖ` on 1,766 of their 6,214 ayah ends that the page never
    draws (Hafs has two). The sign is stripped out of any emission whose glyph is not
    itself a pause glyph; a rule that says nothing else afterwards is skipped."""
    if not val or not _PAUSE_RX.search(val) or _is_pause_glyph(k, detmap):
        return val
    val = _PAUSE_RX.sub("", val)
    return val if val else None


def render_det(glyphs, detmap, missing=None, family="kufi", ctx=None, slug=None,
               cols=None, trace=None):
    """`cols` is extract.raw_colors()' entry for this ayah - one member-colour list per
    glyph slot. When given, `trace` is filled with the PRE-normalisation string and a
    per-character 0xRRGGBB array, which is how the print's own colour layer reaches the
    tajweed builder. The colours ride a parallel list rather than a third tuple field so
    that nothing which reads `out` has to change; the roundtrip proves the text is
    unmoved."""
    keys = [("sp| " if f == "sp" else f"{f}|{c}") for f, c in glyphs]
    def _slot_colour(i):
        # A cluster is one printed letter, and its members agree on colour in all but 4
        # of 688,816 slots, so "the inked member, if any" is the letter's own colour.
        if not cols or i >= len(cols):
            return 0
        for v in (cols[i] or []):
            if v:
                return v
        return 0
    out, ocol = [], []
    for i, k in enumerate(keys):
        col = _slot_colour(i)
        if k == "sp| ":
            out.append(("sp", " ")); ocol.append(0); continue
        if is_marginalia(k):
            out.append((k, "")); ocol.append(col); continue
        if k == "CL|HQPB5#20|1":
            out.append((k, "")); ocol.append(col)   # placeholder; the imalah pass above rewrites runs
            continue
        if k.startswith("CL|") and "HQPB5#20|1" in k and k != "CL|HQPB5#20|1":
            # letter cluster carrying its imalah dot (geometric attachment): resolve
            # the letter without the dot, then put the dot right after it
            members = [m for m in k[3:].split("||") if m != "HQPB5#20|1"]
            base_key = "CL|" + "||".join(members)
            bv = None
            if ctx is not None and base_key in ctx:
                r = ctx[base_key]
                pv = keys[i - 1] if i > 0 else "^"
                nx = keys[i + 1] if i + 1 < len(keys) else "$"
                bv = r.get(f"b:{pv}|{nx}") or r.get(f"p:{pv}") or r.get(f"n:{nx}") or r.get("*")
            if bv is None:
                bv = detmap.get(base_key)
            if bv is None:
                # The letter under the dot can be re-coded too; see GIDFALLBACK.
                bv = GIDFALLBACK.get(family, {}).get(gid_signature(base_key))
            if bv is not None:
                out.append((k, bv + imalah_mark(family))); ocol.append(col)
                continue
        if k in ("CL|HQPB5#7|$", "CL|MSH-Quraan1#35|\u2245") and family != "kufi":
            # MSH-Quraan1#35 is the farsh layer's copy of the same sign, drawn in magenta
            # on a wasl alef that Hafs reads with a hamza (`فَٱتَّبَعَ` 18:85, `فَٱسۡرِ`
            # 15:65, `ٱتَّخَذۡنَٰهُمۡ` 38:63) and on the jalalah of 23:87/89 (`ٱللَّهُ`
            # for Hafs's `لِلَّهِ`): the page saying "a sign belongs HERE".
            # The print DRAWS the wasl sign here and this glyph is where it draws it.
            # Emitting nothing threw that away and left the word-keyed repair to guess
            # from the skeleton, which cannot tell `ا۪ذۡ` from `إِذۡ` or `اَ۬لَا` from
            # `إِلَّا` and so refuses both. Carrying a marker through instead keeps the
            # one fact only the page has - that a sign belongs HERE - and lets the
            # skeleton table answer the much easier question of which sign it is.
            out.append((k, WASL_MARK)); ocol.append(col)
            continue
        v = None
        if ctx is not None and k in ctx:
            r = ctx[k]
            pv = keys[i - 1] if i > 0 else "^"
            nx = keys[i + 1] if i + 1 < len(keys) else "$"
            for kk in (f"b:{pv}|{nx}", f"p:{pv}", f"n:{nx}", "*"):
                if kk in r:
                    v = _sane_rule(k, r[kk], detmap)   # see _sane_rule
                    if v is not None:
                        break
        if k in ZONEFLIP:
            zv = ZONEFLIP[k]         # geometry beats the learner; see ZONEFLIP
            # ...but only where the learner contradicts the geometry. A flat override
            # throws away the key's CORRECT context rules along with its wrong ones:
            # `HQPB4#35` is a kasratain drawn with the small saad-lam-alef pause sign, and
            # its ctx knows to emit `ٍۖ` word-finally and `ٍ` before a space. Pinning the
            # bare `ٍ` deleted that sign from 33 words a Madani volume. A ctx rule that
            # already sits on the right side of the baseline is knowledge this pass does
            # not have, so leave it alone; only a rule on the WRONG side gets replaced.
            if not isinstance(zv, dict) and v is not None:
                zz = _zone_of_emission(zv)
                if zz is not None and _zone_of_emission(v) == zz:
                    zv = None
        if k in ZONEFLIP and zv is not None:
            if isinstance(zv, dict):
                # One outline, two jobs, split by POSITION - the same shape as the
                # ishmam dot below. HQPB5#128 is the only one so far: word-finally it
                # is the alef of `لَا` / `إِلَّا`, and anywhere else it is the shadda
                # + fatha of `فَضَّلۡتُكُمۡ` / `اَ۬لضَّآلِّينَ` / `وَاَلرُّكَّعِ`.
                # Adjudicated over both Yaqub volumes against the verified Duri text:
                # 1,475 word-final occurrences all want the alef and 145 interior ones
                # all want the shadda, with NO context seeing both answers. A flat
                # value cannot express that, and the learner cannot find it either -
                # the glyph appears 850 times per Yaqub volume against 4 in the whole
                # of duriabiamr, so the bridges have nothing to teach from.
                # "word-final" means end of the AYAH STREAM or a following space -
                # render_det is handed a whole ayah, in which words are separated by
                # `sp| ` tokens, so testing only `i + 1 >= len(keys)` marks just the
                # last word of the ayah and silently takes the interior branch for
                # every other one (`وَلَٰكِن لَّا` came out `وَلَٰكِن لَّ`).
                last = i + 1 >= len(keys) or keys[i + 1] == "sp| "
                # ...and a letter that ALREADY carries its shadda cannot be taking a
                # second one, so an interior occurrence there is the alef after all:
                # `تَوَلَّاهُ` (22:4), where the lam's shadda comes from its own glyph.
                if not last and out and "\u0651" in (out[-1][1] or ""):
                    last = True
                v = zv.get("$" if last else "*", zv.get("*"))
            else:
                v = zv
        if any(g in k for g in ISHMAM_GIDS):
            v = ishmam_dot(out)      # one dot, two jobs; see ishmam_dot
        if v == "" and k != "sp| ":
            # A ctx rule may blank a MARK (a stray layer copy) but never a LETTER: a letter
            # that is printed is a letter that is read. Across the Kufi map only 34 rules on
            # 14 letter keys do this, against 1,800+ that keep the letter, and they cost
            # real words: 3 of HQPB2#179's 117 rules deleted the ya of `يَٰبُنَيَّ`.
            base = detmap.get(k)
            # "contains a letter", not "is nothing but letters": `لَ` is a lam that also
            # carries its fatha, and testing the whole emission for combining characters
            # excluded every vowel-bearing ligature from the protection. One rule on
            # `CL|HQPB2#90|ξ` was deleting the lam of `إِصۡلَاحٞ` in eight volumes.
            if base and any(not unicodedata.combining(c) for c in base):
                # ...unless a NEIGHBOUR already draws that letter. A ligature hands its
                # letters to one glyph and blanks the other, so restoring the blanked one
                # doubles them: `لَّأُكَفِّرَنَّ` (5:12) came out with a second alef in
                # front, `أَخَذتُّهَا` (22:48) with a second one behind. Only a letter
                # that NOTHING beside it prints is a letter the page lost.
                want = {c for c in base if not unicodedata.combining(c)}
                def _peek(j):
                    """The value glyph j resolves to, by the same order render uses."""
                    if j < 0 or j >= len(keys) or keys[j] == "sp| ":
                        return None
                    k2 = keys[j]
                    if ctx is not None and k2 in ctx:
                        r2 = ctx[k2]
                        p2 = keys[j - 1] if j else "^"
                        n2 = keys[j + 1] if j + 1 < len(keys) else "$"
                        for kk2 in (f"b:{p2}|{n2}", f"p:{p2}", f"n:{n2}", "*"):
                            if kk2 in r2:
                                return r2[kk2] or ""
                    return detmap.get(k2) or ""
                # Walk PAST the marks on either side: the ligature's letters can sit a
                # mark away (`أَخَذتُّهَا` 22:48 draws the fatha between the blanked alef
                # and the glyph that carries it).
                near = ""
                for step in (-1, 1):
                    j = i + step
                    while True:
                        pv2 = _peek(j)
                        if pv2 is None:
                            break
                        near += pv2
                        if any(not unicodedata.combining(c) for c in pv2):
                            break
                        j += step
                if not want <= set(near):
                    v = base
        if v is None:
            v = _sane_rule(k, detmap.get(k), detmap)
        if v is None:
            # A cluster of ONE glyph drawn on top of itself is that glyph. The page stacks
            # a second copy of a mark on the first often enough that five such keys were
            # still unread, and every one of them is a mark the single key already knows:
            # `HQPB2#155||HQPB2#155` is the dagger alef of `ٱلرَّحۡمَٰنِ`, `HQPB2#158||HQPB2#158`
            # the small yeh of `بِهِۦ`. Abu read three of the five off the page and agreed
            # with the single key in all three, so take the single key's answer rather than
            # asking the learner to relearn one glyph twice. Only an all-identical cluster
            # qualifies: a mixed one is a real ligature and means something else.
            v = _repeat_cluster(k, detmap)
        if v is None:
            # Same glyph, unfamiliar cmap code. See GIDFALLBACK in build_detmap.
            v = GIDFALLBACK.get(family, {}).get(gid_signature(k))
        if v is None and k.startswith(("CL|TraditionalArabic", "CL|DecoType")):
            v = ""    # aux layer with zero aligned evidence = margin furniture
        if v and k.startswith(("CL|TraditionalArabic", "CL|DecoType")) and all(c in "َُِٗany" or c in "ًٌٍَُِ" for c in v):
            v = ""    # aux layers never draw tashkeel; those votes are alignment slop
        pin = ctxpin(family, k, keys[i - 1] if i > 0 else "^",
                     keys[i + 1] if i + 1 < len(keys) else "$")
        if pin is not None:
            v = pin
        if v is None:
            if missing is not None: missing[k] += 1
            out.append((k, "✗")); ocol.append(col)
        else:
            if v and _is_ease_glyph(k):
                v = v + EASE_MARK          # see EASE_MARK
            out.append((k, v)); ocol.append(col)
    _weld_ligature_alef(out)
    # Imalah dot (U+065C): glyph HQPB5 gid 20, drawn in ~3 layers per dot. A run of
    # tokens = round(len/3) dots, belonging UNDER the letters immediately before the
    # run (the print stacks them after the word's letters in x-order). Handled before
    # the dup-collapse below, which would otherwise eat the whole run.
    IMALAH_KEY = "CL|HQPB5#20|1"
    if any(k == IMALAH_KEY for k, _ in out):
        merged, mcol = [], []
        i = 0
        while i < len(out):
            if out[i][0] == IMALAH_KEY:
                j = i
                while j < len(out) and out[j][0] == IMALAH_KEY:
                    j += 1
                ndots = max(1, round((j - i) / 3))
                # The run is the dot drawn once per colour layer; the inked copy is the
                # one the page shows (this is where the red imalah dot gets its colour).
                dotcol = next((ocol[x] for x in range(i, j) if ocol[x]), 0)
                placed = 0
                p = len(merged) - 1
                while p >= 0 and placed < ndots:
                    vv = merged[p][1]
                    if vv and vv != " " and not unicodedata.combining(vv[0]):
                        merged.insert(p + 1, (IMALAH_KEY, imalah_mark(family)))
                        mcol.insert(p + 1, dotcol)
                        placed += 1
                    p -= 1
                if placed == 0:
                    merged.append((IMALAH_KEY, imalah_mark(family))); mcol.append(dotcol)
                i = j
            else:
                merged.append(out[i]); mcol.append(ocol[i])
                i += 1
        out, ocol = merged, mcol

    # SAME-key consecutive identical mark = stroke+fill double-draw → drop the copy.
    # DIFFERENT keys emitting the same single vowel adjacently = kasra+shadda pair
    # whose shadda glyph was EM-confused with the vowel → the second IS the shadda.
    VOWELS = {"ِ", "َ", "ُ"}
    fixed, fcol = [], []
    for _i, (k, v) in enumerate(out):
        col = ocol[_i]
        if fixed:
            pk, pv2 = fixed[-1]
            # Letters double-draw as well (stroke pass then fill pass), which the
            # combining-only rule below cannot see: `جَبۡرَءِيلَ` came out `جَبۡرَءءِيلَ` and
            # `وَمِيكَٰٓـِٔيلَ` came out `وَمِيكَٰٓـِٔيلَاا` off a triple-drawn alef. The SAME glyph
            # key twice running is the signal: a real doubled letter in this text is written
            # with a shadda, and where two letters genuinely do abut they take different
            # contextual forms, hence different gids.
            if k == pk and v == pv2 and v and not unicodedata.combining(v[0]):
                if col and not fcol[-1]: fcol[-1] = col   # keep the inked copy's colour
                continue
            if v == pv2 and v and unicodedata.combining(v[0]) and len(v) == 1:
                if k == pk:
                    if col and not fcol[-1]: fcol[-1] = col
                    continue                    # double-draw artifact
                if v in VOWELS:
                    fixed[-1] = (pk, "ّ" + pv2)  # shadda glyph + vowel; app orders shadda FIRST
                    if col and not fcol[-1]: fcol[-1] = col
                    continue
        fixed.append((k, v)); fcol.append(col)
    if trace is not None:
        pre, precol = [], []
        for (_k, v), c in zip(fixed, fcol):
            v = v.replace(EASE_MARK, "")
            pre.append(v); precol.extend([c] * len(v))
        trace["pre"] = "".join(pre)
        trace["precol"] = precol
    t = reorder_shadda(compose_hamza(
        re.sub(r"\s+", " ", "".join(v for _, v in fixed)).strip()))
    if family == "kufi":
        for dg in ("ٱا", "اٱ", "ٱٱ"):
            t = t.replace(dg, "ٱ")   # wasla-sign glyph + bare-alef glyph = ONE ٱ
        # الله/لله ligature: the lam strokes are VECTOR ART (not text glyphs); only the
        # alef/heh print as text. 'ٱَ' and a standalone 'هِ' word cannot otherwise occur.
        ALLAH_LL = "\u0644\u0644\u0651\u064e"          # ل ل ّ َ  (shadda before vowel)
        # ...but only where a heh actually follows. `اَ` at the END of a word is the
        # accusative alef with its fatha drawn after it (`أَخَذۡتُهَا` 22:48, `ٱلسَّبِيلَا۠`
        # 33:67), and rewriting that to `ٱللَّ` invented a jalalah inside two words.
        for pat in ("\u0671\u064e", "\u0627\u064e"):     # ٱَ / اَ - impossible except in الله
            t = re.sub(re.escape(pat) + "(?=\u0647)", "\u0671" + ALLAH_LL, t)
        for pat in ("\u0671\u06e1", "\u0627\u06e1"):     # ٱۡ / اۡ - sukun of the INVISIBLE lam
            t = t.replace(pat, "\u0671\u0644\u06e1")      # ٱلۡ
        # `وَلَٰكِنِ ٱللَّهُ` (8:17) is a Hamzah farsh word, so the print highlights it and draws
        # the lam's shadda-fatha as its own glyph ON TOP of the ٱَ pair the rule above
        # already expands to للَّ. That leaves the heh carrying two vowels; it carries one,
        # and the second is the real one (the page reads ٱللَّهُ, not ٱللَّهَ).
        t = re.sub("(\u0671\u0644\u0644\u0651\u064e\u0647)[\u064b-\u0650]([\u064b-\u0650])",
                   r"\1\2", t)
        LILLAH_CORE = "\u0644\u0650" + ALLAH_LL + "\u0647"   # لِلَّه
        # A word that prints as a bare heh is `لله` with its two lams drawn as vector art.
        # Matching the LETTER SKELETON rather than the whole token lets the vowels, the
        # shadda an idgham drops on the prefix (`وَّلِلَّهِ` 2:115, 13:15) and a trailing
        # pause sign (`لِلَّهِۚ` 23:85) ride along instead of missing the table.
        # The tail is matched as one run rather than vowel-then-sign: `pause_to_word_end`
        # has already run, so `لِلَّهِۚ` (23:85) arrives as heh + sign + kasra.
        _LIL = re.compile("^([\u0648\u0641]?[\u064b-\u0652\u0670]*)\u0647"
                          "([\u064b-\u0652\u0670\u06d6-\u06dc\u06e9\u06ed]*)$")
        _VOW = set("\u064b\u064c\u064d\u064e\u064f\u0650")
        def _lillah(w):
            if "\u0647" not in w:
                return w
            m = _LIL.match(w)
            if not m or not (_VOW & set(m.group(2))):
                return w
            return m.group(1) + LILLAH_CORE + m.group(2)
        t = " ".join(_lillah(w) for w in t.split(" "))
        # `ءَآللَّهُ` (10:59, 10:'59, 27:59) prints its two lams as vector art too, but it is
        # the jalalah with the interrogative alef in front, not `لله`, so it takes the
        # doubled lam rather than the `لِ` prefix.
        t = re.sub("^(\u0621\u064e\u0627\u0653?)\u0647([\u064b-\u0652])$",
                   "\\1" + ALLAH_LL + "\u0647\\2", t)
        t = " ".join(re.sub("^(\u0621\u064e\u0627\u0653?)\u0647([\u064b-\u0652])$",
                            "\\1" + ALLAH_LL + "\u0647\\2", w) for w in t.split(" "))
        t = t.replace("\u0644\u0650\u0644\u0644", "\u0644\u0650\u0644")  # لِلل → لِل
    t = t.replace("\u0657\u0627\u0627", "\u0657\u0627").replace("\u064b\u0627\u0627", "\u064b\u0627").replace("\u0648\u0627\u0627", "\u0648\u0627")
    t = pause_to_word_end(t)
    t = collapse_doubled_marks(t)
    # `لِّأُوْلِي`: the double-drawn damma on the hamza is read as a shadda by the rule
    # above, but a hamza never carries a shadda in any verified text (0 of 8) - it is the
    # lam's, the idgham of the tanween before it. Move it.
    t = _HAMZA_SHADDA_RX.sub(lambda m: "\u0644\u0651" + m.group(1) + "\u0623" + m.group(2) + m.group(3), t)
    t = attach_orphan_marks(t)
    t = repair_broken_tokens(t, family)
    t = seat_imalah_dot(t)
    t = reorder_dagger(t)
    t = seat_dagger(t)
    t = strip_impossible_marks(t)
    t = canonical_mark_order(t)
    t = weld_bare_alef(t)
    t = maqsura_rule(t, family)
    if family == "kufi":
        t = apply_wasla_rule(t)   # kufi convention: word-initial bare alef is ٱ
    else:
        t = apply_family_conventions(t, family, MADD_TEXT.get(slug))
    t = t.replace(EASE_MARK, "")
    # `فَٱدَّٰرَأْتُمۡ` (2:72): all seven verified texts, and only there, write the sukoon on
    # the hamza as U+0652 - the single `أْ` in each of them against ~485 `أۡ`. One word,
    # one codepoint, matched so comparison mode does not show a phantom difference.
    t = _DARATUM_RX.sub("\\1\u0652\\2", t)
    # Last, because the Madani conventions above re-introduce it: `اُ۬لَارۡضَ` is spelled
    # with a wasl alef AND the lam-alef ligature's own alef, and the pair survives as `اا`.
    # No verified text writes two bare alefs in a row.
    return t.replace("\u0627\u0627", "\u0627")


# ---------------------------------------------------------------- context pass

def ctxpass(fam, bridge_slugs):
    """Deterministic neighbor-conditioned rules for keys the flat map can't decide
    (coupled pairs like kasra/shadda, ya-skeleton/dots, ligature layers). Learned by
    re-aligning bridge volumes against their app texts with the current emissions,
    then keeping only high-purity (prev,key,next)-conditioned emissions."""
    import math
    from extract import overlay, BRIDGES
    counts = json.loads((DATA / f"glyphcounts-{fam}.json").read_text())
    detmap = build_detmap(fam)
    # target keys: anything ambiguous, unmapped-in-render, or from the aux layers
    targets = set()
    amb = json.loads((DATA / f"detamb-{fam}.json").read_text())
    targets |= set(amb.keys())
    for k in counts:
        if k.startswith(("CL|TraditionalArabic", "CL|DecoType", "CL|Hamd")):
            targets.add(k)
    # Glyphs the zone audit proved are mismapped: their ink sits on the wrong side of
    # the baseline for the mark they emit (a kasra is drawn below, a shadda above), so a
    # high "purity" score here only means the EM learned one wrong answer confidently.
    # They MUST be targets, otherwise the pinning below freezes the error in place.
    zb = DATA / "zonebad.json"
    if zb.exists():
        bad = set(json.loads(zb.read_text()))
        targets |= bad
        print(f"{fam}: +{len(bad)} zone-violating keys forced into the target set")

    # low-purity flat keys too
    for k, dist in counts.items():
        items = sorted(dist.items(), key=lambda x: -x[1])
        tot = sum(dist.values())
        if len(items) >= 2 and items[0][1] / tot < 0.90:
            targets.add(k)

    class _EM:
        def __init__(self, c, pinned=None):
            self.p = {}
            self.pinned = pinned or {}
            for k, dist in c.items():
                tot = sum(dist.values())
                self.p[k] = {e: math.log(n / (tot + 2)) for e, n in dist.items()}
        def logp(self, key, e):
            # a key the deterministic map already solved is PINNED: aligning it to
            # anything else is heavily punished, which snaps the whole alignment tight
            # around the few genuinely unknown keys
            v = self.pinned.get(key)
            if v is not None and v != "":
                return -0.05 if e == v else -13.0
            d = self.p.get(key)
            if d is not None and e in d:
                return d[e]
            if key == "sp| ":
                return math.log(0.8) if e == " " else (math.log(0.15) if e == "" else -16.0)
            L = len(e)
            return (-7.5, -6.2, -8.5, -10.5, -12.5)[L] if L <= 4 else -13.5 - L

    import hybrid
    old_em = hybrid.ALIGN_EM
    pinned = {k: v for k, v in detmap.items() if k not in targets}
    hybrid.ALIGN_EM = _EM(counts, pinned=pinned)
    obs = collections.defaultdict(collections.Counter)   # (key,prev,next) -> emissions
    flat = collections.defaultdict(collections.Counter)
    # Pair through collect_pairs, WITH the correspondence check: an ayah paired against
    # the wrong text teaches every target key in it a wrong emission, and the rules built
    # below are exactly what freezes that in place. See extract.PAIR_CUTOFF.
    from extract import collect_pairs
    prev_ctx_p = DATA / f"ctxdet-{fam}.json"
    prev_ctx = json.loads(prev_ctx_p.read_text()) if prev_ctx_p.exists() else {}
    pairs = collect_pairs(bridge_slugs,
                          render=lambda g: render_det(g, detmap, None, fam, prev_ctx))
    for glyphs, text, slug, sid, aid, first in pairs:
        keys = [("sp| " if f == "sp" else f"{f}|{c}") for f, c in glyphs]
        if not any(k in targets for k in keys):
            continue
        spans = hybrid.align_surah(keys, text, band=50)
        if spans is None: continue
        for i, k in enumerate(keys):
            if k not in targets: continue
            e = text[spans[i][0]:spans[i][1]]
            pv = keys[i - 1] if i > 0 else "^"
            nx = keys[i + 1] if i + 1 < len(keys) else "$"
            obs[(k, pv, nx)][e] += 1
            flat[k][e] += 1
    hybrid.ALIGN_EM = old_em
    rules = {}
    for k in targets:
        r = {}
        pv_tab = collections.defaultdict(collections.Counter)
        nx_tab = collections.defaultdict(collections.Counter)
        for (kk, pv, nx), ctr in obs.items():
            if kk != k: continue
            e, n = ctr.most_common(1)[0]
            if n >= 1 and n / sum(ctr.values()) >= 0.85:
                r[f"b:{pv}|{nx}"] = e            # exact-pair rule (strongest)
            pv_tab[pv].update(ctr)
            nx_tab[nx].update(ctr)
        for tag, tab in (("p", pv_tab), ("n", nx_tab)):
            for nb, ctr in tab.items():
                e, n = ctr.most_common(1)[0]
                if n >= 2 and n / sum(ctr.values()) >= 0.85:
                    r[f"{tag}:{nb}"] = e
        if flat[k]:
            e, n = flat[k].most_common(1)[0]
            # `*` is the catch-all and it OVERRIDES the deterministic map, so it needs
            # real support, not just purity. With no floor a single observation scored
            # 100% pure and won: `CL|HQPB4#52|R` is `َۢ` in the detmap on 40 occurrences
            # and one stray alignment gave it a `*` of `اَ`, which shipped `تَوَّاباَا`
            # for `تَوَّابَۢا` in every volume of the family. The `p:`/`n:` rules already
            # require 2; the catch-all should be at least as hard to earn.
            if n >= 3 and n / sum(flat[k].values()) >= 0.70:
                # A context-free `*` that CONTRADICTS the deterministic map is claiming
                # the map's majority is simply wrong, so it has to bring at least as much
                # evidence. `CL|HQPB4#52|R` is one rung of the iqlab ladder (HQPB4 41-52,
                # one fatha-plus-small-meem outline at ten stack heights, verified by
                # rendering all ten); the map reads it `َۢ` on 110 occurrences and six
                # stray alignments gave it a `*` of `اَ`, which shipped `تَوَّاباَا` for
                # `تَوَّابَۢا`. Pinning the whole ladder in ZONEFLIP instead measures
                # WORSE everywhere (shubah 97.84 -> 97.70), so the alef is real in some
                # positions and the answer here is evidence, not geometry.
                dv = detmap.get(k)
                if e == dv or dv is None or n >= counts.get(k, {}).get(dv, 0):
                    r["*"] = e
        if r:
            rules[k] = r
    (DATA / f"ctxdet-{fam}.json").write_text(json.dumps(rules, ensure_ascii=False, sort_keys=True))
    print(f"{fam}: ctx rules for {len(rules)}/{len(targets)} target keys")
    return rules

# ------------------------------------------------- family conventions (madani/basri)

FAMILY_BRIDGE_TEXT = {"madani": "QiraahQaloon", "basri": "QiraahDuri", "makki": "QiraahQunbul"}
# Madd munfasil is riwayah-specific, so the madd repair in _family_tables cannot be learned
# from a bridge that reads it differently from the target. Duri Abu Amr reads munfasil long
# and his text carries 5,549 maddahs; the Islamweb Ruways and Rawh volumes DRAW 2,202 and
# 2,187, the same band as the two Abu Ja'far volumes at ~2,183 and nowhere near the ~5,500
# of every Kufi and Shami volume. Learning MADD off Duri put 2,728 maddahs into Ruways and
# 2,746 into Rawh that the page does not have, against a 142-211 top-up everywhere else.
# Susi is the Basri text that reads qasr, so the madd table alone comes from him; wasl,
# Allah-words and nun-idgham stay on Duri, because Susi's idgham kabir is his own and
# Yaqub does not read it.
#
# The susi BRIDGE needed the same treatment and was the only Basri volume still left on
# Duri: its page draws 2,150 maddahs, Duri's text carries 5,549, and the gap showed up as
# 2,721 spurious maddahs - by itself 74% of susi's roundtrip diffs, burying every class
# underneath. Self-sourcing makes susi's madd contribution to its own score circular, the
# way ruways and rawh already are; what the number still tests is every other layer.
MADD_TEXT = {"ruways": "QiraahSusi", "rawh": "QiraahSusi", "susi": "QiraahSusi"}
_conv_cache = {}
WASL_MARK = "\ufdd0"                  # noncharacter: never survives a render
# A second noncharacter, for the alef that stands in for an EASED second hamza. The Madani
# and Basri prints draw it as its own glyph - Hamd2#3 is the alef with the dot below
# (`هَٰؤُلَآءِ ا۪ن` for Hafs's `إِن`, `تَفِيٓءَ ا۪لَىٰ`), Hamd2#8/#9 the alef with the dot above
# (`ءَا۬نذَرۡتَهُمۡ`, `جَآءَ ا۬جَلُهُمۡ`) - and the seven verified texts write exactly those
# marks. But the same two codepoints are also the wasl signs, which `apply_family_conventions`
# strips and re-derives from its tables, so every eased hamza was losing its dot and 44
# words a Madani volume shipped as `ان` / `اذۡ`. The marker rides the word through the
# conventions (which leave a marked word alone) and is removed at the end of render_det.
EASE_MARK = "\ufdd1"
# Hamd2#76 is the Madani books' one-glyph `ءَٰا۬` (hamza, idkhal alef, eased second hamza)
# of `ءَٰا۬نذَرۡتَهُمۡ`, `ءَٰا۬نتُمۡ`, `ءَٰا۬سۡلَمۡتُمۡ`, `ءَٰا۬لِدُ` (11:72): 21 words a volume.
EASE_GLYPHS = ("CL|Hamd2#3|", "CL|Hamd2#7|", "CL|Hamd2#8|", "CL|Hamd2#9|", "CL|Hamd2#76|")

def _is_ease_glyph(k):
    return any(k.startswith(g) or ("||" + g[3:]) in k for g in EASE_GLYPHS)
_WASL_SIGNS = "\u06ec\u06ea"          # ۬ dot-above, ۪ dot-below
# U+06DF joins them wherever a sign is being IDENTIFIED rather than stripped
_ALL_WASL_SIGNS = "\u06ec\u06ea\u06df"
_PAUSE_SET = set("\u06d6\u06d7\u06d8\u06d9\u06da\u06db")
_NAQL_FOLD = {"\u0624": "\u0648", "\u0626": "\u064a", "\u0623": "\u0627",
              "\u0625": "\u0627", "\u0622": "\u0627", "\u0671": "\u0627"}

def _naql_sk(w):
    """Consonant skeleton with the hamza seats folded to their ibdal letters."""
    return "".join(_NAQL_FOLD.get(ch, ch) for ch in w
                   if not unicodedata.combining(ch) and ch not in "\u0640" and ch not in _WASL_SIGNS)

def _family_tables(family, madd_name=None):
    """Learn, from the family's OWN verified app text: (a) wasl-alef prefix forms keyed
    by (previous word's final char, rest-of-word), (b) Allah-word forms by skeleton,
    (c) nun-idgham junction forms keyed by (bare-final word, next word's first letter)."""
    ck = (family, madd_name)
    if ck in _conv_cache:
        return _conv_cache[ck]
    import collections as _c
    name = FAMILY_BRIDGE_TEXT[family]
    d = json.loads((APP / f"Resources/JSONs-Deprecated/Qiraat/{name}.json").read_text())
    madd_name = madd_name or name
    madd_d = d if madd_name == name else json.loads(
        (APP / f"Resources/JSONs-Deprecated/Qiraat/{madd_name}.json").read_text())
    wasl = _c.defaultdict(_c.Counter)      # (prev_last, stripped) -> full word
    allah = _c.defaultdict(_c.Counter)     # skeleton -> full word
    idgh = _c.defaultdict(_c.Counter)      # (prev_stripped_suffix, next_first) -> (prev_full, next_prefix)
    sign_of = _c.defaultdict(_c.Counter)   # naql skeleton -> which wasl sign it takes
    alef_initial = _c.Counter()            # naql skeleton -> alef-initial occurrences
    def _sk(w):
        return "".join("ا" if ch in "اٱأإآ" else ch for ch in w
                       if not unicodedata.combining(ch) and ch not in "ـ" and ch not in _WASL_SIGNS)
    for v in d.values():
        for a in v:
            ws = a["text"].split()
            for i, w in enumerate(ws):
                prev = ws[i - 1] if i else ""
                prev_last = prev[-1] if prev else "^"
                wp = "".join(ch for ch in w if ch not in _PAUSE_SET)
                # _ALL_WASL_SIGNS, not _WASL_SIGNS: leaving U+06DF out meant the ~120
                # `اُ۟عۡبُدُواْ`-type imperatives were never learned at all, so the sign
                # table had no entry for them and the page-marked fallback below handed
                # them U+06EC instead (134 words per Madani volume).
                if wp and wp[0] == "ا" and len(wp) > 2 and (wp[1] in "\u064e\u064f\u0650" and wp[2] in _ALL_WASL_SIGNS):
                    stripped = "ا" + wp[3:]
                    wasl[(prev_last, stripped)][wp] += 1
                    wasl[("*", stripped)][wp] += 1
                    # Skeleton-keyed fallback: the naql vowel and its dot, keyed by the
                    # previous word's last character and the word's HAMZA-NORMALISED
                    # consonant skeleton. Abu Jafar reads the ibdal forms, so his
                    # `الۡمُومِنِينَ` never matches Qaloon's `اَ۬لۡمُؤۡمِنِينَ` on the exact
                    # string and went unrepaired 59 times over; on the skeleton it matches,
                    # and the answer comes from the verified text rather than a guess.
                    wasl[("sk", prev_last, _naql_sk(stripped))][wp[1:3]] += 1
                    wasl[("sk", "*", _naql_sk(stripped))][wp[1:3]] += 1
                    # Which of the three wasl SIGNS a word takes is lexical, not
                    # contextual: across 10,774 occurrences in this text only one word
                    # (`اتبعوا`, 11 to 1) ever takes two, so the skeleton decides it.
                    # The vowel is the opposite - see carried_vowel - and splitting the
                    # two lets each be answered by the thing that actually knows.
                    sign_of[_naql_sk(stripped)][wp[2]] += 1
                # The homograph guard must count the word by the SAME folded skeleton the
                # sign table is keyed by, hamza seats included: `أَلِيمٞ` folds to the
                # skeleton of a wasl word, and counting only bare-alef words let it look
                # unambiguous and take a sign it never has (64 words per Warsh volume).
                if wp and _NAQL_FOLD.get(wp[0], wp[0]) == "\u0627":
                    alef_initial[_naql_sk(wp)] += 1
                # madd-before-hamza: the app writes a trailing ٓ the print omits.
                # Harvested from madd_d below when that is a different text.
                if madd_d is d and "\u0653" in w[-3:]:
                    bare = w.replace("\u0653", "")
                    nxt0 = ws[i + 1][0] if i + 1 < len(ws) else "$"
                    idgh[("MADD", bare, nxt0)][(w, "")] += 1
                # prefixed wasl (وَا فَا بِا كَا): vowel-on-alef, no dot
                if len(w) > 3 and w[0] in "وفبكت" and w[1] == "\u064e" and w[2] == "ا" and w[3] in "\u064e\u064f\u0650":
                    stripped = w[:3] + w[4:]
                    wasl[("*", "".join(ch for ch in stripped if ch not in _PAUSE_SET))][
                        "".join(ch for ch in w if ch not in _PAUSE_SET)] += 1
                sk = _sk(w)
                # `ءالله` (10:59, 27:59), `وتالله` (21:57) and `اللهم` are jalalah words
                # whose lam pair is vector art exactly like the eight below; leaving them
                # out of the table is why `ءَآللَّهُ` shipped as `ءَآهُ` and `وَتَٱللَّهِ` as
                # `وَتَاهِ`. Every OTHER `لله` skeleton in the three bridge texts is a real
                # word that happens to contain the letters (`ظِلَٰلُهُم`, `ٱللَّهَبِ`,
                # `لِلۡهُدَىٰ`), so the set stays enumerated rather than matched by pattern.
                if sk in ("الله", "لله", "بالله", "والله", "تالله", "فالله", "ولله",
                          "فلله", "ابالله", "ءالله", "وتالله", "اللهم"):
                    # the print draws the lam pair as vector art: key by what the
                    # RENDER produces (lamless skeleton + the final vowel)
                    lamless = sk.replace("لل", "", 1)
                    final = next((ch for ch in reversed(wp) if True), "")
                    allah[(lamless, wp[-1] if wp else "")][wp] += 1
                # nun/tanwin idgham junction: word ends bare ن + next starts doubled letter
                if i + 1 < len(ws):
                    nxt = ws[i + 1]
                    if w.endswith("\u0646\u06e1") and len(nxt) > 2 and nxt[1] == "\u0651":
                        idgh[(w[:-1], nxt[0])][(w, nxt[:2])] += 1
                    elif w.endswith("\u0646") and len(nxt) > 2 and nxt[1] == "\u0651":
                        idgh[(w, nxt[0])][(w, nxt[:2])] += 1
    if madd_d is not d:
        for v in madd_d.values():
            for a in v:
                ws = a["text"].split()
                for i, w in enumerate(ws):
                    if "\u0653" in w[-3:]:
                        bare = w.replace("\u0653", "")
                        nxt0 = ws[i + 1][0] if i + 1 < len(ws) else "$"
                        idgh[("MADD", bare, nxt0)][(w, "")] += 1
    # A skeleton that ALSO occurs unannotated in this text is a homograph, and guessing a
    # sign onto it would be inventing one. Only the ones that always carry a sign are kept.
    for sk, ctr in sign_of.items():
        if alef_initial[sk] and sum(ctr.values()) / alef_initial[sk] >= 0.95:
            wasl[("sign", sk)] = ctr
        # The guard is only needed when we are GUESSING that a word takes a sign. Where
        # the page drew one, the homograph question is already settled and the skeleton
        # is being asked the far narrower question of which sign this word takes when it
        # takes one. `إِذۡ`/`ا۪ذۡ` and `أَوۡ`/`اَ۬وۡ` are both spellings of the same word
        # in the same text, and the print is what says which one is on this page.
        wasl[("signany", sk)] = ctr
    tables = (
        {k: c.most_common(1)[0][0] for k, c in wasl.items()},
        {k: c.most_common(1)[0][0] for k, c in allah.items()},
        {k: c.most_common(1)[0][0] for k, c in idgh.items()},
    )
    _conv_cache[ck] = tables
    return tables

def rep_pref(w, wasl_tab):
    return wasl_tab.get(("*", w))

def apply_family_conventions(t, family, madd_name=None):
    if family not in FAMILY_BRIDGE_TEXT:
        return t
    wasl_tab, allah_tab, idgh_tab = _family_tables(family, madd_name)
    # Wasl signs re-enter only via the learned tables, so the render's own are dropped
    # first. U+06EC is only ever the wasl sign and goes unconditionally.
    #
    # U+06EA does TWO jobs, though, and dropping it wholesale threw the second one away:
    # under a wasl alef it is a wasl sign, and under any other letter it is the taqlil dot
    # (see imalah_mark). The app's Warsh text carries 2,569 of them and only ~664 sit on a
    # wasl alef, so the blanket strip was deleting about 1,900 real marks per volume and
    # leaving the words bare - which read as "the print does not draw taqlil" and is why
    # the dot was being emitted as U+065C in the first place.
    # ...and not when an alef maqsura follows. That shape is the Madani print's `ا۪ىٰتِنَا`
    # family, where Hamdy2#167 DRAWS the dot under the alef and the small letter over the
    # bare tooth carries the vowel, so there is nothing for the learned table to put back
    # afterwards. Across all seven verified texts the lookahead costs exactly one word,
    # Susi's own `اَ۪ىتِ` at 10:15, which is one of these same words.
    # ...and never from a word carrying EASE_MARK: there the dot is the eased hamza the
    # page drew, not a wasl sign, and no table knows the word.
    def _strip_signs(w):
        if EASE_MARK in w:
            return w
        w = w.replace("\u06ec", "")
        return re.sub(r"^([\u0648\u0641\u0628\u0643\u062a\u0644]?[\u064e\u064f\u0650]?"
                      r"[\u0627\u0671][\u064b-\u0652\u0670]*)\u06ea(?!\u0649)", r"\1", w)
    t = " ".join(_strip_signs(w) for w in t.split(" "))
    words = t.split(" ")
    # the marker would stop every table below from matching, so take it out and remember
    # which words carried one
    marked = {i for i, w in enumerate(words) if WASL_MARK in w}
    words = [w.replace(WASL_MARK, "") for w in words]
    def _sk(w):
        return "".join("ا" if ch in "اٱأإآ" else ch for ch in w
                       if not unicodedata.combining(ch) and ch not in "ـ" and ch not in _WASL_SIGNS)
    out = []
    for i, w in enumerate(words):
        if EASE_MARK in w:
            out.append(w); continue          # the page's own spelling; see EASE_MARK
        # Allah-family words (lams are vector art in the print); the final vowel
        # disambiguates against ordinary words sharing the lamless skeleton (لَهُ)
        if "ه" in w and w:
            tail = "".join(ch for ch in w if ch in _PAUSE_SET)
            wp = "".join(ch for ch in w if ch not in _PAUSE_SET)
            # ...and a trailing sukoon, which is not part of the word either: 48:6 prints
            # a sukoon glyph of its own between `ٱللَّهُ` and `عَلَيۡهِمۡ`, attach_orphan_marks
            # hands it to the jalalah, and the table is keyed by the word's LAST character,
            # so `اَ۬للَّهُ` stopped being found and shipped as `اَ۬هُۡ`.
            while wp and wp[-1] in "\u0652\u06e1":
                tail = wp[-1] + tail
                wp = wp[:-1]
            rep = allah_tab.get((_sk(wp), wp[-1] if wp else ""))
            # `لِيَبۡلُغَ فَاهُ` (13:14) is the one real word in the Quran whose lamless
            # skeleton is a jalalah's: it shipped as `فَٱللَّهُ` in both Abu Ja'far volumes.
            if rep and len(wp) < len(rep) and not (out and _sk(out[-1]) == "\u0644\u064a\u0628\u0644\u063a"):
                out.append(rep + tail)
                continue
        # the lam of ال before a hamza letter is vector art: 'اأ/اإ/اءا' never occur
        for hz in ("\u0623", "\u0625", "\u0622"):
            w = w.replace("ا" + hz, "ا\u0644\u06e1" + hz)
        # wasl-alef prefix: rendered form is bare 'ا' + rest; the app form carries
        # naql vowel + dot chosen by the PRECEDING word's ending.
        #
        # Look the word up WITHOUT its waqf sign, and put the sign back afterwards.
        # `_family_tables` strips pause marks on both sides of every entry it learns, so a
        # word that ends in one could never match and never got repaired. That is 950 of
        # Ibn Wardan's 6,214 ayahs: `اِ۬لۡعَٰلَمِينَۖ` came out `الۡعَٰلَمِينَۖ`, the naql
        # vowel and its dot gone, while the identical word one ayah later repaired fine
        # because nothing followed it. Same for the وفبكت prefixes below.
        wtail = "".join(ch for ch in w if ch in _PAUSE_SET)
        wcore = "".join(ch for ch in w if ch not in _PAUSE_SET) if wtail else w
        if wcore and wcore[0] == "ا" and (len(wcore) < 2 or wcore[1] not in "\u064e\u064f\u0650"):
            prev_last = out[-1][-1] if out and out[-1] else "^"
            rep = wasl_tab.get((prev_last, wcore)) or wasl_tab.get(("*", wcore))
            if rep:
                out.append(rep + wtail)
                continue
            vd = (wasl_tab.get(("sk", prev_last, _naql_sk(wcore)))
                  or wasl_tab.get(("sk", "*", _naql_sk(wcore))))
            if vd:                       # skeleton match: prepend the learned vowel + dot
                out.append(wcore[0] + vd + wcore[1:] + wtail)
                continue
        if wcore and wcore[0] in "وفبكت" and rep_pref(wcore, wasl_tab) is not None:
            out.append(rep_pref(wcore, wasl_tab) + wtail)
            continue
        out.append(w)
    # madd-before-hamza junctions
    for i in range(len(out)):
        nxt0 = out[i + 1][0] if i + 1 < len(out) and out[i + 1] else "$"
        rep = idgh_tab.get(("MADD", out[i], nxt0))
        if rep:
            out[i] = rep[0]
    # nun-idgham junctions: the print writes plain ن + plain next initial; the app
    # convention writes نۡ + shadda on the next word's first letter. Learned pairs
    # are keyed by (the bare word, next word's first letter).
    for i in range(len(out) - 1):
        w, nxt = out[i], out[i + 1]
        if w.endswith("\u0646") and nxt:
            rep = idgh_tab.get((w, nxt[0]))
            if rep:
                full_prev, next_prefix = rep
                out[i] = full_prev
                if len(nxt) > 1 and nxt[1] != "\u0651":
                    out[i + 1] = next_prefix + nxt[1:]
    if os.environ.get('QIRAAT_NO_SIGN_REPAIR') != '1':
        out = restore_wasl_signs(out, wasl_tab, marked)
    if family == "madani":
        # Tanween with iqlab on a final alef is written `ـاَۢ` in the Madani texts and
        # `ـَۢا` in the Kufi and Basri ones: 87 words in Qaloon and 72 in Warsh take the
        # first order and NOT ONE takes the second, while Duri and Shubah are the exact
        # mirror. Same word, same sound, different house style, and the print draws one
        # glyph either way, so nothing in the glyph layer can decide it.
        # ...and the waqf sign sits AFTER it, so the rewrite has to look past one.
        out = [re.sub("\u064e\u06e2\u0627([\u06d6-\u06dc\u06de\u06e9]*)$",
                      "\u0627\u064e\u06e2\\1", w) for w in out]
    return fix_wasl_vowels(" ".join(out))

# ------------------------------------------------- wasl vowel

_WASL_VOWELS = "\u064e\u064f\u0650"                 # fatha, damma, kasra
_WASL_IGNORE = set("\u06d6\u06d7\u06d8\u06d9\u06da\u06db\u06dc\u06dd\u06de\u06e9"
                   "\u0652\u06ea\u06e0\u06ec\u06df\u0640")
_WASL_RX = re.compile("([\u0627\u0671])([\u064e\u064f\u0650])([\u06ea\u06ec\u06df])")

def carried_vowel(prev):
    """The vowel the sound BEFORE a wasl alef ends on.

    The vowel written on a wasl alef is not an independent choice: the notation is
    spelling out the join, so it is whatever you are already saying when you arrive.
    Audited over every occurrence in the three app texts that use it, the derivation
    below is right 10,541/10,546 times in Qaloon, 10,537/10,548 in Warsh and
    10,543/10,543 in Duri - and the handful it misses are muqatta'at and five
    U+06DF imperatives, not a rival rule.
    """
    ch = [c for c in prev if c not in _WASL_IGNORE and c != "\u065c"]
    for i in range(len(ch) - 1, -1, -1):
        c = ch[i]
        if c in _WASL_VOWELS:
            return c
        if c in "\u064b\u064c\u064d":
            return "\u0650"                            # tanween joins on a kasra
        if c == "\u0670":
            return "\u064e"                            # dagger alef
        if c in "\u0627\u0649\u0622":
            # a silent alef is not the sound: `قَالُوا` ends on the waw and `خَيۡرًا` on
            # its tanween; only a bare alef with nothing behind it is really a fatha
            if i:
                b = ch[i - 1]
                if b in "\u064b\u064c\u064d": return "\u0650"
                if b == "\u0648": return "\u064f"
                if b == "\u064a": return "\u0650"
                if b in _WASL_VOWELS: return b
            return "\u064e"
        if c == "\u0648": return "\u064f"
        if c == "\u064a":
            # an imalah'd final ya is a bent ALEF, so it carries a fatha, not a kasra
            return "\u064e" if i and ch[i - 1] == "\u065c" else "\u0650"
        return None
    return None


def restore_wasl_signs(words, wasl_tab, marked=()):
    """Put back a wasl sign the word-keyed repair could not place.

    The repair above matches a whole rendered word, so it does nothing at all for a word
    the print drew slightly differently from the bridge: `اعۡبُدُواْ` keeps no sign and no
    vowel, and `اَلَا` keeps the vowel but loses the dot. Between them that is 218 words
    per Madani volume. The sign is recoverable on its own, from the skeleton, and the
    vowel then follows from the context, so neither needs the exact string to match.

    Only skeletons that ALWAYS carry a sign in the bridge are repaired: a skeleton that
    also occurs unannotated there is a homograph and is left alone.
    """
    out = []
    for i, w in enumerate(words):
        tail = "".join(ch for ch in w if ch in _PAUSE_SET)
        core = "".join(ch for ch in w if ch not in _PAUSE_SET) if tail else w
        if (len(core) > 1 and core[0] in "\u0627\u0671"
                and not any(ch in _ALL_WASL_SIGNS for ch in core[:3])):
            sk = _naql_sk(core)
            sign = wasl_tab.get(("sign", sk))
            if sign is None and i in marked:
                # the page says a sign belongs here even though the skeleton is shared
                # with a hamzat-qat' word; U+06EC is 91% of all of them
                sign = wasl_tab.get(("signany", sk)) or "\u06ec"
            if sign:
                has_vowel = core[1] in "\u064e\u064f\u0650"
                vowel = core[1] if has_vowel else (carried_vowel(out[-1]) if out else None)
                if vowel:
                    rest = core[2:] if has_vowel else core[1:]
                    out.append(core[0] + vowel + sign + rest + tail)
                    continue
        out.append(w)
    return out

def fix_wasl_vowels(t):
    """Re-derive every wasl vowel from its context.

    The vowel otherwise comes out of `_family_tables`, which is keyed by the word and
    only sometimes by what precedes it, so a word that occurs in more than one context
    got whichever vowel was commonest. `ٱللَّه` occurs 2,699 times with all three, and
    that single word is 970 of qaloon's word diffs.
    """
    words = t.split(" ")
    for i, w in enumerate(words):
        if EASE_MARK in w:
            continue                          # the vowel is the hamza's own; see EASE_MARK
        def sub(m):
            ctxt = w[:m.start()] if m.start() else (words[i - 1] if i else "")
            v = carried_vowel(ctxt) if ctxt else None
            return m.group(1) + (v or m.group(2)) + m.group(3)
        words[i] = _WASL_RX.sub(sub, w)
    return " ".join(words)

# ------------------------------------------------- muqatta'at repair

# The fawatih are set with ligature glyphs and stacked maddahs that the learned map reads
# only approximately, so the 29 openings are spelled from a table instead. The table is
# built per VOLUME off that volume's own page by muqattaat.py, keyed "surah:ayah".
_muq_cache = {}

def _muq_table(slug):
    """This volume's own fawatih. See muqattaat.py for why the table is per volume and
    not per family: the marks on the opening letters are the reading, so copying a family
    bridge's spelling handed Hisham the imalah dot Ibn Dhakwan has and he does not, hid a
    Ruways/Rawh split at 36:1, and gave the Abu Ja'far pair a shadda for an idgham they
    read as sakt."""
    if not _muq_cache:
        _muq_cache.update(json.loads((DATA / "muqattaat.json").read_text()))
    return _muq_cache.get(slug, {})


def _muq_skeleton(s):
    return "".join("ا" if c == "ٱ" else c for c in s
                   if not unicodedata.combining(c) and c not in _PAUSE_SET)


def apply_muqattaat(t, slug, sid, aid):
    """Replace a rendered fawatih opening with this volume's table spelling - but only
    when the render produced the same letters, so a mis-segmented ayah is left alone."""
    rep = _muq_table(slug).get(f"{sid}:{aid}")
    if not rep:
        return t
    words, n = t.split(), len(rep.split())
    if len(words) < n or _muq_skeleton(" ".join(words[:n])) != _muq_skeleton(rep):
        return t
    return " ".join([rep] + words[n:])

# ---------------------------------------------------------------- roundtrip loop

def word_diff_classes(got, exp):
    """Yield (class, got_word, exp_word) for aligned word diffs."""
    gw, ew = got.split(), exp.split()
    sm = difflib.SequenceMatcher(None, gw, ew)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal": continue
        for g, e in zip(gw[i1:i2] + [""] * max(0, (j2 - j1) - (i2 - i1)),
                        ew[j1:j2] + [""] * max(0, (i2 - i1) - (j2 - j1))):
            sk_g = "".join(ch for ch in g if not unicodedata.combining(ch) and ch != "✗")
            sk_e = "".join(ch for ch in e if not unicodedata.combining(ch))
            PAUSE = set("\u06d6\u06d7\u06d8\u06d9\u06da\u06db\u06dc\u06d9")
            if "✗" in g:
                yield ("UNMAPPED", g, e)
            elif sk_g == sk_e and set(g) ^ set(e) and (set(g) ^ set(e)) <= PAUSE:
                yield ("PAUSE-EDITION", g, e)
            elif sk_g == sk_e:
                # same letters, different marks: show the mark delta
                mg = [hex(ord(c)) for c in g if unicodedata.combining(c)]
                me = [hex(ord(c)) for c in e if unicodedata.combining(c)]
                delta = f"marks {'+'.join(sorted(set(me)-set(mg)))or'-'}|{'+'.join(sorted(set(mg)-set(me)))or'-'}"
                yield (delta, g, e)
            else:
                yield ("RASM", g, e)

# Waqf signs, the rub-el-hizb rosette and the sajdah marker: the layer on which the app's
# own bridge texts and the printed volumes are DIFFERENT EDITIONS rather than more or less
# accurate. QiraahQaloon and QiraahWarsh flatten every pause to a single U+06D6 (9,757 and
# 9,820 of them, and not one other sign), while their volumes print the usual four-way
# system (3,327 U+06D6, 1,915 U+06DA, 585 U+06D7); the app's Madani and Basri texts also
# carry ~430 rub rosettes against the volumes' 198. Left in the comparison this one class
# is 7,218 of qaloon's diffs and no ayah carrying any pause sign can ever match, which is
# most of why Madani appeared to render at 17%. The volumes are the authority here and all
# ten candidates already ship their four-way marks, so the pause-blind figure below is the
# one to steer by; the raw one is kept because a REGRESSION in it would still be real.
_EDITION_PAUSES = dict.fromkeys(
    [ord(c) for c in "\u06d6\u06d7\u06d8\u06d9\u06da\u06db\u06dc\u06de\u06e9"], None)

def strip_edition_pauses(t):
    # the rub rosette is a free-standing token, so collapse the gap it leaves behind
    return re.sub(r"\s+", " ", t.translate(_EDITION_PAUSES)).strip()


def roundtrip(slugs):
    """Render a bridge volume deterministically and diff it against its app text.

    Pairing goes through extract.collect_pairs, which ALIGNS the two ayah lists rather
    than zipping them. Zipping made this number mean two different things at once: for
    shubah it was the accuracy over the whole volume, and for duriabiamr it was the
    accuracy over the 74 of 114 surahs whose ayah count happened to agree, with the
    other 40 silently absent and some of the surviving 74 diffing a render against the
    wrong ayah entirely. The coverage line below now says which it is.
    """
    from extract import collect_pairs
    for slug in slugs:
        fam = FAMILY[slug]
        detmap = build_detmap(fam)
        ctxp = DATA / f"ctxdet-{fam}.json"
        ctx = json.loads(ctxp.read_text()) if ctxp.exists() else None
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        missing = collections.Counter()
        classes = collections.Counter()
        samples = collections.defaultdict(list)
        ok = tot = blind = wok = wtot = 0
        pairs = collect_pairs([slug],
                              render=lambda g: render_det(g, detmap, None, fam, ctx, slug))
        for glyphs, text, _slug, sid, aid, first in pairs:
            got = render_det(glyphs, detmap, missing, family=fam, ctx=ctx, slug=slug)
            tot += 1
            gw, ew = got.split(), text.split()
            wtot += len(ew)
            wok += sum(1 for a, b in zip(gw, ew) if a == b)
            if strip_edition_pauses(got) == strip_edition_pauses(text):
                blind += 1
            if got == text:
                ok += 1
                continue
            # classify on the pause-blind strings: PAUSE-EDITION is an edition
            # difference (see strip_edition_pauses) and at 7,218 of qaloon's diffs it
            # buries every class that can actually be acted on.
            for cls, g, e in word_diff_classes(strip_edition_pauses(got),
                                               strip_edition_pauses(text)):
                classes[cls] += 1
                if len(samples[cls]) < 3:
                    samples[cls].append((f"{sid}:{aid}", g, e))
        avail = sum(max(0, len(su) - 1) for su in seg["data"])
        print(f"\n=== {slug} deterministic roundtrip: {ok}/{tot} exact ({ok/max(tot,1):.2%}) ===")
        print(f"coverage: {tot}/{avail} volume ayahs paired ({tot/max(avail,1):.1%})")
        print(f"pause-blind: {blind}/{tot} exact ({blind/max(tot,1):.2%})   "
              f"words {wok}/{wtot} ({wok/max(wtot,1):.2%})")
        print("diff classes (top 25):")
        for cls, n in classes.most_common(25):
            print(f"  ×{n:<6} {cls}")
            for loc, g, e in samples[cls]:
                print(f"        {loc}: {g!r} ⇢ {e!r}")
        print("unmapped keys (top 15):")
        for k, n in missing.most_common(15):
            print(f"  ×{n:<6} {k}")


def emit_targets(slugs):
    import zlib
    from extract import strip_header_and_basmalah
    OUT = DATA
    # Emit destination. Defaults to pipeline/emit/ so a pipeline run can NEVER overwrite
    # the shipped .json.deflate by accident; point QIRAAT_EMIT_DIR at
    # Resources/Data/Quran only when you have reviewed the diff and mean to ship it.
    APPOUT = pathlib.Path(os.environ.get("QIRAAT_EMIT_DIR", BASE / "emit"))
    APPOUT.mkdir(parents=True, exist_ok=True)
    NAMES = {"hisham":"QiraahHisham","ibndhakwan":"QiraahIbnDhakwan","khalaf":"QiraahKhalaf",
             "khallad":"QiraahKhallad","abuharith":"QiraahAbuHarith","durikisai":"QiraahDuriKisai",
             "ibnwardan":"QiraahIbnWardan","ibnjammaz":"QiraahIbnJammaz","ruways":"QiraahRuways",
             "rawh":"QiraahRawh","ishaq":"QiraahIshaq","idris":"QiraahIdris"}
    for slug in slugs:
        fam = FAMILY[slug]
        detmap = build_detmap(fam)
        ctxp = DATA / f"ctxdet-{fam}.json"
        ctx = json.loads(ctxp.read_text()) if ctxp.exists() else None
        seg = json.loads((DATA / f"{slug}.surahs.json").read_text())
        missing = collections.Counter()
        out = {}
        for sid, surah in enumerate(seg["data"], 1):
            ayahs = []
            for aid, glyphs in enumerate(surah, 1):
                t = render_det(glyphs, detmap, missing, family=fam, ctx=ctx, slug=slug)
                if aid == 1:
                    if sid == 9:
                        t = strip_header_and_basmalah(t, tawbah=True)
                    elif sid == 1:
                        t = strip_header_and_basmalah(t, keep_basmalah=True)
                        if len(t.split()) > 5:
                            t = strip_header_and_basmalah(t, keep_basmalah=False)
                    else:
                        t = strip_header_and_basmalah(t, keep_basmalah=False)
                t = t.replace("✗", "").strip()
                if aid <= 2:
                    t = apply_muqattaat(t, slug, sid, aid)
                t = apply_sitepatch(t, slug, sid, aid)
                ayahs.append({"id": aid, "text": re.sub(r"\s+", " ", t)})
            out[str(sid)] = ayahs
        name = NAMES[slug]
        raw = json.dumps(out, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        (OUT / f"{slug}.final.json").write_text(raw.decode("utf-8"))
        co = zlib.compressobj(9, zlib.DEFLATED, -15)
        blob = co.compress(raw) + co.flush()
        (APPOUT / f"{name}.json.deflate").write_bytes(blob)
        tot = sum(len(v) for v in out.values())
        unm = sum(missing.values())
        print(f"{slug} → {name}: {tot} ayahs, unresolved-glyph occurrences dropped={unm}, deflate={len(blob):,}B")
if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "rules":
        verify_rules()
    elif cmd == "detmap":
        for fam in ("kufi", "madani", "basri", "makki"):
            build_detmap(fam)
    elif cmd == "roundtrip":
        roundtrip(sys.argv[2:])
    elif cmd == "ctxpass":
        ctxpass(sys.argv[2], sys.argv[3:])
    elif cmd == "emit":
        emit_targets(sys.argv[2:])
