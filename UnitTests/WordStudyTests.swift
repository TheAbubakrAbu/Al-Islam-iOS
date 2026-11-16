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

    /// The card's coloured word is cut from the painted ayah by TOKEN, never by the raw text's
    /// offsets. Under the Dot notation each hamzat al-wasl is three characters where the raw text
    /// has one, so a raw range sat two characters early per wasl before the word: the last word of
    /// 58:5 showed "ذَابٌ مّ" and of 6:2 a stray mark and "تَمْتَرُو" (Abu, 2026-11-16).
    func testStyledWordIsCutByTokenUnderTheDotNotation() throws {
        let data = QuranData.shared
        for (sid, aid) in [(58, 5), (6, 2), (1, 2)] {
            let surah = try XCTUnwrap(data.quran.first { $0.id == sid })
            let ayah = try XCTUnwrap(surah.ayahs.first { $0.id == aid })
            let raw = ayah.rawArabicText(surahId: sid, qiraahOverride: "")
            let dot = ayah.displayArabicText(surahId: sid, clean: false, removeDots: false, qiraahOverride: "", waslSign: .dot)
            let styled = try XCTUnwrap(
                TajweedStore.shared.attributedText(surah: sid, ayah: aid, text: raw, removeArabicDots: false, waslSign: .dot),
                "\(sid):\(aid) painted nothing"
            )
            let rawRanges = WordTokens.ranges(in: raw)
            let shown = WordTokens.tokens(in: dot)
            XCTAssertEqual(shown.count, rawRanges.count, "\(sid):\(aid) the notation changed the word count")
            for index in shown.indices {
                let cut = try XCTUnwrap(WordTokens.styledToken(index, in: styled, expecting: rawRanges.count))
                XCTAssertEqual(String(cut.characters), shown[index], "\(sid):\(aid) word \(index + 1)")
            }
            // What the card did before: the raw range, read off the painted text, is another word.
            let last = try XCTUnwrap(rawRanges.last)
            XCTAssertNotEqual(NSAttributedString(styled).attributedSubstring(from: last).string, shown[shown.count - 1],
                              "\(sid):\(aid) no wasl before the last word: pick another ayah")
            // A painted text that counts its words differently is refused, not cut on a guess.
            XCTAssertNil(WordTokens.styledToken(0, in: styled, expecting: rawRanges.count + 1))
        }
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
