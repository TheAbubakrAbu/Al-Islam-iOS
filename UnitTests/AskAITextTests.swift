import XCTest
@testable import iPhone

/// `AskAIText.normalizeMarkers`: citation markers rewritten to "[n]", the ones naming no source removed.
final class AskAITextTests: XCTestCase {

    /// U1: a sourceless turn with a marker at position 0 used to trap on `1...0`.
    func testZeroSourcesMarkerAtStart() {
        let result = AskAIText.normalizeMarkers("[1] Wa alaikum assalam!", sourceCount: 0)
        XCTAssertEqual(result.text, "Wa alaikum assalam!")
        XCTAssertEqual(result.removed, 1)
    }

    /// U1: a sourceless marker mid-sentence goes, with the space before it.
    func testZeroSourcesMarkerBeforePunctuation() {
        let result = AskAIText.normalizeMarkers("Peace be upon you [1].", sourceCount: 0)
        XCTAssertEqual(result.text, "Peace be upon you.")
        XCTAssertEqual(result.removed, 1)
    }

    /// U1: the parenthetical "(source 1)" form with no sources.
    func testZeroSourcesParentheticalMarker() {
        let result = AskAIText.normalizeMarkers("As the source says (source 1), yes.", sourceCount: 0)
        XCTAssertEqual(result.text, "As the source says, yes.")
        XCTAssertEqual(result.removed, 1)
    }

    /// U1: glued and grouped markers with no sources are all removed and counted.
    func testZeroSourcesGroupedMarkers() {
        let result = AskAIText.normalizeMarkers("[2][4] and [1, 3]", sourceCount: 0)
        XCTAssertFalse(result.text.contains("["), result.text)
        XCTAssertEqual(result.text, "and")
        XCTAssertEqual(result.removed, 4)
    }

    /// U1: the four probe shapes of `-askAITextProbe` never trap and leave no bracket.
    func testZeroSourcesProbeShapes() {
        for text in ["[1] Wa alaikum assalam!", "Peace be upon you [1].", "As the source says (source 1), yes.", "[2][4] and [1, 3]"] {
            let result = AskAIText.normalizeMarkers(text, sourceCount: 0)
            XCTAssertFalse(result.text.contains("["), "\(text) -> \(result.text)")
            XCTAssertGreaterThan(result.removed, 0, text)
        }
    }

    /// U1: a valid marker stays, an out-of-range one goes, and a glued marker gets its space.
    func testMixedValidAndInvalidMarkers() {
        let result = AskAIText.normalizeMarkers("Patience is light[1][3].", sourceCount: 2)
        XCTAssertEqual(result.text, "Patience is light [1].")
        XCTAssertEqual(result.removed, 1)
    }

    /// U1: one bracket group with several numbers becomes one bracket per number, deduplicated.
    func testGroupSplitAndDeduplicated() {
        XCTAssertEqual(AskAIText.normalizeMarkers("Pray [1, 2].", sourceCount: 2).text, "Pray [1][2].")
        XCTAssertEqual(AskAIText.normalizeMarkers("Pray [1, 1].", sourceCount: 2).text, "Pray [1].")
        XCTAssertEqual(AskAIText.normalizeMarkers("Pray [Source 3].", sourceCount: 3).text, "Pray [3].")
    }

    /// U1: "[0]" names no source even when sources exist.
    func testMarkerZeroIsRemoved() {
        let result = AskAIText.normalizeMarkers("Fast on Monday [0].", sourceCount: 3)
        XCTAssertEqual(result.text, "Fast on Monday.")
        XCTAssertEqual(result.removed, 1)
    }

    /// U1: empty text is returned untouched.
    func testEmptyText() {
        let result = AskAIText.normalizeMarkers("", sourceCount: 0)
        XCTAssertEqual(result.text, "")
        XCTAssertEqual(result.removed, 0)
    }

    /// U1: every surviving "[n]" names a real source, for every source count and marker position.
    func testSurvivingMarkersAlwaysNameASource() {
        let shapes = [
            "[1] Opening.", "[3] Opening.", "Middle [2] here.", "End [4]", "Glued[1][5].",
            "(source 2) first.", "Two (sources 1 and 3).", "[1, 2, 3, 4] all.", "[Source 12] far.",
            "[1]", "[9]", " [1] ", "Line one [2]\n[3] line two.",
        ]
        let markerRegex = try! NSRegularExpression(pattern: #"\[(\d+)\]"#)
        for count in 0...4 {
            for shape in shapes {
                let result = AskAIText.normalizeMarkers(shape, sourceCount: count)
                let ns = result.text as NSString
                for match in markerRegex.matches(in: result.text, range: NSRange(location: 0, length: ns.length)) {
                    let n = Int(ns.substring(with: match.range(at: 1))) ?? -1
                    XCTAssertTrue(n >= 1 && n <= count, "sourceCount \(count): \(shape) -> \(result.text)")
                }
            }
        }
    }
}

/// The questions an article page's Ask AI offers (`AskAIChatView.articleQuestions`) are new questions
/// whatever came before them: read as a follow-up they would fold the last topic into the search, and
/// read as a recap they would rework the last answer instead of reading the article.
final class AskAIArticleQuestionTests: XCTestCase {
    @MainActor
    func testArticleQuestionsStandAloneAfterAnotherConversation() {
        for title in ["Salah", "Zakah", "How to Pray", "Belief in the Angels", "Muqatta'at Letters", "Is music allowed?"] {
            let article = IslamArticle(id: "TestView", title: title, sections: [], foldedTitle: title.lowercased())
            for question in AskAIChatView.articleQuestions(article) {
                let analyzed = AskAIQuestion.analyze(question, previousTopic: "zakat", hasHistory: true)
                XCTAssertFalse(analyzed.isFollowUp, question)
                XCTAssertNotEqual(analyzed.intent, .recap, question)
                XCTAssertTrue(analyzed.intent.retrieves, question)
            }
        }
    }
}

/// `IslamArticle.summarySource`: what "Summarize with AI" hands the model for an article page.
final class ArticleSummarySourceTests: XCTestCase {

    private func article(_ sections: [(String, String)]) -> IslamArticle {
        IslamArticle(id: "Test", title: "Test",
                     sections: sections.map { IslamArticle.Section(heading: $0.0, text: $0.1, folded: IslamArticles.fold($0.1)) },
                     foldedTitle: "test")
    }

    /// A page that fits goes whole, each section under its heading, in order.
    func testAShortPageGoesWhole() {
        let source = article([("", "Opening words."), ("RULE", "The rule itself.")]).summarySource(limit: 1_000)
        XCTAssertFalse(source.truncated)
        XCTAssertEqual(source.text, "Opening words.\n\nRULE\nThe rule itself.")
    }

    /// A long page keeps EVERY section, each cut to its share, so the summary covers the whole page.
    func testALongPageKeepsEverySection() {
        let sentence = "This sentence is here to make the section long. "
        let page = article((1...12).map { ("SECTION \($0)", String(repeating: sentence, count: 40)) })
        let source = page.summarySource(limit: 6_000)
        XCTAssertTrue(source.truncated)
        XCTAssertLessThanOrEqual(source.text.count, 6_001)
        for number in 1...12 {
            XCTAssertTrue(source.text.contains("SECTION \(number)\n"), "section \(number) was dropped")
        }
    }

    /// Without Arabic support the Arabic words go, and the brackets they leave empty go with them.
    func testArabicIsLeftOutWhenTheModelHasNone() {
        let source = article([("", "The round sukoon (\u{0640}\u{0652}) is read in عَنْهُ, a hadith word.")])
            .summarySource(limit: 1_000, keepArabic: false)
        XCTAssertEqual(source.text, "The round sukoon is read in, a hadith word.")
        XCTAssertNil(source.text.range(of: "[\\u0600-\\u06FF]", options: .regularExpression))
    }

    /// A real Tajweed Foundations page reaches the model as English prose.
    func testATajweedPageSummarizesInEnglish() throws {
        let page = try XCTUnwrap(IslamArticles.all.first { $0.id == "TajweedSukoonView" })
        let source = page.summarySource(limit: OnDeviceAsk.summarizeSourceLimit, keepArabic: false)
        XCTAssertTrue(source.text.contains("Uthmani sukoon"))
        XCTAssertNil(source.text.range(of: "[\\u0600-\\u06FF]", options: .regularExpression))
    }
}

/// What to answer from (Abu, 2026-11-24: "specifically look at Quran or Hadith or whatever"), and the
/// prayer times of another place or day ("can it ... look at prayer times at other times and places?").
@MainActor
final class AskAIScopeAndPlaceTests: XCTestCase {
    /// A library keeps its own sources and nothing else; Everything keeps all.
    func testAScopeKeepsOnlyItsLibrary() {
        let ayah = AskAISource.Kind.ayah(surah: 2, ayah: 153)
        let hadith = AskAISource.Kind.hadith(slug: "bukhari", idInBook: 1)
        let article = AskAISource.Kind.article(id: "salah", heading: "Timings")
        let city = AskAISource.Kind.cityPrayer(latitude: 51.5, longitude: -0.12, city: "London", day: Date())
        XCTAssertTrue(AskAIScope.everything.admits(hadith))
        XCTAssertTrue(AskAIScope.quran.admits(ayah))
        XCTAssertTrue(AskAIScope.quran.admits(.tafsir(surah: 2, ayah: 153, author: "Ibn Kathir")))
        XCTAssertFalse(AskAIScope.quran.admits(hadith))
        XCTAssertFalse(AskAIScope.hadith.admits(ayah))
        XCTAssertTrue(AskAIScope.articles.admits(article))
        XCTAssertTrue(AskAIScope.duas.admits(.name(number: 47)))
        XCTAssertTrue(AskAIScope.prayerTimes.admits(city))
        XCTAssertFalse(AskAIScope.prayerTimes.admits(ayah))
        // The two libraries this app ships are offered, and every choice says what to ask.
        XCTAssertTrue(AskAIScope.available.contains(.quran))
        XCTAssertTrue(AskAIScope.available.contains(.hadith))
        for scope in AskAIScope.available { XCTAssertEqual(scope.starters.count, 4, scope.rawValue) }
    }

    #if HAS_ADHAN
    /// The place after "in", "for" or "of", whether or not it is capitalised, and the day as written.
    func testAPrayerQuestionNamesItsPlaceAndDay() {
        func read(_ question: String) -> (String?, String?) {
            let request = AskAIPrayerRequest.parse(question)
            return (request.place, request.dayPhrase)
        }
        XCTAssertEqual(read("What time is Fajr in London tomorrow?").0, "London")
        XCTAssertEqual(read("What time is Fajr in London tomorrow?").1, "tomorrow")
        XCTAssertEqual(read("maghrib in cairo on friday").0, "cairo")
        XCTAssertEqual(read("When is Isha in New York City next Monday?").0, "New York City")
        XCTAssertEqual(read("prayer times in Irvine, CA the day after tomorrow").0, "Irvine, CA")
        XCTAssertEqual(read("Prayer times in Medina, Saudi Arabia").0, "Medina, Saudi Arabia")
        // "in Ramadan" is a month, not a place; the place after it still counts.
        XCTAssertEqual(read("When is maghrib in Ramadan in Istanbul").0, "Istanbul")
        // No place: today's times where the reader is (or another day there).
        XCTAssertNil(read("What time is Fajr?").0)
        XCTAssertNil(read("What time do I pray fajr in the morning").0)
        XCTAssertNil(read("When should I pray Isha in the winter").0)
        XCTAssertNil(read("what time is dhuhr in 3 days").0)
        XCTAssertNotNil(AskAIPrayerRequest.parse("what time is dhuhr in 3 days").day)
        XCTAssertTrue(AskAIPrayerRequest.parse("What time is Maghrib today?").isPlainToday)
    }
    #endif
}
