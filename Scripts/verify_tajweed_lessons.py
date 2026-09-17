#!/usr/bin/env python3
"""Gate for the shipped TajweedLessons.json.xz.

Checks the pack ON DISK: it decodes as xz and is version 4; every lesson carries
an id, English title, and body; lesson ids are unique; every example references
a real ayah, its `wordSpan` sits inside that ayah's tokens, and no example
carries a copy of the words (`word`); every drill, rule-card fragment and quiz
line that is Quran carries an `ayah` reference [surah, ayahNumber, first, last]
whose span sits inside that ayah's tokens, with no `text`/`arabic` beside it;
no drill `text`, fragment `text` or quiz `arabic` still shipped as text is a
copy of an ayah or of a run of two or more words found in exactly one ayah
(the builder's `quran_reference`, re-run here, so a rebuild cannot bring a copy
back); and (when Tilawa is reachable) a fresh build reproduces the pack byte
for byte.

Run:  python3 Scripts/verify_tajweed_lessons.py [tilawa-root]
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import subprocess
import sys
import lzma

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACK = ROOT / "Resources" / "Data" / "Quran" / "TajweedLessons.json.xz"

_spec = importlib.util.spec_from_file_location("b", ROOT / "Scripts" / "build_tajweed_lessons.py")
_builder = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_builder)


def main() -> None:
    if not PACK.exists():
        raise SystemExit(f"pack missing: {PACK}")

    blob = PACK.read_bytes()
    try:
        raw = lzma.decompress(blob)
    except lzma.LZMAError as error:
        raise SystemExit(f"pack is not a raw deflate stream: {error}")

    pack = json.loads(raw.decode("utf-8"))
    chapters = pack.get("chapters", [])
    counts = _builder.ayah_counts()
    tokens = _builder.ayah_tokens()
    token_counts = {key: len(toks) for key, toks in tokens.items()}
    index = _builder.quran_index(tokens)

    problems: list[str] = []
    if pack.get("version") != 4:
        problems.append(f"pack version {pack.get('version')!r}, expected 4 (drill, fragment and quiz ayahs as references)")
    seen: set[str] = set()
    lessons = examples = spans = 0
    # Per Arabic field: rows seen, rows carrying an ayah reference (whole ayahs / slices), rows kept as text.
    arabic = {name: {"rows": 0, "whole": 0, "slice": 0, "text": 0} for name in _builder.ARABIC_FIELDS}

    def check_arabic(row: dict, name: str, label: str) -> None:
        """One drill / fragment / quiz row: a valid reference with no text beside it, or text that is
        not a copy of Quran words."""
        field = _builder.ARABIC_FIELDS[name]
        stats = arabic[name]
        reference = row.get("ayah")
        if reference is not None:
            stats["rows"] += 1
            if field in row:
                problems.append(f"{label}: carries {field} beside its ayah reference")
            if (not isinstance(reference, list) or len(reference) != 4
                    or not all(isinstance(v, int) for v in reference)):
                problems.append(f"{label}: ayah reference {reference!r} is not [surah, ayah, first, last]")
                return
            surah, ayah, first, last = reference
            if (surah, ayah) not in token_counts:
                problems.append(f"{label}: ayah reference {surah}:{ayah} does not exist")
                return
            if not 0 <= first <= last < token_counts[(surah, ayah)]:
                problems.append(f"{label}: ayah span {first}-{last} outside {surah}:{ayah}")
                return
            whole = first == 0 and last == token_counts[(surah, ayah)] - 1
            if not whole and tokens[(surah, ayah)][0] == "۞":
                whole = first == 1 and last == token_counts[(surah, ayah)] - 1
            stats["whole" if whole else "slice"] += 1
        elif isinstance(row.get(field), str):
            stats["rows"] += 1
            stats["text"] += 1
            found, kind, _ = _builder.quran_reference(row[field], index)
            if found is not None:
                problems.append(f"{label}: {field} {row[field]!r} is a copy of {kind} {found[0]}:{found[1]} "
                                f"tokens {found[2]}-{found[3]}; rebuild the pack")

    for chapter in chapters:
        if not chapter.get("id") or not chapter.get("title"):
            problems.append(f"chapter {chapter.get('id')}: missing id/title")
        for lesson in chapter.get("lessons", []):
            lessons += 1
            lid = lesson.get("id", "")
            if not lid or not lesson.get("titleEn") or not lesson.get("body"):
                problems.append(f"lesson {lid or '<missing>'}: missing id/title/body")
            if lid in seen:
                problems.append(f"duplicate lesson id {lid}")
            seen.add(lid)
            for example in lesson.get("examples", []):
                examples += 1
                surah, ayah = example.get("surahId"), example.get("ayahNumber")
                if surah not in counts or not 1 <= (ayah or 0) <= counts[surah]:
                    problems.append(f"lesson {lid}: bad example {surah}:{ayah}")
                    continue
                if "word" in example:
                    problems.append(f"lesson {lid}: example {surah}:{ayah} carries a copy of its words")
                span = example.get("wordSpan")
                if span is not None:
                    spans += 1
                    if (not isinstance(span, list) or len(span) != 2
                            or not 0 <= span[0] <= span[1] < token_counts[(surah, ayah)]):
                        problems.append(f"lesson {lid}: wordSpan {span} outside {surah}:{ayah}")
            for at, drill in enumerate(lesson.get("drills") or []):
                check_arabic(drill, "drills", f"lesson {lid} drill {at}")
            for at, fragment in enumerate((lesson.get("ruleCard") or {}).get("fragments") or []):
                check_arabic(fragment, "fragments", f"lesson {lid} fragment {at}")
            for at, question in enumerate(lesson.get("quiz") or []):
                check_arabic(question, "quiz", f"lesson {lid} quiz {at}")

    tilawa = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else _builder.DEFAULT_TILAWA
    if (tilawa / "src" / "data" / "tajweedLessons.ts").exists():
        before = blob
        subprocess.run([sys.executable, str(ROOT / "Scripts" / "build_tajweed_lessons.py"), str(tilawa)],
                       check=True, capture_output=True)
        if PACK.read_bytes() != before:
            problems.append("pack does not match a fresh build from source")
    else:
        print(f"note: Tilawa source not found at {tilawa} - skipped the rebuild check")

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:20]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)

    refs = sum(s["whole"] + s["slice"] for s in arabic.values())
    whole = sum(s["whole"] for s in arabic.values())
    kept = sum(s["text"] for s in arabic.values())
    fields = ", ".join(f"{s['rows']} {name}" for name, s in arabic.items())
    print(f"OK: {len(chapters)} chapters, {lessons} lessons, {examples} examples ({spans} with word spans, no text), "
          f"{fields}: {refs} as ayah references ({whole} whole ayahs, {refs - whole} slices), "
          f"{kept} teaching text (none a copy), all ids unique, all refs valid")


if __name__ == "__main__":
    main()
