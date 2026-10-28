import XCTest
@testable import iPhone

/// The chains of narrators (HadithChains.swift): the app decodes from the shipped pack exactly the names
/// and words of transmission that Scripts/build_hadith_chains.py read (its generated
/// `HadithChainSamples`), out of the very narration the reader sees, and builds a diagram from them.
final class HadithChainsTests: XCTestCase {
    private func book(_ slug: String) throws -> HadithBookData {
        let url = try XCTUnwrap(HadithPack.bundledURL(slug), slug)
        return HadithBookData(pack: try XCTUnwrap(HadithPack(slug: slug, url: url), slug))
    }

    private func flatten(_ column: [(String, [String])]) -> [String] {
        column.map { "\($0.0)|\($0.1.joined(separator: "+"))" }
    }

    func testDecoderMatchesTheScript() throws {
        XCTAssertGreaterThan(HadithChainSamples.all.count, 20)
        var books: [String: HadithBookData] = [:]
        for sample in HadithChainSamples.all {
            let data = try books[sample.slug] ?? book(sample.slug)
            books[sample.slug] = data
            let hadith = try XCTUnwrap(data.hadith(numbered: sample.idInBook), "\(sample.slug) \(sample.idInBook)")
            let parsed = try XCTUnwrap(HadithChainDecoder.parse(sample.code), sample.code)
            let words = HadithChainDecoder.tokens(hadith.arabic)
            XCTAssertEqual(parsed.tokenCount, words.count, "\(sample.slug) \(sample.idInBook): the narration's words moved")
            let columns = HadithChainDecoder.columns(parsed, words)
            XCTAssertEqual(flatten(columns.top), sample.top, "\(sample.slug) \(sample.idInBook)")
            XCTAssertEqual(columns.branches.map(flatten), sample.branches, "\(sample.slug) \(sample.idInBook)")
        }
    }

    private func pack() throws -> HadithChainPack {
        let url = try XCTUnwrap(HadithChainPack.bundledURL(), "HadithChains.qpk is not bundled")
        return try XCTUnwrap(HadithChainPack(url: url), "HadithChains.qpk does not open")
    }

    func testEveryBookOfThePackReadsBackInOrder() throws {
        let pack = try pack()
        XCTAssertEqual(pack.books.count, 11)
        XCTAssertGreaterThan(pack.chainCount, 20_000)
        var total = 0
        for (slug, book) in pack.books {
            let chains = pack.chains(slug: slug)
            XCTAssertEqual(chains.count, book.count, slug)
            XCTAssertEqual(chains.map(\.idInBook), chains.map(\.idInBook).sorted(), slug)
            XCTAssertTrue(chains.allSatisfy { HadithChainDecoder.parse($0.code) != nil }, slug)
            total += chains.count
        }
        XCTAssertEqual(total, pack.chainCount)
        XCTAssertNil(pack.code(slug: "bukhari", idInBook: 0))
        XCTAssertFalse(pack.contains(slug: "nawawi40", idInBook: 1))
    }

    /// The binary search finds, for every sample, exactly the code the script wrote for it.
    func testThePackHoldsTheScriptsCodes() throws {
        let pack = try pack()
        for sample in HadithChainSamples.all {
            XCTAssertTrue(pack.contains(slug: sample.slug, idInBook: sample.idInBook), "\(sample.slug) \(sample.idInBook)")
            XCTAssertEqual(pack.code(slug: sample.slug, idInBook: sample.idInBook), sample.code, "\(sample.slug) \(sample.idInBook)")
        }
    }

    func testPackLoadsAndEveryChainFitsItsNarration() throws {
        // Every chain of al-Bukhari decodes against its row: none was read from different words.
        let bukhari = try book("bukhari")
        let chains = try pack().chains(slug: "bukhari")
        XCTAssertGreaterThan(chains.count, 5_000)
        var drawn = 0
        for (id, code) in chains {
            let hadith = try XCTUnwrap(bukhari.hadith(numbered: id))
            if HadithChainDecoder.chain(code: code, arabic: hadith.arabic, compilerArabic: "البُخَارِيُّ", bookTitle: "Sahih al-Bukhari") != nil {
                drawn += 1
            }
        }
        XCTAssertEqual(drawn, chains.count)
    }

    func testTheFirstHadithOfAlBukhari() throws {
        let hadith = try XCTUnwrap(try book("bukhari").hadith(numbered: 1))
        let chain = try XCTUnwrap(HadithChainStore.shared.chain(slug: "bukhari", idInBook: 1, arabic: hadith.arabic, bookTitle: "Sahih al-Bukhari"))
        XCTAssertTrue(HadithChainStore.shared.hasChain(slug: "bukhari", idInBook: 1))
        // The Prophet ﷺ, 'Umar, 'Alqamah, Muhammad ibn Ibrahim, Yahya ibn Sa'id, Sufyan, al-Humaydi.
        let names = chain.top.flatMap(\.nodes).map(\.arabic)
        XCTAssertEqual(names.count, 7)
        XCTAssertTrue(names[1].contains("عُمَرَ"))
        XCTAssertTrue(names.last?.contains("الْحُمَيْدِيُّ") == true)
        XCTAssertEqual(chain.bottom.first?.nodes.first?.arabic, "البُخَارِيُّ")
        XCTAssertEqual(chain.bottom.first?.title, "حَدَّثَنَا")
        // Every narrator named (the Prophet ﷺ and the collector aside) opens his page; the group of
        // chains that are this one is only there when another narration carries it.
        XCTAssertEqual(names.count - 1, chain.top.flatMap(\.nodes).compactMap(\.narratorID).count)
        let code = try XCTUnwrap(HadithChainStore.shared.pack?.code(slug: "bukhari", idInBook: 1))
        XCTAssertEqual(HadithChainDecoder.parse(code)?.group, HadithChainStore.shared.chainGroup(slug: "bukhari", idInBook: 1))
        // A memory warning empties the cache; the next question inflates the book again.
        HadithChainStore.shared.purge()
        XCTAssertTrue(HadithChainStore.shared.hasChain(slug: "bukhari", idInBook: 1))
    }

    func testAChainFromOtherWordsIsNotDrawn() throws {
        let code = try XCTUnwrap(HadithChainSamples.all.first?.code)
        XCTAssertNil(HadithChainDecoder.chain(code: code, arabic: "حَدَّثَنَا فُلاَنٌ", compilerArabic: "", bookTitle: ""))
    }
}
