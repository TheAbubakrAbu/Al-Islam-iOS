#!/usr/bin/env python3
"""Build Resources/Data/Hadith/HadeethEnc.henc from Tilawa's HadeethEnc dataset.

    ./Scripts/build_hadeethenc_pack.py [/path/to/Tilawa]

The Hadith Encyclopedia (hadeethenc.com, الموسوعة الحديثية): 2,328 narrations with a scholarly
explanation, a benefits list, the grading and the takhrij reference, in Arabic and English, under
452 categories. Tilawa (Jamil Hammoudeh) baked the site's API into api/data/hadeethenc/*.json.br;
this script lifts the Arabic and English layers into one app pack. hadeethenc.com permits reuse on
two conditions: no modification of the content and a clear credit (the screens carry the credit).
The hadith itself (title, intro, body) is never touched. The site's own commentary (the English
explanation and benefits) has its em dashes re-punctuated by `soften_dashes` below: a comma, colon
or parentheses in the dash's place, no word added or removed (the app never shows an em dash;
Abu's rule, 2026-09-07).

The pack (version 2, Tilawa Guide decision A, 2026-09-07) is a small container the app reads
on demand instead of one 14 MB JSON parsed at the door:

    "HENC" u16 version=2 u16 entriesPerBlock u32 headerXZ u32 headerRaw u32 blocks u32 entries u32 tree
    block table: blocks x (u32 firstEntry, u32 offset, u32 compressed, u32 raw); offsets from the payload start
    header (xz): two string tables, the topic tree then the light entries (id, topics, English title,
                 intro, grade, attribution): everything the door and the lists show
    payload: one xz string table per block of `entriesPerBlock` full narrations, in id order

A string table is `u32 records`, each `u32 fields` then fields of `u32 length` + UTF-8. No JSON in
the app's path; `HadeethEncStore` (iPhone/Hadith/HadeethEncView.swift) is the reader, `read_pack`
below the Python twin (Scripts/verify_tilawa_packs.py uses it).

Node decodes the brotli files (Python ships no brotli); pass the Tilawa checkout.
"""
import json, lzma, re, struct, subprocess, sys
from pathlib import Path

# MARK: - Em dashes in the commentary

# A dash that opens a subordinate clause reads as a comma; one that introduces an explanation, an
# independent clause or a quotation reads as a colon; a pair around an aside becomes parentheses.
_CONNECTORS = (
    "except", "but ", "for ", "whether", "even ", "and ", "or ", "nor ", "which", "who ", "whom", "whose",
    "so ", "because", "as ", "though", "although", "not ", "i.e.", "that is", "such as", "including",
    "meaning", "namely", "either", "unless", "since", "while", "if ", "without", "thus", "hence",
    "otherwise", "rather", "no matter", "given", "provided", "especially", "particularly", "e.g.",
    "like ", "be it", "referring", "subject to", "out of", "in ", "by ", "to ", "of ", "from ", "at ",
    "on ", "with ", "after", "before", "when", "where", "despite", "regardless", "unlike", "along with",
    "apart from", "other than", "based on", "according", "due to", "thereby", "therefore", "then ",
    "yet ", "still ", "also ", "too ", "as well", "whereas", "until", "till ", "once ", "lest", "both ",
    "neither", "each ", "every ", "among them", "an area", "a reflection", "a general", "a sect",
    "a Yemeni", "a barrier", "a famous", "a small", "a part", "something", "protection", "footwear",
    "distance", "the one", "the part", "the joint", "the two", "the number", "the Jews", "the prayer",
    "the Qur", "the Veil", "the pleasures", "one of", "his ", "her ",
    "their ", "all ", "some ", "three", "sixty", "one hundred", "escorting", "asking", "doing",
    "educating", "praying", "lowering", "abandoning", "violating", "indicating", "taking", "seeking",
    "drinking", "bowing", "benefiting", "attaining", "that is", "everlasting", "strong", "punish",
)
# An independent clause after the dash reads as a colon ("Then he shot him: the arrow struck").
_COLON_STARTS = ("he ", "she ", "it ", "its ", "they ", "we ", "you ", "this ", "these ", "those ", "there ", "that ", "what ", "throw")
# A parenthetical that directly follows one of these takes no comma after it ("because (...) it firms up").
_NO_COMMA_BEFORE_PAREN = {
    "because", "that", "if", "when", "while", "since", "although", "though", "unless", "and", "or", "but",
    "so", "as", "whether", "which", "who", "where", "yet", "then", "for", "of", "in", "to", "by", "with",
    "from", "on", "at", "is", "are", "was", "were", "be", "the", "a", "an",
}
# A comma after a closing parenthesis only where a new clause clearly starts (a subject, a
# contrast, a participle); "(...) is better", "(...) and when", "(...) settles it" take none.
_COMMA_AFTER_PAREN = {
    "they", "he", "she", "it", "we", "you", "i", "this", "these", "those", "there", "then", "so", "yet",
    "thus", "hence", "namely", "not", "no", "his", "her", "their", "its", "our", "my", "your", "whoever",
    "whatever",
}


def _first_word(text: str) -> str:
    match = re.match(r"[A-Za-z'\u2018\u2019]+", text)
    return match.group(0).lower() if match else ""


_SENTENCE_OPENERS = ("And ", "But ", "So ", "Then ", "Thus ", "Hence ", "Or ", "Yet ", "Rather ")


def _join_single(before: str, after: str) -> str:
    """One dash: `before—after`."""
    stripped = after.lstrip()
    lowered = stripped.lower()
    if before.rstrip().endswith((":", ",", ";", "(", "{", "[")):
        return before.rstrip() + " " + stripped
    if stripped.startswith(("(", "[")):
        return before.rstrip() + " " + stripped
    if stripped.startswith(_SENTENCE_OPENERS):
        head = before.rstrip()
        return (head if head.endswith((".", "!", "?")) else head + ".") + " " + stripped
    if stripped[:1].isupper() or stripped[:1] in "\"'\u201c\u2018{[(0123456789":
        return before.rstrip() + ": " + stripped
    if lowered.startswith(_CONNECTORS):
        return before.rstrip() + ", " + stripped
    if lowered.startswith(_COLON_STARTS):
        return before.rstrip() + ": " + stripped
    return before.rstrip() + ", " + stripped


def soften_dashes(text: str) -> str:
    """Re-punctuates every em dash in `text` (see the module doc). Sentence by sentence, so a pair
    never spans a full stop. The split captures its separators and the rejoin puts them back exactly,
    so a paragraph break between two sentences survives: rejoining on a single space used to flatten
    every blank line in any text that happened to contain a dash."""
    if "\u2014" not in text:
        return text
    # Normalize the spaced variants (" — ", "— ", " —") to a bare dash between the two
    # halves. Horizontal whitespace only: a line break beside a dash is structure, not spacing.
    text = re.sub(r"[^\S\n]*\u2014[^\S\n]*", "\u2014", text)
    out = []
    for index, sentence in enumerate(re.split(r"((?<=[.!?])\s+)", text)):
        if index % 2 == 1:
            out.append(sentence)   # the whitespace the split captured, put back as it was
            continue
        parts = sentence.split("\u2014")
        if len(parts) == 1:
            out.append(sentence)
            continue
        result = parts[0]
        i = 1
        while i < len(parts):
            # A pair inside the sentence (something follows the closing dash) is an aside.
            if i + 1 < len(parts) and parts[i + 1].strip(" .,;:!?\"\u201d'\u2019)]}") and parts[i].strip():
                inner = parts[i].strip()
                tail = parts[i + 1]
                if result.rstrip().endswith(","):
                    result = result.rstrip()[:-1]
                lead = "" if result.endswith((" ", "(", "[", "{")) else " "
                if result.rstrip().endswith(")"):
                    # "Khadijah (may Allah be pleased with her) (conveyed by Jibril)" reads as a
                    # double aside: the second becomes a comma pair instead.
                    if tail[:1] in ".,;:!?":
                        result = result.rstrip() + ", " + inner + tail
                    else:
                        result = result.rstrip() + ", " + inner + ", " + tail.lstrip()
                    i += 2
                    continue
                if tail[:1] in ".,;:!?":
                    result = result + lead + "(" + inner + ")" + tail
                else:
                    opener = re.search(r"([A-Za-z]+)\W*$", result)
                    first = _first_word(tail)
                    wants_comma = first in _COMMA_AFTER_PAREN or first.endswith("ing")
                    if opener and opener.group(1).lower() in _NO_COMMA_BEFORE_PAREN:
                        wants_comma = False
                    joiner = ", " if wants_comma else " "
                    result = result + lead + "(" + inner + ")" + joiner + tail.lstrip()
                i += 2
            else:
                after = parts[i]
                if not after.strip(" .,;:!?\"\u201d'\u2019)]}"):
                    # A trailing dash before the sentence's end punctuation: just drop it.
                    result = result.rstrip() + after
                else:
                    result = _join_single(result, after)
                i += 1
        out.append(result)
    return "".join(out)


# Hand-picked readings for the few sentences the rules above punctuate awkwardly (before -> after,
# applied on the raw text ahead of the rules; each must still match the source).
_OVERRIDES = {
    "number of washings odd\u2014three, five, or seven": "number of washings odd: three, five, or seven",
    "Bismill\u0101h\u2014it will be blessed for you": "Bismill\u0101h, it will be blessed for you",
    "Clarifying some of the tasks of angels\u2014among them are those": "Clarifying some of the tasks of angels: among them are those",
    "Affirmation of the miracles of the pious\u2014among them: ": "Affirmation of the miracles of the pious, among them ",
    "First, a countable measure is mentioned\u2014the number of His creations": "First, a countable measure is mentioned: the number of His creations",
    "Then he shot him\u2014the arrow struck": "Then he shot him: the arrow struck",
    "The one whose parents\u2014one of them or both\u2014reached": "The one whose parents (one of them or both) reached",
    "These three things\u2014remembering Allah, performing ablution, and praying\u2014drive": "These three things (remembering Allah, performing ablution, and praying) drive",
    "are raised to Him\u2014the deeds done at night": "are raised to Him: the deeds done at night",
    "with full certainty in his heart\u2014whoever has these qualities": "with full certainty in his heart: whoever has these qualities",
    "They will be called first to account\u2014thus, we are": "They will be called first to account: thus, we are",
    "and its Prophet?\u2014in attribution": "and its Prophet? In attribution",
    "speaking with his mother - the infant sat up": "speaking with his mother: the infant sat up",
    "between the members of his family - the result of this": "between the members of his family: the result of this",
    "or half of it - a Mudd is enough": "or half of it: a Mudd is enough",
}


_SPACED_DASH = re.compile(r"(?<=[A-Za-z\u2019'\)\]\u0101\u016b\u012b]) [-\u2013] (?=[A-Za-z(\u201c\"\u2018\u0101])")


def soften(text: str) -> str:
    for old, new in _OVERRIDES.items():
        text = text.replace(old, new)
    # Quran quotes sit in {braces}; everything between a brace pair is left exactly as it is.
    pieces = re.split(r"(\{[^{}]*\})", text)
    for index, piece in enumerate(pieces):
        if piece.startswith("{"):
            continue
        piece = _SPACED_DASH.sub("\u2014", piece)
        pieces[index] = soften_dashes(piece)
    return "".join(pieces)

ROOT = Path(__file__).resolve().parent.parent
TILAWA = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Tilawa"
SRC = TILAWA / "api/data/hadeethenc"
OUT = ROOT / "Resources/Data/Hadith/HadeethEnc.henc"
MAGIC = b"HENC"
VERSION = 2
ENTRIES_PER_BLOCK = 128
UNIT = "\x1f"   # joins a benefits list inside one field
HEADER = "<4sHHIIIII"
BLOCK_ROW = "<IIII"

# The field order of a full narration inside a block; `HadeethEncStore.parseBlock` reads it by index.
FULL_FIELDS = (
    ("id",), ("cats",),
    ("ar", "title"), ("ar", "intro"), ("ar", "body"), ("ar", "explanation"), ("ar", "benefits"),
    ("ar", "attribution"), ("ar", "grade"), ("ar", "reference"),
    ("en", "title"), ("en", "intro"), ("en", "body"), ("en", "explanation"), ("en", "benefits"),
    ("en", "attribution"), ("en", "grade"),
)


def xz(raw: bytes) -> bytes:
    return lzma.compress(raw, format=lzma.FORMAT_XZ, preset=9 | lzma.PRESET_EXTREME)


def string_table(records) -> bytes:
    out = bytearray(struct.pack("<I", len(records)))
    for record in records:
        out += struct.pack("<I", len(record))
        for field in record:
            data = str(field).encode("utf-8")
            out += struct.pack("<I", len(data)) + data
    return bytes(out)


def full_record(entry: dict) -> list[str]:
    record = []
    for path in FULL_FIELDS:
        if path == ("id",):
            record.append(entry["id"])
        elif path == ("cats",):
            record.append(",".join(entry["cats"]))
        else:
            value = entry[path[0]].get(path[1], "")
            if path[1] == "benefits":
                assert all(UNIT not in b for b in value), entry["id"]
                value = UNIT.join(value)
            record.append(value)
    return record


def write_pack(tree: list[dict], entries: list[dict], out: Path = OUT, per_block: int = ENTRIES_PER_BLOCK) -> dict:
    tree_rows = [[n["id"], n.get("parent") or "", n["en"], n["ar"], n["direct"], n["total"]] for n in tree]
    light_rows = [[e["id"], ",".join(e["cats"]), e["en"]["title"], e["en"]["intro"], e["en"]["grade"], e["en"]["attribution"]]
                  for e in entries]
    header_raw = string_table(tree_rows) + string_table(light_rows)
    header_xz = xz(header_raw)
    table, payload = [], bytearray()
    for start in range(0, len(entries), per_block):
        raw = string_table([full_record(e) for e in entries[start:start + per_block]])
        compressed = xz(raw)
        table.append((start, len(payload), len(compressed), len(raw)))
        payload += compressed
    head = struct.pack(HEADER, MAGIC, VERSION, per_block, len(header_xz), len(header_raw), len(table), len(entries), len(tree))
    out.write_bytes(head + b"".join(struct.pack(BLOCK_ROW, *row) for row in table) + header_xz + bytes(payload))
    return {"blocks": len(table), "header_raw": len(header_raw), "header_xz": len(header_xz),
            "payload": len(payload), "bytes": out.stat().st_size}


def read_table(raw: bytes, pos: int) -> tuple[list[list[str]], int]:
    (count,) = struct.unpack_from("<I", raw, pos)
    pos += 4
    records = []
    for _ in range(count):
        (fields,) = struct.unpack_from("<I", raw, pos)
        pos += 4
        record = []
        for _ in range(fields):
            (length,) = struct.unpack_from("<I", raw, pos)
            pos += 4
            record.append(raw[pos:pos + length].decode("utf-8"))
            pos += length
        records.append(record)
    return records, pos


def read_pack(path: Path = OUT) -> dict:
    """The pack as {"tree": [...], "entries": [light rows], "full": [full entries]} through the same
    layout the app reads, for the verifier and for the self-check below."""
    data = path.read_bytes()
    magic, version, per_block, header_xz, header_raw, blocks, entry_count, tree_count = struct.unpack_from(HEADER, data, 0)
    assert magic == MAGIC and version == VERSION, (magic, version)
    pos = struct.calcsize(HEADER)
    table = [struct.unpack_from(BLOCK_ROW, data, pos + i * struct.calcsize(BLOCK_ROW)) for i in range(blocks)]
    pos += blocks * struct.calcsize(BLOCK_ROW)
    header = lzma.decompress(data[pos:pos + header_xz])
    assert len(header) == header_raw
    payload_start = pos + header_xz
    tree, cursor = read_table(header, 0)
    light, cursor = read_table(header, cursor)
    assert len(tree) == tree_count and len(light) == entry_count, (len(tree), len(light))
    full = []
    for first, offset, compressed, raw_len in table:
        raw = lzma.decompress(data[payload_start + offset:payload_start + offset + compressed])
        assert len(raw) == raw_len
        rows, _ = read_table(raw, 0)
        assert len(full) == first
        for row in rows:
            entry = {"id": row[0], "cats": row[1].split(",") if row[1] else [], "ar": {}, "en": {}}
            for path, value in zip(FULL_FIELDS[2:], row[2:]):
                entry[path[0]][path[1]] = value.split(UNIT) if path[1] == "benefits" and value else ([] if path[1] == "benefits" else value)
            full.append(entry)
    return {"version": version, "entriesPerBlock": per_block, "tree": [
        {"id": r[0], "parent": r[1] or None, "en": r[2], "ar": r[3], "direct": int(r[4]), "total": int(r[5])} for r in tree],
        "entries": light, "full": full}


def decode(name: str):
    script = ("const z=require('zlib'),f=require('fs');"
              "process.stdout.write(z.brotliDecompressSync(f.readFileSync(process.argv[1])));")
    raw = subprocess.run(["node", "-e", script, str(SRC / f"{name}.json.br")], check=True, capture_output=True).stdout
    return json.loads(raw)


def main():
    catalog = decode("catalog")
    core = decode("core")
    english = decode("tr-en")

    tree = []
    for node in catalog["tree"]:
        tree.append({
            "id": node["id"],
            "parent": node.get("parent"),
            "en": node["labels"].get("en", ""),
            "ar": node["labels"].get("ar", ""),
            "direct": node.get("direct", 0),
            "total": node.get("total", 0),
        })
    categories = {row["id"]: row.get("cats", []) for row in catalog["index"]}

    entries = []
    for hadith_id, ar in core.items():
        en = english.get(hadith_id)
        if not en:
            continue
        entries.append({
            "id": hadith_id,
            "cats": categories.get(hadith_id, []),
            "ar": {
                "title": ar.get("title", ""),
                "intro": ar.get("intro", ""),
                "body": ar.get("body", ""),
                "explanation": ar.get("explanation", ""),
                "benefits": ar.get("benefits", []),
                "attribution": ar.get("attribution", ""),
                "grade": ar.get("grade", ""),
                "reference": ar.get("reference", ""),
            },
            "en": {
                "title": en.get("title", ""),
                "intro": en.get("intro", ""),
                "body": en.get("body", ""),
                "explanation": soften(en.get("explanation", "")),
                "benefits": [soften(b) for b in en.get("benefits", [])],
                "attribution": en.get("attribution", ""),
                "grade": en.get("grade", ""),
            },
        })
    entries.sort(key=lambda e: int(e["id"]))
    # Source: hadeethenc.com (the Hadith Encyclopedia), via Tilawa's build of 2026-09-05.
    sizes = write_pack(tree, entries)
    back = read_pack()
    assert [e["id"] for e in back["full"]] == [e["id"] for e in entries]
    assert all(a["en"]["body"] == b["en"]["body"] and a["ar"]["body"] == b["ar"]["body"] and a["en"]["benefits"] == b["en"]["benefits"]
               for a, b in zip(back["full"], entries))
    assert [n["id"] for n in back["tree"]] == [n["id"] for n in tree]
    print(f"{len(entries)} hadiths, {len(tree)} categories; {sizes['blocks']} blocks of {ENTRIES_PER_BLOCK}, "
          f"header {sizes['header_raw']:,} -> {sizes['header_xz']:,} bytes, payload {sizes['payload']:,} bytes, "
          f"{sizes['bytes']:,} bytes at {OUT}")


if __name__ == "__main__":
    main()
