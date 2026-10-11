import SwiftUI

// Simple Mode (docs/Simple Mode Guide.md, agreed with Abu 2026-10-10): one switch, `Settings.simpleMode`,
// that keeps every tab to its essentials. Each site reads the switch itself; this file holds the ⋯ More
// menu a tab carries in Simple Mode, and the catalog below. The pure rules (`enum SimpleMode`: the
// tracker gate, the permission dialogs' snooze) live in SettingsAdhan.swift, which the widgets also
// compile.
//
// The rules (the guide has the reasons):
// 1. Hiding never changes what the app does. Every setting a hidden control drives keeps applying.
// 2. A control stays visible while its value is off its default (the sort row, the riwayah picker,
//    the Legend while anything is coloured): a screen must never be left unexplained.
// 3. Anything hidden from a tab stays one tap away: the tab's More menu, or Settings. Dropped outright,
//    as details rather than features: random picks other than Random Surah, Compare Today, the At a
//    Glance figures, the +/- history expanders, section count pills, the mushaf footer's meters and
//    percentages, the Prophet quote card.
// 4. Never hidden: what the user made, how scripture is shown, search, play, the gear, the Settings
//    tab, the prayer bells, and anything opened by a deliberate tap (long-press menus, sheets).
//
// The catalog of trims, each with where its function lives while hidden:
// - Every tab: NEED A HAND? (Settings; `HelpDoorsSection`), section count pills, search and shuffle
//   buttons (`SectionPillHeader`, `SurahsHeader`), the outline star on a non-favorite tile
//   (long-press; `gridFavoriteStar`).
// - Quran tab: reading mode, Planner and grid toolbar buttons, the door chips, the Today pill,
//   Random Surah (More menu); the Last Listened and Word of the Day tiles (the play menu; More).
// - List reader: the top Previous/Next pair (the bottom pair), the per-ayah play menu and the long
//   ayah menu (a five-action ayah menu plus More Actions, which opens the full actions sheet), the
//   default translation's name caption, the pinned page/juz line, the Global button. (The muqatta'at
//   header stays: it is its own only door, and a beginner's aid.)
// - Page reader: the footer's meters, percentages and progress bar (the Page and Juz buttons stay).
// - Adhan tab: the layout picker (Settings > Prayer Settings), Optional Times (Settings), the date
//   stepper (the Prayer Calendar), At a Glance (its doors live elsewhere), the travel footer (the
//   banner), the tracker until a prayer is marked within `trackerWindowDays`.
// - Hadith tab: the grid toggle, Topics, Encyclopedia, History, Today (More menu); book stats and
//   era lines (the book's own screen); chapter counts and ranges; the reader's top chapter pair.
// - Islam tab: Tools, Signs & Proofs and Ask AI (one More Resources row), the quote card, the
//   Al-Islamic Apps section (the Settings tab).
// - Settings tab: the spotlight cards (the All Tips & Tricks row stays).

#if os(iOS)

/// The ⋯ menu that leads a tab's toolbar in Simple Mode, holding what the tab's toolbar buttons and
/// door chips offer in Full Mode (rule 3). The gear never moves into it: it keeps its own slot.
struct SimpleMoreMenu<Items: View>: View {
    /// Observed for the tint. Not `@Environment(\.appearance)`: this view lives in a toolbar, the
    /// hoisted context where environment objects have failed to arrive in this app before.
    @ObservedObject private var settings = Settings.shared
    /// Something the menu started is still working (the Quran tab building its pages for Read as
    /// Pages): the label spins, as the reading-mode button it stands in for did.
    private let isBusy: Bool
    private let items: Items

    init(isBusy: Bool = false, @ViewBuilder items: () -> Items) {
        self.isBusy = isBusy
        self.items = items()
    }

    var body: some View {
        Menu {
            items
        } label: {
            if isBusy {
                ProgressView()
            } else {
                Image(systemName: "ellipsis.circle")
            }
        }
        .accessibilityLabel("More")
        .accessibilityIdentifier("tabMoreMenu")
        .tint(settings.accentColor.accent1)
    }
}

/// One item of a More menu: a plain `Label`, so the menu item's title is what VoiceOver reads.
///
/// Two traps, both met on 2026-10-10. A `square.grid.2x2.fill` icon made the item read as its
/// symbol's name ("Large Grid") instead of "Topics", so no item here uses that symbol. And hiding the
/// icon from accessibility (with an explicit label on the button) emptied EVERY item's label in the
/// system menu, so neither is done.
struct SimpleMoreMenuItem: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
    }
}

#endif
