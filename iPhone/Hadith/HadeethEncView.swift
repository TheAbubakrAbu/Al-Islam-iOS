#if os(iOS)
import SwiftUI
import UIKit

// The Hadith Encyclopedia (الموسوعة الحديثية, hadeethenc.com): 2,328 narrations, each with a
// scholarly explanation, a list of benefits, its grading and its takhrij reference, in Arabic and
// English, under a tree of 452 topics. Prepared under the supervision of the Dawah and Guidance
// Association and the Association for Serving Islamic Content in Languages; ported to the app from
// Tilawa (Jamil Hammoudeh), with permission.
//
// The data is `Resources/Data/Hadith/HadeethEnc.henc` (Scripts/build_hadeethenc_pack.py): a small
// header (the topic tree and one light row per narration) and nineteen xz blocks of 128 full
// narrations, read on demand (Tilawa Guide, decision A, 2026-09-07). The door parses the header
// alone, a narration inflates its block, and the search folds are built from every block on the
// first search of a language; nothing here holds 14 MB of parsed JSON any more. The site's terms
// allow reuse on two conditions: nothing is modified, added or removed, and the source is credited.
// So the texts render exactly as published, and every screen here carries the credit.

// MARK: - Model

struct HadeethEncCategory: Identifiable, Hashable {
    let id: String
    let parent: String?
    let english: String
    let arabic: String
    /// Narrations filed directly under this topic, and under it and every topic beneath it.
    let direct: Int
    let total: Int
}

/// One narration as the lists show it: the header's light row (the English title, intro, grade and
/// attribution beside the id and topics), so a row never touches a block.
struct HadeethEncEntry: Identifiable, Hashable {
    let id: String
    /// Position in the pack's id order: names the block it lives in and its fold row.
    let index: Int
    let categories: [String]
    let title: String
    let intro: String
    let grade: String
    let attribution: String
}

struct HadeethEncHadith: Identifiable {
    struct Layer {
        let title: String
        let intro: String
        let body: String
        let explanation: String
        let benefits: [String]
        let attribution: String
        let grade: String
        let reference: String
    }

    let id: String
    let categories: [String]
    let arabic: Layer
    let english: Layer

    /// The whole entry as plain text, for copying and sharing, source included.
    var plainText: String {
        var parts: [String] = []
        if !arabic.body.isEmpty { parts.append(arabic.body) }
        if !english.body.isEmpty { parts.append(english.body) }
        let grading = [english.attribution, english.grade].filter { !$0.isEmpty }.joined(separator: " · ")
        if !grading.isEmpty { parts.append(grading) }
        if !english.explanation.isEmpty { parts.append("Explanation\n" + english.explanation) }
        if !english.benefits.isEmpty { parts.append("Benefits\n" + english.benefits.map { "• " + $0 }.joined(separator: "\n")) }
        if !arabic.reference.isEmpty { parts.append(arabic.reference) }
        parts.append("Hadith Encyclopedia (hadeethenc.com), via \(AppIdentifiers.appName)")
        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Store

/// Lazy, lock-guarded, parsed off the hot path on first use, the other packs' pattern. The pack is
/// mapped, not read; the header (about 700 KB inflated) is the only part held for the session, a
/// few parsed blocks ride in a small cache, and the folds come and go with the search. `unload()`
/// hands all of it back.
final class HadeethEncStore: @unchecked Sendable {
    static let shared = HadeethEncStore()
    private init() {}

    struct Library {
        let categories: [HadeethEncCategory]
        let categoriesById: [String: HadeethEncCategory]
        let roots: [HadeethEncCategory]
        let children: [String: [HadeethEncCategory]]
        /// Every narration's light row, in the pack's id order (`HadeethEncEntry.index`).
        let entries: [HadeethEncEntry]
        let entriesById: [String: HadeethEncEntry]
        /// Narrations filed DIRECTLY under a topic, in id order.
        let directEntries: [String: [HadeethEncEntry]]

        func children(of category: HadeethEncCategory) -> [HadeethEncCategory] {
            children[category.id] ?? []
        }

        /// Every narration under a topic, its subtopics included, without repeats.
        func allEntries(under category: HadeethEncCategory) -> [HadeethEncEntry] {
            var seen = Set<String>()
            var out: [HadeethEncEntry] = []
            var queue = [category]
            while !queue.isEmpty {
                let node = queue.removeFirst()
                for entry in directEntries[node.id] ?? [] where seen.insert(entry.id).inserted {
                    out.append(entry)
                }
                queue.append(contentsOf: children(of: node))
            }
            return out.sorted { $0.index < $1.index }
        }

        /// The topic path from a root down to `category`, for a breadcrumb.
        func ancestors(of category: HadeethEncCategory) -> [HadeethEncCategory] {
            var path: [HadeethEncCategory] = []
            var current = category
            while let parentId = current.parent, let parent = categoriesById[parentId] {
                path.insert(parent, at: 0)
                current = parent
            }
            return path
        }
    }

    /// The mapped pack and its block table (the builder's layout, documented at the top of
    /// Scripts/build_hadeethenc_pack.py).
    private struct Container {
        struct Block {
            let firstEntry: Int
            let offset: Int
            let compressed: Int
            let raw: Int
        }
        let data: Data
        let blocks: [Block]
        let entriesPerBlock: Int
        let headerRange: Range<Int>
        let headerRawLength: Int
        let payloadStart: Int
        let entryCount: Int
        let treeCount: Int

        /// The block holding entry `index`, by the table (binary search on `firstEntry`).
        func blockIndex(containing index: Int) -> Int? {
            guard !blocks.isEmpty, index >= 0 else { return nil }
            var low = 0, high = blocks.count - 1
            while low < high {
                let mid = (low + high + 1) / 2
                if blocks[mid].firstEntry <= index { low = mid } else { high = mid - 1 }
            }
            return low
        }

        func inflated(block: Int) -> [UInt8]? {
            guard blocks.indices.contains(block) else { return nil }
            let row = blocks[block]
            let start = payloadStart + row.offset
            guard start >= 0, row.compressed > 0, start + row.compressed <= data.count,
                  let raw = SolidPack.xzDecompress(data.subdata(in: start..<(start + row.compressed))),
                  raw.count == row.raw else { return nil }
            return [UInt8](raw)
        }
    }

    /// One language's search text for every narration, back to back: `starts[i]..<starts[i + 1]` is
    /// narration i's whole fold (title, narration, explanation) and `starts[i]..<headEnds[i]` its
    /// head (title and narration), so a hit in what the hadith says can be told from one in the
    /// commentary on it. Built from every block on the first search of the language, off main.
    private struct FoldBlob {
        var bytes: [UInt8] = []
        var starts: [Int] = [0]
        var headEnds: [Int] = []
    }

    private let lock = NSLock()
    private var container: Container?
    private var loaded: Library?
    private var loadFailed = false
    /// Parsed blocks, the newest few: the narration being read and its neighbours.
    private var blockCache: [Int: [HadeethEncHadith]] = [:]
    private var blockOrder: [Int] = []
    private static let blockBudget = 3
    private var englishFolds: FoldBlob?
    private var arabicFolds: FoldBlob?
    /// Entered while a language's folds build; a second search waits for them instead of building twice.
    private let foldsBuilt = DispatchGroup()
    private var foldsBuilding: Set<Bool> = []

    static let isBundled: Bool = packURL() != nil

    // MARK: Opening

    func library() -> Library? {
        lock.lock()
        if let loaded { lock.unlock(); return loaded }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()
        guard let (container, parsed) = Self.load() else {
            lock.lock(); loadFailed = true; lock.unlock()
            return nil
        }
        lock.lock(); defer { lock.unlock() }
        if let loaded { return loaded }
        self.container = container
        loaded = parsed
        return parsed
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        loaded = nil
        container = nil
        loadFailed = false
        blockCache.removeAll()
        blockOrder.removeAll()
        englishFolds = nil
        arabicFolds = nil
    }

    // MARK: Narrations

    func hadith(id: String) -> HadeethEncHadith? {
        guard let entry = library()?.entriesById[id] else { return nil }
        return hadith(for: entry)
    }

    /// The full narration behind a light row: its block, inflated and parsed once and kept while
    /// it is among the newest few.
    func hadith(for entry: HadeethEncEntry) -> HadeethEncHadith? {
        guard library() != nil else { return nil }
        lock.lock()
        let container = self.container
        lock.unlock()
        guard let container, let block = container.blockIndex(containing: entry.index),
              let hadiths = parsedBlock(block, in: container) else { return nil }
        let slot = entry.index - container.blocks[block].firstEntry
        if hadiths.indices.contains(slot), hadiths[slot].id == entry.id { return hadiths[slot] }
        return hadiths.first { $0.id == entry.id }
    }

    private func parsedBlock(_ block: Int, in container: Container) -> [HadeethEncHadith]? {
        lock.lock()
        if let cached = blockCache[block] {
            blockOrder.removeAll { $0 == block }
            blockOrder.append(block)
            lock.unlock()
            return cached
        }
        lock.unlock()
        // Inflated and parsed outside the lock (milliseconds, and two readers of one block produce
        // the same rows).
        guard let raw = container.inflated(block: block) else { return nil }
        let parsed = PackTrace.measure("HadeethEnc block \(block)") { () -> (result: [HadeethEncHadith]?, bytes: Int) in
            (Self.parseBlock(raw), raw.count)
        }
        guard let parsed else { return nil }
        lock.lock(); defer { lock.unlock() }
        if let cached = blockCache[block] { return cached }
        blockCache[block] = parsed
        blockOrder.append(block)
        while blockOrder.count > Self.blockBudget, let oldest = blockOrder.first {
            blockOrder.removeFirst()
            blockCache.removeValue(forKey: oldest)
        }
        return parsed
    }

    // MARK: Search

    /// Narrations carrying every word of the query, title and body hits first. English queries read
    /// the English layer (title, narration, explanation), Arabic ones the Arabic. The folds of the
    /// language are built from every block the first time it is searched (off main: the search
    /// runs detached) and kept until a memory warning.
    func search(_ query: String, limit: Int = 60) -> [HadeethEncEntry] {
        guard let library = library() else { return [] }
        let isArabic = HadithFold.isArabicScript(query)
        var folded: [UInt8] = []
        if isArabic { Self.foldArabic(query, into: &folded) } else { Self.foldEnglish(query, into: &folded) }
        let terms = folded.split(separator: 0x20, omittingEmptySubsequences: true)
            .map(Array.init)
            .filter { term in term.reduce(0) { $0 + (($1 & 0xC0) == 0x80 ? 0 : 1) } >= 2 }
        guard !terms.isEmpty, let blob = folds(arabic: isArabic) else { return [] }
        let phrase = Array(folded.drop(while: { $0 == 0x20 }).reversed().drop(while: { $0 == 0x20 }).reversed())
        var scored: [(index: Int, score: Int)] = []
        blob.bytes.withUnsafeBufferPointer { text in
            guard let base = text.baseAddress else { return }
            func occurs(_ needle: [UInt8], in range: Range<Int>) -> Bool {
                guard !needle.isEmpty, range.count >= needle.count else { return false }
                return needle.withUnsafeBufferPointer { pattern in
                    guard let patternBase = pattern.baseAddress else { return false }
                    return memmem(base + range.lowerBound, range.count, patternBase, pattern.count) != nil
                }
            }
            let count = min(library.entries.count, blob.headEnds.count, blob.starts.count - 1)
            for index in 0..<count {
                let whole = blob.starts[index]..<blob.starts[index + 1]
                guard terms.allSatisfy({ occurs($0, in: whole) }) else { continue }
                // A hit in the title or the narration outranks one in the commentary on it.
                let head = blob.starts[index]..<blob.headEnds[index]
                var score = 0
                for term in terms where occurs(term, in: head) { score += 2 }
                if terms.count > 1, occurs(phrase, in: head) { score += 5 }
                scored.append((index, score))
            }
        }
        scored.sort { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
        return scored.prefix(limit).map { library.entries[$0.index] }
    }

    private func folds(arabic: Bool) -> FoldBlob? {
        lock.lock()
        if let ready = arabic ? arabicFolds : englishFolds { lock.unlock(); return ready }
        if foldsBuilding.contains(arabic) {
            lock.unlock()
            foldsBuilt.wait()
            lock.lock(); defer { lock.unlock() }
            return arabic ? arabicFolds : englishFolds
        }
        foldsBuilding.insert(arabic)
        foldsBuilt.enter()
        let container = self.container
        lock.unlock()
        defer {
            lock.lock()
            foldsBuilding.remove(arabic)
            lock.unlock()
            foldsBuilt.leave()
        }
        guard let container else { return nil }
        let built = PackTrace.measure("HadeethEnc folds \(arabic ? "ar" : "en")") { () -> (result: FoldBlob, bytes: Int) in
            var blob = FoldBlob()
            blob.bytes.reserveCapacity(4 * 1024 * 1024)
            blob.starts.reserveCapacity(container.entryCount + 1)
            blob.headEnds.reserveCapacity(container.entryCount)
            for block in container.blocks.indices {
                // Not through the block cache: the reader's blocks stay, this pass is one-shot.
                guard let raw = container.inflated(block: block), let hadiths = Self.parseBlock(raw) else { continue }
                for hadith in hadiths {
                    let layer = arabic ? hadith.arabic : hadith.english
                    Self.appendFold(of: layer, arabic: arabic, into: &blob)
                }
            }
            return (blob, blob.bytes.count)
        }
        lock.lock(); defer { lock.unlock() }
        if arabic { arabicFolds = built } else { englishFolds = built }
        return built
    }

    /// The whole fold (title, narration, explanation) with its head length, the parts joined by
    /// single spaces and empty parts skipped, so the head is always a prefix of the whole.
    private static func appendFold(of layer: HadeethEncHadith.Layer, arabic: Bool, into blob: inout FoldBlob) {
        let start = blob.bytes.count
        var wrote = false
        func append(_ text: String) {
            guard !text.isEmpty else { return }
            let before = blob.bytes.count
            if wrote { blob.bytes.append(0x20) }
            if arabic { foldArabic(text, into: &blob.bytes) } else { foldEnglish(text, into: &blob.bytes) }
            if blob.bytes.count == before + (wrote ? 1 : 0) {
                // The part folded to nothing: take back the separator.
                blob.bytes.removeLast(blob.bytes.count - before)
            } else {
                wrote = true
            }
        }
        append(layer.title)
        append(layer.body)
        blob.headEnds.append(blob.bytes.count)
        append(layer.explanation)
        blob.starts.append(blob.bytes.count)
        _ = start
    }

    // MARK: Folds

    /// `IslamArticles.fold` over bytes: ASCII letters lowercased and digits kept, every other ASCII
    /// byte a space, non-ASCII scalars through the rule itself (`CharacterSet.alphanumerics` after
    /// lowercasing). The per-scalar `Character` boxing of the String version was most of the 1.6 s
    /// the folds used to cost. The query folds through this same function, so the two agree byte
    /// for byte ("-auditPacks" also checks it against the String version over every narration).
    static func foldEnglish(_ text: String, into out: inout [UInt8]) {
        for scalar in text.unicodeScalars {
            let value = scalar.value
            if value < 0x80 {
                switch value {
                case 0x41...0x5A: out.append(UInt8(value + 32))
                case 0x61...0x7A, 0x30...0x39: out.append(UInt8(value))
                default: out.append(0x20)
                }
            } else {
                for lowered in String(scalar).lowercased().unicodeScalars {
                    if CharacterSet.alphanumerics.contains(lowered) {
                        UTF8.encode(lowered) { out.append($0) }
                    } else {
                        out.append(0x20)
                    }
                }
            }
        }
    }

    /// Punctuation, symbols and marks, minus the boolean-search operators (`HadithFold.arabic`'s set).
    private static let unwantedSet: CharacterSet = {
        var set = CharacterSet.punctuationCharacters.union(.symbols).union(.nonBaseCharacters)
        set.remove(charactersIn: "&|!#")
        return set
    }()
    private static let whitespaceSet = CharacterSet.whitespacesAndNewlines
    /// Tashkeel, the Quranic annotation signs and the loose marks (`HadithFold.arabic`'s strip).
    private static func isStripped(_ value: UInt32) -> Bool {
        (0x064B...0x065F).contains(value) || (0x06D6...0x06ED).contains(value)
            || value == 0x0670 || value == 0x0657 || value == 0x0674 || value == 0x0656
    }

    /// `HadithFold.arabic` over bytes, in one pass: the canonical letter folds (hamza carriers, the
    /// dagger and wasl alifs, alif maqsurah, teh marbuta), the punctuation, symbol and mark strip,
    /// ASCII lowercased, whitespace runs collapsed to one space with none at the ends, the tashkeel
    /// and signs dropped. Same agreement rule as the English fold.
    static func foldArabic(_ text: String, into out: inout [UInt8]) {
        var pendingSpace = false
        var wroteAny = false
        func emit(_ scalar: Unicode.Scalar) {
            if pendingSpace, wroteAny { out.append(0x20) }
            pendingSpace = false
            wroteAny = true
            UTF8.encode(scalar) { out.append($0) }
        }
        for raw in text.unicodeScalars {
            var scalar = raw
            switch raw.value {
            case 0x0670, 0x0671, 0x0623, 0x0625, 0x0622, 0x0672, 0x0673, 0x0675, 0x0649: scalar = "\u{0627}"
            case 0x0624, 0x0676, 0x0677, 0x06E5: scalar = "\u{0648}"
            case 0x0626, 0x0678, 0x06E6: scalar = "\u{064A}"
            case 0x0629: scalar = "\u{0647}"
            case 0x0621, 0x0674: continue
            default: break
            }
            let value = scalar.value
            if value < 0x80 {
                switch value {
                case 0x20, 0x09...0x0D: pendingSpace = true
                case 0x41...0x5A: emit(Unicode.Scalar(UInt8(value + 32)))
                case 0x61...0x7A, 0x30...0x39, 0x26, 0x7C, 0x21, 0x23: emit(scalar)
                case 0x00...0x08, 0x0E...0x1F, 0x7F: emit(scalar)
                default: break   // ASCII punctuation and symbols: dropped
                }
                continue
            }
            // The Arabic letters and digits, the common case: no set lookups.
            if (0x0620...0x064A).contains(value) || (0x0660...0x0669).contains(value) {
                emit(scalar)
                continue
            }
            if whitespaceSet.contains(scalar) { pendingSpace = true; continue }
            if isStripped(value) || unwantedSet.contains(scalar) { continue }
            for lowered in String(scalar).lowercased().unicodeScalars { emit(lowered) }
        }
    }

    #if DEBUG
    /// "-auditPacks": how many narrations the fast folds disagree with the String folds on
    /// (`IslamArticles.fold`, `HadithFold.arabic`), per language. Zero is the contract.
    func auditFolds() -> (english: Int, arabic: Int) {
        guard let library = library() else { return (-1, -1) }
        var english = 0, arabic = 0
        for entry in library.entries {
            guard let hadith = hadith(for: entry) else { continue }
            let englishText = [hadith.english.title, hadith.english.body, hadith.english.explanation].joined(separator: " ")
            var fast: [UInt8] = []
            Self.foldEnglish(englishText, into: &fast)
            if fast != Array(IslamArticles.fold(englishText).utf8) { english += 1 }
            let arabicText = [hadith.arabic.title, hadith.arabic.body, hadith.arabic.explanation].joined(separator: " ")
            fast.removeAll(keepingCapacity: true)
            Self.foldArabic(arabicText, into: &fast)
            if fast != Array(HadithFold.arabic(arabicText).utf8) { arabic += 1 }
        }
        return (english, arabic)
    }
    #endif

    // MARK: Reading the pack

    private static func packURL() -> URL? {
        Bundle.main.url(forResource: "HadeethEnc", withExtension: "henc", subdirectory: "Data/Hadith")
            ?? Bundle.main.url(forResource: "HadeethEnc", withExtension: "henc", subdirectory: "Hadith")
            ?? Bundle.main.url(forResource: "HadeethEnc", withExtension: "henc")
    }

    private static let magic = 0x434E_4548   // "HENC", little-endian
    private static let version = 2

    private static func load() -> (Container, Library)? {
        PackTrace.measure("HadeethEnc") { () -> (result: (Container, Library)?, bytes: Int) in
            guard let url = packURL(),
                  let data = try? Data(contentsOf: url, options: [.mappedIfSafe]),
                  let container = parseContainer(data),
                  let header = SolidPack.xzDecompress(data.subdata(in: container.headerRange)),
                  header.count == container.headerRawLength,
                  let library = parseHeader([UInt8](header)) else { return (nil, 0) }
            return ((container, library), header.count)
        }
    }

    private static func parseContainer(_ data: Data) -> Container? {
        guard data.count >= 28 else { return nil }
        var reader = QuranPackReader(data: data, cursor: 0)
        guard reader.u32() == magic, reader.u16() == version else { return nil }
        let entriesPerBlock = reader.u16()
        let headerCompressed = reader.u32()
        let headerRaw = reader.u32()
        let blockCount = reader.u32()
        let entryCount = reader.u32()
        let treeCount = reader.u32()
        let tableEnd = 28 + blockCount * 16
        guard blockCount > 0, tableEnd + headerCompressed <= data.count else { return nil }
        var blocks: [Container.Block] = []
        blocks.reserveCapacity(blockCount)
        for _ in 0..<blockCount {
            blocks.append(Container.Block(firstEntry: reader.u32(), offset: reader.u32(),
                                          compressed: reader.u32(), raw: reader.u32()))
        }
        let headerRange = tableEnd..<(tableEnd + headerCompressed)
        return Container(data: data, blocks: blocks, entriesPerBlock: entriesPerBlock, headerRange: headerRange,
                         headerRawLength: headerRaw, payloadStart: headerRange.upperBound,
                         entryCount: entryCount, treeCount: treeCount)
    }

    /// A string table: u32 records, each u32 fields, each u32 length + UTF-8 (the builder's layout).
    private static func readTable(_ bytes: [UInt8], cursor: inout Int) -> [[String]]? {
        func u32() -> Int? {
            guard cursor + 4 <= bytes.count else { return nil }
            let value = Int(bytes[cursor]) | Int(bytes[cursor + 1]) << 8 | Int(bytes[cursor + 2]) << 16 | Int(bytes[cursor + 3]) << 24
            cursor += 4
            return value
        }
        guard let count = u32(), count <= 1_000_000 else { return nil }
        var records: [[String]] = []
        records.reserveCapacity(count)
        for _ in 0..<count {
            guard let fields = u32(), fields <= 64 else { return nil }
            var record: [String] = []
            record.reserveCapacity(fields)
            for _ in 0..<fields {
                guard let length = u32(), cursor + length <= bytes.count else { return nil }
                record.append(String(decoding: bytes[cursor..<(cursor + length)], as: UTF8.self))
                cursor += length
            }
            records.append(record)
        }
        return records
    }

    private static func parseHeader(_ bytes: [UInt8]) -> Library? {
        var cursor = 0
        guard let tree = readTable(bytes, cursor: &cursor), let rows = readTable(bytes, cursor: &cursor) else { return nil }

        var categories: [HadeethEncCategory] = []
        categories.reserveCapacity(tree.count)
        for node in tree where node.count >= 6 {
            categories.append(HadeethEncCategory(
                id: node[0], parent: node[1].isEmpty ? nil : node[1],
                english: node[2], arabic: node[3],
                direct: Int(node[4]) ?? 0, total: Int(node[5]) ?? 0
            ))
        }
        let byId = Dictionary(categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var children: [String: [HadeethEncCategory]] = [:]
        for category in categories {
            if let parent = category.parent { children[parent, default: []].append(category) }
        }
        let roots = categories.filter { $0.parent == nil }

        var entries: [HadeethEncEntry] = []
        var direct: [String: [HadeethEncEntry]] = [:]
        entries.reserveCapacity(rows.count)
        for (index, row) in rows.enumerated() where row.count >= 6 {
            let entry = HadeethEncEntry(
                id: row[0], index: index,
                categories: row[1].isEmpty ? [] : row[1].components(separatedBy: ","),
                title: row[2], intro: row[3], grade: row[4], attribution: row[5]
            )
            entries.append(entry)
            for category in entry.categories { direct[category, default: []].append(entry) }
        }
        guard !entries.isEmpty else { return nil }
        let entriesById = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return Library(categories: categories, categoriesById: byId, roots: roots, children: children,
                       entries: entries, entriesById: entriesById, directEntries: direct)
    }

    /// A block's narrations, in the builder's field order (Scripts/build_hadeethenc_pack.py,
    /// `FULL_FIELDS`): id, topics, then the Arabic layer's eight fields and the English layer's seven.
    private static func parseBlock(_ bytes: [UInt8]) -> [HadeethEncHadith]? {
        var cursor = 0
        guard let rows = readTable(bytes, cursor: &cursor) else { return nil }
        func benefits(_ joined: String) -> [String] {
            joined.isEmpty ? [] : joined.components(separatedBy: "\u{1F}").filter { !$0.isEmpty }
        }
        var hadiths: [HadeethEncHadith] = []
        hadiths.reserveCapacity(rows.count)
        for row in rows where row.count >= 17 {
            let arabic = HadeethEncHadith.Layer(
                title: row[2], intro: row[3], body: row[4], explanation: row[5], benefits: benefits(row[6]),
                attribution: row[7], grade: row[8], reference: row[9]
            )
            let english = HadeethEncHadith.Layer(
                title: row[10], intro: row[11], body: row[12], explanation: row[13], benefits: benefits(row[14]),
                attribution: row[15], grade: row[16], reference: ""
            )
            hadiths.append(HadeethEncHadith(
                id: row[0], categories: row[1].isEmpty ? [] : row[1].components(separatedBy: ","),
                arabic: arabic, english: english
            ))
        }
        return hadiths
    }
}

// MARK: - The door

struct HadeethEncView: View {

    @State private var library: HadeethEncStore.Library?
    @State private var searchText = ""
    @State private var results: [HadeethEncEntry] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var barsCollapsed = false
    #if DEBUG
    @State private var debugEntry: HadeethEncEntry?
    @State private var debugOpen = false
    #endif

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        let _ = RenderCounter.hit("HadeethEncView")
        List {
            if let library {
                if query.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hadith explained")
                                .font(.headline)
                            Text("\(library.entries.count.formatted()) narrations from the Hadith Encyclopedia, each with its meaning laid out by scholars, the lessons drawn from it, its grading and its sources, in Arabic and English. Browse by topic or search the texts.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    Section(header: SectionPillHeader(title: "TOPICS", count: library.roots.count)) {
                        ForEach(library.roots) { root in
                            NavigationLink(destination: LazyDestination {
                                HadeethEncCategoryView(category: root)
                            }) {
                                HadeethEncCategoryRow(category: root)
                            }
                        }
                    }

                    Section(footer: HadeethEncCreditFooter()) { EmptyView() }
                } else {
                    if results.isEmpty {
                        Section {
                            Text("No narrations carry \"\(query)\". Try one word, or browse the topics.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section(header: SectionPillHeader(title: "MATCHING HADITHS", count: results.count)) {
                            ForEach(results) { entry in
                                NavigationLink(destination: LazyDestination {
                                    HadeethEncHadithView(entry: entry)
                                }) {
                                    HadeethEncHadithRow(entry: entry, query: query).equatable()
                                }
                            }
                        }
                    }
                }
            } else {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Opening the encyclopedia…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .applyConditionalListStyle()
        .navigationTitle("Hadith Encyclopedia")
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                      placeholder: "Search the encyclopedia")
                .minimizedBarStyle(barsCollapsed)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        #if DEBUG
        .pushDestination(isPresented: $debugOpen) {
            if let debugEntry { HadeethEncHadithView(entry: debugEntry) }
        }
        #endif
        .onChange(of: searchText) { _ in runSearch() }
        .task {
            guard library == nil else { return }
            #if DEBUG
            MemoryFootprint.log("HadeethEnc before open")
            #endif
            let loaded = await Task.detached(priority: .userInitiated) { HadeethEncStore.shared.library() }.value
            library = loaded
            #if DEBUG
            MemoryFootprint.logLater("HadeethEnc after open")
            // "-hadeethEncOpen <id>" pushes one narration on top of the door.
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-hadeethEncOpen"), i + 1 < args.count,
               let entry = loaded?.entriesById[args[i + 1]] {
                debugEntry = entry
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugOpen = true }
            }
            if let i = args.firstIndex(of: "-hadeethEncSearch"), i + 1 < args.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { searchText = args[i + 1] }
            }
            #endif
        }
    }

    private func runSearch() {
        searchTask?.cancel()
        let query = self.query
        guard query.count >= 2 else {
            results = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            let found = await Task.detached(priority: .userInitiated) { HadeethEncStore.shared.search(query) }.value
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard query == self.query else { return }
                results = found
            }
        }
    }
}

private struct HadeethEncCreditFooter: View {
    var body: some View {
        Text("From the Hadith Encyclopedia (hadeethenc.com), prepared under the supervision of the Dawah and Guidance Association and the Association for Serving Islamic Content in Languages, reproduced without modification. Brought to the app from Tilawa, by Jamil Hammoudeh, with permission.")
            .font(.caption2)
    }
}

// MARK: - Topics

private struct HadeethEncCategoryRow: View {
    @Environment(\.appearance) private var appearance

    let category: HadeethEncCategory

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(category.english)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(category.arabic)
                    .font(appearance.useFontArabic
                          ? Font.arabic(appearance.islamArabicFontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2)
                          : .caption)
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .foregroundStyle(appearance.accent)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            CountPill(count: category.total)
        }
        .padding(.vertical, 2)
    }
}

struct HadeethEncCategoryView: View {
    let category: HadeethEncCategory

    @State private var children: [HadeethEncCategory] = []
    @State private var hadiths: [HadeethEncEntry] = []
    @State private var loaded = false

    var body: some View {
        let _ = RenderCounter.hit("HadeethEncCategoryView")
        List {
            if loaded {
                if !children.isEmpty {
                    Section(header: SectionPillHeader(title: "SUBTOPICS", count: children.count)) {
                        ForEach(children) { child in
                            NavigationLink(destination: LazyDestination {
                                HadeethEncCategoryView(category: child)
                            }) {
                                HadeethEncCategoryRow(category: child)
                            }
                        }
                    }
                }
                if !hadiths.isEmpty {
                    Section(header: SectionPillHeader(title: children.isEmpty ? "HADITHS" : "HADITHS IN THIS TOPIC", count: hadiths.count)) {
                        ForEach(hadiths) { entry in
                            // A hadith lists its topics, including the one you arrived from, so the
                            // pair loops. Keyed by ID: only the hadith you came FROM greys out, never
                            // every hadith just because some hadith is open.
                            OpenScreenLink(screen: .hadeethEncHadith, id: entry.id) {
                                HadeethEncHadithView(entry: entry)
                            } label: {
                                HadeethEncHadithRow(entry: entry, query: "").equatable()
                            }
                        }
                    }
                }
                if children.isEmpty, hadiths.isEmpty {
                    Section {
                        Text("No narrations are filed under this topic.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Section {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            }
        }
        .applyConditionalListStyle()
        .navigationTitle(category.english)
        .openScreen(.hadeethEncCategory, id: category.id)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !loaded else { return }
            let category = self.category
            let result = await Task.detached(priority: .userInitiated) { () -> ([HadeethEncCategory], [HadeethEncEntry]) in
                guard let library = HadeethEncStore.shared.library() else { return ([], []) }
                let children = library.children(of: category)
                // A leaf lists its own narrations; a branch lists the narrations filed directly on it,
                // and its subtopics carry the rest. The rows are light: no block is touched here.
                let rows = library.directEntries[category.id] ?? []
                return (children, rows)
            }.value
            children = result.0
            hadiths = result.1
            loaded = true
        }
    }
}

// MARK: - Rows

struct HadeethEncHadithRow: View, Equatable {
    let entry: HadeethEncEntry
    let query: String
    private let accent: Color

    init(entry: HadeethEncEntry, query: String) {
        self.entry = entry
        self.query = query
        accent = Settings.shared.accentColor.color
    }

    static func == (lhs: HadeethEncHadithRow, rhs: HadeethEncHadithRow) -> Bool {
        lhs.entry.id == rhs.entry.id && lhs.query == rhs.query && lhs.accent == rhs.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HighlightedSnippet(
                source: entry.title,
                term: query,
                font: .subheadline.weight(.semibold),
                accent: accent,
                fg: .primary,
                lineLimit: 3
            )
            if !entry.intro.isEmpty {
                Text(entry.intro)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            HStack(spacing: 6) {
                if !entry.grade.isEmpty {
                    Text(entry.grade)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(accent)
                }
                if !entry.attribution.isEmpty {
                    Text(entry.attribution)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - One narration

struct HadeethEncHadithView: View {
    @Environment(\.appearance) private var appearance

    /// The light row: the title, grade and attribution show at once; the narration itself is
    /// inflated from its block on the screen's task.
    let entry: HadeethEncEntry

    @State private var hadith: HadeethEncHadith?
    @State private var showArabicExplanation = false
    @State private var copied = false
    @State private var topics: [HadeethEncCategory] = []

    private var arabicFont: Font {
        appearance.hadithArabicWantsCustomFace
            ? Font.arabic(appearance.islamArabicFontName, size: appearance.hadithArabicFontSize)
            : .system(size: appearance.hadithArabicFontSize)
    }

    private var arabicCaptionFont: Font {
        appearance.hadithArabicWantsCustomFace
            ? Font.arabic(appearance.islamArabicFontName, size: max(15, appearance.hadithArabicFontSize - 4))
            : .system(size: max(15, appearance.hadithArabicFontSize - 4))
    }

    var body: some View {
        let _ = RenderCounter.hit("HadeethEncHadithView")
        List {
            Group {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(entry.title)
                            .font(.headline)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            if !entry.grade.isEmpty {
                                Text(entry.grade)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(appearance.accent.opacity(0.15)))
                                    .foregroundStyle(appearance.accent)
                            }
                            if !entry.attribution.isEmpty {
                                Text(entry.attribution)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                if let hadith {
                    Section(header: Text("THE HADITH")) {
                        HadithArabicText(text: hadith.arabic.body, term: "", font: arabicFont, lineSpacing: 6)
                            .textSelection(.enabled)
                        Text(hadith.english.body)
                            .font(.system(size: CGFloat(appearance.englishFontSize)))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }

                    if !hadith.english.explanation.isEmpty || !hadith.arabic.explanation.isEmpty {
                        Section(header: Text("EXPLANATION")) {
                            if !hadith.english.explanation.isEmpty {
                                ForEach(Array(paragraphs(hadith.english.explanation).enumerated()), id: \.offset) { _, paragraph in
                                    Text(paragraph)
                                        .font(.system(size: CGFloat(appearance.englishFontSize)))
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            if !hadith.arabic.explanation.isEmpty {
                                Button {
                                    Settings.shared.hapticFeedback()
                                    withAnimation { showArabicExplanation.toggle() }
                                } label: {
                                    Label(showArabicExplanation ? "Hide the Arabic explanation" : "Show the Arabic explanation",
                                          systemImage: showArabicExplanation ? "chevron.up" : "chevron.down")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(appearance.accent)
                                if showArabicExplanation {
                                    ForEach(Array(paragraphs(hadith.arabic.explanation).enumerated()), id: \.offset) { _, paragraph in
                                        Text(paragraph)
                                            .font(arabicCaptionFont)
                                            .arabicFontDesign(custom: appearance.hadithArabicWantsCustomFace)
                                            .multilineTextAlignment(.trailing)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }

                    let benefits = hadith.english.benefits.isEmpty ? hadith.arabic.benefits : hadith.english.benefits
                    if !benefits.isEmpty {
                        let arabicBenefits = hadith.english.benefits.isEmpty
                        Section(header: SectionPillHeader(title: "BENEFITS", count: benefits.count)) {
                            ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                                HStack(alignment: .top, spacing: 10) {
                                    if arabicBenefits {
                                        Text(benefit)
                                            .font(arabicCaptionFont)
                                            .arabicFontDesign(custom: appearance.hadithArabicWantsCustomFace)
                                            .multilineTextAlignment(.trailing)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                        Text("\(index + 1)")
                                            .font(.caption.weight(.semibold).monospacedDigit())
                                            .foregroundStyle(appearance.accent)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.caption.weight(.semibold).monospacedDigit())
                                            .foregroundStyle(appearance.accent)
                                            .frame(width: 18, alignment: .trailing)
                                        Text(benefit)
                                            .font(.system(size: CGFloat(appearance.englishFontSize)))
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    if !hadith.arabic.reference.isEmpty {
                        Section(header: Text("SOURCES")) {
                            ForEach(Array(paragraphs(hadith.arabic.reference, separator: "\n").enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(arabicCaptionFont)
                                    .arabicFontDesign(custom: appearance.hadithArabicWantsCustomFace)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                } else {
                    Section {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Opening the narration…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                if !topics.isEmpty {
                    Section(header: Text("TOPICS")) {
                        ForEach(topics) { topic in
                            // The other half. Only the topic you came from greys; the hadith's OTHER
                            // topics are exactly where a reader should be able to go next.
                            OpenScreenLink(screen: .hadeethEncCategory, id: topic.id) {
                                HadeethEncCategoryView(category: topic)
                            } label: {
                                HadeethEncCategoryRow(category: topic)
                            }
                        }
                    }
                }

                Section(footer: HadeethEncCreditFooter()) { EmptyView() }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Hadith \(entry.id)")
        .openScreen(.hadeethEncHadith, id: entry.id)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        guard let hadith else { return }
                        Settings.shared.hapticFeedback()
                        UIPasteboard.general.string = hadith.plainText
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copied = false } }
                    } label: {
                        Label(copied ? "Copied" : "Copy Hadith", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    Button {
                        guard let hadith else { return }
                        Settings.shared.hapticFeedback()
                        presentSystemShareSheet(items: [hadith.plainText])
                    } label: {
                        Label("Share Hadith", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .tint(appearance.accent)
                .disabled(hadith == nil)
            }
        }
        .task {
            guard hadith == nil else { return }
            let entry = self.entry
            let loaded = await Task.detached(priority: .userInitiated) { () -> (HadeethEncHadith?, [HadeethEncCategory]) in
                let store = HadeethEncStore.shared
                let hadith = store.hadith(for: entry)
                let topics = store.library().map { library in entry.categories.compactMap { library.categoriesById[$0] } } ?? []
                return (hadith, topics)
            }.value
            hadith = loaded.0
            topics = loaded.1
        }
    }

    private func paragraphs(_ text: String, separator: String = "\n\n") -> [String] {
        text.components(separatedBy: separator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
#endif
