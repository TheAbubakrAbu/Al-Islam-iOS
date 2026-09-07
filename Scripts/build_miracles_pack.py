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


def main():
    text = SRC.read_text(encoding="utf-8")
    start = text.index("= [", text.index("MIRACLES_EN")) + 2
    end = text.rindex("];") + 1
    articles = json.loads(text[start:end])
    assert all(a["category"] in dict(CATEGORIES) for a in articles), "unknown category"
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
    print(f"{len(articles)} articles, {ayahs} ayah blocks, {quotes} quotes, {media} images; "
          f"{len(raw):,} bytes raw -> {OUT.stat().st_size:,} bytes xz -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
