import XCTest
@testable import iPhone

/// The custom range's Control Center title (2026-10-31, Abu: add the span, and hide what says
/// nothing): "Name S:A", then the span when the range is more than one ayah, the per-ayah count when
/// each ayah repeats, the section when the range repeats. And the pass of a range that runs on into
/// later surahs (a juz), which the sheet, the history and the player all build the same way.
final class CustomRangeTitleTests: XCTestCase {
    private func title(startSurah: Int = 18, startAyah: Int = 1, endSurah: Int = 18, endAyah: Int = 6,
                       repeatWithinAyah: Int = 1, perAyah: Int = 1,
                       sectionIndex: Int = 1, sectionTotal: Int = 1, loops: Bool = false) -> String {
        QuranPlayer.customRangeTitleText(surahName: "Al-Kahf", surahNumber: 18, ayahNumber: 3,
                                         startSurah: startSurah, startAyah: startAyah, endSurah: endSurah, endAyah: endAyah,
                                         repeatWithinAyah: repeatWithinAyah, perAyah: perAyah,
                                         sectionIndex: sectionIndex, sectionTotal: sectionTotal, loops: loops)
    }

    func testRangePlayedOnceShowsOnlyTheSpan() {
        XCTAssertEqual(title(), "Al-Kahf 18:3 (1\u{2013}6)")
    }

    func testSingleAyahPlayedOnceIsJustTheReference() {
        XCTAssertEqual(title(startAyah: 3, endAyah: 3), "Al-Kahf 18:3")
    }

    func testRepeatsAppendOnlyWhatRepeats() {
        XCTAssertEqual(title(repeatWithinAyah: 2, perAyah: 3), "Al-Kahf 18:3 (1\u{2013}6) (Ayah 2/3)")
        XCTAssertEqual(title(sectionIndex: 2, sectionTotal: 5), "Al-Kahf 18:3 (1\u{2013}6) (Sec 2/5)")
        XCTAssertEqual(title(repeatWithinAyah: 1, perAyah: 2, sectionIndex: 3, sectionTotal: 4),
                       "Al-Kahf 18:3 (1\u{2013}6) (Ayah 1/2) (Sec 3/4)")
        XCTAssertEqual(title(startAyah: 3, endAyah: 3, repeatWithinAyah: 4, perAyah: 5), "Al-Kahf 18:3 (Ayah 4/5)")
    }

    func testForeverShowsTheInfinitePass() {
        XCTAssertEqual(title(sectionIndex: 6, sectionTotal: QuranPlayer.infiniteRepeat, loops: true),
                       "Al-Kahf 18:3 (1\u{2013}6) (Sec 6/\u{221E})")
    }

    func testCrossSurahSpanNamesBothEnds() {
        XCTAssertEqual(title(startAyah: 75, endSurah: 19, endAyah: 98), "Al-Kahf 18:3 (18:75\u{2013}19:98)")
    }

    func testPassRunsThroughEverySurahBetween() {
        let counts = [112: 4, 113: 5, 114: 6]
        let pass = QuranPlayer.customRangePassAyahs(startSurah: 112, startAyah: 3, endSurah: 114, endAyah: 2) { counts[$0] ?? 0 }
        XCTAssertEqual(pass.map { "\($0.surahNumber):\($0.ayahNumber)" },
                       ["112:3", "112:4", "113:1", "113:2", "113:3", "113:4", "113:5", "114:1", "114:2"])
    }

    func testPassInsideOneSurahIsTheSpan() {
        let pass = QuranPlayer.customRangePassAyahs(startSurah: 18, startAyah: 4, endSurah: 18, endAyah: 6) { _ in 110 }
        XCTAssertEqual(pass.map(\.ayahNumber), [4, 5, 6])
        XCTAssertEqual(pass.map(\.surahNumber), [18, 18, 18])
    }

    func testPassWithEndBeforeStartIsEmpty() {
        XCTAssertTrue(QuranPlayer.customRangePassAyahs(startSurah: 19, startAyah: 1, endSurah: 18, endAyah: 6) { _ in 110 }.isEmpty)
        // Inside one surah the player refuses a start past its end before building anything; the
        // builder itself simply yields no ayahs.
        XCTAssertTrue(QuranPlayer.customRangePassAyahs(startSurah: 18, startAyah: 7, endSurah: 18, endAyah: 6) { _ in 110 }.isEmpty)
    }

    func testSelectionKnowsWhenItIsOneAyah() {
        let one = CustomRangeSelection(surahNumber: 18, surahName: "Al-Kahf", startAyah: 3, endSurahNumber: 18, endAyah: 3,
                                       repeatPerAyah: 2, repeatSection: 1)
        XCTAssertTrue(one.isSingleAyah)
        XCTAssertTrue(one.isOnly(surah: 18, ayah: 3))
        XCTAssertFalse(one.isOnly(surah: 18, ayah: 4))
        let span = CustomRangeSelection(surahNumber: 18, surahName: "Al-Kahf", startAyah: 3, endSurahNumber: 19, endAyah: 3,
                                        repeatPerAyah: 1, repeatSection: 1)
        XCTAssertFalse(span.isSingleAyah)
    }
}
