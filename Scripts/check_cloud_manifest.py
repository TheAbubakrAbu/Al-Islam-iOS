#!/usr/bin/env python3
"""Every saved key must be a decision: content, preference, or device-only.

The iCloud backup (docs/iCloud Sync Guide.md) carries an explicit manifest instead of "everything
in UserDefaults", because restoring a device-only key onto another phone (a migration flag, a
notification signature, a cached location) breaks things quietly. The price of an explicit list is
that a NEW key is silently left out of every backup, and a new CONTENT key is also silently deleted
by "Reset All Settings". This script is what makes that loud.

    Scripts/check_cloud_manifest.py            exit 1 on an unclassified key
    Scripts/check_cloud_manifest.py --list     print every key with its class
    Scripts/check_cloud_manifest.py --unclassified-swift
                                               print the unclassified keys as Swift string
                                               literals, ready to paste into a list

It reads key names out of the sources four ways: @AppStorage("key"), forKey: "key", `let
somethingKey = "key"` / `let someFlag = "key"` constants, and `someKey: "key"` arguments. A key
declared any other way, or built from an interpolated string, is invisible here; the app's DEBUG
launch argument -cloudKeyAudit checks the LIVE defaults domain for those (it found fourteen the
first time it ran).

Since round two (guide, section 12) it also checks the lists the three bulk paths share:
- every key the watch syncs (`Settings.watchSyncedAppStorageKeys`) is a preference, never content
  or device-only (the manifest's preference class includes the watch list by construction);
- every app-group preference in the table (`Settings.appGroupPreferences`) is known here, with
  `travelingMode` the one that is not backed up;
- the content categories (`ContentCategory.all`) cover every content key and every backed-up file
  exactly once, and name nothing outside them.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE_DIRS = ["iPhone", "Apple Watch", "Widget", "Complication"]
MANIFEST = os.path.join(ROOT, "iPhone", "Settings", "CloudManifest.swift")
SETTINGS = os.path.join(ROOT, "iPhone", "Settings", "Settings.swift")
WATCH = os.path.join(ROOT, "iPhone", "Settings", "WatchConnectivity.swift")
CATEGORIES = os.path.join(ROOT, "iPhone", "Settings", "ContentCategories.swift")

APPSTORAGE = re.compile(r'@AppStorage\(\s*"([^"\\]+)"')
FORKEY = re.compile(r'forKey:\s*"([^"\\]+)"')
CONSTANT = re.compile(r'\blet\s+\w*(?:[Kk]ey|[Ff]lag)\w*\s*(?::\s*String\s*)?=\s*"([^"\\]+)"')
# A key handed over as an argument: `homeCacheKey: "masjidLocatorHomeCacheData"`.
ARGUMENT = re.compile(r'\b(?!forInfoDictionaryKey\b)\w*Key:\s*"([^"\\]+)"')

# String constants whose name says "key" and that are not UserDefaults keys at all: notification
# userInfo keys, cache keys, the watch payload's field name, search keywords.
NOT_DEFAULTS_KEYS = {
    "sunnahTarget", "sunnahPreset", "intendedFireDate", "watchActivityDays",
    "tips tricks hidden features gestures shortcuts tutorial tour how to help discover easy to miss did you know",
}


def source_keys():
    found = {}
    for top in SOURCE_DIRS:
        for folder, _, files in os.walk(os.path.join(ROOT, top)):
            for name in files:
                if not name.endswith(".swift"):
                    continue
                path = os.path.join(folder, name)
                if os.path.abspath(path) == os.path.abspath(MANIFEST):
                    continue
                text = open(path, encoding="utf-8", errors="replace").read()
                for pattern in (APPSTORAGE, FORKEY, CONSTANT, ARGUMENT):
                    for match in pattern.finditer(text):
                        key = match.group(1)
                        # No saved key here has a space in it; search keywords and messages do.
                        if key in NOT_DEFAULTS_KEYS or " " in key:
                            continue
                        found.setdefault(key, set()).add(name)
    return found


def swift_string_array(text, declaration):
    """The string literals of `static let <declaration> ... = [ ... ]` (comments skipped)."""
    start = text.find(declaration)
    if start < 0:
        sys.exit(f"cannot find `{declaration}`")
    open_bracket = text.index("= ", start)
    open_bracket = text.index("[", open_bracket)
    depth, index = 0, open_bracket
    while True:
        char = text[index]
        if char == "[":
            depth += 1
        elif char == "]":
            depth -= 1
            if depth == 0:
                break
        index += 1
    body = text[open_bracket:index]
    body = re.sub(r"//[^\n]*", "", body)
    return re.findall(r'"([^"\\]+)"', body)


PRAYER_OFFSET_KEYS = ["offsetFajr", "offsetSunrise", "offsetDhuhr", "offsetAsr", "offsetMaghrib", "offsetIsha"]


def app_group_preferences(settings):
    """The rows of `Settings.appGroupPreferences`: key -> backed up (True/False)."""
    start = settings.find("static let appGroupPreferences: [AppGroupPreference] = [")
    if start < 0:
        sys.exit("cannot find `static let appGroupPreferences`")
    end = settings.index("\n    ]", start)
    rows = re.findall(r'key:\s*"([^"]+)",\s*backedUp:\s*(true|false)', settings[start:end])
    if not rows:
        sys.exit("no rows found in `appGroupPreferences`")
    return {key: backed == "true" for key, backed in rows}


def manifest_classes():
    manifest = open(MANIFEST, encoding="utf-8").read()
    settings = open(SETTINGS, encoding="utf-8").read()
    watch = open(WATCH, encoding="utf-8").read()
    classes = {}
    for key in swift_string_array(settings, "static let contentStorageKeys"):
        classes[key] = "content"
    for declaration, label in (
        ("static let listedPreferenceKeys", "preference"),
        ("static let deviceOnlyKeys", "device-only"),
    ):
        for key in swift_string_array(manifest, declaration):
            if key in classes and classes[key] != label:
                sys.exit(f"`{key}` is listed twice: {classes[key]} and {label}")
            classes[key] = label
    # The watch list is part of the preference class by construction (CloudManifest.preferenceKeys
    # unions it), so a watch-synced key that is content or device-only is a contradiction.
    watch_keys = PRAYER_OFFSET_KEYS + swift_string_array(watch, "static let watchSyncedAppStorageKeys")
    for key in watch_keys:
        if classes.get(key, "preference") != "preference":
            sys.exit(f"`{key}` is synced to the watch but classified {classes[key]}: a watch-synced key must be a preference")
        classes[key] = "preference"
    # The app-group table: the backed-up rows are the manifest's app-group keys; travelingMode is
    # location-derived and device-only.
    for key, backed in app_group_preferences(settings).items():
        label = "preference (app group)" if backed else "device-only"
        if key in classes and classes[key] != label:
            sys.exit(f"`{key}` is in the app-group table as {label} but listed as {classes[key]}")
        classes[key] = label
    prefixes = swift_string_array(manifest, "static let deviceOnlyPrefixes")
    files = swift_string_array(settings, "static let contentDocumentFiles")
    return classes, prefixes, files


def check_categories(classes, files):
    """Every content key and file in exactly one category; no category names anything else."""
    text = open(CATEGORIES, encoding="utf-8").read()
    start = text.find("static let all: [ContentCategory] = [")
    if start < 0:
        sys.exit("cannot find `ContentCategory.all`")
    end = text.index("\n    ]\n", start)
    body = text[start:end]
    seen_keys, seen_files, problems = {}, {}, []
    for match in re.finditer(r'id:\s*"([^"]+)".*?keys:\s*\[(.*?)\],\s*files:\s*\[(.*?)\]', body, re.S):
        category, keys, names = match.group(1), re.findall(r'"([^"]+)"', match.group(2)), re.findall(r'"([^"]+)"', match.group(3))
        for key in keys:
            if key in seen_keys:
                problems.append(f"`{key}` is in two categories: {seen_keys[key]} and {category}")
            seen_keys[key] = category
            if classes.get(key) != "content":
                problems.append(f"`{key}` (category {category}) is not a content key")
        for name in names:
            if name in seen_files:
                problems.append(f"`{name}` is in two categories: {seen_files[name]} and {category}")
            seen_files[name] = category
            if name not in files:
                problems.append(f"`{name}` (category {category}) is not a backed-up file")
    for key, label in classes.items():
        if label == "content" and key not in seen_keys:
            problems.append(f"content key `{key}` is in no category (ContentCategories.swift)")
    for name in files:
        if name not in seen_files:
            problems.append(f"backed-up file `{name}` is in no category (ContentCategories.swift)")
    if not seen_keys:
        problems.append("no categories parsed from ContentCategories.swift")
    return problems, len(seen_keys), len(seen_files)


def main():
    keys = source_keys()
    classes, prefixes, files = manifest_classes()

    def class_of(key):
        if key in classes:
            return classes[key]
        if any(key.startswith(prefix) for prefix in prefixes):
            return "device-only"
        return None

    unclassified = sorted(key for key in keys if class_of(key) is None)
    if "--list" in sys.argv:
        for key in sorted(keys):
            print(f"{class_of(key) or 'UNCLASSIFIED':24s} {key:44s} {', '.join(sorted(keys[key])[:3])}")
        return 0
    if "--unclassified-swift" in sys.argv:
        line = "        "
        for key in unclassified:
            literal = f'"{key}", '
            if len(line) + len(literal) > 110:
                print(line.rstrip())
                line = "        "
            line += literal
        if line.strip():
            print(line.rstrip())
        return 0

    stale = sorted(key for key in classes if key not in keys)
    counts = {}
    for key in keys:
        counts[class_of(key) or "UNCLASSIFIED"] = counts.get(class_of(key) or "UNCLASSIFIED", 0) + 1
    print(f"{len(keys)} saved keys in the sources: " + ", ".join(f"{n} {label}" for label, n in sorted(counts.items())))
    if stale:
        print(f"note: {len(stale)} manifest keys no longer appear in the sources (dynamic, or retired): " + ", ".join(stale))
    if unclassified:
        print("\nUNCLASSIFIED (add each to a list in CloudManifest.swift, or to Settings.contentStorageKeys):")
        for key in unclassified:
            print(f"  {key:44s} {', '.join(sorted(keys[key])[:3])}")
        return 1
    problems, category_keys, category_files = check_categories(classes, files)
    if problems:
        print("\nCATEGORIES:")
        for problem in problems:
            print(f"  {problem}")
        return 1
    print(f"every key is classified; the categories cover all {category_keys} content keys and {category_files} files exactly once")
    return 0


sys.exit(main())
