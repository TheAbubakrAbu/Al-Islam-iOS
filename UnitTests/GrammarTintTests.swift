import XCTest
@testable import iPhone

/// The grammar pages tint the word or ending a row is about (`GrammarTint`, 2026-10-28). An ending is
/// found where it LAST occurs, as whole letters, and the Quran text's mark order must not hide it.
final class GrammarTintTests: XCTestCase {

    private func tinted(_ pieces: [String], in text: String, every: Bool = false) -> [String] {
        GrammarTint.ranges(of: pieces, in: text, every: every).map { String(text[$0]) }
    }

    /// كَتَبۡتَ: the root's own taa (its second letter) is also تَ, and must stay plain.
    func testAnEndingIsFoundWhereItLastOccurs() {
        let text = "كَتَبۡتَ"
        let ranges = GrammarTint.ranges(of: ["تَ"], in: text)
        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual(ranges.first?.upperBound, text.endIndex)
    }

    /// إِيَّاكَ said twice in 1:5: `every` tints both.
    func testEveryTintsEachOccurrence() {
        let text = "إِيَّاكَ نَعۡبُدُ وَإِيَّاكَ نَسۡتَعِينُ"
        XCTAssertEqual(tinted(["إِيَّاكَ"], in: text, every: true).count, 2)
        XCTAssertEqual(tinted(["إِيَّاكَ"], in: text).count, 1)
    }

    /// Quran.json stores shaddah THEN fatha; a piece typed fatha then shaddah still matches.
    func testMarkOrderDoesNotHideAPiece() {
        let sourceOrder = "\u{0625}\u{0650}\u{0646}\u{0651}\u{064E}"   // إِنَّ, shaddah first
        let typedOrder = "\u{0625}\u{0650}\u{0646}\u{064E}\u{0651}"    // إِنَّ, fatha first
        XCTAssertEqual(tinted([typedOrder], in: sourceOrder + " ٱللَّهَ").count, 1)
    }

    /// A piece never matches part of a letter: a bare noon is not the noon of نَّ.
    func testAPieceMatchesWholeLettersOnly() {
        XCTAssertTrue(tinted(["\u{0646}"], in: "إِنَّ").isEmpty)
        XCTAssertEqual(tinted(["هُمۡ"], in: "رَبُّهُمۡ"), ["هُمۡ"])
    }

    /// The tint and the Allah highlight share one attributed string with the same characters.
    func testAttributedKeepsTheText() {
        let text = "إِنَّ ٱللَّهَ غَفُورٞ رَّحِيمٞ"
        let ranges = GrammarTint.ranges(of: ["إِنَّ"], in: text)
        let attributed = GrammarTint.attributed(text, ranges: ranges, color: .green, highlightAllah: true)
        XCTAssertEqual(String(attributed.characters), text)
    }
}
