import SwiftUI

// The Hadith tab root: summary tiles, Hadith of the Day, bookmarks, favorites, the catalog by group,
// reference lookups, and all-books search. Every collection ships inside the app as a pack on
// demand (any book whose JSON is ever bundled into the app is picked up automatically instead).

#if os(iOS)

struct HadithTrailingToolbar: ViewModifier {
    @ObservedObject var settings = Settings.shared
    @Binding var hadithGridMode: Bool
    @Binding var showHadithSettings: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
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
        Button {
            settings.hapticFeedback()
            withAnimation { hadithGridMode.toggle() }
        } label: {
            Image(systemName: hadithGridMode ? "list.bullet" : "square.grid.2x2")
        }
        .accessibilityLabel(hadithGridMode ? "Show list" : "Show grid")
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
    @ObservedObject private var settings = Settings.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var store = HadithStore.shared
    /// The favorites and bookmark sections render user marks, which the store only FORWARDS (they
    /// live in HadithUserData, their own publisher) - observing it here is what re-renders them.
    @ObservedObject private var userData = HadithUserData.shared

    @State private var searchText = ""
    @State private var showHadithSettings = false
    /// Grid tiles are plain Buttons (a NavigationLink cell in a List draws a chevron); tapping one sets
    /// this, and a hidden `NavigationLink` behind the List performs the actual push.
    @State private var pushedBook: HadithCatalogBook?

    /// Collapse state for the favorites/bookmarks sections, same as the Quran tab's.
    @AppStorage("showHadithFavoriteBooks") private var showFavoriteBooks = true
    @AppStorage("showHadithBookmarks") private var showHadithBookmarks = true
    /// The Hadith tab's OWN grid/list choice - deliberately decoupled from the app-wide `gridMode`
    /// switch, so flipping the hadith catalog doesn't flip the Quran, 99 Names, and Islam grids too.
    @AppStorage("hadithGridMode") private var hadithGridMode = false
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
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist (the Quran search's
    /// `showKeywordResults`). Reset to the AI list on every new query.
    #if DEBUG
    /// "-hadithKeywordResults": open the switch on Keyword Results (screenshots can't tap it).
    @State private var showHadithKeywordResults = ProcessInfo.processInfo.arguments.contains("-hadithKeywordResults")
    #else
    @State private var showHadithKeywordResults = false
    #endif
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
        guard SemanticSearchEngine.isSupported, trimmed.count >= 3, !trimmed.containsArabicScript,
              HadithReferenceParser.parse(trimmed) == nil else {
            if !globalAIResults.isEmpty { globalAIResults = [] }
            return
        }
        prepareAllBooksCorpus()

        globalAITask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            let results = await semanticEngine.search(corpusID: allBooksCorpusID, query: trimmed, limit: 10)
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
                      let book = HadithCatalogBook.bySlug[String(parts[0])],
                      let data = store.book(book),
                      let hadith = data.hadiths.first(where: { $0.idInBook == idInBook }) else { continue }
                hits.append(GlobalHadithHit(book: book, data: data, hadith: hadith))
                if Task.isCancelled { return }
            }

            let top = hits
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                // Plain apply: an animated section insert racing the keyword sweep's own apply is the
                // collection-view assertion crash the Quran search hit.
                globalAIResults = top
            }
        }
    }

    /// Today's hadith lives in the STORE, resolved at app launch - the tab
    /// renders it instantly.
    private var dailyHadith: HadithStore.DailyPick? { store.daily }
    /// Whether the daily section's history (last 5 days) is unfolded - the shuffle only shows here.
    @State private var showDailyHistory = false
    /// A hidden push target (shuffled bookmark, summary tiles) - HadithReferenceView by slug+number.
    @State private var pushedReference: HadithBookmark? = nil

    private func matches(_ book: HadithCatalogBook) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        if book.englishTitle.localizedCaseInsensitiveContains(query) ||
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
        if isHadithSearchFocused, searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                // The Quran card's grammar: the help folds behind a -/+, the recent chips stay at
                // the bottom, nearest the field.
                HStack(spacing: 8) {
                    Text("Quick Search Help")
                        .font(.subheadline.bold())
                        .foregroundStyle(settings.accentColor.color)

                    Spacer(minLength: 0)

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
                        Text("• Books, chapters & hadith text (English or Arabic)")
                        Text("• Reference: 'bukhari 5103' or 'muslim 3:12'")
                        Text("• AI: meaning search, 'controlling anger'")
                        Text("• Ask: questions get an on-device AI answer")
                        Text("• Text and AI search cover all 17 collections")
                    }
                    .font(.caption)
                    .foregroundStyle(.primary)
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
        navigationContainer
            // The window crossed the compact/regular boundary (iPad Split View drag, Slide Over, Stage
            // Manager) and the container swapped between the split view and the stack. Carry the open
            // book across the swap instead of dropping the reader back on the catalog.
            .onChange(of: usesColumnNavigation) { columns in
                guard #available(iOS 16.0, *) else { return }
                if columns {
                    // Stack → columns: a book opened through the tracked hidden links becomes the
                    // content column's path. (The interceptors on `content` only fire on assignment,
                    // and these were set BEFORE the flip, so they must be converted here.)
                    if let book = pushedBook {
                        pushedBook = nil
                        bookPath = [.book(slug: book.slug, autoOpenHadithID: nil)]
                    } else if let reference = pushedReference {
                        pushedReference = nil
                        bookPath = [.book(slug: reference.slug, autoOpenHadithID: reference.idInBook)]
                    }
                } else if let route = bookPath.last {
                    // Columns → stack: reopen the book through the hidden links - at the spot the
                    // reading column was on when the store has one (the reader keeps last-read fresh),
                    // else at its chapter list. Delayed like every other programmatic push here: an
                    // isActive flip during the container swap is unreliable in NavigationView.
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

    /// The iOS 15 hidden-link pair - see the note at its `.background` call site in `content`.
    @ViewBuilder
    private var legacyHiddenPushLinks: some View {
        if #unavailable(iOS 16.0) {
            ZStack {
                NavigationLink(isActive: Binding(
                    get: { pushedBook != nil },
                    set: { if !$0 { pushedBook = nil } }
                )) {
                    if let pushedBook {
                        HadithBookView(book: pushedBook)
                    }
                } label: {
                    EmptyView()
                }
                .isDetailLink(false)

                NavigationLink(isActive: Binding(
                    get: { pushedReference != nil },
                    set: { if !$0 { pushedReference = nil } }
                )) {
                    if let pushedReference, let book = HadithCatalogBook.bySlug[pushedReference.slug] {
                        HadithBookView(book: book, autoOpenHadithID: pushedReference.idInBook)
                    }
                } label: {
                    EmptyView()
                }
                .isDetailLink(false)
            }
            .opacity(0)
        }
    }

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
                HadithBookView(book: book)
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
                        // Before any reading has happened there is no Last Read - and an empty
                        // "Your Summary" header is just noise. Summary tiles are the only form now;
                        // the old full-row sections went with the removed Summary Mode setting.
                        if dailyHadith != nil || store.lastRead != nil {
                            boxed(summaryTilesSection)
                        }
                    }

                    if let reference = referenceResult {
                        boxed(referenceSection(reference))
                    }

                    if !searchText.isEmpty {
                        // The Quran search's order: matching books first, then chapters, then hadiths.
                        let results = HadithCatalogBook.all.filter(matches)
                        if !results.isEmpty {
                            boxed(bookSection(title: "MATCHING BOOKS", books: results, shuffle: false))
                        } else if referenceResult == nil, numberQuery == nil {
                            // A bare number never matches a book title - the numbered chapter/hadith
                            // sections below are the answer, so skip the "no books" noise for it.
                            boxed(
                                Section(header: SectionPillHeader(title: "MATCHING BOOKS", count: 0)) {
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
                                title: "FAVORITES",
                                books: favorites,
                                icon: "star.fill",
                                accentTitle: true,
                                isExpanded: $showFavoriteBooks
                            ))
                        }

                        ForEach(HadithCatalogBook.Group.allCases, id: \.self) { group in
                            let books = filteredBooks(in: group)
                            if !books.isEmpty {
                                boxed(bookSection(title: group.rawValue, books: books))
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
            .compactListSectionSpacing()
            // The grid/list flip animates the whole catalog, same as the Quran tab.
            .animation(.easeInOut, value: hadithGridMode)
            // iOS 15 ONLY: the hidden isActive links programmatic pushes ride on where there is no
            // NavigationStack path (grid tiles → book; shuffled bookmark / summary tiles / daily
            // history → book, which then auto-pushes the hadith's chapter). On iOS 16+ BOTH containers
            // navigate by value through `bookPath` - these links must not even exist there: an active
            // legacy link inside a NavigationStack can fire a phantom push in the frame before the
            // interceptors below clear the state, and spurious binding writes are the very bug the
            // path migration removes.
            .background(legacyHiddenPushLinks)
            // Column mode navigates by value instead: both hidden links above are legacy
            // `destination` links, which a split view routes into the DETAIL column - the reader's
            // place. Intercepting the two state vars here keeps every caller in the tab unchanged.
            .onChange(of: pushedBook) { book in
                guard #available(iOS 16.0, *), let book else { return }
                pushedBook = nil
                // Both iOS 16 containers navigate by path; only iOS 15 still uses the hidden link.
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
            // The search help floats over the list top while the field is focused and empty.
            .overlay(alignment: .top) {
                searchHelpOverlay
                    .animation(.easeInOut, value: isHadithSearchFocused)
            }
            // Apple Music-style: the bottom search bar minimizes while scrolling down.
            .collapseBarsOnScroll($barsCollapsed)
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
                showHadithSettings: $showHadithSettings
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
                store.loadLastRead()
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
                    showHadithSettings = true
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
                // A new query invalidates the last all-books sweep and starts back at page one -
                // then the sweep runs itself (debounced inside), the Quran search's way.
                globalSearchTask?.cancel()
                isGlobalSearching = false
                globalChapterResults = []
                globalHadithResults = []
                globalHasMoreChapters = false
                globalHasMoreHadiths = false
                globalChapterLimit = 5
                globalHadithLimit = 5
                globalAllChapterHits = []
                globalHadithCursor = nil
                globalSearchRanFor = ""
                // Every new query starts back on the AI list.
                showHadithKeywordResults = false
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
            // A corpus finishing its build mid-query (from a book view) surfaces here immediately.
            .onChange(of: semanticEngine.readyCorpora) { _ in
                runGlobalAISearch(query: searchText)
            }
            .onChange(of: pendingScrollToBookSlug) { slug in
                guard let slug else { return }
                pendingScrollToBookSlug = nil
                // Grid tiles carry no scroll ids (the Quran list has the same rule), so flip to the
                // list first; and clear the search so the catalog rows exist, then land on the book.
                if hadithGridMode { hadithGridMode = false }
                withAnimation { searchText = "" }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { scrollProxy.scrollTo("hadith-book-\(slug)", anchor: .top) }
                }
            }
        }
    }

    // MARK: Hadith of the Day (engine lives in HadithStore; resolved before this tab opens)

    private var dailyHistory: [HadithStore.DailyHadithEntry] { HadithStore.loadDailyHistory() }


    private func dailyHistoryRow(_ entry: HadithStore.DailyHadithEntry, isToday: Bool) -> some View {
        HStack(spacing: 8) {
            Button {
                settings.hapticFeedback()
                pushedReference = HadithBookmark(
                    slug: entry.slug, idInBook: entry.idInBook,
                    reference: entry.reference, preview: entry.englishPreview
                )
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    // The timestamp lives ONLY here, in the expanded (+) rows - top-left, above the
                    // reference pill. The compact tiles stay clean.
                    historyTimestampLabel(entry.date)

                    Text(entry.reference)
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
                        HadithArabicPreview(text: entry.arabicPreview, lineLimit: 2)
                    }

                    if settings.showHadithEnglish {
                        Text(entry.englishPreview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .reservedLineLimit(2)
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
    }

    // MARK: Summary tiles + last read

    /// Compact "summary mode", the Quran tab's pattern: Hadith of the Day and Last Read as two tappable
    /// tiles in one section. On by default; the full rows return when it's off (Hadith settings).
    @ViewBuilder
    private var summaryTilesSection: some View {
        Section(header:
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
            
                Text("YOUR SUMMARY")

                Spacer()

                if !dailyHistory.isEmpty {
                    Image(systemName: showDailyHistory ? "minus.circle" : "plus.circle")
                        .padding(4)
                        .conditionalGlassEffect()
                        .onTapGesture {
                            settings.hapticFeedback()
                            withAnimation { showDailyHistory.toggle() }
                        }
                }
            }
            .foregroundColor(settings.accentColor.color)
        ) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                if let dailyHadith {
                    summaryTile(
                        title: "Hadith of the Day",
                        icon: "sparkles",
                        reference: "\(dailyHadith.book.englishTitle) \(dailyHadith.hadith.displayNumber)",
                        // The previews were captured when the pick was made - the tile never touches a pack.
                        arabic: settings.showHadithArabic ? dailyHadith.arabicPreview : "",
                        english: settings.showHadithEnglish ? dailyHadith.englishPreview : ""
                    ) {
                        pushedReference = HadithBookmark(
                            slug: dailyHadith.book.slug, idInBook: dailyHadith.hadith.idInBook,
                            reference: "", preview: ""
                        )
                    }
                }

                if let lastRead = store.lastRead {
                    summaryTile(
                        title: "Last Read Hadith",
                        icon: "book",
                        reference: lastRead.reference,
                        arabic: settings.showHadithArabic ? lastRead.arabicPreview : "",
                        english: settings.showHadithEnglish ? lastRead.englishPreview : ""
                    ) {
                        pushedReference = HadithBookmark(
                            slug: lastRead.slug, idInBook: lastRead.idInBook,
                            reference: lastRead.reference, preview: ""
                        )
                    }
                }
            }
            .padding(.vertical, 4)

            if showDailyHistory {
                ForEach(Array(dailyHistory.enumerated()), id: \.element.dayKey) { index, entry in
                    dailyHistoryRow(entry, isToday: index == 0)
                        .opacity(index == 0 ? 1 : 0.75)
                }
            }
        }
    }

    private func summaryTile(title: String, icon: String, reference: String, arabic: String, english: String, onTap: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .layoutPriority(1)
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
                    HadithArabicPreview(text: arabic, lineLimit: 2)
                }

                if settings.showHadithEnglish {
                    Text(english)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .reservedLineLimit(2)
                }
            }
            // Hug the content - stretching to fill the row's height (maxHeight + a Spacer) parked
            // all the slack as dead space under the English line.
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .conditionalGlassEffect(clear: true, rectangle: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }


    // MARK: About hadith

    /// One polished orientation card: the two pillar screens as proper links on a glass card, with the
    /// pointer to where the full teachings live.
    private var aboutHadithSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.subheadline)
                        .foregroundColor(settings.accentColor.color)

                    Text("About Hadith & the Sunnah")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }

                NavigationLink(destination: LazyDestination { SunnahPillarView() }) {
                    HStack {
                        Text("What is the Sunnah?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .conditionalGlassEffect(clear: true, rectangle: true)
                    .contentShape(Rectangle())
                    .padding(.horizontal, -2)
                }
                .buttonStyle(.plain)

                NavigationLink(destination: LazyDestination { HadithPillarView() }) {
                    HStack {
                        Text("What are Hadiths?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .conditionalGlassEffect(clear: true, rectangle: true)
                    .contentShape(Rectangle())
                    .padding(.horizontal, -2)
                }
                .buttonStyle(.plain)

                Text("Learn more under Al-Islam → Pillars and Beliefs.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: Reference lookup

    private func referenceSection(_ reference: HadithReferenceParser.Reference) -> some View {
        Section(header: Text("GO TO REFERENCE")) {
            // The reference names ONE hadith - show that hadith in full, exactly like a keyword
            // match, instead of a bare "go to" stub. Resolution mirrors HadithReferenceView; the
            // pack is mapped, not read, so the body-path open is cheap. No `searchText` on the row:
            // the number is the row's identity, not a text match (the BY NUMBER sections' rule).
            if let data = HadithStore.shared.book(reference.book),
               let resolved = resolvedReferenceHadith(reference, data: data) {
                NavigationLink {
                    // Land in the chapter, scrolled to the hadith - the keyword matches' arrival.
                    if let chapter = data.chapters.first(where: { $0.id == resolved.chapterId }) {
                        HadithChapterView(book: reference.book, bookData: data, chapter: chapter, scrollToHadithId: resolved.idInBook)
                    } else {
                        HadithReferenceView(book: reference.book, chapter: reference.chapter, hadith: reference.hadith, suffix: reference.suffix)
                    }
                } label: {
                    HadithRow(book: reference.book, hadith: resolved, compact: true).equatable()
                }
            } else {
                // Unresolvable number: keep the plain jump row - HadithReferenceView explains.
                NavigationLink {
                    HadithReferenceView(book: reference.book, chapter: reference.chapter, hadith: reference.hadith, suffix: reference.suffix)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "number")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(reference.chapter.map { "\(reference.book.englishTitle) - Chapter \($0), Hadith \(reference.hadith)" }
                                 ?? "\(reference.book.englishTitle) - Hadith \(reference.hadith)\(reference.suffix ?? "")")
                                .font(.subheadline.weight(.semibold))

                            Text(reference.book.arabicTitle)
                                .font(.caption)
                                .foregroundColor(settings.accentColor.color)
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
            guard data.chapters.indices.contains(chapter - 1) else { return nil }
            let inChapter = data.hadiths(in: data.chapters[chapter - 1])
            let offset = inChapter.startIndex + (reference.hadith - 1)
            guard reference.hadith >= 1, offset < inChapter.endIndex else { return nil }
            return inChapter[offset]
        }
        return data.hadith(referenced: reference.hadith, suffix: reference.suffix)
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
                Section(header: SectionPillHeader(title: "CHAPTER \(number)", count: globalNumberChapters.count, icon: "book.closed")) {
                    ForEach(globalNumberChapters) { hit in
                        NavigationLink {
                            HadithChapterView(book: hit.book, bookData: hit.data, chapter: hit.chapter)
                        } label: {
                            globalChapterRow(hit)
                        }
                    }
                }
            }

            // Hadiths cited N - one flat section; each compact `HadithRow` shows its own "10 <book>"
            // citation, so no per-book grouping is needed.
            if !globalNumberHadiths.isEmpty {
                Section(header: SectionPillHeader(title: "HADITH \(citedLabel)", count: globalNumberHadiths.count, icon: "number")) {
                    ForEach(globalNumberHadiths) { hit in
                        NavigationLink {
                            if let chapter = hit.data.chapters.first(where: { $0.id == hit.hadith.chapterId }) {
                                HadithChapterView(book: hit.book, bookData: hit.data, chapter: chapter, scrollToHadithId: hit.hadith.idInBook)
                            } else {
                                HadithReferenceView(book: hit.book, resolved: hit.hadith)
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
                    Text("No chapter or hadith is numbered \(citedLabel) in any collection.")
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
            if OnDeviceAsk.isAvailable {
                Section(header: hadithAskAIHeader) {
                    hadithAskPromptRow
                }
            }

            // While the one-time all-books index builds, the standard progress row shows in its place.
            if SemanticSearchEngine.isSupported, !query.containsArabicScript,
               !semanticEngine.isReady(allBooksCorpusID),
               isGatheringAllBooks || HadithSemanticCorpus.isGathering || semanticEngine.isBuilding(allBooksCorpusID) {
                Section { AISearchStatusRow(corpusID: allBooksCorpusID, failed: false) }
            }

            // Matching chapters sit ABOVE the AI/keyword switch, the Quran search's surah-list rule:
            // they are navigation, not a competing result kind, so they show in both modes.
            if !globalChapterResults.isEmpty {
                Section(header: SectionPillHeader(title: "MATCHING CHAPTERS", count: globalChapterResults.count, overflow: globalHasMoreChapters)) {
                    ForEach(globalChapterResults) { hit in
                        NavigationLink {
                            HadithChapterView(book: hit.book, bookData: hit.data, chapter: hit.chapter)
                        } label: {
                            globalChapterRow(hit)
                        }
                    }

                    HadithLoadMoreControls(label: "chapter matches", hasMore: globalHasMoreChapters, limit: Binding(
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
            let showResultsPicker = !globalAIResults.isEmpty && !globalHadithResults.isEmpty
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
                Section(header: SectionPillHeader(title: "AI MATCHES", count: globalAIResults.count, icon: "sparkles", accentTitle: true)) {
                    EmptyView()
                }
                .padding(.bottom, -12)

                ForEach(globalAIResultsGroupedByBook, id: \.book.slug) { group in
                    Section(header: bookSearchSectionHeader(book: group.book, matchCount: group.hits.count)) {
                        ForEach(group.hits) { hit in
                            NavigationLink {
                                if let chapter = hit.data.chapters.first(where: { $0.id == hit.hadith.chapterId }) {
                                    HadithChapterView(book: hit.book, bookData: hit.data, chapter: chapter, scrollToHadithId: hit.hadith.idInBook)
                                } else {
                                    HadithReferenceView(book: hit.book, resolved: hit.hadith)
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

            if keywordVisible, !globalHadithResults.isEmpty {
                // The Quran search's grammar: the TOTAL pill up top, then one section per book with its
                // own count - so results from different books never read as one undifferentiated list.
                Section(header: SectionPillHeader(title: "MATCHING HADITHS", count: globalHadithResults.count, overflow: globalHasMoreHadiths)) {
                    EmptyView()
                }
                .padding(.bottom, -12)

                ForEach(globalHadithResultsGroupedByBook, id: \.book.slug) { group in
                    Section(header: bookSearchSectionHeader(book: group.book, matchCount: group.hits.count)) {
                        ForEach(group.hits) { hit in
                            NavigationLink {
                                // Land in the chapter, scrolled to the hadith - the Quran search's arrival.
                                if let chapter = hit.data.chapters.first(where: { $0.id == hit.hadith.chapterId }) {
                                    HadithChapterView(book: hit.book, bookData: hit.data, chapter: chapter, scrollToHadithId: hit.hadith.idInBook)
                                } else {
                                    HadithReferenceView(book: hit.book, resolved: hit.hadith)
                                }
                            } label: {
                                HadithRow(book: hit.book, hadith: hit.hadith, searchText: searchText, compact: true).equatable()
                            }
                        }
                    }
                }

                Section {
                    HadithLoadMoreControls(label: "hadith matches", hasMore: globalHasMoreHadiths, limit: Binding(
                        get: { globalHadithLimit },
                        set: { newValue in
                            globalHadithLimit = newValue
                            runGlobalSearch(query: query, loadMore: true)
                        }
                    ))
                }
            }

            if !isGlobalSearching, globalSearchRanFor == query,
               globalChapterResults.isEmpty, globalHadithResults.isEmpty {
                Section(footer: Text("Searches every collection in the app.")) {
                    Text("No chapter or hadith matches in any collection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// "ASK AI" with the sparkles glyph - the Quran search's `askAIHeader`, verbatim.
    private var hadithAskAIHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("ASK AI")

            Spacer()
        }
        .foregroundStyle(settings.accentColor.color)
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

                Image(systemName: "chevron.right")
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
            Text(book.englishTitle.uppercased())

            Text(book.arabicTitle)
                .font(.caption)

            Spacer()

            // How many of the hadith matches live in THIS book - the total pill sits up top.
            CountPill(count: matchCount)
        }
    }

    /// A matched chapter from any book: chapter name over the book it belongs to, the
    /// chapter rows' Arabic trailing.
    private func globalChapterRow(_ hit: GlobalChapterHit) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HighlightedSnippet(
                source: hit.chapter.english,
                term: searchText,
                font: .subheadline.weight(.semibold),
                accent: settings.accentColor.color,
                fg: .primary,
                lineLimit: 1
            )

            HStack(alignment: .firstTextBaseline) {
                Text(hit.book.englishTitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .layoutPriority(1)

                Spacer(minLength: 8)

                if !hit.chapter.arabic.isEmpty {
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
                // Chapter.id IS the chapter number - but "8a" can only mean a citation, never a chapter.
                if suffix == nil, let chapter = data.chapters.first(where: { $0.id == number }) {
                    chapterHits.append(GlobalChapterHit(book: book, data: data, chapter: chapter))
                }
                // Citation-first: all the variants a base owns; a typed suffix narrows to that one.
                var cited = data.hadiths(citing: number)
                if let suffix {
                    cited = cited.filter { $0.citation == "\(number)\(suffix)" }
                } else if cited.isEmpty, let fallback = data.hadith(numbered: number) {
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
        let books = HadithCatalogBook.all
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
            if !loadMore {
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
                    while next < library.count {
                        let index = next
                        next += 1
                        guard let entry = library[index] else { continue }
                        let from = index == startBook ? startRow : 0
                        let data = entry.data
                        group.addTask {
                            let rows = data.matchingRows(in: from..<data.hadiths.count, query: folded, limit: needed)
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
                guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
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
            title: "BOOKMARKS",
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
                // "View All" push. In grid mode they render as tiles, like the Quran's bookmark grid.
                if hadithGridMode {
                    LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
                        ForEach(store.bookmarks) { bookmark in
                            HadithBookmarkGridTile(bookmark: bookmark) {
                                pushedReference = bookmark
                            }
                            .equatable()
                        }
                    }
                    .padding(.vertical, 4)
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
            if hadithGridMode {
                Section {
                    LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
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
                        .contextMenu { bookContextMenu(book) }
                        // The surah rows' swipe language: icon-only. Favorite on the leading edge,
                        // scroll-to on the trailing edge.
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) { store.toggleFavorite(book.slug) }
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
        Text(book.englishTitle)
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
            withAnimation(.easeInOut) { store.toggleFavorite(book.slug) }
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
        "\(book.englishTitle) (\(book.arabicTitle))\n\n\(book.authorEnglish) - \(book.era)\n\n\(book.longDescription)"
    }

    /// "97 Ch • 7,277 Ha" - the book's SHAPE (chapters and hadiths). The surah rows lead with ayah
    /// counts; books do the same. Chapters, then hadiths - the one order every hadith surface uses.
    private func bookShapeText(_ book: HadithCatalogBook) -> String {
        guard let counts = store.counts(for: book) else { return "" }
        return "\(counts.chapters) Ch • \(counts.hadiths.formatted()) Ha"
    }

    /// One small glass chip in the shared stat-pill language.
    /// Deliberately tight: three of these share one row with the title and the Arabic name, and the pill
    /// padding was what pushed the counts into ellipses ("7,27...") the moment the row got narrow.
    private func statChip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(settings.accentColor.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .conditionalGlassEffect()
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
                    withAnimation(.easeInOut) { store.toggleFavorite(book.slug) }
                }
                .accessibilityLabel("Book \(book.number)\(isLastRead ? ", last read" : "")")

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

    private func bookRow(_ book: HadithCatalogBook) -> some View {
        HStack(alignment: .center) {
            bookNumberPill(book)
                .padding(.trailing, 2)

            VStack(alignment: .leading, spacing: 4) {
                // Two lines reserved for the title, so "Forty Hadith Qudsi" never stacks a word per line.
                HighlightedSnippet(
                    source: book.englishTitle,
                    term: searchText,
                    font: .subheadline.weight(.semibold),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    lineLimit: 2
                )
                .minimumScaleFactor(0.7)

                // Separate chips - chapters, then hadiths - one stat per pill. There is no third
                // (size) chip any more: every book ships in the app, so its download weight is not a
                // fact the reader has to decide anything with.
                HStack(spacing: 4) {
                    if let counts = store.counts(for: book) {
                        statChip("\(counts.chapters) Ch")
                        statChip("\(counts.hadiths.formatted()) Ha")
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .layoutPriority(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                HighlightedSnippet(
                    source: book.arabicTitle,
                    term: searchText,
                    font: arabicTitleFont(.subheadline, bump: 2),
                    accent: settings.accentColor.color,
                    fg: settings.accentColor.color,
                    lineLimit: 2
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
            }
            .minimumScaleFactor(0.5)
            .padding(.leading, 8)
        }
        .contentShape(Rectangle())
    }

    /// A compact tile in the 99-Names style: Arabic, English, and the number stacked centered - a
    /// Button that pushes through the hidden `pushedBook` link, so no List chevron ever appears.
    private func bookGridTile(_ book: HadithCatalogBook) -> some View {
        Button {
            settings.hapticFeedback()
            pushedBook = book
        } label: {
            VStack(spacing: 3) {
                HighlightedSnippet(
                    source: book.arabicTitle,
                    term: searchText,
                    font: arabicTitleFont(.body, bump: 3),
                    accent: settings.accentColor.color,
                    fg: settings.accentColor.color
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                HighlightedSnippet(
                    source: book.englishTitle,
                    term: searchText,
                    font: .caption.weight(.semibold),
                    accent: settings.accentColor.color,
                    fg: .primary
                )
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.55)

                HStack(spacing: 4) {
                    Text("\(book.number)")
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundColor(settings.accentColor.color)

                    Text("• \(bookShapeText(book))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            // A fixed height so every tile in the grid lines up regardless of how its titles wrap.
            .frame(height: 84)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .conditionalGlassEffect(
            clear: !store.isFavorite(book.slug),
            rectangle: true,
            useColor: store.isFavorite(book.slug) ? 0.25 : nil,
            customTint: store.isFavorite(book.slug) ? settings.accentColor.color : nil
        )
        .gridFavoriteStar(
            isFavorite: store.isFavorite(book.slug),
            accent: settings.accentColor.color,
            accessibilityName: book.englishTitle
        ) {
            store.toggleFavorite(book.slug)
        }
        // No context menu on grid tiles - the long-press preview snapshot fought the tile's glass and
        // the row form still carries the full menu.
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
    static let id = "hadith-all"

    /// Version keyed to the shelf itself - deterministic (never hashValue, which is seeded per
    /// launch), so yesterday's build loads from disk today.
    static var version: String {
        "all3-" + HadithCatalogBook.all.map(\.slug).sorted().joined(separator: ".")
    }

    /// True while the slow path (reading every book to gather texts) runs, pre-embedding.
    private(set) static var isGathering = false

    /// The instant half of `prepare`: load a persisted build from disk (off the main actor, awaited
    /// here) so a caller can search the corpus as soon as this returns. True when the corpus is
    /// ready afterwards. (`texts` is an autoclosure the engine evaluates only when no persisted
    /// build exists, and an empty list starts no build.)
    @discardableResult
    static func probeDisk(engine: SemanticSearchEngine) async -> Bool {
        guard SemanticSearchEngine.isSupported else { return false }
        if !engine.isReady(id), !engine.isBuilding(id) {
            engine.prepare(corpusID: id, version: version, texts: [])
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
        engine.prepare(corpusID: id, version: version, texts: built.texts, keys: built.keys)
        return true
    }
}
