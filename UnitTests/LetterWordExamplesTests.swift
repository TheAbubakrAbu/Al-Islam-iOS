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
