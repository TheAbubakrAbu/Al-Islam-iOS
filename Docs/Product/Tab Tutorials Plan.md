# Tab Tutorials Implementation Plan

> Built natively in one session (Abu, 2026-10-31), one fresh review of the whole change at the end. Steps use checkboxes.

**Goal:** one beginner tutorial per tab (Adhan, Quran, Hadith, Islam), opened from the tab, its settings, the welcome and search, plus a one-time nudge on each tab.

**Architecture:** one new file, `iPhone/Settings/Pages/TabTutorials.swift`, holds the model, the catalogue, the views and the presenter. The paged walkthrough is extracted from `TipsTourView` so both tours share `TourPager` and `TourCard`. The tutorial sheet is presented from ONE place, the tab bar root (`.tabTutorialPresenter()`), driven by `TabTutorialPresenter.shared`, so no tab grows another sheet bridge.

**Tech stack:** SwiftUI, iOS 16 floor (iOS 15 fallbacks kept where the helpers have them), XCTest.

**Spec:** `Docs/Product/Tab Tutorials Design.md`, with Abu's answers to its section 8 (2026-10-31): first-visit nudge YES; "Show me" opens settings and pickers only; a "New to This Tab?" door in each Need a Hand? YES.

## Global constraints

- Every card is true today, checked against the code (the four 2026-10-31 survey reports, file:line).
- No em dashes, no spaced hyphens, in copy, comments or docs.
- Every new string gets Arabic and Urdu (`Scripts/localize_catalog.py` sync, todo, merge, check).
- iPhone target only; the file compiles in Al-Adhan and Al-Quran, so tab cases and steps are gated by `HAS_ADHAN`, `HAS_QURAN`, `HAS_HADITH`, `HAS_WEATHER`.
- Six to ten available cards per tab, in Full and in Simple Mode.
- A "Show me" setting opens as the root of what opens (`SettingsSearchDestinationView.view(for:)`), pushed in the tutorial's own stack; Back returns to the card.
- No defaults write inside a body, an `onAppear` or an `onDisappear`: the nudge's seen set is written only from button actions.
- Simulator: iPhone 17 Pro.

## Review focus

1. A tutorial requested while another sheet is up (the ⋯ menu on iPad, a nudge tap mid-presentation) must not wedge presentation: the presenter ignores a request while one is showing.
2. "Show me" from a tutorial pushed inside a reader's settings sheet still pushes (`pushDestination` on the tutorial view, not links inside the pager).
3. Simple Mode on: the cards about trimmed things hide and every tab still has six to ten (test).
4. Al-Adhan's build (no `HAS_QURAN`, no `HAS_HADITH`): the Islam cards never name the Tajweed Course or the Quran (test on the gate where possible; companion build later).
5. Accessibility sizes and Arabic: a card with two buttons scrolls, the nudge wraps, "N of M" uses local digits.

## Files

| File | Change |
|---|---|
| `iPhone/Settings/Pages/TabTutorials.swift` | NEW: `TutorialTab`, `TutorialStep`, `TutorialAction`, `TutorialCatalog`, `TabTutorialView`, `TutorialNudgeSection`, `TabTutorialPresenter` + `tabTutorialPresenter()`, `TutorialDoorRow`, `SettingsSearchEntry.tutorialEntries`, the seen set on `Settings`. |
| `iPhone/Settings/Pages/TipsAndTricks.swift` | `TourPager`, `TourCard` extracted; `TipsTourView` calls them; `TipsSection` gets the tutorial row first. |
| `iPhone/Settings/SettingsView.swift` | `Destination.tutorial(TutorialTab)` and its icon. |
| `iPhone/Settings/SettingsSearch.swift` | Scope and `view(for:)` for `.tutorial`; `all` adds `tutorialEntries`. |
| `iPhone/Settings/Pages/HelpDoors.swift` | A "New to This Tab?" door leads each tab's run. |
| `iPhone/Settings/Model/Settings.swift`, `SettingsSlices.swift` | `@Setting("tutorialNudgesSeen")`, device-only, in `SystemSettings.keys`. |
| `iPhone/Adhan/AdhanView.swift`, `iPhone/Quran/QuranView.swift`, `iPhone/Hadith/Views/HadithView.swift`, `iPhone/Islam/IslamView.swift` | "Tutorial" item in the ⋯ menu; the nudge section. |
| `iPhone/Al-IslamApp.swift` | `.tabTutorialPresenter()` on the tab view. |
| `iPhone/WelcomePages.swift` | LEARN EACH TAB card on "A lot to discover". |
| `UnitTests/TabTutorialsTests.swift` | NEW, registered with `Scripts/xcode_register.py`. |
| `Resources/Localizable.xcstrings` | New keys, ar + ur. |
| `Scripts/qa/screens.txt` | Lines for `-tutorial <tab>`. |

## Interfaces

```swift
enum TutorialTab: String, CaseIterable, Identifiable   // adhan (HAS_ADHAN), quran (HAS_QURAN), hadith (HAS_HADITH), islam
    var title: String            // "Adhan Tutorial"
    var tabName: String          // "Adhan"
    var summary: String          // the nudge's caption
    var tint: Color, secondaryTint: Color?, tipsArea: TipArea
    init?(tipsArea: TipArea); var helpDoorArea: HelpDoorArea

enum TutorialAction {            // Identifiable by label
    case setting(SettingsSearchEntry.Destination, label: InterfaceText)
    case homeCity                 // HAS_ADHAN: MapView(choosingPrayerTimes: false) as a sheet
    case tips(TipArea)            // TipsView(area:)
}

struct TutorialStep: Identifiable {
    let id: String; let tab: TutorialTab; let systemImage: String
    let title, detail, place: InterfaceText
    var actions: [TutorialAction] = []; var showsHomeCity = false
    var isAvailable: () -> Bool = { true }
}

enum TutorialCatalog { static let all: [TutorialStep]; static func steps(for: TutorialTab) -> [TutorialStep] }

extension Settings { func tutorialNudgeSeen(_: TutorialTab) -> Bool; func markTutorialNudgeSeen(_: TutorialTab) }

@MainActor final class TabTutorialPresenter: ObservableObject { static let shared; @Published var showing: TutorialTab?; func open(_: TutorialTab) }
struct TabTutorialView: View { init(tab: TutorialTab, presentedAsSheet: Bool, initialPage: Int = 0) }
struct TutorialNudgeSection: View { init(tab: TutorialTab) }
struct TourPager<Card: View>: View { init(ids: [String], initialPage: Int = 0, onFinish: @escaping () -> Void, card: (Int) -> Card) }
struct TourCard: View { systemImage, tint, secondaryTint, index, count, title, detail, place, status: String?, buttons: [TourCard.Button] }
```

## Tasks

### Task 1: the shared pager
- [ ] Extract `TourPager` and `TourCard` from `TipsTourView` / `TipTourCard`; `TipsTourView` becomes a caller. No visual change to the tips tour.
- [ ] Build; the existing `TipsCatalogTests` pass.

### Task 2: model, catalogue and tests
- [ ] Write `TabTutorialsTests`: ids unique; each offered tab has 6 to 10 available steps with Simple Mode off and on; every `.setting` destination is one some `SettingsSearchEntry.all` entry opens (compared by `view(for:)`'s case, through a `destinationKey` string); no English copy holds an em dash or " - "; at most two actions per step; the Adhan home city step has `.homeCity` first; the nudge seen set round-trips and writes nothing when already seen.
- [ ] Register the test file; run it; it fails to compile.
- [ ] Write the types and the catalogue from the survey reports.
- [ ] Run the tests; they pass.

### Task 3: the views and the presenter
- [ ] `TabTutorialView` (sheet: `SheetNavigationContainer`, house X, `startLarge`; pushed: no X), one `pushDestination(item:)` for `.setting`/`.tips`, one `.sheet` for `.homeCity`, Finish marks the nudge seen.
- [ ] `TabTutorialPresenter` + `.tabTutorialPresenter()` on the tab view in Al-IslamApp.swift; DEBUG `-tutorial <tab>` and `-tutorialCard <n>`.
- [ ] `TutorialNudgeSection`: a card with "Take the Tutorial" and an X; both mark seen.

### Task 4: entry points
- [ ] ⋯ menu "Tutorial" on all four tabs (end of the places group).
- [ ] The nudge on each tab: Adhan above the prayer list (and in the no-prayers branch); Quran, Hadith, Islam directly above Need a Hand?, not while searching.
- [ ] `TipsSection` first row; `Destination.tutorial` + search entries; Need a Hand? door; welcome LEARN EACH TAB card.
- [ ] Build and run the full UnitTests.

### Task 5: localization, QA, docs
- [ ] `localize_catalog.py sync`, `todo` (ar, ur), translate, `validate`, `merge`, `check` both.
- [ ] Simulator (iPhone 17 Pro): each tutorial, light and dark, accessibility size, Arabic; Show me lands as the root; the nudge on each tab.
- [ ] `Scripts/qa/screens.txt` lines; mark the design doc built; memory updated.
- [ ] One fresh reviewer over the whole diff.
