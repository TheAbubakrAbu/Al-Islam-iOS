#!/usr/bin/env python3
"""Where an article's source marks a part that only one of its two versions shows.

Every article is written twice over one source (iPhone/Islam/Content/ArticleLength.swift, 2026-11-25): what is
unmarked is in both, and a part only one version shows is marked one of three ways:

    ArticleSection("HEADING", only: .long, [ ... ])          a data-backed section
    .longOnly(.text("..."))   .shortOnly(.ayah("2:255"))     one block of a section
    ArticleOnly(.long) { Section(header: ...) { ... } }      a view-based page's sections

`zones(text)` finds those spans; `zone_at` says which version a position belongs to (None: both);
`version(text, keep)` blanks what the other version shows, keeping every offset and line number, so the tools
that read a file line by line (the quote coverage, the gates) can read one version as they read a whole file.
"""
import re

STR = re.compile(r'"""(?:.*?)"""|"(?:[^"\\\n]|\\.)*"', re.S)
OPEN = {"(": ")", "[": "]", "{": "}"}

SECTION_RE = re.compile(r'(?<![\w.])ArticleSection\(\s*"(?:[^"\\\n]|\\.)*"\s*,\s*only:\s*\.(long|short)\s*,')
BLOCK_RE = re.compile(r'(?<![\w.])\.(long|short)Only\(')
VIEW_RE = re.compile(r'(?<![\w.])ArticleOnly\(\s*\.(long|short)\s*\)\s*\{')


def closing(text: str, start: int) -> int:
    """The index just past the bracket that closes the one at `start`, stepping over string literals."""
    stack, i = [], start
    while i < len(text):
        c = text[i]
        if c == '"':
            m = STR.match(text, i)
            i = m.end() if m else i + 1
            continue
        if c == "/" and text.startswith("//", i):
            nl = text.find("\n", i)
            i = len(text) if nl == -1 else nl
            continue
        if c in OPEN:
            stack.append(OPEN[c])
        elif c in ")]}":
            if not stack or stack[-1] != c:
                raise ValueError(f"unbalanced {c!r} at offset {i}")
            stack.pop()
            if not stack:
                return i + 1
        i += 1
    raise ValueError(f"no closing bracket for offset {start}")


def zones(text: str):
    """[(start, end, "long" | "short")] for every marked part, outermost and innermost alike."""
    found = []
    for m in SECTION_RE.finditer(text):
        open_at = text.index("(", m.start())
        found.append((m.start(), closing(text, open_at), m.group(1)))
    for m in BLOCK_RE.finditer(text):
        found.append((m.start(), closing(text, m.end() - 1), m.group(1)))
    for m in VIEW_RE.finditer(text):
        found.append((m.start(), closing(text, m.end() - 1), m.group(1)))
    found.sort()
    return found


def zone_at(found, pos: int):
    """The version the innermost zone holding `pos` belongs to, or None (both)."""
    best = None
    for start, end, only in found:
        if start <= pos < end and (best is None or start >= best[0]):
            best = (start, only)
    return best[1] if best else None


def version(text: str, keep: str) -> str:
    """`text` with what only the other version shows blanked out (spaces, newlines kept)."""
    other = "short" if keep == "long" else "long"
    out = list(text)
    for start, end, only in zones(text):
        if only == other:
            for i in range(start, end):
                if out[i] != "\n":
                    out[i] = " "
    return "".join(out)
