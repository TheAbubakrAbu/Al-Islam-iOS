# Simple Mode v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move every Simple Mode trim behind one named catalog (`SimpleTrim`), add the trims and the three gap fixes Abu approved on 2026-10-20, and give the Simple Mode page a list of what moves where that is generated from that catalog.

**Architecture:** A new file compiled into all four targets holds `enum SimpleTrim` (one case per hideable thing, each with a surface, a title and a door), `Settings.hides(_:)` / `hides(_:unless:)` for views that observe Settings, and a `.hiddenInSimple(_:)` modifier for pure-hide sites and the watch-shared helpers. Every site that reads the raw flag today migrates to one of those three; a unit test proves the catalog's shape and a script proves every case is read by code and no site reads the raw flag again. The only non-hide is rule 9: turning Simple on folds every settings screen's Advanced switch off.

**Tech Stack:** SwiftUI (iOS 16 floor for Al-Islam, siblings on iOS 15), XCTest (hosted UnitTests, XCUITest UITests), Python 3 scripts under `Scripts/`, hand-maintained project.pbxproj.

**Spec:** `Docs/Product/Simple Mode v2 Design.md`. Read it first, then `Docs/Product/Simple Mode Guide.md` for the rules and the first build. The spec's section 5 is the catalog this plan types in; its section 7 is the copy, verbatim.

## Global Constraints

- No `git commit`, `git push` or any history-mutating git command (Abu's global rule). Every task ends with the change left uncommitted and a progress-log line in the guide.
- No em dash anywhere (code, comments, copy, docs), and no spaced hyphen standing in for one.
- Simulator: the iPhone 17 Pro "Claude Al-Islam", `SIM=BE079A6B-4C8A-4D8E-8BBA-EC38E9FA2E46` (confirm with `xcrun simctl list devices available | grep "iPhone 17 Pro"`). Never Abu's own booted 17 Pro.
- Every `xcodebuild` and `simctl` call runs with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- Build: `xcodebuild -project Al-Islam.xcodeproj -scheme iPhone -configuration Debug -destination id=$SIM -derivedDataPath build/DerivedData -quiet build; echo EXIT $?` (about four minutes; the scheme builds the Watch too). Never judge a build through a pipe.
- Unit tests: launch the app once with `-displayQiraah ""` first (a stale riwayah seed breaks the suite), then `xcodebuild test -project Al-Islam.xcodeproj -scheme iPhone -destination id=$SIM -derivedDataPath build/DerivedData -only-testing:UnitTests/<Class>; echo EXIT $?`. A test file the project does not reference runs zero tests and still prints TEST SUCCEEDED, so register every new test file.
- New files are registered with `python3 Scripts/xcode_register.py <new> --like <existing>`; the catalog file `--like iPhone/Settings/Model/SettingsAdhan.swift` (all four targets), test files `--like UnitTests/TipsCatalogTests.swift`.
- No new `@AppStorage` key (spec rule 5); `python3 Scripts/check_cloud_manifest.py` must keep passing.
- Watch-compiled files (QuranView, SurahView, AyahRow, PrayerList, AdhanView, ViewExtensions, SurahHeaders, SettingsView) may call `settings.hides(...)` and `.hiddenInSimple(...)` freely: the catalog compiles everywhere. HelpDoors.swift and SimpleMode.swift are iOS-only. Anything that references an iOS-only type stays inside `#if os(iOS)`.
- Keep every `#available(iOS 16, *)` check in shared code.
- A row type with an Equatable render signature folds `simpleMode` into `==` when its body reads a trim (`ayahRenderSettingsSignature` already does).
- Never write `@AppStorage` or UserDefaults from a body, timer, playback callback or scroll handler. The rule-9 fold runs from the property's `didSet`, which only a Toggle action or the splash drives.
- Confirmation dialogs, never alerts. New copy is the spec's section 7, verbatim.
- Screenshot recipe: `xcrun simctl terminate $SIM com.Quran.Elmallah.Islamic-Pillars; xcrun simctl launch $SIM com.Quran.Elmallah.Islamic-Pillars -skipNotificationPrompt -seedBool simpleMode=1,travelAutomatic=0,quranPageMode=0 -seedInt aboutYouVersionSeen=1,cloudBackup.offerVersionSeen=1 <args>`; wait 11 s (16 s with `-playSurah`); `xcrun simctl io $SIM screenshot <file>`. Seeds persist: end every session with `-seedBool simpleMode=0,travelAutomatic=1,quranPageMode=0`. Foreground `sleep` is blocked in this harness: run a shot script in the background. `idb ui swipe --udid $SIM 200 760 200 140 --duration 0.4` scrolls one screen; taps do not work on iOS 27, so every screen is reached by launch argument (`-launchTabQuran|Hadith|Islam|Settings`, `-islamDestination <rawValue>`, `-settingsOpen <page>`, `-launchHadithBook bukhari`, `-launchHadithOpen bukhari:1`, `-launchHadithTopics`, `-quranListMode -lastRead 2:255`, `-quranPageMode -mushafPageLanguage arabic`, `-playSurah 2`).
- Pair the Simple and Full shots side by side (PIL, as the scratchpad's `grid.py` did) and look at them; a shot nobody viewed proves nothing.

## Review Focus

1. **Rule 2 under Simple: an off-default state keeps its control.** Test Mode on keeps its play-menu rows; a juz sort keeps the sort row; a lit theme keeps the Legend. `hides(_:unless:)` is pinned in Task 1 (`testUnlessKeepsTheControl`); the live cases are screenshots in Task 7 (`-seedBool quranTestModeOn=1,quranTestModeEndsOnLeave=0`) and Task 6 (`-seedString quranSortMode=juz`).
2. **The live flip inside an Equatable tile.** `CountPill` now gates itself: inside an Equatable grid tile the parent will not redraw on the flip, so the pill must watch the key itself (the `GridFavoriteStar` precedent). Task 3's modifier owns an `@AppStorage`; Task 13 flips Simple with the Hadith book screen and the Dua screen pushed and screenshots both.
3. **The fold from inside a sheet.** "Too Much on Screen?" turns Simple on from its own sheet (`HelpDoors.swift:386`); the fold must not touch the sheet's presenter or write from a body. Task 10's `didSet` runs on the assignment, and Task 13 drives the door by hand once.
4. **Search after the fold.** A Simple user searching for an advanced control lands on it: `revealAllAdvancedSettings` turns every switch on and Simple must not fold them again until the next flip. Task 10's `testRevealAfterFoldStays`.
5. **The traveler.** With Simple on and traveling mode on, Show Full Prayers must be reachable from the banner in three taps and the footer must stay hidden. Task 5's `-settingsOpen travelingMode` shot with `-seedBool travelingMode=1`, and Task 13's Adhan shot while traveling.

---

### Task 1: The catalog file and its tests

**Files:**
- Create: `iPhone/Settings/Model/SimpleTrims.swift` (register `--like iPhone/Settings/Model/SettingsAdhan.swift`)
- Modify: `iPhone/Settings/Model/SettingsAdhan.swift:4836-4872` (delete `enum SimpleMode`; it moves verbatim into the new file, doc comment included, with its "here rather than beside the More menu" sentence replaced by "here with the catalog, which every target compiles")
- Create: `UnitTests/SimpleTrimCatalogTests.swift` (register `--like UnitTests/TipsCatalogTests.swift`)

**Interfaces:**
- Produces:
  - `enum SimpleTrim: String, CaseIterable, Identifiable` with the 43 cases of the spec's section 5, declared in the spec's order; `var id: String { rawValue }`.
  - `enum SimpleTrim.Surface: String, CaseIterable, Identifiable`: `everywhere, adhan, quran, listReader, pageReader, playback, hadith, hadithBook, hadithReader, islam, destinations, settings`; `var title: String` ("Every tab", "Adhan", "Quran tab", "List reader", "Page reader", "Play menus", "Hadith tab", "Hadith book", "Hadith reader", "Islam tab", "Islam destinations", "Settings"); `var systemImage: String` (spec section 7).
  - `enum SimpleTrim.Door: Equatable`: `case moreMenu(String), settings(String), longPress(String), elsewhere(String), dropped(String = "")`; `var text: String`: "⋯ menu › \(item)", "Settings › \(path)", "Press and hold › \(item)", the place itself, "Dropped" or "Dropped: \(note)".
  - `struct SimpleTrim.Entry: Identifiable { let trim: SimpleTrim; let surface: Surface; let title: String; let door: Door; var id: SimpleTrim { trim } }`.
  - `static let entries: [Entry]`, **one `Entry(...)` per line**, exactly `Entry(.needAHand, surface: .everywhere, title: "NEED A HAND? on every tab", door: .settings("each card's setting is a row on its own settings page"))` in shape (the script in Task 2 parses that shape). Titles and doors are the spec's table, column three and four, with the door prefix ("⋯ menu:", "Settings:", "Press and hold:", "Elsewhere:", "Dropped") turned into the matching case. No double quote inside a title or a door (the script's regex); the spec's table already has none.
  - `static func entry(for trim: SimpleTrim) -> Entry` (`entries.first` with a `preconditionFailure` on a miss).
  - `static var grouped: [(surface: Surface, entries: [Entry])]`: `Surface.allCases` order, each with its entries in `entries` order, surfaces with no entry skipped.
  - `extension Settings { func hides(_ trim: SimpleTrim) -> Bool; func hides(_ trim: SimpleTrim, unless keep: Bool) -> Bool }` returning `simpleMode` and `simpleMode && !keep`. The `trim` parameter is unused by design (documentation and the script's hook); say so in its doc comment.
  - `struct SimpleTrimGate: ViewModifier` with `@AppStorage("simpleMode") private var simpleMode = false` and `let keep: Bool`; a `@ViewBuilder` body that returns `content` unless `simpleMode && !keep`, in which case `EmptyView()`.
  - `extension View { func hiddenInSimple(_ trim: SimpleTrim, unless keep: Bool = false) -> some View }` applying the gate.
  - `enum SimpleMode` as today (`trackerWindowDays`, `nagSnooze`, `markedRecently`, `isSnoozed`).

- [ ] **Step 1: Write the failing tests** in `UnitTests/SimpleTrimCatalogTests.swift` (`@testable import iPhone`, `final class SimpleTrimCatalogTests: XCTestCase`):
  - `testEveryCaseHasOneEntryInOrder`: `XCTAssertEqual(SimpleTrim.entries.map(\.trim), SimpleTrim.allCases)`.
  - `testTitlesAreUniqueAndNonEmpty`: no empty title; `Set(titles).count == titles.count`.
  - `testEveryDoorReads`: for each entry, `door.text` is non-empty, and for `.moreMenu`, `.settings`, `.longPress`, `.elsewhere` the associated string is non-empty.
  - `testEverySurfaceHasAnEntry`: for each `Surface.allCases`, `entries.contains { $0.surface == surface }`.
  - `testGroupedFollowsSurfaceOrder`: `SimpleTrim.grouped.map(\.surface) == SimpleTrim.Surface.allCases`.
  - `testDoorText`: `.moreMenu("Today").text == "⋯ menu › Today"`, `.settings("Prayer Settings › Optional Prayers").text == "Settings › Prayer Settings › Optional Prayers"`, `.longPress("Favorite").text == "Press and hold › Favorite"`, `.elsewhere("the bottom pair").text == "the bottom pair"`, `.dropped().text == "Dropped"`, `.dropped("the figures").text == "Dropped: the figures"`.
  - `testUnlessKeepsTheControl`: with `Settings.shared.simpleMode = true`, `hides(.playTestMode, unless: true)` is false and `hides(.playTestMode, unless: false)` is true; with it false both are false. Restore the previous value in `defer`.
  - `testCatalogCount`: `XCTAssertEqual(SimpleTrim.allCases.count, 43)`.
- [ ] **Step 2: Register the test file and run it to see it fail to compile** (no `SimpleTrim`). Run the unit-test command with `-only-testing:UnitTests/SimpleTrimCatalogTests`. Expected: build failure naming `SimpleTrim`.
- [ ] **Step 3: Create `SimpleTrims.swift`** with the interfaces above, a header comment that says what the file is (the catalog, the two read idioms, the script and the page that read it, and that `enum SimpleMode` lives here because every target compiles this file), and `enum SimpleMode` moved in from `SettingsAdhan.swift`. Register the file. Delete the enum from `SettingsAdhan.swift`.
- [ ] **Step 4: Build and run both test classes.** `-only-testing:UnitTests/SimpleTrimCatalogTests -only-testing:UnitTests/SimpleModeTests`. Expected: all pass (`SimpleModeTests` proves the move changed nothing).
- [ ] **Step 5: Leave uncommitted; add the progress-log line** to `Docs/Product/Simple Mode Guide.md` ("2026-10-2x: v2 Task 1, the catalog file and its tests").

### Task 2: The usage and raw-read script

**Files:**
- Create: `Scripts/check_simple_trims.py`

**Interfaces:**
- Consumes: the `Entry(` line shape from Task 1.
- Produces: a script with three modes. `check_simple_trims.py` (no flag) exits 1 and names: every case no source reads, every raw read outside the allow-list, and a missing or stale guide block; exits 0 otherwise. `--list` prints `case | surface | title | door | files`, one line per case. `--write-guide` rewrites the markdown table between `<!-- simple-trims:begin -->` and `<!-- simple-trims:end -->` in `Docs/Product/Simple Mode Guide.md` (header row `| Case | Surface | Hidden in Simple | Door |`, one row per entry in `entries` order, the door rendered as `Door.text` does) and exits 0.

- [ ] **Step 1: Write the script.** `ROOT`, `SOURCE_DIRS = ["iPhone", "Apple Watch", "Widget", "Complication"]`, `CATALOG = iPhone/Settings/Model/SimpleTrims.swift`, `GUIDE = Docs/Product/Simple Mode Guide.md`. Parse entries with `re.compile(r'^\s*Entry\(\.(\w+), surface: \.(\w+), title: "([^"]*)", door: \.(\w+)(?:\("([^"]*)"\))?\)')` over the catalog's lines, and also parse `case (\w+)` lines inside `enum SimpleTrim` up to its first `}` to cross-check the two lists match. Usage: a case is read when any `.swift` under `SOURCE_DIRS` other than the catalog contains `hides(.<case>` or `hiddenInSimple(.<case>`. Raw reads: a line matching `settings\.simpleMode\b|Settings\.shared\.simpleMode\b|@AppStorage\("simpleMode"\)` (the word boundary spares `simpleModeFoldsAdvanced`) is flagged unless it contains `$settings.simpleMode`, `isOn: settings.simpleMode`, `value: settings.simpleMode`, `settings.simpleMode = `, or `.onChange(of: settings.simpleMode)`, or the file is one of `iPhone/Settings/Model/Settings.swift`, `iPhone/Settings/Model/SettingsQuran.swift`, `iPhone/Settings/Model/SimpleTrims.swift`, `iPhone/SplashScreen.swift`, `iPhone/WelcomePages.swift`, `iPhone/Settings/Cloud/CloudManifest.swift`, `iPhone/Helpers/System/StressWalker.swift`, `iPhone/Settings/Pages/TipsAndTricks.swift` (only its `outsideSimpleMode` line: flag any other line in that file), or `iPhone/Settings/SettingsView.swift` lines inside `struct SimpleModeSection`. Door text: moreMenu "⋯ menu › x", settings "Settings › x", longPress "Press and hold › x", elsewhere "x", dropped "Dropped" / "Dropped: x". The docstring follows `check_cloud_manifest.py`'s.
- [ ] **Step 2: Run `python3 Scripts/check_simple_trims.py --list`.** Expected: 43 lines, each ending in an empty files column.
- [ ] **Step 3: Run `python3 Scripts/check_simple_trims.py; echo EXIT $?`.** Expected: EXIT 1, listing all 43 cases as unread, about sixty raw reads (the migration's to-do list), and "guide: no simple-trims block". This is the failing check Tasks 3 to 12 turn green.
- [ ] **Step 4: Leave uncommitted; progress-log line.**

### Task 3: The shared helpers

**Files:**
- Modify: `iPhone/Helpers/ViewExtensions.swift:2620-2650` (`GridFavoriteStar`), `:2712-2735` (`CountPill`), `:2856-2945` (`SectionPillHeader`)
- Modify: `iPhone/Quran/Reader/SurahHeaders.swift:9, 29, 78, 104, 110`
- Modify: `iPhone/Settings/Pages/HelpDoors.swift:511, 915`
- Modify: `iPhone/Settings/Pages/TipsAndTricks.swift:1547-1548`

**Interfaces:**
- Consumes: `settings.hides(_:)`, `.hiddenInSimple(_:unless:)` from Task 1.
- Produces: `CountPill` that hides itself in Simple (every caller in the app is covered by this one change); `SectionPillHeader` and `GridFavoriteStar` with no `@AppStorage("simpleMode")` of their own.

- [ ] **Step 1: `CountPill`:** wrap its `Text` in `.hiddenInSimple(.sectionCounts)`. Doc comment: counts are details (spec rule 8), and the rule's exceptions do not use this view.
- [ ] **Step 2: `SectionPillHeader`:** delete the `@AppStorage`; the `CountPill` needs no guard now; the search glyph gets `.hiddenInSimple(.sectionSearch)` and the shuffle `.hiddenInSimple(.sectionShuffles)` (each on the `Image`, inside its `if let`). Keep the trash and the chevron as they are.
- [ ] **Step 3: `GridFavoriteStar`:** replace the `@AppStorage` and `if isFavorite || !simpleMode` with `.hiddenInSimple(.outlineStar, unless: isFavorite)` on the star.
- [ ] **Step 4: `SurahHeaders.swift`:** both headers drop their `@AppStorage`; `SurahsHeader`'s shuffle reads `.hiddenInSimple(.surahShuffle)`; `JuzHeader`'s count is a `CountPill` (already gated) and its shuffle `.hiddenInSimple(.sectionShuffles)`; the `quranSortMode != .khatm` condition stays.
- [ ] **Step 5: `HelpDoors.swift:511`:** `if settings.showsHelpDoors(area), !settings.hides(.needAHand, unless: openDoor != nil)`. `:915`: the caption's conditional sentence reads `settings.hides(.pageHelpDoors)` (Task 10 hides the whole section; the sentence then only ever shows while Full, which is correct: keep it).
- [ ] **Step 6: `TipsAndTricks.swift:1547-1548`:** both reads become `settings.hides(.spotlightCards)`. `outsideSimpleMode` at `:146` stays raw (allow-listed).
- [ ] **Step 7: Build.** Expected: EXIT 0.
- [ ] **Step 8: Run the script.** Expected: `needAHand, sectionCounts, sectionSearch, sectionShuffles, outlineStar, surahShuffle, spotlightCards, pageHelpDoors` no longer listed as unread; no raw read left in the four files touched.
- [ ] **Step 9: Screenshots** in Simple: `-launchTabQuran` (SURAHS header, Bookmarks header), `-launchTabHadith -launchHadithBook bukhari` (chapter tiles, no outline stars), `-launchTabIslam -islamDestination commonDuas` (DUA COLLECTIONS keeps its hand-drawn count: Task 4 takes it). Pair with Full and view.
- [ ] **Step 10: Leave uncommitted; progress-log line.**

### Task 4: Every hand-built count and the hero figures

**Files:**
- Modify: `iPhone/Islam/Dua/DuaView.swift:552-558, 603-608` (two hand-drawn capsules); `:644, :984` already `CountPill`
- Modify: `iPhone/Quran/Themes/QuranThemes.swift:694-700`
- Modify: `iPhone/Islam/Proofs/MiraclesView.swift:417-419`, and the same row count in `iPhone/Islam/Proofs/PropheciesView.swift` and `iPhone/Islam/Proofs/ProphetMiraclesView.swift` (find with `grep -n 'Text("\\(.*count' iPhone/Islam/Proofs/*.swift`)
- Modify: `iPhone/Hadith/Models/HadithTopics.swift:217-222` (lane header count); `:185` is a `CountPill`
- Modify: `iPhone/Islam/Daily/JournalView.swift:546-560` (hero stats), `:769` (`filterChip`)
- Modify: `iPhone/Islam/Content/ArticleDesign.swift:1218-1240` (`ResourceHeroStats`)
- Modify: `iPhone/Islam/Arabic/ArabicView.swift:858, 865` (SPECIAL ARABIC LETTERS and ARABIC NUMBERS counts, if drawn by hand; `:1172` and `:1447` are `CountPill`)

**Interfaces:**
- Consumes: `CountPill`, `.hiddenInSimple(_:)`.
- Produces: no hand-drawn count anywhere on a header or a row; `ResourceHeroStats` that draws nothing in Simple; `JournalView.filterChip` whose count is absent in Simple.

- [ ] **Step 1: Replace each hand-drawn capsule or bare count** listed above with `CountPill(count:)` where the look is a pill, or wrap the existing `Text` in `.hiddenInSimple(.sectionCounts)` where the look is deliberately plainer (the Miracles rows' grey digits, the Topics lane header). Keep `Spacer`s so titles do not shift.
- [ ] **Step 2: `ResourceHeroStats.body`:** apply `.hiddenInSimple(.heroStats)` to the stats row (the hero's own row and the footer variant both route through this view).
- [ ] **Step 3: `JournalView.filterChip`:** the number inside the chip gets `.hiddenInSimple(.sectionCounts)`; the word stays. The hero at `:546` is covered by Step 2.
- [ ] **Step 4: Build.** Expected: EXIT 0.
- [ ] **Step 5: Screenshots** in Simple and Full: `-islamDestination commonDuas`, `commonAdhkar`, `arabicAlphabet`, `miraclesOfQuran`, `journal`; `-launchTabHadith -launchHadithTopics`; `-launchTabQuran` with `-quranOpenThemes` if such an argument exists (else reach Browse by Theme through the ⋯ menu by hand once and screenshot). View the pairs: no number on any header or row in Simple; "Listen All" still there.
- [ ] **Step 6: Run the script.** Expected: `heroStats` read; no raw read in the files touched.
- [ ] **Step 7: Leave uncommitted; progress-log line.**

### Task 5: Adhan

**Files:**
- Modify: `iPhone/Adhan/AdhanView.swift:175, 276`
- Modify: `iPhone/Adhan/Prayers/PrayerList.swift:289, 297, 429, 440`
- Modify: `iPhone/Settings/Pages/SettingsAdhanView.swift:679-700` (`travelingModeGroup`)
- Modify: `iPhone/Settings/SettingsView.swift:525-560` (`-settingsOpen` values) if `travelingMode` is not one already
- Modify: `iPhone/Adhan/Calendar/CalendarView.swift:206` (the second `yearStepperRow`)
- Modify: `iPhone/Settings/Pages/SettingsAdhanView.swift` search entries (the `SettingsSearchEntry` list near `:1500`, wherever "Traveling Mode" has its entry)
- Test: `UnitTests/SimpleModeTests.swift`

**Interfaces:**
- Produces: a "Show Full Prayers" toggle row on the Traveling Mode page bound to `settings.travelingShowFullPrayers`; `-settingsOpen travelingMode`; a search entry titled "Show Full Prayers" with path "Prayer Settings → Traveling Mode".

- [ ] **Step 1: Write the failing test** `testShowFullPrayersIsSearchable` in `SimpleModeTests`: an entry titled "Show Full Prayers" exists in the Adhan settings entries with keywords containing "qasr" and "traveling".
- [ ] **Step 2: Run it.** Expected: FAIL (no entry).
- [ ] **Step 3: Migrate the reads.** `AdhanView:175` → `!settings.hides(.prayerTracker, unless: settings.trackerMarkedRecently())`; `:276` → `settings.hides(.atAGlance)`. `PrayerList:289` (the date stepper) → `.dateStepper`; `:297` → `.dateStepper, unless: isShowingDifferentDay`; `:429` (the travel footer) → `.travelFooter`; `:440` (Optional Times) → `.optionalTimes`. Each becomes `if !settings.hides(...)` in place of `if !settings.simpleMode`.
- [ ] **Step 4: The toggle row.** In `travelingModeGroup`, after the caption and only `if settings.travelingMode`, add a second `VStack(alignment: .leading)` with `Toggle("Show Full Prayers", isOn: $settings.travelingShowFullPrayers.animation(.easeInOut))` in the group's font and tint, and the spec's caption under it. Add the search entry (title, path, keywords "full prayers qasr shorten combine traveling travel", destination the same as the Traveling Mode entry's). Add `case "travelingMode"` to `-settingsOpen` opening `SettingsAdhanView(showNotifications: false, openTravelingMode: true)`.
- [ ] **Step 5: The calendar.** Wrap the second `yearStepperRow` (`CalendarView:206`) in `.hiddenInSimple(.calendarFootStepper)`.
- [ ] **Step 6: Run the test.** Expected: PASS. Build: EXIT 0.
- [ ] **Step 7: Screenshots.** `-seedBool travelingMode=1,travelAutomatic=0,simpleMode=1` on the Adhan tab (banner, QASR badge, no footer), then `-settingsOpen travelingMode` (the new row under the switch); Full copies of both; `-launchTabAdhan` is the default tab. Reseed `travelingMode=0` after. The Hijri Calendar: reach it once by hand (date row) and screenshot its foot in Simple.
- [ ] **Step 8: Run the script.** Expected: the six Adhan cases read; no raw read in Adhan.
- [ ] **Step 9: Leave uncommitted; progress-log line.**

### Task 6: Quran tab root and Quick Search Help

**Files:**
- Modify: `iPhone/Quran/QuranView.swift:2272-2278` (sort row), `:2927-2931` (summary tiles), `:3032` (Today pill), `:1164-1250` (search help overlay), `:2677-2691` (Play Random Ayah), `:3049-3096` (`moreMenuItems`)
- Modify: `iPhone/Hadith/Views/HadithView.swift:385-432` (the hadith search help)
- Test: `UITests/SimpleModeUITests.swift`

**Interfaces:**
- Consumes: `sortModeButton(_:)`, `sortDirectionOptions`, `supportsSurahSortDirection(_:)` (QuranView:2450-2530).
- Produces: a "Sort" submenu in the Quran ⋯ menu, both modes.

- [ ] **Step 1: Write the failing UI test** `testQuranMoreMenuHasSort` next to the existing More-menu tests: in both modes (`-seedBool simpleMode=1` and `0`), open `app.buttons["tabMoreMenu"]` on the Quran tab and assert `app.buttons["Sort"].waitForExistence(timeout: 5)`.
- [ ] **Step 2: Migrate the reads.** `:2272` → `let simpleModeHidesSort = settings.hides(.sortRow, unless: settings.quranSortMode != .surah || settings.quranSortDirection != .ascending)`. `:2927` → `let simple = settings.hides(.lastListenedTiles)` for the two listening tiles; the Word of the Day tile's read `settings.hides(.wordOfDayTile)`; the history expanders `settings.hides(.historyExpanders)` (three reads where one `simple` was; the comment names the three cases). `:3032` → `settings.hides(.quranTodayPill)`.
- [ ] **Step 3: Quick Search Help.** In `searchHelpOverlayCard`, compute `let examplesHidden = settings.hides(.quickSearchHelp)`; while it is true draw neither the title row nor the examples block (`:1208-1250`), only the recent-search chips; `shouldShowSearchHelpOverlay` additionally requires `!settings.quranSearchHistory.isEmpty` when `examplesHidden`. The stored `quranSearchHelpCollapsed` / `quranSearchHelpRemoved` are not read or written on that path. Same shape in `HadithView:385-432` with `hadithSearchHistory`.
- [ ] **Step 4: The play menu.** Wrap the Play Random Ayah button (`:2677-2691`) in `if !settings.hides(.playRandomAyah)`.
- [ ] **Step 5: The Sort submenu.** In `moreMenuItems`, after "Open a Random Surah" and before the divider: `Menu { ForEach(sort modes in the row's three groups with its dividers) { sortModeButton(mode) }; Divider(); ForEach(sortDirectionOptions) { direction button with a checkmark on the current } } label: { Label("Sort", systemImage: "arrow.up.arrow.down") }`. The direction buttons set `settings.quranSortDirection` with the same `withAnimation` the row uses.
- [ ] **Step 6: Build; run the UI test.** Expected: EXIT 0; the test passes in both modes.
- [ ] **Step 7: Screenshots.** Simple and Full: `-launchTabQuran` (no Today pill, two tiles), `-launchTabQuran -seedString quranSortMode=juz` (the sort row stays in Simple), the search field focused (`-quranSearchFocus` if it exists, else tap by hand once): recents only in Simple. Reseed `quranSortMode=surah` after.
- [ ] **Step 8: Run the script.** Expected: the Quran root cases and `quickSearchHelp`, `playRandomAyah`, `historyExpanders` read.
- [ ] **Step 9: Leave uncommitted; progress-log line.**

### Task 7: The readers and the play menus

**Files:**
- Modify: `iPhone/Quran/Reader/SurahView.swift:1438, 2606, 2696, 3817, 4361, 5078` and the play menu `:3942-4020`
- Modify: `iPhone/Quran/Reader/AyahRow.swift:1023, 1070, 1616`
- Modify: `iPhone/Quran/Tajweed/TajweedLegendView.swift:901`
- Modify: `iPhone/Quran/Mushaf/MushafReader.swift:3016, 3032` (footer), `:2605-2615` (find bar), `:3383` (Test Mode), `:3395-3468` (Other Options)
- Modify: `iPhone/Quran/Playback/NowPlayingView.swift:881`

**Interfaces:**
- Consumes: `QuranTestMode.shared.isOn`.

- [ ] **Step 1: SurahView.** `:1438` and `:2696` → `.topSurahPair`; `:2606` and `:4361` → `.pageJuzLine`; `:3817` → `.globalSearch`; `ReaderLegendMenu.isVisible` (`:5078`) → `!Settings.shared.hides(.legendPill, unless: tajweedApplies || themesApply)`. In `playButton`: `QuranTestModeMenuSection` (`:3942`) inside `if !settings.hides(.playTestMode, unless: QuranTestMode.shared.isOn)` (and its divider with it); the `Menu { ... } label: { Label("Other Options", ...) }` (`:3952-4020`) inside `if !settings.hides(.playOtherOptions)`. The hold shortcut (`:3924`) is untouched.
- [ ] **Step 2: AyahRow.** `:1023` → `.ayahPlayMenu`; `:1070` → `.ayahLongMenu`; `:1616` → `.translationCaption, unless: showEnglishMustafa`.
- [ ] **Step 3: TajweedLegendView:901** → `settings.hides(.legendPill) && ThemeHighlights.shared.isEmpty`.
- [ ] **Step 4: MushafReader.** `:3016` and `:3032` → `.mushafMeters`; the "Search the whole Quran" button (`:2605-2615`) inside `if !settings.hides(.findWholeQuran)`; the page-mode play menu's `QuranTestModeMenuSection` (`:3383`) and Other Options (`:3467`) exactly as in Step 1.
- [ ] **Step 5: NowPlayingView:881** → the same `.playTestMode, unless: QuranTestMode.shared.isOn` guard.
- [ ] **Step 6: Build.** Expected: EXIT 0. Confirm `ayahRenderSettingsSignature` still folds `simpleMode` (`SettingsQuran.swift:498`): unchanged.
- [ ] **Step 7: Screenshots** in Simple and Full: `-launchTabQuran -quranListMode -lastRead 2:255` (no top pair, no Global, no pinned line, no ▶ on the ayah); the play menu open by hand once per reader (Choose Reciter, Play Ayah by Ayah, Play Last Listened, Play Surah in Simple); `-seedBool quranTestModeOn=1,quranTestModeEndsOnLeave=0` then the same menu (the Test Mode rows are back); `-quranPageMode -mushafPageLanguage arabic -lastRead 2:255` with the find bar open (no whole-Quran scope). Reseed `quranTestModeOn=0,quranTestModeEndsOnLeave=1`.
- [ ] **Step 8: Run the script.** Expected: every listReader, pageReader and playback case read; no raw read in Quran.
- [ ] **Step 9: Leave uncommitted; progress-log line.**

### Task 8: Hadith

**Files:**
- Modify: `iPhone/Hadith/Views/HadithView.swift:1070, 1077, 1145, 2606, 2674, 2694`
- Modify: `iPhone/Hadith/Views/HadithBookView.swift:1043, 1420, 1455, 1543, 1569, 2000`

- [ ] **Step 1: HadithView.** `:1070` → `.hadithTodayPill`; `:1077` and `:1145` → `.historyExpanders`; `:2606`, `:2674`, `:2694` → `.bookStats` (the frame height reads `settings.hides(.bookStats) ? 72 : 100`).
- [ ] **Step 2: HadithBookView.** `:1043` → `.bookStats`; `:1420`, `:1455`, `:1543`, `:1569` → `.chapterStats`; `:2000` → `.topChapterPair`.
- [ ] **Step 3: Build.** Expected: EXIT 0. Check whether the chapter tile or book row types are Equatable with a settings signature; if one is and its signature lacks `simpleMode`, fold it.
- [ ] **Step 4: Screenshots** in Simple and Full: `-launchTabHadith`, `-launchHadithBook bukhari`, `-launchHadithOpen bukhari:1`. View: unchanged from the first build.
- [ ] **Step 5: Run the script.** Expected: the four Hadith cases read; no raw read in Hadith.
- [ ] **Step 6: Leave uncommitted; progress-log line.**

### Task 9: Islam tab, the card pills, the Daily Hub

**Files:**
- Modify: `iPhone/Islam/IslamView.swift:399, 587, 591, 749, 844` and `islamMoreMenuItems` (`:1220-1232`)
- Modify: `iPhone/Islam/Daily/DailyReminders.swift:1340-1350` (the header's hub pill) and `ReminderOfTheDayCard`'s copy of it (`showsHubDoor`, `:1078`)
- Modify: `iPhone/Islam/Dua/DuaView.swift:1705-1714`
- Modify: `iPhone/Islam/Daily/DailyHub.swift:116, 190`
- Test: `UITests/SimpleModeUITests.swift`

**Interfaces:**
- Consumes: `reminderDoor: ReminderOfTheDayCard.HeaderDoor?` (`IslamView:31`), `islamPath`, `ReminderOfTheDayCard.HeaderDoor.hub`.
- Produces: "Today" in the Islam ⋯ menu, both modes.

- [ ] **Step 1: Write the failing UI test** `testIslamMoreMenuHasToday`: on the Islam tab, in both modes, the More menu has a "Today" button; tapping it lands on a screen whose navigation bar or first static text contains "Today" or "AYAH OF THE DAY".
- [ ] **Step 2: Migrate the reads.** `:399` and `:749` and `:844` → `settings.hides(.foldedGroups)`; `:587` → `.prophetQuote`; `:591` → `.appsSection`.
- [ ] **Step 3: The menu item.** In `islamMoreMenuItems`, first: `TabMoreMenuItem("Today", systemImage: "sun.horizon.fill") { settings.hapticFeedback(); guard islamPath.isEmpty else { return }; reminderDoor = .hub }`, then a `Divider()`, then the two existing items. Both the iPhone list's menu (`:632`) and the iPad's (`:1211`) use `islamMoreMenuItems` already; confirm the iPad path has the same `reminderDoor` state (`:1203` applies `reminderCardDestination`).
- [ ] **Step 4: The card pills.** The hub `Button { ... } label: { DailyHubDoorLabel() }` in `ReminderOfTheDayHeader` (`DailyReminders:1340-1350`) and the one in the Dua card (`DuaView:1705-1714`) each get `.hiddenInSimple(.cardTodayPills)`.
- [ ] **Step 5: The Daily Hub.** The two `shuffleButton(...)` calls (`DailyHub:116` and `:190`) get `.hiddenInSimple(.dailyHubShuffles)`; the dua's play button is untouched.
- [ ] **Step 6: Build; run the UI test.** Expected: EXIT 0; the test passes.
- [ ] **Step 7: Screenshots** in Simple and Full: `-launchTabIslam` (the reminder header without its pill), `-islamDestination commonDuas` (the card without its pill), the Daily Hub via the new item by hand once (no shuffle circles).
- [ ] **Step 8: Run the script.** Expected: the five Islam and destinations cases read; no raw read in Islam.
- [ ] **Step 9: Leave uncommitted; progress-log line.**

### Task 10: Settings pages and the Advanced fold

**Files:**
- Modify: `iPhone/Settings/Pages/TipsAndTricks.swift:1146-1162` (`TipsSection`)
- Modify: `iPhone/Settings/Pages/HelpDoors.swift:905-960` (`HelpDoorsSettingsSection`)
- Modify: `iPhone/Settings/Model/Settings.swift:3812` (the `simpleMode` property) and the Advanced helpers after `:3852`
- Modify: `iPhone/Settings/SettingsView.swift:2243-2253` (`AdvancedSettingsSection.caption`)
- Test: `UnitTests/SimpleModeTests.swift`

**Interfaces:**
- Produces: `Settings.foldAllAdvancedSettings()`: `setAdvanced(screen, false)` for every `AdvancedScreen`; `simpleMode`'s `didSet` calling it when the value turns true; `Settings.simpleModeFoldsAdvanced: Bool` in `SimpleTrims.swift`.

- [ ] **Step 1: Write the failing tests** in `SimpleModeTests`:
  - `testTurningSimpleOnFoldsAdvancedSwitches`: start with Simple off and `setAdvanced(.prayerCalculation, true)`, `setAdvanced(.quranReadingView, true)`; set `simpleMode = true`; assert every `advanced(screen)` is false. Then `setAdvanced(.quranReadingView, true)` while Simple is on; set `simpleMode = false`; assert `.quranReadingView` is still on and `.prayerCalculation` still off. Restore both keys and the flag in `defer`.
  - `testRevealAfterFoldStays`: Simple on, `revealAllAdvancedSettings()`, assert every screen on, and still on after `RunLoop.main.run(until: Date().addingTimeInterval(0.5))`.
  - Amend `testFlippingSimpleModeWritesNothingElse`: the `changed` set also subtracts keys with the prefix `advancedSettings_` (rule 9's writes), and the message says so.
- [ ] **Step 2: Run the class.** Expected: the two new tests FAIL (switches stay on).
- [ ] **Step 3: Implement.** `foldAllAdvancedSettings()` beside `revealAllAdvancedSettings()`, doc comment citing rule 9. On `simpleMode`: `didSet { guard simpleMode, !oldValue else { return }; foldAllAdvancedSettings() }`. Update the property's doc comment: the catalog is `SimpleTrims.swift`; the one action it takes is this fold.
- [ ] **Step 4: The caption.** `SimpleTrims.swift`'s `Settings` extension gains `var simpleModeFoldsAdvanced: Bool { simpleMode }` with a doc comment naming rule 9 (it is not a trim, so it is not a case; the script's word-boundary regex does not flag it). In `AdvancedSettingsSection.caption`, before the `hides` branch: `if settings.simpleModeFoldsAdvanced, !settings.advanced(screen) { return "Simple Mode turned this off; turn it on to see every option here." }`.
- [ ] **Step 5: `TipsSection`:** its `Section` body is wrapped in `.hiddenInSimple(.pageTipsRows)`. `HelpDoorsSettingsSection`: its `Section` wrapped in `.hiddenInSimple(.pageHelpDoors)`. (Both are `Section`s inside a `List`; the modifier's `EmptyView` leaves no gap.)
- [ ] **Step 6: Run the class; build.** Expected: PASS; EXIT 0.
- [ ] **Step 7: Screenshots** in Simple and Full: `-settingsOpen prayer`, `quran`, `hadith`, `islam`, `notifications` scrolled to the foot (one swipe): no Tips & Tricks row, no NEED A HAND? section, the ADVANCED switch present with the new sentence while off.
- [ ] **Step 8: Run the script.** Expected: `pageTipsRows` read; the only remaining raw reads are in `SettingsView.swift`'s `SimpleModeSection` (allowed) and the allow-listed files.
- [ ] **Step 9: Leave uncommitted; progress-log line.**

### Task 11: The Simple Mode page

**Files:**
- Modify: `iPhone/Settings/SettingsView.swift:2150-2198` (`SimpleModeSection`, `SimpleModeSettingsView`), `:655` (the root's section)
- Test: `UITests/SimpleModeUITests.swift`

**Interfaces:**
- Consumes: `SimpleTrim.grouped`, `Surface.title`, `Surface.systemImage`, `Door.text`.
- Produces: `SimpleModeSection(showsCatalogRow: Bool)`; `SimpleModeSettingsView` listing the catalog.

- [ ] **Step 1: Write the failing UI test** `testSimpleModePageListsTheCatalog`: launch with `-launchTabSettings -settingsOpen simpleMode`; assert `app.staticTexts["WHAT MOVES WHERE"]` or the first surface header "EVERY TAB" exists, and `app.staticTexts["The Optional Times pill"]` exists after at most three swipes.
- [ ] **Step 2: `SimpleModeSection`.** Add `var showsCatalogRow = true`. Captions become the spec's two sentences (section 7). When `showsCatalogRow`, a second row in the Section: `NavigationLink(destination: SimpleModeSettingsView()) { SettingsRowLabel(title: "What Moves Where", systemImage: "list.bullet.rectangle", ...) }` in the root's `resourceLink` style; on the iPad split root (the `splitResourceLink` path at `:989`) use the root's selection mechanism, adding a selection case if the enum lacks one. The root (`:655`) keeps `SimpleModeSection()`; the page passes `showsCatalogRow: false`.
- [ ] **Step 3: `SimpleModeSettingsView`.** `List { SimpleModeSection(showsCatalogRow: false); ForEach(SimpleTrim.grouped, id: \.surface) { group in Section(header: SectionIconHeader(group.surface.title.uppercased(), icon: group.surface.systemImage)) { ForEach(group.entries) { entry in VStack(alignment: .leading, spacing: 2) { Text(entry.title).font(.subheadline); Text(entry.door.text).font(.caption).foregroundColor(.secondary) } } } }; Section { Text(footer sentences, spec section 7, as one caption) } }`. Keep `.applyConditionalListStyle()` and the title.
- [ ] **Step 4: Build; run the UI test.** Expected: EXIT 0; PASS.
- [ ] **Step 5: Screenshots.** `-settingsOpen simpleMode` top, one swipe, two swipes, in Simple; the root's SIMPLE MODE section in both modes (`-launchTabSettings`, one swipe). iPad: `-forceLandscape` on the iPad sim if one is available to the harness, else note it for Abu.
- [ ] **Step 6: Leave uncommitted; progress-log line.**

### Task 12: Docs, comments and the generated table

**Files:**
- Modify: `Docs/Product/Simple Mode Guide.md:41-146` (the per-screen tables), `:202-220` (Architecture), `:220-245` (Verification), `:252-268` (Build order), `:268-` (Progress log)
- Modify: `iPhone/Helpers/UI/SimpleMode.swift:1-50` (the header comment)
- Modify: `iPhone/Settings/SettingsView.swift:2244, 2261` and `iPhone/Settings/Model/Settings.swift` (`migrateAdvancedSettings` comment): "eleven" → "nine"
- Modify: `iPhone/Settings/Pages/TipsAndTricks.swift:986-994` (`simpleModeDetail`)
- Modify: `/Users/theabubakrabu/.claude/projects/-Users-theabubakrabu-Downloads-Islam-Al-Islam-iOS/memory/simple-mode.md`

- [ ] **Step 1: The guide.** Replace the seven per-screen tables under "## Per screen" with: the markers `<!-- simple-trims:begin -->` / `<!-- simple-trims:end -->` (empty between them), then a "What stays" list carrying each screen's "Stays:" sentence from the old tables, then the rule-9 paragraph. Fix the Islam wording (one ISLAMIC RESOURCES section). Architecture: the catalog file, the two idioms, the script, the page. Verification: the script and the catalog test join the list. Build order: a "v2 (2026-10-20)" table of these thirteen tasks.
- [ ] **Step 2: Run `python3 Scripts/check_simple_trims.py --write-guide`.** Expected: EXIT 0; the block holds 43 rows. Read the block once.
- [ ] **Step 3: Comments and copy.** `SimpleMode.swift`'s header: the catalog comment (lines 27-50) is replaced by two sentences pointing at `SimpleTrims.swift` and the Simple Mode page; the rules paragraph stays. `simpleModeDetail`: append "What Moves Where, on the Simple Mode page, lists every shortcut and where it went." "eleven screens" → "nine screens" at the three sites.
- [ ] **Step 4: Memory.** Update `simple-mode.md`: the catalog file, the three idioms, the script, rule 9, the two UI tests, and that the guide's table is generated.
- [ ] **Step 5: Build; run `python3 Scripts/check_simple_trims.py; echo EXIT $?` and `python3 Scripts/check_cloud_manifest.py; echo EXIT $?`.** Expected: EXIT 0 for all three. List the new script in `Scripts/qa/README.md` beside `check_cloud_manifest.py` (add a "Checks" list if the README has none; `audits.sh` runs no Python checks).
- [ ] **Step 6: Leave uncommitted; progress-log line.**

### Task 13: The verification sweep

**Files:**
- Read only; screenshots into the scratchpad.

- [ ] **Step 1: Full unit run.** `-only-testing:UnitTests` (whole target). Expected: 0 failures (the CarPlay suite is known to fail only in the full run; see memory `carplay-test-suite-pollution.md`; anything else is this plan's).
- [ ] **Step 2: Both UI tests.** `-only-testing:UITests/SimpleModeUITests`. Expected: PASS.
- [ ] **Step 3: The two-mode sweep.** A background script shooting, in Simple then Full: Adhan (`-seedBool travelingMode=1`), Quran root, list reader (`-quranListMode -lastRead 2:255`), page reader (`-quranPageMode -mushafPageLanguage arabic -lastRead 2:255`), Now Playing (`-playSurah 2`), Hadith root, book, reader, Topics, Islam root, `commonDuas`, `commonAdhkar`, `namesOfAllah`, `arabicAlphabet`, `miraclesOfQuran`, `journal`, Settings root, `-settingsOpen prayer|quran|hadith|islam|notifications|simpleMode|travelingMode`. Pair and view every one.
- [ ] **Step 4: The live flip.** Launch Full with `-launchHadithBook bukhari`; by hand: Settings tab, Simple Mode on, back to the pushed book screen; screenshot: no chapter counts, no outline stars. Same with `-islamDestination commonDuas`: no collection counts, no hero chips, no Today pill. Same from the Islam tab's "Too Much on Screen?" door (Full, NEED A HAND? expanded): the sheet dismisses cleanly and the tab trims.
- [ ] **Step 5: Reset the sim.** `-seedBool simpleMode=0,travelAutomatic=1,quranPageMode=0,travelingMode=0,quranTestModeOn=0,quranTestModeEndsOnLeave=1`, launch once, terminate.
- [ ] **Step 6: Report.** The guide's progress log gets the sweep's line (what was shot, what was viewed, anything left for Abu). The change stays uncommitted; the message to Abu lists the files and the commit it would be.
