import Foundation

// The narrators of the shelf's chains, each with every narration that names him, and the groups of
// chains that are the same chain (Abu, 2026-10-27: "click on each person in the chain and see where
// else they are mentioned and see how many they are in, how many sahih, daif, etc and how many
// Hadiths they narrated and show all of them"; "all chains that are the exact same"; "all of this
// preprocessed and efficient and done so beforehand").
//
// Nothing here counts or compares. Scripts/build_hadith_chains.py numbered every narrator of every
// chain it reads (one id per name as the shelf writes it; a relation like "أبيه" has none), numbered
// the chains that are the same chain narrator for narrator, wrote both ids into the chain codes
// (HadithChains.swift), and shipped the profiles and the lists: Resources/Data/Hadith/HadithNarrators.qpk.
// This file reads a profile, a narrator's list, or a group's members, each a binary search in one
// decompressed block.

/// The six counts a profile carries, in the pack's order (`grade_category` in the script): the
/// strongest word of each grader's verdict, "graders differ" when they disagree, "none" for a book
/// that records no grading. The two Sahihs carry no grade line by design and count as sahih.
enum HadithGradeCategory: Int, CaseIterable {
    case sahih = 0, hasan, daif, differ, other, none

    var title: String {
        switch self {
        case .sahih: return String(localized: "Sahih")
        case .hasan: return String(localized: "Hasan")
        case .daif: return String(localized: "Da'if")
        case .differ: return String(localized: "Graders differ")
        case .other: return String(localized: "Other verdicts")
        case .none: return String(localized: "No grade recorded")
        }
    }
}

/// One narration naming a narrator.
struct HadithNarratorRef: Hashable {
    enum Role: Int {
        /// Somewhere along the chain.
        case link = 0
        /// The top of the chain: the one who narrates from the Prophet ﷺ when the chain reaches him.
        case top = 1
        /// The foot of the chain: the compiler's own teacher.
        case teacher = 2
    }

    let slug: String
    let idInBook: Int
    let role: Role
    let grade: HadithGradeCategory
}

/// A narrator's page: his name as the shelf most often writes it, and his counts.
struct HadithNarratorProfile {
    let id: Int
    let name: String
    /// Every narration whose chain names him.
    let narrations: Int
    /// The narrations he narrates from the Prophet ﷺ himself (the top of a chain that reaches him).
    let fromProphet: Int
    /// The narrations in which he is the compiler's own teacher (the foot of the chain).
    let teacher: Int
    /// By grade, in `HadithGradeCategory` order.
    let grades: [Int]
    /// By book, in the pack's book order, the books with none left out.
    let books: [(slug: String, count: Int)]

    func count(_ grade: HadithGradeCategory) -> Int {
        grades.indices.contains(grade.rawValue) ? grades[grade.rawValue] : 0
    }
}

/// HadithNarrators.qpk in the app's pack container (`QuranPackContainer`); the layout is in
/// `write_narrators_pack` of the script. The eager section names the books (a ref's book byte), the
/// narrator count, the shard size and count, and the group count. Block 0 is the profiles, a
/// `HadithRowBlock` by narrator id; blocks 1 to S are the lists, shard k holding the ids
/// k*shard+1 ... (k+1)*shard; the last block is the groups, by group id. Mapped, not read; a block is
/// decompressed the first time a page asks for a row of it.
final class HadithNarratorsPack: @unchecked Sendable {
    let slugs: [String]
    let narratorCount: Int
    let shardSize: Int
    let shardCount: Int
    let groupCount: Int
    private let container: QuranPackContainer

    static func bundledURL() -> URL? {
        Bundle.main.url(forResource: "HadithNarrators", withExtension: "qpk", subdirectory: "Data/Hadith")
            ?? Bundle.main.url(forResource: "HadithNarrators", withExtension: "qpk", subdirectory: "Hadith")
            ?? Bundle.main.url(forResource: "HadithNarrators", withExtension: "qpk")
    }

    /// Every block decompressed comes to 2.3 MB, so all of them fit the cache at once (the budget
    /// only bounds a corrupt header); a memory warning still empties it (`purge`).
    init?(url: URL) {
        guard let container = QuranPackContainer(url: url, budget: 4 * 1024 * 1024) else { return nil }
        var reader = QuranPackReader(bytes: container.eager)
        let books = reader.u32()
        guard books > 0, books < 64 else { return nil }
        var slugs: [String] = []
        for _ in 0..<books {
            let slug = reader.string()
            guard !slug.isEmpty else { return nil }
            slugs.append(slug)
        }
        let narrators = reader.u32()
        let shard = reader.u32()
        let shards = reader.u32()
        let groups = reader.u32()
        guard reader.remaining == 0, narrators > 0, shard > 0, shards == (narrators + shard - 1) / shard,
              container.blockCount == shards + 2, container.recordCount == container.blockCount,
              container.unitCount == narrators else { return nil }
        self.slugs = slugs
        self.narratorCount = narrators
        self.shardSize = shard
        self.shardCount = shards
        self.groupCount = groups
        self.container = container
    }

    /// The narrator's page, or nil for an id the pack does not hold.
    func profile(id: Int) -> HadithNarratorProfile? {
        guard id >= 1, id <= narratorCount else { return nil }
        return withBlock(0, count: narratorCount) { block, count -> HadithNarratorProfile? in
            guard let index = block.index(of: id, count: count), let payload = block.payload(at: index, count: count)
            else { return nil }
            var reader = QuranPackReader(bytes: Array(payload))
            let name = reader.string()
            let narrations = reader.u32()
            let fromProphet = reader.u32()
            let teacher = reader.u32()
            let grades = (0..<HadithGradeCategory.allCases.count).map { _ in reader.u32() }
            let books = reader.u8()
            guard !name.isEmpty, books == slugs.count else { return nil }
            var byBook: [(slug: String, count: Int)] = []
            for slug in slugs {
                let count = reader.u32()
                if count > 0 { byBook.append((slug, count)) }
            }
            guard reader.remaining == 0 else { return nil }
            return HadithNarratorProfile(id: id, name: name, narrations: narrations, fromProphet: fromProphet,
                                         teacher: teacher, grades: grades, books: byBook)
        } ?? nil
    }

    /// Every narration naming the narrator, in the shelf's order (book, then row).
    func refs(id: Int) -> [HadithNarratorRef] {
        guard id >= 1, id <= narratorCount else { return [] }
        let shard = (id - 1) / shardSize
        let count = min(shardSize, narratorCount - shard * shardSize)
        return withBlock(1 + shard, count: count) { block, count -> [HadithNarratorRef] in
            guard let index = block.index(of: id, count: count), let payload = block.payload(at: index, count: count)
            else { return [] }
            let size = 7
            guard payload.count % size == 0 else { return [] }
            var out: [HadithNarratorRef] = []
            out.reserveCapacity(payload.count / size)
            var at = payload.startIndex
            while at + size <= payload.endIndex {
                let book = Int(payload[at])
                let row = Int(payload[at + 1]) | Int(payload[at + 2]) << 8 | Int(payload[at + 3]) << 16 | Int(payload[at + 4]) << 24
                let role = HadithNarratorRef.Role(rawValue: Int(payload[at + 5]))
                let grade = HadithGradeCategory(rawValue: Int(payload[at + 6]))
                at += size
                guard slugs.indices.contains(book), let role, let grade else { continue }
                out.append(HadithNarratorRef(slug: slugs[book], idInBook: row, role: role, grade: grade))
            }
            return out
        } ?? []
    }

    /// The narrations carried by the chains of a group, in the shelf's order.
    func members(group: Int) -> [(slug: String, idInBook: Int)] {
        guard group >= 1, group <= groupCount else { return [] }
        return withBlock(shardCount + 1, count: groupCount) { block, count -> [(slug: String, idInBook: Int)] in
            guard let index = block.index(of: group, count: count), let payload = block.payload(at: index, count: count)
            else { return [] }
            let size = 5
            guard payload.count % size == 0 else { return [] }
            var out: [(slug: String, idInBook: Int)] = []
            var at = payload.startIndex
            while at + size <= payload.endIndex {
                let book = Int(payload[at])
                let row = Int(payload[at + 1]) | Int(payload[at + 2]) << 8 | Int(payload[at + 3]) << 16 | Int(payload[at + 4]) << 24
                at += size
                guard slugs.indices.contains(book) else { continue }
                out.append((slugs[book], row))
            }
            return out
        } ?? []
    }

    func purge() { container.purge() }

    private func withBlock<T>(_ block: Int, count: Int, _ body: (HadithRowBlock, Int) -> T) -> T? {
        guard count > 0, let bytes = container.block(block),
              // The ids, the offsets, and at least the payloads' start: anything shorter is not this layout.
              bytes.count >= 8 * count + 4 else { return nil }
        return body(HadithRowBlock(bytes: bytes), count)
    }
}

/// The shipped narrators, opened on first use: the chains store's shape (`HadithChainStore`). Not
/// observable; nothing asks on a render, only a page that opens.
final class HadithNarratorStore: @unchecked Sendable {
    static let shared = HadithNarratorStore()
    private init() {}

    private let lock = NSLock()
    private var opened = false
    private var openedPack: HadithNarratorsPack?

    /// The pack, opened once; nil for good when it is missing or does not parse (no profile opens).
    var pack: HadithNarratorsPack? {
        lock.lock()
        defer { lock.unlock() }
        if !opened {
            opened = true
            openedPack = HadithNarratorsPack.bundledURL().flatMap(HadithNarratorsPack.init(url:))
        }
        return openedPack
    }

    func profile(id: Int) -> HadithNarratorProfile? { pack?.profile(id: id) }

    func refs(id: Int) -> [HadithNarratorRef] { pack?.refs(id: id) ?? [] }

    func members(group: Int) -> [(slug: String, idInBook: Int)] { pack?.members(group: group) ?? [] }

    /// Memory pressure (`MemoryTrim`): the decompressed blocks go; the next page inflates its own again.
    func purge() {
        lock.lock()
        let loaded = openedPack
        lock.unlock()
        loaded?.purge()
    }
}
