import XCTest
@testable import iPhone

extension AskAISource {
    /// A test-only ayah source whose text has exactly `characters` characters.
    static func fixture(reference: String, characters: Int) -> AskAISource {
        let parts = reference.split(separator: ":").compactMap { Int($0) }
        return AskAISource(kind: .ayah(surah: parts.first ?? 2, ayah: parts.last ?? 1),
                           reference: reference, title: "Al-Baqarah \(reference)",
                           text: String(repeating: "x", count: characters))
    }
}

/// `AskAIPrompt`: what the model is shown of the conversation, and what fits the window.
final class AskAIPromptTests: XCTestCase {
    private func question(_ text: String, previousTopic: String? = nil, hasHistory: Bool = true) -> AskAIQuestion {
        AskAIQuestion.analyze(text, previousTopic: previousTopic, hasHistory: hasHistory)
    }
    private let turn = AskAIPrompt.Turn(question: "What happens to people in hell?", answer: "Pride in sin leads to a wretched resting place.")

    func testStandaloneQuestionGetsNoHistory() {
        let prompt = AskAIPrompt.build(question: question("I feel lonely and far from God"), sources: [], history: [turn], profile: .onDevice)
        XCTAssertFalse(prompt.contains("EARLIER IN THIS CONVERSATION"))
        XCTAssertFalse(prompt.contains("wretched"))
    }

    func testFollowUpGetsHistory() {
        let prompt = AskAIPrompt.build(question: question("why?", previousTopic: "hell"), sources: [], history: [turn], profile: .onDevice)
        XCTAssertTrue(prompt.contains("EARLIER IN THIS CONVERSATION"))
        XCTAssertTrue(prompt.contains("wretched"))
    }

    func testFitChargesHistoryOnlyWhenSent() {
        // 16 sources of 500 characters overflow the 4,096-token estimate on their own (13 fit);
        // the history (about 550 characters once clipped), charged only on the follow-up, costs one more.
        let sources = (0..<16).map { AskAISource.fixture(reference: "2:\($0 + 1)", characters: 500) }
        let long = AskAIPrompt.Turn(question: turn.question, answer: String(repeating: "Patience is light. ", count: 80))
        let standalone = AskAIPrompt.fit(question: question("What is the nisab for zakat?"), sources: sources, history: [long], profile: .onDevice)
        let followUp = AskAIPrompt.fit(question: question("why?", previousTopic: "zakat"), sources: sources, history: [long], profile: .onDevice)
        XCTAssertGreaterThan(standalone.count, followUp.count)
        XCTAssertLessThan(standalone.count, sources.count)
    }

    @available(iOS 26.0, *)
    func testGuardrailMessageNamesTheSources() {
        XCTAssertTrue(AskAIEngine.message(for: .guardrail)?.contains("sources") == true)
    }

    func testProfileScalesWithTheWindow() {
        XCTAssertEqual(AskAIProfile.onDevice(contextTokens: 4096).sourceLimit, 8)
        XCTAssertEqual(AskAIProfile.onDevice(contextTokens: 8192).sourceLimit, 12)
        XCTAssertEqual(AskAIProfile.onDevice(contextTokens: 8192).sourceCharacters, 600)
    }

    func testEstimateKeepsEightSourcesInTheOnDeviceWindow() {
        let sources = (0..<8).map { AskAISource.fixture(reference: "2:\($0 + 1)", characters: 500) }
        let kept = AskAIPrompt.fit(question: question("What is the nisab for zakat?"), sources: sources, history: [], profile: .onDevice)
        XCTAssertEqual(kept.count, 8)
    }

    func testMeasuredFitDropsUntilTheCountFits() async {
        let sources = (0..<8).map { AskAISource.fixture(reference: "2:\($0 + 1)", characters: 500) }
        // A tokenizer that charges two tokens per character makes even two 500-character sources overflow: the floor of 2 holds.
        let kept = await AskAIPrompt.fit(question: question("What is the nisab for zakat?"), sources: sources, history: [], profile: .onDevice, measure: { $0.count * 2 })
        XCTAssertEqual(kept.count, 2)
        let generous = await AskAIPrompt.fit(question: question("What is the nisab for zakat?"), sources: sources, history: [], profile: .onDevice, measure: { $0.count / 10 })
        XCTAssertEqual(generous.count, 8)
    }

    func testInstructionsCarryNoSamplePhraseAndADeclinePath() {
        let instructions = AskAIPrompt.instructions
        XCTAssertFalse(instructions.lowercased().contains("scholars generally"))
        // A decline path, described, never a quotable template: the model parroted "the app's
        // library has nothing on it" at the end of answers it had just written from the sources.
        XCTAssertTrue(instructions.contains("none of the sources answers the question"))
        XCTAssertFalse(instructions.contains("nothing on it"))
        XCTAssertFalse(instructions.contains("(\""))
        XCTAssertFalse(AskAIIntent.general.taskLine.contains("general knowledge"))
        // The prayer timetable is described only on the turn that has one: told about a "Prayer
        // times today" source on every turn, the model invented a timetable for "What is the best
        // time to pray?" (no prayer source retrieved) and said it was "exactly as written".
        XCTAssertFalse(instructions.contains("Prayer times today"))
        // Since 2026-11-24 the source can be any place and any day (`AskAIPrayerRequest`): the task
        // names the source by its mark, and says what to do with a place that could not be found.
        XCTAssertTrue(AskAIIntent.prayerTimes.taskLine.contains("prayer times source marked SUBJECT OF THE QUESTION"))
        XCTAssertTrue(AskAIIntent.prayerTimes.taskLine.contains("could not be found"))
        // Rule 6 forbids invented clock times only: "How many rakahs is Fajr?" and "How many days is
        // Ramadan?" still get their numbers.
        XCTAssertTrue(instructions.contains("time of day"))
        XCTAssertFalse(instructions.contains("a date or a number"))
    }

    /// `-askAIForceDecline` (DEBUG) makes the engine fail the way a guardrail does, so the decline
    /// card can be seen without a question the permissive model would decline.
    func testForcedDeclineClassifiesAsAGuardrail() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("FoundationModels needs iOS 26") }
        if case .guardrail = AskAIEngine.classify(AskAIEngine.ForcedDecline()) {} else { XCTFail("not a guardrail") }
    }

    /// A transcript an older build saved (no `declined`, no `intent`, an intent this build does not
    /// know) still reads; a failed answer with prose before its failure line is still an answer.
    func testOldTranscriptsDecodeAndPartialProseCounts() throws {
        typealias Message = AskAIConversation.Message
        let old = """
        [{"role":"user","text":"What is sabr?"},
         {"role":"assistant","text":"Patience.","sources":[],"isStreaming":false,"failed":false,"intent":"somethingNew"}]
        """.data(using: .utf8)!
        let messages = try JSONDecoder().decode([Message].self, from: old)
        XCTAssertEqual(messages.count, 2)
        XCTAssertFalse(messages[1].declined)
        XCTAssertNil(messages[1].intent)
        XCTAssertFalse(messages[1].offersHelpLine)
        var partial = Message(role: .assistant, text: "The verse says...\n\n(Apple Intelligence declined to write about this.)")
        partial.failed = true
        partial.sources = [AskAISource.fixture(reference: "2:153", characters: 40)]
        XCTAssertTrue(partial.hasAnswerProse)
        var bare = Message(role: .assistant, text: "Apple Intelligence declined to write about this.")
        bare.failed = true
        XCTAssertFalse(bare.hasAnswerProse)
        XCTAssertTrue(Message(role: .assistant, text: "Patience.").hasAnswerProse)
    }
}
