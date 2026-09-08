#!/usr/bin/env python3
"""Build Resources/Data/Islam/NamesDetails.json.xz: the authored depth behind the 99 Names.

    ./Scripts/build_names_details.py [/path/to/Tilawa]

SOURCE: Tilawa's src/data/allahNameDetails.ts (Jamil Hammoudeh, with permission), keyed by the
same 1..99 numbering as this app's namesofallah.qpk (Tilawa's list IS this app's list). Per name:
a browsing theme (nine groups), the Arabic root, a two-or-three-sentence explanation, and one line
on what believing the name asks of a person ("living").

THE QURAN OCCURRENCES are derived here from THIS app's own data, never copied: every "(s:a)"
reference in the name's `found` field (namesofallah.qpk, mirrored in NamesOfAllahFallback.swift)
is opened in the app's Hafs text and the name's word is located by folded comparison (marks
stripped, wasla and hamza carriers on their base letter, dagger alif dropped), allowing the
definite article and a one- or two-letter clitic prefix. A verse whose word could not be matched
is still listed, with no tint: the verse carries the attribute in another form.

Pack: {"version": 1, "themes": [{"id", "label"}], "names": {"<number>": {"theme", "root",
"explanation", "living", "verses": [[surah, ayah, tokenStart, tokenCount], ...]}}}
(tokenStart -1 when unmatched; tokens are 0-based whitespace indices of the raw Hafs text).
"""
from __future__ import annotations

import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from tilawa_ts import eval_consts, load_softener, xz_compress  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
FALLBACK = ROOT / "iPhone" / "Islam" / "NamesOfAllahFallback.swift"
OUT = ROOT / "Resources" / "Data" / "Islam" / "NamesDetails.json.xz"
TILAWA = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Tilawa"

THEME_LABELS = {
    "mercy": "Mercy", "majesty": "Majesty", "knowledge": "Knowledge", "provision": "Provision",
    "creation": "Creation", "justice": "Justice", "forgiveness": "Forgiveness",
    "guidance": "Guidance", "eternity": "Eternity",
}

_MARKS = re.compile("[ً-ٰٟۖ-ۭـۥۦ]")
_CLITICS = ("", "و", "ف", "ب", "ل", "ك", "ول", "فل", "وب", "فب", "ال", "لل")


def fold(token: str) -> str:
    # The dagger alif becomes a written alif: the mushaf writes خَٰلِق and مَٰلِك with the small
    # alif where the name's own spelling has a full one, and both must fold the same way.
    return (_MARKS.sub("", token.replace("\u0670", "ا"))
            .replace("ٱ", "ا").replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
            .replace("ؤ", "و").replace("ئ", "ي"))


def app_names() -> list[dict]:
    text = FALLBACK.read_text(encoding="utf-8")
    start = text.index('#"""') + 4
    end = text.index('"""#', start)
    return json.loads(text[start:end])


def name_forms(name: str) -> list[list[str]]:
    """The folded word sequences a name can appear as: the name, and the name without its article."""
    words = [fold(w) for w in name.split()]
    forms = [words]
    if words and words[0].startswith("ال") and len(words[0]) > 3:
        forms.append([words[0][2:]] + words[1:])
    # ذُو الجَلَال is ذِي الجَلَال in the genitive (55:78).
    if words and words[0] == "ذو":
        forms.append(["ذي"] + words[1:])
    return forms


def locate(tokens: list[str], forms: list[list[str]]) -> tuple[int, int] | None:
    folded = [fold(t) for t in tokens]
    for form in forms:
        n = len(form)
        for i in range(len(folded) - n + 1):
            head = folded[i]
            # A one-word name may also stand in the accusative with the alif of its tanween
            # (عَزِيزًا, رَحِيمٗا), which survives the fold as a trailing alif.
            heads = [form[0]] + ([form[0] + "ا"] if n == 1 and not form[0].startswith("ال") else [])
            if not any(head == prefix + h for prefix in _CLITICS for h in heads):
                continue
            if all(folded[i + k] == form[k] for k in range(1, n)):
                return i, n
    return None


def main() -> None:
    soften = load_softener()
    source = TILAWA / "src" / "data" / "allahNameDetails.ts"
    if not source.exists():
        raise SystemExit(f"source not found: {source}")
    data = eval_consts(source, ["ALLAH_NAME_THEMES", "ALLAH_NAME_DETAILS"])
    themes = data["ALLAH_NAME_THEMES"]
    details = data["ALLAH_NAME_DETAILS"]

    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    tokens = {(int(s["id"]), int(a["id"])): a["textArabic"].split() for s in quran for a in s["ayahs"]}

    names = {}
    problems = []
    verses_total = matched = 0
    for record in app_names():
        number = int(record["number"])
        detail = details.get(str(number))
        if detail is None:
            problems.append(f"name {number}: no Tilawa detail")
            continue
        if detail["theme"] not in THEME_LABELS:
            problems.append(f"name {number}: unknown theme {detail['theme']}")
        refs = []
        for m in re.finditer(r"\((\d+)\s*:\s*(\d+)\)", record.get("found", "")):
            ref = (int(m.group(1)), int(m.group(2)))
            if ref not in tokens:
                problems.append(f"name {number}: no ayah {ref[0]}:{ref[1]}")
                continue
            if ref not in refs:
                refs.append(ref)
        forms = name_forms(record["name"])
        verses = []
        for s, a in refs:
            verses_total += 1
            hit = locate(tokens[(s, a)], forms)
            if hit:
                matched += 1
                verses.append([s, a, hit[0], hit[1]])
            else:
                verses.append([s, a, -1, 0])
        names[str(number)] = {
            "theme": detail["theme"],
            "root": detail.get("root", ""),
            "explanation": soften(detail.get("explanation", "")),
            "living": soften(detail.get("living", "")),
            "verses": verses,
        }
        for key in ("explanation", "living"):
            if "\u2014" in names[str(number)][key] or " - " in names[str(number)][key]:
                problems.append(f"name {number}: dash left in {key}")

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:40]:
            print("  " + line, file=sys.stderr)
        raise SystemExit(1)

    pack = {
        "version": 1,
        "themes": [{"id": t, "label": THEME_LABELS[t]} for t in themes],
        "names": names,
    }
    body = json.dumps(pack, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    blob = xz_compress(body)
    OUT.write_bytes(blob)
    unmatched = [(n, v) for n, d in names.items() for v in d["verses"] if v[2] < 0]
    print(f"{len(names)} names, {verses_total} verses, {matched} words located, {len(unmatched)} unmatched")
    for n, v in unmatched[:60]:
        print(f"  {n}: {v[0]}:{v[1]}")
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} xz")


if __name__ == "__main__":
    main()
