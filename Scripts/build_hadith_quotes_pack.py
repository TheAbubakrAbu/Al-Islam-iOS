#!/usr/bin/env python3
"""Build Resources/Data/Islam/HadithQuotes.json.deflate: the rows the Watch app needs for the
hadith the articles and the Dua screen quote by reference.

    ./Scripts/build_hadith_quotes_pack.py

The phone reads a referenced narration ("bukhari:6306" plus token ranges, see
iPhone/Islam/HadithQuote.swift) straight out of the bundled .hpk shelf. The Watch app compiles the
same article files and the Dua screen but bundles no shelf (the collections are 12 MB it has no
other use for), so it carries this: the referenced rows only, copied from the shelf at build time.
It is the one derived copy of hadith text the project ships, it ships ONLY in the Watch target
(the phone never bundles it), and Scripts/verify_islam_corpus.py refuses a build where it is not
byte-identical to a fresh build from the shelf, so it cannot drift from the .hpk it was cut from.

Pack: {"version": 1, "rows": {"bukhari:6306": [arabic, narrator, text], ...}} sorted by link,
raw deflate like IslamArticles.json.deflate (inflated by `IslamArticles.inflate`).
"""
from __future__ import annotations

import json
import re
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hadith_spans import row as shelf_row  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SOURCES = [ROOT / "iPhone/Islam" / name for name in (
    "PillarViews.swift", "BeliefsViews.swift", "HowToGuides.swift", "AqeedahViews.swift",
    "SalafiyyahViews.swift", "AnswersViews.swift", "ScholarsViews.swift", "DuaView.swift")]
OUT = ROOT / "Resources/Data/Islam/HadithQuotes.json.deflate"
# `hadith: "slug:citation"` (ScriptureQuote, DuaItem) and `.hadith("slug:citation"` (article blocks).
LINK_RE = re.compile(r'(?:hadith:\s*|(?<!\w)\.hadith\(\s*)"([a-z_0-9]+:(?:\d+[a-z]?|#\d+))"')


def links() -> list[str]:
    found = set()
    for path in SOURCES:
        if path.exists():
            found.update(LINK_RE.findall(path.read_text(encoding="utf-8")))
    return sorted(found)


def build() -> bytes:
    rows = {}
    for link in links():
        slug, _, citation = link.partition(":")
        item = shelf_row(slug, citation)
        if item is None:
            raise SystemExit(f"ERROR: {link} is referenced but is not a row of the shelf")
        rows[link] = [item.arabic, item.narrator, item.text]
    payload = json.dumps({"version": 1, "rows": rows}, ensure_ascii=False, sort_keys=True,
                         separators=(",", ":")).encode("utf-8")
    packer = zlib.compressobj(9, zlib.DEFLATED, -zlib.MAX_WBITS)
    return packer.compress(payload) + packer.flush()


def main() -> None:
    data = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(data)
    print(f"{OUT.relative_to(ROOT)}: {len(links())} referenced rows, {len(data)} bytes")


if __name__ == "__main__":
    main()
