import XCTest
@testable import iPhone

/// The word card's tokens and the riwayat comparisons' spelling key (Quality Guide, Phase 8).
final class WordStudyTests: XCTestCase {

    /// K10: a space carrying a mark (" ۚ", ad-Duri's and as-Susi's 4:44) is cut the same way by the
    /// token list and the UTF-16 ranges a tap is read from. `split` saw one whitespace Character
    /// there, so every word after it was one off.
    func testTokensMatchRangesAcrossAMarkedSpace() {
        // اُ۬لسَّبِيلَ ۚ وَاَللَّهُ
        let text = "\u{0627}\u{064F}\u{06EC}\u{0644}\u{0633}\u{064E}\u{0651}\u{0628}\u{0650}\u{064A}\u{0644}\u{064E} \u{06DA} \u{0648}\u{064E}\u{0627}\u{064E}\u{0644}\u{0644}\u{064E}\u{0651}\u{0647}\u{064F}"
        let ranges = WordTokens.ranges(in: text)
        let tokens = WordTokens.tokens(in: text)
        XCTAssertEqual(ranges.count, 3)
        XCTAssertEqual(tokens, ranges.map { (text as NSString).substring(with: $0) })
        XCTAssertEqual(WordTokens.count(in: text), ranges.count)
        XCTAssertEqual(tokens[1], "\u{06DA}")
    }

    /// K4: two prints read alike when only the silent letter ring (kept by Hafs's text alone), a stop
    /// sign, or the marks' byte order differ. A vowel is a reading.
    func testSpellingKey() {
        // كَفَرُواْ, كَفَرُوا
        XCTAssertEqual(QiraahSpelling.key("\u{0643}\u{064E}\u{0641}\u{064E}\u{0631}\u{064F}\u{0648}\u{0627}\u{0652}"),
                       QiraahSpelling.key("\u{0643}\u{064E}\u{0641}\u{064E}\u{0631}\u{064F}\u{0648}\u{0627}"))
        // بِأَعۡدَآئِكُمۡۚ, بِأَعۡدَآئِكُمۡ
        XCTAssertEqual(QiraahSpelling.key("\u{0628}\u{0650}\u{0623}\u{064E}\u{0639}\u{06E1}\u{062F}\u{064E}\u{0622}\u{0626}\u{0650}\u{0643}\u{064F}\u{0645}\u{06E1}\u{06DA}"),
                       QiraahSpelling.key("\u{0628}\u{0650}\u{0623}\u{064E}\u{0639}\u{06E1}\u{062F}\u{064E}\u{0622}\u{0626}\u{0650}\u{0643}\u{064F}\u{0645}\u{06E1}"))
        // shadda then fatha, fatha then shadda
        XCTAssertEqual(QiraahSpelling.key("\u{0644}\u{0651}\u{064E}"), QiraahSpelling.key("\u{0644}\u{064E}\u{0651}"))
        // a stop sign standing as a word of its own leaves no double space
        XCTAssertEqual(QiraahSpelling.key("\u{0628}\u{064E} \u{06DA} \u{0648}\u{064E}"), QiraahSpelling.key("\u{0628}\u{064E} \u{0648}\u{064E}"))
        // مَٰلِكِ, مَلِكِ
        XCTAssertNotEqual(QiraahSpelling.key("\u{0645}\u{064E}\u{0670}\u{0644}\u{0650}\u{0643}\u{0650}"),
                          QiraahSpelling.key("\u{0645}\u{064E}\u{0644}\u{0650}\u{0643}\u{0650}"))
    }
}
