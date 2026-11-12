import XCTest
@testable import iPhone

/// `AskAIQuestion.analyze`: what is a follow-up (needs the previous turn) and what is a question
/// about today's prayer schedule, against the questions the 2026-11-05 review saw misrouted.
final class AskAIIntentTests: XCTestCase {
    private func q(_ text: String, topic: String? = "zina punishment", history: Bool = true) -> AskAIQuestion {
        AskAIQuestion.analyze(text, previousTopic: topic, hasHistory: history)
    }

    func testQuestionsWithTheirOwnAntecedentAreNotFollowUps() {
        for text in ["Can a man hit his wife?", "Is it haram to dye my hair?", "Is this game allowed?",
                     "Is it true that the Prophet fasted on Mondays?", "What did the Prophet say about his neighbours?"] {
            XCTAssertFalse(q(text).isFollowUp, text)
        }
    }

    func testRealFollowUpsStayFollowUps() {
        for text in ["why?", "and zakat?", "tell me more", "who narrated that?", "is it sahih?", "what about fasting",
                     "explain this", "who was his father?", "is that hadith authentic?"] {
            XCTAssertTrue(q(text).isFollowUp, text)
        }
    }

    func testFiqhQuestionsAboutPrayerAreNotPrayerTimes() {
        for text in ["Can I combine prayers when traveling?", "What is the best time to pray?", "When should I pray Witr?",
                     "Can I shorten my prayers on a journey?", "I missed Fajr, what do I do?"] {
            XCTAssertNotEqual(q(text, history: false).intent, .prayerTimes, text)
        }
        XCTAssertEqual(q("Can I combine prayers when traveling?", history: false).intent, .ruling)
    }

    func testReviewGapsAreInTheLexicon() {
        XCTAssertTrue(AskAILexicon.expand(["zina"]).contains("adultery"))
        XCTAssertTrue(AskAILexicon.expand(["mahr"]).contains("dowry") || AskAILexicon.expand(["mahr"]).contains("dower"))
        XCTAssertTrue(AskAILexicon.expand(["apostasy"]).contains("riddah"))
        // 24:2 and 17:32 say "sexual intercourse" in the shipped Saheeh text, "adultery" only in Mustafa.
        XCTAssertEqual(Array(AskAILexicon.expand(["zina"]).prefix(3)), ["zina", "sexual intercourse", "adultery"])
        // One way: lawful intercourse ("Do I need ghusl after sexual intercourse?") must not search zina.
        XCTAssertFalse(AskAILexicon.expand(["sexual intercourse"]).contains("zina"))
        XCTAssertFalse(AskAILexicon.expand(["lashes"]).contains("zina"))
        XCTAssertNil(AskAILexicon.canonicalTopic(for: "sexual intercourse"))
        // A hint phrase matches whole: "show much" is not "how much".
        XCTAssertTrue(AskAILexicon.phraseHints(in: "how much is zakat").contains("amount"))
        XCTAssertFalse(AskAILexicon.phraseHints(in: "does the quran show much mercy").contains("amount"))
    }

    /// "this issue" points back the way "this verse" does; "is it the same" keeps "it" pointing back.
    func testDemonstrativesAndExpletivesTheReviewFlagged() {
        for text in ["What is the ruling on this issue?", "Is it the same for women?", "Is this practice from the Quran?"] {
            XCTAssertTrue(q(text).isFollowUp, text)
        }
        XCTAssertFalse(q("Is it haram for women to sing?").isFollowUp)
    }

    /// A clock question with a schedule word asks for the time even when "should" is in it; a
    /// fiqh word without that shape keeps the question out of the timetable.
    func testClockShapeWithAScheduleWordBeatsAFiqhWord() {
        #if HAS_ADHAN
        XCTAssertEqual(q("What time should I pray Fajr tomorrow?", history: false).intent, .prayerTimes)
        #endif
        for text in ["I missed Isha tonight, can I still pray it?", "Is it makruh to pray at sunrise?", "When should I pray Witr?"] {
            XCTAssertNotEqual(q(text, history: false).intent, .prayerTimes, text)
        }
    }

    func testScheduleQuestionsArePrayerTimes() {
        #if HAS_ADHAN
        for text in ["When is Fajr?", "What time is Isha tonight?", "How long until Maghrib?", "Is it Asr yet?",
                     "What are today's prayer times?", "fajr", "next prayer"] {
            XCTAssertEqual(q(text, history: false).intent, .prayerTimes, text)
        }
        #endif
    }
}

