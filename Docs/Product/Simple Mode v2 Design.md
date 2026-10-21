# Simple Mode v2: the trim catalog

Design agreed with Abu on 2026-10-20. The first build (Docs/Product/Simple Mode Guide.md, 2026-10-10/11) made Simple Mode real; this pass rethinks what it hides on every screen and restructures the code so one named catalog drives every site. Read the guide first for the rules and their reasons; this document is the delta, and the plan built from it is `Docs/Product/Simple Mode v2 Plan.md`.

## 1. What is wrong today

- The trims live in about sixty `simpleMode` reads across seventeen files, written three ways: `settings.simpleMode` on an observed `Settings`, a local `@AppStorage("simpleMode")` in the watch-shared helpers, and an unobserved `Settings.shared.simpleMode` in two places. Nothing names a trim, so nothing can prove that every hidden thing still has a door.
- The guide's tables are hand-written and drift: it describes the Islam tab in Simple as three sections where the app shows one; the Advanced switch comments say "eleven screens" where there are nine.
- Gaps found in the survey: a traveler in Simple cannot switch between full and Qasr prayers (the only toggle is in the hidden travel footer); the Islam tab has no door to Today once the card pills hide; the page reader still offers "Search the whole Quran" while the list reader's Global button hides; a dozen hand-built count pills bypass the one gated header.
- Settings pages, the Islam destinations and the play menus never read the switch at all.

## 2. Decisions from the brainstorm

| Question | Answer |
|---|---|
| What "full refactor" means | Both: rethink what Simple hides on every screen, and restructure the code so one catalog drives every site. |
| Reach | Everything but sheets: tab roots, readers, Settings pages, Islam destinations, the play menus. Sheets and press-and-hold menus stay complete. |
| Depth | Calm, keep every section: no section moves or folds beyond what Simple does today. Trim details inside (chips, captions, counts, menu items, pills) and fix the gaps. |
| Code shape | A named trim catalog (`enum SimpleTrim`), one read API, a door for every case proven by a unit test, a script that proves every case is used, and a Simple Mode page generated from the catalog. |

## 3. Rules

The guide's rules stay in force; two are sharpened and one is added.

1. Hiding never changes what the app does.
2. A control stays visible while its value is off its default (the sort row, the riwayah picker, the Legend, Test Mode's menu rows while Test Mode is on).
3. An only door moves (the tab's ⋯ menu or Settings) instead of vetoing a trim; a short list of details is dropped outright.
4. Never hidden: what the user made, how scripture is shown, search, play, the gear, the prayer bells, press-and-hold menus and sheets, attribution footers, BETA badges, safety captions (Ask AI's caution line).
5. No new behaviour key. Simple adds no `@AppStorage` key; the catalog is code.
6. An Equatable row whose body reads a trim folds `simpleMode` into its signature (`ayahRenderSettingsSignature` already does).
7. iPad and Mac follow the same rules; the watch never receives the flag and stays Full; the companion apps get the catalog file at the next sibling sync.
8. **Counts are details.** Every count pill, capsule or bare number on a section header or a row is dropped in Simple, through one gate. Exceptions, because they are feedback rather than decoration: the locator's "N matches found", the Tasbih tiles (the user's own numbers), "Lesson N of M", and Listen All pills (play).
9. **Simple acts once, at the moment it is turned on:** it turns every settings screen's Show Advanced Settings switch off. That is the single place Simple does something other than hide, and the Simple Mode page says so. Turning Simple off restores nothing (rule 5: no memory, no key); each screen's ADVANCED switch is one flip away in both modes.

## 4. Architecture

### 4.1 The catalog file

`iPhone/Settings/Model/SimpleTrims.swift`, registered like `SettingsAdhan.swift` (iPhone, Watch, Widget, Complication), so no site needs `#if os(iOS)` just to name a trim. It holds:

- `enum SimpleMode` (the tracker window, the nag snooze, `markedRecently`, `isSnoozed`), moved out of `SettingsAdhan.swift` unchanged, with its tests.
- `enum SimpleTrim: String, CaseIterable`: one case per hideable thing. The cases are listed in section 5.
- `enum SimpleTrim.Surface: String, CaseIterable`, in the order the Simple Mode page lists them: `everywhere`, `adhan`, `quran`, `listReader`, `pageReader`, `playback`, `hadith`, `hadithBook`, `hadithReader`, `islam`, `destinations`, `settings`. Each has a `title` ("Every tab", "Adhan", "Quran tab", "List reader", "Page reader", "Play menus", "Hadith tab", "Hadith book", "Hadith reader", "Islam tab", "Islam destinations", "Settings").
- `enum SimpleTrim.Door`: `.moreMenu(String)` (the item's name in the tab's ⋯ menu), `.settings(String)` (a path, "Prayer Settings › Optional Prayers"), `.longPress(String)` (the menu item), `.elsewhere(String)` (where it is), `.dropped`. `text` renders each for the page: "⋯ menu › Today", "Settings › Prayer Settings › Optional Prayers", "Press and hold › Favorite", the place, "Dropped".
- `struct SimpleTrim.Entry { let trim: SimpleTrim; let surface: Surface; let title: String; let door: Door }` and `static let entries: [Entry]`, **one entry per line** in the form `Entry(.needAHand, surface: .everywhere, title: "...", door: .settings("..."))`. The script parses these lines; the unit test proves `entries` covers `allCases` exactly once. `SimpleTrim.entry` looks a case up; `SimpleTrim.bySurface` groups for the page.

### 4.2 Reading a trim

Three idioms replace the three in use today; no site reads `simpleMode` directly any more except the ones the script allows (the property itself, the render signature, the Simple Mode toggle, the splash and welcome pages, CloudManifest, StressWalker, the tests).

- `settings.hides(.atAGlance)` on a view that already observes `Settings` (`@ObservedObject settings = Settings.shared`). Body: `simpleMode`.
- `settings.hides(.playTestMode, unless: testMode.isOn)` for rule-2 sites. Body: `simpleMode && !keep`. Both live in an extension of `Settings` inside the catalog file.
- `.hiddenInSimple(.needAHand)` and `.hiddenInSimple(.sectionCounts, unless: keep)` as a view modifier for pure-hide sites and the watch-shared helpers (`SectionPillHeader`, `GridFavoriteStar`, `CountPill`). The modifier owns an `@AppStorage("simpleMode")` so it re-renders on the flip without observing every setting, which is why those helpers used a local `@AppStorage` before.

Menu trims are cases too, read with `hides(...)` inside the menu builder. The trim argument is documentation and the script's hook; the functions do not switch on it.

### 4.3 What the catalog proves

- `UnitTests/SimpleTrimCatalogTests.swift`: every case has exactly one entry; every title is unique and non-empty; every non-dropped door's text is non-empty; every surface has at least one entry; `bySurface` follows `Surface.allCases`. Registered like `TipsCatalogTests.swift` (the UnitTests target is not synchronized).
- `Scripts/check_simple_trims.py` (modelled on `check_cloud_manifest.py`): parses the `Entry(` lines; for each case, greps `iPhone/`, `Apple Watch/`, `Widget/`, `Complication/` for `hides(.name` or `hiddenInSimple(.name` and exits 1 naming any case no site reads. It also exits 1 naming any raw read of the flag outside the allow-list: a line matching `settings.simpleMode`, `Settings.shared.simpleMode` or `@AppStorage("simpleMode")`, except a `$settings.simpleMode` binding or an `.onChange(of: settings.simpleMode)`. The allow-list, by file: `Settings.swift` (the property), `SettingsQuran.swift` (the render signature), `SimpleTrims.swift`, `SettingsView.swift`'s `SimpleModeSection`, `SplashScreen.swift` and `WelcomePages.swift` (they set it), `CloudManifest.swift`, `StressWalker.swift`, `TipsAndTricks.swift` (the tips filter), and the test targets. `--list` prints case, surface, title, door and the files that read it; `--write-guide` regenerates the catalog table in `Docs/Product/Simple Mode Guide.md` between `<!-- simple-trims:begin -->` and `<!-- simple-trims:end -->` markers, and the plain run fails if that block is stale. The plan's last task runs it; `Scripts/qa` runs it with the other checks.
- The existing `UnitTests/SimpleModeTests.swift` and `UITests/SimpleModeUITests.swift` keep passing (same key, same identifiers, same `-seedBool simpleMode=1`).

### 4.4 The Simple Mode page

`SimpleModeSettingsView` becomes: the SIMPLE MODE section (the toggle and a one-sentence caption), then one section per surface titled by `Surface.title`, each row a trim's title with its door in secondary text, then a footer with the rule-9 sentence and the never-hidden sentence. The root's SIMPLE MODE section keeps its toggle, the one-sentence caption, and gains a "What Moves Where" row that pushes the page. Copy is in section 7.

### 4.5 Unchanged

The one `simpleMode` key and its iCloud class; `-seedBool simpleMode=1`; `TabMoreMenu` leading every tab root in both modes with the gear in its trailing slot; the splash's second step; the "Too Much on Screen?" door; the tips' `outsideSimpleMode` gate (it filters tips rather than hiding a control, so it keeps its raw read and sits on the script's allow-list); the nag snooze and the tracker window.

## 5. The catalog

A snapshot of `SimpleTrim.entries` as designed on 2026-10-20. The guide carries the generated copy (section 4.3), which is the one to trust once the code exists.

| Case | Surface | Hidden in Simple | Door |
|---|---|---|---|
| needAHand | everywhere | NEED A HAND? on every tab | Settings: each card's setting is a row on its own settings page |
| sectionCounts | everywhere | Count pills and capsules on section headers and rows | Dropped |
| sectionSearch | everywhere | The search glyph on BOOKMARKS and FAVORITES headers | Elsewhere: search's Bookmarks and Favorites filters |
| sectionShuffles | everywhere | Shuffle buttons on section headers | Dropped |
| outlineStar | everywhere | The outline star on a tile that is not a favorite | Press and hold: Favorite |
| historyExpanders | everywhere | The +/− history buttons on YOUR SUMMARY | Dropped |
| heroStats | everywhere | The figures on a resource's hero card | Dropped |
| quickSearchHelp | everywhere | Quick Search Help's examples on the Quran and Hadith tabs | Elsewhere: Tips & Tricks; the recent-search chips stay |
| optionalTimes | adhan | The Optional Times pill | Settings: Prayer Settings › Optional Prayers |
| dateStepper | adhan | The Showing prayers for date stepper, with Compare Today | ⋯ menu: Prayer Calendar |
| atAGlance | adhan | AT A GLANCE | Elsewhere: the date row, the location pill, the sky's moon and the city pill; the figures are dropped |
| prayerTracker | adhan | PRAYER TRACKER until a prayer is marked within 14 days | Settings: Prayer Settings › Prayer Tracker; marking a prayer from its detail brings it back |
| travelFooter | adhan | The travel footer under the prayer list | Elsewhere: the traveling banner, which opens Travel Settings |
| calendarFootStepper | adhan | The Hijri Calendar's second year stepper | Elsewhere: the stepper at the top of IMPORTANT ISLAMIC DATES |
| quranTodayPill | quran | The Today pill on the Quran tab's YOUR SUMMARY | ⋯ menu: Today |
| lastListenedTiles | quran | The Last Listened Ayah and Surah tiles | Elsewhere: the play menu's Play Last Listened Surah |
| wordOfDayTile | quran | The Word of the Day tile | ⋯ menu: Word of the Day |
| surahShuffle | quran | The SURAHS shuffle | ⋯ menu: Open a Random Surah |
| sortRow | quran | The sort row, while the sort is surah ascending | ⋯ menu: Sort |
| topSurahPair | listReader | The top Previous/Next surah pair | Elsewhere: the bottom pair |
| ayahPlayMenu | listReader | The ▶ menu on each ayah | Elsewhere: the ayah ⋯ menu's Play This Ayah; More Actions… for the rest |
| ayahLongMenu | listReader | The long ayah ⋯ menu | Elsewhere: five actions plus More Actions…, which opens the full actions sheet |
| translationCaption | listReader | The default translation's name under the translation | Dropped |
| pageJuzLine | listReader | The pinned page/juz line | Elsewhere: the inline page and juz dividers |
| globalSearch | listReader | The Global button in the controls row | Elsewhere: the Quran tab's search |
| legendPill | listReader | The Legend pill while nothing on the page is coloured (both readers) | Settings: Quran Settings › Arabic Text for tajweed, Highlight Themes for themes |
| mushafMeters | pageReader | The footer's meters, percentages and progress bar | Dropped |
| findWholeQuran | pageReader | Search the whole Quran in the find bar | Elsewhere: the Quran tab's search |
| playRandomAyah | playback | Play Random Ayah in the Quran tab's play menu | Dropped |
| playOtherOptions | playback | Other Options in the readers' play menus | Elsewhere: Play Custom Range is the play button's hold; repeats live in that sheet; the random picks are dropped |
| playTestMode | playback | Test Mode in the readers' play menus, while Test Mode is off | Settings: Quran Settings › Test Mode |
| hadithTodayPill | hadith | The Today pill on the Hadith tab's YOUR SUMMARY | ⋯ menu: Today |
| bookStats | hadith | A book's stats and era lines on the tab | Elsewhere: the book's own screen |
| chapterStats | hadithBook | The CHAPTERS header's pills, each chapter's count and range | Elsewhere: the reading screen's chapter header |
| topChapterPair | hadithReader | The top Previous/Next chapter pair | Elsewhere: the bottom pair |
| foldedGroups | islam | TOOLS, SIGNS & PROOFS and ASK AI | Elsewhere: the More Resources row |
| prophetQuote | islam | The Prophet Muhammad ﷺ quote card | Dropped |
| appsSection | islam | AL-ISLAMIC APPS | Settings: the Settings tab's copy |
| cardTodayPills | islam | The Today pills on the Reminder of the Day and Dua of the Day cards | ⋯ menu: Today |
| dailyHubShuffles | destinations | The shuffle circles on the Ayah and Hadith of the Day | Dropped |
| spotlightCards | settings | The ONLY IN AL-ISLAM spotlight cards | Elsewhere: the All Tips & Tricks row |
| pageTipsRows | settings | The Tips & Tricks row on each settings page | Settings: All Tips & Tricks |
| pageHelpDoors | settings | NEED A HAND? on the settings pages | Dropped: the tab sections it controls are hidden too |

The `destinations` surface has one case of its own because every other destination trim is a shared one (`heroStats`, `sectionCounts`, `outlineStar`); the page still lists the surface so a reader looking for the Dua screen finds it.

## 6. Per-surface design

Each table lists what changes from today. Everything in section 5 not mentioned here carries over exactly as built.

### 6.1 Every surface

| Change | Detail |
|---|---|
| `sectionCounts` becomes one gate | `CountPill` hides itself in Simple (`.hiddenInSimple(.sectionCounts)`), so `SectionPillHeader`, `SurahsHeader`, `JuzHeader` and every `CountPill` caller are covered at once. Hand-drawn capsules and bare numbers adopt `CountPill` or the modifier: DUA COLLECTIONS header and row capsules, MATCHING DUAS, REMEMBRANCES OF ALLAH, Arabic family headers (the ⓘ stays), SPECIAL ARABIC LETTERS and ARABIC NUMBERS, ARABIC and SURAH SEARCH RESULTS, Miracles / Prophecies / Prophet Miracles category rows, Word of the Day's ROOT AND FORM, Browse by Theme topic rows, Hadith Topics lane headers and rows, Encyclopedia rows, the Journal's filter chips (the chip keeps its word, drops its number) and NOTES ON AYAHS AND HADITHS. Rule 8's exceptions stay. |
| `heroStats` | `ResourceHero` draws no stat chips in Simple. The Journal hero too. The Tajweed Course hero keeps its progress bar (the user's own progress). Tajweed Foundations' colour chips are a legend, not stats, and stay. |
| `quickSearchHelp` | Both tabs' overlay renders as if folded: the recent-search chips only, no title row, no −/+ and no trash. With no recents nothing shows. The stored fold and removal flags are untouched. |

### 6.2 Adhan

| Change | Detail |
|---|---|
| Gap fix: full or Qasr prayers while traveling | Settings › Prayer Settings › Traveling Mode gains a "Show Full Prayers" toggle row (the existing `travelingShowFullPrayers` key), under the Traveling Mode switch and shown only while it is on, in both modes. The footer's View Full / View Qasr button stays in Full. The banner's tap already opens Travel Settings, so the Simple door is banner → Show Full Prayers. `PrayerList`'s reset of the flag when traveling mode turns off is unchanged. |
| `calendarFootStepper` | In Simple, `CalendarView` draws the year stepper only at the top of IMPORTANT ISLAMIC DATES; the copy at the foot hides. "Go to This Year" stays with the top stepper. |
| Carried over | Optional Times, the date stepper, At a Glance, the tracker rule, the travel footer. |

### 6.3 Quran tab, both readers, the play menus

| Change | Detail |
|---|---|
| `playRandomAyah` | The tab's play menu in Simple: Choose Reciter, Play Random Surah, Play Last Listened Surah. |
| `playOtherOptions` | Both readers' play menus (`SurahView.playButton` and `MushafReader`'s page-mode play menu; the Now Playing bar's menu hosts Test Mode but no Other Options) drop the Other Options submenu in Simple. Play Custom Range keeps its hold shortcut on the play button in both modes; Repeat Surah lives in the Custom Range sheet's repeat rows; Play Random Ayah and Play Random Reciter are dropped. |
| `playTestMode` | The `QuranTestModeMenuSection` is absent from the play menus in Simple while Test Mode is off; while it is on, the section shows (rule 2) so Hide All Again and the switch stay reachable. Quran Settings › Test Mode turns it on in both modes. |
| `findWholeQuran` | The page reader's find bar drops its "Search the whole Quran" scope button in Simple; "Search this Page / Surah" stay. |
| Gap fix: the sort | The sort row is the sort's only home and Simple hides it while the sort is surah ascending, so a Simple reader could not change the sort at all. The Quran ⋯ menu gains a "Sort" submenu in both modes (system image `arrow.up.arrow.down`): the same mode buttons as the row's menu, a divider, then the direction choices the current mode supports, with a checkmark on the current one. The row keeps its rule-2 behaviour (`sortRow`, `unless:` any other sort or direction). |
| Carried over | The root's Today pill, tiles, shuffle and header details; the list reader's pair, menus, caption, pinned line and Global; the Legend's rule-2 behaviour in both readers (`legendPill`, with `TajweedLegendView`'s Simple caption reading the same case); the page reader's meters. |

### 6.4 Hadith

| Change | Detail |
|---|---|
| Counts | Topics lanes and rows, Encyclopedia rows: via `sectionCounts`. |
| Not trimmed | The per-hadith ⋯ menu (Bookmark, Add or Edit Note, Remove Note, Select Text, Copy, Share, Summarize with AI): every item is a feature and there is no actions sheet to move them to. The chapter tiles' outline stars already follow `outlineStar`. |
| Carried over | Today pill, book stats and era lines, chapter pills and ranges, the top chapter pair. |

### 6.5 Islam tab, destinations, Today

| Change | Detail |
|---|---|
| Gap fix: Today | The Islam ⋯ menu gains a "Today" item in both modes (parity with the Quran and Hadith menus), pushing the Daily Hub through the tab's existing door plumbing. `cardTodayPills`: the `DailyHubDoorLabel` buttons on the Reminder of the Day header and the Dua of the Day card hide in Simple. |
| `dailyHubShuffles` | The Daily Hub's two shuffle circles hide; the Dua of the Day's play button stays. |
| Destinations | Only `heroStats`, `sectionCounts` and `outlineStar` apply. Kept on purpose: the 99 Names and Arabic grid/list toggles, Show All Descriptions, the Arabic grouping menu, Ask AI's ⋯ and suggestion chips, Word of the Day's ACROSS THE QURAN stats, the Qiraat Explorer's slider menu, the locator's match line, credit footers, BETA badges, the Journal's prompt refresh. |
| Guide drift | The Islam tab in Simple is one ISLAMIC RESOURCES section (grouping by subject is the user's `islamGroupResources` choice); the guide's LEARN / REMEMBRANCE / FAITH wording goes. |

### 6.6 Settings

| Change | Detail |
|---|---|
| `pageTipsRows` | The "Tips & Tricks: N things that are easy to miss" row on the Prayer, Notifications, Quran, Hadith and Islam pages hides in Simple; the root's ONLY IN AL-ISLAM section keeps its All Tips & Tricks row, as today. |
| `pageHelpDoors` | `HelpDoorsSettingsSection` (the Show on the X Tab switch, its card list, the Quick Search Help switch) hides on every settings page in Simple. Its switches control sections Simple hides anyway. |
| Rule 9: the Advanced fold | `Settings.simpleMode` gains a `didSet` in the house style (`guard simpleMode, !oldValue else { return }`, as `travelingShowFullPrayers` guards) that calls a new `foldAllAdvancedSettings()`: `setAdvanced(screen, false)` for every `AdvancedScreen`. The flip comes from a Toggle action or the splash, never from a body, so the defaults writes are safe; a `-seedBool` launch writes the key directly and folds nothing, which the tests rely on. `revealAllAdvancedSettings`, `anyAdvancedSettings`, the search breadcrumb and `revealsAdvancedSettings` are unchanged; search still lands on an advanced control in Simple. The `AdvancedSettingsSection` caption adds one sentence while Simple is on and the switch is off: "Simple Mode turned this off; turn it on to see every option here." |
| The Simple Mode page | Section 4.4; copy in section 7. The spotlight cards keep their `spotlightCards` gate, now read through the catalog. |
| Not trimmed | The root's profile tiles and their captions, the hub captions, Appearance, Reset, Credits, the Notifications pages. |

## 7. Copy

Verbatim; the plan's tasks paste these.

- Root SIMPLE MODE caption, Simple on: "Each tab keeps to its essentials. Nothing is turned off; What Moves Where says where everything went."
- The same section on the Simple Mode page itself, Simple on: "Each tab keeps to its essentials. Nothing is turned off; the list below says where everything went."
- Root SIMPLE MODE caption, Simple off: "Keeps each tab to its essentials: shortcuts move into the ⋯ menu at the top or into Settings, and the extras step aside. Nothing is turned off."
- Root row: "What Moves Where", system image `list.bullet.rectangle`.
- Page section headers: `Surface.title` upper-cased with the surface's icon: everywhere `square.grid.2x2`, adhan `safari.fill`, quran `character.book.closed.ar`, listReader `list.bullet`, pageReader `book.pages`, playback `play.circle`, hadith `text.book.closed.fill`, hadithBook `books.vertical.fill`, hadithReader `text.alignright`, islam `moon.stars.fill`, destinations `rectangle.grid.2x2`, settings `gearshape.fill`.
- Page footer, first sentence: "Turning Simple Mode on also turns off Show Advanced Settings on every settings screen; each screen's ADVANCED switch brings its options back."
- Page footer, second sentence: "Sheets, press-and-hold menus, search, play, the gear, the prayer bells and everything you made never change."
- Traveling Mode row: title "Show Full Prayers", caption "Every prayer at its full time while traveling, instead of the shortened and combined Qasr list. You may still shorten and combine."
- Advanced caption while Simple holds it off: "Simple Mode turned this off; turn it on to see every option here."
- Islam ⋯ item: "Today", system image `sun.horizon.fill`.

## 8. Out of scope

Sheets (the planner, the actions sheet, the reciter picker, the custom range sheet) and press-and-hold menus stay complete. The hadith ⋯ menu stays whole. Search filter bars stay (the Bookmarks filter is a door). No section moves, folds or is renamed. No new `@AppStorage` key. The watch, CarPlay, widgets and the Control Center controls are untouched. The splash and welcome pages are untouched.

## 9. Verification

- `xcodebuild` Debug build of the iPhone scheme on the Claude sim (iPhone 17 Pro, BE079A6B-4C8A-4D8E-8BBA-EC38E9FA2E46) with `DEVELOPER_DIR` set; never judge a build through a pipe.
- `UnitTests/SimpleTrimCatalogTests` and `SimpleModeTests` green; `python3 Scripts/check_simple_trims.py` and `python3 Scripts/check_cloud_manifest.py` exit 0.
- A two-mode screenshot sweep of every surface with the launch-argument recipe (seed `simpleMode`, `travelAutomatic=0`, `quranPageMode=0`; `-launchTab…`, `-islamDestination …`, `-settingsOpen …`, `-playSurah n`), paired side by side and viewed: the Adhan tab while traveling, the Quran root with the search field focused, both readers' play menus open, the page reader's find bar, the Hadith Topics and Encyclopedia screens, Dua, Adhkar, Names, Arabic, Miracles, Word of the Day, Browse by Theme, the Daily Hub, each settings hub page and the Simple Mode page.
- The live flip: Simple turned on in Settings with a reader pushed and with the Dua screen pushed; every count, chip and menu takes its new shape without a relaunch.
- Rule 9 in a test: turning Simple on with two Advanced switches on leaves both off and every other default untouched; turning it off changes nothing. The existing `testFlippingSimpleModeWritesNothingElse` learns that the `advancedSettings_<screen>` keys are the one thing the flip may write.
- iPad: the Simple Mode page and one destination in the split layout.
- The sim ends in Full (`-seedBool simpleMode=0,travelAutomatic=1,quranPageMode=0`).
