import Foundation

// Ranked hadith search: the "top results" lane of the hadith searches.
//
// The all-books sweep (`HadithPack.matchingRows`) is a byte search for the query as one contiguous
// run, returned in book order. Exact and exhaustive, and blind to everything else: "controlling
// anger" finds nothing unless the two words touch, "rights" never reaches "the right of the
// neighbour", "intetion" returns an empty list, and a query word landing in a CHAPTER TITLE counts
// for no more than the same word buried in a 400-word narration. This engine matches the words
// independently and scores each hadith on where they landed:
//
//   PRIMARY  the chapter's name, what the narration is ABOUT              (12 a word)
//   CITATION the book it is in                                            (7)
//   BODY     the narration itself, narrator line included                 (3)
//
// with a bonus for a whole-word hit over a substring one, a bonus for the words sitting together as
// the typed phrase, a discount for a stemmed hit ("rights" -> "right"), the other spelling
// ("neighbour" / "neighbor") at full price, and a corrected typo at a heavier discount, so an exact
// match always outranks a guess. Strict pass first (every word has to be there); if that comes back
// empty on a multi-word query, a relaxed pass ranks the rows carrying the most of it instead of
// showing a blank screen.
//
// Ported from the Tilawa app's hadithSearchEngine.ts (Jamil Hammoudeh), with permission, onto the
// packs' prebuilt folds: the query is folded by the same `HadithFold` rules the packs were built
// with, and every test below is a byte compare inside a decompressed block.

enum HadithRankedSearch {
    struct Correction: Hashable {
        let from: String
        let to: String
    }

    struct Token {
        let text: [UInt8]
        /// The suffix-stripped form ("rights" -> "right"), matched at a word start.
        let stem: [UInt8]?
        /// The same word spelled the other way ("neighbour" / "neighbor").
        let variant: [UInt8]?
        /// The library word this one was probably a misspelling of.
        let fuzzy: [UInt8]?
    }

    struct Query {
        let isArabic: Bool
        /// The whole folded query, for the phrase bonus.
        let phrase: [UInt8]
        let tokens: [Token]
        let corrections: [Correction]
        /// What the result rows should paint: the typed words with corrections applied.
        let highlightQuery: String

        var isEmpty: Bool { tokens.isEmpty }
    }

    struct Hit {
        let row: Int
        let score: Int
        /// How many of the query's words landed (in the narration or its chapter): the caller keeps
        /// the rows carrying every word and, only when none does, the ones carrying the most of it.
        let matched: Int
    }

    /// What a relaxed row (fewer than every word of a multi-word query) adds per matched word, on
    /// top of `Hit.score`, when the relaxed rows are the ones shown.
    static func relaxedBonus(matched: Int) -> Int { matched * relaxedTokenWeight }

    /// The names a search scores besides the narration: across the shelf both, inside one book only
    /// the chapter names (the book's own is every row's), inside one chapter neither.
    enum Titles {
        case bookAndChapters, chapters, none
    }

    struct BookOutcome {
        let hits: [Hit]
        let relaxed: Bool
    }

    // Where a word landed decides what it is worth (Tilawa's weights).
    private static let primaryWeight = 12
    private static let citationWeight = 7
    private static let bodyWeight = 3
    private static let phraseBonusPrimary = 60
    private static let phraseBonusBody = 25
    private static let wholeWordBonus = 6
    private static let stemPenalty = 2
    private static let fuzzyPenalty = 5
    private static let relaxedTokenWeight = 40

    static let stopwords: Set<String> = [
        "a", "an", "and", "are", "as", "at", "be", "by", "for", "from", "he", "his", "in", "is", "it",
        "of", "on", "or", "that", "the", "to", "was", "who", "with",
    ]

    // MARK: - Query

    static func parse(_ raw: String, vocabulary: HadithVocabulary?) -> Query? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return nil }
        let isArabic = HadithFold.isArabicScript(trimmed)
        let folded = isArabic ? HadithFold.arabic(trimmed) : HadithFold.english(trimmed)
        let words = folded.split(whereSeparator: { $0.isWhitespace }).map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else { return nil }
        let meaningful = isArabic ? words : words.filter { !stopwords.contains($0) }
        let used = meaningful.isEmpty ? words : meaningful

        var corrections: [Correction] = []
        var highlight: [String] = []
        let tokens: [Token] = used.map { word in
            let stem = isArabic ? nil : stemWord(word)
            let variant = isArabic ? nil : variantSpelling(word)
            let fuzzy = isArabic ? nil : vocabulary?.nearestWord(to: word)
            if let fuzzy { corrections.append(Correction(from: word, to: fuzzy)) }
            highlight.append(fuzzy ?? word)
            return Token(text: Array(word.utf8), stem: stem.map { Array($0.utf8) },
                         variant: variant.map { Array($0.utf8) }, fuzzy: fuzzy.map { Array($0.utf8) })
        }
        return Query(isArabic: isArabic, phrase: Array(used.joined(separator: " ").utf8), tokens: tokens,
                     corrections: corrections, highlightQuery: highlight.joined(separator: " "))
    }

    private static let suffixes = ["ing", "ed", "es", "s", "ly"]

    /// Deliberately not a real stemmer: ASCII only, length-guarded so short words are never truncated
    /// into noise, and always discounted so an exact match outranks it.
    static func stemWord(_ word: String) -> String? {
        guard word.count >= 5, isLatinWord(word) else { return nil }
        for suffix in suffixes where word.hasSuffix(suffix) && word.count - suffix.count >= 4 {
            return QuranRankedSearch.undoubled(String(word.dropLast(suffix.count)))
        }
        return nil
    }

    /// The other side of the Atlantic's spelling: the translations come from several hands, so the
    /// corpus itself mixes "neighbour" and "neighbor". Length-guarded away from the short words that
    /// merely end the same way ("four", "hour", "your").
    static func variantSpelling(_ word: String) -> String? {
        guard isLatinWord(word) else { return nil }
        if word.count >= 6, word.hasSuffix("our") { return String(word.dropLast(3)) + "or" }
        if word.count >= 5, word.hasSuffix("or") { return String(word.dropLast(2)) + "our" }
        if word.count >= 6, word.hasSuffix("ise") { return String(word.dropLast(3)) + "ize" }
        if word.count >= 6, word.hasSuffix("ize") { return String(word.dropLast(3)) + "ise" }
        return nil
    }

    static func isLatinWord(_ word: String) -> Bool {
        !word.isEmpty && word.unicodeScalars.allSatisfy { (97...122).contains($0.value) }
    }

    // MARK: - Byte matching

    private static func isBoundary(_ byte: UInt8) -> Bool {
        byte == 0x20 || byte == 0x0A || byte == 0x09 || byte == 0x0D
    }

    /// Whether `needle` occurs in `haystack`, and whether one occurrence stands alone as a whole word.
    /// A word-START hit (stems) needs only the leading boundary.
    private static func find(_ needle: [UInt8], in haystack: UnsafeBufferPointer<UInt8>,
                             wholeWord: Bool, wordStart: Bool) -> (found: Bool, whole: Bool) {
        guard !needle.isEmpty, haystack.count >= needle.count, let base = haystack.baseAddress else { return (false, false) }
        var found = false
        var offset = 0
        return needle.withUnsafeBufferPointer { needlePointer -> (Bool, Bool) in
            guard let needleBase = needlePointer.baseAddress else { return (false, false) }
            while offset + needle.count <= haystack.count {
                guard let hit = memmem(base + offset, haystack.count - offset, needleBase, needle.count) else { break }
                let start = UnsafeRawPointer(hit).assumingMemoryBound(to: UInt8.self) - base
                found = true
                let leading = start == 0 || isBoundary(haystack[start - 1])
                let end = start + needle.count
                let trailing = end >= haystack.count || isBoundary(haystack[end])
                if wordStart, leading { return (true, true) }
                if wholeWord, leading, trailing { return (true, true) }
                if !wholeWord, !wordStart { return (true, false) }
                offset = start + 1
            }
            return (found, false)
        }
    }

    /// What one query word is worth against one fold, or 0.
    static func tokenHit(_ token: Token, in fold: UnsafeBufferPointer<UInt8>, weight: Int) -> Int {
        let direct = find(token.text, in: fold, wholeWord: true, wordStart: false)
        if direct.found { return weight + (direct.whole ? wholeWordBonus : 0) }
        if let variant = token.variant {
            let hit = find(variant, in: fold, wholeWord: true, wordStart: false)
            if hit.found { return weight + (hit.whole ? wholeWordBonus : 0) }
        }
        if let stem = token.stem, find(stem, in: fold, wholeWord: false, wordStart: true).found {
            return max(1, weight - stemPenalty)
        }
        if let fuzzy = token.fuzzy, find(fuzzy, in: fold, wholeWord: false, wordStart: true).found {
            return max(1, weight - fuzzyPenalty)
        }
        return 0
    }

    private static func tokenHit(_ token: Token, in text: String, weight: Int) -> Int {
        var bytes = Array(text.utf8)
        return bytes.withUnsafeMutableBufferPointer { buffer in
            tokenHit(token, in: UnsafeBufferPointer(buffer), weight: weight)
        }
    }

    private static func contains(_ needle: [UInt8], in text: String) -> Bool {
        guard !needle.isEmpty else { return false }
        var bytes = Array(text.utf8)
        return bytes.withUnsafeMutableBufferPointer { buffer in
            find(needle, in: UnsafeBufferPointer(buffer), wholeWord: false, wordStart: false).found
        }
    }

    // MARK: - One book

    /// Every hadith of `data` carrying at least one word of `query`, with how many words it carries
    /// and its score before the relaxed bonus: ONE pass over the book serves both the strict list
    /// (every word) and the relaxed one (the most words), where two passes used to scan the library
    /// twice for a multi-word query. Blocks in which no word of the query occurs at all, in any
    /// form, are skipped whole unless a chapter of theirs matched. Runs off the main thread; checks
    /// cancellation per block through the pack scanner. `within` narrows the pass to a run of the
    /// book's rows (one chapter's, for the in-chapter search); nil is the whole book. `titles` says
    /// which names count: a name shared by every row in reach matches all of them, which ranks nothing.
    static func rank(book: HadithCatalogBook, data: HadithBookData, query: Query, within: Range<Int>? = nil,
                     titles: Titles = .bookAndChapters) -> [Hit] {
        guard !query.isEmpty else { return [] }
        let pack = data.pack
        // The chapter and citation buckets are the same for every row of a chapter, so they are
        // scored once per chapter, not once per narration.
        struct Bucket { let score: Int; let matched: Set<Int> }
        let bookFold = query.isArabic ? HadithFold.arabic(book.arabicTitle) : HadithFold.english(book.englishTitle)
        var citationHits: [Int: Int] = [:]
        for (index, token) in query.tokens.enumerated() where titles == .bookAndChapters {
            let hit = tokenHit(token, in: bookFold, weight: citationWeight)
            if hit > 0 { citationHits[index] = hit }
        }
        var buckets: [Int: Bucket] = [:]
        for chapter in data.chapters where titles != .none {
            let fold = query.isArabic ? chapter.foldArabic : chapter.foldEnglish
            var score = 0
            var matched = Set<Int>()
            for (index, token) in query.tokens.enumerated() {
                let primary = tokenHit(token, in: fold, weight: primaryWeight)
                let best = max(primary, citationHits[index] ?? 0)
                if best > 0 {
                    score += best
                    matched.insert(index)
                }
            }
            if query.tokens.count > 1, contains(query.phrase, in: fold) { score += phraseBonusPrimary }
            buckets[chapter.id] = Bucket(score: score, matched: matched)
        }
        // Chapters where a word landed in the title or the citation: a block whose folds carry no
        // word at all can still hold rows that match through their chapter, so those blocks scan.
        let matchedChapters = Set(buckets.filter { !$0.value.matched.isEmpty }.map(\.key))
        let rows = data.hadiths
        var hits: [Hit] = []
        pack.scanSearchFolds(in: within ?? 0..<rows.count, isArabic: query.isArabic, blockFilter: { blockRows, span in
            if !matchedChapters.isEmpty,
               blockRows.contains(where: { rows.indices.contains($0) && matchedChapters.contains(rows[$0].chapterId) }) {
                return true
            }
            return query.tokens.contains { appears($0, in: span) }
        }) { row, fold in
            let chapterId = rows.indices.contains(row) ? rows[row].chapterId : -1
            let bucket = buckets[chapterId]
            var score = 0
            var matched = 0
            for (index, token) in query.tokens.enumerated() {
                let body = tokenHit(token, in: fold, weight: bodyWeight)
                let above = (bucket?.matched.contains(index) ?? false)
                if body == 0, !above { continue }
                matched += 1
                score += body
            }
            guard matched > 0 else { return }
            score += bucket?.score ?? 0
            if query.tokens.count > 1, find(query.phrase, in: fold, wholeWord: false, wordStart: false).found {
                score += phraseBonusBody
            }
            hits.append(Hit(row: row, score: score, matched: matched))
        }
        return hits
    }

    // MARK: - One book, as a finished list

    /// The ranked lane of the in-book and in-chapter searches: what `HadithView.runGlobalSearch`
    /// assembles across the shelf, for one book.
    struct ScopedOutcome {
        /// Rows of the book, best first.
        var rows: [Int] = []
        /// How many matched before the cap (and before nothing else: a grading shrinks it to `rows`).
        var total = 0
        /// No hadith carried every word, so these carry the most of them.
        var relaxed = false
        var corrections: [Correction] = []
        /// What the rows should paint (see `Query.highlightQuery`).
        var highlight = ""

        var isEmpty: Bool { rows.isEmpty }
    }

    /// One pass over the book (or `within`), strict list first and the relaxed one only when nothing
    /// is strict, the best `cap` kept. `accept` is the grading test: it reads text blocks, so it is
    /// asked after the ranking, of a deeper list, the all-books lane's way. Runs on the caller's
    /// thread (a detached task); nil when the query has nothing to rank or the task was cancelled.
    static func rankedRows(query raw: String, book: HadithCatalogBook, data: HadithBookData,
                           within: Range<Int>? = nil, cap: Int, accept: ((Int) -> Bool)?) -> ScopedOutcome? {
        // The typo list: the shipped one, a file read. One book is never the whole shelf, so this
        // never starts the walk; without a list the words are searched as typed.
        HadithVocabulary.shared.buildIfNeeded(books: [data])
        guard !Task.isCancelled, let parsed = parse(raw, vocabulary: HadithVocabulary.shared) else { return nil }
        let kept = max(1, min(cap, data.hadiths.count))
        let depth = accept == nil ? kept : max(1, min(kept * 5, data.hadiths.count))
        let outranks: (Hit, Hit) -> Bool = { a, b in
            a.score != b.score ? a.score > b.score : a.row < b.row
        }
        var strict = TopK<Hit>(capacity: depth, outranks: outranks)
        var partial = TopK<Hit>(capacity: depth, outranks: outranks)
        let tokenCount = parsed.tokens.count
        for hit in rank(book: book, data: data, query: parsed, within: within, titles: within == nil ? .chapters : .none) {
            if hit.matched == tokenCount {
                strict.offer(hit)
            } else if tokenCount > 1 {
                partial.offer(Hit(row: hit.row, score: hit.score + relaxedBonus(matched: hit.matched), matched: hit.matched))
            }
        }
        guard !Task.isCancelled else { return nil }
        let relaxed = strict.offered == 0 && partial.offered > 0
        let chosen = relaxed ? partial : strict
        var rows = chosen.sorted().map(\.row)
        var total = chosen.offered
        if let accept {
            rows = Array(rows.filter(accept).prefix(kept))
            total = rows.count
        }
        return ScopedOutcome(rows: rows, total: total, relaxed: relaxed,
                             corrections: parsed.corrections, highlight: parsed.highlightQuery)
    }

    /// Whether any form of the word (as typed, the other spelling, the stem, the correction) occurs
    /// anywhere in `span`: the block-level pre-test, one `memmem` per form.
    private static func appears(_ token: Token, in span: UnsafeBufferPointer<UInt8>) -> Bool {
        if find(token.text, in: span, wholeWord: false, wordStart: false).found { return true }
        if let variant = token.variant, find(variant, in: span, wholeWord: false, wordStart: false).found { return true }
        if let stem = token.stem, find(stem, in: span, wholeWord: false, wordStart: false).found { return true }
        if let fuzzy = token.fuzzy, find(fuzzy, in: span, wholeWord: false, wordStart: false).found { return true }
        return false
    }
}

// MARK: - Bounded top-k

/// The best `capacity` elements of a stream, kept in a small heap ordered by `outranks`, so a common
/// word's tens of thousands of hits are never sorted whole for a forty-row cap. The root is the
/// WORST kept element; a newcomer that outranks it replaces it.
struct TopK<Element> {
    private var heap: [Element] = []
    let capacity: Int
    /// True when the first element ranks above the second.
    private let outranks: (Element, Element) -> Bool
    /// Everything offered, kept or not: the total the screen reports.
    private(set) var offered = 0

    init(capacity: Int, outranks: @escaping (Element, Element) -> Bool) {
        self.capacity = max(1, capacity)
        self.outranks = outranks
        heap.reserveCapacity(self.capacity)
    }

    mutating func offer(_ element: Element) {
        offered += 1
        if heap.count < capacity {
            heap.append(element)
            siftUp(heap.count - 1)
        } else if let worst = heap.first, outranks(element, worst) {
            heap[0] = element
            siftDown(0)
        }
    }

    /// The kept elements, best first.
    func sorted() -> [Element] {
        heap.sorted { outranks($0, $1) }
    }

    private mutating func siftUp(_ index: Int) {
        var child = index
        while child > 0 {
            let parent = (child - 1) / 2
            // A parent that outranks its child is out of place: the worse element belongs above.
            guard outranks(heap[parent], heap[child]) else { break }
            heap.swapAt(parent, child)
            child = parent
        }
    }

    private mutating func siftDown(_ index: Int) {
        var parent = index
        while true {
            let left = 2 * parent + 1
            let right = left + 1
            var worst = parent
            if left < heap.count, outranks(heap[worst], heap[left]) { worst = left }
            if right < heap.count, outranks(heap[worst], heap[right]) { worst = right }
            guard worst != parent else { break }
            heap.swapAt(parent, worst)
            parent = worst
        }
    }
}

// MARK: - Vocabulary

/// Every English word the library uses, for correcting typed ones. Shipped in the bundle
/// (`HadithVocabulary.txt.xz`, decision B of the Tilawa Guide, 2026-09-07: exported by the app's own
/// walk over every search block, so the list and the rule can never disagree), with the walk kept as
/// the fallback for a list built from other packs. Until it is ready a query is searched as typed.
final class HadithVocabulary: @unchecked Sendable {
    static let shared = HadithVocabulary()
    private init() {}

    // MARK: The shipped list

    private static var bundledURL: URL? {
        Bundle.main.url(forResource: "HadithVocabulary", withExtension: "txt.xz", subdirectory: "Data/Hadith")
            ?? Bundle.main.url(forResource: "HadithVocabulary", withExtension: "txt.xz", subdirectory: "Hadith")
            ?? Bundle.main.url(forResource: "HadithVocabulary", withExtension: "txt.xz")
    }

    static let isBundled: Bool = bundledURL != nil

    /// The shipped list's first line: "#shelf " and the fingerprint of the packs it was built from.
    static let headerPrefix = "#shelf "

    /// FNV-1a over "slug:bytes" of every pack on the shelf, by slug: names the shelf a list was
    /// built from, and costs seventeen file sizes to recompute (no pack is opened). The same value
    /// is computed by Scripts/build_hadith_vocabulary.py and Scripts/verify_tilawa_packs.py.
    static let shelfFingerprint: String = {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for slug in HadithCatalogBook.all.map(\.slug).sorted() {
            let size = HadithPack.bundledURL(slug).flatMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize } ?? 0
            for byte in "\(slug):\(size)\n".utf8 {
                hash ^= UInt64(byte)
                hash = hash &* 0x0000_0100_0000_01B3
            }
        }
        return String(hash, radix: 16)
    }()

    /// The shipped words, or nil when the resource is missing or was built for other packs.
    private static func loadBundledWords() -> [String]? {
        guard let url = bundledURL, let blob = try? Data(contentsOf: url),
              let raw = SolidPack.xzDecompress(blob) else { return nil }
        var lines = String(decoding: raw, as: UTF8.self).split(separator: "\n", omittingEmptySubsequences: true)
        guard let first = lines.first, first.hasPrefix(headerPrefix),
              first.dropFirst(headerPrefix.count) == shelfFingerprint else { return nil }
        lines.removeFirst()
        return lines.map(String.init)
    }

    /// For "-auditPacks": the shipped list's size and whether it matches the shelf.
    static func bundledSummary() -> (words: Int, matchesShelf: Bool)? {
        guard let url = bundledURL, let blob = try? Data(contentsOf: url),
              let raw = SolidPack.xzDecompress(blob) else { return nil }
        let lines = String(decoding: raw, as: UTF8.self).split(separator: "\n", omittingEmptySubsequences: true)
        let matches = lines.first.map { $0.hasPrefix(headerPrefix) && $0.dropFirst(headerPrefix.count) == shelfFingerprint } ?? false
        return (max(0, lines.count - 1), matches)
    }

    /// Installs the shipped list (a small xz inflate) and says whether the list is ready afterwards:
    /// the post-reveal schedule's first try, before it opens any book for the walk.
    @discardableResult
    func prepareFromBundle() -> Bool {
        lock.lock()
        if ready { lock.unlock(); return true }
        if building {
            lock.unlock()
            built.wait()
            return isReady
        }
        building = true
        built.enter()
        lock.unlock()
        defer { built.leave() }
        if let words = Self.loadBundledWords() {
            install(words: words)
            return true
        }
        lock.lock(); building = false; lock.unlock()
        return false
    }

    #if DEBUG
    /// "-exportHadithVocabulary": the walk's list, written to Documents/hadith-vocabulary.txt behind
    /// the shelf fingerprint line, for Scripts/build_hadith_vocabulary.py.
    static func exportList(books: [HadithBookData]) {
        let words = collectWords(books: books)
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = documents.appendingPathComponent("hadith-vocabulary.txt")
        let text = headerPrefix + shelfFingerprint + "\n" + words.joined(separator: "\n") + "\n"
        try? text.write(to: url, atomically: true, encoding: .utf8)
        print("VOCAB EXPORT \(words.count) words from \(books.count) books -> \(url.path)")
    }
    #endif

    private let lock = NSLock()
    /// The space-joined words as bytes (the substring test) and by length as bytes (the edit-distance
    /// walk, which used to allocate a `[Character]` per candidate).
    private var blob: [UInt8] = []
    private var byLength: [Int: [QuranRankedSearch.VocabularyWord]] = [:]
    private var ready = false
    private var building = false
    /// Entered while a build runs; a query that needs the list waits on it instead of polling.
    private let built = DispatchGroup()

    private static let minLength = 4
    private static let longWord = 7

    var isReady: Bool {
        lock.lock(); defer { lock.unlock() }
        return ready
    }

    /// The walk's cache, scoped to the shelf it was built from so a pack update can never read back
    /// the words of the old packs.
    private static var fileURL: URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        return base.appendingPathComponent("hadith-vocabulary-\(shelfFingerprint).txt")
    }

    /// Builds (or reloads) the list in the background. Cheap to call: a second call while the first is
    /// running, or once the list is ready, does nothing.
    func prepare(books: [HadithBookData]) {
        lock.lock()
        if ready || building { lock.unlock(); return }
        building = true
        built.enter()
        lock.unlock()
        Task.detached(priority: .utility) { [self] in
            build(books: books)
        }
    }

    /// The same build, on the caller's thread: the ranked search's own background task calls this
    /// before parsing, so the very first query still gets its typo corrected (the list is on disk
    /// after that, and a reload is a file read). A build already running elsewhere is waited for.
    func buildIfNeeded(books: [HadithBookData]) {
        lock.lock()
        if ready { lock.unlock(); return }
        if building {
            lock.unlock()
            built.wait()
            return
        }
        building = true
        built.enter()
        lock.unlock()
        build(books: books)
    }

    /// Only the whole shelf makes a list worth keeping: a search typed before the launch sweep had
    /// opened every book used to write a partial vocabulary to disk and read it back forever.
    private static func isWholeShelf(_ books: [HadithBookData]) -> Bool {
        books.count >= HadithCatalogBook.all.count
    }

    private func build(books: [HadithBookData]) {
        defer { built.leave() }
        // The shipped list first: no book is touched when it matches the shelf.
        if let words = Self.loadBundledWords() {
            install(words: words)
            return
        }
        if let url = Self.fileURL, let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty {
            install(words: text.split(separator: "\n").map(String.init))
            return
        }
        guard Self.isWholeShelf(books) else {
            lock.lock()
            building = false
            lock.unlock()
            return
        }
        let sorted = Self.collectWords(books: books)
        if let url = Self.fileURL {
            try? sorted.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        }
        install(words: sorted)
    }

    /// The walk itself: every 4-24 letter lowercase ASCII word of every book's English search folds,
    /// sorted. The export and the fallback build share it, which is what keeps the shipped list honest.
    private static func collectWords(books: [HadithBookData]) -> [String] {
        var words = Set<String>()
        for data in books {
            data.pack.scanSearchFolds(in: 0..<data.hadiths.count, isArabic: false) { _, fold in
                var start = 0
                let count = fold.count
                var index = 0
                while index <= count {
                    let atEnd = index == count
                    let byte = atEnd ? 0x20 : fold[index]
                    if byte == 0x20 || byte == 0x0A || byte == 0x09 || byte == 0x0D {
                        let length = index - start
                        if length >= minLength, length <= 24 {
                            var isWord = true
                            for offset in start..<index where !(0x61...0x7A).contains(fold[offset]) { isWord = false; break }
                            if isWord, let word = String(bytes: UnsafeBufferPointer(rebasing: fold[start..<index]), encoding: .utf8) {
                                words.insert(word)
                            }
                        }
                        start = index + 1
                    }
                    index += 1
                }
            }
        }
        return words.sorted()
    }

    private func install(words: [String]) {
        var byLength: [Int: [QuranRankedSearch.VocabularyWord]] = [:]
        for word in words { byLength[word.utf8.count, default: []].append(QuranRankedSearch.VocabularyWord(Array(word.utf8))) }
        lock.lock()
        blob = Array((" " + words.joined(separator: " ") + " ").utf8)
        self.byLength = byLength
        ready = true
        building = false
        lock.unlock()
    }

    private static func occurs(_ needle: [UInt8], in haystack: [UInt8]) -> Bool {
        guard !needle.isEmpty, haystack.count >= needle.count else { return false }
        return haystack.withUnsafeBufferPointer { text in
            needle.withUnsafeBufferPointer { pattern in
                guard let base = text.baseAddress, let patternBase = pattern.baseAddress else { return false }
                return memmem(base, text.count, patternBase, pattern.count) != nil
            }
        }
    }

    /// The library word a mistyped one most likely meant, or nil to leave it be. Anything the library
    /// already uses ANYWHERE as a substring is left alone: a half-typed "intent" is a prefix, not a typo.
    func nearestWord(to token: String) -> String? {
        guard token.count >= Self.minLength, HadithRankedSearch.isLatinWord(token) else { return nil }
        lock.lock(); defer { lock.unlock() }
        let bytes = Array(token.utf8)
        guard ready, !Self.occurs(bytes, in: blob) else { return nil }
        let max = token.count >= Self.longWord ? 2 : 1
        let mask = QuranRankedSearch.VocabularyWord.letterMask(of: bytes)
        var best: [UInt8]?
        var bestDistance = max + 1
        for length in (bytes.count - max)...(bytes.count + max) {
            for candidate in byLength[length] ?? [] {
                guard candidate.mayBeWithin(max, of: mask) else { continue }
                let distance = QuranRankedSearch.boundedEditDistance(bytes, candidate.bytes, max: max)
                if distance < bestDistance {
                    bestDistance = distance
                    best = candidate.bytes
                    if distance == 1 { return String(decoding: candidate.bytes, as: UTF8.self) }
                }
            }
        }
        return best.map { String(decoding: $0, as: UTF8.self) }
    }
}
