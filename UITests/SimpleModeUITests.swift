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
        app.launchArguments = ["-skipNotificationPrompt", "-seedBool", "simpleMode=0,THEfirstLaunch=0,hadithGridMode=1,quranSearchHelpRemoved=0,quranSearchHelpCollapsed=0"]
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
        for item in ["Today", "History", "Browse by Theme", "Open a Random Surah"] {
            XCTAssertTrue(app.buttons[item].waitForExistence(timeout: 5), "the More menu has no \(item)")
        }
        XCTAssertTrue(app.buttons["Read as Pages"].exists || app.buttons["Read as List"].exists,
                      "the More menu has no reading-mode switch")
        XCTAssertTrue(app.buttons["Show as Grid"].exists || app.buttons["Show as List"].exists,
                      "the More menu has no grid switch")
    }

    /// The two More menu items whose hosts are easiest to lose: the Quran Planner (a buttonless planner
    /// kept mounted behind the menu, whose settle hooks stamp a finished plan) and the reading-mode
    /// switch (a confirmation hung on the menu).
    func testQuranMoreMenuOpensThePlannerAndAsksBeforeReadingAsPages() {
        let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=1,quranPageMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Quran tab in Simple Mode")
        more.tap()
        let planner = app.buttons["Quran Planner"]
        XCTAssertTrue(planner.waitForExistence(timeout: 5), "the More menu has no Quran Planner")
        planner.tap()
        XCTAssertTrue(app.navigationBars["Quran Planner"].waitForExistence(timeout: 10),
                      "Quran Planner from the More menu did not open the planner")
        app.swipeDown(velocity: .fast)
        Thread.sleep(forTimeInterval: 1.5)

        more.tap()
        let readAsPages = app.buttons["Read as Pages"]
        XCTAssertTrue(readAsPages.waitForExistence(timeout: 5), "the More menu has no Read as Pages")
        readAsPages.tap()
        XCTAssertTrue(app.staticTexts["Switch to Page View?"].waitForExistence(timeout: 5),
                      "Read as Pages from the More menu did not ask first")
        // Left unanswered: anchored to a toolbar button on iOS 26 the dialog has no Cancel (a tap
        // outside dismisses it), and answering would switch this simulator to page mode.
    }

    /// The Hadith tab's door chips moved into its More menu, and a door there really opens its screen.
    func testHadithMoreMenuOpensTopics() {
        // Lists, so the menu's view item reads "Show as Grid": that symbol's name must not stand in
        // for the title either.
        let app = launch(["-launchTabHadith", "-seedBool", "simpleMode=1,hadithGridMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Hadith tab in Simple Mode")
        more.tap()
        // By NAME: before `SimpleMoreMenuItem`, VoiceOver (and so this query) read this item as
        // "Large Grid", its symbol's name.
        let topics = app.buttons["Topics"]
        XCTAssertTrue(topics.waitForExistence(timeout: 5), "the Hadith More menu has no Topics")
        XCTAssertTrue(app.buttons["Show as Grid"].exists, "the Hadith More menu's view item lost its name")
        topics.tap()
        XCTAssertTrue(app.navigationBars["Browse by Topic"].waitForExistence(timeout: 10),
                      "Topics from the More menu did not open the topics screen")
    }

    /// The Islam tab folds TOOLS, SIGNS & PROOFS and ASK AI behind one row, and the row opens them.
    func testIslamMoreResourcesListsTools() {
        let app = launch(["-launchTabIslam", "-seedBool", "simpleMode=1"])
        let zakah = NSPredicate(format: "label CONTAINS[c] 'Zakah'")
        XCTAssertFalse(app.descendants(matching: .any).matching(zakah).firstMatch.exists,
                       "Simple Mode still lists TOOLS on the Islam tab")
        let row = app.descendants(matching: .any)["moreResourcesRow"].firstMatch
        // Into the upper part of the screen: a row merely "hittable" can sit under the floating search
        // bar, which then takes the tap.
        for _ in 0..<8 where !(row.exists && row.isHittable && row.frame.midY < app.frame.height * 0.6) {
            app.swipeUp()
        }
        XCTAssertTrue(row.exists, "no More Resources row on the Islam tab in Simple Mode")
        row.tap()
        XCTAssertTrue(app.navigationBars["More Resources"].waitForExistence(timeout: 10), "More Resources did not open")
        XCTAssertTrue(app.descendants(matching: .any).matching(zakah).firstMatch.waitForExistence(timeout: 5),
                      "More Resources does not list the Zakah Calculator")
    }

    /// A first launch can choose Simple on the splash's second step, and the app opens in Simple Mode.
    func testSplashCanChooseSimple() {
        let app = launch(["-seedBool", "THEfirstLaunch=1,simpleMode=0"])
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 15), "no splash on a first launch")
        getStarted.tap()
        XCTAssertTrue(app.staticTexts["How much would you like to see?"].waitForExistence(timeout: 5),
                      "Get Started did not move to the Simple or Full step")
        app.buttons["splashChoiceSimple"].tap()
        app.buttons["Continue"].tap()
        let quranTab = app.tabBars.buttons["Quran"].firstMatch
        XCTAssertTrue(quranTab.waitForExistence(timeout: 10), "the splash did not end")
        quranTab.tap()
        XCTAssertTrue(app.buttons["tabMoreMenu"].waitForExistence(timeout: 10),
                      "choosing Simple on the splash did not turn Simple Mode on")
    }

    /// Launch no longer asks for location over the welcome; the Adhan tab asks once it is in front.
    func testLocationPromptWaitsForTheWelcome() {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .location)
        app.launchArguments = ["-skipNotificationPrompt", "-travelingMode", "0",
                               "-seedBool", "THEfirstLaunch=1,simpleMode=0"]
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 20), "no splash on a first launch")
        Thread.sleep(forTimeInterval: 2)
        XCTAssertFalse(springboard.alerts.firstMatch.exists, "a system prompt stands over the welcome")
        getStarted.tap()
        app.buttons["Continue"].tap()
        let prompt = springboard.alerts.firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 15), "the Adhan tab never asked for location")
        let allow = prompt.buttons["Allow While Using App"]
        if allow.exists { allow.tap() } else { prompt.buttons.firstMatch.tap() }
    }

    /// A folded Quick Search Help can be put away for good, after asking (Abu, 2026-10-10: "when a tips
    /// tab is collapsed have a button to trash remove it"). Full Mode: the help is not a Simple trim.
    func testQuickSearchHelpCanBeRemoved() {
        let app = launch(["-launchTabQuran",
                          "-seedBool", "simpleMode=0,quranPageMode=0,quranSearchHelpRemoved=0,quranSearchHelpCollapsed=1"])
        // The bar is a UISearchTextField wrapped for SwiftUI, which XCUITest lists as a text field.
        let field = app.textFields.matching(NSPredicate(format: "placeholderValue == 'Search'")).firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 15), "no search field on the Quran tab")
        field.tap()
        let trash = app.buttons["Remove search help"]
        XCTAssertTrue(trash.waitForExistence(timeout: 5), "a folded Quick Search Help has no trash")
        trash.tap()
        let remove = app.buttons["Remove"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5), "the trash did not ask first")
        remove.tap()
        XCTAssertTrue(app.staticTexts["Quick Search Help"].waitForNonExistence(timeout: 5),
                      "Quick Search Help is still there after Remove")
    }

    /// A book in Simple Mode opens as usual: one with a last read opens at it (the reader), and back is
    /// its chapter list, both without the counts, ranges or the top chapter pair. The screenshots ride
    /// along for the guide's verification sweep.
    func testHadithBookAndChapterInSimple() {
        let app = launch(["-launchTabHadith", "-seedBool", "simpleMode=1"])
        let bukhari = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sahih al-Bukhari'")).firstMatch
        XCTAssertTrue(bukhari.waitForExistence(timeout: 15), "no Sahih al-Bukhari on the Hadith tab")
        bukhari.tap()
        Thread.sleep(forTimeInterval: 3)
        attachScreenshot("simple-hadith-reader")
        XCTAssertEqual(app.state, .runningForeground)
        // A book with a last read opens as book, then reader: back is the book's chapter list.
        app.navigationBars.buttons.firstMatch.tap()
        Thread.sleep(forTimeInterval: 2)
        attachScreenshot("simple-hadith-book")
        XCTAssertTrue(app.staticTexts["CHAPTERS"].waitForExistence(timeout: 5), "back did not land on the chapter list")
        XCTAssertEqual(app.state, .runningForeground)
    }

    private func attachScreenshot(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
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
