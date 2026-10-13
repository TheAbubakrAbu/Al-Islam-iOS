import XCTest

/// Simple Mode end to end (docs/Simple Mode Guide.md): what moved into a tab's ⋯ More menu is really
/// there and really opens, the ayah menu keeps to its five actions, and the splash can choose it.
/// Since 2026-10-11 the More menu leads every tab in BOTH modes (Abu: "always have the top left button
/// just be a more button"), so the Full Mode tests here check the same menus with the switch off.
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
        app.launchArguments = ["-skipNotificationPrompt", "-seedBool", "simpleMode=0,THEfirstLaunch=0,hadithGridMode=1,quranSearchHelpRemoved=0,quranSearchHelpCollapsed=0,travelAutomatic=1"]
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

    /// Opens the tab's ⋯ More menu and waits for one of `items` to show. Up to three tries: a system
    /// notification banner (the app's own prayer alerts, which this simulator's clock and city make
    /// frequent) can drop over the toolbar at the moment of the tap and eat it. XCUITest checks for
    /// interrupting elements BEFORE it taps, so a banner arriving in the next fraction of a second goes
    /// unseen (2026-10-11: the Adhan test caught one in the act, "Found 1 interrupting element:
    /// NotificationShortLookView"; the Settings test failed the same way twice with nothing logged).
    /// A retry first swipes any banner away.
    @discardableResult
    private func openMoreMenu(_ app: XCUIApplication, expecting items: [String], timeout: TimeInterval = 4) -> Bool {
        let more = app.buttons["tabMoreMenu"]
        for attempt in 0..<3 {
            if attempt > 0 {
                dismissNotificationBanners()
                Thread.sleep(forTimeInterval: 1)
            }
            more.tap()
            if items.contains(where: { app.buttons[$0].waitForExistence(timeout: timeout) }) { return true }
        }
        return false
    }

    /// Swipes away a notification banner standing over the app, if one is up.
    private func dismissNotificationBanners() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let banner = springboard.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'NotificationShortLookView'")).firstMatch
        if banner.exists { banner.swipeUp() }
    }

    /// The Quran tab's toolbar buttons and summary doors, gathered into the one menu.
    func testQuranMoreMenuHoldsTheMovedDoors() {
        let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=1,quranPageMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Quran tab in Simple Mode")
        XCTAssertTrue(openMoreMenu(app, expecting: ["Today"]), "the Quran More menu did not open")
        for item in ["Today", "History", "Browse by Theme", "Open a Random Surah"] {
            XCTAssertTrue(app.buttons[item].waitForExistence(timeout: 5), "the More menu has no \(item)")
        }
        XCTAssertTrue(app.buttons["Read as Pages"].exists || app.buttons["Read as List"].exists,
                      "the More menu has no reading-mode switch")
        XCTAssertTrue(app.buttons["Show as Grid"].exists || app.buttons["Show as List"].exists,
                      "the More menu has no grid switch")
    }

    /// Full Mode has the same menu: the reading mode, the planner and the grid, which were three toolbar
    /// buttons until 2026-10-11, and the doors that are also chips on the screen.
    func testQuranMoreMenuLeadsInFullMode() {
        let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=0,quranPageMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Quran tab in Full Mode")
        XCTAssertFalse(app.buttons["Read surahs as pages"].exists, "Full Mode still shows the reading-mode button")
        XCTAssertTrue(openMoreMenu(app, expecting: ["Today"]), "the Quran More menu did not open in Full Mode")
        for item in ["Today", "History", "Quran Planner", "Open a Random Surah"] {
            XCTAssertTrue(app.buttons[item].waitForExistence(timeout: 5), "the Full Mode More menu has no \(item)")
        }
        XCTAssertTrue(app.buttons["Read as Pages"].exists || app.buttons["Read as List"].exists,
                      "the Full Mode More menu has no reading-mode switch")
        XCTAssertTrue(app.buttons["Show as Grid"].exists || app.buttons["Show as List"].exists,
                      "the Full Mode More menu has no grid switch")
    }

    /// The Adhan tab's More menu, in Full Mode: the two calendars, and the prayer list's layout, which
    /// left the PRAYER TIMES header for it (Abu, 2026-10-11: "for prayer have it contain a menu to switch
    /// between tiles and grid and whatnot and remove it from where it was originally").
    func testAdhanMoreMenuHoldsTheCalendarsAndTheLayout() {
        // `travelAutomatic` off, and the two persisted "ask me" flags cleared: this simulator's
        // location is far from its saved home, and the "Traveling Mode On" card the automatic check
        // raises closed the open menu under the test (2026-10-11, caught on the recording between Grid
        // and List); a run that set the flag left the card for the next run even with the check off.
        let app = launch(["-seedBool", "simpleMode=0,travelAutomatic=0,travelTurnOnAutomatic=0,travelTurnOffAutomatic=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Adhan tab")
        XCTAssertFalse(app.buttons["Prayer Times Calendar"].exists, "the calendar is still its own toolbar button")
        XCTAssertFalse(app.buttons["TILES"].exists || app.buttons["GRID"].exists,
                       "the PRAYER TIMES header still carries the layout picker")
        XCTAssertTrue(openMoreMenu(app, expecting: ["Prayer Calendar"]), "the Adhan More menu did not open")
        for item in ["Prayer Calendar", "Hijri Calendar"] {
            XCTAssertTrue(app.buttons[item].waitForExistence(timeout: 5), "the Adhan More menu has no \(item)")
        }
        // The layout is a submenu (Abu: "have it be a menu that opens the other"): its row names the
        // layout in use, and the four choices wait inside it.
        let layoutRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Prayer Times Layout'")).firstMatch
        XCTAssertTrue(layoutRow.waitForExistence(timeout: 5), "the Adhan More menu has no Prayer Times Layout submenu")
        XCTAssertFalse(app.buttons["Tiles"].exists, "the layouts are listed in the menu itself, not behind the submenu")
        layoutRow.tap()
        for item in ["Tiles", "Grid", "List", "Split"] {
            XCTAssertTrue(app.buttons[item].waitForExistence(timeout: 5), "the Prayer Times Layout submenu has no \(item)")
        }
        attachScreenshot("adhan-layout-submenu")
        // Back to the menu's first level for the calendar (a submenu's own back row, or the menu again).
        app.tap()
        XCTAssertTrue(openMoreMenu(app, expecting: ["Prayer Calendar"]), "the Adhan More menu did not reopen")
        app.buttons["Prayer Calendar"].tap()
        XCTAssertTrue(app.navigationBars["Prayer Calendar"].waitForExistence(timeout: 10)
                      || app.navigationBars.matching(NSPredicate(format: "identifier CONTAINS[c] 'Calendar'")).firstMatch.waitForExistence(timeout: 5),
                      "Prayer Calendar from the More menu did not open the calendar")
    }

    /// The Islam tab leads with the menu too, holding the grid or list switch its trailing edge carried.
    func testIslamMoreMenuHoldsTheGridSwitch() {
        let app = launch(["-launchTabIslam", "-seedBool", "simpleMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Islam tab")
        XCTAssertFalse(app.buttons["Show grid"].exists || app.buttons["Show list"].exists,
                       "the Islam tab still shows its grid button")
        XCTAssertTrue(openMoreMenu(app, expecting: ["Show as Grid", "Show as List"]),
                      "the Islam More menu has no grid switch")
    }

    /// The Settings and Hadith tabs lead with the menu too, each holding its grid or list switch.
    ///
    /// Failed twice on 2026-10-11 with the tap opening nothing, then passed four times with the same
    /// code; the Adhan test then caught the cause in the act (a notification banner over the toolbar
    /// at the moment of the tap), which `openMoreMenu` now retries through.
    func testSettingsAndHadithMoreMenusHoldTheGridSwitch() {
        let app = launch(["-launchTabSettings", "-seedBool", "simpleMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Settings tab")
        XCTAssertFalse(app.buttons["Show grid"].exists || app.buttons["Show list"].exists,
                       "the Settings tab still shows its grid button")
        XCTAssertTrue(openMoreMenu(app, expecting: ["Show as Grid", "Show as List"]),
                      "the Settings More menu has no grid switch")
        // Close the menu, then the Hadith tab: its grid switch moved the same way.
        app.tap()
        app.tabBars.buttons["Hadith"].firstMatch.tap()
        XCTAssertTrue(more.waitForExistence(timeout: 10), "no More menu on the Hadith tab in Full Mode")
        XCTAssertFalse(app.buttons["Show grid"].exists || app.buttons["Show list"].exists,
                       "the Hadith tab still shows its grid button")
        XCTAssertTrue(openMoreMenu(app, expecting: ["Topics"]), "the Hadith More menu has no Topics in Full Mode")
        XCTAssertTrue(app.buttons["Show as Grid"].exists || app.buttons["Show as List"].exists,
                      "the Hadith More menu has no grid switch in Full Mode")
    }

    /// The two More menu items whose hosts are easiest to lose: the Quran Planner (a buttonless planner
    /// kept mounted behind the menu, whose settle hooks stamp a finished plan) and the reading-mode
    /// switch (a confirmation hung on the menu).
    func testQuranMoreMenuOpensThePlannerAndAsksBeforeReadingAsPages() {
        let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=1,quranPageMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Quran tab in Simple Mode")
        XCTAssertTrue(openMoreMenu(app, expecting: ["Quran Planner"]), "the More menu has no Quran Planner")
        let planner = app.buttons["Quran Planner"]
        planner.tap()
        XCTAssertTrue(app.navigationBars["Quran Planner"].waitForExistence(timeout: 10),
                      "Quran Planner from the More menu did not open the planner")
        app.swipeDown(velocity: .fast)
        Thread.sleep(forTimeInterval: 1.5)

        XCTAssertTrue(openMoreMenu(app, expecting: ["Read as Pages"]), "the More menu has no Read as Pages")
        let readAsPages = app.buttons["Read as Pages"]
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
        // By NAME: before `TabMoreMenuItem`, VoiceOver (and so this query) read this item as
        // "Large Grid", its symbol's name.
        XCTAssertTrue(openMoreMenu(app, expecting: ["Topics"]), "the Hadith More menu has no Topics")
        let topics = app.buttons["Topics"]
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

    /// Look and Feel through every door a person uses: the grid tile, then Show as List from the ⋯ menu
    /// and the list row, then back to the grid, a tile tap straight after a pop, and the Settings
    /// search result (a spotlight-style door, the third of the three that shared the stale-target
    /// bug `testSettingsGridTilesPush` describes). Each push is timed to its first control; a push that
    /// shows nothing within 6 s fails, and the recording shows what it showed instead.
    func testLookAndFeelOpensFromEveryDoor() {
        let app = launch(["-launchTabSettings", "-seedBool", "simpleMode=0,gridModeSettingsRaw=1"])
        XCTAssertTrue(app.staticTexts["SETTINGS"].waitForExistence(timeout: 15), "the Settings tab did not show its hub")
        var timings: [(String, Double)] = []

        func push(_ label: String, via element: XCUIElement, settle: Bool = true) {
            element.scrollIntoViewIfNeeded(in: app)
            XCTAssertTrue(element.exists, "\(label): no door to tap")
            element.waitUntilStill()
            element.tap()
            let started = Date()
            let firstSwitch = app.switches["Default List View"].firstMatch
            let firstHeader = app.staticTexts["HOW IT LOOKS"].firstMatch
            var shown = false
            while !shown, Date().timeIntervalSince(started) < 6 {
                shown = firstSwitch.exists || firstHeader.exists
                if !shown { Thread.sleep(forTimeInterval: 0.1) }
            }
            let elapsed = Date().timeIntervalSince(started)
            timings.append((label, elapsed))
            if !shown { attachScreenshot("look-and-feel-\(label)-blank") }
            XCTAssertTrue(shown, "\(label): Look and Feel showed no controls within 6 s")
            if settle { Thread.sleep(forTimeInterval: 0.6) }
            app.navigationBars.buttons.element(boundBy: 0).tap()
            // The list comes back scrolled to where the door was, so its SETTINGS header may be above
            // the fold: the navigation bar is the landing check.
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10), "\(label): back did not land on Settings")
        }

        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Look and Feel'")).firstMatch
        push("grid-tile", via: tile)
        push("grid-tile-again", via: tile)
        // Straight back in after the pop, no settling on the page.
        push("grid-tile-fast", via: tile, settle: false)

        // Show as List from the ⋯ menu, then the row.
        XCTAssertTrue(openMoreMenu(app, expecting: ["Show as List"]), "the Settings More menu did not open")
        app.buttons["Show as List"].tap()
        Thread.sleep(forTimeInterval: 1)
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Look and Feel'")).firstMatch
        push("list-row", via: row)
        push("list-row-again", via: row)

        // Back to the grid, then the tile right after the switch.
        app.swipeDown(); app.swipeDown()
        XCTAssertTrue(openMoreMenu(app, expecting: ["Show as Grid"]), "the Settings More menu did not reopen")
        app.buttons["Show as Grid"].tap()
        push("grid-tile-after-switch", via: tile)

        // The Settings search result.
        let search = app.searchFields.firstMatch.exists ? app.searchFields.firstMatch : app.textFields.firstMatch
        if search.waitForExistence(timeout: 5) {
            search.tap()
            search.typeText("Look and Feel")
            let result = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Look and Feel'")).firstMatch
            if result.waitForExistence(timeout: 5) {
                push("search-result", via: result)
            } else {
                XCTFail("no Look and Feel search result")
            }
        }

        print("LOOKFEEL doors:", timings.map { "\($0.0)=\(String(format: "%.2f", $0.1))" }.joined(separator: " "))
        for (label, elapsed) in timings {
            XCTAssertLessThan(elapsed, 2.5, "\(label): Look and Feel took \(elapsed) s to show its controls")
        }
    }

    /// Every Settings tile opens its page on the FIRST tap. Four taps in five opened nothing before
    /// 2026-10-11: the door's flag and its target were two states, the push built its destination
    /// before the target's write was readable, and the empty-door fallback closed it (Abu: "Look and
    /// feel opened a couple times as a blank tab then after a couple loaded properly"). The doors
    /// carry their target now (`pushDestination(item:)`).
    func testSettingsGridTilesPush() {
        let app = launch(["-launchTabSettings", "-seedBool", "simpleMode=0,gridModeSettingsRaw=1"])
        XCTAssertTrue(app.staticTexts["SETTINGS"].waitForExistence(timeout: 15), "the Settings tab did not show its hub")
        var report: [String] = []
        // Each tile's label and the title of the page it pushes (Prayer Settings' page is "Al-Adhan
        // Settings"); the grid door, the profile door and the appearance pages are all covered.
        for (label, title) in [("Prayer Settings", "Al-Adhan Settings"), ("Your Progress", "Your Progress"),
                               ("Custom Colors", "Custom Colors"), ("Look and Feel", "Look and Feel"),
                               ("Prayer Settings", "Al-Adhan Settings")] {
            let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", label)).firstMatch
            tile.scrollIntoViewIfNeeded(in: app)
            guard tile.exists else { report.append("\(label): no tile"); continue }
            tile.waitUntilStill()
            tile.tap()
            let opened = app.navigationBars[title].waitForExistence(timeout: 5)
            report.append("\(label): \(opened ? "opened" : "NOTHING")")
            if opened {
                Thread.sleep(forTimeInterval: 0.5)
                app.navigationBars.buttons.element(boundBy: 0).tap()
                _ = app.staticTexts["SETTINGS"].waitForExistence(timeout: 10)
                app.swipeDown(); app.swipeDown()
                Thread.sleep(forTimeInterval: 1.2)
            }
        }
        print("TILES:", report.joined(separator: " | "))
        XCTAssertFalse(report.contains { $0.hasSuffix("NOTHING") }, report.joined(separator: " | "))
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

private extension XCUIElement {
    /// Scrolls the app until this element is on screen (a row further down a Settings list: a List
    /// row below the fold is not even in the hierarchy until it scrolls in).
    func scrollIntoViewIfNeeded(in app: XCUIApplication, tries: Int = 8) {
        var left = tries
        var scrolled = false
        while !(exists && isHittable), left > 0 {
            app.swipeUp()
            scrolled = true
            left -= 1
        }
        if scrolled { waitUntilStill() }
    }

    /// Waits until this element's frame has stopped moving. A tap during a flick's deceleration only
    /// stops the scroll (the 2026-10-11 recordings: the Look and Feel tile took the tap a second after
    /// the swipe, while the list was still coasting, and nothing opened), and a fixed pause is not
    /// enough: a synthesized swipe coasts for two seconds or more.
    func waitUntilStill(timeout: TimeInterval = 5) {
        let deadline = Date().addingTimeInterval(timeout)
        var last = exists ? frame : .zero
        var still = 0
        while Date() < deadline, still < 3 {
            Thread.sleep(forTimeInterval: 0.25)
            let now = exists ? frame : .zero
            still = now == last ? still + 1 : 0
            last = now
        }
    }
}
