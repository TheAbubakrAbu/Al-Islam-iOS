import XCTest
@testable import iPhone

/// The ranked hadith lane (`HadithRankedSearch`), against the shipped shelf. Each test pins an order
/// that was measured WRONG before 2026-10-02, when rows of equal worth came out in book order and one
/// word in a chapter's name outranked the hadith itself.
final class HadithRankedSearchTests: XCTestCase {

    private typealias Shelf = [(book: HadithCatalogBook, data: HadithBookData)]

    private func shelf() async -> Shelf {
        var books: Shelf = []
        for book in HadithCatalogBook.all {
            if let data = await HadithStore.shared.openOffMain(book) { books.append((book, data)) }
        }
        HadithVocabulary.shared.buildIfNeeded(books: books.map(\.data))
        return books
    }

    private struct Row {
        let reference: String
        let text: String
    }

    private func search(_ query: String, in books: Shelf, cap: Int = 8) throws -> (rows: [Row], outcome: HadithRankedSearch.ShelfOutcome, query: HadithRankedSearch.Query) {
        let parsed = try XCTUnwrap(HadithRankedSearch.parse(query, vocabulary: HadithVocabulary.shared))
        let outcome = HadithRankedSearch.rankShelf(books: books, query: parsed, cap: cap)
        let rows = outcome.top.map { hit -> Row in
            let entry = books[hit.bookIndex]
            let hadith = entry.data.hadiths[hit.row]
            let text = hadith.allText
            return Row(reference: "\(entry.book.slug):\(hadith.idInBook)", text: parsed.isArabic ? text.arabic : text.text)
        }
        return (rows, outcome, parsed)
    }

    /// A short narration that is ABOUT the word leads a long one that mentions it once.
    func testShortFocusedNarrationLeads() async throws {
        let books = await shelf()
        try XCTSkipIf(books.count < HadithCatalogBook.all.count, "the shelf did not open")
        let patience = try search("patience", in: books)
        XCTAssertEqual(patience.rows.first?.reference, "bukhari:1260")
        for row in patience.rows { XCTAssertLessThan(row.text.count, 600, row.reference) }

        let honesty = try search("honesty", in: books)
        XCTAssertTrue(honesty.rows.first?.text.contains("When honesty is lost") ?? false)
    }

    /// One word of several in a chapter's name does not make the chapter about the query.
    func testPartOfAChapterNameIsNotAboutTheQuery() async throws {
        let books = await shelf()
        try XCTSkipIf(books.count < HadithCatalogBook.all.count, "the shelf did not open")
        let found = try search("actions are by intentions", in: books, cap: 5)
        XCTAssertFalse(found.outcome.relaxed)
        for row in found.rows {
            let text = row.text.lowercased()
            XCTAssertTrue(text.contains("actions") && text.contains("intention"), "\(row.reference): \(row.text.prefix(80))")
        }
    }

    /// A chapter whose name IS the query still lifts its narrations, but never a stub with no text.
    func testChapterAboutTheQueryLeadsWithoutStubs() async throws {
        let books = await shelf()
        try XCTSkipIf(books.count < HadithCatalogBook.all.count, "the shelf did not open")
        let anger = try search("anger", in: books)
        XCTAssertTrue(anger.rows.first?.reference.hasPrefix("aladab_almufrad:") ?? false)
        for row in anger.rows {
            XCTAssertFalse(row.text.hasPrefix("A variant of the previous hadith"), row.reference)
        }
    }

    func testSeveralWordsAndTypos() async throws {
        let books = await shelf()
        try XCTSkipIf(books.count < HadithCatalogBook.all.count, "the shelf did not open")
        let anger = try search("controlling anger", in: books)
        XCTAssertFalse(anger.outcome.relaxed)
        XCTAssertEqual(anger.rows.first?.reference, "bukhari:5882")

        let typo = try search("intetion", in: books)
        XCTAssertEqual(typo.query.corrections.map(\.to), ["intention"])
        XCTAssertTrue(typo.rows.first?.text.lowercased().contains("intention") ?? false)

        // The phrase as typed, small words included, is what a narration says.
        let parents = try search("kindness to parents", in: books)
        XCTAssertTrue(parents.rows.first?.text.lowercased().contains("kindness to parents") ?? false)
    }

    func testArabicPhrase() async throws {
        let books = await shelf()
        try XCTSkipIf(books.count < HadithCatalogBook.all.count, "the shelf did not open")
        let found = try search("إنما الأعمال بالنيات", in: books)
        XCTAssertEqual(found.rows.first?.reference, "bukhari:1")
    }

    /// A stem is matched at the START of a word: "kindness" reaches "kind", never "mankind".
    func testStemMatchesAtAWordStartOnly() throws {
        let query = try XCTUnwrap(HadithRankedSearch.parse("kindness", vocabulary: nil))
        let token = try XCTUnwrap(query.tokens.first)
        func worth(_ text: String) -> Int {
            var bytes = Array(text.utf8)
            return bytes.withUnsafeMutableBufferPointer { HadithRankedSearch.tokenHit(token, in: UnsafeBufferPointer($0), weight: 3) }
        }
        XCTAssertEqual(worth("the lord of mankind"), 0)
        XCTAssertGreaterThan(worth("be kind to your neighbour"), 0)
        XCTAssertGreaterThan(worth("kindness is from faith"), worth("be kind to your neighbour"))
    }
}
