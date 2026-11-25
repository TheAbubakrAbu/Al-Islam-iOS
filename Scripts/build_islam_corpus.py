#!/usr/bin/env python3
"""Build the Islam-tab article corpus the Ask AI chat retrieves from.

The Pillars, Beliefs and How-to articles are written as SwiftUI views with their
prose inline - there is no data layer to search. This walks those view files and
lifts the prose back out: one record per article view, its sections in the order
the screen shows them, so the chat can hand the model the app's OWN wording
instead of whatever the model half-remembers.

    ./Scripts/build_islam_corpus.py            # write the pack
    ./Scripts/build_islam_corpus.py --print    # dump what it found, write nothing

Quran quotes in the articles are REFERENCES (`ScriptureQuote(quran: "2:255")`,
`.ayah("2:255")`, since 2026-09-16), not copies of the ayah: the screen renders
them from the app's own Quran text, and this builder resolves them the same way
(Quran-Tajweed-Engine/sources/Quran.json, Saheeh International) so the corpus
carries the words the reader sees. Hadith quotes are references too
(`ScriptureQuote(hadith: "muslim:16d", cite: ..., arabic: 35...53, english: 8...38)`,
`.hadith(...)`): the row of the bundled .hpk and token ranges into it, resolved
here through Scripts/hadith_spans.py; a side the shelf does not have in the
article's words is carried literally (`text:`, `arabicText:`). A reference the
app cannot render fails the build. Only the words of scholars, and hadith from
books the app does not bundle, are still literal `ScriptureQuote(text:)`.

Output: Resources/Data/Islam/IslamArticles.json.deflate (raw deflate, the same
wrapping the loose Quran payloads used before the xz swap - IslamArticles.swift
inflates it with one `compression_decode_buffer` call, so no app needs the
solidpack reader to read it).
"""
import json
import re
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hadith_spans import row as shelf_row, token_count, words as shelf_words  # noqa: E402
import article_zones  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SOURCES = [
    ROOT / "iPhone/Islam/Beliefs/PillarsView.swift",
    ROOT / "iPhone/Islam/Beliefs/PillarViews.swift",
    ROOT / "iPhone/Islam/Proofs/ProphetViews.swift",
    ROOT / "iPhone/Islam/Beliefs/BeliefsViews.swift",
    ROOT / "iPhone/Islam/Fiqh/HowToGuides.swift",
    ROOT / "iPhone/Islam/Beliefs/AqeedahViews.swift",
    ROOT / "iPhone/Islam/Beliefs/SalafiyyahViews.swift",
    ROOT / "iPhone/Islam/Beliefs/ScholarsViews.swift",
    ROOT / "iPhone/Islam/Beliefs/AnswersViews.swift",
    ROOT / "iPhone/Islam/Qiraat/RiwayatDifferencesView.swift",
    ROOT / "iPhone/Islam/Content/HadithSciencesViews.swift",
    ROOT / "iPhone/Islam/Proofs/ProvingIslamChapters.swift",
    # The six reading libraries (2026-11-24): Stories of the Prophets; Sahabah, Ahlul Bayt & Salaf; Refuting
    # Religions; Preservation of the Quran; Science of Hadith; the Domino Process.
    ROOT / "iPhone/Islam/Library/StoriesOfTheProphets.swift",
    ROOT / "iPhone/Islam/Library/SahabahAndSalaf.swift",
    ROOT / "iPhone/Islam/Library/RefutingReligions.swift",
    ROOT / "iPhone/Islam/Library/PreservationOfTheQuran.swift",
    ROOT / "iPhone/Islam/Library/ScienceOfHadith.swift",
    ROOT / "iPhone/Islam/Library/DominoProcess.swift",
]
# Tajweed Foundations (2026-11-23, Abu: "support sharing articles for tajweed foundations ... and also
# support ai summary"): the reference's pages are read too, so the Ask AI chat can answer from them and
# each page can be summarized. They are INTERFACE text, translated, so every literal is wrapped in
# `String(localized: "...")`; `tajweed_body` peels that wrapper before the regexes read the page, and
# reads the tajweed kit's own cards (TAJWEED_* below). Kept apart from SOURCES because the verifier's
# catalog checks (search tag, sources section, literal quotes) are about the catalog articles.
TAJWEED_SOURCES = [
    ROOT / "iPhone/Islam/Tajweed/TajweedFoundations.swift",
    ROOT / "iPhone/Islam/Tajweed/TajweedTopics.swift",
]
OUT = ROOT / "Resources/Data/Islam/IslamArticles.json.deflate"
# The articles written twice (2026-11-25, iPhone/Islam/Content/ArticleLength.swift): how long each version takes
# to read, for the switch at the top of the page. Generated with the pack, from the same marks.
LENGTHS_OUT = ROOT / "iPhone/Islam/Content/ArticleLengths.swift"
# Words a minute, read with the quotes; a version is never under a minute.
READING_SPEED = 220

# A Swift string literal: "..." with backslash escapes, or a """...""" block.
STR = r'"""(?:.*?)"""|"(?:[^"\\\n]|\\.)*"'

STRUCT_RE = re.compile(r"^struct (\w+): View \{", re.M)
# `Text("...")`, `Text(verbatim: "...")` and `Text(articleMarkdown: "...")` are the same prose: the
# article files spell plain literals verbatim and markdown ones through the parse cache (Performance
# Guide, Phase 6 step 2), so the corpus reads all three.
# The data-backed articles (step 3) spell the same prose as `ArticleSection("HEADING", [` with
# `.text("...")`, `.markdown("...")` and `.quote(text: "...")` blocks; read those too.
TEXT_ARG = r"(?:verbatim:\s*|articleMarkdown:\s*)?"
SECTION_RE = re.compile(r"(?:Section\(header:\s*(?:ArticleHeader\(|Text\(" + TEXT_ARG + r")|ArticleSection\()(" + STR + r")[),]", re.S)
# The design kit (iPhone/Islam/Content/ArticleDesign.swift, 2026-09-29) draws a lead, a step, a bullet and a
# closing paragraph as cards; each takes the paragraph as the `Text` it replaced did, so the corpus
# reads them as prose: `ArticleLead("...")`, `ArticleStep("1. ...")`, `ArticleBullet(verbatim: "...")`,
# `ArticleClosing(articleMarkdown: "...")`, and the data blocks `.lead(`, `.step(`, `.bullet(`. A plain
# paragraph is `ArticleParagraph(verbatim: "...")` / `ArticleParagraph(articleMarkdown: "...")` since
# 2026-10-19 (the drag-selectable form of the `Text` rows the pages were written with).
# `ArticleArabic(verbatim: "...")` (2026-10-26) is the Arabic of the adhan, the iqamah, the takbir and the
# shahadah, set in the Islam tab's face; it carries the same words the `Text` rows it replaced did.
TEXT_RE = re.compile(r"(?:(?<![\w.])(?:Text|ArticleParagraph|ArticleLead|ArticleStep|ArticleBullet|ArticleClosing|ArticleArabic)\(" + TEXT_ARG
                     + r"|(?<!\w)\.(?:text|markdown|lead|step|bullet)\()(" + STR + r")\)", re.S)
# The kit's other cards, read into sentences: a callout ("Title. Body"), a term card ("Term (Arabic):
# meaning"), stat tiles ("value label"), a chain ("name, detail"), a checklist ("Title: item item"),
# the two sides of a comparison ("label: caption"), and the scale of hadith grades.
CALLOUT_RE = re.compile(r"(?:(?<![\w.])ArticleCallout\(|(?<!\w)\.callout\()\s*(" + STR + r")\s*,\s*title:\s*(" + STR + r")", re.S)
TERM_RE = re.compile(r"(?:(?<![\w.])ArticleTermCard\(|(?<!\w)\.term\()\s*(" + STR + r")\s*,\s*arabic:\s*(" + STR
                     + r")\s*,\s*meaning:\s*(" + STR + r")\s*\)", re.S)
STAT_RE = re.compile(r"ArticleStat\(\s*(" + STR + r")\s*,\s*(" + STR + r")\s*\)", re.S)
CHAIN_LINK_RE = re.compile(r"ArticleChainLink\(\s*(" + STR + r")(?:\s*,\s*(" + STR + r"))?\s*\)", re.S)
CHAIN_CAPTION_RE = re.compile(r"(?:(?<![\w.])ArticleChainDiagram\(|(?<!\w)\.chain\()\s*\[.*?\]\s*,\s*caption:\s*(" + STR + r")", re.S)
# A chain of transmission drawn as the isnad diagram (iPhone/Islam/Content/IsnadDiagram.swift, 2026-10-27):
# `.isnad("caption", .bukhariFirst)` in a data-backed article, `ArticleIsnadCard("caption", isnad: ...)` in
# a view-based one. The caption names the chain's people in order, so it is the chain's text here.
ISNAD_RE = re.compile(r"(?:(?<![\w.])ArticleIsnadCard\(|(?<!\w)\.isnad\()\s*(" + STR + r")\s*,", re.S)
CHECKLIST_RE = re.compile(r"(?:(?<![\w.])ArticleChecklist\(|(?<!\w)\.checklist\()\s*\[(.*?)\]\s*,\s*title:\s*(" + STR + r")", re.S)
SIDE_RE = re.compile(r"ArticleVersus\.Side\(\s*(" + STR + r")(?:\s*,\s*arabic:\s*(" + STR + r"))?\s*,\s*caption:\s*(" + STR + r")\s*\)", re.S)
# The tajweed pages (TAJWEED_SOURCES) only. Their interface text is `String(localized: "...")`, peeled to
# the bare literal first (`tajweed_body`), so the regexes above read their headings, paragraphs, steps,
# checklists, callouts and term cards as they read any article. These read the tajweed kit's own cards
# (iPhone/Islam/Tajweed/TajweedFoundations.swift) and the two kit calls the articles spell differently:
# a lead with an eyebrow ("IN SHORT"), a callout of several paragraphs, and a comparison's sides written
# `.init(...)`. A word card is its title, its note and each word's READING and note; the Arabic word
# itself, and a line of the Quran set on its own card, stay out (the caption under that line is read).
# Apple's on-device model refuses a prompt heavy with Arabic, and the reading says how the word sounds.
LOCALIZED_RE = re.compile(r"String\(localized:\s*(" + STR + r")\s*\)", re.S)
TAJWEED_LEAD_RE = re.compile(r"(?<![\w.])ArticleLead\(\s*(" + STR + r")\s*,\s*eyebrow:", re.S)
TAJWEED_CALLOUT_RE = re.compile(r"(?<![\w.])ArticleCallout\(\s*paragraphs:\s*\[(.*?)\]\s*,\s*title:\s*(" + STR + r")", re.S)
TAJWEED_SIDE_RE = re.compile(r"(?<!\w)\.init\(\s*(" + STR + r")\s*,\s*arabic:\s*(" + STR + r")\s*,\s*caption:\s*(" + STR + r")\s*\)", re.S)
TAJWEED_KEY_RE = re.compile(r"(?<![\w.])TajweedKeyLine\(\s*(" + STR + r")", re.S)
TAJWEED_CARD_RE = re.compile(r"(?<![\w.])TajweedWordCard\(\s*(?:(" + STR + r")\s*,\s*)?(?:note:\s*(" + STR + r")\s*,\s*)?words:\s*\[", re.S)
TAJWEED_WORD_RE = re.compile(r"(?<![\w.])TajweedWord\(\s*(?:" + STR + r")\s*,\s*(" + STR + r")(?:\s*,\s*note:\s*(" + STR + r"))?\s*\)", re.S)
TAJWEED_LINE_RE = re.compile(r"(?<![\w.])TajweedArabicLine\(\s*(?:" + STR + r")(?:\s*,\s*title:\s*(" + STR + r"))?(?:\s*,\s*caption:\s*(" + STR + r"))?", re.S)
TAJWEED_FIX_RE = re.compile(r"(?<![\w.])TajweedFix\(\s*wrong:\s*(" + STR + r")\s*,\s*right:\s*(" + STR + r")\s*\)", re.S)
TAJWEED_STRIP_RE = re.compile(r"(?<![\w.])TajweedLetterStrip\(\s*(" + STR + r")\s*,\s*note:\s*(" + STR + r")", re.S)
# A card title that only labels its example ("Example") says nothing on its own.
TAJWEED_PLAIN_TITLES = {"Example", "Examples"}
LADDER_RE = re.compile(r"HadithGradeLadder\(\)|(?<!\w)\.gradeLadder\b")
# The classes of report by how many carried it (`HadithCountLadder`, its own card since 2026-11-22).
COUNT_LADDER_RE = re.compile(r"HadithCountLadder\(\)|(?<!\w)\.countLadder\b")
# The riwayat page's cards (RiwayatDifferencesView.swift): each spelling ("Warsh (يُومِنُونَ): note"), each
# bar of the tilt chart, and the at-a-glance table, read from its `RiwayahTraits.all` literals.
SPELLING_CARD_RE = re.compile(r"RiwayahSpellingCard\(\s*title:\s*(" + STR + r")", re.S)
SPELLING_RE = re.compile(r"RiwayahSpelling\(\s*(" + STR + r")\s*,\s*arabic:\s*(" + STR + r")\s*,\s*note:\s*(" + STR + r")\s*\)", re.S)
BAR_CHART_RE = re.compile(r"RiwayahBarChart\(\s*title:\s*(" + STR + r")", re.S)
BAR_RE = re.compile(r"RiwayahBar\(\s*(" + STR + r")\s*,\s*filled:\s*(\d+)\s*,\s*hollow:\s*(\d+)\s*\)", re.S)
TRAITS_TABLE_RE = re.compile(r"RiwayahTraitsTable\(\)")
TRAITS_RE = re.compile(r"RiwayahTraits\(name:\s*(" + STR + r"),\s*from:\s*(" + STR + r"),\s*tag:\s*[\w.]+,\s*hamzah:\s*(" + STR
                       + r"),\s*wasl:\s*(" + STR + r"),\s*dots:\s*(" + STR + r"),\s*silah:\s*(" + STR + r"),\s*madd:\s*(" + STR + r")\)", re.S)
RIWAYAT_PAGE = Path(__file__).resolve().parent.parent / "iPhone/Islam/Qiraat/RiwayatDifferencesView.swift"
# `.facts("musa")` / `.mentions("musa")` in a data-backed article, `ProphetFactsSection(prophet: "musa")` /
# `ProphetMentionsSection(prophet: "musa")` in a view-based one (2026-11-24).
PROPHET_BLOCK_RE = re.compile(r'(?<!\w)\.(facts|mentions)\(\s*"([a-z]+)"\s*\)|Prophet(Facts|Mentions)Section\(\s*prophet:\s*"([a-z]+)"\s*\)')
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_prophet_facts as prophet_facts  # noqa: E402
PROPHET_MENTIONS = prophet_facts.mentions()
DESIGN_KIT = Path(__file__).resolve().parent.parent / "iPhone/Islam/Content/ArticleDesign.swift"
QUOTE_RE = re.compile(r"(?:ScriptureQuote|(?<!\w)\.quote)\(\s*text:\s*(" + STR + r")", re.S)
# The same card's Arabic (`arabic:` after the text). It goes to the section's SEARCH-ONLY Arabic
# (`"arabic"` in the pack, 2026-11-24, Abu: "Searching up Arabic or for verses and Hadiths in Islam
# shows nothing"), never to `text`: the Ask AI chat reads `text`, and Apple's on-device model refuses a
# prompt heavy with Arabic.
QUOTE_ARABIC_RE = re.compile(r"(?:ScriptureQuote|(?<!\w)\.quote)\(\s*text:\s*(?:" + STR + r")\s*,\s*arabic:\s*(" + STR + r")", re.S)
# The 10 Qiraat article's "Companions behind each Qiraah" cards (2026-09-26): each reading is
# `lineageRow("Nafi", companions: ["Umar ibn al-Khattab", ...], note: "...")`, drawn as chips, so
# the prose the ten paragraphs used to carry is rebuilt here as one sentence per reading.
LINEAGE_RE = re.compile(r"lineageRow\(\s*(" + STR + r")\s*,\s*companions:\s*\[(.*?)\](?:\s*,\s*note:\s*(" + STR + r"))?\s*\)", re.S)
# A Quran quote by REFERENCE: `ScriptureQuote(quran: "2:255", words: 3...9)` / `.ayah("2:255")`.
# The article carries no copy of the ayah; the app renders it from its own Quran text, and so
# does this corpus (Saheeh International, the app's default translation), so a reference here is
# the same words the screen shows. `words` narrows the screen's emphasis, not the corpus text.
QURAN_RE = re.compile(r"(?:ScriptureQuote\(\s*quran:|(?<!\w)\.ayah\()\s*(" + STR + r")(?:\s*,\s*words:\s*(\d+)\s*\.\.\.\s*(\d+))?", re.S)
# A guide's dua row (`GuideDuaRow(DuaItem(hadith: ..., cite: ..., arabic: ..., english: ...,
# transliteration: ..., note: ...))`) quotes the shelf the same way; its transliteration and note
# are the row's own and stay out of the corpus, like a quote's citation styling.
HADITH_RE = re.compile(r"(?:ScriptureQuote\(\s*hadith:|(?<!\w)\.hadith\(|DuaItem\(\s*hadith:)\s*(" + STR + r")\s*,\s*cite:\s*(" + STR
                       + r")((?:\s*,\s*(?:arabic|english|text|arabicText|transliteration|note):\s*(?:" + STR + r"|\d+\s*\.\.\.\s*\d+|\[[^\]]*\]))*)\s*\)", re.S)
HADITH_ARG_RE = re.compile(r"(arabic|english|text|arabicText):\s*(" + STR + r"|\d+\s*\.\.\.\s*\d+|\[[^\]]*\])", re.S)
RANGE_RE = re.compile(r"(\d+)\s*\.\.\.\s*(\d+)")
# An article's title may be wrapped in `AppLanguage.article(...)`, which keeps it English inside the Arabic
# interface while the articles stay untranslated. Or it carries a catalog key of its own beside the English,
# `String(localized: "prophet.idris", defaultValue: "Idris")` (the prophet is spelled apart from the qiraat
# narrator of the same name in Turkish): the default value is the title. Until 2026-11-22 that spelling was
# not read, so the next rebuild of the pack would have dropped Idris and Ishaq from it without a word.
TITLE_RE = re.compile(r"\.navigationTitle\((?:AppLanguage\.article\(|String\(localized:\s*(?:" + STR
                      + r")\s*,\s*defaultValue:\s*)?(" + STR + r")\)?\)", re.S)
QURAN_JSON = ROOT.parent / "Quran-Tajweed-Engine/sources/Quran.json"
REFERENCE_RE = re.compile(r"^(\d+):(\d+)(?:-(\d+))?((?:,\s*\d+(?:-\d+)?)*)$")

_quran_cache = None


def quran_ayahs():
    """This app's Quran, keyed (surah, ayah)."""
    global _quran_cache
    if _quran_cache is None:
        quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
        _quran_cache = {(s["id"], a["id"]): a for s in quran for a in s["ayahs"]}
    return _quran_cache


def parse_reference(reference: str):
    """"2:255" / "52:35-36" / "2:43, 110" -> (surah, [ayah, ...]) in order, or None when malformed
    or outside this app's Quran."""
    m = REFERENCE_RE.match(reference.strip())
    if not m:
        return None
    surah = int(m.group(1))
    runs = [(int(m.group(2)), int(m.group(3) or m.group(2)))]
    for lo, hi in re.findall(r"(\d+)(?:-(\d+))?", m.group(4) or ""):
        runs.append((int(lo), int(hi or lo)))
    ayahs = quran_ayahs()
    numbers = []
    for lo, hi in runs:
        if lo > hi:
            return None
        numbers += list(range(lo, hi + 1))
    if not numbers or any((surah, n) not in ayahs for n in numbers):
        return None
    return surah, numbers


def quran_quote(reference: str, words=None) -> str:
    """The quote as the screen shows it: the cited ayahs' translation and the citation. Fails the
    build, loudly, on a reference the app cannot render (a dead quote must never ship)."""
    parsed = parse_reference(reference)
    if parsed is None:
        raise SystemExit(f"ERROR: Quran reference {reference!r} is not an ayah of this app")
    surah, numbers = parsed
    ayahs = quran_ayahs()
    if words is not None:
        tokens = sum(len(ayahs[(surah, n)]["textArabic"].split()) for n in numbers)
        if not 0 <= words[0] <= words[1] < tokens:
            raise SystemExit(f"ERROR: Quran reference {reference!r}: words {words} outside its {tokens} tokens")
    english = " ".join(ayahs[(surah, n)]["textEnglishSaheeh"].strip() for n in numbers)
    return f"“{english}” (Quran {reference.strip()})"


def quran_arabic(reference: str) -> str:
    """The cited ayahs' Arabic (the app's Uthmani text), for the section's search-only Arabic. The whole
    ayah, even when `words` narrows the card: a reader may search any part of it."""
    parsed = parse_reference(reference)
    if parsed is None:
        return ""
    surah, numbers = parsed
    ayahs = quran_ayahs()
    return " ".join(ayahs[(surah, n)]["textArabic"].strip() for n in numbers)


def hadith_arabic(args: dict) -> str:
    """The hadith card's Arabic: the referenced words of the row's Arabic, or the literal
    `arabicText`, or nothing when the card shows none."""
    if args["arabicText"]:
        return args["arabicText"]
    if args["arabic"] is None:
        return ""
    slug, _, citation = args["link"].partition(":")
    item = shelf_row(slug, citation) if slug and citation else None
    if item is None:
        return ""
    return shelf_words(item.arabic, [args["arabic"]])


def quran_references():
    """Every Quran reference in the article files: (file, line, reference, words or None)."""
    found = []
    for path in SOURCES:
        src = path.read_text()
        for m in QURAN_RE.finditer(src):
            words = (int(m.group(2)), int(m.group(3))) if m.group(2) else None
            found.append((path.name, src.count("\n", 0, m.start()) + 1, unquote(m.group(1)), words))
    return found

def parse_hadith(link_literal: str, cite_literal: str, args_src: str) -> dict:
    """The arguments of one `ScriptureQuote(hadith:)` / `.hadith(` call, as values."""
    args = {"link": unquote(link_literal), "cite": unquote(cite_literal), "arabic": None, "english": [],
            "text": None, "arabicText": None}
    for name, value in HADITH_ARG_RE.findall(args_src):
        if name in ("text", "arabicText"):
            args[name] = unquote(value)
        elif name == "arabic":
            args["arabic"] = tuple(int(x) for x in RANGE_RE.match(value).groups())
        else:
            args["english"] = [(int(a), int(b)) for a, b in RANGE_RE.findall(value)]
    return args


def hadith_quote(args: dict) -> str:
    """The quote as the screen shows it: the referenced words of the row's translation (or the
    literal `text`) and the citation. Fails the build, loudly, on a row the shelf does not have or a
    range outside it (a dead quote must never ship)."""
    link = args["link"]
    slug, _, citation = link.partition(":")
    item = shelf_row(slug, citation) if slug and citation else None
    if item is None:
        raise SystemExit(f"ERROR: hadith reference {link!r} is not a row of this app's shelf")
    if args["arabic"] is not None:
        first, last = args["arabic"]
        count = token_count(item.arabic)
        if not 0 <= first <= last < count:
            raise SystemExit(f"ERROR: hadith reference {link!r}: arabic {args['arabic']} outside its {count} tokens")
    count = token_count(item.text)
    for first, last in args["english"]:
        if not 0 <= first <= last < count:
            raise SystemExit(f"ERROR: hadith reference {link!r}: english {(first, last)} outside its {count} tokens")
    if args["english"]:
        english = f"\u201c{shelf_words(item.text, args['english'])}\u201d"
    else:
        english = args["text"] or ""
    return f"{english} ({args['cite']})".strip()


def hadith_references():
    """Every hadith reference in the article files: (file, line, parsed arguments)."""
    found = []
    for path in SOURCES:
        src = path.read_text()
        for m in HADITH_RE.finditer(src):
            found.append((path.name, src.count("\n", 0, m.start()) + 1, parse_hadith(m.group(1), m.group(2), m.group(3))))
    return found


# Views that are chrome, not an article: the index screens and the shared pieces.
SKIP_VIEWS = {"GuidesView", "PillarsView", "TajweedFoundationsView", "DebugArticleLink", "ScriptureQuote", "GuideSourcesSection", "ArticleSourcesSection", "ArticleSource",
              "IslamArticleIndexSections"}


def unquote(literal: str) -> str:
    """Swift literal -> its text. Markdown emphasis is dropped: the model reads prose."""
    if literal.startswith('"""'):
        body = literal[3:-3]
        lines = [l for l in body.split("\n")]
        while lines and not lines[0].strip():
            lines.pop(0)
        while lines and not lines[-1].strip():
            lines.pop()
        indent = min((len(l) - len(l.lstrip()) for l in lines if l.strip()), default=0)
        text = "\n".join(l[indent:] for l in lines)
    else:
        text = literal[1:-1]
    out, i = [], 0
    while i < len(text):
        c = text[i]
        if c == "\\" and i + 1 < len(text):
            nxt = text[i + 1]
            if nxt == "u" and text[i + 2 : i + 3] == "{":
                end = text.index("}", i)
                out.append(chr(int(text[i + 3 : end], 16)))
                i = end + 1
                continue
            out.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\", "'": "'", "0": "\0"}.get(nxt, nxt))
            i += 2
            continue
        out.append(c)
        i += 1
    text = "".join(out)
    text = text.replace("**", "").replace("’", "'")
    return re.sub(r"[ \t]+", " ", text).strip()


_ladder_cache = None


def _read_ladders():
    """The two cards' words, read from `HadithGrade.all` and `HadithGrade.byNumber` in
    ArticleDesign.swift (the one copy of those definitions): (the scale of grades, the classes by
    how many carried a report)."""
    global _ladder_cache
    if _ladder_cache is None:
        src = DESIGN_KIT.read_text(encoding="utf-8")
        grades = re.findall(r"HadithGrade\(name:\s*(" + STR + r"),\s*arabic:\s*(" + STR + r"),\s*english:\s*(" + STR
                            + r"),\s*definition:\s*(" + STR + r"),\s*verdict:\s*(" + STR + r")", src, re.S)
        block = src[src.index("static let byNumber"):]
        block = block[:block.index("]\n")]
        numbers = re.findall(r"\(\s*(" + STR + r")\s*,\s*(" + STR + r")\s*,\s*(" + STR + r")\s*\)", block, re.S)
        if len(grades) != 4 or not numbers:
            raise SystemExit("ERROR: could not read the hadith grade scale from ArticleDesign.swift")
        scale = [f"{unquote(n)} ({unquote(a)}), {unquote(e)}: {unquote(d)} {unquote(v)}." for n, a, e, d, v in grades]
        counted = [f"{unquote(n)} ({unquote(a)}): {unquote(m)}." for n, a, m in numbers]
        _ladder_cache = (" ".join(scale), "Counted at the narrowest point of the chain: " + " ".join(counted))
    return _ladder_cache


def grade_ladder_text() -> str:
    """The scale of hadith grades as `HadithGradeLadder` draws it."""
    return _read_ladders()[0]


def count_ladder_text() -> str:
    """The classes of report by how many carried it, as `HadithCountLadder` draws them."""
    return _read_ladders()[1]


_traits_cache = None


def riwayah_traits_text() -> str:
    """The riwayat page's at-a-glance table as sentences, from `RiwayahTraits.all`."""
    global _traits_cache
    if _traits_cache is None:
        rows = TRAITS_RE.findall(RIWAYAT_PAGE.read_text(encoding="utf-8"))
        if len(rows) != 20:
            raise SystemExit(f"ERROR: expected 20 RiwayahTraits rows, found {len(rows)}")
        _traits_cache = " ".join(
            f"{unquote(n)} {unquote(f)}: hamzah {unquote(h)}; hamzat al-wasl {unquote(w)}; tilt {unquote(d)}; "
            f"silah {unquote(si)}; separated madd {unquote(m)}." for n, f, h, w, d, si, m in rows)
    return _traits_cache


def tajweed_body(src: str) -> str:
    """A tajweed file with every `String(localized: "...")` peeled to its literal, so the article
    regexes read it as they read the English-only article files."""
    return LOCALIZED_RE.sub(lambda m: m.group(1), src)


def _closing_bracket(text: str, start: int) -> int:
    """The index of the `]` closing the `[` at `start`, stepping over string literals."""
    depth, i = 0, start
    while i < len(text):
        c = text[i]
        if c == '"':
            m = re.compile(STR, re.S).match(text, i)
            i = m.end() if m else i + 1
            continue
        if c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return len(text)


def _reading(literal: str, note_literal) -> str:
    """One word of a card: its reading, and its note in brackets."""
    reading = unquote(literal)
    note = unquote(note_literal) if note_literal else ""
    return f"{reading} ({note})" if note else reading


def tajweed_hits(body: str):
    """The tajweed kit's cards on one page, as (position, "computed", sentence)."""
    hits = []
    inside_cards = []
    for m in TAJWEED_CARD_RE.finditer(body):
        end = _closing_bracket(body, m.end() - 1)
        inside_cards.append((m.end(), end))
        words = [_reading(w.group(1), w.group(2)) for w in TAJWEED_WORD_RE.finditer(body, m.end(), end)]
        title = unquote(m.group(1)) if m.group(1) else ""
        note = unquote(m.group(2)) if m.group(2) else ""
        label = title if title and title not in TAJWEED_PLAIN_TITLES else ""
        if note:
            label = f"{label} ({note})" if label else note
        if words:
            joined = "; ".join(words)
            hits.append((m.start(), "computed", f"{label}: {joined}." if label else f"{joined}."))
        elif label:
            hits.append((m.start(), "computed", f"{label}."))
    for m in TAJWEED_WORD_RE.finditer(body):
        if not any(lo <= m.start() < hi for lo, hi in inside_cards):
            hits.append((m.start(), "computed", _reading(m.group(1), m.group(2)) + "."))
    for m in TAJWEED_LEAD_RE.finditer(body):
        hits.append((m.start(1), "text", m.group(1)))
    for m in TAJWEED_KEY_RE.finditer(body):
        hits.append((m.start(1), "text", m.group(1)))
    for m in TAJWEED_LINE_RE.finditer(body):
        title = unquote(m.group(1)) if m.group(1) else ""
        caption = unquote(m.group(2)) if m.group(2) else ""
        if caption:
            hits.append((m.start(), "computed",
                         f"{title}: {caption}" if title and title not in TAJWEED_PLAIN_TITLES else caption))
    for m in TAJWEED_FIX_RE.finditer(body):
        hits.append((m.start(1), "computed", f"Instead of {unquote(m.group(1))}, do this: {unquote(m.group(2))}"))
    for m in TAJWEED_STRIP_RE.finditer(body):
        hits.append((m.start(1), "computed", f"{unquote(m.group(1))}: {unquote(m.group(2))}"))
    for m in TAJWEED_CALLOUT_RE.finditer(body):
        paragraphs = " ".join(unquote(p) for p in re.findall(STR, m.group(1), re.S))
        hits.append((m.start(), "computed", f"{unquote(m.group(2))}. {paragraphs}"))
    for m in TAJWEED_SIDE_RE.finditer(body):
        hits.append((m.start(1), "computed", f"{unquote(m.group(1))} ({unquote(m.group(2))}): {unquote(m.group(3))}"))
    return hits


def articles():
    found = []
    for path in SOURCES + TAJWEED_SOURCES:
        found += file_articles(path, tajweed=path in TAJWEED_SOURCES)
    return found


def file_articles(path, tajweed=False):
    """The articles of one source file, each {"id", "title", "sections"}; an article written twice also
    carries "_minutes" (short, long) and "_words" (short, long) for the tools (popped before the pack)."""
    found = []
    if True:
        src = tajweed_body(path.read_text()) if tajweed else path.read_text()
        bounds = [(m.group(1), m.start()) for m in STRUCT_RE.finditer(src)]
        bounds.append(("", len(src)))
        for (name, start), (_, end) in zip(bounds, bounds[1:]):
            if name in SKIP_VIEWS:
                continue
            body = src[start:end]
            title = TITLE_RE.search(body)
            if not title:
                continue  # no navigation title: not a page the reader can land on
            # One ordered pass so section headings, prose and quotes keep the screen's order.
            hits = []
            for regex, kind in ((SECTION_RE, "heading"), (QUOTE_RE, "quote"), (TEXT_RE, "text")):
                for m in regex.finditer(body):
                    hits.append((m.start(1), kind, m.group(1)))
            for m in QURAN_RE.finditer(body):
                words = (int(m.group(2)), int(m.group(3))) if m.group(2) else None
                hits.append((m.start(1), "ayah", (m.group(1), words)))
                hits.append((m.start(1), "arabic", quran_arabic(unquote(m.group(1)))))
            for m in HADITH_RE.finditer(body):
                args = parse_hadith(m.group(1), m.group(2), m.group(3))
                hits.append((m.start(1), "hadith", (m.group(1), args)))
                hits.append((m.start(1), "arabic", hadith_arabic(args)))
            for m in QUOTE_ARABIC_RE.finditer(body):
                hits.append((m.start(), "arabic", unquote(m.group(1))))
            for m in LINEAGE_RE.finditer(body):
                names = [unquote(n) for n in re.findall(STR, m.group(2))]
                sentence = f"{unquote(m.group(1))}: transmitted from {', '.join(names)}."
                if m.group(3):
                    sentence += f" {unquote(m.group(3))}."
                hits.append((m.start(1), "computed", sentence))
            # The design kit's cards (see the regexes above).
            for m in CALLOUT_RE.finditer(body):
                hits.append((m.start(1), "computed", f"{unquote(m.group(2))}. {unquote(m.group(1))}"))
            for m in TERM_RE.finditer(body):
                hits.append((m.start(1), "computed", f"{unquote(m.group(1))} ({unquote(m.group(2))}): {unquote(m.group(3))}"))
            for m in STAT_RE.finditer(body):
                hits.append((m.start(1), "computed", f"{unquote(m.group(1))} {unquote(m.group(2))}."))
            for m in CHAIN_CAPTION_RE.finditer(body):
                hits.append((m.start(), "computed", f"{unquote(m.group(1))}:"))
            for m in CHAIN_LINK_RE.finditer(body):
                detail = f", {unquote(m.group(2))}" if m.group(2) and unquote(m.group(2)) else ""
                hits.append((m.start(1), "computed", f"{unquote(m.group(1))}{detail}."))
            for m in ISNAD_RE.finditer(body):
                hits.append((m.start(1), "computed", unquote(m.group(1))))
            for m in CHECKLIST_RE.finditer(body):
                items = [unquote(item) for item in re.findall(STR, m.group(1))]
                hits.append((m.start(), "computed", f"{unquote(m.group(2)).rstrip(':')}: " + " ".join(items)))
            for m in SIDE_RE.finditer(body):
                arabic = f" ({unquote(m.group(2))})" if m.group(2) else ""
                hits.append((m.start(1), "computed", f"{unquote(m.group(1))}{arabic}: {unquote(m.group(3))}"))
            for m in LADDER_RE.finditer(body):
                hits.append((m.start(), "computed", grade_ladder_text()))
            for m in COUNT_LADDER_RE.finditer(body):
                hits.append((m.start(), "computed", count_ladder_text()))
            for m in SPELLING_CARD_RE.finditer(body):
                hits.append((m.start(1), "computed", f"{unquote(m.group(1))}:"))
            for m in SPELLING_RE.finditer(body):
                hits.append((m.start(1), "computed", f"{unquote(m.group(1))} ({unquote(m.group(2))}): {unquote(m.group(3))}."))
            for m in BAR_CHART_RE.finditer(body):
                hits.append((m.start(1), "computed", f"{unquote(m.group(1))}:"))
            for m in BAR_RE.finditer(body):
                hits.append((m.start(1), "computed", f"{unquote(m.group(1))}: {m.group(2)} filled dots, {m.group(3)} hollow rings."))
            for m in TRAITS_TABLE_RE.finditer(body):
                hits.append((m.start(), "computed", riwayah_traits_text()))
            # A prophet's facts card and the ayahs that name him (2026-11-24), generated by
            # build_prophet_facts.py: the same words the cards show. The view-based Pillars pages draw
            # each as a section of its own, so those carry their heading too.
            for m in PROPHET_BLOCK_RE.finditer(body):
                kind, key = m.group(1) or m.group(3), m.group(2) or m.group(4)
                if m.group(3):
                    heading = "AT A GLANCE" if kind == "Facts" else "NAMED IN THE QURAN"
                    hits.append((m.start(), "heading", '"' + heading + '"'))
                text = prophet_facts.facts_text(key, PROPHET_MENTIONS) if kind.lower() == "facts" else prophet_facts.mentions_text(key, PROPHET_MENTIONS)
                hits.append((m.start() + 1, "computed", text))
            if tajweed:
                hits += tajweed_hits(body)
            # A section header IS a Text(...), so it matches twice - keep the heading, drop the twin.
            headings = {pos for pos, kind, _ in hits if kind == "heading"}
            hits = [h for h in hits if not (h[1] == "text" and h[0] in headings)]
            hits.sort(key=lambda h: (h[0], h[1]))
            # The two versions (article_zones.py). The pack carries the LONG version: what both show, and
            # what only the long one shows as parts of their own (`"only": "long"`), so a search hit there
            # opens the page in full. What only the short version shows is a retelling of the long one and
            # is left out of the pack; it is only counted, for the short version's reading time.
            marks = article_zones.zones(body)
            words = {"short": 0, "long": 0}
            sections, heading, parts = [], None, {}

            def part(only):
                nonlocal heading, parts
                if heading is None:
                    heading = ""
                if only not in parts:
                    parts[only] = {"heading": heading, "text": [], "arabic": [], "only": only}
                    sections.append(parts[only])
                return parts[only]

            for pos, kind, literal in hits:
                only = article_zones.zone_at(marks, pos)
                if kind == "arabic":
                    if literal and only != "short":
                        part(only)["arabic"].append(literal)
                    continue
                if kind == "ayah":
                    literal, ayah_words = literal
                    value = quran_quote(unquote(literal), ayah_words)
                elif kind == "hadith":
                    literal, args = literal
                    value = hadith_quote(args)
                elif kind == "computed":
                    value, literal = literal, ""
                else:
                    value = unquote(literal)
                if not value or "\\(" in literal:
                    continue
                if kind == "heading":
                    if only == "short":
                        continue
                    heading, parts = value, {}
                    part(only)
                    continue
                count = len(value.split())
                if only != "short":
                    words["long"] += count
                if only != "long":
                    words["short"] += count
                if only == "short":
                    continue
                part(only)["text"].append(value)
            title_text = unquote(title.group(1))
            body_sections = [
                {"heading": s["heading"], "text": "\n".join(s["text"]),
                 **({"arabic": "\n".join(s["arabic"])} if s["arabic"] else {}),
                 **({"only": s["only"]} if s["only"] else {})}
                for s in sections
                if s["text"] and s["heading"] != title_text
            ]
            if not body_sections:
                continue
            article = {"id": name, "title": title_text, "sections": body_sections}
            if marks:
                article["_minutes"] = tuple(max(1, round(words[v] / READING_SPEED)) for v in ("short", "long"))
                article["_words"] = (words["short"], words["long"])
            found.append(article)
    return found


def write_lengths(items) -> None:
    """ArticleLengths.swift: the reading time of each version of every article written twice."""
    LENGTHS_OUT.write_text(lengths_text(items))


def lengths_text(items) -> str:
    """What ArticleLengths.swift holds for `items` (verify_islam_corpus.py compares it with the file)."""
    rows = [f'        "{a["id"]}": Minutes(short: {a["_minutes"][0]}, long: {a["_minutes"][1]}),'
            for a in sorted(items, key=lambda a: a["id"]) if "_minutes" in a]
    table = "[\n" + "\n".join(rows) + "\n    ]" if rows else "[:]"
    return (
        "// Generated by Scripts/build_islam_corpus.py from the articles' marks (ArticleLength.swift). Do not edit.\n\n"
        "enum ArticleLengths {\n"
        "    /// Minutes each version takes to read.\n"
        "    struct Minutes: Equatable, Sendable {\n"
        "        let short: Int\n"
        "        let long: Int\n"
        "    }\n\n"
        "    /// The articles written twice, by catalog id: the pages that draw the switch.\n"
        f"    static let minutes: [String: Minutes] = {table}\n"
        "}\n")


def main():
    items = articles()
    if "--print" in sys.argv:
        for a in items:
            chars = sum(len(s["text"]) for s in a["sections"])
            print(f'{a["id"]:28s} {a["title"][:42]:44s} {len(a["sections"])} sections, {chars} chars')
        print(f"\n{len(items)} articles, {sum(sum(len(s['text']) for s in a['sections']) for a in items)} chars")
        return
    write_lengths(items)
    for a in items:
        a.pop("_minutes", None)
        a.pop("_words", None)
    payload = json.dumps({"version": 1, "articles": items}, ensure_ascii=False).encode()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Raw deflate, no zlib header: what `compression_decode_buffer(COMPRESSION_ZLIB)` reads.
    packer = zlib.compressobj(9, zlib.DEFLATED, -zlib.MAX_WBITS)
    OUT.write_bytes(packer.compress(payload) + packer.flush())
    print(f"{OUT.relative_to(ROOT)}: {len(items)} articles, {len(payload)} -> {OUT.stat().st_size} bytes")


if __name__ == "__main__":
    main()
