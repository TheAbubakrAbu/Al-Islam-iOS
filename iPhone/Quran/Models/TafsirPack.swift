import Foundation
import Compression

// The reader for the app's bundled tafsir packs (.tpk) - all six editions (three English, three
// Arabic) ship INSIDE the app, so no tafsir is ever downloaded and no download settings exist.
//
// Why a pack and not the raw JSON: the six editions are ~345 MB of per-ayah JSON at the sources.
// Two things collapse that to under 19 MB bundled: grouped-ayah tafsirs repeat one passage across
// every ayah of the group (Ibn Kathir covers 6,236 ayahs with ~1,900 unique passages), so each
// UNIQUE passage is stored once behind a 6,236-entry ayah index; and the passages are LZMA-block
// compressed. Reading is: map the file (no resident cost), decompress ONE ~256 KB block, hand back
// the passage - the HadithPack shape exactly.
//
// FILE LAYOUT (little-endian throughout; written by Tafsir-Corpus/build_tpk.py and specified
// byte-for-byte in Tafsir-Corpus/TPK-FORMAT.md, with a Python reference reader in read_tpk.py)
//
//   header, 48 bytes
//     u32  magic "TFPK"
//     u16  format version (1)
//     u8   codec (2 = LZMA, the .hpk codec ids), u8 reserved
//     u16  block count, u16 reserved
//     u32  ayah entry count (6,236)
//     u32  passage count
//     u32  index offset, u32 index compressed length, u32 index raw length
//     u64  corpus fingerprint (sha256 head of the exact source text), u64 reserved
//
//   block table, 16 bytes per block, immediately after the header
//     u32  first passage id, u32 offset, u32 compressed length, u32 raw length
//
//   index section (compressed once, decompressed on open, kept resident - ~75 KB raw)
//     slug string, title string, u32 ayah count, then per ayah (12 bytes):
//       u16 surah, u16 ayah, u32 passage id, u16 group start ayah, u16 group end ayah
//     (group start/end = the contiguous run of same-passage ayahs in the surah, derived at pack
//      time; the verbatim source groupVerse, where one exists, rides with the passage itself)
//
//   per block: passage records back to back, in passage-id order
//     u8 flags (bit 0 = groupVerse present), [groupVerse string], content string
//
// Strings are u32 length + UTF-8 bytes. Passage id -> block is a binary search over the table's
// first-passage ids; the slot within the block is (id - firstPassage).

#if os(iOS)

// MARK: - Block cache

/// The decompressed passage blocks currently worth keeping, shared by every open pack and bounded
/// in BYTES. Keyed by the edition's SLUG, never by pack-object identity - a released pack's address
/// can be handed straight back to the next one allocated, and an identity key then serves one
/// edition's passage under another's heading (the bug the hadith pack verifier caught).
/// `@unchecked Sendable`: every mutable field is reached only under `lock`, and what it hands back
/// are value types the caller owns outright.
final class TafsirBlockCache: @unchecked Sendable {
    static let shared = TafsirBlockCache()

    /// One decompressed block: the passages in id order, each with its verbatim groupVerse (nil
    /// where the source carries none - all Arabic editions) and content.
    typealias PassageBlock = [(groupVerse: String?, content: String)]

    private let lock = NSLock()

    private struct Key: Hashable {
        let slug: String
        let block: Int
    }

    private var entries: [Key: PassageBlock] = [:]
    private var order: [Key] = []
    private var bytes = 0
    /// A tafsir sheet touches one block per edition, six editions worst-case (Summarize); the
    /// budget keeps a reading session's neighbourhood warm without holding a whole edition.
    private let budget = 8 * 1024 * 1024

    private func cost(_ block: PassageBlock) -> Int {
        block.reduce(0) { $0 + $1.content.utf8.count + ($1.groupVerse?.utf8.count ?? 0) + 48 }
    }

    func block(slug: String, block: Int, build: () -> PassageBlock?) -> PassageBlock? {
        let key = Key(slug: slug, block: block)
        lock.lock()
        if let hit = entries[key] {
            touch(key)
            lock.unlock()
            return hit
        }
        lock.unlock()

        // Built OUTSIDE the lock: decompression is milliseconds, and holding the lock across it
        // would serialise every reader behind one block. Two threads may build the same block at
        // once - identical content, and the accounting below charges for exactly one of them.
        guard let built = build() else { return nil }
        let builtCost = cost(built)

        lock.lock()
        if let existing = entries.updateValue(built, forKey: key) {
            bytes -= cost(existing)
        }
        touch(key)
        bytes += builtCost
        while bytes > budget, order.count > 1, let oldest = order.first {
            order.removeFirst()
            if let dropped = entries.removeValue(forKey: oldest) {
                bytes -= cost(dropped)
            }
        }
        lock.unlock()
        return built
    }

    private func touch(_ key: Key) {
        if let index = order.firstIndex(of: key) { order.remove(at: index) }
        order.append(key)
    }

    /// Everything here is rebuildable from the bundle - under memory pressure it all goes.
    func purge() {
        lock.lock()
        entries.removeAll()
        order.removeAll()
        bytes = 0
        lock.unlock()
    }
}

// MARK: - Pack

/// One bundled tafsir edition, memory-mapped. Opening a pack costs the index section (~75 KB raw:
/// the ayah map and two strings); the megabytes of passage text behind it stay on disk until an
/// ayah is asked for.
///
/// `@unchecked Sendable`: every stored property is a `let` set during init and never touched again.
/// The only shared mutable state it reaches is the block cache, which is locked.
final class TafsirPack: @unchecked Sendable {

    /// One ayah's tafsir, decoded from the pack. `groupVerse` is the source's own group sentence,
    /// verbatim, exactly as the network responses used to carry it (nil for the Arabic editions,
    /// whose source has none); `groupStart`/`groupEnd` are the pack-time derived run of ayahs in
    /// this surah sharing the passage.
    struct Entry {
        let groupVerse: String?
        let content: String
        let groupStart: Int
        let groupEnd: Int
    }

    private struct Block {
        let firstPassage: Int
        let offset: Int
        let length: Int
        let rawLength: Int
    }

    private struct AyahRecord {
        let passage: Int32
        let groupStart: UInt16
        let groupEnd: UInt16
    }

    let slug: String
    let title: String

    private let data: Data
    private let blocks: [Block]
    /// (surah << 16 | ayah) -> record. 6,236 entries, resident for the life of the pack.
    private let index: [Int32: AyahRecord]

    // MARK: Opening

    /// The pack file for a slug, wherever Xcode put it in the bundle (flat, or under the Data
    /// group's folder). Probed once per slug by the store, never from a render path.
    static func bundledURL(_ slug: String) -> URL? {
        Bundle.main.url(forResource: slug, withExtension: "tpk")
            ?? Bundle.main.url(forResource: slug, withExtension: "tpk", subdirectory: "Tafsir")
            ?? Bundle.main.url(forResource: slug, withExtension: "tpk", subdirectory: "Data/Tafsir")
    }

    init?(slug: String, url: URL) {
        // Mapped, not read: the compressed text never enters the app's footprint, and the pages
        // that do get touched are clean file-backed pages the OS can evict for free.
        guard let mapped = try? Data(contentsOf: url, options: [.mappedIfSafe]), mapped.count >= 48 else {
            return nil
        }
        self.data = mapped

        // Strict header check: wrong magic or version = not our file, refuse it whole.
        var header = TafsirPackReader(data: mapped, cursor: 0)
        guard header.u32() == 0x4B50_4654, header.u16() == 1 else { return nil }
        guard header.u8() == 2 else { return nil }   // LZMA is the only v1 codec
        _ = header.u8()
        let blockCount = header.u16()
        _ = header.u16()
        _ = header.u32()                             // ayah count - the index section repeats it
        _ = header.u32()                             // passage count - implied by the blocks
        let indexOffset = header.u32()
        let indexLength = header.u32()
        let indexRawLength = header.u32()

        // Counts are bounded by what the buffer could actually hold before anything reserves
        // against them - a truncated file must not hand `reserveCapacity` garbage.
        var table: [Block] = []
        let blocksAvailable = max(0, (mapped.count - 48) / 16)
        let readableBlocks = min(blockCount, blocksAvailable)
        table.reserveCapacity(readableBlocks)
        var reader = TafsirPackReader(data: mapped, cursor: 48)
        for _ in 0..<readableBlocks {
            table.append(Block(
                firstPassage: reader.u32(),
                offset: reader.u32(), length: reader.u32(), rawLength: reader.u32()
            ))
        }
        self.blocks = table

        guard let raw = Self.decompress(mapped, offset: indexOffset, length: indexLength,
                                        rawLength: indexRawLength) else { return nil }
        var indexReader = TafsirPackReader(bytes: raw)
        let storedSlug = indexReader.string()
        title = indexReader.string()
        // The slug inside the file must be the slug asked for - a renamed or shuffled pack would
        // otherwise serve one edition's text under another's name.
        guard storedSlug == slug else { return nil }
        self.slug = slug

        var map: [Int32: AyahRecord] = [:]
        // Each ayah record is exactly 12 bytes.
        let ayahCount = min(indexReader.u32(), indexReader.remaining / 12)
        map.reserveCapacity(ayahCount)
        for _ in 0..<ayahCount {
            let surah = indexReader.u16()
            let ayah = indexReader.u16()
            let passage = indexReader.u32()
            let start = indexReader.u16()
            let end = indexReader.u16()
            map[Int32(surah) << 16 | Int32(ayah)] = AyahRecord(
                passage: Int32(truncatingIfNeeded: passage),
                groupStart: UInt16(truncatingIfNeeded: start),
                groupEnd: UInt16(truncatingIfNeeded: end)
            )
        }
        index = map
    }

    // MARK: Reading

    /// This edition's tafsir for one ayah - one index lookup and one (cached) block decode.
    func entry(surah: Int, ayah: Int) -> Entry? {
        guard surah > 0, surah <= 114, ayah > 0, ayah <= 0xFFFF,
              let record = index[Int32(surah) << 16 | Int32(ayah)] else { return nil }
        guard let passage = passage(Int(record.passage)) else { return nil }
        return Entry(
            groupVerse: passage.groupVerse,
            content: passage.content,
            groupStart: Int(record.groupStart),
            groupEnd: Int(record.groupEnd)
        )
    }

    private func passage(_ id: Int) -> (groupVerse: String?, content: String)? {
        // Binary search the block table by first-passage id.
        guard !blocks.isEmpty, id >= 0 else { return nil }
        var low = 0, high = blocks.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            if blocks[mid].firstPassage <= id { low = mid } else { high = mid - 1 }
        }
        guard let passages = passageBlock(low) else { return nil }
        let slot = id - blocks[low].firstPassage
        guard slot >= 0, slot < passages.count else { return nil }
        return passages[slot]
    }

    private func passageBlock(_ blockIndex: Int) -> TafsirBlockCache.PassageBlock? {
        TafsirBlockCache.shared.block(slug: slug, block: blockIndex) { [self] in
            let block = blocks[blockIndex]
            guard let raw = Self.decompress(data, offset: block.offset, length: block.length,
                                            rawLength: block.rawLength) else { return nil }
            var reader = TafsirPackReader(bytes: raw)
            var passages: TafsirBlockCache.PassageBlock = []
            passages.reserveCapacity(64)
            while reader.remaining >= 5 {
                let flags = reader.u8()
                let groupVerse = flags & 1 != 0 ? reader.string() : nil
                passages.append((groupVerse: groupVerse, content: reader.string()))
            }
            return passages
        }
    }

    // MARK: Decompression

    /// The packs are standard xz streams; `COMPRESSION_LZMA` decodes them directly.
    private static func decompress(_ data: Data, offset: Int, length: Int, rawLength: Int) -> [UInt8]? {
        guard length > 0, rawLength > 0, offset >= 0, offset + length <= data.count else { return nil }
        var output = [UInt8](repeating: 0, count: rawLength)
        let written = data.withUnsafeBytes { source -> Int in
            guard let base = source.baseAddress else { return 0 }
            return output.withUnsafeMutableBufferPointer { destination in
                compression_decode_buffer(
                    destination.baseAddress!, rawLength,
                    base.advanced(by: offset).assumingMemoryBound(to: UInt8.self), length,
                    nil, COMPRESSION_LZMA
                )
            }
        }
        return written == rawLength ? output : nil
    }
}

// MARK: - Reader

/// A cursor over pack bytes - HadithPack's PackReader, for the .tpk layout (nothing in the file is
/// guaranteed to land on its natural alignment, so every integer is assembled byte by byte).
private struct TafsirPackReader {
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
