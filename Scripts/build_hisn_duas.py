#!/usr/bin/env python3
"""Build Resources/Data/Islam/HisnDuas.json.xz from Tilawa's generated Hisn al-Muslim tables.

Reads src/data/generated/duaDatabase.ts (268 entries, 132 categories, 14 collections; the islamic.app
Dhikr API import) and src/data/generated/duaAudio.ts (hisnmuslim.com recitation URLs) from a Tilawa
checkout and writes one xz JSON pack:

  {"version": 1, "source": {...},
   "categories": [{id, number, label, arabic, count}],
   "collections": [{id, label, arabic, subtitle, icon, tint, entryIds, categoryNumbers}],
   "entries": [{id, number, category, title, arabic, transliteration, translation, notes, benefits,
                repeat, reference, audio}]}

Usage: python3 Scripts/build_hisn_duas.py [/path/to/Tilawa]
"""
import json, lzma, os, re, sys

TILAWA = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Downloads/Islam/Tilawa")
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "Resources", "Data", "Islam", "HisnDuas.json.xz")


def block(src, name, kind="["):
    """The JSON array/object assigned to `export const NAME`, trailing commas removed."""
    close = "]" if kind == "[" else "}"
    head = re.search(r"export const " + re.escape(name) + r"\b", src).start()
    open_at = src.index(kind, src.index("=", head))
    # The generator closes every top-level table with the bracket at the start of a line.
    close_at = src.index("\n" + close + ";", open_at) + 1
    text = src[open_at:close_at + 1]
    text = re.sub(r",(\s*[\]}])", r"\1", text)
    return json.loads(text)


def strip(s):
    return re.sub(r"\s+", " ", (s or "")).strip()


def main():
    src = open(os.path.join(TILAWA, "src/data/generated/duaDatabase.ts"), encoding="utf-8").read()
    cats = block(src, "DUA_DATABASE_CATEGORIES")
    cols = block(src, "DUA_DATABASE_COLLECTIONS")
    ents = block(src, "DUA_DATABASE")
    audio_src = open(os.path.join(TILAWA, "src/data/generated/duaAudio.ts"), encoding="utf-8").read()
    audio = block(audio_src, "DUA_AUDIO_URLS", "{")

    root = {
        "version": 1,
        "source": {
            "name": "Hisn al-Muslim (Fortress of the Muslim) by Sa'id ibn Ali ibn Wahf al-Qahtani, via the "
                    "islamic.app Dhikr API; recitations by hisnmuslim.com; ported from the Tilawa app "
                    "(Jamil Hammoudeh) with permission",
            "url": "https://docs.islamic.app/docs/dhikr-api",
        },
        "categories": [{"id": c["id"], "number": c["number"], "label": c["label"], "arabic": c["arabicLabel"],
                        "count": c["count"]} for c in cats],
        "collections": [{"id": c["id"], "label": c["label"], "arabic": c["arabicLabel"], "subtitle": c["subtitle"],
                         "icon": c["iconKey"], "tint": c["tint"], "entryIds": c["entryIds"],
                         "categoryNumbers": c["categoryNumbers"]} for c in cols],
        "entries": [{"id": e["id"], "number": e["entryNumber"], "category": e["categoryId"], "title": e["title"],
                     "arabic": strip(e["arabic"]), "transliteration": strip(e["transliteration"].replace("\n", " ")),
                     "translation": strip(e["translation"]), "notes": strip(e["notes"]),
                     "benefits": strip(e["benefits"]), "repeat": e["repeat"], "reference": strip(e["reference"]),
                     "audio": audio.get(e["id"], "")} for e in ents],
    }
    raw = json.dumps(root, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    with open(OUT, "wb") as f:
        f.write(lzma.compress(raw, preset=9))
    print(f"{len(cats)} categories, {len(cols)} collections, {len(ents)} entries -> {OUT} ({os.path.getsize(OUT)} bytes)")


if __name__ == "__main__":
    main()
