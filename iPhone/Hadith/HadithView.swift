import SwiftUI

// The Hadith tab root: summary tiles, Hadith of the Day, bookmarks, favorites, the catalog by group,
// reference lookups, and all-books search. Every collection downloads from the hadith-json CDN on
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
    @ObservedObject private var store = HadithStore.shared

    @State private var searchText = ""
    @State private var confirmDownloadAll = false
    @State private var confirmDeleteAll = false
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
    @State private var globalHasMoreChapters = false
    @State private var globalHasMoreHadiths = false
    @State private var globalChapterLimit = 5
    @State private var globalHadithLimit = 5
    @State private var isGlobalSearching = false
    @State private var globalSearchRanFor = ""
    @State private var globalSearchTask: Task<Void, Never>?

    /// Today's hadith lives in the STORE, resolved at app launch from the downloaded books - the tab
    /// renders it instantly.
    private var dailyHadith: (book: HadithCatalogBook, hadith: HadithBookData.Hadith)? { store.daily }
    /// Whether the daily section's history (last 5 days) is unfolded - the shuffle only shows here.
    @State private var showDailyHistory = false
    /// Compact "summary mode": Hadith of the Day + Last Read as tiles, like the Quran tab. On by default.
    @AppStorage("hadithSummaryMode") private var hadithSummaryMode = true
    /// A hidden push target (shuffled bookmark, summary tiles) - HadithReferenceView by slug+number.
    @State private var pushedReference: HadithBookmark? = nil

    private func matches(_ book: HadithCatalogBook) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return book.englishTitle.localizedCaseInsensitiveContains(query) ||
            book.arabicTitle.localizedCaseInsensitiveContains(query) ||
            settings.cleanSearch(book.arabicTitle, whitespace: true).localizedCaseInsensitiveContains(settings.cleanSearch(query, whitespace: true))
    }

    private func filteredBooks(in group: HadithCatalogBook.Group) -> [HadithCatalogBook] {
        HadithCatalogBook.books(in: group).filter(matches)
    }

    private var filteredFavorites: [HadithCatalogBook] {
        HadithCatalogBook.all.filter { store.isFavorite($0.slug) && matches($0) }
    }

    private var referenceResult: HadithReferenceParser.Reference? {
        HadithReferenceParser.parse(searchText)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { scrollProxy in
            List {
                Group {
                    if searchText.isEmpty {
                        // With no downloaded books there is no Hadith of the Day, and before any reading
                        // there is no Last Read either - an empty "Your Summary" header is just noise.
                        if hadithSummaryMode {
                            if dailyHadith != nil || store.lastRead != nil {
                                summaryTilesSection
                            }
                        } else {
                            hadithOfTheDaySection
                            lastReadSection
                        }
                    }

                    if store.isDownloading {
                        downloadProgressSection
                    }

                    if let error = store.downloadError {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    if let reference = referenceResult {
                        referenceSection(reference)
                    }

                    if !searchText.isEmpty {
                        // The Quran search's order: matching books first, then chapters, then hadiths.
                        let results = HadithCatalogBook.all.filter(matches)
                        if !results.isEmpty {
                            bookSection(title: "MATCHING BOOKS", books: results, shuffle: false)
                        }
                    }

                    globalSearchSection

                    if !store.bookmarks.isEmpty && searchText.isEmpty {
                        bookmarksSection
                    }

                    if searchText.isEmpty {
                        let favorites = filteredFavorites
                        if !favorites.isEmpty {
                            bookSection(
                                title: "FAVORITE BOOKS",
                                books: favorites,
                                icon: "star.fill",
                                accentTitle: true,
                                isExpanded: $showFavoriteBooks
                            )
                        }

                        ForEach(HadithCatalogBook.Group.allCases, id: \.self) { group in
                            let books = filteredBooks(in: group)
                            if !books.isEmpty {
                                bookSection(title: group.rawValue, books: books)
                            }
                        }
                    }

                    if searchText.isEmpty {
                        aboutHadithSection
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .compactListSectionSpacing()
            // The grid/list flip animates the whole catalog, same as the Quran tab.
            .animation(.easeInOut, value: hadithGridMode)
            // The invisible link the grid tiles push through (list rows use real NavigationLinks).
            .background(
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
                .opacity(0)
            )
            // And the one the shuffled bookmark / summary tiles / daily history push through.
            .background(
                NavigationLink(isActive: Binding(
                    get: { pushedReference != nil },
                    set: { if !$0 { pushedReference = nil } }
                )) {
                    if let pushedReference, let book = HadithCatalogBook.bySlug[pushedReference.slug] {
                        HadithReferenceView(book: book, chapter: nil, hadith: pushedReference.idInBook)
                    }
                } label: {
                    EmptyView()
                }
                .opacity(0)
            )
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
            .navigationTitle("Hadith")
            .toolbar {
                // Download management on the LEFT.
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Text("Offline Books")
                            .foregroundStyle(.secondary)

                        Button {
                            settings.hapticFeedback()
                            confirmDownloadAll = true
                        } label: {
                            Label("Download All Books", systemImage: "icloud.and.arrow.down")
                        }
                        .disabled(store.isDownloading)

                        if !store.downloadedSlugs.isEmpty {
                            Button(role: .destructive) {
                                settings.hapticFeedback()
                                confirmDeleteAll = true
                            } label: {
                                Label("Delete All Downloads", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "icloud.and.arrow.down")
                    }
                    .tint(settings.accentColor.accent1)
                }

            }
            // Trailing buttons live in their own modifier so iOS 26 can interleave ToolbarSpacers
            // between them - without spacers, Liquid Glass merges them into ONE capsule (the same
            // treatment the Quran tab's trailing toolbar has).
            .modifier(HadithTrailingToolbar(
                hadithGridMode: $hadithGridMode,
                showHadithSettings: $showHadithSettings
            ))
            .sheet(isPresented: $showHadithSettings) {
                HadithSettingsSheet()
                    .smallMediumSheetPresentation()
            }
            .confirmationDialog("Download All Books?", isPresented: $confirmDownloadAll, titleVisibility: .visible) {
                Button("Download (~\(HadithCatalogBook.totalMegabytes) MB)") {
                    settings.hapticFeedback()
                    store.startDownloadAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This downloads every hadith collection for offline reading. It may use significant data - Wi-Fi is recommended. Already-downloaded books are skipped.")
            }
            .confirmationDialog("Delete all downloaded books?", isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    settings.hapticFeedback()
                    store.deleteAllDownloads()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Books will be re-downloaded as you open them.")
            }
            .onAppear {
                store.refreshDiskState()
                store.loadLastRead()
            }
            .task {
                // Usually a no-op: the pick was resolved at app launch. This just covers day rollover
                // while the app stays open.
                store.prepareDailyHadith()
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
                let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if query.count >= 3, HadithReferenceParser.parse(text) == nil {
                    runGlobalSearch(query: query)
                }
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
        .navigationViewStyle(.stack)
    }

    // MARK: Hadith of the Day (engine lives in HadithStore; resolved before this tab opens)

    private var dailyHistory: [HadithStore.DailyHadithEntry] { HadithStore.loadDailyHistory() }

    @ViewBuilder
    private var hadithOfTheDaySection: some View {
        if let dailyHadith {
            Section {
                HadithRow(book: dailyHadith.book, hadith: dailyHadith.hadith)

                if showDailyHistory {
                    // The last 5 days, timestamped and dimmed - today first. The Today row carries the
                    // shuffle (a genuinely random pick from any collection on this device).
                    ForEach(Array(dailyHistory.enumerated()), id: \.element.dayKey) { index, entry in
                        dailyHistoryRow(entry, isToday: index == 0)
                            .opacity(index == 0 ? 1 : 0.75)
                    }
                }
            } header: {
                HStack {
                    Text("HADITH OF THE DAY")

                    Spacer()

                    Image(systemName: showDailyHistory ? "minus.circle" : "plus.circle")
                        .foregroundColor(settings.accentColor.color)
                        .padding(4)
                        .conditionalGlassEffect()
                        .onTapGesture {
                            settings.hapticFeedback()
                            withAnimation { showDailyHistory.toggle() }
                        }
                        .accessibilityLabel("Show recent hadiths of the day")
                }
            }
        }
    }

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
                    HStack {
                        Text(entry.reference)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)

                        Spacer(minLength: 8)

                        historyTimestampLabel(entry.date)
                    }

                    if !entry.arabicPreview.isEmpty {
                        HadithArabicPreview(text: entry.arabicPreview)
                    }

                    if !entry.englishPreview.isEmpty {
                        Text(entry.englishPreview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
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
                        reference: "\(dailyHadith.book.englishTitle) \(dailyHadith.hadith.idInBook)",
                        arabic: String(dailyHadith.hadith.arabic.prefix(120)),
                        english: String(dailyHadith.hadith.english.text.prefix(140))
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
                        arabic: lastRead.arabicPreview,
                        english: lastRead.englishPreview
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
                }

                Text(reference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if !arabic.isEmpty {
                    HadithArabicPreview(text: arabic)
                }

                if !english.isEmpty {
                    Text(english)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(12)
            .conditionalGlassEffect(clear: true, rectangle: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Last Read Hadith, full-row form (summary mode off) - the Quran's Last Read Ayah counterpart.
    @ViewBuilder
    private var lastReadSection: some View {
        if let lastRead = store.lastRead {
            Section(header: Text("LAST READ HADITH")) {
                Button {
                    settings.hapticFeedback()
                    pushedReference = HadithBookmark(
                        slug: lastRead.slug, idInBook: lastRead.idInBook,
                        reference: lastRead.reference, preview: ""
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(lastRead.reference)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)

                            Spacer(minLength: 8)

                            historyTimestampLabel(lastRead.timestamp)
                        }

                        if !lastRead.arabicPreview.isEmpty {
                            HadithArabicPreview(text: lastRead.arabicPreview)
                        }

                        if !lastRead.englishPreview.isEmpty {
                            Text(lastRead.englishPreview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
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

    private var downloadProgressSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(store.downloadingBookTitle)
                    .font(.subheadline.weight(.semibold))

                ProgressView(
                    value: Double(store.downloadCompletedBooks),
                    total: Double(max(store.downloadTotalBooks, 1))
                )

                Text("\(store.downloadCompletedBooks) of \(store.downloadTotalBooks) books")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()

                Button(role: .destructive) {
                    settings.hapticFeedback()
                    store.cancelDownload()
                } label: {
                    Text("Cancel Download")
                        .font(.subheadline)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: Reference lookup

    private func referenceSection(_ reference: HadithReferenceParser.Reference) -> some View {
        Section(header: Text("GO TO REFERENCE")) {
            NavigationLink {
                HadithReferenceView(book: reference.book, chapter: reference.chapter, hadith: reference.hadith)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "number")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(reference.chapter.map { "\(reference.book.englishTitle) - Chapter \($0), Hadith \(reference.hadith)" }
                             ?? "\(reference.book.englishTitle) - Hadith \(reference.hadith)")
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

    // MARK: All-books search

    @ViewBuilder
    private var globalSearchSection: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.count >= 3, referenceResult == nil {
            if isGlobalSearching && globalChapterResults.isEmpty && globalHadithResults.isEmpty {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Searching downloaded books...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

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
                            runGlobalSearch(query: query)
                        }
                    ))
                }
            }

            if !globalHadithResults.isEmpty {
                Section(header: SectionPillHeader(title: "MATCHING HADITHS", count: globalHadithResults.count, overflow: globalHasMoreHadiths)) {
                    ForEach(globalHadithResults) { hit in
                        NavigationLink {
                            // Land in the chapter, scrolled to the hadith - the Quran search's arrival.
                            if let chapter = hit.data.chapters.first(where: { $0.id == hit.hadith.chapterId }) {
                                HadithChapterView(book: hit.book, bookData: hit.data, chapter: chapter, scrollToHadithId: hit.hadith.idInBook)
                            } else {
                                HadithReferenceView(book: hit.book, chapter: nil, hadith: hit.hadith.idInBook)
                            }
                        } label: {
                            HadithRow(book: hit.book, hadith: hit.hadith, searchText: searchText, compact: true)
                        }
                    }

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
                Section(footer: Text("Searches every downloaded book. Books not downloaded yet are skipped.")) {
                    Text("No chapter or hadith matches in the downloaded books.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// A matched chapter from any downloaded book: chapter name over the book it belongs to, the
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
                        lineLimit: 1,
                        basicFontForCommas: settings.useFontArabic ? UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2 : nil
                    )
                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                    .minimumScaleFactor(0.6)
                }
            }
        }
        .padding(.vertical, 2)
    }

    /// The automatic all-books sweep: debounced, script-aware, early-exiting at one past each page,
    /// and served from the store's preprocessed indexes wherever they're ready.
    private func runGlobalSearch(query: String) {
        globalSearchTask?.cancel()
        isGlobalSearching = true

        let chapterCap = globalChapterLimit
        let hadithCap = globalHadithLimit
        let arabicQuery = query.containsArabicScript
        let cleanQuery = arabicQuery ? settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns : ""
        let lowerQuery = query.lowercased()

        globalSearchTask = Task {
            // Debounce: typing restarts this task, so only a settled query pays for the sweep.
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            var chapterHits: [GlobalChapterHit] = []
            var hadithHits: [GlobalHadithHit] = []

            for book in HadithCatalogBook.all where HadithStore.shared.isAvailableOffline(book) {
                if Task.isCancelled { return }
                if chapterHits.count > chapterCap, hadithHits.count > hadithCap { break }
                guard let data = try? await HadithStore.shared.book(book) else { continue }

                if chapterHits.count <= chapterCap {
                    for chapter in data.chapters {
                        let matched: Bool
                        if arabicQuery {
                            matched = settings.cleanSearch(chapter.arabic, whitespace: true).removingArabicDiacriticsAndSigns.contains(cleanQuery)
                        } else {
                            matched = chapter.english.localizedCaseInsensitiveContains(query)
                        }
                        if matched {
                            chapterHits.append(GlobalChapterHit(book: book, data: data, chapter: chapter))
                            if chapterHits.count > chapterCap { break }
                        }
                    }
                }

                if hadithHits.count <= hadithCap {
                    let index = HadithStore.shared.searchIndexes[book.slug]
                    let needed = hadithCap + 1 - hadithHits.count
                    // Scan off-main: Bukhari alone is ~7,500 hadiths of long text.
                    let matched = await Task.detached(priority: .userInitiated) { () -> [HadithBookData.Hadith] in
                        var found: [HadithBookData.Hadith] = []
                        for hadith in data.hadiths {
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
                                found.append(hadith)
                                if found.count >= needed { break }
                            }
                        }
                        return found
                    }.value
                    for hadith in matched {
                        hadithHits.append(GlobalHadithHit(book: book, data: data, hadith: hadith))
                    }
                }
            }

            guard !Task.isCancelled else { return }
            let finalChapters = chapterHits
            let finalHadiths = hadithHits
            await MainActor.run {
                guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                globalChapterResults = Array(finalChapters.prefix(chapterCap))
                globalHadithResults = Array(finalHadiths.prefix(hadithCap))
                globalHasMoreChapters = finalChapters.count > chapterCap
                globalHasMoreHadiths = finalHadiths.count > hadithCap
                globalSearchRanFor = query
                isGlobalSearching = false
            }
        }
    }

    // MARK: Bookmarks

    private var bookmarksSection: some View {
        Section(header: SectionPillHeader(
            title: "BOOKMARKED HADITHS",
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
                // The first five, Quran-bookmark style; the full list lives one push away. In grid mode
                // they render as tiles, like the Quran's bookmark grid.
                if hadithGridMode {
                    LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
                        ForEach(store.bookmarks.prefix(5)) { bookmark in
                            HadithBookmarkGridTile(bookmark: bookmark) {
                                pushedReference = bookmark
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(store.bookmarks.prefix(5)) { bookmark in
                        HadithBookmarkRow(bookmark: bookmark)
                    }
                }

                if store.bookmarks.count > 5 {
                    NavigationLink {
                        HadithBookmarksListView()
                    } label: {
                        Label("View All (\(store.bookmarks.count))", systemImage: "bookmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
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
        Section(header: header) {
            if isExpanded?.wrappedValue ?? true {
                if hadithGridMode {
                    LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
                        ForEach(books) { book in
                            bookGridTile(book)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(books) { book in
                        NavigationLink {
                            HadithBookView(book: book)
                        } label: {
                            bookRow(book)
                        }
                        .contextMenu { bookContextMenu(book) }
                        // The surah rows' swipe language: icon-only. Favorite on the leading edge;
                        // scroll-to (and freeing a download) on the trailing edge.
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
                            if store.downloadedSlugs.contains(book.slug) {
                                Button(role: .destructive) {
                                    settings.hapticFeedback()
                                    store.deleteDownload(book)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }

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

        if store.downloadedSlugs.contains(book.slug) {
            Button(role: .destructive) {
                settings.hapticFeedback()
                store.deleteDownload(book)
            } label: {
                Label("Remove Download", systemImage: "trash")
            }
        }
    }

    /// Sharing a BOOK sends its identity and story, not megabytes of text.
    private func bookShareText(_ book: HadithCatalogBook) -> String {
        "\(book.englishTitle) (\(book.arabicTitle))\n\n\(book.authorEnglish) - \(book.era)\n\n\(book.longDescription)"
    }

    /// "13 MB" - always shown, downloaded or not (the offline icon carries the downloaded state).
    /// Same format as the book view's own size pill, so the two read as one system.
    private func bookSizeText(_ book: HadithCatalogBook) -> String {
        book.approximateMegabytes < 1 ? "<1 MB" : "\(String(format: "%.0f", book.approximateMegabytes)) MB"
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
                .accessibilityLabel("Book \(book.number)")

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

    /// The size as a small glass chip - the same pill language the book view's stats use.
    private func bookSizePill(_ book: HadithCatalogBook) -> some View {
        Text(bookSizeText(book))
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(settings.accentColor.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .conditionalGlassEffect()
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

                bookSizePill(book)
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

                if store.isAvailableOffline(book) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(settings.accentColor.color)
                }
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

                    Text("• \(bookSizeText(book))")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if store.isAvailableOffline(book) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(settings.accentColor.color)
                    }
                }
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
