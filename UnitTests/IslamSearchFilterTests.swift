import XCTest
@testable import iPhone

/// The Islam tab's search after the 2026-11-24 pass (Abu: "Searching up Arabic or for verses and
/// Hadiths in Islam shows nothing", "Support similar searching and filtering search stuff in Islam as
/// there is in Quran"): Arabic without harakat, the quotes' Arabic, references to an ayah or a hadith,
/// numbers matched whole, and the filters (Match, Words, Without, Topics).
final class IslamSearchFilterTests: XCTestCase {
    private let everyHome = Set(IslamArticleHome.allCases)

    private func hits(_ text: String, _ filters: IslamSearchFilters = IslamSearchFilters()) -> [IslamArticleSearch.ContentHit] {
        IslamArticleSearch.contentHits(IslamSearchQuery(text, filters: filters), homes: everyHome, filters: filters, limit: 500)
    }

    // MARK: Arabic

    func testArabicWithoutHarakatFindsTheVowelledPages() {
        XCTAssertFalse(hits("توحيد").isEmpty, "the pages write تَوحِيد")
        XCTAssertFalse(hits("الاستواء").isEmpty, "Imam Malik's answer writes الِاستِوَاءُ")
    }

    func testTheQuotesArabicIsSearched() {
        let found = hits("ليس كمثله شيء")
        XCTAssertTrue(found.contains { $0.article.id == "AsmaSifatView" }, "42:11 is quoted there")
        XCTAssertTrue(found.contains { $0.snippetIsArabic }, "the window is the ayah's Arabic")
    }

    func testTheMushafSpellingMeetsTheTypedOne() {
        // ٱلسَّمَٰوَٰتِ in the ayah cards: the dagger alif read as a full alif (the second lane).
        XCTAssertFalse(hits("السماوات والارض").isEmpty)
    }

    // MARK: References

    func testQuranReferences() {
        XCTAssertEqual(IslamScriptureReference.parse("2:255"), .ayahs(surah: 2, first: 255, last: 255))
        XCTAssertEqual(IslamScriptureReference.parse("Quran 52:35-36"), .ayahs(surah: 52, first: 35, last: 36))
        XCTAssertEqual(IslamScriptureReference.parse("٤٢:١١"), .ayahs(surah: 42, first: 11, last: 11))
        XCTAssertNil(IslamScriptureReference.parse("2:287"), "al-Baqarah has 286 ayahs")
        XCTAssertNil(IslamScriptureReference.parse("115:1"))
        XCTAssertNil(IslamScriptureReference.parse("mercy"))
    }

    func testAVerseReferenceListsThePassagesThatCiteIt() {
        let found = hits("42:11")
        XCTAssertFalse(found.isEmpty)
        for hit in found {
            XCTAssertTrue(hit.section.text.contains("42:11"), "\(hit.article.id) › \(hit.section.heading)")
        }
    }

    func testAHadithReferenceIsExact() throws {
        guard case let .hadith(slug, number, _)? = IslamScriptureReference.parse("bukhari 1") else {
            return XCTFail("bukhari 1 is a hadith reference")
        }
        XCTAssertEqual(slug, "bukhari")
        XCTAssertEqual(number, 1)
        let found = hits("bukhari 1")
        XCTAssertFalse(found.isEmpty, "Bukhari 1 (actions are by intentions) is quoted")
        let exact = try NSRegularExpression(pattern: #"Bukhari 1\b(?![\d])"#)
        for hit in found {
            let text = hit.section.text
            XCTAssertNotNil(exact.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                            "\(hit.article.id) › \(hit.section.heading) does not cite Bukhari 1")
        }
        XCTAssertFalse(hits("Sahih Muslim 867").isEmpty)
    }

    // MARK: Words

    func testNumbersMatchWhole() {
        XCTAssertEqual(IslamSearchQuery.count("1", in: "bukhari 1385 and 1", rule: .contains), 1)
        XCTAssertEqual(IslamSearchQuery.count("25", in: "the 25 prophets 2501", rule: .contains), 1)
    }

    func testMatchRules() {
        let text = IslamArticles.fold("The prayer of those who pray, and spray.")
        XCTAssertEqual(IslamSearchQuery.count("pray", in: text, rule: .contains), 3)
        XCTAssertEqual(IslamSearchQuery.count("pray", in: text, rule: .startsWith), 2)
        XCTAssertEqual(IslamSearchQuery.count("pray", in: text, rule: .wholeWord), 1)
    }

    func testPhraseStepsOverPunctuation() {
        var filters = IslamSearchFilters()
        filters.combine = .phrase
        let text = IslamArticles.fold("Allah, the Most High; and the Most Great.")
        XCTAssertTrue(IslamSearchQuery("allah the most", filters: filters).matches(text))
        XCTAssertFalse(IslamSearchQuery("the allah", filters: filters).matches(text))
        filters.combine = .allWords
        XCTAssertTrue(IslamSearchQuery("great allah", filters: filters).matches(text))
        filters.combine = .anyWord
        XCTAssertTrue(IslamSearchQuery("zzqx great", filters: filters).matches(text))
    }

    func testWithoutLeavesAPassageOut() {
        var filters = IslamSearchFilters()
        filters.excluded = "fire"
        let text = IslamArticles.fold("Paradise and the Fire")
        XCTAssertFalse(IslamSearchQuery("paradise", filters: filters).matches(text))
        XCTAssertTrue(IslamSearchQuery("paradise", filters: filters).matches(IslamArticles.fold("Paradise and its gardens")))
    }

    // MARK: Filters

    func testTopicsNarrowTheArticles() {
        var filters = IslamSearchFilters()
        filters.groups = ["stories/THE 25 PROPHETS NAMED IN THE QURAN"]
        let found = hits("mercy", filters)
        XCTAssertFalse(found.isEmpty)
        XCTAssertTrue(found.allSatisfy { $0.entry?.group == "THE 25 PROPHETS NAMED IN THE QURAN" })
        let titles = IslamArticleSearch.titleHits("ibrahim", homes: everyHome, filters: filters)
        XCTAssertTrue(titles.allSatisfy { $0.group == "THE 25 PROPHETS NAMED IN THE QURAN" })
    }

    func testBestMatchPutsTheStrongestFirst() {
        var filters = IslamSearchFilters()
        filters.sort = .relevance
        let query = IslamSearchQuery("mercy", filters: filters)
        let found = IslamArticleSearch.contentHits(query, homes: everyHome, filters: filters)
        let scores = found.compactMap { query.score($0.section.folded, $0.section.foldedArabic) }
        XCTAssertEqual(scores, scores.sorted(by: >))
    }
}
