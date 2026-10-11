# Simple Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Simple Mode actually calm the app (per-tab trims, a ⋯ More menu, a five-action ayah menu), offer it on the splash, and ship the everyone-fixes Abu picked on 2026-10-10.

**Architecture:** One existing switch, `Settings.simpleMode`, read directly at each site. A small iOS-only kit file holds the pure rules (tracker gate, snooze) and the More menu label. Every hidden control either moves (More menu, Settings) or is on the guide's "dropped" list; nothing that changes behaviour is tied to the switch.

**Tech Stack:** SwiftUI (iOS 16 floor for Al-Islam, siblings on iOS 15), XCTest (hosted UnitTests, XCUITest UITests), hand-maintained project.pbxproj.

**Spec:** `docs/Simple Mode Guide.md`. Read it first; this plan argues from it, and its tables are the source of truth for what hides and where it goes.

## Global Constraints

- No `git commit`, `git push` or any history-mutating git command (Abu's global rule). Every task ends with the change left uncommitted and a progress-log line in the guide.
- No em dash anywhere (code, comments, copy, docs), and no spaced hyphen standing in for one.
- Simulator: the iPhone 17 Pro "Claude Al-Islam" (`xcrun simctl list devices available | grep "iPhone 17 Pro"`; today BE079A6B-4C8A-4D8E-8BBA-EC38E9FA2E46). Never Abu's own booted 17 Pro.
- Every `xcodebuild` and `simctl` call runs with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- Build: `xcodebuild -project Al-Islam.xcodeproj -scheme iPhone -destination id=$SIM -derivedDataPath build/DerivedData -quiet build; echo EXIT $?` (scheme iPhone builds the Watch too). Never judge a build through a pipe.
- Anything a Watch-compiled file (QuranView.swift, ViewExtensions.swift, SplashScreen.swift, SurahView.swift) references from the new kit file sits inside `#if os(iOS)`.
- Keep every `#available(iOS 16, *)` check in shared code.
- Every new `@AppStorage` key is classified in `iPhone/Settings/Cloud/CloudManifest.swift`; `python3 Scripts/check_cloud_manifest.py` must pass.
- A row type with an Equatable render signature folds `simpleMode` into `==` when its body reads it.
- Never write `@AppStorage` or UserDefaults from a body, timer, playback callback or scroll handler.
- Confirmation dialogs, never alerts. New copy is the guide's copy, verbatim.
- New files are registered with `python3 Scripts/xcode_register.py <new> --like <existing>`; an unregistered test file runs zero tests and still prints SUCCEEDED.
- Screenshot recipe: terminate, `xcrun simctl launch $SIM com.Quran.Elmallah.Islamic-Pillars -skipNotificationPrompt -travelingMode 0 -seedBool simpleMode=1 <args>`, wait 11 s, `xcrun simctl io $SIM screenshot <file>`. Seeds persist in the app's defaults: end every session with `-seedBool simpleMode=0`.

## Review Focus

1. **Flipping the switch with a list on screen** (an open reader, the hadith catalog): every row must take its new shape at once. Owned by Tasks 4 and 7: a live-flip check with `-seedBool` relaunch is not enough; flip in Settings with the reader pushed and screenshot.
2. **Simple Mode with a non-default state**: a juz sort, a non-Hafs riwayah, khatm sort, a list-mode tab. The control that explains the state must still show. Owned by Task 3 (`-seedString quranSortMode=juz` screenshot).
3. **iPad and Mac split views**: the More menu belongs in the sidebar toolbar, and the gear rule (never in the sidebar list) stays. Owned by Task 15 (iPad screenshot of each split tab).
4. **Accessibility text sizes**: the More menu, the trash buttons and splash step two must fit or scroll at an accessibility size. Owned by Tasks 2, 14 and 15.
5. **Switching back to Full lands exactly where it started**: no setting may change because Simple Mode was on. Owned by Task 1 (`testFlippingSimpleModeWritesNothingElse`).

---

### Task 1: The kit file and its rules

**Files:**
- Create: `iPhone/Helpers/UI/SimpleMode.swift` (iOS only; register `--like iPhone/Helpers/UI/BannerWindow.swift`)
- Modify: `iPhone/Settings/Model/SettingsAdhan.swift` (the tracker wrapper), `iPhone/Settings/Model/Settings.swift` (the `simpleMode` doc comment: rule 3 replaces "Nothing that is the only way to reach something may hide behind it")
- Test: `UnitTests/SimpleModeTests.swift` (register `--like UnitTests/AyahRowIdentityTests.swift`)

**Interfaces:**
- Produces:
  - `enum SimpleMode`
  - `static let trackerWindowDays = 14`
  - `static let nagSnooze: TimeInterval = 86_400`
  - `static func markedRecently(_ tracker: [String: [String: PrayerMark]], today: Date, days: Int = trackerWindowDays, dayKey: (Date) -> String) -> Bool`
  - `static func isSnoozed(until: Double, now: Date) -> Bool`
  - `struct SimpleMoreMenu<Items: View>: View`, built as `SimpleMoreMenu { items }`: a `Menu` with an `ellipsis.circle` label, `.accessibilityLabel("More")`, `.accessibilityIdentifier("tabMoreMenu")` and `.tint(settings.accentColor.accent1)`. The identifier sits on the Menu itself, so the UI tests find the button.
  - (As built: `enum SimpleMode` lives at the end of SettingsAdhan.swift, because the Widget target compiles that file and not the kit file. The kit file keeps the catalog comment and `SimpleMoreMenu`.)
  - `Settings.trackerMarkedRecently(now: Date = Date()) -> Bool`, which calls `markedRecently(loadPrayerTracker(), today: now, dayKey: prayerTrackerKey(for:))`

- [ ] **Step 1: Write the failing tests** in `UnitTests/SimpleModeTests.swift`. Use `@MainActor final class SimpleModeTests: XCTestCase`, with a fixed `today` and a gregorian "yyyy-MM-dd" key formatter (UTC):
  - `testTrackerGateWindow`: a mark 13 days back gives `true`; only a mark 15 days back gives `false`; `[:]` gives `false`; a day key whose marks dictionary is empty gives `false`; a mark today gives `true`.
  - `testSnooze`: `isSnoozed(until: now + 1, now: now)` is `true`; `isSnoozed(until: now - 1, now: now)` is `false`; `isSnoozed(until: 0, now: now)` is `false`.
  - `testFlippingSimpleModeWritesNothingElse`:
    1. Snapshot `UserDefaults.standard.dictionaryRepresentation()`.
    2. Set `Settings.shared.simpleMode = true`, then `false`.
    3. Snapshot again. The key sets are equal, and every key except `simpleMode` has the same value as before.
    4. Restore the saved `simpleMode` in `tearDown`.
- [ ] **Step 2:** Run `xcodebuild test ... -only-testing:UnitTests/SimpleModeTests`. Expected: build FAILS, "cannot find 'SimpleMode' in scope".
- [ ] **Step 3:** Implement the interfaces above.
  - `markedRecently` checks at most `days` keys, today and the 13 before it, with `calendar.date(byAdding: .day, value: -i, to: today)`. A day counts only if its dictionary is non-empty.
  - The file opens with the catalog comment: every trim and its door, mirroring the guide's tables, one line each.
- [ ] **Step 4:** Run the same test command. Expected: `Executed 3 tests, with 0 failures`.
- [ ] **Step 5:** Debug build (`EXIT 0`); log the task in the guide's progress log; leave uncommitted.

### Task 2: Section headers (Simple trims, the trash) and Need a Hand?'s trash

**Files:**
- Modify: `iPhone/Helpers/ViewExtensions.swift` (`SectionPillHeader`), `iPhone/Quran/Reader/SurahHeaders.swift` (`SurahsHeader`), `iPhone/Settings/Pages/HelpDoors.swift` (`HelpDoorsSection`)

**Interfaces:**
- Produces: `SectionPillHeader(..., onRemove: (() -> Void)? = nil)`. The trash draws only when `onRemove != nil && isExpanded?.wrappedValue == false`. It is a `trash` symbol circle the size of the shuffle circle, with `.accessibilityLabel("Remove \(title.lowercased())")`. Cluster order: count, search, shuffle, trash, chevron (update the ordering comment).
- `SectionPillHeader` and `SurahsHeader` read `@AppStorage("simpleMode") private var simpleMode = false` (it observes the key, and it compiles for the watch). In Simple they omit the count pill, search and shuffle.

- [ ] **Step 1:** Implement the header changes.
- [ ] **Step 2:** In `HelpDoorsSection`, pass `onRemove: { confirmingRemove = true }` and attach `.confirmationDialog("Remove Need a Hand?", isPresented: $confirmingRemove, titleVisibility: .visible)` to the header.
  - Buttons: `Button("Remove", role: .destructive) { withAnimation(.easeInOut) { settings.setShowsHelpDoors(area, false) } }`, then `Button("Cancel", role: .cancel) {}`.
  - Message: `Text("It leaves the \(area.tabName) tab. You can bring it back in \(area.settingsPageName).")`.
  - The section returns `EmptyView` while `settings.simpleMode` is on: Simple hides Need a Hand? on all four tabs, so the tabs need no per-site gate.
- [ ] **Step 3:** Debug build, then two screenshots:
  - Full, Quran tab, `-seedString helpDoorsCollapsed=quran`. Expected: the trash shows between the count and the chevron.
  - Simple, Quran tab. Expected: no NEED A HAND? section; the BOOKMARKS header shows no count or shuffle.
- [ ] **Step 4:** At an accessibility text size (`xcrun simctl ui $SIM content_size accessibility-large`), the collapsed header's cluster still fits (it may drop under the title, per `AdaptiveSectionHeader`). Reset with `content_size large`.
- [ ] **Step 5:** Log the task; leave uncommitted.

### Task 3: Quran tab root

**Files:**
- Modify: `iPhone/Quran/QuranView.swift`: `QuranLeadingToolbar`, `QuranTrailingToolbar`, `summaryTilesSection(context:)`, `summaryHeader`, the door-chip builder (`SummaryDoorChip` list), `surahGridTile(surah:context:)`
- Modify: `iPhone/Helpers/ViewExtensions.swift`: `gridFavoriteStar(...)` draws nothing for a non-favorite in Simple. The change is app-wide (Quran, Islam and Hadith tiles alike), which the guide wants.
- Modify: `iPhone/Quran/Reader/QuranPlannerView.swift`: let `QuranPlannerToolbarButton`'s sheet open from outside, through an `isPresented: Binding<Bool>` init or a shared presenter, so the More menu can open the Planner.

**Interfaces:**
- Consumes: `SimpleMoreMenu` (Task 1).
- Produces: a `summaryDoors() -> [SummaryDoorChip]` builder shared by the chips row (Full) and the More menu (Simple), so each item has exactly one action.

- [ ] **Step 1: The toolbar in Simple, when not the picker.**
  - Leading: one `ToolbarItem` holding `SimpleMoreMenu { … }`, carrying the reading-mode `confirmationDialog` the book button carries today.
  - Trailing: `khatmButton`, which only renders in khatm sort (that's rule 2), then `gearButton`.
  - Menu items, in order:
    1. Today
    2. History
    3. Browse by Theme
    4. Word of the Day
    5. Qiraat Explorer (while `showOtherQiraatReciters`)
    6. Quran Planner (while `isHafsDisplay`)
    7. Open a Random Surah (the `SurahsHeader` shuffle's action)
    8. a Divider
    9. Read as Pages, or Read as List (sets `showReadingModeConfirm`)
    10. Show as Grid, or Show as List
- [ ] **Step 2: The summary in Simple.**
  - Only the Last Read Ayah and Ayah of the Day tiles show.
  - No +/− history buttons, no Today pill, no chips row.
  - The Word of the Day odd-count rule only runs in Full.
- [ ] **Step 3:** Debug build, then screenshots:
  - Simple, Quran tab. Expected: [More] Al-Quran [gear]; at most two summary tiles; no chips; no NEED A HAND?; SURAHS with no count or shuffle; no outline stars.
  - Full. Expected: unchanged from today's `quran.png`.
  - Simple with `-seedString quranSortMode=juz`. Expected: the sort row still shows (Review Focus 2).
- [ ] **Step 4: UITest** `UITests/SimpleModeUITests.swift` (register `--like UITests/SurahSwapTests.swift`):
  - `testQuranMoreMenuHoldsTheMovedDoors`: launch with `-skipNotificationPrompt -launchTabQuran -seedBool simpleMode=1`; tap `app.buttons["tabMoreMenu"]`; assert that buttons "History", "Browse by Theme", "Word of the Day" and "Open a Random Surah" exist.
  - `tearDown` relaunches with `-seedBool simpleMode=0`.
  - Run with `-only-testing:UITests/SimpleModeUITests`. Expected: PASS.
- [ ] **Step 5:** Log the task; leave uncommitted.

### Task 4: List reader and the ayah ⋯ menu

**Files:**
- Modify: `iPhone/Quran/Reader/SurahView.swift`: the top Previous/Next pair above the first ayah; the pinned page/juz line; the Global button in `qiraatAndTajweedControls(inline:)`
- Modify: `iPhone/Quran/Reader/AyahRow.swift`: the `play.circle` Menu, the ellipsis Menu, the Saheeh caption, `muqattaatPronunciationBlock()`, the `==` signature
- Modify: `iPhone/Quran/Reader/ContextMenu.swift` and `iPhone/Quran/Sheets/AyahSheets.swift` (small fixes only)

**Interfaces:**
- Produces: `AyahRow.simpleMenuBlock(isBookmarked: Bool) -> some View`, holding:
  - Play This Ayah (`isHafsDisplay` only; the same action as `playbackMenuBlock`'s last item)
  - Bookmark Ayah, or Remove Bookmark
  - See Tafsir
  - Copy Ayah
  - Share Ayah
  - a Divider
  - "More Actions…", which calls `requestSheet(.actions)`

  The ellipsis label gets `.accessibilityIdentifier("ayahActionsMenu")`.

- [ ] **Step 1: Write the failing UITest** `testAyahMenuIsFiveActionsInSimple` in `SimpleModeUITests`:
  1. Launch with `-skipNotificationPrompt -launchTabQuran -quranListMode -lastRead 1:1 -seedBool simpleMode=1`, then wait 8 s.
  2. Tap `app.buttons["ayahActionsMenu"].firstMatch`.
  3. Assert that "See Tafsir", "Copy Ayah", "Share Ayah" and "More Actions…" exist, and that "Similar Ayahs" does not.
- [ ] **Step 2:** Run it. Expected: FAIL (there is no "More Actions…" yet).
- [ ] **Step 3:** Implement the Simple branch at each site, per the guide's List reader table.
  - Both slots of the bottom Previous/Next pair still always render.
  - The Saheeh caption hides only while exactly one translation shows.
  - Fold `simpleMode` into `AyahRow`'s `==`.
- [ ] **Step 4:** Small fixes at all three parity sites (`ContextMenu.swift` menuItems, `AyahRow.menuBlock` and `playbackMenuBlock`, `AyahActionsSheet`):
  - "Play Custom Range" stays only under Play Ayah.
  - The reader play menu's Repeat Surah runs 2, 3, 5, 10, 15, 20, Forever.
  - The Compare Ayah tile is a plain button when it holds one item.
- [ ] **Step 5:** Run the UITest. Expected: PASS. Debug build `EXIT 0`.
- [ ] **Step 6: Screenshots.**
  - Simple and Full list reader (`-quranListMode -lastRead 2:255`). Expected in Simple: no top pair, no ▶, no Saheeh caption, no pinned page line, no Global button.
  - Live flip (Review Focus 1): launch Full into the reader, switch Simple Mode on in Settings with the reader still pushed, return, and screenshot. Expected: the rows lose ▶ without a relaunch.
- [ ] **Step 7:** Log the task; leave uncommitted.

### Task 5: Page reader footer

**Files:**
- Modify: `iPhone/Quran/Mushaf/MushafReader.swift` (`pageInfoPill(page:surah:pages:…)`)

- [ ] **Step 1:** In Simple, `pageInfoPill` draws no `meter(...)` rows, no percentages and no whole-mushaf bar. "Page 42" and "Juz 3" stay as the two jump buttons, with their wheel pickers and the long-press to Choose Surah.
- [ ] **Step 2:** Debug build; screenshots of Simple and Full with `-quranPageMode -mushafPageLanguage arabic -lastRead 2:255`. Expected: the Simple pill is one short row; the bottom band is no taller than Full's.
- [ ] **Step 3:** Log the task; leave uncommitted.

### Task 6: Adhan tab and the Prayer Times Layout row

**Files:**
- Modify: `iPhone/Adhan/Prayers/PrayerList.swift`: `sectionHeader` (the layout picker), `optionalPrayersFooter` (the Optional Times pill only), `travelModeFooter`, `dateSelectionFooter`
- Modify: `iPhone/Adhan/AdhanView.swift`: the AT A GLANCE section, and the `PrayerTrackerSection()` gate
- Modify: `iPhone/Settings/Pages/SettingsAdhanView.swift`: a Prayer Times Layout picker in the Prayer Settings root's PRAYER TIMES section, bound to the same storage as the header picker (`prayerDisplayModeV2`), with the same four options and labels

**Interfaces:**
- Consumes: `Settings.trackerMarkedRecently(now:)` (Task 1).

- [ ] **Step 1:** In Simple, hide each element in the guide's Adhan table. The tracker shows when `!settings.simpleMode || settings.trackerMarkedRecently()`; that read is at most 14 dictionary lookups on the cached tracker, so it is safe on every countdown tick.
- [ ] **Step 2:** Add the Settings picker (both modes) and a search entry for it: "Prayer Times Layout", path "Prayer Settings", keywords "tiles grid list split layout columns prayer times view".
- [ ] **Step 3:** Debug build, then screenshots:
  - Simple and Full Adhan. Expected in Simple: no layout picker, no Optional Times pill (the Rakaah Guide stays), no date stepper, no AT A GLANCE, no NEED A HAND?, no PRAYER TRACKER (this sim has no recent marks; if it has, the section correctly stays).
  - Prayer Settings (`-launchTabSettings -settingsOpen prayer`). Expected: the new picker.
- [ ] **Step 4:** Log the task; leave uncommitted.

### Task 7: Hadith tab, book and reading screens

**Files:**
- Modify: `iPhone/Hadith/Views/HadithView.swift`: the toolbar (`gridButton`, gear), `summaryTilesSection`, `encyclopediaDoors`, `bookGridTile(_:)`, `bookRow(_:)`, `bookEraLabel(_:)` and `statChip(_:)` call sites, and any Equatable tile or row signature
- Modify: `iPhone/Hadith/Views/HadithBookView.swift`: `chaptersSectionHeader(_:)`, `chapterRow(_:data:)`, the top `chapterNavButtonPair()` call in the reading screen

**Interfaces:**
- Consumes: `SimpleMoreMenu`. Topics, Encyclopedia and History reuse the exact destinations `encyclopediaDoors` pushes today; Today reuses the summary header's Daily Hub push.

- [ ] **Step 1: Toolbar in Simple.** `[More] Al-Hadith [gear]`, with the More menu holding Today, Topics, Encyclopedia, History, a Divider, then Show as Grid or Show as List.
- [ ] **Step 2:** Apply the rest of the guide's Hadith table. The grade line is untouched. The bottom chapter pair stays.
- [ ] **Step 3: UITest** `testHadithMoreMenuOpensTopics`: launch with `-skipNotificationPrompt -launchTabHadith -seedBool simpleMode=1`; tap "tabMoreMenu"; tap "Topics"; assert that a navigation bar titled "Topics" exists. Expected: PASS.
- [ ] **Step 4:** Debug build; screenshots of the Simple and Full Hadith root, a book (from the UITest's path or `-hadithOpenBook` if one exists; else skip and note it), and the reader. Then a live flip on the catalog (Review Focus 1).
- [ ] **Step 5:** Log the task; leave uncommitted.

### Task 8: Islam tab and More Resources

**Files:**
- Modify: `iPhone/Islam/IslamView.swift`: `modernResourceSections`, `islamListEntries(split:)` (the quote card `ProphetQuote`, `HelpDoorsSection(area: .islam)`, `AlIslamAppsSection`), `resourcesSectionSplit`, and the navigation destination switch
- Create: nothing new; the More Resources screen is a view in IslamView.swift (`IslamMoreResourcesView`, private) built from the same `resourceItems(_:)` and section headers

**Interfaces:**
- Produces: `ResourceGroup` gains `static let simpleFolded: Set<ResourceGroup>` (TOOLS, SIGNS & PROOFS, ASK AI). If the tab's stack is value-based, the push goes through a new `IslamDestination.moreResources` case, excluded from `available`, search, favorites and Start Here, never listed as a tile.

- [ ] **Step 1:** In Simple, the folded groups are skipped, and one More Resources row (the tab's banner style, `square.grid.2x2`, subtitle "Tools, signs and proofs, Ask AI") follows the last shown section. The quote card, NEED A HAND? and AL-ISLAMIC APPS are skipped.
- [ ] **Step 2:** The sidebar (`resourcesSectionSplit`) folds the same groups the same way.
- [ ] **Step 3: UITest** `testIslamMoreResourcesListsTools`: launch with `-launchTabIslam -seedBool simpleMode=1`; assert there is no "Zakah Calculator" text on the root; tap "More Resources"; assert "Zakah Calculator" exists. Expected: PASS.
- [ ] **Step 4:** Debug build; screenshots of the Simple and Full Islam root and More Resources.
- [ ] **Step 5:** Log the task; leave uncommitted.

### Task 9: Settings tab and finding it

**Files:**
- Modify: `iPhone/Settings/SettingsView.swift`: `settingsSections` (move `SimpleModeSection()` to just after the hub section, in both modes), `SimpleModeSection` (new caption), `appearanceControlEntries` (new entry)
- Modify: `iPhone/Settings/Pages/TipsAndTricks.swift` (`SettingsSpotlightSection` hides its cards in Simple and keeps the All Tips & Tricks row; a new tip, `app.simple`)
- Modify: `iPhone/Settings/Pages/HelpDoors.swift` (`islam(_:)` gains the door `islam.simple`)
- Modify: `iPhone/Settings/SettingsSearch.swift` (a destination for the Simple Mode page, if none fits)
- Test: `UnitTests/SimpleModeTests.swift`

**Interfaces:**
- Produces: `struct SimpleModeSettingsView: View`, a List holding `SimpleModeSection()` with the title "Simple Mode". The search entry, the tip and the door all land on it.
  - The door: title "Too Much on Screen?", caption "Simple Mode keeps each tab to its essentials.", answerName "Simple Mode", action `.toggle("Simple Mode", isOn: settings.simpleMode, systemImage: "rectangle.compress.vertical")`.
  - The search entry: title "Simple Mode", path "Settings", keywords "simple simpler busy clutter cluttered overwhelming essentials less minimal declutter".

- [ ] **Step 1: Write the failing test** `testSimpleModeIsSearchable`: `SettingsSearchEntry.appearanceEntries` contains an entry titled "Simple Mode" whose keywords contain "overwhelming".
- [ ] **Step 2:** Run it. Expected: FAIL.
- [ ] **Step 3:** Implement the interfaces.
  - Caption, on: "Each tab keeps to its essentials. Shortcuts wait in the ⋯ menu at the top of a tab, and extras like Need a Hand? and At a Glance step aside. Nothing is turned off: everything still works and is one tap away."
  - Caption, off: "Keeps each tab to its essentials: shortcuts move into a ⋯ menu at the top, and the extras step aside. Nothing is turned off, and turning this back off brings it all back."
- [ ] **Step 4:** Run the test. Expected: PASS. Debug build; screenshot the Settings root in Simple and Full. Expected: SIMPLE MODE directly under the hub; in Simple, no spotlight cards and one All Tips & Tricks row.
- [ ] **Step 5:** Log the task; leave uncommitted.

### Task 10: Quick Search Help trash

**Files:**
- Modify: `iPhone/Quran/QuranView.swift` (`searchHelpOverlayCard`, `shouldShowSearchHelpOverlay`), `iPhone/Hadith/Views/HadithView.swift` (its twin)
- Modify: `iPhone/Settings/Pages/HelpDoors.swift` (`HelpDoorsSettingsSection`: a "Quick Search Help" toggle for `.quran` and `.hadith`)
- Modify: `iPhone/Settings/Cloud/CloudManifest.swift` (both keys under preferences, beside `quranSearchHelpCollapsed`)

**Interfaces:**
- Produces: `@AppStorage("quranSearchHelpRemoved")` and `@AppStorage("hadithSearchHelpRemoved")`, both `Bool`, default `false`. A settings toggle shows "Quick Search Help" while the key is false (`isOn: !removed`).

- [ ] **Step 1:** While collapsed, a `trash` button sits beside the plus (`.accessibilityLabel("Remove search help")`). It raises the confirmation dialog "Remove Quick Search Help?", with the message "Your recent searches stay. You can bring the help back in Quran Settings." (Hadith Settings on that tab), a destructive Remove and a Cancel.
- [ ] **Step 2:** While removed, the card holds only the recent searches; with none, `shouldShowSearchHelpOverlay` is false.
- [ ] **Step 3:** Run `python3 Scripts/check_cloud_manifest.py` (expected: passes). Debug build. Screenshot with `-quranSearch ""` if it focuses the field; otherwise note the check as manual.
- [ ] **Step 4:** Log the task; leave uncommitted.

### Task 11: Settings pages lead with settings; the slim permission card

**Files:**
- Modify: `iPhone/Settings/Pages/SettingsAdhanView.swift` (the Prayer Settings root around `TipsSection(area: .adhan…)`, the Notifications root's `TipsSection(area: .notifications…)`, `permissionCard`)
- Modify: `iPhone/Settings/Pages/SettingsQuranView.swift`, `SettingsHadithView.swift`, `SettingsIslamView.swift` (their roots)

- [ ] **Step 1:** On each root, move `TipsSection` and `HelpDoorsSettingsSection` to just above the `AdvancedSettingsSection` (or to the end where a page has none).
- [ ] **Step 2:** `permissionCard`: when authorized with alerts and sounds on, render one row: `Label("Notifications Allowed", systemImage: "checkmark.seal.fill")`, accent tinted. Otherwise render today's full card. The watchOS branch is untouched.
- [ ] **Step 3:** Debug build; screenshots of Prayer, Quran and Notification Settings. Expected: each opens on a real setting; the permission row is one line.
- [ ] **Step 4:** Log the task; leave uncommitted.

### Task 12: The permission nags wait a day

**Files:**
- Modify: `iPhone/Settings/Model/Settings.swift`: `@AppStorage("locationAlertSnoozedUntil") var locationAlertSnoozedUntil: Double = 0` and the same for `notificationAlertSnoozedUntil`, beside `locationNeverAskAgain`; add both to that device-only key list
- Modify: `iPhone/Adhan/AdhanView.swift`: `nextAlertToPresent`, and the dialog binding's dismissal `set:` closure
- Modify: `iPhone/Settings/Cloud/CloudManifest.swift`: device-only
- Test: `UnitTests/SimpleModeTests.swift`

**Interfaces:**
- Consumes: `SimpleMode.isSnoozed(until:now:)`, `SimpleMode.nagSnooze`.
- Produces: `Settings.snoozePermissionAlert(location: Bool, now: Date = Date())`, which sets the matching key to `now.timeIntervalSince1970 + SimpleMode.nagSnooze`.

- [ ] **Step 1: Write the failing test** `testSnoozeSetsADay`: call `snoozePermissionAlert(location: true, now: t)`; assert `locationAlertSnoozedUntil == t.timeIntervalSince1970 + 86_400`; save and restore the key.
- [ ] **Step 2:** Run it. Expected: FAIL.
- [ ] **Step 3:** Implement.
  - `nextAlertToPresent` skips each permission alert while `isSnoozed`.
  - Any dismissal of `.locationAlert` or `.notificationAlert` (Ignore, Open Settings, a tap outside) calls `snoozePermissionAlert`. Never Ask Again keeps setting its permanent flag.
- [ ] **Step 4:** Run the test (expected: PASS) and `check_cloud_manifest.py` (expected: passes).
- [ ] **Step 5:** Log the task; leave uncommitted.

### Task 13: Location after the welcome

**Files:**
- Modify: `iPhone/Settings/Model/Settings.swift` (the `DispatchQueue.main.async { self?.requestLocationAuthorization() }` in init)
- Modify: `iPhone/Settings/Model/SettingsAdhan.swift` (`requestLocationAuthorization()`)
- Modify: `iPhone/Adhan/AdhanView.swift` (its first-appearance path, and the notification-prompt path in `prayerTimeRefresh`)

**Interfaces:**
- Produces:
  - `Settings.startLocationAtLaunch()`: init calls this. It runs today's body unless the status is `.notDetermined`, in which case it only starts the network monitor.
  - `Settings.requestLocationIfUndetermined()`: AdhanView calls this on appear once `appRevealed` is true.

- [ ] **Step 1: Audit the other location consumers** before changing anything: grep `currentLocation`, `requestLocation` and `locationManager` across the Islam tab (Masjid Locator, Halal Food), Qibla and the Widget. Write what each does on a fresh install with no fix into the progress log.
- [ ] **Step 2:** Implement.
  - The notification prompt waits while location is `.notDetermined`, then fires after the authorization callback. Never stack two system prompts.
- [ ] **Step 3: UITest** `testLocationPromptWaitsForTheWelcome`:
  1. `app.resetAuthorizationStatus(for: .location)`.
  2. Launch with `-seedBool THEfirstLaunch=1` and `-skipNotificationPrompt`.
  3. After 6 s, assert `springboard.alerts.count == 0` while "Get Started" exists.
  4. Tap through the splash (Task 14 adds step two: tap Continue). Then assert that a springboard alert appears within 10 s.
  5. `tearDown` relaunches with `-seedBool THEfirstLaunch=0`.

  If XCUITest cannot see the prompt on this runtime, record that and fall back to timed screenshots (3 s, then after the splash).
- [ ] **Step 4:** Log the task, plus a note for the next sibling sync: Al-Quran has no Adhan tab, so confirm it needs no location. Leave uncommitted.

### Task 14: Splash step two and the clipped row

**Files:**
- Modify: `iPhone/SplashScreen.swift`

**Interfaces:**
- Produces:
  - `@State private var step = 1` and `@State private var choosesSimple = false`.
  - DEBUG `-splashStep 2` (a `ProcessInfo` argument read once in `onAppear`, the file's existing launch-argument style).
  - `private func finishFirstLaunch()`, which writes `settings.simpleMode = choosesSimple` once, then `withAnimation { settings.firstLaunch = false }`.

- [ ] **Step 1: Write the failing UITest** `testSplashCanChooseSimple`:
  1. Launch with `-seedBool THEfirstLaunch=1,simpleMode=0` and `-skipNotificationPrompt`.
  2. Tap "Get Started"; assert the text "How much would you like to see?" exists.
  3. Tap "Simple", then "Continue".
  4. Tap the Quran tab; assert `app.buttons["tabMoreMenu"]` exists.
  5. `tearDown` restores both seeds to 0.
- [ ] **Step 2:** Run it. Expected: FAIL (there is no step two).
- [ ] **Step 3: Implement step two** per the guide's Splash section: copy verbatim, Full preselected, About You's option-card grammar, Back and Continue.
  - As a sheet (`presentedAsSheet`), the button keeps today's dismiss and never shows step two.
  - At accessibility sizes, step two scrolls.
- [ ] **Step 4: Fix the clipped last row** of step one.
  - First measure where the hero overlaps the scroll view's last line (screenshot at 13 s with `-seedBool THEfirstLaunch=1`).
  - Then fix it with the smallest change that fits the 17 Pro at the default size with no scrolling (the splash memory's standard): tighter card padding, or the hero at a smaller `heroFraction`.
- [ ] **Step 5:** Run the UITest (expected: PASS). Screenshot step two in dark and light, plus step one. Restore `-seedBool THEfirstLaunch=0,simpleMode=0`.
- [ ] **Step 6:** Log the task; leave uncommitted.

### Task 15: Verification sweep, review and memory

**Files:**
- Modify: `docs/Simple Mode Guide.md` (status table, progress log)
- Modify: the memory files `simple-mode.md` and `MEMORY.md`

- [ ] **Step 1: The full screenshot matrix** from the guide's Verification section: Simple and Full, dark and light, plus one accessibility size per tab. Read every image; fix anything clipped or misaligned before moving on.
- [ ] **Step 2: iPad.** On an iPad simulator (`xcrun simctl list devices available | grep iPad`), take one Simple screenshot each of the Quran, Hadith and Islam split views (Review Focus 3).
- [ ] **Step 3: The full UnitTests run** (`-only-testing:UnitTests`).
  - Launch once with `-displayQiraah ""` first (the riwayah seed trap).
  - Expected: no new failures. Rerun any CarPlay failure isolated.
- [ ] **Step 4:** `python3 Scripts/check_cloud_manifest.py` passes. `grep -rn "—"` over the touched files returns nothing.
- [ ] **Step 5: Review.** Dispatch a fresh `agent-skills:code-reviewer` on `git diff` for these files. Fix every confirmed finding.
- [ ] **Step 6:** Update the memory (Simple Mode's new rules, the More menu, the splash step, the tracker gate) and the guide's status table. Tell Abu what is modified and what the commit would contain; do not commit.
