import SwiftUI

struct IslamView: View {
    @ObservedObject var settings = Settings.shared
    // No NamesViewModel observation: this body renders nothing from it, and observing it re-ran the
    // whole tab root when the 99 Names JSON finished its background load. NamesView observes it itself.
    #if os(iOS)
    // Split-view multitasking (Slide Over, 1/3 Split View, narrow Stage Manager windows) makes an iPad
    // window compact - the sidebar/detail layout must collapse to the iPhone shape there (see
    // `usesColumnNavigation`), or the split collapses onto a pre-selected detail with no way back.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// iPad: the split view's sidebar selection. Seeded from `-islamDestination` too, so the DEBUG
    /// hook lands on the resource in the detail column as it does on the iPhone stack (2026-09-06).
    @State private var selectedResource: IslamDestination? = Self.launchDestination ?? .arabicAlphabet
    /// Bumped when the SAME sidebar row is re-tapped: the detail stack is keyed on it, so the tap
    /// always lands (pops that section back to its root) instead of dying against unchanged state.
    @State private var islamDetailRefreshToken = 0
    /// Programmatic pushes for the grid tiles (a `NavigationLink` inside a List row drags the row chevron
    /// into each tile; a path append does not).
    @State private var islamPath: [IslamDestination] = Self.launchDestination.map { [$0] } ?? []

    /// The tab's search: resources by name, and every Pillars & Beliefs / How-to article by title and
    /// by the prose inside it (IslamSearch.swift). Results replace the list while a query is typed.
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The resource row a result asked to scroll to ("Scroll To ..."), consumed once the search clears.
    @State private var scrollTarget: String?
    @StateObject private var articleSearch = IslamArticleSearchModel()

    #if DEBUG
    /// `-islamOpenArticle <catalog id>` (with `-articleSection <HEADING>` alongside): what tapping an
    /// article result on this screen does, headlessly - the article's index pushed as a destination and
    /// the article on top of it - so the two-hop landing can be screenshot.
    @State private var debugOpenArticle = false

    private static var debugArticleRequest: (home: IslamArticleHome, request: IslamArticleOpenRequest)? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let idx = arguments.firstIndex(of: "-islamOpenArticle"), arguments.indices.contains(idx + 1),
              let entry = IslamArticleCatalog.byID[arguments[idx + 1]] else { return nil }
        var section: String?
        if let sectionIdx = arguments.firstIndex(of: "-articleSection"), arguments.indices.contains(sectionIdx + 1) {
            section = arguments[sectionIdx + 1]
        }
        return (entry.home, IslamArticleOpenRequest(id: entry.id, section: section))
    }
    #endif

    /// DEBUG launch argument `-islamDestination <rawValue>` (e.g. `namesOfAllah`): the resource is
    /// pushed as the tab appears, the only headless route into a resource page (see Settings.init).
    private static var launchDestination: IslamDestination? {
        #if DEBUG
        if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-islamDestination"),
           ProcessInfo.processInfo.arguments.indices.contains(idx + 1) {
            return IslamDestination(rawValue: ProcessInfo.processInfo.arguments[idx + 1])
        }
        #endif
        return nil
    }

    /// Two side-by-side columns only when the window is actually wide enough - the Hadith tab's rule.
    private var usesColumnNavigation: Bool {
        guard #available(iOS 16.0, *) else { return false }
        guard horizontalSizeClass == .regular else { return false }
        return UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac
    }

    /// What re-identifies the iPad detail stack: the selected resource, or a re-tap of the same row.
    private struct IslamDetailIdentity: Hashable {
        let resource: IslamDestination
        let token: Int
    }

    private var islamDetailIdentity: IslamDetailIdentity {
        IslamDetailIdentity(resource: selectedResource ?? .arabicAlphabet, token: islamDetailRefreshToken)
    }

    /// String-backed so favorites persist by raw value, CaseIterable so the resource list, the grid, and the
    /// favorites section all draw from one source of truth instead of three hand-maintained row lists.
    private enum IslamDestination: String, Hashable, CaseIterable {
        /// The on-device chat. Listed only where Apple Intelligence can run it (`available`).
        case arabicAlphabet
        // The Tajweed Course was merged INTO Foundations (Abu, 2026-09-19): one subject, one door. Since
        // 2026-09-23 the two are one course, merged lesson by lesson, and Foundations IS its index, so
        // there is no `tajweedCourse` case.
        case tajweedFoundations
        case namesOfAllah
        case commonAdhkar
        case commonDuas
        case tasbihCounter
        case zakahCalculator
        case inheritanceCalculator
        case hijriCalendarConverter
        case masjidLocator
        case halalFoodLocator
        // The journal sits with the two locators (Abu, 2026-09-23): those three are the tab's
        // "things you do", as against the reference screens under them.
        case journal
        case pillarsAndBasics
        case howToGuides
        case islamicWallpapers
        // The three miracle / prophecy screens are one subject, so they are one grid row.
        case miraclesOfQuran
        case propheciesOfProphet
        case miraclesOfProphets
        case askAI

        /// Screens the door leaves alone. The alphabet, the 99 Names, the inheritance calculator and
        /// the journal have a trailing button of their own and place the gear themselves, after it
        /// (`islamSettingsToolbar(own:)`): a gear added from outside lands on the wrong side of that
        /// button. Ask AI gets none: it is an assistant with its own toolbar, and nothing in Islam
        /// Settings changes how it reads.
        var placesOwnSettingsGear: Bool {
            switch self {
            case .arabicAlphabet, .namesOfAllah, .inheritanceCalculator, .journal, .askAI: return true
            default: return false
            }
        }

        var title: String {
            switch self {
            case .askAI: return "Ask AI"
            case .arabicAlphabet: return "Arabic Alphabet"
            case .tajweedFoundations: return "Tajweed Foundations"
            case .commonAdhkar: return "Dhikr & Remembrances"
            case .commonDuas: return "Dua & Supplications"
            case .tasbihCounter: return "Tasbih Counter"
            case .zakahCalculator: return "Zakah Calculator"
            case .inheritanceCalculator: return "Inheritance Calculator"
            case .namesOfAllah: return "99 Names of Allah"
            case .hijriCalendarConverter: return "Hijri Date Converter"
            case .masjidLocator: return "Masjid Locator"
            case .halalFoodLocator: return "Halal Food Locator"
            case .islamicWallpapers: return "Islamic Wallpapers"
            case .pillarsAndBasics: return "Pillars & Beliefs"
            case .howToGuides: return "How-To Guides"
            case .miraclesOfQuran: return "Miracles of the Quran"
            case .propheciesOfProphet: return "Prophecies of the Prophet"
            case .miraclesOfProphets: return "Miracles of the Prophets"
            case .journal: return "Islamic Journal"
            }
        }

        var systemImage: String {
            switch self {
            case .askAI: return "sparkles"
            case .arabicAlphabet: return "textformat.size.ar"
            case .tajweedFoundations: return "waveform"
            case .commonAdhkar: return "book.closed"
            case .commonDuas: return "text.book.closed"
            case .tasbihCounter: return "circles.hexagonpath.fill"
            case .zakahCalculator: return "percent"
            case .inheritanceCalculator: return "divide.circle"
            case .namesOfAllah: return "signature"
            case .hijriCalendarConverter: return "calendar"
            case .masjidLocator: return "mappin.and.ellipse"
            case .halalFoodLocator: return "fork.knife"
            case .islamicWallpapers: return "photo.on.rectangle"
            case .pillarsAndBasics: return "moon.stars"
            case .howToGuides: return "list.bullet.rectangle"
            case .miraclesOfQuran: return "sparkle.magnifyingglass"
            case .propheciesOfProphet: return "checkmark.seal"
            case .miraclesOfProphets: return "staroflife"
            case .journal: return "square.and.pencil"
            }
        }

        /// One line of what lives behind the row - the Settings hub's caption column, here.
        var subtitle: String {
            switch self {
            case .askAI: return "Ask anything about Islam, on device"
            case .arabicAlphabet: return "Letters, forms, diacritics, and signs"
            case .tajweedFoundations: return "A full course, from the letters to the mushaf"
            case .commonAdhkar: return "Morning, evening, and daily remembrances"
            case .commonDuas: return "Authenticated supplications with sources"
            case .tasbihCounter: return "Count dhikr with a tap"
            case .zakahCalculator: return "Work out what you owe"
            case .inheritanceCalculator: return "Divide an estate by the Quranic shares"
            case .namesOfAllah: return "Asma ul-Husna with meanings"
            case .hijriCalendarConverter: return "Convert Hijri and Gregorian dates"
            case .masjidLocator: return "Find mosques near you"
            case .halalFoodLocator: return "Find halal food near you"
            case .islamicWallpapers: return "Beautiful wallpapers to save"
            case .pillarsAndBasics: return "The Five Pillars and Six Beliefs"
            case .howToGuides: return "Wudu, salah, Jumuah, and more"
            case .miraclesOfQuran: return "Signs in creation, science, and history"
            case .propheciesOfProphet: return "What he foretold, and what history did"
            case .miraclesOfProphets: return "The signs given to the prophets, and to him"
            case .journal: return "Notes from khutbahs, classes, and your reading"
            }
        }

        /// The tile title with its line break CHOSEN, not wherever truncation lands: every grid tile is
        /// exactly two lines, broken at the natural point, so a whole grid of tiles shares one height and
        /// one rhythm.
        var gridTitle: String {
            switch self {
            case .askAI: return "Ask\nAI"
            case .arabicAlphabet: return "Arabic\nAlphabet"
            case .tajweedFoundations: return "Tajweed\nFoundations"
            case .commonAdhkar: return "Dhikr &\nRemembrances"
            case .commonDuas: return "Dua &\nSupplications"
            case .tasbihCounter: return "Tasbih\nCounter"
            case .zakahCalculator: return "Zakah\nCalculator"
            case .inheritanceCalculator: return "Inheritance\nCalculator"
            case .namesOfAllah: return "99 Names\nof Allah"
            case .hijriCalendarConverter: return "Hijri Date\nConverter"
            case .masjidLocator: return "Masjid\nLocator"
            case .halalFoodLocator: return "Halal Food\nLocator"
            case .islamicWallpapers: return "Islamic\nWallpapers"
            case .pillarsAndBasics: return "Pillars &\nBeliefs"
            case .howToGuides: return "How-To\nGuides"
            case .miraclesOfQuran: return "Miracles of\nthe Quran"
            case .propheciesOfProphet: return "Prophecies of\nthe Prophet"
            case .miraclesOfProphets: return "Miracles of\nthe Prophets"
            case .journal: return "Islamic\nJournal"
            }
        }

        /// Words a searcher types that the title and subtitle do not carry.
        var searchKeywords: [String] {
            switch self {
            case .askAI: return ["chat", "question", "assistant", "apple intelligence"]
            case .arabicAlphabet: return ["letters", "harakat", "huruf", "alphabet", "tashkeel", "numbers",
                                          "sifaat", "sifat", "makharij", "whistling", "safeer", "hams", "families",
                                          "sound-alike", "quiz", "sun letters", "moon letters",
                                          "reading test", "qaida", "qaidah", "noorani", "spelling", "pronunciation"]
            case .tajweedFoundations: return ["recitation", "rules", "makharij", "ghunnah", "qalqalah", "madd",
                                              // The merged course's own words, so "tajweed course" still lands here.
                                              "lessons", "course", "learn", "practice", "beginner", "step by step", "tajwid"]
            case .commonAdhkar: return ["dhikr", "adhkar", "azkar", "remembrance", "tasbih", "subhanallah"]
            case .commonDuas: return ["dua", "duas", "supplication", "prayer", "invocation"]
            case .tasbihCounter: return ["counter", "beads", "misbaha", "count"]
            case .zakahCalculator: return ["zakat", "charity", "nisab", "gold", "silver", "2.5", "fitr", "zakat al-fitr", "sadaqah", "hawl", "sa'"]
            case .inheritanceCalculator: return ["faraid", "mirath", "estate", "heirs", "shares", "will", "wasiyyah", "bequest", "awl", "radd", "asabah"]
            case .namesOfAllah: return ["asma", "husna", "asmaul husna", "attributes", "ar-rahman"]
            case .hijriCalendarConverter: return ["calendar", "date", "islamic date", "gregorian", "converter"]
            case .masjidLocator: return ["mosque", "masjid", "near me", "map", "prayer place"]
            case .halalFoodLocator: return ["restaurant", "halal", "food", "eat", "map"]
            case .islamicWallpapers: return ["wallpaper", "background", "lock screen", "calligraphy"]
            case .pillarsAndBasics: return ["beliefs", "aqeedah", "articles", "basics", "iman", "faith"]
            case .howToGuides: return ["how to", "guide", "steps", "wudu", "salah", "ghusl"]
            case .miraclesOfQuran: return ["miracles", "miracle", "science", "scientific", "signs", "creation", "embryology", "astronomy", "cosmology", "universe", "ijaz"]
            case .propheciesOfProphet: return ["prophecy", "prophecies", "foretold", "predicted", "prediction", "future", "signs of the hour", "end times", "fulfilled"]
            case .miraclesOfProphets: return ["miracles", "prophets", "moses", "musa", "jesus", "isa", "abraham", "ibrahim", "salih", "moon", "splitting", "staff", "sea", "proof", "prophethood",
                                              "david", "dawud", "solomon", "sulayman", "jonah", "yunus", "whale", "iron", "jinn", "ants", "birds",
                                              "night journey", "isra", "miraj", "ascension", "aqsa", "cradle", "she-camel", "fire"]
            case .journal: return ["journal", "notes", "note", "diary", "khutbah", "lecture", "class", "study", "reflection", "write"]
            }
        }

        /// The row title, subtitle and keywords, folded ONCE per launch for matching (this was
        /// re-folded for every resource on every keystroke; Performance Guide, Phase 6 step 10).
        var searchBlob: String { Self.searchBlobs[self] ?? "" }

        private static let searchBlobs: [IslamDestination: String] = Dictionary(uniqueKeysWithValues: allCases.map {
            ($0, IslamArticles.fold(([$0.title, $0.subtitle] + $0.searchKeywords).joined(separator: " ")))
        })

        /// Every resource this device can show: all of them, minus Ask AI where Apple Intelligence
        /// can't run it (a row that opens onto "not available here" is worse than no row).
        static var available: [IslamDestination] {
            allCases.filter {
                if $0 == .askAI { return OnDeviceAsk.isAvailable }
                return true
            }
        }
    }

    /// Collapse state for the favorites section, same as the Quran tab's Favorite Surahs.
    @AppStorage("showIslamFavorites") private var showIslamFavorites = true

    private var favoriteResources: [IslamDestination] {
        IslamDestination.available.filter { settings.isIslamResourceFavorite($0.rawValue) }
    }

    private func favoriteToggleButton(_ item: IslamDestination) -> some View {
        let isFavorite = settings.isIslamResourceFavorite(item.rawValue)
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleIslamResourceFavorite(item.rawValue)
            }
        } label: {
            Label(isFavorite ? "Unfavorite" : "Favorite", systemImage: isFavorite ? "star.fill" : "star")
        }
    }
    #endif

    /// Cross-platform mirror of `usesColumnNavigation`, so the shared `body` can observe layout flips
    /// (the watch build reads a constant false).
    private var columnLayoutActive: Bool {
        #if os(iOS)
        return usesColumnNavigation
        #else
        return false
        #endif
    }

    var body: some View {
        navigationContainer
            #if os(iOS)
            // A Reminder of the Day card's "Open": the resource pushed onto this tab's stack (or
            // selected in the iPad sidebar), then the request cleared so it never replays.
            .onReceive(AppNavigation.shared.$pendingIslam) { target in
                guard let target else { return }
                let destination: IslamDestination?
                switch target {
                case .duas: destination = .commonDuas
                case .adhkar: destination = .commonAdhkar
                case .names(let number):
                    NamesViewModel.shared.pendingNameNumber = number
                    destination = .namesOfAllah
                case .hadithTab, .tab: destination = nil
                }
                guard let destination else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if columnLayoutActive {
                        selectedResource = destination
                        islamDetailRefreshToken += 1
                    } else if #available(iOS 16.0, *) {
                        islamPath = [destination]
                    }
                    AppNavigation.shared.pendingIslam = nil
                }
            }
            #endif
            // The window crossed the compact/regular boundary (iPad Split View drag, Slide Over, Stage
            // Manager): carry the open resource across the sidebar/stack swap so the user stays where
            // they were instead of being dumped back on the list. Only for a crossing the USER made -
            // backgrounding the app makes iOS flip the window compact and back for its app-switcher
            // snapshots, and this migration cannot survive that round trip (see `ColumnLayoutMigration`).
            //
            // `islamPath.isEmpty` on the way out: the path is the thing being rebuilt, so it must not
            // overwrite a stack that already has something in it.
            #if os(iOS)
            .columnLayoutMigration(columns: columnLayoutActive) { columns in
                guard #available(iOS 16.0, *) else { return }
                if columns {
                    if let top = islamPath.last {
                        selectedResource = top
                        islamPath.removeAll()
                    }
                } else if let selected = selectedResource, islamPath.isEmpty {
                    islamPath = [selected]
                }
            }
            #endif
    }

    private var navigationContainer: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *), usesColumnNavigation {
                NavigationSplitView {
                    islamSidebar
                } detail: {
                    // The detail needs its own NavigationStack so NavigationLinks inside a destination
                    // (e.g. tapping a letter in ArabicView) push within the detail column instead of
                    // hijacking the whole split. `.id` rebuilds the stack when the sidebar selection
                    // changes - or when the same row is re-tapped (the token) - so switching sections
                    // always resets to that section's root.
                    NavigationStack {
                        islamDetail
                    }
                    .id(islamDetailIdentity)
                }
            } else if #available(iOS 16.0, *) {
                NavigationStack(path: $islamPath) {
                    islamList
                        .navigationDestination(for: IslamDestination.self) { destination in
                            destinationView(for: destination)
                        }
                }
            } else {
                NavigationView {
                    islamList
                }
                .navigationViewStyle(.stack)
            }
            #else
            NavigationView {
                islamList
            }
            #endif
        }
    }

    /// The list body both shapes share: only the resource rows swap their link grammar (stack links
    /// on iPhone, selection rows in the iPad sidebar) - the quote and the apps card are literally the
    /// same views everywhere, so an edit to them can never fork between iPhone and iPad.
    @ViewBuilder
    private func islamListEntries(split: Bool) -> some View {
        Group {
            Group {
                #if os(iOS)
                if split, #available(iOS 16.0, *) {
                    resourcesSectionSplit
                } else if #available(iOS 16.0, *) {
                    modernResourceSections
                } else {
                    resourcesSection
                }
                #else
                resourcesSection
                #endif
            }

            // The Reminder of the Day lives in the Islam tab (Abu, 2026-09-12: "keep it in Islam,
            // don't have it be a sheet"), directly UNDER the resources rather than above them
            // (2026-09-18) - the tab opens on what it is for, and the card is the first thing past
            // it. It renders only once the corpus has parsed, so the resource grid never waits on it.
            #if os(iOS)
            ReminderOfTheDaySection()
                .id("reminder")
            #endif

            ProphetQuote()
            AlIslamAppsSection()
                .id("apps")
        }
        .themedListRowBackground()
    }

    private var islamList: some View {
        #if os(iOS)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return ScrollViewReader { proxy in
            List {
                if query.isEmpty {
                    islamListEntries(split: false)
                } else {
                    searchResultSections(query: query)
                }
            }
            .applyConditionalListStyle()
            .navigationTitle("Al-Islam")
            #if DEBUG
            .debugPushDestination(isPresented: $debugOpenArticle) {
                if let debug = Self.debugArticleRequest {
                    IslamArticleCatalog.homeDestination(debug.home, opening: debug.request)
                }
            }
            #endif
            // The grid toggle, then the Islam Settings gear at the far right: one toolbar, so the
            // order is declared (see `IslamSettingsToolbar`).
            .islamSettingsToolbar {
                if #available(iOS 16.0, *), query.isEmpty {
                    Button {
                        settings.hapticFeedback()
                        withAnimation { settings.islamGridMode.toggle() }
                    } label: {
                        Image(systemName: settings.islamGridMode ? "list.bullet" : "square.grid.2x2")
                    }
                    .accessibilityLabel(settings.islamGridMode ? "Show list" : "Show grid")
                    .tint(settings.accentColor.accent1)
                }
            }
            // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
            .collapseBarsOnScroll($barsCollapsed)
            .adaptiveSafeArea(edge: .bottom) {
                SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
                    .minimizedBarStyle(barsCollapsed)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .background(Color.white.opacity(0.00001))
            }
            .onChange(of: scrollTarget) { target in
                guard let target else { return }
                // The search rows are still animating out; scroll once the resource rows are back.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { proxy.scrollTo(target, anchor: .top) }
                }
            }
        }
        .onAppear {
            // A real visit inflates the corpus ahead of the first keystroke; the under-cover tab walk
            // also lands here, and that inflate belongs to the root's post-reveal schedule instead.
            if AppReveal.revealed { IslamArticleSearchModel.prewarm() }
            #if DEBUG
            // `-islamScrollToApps`: bring the app tiles at the foot of the list into a screenshot.
            if ProcessInfo.processInfo.arguments.contains("-islamScrollToApps") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { scrollTarget = "apps" }
            }
            // `-islamScrollToReminder`: bring the Reminder of the Day card under the resources
            // into a screenshot (there is no scroll tooling for the simulator).
            if ProcessInfo.processInfo.arguments.contains("-islamScrollToReminder") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { scrollTarget = "reminder" }
            }
            if let seeded = IslamSearchDebug.launchQuery("-islamSearch"), searchText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { searchText = seeded }
            }
            if Self.debugArticleRequest != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { debugOpenArticle = true }
            }
            #endif
        }
        .onChange(of: searchText) { text in
            articleSearch.update(query: text, homes: [.pillars, .guides])
            if !text.isEmpty { scrollTarget = nil }
        }
        #else
        return List {
            islamListEntries(split: false)
        }
        .applyConditionalListStyle()
        .navigationTitle("Al-Islam")
        #endif
    }

    #if os(iOS)
    /// The resources whose title, subtitle or keywords carry every word of the query.
    private func matchingResources(_ query: String) -> [IslamDestination] {
        let terms = IslamArticleSearch.words(query)
        guard !terms.isEmpty else { return [] }
        return IslamDestination.available.filter { item in
            let blob = item.searchBlob
            return terms.allSatisfy { blob.contains($0) }
        }
    }

    /// The search's list: the Ask AI row, matching RESOURCES, then the article matches from both
    /// Pillars & Beliefs and the How-to guides, each labelled with where it lives.
    @ViewBuilder
    private func searchResultSections(query: String) -> some View {
        let resources = matchingResources(query)
        Group {
            AskAISearchSection(query: query)

            if !resources.isEmpty {
                Section(header: SectionPillHeader(title: "RESOURCES", count: resources.count)) {
                    ForEach(resources, id: \.self) { item in
                        resourceSearchRow(item, query: query)
                    }
                }
            }

            IslamArticleSearchSections(
                query: query,
                homes: [.pillars, .guides],
                contentHits: articleSearch.contentHits,
                isSearching: articleSearch.isSearching,
                showHome: true,
                openViaHome: true,
                hasOtherResults: !resources.isEmpty,
                scrollLabel: { "Scroll To \($0.home.title)" },
                onScrollTo: { entry in
                    // The article's own row is inside its resource; the nearest thing on THIS screen is
                    // the resource row, so that is where the list scrolls.
                    scrollToResource(entry.home == .pillars ? .pillarsAndBasics : .howToGuides)
                }
            )
        }
        .themedListRowBackground()
    }

    private func scrollToResource(_ item: IslamDestination) {
        withAnimation { searchText = "" }
        scrollTarget = Self.rowID(item)
    }

    private static func rowID(_ item: IslamDestination) -> String { "resource_\(item.rawValue)" }

    /// A resource as a search result: the list row with the match coloured, whatever the grid toggle
    /// says (a grid tile cannot carry a context menu). Its menu and trailing swipe scroll the list back
    /// to the resource's own row, the Quran list's grammar.
    @ViewBuilder
    private func resourceSearchRow(_ item: IslamDestination, query: String) -> some View {
        let label = HStack(spacing: 12) {
            AccentIconChip(systemImage: item.systemImage)

            VStack(alignment: .leading, spacing: 1) {
                HighlightedSnippet(source: item.title, term: query, font: .body,
                                   accent: settings.accentColor.color, fg: .primary)

                HighlightedSnippet(source: item.subtitle, term: query, font: .caption,
                                   accent: settings.accentColor.color, fg: .secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)

        let link = Group {
            if #available(iOS 16.0, *), !usesColumnNavigation {
                NavigationLink(value: item) { label }
            } else {
                NavigationLink(destination: LazyDestination { destinationView(for: item) }) { label }
            }
        }

        link
            .contextMenu {
                Text(item.title)
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    scrollToResource(item)
                } label: {
                    Label("Scroll To Resource", systemImage: "arrow.down.circle")
                }

                Divider()

                favoriteToggleButton(item)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                resourceSwipeFavoriteButton(item)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    settings.hapticFeedback()
                    scrollToResource(item)
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .tint(.secondary)
            }
    }
    #endif

    #if os(iOS)
    /// The favorites section plus the full resource list, honoring the app-wide grid toggle. Value-based
    /// navigation (iOS 16+): the enum IS the row, so favorites, grid tiles, and list rows all push through
    /// the same `navigationDestination`.
    @available(iOS 16.0, *)
    @ViewBuilder
    private var modernResourceSections: some View {
        startHereSection(split: false)

        let favorites = favoriteResources
        if !favorites.isEmpty {
            Section(header: SectionPillHeader(
                title: "FAVORITES",
                count: favorites.count,
                icon: "star.fill",
                accentTitle: true,
                isExpanded: $showIslamFavorites
            )) {
                if showIslamFavorites {
                    resourceItems(favorites)
                }
            }
        }

        Section(header: SectionPillHeader(title: "ISLAMIC RESOURCES", count: IslamDestination.available.count)) {
            resourceItems(IslamDestination.available)
        }
    }

    @available(iOS 16.0, *)
    @ViewBuilder
    private func resourceItems(_ items: [IslamDestination]) -> some View {
        if settings.islamGridMode {
            // Ask AI is the odd one out: it is a conversation, not a reference page, and at one third
            // of a row its label had to shrink to "Ask AI" with no room to say what it does. It spans
            // the full width, with the caption the tiles cannot carry, and sits BELOW the grid
            // (Abu, 2026-09-19: the references are what the tab is for; the assistant is the thing
            // you reach for when they have not answered you). Pulled OUT of `items` so it never
            // draws twice.
            let askAI = items.first { $0 == .askAI }
            let tiles = items.filter { $0 != .askAI }

            // Press-and-hold offers the row's menu through `GridTileMenu` - a plain `contextMenu`
            // here would lift the WHOLE row (every tile at once) as its preview, since the grid is
            // one LazyVGrid inside a single List row.
            //
            // The grid and the banner share ONE row, 8 pt apart like the tiles themselves. As two
            // rows each carried its own ~16 pt inset, so the banner sat 33 pt under the tiles, and a
            // section holding only Ask AI (Favorites, with it as the one favorite) still drew the
            // grid's row with nothing in it: an empty block above the banner (Abu, 2026-09-20,
            // "weird top padding for ask ai").
            VStack(spacing: 8) {
                if !tiles.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(tiles, id: \.self) { item in
                            resourceGridStar(item, on: GridTileMenu {
                                settings.hapticFeedback()
                                islamPath.append(item)
                            } menu: {
                                favoriteToggleButton(item)
                            } label: {
                                resourceGridTile(item)
                            })
                            .id(Self.rowID(item))
                        }
                    }
                }

                if let askAI {
                    resourceGridStar(askAI, on: GridTileMenu {
                        settings.hapticFeedback()
                        islamPath.append(askAI)
                    } menu: {
                        favoriteToggleButton(askAI)
                    } label: {
                        askAIBanner(askAI)
                    })
                    .id(Self.rowID(askAI))
                }
            }
            // 1, not 4: the section row already carries ~16pt of its own vertical inset, so 4
            // put the tiles 20pt from the container's top and bottom edges against 17pt at the
            // sides. Measured on the iPhone 17 Pro; 1 lands all four insets on 17pt.
            .padding(.vertical, 1)
            // One cell, so it draws no separator of its own; hidden anyway so a rule can never
            // appear under the section's last row.
            .listRowSeparator(.hidden)
        } else {
            ForEach(items, id: \.self) { item in
                NavigationLink(value: item) {
                    toolLabel(item.title, systemImage: item.systemImage, subtitle: item.subtitle)
                }
                .id(Self.rowID(item))
                .contextMenu { favoriteToggleButton(item) }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    resourceSwipeFavoriteButton(item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    resourceSwipeFavoriteButton(item)
                }
            }
        }
    }

    private func resourceSwipeFavoriteButton(_ item: IslamDestination) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleIslamResourceFavorite(item.rawValue)
            }
        } label: {
            Image(systemName: settings.isIslamResourceFavorite(item.rawValue) ? "star.fill" : "star")
        }
        .tint(settings.accentColor.color)
    }

    /// Ask AI's full-width banner in grid mode: the chip, the title, and the caption the one-third
    /// tile had no room for. Deliberately the same glass and favorite tinting as a tile, so it reads
    /// as the same family of control at a different size.
    @available(iOS 16.0, *)
    private func askAIBanner(_ item: IslamDestination) -> some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: item.systemImage, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .conditionalGlassEffect(
            clear: !settings.isIslamResourceFavorite(item.rawValue),
            rectangle: true,
            useColor: settings.isIslamResourceFavorite(item.rawValue) ? 0.25 : nil,
            customTint: settings.isIslamResourceFavorite(item.rawValue) ? settings.accentColor.color : nil
        )
    }

    @available(iOS 16.0, *)
    private func resourceGridTile(_ item: IslamDestination) -> some View {
        VStack(spacing: 6) {
            AccentIconChip(systemImage: item.systemImage, size: 32)

            Text(item.gridTitle)
                .font(.caption2.weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        // Favorites are accent-tinted, everything else is clear - the same pattern as the surah, 99 Names,
        // and Arabic letter grids, so a favorite reads the same way everywhere.
        .conditionalGlassEffect(
            clear: !settings.isIslamResourceFavorite(item.rawValue),
            rectangle: true,
            useColor: settings.isIslamResourceFavorite(item.rawValue) ? 0.25 : nil,
            customTint: settings.isIslamResourceFavorite(item.rawValue) ? settings.accentColor.color : nil
        )
    }

    /// The tile's corner star, applied OUTSIDE `GridTileMenu` (its 30 pt tap target would otherwise
    /// fight the long press that opens the menu).
    @available(iOS 16.0, *)
    private func resourceGridStar<V: View>(_ item: IslamDestination, on view: V) -> some View {
        view.gridFavoriteStar(
            isFavorite: settings.isIslamResourceFavorite(item.rawValue),
            accent: settings.accentColor.color,
            accessibilityName: item.title
        ) {
            settings.toggleIslamResourceFavorite(item.rawValue)
        }
    }
    #endif

    #if os(iOS)
    /// Start Here: the guided path About You switches on for anyone who is not simply at home in all
    /// of this already (a revert, someone just getting started, someone learning about Islam). It
    /// leads the tab, above Favorites, because for that reader it IS what the tab is for; each step
    /// ticks itself off when its resource is opened (`destinationView(for:)`), and Hide puts the
    /// whole thing away (About You, in Settings, brings it back).
    ///
    /// Always rows, in grid mode too: a path is read top to bottom, and tiles have no order.
    @available(iOS 16.0, *)
    @ViewBuilder
    private func startHereSection(split: Bool) -> some View {
        if StartHere.isShown(settings), let background = settings.userBackground {
            let steps = StartHere.steps(for: background)
            let visited = StartHere.visited(settings)
            Section(header: startHereHeader(done: steps.filter { visited.contains($0.id) }.count, of: steps.count)) {
                ForEach(steps) { step in
                    startHereRow(step, done: visited.contains(step.id), split: split)
                }
            }
        }
    }

    private func startHereHeader(done: Int, of total: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.fill")
                .foregroundColor(settings.accentColor.color)

            // One line each, shrinking before they wrap: the iPad sidebar is narrow enough that
            // "START HERE" broke in two and pushed the count under it.
            Text("START HERE")
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)

            Text("\(done) of \(total)")
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 4)

            Button("Hide") {
                settings.hapticFeedback()
                withAnimation(.easeInOut) { settings.startHereHidden = true }
            }
            .font(.caption.weight(.semibold))
            .textCase(nil)
            .tint(settings.accentColor.color)
            .accessibilityLabel("Hide Start Here")
        }
    }

    @available(iOS 16.0, *)
    @ViewBuilder
    private func startHereRow(_ step: StartHereStep, done: Bool, split: Bool) -> some View {
        let label = startHereLabel(step, done: done)
        if let resource = step.resource.flatMap(IslamDestination.init(rawValue:)) {
            if split {
                Button { selectSplitResource(resource) } label: { label }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
            } else {
                NavigationLink(value: resource) { label }
            }
        } else {
            // The one step that leaves the tab: the Quran. `AppNavigation` switches tabs.
            Button {
                settings.hapticFeedback()
                StartHere.markVisited(resource: nil)
                AppNavigation.shared.open(.tab)
            } label: {
                HStack {
                    label
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func startHereLabel(_ step: StartHereStep, done: Bool) -> some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: done ? "checkmark" : step.systemImage)
                .opacity(done ? 0.55 : 1)

            VStack(alignment: .leading, spacing: 1) {
                Text(step.title)
                    .foregroundColor(.primary)

                Text(step.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
        .accessibilityLabel("\(step.title). \(step.subtitle)\(done ? ". Opened" : "")")
    }
    #endif

    #if os(iOS)
    @available(iOS 16.0, *)
    private var islamSidebar: some View {
        List(selection: $selectedResource) {
            islamListEntries(split: true)
        }
        // The detail column's screens show the Now Playing bar; suppress the sidebar's copy or
        // recitation puts one identical bar in EACH column (the Quran tab's rule).
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .navigationTitle("Al-Islam")
        // The same control, on the same setting, as the iPhone list's - the iPad simply never had it,
        // so the toggle was unreachable on the one layout where it is shown as a sidebar. The gear
        // follows it, as on the iPhone.
        .islamSettingsToolbar {
            Button {
                settings.hapticFeedback()
                withAnimation { settings.islamGridMode.toggle() }
            } label: {
                Image(systemName: settings.islamGridMode ? "list.bullet" : "square.grid.2x2")
            }
            .accessibilityLabel(settings.islamGridMode ? "Show list" : "Show grid")
            .tint(settings.accentColor.accent1)
        }
    }

    @available(iOS 16.0, *)
    private var islamDetail: some View {
        // Re-identify the detail by the current selection so the split-view detail always rebuilds when the
        // sidebar selection changes. Without this the detail could get "stuck" on a previous item after the
        // view disappeared and came back on iPad/Mac.
        destinationView(for: selectedResource ?? .arabicAlphabet)
            .id(islamDetailIdentity)
    }

    /// Every resource carries the Islam Settings gear at its top right (Abu, 2026-09-20). Applied HERE,
    /// the one door all of them are opened through (the stack, the search rows, the iPad detail), so a
    /// new resource gets it without being told to.
    @ViewBuilder
    private func destinationView(for destination: IslamDestination) -> some View {
        Group {
            if destination.placesOwnSettingsGear {
                resourceRoot(for: destination)
            } else {
                resourceRoot(for: destination).islamSettingsToolbar()
            }
        }
        // Start Here ticks a step off when its resource is opened, by whichever route.
        .onAppear { StartHere.markVisited(resource: destination.rawValue) }
    }

    @ViewBuilder
    private func resourceRoot(for destination: IslamDestination) -> some View {
        switch destination {
        case .askAI:
            if #available(iOS 16.0, *) {
                AskAIChatView()
            }
        case .arabicAlphabet:
            ArabicView()
        case .tajweedFoundations:
            // `-showQiraatAnalysis` opens the buried textual-comparison page directly: it normally
            // takes seven taps at the bottom of the Qiraat guide, and taps aren't scriptable in the
            // simulator, so headless verification needs a way in.
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-showQiraatAnalysis") {
                QiraatTextAnalysisView()
            } else {
                TajweedFoundationsView()
            }
            #else
            TajweedFoundationsView()
            #endif
        case .commonAdhkar:
            AdhkarView()
        case .commonDuas:
            DuaView()
        case .tasbihCounter:
            TasbihView()
        case .zakahCalculator:
            ZakahCalculatorView()
        case .inheritanceCalculator:
            InheritanceCalculatorView()
        case .namesOfAllah:
            NamesView()
        case .hijriCalendarConverter:
            DateView()
        case .masjidLocator:
            PlaceLocatorView(profile: .masjid)
        case .halalFoodLocator:
            PlaceLocatorView(profile: .halalFood)
        case .islamicWallpapers:
            WallpaperView()
        case .pillarsAndBasics:
            PillarsView()
        case .howToGuides:
            GuidesView()
        case .miraclesOfQuran:
            MiraclesView()
        case .propheciesOfProphet:
            PropheciesView()
        case .miraclesOfProphets:
            ProphetMiraclesView()
        case .journal:
            JournalView()
        }
    }
    #endif

    private var resourcesSection: some View {
        Section(header: Text("ISLAMIC RESOURCES")) {
            resourceLink(title: "Arabic Alphabet", systemImage: "textformat.size.ar", placesOwnSettingsGear: true) {
                ArabicView()
            }

            // The tajweed course IS Tajweed Foundations (merged 2026-09-23), so it has one row.
            resourceLink(title: "Tajweed Foundations", systemImage: "waveform") {
                TajweedFoundationsView()
            }

            resourceLink(title: "Dhikr & Remembrances", systemImage: "book.closed") {
                AdhkarView()
            }

            resourceLink(title: "Dua & Supplications", systemImage: "text.book.closed") {
                DuaView()
            }

            resourceLink(title: "Tasbih Counter", systemImage: "circles.hexagonpath.fill") {
                TasbihView()
            }

            #if os(iOS)
            resourceLink(title: "Zakah Calculator", systemImage: "percent") {
                ZakahCalculatorView()
            }

            resourceLink(title: "Inheritance Calculator", systemImage: "divide.circle", placesOwnSettingsGear: true) {
                InheritanceCalculatorView()
            }
            #endif

            resourceLink(title: "99 Names of Allah", systemImage: "signature", placesOwnSettingsGear: true) {
                NamesView()
            }

            #if os(iOS)
            resourceLink(title: "Hijri Date Converter", systemImage: "calendar") {
                DateView()
            }

            resourceLink(title: "Masjid Locator", systemImage: "mappin.and.ellipse") {
                PlaceLocatorView(profile: .masjid)
            }

            resourceLink(title: "Halal Food Locator", systemImage: "fork.knife") {
                PlaceLocatorView(profile: .halalFood)
            }
            #endif

            resourceLink(title: "Pillars & Beliefs", systemImage: "moon.stars") {
                PillarsView()
            }

            resourceLink(title: "How-To Guides", systemImage: "list.bullet.rectangle") {
                GuidesView()
            }

            resourceLink(title: "Islamic Wallpapers", systemImage: "photo.on.rectangle") {
                WallpaperView()
            }
        }
    }

    #if os(iOS)
    @available(iOS 16.0, *)
    @ViewBuilder
    private var resourcesSectionSplit: some View {
        // The sidebar answers to the SAME grid toggle the iPhone list does (Abu, 2026-09-14: "Islam
        // view doesn't have grid mode top right on iPad"). It was list-only on the reasoning that a
        // grid crammed into a sidebar column reads worse than rows - true at three columns, which is
        // why this one is two.
        startHereSection(split: true)

        let favorites = favoriteResources
        if !favorites.isEmpty {
            Section(header: Text("FAVORITES")) {
                splitResourceItems(favorites)
            }
        }

        Section(header: Text("ISLAMIC RESOURCES")) {
            splitResourceItems(IslamDestination.available)
        }
    }

    /// The sidebar's rows or tiles for one section. Rows keep `List(selection:)`'s own highlight;
    /// tiles are inside a single list row, so the selection has to be drawn on the tile itself.
    @available(iOS 16.0, *)
    @ViewBuilder
    private func splitResourceItems(_ items: [IslamDestination]) -> some View {
        if settings.islamGridMode {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(items, id: \.self) { item in
                    resourceGridStar(item, on: GridTileMenu {
                        selectSplitResource(item)
                    } menu: {
                        favoriteToggleButton(item)
                    } label: {
                        resourceGridTile(item)
                            // `GlassCorner.rectangle`, NOT a hardcoded number: this border outlines
                            // the tile's own glass shape, and at 12 against the glass's 24 it cut
                            // visible corners inside the tile it was meant to trace
                            // (Abu, 2026-09-19, with a screenshot of the iPad sidebar).
                            .overlay(
                                RoundedRectangle(cornerRadius: GlassCorner.rectangle, style: .continuous)
                                    .strokeBorder(settings.accentColor.color,
                                                  lineWidth: selectedResource == item ? 2 : 0)
                            )
                    })
                }
            }
            // Same reasoning as the iPhone grid's inset: the section row carries ~16pt of its own.
            .padding(.vertical, 1)
        } else {
            ForEach(items, id: \.self) { splitResourceLink($0) }
        }
    }

    /// Selecting a sidebar resource, shared by the rows and the tiles: re-tapping the row that is
    /// already selected pops its section back to the root instead of doing nothing.
    @available(iOS 16.0, *)
    private func selectSplitResource(_ value: IslamDestination) {
        settings.hapticFeedback()
        withAnimation(.easeInOut) {
            if selectedResource == value {
                islamDetailRefreshToken &+= 1
            } else {
                selectedResource = value
            }
        }
    }

    @available(iOS 16.0, *)
    private func splitResourceLink(_ value: IslamDestination) -> some View {
        Button {
            // Re-tapping the selected row must still LAND - see `selectSplitResource`.
            selectSplitResource(value)
        } label: {
            toolLabel(value.title, systemImage: value.systemImage)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .tag(value)
        .contextMenu { favoriteToggleButton(value) }
    }
    #endif

    private func resourceLink<Destination: View>(
        title: String,
        systemImage: String,
        placesOwnSettingsGear: Bool = false,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        // The destination is wrapped so it is built only when the row is actually pushed. The plain
        // `NavigationLink(destination:)` initializer evaluates its destination immediately, which meant every
        // body pass of this list constructed all nine destination views - the watch's swipe-into-this-tab
        // hitch (iOS 16+ uses the lazy `navigationDestination(for:)` path instead and never hit this).
        #if os(iOS)
        // The pre-iOS 16 list pushes through here instead of `destinationView(for:)`: same gear,
        // and the same exception for the screens that place it themselves.
        NavigationLink(destination: LazyDestination {
            // A Group, because `LazyDestination`'s closure is a plain one and not a view builder.
            Group {
                if placesOwnSettingsGear { destination() } else { destination().islamSettingsToolbar() }
            }
        }) {
            toolLabel(title, systemImage: systemImage)
        }
        #else
        NavigationLink(destination: LazyDestination(build: destination)) {
            toolLabel(title, systemImage: systemImage)
        }
        #endif
    }

    private func toolLabel(_ title: String, systemImage: String, subtitle: String? = nil) -> some View {
        #if os(watchOS)
        // The 40 mm face leaves about 103 pt beside the standard chip, and "Remembrances" (108 pt at
        // its body size) broke as "Remem-" / "brances"; a smaller chip and gap there give the title
        // the line it needs, at full size.
        let chipSize: CGFloat = WatchScreen.isNarrow ? 24 : 29
        let chipSpacing: CGFloat = WatchScreen.isNarrow ? 8 : 12
        #else
        let chipSize: CGFloat = 29
        let chipSpacing: CGFloat = 12
        #endif
        return HStack(spacing: chipSpacing) {
            AccentIconChip(systemImage: systemImage, size: chipSize)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .foregroundColor(.primary)

                // The caption column is an iPhone luxury - the 40mm screen has no room for it.
                #if os(iOS)
                if let subtitle {
                    // Two lines, at full size. It used to be one line shrunk to 80%, so the longer
                    // subtitles ("Divide an estate by the Quranic shares") rendered smaller than
                    // their neighbours AND still clipped - the rows read as ragged (Abu, 2026-09-19).
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                #endif
            }
        }
        .padding(.vertical, 3)
    }
}

/// The quote card sits between two first-accent sections (resources above, apps below), so it is the screen's
/// second-accent section - every tint in here reads from `accent2`.
///
/// Its motion is a single LIGHT SWEEP: when the card appears, a soft band of light crosses it once from the
/// leading edge to the trailing edge, and the badge's ring keeps a slow shimmer turning. Nothing scales,
/// nothing moves up or down, nothing pulses - the earlier scale/offset/opacity entrance replayed on every
/// scroll past the card and read as the whole card breathing.
struct ProphetQuote: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.appearance) private var appearance
    /// The sweep's horizontal position across the card, in points from its centre. Parked off the leading
    /// edge until the card appears, then animated once past the trailing edge.
    @State private var sweepOffset: CGFloat = -600
    @State private var rotateRing = false

    private let quoteText = "“O people, your Lord is one and your father Adam is one. There is no superiority of an Arab over a non-Arab, nor of a non-Arab over an Arab, nor of a red man over a black man, nor of a black man over a red man, except by taqwa (piety, righteousness, and God-consciousness).“"
    private let attributionText1 = "Farewell Sermon\nMusnad Ahmad 22978"
    private let attributionText2 = "Jumuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE"

    var body: some View {
        Section(header: Text("PROPHET MUHAMMAD ﷺ QUOTE")) {
            ZStack {
                if appearance.liquidGlass {
                    quoteCardBackground
                }

                VStack(alignment: .center, spacing: 12) {
                    quoteBadge
                    quoteBody
                    ornamentDivider
                    attribution
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .conditionalGlassEffect(rectangle: true, useColor: 0.16)
                .overlay(lightSweep)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 2)
            .onAppear(perform: startMotion)
            .onDisappear {
                sweepOffset = -600
                rotateRing = false
            }
        }
        #if os(iOS)
        .contextMenu {
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                UIPasteboard.general.string = "O people, your Lord is one and your father Adam is one. There is no superiority of an Arab over a non-Arab, nor of a non-Arab over an Arab, nor of a red man over a black man, nor of a black man over a red man, except by taqwa (piety, righteousness, and God-consciousness).\n\n– Farewell Sermon\nMusnad Ahmad 22978\n\nJumuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE"
            } label: {
                Label("Copy Text", systemImage: "doc.on.doc")
            }
        }
        #endif
    }

    /// One pass of light across the card - a narrow diagonal band, brighter at its centre, that never
    /// lingers: it enters from the leading edge and leaves past the trailing edge in about 1.4 s.
    private var lightSweep: some View {
        LinearGradient(
            colors: [
                .clear,
                settings.accentColor.accent2.opacity(0.10),
                Color.white.opacity(0.22),
                settings.accentColor.accent2.opacity(0.10),
                .clear,
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 140)
        .rotationEffect(.degrees(18))
        .offset(x: sweepOffset)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func startMotion() {
        // Purely decorative; in Low Power Mode a forever-animation is exactly the CPU the system is asking
        // apps not to spend, and the watch's paging TabView re-fires onAppear on every swipe (a restarted
        // forever-animation per swipe was the Quran → Islam swipe lag). The card renders identically, still.
        #if os(watchOS)
        return
        #else
        guard !AppPerformance.shouldReduceAnimations else { return }
        sweepOffset = -600
        withAnimation(.easeInOut(duration: 1.4).delay(0.35)) {
            sweepOffset = 600
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotateRing = true
        }
        #endif
    }

    private var quoteCardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        settings.accentColor.accent2.opacity(0.18),
                        Color.secondary.opacity(0.08),
                        settings.accentColor.accent2.opacity(0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(settings.accentColor.accent2.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: settings.accentColor.accent2.opacity(0.12), radius: 10, x: 0, y: 3)
    }

    private var quoteBadge: some View {
        ZStack {
            // A slowly rotating shimmer ring behind the badge: the card's one continuous motion.
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            settings.accentColor.accent2.opacity(0.0),
                            settings.accentColor.accent2.opacity(0.55),
                            settings.accentColor.accent2.opacity(0.0)
                        ]),
                        center: .center
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 66, height: 66)
                .rotationEffect(.degrees(rotateRing ? 360 : 0))

            Circle()
                .strokeBorder(settings.accentColor.accent2, lineWidth: 1)
                .frame(width: 60, height: 60)

            Text("ﷺ")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(settings.accentColor.accent2)
                .padding()
                .clipShape(Circle())
        }
        .conditionalGlassEffect(circle: true)
        // A steady, quiet glow - deliberately NOT animated.
        .shadow(color: settings.accentColor.accent2.opacity(0.28), radius: 8)
        .padding(4)
    }

    private var quoteBody: some View {
        // Editorial typography for the one quotation in the app: serif italic on the primary color,
        // with opened-up leading - the accent stays on the badge, ring and ornament, so the words
        // themselves read as ink rather than tint.
        Text(quoteText)
            .font(.system(.subheadline, design: .serif))
            .italic()
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .foregroundColor(.primary)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 6)
    }

    /// A thin rule fading in from both edges to a small diamond - the classical divider between a
    /// quotation and its attribution.
    private var ornamentDivider: some View {
        HStack(spacing: 10) {
            LinearGradient(
                colors: [settings.accentColor.accent2.opacity(0), settings.accentColor.accent2.opacity(0.45)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)

            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundColor(settings.accentColor.accent2.opacity(0.7))

            LinearGradient(
                colors: [settings.accentColor.accent2.opacity(0.45), settings.accentColor.accent2.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
        .frame(maxWidth: 220)
        .padding(.top, 2)
    }

    private var attribution: some View {
        VStack(spacing: 10) {
            Text(attributionText1)
                .foregroundColor(.primary)
                .font(.caption)

            Text(attributionText2)
                .foregroundColor(.secondary)
                .font(.caption2)
        }
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct AlIslamAppsSection: View {
    @ObservedObject var settings = Settings.shared
    #if os(iOS)
    @State private var showLearnMoreSheet = false
    #endif
    @State private var popLeft = false
    @State private var popCenter = false
    @State private var popRight = false

    #if os(iOS)
    let spacing: CGFloat = 20
    #else
    let spacing: CGFloat = 10
    #endif

    var body: some View {
        Section(header: Text("AL-ISLAMIC APPS")) {
            ZStack {
                cardBackground

                VStack(spacing: 10) {
                    appCardsRow
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    #if os(iOS)
                    Button {
                        settings.hapticFeedback()
                        showLearnMoreSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles.rectangle.stack")
                            Text("Learn More")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                    }
                    .contentShape(Rectangle())
                    .conditionalGlassEffect()
                    .padding([.horizontal, .bottom], 8)
                    #endif
                }
            }
            .conditionalGlassEffect(rectangle: true)
            .onAppear(perform: runAppCardsPopAnimation)
            #if DEBUG
            .onAppear { MemoryFootprint.logLater("app tiles") }
            #endif
            #if os(iOS) && DEBUG
            // `-openLearnMore` (pair it with `-islamScrollToApps`, which brings this card on
            // screen): opens the Learn More sheet for screenshot runs - taps aren't scriptable.
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("-openLearnMore") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showLearnMoreSheet = true }
                }
            }
            #endif
            .onDisappear {
                withAnimation {
                    popLeft = false
                    popCenter = false
                    popRight = false
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showLearnMoreSheet) {
                SplashScreen(presentedAsSheet: true)
            }
            #endif
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.yellow.opacity(0.25), .green.opacity(0.25)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .primary.opacity(0.25), radius: 5, x: 0, y: 1)
    }

    #if os(iOS)
    private var alIslamAppsCardBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return -11
        }
        return -2
    }
    #endif

    private var appCardsRow: some View {
        HStack(spacing: spacing) {
            if let url = URL(string: "https://apps.apple.com/us/app/al-adhan-prayer-times/id6475015493?platform=iphone") {
                Card(title: "Al-Adhan", url: url)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(popLeft ? 1 : 0.2)
                    .offset(y: popLeft ? 0 : 80)
                    .opacity(popLeft ? 1 : 0.35)
                    .rotationEffect(.degrees(-6))
            }

            if let url = URL(string: "https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655?platform=iphone") {
                Card(title: "Al-Islam", url: url)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(popCenter ? 1.02 : 0.24)
                    .offset(y: popCenter ? 0 : 86)
                    .opacity(popCenter ? 1 : 0.4)
            }

            if let url = URL(string: "https://apps.apple.com/us/app/al-quran-beginner-quran/id6474894373?platform=iphone") {
                Card(title: "Al-Quran", url: url)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(popRight ? 1 : 0.2)
                    .offset(y: popRight ? 0 : 80)
                    .opacity(popRight ? 1 : 0.35)
                    .rotationEffect(.degrees(6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .padding(.horizontal)
    }

    private var popSpring: Animation {
        .spring(response: 0.52, dampingFraction: 0.62, blendDuration: 0)
    }

    private func runAppCardsPopAnimation() {
        // The watch's paging TabView re-fires onAppear on every swipe, and this section sits on BOTH the
        // Islam and Settings tabs - replaying a three-stage spring (plus decoding three card images) on
        // each swipe was a real slice of the tab-switch lag. The cards just show, settled.
        #if os(watchOS)
        popLeft = true
        popCenter = true
        popRight = true
        #else
        // Reduced tier / Reduce Motion: the cards just show, settled (Performance Guide, Phase 6
        // step 8) - three springs on every tab appearance are decoration.
        if AppPerformance.shouldReduceAnimations {
            popLeft = true
            popCenter = true
            popRight = true
            return
        }
        popLeft = false
        popCenter = false
        popRight = false

        withAnimation(popSpring) {
            popCenter = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(popSpring) {
                popLeft = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(popSpring) {
                popRight = true
            }
        }
        #endif
    }
}

private struct Card: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.openURL) private var openURL
    @State private var showActions = false

    let title: String
    let url: URL

    private var iconImage: UIImage? {
        UIImage(named: title)
    }

    var body: some View {
        VStack {
            // The 300 px "<name> Tile" asset, not the 1024 px icon: a 100-point tile decoded from the
            // full icon cost 4 MB apiece on every Islam and Settings tab switch (Phase 6 step 4).
            Image("\(title) Tile")
                .resizable()
                .scaledToFit()
                .cornerRadius(18)
                .shadow(radius: 4)

            #if os(iOS)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 4)
            #endif
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                settings.hapticFeedback()
                openURL(url)
            }
        }
        #if os(iOS)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                settings.hapticFeedback()
                showActions = true
            }
        )
        .confirmationDialog(title, isPresented: $showActions, titleVisibility: .visible) {
            Button {
                UIPasteboard.general.string = url.absoluteString
                settings.hapticFeedback()
            } label: {
                Label("Copy Link", systemImage: "link")
            }

            if iconImage != nil {
                Button {
                    if let iconImage {
                        UIPasteboard.general.image = iconImage
                        settings.hapticFeedback()
                    }
                } label: {
                    Label("Copy Icon", systemImage: "doc.on.doc")
                }
            }

            Button("Cancel") { }
        }
        #endif
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: true) {
        IslamView()
    }
}
