import SwiftUI

// The open-books cache over the app's bundled hadith packs (every collection ships inside the app -
// nothing is downloaded, and there is no cache to manage), plus favorites, bookmarks, last-read, and
// the Hadith of the Day engine.

#if os(iOS)

// MARK: - User collections (favorites, bookmarks, notes)

/// The reader's own marks - favorite books/chapters, bookmarks, and their notes - split OUT of
/// HadithStore's `objectWillChange`: the store used to publish constantly (bulk downloads, per-book
/// decode ticks), and every row observing it just for bookmark state re-rendered on each tick. This object publishes only on actual user edits, so the rows that
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

/// The open books, over the packs bundled in the app: favorites, bookmarks, last read, and Hadith of
/// the Day. Every collection is present on the device from the moment the app is installed, so there
/// is no download state, no cache directory, and no "not available offline" anywhere in the tab.
@MainActor
final class HadithStore: ObservableObject {
    static let shared = HadithStore()

    private init() {
        #if os(iOS)
        // Everything the reader holds is rebuildable from the bundle in milliseconds: the decompressed
        // blocks, the per-book Hadith arrays, the pager's derived text. Under real pressure all of it
        // goes rather than letting jetsam make the decision.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                HadithStore.shared.trimCachesForMemoryPressure()
            }
        }
        #endif
    }

    /// Drops every decompressed block and all but the most recently opened books. The packs themselves
    /// stay mapped - a memory map is not resident memory, and dropping it would only cost a re-open.
    private func trimCachesForMemoryPressure() {
        // The pager's derived caches retain whole chapters of text independent of the block cache.
        HadithPagedView.clearDerivedCaches()
        HadithBlockCache.shared.purge()
        let keep = 2
        guard openOrder.count > keep else { return }
        let dropped = Array(openOrder.prefix(openOrder.count - keep))
        openOrder.removeFirst(dropped.count)
        for slug in dropped { books.removeValue(forKey: slug) }
    }

    /// Packs, mapped once and kept for the life of the app - each is a file mapping plus its id table,
    /// so all 17 together are about a megabyte and open in tens of milliseconds.
    private var packs: [String: HadithPack] = [:]

    /// The `HadithBookData` built over each open pack (its chapter list and per-hadith records), and
    /// the order they were opened in, newest last, for the memory-pressure trim.
    private var books: [String: HadithBookData] = [:]
    private var openOrder: [String] = []

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

    /// The book's shape for display, straight from the pack - which is the data, so there is no
    /// hand-maintained table to drift. Opening a book is a memory map and an id table, cheap enough
    /// for a catalog row to ask from its body; `recordedCounts` covers the moment before that lands.
    func counts(for book: HadithCatalogBook) -> (chapters: Int, hadiths: Int)? {
        if let open = self.book(book) {
            return (open.chapters.count, open.hadiths.count)
        }
        if let known = recordedCounts[book.slug], known.count == 2 {
            return (known[0], known[1])
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
        // Re-recording the position already held is a NO-OP, publish included. Opening "Last Read" (or
        // the auto-open landing on the remembered chapter) records the very hadith the store already
        // holds - and that publish re-rendered the screens hosting the programmatic navigation links
        // mid-push, whose reconciliation is what popped the just-opened chapter back to the chapter
        // list. Deliberate trade-off: the entry's timestamp is NOT refreshed on a same-spot re-read,
        // so the cross-book "latest" pick can lag until the reader actually moves to a new hadith.
        if let existing = lastReadByBook[book.slug],
           existing.idInBook == hadith.idInBook, existing.chapterId == hadith.chapterId {
            return
        }
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

    /// Open EVERY collection at launch - most recent last-reads first, then favorites, then the rest
    /// of the shelf - so opening any of them is instant. This used to mean decoding 75 MB of JSON and
    /// holding the whole library's text in memory; over the packs it is a memory map and an id table
    /// per book, about 20 ms and a megabyte for all 17, with none of their text touched.
    func prewarmBooks() {
        guard !didPrewarmBooks else { return }
        didPrewarmBooks = true
        loadLastRead()
        Self.purgeLegacyDownloadCache()

        var ordered: [String] = lastReadByBook.values
            .sorted { $0.timestamp > $1.timestamp }
            .map(\.slug)
        ordered += HadithUserData.shared.favoriteSlugs.sorted()
        ordered += HadithCatalogBook.all.map(\.slug)

        var seen = Set<String>()
        let targets = ordered
            .compactMap { HadithCatalogBook.bySlug[$0] }
            .filter { seen.insert($0.slug).inserted }
        guard !targets.isEmpty else { return }

        Task {
            for book in targets where self.books[book.slug] == nil {
                _ = self.book(book)
                // One book per turn of the run loop: the whole sweep is milliseconds, but launch has
                // better things to do with an uninterrupted main thread than 17 of them in a row.
                await Task.yield()
            }
        }
    }

    /// Delete the pre-4.7 download cache, once. Before the books shipped inside the app they were
    /// fetched to `Application Support/HadithCache`, and a reader who had downloaded the shelf is
    /// carrying up to 75 MB there that nothing will ever read again - and with the Downloads screen
    /// gone, no way to find it. Runs off-main at launch, and only until it succeeds.
    private static func purgeLegacyDownloadCache() {
        let flag = "hadithLegacyCachePurged"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        Task.detached(priority: .background) {
            guard let base = try? FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false
            ) else { return }
            let directory = base.appendingPathComponent("HadithCache", isDirectory: true)
            if FileManager.default.fileExists(atPath: directory.path) {
                try? FileManager.default.removeItem(at: directory)
            }
            await MainActor.run { UserDefaults.standard.set(true, forKey: flag) }
        }
    }

    // MARK: Books

    /// The book, opened over its bundled pack. Synchronous and cheap by construction - the pack is
    /// mapped, not read, and none of its text is decompressed until a view asks for a hadith - so
    /// callers no longer need a loading state at all.
    @discardableResult
    func book(_ book: HadithCatalogBook) -> HadithBookData? {
        if let open = books[book.slug] {
            if let index = openOrder.firstIndex(of: book.slug) {
                openOrder.remove(at: index)
                openOrder.append(book.slug)
            }
            return open
        }
        guard let pack = pack(book.slug) else { return nil }
        let data = HadithBookData(pack: pack)
        books[book.slug] = data
        openOrder.append(book.slug)
        // Deliberately deferred to the next main-actor turn: opening a book is now synchronous, so
        // this runs from view `init`s and body paths, and `recordCounts` publishes. Publishing from
        // inside a view update is exactly what SwiftUI warns about. It is a no-op after the first
        // time each book is opened, on the first launch that opens it.
        if recordedCounts[book.slug] != [data.chapters.count, data.hadiths.count] {
            let slug = book.slug
            let chapters = data.chapters.count
            let hadiths = data.hadiths.count
            Task { @MainActor in
                self.recordCounts(slug: slug, chapters: chapters, hadiths: hadiths)
            }
        }
        return data
    }

    /// The book if it is already open - the synchronous path a view body can take without opening
    /// anything. (Kept distinct from `book(_:)` so a render pass can never trigger a map.)
    func cachedBook(_ slug: String) -> HadithBookData? {
        books[slug]
    }

    private func pack(_ slug: String) -> HadithPack? {
        if let open = packs[slug] { return open }
        guard let url = HadithPack.bundledURL(slug), let pack = HadithPack(slug: slug, url: url) else {
            return nil
        }
        packs[slug] = pack
        return pack
    }

    // MARK: Hadith of the Day

    /// Today's hadith, resolved BEFORE the tab ever opens (`prepareDailyHadith()` runs at launch) so
    /// the card renders instantly. Picked ONLY from collections available on this device; nil when
    /// nothing is available at all.
    @Published private(set) var daily: (book: HadithCatalogBook, hadith: HadithBookData.Hadith)?

    private var dailyPreparedForDay: String?
    private static let dailyOverrideKey = "hadithOfTheDayOverride"
    private static let dailyResolvedKey = "hadithOfTheDayResolved"

    /// The fingerprint of THIS build's blocked-word list. The packs carry the fingerprint of the list
    /// they were built from; when the two agree, every hadith's `dailyGentle` flag is already correct
    /// and choosing a daily hadith reads no text at all.
    nonisolated static let appBlockedWordFingerprint: UInt64 =
        HadithFold.wordListFingerprint(Settings.dailyCardBlockedWords)

    /// Whether a book's precomputed daily flags can be taken at face value - i.e. whether the word
    /// list was the same when the packs were built. If it wasn't, nothing breaks: the length flag is
    /// still objective, and the words get rechecked live for the few hadiths that pass it.
    nonisolated static func trustsDailyFlags(_ data: HadithBookData) -> Bool {
        data.pack.blockedWordFingerprint == appBlockedWordFingerprint
    }

    /// Whether this hadith belongs in the daily rotation: short enough in both scripts, English text
    /// present, and free of the words that keep the daily cards gentle (the same list Ayah of the Day
    /// uses - "slave", "hit", "beat" and family). Both halves were decided when the pack was built.
    // nonisolated: the fallback path runs this over a whole book from a detached task, and the store
    // is @MainActor. It reads only the pack, which is thread-safe by construction.
    nonisolated static func isDailyWorthy(_ hadith: HadithBookData.Hadith, trustingFlags: Bool) -> Bool {
        // The length gate is objective and always precomputed - no text, no decompression.
        guard hadith.flags & HadithPack.Flag.dailyLength != 0 else { return false }
        if trustingFlags { return hadith.flags & HadithPack.Flag.dailyGentle != 0 }
        // The app's list has moved since the packs were built: recheck, but only for the ~24% of
        // hadiths that passed the length gate.
        let strings = hadith.allText
        return !Settings.containsDailyBlockedWord(strings.text + " " + strings.narrator)
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
    /// pass), and a store publish re-runs those bodies
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
           let data = book(ref.book),
           let hadith = data.hadiths.first(where: { $0.idInBook == ref.idInBook }) {
            daily = (ref.book, hadith)
            dailyPreparedForDay = dayKey
            recordDailyHistory(book: ref.book, hadith: hadith, dayKey: dayKey)
            return
        }

        // 2. Today's already-resolved pick: one book load, instant thereafter (memory cache).
        if !force,
           let ref = parseDailyRef(UserDefaults.standard.string(forKey: Self.dailyResolvedKey), dayKey: dayKey),
           let data = book(ref.book),
           let hadith = data.hadiths.first(where: { $0.idInBook == ref.idInBook }) {
            daily = (ref.book, hadith)
            dailyPreparedForDay = dayKey
            return
        }

        // 3. Deterministic pick across the whole library - the day chooses the book, then the hadith
        //    within it, so only ONE book ever has to open.
        let available = HadithCatalogBook.all
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        for offset in 0..<available.count {
            let candidate = available[(day + offset) % available.count]
            guard let data = book(candidate) else { continue }
            // OFF-MAIN, always: the worthiness filter reads the text of every hadith in the book, and
            // over the packs that means decompressing all of it. On the main actor this ran at launch,
            // behind the first frame. It returns a row, not a hadith, so nothing crosses back but an Int.
            guard let pickedRow = await Self.dailyWorthyRow(in: data, index: day) else { continue }
            let pick = data.hadiths[pickedRow]
            daily = (candidate, pick)
            dailyPreparedForDay = dayKey
            UserDefaults.standard.set("\(dayKey)|\(candidate.slug)|\(pick.idInBook)", forKey: Self.dailyResolvedKey)
            recordDailyHistory(book: candidate, hadith: pick, dayKey: dayKey)
            return
        }
        daily = nil
        dailyPreparedForDay = dayKey
    }

    /// A GENUINELY random hadith from any collection, stored as today's override.
    func shuffleDailyHadith() async {
        for candidate in HadithCatalogBook.all.shuffled() {
            guard let data = book(candidate) else { continue }
            guard let pickedRow = await Self.dailyWorthyRow(in: data, index: nil) else { continue }
            let pick = data.hadiths[pickedRow]
            UserDefaults.standard.set("\(Settings.dayKey())|\(candidate.slug)|\(pick.idInBook)", forKey: Self.dailyOverrideKey)
            await resolveDaily(force: true)
            return
        }
    }

    /// The row of a daily-worthy hadith in this book: the `index`-th one deterministically, or a
    /// random one when `index` is nil.
    private static func dailyWorthyRow(in data: HadithBookData, index: Int?) async -> Int? {
        if trustsDailyFlags(data) {
            // The normal path: a walk of the resident id table, reading two bits per hadith. No text,
            // no decompression, no thread hop - microseconds for the largest book.
            var worthy: [Int] = []
            for (row, hadith) in data.hadiths.enumerated()
            where isDailyWorthy(hadith, trustingFlags: true) {
                worthy.append(row)
            }
            return pick(worthy, index: index)
        }

        // The word list changed without a repack: fall back to reading the text of the hadiths that
        // passed the length gate, off-main.
        return await Task.detached(priority: .userInitiated) { () -> Int? in
            var worthy: [Int] = []
            for (row, hadith) in data.hadiths.enumerated()
            where isDailyWorthy(hadith, trustingFlags: false) {
                worthy.append(row)
            }
            return pick(worthy, index: index)
        }.value
    }

    /// The `index`-th worthy row deterministically, or a random one when `index` is nil.
    // nonisolated: the fallback above calls this from a detached task.
    private nonisolated static func pick(_ worthy: [Int], index: Int?) -> Int? {
        guard !worthy.isEmpty else { return nil }
        guard let index else { return worthy.randomElement() }
        return worthy[index % worthy.count]
    }

    /// Keeps the last 5 days on record, one entry per day (a shuffle REPLACES today's entry).
    private func recordDailyHistory(book: HadithCatalogBook, hadith: HadithBookData.Hadith, dayKey: String) {
        var history = Self.loadDailyHistory()
        let strings = hadith.allText
        let entry = DailyHadithEntry(
            dayKey: dayKey,
            slug: book.slug,
            idInBook: hadith.idInBook,
            reference: "\(book.englishTitle) \(hadith.idInBook)",
            arabicPreview: String(strings.arabic.prefix(120)),
            englishPreview: String(strings.text.prefix(140)),
            date: Date()
        )
        if let first = history.first, first.dayKey == dayKey {
            history[0] = entry
        } else {
            history.insert(entry, at: 0)
        }
        Self.saveDailyHistory(history)
    }

}

/// The Hadith tab's trailing toolbar, split with iOS 26 ToolbarSpacers so Liquid Glass doesn't merge
/// the buttons into one capsule - the same treatment the Quran tab's trailing toolbar has.
#endif
