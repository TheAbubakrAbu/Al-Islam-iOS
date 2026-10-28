import Foundation

// Similar Hadiths: for one narration, the other rows on the shelf that carry the same text, and the
// ones that say nearly the same thing (Abu, 2026-10-27: "shows exact matches whether that be chain
// and Arabic or just Arabic ... then similar ones ... all of this preprocessed").
//
// Nothing here compares narrations. Scripts/build_similar_hadiths.py compared every row of the
// seventeen books with every other (its header says how: vowel marks and punctuation set aside, the
// chain of narrators separated from the text, wording compared by shared phrases) and shipped each
// row's list: Resources/Data/Hadith/SimilarHadiths.qpk, each match with the runs of its own text
// that the two share (Abu, later the same day: "I don't want you doing any calculations when the
// app is open ... which parts match and highlight the matched parts"). This file reads a row's
// list; the sheet paints the runs as they come.

/// One row the pack lists for a narration, in the sheet's default order (tier, then score).
struct SimilarHadithMatch: Hashable {
    enum Tier: Int, CaseIterable, Comparable {
        /// The whole Arabic is the same, chain of narrators included.
        case sameTextAndChain = 0
        /// The words after the chain are the same; the chain differs.
        case sameText = 1
        /// Enough shared phrases to be the same narration in other words, or one inside the other.
        case similar = 2

        static func < (l: Self, r: Self) -> Bool { l.rawValue < r.rawValue }
    }

    let slug: String
    let idInBook: Int
    let tier: Tier
    /// 100 for the exact tiers; for similar wording, the share of the shorter text's word pairs the
    /// other carries (40-100), or 100 for a short narration quoted whole.
    let score: Int
    /// The English translations are the same text too: a secondary mark, never a reason to match.
    let sameEnglish: Bool
    /// What the matched narration shares with the one the list is about, as UTF-16 ranges into the
    /// matched narration's own Arabic, found by the script: its whole text after the chain for the
    /// same-text tier, the two-word runs both carry for similar wording, nothing when the whole
    /// row is the same.
    let sharedRanges: [NSRange]
}

/// SimilarHadiths.qpk in the app's pack container (`QuranPackContainer`): the eager section names
/// the books in the catalog's order (a record names its book by that index) with each one's count
/// of rows that have matches, and book n's block is a `HadithRowBlock` of those rows, sorted by
/// `idInBook`, whose payloads are the records back to back: u8 book, u32 idInBook, u8 tier, u8 score,
/// u8 flags, then the runs to tint as LEB128 varints (their count, then per run the gap from the end
/// of the run before and the length, in UTF-16 units). Mapped, not read; a block is decompressed the
/// first time a row of its book asks, cached by the container, and searched where it lies.
final class SimilarHadithsPack: @unchecked Sendable {
    struct Book {
        let block: Int
        let count: Int
    }

    /// The books by block index: what a record's book byte names.
    let slugs: [String]
    let books: [String: Book]
    /// Every book's rows with matches together: the header's unit count.
    let rowCount: Int
    private let container: QuranPackContainer

    static func bundledURL() -> URL? {
        Bundle.main.url(forResource: "SimilarHadiths", withExtension: "qpk", subdirectory: "Data/Hadith")
            ?? Bundle.main.url(forResource: "SimilarHadiths", withExtension: "qpk", subdirectory: "Hadith")
            ?? Bundle.main.url(forResource: "SimilarHadiths", withExtension: "qpk")
    }

    /// Every book's block fits the cache at once (the budget only bounds a corrupt header); a memory
    /// warning still empties it (`purge`).
    init?(url: URL) {
        guard let container = QuranPackContainer(url: url, budget: 12 * 1024 * 1024) else { return nil }
        var reader = QuranPackReader(bytes: container.eager)
        let count = reader.u32()
        guard count > 0, count == container.recordCount, count == container.blockCount else { return nil }
        var slugs: [String] = []
        var books: [String: Book] = [:]
        var total = 0
        for block in 0..<count {
            let slug = reader.string()
            let rows = reader.u32()
            guard !slug.isEmpty, rows >= 0, books[slug] == nil else { return nil }
            slugs.append(slug)
            books[slug] = Book(block: block, count: rows)
            total += rows
        }
        guard reader.remaining == 0, total == container.unitCount else { return nil }
        self.slugs = slugs
        self.books = books
        self.rowCount = total
        self.container = container
    }

    /// A binary search and nothing more: what a row asks on every render.
    func contains(slug: String, idInBook: Int) -> Bool {
        withBlock(slug) { block, count in block.index(of: idInBook, count: count) != nil } ?? false
    }

    /// The row's matches in the pack's order, or [] when the script found none for it.
    func matches(slug: String, idInBook: Int) -> [SimilarHadithMatch] {
        withBlock(slug) { block, count -> [SimilarHadithMatch] in
            guard let index = block.index(of: idInBook, count: count),
                  let payload = block.payload(at: index, count: count) else { return [] }
            return decode(payload)
        } ?? []
    }

    /// Every row of a book with its matches, in `idInBook` order: for the tests.
    func rows(slug: String) -> [(idInBook: Int, matches: [SimilarHadithMatch])] {
        withBlock(slug) { block, count in
            (0..<count).compactMap { index in
                block.payload(at: index, count: count).map { (idInBook: block.id(at: index), matches: decode($0)) }
            }
        } ?? []
    }

    func purge() { container.purge() }

    private func decode(_ payload: ArraySlice<UInt8>) -> [SimilarHadithMatch] {
        var out: [SimilarHadithMatch] = []
        var at = payload.startIndex
        /// One LEB128 varint, or nil at a truncated payload (which ends the list, never traps).
        func varint() -> Int? {
            var value = 0
            var shift = 0
            while at < payload.endIndex, shift < 35 {
                let byte = Int(payload[at])
                at += 1
                value |= (byte & 0x7F) << shift
                if byte & 0x80 == 0 { return value }
                shift += 7
            }
            return nil
        }
        while at + 8 <= payload.endIndex {
            let book = Int(payload[at])
            let id = Int(payload[at + 1]) | Int(payload[at + 2]) << 8 | Int(payload[at + 3]) << 16 | Int(payload[at + 4]) << 24
            let tier = SimilarHadithMatch.Tier(rawValue: Int(payload[at + 5]))
            let score = Int(payload[at + 6])
            let flags = Int(payload[at + 7])
            at += 8
            guard let count = varint() else { break }
            var ranges: [NSRange] = []
            ranges.reserveCapacity(count)
            var end = 0
            var complete = true
            for _ in 0..<count {
                guard let gap = varint(), let length = varint() else { complete = false; break }
                ranges.append(NSRange(location: end + gap, length: length))
                end += gap + length
            }
            guard complete else { break }
            guard slugs.indices.contains(book), let tier else { continue }
            out.append(SimilarHadithMatch(slug: slugs[book], idInBook: id, tier: tier, score: score,
                                          sameEnglish: flags & 1 != 0, sharedRanges: ranges))
        }
        return out
    }

    private func withBlock<T>(_ slug: String, _ body: (HadithRowBlock, Int) -> T) -> T? {
        guard let book = books[slug], book.count > 0, let bytes = container.block(book.block),
              // The ids, the offsets, and at least the payloads' start: anything shorter is not this layout.
              bytes.count >= 8 * book.count + 4 else { return nil }
        return body(HadithRowBlock(bytes: bytes), book.count)
    }
}

/// The shipped matches, opened on first use: the chains store's shape exactly (`HadithChainStore`).
/// Opening maps the file and reads its header; a book's block is decompressed once, and from then on
/// a row's question is a binary search. The book screen inflates its book off the main thread as it
/// appears (`prewarm(slug:)`); a row that gets there first inflates it itself. Nothing is published
/// and no row observes this: a row drawn at any moment gets the true answer.
final class SimilarHadithsStore: @unchecked Sendable {
    static let shared = SimilarHadithsStore()
    private init() {}

    private let lock = NSLock()
    private var opened = false
    private var openedPack: SimilarHadithsPack?

    /// The pack, opened once; nil for good when it is missing or does not parse (nothing is offered).
    var pack: SimilarHadithsPack? {
        lock.lock()
        defer { lock.unlock() }
        if !opened {
            opened = true
            openedPack = SimilarHadithsPack.bundledURL().flatMap(SimilarHadithsPack.init(url:))
        }
        return openedPack
    }

    /// Opens the pack and inflates one book's rows off the main thread. The container decompresses
    /// outside its lock, so a row asking meanwhile never waits on this; at worst both inflate the block.
    func prewarm(slug: String) {
        DispatchQueue.global(qos: .utility).async {
            _ = self.pack?.contains(slug: slug, idInBook: 0)
        }
    }

    func hasMatches(slug: String, idInBook: Int) -> Bool {
        pack?.contains(slug: slug, idInBook: idInBook) ?? false
    }

    func matches(slug: String, idInBook: Int) -> [SimilarHadithMatch] {
        pack?.matches(slug: slug, idInBook: idInBook) ?? []
    }

    /// Memory pressure (`MemoryTrim`): the decompressed books go; the next row to ask inflates its own again.
    func purge() {
        lock.lock()
        let loaded = openedPack
        lock.unlock()
        loaded?.purge()
    }
}
