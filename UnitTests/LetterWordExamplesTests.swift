import XCTest
@testable import iPhone

/// The letter pages' SEE IT IN WORDS rows: yaa and waaw are looked up once as consonants and once as
/// long vowels (2026-10-24), and each row tints the occurrence it was found at.
final class LetterWordExamplesTests: XCTestCase {

    private static let yaa = "\u{064A}"
    private static let waw = "\u{0648}"

    private static let consonantMarks: Set<Unicode.Scalar> = [
        "\u{064E}", "\u{0650}", "\u{064F}", "\u{064B}", "\u{064D}", "\u{064C}", "\u{0651}",
    ]

    /// The letter an example was found at, with its marks.
    private func letter(_ example: LetterWordExamples.Example) throws -> (letters: [String], index: Int) {
        let letters = ReadingTestText.letters(example.item.arabic)
        let index = try XCTUnwrap(example.letterIndex)
        XCTAssertTrue(letters.indices.contains(index), example.item.arabic)
        return (letters, index)
    }

    func testVowelExamplesAreBareAfterTheirShortVowelAndNeverStartAWord() throws {
        for (key, partner) in [(Self.yaa, Unicode.Scalar("\u{0650}")), (Self.waw, Unicode.Scalar("\u{064F}"))] {
            let examples = LetterWordExamples.examples(for: key, role: .vowel)
            XCTAssertEqual(examples.map(\.position), [.middle, .end], key)
            for example in examples {
                let (letters, index) = try letter(example)
                XCTAssertEqual(letters[index], key, "a long vowel carries no mark: \(example.item.arabic)")
                XCTAssertGreaterThan(index, 0)
                XCTAssertTrue(letters[index - 1].unicodeScalars.contains(partner), example.item.arabic)
            }
        }
    }

    func testConsonantExamplesCarryAMarkOfTheirOwn() throws {
        for key in [Self.yaa, Self.waw] {
            let examples = LetterWordExamples.examples(for: key, role: .consonant)
            XCTAssertEqual(examples.map(\.position), [.start, .middle, .end], key)
            for example in examples {
                let (letters, index) = try letter(example)
                XCTAssertEqual(letters[index].unicodeScalars.first.map(String.init), key)
                XCTAssertTrue(letters[index].unicodeScalars.dropFirst().contains(where: Self.consonantMarks.contains),
                              "a consonant carries a vowel, tanween or shaddah: \(example.item.arabic)")
            }
        }
    }

    /// Every other letter keeps its one start-middle-end set.
    func testOtherLettersAreUnchanged() {
        XCTAssertFalse(LetterWordExamples.hasTwoRoles("\u{0628}"))
        XCTAssertEqual(LetterWordExamples.examples(for: "\u{0628}").map(\.position), [.start, .middle, .end])
        XCTAssertEqual(LetterWordExamples.examples(for: "\u{0649}").map(\.position), [.end])
    }

    /// يَحۡيَىٰ has a yaa at letters 0 and 2: the tint goes where it is asked, and falls back to the
    /// first occurrence when the index is not that letter.
    func testRangeTintsTheRequestedOccurrence() {
        let word = "\u{064A}\u{064E}\u{062D}\u{06E1}\u{064A}\u{064E}\u{0649}\u{0670}"
        let second = ArabicLetterMatch.range(of: Self.yaa, in: word, letterIndex: 2)
        XCTAssertEqual(second.map { String(word[$0]) }, "\u{064A}\u{064E}")
        XCTAssertEqual(second?.lowerBound, word.index(word.startIndex, offsetBy: 2))
        let fallback = ArabicLetterMatch.range(of: Self.yaa, in: word, letterIndex: 1)
        XCTAssertEqual(fallback?.lowerBound, word.startIndex)
    }
}

/// Vowel or consonant (2026-10-28): the rule `VowelLetterRoles` reads off a vowel letter's marks, the
/// examples the letter pages show, the practice rounds, and the tanween written out with its nuun.
final class VowelLetterRolesTests: XCTestCase {

    private typealias Reason = VowelLetterRoles.Reason

    private func reason(_ word: String, _ index: Int) -> Reason? {
        VowelLetterRoles.reason(in: ReadingTestText.letters(word), at: index)?.reason
    }

    func testTheMarksDecideTheRole() {
        // هُوَ: the waaw carries a fatha.
        XCTAssertEqual(reason("\u{0647}\u{064F}\u{0648}\u{064E}", 1), .ownVowel)
        // يَوۡمَ: the yaa opens the word, the waaw has a sukoon after a fatha (leen).
        XCTAssertEqual(reason("\u{064A}\u{064E}\u{0648}\u{06E1}\u{0645}\u{064E}", 0), .opensWord)
        XCTAssertEqual(reason("\u{064A}\u{064E}\u{0648}\u{06E1}\u{0645}\u{064E}", 1), .leen)
        // يَقُولُ: a bare waaw after a damma is the long vowel.
        XCTAssertEqual(reason("\u{064A}\u{064E}\u{0642}\u{064F}\u{0648}\u{0644}\u{064F}", 2), .longVowel)
        // عَدُوٌّ: a shaddah on the waaw.
        XCTAssertEqual(reason("\u{0639}\u{064E}\u{062F}\u{064F}\u{0648}\u{0651}\u{064C}", 2), .shaddah)
        // قَالَ: alif after a fatha.
        XCTAssertEqual(reason("\u{0642}\u{064E}\u{0627}\u{0644}\u{064E}", 1), .alifLong)
        // أَمَرَ: the hamza seat, a consonant.
        XCTAssertEqual(reason("\u{0623}\u{064E}\u{0645}\u{064E}\u{0631}\u{064E}", 0), .hamzaSeat)
        // قَالُواْ: the silent alif after the waaw is no question at all.
        XCTAssertNil(reason("\u{0642}\u{064E}\u{0627}\u{0644}\u{064F}\u{0648}\u{0627}\u{0652}", 4))
        // أَبَدًا: the alif after an "an" tanween is only its seat.
        XCTAssertNil(reason("\u{0623}\u{064E}\u{0628}\u{064E}\u{062F}\u{064B}\u{0627}", 3))
    }

    func testEveryLetterShowsEachOfItsRules() {
        let waaw = Set(VowelLetterRoles.examples(for: VowelLetterRoles.waaw).map(\.reason))
        let yaa = Set(VowelLetterRoles.examples(for: VowelLetterRoles.yaa).map(\.reason))
        for reasons in [waaw, yaa] {
            XCTAssertTrue(reasons.isSuperset(of: [.longVowel, .opensWord, .ownVowel, .shaddah, .leen]), "\(reasons)")
        }
        let alif = Set(VowelLetterRoles.examples(for: VowelLetterRoles.alif).map(\.reason))
        XCTAssertTrue(alif.isSuperset(of: [.alifLong, .hamzaSeat]), "\(alif)")
    }

    func testEveryOccurrenceCanBeTinted() {
        XCTAssertFalse(VowelLetterRoles.all.isEmpty)
        for occurrence in VowelLetterRoles.all {
            for mushaf in [false, true] {
                let shown = ReadingTestText.display(occurrence.item.arabic, mushafMarks: mushaf)
                let range = ArabicLetterMatch.range(of: occurrence.letter, in: shown, letterIndex: occurrence.letterIndex)
                XCTAssertNotNil(range, occurrence.item.arabic)
                if let range {
                    XCTAssertEqual(shown[range].unicodeScalars.first.map { String($0) }, occurrence.letter, occurrence.item.arabic)
                }
            }
        }
    }

    func testRoundsAreBalancedWithNoRepeatedWord() {
        for letter in [nil, VowelLetterRoles.waaw, VowelLetterRoles.yaa] {
            for _ in 0..<20 {
                let round = VowelLetterRoles.round(for: letter)
                XCTAssertEqual(round.count, 10)
                XCTAssertEqual(round.filter(\.reason.isVowel).count, 5)
                XCTAssertEqual(Set(round.map(\.item.arabic)).count, round.count)
                if let letter { XCTAssertTrue(round.allSatisfy { $0.letter == letter }) }
            }
        }
        let alif = VowelLetterRoles.round(for: VowelLetterRoles.alif)
        XCTAssertEqual(alif.count, 10)
        XCTAssertEqual(alif.filter { $0.reason == .hamzaSeat }.count, 4)
    }

    func testTanweenIsWrittenOutWithItsNuun() {
        let baa = "\u{0628}"
        let sukoon = "\u{0652}"
        XCTAssertEqual(tanweenWrittenOut(letter: baa, tanweenName: "Dammatayn", sukoon: sukoon), "\u{0628}\u{064F}\u{0646}\u{0652}")
        XCTAssertEqual(tanweenWrittenOut(letter: baa, tanweenName: "Kasratayn", sukoon: sukoon), "\u{0628}\u{0650}\u{0646}\u{0652}")
        XCTAssertEqual(tanweenWrittenOut(letter: baa, tanweenName: "Fathatayn", sukoon: "\u{06E1}"), "\u{0628}\u{064E}\u{0646}\u{06E1}")
        XCTAssertNil(tanweenWrittenOut(letter: baa, tanweenName: "Fatha"))
        XCTAssertEqual(shaddahWrittenOut(letter: baa, vowel: "\u{064E}", sukoon: "\u{06E1}"), "\u{0628}\u{06E1}\u{0628}\u{064E}")
    }
}
