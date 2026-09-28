#!/usr/bin/env python3
"""Gate the Prophecies of the Prophet and Miracles of the Prophets libraries against THIS APP'S OWN
hadith shelf and Quran. Non-zero exit means do not ship.

    python3 Scripts/verify_prophecies.py              # check every article in both libraries
    python3 Scripts/verify_prophecies.py --show       # also print each quote as the screen shows it
    python3 Scripts/verify_prophecies.py FILE ...     # check other files (a draft) instead

Every article is data (`SignBlock` in iPhone/Islam/SignsAndProphets.swift), so the quotes are read
straight out of the Swift: each `.hadith("slug:citation", cite:, arabic: a...b, english: c...d)` and
each `.quran("s:a-b")`. Nothing is listed here by hand, so the gate cannot drift from what ships
(the 2026-09-19 version kept its own candidate list, and 35 of its 43 verified prophecies never
reached the screen).

Why the shelf: the source sites cite the same hadith in four numbering schemes (Yaqeen's "Sahih
al-Bukhari 4:197, no. 3595" is volume:page plus number; Proving Islam's "Vol. 9, Book 88, Hadith
203" is the old USC/MSA scheme). The app quotes a row of its OWN packs by token range, so every claim
is resolved to a row here and read there.

The policy this enforces (Abu's standing rule, see the islamic-content-standards memory):
  * sahih or hasan only: anything our packs grade weak is refused, not softened;
  * Bukhari and Muslim rows carry no grade line (inclusion IS the grade), so an empty list there is
    a pass; an ungraded row from any other book is NOT, because nobody vouched for it;
  * every token range lies inside its row, every Quran reference is an ayah this app has;
  * no em dash, and no spaced hyphen standing in for one, in any user-facing string.
"""
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "Scripts"))
from islam_packs import is_weak, _quran  # noqa: E402
from hadith_spans import row as shelf_row, words as shelf_words  # noqa: E402

LIBRARIES = [ROOT / "iPhone/Islam" / name for name in (
    "PropheciesView.swift", "PropheciesContent.swift",
    "ProphetMiraclesView.swift", "ProphetMiraclesContent.swift",
    "SignsAndProphets.swift", "MiraclesView.swift")]

SOUND = re.compile(r"sahih|hasan|صحيح|حسن", re.I)
HADITH_RE = re.compile(
    r'\.hadith\(\s*"([a-z_0-9]+):([0-9]+[a-z]?|#[0-9]+)"\s*,\s*cite:\s*"([^"]*)"\s*,'
    r'\s*arabic:\s*(\d+)\.\.\.(\d+)\s*,\s*english:\s*(\d+)\.\.\.(\d+)\s*\)')
QURAN_RE = re.compile(r'\.quran\(\s*"([^"]+)"\s*\)')
REFERENCE_RE = re.compile(r"^(\d+):(\d+)(?:-(\d+))?((?:\s*,\s*\d+(?:-\d+)?)*)$")
# Every string literal on a line that is user-facing prose: `.text(`, titles, summaries, footers.
PROSE_RE = re.compile(r'(?:\.text\(|title:|summary:|signs:|footer:|Text\((?:verbatim:)?)\s*"((?:[^"\\]|\\.)*)"')


def verdict(slug, grades):
    """sahih/hasan, weak, or unknown, by the WEIGHT of the grade lines, not by any single one.

    Our packs carry up to five graders per row and they disagree: "holding to one's religion like a
    burning coal" (Tirmidhi 2260) is Sahih to Ahmad Shakir and al-Albani, Hasan to Darussalam, and
    Da'if only to Zubair Ali Zai. "Any weak grade drops it" would throw out a hadith the majority
    authenticate; "any sound grade keeps it" would keep weak ones a single lenient grader passed.
    So: sound when the sound graders are a MAJORITY, weak when they are not.
    """
    if not grades:
        return "sahih-by-collection" if slug in ("bukhari", "muslim") else "unknown"
    sound = sum(1 for g in grades if SOUND.search(g[1]) and not is_weak([g]))
    weak = sum(1 for g in grades if is_weak([g]))
    if sound == 0 and weak == 0:
        return "unknown"
    return "sound" if sound > weak else "weak"


def quran_ok(reference):
    m = REFERENCE_RE.match(reference.strip())
    if not m:
        return False
    surah = int(m.group(1))
    runs = [(int(m.group(2)), int(m.group(3) or m.group(2)))]
    runs += [(int(lo), int(hi or lo)) for lo, hi in re.findall(r"(\d+)(?:-(\d+))?", m.group(4) or "")]
    quran = _quran()
    if not 1 <= surah <= len(quran):
        return False
    count = len(quran[surah - 1]["ayahs"])
    return all(1 <= lo <= hi <= count for lo, hi in runs)


def check(paths, show):
    failures, hadith_count, quran_count = [], 0, 0
    for path in paths:
        src = path.read_text(encoding="utf-8")
        line_of = lambda pos: src.count("\n", 0, pos) + 1  # noqa: E731

        for m in HADITH_RE.finditer(src):
            hadith_count += 1
            slug, citation, cite = m.group(1), m.group(2), m.group(3)
            a0, a1, e0, e1 = (int(m.group(i)) for i in range(4, 8))
            where = f"{path.name}:{line_of(m.start())} {slug}:{citation}"
            item = shelf_row(slug, citation)
            if item is None:
                failures.append(f"{where}: not a row of this app's shelf")
                continue
            call = verdict(slug, item.grades)
            if call in ("weak", "unknown"):
                failures.append(f"{where}: graded {call} {item.grades}")
            arabic, english = item.arabic.split(), item.text.split()
            if not 0 <= a0 <= a1 < len(arabic):
                failures.append(f"{where}: arabic {a0}...{a1} outside its {len(arabic)} tokens")
            if not 0 <= e0 <= e1 < len(english):
                failures.append(f"{where}: english {e0}...{e1} outside its {len(english)} tokens")
            if show:
                print(f"\n[{call}] {where} ({cite})")
                print(f"  EN: {shelf_words(item.text, (e0, e1))}")
                print(f"  AR: {shelf_words(item.arabic, (a0, a1))}")

        for m in QURAN_RE.finditer(src):
            quran_count += 1
            if not quran_ok(m.group(1)):
                failures.append(f"{path.name}:{line_of(m.start())}: Quran {m.group(1)!r} is not an ayah range of this app")

        for m in PROSE_RE.finditer(src):
            text = m.group(1)
            where = f"{path.name}:{line_of(m.start())}"
            if "\u2014" in text or "\\u{2014}" in text:
                failures.append(f"{where}: em dash in {text[:60]!r}")
            if " - " in text:
                failures.append(f"{where}: spaced hyphen standing in for a dash in {text[:60]!r}")

    print(f"{hadith_count} hadith references, {quran_count} Quran references checked in {len(paths)} files")
    for f in failures:
        print("FAIL", f)
    return not failures


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="*")
    parser.add_argument("--show", action="store_true")
    args = parser.parse_args()
    paths = [Path(f).resolve() for f in args.files] or [p for p in LIBRARIES if p.exists()]
    sys.exit(0 if check(paths, args.show) else 1)


if __name__ == "__main__":
    main()
