import XCTest
@testable import iPhone

/// The Arabic Alphabet screen's search finds its SECTIONS, not only its letters (Abu, 2026-11-08: "I'll
/// say hamzatul wasl and only the letter will show up not the section").
final class ArabicTopicSearchTests: XCTestCase {

    private func ids(_ query: String) -> [String] {
        ArabicTopicCatalog.matching(query).map(\.id)
    }

    func testEveryRowOfTheScreenIsATopic() {
        let all = ArabicTopicCatalog.all.map(\.id)
        for expected in ["families", "soundAlikes", "readingTest", "tashkeel", "defaultTashkeel", "basics",
                         "baaHaa", "laamAlif", "maqsurahYaa", "vowelLetters", "vowelPractice",
                         "wasl", "waslStart", "waslTanween", "waslReadOn",
                         "pronouns", "noun", "verb", "harf", "numbers", "signs", "quiz"] {
            XCTAssertTrue(all.contains(expected), expected)
        }
        for tier in ReadingTier.all {
            XCTAssertTrue(all.contains("tier:" + tier.id), tier.id)
        }
        XCTAssertEqual(Set(all).count, all.count, "topic ids are unique")
    }

    func testHamzatulWaslFindsThePageAndItsDrillsPageFirst() {
        for query in ["hamzatul wasl", "Hamzatul WaSl", "hamzat al-wasl", "hamzat al wasl", "wasl", "همزة الوصل", "connecting hamza"] {
            let found = ids(query)
            XCTAssertEqual(found.first, "wasl", query)
            for drill in ["waslStart", "waslTanween", "waslReadOn"] {
                XCTAssertTrue(found.contains(drill), "\(query) should find \(drill): \(found)")
            }
        }
        // The Reading Test's own tier for it answers too.
        XCTAssertTrue(ids("hamzat al-wasl").contains("tier:wasl"))
    }

    func testTanweenFindsTheDrillTheTierAndTheTashkeelTable() {
        let found = ids("tanween")
        XCTAssertTrue(found.contains("waslTanween"), "\(found)")
        XCTAssertTrue(found.contains("tier:tanween"), "\(found)")
        XCTAssertTrue(found.contains("tashkeel"), "\(found)")
        // The one NAMED Tanween leads the ones that mention it.
        XCTAssertTrue(found.prefix(2).contains("tier:tanween"), "\(found)")
    }

    func testEveryTypedWordMustHit() {
        XCTAssertEqual(ids("tanween wasl").first, "waslTanween")
        XCTAssertFalse(ids("tanween wasl").contains("tier:tanween"), "the tier says nothing about wasl")
        XCTAssertTrue(ids("laam alif").contains("laamAlif"))
        XCTAssertFalse(ids("laam alif").contains("baaHaa"))
    }

    func testSectionsWithoutAPageScroll() {
        XCTAssertEqual(ArabicTopicCatalog.numbers.opens, .scroll(rowID: ArabicTopicRowID.numbers))
        XCTAssertEqual(ArabicTopicCatalog.signs.opens, .scroll(rowID: ArabicTopicRowID.signs))
        XCTAssertTrue(ids("numbers").contains("numbers"))
        XCTAssertTrue(ids("digits").contains("numbers"))
        XCTAssertTrue(ids("waqf").contains("signs"))
        XCTAssertTrue(ids("mandatory stop").contains("signs"), "a sign's own name finds the section")
        for topic in ArabicTopicCatalog.all where topic.opens != .page {
            XCTAssertTrue(topic.id == "numbers" || topic.id == "signs", topic.id)
        }
    }

    func testShortQueriesAnswerNothingUntilThreeLetters() {
        XCTAssertEqual(ids("b"), [])
        XCTAssertEqual(ids("ba"), [])
        XCTAssertEqual(ids("  "), [])
        XCTAssertFalse(ids("baa").isEmpty)
        // Two Arabic letters are already a word.
        XCTAssertTrue(ids("لا").contains("laamAlif"))
    }

    func testLatinAccentsAreFolded() {
        XCTAssertEqual(ids("hamzatul waṣl").first, "wasl")
        XCTAssertEqual(ids("tashkīl").first, "tashkeel")
    }

    func testGrammarAndVowelLetters() {
        XCTAssertEqual(ids("pronouns").first, "pronouns")
        XCTAssertTrue(ids("iraab").contains("noun"))
        XCTAssertTrue(ids("i'raab").contains("basics"))
        XCTAssertEqual(ids("vowel letters").first, "vowelLetters")
        XCTAssertTrue(ids("vowel or consonant").contains("vowelPractice"))
        XCTAssertEqual(ids("maqsurah").first, "maqsurahYaa")
    }

    func testTheOrderOfTiesIsTheScreensOrder() {
        // "drill" is a keyword of exactly these four, none of which is named for it, so they tie and
        // come back in the order the screen shows them: the vowel practice, then the three wasl drills.
        XCTAssertEqual(ids("drill"), ["vowelPractice", "waslStart", "waslTanween", "waslReadOn"])
    }
}
