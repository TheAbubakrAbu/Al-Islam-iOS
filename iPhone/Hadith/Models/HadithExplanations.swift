import Foundation

// Which narrations the Hadith Encyclopedia (hadeethenc.com, HadeethEncView.swift) explains, joined
// ahead of time by Scripts/build_hadith_explanations.py (Abu, 2026-11-02: "bring hadith explanation")
// and shipped as Resources/Data/Hadith/HadithExplanations.qpk in the HadithChains.qpk shape: one
// block per book of `u32 idInBook` ascending, `u32 offsets`, then the encyclopedia entry ids (ASCII)
// back to back. A row asks a binary search; the sheet then opens the entry through `HadeethEncStore`.

/// The pack: a book table in the eager section, a `HadithRowBlock` per book.
final class HadithExplanationPack: @unchecked Sendable {
    struct Book {
        let block: Int
        let count: Int
    }

    let books: [String: Book]
    /// Every book's linked rows together: the header's unit count.
    let rowCount: Int
    private let container: QuranPackContainer

    static func bundledURL() -> URL? {
        Bundle.main.url(forResource: "HadithExplanations", withExtension: "qpk", subdirectory: "Data/Hadith")
            ?? Bundle.main.url(forResource: "HadithExplanations", withExtension: "qpk", subdirectory: "Hadith")
            ?? Bundle.main.url(forResource: "HadithExplanations", withExtension: "qpk")
    }

    init?(url: URL) {
        guard let container = QuranPackContainer(url: url, budget: 512 * 1024) else { return nil }
        var reader = QuranPackReader(bytes: container.eager)
        let count = reader.u32()
        guard count > 0, count == container.recordCount, count == container.blockCount else { return nil }
        var books: [String: Book] = [:]
        var total = 0
        for block in 0..<count {
            let slug = reader.string()
            let rows = reader.u32()
            guard !slug.isEmpty, rows > 0 else { return nil }
            books[slug] = Book(block: block, count: rows)
            total += rows
        }
        guard reader.remaining == 0, total == container.unitCount else { return nil }
        self.books = books
        self.rowCount = total
        self.container = container
    }

    /// The encyclopedia entry explaining the row, or nil when the script linked none.
    func entryID(slug: String, idInBook: Int) -> String? {
        withBlock(slug) { block, count in
            block.index(of: idInBook, count: count).flatMap { block.code(at: $0, count: count) }
        } ?? nil
    }

    /// A binary search and nothing more: what a row asks on every render.
    func contains(slug: String, idInBook: Int) -> Bool {
        withBlock(slug) { block, count in block.index(of: idInBook, count: count) != nil } ?? false
    }

    /// Every linked row of a book in `idInBook` order, for the tests.
    func entries(slug: String) -> [(idInBook: Int, entry: String)] {
        withBlock(slug) { block, count in
            (0..<count).compactMap { index in
                block.code(at: index, count: count).map { (idInBook: block.u32(4 * index), entry: $0) }
            }
        } ?? []
    }

    func purge() { container.purge() }

    private func withBlock<T>(_ slug: String, _ body: (HadithRowBlock, Int) -> T) -> T? {
        guard let book = books[slug], let bytes = container.block(book.block),
              bytes.count >= 8 * book.count + 4 else { return nil }
        return body(HadithRowBlock(bytes: bytes), book.count)
    }
}

/// The pack opened once for the app, like `HadithChainStore`: not observable, a row's `hasExplanation`
/// is always the true answer (the first ask inflates the book's block, a moment).
final class HadithExplanationStore: @unchecked Sendable {
    static let shared = HadithExplanationStore()
    private init() {}

    private let lock = NSLock()
    private var opened = false
    private var openedPack: HadithExplanationPack?

    /// The pack, opened once; nil for good when it is missing or does not parse (no explanation is offered).
    var pack: HadithExplanationPack? {
        lock.lock()
        defer { lock.unlock() }
        if !opened {
            opened = true
            openedPack = HadithExplanationPack.bundledURL().flatMap(HadithExplanationPack.init(url:))
        }
        return openedPack
    }

    /// Opens the pack and inflates one book's block off the main thread, as the book screen appears.
    func prewarm(slug: String) {
        DispatchQueue.global(qos: .utility).async {
            _ = self.pack?.contains(slug: slug, idInBook: 0)
        }
    }

    func hasExplanation(slug: String, idInBook: Int) -> Bool {
        pack?.contains(slug: slug, idInBook: idInBook) ?? false
    }

    /// The Hadith Encyclopedia entry id (`HadeethEncEntry.id`) explaining the row, or nil.
    func explanationID(slug: String, idInBook: Int) -> String? {
        pack?.entryID(slug: slug, idInBook: idInBook)
    }

    /// Memory pressure (`MemoryTrim`): the decompressed books go; the next row to ask inflates its own again.
    func purge() {
        lock.lock()
        let loaded = openedPack
        lock.unlock()
        loaded?.purge()
    }
}
