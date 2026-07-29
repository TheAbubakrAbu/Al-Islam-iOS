import SwiftUI

// One collection: the chapter list (with in-place page mode), one chapter, and the right-to-left
// paged reader that fits as many hadiths per page as the font sizes allow.

#if os(iOS)

// MARK: - One collection: chapters + book search + page mode

struct HadithBookView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared
    /// Chapter favorites render through the store's forwards; the data publishes from HadithUserData,
    /// so this observation is what re-renders the pills/tiles when a favorite toggles.
    @ObservedObject private var userData = HadithUserData.shared

    let book: HadithCatalogBook

    @State private var data: HadithBookData?
    @State private var loadError: String?
    @State private var searchText = ""
    @State private var loadAttempt = 0
    /// A book that is NOT yet on this device asks before fetching (they are big); this flips on confirm.
    @State private var didConfirmDownload = false
    @State private var confirmDownload = false
    /// "Read Without Downloading": the book loads into the session's memory cache only - full reading,
    /// zero storage kept afterward.
    @State private var temporaryRead = false
    @State private var confirmDeleteDownload = false
    /// The loading spinner waits a beat before appearing - a downloaded book decodes fast enough that
    /// flashing a full loading screen for it read as a glitch.
    @State private var showLoadingSpinner = false
    /// The chapter list shares the tab's grid/list choice, with its own copy of the toggle up top.
    @AppStorage("hadithGridMode") private var hadithGridMode = false
    /// How chapters open (pages by default, the Quran mushaf's way) - the toggle sits top left here
    /// exactly as it does in the chapter itself, but flips the setting rather than this screen.
    @AppStorage("hadithPageMode") private var hadithPageMode = true
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
    }

    private func prepareSemanticCorpus(_ data: HadithBookData) {
        guard SemanticSearchEngine.isSupported, !semanticEngine.isReady(semanticCorpusID) else { return }
        let texts = data.hadiths.map { "\($0.english.narrator) \($0.english.text)" }
        // Keyed by idInBook (the all-books corpus's rule): positional `data.hadiths[$0.index]` mapping
        // meant a CDN update that REORDERS hadiths without changing the count served persisted vectors
        // for the wrong hadith. v3 bumps past existing positional caches.
        let keys = data.hadiths.map { String($0.idInBook) }
        semanticEngine.prepare(corpusID: semanticCorpusID, version: "v3-\(texts.count)", texts: texts, keys: keys)
    }

    // Ask (the on-device LLM, grounded RAG): question-shaped queries stream an answer card above the
    // matches, drawn strictly from THIS book's retrieved hadiths - the Quran search's exact feature.
    @State private var askAnswer = ""
    @State private var askIsStreaming = false
    @State private var askRanForQuery = ""
    /// A MANUAL ask that found nothing to ground on or errored - the tapped row must answer with
    /// SOMETHING instead of silently restoring the prompt (the Quran search's `askNoAnswer`).
    @State private var askNoAnswer = false
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist (the Quran search's
    /// `showKeywordResults`). Reset to the AI list on every new query.
    @State private var showBookKeywordResults = false
    @State private var askTask: Task<Void, Never>?

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
            var seen = Set<Int>()
            for hadith in aiHits.prefix(6) where seen.insert(hadith.idInBook).inserted {
                sources.append(.init(reference: "\(book.englishTitle) \(hadith.idInBook)",
                                     text: hadith.english.text.isEmpty ? hadith.english.narrator : hadith.english.text))
            }
            // From the already-settled STATE (the 200ms scan finishes well inside this 900ms wait),
            // not the synchronous full-book scan - Ask's auto path is not a user gesture.
            for hadith in inBookMatches.shown.prefix(6) where seen.insert(hadith.idInBook).inserted {
                sources.append(.init(reference: "\(book.englishTitle) \(hadith.idInBook)",
                                     text: hadith.english.text.isEmpty ? hadith.english.narrator : hadith.english.text))
            }
            guard !sources.isEmpty else {
                askAnswer = ""; askIsStreaming = false; askRanForQuery = ""
                // A tapped ask MUST respond: with nothing retrieved to ground on, say so instead of
                // silently restoring the prompt row.
                if manual { askNoAnswer = true }
                return
            }

            askAnswer = ""; askIsStreaming = true; askRanForQuery = trimmed
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
                askAnswer = ""; askIsStreaming = false; askRanForQuery = ""
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

    init(book: HadithCatalogBook, autoOpenHadithID: Int? = nil) {
        self.book = book
        self.autoOpenHadithID = autoOpenHadithID
        // A book still in the session's memory cache renders instantly - no task hop, no flash.
        _data = State(initialValue: HadithStore.shared.cachedBook(book.slug))
    }

    /// Offline books open straight away; everything else shows the info + download/temporary prompt first.
    private var needsDownloadPrompt: Bool {
        data == nil && !store.isAvailableOffline(book) && !didConfirmDownload && !temporaryRead
    }

    /// Everything the chapter rows read per render, computed ONCE per book. These used to be computed
    /// vars over `data.hadiths` - a full O(hadiths) walk on every access, per row, per render (Bukhari:
    /// 97 rows x 7,500 hadiths each pass). The book data is immutable, so memoize by slug - the same
    /// discipline as the surah reader's prepared cache.
    struct ChapterStats {
        let counts: [Int: Int]
        let ranges: [Int: ClosedRange<Int>]
        let ordinals: [Int: Int]

        init(_ data: HadithBookData) {
            var counts: [Int: Int] = [:]
            var ranges: [Int: ClosedRange<Int>] = [:]
            for hadith in data.hadiths {
                counts[hadith.chapterId, default: 0] += 1
                if let existing = ranges[hadith.chapterId] {
                    ranges[hadith.chapterId] = min(existing.lowerBound, hadith.idInBook)...max(existing.upperBound, hadith.idInBook)
                } else {
                    ranges[hadith.chapterId] = hadith.idInBook...hadith.idInBook
                }
            }
            self.counts = counts
            self.ranges = ranges
            self.ordinals = Dictionary(uniqueKeysWithValues: data.chapters.enumerated().map { ($0.element.id, $0.offset + 1) })
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
        if query.containsArabicScript {
            let cleanQuery = settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns
            return data.chapters.filter {
                settings.cleanSearch($0.arabic, whitespace: true).removingArabicDiacriticsAndSigns.contains(cleanQuery)
            }
        }
        return data.chapters.filter { $0.english.localizedCaseInsensitiveContains(query) }
    }

    /// Book-wide hadith search (English text/narrator + diacritic-insensitive Arabic), the Quran
    /// search's way: scan only until one PAST the shown page, so finding page one of a common word
    /// in Bukhari never walks all 7,500 hadiths. `hasMore` renders the count pill as "5+".
    /// The debounced, off-main scan feeding `inBookMatches` - the body reads state, never scans.
    private func runInBookSearch(_ data: HadithBookData) {
        inBookSearchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3 else {
            if !inBookMatches.shown.isEmpty || inBookMatches.hasMore { inBookMatches = ([], false) }
            return
        }
        let arabicQuery = query.containsArabicScript
        let cleanQuery = arabicQuery ? settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns : ""
        let lowerQuery = HighlightedSnippet.foldedEnglishForSearch(query)
        let index = store.searchIndexes[book.slug]
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
                    let matches: Bool
                    if arabicQuery {
                        let source = index?.arabicByID[hadith.id]
                            ?? Settings.shared.cleanSearch(hadith.arabic, whitespace: true).removingArabicDiacriticsAndSigns
                        matches = source.contains(cleanQuery)
                    } else if let english = index?.englishByID[hadith.id] {
                        matches = english.contains(lowerQuery)
                    } else {
                        matches = hadith.english.text.localizedCaseInsensitiveContains(query)
                            || hadith.english.narrator.localizedCaseInsensitiveContains(query)
                    }
                    if matches {
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
                sources.append(hadith.arabic)
                sources.append(hadith.english.text)
                sources.append(hadith.english.narrator)
            }
            let prewarm = sources
            Task.detached(priority: .utility) {
                HighlightedSnippet.prewarmNormalization(of: prewarm)
            }
        }
    }

    /// Synchronous variant, kept ONLY for user-gesture paths (Ask's context gather, the focus-loss
    /// history check) - never called per keystroke or from body.
    private func matchingHadiths(_ data: HadithBookData) -> (shown: [HadithBookData.Hadith], hasMore: Bool) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3 else { return ([], false) }
        // Script-aware: an Arabic query can only live in the Arabic text, a Latin one only in the
        // English - so each keystroke pays for exactly ONE field. The store's preprocessed index
        // (built when the book was decoded) replaces per-hadith normalization entirely; the raw
        // path only runs in the moment before the index lands.
        let arabicQuery = query.containsArabicScript
        let cleanQuery = arabicQuery ? settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns : ""
        let lowerQuery = HighlightedSnippet.foldedEnglishForSearch(query)
        let index = store.searchIndexes[book.slug]

        var results: [HadithBookData.Hadith] = []
        for hadith in data.hadiths {
            let matches: Bool
            if arabicQuery {
                let source = index?.arabicByID[hadith.id]
                    ?? settings.cleanSearch(hadith.arabic, whitespace: true).removingArabicDiacriticsAndSigns
                matches = source.contains(cleanQuery)
            } else if let english = index?.englishByID[hadith.id] {
                matches = english.contains(lowerQuery)
            } else {
                matches = hadith.english.text.localizedCaseInsensitiveContains(query)
                    || hadith.english.narrator.localizedCaseInsensitiveContains(query)
            }
            if matches {
                results.append(hadith)
                if results.count > hadithMatchLimit {
                    return (Array(results.prefix(hadithMatchLimit)), true)
                }
            }
        }
        return (results, false)
    }

    var body: some View {
        Group {
            if let data {
                loadedBody(data)
            } else if needsDownloadPrompt {
                downloadPrompt
            } else if let loadError {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text(loadError)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        settings.hapticFeedback()
                        self.loadError = nil
                        loadAttempt += 1
                    } label: {
                        Text("Try Again")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                .padding()
            } else {
                Group {
                    if showLoadingSpinner {
                        ProgressView(store.isAvailableOffline(book)
                            ? "Opening \(book.englishTitle)..."
                            : "Downloading \(book.englishTitle) (\(bookSizeText))...")
                    } else {
                        Color.clear
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task {
                    // Only a load that actually takes a moment earns a spinner.
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    showLoadingSpinner = true
                }
            }
        }
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
        .task(id: "\(loadAttempt)|\(didConfirmDownload)|\(temporaryRead)") {
            guard data == nil, !needsDownloadPrompt else { return }
            do {
                data = try await store.book(book, persist: !temporaryRead)
            } catch {
                loadError = error.localizedDescription
            }
        }
    }

    /// The pre-download screen: everything worth knowing about the book (its story, compiler, era, size),
    /// and an explicit Download button behind a confirmation - nothing fetches until the reader says so.
    private var downloadPrompt: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(book.number): \(book.englishTitle)")
                            .font(.headline)

                        Spacer(minLength: 8)

                        HighlightedSnippet(
                            source: book.arabicTitle,
                            term: "",
                            font: settings.useFontArabic
                                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 2)
                                : .headline,
                            accent: settings.accentColor.color,
                            fg: settings.accentColor.color,
                            basicFontForCommas: settings.useFontArabic ? UIFont.preferredFont(forTextStyle: .headline).pointSize + 2 : nil
                        )
                        .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                    }

                    Text("\(book.authorEnglish) (\(book.authorArabic)) - \(book.era)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(book.longDescription)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .conditionalGlassEffect(rectangle: true, useColor: 0.08)

                OnlineNoticeCard(text: "This book is about \(bookSizeText) and has not been downloaded yet. Download it to keep it on this device for offline reading, or read it once without keeping it.")

                Button {
                    settings.hapticFeedback()
                    confirmDownload = true
                } label: {
                    Label("Download \(book.englishTitle) (\(bookSizeText))", systemImage: "icloud.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .conditionalGlassEffect(rectangle: true)
                }
                .buttonStyle(.plain)
                // Anchored to the Download button, so the dialog pops from the control that asked.
                .confirmationDialog("Download \(book.englishTitle)?", isPresented: $confirmDownload, titleVisibility: .visible) {
                    Button("Download (\(bookSizeText))") {
                        settings.hapticFeedback()
                        didConfirmDownload = true
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This fetches the whole book for offline reading. It may use significant data; Wi-Fi is recommended.")
                }

                // The storage-saver: the whole book loads for THIS reading session only and nothing is
                // kept on the device afterward.
                Button {
                    settings.hapticFeedback()
                    temporaryRead = true
                } label: {
                    VStack(spacing: 3) {
                        Label("Read Without Downloading", systemImage: "eye")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)

                        Text("Loads the full book just for now; nothing stays on your device.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .conditionalGlassEffect(clear: true, rectangle: true)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    private var bookSizeText: String {
        book.approximateMegabytes < 1 ? "under 1 MB" : "\(String(format: "%.0f", book.approximateMegabytes)) MB"
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
                                fg: settings.accentColor.color,
                                basicFontForCommas: settings.useFontArabic ? UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2 : nil
                            )
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                        }

                        Text("\(book.authorEnglish) (\(book.authorArabic)) - \(book.era)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // The fuller, authentic orientation to this collection.
                        Text(book.longDescription)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                }

                // This book's own remembered spot - the Quran's Last Read Ayah, per book. Jumps into
                // the chapter scrolled to the hadith, arrival-marked.
                if !isSearchActive, let lastRead = store.lastRead(for: book.slug) {
                    Section(header: Text("LAST READ")) {
                        NavigationLink {
                            if let chapter = data.chapters.first(where: { $0.id == lastRead.chapterId })
                                ?? data.hadiths.first(where: { $0.idInBook == lastRead.idInBook })
                                    .flatMap({ resolved in data.chapters.first { $0.id == resolved.chapterId } }) {
                                HadithChapterView(book: book, bookData: data, chapter: chapter, scrollToHadithId: lastRead.idInBook)
                            } else {
                                HadithReferenceView(book: book, chapter: nil, hadith: lastRead.idInBook)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(lastRead.reference)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(settings.accentColor.color)

                                    Spacer(minLength: 8)

                                    Text(lastRead.timestamp, style: .relative)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                if settings.showHadithArabic, !lastRead.arabicPreview.isEmpty {
                                    HadithArabicPreview(text: lastRead.arabicPreview)
                                }

                                if settings.showHadithEnglish, !lastRead.englishPreview.isEmpty {
                                    Text(lastRead.englishPreview)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // While searching: chapter matches first, then hadith matches - each page-sized with
                // load-more controls, the Quran search's way.
                if isSearchActive {
                    // Question-shaped queries stream a grounded on-device answer automatically; other
                    // queries get a one-tap "Ask AI" row - the Quran search's exact grammar, under the
                    // same accent ASK AI header. The prompt row shows only once there are results to
                    // ground an answer on: while the scan is still running a tap had nothing to
                    // retrieve against and silently did nothing.
                    if OnDeviceAsk.isAvailable {
                        if askNoAnswer {
                            Section(header: askAIHeader) {
                                askNoAnswerRow
                            }
                        } else if !askRanForQuery.isEmpty {
                            Section(header: askAIHeader) {
                                AskAnswerCard(answer: askAnswer, isStreaming: askIsStreaming)
                            }
                        } else if !aiHits.isEmpty || !matches.shown.isEmpty {
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
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

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

                // Free the storage right from the book's own page. Bundle-shipped books occupy no
                // cache storage, so there is nothing to delete for them.
                if store.downloadedSlugs.contains(book.slug) {
                    Section {
                        Button(role: .destructive) {
                            settings.hapticFeedback()
                            confirmDeleteDownload = true
                        } label: {
                            Label("Delete Download (\(bookSizeText))", systemImage: "trash")
                                .font(.subheadline)
                        }
                        // Anchored to the Delete button itself.
                        .confirmationDialog("Delete \(book.englishTitle)?", isPresented: $confirmDeleteDownload, titleVisibility: .visible) {
                            Button("Delete Download", role: .destructive) {
                                settings.hapticFeedback()
                                store.deleteDownload(book)
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Frees about \(bookSizeText). You can download it again anytime.")
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        // No pinned book header here: the navigation title already names the book, and the CHAPTERS
        // header carries the counts - a floating bar was pure repetition on this screen.
        // The grid/list flip animates, same as the catalog.
        .animation(.easeInOut, value: hadithGridMode)
        // The invisible link the chapter grid tiles push through.
        .background(
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
            .opacity(0)
        )
        // And the auto-open link: a hadith opened from the tab root pushes ITS chapter (scrolled to the
        // hadith) on top of this chapters screen - back lands here, never skipping the chapter list.
        .background(
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
            .opacity(0)
        )
        .onAppear {
            // Build (or disk-load) this book's AI index shortly AFTER the book renders - ready by
            // the first search keystroke, but never competing with the open itself. No-ops when built.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                prepareSemanticCorpus(data)
            }

            // Resolve and push the target chapter once, after this screen settles (an immediate
            // isActive flip on arrival is unreliable in the pre-NavigationStack containers).
            guard !didAutoOpen, let targetID = autoOpenHadithID else { return }
            didAutoOpen = true
            guard let hadith = data.hadiths.first(where: { $0.idInBook == targetID }),
                  let chapter = data.chapters.first(where: { $0.id == hadith.chapterId }) else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                autoOpenTarget = chapter
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
        // The folded index landing mid-query (Bukhari's first-open fold takes seconds): re-run so the
        // raw-text fallback's results upgrade to the index's - the state-driven search lost the
        // implicit re-render the old body-computed matches got from observing the store.
        .onReceive(HadithStore.shared.$searchIndexes) { _ in
            guard isSearchActive, !searchText.isEmpty else { return }
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
                .padding([.horizontal, .top], -8)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
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

    /// The CHAPTERS header carrying the book's shape at a glance - the size and the count pills sit at
    /// its trailing edge, in the same pill language the other section headers use.
    private func chaptersSectionHeader(_ data: HadithBookData) -> some View {
        HStack(spacing: 6) {
            Text("CHAPTERS")

            Spacer()

            // Chapters, hadiths, size - the SAME order as the catalog rows' Ch / Ha / MB chips.
            statPill("\(data.chapters.count) Chapters")
            statPill("\(data.hadiths.count.formatted()) Hadiths")
            statPill(bookSizeText)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    /// A small glass stat chip, in the count-pill language.
    private func statPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(settings.accentColor.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
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

            Text("AI couldn't find anything in this book matching \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}. Try different wording.")
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
                    Section(header: SectionPillHeader(title: "AI MATCHES", count: aiHits.count, icon: "sparkles", accentTitle: true)) {
                        ForEach(aiHits) { hadith in
                            NavigationLink {
                                // Land in the chapter, scrolled to the hadith - the keyword matches' arrival.
                                if let chapter = data.chapters.first(where: { $0.id == hadith.chapterId }) {
                                    HadithChapterView(book: book, bookData: data, chapter: chapter, scrollToHadithId: hadith.idInBook)
                                } else {
                                    HadithReferenceView(book: book, chapter: nil, hadith: hadith.idInBook)
                                }
                            } label: {
                                HadithRow(book: book, hadith: hadith, searchText: searchText, compact: true).equatable()
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
                        NavigationLink {
                            HadithChapterView(
                                book: book,
                                bookData: data,
                                chapter: group.chapter,
                                scrollToHadithId: hadith.idInBook
                            )
                        } label: {
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

    /// One chapter row with its full grammar - the NavigationLink, context menu, swipes, and scroll
    /// id - shared by the browsing list and the search results.
    private func chapterRowLink(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> some View {
        NavigationLink {
            HadithChapterView(book: book, bookData: data, chapter: chapter)
        } label: {
            chapterRow(chapter, data: data)
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
                .accessibilityLabel("Chapter \(chapterOrdinal(chapter, data: data))")

            if favorite {
                Image(systemName: "star.fill")
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
                        HighlightedSnippet(
                            source: chapter.arabic,
                            term: searchText,
                            font: settings.useFontArabic
                                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2)
                                : .caption,
                            accent: settings.accentColor.color,
                            fg: .secondary,
                            lineLimit: 1,
                            basicFontForCommas: settings.useFontArabic ? UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2 : nil
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
        return Button {
            settings.hapticFeedback()
            pushedChapter = chapter
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                if !chapter.arabic.isEmpty {
                    HStack(spacing: 4) {
                        HighlightedSnippet(
                            source: chapter.arabic,
                            term: searchText,
                            font: settings.useFontArabic
                                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2)
                                : .subheadline,
                            accent: settings.accentColor.color,
                            fg: settings.accentColor.color,
                            lineLimit: 1,
                            basicFontForCommas: settings.useFontArabic ? UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2 : nil
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
        .conditionalGlassEffect(
            clear: !favorite,
            rectangle: true,
            useColor: favorite ? 0.25 : nil,
            customTint: favorite ? settings.accentColor.color : nil
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
            let hadiths = data.hadiths.filter { $0.chapterId == chapter.id }
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
    @ObservedObject private var settings = Settings.shared
    /// NOT `@ObservedObject`: this view's render tree never reads a published store property (the three
    /// `store.` uses are inside onChange/button handlers). Observing it re-ran the whole reading body -
    /// List, sections, every row - on every launch-prewarm decode tick and download progress publish.
    private var store: HadithStore { HadithStore.shared }

    let book: HadithCatalogBook
    let bookData: HadithBookData
    /// A search result or reference landing here scrolls the list to this hadith, the Quran's way.
    let scrollToHadithId: Int?

    /// Bumped when a search index lands mid-query - a @State change is what re-renders this view now
    /// that it no longer observes the store (the value itself is never read).
    @State private var indexRefreshToken = 0

    // The current chapter and its derived reading data. Held in @State so Previous/Next swaps the chapter
    // IN PLACE (the surah reader's way) rather than pushing a new view. Each is computed once - at init and
    // again only on a chapter swap - so the progress bar never pays an O(hadiths) walk per scroll tick.
    @State private var chapter: HadithBookData.Chapter
    @State private var chapterIndex: Int
    @State private var allChapterHadiths: [HadithBookData.Hadith]
    @State private var chapterRange: ClosedRange<Int>?

    init(book: HadithCatalogBook, bookData: HadithBookData, chapter: HadithBookData.Chapter, scrollToHadithId: Int? = nil) {
        self.book = book
        self.bookData = bookData
        self.scrollToHadithId = scrollToHadithId
        _chapter = State(initialValue: chapter)
        _chapterIndex = State(initialValue: bookData.chapters.firstIndex(where: { $0.id == chapter.id }) ?? 0)
        let hadiths = bookData.hadiths.filter { $0.chapterId == chapter.id }
        _allChapterHadiths = State(initialValue: hadiths)
        if let low = hadiths.map(\.idInBook).min(), let high = hadiths.map(\.idInBook).max() {
            _chapterRange = State(initialValue: low...high)
        } else {
            _chapterRange = State(initialValue: nil)
        }
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
        let hadiths = bookData.hadiths.filter { $0.chapterId == target.id }
        withAnimation(.easeInOut) {
            chapter = target
            chapterIndex = bookData.chapters.firstIndex(where: { $0.id == target.id }) ?? 0
            allChapterHadiths = hadiths
            if let low = hadiths.map(\.idInBook).min(), let high = hadiths.map(\.idInBook).max() {
                chapterRange = low...high
            } else {
                chapterRange = nil
            }
            searchText = ""
            visibility.visibleIDs = []
            highlightedHadithID = nil
        }
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
    /// The chapter's reading mode, the Quran mushaf's default: pages unless the reader turns it off
    /// (via the title menu or Hadith Settings).
    @AppStorage("hadithPageMode") private var hadithPageMode = true
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
        // Script-aware, same as the book search: one field per query, served from the store's
        // preprocessed index whenever it's ready.
        let arabicQuery = query.containsArabicScript
        let cleanQuery = arabicQuery ? settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns : ""
        // The highlighter's fold, matching the index build - the THIRD consumer of englishByID; plain
        // `lowercased()` here stopped matching "Allah's"/"A'ishah" the moment the folded index landed.
        let lowerQuery = HighlightedSnippet.foldedEnglishForSearch(query)
        let index = HadithStore.shared.searchIndexes[book.slug]

        return allChapterHadiths.filter { hadith in
            if arabicQuery {
                let source = index?.arabicByID[hadith.id]
                    ?? settings.cleanSearch(hadith.arabic, whitespace: true).removingArabicDiacriticsAndSigns
                return source.contains(cleanQuery)
            }
            if let english = index?.englishByID[hadith.id] {
                return english.contains(lowerQuery)
            }
            return hadith.english.text.localizedCaseInsensitiveContains(query)
                || hadith.english.narrator.localizedCaseInsensitiveContains(query)
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
        // Dropping the whole-store observation (correct - the render tree reads no published state)
        // also dropped the ONE publish this screen did care about: the search index landing mid-query.
        // Without this nudge, in-chapter results computed on the raw-text fallback didn't refresh
        // against the arrived index until the next keystroke.
        .onReceive(HadithStore.shared.$searchIndexes) { _ in
            guard !searchText.isEmpty else { return }
            indexRefreshToken &+= 1
        }
    }

    /// Rebuild the derived chapter state when the INDEX moved without `navigateToChapter` (the paged
    /// footer's chevrons). No-op when already in sync.
    private func syncChapterFromIndex(_ index: Int) {
        guard bookData.chapters.indices.contains(index),
              bookData.chapters[index].id != chapter.id else { return }
        let target = bookData.chapters[index]
        let hadiths = bookData.hadiths.filter { $0.chapterId == target.id }
        chapter = target
        allChapterHadiths = hadiths
        if let low = hadiths.map(\.idInBook).min(), let high = hadiths.map(\.idInBook).max() {
            chapterRange = low...high
        } else {
            chapterRange = nil
        }
        highlightedHadithID = nil
        isSelectingHadiths = false
        selectedHadithIDs = []
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
    private var chapterTitleLabel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(book.englishTitle)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HighlightedSnippet(
                    source: book.arabicTitle,
                    term: "",
                    font: settings.useFontArabic
                        ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2)
                        : .subheadline,
                    accent: settings.accentColor.color,
                    fg: settings.accentColor.color,
                    lineLimit: 1,
                    basicFontForCommas: settings.useFontArabic ? UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2 : nil
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .minimumScaleFactor(0.5)
            }

            Text("Chapter \(chapterIndex + 1) of \(bookData.chapters.count)")
                .font(.caption2)
                .lineLimit(1)
                .padding(.top, -2)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.primary)
        .contentShape(Rectangle())
        .padding(.horizontal)
        .padding(.vertical, 4)
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
                    let matches = chapterMatches()
                    Section(header: SectionPillHeader(title: "MATCHING HADITHS", count: matches.count)) {
                        if matches.isEmpty {
                            Text("No hadiths found.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, matches.isEmpty ? 0 : -12)

                    ForEach(matches) { hadith in
                        Section {
                            HadithRow(book: book, hadith: hadith, searchText: searchText).equatable()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    let target = hadith.idInBook
                                    highlightedHadithID = target
                                    withAnimation { searchText = "" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation { scrollProxy.scrollTo("chapter-hadith-\(target)", anchor: .top) }
                                    }
                                }
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
                            HadithRow(book: book, hadith: hadith, searchText: searchText).equatable()
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
                    .padding(.bottom, 8)
                    .background(Color.white.opacity(0.00001))
            } else {
                SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut))
                    .padding([.horizontal, .top], -8)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
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
                Text((chapter.english.isEmpty ? book.englishTitle : chapter.english).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

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
                        lineLimit: 1,
                        basicFontForCommas: settings.useFontArabic ? UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2 : nil
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

    /// Hadith counts per chapter, computed once per sheet open (a single grouped pass).
    private var countsByChapter: [Int: Int] {
        bookData.hadiths.reduce(into: [:]) { $0[$1.chapterId, default: 0] += 1 }
    }

    private var filteredChapters: [(offset: Int, element: HadithBookData.Chapter)] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = Array(bookData.chapters.enumerated())
        guard !query.isEmpty else { return all }
        if query.containsArabicScript {
            let clean = settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns
            return all.filter {
                settings.cleanSearch($0.element.arabic, whitespace: true).removingArabicDiacriticsAndSigns.contains(clean)
            }
        }
        return all.filter {
            $0.element.english.localizedCaseInsensitiveContains(query) || String($0.offset + 1) == query
        }
    }

    var body: some View {
        NavigationView {
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
                                        lineLimit: 1,
                                        basicFontForCommas: settings.useFontArabic ? UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2 : nil
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
                }
            }
            .applyConditionalListStyle()
            .compactListSectionSpacing()
            .navigationTitle("Choose Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search chapters")
            .dismissKeyboardOnScroll()
            .sheetDismissToolbar()
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

        var id: String {
            switch self {
            case .hadithHeader(let hadith): return "hdr-\(hadith.id)"
            case .arabic(let hadith): return "ar-\(hadith.id)"
            case .narrator(let hadith): return "narr-\(hadith.id)"
            case .english(let hadith): return "en-\(hadith.id)"
            }
        }

        var hadith: HadithBookData.Hadith? {
            switch self {
            case .hadithHeader(let hadith), .arabic(let hadith),
                 .narrator(let hadith), .english(let hadith):
                return hadith
            }
        }
    }

    private var chapter: HadithBookData.Chapter? {
        bookData.chapters.indices.contains(chapterIndex) ? bookData.chapters[chapterIndex] : nil
    }

    /// Chapter hadiths, memoized: this used to filter ALL of the book's hadiths on every access - and
    /// it is read on every body evaluation (each swipe). Bukhari walked 7,500 hadiths per page turn.
    /// The book data is immutable, so memoize per (book, chapter).
    @MainActor private static var chapterHadithsCache: [String: [HadithBookData.Hadith]] = [:]

    private var chapterHadiths: [HadithBookData.Hadith] {
        guard let chapter else { return [] }
        let key = "\(book.slug)-\(chapter.id)"
        if let cached = Self.chapterHadithsCache[key] { return cached }
        let hadiths = bookData.hadiths.filter { $0.chapterId == chapter.id }
        if Self.chapterHadithsCache.count > 48 { Self.chapterHadithsCache.removeAll(keepingCapacity: true) }
        Self.chapterHadithsCache[key] = hadiths
        return hadiths
    }

    /// Drops every derived static cache (built pages, chapter hadith lists, ordinals). These retain
    /// whole chapters of text, so the store's memory-pressure trim and book deletion both call this -
    /// otherwise the trim's savings were partially pinned here, and a re-downloaded book with changed
    /// content could serve stale pages for chapters cached earlier in the session.
    static func clearDerivedCaches() {
        builtPagesCache.removeAll(keepingCapacity: false)
        chapterHadithsCache.removeAll(keepingCapacity: false)
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
            var elements: [PageElement] = [.hadithHeader(hadith)]
            if settings.showHadithArabic, !hadith.arabic.isEmpty {
                elements.append(.arabic(hadith))
            }
            if settings.showHadithEnglish {
                if !hadith.english.narrator.isEmpty { elements.append(.narrator(hadith)) }
                if !hadith.english.text.isEmpty { elements.append(.english(hadith)) }
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
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    if let chapterNumber = chapterHadithNumber(hadith) {
                        Text("\(chapterNumber)")
                            .font(.subheadline.monospacedDigit().weight(.semibold))

                        Text("-")
                            .font(.caption.weight(.semibold))
                            .opacity(0.55)
                    }

                    Text("\(hadith.idInBook)")
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
                    useColor: HadithStore.shared.isBookmarked(slug: book.slug, idInBook: hadith.idInBook) ? 0.3 : nil,
                    customTint: HadithStore.shared.isBookmarked(slug: book.slug, idInBook: hadith.idInBook) ? settings.accentColor.color : nil,
                    interactive: false
                )

                Spacer(minLength: 0)
            }
            .contextMenu {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { HadithStore.shared.toggleBookmark(book: book, hadith: hadith) }
                } label: {
                    Label(HadithStore.shared.isBookmarked(slug: book.slug, idInBook: hadith.idInBook) ? "Remove Bookmark" : "Bookmark Hadith",
                          systemImage: HadithStore.shared.isBookmarked(slug: book.slug, idInBook: hadith.idInBook) ? "bookmark.fill" : "bookmark")
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

        case .arabic(let hadith):
            HighlightedSnippet(
                source: hadith.arabic,
                term: "",
                font: settings.useFontArabic
                    ? Font.arabic(settings.nonQuranArabicFontName, size: settings.hadithArabicFontSize)
                    : .system(size: settings.hadithArabicFontSize),
                accent: settings.accentColor.color,
                fg: .primary,
                highlightAllahNames: settings.highlightAllahNamesHadith,
                basicFontForCommas: settings.useFontArabic ? settings.hadithArabicFontSize : nil
            )
            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
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
                                Text("Hadith \(i + 1)  (#\(chapterHadiths[i].idInBook))").tag(i)
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
