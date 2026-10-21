import XCTest

/// Choose Surah, then a reading-mode switch, must keep the surah that was picked.
///
/// Two things sent the switch elsewhere (reported 2026-10-20 as "a 50/50"):
///
/// * The mark of the ayah the reader OPENED at survived the pick (a programmatic page turn keeps the
///   mark, so that a search hit keeps its own), and a mode switch lands on the marked ayah first: Read
///   as List after picking Ibrahim from al-Baqarah reopened al-Baqarah. A pick now clears the mark, and
///   the page reader drops any mark the page it lands on does not hold.
/// * 64 of the 114 surahs start partway down a mushaf page (al-Ma'idah opens on page 106 under an-Nisa;
///   al-Falaq on page 604 under al-Ikhlas), and the page reader reported the page's FIRST surah and ayah
///   as its position: the title, the header and the last read said the previous surah, and Read as List
///   opened it. The reader now reports the surah and ayah a navigation LANDED on, and only a real page
///   turn falls back to the page's first row (`SurahPageReader.pendingLanding`).
///
/// The picks are rows that are on screen when the sheet opens standing on the current surah (this
/// simulator's persisted search filters can hide every search lane, so the tests never search).
final class ChooseSurahModeSwitchTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        if ProcessInfo.processInfo.isiOSAppOnMac || UIDevice.current.userInterfaceIdiom == .pad {
            throw XCTSkip("the phone's stack reader; iPad and Mac open surahs in columns")
        }
        MonkeyTests.skipQuiescenceWait()
    }

    /// Page mode on al-Baqarah (page 2); Choose Surah picks al-Ma'idah (page 106, under an-Nisa): a far
    /// page turn. The title must name al-Ma'idah at once, and Read as List must open al-Ma'idah.
    func testPickedMidPageSurahThenReadAsListOpensThatSurah() {
        let app = launch(["-quranPageMode", "-mushafPageLanguage", "arabic", "-lastRead", "2:1", "-openSurahPicker"])
        pickSurah(app, 5)
        assertTitle(app, names: "Al-Ma'idah", after: "picking al-Ma'idah in page mode")
        switchReadingMode(app, to: "Read as List")
        assertListShows(app, surah: 5)
        assertTitle(app, names: "Al-Ma'idah", after: "Read as List")
    }

    /// Page mode on al-Ikhlas (page 604); Choose Surah picks al-Falaq on the SAME page: nothing turns,
    /// and the position still has to move onto al-Falaq.
    func testPickedSurahOnTheSamePageThenReadAsListOpensThatSurah() {
        let app = launch(["-quranPageMode", "-mushafPageLanguage", "arabic", "-lastRead", "112:1", "-openSurahPicker"])
        pickSurah(app, 113)
        assertTitle(app, names: "Al-Falaq", after: "picking al-Falaq on its own page")
        switchReadingMode(app, to: "Read as List")
        assertListShows(app, surah: 113)
    }

    /// List mode on al-Ikhlas; Choose Surah picks al-Falaq; Read as Pages must open page 604 titled
    /// al-Falaq, not al-Ikhlas.
    func testPickedMidPageSurahThenReadAsPagesTitlesThatSurah() {
        let app = launch(["-quranListMode", "-lastRead", "112:1", "-openSurahPicker"])
        pickSurah(app, 113)
        assertListShows(app, surah: 113)
        switchReadingMode(app, to: "Read as Pages")
        assertTitle(app, names: "Al-Falaq", after: "Read as Pages")
        assertPage(app, 604)
    }

    /// The round trip: pages, list, pages again, all on al-Ma'idah.
    func testPickedMidPageSurahSurvivesTheRoundTrip() {
        let app = launch(["-quranPageMode", "-mushafPageLanguage", "arabic", "-lastRead", "2:1", "-openSurahPicker"])
        pickSurah(app, 5)
        switchReadingMode(app, to: "Read as List")
        assertListShows(app, surah: 5)
        switchReadingMode(app, to: "Read as Pages")
        assertTitle(app, names: "Al-Ma'idah", after: "the second Read as Pages")
        assertPage(app, 106)
    }

    // MARK: Helpers

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-skipNotificationPrompt", "-travelingMode", "0", "-launchTabQuran",
                               "-seedBool", "simpleMode=0", "-quranSortMode", "surah",
                               "-seedString", "quranSortDirection=ascending"] + arguments
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        // The launch cover sits over the reader for its first seconds (SurahSwapTests waits the same 8 s).
        Thread.sleep(forTimeInterval: 8)
        return app
    }

    /// Taps the surah's row in the Choose Surah sheet (its spoken label opens "Surah 5, Al-Ma'idah, ...").
    /// The sheet opens standing on the current surah; the row is a few below it, and the list is lazy, so
    /// it is nudged up until the row exists and sits wholly inside the sheet's list band (between the
    /// title and the sort row), and the tap waits for the list to come to rest: a tap on a list that is
    /// still settling only stops it. The tap is a COORDINATE in the row's middle: `tap()` on the row
    /// element lands on the number badge, whose own tap gesture favorites the surah (the recording of
    /// the first run showed "Remove from favorites?" instead of a pick).
    private func pickSurah(_ app: XCUIApplication, _ id: Int) {
        let sheetTitle = app.staticTexts["Choose Surah"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 15), "the Choose Surah sheet did not open")
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Surah \(id),")).firstMatch
        let sort = app.buttons["Asc"]

        func band() -> (top: CGFloat, bottom: CGFloat) {
            let top = sheetTitle.exists ? sheetTitle.frame.maxY + 4 : app.frame.height * 0.55
            let bottom = sort.exists ? sort.frame.minY - 4 : app.frame.height * 0.84
            return (top, bottom)
        }
        func rowIsInBand() -> Bool {
            guard row.exists else { return false }
            let frame = row.frame, limits = band()
            return frame.minY >= limits.top && frame.maxY <= limits.bottom
        }
        func nudge(by fraction: CGFloat) {
            let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.76))
            let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.76 - fraction))
            from.press(forDuration: 0.1, thenDragTo: to)
            Thread.sleep(forTimeInterval: 0.8)
        }

        var nudges = 0
        while !rowIsInBand(), nudges < 24 {
            // A long pull while the row is not even mounted; a short one to seat it once it is.
            nudge(by: row.exists ? 0.07 : 0.16)
            nudges += 1
        }
        XCTAssertTrue(rowIsInBand(), "the row for surah \(id) could not be seated in the sheet")

        for attempt in 0..<2 {
            // At rest: the same frame twice in a row.
            var last = row.frame
            for _ in 0..<8 {
                Thread.sleep(forTimeInterval: 0.4)
                let now = row.frame
                if now == last { break }
                last = now
            }
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5)).tap()
            // The pick is performed when the sheet has finished dismissing; the page turn follows.
            Thread.sleep(forTimeInterval: 4)
            if !sheetTitle.exists { return }
            NSLog("ChooseSurahModeSwitchTests: the sheet stayed open after tap %d on surah %d", attempt + 1, id)
        }
        XCTFail("the Choose Surah sheet is still open after tapping surah \(id)")
    }

    /// Opens the reader's title menu and taps "Read as List" / "Read as Pages".
    private func switchReadingMode(_ app: XCUIApplication, to item: String) {
        let title = app.buttons["readerTitleMenu"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "no reader title menu on screen")
        title.tap()
        let button = app.buttons[item]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "the title menu has no \(item)")
        button.tap()
        Thread.sleep(forTimeInterval: 4)
    }

    /// The reader's title names `name`: the title menu's label carries the surah's number, names and
    /// meaning, and the name also stands as text in the bar.
    private func assertTitle(_ app: XCUIApplication, names name: String, after context: String) {
        let title = app.buttons["readerTitleMenu"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "no reader title menu after \(context)")
        NSLog("ChooseSurahModeSwitchTests: after %@ the title reads \"%@\"", context, title.label)
        let text = app.staticTexts[name]
        let inBar = text.exists && text.frame.midY < app.frame.height * 0.15
        XCTAssertTrue(title.label.contains(name) || inBar,
                      "after \(context) the title reads \"\(title.label)\", not \(name)")
    }

    /// The mushaf footer shows this page.
    private func assertPage(_ app: XCUIApplication, _ page: Int) {
        let pill = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Page \(page)")).firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 8), "the mushaf is not on page \(page)")
    }

    /// The list reader is on screen showing rows of `surah` and of no other (every row carries a
    /// "surah:ayah" label; a mushaf page carries none).
    private func assertListShows(_ app: XCUIApplication, surah: Int) {
        var seen: Set<String> = []
        let deadline = Date().addingTimeInterval(8)
        repeat {
            seen = []
            if let snapshot = try? app.snapshot() {
                visit(snapshot) { element in
                    guard element.elementType == .staticText, element.frame.intersects(app.frame),
                          element.label.range(of: #"^\d+:\d+$"#, options: .regularExpression) != nil else { return }
                    seen.insert(String(element.label.split(separator: ":")[0]))
                }
            }
            if !seen.isEmpty { break }
            Thread.sleep(forTimeInterval: 0.5)
        } while Date() < deadline
        XCTAssertEqual(seen, ["\(surah)"], "expected the list rows of surah \(surah), saw surahs \(seen.sorted())")
    }

    private func visit(_ element: XCUIElementSnapshot, _ body: (XCUIElementSnapshot) -> Void) {
        body(element)
        for child in element.children { visit(child, body) }
    }
}
