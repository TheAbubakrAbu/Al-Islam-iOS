#!/usr/bin/env python3
"""Build Resources/Data/Quran/WordOfDay.json.xz - the Word of the Day corpus.

    ./Scripts/build_word_of_day.py [/path/to/Tilawa]

Tilawa (Jamil Hammoudeh, with permission) curates 150 pieces of Quranic vocabulary in
src/data/generated/wordOfDay.ts: the exact KFGQPC token of an anchor occurrence, its
transliteration and the English gloss of that occurrence (the same Quran.com word-by-word gloss the
reader's word-by-word mode uses). This script takes those three fields and the anchor, then derives
everything else from THIS app's Hafs text (Resources/JSONs-Deprecated/Quran.json): every ayah the
written form appears in, with the 0-based whitespace-token indices the reader tints, and the
occurrence count. Tokens are compared folded (harakat and annotation marks stripped, alif wasla and
the hamza carriers on their base letter, the dagger alif KEPT so genuinely different forms never
merge), Tilawa's own fold, and the counts are checked against Tilawa's so any drift between the two
texts is reported rather than shipped silently.

Pack layout (version 2): {"version": 2, "words": [{"id", "tr", "en", "s", "a", "p", "n",
"occ": [[surah, ayah, [token, ...]], ...]}]} - `p` is the anchor's 0-based token index, `n` the
count of the form across the Quran, `occ` every ayah in mushaf order. The written form itself is
NOT stored: it is the app's own token at the anchor (`s`:`a`, token `p`), read from the Quran
text at runtime, so the pack carries no copy of a Quranic word (version 1 did, as `ar`).
"""
import json, lzma, pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
OUT = ROOT / "Resources" / "Data" / "Quran" / "WordOfDay.json.xz"
TILAWA = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Tilawa"

_MARKS = re.compile("[ً-ٟۖ-ۭـ]")


def fold(token: str) -> str:
    return (_MARKS.sub("", token)
            .replace("ٱ", "ا")
            .replace("أ", "ا").replace("إ", "ا")
            .replace("ؤ", "و")
            .replace("ئ", "ي"))


def xz(body: bytes) -> bytes:
    dict_size = 1 << 16
    while dict_size < len(body) and dict_size < (1 << 26):
        dict_size <<= 1
    filters = [{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME, "dict_size": dict_size}]
    return lzma.compress(body, format=lzma.FORMAT_XZ, check=lzma.CHECK_CRC32, filters=filters)


def tilawa_words() -> list[dict]:
    """The generated TS array, evaluated by node (it is a plain object literal after the types go)."""
    source = TILAWA / "src" / "data" / "generated" / "wordOfDay.ts"
    if not source.exists():
        raise SystemExit(f"source not found: {source}")
    script = (
        "const fs=require('fs');let t=fs.readFileSync(process.argv[1],'utf8');"
        "t=t.replace(/export type[\\s\\S]*?\\n};\\n/,'').replace(/^export /mg,'')"
        ".replace(/const WORDS_OF_DAY: [^=]*=/,'const WORDS_OF_DAY =');"
        "eval(t+';process.stdout.write(JSON.stringify(WORDS_OF_DAY))');"
    )
    raw = subprocess.run(["node", "-e", script, str(source)], check=True, capture_output=True).stdout
    return json.loads(raw)


def main() -> None:
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    tokens = {}  # (surah, ayah) -> [token]
    order = []
    for surah in quran:
        for ayah in surah["ayahs"]:
            key = (int(surah["id"]), int(ayah["id"]))
            order.append(key)
            tokens[key] = ayah["textArabic"].split()
    folded = {key: [fold(t) for t in toks] for key, toks in tokens.items()}

    words = []
    drift = []
    seen_forms = set()
    for entry in tilawa_words():
        form = fold(entry["arabic"])
        s, a, p = int(entry["surahId"]), int(entry["ayahNumber"]), int(entry["wordPosition"]) - 1
        anchor = tokens.get((s, a))
        if anchor is None or p >= len(anchor):
            raise SystemExit(f"{entry['id']}: anchor {s}:{a} word {p + 1} is outside this app's text")
        if fold(anchor[p]) != form:
            raise SystemExit(f"{entry['id']}: anchor token differs: app {anchor[p]!r} vs Tilawa {entry['arabic']!r}")
        if form in seen_forms:
            raise SystemExit(f"{entry['id']}: duplicate form {form}")
        seen_forms.add(form)
        occ = []
        count = 0
        for key in order:
            hits = [i for i, t in enumerate(folded[key]) if t == form]
            if hits:
                occ.append([key[0], key[1], hits])
                count += len(hits)
        if count != int(entry["occurrences"]):
            drift.append(f"{entry['id']} {entry['arabic']}: app {count} vs Tilawa {entry['occurrences']}")
        words.append({
            "id": entry["id"],
            # No "ar": the form is the app's own token at (s, a, p), read at runtime.
            "tr": entry["transliteration"],
            "en": entry["meaningEn"],
            "s": s, "a": a, "p": p,
            "n": count,
            "occ": occ,
        })

    pack = {"version": 2, "source": "Tilawa wordOfDay.ts (curation, transliteration, gloss); the form and its occurrences from this app's Hafs text", "words": words}
    body = json.dumps(pack, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(xz(body))
    print(f"{len(words)} words, {sum(w['n'] for w in words)} occurrences, {len(body):,} B json -> {OUT.stat().st_size:,} B xz")
    if drift:
        print("count drift vs Tilawa (the app's text wins):")
        for line in drift:
            print("  " + line)


if __name__ == "__main__":
    main()
