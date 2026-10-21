#!/usr/bin/env python3
"""Every Simple Mode hide must be a catalog case, and every case must be read by some site.

Simple Mode's catalog (iPhone/Settings/Model/SimpleTrims.swift, Docs/Product/Simple Mode Guide.md) lists
each control Simple Mode hides as one `SimpleTrim` case. A view reads a case as `settings.hides(.case)`
or `.hiddenInSimple(.case)`. This script is what keeps the three honest: the catalog, the sources and the
guide's table.

    Scripts/check_simple_trims.py                exit 1 on an unread case, a raw read of the flag
                                                 outside the allow-list, or a missing or stale guide block
    Scripts/check_simple_trims.py --list         print `case | surface | title | door | files`, one line per case
    Scripts/check_simple_trims.py --write-guide  rewrite the table between <!-- simple-trims:begin --> and
                                                 <!-- simple-trims:end --> in the guide, then exit 0
    Scripts/check_simple_trims.py --guide PATH   use PATH instead of the real guide (any mode); the
                                                 SIMPLE_TRIMS_GUIDE environment variable does the same

It parses the `Entry(` lines (one per line) and the `case` lines of `enum SimpleTrim` and fails if the two
lists differ. A case counts as read when a .swift file under iPhone, Apple Watch, Widget or Complication
other than the catalog contains `hides(.case` or `hiddenInSimple(.case`. A raw read is a line naming
`settings.simpleMode`, `Settings.shared.simpleMode` or `@AppStorage("simpleMode")` (a word boundary spares
`simpleModeFoldsAdvanced`); the setting's own page, the model files and a few other places are allowed.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE_DIRS = ["iPhone", "Apple Watch", "Widget", "Complication"]
CATALOG = os.path.join(ROOT, "iPhone", "Settings", "Model", "SimpleTrims.swift")
GUIDE = os.path.join(ROOT, "Docs", "Product", "Simple Mode Guide.md")

BEGIN = "<!-- simple-trims:begin -->"
END = "<!-- simple-trims:end -->"

# The brief's regex plus an optional empty argument list, so `.dropped()` parses.
ENTRY = re.compile(r'^\s*Entry\(\.(\w+), surface: \.(\w+), title: "([^"]*)", door: \.(\w+)(?:\((?:"([^"]*)")?\))?\)')
CASE = re.compile(r'^\s*case (\w+)\s*$')
RAW_READ = re.compile(r'settings\.simpleMode\b|Settings\.shared\.simpleMode\b|@AppStorage\("simpleMode"\)')
ALLOWED_SNIPPETS = [
    "$settings.simpleMode",
    "isOn: settings.simpleMode",
    "value: settings.simpleMode",
    "settings.simpleMode = ",
    ".onChange(of: settings.simpleMode)",
]
ALLOWED_FILES = {
    "iPhone/Settings/Model/Settings.swift",
    "iPhone/Settings/Model/SettingsQuran.swift",
    "iPhone/Settings/Model/SimpleTrims.swift",
    "iPhone/SplashScreen.swift",
    "iPhone/WelcomePages.swift",
    "iPhone/Settings/Cloud/CloudManifest.swift",
    "iPhone/Helpers/System/StressWalker.swift",
}
TIPS_FILE = "iPhone/Settings/Pages/TipsAndTricks.swift"
SETTINGS_VIEW_FILE = "iPhone/Settings/SettingsView.swift"
TOP_LEVEL = re.compile(r'^(?:(?:private|fileprivate|public|internal|final) )*(?:struct|enum|extension|class) ')


def parse_catalog():
    entries = []
    cases = []
    in_enum = False
    with open(CATALOG, encoding="utf-8") as handle:
        for line in handle:
            match = ENTRY.match(line)
            if match:
                trim, surface, title, door, arg = match.groups()
                entries.append((trim, surface, title, door, arg))
            if line.startswith("enum SimpleTrim"):
                in_enum = True
                continue
            if in_enum:
                if "}" in line:
                    in_enum = False
                    continue
                case = CASE.match(line)
                if case:
                    cases.append(case.group(1))
    return entries, cases


def door_text(kind, arg):
    arg = arg or ""
    if kind == "moreMenu":
        return "⋯ menu › " + arg
    if kind == "settings":
        return "Settings › " + arg
    if kind == "longPress":
        return "Press and hold › " + arg
    if kind == "elsewhere":
        # The app's `Door.text` capitalises a place, since the page shows it as a line of its own.
        return arg[:1].upper() + arg[1:]
    if kind == "dropped":
        return "Dropped: " + arg if arg else "Dropped"
    return arg


def swift_files():
    for top in SOURCE_DIRS:
        for folder, _, files in os.walk(os.path.join(ROOT, top)):
            for name in sorted(files):
                if name.endswith(".swift"):
                    yield os.path.join(folder, name)


def scan(cases):
    """Return (files that read each case, raw-read findings)."""
    readers = {case: [] for case in cases}
    raw = []
    patterns = {case: (f"hides(.{case}", f"hiddenInSimple(.{case}") for case in cases}
    catalog = os.path.abspath(CATALOG)
    for path in swift_files():
        rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
        try:
            with open(path, encoding="utf-8") as handle:
                lines = handle.read().splitlines()
        except (OSError, UnicodeDecodeError):
            continue
        if os.path.abspath(path) != catalog:
            text = "\n".join(lines)
            for case, needles in patterns.items():
                if any(needle in text for needle in needles):
                    readers[case].append(rel)
        if rel in ALLOWED_FILES:
            continue
        in_section = False
        for number, line in enumerate(lines, 1):
            if rel == SETTINGS_VIEW_FILE:
                if "struct SimpleModeSection" in line:
                    in_section = True
                elif in_section and TOP_LEVEL.match(line):
                    in_section = False
            if not RAW_READ.search(line):
                continue
            if any(snippet in line for snippet in ALLOWED_SNIPPETS):
                continue
            if rel == TIPS_FILE and "outsideSimpleMode" in line:
                continue
            if rel == SETTINGS_VIEW_FILE and in_section:
                continue
            raw.append((rel, number, line.strip()))
    return readers, raw


def render_block(entries):
    rows = ["| Case | Surface | Hidden in Simple | Door |", "| --- | --- | --- | --- |"]
    for trim, surface, title, door, arg in entries:
        rows.append(f"| {trim} | {surface} | {title} | {door_text(door, arg)} |")
    return "\n".join(rows)


def split_guide(text):
    """Return (before, block, after) or None when the marker block is missing."""
    start = text.find(BEGIN)
    end = text.find(END)
    if start < 0 or end < 0 or end < start:
        return None
    return text[:start + len(BEGIN)], text[start + len(BEGIN):end], text[end:]


def guide_path(argv):
    if "--guide" in argv:
        index = argv.index("--guide")
        if index + 1 < len(argv):
            return argv[index + 1]
    return os.environ.get("SIMPLE_TRIMS_GUIDE") or GUIDE


def main():
    argv = sys.argv[1:]
    guide = guide_path(argv)
    entries, cases = parse_catalog()
    problems = []
    if [entry[0] for entry in entries] != cases:
        problems.append("catalog: Entry lines and enum cases differ: "
                        f"{len(entries)} entries vs {len(cases)} cases")
    readers, raw = scan([entry[0] for entry in entries])

    if "--list" in argv:
        for trim, surface, title, door, arg in entries:
            print(f"{trim} | {surface} | {title} | {door_text(door, arg)} | {', '.join(readers[trim])}")
        return 0

    block = render_block(entries)
    if "--write-guide" in argv:
        with open(guide, encoding="utf-8") as handle:
            parts = split_guide(handle.read())
        if parts is None:
            print(f"guide: no simple-trims block in {guide}", file=sys.stderr)
            return 1
        before, _, after = parts
        with open(guide, "w", encoding="utf-8") as handle:
            handle.write(before + "\n" + block + "\n" + after)
        print(f"guide: wrote {len(entries)} rows to {guide}")
        return 0

    for trim in (entry[0] for entry in entries):
        if not readers[trim]:
            problems.append(f"unread: {trim}")
    for rel, number, line in raw:
        problems.append(f"raw read: {rel}:{number}: {line}")
    try:
        with open(guide, encoding="utf-8") as handle:
            parts = split_guide(handle.read())
    except OSError:
        parts = None
    if parts is None:
        problems.append("guide: no simple-trims block")
    elif parts[1].strip() != block:
        problems.append("guide: simple-trims block is stale (run --write-guide)")

    for problem in problems:
        print(problem)
    unread = sum(1 for p in problems if p.startswith("unread:"))
    raws = sum(1 for p in problems if p.startswith("raw read:"))
    if problems:
        print(f"FAIL: {unread} unread, {raws} raw reads, {len(problems) - unread - raws} other")
        return 1
    print(f"OK: {len(entries)} cases, all read, no raw reads, guide current")
    return 0


if __name__ == "__main__":
    sys.exit(main())
