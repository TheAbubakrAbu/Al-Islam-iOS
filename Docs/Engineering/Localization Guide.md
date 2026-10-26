# Localization Guide

The app speaks English, Arabic (since 2026-10-24) and Urdu (since 2026-10-26). Everything is translated, the
Islam tab included, except the Islam tab's ARTICLES: Faith & Proofs (the pillars, beliefs, How-To Guides,
miracles, prophecies, the prophets' miracles, the Sunnahs of the Prophet, Proving Islam), Hadith & Its Sciences
and the riwayat differences page. Those stay English and read left to right inside the Arabic and Urdu interfaces.

## Where things live

| What | Where |
| --- | --- |
| Interface strings, their Arabic and Urdu | `Resources/Localizable.xcstrings` (iPhone, Widget, Watch, Complication) |
| Permission prompts, the home-screen name | `Resources/InfoPlist.xcstrings` (iPhone, Watch) |
| Siri and Shortcuts phrases | `Resources/ar.lproj/AppShortcuts.strings` (iPhone), `Resources/Watch/ar.lproj/AppShortcuts.strings` (Watch); none for Urdu (Siri has no Urdu) |
| Helpers | `iPhone/Helpers/System/Localization.swift` (every target) |
| Catalog tool | `Scripts/localize_catalog.py` |

The language is the per-app choice iOS keeps in Settings > Al-Islam > Language. The app's own Settings has a
Language row (APPEARANCE) that opens that page. There is no in-app language switch: `String(localized:)`,
notifications and widgets would not follow one.

## Writing code that stays translated

1. **Interface text is a literal the compiler can see.** SwiftUI already extracts `Text("...")`,
   `Button("...")`, `Label("...", systemImage:)`, `Toggle`, `Section`, `.navigationTitle`, alerts and
   accessibility labels. Text that reaches the screen as a `String` (a `title` property, a notification body,
   an argument to one of the app's own views) is written `String(localized: "...")`.
2. **Localize the display, never the data.** A string that is stored, compared, matched, searched, used as an
   identifier or sent to the on-device model stays English. Show it through `.localizedDisplay` (a runtime
   lookup) or a display-only property (`displayTitle`, `displayName`). A `.localizedDisplay` value needs a
   manual catalog key (see below).
3. **Whole sentences, not pieces.** `"\(n) ayahs"` and `"Surah \(name)"` become one key each. Never glue
   translated fragments together, and never put an English word in a key's argument.
4. **Plurals:** keep the English branches as they are; Arabic gets its six plural forms in the catalog, Urdu its
   two (one, other).
5. **Two meanings, two keys.** One English word with two senses needs a key of its own:
   `String(localized: "weather.clear", defaultValue: "Clear")`. Met so far: "Voice" (the grammar card's
   البناء; the letters course uses `sifah.voice`) and the ayah-counting traditions (`count.makki` and the
   rest: "Makki" alone is the Meccan surah filter, مكية). A dotted key needs its English written into the
   catalog too.
6. **The model, saved data and backups get English.** Ask AI's sources, the semantic corpora, saved
   reflections, iCloud summaries and any id are built from English. Interface text that is ALSO model input
   (the tips catalogue, settings search entries) is an `InterfaceText` (SettingsView.swift): `display` for the
   screen, `english` for the model and ids, from the same literal and catalog key.

Traps:
- `NSLocalizedString` is NOT extracted by the command-line compiler. Use `String(localized:)`.
- A ternary inside an interpolation (`"\(n) \(n == 1 ? "a" : "b")"`) is not extracted. Write whole branches.
- An `Int` interpolated into `String(localized:)` gets grouping ("2,026"). A count may group; an identifier
  (a hadith number, a year) must not: pass it as text (`HadithBookView.citation`, `String(year).localizedDigits`).
- `String(localized:)` isolates every argument. An Arabic line with no Arabic letter outside its arguments, or
  one that starts with an argument, falls back to left to right and its parts swap: the catalog tool starts
  such Arabic values with U+200F, and a line built in code needs the same (`SymbolNumber.rightToLeftLine`).
- A middle dot "·" beside Arabic-Indic digits reads as a zero; Arabic uses "•" or "،".
- Join lists with `[String].sentenceList` (Globals.swift), never a Latin ", ", and show a stored
  "City, Region" label through `displayCity`. The city is geocoded in the interface language and looked
  up again when the language changes (`currentLocationLabelLanguage`).
- `.trailing` means the LEFT edge in Arabic. Arabic text that should hug the right edge in both languages
  needs `.environment(\.layoutDirection, .leftToRight)` around its `.trailing` frame, or the natural
  alignment of a UIKit text view.

## Digits

Every number on screen follows the locale's digits, the way Apple's own formatting does. The locale is the
app's language plus the phone's region: an Arabic interface on a US-region phone is `ar_US` and writes
Western digits (0-9); Saudi Arabia (`ar_SA`) and Egypt write Arabic-Indic (٠-٩); a reader can also pick the
digits in iOS. Numbers Foundation and SwiftUI format follow it on their own. Two kinds do not:
- digits the app builds into a string itself (`"\(surah):\(ayah)"`, `String(n)`, `Text(verbatim:)`), and
- digits a translation writes out ("٥ دقائق").
Both go through `.localizedDigits` at the display site. It maps every digit, Western, Arabic-Indic or Extended
Arabic-Indic, to the locale's, and is a no-op in English. Never on data. Test both: `-AppleLocale ar_US` and
`-AppleLocale ar_SA`.

Urdu: Apple's Urdu locales, `ur_PK` and `ur_IN` alike, write Western digits; a reader who picks Urdu digits
in iOS (Settings > General > Language & Region > Numbers) gets Extended Arabic-Indic (۰-۹), and every number
the app formats or passes through `localizedDigits` follows (measured 2026-10-26). Urdu translations write
Western digits (the validator rejects the others), so a catalog value shown straight by SwiftUI keeps them.
Test `-AppleLocale ur_PK` and `-AppleLocale "ur_PK@numbers=arabext"`.

## Names

- The app's own name: `AppIdentifiers.displayName` (الإسلام in Arabic) wherever it is shown;
  `AppIdentifiers.appName` stays the identifier, asset name and file-name prefix. In an Arabic sentence the
  app is "تطبيق %@" (a bare الإسلام in a sentence reads as the religion). The home-screen name is
  `CFBundleDisplayName` in InfoPlist.xcstrings.
- Surahs, juz, hadith books, chapters, authors and Quran topics show their Arabic names in Arabic and in Urdu
  (`Surah.displayName`, `Juz.displayName`, `HadithCatalogBook.displayTitle` and `displayReference`). The switch
  is `AppLanguage.isArabicScript` (Arabic or Urdu): wherever a comment says "the Arabic interface", Urdu does
  the same, because the Latin transliteration and the English meaning would be untranslated English in either.
  `AppLanguage.isArabic` alone is kept for what only Arabic does: the surah name Siri says back.
- In Urdu the app is الاسلام (الاذان، القرآن، الحدیث), and in a sentence "%@ ایپ", the name first, with
  feminine verbs (ایپ ... استعمال کرتی ہے).

## Right to left

SwiftUI mirrors every layout in Arabic and Urdu. What must not mirror:
- **English content** (a translation, a transliteration, a hadith's English, an English tafsir):
  `.leftToRightContent()` on the text, never on the row around it.
- **Clocks and numeric runs** (`2:49:59`): pin the stack `.leftToRight`.
- **The mushaf pager:** UIKit already starts a paging scroll view on the right in a right-to-left app, so
  `MushafReader` reverses its pages only in English (`AppLanguage.isRightToLeft`). Check a page turn with
  `-pageTurns 1` and a screen recording: the next page slides in from the LEFT in both languages.
- **English articles:** each article screen's List carries `.englishArticle()`, so the page reads left to right
  as it does in English while its navigation bar stays Arabic; sheets and screens it opens get the interface
  direction back on their own. Interface words inside an article whose key a translated screen shares keep
  English through `AppLanguage.article("...")`. `Scripts/build_islam_corpus.py` reads an article's title from
  `.navigationTitle("...")` and accepts the `AppLanguage.article(...)` wrapper; run
  `Scripts/verify_islam_corpus.py` after touching article titles (never import the builder: it rewrites the pack).
- **Never pin a tab root or a NavigationStack** left to right, by environment or by trait: Lists drew mirrored,
  letters backwards, and the back chevron flipped. A pin on a pushed screen's List is fine (measured
  2026-10-25).

## Siri and Shortcuts

The English phrases are the ones in `AppShortcutsRoot` (iPhone/Settings/System/AppIntents.swift). Every other
language gets one translated phrase per English phrase in `<language>.lproj/AppShortcuts.strings`, keyed by the
English with `${applicationName}`, `${surah}` and `${prayer}` kept as written. A String Catalog cannot be used:
AppShortcuts.xcstrings needs iOS 17 and watchOS 10. The Watch copy leaves out the Open Surah phrases (their
intents are iPhone only); a build warning "This phrase is not used in any App Shortcut" means the two have
drifted apart. Never write a non-English phrase into the code: to Siri it would be one more English phrase.
The surah a phrase names is matched against Arabic names too (`Surah.spokenName`, `normalizedSearchNames`).

Urdu has no AppShortcuts.strings: Siri cannot be set to Urdu (iOS 26 brought Urdu to the interface, not to
Siri or dictation), so an Urdu phrase could never be heard. On an Urdu phone Siri runs in English or Arabic and
matches those phrases; the shortcut titles in the Shortcuts app and Spotlight are catalog keys and show Urdu.

## Updating the catalog

`xcodebuild` does not write new keys into the catalog (only a build inside Xcode does). After a command-line
build:

```sh
DD=<the build's -derivedDataPath>
./Scripts/localize_catalog.py sync $DD                 # add new keys, mark vanished ones stale
./Scripts/localize_catalog.py todo $DD /tmp/todo       # batches of keys still missing Arabic (--lang ur: Urdu)
./Scripts/localize_catalog.py validate ar.json         # check a translation file, write nothing
./Scripts/localize_catalog.py merge ar.json            # write it in
./Scripts/localize_catalog.py manual keys.json         # data strings shown through .localizedDisplay
./Scripts/localize_catalog.py check                    # every translated value against its key
./Scripts/localize_catalog.py sibling SIBLING_DD [--add]  # keys only Al-Adhan's or Al-Quran's code has
```

`todo`, `validate`, `merge`, `check` and `sibling` take `--lang ur` for Urdu (Arabic is the default). An Urdu
batch carries each key's Arabic as `arabic`, the reference for its sense and for the Islamic term chosen.

A translation file is `{english key: translation}`; a key with exactly one integer argument may map to an object
of plural forms (Arabic `one`, `two`, `few`, `many`, `other`; Urdu `one`, `other`; optional `zero` in both).
The validator rejects mismatched placeholders, leftover English words, em dashes and changed `${parameter}`
tokens, and in Urdu Arabic letter forms, Eastern digits and a Latin full stop. A Latin word may stay only when
the key has it too and it is a letter or two or quoted (the alphabet lessons compare letters with English
words: «مثل حرف b في “book”»). Keys whose every source is an article file (`ARTICLE_SOURCES`) are never offered
for translation, nor a key marked `shouldTranslate: false` (an email address).

A key the code shows AND the tajweed pack shows as data can mean two things: "Light" is the Color Theme
choice and a light letter (مرقّقة), "Merge" a backup choice and idgham, "Article" an Ask AI source and the
definite article. The code side then takes a dotted key of its own (`appearance.light`, `backup.merge`,
`askai.article`, `dhikr.count.one`) and the plain key stays the pack's, marked `manual`. Short keys that
both show are worth checking after every pack harvest: the Tilawa harvest of 2026-10-25 had overwritten the
Arabic of "Surah" (الموضع), "Note" (تنبيه), "Noun" and "Verb" with their senses in one lesson table.

Data shown through `.localizedDisplay` needs its English registered as a manual key. The tajweed course is the
big one: its 58 lessons live in `Resources/Data/Quran/TajweedLessons.json.xz`, and every field the course shows
is a manual key, so rebuilding that pack with different English needs those keys again.

Tilawa (the sister React Native app) carries Arabic for much of the same content (its tajweed course, its UI
dictionary): align by position or by identical English before translating from scratch.

## Al-Adhan and Al-Quran

The siblings get their languages from the sync (`~/Downloads/Islam/sync_from_islam.sh`, Docs/Engineering/Sibling
Sync Guide.md). The code (`Localization.swift`, every `String(localized:)`) merges like any shared file. The
rest is `../sync_localization.py`'s, a pass of the sync that can also run alone:

| Sibling file | Where it comes from |
| --- | --- |
| `Resources/Localizable.xcstrings` | Al-Islam's, copied whole on every sync (`L10N_MIRROR`): all translation happens here |
| `Resources/InfoPlist.xcstrings` | written per app (`L10N_DERIVED`): the keys its Info.plist declares, its own English, this catalog's Arabic and Urdu with the app's name swapped (الأذان، القرآن, "تطبيق %@" in an Arabic sentence; الاذان، القرآن, "%@ ایپ" in Urdu) |
| `Resources/ar.lproj/AppShortcuts.strings`, `Resources/Watch/ar.lproj/AppShortcuts.strings` | written per app and target: only the phrases its `AppShortcutsRoot` compiles under its flags (Al-Adhan the prayer phrases, Al-Quran the surah ones), since an unused phrase is a build warning |
| the project | `ar` and `ur` in knownRegions, `STRING_CATALOG_GENERATE_SYMBOLS = NO` (Al-Quran's Widget overrides it too), and the files above registered in the targets Al-Islam's are in |

Never translate inside a sibling: its catalog is replaced on the next sync. A key only a sibling's code has
(its root, a string it renamed) is found from one of its builds and added here:

```sh
./Scripts/localize_catalog.py sibling <the sibling's -derivedDataPath>         # report only
./Scripts/localize_catalog.py sibling <the sibling's -derivedDataPath> --add   # add them as manual keys
```

then `todo`, translate, `merge` as usual, and the next sync (or `../sync_localization.py <app> --apply`)
carries them over. A new privacy prompt or Siri phrase in Al-Islam reaches a sibling the same way, through its
translation here. A sibling prompt whose English differs from Al-Islam's beyond the app name is a LOC-ERROR,
translated by hand in that sibling's InfoPlist.xcstrings (the pass keeps a hand translation it cannot derive).

## Arabic style

Modern Standard Arabic as Apple's own Arabic interface writes it. Prayer names, Quran and hadith terms follow
one glossary (الفجر، سورة، آية، جزء، الرواية، التجويد ...). A feature name quoted in a tip uses exactly the
label the control shows. Quranic text is never written from memory: an ayah in a translation is either the
exact text between ﴿ ﴾, checked against the Quran's text, or its meaning without the brackets. Search fields
accept Arabic-Indic digits (٢:٢٥٥): the Quran search, the mushaf find bar, the Go To fields and the hadith
reference parser fold them to Western digits.

## Urdu style

Since 2026-10-26, made the way the Arabic was: the same catalog, the same tool (`--lang ur`), and the
Arabic beside every key as the reference for its sense and its Islamic term.

**Names.** The same names as Arabic, in Urdu spelling (no hamza on the alif, Urdu ی):

| English | Urdu | Used as |
| --- | --- | --- |
| Al-Islam | الاسلام | home-screen name, the Adhan screen's title, sentences |
| Al-Adhan | الاذان | the same, in Al-Adhan |
| Al-Quran | القرآن | the same, in Al-Quran |
| Al-Hadith | الحدیث | the Hadith screen's title |
| Settings | ترتیبات | tab (Tilawa's word; سیٹنگز is the spoken one) |
| "the app" in a sentence | `%@ ایپ` | the name comes FIRST: «الاسلام ایپ آپ کا مقام … استعمال کرتی ہے۔» |

- ایپ is feminine, so a sentence whose subject is "%@ ایپ" ends in کرتی ہے، دکھاتی ہے, not the masculine forms.
- A bare اسلام in a sentence is the religion; the app is always الاسلام or «الاسلام ایپ».
- The tabs ("Islam", "Quran", "Hadith", "Adhan") are the plain words, as Urdu says them: اسلام، قرآن، حدیث،
  اذان. Arabic's tabs carry ال because that is how Arabic says those words, not because they are the brand.

**Writing Urdu**
- Urdu letters, never their Arabic look-alikes: ی (U+06CC) not ي, ک (U+06A9) not ك, ہ (U+06C1) and ھ
  (U+06BE) not ه, ۃ not ة. The full stop is ۔ (U+06D4). The validator rejects a word that mixes the two, and
  an Arabic-form word unless it is vowelled, inside ﴿ ﴾, or spelled the same in the key or its Arabic (an
  Arabic term quoted as Arabic: «الحروف الهجائية»).
- Prayer and Quran terms the way Urdu speakers say them: نماز (not صلاة), فجر، ظہر، عصر، مغرب، عشاء، سورت
  (سورۃ before a name), آیت، پارہ (a juz), قاری، تجوید، قبلہ. Fatha, kasra and damma are زبر، زیر، پیش, as
  in the Noorani Qaida.
- Western digits in every value (the validator rejects ٠-٩ and ۰-۹ unless the key has them); Hijri years
  take ھ ("1448ھ"). A literal percent stays % (Arabic's ٪ is Arabic only).
- Plurals: `one` and `other` (and the optional `zero`).

**Where it came from.** 3,963 strings are Tilawa's own Urdu (`src/data/tajweed-course/ur/`, the tajweed
article overlay): the whole 58-lesson course, aligned by lesson and field as the Arabic was, plus Tilawa's
lesson `title` and rule-card `countLabel`, which only its Urdu copy has (Arabic reads the lesson's
`titleAr`). Tilawa's UI dictionary (`strings.ur.ts`) was NOT used: its short labels are machine-quality
(Juz as جوز, Ayah as آیہ, full stops on buttons). The other 8,300 keys were translated against the
glossary above with the Arabic as the reference.

**Siri.** None (see Siri and Shortcuts): the two tips that quote Siri phrases quote them in English on an
Urdu screen, with the name Siri hears (`TipsAndTricks.siriApp`).

**Nastaliq.** iOS draws Urdu in Noto Nastaliq Urdu, much taller than Arabic Naskh. Text that can wrap
grows on its own; check fixed-height rows, chips and widget lines in `-AppleLanguages "(ur)"` for clipping.

**The Hijri date** reads in Arabic in Urdu, as it does in Arabic (`HijriDate.interfaceLine`, the widgets'
`Language.interface`): the month names are the same words, and the line beside it is the Gregorian date in
Urdu.

## Still open

- The Islam tab's articles (about 220,000 words) are English.
- Quran, hadith, dua and 99 Names English meanings stay English (they are translations of the Arabic).
- The siblings are staged, not applied (2026-10-25): their next sync carries Arabic and Urdu (section above).
  Their Arabic store listings wait in `~/Downloads/Islam/sibling-staging/<App>-iOS/Docs/Arabic Listing.md`.
- The App Store listing in Arabic is drafted in `Docs/App Store/Arabic Listing.md`; screenshots are English
  (App Store Connect shows the English ones for a language that has none of its own).
- Every Arabic and Urdu string is machine-translated (Urdu's tajweed course is Tilawa's) and needs a fluent
  reviewer before release.
- The App Store listing in Urdu is drafted in `Docs/App Store/Urdu Listing.md`; the siblings' Urdu listings
  wait in `~/Downloads/Islam/sibling-staging/<App>-iOS/Docs/Urdu Listing.md`.
