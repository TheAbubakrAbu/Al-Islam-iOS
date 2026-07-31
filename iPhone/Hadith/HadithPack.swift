import Foundation
import Compression

// The reader for the app's bundled hadith packs (.hpk) - every collection ships INSIDE the app, so
// nothing is ever downloaded, and nothing the reader isn't looking at is ever in memory.
//
// Why a pack and not the raw JSON: the 17 books are 75 MB of JSON. Bundled as-is that is 75 MB of
// install footprint, and opening one meant decoding megabytes of JSON into Swift Strings on the
// device - the whole shelf resident at once once the launch prewarm had run. The packs are 24 MB
// total, and reading is: map the file (no resident cost), decompress ONE ~256 KB block, hand back
// the strings inside it.
//
// FILE LAYOUT (little-endian throughout; written by Hadith-JSON-Engine/tools/pack/pack-hadith.swift)
//
//   header, 48 bytes
//     u32  magic "HDPK"
//     u16  format version (2)
//     u8   eager codec, u8 text codec, u8 search codec, u8 reserved
//     u16  block count
//     u32  chapter count
//     u32  hadith count
//     u32  eager offset, u32 eager compressed length, u32 eager raw length
//     u64  fold fingerprint        - the packer's HadithFold, so a drifted copy is caught
//     u64  blocked-word fingerprint - the daily-card word list the flags were computed from
//
//   block table, 28 bytes per block, immediately after the header
//     u32  first row
//     u32  text offset, u32 text compressed length, u32 text raw length
//     u32  search offset, u32 search compressed length, u32 search raw length
//
//   eager section (compressed once, read whole when the book opens - it is small)
//     4 strings: Arabic title, Arabic author, English title, English author
//     u32 chapter count, then per chapter:
//       i32 id, u32 first row, u32 row count, arabic, english, arabic fold, english fold
//     u32 hadith count, then per hadith:
//       u32 id, u32 idInBook, i32 chapterId, u16 block index, u8 flags
//
//   per block: the display payload, then the search payload
//     display: the block's strings back to back, length-prefixed, THREE per hadith in row order
//              (arabic, narrator, text) - so hadith `row` is at slot (row - firstRow) * 3
//     search:  u32 count, u32 arabic section length, then count u32 Arabic lengths and count u32
//              English lengths, then the Arabic folds NUL-terminated, then the English folds
//
// Strings are u32 length + UTF-8 bytes.

#if os(iOS)

// MARK: - Block cache

/// The decompressed blocks currently worth keeping, shared by every open pack and bounded in BYTES,
/// not in entries - one global ceiling instead of 17 books each quietly holding their own few
/// megabytes. Display and search keep separate budgets on purpose: a search sweep streams through
/// every search block in the library, and it must not be able to evict the chapter the reader is
/// looking at.
/// `@unchecked Sendable`: every mutable field is reached only under `lock`, and what it hands back
/// are value types (arrays and ranges) the caller then owns outright.
final class HadithBlockCache: @unchecked Sendable {
    static let shared = HadithBlockCache()

    /// Decompressed display strings for one block: three per hadith, in row order.
    typealias TextBlock = [String]

    /// One decompressed search block: the folds as raw UTF-8, with each record's byte range, so
    /// matching is a byte compare inside this buffer and never allocates a String.
    struct SearchBlock {
        let bytes: [UInt8]
        /// Byte range of each record's Arabic fold, indexed by (row - firstRow).
        let arabic: [Range<Int>]
        /// Byte range of each record's English fold (narration + narrator).
        let english: [Range<Int>]
    }

    private let lock = NSLock()

    /// Keyed by the book's SLUG, not by the pack object's identity: a released pack's address can be
    /// handed straight back to the next one allocated, and an `ObjectIdentifier` key then serves the
    /// old book's block to the new book. (Found by the pack verifier, which read the books in order
    /// and got Hadith Qudsi's text out of an-Nawawi's Forty.)
    private struct Key: Hashable {
        let slug: String
        let block: Int
    }

    private var textEntries: [Key: TextBlock] = [:]
    private var textOrder: [Key] = []
    private var textBytes = 0
    /// Enough for a long chapter and the ones on either side of it, at 256 KB a block.
    private let textBudget = 6 * 1024 * 1024

    private var searchEntries: [Key: SearchBlock] = [:]
    private var searchOrder: [Key] = []
    private var searchBytes = 0
    /// A sweep only ever needs the block it is on; the budget just keeps the next query's first
    /// blocks warm and covers a reader flicking between results in the same neighbourhood.
    private let searchBudget = 3 * 1024 * 1024

    private func textCost(_ block: TextBlock) -> Int {
        block.reduce(0) { $0 + $1.utf8.count + 24 }
    }

    private func searchCost(_ block: SearchBlock) -> Int {
        block.bytes.count + block.arabic.count * 32
    }

    func text(pack: HadithPack, block: Int, build: () -> TextBlock?) -> TextBlock? {
        let key = Key(slug: pack.slug, block: block)
        lock.lock()
        if let hit = textEntries[key] {
            touch(&textOrder, key)
            lock.unlock()
            return hit
        }
        lock.unlock()

        // Built OUTSIDE the lock: decompression is milliseconds, and holding the lock across it
        // would serialise every reader in the app behind one block. Two threads can therefore build
        // the same block at once - they produce identical content, and the accounting below charges
        // for exactly one of them (charging twice would leak bytes and evict a live chapter).
        guard let built = build() else { return nil }
        let cost = textCost(built)

        lock.lock()
        if let existing = textEntries.updateValue(built, forKey: key) {
            textBytes -= textCost(existing)
        }
        touch(&textOrder, key)
        textBytes += cost
        while textBytes > textBudget, textOrder.count > 1, let oldest = textOrder.first {
            textOrder.removeFirst()
            if let dropped = textEntries.removeValue(forKey: oldest) {
                textBytes -= textCost(dropped)
            }
        }
        lock.unlock()
        return built
    }

    func search(pack: HadithPack, block: Int, build: () -> SearchBlock?) -> SearchBlock? {
        let key = Key(slug: pack.slug, block: block)
        lock.lock()
        if let hit = searchEntries[key] {
            touch(&searchOrder, key)
            lock.unlock()
            return hit
        }
        lock.unlock()

        guard let built = build() else { return nil }
        let cost = searchCost(built)

        lock.lock()
        if let existing = searchEntries.updateValue(built, forKey: key) {
            searchBytes -= searchCost(existing)
        }
        touch(&searchOrder, key)
        searchBytes += cost
        while searchBytes > searchBudget, searchOrder.count > 1, let oldest = searchOrder.first {
            searchOrder.removeFirst()
            if let dropped = searchEntries.removeValue(forKey: oldest) {
                searchBytes -= searchCost(dropped)
            }
        }
        lock.unlock()
        return built
    }

    private func touch(_ order: inout [Key], _ key: Key) {
        if let index = order.firstIndex(of: key) { order.remove(at: index) }
        order.append(key)
    }

    /// Everything here is rebuildable from the bundle - under memory pressure it all goes.
    func purge() {
        lock.lock()
        textEntries.removeAll()
        textOrder.removeAll()
        textBytes = 0
        searchEntries.removeAll()
        searchOrder.removeAll()
        searchBytes = 0
        lock.unlock()
    }
}

// MARK: - Pack

/// One bundled collection, memory-mapped. Opening a pack costs the eager section (titles, chapters,
/// and the id table - under 100 KB compressed for the largest book); the 12 MB of text behind it
/// stays on disk until something asks for a hadith.
///
/// `@unchecked Sendable`: every stored property is a `let` set during init and never touched again -
/// the mapped file, the tables, the codecs. It is read from the main actor and from the detached
/// search scans at the same time by design, and the only shared mutable state it reaches is the
/// block cache, which is locked.
final class HadithPack: @unchecked Sendable {

    enum Codec: UInt8 {
        case lzfse = 1
        case lzma = 2

        var algorithm: compression_algorithm {
            switch self {
            case .lzfse: return COMPRESSION_LZFSE
            case .lzma: return COMPRESSION_LZMA
            }
        }
    }

    struct Block {
        let firstRow: Int
        let textOffset: Int
        let textLength: Int
        let textRawLength: Int
        let searchOffset: Int
        let searchLength: Int
        let searchRawLength: Int
    }

    /// A chapter, with the search folds built at pack time beside its display text - and the RANGE of
    /// rows it owns. The books lay their hadiths out in chapter order, one unbroken run per chapter
    /// (an invariant the packer checks and refuses to violate), so a chapter's hadiths are a slice of
    /// the row table rather than a filter over the whole book.
    struct Chapter {
        let id: Int
        let arabic: String
        let english: String
        let foldArabic: String
        let foldEnglish: String
        let firstRow: Int
        let rowCount: Int
    }

    /// The per-hadith facts small enough to keep resident for the whole library: 50,884 of these is
    /// about 1 MB, and it is what lets any book open instantly with none of its text loaded.
    struct Row {
        let id: Int32
        let idInBook: Int32
        let chapterId: Int32
        let block: UInt16
        /// Precomputed answers to questions that would otherwise need the hadith's TEXT. See `Flag`.
        let flags: UInt8
    }

    /// Bits in `Row.flags`, written by the packer.
    enum Flag {
        /// Short enough for a daily card in both scripts, with English text present. Objective.
        static let dailyLength: UInt8 = 1 << 0
        /// Free of the daily-card blocked words. Policy - trust it only when the fingerprints agree.
        static let dailyGentle: UInt8 = 1 << 1
    }

    let slug: String
    let arabicTitle: String
    let arabicAuthor: String
    let englishTitle: String
    let englishAuthor: String
    let chapters: [Chapter]
    let rows: [Row]

    /// The fingerprint of the fold the packer used, and of the blocked-word list the daily flags came
    /// from. The app compares its own against these before trusting prebuilt work - see
    /// `HadithPack.foldMatchesApp` and `HadithStore.isDailyWorthy`.
    let foldFingerprint: UInt64
    let blockedWordFingerprint: UInt64

    /// True when this pack's search text was folded by the same rules this build folds queries with.
    /// False means the two copies of `HadithFold.swift` drifted, and prebuilt search text cannot be
    /// trusted - the packs must be rebuilt with `tools/pack/build.sh`.
    var foldMatchesApp: Bool { foldFingerprint == HadithFold.foldFingerprint }

    private let data: Data
    private let blocks: [Block]
    private let textCodec: Codec
    private let searchCodec: Codec

    // MARK: Opening

    /// The pack file for a slug, wherever Xcode put it in the bundle (flat, or under the JSONs
    /// group's folder). Probed once per slug by the store, never from a render path.
    static func bundledURL(_ slug: String) -> URL? {
        Bundle.main.url(forResource: slug, withExtension: "hpk")
            ?? Bundle.main.url(forResource: slug, withExtension: "hpk", subdirectory: "Hadith")
            ?? Bundle.main.url(forResource: slug, withExtension: "hpk", subdirectory: "JSONs/Hadith")
    }

    init?(slug: String, url: URL) {
        // Mapped, not read: the file's 12 MB of compressed text never enters the app's footprint,
        // and the pages that do get touched are clean file-backed pages the OS can evict for free.
        guard let mapped = try? Data(contentsOf: url, options: [.mappedIfSafe]), mapped.count >= 32 else {
            return nil
        }
        self.slug = slug
        self.data = mapped

        var header = PackReader(data: mapped, cursor: 0)
        guard header.u32() == 0x4B50_4448, header.u16() == 2 else { return nil }
        let eagerCodecID = header.u8()
        let textCodecID = header.u8()
        let searchCodecID = header.u8()
        _ = header.u8()
        let blockCount = header.u16()
        _ = header.u32()                       // chapter count - the eager section repeats it
        _ = header.u32()                       // hadith count - likewise
        let eagerOffset = header.u32()
        let eagerLength = header.u32()
        let eagerRawLength = header.u32()
        foldFingerprint = header.u64()
        blockedWordFingerprint = header.u64()

        guard let eagerCodec = Codec(rawValue: UInt8(truncatingIfNeeded: eagerCodecID)),
              let text = Codec(rawValue: UInt8(truncatingIfNeeded: textCodecID)),
              let search = Codec(rawValue: UInt8(truncatingIfNeeded: searchCodecID)) else { return nil }
        self.textCodec = text
        self.searchCodec = search

        // Counts are bounded by what the buffer could actually hold before anything reserves against
        // them. A truncated or corrupted file would otherwise hand `reserveCapacity` a number read
        // out of garbage - a 4-billion-element reserve is an allocation failure, not a bad read.
        var table: [Block] = []
        let blocksAvailable = max(0, (mapped.count - 48) / 28)
        let readableBlocks = min(blockCount, blocksAvailable)
        table.reserveCapacity(readableBlocks)
        var reader = PackReader(data: mapped, cursor: 48)
        for _ in 0..<readableBlocks {
            table.append(Block(
                firstRow: reader.u32(),
                textOffset: reader.u32(), textLength: reader.u32(), textRawLength: reader.u32(),
                searchOffset: reader.u32(), searchLength: reader.u32(), searchRawLength: reader.u32()
            ))
        }
        self.blocks = table

        guard let eager = Self.decompress(mapped, offset: eagerOffset, length: eagerLength,
                                          rawLength: eagerRawLength, codec: eagerCodec) else { return nil }
        var eagerReader = PackReader(bytes: eager)
        arabicTitle = eagerReader.string()
        arabicAuthor = eagerReader.string()
        englishTitle = eagerReader.string()
        englishAuthor = eagerReader.string()

        var chapterList: [Chapter] = []
        // A chapter is an id, a row range, and four length-prefixed strings: 28 bytes even if all
        // four strings are empty.
        let chapterCount = min(eagerReader.u32(), eagerReader.remaining / 28)
        chapterList.reserveCapacity(chapterCount)
        for _ in 0..<chapterCount {
            let id = eagerReader.i32()
            let firstRow = eagerReader.u32()
            let rowCount = eagerReader.u32()
            chapterList.append(Chapter(
                id: id,
                arabic: eagerReader.string(),
                english: eagerReader.string(),
                foldArabic: eagerReader.string(),
                foldEnglish: eagerReader.string(),
                firstRow: firstRow,
                rowCount: rowCount
            ))
        }

        var rowList: [Row] = []
        // Each id record is exactly 15 bytes.
        let hadithCount = min(eagerReader.u32(), eagerReader.remaining / 15)
        rowList.reserveCapacity(hadithCount)
        for _ in 0..<hadithCount {
            rowList.append(Row(
                id: Int32(truncatingIfNeeded: eagerReader.u32()),
                idInBook: Int32(truncatingIfNeeded: eagerReader.u32()),
                chapterId: Int32(truncatingIfNeeded: eagerReader.i32()),
                block: UInt16(truncatingIfNeeded: eagerReader.u16()),
                flags: UInt8(truncatingIfNeeded: eagerReader.u8())
            ))
        }
        rows = rowList

        // A corrupt or truncated eager section can leave a chapter pointing outside the row table.
        // Clamp here, once, so no caller ever has to bounds-check a slice it was handed.
        let rowTotal = rowList.count
        chapters = chapterList.map { chapter in
            guard chapter.firstRow >= 0, chapter.firstRow <= rowTotal,
                  chapter.rowCount >= 0, chapter.firstRow + chapter.rowCount <= rowTotal else {
                return Chapter(id: chapter.id, arabic: chapter.arabic, english: chapter.english,
                               foldArabic: chapter.foldArabic, foldEnglish: chapter.foldEnglish,
                               firstRow: 0, rowCount: 0)
            }
            return chapter
        }
    }

    // MARK: Display text

    /// The three display strings of one hadith: arabic, narrator, text. Serving them together means
    /// one block lookup for a row a view is about to render all of.
    func strings(row: Int) -> (arabic: String, narrator: String, text: String) {
        guard row >= 0, row < rows.count else { return ("", "", "") }
        let blockIndex = Int(rows[row].block)
        guard blockIndex < blocks.count, let strings = textBlock(blockIndex) else { return ("", "", "") }
        let slot = (row - blocks[blockIndex].firstRow) * 3
        guard slot >= 0, slot + 2 < strings.count else { return ("", "", "") }
        return (strings[slot], strings[slot + 1], strings[slot + 2])
    }

    func string(row: Int, field: Int) -> String {
        guard row >= 0, row < rows.count else { return "" }
        let blockIndex = Int(rows[row].block)
        guard blockIndex < blocks.count, let strings = textBlock(blockIndex) else { return "" }
        let slot = (row - blocks[blockIndex].firstRow) * 3 + field
        guard slot >= 0, slot < strings.count else { return "" }
        return strings[slot]
    }

    private func textBlock(_ index: Int) -> HadithBlockCache.TextBlock? {
        HadithBlockCache.shared.text(pack: self, block: index) { [self] in
            let block = blocks[index]
            guard let raw = Self.decompress(data, offset: block.textOffset, length: block.textLength,
                                            rawLength: block.textRawLength, codec: textCodec) else { return nil }
            var reader = PackReader(bytes: raw)
            var strings: [String] = []
            strings.reserveCapacity(1024)
            while reader.remaining >= 4 {
                strings.append(reader.string())
            }
            return strings
        }
    }

    // MARK: Search

    /// Whether this hadith's prebuilt fold contains the folded query. No String is created and no
    /// normalization runs: the work that used to happen per keystroke happened once, at pack time.
    func matches(row: Int, query: HadithFold.Query) -> Bool {
        guard !query.bytes.isEmpty, row >= 0, row < rows.count else { return false }
        let blockIndex = Int(rows[row].block)
        guard blockIndex < blocks.count, let block = searchBlock(blockIndex) else { return false }
        let slot = row - blocks[blockIndex].firstRow
        let ranges = query.isArabic ? block.arabic : block.english
        guard slot >= 0, slot < ranges.count else { return false }
        let range = ranges[slot]
        // The ranges are validated when the block is built, but this is the one place that walks raw
        // memory - it re-checks rather than trust an index into a pointer.
        guard range.count >= query.bytes.count, range.lowerBound >= 0,
              range.upperBound <= block.bytes.count else { return false }

        return block.bytes.withUnsafeBufferPointer { haystack in
            query.bytes.withUnsafeBufferPointer { needle in
                memmem(haystack.baseAddress! + range.lowerBound, range.count,
                       needle.baseAddress!, needle.count) != nil
            }
        }
    }

    private func searchBlock(_ index: Int) -> HadithBlockCache.SearchBlock? {
        HadithBlockCache.shared.search(pack: self, block: index) { [self] in
            let block = blocks[index]
            guard let raw = Self.decompress(data, offset: block.searchOffset, length: block.searchLength,
                                            rawLength: block.searchRawLength, codec: searchCodec) else { return nil }
            var reader = PackReader(bytes: raw)
            // Bounded before it is reserved against, same rule as the eager section: each record
            // costs 8 bytes of lengths and two NUL terminators.
            let count = min(reader.u32(), max(0, reader.remaining - 4) / 10)
            let arabicSectionLength = reader.u32()
            var arabicLengths: [Int] = []
            arabicLengths.reserveCapacity(count)
            for _ in 0..<count { arabicLengths.append(reader.u32()) }
            var englishLengths: [Int] = []
            englishLengths.reserveCapacity(count)
            for _ in 0..<count { englishLengths.append(reader.u32()) }

            // Each record is NUL-terminated, so a match can never straddle two hadiths. Any range
            // that would run past the buffer fails the whole block rather than being handed out.
            var arabicRanges: [Range<Int>] = []
            arabicRanges.reserveCapacity(count)
            var cursor = reader.cursor
            for length in arabicLengths {
                guard length >= 0, cursor + length <= raw.count else { return nil }
                arabicRanges.append(cursor..<(cursor + length))
                cursor += length + 1
            }
            guard arabicSectionLength >= 0, reader.cursor + arabicSectionLength <= raw.count,
                  cursor <= reader.cursor + arabicSectionLength else { return nil }

            var englishRanges: [Range<Int>] = []
            englishRanges.reserveCapacity(count)
            cursor = reader.cursor + arabicSectionLength
            for length in englishLengths {
                guard length >= 0, cursor + length <= raw.count else { return nil }
                englishRanges.append(cursor..<(cursor + length))
                cursor += length + 1
            }
            guard cursor <= raw.count else { return nil }
            return HadithBlockCache.SearchBlock(bytes: raw, arabic: arabicRanges, english: englishRanges)
        }
    }

    // Chapters match through `HadithBookData.matches(_:_:)` - their folds ride in the eager section,
    // so that path needs no block at all and never comes through here.

    // MARK: Decompression

    private static func decompress(_ data: Data, offset: Int, length: Int,
                                   rawLength: Int, codec: Codec) -> [UInt8]? {
        guard length > 0, rawLength > 0, offset >= 0, offset + length <= data.count else { return nil }
        var output = [UInt8](repeating: 0, count: rawLength)
        let written = data.withUnsafeBytes { source -> Int in
            guard let base = source.baseAddress else { return 0 }
            return output.withUnsafeMutableBufferPointer { destination in
                compression_decode_buffer(
                    destination.baseAddress!, rawLength,
                    base.advanced(by: offset).assumingMemoryBound(to: UInt8.self), length,
                    nil, codec.algorithm
                )
            }
        }
        return written == rawLength ? output : nil
    }
}

// MARK: - Reader

/// A cursor over pack bytes. Every integer is assembled byte by byte - the records are 14 and 28
/// bytes wide, so nothing in the file is guaranteed to land on its natural alignment.
private struct PackReader {
    private let data: Data?
    private let bytes: [UInt8]
    private(set) var cursor: Int

    init(data: Data, cursor: Int) {
        self.data = data
        self.bytes = []
        self.cursor = cursor
    }

    init(bytes: [UInt8]) {
        self.data = nil
        self.bytes = bytes
        self.cursor = 0
    }

    var count: Int { data?.count ?? bytes.count }
    var remaining: Int { count - cursor }

    private func byte(_ index: Int) -> UInt8 {
        if let data { return data[data.startIndex + index] }
        return bytes[index]
    }

    mutating func u8() -> Int {
        guard cursor < count else { return 0 }
        defer { cursor += 1 }
        return Int(byte(cursor))
    }

    mutating func u16() -> Int {
        guard cursor + 2 <= count else { cursor = count; return 0 }
        defer { cursor += 2 }
        return Int(byte(cursor)) | Int(byte(cursor + 1)) << 8
    }

    mutating func u32() -> Int {
        guard cursor + 4 <= count else { cursor = count; return 0 }
        defer { cursor += 4 }
        return Int(byte(cursor)) | Int(byte(cursor + 1)) << 8
            | Int(byte(cursor + 2)) << 16 | Int(byte(cursor + 3)) << 24
    }

    mutating func i32() -> Int {
        Int(Int32(truncatingIfNeeded: u32()))
    }

    mutating func u64() -> UInt64 {
        let low = UInt64(UInt32(truncatingIfNeeded: u32()))
        let high = UInt64(UInt32(truncatingIfNeeded: u32()))
        return low | (high << 32)
    }

    mutating func string() -> String {
        let length = u32()
        guard length > 0, cursor + length <= count else {
            cursor = min(cursor + max(length, 0), count)
            return ""
        }
        defer { cursor += length }
        if let data {
            let start = data.startIndex + cursor
            return String(decoding: data[start..<(start + length)], as: UTF8.self)
        }
        return String(decoding: bytes[cursor..<(cursor + length)], as: UTF8.self)
    }
}

#endif
