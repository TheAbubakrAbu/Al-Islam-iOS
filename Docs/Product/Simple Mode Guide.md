# Simple Mode Guide

Working document for Claude Code sessions. Not user-facing. Abu asked on 2026-10-10: "Work on simple mode (its too cluttered and too complex easy to get overwhelemd. right now its worthless come up with a whole plan). then after Include simple mode in splash screen". This file is the design agreed that day. A session that hears "do Phase 3" (or "do the Adhan tab") reads this file, does that phase, ticks its boxes and adds a progress-log entry.

Nothing in the app was changed when this was written. Line numbers and symbols are from the 2026-10-10 tree (Save 28 plus the uncommitted work); re-grep before editing, never trust a number.

## Why it was worthless

`@AppStorage("simpleMode")` (Settings.swift, added 2026-10-07, OFF by default) answered Abu's 10-07 ask ("i want complicated and cluttered and complex stuff to disappear from the interface whether that be tool bar ... just make the app look less overwhelming") by hiding two things: the Quran tab's sort row (only while the sort is surah, ascending) and the readers' Legend button while nothing is coloured.

One rule kept it that small: "a control that is the only way to reach something may not hide". About 15 of the roughly 60 controls on the four content tabs are an only door (the Planner, History, the Rakaah Guide, the prayer layout picker, Topics and Encyclopedia, the shuffles), so almost nothing qualified. This design keeps the rule's intent, that nothing becomes unreachable, and changes its mechanism: an only door MOVES, into the tab's ⋯ More menu or into Settings, instead of blocking the trim.

## Decisions made (Abu, 2026-10-10)

- **Reach: trim plus a More menu**, and the Hadith tab stays a tab ("nah keep hadith but do everything else trim + more").
- **Controls only.** Simple Mode never touches tajweed colours, the Allah highlight, translations or any other reading setting.
- **Splash: a second step after Get Started**, Simple and Full cards, Full preselected. Existing installs are never asked and stay Full; the 10-07 "off by default for everyone" stands.
- **Added (everyone):** a trash button on a collapsed NEED A HAND? section ("when a tips tab is collapsed have a button to trash remove it") and on a folded Quick Search Help card.
- **Added (Simple):** the ayah ⋯ menu cut to five actions plus More Actions….
- **Added (everyone):** location asked after the welcome; settings pages open on their settings; a one-line permission card while notifications are allowed; Ignore on the permission nags waits a day ("for ignore snoozing make it wait a day").
- **The gear never moves** (Abu, after reading the guide: "keep the settings always at the top tool bar"). Every tab's and every reader's settings button stays in the top toolbar in both modes; the More menu never absorbs it.
- **Menus and sheets stay complete** (same message: "for context menus and sheets like that maybe show them all lowkey I don't know about that one your choice actually"). Chosen: every long-press menu and every sheet keeps its full list in both modes, because they are opened on purpose and add nothing to the screen. The one menu Simple trims is the visible ⋯ button on each ayah row.
- **Declined:** a silent first calculation-method pick (the Override/Confirm dialog stays as it is), delaying the iCloud offer, quieting achievement banners, any change to new-install alert defaults (Shurooq and the day-before Hijri alerts stay on), folding Hadith into the Islam tab, calmer Quran text in Simple.

## The rules

1. **Hiding never changes what the app does.** Every setting a hidden control drives keeps its value and keeps applying; switching Simple Mode off lands exactly where it started. (Unchanged from 10-07.)
2. **A control stays visible whenever hiding it would leave the screen unexplained**: once its value is off the default, it shows. Existing cases: the sort row (any sort but surah, ascending), the riwayah picker (any riwayah but Hafs), the Legend (anything coloured). Every new hide must ask this question.
3. **One tap away.** Anything hidden from a tab stays reachable in one tap from that tab's ⋯ More menu, or from Settings. Deliberately dropped in Simple, with no door, because they are details rather than features: random picks other than Random Surah (the bookmark and catalog shuffles), Compare Today, the At a Glance figures (daylight length, fasting window, distances), the +/− history expanders on summary tiles, section count pills, the mushaf footer's meters and percentages, the Prophet ﷺ quote card (one daily card per tab is enough).
4. **Never hidden by Simple Mode:** what the user made (bookmarks, favorites, notes, highlights); how scripture is shown (hadith grades, tajweed colours, the Allah highlight, translations, transliteration); search; play; the per-tab gear; the Settings tab; each prayer's notification bell; anything opened by a deliberate tap (a prayer's detail, the long-press sheets).
5. **No new behaviour key.** Simple Mode is the one existing `simpleMode` key (a preference: it syncs, and Reset clears it).
6. **Rows redraw on the flip.** A row type with an Equatable render signature folds `simpleMode` into its `==` if its body reads it, or the row keeps its old shape when the switch flips.
7. **iPad and Mac** follow the same rules wherever the same views build; a split view's sidebar toolbar carries the More menu.

## The More menu

**Since 2026-10-11 the ⋯ menu is every tab's leading button in BOTH modes** (Abu: "there are some things that I like that should always be there. for example always have the top left button just be a more button that contains grid and everything else"). `TabMoreMenu` (was `SimpleMoreMenu`) leads the Adhan, Quran, Hadith, Islam and Settings roots; the gear keeps its trailing slot on every tab and reader. What a tab's toolbar used to show as separate buttons is an item of its menu now, in both modes: the grid or list switch on every tab, the Quran tab's reading mode and Planner, the Adhan tab's Prayer and Hijri calendars and the prayer list's layout (a Prayer Times Layout submenu naming the layout in use, with TILES / GRID / LIST / SPLIT inside it; the PRAYER TIMES header no longer carries it). The doors Simple Mode takes off the screen (Today, History, Topics, ...) are items of the menu in both modes too. The Quran and Hadith summaries' door chips (Word of the Day, Browse by Theme, History; Topics, Encyclopedia, History) are gone in both modes since later that day (Abu: "put these top left no matter simple or normal and remove it from summary"): the menu is their only door now, and the Today pill is the one door left on the summary header in Full. Items keep the exact behaviour of the controls they replace (the reading-mode switch still asks to confirm). Order: places to open, a divider, then view choices. A pushed screen (a hadith book) keeps its own trailing buttons: its leading slot is Back.

Before 2026-10-11: the menu showed in Simple only, and Full Mode kept the individual toolbar buttons. The tables below say "More menu" for both.

## Per screen

Each table lists what Simple hides and where its function lives while hidden. Anything not listed stays as it is.

### Quran tab (QuranView.swift)

| Hidden in Simple | Where it lives |
|---|---|
| Reading-mode button (`book`), Quran Planner button, Grid/List toggle | More menu (in both modes since 2026-10-11) |
| Door chips: Word of the Day, Browse by Theme, History, Qiraat Explorer | More menu, in both modes since 2026-10-11 (the chips are gone from Full too; Qiraat Explorer only while `showOtherQiraatReciters`, as now) |
| The Today pill on YOUR SUMMARY | More menu |
| Last Listened Ayah, Last Listened Surah and Word of the Day tiles | the play menu's Play Last Listened Surah; Word of the Day in More |
| +/− history buttons on the summary tiles | dropped (rule 3) |
| NEED A HAND? | Settings (each card's target already lives there) |
| SURAHS count pill and shuffle | the shuffle becomes More › Open a Random Surah |
| Outline star on every surah grid tile (a favorite keeps its filled star) | long-press › Favorite Surah |
| Count, search and shuffle on the BOOKMARKS and FAVORITES headers | dropped; the sections and their collapse arrows stay; bookmarks are searchable through search's Bookmarks filter |
| Sort row | unchanged: hidden only while the sort is surah, ascending |

Stays: the Last Read Ayah and Ayah of the Day tiles, bookmarks, favorites, the surah grid, search, play.

More menu: Today, History, Browse by Theme, Word of the Day, Qiraat Explorer, Quran Planner (Hafs only, as now), Open a Random Surah; divider; Read as Pages or Read as List; Show as Grid or Show as List.

### List reader (SurahView.swift, AyahRow.swift)

| Hidden in Simple | Where it lives |
|---|---|
| Top Previous/Next surah pair | the bottom pair (both slots always render) |
| The ▶ `play.circle` menu on each ayah | the ⋯ menu's Play This Ayah; More Actions… for the rest |
| The long ⋯ menu (13 items, 35 actions, 5 submenus) | ⋯ shows Play This Ayah (Hafs only), Bookmark or Remove Bookmark, See Tafsir, Copy Ayah, Share Ayah, a divider, More Actions… (opens the long-press actions sheet, `requestSheet(.actions)`) |
| "Saheeh International" caption under the translation | dropped while it is the only translation on screen; "Clear Quran (Mustafa Khattab)" always keeps its name, being the off-default choice (rule 2) |
| Pinned page/juz line ("Page 42 (41/48) • Juz 3") | the inline page and juz dividers, which stay |
| Global search button in the controls row | the Quran tab's own search |

The 2026-09-05 parity rule ("every ayah menu offers the same actions in the same order") is suspended for the ⋯ button in Simple only. Long-press still opens the full sheet everywhere, the Quran tab's ayah context menu is untouched, and Full Mode keeps strict parity.

Stays: the Legend and the riwayah picker under their existing rules, the Bismillah row, the surah card, search, play.

### Page reader (MushafReader.swift)

| Hidden in Simple | Where it lives |
|---|---|
| The footer pill's Surah n/N and Juz n/N meters, its percentages and the whole-mushaf progress bar | dropped; the pill keeps "Page 42" and "Juz 3" as its two jump buttons |

Since 2026-10-11 the Simple pill is 44 pt tall instead of 62 (`footerHeight`), and the Play button beside it, a square of the same height, shrinks with it (Abu: "make the height of the button and the page/juz thing smaller"). Flipping the mode is one band change the page refits for once.

Everything else stays: the top strip, the controls row, search, play, the fold chevron.

### Adhan tab (AdhanView.swift, PrayerList.swift)

| Hidden in Simple | Where it lives |
|---|---|
| Layout picker (TILES / GRID / LIST / SPLIT) on PRAYER TIMES | since 2026-10-11 the header carries no picker in either mode: the tab's More menu holds it (an inline picker under the two calendars), and Settings › Prayer Settings' Prayer Times Layout row (built 2026-10-10) stays; same `prayerDisplayModeV2` key |
| Optional Times pill | Settings › Prayer Settings › Optional Prayers (exists) |
| "Showing prayers for" date stepper, with Compare Today | the Prayer Calendar (toolbar); Compare Today dropped (rule 3) |
| AT A GLANCE (12 tiles) | each destination keeps another door: the calendar button, the Qibla compass, the city pill, the sky's moon; the figures are dropped (rule 3) |
| PRAYER TRACKER section | shown once any prayer has been marked in the last 14 days; marking one from a prayer's detail (tap its tile) brings it back; its History & Insights page is a Prayer Tracker row in Settings › Prayer Settings (both modes) |
| NEED A HAND? | Settings |
| Travel footer under the prayer list | the traveling banner at the top, which stays |

Stays: the toolbar (calendar, gear), the date, location and Qibla card, the sky with its countdown and moon, the prayer tiles with their bells and tracker dots, every prayer's detail as it is today, the Rakaah Guide pill, the traveling banner.

The tracker gate must be cheap: the tab re-renders on every countdown tick. Read it from the tracker's day-keyed marks (at most 14 lookups) or the cached stats, never a history walk in a body.

### Hadith tab (HadithView.swift, HadithBookView.swift, HadithComponents.swift)

| Hidden in Simple | Where it lives |
|---|---|
| Grid/List toggle | More menu (in both modes since 2026-10-11) |
| Door chips Topics, Encyclopedia and History; the Today pill | More menu (the chips are gone from Full too since 2026-10-11; the Today pill stays on the header in Full) |
| The +/− history toggle on YOUR SUMMARY | dropped (rule 3) |
| NEED A HAND? | Settings |
| Count and shuffle on every catalog header, BOOKMARKS and FAVORITES | dropped (rule 3) |
| A book tile's stats line ("N • 97 Ch • 7,277 Ha") and era line; a list row's stat chips and era | the book's own screen (its hero card) |
| Book screen: the CHAPTERS header's stat pills; each chapter row's count pill and "Hadiths a–b" range | the reading screen's chapter header |
| Reading screen: the top Previous/Next chapter pair | the bottom pair |

Stays: Hadith of the Day, Last Read, bookmarks, favorites, every book, About Hadith & the Sunnah, search with its filters, every hadith's grade line.

More menu: Today, Topics, Encyclopedia, History; divider; Show as Grid or Show as List.

### Islam tab (IslamView.swift)

| Hidden in Simple | Where it lives |
|---|---|
| The TOOLS, SIGNS & PROOFS and ASK AI sections | one More Resources row after the last shown section, pushing a screen that lists those sections in the tab's grid or list form; search still finds every resource |
| The star on every tile (a favorite keeps its filled star) | the tile's long-press menu (`GridTileMenu`) |
| Section count pills | dropped (rule 3) |
| The Prophet Muhammad ﷺ quote card | dropped (rule 3); Reminder of the Day stays as the tab's daily card |
| NEED A HAND? | Settings |
| AL-ISLAMIC APPS | the Settings tab's copy, which stays |

Shown in Simple: Start Here (when it applies), Favorites, LEARN, REMEMBRANCE, FAITH & PRACTICE, More Resources, Reminder of the Day. The toolbar is the same in both modes: since 2026-10-11 the leading ⋯ More menu (holding the grid toggle) and the gear. The iPad and Mac sidebar keeps every section (as built 2026-10-10): its detail column cannot host the More Resources screen, whose tiles push onto the iPhone stack's path, and a sidebar is a list of places anyway. The quote card and AL-ISLAMIC APPS step aside there too.

### Settings tab (SettingsView.swift)

| Hidden in Simple | Where it lives |
|---|---|
| The ONLY IN AL-ISLAM spotlight cards (12) | the section keeps its All Tips & Tricks row |

For everyone: the SIMPLE MODE section moves up to sit directly under the SETTINGS hub, so the way back out is easy to find. Since 2026-10-11 the tab's grid toggle is the one item of a leading ⋯ More menu, in both modes (it was a trailing button). The settings pages are not touched by Simple Mode; their per-screen Advanced switches already do that job.

### Section headers (`SectionPillHeader`, ViewExtensions.swift)

In Simple the header drops its count pill, its search button and its shuffle; one change covers the Quran, Hadith and Islam tabs. The collapse arrow stays, and so does the new trash. `SurahsHeader` lays its cluster out by hand and needs the same treatment.

## Help surfaces: trash when collapsed (everyone)

- **NEED A HAND?** (`HelpDoorsSection`, all four tabs). While folded, a trash button sits just before the arrow: `SectionPillHeader` gains `onRemove`, drawn only while `isExpanded` is false, and the header's ordering comment becomes count, search, shuffle, trash, arrow. A tap raises a confirmation dialog (a dialog, never an alert): title "Remove Need a Hand?", message "It leaves the \(area.tabName) tab. You can bring it back in \(area.settingsPageName).", buttons Remove (destructive) and Cancel. Remove calls `setShowsHelpDoors(area, false)`, the existing Hide on This Tab switch, so nothing new is stored.
- **Quick Search Help** (the Quran tab's `searchHelpOverlayCard` and the Hadith tab's twin). While folded (+), a trash button sits beside the +, with the same dialog grammar. New keys `quranSearchHelpRemoved` and `hadithSearchHelpRemoved`, preferences like their `*SearchHelpCollapsed` siblings. Once removed, the card keeps only the recent searches (the TRY examples leave with the help); with no recent searches there is no card. The way back is a Quick Search Help switch in the help block at the bottom of Quran Settings and Hadith Settings.

## Settings pages lead with settings (everyone)

On Prayer Settings, Notifications, Quran Settings, Hadith Settings and Islam Settings, `TipsSection` and `HelpDoorsSettingsSection` move from the top of the page to the bottom, just above the ADVANCED section, which stays last. Notifications has only the Tips row to move. Each page then opens on its first real setting (today Prayer Settings' first setting starts about 60% of the way down the screen).

Notification Settings' permission card: while notifications are allowed (authorized, alerts and sounds on) it is one quiet row, "Notifications Allowed". The full card (the status rows, Request Access, Open Settings) appears only when something is wrong: not determined, denied, provisional, or alerts or sounds off.

## Nags wait a day (everyone)

The Adhan tab's "Location Access Needed" and "Notifications Off" dialogs (`nextAlertToPresent`) return on every refresh today, so Ignore lasts only until the next app open. New: any dismissal other than Never Ask Again (Ignore, Open Settings, a tap outside) snoozes that dialog for 24 hours, in `locationAlertSnoozedUntil` and `notificationAlertSnoozedUntil` (device-only: permission is per device). Never Ask Again stays permanent.

## Location after the welcome (everyone)

Today `Settings.init` calls `requestLocationAuthorization()` one main-queue tick after init, so a new install's system location prompt lands over the launch animation, before the splash has said Assalamu Alaikum.

New: while the authorization status is `.notDetermined`, the request waits for the first time the Adhan tab is on screen after reveal (`appRevealed`), where the notification prompt already lives. Authorized installs are unchanged: significant-change monitoring and the launch fix still start at init.

- Two system prompts must never stack: location first, then the notification prompt once location is answered.
- Check in planning that nothing outside the Adhan tab relies on the launch request: the Islam tab's locators, the Qibla screens, the widgets. Each must still work, or ask in context.
- Al-Quran has no Adhan tab, so it would never ask. At the next sibling sync, confirm it needs no location; if it does, call the same hook at reveal.

**2026-10-11, the permissions sheet (Abu: "have location and notification permissions come as a separate sheet").** The bare system prompts no longer lead. When the Adhan tab is first in front after the welcome and either permission is `.notDetermined`, it presents `PermissionsSheet` (iPhone/Adhan/Location/PermissionsSheet.swift): one card per permission with its status pill and its own Allow button, and a primary button that asks for both in turn (location first). Not Now (or a swipe) snoozes whatever is still unanswered for a day through the same `locationAlertSnoozedUntil` / `notificationAlertSnoozedUntil` keys the nags use, and while a snooze stands the tab refreshes WITHOUT raising a system prompt (`requestNotificationAuthorization(askIfUndetermined: false)`, and `requestLocationIfUndetermined` is skipped). The sheet is the one door to those prompts from the tab; Settings' Request Access still asks on demand. `PermissionsSheet.shouldPresent` is the pure rule (SkyWeatherTests pins it). DEBUG: `-skipNotificationPrompt` never shows it (every headless recipe, and the UI tests above still see the bare location prompt), `-showPermissionsSheet` always does.

## Splash: choosing Simple or Full (SplashScreen.swift)

**2026-10-19: the splash is a walk through pages now** (Abu: "for splash screen force them to go through it ... instead of asking location and notification at the same time have them be buttons in a splash screen page ... tips and tricks ... simple mode ... icloud"). `SplashScreen.pages`: what the app is (the old step one), About You (`AboutYouView(embedded:)`), Location and Notifications (`WelcomePermissionsPage`, WelcomePages.swift, `#if HAS_ADHAN`), then "A lot to discover" (`WelcomeDiscoverPage`: the pitch, the Tips & Tricks tour door, and the Simple or Full cards below); on Al-Islam the iCloud offer is the stage after it. Every page ends in `WelcomeActionBar` with a Skip that skips that page alone, and nothing leaves the whole walk at once (Abu, same day: "have each page option have a skip button but don't have way to leave the tutorial completely"): the first page, both steps of About You (Skip on its tailored page keeps the answer and leaves the suggested settings; Back sits beside it), the permissions page whether or not anything was answered, the discover page, and the iCloud offer with or without an account. The permissions page's Skip snoozes whatever is unanswered for a day, so the Adhan tab's sheet never follows the welcome with the same question. Progress dots sit in the bar's centre. `-splashStep N` lands on page N. The "step two" below is that discover page's lower half; the rest of this section is as written on 10-10.

- **Step one** is unchanged except for its clipped last row ("...see it on the App Store." is cut off behind the app-family hero). Page one must fit the iPhone 17 Pro at the default text size again; measure before touching it.
- **Step two.** On a first launch, step one's button (Get Started, or Done after an App Store tap) moves to step two in place; it is not a new root stage. Its title is "How much would you like to see?", above two option cards in About You's option-card grammar (icon tile, title, caption, radio):
  - Simple: "Prayer times, the Quran and the essentials, with the extras tucked away until you want them." (As first written it said "Everything else is one tap away", which the More Resources screen and the dropped details made untrue; changed after the review.)
  - Full: "Every tool, shortcut and detail, right on screen."
  - Full is preselected. The footnote reads "You can change this any time in Settings › Simple Mode."
  - Continue (primary) writes `settings.simpleMode` once, then ends the splash through the existing `firstLaunch = false`. Back (secondary text button) returns to step one.
- **As a sheet** (Islam tab › Learn More), step two never shows and the button stays Done: a promotional sheet never changes a setting.
- **Siblings.** The file is shared with Al-Adhan and Al-Quran, and they get the step at the next sync (`simpleMode` lives in the shared Settings.swift). Do not run the sync.
- **DEBUG:** `-splashStep 2` lands on step two for screenshots.
- About You is untouched: it neither asks about nor reads Simple Mode, so its "Nothing in the app is locked or hidden by it" stays true.

## Finding it (everyone)

- **Settings search:** a Simple Mode entry in `appearanceEntries`, keywords simple, simpler, busy, clutter, cluttered, overwhelming, essentials, less, minimal, declutter.
- **Tips & Tricks:** a tip in FINDING THINGS that opens the section.
- **NEED A HAND? on the Islam tab:** a "Too Much on Screen?" door whose answer is Simple Mode's switch. It only ever appears in Full, because Simple hides the section.
- **Caption.** `SimpleModeSection`'s caption is rewritten to say what moves where, and the doc comment on `simpleMode` gets the new rule 3. Neither may promise anything this guide does not do.

## Small fixes along the way (everyone)

- **Done:** the actions sheet's Compare Ayah tile is a plain button when it holds a single choice.
- **Kept, on reading the code:** "Play Custom Range" in both the Repeat Ayah and Play Ayah submenus is deliberate (a custom range repeats too; the code says so). The reader's play menu counts Forever, 20 down to 2 because it opens upward from the bottom bar, which puts 2 by the thumb, as 2 is in the ayah menus that open downward.
- **Tips:** the tips that teach a control Simple Mode removes (the layout menu, the Optional Times pill, the date picker, At a Glance, the shuffles, the summary doors, Need a Hand?) are not offered while Simple Mode is on (`TipCatalog.outsideSimpleMode`).

## Architecture

- **One switch**, read directly at each site (`settings.simpleMode`). Two alternatives were rejected:
  - per-element switches, which rebuild the clutter as settings
  - separate simple copies of each tab, which means two copies of 6,000-line views that drift apart
- **A new file**, `iPhone/Helpers/UI/SimpleMode.swift`, iOS-only.
  - It holds the More menu's shared label and helpers, plus a catalog comment listing every trim and its door (this guide's tables, kept beside the code).
  - QuranView also compiles into the Watch target, so every reference from it to this file sits inside `#if os(iOS)`. `simpleMode` itself is declared outside the iOS-only blocks, so `SectionPillHeader` can read it on the watch.
  - Register the file by hand in project.pbxproj, iPhone target only. Object IDs are 22 or 24 hex characters.
  - The siblings will need the file at the next sync; the sync report lists new files.
- **New keys**, each classified in CloudManifest.swift (or `Scripts/check_cloud_manifest.py` fails):
  - `quranSearchHelpRemoved` and `hadithSearchHelpRemoved`: preference
  - `locationAlertSnoozedUntil` and `notificationAlertSnoozedUntil`: device-only

  Nothing else is new: the layout row and the NEED A HAND? trash reuse existing keys.
- **Equatable signatures** to check for `simpleMode`: AyahRow, the surah grid tile and list row, the hadith book tile and row, the chapter rows. Grep `static func ==` in each before editing.
- **No writes from a body.** Never write `@AppStorage` or UserDefaults from a body, timer or scroll handler. The splash writes once, on Continue.

## Verification

- **Build after each phase:** a Debug build of scheme `iPhone` (all targets, the Watch included). Read the result from `grep -E "BUILD (SUCCEEDED|FAILED)"`, never from a piped exit code.
- **Screenshot pairs**, Simple against Full (`-seedBool simpleMode=1` and `=0`), on the iPhone 17 Pro. Cover:
  - Adhan
  - the Quran root
  - the list reader (`-quranListMode -lastRead 2:255`)
  - the page reader (`-quranPageMode -mushafPageLanguage arabic`)
  - the Hadith root, a book and the reader
  - the Islam root and More Resources
  - the Settings root
  - splash steps one and two (`-seedBool THEfirstLaunch=1`, plus `-splashStep 2`; restore with `-seedBool THEfirstLaunch=0`, because the flag persists)
  - Prayer, Quran and Notification Settings

  Shoot each in dark and light, at the default text size and an accessibility size.
- **Live flip:** with a reader open, flipping Simple Mode in Settings redraws the rows (this is the Equatable check).
- **Unit tests.** Register each new file in project.pbxproj: the UnitTests target is not synchronized, so an unregistered file runs zero tests and still says SUCCEEDED. Cover:
  - the splash choice writes `simpleMode`, and the sheet never does
  - the tracker gate: marked 13 days ago shows, 15 days ago hides
  - the nag snooze: a dismissal snoozes for 24 hours, and Never Ask Again stays permanent
  - each trash path sets its key
- **Full UnitTests run** at the end. The CarPlay tests fail only in the full run from order pollution; rerun those isolated before blaming a change.
- `Scripts/check_cloud_manifest.py` passes.
- **iPad and Mac:** one Simple screenshot of each split tab.

## Noticed, not in scope

- The notification settings pages raise their own "Notifications Off" dialog every time they open (three sites in SettingsAdhanView). Once the full permission card says the same thing in place, the dialog may be redundant.
- The "please open the app to refresh" pushes at noon after two idle days.
- `notificationDuha`, `notificationIslamicMidnight` and `notificationLastThird` default to true. They stay silent only because their show switches default to off.
- The sort menu's "Page Count" and "Pages" read alike.

## Build order

| Phase | What | Status |
|---|---|---|
| 1 | The kit and Settings: SimpleMode.swift, the More menu, `SectionPillHeader` (the Simple trims and the trash), the SIMPLE MODE section's move and caption, the search entry, the tip, the "Too Much on Screen?" door | done 2026-10-10/11 |
| 2 | Quran tab root | done 2026-10-10/11 |
| 3 | List and page readers: the ayah ⋯ menu and the small menu fixes | done 2026-10-10/11 |
| 4 | Adhan tab, and the Prayer Times Layout row | done 2026-10-10/11 |
| 5 | Hadith tab: the root, the book and the reading screens | done 2026-10-10/11 |
| 6 | Islam tab and More Resources | done 2026-10-10/11 |
| 7 | For everyone: both trash buttons, settings pages leading with settings, the slim permission card, the nag snooze, location after the welcome | done 2026-10-10/11 |
| 8 | Splash step two and the clipped row | done 2026-10-10/11 |
| 9 | The verification sweep and the memory update | done 2026-10-10/11 |

Each phase ends with a Debug build and its screens' Simple and Full screenshots. Phase 7 does not depend on Simple Mode and can ship on its own.

## Progress log

- **2026-10-11, the More menu for everyone (Abu: "Go through simple mode. there are some things that I like that should always be there").**
  - **Every tab root leads with the ⋯ menu in both modes.** `SimpleMoreMenu` and `SimpleMoreMenuItem` are `TabMoreMenu` and `TabMoreMenuItem` (SimpleMode.swift). Quran: `QuranLeadingToolbar` lost its Full Mode branches (the book button and the planner button are gone; the planner stays mounted buttonless behind the menu in both modes), `QuranTrailingToolbar` lost its grid button and `listForJump`. Hadith: `HadithTrailingToolbar.moreMenuItems` is always set by the root; the book screen passes nil and keeps its chapter grid toggle. Settings: `settingsMoreMenu` (leading) replaces `settingsGridButton` (trailing). Islam: the stack and the sidebar each put `TabMoreMenu { islamGridMenuItem }` in the leading slot and call `islamSettingsToolbar()` for the gear alone. Islam was not named in the ask; it got the menu so no tab is the odd one out.
  - **Adhan.** `adhanMoreItems`: Prayer Calendar and Hijri Calendar (through `pushedCalendar`, the glance tiles' pushes, so the menu and a tile can never stack two), a divider, a "Prayer Times Layout" title and an inline `Picker` over `PrayerList.PrayerDisplayMode` (new `menuSymbol`), the current layout ticked. The haptic lives in the binding's setter (`prayerLayoutSelection`): an `onChange` on a view inside a menu is not reliably alive. `PrayerList.sectionHeader` keeps only the title and the qasr badge ("remove it from where it was originally"). The calendar toolbar button is gone; its tip and the layout tip were reworded, and the layout tip is offered in both modes again.
  - **Page reader.** `footerHeight` is 44 in Simple, 62 in Full; the Play button follows.
  - **Settings tiles.** `SettingsGridTile`'s caption is one line at the standard sizes (`minimumScaleFactor` 0.75), wrapping only at the accessibility sizes, as `toolLabel`'s captions already did ("make sure each caption line is line limit 1").
  - **Tests.** `SimpleModeUITests` gained `testQuranMoreMenuLeadsInFullMode`, `testAdhanMoreMenuHoldsTheCalendarsAndTheLayout`, `testIslamMoreMenuHoldsTheGridSwitch` and `testSettingsAndHadithMoreMenusHoldTheGridSwitch`. The Settings one failed twice in sequenced runs on the iOS 27 simulator (the tap opened no menu; the recording shows none), then passed four times running with the same code; the Adhan one then failed once with the cause in the log: "Found 1 interrupting element: NotificationShortLookView", a notification banner (the app's own prayer alerts, frequent with the simulator's clock and city) over the toolbar at the moment of the tap. XCUITest checks for interruptions BEFORE it taps, so a banner arriving a fraction of a second later eats the tap unseen. Every More-menu tap in the suite now goes through `openMoreMenu`, which retries up to three times and swipes a banner away first. Not a product bug: a trailing probe menu, the conditional wrapper (the Islam tab's, which passes) and the test order were each ruled out before the banner was caught.
  - **Screenshots (iPhone 17 Pro, dark):** Adhan, Quran, Hadith, Islam and Settings roots in Full with the ⋯ leading; Adhan in Simple; the page reader in both modes (the Simple footer row is visibly shorter, Play included); the Settings grid with one-line captions.

- **2026-10-11, later: the chips go, the layout becomes a submenu, the captions shorten (Abu, with two screenshots of the chip rows: "put these top left no matter simple or normal and remove it from summary").**
  - **Quran and Hadith summaries.** The door chips under the tiles (Word of the Day, Browse by Theme, History, Qiraat Explorer; Topics, Encyclopedia, History) are gone in BOTH modes. The ⋯ menu already held every one of them, so nothing moved: `summaryTilesSection` lost its `doors` row and `QuranView` its `SummaryDoorChip`, `summaryDoors`, `summaryDoorButton`, `openDoor(_:)` and `summaryDoorChip`; `HadithView` lost `encyclopediaDoors`, `encyclopediaDoorButtons`, `doorButton` and `doorChip`, and its summary section now renders only with a tile in it (`showSummaryTiles`) in both modes, as Simple already did. `EvenChipRows` (ViewExtensions.swift) had no other user and is gone. The Today pill stays on the summary header in Full. The Word of the Day still fills an odd grid as a tile; with an even grid it is in the menu alone.
  - **Adhan.** The layout is a submenu now ("for adhan for top left the prayer layout have it be a menu that opens the other"): a nested `Menu` whose label is `Label("Prayer Times Layout", systemImage:)` plus a second `Text` naming the layout in use (iOS draws it as the row's subtitle, the Files app's Sort By), with the inline `Picker` inside. The recording shows the row as "Prayer Times Layout › / Tiles" and the submenu unfolding under it with Tiles ticked.
  - **Settings tiles.** The captions were still truncating at the 0.75 floor ("looks chopped so shorten the actual text"), so they are shorter now and the rows say the same words: "Calculation, offsets, travel, sky", "Fonts, tajweed, reciters, themes", "Arabic and English, reading view", "Arabic font, libraries, reminders", "Background, accent, the glow", "Opening tab, Liquid Glass, haptics" (companions: "List style, Liquid Glass, haptics"). The 0.75 floor was already there; the screenshot shows every caption whole on one line.
  - **Tips.** The Hadith "Topics, Encyclopedia, History" tip points at the ⋯ menu and shows in both modes.
  - **Tests.** `testAdhanMoreMenuHoldsTheCalendarsAndTheLayout` opens the submenu first and seeds `travelAutomatic=0` with the two "ask me" flags cleared: the first run found Tiles and Grid, then the app's own "Traveling Mode On" card (this simulator sits 382 mi from its saved home) closed the menu before List was checked, and a second run met the card again from the persisted flag. `tearDown` seeds `travelAutomatic=1` back.
  - **The blank Look and Feel (not Simple Mode, but reported with it: "Look and feel opened a couple times as a blank tab then after a couple loaded properly").** Reproduced by UI test on the first try once the test tapped the tile: four tile taps in five opened nothing. The simulator log, with temporary NSLogs on the doors, showed each tap raising `gridDoor` + `openGridDoor` and `EmptyDoor` closing the push ten milliseconds later: `navigationDestination(isPresented:)` built the destination the moment the Bool flag turned true and read the separately stored target stale (nil, or an earlier tap's door, which is why the fifth tap "worked" and why Abu saw it load "after a couple"). On a device the cancelled push is a blank page sliding back. The three Settings doors (profile tiles, grid tiles, spotlight cards and search results) are one optional each now, pushed with the new `pushDestination(item:)` (`PushItemDestination`, Globals.swift); `anyDoorOpen` compares them to nil. Sweep of every `pushDestination` / `navigationDestination(isPresented:)` site in the app: only `MiraclesView`'s prose-link door had the same flag-plus-target shape, and it is converted; the rest were already item-shaped (Quran/Hadith summary doors, Arabic, Dua, Pillars, Hadith book) or fixed destinations. `EmptyDoor` stays as the floor and logs in DEBUG if it ever fires again. Regression tests: `testSettingsGridTilesPush` (every tile opens on the first tap) and `testLookAndFeelOpensFromEveryDoor` (tile, list row, straight after a pop, after a grid switch, search result).

- **2026-10-11, the Adhan tab's sky.** Three things Abu asked for the same day, none of them Simple Mode but all on this tab: Sky Fills the Screen (`skyFillsAdhanTab`, off; `SkyPageBackground` under the whole List, rows on `SkyPageFill.rowColor`, dark scheme on the content only), Apple Weather on the sky (`skyShowsWeather`, OFF and opt-in because the location string promises the location stays on the device; SkyWeather.swift is the shared model and tint, SkyWeatherStore.swift the app-only fetch with a half-hour cadence and the app-group cache the widgets read; Al-Islam ONLY behind the project-level `HAS_WEATHER` flag, which both sync manifests skip, so the companion apps compile none of it and the splash names it among Al-Islam's exclusives with iCloud Backup, Tips & Tricks and the stickers), and the permissions sheet above. The automatic-change dialogs were rewritten to one short sentence and two plain buttons (`Settings.AutoChangeCard`).

- **2026-10-10, Task 1 (kit and rules).** Added `iPhone/Helpers/UI/SimpleMode.swift` (the catalog comment and `SimpleMoreMenu`, iPhone target only) and `enum SimpleMode` at the end of SettingsAdhan.swift (the tracker gate and the snooze; the Widget compiles that file). Added `Settings.trackerMarkedRecently(now:)`, a new rule in the `simpleMode` doc comment, and `UnitTests/SimpleModeTests.swift` with 3 tests, all passing. The flip test settles the host launch first: an unsettled run blamed the flip for `surahOpenCountsData`, which the launch's reopened reader writes. `Scripts/xcode_register.py` cannot place a file in a group indented five tabs deep (iPhone/Helpers/UI); an indentation-tolerant copy did it. Full Debug build EXIT 0.
- **2026-10-10, Task 2 (headers and the trash).**
  - `SectionPillHeader`: new `onRemove`, a trash drawn only while folded (count, search, shuffle, trash, arrow). In Simple it drops its count, search and shuffle; it watches `@AppStorage("simpleMode")` itself rather than Settings.
  - `SurahsHeader` and `JuzHeader` follow suit.
  - `HelpDoorsSection` hides in Simple on all four tabs. In Full, its folded header's trash raises "Remove Need a Hand?", whose Remove calls `setShowsHelpDoors(area, false)`.
  - Screenshots: Full Hadith folded shows count, trash, arrow; Simple shows no section and BOOKMARKS with only its arrow.
  - The accessibility-size check moved to Task 15's sweep.
- **2026-10-10, Task 3 (Quran tab).**
  - The leading toolbar in Simple is one `SimpleMoreMenu`: Today, History, Browse by Theme, Word of the Day, Qiraat Explorer, Quran Planner, Open a Random Surah, then Read as Pages/List and Show as Grid/List.
  - The trailing toolbar keeps khatm (khatm sort only) and the gear.
  - `SummaryDoor` gained `.daily`, so the More menu pushes Today through the doors' one destination and guard. `ReadingModeConfirmation` is shared by the book button and the menu.
  - `QuranPlannerToolbarButton` gained `hidesButton`/`presentRequest`: in Simple it stays mounted behind the menu, so its settle hooks keep stamping a finished plan (rule 1).
  - The summary in Simple is Last Read and the Ayah of the Day only (no expanders, no chips, no Today pill); the section is skipped if both are absent.
  - `gridFavoriteStar` now draws through `GridFavoriteStar`, which hides a non-favorite's star in Simple. All six tile kinds offer Favorite on long-press.
  - UITest `testQuranMoreMenuHoldsTheMovedDoors` passes; the first run tapped More under the launch cover, so the helper now waits 8 s.
  - Screenshots: Simple (two tiles, ⋯ and gear), Full unchanged, Simple plus juz sort keeps the sort row.
- **2026-10-10, Task 4 (list reader, ayah menu).**
  - **Simple hides:** the top Previous/Next pair, the pinned page/juz line, the Global button, and the per-ayah ▶ menu. `surahListTopTargetID` mirrors the hidden pair, so a swap never scrolls to a missing anchor.
  - **The ⋯ menu** shows `simpleMenuBlock`: Play This Ayah (Hafs), Bookmark, See Tafsir, Copy, Share, then More Actions…, which opens `requestSheet(.actions)`. The translation-name caption drops while one translation shows.
  - `simpleMode` joined `ayahRenderSettingsSignature`, which every Equatable ayah row compares.
  - The one-item Compare tile is a button now.
  - **Three planned items were dropped after reading the code:**
    - the muqatta'at header (no Settings switch exists, so it is its own only door, and it helps beginners)
    - "Play Custom Range" in both submenus (deliberate, its comment says a range repeats too)
    - the reversed Repeat order (deliberate, the bottom-bar menu opens upward so 2 sits by the thumb)
  - UITest `testAyahMenuIsFiveActionsInSimple` passes.
- **2026-10-10, Task 5 (page reader).** In Simple the footer pill keeps its height and shows only the Page and Juz jumps, in a new `prominent` size. No meters, percentages or bar. Screenshot checked.
- **2026-10-10, Task 6 (Adhan).**
  - **Simple hides:** the layout picker, Optional Times (the Rakaah Guide goes full width), the travel footer, and AT A GLANCE.
  - **The date stepper** stays while another day is on screen (rule 2).
  - **The tracker** shows only after a mark within 14 days (`showsTracker`).
  - **New:** a Prayer Times Layout picker in Prayer Settings (same `prayerDisplayModeV2` key, iOS only) and its search entry.
  - Screenshots: Simple Adhan ends at the Rakaah Guide; the Prayer Settings picker reads Split.
- **2026-10-10, Task 7 (Hadith).**
  - **Toolbar:** a More menu (Today, Topics, Encyclopedia, History, Show as Grid/List; `SummaryDoor.daily`) and the gear.
  - **Summary:** tiles only. No Today pill, no +/− expander, no door chips; the section is skipped when there are no tiles.
  - **Books:** tiles drop the stats and era (height 100 to 72); rows drop the stat chips and era.
  - **Book screen:** no CHAPTERS stat pills, chapter count pills or ranges (the grid tile shrinks from 76 to 60).
  - **Reader:** the top chapter pair is hidden, and `showsTopChapterNav` re-aims both scroll targets.
  - **VoiceOver bug, menu items:** a `square.grid.2x2.fill` icon made a menu item read as "Large Grid" instead of its title. Topics is now `tag.fill` and Browse by Theme `rectangle.stack.fill`.
  - **VoiceOver bug, a failed fix:** hiding the icon from accessibility emptied EVERY item's label, so `SimpleMoreMenuItem` stays a plain `Label`.
  - UITest `testHadithMoreMenuOpensTopics` passes; it checks Topics and Show as Grid by name.
- **2026-10-10, Task 8 (Islam).**
  - **Folding:** TOOLS, SIGNS & PROOFS and ASK AI fold into a More Resources row (`IslamDestination.moreResources`, pushed by value, never `available`). Its screen lists them in the tab's grid or list form.
  - **Row tap:** a plain Button there never took the tap in the UI test, so the row is a `GridTileMenu` (with "Open More Resources" on the hold), as the banners are.
  - **Also hidden:** the quote card and AL-ISLAMIC APPS.
  - UITest `testIslamMoreResourcesListsTools` passes. The `-islamDestination moreResources` screenshot shows the folded groups.
- **2026-10-10, Task 9 (Settings and finding it).**
  - SIMPLE MODE now sits under the hub in both modes, with a new caption.
  - In Simple the spotlight is one All Tips & Tricks row under "TIPS & TRICKS".
  - New Settings search entry (destination `.simpleMode`, `-settingsOpen simpleMode`) on a `SimpleModeSettingsView` page.
  - New tip `app.simple`, and the Islam door `islam.simple` ("Too Much on Screen?", Full only).
  - Unit test `testSimpleModeIsSearchable` passes.
- **2026-10-10, Task 10 (Quick Search Help trash).** Both tabs:
  - a trash beside the + while folded
  - the dialog hung on the list, not the card
  - removed means recents only, and no card without recents
  - Quran and Hadith Settings carry the "Quick Search Help" switch
  - both keys are preferences in CloudManifest
- **2026-10-10, Task 11 (settings lead with settings).** On five pages, Tips and Need a Hand? move to the foot, above ADVANCED. The permission card is one "Notifications Allowed" row (redacted while loading) unless authorization, alerts or sounds are not fully on.
- **2026-10-10, Task 12 (nags wait a day).** `locationAlertSnoozedUntil` and `notificationAlertSnoozedUntil` (device-only). Any dismissal but Never Ask Again snoozes for `SimpleMode.nagSnooze`. Unit test `testSnoozeSetsADay` passes.
- **2026-10-10, Task 13 (location after the welcome).**
  - **Launch:** `Settings.init` calls `startLocationAtLaunch()`, which only starts the network monitor while undetermined (the watch keeps its launch request).
  - **Adhan tab:** `askLocationThenRefresh()` asks location first, then runs the refresh that carries the notification question. A one-shot waiter in `didChangeAuthorization` sequences the two.
  - **Off-screen at reveal:** location waits for the tab; the refresh runs as before.
  - **Audit:** the Masjid and Halal Food locators already request in context; widgets read the app group.
  - **Next sibling sync:** Al-Quran has no Adhan tab, so confirm it needs no location.
- **2026-10-10, Task 14 (splash).**
  - **Step two:** a Simple or Full step (Full preselected; Back and Continue; `-splashStep 2`). Continue writes `simpleMode` once, then ends the splash; the sheet never reaches the step.
  - **Step one:** the clipped last row is fixed by `heroFraction` 0.8 to 0.74. Measured: the card's bottom edge now clears the hero on the 17 Pro.
- **2026-10-19 (the welcome walk).** The splash became the pages listed under "Splash" above (SplashScreen.swift, WelcomePages.swift; About You embedded, the permissions page over `PermissionAsker`/`PermissionCards` shared with the sheet, the Simple or Full cards moved to the discover page). UITests/SimpleModeUITests `testSplashCanChooseSimple` and `testLocationPromptWaitsForTheWelcome` walk the new pages. `testEveryWelcomePageSkipsOnlyItself` walks the whole welcome by Skip alone.
- **2026-10-11, Task 15 (sweep and review).**
  - **Tests:**
    - The full UnitTests suite: 299 tests, 16 skipped, and 2 `AdhanCatchUpOfferTests` failures. The run landed one minute after Fajr in the sim's city, and the live host app was really playing the catch-up adhan. All 7 pass in isolation.
    - `SimpleModeTests`: all 5 pass.
    - `SimpleModeUITests`: the More menus, the ayah menu, More Resources, the splash choice, the location timing, the Quick Search Help trash and the Hadith book all pass.
  - **Screenshots:** Simple and Full in dark and light, at an accessibility size, and on an iPad Pro 13-inch split view (the More menu sits in each sidebar).
  - **Review fixes:**
    - (critical) The Control Center "Open Qibla" control was answered only by the glance card, which Simple unmounts. AdhanView answers it now through `GlanceCard.qiblaValues`.
    - Islam search's "Scroll To" for a folded resource scrolls to the More Resources row.
    - The iPad column migration never carries `.moreResources` into the detail column.
    - The moon-preview reset moved from the date footer to the section.
    - "Too Much on Screen?" keeps its section while its sheet is up.
    - The Mustafa caption always shows.
    - The Need a Hand? settings caption mentions Simple.
    - The copy no longer promises one tap for everything.
    - The trimmed tips hide in Simple.
    - The More menu spins while Read as Pages prepares.
    - A Prayer Tracker row in Prayer Settings.
    - Simple Mode's switch is iOS-only.
    - Landscape drops its page/juz line too.
    - The divider rows keep feeding the last-read anchor in Simple (rule 1).
  - **Declined:** moving `SimpleMoreMenu`'s tint to `@Environment(\.appearance)`, because it sits in a toolbar, where environment objects have not always arrived in this app.
