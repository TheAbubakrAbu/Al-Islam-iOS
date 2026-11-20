#!/usr/bin/env python3
"""Keep Resources/Localizable.xcstrings in step with the code, and carry translations into it.

The compiler writes one `.stringsdata` file per Swift source (SWIFT_EMIT_LOC_STRINGS) listing every
localizable literal it found. Xcode's IDE folds those into the catalog on each build; `xcodebuild` from
the command line does not, so this script does the same fold, then adds what only a person can supply:
the translations, Arabic (`ar`, 2026-10-24), Urdu (`ur`, 2026-10-26), Indonesian, Malay and Turkish
(`id`, `ms`, `tr`, 2026-11-19), French, Bangla and Russian (`fr`, `bn`, `ru`, 2026-11-20), and Hindi, German
and Spanish (`hi`, `de`, `es`, 2026-11-20). They are written into the catalog,
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

`todo`, `merge`, `validate`, `check` and `sibling` take `--lang ar|ur|id|ms|tr|fr|bn|ru|hi|de|es|ml|ta|nl` (default ar). An Urdu
`todo` batch carries each key's Arabic beside it (`arabic`), the reference for its sense and its Islamic terms;
a batch in any other language carries it for short keys only, where the sense is in doubt. For any
language but Arabic, `todo DD OUTDIR --like-ar` offers exactly the keys Arabic has (a new language's first
pass: Arabic's coverage already leaves out the article-only and symbol-only keys; `-` for DD when there is no
build, at the cost of each key's file names). `--words N` cuts batches by English word count, not keys.

Al-Adhan and Al-Quran carry a copy of this catalog (../sync_localization.py replaces theirs whole on every
sync), so their translations are made here too. `sibling` reads one of their builds and lists the keys their
code has that this catalog cannot translate; --add writes them in as manual keys (this app's own `sync` never
marks those stale), and `todo` then offers them with the rest.

A translation file is a JSON object {english key: translation}. A key holding exactly one integer argument
(%lld, %d, %ld, %u, %lu) may map to an object of CLDR plural forms instead: Arabic
{"one": ..., "two": ..., "few": ..., "many": ..., "other": ..., "zero": ...}, Urdu and Turkish
{"one": ..., "other": ...}, French and Spanish {"one": ..., "other": ...} ("many" optional: a round million),
German, Hindi, Dutch, Malayalam and Tamil {"one": ..., "other": ...}, Russian {"one": ..., "few": ..., "many": ..., "other": ...}, Indonesian, Malay and Bangla {"other": ...}
("zero" optional in all). Indonesian, Malay and Bangla never inflect a noun for its number, so a plain string
is the usual answer there; outside Arabic and Urdu, forms that are all the same (or {"other": x} alone) are
written as one plain string.
"""
import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(REPO, "Resources", "Localizable.xcstrings")
LANG = "ar"  # --lang (main)
LANGUAGES = ("ar", "ur", "id", "ms", "tr", "fr", "bn", "ru", "hi", "de", "es", "ml", "ta", "nl")
# Written in the Latin script, left to right: their own validator (`latin_problems`) and no direction marks.
LATIN_LANGUAGES = ("id", "ms", "tr", "fr", "de", "es", "nl")
# Written right to left in the Arabic script. Every other language reads left to right, so its values need no
# direction marks, and its checks look for English left in it rather than for any Latin word (`problems`).
ARABIC_SCRIPT = ("ar", "ur")
# The letters of a language not written in the Latin script: a value with none of them is untranslated.
NATIVE_LETTER = {"bn": re.compile("[\u0980-\u09FF]"), "ru": re.compile("[\u0400-\u04FF]"),
                 "hi": re.compile("[\u0900-\u097F]"), "ml": re.compile("[\u0D00-\u0D7F]"),
                 "ta": re.compile("[\u0B80-\u0BFF]")}
SCRIPT_NAME = {"bn": "Bengali", "ru": "Cyrillic", "hi": "Devanagari", "ml": "Malayalam", "ta": "Tamil"}
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
PLURAL_FORMS = {"ar": ("zero", "one", "two", "few", "many", "other"), "ur": ("zero", "one", "other"),
                "id": ("zero", "other"), "ms": ("zero", "other"), "tr": ("zero", "one", "other"),
                "fr": ("zero", "one", "many", "other"), "bn": ("zero", "one", "other"),
                "ru": ("zero", "one", "few", "many", "other"), "hi": ("zero", "one", "other"),
                "de": ("zero", "one", "other"), "es": ("zero", "one", "many", "other"),
                "ml": ("zero", "one", "other"), "ta": ("zero", "one", "other"), "nl": ("zero", "one", "other")}
REQUIRED_PLURALS = {"ar": ("one", "two", "few", "many", "other"), "ur": ("one", "other"),
                    "id": ("other",), "ms": ("other",), "tr": ("one", "other"),
                    "fr": ("one", "other"), "bn": ("other",), "ru": ("one", "few", "many", "other"),
                    "hi": ("one", "other"), "de": ("one", "other"), "es": ("one", "other"),
                    "ml": ("one", "other"), "ta": ("one", "other"), "nl": ("one", "other")}
# The forms that may say the number as a word (one ayah, two ayahs) instead of printing it.
# French and Hindi "one" covers 0 and 1, Russian "one" 21 and 31 too, Bangla's 0 and 1: none of them can be a
# word. German, Spanish, Dutch, Malayalam and Tamil "one" is 1 alone, but they keep the digit too, as every
# left-to-right language does.
WORD_FORMS = {"ar": ("zero", "one", "two"), "ur": ("zero", "one"), "id": ("zero",), "ms": ("zero",),
              "tr": ("zero", "one"), "fr": ("zero",), "bn": ("zero",), "ru": ("zero",), "hi": ("zero",),
              "de": ("zero",), "es": ("zero",), "ml": ("zero",), "ta": ("zero",), "nl": ("zero",)}
# A Latin name joined by hyphens, dots or slashes: a URL, a domain, a repository (`problems`).
IDENTIFIER = re.compile("[A-Za-z0-9]+(?:[-\u2011./][A-Za-z0-9]+)+")
# Latin words allowed to stay in a translated value.
LATIN_OK = {"al-islam", "al-adhan", "al-quran", "apple", "icloud", "carplay", "siri", "watch", "ios",
            "ipados", "macos", "watchos", "intelligence", "id", "gps", "pdf", "ai", "faceid", "touch",
            "airplay", "wi-fi", "wifi", "bluetooth", "imessage", "facetime", "safari", "url", "qr",
            "utc", "gmt", "am", "pm", "hafs", "warsh", "qalun", "app", "store", "tilawa", "quran.com",
            "github", "dynamic", "island", "pro", "max", "ipad", "iphone", "mac", "kfgqpc", "uthmani",
            "indopak", "sf", "rounded", "mp3", "ok", "csv",
            # The crisis help lines (Ask AI): names and a domain, the same in every language.
            "findahelpline.com", "tele-manas", "samaritans", "lifeline"}


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


def ordered_specs(s):
    """The argument kinds in the order they appear, or None when the string numbers its arguments (%2$@):
    unnumbered arguments are taken in order, so a translation that moves a %lld before a %@ swaps them."""
    out = []
    for m in SPEC.finditer(s):
        if m.group(3) == "%":
            continue
        if m.group(1):
            return None
        conv = m.group(3)
        out.append("int" if conv in INT_CONV else "obj" if conv == "@" else "float" if conv in "fFeEgGaA" else conv)
    return out


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


def cmd_todo(dd, outdir, chunk, words=0, like_arabic=False):
    cat = load_catalog()
    # --like-ar (or "-", no build to read): offer exactly what Arabic has, for a language starting out.
    # Arabic's coverage already skips the article-only and symbol-only keys. A build, when given, still
    # names each key's files, the context a translator reads a short key's sense from.
    like_arabic = like_arabic or dd == "-"
    if like_arabic and LANG == "ar":
        sys.exit("todo --like-ar: Arabic is the reference; pass its DerivedData")
    keys = {} if dd == "-" else extracted(dd)
    todo = []
    for key, entry in cat["strings"].items():
        if has_translation(entry) or entry.get("extractionState") == "stale" or not key.strip():
            continue
        if like_arabic and not has_translation(entry, "ar"):
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
        # The Arabic shows which sense a short key has ("Light": a theme or a light letter). Urdu takes it
        # for every key (its Islamic terms follow the Arabic); the other languages only for short keys.
        if LANG != "ar" and has_translation(entry, "ar") and (LANG == "ur" or word_count(key) <= 6):
            item["arabic"] = value_of(entry, "ar")
        todo.append(item)
    # Grouped by first source file so a batch reads as whole screens.
    todo.sort(key=lambda t: (t["files"][0], t["key"]))
    os.makedirs(outdir, exist_ok=True)
    batches, batch, size = [], [], 0
    for item in todo:
        weight = word_count(item.get("english", item["key"])) if words else 1
        if batch and size + weight > (words or chunk):
            batches.append(batch)
            batch, size = [], 0
        batch.append(item)
        size += weight
    if batch:
        batches.append(batch)
    for n, batch in enumerate(batches, 1):
        with open(os.path.join(outdir, f"todo_{n:03d}.json"), "w", encoding="utf-8") as f:
            json.dump(batch, f, ensure_ascii=False, indent=1)
    total = sum(word_count(t.get("english", t["key"])) for t in todo)
    print(f"todo [{LANG}]: {len(todo)} keys ({total} English words) in {len(batches)} files under {outdir}")


def word_count(text):
    return len(re.findall(r"[A-Za-z']+", SPEC.sub(" ", text)))


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
    if LANG not in ARABIC_SCRIPT:
        out += latin_problems(reference, value)
    if not value.strip():
        out.append("empty")
    if english is not None and value == key and key != english:
        out.append("the value is the dotted key itself; translate its English")
    if EM_DASH in value or "&mdash;" in value:
        out.append("em dash")
    if specs(value) != specs(reference) and not (may_drop_count and not specs(value)):
        out.append(f"placeholders {specs(value)} != key {specs(reference)}")
    elif ordered_specs(value) is not None and ordered_specs(reference) is not None \
            and ordered_specs(value) != ordered_specs(reference) and specs(value):
        out.append("arguments of different types change order: number them all (%1$@, %2$lld)")
    if reference.count("%%") > value.count("%%") + value.count("\u066A"):
        out.append("a literal %% is missing")
    if "%" in SPEC.sub("", value) and "%" not in SPEC.sub("", reference):
        out.append("a lone % the key does not have: a format string writes a literal percent as %% (or write it out)")
    if sorted(PARAM_TOKEN.findall(value)) != sorted(PARAM_TOKEN.findall(reference)):
        out.append("${...} parameter tokens differ from the key")
    if LANG in LATIN_LANGUAGES:
        return out  # every word is Latin here: `latin_problems` looks for English instead
    if LANG in NATIVE_LETTER:
        return out + script_problems(reference, value)
    quoted = set(quoted_latin(value))
    key_words = {w.lower() for w in re.findall(r"[A-Za-z]+", reference)}
    scanned = PARAM_TOKEN.sub(" ", SPEC.sub(" ", value))
    # A URL or a repository name (opendatacommons.org/licenses/odbl, Hadith-JSON-Engine) is a name, not a
    # word to translate: it may stay when the key spells it the same way. A non-breaking hyphen (U+2011),
    # which keeps such a name on one line inside right-to-left text, counts as a hyphen.
    names = {n.replace("\u2011", "-") for n in IDENTIFIER.findall(reference)}
    scanned = IDENTIFIER.sub(lambda m: " " if m.group(0).replace("\u2011", "-") in names else m.group(0), scanned)
    for word in re.findall(r"[A-Za-z][A-Za-z.\-]*", scanned):
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


# English function words: none of them is a word in Indonesian, Malay or Turkish, so one left in a value
# is English that was not translated. Left out on purpose, as words of those languages: "on" (Turkish ten),
# "an" (a moment), "at" (a horse), "can" (a soul), "it", "not" (a note), "as", "do", "in", "a".
ENGLISH_WORDS = {"the", "and", "of", "your", "you", "with", "this", "that", "from", "for", "will", "are",
                 "is", "to", "when", "which", "what", "into", "each", "every", "only", "after", "before",
                 "these", "those", "would", "should", "their", "they", "them", "been", "were", "was", "have",
                 "has", "there", "here", "about", "than", "then", "also", "its", "our", "his", "her", "who",
                 "how", "why", "where", "between", "without", "while", "over", "under", "shows", "show",
                 "tap", "turn", "choose", "opens", "reads"}
# Words of these languages that are spelled like an English one on the list: Turkish "her" (every: Apple's
# "Her Zaman"), "his" (a feeling) and "has" (own, special); German "will" (wants), "was" (what), "also" (so)
# and "her" (hither); Spanish "has" (you have: "has completado"); Dutch "is" (is), "of" (or), "over" (about,
# over), "was" (was) and "been" (leg: "op het verkeerde been").
NOT_ENGLISH = {"tr": {"her", "his", "has"}, "id": set(), "ms": set(), "fr": set(), "bn": set(), "ru": set(),
               "hi": set(), "de": {"will", "was", "also", "her"}, "es": {"has"}, "ml": set(), "ta": set(),
               "nl": {"is", "of", "over", "was", "been"}}
# A value may equal its key when the key is a name (a reciter, a book, Hafs): only one holding an English
# word is untranslated. Names that keep an English word on purpose (a published title) go here.
IDENTICAL_OK = set()


def latin_problems(reference, value):
    """Every left-to-right language (Indonesian, Malay, Turkish, French; Bangla and Russian too, with
    `script_problems` after it): English left in the value. A published title the key has too ("The
    Clear Quran", "The Sealed Nectar") may stay: a run of capitalised words copied from the key is a name."""
    out = []
    # A key that starts or ends with a space (" of ", "Contact: ") is glued to other text. Text always follows
    # a trailing space, so the value keeps one; a leading space may become punctuation (Turkish ", toplam ").
    # Neither edge gains a space the key does not have.
    if reference and value:
        lead = (reference[0].isspace() and value[0].isalnum()) or (not reference[0].isspace() and value[0].isspace())
        trail = reference[-1].isspace() != value[-1].isspace()
        if lead or trail:
            out.append("leading or trailing space differs from the key")
    if value == reference and reference not in IDENTICAL_OK and \
            {w.lower() for w in re.findall(r"[A-Za-z]+", reference)} & ENGLISH_WORDS:
        return ["untranslated: the value is the English key"]
    text = PARAM_TOKEN.sub(" ", SPEC.sub(" ", value))
    # A domain or repository the key names the same way (miracles-of-quran.com) is a name, not English.
    names = set(IDENTIFIER.findall(reference))
    text = IDENTIFIER.sub(lambda m: " " if m.group(0) in names else m.group(0), text)
    for m in QUOTED.finditer(text):  # a quoted word is an example ("the b in “book”")
        text = text.replace(m.group(0), " ")
    # Title Case runs the key spells the same way are names: "The Clear Quran", "Sahih International".
    for run in re.findall(r"(?:\b[A-Z][\w'’.-]*(?:\s+(?:of|the|and|in|on|for|al|an|as|at|to)\b|\s+[A-Z][\w'’.-]*)*)",
                          text):
        if " " in run.strip() and run.strip() in reference:
            text = text.replace(run, " ")
    # Arabic in the key (a word, an ayah, a letter) is quoted, never retyped: each run is in the value byte for
    # byte. A writing tool that recomposes Unicode (آ for ا + ٓ, harakat reordered) fails this.
    from collections import Counter
    runs = Counter(ARABIC_RUN.findall(reference))
    have = Counter(ARABIC_RUN.findall(value))
    lost = [r for r, n in runs.items() if have[r] < n and r not in value]
    if lost:
        out.append(f"Arabic {lost[0]!r} from the key is not in the value as written")
    # Whole words in any script: split at [A-Za-z] alone, Turkish "yaşandığı" held an English "and".
    left = [w for w in re.findall(r"[^\W\d_]+", text) if w.lower() in ENGLISH_WORDS - NOT_ENGLISH[LANG]]
    if left:
        out.append(f"English word {left[0]!r} left in the value")
    if EASTERN_DIGIT.search(text) and not EASTERN_DIGIT.search(reference):
        out.append("Arabic-Indic digits: write 0-9")
    return out


def is_english_word(word, cache={}):
    """In the system word list (/usr/share/dict/words): a lesson's transliteration ("kufuwan", "arkaboo") is
    not, so it may stay Latin in a Bangla or Russian value. Without the list every word counts as English."""
    if "words" not in cache:
        try:
            with open("/usr/share/dict/words", encoding="utf-8") as f:
                cache["words"] = {line.strip().lower() for line in f}
        except OSError:
            cache["words"] = None
    return cache["words"] is None or word.lower() in cache["words"]


BENGALI_DIGIT = re.compile("[\u09E6-\u09EF]")
DEVANAGARI_DIGIT = re.compile("[\u0966-\u096F]")
# Malayalam and Tamil digits (and Tamil's own signs for 10, 100, 1000): the app writes 0-9 there too.
NATIVE_DIGIT = {"ml": re.compile("[\u0D66-\u0D78]"), "ta": re.compile("[\u0BE6-\u0BF2]")}
# Bangla abbreviations end in a Latin full stop: died, Hijri, CE, page, number, Dr, (peace be upon him) ...
BANGLA_ABBREVIATIONS = {"মৃ", "হি", "খ্রি", "খ্রিস্টাব্দ", "পৃ", "নং", "ড", "ডা", "সা", "রা", "আ", "মি", "কি", "সে", "ঘ", "মিনি"}
# Hindi abbreviations end in a Latin full stop too: Dr, page, number, CE, Hijri, minute, second, hour, and the
# honorifics (radiyallahu, alaihis salam, rahimahullah).
HINDI_ABBREVIATIONS = {"डॉ", "पृ", "सं", "नं", "क्र", "ई", "हि", "मि", "से", "घं", "रज़ि", "अलै", "रह", "स", "अ"}
LATIN_LETTER = re.compile("[A-Za-z]")


def script_problems(reference, value):
    """Bangla, Russian, Hindi, Malayalam and Tamil, written in their own scripts: a value with none of its letters while the key has
    ordinary English words (a name like "Sahih al-Bukhari" may be written either way), a Cyrillic word with a
    Latin look-alike letter inside it, Bengali digits (the app writes 0-9: Apple's Bangla formats numbers in
    them too, and `localizedDigits` follows the locale), Devanagari, Malayalam and Tamil digits likewise, and a
    Latin full stop where Bangla and Hindi write the danda (Malayalam and Tamil end a sentence with the full
    stop, as English does)."""
    out = []
    text = PARAM_TOKEN.sub(" ", SPEC.sub(" ", value))
    for m in QUOTED.finditer(text):
        text = text.replace(m.group(0), " ")
    english = [w for w in re.findall(r"[A-Za-z']+", SPEC.sub(" ", reference))
               if w.islower() and len(w) >= 3 and w not in LATIN_OK and is_english_word(w)]
    if english and not NATIVE_LETTER[LANG].search(value):
        out.append(f"untranslated: no {SCRIPT_NAME[LANG]} letters in the value")
    if LANG == "ru":
        mixed = [w for w in re.findall(r"[^\W\d_]+", text) if NATIVE_LETTER["ru"].search(w) and LATIN_LETTER.search(w)]
        if mixed:
            out.append(f"Latin letter inside the Cyrillic word {mixed[0]!r}")
    if LANG == "bn":
        if BENGALI_DIGIT.search(text) and not BENGALI_DIGIT.search(reference):
            out.append("Bengali digits: write 0-9 (the app follows the locale)")
        stops = [m.group(1) for m in re.finditer("([\u0980-\u09FF]+)\\.(?=\\s|$)", text)]
        if any(word not in BANGLA_ABBREVIATIONS for word in stops):
            out.append("a Latin full stop after Bangla: write \u0964")
    if LANG == "hi":
        import unicodedata
        if DEVANAGARI_DIGIT.search(text) and not DEVANAGARI_DIGIT.search(reference):
            out.append("Devanagari digits: write 0-9 (the app follows the locale)")
        abbreviations = {unicodedata.normalize("NFC", a) for a in HINDI_ABBREVIATIONS}
        stops = [unicodedata.normalize("NFC", m.group(1)) for m in re.finditer("([\u0900-\u097F]+)\\.(?=\\s|$)", text)]
        if any(word not in abbreviations for word in stops):
            out.append("a Latin full stop after Hindi: write \u0964")
    if LANG in NATIVE_DIGIT and NATIVE_DIGIT[LANG].search(text) and not NATIVE_DIGIT[LANG].search(reference):
        out.append(f"{SCRIPT_NAME[LANG]} digits: write 0-9 (the app follows the locale)")
    return out


# A count written beside its noun ("%lld аятов", "%lld versets") is right for some numbers only: those keys
# take plural forms. A plain string must put the number where no noun agrees with it ("Аяты: %lld").
COUNT_NOUN = {"ru": re.compile(r"%(?:\d+\$)?l{0,2}[du]\s+(?!(?:из|в|во|на|с|со|по|до|за|от|к|ко|для|о|об|при|через|"
                              r"подряд|и|или|мин|сек|ч|г|км|м|стр|мс|гр)(?![\u0400-\u04FF]))[\u0400-\u04FF]", re.I),
              "fr": re.compile(r"%(?:\d+\$)?l{0,2}[du]\s+(?!(?:fois|mois|sur|sous|dans|plus|pas|après|depuis|à|de)\b)\w+[sx]\b"),
              # German capitalises every noun: a count before one needs forms ("1 Vers", "2 Verse"), except a noun
              # whose plural is the same word.
              "de": re.compile(r"%(?:\d+\$)?l{0,2}[du]\s+(?!(?:Mal|Kapitel|Meter|Kilometer|Juz|Hizb|Prozent|Grad|Zeichen|"
                               r"Fehler|Uhr)\b)[A-ZÄÖÜ][a-zäöüß]"),
              "es": re.compile(r"%(?:\d+\$)?l{0,2}[du]\s+(?!(?:más|menos|tras|antes|después|pues|además)\b)\w+s\b"),
              # Hindi marks the plural on the noun or its postposition's form: आयतें, आयतों में, दुआएँ (में is "in").
              "hi": re.compile("%(?:\\d+\\$)?l{0,2}[du]\\s+(?!\u092E\u0947\u0902(?![\u0900-\u097F]))[\u0900-\u097F]*(?:\u0947\u0902|\u094B\u0902|\u0901)(?![\u0900-\u097F])"),
              # Malayalam and Tamil mark the plural with -കൾ / -ങ്ങൾ and -கள் (case endings may follow:
              # ആയത്തുകളിൽ, ஆயத்துகளில்).
              "ml": re.compile("%(?:\\d+\\$)?l{0,2}[du]\\s+[\u0D00-\u0D7F]*(?:\u0D15|\u0D19\u0D4D\u0D19)(?:\u0D7E|\u0D33)"),
              "ta": re.compile("%(?:\\d+\\$)?l{0,2}[du]\\s+[\u0B80-\u0BFF]*\u0B95\u0BB3"),
              # Dutch plurals end in -en or -s ('s): "1 vers", "2 verzen", "1 pagina", "2 pagina's". A unit that
              # stays singular after a number (keer, uur, jaar, procent) needs no forms.
              "nl": re.compile(r"%(?:\d+\$)?l{0,2}[du]\s+(?!(?:keer|maal|uur|jaar|procent|graden|meter|kilometer|"
                               r"juz|hizb|tekens|van|voor|na|op|in|uit|per|en|of|om)\b)\w+(?:en|'s|’s)\b")}


def needs_plural_forms(key, value):
    pattern = COUNT_NOUN.get(LANG)
    return bool(pattern and plural_eligible(key) and pattern.search(value))


# “…”, «…», "…" and German „…“ (it closes with the English opening mark).
QUOTED = re.compile(r"[\u201C\u201E\u00AB\"]([^\u201C\u201D\u00BB\"]{1,60})[\u201C\u201D\u00BB\"]")
# A run of Arabic script, its marks and tatweel included (spaces end it).
ARABIC_RUN = re.compile("[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+")


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
    if LANG not in ARABIC_SCRIPT:
        return value  # left to right, Western digits: nothing to adjust
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
                forms = [f for f in PLURAL_FORMS[LANG] if value.get(f)]
                if LANG not in ARABIC_SCRIPT and (forms == ["other"] or len({value[f] for f in forms}) == 1):
                    loc = unit(value[forms[-1]])  # one form for every number: a plain string
                else:
                    loc = {"variations": {"plural": {f: unit(value[f]) for f in forms}}}
            else:
                errs = problems(key, value, english=english_of(strings[key]), arabic=value_of(strings[key], "ar"))
                if needs_plural_forms(key, value):
                    errs.append("the count stands beside its noun: give plural forms "
                                + "{" + ", ".join(f'"{f}": ...' for f in REQUIRED_PLURALS[LANG]) + "}")
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
        words = int(args[args.index("--words") + 1]) if "--words" in args else 0
        cmd_todo(args[0], args[1], chunk, words, "--like-ar" in args)
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
