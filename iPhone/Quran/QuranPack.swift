import Foundation
import Compression

// Readers for the bundled Quran packs (.qpk) - the Quran, the seven qiraat, and the
// "about this surah" prose all ship INSIDE the app, and nothing the reader isn't looking at
// is ever in memory.
//
// Why a pack and not the raw JSON: the three payloads are ~17 MB of JSON. Bundled as-is that
// is 17 MB of install footprint, decoded on first launch into a binary-plist cache written to
// Application Support - so the device pays TWICE, once in the bundle and again in derived
// cache, and the first launch pays the whole decode. The packs are 3.1 MB total, they ARE the
// decoded form, and reading is: map the file (no resident cost), decompress one block, hand
// back the values inside it.
//
// FILE LAYOUT (little-endian throughout; written by Quran-Tajweed-Engine/tools/pack/pack-quran.swift)
//
//   header, 48 bytes
//     u32  magic "QRPK"
//     u16  format version (1)
//     u8   eager codec, u8 block codec
//     u16  block count, u16 reserved
//     u32  record count      surahs (114) / readings (7) / infos (114)
//     u32  unit count        ayahs (6236) / total ayah rows / total sources
//     u32  eager offset, u32 eager compressed length, u32 eager raw length
//     u64  source fingerprint (FNV-1a over the JSON this was built from)
//     u64  reserved
//
//   block table, 16 bytes per block, immediately after the header
//     u32  first record, u32 offset, u32 compressed length, u32 raw length
//
//   eager section  - per-pack; see each reader below
//   blocks         - the large text, one decompression per read
//
// Strings are u32 length + UTF-8 bytes. Records are not naturally aligned; every integer is
// assembled byte by byte.
//
// The format is specified independently in Quran-Tajweed-Engine/docs/09-qpk-format.md.

// MARK: - Cursor

/// A cursor over pack bytes. Bounds-checked: a truncated or corrupt file yields empty values
/// rather than trapping, which matters because these are read from a mapped file.
struct QuranPackReader {
    private let data: Data?
    private let bytes: [UInt8]
    private(set) var cursor: Int

    init(data: Data, cursor: Int) { self.data = data; self.bytes = []; self.cursor = cursor }
    init(bytes: [UInt8]) { self.data = nil; self.bytes = bytes; self.cursor = 0 }

    var count: Int { data?.count ?? bytes.count }
    var remaining: Int { count - cursor }

    private func byte(_ i: Int) -> UInt8 {
        if let data { return data[data.startIndex + i] }
        return bytes[i]
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

    mutating func u64() -> UInt64 {
        let low = UInt64(UInt32(truncatingIfNeeded: u32()))
        let high = UInt64(UInt32(truncatingIfNeeded: u32()))
        return low | (high << 32)
    }

    /// Steps over one length-prefixed string without decoding it.
    mutating func skipString() {
        let length = u32()
        cursor = min(cursor + max(length, 0), count)
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

// MARK: - Solid packs

/// Reader for the `.solidpack` bundles - ONE xz stream over a whole family of raw JSONs
/// (the 12 beta qiraah texts, the 19 tajweed rule files) concatenated back to back.
///
/// Why solid instead of the per-file `.json.deflate`s it replaced: the qiraah JSONs are ~97%
/// identical to each other (same Quran, different marks), so compressing them TOGETHER collapses
/// 17.6 MB of JSON into ~0.4 MB where the individual files cost 3.5 MB shipped. The cost is that
/// extracting one member decompresses the whole family (~150 ms), which only happens on a riwayah
/// switch and whose parsed result the callers (BetaQiraatStore / QiraahTajweed) already cache.
///
/// Layout after decompression (built by Scripts/build_solidpacks.py):
///   u32 LE index length, index JSON {"entries":[{"name","offset","length"},...]},
///   then the raw JSONs back to back; offsets are relative to the first byte after the index.
enum SolidPack {
    /// The raw JSON for one member, or nil if the pack or member is missing.
    static func json(named name: String, inPack pack: String) -> Data? {
        guard let url = Bundle.main.url(forResource: pack, withExtension: "solidpack")
            ?? Bundle.main.url(forResource: pack, withExtension: "solidpack", subdirectory: "Data/Quran"),
              let compressed = try? Data(contentsOf: url),
              let body = xzDecompress(compressed) else { return nil }

        var reader = QuranPackReader(data: body, cursor: 0)
        let indexLength = reader.u32()
        let payloadStart = 4 + indexLength
        guard indexLength > 0, payloadStart <= body.count,
              let index = try? JSONSerialization.jsonObject(
                  with: body.subdata(in: 4..<payloadStart)) as? [String: [[String: Any]]],
              let entries = index["entries"] else { return nil }

        for entry in entries {
            guard entry["name"] as? String == name,
                  let offset = entry["offset"] as? Int,
                  let length = entry["length"] as? Int,
                  offset >= 0, length > 0, payloadStart + offset + length <= body.count else { continue }
            return body.subdata(in: (payloadStart + offset)..<(payloadStart + offset + length))
        }
        return nil
    }

    /// Streaming xz decode (`COMPRESSION_LZMA` reads the xz container). Streamed because, unlike
    /// the qpk blocks, these files don't carry their decompressed size up front - the mushaf
    /// `.pdf.xz` facsimiles come through here too.
    static func xzDecompress(_ data: Data) -> Data? {
        let bufferSize = 1 << 20
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        // compression_stream has no empty initializer in Swift; these fields are
        // overwritten by compression_stream_init and the loop before first use.
        var stream = compression_stream(dst_ptr: buffer, dst_size: 0, src_ptr: buffer, src_size: 0, state: nil)
        guard compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_LZMA)
            == COMPRESSION_STATUS_OK else { return nil }
        defer { compression_stream_destroy(&stream) }

        var out = Data()
        let finished: Bool? = data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> Bool? in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return nil }
            stream.src_ptr = base
            stream.src_size = data.count
            while true {
                stream.dst_ptr = buffer
                stream.dst_size = bufferSize
                switch compression_stream_process(&stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue)) {
                case COMPRESSION_STATUS_END:
                    out.append(buffer, count: bufferSize - stream.dst_size)
                    return true
                case COMPRESSION_STATUS_OK:
                    // A full pass with no output and no input left would spin forever: bail.
                    guard bufferSize - stream.dst_size > 0 || stream.src_size > 0 else { return false }
                    out.append(buffer, count: bufferSize - stream.dst_size)
                default:
                    return false
                }
            }
        }
        return finished == true ? out : nil
    }
}

// MARK: - Container

/// Header, block table, and eager section of one `.qpk`. The typed readers below layer their
/// own eager parsing on top; block decompression and bounds discipline live here, once.
///
/// `@unchecked Sendable`: every stored property is a `let` set during init. Blocks are
/// decompressed on demand and the only shared mutable state is the cache, which is locked.
final class QuranPackContainer: @unchecked Sendable {

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
        let firstRecord: Int
        let offset: Int
        let compressedLength: Int
        let rawLength: Int
    }

    let recordCount: Int
    let unitCount: Int
    let sourceFingerprint: UInt64
    let eager: [UInt8]

    private let data: Data
    private let blocks: [Block]
    private let blockCodec: Codec

    private let lock = NSLock()
    private var cache: [Int: [UInt8]] = [:]
    private var order: [Int] = []
    private var cachedBytes = 0
    /// Enough for the surah being read and its neighbours. Everything here is rebuildable
    /// from the bundle, so it can all go under memory pressure.
    private let budget: Int

    init?(url: URL, budget: Int = 4 * 1024 * 1024) {
        // Mapped, not read: the compressed text never enters the app's footprint, and the
        // pages that do get touched are clean file-backed pages the OS can evict for free.
        guard let mapped = try? Data(contentsOf: url, options: [.mappedIfSafe]),
              mapped.count >= 48 else { return nil }
        self.data = mapped
        self.budget = budget

        var header = QuranPackReader(data: mapped, cursor: 0)
        guard header.u32() == 0x4B50_5251, header.u16() == 1 else { return nil }
        let eagerCodecID = header.u8()
        let blockCodecID = header.u8()
        let blockCount = header.u16()
        _ = header.u16()
        recordCount = header.u32()
        unitCount = header.u32()
        let eagerOffset = header.u32()
        let eagerLength = header.u32()
        let eagerRawLength = header.u32()
        sourceFingerprint = header.u64()
        _ = header.u64()

        guard let eagerCodec = Codec(rawValue: UInt8(truncatingIfNeeded: eagerCodecID)),
              let block = Codec(rawValue: UInt8(truncatingIfNeeded: blockCodecID)) else { return nil }
        self.blockCodec = block

        // Bound the count by what the buffer could actually hold before reserving against it:
        // a truncated file would otherwise hand `reserveCapacity` a number read out of garbage.
        var table: [Block] = []
        let available = max(0, (mapped.count - 48) / 16)
        let readable = min(blockCount, available)
        table.reserveCapacity(readable)
        var reader = QuranPackReader(data: mapped, cursor: 48)
        for _ in 0..<readable {
            table.append(Block(firstRecord: reader.u32(), offset: reader.u32(),
                               compressedLength: reader.u32(), rawLength: reader.u32()))
        }
        blocks = table

        guard let decoded = Self.decompress(mapped, offset: eagerOffset, length: eagerLength,
                                            rawLength: eagerRawLength, codec: eagerCodec) else { return nil }
        eager = decoded
    }

    var blockCount: Int { blocks.count }

    /// The decompressed bytes of one block, cached. Built OUTSIDE the lock: decompression is
    /// milliseconds, and holding the lock across it would serialise every reader behind one
    /// block. Two threads can therefore build the same block at once - they produce identical
    /// content, and the accounting below charges for exactly one of them.
    func block(_ index: Int) -> [UInt8]? {
        guard index >= 0, index < blocks.count else { return nil }
        lock.lock()
        if let hit = cache[index] {
            touch(index)
            lock.unlock()
            return hit
        }
        lock.unlock()

        let b = blocks[index]
        guard let built = Self.decompress(data, offset: b.offset, length: b.compressedLength,
                                          rawLength: b.rawLength, codec: blockCodec) else { return nil }

        lock.lock()
        if let existing = cache.updateValue(built, forKey: index) { cachedBytes -= existing.count }
        touch(index)
        cachedBytes += built.count
        while cachedBytes > budget, order.count > 1, let oldest = order.first {
            order.removeFirst()
            if let dropped = cache.removeValue(forKey: oldest) { cachedBytes -= dropped.count }
        }
        lock.unlock()
        return built
    }

    private func touch(_ index: Int) {
        if let i = order.firstIndex(of: index) { order.remove(at: i) }
        order.append(index)
    }

    func purge() {
        lock.lock()
        cache.removeAll(); order.removeAll(); cachedBytes = 0
        lock.unlock()
    }

    private static func decompress(_ data: Data, offset: Int, length: Int,
                                   rawLength: Int, codec: Codec) -> [UInt8]? {
        guard length > 0, rawLength > 0, offset >= 0, offset + length <= data.count else { return nil }
        var output = [UInt8](repeating: 0, count: rawLength)
        let written = data.withUnsafeBytes { source -> Int in
            guard let base = source.baseAddress else { return 0 }
            return output.withUnsafeMutableBufferPointer { destination in
                compression_decode_buffer(destination.baseAddress!, rawLength,
                                          base.advanced(by: offset).assumingMemoryBound(to: UInt8.self),
                                          length, nil, codec.algorithm)
            }
        }
        return written == rawLength ? output : nil
    }
}

// MARK: - quran.qpk

/// The Quran: 114 surahs and 6,236 ayahs. Everything except ayah TEXT is resident after
/// `init` - about 300 KB - which is what lets any surah open with none of its text loaded.
final class QuranPack: @unchecked Sendable {

    /// A surah's metadata. Identical in content to the JSON record minus its `ayahs`.
    struct SurahMeta {
        let id: Int
        let isMakkan: Bool
        let nameArabic: String
        let nameTransliteration: String
        let nameEnglish: String
        let revelationExceptions: String
        let numberOfAyahs: Int
        let pageStart: Int
        let pageEnd: Int
        let numberOfPages: Int
        let firstJuz: Int
        let lastJuz: Int
        let revelationOrder: Int
        let wordCount: Int
        let letterCount: Int
        let juzChangesWithinSurah: Bool
        let juzs: [Int]
        let similarNames: [String]
        /// Global row of this surah's first ayah. A surah is a SLICE of the ayah table.
        let firstRow: Int
    }

    /// Per-ayah facts small enough to keep resident for the whole Quran.
    struct AyahMeta {
        let id: Int
        let juz: Int
        let page: Int
        let wordCount: Int
        let letterCount: Int
        let block: Int
    }

    /// The four text fields of one ayah, served together - one block lookup for a row a view
    /// is about to render all of.
    struct AyahText {
        let arabic: String
        let transliteration: String
        let englishSaheeh: String
        let englishMustafa: String
    }

    let surahs: [SurahMeta]
    let ayahs: [AyahMeta]
    private let container: QuranPackContainer
    /// First ayah row of each block, computed once. Reading an ayah needs it to find the row's
    /// slot inside its block, and recovering it by scanning the row table per read would make
    /// every ayah lookup O(6236).
    private let blockFirstRow: [Int]
    /// The last block parsed into strings. The container caches decompressed BYTES, but parsing
    /// ~2,000 strings out of them per `text(row:)` call made bulk materialization O(rows × block):
    /// 6,236 ayah reads re-parsed their whole block each - seconds of launch time. Reads are
    /// sequential (bulk load) or neighbouring (the reader view), so one slot removes virtually
    /// every re-parse while holding at most one block's strings.
    private let parseLock = NSLock()
    private var parsedBlock: (index: Int, strings: [String])?

    init?(url: URL) {
        guard let container = QuranPackContainer(url: url) else { return nil }
        self.container = container

        var r = QuranPackReader(bytes: container.eager)
        // A surah record is at least 60 bytes even with every string empty; bound before reserving.
        let surahCount = min(r.u32(), max(0, r.remaining / 60) + 1)
        var metas: [SurahMeta] = []
        metas.reserveCapacity(surahCount)
        for _ in 0..<surahCount {
            let id = r.u32()
            let isMakkan = r.u8() == 1
            let nameArabic = r.string(), nameTranslit = r.string(), nameEnglish = r.string()
            let exceptions = r.string()
            let numberOfAyahs = r.u32(), pageStart = r.u32(), pageEnd = r.u32(), numberOfPages = r.u32()
            let firstJuz = r.u32(), lastJuz = r.u32(), revelationOrder = r.u32()
            let wordCount = r.u32(), letterCount = r.u32()
            let juzChanges = r.u8() == 1
            var juzs: [Int] = []
            let juzCount = min(r.u32(), max(0, r.remaining / 4))
            for _ in 0..<juzCount { juzs.append(r.u32()) }
            var similar: [String] = []
            let similarCount = min(r.u32(), max(0, r.remaining / 4))
            for _ in 0..<similarCount { similar.append(r.string()) }
            metas.append(SurahMeta(
                id: id, isMakkan: isMakkan, nameArabic: nameArabic,
                nameTransliteration: nameTranslit, nameEnglish: nameEnglish,
                revelationExceptions: exceptions, numberOfAyahs: numberOfAyahs,
                pageStart: pageStart, pageEnd: pageEnd, numberOfPages: numberOfPages,
                firstJuz: firstJuz, lastJuz: lastJuz, revelationOrder: revelationOrder,
                wordCount: wordCount, letterCount: letterCount,
                juzChangesWithinSurah: juzChanges, juzs: juzs, similarNames: similar,
                firstRow: r.u32()))
        }
        surahs = metas

        // Each ayah record is exactly 18 bytes.
        let ayahCount = min(r.u32(), max(0, r.remaining / 18))
        var rows: [AyahMeta] = []
        rows.reserveCapacity(ayahCount)
        for _ in 0..<ayahCount {
            rows.append(AyahMeta(id: r.u32(), juz: r.u16(), page: r.u16(),
                                 wordCount: r.u32(), letterCount: r.u32(), block: r.u16()))
        }
        ayahs = rows

        var firstRows = [Int](repeating: 0, count: container.blockCount)
        var seen = Set<Int>()
        for (row, ayah) in rows.enumerated() where !seen.contains(ayah.block) {
            if ayah.block >= 0 && ayah.block < firstRows.count { firstRows[ayah.block] = row }
            seen.insert(ayah.block)
        }
        blockFirstRow = firstRows
    }

    /// The four display strings of one ayah, by global row.
    func text(row: Int) -> AyahText? {
        guard row >= 0, row < ayahs.count else { return nil }
        let block = ayahs[row].block
        guard block >= 0, block < blockFirstRow.count,
              let strings = strings(inBlock: block) else { return nil }
        let slot = (row - blockFirstRow[block]) * 4
        guard slot >= 0, slot + 3 < strings.count else { return nil }
        return AyahText(arabic: strings[slot], transliteration: strings[slot + 1],
                        englishSaheeh: strings[slot + 2], englishMustafa: strings[slot + 3])
    }

    private func strings(inBlock index: Int) -> [String]? {
        parseLock.lock()
        if let parsed = parsedBlock, parsed.index == index {
            defer { parseLock.unlock() }
            return parsed.strings
        }
        parseLock.unlock()

        guard let raw = container.block(index) else { return nil }
        var reader = QuranPackReader(bytes: raw)
        var out: [String] = []
        out.reserveCapacity(2048)
        while reader.remaining >= 4 { out.append(reader.string()) }

        parseLock.lock()
        parsedBlock = (index, out)
        parseLock.unlock()
        return out
    }

    func purge() {
        parseLock.lock()
        parsedBlock = nil
        parseLock.unlock()
        container.purge()
    }
}

// MARK: - qiraat.qpk

/// The seven alternate readings. Which surahs a reading covers, and how many ayahs each has,
/// are resident; the text is decompressed only when a reading is actually displayed. Most users
/// never open one.
///
/// The seven texts share ONE solid block (Scripts/reblock_packs.py): they are ~97% the same
/// Quran with different marks, and only a compressor that sees them together can exploit that -
/// 0.47 MB shipped against 1.4 MB as seven separate blocks. The eager section still records a
/// block per reading; readings that share a block are stored back to back in eager order, and
/// `allAyahs` walks past the ones ahead of the reading it was asked for.
final class QiraatPack: @unchecked Sendable {

    struct Reading {
        let key: String
        /// surah id → ayah count, for `existsInQiraah` / `numberOfAyahs(for:)` without any text.
        let ayahCounts: [Int: Int]
        /// surah ids in the order the block stores them.
        let surahOrder: [Int]
        let block: Int
    }

    let readings: [Reading]
    private let container: QuranPackContainer

    init?(url: URL) {
        guard let container = QuranPackContainer(url: url) else { return nil }
        self.container = container

        var r = QuranPackReader(bytes: container.eager)
        let count = min(r.u32(), max(0, r.remaining / 8) + 1)
        var list: [Reading] = []
        list.reserveCapacity(count)
        for _ in 0..<count {
            let key = r.string()
            var counts: [Int: Int] = [:]
            var order: [Int] = []
            let surahCount = min(r.u32(), max(0, r.remaining / 8))
            counts.reserveCapacity(surahCount)
            order.reserveCapacity(surahCount)
            for _ in 0..<surahCount {
                let sid = r.u32()
                counts[sid] = r.u32()
                order.append(sid)
            }
            list.append(Reading(key: key, ayahCounts: counts, surahOrder: order, block: r.u16()))
        }
        readings = list
    }

    func reading(_ key: String) -> Reading? { readings.first { $0.key == key } }

    /// Every surah of one reading, walked in ONE sequential pass over its block. The per-surah
    /// accessor below re-scans the block from the start on each call; building the whole overlay
    /// through it was O(surahs²) per reading - the difference between ~1s and ~10ms at launch
    /// when a riwayah is enabled.
    func allAyahs(reading key: String) -> [(surah: Int, ayahs: [(id: Int, text: String)])]? {
        guard let reading = reading(key), let raw = container.block(reading.block) else { return nil }
        var r = QuranPackReader(bytes: raw)
        // Readings sharing this block sit back to back in eager order: step over the earlier ones.
        for earlier in readings {
            if earlier.key == key { break }
            guard earlier.block == reading.block else { continue }
            for sid in earlier.surahOrder {
                for _ in 0..<(earlier.ayahCounts[sid] ?? 0) {
                    _ = r.u32()
                    r.skipString()
                }
            }
        }
        var out: [(surah: Int, ayahs: [(id: Int, text: String)])] = []
        out.reserveCapacity(reading.surahOrder.count)
        for sid in reading.surahOrder {
            let count = reading.ayahCounts[sid] ?? 0
            var list: [(id: Int, text: String)] = []
            list.reserveCapacity(count)
            for _ in 0..<count { list.append((r.u32(), r.string())) }
            out.append((sid, list))
        }
        return out
    }


    func purge() { container.purge() }
}

// MARK: - surahinfos.qpk

/// "About this surah" prose. Source NAMES are resident so a picker can be built without touching
/// any prose; the prose itself sits in a couple of ~1 MB blocks (Scripts/reblock_packs.py merged
/// the original one-block-per-surah layout, which cost 0.24 MB more to ship). Entries that share a
/// block are stored back to back in eager order, and `sources(surah:)` walks past the earlier ones.
final class SurahInfoPack: @unchecked Sendable {

    struct Entry {
        let id: Int
        let sourceNames: [String]
        let block: Int
    }

    let entries: [Entry]
    private let container: QuranPackContainer

    init?(url: URL) {
        guard let container = QuranPackContainer(url: url) else { return nil }
        self.container = container

        var r = QuranPackReader(bytes: container.eager)
        let count = min(r.u32(), max(0, r.remaining / 10) + 1)
        var list: [Entry] = []
        list.reserveCapacity(count)
        for _ in 0..<count {
            let id = r.u32()
            var names: [String] = []
            let nameCount = min(r.u32(), max(0, r.remaining / 4))
            for _ in 0..<nameCount { names.append(r.string()) }
            list.append(Entry(id: id, sourceNames: names, block: r.u16()))
        }
        entries = list
    }

    func sourceNames(surah: Int) -> [String] {
        entries.first { $0.id == surah }?.sourceNames ?? []
    }

    /// The prose for one surah, as `(name, contents)` pairs. Decompresses that surah's block only
    /// (cached by the container, so the surahs sharing it come for free afterwards).
    func sources(surah: Int) -> [(name: String, contents: String)] {
        guard let index = entries.firstIndex(where: { $0.id == surah }),
              let raw = container.block(entries[index].block) else { return [] }
        var r = QuranPackReader(bytes: raw)
        // Entries sharing this block sit back to back in eager order: step over the earlier ones.
        for earlier in entries[..<index] where earlier.block == entries[index].block {
            for _ in earlier.sourceNames { r.skipString() }
        }
        return entries[index].sourceNames.map { ($0, r.string()) }
    }

    func purge() { container.purge() }
}

// MARK: - namesofallah.qpk

/// The 99 Names of Allah. Small enough that the whole payload IS the eager section - one LZFSE
/// decompression when the Names view first opens, zero blocks. Same container format as the
/// other packs (and built/verified by the same discipline: field-for-field against the JSON it
/// replaced).
struct NamesPack {
    struct Record {
        let number: Int
        let name: String
        let transliteration: String
        let found: String
        let meaning: String
        let desc: String
        let otherNames: [String]
    }

    let records: [Record]

    init?(url: URL) {
        guard let container = QuranPackContainer(url: url) else { return nil }
        var r = QuranPackReader(bytes: container.eager)
        let count = r.u32()
        guard count > 0, count <= 200, count == container.recordCount else { return nil }

        var list: [Record] = []
        list.reserveCapacity(count)
        for _ in 0..<count {
            let number = r.u32()
            let name = r.string()
            let transliteration = r.string()
            let found = r.string()
            let meaning = r.string()
            let desc = r.string()
            let otherCount = min(r.u32(), 16)
            var others: [String] = []
            others.reserveCapacity(otherCount)
            for _ in 0..<otherCount { others.append(r.string()) }
            list.append(Record(number: number, name: name, transliteration: transliteration,
                               found: found, meaning: meaning, desc: desc, otherNames: others))
        }
        guard r.remaining == 0 else { return nil }
        records = list
    }
}
