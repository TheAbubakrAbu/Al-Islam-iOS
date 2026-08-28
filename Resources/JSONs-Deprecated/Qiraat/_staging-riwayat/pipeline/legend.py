"""Each volume's own tajweed legend, read off its pages.

Every volume but Qalun prints its key in the bottom margin of EVERY page: a filled circle
per rule with the rule's Arabic name beside it. The circles are vector fills and come out
of the PDF exactly; the names are text, but most volumes set them in a DecoType face whose
ToUnicode is broken (they extract as Hebrew), so the names below were read off the
rendered pages and the swatch SET is what gets verified automatically.

The single most consequential thing the keys say is the UNIT. Three volumes name their
khilaf colour الكلمة المخالفة لحفص, "the WORD differing from Hafs"; the other fifteen name
it الحرف المخالف لحفص, "the LETTER". So whether a highlight covers a word or a letter is
the print's own declaration, not a guess - and the previous build had it wrong for four of
the five volumes it treated as whole-word.

    python3 legend.py verify      # the printed swatch set still matches this table
"""
import sys, os, json, collections, pathlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fitz, extract

DATA = pathlib.Path(__file__).resolve().parent / "data"

# rule slug -> (Arabic as printed, English)
RULES = {
    "khilaf-letter":  ("الحرف المخالف لحفص", "the letter differing from Hafs"),
    "khilaf-word":    ("الكلمة المخالفة لحفص", "the word differing from Hafs"),
    "khilaf-ha":      ("هاء الضمير المخالفة لحفص", "the pronoun ha differing from Hafs"),
    "idgham":         ("الإدغام", "idgham"),
    "imalah":         ("الإمالة", "imalah"),
    "taqlil":         ("التقليل", "taqlil"),
    "badal":          ("مد البدل", "madd al-badal"),
    "leen":           ("مد اللين", "madd al-leen"),
    "raa":            ("الراءات المرققة", "the lightened ra"),
    "lam":            ("اللامات المغلظة", "the thickened lam"),
    "silah":          ("صلة ميم الجمع", "silat meem al-jam'"),
    "sakt":           ("السكت", "sakt"),
    "ishmam":         ("إشمام الصاد صوت الزاي", "ishmam of sad with the sound of zay"),
    "ghunnah":        ("الغنة مع الخاء والغين", "ghunnah with kha and ghayn"),
    "tashdid-ta":     ("تشديد التاء", "the doubled ta"),
    "ibtida-wasl":    ("الابتداء بهمزة الوصل", "beginning on the wasl hamzah"),
}

# slug -> {0xRRGGBB: rule slug}
LEGEND = {
    # Shu'bah's key lists two colours but the volume also inks 58 red imalah dots (the
    # MSH dot glyph, which this series always draws red). The dots are on the page, so
    # they are read; the key simply does not mention them.
    "shubah":     {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "imalah"},
    "warsh":      {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "taqlil",
                   0x00ccff: "badal", 0x00ff00: "raa", 0x3366ff: "lam",
                   0xff6600: "silah", 0x99cc00: "leen"},
    # Qalun is the one volume that prints no key at all. Its body carries 1,558 magenta
    # runs and 25 blue against single strays of everything else, and those two colours
    # mean the same thing in all eighteen volumes that DO print a key.
    "qaloon":     {0xff00ff: "khilaf-letter", 0x0000ff: "idgham"},
    # al-Bazzi's key names three colours; the volume also inks 44 cyan runs its key is
    # silent about, and every one of them is the same thing: a word beginning in a
    # doubled ta together with the particle before it (`وَلَا تَّيَمَّمُواْ`, `أَن تَّبَدَّلَ`,
    # `فَتَّفَرَّقَ`). That word list IS تشديد التاء, the rule al-Bazzi is known for, and it
    # can only be read in wasl - which is why the particle is inked with it.
    "bazzi":      {0xff00ff: "khilaf-letter", 0x0000ff: "khilaf-ha", 0xff0000: "silah",
                   0x00ccff: "tashdid-ta"},
    "qunbul":     {0xff00ff: "khilaf-letter", 0x0000ff: "khilaf-ha", 0xff0000: "silah"},
    "duriabiamr": {0xff00ff: "khilaf-word", 0x0000ff: "idgham", 0xff0000: "imalah"},
    "susi":       {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "imalah"},
    "hisham":     {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "imalah"},
    "ibndhakwan": {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "imalah"},
    "khalaf":     {0xff00ff: "khilaf-word", 0x0000ff: "idgham", 0xff0000: "imalah",
                   0x00ccff: "sakt", 0xff6600: "ishmam"},
    "khallad":    {0xff00ff: "khilaf-word", 0x0000ff: "idgham", 0xff0000: "imalah",
                   0x00ccff: "sakt", 0xff6600: "ishmam"},
    "abuharith":  {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "imalah",
                   0xff6600: "ishmam"},
    "durikisai":  {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "imalah",
                   0xff6600: "ishmam"},
    # Both Abu Ja'far volumes ink a fifth colour their keys omit: bright green, on the
    # muqatta'at of all 29 fawatih surahs and on nothing else in the book. Abu Ja'far is
    # the only one of the Ten who pauses on each disjoined letter, so that is sakt - the
    # same rule the two Hamzah volumes key in cyan.
    # A SIXTH colour, also unkeyed: a green dot on the wasl alef of 16 words, and only
    # those 16 - every place in the Quran where a hamzat al-wasl is followed by a
    # sukoon-bearing hamza (`ٱئۡتِنَا`, `ٱئۡتُونِي`, `ٱئۡتِيَا`, `ٱئۡذَن` 9:49, `ٱؤۡتُمِنَ` 2:283).
    # It is the Maghribi starting-vowel dot, and its POSITION is the vowel: measured off
    # the ink, 15 of the 16 sit below the alef (kasrah -> `إِيتِنَا`) and `ٱؤۡتُمِنَ` alone
    # sits mid-height on its left (dammah -> `اُوتُمِنَ`). The volume draws 607 of these
    # dots in black; these are the only coloured ones, because these are the only ones
    # where beginning also turns the next hamza into a madd letter.
    "ibnwardan":  {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "silah",
                   0x00ccff: "ghunnah", 0x00ff00: "sakt", 0x00b050: "ibtida-wasl"},
    "ibnjammaz":  {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "silah",
                   0x00ccff: "ghunnah", 0x00ff00: "sakt", 0x00b050: "ibtida-wasl"},
    # Ruways and the two Khalaf al-Ashir volumes ink 12 orange marks each that their keys
    # do not name. Every one sits on the sad of `أَصۡدَقُ` / `يَصۡدِفُونَ`, in the same colour
    # that four other volumes key as إشمام الصاد صوت الزاي, so that is what they are.
    "ruways":     {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "imalah",
                   0xff6600: "ishmam"},
    # Rawh's key names two colours, but the volume also inks nine red slots (three words:
    # أَعۡمَىٰ 17:72, كَٰفِرِينَ 27:43, يٓسٓ 36:1). Every one carries U+065C, the imalah dot, so
    # they are imalah exactly as in Shu'bah, whose key is silent about its red dots too.
    "rawh":       {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "imalah"},
    "ishaq":      {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "imalah",
                   0xff6600: "ishmam"},
    "idris":      {0xff00ff: "khilaf-letter", 0x0000ff: "idgham", 0xff0000: "imalah",
                   0xff6600: "ishmam"},
}

# Volumes whose key says الكلمة, so a khilaf highlight covers the whole word by the
# print's own definition. Everyone else says الحرف and highlights the letter.
WORD_UNIT = {s for s, m in LEGEND.items() if "khilaf-word" in m.values()}


# Colours a volume inks in the body but leaves out of its printed key.
UNKEYED = {"shubah": {0xff0000}, "ruways": {0xff6600}, "rawh": {0xff0000},
           "ishaq": {0xff6600}, "idris": {0xff6600}, "bazzi": {0x00ccff},
           "ibnwardan": {0x00ff00, 0x00b050}, "ibnjammaz": {0x00ff00, 0x00b050}}


def rgb(f):
    return (int(round(f[0] * 255)) << 16) | (int(round(f[1] * 255)) << 8) | int(round(f[2] * 255))


def resolve(slug, col):
    """Body colour -> rule slug. The key's swatch and the ink differ by a rounding step
    (#99cc00 in the key against #9acc00 in the text), so match to the nearest."""
    m = LEGEND[slug]
    def dist(a, b):
        return sum((((a >> s) & 255) - ((b >> s) & 255)) ** 2 for s in (16, 8, 0))
    best = min(m, key=lambda k: dist(col, k))
    # 45 per channel. The ink and the key round differently (#99cc00 keyed against
    # #9acc00 inked, #00ccff keyed against #33cccc inked in Khallad's 1,578 sakt marks,
    # #ff00ff against #ff33cc), and 45 clears every one of those while still leaving the
    # closest DIFFERENT pair in any volume - #ff6600 against #ff0000 - comfortably apart.
    return m[best] if dist(col, best) <= 3 * 45 * 45 else None


def printed_swatches(slug, probe=7):
    d = fitz.open(extract.pdf_path(slug))
    votes = collections.Counter()
    pages = list(range(20, d.page_count, max(1, d.page_count // probe)))
    for pno in pages:
        sw = set()
        for dr in d[pno].get_drawings():
            # Abu al-Harith draws its magenta key circle stroke-only while inking the
            # body solid magenta, so a fill-only scan misses one real key.
            f = dr.get("fill") or dr.get("color")
            if not f:
                continue
            r = dr["rect"]
            w, h = r.x1 - r.x0, r.y1 - r.y0
            # 45..550 is the content band: the green rule-and-leaf border runs down both
            # margins at x 25-39 and 556-571 in the same size class.
            if (8 <= w <= 22 and 8 <= h <= 22 and abs(w - h) < 4 and r.y0 > 600
                    and 45 < r.x0 < 550):
                c = rgb(f)
                # the Yaqub/Khalaf volumes edge the page with blue stars of the same size
                if c not in (0xffffff, 0x0909e9):
                    sw.add(c)
        votes[tuple(sorted(sw))] += 1
    return votes.most_common(1)[0][0], len(pages)


if __name__ == "__main__":
    if sys.argv[1:2] == ["verify"]:
        bad = 0
        for slug, m in LEGEND.items():
            got, n = printed_swatches(slug)
            want = set(m)
            # keys the print inks but does not draw a swatch for
            want -= UNKEYED.get(slug, set())
            extra, miss = set(got) - want, want - set(got)
            ok = not extra and not miss
            if slug == "qaloon":
                ok = not got            # prints no key at all
            print("%-12s %-4s %d keys  %s" % (slug, "OK" if ok else "BAD", len(m),
                  "" if ok else f"extra={[hex(c) for c in extra]} missing={[hex(c) for c in miss]}"))
            bad += not ok
        sys.exit(1 if bad else 0)
    out = {s: {"unit": "word" if s in WORD_UNIT else "letter",
               "keys": {"#%06x" % c: {"rule": r, "ar": RULES[r][0], "en": RULES[r][1]}
                        for c, r in sorted(m.items())}}
           for s, m in LEGEND.items()}
    (DATA / "legend.json").write_text(json.dumps(out, ensure_ascii=False, indent=1))
    print("wrote data/legend.json")
