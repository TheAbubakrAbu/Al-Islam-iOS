# Localization Guide

The app speaks English and Arabic (since 2026-10-24). Everything is translated, the Islam tab included, except
the Islam tab's ARTICLES: Faith & Proofs (the pillars, beliefs, How-To Guides, miracles, prophecies, the
prophets' miracles, Proving Islam), Hadith & Its Sciences and the riwayat differences page. Those stay English
and read left to right inside the Arabic interface.

## Where things live

| What | Where |
| --- | --- |
| Interface strings and their Arabic | `Resources/Localizable.xcstrings` (iPhone, Widget, Watch, Complication) |
| Permission prompts, the home-screen name | `Resources/InfoPlist.xcstrings` (iPhone, Watch) |
| Siri and Shortcuts phrases | `Resources/ar.lproj/AppShortcuts.strings` (iPhone), `Resources/Watch/ar.lproj/AppShortcuts.strings` (Watch) |
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
4. **Plurals:** keep the English branches as they are; Arabic gets its six plural forms in the catalog.
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
Both go through `.localizedDigits` at the display site. It maps every digit, Western or Arabic-Indic, to the
locale's, and is a no-op in English. Never on data. Test both: `-AppleLocale ar_US` and `-AppleLocale ar_SA`.

## Names

- The app's own name: `AppIdentifiers.displayName` (الإسلام in Arabic) wherever it is shown;
  `AppIdentifiers.appName` stays the identifier, asset name and file-name prefix. In an Arabic sentence the
  app is "تطبيق %@" (a bare الإسلام in a sentence reads as the religion). The home-screen name is
  `CFBundleDisplayName` in InfoPlist.xcstrings.
- Surahs, juz, hadith books, chapters, authors and Quran topics show their Arabic names in Arabic
  (`Surah.displayName`, `Juz.displayName`, `HadithCatalogBook.displayTitle` and `displayReference`).

## Right to left

SwiftUI mirrors every layout in Arabic. What must not mirror:
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

## Updating the catalog

`xcodebuild` does not write new keys into the catalog (only a build inside Xcode does). After a command-line
build:

```sh
DD=<the build's -derivedDataPath>
./Scripts/localize_catalog.py sync $DD                 # add new keys, mark vanished ones stale
./Scripts/localize_catalog.py todo $DD /tmp/todo       # batches of keys still missing Arabic
./Scripts/localize_catalog.py validate ar.json         # check a translation file, write nothing
./Scripts/localize_catalog.py merge ar.json            # write it in
./Scripts/localize_catalog.py manual keys.json         # data strings shown through .localizedDisplay
./Scripts/localize_catalog.py check                    # every Arabic value against its key
./Scripts/localize_catalog.py sibling SIBLING_DD [--add]  # keys only Al-Adhan's or Al-Quran's code has
```

A translation file is `{english key: arabic}`; a key with exactly one integer argument may map to an object of
plural forms (`one`, `two`, `few`, `many`, `other`, optional `zero`). The validator rejects mismatched
placeholders, leftover English words, em dashes and changed `${parameter}` tokens. A Latin word may stay only
when the key has it too and it is a letter or two or quoted (the alphabet lessons compare letters with English
words: «مثل حرف b في “book”»). Keys whose every source is an article file (`ARTICLE_SOURCES`) are never offered
for translation.

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
| `Resources/InfoPlist.xcstrings` | written per app (`L10N_DERIVED`): the keys its Info.plist declares, its own English, this catalog's Arabic with the app's name swapped (الأذان، القرآن; "تطبيق %@" in a sentence) |
| `Resources/ar.lproj/AppShortcuts.strings`, `Resources/Watch/ar.lproj/AppShortcuts.strings` | written per app and target: only the phrases its `AppShortcutsRoot` compiles under its flags (Al-Adhan the prayer phrases, Al-Quran the surah ones), since an unused phrase is a build warning |
| the project | `ar` in knownRegions, `STRING_CATALOG_GENERATE_SYMBOLS = NO` (Al-Quran's Widget overrides it too), and the files above registered in the targets Al-Islam's are in |

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

## Urdu (planned, not started)

Written down 2026-10-25 so the next language starts from decisions already made. Nothing below is in the
catalog or the code yet.

**Names.** The same names as Arabic, in Urdu spelling (no hamza on the alif, Urdu ی):

| English | Urdu | Used as |
| --- | --- | --- |
| Al-Islam | الاسلام | home-screen name and tab |
| Al-Adhan | الاذان | home-screen name and tab |
| Al-Quran | القرآن | home-screen name and tab |
| Al-Hadith | الحدیث | tab |
| Settings | ترتیبات | tab (Tilawa's word; سیٹنگز is the spoken one) |
| "the app" in a sentence | `%@ ایپ` | the name comes FIRST: «الاسلام ایپ آپ کا مقام … استعمال کرتی ہے۔» |

- ایپ is feminine, so a sentence whose subject is "%@ ایپ" ends in کرتی ہے، دکھاتی ہے, not the masculine forms.
- A bare اسلام in a sentence is the religion; the app is always الاسلام or «الاسلام ایپ».

**App Store names** (drafts, 30 characters max; App Store Connect has taken Urdu listings since 2026-03-31):

| App | Name | Count |
| --- | --- | --- |
| Al-Islam | الاسلام \| قرآن، اذان، حدیث | 26 |
| Al-Adhan | الاذان \| نماز کے اوقات، قبلہ | 28 |
| Al-Quran | القرآن \| تلاوت، تفسیر، تجوید | 28 |

**Writing Urdu**
- Urdu letters, never their Arabic look-alikes: ی (U+06CC) not ي, ک (U+06A9) not ك, ہ (U+06C1) and ھ
  (U+06BE) not ه. The full stop is ۔ (U+06D4). A validator rule should reject the Arabic forms in `ur`
  values (quoted Arabic, an ayah or a dua, keeps its own spelling).
- Prayer and Quran terms the way Urdu speakers say them: نماز (not صلاة) for the prayer, فجر، ظہر، عصر، مغرب،
  عشاء، سورت or سورہ، آیت، پارہ (the common word for a juz), تجوید، قبلہ.
- Digits: `ur_PK` writes Western digits and `ur_IN` Extended Arabic-Indic (۰-۹); `localizedDigits` already
  maps both ways.
- Plurals: Urdu has only `one` and `other`. `localize_catalog.py` requires Arabic's five forms today, so the
  required forms become per language first.

**What the tooling needs when it starts**
- `ur` in knownRegions, catalog values for `ur`, and `InfoPlist.xcstrings` entries in the same name pattern.
- `../sync_localization.py` swaps the app's name into the siblings' prompts through `APP_WORD`, which only
  knows a word placed BEFORE the name (Arabic تطبيق). Urdu puts ایپ AFTER it, so the swap needs a suffix form.
- Nastaliq: iOS draws Urdu in Noto Nastaliq Urdu, which is much taller than Arabic Naskh. Fixed-height rows,
  chips and widget lines need checking for clipped text.
- Siri: check Apple's list of Siri languages before writing `ur.lproj/AppShortcuts.strings` (unverified
  when this was written whether Siri speaks Urdu; the phrases would still show in Spotlight and Shortcuts).
- Tilawa ships Urdu (`src/i18n/strings.ur.ts`, about 4,100 keys, plus the whole tajweed course under
  `src/data/tajweed-course/ur/`): align by identical English first, as was done for Arabic.

## Still open

- The Islam tab's articles (about 220,000 words) are English.
- Quran, hadith, dua and 99 Names English meanings stay English (they are translations of the Arabic).
- The siblings are staged, not applied (2026-10-25): their next sync carries Arabic (section above). Their
  Arabic store listings wait in `~/Downloads/Islam/sibling-staging/<App>-iOS/Docs/Arabic Listing.md`.
- The App Store listing in Arabic is drafted in `Docs/App Store/Arabic Listing.md`; screenshots are English
  (App Store Connect shows the English ones for a language that has none of its own).
- Every Arabic string is machine-translated and needs a fluent reviewer before release.
