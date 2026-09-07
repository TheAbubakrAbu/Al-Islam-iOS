#!/usr/bin/env python3
"""Build Resources/Data/Hadith/HadeethEnc.json.xz from Tilawa's HadeethEnc dataset.

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

Node decodes the brotli files (Python ships no brotli); pass the Tilawa checkout.
"""
import json, lzma, re, subprocess, sys
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
    never spans a full stop."""
    if "\u2014" not in text:
        return text
    # Normalize the spaced variants (" — ", "— ", " —") to a bare dash between the two halves.
    text = re.sub(r"\s*\u2014\s*", "\u2014", text)
    out = []
    for sentence in re.split(r"(?<=[.!?])\s+", text):
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
    return " ".join(out)


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
OUT = ROOT / "Resources/Data/Hadith/HadeethEnc.json.xz"


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
    pack = {
        "version": 1,
        "source": "hadeethenc.com (the Hadith Encyclopedia), via Tilawa's build of 2026-09-05",
        "tree": tree,
        "entries": entries,
    }
    raw = json.dumps(pack, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    OUT.write_bytes(lzma.compress(raw, format=lzma.FORMAT_XZ, preset=9 | lzma.PRESET_EXTREME))
    print(f"{len(entries)} hadiths, {len(tree)} categories; {len(raw):,} bytes raw -> {OUT.stat().st_size:,} bytes xz")


if __name__ == "__main__":
    main()
