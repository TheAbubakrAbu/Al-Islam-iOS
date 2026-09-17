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
(Resources/JSONs-Deprecated/Quran.json, Saheeh International) so the corpus
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

ROOT = Path(__file__).resolve().parent.parent
SOURCES = [
    ROOT / "iPhone/Islam/PillarsView.swift",
    ROOT / "iPhone/Islam/PillarViews.swift",
    ROOT / "iPhone/Islam/BeliefsViews.swift",
    ROOT / "iPhone/Islam/HowToGuides.swift",
    ROOT / "iPhone/Islam/AqeedahViews.swift",
    ROOT / "iPhone/Islam/SalafiyyahViews.swift",
    ROOT / "iPhone/Islam/ScholarsViews.swift",
    ROOT / "iPhone/Islam/AnswersViews.swift",
]
OUT = ROOT / "Resources/Data/Islam/IslamArticles.json.deflate"

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
TEXT_RE = re.compile(r"(?:(?<![\w.])Text\(" + TEXT_ARG + r"|(?<!\w)\.(?:text|markdown)\()(" + STR + r")\)", re.S)
QUOTE_RE = re.compile(r"(?:ScriptureQuote|(?<!\w)\.quote)\(\s*text:\s*(" + STR + r")", re.S)
# A Quran quote by REFERENCE: `ScriptureQuote(quran: "2:255", words: 3...9)` / `.ayah("2:255")`.
# The article carries no copy of the ayah; the app renders it from its own Quran text, and so
# does this corpus (Saheeh International, the app's default translation), so a reference here is
# the same words the screen shows. `words` narrows the screen's emphasis, not the corpus text.
QURAN_RE = re.compile(r"(?:ScriptureQuote\(\s*quran:|(?<!\w)\.ayah\()\s*(" + STR + r")(?:\s*,\s*words:\s*(\d+)\s*\.\.\.\s*(\d+))?", re.S)
HADITH_RE = re.compile(r"(?:ScriptureQuote\(\s*hadith:|(?<!\w)\.hadith\()\s*(" + STR + r")\s*,\s*cite:\s*(" + STR
                       + r")((?:\s*,\s*(?:arabic|english|text|arabicText):\s*(?:" + STR + r"|\d+\s*\.\.\.\s*\d+|\[[^\]]*\]))*)\s*\)", re.S)
HADITH_ARG_RE = re.compile(r"(arabic|english|text|arabicText):\s*(" + STR + r"|\d+\s*\.\.\.\s*\d+|\[[^\]]*\])", re.S)
RANGE_RE = re.compile(r"(\d+)\s*\.\.\.\s*(\d+)")
TITLE_RE = re.compile(r"\.navigationTitle\((" + STR + r")\)", re.S)
QURAN_JSON = ROOT / "Resources/JSONs-Deprecated/Quran.json"
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
SKIP_VIEWS = {"GuidesView", "PillarsView", "DebugArticleLink", "ScriptureQuote", "GuideSourcesSection", "ArticleSourcesSection", "ArticleSource",
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


def articles():
    found = []
    for path in SOURCES:
        src = path.read_text()
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
            for m in HADITH_RE.finditer(body):
                hits.append((m.start(1), "hadith", (m.group(1), parse_hadith(m.group(1), m.group(2), m.group(3)))))
            # A section header IS a Text(...), so it matches twice - keep the heading, drop the twin.
            headings = {pos for pos, kind, _ in hits if kind == "heading"}
            hits = [h for h in hits if not (h[1] == "text" and h[0] in headings)]
            hits.sort()
            sections, current = [], None
            for pos, kind, literal in hits:
                if kind == "ayah":
                    literal, words = literal
                    value = quran_quote(unquote(literal), words)
                elif kind == "hadith":
                    literal, args = literal
                    value = hadith_quote(args)
                else:
                    value = unquote(literal)
                if not value or "\\(" in literal:
                    continue
                if kind == "heading":
                    current = {"heading": value, "text": []}
                    sections.append(current)
                    continue
                if current is None:
                    current = {"heading": "", "text": []}
                    sections.append(current)
                current["text"].append(value)
            title_text = unquote(title.group(1))
            body_sections = [
                {"heading": s["heading"], "text": "\n".join(s["text"])}
                for s in sections
                if s["text"] and s["heading"] != title_text
            ]
            if not body_sections:
                continue
            found.append({"id": name, "title": title_text, "sections": body_sections})
    return found


def main():
    items = articles()
    if "--print" in sys.argv:
        for a in items:
            chars = sum(len(s["text"]) for s in a["sections"])
            print(f'{a["id"]:28s} {a["title"][:42]:44s} {len(a["sections"])} sections, {chars} chars')
        print(f"\n{len(items)} articles, {sum(sum(len(s['text']) for s in a['sections']) for a in items)} chars")
        return
    payload = json.dumps({"version": 1, "articles": items}, ensure_ascii=False).encode()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Raw deflate, no zlib header: what `compression_decode_buffer(COMPRESSION_ZLIB)` reads.
    packer = zlib.compressobj(9, zlib.DEFLATED, -zlib.MAX_WBITS)
    OUT.write_bytes(packer.compress(payload) + packer.flush())
    print(f"{OUT.relative_to(ROOT)}: {len(items)} articles, {len(payload)} -> {OUT.stat().st_size} bytes")


main()
