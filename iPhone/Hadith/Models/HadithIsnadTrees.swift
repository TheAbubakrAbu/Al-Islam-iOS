import Foundation

// One narration's tree of narrators: every chain of it and of the narrations that carry its text (or
// nearly), merged from the Prophet ﷺ down through every fork to each compiler (Abu, 2026-10-27: "in
// similar chains and similar Hadiths and show/share chain create one big chain from prophet Muhammad
// and all the different forks and all the other chains ... all of this preprocessed").
//
// Nothing here merges. Scripts/build_isnad_trees.py read the chains (HadithChains.qpk) of every
// narration and of its similar narrations (SimilarHadiths.qpk), merged them where they name the same
// narrator (its header says exactly when two spellings are taken for one man, and when they are not),
// and shipped the trees: Resources/Data/Hadith/HadithIsnadTrees.qpk. This file reads a row's tree; the
// page lays it out and draws it (HadithIsnadTreeView.swift).

/// A tree as the pack holds it: the nodes in preorder, the root first, each naming its children.
struct HadithIsnadTree {
    enum Kind: Int {
        /// The Prophet ﷺ, at the root.
        case root = 0
        /// A narrator (or a relation to the one below, "أبيه", who has no profile).
        case narrator = 1
        /// A compiler, at a leaf, with the narrations this road reaches in his book.
        case compiler = 2
    }

    struct Ref: Hashable {
        let idInBook: Int
        /// The chain, as written, names the Prophet ﷺ.
        let raised: Bool
    }

    struct Node {
        let kind: Kind
        /// The narrator ids joined into this node (HadithNarrators.qpk), the fullest name first;
        /// empty at the root and for a relation.
        let narratorIDs: [Int]
        /// A relation's text as a narration writes it ("أَبِيهِ"); "" elsewhere.
        let text: String
        /// A narration beneath this narrator names the Prophet ﷺ; the page draws the link from the
        /// root dashed where none does.
        let raised: Bool
        /// Indices into `nodes`.
        let children: [Int]
        /// The compiler's book, at a leaf.
        let slug: String
        let refs: [Ref]

        var narratorID: Int? { narratorIDs.first }
    }

    let id: Int
    let nodes: [Node]

    /// The paths from the root to a compiler: what the page calls roads.
    var roads: Int { nodes.lazy.filter { $0.kind == .compiler }.count }

    /// Every narration the tree reaches, by book, in the tree's order.
    var refs: [(slug: String, idInBook: Int)] {
        var seen: Set<String> = []
        var out: [(slug: String, idInBook: Int)] = []
        for node in nodes where node.kind == .compiler {
            for ref in node.refs where seen.insert("\(node.slug):\(ref.idInBook)").inserted {
                out.append((node.slug, ref.idInBook))
            }
        }
        return out
    }

    /// The tree with only the narrations `keep` answers true for: a compiler keeps those of his
    /// narrations, a narrator stays while a road beneath him does. Nil when nothing is left.
    func pruned(keeping keep: (String, Int) -> Bool) -> HadithIsnadTree? {
        var out: [Node] = []
        func copy(_ index: Int) -> Int? {
            let node = nodes[index]
            if node.kind == .compiler {
                let refs = node.refs.filter { keep(node.slug, $0.idInBook) }
                guard !refs.isEmpty else { return nil }
                out.append(Node(kind: .compiler, narratorIDs: [], text: "", raised: refs.contains { $0.raised },
                                children: [], slug: node.slug, refs: refs))
                return out.count - 1
            }
            let place = out.count
            out.append(node)
            let children = node.children.compactMap(copy)
            guard node.kind == .root || !children.isEmpty else {
                out.removeSubrange(place...)
                return nil
            }
            let raised = children.contains { out[$0].raised }
            out[place] = Node(kind: node.kind, narratorIDs: node.narratorIDs, text: node.text, raised: raised,
                              children: children, slug: "", refs: [])
            return place
        }
        guard !nodes.isEmpty, copy(0) != nil, out.count > 1 else { return nil }
        return HadithIsnadTree(id: id, nodes: out)
    }

    /// The pack's preorder (`serialize` in the script), or nil for bytes that are not a tree.
    static func decode(id: Int, _ payload: ArraySlice<UInt8>) -> HadithIsnadTree? {
        var at = payload.startIndex
        var nodes: [Node] = []
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
        func node(depth: Int) -> Int? {
            guard depth < 64, nodes.count < 50_000, at < payload.endIndex else { return nil }
            let flags = Int(payload[at])
            at += 1
            guard let kind = Kind(rawValue: flags & 3) else { return nil }
            let place = nodes.count
            if kind == .compiler {
                guard at < payload.endIndex else { return nil }
                let book = Int(payload[at])
                at += 1
                guard let count = varint() else { return nil }
                var refs: [Ref] = []
                for _ in 0..<count {
                    guard let idInBook = varint(), at < payload.endIndex else { return nil }
                    refs.append(Ref(idInBook: idInBook, raised: payload[at] != 0))
                    at += 1
                }
                // The book index is resolved by the pack, which knows the slugs: kept in `text` for now.
                nodes.append(Node(kind: .compiler, narratorIDs: [], text: String(book), raised: refs.contains { $0.raised },
                                  children: [], slug: "", refs: refs))
                return place
            }
            var ids: [Int] = []
            var text = ""
            if kind == .narrator {
                guard let count = varint() else { return nil }
                if count == 0 {
                    guard at < payload.endIndex else { return nil }
                    let length = Int(payload[at])
                    at += 1
                    guard at + length <= payload.endIndex else { return nil }
                    text = String(decoding: payload[at..<(at + length)], as: UTF8.self)
                    at += length
                }
                for _ in 0..<count {
                    guard let narrator = varint() else { return nil }
                    ids.append(narrator)
                }
            }
            guard let count = varint() else { return nil }
            nodes.append(Node(kind: kind, narratorIDs: ids, text: text, raised: flags & 4 != 0, children: [], slug: "", refs: []))
            var children: [Int] = []
            for _ in 0..<count {
                guard let child = node(depth: depth + 1) else { return nil }
                children.append(child)
            }
            nodes[place] = Node(kind: kind, narratorIDs: ids, text: text, raised: flags & 4 != 0, children: children,
                                slug: "", refs: [])
            return place
        }
        guard node(depth: 0) == 0, at == payload.endIndex, nodes.first?.kind == .root else { return nil }
        return HadithIsnadTree(id: id, nodes: nodes)
    }

    /// The compilers' book indices turned into slugs; a leaf naming no book of the pack is not a tree.
    func naming(_ slugs: [String]) -> HadithIsnadTree? {
        var out: [Node] = []
        out.reserveCapacity(nodes.count)
        for node in nodes {
            guard node.kind == .compiler else {
                out.append(node)
                continue
            }
            guard let book = Int(node.text), slugs.indices.contains(book) else { return nil }
            out.append(Node(kind: .compiler, narratorIDs: [], text: "", raised: node.raised, children: [],
                            slug: slugs[book], refs: node.refs))
        }
        return HadithIsnadTree(id: id, nodes: out)
    }
}

/// HadithIsnadTrees.qpk in the app's pack container (`QuranPackContainer`); the layout is in
/// `write_pack` of the script. The eager section names the books (a compiler's book byte) and the
/// counts; block n (one per book) maps the book's rows to their trees (a `HadithRowBlock` by
/// idInBook: varint tree id, narrations, books); the blocks after hold the trees, `shardSize` to a
/// block by tree id. Mapped, not read; a block is decompressed the first time a page asks.
final class HadithIsnadTreesPack: @unchecked Sendable {
    /// What a row's door says before the tree is read.
    struct Summary: Equatable {
        let tree: Int
        /// The narrations whose chains the tree merges, and the books they are from.
        let narrations: Int
        let books: Int
    }

    let slugs: [String]
    /// Each book's rows with a tree: its block's row count.
    let counts: [Int]
    let rowCount: Int
    let treeCount: Int
    let shardSize: Int
    let shardCount: Int
    private let container: QuranPackContainer

    static func bundledURL() -> URL? {
        Bundle.main.url(forResource: "HadithIsnadTrees", withExtension: "qpk", subdirectory: "Data/Hadith")
            ?? Bundle.main.url(forResource: "HadithIsnadTrees", withExtension: "qpk", subdirectory: "Hadith")
            ?? Bundle.main.url(forResource: "HadithIsnadTrees", withExtension: "qpk")
    }

    /// Every block decompressed comes to about 2.3 MB, so all of them fit the cache at once (the
    /// budget only bounds a corrupt header); a memory warning still empties it (`purge`).
    init?(url: URL) {
        guard let container = QuranPackContainer(url: url, budget: 6 * 1024 * 1024) else { return nil }
        var reader = QuranPackReader(bytes: container.eager)
        let books = reader.u32()
        guard books > 0, books < 64 else { return nil }
        var slugs: [String] = []
        var counts: [Int] = []
        for _ in 0..<books {
            let slug = reader.string()
            let count = reader.u32()
            guard !slug.isEmpty, count >= 0 else { return nil }
            slugs.append(slug)
            counts.append(count)
        }
        let rows = reader.u32()
        let trees = reader.u32()
        let shard = reader.u32()
        let shards = reader.u32()
        guard reader.remaining == 0, rows > 0, trees > 0, shard > 0, shards == (trees + shard - 1) / shard,
              container.blockCount == books + shards, container.recordCount == container.blockCount,
              container.unitCount == rows, counts.reduce(0, +) == rows else { return nil }
        self.slugs = slugs
        self.counts = counts
        self.rowCount = rows
        self.treeCount = trees
        self.shardSize = shard
        self.shardCount = shards
        self.container = container
    }

    /// The row's tree and counts, or nil when the script built none for it (fewer than two chains in
    /// its family). A binary search in the book's block.
    func summary(slug: String, idInBook: Int) -> Summary? {
        guard let book = slugs.firstIndex(of: slug) else { return nil }
        return withBlock(book, count: counts[book]) { block, count -> Summary? in
            guard let index = block.index(of: idInBook, count: count), let payload = block.payload(at: index, count: count)
            else { return nil }
            var at = payload.startIndex
            var values: [Int] = []
            for _ in 0..<3 {
                var value = 0
                var shift = 0
                var done = false
                while at < payload.endIndex, shift < 35 {
                    let byte = Int(payload[at])
                    at += 1
                    value |= (byte & 0x7F) << shift
                    if byte & 0x80 == 0 { done = true; break }
                    shift += 7
                }
                guard done else { return nil }
                values.append(value)
            }
            guard at == payload.endIndex, values[0] >= 1, values[0] <= treeCount else { return nil }
            return Summary(tree: values[0], narrations: values[1], books: values[2])
        } ?? nil
    }

    /// Every row of a book that has a tree, in `idInBook` order: for the tests.
    func rows(slug: String) -> [(idInBook: Int, summary: Summary)] {
        guard let book = slugs.firstIndex(of: slug) else { return [] }
        return withBlock(book, count: counts[book]) { block, count in
            (0..<count).compactMap { index in
                summary(slug: slug, idInBook: block.id(at: index)).map { (idInBook: block.id(at: index), summary: $0) }
            }
        } ?? []
    }

    /// The tree, decoded from its shard; nil for an id the pack does not hold or bytes that are not a tree.
    func tree(id: Int) -> HadithIsnadTree? {
        guard id >= 1, id <= treeCount else { return nil }
        let shard = (id - 1) / shardSize
        let count = min(shardSize, treeCount - shard * shardSize)
        return withBlock(slugs.count + shard, count: count) { block, count -> HadithIsnadTree? in
            guard let index = block.index(of: id, count: count), let payload = block.payload(at: index, count: count)
            else { return nil }
            return HadithIsnadTree.decode(id: id, payload)?.naming(slugs)
        } ?? nil
    }

    func purge() { container.purge() }

    private func withBlock<T>(_ block: Int, count: Int, _ body: (HadithRowBlock, Int) -> T) -> T? {
        guard count > 0, let bytes = container.block(block),
              // The ids, the offsets, and at least the payloads' start: anything shorter is not this layout.
              bytes.count >= 8 * count + 4 else { return nil }
        return body(HadithRowBlock(bytes: bytes), count)
    }
}

/// The shipped trees, opened on first use: the chains store's shape (`HadithChainStore`). Not
/// observable; a sheet asks once when it opens.
final class HadithIsnadTreeStore: @unchecked Sendable {
    static let shared = HadithIsnadTreeStore()
    private init() {}

    private let lock = NSLock()
    private var opened = false
    private var openedPack: HadithIsnadTreesPack?

    /// The pack, opened once; nil for good when it is missing or does not parse (no door is offered).
    var pack: HadithIsnadTreesPack? {
        lock.lock()
        defer { lock.unlock() }
        if !opened {
            opened = true
            openedPack = HadithIsnadTreesPack.bundledURL().flatMap(HadithIsnadTreesPack.init(url:))
        }
        return openedPack
    }

    func summary(slug: String, idInBook: Int) -> HadithIsnadTreesPack.Summary? {
        pack?.summary(slug: slug, idInBook: idInBook)
    }

    func tree(id: Int) -> HadithIsnadTree? { pack?.tree(id: id) }

    /// Memory pressure (`MemoryTrim`): the decompressed blocks go; the next page inflates its own again.
    func purge() {
        lock.lock()
        let loaded = openedPack
        lock.unlock()
        loaded?.purge()
    }
}
