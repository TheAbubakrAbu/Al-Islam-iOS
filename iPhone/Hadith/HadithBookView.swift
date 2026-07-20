import SwiftUI

// One collection: the chapter list (with in-place page mode), one chapter, and the right-to-left
// paged reader that fits as many hadiths per page as the font sizes allow.

#if os(iOS)

// MARK: - One collection: chapters + book search + page mode

struct HadithBookView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

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

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false

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
        semanticEngine.prepare(corpusID: semanticCorpusID, version: "v1-\(texts.count)", texts: texts)
    }

    private func runAISearch(query: String, data: HadithBookData?) {
        aiSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SemanticSearchEngine.isSupported, let data,
              trimmed.count >= 3, !trimmed.containsArabicScript else {
            if !aiHits.isEmpty { withAnimation { aiHits = [] } }
            return
        }
        prepareSemanticCorpus(data)
        let corpusID = semanticCorpusID

        aiSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let results = await semanticEngine.search(corpusID: corpusID, query: trimmed, limit: 10)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                withAnimation {
                    aiHits = results.compactMap { data.hadiths.indices.contains($0.index) ? data.hadiths[$0.index] : nil }
                }
            }
        }
    }

    init(book: HadithCatalogBook) {
        self.book = book
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
    private func matchingHadiths(_ data: HadithBookData) -> (shown: [HadithBookData.Hadith], hasMore: Bool) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3 else { return ([], false) }
        // Script-aware: an Arabic query can only live in the Arabic text, a Latin one only in the
        // English - so each keystroke pays for exactly ONE field. The store's preprocessed index
        // (built when the book was decoded) replaces per-hadith normalization entirely; the raw
        // path only runs in the moment before the index lands.
        let arabicQuery = query.containsArabicScript
        let cleanQuery = arabicQuery ? settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns : ""
        let lowerQuery = query.lowercased()
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
                        ProgressView("Loading \(book.englishTitle)...")
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
                             : "Chapters will open as pages right away - a right-to-left paged reader fitting as many hadiths per page as your font sizes allow.")
                    }
                }
            }
        }
        .modifier(HadithTrailingToolbar(
            hadithGridMode: $hadithGridMode,
            showHadithSettings: $showHadithSettings
        ))
        .sheet(isPresented: $showHadithSettings) {
            HadithSettingsSheet()
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

                        Text(book.arabicTitle)
                            .font(settings.useFontArabic
                                  ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 2)
                                  : .headline)
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                            .foregroundColor(settings.accentColor.color)
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
                    Text("This fetches the whole book for offline reading. It may use significant data - Wi-Fi is recommended.")
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

                        Text("Loads the full book just for now - nothing stays on your device.")
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
        ScrollViewReader { scrollProxy in
        List {
            Group {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(data.metadata.english.title)
                                .font(.subheadline.weight(.semibold))

                            Spacer(minLength: 8)

                            Text(book.arabicTitle)
                                .font(settings.useFontArabic
                                      ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2)
                                      : .subheadline)
                                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                                .foregroundColor(settings.accentColor.color)
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

                // While searching: chapter matches first, then hadith matches - each page-sized with
                // load-more controls, the Quran search's way.
                if isSearchActive {
                    // AI matches appear AUTOMATICALLY at the very top, the Quran ayah search's exact
                    // grammar - no mode to enter. Keyword sections always stay below.
                    aiMatchesSection(data)

                    if !filteredChapters.isEmpty {
                        Section(header: SectionPillHeader(title: "MATCHING CHAPTERS", count: filteredChapters.count)) {
                            ForEach(filteredChapters.prefix(chapterMatchLimit)) { chapter in
                                chapterRowLink(chapter, data: data)
                            }

                            HadithLoadMoreControls(label: "chapter matches", hasMore: filteredChapters.count > chapterMatchLimit, limit: $chapterMatchLimit)
                        }
                    }

                    // Hadith matches, the Quran ayah-search way: compact rows grouped per chapter,
                    // each group with its own count pill; tapping one opens the chapter scrolled to it.
                    hadithMatchesSections(data)

                    if filteredChapters.isEmpty && matchingHadiths(data).shown.isEmpty {
                        Section {
                            Text("No matches found.")
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
                                ForEach(filteredChapters) { chapter in
                                    chapterGridTile(chapter, data: data)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        ForEach(filteredChapters) { chapter in
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
        .onChange(of: searchText) { text in
            // A new query starts back at the first page of matches.
            chapterMatchLimit = 5
            hadithMatchLimit = 5
            runAISearch(query: text, data: data)
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
        // Apple Music-style: the bottom search bar minimizes while scrolling down.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: $searchText)
                .padding([.horizontal, .top], -8)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .background(Color.white.opacity(0.00001))
                .minimizedBarStyle(barsCollapsed)
        }
        }
    }

    /// The CHAPTERS header carrying the book's shape at a glance - the size and the count pills sit at
    /// its trailing edge, in the same pill language the other section headers use.
    private func chaptersSectionHeader(_ data: HadithBookData) -> some View {
        HStack(spacing: 6) {
            Text("CHAPTERS")

            Spacer()

            statPill(bookSizeText)
            statPill("\(data.hadiths.count) Hadiths")
            statPill("\(data.chapters.count) Chapters")
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
                                HadithRow(book: book, hadith: hadith, searchText: searchText, compact: true)
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
    private func hadithMatchesSections(_ data: HadithBookData) -> some View {
        let matches = matchingHadiths(data)
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
                            HadithRow(book: book, hadith: hadith, searchText: searchText, compact: true)
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

struct HadithChapterView: View {
    @ObservedObject private var settings = Settings.shared

    let book: HadithCatalogBook
    let bookData: HadithBookData
    /// A search result or reference landing here scrolls the list to this hadith, the Quran's way.
    let scrollToHadithId: Int?

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
    private func navigateToChapter(_ target: HadithBookData.Chapter) {
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
            visibleHadithIDs = []
            highlightedHadithID = nil
        }
        if let first = hadiths.first {
            HadithStore.shared.recordLastRead(book: book, hadith: first)
        }
    }

    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @State private var showChapterSettings = false
    /// The hadith the reader marked by tapping it - the ayah list's grey attention tint, for hadiths.
    /// Tap to mark (keep your place), tap again to clear; arriving at a searched hadith marks it too.
    @State private var highlightedHadithID: Int? = nil
    /// The Quran search's page size: matches show 5 at a time until Load More asks for more.
    @State private var hadithMatchLimit = 5
    /// Which hadiths are on screen - drives the pinned header's progress bar, the surah reader's way.
    @State private var visibleHadithIDs: Set<Int> = []
    /// The chapter's reading mode, the Quran mushaf's default: pages unless the reader turns it off
    /// (here or in Hadith Settings).
    @AppStorage("hadithPageMode") private var hadithPageMode = true
    /// Drives the "Switch to Page/List View?" confirmation before the reading mode actually flips.
    @State private var showReadingModeConfirm = false

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The chapter's hadith search, the Quran search's way: scan only until one PAST the shown page;
    /// `hasMore` renders the count pill as "5+".
    private func chapterMatches() -> (shown: [HadithBookData.Hadith], hasMore: Bool) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return (allChapterHadiths, false) }
        // Script-aware, same as the book search: one field per query, served from the store's
        // preprocessed index whenever it's ready.
        let arabicQuery = query.containsArabicScript
        let cleanQuery = arabicQuery ? settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns : ""
        let lowerQuery = query.lowercased()
        let index = HadithStore.shared.searchIndexes[book.slug]

        var results: [HadithBookData.Hadith] = []
        for hadith in allChapterHadiths {
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
            // A scroll target always lands in the list - a paged reader can't scroll to one hadith.
            if hadithPageMode && scrollToHadithId == nil {
                HadithPagedView(book: book, bookData: bookData, chapterIndex: chapterIndex)
            } else {
                chapterList
            }
        }
        .navigationTitle("Chapter \(chapterIndex + 1)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // The Quran reader's toolbar: pages/list top left (behind a confirmation anchored to
            // the button), the gear top right.
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    settings.hapticFeedback()
                    showReadingModeConfirm = true
                } label: {
                    Image(systemName: hadithPageMode ? "list.bullet.rectangle" : "book")
                }
                .accessibilityLabel(hadithPageMode ? "Read as a list" : "Read as pages")
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
                         ? "This chapter will be shown as a scrolling list of hadiths."
                         : "Pages open right away - this chapter becomes a right-to-left paged reader, fitting as many hadiths per page as your font sizes allow.")
                }
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
            HadithSettingsSheet()
                .smallMediumSheetPresentation()
        }
        .onAppear {
            // The chapter IS the reading surface now, so it owns the Last Read record.
            let target = scrollToHadithId.flatMap { id in allChapterHadiths.first { $0.idInBook == id } }
                ?? allChapterHadiths.first
            if let target {
                HadithStore.shared.recordLastRead(book: book, hadith: target)
            }
        }
    }

    private var chapterList: some View {
        ScrollViewReader { scrollProxy in
        List {
            Group {
                if isSearchActive {
                    // The Quran search's way: compact rows, five at a time; tapping one clears the
                    // search and lands the list on the hadith itself.
                    let matches = chapterMatches()
                    Section(header: SectionPillHeader(title: "MATCHING HADITHS", count: matches.shown.count, overflow: matches.hasMore)) {
                        ForEach(matches.shown) { hadith in
                            HadithRow(book: book, hadith: hadith, searchText: searchText, compact: true)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    withAnimation { searchText = "" }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation { scrollProxy.scrollTo("chapter-hadith-\(hadith.idInBook)", anchor: .top) }
                                    }
                                }
                        }

                        HadithLoadMoreControls(label: "hadith matches", hasMore: matches.hasMore, limit: $hadithMatchLimit)

                        if matches.shown.isEmpty {
                            Text("No hadiths found.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    // The Quran ayah list's shape: each hadith is its own Section, with a Previous/Next
                    // chapter pair at the top and bottom that swaps the chapter in place. The chapter's
                    // identity is the pinned header above; rows report visibility for its progress bar.
                    if previousChapter != nil || nextChapter != nil {
                        Section { chapterNavButtonPair() }
                    }

                    ForEach(allChapterHadiths) { hadith in
                        Section {
                            HadithRow(book: book, hadith: hadith, searchText: searchText)
                                // The ayah list's tap-to-mark: a grey attention tint that keeps your
                                // place. The row's own controls (number pill, menu) win their taps.
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.secondary.opacity(highlightedHadithID == hadith.idInBook ? 0.18 : 0))
                                )
                                .padding(-6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        highlightedHadithID = highlightedHadithID == hadith.idInBook ? nil : hadith.idInBook
                                    }
                                }
                                .id("chapter-hadith-\(hadith.idInBook)")
                                .onAppear { visibleHadithIDs.insert(hadith.idInBook) }
                                .onDisappear { visibleHadithIDs.remove(hadith.idInBook) }
                        }
                    }

                    if previousChapter != nil || nextChapter != nil {
                        Section { chapterNavButtonPair() }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
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
        // Always-pinned header (safeAreaInset, not overlay), the surah reader's exact shape: it
        // reserves space so list content sits below it instead of hiding behind it, with the
        // progress bar full-width directly beneath the toolbar.
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                if let barFraction = hadithProgressFraction {
                    TrackedBar(
                        fraction: barFraction,
                        height: 3,
                        color: settings.accentColor.color
                    )
                    .transition(.opacity)
                }

                floatingChapterHeader
            }
        }
        .onChange(of: searchText) { _ in
            // A new query starts back at the first page of matches.
            hadithMatchLimit = 5
        }
        .onChange(of: chapterIndex) { _ in
            // A Previous/Next chapter swap lands at the top of the new chapter.
            guard let first = allChapterHadiths.first?.idInBook else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { scrollProxy.scrollTo("chapter-hadith-\(first)", anchor: .top) }
            }
        }
        // Apple Music-style: the bottom search bar minimizes while scrolling down.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: $searchText)
                .padding([.horizontal, .top], -8)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .background(Color.white.opacity(0.00001))
                .minimizedBarStyle(barsCollapsed)
        }
        }
    }

    /// How far the top-visible hadith is through the chapter - the surah reader's ayah progress,
    /// by hadith. Fills continuously as you scroll; full only once the last hadith is on screen.
    private var hadithProgressFraction: CGFloat? {
        guard !isSearchActive,
              let firstID = allChapterHadiths.first?.idInBook,
              let lastID = allChapterHadiths.last?.idInBook,
              lastID > firstID else { return nil }
        if visibleHadithIDs.contains(lastID) { return 1 }
        guard let current = visibleHadithIDs.min() else { return 0 }
        // Never quite full while scrolling: cap below 1 so 100% is reserved for the chapter's end.
        return min(CGFloat(current - firstID) / CGFloat(lastID - firstID), 0.97)
    }

    /// The chapter's identity: its name in English and Arabic on the leading side; the count pill
    /// with the span of hadith numbers beneath it on the trailing side. Pinned above the list as a
    /// glass bar, the surah reader's pinned-header way.
    private var floatingChapterHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text((chapter.english.isEmpty ? book.englishTitle : chapter.english).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                if !chapter.arabic.isEmpty {
                    Text(chapter.arabic)
                        .font(settings.useFontArabic
                              ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2)
                              : .caption)
                        .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                CountPill(count: allChapterHadiths.count)

                if let range = chapterRange {
                    Text(range.lowerBound == range.upperBound
                         ? "HADITH \(range.lowerBound)"
                         : "HADITHS \(range.lowerBound)-\(range.upperBound)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 0)
        .conditionalGlassEffect(rectangle: true)
        .padding(.top, 4)
        .padding(.horizontal, settings.defaultView ? 20 : 16)
        .zIndex(1)
    }

    /// Previous | Next chapter, side by side - the surah reader's navigation pair, by chapter. Each
    /// swaps the chapter in place rather than pushing a new view.
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

    let book: HadithCatalogBook
    let bookData: HadithBookData

    @State var chapterIndex: Int
    @State private var pageIndex = 0
    /// The mushaf's "Fit Page to Screen": an overflowing page's text shrinks just enough to fit;
    /// off reads at exactly the chosen sizes and the page scrolls.
    @AppStorage("hadithFitPage") private var hadithFitPage = true

    /// One built page: its elements, and the font scale that makes an overflowing page fit the
    /// screen when Fit Page is on (1 everywhere else - only a page that can't fit at full size,
    /// typically a single very long hadith, ever shrinks).
    private struct BuiltPage {
        let elements: [PageElement]
        let scale: CGFloat
    }

    private enum PageElement: Identifiable {
        case heading(HadithBookData.Chapter)
        case hadith(HadithBookData.Hadith)

        var id: String {
            switch self {
            case .heading(let chapter): return "heading-\(chapter.id)"
            case .hadith(let hadith): return "hadith-\(hadith.id)"
            }
        }
    }

    private var chapter: HadithBookData.Chapter? {
        bookData.chapters.indices.contains(chapterIndex) ? bookData.chapters[chapterIndex] : nil
    }

    private var chapterHadiths: [HadithBookData.Hadith] {
        guard let chapter else { return [] }
        return bookData.hadiths.filter { $0.chapterId == chapter.id }
    }

    // MARK: Measurement

    private func measuredHeight(of text: String, font: UIFont, width: CGFloat, lineSpacing: CGFloat = 0) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: style],
            context: nil
        )
        return ceil(rect.height)
    }

    /// Estimated on-screen height of one hadith block, mirroring `HadithRow`'s fonts and spacings (with
    /// a little slack - the page also scrolls, so a slight under-estimate can never hide text).
    private func height(of hadith: HadithBookData.Hadith, width: CGFloat) -> CGFloat {
        var total: CGFloat = 28 + 10 + 8   // number badge row + stack spacing + row padding

        if settings.showHadithArabic, !hadith.arabic.isEmpty {
            let arabicFont = UIFont(name: settings.nonQuranArabicFontName, size: settings.hadithArabicFontSize)
                ?? .roundedSystemFont(ofSize: settings.hadithArabicFontSize)
            total += measuredHeight(of: hadith.arabic, font: arabicFont, width: width, lineSpacing: 6) + 10
        }
        if settings.showHadithEnglish {
            let englishFont = UIFont.roundedSystemFont(ofSize: settings.hadithEnglishFontSize)
            if settings.showHadithNarrator, !hadith.english.narrator.isEmpty {
                total += measuredHeight(of: hadith.english.narrator, font: englishFont, width: width) + 10
            }
            if !hadith.english.text.isEmpty {
                total += measuredHeight(of: hadith.english.text, font: englishFont, width: width) + 10
            }
        }
        return total * 1.06
    }

    private func headingHeight(_ chapter: HadithBookData.Chapter, width: CGFloat) -> CGFloat {
        var total: CGFloat = 12
        total += measuredHeight(of: chapter.english, font: .roundedSystemFont(ofSize: 15, weight: .semibold), width: width)
        if !chapter.arabic.isEmpty {
            let arabicFont = UIFont(name: settings.nonQuranArabicFontName, size: 15) ?? .roundedSystemFont(ofSize: 15)
            total += measuredHeight(of: chapter.arabic, font: arabicFont, width: width) + 4
        }
        return total * 1.06
    }

    /// Packs the chapter into pages: fill until the height budget runs out, never orphan the heading,
    /// keep every hadith whole. Re-runs whenever the fonts or display toggles change (it is a pure
    /// function of its inputs), which is what makes the per-page count adapt to the font sizes.
    private func paginate(size: CGSize) -> [BuiltPage] {
        let width = max(size.width - 40, 1)
        let budget = max(size.height - 24, 200)
        let hadiths = chapterHadiths
        guard !hadiths.isEmpty else { return [] }

        var elements: [PageElement] = []
        if let chapter { elements.append(.heading(chapter)) }
        elements.append(contentsOf: hadiths.map { .hadith($0) })

        // Fit Page's shrink, the mushaf setting's twin: a page whose content can't fit even alone
        // (a single very long hadith) scales down toward the screen - never below a legible floor,
        // and never at all when the setting is off (the page scrolls instead).
        func built(_ elements: [PageElement], used: CGFloat) -> BuiltPage {
            let scale = (hadithFitPage && used > budget) ? max(budget / used, 0.6) : 1
            return BuiltPage(elements: elements, scale: scale)
        }

        var pages: [BuiltPage] = []
        var current: [PageElement] = []
        var used: CGFloat = 0
        let spacing: CGFloat = 16

        for element in elements {
            let h: CGFloat
            switch element {
            case .heading(let chapter): h = headingHeight(chapter, width: width)
            case .hadith(let hadith): h = height(of: hadith, width: width)
            }

            let needed = (current.isEmpty ? 0 : spacing) + h
            if !current.isEmpty, used + needed > budget {
                // Never leave a heading stranded as the page's last line - it moves with what follows.
                if case .heading = current.last {
                    let heading = current.removeLast()
                    if !current.isEmpty { pages.append(built(current, used: used)) }
                    current = [heading]
                    used = headingHeight(chapter!, width: width)
                } else {
                    pages.append(built(current, used: used))
                    current = []
                    used = 0
                }
                current.append(element)
                used += h
            } else {
                current.append(element)
                used += needed
            }
        }
        if !current.isEmpty { pages.append(built(current, used: used)) }
        return pages
    }

    var body: some View {
        GeometryReader { geo in
            let pages = paginate(size: geo.size)

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
                            pageBody(pages[index].elements, scale: pages[index].scale)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .safeAreaInset(edge: .bottom) {
                pagerFooter(pageCount: pages.count, hadithCount: chapterHadiths.count)
            }
        }
        .navigationTitle(chapter?.english.isEmpty == false ? (chapter?.english ?? "") : book.englishTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: chapterIndex) { _ in
            pageIndex = 0
        }
        .onChange(of: pageIndex) { _ in
            recordPageLastRead()
        }
        .onAppear {
            recordPageLastRead()
        }
    }

    /// The page's first hadith becomes the Last Read - the paged equivalent of opening a detail.
    private func recordPageLastRead() {
        guard let first = chapterHadiths.first else { return }
        HadithStore.shared.recordLastRead(book: book, hadith: first)
    }

    private func pageBody(_ elements: [PageElement], scale: CGFloat = 1) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(elements) { element in
                    switch element {
                    case .heading(let chapter):
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chapter.english)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(settings.accentColor.color)

                            if !chapter.arabic.isEmpty {
                                Text(chapter.arabic)
                                    .font(settings.useFontArabic
                                          ? Font.arabic(settings.nonQuranArabicFontName, size: 15)
                                          : .subheadline)
                                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }

                    case .hadith(let hadith):
                        HadithRow(book: book, hadith: hadith, fontScale: scale)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func pagerFooter(pageCount: Int, hadithCount: Int) -> some View {
        VStack(spacing: 6) {
            TrackedBar(
                fraction: pageCount > 1 ? CGFloat(pageIndex) / CGFloat(pageCount - 1) : 1,
                height: 3,
                color: settings.accentColor.color
            )
            .padding(.horizontal, 2)

            HStack(spacing: 12) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { chapterIndex = max(0, chapterIndex - 1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .contentShape(Rectangle())
                }
                .disabled(chapterIndex == 0)

                VStack(spacing: 1) {
                    Text("Chapter \(chapterIndex + 1)/\(bookData.chapters.count)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()

                    Text(pageCount > 0 ? "Page \(pageIndex + 1)/\(pageCount) - \(hadithCount) hadiths" : "-")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { chapterIndex = min(bookData.chapters.count - 1, chapterIndex + 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .contentShape(Rectangle())
                }
                .disabled(chapterIndex >= bookData.chapters.count - 1)
            }
            .foregroundColor(settings.accentColor.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

#endif
