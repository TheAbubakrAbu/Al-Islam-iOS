import XCTest

/// Choose Surah while page mode shows the printed-mushaf facsimile (`-mushafPageLanguage pdf`) must
/// turn to the picked surah's page, as it does over the composed pages.
///
/// Reported 2026-10-25 ("I'll sometimes choose hadid for choose Surah and it will go to mujadilah in
/// page mode"): over the facsimile the title changed to al-Hadid but the page stayed where it was
/// (al-Mujadilah's), and the app's main thread went into a layout loop (see the fix in
/// `SurahPageReader.turnPage`). The pick is `-pickSurah`: the Choose Surah sheet opens, records the
/// pick and dismisses itself, and the reader performs it in the sheet's `onDismiss`, exactly as a
/// tap on the row does (seating a row for XCUITest to tap proved flaky over the facsimile, and the
/// fault lies after the dismissal either way: `-jumpSurah`, with no sheet at all, hung the same way).
/// A hung main thread fails the page assertion: the footer never shows the page, and the queries time out.
final class ChooseSurahFacsimileTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        if ProcessInfo.processInfo.isiOSAppOnMac || UIDevice.current.userInterfaceIdiom == .pad {
            throw XCTSkip("the phone's stack reader; iPad and Mac open surahs in columns")
        }
        MonkeyTests.skipQuiescenceWait()
    }

    /// Facsimile on al-Mujadilah (page 542); Choose Surah picks al-Hadid (page 537, under al-Waqi'ah's
    /// end): the page must turn back to 537 and the title must say al-Hadid.
    func testPickedSurahTurnsTheFacsimileBack() {
        let app = launch(["-mushafPageLanguage", "pdf", "-lastRead", "58:1", "-pickSurah", "57"])
        assertPage(app, 537)
        assertTitle(app, names: "Al-Hadid", after: "picking al-Hadid over the facsimile")
    }

    /// The other way: facsimile on al-Waqi'ah (page 534), al-Hadid is three pages on.
    func testPickedSurahTurnsTheFacsimileForward() {
        let app = launch(["-mushafPageLanguage", "pdf", "-lastRead", "56:1", "-pickSurah", "57"])
        assertPage(app, 537)
        assertTitle(app, names: "Al-Hadid", after: "picking al-Hadid over the facsimile, forward")
    }

    /// A far turn over the facsimile: al-Baqarah's first page to al-Hadid, 535 pages on.
    func testFarPickTurnsTheFacsimile() {
        let app = launch(["-mushafPageLanguage", "pdf", "-lastRead", "2:1", "-pickSurah", "57"])
        assertPage(app, 537)
        assertTitle(app, names: "Al-Hadid", after: "picking al-Hadid from al-Baqarah over the facsimile")
    }

    /// The composed pages, the same pick: the control.
    func testPickedSurahTurnsTheComposedPages() {
        let app = launch(["-mushafPageLanguage", "arabic", "-lastRead", "58:1", "-pickSurah", "57"])
        assertPage(app, 537)
        assertTitle(app, names: "Al-Hadid", after: "picking al-Hadid over the composed pages")
    }

    // MARK: Helpers (as in ChooseSurahModeSwitchTests)

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-skipNotificationPrompt", "-travelingMode", "0", "-launchTabQuran",
                               "-seedBool", "simpleMode=0", "-quranSortMode", "surah",
                               "-seedString", "quranSortDirection=ascending", "-quranPageMode",
                               "-displayQiraah", "", "-windowTrace"] + arguments
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        return app
    }

    private func assertTitle(_ app: XCUIApplication, names name: String, after context: String) {
        let title = app.buttons["readerTitleMenu"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "no reader title menu after \(context)")
        NSLog("ChooseSurahFacsimileTests: after %@ the title reads \"%@\"", context, title.label)
        let text = app.staticTexts[name]
        let inBar = text.exists && text.frame.midY < app.frame.height * 0.15
        XCTAssertTrue(title.label.contains(name) || inBar,
                      "after \(context) the title reads \"\(title.label)\", not \(name)")
    }

    /// The mushaf footer shows this page. A generous wait: a far turn composes or decodes its page first.
    private func assertPage(_ app: XCUIApplication, _ page: Int) {
        let pill = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Page \(page)")).firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 12), "the mushaf is not on page \(page)")
    }
}
