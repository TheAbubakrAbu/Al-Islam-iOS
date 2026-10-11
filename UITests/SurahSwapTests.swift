import XCTest

/// Previous and Next in the LIST reader must show each surah's own Arabic.
///
/// The reader swaps the surah in place, and for one render after a swap it drew the new surah with
/// the previous surah's ayahs. Every row on screen then filed the previous surah's Arabic under its
/// own surah:ayah in `AyahRow`'s display cache and went on showing it, under the right number and
/// translation (reported 2026-10-05: An-Nas 114:5 over Al-Falaq 113:5's text; see
/// `SurahView.listAyahs`).
///
/// Each walk reads every row of the surah it is on, moves, and reads every row of the surah it lands
/// on: no row may show the Arabic the same ayah number had in the surah it came from. Four steps, so
/// each walk reaches surahs the launch prewarm leaves cold (it warms the last-read surah and two on
/// either side): a cold display cache is where the wrong words got in. Tajweed colours are off for the
/// run because their paint is built from the ayah's own text and covered the wrong words a moment
/// later, so with them on the defect only flashed.
final class SurahSwapTests: XCTestCase {
    /// Set once a walk has launched with tajweed colours off.
    private var seededTajweedOff = false

    override func setUpWithError() throws {
        continueAfterFailure = false
        if ProcessInfo.processInfo.isiOSAppOnMac || UIDevice.current.userInterfaceIdiom == .pad {
            throw XCTSkip("the phone's stack reader; iPad and Mac open surahs in columns")
        }
        MonkeyTests.skipQuiescenceWait()
    }

    override func tearDown() {
        // The seed persists in the app's defaults: put tajweed colours back to their default for
        // whatever runs on this simulator next.
        if seededTajweedOff {
            let app = XCUIApplication()
            app.launchArguments = ["-skipNotificationPrompt", "-seedBool", "showTajweedColors=1"]
            app.launch()
            _ = app.wait(for: .runningForeground, timeout: 20)
            app.terminate()
        }
        super.tearDown()
    }

    /// 110 to 114, tapping the pair below each surah's last ayah.
    func testNextShowsEachSurahsOwnArabic() {
        walk(from: 110, toward: "Next", steps: 4)
    }

    /// 114 to 110, tapping the pair above each surah's first ayah.
    func testPreviousShowsEachSurahsOwnArabic() {
        walk(from: 114, toward: "Previous", steps: 4)
    }

    private func walk(from start: Int, toward direction: String, steps: Int) {
        let app = XCUIApplication()
        app.launchArguments = ["-skipNotificationPrompt", "-launchTabQuran", "-quranListMode",
                               "-lastRead", "\(start):1", "-seedBool", "showTajweedColors=0"]
        seededTajweedOff = true
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        Thread.sleep(forTimeInterval: 8)

        var surah = start
        var rows = readRows(app, surah: surah)
        for step in 1...steps {
            let target = direction == "Next" ? surah + 1 : surah - 1
            flick(app, toEnd: direction == "Next")
            XCTAssertTrue(tapPair(app, direction), "step \(step): no \(direction) button on screen in \(surah)")
            Thread.sleep(forTimeInterval: 2.5)
            XCTAssertEqual(app.state, .runningForeground, "step \(step): the app died going \(direction) from \(surah)")

            let landed = readRows(app, surah: target)
            let carried = landed.keys.sorted().filter { rows[$0] == landed[$0] }
            XCTAssertTrue(carried.isEmpty, "after \(direction) from \(surah), "
                + carried.map { "\(target):\($0) shows \(surah):\($0)'s Arabic (\(landed[$0] ?? ""))" }
                    .joined(separator: "; "))
            surah = target
            rows = landed
        }
    }

    /// Every row of the surah on screen, from the top: ayah number to its Arabic, read from the row's
    /// own text (the Arabic line ends in the ayah's number in Arabic-Indic digits). Fails unless the
    /// list shows `surah` and every ayah the header counts was read.
    private func readRows(_ app: XCUIApplication, surah: Int) -> [Int: String] {
        flick(app, toEnd: false)
        var rows: [Int: String] = [:]
        var headers: Set<String> = []
        var expected: Int?
        for _ in 0..<10 {
            if let snapshot = try? app.snapshot() {
                visit(snapshot) { element in
                    guard element.elementType == .staticText, element.frame.intersects(app.frame) else { return }
                    let label = element.label
                    if let count = Self.ayahCount(label) { expected = count }
                    if label.range(of: #"^\d+:\d+$"#, options: .regularExpression) != nil { headers.insert(label) }
                    if let (number, arabic) = Self.arabicLine(label) { rows[number] = arabic }
                }
            }
            if let expected, rows.count >= expected { break }
            drag(app, up: true)
        }
        XCTAssertEqual(Set(headers.map { String($0.split(separator: ":")[0]) }), Set(["\(surah)"]),
                       "expected the rows of surah \(surah), read \(headers.sorted())")
        if let expected {
            XCTAssertEqual(rows.count, expected, "read \(rows.count) of surah \(surah)'s \(expected) ayahs")
        } else {
            XCTFail("no ayah count in surah \(surah)'s header")
        }
        return rows
    }

    /// "5 AYAHS - <1 PAGE" in the pinned header.
    private static func ayahCount(_ label: String) -> Int? {
        guard let match = label.range(of: #"^\d+ AYAHS"#, options: .regularExpression) else { return nil }
        return Int(label[match].split(separator: " ")[0])
    }

    /// An ayah's Arabic line: Arabic letters, then a space and the ayah's number in Arabic-Indic digits.
    private static func arabicLine(_ label: String) -> (Int, String)? {
        guard let space = label.lastIndex(of: " ") else { return nil }
        let digits = label[label.index(after: space)...]
        guard !digits.isEmpty, digits.allSatisfy({ ("\u{0660}"..."\u{0669}").contains($0) }) else { return nil }
        let text = String(label[..<space])
        guard text.unicodeScalars.contains(where: { (0x0621...0x064A).contains($0.value) }) else { return nil }
        let number = digits.reduce(0) { $0 * 10 + Int($1.unicodeScalars.first!.value - 0x0660) }
        return (number, text)
    }

    private func visit(_ element: XCUIElementSnapshot, _ body: (XCUIElementSnapshot) -> Void) {
        body(element)
        for child in element.children { visit(child, body) }
    }

    /// Moves the list by a little under half a screen, with no flick, so no row is skipped.
    private func drag(_ app: XCUIApplication, up: Bool) {
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.7 : 0.3))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.3 : 0.7))
        from.press(forDuration: 0.05, thenDragTo: to)
        Thread.sleep(forTimeInterval: 0.4)
    }

    /// To the end of the list (or its top), and still: these surahs are a screen or two long.
    private func flick(_ app: XCUIApplication, toEnd: Bool) {
        for _ in 0..<2 {
            if toEnd { app.swipeUp(velocity: .fast) } else { app.swipeDown(velocity: .fast) }
        }
        Thread.sleep(forTimeInterval: 1.2)
    }

    /// Taps the Previous or Next button that is on screen and clear of the bars: the reader's
    /// pinned header above, the search bar and its rows below.
    private func tapPair(_ app: XCUIApplication, _ direction: String) -> Bool {
        guard let snapshot = try? app.snapshot() else { return false }
        let height = app.frame.height
        var target: CGRect?
        visit(snapshot) { element in
            guard target == nil, element.elementType == .button, element.label.hasPrefix(direction + ", "),
                  element.frame.midY > height * 0.22, element.frame.midY < height * 0.8 else { return }
            target = element.frame
        }
        guard let frame = target else { return false }
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: frame.midY)).tap()
        return true
    }
}
