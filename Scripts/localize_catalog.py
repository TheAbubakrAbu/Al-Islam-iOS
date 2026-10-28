#!/usr/bin/env python3
"""Keep Resources/Localizable.xcstrings in step with the code, and carry translations into it.

The compiler writes one `.stringsdata` file per Swift source (SWIFT_EMIT_LOC_STRINGS) listing every
localizable literal it found. Xcode's IDE folds those into the catalog on each build; `xcodebuild` from
the command line does not, so this script does the same fold, then adds what only a person can supply:
the translations, Arabic (`ar`, 2026-10-24) and Urdu (`ur`, 2026-10-26). They are written into the catalog,
which stays the one source of truth for translations (Xcode's catalog editor reads and writes the same file).

The Islam tab's articles are not translated yet (2026-10-25): a key whose every source is an article file
(ARTICLE_SOURCES) is listed in the catalog but never offered for translation, and reads English.

    # after a build with -derivedDataPath DD:
    ./Scripts/localize_catalog.py sync DD                  # add new keys, mark vanished ones stale
    ./Scripts/localize_catalog.py todo DD OUTDIR [--chunk 300]   # batches of keys still missing a translation
    ./Scripts/localize_catalog.py merge FILE.json [...]    # write translations in (validated)
    ./Scripts/localize_catalog.py validate FILE.json [...] # the same checks, writing nothing
    ./Scripts/localize_catalog.py check                    # every translated value against its key
    ./Scripts/localize_catalog.py manual KEYS.json         # data strings shown through .localizedDisplay
    ./Scripts/localize_catalog.py sibling DD [--add]       # Al-Adhan's or Al-Quran's build: keys only it has

`todo`, `merge`, `validate`, `check` and `sibling` take `--lang ar|ur` (default ar). An Urdu `todo` batch
carries each key's Arabic beside it (`arabic`), the reference for its sense and its Islamic terms.

Al-Adhan and Al-Quran carry a copy of this catalog (../sync_localization.py replaces theirs whole on every
sync), so their translations are made here too. `sibling` reads one of their builds and lists the keys their
code has that this catalog cannot translate; --add writes them in as manual keys (this app's own `sync` never
marks those stale), and `todo` then offers them with the rest.

A translation file is a JSON object {english key: translation}. A key holding exactly one integer argument
(%lld, %d, %ld, %u, %lu) may map to an object of CLDR plural forms instead: Arabic
{"one": ..., "two": ..., "few": ..., "many": ..., "other": ..., "zero": ...}, Urdu {"one": ..., "other": ...}
("zero" optional in both).
"""
import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(REPO, "Resources", "Localizable.xcstrings")
LANG = "ar"  # --lang (main)
LANGUAGES = ("ar", "ur")
TARGET_BUILDS = ("iPhone.build", "Widget.build", "Watch.build", "Complication.build")
# The Islam tab's articles (Faith & Proofs, the How-To Guides, Hadith & Its Sciences, the riwayat
# differences) stay English for now; the rest of that tab is translated. The article kit (ArticleDesign.swift)
# is shared with translated pages, so its few literals are translated; its String defaults stay English and
# translated pages pass their own.
ARTICLE_SOURCES = ("iPhone/Islam/Beliefs/", "iPhone/Islam/Proofs/", "iPhone/Islam/Fiqh/HowToGuides.swift",
                   "iPhone/Islam/Fiqh/SunnahView.swift", "iPhone/Islam/Fiqh/SunnahContent.swift",
                   "iPhone/Islam/Content/HadithSciencesViews.swift", "iPhone/Islam/Content/IslamArticles.swift",
                   "iPhone/Islam/Qiraat/RiwayatDifferencesView.swift")

# printf conversions as Foundation writes them into catalog keys: %@ %lld %d %f %.1f %1$@ %%.
# The space flag is left out on purpose: "80% coverage" is prose, not a "% c" conversion.
SPEC = re.compile(r"%(?:(\d+)\$)?[-+#0]*\d*(?:\.\d+)?(ll|l|h|hh|q|z|t|j)?([@dDiuUxXoOfFeEgGcsSpaA%])")
# App Shortcuts parameter tokens ("Open ${surah}") stay literal in every language.
PARAM_TOKEN = re.compile(r"\$\{[A-Za-z_]+\}")
INT_CONV = set("dDiuUxXoO")
EM_DASH = chr(0x2014)
# CLDR's plural categories per language (Urdu has only one and other), and "zero", which is optional.
PLURAL_FORMS = {"ar": ("zero", "one", "two", "few", "many", "other"), "ur": ("zero", "one", "other")}
REQUIRED_PLURALS = {"ar": ("one", "two", "few", "many", "other"), "ur": ("one", "other")}
# The forms that may say the number as a word (one ayah, two ayahs) instead of printing it.
WORD_FORMS = {"ar": ("zero", "one", "two"), "ur": ("zero", "one")}
# Latin words allowed to stay in a translated value.
LATIN_OK = {"al-islam", "al-adhan", "al-quran", "apple", "icloud", "carplay", "siri", "watch", "ios",
            "ipados", "macos", "watchos", "intelligence", "id", "gps", "pdf", "ai", "faceid", "touch",
            "airplay", "wi-fi", "wifi", "bluetooth", "imessage", "facetime", "safari", "url", "qr",
            "utc", "gmt", "am", "pm", "hafs", "warsh", "qalun", "app", "store", "tilawa", "quran.com",
            "github", "dynamic", "island", "pro", "max", "ipad", "iphone", "mac", "kfgqpc", "uthmani",
            "indopak", "sf", "rounded", "mp3", "ok", "csv"}


def load_catalog():
    with open(CATALOG, encoding="utf-8") as f:
        return json.load(f)


def save_catalog(cat):
    cat["strings"] = dict(sorted(cat["strings"].items(), key=lambda kv: kv[0]))
    # Written beside the catalog and moved over it, so a reader never sees half a file.
    tmp = CATALOG + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(cat, f, ensure_ascii=False, indent=2, separators=(",", " : "))
        f.write("\n")
    os.replace(tmp, CATALOG)


def specs(s):
    """The argument conversions in a format string, position-free, '%%' excluded."""
    out = []
    for m in SPEC.finditer(s):
        if m.group(3) == "%":
            continue
        conv = m.group(3)
        kind = "int" if conv in INT_CONV else "obj" if conv == "@" else "float" if conv in "fFeEgGaA" else conv
        out.append(kind)
    return sorted(out)


def plural_eligible(key):
    sp = specs(key)
    return len(sp) == 1 and sp[0] == "int"


def repo_of(path, cache={}):
    """The checkout a source file belongs to: the nearest folder above it holding an .xcodeproj."""
    d = os.path.dirname(path)
    if d not in cache:
        up = d
        while up != os.path.dirname(up) and not any(f.endswith(".xcodeproj") for f in os.listdir(up)):
            up = os.path.dirname(up)
        cache[d] = up if up != os.path.dirname(up) else REPO
    return cache[d]


def extracted(dd):
    """{key: set(source paths)} for the Localizable table, from a build's .stringsdata files. Paths are
    relative to the checkout that built them (this one, or a sibling's)."""
    keys = {}
    pattern = os.path.join(dd, "Build", "Intermediates.noindex", "**", "*.stringsdata")
    paths = [p for p in glob.glob(pattern, recursive=True) if any(t in p for t in TARGET_BUILDS)]
    # One configuration only, the one built most recently. A long-lived DerivedData keeps every
    # configuration ever built there, and a Release build from September beside today's Debug build
    # carried 35 keys the code no longer has (2026-10-26); the slices of one configuration are rebuilt
    # together, so the newest one speaks for the code as it is.
    def configuration(path):
        found = re.search(r"/(Debug|Release)-[^/]+/", path)
        return found.group(1) if found else ""
    newest = {}
    for path in paths:
        name = configuration(path)
        newest[name] = max(newest.get(name, 0), os.path.getmtime(path))
    if len(newest) > 1:
        keep = max(newest, key=newest.get)
        print(f"extracted: the {keep} build; ignoring older {', '.join(sorted(n for n in newest if n != keep))} slices")
        paths = [p for p in paths if configuration(p) == keep]
    # One slice per source file and target: the newest. The same configuration holds a slice per
    # PLATFORM too (Debug-iphoneos beside Debug-iphonesimulator, Debug-maccatalyst), and only the one
    # built last is the code as it is: a device build from earlier in the month revived 183 keys the
    # files no longer carry (2026-10-27). A file compiled into several targets keeps a slice per target,
    # since a shared file's `#if os(watchOS)` branches extract only in that target's compile.
    newest_slice = {}
    for path in paths:
        try:
            data = json.load(open(path, encoding="utf-8"))
        except (ValueError, OSError):
            continue
        source = data.get("source", "")
        # A moved or deleted file leaves its old .stringsdata behind in a long-lived DerivedData (2026-10-26:
        # a sync against build/DerivedData revived 462 dead keys from pre-reorganisation paths such as
        # iPhone/Settings/SettingsAdhanView.swift). Only a source that still exists speaks for the code.
        if os.path.isabs(source) and not os.path.exists(source):
            continue
        target = next((t for t in TARGET_BUILDS if t in path), "")
        stamp = os.path.getmtime(path)
        current = newest_slice.get((source, target))
        if current is None or stamp > current[0]:
            newest_slice[(source, target)] = (stamp, data)
    for (source, _), (_, data) in newest_slice.items():
        src = os.path.relpath(source, repo_of(source) if os.path.isabs(source) else REPO)
        for entry in data.get("tables", {}).get("Localizable", []):
            keys.setdefault(entry["key"], set()).add(src)
    return keys


def translatable(sources):
    return any(not s.startswith(ARTICLE_SOURCES) for s in sources)


def has_translation(entry, lang=None):
    return (lang or LANG) in entry.get("localizations", {})


def value_of(entry, lang):
    """One language's value as a string, a plural as "form: value" lines; None when it has none."""
    loc = entry.get("localizations", {}).get(lang)
    if not loc:
        return None
    if "stringUnit" in loc:
        return loc["stringUnit"]["value"]
    forms = loc.get("variations", {}).get("plural", {})
    return "\n".join(f"{form}: {v['stringUnit']['value']}" for form, v in forms.items())


def cmd_sync(dd):
    cat = load_catalog()
    keys = extracted(dd)
    if not keys:
        sys.exit(f"no .stringsdata under {dd}: build with -derivedDataPath first")
    strings = cat["strings"]
    added = stale = revived = 0
    for key in keys:
        entry = strings.get(key)
        if entry is None:
            strings[key] = {}
            added += 1
        elif entry.get("extractionState") == "stale":
            entry.pop("extractionState")
            revived += 1
    for key, entry in strings.items():
        if key not in keys and entry.get("extractionState") not in ("manual", "stale"):
            entry["extractionState"] = "stale"
            stale += 1
    save_catalog(cat)
    print(f"sync: {len(keys)} extracted, {added} added, {revived} revived, {stale} marked stale")


def cmd_manual(path):
    cat = load_catalog()
    added = 0
    for key in json.load(open(path, encoding="utf-8")):
        entry = cat["strings"].get(key)
        if entry is None:
            cat["strings"][key] = {"extractionState": "manual"}
            added += 1
        elif entry.get("extractionState") == "stale":
            # Gone from the code but still shown as data: keep it.
            entry["extractionState"] = "manual"
        # An entry the compiler extracts (no extractionState) stays as it is.
    save_catalog(cat)
    print(f"manual: {added} added")


def cmd_todo(dd, outdir, chunk):
    cat = load_catalog()
    keys = extracted(dd)
    todo = []
    for key, entry in cat["strings"].items():
        if has_translation(entry) or entry.get("extractionState") == "stale" or not key.strip():
            continue
        if entry.get("shouldTranslate") is False:  # an address, a name: marked in Xcode's catalog editor
            continue
        sources = keys.get(key)
        if sources is not None and not translatable(sources):
            continue
        # Nothing to translate in a bare argument ("%lld") or a symbol.
        if not re.search(r"[A-Za-z]", SPEC.sub("", key)):
            continue
        item = {"key": key, "files": sorted(sources or ["(data shown via .localizedDisplay)"]),
                "plural": plural_eligible(key)}
        if english_of(entry) is not None:
            item["english"] = english_of(entry)
        if LANG != "ar" and has_translation(entry, "ar"):
            item["arabic"] = value_of(entry, "ar")
        todo.append(item)
    # Grouped by first source file so a batch reads as whole screens.
    todo.sort(key=lambda t: (t["files"][0], t["key"]))
    os.makedirs(outdir, exist_ok=True)
    n = 0
    for i in range(0, len(todo), chunk):
        n += 1
        with open(os.path.join(outdir, f"todo_{n:03d}.json"), "w", encoding="utf-8") as f:
            json.dump(todo[i:i + chunk], f, ensure_ascii=False, indent=1)
    print(f"todo [{LANG}]: {len(todo)} keys in {n} files under {outdir}")


def cmd_sibling(dd, add):
    cat = load_catalog()
    keys = extracted(dd)
    if not keys:
        sys.exit(f"no .stringsdata under {dd}: build the sibling with -derivedDataPath first")
    strings = cat["strings"]
    have = untranslated = articles = 0
    missing, revive = [], []
    for key, sources in sorted(keys.items()):
        if not translatable(sources):
            articles += 1
            continue
        if not re.search(r"[A-Za-z]", SPEC.sub("", key)):
            continue
        entry = strings.get(key)
        if entry is None:
            missing.append((key, sorted(sources)[0]))
        elif has_translation(entry):
            have += 1
        else:
            untranslated += 1
            if entry.get("extractionState") == "stale":
                revive.append(key)  # gone from this app's code: `todo` skips it unless it turns manual
    print(f"sibling [{LANG}]: {len(keys)} keys in that build; {have} are translated here, {untranslated} are "
          f"here without a translation yet ({len(revive)} of them stale), {len(missing)} are missing; "
          f"{articles} article-only skipped")
    for key, src in missing[:40]:
        print(f"  missing  {key!r}  ({src})")
    if len(missing) > 40:
        print(f"  ... and {len(missing) - 40} more")
    if add and (missing or revive):
        for key, _ in missing:
            strings[key] = {"extractionState": "manual"}
        for key in revive:
            strings[key]["extractionState"] = "manual"
        save_catalog(cat)
        print(f"sibling: {len(missing)} added and {len(revive)} kept as manual keys; `todo` offers them now")


def english_of(entry):
    """A dotted key's English (`weather.clear`, `about.app`: `String(localized: "about.app", defaultValue:
    "About \\(name)")`), kept as the catalog's `en` unit; None for an ordinary key, which IS its English."""
    return entry.get("localizations", {}).get("en", {}).get("stringUnit", {}).get("value")


def problems(key, value, may_drop_count=False, english=None, arabic=None):
    """What is wrong with one translated value (a string), as a list of messages. `may_drop_count`: a
    plural form that can say the number as a word (one ayah, two ayahs) instead of printing it (WORD_FORMS).
    `english`: the English a dotted key stands for (see `english_of`); the placeholders, `${...}` tokens
    and Latin words are checked against it, since the key itself ("about.app") carries none of them.
    `arabic`: the key's Arabic, for an Urdu value (`urdu_problems`)."""
    out = urdu_problems(key, value, english, arabic) if LANG == "ur" else []
    reference = english if english is not None else key
    if not value.strip():
        out.append("empty")
    if EM_DASH in value or "&mdash;" in value:
        out.append("em dash")
    if specs(value) != specs(reference) and not (may_drop_count and not specs(value)):
        out.append(f"placeholders {specs(value)} != key {specs(reference)}")
    if reference.count("%%") > value.count("%%") + value.count("\u066A"):
        out.append("a literal %% is missing")
    if sorted(PARAM_TOKEN.findall(value)) != sorted(PARAM_TOKEN.findall(reference)):
        out.append("${...} parameter tokens differ from the key")
    quoted = set(quoted_latin(value))
    key_words = {w.lower() for w in re.findall(r"[A-Za-z]+", reference)}
    for word in re.findall(r"[A-Za-z][A-Za-z.\-]*", PARAM_TOKEN.sub(" ", SPEC.sub(" ", value))):
        w = word.lower().strip(".-")
        if not w or w in LATIN_OK:
            continue
        # The Arabic lessons compare a letter with an English word ("like the b in “book”"): a Latin
        # word the key has too may stay when it is a letter or two, or quoted in the Arabic.
        if w in key_words and (len(w) <= 2 or w in quoted):
            continue
        out.append(f"Latin word {word!r}")
        break
    return out


# Urdu writes its own forms of three letters: ی (U+06CC) for ي, ک (U+06A9) for ك, ہ (U+06C1) or ھ (U+06BE)
# for ه, and ۃ (U+06C3) or ہ for ة, ی for ى. An Arabic form is right only in quoted Arabic: an ayah between
# ﴿ ﴾, a vocalised word, or a term the key or its Arabic spells the same way («الحروف الهجائية»).
ARABIC_FORMS = re.compile("[\u064A\u0643\u0647\u0629\u0649]")
URDU_ONLY = re.compile("[\u06CC\u06A9\u06C1\u06BE\u06C3\u06D2\u0679\u0688\u0691\u06BA]")
HARAKAT = re.compile("[\u064B-\u0652\u0670\u06E1]")
ARABIC_WORD = re.compile("[\u0621-\u064A\u0660-\u0669\u066E-\u06D3\u06D5-\u06FF\u064B-\u0652\u0670\u0640]+")
AYAH = re.compile("\uFD3F[^\uFD3E]*\uFD3E")
EASTERN_DIGIT = re.compile("[\u0660-\u0669\u06F0-\u06F9]")


def bare(word):
    return re.sub("[\u064B-\u0652\u0670\u06E1\u0640]", "", word)


def urdu_problems(key, value, english, arabic):
    """Urdu's own checks: its letter forms, Western digits (Urdu in Pakistan writes 0-9; `localizedDigits`
    turns them into ۰-۹ for Urdu in India), and ۔ to end a sentence."""
    out = []
    reference = english if english is not None else key
    text = AYAH.sub(" ", value)
    allowed = {bare(w) for w in ARABIC_WORD.findall(reference + " " + (arabic or ""))}
    for word in ARABIC_WORD.findall(text):
        if not ARABIC_FORMS.search(word):
            continue
        if URDU_ONLY.search(word):
            out.append(f"Arabic letter form in the Urdu word {word!r}")
            break
        if HARAKAT.search(word) or len(bare(word)) <= 1 or bare(word) in allowed:
            continue
        out.append(f"Arabic letter form in {word!r} (Urdu writes \u06CC \u06A9 \u06C1)")
        break
    if EASTERN_DIGIT.search(SPEC.sub("", text)) and not EASTERN_DIGIT.search(reference):
        out.append("Eastern digits: write 0-9 in Urdu")
    if re.search("[\u0621-\u06FF]\\.(\\s|$)", text):
        out.append("a Latin full stop after Urdu: write \u06D4")
    return out


QUOTED = re.compile(r"[\u201C\u00AB\"]([^\u201D\u00BB\"]{1,60})[\u201D\u00BB\"]")


def quoted_latin(value):
    """Latin words that sit inside quotation marks in an Arabic value."""
    for m in QUOTED.finditer(value):
        for w in re.findall(r"[A-Za-z]+", m.group(1)):
            yield w.lower()


RLM = "\u200F"
ARABIC_LETTER = re.compile(r"[\u0600-\u06FF]")


def directional(value):
    """A value whose only Arabic-script letters sit inside its arguments starts with a right-to-left mark:
    `String(localized:)` isolates every argument, so with nothing strong outside them the line fell back to
    left to right and its parts swapped ("%1$@/%2$lld  %3$@" put the percent first). A middle dot beside
    Arabic-Indic digits (or Urdu's ۰) reads as a zero, so the separator becomes a bullet, and in Arabic a
    literal percent becomes the Arabic percent sign (Urdu keeps %)."""
    value = value.replace(" \u00B7 ", " \u2022 ")
    # Arabic writes its own percent sign beside its digits (a literal percent is "%%" in a format string).
    if LANG == "ar":
        value = value.replace("%%", "\u066A")
    if specs(value) and not value.startswith(RLM) and not ARABIC_LETTER.search(SPEC.sub("", value)):
        value = RLM + value
    return value


def unit(value):
    return {"stringUnit": {"state": "translated", "value": directional(value)}}


def cmd_merge(paths, dry_run=False):
    cat = load_catalog()
    strings = cat["strings"]
    written = skipped = 0
    bad = []
    for path in paths:
        for key, value in json.load(open(path, encoding="utf-8")).items():
            if key not in strings:
                bad.append((path, key, "key not in catalog"))
                continue
            if isinstance(value, dict):
                if not plural_eligible(key):
                    bad.append((path, key, "plural forms on a key without exactly one integer"))
                    continue
                missing = [f for f in REQUIRED_PLURALS[LANG] if not value.get(f)]
                errs = [f"{f}: {p}" for f, v in value.items() if f in PLURAL_FORMS[LANG]
                        for p in problems(key, v, may_drop_count=f in WORD_FORMS[LANG],
                                          english=english_of(strings[key]), arabic=value_of(strings[key], "ar"))]
                extra = [f for f in value if f not in PLURAL_FORMS[LANG]]
                if missing or errs or extra:
                    bad.append((path, key, f"missing {missing} extra {extra} {errs}"))
                    continue
                loc = {"variations": {"plural": {f: unit(value[f]) for f in PLURAL_FORMS[LANG] if value.get(f)}}}
            else:
                errs = problems(key, value, english=english_of(strings[key]), arabic=value_of(strings[key], "ar"))
                if errs:
                    bad.append((path, key, "; ".join(errs)))
                    continue
                loc = unit(value)
            strings[key].setdefault("localizations", {})[LANG] = loc
            written += 1
    if not dry_run:
        save_catalog(cat)
    for path, key, why in bad:
        print(f"REJECTED {os.path.basename(path)}: {key!r}: {why}")
    print(f"{'validate' if dry_run else 'merge'}: {written} {'valid' if dry_run else 'written'}, {len(bad)} rejected")
    return 1 if bad else 0


def cmd_check():
    cat = load_catalog()
    bad = 0
    for key, entry in cat["strings"].items():
        loc = entry.get("localizations", {}).get(LANG)
        if not loc:
            continue
        values = [("", loc["stringUnit"]["value"])] if "stringUnit" in loc else \
            [(f, v["stringUnit"]["value"]) for f, v in loc.get("variations", {}).get("plural", {}).items()]
        for form, v in values:
            for p in problems(key, v, may_drop_count=form in WORD_FORMS[LANG], english=english_of(entry),
                              arabic=value_of(entry, "ar")):
                print(f"{key!r}: {p}")
                bad += 1
    total = sum(1 for e in cat["strings"].values() if has_translation(e))
    print(f"check [{LANG}]: {total} entries, {bad} problems")
    return 1 if bad else 0


def main(argv):
    global LANG
    argv = list(argv)
    if "--lang" in argv:
        i = argv.index("--lang")
        LANG = argv[i + 1] if i + 1 < len(argv) else ""
        del argv[i:i + 2]
        if LANG not in LANGUAGES:
            sys.exit(f"--lang takes one of {', '.join(LANGUAGES)}")
    if len(argv) < 2:
        sys.exit(__doc__)
    cmd, args = argv[1], argv[2:]
    if cmd == "sync":
        cmd_sync(args[0])
    elif cmd == "todo":
        chunk = int(args[args.index("--chunk") + 1]) if "--chunk" in args else 300
        cmd_todo(args[0], args[1], chunk)
    elif cmd == "merge":
        sys.exit(cmd_merge(args))
    elif cmd == "validate":
        sys.exit(cmd_merge(args, dry_run=True))
    elif cmd == "check":
        sys.exit(cmd_check())
    elif cmd == "manual":
        cmd_manual(args[0])
    elif cmd == "sibling":
        cmd_sibling(args[0], "--add" in args)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
