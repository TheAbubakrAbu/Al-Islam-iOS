import XCTest

/// Simple Mode end to end (docs/Simple Mode Guide.md): what moved into a tab's ⋯ More menu is really
/// there and really opens, the ayah menu keeps to its five actions, and the splash can choose it.
/// Every launch seeds the switch, and `tearDown` puts it back off for whatever runs next on this
/// simulator (a seed persists in the app's defaults).
final class SimpleModeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        if ProcessInfo.processInfo.isiOSAppOnMac || UIDevice.current.userInterfaceIdiom == .pad {
            throw XCTSkip("the phone's tab stacks; iPad and Mac open these screens in columns")
        }
        MonkeyTests.skipQuiescenceWait()
    }

    override func tearDown() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipNotificationPrompt", "-seedBool", "simpleMode=0,THEfirstLaunch=0"]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 20)
        app.terminate()
        super.tearDown()
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-skipNotificationPrompt", "-travelingMode", "0"] + arguments
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        // The launch cover sits over the tabs for its first seconds: a toolbar button already exists
        // under it, and a tap there lands on the cover (the first run tapped More at 7 s and no menu
        // opened). SurahSwapTests waits the same 8 s.
        Thread.sleep(forTimeInterval: 8)
        return app
    }

    /// The Quran tab's toolbar buttons and summary doors, gathered into the one menu.
    func testQuranMoreMenuHoldsTheMovedDoors() {
        let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=1,quranPageMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Quran tab in Simple Mode")
        more.tap()
        for item in ["Today", "History", "Open a Random Surah"] {
            XCTAssertTrue(app.buttons[item].waitForExistence(timeout: 5), "the More menu has no \(item)")
        }
        XCTAssertTrue(app.buttons["Read as Pages"].exists || app.buttons["Read as List"].exists,
                      "the More menu has no reading-mode switch")
        XCTAssertTrue(app.buttons["Show as Grid"].exists || app.buttons["Show as List"].exists,
                      "the More menu has no grid switch")
    }

    /// The Hadith tab's door chips moved into its More menu, and a door there really opens its screen.
    func testHadithMoreMenuOpensTopics() {
        let app = launch(["-launchTabHadith", "-seedBool", "simpleMode=1"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Hadith tab in Simple Mode")
        more.tap()
        Thread.sleep(forTimeInterval: 2)
        print("SIMPLE-DEBUG-TREE-BEGIN\n\(app.debugDescription)\nSIMPLE-DEBUG-TREE-END")
        let topics = app.buttons["Topics"]
        XCTAssertTrue(topics.waitForExistence(timeout: 5), "the Hadith More menu has no Topics")
        topics.tap()
        XCTAssertTrue(app.navigationBars["Browse by Topic"].waitForExistence(timeout: 10),
                      "Topics from the More menu did not open the topics screen")
    }

    /// The ayah's ⋯ keeps to five actions and a way to the rest; the long list waits behind More Actions.
    func testAyahMenuIsFiveActionsInSimple() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1", "-seedBool", "simpleMode=1"])
        let menu = app.buttons["ayahActionsMenu"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 15), "no ayah menu in the list reader")
        menu.tap()
        for item in ["Play This Ayah", "See Tafsir", "Copy Ayah", "Share Ayah", "More Actions\u{2026}"] {
            XCTAssertTrue(app.buttons[item].waitForExistence(timeout: 5), "the Simple ayah menu has no \(item)")
        }
        XCTAssertFalse(app.buttons["Similar Ayahs"].exists, "the Simple ayah menu still carries the long list")
        XCTAssertFalse(app.buttons["Select Text"].exists, "the Simple ayah menu still carries the long list")
    }
}
