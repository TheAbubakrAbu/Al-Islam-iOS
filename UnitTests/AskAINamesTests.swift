import XCTest
@testable import iPhone

/// The Names of Allah lane: a Name is retrieved when the question writes it as a Name (with its
/// article, or beside a cue word such as "name"), never because an ordinary English word happens
/// to fold onto one ("mother" is not Al-Musawwir, "money" is not Al-Mani, "game" is not Al-Jami).
final class AskAINamesTests: XCTestCase {
    @MainActor private func names(_ text: String) -> [String] {
        AskAIRetriever.exactNames(in: AskAIQuestion.analyze(text, previousTopic: nil, hasHistory: false)).map(\.transliteration)
    }

    @MainActor private func loadNames() async throws {
        await NamesViewModel.shared.waitUntilLoaded()
        try XCTSkipIf(NamesViewModel.shared.namesOfAllah.isEmpty, "Names not loaded in the host")
    }

    @MainActor func testBareEnglishWordsAreNotNames() async throws {
        try await loadNames()
        for text in ["What is the name of the Prophet's mother?", "What is the mahr?", "How do I save money?",
                     "Is this game allowed?", "Who was Imam Malik?", "What is a good gift for my mother?"] {
            XCTAssertEqual(names(text), [], text)
        }
    }

    @MainActor func testArticledOrCuedNamesMatch() async throws {
        try await loadNames()
        XCTAssertEqual(names("What does Al-Wadud mean?"), ["Al-Wadood"])
        XCTAssertEqual(names("explain ar rahman"), ["Ar-Rahmaan"])
        XCTAssertEqual(names("what does al wadood mean"), ["Al-Wadood"])
        XCTAssertEqual(names("Is Aziz a good name for a boy?"), ["Al-Azeez"])
        XCTAssertEqual(names("what does the name malik mean"), ["Al-Malik"])
    }

    func testAsmaAloneIsNotTheNamesOfAllah() {
        XCTAssertFalse(AskAILexicon.expand(["asma"]).contains("names of allah"))
        XCTAssertTrue(AskAILexicon.expand(["asma", "ul", "husna"]).contains("names of allah"))
    }
}
