#!/usr/bin/env python3
"""Download the per-word transliteration layer that backs "tap a word" in the reader.

The English glosses were fetched once into `word-by-word-en.json` (see the sibling
`build_wordbyword.py`, which aligns them against this app's own Hafs tokens). The same
upstream - Quran.com's QDC API - also carries a per-word Latin transliteration, which the
original fetch deliberately dropped. This script fetches ONLY that layer and writes it in
the same shape, keyed the same way, so the two files merge by position:

    {"1:1": [{"p": 1, "a": "بِسْمِ", "t": "bis'mi"}, ...], ...}

`a` (the upstream Uthmani spelling) is kept because `build_wordbyword.py` aligns on it -
the transliteration alone could not be matched to a token.

    python3 Scripts/fetch_wordbyword.py [out.json]

Defaults next to the English file, at ../Tilawa/assets/quran/word-by-word-translit.json.
Resumable: chapters already present in the output are skipped, so a dropped connection
costs only the chapters that had not landed yet.
"""

from __future__ import annotations

import json
import pathlib
import sys
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT.parent / "Tilawa" / "assets" / "quran" / "word-by-word-translit.json"

FIELDS = "text_uthmani,transliteration,position,char_type_name"
URL = ("https://api.qurancdn.com/api/qdc/verses/by_chapter/{chapter}"
       "?words=true&word_translation_language=en&per_page=300&word_fields=" + FIELDS)


def fetch(chapter: int) -> list[dict]:
    request = urllib.request.Request(URL.format(chapter=chapter),
                                     headers={"User-Agent": "al-islam-build/1.0"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.loads(response.read().decode("utf-8")).get("verses", [])


def words_of(verse: dict) -> list[dict]:
    out = []
    for word in verse.get("words", []):
        # Rosette ayah-markers: not words, and never carry a transliteration.
        if word.get("char_type_name") == "end":
            continue
        translit = word.get("transliteration")
        text = translit.get("text") or "" if isinstance(translit, dict) else (translit or "")
        out.append({"p": word.get("position"), "a": word.get("text_uthmani") or "", "t": text})
    return out


def main() -> None:
    out_path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_OUT
    out_path.parent.mkdir(parents=True, exist_ok=True)

    table: dict[str, list[dict]] = {}
    if out_path.exists():
        table = json.loads(out_path.read_text(encoding="utf-8"))

    pending = [c for c in range(1, 115) if f"{c}:1" not in table]
    print(f"{114 - len(pending)}/114 chapters cached, {len(pending)} to fetch")

    for chapter in pending:
        for attempt in range(5):
            try:
                for verse in fetch(chapter):
                    table[verse["verse_key"]] = words_of(verse)
                break
            except Exception as error:  # noqa: BLE001 - any network failure is retryable
                print(f"  chapter {chapter} attempt {attempt + 1}: {error}", file=sys.stderr)
                time.sleep(2 * (attempt + 1))
        else:
            raise SystemExit(f"chapter {chapter} failed after 5 attempts")
        if chapter % 10 == 0:
            out_path.write_text(json.dumps(table, ensure_ascii=False), encoding="utf-8")
            print(f"  through chapter {chapter}")

    missing = [k for k, v in table.items() if not any(w["t"] for w in v)]
    out_path.write_text(json.dumps(table, ensure_ascii=False), encoding="utf-8")
    words = sum(len(v) for v in table.values())
    print(f"wrote {out_path}: {len(table)} ayahs, {words:,} words"
          + (f", {len(missing)} ayahs with no transliteration at all" if missing else ""))


if __name__ == "__main__":
    main()
