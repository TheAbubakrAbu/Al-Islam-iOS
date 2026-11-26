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
        let source = page.summarySource(limit: 6_000, keepArabic: false)
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

    /// What a question asks for beside the times, and what is never a place: "the last third of the
    /// night tonight" once left "the" as a place, and the map found a village for it (2026-11-25).
    func testPrayerRequestTopicsAndFillerPlaces() {
        func topics(_ raw: String) -> AskAIPrayerRequest.Topics { AskAIPrayerRequest.parse(raw).topics }
        XCTAssertNil(AskAIPrayerRequest.parse("When is the last third of the night tonight?").place)
        XCTAssertTrue(topics("When is the last third of the night tonight?").contains(.night))
        XCTAssertTrue(topics("When does Isha end tonight?").contains(.night))
        XCTAssertTrue(topics("Tahajjud time tonight?").contains(.night))
        XCTAssertTrue(topics("When is iftar today?").contains(.fasting))
        XCTAssertTrue(topics("How many rakahs is Maghrib?").contains(.rakahs))
        XCTAssertTrue(topics("What calculation method do my prayer times use?").contains(.method))
        XCTAssertTrue(topics("What is the Hijri date today?").contains(.hijri))
        XCTAssertTrue(topics("Which direction is the qibla from here?").contains(.qibla))
        XCTAssertNil(AskAIPrayerRequest.parse("Which direction is the qibla from here?").place)
        XCTAssertEqual(AskAIPrayerRequest.parse("Qibla direction in London").place, "London")
        XCTAssertTrue(topics("What time is Fajr?").isEmpty)

        let ramadan = AskAIPrayerRequest.parse("When is Ramadan next year?")
        XCTAssertTrue(ramadan.topics.contains(.events))
        XCTAssertEqual(ramadan.eventWords, ["ramadan"])
        XCTAssertNil(ramadan.place)
        XCTAssertFalse(ramadan.wantsTimes)
        XCTAssertTrue(AskAIPrayerRequest.parse("When is iftar today?").wantsTimes)

        let week = AskAIPrayerRequest.parse("What are the prayer times in London this week?")
        XCTAssertEqual(week.place, "London")
        XCTAssertTrue(week.topics.contains(.week))
        XCTAssertEqual(AskAIPrayerRequest.parse("prayer times for the next 3 days").days, 3)
        XCTAssertNil(AskAIPrayerRequest.parse("prayer times for the next 3 days").place)
    }

    /// A follow-up keeps the place and the day of the question before it, and only a question the app
    /// computes an answer to is taken from the library ("why did the qibla change" stays there).
    func testPrayerFollowUpsInheritAndDateQuestionsRoute() {
        let first = AskAIPrayerRequest.parse("What time is Fajr in Makkah tomorrow?")
        let cairo = AskAIPrayerRequest.parse("And in Cairo?").inheriting(first)
        XCTAssertEqual(cairo.place, "Cairo")
        XCTAssertEqual(cairo.dayPhrase, "tomorrow")
        // The prayer asked about carries over too, until the follow-up names its own.
        XCTAssertEqual(cairo.prayers, ["Fajr"])
        let maghrib = AskAIPrayerRequest.parse("What about Maghrib?").inheriting(cairo)
        XCTAssertEqual(maghrib.place, "Cairo")
        XCTAssertNotNil(maghrib.day)
        XCTAssertEqual(maghrib.prayers, ["Maghrib"])
        // "until" asks how long, not when Isha's time ends; iftar is Maghrib's time.
        XCTAssertFalse(AskAIPrayerRequest.parse("How long until Isha?").topics.contains(.night))
        XCTAssertEqual(AskAIPrayerRequest.parse("How long until Isha?").prayers, ["Isha"])
        XCTAssertEqual(AskAIPrayerRequest.parse("When is iftar today?").prayers, ["Maghrib"])
        XCTAssertTrue(AskAIPrayerRequest.parse("What is the next prayer?").prayers.isEmpty)
        XCTAssertTrue(AskAIPrayerRequest.parse("What about Maghrib?").continuesPrayerTalk)
        XCTAssertFalse(AskAIPrayerRequest.parse("Why is that?").continuesPrayerTalk)

        XCTAssertTrue(AskAIPrayerRequest.asksDateOrDirection("when is ramadan next year?"))
        XCTAssertTrue(AskAIPrayerRequest.asksDateOrDirection("how many days until eid?"))
        XCTAssertTrue(AskAIPrayerRequest.asksDateOrDirection("what is the hijri date today?"))
        XCTAssertTrue(AskAIPrayerRequest.asksDateOrDirection("which direction is the qibla from here?"))
        XCTAssertFalse(AskAIPrayerRequest.asksDateOrDirection("why did the qibla change from jerusalem?"))
        XCTAssertFalse(AskAIPrayerRequest.asksDateOrDirection("what is the virtue of fasting arafah?"))
        XCTAssertFalse(AskAIPrayerRequest.asksDateOrDirection("when should i fast in ramadan?"))
        XCTAssertFalse(AskAIPrayerRequest.asksDateOrDirection("what is the hijri calendar?"))
        XCTAssertFalse(AskAIPrayerRequest.asksDateOrDirection("what does the quran say about patience?"))
        // The counts of the five prayers are the app's own; a prayer outside the day's list is the library's.
        XCTAssertTrue(AskAIPrayerRequest.asksRakahCount("how many rakahs is maghrib?"))
        XCTAssertFalse(AskAIPrayerRequest.asksRakahCount("how many rakahs is tahajjud?"))
        XCTAssertFalse(AskAIPrayerRequest.asksRakahCount("how many rakahs is dhuhr when traveling?"))
        XCTAssertFalse(AskAIPrayerRequest.asksRakahCount("what time is maghrib?"))
    }
    #endif

    #if canImport(FoundationModels)
    /// A long text is cut for reading where a paragraph or a sentence ends, never mid-word, and every
    /// character of it lands in exactly one part.
    func testSummaryPartsCutAtParagraphsAndSentences() {
        let paragraph = String(repeating: "The scholars explained this verse at length. ", count: 20)
            .trimmingCharacters(in: .whitespaces)
        let text = Array(repeating: paragraph, count: 12).joined(separator: "\n\n")
        var rest = Substring(text)
        var parts: [Substring] = []
        while !rest.isEmpty {
            let part = OnDeviceAsk.head(of: rest, limit: 2_000)
            XCTAssertLessThanOrEqual(part.count, 2_000)
            XCTAssertFalse(part.isEmpty)
            parts.append(part)
            rest = rest[part.endIndex...]
        }
        XCTAssertEqual(parts.map(String.init).joined(), text)
        XCTAssertTrue(parts.dropLast().allSatisfy { $0.hasSuffix("\n\n") })
        // No paragraph break in reach: the cut falls after a sentence.
        XCTAssertTrue(OnDeviceAsk.head(of: Substring(paragraph), limit: 300).hasSuffix("."))
        XCTAssertEqual(String(OnDeviceAsk.head(of: "short", limit: 300)), "short")
    }

    /// A paragraph that ran into its token ceiling loses its unfinished sentence, and a question about
    /// a long text is answered from the passages that hold its words, in the text's order.
    func testSummaryWholeSentencesAndPassages() {
        XCTAssertEqual(OnDeviceAsk.wholeSentences("  The first point. The second point. The third was cut off mid"),
                       "The first point. The second point.")
        XCTAssertEqual(OnDeviceAsk.wholeSentences("A finished paragraph."), "A finished paragraph.")
        XCTAssertEqual(OnDeviceAsk.wholeSentences("no sentence end at all"), "no sentence end at all")

        let filler = String(repeating: "This part speaks of other matters entirely and at some length. ", count: 14)
        let text = [filler, "Then the Throne is described: the Kursi extends over the heavens and the earth.", filler,
                    "Finally the intercession is explained: none may intercede except by His permission.", filler]
            .joined(separator: "\n\n")
        XCTAssertEqual(OnDeviceAsk.passages(of: "short text", for: "anything", limit: 2_000), "short text")
        let found = OnDeviceAsk.passages(of: text, for: "What does it say about intercession?", limit: 2_000)
        XCTAssertLessThanOrEqual(found.count, 2_100)
        XCTAssertTrue(found.contains("none may intercede"))
        XCTAssertTrue(found.contains("[...]"))
        // A question that names nothing in the text is answered from its opening.
        let opening = OnDeviceAsk.passages(of: text, for: "What is the main point?", limit: 2_000)
        XCTAssertTrue(text.hasPrefix(opening))
    }
    #endif

    // MARK: - A passage found from its description (2026-11-25)

    /// The description search's stemmer brings a word's forms together, and no further.
    func testDescribedSearchStemsAndConcepts() {
        XCTAssertEqual(AskAIWords.stem("killing"), "kill")
        XCTAssertEqual(AskAIWords.stem("killed"), "kill")
        XCTAssertEqual(AskAIWords.stem("children"), "child")
        XCTAssertEqual(AskAIWords.stem("shaded"), AskAIWords.stem("shade"))
        XCTAssertEqual(AskAIWords.stem("loving"), AskAIWords.stem("loves"))
        XCTAssertEqual(AskAIWords.stem("buried"), AskAIWords.stem("bury"))
        // An apostrophe's tail goes, an accent is the plain letter, a number is written out.
        XCTAssertEqual(AskAIWords.words("your brother's flesh"), ["your", "brother", "flesh"])
        XCTAssertEqual(AskAIWords.words("Muḥammad ˹said˺"), ["muhammad", "said"])
        XCTAssertEqual(AskAIWords.queryStems("the people who slept for 300 years"),
                       ["people", "slept", "three", "hundred", "years"].map(AskAIWords.stem))
        XCTAssertEqual(AskAIWords.queryStems("Verse about the man who killed 99 people"),
                       ["man", "killed", "ninety", "nine", "people"].map(AskAIWords.stem))
        // A verse reference is not a number to write out.
        XCTAssertEqual(AskAIWords.spellingOutNumbers(in: "explain 2:255"), "explain 2:255")
        // The concepts that make "killing their children out of shame" reach "bury" and "humiliation".
        func related(_ word: String, _ other: String) -> Bool {
            AskAIWords.related[AskAIWords.stem(word)]?.contains(AskAIWords.stem(other)) == true
        }
        XCTAssertTrue(related("shame", "humiliation"))
        XCTAssertTrue(related("shame", "disgrace"))
        XCTAssertTrue(related("children", "daughter"))
        XCTAssertTrue(related("killing", "bury"))
        XCTAssertFalse(related("shame", "kill"))
    }

    /// A question that LOOKS FOR a passage, against one that asks what scripture teaches.
    func testQuestionsThatLookForAPassage() {
        func finds(_ text: String) -> Bool { AskAIQuestion.analyze(text, previousTopic: nil, hasHistory: false).findsPassage }
        XCTAssertTrue(finds("Verse about fathers killing their children out of shame"))
        XCTAssertTrue(finds("Which verse says the two seas do not mix?"))
        XCTAssertTrue(finds("Is there a hadith about smiling being charity?"))
        XCTAssertTrue(finds("Where does the Quran say Allah is closer than the jugular vein?"))
        XCTAssertTrue(finds("Hadith about the woman who went to hell because of a cat"))
        XCTAssertFalse(finds("What does the Quran say about patience?"))
        XCTAssertFalse(finds("How do I make wudu?"))
        XCTAssertFalse(finds("Explain 2:255"))
        XCTAssertFalse(finds("What is tawhid?"))
    }

    /// The model saying where a passage is and quoting it is kept (its marker moved to the end); a
    /// source line copied out of the prompt, with its provenance, still goes.
    func testAReferenceWithItsQuotationIsNotASourceEcho() {
        let hadith = AskAISource(kind: .hadith(slug: "tirmidhi", idInBook: 1956), reference: "Jami` at-Tirmidhi 1956",
                                 title: "Jami` at-Tirmidhi 1956", text: "Your smiling in the face of your brother is charity.",
                                 provenance: ["Jami` at-Tirmidhi, compiled by Imam at-Tirmidhi"])
        let kept = AskAIText.droppingSourceEchoes("[1] Jami` at-Tirmidhi 1956, \u{201C}Your smiling in the face of your brother is charity.\u{201D}\n\nSmiling is charity.",
                                                  sources: [hadith])
        XCTAssertEqual(kept, "Jami` at-Tirmidhi 1956, \u{201C}Your smiling in the face of your brother is charity.\u{201D} [1]\n\nSmiling is charity.")
        let dropped = AskAIText.droppingSourceEchoes("[1] Jami` at-Tirmidhi 1956 (Jami` at-Tirmidhi, compiled by Imam at-Tirmidhi): Your smiling\n\nSmiling is charity.",
                                                     sources: [hadith])
        XCTAssertEqual(dropped, "Smiling is charity.")
    }

    /// What the app itself writes of a found passage: its reference and words, and what else is close.
    func testThePassageTheAppWritesItself() {
        func ayah(_ surah: Int, _ number: Int, _ name: String, _ text: String) -> AskAISource {
            AskAISource(kind: .ayah(surah: surah, ayah: number), reference: "\(surah):\(number)", title: "\(name) \(surah):\(number)", text: text)
        }
        let sources = [ayah(81, 8, "At-Takwir", "And when the girl [who was] buried alive is asked"),
                       ayah(81, 9, "At-Takwir", "For what sin she was killed"),
                       ayah(16, 58, "An-Nahl", "And when one of them is informed of [the birth of] a female, his face becomes dark, and he suppresses grief."),
                       ayah(6, 151, "Al-An'am", "Say, Come, I will recite what your Lord has prohibited to you.")]
        let named = AskAIConversation.PassageAnswer(sources: sources, count: 2)
        XCTAssertEqual(named.lead, "Surah At-Takwir 81:8 [1]: \u{201C}And when the girl [who was] buried alive is asked\u{201D}\n\nSurah At-Takwir 81:9 [2]: \u{201C}For what sin she was killed\u{201D}\n\n")
        XCTAssertEqual(named.tail, "\n\nAlso close: An-Nahl 16:58 [3], Al-An'am 6:151 [4].")
        XCTAssertEqual(named.promptSources, 2)
        let quoted = AskAIConversation.PassageAnswer(sources: sources, count: 2, quotesSecond: true)
        XCTAssertTrue(quoted.tail.hasPrefix("\n\nAlso close: Surah An-Nahl 16:58 [3]: \u{201C}And when one of them"))
        XCTAssertTrue(quoted.tail.hasSuffix("\n\nOther places to look: Al-An'am 6:151 [4]."))
        XCTAssertEqual(AskAIConversation.PassageAnswer(missed: ()).promptSources, 0)
    }

    /// The shipped search words open, and hold every collection the hadith lane reads.
    @MainActor
    func testShippedSearchWordsAreReadable() throws {
        let tafsir = try XCTUnwrap(SearchWordsPack.load("TafsirKeywords", subdirectory: "Quran"))
        XCTAssertEqual(tafsir.editions.map(\.slug), ["en-tafsir-ibn-kathir", "en-tafsir-maarif-ul-quran", "en-tafsir-tazkirul-quran"])
        XCTAssertTrue(tafsir.editions.allSatisfy { $0.ayahs.count == 6_236 && !$0.passages.isEmpty })
        XCTAssertTrue(tafsir.words.contains("daughters"))
        let hadith = try XCTUnwrap(SearchWordsPack.load("HadithSearchWords", subdirectory: "Hadith"))
        XCTAssertEqual(hadith.editions.map(\.slug), ["bukhari", "muslim", "nawawi40", "riyad_assalihin", "tirmidhi", "abudawud", "nasai", "ibnmajah"])
        // Each collection's rows are the pack's own rows: a rebuilt .hpk without rebuilt words is left out, not misread.
        for edition in hadith.editions {
            let book = try XCTUnwrap(HadithCatalogBook.bySlug[edition.slug])
            XCTAssertEqual(HadithStore.shared.book(book)?.hadiths.count, edition.passages.count, edition.slug)
        }
    }

    /// The search itself, on the Quran the app ships: descriptions that share no word with the verse.
    @MainActor
    func testDescribedVersesAreFound() async throws {
        await QuranData.shared.waitUntilLoaded()
        let index = try await XCTUnwrapAsync(await QuranDescribedSearch.index(quranData: QuranData.shared))
        XCTAssertTrue(index.hasTafsir)
        func first(_ description: String, _ count: Int = 1) -> [String] {
            index.search(description, limit: 12).prefix(count).map { "\($0.surah):\($0.ayah)" }
        }
        XCTAssertEqual(first("Which verse mentions burying baby girls alive?"), ["81:8"])
        XCTAssertEqual(first("Verse about wives being a garment for you"), ["2:187"])
        XCTAssertEqual(first("Verse about the spider's house being the weakest"), ["29:41"])
        XCTAssertEqual(first("Verse about backbiting being like eating your dead brother's flesh"), ["49:12"])
        XCTAssertEqual(first("Where does the Quran say Allah is closer than the jugular vein?"), ["50:16"])
        XCTAssertEqual(first("the people who slept for 300 years"), ["18:25"])
        // Abu's own example: the verses meant are among the first, though no word of theirs is his.
        let shame = first("Verse about fathers killing their children out of shame", 6)
        XCTAssertTrue(shame.contains("81:8") && shame.contains("6:151"), "\(shame)")
        XCTAssertTrue(first("Verse about fathers killing their children out of shame", 12).contains("16:59"))
        // Nothing to find is nothing found.
        XCTAssertTrue(index.search("Is there a verse about dinosaurs?", limit: 5).isEmpty)
        // A hit says how much of the description it carries, and names the verse that finishes its sentence.
        let girl = try XCTUnwrap(index.search("Which verse mentions burying baby girls alive?", limit: 3).first)
        XCTAssertTrue(girl.isConfident)
    }

    private func XCTUnwrapAsync<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) async throws -> T {
        try XCTUnwrap(value, file: file, line: line)
    }

    // MARK: - The Prayer Tracker and two places (2026-11-25)

    #if HAS_ADHAN
    func testTrackerQuestionsAndComparedPlaces() {
        // The reader's own record, and the clock: the app's, not a ruling.
        XCTAssertTrue(AskAIPrayerRequest.asksTracker("Did I pray Fajr today?"))
        XCTAssertTrue(AskAIPrayerRequest.asksTracker("Did I miss Dhuhr?"))
        XCTAssertTrue(AskAIPrayerRequest.asksTracker("Which prayers have I prayed today?"))
        XCTAssertEqual(AskAIQuestion.analyze("Did I miss Dhuhr?", previousTopic: nil, hasHistory: false).intent, .prayerTimes)
        // What to DO about a missed prayer is the library's.
        XCTAssertFalse(AskAIPrayerRequest.asksTracker("I missed Fajr, what should I do?"))
        XCTAssertFalse(AskAIPrayerRequest.asksTracker("How do I make up a missed prayer?"))
        XCTAssertFalse(AskAIPrayerRequest.asksTracker("What time is Fajr?"))
        // The same words asking for a time, or for what is allowed, are not about the record.
        XCTAssertFalse(AskAIPrayerRequest.parse("What time should I pray Fajr tomorrow?").topics.contains(.tracker))
        XCTAssertFalse(AskAIPrayerRequest.parse("Can I pray Asr now?").topics.contains(.tracker))
        XCTAssertTrue(AskAIPrayerRequest.parse("Have I prayed Asr?").topics.contains(.tracker))
        XCTAssertEqual(AskAIPrayerRequest.parse("Did I pray Asr?").prayers, ["Asr"])
        // Two places, in the order written; one place stays one.
        XCTAssertEqual(AskAIPrayerRequest.places(in: "What time is Fajr in Makkah and Cairo?"), ["Makkah", "Cairo"])
        let compared = AskAIPrayerRequest.parse("What time is Fajr in Makkah and Cairo?")
        XCTAssertEqual(compared.place, "Cairo")
        XCTAssertEqual(compared.morePlaces, ["Makkah"])
        XCTAssertEqual(AskAIPrayerRequest.parse("Prayer times in London").morePlaces, [])
        XCTAssertEqual(AskAIPrayerRequest.parse("Prayer times in London and how long until Asr").morePlaces, [])
        // Eight starters for the Prayer Times choice, four a day, each a key of the catalog.
        XCTAssertEqual(AskAIScope.prayerTimes.starters.count, 4)
        XCTAssertEqual(Set(AskAIScope.prayerTimes.starters).count, 4)
    }
    #endif
}
