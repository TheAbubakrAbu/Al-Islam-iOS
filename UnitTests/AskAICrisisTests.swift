import XCTest
@testable import iPhone

/// `AskAICrisis`: a first-person expression of suicidal intent or self-harm gets a reply the app
/// writes itself (no model, no retrieval, nothing kept as history); a question ABOUT suicide stays
/// a question and only earns the help line beneath its answer.
final class AskAICrisisTests: XCTestCase {

    func testFirstPersonIntentIsACrisis() {
        for text in ["I feel like ending my life", "i want to kill myself", "I don't want to live anymore",
                     "I've been thinking about suicide", "wish I was dead", "I keep hurting myself",
                     "I wanna die", "I've been self-harming", "I do not want to live", "I cannot go on",
                     "I can't go on like this", "I'm going to die tonight and I want it", "im suicidal",
                     "I want to commit suicide", "I cut myself when it gets bad"] {
            XCTAssertTrue(AskAICrisis.isCrisis(text), text)
        }
    }

    func testInformationalMentionIsNotACrisis() {
        for text in ["Is suicide haram?", "What does Islam say about suicide?", "I want to die as a Muslim",
                     "What happens to someone who kills himself?", "Is it haram to commit suicide?",
                     "Is committing suicide a major sin?", "Is self-harm haram?",
                     "My father is going to die soon, what dua can I read?", "I can't go on Hajj this year",
                     "If I cut myself shaving, does my wudu break?", "I hurt myself during sujood, can I pray sitting?"] {
            XCTAssertFalse(AskAICrisis.isCrisis(text), text)
        }
        for text in ["Is suicide haram?", "Is it haram to commit suicide?", "Is self-harm haram?",
                     "What happens to someone who kills himself?"] {
            XCTAssertTrue(AskAICrisis.mentionsSelfHarm(text), text)
        }
        XCTAssertFalse(AskAICrisis.mentionsSelfHarm("What is the nisab for zakat?"))
    }

    /// The thread before a crisis is over: a later "why?" must not continue it.
    func testCrisisEndsTheEarlierThread() {
        typealias Message = AskAIConversation.Message
        var crisis = Message(role: .assistant, text: "I am really glad you told me.")
        crisis.intent = .crisis
        let messages = [
            Message(role: .user, text: "What happens to people in hell?"),
            Message(role: .assistant, text: "Pride in sin leads to a wretched resting place.", intent: .general),
            Message(role: .user, text: "I feel like ending my life"),
            crisis,
        ]
        XCTAssertTrue(AskAIConversation.completedTurns(in: messages).isEmpty)
        XCTAssertNil(AskAIConversation.previousReply(in: messages))
        let later = messages + [Message(role: .user, text: "What is sabr?"),
                                Message(role: .assistant, text: "Patience.", intent: .define)]
        XCTAssertEqual(AskAIConversation.completedTurns(in: later).map(\.question), ["What is sabr?"])
        XCTAssertEqual(AskAIConversation.previousReply(in: later)?.text, "Patience.")
    }

    @MainActor func testCrisisTurnClearsTheTopicMidConversation() async {
        let conversation = AskAIConversation.shared
        conversation.reset()
        conversation.seedTopicForTesting("hell")
        conversation.ask("I feel like ending my life")
        await Task.yield()
        XCTAssertNil(conversation.topic)
        conversation.reset()
    }

    @MainActor func testReplyCitesEaseOnlyWhenTheVerseIsFirst() {
        XCTAssertTrue(AskAICrisis.reply(citingEase: true).contains("[1]"))
        XCTAssertFalse(AskAICrisis.reply(citingEase: false).contains("[1]"))
        let sources = AskAICrisis.sources()
        if case .ayah(let surah, let ayah)? = sources.first?.kind {
            XCTAssertEqual([surah, ayah], [94, 5])
            XCTAssertTrue(AskAICrisis.reply.contains("[1]"))
        } else {
            XCTAssertFalse(AskAICrisis.reply.contains("[1]"))
        }
    }

    /// Arabic and Urdu first-person shapes, on the folded text (hamza forms fold to a bare alif).
    func testArabicAndUrduFirstPersonIntentIsACrisis() {
        for text in ["أريد أن أموت", "اريد ان اقتل نفسي", "أفكر في الانتحار", "أفكر بالانتحار", "لا أريد أن أعيش", "سأنتحر",
                     "أتمنى الموت", "أريد أن أنهي حياتي", "لم أعد أريد الحياة", "أؤذي نفسي",
                     "میں مرنا چاہتا ہوں", "مرنا چاہتی ہوں", "میں خودکشی کرنا چاہتا ہوں", "میں زندہ نہیں رہنا چاہتی",
                     "اپنی جان لینا چاہتا ہوں", "میں خودکشی کے بارے میں سوچ رہا ہوں", "میں خود کو نقصان پہنچاتا ہوں",
                     "مرنے کو دل کرتا ہے", "خود کو مار لوں؟"] {
            XCTAssertTrue(AskAICrisis.isCrisis(text), text)
        }
        for text in ["هل الانتحار حرام؟", "ما حكم الانتحار في الإسلام؟", "ما حكم من قتل نفسه؟", "کیا خودکشی حرام ہے؟",
                     "خودکشی کے بارے میں اسلام کیا کہتا ہے؟", "کیا خود کو نقصان پہنچانا حرام ہے؟"] {
            XCTAssertFalse(AskAICrisis.isCrisis(text), text)
            XCTAssertTrue(AskAICrisis.mentionsSelfHarm(text), text)
        }
        for text in ["لا أريد أن أموت قبل الحج", "میرا دوست مرنا چاہتا ہے", "متى أموت؟"] {
            XCTAssertFalse(AskAICrisis.isCrisis(text), text)
        }
    }

    /// The help line is a thing to tap, not only to read.
    func testHelpLineActionOpensTheNumber() {
        XCTAssertEqual(AskAICrisis.helpLineAction(regionCode: "US")?.url.absoluteString, "tel:988")
        XCTAssertEqual(AskAICrisis.helpLineAction(regionCode: "GB")?.url.absoluteString, "tel:116123")
        XCTAssertEqual(AskAICrisis.helpLineAction(regionCode: "AU")?.url.absoluteString, "tel:131114")
        XCTAssertEqual(AskAICrisis.helpLineAction(regionCode: "EG")?.url.absoluteString, "https://findahelpline.com")
        XCTAssertFalse(AskAICrisis.helpLineAction(regionCode: "US")?.label.isEmpty ?? true)
    }

    @MainActor func testCrisisTurnOffersTheHelpLine() async {
        let conversation = AskAIConversation.shared
        conversation.reset()
        conversation.ask("I feel like ending my life")
        await Task.yield()
        XCTAssertEqual(conversation.messages.last?.offersHelpLine, true)
        conversation.reset()
    }

    func testHelpLineFallsBackToTheFinder() {
        XCTAssertTrue(AskAICrisis.helpLine(regionCode: "US").contains("988"))
        XCTAssertTrue(AskAICrisis.helpLine(regionCode: "GB").contains("116 123"))
        XCTAssertTrue(AskAICrisis.helpLine(regionCode: "EG").contains("findahelpline.com"))
        XCTAssertTrue(AskAICrisis.helpLine(regionCode: nil).contains("findahelpline.com"))
    }

    @MainActor func testReplyHasNoEmDashAndCitesOnlyItsSources() {
        XCTAssertFalse(AskAICrisis.reply.contains("\u{2014}"))
        let markers = AskAIText.normalizeMarkers(AskAICrisis.reply, sourceCount: AskAICrisis.sources().count)
        XCTAssertEqual(markers.removed, 0)
    }

    @MainActor func testCrisisTurnLeavesNoHistoryOrTopic() async {
        let conversation = AskAIConversation.shared
        conversation.reset()
        conversation.ask("I feel like ending my life")
        await Task.yield()
        XCTAssertEqual(conversation.messages.last?.intent, .crisis)
        XCTAssertFalse(conversation.isAnswering)
        XCTAssertTrue(conversation.completedTurns().isEmpty)
        XCTAssertNil(conversation.topic)
        conversation.reset()
    }
}
