import XCTest
@testable import iPhone

/// `AskAIText.normalizeMarkers`: citation markers rewritten to "[n]", the ones naming no source removed.
final class AskAITextTests: XCTestCase {

    /// U1: a sourceless turn with a marker at position 0 used to trap on `1...0`.
    func testZeroSourcesMarkerAtStart() {
        let result = AskAIText.normalizeMarkers("[1] Wa alaikum assalam!", sourceCount: 0)
        XCTAssertEqual(result.text, "Wa alaikum assalam!")
        XCTAssertEqual(result.removed, 1)
    }

    /// U1: a sourceless marker mid-sentence goes, with the space before it.
    func testZeroSourcesMarkerBeforePunctuation() {
        let result = AskAIText.normalizeMarkers("Peace be upon you [1].", sourceCount: 0)
        XCTAssertEqual(result.text, "Peace be upon you.")
        XCTAssertEqual(result.removed, 1)
    }

    /// U1: the parenthetical "(source 1)" form with no sources.
    func testZeroSourcesParentheticalMarker() {
        let result = AskAIText.normalizeMarkers("As the source says (source 1), yes.", sourceCount: 0)
        XCTAssertEqual(result.text, "As the source says, yes.")
        XCTAssertEqual(result.removed, 1)
    }

    /// U1: glued and grouped markers with no sources are all removed and counted.
    func testZeroSourcesGroupedMarkers() {
        let result = AskAIText.normalizeMarkers("[2][4] and [1, 3]", sourceCount: 0)
        XCTAssertFalse(result.text.contains("["), result.text)
        XCTAssertEqual(result.text, "and")
        XCTAssertEqual(result.removed, 4)
    }

    /// U1: the four probe shapes of `-askAITextProbe` never trap and leave no bracket.
    func testZeroSourcesProbeShapes() {
        for text in ["[1] Wa alaikum assalam!", "Peace be upon you [1].", "As the source says (source 1), yes.", "[2][4] and [1, 3]"] {
            let result = AskAIText.normalizeMarkers(text, sourceCount: 0)
            XCTAssertFalse(result.text.contains("["), "\(text) -> \(result.text)")
            XCTAssertGreaterThan(result.removed, 0, text)
        }
    }

    /// U1: a valid marker stays, an out-of-range one goes, and a glued marker gets its space.
    func testMixedValidAndInvalidMarkers() {
        let result = AskAIText.normalizeMarkers("Patience is light[1][3].", sourceCount: 2)
        XCTAssertEqual(result.text, "Patience is light [1].")
        XCTAssertEqual(result.removed, 1)
    }

    /// U1: one bracket group with several numbers becomes one bracket per number, deduplicated.
    func testGroupSplitAndDeduplicated() {
        XCTAssertEqual(AskAIText.normalizeMarkers("Pray [1, 2].", sourceCount: 2).text, "Pray [1][2].")
        XCTAssertEqual(AskAIText.normalizeMarkers("Pray [1, 1].", sourceCount: 2).text, "Pray [1].")
        XCTAssertEqual(AskAIText.normalizeMarkers("Pray [Source 3].", sourceCount: 3).text, "Pray [3].")
    }

    /// U1: "[0]" names no source even when sources exist.
    func testMarkerZeroIsRemoved() {
        let result = AskAIText.normalizeMarkers("Fast on Monday [0].", sourceCount: 3)
        XCTAssertEqual(result.text, "Fast on Monday.")
        XCTAssertEqual(result.removed, 1)
    }

    /// U1: empty text is returned untouched.
    func testEmptyText() {
        let result = AskAIText.normalizeMarkers("", sourceCount: 0)
        XCTAssertEqual(result.text, "")
        XCTAssertEqual(result.removed, 0)
    }

    /// U1: every surviving "[n]" names a real source, for every source count and marker position.
    func testSurvivingMarkersAlwaysNameASource() {
        let shapes = [
            "[1] Opening.", "[3] Opening.", "Middle [2] here.", "End [4]", "Glued[1][5].",
            "(source 2) first.", "Two (sources 1 and 3).", "[1, 2, 3, 4] all.", "[Source 12] far.",
            "[1]", "[9]", " [1] ", "Line one [2]\n[3] line two.",
        ]
        let markerRegex = try! NSRegularExpression(pattern: #"\[(\d+)\]"#)
        for count in 0...4 {
            for shape in shapes {
                let result = AskAIText.normalizeMarkers(shape, sourceCount: count)
                let ns = result.text as NSString
                for match in markerRegex.matches(in: result.text, range: NSRange(location: 0, length: ns.length)) {
                    let n = Int(ns.substring(with: match.range(at: 1))) ?? -1
                    XCTAssertTrue(n >= 1 && n <= count, "sourceCount \(count): \(shape) -> \(result.text)")
                }
            }
        }
    }
}
