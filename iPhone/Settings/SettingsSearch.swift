import SwiftUI

// Settings search, page by page (2026-09-16). The Settings tab's root search indexes every setting;
// this file gives each settings page (Prayer, Notifications, Quran, Hadith, Appearance) a search bar
// of its own over that page's slice of the same index, with results that push the exact sub-screen
// (Arabic Text, Traveling Mode, ...) instead of landing on the page's root. The sub-screens are named
// by the page enums below, which the root search's deep links use too.

// MARK: - The pages a result can land on

/// The Quran settings' sub-screens, each a row on the Quran Settings root.
enum SettingsQuranPage: String, CaseIterable, Hashable {
    case recitation, readingView, arabicText, englishText, highlightThemes, sunnahReminders, favorites

    var title: String {
        switch self {
        case .recitation: return "Recitation"
        case .readingView: return "Reading View"
        case .arabicText: return "Arabic Text"
        case .englishText: return "English Text"
        case .highlightThemes: return "Highlight Themes"
        case .sunnahReminders: return "Sunnah Reminders"
        case .favorites: return "Favorites and Bookmarks"
        }
    }

    var systemImage: String {
        switch self {
        case .recitation: return "headphones"
        case .readingView: return "book"
        case .arabicText: return "textformat.ar"
        case .englishText: return "textformat"
        case .highlightThemes: return "paintbrush.pointed.fill"
        case .sunnahReminders: return "bell.badge"
        case .favorites: return "star"
        }
    }

    /// One line of what lives behind the row.
    var caption: String {
        switch self {
        case .recitation: return "Reciter, recitation type, what plays next"
        case .readingView: return "List or pages, dividers, the Quran tab"
        case .arabicText: return "Fonts, tajweed, riwayat, word by word"
        case .englishText: return "Translations and transliteration"
        case .highlightThemes: return "Color-coded passages and lit themes"
        case .sunnahReminders: return "Al-Kahf on Friday, al-Mulk before sleep"
        case .favorites: return "Edit surahs, ayahs, letters, khatm"
        }
    }
}

/// The prayer settings' sub-screens.
enum SettingsAdhanPage: String, CaseIterable, Hashable {
    case prayerCalculation, travelingMode, optionalPrayers, manualOffsets, customPrayerNames, sky, skyColors

    var title: String {
        switch self {
        case .prayerCalculation: return "Prayer Calculation"
        case .travelingMode: return "Traveling Mode"
        case .optionalPrayers: return "Optional Prayers"
        case .manualOffsets: return "Manual Offsets"
        case .customPrayerNames: return "Custom Prayer Names"
        case .sky: return "Sky"
        case .skyColors: return "Sky Colors"
        }
    }

    var systemImage: String {
        switch self {
        case .prayerCalculation: return "function"
        case .travelingMode: return "airplane"
        case .optionalPrayers: return "moon.stars"
        case .manualOffsets: return "slider.horizontal.3"
        case .customPrayerNames: return "character.cursor.ibeam"
        case .sky: return "sun.horizon.fill"
        case .skyColors: return "paintpalette"
        }
    }

    var caption: String {
        switch self {
        case .prayerCalculation: return "Method, angles, madhab, high latitude"
        case .travelingMode: return "Shorten and combine while away"
        case .optionalPrayers: return "Duha, Islamic midnight, last third"
        case .manualOffsets: return "Nudge each prayer and the Hijri date"
        case .customPrayerNames: return "Call the prayers what you call them"
        case .sky: return "Sun arc, moon and stars, skyline, colors"
        case .skyColors: return "Two colors per prayer for the sky"
        }
    }
}

/// The notification settings' sub-screens.
enum SettingsNotificationsPage: String, CaseIterable, Hashable {
    case prayerReminders, naggingMode, sunnahReminders

    var title: String {
        switch self {
        case .prayerReminders: return "Prayer Reminders"
        case .naggingMode: return "Nagging Mode"
        case .sunnahReminders: return "Sunnah Reminders"
        }
    }

    var systemImage: String {
        switch self {
        case .prayerReminders: return "bell.and.waves.left.and.right.fill"
        case .naggingMode: return "exclamationmark.bubble.fill"
        case .sunnahReminders: return "bell.badge"
        }
    }

    var caption: String {
        switch self {
        case .prayerReminders: return "Per-prayer alerts and early warnings"
        case .naggingMode: return "Asks \u{201C}Did you pray?\u{201D} until you answer"
        case .sunnahReminders: return "Al-Kahf on Friday, al-Mulk before sleep"
        }
    }
}

/// The hadith settings' sub-screens.
enum SettingsHadithPage: String, CaseIterable, Hashable {
    case readingView, arabicText, englishText

    var title: String {
        switch self {
        case .readingView: return "Reading View"
        case .arabicText: return "Arabic Text"
        case .englishText: return "English Text"
        }
    }

    var systemImage: String {
        switch self {
        case .readingView: return "book"
        case .arabicText: return "textformat.ar"
        case .englishText: return "textformat"
        }
    }

    var caption: String {
        switch self {
        case .readingView: return "The name of Allah in red"
        case .arabicText: return "Show Arabic, its face and size"
        case .englishText: return "Show English, its size"
        }
    }
}

/// A sub-screen of Islam Settings - the fourth area, for everything that is not the Quran, the prayer
/// times or the hadith books.
enum SettingsIslamPage: String, CaseIterable, Hashable {
    case arabicText, alphabet, libraries, sunnahReminders

    var title: String {
        switch self {
        case .arabicText: return "Arabic Text"
        case .alphabet: return "Arabic Alphabet"
        case .libraries: return "Libraries"
        case .sunnahReminders: return "Sunnah Reminders"
        }
    }

    var systemImage: String {
        switch self {
        case .arabicText: return "textformat.ar"
        case .alphabet: return "abc"
        case .libraries: return "square.grid.2x2"
        case .sunnahReminders: return "bell.badge"
        }
    }

    var caption: String {
        switch self {
        case .arabicText: return "The face for duas, dhikr, names, letters; Highlight Allah"
        case .alphabet: return "Arabic size, English readings, sukoon"
        case .libraries: return "Grid or rows, Word of the Day, Fajr"
        // The same words the Quran and Notifications rows carry: it is the same screen, reached
        // from a third door.
        case .sunnahReminders: return "Al-Kahf on Friday, al-Mulk before sleep"
        }
    }
}

/// A sub-screen of Appearance. The section sits inline on the Settings tab, and it had grown to a
/// dozen controls there (Abu, 2026-09-21: "parts of the appearance settings should be placed in a
/// navigationlink like other settings"): the theme and the accent swatches stay on the tab, and
/// everything set once and left alone is one push away, the way the other areas are laid out.
enum SettingsAppearancePage: String, CaseIterable, Hashable {
    case customColors, lookAndFeel

    /// "Open the App On" is Al-Islam's alone. The companion apps share these files but not their
    /// roots (each has its own tabs, and nothing there reads the choice), so they leave the picker
    /// out: a control the app never reads is exactly what that setting was added to put right.
    static let offersLaunchTab = AppIdentifiers.appName == "Al-Islam"

    var title: String {
        switch self {
        case .customColors: return "Custom Colors"
        case .lookAndFeel: return "Look and Feel"
        }
    }

    var systemImage: String {
        switch self {
        case .customColors: return "eyedropper.halffull"
        case .lookAndFeel: return "slider.horizontal.3"
        }
    }

    var caption: String {
        switch self {
        case .customColors: return "Your own background and accent, the glow"
        case .lookAndFeel: return Self.offersLaunchTab ? "Opening tab, list style, Classic Look, haptics" : "List style, Classic Look, haptics"
        }
    }
}

// MARK: - Row tints

/// The Settings hub's colours, one per area, so a glance finds the row before a word is read (the
/// iOS Settings app's grammar). The three content areas are FIXED whatever accent the user picked
/// (Abu, 2026-09-16): prayer yellow, Quran green, hadith blue.
enum SettingsTint {
    static let notifications = Color(red: 0.93, green: 0.36, blue: 0.32)
    static let prayer = Color(red: 0.98, green: 0.75, blue: 0.18)
    static let hadith = Color(red: 0.24, green: 0.56, blue: 0.96)
    static let quran = Color.green
    /// Islam Settings wears BOTH of Al-Islam's colours rather than one of its own: the section is
    /// app-wide (the Arabic face, the libraries, the daily reminders) instead of belonging to a single
    /// tab, so it gets the brand pair, yellow at the top-leading corner into green at the bottom-trailing
    /// (Abu, 2026-09-19). Same two colours as the Top Accent Glow option in Appearance.
    static let islam = Color(red: 0.98, green: 0.75, blue: 0.18)
    static let islamSecondary = Color.green
    static let appearance = Color(red: 0.62, green: 0.40, blue: 0.93)
    static let credits = Color(white: 0.55)
    static let sky = Color(red: 0.98, green: 0.58, blue: 0.24)
}

/// A settings row in the iOS Settings app's visual grammar: the icon on a small tinted chip, the
/// title, an optional caption under it, and an optional value at the trailing edge. The hub, every
/// settings page's root, and the search results all use it, so the whole Settings tab reads as one.
struct SettingsRowLabel: View {
    let title: String
    let systemImage: String
    var subtitle: String? = nil
    /// The chip's colour; nil is the app accent.
    var tint: Color? = nil
    /// A second chip colour, for a row whose area is not one tab - see `AccentIconChip`.
    var secondaryTint: Color? = nil
    /// A short state read-out ("On", "3 passages") at the trailing edge.
    var value: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage, tint: tint, secondaryTint: secondaryTint)

            // The title never wraps: a long value ("All passages · 2 themes") shrinks and then
            // truncates before the title gives up a line.
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // The caption column is an iPhone luxury - the 40mm screen has no room for it.
                #if os(iOS)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                #endif
            }
            .layoutPriority(1)

            if let value {
                Spacer(minLength: 8)

                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.vertical, 3)
    }
}

#if os(iOS)
// MARK: - The index, sliced per page

/// Which settings page an entry belongs to: the slice a page's own search bar searches.
enum SettingsSearchScope: Hashable {
    /// `general` is the Settings tab's own root (About You, every Tips & Tricks list): no page
    /// searches that slice, the root's search covers it.
    case notifications, prayer, quran, hadith, islam, appearance, credits, general

    var placeholder: String {
        switch self {
        case .notifications: return "Search notifications"
        case .prayer: return "Search prayer settings"
        case .quran: return "Search Quran settings"
        case .hadith: return "Search hadith settings"
        case .islam: return "Search Islam settings"
        case .appearance: return "Search appearance"
        case .credits: return "Search credits"
        case .general: return "Search settings"
        }
    }

    /// The title of the entry that IS the page ("Quran Settings"), left out of that page's results.
    var rootTitle: String {
        switch self {
        case .notifications: return "Notification Settings"
        case .prayer: return "Prayer Settings"
        case .quran: return "Quran Settings"
        case .hadith: return "Hadith Settings"
        case .islam: return "Islam Settings"
        case .appearance: return "Appearance"
        case .credits: return "Credits & Contact"
        case .general: return "Settings"
        }
    }

    /// The breadcrumb prefix a page's results drop, because the reader is already on that page.
    var pathPrefix: String {
        switch self {
        case .notifications: return "Notifications"
        case .prayer: return "Prayer Settings"
        case .quran: return "Quran Settings"
        case .hadith: return "Hadith Settings"
        case .islam: return "Islam Settings"
        case .appearance: return "Appearance"
        case .credits: return "Credits"
        case .general: return "Settings"
        }
    }
}

extension SettingsSearchEntry.Destination {
    /// A page's root rather than one of its sub-screens: on that page's own search such a result
    /// has nowhere to push and says "this page" instead.
    var isPageRoot: Bool {
        switch self {
        case .notifications, .prayerSettings, .quranSettings, .hadithSettings, .islamSettings, .appearance, .credits: return true
        default: return false
        }
    }

    var scope: SettingsSearchScope {
        switch self {
        case .notifications, .notificationReminders, .notificationsPage: return .notifications
        case .prayerSettings, .prayerTracker, .travelingMode, .prayerCalculation, .skyColors, .prayerPage: return .prayer
        case .quranSettings, .reciters, .quranPage: return .quran
        case .hadithSettings, .hadithPage: return .hadith
        case .islamSettings, .islamPage: return .islam
        case .appearance, .appearancePage: return .appearance
        case .aboutYou, .cloudBackup: return .general
        // A page's own tips belong to that page's search; the door to all of them, to the root's.
        case .tips(let area):
            switch area {
            case .adhan: return .prayer
            case .notifications: return .notifications
            case .quran: return .quran
            case .hadith: return .hadith
            case .islam: return .islam
            case .app, .none: return .general
            }
        case .credits, .credit: return .credits
        }
    }
}

extension SettingsSearchEntry {
    /// The whole index, composed from the per-screen lists that live next to the screens they describe.
    static let all: [SettingsSearchEntry] =
        notificationEntries
        + adhanEntries
        + prayerCalculationEntries
        + quranEntries
        + hadithEntries
        + islamEntries
        + appearanceEntries
        + aboutYouEntries
        + cloudBackupEntries
        + tipsEntries
        + creditEntries

    static func entries(in scope: SettingsSearchScope) -> [SettingsSearchEntry] {
        all.filter { $0.destination.scope == scope }
    }

    /// Ranked keyword results: every query term must match somewhere (title, path, or keywords,
    /// diacritic-insensitive), and results order by WHERE they matched - title prefix first, then
    /// title, then path, then keywords-only - so "not" puts Notifications above rows that merely
    /// mention it. Ties keep the index's hand-authored order.
    static func rank(_ entries: [SettingsSearchEntry], query rawQuery: String) -> [SettingsSearchEntry] {
        let query = rawQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        guard !query.isEmpty else { return [] }
        let terms = query.split(separator: " ").map(String.init)

        func fold(_ text: String) -> String {
            text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        }

        let scored: [(entry: SettingsSearchEntry, score: Int, order: Int)] = entries.enumerated().compactMap { order, entry in
            let title = fold(entry.title)
            let path = fold(entry.path)
            let keywords = fold(entry.keywords)
            var score = 0
            for term in terms {
                if title.hasPrefix(term) { score += 40 }
                else if title.split(separator: " ").contains(where: { $0.hasPrefix(Substring(term)) }) { score += 24 }
                else if title.contains(term) { score += 16 }
                else if path.contains(term) { score += 8 }
                else if keywords.contains(term) { score += 4 }
                else { return nil }   // every term must land somewhere
            }
            return (entry, score, order)
        }
        return scored
            .sorted { ($0.score, -$0.order) > ($1.score, -$1.order) }
            .map(\.entry)
    }
}

// MARK: - Where a result lands

/// The app-wide mapping from a search destination to its screen, for the root search and for any
/// page whose own resolver has nothing to say about a destination.
enum SettingsSearchDestinationView {
    @ViewBuilder
    static func view(for destination: SettingsSearchEntry.Destination) -> some View {
        switch destination {
        case .notifications: NotificationView()
        case .notificationReminders: MoreNotificationView()
        case .notificationsPage(let page): NotificationView(openPage: page)
        case .prayerSettings: SettingsAdhanView(showNotifications: false)
        case .prayerTracker: PrayerTrackerView()
        case .travelingMode: SettingsAdhanView(showNotifications: false, openPage: .travelingMode)
        case .prayerCalculation: SettingsAdhanView(showNotifications: false, openPage: .prayerCalculation)
        case .skyColors: SettingsAdhanView(showNotifications: false, openPage: .skyColors)
        case .prayerPage(let page): SettingsAdhanView(showNotifications: false, openPage: page)
        case .quranSettings: SettingsQuranView()
        case .reciters: ReciterListView()
        case .quranPage(let page): SettingsQuranView(openPage: page)
        case .hadithSettings: SettingsHadithView(presentedAsSheet: false)
        case .hadithPage(let page): SettingsHadithView(presentedAsSheet: false, openPage: page)
        case .islamSettings: SettingsIslamView()
        case .islamPage(let page): SettingsIslamView(openPage: page)
        case .appearance: AppearanceSettingsScreen()
        case .appearancePage(let page): AppearancePageView(page: page)
        case .aboutYou: AboutYouSettingsView()
        case .cloudBackup: CloudBackupSettingsView()
        case .tips(let area):
            if let area { TipsView(area: area) } else { TipsHubView() }
        case .credits: CreditsView(presentedAsSheet: false)
        case .credit(let id): CreditsView(presentedAsSheet: false, scrollTo: id)
        }
    }
}

/// One search result row: the destination's chip, the title with the match lit, and the breadcrumb.
struct SettingsSearchResultRow: View {
    @ObservedObject private var settings = Settings.shared

    let entry: SettingsSearchEntry
    let query: String
    /// The breadcrumb's leading segment to drop ("Quran Settings" on the Quran page), or nil for the
    /// root's full "Settings › ..." trail.
    var dropPrefix: String? = nil

    private var breadcrumb: String {
        let path = entry.path.replacingOccurrences(of: " → ", with: " › ")
        guard let dropPrefix else { return "Settings › \(path)" }
        if path == dropPrefix { return "This page" }
        if path.hasPrefix(dropPrefix + " › ") { return String(path.dropFirst(dropPrefix.count + 3)) }
        return path
    }

    var body: some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: entry.destination.icon)

            VStack(alignment: .leading, spacing: 2) {
                HighlightedSnippet(
                    source: entry.title,
                    term: query,
                    font: .subheadline,
                    accent: settings.accentColor.color,
                    fg: .primary
                )

                Text(breadcrumb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - A settings page with its own search bar

/// The scaffold every settings page root stands on: its sections as the list, the app's floating
/// search bar at the foot, and, while a query is typed, that page's slice of the settings index in
/// place of the sections. `resolve` hands a result to the page's OWN sub-screens (so "Arabic Text"
/// pushes the page's Arabic Text directly); a destination it returns nil for takes the app-wide
/// mapping.
struct SettingsScopedSearch<Content: View>: View {
    let scope: SettingsSearchScope
    let resolve: (SettingsSearchEntry.Destination) -> AnyView?
    @ViewBuilder let content: () -> Content

    @ObservedObject private var settings = Settings.shared
    @State private var query = ""
    /// Apple Music-style: true while scrolling down, minimizing the floating search bar.
    @State private var barsCollapsed = false

    init(scope: SettingsSearchScope,
         resolve: @escaping (SettingsSearchEntry.Destination) -> AnyView? = { _ in nil },
         @ViewBuilder content: @escaping () -> Content) {
        self.scope = scope
        self.resolve = resolve
        self.content = content
    }

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        List {
            Group {
                if trimmedQuery.isEmpty {
                    content()
                } else {
                    resultsSection
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .collapseBarsOnScroll($barsCollapsed)
        .dismissKeyboardOnScroll()
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                SearchBar(text: AppPerformance.shouldReduceAnimations ? $query : $query.animation(.easeInOut),
                          placeholder: scope.placeholder)
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
            .background(Color.white.opacity(0.00001))
        }
        #if DEBUG
        // "-settingsPageSearch <query>" seeds this page's bar a moment after it appears (typing is not
        // scriptable in the simulator), the per-page twin of the root's "-settingsSearch".
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            if let idx = arguments.firstIndex(of: "-settingsPageSearch"), arguments.indices.contains(idx + 1), query.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { query = arguments[idx + 1] }
            }
        }
        #endif
    }

    @ViewBuilder
    private var resultsSection: some View {
        let candidates = SettingsSearchEntry.entries(in: scope).filter { $0.title != scope.rootTitle }
        let results = SettingsSearchEntry.rank(candidates, query: trimmedQuery)
        Section(header: SectionPillHeader(title: "RESULTS", count: results.count)) {
            if results.isEmpty {
                Text("Nothing on this page matches. The Settings tab's search covers every setting.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(results) { entry in
                if entry.destination.isPageRoot, entry.destination.scope == scope {
                    // A control on this very root: nothing to push, so the row just names it.
                    SettingsSearchResultRow(entry: entry, query: trimmedQuery, dropPrefix: scope.pathPrefix)
                } else {
                    NavigationLink(destination: LazyDestination {
                        if let own = resolve(entry.destination) {
                            own
                        } else {
                            AnyView(SettingsSearchDestinationView.view(for: entry.destination))
                        }
                    }) {
                        SettingsSearchResultRow(entry: entry, query: trimmedQuery, dropPrefix: scope.pathPrefix)
                    }
                    .tint(settings.accentColor.color)
                }
            }
        }
    }
}

// MARK: - Deep links into a page

/// Pushes the sub-screen a settings search result named, a beat after the page's root has mounted
/// (a push raised before the container exists never lands, 2026-09-05): iOS 16+ through
/// `navigationDestination(isPresented:)`, iOS 15 through a hidden `isActive` link. Inert when
/// nothing was requested, so a page presented in a plain `NavigationView` (the readers' settings
/// sheets) never carries a destination modifier that container would not honour.
struct SettingsDeepLink<Destination: View>: ViewModifier {
    @Binding var isPresented: Bool
    var active: Bool = true
    @ViewBuilder let destination: () -> Destination

    func body(content: Content) -> some View {
        if !active {
            content
        } else if #available(iOS 16.0, *) {
            content.navigationDestination(isPresented: $isPresented, destination: destination)
        } else {
            content.background(
                NavigationLink(isActive: $isPresented) { destination() } label: { EmptyView() }
                    .hidden()
            )
        }
    }
}
#endif
