import XCTest
@testable import iPhone

/// Arabic with Quranic marks inside English prose (`QuranicInline`, Globals.swift): only the runs that
/// carry a mark the system face cannot draw are found, a phrase stays one run, and plain Arabic is left
/// to the system face.
final class QuranicInlineTests: XCTestCase {
    private func found(_ text: String) -> [String] {
        let string = text as NSString
        return QuranicInline.ranges(in: text).map { string.substring(with: $0) }
    }

    func testFindsTheMarkedWordInsideEnglish() {
        XCTAssertEqual(found("like the “al-” of ٱلۡحَمۡدُ. The mushafs"), ["ٱلۡحَمۡدُ"])
    }

    func testAPhraseIsOneRun() {
        XCTAssertEqual(found("the dot after a fatha: صِرَٰطَ اَ۬لذِينَ, over the alef"), ["صِرَٰطَ اَ۬لذِينَ"])
    }

    func testPlainArabicIsLeftAlone() {
        XCTAssertEqual(found("the rasm (رَسم), carries every reading"), [])
        XCTAssertEqual(found("Jumuah (جُمُعَة) comes from the root"), [])
    }

    func testEachMarkedRunSeparately() {
        XCTAssertEqual(found("يُؤۡمِنُونَ is read yūminūn, not رَسم, and مَجۡر۪ىٰهَا once"), ["يُؤۡمِنُونَ", "مَجۡر۪ىٰهَا"])
    }

    func testRangesAreUTF16() {
        // an emoji (two UTF-16 units) before the run must not shift it
        let text = "🙂 then ٱلۡحَمۡدُ"
        let range = QuranicInline.ranges(in: text).first
        XCTAssertEqual(range.map { (text as NSString).substring(with: $0) }, "ٱلۡحَمۡدُ")
    }
}
