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
app's house rule); Arabic and ayah text is carried as written.

VALIDATION (build fails, writing nothing, if violated)
------------------------------------------------------
* every example's (surahId, ayahNumber) exists in this app's Quran;
* every lesson has an id, English title, and at least one body paragraph;
* lesson ids are unique across chapters; every `related` id resolves;
* every quiz answer indexes its choices.

OUTPUT: xz over {"version": 2, "stages": [...], "ruleCounts": {...},
        "chapters": [...]} in the source's own order (narrationUrl dropped:
        no recordings exist).

RUN:  python3 Scripts/build_tajweed_lessons.py [tilawa-root]
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from tilawa_ts import eval_modules, load_softener, xz_compress  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
OUT = ROOT / "Resources" / "Data" / "Quran" / "TajweedLessons.json.xz"
DEFAULT_TILAWA = ROOT.parent / "Tilawa"

PROSE_KEYS = ("summary", "focus", "caption", "literal", "technical", "trigger", "action", "hold",
              "gloss", "note", "wrong", "right", "why", "prompt", "explain", "label", "title",
              "subtitle", "blurbEn")
PROSE_LIST_KEYS = ("body", "keyPoints", "choices")


def ayah_counts() -> dict[int, int]:
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    return {s["id"]: len(s["ayahs"]) for s in quran}


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
        if "\u2014" in node or re.search(r"[A-Za-z)] - [A-Za-z(]", node):
            found.append(f"{path}: {node[:70]}")
    return found


def main() -> None:
    tilawa = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_TILAWA
    if not (tilawa / "src" / "data" / "tajweedLessons.ts").exists():
        raise SystemExit(f"source not found under {tilawa}")

    soften = load_softener()
    counts = ayah_counts()
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
    seen_ids: set[str] = set()
    lessons = examples = drills = quizzes = 0
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
            drills += len(lesson.get("drills") or [])
            for question in lesson.get("quiz") or []:
                quizzes += 1
                choices = question.get("choices") or []
                if not 0 <= int(question.get("answer", -1)) < len(choices):
                    problems.append(f"lesson {lid}: quiz answer out of range")
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

    pack = {"version": 2, "stages": stages, "ruleCounts": rule_counts, "chapters": softened}
    body = json.dumps(pack, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    blob = xz_compress(body)
    OUT.write_bytes(blob)

    print(f"{len(chapters)} chapters, {lessons} lessons, {examples} examples, {drills} drills, {quizzes} quiz questions")
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} xz")


if __name__ == "__main__":
    main()
