#!/usr/bin/env python3
"""The prophets' facts and every ayah that names them, preprocessed into Swift.

Abu, 2026-11-24: "Mention every ayah and every surah that mentions the name of the prophet ... Make it all
preprocessed obviously", and "Put tags for each prophet like if Israelite if one of the 5 messengers if given
a book and which book and if there's a Surah named after them, how many times mentioned in the Quran, how
many ayahs, how many surahs, what race or people he was sent to and what his big thing was".

    ./Scripts/build_prophet_facts.py            # writes iPhone/Islam/Library/ProphetFacts.swift
    ./Scripts/build_prophet_facts.py --check    # the counts beside the ones the scholars of the Quran give

The names are found by WORD in the app's own Quran text (the Hafs text the reader draws), not by lemma: the
Quranic Arabic Corpus lemmas this repo ships (Resources/Data/Quran/Morphology.json.xz) miss five of Harun's
twenty and thirteen of Ibrahim's sixty-nine. A word matches when, with its harakat and Quranic marks taken
off and at most one attached particle (wa-, fa-, bi-, li-, ka-, the vocative ya-) peeled from its front, it
is one of the name's spellings. Two names are also ordinary words and are listed by ayah instead: Salih
("righteous") and Hud (also "Jews", 2:111, 2:135, 2:140); Yahya is also "he lives" (8:42, 20:74, 87:13).
`--check` prints each count beside the commonly cited one so a change in the text cannot slip by.

The corpus builder (build_islam_corpus.py) imports this module, so a page's `.mentions("musa")` and
`.facts("musa")` read as the same words in search and in the Ask AI chat as on screen.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT.parent / "Quran-Tajweed-Engine/sources/Quran.json"
OUT = ROOT / "iPhone/Islam/Library/ProphetFacts.swift"

# MARK: - Facts

# rank: "ulul-azm" (one of the five of firm resolve, 46:35, 33:7, 42:13), "rasul" (a messenger: the Quran
# calls him one), "nabi" (a prophet), "" (not a prophet: Maryam). `people` is his lineage in a word or two,
# `book` the scripture he was given by name in the Quran, `surah` the surah named after him, `sent` the
# people he was sent to, `known` what he is best known for. Every field is shown as a tag on his rows and
# in the card at the top of his pages; the full account (names, family, language) is the pages' prose.
FACTS = [
    dict(key="adam", name="Adam", arabic="آدَم", english="", rank="nabi", people="Father of mankind",
         book="", surah=0, sent="His children", known="Taught the names",
         stories=["StoryAdamView"], pillars="ProphetAdamView"),
    dict(key="idris", name="Idris", arabic="إِدْرِيس", english="Enoch, many say", rank="nabi", people="Early, before Nuh most say",
         book="", surah=0, sent="People not named", known="Raised to a high station",
         stories=["StoryIdrisView"], pillars="ProphetIdrisView"),
    dict(key="nuh", name="Nuh", arabic="نُوح", english="Noah", rank="ulul-azm", people="Line of Adam",
         book="", surah=71, sent="His people", known="The first messenger; the Ark",
         stories=["StoryNuhView"], pillars="ProphetNuhView"),
    dict(key="hud", name="Hud", arabic="هُود", english="", rank="rasul", people="Arab",
         book="", surah=11, sent="‘Ad of al-Ahqaf", known="The barren wind",
         stories=["StoryHudView"], pillars="ProphetHudView"),
    dict(key="salih", name="Salih", arabic="صَالِح", english="", rank="rasul", people="Arab",
         book="", surah=0, sent="Thamud of al-Hijr", known="The she-camel",
         stories=["StorySalihView"], pillars="ProphetSalihView"),
    dict(key="ibrahim", name="Ibrahim", arabic="إِبْرَاهِيم", english="Abraham", rank="ulul-azm", people="Father of the prophets",
         book="Suhuf", surah=14, sent="His people and their king", known="Khalil of Allah; the fire",
         stories=["StoryIbrahimView"], pillars="ProphetIbrahimView"),
    dict(key="lut", name="Lut", arabic="لُوط", english="Lot", rank="rasul", people="Ibrahim’s nephew",
         book="", surah=0, sent="Sodom and its towns", known="The overturned cities",
         stories=["StoryLutView"], pillars="ProphetLutView"),
    dict(key="ismail", name="Isma’il", arabic="إِسْمَاعِيل", english="Ishmael", rank="rasul", people="Father of the Arabs",
         book="", surah=0, sent="Makkah and Jurhum", known="Zamzam; the House raised",
         stories=["StoryKabahView"], pillars="ProphetIsmailView"),
    dict(key="ishaq", name="Ishaq", arabic="إِسْحَاق", english="Isaac", rank="nabi", people="Son of Ibrahim and Sarah",
         book="", surah=0, sent="The land of Sham", known="Glad tidings to Sarah",
         stories=["StoryIshaqView"], pillars="ProphetIshaqView"),
    dict(key="yaqub", name="Ya’qub / Isra’il", arabic="يَعْقُوب", english="Jacob, Israel", rank="nabi", people="Israel himself",
         book="", surah=0, sent="His household in Canaan", known="Beautiful patience; twelve sons",
         stories=["StoryYaqubView"], pillars="ProphetYaqubView"),
    dict(key="yusuf", name="Yusuf", arabic="يُوسُف", english="Joseph", rank="rasul", people="Israelite",
         book="", surah=12, sent="Egypt", known="The best of stories",
         stories=["StoryYusufView"], pillars="ProphetYusufView"),
    dict(key="ayyub", name="Ayyub", arabic="أَيُّوب", english="Job", rank="nabi", people="Line of Nuh (6:84)",
         book="", surah=0, sent="People not named", known="Patience in affliction",
         stories=["StoryAyyubView"], pillars="ProphetAyyubView"),
    dict(key="shuayb", name="Shu’ayb", arabic="شُعَيْب", english="", rank="rasul", people="Arab",
         book="", surah=0, sent="Madyan and al-Aykah", known="Full measure and weight",
         stories=["StoryShuaybView"], pillars="ProphetShuaybView"),
    dict(key="musa", name="Musa", arabic="مُوسَىٰ", english="Moses", rank="ulul-azm", people="Israelite, of Levi",
         book="Tawrah", surah=0, sent="Pharaoh and Bani Isra’il", known="Allah spoke to him; the sea",
         stories=["StoryMusaEarlyView", "StoryMusaPharaohView", "StoryWildernessView", "StoryKhidrView"], pillars="ProphetMusaView"),
    dict(key="harun", name="Harun", arabic="هَارُون", english="Aaron", rank="rasul", people="Israelite, of Levi",
         book="", surah=0, sent="Pharaoh and Bani Isra’il", known="Musa’s brother and minister",
         stories=["StoryHarunView"], pillars="ProphetHarunView"),
    dict(key="dhulkifl", name="Dhul-Kifl", arabic="ذُو الْكِفْل", english="", rank="nabi", people="Of Bani Isra’il, reported",
         book="", surah=0, sent="People not named", known="Among the patient",
         stories=["StoryDhulKiflView"], pillars="ProphetDhulKiflView"),
    dict(key="dawud", name="Dawud", arabic="دَاوُود", english="David", rank="nabi", people="Israelite, of Judah",
         book="Zabur", surah=0, sent="Bani Isra’il, as their king", known="Jalut slain; iron made soft",
         stories=["StoryDawudView"], pillars="ProphetDawudView"),
    dict(key="sulayman", name="Sulayman", arabic="سُلَيْمَان", english="Solomon", rank="nabi", people="Israelite, son of Dawud",
         book="", surah=0, sent="Bani Isra’il, as their king", known="The wind, the jinn, the birds",
         stories=["StorySulaymanView"], pillars="ProphetSulaymanView"),
    dict(key="ilyas", name="Ilyas", arabic="إِلْيَاس", english="Elijah", rank="rasul", people="Of Bani Isra’il, reported",
         book="", surah=0, sent="The worshippers of Ba’l", known="He called them from Ba’l",
         stories=["StoryIlyasView"], pillars="ProphetIlyasView"),
    dict(key="alyasa", name="al-Yasa’", arabic="الْيَسَع", english="Elisha", rank="nabi", people="Of Bani Isra’il, reported",
         book="", surah=0, sent="Bani Isra’il", known="Among the best",
         stories=["StoryAlyasaView"], pillars="ProphetAlyasaView"),
    dict(key="yunus", name="Yunus", arabic="يُونُس", english="Jonah", rank="rasul", people="Of Bani Isra’il, reported",
         book="", surah=10, sent="A hundred thousand or more", known="Dhun-Nun; the fish",
         stories=["StoryYunusView"], pillars="ProphetYunusView"),
    dict(key="zakariyya", name="Zakariyya", arabic="زَكَرِيَّا", english="Zechariah", rank="nabi", people="Israelite",
         book="", surah=0, sent="Bani Isra’il", known="Guardian of Maryam",
         stories=["StoryZakariyyaView"], pillars="ProphetZakariyaView"),
    dict(key="yahya", name="Yahya", arabic="يَحْيَىٰ", english="John", rank="nabi", people="Israelite",
         book="", surah=0, sent="Bani Isra’il", known="Wisdom as a boy",
         stories=["StoryYahyaView"], pillars="ProphetYahyaView"),
    dict(key="isa", name="Isa", arabic="عِيسَىٰ", english="Jesus", rank="ulul-azm", people="Israelite, through Maryam",
         book="Injil", surah=0, sent="Bani Isra’il", known="Al-Masih; raised alive",
         stories=["StoryIsaView"], pillars="ProphetIsaView"),
    dict(key="muhammad", name="Muhammad", arabic="مُحَمَّد ﷺ", english="", rank="ulul-azm", people="Arab, of Quraysh",
         book="Quran", surah=47, sent="All mankind and the jinn", known="The seal of the prophets",
         stories=["StoryMuhammadView"], pillars="ProphetMuhammadView"),
    dict(key="maryam", name="Maryam", arabic="مَرْيَم", english="Mary", rank="", people="Family of ‘Imran",
         book="", surah=19, sent="", known="The only woman named",
         stories=["StoryMaryamView"], pillars=""),
]

RANK_TITLE = {"ulul-azm": "Ulul ‘Azm", "rasul": "Messenger", "nabi": "Prophet", "": ""}

# MARK: - Names in the text

# The spellings, with harakat and marks taken off (see `plain`), of each name as the Hafs text writes it.
FORMS = {
    "adam": {"ادم"}, "idris": {"ادريس"}, "nuh": {"نوح", "نوحا"}, "ibrahim": {"ابرهيم", "ابرهم", "ابراهيم"},
    "lut": {"لوط", "لوطا"}, "ismail": {"اسمعيل", "اسماعيل"}, "ishaq": {"اسحق", "اسحاق"}, "yaqub": {"يعقوب"},
    "yusuf": {"يوسف"}, "ayyub": {"ايوب"}, "shuayb": {"شعيب", "شعيبا"}, "musa": {"موسي"},
    "harun": {"هرون", "هارون"}, "dawud": {"داود", "داوود"}, "sulayman": {"سليمن", "سليمان"},
    "ilyas": {"الياس"}, "alyasa": {"اليسع"}, "yunus": {"يونس"}, "zakariyya": {"زكريا"},
    "yahya": {"يحيي"}, "isa": {"عيسي"}, "muhammad": {"محمد"}, "maryam": {"مريم"},
}
# Names that are also ordinary words: the ayahs, as the scholars of the Quran list them.
BY_AYAH = {
    "salih": ["7:73", "7:75", "7:77", "11:61", "11:62", "11:66", "11:89", "26:142", "27:45"],
    "hud": ["7:65", "11:50", "11:53", "11:58", "11:60", "11:89", "26:124"],
    "dhulkifl": ["21:85", "38:48"],
}
# A form that is also another word in these ayahs ("wa yahya man hayya", "la yamutu fiha wa la yahya").
EXCLUDE = {"yahya": {"8:42", "20:74", "87:13"}}
# The other names the Quran gives him, each listed under its own line.
ALSO = {
    "yaqub": [("as Isra’il", ["3:93", "19:58"])],
    "isa": [("as al-Masih", "masih"), ("as “the son of Maryam”", "ibnmaryam")],
    "yunus": [("as Dhun-Nun, “the one of the fish”", ["21:87"]), ("as “the companion of the fish”", ["68:48"])],
    "ilyas": [("as Il Yasin", ["37:130"])],
    "muhammad": [("as Ahmad", ["61:6"])],
}
# How often the scholars of the Quran say each name occurs, for `--check`.
EXPECTED = {"adam": 25, "idris": 2, "nuh": 43, "hud": 7, "salih": 9, "ibrahim": 69, "lut": 27, "ismail": 12,
            "ishaq": 17, "yaqub": 16, "yusuf": 27, "ayyub": 4, "shuayb": 11, "musa": 136, "harun": 20,
            "dhulkifl": 2, "dawud": 16, "sulayman": 17, "ilyas": 2, "alyasa": 2, "yunus": 4, "zakariyya": 7,
            "yahya": 5, "isa": 25, "muhammad": 4, "maryam": 34}

MARKS = re.compile(r"[ؐ-ًؚ-ٰٟۖ-ۭـࣰ-ࣿ]")
PARTICLES = ("ول", "وب", "فل", "فب", "وك", "وي", "في", "و", "ف", "ب", "ل", "ك", "ي")


def plain(word: str) -> str:
    word = MARKS.sub("", word)
    word = re.sub("[ٱأإآ]", "ا", word).replace("ء", "").replace("ى", "ي").replace("ئ", "ي").replace("ؤ", "و")
    return word


def matches(token: str, forms: set) -> bool:
    if token in forms:
        return True
    return any(token.startswith(p) and token[len(p):] in forms for p in PARTICLES)


_quran = None


def quran():
    global _quran
    if _quran is None:
        _quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    return _quran


def surah_names():
    return {s["id"]: s["nameTransliteration"] for s in quran()}


def find(forms: set, exclude=frozenset()):
    """Every (surah, ayah) whose text has one of `forms`, once per occurrence."""
    hits = []
    for s in quran():
        for a in s["ayahs"]:
            key = f"{s['id']}:{a['id']}"
            if key in exclude:
                continue
            for token in a["textArabic"].split():
                if matches(plain(token), forms):
                    hits.append((s["id"], a["id"]))
    return hits


def find_pairs(first: str, second: str):
    """Two words in a row ("ibn maryam", "al-masih" alone is one word)."""
    hits = []
    for s in quran():
        for a in s["ayahs"]:
            tokens = [plain(t) for t in a["textArabic"].split()]
            for i in range(len(tokens) - 1):
                if matches(tokens[i], {first}) and tokens[i + 1] == second:
                    hits.append((s["id"], a["id"]))
    return hits


def parse(refs):
    return [tuple(int(x) for x in r.split(":")) for r in refs]


def occurrences(key: str):
    if key in BY_AYAH:
        return parse(BY_AYAH[key])
    return find(FORMS[key], EXCLUDE.get(key, frozenset()))


def grouped(hits):
    """[(surah, [ayah, ...])] in mushaf order, each ayah once."""
    out = {}
    for s, a in sorted(set(hits)):
        out.setdefault(s, []).append(a)
    return sorted(out.items())


def also_lines(key: str):
    lines = []
    for label, spec in ALSO.get(key, []):
        if spec == "masih":
            hits = find({"المسيح"})
        elif spec == "ibnmaryam":
            hits = find_pairs("ابن", "مريم")
        else:
            hits = parse(spec)
        lines.append((label, len(hits), grouped(hits)))
    return lines


def mentions():
    """key -> dict(times, ayahs, surahs, groups, also)."""
    out = {}
    for fact in FACTS:
        key = fact["key"]
        hits = occurrences(key)
        groups = grouped(hits)
        out[key] = dict(times=len(hits), ayahs=sum(len(a) for _, a in groups), surahs=len(groups),
                        groups=groups, also=also_lines(key))
    return out


# MARK: - Text the corpus reads


def count_phrase(m):
    return (f"named {m['times']} time{'s' if m['times'] != 1 else ''} in {m['ayahs']} ayah{'s' if m['ayahs'] != 1 else ''} "
            f"across {m['surahs']} surah{'s' if m['surahs'] != 1 else ''}")


def mentions_text(key: str, cached=None) -> str:
    """The words `.mentions(key)` shows, for the corpus: the count, then every surah with its ayahs."""
    fact = next(f for f in FACTS if f["key"] == key)
    m = (cached or mentions())[key]
    names = surah_names()
    parts = [f"{fact['name']} is {count_phrase(m)} of the Quran."]
    parts.append("; ".join(f"{names[s]} ({s}): " + ", ".join(f"{s}:{a}" for a in ayahs) for s, ayahs in m["groups"]) + ".")
    for label, times, groups in m["also"]:
        parts.append(f"Also {label}, {times} time{'s' if times != 1 else ''}: " +
                     "; ".join(", ".join(f"{s}:{a}" for a in ayahs) for s, ayahs in groups) + ".")
    return " ".join(parts)


def tags(key: str, cached=None):
    """The tags, in order: rank, people, book, surah, count, sent to, known for."""
    fact = next(f for f in FACTS if f["key"] == key)
    m = (cached or mentions())[key]
    names = surah_names()
    out = []
    if fact["rank"]:
        out.append(("rank", RANK_TITLE[fact["rank"]]))
    if fact["people"]:
        out.append(("people", fact["people"]))
    if fact["book"]:
        out.append(("book", fact["book"]))
    if fact["surah"]:
        out.append(("surah", f"Surah {names[fact['surah']]} ({fact['surah']})"))
    out.append(("count", f"{m['times']}× · {m['ayahs']} ayah{'s' if m['ayahs'] != 1 else ''} · {m['surahs']} surah{'s' if m['surahs'] != 1 else ''}"))
    if fact["sent"]:
        out.append(("sent", fact["sent"]))
    if fact["known"]:
        out.append(("known", fact["known"]))
    return out


def facts_text(key: str, cached=None) -> str:
    """The words `.facts(key)` shows, for the corpus."""
    fact = next(f for f in FACTS if f["key"] == key)
    labels = {"rank": "Rank", "people": "Lineage", "book": "Book", "surah": "Surah named after", "count": "In the Quran",
              "sent": "Sent to", "known": "Known for"}
    head = f"{fact['name']} ({fact['arabic']})" + (f", {fact['english']}" if fact["english"] else "") + "."
    return head + " " + " ".join(f"{labels[k]}: {v}." for k, v in tags(key, cached))


# MARK: - Swift


def swift_string(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_swift():
    m = mentions()
    names = surah_names()
    lines = [
        "import SwiftUI",
        "",
        "// GENERATED by Scripts/build_prophet_facts.py from its FACTS table and the app's own Quran text. Do not",
        "// edit by hand: change the script and run it again. Every count and ayah list here is found by word in",
        "// the Hafs text (see the script for how), so the tags and the lists can never disagree with the reader.",
        "",
        "/// One prophet's facts (Abu, 2026-11-24): the tags on his rows in Stories of the Prophets and in Pillars &",
        "/// Beliefs, the card at the top of his pages, and every ayah that names him.",
        "struct ProphetFacts {",
        "    struct Tag: Hashable {",
        "        enum Kind: String { case rank, people, book, surah, count, sent, known, date, place }",
        "        let kind: Kind",
        "        let text: String",
        "    }",
        "",
        "    /// Ayahs of one surah that name him.",
        "    struct Surah: Hashable {",
        "        let number: Int",
        "        let name: String",
        "        let ayahs: [Int]",
        "    }",
        "",
        "    /// Another name the Quran gives him (\"as al-Masih\"), with where.",
        "    struct Also: Hashable {",
        "        let label: String",
        "        let times: Int",
        "        let surahs: [Surah]",
        "    }",
        "",
        "    let key: String",
        "    let name: String",
        "    let arabic: String",
        "    let english: String",
        "    let tags: [Tag]",
        "    let times: Int",
        "    let ayahCount: Int",
        "    let surahs: [Surah]",
        "    let also: [Also]",
        "    /// His Stories of the Prophets chapters and his Pillars & Beliefs page, by catalog id.",
        "    let stories: [String]",
        "    let pillars: String",
        "",
        "    static func named(_ key: String) -> ProphetFacts? { byKey[key] }",
        "",
        "    /// The prophet a catalog article is about: his story chapters and his Pillars page, by id.",
        "    static func forArticle(_ id: String) -> ProphetFacts? { byArticle[id] }",
        "",
        "    private static let byKey: [String: ProphetFacts] = Dictionary(uniqueKeysWithValues: all.map { ($0.key, $0) })",
        "    private static let byArticle: [String: ProphetFacts] = {",
        "        var out: [String: ProphetFacts] = [:]",
        "        for facts in all {",
        "            for id in facts.stories where out[id] == nil { out[id] = facts }",
        "            if !facts.pillars.isEmpty { out[facts.pillars] = facts }",
        "        }",
        "        return out",
        "    }()",
        "",
        "    static let all: [ProphetFacts] = [",
    ]

    def surah_list(groups, indent):
        rows = [f"{indent}.init(number: {s}, name: {swift_string(names[s])}, ayahs: [{', '.join(map(str, a))}])," for s, a in groups]
        return rows

    for fact in FACTS:
        key = fact["key"]
        mm = m[key]
        lines.append("        ProphetFacts(")
        lines.append(f"            key: {swift_string(key)}, name: {swift_string(fact['name'])}, arabic: {swift_string(fact['arabic'])},")
        lines.append(f"            english: {swift_string(fact['english'])},")
        lines.append("            tags: [")
        for kind, text in tags(key, m):
            lines.append(f"                .init(kind: .{kind}, text: {swift_string(text)}),")
        lines.append("            ],")
        lines.append(f"            times: {mm['times']}, ayahCount: {mm['ayahs']},")
        lines.append("            surahs: [")
        lines += surah_list(mm["groups"], "                ")
        lines.append("            ],")
        lines.append("            also: [")
        for label, times, groups in mm["also"]:
            lines.append(f"                .init(label: {swift_string(label)}, times: {times}, surahs: [")
            lines += surah_list(groups, "                    ")
            lines.append("                ]),")
        lines.append("            ],")
        lines.append(f"            stories: [{', '.join(swift_string(s) for s in fact['stories'])}], pillars: {swift_string(fact['pillars'])}")
        lines.append("        ),")
    lines.append("    ]")
    lines.append("}")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return m


def main():
    m = mentions()
    if "--check" in sys.argv:
        bad = 0
        for fact in FACTS:
            key = fact["key"]
            got, want = m[key]["times"], EXPECTED.get(key)
            flag = "" if got == want else "   <-- differs"
            bad += bool(flag)
            print(f"{fact['name']:18s} {got:4d} (expected {want}) {m[key]['ayahs']:4d} ayahs {m[key]['surahs']:3d} surahs{flag}")
            for label, times, _ in m[key]["also"]:
                print(f"{'':18s}   also {label}: {times}")
        sys.exit(1 if bad else 0)
    write_swift()
    print(f"wrote {OUT.relative_to(ROOT)}: {len(FACTS)} entries")


if __name__ == "__main__":
    main()
