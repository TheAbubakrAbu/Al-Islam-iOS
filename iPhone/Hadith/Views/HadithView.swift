import SwiftUI

// The Hadith tab root: summary tiles, Hadith of the Day, bookmarks, favorites, the catalog by group,
// reference lookups, and all-books search. Every collection ships inside the app as a pack on
// demand (any book whose JSON is ever bundled into the app is picked up automatically instead).

#if os(iOS)

struct HadithTrailingToolbar: ViewModifier {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Binding var hadithGridMode: Bool
    @Binding var showHadithSettings: Bool
    /// A jump's one-visit list (`HadithView.listForJump`, `HadithBookView.listForJump`).
    var listForJump: Binding<Bool> = .constant(false)
    /// The tab root's ⋯ More menu items (`HadithView.moreMenuItems`), in both modes since 2026-10-11
    /// (Abu: "for settings and hadith too put it on the left as a menu"); nil on a book's screen, which
    /// keeps its chapter grid toggle up here. While set, the menu leads and the gear keeps its own slot.
    var moreMenuItems: AnyView? = nil

    func body(content: Content) -> some View {
        if let moreMenuItems {
            content.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    TabMoreMenu(hold: MenuShortcut(hadithGridMode && !listForJump.wrappedValue ? String(localized: "Show as List") : String(localized: "Show as Grid")) {
                        Settings.shared.hapticFeedback()
                        withAnimation {
                            if listForJump.wrappedValue { listForJump.wrappedValue = false } else { hadithGridMode.toggle() }
                        }
                    }) { moreMenuItems }
                }
                ToolbarItem(placement: .navigationBarTrailing) { gearButton }
            }
        } else if #available(iOS 26.0, *) {
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { gridButton }
                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
                ToolbarItem(placement: .navigationBarTrailing) { gearButton }
            }
        } else {
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { gridButton }
                ToolbarItem(placement: .navigationBarTrailing) { gearButton }
            }
        }
    }

    private var gridButton: some View {
        // What the screen shows, so a jump's one-visit list reads as a list here too.
        let showsGrid = hadithGridMode && !listForJump.wrappedValue
        return Button {
            settings.hapticFeedback()
            withAnimation {
                // From a jump's list the button only brings the grid back: the stored choice never
                // stopped being grid.
                if listForJump.wrappedValue { listForJump.wrappedValue = false } else { hadithGridMode.toggle() }
            }
        } label: {
            Image(systemName: showsGrid ? "list.bullet" : "square.grid.2x2")
        }
        .accessibilityLabel(showsGrid ? "Show list" : "Show grid")
        .tint(settings.accentColor.accent2)
    }

    private var gearButton: some View {
        Button {
            settings.hapticFeedback()
            showHadithSettings = true
        } label: {
            Image(systemName: "gear")
        }
        .accessibilityLabel("Hadith settings")
        .tint(settings.accentColor.accent2)
    }
}

// MARK: - The tab root: collections

struct HadithView: View {
    #if DEBUG
    /// `-launchHadithSettings` presents once per launch (see the hook in the body's onAppear).
    private static var debugSettingsHookScheduled = false
    #endif
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var hadithSettings = HadithSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject private var store = HadithStore.shared
    /// The favorites and bookmark sections render user marks, which the store only FORWARDS (they
    /// live in HadithUserData, their own publisher) - observing it here is what re-renders them.
    @ObservedObject private var userData = HadithUserData.shared

    @State private var searchText = ""
    @State private var showHadithSettings = false
    /// Grid tiles are plain Buttons (a NavigationLink cell in a List draws a chevron); tapping one sets
    /// this, and the `onChange` on `content` turns it into a `bookPath` push (iOS 16 is the floor since
    /// 2026-10-09, so the hidden `NavigationLink` that once did the push on iOS 15 is gone).
    @State private var pushedBook: HadithCatalogBook?
    /// Which summary door was tapped (Today / Topics / Encyclopedia / History, the About cards). One
    /// piece of state driving one destination: see `SummaryDoor`.
    @State private var openDoor: SummaryDoor?
    #if DEBUG
    /// `-launchHadithEncyclopedia`: the Hadith Encyclopedia pushed on launch, the headless way in.
    @State private var debugOpenEncyclopedia = false
    @State private var debugOpenTopics = false
    @State private var debugOpenHistory = false
    #endif

    /// Collapse state for the favorites/bookmarks sections, same as the Quran tab's.
    @AppStorage("showHadithFavoriteBooks") private var showFavoriteBooks = true
    @AppStorage("showHadithBookmarks") private var showHadithBookmarks = true
    /// The Hadith tab's OWN grid/list choice - deliberately decoupled from the app-wide `gridMode`
    /// switch, so flipping the hadith catalog doesn't flip the Quran, 99 Names, and Islam grids too.
    /// Grid by default, like every other catalog (Abu, 2026-09-18).
    @AppStorage("hadithGridMode") private var hadithGridMode = true
    /// Scroll To Book from the grid shows the list for that one visit (a grid tile has no scroll
    /// target), and never writes the stored choice, which until 2026-10-10 it switched off for good.
    @State private var listForJump = false
    private var showsGrid: Bool { hadithGridMode && !listForJump }
    /// "Scroll to book" from a search result: clears the search and lands the catalog on this book.
    @State private var pendingScrollToBookSlug: String? = nil
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// True while the bottom search field has the keyboard - the recent-searches chips only show then.
    @State private var isHadithSearchFocused = false
    /// The last query written to the search history, so editing keystrokes don't rewrite it repeatedly.
    @State private var lastSavedSearchQuery = ""

    // All-books search - automatic, the Quran search's way: books, then chapters (page of 5),
    // then hadiths (page of 5), each with Load More.
    private struct GlobalChapterHit: Identifiable {
        let book: HadithCatalogBook
        let data: HadithBookData
        let chapter: HadithBookData.Chapter
        var id: String { "\(book.slug)-\(chapter.id)" }
    }
    private struct GlobalHadithHit: Identifiable {
        let book: HadithCatalogBook
        let data: HadithBookData
        let hadith: HadithBookData.Hadith
        var id: String { "\(book.slug)-\(hadith.id)" }
    }
    @State private var globalChapterResults: [GlobalChapterHit] = []
    @State private var globalHadithResults: [GlobalHadithHit] = []
    /// The ranked lane (`HadithRankedSearch`): every book scored word by word - stems, spelling
    /// variants, typo correction, chapter titles weighted over narration text - best first. Lands after
    /// the exact sweep's first page, on the same settled query.
    @State private var globalRankedHits: [GlobalHadithHit] = []
    @State private var globalRankedTotal = 0
    @State private var globalRankedRelaxed = false
    @State private var globalRankedCorrections: [HadithRankedSearch.Correction] = []
    @State private var globalRankedHighlight = ""
    @State private var globalRankedLimit = 6
    private static let rankedHadithCap = 40
    /// A ranked row's List identity, distinct from the same hadith's row in the book-ordered list.
    private struct RankedHadithRow: Identifiable {
        let hit: GlobalHadithHit
        var id: String { "ranked-" + hit.id }
    }
    // Bare-number search ("10"): chapter N + hadith N across every book (distinct from the
    // "bukhari 10" reference card, which resolves one exact hadith). Reuses the chapter/hadith hit shapes.
    @State private var globalNumberChapters: [GlobalChapterHit] = []
    @State private var globalNumberHadiths: [GlobalHadithHit] = []
    @State private var numberSearchRanFor: Int? = nil
    @State private var isNumberSearching = false
    @State private var globalNumberTask: Task<Void, Never>?
    @State private var globalHasMoreChapters = false
    @State private var globalHasMoreHadiths = false
    @State private var globalChapterLimit = 5
    @State private var globalHadithLimit = 5
    /// EVERY matching chapter for the settled query - chapter names ride in the packs' eager
    /// sections, so all ~1,700 of them are compared in microseconds and Load More is a prefix.
    @State private var globalAllChapterHits: [GlobalChapterHit] = []
    /// Where the hadith sweep stopped: the (catalog index, row) the next Load More resumes from.
    /// It used to restart from book 1 and re-scan everything already shown.
    @State private var globalHadithCursor: (book: Int, row: Int)? = nil
    @State private var isGlobalSearching = false
    /// The button row's filters (HadithSearchFilters.swift): books, gradings, word mode, order, sections.
    @State private var searchFilters = HadithSearchFilters.restored()
    @State private var showSearchFilterSheet = false
    @State private var globalSearchRanFor = ""
    @State private var globalSearchTask: Task<Void, Never>?

    // The tab-wide AI matches: ONE combined corpus over EVERY book (built once and persisted, and
    // the shelf can no longer change under it) - so "controlling anger" searches all
    // hadiths at once, which is what a tab-level search means 9 times out of 10.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var globalAIResults: [GlobalHadithHit] = []

    // Ask AI: the on-device chat (`AskAIChatView`), opened from the ASK AI row above the results with
    // the typed query as its first question - the Quran tab's rule. Exists only on Apple Intelligence
    // devices (`OnDeviceAsk.isAvailable`).
    @State private var showAskAI = false
    /// The help card folded to its title + recent chips (persists; the -/+ on the card).
    @AppStorage("hadithSearchHelpCollapsed") private var hadithSearchHelpCollapsed = false
    /// The folded help put away for good by its trash; the recent searches stay. Hadith Settings
    /// brings it back (the Quran tab's `quranSearchHelpRemoved`, for hadith).
    @AppStorage("hadithSearchHelpRemoved") private var hadithSearchHelpRemoved = false
    /// The trash's confirmation, hung on the list: the card exists only while the field is focused.
    @State private var confirmingSearchHelpRemoval = false
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist (the Quran search's
    /// `showKeywordResults`). Reset to the AI list on every new query.
    @State private var showHadithKeywordResults = HadithView.opensOnKeywordResults
    /// Which list a new query opens on: the keyword lists unless the reader chose AI first
    /// (`SearchFilterBar.opensOnKeywordResults`). "-hadithKeywordResults" and "-hadithAIResults"
    /// (DEBUG) force one or the other, because a screenshot cannot tap the switch. Re-read on each
    /// typed query: "-hadithSearch" seeds the text a beat after launch, and that seeding is itself a
    /// new query.
    static var opensOnKeywordResults: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-hadithKeywordResults") { return true }
        if ProcessInfo.processInfo.arguments.contains("-hadithAIResults") { return false }
        #endif
        return SearchFilterBar.opensOnKeywordResults
    }
    @State private var globalAITask: Task<Void, Never>?
    /// True while the slow path (reading every book to gather texts) runs, pre-embedding.
    @State private var isGatheringAllBooks = false

    private var allBooksCorpusID: String { HadithSemanticCorpus.id }

    /// Load-or-build the all-books corpus (`HadithSemanticCorpus`, shared with the Ask AI chat). The
    /// disk hit is instant; the cold build reads each book once (off the visible path) and then
    /// embeds a SHARED vocabulary - the books overlap heavily in words, so all-of-them costs little
    /// more than Bukhari alone.
    private func prepareAllBooksCorpus() {
        guard SemanticSearchEngine.isSupported,
              !semanticEngine.isReady(allBooksCorpusID),
              !semanticEngine.isBuilding(allBooksCorpusID),
              !isGatheringAllBooks,
              // The Ask AI chat may own the gather: never re-enter while it runs (a prepare that
              // returns at once would otherwise re-run the search, which re-calls this, forever).
              !HadithSemanticCorpus.isGathering else { return }
        isGatheringAllBooks = true
        Task {
            await HadithSemanticCorpus.prepare(engine: semanticEngine, store: store)
            isGatheringAllBooks = false
            // Re-run only when a corpus actually landed (the disk load); a build started here
            // finishes through `.onChange(of: semanticEngine.readyCorpora)`.
            if semanticEngine.isReady(allBooksCorpusID) { runGlobalAISearch(query: searchText) }
        }
    }

    private func runGlobalAISearch(query: String) {
        globalAITask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filters = searchFilters
        guard SemanticSearchEngine.isSupported, filters.shows(.ai), trimmed.count >= 3, !trimmed.containsArabicScript,
              HadithReferenceParser.parse(trimmed) == nil else {
            if !globalAIResults.isEmpty { globalAIResults = [] }
            return
        }
        prepareAllBooksCorpus()
        // The engine ranks the whole shelf; books and gradings cut what comes back, so ask for more.
        let narrowed = !filters.books.isEmpty || !filters.grades.isEmpty

        globalAITask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            let results = await semanticEngine.search(corpusID: allBooksCorpusID, query: trimmed, limit: narrowed ? 120 : 10)
            guard !Task.isCancelled else { return }
            guard let keys = semanticEngine.corpus(allBooksCorpusID)?.itemKeys else {
                if !globalAIResults.isEmpty {
                    await MainActor.run { globalAIResults = [] }
                }
                return
            }

            var hits: [GlobalHadithHit] = []
            for result in results {
                guard keys.indices.contains(result.index) else { continue }
                let parts = keys[result.index].split(separator: "|")
                guard parts.count >= 2, let idInBook = Int(parts[1]),
                      let book = HadithCatalogBook.bySlug[String(parts[0])], filters.includes(book),
                      let data = store.book(book),
                      let hadith = data.hadiths.first(where: { $0.idInBook == idInBook }) else { continue }
                hits.append(GlobalHadithHit(book: book, data: data, hadith: hadith))
                if Task.isCancelled { return }
            }

            // The grading reads each row's text block, so it is asked off the main actor.
            let candidates = hits
            let top: [GlobalHadithHit] = filters.grades.isEmpty ? Array(candidates.prefix(10)) : await Task.detached(priority: .userInitiated) {
                Array(candidates.filter { hit in
                    hit.hadith.row < 0 || (filters.gradeTest(for: hit.book, data: hit.data)?(hit.hadith.row) ?? true)
                }.prefix(10))
            }.value
            // The rows' text blocks, inflated off the main actor before they show (the ranked and
            // sweep rows are warmed the same way; these decoded theirs in their bodies on main).
            await withTaskGroup(of: Void.self) { group in
                for hit in top where hit.hadith.row >= 0 {
                    let data = hit.data
                    let row = hit.hadith.row
                    group.addTask(priority: .userInitiated) { data.prewarmText(rows: row..<(row + 1)) }
                }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines), filters == searchFilters else { return }
                // Plain apply: an animated section insert racing the keyword sweep's own apply is the
                // collection-view assertion crash the Quran search hit.
                globalAIResults = top
            }
        }
    }

    /// Today's hadith lives in the STORE, resolved at app launch - the tab
    /// renders it instantly. Nil while the tile is hidden for today or turned off (the Ayah of the
    /// Day card's "Hide for Today" / "Delete Forever", 2026-09-21).
    private var dailyHadith: HadithStore.DailyPick? {
        guard settings.showHadithOfTheDay, !settings.isHadithOfTheDayHiddenToday else { return nil }
        return store.daily
    }
    /// "Delete Forever" on the Hadith of the Day asks first, like the ayah card's.
    @State private var confirmDeleteDailyForever = false
    /// Which tile's recents are unfolded under the grid, the Quran tab's one expansion slot: the
    /// Hadith of the Day's earlier days, or where each book was left. Until 2026-10-26 the daily
    /// history alone unfolded, from a +/- in the header; the + sits in the tile's corner now, where
    /// the Quran tab's tiles carry theirs.
    @State private var summaryHistoryExpansion: SummaryHistoryKind?

    enum SummaryHistoryKind { case daily, leftOff }

    /// Toggle a tile's recents: the same tile collapses, a different tile takes over the one slot.
    private func toggleSummaryExpansion(_ kind: SummaryHistoryKind) {
        withAnimation(.easeInOut) {
            summaryHistoryExpansion = summaryHistoryExpansion == kind ? nil : kind
        }
    }

    /// Where each book was left, newest first (the History screen's WHERE YOU LEFT OFF).
    private var leftOffEntries: [HadithLastRead] {
        store.lastReadByBook.values.sorted { $0.timestamp > $1.timestamp }
    }
    /// A hidden push target (shuffled bookmark, summary tiles) - HadithReferenceView by slug+number.
    @State private var pushedReference: HadithBookmark? = nil

    private func matches(_ book: HadithCatalogBook) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        if book.englishTitle.localizedCaseInsensitiveContains(query.foldingLatinDiacritics) ||
            book.arabicTitle.localizedCaseInsensitiveContains(query) {
            return true
        }
        // The cleaned QUERY is identical for all 17 books - normalize it once per filter pass, not per book.
        let cleanedQuery = Self.cleanedQueryCache.query == query
            ? Self.cleanedQueryCache.cleaned
            : {
                let cleaned = settings.cleanSearch(query, whitespace: true)
                Self.cleanedQueryCache = (query, cleaned)
                return cleaned
            }()
        if settings.cleanSearch(book.arabicTitle, whitespace: true).localizedCaseInsensitiveContains(cleanedQuery) {
            return true
        }
        // The reference parser's name resolution as a last resort, so a misspelled book name
        // ("Tirmidi", "Bokhari") still surfaces its book - same aliases, prefixes, and
        // one-edit tolerance the "tirmidi 2950" reference path uses. Resolved once per query.
        let resolvedSlug = Self.resolvedBookCache.query == query
            ? Self.resolvedBookCache.slug
            : {
                let slug = HadithReferenceParser.book(named: query)?.slug
                Self.resolvedBookCache = (query, slug)
                return slug
            }()
        return resolvedSlug == book.slug
    }

    private static var cleanedQueryCache: (query: String, cleaned: String) = ("", "")
    private static var resolvedBookCache: (query: String, slug: String?) = ("", nil)

    private func filteredBooks(in group: HadithCatalogBook.Group) -> [HadithCatalogBook] {
        HadithCatalogBook.books(in: group).filter(matches)
    }

    private var filteredFavorites: [HadithCatalogBook] {
        HadithCatalogBook.all.filter { store.isFavorite($0.slug) && matches($0) }
    }

    private var referenceResult: HadithReferenceParser.Reference? {
        HadithReferenceParser.parse(searchText)
    }

    /// A bare-citation query ("10", or "8a" with sunnah.com's variant letter) - drives the
    /// reference-number sweep (chapter N + hadith cited N across every book). Distinct from
    /// `referenceResult` ("bukhari 10"), which names a book and resolves one exact hadith.
    private var citationQuery: (base: Int, suffix: String?)? {
        HadithBookData.citationNumber(inQuery: searchText)
    }

    /// The base number of `citationQuery` - what the section headers and staleness guards key on.
    private var numberQuery: Int? { citationQuery?.base }

    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    /// Heap-box a section subtree - QuranView's stack-overflow fix, applied here preemptively: the
    /// body's one List expression otherwise materializes every section's whole generic view value on a
    /// single stack frame, and this tab builds under the launch cover too.
    private func boxed<V: View>(_ view: V) -> AnyView { AnyView(view) }

    /// The Quran tab's Quick Search Help, for hadith - shown while the search field is focused and
    /// empty. Deliberately terse.
    @ViewBuilder
    private var searchHelpOverlay: some View {
        // Simple Mode draws only the recent-search chips (the stored fold and removal flags are not
        // read on that path); with the help removed the card is only the recents too. With none, no card.
        let examplesHidden = settings.hides(.quickSearchHelp)
        if isHadithSearchFocused, searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           examplesHidden ? !settings.hadithSearchHistory.isEmpty
                          : (!hadithSearchHelpRemoved || !settings.hadithSearchHistory.isEmpty) {
            VStack(alignment: .leading, spacing: 10) {
                // The Quran card's grammar: the help folds behind a -/+, the recent chips stay at
                // the bottom, nearest the field. Folded, a trash removes the help for good.
                if !examplesHidden, !hadithSearchHelpRemoved {
                HStack(spacing: 8) {
                    Text("Quick Search Help")
                        .font(.subheadline.bold())
                        .foregroundStyle(settings.accentColor.color)

                    Spacer(minLength: 0)

                    if hadithSearchHelpCollapsed {
                        Button {
                            settings.hapticFeedback()
                            confirmingSearchHelpRemoval = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline)
                                .foregroundStyle(settings.accentColor.color)
                                .contentShape(Rectangle().inset(by: -8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove search help")
                    }

                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { hadithSearchHelpCollapsed.toggle() }
                    } label: {
                        Image(systemName: hadithSearchHelpCollapsed ? "plus.circle" : "minus.circle")
                            .font(.subheadline)
                            .foregroundStyle(settings.accentColor.color)
                            .contentShape(Rectangle().inset(by: -8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(hadithSearchHelpCollapsed ? "Show search help" : "Hide search help")
                }

                if !hadithSearchHelpCollapsed {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Books, chapters or hadith text, in English or Arabic")
                        Text(String(localized: "• A reference: 'bukhari 5103' or 'muslim 3:12'").localizedDigits)
                        Text("• By meaning: 'controlling anger', or ask a question")
                        Text("• The buttons above narrow it by book and grade")
                    }
                    .font(.caption)
                    .foregroundStyle(.primary)
                }
                }

                HadithRecentSearches(searchText: $searchText)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .conditionalGlassEffect(rectangle: true)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    var body: some View {
        #if DEBUG
        let _ = LaunchClock.markOnce("hadith root: first body")
        #endif
        navigationContainer
            // The window crossed the compact/regular boundary (iPad Split View drag, Slide Over, Stage
            // Manager) and the container swapped between the split view and the stack. Carry the open
            // book across the swap instead of dropping the reader back on the catalog.
            // Only for a boundary crossing the USER made - backgrounding the app makes iOS flip the
            // window compact and back for its app-switcher snapshots, and this migration empties
            // `bookPath` on the way out, so a round trip closed the open book. See
            // `ColumnLayoutMigration`.
            .columnLayoutMigration(columns: usesColumnNavigation) { columns in
                guard #available(iOS 16.0, *) else { return }
                if columns {
                    // Stack → columns: a book still pending in the request state becomes the content
                    // column's path. (The interceptors on `content` only fire on assignment, and these
                    // were set BEFORE the flip, so they must be converted here.)
                    if let book = pushedBook {
                        pushedBook = nil
                        bookPath = [.book(slug: book.slug, autoOpenHadithID: nil)]
                    } else if let reference = pushedReference {
                        pushedReference = nil
                        bookPath = [.book(slug: reference.slug, autoOpenHadithID: reference.idInBook)]
                    }
                } else if let route = bookPath.last {
                    // Columns → stack: reopen the book through the request state, which the
                    // interceptors below turn into the stack's path. It opens at the spot the reading
                    // column was on when the store has one (the reader keeps last-read fresh), else at
                    // its chapter list.
                    // Delayed like every other programmatic push here: a push issued during the
                    // container swap lands on the container that is going away.
                    bookPath.removeAll()
                    let slug = route.slug
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        guard !usesColumnNavigation else { return }
                        if let lastRead = store.lastRead(for: slug) {
                            pushedReference = HadithBookmark(
                                slug: slug,
                                idInBook: lastRead.idInBook,
                                reference: "",
                                preview: ""
                            )
                        } else {
                            pushedBook = HadithCatalogBook.bySlug[slug]
                        }
                    }
                }
            }
    }

    /// iPad/Mac read the tab as TWO columns, the Quran tab's shape exactly: the catalog (and, once a book
    /// is open, its chapter list) on the left, the chapter being read on the right. It has to live HERE,
    /// at the tab root, rather than inside the book screen: only a real `NavigationSplitView` composes
    /// both columns' toolbars into the one bar row beside the tab bar - a split improvised further down
    /// leaves the reader's title squeezed into a second row under it.
    private var usesColumnNavigation: Bool {
        guard #available(iOS 16.0, *) else { return false }
        guard horizontalSizeClass == .regular else { return false }
        return UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac
    }

    /// One pushable screen, as a value a `NavigationStack` path can carry - by VALUE, not destination.
    /// In column mode because a legacy `NavigationLink(destination:)` inside a split view's first column
    /// is defined to open in the DETAIL column; in iPhone stack mode (iOS 16+) because path state is what
    /// finally killed the deep-link pop: a hidden `NavigationLink(isActive:)` could be handed a spurious
    /// `false` whenever a store publish re-rendered its host mid-push (the Last Read record, a corpus
    /// build), unwinding the just-opened chapter - no debounce or anchoring choice ever fully stopped it.
    enum BookRoute: Hashable {
        case book(slug: String, autoOpenHadithID: Int?)
        /// Books → Chapters → Hadiths, as path elements: the chapter rides ON TOP of its book's route,
        /// so backing out of a deep-linked hadith still lands on the chapter list, never skipping it.
        case chapter(slug: String, chapterId: Int, scrollToHadithId: Int?)

        var slug: String {
            switch self {
            case .book(let slug, _), .chapter(let slug, _, _): return slug
            }
        }
    }

    @State private var bookPath: [BookRoute] = []

    /// Shared by both iOS 16 containers. `columns` decides the environment flag and whether the book
    /// screen pushes chapters through the path (stack) or swaps the detail column (split).
    @available(iOS 16.0, *)
    @ViewBuilder
    private func routeDestination(_ route: BookRoute, columns: Bool) -> some View {
        switch route {
        case .book(let slug, let autoOpenHadithID):
            if let book = HadithCatalogBook.bySlug[slug] {
                // Set ON the destination: a `navigationDestination` builds its content in its own
                // environment, so a value applied to the stack above never reaches it - the book
                // screen would silently fall back to pushing.
                HadithBookView(
                    book: book,
                    autoOpenHadithID: autoOpenHadithID,
                    onPushChapter: columns ? nil : { chapter, scrollTo in
                        bookPath.append(.chapter(slug: slug, chapterId: chapter.id, scrollToHadithId: scrollTo))
                    }
                )
                .environment(\.hadithUsesColumnNavigation, columns)
            }
        case .chapter(let slug, let chapterId, let scrollToHadithId):
            if let book = HadithCatalogBook.bySlug[slug],
               let data = store.book(book),
               let chapter = data.chapters.first(where: { $0.id == chapterId }) {
                HadithChapterView(book: book, bookData: data, chapter: chapter, scrollToHadithId: scrollToHadithId)
            }
        }
    }

    @ViewBuilder
    private var navigationContainer: some View {
        if #available(iOS 16.0, *), usesColumnNavigation {
            NavigationSplitView {
                // The content column keeps its own stack: opening a book pushes its chapters HERE,
                // replacing the catalog, while the reader stays put on the right.
                NavigationStack(path: $bookPath) {
                    content
                        .navigationDestination(for: BookRoute.self) { route in
                            routeDestination(route, columns: true)
                        }
                }
                .splitSidebarColumn()
            } detail: {
                HadithDetailColumn()
            }
        } else if #available(iOS 16.0, *) {
            // iPhone: a real NavigationStack, not NavigationView - programmatic pushes live in
            // `bookPath`, which a mid-push re-render cannot spuriously unwind.
            NavigationStack(path: $bookPath) {
                content
                    .navigationDestination(for: BookRoute.self) { route in
                        routeDestination(route, columns: false)
                    }
            }
        } else {
            NavigationView {
                content
            }
            .navigationViewStyle(.stack)
        }
    }

    /// One catalog row's link into a book: by value in the content column, a plain push otherwise.
    @ViewBuilder
    private func bookLink<Label: View>(
        _ book: HadithCatalogBook,
        @ViewBuilder label: () -> Label
    ) -> some View {
        if #available(iOS 16.0, *) {
            // Value link in BOTH iOS 16 containers - the stack branch is a NavigationStack now, and
            // value pushes are what route every book open through `routeDestination` (which is also
            // where the stack-mode chapter-push closure gets attached).
            NavigationLink(value: BookRoute.book(slug: book.slug, autoOpenHadithID: nil)) {
                label()
            }
        } else {
            NavigationLink {
                LazyDestination {
                    HadithBookView(book: book)
                }
            } label: {
                label()
            }
        }
    }

    private var content: some View {
        RenderCounter.hit("HadithView.content")
        return ScrollViewReader { scrollProxy in
            List {
                Group {
                    // Every big subtree heap-boxed - the one-expression List otherwise materializes all
                    // of them on a single stack frame, which is exactly what overflowed the device main
                    // thread's 1MB stack in QuranView (the simulator's 8MB stack hid it). See `boxed`.
                    if searchText.isEmpty {
                        // Summary tiles are the only form now (the old full-row sections went with the
                        // removed Summary Mode setting). The three doors (topics, the encyclopedia,
                        // history) hung off the bottom of this section from 2026-09-07 to 2026-10-11;
                        // they are items of the ⋯ More menu now, in both modes, so with no tile to show
                        // there is nothing left in the section.
                        if showSummaryTiles {
                            boxed(summaryTilesSection)
                        }
                        // Need a Hand?: one language or both, and the name of Allah in red, right
                        // under the summary (see HelpDoors.swift).
                        boxed(HelpDoorsSection(area: .hadith))
                    }

                    if let reference = referenceResult {
                        boxed(referenceSection(reference))
                    }

                    if !searchText.isEmpty {
                        // The Quran search's order: matching books first, then chapters, then hadiths.
                        let results = SearchRank.sorted(HadithCatalogBook.all.filter(matches), by: searchText) {
                            [$0.englishTitle, $0.arabicTitle]
                        }
                        if !results.isEmpty {
                            boxed(bookSection(title: String(localized: "MATCHING BOOKS"), books: results, icon: "magnifyingglass", shuffle: false))
                        } else if referenceResult == nil, numberQuery == nil,
                                  globalChapterResults.isEmpty, globalHadithResults.isEmpty,
                                  globalRankedHits.isEmpty, globalAIResults.isEmpty {
                            // Said only while NOTHING else answered: over a page of matching hadiths
                            // the empty block was the first thing on screen and pushed them down.
                            // A bare number never matches a book title - the numbered chapter/hadith
                            // sections below are the answer, so skip the "no books" noise for it.
                            boxed(
                                Section(header: SectionPillHeader(title: String(localized: "MATCHING BOOKS"), count: 0, icon: "magnifyingglass")) {
                                    Text("No books match your search.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            )
                        }
                    }

                    boxed(globalNumberSection)

                    boxed(globalSearchSection)

                    if !store.bookmarks.isEmpty && searchText.isEmpty {
                        boxed(bookmarksSection)
                    }

                    if searchText.isEmpty {
                        let favorites = filteredFavorites
                        if !favorites.isEmpty {
                            boxed(bookSection(
                                title: String(localized: "FAVORITES"),
                                books: favorites,
                                icon: "star.fill",
                                accentTitle: true,
                                isExpanded: $showFavoriteBooks
                            ))
                        }

                        ForEach(HadithCatalogBook.Group.allCases, id: \.self) { group in
                            let books = filteredBooks(in: group)
                            if !books.isEmpty {
                                boxed(bookSection(title: group.rawValue.localizedDisplay, books: books, icon: group.systemImage))
                            }
                        }
                    }

                    if searchText.isEmpty {
                        boxed(aboutHadithSection)
                    }
                }
                .themedListRowBackground()
            }
            // Column mode: the reading (detail) column shows its own Now Playing bar - suppress the
            // catalog's copy or recitation puts one identical bar in EACH column (the Quran tab's rule).
            .applyConditionalListStyle(disableNowPlayingInset: usesColumnNavigation)
            // The ONE destination the three summary doors share. On the List, not on the row: a lazy
            // row's own destination never fires (see `PushDestination`).
            .pushDestination(isPresented: Binding(
                get: { openDoor != nil },
                set: { if !$0 { openDoor = nil } }
            )) {
                summaryDoorDestination
            }
            .compactListSectionSpacing()
            // The grid/list flip animates the whole catalog, same as the Quran tab.
            .animation(.easeInOut, value: showsGrid)
            #if DEBUG
            .debugPushDestination(isPresented: $debugOpenEncyclopedia) { HadeethEncView() }
            .debugPushDestination(isPresented: $debugOpenTopics) { HadithTopicsView() }
            .debugPushDestination(isPresented: $debugOpenHistory) { HadithHistoryView() }
            #endif
            // A recent search tapped in History (a pushed screen, which pops itself): the term goes
            // into the field once the pop has landed, the way the Quran tab's history chips search.
            .onReceive(HadithSearchHandoff.shared.$pendingTerm) { term in
                guard let term else { return }
                HadithSearchHandoff.shared.pendingTerm = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { searchText = term }
            }
            // Every caller in the tab sets one of these two request vars; here they become `bookPath`
            // values, which both containers navigate by (a legacy `destination` link inside a split
            // view would open in the DETAIL column, the reader's place). Intercepting them keeps every
            // caller unchanged.
            .onChange(of: pushedBook) { book in
                guard #available(iOS 16.0, *), let book else { return }
                pushedBook = nil
                // Both containers navigate by path.
                bookPath = [.book(slug: book.slug, autoOpenHadithID: nil)]
            }
            .onChange(of: pushedReference) { reference in
                guard #available(iOS 16.0, *), let reference else { return }
                pushedReference = nil
                guard usesColumnNavigation else {
                    // iPhone stack: the book route carries the target; the book screen resolves the
                    // chapter and APPENDS it to this same path (see `routeDestination`), so the stack
                    // is Books → Chapters → Hadiths and back never skips the chapter list.
                    bookPath = [.book(slug: reference.slug, autoOpenHadithID: reference.idInBook)]
                    return
                }
                // Re-tapping a reference into the book whose chapters are ALREADY open: assigning the
                // identical path is a structural no-op (the book screen's one-shot auto-open never
                // re-fires), which used to read as a dead tap. Point the reading column at the hadith
                // directly instead - identical-target re-taps still land via the selection's refresh
                // token (rebuild + re-scroll).
                if bookPath.last?.slug == reference.slug,
                   let book = HadithCatalogBook.bySlug[reference.slug],
                   let data = store.book(book),
                   let hadith = data.hadiths.first(where: { $0.idInBook == reference.idInBook }),
                   let chapter = data.chapters.first(where: { $0.id == hadith.chapterId }) {
                    HadithColumnSelection.shared.select(
                        book: book,
                        bookData: data,
                        chapter: chapter,
                        scrollToHadithId: reference.idInBook,
                        userInitiated: true
                    )
                    return
                }
                bookPath = [.book(slug: reference.slug, autoOpenHadithID: reference.idInBook)]
            }
            // Apple Music-style: the bottom search bar minimizes while scrolling down. On the List
            // itself, BEFORE the help overlay and the filter row join the tree: `onScrollGeometryChange`
            // watches every scroll view under it, and with the filter buttons (a horizontal ScrollView)
            // mounted for a search it logged "Multiple scroll views were found. Picking the first one"
            // on every scroll (the stress walk, 2026-10-13) and could end up watching the chips.
            .collapseBarsOnScroll($barsCollapsed)
            // The search help floats over the list top while the field is focused and empty.
            .overlay(alignment: .top) {
                searchHelpOverlay
                    .animation(.easeInOut, value: isHadithSearchFocused)
            }
            .confirmationDialog("Remove Quick Search Help?", isPresented: $confirmingSearchHelpRemoval,
                                titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { hadithSearchHelpRemoved = true }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your recent searches stay. You can bring the help back in Hadith Settings.")
            }
            // The filter buttons ride above the results while a search (or a filter) is live; applied
            // after the help card, so the card sits under the row.
            .adaptiveSafeArea(edge: .top, spacing: 0) {
                if isHadithSearchFocused || !searchText.isEmpty || searchFilters.hasSessionFilters {
                    HadithSearchFilterBar(filters: $searchFilters) { showSearchFilterSheet = true }
                        .background {
                            if #unavailable(iOS 26.0) {
                                Rectangle().fill(.bar).ignoresSafeArea(edges: .top)
                            }
                        }
                }
            }
            .sheet(isPresented: $showSearchFilterSheet) {
                HadithSearchFilterSheet(filters: $searchFilters)
                    .smallMediumSheetPresentation()
            }
            .adaptiveSafeArea(edge: .bottom) {
                // The Quran tab's exact bottom-bar grammar: just the field. (Recent searches used to
                // stack above it as chips; they live in the search-help card over the list now.)
                VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                    SearchBar(
                        // Animated like the Quran tab's bar, same gate: Low Power Mode / Reduce Motion
                        // keep typing free of animated whole-list diffs. The synchronous per-keystroke
                        // part here is only the ~20-book catalog filter; the async sweep results animate
                        // at their apply site.
                        text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                        onFocusChanged: { focused in
                            withAnimation { isHadithSearchFocused = focused }
                            // A persisted all-books index loads (off-main) the moment the field is
                            // focused, so it is usually ready before the first query. The cold
                            // GATHER + build waits for the first AI-eligible query (`runGlobalAISearch`):
                            // focusing a field must not start a 51k-hadith embedding.
                            if focused {
                                let engine = semanticEngine
                                Task { await HadithSemanticCorpus.probeDisk(engine: engine) }
                            }
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .minimizedBarStyle(barsCollapsed && !isHadithSearchFocused)
                }
                .background(Color.white.opacity(0.00001))
                // Same keyboard-transaction strip as the Quran tab's bottom bar: the keyboard supplies
                // the motion, so the bar tracks it instead of easing on its own colliding curve.
                .transaction { $0.animation = nil }
            }
            .navigationTitle("Al-Hadith")
            // Trailing buttons live in their own modifier so iOS 26 can interleave ToolbarSpacers
            // between them - without spacers, Liquid Glass merges them into ONE capsule (the same
            // treatment the Quran tab's trailing toolbar has).
            .modifier(HadithTrailingToolbar(
                hadithGridMode: $hadithGridMode,
                showHadithSettings: $showHadithSettings,
                listForJump: $listForJump,
                moreMenuItems: AnyView(moreMenuItems)
            ))
            .sheet(isPresented: $showHadithSettings) {
                SettingsHadithView()
                    .smallMediumSheetPresentation()
            }
            .sheet(isPresented: $showAskAI) {
                if #available(iOS 16.0, *) {
                    AskAIChatSheet(initialQuestion: searchText)
                }
            }
            .onAppear {
                // Back from the book a jump opened (or from another tab): the grid again.
                if listForJump { listForJump = false }
                store.loadLastRead()
                // An order or a Show choice changed inside a book or a chapter (their filter rows
                // share the preference) reaches this row when the tab comes back.
                searchFilters.adoptStoredPreferences()
                #if DEBUG
                // Headless visual verification (no tap access on the dev machine): land directly on a
                // given hadith, e.g. `-launchHadithOpen muslim:6846`. DEBUG builds only.
                if #available(iOS 16.0, *), bookPath.isEmpty,
                   let flagIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "-launchHadithOpen"),
                   ProcessInfo.processInfo.arguments.indices.contains(flagIndex + 1) {
                    let parts = ProcessInfo.processInfo.arguments[flagIndex + 1].split(separator: ":")
                    if parts.count == 2, let id = Int(parts[1]) {
                        bookPath = [.book(slug: String(parts[0]), autoOpenHadithID: id)]
                    }
                }
                // `-launchHadithEncyclopedia`: the Hadith Encyclopedia's door (pair with
                // `-hadeethEncOpen <id>` or `-hadeethEncSearch <term>` for what lies behind it).
                if ProcessInfo.processInfo.arguments.contains("-launchHadithEncyclopedia") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenEncyclopedia = true }
                }
                // `-launchHadithTopics` / `-launchHadithHistory`: the topic library and the history page.
                if ProcessInfo.processInfo.arguments.contains("-launchHadithTopics") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenTopics = true }
                }
                if ProcessInfo.processInfo.arguments.contains("-launchHadithHistory") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenHistory = true }
                }
                // `-launchHadithBook bukhari`: the book's chapter list itself, no chapter pushed.
                if #available(iOS 16.0, *), bookPath.isEmpty,
                   let flagIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "-launchHadithBook"),
                   ProcessInfo.processInfo.arguments.indices.contains(flagIndex + 1) {
                    bookPath = [.book(slug: ProcessInfo.processInfo.arguments[flagIndex + 1], autoOpenHadithID: nil)]
                }
                // `-hadithSearch <term>` runs the tab-wide search headlessly (typing isn't scriptable
                // in the simulator), on a delay so the search field and its onChange are mounted.
                if let flagIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "-hadithSearch"),
                   ProcessInfo.processInfo.arguments.indices.contains(flagIndex + 1) {
                    let term = ProcessInfo.processInfo.arguments[flagIndex + 1]
                    // `-hadithSearchLimit N` sets the first hadith page size; `-hadithLoadMore` taps
                    // Load More (+5) once the first page has landed - the cursor check.
                    if let limitIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "-hadithSearchLimit"),
                       ProcessInfo.processInfo.arguments.indices.contains(limitIndex + 1),
                       let limit = Int(ProcessInfo.processInfo.arguments[limitIndex + 1]) {
                        // After the onChange reset: raise the page and restart the (debounced) sweep.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                            globalHadithLimit = limit
                            runGlobalSearch(query: term)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { searchText = term }
                    if ProcessInfo.processInfo.arguments.contains("-hadithLoadMore") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                            globalHadithLimit += 5
                            runGlobalSearch(query: term, loadMore: true)
                        }
                    }
                }
                // Same rule for the settings sheet: `-launchHadithSettings` presents it directly,
                // and `-launchHadithSettingsReading` lands on its Reading View subpage.
                if ProcessInfo.processInfo.arguments.contains(where: {
                    $0 == "-launchHadithSettings" || $0 == "-launchHadithSettingsReading"
                }) {
                    // After the reveal AND the warm walk, like a real tap, and once: this onAppear
                    // runs on every visit of the under-cover tab walk, and a slow launch can lift the
                    // cover (it has a time cap) while the walk still has another tab selected, which
                    // logged "A sheet was presented but its presenter is not yet in the window"
                    // (Quality Guide G12).
                    if !Self.debugSettingsHookScheduled {
                        Self.debugSettingsHookScheduled = true
                        Task { @MainActor in
                            await AppReveal.waitUntilRevealed()
                            await LaunchWarmup.shared.waitUntilWarm(maxWaitNanos: 10_000_000_000)
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            showHadithSettings = true
                        }
                    }
                }
                #endif
            }
            .task {
                // Usually a no-op: the pick was resolved at app launch. This just covers day rollover
                // while the app stays open.
                store.prepareDailyHadith()
                // The 17-book shelf sweep and the cross-language lexicon are the app root's post-reveal
                // work (Al-IslamApp's schedule), not this tab's: the under-cover tab walk realizes this
                // view too, and both used to start here, inside the launch window, un-gated.
            }
            .onChange(of: searchText) { text in
                // Newly TYPED text starts back on the AI list. Here and not inside `restartSearch`:
                // a filter change re-runs the SAME words, and resetting there threw the reader off
                // Keyword Results every time they flipped Sahih or All Words.
                showHadithKeywordResults = Self.opensOnKeywordResults
                restartSearch(text)
            }
            // A filter is a new question about the same words: the whole fan-out runs again.
            .onChange(of: searchFilters) { filters in
                filters.persistPreferences()
                restartSearch(searchText)
            }
            // A corpus finishing its build mid-query (from a book view) surfaces here immediately.
            .onChange(of: semanticEngine.readyCorpora) { _ in
                runGlobalAISearch(query: searchText)
            }
            .onChange(of: pendingScrollToBookSlug) { slug in
                guard let slug else { return }
                pendingScrollToBookSlug = nil
                // Grid tiles carry no scroll ids (the Quran list has the same rule), so this visit
                // shows the list, the stored choice untouched; and clear the search so the catalog
                // rows exist, then land on the book.
                if showsGrid { listForJump = true }
                withAnimation { searchText = "" }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { scrollProxy.scrollTo("hadith-book-\(slug)", anchor: .top) }
                }
            }
        }
    }

    // MARK: Hadith of the Day (engine lives in HadithStore; resolved before this tab opens)

    private var dailyHistory: [HadithStore.DailyHadithEntry] { HadithStore.loadDailyHistory() }


    /// One unfolded row under the summary grid: an earlier Hadith of the Day, or where a book was
    /// left. `isToday` adds the shuffle and today's menu (the Ayah of the Day history row's).
    private func summaryHistoryRow(slug: String, idInBook: Int, reference: String, arabic: String, english: String,
                                   date: Date, dimmed: Bool, isToday: Bool = false) -> some View {
        HStack(spacing: 8) {
            Button {
                settings.hapticFeedback()
                pushedReference = HadithBookmark(slug: slug, idInBook: idInBook, reference: "", preview: english)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    // The timestamp lives ONLY here, in the expanded (+) rows - top-left, above the
                    // reference pill. The compact tiles stay clean.
                    historyTimestampLabel(date)

                    Text(reference)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)

                    // Each visible language reserves its own two lines whether or not this entry HAS
                    // that language - an empty string still reserves them - so a hadith with no
                    // Arabic, or none translated, keeps the same row height as one carrying both.
                    // Giving the surviving language four lines instead does NOT square them: four
                    // Arabic lines are taller than two Arabic plus two English, and four English
                    // lines are shorter, so those rows sat proud of or below their neighbours.
                    // The toggles gate the slots, not the content, because a toggle applies to every
                    // row at once and so cannot make the list ragged.
                    if settings.showHadithArabic {
                        HadithArabicPreview(text: arabic, lineLimit: 2)
                    }

                    if settings.showHadithEnglish {
                        Text(english)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .reservedLineLimit(2)
                            // English content keeps the left edge in the Arabic interface.
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .leftToRightContent()
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isToday {
                Image(systemName: "shuffle")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: SectionPillHeader.pillHeight, height: SectionPillHeader.pillHeight)
                    .conditionalGlassEffect(circle: true)
                    .onTapGesture {
                        settings.hapticFeedback()
                        Task { await store.shuffleDailyHadith() }
                    }
                    .accessibilityLabel("Pick a random hadith of the day")
            }
        }
        .padding(.vertical, 2)
        // Same dimming the Quran tab gives its unfolded history, so "current" reads brighter.
        .opacity(dimmed ? 0.75 : 1)
        // Today's row carries the tile's menu (the Ayah of the Day history row does the same).
        .contextMenu {
            if isToday, let pick = store.daily {
                dailyMenuItems(pick)
            }
        }
    }

    // MARK: Summary tiles + last read

    /// Compact "summary mode", the Quran tab's pattern: Hadith of the Day and Last Read as two tappable
    /// tiles in one section. On by default; the full rows return when it's off (Hadith settings).
    @ViewBuilder
    private var summaryTilesSection: some View {
        // The Quran tab's header, to the letter: the accent icon header, the Today pill at the
        // trailing edge, the two dropping onto separate lines where they do not fit (an iPad sidebar
        // broke it into "YOUR / SUM- / MARY" beside "To- / da / y"). Simple Mode keeps the tiles alone:
        // Today moves into the More menu, and the history expanders step aside
        // (Docs/Product/Simple Mode Guide.md).
        let expandersHidden = settings.hides(.historyExpanders)
        Section(header:
            SectionHeaderLine(String(localized: "YOUR SUMMARY"), icon: "sparkles", accentTitle: true,
                              forceStacked: dynamicTypeSize.isAccessibilitySize) {
                // Everything of the day on one screen (2026-09-16): the door every daily card carries.
                if !settings.hides(.hadithTodayPill) {
                    NavigationLink(destination: LazyDestination { DailyHubView() }) {
                        DailyHubDoorLabel()
                    }
                    .buttonStyle(.plain)
                }
            }
        ) {
            // The grid only when there is something in it: an empty grid would still draw its own
            // padded row.
            if showSummaryTiles {
                // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different height
                // on each self-sizing pass, which iOS 26 traps on.
                SummaryTileGrid(columns: 2) {
                    if let dailyHadith {
                        // The Ayah of the Day tile's long-press menu (Hide for Today, Delete Forever,
                        // then the hadith's own actions) - a GridTileMenu, like every other grid tile.
                        GridTileMenu(primaryAction: {
                            settings.hapticFeedback()
                            pushedReference = HadithBookmark(
                                slug: dailyHadith.book.slug, idInBook: dailyHadith.hadith.idInBook,
                                reference: "", preview: ""
                            )
                        }) {
                            dailyMenuItems(dailyHadith)
                        } label: {
                            summaryTileLabel(
                                title: String(localized: "Hadith of the Day"),
                                icon: "sparkles",
                                reference: dailyHadith.book.displayReference(dailyHadith.hadith.displayNumber),
                                // The previews were captured when the pick was made - the tile never touches a pack.
                                arabic: settings.showHadithArabic ? dailyHadith.arabicPreview : "",
                                english: settings.showHadithEnglish ? dailyHadith.englishPreview : "",
                                isExpanded: summaryHistoryExpansion == .daily,
                                onExpand: expandersHidden || dailyHistory.isEmpty ? nil : { toggleSummaryExpansion(.daily) }
                            )
                        }
                        .confirmationDialog("Are you sure?", isPresented: $confirmDeleteDailyForever, titleVisibility: .visible) {
                            Button("Remove Permanently", role: .destructive) {
                                settings.hapticFeedback()
                                withAnimation { settings.showHadithOfTheDay = false }
                            }
                            Button("Cancel") {}
                        } message: {
                            Text("You can re-enable Hadith of the Day later in Hadith Settings.")
                        }
                    }

                    if let lastRead = store.lastRead {
                        summaryTile(
                            title: String(localized: "Last Read Hadith"),
                            icon: "book",
                            reference: lastRead.displayReference,
                            arabic: settings.showHadithArabic ? lastRead.arabicPreview : "",
                            english: settings.showHadithEnglish ? lastRead.englishPreview : "",
                            isExpanded: summaryHistoryExpansion == .leftOff,
                            // Where every other book was left: only once a second book has a position.
                            onExpand: expandersHidden || leftOffEntries.count < 2 ? nil : { toggleSummaryExpansion(.leftOff) }
                        ) {
                            pushedReference = HadithBookmark(
                                slug: lastRead.slug, idInBook: lastRead.idInBook,
                                reference: lastRead.reference, preview: ""
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // The one open expansion, unfolded as plain rows right under the tiles (the Quran tab's
            // `summaryHistoryRows`). "Today" and the current book keep full brightness: they ARE the
            // tile's own hadith, not history.
            if !expandersHidden, let kind = summaryHistoryExpansion {
                switch kind {
                case .daily:
                    ForEach(Array(dailyHistory.enumerated()), id: \.element.dayKey) { index, entry in
                        summaryHistoryRow(
                            slug: entry.slug, idInBook: entry.idInBook,
                            reference: HadithCatalogBook.displayReference(stored: entry.reference, slug: entry.slug),
                            arabic: entry.arabicPreview, english: entry.englishPreview, date: entry.date,
                            dimmed: index != 0, isToday: index == 0
                        )
                        .transition(.opacity)
                    }
                case .leftOff:
                    ForEach(leftOffEntries, id: \.slug) { entry in
                        summaryHistoryRow(
                            slug: entry.slug, idInBook: entry.idInBook, reference: entry.displayReference,
                            arabic: entry.arabicPreview, english: entry.englishPreview, date: entry.timestamp,
                            dimmed: entry.slug != store.lastRead?.slug
                        )
                        .transition(.opacity)
                    }
                }
            }
        }
    }

    /// Whether there is anything to put in the tile grid at all; the section renders only then.
    private var showSummaryTiles: Bool {
        dailyHadith != nil || store.lastRead != nil
    }

    private func summaryTile(title: String, icon: String, reference: String, arabic: String, english: String,
                             isExpanded: Bool = false, onExpand: (() -> Void)? = nil, onTap: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            onTap()
        } label: {
            summaryTileLabel(title: title, icon: icon, reference: reference, arabic: arabic, english: english,
                             isExpanded: isExpanded, onExpand: onExpand)
        }
        .buttonStyle(.plain)
    }

    /// The Ayah of the Day card's own items, for the hadith: Hide for Today and Delete Forever lead
    /// (destructive, then a divider), then the shuffle the today row already offers, and the bookmark.
    @ViewBuilder
    private func dailyMenuItems(_ pick: HadithStore.DailyPick) -> some View {
        Text(pick.book.displayReference(pick.hadith.displayNumber))
            .foregroundStyle(.secondary)

        Button(role: .destructive) {
            settings.hapticFeedback()
            withAnimation { settings.hadithOfTheDayHiddenDate = settings.dailyDayKey() }
        } label: { Label("Hide for Today", systemImage: "eye.slash") }

        Button(role: .destructive) {
            settings.hapticFeedback()
            confirmDeleteDailyForever = true
        } label: { Label("Delete Forever", systemImage: "trash") }

        Divider()

        let bookmarked = HadithUserData.shared.isBookmarked(slug: pick.book.slug, idInBook: pick.hadith.idInBook)
        Button(role: bookmarked ? .destructive : nil) {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                HadithUserData.shared.toggleBookmarkOrConfirm(book: pick.book, hadith: pick.hadith)
            }
        } label: {
            Label(bookmarked ? "Remove Bookmark" : "Bookmark Hadith", systemImage: bookmarked ? "bookmark.fill" : "bookmark")
        }

        Button {
            settings.hapticFeedback()
            Task { await store.shuffleDailyHadith() }
        } label: { Label("Pick a Random Hadith", systemImage: "shuffle") }
    }

    /// `onExpand` grows the Quran tile's small +/- in the corner, which unfolds this tile's recents
    /// under the grid (`summaryHistoryExpansion`).
    private func summaryTileLabel(title: String, icon: String, reference: String, arabic: String, english: String,
                                  isExpanded: Bool = false, onExpand: (() -> Void)? = nil) -> some View {
            // Tight on purpose (Abu, 2026-09-16), the Quran tab's tiles' exact grammar: 4 pt between
            // lines, 10 pt of padding, one line of each script, a small chip for the icon.
            // LEADING, unlike the short-label tiles elsewhere in the app, which centre (Abu,
            // 2026-10-05: "summary tiles and hadiths/ayahs should be leading everything else
            // centered"). These tiles carry PROSE - a narration's opening, a translation - and a
            // straight left edge is what you read down; a centred paragraph ragged on both sides is
            // not. The Arabic keeps its own RTL side.
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    AccentIconChip(systemImage: icon, size: 18)
                    // The label in the quiet glass tone, the reference in the accent, as on the Quran
                    // tab's tiles (2026-09-27): all accent read as one block with no hierarchy.
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondaryOnGlass)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .layoutPriority(1)

                    if let onExpand {
                        Spacer(minLength: 0)

                        Image(systemName: isExpanded ? "minus.circle" : "plus.circle")
                            .font(.caption)
                            .foregroundColor(settings.accentColor.color)
                            .contentShape(Rectangle().inset(by: -8))
                            .onTapGesture {
                                settings.hapticFeedback()
                                onExpand()
                            }
                            .accessibilityLabel("Show recent \(title)")
                    }
                }

                Text(reference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                // Each visible language reserves its own two lines whether or not this hadith HAS
                // that language - an empty string still reserves them - so the two tiles sitting
                // side by side in the grid are the same height even when one has no Arabic or no
                // translation. Giving the surviving language four lines instead does NOT square
                // them: four Arabic lines are taller than two Arabic plus two English, and four
                // English lines are shorter. The toggles gate the slots, not the content, because a
                // toggle applies to both tiles at once and so cannot make them ragged.
                if settings.showHadithArabic {
                    HadithArabicPreview(text: arabic, lineLimit: 1)
                }

                if settings.showHadithEnglish {
                    Text(english)
                        .font(.caption)
                        .foregroundColor(.secondaryOnGlass)
                        .reservedLineLimit(1)
                        // The narration's English keeps the left edge in the Arabic interface, like
                        // the Quran tab's ayah tile.
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .leftToRightContent()
                }
            }
            // Hug the content - stretching to fill the row's height (maxHeight + a Spacer) parked
            // all the slack as dead space under the English line.
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .conditionalGlassEffect(clear: true, rectangle: true)
            .contentShape(Rectangle())
    }


    // MARK: The summary's doors

    /// The screens the summary opens through one `@State` + one destination (`openDoor`,
    /// `summaryDoorDestination`), so exactly one screen opens. Topics, the Encyclopedia and History
    /// were three chips under the summary tiles from 2026-09-07 to 2026-10-11 (one row from
    /// 2026-09-16); they are items of the ⋯ More menu now, in both modes (Abu: "put these top left no
    /// matter simple or normal and remove it from summary"). The one-destination plumbing is older
    /// than the menu: a NavigationLink activates with EVERY other link in the same List row, so three
    /// links in one row pushed all three at once (Abu, 2026-09-19).
    enum SummaryDoor: String, Identifiable, Hashable {
        /// `daily` is the Today screen: Full Mode opens it from the summary header's pill, Simple Mode
        /// from the More menu (a toolbar menu cannot hold a NavigationLink).
        case topics, encyclopedia, history, daily
        /// The "About Hadith & the Sunnah" cards, which share the same one-destination plumbing: the two
        /// pillar screens, then (2026-09-29) the Hadith & Its Sciences group of Pillars & Beliefs.
        case sunnah, hadithPillar, hadithSciences, hadithPreservation, hadithRejectors
        var id: String { rawValue }
    }

    /// A tile's book push still on its way (request set, or the path already non-empty): a door raised
    /// now would be a second push on the same stack in the same frame, so the door tap is dropped.
    private var bookPushInFlight: Bool {
        pushedBook != nil || pushedReference != nil || !bookPath.isEmpty
    }

    /// One "About Hadith" card: a Button through the summary's one door, not a NavigationLink (see
    /// `SummaryDoor`).
    private func aboutDoorRow(_ title: String, systemImage: String, door: SummaryDoor) -> some View {
        Button {
            guard !bookPushInFlight else { return }
            settings.hapticFeedback()
            openDoor = door
        } label: {
            SettingsRowLabel(title: title, systemImage: systemImage, showsChevron: true)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// The tab's ⋯ More menu (Docs/Product/Simple Mode Guide.md), the same in both modes: the Today pill, then
    /// Topics, the Encyclopedia and History (this menu is their only door since 2026-10-11), then the
    /// grid. Each item raises its door through the one guard.
    @ViewBuilder
    var moreMenuItems: some View {
        menuDoor(.daily, title: String(localized: "Today"), systemImage: "sun.horizon.fill")
        if HadithTopicsStore.isBundled {
            menuDoor(.topics, title: String(localized: "Topics"), systemImage: "tag.fill")
        }
        if HadeethEncStore.isBundled {
            menuDoor(.encyclopedia, title: String(localized: "Encyclopedia"), systemImage: "books.vertical.fill")
        }
        menuDoor(.history, title: String(localized: "History"), systemImage: "clock.arrow.circlepath")

        Divider()

        let showsGrid = hadithGridMode && !listForJump
        TabMoreMenuItem(showsGrid ? String(localized: "Show as List") : String(localized: "Show as Grid"), systemImage: showsGrid ? "list.bullet" : "square.grid.2x2") {
            settings.hapticFeedback()
            withAnimation {
                if listForJump { listForJump = false } else { hadithGridMode.toggle() }
            }
        }
    }

    private func menuDoor(_ door: SummaryDoor, title: String, systemImage: String) -> some View {
        TabMoreMenuItem(title, systemImage: systemImage) {
            guard !bookPushInFlight else { return }
            settings.hapticFeedback()
            openDoor = door
        }
    }

    /// The destination for `openDoor`, attached to the LIST (a lazy row's own destination never
    /// fires - the same rule `PushDestination` documents).
    @ViewBuilder
    var summaryDoorDestination: some View {
        switch openDoor {
        case .topics:       HadithTopicsView()
        case .encyclopedia: HadeethEncView()
        case .history:      HadithHistoryView()
        case .daily:        LazyDestination { DailyHubView() }
        case .sunnah:       SunnahPillarView()
        case .hadithPillar: HadithPillarView()
        case .hadithSciences:     HadithSciencesView()
        case .hadithPreservation: HadithPreservationView()
        case .hadithRejectors:    HadithRejectorsView()
        case .none:         EmptyView()
        }
    }

    // MARK: About hadith

    /// One polished orientation card: the two pillar screens as proper links on a glass card, with the
    /// pointer to where the full teachings live.
    /// The Islam tab's five pages about the Sunnah, as a section of the tab root (an icon header,
    /// a door row each, the pointer as the footer). Until 2026-10-26 it was one List row holding
    /// five glass cards under a hand-drawn accent title, the only section of the root in its own
    /// grammar. BUTTONS, not links: each pushes through `openDoor` and the List's one destination,
    /// since a NavigationLink activates with every other link in its row (2026-09-19 audit), and a
    /// row of its own per door keeps the rows pressable.
    private var aboutHadithSection: some View {
        Section(header: SectionIconHeader(String(localized: "ABOUT HADITH & THE SUNNAH"), icon: "text.book.closed.fill"),
                footer: Text("Learn more under Al-Islam → Pillars and Beliefs.")) {
            aboutDoorRow(String(localized: "What is the Sunnah?"), systemImage: "sun.max.fill", door: .sunnah)
            aboutDoorRow(String(localized: "What are Hadiths?"), systemImage: "text.quote", door: .hadithPillar)
            aboutDoorRow(String(localized: "The Sciences of Hadith"), systemImage: "graduationcap.fill", door: .hadithSciences)
            aboutDoorRow(String(localized: "How the Hadith Were Preserved"), systemImage: "archivebox.fill", door: .hadithPreservation)
            aboutDoorRow(String(localized: "Answering the Hadith Rejectors"), systemImage: "checkmark.shield.fill", door: .hadithRejectors)
        }
    }

    // MARK: Reference lookup

    @ViewBuilder
    private func referenceSection(_ reference: HadithReferenceParser.Reference) -> some View {
        referenceHadithSection(reference)

        // "Bukhari 15" can also mean the book's fifteenth chapter, so offer that door under the
        // hadith (Abu, 2026-09-21). "Bukhari 1:4" and "Muslim 8a" name one hadith and nothing else.
        if reference.chapter == nil, reference.suffix == nil, !reference.introduction,
           let data = HadithStore.shared.book(reference.book),
           let chapter = data.chapter(atPosition: reference.hadith) {
            Section(header: Text("CHAPTER \(reference.hadith)")) {
                NavigationLink {
                    LazyDestination {
                        HadithChapterView(book: reference.book, bookData: data, chapter: chapter)
                    }
                } label: {
                    globalChapterRow(GlobalChapterHit(book: reference.book, data: data, chapter: chapter))
                }
            }
        }
    }

    private func referenceHadithSection(_ reference: HadithReferenceParser.Reference) -> some View {
        Section(header: Text("GO TO REFERENCE")) {
            // The reference names ONE hadith - show that hadith in full, exactly like a keyword
            // match, instead of a bare "go to" stub. Resolution mirrors HadithReferenceView; the
            // pack is mapped, not read, so the body-path open is cheap. No `searchText` on the row:
            // the number is the row's identity, not a text match (the BY NUMBER sections' rule).
            if let data = HadithStore.shared.book(reference.book),
               let resolved = resolvedReferenceHadith(reference, data: data) {
                NavigationLink {
                    LazyDestination {
                        // Land in the chapter, scrolled to the hadith - the keyword matches' arrival.
                        if let chapter = data.chapters.first(where: { $0.id == resolved.chapterId }) {
                            HadithChapterView(book: reference.book, bookData: data, chapter: chapter, scrollToHadithId: resolved.idInBook)
                        } else {
                            HadithReferenceView(book: reference.book, chapter: reference.chapter, hadith: reference.hadith, suffix: reference.suffix, introduction: reference.introduction)
                        }
                    }
                } label: {
                    HadithRow(book: reference.book, hadith: resolved, compact: true).equatable()
                }
            } else {
                // Unresolvable number: keep the plain jump row - HadithReferenceView explains.
                NavigationLink {
                    LazyDestination {
                        HadithReferenceView(book: reference.book, chapter: reference.chapter, hadith: reference.hadith, suffix: reference.suffix, introduction: reference.introduction)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "number")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(reference.chapter.map { "\(reference.book.displayTitle) - Chapter \($0), Hadith \(reference.hadith)" }
                                 ?? "\(reference.book.displayTitle) - \(reference.introduction ? String(localized: "Introduction") + " " : String(localized: "Hadith") + " ")\(reference.hadith)\(reference.suffix ?? "")")
                                .font(.subheadline.weight(.semibold))

                            // The Arabic interface names the book once, in the line above.
                            if !AppLanguage.isArabicScript {
                                Text(reference.book.arabicTitle)
                                    .font(.caption)
                                    .foregroundColor(settings.accentColor.color)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    /// "book N" resolves the hadith CITED N (standard sunnah.com numbering, falling back to the
    /// internal row number); "book C:N" the Nth hadith of chapter C - the exact rule
    /// `HadithReferenceView.resolved` applies, lifted here so the search list can show the full
    /// hadith row for a reference query.
    private func resolvedReferenceHadith(_ reference: HadithReferenceParser.Reference, data: HadithBookData) -> HadithBookData.Hadith? {
        if let chapter = reference.chapter {
            return data.hadith(chapterPosition: chapter, position: reference.hadith)
        }
        return data.hadith(referenced: reference.hadith, suffix: reference.suffix, introduction: reference.introduction)
    }

    // MARK: All-books search

    /// A bare number ("10") lists the chapter numbered 10 and the hadith numbered 10 (Bukhari 10, Muslim
    /// 10, …) from every book, in two sections reusing the keyword-search layout. The text
    /// sweep is suppressed for a number query - the numbered chapter/hadith is what "10" means.
    @ViewBuilder
    private var globalNumberSection: some View {
        if let citation = citationQuery {
            let number = citation.base
            let citedLabel = "\(number)\(citation.suffix ?? "")"
            // Chapters numbered N - one flat section (each `globalChapterRow` names its own book).
            if !globalNumberChapters.isEmpty {
                Section(header: SectionPillHeader(title: String(localized: "CHAPTER \(number)"), count: globalNumberChapters.count, icon: "book.closed")) {
                    ForEach(globalNumberChapters) { hit in
                        NavigationLink {
                            LazyDestination {
                                HadithChapterView(book: hit.book, bookData: hit.data, chapter: hit.chapter)
                            }
                        } label: {
                            globalChapterRow(hit)
                        }
                    }
                }
            }

            // Hadiths cited N - one flat section; each compact `HadithRow` shows its own "10 <book>"
            // citation, so no per-book grouping is needed.
            if !globalNumberHadiths.isEmpty {
                Section(header: SectionPillHeader(title: String(localized: "HADITH \(HadithDigits.display(citedLabel))"), count: globalNumberHadiths.count, icon: "number")) {
                    ForEach(globalNumberHadiths) { hit in
                        NavigationLink {
                            LazyDestination {
                                if let chapter = hit.data.chapters.first(where: { $0.id == hit.hadith.chapterId }) {
                                    HadithChapterView(book: hit.book, bookData: hit.data, chapter: chapter, scrollToHadithId: hit.hadith.idInBook)
                                } else {
                                    HadithReferenceView(book: hit.book, resolved: hit.hadith)
                                }
                            }
                        } label: {
                            HadithRow(book: hit.book, hadith: hit.hadith, searchText: searchText, compact: true).equatable()
                        }
                    }
                }
            }

            if isNumberSearching, globalNumberChapters.isEmpty, globalNumberHadiths.isEmpty {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Searching every collection...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !isNumberSearching, numberSearchRanFor == number,
               globalNumberChapters.isEmpty, globalNumberHadiths.isEmpty {
                Section(footer: Text("Searches every collection in the app.")) {
                    Text("No chapter or hadith is numbered \(HadithDigits.display(citedLabel)) in any collection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var globalSearchSection: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.count >= 3, referenceResult == nil, numberQuery == nil {
            // Ask AI first - ALWAYS present while searching, results or none: the ask is an
            // invitation, not a result. It opens the chat with this query as its first question.
            if OnDeviceAsk.isAvailable, searchFilters.shows(.ai) {
                Section(header: hadithAskAIHeader) {
                    hadithAskPromptRow
                }
            }

            // While the one-time all-books index builds, the standard progress row shows in its place.
            if SemanticSearchEngine.isSupported, searchFilters.shows(.ai), !query.containsArabicScript,
               !semanticEngine.isReady(allBooksCorpusID),
               isGatheringAllBooks || HadithSemanticCorpus.isGathering || semanticEngine.isBuilding(allBooksCorpusID) {
                Section { AISearchStatusRow(corpusID: allBooksCorpusID, failed: false) }
            }

            // Matching chapters sit ABOVE the AI/keyword switch, the Quran search's surah-list rule:
            // they are navigation, not a competing result kind, so they show in both modes.
            if !globalChapterResults.isEmpty {
                Section(header: SectionPillHeader(title: String(localized: "MATCHING CHAPTERS"), count: globalChapterResults.count, icon: "magnifyingglass", overflow: globalHasMoreChapters)) {
                    ForEach(globalChapterResults) { hit in
                        NavigationLink {
                            LazyDestination {
                                HadithChapterView(book: hit.book, bookData: hit.data, chapter: hit.chapter)
                            }
                        } label: {
                            globalChapterRow(hit)
                        }
                    }

                    HadithLoadMoreControls(label: String(localized: "chapter matches"), hasMore: globalHasMoreChapters, limit: Binding(
                        get: { globalChapterLimit },
                        set: { newValue in
                            globalChapterLimit = newValue
                            // Every chapter hit is already known: a longer prefix, no rescan.
                            globalChapterResults = Array(globalAllChapterHits.prefix(newValue))
                            globalHasMoreChapters = globalAllChapterHits.count > newValue
                        }
                    ))
                }
            }

            // Both HADITH result kinds landed: ONE segmented switch decides which list fills the page
            // - the AI's ranked meaning matches or the exhaustive keyword list - never both stacked.
            // With only one kind present there is nothing to choose, so no picker (the Quran's rule).
            let showResultsPicker = !globalAIResults.isEmpty && (!globalHadithResults.isEmpty || !globalRankedHits.isEmpty)
            if showResultsPicker {
                Section {
                    Picker("Results", selection: $showHadithKeywordResults) {
                        Text("AI Results").tag(false)
                        Text("Keyword Results").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
            let keywordVisible = !showResultsPicker || showHadithKeywordResults

            if !globalAIResults.isEmpty, !showResultsPicker || !showHadithKeywordResults {
                // The keyword matches' grammar for the semantic list too: the sparkles TOTAL pill up
                // top, then one section per book with its own count - AI matches from different books
                // never read as one undifferentiated list.
                Section(header: SectionPillHeader(title: String(localized: "AI MATCHES"), count: globalAIResults.count, icon: "sparkles")) {
                    EmptyView()
                }
                .padding(.bottom, -12)

                ForEach(globalAIResultsGroupedByBook, id: \.book.slug) { group in
                    Section(header: bookSearchSectionHeader(book: group.book, matchCount: group.hits.count)) {
                        ForEach(group.hits) { hit in
                            NavigationLink {
                                LazyDestination {
                                    if let chapter = hit.data.chapters.first(where: { $0.id == hit.hadith.chapterId }) {
                                        HadithChapterView(book: hit.book, bookData: hit.data, chapter: chapter, scrollToHadithId: hit.hadith.idInBook)
                                    } else {
                                        HadithReferenceView(book: hit.book, resolved: hit.hadith)
                                    }
                                }
                            } label: {
                                HadithRow(book: hit.book, hadith: hit.hadith, searchText: searchText, compact: true).equatable()
                            }
                        }
                    }
                }
            }

            if isGlobalSearching && globalChapterResults.isEmpty && globalHadithResults.isEmpty {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Searching every collection...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // The ranked lane above the book-ordered list, when it adds something the list does not: an
            // order (more matches than the page shows), a correction, a partial match, or matches the
            // exact sweep could not reach at all (a stem, a typo, words that do not touch).
            // Best Match (the filter row's order): the ranked list IS the hadith list, always shown,
            // and the book-ordered sweep under it stands down.
            let bestMatch = searchFilters.sort == .relevance && !globalRankedHits.isEmpty
            let rankedRows = bestMatch ? globalRankedHits.map { RankedHadithRow(hit: $0) } : rankedHadithSectionRows
            if keywordVisible, !rankedRows.isEmpty {
                // The pill counts what can be reached (the engine keeps its best forty), with a + when
                // more matched than that: it used to print the whole tally over forty rows.
                Section(header: SectionPillHeader(title: bestMatch ? String(localized: "HADITHS BY BEST MATCH") : String(localized: "TOP HADITH RESULTS"),
                                                  count: rankedRows.count, icon: "magnifyingglass",
                                                  overflow: globalRankedTotal > rankedRows.count)) {
                    rankedHadithNotice
                    ForEach(rankedRows.prefix(globalRankedLimit)) { row in
                        let hit = row.hit
                        NavigationLink {
                            LazyDestination {
                                if let chapter = hit.data.chapters.first(where: { $0.id == hit.hadith.chapterId }) {
                                    HadithChapterView(book: hit.book, bookData: hit.data, chapter: chapter, scrollToHadithId: hit.hadith.idInBook)
                                } else {
                                    HadithReferenceView(book: hit.book, resolved: hit.hadith)
                                }
                            }
                        } label: {
                            // The ranked rows paint the words the engine matched (a corrected spelling,
                            // say), or a corrected hit would show no highlight at all.
                            HadithRow(book: hit.book, hadith: hit.hadith,
                                      searchText: globalRankedHighlight.isEmpty ? searchText : globalRankedHighlight,
                                      compact: true).equatable()
                        }
                    }
                    if rankedRows.count > globalRankedLimit {
                        Button {
                            settings.hapticFeedback()
                            globalRankedLimit += 6
                        } label: {
                            Text("Show \(min(6, rankedRows.count - globalRankedLimit)) more")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .foregroundColor(settings.accentColor.color)
                    }
                }
            }

            if keywordVisible, !bestMatch, !globalHadithResults.isEmpty {
                // The Quran search's grammar: the TOTAL pill up top, then one section per book with its
                // own count - so results from different books never read as one undifferentiated list.
                Section(header: SectionPillHeader(title: String(localized: "MATCHING HADITHS"), count: globalHadithResults.count, icon: "magnifyingglass", overflow: globalHasMoreHadiths)) {
                    EmptyView()
                }
                .padding(.bottom, -12)

                ForEach(globalHadithResultsGroupedByBook, id: \.book.slug) { group in
                    Section(header: bookSearchSectionHeader(book: group.book, matchCount: group.hits.count)) {
                        ForEach(group.hits) { hit in
                            NavigationLink {
                                LazyDestination {
                                    // Land in the chapter, scrolled to the hadith - the Quran search's arrival.
                                    if let chapter = hit.data.chapters.first(where: { $0.id == hit.hadith.chapterId }) {
                                        HadithChapterView(book: hit.book, bookData: hit.data, chapter: chapter, scrollToHadithId: hit.hadith.idInBook)
                                    } else {
                                        HadithReferenceView(book: hit.book, resolved: hit.hadith)
                                    }
                                }
                            } label: {
                                HadithRow(book: hit.book, hadith: hit.hadith, searchText: searchText, compact: true).equatable()
                            }
                        }
                    }
                }

                Section {
                    HadithLoadMoreControls(label: String(localized: "hadith matches"), hasMore: globalHasMoreHadiths, limit: Binding(
                        get: { globalHadithLimit },
                        set: { newValue in
                            globalHadithLimit = newValue
                            runGlobalSearch(query: query, loadMore: true)
                        }
                    ))
                }
            }

            if !isGlobalSearching, globalSearchRanFor == query,
               globalChapterResults.isEmpty, globalHadithResults.isEmpty, globalRankedHits.isEmpty {
                Section(footer: Text(searchFilters.hasSessionFilters
                                     ? "The filters above narrow this search. Reset them to search every collection."
                                     : "Searches every collection in the app.")) {
                    Text(searchFilters.hasSessionFilters ? "No chapter or hadith matches with these filters."
                                                         : "No chapter or hadith matches in any collection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// "ASK AI" with the sparkles glyph - the Quran search's `askAIHeader`, verbatim.
    private var hadithAskAIHeader: some View {
        SectionIconHeader(String(localized: "ASK AI"), icon: "sparkles")
    }

    /// The one-tap Ask entry: press to open the Ask AI chat with exactly what's typed as its first
    /// question - the Quran search's row, verbatim.
    private var hadithAskPromptRow: some View {
        Button {
            settings.hapticFeedback()
            showAskAI = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)

                Text("Ask AI about \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                    .font(.caption.weight(.semibold))

                Spacer()

                Image(systemName: "chevron.forward")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundColor(settings.accentColor.color)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .conditionalGlassEffect(clear: true, rectangle: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Hadith matches bucketed per book, preserving the result order - the Quran search's
    /// `verseHitsGroupedBySurah`, for books.
    /// The ranked rows worth a section of their own (see the section comment in the results list).
    private var rankedHadithSectionRows: [RankedHadithRow] {
        guard !globalRankedHits.isEmpty else { return [] }
        let all = globalRankedHits.map { RankedHadithRow(hit: $0) }
        if globalHadithResults.isEmpty || globalRankedRelaxed || !globalRankedCorrections.isEmpty { return all }
        if globalRankedTotal > globalHadithResults.count { return all }
        let shown = Set(globalHadithResults.prefix(globalRankedHits.count).map(\.id))
        return Set(globalRankedHits.map(\.id)) == shown ? [] : all
    }

    /// One line above the ranked results saying what was searched for when it was not what was typed.
    @ViewBuilder
    private var rankedHadithNotice: some View {
        if !globalRankedCorrections.isEmpty {
            let to = globalRankedCorrections.quotedWords(\.to)
            let from = globalRankedCorrections.quotedWords(\.from)
            Text("Showing results for \(to) instead of \(from).")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if globalRankedRelaxed {
            Text("No hadith carries every word. These carry the most of them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var globalHadithResultsGroupedByBook: [(book: HadithCatalogBook, hits: [GlobalHadithHit])] {
        var order: [String] = []
        var byBook: [String: [GlobalHadithHit]] = [:]
        for hit in globalHadithResults {
            if byBook[hit.book.slug] == nil { order.append(hit.book.slug) }
            byBook[hit.book.slug, default: []].append(hit)
        }
        return order.compactMap { slug in
            guard let hits = byBook[slug], let book = hits.first?.book else { return nil }
            return (book, hits)
        }
    }

    /// The AI matches bucketed per book, in first-appearance (relevance) order - the keyword results'
    /// `globalHadithResultsGroupedByBook`, for the semantic list.
    private var globalAIResultsGroupedByBook: [(book: HadithCatalogBook, hits: [GlobalHadithHit])] {
        var order: [String] = []
        var byBook: [String: [GlobalHadithHit]] = [:]
        for hit in globalAIResults {
            if byBook[hit.book.slug] == nil { order.append(hit.book.slug) }
            byBook[hit.book.slug, default: []].append(hit)
        }
        return order.compactMap { slug in
            guard let hits = byBook[slug], let book = hits.first?.book else { return nil }
            return (book, hits)
        }
    }

    /// "SAHIH AL-BUKHARI - <arabic>  [count]" - the Quran's per-surah search header, for a book.
    private func bookSearchSectionHeader(book: HadithCatalogBook, matchCount: Int) -> some View {
        HStack(spacing: 6) {
            // The Arabic interface names the book once, by its Arabic title (Arabic has no case).
            if AppLanguage.isArabicScript {
                Text(book.displayTitle)
            } else {
                Text(book.englishTitle.uppercased())

                Text(book.arabicTitle)
                    .font(.caption)
            }

            Spacer()

            // How many of the hadith matches live in THIS book - the total pill sits up top.
            CountPill(count: matchCount)
        }
    }

    /// A matched chapter from any book: chapter name over the book it belongs to, the
    /// chapter rows' Arabic trailing.
    private func globalChapterRow(_ hit: GlobalChapterHit) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            // In the Arabic interface the Arabic name IS the headline, so the trailing Arabic (the
            // same name again) is left out.
            HighlightedSnippet(
                source: hit.chapter.displayTitle,
                term: searchText,
                font: .subheadline.weight(.semibold),
                accent: settings.accentColor.color,
                fg: .primary,
                lineLimit: 1
            )

            HStack(alignment: .firstTextBaseline) {
                Text(hit.book.displayTitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .layoutPriority(1)

                Spacer(minLength: 8)

                if !AppLanguage.isArabicScript, !hit.chapter.arabic.isEmpty {
                    HighlightedSnippet(
                        source: hit.chapter.arabic,
                        term: searchText,
                        font: settings.useFontArabic
                            ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2)
                            : .caption,
                        accent: settings.accentColor.color,
                        fg: .secondary,
                        lineLimit: 1
                    )
                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                    .minimumScaleFactor(0.6)
                }
            }
        }
        .padding(.vertical, 2)
    }

    /// The bare-number sweep: gather the chapter numbered N and every hadith CITED N (standard
    /// sunnah.com numbering - "8" surfaces Sahih Muslim's 8a...8e) from every book, falling back to
    /// the internal row number for the books that carry no citations. The books are all open
    /// already (mirrors `runGlobalSearch`'s staleness-guarded apply).
    private func runGlobalNumberSearch(_ number: Int, suffix: String?) {
        globalNumberTask?.cancel()
        isNumberSearching = true

        globalNumberTask = Task {
            // Small debounce so holding a multi-digit number doesn't sweep on every intermediate value.
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }

            var chapterHits: [GlobalChapterHit] = []
            var hadithHits: [GlobalHadithHit] = []

            for book in HadithCatalogBook.all {
                if Task.isCancelled { return }
                guard let data = HadithStore.shared.book(book) else { continue }
                // The chapter at that POSITION, the reading "bukhari 1:4" and the in-book search use
                // (five books carry an id-0 chapter, so id and position part ways there). "8a" can
                // only mean a citation, never a chapter.
                if suffix == nil, let chapter = data.chapter(atPosition: number) {
                    chapterHits.append(GlobalChapterHit(book: book, data: data, chapter: chapter))
                }
                // Citation-first: all the variants a base owns; a typed suffix narrows to that one.
                var cited = data.hadiths(citing: number)
                if let suffix {
                    cited = cited.filter { $0.citation == "\(number)\(suffix)" }
                } else if cited.isEmpty, let fallback = data.hadith(uncitedRow: number) {
                    // No citations under this number (Muwatta Malik, most of Bulugh): the internal
                    // row number is what these books show, exactly as before.
                    cited = [fallback]
                }
                for hadith in cited {
                    hadithHits.append(GlobalHadithHit(book: book, data: data, hadith: hadith))
                }
            }

            guard !Task.isCancelled else { return }
            let finalChapters = chapterHits
            let finalHadiths = hadithHits
            await MainActor.run {
                // Still the same citation on screen? (Plain apply - the search-race crash rule.)
                guard citationQuery?.base == number, citationQuery?.suffix == suffix else { return }
                globalNumberChapters = finalChapters
                globalNumberHadiths = finalHadiths
                numberSearchRanFor = number
                isNumberSearching = false
            }
        }
    }

    /// One book's share of the hadith sweep: the matching rows found from `startRow`, at most the
    /// number still needed, and whether the scan reached the end of the book.
    private struct BookScan: Sendable {
        let index: Int
        let rows: [Int]
        let complete: Bool
    }

    /// A new query (or a changed filter) invalidates the last all-books sweep and starts back at page
    /// one - then the sweep runs itself (debounced inside), the Quran search's way.
    private func restartSearch(_ text: String) {
        globalSearchTask?.cancel()
        isGlobalSearching = false
        globalChapterResults = []
        globalHadithResults = []
        globalRankedHits = []
        globalRankedTotal = 0
        globalRankedRelaxed = false
        globalRankedCorrections = []
        globalRankedHighlight = ""
        globalRankedLimit = 6
        globalHasMoreChapters = false
        globalHasMoreHadiths = false
        globalChapterLimit = 5
        globalHadithLimit = 5
        globalAllChapterHits = []
        globalHadithCursor = nil
        globalSearchRanFor = ""
        // Reset the bare-number sweep too.
        globalNumberTask?.cancel()
        isNumberSearching = false
        globalNumberChapters = []
        globalNumberHadiths = []
        numberSearchRanFor = nil
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let citation = citationQuery {
            // A bare number: only the numbered chapter/hadith sweep - the text sweep, AI, and Ask
            // are all meaningless for "10".
            runGlobalNumberSearch(citation.base, suffix: citation.suffix)
        } else {
            if query.count >= 3, HadithReferenceParser.parse(text) == nil {
                runGlobalSearch(query: query)
            }
            // AI matches ride along automatically (already-built corpora only) - the Quran
            // search's rule: AI adds understanding on top, keyword stays exhaustive below.
            runGlobalAISearch(query: text)
        }
    }

    /// The automatic all-books sweep: debounced, script-aware, and matched against the folds built
    /// into the packs - so a keystroke is a byte search, never a normalization pass over the
    /// library. Chapters are matched in full (their names ride in the eager sections). Hadiths are
    /// scanned book by book in a TaskGroup bounded to the core count, one search-block fetch per
    /// block, until one past the page is in hand; `loadMore` resumes from the cursor the last
    /// sweep left instead of re-scanning the books already shown (Performance Guide, Phase 7 step 4).
    private func runGlobalSearch(query: String, loadMore: Bool = false) {
        globalSearchTask?.cancel()
        isGlobalSearching = true

        // "Load all" sets a limit to Int.max - clamped here so the one-past-the-cap arithmetic below
        // (`cap + 1`) can't overflow and trap.
        let chapterCap = min(globalChapterLimit, Int.max - 1)
        let hadithCap = min(globalHadithLimit, Int.max - 1)
        // Folded exactly as the packs' text was folded (punctuation stripped, script-aware), so
        // "aishah" finds "'A'ishah" - one fold of the query, then byte compares from here on.
        let folded = HadithFold.query(query)
        // The filters in force for THIS sweep: the chosen books are the whole library it sees (so the
        // Load More cursor stays an index into the same list), the words become needles, and the
        // grading is a row test run on text matches only.
        let filters = searchFilters
        let books = HadithCatalogBook.all.filter(filters.includes)
        let needles = filters.needles(for: query)
        let sweepChapters = filters.shows(.chapters)
        let sweepHadiths = filters.shows(.hadiths)
        let existingHits = loadMore ? globalHadithResults : []
        let cursor = loadMore ? globalHadithCursor : nil
        let knownChapters = loadMore ? globalAllChapterHits : []
        // One past the cap: the extra hit is what makes "hasMore" true, and its row is the cursor.
        let needed = max(1, hadithCap + 1 - existingHits.count)
        let maxConcurrent = max(1, min(4, ProcessInfo.processInfo.activeProcessorCount))

        globalSearchTask = Task {
            // Debounce: typing restarts this task, so only a settled query pays for the sweep. A Load
            // More is a tap, not a keystroke - it goes straight to the scan.
            if !loadMore {
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
            }

            // The books, opened (a dictionary hit each after the shelf sweep; a search typed before
            // the sweep reaches a book opens it off-main here instead of on this actor).
            var opened: [(book: HadithCatalogBook, data: HadithBookData)?] = []
            opened.reserveCapacity(books.count)
            for book in books {
                if Task.isCancelled { return }
                opened.append(await HadithStore.shared.openOffMain(book).map { (book, $0) })
            }
            let library = opened

            // Chapters: the whole shelf, off-main, in one pass.
            var chapterHits = knownChapters
            if !loadMore, sweepChapters {
                let matched = await Task.detached(priority: .userInitiated) { () -> [(Int, [HadithBookData.Chapter])] in
                    var found: [(Int, [HadithBookData.Chapter])] = []
                    for (index, entry) in library.enumerated() {
                        guard let entry else { continue }
                        let chapters = entry.data.chapters.filter { entry.data.matches($0, folded) }
                        if !chapters.isEmpty { found.append((index, chapters)) }
                    }
                    return found
                }.value
                guard !Task.isCancelled else { return }
                for (index, chapters) in matched {
                    guard let entry = library[index] else { continue }
                    for chapter in chapters {
                        chapterHits.append(GlobalChapterHit(book: entry.book, data: entry.data, chapter: chapter))
                    }
                }
                // The page shows five: the chapter NAMED for the query leads, across the shelf, instead
                // of the first five that mention it in catalog order. Ties keep that order.
                chapterHits = SearchRank.sorted(chapterHits, by: query) { [$0.chapter.english, $0.chapter.arabic] }
            }

            // Hadiths: books from the cursor onward, `maxConcurrent` at a time, in catalog order.
            // Each child stops at `needed` hits; the group stops adding books once the assembled
            // contiguous prefix already covers the page.
            let startBook = cursor?.book ?? 0
            let startRow = cursor?.row ?? 0
            let scans: [Int: BookScan] = await withTaskGroup(of: BookScan.self) { group in
                var results: [Int: BookScan] = [:]
                var next = startBook
                var prefixEnd = startBook
                var assembled = 0

                func addNext() {
                    guard sweepHadiths else { return }
                    while next < library.count {
                        let index = next
                        next += 1
                        guard let entry = library[index] else { continue }
                        let from = index == startBook ? startRow : 0
                        let data = entry.data
                        let accept = filters.gradeTest(for: entry.book, data: data)
                        group.addTask {
                            let rows = data.matchingRows(in: from..<data.hadiths.count, queries: needles.queries,
                                                         requireAll: needles.requireAll, limit: needed, accept: accept)
                            return BookScan(index: index, rows: rows, complete: rows.count < needed)
                        }
                        return
                    }
                }
                for _ in 0..<maxConcurrent { addNext() }

                for await scan in group {
                    results[scan.index] = scan
                    var covered = false
                    while let done = results[prefixEnd] {
                        assembled += done.rows.count
                        prefixEnd += 1
                        if assembled >= needed { covered = true; break }
                    }
                    if covered || Task.isCancelled {
                        group.cancelAll()
                        break
                    }
                    addNext()
                }
                return results
            }
            guard !Task.isCancelled else { return }

            // Assemble in catalog order, stopping one past the cap. That overflow hit is NOT shown;
            // its row is the cursor, so the next Load More re-finds it first (a cursor one row past
            // it silently dropped one hadith per page - caught by the `-hadithLoadMore` check).
            var newHits: [GlobalHadithHit] = []
            var nextCursor: (book: Int, row: Int)? = nil
            assembly: for index in startBook..<library.count {
                guard let entry = library[index] else { continue }
                guard let scan = scans[index] else { break }
                for row in scan.rows {
                    newHits.append(GlobalHadithHit(book: entry.book, data: entry.data, hadith: entry.data.hadiths[row]))
                    if newHits.count >= needed {
                        nextCursor = (index, row)
                        break assembly
                    }
                }
                guard scan.complete else { break }
            }
            let hasMore = newHits.count >= needed
            let shownNew = Array(newHits.prefix(needed - 1))
            let finalHadiths = existingHits + shownNew
            let finalChapters = chapterHits
            let resumeCursor = hasMore ? nextCursor : nil

            // Warm what the result rows are about to read, OFF main: the text blocks behind the
            // shown hits (each a ~130 ms LZMA inflate that used to run inside this task on the main
            // actor), then the highlight folds and the cross-language spans for those texts.
            let warmHits = shownNew
            await withTaskGroup(of: Void.self) { group in
                var seen = Set<String>()
                for hit in warmHits {
                    guard let block = hit.data.pack.textBlockIndex(ofRow: hit.hadith.row),
                          seen.insert("\(hit.book.slug)#\(block)").inserted else { continue }
                    let row = hit.hadith.row
                    let data = hit.data
                    group.addTask(priority: .userInitiated) {
                        data.prewarmText(rows: row..<(row + 1))
                    }
                }
            }
            guard !Task.isCancelled else { return }
            Task.detached(priority: .utility) {
                for hit in warmHits {
                    let strings = hit.hadith.allText
                    HighlightedSnippet.prewarmNormalization(of: [strings.arabic, strings.text, strings.narrator])
                    HadithRow.prewarmCrossLanguageSpans(query: query, text: strings)
                }
            }

            await MainActor.run {
                guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines), filters == searchFilters else { return }
                // Plain apply: the AI pipeline and this sweep land in separate passes, and an animated
                // structural diff racing another is the collection-view assertion crash the Quran
                // search hit (type/delete/type).
                globalAllChapterHits = finalChapters
                globalChapterResults = Array(finalChapters.prefix(chapterCap))
                globalHadithResults = finalHadiths
                globalHasMoreChapters = finalChapters.count > chapterCap
                globalHasMoreHadiths = hasMore
                globalHadithCursor = resumeCursor
                globalSearchRanFor = query
                isGlobalSearching = false
                #if DEBUG
                if RenderCounter.enabled {
                    let refs = finalHadiths.map { "\($0.book.slug):\($0.hadith.idInBook)" }.joined(separator: " ")
                    NSLog("HADITH SWEEP %@ loadMore=%d chapters=%d hadiths=%d hasMore=%d cursor=%@ [%@]",
                          query, loadMore ? 1 : 0, finalChapters.count, finalHadiths.count, hasMore ? 1 : 0,
                          resumeCursor.map { "\($0.book)/\($0.row)" } ?? "none", refs)
                }
                #endif
                // A settled query that actually FOUND something joins the recent-searches chips - the
                // Quran search history's rule, minus the noise of dead-end queries.
                if !finalChapters.isEmpty || !finalHadiths.isEmpty {
                    persistHadithSearchHistoryIfNeeded(query)
                }
            }

            // The ranked lane, after the exact page has landed so the list never waits on it: every
            // book scored word by word, strict pass then relaxed (see HadithRankedSearch). Skipped on
            // Load More, which only extends the exact list.
            guard !loadMore, sweepHadiths else { return }
            let books = library.compactMap { $0 }
            // A grading is tested AFTER the ranking (it reads text blocks, and the ranking offers
            // thousands of rows): keep a deeper list, then cut it to the graded forty.
            let cap = filters.grades.isEmpty ? Self.rankedHadithCap : Self.rankedHadithCap * 5
            // Read here, on the main actor: the detached ranking below cannot reach a view's static.
            let keptAfterGrading = Self.rankedHadithCap
            let reduced = AppPerformance.shouldAvoidBroadPrewarm
            // The reduced tier runs the lane only where the exact list cannot answer alone: two or
            // more words, or a single word the sweep found nothing for (a likely typo).
            if reduced, filters.sort != .relevance, !finalHadiths.isEmpty || !finalChapters.isEmpty,
               query.split(whereSeparator: { $0.isWhitespace }).count < 2 { return }
            let scan = Task.detached(priority: reduced ? .utility : .userInitiated) { () -> (top: [HadithRankedSearch.ShelfHit], total: Int, relaxed: Bool, query: HadithRankedSearch.Query)? in
                #if DEBUG
                let vocabStarted = DispatchTime.now().uptimeNanoseconds
                #endif
                // The typo vocabulary first (a file read; on a fresh install the post-reveal schedule
                // walks the packs for it, and a search before that walks them here), so the first
                // search of a session corrects spelling like every later one.
                HadithVocabulary.shared.buildIfNeeded(books: books.map(\.data))
                #if DEBUG
                let vocabMs = Double(DispatchTime.now().uptimeNanoseconds - vocabStarted) / 1_000_000
                let rankStarted = DispatchTime.now().uptimeNanoseconds
                #endif
                guard !Task.isCancelled,
                      let parsed = HadithRankedSearch.parse(query, vocabulary: HadithVocabulary.shared) else { return nil }
                #if DEBUG
                let parseMs = Double(DispatchTime.now().uptimeNanoseconds - rankStarted) / 1_000_000
                #endif
                // One pass over the library (see `HadithRankedSearch.rankShelf`): the rows carrying
                // every word, or, when none does, the ones carrying the most of them, the best `cap`.
                let shelf = HadithRankedSearch.rankShelf(books: books, query: parsed, cap: cap)
                let relaxed = shelf.relaxed
                #if DEBUG
                if RenderCounter.enabled {
                    NSLog("RANKED hadith %.1f ms (strict %d, partial %d, relaxed %d, parse %.1f ms, vocab %.1f ms)",
                          Double(DispatchTime.now().uptimeNanoseconds - rankStarted) / 1_000_000,
                          shelf.strictCount, shelf.partialCount, relaxed ? 1 : 0, parseMs, vocabMs)
                }
                #endif
                var top = shelf.top
                var total = shelf.total
                if !filters.grades.isEmpty {
                    top = top.filter { item in
                        let entry = books[item.bookIndex]
                        return filters.gradeTest(for: entry.book, data: entry.data)?(item.row) ?? true
                    }
                    top = Array(top.prefix(keptAfterGrading))
                    total = top.count
                }
                return (top, total, relaxed, parsed)
            }
            guard let ranked = await withTaskCancellationHandler(operation: { await scan.value },
                                                                 onCancel: { scan.cancel() }),
                  !Task.isCancelled else { return }
            let parsed = ranked.query
            let rankedHits: [GlobalHadithHit] = ranked.top.compactMap { item in
                let entry = books[item.bookIndex]
                guard entry.data.hadiths.indices.contains(item.row) else { return nil }
                return GlobalHadithHit(book: entry.book, data: entry.data, hadith: entry.data.hadiths[item.row])
            }
            // Warm the first two screens of ranked rows off-main (the cache dedupes the blocks), the
            // way the sweep warms its page; the List realizes more rows than are visible.
            let warmRanked = Array(rankedHits.prefix(20))
            await withTaskGroup(of: Void.self) { group in
                for hit in warmRanked where hit.hadith.row >= 0 {
                    let row = hit.hadith.row
                    let data = hit.data
                    group.addTask(priority: .userInitiated) {
                        data.prewarmText(rows: row..<(row + 1))
                    }
                }
            }
            guard !Task.isCancelled else { return }
            let highlight = parsed.highlightQuery
            Task.detached(priority: .utility) {
                for hit in warmRanked {
                    let strings = hit.hadith.allText
                    HighlightedSnippet.prewarmNormalization(of: [strings.arabic, strings.text, strings.narrator])
                    HadithRow.prewarmCrossLanguageSpans(query: highlight, text: strings)
                }
            }
            await MainActor.run {
                guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines), filters == searchFilters else { return }
                globalRankedHits = rankedHits
                globalRankedTotal = ranked.total
                globalRankedRelaxed = ranked.relaxed
                globalRankedCorrections = parsed.corrections
                globalRankedHighlight = parsed.highlightQuery
                if !rankedHits.isEmpty { persistHadithSearchHistoryIfNeeded(query) }
                #if DEBUG
                if RenderCounter.enabled {
                    let refs = rankedHits.map { "\($0.book.slug):\($0.hadith.idInBook)" }.joined(separator: " ")
                    NSLog("RANKED hadith refs %@ total=%d relaxed=%d [%@]", query, ranked.total, ranked.relaxed ? 1 : 0, refs)
                }
                #endif
            }
        }
    }

    // MARK: Search history (the Quran tab's chips, for hadith)

    private func persistHadithSearchHistoryIfNeeded(_ rawQuery: String) {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return }
        // Avoid repeatedly writing the same query while the user is editing.
        if lastSavedSearchQuery.caseInsensitiveCompare(trimmed) == .orderedSame { return }
        settings.addHadithSearchHistory(trimmed)
        lastSavedSearchQuery = trimmed
    }

    // (The chips row itself is the shared `HadithSearchHistoryChips` - one component for the tab root
    // and the book view, so the two search bars read identically.)

    // MARK: Bookmarks

    private var bookmarksSection: some View {
        Section(header: SectionPillHeader(
            title: String(localized: "BOOKMARKS"),
            count: store.bookmarks.count,
            icon: "bookmark.fill",
            accentTitle: true,
            isExpanded: $showHadithBookmarks,
            onShuffle: store.bookmarks.isEmpty ? nil : {
                if let random = store.bookmarks.randomElement() {
                    pushedReference = random
                }
            }
        )) {
            if showHadithBookmarks {
                // Every bookmark lives right here, Quran-bookmark style - no capped preview with a
                // "View All" push, and no folders above them: bookmarks ARE the filing system
                // (Abu, 2026-09-07). In grid mode they render as tiles, like the Quran's bookmark grid.
                if showsGrid {
                    // Chunked non-lazy rows (`tileGridChunk`): a lazy grid in a List row can answer a
                    // different height on each self-sizing pass, which iOS 26 traps on.
                    let bookmarks = store.bookmarks
                    let chunk = tileGridChunk(columns: gridColumns.count)
                    ForEach(Array(stride(from: 0, to: bookmarks.count, by: chunk)), id: \.self) { start in
                        SummaryTileGrid(columns: gridColumns.count) {
                            ForEach(bookmarks[start..<min(start + chunk, bookmarks.count)]) { bookmark in
                                HadithBookmarkGridTile(bookmark: bookmark, ringsReading: usesColumnNavigation) {
                                    pushedReference = bookmark
                                }
                                .equatable()
                            }
                        }
                        .tileGridChunkRow(start: start, count: bookmarks.count, chunk: chunk)
                    }
                } else {
                    ForEach(store.bookmarks) { bookmark in
                        HadithBookmarkRow(bookmark: bookmark)
                            .equatable()
                    }
                }
            }
        }
    }

    /// Removal only needs the identity fields; the store matches on slug + idInBook.
    private func placeholderHadith(for bookmark: HadithBookmark) -> HadithBookData.Hadith? {
        HadithBookData.Hadith(
            id: -1, idInBook: bookmark.idInBook, chapterId: -1,
            arabic: "", english: HadithBookData.Hadith.EnglishText(narrator: "", text: "")
        )
    }

    // MARK: Catalog sections

    /// A catalog section rendered as a grid of tiles or a list of rows, per the app-wide `gridMode`,
    /// under the shared counted header. Pass `isExpanded` (plus the star icon and accent) for the
    /// collapsible favorites treatment the Quran tab uses.
    @ViewBuilder
    private func bookSection(
        title: String,
        books: [HadithCatalogBook],
        icon: String? = nil,
        accentTitle: Bool = false,
        isExpanded: Binding<Bool>? = nil,
        shuffle: Bool = true
    ) -> some View {
        let header = SectionPillHeader(
            title: title,
            count: books.count,
            icon: icon,
            accentTitle: accentTitle,
            isExpanded: isExpanded,
            // The SurahsHeader shuffle, for books: open a random one from this section.
            onShuffle: shuffle ? {
                if let random = books.randomElement() {
                    pushedBook = random
                }
            } : nil
        )
        // The Quran surah list's shape (and the chapter list's): the header stands alone, then each
        // book is its OWN Section - separate glass cards with compact spacing between them.
        Section(header: header) { }
            .padding(.bottom, -12)

        if isExpanded?.wrappedValue ?? true {
            if showsGrid {
                Section {
                    // Centered: a book tile is short labels (Abu, 2026-10-05). The BOOKMARK grid above
                    // keeps .leading - those tiles carry hadith prose.
                    // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different
                    // height on each self-sizing pass, which iOS 26 traps on.
                    SummaryTileGrid(columns: gridColumns.count) {
                        ForEach(books) { book in
                            bookGridTile(book)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                ForEach(books) { book in
                    Section {
                        bookLink(book) {
                            bookRow(book)
                        }
                        // iPad/Mac: the book the detail column is reading keeps its bed, the same
                        // promise the grid tiles' ring makes (2026-10-05). The row's whole cell, from a
                        // modifier that alone observes the selection, so a chapter pick never
                        // re-renders the catalog (see `HadithReadingRowHighlight`).
                        .modifier(HadithReadingRowHighlight(slug: book.slug, isActive: usesColumnNavigation))
                        .contextMenu { bookContextMenu(book) }
                        // The surah rows' swipe language: icon-only. Favorite on the leading edge,
                        // scroll-to on the trailing edge.
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) { store.toggleFavoriteOrConfirm(book) }
                            } label: {
                                Image(systemName: store.isFavorite(book.slug) ? "star.fill" : "star")
                            }
                            .tint(settings.accentColor.color)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                settings.hapticFeedback()
                                pendingScrollToBookSlug = book.slug
                            } label: {
                                Image(systemName: "arrow.down.circle")
                            }
                            .tint(.secondary)
                        }
                        .id("hadith-book-\(book.slug)")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bookContextMenu(_ book: HadithCatalogBook) -> some View {
        Text(book.displayTitle)
            .foregroundStyle(.secondary)

        Button {
            settings.hapticFeedback()
            FocusOverlayPresenter.shared.present(.hadithBook(book))
        } label: {
            Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
        }

        Button {
            settings.hapticFeedback()
            presentSystemShareSheet(items: [bookShareText(book)])
        } label: {
            Label("Share Book", systemImage: "square.and.arrow.up")
        }

        Divider()

        Button(role: store.isFavorite(book.slug) ? .destructive : .cancel) {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { store.toggleFavoriteOrConfirm(book) }
        } label: {
            Label(store.isFavorite(book.slug) ? "Unfavorite Book" : "Favorite Book",
                  systemImage: store.isFavorite(book.slug) ? "star.fill" : "star")
        }

        Button {
            settings.hapticFeedback()
            pendingScrollToBookSlug = book.slug
        } label: {
            Text("Scroll To Book")
            Image(systemName: "arrow.down.circle")
        }

    }

    /// Sharing a BOOK sends its identity and story, not megabytes of text.
    private func bookShareText(_ book: HadithCatalogBook) -> String {
        let name = book.name
        // The Arabic interface shares the book in Arabic: its title, compiler and full title once,
        // without the English meaning and transliteration lines.
        if AppLanguage.isArabicScript {
            return "\(book.displayTitle)\n\n\(book.displayAuthor)\n\(book.eraDisplay)\n\n"
                + String(localized: "Full title: \(name.fullArabic)") + "\n\n\(book.longDescription)"
        }
        return "\(book.englishTitle) (\(book.arabicTitle)): “\(name.meaning)”\n\n\(book.authorEnglish) - \(book.era)\n\n"
            + String(localized: "Full title: \(name.fullArabic)") + "\n\(name.fullTransliteration)\n“\(name.fullMeaning)”\n\n\(book.longDescription)"
    }

    /// "97 Ch • 7,277 Ha" - the book's SHAPE (chapters and hadiths). The surah rows lead with ayah
    /// counts; books do the same. Chapters, then hadiths - the one order every hadith surface uses.
    /// When the book was compiled, dated the classical way by its compiler's death ("d. 256 AH /
    /// 870 CE"), under the counts on a list row and a grid tile alike, so the shelf reads in time.
    private func bookEraLabel(_ book: HadithCatalogBook) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "calendar")
                .imageScale(.small)
            Text(book.eraDisplay)
                .monospacedDigit()
        }
        .font(.caption2)
        .foregroundColor(.secondaryOnGlass)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(book.eraAccessibilityLabel)
    }

    private func arabicTitleFont(_ style: UIFont.TextStyle, bump: CGFloat) -> Font {
        settings.useFontArabic
            ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: style).pointSize + bump)
            : Font(UIFont.preferredFont(forTextStyle: style))
    }

    /// The SurahRow number pill's width: enough for a two-digit number in headline type.
    private var bookBadgeWidth: CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        return ("100" as NSString).size(withAttributes: [.font: font]).width + 8
    }

    /// The SurahRow number pill, for a book: full row height, tinted when favorited, and the tap
    /// itself toggles the favorite - the same conditional-glass control the surah list has.
    @ViewBuilder
    private func bookNumberPill(_ book: HadithCatalogBook) -> some View {
        let favorite = store.isFavorite(book.slug)
        // The Quran's continue-reading grammar: a book badge (no tint) marks where you left off.
        let isLastRead = store.lastRead?.slug == book.slug
        ZStack(alignment: .topTrailing) {
            Text("\(book.number)")
                .font(.caption.weight(.bold))
                .foregroundColor(settings.accentColor.color)
                .frame(width: bookBadgeWidth)
                .frame(maxHeight: .infinity)
                .conditionalGlassEffect(
                    useColor: favorite ? 0.3 : nil,
                    customTint: favorite ? settings.accentColor.color : nil
                )
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { store.toggleFavoriteOrConfirm(book) }
                }
                .accessibilityLabel("Book \(book.number)\(isLastRead ? String(localized: ", last read") : "")")

            if favorite {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(settings.accentColor.color)
                    .padding(4)
                    .offset(x: 8, y: -6)
            } else if isLastRead {
                Image(systemName: "book.fill")
                    .font(.caption2)
                    .foregroundStyle(settings.accentColor.color)
                    .padding(4)
                    .offset(x: 8, y: -6)
            }
        }
        .padding(.vertical, {
            if #available(iOS 26, *) { 0 } else { 8 }
        }())
    }

    /// The SurahRow, for a book (2026-10-26, the Quran/Hadith consistency pass): the number pill,
    /// the title over its caption lines (the counts, then the era, in the surah row's glass
    /// secondary), and at the trailing edge the Arabic name in the primary colour with its number
    /// beside it in the accent. Until then the counts were two glass chips and the Arabic name was
    /// painted in the accent, so the two catalogs read as two apps.
    private func bookRow(_ book: HadithCatalogBook) -> some View {
        HStack(alignment: .center) {
            bookNumberPill(book)
                .padding(.trailing, 2)

            VStack(alignment: .leading, spacing: 2) {
                // Two lines reserved for the title, so "Forty Hadith Qudsi" never stacks a word per line.
                // The Arabic interface titles the row by its Arabic name and drops the trailing Arabic
                // column below (the same name twice).
                HighlightedSnippet(
                    source: book.displayTitle,
                    term: searchText,
                    font: .subheadline.weight(.semibold),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    lineLimit: 2
                )
                .minimumScaleFactor(0.7)

                // Simple Mode leaves the counts and the era to the book's own screen.
                if !settings.hides(.bookStats) {
                    if let counts = store.counts(for: book) {
                        Text(bookCountsLine(counts))
                            .font(.caption2)
                            .foregroundColor(.secondaryOnGlass)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    bookEraLabel(book)
                }
            }
            .layoutPriority(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            if !AppLanguage.isArabicScript {
                HStack(spacing: 6) {
                    HighlightedSnippet(
                        source: book.arabicTitle,
                        term: searchText,
                        font: arabicTitleFont(.title3, bump: 0),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        lineLimit: 2
                    )
                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                    .multilineTextAlignment(.trailing)

                    bookArabicNumber(book, style: .title3)
                }
                .minimumScaleFactor(0.5)
                .padding(.leading, 8)
            }
        }
        .contentShape(Rectangle())
    }

    /// The book's number in Arabic-Indic digits beside its Arabic name, the surah row's ornament
    /// (the Arabic face draws the digits in the end-of-ayah ring, as the chapter tiles have it).
    private func bookArabicNumber(_ book: HadithCatalogBook, style: UIFont.TextStyle) -> some View {
        Text(arabicNumberString(from: book.number))
            .font(settings.useFontArabic
                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: style).pointSize + 2)
                : Font(UIFont.preferredFont(forTextStyle: style)).weight(.semibold))
            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
            .foregroundColor(settings.accentColor.color)
            .layoutPriority(1)
    }

    /// "97 Chapters • 7,277 Hadiths": the surah row's "286 Ayahs" line, for a book.
    private func bookCountsLine(_ counts: (chapters: Int, hadiths: Int)) -> String {
        let chapters = counts.chapters == 1 ? String(localized: "1 Chapter") : String(localized: "\(counts.chapters) Chapters")
        return String(localized: "\(chapters) • \(counts.hadiths.formatted()) Hadiths")
    }

    /// A compact tile in the 99-Names style: Arabic, English, and the number stacked centered - a
    /// Button that pushes through the hidden `pushedBook` link, so no List chevron ever appears.
    private func bookGridTile(_ book: HadithCatalogBook) -> some View {
        GridTileMenu {
            settings.hapticFeedback()
            pushedBook = book
        } menu: {
            bookContextMenu(book)
        } label: {
            // The surah grid tile's lines (2026-10-26): the Arabic name in the primary colour with
            // its number beside it, "1: Sahih al-Bukhari" with the number in the accent, then the
            // counts and the era in the glass secondary. CENTERED, every line, like every short-label
            // tile (Abu, 2026-10-05).
            VStack(alignment: .center, spacing: 2) {
                HStack(spacing: 4) {
                    bookArabicNumber(book, style: .subheadline)

                    HighlightedSnippet(
                        source: book.arabicTitle,
                        term: searchText,
                        font: arabicTitleFont(.title3, bump: 0),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        lineLimit: 1
                    )
                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                // The star overlay sits in the trailing corner, so this line alone needs room for it,
                // taken from both edges to keep it on the tile's true centre.
                .padding(.horizontal, 20)

                if !AppLanguage.isArabicScript {
                    // One run, number and title: a two-line title ("The Forty Hadith of Imam Nawawi")
                    // keeps its number on the first line instead of beside a centred block.
                    HighlightedSnippet(
                        source: book.englishTitle,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        leadingPrefix: "\(book.number): ",
                        leadingPrefixFont: .subheadline.monospacedDigit().weight(.bold),
                        leadingPrefixColor: settings.accentColor.color,
                        lineLimit: 2
                    )
                    .multilineTextAlignment(.center)
                    .leftToRightContent()
                    .minimumScaleFactor(0.55)
                }

                // Simple Mode leaves the counts and the era to the book's own screen, and the tile
                // shrinks to what it still holds.
                if !settings.hides(.bookStats) {
                    if let counts = store.counts(for: book) {
                        Text(bookCountsLine(counts))
                            .font(.caption2)
                            .foregroundColor(.secondaryOnGlass)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }

                    bookEraLabel(book)
                }

                Spacer(minLength: 0)
            }
            .multilineTextAlignment(.center)
            // Every tile in a row takes the row's height (`SummaryTileGrid`), as the surah tiles do.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            // iPad/Mac: the book the detail column is reading wears the sidebar's ring.
            .overlay {
                if usesColumnNavigation { HadithReadingRing(slug: book.slug) }
            }
        }
        .conditionalGlassEffect(
            clear: !store.isFavorite(book.slug),
            rectangle: true,
            useColor: store.isFavorite(book.slug) ? 0.25 : nil,
            customTint: store.isFavorite(book.slug) ? settings.accentColor.color : nil
        )
        // OUTSIDE the menu's label, so the star's own tap target does not fight the long press that
        // opens it (see `GridTileMenu`).
        .gridFavoriteStar(
            isFavorite: store.isFavorite(book.slug),
            accent: settings.accentColor.color,
            accessibilityName: book.displayTitle
        ) {
            store.toggleFavoriteOrConfirm(book)
        }
    }
}


#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        HadithView()
    }
}
#endif

// MARK: - The all-books hadith corpus

/// The ONE combined AI-search corpus over EVERY book, shared by the Hadith tab's search and the Ask AI
/// chat: built once (a gather of all ~50k hadiths off the main thread, then the engine's shared
/// embedding) and persisted, so every launch after the first loads it from disk in one read.
@MainActor
enum HadithSemanticCorpus {
    nonisolated static let id = "hadith-all"

    /// Version keyed to the shelf itself - deterministic (never hashValue, which is seeded per
    /// launch), so yesterday's build loads from disk today.
    static var version: String {
        "all3-" + HadithCatalogBook.all.map(\.slug).sorted().joined(separator: ".")
    }

    /// True while the slow path (reading every book to gather texts) runs, pre-embedding.
    private(set) static var isGathering = false

    /// What a shipped pack was built from, named without opening a book: every catalog slug with
    /// its pack's byte size. A text correction changes the compressed pack's size in practice, and
    /// the pack rebuild procedure re-exports the vectors regardless (Performance Guide, section 15).
    nonisolated static var fingerprint: String {
        let parts = HadithCatalogBook.all.map(\.slug).sorted().map { slug -> String in
            let size = HadithPack.bundledURL(slug)
                .flatMap { try? FileManager.default.attributesOfItem(atPath: $0.path) }
                .flatMap { $0[.size] as? UInt64 } ?? 0
            return "\(slug):\(size)"
        }
        return "hadith-all:" + parts.joined(separator: ",")
    }

    /// The instant half of `prepare`: load a persisted build from disk (off the main actor, awaited
    /// here) so a caller can search the corpus as soon as this returns. True when the corpus is
    /// ready afterwards. (`texts` is an autoclosure the engine evaluates only when no persisted
    /// build exists, and an empty list starts no build.)
    @discardableResult
    static func probeDisk(engine: SemanticSearchEngine) async -> Bool {
        guard SemanticSearchEngine.isSupported else { return false }
        if !engine.isReady(id), !engine.isBuilding(id) {
            engine.prepare(corpusID: id, version: version, fingerprint: { Self.fingerprint }, texts: [])
        }
        await engine.awaitDiskLoad(id)
        return engine.isReady(id)
    }

    /// Load-or-build. Returns after the disk probe when a persisted build exists (or one is already
    /// building or gathering); otherwise returns once the texts are gathered and handed to the
    /// engine, whose embedding then continues in the background (`readyCorpora` publishes).
    /// True when this call loaded or started something; false when there was nothing to do.
    @discardableResult
    static func prepare(engine: SemanticSearchEngine, store: HadithStore) async -> Bool {
        guard SemanticSearchEngine.isSupported,
              !engine.isReady(id), !engine.isBuilding(id), !isGathering else { return false }

        if await probeDisk(engine: engine) { return true }
        guard !engine.isReady(id), !engine.isBuilding(id), !isGathering else { return false }

        isGathering = true
        defer { isGathering = false }
        // The books are opened on the main actor (that is where the store lives), but the TEXT is
        // gathered off it: this walks every hadith, and over the packs that decompresses the whole
        // library. Inline, it was a second of main thread in ~100 ms hitches. The opens themselves
        // take one runloop turn each (the shelf sweep's rule): seventeen back-to-back maps and index
        // parses read as one stall under Low Power Mode (Performance Guide, Phase 6 step 6).
        var opened: [(String, HadithBookData)] = []
        for book in HadithCatalogBook.all {
            if let data = store.book(book) { opened.append((book.slug, data)) }
            await Task.yield()
        }
        let built = await Task.detached(priority: .utility) { () -> (texts: [String], keys: [String]) in
            var texts: [String] = []
            var keys: [String] = []
            for (slug, data) in opened {
                for hadith in data.hadiths {
                    let strings = hadith.allText
                    texts.append("\(strings.narrator) \(strings.text)")
                    keys.append("\(slug)|\(hadith.idInBook)")
                }
            }
            return (texts, keys)
        }.value
        engine.prepare(corpusID: id, version: version, fingerprint: { Self.fingerprint },
                       texts: built.texts, keys: built.keys)
        return true
    }
}
