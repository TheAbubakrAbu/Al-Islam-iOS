import SwiftUI

// The Simple Mode catalog (Docs/Product/Simple Mode v2 Design.md, Docs/Product/Simple Mode Guide.md).
//
// Every control Simple Mode hides is one `SimpleTrim` case with a surface, a title and a door (where
// the thing went). Views read a trim in one of two idioms: `settings.hides(.case)` /
// `settings.hides(.case, unless: keep)` on a view that already observes Settings, or the
// `.hiddenInSimple(.case)` modifier for pure-hide sites and the watch-shared helpers. No site reads
// the raw `simpleMode` flag any more. Scripts/check_simple_trims.py parses the `Entry(` lines below
// (keep them one per line, no double quote inside a string) to prove every case is read by some site,
// and the Simple Mode settings page lists `grouped`.
//
// `enum SimpleMode` (the tracker window and the nag snooze) lives here because every target compiles
// this file, so it holds only SwiftUI and Foundation.

enum SimpleTrim: String, CaseIterable, Identifiable {
    case needAHand
    case sectionCounts
    case sectionSearch
    case sectionShuffles
    case outlineStar
    case historyExpanders
    case heroStats
    case quickSearchHelp
    case optionalTimes
    case dateStepper
    case atAGlance
    case prayerTracker
    case travelFooter
    case calendarFootStepper
    case quranTodayPill
    case lastListenedTiles
    case wordOfDayTile
    case surahShuffle
    case sortRow
    case topSurahPair
    case ayahPlayMenu
    case ayahLongMenu
    case translationCaption
    case pageJuzLine
    case globalSearch
    case legendPill
    case mushafMeters
    case findWholeQuran
    case playRandomAyah
    case playOtherOptions
    case playTestMode
    case hadithTodayPill
    case bookStats
    case chapterStats
    case topChapterPair
    case foldedGroups
    case prophetQuote
    case appsSection
    case cardTodayPills
    case dailyHubShuffles
    case spotlightCards
    case pageTipsRows
    case pageHelpDoors

    var id: String { rawValue }

    /// The screens the Simple Mode page groups trims under, in the order it lists them.
    enum Surface: String, CaseIterable, Identifiable {
        case everywhere, adhan, quran, listReader, pageReader, playback
        case hadith, hadithBook, hadithReader, islam, destinations, settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .everywhere: return "Every tab"
            case .adhan: return "Adhan"
            case .quran: return "Quran tab"
            case .listReader: return "List reader"
            case .pageReader: return "Page reader"
            case .playback: return "Play menus"
            case .hadith: return "Hadith tab"
            case .hadithBook: return "Hadith book"
            case .hadithReader: return "Hadith reader"
            case .islam: return "Islam tab"
            case .destinations: return "Islam destinations"
            case .settings: return "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .everywhere: return "square.grid.2x2"
            case .adhan: return "safari.fill"
            case .quran: return "character.book.closed.ar"
            case .listReader: return "list.bullet"
            case .pageReader: return "book.pages"
            case .playback: return "play.circle"
            case .hadith: return "text.book.closed.fill"
            case .hadithBook: return "books.vertical.fill"
            case .hadithReader: return "text.alignright"
            case .islam: return "moon.stars.fill"
            case .destinations: return "rectangle.grid.2x2"
            case .settings: return "gearshape.fill"
            }
        }
    }

    /// Where a hidden thing went.
    enum Door: Equatable {
        case moreMenu(String)
        case settings(String)
        case longPress(String)
        case elsewhere(String)
        case dropped(String = "")

        var text: String {
            switch self {
            case .moreMenu(let item): return "⋯ menu › \(item)"
            case .settings(let path): return "Settings › \(path)"
            case .longPress(let item): return "Press and hold › \(item)"
            // A place reads as a phrase ("the bottom pair") in the catalog, but the page shows it as
            // a line of its own, so it starts with a capital there.
            case .elsewhere(let place): return place.prefix(1).uppercased() + place.dropFirst()
            case .dropped(let note): return note.isEmpty ? "Dropped" : "Dropped: \(note)"
            }
        }
    }

    struct Entry: Identifiable {
        let trim: SimpleTrim
        let surface: Surface
        let title: String
        let door: Door

        var id: SimpleTrim { trim }

        /// Unlabeled first argument so each entry reads `Entry(.needAHand, surface: ...)`.
        init(_ trim: SimpleTrim, surface: Surface, title: String, door: Door) {
            self.trim = trim
            self.surface = surface
            self.title = title
            self.door = door
        }
    }

    /// One entry per case, in case order, one per line (the script parses this shape).
    static let entries: [Entry] = [
        Entry(.needAHand, surface: .everywhere, title: "NEED A HAND? on every tab", door: .settings("each card's setting is a row on its own settings page")),
        Entry(.sectionCounts, surface: .everywhere, title: "Count pills and capsules on section headers and rows", door: .dropped()),
        Entry(.sectionSearch, surface: .everywhere, title: "The search glyph on BOOKMARKS and FAVORITES headers", door: .elsewhere("search's Bookmarks and Favorites filters")),
        Entry(.sectionShuffles, surface: .everywhere, title: "Shuffle buttons on section headers", door: .dropped()),
        Entry(.outlineStar, surface: .everywhere, title: "The outline star on a tile that is not a favorite", door: .longPress("Favorite")),
        Entry(.historyExpanders, surface: .everywhere, title: "The +/− history buttons on YOUR SUMMARY", door: .dropped()),
        Entry(.heroStats, surface: .everywhere, title: "The figures on a resource's hero card", door: .dropped()),
        Entry(.quickSearchHelp, surface: .everywhere, title: "Quick Search Help's examples on the Quran and Hadith tabs", door: .elsewhere("Tips & Tricks; the recent-search chips stay")),
        Entry(.optionalTimes, surface: .adhan, title: "The Optional Times pill", door: .settings("Prayer Settings › Optional Prayers")),
        Entry(.dateStepper, surface: .adhan, title: "The Showing prayers for date stepper, with Compare Today", door: .moreMenu("Prayer Calendar")),
        Entry(.atAGlance, surface: .adhan, title: "AT A GLANCE", door: .elsewhere("the date row, the location pill, the sky's moon and the city pill; the figures are dropped")),
        Entry(.prayerTracker, surface: .adhan, title: "PRAYER TRACKER until a prayer is marked within 14 days", door: .settings("Prayer Settings › Prayer Tracker; marking a prayer from its detail brings it back")),
        Entry(.travelFooter, surface: .adhan, title: "The travel footer under the prayer list", door: .elsewhere("the traveling banner, which opens Travel Settings")),
        Entry(.calendarFootStepper, surface: .adhan, title: "The Hijri Calendar's second year stepper", door: .elsewhere("the stepper at the top of IMPORTANT ISLAMIC DATES")),
        Entry(.quranTodayPill, surface: .quran, title: "The Today pill on the Quran tab's YOUR SUMMARY", door: .moreMenu("Today")),
        Entry(.lastListenedTiles, surface: .quran, title: "The Last Listened Ayah and Surah tiles", door: .elsewhere("the play menu's Play Last Listened Surah")),
        Entry(.wordOfDayTile, surface: .quran, title: "The Word of the Day tile", door: .moreMenu("Explore › Word of the Day")),
        Entry(.surahShuffle, surface: .quran, title: "The SURAHS shuffle", door: .moreMenu("Open a Random Surah")),
        Entry(.sortRow, surface: .quran, title: "The sort row, while the sort is surah ascending", door: .moreMenu("Sort")),
        Entry(.topSurahPair, surface: .listReader, title: "The top Previous/Next surah pair", door: .elsewhere("the bottom pair")),
        Entry(.ayahPlayMenu, surface: .listReader, title: "The ▶ button on each ayah", door: .elsewhere("the ayah ⋯ menu's Play This Ayah; More Actions… for the rest; a double tap on the ayah's text still plays it")),
        Entry(.ayahLongMenu, surface: .listReader, title: "The long ayah ⋯ menu", door: .elsewhere("five actions plus More Actions…, which opens the full actions sheet")),
        Entry(.translationCaption, surface: .listReader, title: "The default translation's name under the translation", door: .dropped()),
        Entry(.pageJuzLine, surface: .listReader, title: "The pinned page/juz line", door: .elsewhere("the inline page and juz dividers")),
        Entry(.globalSearch, surface: .listReader, title: "The Global button in the controls row", door: .elsewhere("the Quran tab's search")),
        Entry(.legendPill, surface: .listReader, title: "The Legend pill while nothing on the page is coloured (both readers)", door: .settings("Quran Settings › Arabic Text for tajweed, Highlight Themes for themes")),
        Entry(.mushafMeters, surface: .pageReader, title: "The footer's meters, percentages and progress bar", door: .dropped()),
        Entry(.findWholeQuran, surface: .pageReader, title: "Search the whole Quran in the find bar", door: .elsewhere("the Quran tab's search")),
        Entry(.playRandomAyah, surface: .playback, title: "Play Random Ayah in the Quran tab's play menu", door: .dropped()),
        Entry(.playOtherOptions, surface: .playback, title: "Other Options in the readers' play menus", door: .elsewhere("Play Custom Range is the play button's hold; repeats live in that sheet; the random picks are dropped")),
        Entry(.playTestMode, surface: .playback, title: "Test Mode in the readers' play menus, while Test Mode is off", door: .settings("Quran Settings › Test Mode")),
        Entry(.hadithTodayPill, surface: .hadith, title: "The Today pill on the Hadith tab's YOUR SUMMARY", door: .moreMenu("Today")),
        Entry(.bookStats, surface: .hadith, title: "A book's stats and era lines on the tab", door: .elsewhere("the book's own screen")),
        Entry(.chapterStats, surface: .hadithBook, title: "The CHAPTERS header's pills, each chapter's count and range", door: .elsewhere("the reading screen's chapter header")),
        Entry(.topChapterPair, surface: .hadithReader, title: "The top Previous/Next chapter pair", door: .elsewhere("the bottom pair")),
        Entry(.foldedGroups, surface: .islam, title: "TOOLS, SIGNS & PROOFS and ASK AI", door: .elsewhere("the More Resources row")),
        Entry(.prophetQuote, surface: .islam, title: "The Prophet Muhammad ﷺ quote card", door: .dropped()),
        Entry(.appsSection, surface: .islam, title: "AL-ISLAMIC APPS", door: .settings("the Settings tab's copy")),
        Entry(.cardTodayPills, surface: .islam, title: "The Today pills on the Reminder of the Day and Dua of the Day cards", door: .moreMenu("Today")),
        Entry(.dailyHubShuffles, surface: .destinations, title: "The shuffle circles on the Ayah and Hadith of the Day", door: .dropped()),
        Entry(.spotlightCards, surface: .settings, title: "The ONLY IN AL-ISLAM spotlight cards", door: .elsewhere("the All Tips & Tricks row")),
        Entry(.pageTipsRows, surface: .settings, title: "The Tips & Tricks row on each settings page", door: .settings("All Tips & Tricks")),
        Entry(.pageHelpDoors, surface: .settings, title: "NEED A HAND? on the settings pages", door: .dropped("the tab sections it controls are hidden too")),
    ]

    static func entry(for trim: SimpleTrim) -> Entry {
        guard let found = entries.first(where: { $0.trim == trim }) else {
            preconditionFailure("SimpleTrim.entries has no entry for \(trim)")
        }
        return found
    }

    /// The entries by surface, in `Surface.allCases` order; a surface with no entry is skipped.
    static var grouped: [(surface: Surface, entries: [Entry])] {
        Surface.allCases.compactMap { surface in
            let list = entries.filter { $0.surface == surface }
            return list.isEmpty ? nil : (surface: surface, entries: list)
        }
    }
}

extension Settings {
    /// Whether Simple Mode hides `trim`. The argument is unused by design: it is documentation and the
    /// hook Scripts/check_simple_trims.py greps for.
    func hides(_ trim: SimpleTrim) -> Bool {
        simpleMode
    }

    /// Whether Simple Mode hides `trim`, unless `keep` holds the control on screen (rule 2: something
    /// the person is using stays). The `trim` argument is unused by design, as above.
    func hides(_ trim: SimpleTrim, unless keep: Bool) -> Bool {
        simpleMode && !keep
    }

    /// Whether Simple Mode is the reason a screen's Advanced switch may be off (rule 9: turning Simple
    /// Mode on folds every one of them off, see `Settings.foldAllAdvancedSettings()`). Not a trim, since
    /// it hides nothing, so not a case: `AdvancedSettingsSection`'s caption reads it to say why.
    var simpleModeFoldsAdvanced: Bool {
        simpleMode
    }
}

/// The view-modifier form of `hides`. It owns an `@AppStorage("simpleMode")` so it re-renders on the
/// flip without observing every setting, which is also why the watch-shared helpers can use it.
struct SimpleTrimGate: ViewModifier {
    @AppStorage("simpleMode") private var simpleMode = false
    let keep: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if simpleMode && !keep {
            EmptyView()
        } else {
            content
        }
    }
}

extension View {
    /// Removes the view while Simple Mode is on, unless `keep` holds it. `trim` is documentation and the
    /// script's hook.
    func hiddenInSimple(_ trim: SimpleTrim, unless keep: Bool = false) -> some View {
        modifier(SimpleTrimGate(keep: keep))
    }
}

// MARK: - Simple Mode's rules (Docs/Product/Simple Mode Guide.md)

/// The rules Simple Mode's views share, kept pure so they are tested on their own (SimpleModeTests).
/// Here with the catalog, which every target compiles.
enum SimpleMode {
    /// How recent a tracker mark keeps the Adhan tab's PRAYER TRACKER on screen in Simple Mode: someone
    /// who tracks sees it, someone who never has is not handed an empty habit tracker on day one.
    static let trackerWindowDays = 14

    /// How long Ignore quiets the Adhan tab's location and notification dialogs (Abu, 2026-10-10: "for
    /// ignore snoozing make it wait a day"). Never Ask Again stays permanent.
    static let nagSnooze: TimeInterval = 86_400

    /// Whether any prayer was marked (on time, late or missed) on today or one of the `days - 1` days
    /// before it. At most `days` dictionary lookups: the Adhan tab asks on every countdown tick, so
    /// this never walks the whole history.
    static func markedRecently(
        _ tracker: [String: [String: PrayerMark]],
        today: Date,
        days: Int = trackerWindowDays,
        calendar: Calendar = .current,
        dayKey: (Date) -> String
    ) -> Bool {
        guard days > 0, !tracker.isEmpty else { return false }
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            if let marks = tracker[dayKey(day)], !marks.isEmpty { return true }
        }
        return false
    }

    /// Whether a dialog snoozed until `until` (seconds since 1970; 0 = never snoozed) is still quiet.
    static func isSnoozed(until: Double, now: Date) -> Bool {
        now.timeIntervalSince1970 < until
    }
}
