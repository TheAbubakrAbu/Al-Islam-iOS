# Localization Guide

The app speaks English, Arabic (since 2026-10-24), Urdu (since 2026-10-26), Indonesian, Malay and Turkish
(since 2026-11-19), French, Bangla, Russian, Hindi, German and Spanish (since 2026-11-20), and Malayalam,
Tamil and Dutch (since 2026-11-21). Everything is translated, the Islam tab included, except the Islam tab's ARTICLES:
the seven Faith & Proofs resources (Pillars and Beliefs, How-To Guides, Miracles of the Quran, Prophecies of the
Prophet, Miracles of the Prophets, Sunnahs of the Prophet, Proving Islam). Those stay English, and read left to
right inside the Arabic and Urdu interfaces. Hadith & Its Sciences and the riwayat differences page are not a
separate set: they are groups and pages INSIDE Pillars and Beliefs. The Hadith tab's "About Hadith & the Sunnah"
section and Quran Words only link into them.

Scripture and its meanings are data, not interface, and stay as shipped in every language: the Quran
translations (Saheeh International, the Clear Quran), the hadiths' English, the hadith explanations, the
English tafsir, the duas' and dhikr's meanings, the 99 Names' meanings and explanations, the daily reminders
and the word-by-word meanings. The Arabic is always beside them. Other languages would need a published
translation chosen for each, never a machine one.

Outside English the app says so (2026-11-24, Abu: "say it only supports English clearly"; `EnglishOnly` in
ArticleDesign.swift): every Faith & Proofs tile carries "EN" in its corner, its rows and banners an "English
only" tag, the FAITH & PROOFS header the same tag, and each of the seven pages opens with "Available in
English only" at the top of its card (`ResourceHero` reads `isEnglishArticle`, which `englishArticle()` sets).
The Hadith tab's section of article links says it in its footer. In English none of it is drawn.

## Where things live

| What | Where |
| --- | --- |
| Interface strings and every translation | `Resources/Localizable.xcstrings` (iPhone, Widget, Watch, Complication; the three extensions ship only their share, see "Each extension's share") |
| Permission prompts, the home-screen name | `Resources/InfoPlist.xcstrings` (iPhone, Watch) |
| Siri and Shortcuts phrases | `Resources/<ar, ms, tr, fr, ru, de, es, nl>.lproj/AppShortcuts.strings` (iPhone), `Resources/Watch/<same>.lproj/AppShortcuts.strings` (Watch); none for Urdu, Indonesian, Bangla, Hindi, Malayalam or Tamil (Siri has none of them) |
| Helpers | `iPhone/Helpers/System/Localization.swift` (every target) |
| Catalog tool | `Scripts/localize_catalog.py` |
| Next languages, the runbook | `Docs/Engineering/Localization Roadmap.md` |
| Translation kit (brief, glossaries, labels, scripts, agent prompts) | `Scripts/Localization/` (copy it to a scratchpad to run a round) |

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
   البناء; the letters course uses `sifah.voice`), "Clear" (the button, مسح; izhar's meaning on the letters
   course card is `idhaar.clear`, البيان), "Hidden" (the tajweed legend's VoiceOver value for a rule switched
   off, مخفي; ikhfa's meaning is `ikhfaa.hidden`, الستر), the ayah-counting traditions (`count.makki` and the rest: "Makki"
   alone is the Meccan surah filter, مكية), and the prophets Idris and Ishaq (`prophet.idris`,
   `prophet.ishaq`: the plain keys are the qiraat narrators, who keep the Latin spelling in Turkish like
   Warsh and Qalun, where the prophets are İdris and İshak). A dotted key needs its English written into the
   catalog too.
6. **English-only forms ask `AppLanguage.isEnglish`, never `!isArabicScript`.** Every left-to-right language
   after English (Indonesian, Malay, Turkish, French, Bangla, Russian, Hindi, German, Spanish, Malayalam, Tamil,
   Dutch) takes the English LAYOUT (every `isArabicScript` branch's Latin side), but not its English text: a Hijri
   date pinned to `Locale(identifier: "en")`, a list joined with " and ", a meaning read straight from
   English data. Those switch on `isEnglish` and otherwise use the locale (`.current`) or the catalog.
7. **The model, saved data and backups get English.** Ask AI's sources, the semantic corpora, saved
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
- A translated label set into a sentence ("Hold to %@.", "exit 3, %@") goes through `.midSentence`, never
  `.lowercased()`: German capitalises every noun ("Zu Favoriten hinzufügen" must not become "zu favoriten
  hinzufügen"), and Turkish lowercases İ to i, which only the locale knows.
- Letter spacing goes through `AppLanguage.letterSpacing(_:)` (`.tracking(AppLanguage.letterSpacing(0.8))`), never
  a bare number: it is zero in Arabic, Urdu, Hindi and Bangla, whose letters join or hang from one headline
  stroke, where any tracking pulls each word apart into loose letters (all 34 sites, 2026-11-20), and in
  Malayalam and Tamil, whose vowel signs and conjuncts are shaped as one cluster with their consonant.
- `.uppercased()` ignores the locale: Turkish capitals are İ for i ("İKİNDİ"). Display text is
  `.localizedUppercase` (89 sites changed 2026-11-19); search keys, identifiers and ENGLISH content (the
  articles, hadith chapter titles, a book's `englishTitle`) keep `.uppercased()`: under a Turkish locale
  `localizedUppercase` would write the English "in" as "İN".
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
  Every other language reads a hadith book's title and compiler through the catalog (manual keys, the
  English as the key: "Sahih Muslim" -> «Сахих Муслим», "Forty Hadith Qudsi" -> «Quarante hadiths
  qudsi»); a transliterated title a language keeps as it is simply has no entry there (2026-11-20).
- In Urdu the app is الاسلام (الاذان، القرآن، الحدیث), and in a sentence "%@ ایپ", the name first, with
  feminine verbs (ایپ ... استعمال کرتی ہے).

- **Indonesian, Malay, Turkish, French, Bangla, Russian, Hindi, German, Spanish, Malayalam, Tamil and Dutch keep
  the Latin names**: the app is Al-Islam (Al-Adhan, Al-Quran) in a
  sentence and on the home screen, surahs keep the app's transliteration (Al-Baqarah), and only the surah's
  MEANING is translated, through one catalog key per surah: `Surah.localizedMeaning` reads
  `surah.meaning.<id>` ("Sapi Betina", "İnek"), and the surah search matches it too. `nameEnglish` stays for
  search, the model and the English share cards. Bangla, Russian, Hindi, Malayalam and Tamil write people, books
  and riwayat in their own script (Сахих аль-Бухари, হাফস, इब्ने कसीर, ഇബ്നു കസീർ, இப்னு கஸீர்) but keep the Latin surah names and letter-card names in sentences, so a
  reader can find them in the surah list and on the letter cards.

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

Malay and Turkish have their own (2026-11-19), French, Russian, German and Spanish too (2026-11-20), and Dutch
(2026-11-21). Indonesian, Bangla, Hindi, Malayalam and Tamil have none, like Urdu: Siri has none of them (Apple's
feature availability lists Malaysia (Malay), Türkiye, France, Russia, Germany, Spain and the Netherlands, not
Indonesia or Bangladesh, and India with English only). `AppLanguage.siriSpeaksInterfaceLanguage` is false for
all six, and the two tips that quote Siri phrases then
quote the English ones with the name Siri hears.

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

`todo`, `validate`, `merge`, `check` and `sibling` take `--lang ar|ur|id|ms|tr|fr|bn|ru|hi|de|es|ml|ta|nl` (Arabic
is the default). An Urdu batch carries each key's Arabic as `arabic`, the reference for its sense and for the Islamic
term chosen; a batch in any other language carries it for keys of six words or fewer, where the sense can be in
doubt. A new language's first pass is `todo DD OUTDIR --like-ar --words 8000`: exactly the keys Arabic has,
in batches of about 8,000 English words, each key with the files that show it.

Sync only after a build of the whole scheme, and read its report: a long-lived DerivedData (`build/DerivedData`)
keeps `.stringsdata` that no longer speak for the code, and on 2026-10-26 a sync there "revived" 462 dead keys.
`extracted()` now ignores a stringsdata whose source file no longer exists (a file moved by the pbxproj
reorganisation left its old one behind under the old path) and reads one configuration only, the one built most
recently (a Release build from September sat beside today's Debug build and carried 35 keys the code had lost);
it prints which configuration it took. A report with hundreds revived or marked stale is the trap, not the code:
restore the catalog and look at the DerivedData before translating anything. (A stringsdata's age against its
source is NOT a usable test: an incremental build leaves an unchanged file's stringsdata older than a source whose
mtime moved without a content change, and that rule marked 758 live keys stale.)

A translation file is `{english key: translation}`; a key with exactly one integer argument may map to an object
of plural forms (Arabic `one`, `two`, `few`, `many`, `other`; Urdu `one`, `other`; optional `zero` in both).
The validator rejects mismatched placeholders, leftover English words, em dashes and changed `${parameter}`
tokens, and in Urdu Arabic letter forms, Eastern digits and a Latin full stop. In Indonesian, Malay and Turkish
every word is Latin, so it looks for English instead (`latin_problems`): a value identical to a key that holds
an English function word, an English function word left outside quotes and outside a Title Case name the key
spells the same way ("The Clear Quran"), Eastern digits, and a lost edge space (" of ", "Contact: ": the Write
tool of a translating agent strips trailing spaces). `ENGLISH_WORDS` leaves out words those languages share
(Turkish "on" ten, "an", "at", "can", "not"; `NOT_ENGLISH` adds Turkish "her" and "his"). A Latin word may stay only when
the key has it too and it is a letter or two or quoted (the alphabet lessons compare letters with English
words: «مثل حرف b في “book”»). Keys whose every source is an article file (`ARTICLE_SOURCES`) are never offered
for translation, nor a key marked `shouldTranslate: false` (an email address).

French, German, Spanish and Dutch use the same English check (`NOT_ENGLISH` adds German "will", "was", "also",
"her", Spanish "has" and Dutch "is", "of", "over", "was", "been", words of those languages, and a value identical
to its key is judged by the same list; German „…“ counts as a quote). Bangla, Russian, Hindi, Malayalam and Tamil
run it too, then `script_problems`: a value with no
Bengali or Cyrillic letter while the key holds an English dictionary word (`/usr/share/dict/words`, so a
lesson's transliteration, "kufuwan", may stay Latin), a Latin look-alike letter inside a Cyrillic word,
Bengali digits (the app writes 0-9; Apple's Bangla formats numbers in them too), and a Latin full stop where
Bangla and Hindi write the danda (Devanagari, Malayalam and Tamil digits are rejected like Bengali ones;
Malayalam and Tamil end a sentence with the Latin full stop), and, since 2026-11-21, an Arabic run of the key
that is not in the value byte for byte (the Latin-script check always had it; the script languages had
skipped it). In Russian, French, German, Spanish, Hindi, Dutch, Malayalam and Tamil a plain string that puts a
count before an agreeing noun ("%lld аятов", "%lld versets", "%lld Verse", "%lld aleyas", "%lld आयतें", "%lld
verzen", "%lld ആയത്തുകൾ", "%lld வசனங்கள்") is rejected: it needs plural forms (Russian one, few, many, other;
the others one, other). Dutch lets a count stand before a unit that stays singular (keer, uur, jaar, procent)
and before a verb or "een". Every
language: arguments of different types that change order must be numbered (%1$@, %2$lld), and a lone "%"
the key does not have is rejected (a format string writes %%).

A key the code shows AND the tajweed pack shows as data can mean two things: "Light" is the Color Theme
choice and a light letter (مرقّقة), "Merge" a backup choice and idgham, "Article" an Ask AI source and the
definite article. The code side then takes a dotted key of its own (`appearance.light`, `backup.merge`,
`askai.article`, `dhikr.count.one`) and the plain key stays the pack's, marked `manual`. The same goes for
two code senses: "Madani" is the Medinan-surah filter (مدنية), so the script-style picker says
`script.madani` / `script.maghribi` (المدني beside المغربي). Short keys that
both show are worth checking after every pack harvest: the Tilawa harvest of 2026-10-25 had overwritten the
Arabic of "Surah" (الموضع), "Note" (تنبيه), "Noun" and "Verb" with their senses in one lesson table.

Data shown through `.localizedDisplay` needs its English registered as a manual key. The tajweed course is the
big one: its 58 lessons live in `Resources/Data/Quran/TajweedLessons.json.xz`, and every field the course shows
is a manual key, so rebuilding that pack with different English needs those keys again.

Tilawa (the sister React Native app) carries Arabic for much of the same content (its tajweed course, its UI
dictionary): align by position or by identical English before translating from scratch.

## Each extension's share

App Store Connect refuses a watch app over 75 MB after thinning (ITMS-90389). Xcode compiles every key of a
catalog into every target that carries it, so with one catalog for the whole app each language cost about
3 MB per target: twice on the watch (Watch.app and Complication.appex), where build 271 (4.6.7, 11 languages)
came to 95 MB and was refused on 2026-11-23, and once more for the Widget inside the iPhone app.

The Watch, Complication and Widget targets therefore end with a Run Script phase, "Trim Strings"
(`Scripts/trim_strings.py`), that compiles a copy of the catalog holding only the keys the target can reach
and puts its Localizable.strings and Localizable.stringsdict in place of the full ones. A key is kept when the
compiler extracted it from that target's own Swift files, when one of them (or the Adhan package) holds it as
a plain string literal (a prayer name, an enum's raw value shown through `.localizedDisplay`), when it matches
an interpolated literal there (`"surah.meaning.\(id)"`), and, for the Watch app only, when it is a manual
key: the Watch ships the tajweed course, surah info, the Names and the hadith quotes and shows their text
through `.localizedDisplay`. Literals inside branches the target does not compile (`#if os(iOS)` on the watch,
a compilation condition the target lacks) are left out of the scan; a condition the script cannot decide
(`canImport`) counts as compiled. The catalog itself is never changed, and translating needs no extra step:
the next build trims the new translations too. The iPhone app keeps the whole catalog.

The tajweed course is the one data source cut by field. The watch's lesson page (`TajweedLessonWatchView`)
shows titles, summary, definition, rule card, letter sets, body, word groups, key points and the mistakes'
wrong and right forms; the examples, quizzes, the mistakes' "why", tables, drills, images, rule-card
fragments, mnemonics, counts, chapter subtitles and stage blurbs stay on the phone, so the Watch leaves their
text out (`WATCH_HIDDEN_COURSE_FIELDS`, sentences of 16 characters or more only). The build FAILS if watch
code that touches the course reads one of those fields (`lesson.quiz`, `card.fragments`): take the field out
of that list and its translations ship again.

Measured 2026-11-23 with 14 languages: the Watch app keeps 7,091 of 14,195 keys (25.8 MB of tables instead of
44.4 MB), the Complication 1,230 (2.1 MB), the Widget 1,485 (2.6 MB), and the thinned watch app comes to about
54 MB of the 75. Every string a target's code extracts keeps all its translations. Each new language adds
about 1.9 MB to the watch app and about 3.3 MB to the iPhone app.

What this means when writing extension code:
- A literal the extension shows is kept automatically, wherever its key came from.
- A key built at runtime from pieces with no literal behind it ("\(prefix).\(suffix)") is not: give it a
  literal pattern in a file that target compiles, or (watch) register it as a manual key.
- `./Scripts/trim_strings.py --report --objects <the target's Objects-normal> --conditions "<its
  SWIFT_ACTIVE_COMPILATION_CONDITIONS>" [--with-data-keys [--watch-course]]` prints what a build would keep.
  The phase needs `SWIFT_EMIT_LOC_STRINGS = YES` (it reads the compiler's `.stringsdata`) and script
  sandboxing off in the three targets (it reads the sources); it fails the build, rather than ship the full
  tables, when it finds no `.stringsdata`.

## Indonesian, Malay and Turkish

Since 2026-11-19, the whole interface the Arabic has, from the same catalog (`--lang id|ms|tr`). All three
are written left to right in the Latin script, so nothing mirrors; the work is in the words.

| English | Indonesian | Malay | Turkish |
| --- | --- | --- | --- |
| Settings (tab) | Pengaturan | Seting | Ayarlar |
| Quran / Hadith / Adhan / Islam (tabs) | Al-Qur'an / Hadis / Azan / Islam | Al-Quran / Hadis / Azan / Islam | Kur'an / Hadis / Ezan / İslam |
| prayer | salat | solat | namaz |
| Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | Subuh, Terbit, Zuhur, Asar, Magrib, Isya | Subuh, Syuruk, Zohor, Asar, Maghrib, Isyak | Sabah, Güneş, Öğle, İkindi, Akşam, Yatsı |
| surah, ayah, juz | surah, ayat, juz | surah, ayat, juzuk | sure, ayet, cüz |
| tajweed, qibla, dua | tajwid, kiblat, doa | tajwid, kiblat, doa | tecvid, kıble, dua |

- Indonesian follows KBBI and Apple's Indonesian ("Anda"); Malay is Malaysian Malay as JAKIM and Apple's
  Malay write it ("anda", "solat", "muat turun"), never Indonesian; Turkish follows the Diyanet and Apple's
  Turkish (the polite "siz").
- Turkish Fajr is "Sabah", the prayer's own name, not Diyanet's "İmsak": the same key names the prayer in
  the tracker and the notifications, where İmsak (the time fasting starts) would be wrong.
- Turkish attaches case endings by vowel harmony, which a `%@` cannot know: translations rephrase instead
  ("Konum: %@", "%@ için"), and "Surah %@" is "%@ Suresi". A percent sign goes before the number ("%%%lld").
- Plurals: Indonesian and Malay never inflect a noun for its number, and Turkish keeps it singular after one,
  so nearly every plural key is a plain string (`merge` writes `{"other": x}` as one).
- Digits are Western in all three; numbers and dates come from the locale (Turkish and Indonesian write
  "1.234,5"). The Hijri line beside the Arabic date is the locale's own long Hijri date ("12 Jumadilakhir
  1448 H", "Hicri 12 Cemaziyelahir 1448"), whose month names are those languages', not the app's English
  transliterations; `HijriDate.language` makes a language change recompute it the same day, and the
  widgets' Latin Hijri pieces follow the same locale (`AdhanWidgetDateFormatting.latinLocale`).
- How they were made: 13,466 keys per language, translated by parallel agents from one brief and a glossary
  per language, with the app's 331 labels that other strings name (feature names, settings rows, quoted
  buttons) fixed first so every sentence quotes a control exactly as it reads. Machine translation: each
  language needs a fluent reviewer before release.

## French, Bangla and Russian

Since 2026-11-20, the same coverage (`--lang fr|bn|ru`, 13,589 keys each). All three read left to right, so
they take the English layout like Indonesian, Malay and Turkish; Bangla and Russian are the first interface
languages in a script of their own besides Arabic.

| English | French | Bangla | Russian |
| --- | --- | --- | --- |
| Settings (tab) | Réglages | সেটিংস | Настройки |
| Quran / Hadith / Adhan / Islam (tabs) | Coran / Hadith / Adhan / Islam | কুরআন / হাদীস / আযান / ইসলাম | Коран / Хадисы / Азан / Ислам |
| prayer | prière | নামাজ (salah: সালাত) | намаз |
| Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | Fajr, Lever du soleil, Dhuhr, Asr, Maghrib, Isha | ফজর, সূর্যোদয়, যোহর, আসর, মাগরিব, এশা | Фаджр, Восход, Зухр, Аср, Магриб, Иша |
| surah, ayah, juz | sourate, verset, juz | সূরা, আয়াত, পারা | сура, аят, джуз |
| tajweed, qibla, dua | tajwid, qibla, invocation | তাজবীদ, কিবলা, দোয়া | таджвид, кибла, дуа |

- French follows Apple's French: "vous", sentence case, a no-break space before : ; ? ! and inside « »,
  the curly ’. Russian follows Apple's Russian: lowercase "вы", sentence case, «» quotes, е for ё; the dash
  Russian puts between subject and predicate before "это" is rephrased ("X означает Y"), never written. Bangla follows Bangladeshi Muslim
  usage (নামাজ, রোজা, অজু, পারা for juz) in Bangla Academy spelling, with the danda । and Western digits
  (Apple's Bangla formats numbers in 0-9 too).
- Plurals: Russian takes one / few / many / other on every count beside a noun (the validator rejects a
  plain "%lld аятов"); French takes one / other ("one" covers 0 and 1); Bangla never inflects (a plain
  string, often with the classifier টি).
- Names: French keeps every Latin name; Bangla and Russian write people, books and riwayat in their script
  (Сахих аль-Бухари, Ибн Кясир; হাফস, ইবনে কাসীর) as the labels fixed them. Surah names and letter-card
  names stay Latin in all three (rule 7 of the translators' brief), but a letter named as a word in a
  lesson ("the noon") is Bangla or Cyrillic (নূন, нун), from a fixed list per language.
- Siri: French and Russian have phrase files; Bangla has none (no Siri), so its tips quote the English
  phrases like Indonesian and Urdu.
- How they were made: as Indonesian, Malay and Turkish (labels first, then 19 batches per language, then a
  consistency review per language), with three validator additions this round: arguments of different
  types that change order must be numbered, a lone "%" is rejected, and Bangla/Russian get `script_problems`
  (see the catalog section). Machine translation: each language needs a fluent reviewer before release.

## Hindi, German and Spanish

Since 2026-11-20, the same coverage (`--lang hi|de|es`, 13,623 keys each). All three read left to right and take
the English layout.

| English | Hindi | German | Spanish |
| --- | --- | --- | --- |
| Settings (tab) | सेटिंग्ज़ | Einstellungen | Ajustes |
| Quran / Hadith / Adhan / Islam (tabs) | क़ुरआन / हदीस / अज़ान / इस्लाम | Koran / Hadith / Adhan / Islam | Corán / Hadices / Adhan / Islam |
| prayer | नमाज़ | Gebet | oración |
| Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | फ़ज्र, सूर्योदय, ज़ुहर, अस्र, मग़रिब, इशा | Fajr, Sonnenaufgang, Dhuhr, Asr, Maghrib, Isha | Fajr, Salida del sol, Dhuhr, Asr, Maghrib, Isha |
| surah, ayah, juz | सूरह, आयत, पारा | Sure, Vers, Juz | sura, aleya, juz |
| tajweed, qibla, dua | तजवीद, क़िबला, दुआ | Tajwid, Qibla, Dua | tajwid, qibla, dua |

- Hindi is written the way Indian Muslims write it: plain everyday Hindi, with every Islamic word the one Urdu
  uses, in Devanagari with the nukta (नमाज़, रोज़ा, वुज़ू, क़ुरआन; never प्रार्थना or उपवास). Each Hindi batch
  carried the reviewed Urdu beside the English as its reference. The nukta is stored as the base letter plus
  U+093C (Unicode NFC), never the precomposed letters; sentences end with the danda । and digits are Western
  (Apple's Hindi formats numbers in 0-9). People, books and riwayat are in Devanagari ("X an Y" is "Y से X":
  आसिम से हफ़्स; Ibn is इब्ने), surah and letter-card names Latin, and a letter named in lesson prose
  Devanagari from a fixed list (नून, मीम; ي is या (ي), since या alone means "or").
- German follows Apple's German: "du", sentence case with every noun capitalised, „…“ quotes, a no-break space
  before %. A placeholder cannot be declined, so no article or contraction goes before one ("Sure %@", never
  "der %@"); das Alif and das Madd, other letter names masculine, haa and taa lowercase where the app uses the
  case to tell ه from ح and ت from ط.
- Spanish is one neutral Spanish for Spain and Latin America (App Store Connect's Spanish (Spain) and Spanish
  (Mexico) both take it): "tú", ¿ ¡, no vosotros (a plural address is ustedes), Arabic terms in the app's Latin
  spelling (idgham, ikhfa, makhraj), «el alif» and the other letters feminine. No «de %@» or «a %@» where the
  argument can start with «el».
- Plurals: German, Spanish and Hindi take one / other on a count beside a noun (Hindi too: आयत / आयतें, and
  the oblique आयत में / आयतों में).
- Siri: German and Spanish have phrase files; Hindi has none (India's Siri is English), so its tips quote the
  English phrases.
- How they were made: as French, Bangla and Russian (labels first, 19 batches per language, a consistency review
  per language), with the term choices that settled mid-run last time fixed in each glossary up front.
  Machine translation: each language needs a fluent reviewer before release.

## Malayalam, Tamil and Dutch

Since 2026-11-21, the same coverage (`--lang ml|ta|nl`, 13,623 keys each). All three read left to right and take
the English layout.

| English | Malayalam | Tamil | Dutch |
| --- | --- | --- | --- |
| Settings (tab) | ക്രമീകരണം | அமைப்புகள் | Instellingen |
| Quran / Hadith / Adhan / Islam (tabs) | ഖുർആൻ / ഹദീസ് / ബാങ്കുവിളി / ഇസ്ലാം | குர்ஆன் / ஹதீஸ் / பாங்கு / இஸ்லாம் | Koran / Hadith / Adhan / Islam |
| prayer | നിസ്കാരം | தொழுகை | gebed |
| Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | സുബ്ഹ്, ഉദയം, ളുഹ്ർ, അസ്ർ, മഗ്രിബ്, ഇശാ | ஃபஜ்ர், சூரிய உதயம், லுஹர், அஸர், மஃரிப், இஷா | Fajr, Zonsopkomst, Dhuhr, Asr, Maghrib, Isha |
| surah, ayah, juz | സൂറത്ത്, ആയത്ത്, ജുസ്അ് | சூரா, வசனம், ஜுஸ்உ | soera, vers, juz |
| tajweed, qibla, dua | തജ്വീദ്, ഖിബ്ല, ദുആ | தஜ்வீத், கிப்லா, துஆ | tajweed, qibla, dua |

- Malayalam is written as Kerala's Muslims write it (Samastha usage: നിസ്കാരം, സുബ്ഹ്, ض and ظ as ള in
  ളുഹ്ർ and വുളൂഅ്), in Apple's polite -ൂ imperative (ടാപ്പ് ചെയ്യൂ). The Adhan tab is ബാങ്കുവിളി, because a
  bare ബാങ്ക് also spells "bank"; sentences say ബാങ്ക്. Chillu letters are the atomic code points and the text
  has no zero-width joiners. A settings screen is the singular ക്രമീകരണം.
- Tamil is written as Tamil Muslims write it (தொழுகை, பாங்கு, வசனம்; Grantha letters ஜ ஷ ஸ ஹ and the aytham
  for f and z sounds; ض ظ as ள in லுஹர்), in Apple's -வும் form for instructions (தட்டவும்). Khatm is கத்ம்,
  never கத்தம், which Tamil Muslims use for recitation for the dead; the madd of compensation is always
  மத்துல் இவள், since a bare இவள் reads "she".
- Both name people, books and riwayat in their own script ("Hafs an Asim" is "Hafs from Asim": ആസ്വിമിൽ
  നിന്നുള്ള ഹഫ്സ്, ஆஸிமிடமிருந்து ஹஃப்ஸ்), keep surah and letter-card names Latin, write a letter named in
  lesson prose from a fixed list with the Arabic letter beside it where the script cannot tell two apart (ഹാ
  (ه) and ഹാ (ح), காஃப் (ق) and காஃப் (ك)), end a sentence with the Latin full stop and write digits 0-9. A
  case ending is never glued to `%@` or to a bare Arabic letter: a noun carries it ("%@ എന്ന സൂറത്തിൽ").
- Dutch follows Apple's Dutch: "je", sentence case, the imperative on verb-led buttons ("Voeg notitie toe",
  "Stel alle instellingen opnieuw in"), “…” quotes. Arabic terms keep the key's transliteration (wudu, sunnah,
  sukoon, tajweed); only established Dutch words replace it (Koran, soera, vers, profeet, hadj, djinn).
  Nagging Mode is Zeurmodus.
- Plurals: all three take one / other on a count beside an agreeing noun (Dutch verzen, Malayalam -കൾ, Tamil
  -கள்); a unit that stays singular after a number takes a plain string.
- Siri: Dutch has phrase files; Malayalam and Tamil have none (India's Siri is English), so their tips quote
  the English phrases and say to say them in English.
- The tip-search hints ('"adhan", "qibla" or "widget"' and its siblings) are written in the interface
  language in every language: the tips search reads the displayed text, so an English example finds nothing
  in a translated interface (Hindi, German and Dutch were corrected 2026-11-21).
- How they were made: as Hindi, German and Spanish (a glossary per language first, then labels, 19 batches per
  language and a consistency review per language). Machine translation: each language needs a fluent reviewer
  before release.

## Al-Adhan and Al-Quran

The siblings get their languages from the sync (`~/Downloads/Islam/sync_from_islam.sh`, Docs/Engineering/Sibling
Sync Guide.md). The code (`Localization.swift`, every `String(localized:)`) merges like any shared file. The
rest is `../sync_localization.py`'s, a pass of the sync that can also run alone:

| Sibling file | Where it comes from |
| --- | --- |
| `Resources/Localizable.xcstrings` | Al-Islam's, copied whole on every sync (`L10N_MIRROR`): all translation happens here |
| `Resources/InfoPlist.xcstrings` | written per app (`L10N_DERIVED`): the keys its Info.plist declares, its own English, this catalog's translations with the app's name swapped (الأذان، القرآن, "تطبيق %@" in an Arabic sentence; الاذان، القرآن, "%@ ایپ" in Urdu; Al-Adhan, Al-Quran as they are in the Latin-name languages) |
| `Resources/<lang>.lproj/AppShortcuts.strings`, `Resources/Watch/<lang>.lproj/AppShortcuts.strings` (ar, ms, tr, fr, ru, de, es, nl) | written per app and target: only the phrases its `AppShortcutsRoot` compiles under its flags (Al-Adhan the prayer phrases, Al-Quran the surah ones), since an unused phrase is a build warning |
| the project | Al-Islam's languages in knownRegions, `STRING_CATALOG_GENERATE_SYMBOLS = NO` (Al-Quran's Widget overrides it too), and the files above registered in the targets Al-Islam's are in |

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
  wait in `~/Downloads/Islam/sibling-staging/<App>-iOS/Docs/Urdu Listing.md`. Indonesian, Malay and Turkish
  likewise: `Docs/App Store/<Language> Listing.md` and the siblings' in sibling-staging.
- Indonesian, Malay and Turkish (2026-11-19), French, Bangla, Russian, Hindi, German and Spanish (2026-11-20)
  and Malayalam, Tamil and Dutch (2026-11-21) are machine-translated and need fluent reviewers too. Their store listings: `Docs/App Store/<Language>
  Listing.md`, the siblings' in sibling-staging. Search
  keeps English in two places, and the help text says so: search by meaning reads English phrases, and the
  Quran search's typed keywords ("page 5", "juz 30", "makki") are English words.
- The 99 Names' meanings, the hadith and Quran translations, and hadith chapter titles stay English in every
  Latin-script language, as they do in Arabic and Urdu.
