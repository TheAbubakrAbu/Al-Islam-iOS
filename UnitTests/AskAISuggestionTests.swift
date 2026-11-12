import XCTest
@testable import iPhone

/// The follow-up chips: built from the question's canonical topic (a synonym head) and what the
/// answer cited, never from leftover words, the previous turn's topic, or a dua that does not exist.
final class AskAISuggestionTests: XCTestCase {
    private func chips(_ text: String, previousTopic: String? = nil, hasHistory: Bool = false, duaTopics: Set<String> = []) -> [String] {
        let q = AskAIQuestion.analyze(text, previousTopic: previousTopic, hasHistory: hasHistory)
        return AskAIText.suggestions(for: q, cited: [], duaTopics: duaTopics, starters: AskAIStarters.forDay(1))
    }

    func testNoLeftoverWordsInChips() {
        for (text, junk) in [("I feel lonely and far from God", "feel"), ("What happens to people in hell?", "happens"),
                             ("How do I stop being lazy?", "stop"), ("Who has to pay the mahr?", "pay")] {
            XCTAssertFalse(chips(text).joined().lowercased().contains(junk), text)
        }
    }

    func testKnownTopicIsNamedByItsHead() {
        // "kind" is a stop word, so the topic is "parents".
        XCTAssertTrue(chips("What does the Quran say about being kind to parents?").contains("What do the hadith say about parents?"))
        XCTAssertTrue(chips("What is a good gift for my mother?").contains("What does the Quran say about parents?"))
    }

    func testNoDuaChipWithoutADua() {
        XCTAssertFalse(chips("What does Islam say about homosexuality?", duaTopics: ["anxiety", "travel"]).contains { $0.contains("dua") })
        XCTAssertTrue(chips("How do I deal with anxiety?", duaTopics: ["anxiety"]).contains { $0.contains("dua") })
    }

    /// The dua chip needs a dua for the TOPIC, not for any word in the question ("prophet" is in
    /// many Hisn titles; "Is there a dua for mercy?" was offered on the strength of it).
    func testDuaChipNeedsADuaForTheTopicItself() {
        XCTAssertFalse(chips("What does the Quran say about the Prophet\u{2019}s mercy?", duaTopics: ["prophet"]).contains { $0.contains("dua") })
        XCTAssertTrue(chips("What does the Quran say about sickness?", duaTopics: ["sick"]).contains("Is there a dua for sickness?"))
    }

    /// The topic is a head word when the question has one ("celebrating Eid" is about Eid, not
    /// birthdays), and proper nouns read as names.
    func testTopicPrefersAHeadWordAndNamesItProperly() {
        XCTAssertEqual(AskAILexicon.canonicalTopic(in: ["celebrating", "eid"]), "eid")
        XCTAssertEqual(AskAILexicon.canonicalTopic(in: ["patience", "hardship"]), "patience")
        XCTAssertEqual(AskAILexicon.canonicalTopic(in: ["thankful", "parents"]), "parents")
        XCTAssertEqual(AskAILexicon.canonicalTopic(in: ["prophet", "musa", "staff"]), "moses")
        XCTAssertNil(AskAILexicon.canonicalTopic(in: ["homosexuality"]))
        XCTAssertEqual(AskAILexicon.displayTopic("eid"), "Eid")
        XCTAssertEqual(AskAILexicon.displayTopic("moses"), "Musa")
        XCTAssertEqual(AskAILexicon.displayTopic("patience"), "patience")
        XCTAssertTrue(chips("What does the Quran say about celebrating Eid?").contains("What do the hadith say about Eid?"))
        XCTAssertTrue(chips("What does the Quran say about Prophet Musa?").contains("Which surah speaks most about Musa?"))
        XCTAssertTrue(chips("Who was Prophet Ayyub?").contains("What lessons does the story of Ayyub teach?"))
    }

    func testDefineChipAsksWhatTheProphetSaid() {
        let out = chips("What is sabr?")
        XCTAssertTrue(out.contains("What did the Prophet say about patience?"), out.joined(separator: " | "))
        XCTAssertFalse(out.contains { $0.hasPrefix("Give an example") })
    }

    func testNoOppositeAndNoQuranStoryForAPerson() {
        XCTAssertFalse(chips("What is the nisab for zakat?").contains { $0.contains("opposite") })
        XCTAssertFalse(chips("Who was Imam Malik?").contains { $0.contains("surah tells") })
    }

    func testFollowUpNeverReusesThePreviousTopic() {
        let out = chips("why?", previousTopic: "go back sleep after fajr", hasHistory: true)
        XCTAssertFalse(out.joined().lowercased().contains("sleep"))
    }

    func testGreetingChipsRotateWithTheStarters() {
        XCTAssertEqual(chips("hello"), Array(AskAIStarters.forDay(1).prefix(3)))
        XCTAssertNotEqual(AskAIStarters.forDay(1), AskAIStarters.forDay(2))
    }

    func testDespairIsNotSuicideAndSuicideGetsTheCrisisChips() {
        XCTAssertNotEqual(AskAILexicon.canonicalTopic(for: "despair"), "suicide")
        XCTAssertFalse(AskAILexicon.expand(["despair"]).contains("suicide"))
        XCTAssertFalse(chips("What is despair?").joined().lowercased().contains("suicide"))
        XCTAssertEqual(chips("What is suicide?"), AskAICrisis.suggestions)
        XCTAssertEqual(chips("Is it haram to commit suicide?"), AskAICrisis.suggestions)
    }

    func testCanonicalTopic() {
        XCTAssertEqual(AskAILexicon.canonicalTopic(for: "zakat"), "charity")
        XCTAssertEqual(AskAILexicon.canonicalTopic(for: "hell"), "hell")
        XCTAssertNil(AskAILexicon.canonicalTopic(for: "homosexuality"))
    }
}
