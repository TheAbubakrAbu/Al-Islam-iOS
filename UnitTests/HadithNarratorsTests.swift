import XCTest
@testable import iPhone

/// The narrators and the groups of equal chains (HadithNarrators.swift): the shipped pack reads back
/// exactly what Scripts/build_hadith_chains.py counted (its generated `HadithNarratorSamples`), the
/// chain codes name narrators the pack holds, and every narration a profile lists is on the shelf.
final class HadithNarratorsTests: XCTestCase {
    private func book(_ slug: String) throws -> HadithBookData {
        let url = try XCTUnwrap(HadithPack.bundledURL(slug), slug)
        return HadithBookData(pack: try XCTUnwrap(HadithPack(slug: slug, url: url), slug))
    }

    private func pack() throws -> HadithNarratorsPack {
        let url = try XCTUnwrap(HadithNarratorsPack.bundledURL(), "HadithNarrators.qpk is not bundled")
        return try XCTUnwrap(HadithNarratorsPack(url: url), "HadithNarrators.qpk does not open")
    }

    func testThePackOpensAsTheScriptWroteIt() throws {
        let pack = try pack()
        XCTAssertEqual(pack.slugs, HadithNarratorSamples.books)
        XCTAssertEqual(pack.narratorCount, HadithNarratorSamples.narratorCount)
        XCTAssertEqual(pack.groupCount, HadithNarratorSamples.groupCount)
        XCTAssertGreaterThan(pack.narratorCount, 5_000)
        XCTAssertGreaterThan(pack.groupCount, 1_000)
        XCTAssertNil(pack.profile(id: 0))
        XCTAssertNil(pack.profile(id: pack.narratorCount + 1))
        XCTAssertTrue(pack.refs(id: 0).isEmpty)
        XCTAssertTrue(pack.members(group: 0).isEmpty)
        XCTAssertTrue(pack.members(group: pack.groupCount + 1).isEmpty)
    }

    /// Every sample narrator's profile and list are what the script counted, and the counts agree
    /// with the list: by grade and by book they add up to the narrations, the list is in the shelf's
    /// order, and every narration listed exists.
    func testTheSampleNarratorsReadBack() throws {
        let pack = try pack()
        var books: [String: HadithBookData] = [:]
        for sample in HadithNarratorSamples.narrators {
            let profile = try XCTUnwrap(pack.profile(id: sample.id), "narrator \(sample.id)")
            XCTAssertEqual(profile.name, sample.name)
            XCTAssertEqual(profile.narrations, sample.narrations)
            XCTAssertEqual(profile.fromProphet, sample.fromProphet)
            XCTAssertEqual(profile.teacher, sample.teacher)
            XCTAssertEqual(profile.grades, sample.grades)
            XCTAssertEqual(profile.grades.reduce(0, +), sample.narrations, sample.name)
            let byBook = Dictionary(uniqueKeysWithValues: profile.books.map { ($0.slug, $0.count) })
            XCTAssertEqual(byBook, Dictionary(uniqueKeysWithValues: zip(HadithNarratorSamples.books, sample.books).filter { $0.1 > 0 }), sample.name)
            XCTAssertEqual(profile.books.map(\.count).reduce(0, +), sample.narrations, sample.name)

            let refs = pack.refs(id: sample.id)
            XCTAssertEqual(refs.count, sample.narrations, sample.name)
            XCTAssertEqual(refs.prefix(5).map { "\($0.slug):\($0.idInBook):\($0.role.rawValue):\($0.grade.rawValue)" },
                           sample.firstRefs.map { "\($0.slug):\($0.idInBook):\($0.role):\($0.grade)" }, sample.name)
            let order = refs.map { (HadithNarratorSamples.books.firstIndex(of: $0.slug) ?? 99, $0.idInBook) }
            XCTAssertEqual(order.map { "\($0.0):\($0.1)" }, order.sorted { $0 < $1 }.map { "\($0.0):\($0.1)" }, sample.name)
            XCTAssertEqual(refs.filter { $0.role == .teacher }.count, sample.teacher, sample.name)
            XCTAssertLessThanOrEqual(sample.fromProphet, refs.filter { $0.role == .top }.count, sample.name)
            for ref in refs {
                let data = try books[ref.slug] ?? book(ref.slug)
                books[ref.slug] = data
                XCTAssertNotNil(data.hadith(numbered: ref.idInBook), "\(sample.name): \(ref.slug) \(ref.idInBook) is not on the shelf")
                // A narration listed under a narrator carries a chain that names him.
                let code = HadithChainStore.shared.pack?.code(slug: ref.slug, idInBook: ref.idInBook)
                XCTAssertTrue(code?.contains("@\(sample.id)") == true, "\(sample.name): \(ref.slug) \(ref.idInBook) does not name him")
            }
        }
    }

    /// The sample groups read back, every member's chain code carries the group, and the chains are
    /// drawn from the same narrators.
    func testTheSampleGroupsReadBack() throws {
        let pack = try pack()
        let chains = try XCTUnwrap(HadithChainStore.shared.pack)
        var books: [String: HadithBookData] = [:]
        for sample in HadithNarratorSamples.groups {
            let members = pack.members(group: sample.id)
            XCTAssertEqual(members.map { "\($0.slug):\($0.idInBook)" }, sample.members.map { "\($0.slug):\($0.idInBook)" }, "group \(sample.id)")
            XCTAssertGreaterThan(members.count, 1)
            var narrators: Set<[Int]> = []
            for member in members {
                let code = try XCTUnwrap(chains.code(slug: member.slug, idInBook: member.idInBook), "\(member.slug) \(member.idInBook)")
                XCTAssertTrue(code.hasSuffix("~\(sample.id)"), "\(member.slug) \(member.idInBook): \(code)")
                XCTAssertEqual(HadithChainStore.shared.chainGroup(slug: member.slug, idInBook: member.idInBook), sample.id)
                let parsed = try XCTUnwrap(HadithChainDecoder.parse(code))
                XCTAssertEqual(parsed.group, sample.id)
                let data = try books[member.slug] ?? book(member.slug)
                books[member.slug] = data
                let ids = (parsed.shared + parsed.branches.flatMap(\.layers)).map { layer in layer.compactMap(\.narrator).sorted() }.flatMap { $0 }
                narrators.insert(ids)
            }
            XCTAssertEqual(narrators.count, 1, "group \(sample.id): its chains name different narrators")
        }
    }

    /// The first hadith of al-Bukhari: every narrator chip opens a profile that lists it, 'Umar at
    /// the top, al-Humaydi as the compiler's teacher, and the collector's chip opens nothing.
    func testTheFirstHadithOfAlBukhariNamesItsNarrators() throws {
        let hadith = try XCTUnwrap(try book("bukhari").hadith(numbered: 1))
        let chain = try XCTUnwrap(HadithChainStore.shared.chain(slug: "bukhari", idInBook: 1, arabic: hadith.arabic, bookTitle: "Sahih al-Bukhari"))
        let nodes = chain.top.flatMap(\.nodes)
        XCTAssertNil(nodes.first?.narratorID, "the Prophet ﷺ is no narrator's page")
        XCTAssertNil(chain.bottom.first?.nodes.first?.narratorID, "the collector is no narrator's page")
        let narrators = nodes.dropFirst().compactMap(\.narratorID)
        XCTAssertEqual(narrators.count, 6)
        for (index, id) in narrators.enumerated() {
            let profile = try XCTUnwrap(HadithNarratorStore.shared.profile(id: id))
            XCTAssertGreaterThan(profile.narrations, 0)
            let ref = try XCTUnwrap(HadithNarratorStore.shared.refs(id: id).first { $0.slug == "bukhari" && $0.idInBook == 1 },
                                    "\(profile.name) does not list bukhari 1")
            XCTAssertEqual(ref.grade, .sahih)
            XCTAssertEqual(ref.role, index == 0 ? .top : (index == narrators.count - 1 ? .teacher : .link), profile.name)
        }
        let umar = try XCTUnwrap(HadithNarratorStore.shared.profile(id: narrators[0]))
        // Scalars, not Characters: a String `contains` would not find "ر" inside the grapheme "رَ".
        XCTAssertTrue(umar.name.unicodeScalars.starts(with: "عُمَرَ".unicodeScalars), umar.name)
        XCTAssertGreaterThan(umar.fromProphet, 100)
        // A memory warning empties the cache; the next question inflates the block again.
        HadithNarratorStore.shared.purge()
        XCTAssertEqual(HadithNarratorStore.shared.profile(id: narrators[0])?.name, umar.name)
    }
}
