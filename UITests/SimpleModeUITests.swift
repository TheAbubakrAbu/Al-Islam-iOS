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

    /// The welcome's permissions page: Skip while something is unanswered (notifications under
    /// -skipNotificationPrompt, unless this simulator answered them in an earlier run), else Continue.
    private func leavePermissionsPage(_ app: XCUIApplication) {
        let skip = app.buttons["welcomeSkip"]
        let proceed = app.buttons["Continue"]
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if skip.exists, skip.isHittable { skip.tap(); return }
            if proceed.exists, proceed.isEnabled, proceed.isHittable { proceed.tap(); return }
            Thread.sleep(forTimeInterval: 0.3)
        }
        XCTFail("the permissions page offered neither Skip nor an enabled Continue")
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

    /// The sort row hides in Simple while the sort is the default, so the ⋯ menu carries a Sort submenu in
    /// both modes (Simple Mode v2, Task 6).
    func testQuranMoreMenuHasSort() {
        for simple in [1, 0] {
            let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=\(simple),quranPageMode=0"])
            XCTAssertTrue(app.buttons["tabMoreMenu"].waitForExistence(timeout: 15),
                          "no More menu on the Quran tab (simpleMode=\(simple))")
            XCTAssertTrue(openMoreMenu(app, expecting: ["Today"]), "the Quran More menu did not open (simpleMode=\(simple))")
            XCTAssertTrue(app.buttons["Sort"].waitForExistence(timeout: 5),
                          "the Quran More menu has no Sort (simpleMode=\(simple))")
            app.terminate()
        }
    }

    /// The Islam tab has no Today pill in Simple (the card pills hide), so its ⋯ menu leads with a Today
    /// item in both modes, and it pushes the Daily Hub (Simple Mode v2, Task 9).
    func testIslamMoreMenuHasToday() {
        for simple in [1, 0] {
            let app = launch(["-launchTabIslam", "-seedBool", "simpleMode=\(simple)"])
            XCTAssertTrue(app.buttons["tabMoreMenu"].waitForExistence(timeout: 15),
                          "no More menu on the Islam tab (simpleMode=\(simple))")
            XCTAssertTrue(openMoreMenu(app, expecting: ["Today"]), "the Islam More menu did not open (simpleMode=\(simple))")
            let today = app.buttons["Today"]
            XCTAssertTrue(today.waitForExistence(timeout: 5), "the Islam More menu has no Today (simpleMode=\(simple))")
            today.tap()
            let landed = app.navigationBars.matching(NSPredicate(format: "identifier CONTAINS[c] 'Today'")).firstMatch
            let heading = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'AYAH OF THE DAY' OR label CONTAINS[c] 'Today'")).firstMatch
            XCTAssertTrue(landed.waitForExistence(timeout: 8) || heading.waitForExistence(timeout: 8),
                          "Today did not open the Daily Hub (simpleMode=\(simple))")
            app.terminate()
        }
    }

    /// The Simple Mode page is the live catalog of what Simple hides and where each thing went (Simple
    /// Mode v2, Task 11): the switch, then one section per surface in the catalog's order, each trim's
    /// title over its door, in both modes, and no row back to itself. The root's SIMPLE MODE section
    /// carries the What Moves Where row that pushes it, on the list root and on the grid root.
    func testSimpleModePageListsTheCatalog() {
        let door = NSPredicate(format: "label BEGINSWITH 'What Moves Where'")
        for simple in [1, 0] {
            let app = launch(["-launchTabSettings", "-settingsOpen", "simpleMode", "-seedBool", "simpleMode=\(simple)"])
            XCTAssertTrue(app.staticTexts["EVERY TAB"].waitForExistence(timeout: 15),
                          "the Simple Mode page has no EVERY TAB section (simpleMode=\(simple))")
            XCTAssertTrue(app.switches["Simple Mode"].exists, "the Simple Mode page lost its switch (simpleMode=\(simple))")
            XCTAssertFalse(app.buttons.matching(door).firstMatch.exists,
                           "the Simple Mode page links to itself (simpleMode=\(simple))")
            // The Adhan section's first row, under the eight of EVERY TAB: at most three swipes down.
            let row = app.staticTexts["The Optional Times pill"]
            var swipes = 0
            while !row.exists, swipes < 3 {
                app.swipeUp()
                swipes += 1
            }
            XCTAssertTrue(row.waitForExistence(timeout: 3), "no Optional Times row after \(swipes) swipes (simpleMode=\(simple))")
            XCTAssertTrue(app.staticTexts["ADHAN"].exists, "the Optional Times row has no ADHAN header (simpleMode=\(simple))")
            XCTAssertTrue(app.staticTexts["Settings › Prayer Settings › Optional Prayers"].exists,
                          "the Optional Times row does not say where it went (simpleMode=\(simple))")
            attachScreenshot("simple-mode-page-\(simple)")

            // Down the rest of the page: every surface's header, the last trim with its door, then the
            // footer. A header is checked as the swipes pass it, since a List drops what scrolls away.
            let headers = ["QURAN TAB", "LIST READER", "PAGE READER", "PLAY MENUS", "HADITH TAB", "HADITH BOOK",
                           "HADITH READER", "ISLAM TAB", "ISLAM DESTINATIONS", "SETTINGS"]
            let footer = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Turning Simple Mode on also turns off'")).firstMatch
            var seen: Set<String> = []
            var more = 0
            repeat {
                for header in headers where !seen.contains(header) && app.staticTexts[header].exists {
                    seen.insert(header)
                }
                if footer.exists { break }
                app.swipeUp()
                more += 1
            } while more < 15
            for header in headers where !seen.contains(header) && app.staticTexts[header].exists {
                seen.insert(header)
            }
            XCTAssertEqual(seen, Set(headers), "headers missing from the page: \(Set(headers).subtracting(seen)) (simpleMode=\(simple))")
            XCTAssertTrue(footer.exists, "no footer after \(more) more swipes (simpleMode=\(simple))")
            XCTAssertTrue(app.staticTexts["NEED A HAND? on the settings pages"].exists,
                          "the last trim is missing (simpleMode=\(simple))")
            XCTAssertTrue(app.staticTexts["Dropped: the tab sections it controls are hidden too"].exists,
                          "the last trim does not say where it went (simpleMode=\(simple))")
            attachScreenshot("simple-mode-page-foot-\(simple)")
            app.terminate()
        }

        for grid in [0, 1] {
            let app = launch(["-launchTabSettings", "-seedBool", "simpleMode=1,gridModeSettingsRaw=\(grid)"])
            XCTAssertTrue(app.staticTexts["SIMPLE MODE"].waitForExistence(timeout: 15) || app.navigationBars["Settings"].exists,
                          "the Settings tab did not show its root (grid=\(grid))")
            let row = app.buttons.matching(door).firstMatch
            row.scrollIntoViewIfNeeded(in: app)
            XCTAssertTrue(row.exists, "the root's SIMPLE MODE section has no What Moves Where row (grid=\(grid))")
            // The floating search bar's inset spans the foot of the screen and takes a tap there: on
            // the grid root the row lands at 748 of 874 points, under it, and the first run's tap
            // opened nothing. A slow drag, held at its end so nothing coasts, lifts the row clear.
            if row.frame.maxY > app.frame.height * 0.75 {
                let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
                from.press(forDuration: 0.1, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.3)
                row.waitUntilStill()
            }
            attachScreenshot("simple-mode-root-row-grid\(grid)")
            row.tap()
            XCTAssertTrue(app.staticTexts["EVERY TAB"].waitForExistence(timeout: 8),
                          "What Moves Where did not open the Simple Mode page (grid=\(grid))")
            app.terminate()
        }
    }

    /// Rule 9 through the real switch: the Settings root's Simple Mode toggle writes through
    /// `$settings.simpleMode`, and that binding must run the property's `didSet`, which folds every
    /// screen's Show Advanced Settings off. A `-seedBool` writes the key directly and folds nothing, so
    /// the control launch (the seed, no tap) still shows the switch on; after one tap on Simple Mode a
    /// fresh launch shows it off, with the caption naming Simple Mode as the reason.
    func testSimpleModeSwitchFoldsAdvanced() {
        let seed = "advancedSettings_prayerCalculation=1,advancedSettings_islamLibraries=1,simpleMode=0,gridModeSettingsRaw=1"
        let advancedSwitch: (XCUIApplication) -> XCUIElement = { $0.switches["Show Advanced Settings"].firstMatch }

        // The control: seeded on, nothing tapped, the Libraries page's switch reads on.
        var app = launch(["-launchTabSettings", "-settingsOpen", "islamLibraries", "-seedBool", seed])
        XCTAssertTrue(advancedSwitch(app).waitForExistence(timeout: 15), "the Libraries page has no ADVANCED switch (control)")
        XCTAssertEqual(advancedSwitch(app).value as? String, "1", "the seed alone did not leave Show Advanced Settings on")
        attachScreenshot("advanced-fold-control")
        app.terminate()

        // The same seed, then one tap on the Settings root's Simple Mode switch.
        app = launch(["-launchTabSettings", "-seedBool", seed])
        let simple = app.switches["Simple Mode"].firstMatch
        XCTAssertTrue(simple.waitForExistence(timeout: 15), "the Settings root has no Simple Mode switch")
        simple.scrollIntoViewIfNeeded(in: app)
        // The floating search bar's inset takes a tap at the foot of the screen (see the What Moves
        // Where row above): lift the switch clear first.
        if simple.frame.maxY > app.frame.height * 0.7 {
            let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
            from.press(forDuration: 0.1, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.3)
            simple.waitUntilStill()
        }
        XCTAssertEqual(simple.value as? String, "0", "the seed did not leave Simple Mode off")
        // A SwiftUI Toggle's row is one element, label and all; the tap has to land on the switch.
        let knob = simple.switches.firstMatch
        if knob.exists {
            knob.tap()
        } else {
            simple.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5)).withOffset(CGVector(dx: -32, dy: 0)).tap()
        }
        let turnedOn = NSPredicate(format: "value == '1'")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: turnedOn, object: simple)], timeout: 5), .completed,
                       "the tap did not turn Simple Mode on")
        attachScreenshot("advanced-fold-tapped")
        // The writes reach the defaults daemon before the next launch kills this one.
        Thread.sleep(forTimeInterval: 2)
        app.terminate()

        // No seed this time: whatever the tap wrote is what the page reads.
        app = launch(["-launchTabSettings", "-settingsOpen", "islamLibraries"])
        XCTAssertTrue(advancedSwitch(app).waitForExistence(timeout: 15), "the Libraries page has no ADVANCED switch (after the tap)")
        XCTAssertEqual(advancedSwitch(app).value as? String, "0",
                       "turning Simple Mode on with its switch did not fold Show Advanced Settings (rule 9)")
        let caption = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Also here, with this on:' AND label ENDSWITH 'Simple Mode turned this off; turn it on to see every option here.'")).firstMatch
        XCTAssertTrue(caption.exists, "the ADVANCED caption does not keep its list and add the Simple Mode sentence")
        attachScreenshot("advanced-fold-after")
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

    /// A first launch walks the welcome's pages (2026-10-19: what the app is, About You, Location and
    /// Notifications, A lot to discover), each skippable on its own, and the last can choose Simple:
    /// the app then opens in Simple Mode.
    func testSplashCanChooseSimple() {
        // Page mode off: with it on, the Quran tab opens straight onto the mushaf (the reader hides
        // the root's More button this test looks for), which has nothing to do with the welcome.
        let app = launch(["-seedBool", "THEfirstLaunch=1,simpleMode=0,quranPageMode=0"])
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 15), "no splash on a first launch")
        getStarted.tap()
        XCTAssertTrue(app.staticTexts["Which describes you best?"].waitForExistence(timeout: 5),
                      "Get Started did not move to About You")
        app.buttons["welcomeSkip"].tap()
        XCTAssertTrue(app.staticTexts["Prayer times for where you are"].waitForExistence(timeout: 5),
                      "skipping About You did not move to the permissions page")
        leavePermissionsPage(app)
        XCTAssertTrue(app.staticTexts["A lot to discover"].waitForExistence(timeout: 5),
                      "leaving the permissions did not move to the discover page")
        app.buttons["splashChoiceSimple"].tap()
        app.buttons["Continue"].tap()
        let quranTab = app.tabBars.buttons["Quran"].firstMatch
        XCTAssertTrue(quranTab.waitForExistence(timeout: 10), "the splash did not end")
        quranTab.tap()
        XCTAssertTrue(app.buttons["tabMoreMenu"].waitForExistence(timeout: 10),
                      "choosing Simple on the splash did not turn Simple Mode on")
    }

    /// Every page of the welcome has a Skip of its own, and Skip moves one page on, never out of the
    /// whole walk (Abu, 2026-10-19: "have each page option have a skip button but don't have way to
    /// leave the tutorial completely"). About You's tailored page carries Skip with Back beside it.
    func testEveryWelcomePageSkipsOnlyItself() {
        let app = launch(["-seedBool", "THEfirstLaunch=1,simpleMode=0,quranPageMode=0"])
        let skip = app.buttons["welcomeSkip"]
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 15), "no splash on a first launch")
        XCTAssertTrue(skip.exists, "the first page has no Skip")
        skip.tap()
        XCTAssertTrue(app.staticTexts["Which describes you best?"].waitForExistence(timeout: 5),
                      "Skip on the first page did not move to About You")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Revert'")).firstMatch.tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["welcomeBack"].waitForExistence(timeout: 5), "About You's second step has no Back")
        XCTAssertTrue(skip.exists, "About You's second step has no Skip")
        skip.tap()
        XCTAssertTrue(app.staticTexts["Prayer times for where you are"].waitForExistence(timeout: 5),
                      "Skip on About You did not move to the permissions page")
        XCTAssertTrue(skip.waitForExistence(timeout: 5), "the permissions page has no Skip")
        skip.tap()
        XCTAssertTrue(app.staticTexts["A lot to discover"].waitForExistence(timeout: 5),
                      "Skip on the permissions page did not move to the discover page")
        XCTAssertTrue(skip.exists, "the discover page has no Skip")
        skip.tap()
        XCTAssertTrue(app.tabBars.buttons["Quran"].firstMatch.waitForExistence(timeout: 10),
                      "Skip on the last page did not end the welcome")
    }

    /// Nothing asks for location over the welcome's first pages; the permissions page asks when its own
    /// Allow Location button is tapped, and a skipped permission is not asked again by the Adhan tab
    /// the moment the welcome ends (its sheet is snoozed a day, like its Not Now).
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
        XCTAssertTrue(app.buttons["welcomeSkip"].waitForExistence(timeout: 5), "no About You page")
        app.buttons["welcomeSkip"].tap()
        let allowLocation = app.buttons["permissionsAllowLocation"]
        XCTAssertTrue(allowLocation.waitForExistence(timeout: 5), "no Allow Location button on the permissions page")
        XCTAssertFalse(springboard.alerts.firstMatch.exists, "a system prompt rose before Allow Location was tapped")
        allowLocation.tap()
        let prompt = springboard.alerts.firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 15), "Allow Location did not ask")
        let allow = prompt.buttons["Allow While Using App"]
        if allow.exists { allow.tap() } else { prompt.buttons.firstMatch.tap() }
        leavePermissionsPage(app)
        XCTAssertTrue(app.staticTexts["A lot to discover"].waitForExistence(timeout: 5), "no discover page")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.tabBars.buttons["Quran"].firstMatch.waitForExistence(timeout: 10), "the splash did not end")
        Thread.sleep(forTimeInterval: 3)
        XCTAssertFalse(springboard.alerts.firstMatch.exists, "the tab asked again right after the welcome")
        XCTAssertFalse(app.buttons["permissionsPrimary"].exists, "the permissions sheet followed the welcome")
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

    // Menu shortcuts must not also trigger the native menu or the containing row's hold action.
    func testAyahMenuDoubleTapCopiesWithoutOpeningMenu() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0",
                          "-shareAyahLastActionMode", "text"])
        let menu = app.buttons["ayahActionsMenu"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 15))
        menu.doubleTap()
        XCTAssertTrue(app.staticTexts["Copied"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Copy Ayah"].exists, "double tap also opened the menu")
        XCTAssertFalse(app.buttons["Select Text"].exists, "double tap opened the row actions")
    }

    func testAyahMenuHoldOpensShare() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        let menu = app.buttons["ayahActionsMenu"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 15))
        menu.press(forDuration: 0.7)
        let shareOpened = app.buttons["Share"].waitForExistence(timeout: 5)
        if !shareOpened {
            attachScreenshot("Ayah share hold")
            print(app.debugDescription)
        }
        XCTAssertTrue(shareOpened, "hold did not open the share editor")
        XCTAssertFalse(app.buttons["Select Text"].exists, "row hold stole the button's hold")
    }

    func testAyahPlaybackDoubleTapStartsPlayback() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:2",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0,nowPlayingExpanded=1"])
        let play = app.buttons["ayahPlaybackMenu"].firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        play.doubleTap()
        XCTAssertTrue(app.buttons["Stop playing"].waitForExistence(timeout: 10), "double tap did not start playback")
        XCTAssertFalse(app.buttons["Play This Ayah"].exists, "double tap also opened the playback menu")
        app.buttons["Stop playing"].tap()
    }

    func testAyahPlaybackTapAndHold() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        let play = app.buttons["ayahPlaybackMenu"].firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        play.tap()
        XCTAssertTrue(app.buttons["Play This Ayah"].waitForExistence(timeout: 5))
        // Dismiss the menu without selecting a playback action.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.15)).tap()
        play.press(forDuration: 0.7)
        XCTAssertTrue(app.navigationBars["Custom Range"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Select Text"].exists, "row hold stole the button's hold")
    }

    func testHadithMenuCopyAndShareShortcuts() {
        let app = launch(["-launchTabHadith", "-launchHadithOpen", "bukhari:20",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        XCTAssertTrue(app.buttons["hadithActionsMenu"].firstMatch.waitForExistence(timeout: 15))
        guard let menu = app.buttons.matching(identifier: "hadithActionsMenu")
            .allElementsBoundByIndex.first(where: { $0.isHittable }) else {
            return XCTFail("no visible hadith action control")
        }
        menu.doubleTap()
        XCTAssertTrue(app.staticTexts["Copied"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Copy Hadith"].exists, "double tap also opened the menu")
        menu.press(forDuration: 0.7)
        let shareOpened = app.buttons["Share"].waitForExistence(timeout: 5)
        if !shareOpened {
            attachScreenshot("Hadith share hold")
            print(app.debugDescription)
        }
        XCTAssertTrue(shareOpened)
    }

    func testAyahTextStillOpensActionsOnHold() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        let menu = app.buttons["ayahActionsMenu"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 15))
        // The first ayah's text, below its reference and action controls.
        let point = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: menu.frame.maxY + 40))
        point.press(forDuration: 0.7)
        // The trailing action tiles are lazy and below the fold in the medium sheet.
        let keepOpen = app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", "Keep Sheet Open")).firstMatch
        let opened = keepOpen.waitForExistence(timeout: 5)
        if !opened {
            attachScreenshot("Ayah text hold")
            print(app.debugDescription)
        }
        XCTAssertTrue(opened, "holding the text did not open the ayah actions sheet")
    }

    func testMoreMenuDoubleTapChangesLayout() {
        let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=0,THEfirstLaunch=0,quranGridMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15))
        more.doubleTap()
        XCTAssertFalse(app.buttons["Open a Random Surah"].exists, "double tap also opened More")
        more.tap()
        let changedToGrid = app.buttons["Show as List"].waitForExistence(timeout: 5)
        if !changedToGrid {
            attachScreenshot("More after layout shortcut")
            print(app.debugDescription)
        }
        XCTAssertTrue(changedToGrid, "double tap did not switch to grid")
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
