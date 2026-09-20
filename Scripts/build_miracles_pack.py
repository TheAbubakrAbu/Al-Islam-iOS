#!/usr/bin/env python3
"""Build Resources/Data/Islam/Miracles.json.xz from Tilawa's Miracles of the Quran capture.

    ./Scripts/build_miracles_pack.py [/path/to/Tilawa]

Tilawa (Jamil Hammoudeh, with permission) captured miracles-of-quran.com's 202 articles into
src/data/generated/miraclesEn.ts: the site waives copyright on its own prose, third-party excerpts
are trimmed to attributed quotes at import, Quran verses are references (drawn from our own text at
render time), and the images stay on Tilawa's CDN (https://miracles.tilawaai.app/). This script
lifts the English capture into the app's pack format unchanged: one object per article with its
slug, title, category, level and blocks.
"""
import json, lzma, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TILAWA = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Tilawa"
SRC = TILAWA / "src/data/generated/miraclesEn.ts"
OUT = ROOT / "Resources/Data/Islam/Miracles.json.xz"

CATEGORIES = [
    ("history", "simple"), ("egyptology", "simple"), ("zoology", "simple"),
    ("botany", "simple"), ("mathematics", "simple"),
    ("biology", "intermediate"), ("physiology", "intermediate"),
    ("geology", "intermediate"), ("hydrology", "intermediate"), ("meteorology", "intermediate"),
    ("embryology", "advanced"), ("chemistry", "advanced"),
    ("physics", "advanced"), ("astronomy", "advanced"), ("cosmology", "advanced"),
]


# The capture glued each excerpt's own page/section heading onto the front of the quote with no
# separator, so the reader saw "PetraPetra is believed to have been settled..." and, on 98 quotes,
# a word repeated or a stray heading run into the first sentence (Abu, 2026-09-19).
#
# The heading is a Title Case run at position 0 butted directly against the next capital letter.
# 88 of the 98 name something the `sourceLabel` already says ("Camels" under "Wikipedia, Camel"),
# so those are simply dropped. The other 10 name a SUBSECTION the label does not ("Abstract" under
# an Oxford Academic paper, "Work by gravity" under "Work (physics)") - those are kept and folded
# into the label as "<label> - <heading>", so nothing is lost and nothing reads as a typo.
GLUED_HEADING = re.compile(r"^((?:[A-Z][a-z'\u2019]+)(?:[ \-][A-Z]?[a-z'\u2019]+){0,3})(?=[A-Z])")


def unglue_quote_headings(articles):
    """Split a run-on heading off the front of every quote. Returns how many were repaired."""
    repaired = 0
    for article in articles:
        for block in article.get("blocks", []):
            if block.get("kind") != "quote":
                continue
            match = GLUED_HEADING.match(block.get("text", ""))
            if not match:
                continue
            heading = match.group(1)
            label = block.get("sourceLabel", "")
            block["text"] = block["text"][len(heading):].lstrip()
            if heading.lower() not in label.lower():
                block["sourceLabel"] = f"{label} - {heading}" if label else heading
            repaired += 1
    return repaired


def main():
    text = SRC.read_text(encoding="utf-8")
    start = text.index("= [", text.index("MIRACLES_EN")) + 2
    end = text.rindex("];") + 1
    articles = json.loads(text[start:end])
    assert all(a["category"] in dict(CATEGORIES) for a in articles), "unknown category"
    unglued = unglue_quote_headings(articles)
    media = sum(1 for a in articles for b in a["blocks"] if b["kind"] == "image")
    quotes = sum(1 for a in articles for b in a["blocks"] if b["kind"] == "quote")
    ayahs = sum(1 for a in articles for b in a["blocks"] if b["kind"] == "ayah")
    pack = {
        "version": 1,
        "source": "miracles-of-quran.com, captured 2026-09-06 by Tilawa (scripts/miracles-import.mjs)",
        "imageBase": "https://miracles.tilawaai.app/",
        "categories": [{"id": c, "level": l} for c, l in CATEGORIES],
        "articles": articles,
    }
    raw = json.dumps(pack, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(lzma.compress(raw, format=lzma.FORMAT_XZ, preset=9 | lzma.PRESET_EXTREME))
    print(f"unglued {unglued} run-on quote headings")
    print(f"{len(articles)} articles, {ayahs} ayah blocks, {quotes} quotes, {media} images; "
          f"{len(raw):,} bytes raw -> {OUT.stat().st_size:,} bytes xz -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
