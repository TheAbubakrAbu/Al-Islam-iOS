import SwiftUI

// One collection: the chapter list (with in-place page mode), one chapter, and the right-to-left
// paged reader that fits as many hadiths per page as the font sizes allow.

#if os(iOS)

fileprivate extension HadithBookData.Hadith {
    /// The BASE of the number a reader would cite for this hadith: the citation with its variant
    /// letter dropped ("8a" -> 8), or `idInBook` for the rows that carry no citation - what the
    /// chapter range labels ("Hadiths 100-200") are built from.
    var citedBaseNumber: Int {
        citation.flatMap { Int($0.prefix(while: { $0.isASCII && $0.isNumber })) } ?? idInBook
    }
}

// MARK: - One collection: chapters + book search + page mode

struct HadithBookView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared
    /// Chapter favorites render through the store's forwards; the data publishes from HadithUserData,
    /// so this observation is what re-renders the pills/tiles when a favorite toggles.
    @ObservedObject private var userData = HadithUserData.shared

    let book: HadithCatalogBook

    @State private var searchText = ""
    /// The chapter list shares the tab's grid/list choice, with its own copy of the toggle up top.
    @AppStorage("hadithGridMode") private var hadithGridMode = false
    /// How chapters open. Hadiths are prose of wildly varying length, not the mushaf's fixed page, so the
    /// scrolling LIST is the default here (unlike the Quran, where pages are the canonical layout); the
    /// paged reader is opt-in. The toggle sits top left exactly as it does in the chapter itself, but
    /// flips the setting rather than this screen.
    @AppStorage("hadithPageMode") private var hadithPageMode = false
    /// Drives the "Switch to Page/List View?" confirmation before the reading mode actually flips.
    @State private var showReadingModeConfirm = false
    /// The hidden push target the chapter grid tiles use (a NavigationLink cell would draw a chevron).
    @State private var pushedChapter: HadithBookData.Chapter?
    /// "Scroll to chapter": clears the search, then lands the list on this chapter.
    @State private var pendingScrollToChapterId: Int? = nil
    @State private var showHadithSettings = false
    /// The Quran search's page size: matches show 5 at a time until Load More asks for more.
    @State private var chapterMatchLimit = 5
    @State private var hadithMatchLimit = 5
    /// The in-book keyword results, filled by `runInBookSearch` (debounced + off-main).
    @State private var inBookMatches: (shown: [HadithBookData.Hadith], hasMore: Bool) = ([], false)
    @State private var inBookSearchTask: Task<Void, Never>?

    // MARK: iPad/Mac two columns - chapters left, hadiths right

    /// True when the Hadith tab is running as a `NavigationSplitView` (iPad/Mac), which makes this screen
    /// the split's CONTENT column: chapters here, the chapter's hadiths in the detail column beside them.
    /// Read from the environment, never from this screen's own size class - a split view's columns report
    /// their own (often compact) width, which would flip these rows back to pushing inside the column.
    @Environment(\.hadithUsesColumnNavigation) private var usesColumnNavigation
    /// What the detail column is reading, shared with the tab root that hosts it.
    @ObservedObject private var columnSelection = HadithColumnSelection.shared

    /// Point the detail column at a chapter. `userInitiated` defaults true because every call here is
    /// a tap (rows, grid tiles, deep-linked references) except the onAppear default below - a re-tap
    /// of the identical chapter must still land (rebuild + re-scroll), never die silently.
    private func selectChapter(_ chapter: HadithBookData.Chapter, data: HadithBookData, scrollToHadithId: Int? = nil, userInitiated: Bool = true) {
        columnSelection.select(book: book, bookData: data, chapter: chapter, scrollToHadithId: scrollToHadithId, userInitiated: userInitiated)
    }

    /// What the detail column reads when this book opens without a chapter picked - the book's remembered
    /// spot, else its first chapter.
    private func selectDefaultChapter(_ data: HadithBookData) {
        if let lastRead = store.lastRead(for: book.slug),
           let chapter = data.chapters.first(where: { $0.id == lastRead.chapterId }) {
            selectChapter(chapter, data: data, scrollToHadithId: lastRead.idInBook, userInitiated: false)
        } else if let first = data.chapters.first {
            selectChapter(first, data: data, userInitiated: false)
        }
    }

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// True while the bottom search field has the keyboard - the recent-searches chips only show then.
    @State private var isBookSearchFocused = false
    /// The last query written to the shared hadith search history (avoid rewrites while editing).
    @State private var lastSavedSearchQuery = ""

    // AI (semantic) hadith search - the Quran ayah search's AI results, for this book: on-device meaning
    // matching over the hadith English texts, shown automatically above the keyword matches. No mode to
    // enter; the section appears (with one-time build progress the first time) whenever it can help.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var aiHits: [HadithBookData.Hadith] = []
    @State private var aiSearchTask: Task<Void, Never>?

    private var semanticCorpusID: String { "hadith-\(book.slug)" }

    /// True when the live query is one the semantic engine can answer (English text, long enough).
    private var aiQueryEligible: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return SemanticSearchEngine.isSupported
            && trimmed.count >= 3
            && !trimmed.containsArabicScript
            // "1234" (or "8a") is a hadith citation, not a question - it gets an exact lookup, so
            // there is nothing for the semantic engine (or the Ask row) to be asked about.
            && HadithBookData.citationNumber(inQuery: trimmed) == nil
    }

    private func prepareSemanticCorpus(_ data: HadithBookData) {
        prepareBookSemanticCorpus(semanticEngine, data: data, corpusID: semanticCorpusID)
    }

    // Ask (the on-device LLM, grounded RAG): question-shaped queries stream an answer card above the
    // matches, drawn strictly from THIS book's retrieved hadiths - the Quran search's exact feature.
    @State private var askAnswer = ""
    @State private var askIsStreaming = false
    @State private var askRanForQuery = ""
    /// A MANUAL ask that found nothing to ground on or errored - the tapped row must answer with
    /// SOMETHING instead of silently restoring the prompt (the Quran search's `askNoAnswer`).
    @State private var askNoAnswer = false
    /// Whether the current answer was grounded in retrieved hadiths (drives the card's footer).
    @State private var askGrounded = true
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist (the Quran search's
    /// `showKeywordResults`). Reset to the AI list on every new query.
    @State private var showBookKeywordResults = false
    @State private var askTask: Task<Void, Never>?
    /// The hadiths the answer was grounded on, kept so the answer's citations can resolve back to
    /// REAL rows - the global hadith search's `hadithAskSourceHits`, for this book.
    @State private var askSourceHadiths: [HadithBookData.Hadith] = []

    /// The hadiths the streamed answer actually cited, in citation order - matched against the exact
    /// source references the model was given ("Sahih al-Bukhari 6114"). The digit-boundary check
    /// keeps "…6114" from also matching a claimed "611".
    private var askCitedHadiths: [HadithBookData.Hadith] {
        guard !askAnswer.isEmpty else { return [] }
        let answer = askAnswer.lowercased()
        var cited: [(position: Int, hadith: HadithBookData.Hadith)] = []
        for hadith in askSourceHadiths {
            let reference = "\(book.englishTitle) \(hadith.displayNumber)".lowercased()
            guard let range = answer.range(of: reference) else { continue }
            if range.upperBound < answer.endIndex, answer[range.upperBound].isNumber { continue }
            cited.append((answer.distance(from: answer.startIndex, to: range.lowerBound), hadith))
        }
        return cited.sorted { $0.position < $1.position }.prefix(10).map(\.hadith)
    }

    private func runAskIfNeeded(query: String, data: HadithBookData?) {
        runAsk(query: query, data: data, manual: false)
    }

    /// Auto mode runs only for QUESTION-shaped queries; `manual` (the tapped "Ask AI" row) runs for
    /// anything - the user explicitly asked.
    private func runAsk(query: String, data: HadithBookData?, manual: Bool) {
        askTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // Any new run (or keystroke) clears a previous dead-end notice. Plain writes throughout: the
        // Ask card is a List section, and animated section churn racing the async result applies is
        // the collection-view assertion crash the Quran search hit.
        askNoAnswer = false
        guard OnDeviceAsk.isAvailable, trimmed.count >= 3, data != nil,
              manual || OnDeviceAsk.looksLikeQuestion(trimmed) else {
            if !askRanForQuery.isEmpty {
                askAnswer = ""; askIsStreaming = false; askRanForQuery = ""
            }
            return
        }

        askTask = Task {
            // Auto waits out the search debounces; a manual tap goes immediately.
            try? await Task.sleep(nanoseconds: manual ? 100_000_000 : 900_000_000)
            guard !Task.isCancelled else { return }

            var sources: [OnDeviceAsk.Source] = []
            var sourceHadiths: [HadithBookData.Hadith] = []
            var seen = Set<Int>()
            for hadith in aiHits.prefix(6) where seen.insert(hadith.idInBook).inserted {
                sources.append(.init(reference: "\(book.englishTitle) \(hadith.displayNumber)",
                                     text: hadith.english.text.isEmpty ? hadith.english.narrator : hadith.english.text))
                sourceHadiths.append(hadith)
            }
            // From the already-settled STATE (the 200ms scan finishes well inside this 900ms wait),
            // not the synchronous full-book scan - Ask's auto path is not a user gesture.
            for hadith in inBookMatches.shown.prefix(6) where seen.insert(hadith.idInBook).inserted {
                sources.append(.init(reference: "\(book.englishTitle) \(hadith.displayNumber)",
                                     text: hadith.english.text.isEmpty ? hadith.english.narrator : hadith.english.text))
                sourceHadiths.append(hadith)
            }
            // Nothing retrieved is no longer a dead end: the ask still runs, in OPEN mode - a clearly
            // labeled general-knowledge answer with no recreated quotes (the engine's open rules).

            askGrounded = !sources.isEmpty
            askAnswer = ""; askIsStreaming = true; askRanForQuery = trimmed
            askSourceHadiths = sourceHadiths
            guard #available(iOS 26.0, *) else { return }
            do {
                for try await text in OnDeviceAsk.streamAnswer(question: trimmed, sources: sources) {
                    guard !Task.isCancelled else { return }
                    askAnswer = text
                }
                guard !Task.isCancelled else { return }
                askIsStreaming = false
            } catch {
                guard !Task.isCancelled else { return }
                askAnswer = ""; askIsStreaming = false; askRanForQuery = ""; askSourceHadiths = []
                if manual { askNoAnswer = true }
            }
        }
    }

    private func runAISearch(query: String, data: HadithBookData?) {
        aiSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SemanticSearchEngine.isSupported, let data,
              trimmed.count >= 3, !trimmed.containsArabicScript else {
            if !aiHits.isEmpty { aiHits = [] }
            return
        }
        prepareSemanticCorpus(data)
        let corpusID = semanticCorpusID

        aiSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let results = await semanticEngine.search(corpusID: corpusID, query: trimmed, limit: 10)
            guard !Task.isCancelled else { return }
            // Resolve through the corpus KEYS (idInBook), falling back to position only for a corpus
            // persisted before keys existed - position is wrong the moment the source reorders.
            let keys = await MainActor.run { semanticEngine.corpus(corpusID)?.itemKeys }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                // Plain apply: an animated section insert racing the keyword scan's own apply is the
                // collection-view assertion crash the Quran search hit.
                aiHits = results.compactMap { result in
                    if let keys, keys.indices.contains(result.index), let idInBook = Int(keys[result.index]) {
                        return data.hadiths.first(where: { $0.idInBook == idInBook })
                    }
                    return data.hadiths.indices.contains(result.index) ? data.hadiths[result.index] : nil
                }
            }
        }
    }

    /// When set, the book view auto-pushes the hadith's CHAPTER (scrolled to the hadith) as soon as its
    /// data is ready - so a hadith opened from the tab root lands as Books → Chapters → Hadiths, and
    /// backing out of the hadith shows the chapter list instead of skipping it.
    var autoOpenHadithID: Int? = nil
    @State private var didAutoOpen = false
    @State private var autoOpenTarget: HadithBookData.Chapter?

    /// iOS 16 stack mode's push channel: the tab root hands this in and appends a chapter ROUTE to its
    /// `NavigationStack` path. Path state is the fix for the deep-link pop - a hidden
    /// `NavigationLink(isActive:)` could be handed a spurious `false` whenever a store publish
    /// re-rendered these screens mid-push, which unwound the freshly opened chapter no matter how the
    /// publish was debounced or where the link was anchored. Nil on iOS 15 (hidden links remain) and in
    /// column mode (chapters swap the detail column instead of pushing).
    var onPushChapter: ((HadithBookData.Chapter, Int?) -> Void)? = nil

    init(book: HadithCatalogBook, autoOpenHadithID: Int? = nil, onPushChapter: ((HadithBookData.Chapter, Int?) -> Void)? = nil) {
        self.book = book
        self.autoOpenHadithID = autoOpenHadithID
        self.onPushChapter = onPushChapter
    }

    /// The open book. Every collection ships in the app, so this is a dictionary hit over an
    /// already-mapped pack - which is why it can be computed rather than loaded into `@State`: it is
    /// always THIS `book`'s data. Held in state, a screen re-created for a different collection (the
    /// split view's content column, which reuses one view identity across pushes) would go on
    /// rendering the previous book's chapters.
    private var data: HadithBookData? { store.book(book) }

    /// Everything the chapter rows read per render, computed ONCE per book. It is now built from the
    /// CHAPTER table alone - each chapter carries the row range the packer measured, so this is one
    /// pass over ~97 chapters instead of the 7,500-hadith walk it used to be (which itself replaced a
    /// walk per row, per render).
    struct ChapterStats {
        let counts: [Int: Int]
        let ranges: [Int: ClosedRange<Int>]
        let ordinals: [Int: Int]

        init(_ data: HadithBookData) {
            var counts: [Int: Int] = [:]
            var ranges: [Int: ClosedRange<Int>] = [:]
            var ordinals: [Int: Int] = [:]
            for (offset, chapter) in data.chapters.enumerated() {
                counts[chapter.id] = chapter.rowCount
                ordinals[chapter.id] = offset + 1
                // Citation BASE numbers - the numbers readers actually cite - with idInBook standing
                // in per row where no citation exists (so books without citations behave exactly as
                // before). Min/max over the WHOLE slice, never first/last: Sahih Muslim's citations
                // are not monotonic within a chapter.
                let rows = data.hadiths(in: chapter)
                if var low = rows.first?.citedBaseNumber {
                    var high = low
                    for hadith in rows.dropFirst() {
                        let number = hadith.citedBaseNumber
                        low = min(low, number)
                        high = max(high, number)
                    }
                    ranges[chapter.id] = low...high
                }
            }
            self.counts = counts
            self.ranges = ranges
            self.ordinals = ordinals
        }
    }

    private static var statsCache: [String: ChapterStats] = [:]

    private func chapterStats(_ data: HadithBookData) -> ChapterStats {
        if let cached = Self.statsCache[book.slug] { return cached }
        let stats = ChapterStats(data)
        Self.statsCache[book.slug] = stats
        return stats
    }

    private var filteredChapters: [HadithBookData.Chapter] {
        guard let data else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return data.chapters }
        // The chapter folds ride in the pack's eager section, so this is a plain compare against text
        // that was normalized at build time - no per-chapter Arabic fold on the main thread.
        let folded = HadithFold.query(query)
        return data.chapters.filter { data.matches($0, folded) }
    }

    /// Book-wide hadith search (English text/narrator + diacritic-insensitive Arabic), the Quran
    /// search's way: scan only until one PAST the shown page, so finding page one of a common word
    /// in Bukhari never walks all 7,500 hadiths. `hasMore` renders the count pill as "5+".
    /// The debounced, off-main scan feeding `inBookMatches` - the body reads state, never scans.
    private func runInBookSearch(_ data: HadithBookData) {
        inBookSearchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        // A pure citation ("5", or "8a" with the variant letter) is a hadith NUMBER: the hadith
        // CITED 5 in this book, all its variants when the base owns several, falling back to the
        // internal row number where no citations exist. Answered directly - no scan, and deliberately
        // BEFORE the three-character floor below, which is why typing a one- or two-digit number
        // used to show nothing at all.
        if let citation = HadithBookData.citationNumber(inQuery: query) {
            inBookMatches = (Self.citedMatches(citation, in: data), false)
            return
        }

        guard query.count >= 3 else {
            if !inBookMatches.shown.isEmpty || inBookMatches.hasMore { inBookMatches = ([], false) }
            return
        }
        let folded = HadithFold.query(query)
        let limit = hadithMatchLimit

        inBookSearchTask = Task {
            // Debounce so typing pays once per settled query; the scan itself runs detached, with
            // cancellation bridged in (detached tasks don't inherit it).
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            let scan = Task.detached(priority: .userInitiated) { () -> (shown: [HadithBookData.Hadith], hasMore: Bool) in
                var results: [HadithBookData.Hadith] = []
                for hadith in data.hadiths {
                    if Task.isCancelled { return (results, false) }
                    if data.matches(hadith, folded) {
                        results.append(hadith)
                        if results.count > limit { return (Array(results.prefix(limit)), true) }
                    }
                }
                return (results, false)
            }
            let result = await withTaskCancellationHandler {
                await scan.value
            } onCancel: {
                scan.cancel()
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                // Plain apply - see the aiHits apply note (collection-view assertion).
                inBookMatches = result
            }
            // First render of each result row hits the highlight cache instead of paying the fold.
            // Detached: this task inherits the view's @MainActor.
            var sources: [String] = []
            sources.reserveCapacity(result.shown.count * 3)
            for hadith in result.shown {
                let strings = hadith.allText
                sources.append(strings.arabic)
                sources.append(strings.text)
                sources.append(strings.narrator)
            }
            let prewarm = sources
            Task.detached(priority: .utility) {
                HighlightedSnippet.prewarmNormalization(of: prewarm)
            }
        }
    }

    /// The citation-first reading of a bare number in THIS book: every variant the base owns
    /// (filtered to one when a suffix was typed), the internal row number when the book carries no
    /// citations under it - shared by the debounced search and its synchronous twin.
    private static func citedMatches(_ citation: (base: Int, suffix: String?), in data: HadithBookData) -> [HadithBookData.Hadith] {
        var cited = data.hadiths(citing: citation.base)
        if let suffix = citation.suffix {
            cited = cited.filter { $0.citation == "\(citation.base)\(suffix)" }
        } else if cited.isEmpty, let fallback = data.hadith(numbered: citation.base) {
            cited = [fallback]
        }
        return cited
    }

    /// Synchronous variant, kept ONLY for user-gesture paths (Ask's context gather, the focus-loss
    /// history check) - never called per keystroke or from body.
    private func matchingHadiths(_ data: HadithBookData) -> (shown: [HadithBookData.Hadith], hasMore: Bool) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let citation = HadithBookData.citationNumber(inQuery: query) {
            return (Self.citedMatches(citation, in: data), false)
        }
        guard query.count >= 3 else { return ([], false) }
        // Script-aware: an Arabic query can only live in the Arabic text, a Latin one only in the
        // English - so each query pays for exactly ONE field, matched against the fold the pack
        // already carries.
        let folded = HadithFold.query(query)

        var results: [HadithBookData.Hadith] = []
        for hadith in data.hadiths {
            if data.matches(hadith, folded) {
                results.append(hadith)
                if results.count > hadithMatchLimit {
                    return (Array(results.prefix(hadithMatchLimit)), true)
                }
            }
        }
        return (results, false)
    }

    /// The two invisible `isActive` pushes this screen drives programmatically: the chapter a grid tile
    /// taps, and the auto-open deep link (a hadith opened from the tab root lands on ITS chapter, scrolled
    /// to it, so backing out shows the chapter list instead of skipping it).
    ///
    /// `isDetailLink(false)` is load-bearing, not decoration: NavigationView can feed a programmatic
    /// link's `isActive` binding a spurious `false` while reconciling a re-render of the screen hosting
    /// it - which nils the state and pops the pushed chapter right back here. That re-render reliably
    /// arrived from the chapter recording Last Read (a publish these screens observe), so every deep-
    /// linked open popped itself moments after the scroll landed, no matter where in this screen the
    /// link was anchored.
    @ViewBuilder
    private var pushLinks: some View {
        // iOS 15 only: on iOS 16+ chapter pushes go through `onPushChapter` into the tab root's
        // NavigationStack path (stack mode) or swap the detail column (column mode) - these links
        // must not exist there, or their bindings reintroduce the spurious-pop surface.
        if #unavailable(iOS 16.0), let data {
            ZStack {
                NavigationLink(isActive: Binding(
                    get: { pushedChapter != nil },
                    set: { if !$0 { pushedChapter = nil } }
                )) {
                    if let pushedChapter {
                        HadithChapterView(book: book, bookData: data, chapter: pushedChapter)
                    }
                } label: {
                    EmptyView()
                }
                .isDetailLink(false)

                NavigationLink(isActive: Binding(
                    get: { autoOpenTarget != nil },
                    set: { if !$0 { autoOpenTarget = nil } }
                )) {
                    if let autoOpenTarget, let autoOpenHadithID {
                        HadithChapterView(book: book, bookData: data, chapter: autoOpenTarget, scrollToHadithId: autoOpenHadithID)
                    }
                } label: {
                    EmptyView()
                }
                .isDetailLink(false)
            }
            .opacity(0)
        }
    }

    var body: some View {
        Group {
            if let data {
                loadedBody(data)
            } else {
                // The pack is bundled, so this only shows if its file is missing from the app itself.
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("\(book.englishTitle) could not be opened.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        // Both invisible push links live HERE, on the outer container, not on the chapters List.
        // Hung off the List they were torn down whenever it re-diffed - and the chapter they pushed
        // records Last Read through the store this screen observes, so opening a hadith from the tab
        // root reliably popped itself back to the chapter list a beat after it scrolled.
        .background(pushLinks)
        .navigationTitle(book.englishTitle)
        .navigationBarTitleDisplayMode(.inline)
        // The Quran reader's toolbar shape: the reading-mode toggle on the left, the gear on the
        // right - fullscreen and sharing live in the rows' context menus, not up here.
        // Pages/list top left (the Quran reader's toolbar shape), grid + gear top right - the tab
        // root's exact trailing pair. Fullscreen/sharing live in the rows' context menus.
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if data != nil {
                    Button {
                        settings.hapticFeedback()
                        showReadingModeConfirm = true
                    } label: {
                        Image(systemName: hadithPageMode ? "list.bullet.rectangle" : "book")
                    }
                    .accessibilityLabel(hadithPageMode ? "Open chapters as lists" : "Open chapters as pages")
                    .tint(settings.accentColor.accent1)
                    .confirmationDialog(
                        hadithPageMode ? "Switch to List View?" : "Switch to Page View?",
                        isPresented: $showReadingModeConfirm,
                        titleVisibility: .visible
                    ) {
                        Button(hadithPageMode ? "Read as List" : "Read as Pages") {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) { hadithPageMode.toggle() }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text(hadithPageMode
                             ? "Chapters will open as a scrolling list of hadiths."
                             : "Chapters will open as pages right away: a right-to-left paged reader fitting as many hadiths per page as your font sizes allow.")
                    }
                }
            }
        }
        .modifier(HadithTrailingToolbar(
            hadithGridMode: $hadithGridMode,
            showHadithSettings: $showHadithSettings
        ))
        .sheet(isPresented: $showHadithSettings) {
            SettingsHadithView()
                .smallMediumSheetPresentation()
        }
    }

    private func loadedBody(_ data: HadithBookData) -> some View {
        // Matches come from STATE, filled by `runInBookSearch`'s debounced, off-main scan. Computing
        // them here walked up to the whole book (Bukhari ~7,500 hadiths of `.contains`) synchronously
        // on the main thread on every keystroke - the one search path that never got the global
        // sweep's detached treatment.
        let matches = isSearchActive
            ? inBookMatches
            : (shown: [HadithBookData.Hadith](), hasMore: false)
        let shownChapters = filteredChapters

        return ScrollViewReader { scrollProxy in
        List {
            Group {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(data.metadata.english.title)
                                .font(.subheadline.weight(.semibold))

                            Spacer(minLength: 8)

                            HighlightedSnippet(
                                source: book.arabicTitle,
                                term: "",
                                font: settings.useFontArabic
                                    ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2)
                                    : .subheadline,
                                accent: settings.accentColor.color,
                                fg: settings.accentColor.color
                            )
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                        }

                        Text("\(book.authorEnglish) (\(book.authorArabic)) - \(book.era)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // The fuller, authentic orientation to this collection - selectable,
                        // because it's the one paragraph on the screen a reader would quote.
                        SelectableProse(text: book.longDescription,
                                        textStyle: .footnote,
                                        secondary: true)
                    }
                    .padding(.vertical, 2)
                }

                // This book's own remembered spot - the Quran's Last Read Ayah, per book. Jumps into
                // the chapter scrolled to the hadith, arrival-marked.
                if !isSearchActive, let lastRead = store.lastRead(for: book.slug) {
                    Section(header: Text("LAST READ")) {
                        // The chapter resolves lazily through `??`: the fallback's full-book scan only
                        // runs for a record whose chapter id no longer exists in the data.
                        if let chapter = data.chapters.first(where: { $0.id == lastRead.chapterId })
                            ?? data.hadiths.first(where: { $0.idInBook == lastRead.idInBook })
                                .flatMap({ resolved in data.chapters.first { $0.id == resolved.chapterId } }) {
                            chapterLink(chapter, data: data, scrollToHadithId: lastRead.idInBook) {
                                lastReadRow(lastRead)
                            }
                        } else {
                            NavigationLink {
                                // byRowNumber: a stale record's key is a row number, not a citation -
                                // citation-first reading would open a different hadith in drifted books.
                                HadithReferenceView(book: book, chapter: nil, hadith: lastRead.idInBook, byRowNumber: true)
                            } label: {
                                lastReadRow(lastRead)
                            }
                        }
                    }
                }

                // While searching: chapter matches first, then hadith matches - each page-sized with
                // load-more controls, the Quran search's way.
                if isSearchActive {
                    // Question-shaped queries stream a grounded on-device answer automatically; other
                    // queries get a one-tap "Ask AI" row - the Quran search's exact grammar, under the
                    // same accent ASK AI header. ALWAYS present while searching, results or none: with
                    // nothing retrieved the ask answers in the engine's open mode instead.
                    if OnDeviceAsk.isAvailable {
                        if askNoAnswer {
                            Section(header: askAIHeader) {
                                askNoAnswerRow
                            }
                        } else if !askRanForQuery.isEmpty {
                            Section(header: askAIHeader) {
                                AskAnswerCard(answer: askAnswer, isStreaming: askIsStreaming, grounded: askGrounded)

                                // The answer's receipts: the hadiths it actually cited, as standard
                                // rows (full context menu) landing in their chapter - the global
                                // hadith search's exact grammar.
                                ForEach(askCitedHadiths) { hadith in
                                    if let chapter = data.chapters.first(where: { $0.id == hadith.chapterId }) {
                                        chapterLink(chapter, data: data, scrollToHadithId: hadith.idInBook) {
                                            HadithRow(book: book, hadith: hadith, searchText: searchText, compact: true).equatable()
                                        }
                                    }
                                }
                            }
                        } else {
                            Section(header: askAIHeader) {
                                Button {
                                    settings.hapticFeedback()
                                    runAsk(query: searchText, data: data, manual: true)
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
                        }
                    }

                    // Both result kinds landed: ONE segmented switch decides which list fills the page
                    // (the Quran search's rule). With only one kind present, no picker - it just shows.
                    let showResultsPicker = !aiHits.isEmpty && (!matches.shown.isEmpty || !shownChapters.isEmpty)
                    if showResultsPicker {
                        Section {
                            Picker("Results", selection: $showBookKeywordResults) {
                                Text("AI Results").tag(false)
                                Text("Keyword Results").tag(true)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    let keywordVisible = !showResultsPicker || showBookKeywordResults

                    // AI matches appear AUTOMATICALLY at the very top, the Quran ayah search's exact
                    // grammar - no mode to enter.
                    if !showResultsPicker || !showBookKeywordResults {
                        aiMatchesSection(data)
                    }

                    if keywordVisible, !shownChapters.isEmpty {
                        Section(header: SectionPillHeader(title: "MATCHING CHAPTERS", count: shownChapters.count)) {
                            ForEach(shownChapters.prefix(chapterMatchLimit)) { chapter in
                                chapterRowLink(chapter, data: data)
                            }

                            HadithLoadMoreControls(label: "chapter matches", hasMore: shownChapters.count > chapterMatchLimit, limit: $chapterMatchLimit)
                        }
                    }

                    // Hadith matches, the Quran ayah-search way: compact rows grouped per chapter,
                    // each group with its own count pill; tapping one opens the chapter scrolled to it.
                    if keywordVisible {
                        hadithMatchesSections(data, matches: matches)
                    }

                    if shownChapters.isEmpty && matches.shown.isEmpty {
                        Section {
                            Text(aiHits.isEmpty
                                 ? "No matches found."
                                 : "No keyword matches. See the AI results above.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    // The Quran surah list's shape: the header stands alone, then each chapter is its own
                    // Section - separate glass cards with compact spacing between them.
                    Section(header: chaptersSectionHeader(data)) { }
                        .padding(.bottom, -12)

                    if hadithGridMode {
                        Section {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                ForEach(shownChapters) { chapter in
                                    chapterGridTile(chapter, data: data)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        ForEach(shownChapters) { chapter in
                            Section {
                                chapterRowLink(chapter, data: data)
                            }
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        // Column mode: this is the CONTENT column and the reading column beside it shows the Now
        // Playing bar - suppress the duplicate here (same rule as the catalog and the Quran sidebar).
        .applyConditionalListStyle(disableNowPlayingInset: usesColumnNavigation)
        .compactListSectionSpacing()
        // No pinned book header here: the navigation title already names the book, and the CHAPTERS
        // header carries the counts - a floating bar was pure repetition on this screen.
        // The grid/list flip animates, same as the catalog.
        .animation(.easeInOut, value: hadithGridMode)
        // NOTE: the two invisible push links (grid tile, auto-open) deliberately do NOT live here.
        // Anchoring an `isActive` NavigationLink to this List means every re-diff of the List can tear
        // it down and pop whatever it pushed - and the pushed chapter's own Last Read record publishes
        // through the store THIS screen observes, which re-diffs the List (for a first read it inserts
        // the whole LAST READ section). They hang off the outer container in `body` instead, where the
        // List's content can't reach them. See `pushLinks`.
        .onAppear {
            // Build (or disk-load) this book's AI index shortly AFTER the book renders - ready by
            // the first search keystroke, but never competing with the open itself. No-ops when built.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                prepareSemanticCorpus(data)
            }

            // Resolve and push the target chapter once, after this screen settles (an immediate
            // isActive flip on arrival is unreliable in the pre-NavigationStack containers).
            guard !didAutoOpen, let targetID = autoOpenHadithID else {
                // No deep link: in column mode the detail needs something to read. Only when it isn't
                // already on THIS book - coming back from the books list must not throw away the chapter
                // the reader was on.
                if usesColumnNavigation, columnSelection.bookSlug != book.slug {
                    selectDefaultChapter(data)
                }
                return
            }
            didAutoOpen = true
            guard let hadith = data.hadiths.first(where: { $0.idInBook == targetID }),
                  let chapter = data.chapters.first(where: { $0.id == hadith.chapterId }) else { return }
            // Column mode has no push to make - the deep-linked chapter just becomes the detail column,
            // with the chapter list beside it (which is what the push was protecting on iPhone).
            guard !usesColumnNavigation else {
                selectChapter(chapter, data: data, scrollToHadithId: targetID)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if let onPushChapter {
                    // iOS 16 stack: append the chapter to the tab root's path (immune to re-renders).
                    onPushChapter(chapter, targetID)
                } else {
                    autoOpenTarget = chapter
                }
            }
        }
        .onChange(of: searchText) { text in
            // A new query starts back at the first page of matches, on the AI list, with any
            // dead-end ask notice cleared.
            chapterMatchLimit = 5
            hadithMatchLimit = 5
            showBookKeywordResults = false
            askNoAnswer = false
            runInBookSearch(data)
            runAISearch(query: text, data: data)
            runAskIfNeeded(query: text, data: data)
        }
        // Load-more bumps the limit; re-run the (debounced, off-main) scan for the bigger page.
        .onChange(of: hadithMatchLimit) { _ in
            runInBookSearch(data)
        }
        // The one-time vector build finishing mid-query: surface the results without another keystroke.
        .onChange(of: semanticEngine.readyCorpora) { ready in
            guard ready.contains(semanticCorpusID) else { return }
            runAISearch(query: searchText, data: data)
        }
        .onChange(of: pendingScrollToChapterId) { chapterId in
            guard let chapterId else { return }
            pendingScrollToChapterId = nil
            // Grid tiles carry no scroll ids (the Quran list has the same rule), so flip to the
            // list first; and clear the search so the chapter rows exist, then land on the chapter.
            if hadithGridMode { hadithGridMode = false }
            withAnimation { searchText = "" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { scrollProxy.scrollTo("hadith-chapter-\(chapterId)", anchor: .top) }
            }
        }
        // Apple Music-style: the bottom search bar minimizes while scrolling down. The whole bottom
        // bar is the tab root's exact grammar - recent-searches chips over the field while focused.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            let chipsVisible = isBookSearchFocused && !settings.hadithSearchHistory.isEmpty
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                HadithSearchHistoryChips(searchText: $searchText)
                    .frame(height: chipsVisible ? nil : 0)
                    .clipped()
                    .opacity(chipsVisible ? 1 : 0)
                    .allowsHitTesting(chipsVisible)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: chipsVisible)
                    .padding(.horizontal, 24)

                SearchBar(
                    // Animated with the app-wide gate; the in-book hadith matches already animate at
                    // their debounced apply site, so this covers the chapter-filter diff while typing.
                    text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                    onFocusChanged: { focused in
                        withAnimation { isBookSearchFocused = focused }
                        // Leaving the field with a query that found something joins the shared
                        // recent-searches chips (the tab root's rule).
                        if !focused, isSearchActive,
                           !filteredChapters.isEmpty || !matchingHadiths(data).shown.isEmpty {
                            persistSearchHistoryIfNeeded()
                        }
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .minimizedBarStyle(barsCollapsed && !isBookSearchFocused)
            }
            .background(Color.white.opacity(0.00001))
            .transaction { $0.animation = nil }
        }
        }
    }

    private func persistSearchHistoryIfNeeded() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return }
        if lastSavedSearchQuery.caseInsensitiveCompare(trimmed) == .orderedSame { return }
        settings.addHadithSearchHistory(trimmed)
        lastSavedSearchQuery = trimmed
    }

    /// This book's remembered spot, as a row - the reference, how long ago, and both previews.
    private func lastReadRow(_ lastRead: HadithLastRead) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(lastRead.reference)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)

                Spacer(minLength: 8)

                // Same "Today 5:30 PM" form as the Quran history rows and the Hadith tab's card -
                // this row used a bare relative age ("5 minutes") and matched neither.
                historyTimestampLabel(lastRead.timestamp)
            }

            if settings.showHadithArabic, !lastRead.arabicPreview.isEmpty {
                HadithArabicPreview(text: lastRead.arabicPreview)
            }

            if settings.showHadithEnglish, !lastRead.englishPreview.isEmpty {
                Text(lastRead.englishPreview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .reservedLineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    /// The CHAPTERS header carrying the book's shape at a glance - the count pills sit at its trailing
    /// edge, in the same pill language the other section headers use. No size pill: the book is part of
    /// the app, so how many megabytes it weighs is not something the reader has to think about.
    private func chaptersSectionHeader(_ data: HadithBookData) -> some View {
        HStack(spacing: 5) {
            Text("CHAPTERS")

            Spacer()

            // Chapters, then hadiths - the SAME order as the catalog rows' chips, abbreviated in the
            // split view's narrow content column so neither ellipsizes.
            if usesColumnNavigation {
                statPill("\(data.chapters.count) Ch")
                statPill("\(data.hadiths.count.formatted()) Ha")
            } else {
                statPill("\(data.chapters.count) Chapters")
                statPill("\(data.hadiths.count.formatted()) Hadiths")
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    /// A small glass stat chip, in the count-pill language - padded to match the catalog's `statChip`,
    /// which had to tighten to survive the narrow content column.
    private func statPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(settings.accentColor.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .conditionalGlassEffect()
    }

    /// "ASK AI" with the sparkles glyph, accent-tinted - the Quran search's `askAIHeader`, for this book.
    private var askAIHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("ASK AI")

            Spacer()
        }
        .foregroundStyle(settings.accentColor.color)
    }

    /// Shown when a manual ask dead-ends: nothing retrieved matched the query, so there was nothing to
    /// answer from. Editing the query clears it (`runAsk` resets the flag on every run).
    private var askNoAnswerRow: some View {
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

    /// The AI (semantic) matches for the live query, shown automatically: build progress the first time,
    /// then the ranked matches - each the standard compact hadith row, landing in its chapter scrolled
    /// to the hadith, exactly like the keyword matches. Deliberately SILENT otherwise (Arabic query,
    /// build failed, no semantic matches): an automatic section must never nag.
    @ViewBuilder
    private func aiMatchesSection(_ data: HadithBookData) -> some View {
        if aiQueryEligible {
            if semanticEngine.isReady(semanticCorpusID) {
                if !aiHits.isEmpty {
                    // The keyword matches' grammar: the sparkles TOTAL pill up top, then one section
                    // per chapter with its own count - the same split `hadithMatchesSections` gives
                    // the keyword hits, so both lists read identically.
                    Section(header: SectionPillHeader(title: "AI MATCHES", count: aiHits.count, icon: "sparkles", accentTitle: true)) {
                        EmptyView()
                    }
                    .padding(.bottom, -12)

                    ForEach(hadithMatchGroups(data, shown: aiHits)) { group in
                        Section {
                            ForEach(group.shown) { hadith in
                                // Land in the chapter, scrolled to the hadith - the keyword matches' arrival.
                                chapterLink(group.chapter, data: data, scrollToHadithId: hadith.idInBook) {
                                    HadithRow(book: book, hadith: hadith, searchText: searchText, compact: true).equatable()
                                }
                            }
                        } header: {
                            HStack(spacing: 8) {
                                Text(group.chapter.english.uppercased())
                                    .lineLimit(1)

                                Spacer()

                                CountPill(count: group.shown.count)
                            }
                        }
                    }
                }
            } else if !semanticEngine.failedCorpora.contains(semanticCorpusID) {
                Section { AISearchStatusRow(progress: semanticEngine.progress(semanticCorpusID), failed: false) }
            }
        }
    }

    /// One chapter's slice of the shown match page.
    private struct HadithMatchGroup: Identifiable {
        let chapter: HadithBookData.Chapter
        let shown: [HadithBookData.Hadith]
        var id: Int { chapter.id }
    }

    /// The shown page of hadith matches grouped by chapter in book order - the Quran search's
    /// per-surah grouping.
    private func hadithMatchGroups(
        _ data: HadithBookData,
        shown: [HadithBookData.Hadith]
    ) -> [HadithMatchGroup] {
        var order: [Int] = []
        var byChapter: [Int: [HadithBookData.Hadith]] = [:]
        for hadith in shown {
            if byChapter[hadith.chapterId] == nil { order.append(hadith.chapterId) }
            byChapter[hadith.chapterId, default: []].append(hadith)
        }

        return order.compactMap { chapterId in
            guard let chapter = data.chapters.first(where: { $0.id == chapterId }) else { return nil }
            return HadithMatchGroup(chapter: chapter, shown: byChapter[chapterId] ?? [])
        }
    }

    @ViewBuilder
    private func hadithMatchesSections(_ data: HadithBookData, matches: (shown: [HadithBookData.Hadith], hasMore: Bool)) -> some View {
        if !matches.shown.isEmpty {
            let groups = hadithMatchGroups(data, shown: matches.shown)
            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                Section(header: matchGroupHeader(group, isFirst: index == 0, matches: matches)) {
                    if index == 0 {
                        // The first group still names its chapter, under the overall header.
                        HStack(spacing: 8) {
                            Text(group.chapter.english)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                                .lineLimit(1)

                            Spacer()

                            CountPill(count: group.shown.count)
                        }
                    }

                    ForEach(group.shown) { hadith in
                        chapterLink(group.chapter, data: data, scrollToHadithId: hadith.idInBook) {
                            HadithRow(book: book, hadith: hadith, searchText: searchText, compact: true).equatable()
                        }
                    }

                    if index == groups.count - 1 {
                        HadithLoadMoreControls(label: "hadith matches", hasMore: matches.hasMore, limit: $hadithMatchLimit)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func matchGroupHeader(_ group: HadithMatchGroup, isFirst: Bool, matches: (shown: [HadithBookData.Hadith], hasMore: Bool)) -> some View {
        HStack(spacing: 8) {
            if isFirst {
                Text("MATCHING HADITHS")
                Spacer()
                CountPill(count: matches.shown.count, overflow: matches.hasMore)
            } else {
                Text(group.chapter.english.uppercased())
                    .lineLimit(1)
                Spacer()
                CountPill(count: group.shown.count)
            }
        }
    }

    /// Opening a chapter, in whichever navigation this screen is running: a push on iPhone, a swap of the
    /// detail column on iPad/Mac. The Quran tab's `quranNavigationLink`, for chapters - every row that
    /// opens a chapter (browsing, search matches, AI matches, last read) goes through this one place.
    @ViewBuilder
    private func chapterLink<Label: View>(
        _ chapter: HadithBookData.Chapter,
        data: HadithBookData,
        scrollToHadithId: Int? = nil,
        @ViewBuilder label: () -> Label
    ) -> some View {
        if usesColumnNavigation {
            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    selectChapter(chapter, data: data, scrollToHadithId: scrollToHadithId)
                }
            } label: {
                HStack(spacing: 8) {
                    label()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                HadithChapterView(book: book, bookData: data, chapter: chapter, scrollToHadithId: scrollToHadithId)
            } label: {
                label()
            }
        }
    }

    /// One chapter row with its full grammar - the link, context menu, swipes, and scroll id - shared by
    /// the browsing list and the search results.
    private func chapterRowLink(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> some View {
        let isCurrent = usesColumnNavigation && columnSelection.currentChapterID == chapter.id
        return chapterLink(chapter, data: data) {
            chapterRow(chapter, data: data)
                // Column mode only: the left list stays truthful about what fills the right, including
                // after the reader swaps chapters from inside the reader itself.
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(settings.accentColor.color.opacity(isCurrent ? 0.18 : 0))
                        .padding(-6)
                )
        }
        .contextMenu { chapterContextMenu(chapter, data: data) }
        // The surah rows' swipe language, icon-only: favorite leading, scroll-to trailing.
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    store.toggleChapterFavorite(slug: book.slug, chapterId: chapter.id)
                }
            } label: {
                Image(systemName: store.isChapterFavorite(slug: book.slug, chapterId: chapter.id) ? "star.fill" : "star")
            }
            .tint(settings.accentColor.color)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                settings.hapticFeedback()
                pendingScrollToChapterId = chapter.id
            } label: {
                Image(systemName: "arrow.down.circle")
            }
            .tint(.secondary)
        }
        .id("hadith-chapter-\(chapter.id)")
    }

    /// The chapter's place in the book, 1-based - what the badge and "CHAPTER N" header show.
    private func chapterOrdinal(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> Int {
        chapterStats(data).ordinals[chapter.id] ?? 1
    }

    private var chapterBadgeWidth: CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        return ("100" as NSString).size(withAttributes: [.font: font]).width + 8
    }

    /// "Hadiths 100-200" - which hadith numbers this chapter spans.
    private func chapterRangeText(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> String? {
        guard let range = chapterStats(data).ranges[chapter.id] else { return nil }
        return range.lowerBound == range.upperBound
            ? "Hadith \(range.lowerBound)"
            : "Hadiths \(range.lowerBound)-\(range.upperBound)"
    }

    /// The SurahRow number pill, for a chapter: full row height, tinted when favorited, and the tap
    /// itself toggles the favorite.
    @ViewBuilder
    private func chapterNumberPill(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> some View {
        let favorite = store.isChapterFavorite(slug: book.slug, chapterId: chapter.id)
        // The Quran's continue-reading grammar: a book badge (no tint) marks where you left off.
        let isLastRead = store.lastRead(for: book.slug)?.chapterId == chapter.id
        ZStack(alignment: .topTrailing) {
            Text("\(chapterOrdinal(chapter, data: data))")
                .font(.caption.weight(.bold))
                .foregroundColor(settings.accentColor.color)
                .frame(width: chapterBadgeWidth)
                .frame(maxHeight: .infinity)
                .conditionalGlassEffect(
                    useColor: favorite ? 0.3 : nil,
                    customTint: favorite ? settings.accentColor.color : nil
                )
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        store.toggleChapterFavorite(slug: book.slug, chapterId: chapter.id)
                    }
                }
                .accessibilityLabel("Chapter \(chapterOrdinal(chapter, data: data))\(isLastRead ? ", last read" : "")")

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

    private func chapterRow(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> some View {
        HStack(alignment: .center) {
            chapterNumberPill(chapter, data: data)
                .padding(.trailing, 2)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    HighlightedSnippet(
                        source: chapter.english,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )
                    .lineLimit(1)

                    Spacer(minLength: 8)

                    if let count = chapterStats(data).counts[chapter.id] {
                        CountPill(count: count)
                    }
                }

                // The Arabic name and the span share one row - Arabic under the English title,
                // the range under the count pill.
                HStack(alignment: .firstTextBaseline) {
                    if !chapter.arabic.isEmpty {
                        // The chapter number in Arabic-Indic digits beside the Arabic name, matching
                        // the grid tile - both scripts carry the number.
                        Text(arabicNumberString(from: chapterOrdinal(chapter, data: data)))
                            .font(settings.useFontArabic
                                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2)
                                : .caption.weight(.semibold))
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                            .foregroundColor(.secondary)
                            .layoutPriority(1)

                        HighlightedSnippet(
                            source: chapter.arabic,
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

                    Spacer(minLength: 8)

                    if let rangeText = chapterRangeText(chapter, data: data) {
                        Text(rangeText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                            .layoutPriority(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }

    /// The chapter as a grid card - the SurahRow grid tile's shape: Arabic on top, English and the
    /// span below, favorites tinted with the corner star.
    private func chapterGridTile(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> some View {
        let favorite = store.isChapterFavorite(slug: book.slug, chapterId: chapter.id)
        let isCurrent = usesColumnNavigation && columnSelection.currentChapterID == chapter.id
        return Button {
            settings.hapticFeedback()
            // Column mode swaps the detail; iOS 16 stack appends to the path; iOS 15 uses the hidden link.
            if usesColumnNavigation {
                withAnimation(.easeInOut) { selectChapter(chapter, data: data) }
            } else if let onPushChapter {
                onPushChapter(chapter, nil)
            } else {
                pushedChapter = chapter
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                if !chapter.arabic.isEmpty {
                    HStack(spacing: 4) {
                        // The surah grid tile's top-row grammar: the chapter number in Arabic-Indic
                        // digits beside the Arabic name, so both scripts carry the number.
                        Text(arabicNumberString(from: chapterOrdinal(chapter, data: data)))
                            .font(settings.useFontArabic
                                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2)
                                : .subheadline.weight(.semibold))
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                            .foregroundColor(settings.accentColor.color)
                            .layoutPriority(1)

                        HighlightedSnippet(
                            source: chapter.arabic,
                            term: searchText,
                            font: settings.useFontArabic
                                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2)
                                : .subheadline,
                            accent: settings.accentColor.color,
                            fg: settings.accentColor.color,
                            lineLimit: 1
                        )
                        .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)

                        // Leaves room at the trailing edge for the corner star overlay.
                        Spacer(minLength: 20)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                }

                HStack(spacing: 4) {
                    Text("\(chapterOrdinal(chapter, data: data)):")
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .foregroundColor(settings.accentColor.color)
                        .layoutPriority(1)

                    HighlightedSnippet(
                        source: chapter.english,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )
                    .lineLimit(1)
                }
                .minimumScaleFactor(0.6)

                HStack(spacing: 4) {
                    if let rangeText = chapterRangeText(chapter, data: data) {
                        Text(rangeText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                    if let count = chapterStats(data).counts[chapter.id] {
                        Text("• \(count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(height: 76)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Favorite keeps its full tint; the chapter currently filling the detail column gets a lighter
        // one, so the grid says which tile is open the same way the list rows do.
        .conditionalGlassEffect(
            clear: !favorite && !isCurrent,
            rectangle: true,
            useColor: favorite ? 0.25 : (isCurrent ? 0.15 : nil),
            customTint: favorite || isCurrent ? settings.accentColor.color : nil
        )
        .gridFavoriteStar(
            isFavorite: favorite,
            accent: settings.accentColor.color,
            accessibilityName: chapter.english
        ) {
            store.toggleChapterFavorite(slug: book.slug, chapterId: chapter.id)
        }
    }

    /// The SurahContextMenu's shape, for a chapter: fullscreen and sharing on top, then favorite
    /// and scroll-to.
    @ViewBuilder
    private func chapterContextMenu(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> some View {
        Text(chapter.english.isEmpty ? book.englishTitle : chapter.english)
            .foregroundStyle(.secondary)

        Button {
            settings.hapticFeedback()
            FocusOverlayPresenter.shared.present(.hadithChapter(
                book: book,
                chapter: chapter,
                ordinal: chapterOrdinal(chapter, data: data),
                rangeText: chapterRangeText(chapter, data: data)
            ))
        } label: {
            Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
        }

        Button {
            settings.hapticFeedback()
            let hadiths = data.hadiths(in: chapter)
            var parts = ["\(book.englishTitle) - \(chapter.english)"]
            parts.append(contentsOf: hadiths.map { HadithShareSheet.composedText(book: book, hadith: $0) })
            presentSystemShareSheet(items: [parts.joined(separator: "\n\n")])
        } label: {
            Label("Share Chapter", systemImage: "square.and.arrow.up")
        }

        Divider()

        Button(role: store.isChapterFavorite(slug: book.slug, chapterId: chapter.id) ? .destructive : .cancel) {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                store.toggleChapterFavorite(slug: book.slug, chapterId: chapter.id)
            }
        } label: {
            Label(store.isChapterFavorite(slug: book.slug, chapterId: chapter.id) ? "Unfavorite Chapter" : "Favorite Chapter",
                  systemImage: store.isChapterFavorite(slug: book.slug, chapterId: chapter.id) ? "star.fill" : "star")
        }

        Button {
            settings.hapticFeedback()
            pendingScrollToChapterId = chapter.id
        } label: {
            Text("Scroll To Chapter")
            Image(systemName: "arrow.down.circle")
        }
    }
}

// MARK: - The detail column (iPad/Mac)

/// Whether the Hadith tab is running as a `NavigationSplitView`, so the screens inside its content column
/// open chapters into the detail column instead of pushing. Set once by `HadithView`; every screen below
/// reads it from here rather than from its own size class, which inside a split column is the column's,
/// not the window's.
private struct HadithColumnNavigationKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var hadithUsesColumnNavigation: Bool {
        get { self[HadithColumnNavigationKey.self] }
        set { self[HadithColumnNavigationKey.self] = newValue }
    }
}

/// What the Hadith tab's detail column is reading on iPad/Mac. It is shared state rather than a binding
/// because the chapter list that writes it sits several pushes deep inside the content column, while the
/// detail column that reads it hangs off the tab root - the Quran's `selectedRoute`, spanning that gap.
@MainActor
final class HadithColumnSelection: ObservableObject {
    static let shared = HadithColumnSelection()

    struct Target {
        let book: HadithCatalogBook
        let bookData: HadithBookData
        let chapter: HadithBookData.Chapter
        let scrollToHadithId: Int?

        /// What re-identifies the reader: a different chapter, or a different landing hadith within one.
        var identity: String { "\(book.slug)-\(chapter.id)-\(scrollToHadithId ?? -1)" }
    }

    @Published private(set) var target: Target?
    /// The chapter the reader is ACTUALLY on. It drifts from `target` whenever the reader swaps chapters
    /// in place (Previous/Next, the picker) - which must NOT re-identify the detail, or every swap would
    /// rebuild the reader and lose its place. Only the chapter list's selected-row tint reads it.
    @Published private(set) var currentChapterID: Int?
    /// Bumped when a USER tap re-selects the identical target: the detail is keyed on it, so the tap
    /// always lands (re-scrolls to the hadith) instead of dying against an unchanged identity.
    @Published private(set) var refreshToken = 0

    var bookSlug: String? { target?.book.slug }

    func select(
        book: HadithCatalogBook,
        bookData: HadithBookData,
        chapter: HadithBookData.Chapter,
        scrollToHadithId: Int? = nil,
        userInitiated: Bool = false
    ) {
        let newTarget = Target(book: book, bookData: bookData, chapter: chapter, scrollToHadithId: scrollToHadithId)
        // Only USER re-taps force a refresh: programmatic defaults (book onAppear, last-read restore)
        // re-select the same target on every visit and must never rebuild the reader mid-read.
        if userInitiated, let current = target, current.identity == newTarget.identity {
            refreshToken &+= 1
        }
        target = newTarget
        currentChapterID = chapter.id
    }

    func noteChapterChanged(_ chapter: HadithBookData.Chapter) {
        currentChapterID = chapter.id
    }
}

/// The Hadith tab's detail column: the selected chapter's hadiths, in their own `NavigationStack` so the
/// reader's title menu and gear ride in the detail's own bar - the Quran tab's detail column, exactly.
///
/// Nothing above it observes `HadithColumnSelection`, so picking a chapter re-renders this column alone
/// and never the catalog behind it.
@available(iOS 16.0, *)
struct HadithDetailColumn: View {
    @ObservedObject private var selection = HadithColumnSelection.shared
    @ObservedObject private var store = HadithStore.shared
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        NavigationStack {
            Group {
                if let target = selection.target {
                    HadithChapterView(
                        book: target.book,
                        bookData: target.bookData,
                        chapter: target.chapter,
                        scrollToHadithId: target.scrollToHadithId,
                        onChapterChanged: { selection.noteChapterChanged($0) }
                    )
                    // A different chapter (or a different hadith within one) rebuilds the reader so it
                    // lands where it was asked to - the Quran detail column's `.id(route)` rule. Swaps
                    // made INSIDE the reader deliberately don't touch the target, so they don't rebuild.
                    // The refresh token folds in USER re-taps of the identical target (see `select`).
                    .id("\(target.identity)#\(selection.refreshToken)")
                } else {
                    placeholder
                }
            }
        }
        .task {
            await openLastReadIfIdle()
        }
    }

    /// Before anything is picked - the Quran's detail column opens on its last read, so this one does too.
    private func openLastReadIfIdle() async {
        guard selection.target == nil,
              let lastRead = store.lastRead,
              let book = HadithCatalogBook.bySlug[lastRead.slug],
              let data = store.book(book),
              // Records saved by older builds carry no chapter id - resolve those through the hadith.
              let chapter = data.chapters.first(where: { $0.id == lastRead.chapterId })
                ?? data.hadiths.first(where: { $0.idInBook == lastRead.idInBook })
                    .flatMap({ resolved in data.chapters.first { $0.id == resolved.chapterId } }),
              // The reader may have picked a chapter while the book was loading - never override that.
              selection.target == nil else { return }
        selection.select(book: book, bookData: data, chapter: chapter, scrollToHadithId: lastRead.idInBook)
    }

    private var placeholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "books.vertical")
                .font(.largeTitle)
                .foregroundStyle(settings.accentColor.color)

            Text("Choose a chapter to start reading.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The standard washed background + Now Playing inset: without this, the empty detail column is
        // the one pane in the app with a bare system background - and the only place recitation had no
        // bar at all once the catalog column suppresses its duplicate.
        .applyConditionalListStyle()
    }
}

// MARK: - One chapter: the hadiths

/// Which hadiths are on screen, held OUTSIDE the chapter view's own state. Rows report in on every
/// viewport crossing while scrolling; when this was `@State` on HadithChapterView, each crossing
/// re-ran the entire chapter body (the whole List builder plus the pinned header). Only
/// `ChapterProgressBar` observes it, so a scroll tick now re-renders just the 3pt bar.
@MainActor
final class ChapterVisibilityModel: ObservableObject {
    @Published var visibleIDs: Set<Int> = []
}

/// The pinned header's reading-progress bar - the one view whose input (the visible-hadith set)
/// changes on every scroll tick, so it is the one view that subscribes to it.
struct ChapterProgressBar: View {
    @ObservedObject var visibility: ChapterVisibilityModel
    let firstID: Int?
    let lastID: Int?
    /// False while searching - the filtered list is not the chapter, so progress means nothing.
    let isActive: Bool
    let color: Color

    /// How far the top-visible hadith is through the chapter - the surah reader's ayah progress,
    /// by hadith. Fills continuously as you scroll; full only once the last hadith is on screen.
    private var fraction: CGFloat? {
        guard isActive, let firstID, let lastID, lastID > firstID else { return nil }
        if visibility.visibleIDs.contains(lastID) { return 1 }
        guard let current = visibility.visibleIDs.min() else { return 0 }
        // Never quite full while scrolling: cap below 1 so 100% is reserved for the chapter's end.
        return min(CGFloat(current - firstID) / CGFloat(lastID - firstID), 0.97)
    }

    var body: some View {
        if let fraction {
            TrackedBar(
                fraction: fraction,
                height: 3,
                color: color
            )
            .transition(.opacity)
        }
    }
}

/// The ONE debounce slot for hadith last-read records, shared by the chapter list and the pager (view
/// structs are recreated per body pass, so instance state can't own it; one reading surface is on screen
/// at a time, so a single slot is enough). 1.0s trailing: always past the push-transition window whose
/// mid-flight store publish used to pop the deep-linked screen, and last-record-wins by construction.
@MainActor
enum HadithLastReadDebounce {
    private static var pending: DispatchWorkItem?

    static func schedule(_ record: @escaping () -> Void) {
        pending?.cancel()
        let work = DispatchWorkItem(block: record)
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }
}

struct HadithChapterView: View {
    #if DEBUG
    /// `-launchHadithShare` (with `-launchHadithOpen`): the landed hadith's share sheet, presented headlessly.
    @State private var debugShareHadith: HadithBookData.Hadith? = nil
    #endif
    @ObservedObject private var settings = Settings.shared
    /// NOT `@ObservedObject`: this view's render tree never reads a published store property (the three
    /// `store.` uses are inside onChange/button handlers). Observing it re-ran the whole reading body -
    /// List, sections, every row - on every publish the store made while opening books.
    private var store: HadithStore { HadithStore.shared }

    let book: HadithCatalogBook
    let bookData: HadithBookData
    /// A search result or reference landing here scrolls the list to this hadith, the Quran's way.
    let scrollToHadithId: Int?
    /// Column mode (iPad/Mac): report chapter swaps made in HERE - Previous/Next, the picker - so the
    /// chapter list in the left column can follow. Nil everywhere else; it must never re-identify this
    /// view, so the book screen keeps it out of the detail column's selection.
    var onChapterChanged: ((HadithBookData.Chapter) -> Void)? = nil

    // The current chapter and its derived reading data. Held in @State so Previous/Next swaps the chapter
    // IN PLACE (the surah reader's way) rather than pushing a new view. Each is computed once - at init and
    // again only on a chapter swap - so the progress bar never pays an O(hadiths) walk per scroll tick.
    @State private var chapter: HadithBookData.Chapter
    @State private var chapterIndex: Int
    @State private var allChapterHadiths: [HadithBookData.Hadith]
    @State private var chapterRange: ClosedRange<Int>?

    init(
        book: HadithCatalogBook,
        bookData: HadithBookData,
        chapter: HadithBookData.Chapter,
        scrollToHadithId: Int? = nil,
        onChapterChanged: ((HadithBookData.Chapter) -> Void)? = nil
    ) {
        self.book = book
        self.bookData = bookData
        self.scrollToHadithId = scrollToHadithId
        self.onChapterChanged = onChapterChanged
        _chapter = State(initialValue: chapter)
        _chapterIndex = State(initialValue: bookData.chapters.firstIndex(where: { $0.id == chapter.id }) ?? 0)
        let hadiths = Array(bookData.hadiths(in: chapter))
        _allChapterHadiths = State(initialValue: hadiths)
        _chapterRange = State(initialValue: HadithChapterView.range(of: hadiths))
    }

    /// The span of CITED hadith numbers a chapter covers ("1234-1256") - citation base numbers,
    /// falling back to idInBook per row for the books without citations (identical to the old label
    /// there). Min/max over the whole slice, never first/last: Sahih Muslim's citations are not
    /// monotonic within a chapter.
    static func range(of hadiths: [HadithBookData.Hadith]) -> ClosedRange<Int>? {
        guard var low = hadiths.first?.citedBaseNumber else { return nil }
        var high = low
        for hadith in hadiths.dropFirst() {
            let number = hadith.citedBaseNumber
            low = min(low, number)
            high = max(high, number)
        }
        return low...high
    }

    /// The book-order neighbours of the current chapter - the surah reader's Previous/Next, by chapter.
    private var previousChapter: HadithBookData.Chapter? {
        bookData.chapters.indices.contains(chapterIndex - 1) ? bookData.chapters[chapterIndex - 1] : nil
    }
    private var nextChapter: HadithBookData.Chapter? {
        bookData.chapters.indices.contains(chapterIndex + 1) ? bookData.chapters[chapterIndex + 1] : nil
    }

    /// Swap the chapter in place - recompute its derived reading data, reset the search and visibility,
    /// and record it as Last Read - exactly as the surah reader swaps surahs without a new push.
    /// `recordLastRead: false` is for the page-mode entry jump TO the last read: recording the
    /// chapter's first hadith would overwrite the exact spot the page seed is about to land on.
    private func navigateToChapter(_ target: HadithBookData.Chapter, recordLastRead: Bool = true) {
        settings.hapticFeedback()
        let hadiths = Array(bookData.hadiths(in: target))
        withAnimation(.easeInOut) {
            chapter = target
            chapterIndex = bookData.chapters.firstIndex(where: { $0.id == target.id }) ?? 0
            allChapterHadiths = hadiths
            chapterRange = Self.range(of: hadiths)
            searchText = ""
            visibility.visibleIDs = []
            highlightedHadithID = nil
        }
        onChapterChanged?(target)
        if recordLastRead, let first = hadiths.first {
            // Through the shared debounce slot, like every other last-read record: an immediate store
            // publish mid-transition re-renders the observing book screen - the pop hazard - and in
            // page mode the pager's own record follows anyway (single slot: last record wins).
            let book = book
            HadithLastReadDebounce.schedule {
                HadithStore.shared.recordLastRead(book: book, hadith: first)
            }
        }
    }

    @State private var searchText = ""

    #if os(iOS)
    // Within-chapter AI search: the book's own corpus ("hadith-<slug>", one vector cache shared
    // with the book screen), hits filtered to this chapter's rows.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var chapterAIHits: [HadithBookData.Hadith] = []
    @State private var chapterAISearchTask: Task<Void, Never>?

    private func runChapterAISearch(query: String) {
        chapterAISearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SemanticSearchEngine.isSupported, trimmed.count >= 3, !trimmed.containsArabicScript,
              HadithBookData.hadithNumber(inQuery: trimmed) == nil else {
            if !chapterAIHits.isEmpty { chapterAIHits = [] }
            return
        }
        let corpusID = "hadith-\(book.slug)"
        prepareBookSemanticCorpus(semanticEngine, data: bookData, corpusID: corpusID)

        chapterAISearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            // Over-fetch from the whole book, keep this chapter's rows - filtering after ranking
            // beats a per-chapter corpus.
            let results = await semanticEngine.search(corpusID: corpusID, query: trimmed, limit: 48)
            guard !Task.isCancelled else { return }
            let keys = await MainActor.run { semanticEngine.corpus(corpusID)?.itemKeys }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                chapterAIHits = results.compactMap { result -> HadithBookData.Hadith? in
                    let hadith: HadithBookData.Hadith?
                    if let keys, keys.indices.contains(result.index), let number = Int(keys[result.index]) {
                        hadith = bookData.hadith(numbered: number)
                    } else if bookData.hadiths.indices.contains(result.index) {
                        hadith = bookData.hadiths[result.index]
                    } else {
                        hadith = nil
                    }
                    guard let hadith, hadith.chapterId == chapter.id else { return nil }
                    return hadith
                }
                .prefix(6).map { $0 }
            }
        }
    }
    #endif
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @State private var showChapterSettings = false
    /// The hadith the reader marked by tapping it - the ayah list's grey attention tint, for hadiths.
    /// Tap to mark (keep your place), tap again to clear; arriving at a searched hadith marks it too.
    @State private var highlightedHadithID: Int? = nil
    /// Which hadiths are on screen - drives the pinned header's progress bar, the surah reader's way.
    /// A plain (NOT observed) reference in @State: rows write into it on every viewport crossing, and
    /// only ChapterProgressBar subscribes - so scrolling no longer invalidates this whole view.
    @State private var visibility = ChapterVisibilityModel()
    /// The chapter's reading mode: the scrolling list unless the reader asks for pages (via the title
    /// menu or Hadith Settings). Same key, same default, as the chapters screen declares.
    @AppStorage("hadithPageMode") private var hadithPageMode = false
    /// The title menu's chapter picker sheet.
    @State private var showChapterPicker = false
    // Multi-select (list mode): pick several hadiths, then copy/share/bookmark them all at once - the
    // surah reader's select mode, for hadiths.
    @State private var isSelectingHadiths = false
    @State private var selectedHadithIDs: Set<Int> = []

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The chapter's hadith search, SurahView's way now: filter the reading list itself and show every
    /// match as a FULL row - no paging, no load-more, exactly how the ayah list filters in place. The
    /// chapter is bounded (a few hundred hadiths at most), so the full scan is instant.
    private func chapterMatches() -> [HadithBookData.Hadith] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return allChapterHadiths }
        // Script-aware, same as the book search: one field per query, matched against the fold the
        // pack carries - which is also the fold the highlighter uses, so "Allah's" and "A'ishah"
        // match what gets coloured.
        let folded = HadithFold.query(query)
        let numbered = Set(numberMatches().map(\.hadith.row))
        // Number matches get their own labelled section above; a text match on the same hadith would
        // otherwise draw the identical row twice.
        return allChapterHadiths.filter { !numbered.contains($0.row) && bookData.matches($0, folded) }
    }

    /// One reading of a pure-number query, with the label that says WHICH reading it is.
    private struct NumberMatch: Identifiable {
        let hadith: HadithBookData.Hadith
        let caption: String
        var id: Int { hadith.row }
    }

    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    /// What "5" means while reading a chapter, in both senses a reader could mean it: the 5th hadith of
    /// THIS chapter, and the hadith numbered 5 in the whole book. They are the same row in a
    /// single-chapter book (the forties) and different rows everywhere else; either may not exist, in
    /// which case only the other shows.
    private func numberMatches() -> [NumberMatch] {
        guard let query = HadithBookData.citationNumber(inQuery: searchText) else { return [] }
        let number = query.base
        let ordinal = Self.ordinalFormatter.string(from: NSNumber(value: number)) ?? "\(number)"

        var found: [NumberMatch] = []
        // "8a" names a citation variant, not an ordinal - the in-chapter reading is digits-only.
        if query.suffix == nil, number <= allChapterHadiths.count {
            found.append(NumberMatch(hadith: allChapterHadiths[number - 1], caption: "\(ordinal) in this chapter"))
        }

        if let overall = bookData.hadith(referenced: number, suffix: query.suffix) {
            var caption = "Hadith \(number) in this book"
            // It can live in another chapter - name that chapter, since tapping the row goes there.
            if let home = bookData.chapter(of: overall), home.id != chapter.id {
                caption += " · \(home.english)"
            }
            if let existing = found.firstIndex(where: { $0.hadith.row == overall.row }) {
                found[existing] = NumberMatch(hadith: overall, caption: "\(found[existing].caption) · \(caption)")
            } else {
                found.append(NumberMatch(hadith: overall, caption: caption))
            }
        }
        return found
    }

    /// Land on a match: mark it (the ayah list's arrival) and scroll to it. A number match can point
    /// OUTSIDE the current chapter, so the chapter is swapped in place first - Previous/Next's path.
    private func openMatch(_ hadith: HadithBookData.Hadith, scrollProxy: ScrollViewProxy) {
        let target = hadith.idInBook
        if hadith.chapterId != chapter.id, let home = bookData.chapter(of: hadith) {
            // Clears the search and fires the haptic itself.
            navigateToChapter(home)
        } else {
            settings.hapticFeedback()
            withAnimation { searchText = "" }
        }
        highlightedHadithID = target
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { scrollProxy.scrollTo("chapter-hadith-\(target)", anchor: .top) }
        }
    }

    /// What the page shows, as one choice - backs the title menu's "Page Text" picker, the mushaf's
    /// page-language picker for hadiths. 0 = Arabic & English, 1 = Arabic only, 2 = English only.
    private var pageTextSelection: Binding<Int> {
        Binding(
            get: {
                if settings.showHadithArabic && settings.showHadithEnglish { return 0 }
                return settings.showHadithArabic ? 1 : 2
            },
            set: { value in
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.showHadithArabic = value != 2
                    settings.showHadithEnglish = value != 1
                }
            }
        )
    }

    var body: some View {
        Group {
            // Page mode is the user's reading mode, deep link or not: a target hadith opens the PAGER
            // seeded to its page (the mushaf's way). It used to force the list - "open last read" while
            // in page mode dumped you into list mode, the reported bug.
            if hadithPageMode {
                HadithPagedView(book: book, bookData: bookData, chapterIndex: $chapterIndex, seedHadithID: scrollToHadithId)
                    // The chapter list gets the top accent glow through `applyConditionalListStyle`;
                    // the pager is not a list, so it draws the same wash itself - themed base included.
                    .background(AccentGlowOverlay())
                    .themedReaderBackground()
            } else {
                chapterList
            }
        }
        // ONE pinned chapter-identity header for BOTH reading modes (the title above carries only the
        // book + chapter number, so nothing repeats). The list's progress bar rides on top of it.
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                if !hadithPageMode {
                    ChapterProgressBar(
                        visibility: visibility,
                        firstID: allChapterHadiths.first?.idInBook,
                        lastID: allChapterHadiths.last?.idInBook,
                        isActive: !isSearchActive,
                        color: settings.accentColor.color
                    )
                }

                floatingChapterHeader
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // The SurahView toolbar shape, exactly: the title IS the menu (a glass button carrying the
            // chapter identity), the gear top right. The old leading pages/list button lives in the
            // menu now - the chapters screen keeps its own toggle for the default.
            ToolbarItem(placement: .principal) {
                chapterTitleMenuButton
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    showChapterSettings = true
                } label: {
                    Image(systemName: "gear")
                }
                .accessibilityLabel("Hadith settings")
                .tint(settings.accentColor.accent2)
            }
        }
        #if os(iOS)
        .onChange(of: searchText) { text in
            runChapterAISearch(query: text)
        }
        .onChange(of: semanticEngine.readyCorpora) { ready in
            guard ready.contains("hadith-\(book.slug)"), !searchText.isEmpty else { return }
            runChapterAISearch(query: searchText)
        }
        #endif
        .sheet(isPresented: $showChapterSettings) {
            SettingsHadithView()
                .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showChapterPicker) {
            HadithChapterPickerSheet(book: book, bookData: bookData, currentChapterID: chapter.id) { picked in
                showChapterPicker = false
                guard picked.id != chapter.id else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    navigateToChapter(picked)
                }
            }
            .smallMediumSheetPresentation()
        }
        #if DEBUG
        // Headless visual verification of the share card (no tap access on the dev machine):
        // `-launchHadithOpen abudawud:120 -launchHadithShare` opens the share sheet for the landed hadith.
        .sheet(item: $debugShareHadith) { hadith in
            HadithShareSheet(book: book, hadith: hadith)
        }
        .onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-launchHadithShare"),
                  let id = scrollToHadithId,
                  let target = allChapterHadiths.first(where: { $0.idInBook == id }) else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { debugShareHadith = target }
        }
        #endif
        .onAppear {
            // In LIST mode the chapter is the reading surface, so it owns the Last Read record - routed
            // through the ONE shared debounce slot, deferred past the push transition (`recordLastRead`
            // publishes through the store the PARENT book screen observes and renders, and re-diffing
            // the List hosting the auto-open NavigationLink mid-push is what spuriously popped a
            // deep-linked chapter back to the chapter list). In PAGE mode the pager owns the record -
            // a chapter-level record here raced the pager's and could reset a mid-chapter last-read
            // back to the chapter's first hadith, depending on onAppear ordering.
            guard !hadithPageMode else { return }
            let target = scrollToHadithId.flatMap { id in allChapterHadiths.first { $0.idInBook == id } }
                ?? allChapterHadiths.first
            if let target {
                let book = book
                HadithLastReadDebounce.schedule {
                    HadithStore.shared.recordLastRead(book: book, hadith: target)
                }
            }
        }
        // The paged footer's Previous/Next drives `chapterIndex` directly (it's a Binding into this
        // view) - keep the derived chapter state in lock-step so the title and list follow.
        .onChange(of: chapterIndex) { index in
            syncChapterFromIndex(index)
        }
        // Entering page mode opens where you actually left off - the surah reader's rule: this book's
        // last-read chapter when it has one, chapter 1 otherwise. (Leaving page mode stays put.)
        .onChange(of: hadithPageMode) { isOn in
            guard isOn, scrollToHadithId == nil else { return }
            let target = store.lastRead(for: book.slug)
                .flatMap { last in bookData.chapters.first(where: { $0.id == last.chapterId }) }
                ?? bookData.chapters.first
            guard let target, target.id != chapter.id else { return }
            navigateToChapter(target, recordLastRead: false)
        }
    }

    /// Rebuild the derived chapter state when the INDEX moved without `navigateToChapter` (the paged
    /// footer's chevrons). No-op when already in sync.
    private func syncChapterFromIndex(_ index: Int) {
        guard bookData.chapters.indices.contains(index),
              bookData.chapters[index].id != chapter.id else { return }
        let target = bookData.chapters[index]
        let hadiths = Array(bookData.hadiths(in: target))
        chapter = target
        allChapterHadiths = hadiths
        chapterRange = Self.range(of: hadiths)
        highlightedHadithID = nil
        isSelectingHadiths = false
        selectedHadithIDs = []
        onChapterChanged?(target)
    }

    /// The SurahView title button, for a chapter: the glass label opens a menu with the chapter picker,
    /// multi-select, the pages/list flip, and - the mushaf's page-language picker - what text the page shows.
    private var chapterTitleMenuButton: some View {
        Menu {
            Button {
                settings.hapticFeedback()
                showChapterPicker = true
            } label: {
                Label("Choose Chapter", systemImage: "list.bullet")
            }

            Divider()

            // Multi-select: pick several hadiths, then copy/share/bookmark them all at once. A list-mode
            // feature - entering it from a page flips to the list first, the surah reader's rule.
            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    if hadithPageMode { hadithPageMode = false }
                    isSelectingHadiths = true
                    selectedHadithIDs = []
                }
            } label: {
                Label("Select Hadiths", systemImage: "checkmark.circle")
            }

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    isSelectingHadiths = false
                    selectedHadithIDs = []
                    hadithPageMode.toggle()
                }
            } label: {
                Label(hadithPageMode ? "Read as List" : "Read as Pages",
                      systemImage: hadithPageMode ? "list.bullet.rectangle" : "book")
            }

            // Page mode: what the page's text is - just Arabic, just English, or both. (The same Show
            // Arabic/English switches as settings, reachable where the reading actually happens.)
            if hadithPageMode {
                Menu {
                    Picker("Page Text", selection: pageTextSelection) {
                        Text("Arabic & English").tag(0)
                        Text("Arabic Only").tag(1)
                        Text("English Only").tag(2)
                    }
                } label: {
                    Label("Page Text", systemImage: "character.book.closed")
                }
            }
        } label: {
            chapterTitleLabel
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    /// The title carries the BOOK and the chapter NUMBER only - the chapter's full name (both scripts)
    /// lives in the pinned header below, so the two never repeat each other.
    ///
    /// The surah title's metrics, EXACTLY - same fonts, same sizes, same paddings - so flipping
    /// between the Quran and Hadith readers never makes the title pill visibly grow or shrink.
    private var chapterTitleLabel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // The Latin side never shrinks (a scaled-down title next to full-size Arabic reads
                // as a mistake) - it truncates instead.
                Text(book.englishTitle)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                // Arabic at the surah title's size (headline + 2) whatever the Arabic-face setting:
                // the Basic face used to drop this to plain .headline and scale down to half, which
                // is why this pill sat visibly smaller than the surah reader's.
                HighlightedSnippet(
                    source: book.arabicTitle,
                    term: "",
                    font: Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 2),
                    accent: settings.accentColor.color,
                    fg: settings.accentColor.color,
                    lineLimit: 1
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
            }

            Text("Chapter \(chapterIndex + 1) of \(bookData.chapters.count)")
                .font(.caption2)
                .lineLimit(1)
                // -2, NOT the surah pill's -8: that pull-up is tuned for the Quran faces' contained
                // metrics, but hadith Arabic (full tashkeel, and the Basic face's tall line box) has
                // real descenders here - at -8 they sat on top of this line with no gap at all.
                .padding(.top, -2)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.primary)
        .contentShape(Rectangle())
        .padding(.horizontal)
        .padding(.bottom, 6)
        .conditionalGlassEffect()
    }

    private var chapterList: some View {
        ScrollViewReader { scrollProxy in
        List {
            Group {
                if isSearchActive {
                    // SurahView's search, exactly: the reading list filters IN PLACE - every match as a
                    // FULL row in its own Section, the count pill up top, no paging. Tapping a match
                    // clears the search, scrolls to the hadith, and MARKS it (the ayah list's arrival).
                    let numbered = numberMatches()
                    let matches = chapterMatches()

                    // A number query answers first: the labelled hadith(s) that number names, above
                    // whatever the same digits happen to match in the text.
                    if !numbered.isEmpty {
                        Section(header: SectionPillHeader(title: "BY NUMBER", count: numbered.count)) {}
                            .padding(.bottom, -12)

                        ForEach(numbered) { match in
                            Section {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(match.caption)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)

                                    // No `searchText`: highlighting the digits inside the narration is
                                    // noise - the number is the row's identity here, not a text match.
                                    HadithRow(book: book, hadith: match.hadith, showsChapterPosition: true).equatable()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { openMatch(match.hadith, scrollProxy: scrollProxy) }
                            }
                        }
                    }

                    #if os(iOS)
                    // AI hits the keyword filter (or the number lookup) already shows would render
                    // twice - the AI section carries only the extras, above the keyword rows.
                    let shownRows = Set(matches.map(\.row)).union(numbered.map(\.hadith.row))
                    let aiOnly = chapterAIHits.filter { !shownRows.contains($0.row) }
                    if !aiOnly.isEmpty {
                        Section(header: SectionPillHeader(title: "AI MATCHES", count: aiOnly.count, icon: "sparkles", accentTitle: true)) {}
                            .padding(.bottom, -12)

                        ForEach(aiOnly, id: \.row) { hadith in
                            Section {
                                HadithRow(book: book, hadith: hadith, showsChapterPosition: true).equatable()
                                    .contentShape(Rectangle())
                                    .onTapGesture { openMatch(hadith, scrollProxy: scrollProxy) }
                            }
                        }
                    }
                    #endif

                    // "No hadiths found" would contradict the rows just above it, so the text-match
                    // section stands down entirely once a number has answered.
                    if !matches.isEmpty || numbered.isEmpty {
                        Section(header: SectionPillHeader(title: "MATCHING HADITHS", count: matches.count)) {
                            if matches.isEmpty {
                                Text("No hadiths found.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.bottom, matches.isEmpty ? 0 : -12)
                    }

                    ForEach(matches) { hadith in
                        Section {
                            HadithRow(book: book, hadith: hadith, searchText: searchText, showsChapterPosition: true).equatable()
                                .contentShape(Rectangle())
                                .onTapGesture { openMatch(hadith, scrollProxy: scrollProxy) }
                        }
                    }
                } else {
                    // The Quran ayah list's shape: each hadith is its own Section, with a Previous/Next
                    // chapter pair at the top and bottom that swaps the chapter in place. The chapter's
                    // identity is the pinned header above; rows report visibility for its progress bar.
                    if previousChapter != nil || nextChapter != nil {
                        Section { chapterNavButtonPair() }
                            .id("chapter-top-nav")
                    }

                    ForEach(allChapterHadiths) { hadith in
                        Section {
                            let isSelected = selectedHadithIDs.contains(hadith.idInBook)
                            HadithRow(book: book, hadith: hadith, searchText: searchText, showsChapterPosition: true).equatable()
                                // The ayah list's tap grammar: selecting mode builds the selection
                                // (accent tint); otherwise tap-to-mark (grey attention tint). The row's
                                // own controls (number pill, menu) win their taps either way.
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(isSelectingHadiths && isSelected
                                              ? settings.accentColor.color.opacity(0.16)
                                              : Color.secondary.opacity(highlightedHadithID == hadith.idInBook ? 0.18 : 0))
                                )
                                .padding(-6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    if isSelectingHadiths {
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            if isSelected {
                                                selectedHadithIDs.remove(hadith.idInBook)
                                            } else {
                                                selectedHadithIDs.insert(hadith.idInBook)
                                            }
                                        }
                                    } else {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            highlightedHadithID = highlightedHadithID == hadith.idInBook ? nil : hadith.idInBook
                                        }
                                    }
                                }
                                .id("chapter-hadith-\(hadith.idInBook)")
                                .onAppear { visibility.visibleIDs.insert(hadith.idInBook) }
                                .onDisappear { visibility.visibleIDs.remove(hadith.idInBook) }
                        }
                    }

                    if previousChapter != nil || nextChapter != nil {
                        Section { chapterNavButtonPair() }
                    }
                }
            }
            .themedListRowBackground()
        }
        // The ayah list's fix for a pinned header sitting flush on the first row: breathing room
        // via the list's top content margin, not a phantom spacer row.
        .applyConditionalListStyle(topContentMargin: 11)
        .compactListSectionSpacing()
        .onAppear {
            // A search result or reference landed here: settle, then scroll to the hadith itself - and
            // MARK it (the Quran's arrival rule: the selection shows you where you landed; tap to clear).
            guard let target = scrollToHadithId else { return }
            highlightedHadithID = target
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { scrollProxy.scrollTo("chapter-hadith-\(target)", anchor: .top) }
            }
        }
        // (The pinned chapter header + progress bar live at the BODY level now, shared with page mode.)
        .onChange(of: chapterIndex) { _ in
            // A Previous/Next chapter swap lands at the LITERAL top of the new chapter - the nav
            // buttons above the first hadith included - not at hadith 1 with them scrolled away.
            let target: String
            if previousChapter != nil || nextChapter != nil {
                target = "chapter-top-nav"
            } else if let first = allChapterHadiths.first?.idInBook {
                target = "chapter-hadith-\(first)"
            } else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { scrollProxy.scrollTo(target, anchor: .top) }
            }
        }
        // Apple Music-style: the bottom search bar minimizes while scrolling down. Select mode swaps
        // the search for the bulk-action bar, exactly like the surah reader's list.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            if isSelectingHadiths {
                selectionActionBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .background(Color.white.opacity(0.00001))
            } else {
                SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut))
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .background(Color.white.opacity(0.00001))
                    .minimizedBarStyle(barsCollapsed)
            }
        }
        }
    }

    // MARK: Multi-select (the surah reader's bulk actions, for hadiths)

    private var selectedHadiths: [HadithBookData.Hadith] {
        allChapterHadiths.filter { selectedHadithIDs.contains($0.idInBook) }
    }

    /// The bulk-action bar shown while selecting: count, Copy, Share, Bookmark, Done - one glass bar
    /// where the search normally sits.
    private var selectionActionBar: some View {
        HStack(spacing: 16) {
            Text("\(selectedHadithIDs.count)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(selectedHadithIDs.isEmpty ? .secondary : .primary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = selectedHadiths
                    .map { HadithShareSheet.composedText(book: book, hadith: $0) }
                    .joined(separator: "\n\n")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.body.weight(.semibold))
            }
            .disabled(selectedHadithIDs.isEmpty)

            Button {
                settings.hapticFeedback()
                let text = selectedHadiths
                    .map { HadithShareSheet.composedText(book: book, hadith: $0) }
                    .joined(separator: "\n\n")
                presentSystemShareSheet(items: [text])
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
            }
            .disabled(selectedHadithIDs.isEmpty)

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    for hadith in selectedHadiths where !store.isBookmarked(slug: book.slug, idInBook: hadith.idInBook) {
                        store.toggleBookmark(book: book, hadith: hadith)
                    }
                }
            } label: {
                Image(systemName: "bookmark")
                    .font(.body.weight(.semibold))
            }
            .disabled(selectedHadithIDs.isEmpty)

            Spacer()

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    isSelectingHadiths = false
                    selectedHadithIDs = []
                }
            } label: {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .foregroundStyle(settings.accentColor.color)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .conditionalGlassEffect(rectangle: true)
    }

    /// The chapter's identity, pinned above the list - reorganized around the ordinal chip: number in
    /// glass leading (the surah header's badge), name + Arabic stacked beside it, the count pill with
    /// the hadith span trailing. One consistent grammar with the book view's pinned header below.
    private var floatingChapterHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("\(chapterIndex + 1)")
                .font(.caption.weight(.bold))
                .foregroundColor(settings.accentColor.color)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .conditionalGlassEffect()

            VStack(alignment: .leading, spacing: 1) {
                // ONE line, like every other floating overlay in the Quran and hadith readers: a two-line
                // title made the pinned header grow and shove the reading surface down mid-scroll.
                // The title is the one PRIMARY element - the chapter row's grammar, where the English
                // name leads and the Arabic and the span sit secondary beneath it; an all-secondary bar
                // read as one grey block with nothing to hold on to.
                Text((chapter.english.isEmpty ? book.englishTitle : chapter.english).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if !chapter.arabic.isEmpty {
                    // Comma-safe via the snippet renderer, like every other Arabic label in this tab.
                    HighlightedSnippet(
                        source: chapter.arabic,
                        term: "",
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

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                CountPill(count: allChapterHadiths.count)

                if let range = chapterRange {
                    Text(range.lowerBound == range.upperBound
                         ? "HADITH \(range.lowerBound)"
                         : "HADITHS \(range.lowerBound)-\(range.upperBound)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 0)
        .conditionalGlassEffect(rectangle: true)
        .padding(.top, 4)
        .padding(.horizontal, settings.defaultView ? 20 : 16)
        .zIndex(1)
    }

    /// Previous | Next chapter, side by side - the surah reader's navigation pair, in ITS order:
    /// Previous on the left, Next on the right. (Only the PAGES turn right-to-left.)
    @ViewBuilder
    private func chapterNavButtonPair() -> some View {
        HStack(spacing: 10) {
            if let previousChapter {
                chapterNavButton(title: "Previous", chapter: previousChapter, systemImage: "chevron.left", trailing: false)
            }
            if let nextChapter {
                chapterNavButton(title: "Next", chapter: nextChapter, systemImage: "chevron.right", trailing: true)
            }
        }
    }

    private func chapterNavButton(title: String, chapter target: HadithBookData.Chapter, systemImage: String, trailing: Bool) -> some View {
        let ordinal = (bookData.chapters.firstIndex(where: { $0.id == target.id }) ?? 0) + 1
        return Button {
            navigateToChapter(target)
        } label: {
            HStack(spacing: 8) {
                if !trailing {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }

                VStack(alignment: trailing ? .trailing : .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text("\(ordinal). \(target.english.isEmpty ? book.englishTitle : target.english)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)

                if trailing {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chapter picker (the SurahPickerSheet, for chapters)

/// The title menu's "Choose Chapter": every chapter with its ordinal, names, and count - the current
/// one highlighted - swapping the chapter IN PLACE on selection, the surah picker's exact behavior.
struct HadithChapterPickerSheet: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let book: HadithCatalogBook
    let bookData: HadithBookData
    let currentChapterID: Int
    let onPick: (HadithBookData.Chapter) -> Void

    @State private var searchText = ""

    /// Hadith counts per chapter. `Chapter.rowCount` was computed when the pack was built, so this
    /// is O(chapters) - the old whole-book reduce re-ran per body pass of the sheet, per keystroke.
    private var countsByChapter: [Int: Int] {
        bookData.chapters.reduce(into: [:]) { $0[$1.id] = $1.rowCount }
    }

    private var filteredChapters: [(offset: Int, element: HadithBookData.Chapter)] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = Array(bookData.chapters.enumerated())
        guard !query.isEmpty else { return all }
        if query.containsArabicScript {
            // Compare against the fold the pack precomputed (like the chapter list's own filter does)
            // instead of live-cleaning every chapter title on main per keystroke.
            let folded = HadithFold.query(query)
            return all.filter { bookData.matches($0.element, folded) }
        }
        return all.filter {
            $0.element.english.localizedCaseInsensitiveContains(query) || String($0.offset + 1) == query
        }
    }

    /// Open ALREADY positioned on the current chapter - the surah picker's exact behavior. The
    /// repeated fire covers the sheet transition swallowing a scroll issued mid-presentation.
    private func scrollToCurrentChapter(_ proxy: ScrollViewProxy) {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard filteredChapters.contains(where: { $0.element.id == currentChapterID }) else { return }

        let requestScroll = { proxy.scrollTo(currentChapterID, anchor: .center) }
        DispatchQueue.main.async {
            requestScroll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { requestScroll() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { requestScroll() }
        }
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
            List {
                let counts = countsByChapter
                ForEach(filteredChapters, id: \.element.id) { offset, chapter in
                    Button {
                        settings.hapticFeedback()
                        onPick(chapter)
                    } label: {
                        HStack(spacing: 10) {
                            Text("\(offset + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(settings.accentColor.color)
                                .frame(minWidth: 30)
                                .padding(.vertical, 6)
                                .conditionalGlassEffect(
                                    useColor: chapter.id == currentChapterID ? 0.3 : nil,
                                    customTint: chapter.id == currentChapterID ? settings.accentColor.color : nil
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(chapter.english.isEmpty ? book.englishTitle : chapter.english)
                                    .font(.subheadline.weight(chapter.id == currentChapterID ? .bold : .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.7)

                                if !chapter.arabic.isEmpty {
                                    HighlightedSnippet(
                                        source: chapter.arabic,
                                        term: "",
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

                            Spacer(minLength: 8)

                            if let count = counts[chapter.id] {
                                CountPill(count: count)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .themedListRowBackground()
                    .id(chapter.id)
                }
            }
            .applyConditionalListStyle()
            .compactListSectionSpacing()
            .navigationTitle("Choose Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search chapters")
            .dismissKeyboardOnScroll()
            .sheetDismissToolbar()
            .onAppear { scrollToCurrentChapter(proxy) }
            }
        }
        .navigationViewStyle(.stack)
        .accentColor(settings.accentColor.color)
    }
}

// MARK: - Page mode: as many hadiths per page as fit, right-to-left, chapter by chapter

/// The paged reader, in the mushaf's manner: pages turn RIGHT-TO-LEFT, and each page carries as many
/// whole hadiths as the current Arabic/English font sizes allow. Chapter-scoped - paging all ~7,500
/// hadiths of Bukhari through one TabView is the page-realization stampede the Quran mushaf had to
/// engineer around; a chapter is at most a few hundred light pages.
///
/// Layout rules: a chapter heading is never left as the last thing on a page (it moves to the top of
/// the next page so its hadiths follow it), and a hadith is atomic - its reference line and its text
/// always travel together.
struct HadithPagedView: View {
    @ObservedObject private var settings = Settings.shared
    /// The paged header's bookmark tint reads user marks (via the store's forwards) - this
    /// observation is what refreshes it when a bookmark toggles.
    @ObservedObject private var userData = HadithUserData.shared

    let book: HadithCatalogBook
    let bookData: HadithBookData

    /// Bound to the parent chapter view, so Choose Chapter, Previous/Next, and the title all stay in
    /// sync - the pager no longer keeps a private copy that could drift.
    @Binding var chapterIndex: Int
    /// A deep-link target (last read, bookmark, search result): the pager opens on ITS page instead of
    /// the book's last-read seed. Nil for a plain chapter open.
    var seedHadithID: Int? = nil
    @State private var pageIndex = 0
    /// ONE hadith per page, rendered at the user's exact hadith font sizes - no fit-to-page shrinking
    /// and no mid-hadith splitting. A hadith taller than the screen simply scrolls within its page.
    private struct BuiltPage {
        let elements: [PageElement]
    }

    /// Seed-once guard: the reader opens on the page holding this book's last-read hadith (when it is
    /// in this chapter), then never yanks the user again.
    @State private var didSeedPage = false
    /// The deep-link target is honored on the FIRST seed only; re-arms (chapter swaps) follow the live
    /// last read instead.
    @State private var didConsumeDeepLinkSeed = false

    /// Which inline wheel is open above the footer - the mushaf reader's page/juz picker, reshaped
    /// for hadiths and chapters.
    private enum PickerTarget { case hadith, chapter }
    @State private var activePicker: PickerTarget?
    @State private var hadithPickerSelection = 0
    @State private var chapterPickerSelection = 0

    /// One renderable part of a hadith's page (header capsule, Arabic, narrator, English).
    private enum PageElement: Identifiable {
        case hadithHeader(HadithBookData.Hadith)
        case arabic(HadithBookData.Hadith)
        case narrator(HadithBookData.Hadith)
        case english(HadithBookData.Hadith)
        case grades(HadithBookData.Hadith)

        var id: String {
            switch self {
            case .hadithHeader(let hadith): return "hdr-\(hadith.id)"
            case .arabic(let hadith): return "ar-\(hadith.id)"
            case .narrator(let hadith): return "narr-\(hadith.id)"
            case .english(let hadith): return "en-\(hadith.id)"
            case .grades(let hadith): return "gr-\(hadith.id)"
            }
        }

        var hadith: HadithBookData.Hadith? {
            switch self {
            case .hadithHeader(let hadith), .arabic(let hadith),
                 .narrator(let hadith), .english(let hadith),
                 .grades(let hadith):
                return hadith
            }
        }
    }

    private var chapter: HadithBookData.Chapter? {
        bookData.chapters.indices.contains(chapterIndex) ? bookData.chapters[chapterIndex] : nil
    }

    private var chapterHadiths: [HadithBookData.Hadith] {
        // A slice of the row table, so there is nothing left to memoize: the cache this used to keep
        // existed only to avoid re-filtering the whole book on every body pass.
        guard let chapter else { return [] }
        return Array(bookData.hadiths(in: chapter))
    }

    /// Drops every derived static cache (built pages, ordinals). Built pages retain whole chapters of
    /// text, so the store's memory-pressure trim calls this - otherwise the trim's savings would be
    /// partly pinned here, holding decompressed chapters the reader has left.
    static func clearDerivedCaches() {
        builtPagesCache.removeAll(keepingCapacity: false)
        ordinalCache.removeAll(keepingCapacity: false)
    }

    /// Built pages, memoized on the only inputs that change them: the chapter and the two display
    /// toggles. `body` runs on every page turn and every settings publish (a font-size slider drag
    /// publishes per step), and this map used to re-allocate O(chapter) arrays each time.
    private static var builtPagesCache: [String: [BuiltPage]] = [:]

    private func builtPages() -> [BuiltPage] {
        let key = "\(book.slug)-\(chapter?.id ?? -1)-\(settings.showHadithArabic ? 1 : 0)\(settings.showHadithEnglish ? 1 : 0)"
        if let cached = Self.builtPagesCache[key] { return cached }

        let pages = chapterHadiths.map { hadith in
            // One block lookup for the emptiness checks instead of one per field.
            let text = hadith.allText
            var elements: [PageElement] = [.hadithHeader(hadith)]
            if settings.showHadithArabic, !text.arabic.isEmpty {
                elements.append(.arabic(hadith))
            }
            if settings.showHadithEnglish {
                if !text.narrator.isEmpty { elements.append(.narrator(hadith)) }
                if !text.text.isEmpty { elements.append(.english(hadith)) }
            }
            // The grade line trails the text - after the English, or after the Arabic when English is
            // off or absent (the reading rows' placement). Always shown: the grading is part of the
            // hadith, not a preference - a reader must be able to tell sahih from da'if.
            if !hadith.grades.isEmpty {
                elements.append(.grades(hadith))
            }
            return BuiltPage(elements: elements)
        }
        if Self.builtPagesCache.count > 24 { Self.builtPagesCache.removeAll(keepingCapacity: true) }
        Self.builtPagesCache[key] = pages
        return pages
    }

    var body: some View {
        let pages = builtPages()

        Group {
            if pages.isEmpty {
                Text("This chapter has no hadiths.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Right-to-left, exactly like the mushaf: the DATA is reversed rather than the layout
                // direction, so page 0 sits at the far right and reading advances leftward.
                TabView(selection: $pageIndex) {
                    ForEach(pages.indices.reversed(), id: \.self) { index in
                        pageBody(pages[index].elements)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .safeAreaInset(edge: .bottom) {
            pagerFooter(pageCount: pages.count)
        }
        .onAppear {
            // Open on the page holding the deep-link target (or this book's last-read hadith) - the
            // mushaf's "open where you stopped" - then record that page as the new last read via the
            // ONE debounced recorder below.
            let seeded = seedPageIfNeeded(pages)
            scheduleRecordLastRead(pages: pages, at: seeded ?? pageIndex)
        }
        .onChange(of: pageIndex) { index in
            scheduleRecordLastRead(pages: pages, at: index)
        }
        .onChange(of: chapterIndex) { _ in
            // A chapter swap re-arms the last-read seed: when the book's last read lives in the
            // NEW chapter (the page-mode entry jump), land on its exact page - otherwise hadith 1.
            didSeedPage = false
            activePicker = nil
            if let seeded = seedPageIfNeeded(pages) {
                scheduleRecordLastRead(pages: pages, at: seeded)
            } else {
                // Record page 1 EXPLICITLY: when `pageIndex` was already 0 (jumping chapters from the
                // wheel while on a chapter's first page), the assignment below fires no `.onChange`,
                // and the newly-opened chapter never became the last read.
                pageIndex = 0
                scheduleRecordLastRead(pages: pages, at: 0)
            }
        }
        // No title of its own: the parent chapter view's principal title-menu button owns the bar.
    }

    /// The ONE path a page becomes the last read, trailing-debounced 1.0s through the shared slot. This
    /// closes two holes the separate immediate/deferred records had: the onAppear SEED sets `pageIndex`,
    /// whose `.onChange` used to record immediately - a store publish mid-push that re-rendered the
    /// ancestor book screen (which observes the store) and could pop this very view; and a page turn
    /// inside the first second recorded instantly, only to be overwritten by the stale deferred landing
    /// record. A single debounce slot means the LAST record standing wins, always past the transition.
    private func scheduleRecordLastRead(pages: [BuiltPage], at index: Int) {
        HadithLastReadDebounce.schedule {
            recordPageLastRead(pages: pages, at: index)
        }
    }

    /// Land on the target hadith's page, once per open: the explicit deep-link target when there is
    /// one, this book's last-read hadith otherwise. Returns the seeded index when it resolved.
    private func seedPageIfNeeded(_ pages: [BuiltPage]) -> Int? {
        guard !didSeedPage else { return nil }
        didSeedPage = true

        // The deep-link target seeds exactly ONCE. It used to win every re-arm (chapter swap and
        // back), yanking the pager - and the follow-up record - BACK to the original target after the
        // user had read past it, regressing their last read to a position they'd already left.
        let deepLinkTarget: Int?
        if let seedHadithID, !didConsumeDeepLinkSeed {
            didConsumeDeepLinkSeed = true
            deepLinkTarget = seedHadithID
        } else {
            deepLinkTarget = nil
        }
        let targetID: Int? = deepLinkTarget ?? {
            guard let chapter,
                  let lastRead = HadithStore.shared.lastRead(for: book.slug),
                  lastRead.chapterId == chapter.id
                    || chapterHadiths.contains(where: { $0.idInBook == lastRead.idInBook })
            else { return nil }
            return lastRead.idInBook
        }()

        guard let targetID, let index = pages.firstIndex(where: { page in
            page.elements.contains { $0.hadith?.idInBook == targetID }
        }) else { return nil }
        // Report the landing page even when it's the one already showing - callers treat nil as
        // "nothing to seed" and reset to page 1.
        if index != pageIndex { pageIndex = index }
        return index
    }

    /// The CURRENT page's first hadith becomes the Last Read - it used to record the chapter's first
    /// hadith on every turn, so "last read" never moved past page one.
    private func recordPageLastRead(pages: [BuiltPage], at index: Int) {
        guard pages.indices.contains(index) else { return }
        for element in pages[index].elements {
            if let hadith = element.hadith {
                HadithStore.shared.recordLastRead(book: book, hadith: hadith)
                return
            }
        }
    }

    /// 1-based ordinals by `idInBook`, memoized per chapter. The old arithmetic
    /// (`idInBook - first.idInBook + 1`) assumed a chapter's ids are gapless - any gap in the source
    /// data displayed a wrong (even out-of-range) position. Position IS the ordinal; derive it from it.
    private static var ordinalCache: [String: [Int: Int]] = [:]

    /// The hadith's position within this chapter, for the header capsule ("3 - 102 Book").
    private func chapterHadithNumber(_ hadith: HadithBookData.Hadith) -> Int? {
        let key = "\(book.slug)-\(chapter?.id ?? -1)"
        if let map = Self.ordinalCache[key] { return map[hadith.idInBook] }
        // `uniquingKeysWith`: the whole point of this rewrite is that CDN ids are imperfect - a
        // duplicate idInBook within a chapter must show the first position, not trap the app.
        let map = Dictionary(chapterHadiths.enumerated().map { ($1.idInBook, $0 + 1) },
                             uniquingKeysWith: { first, _ in first })
        if Self.ordinalCache.count > 48 { Self.ordinalCache.removeAll(keepingCapacity: true) }
        Self.ordinalCache[key] = map
        return map[hadith.idInBook]
    }

    /// The page header's actions, shared verbatim by the ellipsis Menu and the long-press context menu.
    @ViewBuilder
    private func hadithHeaderActions(_ hadith: HadithBookData.Hadith, isBookmarked: Bool) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { HadithStore.shared.toggleBookmark(book: book, hadith: hadith) }
        } label: {
            Label(isBookmarked ? "Remove Bookmark" : "Bookmark Hadith",
                  systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
        }

        Button {
            settings.hapticFeedback()
            UIPasteboard.general.string = HadithShareSheet.composedText(book: book, hadith: hadith)
        } label: {
            Label("Copy Hadith", systemImage: "doc.on.doc")
        }

        Button {
            settings.hapticFeedback()
            presentSystemShareSheet(items: [HadithShareSheet.composedText(book: book, hadith: hadith)])
        } label: {
            Label("Share Hadith", systemImage: "square.and.arrow.up")
        }
    }

    private func pageBody(_ elements: [PageElement]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(elements) { element in
                    blockView(element)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    /// One flowed block, rendered with the reading rows' exact styles (fonts, comma fallback, Allah
    /// highlighting) - the page IS the row, just flowing across pages.
    @ViewBuilder
    private func blockView(_ element: PageElement) -> some View {
        switch element {
        case .hadithHeader(let hadith):
            // The reading row's exact header grammar: tap the pill to toggle the bookmark (tinted +
            // corner badge when set), and the same actions behind an always-ellipsis button - page
            // mode used to offer only a long-press context menu, which read as "can't bookmark here".
            let isBookmarked = HadithStore.shared.isBookmarked(slug: book.slug, idInBook: hadith.idInBook)

            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    if let chapterNumber = chapterHadithNumber(hadith) {
                        Text("\(chapterNumber)")
                            .font(.subheadline.monospacedDigit().weight(.semibold))

                        Text("-")
                            .font(.caption.weight(.semibold))
                            .opacity(0.55)
                    }

                    Text(hadith.displayNumber)
                        .font(.subheadline.monospacedDigit().weight(.semibold))

                    Text(book.englishTitle)
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 8)
                .frame(height: 26)
                .conditionalGlassEffect(
                    useColor: isBookmarked ? 0.3 : nil,
                    customTint: isBookmarked ? settings.accentColor.color : nil,
                    interactive: false
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { HadithStore.shared.toggleBookmark(book: book, hadith: hadith) }
                }
                .overlay(alignment: .topTrailing) {
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(settings.accentColor.color)
                            .padding(4)
                            .offset(x: 8, y: -6)
                    }
                }

                Spacer(minLength: 0)

                Menu {
                    hadithHeaderActions(hadith, isBookmarked: isBookmarked)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 23, height: 23)
                        .foregroundColor(settings.accentColor.color)
                        .conditionalGlassEffect()
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
            }
            .contextMenu {
                hadithHeaderActions(hadith, isBookmarked: isBookmarked)
            }

        case .arabic(let hadith):
            // The font comes from `hadithArabicFont(for:)`: the longest narrations fall back to the
            // system face, because the custom KFGQPC faces DROP contextual shaping past a length
            // cliff and every letter renders isolated (see `arabicShapingCharacterLimit`).
            HighlightedSnippet(
                source: hadith.arabic,
                term: "",
                font: settings.hadithArabicFont(for: hadith.arabic, size: settings.hadithArabicFontSize),
                accent: settings.accentColor.color,
                fg: .primary,
                highlightAllahNames: settings.highlightAllahNamesHadith
            )
            .arabicFontDesign(custom: settings.hadithArabicUsesCustomFace(for: hadith.arabic))
            .multilineTextAlignment(.trailing)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)

        case .narrator(let hadith):
            // HighlightedSnippet (not a plain Text) so the narrator line gets the Allah highlight in
            // page mode too - it's English text like the body, and the list rows already color it.
            HighlightedSnippet(
                source: hadith.english.narrator,
                term: "",
                font: .system(size: settings.hadithEnglishFontSize).italic(),
                accent: settings.accentColor.color,
                fg: .secondary,
                highlightAllahNames: settings.highlightAllahNamesHadith
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)

        case .english(let hadith):
            HighlightedSnippet(
                source: hadith.english.text,
                term: "",
                font: .system(size: settings.hadithEnglishFontSize),
                accent: settings.accentColor.color,
                fg: .primary,
                highlightAllahNames: settings.highlightAllahNamesHadith
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)

        case .grades(let hadith):
            // The reading rows' grade line, verbatim - never parsed, ranked, or colored.
            HadithGradeLine(grades: hadith.grades)
                .textSelection(.enabled)
        }
    }

    private func pagerFooter(pageCount: Int) -> some View {
        VStack(spacing: 6) {
            TrackedBar(
                fraction: pageCount > 1 ? CGFloat(pageIndex) / CGFloat(pageCount - 1) : 1,
                height: 3,
                color: settings.accentColor.color
            )
            .padding(.horizontal, 2)

            if activePicker != nil {
                inlinePicker(pageCount: pageCount)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // The mushaf footer's grammar: the readouts ARE the buttons that open their pickers -
            // "Hadith X / Y" and "Chapter A / B" each unfold an inline wheel, no chevron-stepping.
            HStack(spacing: 10) {
                jumpButton(
                    title: pageCount > 0 ? "Hadith \(pageIndex + 1) / \(pageCount)" : "Hadith - / -",
                    target: .hadith
                ) {
                    hadithPickerSelection = pageIndex
                }

                jumpButton(
                    title: "Chapter \(chapterIndex + 1) / \(bookData.chapters.count)",
                    target: .chapter
                ) {
                    chapterPickerSelection = chapterIndex
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    /// The readouts double as the buttons that open their picker. `seed` sets the wheel to where you
    /// currently are, so opening it and confirming without touching it is a no-op.
    private func jumpButton(title: String, target: PickerTarget, seed: @escaping () -> Void) -> some View {
        let isOpen = activePicker == target

        return Button {
            settings.hapticFeedback()
            if !isOpen { seed() }
            withAnimation(.easeInOut) {
                activePicker = isOpen ? nil : target
            }
        } label: {
            HStack(spacing: 3) {
                Text(title)
                Image(systemName: isOpen ? "chevron.down" : "chevron.up.chevron.down")
                    .font(.system(size: 7))
            }
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(settings.accentColor.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(settings.accentColor.color.opacity(isOpen ? 0.22 : 0.12))
            )
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .accessibilityLabel("\(title). Jump to")
    }

    /// The hadith and chapter pickers, in place rather than as a sheet - the mushaf's page/juz picker
    /// chrome (xmark / title / checkmark over a wheel), reshaped for this reader.
    private func inlinePicker(pageCount: Int) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { activePicker = nil }
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(activePicker == .hadith ? "Go to Hadith" : "Go to Chapter")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    settings.hapticFeedback()
                    switch activePicker {
                    case .hadith:
                        // Clamped: the selection was seeded against the page list it was opened with.
                        pageIndex = min(max(hadithPickerSelection, 0), max(pageCount - 1, 0))
                    case .chapter:
                        let target = min(max(chapterPickerSelection, 0), max(bookData.chapters.count - 1, 0))
                        if target != chapterIndex {
                            withAnimation(.easeInOut) { chapterIndex = target }
                        }
                    case nil:
                        break
                    }
                    withAnimation(.easeInOut) { activePicker = nil }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(settings.accentColor.accent2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            Group {
                if activePicker == .hadith {
                    Picker("Hadith", selection: $hadithPickerSelection) {
                        ForEach(0..<max(pageCount, 1), id: \.self) { i in
                            // Within-chapter position plus the book-wide citation number.
                            if chapterHadiths.indices.contains(i) {
                                Text("Hadith \(i + 1)  (#\(chapterHadiths[i].displayNumber))").tag(i)
                            } else {
                                Text("Hadith \(i + 1)").tag(i)
                            }
                        }
                    }
                } else {
                    Picker("Chapter", selection: $chapterPickerSelection) {
                        ForEach(0..<max(bookData.chapters.count, 1), id: \.self) { i in
                            if bookData.chapters.indices.contains(i) {
                                Text("\(i + 1). \(bookData.chapters[i].english)").tag(i)
                            } else {
                                Text("Chapter \(i + 1)").tag(i)
                            }
                        }
                    }
                }
            }
            .labelsHidden()
            .pickerStyle(.wheel)
            .frame(height: 110)
        }
    }
}

#endif

#if os(iOS)
/// Builds (or disk-loads) one book's semantic corpus - shared by the book screen's search and the
/// within-chapter search, which scope the same corpus differently.
@MainActor
private func prepareBookSemanticCorpus(_ engine: SemanticSearchEngine, data: HadithBookData, corpusID: String) {
        guard SemanticSearchEngine.isSupported,
              !engine.isReady(corpusID),
              !engine.isBuilding(corpusID) else { return }
        // The count, not the texts: the version must not be what forces the whole book into memory.
        let version = "v3-\(data.hadiths.count)"
        // Disk-first probe with no texts at all - a corpus built in an earlier session loads in one
        // read, and the gather below never runs. (`prepare` no-ops on an empty list past that check.)
        engine.prepare(corpusID: corpusID, version: version, texts: [])
        guard !engine.isReady(corpusID) else { return }

        Task {
            // OFF-MAIN: this reads every hadith in the book, which over the packs means decompressing
            // all of it. It used to run inline here, on the main thread, a second after the book opened.
            let built = await Task.detached(priority: .utility) { () -> (texts: [String], keys: [String]) in
                var texts: [String] = []
                var keys: [String] = []
                texts.reserveCapacity(data.hadiths.count)
                keys.reserveCapacity(data.hadiths.count)
                for hadith in data.hadiths {
                    let strings = hadith.allText
                    texts.append("\(strings.narrator) \(strings.text)")
                    // Keyed by idInBook (the all-books corpus's rule): positional mapping meant a data
                    // update that REORDERS hadiths without changing the count served persisted vectors
                    // for the wrong hadith. v3 bumps past existing positional caches.
                    keys.append(String(hadith.idInBook))
                }
                return (texts, keys)
            }.value
            engine.prepare(corpusID: corpusID, version: version,
                                   texts: built.texts, keys: built.keys)
        }
}
#endif
