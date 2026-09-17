#!/usr/bin/env python3
"""Build the quote packs the siblings need, which quote the Quran and the hadith shelf but do not
ship a reader for both.

    ./Scripts/build_sibling_quote_packs.py [--check]

Al-Islam resolves an article's `ScriptureQuote(quran: "2:255")` through `QuranData` and its
`hadith: "bukhari:6306"` through the bundled .hpk shelf, so an article always shows exactly what the
reader finds in the Quran or Hadith tab. The siblings compile the same article files, the same Dua
screen and the same Reminder of the Day, without both readers:

  Al-Adhan  has neither Quran nor hadith  -> both packs
  Al-Quran  has QuranData, no hadith code -> the hadith pack only

So they carry the referenced ayahs and narrations only, cut from Al-Islam's own text at build time.

They are derived copies, so the same rule governs them as governs the Watch's
HadithQuotes.json.deflate: reproducible from the source, and `--check` fails when a fresh build
would differ. That is what stops them drifting from the text they are supposed to be quoting.

Why this is separate from Scripts/build_hadith_quotes_pack.py: that one cuts the rows the WATCH
needs, and the Watch does not compile DailyReminders.swift, so it needs no reminder rows. The
siblings do compile it, so their hadith pack is the union of the article/Dua links and the reminder
links (548 rows against the Watch's 501). Al-Islam's pack is byte-gated by verify_islam_corpus.py
and is deliberately left alone here.

Packs (both raw deflate, inflated by `IslamArticles.inflate`):
  QuranQuotes.json.deflate   {"version": 1, "rows": {"2:255": [arabic, english], ...}}
  HadithQuotes.json.deflate  {"version": 1, "rows": {"bukhari:6306": [arabic, narrator, text], ...}}

The Quran English is Saheeh International, the translation the sibling's own articles name as their
source. Al-Islam lets the reader choose between Saheeh and Mustafa Khattab because its Quran tab has
that setting; the sibling has no Quran tab and no such setting, so only one travels.
"""
from __future__ import annotations

import json
import lzma
import re
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hadith_spans import row as shelf_row  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
QURAN = ROOT / "Resources/JSONs-Deprecated/Quran.json"

# Which packs each sibling needs: "quran" only where the app ships no Quran text of its own.
SIBLINGS = {
    "Al-Adhan-iOS": ("quran", "hadith"),
    "Al-Quran-iOS": ("hadith",),
}

# `quran: "2:255"` as ScriptureQuote and DuaItem both write it.
QURAN_RE = re.compile(r'quran:\s*"(\d+:[0-9,\s-]+)"')
# `hadith: "slug:citation"` (ScriptureQuote, DuaItem) and `.hadith("slug:citation"` (article blocks).
HADITH_RE = re.compile(r'(?:hadith:\s*|(?<!\w)\.hadith\(\s*)"([a-z_0-9]+:(?:\d+[a-z]?|#\d+))"')


def deflate(payload: dict) -> bytes:
    raw = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    packer = zlib.compressobj(9, zlib.DEFLATED, -zlib.MAX_WBITS)
    return packer.compress(raw) + packer.flush(), len(raw)


def swift_sources(sibling: Path) -> list[Path]:
    return sorted((sibling / "iPhone/Islam").glob("*.swift"))


# ---------------------------------------------------------------- Quran

def quran_references(sibling: Path) -> list[str]:
    found: set[str] = set()
    for path in swift_sources(sibling):
        found.update(m.strip() for m in QURAN_RE.findall(path.read_text(encoding="utf-8")))
    return sorted(found)


def parse_reference(reference: str) -> tuple[int, list[int]] | None:
    """"2:255" / "52:35-36" / "2:43, 110" -> (surah, [ayahs]). Mirrors QuranQuoteReference."""
    surah_text, _, rest = reference.partition(":")
    if not rest:
        return None
    try:
        surah = int(surah_text)
    except ValueError:
        return None
    if not 1 <= surah <= 114:
        return None
    ayahs: list[int] = []
    for piece in rest.split(","):
        try:
            bounds = [int(b.strip()) for b in piece.strip().split("-")]
        except ValueError:
            return None
        if len(bounds) == 1:
            ayahs.append(bounds[0])
        elif len(bounds) == 2 and bounds[0] <= bounds[1]:
            ayahs.extend(range(bounds[0], bounds[1] + 1))
        else:
            return None
    return surah, ayahs


def build_quran(sibling: Path) -> tuple[bytes, int, int]:
    quran = json.loads(QURAN.read_text(encoding="utf-8"))
    by_surah = {s["id"]: {a["id"]: a for a in s["ayahs"]} for s in quran}

    rows: dict[str, list[str]] = {}
    for reference in quran_references(sibling):
        parsed = parse_reference(reference)
        if parsed is None:
            raise SystemExit(f"ERROR: {reference} is quoted but is not a reference this app can parse")
        surah, numbers = parsed
        ayahs = by_surah.get(surah, {})
        arabic, english = [], []
        for number in numbers:
            ayah = ayahs.get(number)
            if ayah is None:
                raise SystemExit(f"ERROR: {reference} is quoted but {surah}:{number} is not in the Quran")
            arabic.append(ayah["textArabic"])
            english.append(ayah["textEnglishSaheeh"])
        rows[reference] = [" ".join(arabic), " ".join(english)]
    packed, raw_size = deflate({"version": 1, "rows": rows})
    return packed, len(rows), raw_size


# --------------------------------------------------------------- Hadith

def hadith_links(sibling: Path) -> list[str]:
    """Article/Dua links plus the Reminder of the Day's, which the Watch's pack does not carry."""
    found: set[str] = set()
    for path in swift_sources(sibling):
        found.update(HADITH_RE.findall(path.read_text(encoding="utf-8")))
    reminders = sibling / "Resources/Data/Islam/DailyReminders.json.xz"
    if reminders.exists():
        pack = json.loads(lzma.open(reminders).read())
        for entry in pack.get("entries", []):
            link = entry.get("hadith")
            if link:
                found.add(link)
    return sorted(found)


def build_hadith(sibling: Path) -> tuple[bytes, int, int]:
    rows: dict[str, list[str]] = {}
    for link in hadith_links(sibling):
        slug, _, citation = link.partition(":")
        item = shelf_row(slug, citation)
        if item is None:
            raise SystemExit(f"ERROR: {link} is referenced but is not a row of the shelf")
        rows[link] = [item.arabic, item.narrator, item.text]
    packed, raw_size = deflate({"version": 1, "rows": rows})
    return packed, len(rows), raw_size


# ----------------------------------------------------------------- main

BUILDERS = {"quran": build_quran, "hadith": build_hadith}


def main() -> None:
    check = "--check" in sys.argv[1:]
    failures = []
    for name, kinds in SIBLINGS.items():
        sibling = ROOT.parent / name
        if not sibling.exists():
            print(f"{name}: not beside Al-Islam, skipped")
            continue
        for kind in kinds:
            out = sibling / f"Resources/Data/Islam/{kind.capitalize()}Quotes.json.deflate"
            packed, count, raw_size = BUILDERS[kind](sibling)
            if check:
                if not out.exists():
                    failures.append(f"{name} {kind}: {out} does not exist")
                elif out.read_bytes() != packed:
                    failures.append(f"{name} {kind}: {out.name} is not what a fresh build produces")
                else:
                    print(f"{name} {kind} OK: {count} rows, {raw_size} bytes raw, {len(packed)} packed")
            else:
                out.parent.mkdir(parents=True, exist_ok=True)
                out.write_bytes(packed)
                print(f"{name} {kind}: {count} rows, {raw_size} bytes raw, {len(packed)} packed -> {out.name}")
    if failures:
        for line in failures:
            print(line, file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
