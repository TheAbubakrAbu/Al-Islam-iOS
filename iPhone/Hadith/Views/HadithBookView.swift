import SwiftUI

// One collection: the chapter list and one chapter, read as a scrolling list. (A right-to-left
// paged reader used to be offered here as well; it was removed - hadith are read as a list.)

#if os(iOS)

fileprivate extension HadithBookData.Hadith {
    /// The BASE of the number a reader would cite for this hadith: the citation with its variant
    /// letter dropped ("8a" -> 8), or `idInBook` for the rows that carry no citation - what the
    /// chapter range labels ("Hadiths 100-200") are built from.
    var citedBaseNumber: Int {
        citation.flatMap { Int($0.prefix(while: { $0.isASCII && $0.isNumber })) } ?? idInBook
    }
}

// MARK: - The book's opening card

/// A collection's opening card, the hero every Islam resource opens on (Abu, 2026-10-03: "make it
/// pretty like pillars and beliefs ... and each Hadith book"): its shelf as the eyebrow, the title with
/// its Arabic, the compiler, the figures (chapters, hadiths, and the date the collection is known by),
/// then its story. The story stays selectable, because it is the one paragraph on the screen a reader
/// would quote, and folds away during a search, where it filled the screen and pushed every result
/// below the fold; the title, compiler and figures stay.
private struct HadithBookHero: View {
    @Environment(\.appearance) private var appearance

    let book: HadithCatalogBook
    let chapters: Int
    let hadiths: Int
    let showsStory: Bool
    @State private var showMore = false

    var body: some View {
        let era = book.eraStat
        // The Arabic interface titles the card by the Arabic name alone (it would otherwise sit beside
        // itself), and names the compiler once, in Arabic.
        ResourceHero(eyebrow: book.group.rawValue.localizedDisplay,
                     systemImage: "books.vertical.fill",
                     headline: book.displayTitle,
                     arabic: AppLanguage.isArabicScript ? nil : book.arabicTitle,
                     message: "") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    AccentIconChip(systemImage: "person.fill", size: 26)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.displayAuthor)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !AppLanguage.isArabicScript {
                            Text(book.authorArabic)
                                .font(appearance.islamArabicFont(base: 17, relativeTo: .subheadline))
                                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                                .foregroundColor(appearance.accent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                    }
                }
                .accessibilityElement(children: .combine)

                ResourceHeroStats([
                    ResourceHeroStat(chapters.formatted(), chapters == 1 ? String(localized: "chapter") : String(localized: "chapters")),
                    ResourceHeroStat(hadiths.formatted(), String(localized: "hadiths")),
                    ResourceHeroStat(era.value, era.label),
                ])
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(chapters) chapters, \(hadiths) hadiths, \(book.eraAccessibilityLabel)")

                if showsStory {
                    Button {
                        Settings.shared.hapticFeedback()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showMore.toggle()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: showMore ? "chevron.up.circle.fill" : "info.circle.fill")
                                .font(.title3)
                            Text(showMore ? "Show Less" : "Show More")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: showMore ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(appearance.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(appearance.accent.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(appearance.accent.opacity(0.22), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(showMore ? "Hides the book's full name and description." :
                                       "Shows the book's full name and description.")

                    if showMore {
                        HadithBookNameBlock(name: book.name)
                        SelectableProse(text: book.longDescription.localizedDigits,
                                        textStyle: .subheadline,
                                        secondary: true)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .articleCardRow()
    }
}

/// What the book's name says: the short title in English, then the full title its compiler gave it,
/// in Arabic, transliterated, and translated. Part of the story, so it folds away with it in a search.
private struct HadithBookNameBlock: View {
    @Environment(\.appearance) private var appearance

    let name: HadithCatalogBook.Name

    var body: some View {
        // The Arabic interface keeps only the full title in Arabic: the meaning, the transliteration
        // and the translation are English, written for a reader who cannot read the Arabic.
        VStack(alignment: .leading, spacing: 10) {
            if !AppLanguage.isArabicScript {
                VStack(alignment: .leading, spacing: 3) {
                    label(String(localized: "THE NAME MEANS"))
                    Text("“\(name.meaning)”")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        // The title's English meaning and its transliteration (below) are English
                        // content: left to right in the Arabic interface too.
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .leftToRightContent()
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                label(String(localized: "FULL TITLE"))
                Text(name.fullArabic)
                    .font(appearance.islamArabicFont(base: 19, relativeTo: .subheadline))
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .foregroundColor(appearance.accent)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    // The right edge in the Arabic interface too (`.trailing` is right only left to right).
                    .environment(\.layoutDirection, .leftToRight)
                if !AppLanguage.isArabicScript {
                    Text(name.fullTransliteration)
                        .font(.subheadline.italic())
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .leftToRightContent()
                    Text("“\(name.fullMeaning)”")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .leftToRightContent()
                }
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .tracking(AppLanguage.letterSpacing(1.1))
            .foregroundColor(.secondary)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - One collection: chapters + book search

struct HadithBookView: View {
    #if DEBUG
    /// Hands a launch argument's value to `apply` once the screen is mounted (typing is not scriptable).
    static func debugSeed(_ flag: String, apply: @escaping (String) -> Void) {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return }
        let value = arguments[index + 1]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { apply(value) }
    }
    #endif

    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    @ObservedObject private var hadithSettings = HadithSettings.shared

    @ObservedObject private var islamSettings = IslamSettings.shared

    @ObservedObject private var quranDisplay = QuranDisplay.shared

    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var store = HadithStore.shared
    /// Chapter favorites render through the store's forwards; the data publishes from HadithUserData,
    /// so this observation is what re-renders the pills/tiles when a favorite toggles.
    @ObservedObject private var userData = HadithUserData.shared

    let book: HadithCatalogBook

    @State private var searchText = ""
    /// The chapter list's OWN grid/list choice, a GRID by default as every screen with the switch is
    /// (Abu, 2026-11-15: "Use grid mode everywhere default"). It was a list until then, because
    /// chapter titles are sentences, which a tile cuts short. Until 2026-10-10 it shared the tab's
    /// `hadithGridMode` key with the opposite default, so flipping the collections flipped the
    /// chapters too (`Settings.migrateGridModes` carried each install's choice over, which is why an
    /// install from before 2026-11-15 has a list stored here and keeps it).
    @AppStorage("hadithChapterGridMode") private var chapterGridMode = true
    /// Scroll To Chapter from the grid shows the list for that one visit, the stored choice untouched.
    @State private var listForJump = false
    private var showsGrid: Bool { chapterGridMode && !listForJump }
    /// The push target the chapter grid tiles use when no tab path is handed in (a NavigationLink cell
    /// would draw a chevron). See the `pushDestination` pair in `body`.
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
    /// The tab root's button row (HadithSearchFilters.swift) minus the collection buttons: gradings,
    /// word mode, order, sections. The session filters are this screen's own and never reset by
    /// themselves; the order and the Show choices are the one remembered preference.
    @State private var searchFilters = HadithSearchFilters.restored(scope: .oneBook)
    @State private var showSearchFilterSheet = false
    /// The ranked lane for this book (`HadithRankedSearch.rankedRows`): the hadith list under Best
    /// Match, and what answers instead of an empty list when the exact scan finds nothing (a
    /// misspelling, another word ending, words that do not touch), whatever the order.
    @State private var inBookRanked = HadithRankedSearch.ScopedOutcome()
    @State private var rankedMatchLimit = 5
    private static let rankedHadithCap = 40
    /// How many ranked rows the engine keeps: the forty-row cap until Search All Matches lifts it to
    /// the whole book (`rankedRows` clamps it to the book's row count).
    @State private var rankedHadithLimit = HadithBookView.rankedHadithCap

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
    /// True while this screen owns the all-books gather (the corpus's slow path).
    @State private var isGatheringCorpus = false

    /// The ONE all-books corpus, filtered to this book. There is no per-book corpus any more: each
    /// book used to build and persist its own ~10 MB vector file on open (17 of them, ~100 MB in
    /// Caches, three resident at ~43 MB), while the all-books corpus already keys every row by
    /// "slug|idInBook" (Performance Guide, Phase 7 step 3).
    private var semanticCorpusID: String { HadithSemanticCorpus.id }

    /// True when the live query is one the semantic engine can answer (English text, long enough).
    private var aiQueryEligible: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return SemanticSearchEngine.isSupported
            && trimmed.count >= 3
            && !trimmed.containsArabicScript
            // "1234" (or "8a", or "1:4") is a hadith citation, not a question - it gets an exact
            // lookup, so there is nothing for the semantic engine (or the Ask row) to be asked about.
            && !HadithBookData.isNumberQuery(localQuery)
    }

    /// The query with this book's own name dropped: "bukhari 1:4" typed inside Sahih al-Bukhari is the
    /// bare "1:4". Every NUMBER reading below goes through this; the keyword scan keeps the raw text.
    private var localQuery: String {
        HadithReferenceParser.localQuery(searchText, in: book)
    }

    /// Load-or-build the all-books corpus, on the first AI-eligible query - never on open.
    private func prepareSemanticCorpus() {
        guard SemanticSearchEngine.isSupported,
              !semanticEngine.isReady(semanticCorpusID),
              !semanticEngine.isBuilding(semanticCorpusID),
              !isGatheringCorpus,
              !HadithSemanticCorpus.isGathering else { return }
        isGatheringCorpus = true
        Task {
            await HadithSemanticCorpus.prepare(engine: semanticEngine, store: store)
            isGatheringCorpus = false
            if semanticEngine.isReady(semanticCorpusID) { runAISearch(query: searchText, data: data) }
        }
    }

    // Ask AI: the on-device chat (`AskAIChatView`), opened from the ASK AI row above the matches
    // with the typed query as its first question - the Quran search's rule. Exists only on Apple
    // Intelligence devices (`OnDeviceAsk.isAvailable`).
    @State private var showAskAI = false
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist (the Quran search's
    /// `showKeywordResults`). Reset on every new query to the list the reader's preference opens on.
    @State private var showBookKeywordResults = HadithView.opensOnKeywordResults

    private func runAISearch(query: String, data: HadithBookData?) {
        aiSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filters = searchFilters
        guard SemanticSearchEngine.isSupported, let data, filters.shows(.ai, in: .oneBook),
              trimmed.count >= 3, !trimmed.containsArabicScript,
              // A number reading shows no AI section, so stale hits must not raise the AI/keyword switch.
              !HadithBookData.isNumberQuery(HadithReferenceParser.localQuery(trimmed, in: book)) else {
            if !aiHits.isEmpty { aiHits = [] }
            return
        }
        prepareSemanticCorpus()
        let corpusID = semanticCorpusID
        let slugPrefix = "\(book.slug)|"
        let accept = filters.gradeTest(for: book, data: data)

        aiSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            // Over-fetch from the whole shelf and keep this book's rows - filtering after ranking
            // is what replaced the per-book corpus.
            let results = await semanticEngine.search(corpusID: corpusID, query: trimmed, limit: 60)
            guard !Task.isCancelled else { return }
            let keys = await MainActor.run { semanticEngine.corpus(corpusID)?.itemKeys }
            let candidates = results.compactMap { result -> HadithBookData.Hadith? in
                guard let keys, keys.indices.contains(result.index) else { return nil }
                let key = keys[result.index]
                guard key.hasPrefix(slugPrefix), let idInBook = Int(key.dropFirst(slugPrefix.count)) else { return nil }
                return data.hadith(numbered: idInBook)
            }
            // A grading reads the rows' text blocks, so it is tested off the main thread.
            var kept: Set<Int>? = nil
            if let accept {
                let rows = candidates.map(\.row)
                kept = await Task.detached(priority: .userInitiated) { Set(rows.filter { $0 >= 0 && accept($0) }) }.value
                guard !Task.isCancelled else { return }
            }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines), filters == searchFilters else { return }
                // Plain apply: an animated section insert racing the keyword scan's own apply is the
                // collection-view assertion crash the Quran search hit.
                aiHits = candidates.filter { kept?.contains($0.row) ?? true }.prefix(10).map { $0 }
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
    /// publish was debounced or where the link was anchored. Nil in column mode (chapters swap the detail
    /// column instead of pushing) and when the book is opened outside the Hadith tab (the screen then
    /// pushes by itself, see the `pushDestination` pair in `body`).
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
    /// pass over ~97 chapters instead of the 7,277-hadith walk it used to be (which itself replaced a
    /// walk per row, per render).
    struct ChapterStats {
        let counts: [Int: Int]
        let ranges: [Int: ClosedRange<Int>]
        let ordinals: [Int: Int]

        init(_ data: HadithBookData) {
            var counts: [Int: Int] = [:]
            var ranges: [Int: ClosedRange<Int>] = [:]
            var ordinals: [Int: Int] = [:]
            for chapter in data.chapters {
                counts[chapter.id] = chapter.rowCount
                ordinals[chapter.id] = data.position(of: chapter)
                // Citation BASE numbers - the numbers readers actually cite - with idInBook standing
                // in per row where no citation exists (so books without citations behave exactly as
                // before). Min/max over the WHOLE slice, never first/last: Sahih Muslim's citations
                // are not monotonic within a chapter.
                // In a book that cites some rows, only the cited ones count: an uncited row is named
                // "C:N" there (H4), and its row number is no citation.
                let citing = data.pack.citesAnyRow
                let rows = data.hadiths(in: chapter).filter { !citing || $0.citation != nil }
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

    /// Drops the per-book chapter statistics; the store's memory-pressure trim calls this (they are
    /// one pass over the chapter table to rebuild).
    static func clearDerivedCaches() {
        statsCache.removeAll(keepingCapacity: false)
    }

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
        // (Skipped when the filter row hides chapter matches; a number below still answers.)
        let folded = HadithFold.query(query)
        let byText = searchFilters.shows(.chapters, in: .oneBook) ? data.chapters.filter { data.matches($0, folded) } : []
        // A number names a chapter by its position too: "15" lists chapter 15 above the hadith cited
        // 15, and "1:4" lists chapter 1 above its fourth hadith (Abu, 2026-09-21).
        let local = localQuery
        let position = HadithBookData.chapterHadith(inQuery: local)?.chapter
            ?? HadithBookData.citationNumber(inQuery: local).flatMap { $0.suffix == nil ? $0.base : nil }
        guard let position, let numbered = data.chapter(atPosition: position) else { return byText }
        return [numbered] + byText.filter { $0.id != numbered.id }
    }

    /// Book-wide hadith search (English text/narrator + diacritic-insensitive Arabic), the Quran
    /// search's way: scan only until one PAST the shown page, so finding page one of a common word
    /// in Bukhari never walks all 7,277 hadiths. `hasMore` renders the count pill as "5+".
    /// The debounced, off-main scan feeding `inBookMatches` - the body reads state, never scans.
    private func runInBookSearch(_ data: HadithBookData) {
        inBookSearchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        // A pure citation ("5", or "8a" with the variant letter) is a hadith NUMBER: the hadith
        // CITED 5 in this book, all its variants when the base owns several, falling back to the
        // internal row number where no citations exist. Answered directly - no scan, and deliberately
        // BEFORE the three-character floor below, which is why typing a one- or two-digit number
        // used to show nothing at all.
        // The filter row never reaches this: a number answers whatever is chosen there.
        if let matches = numberMatches(in: data) {
            inBookMatches = (matches, false)
            if !inBookRanked.isEmpty { inBookRanked = HadithRankedSearch.ScopedOutcome() }
            return
        }

        let filters = searchFilters
        guard query.count >= 3, filters.shows(.hadiths, in: .oneBook) else {
            if !inBookMatches.shown.isEmpty || inBookMatches.hasMore { inBookMatches = ([], false) }
            if !inBookRanked.isEmpty { inBookRanked = HadithRankedSearch.ScopedOutcome() }
            return
        }
        let folded = HadithFold.query(query)
        // "Load all" sets Int.max; clamped so the one-past-the-page `limit + 1` below cannot overflow.
        let limit = min(hadithMatchLimit, Int.max - 1)
        // The filters in force for THIS scan: the words become needles with the Match rule's word
        // edges, and the grading (plus Exact's letters) a row test run on text matches only. With none
        // of them (the row untouched, or only its order changed) the scan is the one-needle sweep it
        // has always been, so the pages come out the same. The ranked lane re-tests its hits under a
        // rule (`rankedRowTest`): it ranks stems and corrected spellings, which a rule must not pass.
        let needles = filters.needles(for: query)
        let accept = filters.rowTest(for: book, data: data, query: query)
        let rankedAccept = filters.rankedRowTest(for: book, data: data, query: query)
        let isPlainScan = accept == nil && needles.queries.count == 1 && needles.rule == .contains
        let wantsRanked = filters.sort == .relevance
        let book = book
        let rankedCap = rankedHadithLimit

        inBookSearchTask = Task {
            // Debounce so typing pays once per settled query; the scan itself runs detached, with
            // cancellation bridged in (detached tasks don't inherit it). One search-block fetch per
            // block, and the shown rows' TEXT blocks are inflated in the same detached pass, so the
            // result rows never decode on the main thread.
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            let scan = Task.detached(priority: .userInitiated) { () -> (shown: [HadithBookData.Hadith], hasMore: Bool, ranked: HadithRankedSearch.ScopedOutcome) in
                let rows = isPlainScan
                    ? data.matchingRows(in: 0..<data.hadiths.count, query: folded, limit: limit + 1)
                    : data.matchingRows(in: 0..<data.hadiths.count, queries: needles.queries,
                                        requireAll: needles.requireAll, limit: limit + 1,
                                        rule: needles.rule, accept: accept)
                if Task.isCancelled { return ([], false, HadithRankedSearch.ScopedOutcome()) }
                let shown = rows.prefix(limit).map { data.hadiths[$0] }
                for hadith in shown {
                    if Task.isCancelled { break }
                    data.prewarmText(rows: hadith.row..<(hadith.row + 1))
                    let strings = hadith.allText
                    HighlightedSnippet.prewarmNormalization(of: [strings.arabic, strings.text, strings.narrator])
                    HadithRow.prewarmCrossLanguageSpans(query: query, text: strings)
                }
                // The ranked lane: asked for (Best Match), or the exact scan came back empty and a
                // forgiving answer beats a blank screen. Never on a plain search that found something.
                var ranked = HadithRankedSearch.ScopedOutcome()
                if wantsRanked || rows.isEmpty {
                    ranked = HadithRankedSearch.rankedRows(query: query, book: book, data: data,
                                                           cap: rankedCap, accept: rankedAccept) ?? ranked
                    for row in ranked.rows.prefix(12) where data.hadiths.indices.contains(row) {
                        if Task.isCancelled { break }
                        data.prewarmText(rows: row..<(row + 1))
                        let strings = data.hadiths[row].allText
                        HighlightedSnippet.prewarmNormalization(of: [strings.arabic, strings.text, strings.narrator])
                        HadithRow.prewarmCrossLanguageSpans(query: ranked.highlight, text: strings)
                    }
                }
                return (shown, rows.count > limit, ranked)
            }
            let result = await withTaskCancellationHandler {
                await scan.value
            } onCancel: {
                scan.cancel()
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines), filters == searchFilters else { return }
                // Plain apply - see the aiHits apply note (collection-view assertion).
                inBookMatches = (result.shown, result.hasMore)
                inBookRanked = result.ranked
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
        } else if cited.isEmpty, let fallback = data.hadith(uncitedRow: citation.base) {
            cited = [fallback]
        }
        return cited
    }

    /// Both number readings of the live query, nil when it is words: "1:4" is the fourth hadith of
    /// chapter 1 (empty when the book has no such hadith), "15" / "8a" the citation lookup above.
    private func numberMatches(in data: HadithBookData) -> [HadithBookData.Hadith]? {
        let local = localQuery
        if let reference = HadithBookData.chapterHadith(inQuery: local) {
            return data.hadith(chapterPosition: reference.chapter, position: reference.hadith).map { [$0] } ?? []
        }
        if let citation = HadithBookData.citationNumber(inQuery: local) {
            return Self.citedMatches(citation, in: data)
        }
        return nil
    }

    /// Synchronous variant, kept ONLY for user-gesture paths (Ask's context gather, the focus-loss
    /// history check) - never called per keystroke or from body.
    private func matchingHadiths(_ data: HadithBookData) -> (shown: [HadithBookData.Hadith], hasMore: Bool) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let matches = numberMatches(in: data) { return (matches, false) }
        guard query.count >= 3 else { return ([], false) }
        // Script-aware: an Arabic query can only live in the Arabic text, a Latin one only in the
        // English - so each query pays for exactly ONE field, matched against the fold the pack
        // already carries.
        let folded = HadithFold.query(query)
        let limit = min(hadithMatchLimit, Int.max - 1)
        let rows = data.matchingRows(in: 0..<data.hadiths.count, query: folded, limit: limit + 1)
        return (rows.prefix(limit).map { data.hadiths[$0] }, rows.count > limit)
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

                    Text("\(book.displayTitle) could not be opened.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        // The chapter pushes this screen makes by itself, when no tab path is handed in
        // (`onPushChapter` nil outside column mode): a book opened from somewhere other than the Hadith
        // tab's own stack, such as the Daily Hub's "Read the hadith". A grid tile sets `pushedChapter`;
        // the auto-open sets `autoOpenTarget` (the hadith's chapter, scrolled to it). Until 2026-10-09
        // these rode on iOS 15 hidden `isActive` links that did not exist on iOS 16, so from the Daily
        // Hub a grid tile did nothing and "Read the hadith" stopped at the chapter list. On the outer
        // container, not the chapters List: the List re-diffs whenever the pushed chapter records Last
        // Read through the store this screen observes. In the Hadith tab both stay nil.
        .pushDestination(isPresented: Binding(
            get: { pushedChapter != nil },
            set: { if !$0 { pushedChapter = nil } }
        )) {
            if let pushedChapter, let data {
                HadithChapterView(book: book, bookData: data, chapter: pushedChapter)
            }
        }
        .pushDestination(isPresented: Binding(
            get: { autoOpenTarget != nil },
            set: { if !$0 { autoOpenTarget = nil } }
        )) {
            if let autoOpenTarget, let autoOpenHadithID, let data {
                HadithChapterView(book: book, bookData: data, chapter: autoOpenTarget, scrollToHadithId: autoOpenHadithID)
            }
        }
        .navigationTitle(book.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        // The chapter grid toggle and the gear, top right. (The tab root moved its grid switch into
        // its leading ⋯ More menu on 2026-10-11; a pushed screen's leading slot is Back, so this one
        // keeps the button.) Fullscreen and sharing live in the rows' context menus, not up here.
        .modifier(HadithTrailingToolbar(
            hadithGridMode: $chapterGridMode,
            showHadithSettings: $showHadithSettings,
            listForJump: $listForJump
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
        .sheet(isPresented: $showSearchFilterSheet) {
            HadithSearchFilterSheet(filters: $searchFilters, scope: .oneBook)
                .smallMediumSheetPresentation()
        }
    }

    /// Decode, while the reader is choosing a chapter, the text each chapter opens on: this book's
    /// last read first (its own row leads the list), then the chapters in order, within what the
    /// text cache spares (`prewarmLandingText`: every chapter of every book on a 4 GB phone, the
    /// first two blocks on a weak or power-saving one). Off the main thread, about 3 ms a block,
    /// and nothing at all when resident already (every return from a chapter runs this again). A
    /// chapter it did not reach decodes its own landing as it opens.
    private func prewarmChapterLandings(_ data: HadithBookData) {
        var landings: [Range<Int>] = []
        if let lastRead = store.lastRead(for: book.slug),
           let hadith = data.hadiths.first(where: { $0.idInBook == lastRead.idInBook }),
           let chapter = data.chapter(of: hadith) {
            landings.append(data.landingRows(of: chapter, at: hadith))
        }
        landings += data.chapters.map { data.landingRows(of: $0) }
        Task.detached(priority: .utility) { data.prewarmLandingText(landings) }
    }

    private func loadedBody(_ data: HadithBookData) -> some View {
        // Matches come from STATE, filled by `runInBookSearch`'s debounced, off-main scan. Computing
        // them here walked up to the whole book (Bukhari's 7,277 hadiths of `.contains`) synchronously
        // on the main thread on every keystroke - the one search path that never got the global
        // sweep's detached treatment.
        let matches = isSearchActive
            ? inBookMatches
            : (shown: [HadithBookData.Hadith](), hasMore: false)
        let shownChapters = filteredChapters
        #if os(iOS)
        // The chapter numbers down the edge, in the list and the grid alike; not while searching.
        let railItems = isSearchActive ? [] : Self.chapterRailItems(shownChapters, data: data, book: book)
        #endif

        return ScrollViewReader { scrollProxy in
        List {
            Group {
                Section {
                    HadithBookHero(book: book,
                                   chapters: data.chapters.count,
                                   hadiths: data.hadiths.count,
                                   showsStory: !isSearchActive)
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
                                LazyDestination {
                                    // byRowNumber: a stale record's key is a row number, not a citation -
                                    // citation-first reading would open a different hadith in drifted books.
                                    HadithReferenceView(book: book, chapter: nil, hadith: lastRead.idInBook, byRowNumber: true)
                                }
                            } label: {
                                lastReadRow(lastRead)
                            }
                        }
                    }
                }

                // While searching: chapter matches first, then hadith matches - each page-sized with
                // load-more controls, the Quran search's way.
                if isSearchActive {
                    // The Ask AI row - ALWAYS present while searching, results or none - under the
                    // same accent ASK AI header as the Quran search: it opens the chat with this query
                    // as its first question.
                    // (Not for a number reading: "1:4" is a lookup, there is no question in it.)
                    if OnDeviceAsk.isAvailable, !HadithBookData.isNumberQuery(localQuery),
                       searchFilters.shows(.ai, in: .oneBook) {
                        Section(header: askAIHeader) {
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
                    }

                    // Matching chapters sit ABOVE the AI/keyword switch (the Quran search's surah-list
                    // rule): navigation, not a competing result kind, so they show in both modes.
                    if !shownChapters.isEmpty {
                        Section(header: SectionPillHeader(title: String(localized: "MATCHING CHAPTERS"), count: shownChapters.count)) {
                            ForEach(shownChapters.prefix(chapterMatchLimit)) { chapter in
                                chapterRowLink(chapter, data: data)
                            }

                            HadithLoadMoreControls(label: String(localized: "chapter matches"), hasMore: shownChapters.count > chapterMatchLimit, limit: $chapterMatchLimit)
                        }
                    }

                    // Both HADITH result kinds landed: ONE segmented switch decides which list fills
                    // the page (the Quran search's rule). With only one kind present, no picker.
                    // The ranked list stands in for the exact one under Best Match, and whenever the
                    // exact scan found nothing (see `inBookRanked`).
                    let showsRanked = !inBookRanked.isEmpty && (searchFilters.sort == .relevance || matches.shown.isEmpty)
                    let showResultsPicker = !aiHits.isEmpty && (!matches.shown.isEmpty || showsRanked)
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

                    // Hadith matches, the Quran ayah-search way: compact rows grouped per chapter,
                    // each group with its own count pill; tapping one opens the chapter scrolled to it.
                    if keywordVisible {
                        if showsRanked {
                            rankedMatchesSection(data)
                        } else {
                            hadithMatchesSections(data, matches: matches)
                        }
                    }

                    if shownChapters.isEmpty && matches.shown.isEmpty && !showsRanked {
                        Section {
                            Text(aiHits.isEmpty
                                 ? (searchFilters.hasSessionFilters ? "No matches with these filters." : "No matches found.")
                                 : "No keyword matches. See the AI results above.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } footer: {
                            if searchFilters.hasSessionFilters, aiHits.isEmpty {
                                Text("The filters above narrow this search. Reset them to search the whole book.")
                            }
                        }
                    }
                } else {
                    // The Quran surah list's shape: the header stands alone, then each chapter is its own
                    // Section - separate glass cards with compact spacing between them.
                    Section(header: chaptersSectionHeader(data)) { }
                        .padding(.bottom, -12)

                    if showsGrid {
                        Section {
                            // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a
                            // different height on each self-sizing pass, which iOS 26 traps on. One
                            // grid row per List row (`tileGridChunk`), each with an id the chapter
                            // rail lands on; it was every chapter in one row (Bukhari's 97 tiles).
                            let chunk = tileGridChunk(columns: Self.chapterGridColumns)
                            ForEach(Array(stride(from: 0, to: shownChapters.count, by: chunk)), id: \.self) { start in
                                SummaryTileGrid(columns: Self.chapterGridColumns) {
                                    ForEach(shownChapters[start..<min(start + chunk, shownChapters.count)]) { chapter in
                                        chapterGridTile(chapter, data: data)
                                    }
                                }
                                .tileGridChunkRow(start: start, count: shownChapters.count, chunk: chunk)
                                .id(Self.chapterGridRowID(start))
                            }
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
        #if os(iOS)
        .jumpIndexRailRoom(railItems)
        #endif
        // Column mode: this is the CONTENT column and the reading column beside it shows the Now
        // Playing bar - suppress the duplicate here (same rule as the catalog and the Quran sidebar).
        .applyConditionalListStyle(disableNowPlayingInset: usesColumnNavigation)
        .compactListSectionSpacing()
        #if os(iOS)
        .jumpIndexRail(railItems, accessibilityName: String(localized: "Chapter index"), proxy: scrollProxy) { item -> String? in
            guard shownChapters.indices.contains(item.id) else { return nil }
            let chunk = tileGridChunk(columns: Self.chapterGridColumns)
            return showsGrid
                ? Self.chapterGridRowID(item.id - item.id % chunk)
                : "hadith-chapter-\(shownChapters[item.id].id)"
        }
        #endif
        // No pinned book header here: the navigation title already names the book, and the CHAPTERS
        // header carries the counts - a floating bar was pure repetition on this screen.
        // The grid/list flip animates, same as the catalog.
        .animation(.easeInOut, value: showsGrid)
        // NOTE: the screen's own chapter pushes (grid tile, auto-open) deliberately do NOT live here.
        // The pushed chapter's Last Read record publishes through the store THIS screen observes, which
        // re-diffs the List (for a first read it inserts the whole LAST READ section), and a push hung
        // off something that re-diffs is a push that can be torn down. They sit on the outer container
        // in `body` instead, where the List's content can't reach them.
        .onAppear {
            // Back from the chapter a jump opened: the grid again.
            if listForJump { listForJump = false }
            // (No AI index build on open any more: the all-books corpus loads or builds on the first
            // AI-eligible query, from `runAISearch`.)

            // The order and the Show choices are one preference shared with the tab root and the
            // chapter screen; coming back from either picks up what was chosen there.
            searchFilters.adoptStoredPreferences()
            // This book's chains of narrators (HadithChains.swift), inflated off the main thread while
            // the reader picks a chapter, so its rows' first question is a lookup.
            HadithChainStore.shared.prewarm(slug: book.slug)
            // Likewise this book's similar-narration lists (SimilarHadiths.swift) and its links to the
            // Hadith Encyclopedia's explanations (HadithExplanations.swift).
            SimilarHadithsStore.shared.prewarm(slug: book.slug)
            HadithExplanationStore.shared.prewarm(slug: book.slug)
            // And the text each chapter opens on, so the chapter opens with its rows.
            prewarmChapterLandings(data)

            #if DEBUG
            // `-hadithBookSearch <term>` (with `-launchHadithBook <slug>`): the in-book search, headless.
            Self.debugSeed("-hadithBookSearch") { if searchText.isEmpty { searchText = $0 } }
            #endif

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
                } else if pushedChapter == nil {
                    // Never raise both of the screen's push flags: a tile tapped inside the delay wins.
                    autoOpenTarget = chapter
                }
            }
        }
        .onChange(of: searchText) { text in
            // A new query starts back at the first page of matches, on the AI list.
            chapterMatchLimit = 5
            hadithMatchLimit = 5
            rankedMatchLimit = 5
            rankedHadithLimit = Self.rankedHadithCap
            showBookKeywordResults = HadithView.opensOnKeywordResults
            runInBookSearch(data)
            runAISearch(query: text, data: data)
        }
        // A pressed filter button is a new search: back to page one, both lanes re-run.
        .onChange(of: searchFilters) { filters in
            filters.persistPreferences()
            chapterMatchLimit = 5
            rankedMatchLimit = 5
            rankedHadithLimit = Self.rankedHadithCap
            if hadithMatchLimit != 5 {
                // The limit's own onChange below re-runs the scan.
                hadithMatchLimit = 5
            } else {
                runInBookSearch(data)
            }
            runAISearch(query: searchText, data: data)
        }
        // Load-more bumps the limit; re-run the (debounced, off-main) scan for the bigger page.
        .onChange(of: hadithMatchLimit) { _ in
            runInBookSearch(data)
        }
        // Search All Matches under Best Match lifts the engine's cap; the same scan ranks the whole book.
        .onChange(of: rankedHadithLimit) { _ in
            runInBookSearch(data)
        }
        // The one-time vector build finishing mid-query: surface the results without another keystroke.
        .onChange(of: semanticEngine.readyCorpora) { ready in
            guard ready.contains(semanticCorpusID), !searchText.isEmpty else { return }
            runAISearch(query: searchText, data: data)
        }
        .onChange(of: pendingScrollToChapterId) { chapterId in
            guard let chapterId else { return }
            pendingScrollToChapterId = nil
            // Grid tiles carry no scroll ids (the Quran list has the same rule), so this visit shows
            // the list, the stored choice untouched; and clear the search so the chapter rows exist,
            // then land on the chapter.
            if showsGrid { listForJump = true }
            withAnimation { searchText = "" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { scrollProxy.scrollTo("hadith-chapter-\(chapterId)", anchor: .top) }
            }
        }
        // Apple Music-style: the bottom search bar minimizes while scrolling down. The whole bottom
        // bar is the tab root's exact grammar: just the field. On the List itself, before the help
        // card and the filter row (a horizontal ScrollView) join the tree, for the reason the tab
        // root gives: `onScrollGeometryChange` must see one scroll view.
        .collapseBarsOnScroll($barsCollapsed)
        // Recent searches float over the list top while the field is focused and empty (the tab
        // root's help card, minus the help: a book search needs no syntax guide).
        .overlay(alignment: .top) {
            bookSearchHelpOverlay
                .animation(.easeInOut, value: isBookSearchFocused)
        }
        // The tab root's filter buttons, mounted the same way: above the results while a search is
        // live (the field focused or holding text; a filter alone keeps its setting but not the row),
        // applied after the recent-searches card so the card sits under the row.
        .adaptiveSafeArea(edge: .top, spacing: 0) {
            if isBookSearchFocused || isSearchActive {
                HadithSearchFilterBar(filters: $searchFilters, scope: .oneBook) { showSearchFilterSheet = true }
                    .background {
                        if #unavailable(iOS 26.0) {
                            Rectangle().fill(.bar).ignoresSafeArea(edges: .top)
                        }
                    }
            }
        }
        // The result rows paint by the Match button's rule, not only filter by it.
        .environment(\.searchWordRule, searchFilters.highlightWordRule)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                SearchBar(
                    // Animated with the app-wide gate; the in-book hadith matches already animate at
                    // their debounced apply site, so this covers the chapter-filter diff while typing.
                    text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                    onFocusChanged: { focused in
                        withAnimation { isBookSearchFocused = focused }
                        // Leaving the field with a query that found something joins the shared
                        // recent-searches chips (the tab root's rule).
                        if !focused, isSearchActive,
                           !filteredChapters.isEmpty || !inBookRanked.isEmpty || !matchingHadiths(data).shown.isEmpty {
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

    @ViewBuilder
    private var bookSearchHelpOverlay: some View {
        if isBookSearchFocused,
           searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !settings.hadithSearchHistory.isEmpty {
            HadithRecentSearches(searchText: $searchText)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .conditionalGlassEffect(rectangle: true)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
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
                Text(lastRead.displayReference)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .leftToRightContent()
            }
        }
        .padding(.vertical, 2)
    }

    /// The CHAPTERS header carrying the book's shape at a glance - the count pills sit at its trailing
    /// edge, in the same pill language the other section headers use. No size pill: the book is part of
    /// the app, so how many megabytes it weighs is not something the reader has to think about.
    private func chaptersSectionHeader(_ data: HadithBookData) -> some View {
        SectionHeaderLine(String(localized: "CHAPTERS")) {
            // Chapters, then hadiths - the SAME order as the catalog rows' counts, abbreviated in the
            // split view's narrow content column so neither ellipsizes. Simple Mode drops them.
            if settings.hides(.chapterStats) {
                EmptyView()
            } else if usesColumnNavigation {
                statPill(String(localized: "\(data.chapters.count) Ch"))
                statPill(String(localized: "\(data.hadiths.count) Ha"))
            } else {
                statPill(data.chapters.count == 1 ? String(localized: "\(data.chapters.count) Chapter") : String(localized: "\(data.chapters.count) Chapters"))
                statPill(String(localized: "\(data.hadiths.count) Hadiths"))
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

    /// "ASK AI" with the sparkles glyph in the header gray, as the Quran search's `askAIHeader` draws it, for this book.
    private var askAIHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("ASK AI")

            Spacer()
        }
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
                    Section(header: SectionPillHeader(title: String(localized: "AI MATCHES"), count: aiHits.count, icon: "sparkles")) {
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
                                Text(group.chapter.displayTitle.uppercased())
                                    .lineLimit(1)

                                Spacer()

                                CountPill(count: group.shown.count)
                            }
                        }
                    }
                }
            } else if !semanticEngine.failedCorpora.contains(semanticCorpusID),
                      isGatheringCorpus || HadithSemanticCorpus.isGathering || semanticEngine.isBuilding(semanticCorpusID) {
                Section { AISearchStatusRow(corpusID: semanticCorpusID, failed: false) }
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

    /// What a match row paints: the typed words, or nothing for a number reading ("1:4", "bukhari
    /// 15"), where the number is the row's identity and a forced closest-word span would be noise.
    private var highlightTerm: String {
        HadithBookData.isNumberQuery(localQuery) ? "" : searchText
    }

    @ViewBuilder
    private func hadithMatchesSections(_ data: HadithBookData, matches: (shown: [HadithBookData.Hadith], hasMore: Bool)) -> some View {
        if !matches.shown.isEmpty {
            let groups = hadithMatchGroups(data, shown: matches.shown)
            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                Section(header: matchGroupHeader(group, isFirst: index == 0, matches: matches)) {
                    if index == 0 {
                        // The Search All card at the head of the list; the Load More card under it
                        // stays. The scan stops one past its page, so the total is unknown until then.
                        if matches.hasMore {
                            HadithSearchAllRow(shown: matches.shown.count, isLoading: hadithMatchLimit == Int.max) {
                                hadithMatchLimit = Int.max
                            }
                        }
                        // The first group still names its chapter, under the overall header.
                        HStack(spacing: 8) {
                            Text(group.chapter.displayTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                                .lineLimit(1)

                            Spacer()

                            CountPill(count: group.shown.count)
                        }
                    }

                    ForEach(group.shown) { hadith in
                        chapterLink(group.chapter, data: data, scrollToHadithId: hadith.idInBook) {
                            HadithRow(book: book, hadith: hadith, searchText: highlightTerm, compact: true).equatable()
                        }
                    }

                    if index == groups.count - 1 {
                        HadithLoadMoreControls(label: String(localized: "hadith matches"), hasMore: matches.hasMore, limit: $hadithMatchLimit)
                    }
                }
            }
        }
    }

    /// The ranked list (see `inBookRanked`): best first, so it is NOT grouped by chapter the way the
    /// book-ordered matches are. Each row lands in its chapter, scrolled to the hadith, like theirs.
    @ViewBuilder
    private func rankedMatchesSection(_ data: HadithBookData) -> some View {
        let hadiths = inBookRanked.rows.compactMap { data.hadiths.indices.contains($0) ? data.hadiths[$0] : nil }
        let bestMatch = searchFilters.sort == .relevance
        Section(header: SectionPillHeader(title: bestMatch ? String(localized: "HADITHS BY BEST MATCH") : String(localized: "CLOSEST HADITHS"),
                                          count: hadiths.count, overflow: inBookRanked.total > hadiths.count || inBookRanked.hasMore)) {
            rankedNotice(exactFoundNothing: inBookMatches.shown.isEmpty)

            // The Search All card: every ranked row on screen, and the engine's cap lifted (the
            // whole book re-ranked) when more matched than it kept. Under a grading or a Match rule
            // the total is a floor until then (see `ScopedOutcome.hasMore`), so the card shows none.
            if hadiths.count > rankedMatchLimit || inBookRanked.hasMore {
                let rankedTotal: Int? = inBookRanked.hasMore && inBookRanked.total <= hadiths.count ? nil : inBookRanked.total
                HadithSearchAllRow(shown: min(rankedMatchLimit, hadiths.count), total: rankedTotal,
                                   isLoading: rankedHadithLimit == Int.max && inBookRanked.hasMore) {
                    rankedMatchLimit = Int.max
                    if inBookRanked.hasMore { rankedHadithLimit = Int.max }
                }
            }

            // Each hadith's chapter is found HERE, not by an `if let` in the row: a row that may be
            // nothing is one the List has to build to count (see `OneRow`).
            let placed = hadiths.prefix(rankedMatchLimit).compactMap { hadith in
                data.chapter(of: hadith).map { (hadith: hadith, chapter: $0) }
            }
            ForEach(placed, id: \.hadith.id) { match in
                chapterLink(match.chapter, data: data, scrollToHadithId: match.hadith.idInBook) {
                    // The ranked rows paint the words the engine matched (a corrected spelling,
                    // say), or a corrected hit would show no highlight at all.
                    HadithRow(book: book, hadith: match.hadith,
                              searchText: inBookRanked.highlight.isEmpty ? searchText : inBookRanked.highlight,
                              compact: true).equatable()
                }
            }

            HadithLoadMoreControls(label: String(localized: "hadith matches"), hasMore: hadiths.count > rankedMatchLimit, limit: $rankedMatchLimit)
        }
    }

    /// One line above the ranked results saying what was searched for when it was not what was typed.
    @ViewBuilder
    private func rankedNotice(exactFoundNothing: Bool) -> some View {
        if !inBookRanked.corrections.isEmpty {
            let to = inBookRanked.corrections.quotedWords(\.to)
            let from = inBookRanked.corrections.quotedWords(\.from)
            Text("Showing results for \(to) instead of \(from).")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if inBookRanked.relaxed {
            Text("No hadith carries every word. These carry the most of them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if exactFoundNothing {
            Text("No hadith has these exact words. These are the closest: another word ending, or the words apart.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                Text(group.chapter.displayTitle.uppercased())
                    .lineLimit(1)
                Spacer()
                CountPill(count: group.shown.count)
            }
        }
    }

    /// Opening a chapter, in whichever navigation this screen is running: a push on iPhone, a swap of the
    /// detail column on iPad/Mac. The Quran tab's `quranNavigationLink`, for chapters - every row that
    /// opens a chapter (browsing, search matches, AI matches, last read) goes through this one place.
    ///
    /// The branch sits inside `OneRow`: these are List rows, and a bare branch made each of them a row
    /// the List builds to count and re-inserts after a scroll (see `OneRow`). A caller's cell modifiers
    /// (`rowSelectionHighlight`, swipes, `id`) go on what this returns, as they always did.
    private func chapterLink<Label: View>(
        _ chapter: HadithBookData.Chapter,
        data: HadithBookData,
        scrollToHadithId: Int? = nil,
        @ViewBuilder label: () -> Label
    ) -> some View {
        OneRow {
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

                        Image(systemName: "chevron.forward")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink {
                    LazyDestination {
                        HadithChapterView(book: book, bookData: data, chapter: chapter, scrollToHadithId: scrollToHadithId)
                    }
                } label: {
                    label()
                }
            }
        }
    }

    /// One chapter row with its full grammar - the link, context menu, swipes, and scroll id - shared by
    /// the browsing list and the search results.
    private func chapterRowLink(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> some View {
        let isCurrent = isReaderChapter(chapter)
        return chapterLink(chapter, data: data) {
            chapterRow(chapter, data: data)
        }
        // Column mode only: the left list stays truthful about what fills the right, including
        // after the reader swaps chapters from inside the reader itself. The SHARED row
        // highlight (2026-10-05), not a hand-rolled fill: this one was accent at 0.18 behind a
        // 12 pt corner while the Quran rows drew nothing and the Settings sidebar used the
        // system tint, which is how the three tabs came to mark a selected row three different
        // ways (Abu: "sometimes it gets highlighted then it stops sometimes it doesnt
        // highlight at all"). On the row, not the label: it is the row's whole cell.
        .rowSelectionHighlight(isCurrent, isActive: usesColumnNavigation)
        .contextMenu { chapterContextMenu(chapter, data: data) }
        // The surah rows' swipe language, icon-only: favorite leading, scroll-to trailing.
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    store.toggleChapterFavoriteOrConfirm(book: book, chapter: chapter)
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

    /// Column mode: the chapter the detail column is reading, followed through the reader's own
    /// Previous/Next. Shared by the row's tint and the tile's ring so the two can never disagree; the
    /// book check is a backstop, because chapter ids repeat from book to book.
    private func isReaderChapter(_ chapter: HadithBookData.Chapter) -> Bool {
        usesColumnNavigation
            && columnSelection.bookSlug == book.slug
            && columnSelection.currentChapterID == chapter.id
    }

    /// The chapter's place in the book, 1-based (0 for an introduction that opens it): what the
    /// badge and "CHAPTER N" header show.
    private func chapterOrdinal(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> Int {
        chapterStats(data).ordinals[chapter.id] ?? 1
    }

    private var chapterBadgeWidth: CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        return ("100" as NSString).size(withAttributes: [.font: font]).width + 8
    }

    /// "Hadiths 100-200" - which hadith numbers this chapter spans.
    /// A hadith number as a citation, never grouped ("1302", not "1,302"), in the interface's digits.
    /// A count is grouped; a citation number is a name.
    static func citation(_ number: Int) -> String {
        HadithDigits.display(String(number))
    }

    private func chapterRangeText(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> String? {
        guard let range = chapterStats(data).ranges[chapter.id] else { return nil }
        return range.lowerBound == range.upperBound
            ? String(localized: "Hadith \(Self.citation(range.lowerBound))")
            : String(localized: "Hadiths \(Self.citation(range.lowerBound))-\(Self.citation(range.upperBound))")
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
                    customTint: favorite ? settings.accentColor.color : nil,
                    inRow: true
                )
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        store.toggleChapterFavoriteOrConfirm(book: book, chapter: chapter)
                    }
                }
                .accessibilityLabel("Chapter \(chapterOrdinal(chapter, data: data))\(isLastRead ? String(localized: ", last read") : "")")

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
                        source: chapter.displayTitle,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )
                    .lineLimit(1)

                    Spacer(minLength: 8)

                    if !settings.hides(.chapterStats), let count = chapterStats(data).counts[chapter.id] {
                        CountPill(count: count)
                    }
                }

                // The Arabic name and the span share one row: Arabic under the English title,
                // the range under the count pill. In the Arabic interface the title above IS the
                // Arabic name, so the row keeps only the range.
                HStack(alignment: .firstTextBaseline) {
                    if !AppLanguage.isArabicScript, !chapter.arabic.isEmpty {
                        // The chapter number in Arabic-Indic digits beside the Arabic name, matching
                        // the grid tile - both scripts carry the number.
                        // The surah row's colours: the number carries the accent, the Arabic name
                        // is content in the primary colour (2026-10-26).
                        // A number the Arabic face cannot ring whole (`ArabicNumberFace`) is set in
                        // the system face, rounded like the rest of the interface.
                        let ordinal = chapterOrdinal(chapter, data: data)
                        let plainDigits = settings.useFontArabic && !ArabicNumberFace.draws(ordinal, in: settings.nonQuranArabicFontName)
                        Text(arabicNumberString(from: ordinal))
                            .font(settings.useFontArabic && !plainDigits
                                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2)
                                : .caption.weight(.semibold))
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace && !plainDigits)
                            .foregroundColor(settings.accentColor.color)
                            .layoutPriority(1)

                        HighlightedSnippet(
                            source: chapter.arabic,
                            term: searchText,
                            font: settings.useFontArabic
                                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2)
                                : .caption,
                            accent: settings.accentColor.color,
                            fg: .primary,
                            lineLimit: 1
                        )
                        .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                        .minimumScaleFactor(0.6)
                    }

                    Spacer(minLength: 8)

                    if !settings.hides(.chapterStats), let rangeText = chapterRangeText(chapter, data: data) {
                        Text(rangeText)
                            .font(.caption2)
                            .foregroundColor(.secondaryOnGlass)
                            .monospacedDigit()
                            .layoutPriority(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }

    /// The chapter grid's columns, on every width.
    private static let chapterGridColumns = 2

    /// A chapter grid row's id: the index of its first tile.
    private static func chapterGridRowID(_ start: Int) -> String { "hadith-chapter-row-\(start)" }

    #if os(iOS)
    /// The chapter rail's stops by chapter number (1, 5, 10 ... 95, 97 in Bukhari), for a book of 30
    /// chapters or more. An opening introduction (number 0) is the row above chapter 1, not a stop.
    /// Each stop's id is its chapter's index in `chapters`.
    private static func chapterRailItems(_ chapters: [HadithBookData.Chapter], data: HadithBookData,
                                         book: HadithCatalogBook) -> [JumpIndexItem] {
        let offset = chapters.first.map { data.position(of: $0) == 0 ? 1 : 0 } ?? 0
        let numbered = Array(chapters.dropFirst(offset))
        guard numbered.count >= 30 else { return [] }
        return JumpIndexItem.numberedStops(numbered.map { data.position(of: $0) },
                                           title: { String(localized: "Chapter \(data.position(of: numbered[$0]))") },
                                           subtitle: { numbered[$0].displayTitle(in: book) })
            .map { JumpIndexItem(id: $0.id + offset, label: $0.label, title: $0.title, subtitle: $0.subtitle) }
    }
    #endif

    /// The chapter as a grid card - the SurahRow grid tile's shape: Arabic on top, English and the
    /// span below, favorites tinted with the corner star.
    private func chapterGridTile(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> some View {
        let favorite = store.isChapterFavorite(slug: book.slug, chapterId: chapter.id)
        let isCurrent = isReaderChapter(chapter)
        return GridTileMenu {
            settings.hapticFeedback()
            // Column mode swaps the detail; the Hadith tab's stack appends to its path; a book opened
            // anywhere else pushes the chapter itself (the `pushDestination` pair in `body`).
            if usesColumnNavigation {
                withAnimation(.easeInOut) { selectChapter(chapter, data: data) }
            } else if let onPushChapter {
                onPushChapter(chapter, nil)
            } else if autoOpenTarget == nil {
                pushedChapter = chapter
            }
        } menu: {
            chapterContextMenu(chapter, data: data)
        } label: {
            // CENTERED, every line, the same grammar the surah grid tile uses (Abu, 2026-10-05:
            // "everything that isnt a long thing like an AYAH or a HADITH ... everything else
            // center"). A chapter name, its number and its span are short labels, not prose.
            VStack(alignment: .center, spacing: 2) {
                if !chapter.arabic.isEmpty {
                    HStack(spacing: 4) {
                        // The surah grid tile's top-row grammar: the chapter number in Arabic-Indic
                        // digits beside the Arabic name, so both scripts carry the number.
                        // The list row's rule for a number past the face's medallions.
                        let ordinal = chapterOrdinal(chapter, data: data)
                        let plainDigits = settings.useFontArabic && !ArabicNumberFace.draws(ordinal, in: settings.nonQuranArabicFontName)
                        Text(arabicNumberString(from: ordinal))
                            .font(settings.useFontArabic && !plainDigits
                                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2)
                                : .subheadline.weight(.semibold))
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace && !plainDigits)
                            .foregroundColor(settings.accentColor.color)
                            .layoutPriority(1)

                        HighlightedSnippet(
                            source: chapter.arabic,
                            term: searchText,
                            font: settings.useFontArabic
                                ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2)
                                : .subheadline,
                            accent: settings.accentColor.color,
                            fg: .primary,
                            lineLimit: 1
                        )
                        .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    // The star overlay sits in the trailing corner, so this line alone needs room for
                    // it. Taking that room from BOTH edges keeps it on the tile's true centre - the
                    // same centre the lines below use. A trailing-only inset (the `Spacer(minLength:
                    // 20)` this replaced) would clear the star but shift this line left of them.
                    .padding(.horizontal, 20)
                }

                // The Arabic interface leaves out the English line when the Arabic one above names
                // the chapter (and its number) already.
                if !AppLanguage.isArabicScript || chapter.arabic.isEmpty {
                    // One run, number and title, on as many lines as it needs up to three (Abu,
                    // 2026-11-15: "grid mode chapter lowkey chopped"). On one line, half the shelf's
                    // chapter titles (median 22 letters, a tile holds about 19) were either shrunk,
                    // each tile to its own size, or cut ("5: The Book of Mosques and..."). The book
                    // tile's grammar: the number rides the first line of a title that wraps.
                    Spacer(minLength: 0)

                    HighlightedSnippet(
                        source: chapter.english,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        leadingPrefix: "\(chapterOrdinal(chapter, data: data)): ",
                        leadingPrefixFont: .subheadline.monospacedDigit().weight(.bold),
                        leadingPrefixColor: settings.accentColor.color,
                        lineLimit: 3
                    )
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    // Its lines are the tile's height: never squeezed back to one by the frame.
                    .fixedSize(horizontal: false, vertical: true)
                    // "3: The Book of Faith" is an English line: the number stays before the name in the
                    // Arabic interface too.
                    .leftToRightContent()

                    Spacer(minLength: 0)
                }

                // Simple Mode leaves the span and the count to the reader's chapter header.
                if !settings.hides(.chapterStats) {
                    HStack(spacing: 4) {
                        if let rangeText = chapterRangeText(chapter, data: data) {
                            Text(rangeText)
                                .font(.caption2)
                                .foregroundColor(.secondaryOnGlass)
                                .monospacedDigit()
                        }

                        if let count = chapterStats(data).counts[chapter.id] {
                            Text("• \(count)")
                                .font(.caption2)
                                .foregroundColor(.secondaryOnGlass)
                                .monospacedDigit()
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                }
            }
            .multilineTextAlignment(.center)
            // The Arabic at the top and the span at the foot of every tile, the title centred in
            // what lies between: a row of tiles lines up whether a title takes one line or three.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            // As tall as its title needs, never shorter than the one-line tile: the grid gives a
            // row the height of its taller tile (`EqualColumnsLayout`) and each tile fills it. It
            // was one fixed height, which is what held every title to a single line.
            .frame(minHeight: settings.hides(.chapterStats) ? 62 : 78)
            .contentShape(Rectangle())
            // The chapter filling the detail column wears the sidebar's ring. It used to get a lighter
            // accent TINT, the favorite's own grammar, so the open chapter "just highlights the back as
            // if its favorited" (Abu, 2026-09-25). The tint is the favorite's alone now; both can show.
            .gridSelectionRing(isCurrent)
        }
        .conditionalGlassEffect(
            clear: !favorite,
            rectangle: true,
            useColor: favorite ? 0.25 : nil,
            customTint: favorite ? settings.accentColor.color : nil,
            inRow: true
        )
        .gridFavoriteStar(
            isFavorite: favorite,
            accent: settings.accentColor.color,
            accessibilityName: chapter.displayTitle
        ) {
            store.toggleChapterFavoriteOrConfirm(book: book, chapter: chapter)
        }
    }

    /// The SurahContextMenu's shape, for a chapter: fullscreen and sharing on top, then favorite
    /// and scroll-to.
    @ViewBuilder
    private func chapterContextMenu(_ chapter: HadithBookData.Chapter, data: HadithBookData) -> some View {
        Text(chapter.displayTitle(in: book))
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
            var parts = ["\(book.displayTitle) - \(chapter.displayTitle)"]
            parts.append(contentsOf: hadiths.map { HadithShareSheet.composedText(book: book, hadith: $0) })
            presentSystemShareSheet(items: [parts.joined(separator: "\n\n")])
        } label: {
            Label("Share Chapter", systemImage: "square.and.arrow.up")
        }

        Divider()

        Button(role: store.isChapterFavorite(slug: book.slug, chapterId: chapter.id) ? .destructive : .cancel) {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                store.toggleChapterFavoriteOrConfirm(book: book, chapter: chapter)
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

/// The sidebar ring (`gridSelectionRing`) for a CATALOG tile: the book the detail column is reading,
/// or, given a hadith, the bookmark it was opened at. Its own view observing the selection, because
/// nothing above the detail column may (see `HadithDetailColumn`): a chapter pick re-renders these
/// few rings, never the catalog they sit in.
struct HadithReadingRing: View {
    @ObservedObject private var selection = HadithColumnSelection.shared

    let slug: String
    var hadithID: Int? = nil

    private var isReading: Bool {
        guard let target = selection.target, target.book.slug == slug else { return false }
        guard let hadithID else { return true }
        // Until the reader leaves the bookmark's chapter by its own Previous/Next.
        return target.scrollToHadithId == hadithID && selection.currentChapterID == target.chapter.id
    }

    var body: some View {
        Color.clear
            .gridSelectionRing(isReading)
            .allowsHitTesting(false)
    }
}

/// The list-row counterpart of `HadithReadingRing`: the filled bed a CATALOG ROW wears while the
/// detail column is reading that book. Its own view observing the selection for the same reason the
/// ring is - nothing above the detail column may observe it, so a chapter pick re-renders these few
/// beds and never the catalog behind them.
///
/// Grid mode ringed its tiles and list mode drew nothing at all, so on iPad the same screen marked
/// the open book in one shape and not the other (Abu, 2026-10-05).
///
/// A modifier on the row (`rowSelectionHighlight` paints the row's whole cell), and the only thing that
/// observes the selection: a pick re-renders these modifiers, never the catalog. `isActive` is column
/// mode; the iPhone's stack leaves the rows alone.
struct HadithReadingRowHighlight: ViewModifier {
    @ObservedObject private var selection = HadithColumnSelection.shared

    let slug: String
    let isActive: Bool

    func body(content: Content) -> some View {
        content.rowSelectionHighlight(selection.target?.book.slug == slug, isActive: isActive)
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
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
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
        // Nor below empty: a chapter's ids need not rise all the way (the Musnad's fifteen rows of
        // Abu Rimthah keep the low ids they always had, inside a chapter of later ones).
        return min(max(CGFloat(current - firstID) / CGFloat(lastID - firstID), 0), 0.97)
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
    /// For the title pill's Dynamic Type ceiling (see `NavigationTitlePill`).
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #if DEBUG
    /// `-launchHadithShare` (with `-launchHadithOpen`): the landed hadith's share sheet, presented headlessly.
    @State private var debugShareHadith: HadithBookData.Hadith? = nil
    #endif
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
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
    /// Whether the text the reader LANDS on is decoded and resident (`landingRows`): the gate the
    /// rows wait behind. True at init when it already is, which is nearly always (the book screen
    /// and the Hadith tab decode it ahead of the tap, `HadithBookData.prewarmLandingText`, and a
    /// search result has drawn it); otherwise `prefetchText` decodes it as the screen appears, a
    /// 256 KB block of about 3 ms, so the first frame still has its rows.
    ///
    /// It used to ask for the WHOLE chapter, decode it on a detached task and show a spinner
    /// meanwhile (Abu, 2026-11-13: "When page first opens there's a progress view I don't want that
    /// should be preprocessed before it opens"). That was sized for the 2 MB blocks of the time, at
    /// 130 ms each; even at 3 ms the hop to the task and back was a frame or two of spinner on
    /// every chapter's first visit, and forty-odd decodes of it on a long book of the Musnad.
    @State private var textReady: Bool
    /// Index in `allChapterHadiths` of the first row laid out: 0, always, in a chapter shown whole;
    /// the start of the part on screen in a long one (see "A long chapter, a part at a time").
    @State private var partStart: Int

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
        // Opened ON a hadith: the part that holds it is the one laid out.
        let start = HadithChapterView.partStart(holding: scrollToHadithId, in: hadiths)
        _partStart = State(initialValue: start)
        _textReady = State(initialValue: bookData.hasText(
            rows: HadithChapterView.landingRows(in: hadiths, partStart: start, target: scrollToHadithId)))
        #if DEBUG
        // Under `-renderCounter`: a chapter screen built before a tap (an eager link) shows here.
        if RenderCounter.enabled { NSLog("HADITH CHAPTER INIT %@ chapter %d", book.slug, chapter.id) }
        #endif
    }

    /// The chapter's rows in the book's row table.
    private static func rowRange(of chapter: HadithBookData.Chapter) -> Range<Int> {
        chapter.firstRow..<(chapter.firstRow + chapter.rowCount)
    }

    // MARK: A long chapter, a part at a time

    /// The longest chapter laid out whole. The list gives every hadith its own Section (the ayah
    /// list's shape), and a List's layout costs the SQUARE of its section count. Measured 2026-11-12
    /// on the 17 Pro simulator, the push to a chapter of 921 hadiths (the longest the shelf had
    /// before the whole Musnad) took under a second, one of 2,924 froze for six, and the 11,737 of
    /// the Musnad's book of the Companions who narrated most had not come back after eighty.
    ///
    /// So a chapter longer than this is laid out a PART at a time, and the Previous | Next pair
    /// steps through its parts before it steps to the neighbouring chapter. Every chapter outside
    /// the Musnad is under the limit and renders whole, exactly as it always did.
    static let wholeChapterLimit = 1_000
    /// The most hadiths a part holds.
    static let partSizeGoal = 500

    /// How many hadiths a part of a chapter `count` long holds: the chapter cut into the fewest
    /// parts of at most `partSizeGoal`, evened out so the last part is never a stub.
    static func partLength(ofChapterWith count: Int) -> Int {
        guard count > wholeChapterLimit else { return max(count, 1) }
        let parts = (count + partSizeGoal - 1) / partSizeGoal
        return (count + parts - 1) / parts
    }

    /// Where the part holding the chapter's hadith at `index` starts: 0 in a chapter shown whole.
    static func partStart(holdingIndex index: Int, count: Int) -> Int {
        guard count > wholeChapterLimit, index >= 0, index < count else { return 0 }
        let length = partLength(ofChapterWith: count)
        return index / length * length
    }

    private static func partStart(holding idInBook: Int?, in hadiths: [HadithBookData.Hadith]) -> Int {
        guard hadiths.count > wholeChapterLimit, let idInBook,
              let index = hadiths.firstIndex(where: { $0.idInBook == idInBook }) else { return 0 }
        return partStart(holdingIndex: index, count: hadiths.count)
    }

    private var isInParts: Bool { allChapterHadiths.count > Self.wholeChapterLimit }

    /// The hadiths laid out, as indices into `allChapterHadiths`: the whole chapter, or its part.
    private var shownRange: Range<Int> {
        let count = allChapterHadiths.count
        guard isInParts else { return 0..<count }
        let start = min(max(0, partStart), count - 1)
        return start..<min(start + Self.partLength(ofChapterWith: count), count)
    }

    private var shownHadiths: [HadithBookData.Hadith] {
        isInParts ? Array(allChapterHadiths[shownRange]) : allChapterHadiths
    }

    /// Where the part before this one starts; nil at the chapter's first part and in a whole chapter.
    private var earlierPartStart: Int? {
        guard isInParts, shownRange.lowerBound > 0 else { return nil }
        return max(0, shownRange.lowerBound - Self.partLength(ofChapterWith: allChapterHadiths.count))
    }

    /// Where the part after this one starts; nil at the chapter's last part and in a whole chapter.
    private var laterPartStart: Int? {
        guard isInParts, shownRange.upperBound < allChapterHadiths.count else { return nil }
        return shownRange.upperBound
    }

    /// "Hadiths 4037-4525": the numbers the part starting at `start` covers, in the chapter list's
    /// own wording for a chapter's span.
    private func partLabel(startingAt start: Int) -> String {
        let count = allChapterHadiths.count
        let end = min(start + Self.partLength(ofChapterWith: count), count)
        guard start >= 0, start < end, let range = Self.range(of: Array(allChapterHadiths[start..<end])) else { return "" }
        return range.lowerBound == range.upperBound
            ? String(localized: "Hadith \(HadithBookView.citation(range.lowerBound))")
            : String(localized: "Hadiths \(HadithBookView.citation(range.lowerBound))-\(HadithBookView.citation(range.upperBound))")
    }

    /// Step to another part of this chapter: a chapter swap's landing (the literal top, the pair
    /// included, from the list's `onChange(of: partStart)`) and its last-read record.
    private func showPart(startingAt start: Int) {
        guard isInParts, allChapterHadiths.indices.contains(start) else { return }
        settings.hapticFeedback()
        // The part's text was never asked for before it was laid out (the chapter's first visit
        // was trusted to have decoded all of it, and to still hold it): now its landing is, BEFORE
        // the rows change, like a chapter swap's, so a step never decodes inside a row body.
        prefetchText(hadiths: allChapterHadiths, partStart: start, scrollTarget: nil)
        withAnimation(.easeInOut) {
            partStart = start
            visibility.visibleIDs = []
            highlightedHadithID = nil
        }
        let book = book
        let first = allChapterHadiths[start]
        HadithLastReadDebounce.schedule {
            HadithStore.shared.recordLastRead(book: book, hadith: first)
        }
    }

    /// Lay out the part that holds a hadith about to be scrolled to. Nothing to do in a chapter
    /// shown whole, or when the hadith is in the part already on screen.
    private func showPart(holding idInBook: Int) {
        guard isInParts else { return }
        let start = Self.partStart(holding: idInBook, in: allChapterHadiths)
        guard start != partStart else { return }
        // The match was a row a moment ago, so its text is resident nearly always; the rest of
        // the part decodes behind it.
        prefetchText(hadiths: allChapterHadiths, partStart: start, scrollTarget: idInBook)
        partStart = start
        visibility.visibleIDs = []
    }

    // MARK: Text before rows

    /// The book rows the reader lands on in a chapter's `hadiths` (`HadithBookData.landingRows`):
    /// around the hadith a search or a reference opens on, or else the head of the part laid out.
    static func landingRows(in hadiths: [HadithBookData.Hadith], partStart: Int, target idInBook: Int?) -> Range<Int> {
        guard let first = hadiths.first else { return 0..<0 }
        let index = idInBook.flatMap { id in hadiths.firstIndex { $0.idInBook == id } } ?? partStart
        return HadithBookData.landingRows(firstRow: first.row, count: hadiths.count, index: index)
    }

    /// The book rows of the part laid out: the whole chapter when it is shown whole.
    private static func partRows(in hadiths: [HadithBookData.Hadith], partStart: Int) -> Range<Int> {
        guard let first = hadiths.first else { return 0..<0 }
        let count = hadiths.count
        guard count > wholeChapterLimit else { return first.row..<(first.row + count) }
        let start = min(max(0, partStart), count - 1)
        return (first.row + start)..<(first.row + min(start + partLength(ofChapterWith: count), count))
    }

    /// Have the text the reader lands on resident NOW and open the gate, then decode the rest of
    /// the part laid out off the main thread, so scrolling on through it never decodes inside a
    /// row body. The landing is one block, two at a seam; when the prewarms missed it, it is
    /// decoded right here (about 3 ms a block on the simulator's Debug build, measured 2026-11-13)
    /// instead of on a task the first frame would have to be drawn without. Never the whole of a
    /// long chapter: on a 3 GB phone a long book of the Musnad is twice what the cache keeps.
    private func prefetchText(hadiths: [HadithBookData.Hadith], partStart start: Int, scrollTarget: Int?) {
        let data = bookData
        data.prewarmText(rows: Self.landingRows(in: hadiths, partStart: start, target: scrollTarget))
        if !textReady { textReady = true }
        let part = Self.partRows(in: hadiths, partStart: start)
        guard !data.hasText(rows: part) else { return }
        Task.detached(priority: .userInitiated) { data.prewarmText(rows: part) }
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

    /// Whether to show the Previous | Next pair at all. Both slots render whenever there is anywhere
    /// to go, so the test is the BOOK having more than one chapter, not this chapter having a
    /// neighbour: at chapter 1 the Previous slot is the dimmed "First Chapter", not nothing.
    private var showsChapterNav: Bool { bookData.chapters.count > 1 || isInParts }

    /// The pair ABOVE the first hadith. Simple Mode keeps only the one below the last
    /// (Docs/Product/Simple Mode Guide.md), and the two scrolls that land "at the literal top" target the
    /// first hadith instead of a pair that is not there.
    private var showsTopChapterNav: Bool { showsChapterNav && !settings.hides(.topChapterPair) }

    /// Swap the chapter in place - recompute its derived reading data, reset the search and visibility,
    /// and record it as Last Read - exactly as the surah reader swaps surahs without a new push.
    /// `recordLastRead: false` is for the page-mode entry jump TO the last read: recording the
    /// chapter's first hadith would overwrite the exact spot the page seed is about to land on.
    /// `landingOn` is the hadith the caller scrolls to next (a number match in another chapter): in a
    /// long chapter its part is the one laid out; a plain swap opens the chapter's first.
    private func navigateToChapter(_ target: HadithBookData.Chapter, recordLastRead: Bool = true, landingOn: Int? = nil) {
        settings.hapticFeedback()
        let hadiths = Array(bookData.hadiths(in: target))
        let start = Self.partStart(holding: landingOn, in: hadiths)
        // The new chapter's landing text first, so its rows are laid out with their text.
        prefetchText(hadiths: hadiths, partStart: start, scrollTarget: landingOn)
        withAnimation(.easeInOut) {
            chapter = target
            chapterIndex = bookData.chapters.firstIndex(where: { $0.id == target.id }) ?? 0
            allChapterHadiths = hadiths
            partStart = start
            chapterRange = Self.range(of: hadiths)
            searchText = ""
            visibility.visibleIDs = []
            highlightedHadithID = nil
            // The selection is this chapter's. A Previous/Next swap used to keep select mode on
            // with the old chapter's picks counted in the title and nothing for the bar to act on
            // (`syncChapterFromIndex` already ended it; the surah reader's swap does too).
            isSelectingHadiths = false
            selectedHadithIDs = []
        }
        onChapterChanged?(target)
        if recordLastRead, let first = hadiths.first {
            // Through the shared debounce slot, like every other last-read record: an immediate store
            // publish mid-transition re-renders the observing book screen - the pop hazard - and in
            // the chapter list owns the record (single slot: last record wins).
            let book = book
            HadithLastReadDebounce.schedule {
                HadithStore.shared.recordLastRead(book: book, hadith: first)
            }
        }
    }

    @State private var searchText = ""
    /// The book screen's button row, for one chapter: gradings, word mode, order, and the two result
    /// kinds a chapter has. The session filters are this screen's own and never reset by themselves
    /// (a Previous/Next swap keeps them); the order and the Show choices are the shared preference.
    @State private var searchFilters = HadithSearchFilters.restored(scope: .oneChapter)
    @State private var showSearchFilterSheet = false
    @State private var isChapterSearchFocused = false

    #if os(iOS)
    // Within-chapter AI search: the ONE all-books corpus (no per-book corpus any more - Performance
    // Guide, Phase 7 step 3), hits filtered to this book and chapter.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var chapterAIHits: [HadithBookData.Hadith] = []
    @State private var chapterAISearchTask: Task<Void, Never>?

    private func runChapterAISearch(query: String) {
        chapterAISearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filters = searchFilters
        guard SemanticSearchEngine.isSupported, filters.shows(.ai, in: .oneChapter),
              trimmed.count >= 3, !trimmed.containsArabicScript,
              !HadithBookData.isNumberQuery(HadithReferenceParser.localQuery(trimmed, in: book)) else {
            if !chapterAIHits.isEmpty { chapterAIHits = [] }
            return
        }
        let accept = filters.gradeTest(for: book, data: bookData)
        let corpusID = HadithSemanticCorpus.id
        if !semanticEngine.isReady(corpusID), !semanticEngine.isBuilding(corpusID), !HadithSemanticCorpus.isGathering {
            // Load-or-build on the first AI-eligible query; `readyCorpora` re-runs this search.
            let engine = semanticEngine
            Task { await HadithSemanticCorpus.prepare(engine: engine, store: HadithStore.shared) }
        }
        let slugPrefix = "\(book.slug)|"
        let chapterID = chapter.id

        chapterAISearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            // Over-fetch from the whole shelf, keep this chapter's rows - filtering after ranking
            // beats a per-chapter (or per-book) corpus.
            let results = await semanticEngine.search(corpusID: corpusID, query: trimmed, limit: 120)
            guard !Task.isCancelled else { return }
            let keys = await MainActor.run { semanticEngine.corpus(corpusID)?.itemKeys }
            let candidates = results.compactMap { result -> HadithBookData.Hadith? in
                guard let keys, keys.indices.contains(result.index) else { return nil }
                let key = keys[result.index]
                guard key.hasPrefix(slugPrefix), let number = Int(key.dropFirst(slugPrefix.count)),
                      let hadith = bookData.hadith(numbered: number), hadith.chapterId == chapterID else { return nil }
                return hadith
            }
            // A grading reads the rows' text blocks, so it is tested off the main thread.
            var kept: Set<Int>? = nil
            if let accept {
                let rows = candidates.map(\.row)
                kept = await Task.detached(priority: .userInitiated) { Set(rows.filter { $0 >= 0 && accept($0) }) }.value
                guard !Task.isCancelled else { return }
            }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines), filters == searchFilters,
                      chapterID == chapter.id else { return }
                chapterAIHits = candidates.filter { kept?.contains($0.row) ?? true }.prefix(6).map { $0 }
            }
        }
    }
    #endif

    /// The chapter's keyword matches for the settled query - filled by `runChapterKeywordSearch`
    /// (debounced, scanned off-main one search block at a time). The body reads this; it used to
    /// scan the chapter inside `body` on every keystroke and on every corpus progress tick.
    @State private var chapterKeywordMatches: [HadithBookData.Hadith] = []
    @State private var chapterKeywordTask: Task<Void, Never>?
    /// Non-empty when `chapterKeywordMatches` is the RANKED list (`HadithRankedSearch.rankedRows`
    /// over this chapter's rows): Best Match was chosen, or the exact scan found nothing and the
    /// forgiving answer (a misspelling, another word ending, words apart) stands in for it.
    @State private var chapterRanked = HadithRankedSearch.ScopedOutcome()

    private func runChapterKeywordSearch(query: String) {
        chapterKeywordTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filters = searchFilters
        guard !trimmed.isEmpty, filters.shows(.hadiths, in: .oneChapter) else {
            if !chapterKeywordMatches.isEmpty { chapterKeywordMatches = [] }
            if !chapterRanked.isEmpty { chapterRanked = HadithRankedSearch.ScopedOutcome() }
            return
        }
        // Script-aware, same as the book search: one field per query, matched against the fold the
        // pack carries - which is also the fold the highlighter uses, so "Allah's" and "A'ishah"
        // match what gets coloured. Number matches get their own labelled section above; a text
        // match on the same hadith would otherwise draw the identical row twice.
        let folded = HadithFold.query(trimmed)
        let numbered = Set(numberMatches().map(\.hadith.row))
        let data = bookData
        let range = Self.rowRange(of: chapter)
        let chapterID = chapter.id
        // The filters in force for THIS scan (the book screen's rule): words as needles with the Match
        // rule's word edges, the grading (plus Exact's letters) as a row test on text matches only, and
        // the one-needle sweep when none is set. A number reading is answered above, outside all of this.
        let needles = filters.needles(for: trimmed)
        let accept = filters.rowTest(for: book, data: data, query: trimmed)
        let rankedAccept = filters.rankedRowTest(for: book, data: data, query: trimmed)
        let isPlainScan = accept == nil && needles.queries.count == 1 && needles.rule == .contains
        let wantsRanked = filters.sort == .relevance
        let isNumberReading = HadithBookData.isNumberQuery(HadithReferenceParser.localQuery(trimmed, in: book))
        let book = book

        chapterKeywordTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            let scan = Task.detached(priority: .userInitiated) { () -> (hits: [HadithBookData.Hadith], ranked: HadithRankedSearch.ScopedOutcome) in
                let rows = isPlainScan
                    ? data.matchingRows(in: range, query: folded, limit: Int.max)
                    : data.matchingRows(in: range, queries: needles.queries, requireAll: needles.requireAll,
                                        limit: Int.max, rule: needles.rule, accept: accept)
                if Task.isCancelled { return ([], HadithRankedSearch.ScopedOutcome()) }
                var hits = rows.filter { !numbered.contains($0) }.map { data.hadiths[$0] }
                // The ranked lane over this chapter's rows: asked for (Best Match), or the exact scan
                // came back empty. Its rows REPLACE the list; a number reading has none (it is not words).
                var ranked = HadithRankedSearch.ScopedOutcome()
                if wantsRanked || rows.isEmpty, !isNumberReading {
                    ranked = HadithRankedSearch.rankedRows(query: trimmed, book: book, data: data, within: range,
                                                           cap: max(1, range.count), accept: rankedAccept) ?? ranked
                    ranked.rows.removeAll { numbered.contains($0) || !data.hadiths.indices.contains($0) }
                    if !ranked.isEmpty { hits = ranked.rows.map { data.hadiths[$0] } }
                }
                let highlight = ranked.isEmpty || ranked.highlight.isEmpty ? trimmed : ranked.highlight
                // The first screenful's highlight folds and cross-language spans, warm before render.
                for hadith in hits.prefix(12) {
                    if Task.isCancelled { break }
                    let strings = hadith.allText
                    HighlightedSnippet.prewarmNormalization(of: [strings.arabic, strings.text, strings.narrator])
                    HadithRow.prewarmCrossLanguageSpans(query: highlight, text: strings)
                }
                return (hits, ranked)
            }
            let result = await withTaskCancellationHandler {
                await scan.value
            } onCancel: {
                scan.cancel()
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines), filters == searchFilters,
                      chapterID == chapter.id else { return }
                chapterKeywordMatches = result.hits
                chapterRanked = result.ranked
            }
        }
    }
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @State private var showChapterSettings = false
    /// The hadith the reader marked by tapping it - the ayah list's grey attention tint, for hadiths.
    /// Tap to mark (keep your place), tap again to clear; arriving at a searched hadith marks it too.
    @State private var highlightedHadithID: Int? = nil
    /// Set once the chapter has landed on `scrollToHadithId`. The landing runs from the list's
    /// `onAppear`, which runs again every time the tab comes back, and each run scrolled a reader who
    /// had read on back to the hadith they arrived at and marked it again (Abu, 2026-10-09). The surah
    /// reader's `didScrollDown`.
    @State private var didLandOnArrival = false
    /// Which hadiths are on screen - drives the pinned header's progress bar, the surah reader's way.
    /// A plain (NOT observed) reference in @State: rows write into it on every viewport crossing, and
    /// only ChapterProgressBar subscribes - so scrolling no longer invalidates this whole view.
    @State private var visibility = ChapterVisibilityModel()
    /// The chapter's reading mode: the scrolling list unless the reader asks for pages (via the title
    /// menu or Hadith Settings). Same key, same default, as the chapters screen declares.
    /// The title menu's chapter picker sheet.
    @State private var showChapterPicker = false
    // Multi-select (list mode): pick several hadiths, then copy/share/bookmark them all at once - the
    // surah reader's select mode, for hadiths.
    @State private var isSelectingHadiths = false
    @State private var selectedHadithIDs: Set<Int> = []
    /// The hadith checked last by hand, which a hold on another runs the selection FROM
    /// (`extendHadithSelection`). Only trusted while it is still selected, so the places that empty
    /// the selection need not clear it.
    @State private var selectionAnchorID: Int?

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The chapter's hadith search, SurahView's way: filter the reading list itself and show every
    /// match as a FULL row - no paging, no load-more, exactly how the ayah list filters in place.
    /// The matches come from state (`runChapterKeywordSearch`), never from a scan in the body.
    private func chapterMatches() -> [HadithBookData.Hadith] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return allChapterHadiths }
        return chapterKeywordMatches
    }

    private var chapterMatchesTitle: String {
        if chapterRanked.isEmpty { return String(localized: "MATCHING HADITHS") }
        return searchFilters.sort == .relevance ? String(localized: "HADITHS BY BEST MATCH") : String(localized: "CLOSEST HADITHS")
    }

    /// One line under the ranked header saying what was searched for when it was not what was typed.
    private var chapterRankedNotice: String? {
        if !chapterRanked.corrections.isEmpty {
            let to = chapterRanked.corrections.quotedWords(\.to)
            let from = chapterRanked.corrections.quotedWords(\.from)
            return String(localized: "Showing results for \(to) instead of \(from).")
        }
        if chapterRanked.relaxed { return String(localized: "No hadith carries every word. These carry the most of them.") }
        if searchFilters.sort != .relevance {
            return String(localized: "No hadith has these exact words. These are the closest: another word ending, or the words apart.")
        }
        return nil
    }

    private var chapterEmptyMessage: String {
        if !searchFilters.shows(.hadiths, in: .oneChapter) { return String(localized: "Hadith matches are turned off in the filters above.") }
        return searchFilters.hasSessionFilters ? String(localized: "No hadiths found with these filters.") : String(localized: "No hadiths found.")
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
    /// A chapter named in a number match's caption: its Arabic name in the Arabic interface. The pieces
    /// join through the catalog's "%@ · %@", whose Arabic reads "،": a "·" beside Arabic-Indic digits
    /// reads as a zero.
    private static func captionName(_ chapter: HadithBookData.Chapter) -> String {
        chapter.displayTitle
    }

    private func numberMatches() -> [NumberMatch] {
        // The book's own name is optional here: "bukhari 1:4" reads as "1:4".
        let local = HadithReferenceParser.localQuery(searchText, in: book)

        // "1:4": the fourth hadith of chapter 1, wherever the reader is now (Abu, 2026-09-21).
        if let reference = HadithBookData.chapterHadith(inQuery: local) {
            guard let hadith = bookData.hadith(chapterPosition: reference.chapter, position: reference.hadith) else { return [] }
            var caption = String(localized: "Chapter \(reference.chapter), Hadith \(reference.hadith)")
            if let home = bookData.chapter(of: hadith), home.id != chapter.id {
                caption = String(localized: "\(caption) · \(Self.captionName(home))")
            }
            return [NumberMatch(hadith: hadith, caption: caption)]
        }

        guard let query = HadithBookData.citationNumber(inQuery: local) else { return [] }
        let number = query.base
        let ordinal = Self.ordinalFormatter.string(from: NSNumber(value: number)) ?? "\(number)"

        var found: [NumberMatch] = []
        // "8a" names a citation variant, not an ordinal - the in-chapter reading is digits-only.
        if query.suffix == nil, number <= allChapterHadiths.count {
            found.append(NumberMatch(hadith: allChapterHadiths[number - 1], caption: String(localized: "\(ordinal) in this chapter")))
        }

        if let overall = bookData.hadith(referenced: number, suffix: query.suffix) {
            var caption = String(localized: "Hadith \(HadithBookView.citation(number)) in this book")
            // It can live in another chapter - name that chapter, since tapping the row goes there.
            if let home = bookData.chapter(of: overall), home.id != chapter.id {
                caption = String(localized: "\(caption) · \(Self.captionName(home))")
            }
            if let existing = found.firstIndex(where: { $0.hadith.row == overall.row }) {
                found[existing] = NumberMatch(hadith: overall, caption: String(localized: "\(found[existing].caption) · \(caption)"))
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
            navigateToChapter(home, landingOn: target)
        } else {
            settings.hapticFeedback()
            withAnimation { searchText = "" }
            // In a long chapter the match may sit in another part than the one laid out.
            showPart(holding: target)
        }
        highlightedHadithID = target
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { scrollProxy.scrollTo("chapter-hadith-\(target)", anchor: .top) }
        }
    }

    /// What the page shows, as one choice - backs the title menu's "Page Text" picker, the mushaf's
    /// page-language picker for hadiths. 0 = Arabic & English, 1 = Arabic only, 2 = English only.
    var body: some View {
        RenderCounter.hit("HadithChapterView")
        // A chapter is ALWAYS a scrolling list. The right-to-left paged reader this screen used to
        // offer (and its `hadithPageMode` toggle, in the toolbar and in Hadith Settings) was removed:
        // hadith are read as a list, unlike the mushaf, where a page is the unit the text is printed in.
        return chapterList
        // ONE pinned chapter-identity header for BOTH reading modes (the title above carries only the
        // book + chapter number, so nothing repeats). The list's progress bar rides on top of it.
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                ChapterProgressBar(
                    visibility: visibility,
                    firstID: allChapterHadiths.first?.idInBook,
                    lastID: allChapterHadiths.last?.idInBook,
                    isActive: !isSearchActive,
                    color: settings.accentColor.color
                )

                floatingChapterHeader

                // The book screen's filter buttons, under the chapter header while a search is live
                // (the field focused or holding text; a filter alone keeps its setting but not the
                // row). No bar background: the header above floats as glass too.
                if !isSelectingHadiths, isChapterSearchFocused || isSearchActive {
                    HadithSearchFilterBar(filters: $searchFilters, scope: .oneChapter) { showSearchFilterSheet = true }
                        // Before iOS 26 the row's horizontal scroller took spare height from this
                        // stack and left an empty band under the buttons.
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Select mode takes the bar over the way the surah reader's does (`SurahView.applySurahToolbar`,
        // 2026-11-09): the count where the title was, Select All in the back button's place, Done
        // trailing. The bottom bar then holds only the actions (`selectionActionBar`).
        .navigationBarBackButtonHidden(isSelectingHadiths)
        .toolbar {
            if isSelectingHadiths {
                ToolbarItem(placement: .navigationBarLeading) {
                    selectAllButton
                }

                ToolbarItem(placement: .principal) {
                    selectionTitle
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    selectionDoneButton
                }
            } else {
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
        }
        .onChange(of: searchText) { text in
            runChapterKeywordSearch(query: text)
            #if os(iOS)
            runChapterAISearch(query: text)
            #endif
        }
        // A pressed filter button is a new search of the same words.
        .onChange(of: searchFilters) { filters in
            filters.persistPreferences()
            runChapterKeywordSearch(query: searchText)
            #if os(iOS)
            runChapterAISearch(query: searchText)
            #endif
        }
        // The order and the Show choices are one preference shared with the tab root and the book.
        .onAppear {
            searchFilters.adoptStoredPreferences()
            #if DEBUG
            // `-hadithChapterSearch <term>` (with `-launchHadithOpen <slug>:<id>`): the in-chapter search.
            HadithBookView.debugSeed("-hadithChapterSearch") { if searchText.isEmpty { searchText = $0 } }
            #endif
        }
        #if os(iOS)
        .onChange(of: semanticEngine.readyCorpora) { ready in
            guard ready.contains(HadithSemanticCorpus.id), !searchText.isEmpty else { return }
            runChapterAISearch(query: searchText)
        }
        #endif
        .sheet(isPresented: $showSearchFilterSheet) {
            HadithSearchFilterSheet(filters: $searchFilters, scope: .oneChapter)
                .smallMediumSheetPresentation()
        }
        // The match rows paint by the Match button's rule, not only filter by it.
        .environment(\.searchWordRule, searchFilters.highlightWordRule)
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
            // The landing's text, then the rest of the part laid out, before any row asks for it
            // (nothing at all when resident). The hadith opened on is the landing only while its
            // part is the one on screen: back from a pushed screen after a step, the part's head is.
            let opened = scrollToHadithId.flatMap { id in
                Self.partStart(holding: id, in: allChapterHadiths) == partStart ? id : nil
            }
            prefetchText(hadiths: allChapterHadiths, partStart: partStart, scrollTarget: opened)
            // In LIST mode the chapter is the reading surface, so it owns the Last Read record - routed
            // through the ONE shared debounce slot, deferred past the push transition (`recordLastRead`
            // publishes through the store the PARENT book screen observes and renders, and re-diffing
            // the List hosting the auto-open NavigationLink mid-push is what spuriously popped a
            // deep-linked chapter back to the chapter list).
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
    }

    /// Rebuild the derived chapter state when the INDEX moved without `navigateToChapter` (the paged
    /// footer's chevrons). No-op when already in sync.
    private func syncChapterFromIndex(_ index: Int) {
        guard bookData.chapters.indices.contains(index),
              bookData.chapters[index].id != chapter.id else { return }
        let target = bookData.chapters[index]
        let hadiths = Array(bookData.hadiths(in: target))
        prefetchText(hadiths: hadiths, partStart: 0, scrollTarget: nil)
        chapter = target
        allChapterHadiths = hadiths
        partStart = 0
        chapterRange = Self.range(of: hadiths)
        highlightedHadithID = nil
        isSelectingHadiths = false
        selectedHadithIDs = []
        onChapterChanged?(target)
    }

    /// A search result or reference landed here: open on the hadith itself, and MARK
    /// it (the Quran's arrival rule: the selection shows you where you landed; tap to clear). Fired
    /// once the rows exist, which is `textReady` - not the List's appearance.
    private func scheduleArrivalScroll(_ scrollProxy: ScrollViewProxy) {
        guard let target = scrollToHadithId, !didLandOnArrival else { return }
        didLandOnArrival = true
        highlightedHadithID = target
        // Landing on the chapter's FIRST hadith lands at the literal top, the Previous/Next pair
        // included (the chapter-swap rule): anchoring hadith 1 itself left the pair's bottom edge
        // peeking out under the bar.
        let anchorID: String
        if allChapterHadiths.first?.idInBook == target, showsTopChapterNav {
            anchorID = "chapter-top-nav"
        } else {
            anchorID = "chapter-hadith-\(target)"
        }
        // Opened ON the hadith, the way a searched ayah opens in the surah reader (`scrollToAyah`):
        // plain jumps from the first frame, no animation. The animated scroll a beat after the push
        // rode down past every hadith above the target, a long ride on a long chapter (Abu,
        // 2026-10-31: "for Quran when I search an ayah ... it opens on it but for Hadith it scrolls
        // down"). The List lays rows out as they come on screen, so a far target can land a little
        // off on the first jump; the later ones correct it from the rows measured around it.
        func jump(_ remaining: Int) {
            scrollProxy.scrollTo(anchorID, anchor: .top)
            guard remaining > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { jump(remaining - 1) }
        }
        DispatchQueue.main.async { jump(3) }
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
                    beginSelectingHadiths()
                }
            } label: {
                Label("Select Hadiths", systemImage: "checkmark.circle")
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
                // as a mistake); it truncates instead. The Arabic interface names the book once, by
                // the Arabic title beside it.
                if !AppLanguage.isArabicScript {
                    Text(book.englishTitle)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                }

                // Arabic at the surah title's size (headline + 2) whatever the Arabic-face setting:
                // the Basic face used to drop this to plain .headline and scale down to half, which
                // is why this pill sat visibly smaller than the surah reader's.
                HighlightedSnippet(
                    source: book.arabicTitle,
                    term: "",
                    font: Font.arabic(settings.nonQuranArabicFontName, size: NavigationTitlePill.pointSize(.headline, at: dynamicTypeSize) + 2),
                    accent: settings.accentColor.color,
                    fg: settings.accentColor.color,
                    lineLimit: 1
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
            }

            Text(bookData.position(of: chapter) == 0
                 ? "Introduction"
                 : "Chapter \(bookData.position(of: chapter)) of \(bookData.chapters.count - (bookData.opensWithIntroduction ? 1 : 0))")
                .font(.caption2)
                .lineLimit(1)
                // -2, NOT the surah pill's -8: that pull-up is tuned for the Quran faces' contained
                // metrics, but hadith Arabic (full tashkeel, and the Basic face's tall line box) has
                // real descenders here - at -8 they sat on top of this line with no gap at all.
                .padding(.top, -2)
        }
        // Bar chrome: the pill stops scaling at the extra-large text size (see `NavigationTitlePill`).
        .dynamicTypeSize(...NavigationTitlePill.typeSizeCeiling)
        .frame(maxWidth: .infinity)
        .foregroundColor(.primary)
        .contentShape(Rectangle())
        .padding(.horizontal)
        .padding(.bottom, 6)
        .conditionalGlassEffect()
    }

    private var chapterList: some View {
        ScrollViewReader { scrollProxy in
        #if os(iOS)
        // The hadiths' places in the chapter down the edge, the surah reader's ayah rail: the
        // numbers the rows lead with, the book's own citation in the bubble.
        let railItems = !isSearchActive && textReady ? hadithRailItems : []
        #endif
        List {
            Group {
                if isSearchActive {
                    // SurahView's search, exactly: the reading list filters IN PLACE - every match as a
                    // FULL row in its own Section, the count pill up top, no paging. Tapping a match
                    // clears the search, scrolls to the hadith, and MARKS it (the ayah list's arrival).
                    let numbered = numberMatches()
                    let allMatches = chapterMatches()
                    // Every match is a full row in its own Section, which a List cannot lay out by
                    // the thousand (`wholeChapterLimit`): a word half of a long chapter carries
                    // lists its first thousand rows and says how many there are.
                    let matches = allMatches.count > Self.wholeChapterLimit ? Array(allMatches.prefix(Self.wholeChapterLimit)) : allMatches

                    // A number query answers first: the labelled hadith(s) that number names, above
                    // whatever the same digits happen to match in the text.
                    if !numbered.isEmpty {
                        Section(header: SectionPillHeader(title: String(localized: "BY NUMBER"), count: numbered.count)) {}
                            .padding(.bottom, -12)

                        ForEach(numbered) { match in
                            Section {
                                selectableRow(
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(match.caption)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                                        // No `searchText`: highlighting the digits inside the narration is
                                        // noise - the number is the row's identity here, not a text match.
                                        chapterRow(match.hadith)
                                    },
                                    for: match.hadith
                                ) { openMatch(match.hadith, scrollProxy: scrollProxy) }
                            }
                        }
                    }

                    #if os(iOS)
                    // AI hits the keyword filter (or the number lookup) already shows would render
                    // twice - the AI section carries only the extras, above the keyword rows.
                    let shownRows = Set(allMatches.map(\.row)).union(numbered.map(\.hadith.row))
                    let aiOnly = chapterAIHits.filter { !shownRows.contains($0.row) }
                    if !aiOnly.isEmpty {
                        Section(header: SectionPillHeader(title: String(localized: "AI MATCHES"), count: aiOnly.count, icon: "sparkles")) {}
                            .padding(.bottom, -12)

                        ForEach(aiOnly, id: \.row) { hadith in
                            Section {
                                selectableRow(chapterRow(hadith), for: hadith) { openMatch(hadith, scrollProxy: scrollProxy) }
                            }
                        }
                    }
                    #endif

                    // "No hadiths found" would contradict the rows just above it, so the text-match
                    // section stands down entirely once a number has answered.
                    // The ranked list (see `chapterRanked`) says so in its header, and says why it is
                    // not the exact one.
                    let notice = matches.count < allMatches.count
                        ? String(localized: "Showing \(matches.count) of \(allMatches.count)").localizedDigits
                        : (chapterRanked.isEmpty ? nil : chapterRankedNotice)
                    if !matches.isEmpty || numbered.isEmpty {
                        Section(header: SectionPillHeader(title: chapterMatchesTitle, count: allMatches.count)) {
                            if matches.isEmpty {
                                Text(chapterEmptyMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else if let notice {
                                Text(notice)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.bottom, matches.isEmpty || notice != nil ? 0 : -12)
                    }

                    ForEach(matches) { hadith in
                        Section {
                            // The ranked rows paint the words the engine matched (a corrected spelling, say).
                            selectableRow(
                                chapterRow(hadith, searchText: chapterRanked.isEmpty || chapterRanked.highlight.isEmpty ? searchText : chapterRanked.highlight),
                                for: hadith
                            ) { openMatch(hadith, scrollProxy: scrollProxy) }
                        }
                    }
                } else {
                    // The Quran ayah list's shape: each hadith is its own Section, with a Previous/Next
                    // chapter pair at the top and bottom that swaps the chapter in place. The chapter's
                    // identity is the pinned header above; rows report visibility for its progress bar.
                    if showsTopChapterNav {
                        Section { chapterNavButtonPair() }
                            .id("chapter-top-nav")
                    }

                    // No rows until the landing text is resident, which `prefetchText` sees to as
                    // the screen appears (see `textReady`), and nothing in their place: the spinner
                    // that stood here only ever flashed.
                    ForEach(textReady ? shownHadiths : []) { hadith in
                        Section {
                            // The ayah list's tap grammar: selecting mode builds the selection
                            // (accent tint, see `selectableRow`); otherwise tap-to-mark (grey
                            // attention tint). Outside select mode the row's own controls (number
                            // pill, menu) win their taps.
                            selectableRow(chapterRow(hadith, searchText: searchText), for: hadith,
                                          isMarked: highlightedHadithID == hadith.idInBook) {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    highlightedHadithID = highlightedHadithID == hadith.idInBook ? nil : hadith.idInBook
                                }
                            }
                                .id("chapter-hadith-\(hadith.idInBook)")
                                .onAppear { visibility.visibleIDs.insert(hadith.idInBook) }
                                .onDisappear { visibility.visibleIDs.remove(hadith.idInBook) }
                        }
                    }

                    // With its rows: alone under the top pair it would show for a frame and jump away.
                    if showsChapterNav, textReady {
                        Section { chapterNavButtonPair() }
                    }
                }
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        .jumpIndexRailRoom(railItems)
        #endif
        // The ayah list's fix for a pinned header sitting flush on the first row: breathing room
        // via the list's top content margin, not a phantom spacer row.
        .applyConditionalListStyle(topContentMargin: 11, readingWidth: true)
        .compactListSectionSpacing()
        #if os(iOS)
        .jumpIndexRail(railItems, accessibilityName: String(localized: "Hadith index"), proxy: scrollProxy, showsProgress: false) { item in
            // The stops index the hadiths laid out (`hadithRailItems`): the whole chapter, or its part.
            let index = shownRange.lowerBound + item.id
            return allChapterHadiths.indices.contains(index) ? "chapter-hadith-\(allChapterHadiths[index].idInBook)" : nil
        }
        #endif
        .onAppear {
            if textReady { scheduleArrivalScroll(scrollProxy) }
        }
        .onChange(of: textReady) { ready in
            if ready { scheduleArrivalScroll(scrollProxy) }
        }
        // (The pinned chapter header + progress bar live at the BODY level now.)
        .onChange(of: chapterIndex) { _ in
            // A Previous/Next chapter swap lands at the LITERAL top of the new chapter - the nav
            // buttons above the first hadith included - not at hadith 1 with them scrolled away.
            scrollToListTop(scrollProxy)
        }
        // A step to another part of a long chapter lands the same way. (A match that opens in
        // another part moves the part too; its own scroll, a beat later, takes it to the hadith.)
        .onChange(of: partStart) { _ in
            scrollToListTop(scrollProxy)
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
                SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                          onFocusChanged: { focused in
                              withAnimation { isChapterSearchFocused = focused }
                          })
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .background(Color.white.opacity(0.00001))
                    .minimizedBarStyle(barsCollapsed)
            }
        }
        }
    }

    /// The literal top of what is laid out: the Previous | Next pair above the first hadith when it
    /// is there, the first hadith otherwise. Where a chapter swap and a step between parts land.
    private func scrollToListTop(_ scrollProxy: ScrollViewProxy) {
        let target: String
        if showsTopChapterNav {
            target = "chapter-top-nav"
        } else if let first = shownHadiths.first?.idInBook {
            target = "chapter-hadith-\(first)"
        } else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation { scrollProxy.scrollTo(target, anchor: .top) }
        }
    }

    #if os(iOS)
    /// The hadith rail's stops, by place in the chapter (1, 10, 20 ...), for a chapter of 20 or more:
    /// over the hadiths laid out, so in a long chapter the rail rules the part on screen (501, 520 ...).
    private var hadithRailItems: [JumpIndexItem] {
        let hadiths = allChapterHadiths
        guard hadiths.count >= 20 else { return [] }
        let shown = shownRange
        return JumpIndexItem.numberedStops(Array((shown.lowerBound + 1)...shown.upperBound),
                                           title: { String(localized: "Hadith \(shown.lowerBound + $0 + 1)") },
                                           subtitle: { book.displayReference(hadiths[shown.lowerBound + $0].displayNumber) })
    }
    #endif

    // MARK: Multi-select (the surah reader's bulk actions, for hadiths)

    /// Turns select mode on with nothing in it (the title menu's Select Hadiths). The surah
    /// reader's `beginSelectingAyahs`: a search keeps its results under select mode but not its
    /// keyboard (the bar it is typed in gives way to the action bar, and a field that leaves the
    /// screen focused never reports losing focus, so the flag is cleared by hand), and the reading
    /// mark goes, a tint that would read as one more pick. Callers wrap this in their own animation.
    private func beginSelectingHadiths() {
        endEditing()
        if isChapterSearchFocused { isChapterSearchFocused = false }
        highlightedHadithID = nil
        selectedHadithIDs = []
        selectionAnchorID = nil
        isSelectingHadiths = true
    }

    /// Toggle one hadith's place in the selection. The one checked last is where a hold runs from
    /// (`extendHadithSelection`); unchecking it leaves nothing to run from.
    private func toggleHadithSelection(_ idInBook: Int) {
        if selectedHadithIDs.contains(idInBook) {
            selectedHadithIDs.remove(idInBook)
            if selectionAnchorID == idInBook { selectionAnchorID = nil }
        } else {
            selectedHadithIDs.insert(idInBook)
            selectionAnchorID = idInBook
        }
    }

    /// A hold in select mode, the surah reader's `extendSelection`: every hadith from the one
    /// checked last through the held one joins the selection, in the order the list shows them
    /// (the chapter's own, across its parts, or a search's results), and the held hadith is where
    /// the next hold runs from. With nothing to run from it is a slow tap and toggles the hadith.
    /// A run only ever adds.
    private func extendHadithSelection(_ idInBook: Int) {
        guard let anchor = selectionAnchorID, anchor != idInBook, selectedHadithIDs.contains(anchor) else {
            toggleHadithSelection(idInBook)
            return
        }
        let order = listedSearchHadithIDs ?? allChapterHadiths.map(\.idInBook)
        guard let from = order.firstIndex(of: anchor), let to = order.firstIndex(of: idInBook) else {
            toggleHadithSelection(idInBook)
            return
        }
        selectedHadithIDs.formUnion(order[min(from, to)...max(from, to)])
        selectionAnchorID = idInBook
    }

    /// The hadiths a search lists that can be picked, in the order the list shows them (by number,
    /// the AI matches, then the matches), nil with no query: what Select All and a hold's run
    /// cover while a search narrows the list, not the chapter behind it. A number match from
    /// another chapter is left out (see `chapterRow`). The same rules the list is built by, from
    /// the same state.
    private var listedSearchHadithIDs: [Int]? {
        guard isSearchActive else { return nil }
        let numbered = numberMatches().map(\.hadith)
        let allMatches = chapterMatches()
        var ids: [Int] = []
        var seen = Set<Int>()
        func add(_ hadith: HadithBookData.Hadith) {
            guard hadith.chapterId == chapter.id, seen.insert(hadith.idInBook).inserted else { return }
            ids.append(hadith.idInBook)
        }
        numbered.forEach(add)
        #if os(iOS)
        let shownRows = Set(allMatches.map(\.row)).union(numbered.map(\.row))
        chapterAIHits.filter { !shownRows.contains($0.row) }.forEach(add)
        #endif
        allMatches.prefix(Self.wholeChapterLimit).forEach(add)
        return ids
    }

    /// A hadith as the reading list and its search draw it, wired for select mode. The selection
    /// is this chapter's, so a number match from ANOTHER chapter takes no part in it.
    private func chapterRow(_ hadith: HadithBookData.Hadith, searchText: String = "") -> some View {
        let id = hadith.idInBook
        let selectable = hadith.chapterId == chapter.id
        return HadithRow(
            book: book, hadith: hadith, searchText: searchText, showsChapterPosition: true,
            isSelecting: isSelectingHadiths && selectable,
            isSelected: isSelectingHadiths && selectedHadithIDs.contains(id),
            onToggleSelection: {
                withAnimation(.easeInOut(duration: 0.1)) { toggleHadithSelection(id) }
            }
        )
        .equatable()
    }

    /// Select mode's gestures and wash on a row, a reading row or a search result alike: a tap
    /// toggles the hadith, a hold selects the run up to it, and only the selection is tinted (the
    /// ayah row's wash, filling the whole cell: Abu, 2026-10-09, "fix it for hadith"). Outside
    /// select mode the row keeps its own tap (`plainTap`) and its reading mark (`isMarked`), and
    /// the hold is masked off so the row's long-press menu opens. A search result used to jump to
    /// its hadith on a tap in select mode too, which ended the search being picked from.
    private func selectableRow<Row: View>(_ row: Row, for hadith: HadithBookData.Hadith, isMarked: Bool = false,
                                          plainTap: @escaping () -> Void) -> some View {
        let id = hadith.idInBook
        let selectable = hadith.chapterId == chapter.id
        let isSelected = isSelectingHadiths && selectedHadithIDs.contains(id)
        let standsAside = isSelectingHadiths && !selectable
        return row
            .contentShape(Rectangle())
            .onTapGesture {
                guard isSelectingHadiths else {
                    plainTap()
                    return
                }
                guard selectable else { return }
                settings.hapticFeedback()
                withAnimation(.easeInOut(duration: 0.1)) { toggleHadithSelection(id) }
            }
            .highPriorityGesture(
                LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                    settings.hapticFeedback()
                    withAnimation(.easeInOut(duration: 0.1)) { extendHadithSelection(id) }
                },
                including: isSelectingHadiths && selectable ? .all : .subviews
            )
            .opacity(standsAside ? 0.45 : 1)
            .allowsHitTesting(!standsAside)
            .rowWash(isSelectingHadiths
                     ? (isSelected ? ReaderRowTint.accent(settings.accentColor.color, defaultView: settings.defaultView) : nil)
                     : (isMarked ? ReaderRowTint.attention : nil))
    }

    private var selectedHadiths: [HadithBookData.Hadith] {
        allChapterHadiths.filter { selectedHadithIDs.contains($0.idInBook) }
    }

    /// Every selected hadith is already bookmarked - the bar's bookmark button then removes instead
    /// (the surah reader's `allSelectedBookmarked` rule).
    private var allSelectedBookmarked: Bool {
        !selectedHadithIDs.isEmpty && selectedHadiths.allSatisfy { store.isBookmarked(slug: book.slug, idInBook: $0.idInBook) }
    }

    /// Bookmarks every selected hadith that isn't, or - when all of them are - removes all the
    /// bookmarks after ONE confirmation (every removal asks first; notes on them are lost with them).
    private func bulkToggleHadithBookmarks() {
        let targets = selectedHadiths
        if allSelectedBookmarked {
            // One hadith: the single removal's own question, which names it ("Remove 1 bookmarks?"
            // otherwise).
            if targets.count == 1, let only = targets.first {
                withAnimation(.easeInOut) { store.toggleBookmarkOrConfirm(book: book, hadith: only) }
                return
            }
            let noted = targets.filter { store.note(slug: book.slug, idInBook: $0.idInBook) != nil }.count
            RemovalConfirmation.present(
                title: noted > 0 ? String(localized: "Remove \(targets.count) bookmarks and delete \(noted) notes?") : String(localized: "Remove \(targets.count) bookmarks?"),
                message: noted > 0
                    ? String(localized: "The selected hadiths will be removed from your bookmarks, and their notes will be deleted.")
                    : String(localized: "The selected hadiths will be removed from your bookmarks."),
                confirmTitle: String(localized: "Remove Bookmarks")
            ) {
                withAnimation(.easeInOut) {
                    for hadith in targets { store.toggleBookmark(book: book, hadith: hadith) }
                }
            }
        } else {
            withAnimation(.easeInOut) {
                for hadith in targets where !store.isBookmarked(slug: book.slug, idInBook: hadith.idInBook) {
                    store.toggleBookmark(book: book, hadith: hadith)
                }
            }
        }
    }

    /// The bulk actions while selecting, the surah reader's bar exactly (`SurahView.selectionActionBar`,
    /// 2026-11-09): one glass row of bare symbols, Copy, Share, Bookmark, where the search normally
    /// sits. The count, Select All and Done moved up to the navigation bar for the duration (see the
    /// toolbar), so the two readers' select modes read the same. The old bar put all six in one slab.
    private var selectionActionBar: some View {
        HStack(spacing: 0) {
            bulkActionButton(String(localized: "Copy"), systemImage: "doc.on.doc") {
                UIPasteboard.general.string = selectedHadithsText
                CopyConfirmation.shared.show()
            }
            bulkActionButton(String(localized: "Share"), systemImage: "square.and.arrow.up") {
                presentSystemShareSheet(items: [selectedHadithsText])
            }
            bulkActionButton(allSelectedBookmarked ? String(localized: "Remove Bookmarks") : String(localized: "Bookmark"),
                             systemImage: allSelectedBookmarked ? "bookmark.fill" : "bookmark") {
                bulkToggleHadithBookmarks()
            }
        }
        .disabled(selectedHadithIDs.isEmpty)
        .opacity(selectedHadithIDs.isEmpty ? 0.45 : 1)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .conditionalGlassEffect()
    }

    /// Every selected hadith's share text, in reading order.
    private var selectedHadithsText: String {
        selectedHadiths
            .map { HadithShareSheet.composedText(book: book, hadith: $0) }
            .joined(separator: "\n\n")
    }

    /// Select mode's navigation bar, in place of the chapter title, the gear and the back button: the
    /// count as the title, Select All leading, Done trailing (the system's edit-mode arrangement).
    private var selectionTitle: some View {
        Text("\(selectedHadithIDs.count) Selected")
            .font(.headline)
            .monospacedDigit()
            .lineLimit(1)
            .accessibilityAddTraits(.isHeader)
    }

    /// The whole chapter on screen, or none of it. In a long chapter what is on screen is its part:
    /// Select All adds that part to whatever is already picked, and a second tap clears everything.
    /// While a search narrows the list it is the results (`listedSearchHadithIDs`): it used to
    /// take the chapter behind them.
    private var selectAllButton: some View {
        let shown = shownHadiths
        let listed = listedSearchHadithIDs
        let allSelected: Bool
        if let listed {
            allSelected = !listed.isEmpty && listed.allSatisfy { selectedHadithIDs.contains($0) }
        } else if isInParts {
            allSelected = !shown.isEmpty && shown.allSatisfy { selectedHadithIDs.contains($0.idInBook) }
        } else {
            allSelected = !allChapterHadiths.isEmpty && selectedHadithIDs.count >= allChapterHadiths.count
        }

        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                selectedHadithIDs = allSelected ? [] : selectedHadithIDs.union(listed ?? shown.map(\.idInBook))
            }
        } label: {
            Text(allSelected ? "Deselect All" : "Select All")
                .lineLimit(1)
        }
        .tint(settings.accentColor.color)
    }

    private var selectionDoneButton: some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                isSelectingHadiths = false
                selectedHadithIDs = []
            }
        } label: {
            Text("Done")
                .fontWeight(.semibold)
        }
        .tint(settings.accentColor.color)
    }

    /// A bare symbol in an equal-width slot, the title for VoiceOver: the surah reader's
    /// `bulkActionLabel`, so the two bars draw alike.
    private func bulkActionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundColor(settings.accentColor.color)
                .frame(maxWidth: .infinity, minHeight: 36)
                .contentShape(Rectangle())
                .accessibilityLabel(title)
        }
        .buttonStyle(.plain)
    }

    /// The chapter's identity, pinned above the list - reorganized around the ordinal chip: number in
    /// glass leading (the surah header's badge), name + Arabic stacked beside it, the count pill with
    /// the hadith span trailing. One consistent grammar with the book view's pinned header below.
    private var floatingChapterHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("\(bookData.position(of: chapter))")
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
                // read as one grey block with nothing to hold on to. In the Arabic interface the title
                // IS the Arabic name, so the secondary Arabic line is left out.
                Text(chapter.displayTitle(in: book).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if !AppLanguage.isArabicScript, !chapter.arabic.isEmpty {
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
                         ? "HADITH \(HadithBookView.citation(range.lowerBound))"
                         : "HADITHS \(HadithBookView.citation(range.lowerBound))-\(HadithBookView.citation(range.upperBound))")
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
    ///
    /// BOTH slots always render, like the surah reader's pair: at the book's ends the dead direction
    /// stays visible but dimmed, with "First Chapter" / "Last Chapter" where a name would be - so it
    /// reads as "there is nothing before this one", not as a mysteriously missing button (user rule:
    /// make it clear you can't go back/forward there).
    ///
    /// In a long chapter, laid out a part at a time, a slot steps to the part before or after the
    /// one on screen, named by the hadith numbers it holds ("Hadiths 4037-4525"), and only at the
    /// chapter's own first or last part does it name the neighbouring chapter.
    @ViewBuilder
    private func chapterNavButtonPair() -> some View {
        HStack(spacing: 10) {
            if let earlier = earlierPartStart {
                navButton(title: String(localized: "Previous"), subtitle: partLabel(startingAt: earlier), enabled: true,
                          systemImage: "chevron.backward", trailing: false) { showPart(startingAt: earlier) }
            } else {
                chapterNavButton(title: String(localized: "Previous"), chapter: previousChapter, endNote: String(localized: "First Chapter"),
                                 systemImage: "chevron.backward", trailing: false)
            }
            if let later = laterPartStart {
                navButton(title: String(localized: "Next"), subtitle: partLabel(startingAt: later), enabled: true,
                          systemImage: "chevron.forward", trailing: true) { showPart(startingAt: later) }
            } else {
                chapterNavButton(title: String(localized: "Next"), chapter: nextChapter, endNote: String(localized: "Last Chapter"),
                                 systemImage: "chevron.forward", trailing: true)
            }
        }
    }

    private func chapterNavButton(title: String, chapter target: HadithBookData.Chapter?, endNote: String,
                                  systemImage: String, trailing: Bool) -> some View {
        let subtitle = target.map { chapter -> String in
            let ordinal = bookData.position(of: chapter)
            // The Arabic interface names the chapter by its Arabic title, in its own digits.
            if AppLanguage.isArabicScript {
                return "\(ordinal.formatted(.number.grouping(.never))). \(chapter.displayTitle(in: book))"
            }
            return "\(ordinal). \(chapter.english.isEmpty ? book.englishTitle : chapter.english)"
        } ?? endNote
        return navButton(title: title, subtitle: subtitle, enabled: target != nil, systemImage: systemImage, trailing: trailing) {
            if let target { navigateToChapter(target) }
        }
    }

    /// One slot of the pair: where it goes is the caller's (a chapter, or a part of this one).
    private func navButton(title: String, subtitle: String, enabled: Bool, systemImage: String, trailing: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if !trailing {
                    chapterNavChevron(systemImage, enabled: enabled)
                }

                VStack(alignment: trailing ? .trailing : .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(enabled ? .primary : .secondary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)

                if trailing {
                    chapterNavChevron(systemImage, enabled: enabled)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
    }

    /// The chevron in a soft accent disc - the surah reader's `surahNavigationChevron`, so the pair
    /// reads as tappable on both Liquid Glass and the classic look. The dead direction's disc goes
    /// gray with the rest of its slot.
    private func chapterNavChevron(_ systemImage: String, enabled: Bool) -> some View {
        Image(systemName: systemImage)
            .font(.footnote.weight(.bold))
            .foregroundColor(enabled ? settings.accentColor.color : .secondary)
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill((enabled ? settings.accentColor.color : Color.secondary).opacity(0.16))
            )
    }
}

// MARK: - Chapter picker (the SurahPickerSheet, for chapters)

/// The title menu's "Choose Chapter": every chapter with its ordinal, names, and count - the current
/// one highlighted - swapping the chapter IN PLACE on selection, the surah picker's exact behavior.
struct HadithChapterPickerSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
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
        let plain = query.foldingLatinDiacritics
        return all.filter {
            $0.element.english.foldingLatinDiacritics.localizedCaseInsensitiveContains(plain)
                || String(bookData.position(of: $0.element)) == query
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
        SheetNavigationContainer {
            ScrollViewReader { proxy in
            List {
                let counts = countsByChapter
                ForEach(filteredChapters, id: \.element.id) { _, chapter in
                    Button {
                        settings.hapticFeedback()
                        onPick(chapter)
                    } label: {
                        HStack(spacing: 10) {
                            Text("\(bookData.position(of: chapter))")
                                .font(.caption.weight(.bold))
                                .foregroundColor(settings.accentColor.color)
                                .frame(minWidth: 30)
                                .padding(.vertical, 6)
                                .conditionalGlassEffect(
                                    useColor: chapter.id == currentChapterID ? 0.3 : nil,
                                    customTint: chapter.id == currentChapterID ? settings.accentColor.color : nil,
                                    inRow: true
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                // The Arabic interface titles the row by the Arabic name and leaves
                                // out the Arabic line under it.
                                Text(chapter.displayTitle(in: book))
                                    .font(.subheadline.weight(chapter.id == currentChapterID ? .bold : .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.7)

                                if !AppLanguage.isArabicScript, !chapter.arabic.isEmpty {
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
                    .id(chapter.id)
                }
                // On the ForEach, not on each row: the modifier is a branch, and on a row it makes
                // the row one the List builds to count (see `OneRow`). Here it paints the same cells.
                .themedListRowBackground()
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
        .accentColor(settings.accentColor.color)
    }
}

#endif
