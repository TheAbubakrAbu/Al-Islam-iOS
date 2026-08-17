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
    @State private var isGlobalSearching = false
    @State private var globalSearchRanFor = ""
    @State private var globalSearchTask: Task<Void, Never>?

    // The tab-wide AI matches: ONE combined corpus over EVERY book (built once and persisted, and
    // the shelf can no longer change under it) - so "controlling anger" searches all
    // hadiths at once, which is what a tab-level search means 9 times out of 10.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var globalAIResults: [GlobalHadithHit] = []

    // Ask (the on-device LLM) - the Quran search's Ask, for hadiths: auto-runs for question-shaped
    // queries, one tap for everything else - grounded in the retrieved hadiths and cited when
    // retrieval found any, an open general-knowledge answer (clearly labeled, quote-free) when it
    // found none. Exists only on Apple Intelligence devices (`OnDeviceAsk.isAvailable`).
    @State private var hadithAskAnswer = ""
    @State private var hadithAskIsStreaming = false
    @State private var hadithAskRanForQuery = ""
    /// A MANUAL ask where the model declined or errored - the tapped row must answer with
    /// SOMETHING instead of silently restoring the prompt (the Quran search's `askNoAnswer`).
    @State private var hadithAskNoAnswer = false
    /// Whether the current answer was grounded in retrieved hadiths (drives the card's footer).
    @State private var hadithAskGrounded = true
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist (the Quran search's
    /// `showKeywordResults`). Reset to the AI list on every new query.
    @State private var showHadithKeywordResults = false
    @State private var hadithAskTask: Task<Void, Never>?
    /// The hadiths the running answer was grounded on - the pool citations are resolved from, so a
    /// cited row can never point at a hadith the model wasn't shown.
    @State private var hadithAskSourceHits: [GlobalHadithHit] = []
    @State private var globalAITask: Task<Void, Never>?
    /// True while the slow path (reading every book to gather texts) runs, pre-embedding.
    @State private var isGatheringAllBooks = false

    private var allBooksCorpusID: String { "hadith-all" }

    /// Version keyed to the shelf itself - deterministic (never hashValue, which is seeded per
    /// launch), so yesterday's build loads from disk today.
    private var allBooksCorpusVersion: String {
        "all3-" + HadithCatalogBook.all.map(\.slug).sorted().joined(separator: ".")
    }

    /// Load-or-build the all-books corpus. The disk hit is instant; the cold build reads each book
    /// once (off the visible path) and then embeds a SHARED vocabulary - the books overlap heavily in
    /// words, so all-of-them costs little more than Bukhari alone.
    private func prepareAllBooksCorpus() {
        guard SemanticSearchEngine.isSupported,
              !semanticEngine.isReady(allBooksCorpusID),
              !semanticEngine.isBuilding(allBooksCorpusID),
              !isGatheringAllBooks else { return }
        let books = HadithCatalogBook.all

        // Disk-first probe: `texts` is an autoclosure evaluated only past the disk check, so this
        // costs nothing when a persisted build exists.
        semanticEngine.prepare(corpusID: allBooksCorpusID, version: allBooksCorpusVersion, texts: [])
        guard !semanticEngine.isReady(allBooksCorpusID) else { return }

        isGatheringAllBooks = true
        Task {
            // The books are opened on the main actor (that is where the store lives), but the TEXT is
            // gathered off it: this walks all 50,884 hadiths, and over the packs that decompresses the
            // whole library. Inline, it was a second of main thread in ~100 ms hitches.
            let opened = books.compactMap { book in store.book(book).map { (book.slug, $0) } }
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
            semanticEngine.prepare(corpusID: allBooksCorpusID, version: allBooksCorpusVersion,
                                   texts: built.texts, keys: built.keys)
            isGatheringAllBooks = false
            runGlobalAISearch(query: searchText)
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

    /// The Quran search's `runAsk`, for hadiths: grounded strictly on the retrieved hadiths (AI
    /// matches first, then keyword matches), streaming the answer card in `globalSearchSection`.
    private func runHadithAsk(query: String, manual: Bool) {
        hadithAskTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // Any new run (or keystroke) clears a previous dead-end notice. Plain writes throughout: the
        // Ask card is a List section, and animated section churn racing the async result applies is
        // the collection-view assertion crash the Quran search hit.
        hadithAskNoAnswer = false
        guard OnDeviceAsk.isAvailable, trimmed.count >= 3,
              manual || OnDeviceAsk.looksLikeQuestion(trimmed) else {
            if !hadithAskRanForQuery.isEmpty {
                hadithAskAnswer = ""; hadithAskIsStreaming = false; hadithAskRanForQuery = ""; hadithAskSourceHits = []
            }
            return
        }

        hadithAskTask = Task {
            // Auto waits out the search debounces so the retrieval this answer is GROUNDED on has
            // settled; a manual tap means the results are already on screen - go immediately.
            try? await Task.sleep(nanoseconds: manual ? 100_000_000 : 900_000_000)
            guard !Task.isCancelled else { return }

            var sources: [OnDeviceAsk.Source] = []
            var sourceHits: [GlobalHadithHit] = []
            var seen = Set<String>()
            for hit in globalAIResults.prefix(6) {
                let reference = "\(hit.book.englishTitle) \(hit.hadith.displayNumber)"
                if seen.insert(reference).inserted, !hit.hadith.english.text.isEmpty {
                    sources.append(.init(reference: reference, text: hit.hadith.english.text))
                    sourceHits.append(hit)
                }
            }
            for hit in globalHadithResults.prefix(6) {
                let reference = "\(hit.book.englishTitle) \(hit.hadith.displayNumber)"
                if seen.insert(reference).inserted, !hit.hadith.english.text.isEmpty {
                    sources.append(.init(reference: reference, text: hit.hadith.english.text))
                    sourceHits.append(hit)
                }
            }
            // Nothing retrieved is no longer a dead end: the ask still runs, in OPEN mode - a clearly
            // labeled general-knowledge answer with no recreated quotes (the engine's open rules).

            hadithAskGrounded = !sources.isEmpty
            hadithAskAnswer = ""
            hadithAskIsStreaming = true
            hadithAskRanForQuery = trimmed
            hadithAskSourceHits = sourceHits
            guard #available(iOS 26.0, *) else { return }
            do {
                for try await text in OnDeviceAsk.streamAnswer(question: trimmed, sources: sources) {
                    guard !Task.isCancelled else { return }
                    hadithAskAnswer = text
                }
                guard !Task.isCancelled else { return }
                hadithAskIsStreaming = false
            } catch {
                // Declined or errored: the card goes away - AI and keyword results still stand. But a
                // MANUAL ask still owes a response (see the empty-sources guard).
                guard !Task.isCancelled else { return }
                hadithAskAnswer = ""; hadithAskIsStreaming = false; hadithAskRanForQuery = ""; hadithAskSourceHits = []
                if manual { hadithAskNoAnswer = true }
            }
        }
    }

    /// The hadiths the streamed answer actually cited, in citation order - the Quran's `askCitedAyahs`,
    /// for hadiths. Citations are matched against the exact source references the model was given
    /// ("Sahih al-Bukhari 6114"), so every resolved row is guaranteed to open a real hadith. The
    /// digit-boundary check keeps "…6114" from also matching a claimed "611".
    private var hadithAskCitedResults: [GlobalHadithHit] {
        guard !hadithAskAnswer.isEmpty else { return [] }
        let answer = hadithAskAnswer.lowercased()
        var cited: [(position: Int, hit: GlobalHadithHit)] = []
        for hit in hadithAskSourceHits {
            let reference = "\(hit.book.englishTitle) \(hit.hadith.displayNumber)".lowercased()
            guard let range = answer.range(of: reference) else { continue }
            if range.upperBound < answer.endIndex, answer[range.upperBound].isNumber { continue }
            cited.append((answer.distance(from: answer.startIndex, to: range.lowerBound), hit))
        }
        return cited.sorted { $0.position < $1.position }.prefix(10).map(\.hit)
    }

    /// Today's hadith lives in the STORE, resolved at app launch - the tab
    /// renders it instantly.
    private var dailyHadith: (book: HadithCatalogBook, hadith: HadithBookData.Hadith)? { store.daily }
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
                Text("Quick Search Help")
                    .font(.subheadline.bold())
                    .foregroundStyle(settings.accentColor.color)

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
        ScrollViewReader { scrollProxy in
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
                // The Quran tab's exact bottom-bar grammar: recent-search chips above the field while it
                // is focused (kept mounted, collapsed via height+opacity - glass can't transition).
                let chipsVisible = isHadithSearchFocused && !settings.hadithSearchHistory.isEmpty
                VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                    HadithSearchHistoryChips(searchText: $searchText)
                        .frame(height: chipsVisible ? nil : 0)
                        .clipped()
                        .opacity(chipsVisible ? 1 : 0)
                        .allowsHitTesting(chipsVisible)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: chipsVisible)
                        .padding(.horizontal, 24)

                    SearchBar(
                        // Animated like the Quran tab's bar, same gate: Low Power Mode / Reduce Motion
                        // keep typing free of animated whole-list diffs. The synchronous per-keystroke
                        // part here is only the ~20-book catalog filter; the async sweep results animate
                        // at their apply site.
                        text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                        onFocusChanged: { focused in
                            withAnimation { isHadithSearchFocused = focused }
                            // Start the one-time all-books AI index (or its instant disk load) the
                            // moment the field is focused - usually ready before the first query.
                            if focused { prepareAllBooksCorpus() }
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
                // Same no-op rule: the launch task usually already warmed the likely books.
                store.prewarmBooks()
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
                globalSearchRanFor = ""
                // Every new query starts back on the AI list, with any dead-end ask notice cleared.
                showHadithKeywordResults = false
                hadithAskNoAnswer = false
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
                    // Question-shaped queries stream a grounded answer automatically; anything else keeps
                    // the one-tap Ask row (and this call clears a previous answer).
                    runHadithAsk(query: text, manual: false)
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

                    // When only one language is visible (toggle off, or the entry lacks one), that
                    // single preview reserves four lines so every history row keeps the same height
                    // as a two-language one. With both visible, each keeps its usual two.
                    let showsArabic = settings.showHadithArabic && !entry.arabicPreview.isEmpty
                    let showsEnglish = settings.showHadithEnglish && !entry.englishPreview.isEmpty

                    if showsArabic {
                        HadithArabicPreview(text: entry.arabicPreview, lineLimit: showsEnglish ? 2 : 4)
                    }

                    if showsEnglish {
                        Text(entry.englishPreview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .reservedLineLimit(showsArabic ? 2 : 4)
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
                        arabic: settings.showHadithArabic ? String(dailyHadith.hadith.arabic.prefix(120)) : "",
                        english: settings.showHadithEnglish ? String(dailyHadith.hadith.english.text.prefix(140)) : ""
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

                // A tile showing only one language (toggle off, or nothing stored for the other)
                // reserves four lines for it, so the two tiles in the grid stay the same height.
                // With both languages, each keeps its usual two.
                if !arabic.isEmpty {
                    HadithArabicPreview(text: arabic, lineLimit: english.isEmpty ? 4 : 2)
                }

                if !english.isEmpty {
                    Text(english)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .reservedLineLimit(arabic.isEmpty ? 4 : 2)
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
            // Ask AI first - the streamed grounded answer WITH its cited hadiths (real tappable rows);
            // the citations are the answer's receipts, so they live in the same section - the Quran
            // search's exact grammar.
            if OnDeviceAsk.isAvailable {
                if hadithAskNoAnswer {
                    Section(header: hadithAskAIHeader(citedCount: 0)) {
                        hadithAskNoAnswerRow
                    }
                } else if !hadithAskRanForQuery.isEmpty {
                    let cited = hadithAskCitedResults
                    Section(header: hadithAskAIHeader(citedCount: cited.count)) {
                        AskAnswerCard(answer: hadithAskAnswer, isStreaming: hadithAskIsStreaming, grounded: hadithAskGrounded)

                        ForEach(cited) { hit in
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
                } else {
                    // ALWAYS present while searching, results or none - the ask is an invitation,
                    // not a result; with nothing retrieved it answers in the engine's open mode.
                    Section(header: hadithAskAIHeader(citedCount: 0)) {
                        hadithAskPromptRow
                    }
                }
            }

            // While the one-time all-books index builds, the standard progress row shows in its place.
            if SemanticSearchEngine.isSupported, !query.containsArabicScript,
               !semanticEngine.isReady(allBooksCorpusID),
               isGatheringAllBooks || semanticEngine.isBuilding(allBooksCorpusID) {
                Section { AISearchStatusRow(progress: semanticEngine.progress(allBooksCorpusID), failed: false) }
            }

            // Both result kinds landed: ONE segmented switch decides which list fills the page - the
            // AI's ranked meaning matches or the exhaustive keyword lists - never both stacked. With
            // only one kind present there is nothing to choose, so no picker (the Quran search's rule).
            let showResultsPicker = !globalAIResults.isEmpty
                && (!globalHadithResults.isEmpty || !globalChapterResults.isEmpty)
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

            if keywordVisible, !globalChapterResults.isEmpty {
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
                            runGlobalSearch(query: query)
                        }
                    ))
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
                            runGlobalSearch(query: query)
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

    /// "ASK AI" with the sparkles glyph; the pill counts the answer's cited hadiths once they exist -
    /// the Quran search's `askAIHeader`, verbatim (accent tint on the whole header included).
    private func hadithAskAIHeader(citedCount: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("ASK AI")

            Spacer()

            if citedCount > 0 {
                Text(String(citedCount))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .conditionalGlassEffect()
                    .padding(.vertical, -16)
            }
        }
        .foregroundStyle(settings.accentColor.color)
    }

    /// Shown when a manual ask dead-ends: nothing retrieved matched the query, so there was nothing to
    /// answer from. Editing the query clears it (`runHadithAsk` resets the flag on every run).
    private var hadithAskNoAnswerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("AI couldn't answer \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D} right now. Try different wording, or try again.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .conditionalGlassEffect(clear: true, rectangle: true)
    }

    /// The one-tap Ask entry for non-question queries: press to run the grounded on-device answer for
    /// exactly what's typed - the Quran search's row, verbatim.
    private var hadithAskPromptRow: some View {
        Button {
            settings.hapticFeedback()
            runHadithAsk(query: searchText, manual: true)
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

    /// The automatic all-books sweep: debounced, script-aware, early-exiting at one past each page,
    /// and matched against the folds built into the packs - so a keystroke is a byte search, never a
    /// normalization pass over the library.
    private func runGlobalSearch(query: String) {
        globalSearchTask?.cancel()
        isGlobalSearching = true

        // "Load all" sets a limit to Int.max - clamped here so the one-past-the-cap arithmetic below
        // (`cap + 1`) can't overflow and trap.
        let chapterCap = min(globalChapterLimit, Int.max - 1)
        let hadithCap = min(globalHadithLimit, Int.max - 1)
        // Folded exactly as the packs' text was folded (punctuation stripped, script-aware), so
        // "aishah" finds "'A'ishah" - one fold of the query, then byte compares from here on.
        let folded = HadithFold.query(query)

        globalSearchTask = Task {
            // Debounce: typing restarts this task, so only a settled query pays for the sweep.
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            var chapterHits: [GlobalChapterHit] = []
            var hadithHits: [GlobalHadithHit] = []

            for book in HadithCatalogBook.all {
                if Task.isCancelled { return }
                if chapterHits.count > chapterCap, hadithHits.count > hadithCap { break }
                guard let data = HadithStore.shared.book(book) else { continue }

                // ONE detached scan per book covering chapters AND hadiths. Cancellation is bridged in
                // explicitly: detached tasks don't inherit it.
                let needChapters = chapterHits.count <= chapterCap
                let needHadiths = hadithHits.count <= hadithCap
                let chapterNeeded = chapterCap + 1 - chapterHits.count
                let hadithNeeded = hadithCap + 1 - hadithHits.count

                let scan = Task.detached(priority: .userInitiated) { () -> (chapters: [HadithBookData.Chapter], hadiths: [HadithBookData.Hadith]) in
                    var chapters: [HadithBookData.Chapter] = []
                    if needChapters {
                        for chapter in data.chapters {
                            if Task.isCancelled { break }
                            if data.matches(chapter, folded) {
                                chapters.append(chapter)
                                if chapters.count >= chapterNeeded { break }
                            }
                        }
                    }

                    var hadiths: [HadithBookData.Hadith] = []
                    if needHadiths {
                        for hadith in data.hadiths {
                            if Task.isCancelled { break }
                            if data.matches(hadith, folded) {
                                hadiths.append(hadith)
                                if hadiths.count >= hadithNeeded { break }
                            }
                        }
                    }
                    return (chapters, hadiths)
                }
                let found = await withTaskCancellationHandler {
                    await scan.value
                } onCancel: {
                    scan.cancel()
                }

                for chapter in found.chapters {
                    chapterHits.append(GlobalChapterHit(book: book, data: data, chapter: chapter))
                }
                for hadith in found.hadiths {
                    hadithHits.append(GlobalHadithHit(book: book, data: data, hadith: hadith))
                }
            }

            guard !Task.isCancelled else { return }
            let finalChapters = chapterHits
            let finalHadiths = hadithHits
            // Fold the shown hits' texts into the highlight caches OFF-main, so each result row's
            // first render is a cache hit instead of paying the normalization during scrolling.
            // Task.detached, because THIS task inherits the view's @MainActor - `nonisolated` on the
            // prewarm makes the call legal, not off-main.
            var prewarmSources: [String] = []
            prewarmSources.reserveCapacity(min(finalHadiths.count, hadithCap) * 3)
            for hit in finalHadiths.prefix(hadithCap) {
                let strings = hit.hadith.allText
                prewarmSources.append(strings.arabic)
                prewarmSources.append(strings.text)
                prewarmSources.append(strings.narrator)
            }
            let sources = prewarmSources
            Task.detached(priority: .utility) {
                HighlightedSnippet.prewarmNormalization(of: sources)
            }
            await MainActor.run {
                guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                // Plain apply: the AI pipeline and this sweep land in separate passes, and an animated
                // structural diff racing another is the collection-view assertion crash the Quran
                // search hit (type/delete/type).
                globalChapterResults = Array(finalChapters.prefix(chapterCap))
                globalHadithResults = Array(finalHadiths.prefix(hadithCap))
                globalHasMoreChapters = finalChapters.count > chapterCap
                globalHasMoreHadiths = finalHadiths.count > hadithCap
                globalSearchRanFor = query
                isGlobalSearching = false
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
