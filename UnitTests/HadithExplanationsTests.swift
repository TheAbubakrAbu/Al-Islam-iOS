import XCTest
@testable import iPhone

/// The links from the shelf's narrations to the Hadith Encyclopedia (HadithExplanations.swift) and
/// the chain cut that opens a hadith at its final narrator (HadithChainCut, 2026-11-02).
final class HadithExplanationsTests: XCTestCase {
    private func pack() throws -> HadithExplanationPack {
        let url = try XCTUnwrap(HadithExplanationPack.bundledURL(), "HadithExplanations.qpk is not bundled")
        return try XCTUnwrap(HadithExplanationPack(url: url), "HadithExplanations.qpk does not open")
    }

    func testThePackHoldsTheScriptsLinks() throws {
        let pack = try pack()
        XCTAssertEqual(pack.rowCount, HadithExplanationSamples.linkedRows)
        XCTAssertGreaterThan(HadithExplanationSamples.picks.count, 10)
        for pick in HadithExplanationSamples.picks {
            XCTAssertEqual(pack.entryID(slug: pick.slug, idInBook: pick.idInBook), pick.entry, "\(pick.slug) \(pick.idInBook)")
            XCTAssertTrue(pack.contains(slug: pick.slug, idInBook: pick.idInBook))
        }
        XCTAssertNil(pack.entryID(slug: "bukhari", idInBook: 0))
        XCTAssertFalse(pack.contains(slug: "nobody", idInBook: 1))
        // Al-Bukhari's first hadith (the deeds by intentions) and the encyclopedia's page for it.
        XCTAssertEqual(pack.entryID(slug: "bukhari", idInBook: 1), "66511")
    }

    func testEveryLinkedEntryIsInTheEncyclopedia() throws {
        let pack = try pack()
        let library = try XCTUnwrap(HadeethEncStore.shared.library(), "the encyclopedia pack does not open")
        var total = 0
        for (slug, book) in pack.books {
            let entries = pack.entries(slug: slug)
            XCTAssertEqual(entries.count, book.count, slug)
            var last = -1
            for entry in entries {
                XCTAssertGreaterThan(entry.idInBook, last, "\(slug): ids out of order")
                last = entry.idInBook
                XCTAssertNotNil(library.entriesById[entry.entry], "\(slug) \(entry.idInBook) -> \(entry.entry) is no entry")
            }
            total += entries.count
        }
        XCTAssertEqual(total, pack.rowCount)
    }

    func testTheChainCutOpensAtTheFinalNarrator() throws {
        let url = try XCTUnwrap(HadithPack.bundledURL("bukhari"))
        let book = HadithBookData(pack: try XCTUnwrap(HadithPack(slug: "bukhari", url: url)))
        let first = try XCTUnwrap(book.hadith(numbered: 1))
        let cut = try XCTUnwrap(HadithChainStore.shared.matnStart(slug: "bukhari", idInBook: 1, arabic: first.arabic))
        let parts = try XCTUnwrap(HadithChainCut.split(first.arabic, at: cut, spans: []))
        // "سمعت عمر بن الخطاب ... قال: سمعت رسول الله ﷺ يقول: إنما الأعمال بالنيات": the word by which
        // Alqamah received it from Umar opens the hadith; the chain ends with Alqamah's name.
        XCTAssertTrue(parts.matn.hasPrefix("سَمِعْتُ عُمَرَ"), parts.matn.prefix(40).description)
        XCTAssertTrue(parts.chain.hasPrefix("حَدَّثَنَا الْحُمَيْدِيُّ"), parts.chain.prefix(40).description)
        XCTAssertFalse(parts.chain.last?.isWhitespace ?? true)
        // Spans re-base onto the part they fall in; one across the cut keeps the row whole.
        let inMatn = NSRange(location: cut + 2, length: 3)
        let rebased = try XCTUnwrap(HadithChainCut.split(first.arabic, at: cut, spans: [inMatn]))
        XCTAssertEqual(rebased.matnSpans, [NSRange(location: 2, length: 3)])
        XCTAssertNil(HadithChainCut.split(first.arabic, at: cut, spans: [NSRange(location: cut - 1, length: 3)]))
        // A row with no chain read has no cut.
        XCTAssertNil(HadithChainStore.shared.matnStart(slug: "bukhari", idInBook: 1, arabic: "كلام آخر"))
    }
}
