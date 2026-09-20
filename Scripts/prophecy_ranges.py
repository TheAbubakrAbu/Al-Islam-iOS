#!/usr/bin/env python3
"""Find the token ranges a `ScriptureQuote(hadith:)` needs for the Prophecies / Miracles articles.

    python3 Scripts/prophecy_ranges.py bukhari 3595 --en "you will certainly see that a lady"
    python3 Scripts/prophecy_ranges.py bukhari 3595 --ar "لَتَرَيَنَّ الظَّعِينَةَ"

`ScriptureQuote(hadith:cite:arabic:english:)` quotes a narration by TOKEN RANGE into the row our
packs carry, so the words on screen are the shelf's own and can never drift from them (see
PillarsView.swift). Working those ranges out by eye over a 400-word narration is where mistakes get
made, so this does it: give it a phrase and it prints the closed range to paste into the article.

Ranges are 0-based and inclusive, matching `ScriptureQuote`'s `a...b`.
"""
import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from islam_packs import Hadith, strip_marks  # noqa: E402


def tokens(text):
    return text.split()


def find_range(text, phrase, fold=lambda s: s):
    """The inclusive token range whose joined text contains `phrase`, or None."""
    toks = tokens(text)
    folded = [fold(t) for t in toks]
    needle = fold(phrase).split()
    if not needle:
        return None
    for start in range(len(folded)):
        if folded[start] != needle[0] and not folded[start].startswith(needle[0]):
            continue
        for end in range(start, min(start + len(needle) + 12, len(folded))):
            window = " ".join(folded[start:end + 1])
            if fold(phrase) in window:
                return start, end
    # Fall back to a loose search: first and last token of the phrase, anywhere.
    try:
        start = next(i for i, t in enumerate(folded) if needle[0] in t)
        end = next(i for i in range(len(folded) - 1, -1, -1) if needle[-1] in folded[i])
        if end >= start:
            return start, end
    except StopIteration:
        pass
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("slug")
    parser.add_argument("citation")
    parser.add_argument("--en", help="English phrase to locate")
    parser.add_argument("--ar", help="Arabic phrase to locate")
    parser.add_argument("--dump", action="store_true", help="print every token with its index")
    args = parser.parse_args()

    items = Hadith(args.slug).find(args.citation)
    if not items:
        sys.exit(f"no row {args.slug} {args.citation}")
    item = items[0]

    if args.dump:
        print("--- ENGLISH ---")
        for i, t in enumerate(tokens(item.text)):
            print(f"{i:4} {t}")
        print("--- ARABIC ---")
        for i, t in enumerate(tokens(item.arabic)):
            print(f"{i:4} {t}")
        return

    if args.en:
        found = find_range(item.text, args.en, fold=lambda s: re.sub(r"[^\w\s]", "", s.lower()))
        if found:
            a, b = found
            print(f"english: {a}...{b}")
            print("  " + " ".join(tokens(item.text)[a:b + 1]))
        else:
            print("english: NOT FOUND")

    if args.ar:
        found = find_range(item.arabic, args.ar, fold=strip_marks)
        if found:
            a, b = found
            print(f"arabic: {a}...{b}")
            print("  " + " ".join(tokens(item.arabic)[a:b + 1]))
        else:
            print("arabic: NOT FOUND")


if __name__ == "__main__":
    main()
