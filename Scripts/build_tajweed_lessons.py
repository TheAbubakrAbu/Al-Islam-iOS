#!/usr/bin/env python3
"""Build Resources/Data/Quran/TajweedLessons.json.xz - the structured tajweed
course behind Islam tab -> Tajweed -> Structured Lessons.

SOURCE
------
Tilawa's src/data/tajweed-course/*.ts: a hand-authored curriculum by Jamil
Hammoudeh (four stages -> ten chapters -> lessons, each with a definition card,
a trigger/action/hold rule card, body paragraphs, key points, letter sets, a
comparison table, common mistakes, curated example ayahs, Qaida-Noorania-style
drills and a self-check quiz). Ported with his permission; see CreditsView.

The chapter files are data plus TypeScript dressing. Rather than hand-copying
the prose (which would drift from Tilawa), this script strips the types,
evaluates the chapter literals with node in the order tajweedLessons.ts lists
them, and re-emits them as JSON, so a Tilawa content fix is a rebuild away.
Tilawa-authored prose has its spaced hyphens and em dashes re-punctuated (the
app's house rule); teaching Arabic is carried as written, ayah text never is
(see below).

VALIDATION (build fails, writing nothing, if violated)
------------------------------------------------------
* every example's (surahId, ayahNumber) exists in this app's Quran, and the
  words the example points at are found in that ayah;
* every lesson has an id, English title, and at least one body paragraph;
* lesson ids are unique across chapters; every `related` id resolves;
* every quiz answer indexes its choices.

QURAN WORDS ARE SPANS, NOT TEXT: the pack carries no copy of an ayah or of a
phrase from one; it stores where the words sit in this app's own Hafs text
(`quran_spans.py`: a 0-based inclusive range of the ayah's whitespace tokens)
and the app reads them out of the ayah at render time, so they can never drift
from the mushaf text.

* Examples (version 3): the source gives each example the words to listen at
  as a string (`word`); the pack stores `wordSpan` located in the cited ayah
  (a piece cut inside a word, like the لنَّاسِ of ٱلنَّاسِ, spans the whole
  token).
* Drills, rule-card fragments and quiz lines (version 4): `drills[].text`,
  `ruleCard.fragments[].text` and `quiz[].arabic` are Tilawa's teaching Arabic
  with no citation, and some of them are ayahs. Every one is folded
  (`quran_spans.fold`) and searched across all 6,236 ayahs for a contiguous
  run of its tokens (`quran_reference`). The string is replaced by
  `"ayah": [surah, ayahNumber, first, last]` when the match is unambiguous:
  the words are a whole ayah (a whole ayah that recurs, like a basmalah, takes
  its first place in mushaf order), or a run of two or more tokens found in
  exactly one ayah. Everything else stays text: a single token (too ambiguous,
  unless it is a one-word ayah found exactly once, like وَٱلۡفَجۡرِ 89:1), a run
  found in several ayahs, a list of snippets joined by / -> + = ..., whole
  ayahs one after another or an ayah plus other words (the isti'adhah then the
  basmalah), and the letters, syllables and invented words that are not Quran.
  A token that folds to nothing (the standalone sakta sign a drill puts between
  مَنۡ and رَاقٖ, the ۞ that opens a rub') does not take part in the match.
  `caption`, `translit`, the quiz `prompt`, `choices`, `answer` and `explain`
  are kept beside the reference. Scripts/verify_tajweed_lessons.py re-runs the
  search over every string still shipped as text, so a rebuild cannot bring a
  copy back.

OUTPUT: xz over {"version": 4, "stages": [...], "ruleCounts": {...},
        "chapters": [...]} in the source's own order (narrationUrl dropped:
        no recordings exist).

RUN:  python3 Scripts/build_tajweed_lessons.py [tilawa-root]
"""

from __future__ import annotations

import collections
import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from quran_spans import fold, locate_slice  # noqa: E402
from tilawa_ts import eval_modules, load_softener, xz_compress  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
OUT = ROOT / "Resources" / "Data" / "Quran" / "TajweedLessons.json.xz"
DEFAULT_TILAWA = ROOT.parent / "Tilawa"

PROSE_KEYS = ("summary", "focus", "caption", "literal", "technical", "trigger", "action", "hold",
              "gloss", "note", "wrong", "right", "why", "prompt", "explain", "label", "title",
              "subtitle", "blurbEn")
PROSE_LIST_KEYS = ("body", "keyPoints", "choices")

# The Arabic fields that may hold Quran words with no citation: (row list, field), see quran_reference.
ARABIC_FIELDS = {"drills": "text", "fragments": "text", "quiz": "arabic"}

# A folded token with no Arabic letter in it (/ -> + = ...) separates snippets; such a string is a
# list of pieces, not one run of Quran words.
_LETTER = re.compile("[ء-يٱ]")

# How quran_reference reads a string that stays text.
TEXT_REASONS = {
    "single": "a single token (not a one-word ayah found once)",
    "ambiguous": "a run found in several ayahs",
    "pieces": "snippets joined by / -> + = ...",
    "joined": "whole ayahs one after another, or an ayah plus other words",
    "none": "not Quran (letters, syllables, invented words, the isti'adhah)",
}


def ayah_counts() -> dict[int, int]:
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    return {s["id"]: len(s["ayahs"]) for s in quran}


def ayah_tokens() -> dict[tuple[int, int], list[str]]:
    """This app's Hafs text, one whitespace token list per ayah, in mushaf order."""
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    return {(s["id"], a["id"]): a["textArabic"].split() for s in quran for a in s["ayahs"]}


def quran_index(tokens: dict[tuple[int, int], list[str]]):
    """The whole Quran folded for the run search: per ayah, its folded tokens with the original index
    of each (a token that folds to nothing, the ۞ of a rub', is skipped, so a run may start after
    it), and for every folded token the ayah positions it occurs at, in mushaf order."""
    ayahs: dict[tuple[int, int], tuple[list[str], list[int]]] = {}
    starts: dict[str, list[tuple[tuple[int, int], int]]] = collections.defaultdict(list)
    for key, toks in tokens.items():
        folded, positions = [], []
        for index, token in enumerate(toks):
            word = fold(token)
            if word:
                folded.append(word)
                positions.append(index)
        ayahs[key] = (folded, positions)
        for at, word in enumerate(folded):
            starts[word].append((key, at))
    return ayahs, starts


def quran_reference(text: str, index) -> tuple[list[int] | None, str, int]:
    """Where `text` sits in the Quran when that is unambiguous.

    Returns (reference, kind, places): the reference is [surah, ayahNumber, first, last], the
    0-based inclusive token span in this app's text, with kind "whole" (the words are a whole ayah;
    `places` counts the ayahs they are the whole of, the first in mushaf order taken) or "slice"
    (a run of two or more tokens found in exactly one ayah). When the text stays text the reference
    is None and kind is a TEXT_REASONS key ("single", "ambiguous", "pieces", "joined", "none").
    """
    words = [word for word in (fold(token) for token in text.split()) if word]
    if not words:
        return None, "none", 0
    if not all(_LETTER.search(word) for word in words):
        return None, "pieces", 0
    ayahs, starts = index
    n = len(words)
    whole: list[list[int]] = []
    slices: list[list[int]] = []
    for key, at in starts.get(words[0], ()):
        folded, positions = ayahs[key]
        if folded[at:at + n] == words:
            hit = [key[0], key[1], positions[at], positions[at + n - 1]]
            (whole if n == len(folded) else slices).append(hit)
    if n == 1:
        if len(whole) == 1:
            return whole[0], "whole", 1
        return None, "single", len(whole) or len({(h[0], h[1]) for h in slices})
    if whole:
        return whole[0], "whole", len(whole)
    in_ayahs = {(h[0], h[1]) for h in slices}
    if len(in_ayahs) == 1:
        return slices[0], "slice", 1
    if in_ayahs:
        return None, "ambiguous", len(in_ayahs)
    # No run at all: is a whole ayah inside the string (ayahs read one after another, or an ayah
    # after words that are not Quran)?
    for at, word in enumerate(words):
        for key, j in starts.get(word, ()):
            if j:
                continue
            folded = ayahs[key][0]
            if words[at:at + len(folded)] == folded:
                return None, "joined", 1
    return None, "none", 0


def reference_arabic(row: dict, field: str, index, tally: collections.Counter) -> str | None:
    """Replace `row[field]` by `row["ayah"]` when the text is one unambiguous run of Quran words
    (`quran_reference`), else leave it as text. Returns a note when a whole ayah recurs."""
    text = row.get(field)
    if not isinstance(text, str):
        return None
    reference, kind, places = quran_reference(text, index)
    tally[kind] += 1
    if reference is None:
        return None
    del row[field]
    row["ayah"] = reference
    if kind == "whole" and places > 1:
        return f"{text!r} is a whole ayah in {places} places; the first, {reference[0]}:{reference[1]}, taken"
    return None


def chapter_files(tilawa: pathlib.Path) -> tuple[list[pathlib.Path], list[str]]:
    """The chapter modules in the order tajweedLessons.ts assembles them."""
    assembly = (tilawa / "src" / "data" / "tajweedLessons.ts").read_text(encoding="utf-8")
    literal = assembly[assembly.index("export const TAJWEED_CHAPTERS"):]
    literal = literal[:literal.index("];")]
    names = re.findall(r"^\s+(\w+Chapter),\s*$", literal, re.M)
    course = tilawa / "src" / "data" / "tajweed-course"
    by_name = {}
    for path in sorted(course.glob("*.ts")):
        text = path.read_text(encoding="utf-8")
        m = re.search(r"^export const (\w+Chapter):", text, re.M)
        if m:
            by_name[m.group(1)] = path
    missing = [n for n in names if n not in by_name]
    if missing:
        raise SystemExit(f"chapter modules not found: {missing}")
    return [by_name[n] for n in names], names


def soften_tree(node, soften):
    """Re-punctuate every Tilawa-authored prose field, leaving Arabic and ayah text alone."""
    if isinstance(node, dict):
        out = {}
        for key, value in node.items():
            if key in PROSE_KEYS and isinstance(value, str):
                out[key] = soften(value)
            elif key in PROSE_LIST_KEYS and isinstance(value, list):
                out[key] = [soften(v) if isinstance(v, str) else v for v in value]
            elif key == "rows" and isinstance(value, list):
                out[key] = [[soften(c) if isinstance(c, str) else c for c in row] for row in value]
            elif key == "columns" and isinstance(value, list):
                out[key] = [soften(c) if isinstance(c, str) else c for c in value]
            else:
                out[key] = soften_tree(value, soften)
        return out
    if isinstance(node, list):
        return [soften_tree(v, soften) for v in node]
    return node


def dashes_left(node, path="") -> list[str]:
    found = []
    if isinstance(node, dict):
        for key, value in node.items():
            found += dashes_left(value, f"{path}.{key}")
    elif isinstance(node, list):
        for i, value in enumerate(node):
            found += dashes_left(value, f"{path}[{i}]")
    elif isinstance(node, str) and not re.search(r"[؀-ۿ]", node):
        if ", " in node or re.search(r"[A-Za-z)] - [A-Za-z(]", node):
            found.append(f"{path}: {node[:70]}")
    return found


def main() -> None:
    tilawa = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_TILAWA
    if not (tilawa / "src" / "data" / "tajweedLessons.ts").exists():
        raise SystemExit(f"source not found under {tilawa}")

    soften = load_softener()
    counts = ayah_counts()
    tokens = ayah_tokens()
    index = quran_index(tokens)
    files, names = chapter_files(tilawa)
    assembly = tilawa / "src" / "data" / "tajweedLessons.ts"
    rule_counts_file = tilawa / "src" / "data" / "tajweed-course" / "ruleCounts.ts"
    modules = files + [rule_counts_file, assembly]
    evaluated = eval_modules(modules, names + ["STAGE_ORDER", "STAGE_META", "RULE_CORPUS_COUNTS"])
    chapters = [evaluated[n] for n in names]
    stage_order = evaluated["STAGE_ORDER"]
    stage_meta = evaluated["STAGE_META"]
    rule_counts = evaluated["RULE_CORPUS_COUNTS"] or {}

    problems: list[str] = []
    notes: list[str] = []
    seen_ids: set[str] = set()
    lessons = examples = drills = fragments = quizzes = 0
    # Per Arabic field, how quran_reference read each string ("whole", "slice", or why it stays text).
    tally = {name: collections.Counter() for name in ARABIC_FIELDS}
    all_ids = {l["id"] for c in chapters for l in c.get("lessons", [])}

    for chapter in chapters:
        if chapter.get("stage") not in stage_order:
            problems.append(f"chapter {chapter.get('id')}: unknown stage {chapter.get('stage')}")
        for lesson in chapter.get("lessons", []):
            lessons += 1
            lid = lesson.get("id", "")
            if not lid or not lesson.get("titleEn") or not lesson.get("body"):
                problems.append(f"lesson {lid or '<missing id>'}: missing id/title/body")
            if lid in seen_ids:
                problems.append(f"duplicate lesson id {lid}")
            seen_ids.add(lid)
            lesson.pop("narrationUrl", None)
            for example in lesson.get("examples", []):
                examples += 1
                surah, ayah = example.get("surahId"), example.get("ayahNumber")
                if surah not in counts or not 1 <= (ayah or 0) <= counts[surah]:
                    problems.append(f"lesson {lid}: bad example {surah}:{ayah}")
                    continue
                # The words to listen at: located in the app's own text, stored as a span, never
                # as a copy of the words.
                word = (example.pop("word", None) or "").strip()
                if word:
                    span = locate_slice(word.split(), tokens[(surah, ayah)])
                    if span is None:
                        problems.append(f"lesson {lid}: example words {word!r} are not in {surah}:{ayah}")
                    else:
                        example["wordSpan"] = [span[0], span[1]]
            # The uncited Arabic of drills, rule-card fragments and quiz lines: a string that is one
            # unambiguous run of Quran words becomes a reference into the app's text.
            for drill in lesson.get("drills") or []:
                drills += 1
                if note := reference_arabic(drill, "text", index, tally["drills"]):
                    notes.append(f"lesson {lid} drill: {note}")
            for fragment in (lesson.get("ruleCard") or {}).get("fragments") or []:
                fragments += 1
                if note := reference_arabic(fragment, "text", index, tally["fragments"]):
                    notes.append(f"lesson {lid} fragment: {note}")
            for question in lesson.get("quiz") or []:
                quizzes += 1
                choices = question.get("choices") or []
                if not 0 <= int(question.get("answer", -1)) < len(choices):
                    problems.append(f"lesson {lid}: quiz answer out of range")
                if note := reference_arabic(question, "arabic", index, tally["quiz"]):
                    notes.append(f"lesson {lid} quiz: {note}")
            for related in lesson.get("related") or []:
                if related not in all_ids:
                    problems.append(f"lesson {lid}: related {related} does not exist")

    softened = soften_tree(chapters, soften)
    stages = [{"id": s, "titleEn": soften(stage_meta[s]["titleEn"]), "titleAr": stage_meta[s]["titleAr"],
               "blurb": soften(stage_meta[s]["blurbEn"])} for s in stage_order]
    problems += dashes_left(softened, "chapters") + dashes_left(stages, "stages")

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:40]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)

    pack = {"version": 4, "stages": stages, "ruleCounts": rule_counts, "chapters": softened}
    body = json.dumps(pack, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    blob = xz_compress(body)
    OUT.write_bytes(blob)

    print(f"{len(chapters)} chapters, {lessons} lessons, {examples} examples, {drills} drills, "
          f"{fragments} fragments, {quizzes} quiz questions")
    for name, counter in tally.items():
        refs = counter["whole"] + counter["slice"]
        kept = sum(count for kind, count in counter.items() if kind not in ("whole", "slice"))
        reasons = ", ".join(f"{count} {kind}" for kind, count in sorted(counter.items()) if kind in TEXT_REASONS)
        print(f"  {name}: {refs} as ayah references ({counter['whole']} whole ayahs, {counter['slice']} slices), "
              f"{kept} kept as text ({reasons})")
    for note in notes:
        print(f"  note: {note}")
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} xz")


if __name__ == "__main__":
    main()
