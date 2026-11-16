import XCTest
import UIKit
@testable import iPhone

/// How hadiths and chapters are numbered (Quality Guide, Phase 8: H4 and H7).
final class HadithNumberingTests: XCTestCase {

    private static let slugs = [
        "bukhari", "muslim", "ibnmajah", "abudawud", "tirmidhi", "nasai", "malik", "ahmed", "darimi",
        "qudsi40", "nawawi40", "shahwaliullah40", "aladab_almufrad", "shamail_muhammadiyah",
        "riyad_assalihin", "mishkat_almasabih", "bulugh_almaram",
    ]

    private func book(_ slug: String) throws -> HadithBookData {
        let url = try XCTUnwrap(HadithPack.bundledURL(slug), slug)
        return HadithBookData(pack: try XCTUnwrap(HadithPack(slug: slug, url: url), slug))
    }

    /// H7: five books store their introduction (chapter id 0) last, though it opens the book. It
    /// leads, at position 0, and every numbered chapter keeps its position.
    func testIntroductionLeadsTheBook() throws {
        for slug in ["muslim", "ibnmajah", "darimi", "riyad_assalihin", "mishkat_almasabih"] {
            let data = try book(slug)
            XCTAssertTrue(data.opensWithIntroduction, slug)
            XCTAssertEqual(data.chapters.first?.id, 0, slug)
            XCTAssertEqual(data.position(of: data.chapters[0]), 0, slug)
            XCTAssertEqual(data.chapter(atPosition: 0)?.id, 0, slug)
            XCTAssertEqual(data.chapter(atPosition: 1)?.id, 1, slug)
            XCTAssertEqual(data.position(of: data.chapters[1]), 1, slug)
            XCTAssertEqual(data.chapter(id: 0)?.id, 0, slug)
        }
        // A book whose one chapter is id 0 keeps it at position 1.
        let nawawi = try book("nawawi40")
        XCTAssertFalse(nawawi.opensWithIntroduction)
        XCTAssertEqual(nawawi.chapter(atPosition: 1)?.id, 0)
        // A book with no introduction is untouched.
        let bukhari = try book("bukhari")
        XCTAssertFalse(bukhari.opensWithIntroduction)
        XCTAssertEqual(bukhari.position(of: bukhari.chapters[0]), 1)
    }

    /// H4: an uncited row's number never reads as another row's citation (197 of Bulugh al-Maram's
    /// did). In a book that cites its other rows it is named by its place, "C:N", which the search
    /// resolves back to it; a book that cites nothing keeps its row numbers.
    func testUncitedRowsNeverShowAnotherRowsCitation() throws {
        for slug in Self.slugs {
            let data = try book(slug)
            let citations = Set(data.hadiths.compactMap(\.citation))
            for hadith in data.hadiths where hadith.citation == nil {
                XCTAssertFalse(citations.contains(hadith.displayNumber), "\(slug) row \(hadith.row) shows \(hadith.displayNumber)")
            }
        }
        let bulugh = try book("bulugh_almaram")
        for hadith in bulugh.hadiths.prefix(60) where hadith.citation == nil {
            let parts = hadith.displayNumber.split(separator: ":").compactMap { Int($0) }
            XCTAssertEqual(parts.count, 2, hadith.displayNumber)
            guard parts.count == 2 else { continue }
            XCTAssertEqual(bulugh.hadith(chapterPosition: parts[0], position: parts[1])?.row, hadith.row, hadith.displayNumber)
        }
        let malik = try book("malik")
        XCTAssertEqual(malik.hadiths[0].displayNumber, String(malik.hadiths[0].idInBook))
    }

    /// The Musnad's chapters are the print's own books, not its 1,314 per-Companion headings, half
    /// of which hold one narration (Abu, 2026-11-12: "there's like thousands of chapters for the new
    /// ones if they're not in real chapters just put it in one chapter"; the print has real ones).
    /// Each of the ten promised Paradise keeps his own musnad, every book after them is one
    /// chapter, and the fifteen rows of Abu Rimthah keep chapter id 31, which is now the whole
    /// book they sit in, so nothing saved against one of the rows the app had before has moved.
    func testMusnadChaptersAreThePrintsBooks() throws {
        let ahmed = try book("ahmed")
        XCTAssertEqual(ahmed.chapters.map(\.id),
                       [1, 2, 3, 4, 5, 6, 7, 108, 109, 110, 111, 1402, 1403, 1404, 31, 1406, 1407, 1408, 1409, 1410, 1411, 1413])
        XCTAssertFalse(ahmed.chapters.contains { $0.arabic.isEmpty || $0.english.isEmpty })
        let narratedMost = try XCTUnwrap(ahmed.chapter(id: 31))
        let rows = ahmed.hadiths(in: narratedMost)
        XCTAssertEqual(rows.count, 11_737)
        XCTAssertEqual(rows.first?.citation, "3548")
        let abuRimthah = try XCTUnwrap(ahmed.hadith(numbered: 1360))
        XCTAssertEqual(abuRimthah.citation, "7104")
        XCTAssertEqual(abuRimthah.chapterId, 31)
        XCTAssertTrue(rows.contains { $0.idInBook == 1360 })
        // a row of the six musnads the app had from the start, and the first row of the rest
        XCTAssertEqual(ahmed.hadith(numbered: 1)?.chapterId, 1)
        XCTAssertEqual(ahmed.hadith(numbered: 1375)?.chapterId, 108)
    }

    /// A long chapter is read a part at a time (`HadithChapterView.wholeChapterLimit`: a List lays
    /// its sections out at the cost of their number squared, and the Musnad's largest book holds
    /// 11,737 hadiths). The parts tile the chapter, none is longer than the goal, none is a stub,
    /// and a chapter within the limit is one part. No chapter outside the Musnad is cut at all.
    func testLongChaptersAreCutIntoEvenParts() throws {
        for count in [1, 77, 921, 1_000] {
            XCTAssertEqual(HadithChapterView.partLength(ofChapterWith: count), count)
            XCTAssertEqual(HadithChapterView.partStart(holdingIndex: count - 1, count: count), 0)
        }
        for count in [1_001, 1_273, 1_780, 2_924, 3_635, 11_737, 27_529] {
            let length = HadithChapterView.partLength(ofChapterWith: count)
            XCTAssertLessThanOrEqual(length, HadithChapterView.partSizeGoal, "\(count)")
            let starts = Set((0..<count).map { HadithChapterView.partStart(holdingIndex: $0, count: count) }).sorted()
            XCTAssertEqual(starts.first, 0, "\(count)")
            for (earlier, later) in zip(starts, starts.dropFirst()) { XCTAssertEqual(later - earlier, length, "\(count)") }
            XCTAssertGreaterThan(count - (starts.last ?? 0), length / 2, "\(count)")
        }
        for slug in Self.slugs where slug != "ahmed" {
            for chapter in try book(slug).chapters {
                XCTAssertLessThanOrEqual(chapter.rowCount, HadithChapterView.wholeChapterLimit, "\(slug) \(chapter.id)")
            }
        }
        let cut = try book("ahmed").chapters.filter { $0.rowCount > HadithChapterView.wholeChapterLimit }.map(\.id)
        XCTAssertEqual(cut, [1404, 31, 1408, 1409, 1410, 1411, 1413])
    }

    /// A chapter lays its rows out on the text it LANDS on (`HadithBookData.landingRows`), never on
    /// the whole chapter's, which it used to decode behind a spinner (Abu, 2026-11-13: "should be
    /// preprocessed before it opens"). The landing stays inside the chapter and holds the hadith
    /// opened on; what the book screen decodes ahead of the tap is exactly what the chapter asks
    /// for; and a prewarm stops at what the cache spares, so its first blocks outlive its last.
    func testAChapterWaitsOnlyForTheTextItLandsOn() throws {
        XCTAssertEqual(HadithBookData.landingRows(firstRow: 100, count: 0, index: 0), 0..<0)
        XCTAssertEqual(HadithBookData.landingRows(firstRow: 100, count: 5, index: 0), 100..<105)
        XCTAssertEqual(HadithBookData.landingRows(firstRow: 100, count: 500, index: 0), 100..<112)
        XCTAssertEqual(HadithBookData.landingRows(firstRow: 100, count: 500, index: 40), 138..<152)
        XCTAssertEqual(HadithBookData.landingRows(firstRow: 100, count: 500, index: 499), 597..<600)
        XCTAssertEqual(HadithBookData.landingRows(firstRow: 100, count: 500, index: 9_000), 597..<600)

        let ahmed = try book("ahmed")
        HadithBlockCache.shared.purge()
        defer { HadithBlockCache.shared.purge() }

        // Opened on a hadith two thirds of the way down the longest book: one landing, in its part.
        let long = try XCTUnwrap(ahmed.chapters.max { $0.rowCount < $1.rowCount })
        let hadiths = Array(ahmed.hadiths(in: long))
        let place = hadiths.count * 2 / 3
        let deep = hadiths[place]
        let start = HadithChapterView.partStart(holdingIndex: place, count: hadiths.count)
        let landing = HadithChapterView.landingRows(in: hadiths, partStart: start, target: deep.idInBook)
        XCTAssertEqual(landing, ahmed.landingRows(of: long, at: deep))
        XCTAssertTrue(landing.contains(deep.row))
        XCTAssertLessThanOrEqual(landing.count, HadithBookData.landingReach + 2)
        XCTAssertFalse(ahmed.hasText(rows: landing))
        ahmed.prewarmLandingText([landing])
        XCTAssertTrue(ahmed.hasText(rows: landing))
        XCTAssertFalse(ahmed.hasText(rows: long.firstRow..<(long.firstRow + long.rowCount)),
                       "the whole of a long chapter is more than a landing")
        // A part's head, with no hadith named, is its own landing.
        let head = HadithChapterView.landingRows(in: hadiths, partStart: start, target: nil)
        XCTAssertEqual(head.lowerBound, long.firstRow + max(0, start - 2))

        // The book screen's prewarm: every chapter's opening is resident when it ends.
        HadithBlockCache.shared.purge()
        // (The allowance is named here, the full tier's: `prewarmLandingText` picks two blocks
        // instead on a weak or power-saving host.)
        let allowance = HadithBlockCache.shared.textRoom * 3 / 4
        let openings = ahmed.chapters.map { ahmed.landingRows(of: $0) }
        ahmed.pack.prefetchText(landings: openings, allowance: allowance)
        for (chapter, opening) in zip(ahmed.chapters, openings) {
            XCTAssertTrue(ahmed.hasText(rows: opening), "chapter \(chapter.id)")
        }

        // Asked for the whole Musnad (more text than the cache keeps), it stops inside the cache:
        // the first landing is still resident, and the last was never decoded.
        HadithBlockCache.shared.purge()
        let everywhere = stride(from: 0, to: ahmed.hadiths.count, by: 50).map { $0..<($0 + 1) }
        ahmed.pack.prefetchText(landings: everywhere, allowance: allowance)
        XCTAssertTrue(ahmed.hasText(rows: try XCTUnwrap(everywhere.first)))
        XCTAssertFalse(ahmed.hasText(rows: try XCTUnwrap(everywhere.last)))
    }

    /// The Quran faces ring a number whole only as far as `ArabicNumberFace.medallionLimit`: every
    /// number a view may set in them comes out as ONE glyph, a number well past it does not, and
    /// the faces that write plain digits are never refused.
    func testArabicNumberFaceLimitIsTheFacesOwn() throws {
        for name in [Settings.hafsUthmaniFontName, Settings.warshUthmaniFontName] {
            let font = try XCTUnwrap(UIFont(name: name, size: 20), name)
            func glyphs(_ number: Int) -> Int {
                let text = NSAttributedString(string: arabicNumberString(from: number), attributes: [.font: font])
                return CTLineGetGlyphCount(CTLineCreateWithAttributedString(text))
            }
            for number in 1...ArabicNumberFace.medallionLimit {
                XCTAssertEqual(glyphs(number), 1, "\(name) \(number)")
                XCTAssertTrue(ArabicNumberFace.draws(number, in: name), "\(name) \(number)")
            }
            for number in [288, 604, 1287, 27_647] {
                XCTAssertGreaterThan(glyphs(number), 1, "\(name) \(number)")
                XCTAssertFalse(ArabicNumberFace.draws(number, in: name), "\(name) \(number)")
            }
        }
        for name in [Settings.indopakFontName, Settings.kufiFontName, Settings.systemArabicFontName] {
            XCTAssertTrue(ArabicNumberFace.draws(27_647, in: name), name)
        }
    }
}
