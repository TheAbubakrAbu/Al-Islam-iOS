import XCTest
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
}
