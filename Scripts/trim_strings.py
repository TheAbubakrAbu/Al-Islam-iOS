#!/usr/bin/env python3
"""Ship each extension only the strings it can show (a Run Script phase of the Watch, Complication and
Widget targets).

Resources/Localizable.xcstrings is one catalog for every target, so Xcode compiles all of its keys (the whole
iPhone app's interface, about 14,000 of them) into each target that carries it, in every language: about
3 MB per language per target. On the watch that came twice (Watch.app and Complication.appex): with 11
languages the watchOS variant of build 271 (4.6.7) was 95 MB, and App Store Connect refuses a watch app over
75 MB after thinning (ITMS-90389, 2026-11-23). The Widget carried the same 44 MB inside the iPhone app.

This phase runs after Copy Bundle Resources. It compiles a copy of the catalog holding only the keys the
target can reach, with the same compiler Xcode uses (`xcstringstool compile`), and puts its
Localizable.strings and Localizable.stringsdict in place of the full ones. A key is kept when

  1. the compiler extracted it from one of this target's own Swift files (the target's .stringsdata), or
  2. one of those files (or the Adhan package) holds it as a plain string literal: a value shown through
     `.localizedDisplay`, an enum's raw value, a prayer name, or
  3. one of those files holds an interpolated literal it matches ("surah.meaning.\\(id)"), or
  4. with --with-data-keys, it is a manual key: data text shown through `.localizedDisplay`. The Watch app
     ships the tajweed course, surah info, the Names and the hadith quotes and shows them, and the catalog
     does not record which data a manual key came from, so the Watch keeps them, less the course fields its
     lesson page never shows (--watch-course, below). The Complication and Widget ship no data.

Rules 2 and 3 scan only code the target compiles (`#if os(iOS)` branches are left out of a watch scan) and
are deliberately generous: a key kept that is never shown costs a few bytes, a key dropped that is shown
reads English. The catalog itself is never touched.

    python3 "${PROJECT_DIR}/Scripts/trim_strings.py" [--with-data-keys [--watch-course]]   # the build phase
    ./Scripts/trim_strings.py --objects DIR [--conditions "HAS_X ..."] [flags] --report    # what it would keep

Skips itself when nothing it reads has changed since its last run (a stamp in DERIVED_FILE_DIR), since the
compile takes about five seconds.
"""
import glob
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(REPO, "Resources", "Localizable.xcstrings")
# Linked into every target this runs in; its enum raw values can reach `.localizedDisplay`.
PACKAGE_SOURCES = os.path.join(REPO, "Resources", "Packages", "adhan-swift-main", "Sources")
OUTPUTS = ("Localizable.strings", "Localizable.stringsdict")
# The tajweed course reaches the Watch as manual keys. Its lesson page there (TajweedLessonWatchView,
# iPhone/Islam/Tajweed/TajweedView.swift) shows titles, summary, definition, rule card, letter sets, body, word
# groups, key points and the mistakes' wrong and right forms; the fields below stay on the phone, so with
# --watch-course their text is left out of the Watch (2,000 keys, about 7 MB over 14 languages). Each maps to
# the Swift properties that would show it: the build FAILS if watch-compiled code that touches the course
# reads one of them, so a field the watch starts to show can never quietly read English. Short strings are
# always kept (a word like "Light" may be shown elsewhere), only sentences go.
COURSE = os.path.join(REPO, "Resources", "Data", "Quran", "TajweedLessons.json.xz")
WATCH_HIDDEN_COURSE_FIELDS = {
    "lessons.examples": ("examples",),
    "lessons.quiz": ("quiz",),
    "lessons.mistakes.why": ("why",),
    "lessons.table": ("table",),
    "lessons.drills": ("drills",),
    "lessons.images": ("images",),
    "lessons.ruleCard.fragments": ("fragments",),
    "lessons.ruleCard.mnemonic": ("mnemonicGloss", "mnemonicArabic"),
    "lessons.ruleCard.countEn": ("countEn",),
    "chapters.subtitle": ("subtitle",),
    "stages.blurb": ("blurb",),
}
COURSE_TYPES = re.compile(r"\bTajweed(Lesson|Course|Quiz)")
MIN_DROPPED_LENGTH = 16
# An interpolated literal becomes a pattern only when a fixed end of it is at least this long, so
# "\(a) \(b)" does not pull in every key holding a space.
MIN_ANCHOR = 3


def fail(message):
    # The Xcode issue navigator shows "error:" lines as build errors.
    print(f"error: trim_strings: {message}", file=sys.stderr)
    sys.exit(1)


# Conditional compilation ---------------------------------------------------------------------------------------
# A watch-compiled file is mostly shared code, and its `#if os(iOS)` branches (944 of them in 2026-11) hold
# literals the watch never compiles. Those branches are blanked before the literal scan. A condition is
# decided only when it is certain: os(...), targetEnvironment(macCatalyst) and the target's own
# SWIFT_ACTIVE_COMPILATION_CONDITIONS (DEBUG, HAS_ADHAN, ...); anything else (canImport, simulator) counts as
# possibly true, so its branch is scanned.

CONDITION_TOKEN = re.compile(r"\s*(\|\||&&|!|\(|\)|[A-Za-z_][A-Za-z0-9_]*\s*\([^()]*\)|[A-Za-z_][A-Za-z0-9_]*)")


def evaluate(expression, flags, platform):
    """True, False, or None (cannot tell) for an #if condition."""
    tokens, pos = [], 0
    while pos < len(expression):
        m = CONDITION_TOKEN.match(expression, pos)
        if not m:
            if expression[pos:].strip() == "" or expression[pos:].lstrip().startswith("//"):
                break
            return None
        tokens.append(m.group(1).replace(" ", ""))
        pos = m.end()

    def atom(tok):
        call = re.fullmatch(r"(\w+)\((.*)\)", tok)
        if call:
            name, arg = call.groups()
            if name == "os":
                return arg == platform
            if name == "targetEnvironment" and arg == "macCatalyst":
                return False
            return None
        if tok in ("true", "false"):
            return tok == "true"
        if flags is None:
            return None
        return tok in flags

    def parse_or(i):
        value, i = parse_and(i)
        while i < len(tokens) and tokens[i] == "||":
            right, i = parse_and(i + 1)
            value = True if (value is True or right is True) else (False if value is False and right is False else None)
        return value, i

    def parse_and(i):
        value, i = parse_not(i)
        while i < len(tokens) and tokens[i] == "&&":
            right, i = parse_not(i + 1)
            value = False if (value is False or right is False) else (True if value is True and right is True else None)
        return value, i

    def parse_not(i):
        if i < len(tokens) and tokens[i] == "!":
            value, i = parse_not(i + 1)
            return (None if value is None else not value), i
        if i < len(tokens) and tokens[i] == "(":
            value, i = parse_or(i + 1)
            return value, i + 1  # the closing parenthesis
        if i < len(tokens):
            return atom(tokens[i]), i + 1
        return None, i

    try:
        value, end = parse_or(0)
    except (IndexError, RecursionError):
        return None
    return value if end == len(tokens) else None


DIRECTIVE = re.compile(r"^\s*#(if|elseif|else|endif)\b(.*)$")


def active_code(text, flags, platform):
    """The file with every branch the target certainly does not compile blanked (line count kept)."""
    out = []
    # Per open #if: [this branch may be compiled, an earlier branch certainly was]
    stack = []
    live = True
    for line in text.split("\n"):
        m = DIRECTIVE.match(line)
        if m:
            kind, rest = m.group(1), m.group(2)
            if kind == "if":
                value = evaluate(rest, flags, platform)
                stack.append([value is not False, value is True])
            elif kind == "elseif" and stack:
                frame = stack[-1]
                value = evaluate(rest, flags, platform)
                frame[0] = not frame[1] and value is not False
                frame[1] = frame[1] or value is True
            elif kind == "else" and stack:
                frame = stack[-1]
                frame[0] = not frame[1]
            elif kind == "endif" and stack:
                stack.pop()
            live = all(f[0] for f in stack) if stack else True
            out.append("")
            continue
        out.append(line if live else "")
    return "\n".join(out)


# Swift string literals ---------------------------------------------------------------------------------------

ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "0": "\0", '"': '"', "'": "'", "\\": "\\"}


def swift_literals(text):
    """Every string literal in a Swift file as a list of its fixed parts: ["Fajr"] for "Fajr",
    ["surah.meaning.", ""] for "surah.meaning.\\(id)". Handles escapes, nested literals inside an
    interpolation, multi-line literals and raw (#"..."#) literals; comments are skipped."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if text.startswith("//", i):
            j = text.find("\n", i)
            i = n if j < 0 else j
            continue
        if text.startswith("/*", i):
            j = text.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        if c == "#" or c == '"':
            hashes = 0
            j = i
            while j < n and text[j] == "#":
                hashes += 1
                j += 1
            if j < n and text[j] == '"':
                parts, i = read_literal(text, j, hashes, out)
                if parts is not None:
                    out.append(parts)
                continue
            i = j if j > i else i + 1
            continue
        i += 1
    return out


def read_literal(text, start, hashes, sink):
    """Read the literal whose opening quote is at `start`; return (fixed parts, index after it). Literals
    nested inside an interpolation are appended to `sink` as literals of their own."""
    n = len(text)
    multiline = text.startswith('"""', start)
    i = start + (3 if multiline else 1)
    close = ('"""' if multiline else '"') + "#" * hashes
    escape = "\\" + "#" * hashes
    parts, current = [], []
    while i < n:
        if text.startswith(close, i):
            parts.append("".join(current))
            return parts, i + len(close)
        if not multiline and text[i] == "\n":
            return None, i  # unterminated on its line: not a literal after all
        if text.startswith(escape, i):
            k = i + len(escape)
            if k >= n:
                break
            e = text[k]
            if e == "(":
                # Interpolation: skip to its matching parenthesis, reading nested literals on the way.
                parts.append("".join(current))
                current = []
                depth, k = 1, k + 1
                while k < n and depth:
                    ch = text[k]
                    if ch == '"' or ch == "#":
                        h, m = 0, k
                        while m < n and text[m] == "#":
                            h, m = h + 1, m + 1
                        if m < n and text[m] == '"':
                            nested, k = read_literal(text, m, h, sink)
                            if nested is not None:
                                sink.append(nested)
                            continue
                        k = m if m > k else k + 1
                        continue
                    depth += ch == "("
                    depth -= ch == ")"
                    k += 1
                i = k
                continue
            if e == "u" and k + 1 < n and text[k + 1] == "{":
                end = text.find("}", k)
                try:
                    current.append(chr(int(text[k + 2:end], 16)))
                except ValueError:
                    pass
                i = end + 1
                continue
            if multiline and e == "\n":
                i = k + 1  # a line continuation
                continue
            current.append(ESCAPES.get(e, e))
            i = k + 1
            continue
        current.append(text[i])
        i += 1
    return None, n


def multiline_body(parts):
    # A multi-line literal's indentation is stripped by the compiler; the key never starts with a newline.
    return [p.lstrip("\n") if idx == 0 else p for idx, p in enumerate(parts)]


# The keep set --------------------------------------------------------------------------------------------------

def stringsdata(objects):
    """(extracted keys, source files) from the target's .stringsdata files, one folder per architecture."""
    keys, sources = set(), set()
    files = glob.glob(os.path.join(objects, "*", "*.stringsdata"))
    for path in files:
        try:
            data = json.load(open(path, encoding="utf-8"))
        except (ValueError, OSError):
            continue
        source = data.get("source", "")
        if os.path.isabs(source):
            # A moved or deleted file leaves its old .stringsdata behind in a long-lived DerivedData.
            if not os.path.exists(source):
                continue
            sources.add(source)
        for entry in data.get("tables", {}).get("Localizable", []):
            keys.add(entry["key"])
    return files, keys, sources


def package_sources():
    return sorted(glob.glob(os.path.join(PACKAGE_SOURCES, "**", "*.swift"), recursive=True))


def course_fields():
    """(shown, left out) strings of the tajweed course pack, split by WATCH_HIDDEN_COURSE_FIELDS."""
    import lzma
    course = json.loads(lzma.decompress(open(COURSE, "rb").read()))
    shown, hidden = set(), set()

    def walk(value, where):
        if isinstance(value, dict):
            for key, inner in value.items():
                walk(inner, f"{where}.{key}")
        elif isinstance(value, list):
            for inner in value:
                walk(inner, where)
        elif isinstance(value, str):
            gone = any(where == f or where.startswith(f + ".") for f in WATCH_HIDDEN_COURSE_FIELDS)
            (hidden if gone else shown).add(value)

    for stage in course.get("stages", []):
        walk(stage, "stages")
    for chapter in course.get("chapters", []):
        for key, value in chapter.items():
            if key == "lessons":
                for lesson in value:
                    walk(lesson, "lessons")
            else:
                walk(value, f"chapters.{key}")
    return shown, hidden


def course_guard(texts):
    """Lines of compiled code, in files that touch the course, reading a field the Watch leaves out."""
    names = sorted({name for props in WATCH_HIDDEN_COURSE_FIELDS.values() for name in props})
    # `lesson.quiz`, `card?.fragments`: a member read on a value, not an enum case (`case .quiz:`).
    reads = re.compile(r"(?<=[\w)\]?!])\.(" + "|".join(names) + r")\b")
    found = []
    for path, text in texts:
        if not COURSE_TYPES.search(text):
            continue
        for number, line in enumerate(text.split("\n"), 1):
            hit = reads.search(line.split("//")[0])
            if hit:
                found.append(f"{os.path.relpath(path, REPO)}:{number}: .{hit.group(1)}")
    return found


def keep_set(strings, extracted, sources, with_data_keys, flags=None, platform="watchOS", watch_course=False):
    catalog_keys = set(strings)
    literal, patterns, texts = set(), [], []
    for path in sources:
        try:
            text = open(path, encoding="utf-8").read()
        except (OSError, UnicodeDecodeError):
            continue
        # The package is built with its own conditions: only its os() branches are decided.
        text = active_code(text, None if path.startswith(PACKAGE_SOURCES) else flags, platform)
        texts.append((path, text))
        for parts in swift_literals(text):
            parts = multiline_body(parts)
            if len(parts) == 1:
                if parts[0] in catalog_keys:
                    literal.add(parts[0])
            else:
                patterns.append(parts)
    # Index the catalog by each key's first and last few characters so a pattern is tried only against
    # keys that could match it.
    by_prefix, by_suffix = {}, {}
    for key in catalog_keys:
        if len(key) >= MIN_ANCHOR:
            by_prefix.setdefault(key[:MIN_ANCHOR], []).append(key)
            by_suffix.setdefault(key[-MIN_ANCHOR:], []).append(key)
    matched = set()
    for parts in patterns:
        head, tail = parts[0], parts[-1]
        if len(head) >= MIN_ANCHOR:
            candidates = by_prefix.get(head[:MIN_ANCHOR], ())
        elif len(tail) >= MIN_ANCHOR:
            candidates = by_suffix.get(tail[-MIN_ANCHOR:], ())
        else:
            continue
        regex = re.compile(".*".join(re.escape(p) for p in parts), re.S)
        for key in candidates:
            if key not in matched and regex.fullmatch(key):
                matched.add(key)
    manual = {k for k, v in strings.items() if v.get("extractionState") == "manual"} if with_data_keys else set()
    left_out = set()
    if with_data_keys and watch_course:
        violations = course_guard(texts)
        if violations:
            fail("the Watch now reads tajweed course fields this script leaves out of it:\n  "
                 + "\n  ".join(violations)
                 + "\nTake those fields out of WATCH_HIDDEN_COURSE_FIELDS in Scripts/trim_strings.py so their "
                   "translations ship to the watch.")
        shown, hidden = course_fields()
        left_out = {k for k in hidden - shown if len(k) >= MIN_DROPPED_LENGTH} & manual
        left_out -= extracted | literal | matched
        manual -= left_out
    keep = (extracted & catalog_keys) | literal | matched | manual
    counts = {"extracted": len(extracted & catalog_keys), "literal": len(literal - extracted),
              "pattern": len(matched - extracted - literal),
              "data": len(manual - extracted - literal - matched)}
    if watch_course:
        counts["course text the watch never shows, left out"] = len(left_out)
    return keep, counts


# The phase -----------------------------------------------------------------------------------------------------

def file_stats(paths):
    stats = []
    for p in sorted(paths):
        try:
            st = os.stat(p)
            stats.append((p, st.st_size, st.st_mtime_ns))
        except OSError:
            stats.append((p, -1, 0))
    return stats


def product_outputs(product):
    return [p for name in OUTPUTS for p in glob.glob(os.path.join(product, "*.lproj", name))]


def signature(flags, stringsdata_files, sources, product):
    """Everything a run depends on: the catalog, this script, the target's .stringsdata and sources, and
    the product's Localizable files as this script last left them (Xcode rewrites them when it recompiles
    the catalog)."""
    blob = json.dumps([flags, os.environ.get("SWIFT_ACTIVE_COMPILATION_CONDITIONS", ""),
                       file_stats([CATALOG, COURSE, os.path.abspath(__file__)]),
                       file_stats(stringsdata_files), file_stats(sources),
                       file_stats(product_outputs(product))])
    return hashlib.sha1(blob.encode()).hexdigest()


def compile_trimmed(catalog, keep, work, binary):
    trimmed = dict(catalog)
    trimmed["strings"] = {k: v for k, v in catalog["strings"].items() if k in keep}
    os.makedirs(work, exist_ok=True)
    path = os.path.join(work, "Localizable.xcstrings")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(trimmed, f, ensure_ascii=False)
    out = os.path.join(work, "out")
    shutil.rmtree(out, ignore_errors=True)
    command = ["xcrun", "xcstringstool", "compile", path, "--output-directory", out,
               "--serialization-format", "binary" if binary else "text"]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        fail(f"xcstringstool compile failed:\n{result.stdout}{result.stderr}")
    return out


def install(compiled, product):
    """Put each language's trimmed files in place of the full ones; a file the trimmed compile no longer
    makes (a language left with no plural key) goes too. Nothing else in the .lproj is touched."""
    before = after = 0
    languages = {os.path.basename(p) for p in glob.glob(os.path.join(compiled, "*.lproj"))}
    languages |= {os.path.basename(os.path.dirname(p)) for p in product_outputs(product)}
    for lproj in sorted(languages):
        for name in OUTPUTS:
            src = os.path.join(compiled, lproj, name)
            dst = os.path.join(product, lproj, name)
            if os.path.exists(dst):
                before += os.path.getsize(dst)
                os.remove(dst)
            if os.path.exists(src):
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copyfile(src, dst)
                after += os.path.getsize(dst)
    return before, after


def main(argv):
    with_data_keys = "--with-data-keys" in argv
    watch_course = "--watch-course" in argv
    report = "--report" in argv

    def option(name, env):
        if name in argv:
            return argv[argv.index(name) + 1]
        return os.environ.get(env, "")

    objects = option("--objects", "OBJECT_FILE_DIR_normal")
    if not objects:
        fail("no OBJECT_FILE_DIR_normal: run from a Run Script phase, or pass --objects")
    files, extracted, sources = stringsdata(objects)
    if not files:
        fail(f"no .stringsdata under {objects}: the target needs SWIFT_EMIT_LOC_STRINGS = YES, and this phase "
             "must come after Compile Sources")
    sources = sorted(sources) + package_sources()
    target = os.environ.get("TARGET_NAME") or os.path.basename(os.path.dirname(objects.rstrip("/"))).removesuffix(".build")

    conditions = option("--conditions", "SWIFT_ACTIVE_COMPILATION_CONDITIONS")
    flags = set(conditions.split()) if conditions or "SWIFT_ACTIVE_COMPILATION_CONDITIONS" in os.environ else None
    platform = {"watchos": "watchOS", "watchsimulator": "watchOS", "iphoneos": "iOS", "iphonesimulator": "iOS"}.get(
        os.environ.get("PLATFORM_NAME", "watchos"), "watchOS")

    def plan():
        catalog = json.load(open(CATALOG, encoding="utf-8"))
        keep, counts = keep_set(catalog["strings"], extracted, sources, with_data_keys, flags, platform, watch_course)
        summary = (f"{target} keeps {len(keep):,} of {len(catalog['strings']):,} keys ("
                   + ", ".join(f"{v:,} {k}" for k, v in counts.items()) + ")")
        return catalog, keep, summary

    if report:
        print(plan()[2])
        return

    built = os.environ.get("TARGET_BUILD_DIR", "")
    folder = os.environ.get("UNLOCALIZED_RESOURCES_FOLDER_PATH", "")
    work_root = os.environ.get("DERIVED_FILE_DIR", "")
    if not (built and folder and work_root):
        fail("TARGET_BUILD_DIR, UNLOCALIZED_RESOURCES_FOLDER_PATH and DERIVED_FILE_DIR must be set")
    product = os.path.join(built, folder)
    work = os.path.join(work_root, "TrimmedStrings")
    stamp = os.path.join(work, "stamp")
    if not product_outputs(product):
        fail(f"no Localizable.strings in {product}: this phase must come after Copy Bundle Resources")

    sign = signature([with_data_keys, watch_course], files, sources, product)
    try:
        if open(stamp).read() == sign:
            print(f"trim_strings: {target} is up to date")
            return
    except OSError:
        pass

    catalog, keep, summary = plan()
    compiled = compile_trimmed(catalog, keep, work, os.environ.get("STRINGS_FILE_OUTPUT_ENCODING", "binary") == "binary")
    before, after = install(compiled, product)
    print(f"trim_strings: {summary}; Localizable files {before / 1e6:.1f} MB -> {after / 1e6:.1f} MB")
    with open(stamp, "w") as f:
        f.write(signature([with_data_keys, watch_course], files, sources, product))


if __name__ == "__main__":
    main(sys.argv[1:])
