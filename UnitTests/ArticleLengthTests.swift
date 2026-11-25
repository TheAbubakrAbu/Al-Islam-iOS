import XCTest
@testable import iPhone

/// Every article in two versions, Short and Full (2026-11-25): one source with parts marked for one version
/// (ArticleLength.swift), a switch at the top of each page, and the search reading the full article.
final class ArticleLengthTests: XCTestCase {
    private let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [.text("In short: both."), .facts("musa")]),
        ArticleSection("BOTH", [
            .text("one"),
            .longOnly(.text("two")),
            .shortOnly(.text("bridge")),
            .text("three"),
        ]),
        ArticleSection("DEEP", only: .long, [.text("only in full")]),
        ArticleSection("BRIEF", only: .short, [.text("only in short")]),
        ArticleSection("EMPTY IN SHORT", [.longOnly(.text("all long"))]),
    ]

    func testEachVersionShowsItsOwnParts() {
        let short = ArticleSection.shown(sections, in: .short)
        XCTAssertEqual(short.map(\.heading), ["SUMMARY", "BOTH", "BRIEF"],
                       "a section the short version shows nothing of is left out")
        XCTAssertEqual(short[1].rows.map(\.index), [0, 2, 3])

        let long = ArticleSection.shown(sections, in: .long)
        XCTAssertEqual(long.map(\.heading), ["SUMMARY", "BOTH", "DEEP", "EMPTY IN SHORT"])
        XCTAssertEqual(long[1].rows.map(\.index), [0, 1, 3])
    }

    func testRowsKeepTheirPlaceInTheArticle() {
        // A switch inserts and removes rows; the rows both versions show keep their identity.
        let short = ArticleSection.shown(sections, in: .short)
        let long = ArticleSection.shown(sections, in: .long)
        XCTAssertEqual(short.first { $0.heading == "BOTH" }?.index, long.first { $0.heading == "BOTH" }?.index)
        XCTAssertEqual(long.first { $0.heading == "DEEP" }?.index, 2)
    }

    func testAMarkIsUnwrapped() {
        guard case .text(let prose)? = ArticleBlock.longOnly(.text("x")).shown(in: .long) else {
            return XCTFail("a long-only block draws its block in the full article")
        }
        XCTAssertEqual(prose, "x")
        XCTAssertNil(ArticleBlock.longOnly(.text("x")).shown(in: .short))
        XCTAssertNil(ArticleBlock.shortOnly(.text("x")).shown(in: .long))
    }

    /// Every page with a switch is a catalog article, and its short version is the shorter.
    @MainActor
    func testTheReadingTimesAreForCatalogArticles() {
        for (id, minutes) in ArticleLengths.minutes {
            XCTAssertNotNil(IslamArticleCatalog.byID[id], "\(id) has reading times but is not in the catalog")
            XCTAssertLessThan(minutes.short, minutes.long, "\(id): the short version is not shorter")
        }
    }

    /// The search reads the full article: a page written twice has passages only the full one shows, and a
    /// hit in one of them opens the page in full (`IslamArticle.Section.only`).
    func testTheSearchKnowsWhatOnlyTheFullArticleHas() {
        let written = Set(ArticleLengths.minutes.keys)
        guard !written.isEmpty else { return }
        let flagged = IslamArticles.all.filter { written.contains($0.id) && $0.sections.contains { $0.only == .long } }
        XCTAssertGreaterThan(flagged.count, written.count / 2,
                             "the pack carries no full-only passages: rebuild it with build_islam_corpus.py")
        for article in IslamArticles.all where !written.contains(article.id) {
            XCTAssertFalse(article.sections.contains { $0.only != nil }, "\(article.id) has marks but no reading times")
        }
    }
}
