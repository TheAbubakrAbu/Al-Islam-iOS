import XCTest
@testable import iPhone

/// The trees of narrators (HadithIsnadTrees.swift): the shipped pack reads back exactly what
/// Scripts/build_isnad_trees.py built (its generated `HadithIsnadTreeSamples`), every tree is well
/// formed, its narrators have profiles, its narrations are on the shelf and name those narrators, and
/// the page's layout keeps a narration's own road straight.
final class HadithIsnadTreesTests: XCTestCase {
    private func book(_ slug: String) throws -> HadithBookData {
        let url = try XCTUnwrap(HadithPack.bundledURL(slug), slug)
        return HadithBookData(pack: try XCTUnwrap(HadithPack(slug: slug, url: url), slug))
    }

    private func pack() throws -> HadithIsnadTreesPack {
        let url = try XCTUnwrap(HadithIsnadTreesPack.bundledURL(), "HadithIsnadTrees.qpk is not bundled")
        return try XCTUnwrap(HadithIsnadTreesPack(url: url), "HadithIsnadTrees.qpk does not open")
    }

    /// The script's outline of a tree, rebuilt from the app's decoding: one line per node in preorder.
    private func outline(_ tree: HadithIsnadTree) -> [String] {
        var lines: [String] = []
        var names: [Int: String] = [:]
        func walk(_ index: Int, depth: Int) {
            let node = tree.nodes[index]
            switch node.kind {
            case .root:
                lines.append("\(depth):root")
            case .compiler:
                let refs = node.refs.map { "\($0.idInBook)\($0.raised ? "^" : "")" }.joined(separator: ",")
                lines.append("\(depth):\(node.slug):\(refs)")
            case .narrator:
                let ids = node.narratorIDs.isEmpty ? "0" : node.narratorIDs.map(String.init).joined(separator: "+")
                let text: String
                if let id = node.narratorID {
                    if names[id] == nil { names[id] = HadithNarratorStore.shared.profile(id: id)?.name ?? "" }
                    text = names[id] ?? ""
                } else {
                    text = node.text
                }
                lines.append("\(depth):\(ids)\(node.raised ? "^" : ""):\(text)")
            }
            for child in node.children { walk(child, depth: depth + 1) }
        }
        walk(0, depth: 0)
        return lines
    }

    func testThePackOpensAsTheScriptWroteIt() throws {
        let pack = try pack()
        XCTAssertEqual(pack.slugs, HadithIsnadTreeSamples.books)
        XCTAssertEqual(pack.rowCount, HadithIsnadTreeSamples.rowCount)
        XCTAssertEqual(pack.treeCount, HadithIsnadTreeSamples.treeCount)
        XCTAssertEqual(pack.shardSize, HadithIsnadTreeSamples.shard)
        XCTAssertGreaterThan(pack.rowCount, 20_000)
        XCTAssertGreaterThan(pack.treeCount, 10_000)
        XCTAssertNil(pack.tree(id: 0))
        XCTAssertNil(pack.tree(id: pack.treeCount + 1))
        XCTAssertNil(pack.summary(slug: "bukhari", idInBook: 0))
        XCTAssertNil(pack.summary(slug: "nowhere", idInBook: 1))
        // A row with one chain in its family has no tree: Ibn Majah's first row, which the script found none for.
        XCTAssertNil(pack.summary(slug: "ibnmajah", idInBook: 1))
    }

    /// Every sample row's summary and tree are what the script built, node for node.
    func testTheSampleTreesReadBack() throws {
        let pack = try pack()
        for sample in HadithIsnadTreeSamples.all {
            let summary = try XCTUnwrap(pack.summary(slug: sample.slug, idInBook: sample.idInBook), "\(sample.slug) \(sample.idInBook)")
            XCTAssertEqual(summary.tree, sample.tree)
            XCTAssertEqual(summary.narrations, sample.narrations)
            XCTAssertEqual(summary.books, sample.books)
            let tree = try XCTUnwrap(pack.tree(id: sample.tree), "tree \(sample.tree)")
            XCTAssertEqual(outline(tree), sample.outline, "\(sample.slug) \(sample.idInBook)")
            // The counts agree with the tree: as many books as compilers' books, and every narration
            // counted is reached by some road.
            let slugs = Set(tree.nodes.filter { $0.kind == .compiler }.map(\.slug))
            XCTAssertEqual(slugs.count, sample.books)
            XCTAssertEqual(tree.refs.count, sample.narrations)
            XCTAssertTrue(tree.refs.contains { $0.slug == sample.slug && $0.idInBook == sample.idInBook } || HadithChainStore.shared.hasChain(slug: sample.slug, idInBook: sample.idInBook) == false,
                          "\(sample.slug) \(sample.idInBook) is not in its own tree")
        }
    }

    /// Every tree of al-Bukhari's first fifty rows is well formed: the root first, every child index
    /// ahead of its parent, a compiler at every leaf and only there, every narrator a profile, every
    /// narration on the shelf with a chain that names the narrators of its road.
    func testTheTreesOfAlBukhariAreWellFormed() throws {
        let pack = try pack()
        let chains = try XCTUnwrap(HadithChainStore.shared.pack)
        var books: [String: HadithBookData] = [:]
        var checked = 0
        for row in pack.rows(slug: "bukhari").prefix(50) {
            let tree = try XCTUnwrap(pack.tree(id: row.summary.tree), "bukhari \(row.idInBook)")
            XCTAssertEqual(tree.nodes.first?.kind, .root)
            var parents = [Int?](repeating: nil, count: tree.nodes.count)
            for (index, node) in tree.nodes.enumerated() {
                for child in node.children {
                    XCTAssertGreaterThan(child, index)
                    XCTAssertLessThan(child, tree.nodes.count)
                    parents[child] = index
                }
                switch node.kind {
                case .root:
                    XCTAssertEqual(index, 0)
                    XCTAssertFalse(node.children.isEmpty)
                case .narrator:
                    XCTAssertFalse(node.children.isEmpty, "a narrator with no road beneath")
                    XCTAssertTrue(node.narratorIDs.isEmpty ? !node.text.isEmpty : node.text.isEmpty)
                    for id in node.narratorIDs {
                        XCTAssertNotNil(HadithNarratorStore.shared.profile(id: id), "narrator \(id) has no profile")
                    }
                case .compiler:
                    XCTAssertTrue(node.children.isEmpty)
                    XCTAssertFalse(node.refs.isEmpty)
                    XCTAssertTrue(pack.slugs.contains(node.slug))
                    // The road above the compiler: every numbered narrator on it is named by each narration's chain.
                    var road: [Int] = []
                    var at = parents[index]
                    while let here = at {
                        road += tree.nodes[here].narratorIDs
                        at = parents[here]
                    }
                    for ref in node.refs {
                        let data = try books[node.slug] ?? book(node.slug)
                        books[node.slug] = data
                        XCTAssertNotNil(data.hadith(numbered: ref.idInBook), "\(node.slug) \(ref.idInBook) is not on the shelf")
                        let code = try XCTUnwrap(chains.code(slug: node.slug, idInBook: ref.idInBook), "\(node.slug) \(ref.idInBook) has no chain")
                        XCTAssertEqual(code.contains("!"), ref.raised, "\(node.slug) \(ref.idInBook)")
                        let named = Set(HadithChainDecoder.parse(code)?.shared.flatMap { $0 }.compactMap(\.narrator) ?? [])
                            .union(HadithChainDecoder.parse(code)?.branches.flatMap { $0.layers.flatMap { $0 } }.compactMap(\.narrator) ?? [])
                        // The road names the narrators as this narration writes them, or the fuller
                        // names they were joined to: at least one id of every node must be the narration's own.
                        var atNode = parents[index]
                        while let here = atNode {
                            let ids = tree.nodes[here].narratorIDs
                            XCTAssertTrue(ids.isEmpty || !named.isDisjoint(with: ids), "\(node.slug) \(ref.idInBook): \(ids) not in its chain")
                            atNode = parents[here]
                        }
                    }
                    _ = road
                }
            }
            checked += 1
        }
        XCTAssertEqual(checked, 50)
    }

    /// The page's layout: the narration's own road is one straight column at the right edge, the
    /// root over it, every other node to its left, and no two nodes share a place.
    func testTheLayoutKeepsTheOwnRoadStraight() throws {
        let pack = try pack()
        let sample = try XCTUnwrap(HadithIsnadTreeSamples.all.first)
        let tree = try XCTUnwrap(pack.tree(id: sample.tree))
        let layout = HadithIsnadTreeLayout(tree: tree, source: (sample.slug, sample.idInBook))
        XCTAssertEqual(layout.roads, tree.roads)
        XCTAssertEqual(layout.placed.count, tree.nodes.count)
        let own = layout.placed.filter(\.highlighted)
        XCTAssertGreaterThan(own.count, 2)
        let rightmost = layout.width - HadithIsnadTreeLayout.inset - HadithIsnadTreeLayout.columnPitch / 2
        for placed in own {
            XCTAssertEqual(placed.center.x, rightmost, accuracy: 0.01, "the own road bends")
        }
        XCTAssertEqual(layout.placed[0].center.x, rightmost, accuracy: 0.01, "the root is not over the own road")
        let places = layout.placed.map { "\(Int($0.center.x))|\(Int($0.center.y))" }
        XCTAssertEqual(Set(places).count, places.count, "two nodes share a place")
        for placed in layout.placed {
            XCTAssertLessThanOrEqual(placed.center.x, rightmost + 0.01)
            XCTAssertGreaterThanOrEqual(placed.center.x, HadithIsnadTreeLayout.inset)
            XCTAssertLessThanOrEqual(placed.center.y + HadithIsnadTreeLayout.chipHeight / 2, layout.height)
        }
        // Pruned to nothing but the own narration's family, the tree keeps at least its own road.
        let kept = try XCTUnwrap(tree.pruned { slug, id in slug == sample.slug && id == sample.idInBook })
        XCTAssertEqual(kept.roads, 1)
        XCTAssertNil(tree.pruned { _, _ in false })
    }

    func testTheStoreAnswersAndSurvivesAPurge() throws {
        let store = HadithIsnadTreeStore.shared
        let summary = try XCTUnwrap(store.summary(slug: "bukhari", idInBook: 1))
        XCTAssertNotNil(store.tree(id: summary.tree))
        store.purge()
        XCTAssertEqual(store.summary(slug: "bukhari", idInBook: 1), summary)
        XCTAssertEqual(store.tree(id: summary.tree)?.nodes.count, store.tree(id: summary.tree)?.nodes.count)
    }
}
