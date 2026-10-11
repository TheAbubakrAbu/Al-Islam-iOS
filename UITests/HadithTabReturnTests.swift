import XCTest

/// A hadith chapter keeps the reader's place across a trip to another tab.
///
/// A chapter opened AT a hadith (a search result, Last Read, a reference) scrolls to that hadith and
/// marks it. That landing ran from the list's `onAppear`, and `onAppear` runs again every time the
/// tab comes back, so a reader who had read on was thrown back to the hadith they arrived at, and the
/// mark went back onto it (reported 2026-10-09). The surah reader lands once (`didScrollDown`), and
/// this pins the chapter to the same rule.
final class HadithTabReturnTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        if ProcessInfo.processInfo.isiOSAppOnMac || UIDevice.current.userInterfaceIdiom == .pad {
            throw XCTSkip("the phone's stack reader; iPad and Mac read a chapter in a column")
        }
        MonkeyTests.skipQuiescenceWait()
    }

    func testChapterKeepsItsPlaceAcrossATabTrip() {
        let app = XCUIApplication()
        // Sahih al-Bukhari 20 sits in the chapter on belief (8 to 58): plenty to read on into.
        app.launchArguments = ["-skipNotificationPrompt", "-launchTabHadith", "-launchHadithOpen", "bukhari:20"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        Thread.sleep(forTimeInterval: 9)
        XCTAssertEqual(topHadith(app)?.number, "20", "the chapter did not open at the hadith it was asked for")

        for _ in 0..<4 { drag(app) }
        guard let before = settledTopHadith(app) else { return XCTFail("no hadith on screen after reading on") }
        XCTAssertNotEqual(before.number, "20", "the list did not move off the hadith it opened at")

        app.tabBars.buttons["Quran"].tap()
        Thread.sleep(forTimeInterval: 2)
        app.tabBars.buttons["Hadith"].tap()
        // The landing waited 0.3 s and then animated: this is well past both.
        Thread.sleep(forTimeInterval: 2.5)

        guard let after = settledTopHadith(app) else { return XCTFail("no hadith on screen after the tab trip") }
        XCTAssertEqual(after.number, before.number,
                       "the tab trip moved the list: hadith \(before.number) led it before, \(after.number) after")
        XCTAssertEqual(after.y, before.y, accuracy: 4, "the tab trip scrolled the list")
    }

    /// `topHadith` once the list has stopped: a drag can leave it coasting for a second, and a reading
    /// taken mid-coast is not where the list comes to rest.
    private func settledTopHadith(_ app: XCUIApplication) -> (number: String, y: CGFloat)? {
        var last = topHadith(app)
        for _ in 0..<8 {
            Thread.sleep(forTimeInterval: 0.5)
            let now = topHadith(app)
            if let now, let previous = last, now.number == previous.number, abs(now.y - previous.y) < 0.5 {
                return now
            }
            last = now
        }
        return last
    }

    /// The first hadith whose number pill sits below the pinned chapter header: its citation number
    /// (the digits just before the book's name in the pill) and the pill's top edge.
    private func topHadith(_ app: XCUIApplication) -> (number: String, y: CGFloat)? {
        guard let snapshot = try? app.snapshot() else { return nil }
        var texts: [XCUIElementSnapshot] = []
        visit(snapshot) { element in
            if element.elementType == .staticText { texts.append(element) }
        }
        let floor = app.frame.height * 0.2
        let titles = texts.filter { $0.label == "Sahih al-Bukhari" && $0.frame.minY > floor && $0.frame.maxY < app.frame.height }
        guard let title = titles.min(by: { $0.frame.minY < $1.frame.minY }) else { return nil }
        let number = texts
            .filter { abs($0.frame.midY - title.frame.midY) < 4 && $0.frame.maxX <= title.frame.minX + 1
                && !$0.label.isEmpty && $0.label.allSatisfy(\.isNumber) }
            .max(by: { $0.frame.maxX < $1.frame.maxX })
        guard let number else { return nil }
        return (number.label, title.frame.minY)
    }

    private func visit(_ element: XCUIElementSnapshot, _ body: (XCUIElementSnapshot) -> Void) {
        body(element)
        for child in element.children { visit(child, body) }
    }

    /// A slow drag up through the middle of the list (no flick), so the list moves by about the drag.
    private func drag(_ app: XCUIApplication) {
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        from.press(forDuration: 0.05, thenDragTo: to)
        Thread.sleep(forTimeInterval: 0.6)
    }
}
