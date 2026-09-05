#!/usr/bin/env python3
"""Build the Islam-tab article corpus the Ask AI chat retrieves from.

The Pillars, Beliefs and How-to articles are written as SwiftUI views with their
prose inline - there is no data layer to search. This walks those view files and
lifts the prose back out: one record per article view, its sections in the order
the screen shows them, so the chat can hand the model the app's OWN wording
instead of whatever the model half-remembers.

    ./Scripts/build_islam_corpus.py            # write the pack
    ./Scripts/build_islam_corpus.py --print    # dump what it found, write nothing

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
TITLE_RE = re.compile(r"\.navigationTitle\((" + STR + r")\)", re.S)

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
            # A section header IS a Text(...), so it matches twice - keep the heading, drop the twin.
            headings = {pos for pos, kind, _ in hits if kind == "heading"}
            hits = [h for h in hits if not (h[1] == "text" and h[0] in headings)]
            hits.sort()
            sections, current = [], None
            for pos, kind, literal in hits:
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
