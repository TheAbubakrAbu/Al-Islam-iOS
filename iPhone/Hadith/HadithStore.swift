import SwiftUI

// Disk + memory cache over the hadith-json CDN (bundle-shipped books load straight from the app),
// plus downloads, favorites, bookmarks, last-read, and the Hadith of the Day engine.

#if os(iOS)

// MARK: - User collections (favorites, bookmarks, notes)

/// The reader's own marks - favorite books/chapters, bookmarks, and their notes - split OUT of
/// HadithStore's `objectWillChange`: the store publishes constantly during bulk downloads and the
/// launch prewarm (per-book decode ticks), and every row observing it just for bookmark state
/// re-rendered on each tick. This object publishes only on actual user edits, so the rows that
/// render marks observe THIS instead. HadithStore forwards its old accessor API here, which keeps
/// call sites unchanged - but note the forwards do NOT publish: any view that RENDERS this state
/// must observe `HadithUserData.shared` itself.
@MainActor
final class HadithUserData: ObservableObject {
    static let shared = HadithUserData()

    private static let favoritesKey = "hadithFavoriteBooks"
    private static let chapterFavoritesKey = "hadithFavoriteChapters"
    private static let bookmarksKey = "hadithBookmarks"

    private init() {
        favoriteSlugs = Set(UserDefaults.standard.stringArray(forKey: Self.favoritesKey) ?? [])
        favoriteChapterKeys = Set(UserDefaults.standard.stringArray(forKey: Self.chapterFavoritesKey) ?? [])
        if let data = UserDefaults.standard.data(forKey: Self.bookmarksKey),
           let decoded = try? JSONDecoder().decode([HadithBookmark].self, from: data) {
            bookmarks = decoded
            // didSet does not fire inside init - seed the lookup index by hand.
            bookmarksByKey = Dictionary(
                decoded.map { ("\($0.slug)|\($0.idInBook)", $0) },
                uniquingKeysWith: { first, _ in first }
            )
        }
    }

    /// Favorited book slugs, pinned to the top of the catalog. Persisted in UserDefaults.
    @Published private(set) var favoriteSlugs: Set<String> = []

    /// Favorited chapters, keyed "slug|chapterId" - the chapter rows' counterpart to book favorites.
    @Published private(set) var favoriteChapterKeys: Set<String> = []

    /// Bookmarked individual hadiths, newest first. Each carries enough text to render its row without
    /// loading the (large) book it came from. Persisted in UserDefaults.
    @Published private(set) var bookmarks: [HadithBookmark] = [] {
        didSet {
            bookmarksByKey = Dictionary(
                bookmarks.map { ("\($0.slug)|\($0.idInBook)", $0) },
                uniquingKeysWith: { first, _ in first }
            )
        }
    }

    /// O(1) bookmark/note lookups. `isBookmarked`/`note` run per visible row per body pass (and 4x in
    /// the paged reader's header), so linear scans over `bookmarks` degraded with every saved
    /// bookmark. Rebuilt on the rare mutations instead.
    private var bookmarksByKey: [String: HadithBookmark] = [:]

    // MARK: Favorites

    func isFavorite(_ slug: String) -> Bool { favoriteSlugs.contains(slug) }

    func toggleFavorite(_ slug: String) {
        if favoriteSlugs.contains(slug) {
            favoriteSlugs.remove(slug)
        } else {
            favoriteSlugs.insert(slug)
        }
        UserDefaults.standard.set(Array(favoriteSlugs), forKey: Self.favoritesKey)
    }

    func isChapterFavorite(slug: String, chapterId: Int) -> Bool {
        favoriteChapterKeys.contains("\(slug)|\(chapterId)")
    }

    func toggleChapterFavorite(slug: String, chapterId: Int) {
        let key = "\(slug)|\(chapterId)"
        if favoriteChapterKeys.contains(key) {
            favoriteChapterKeys.remove(key)
        } else {
            favoriteChapterKeys.insert(key)
        }
        UserDefaults.standard.set(Array(favoriteChapterKeys), forKey: Self.chapterFavoritesKey)
    }

    // MARK: Bookmarks

    func isBookmarked(slug: String, idInBook: Int) -> Bool {
        bookmarksByKey["\(slug)|\(idInBook)"] != nil
    }

    func toggleBookmark(book: HadithCatalogBook, hadith: HadithBookData.Hadith) {
        if let index = bookmarks.firstIndex(where: { $0.slug == book.slug && $0.idInBook == hadith.idInBook }) {
            bookmarks.remove(at: index)
        } else {
            let preview = hadith.english.text.isEmpty ? hadith.arabic : hadith.english.text
            bookmarks.insert(
                HadithBookmark(
                    slug: book.slug,
                    idInBook: hadith.idInBook,
                    reference: "\(book.englishTitle) \(hadith.idInBook)",
                    preview: String(preview.prefix(140)),
                    chapterId: hadith.chapterId,
                    arabicPreview: String(hadith.arabic.prefix(120)),
                    englishPreview: String(hadith.english.text.prefix(140))
                ),
                at: 0
            )
        }
        persistBookmarks()
    }

    // MARK: Notes (the bookmarked-ayah rule: a note lives on a bookmark)

    func note(slug: String, idInBook: Int) -> String? {
        let note = bookmarksByKey["\(slug)|\(idInBook)"]?.note
        return (note?.isEmpty ?? true) ? nil : note
    }

    /// Attach/replace the note on this hadith's bookmark - bookmarking it first when needed, exactly like
    /// notes on ayahs. An empty note clears it (the bookmark itself stays).
    func setNote(book: HadithCatalogBook, hadith: HadithBookData.Hadith, note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if bookmarks.firstIndex(where: { $0.slug == book.slug && $0.idInBook == hadith.idInBook }) == nil {
            toggleBookmark(book: book, hadith: hadith)
        }
        guard let index = bookmarks.firstIndex(where: { $0.slug == book.slug && $0.idInBook == hadith.idInBook }) else { return }
        bookmarks[index].note = trimmed.isEmpty ? nil : trimmed
        persistBookmarks()
    }

    func removeNote(slug: String, idInBook: Int) {
        guard let index = bookmarks.firstIndex(where: { $0.slug == slug && $0.idInBook == idInBook }) else { return }
        bookmarks[index].note = nil
        persistBookmarks()
    }

    private func persistBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: Self.bookmarksKey)
        }
    }
}

// MARK: - Store

/// Disk + memory cache over the hadith-json CDN (with the forties served straight from the app bundle),
/// plus bulk download, favorite books, and per-hadith bookmarks.
@MainActor
final class HadithStore: ObservableObject {
    static let shared = HadithStore()

    private init() {}

    // Download progress, published for the catalog UI.
    @Published private(set) var isDownloading = false
    @Published private(set) var downloadingBookTitle = ""
    @Published private(set) var downloadCompletedBooks = 0
    @Published private(set) var downloadTotalBooks = 0
    @Published var downloadError: String?
    /// Slugs with a file on disk, so rows can show their downloaded state (bundled books are always offline).
    @Published private(set) var downloadedSlugs: Set<String> = []
    @Published private(set) var diskUsageBytes: Int64 = 0

    /// Decoded books kept in memory, newest last (tiny LRU - Bukhari decoded is large).
    private var decoded: [(slug: String, book: HadithBookData)] = []

    /// Pre-normalized search text for a decoded book, built once off-main right after decode - the
    /// Quran search-snapshot discipline, so a keystroke never pays for per-hadith Arabic normalization.
    /// Keyed by the hadith's global `id`, so any subset (a chapter, a page of matches) can look up its
    /// rows without caring about positions.
    struct HadithSearchIndex {
        let arabicByID: [Int: String]
        let englishByID: [Int: String]
    }

    /// Ready indexes by slug. Published so a search view re-runs (and speeds up) the moment one lands.
    @Published private(set) var searchIndexes: [String: HadithSearchIndex] = [:]

    /// Everything about a book is preprocessed the moment it is decoded: the search normalization runs
    /// off-main over the whole text, and the finished index replaces per-keystroke normalization.
    private func buildSearchIndex(slug: String, book parsed: HadithBookData) {
        guard searchIndexes[slug] == nil else { return }
        Task.detached(priority: .utility) {
            var arabic: [Int: String] = Dictionary(minimumCapacity: parsed.hadiths.count)
            var english: [Int: String] = Dictionary(minimumCapacity: parsed.hadiths.count)
            for hadith in parsed.hadiths {
                arabic[hadith.id] = Settings.shared.cleanSearch(hadith.arabic, whitespace: true).removingArabicDiacriticsAndSigns
                english[hadith.id] = (hadith.english.text + "\n" + hadith.english.narrator).lowercased()
            }
            let index = HadithSearchIndex(arabicByID: arabic, englishByID: english)
            await MainActor.run { self.searchIndexes[slug] = index }
        }
    }
    private var downloadTask: Task<Void, Never>?

    // MARK: User collections (forwarded to HadithUserData)

    // Favorites/bookmarks/notes live in `HadithUserData` - their own publisher, so download/prewarm
    // ticks here no longer re-render every mark-showing row. These forwards keep the store's old API
    // for call sites; they read live data but do NOT publish - a view that RENDERS this state must
    // observe `HadithUserData.shared` itself.

    var bookmarks: [HadithBookmark] { HadithUserData.shared.bookmarks }

    func isFavorite(_ slug: String) -> Bool { HadithUserData.shared.isFavorite(slug) }

    func toggleFavorite(_ slug: String) { HadithUserData.shared.toggleFavorite(slug) }

    func isChapterFavorite(slug: String, chapterId: Int) -> Bool {
        HadithUserData.shared.isChapterFavorite(slug: slug, chapterId: chapterId)
    }

    func toggleChapterFavorite(slug: String, chapterId: Int) {
        HadithUserData.shared.toggleChapterFavorite(slug: slug, chapterId: chapterId)
    }

    func isBookmarked(slug: String, idInBook: Int) -> Bool {
        HadithUserData.shared.isBookmarked(slug: slug, idInBook: idInBook)
    }

    func toggleBookmark(book: HadithCatalogBook, hadith: HadithBookData.Hadith) {
        HadithUserData.shared.toggleBookmark(book: book, hadith: hadith)
    }

    func note(slug: String, idInBook: Int) -> String? {
        HadithUserData.shared.note(slug: slug, idInBook: idInBook)
    }

    func setNote(book: HadithCatalogBook, hadith: HadithBookData.Hadith, note: String) {
        HadithUserData.shared.setNote(book: book, hadith: hadith, note: note)
    }

    func removeNote(slug: String, idInBook: Int) {
        HadithUserData.shared.removeNote(slug: slug, idInBook: idInBook)
    }

    // MARK: Book shape (chapter / hadith counts)

    /// Live counts recorded whenever a book decodes, persisted so the catalog rows show a book's real
    /// shape across launches. The static catalog table seeds books never opened on this device.
    @Published private(set) var recordedCounts: [String: [Int]] = {
        (UserDefaults.standard.dictionary(forKey: "hadithBookCounts") as? [String: [Int]]) ?? [:]
    }()

    func recordCounts(slug: String, chapters: Int, hadiths: Int) {
        let value = [chapters, hadiths]
        guard recordedCounts[slug] != value else { return }
        recordedCounts[slug] = value
        UserDefaults.standard.set(recordedCounts, forKey: "hadithBookCounts")
    }

    /// The book's shape for display: live-recorded counts first, the catalog's measured table otherwise.
    func counts(for book: HadithCatalogBook) -> (chapters: Int, hadiths: Int)? {
        if let known = recordedCounts[book.slug], known.count == 2 {
            return (known[0], known[1])
        }
        if let chapters = book.chapterCount, let hadiths = book.hadithCount {
            return (chapters, hadiths)
        }
        return nil
    }

    // MARK: Last read

    /// Per-BOOK last-read hadiths, persisted: every book remembers its own spot (shown at the top of
    /// its screen), and the tab-level "Last Read" is simply the LATEST across all of them - the Quran's
    /// Last Read Ayah counterpart, per book.
    @Published private(set) var lastReadByBook: [String: HadithLastRead] = [:]

    private static let lastReadKey = "hadithLastRead"              // pre-4.7 single global entry (migrated)
    private static let lastReadByBookKey = "hadithLastReadByBook"

    /// The tab's Last Read: the most recent spot across every book.
    var lastRead: HadithLastRead? {
        lastReadByBook.values.max(by: { $0.timestamp < $1.timestamp })
    }

    /// The book's own remembered spot.
    func lastRead(for slug: String) -> HadithLastRead? {
        lastReadByBook[slug]
    }

    func loadLastRead() {
        guard lastReadByBook.isEmpty else { return }
        if let data = UserDefaults.standard.data(forKey: Self.lastReadByBookKey),
           let decoded = try? JSONDecoder().decode([String: HadithLastRead].self, from: data) {
            lastReadByBook = decoded
        }
        // Migrate the old single global entry into its book's slot (once - it then lives in the dict).
        if let data = UserDefaults.standard.data(forKey: Self.lastReadKey),
           let legacy = try? JSONDecoder().decode(HadithLastRead.self, from: data) {
            if lastReadByBook[legacy.slug] == nil {
                lastReadByBook[legacy.slug] = legacy
                persistLastRead()
            }
            UserDefaults.standard.removeObject(forKey: Self.lastReadKey)
        }
    }

    func recordLastRead(book: HadithCatalogBook, hadith: HadithBookData.Hadith) {
        let entry = HadithLastRead(
            slug: book.slug,
            idInBook: hadith.idInBook,
            reference: "\(book.englishTitle) \(hadith.idInBook)",
            arabicPreview: String(hadith.arabic.prefix(120)),
            englishPreview: String(hadith.english.text.prefix(140)),
            timestamp: Date(),
            chapterId: hadith.chapterId
        )
        lastReadByBook[book.slug] = entry
        persistLastRead()
    }

    private func persistLastRead() {
        if let data = try? JSONEncoder().encode(lastReadByBook) {
            UserDefaults.standard.set(data, forKey: Self.lastReadByBookKey)
        }
    }

    // MARK: Prewarm (instant book opens)

    private var didPrewarmBooks = false

    /// Decode EVERY book available offline - most recent last-reads first, then favorites, then the
    /// rest of the shelf (downloaded and bundled) - into the session cache at launch, so opening ANY
    /// of them is INSTANT instead of paying the JSON decode behind a spinner. Off-main, one book at a
    /// time in likelihood order, so the books you actually open first warm up first.
    func prewarmBooks() {
        guard !didPrewarmBooks else { return }
        didPrewarmBooks = true
        loadLastRead()

        var ordered: [String] = lastReadByBook.values
            .sorted { $0.timestamp > $1.timestamp }
            .map(\.slug)
        ordered += HadithUserData.shared.favoriteSlugs.sorted()
        ordered += HadithCatalogBook.all.map(\.slug)

        var seen = Set<String>()
        let targets = ordered
            .compactMap { HadithCatalogBook.bySlug[$0] }
            .filter { seen.insert($0.slug).inserted && isAvailableOffline($0) }
        guard !targets.isEmpty else { return }

        Task {
            for book in targets where cachedBook(book.slug) == nil {
                _ = try? await self.book(book)
            }
        }
    }

    // MARK: Fetching

    private nonisolated static let directory: URL = {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )) ?? FileManager.default.temporaryDirectory
        var dir = base.appendingPathComponent("HadithCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)
        return dir
    }()

    private nonisolated static func fileURL(_ book: HadithCatalogBook) -> URL {
        directory.appendingPathComponent("\(book.slug).json")
    }

    private nonisolated static func endpoint(_ book: HadithCatalogBook) -> URL? {
        URL(string: "https://cdn.jsdelivr.net/gh/AhmedBaset/hadith-json@main/db/by_book/\(book.folder)/\(book.slug).json")
    }

    /// The book's JSON inside the app bundle, if it ships there (loose or under JSONs/). Any book whose
    /// file exists in the bundle is treated as ALREADY AVAILABLE - no download flow, no storage cost -
    /// so bundling more collections (or building an all-bundled Hadith app) needs no code changes.
    nonisolated static func bundledURL(_ slug: String) -> URL? {
        // Catalog slugs come from the one-time probe table (hits AND misses - a not-bundled book must
        // not fall through to a live probe on every call). Bundle contents can't change at runtime.
        if let cached = bundledURLBySlug[slug] { return cached }
        return probeBundledURL(slug)
    }

    /// Every catalog slug probed ONCE. `Bundle.main.url` is a resource lookup (two of them per miss),
    /// and `isAvailableOffline` runs from body paths - per row in the catalog list.
    nonisolated private static let bundledURLBySlug: [String: URL?] = {
        var map: [String: URL?] = [:]
        for book in HadithCatalogBook.all {
            map[book.slug] = probeBundledURL(book.slug)
        }
        return map
    }()

    nonisolated private static func probeBundledURL(_ slug: String) -> URL? {
        Bundle.main.url(forResource: slug, withExtension: "json")
            ?? Bundle.main.url(forResource: slug, withExtension: "json", subdirectory: "JSONs")
    }

    /// True when this book can be read right now without the network: downloaded, or shipped in the
    /// app bundle itself.
    func isAvailableOffline(_ book: HadithCatalogBook) -> Bool {
        downloadedSlugs.contains(book.slug) || Self.bundledURL(book.slug) != nil
    }

    /// Bundled books never occupy cache storage and never show download UI.
    nonisolated static func isBundledResource(_ book: HadithCatalogBook) -> Bool {
        bundledURL(book.slug) != nil
    }

    /// The decoded book if it's already in the memory cache - synchronous, so an open of a recently-read
    /// book can render instantly instead of flashing the loading screen.
    func cachedBook(_ slug: String) -> HadithBookData? {
        decoded.first(where: { $0.slug == slug })?.book
    }

    /// Cache-first: memory (decoded), then disk, then the app bundle (forties), then network - decode
    /// always runs off-main. `persist: false` is the TEMPORARY read: the book is loaded into the small
    /// memory cache for this session and nothing is written to disk - it evaporates on its own instead
    /// of taking up storage.
    func book(_ book: HadithCatalogBook, persist: Bool = true) async throws -> HadithBookData {
        if let hit = decoded.first(where: { $0.slug == book.slug })?.book {
            return hit
        }

        let data: Data
        let file = Self.fileURL(book)
        if let bundled = Self.bundledURL(book.slug),
           let bundledData = await Task.detached(priority: .userInitiated, operation: { try? Data(contentsOf: bundled) }).value {
            // Shipped in the app bundle: the bundle IS its storage - nothing to download, nothing to keep.
            data = bundledData
        } else if let disk = await Task.detached(priority: .userInitiated, operation: { try? Data(contentsOf: file) }).value {
            data = disk
        } else {
            guard let remote = Self.endpoint(book) else { throw URLError(.badURL) }
            let (fetched, response) = try await URLSession.shared.data(from: remote)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            data = fetched
            if persist {
                Task.detached(priority: .utility) {
                    try? fetched.write(to: file, options: .atomic)
                }
                downloadedSlugs.insert(book.slug)
            }
        }

        let parsed = try await Task.detached(priority: .userInitiated) {
            try JSONDecoder().decode(HadithBookData.self, from: data)
        }.value

        decoded.removeAll { $0.slug == book.slug }
        decoded.append((book.slug, parsed))
        // The cache holds the WHOLE offline shelf (prewarm decodes every available book so any open
        // is instant); the floor of 4 only matters for online-only reads on an empty shelf.
        let cacheCap = max(4, HadithCatalogBook.all.filter { isAvailableOffline($0) }.count)
        if decoded.count > cacheCap {
            let evicted = decoded.removeFirst()
            // The index rides with the decoded book - keep the two caches aligned.
            searchIndexes.removeValue(forKey: evicted.slug)
        }
        buildSearchIndex(slug: book.slug, book: parsed)
        recordCounts(slug: book.slug, chapters: parsed.chapters.count, hadiths: parsed.hadiths.count)
        return parsed
    }

    // MARK: Bulk download

    /// Fetch every non-bundled book not yet on disk, one at a time (the files are large; parallel
    /// fetches of 13 MB JSONs just fight each other for bandwidth). Bundle-shipped books are already
    /// available and skipped.
    func startDownloadAll() {
        guard !isDownloading else { return }
        let downloadable = HadithCatalogBook.all.filter { Self.bundledURL($0.slug) == nil }
        isDownloading = true
        downloadError = nil
        downloadTotalBooks = downloadable.count
        downloadCompletedBooks = 0

        downloadTask = Task { [weak self] in
            var failures = 0
            for book in downloadable {
                if Task.isCancelled { break }
                guard let self else { return }
                self.downloadingBookTitle = book.englishTitle

                let file = Self.fileURL(book)
                let exists = await Task.detached(priority: .userInitiated) {
                    FileManager.default.fileExists(atPath: file.path)
                }.value
                if exists {
                    self.downloadCompletedBooks += 1
                    self.downloadedSlugs.insert(book.slug)
                    continue
                }

                guard let url = Self.endpoint(book),
                      let (data, response) = try? await URLSession.shared.data(from: url),
                      let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    failures += 1
                    continue
                }
                let write = data
                await Task.detached(priority: .utility) {
                    try? write.write(to: file, options: .atomic)
                }.value
                self.downloadedSlugs.insert(book.slug)
                self.downloadCompletedBooks += 1
            }

            guard let self else { return }
            if failures > 0, !Task.isCancelled {
                self.downloadError = "\(failures) books failed to download. Run the download again to retry them."
            }
            self.isDownloading = false
            self.downloadingBookTitle = ""
            self.refreshDiskState()
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        downloadingBookTitle = ""
    }

    func deleteDownload(_ book: HadithCatalogBook) {
        decoded.removeAll { $0.slug == book.slug }
        downloadedSlugs.remove(book.slug)
        Task.detached(priority: .utility) { [weak self] in
            try? FileManager.default.removeItem(at: Self.fileURL(book))
            await self?.refreshDiskState()
        }
    }

    func deleteAllDownloads() {
        cancelDownload()
        decoded.removeAll()
        downloadedSlugs = []
        Task.detached(priority: .utility) { [weak self] in
            let contents = (try? FileManager.default.contentsOfDirectory(at: Self.directory, includingPropertiesForKeys: nil)) ?? []
            for file in contents {
                try? FileManager.default.removeItem(at: file)
            }
            await self?.refreshDiskState()
        }
    }

    // MARK: Hadith of the Day

    /// Today's hadith, resolved BEFORE the tab ever opens (`prepareDailyHadith()` runs at launch) so
    /// the card renders instantly. Picked ONLY from collections available on this device; nil when
    /// nothing is available at all.
    @Published private(set) var daily: (book: HadithCatalogBook, hadith: HadithBookData.Hadith)?

    private var dailyPreparedForDay: String?
    private static let dailyOverrideKey = "hadithOfTheDayOverride"
    private static let dailyResolvedKey = "hadithOfTheDayResolved"

    /// Words that keep a hadith out of the daily rotation - the same gentle filter the Ayah of the Day
    /// pool uses, plus a length cap so the card never carries a page-long hadith.
    static func isDailyWorthy(_ hadith: HadithBookData.Hadith) -> Bool {
        guard hadith.arabic.count <= 220, hadith.english.text.count <= 220, !hadith.english.text.isEmpty else { return false }
        // ONE canonical gentle-filter, shared with Ayah of the Day (Settings.dailyCardBlockedWords):
        // whole-word matching over explicit forms - "slave", "hit", "beat" and family included.
        return !Settings.containsDailyBlockedWord(hadith.english.text + " " + hadith.english.narrator)
    }

    struct DailyHadithEntry: Codable {
        let dayKey: String
        let slug: String
        let idInBook: Int
        let reference: String
        let arabicPreview: String
        let englishPreview: String
        let date: Date
    }

    /// Memoized decode: the Hadith tab reads the history from body paths (2-3 accesses per body
    /// pass), and the store's frequent publishes during launch prewarm/downloads re-run those bodies
    /// - without this cache each access was a fresh UserDefaults read + JSONDecoder pass on main.
    private static var dailyHistoryCache: [DailyHadithEntry]?

    static func loadDailyHistory() -> [DailyHadithEntry] {
        if let cached = dailyHistoryCache { return cached }
        guard let data = UserDefaults.standard.data(forKey: "hadithOfTheDayHistory"),
              let decoded = try? JSONDecoder().decode([DailyHadithEntry].self, from: data) else {
            dailyHistoryCache = []
            return []
        }
        dailyHistoryCache = decoded
        return decoded
    }

    private static func saveDailyHistory(_ entries: [DailyHadithEntry]) {
        let trimmed = Array(entries.prefix(5))
        dailyHistoryCache = trimmed
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: "hadithOfTheDayHistory")
        }
    }

    /// Kick off today's resolution. Called at APP LAUNCH (and again by the tab as a cheap no-op) so the
    /// pick is ready before the Hadith tab is ever opened.
    func prepareDailyHadith(force: Bool = false) {
        Task { await resolveDaily(force: force) }
    }

    private func parseDailyRef(_ raw: String?, dayKey: String) -> (book: HadithCatalogBook, idInBook: Int)? {
        guard let raw else { return nil }
        let parts = raw.split(separator: "|")
        guard parts.count == 3, String(parts[0]) == dayKey,
              let id = Int(parts[2]),
              let book = HadithCatalogBook.bySlug[String(parts[1])] else { return nil }
        return (book, id)
    }

    private func resolveDaily(force: Bool) async {
        let dayKey = Settings.dayKey()
        if !force, dailyPreparedForDay == dayKey, daily != nil { return }

        // 1. A shuffle override for today wins.
        if let ref = parseDailyRef(UserDefaults.standard.string(forKey: Self.dailyOverrideKey), dayKey: dayKey),
           isAvailableOffline(ref.book),
           let data = try? await book(ref.book, persist: false),
           let hadith = data.hadiths.first(where: { $0.idInBook == ref.idInBook }) {
            daily = (ref.book, hadith)
            dailyPreparedForDay = dayKey
            recordDailyHistory(book: ref.book, hadith: hadith, dayKey: dayKey)
            return
        }

        // 2. Today's already-resolved pick: one book load, instant thereafter (memory cache).
        if !force,
           let ref = parseDailyRef(UserDefaults.standard.string(forKey: Self.dailyResolvedKey), dayKey: dayKey),
           isAvailableOffline(ref.book),
           let data = try? await book(ref.book, persist: false),
           let hadith = data.hadiths.first(where: { $0.idInBook == ref.idInBook }) {
            daily = (ref.book, hadith)
            dailyPreparedForDay = dayKey
            return
        }

        // 3. Deterministic pick from the AVAILABLE books only - the day chooses the book, then the
        //    hadith within it, so only ONE book ever has to load. No available books, no card.
        let available = HadithCatalogBook.all.filter { isAvailableOffline($0) }
        guard !available.isEmpty else {
            daily = nil
            dailyPreparedForDay = dayKey
            return
        }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        for offset in 0..<available.count {
            let candidate = available[(day + offset) % available.count]
            guard let data = try? await book(candidate, persist: false) else { continue }
            let worthy = data.hadiths.filter(Self.isDailyWorthy)
            guard !worthy.isEmpty else { continue }
            let pick = worthy[day % worthy.count]
            daily = (candidate, pick)
            dailyPreparedForDay = dayKey
            UserDefaults.standard.set("\(dayKey)|\(candidate.slug)|\(pick.idInBook)", forKey: Self.dailyResolvedKey)
            recordDailyHistory(book: candidate, hadith: pick, dayKey: dayKey)
            return
        }
        daily = nil
        dailyPreparedForDay = dayKey
    }

    /// A GENUINELY random hadith from any available collection, stored as today's override.
    func shuffleDailyHadith() async {
        let available = HadithCatalogBook.all.filter { isAvailableOffline($0) }.shuffled()
        for candidate in available {
            guard let data = try? await book(candidate, persist: false) else { continue }
            guard let pick = data.hadiths.filter(Self.isDailyWorthy).randomElement() else { continue }
            UserDefaults.standard.set("\(Settings.dayKey())|\(candidate.slug)|\(pick.idInBook)", forKey: Self.dailyOverrideKey)
            await resolveDaily(force: true)
            return
        }
    }

    /// Keeps the last 5 days on record, one entry per day (a shuffle REPLACES today's entry).
    private func recordDailyHistory(book: HadithCatalogBook, hadith: HadithBookData.Hadith, dayKey: String) {
        var history = Self.loadDailyHistory()
        let entry = DailyHadithEntry(
            dayKey: dayKey,
            slug: book.slug,
            idInBook: hadith.idInBook,
            reference: "\(book.englishTitle) \(hadith.idInBook)",
            arabicPreview: String(hadith.arabic.prefix(120)),
            englishPreview: String(hadith.english.text.prefix(140)),
            date: Date()
        )
        if let first = history.first, first.dayKey == dayKey {
            history[0] = entry
        } else {
            history.insert(entry, at: 0)
        }
        Self.saveDailyHistory(history)
    }

    func refreshDiskState() {
        Task.detached(priority: .utility) { [weak self] in
            let contents = (try? FileManager.default.contentsOfDirectory(
                at: Self.directory, includingPropertiesForKeys: [.fileSizeKey]
            )) ?? []
            var slugs: Set<String> = []
            var bytes: Int64 = 0
            for url in contents {
                slugs.insert(url.deletingPathExtension().lastPathComponent)
                bytes += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            }
            let finalSlugs = slugs
            let finalBytes = bytes
            await MainActor.run { [weak self] in
                self?.downloadedSlugs = finalSlugs
                self?.diskUsageBytes = finalBytes
            }
        }
    }
}

/// The Hadith tab's trailing toolbar, split with iOS 26 ToolbarSpacers so Liquid Glass doesn't merge
/// the buttons into one capsule - the same treatment the Quran tab's trailing toolbar has.
#endif
