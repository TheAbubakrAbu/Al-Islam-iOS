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

    /// Every hadith of `data` scored against `query`, best first: the strict pass, or, when nothing
    /// carries every word of a multi-word query, the relaxed one. Runs off the main thread; checks
    /// cancellation per block through the pack scanner.
    static func rank(book: HadithCatalogBook, data: HadithBookData, query: Query, requireAll: Bool) -> [Hit] {
        guard !query.isEmpty else { return [] }
        let pack = data.pack
        // The chapter and citation buckets are the same for every row of a chapter, so they are
        // scored once per chapter, not once per narration.
        struct Bucket { let score: Int; let matched: Set<Int> }
        let bookFold = query.isArabic ? HadithFold.arabic(book.arabicTitle) : HadithFold.english(book.englishTitle)
        var citationHits: [Int: Int] = [:]
        for (index, token) in query.tokens.enumerated() {
            let hit = tokenHit(token, in: bookFold, weight: citationWeight)
            if hit > 0 { citationHits[index] = hit }
        }
        var buckets: [Int: Bucket] = [:]
        for chapter in data.chapters {
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
        let rows = data.hadiths
        var hits: [Hit] = []
        pack.scanSearchFolds(in: 0..<rows.count, isArabic: query.isArabic) { row, fold in
            let chapterId = rows.indices.contains(row) ? rows[row].chapterId : -1
            let bucket = buckets[chapterId]
            var score = 0
            var matched = 0
            for (index, token) in query.tokens.enumerated() {
                let body = tokenHit(token, in: fold, weight: bodyWeight)
                let above = (bucket?.matched.contains(index) ?? false)
                if body == 0, !above {
                    if requireAll { return }
                    continue
                }
                matched += 1
                score += body
            }
            guard matched > 0 else { return }
            score += bucket?.score ?? 0
            if !requireAll { score += matched * relaxedTokenWeight }
            if query.tokens.count > 1, find(query.phrase, in: fold, wholeWord: false, wordStart: false).found {
                score += phraseBonusBody
            }
            hits.append(Hit(row: row, score: score))
        }
        return hits
    }
}

// MARK: - Vocabulary

/// Every English word the library uses, for correcting typed ones: built once from the packs' folds
/// (a walk over every search block), kept on disk, loaded on the first hadith search. Until it is
/// ready a query is simply searched as typed.
final class HadithVocabulary: @unchecked Sendable {
    static let shared = HadithVocabulary()
    private init() {}

    private let lock = NSLock()
    private var blob = ""
    private var byLength: [Int: [String]] = [:]
    private var ready = false
    private var building = false

    private static let minLength = 4
    private static let longWord = 7

    var isReady: Bool {
        lock.lock(); defer { lock.unlock() }
        return ready
    }

    private static var fileURL: URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        return base.appendingPathComponent("hadith-vocabulary-v1.txt")
    }

    /// Builds (or reloads) the list in the background. Cheap to call: a second call while the first is
    /// running, or once the list is ready, does nothing.
    func prepare(books: [HadithBookData]) {
        lock.lock()
        if ready || building { lock.unlock(); return }
        building = true
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
            var waited = 0
            while waited < 60 {
                Thread.sleep(forTimeInterval: 0.1)
                waited += 1
                if isReady { return }
            }
            return
        }
        building = true
        lock.unlock()
        build(books: books)
    }

    private func build(books: [HadithBookData]) {
        do {
            if let url = Self.fileURL, let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty {
                install(words: text.split(separator: "\n").map(String.init))
                return
            }
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
                            if length >= Self.minLength, length <= 24 {
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
            let sorted = words.sorted()
            if let url = Self.fileURL {
                try? sorted.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            }
            install(words: sorted)
        }
    }

    private func install(words: [String]) {
        var byLength: [Int: [String]] = [:]
        for word in words { byLength[word.count, default: []].append(word) }
        lock.lock()
        blob = " " + words.joined(separator: " ") + " "
        self.byLength = byLength
        ready = true
        building = false
        lock.unlock()
    }

    /// The library word a mistyped one most likely meant, or nil to leave it be. Anything the library
    /// already uses ANYWHERE as a substring is left alone: a half-typed "intent" is a prefix, not a typo.
    func nearestWord(to token: String) -> String? {
        guard token.count >= Self.minLength, HadithRankedSearch.isLatinWord(token) else { return nil }
        lock.lock(); defer { lock.unlock() }
        guard ready, !blob.contains(token) else { return nil }
        let max = token.count >= Self.longWord ? 2 : 1
        let chars = Array(token)
        var best: String?
        var bestDistance = max + 1
        for length in (token.count - max)...(token.count + max) {
            for candidate in byLength[length] ?? [] {
                let distance = QuranRankedSearch.boundedEditDistance(chars, Array(candidate), max: max)
                if distance < bestDistance {
                    bestDistance = distance
                    best = candidate
                    if distance == 1 { return best }
                }
            }
        }
        return best
    }
}
