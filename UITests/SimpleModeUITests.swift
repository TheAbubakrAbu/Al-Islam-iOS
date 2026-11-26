import XCTest

/// Simple Mode end to end (docs/Simple Mode Guide.md): what moved into a tab's ⋯ More menu or its
/// capsules under the summary (2026-11-24) is really there and really opens, the ayah menu keeps to its
/// five actions, and the splash can choose it.
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

    /// The welcome's permissions page: Skip, which stands whatever was answered (its one button reads
    /// Allow Location, Allow Notifications, then Continue).
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

    /// The Quran tab's doors are capsules under YOUR SUMMARY since 2026-11-24 (Abu: "put it in summary
    /// underneath the bottom as a bunch of capsule buttons ... so the top left ellipses has as little
    /// options as possible"). In Simple the ⋯ menu keeps Today, whose pill Simple hides, beside how the
    /// tab is shown; Random Surah is a capsule because the SURAHS shuffle hides too.
    func testQuranMoreMenuHoldsTheMovedDoors() {
        let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=1,quranPageMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Quran tab in Simple Mode")
        for door in ["History", "Random Surah"] {
            XCTAssertTrue(app.buttons[door].waitForExistence(timeout: 5), "no \(door) capsule on the Quran tab in Simple Mode")
        }
        XCTAssertTrue(openMoreMenu(app, expecting: ["Today"]), "the Quran More menu did not open")
        XCTAssertTrue(app.buttons["Sort"].waitForExistence(timeout: 5), "the More menu has no Sort")
        XCTAssertTrue(app.buttons["Read as Pages"].exists || app.buttons["Read as List"].exists,
                      "the More menu has no reading-mode switch")
        XCTAssertTrue(app.buttons["Show as Grid"].exists || app.buttons["Show as List"].exists,
                      "the More menu has no grid switch")
        for gone in ["Explore", "Open a Random Surah"] {
            XCTAssertFalse(app.buttons[gone].exists, "the More menu still has \(gone)")
        }
    }

    /// Full Mode: the doors are capsules under the summary (the planner among them), and the ⋯ menu is
    /// how the tab is shown: the sort, the reading mode and the grid, which were toolbar buttons until
    /// 2026-10-11. Today stays the summary header's pill, never a menu item beside it.
    func testQuranMoreMenuLeadsInFullMode() {
        let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=0,quranPageMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Quran tab in Full Mode")
        XCTAssertFalse(app.buttons["Read surahs as pages"].exists, "Full Mode still shows the reading-mode button")
        for door in ["History", "Topics", "Planner"] {
            XCTAssertTrue(app.buttons[door].waitForExistence(timeout: 5), "no \(door) capsule under YOUR SUMMARY in Full Mode")
        }
        XCTAssertTrue(openMoreMenu(app, expecting: ["Sort"]), "the Quran More menu did not open in Full Mode")
        XCTAssertTrue(app.buttons["Read as Pages"].exists || app.buttons["Read as List"].exists,
                      "the Full Mode More menu has no reading-mode switch")
        XCTAssertTrue(app.buttons["Show as Grid"].exists || app.buttons["Show as List"].exists,
                      "the Full Mode More menu has no grid switch")
        for gone in ["Explore", "Open a Random Surah"] {
            XCTAssertFalse(app.buttons[gone].exists, "the Full Mode More menu still has \(gone)")
        }
    }

    /// YOUR SUMMARY is full-width lines since 2026-11-25, where four half-width tiles stood (Abu:
    /// "Summary tiles are so ugly with inconsistencies 2 lines for headers and the actual verses are
    /// too small"). The Ayah of the Day leads with its verse under it; the places to pick up from are
    /// one bare 44 pt line each, every one the same height whatever the length of its name ("Last
    /// Listened Ayah" was the title that wrapped); and a line opens what it names.
    func testQuranSummaryIsLinesThatOpen() {
        let app = launch(["-launchTabQuran", "-lastRead", "2:255",
                          "-seedBool", "simpleMode=0,quranPageMode=0,THEfirstLaunch=0,saveLastReadAyah=1,showAyahOfTheDay=1"])
        let daily = app.buttons["summaryLine.ayahOfTheDay"]
        let lastRead = app.buttons["summaryLine.reading"]
        XCTAssertTrue(lastRead.waitForExistence(timeout: 15), "no Last Read line in YOUR SUMMARY")
        XCTAssertTrue(daily.exists, "no Ayah of the Day line in YOUR SUMMARY")
        if !daily.exists || lastRead.frame.height > 50 { attachScreenshot("Summary lines") }

        XCTAssertTrue(lastRead.label.contains("Al-Baqarah 2:255"), "the Last Read line does not name its ayah: \(lastRead.label)")
        XCTAssertLessThan(daily.frame.minY, lastRead.frame.minY, "the Ayah of the Day does not lead the summary")
        XCTAssertGreaterThan(daily.frame.height, lastRead.frame.height + 30, "the Ayah of the Day shows no verse under its line")
        XCTAssertEqual(lastRead.frame.height, 44, accuracy: 1, "a bare summary line is not 44 pt")
        XCTAssertGreaterThan(lastRead.frame.width, app.frame.width * 0.75, "a summary line is not the screen's width")
        // Every bare line is the same height: no name wraps.
        for kind in ["listenedAyah", "listenedSurah"] {
            let line = app.buttons["summaryLine.\(kind)"]
            if line.exists {
                XCTAssertEqual(line.frame.height, lastRead.frame.height, accuracy: 0.5, "the \(kind) line is not the Last Read line's height")
            }
        }

        lastRead.tap()
        let opened = app.staticTexts["2:255"].waitForExistence(timeout: 10)
        if !opened { attachScreenshot("Summary line tap") }
        XCTAssertTrue(opened, "the Last Read line did not open its ayah")
    }

    /// The sort row hides in Simple while the sort is the default, so the ⋯ menu carries a Sort submenu in
    /// both modes (Simple Mode v2, Task 6).
    func testQuranMoreMenuHasSort() {
        for simple in [1, 0] {
            let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=\(simple),quranPageMode=0"])
            XCTAssertTrue(app.buttons["tabMoreMenu"].waitForExistence(timeout: 15),
                          "no More menu on the Quran tab (simpleMode=\(simple))")
            XCTAssertTrue(openMoreMenu(app, expecting: ["Sort"]), "the Quran More menu did not open (simpleMode=\(simple))")
            XCTAssertTrue(app.buttons["Sort"].waitForExistence(timeout: 5),
                          "the Quran More menu has no Sort (simpleMode=\(simple))")
            app.terminate()
        }
    }

    /// The Islam tab has no Today pill in Simple (the card pills hide), so its ⋯ menu carries a Today item
    /// there, and it pushes the Daily Hub (Simple Mode v2, Task 9). In Full the Reminder of the Day's pill
    /// is the door, and the menu leaves it out (2026-11-24).
    func testIslamMoreMenuHasToday() {
        let app = launch(["-launchTabIslam", "-seedBool", "simpleMode=1"])
        XCTAssertTrue(app.buttons["tabMoreMenu"].waitForExistence(timeout: 15), "no More menu on the Islam tab in Simple Mode")
        XCTAssertTrue(openMoreMenu(app, expecting: ["Today"]), "the Islam More menu has no Today in Simple Mode")
        app.buttons["Today"].tap()
        let landed = app.navigationBars.matching(NSPredicate(format: "identifier CONTAINS[c] 'Today'")).firstMatch
        let heading = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'AYAH OF THE DAY' OR label CONTAINS[c] 'Today'")).firstMatch
        XCTAssertTrue(landed.waitForExistence(timeout: 8) || heading.waitForExistence(timeout: 8),
                      "Today did not open the Daily Hub")
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
        let seed = "advancedSettings_prayerCalculation=1,advancedSettings_naggingMode=1,simpleMode=0,gridModeSettingsRaw=1"
        let advancedSwitch: (XCUIApplication) -> XCUIElement = { $0.switches["Show Advanced Settings"].firstMatch }

        // The control: seeded on, nothing tapped, the Prayer Calculation page's switch reads on.
        var app = launch(["-launchTabSettings", "-settingsOpen", "prayerCalculation", "-seedBool", seed])
        XCTAssertTrue(advancedSwitch(app).waitForExistence(timeout: 15), "the Prayer Calculation page has no ADVANCED switch (control)")
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
        app = launch(["-launchTabSettings", "-settingsOpen", "prayerCalculation"])
        XCTAssertTrue(advancedSwitch(app).waitForExistence(timeout: 15), "the Prayer Calculation page has no ADVANCED switch (after the tap)")
        XCTAssertEqual(advancedSwitch(app).value as? String, "0",
                       "turning Simple Mode on with its switch did not fold Show Advanced Settings (rule 9)")
        let caption = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Also here, with this on:' AND label ENDSWITH 'Simple Mode turned this off; turn it on to see every option here.'")).firstMatch
        XCTAssertTrue(caption.exists, "the ADVANCED caption does not keep its list and add the Simple Mode sentence")
        attachScreenshot("advanced-fold-after")
    }

    /// The Adhan tab's More menu, in Full Mode: the two calendars, and the prayer list's layout, which
    /// left the PRAYER TIMES header for it (Abu, 2026-10-11: "for prayer have it contain a menu to switch
    /// between tiles and grid and whatnot and remove it from where it was originally"). The calendars
    /// stayed in the menu when the other tabs' doors became capsules (Abu, 2026-11-24).
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
        // layout in use, and the five choices wait inside it.
        let layoutRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Prayer Times Layout'")).firstMatch
        XCTAssertTrue(layoutRow.waitForExistence(timeout: 5), "the Adhan More menu has no Prayer Times Layout submenu")
        XCTAssertFalse(app.buttons["Tiles"].exists, "the layouts are listed in the menu itself, not behind the submenu")
        layoutRow.tap()
        for item in ["Tiles", "Centered Tiles", "Grid", "List", "Split"] {
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
        XCTAssertTrue(app.buttons["Topics"].waitForExistence(timeout: 5), "no Topics capsule on the Hadith tab in Full Mode")
        XCTAssertTrue(openMoreMenu(app, expecting: ["Show as Grid", "Show as List"]),
                      "the Hadith More menu has no grid switch in Full Mode")
    }

    /// The two doors whose hosts are easiest to lose: the Quran Planner (a buttonless planner kept
    /// mounted behind the menu, whose settle hooks stamp a finished plan, opened from its capsule under the
    /// summary) and the reading-mode switch (a confirmation hung on the menu).
    func testQuranMoreMenuOpensThePlannerAndAsksBeforeReadingAsPages() {
        let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=1,quranPageMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Quran tab in Simple Mode")
        let planner = app.buttons["Planner"]
        XCTAssertTrue(planner.waitForExistence(timeout: 5), "no Planner capsule under the summary")
        planner.tap()
        XCTAssertTrue(app.navigationBars["Quran Planner"].waitForExistence(timeout: 10),
                      "the Planner capsule did not open the planner")
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

    /// The Hadith tab's doors are capsules under its summary (2026-11-24), and a door there really opens
    /// its screen; the menu keeps its view item, by name.
    func testHadithMoreMenuOpensTopics() {
        // Lists, so the menu's view item reads "Show as Grid": that symbol's name must not stand in
        // for the title either.
        let app = launch(["-launchTabHadith", "-seedBool", "simpleMode=1,hadithGridMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15), "no More menu on the Hadith tab in Simple Mode")
        // By NAME: before `TabMoreMenuItem`, VoiceOver (and so this query) read this item as
        // "Large Grid", its symbol's name.
        XCTAssertTrue(openMoreMenu(app, expecting: ["Show as Grid"]), "the Hadith More menu's view item lost its name")
        app.tap()
        let topics = app.buttons["Topics"]
        XCTAssertTrue(topics.waitForExistence(timeout: 5), "no Topics capsule on the Hadith tab")
        topics.tap()
        XCTAssertTrue(app.navigationBars["Browse by Topic"].waitForExistence(timeout: 10),
                      "the Topics capsule did not open the topics screen")
    }

    /// The Islam tab folds TOOLS and ASK AI behind one row, and the row opens them.
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

    /// A first launch walks the welcome's pages (what the app is, About You, Location and Notifications,
    /// Simple or Full), each after the first skippable on its own, and the last can choose Simple: the
    /// app then opens in Simple Mode.
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
        XCTAssertTrue(app.staticTexts["Simple or Full?"].waitForExistence(timeout: 5),
                      "leaving the permissions did not move to the Simple or Full page")
        app.buttons["splashChoiceSimple"].tap()
        app.buttons["Continue"].tap()
        let quranTab = app.tabBars.buttons["Quran"].firstMatch
        XCTAssertTrue(quranTab.waitForExistence(timeout: 10), "the splash did not end")
        quranTab.tap()
        XCTAssertTrue(app.buttons["tabMoreMenu"].waitForExistence(timeout: 10),
                      "choosing Simple on the splash did not turn Simple Mode on")
    }

    /// Every page of the welcome that asks something has a Skip of its own, and Skip moves one page on,
    /// never out of the whole walk (Abu, 2026-10-19: "have each page option have a skip button but don't
    /// have way to leave the tutorial completely"). The first page asks nothing and has Get Started
    /// alone (2026-11-05); About You's second step carries Skip with Back beside it.
    func testEveryWelcomePageSkipsOnlyItself() {
        let app = launch(["-seedBool", "THEfirstLaunch=1,simpleMode=0,quranPageMode=0"])
        let skip = app.buttons["welcomeSkip"]
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 15), "no splash on a first launch")
        // Hittable, not merely there: a stage mounted under the welcome can carry a Skip of its own.
        XCTAssertFalse(skip.exists && skip.isHittable, "the first page has a Skip beside Get Started")
        getStarted.tap()
        XCTAssertTrue(app.staticTexts["Which describes you best?"].waitForExistence(timeout: 5),
                      "Get Started did not move to About You")
        XCTAssertTrue(skip.waitForExistence(timeout: 5), "About You has no Skip")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Revert'")).firstMatch.tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["welcomeBack"].waitForExistence(timeout: 5), "About You's second step has no Back")
        XCTAssertTrue(skip.exists, "About You's second step has no Skip")
        skip.tap()
        XCTAssertTrue(app.staticTexts["Prayer times for where you are"].waitForExistence(timeout: 5),
                      "Skip on About You did not move to the permissions page")
        XCTAssertTrue(skip.waitForExistence(timeout: 5), "the permissions page has no Skip")
        skip.tap()
        XCTAssertTrue(app.staticTexts["Simple or Full?"].waitForExistence(timeout: 5),
                      "Skip on the permissions page did not move to the Simple or Full page")
        XCTAssertTrue(skip.exists, "the Simple or Full page has no Skip")
        skip.tap()
        XCTAssertTrue(app.tabBars.buttons["Quran"].firstMatch.waitForExistence(timeout: 10),
                      "Skip on the last page did not end the welcome")
    }

    /// Nothing asks for location over the welcome's first pages; the permissions page asks when its
    /// button, reading Allow Location, is tapped, and nothing rises over the Adhan tab when the welcome
    /// ends (the tab asks from its own cards, never with a prompt or a sheet of its own).
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
        XCTAssertTrue(app.staticTexts["Simple or Full?"].waitForExistence(timeout: 5), "no Simple or Full page")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.tabBars.buttons["Quran"].firstMatch.waitForExistence(timeout: 10), "the splash did not end")
        Thread.sleep(forTimeInterval: 3)
        XCTAssertFalse(springboard.alerts.firstMatch.exists, "the tab asked again right after the welcome")
        XCTAssertFalse(app.buttons["adhanAllowLocation"].exists, "the tab offers a permission that was just given")
    }

    /// A skipped location is asked for in the app itself (Abu, 2026-11-05: "if location or notification
    /// is not given then have it be in the actual app to give it"): the Adhan tab raises no prompt of
    /// its own, shows Turn On Location where the prayer times would be, and its button asks.
    func testAdhanTabOffersASkippedLocation() {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .location)
        // Never Ask Again off: a simulator whose card was put away with its X (over times from a stored
        // place) would show none.
        app.launchArguments = ["-skipNotificationPrompt", "-travelingMode", "0",
                               "-seedBool", "THEfirstLaunch=0,simpleMode=0,locationNeverAskAgain=0"]
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowLocation = app.buttons["adhanAllowLocation"]
        XCTAssertTrue(allowLocation.waitForExistence(timeout: 20), "no Turn On Location card on the Adhan tab")
        // Past the launch cover, which takes the taps of its first seconds.
        Thread.sleep(forTimeInterval: 8)
        XCTAssertFalse(springboard.alerts.firstMatch.exists, "the tab raised a system prompt on its own")
        allowLocation.tap()
        let prompt = springboard.alerts.firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 15), "Allow Location on the tab did not ask")
        let allow = prompt.buttons["Allow While Using App"]
        if allow.exists { allow.tap() } else { prompt.buttons.firstMatch.tap() }
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: allowLocation)
        waitForExpectations(timeout: 15)
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
        // Each tile's label and the title of the page it pushes (a page is titled as its door is
        // named); the grid door, the profile door and the appearance pages are all covered.
        for (label, title) in [("Prayer Settings", "Prayer Settings"), ("Your Progress", "Your Progress"),
                               ("Custom Colors", "Custom Colors"), ("Look and Feel", "Look and Feel"),
                               ("Prayer Settings", "Prayer Settings")] {
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

    // Menu shortcuts must not also trigger the native menu or the containing row's hold action. (The
    // double-tap shortcuts, and their tests, went on 2026-11-01: a double tap made every plain tap wait.)
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

    /// The first ayah play button on screen. With `-lastRead 1:2` the FIRST match can be 1:1's
    /// control scrolled off the top, so the hittable one is wanted.
    private func hittablePlayButton(_ app: XCUIApplication) -> XCUIElement? {
        let any = app.buttons["ayahPlayButton"].firstMatch
        guard any.waitForExistence(timeout: 15) else { return nil }
        return app.buttons.matching(identifier: "ayahPlayButton").allElementsBoundByIndex
            .first(where: { $0.isHittable })
    }

    /// The ayah's play button is a MENU on a tap, plays from the ayah to the end of the surah on a
    /// double tap, and opens Play Custom Range on a hold (2026-10-23; for two days the tap played and
    /// the hold opened the menu).
    func testAyahPlayButtonTapOpensPlaybackMenu() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        guard let play = hittablePlayButton(app) else { return XCTFail("no hittable play button") }
        play.tap()
        XCTAssertTrue(app.buttons["Play This Ayah"].waitForExistence(timeout: 5), "tap did not open the playback menu")
        XCTAssertTrue(app.buttons["Play Custom Range"].exists)
        // Choose Reciter is on the menu, under the two play rows, as the Quran tab's hold menu has it.
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Choose Reciter")).firstMatch.exists,
                      "the playback menu has no Choose Reciter")
        XCTAssertFalse(app.buttons["Stop playing"].exists, "tap also started playback")
    }

    /// The actions sheet's "Keep Screen On" switch, the one row it always has whatever the riwayah.
    private func actionsSheetSwitch(_ app: XCUIApplication) -> XCUIElement {
        app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", "Keep Screen On")).firstMatch
    }

    private func launchActionsSheet(keepOpenOnPlay: Bool) -> XCUIApplication {
        launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:2", "-openRowSheet", "actions", "-sheetLarge",
                "-seedBool", "simpleMode=0,THEfirstLaunch=0,ayahSheetKeepsScreenOn=0,keepAyahSheetOpenOnPlay=\(keepOpenOnPlay ? 1 : 0)"])
    }

    /// Play This Ayah closes the actions sheet while Keep Sheet Open While Playing is off, its default.
    func testActionsSheetPlayClosesSheetByDefault() {
        let app = launchActionsSheet(keepOpenOnPlay: false)
        let play = app.buttons["Play This Ayah"]
        XCTAssertTrue(play.waitForExistence(timeout: 10), "the actions sheet has no Play This Ayah tile")
        XCTAssertTrue(actionsSheetSwitch(app).exists, "the actions sheet has no Keep Screen On switch")
        play.tap()
        let closed = actionsSheetSwitch(app).waitForNonExistence(timeout: 5)
        if !closed { attachScreenshot("Actions sheet after play, default") }
        XCTAssertTrue(closed, "Play This Ayah left the sheet open with the switch off")
        if app.buttons["Stop playing"].waitForExistence(timeout: 5) { app.buttons["Stop playing"].firstMatch.tap() }
    }

    /// With Keep Sheet Open While Playing on, Play This Ayah starts the recitation and the sheet stays.
    func testActionsSheetPlayKeepsSheetWhenSwitchOn() {
        let app = launchActionsSheet(keepOpenOnPlay: true)
        let play = app.buttons["Play This Ayah"]
        XCTAssertTrue(play.waitForExistence(timeout: 10), "the actions sheet has no Play This Ayah tile")
        play.tap()
        Thread.sleep(forTimeInterval: 2)
        attachScreenshot("Actions sheet after play, kept open")
        XCTAssertTrue(actionsSheetSwitch(app).exists, "Play This Ayah closed the sheet with the switch on")
        XCTAssertTrue(app.buttons["Play This Ayah"].exists, "the sheet's tiles went away")
        if app.buttons["Stop playing"].exists { app.buttons["Stop playing"].firstMatch.tap() }
    }

    /// Play From Ayah closes the sheet even with Keep Sheet Open While Playing on (Abu, 2026-10-26:
    /// "play from ayah shouldn't count for keeping sheet opened, only repeat and play this ayah"): the
    /// recitation moves on past this ayah, so only Play This Ayah and Repeat Ayah keep the sheet.
    func testActionsSheetPlayFromClosesSheetEvenWhenSwitchOn() {
        let app = launchActionsSheet(keepOpenOnPlay: true)
        let playFrom = app.buttons["Play From Ayah"]
        XCTAssertTrue(playFrom.waitForExistence(timeout: 10), "the actions sheet has no Play From Ayah tile")
        XCTAssertTrue(actionsSheetSwitch(app).exists, "the actions sheet has no Keep Screen On switch")
        playFrom.tap()
        let untilEndOfSurah = app.buttons["Until End of Surah"]
        XCTAssertTrue(untilEndOfSurah.waitForExistence(timeout: 5), "the Play From Ayah tile did not open its menu")
        untilEndOfSurah.tap()
        let closed = actionsSheetSwitch(app).waitForNonExistence(timeout: 5)
        if !closed { attachScreenshot("Actions sheet after Play From Ayah, switch on") }
        XCTAssertTrue(closed, "Play From Ayah left the sheet open with Keep Sheet Open While Playing on")
        if app.buttons["Stop playing"].waitForExistence(timeout: 5) { app.buttons["Stop playing"].firstMatch.tap() }
    }

    /// Keep Sheet Open While Playing and Play Custom Range (Abu, 2026-10-31: "if you're only playing the
    /// ayah on the sheet then don't dismiss it ... if many ayahs then dismiss"): the range sheet stacks
    /// on the actions sheet, and a range WIDER than the sheet's ayah closes both once it plays. The
    /// range sheet opens on two ayahs (the tapped one and the next), so Play as it opens is that case.
    func testActionsSheetCustomRangeWiderThanAyahClosesSheet() {
        let app = launchActionsSheet(keepOpenOnPlay: true)
        let tile = app.buttons["Play Custom Range"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10), "the actions sheet has no Play Custom Range tile")
        tile.tap()
        let play = app.buttons["Play Range"]
        XCTAssertTrue(play.waitForExistence(timeout: 10), "the range sheet did not open on the actions sheet")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "2 ayahs")).firstMatch.exists,
                      "the range sheet did not open on two ayahs")
        play.tap()
        let closed = actionsSheetSwitch(app).waitForNonExistence(timeout: 8)
        if !closed {
            attachScreenshot("Actions sheet after a wider range")
            print(app.debugDescription)
        }
        XCTAssertTrue(closed, "a range wider than the ayah left the actions sheet open")
        if app.buttons["Stop playing"].waitForExistence(timeout: 20) { app.buttons["Stop playing"].firstMatch.tap() }
    }

    /// The other half of the rule: a range of the sheet's ONE ayah hands the actions sheet back.
    func testActionsSheetCustomRangeOfThisAyahKeepsSheet() {
        let app = launchActionsSheet(keepOpenOnPlay: true)
        let tile = app.buttons["Play Custom Range"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10), "the actions sheet has no Play Custom Range tile")
        tile.tap()
        let play = app.buttons["Play Range"]
        XCTAssertTrue(play.waitForExistence(timeout: 10), "the range sheet did not open on the actions sheet")
        // Pull the end back onto the start: the To field's minus, the second "Previous ayah" stepper.
        let steppers = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Previous ayah"))
        XCTAssertGreaterThanOrEqual(steppers.count, 2, "the range card has no To stepper")
        steppers.element(boundBy: 1).tap()
        let oneAyah = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "1 ayah")).firstMatch
        if !oneAyah.waitForExistence(timeout: 5) {
            attachScreenshot("Range sheet after To minus")
            print(app.debugDescription)
        }
        XCTAssertTrue(oneAyah.exists, "the To stepper did not narrow the range to one ayah")
        play.tap()
        XCTAssertTrue(play.waitForNonExistence(timeout: 8), "the range sheet stayed up after Play")
        Thread.sleep(forTimeInterval: 1.5)
        let kept = actionsSheetSwitch(app).exists
        if !kept {
            attachScreenshot("Actions sheet after a one-ayah range")
            print(app.debugDescription)
        }
        XCTAssertTrue(kept, "a range of the sheet's own ayah closed the actions sheet")
        if app.buttons["Stop playing"].waitForExistence(timeout: 20) { app.buttons["Stop playing"].firstMatch.tap() }
    }

    /// The sheet's Choose Reciter row opens the reciter list ON the sheet: closing the list without a
    /// pick lands back on the actions.
    func testActionsSheetChooseReciterStacksOnSheet() {
        let app = launchActionsSheet(keepOpenOnPlay: false)
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Reciter:")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "the actions sheet has no reciter row")
        row.tap()
        let listOpened = app.navigationBars["Select Reciter"].waitForExistence(timeout: 5)
        if !listOpened {
            attachScreenshot("Actions sheet reciter row")
            print(app.debugDescription)
        }
        XCTAssertTrue(listOpened, "the reciter row did not open the reciter list")
        app.navigationBars["Select Reciter"].buttons["Close"].tap()
        XCTAssertTrue(actionsSheetSwitch(app).waitForExistence(timeout: 5), "closing the reciter list also closed the actions sheet")
    }

    /// The actions sheet's tiles fill their rows (Abu, 2026-11-18: "long hold ayah has copy ayah on
    /// its own row which is ugly"), in the Quran tab hold menu's order ("context menu for quran isnt
    /// the same as long hold ayah"): Play This Ayah, Play Word by Word and the reciter on one row,
    /// Repeat Ayah, Play Custom Range and Play From Ayah on the next, Select Text, Copy Ayah and Select
    /// Ayahs (the reader's select mode, 2026-11-18) across the whole width, and Share Ayah ONCE, the
    /// full-width button under them.
    func testActionsSheetTilesFillTheirRowsInTheMenuOrder() {
        let app = launchActionsSheet(keepOpenOnPlay: false)
        XCTAssertTrue(app.buttons["Play This Ayah"].waitForExistence(timeout: 10), "the actions sheet has no Play This Ayah tile")
        let reciter = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Reciter:")).firstMatch
        XCTAssertTrue(reciter.exists, "the actions sheet has no Choose Reciter tile")

        func frame(_ title: String) -> CGRect {
            let tile = app.buttons[title]
            XCTAssertTrue(tile.exists, "the actions sheet has no \(title) tile")
            return tile.frame
        }
        /// The tiles sit on one row, left to right in the order given.
        func assertOneRow(_ frames: [CGRect], _ what: String) {
            for (a, b) in zip(frames, frames.dropFirst()) {
                XCTAssertEqual(a.minY, b.minY, accuracy: 1.5, "\(what) are not on one row")
                XCTAssertLessThan(a.maxX, b.minX + 0.5, "\(what) are out of order")
                XCTAssertEqual(a.width, b.width, accuracy: 1.5, "\(what) are not equal widths")
            }
        }

        let playRow = [frame("Play This Ayah"), frame("Play Word by Word"), reciter.frame]
        let rangeRow = [frame("Repeat Ayah"), frame("Play Custom Range"), frame("Play From Ayah")]
        let textRow = [frame("Select Text"), frame("Copy Ayah"), frame("Select Ayahs")]
        assertOneRow(playRow, "Play This Ayah, Play Word by Word and Choose Reciter")
        assertOneRow(rangeRow, "Repeat Ayah, Play Custom Range and Play From Ayah")
        assertOneRow(textRow, "Select Text, Copy Ayah and Select Ayahs")
        XCTAssertLessThan(playRow[0].maxY, rangeRow[0].minY, "the Repeat row is not under the Play row")
        XCTAssertLessThan(rangeRow[0].maxY, textRow[0].minY, "Select Text, Copy Ayah and Select Ayahs are not under the play tiles")

        // Every row runs edge to edge: a short row stretches instead of leaving cells empty.
        let leading = playRow[0].minX, trailing = playRow[2].maxX
        for (row, what) in [(rangeRow, "the Repeat row"), (textRow, "the Select Text row")] {
            XCTAssertEqual(row.first!.minX, leading, accuracy: 1.5, "\(what) does not start at the grid's edge")
            XCTAssertEqual(row.last!.maxX, trailing, accuracy: 1.5, "\(what) does not reach the grid's edge")
        }

        let shares = app.buttons.matching(identifier: "Share Ayah")
        XCTAssertEqual(shares.count, 1, "Share Ayah is on the sheet \(shares.count) times")
        let share = shares.firstMatch.frame
        XCTAssertGreaterThan(share.minY, textRow[0].maxY, "Share Ayah is not under the Select Text row")
        XCTAssertEqual(share.minX, leading, accuracy: 1.5, "Share Ayah does not start at the grid's edge")
        XCTAssertEqual(share.maxX, trailing, accuracy: 1.5, "Share Ayah does not reach the grid's edge")
        attachScreenshot("Actions sheet tiles")
    }

    private func launchActionsSheet(keepSheetOpen: Bool) -> XCUIApplication {
        launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:2", "-openRowSheet", "actions", "-sheetLarge",
                "-seedBool", "simpleMode=0,THEfirstLaunch=0,ayahSheetKeepsScreenOn=0,keepAyahSheetOpenOnPlay=0,THEkeepAyahSheetOpen=\(keepSheetOpen ? 1 : 0)",
                "-seedString", "shareAyahLastActionMode=text"])
    }

    /// A value saved under Keep Sheet Open's old key is dropped (2026-11-23: Abu, "by default off saved value
    /// make it reset"): the old key stored ON, the setting still reads off, and Share Ayah swaps the sheet.
    func testKeepSheetOpenSavedUnderTheOldKeyIsReset() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:2", "-openRowSheet", "actions", "-sheetLarge",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0,ayahSheetKeepsScreenOn=0,keepAyahSheetOpenOnPlay=0,keepAyahSheetOpen=1",
                          "-seedString", "shareAyahLastActionMode=text"])
        let share = app.buttons["Share Ayah"]
        XCTAssertTrue(share.waitForExistence(timeout: 10), "the actions sheet has no Share Ayah row")
        share.tap()
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 10), "Share Ayah did not open the share editor")
        let swapped = !actionsSheetSwitch(app).exists
        if !swapped { attachScreenshot("Share editor over the actions sheet with the old key stored on") }
        XCTAssertTrue(swapped, "the old Keep Sheet Open value still stacked the share editor")
    }

    /// Share Ayah with Keep Sheet Open off, its default: the actions sheet closes as the share editor opens.
    func testActionsSheetShareSwapsSheetByDefault() {
        let app = launchActionsSheet(keepSheetOpen: false)
        let share = app.buttons["Share Ayah"]
        XCTAssertTrue(share.waitForExistence(timeout: 10), "the actions sheet has no Share Ayah row")
        share.tap()
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 10), "Share Ayah did not open the share editor")
        XCTAssertFalse(actionsSheetSwitch(app).exists, "the actions sheet stayed under the share editor with Keep Sheet Open off")
    }

    /// Share Ayah with Keep Sheet Open on (Abu, 2026-11-04: "why doesn't share ayah collapse the ayah
    /// sheet"): the editor stacks on the actions sheet, and a copy (or a completed share) closes both.
    func testActionsSheetShareCopyClosesStackedSheet() {
        let app = launchActionsSheet(keepSheetOpen: true)
        let share = app.buttons["Share Ayah"]
        XCTAssertTrue(share.waitForExistence(timeout: 10), "the actions sheet has no Share Ayah row")
        share.tap()
        let copy = app.buttons["Copy"]
        XCTAssertTrue(copy.waitForExistence(timeout: 10), "Share Ayah did not open the share editor")
        XCTAssertTrue(actionsSheetSwitch(app).exists, "Keep Sheet Open did not keep the actions sheet under the share editor")
        copy.tap()
        XCTAssertTrue(copy.waitForNonExistence(timeout: 8), "Copy left the share editor up")
        let closed = actionsSheetSwitch(app).waitForNonExistence(timeout: 8)
        if !closed {
            attachScreenshot("Actions sheet after a stacked copy")
            print(app.debugDescription)
        }
        XCTAssertTrue(closed, "a copy from the stacked share editor left the actions sheet open")
    }

    /// The other half: closing the stacked share editor without sharing hands the actions sheet back.
    func testActionsSheetShareClosedKeepsStackedSheet() {
        let app = launchActionsSheet(keepSheetOpen: true)
        let share = app.buttons["Share Ayah"]
        XCTAssertTrue(share.waitForExistence(timeout: 10), "the actions sheet has no Share Ayah row")
        share.tap()
        let copy = app.buttons["Copy"]
        XCTAssertTrue(copy.waitForExistence(timeout: 10), "Share Ayah did not open the share editor")
        // Both sheets carry a Close; the editor's is the one on top.
        let closes = app.buttons.matching(NSPredicate(format: "label == %@", "Close")).allElementsBoundByIndex
        guard let close = closes.last(where: { $0.isHittable }) else { return XCTFail("the share editor has no Close button") }
        close.tap()
        XCTAssertTrue(copy.waitForNonExistence(timeout: 8), "Close left the share editor up")
        Thread.sleep(forTimeInterval: 1.5)
        let kept = actionsSheetSwitch(app).exists
        if !kept {
            attachScreenshot("Actions sheet after closing the stacked share editor")
            print(app.debugDescription)
        }
        XCTAssertTrue(kept, "closing the share editor without sharing closed the actions sheet too")
    }

    func testAyahPlayButtonHoldOpensCustomRange() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        guard let play = hittablePlayButton(app) else { return XCTFail("no hittable play button") }
        play.press(forDuration: 0.7)
        let rangeOpened = app.buttons["Play Range"].waitForExistence(timeout: 5)
            || app.staticTexts["Play Range"].exists
        if !rangeOpened {
            attachScreenshot("Ayah play hold")
            print(app.debugDescription)
        }
        XCTAssertTrue(rangeOpened, "hold did not open the custom range sheet")
        XCTAssertFalse(app.buttons["Play This Ayah"].exists, "hold also opened the playback menu")
        XCTAssertFalse(app.buttons["Stop playing"].exists, "hold also started playback")
        XCTAssertFalse(app.buttons["Select Text"].exists, "row hold stole the button's hold")
    }

    /// The range card's Surah chip is a menu (2026-10-31): "To End of Surah" widens the range from the
    /// From ayah alone, so the play summary counts the rest of the surah. Three menus share one List
    /// row; this also proves each takes its own tap.
    func testCustomRangeSurahMenuOffersToEndOfSurah() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "18:1", "-showCustomRangeSheet",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0", "-seedString", "customRangeSelectionMode=ayahs"])
        let surahChip = app.buttons["Surah"].firstMatch
        XCTAssertTrue(surahChip.waitForExistence(timeout: 15), "the range card has no Surah menu")
        // The reciter sits above the range card since 2026-11-04, so the chips open under the Play bar,
        // where a tap lands on Play Range (`isHittable` says yes there all the same). The list is nudged
        // up until the chip clears the bar's top, the play summary over the button.
        let playSummary = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "plays")).firstMatch
        func playBarTop() -> CGFloat {
            playSummary.exists ? playSummary.frame.minY : app.buttons["Play Range"].frame.minY - 40
        }
        var drags = 0
        while surahChip.frame.maxY > playBarTop() - 8, drags < 6 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42)))
            drags += 1
        }
        surahChip.tap()
        let toEnd = app.buttons["To End of Surah"]
        if !toEnd.waitForExistence(timeout: 5) {
            attachScreenshot("Custom range Surah menu")
            print(app.debugDescription)
        }
        XCTAssertTrue(toEnd.exists, "the Surah menu has no To End of Surah")
        toEnd.tap()
        // The surah's own size, from the totals line under the mode picker ("110 ayahs · 12 pages
        // (293–304)"): a simulator with a stale reading position may open another surah than 18.
        let totals = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^\\d+ ayahs · \\d+ pages? \\(.*")).firstMatch
        XCTAssertTrue(totals.waitForExistence(timeout: 5), "the range card has no totals line")
        let count = totals.label.prefix(while: \.isNumber)
        let summary = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "\(count) ayahs", "plays")).firstMatch
        if !summary.waitForExistence(timeout: 5) {
            attachScreenshot("Custom range after To End of Surah")
            print(app.debugDescription)
        }
        XCTAssertTrue(summary.exists, "To End of Surah did not widen the range to the surah's last ayah (\(count))")
    }

    /// Two taps on the ayah's text, off any word, play just that ayah; the row's single tap (the mark)
    /// is not made to wait, and neither the playback menu nor the row's actions sheet opens.
    func testAyahTextDoubleTapPlaysAyah() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:2",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0,nowPlayingExpanded=1"])
        let menu = app.buttons["ayahActionsMenu"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 15))
        // The translation line of the first ayah on screen: off any Arabic word, inside the text block.
        let translation = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "praise")).firstMatch
        XCTAssertTrue(translation.waitForExistence(timeout: 5), "no translation line to double tap")
        attachScreenshot("Ayah text before double tap")
        translation.doubleTap()
        let started = app.buttons["Stop playing"].waitForExistence(timeout: 10)
        if !started {
            attachScreenshot("Ayah text after double tap")
            print(app.debugDescription)
        }
        XCTAssertTrue(started, "double tap did not start playback")
        XCTAssertFalse(app.buttons["Play This Ayah"].exists, "double tap opened the playback menu")
        XCTAssertFalse(app.buttons["Select Text"].exists, "double tap opened the row actions")
        if started { app.buttons["Stop playing"].firstMatch.tap() }
    }

    /// A word's own two taps (the word card) win over the ayah's: the card opens and nothing plays.
    func testAyahWordDoubleTapOpensCardNotPlayback() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:2",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0,wordByWordMeanings=1,nowPlayingExpanded=1"])
        XCTAssertTrue(app.buttons["ayahActionsMenu"].firstMatch.waitForExistence(timeout: 15))
        // The first ⋯ ON SCREEN: opened at 1:2, the first match is 1:1's, scrolled off the top (a tap
        // 40 pt under it landed in the title bar, 2026-10-21).
        guard let menu = app.buttons.matching(identifier: "ayahActionsMenu")
            .allElementsBoundByIndex.first(where: { $0.isHittable }) else {
            return XCTFail("no visible ayah actions control")
        }
        // The first word of the Arabic line sits at its trailing edge, under the ⋯ control.
        let point = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: menu.frame.midX, dy: menu.frame.maxY + 40))
        attachScreenshot("Word before double tap")
        point.doubleTap()
        let opened = app.staticTexts["Word Study"].waitForExistence(timeout: 5)
            || app.navigationBars["Word Study"].waitForExistence(timeout: 2)
        if !opened {
            attachScreenshot("Word after double tap")
            print(app.debugDescription)
        }
        XCTAssertTrue(opened, "the word's two taps did not open its card")
        XCTAssertFalse(app.buttons["Stop playing"].waitForExistence(timeout: 3), "the word's two taps also played the ayah")
    }

    func testHadithMenuHoldOpensShare() {
        let app = launch(["-launchTabHadith", "-launchHadithOpen", "bukhari:20",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        XCTAssertTrue(app.buttons["hadithActionsMenu"].firstMatch.waitForExistence(timeout: 15))
        guard let menu = app.buttons.matching(identifier: "hadithActionsMenu")
            .allElementsBoundByIndex.first(where: { $0.isHittable }) else {
            return XCTFail("no visible hadith action control")
        }
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

    /// Select Ayahs in the list reader (Abu, 2026-11-18: "it's just so annoying"; 2026-11-19: "make
    /// sure select is perfect"). Entering it moves nothing: the circle stands where the ▶ and ⋯ were,
    /// so the NEXT ayah's reference stays exactly where it was (the old leading circle slid every row
    /// 32 pt right, 2:30 rewrapped a line longer and the list jumped). The row's own controls step
    /// aside, the reference pill selects instead of bookmarking, a hold is a slow tap (it selects once
    /// and opens no sheet), and Done puts everything back where it was.
    func testSelectAyahsLeavesTheListStill() {
        // Select mode starts 14 s after the reader appears: after `launch`'s own 8 s wait, so the
        // "before" frame below is read in the plain reading state.
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "2:30", "-selectAyahsAt", "14",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        func eventually(_ condition: () -> Bool) -> Bool {
            for _ in 0..<20 {
                if condition() { return true }
                Thread.sleep(forTimeInterval: 0.15)
            }
            return condition()
        }

        let menu = app.buttons["ayahActionsMenu"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 15), "the reader never showed an ayah")
        let next = app.staticTexts["2:31"]
        XCTAssertTrue(next.waitForExistence(timeout: 5), "2:31's reference is not in the list")
        let before = next.frame

        let mark = app.buttons["Select 2:30"]
        XCTAssertTrue(mark.waitForExistence(timeout: 30), "select mode never started")
        Thread.sleep(forTimeInterval: 0.6)
        XCTAssertEqual(next.frame.minY, before.minY, accuracy: 0.5, "entering select mode moved the next ayah")
        XCTAssertFalse(app.buttons["ayahActionsMenu"].exists, "the ⋯ menu is still on the rows in select mode")
        XCTAssertFalse(app.buttons["ayahPlayButton"].exists, "the play menu is still on the rows in select mode")
        XCTAssertFalse(mark.isSelected, "select mode started with an ayah checked")

        // The reference pill is part of the row here: it selects, where it used to bookmark.
        app.staticTexts["2:30"].tap()
        let pillSelected = eventually { mark.isSelected }
        if !pillSelected { attachScreenshot("Select mode pill tap") }
        XCTAssertTrue(pillSelected, "the reference pill did not select the ayah")

        // A hold on the text is a slow tap: one toggle, and no actions sheet over the selection.
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: mark.frame.maxY + 60))
            .press(forDuration: 1.0)
        let holdDeselected = eventually { !mark.isSelected }
        if !holdDeselected { attachScreenshot("Select mode hold") }
        XCTAssertTrue(holdDeselected, "a hold did not toggle the ayah once")
        XCTAssertFalse(app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", "Keep Sheet Open")).firstMatch.exists,
                       "a hold opened the actions sheet in select mode")

        app.buttons["Done"].tap()
        XCTAssertTrue(menu.waitForExistence(timeout: 5), "Done did not bring the rows' controls back")
        Thread.sleep(forTimeInterval: 0.6)
        XCTAssertEqual(next.frame.minY, before.minY, accuracy: 0.5, "leaving select mode moved the next ayah")
    }

    /// Select Ayahs in the page reader (Abu, 2026-11-25: "it repositions the page and that makes it
    /// annoying cause its hard to refind the ayahs"). The bulk-action bar takes the controls row's
    /// place at the row's own size, so the page keeps the band it was fitted into: its frame, read
    /// off the spine that runs the page's full height, is the same before, in and after select mode.
    /// The bar used to come in taller than the row (the band 19 pt shorter on the 17 Pro) and the
    /// page re-fitted itself into it, every line landing somewhere else.
    func testSelectAyahsLeavesThePageStill() {
        // Select mode starts 14 s after the reader appears: after `launch`'s own 8 s wait, so the
        // "before" frame below is read in the plain reading state.
        let app = launch(["-launchTabQuran", "-quranPageMode", "-mushafPageLanguage", "arabic",
                          "-lastRead", "2:30", "-selectAyahsAt", "14",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0,saveLastReadAyah=1"])
        let search = app.buttons["Search this page"]
        XCTAssertTrue(search.waitForExistence(timeout: 15), "the page reader never showed its controls row")
        let spine = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label ENDSWITH %@", "-hand page")).firstMatch
        XCTAssertTrue(spine.waitForExistence(timeout: 5), "the page is not on screen")
        let page = spine.frame
        let row = search.frame

        let copy = app.buttons["Copy"]
        XCTAssertTrue(copy.waitForExistence(timeout: 30), "select mode never started")
        Thread.sleep(forTimeInterval: 0.6)
        if abs(spine.frame.height - page.height) > 0.5 { attachScreenshot("Select mode page band") }
        XCTAssertEqual(spine.frame.minY, page.minY, accuracy: 0.5, "entering select mode moved the page")
        XCTAssertEqual(spine.frame.height, page.height, accuracy: 0.5, "entering select mode resized the page")
        // The bar stands exactly where the row stood, at its height.
        XCTAssertEqual(copy.frame.minY, row.minY, accuracy: 1, "the bar is not in the controls row's place")
        XCTAssertEqual(copy.frame.height, row.height, accuracy: 1, "the bar is not the controls row's height")
        XCTAssertFalse(search.exists && search.isHittable, "the controls row under the bar still takes taps")

        app.buttons["Done"].tap()
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Done did not bring the controls row back")
        Thread.sleep(forTimeInterval: 0.6)
        XCTAssertTrue(search.isHittable, "the controls row came back unusable")
        XCTAssertEqual(spine.frame.minY, page.minY, accuracy: 0.5, "leaving select mode moved the page")
        XCTAssertEqual(spine.frame.height, page.height, accuracy: 0.5, "leaving select mode resized the page")
    }

    /// A hold in select mode selects the run from the ayah checked last through the held one
    /// (2026-11-19): 112:1 checked, a hold on 112:3 checks 112:2 with it, an ayah nothing touched.
    /// A hold on the ayah the run ended at is a slow tap again and unchecks that ayah alone.
    func testSelectHoldSelectsTheRunOfAyahs() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "112:1", "-selectAyahsAt", "2",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        func eventually(_ condition: () -> Bool) -> Bool {
            for _ in 0..<20 {
                if condition() { return true }
                Thread.sleep(forTimeInterval: 0.15)
            }
            return condition()
        }

        let first = app.buttons["Select 112:1"]
        let second = app.buttons["Select 112:2"]
        let third = app.buttons["Select 112:3"]
        XCTAssertTrue(first.waitForExistence(timeout: 30), "select mode never started")
        XCTAssertTrue(second.exists && third.exists, "112:2 and 112:3 are not on screen with 112:1")
        Thread.sleep(forTimeInterval: 0.6)

        app.staticTexts["112:1"].tap()
        XCTAssertTrue(eventually { first.isSelected }, "the reference pill did not select 112:1")

        // 112:3's text, below its reference and its circle.
        let thirdText = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: third.frame.maxY + 40))
        thirdText.press(forDuration: 1.0)
        let ranThrough = eventually { second.isSelected && third.isSelected }
        if !ranThrough { attachScreenshot("Select mode run") }
        XCTAssertTrue(ranThrough, "a hold on 112:3 did not select 112:2 and 112:3 with 112:1")
        XCTAssertTrue(first.isSelected, "the run unchecked the ayah it started from")

        thirdText.press(forDuration: 1.0)
        let endToggled = eventually { !third.isSelected }
        if !endToggled { attachScreenshot("Select mode run end") }
        XCTAssertTrue(endToggled, "a hold on the run's last ayah did not uncheck it")
        XCTAssertTrue(first.isSelected && second.isSelected, "that hold unchecked more than its own ayah")
        XCTAssertFalse(app.switches.matching(NSPredicate(format: "label BEGINSWITH %@", "Keep Sheet Open")).firstMatch.exists,
                       "a hold opened the actions sheet in select mode")
    }

    /// Select Hadiths, the ayah list's select mode for a chapter (2026-11-19). A circle stands where
    /// each ⋯ was, so the menus cannot open mid-selection; a tap on the narration toggles the
    /// hadith; a hold on a later hadith checks the hadiths between, ones nothing touched, and opens
    /// no long-press menu; Done brings the ⋯ menus back.
    func testSelectHadithsTakesOverTheRows() {
        let app = launch(["-launchTabHadith", "-launchHadithOpen", "bukhari:20",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        func eventually(_ condition: () -> Bool) -> Bool {
            for _ in 0..<20 {
                if condition() { return true }
                Thread.sleep(forTimeInterval: 0.15)
            }
            return condition()
        }
        // Circles clear of the pinned chapter header and of the bottom bars.
        func visibleMarks() -> [XCUIElement] {
            app.buttons.matching(identifier: "hadithSelectionMark").allElementsBoundByIndex
                .filter { $0.isHittable && $0.frame.minY > 190 && $0.frame.maxY < app.frame.maxY - 260 }
                .sorted { $0.frame.minY < $1.frame.minY }
        }

        XCTAssertTrue(app.buttons["hadithActionsMenu"].firstMatch.waitForExistence(timeout: 15))
        // The chapter title, in the middle of the navigation bar, is the menu that starts select mode.
        let bar = app.navigationBars.firstMatch
        let titleY = bar.exists ? bar.frame.midY : 84
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: app.frame.midX, dy: titleY)).tap()
        let select = app.buttons["Select Hadiths"]
        XCTAssertTrue(select.waitForExistence(timeout: 5), "the title menu has no Select Hadiths")
        select.tap()

        let anyMark = app.buttons.matching(identifier: "hadithSelectionMark").firstMatch
        XCTAssertTrue(anyMark.waitForExistence(timeout: 5), "select mode never started")
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertFalse(app.buttons["hadithActionsMenu"].exists, "the ⋯ menu is still on the rows in select mode")
        guard let started = visibleMarks().first else {
            attachScreenshot("Select Hadiths start")
            return XCTFail("no hadith's circle is on screen")
        }
        let startedLabel = started.label
        XCTAssertFalse(started.isSelected, "select mode started with a hadith checked")

        // A tap on the narration toggles the hadith.
        let startedText = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: started.frame.maxY + 60))
        startedText.tap()
        let checked = eventually { app.buttons[startedLabel].isSelected }
        if !checked { attachScreenshot("Select Hadiths tap") }
        XCTAssertTrue(checked, "a tap on the text did not check the hadith")

        // A hadith is taller than the screen, so its neighbours' circles come by one at a time:
        // scroll to the next hadith's circle and leave it alone, scroll to the one after and hold
        // its text, then come back up. The one left alone is part of the run. Circles are looked up
        // again by their label after each scroll: an element found by its place in a query names
        // whatever sits at that place once the list has loaded or dropped a row.
        func scrollToMark(skipping seen: Set<String> = [], up: Bool = true, wanted: String? = nil) -> String? {
            for _ in 0..<12 {
                let match = visibleMarks().map(\.label).first { label in
                    if let wanted { return label == wanted }
                    return !seen.contains(label)
                }
                if let match { return match }
                if up { app.swipeUp(velocity: .slow) } else { app.swipeDown(velocity: .slow) }
                Thread.sleep(forTimeInterval: 1.2)
            }
            return nil
        }
        guard let betweenLabel = scrollToMark(skipping: [startedLabel]) else {
            attachScreenshot("Select Hadiths scroll")
            return XCTFail("the next hadith's circle never came on screen")
        }
        XCTAssertFalse(app.buttons[betweenLabel].isSelected, "a hadith nothing touched is already checked")
        guard let heldLabel = scrollToMark(skipping: [startedLabel, betweenLabel]) else {
            attachScreenshot("Select Hadiths scroll")
            return XCTFail("the hadith after it never came on screen")
        }
        Thread.sleep(forTimeInterval: 0.8)
        let held = app.buttons[heldLabel]
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: held.frame.maxY + 40))
            .press(forDuration: 1.0)
        let heldChecked = eventually { held.isSelected }
        if !heldChecked { attachScreenshot("Select Hadiths hold") }
        XCTAssertTrue(heldChecked, "a hold did not check the held hadith")
        XCTAssertFalse(app.buttons["Share Hadith"].exists, "the hold opened the hadith's menu in select mode")
        guard scrollToMark(up: false, wanted: betweenLabel) != nil else {
            attachScreenshot("Select Hadiths run")
            return XCTFail("could not scroll back to the hadith between")
        }
        let ran = app.buttons[betweenLabel].isSelected
        if !ran {
            attachScreenshot("Select Hadiths run")
            print(app.debugDescription)
        }
        XCTAssertTrue(ran, "a hold did not select the hadith between the last pick and the held one")

        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["hadithActionsMenu"].firstMatch.waitForExistence(timeout: 5),
                      "Done did not bring the rows' menus back")
    }

    /// The grid switch is the ⋯ menu's HOLD since 2026-10-26 (a double tap made every plain tap wait
    /// out the double-tap interval, which read as lag; see `ShortcutMenu`).
    func testMoreMenuHoldChangesLayout() {
        let app = launch(["-launchTabQuran", "-seedBool", "simpleMode=0,THEfirstLaunch=0,quranGridMode=0"])
        let more = app.buttons["tabMoreMenu"]
        XCTAssertTrue(more.waitForExistence(timeout: 15))
        more.press(forDuration: 0.7)
        XCTAssertFalse(app.buttons["Open a Random Surah"].exists, "the hold also opened More")
        more.tap()
        let changedToGrid = app.buttons["Show as List"].waitForExistence(timeout: 5)
        if !changedToGrid {
            attachScreenshot("More after layout shortcut")
            print(app.debugDescription)
        }
        XCTAssertTrue(changedToGrid, "the hold did not switch to grid")
    }

    /// Full Mode's ⋯ menu is four groups with the deeper study and the playback behind submenus
    /// (2026-10-21): the long list it was is gone from the top level.
    func testAyahMenuIsGroupedInFullMode() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        let menu = app.buttons["ayahActionsMenu"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 15), "no ayah menu in the list reader")
        menu.tap()
        for item in ["Bookmark Ayah", "Highlight", "Add Note", "See Tafsir", "Study Ayah", "Apply Settings",
                     "Play Ayah", "Select Text", "Copy Ayah", "Select Ayahs", "Share Ayah"] {
            XCTAssertTrue(app.buttons[item].waitForExistence(timeout: 5), "the ayah menu has no \(item)")
        }
        attachScreenshot("Ayah menu grouped")
        for nested in ["Similar Ayahs", "Mutashabihat", "Play This Ayah", "Repeat Ayah", "Play Custom Range"] {
            XCTAssertFalse(app.buttons[nested].exists, "\(nested) is still on the menu's top level")
        }
        app.buttons["Study Ayah"].tap()
        XCTAssertTrue(app.buttons["Similar Ayahs"].waitForExistence(timeout: 5), "Study Ayah has no Similar Ayahs")
        attachScreenshot("Ayah menu study submenu")
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


    // MARK: Pinch to zoom and the Signs legend (2026-11-01)

    /// A pinch out on an ayah's text zooms that ayah IN PLACE (no sheet, no menu): its translation line
    /// grows taller, and nothing else fires.
    func testAyahPinchZoomsAyahInPlace() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:2",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        let menu = app.buttons["ayahActionsMenu"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 15))
        let query = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "praise"))
        let translation = query.firstMatch
        XCTAssertTrue(translation.waitForExistence(timeout: 5), "no translation line to pinch")
        translation.waitUntilStill()
        let before = translation.frame.height
        translation.pinch(withScale: 2.0, velocity: 2.0)
        Thread.sleep(forTimeInterval: 1.0)
        let after = query.firstMatch.frame.height
        if after < before * 1.3 {
            attachScreenshot("Ayah pinch")
            print(app.debugDescription)
        }
        XCTAssertGreaterThan(after, before * 1.3, "the pinch did not grow the ayah (\(before) -> \(after))")
        // Any row control still hittable: the FIRST match may have scrolled off above the grown ayah.
        XCTAssertTrue(app.buttons.matching(identifier: "ayahActionsMenu").allElementsBoundByIndex.contains { $0.isHittable },
                      "the pinch covered the reader with a sheet")
        XCTAssertFalse(app.buttons["Select Text"].exists, "the pinch opened the row actions")
        XCTAssertFalse(app.buttons["Play This Ayah"].exists, "the pinch opened the playback menu")
    }

    /// The same pinch on a hadith row grows its narration in place.
    func testHadithPinchZoomsHadithInPlace() {
        let app = launch(["-launchTabHadith", "-launchHadithOpen", "bukhari:20",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        XCTAssertTrue(app.buttons["hadithActionsMenu"].firstMatch.waitForExistence(timeout: 15))
        // A narration's English line that is on screen and clear of the bottom bars (a pinch there
        // reaches the system's home gesture instead).
        let query = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Narrated"))
        let floor = app.frame.maxY - 220
        func clearLine() -> XCUIElement? {
            query.allElementsBoundByIndex.first(where: { $0.isHittable && $0.frame.maxY < floor && $0.frame.minY > 150 })
        }
        // The chain card sits above the narration since 2026-11-15, which put hadith 20's English
        // under the bottom bars on arrival: scroll until a narration line is clear of them.
        var found = clearLine()
        for _ in 0..<4 where found == nil {
            app.swipeUp(velocity: .slow)
            // Until the list has settled: an element found by its place in the query names another
            // line once a row is loaded or dropped.
            Thread.sleep(forTimeInterval: 1.5)
            found = clearLine()
        }
        guard let line = found else {
            attachScreenshot("Hadith pinch target")
            return XCTFail("no narration line clear of the bars to pinch")
        }
        let label = line.label
        let before = line.frame.height
        line.pinch(withScale: 2.0, velocity: 2.0)
        Thread.sleep(forTimeInterval: 1.0)
        let after = app.staticTexts[label].firstMatch.frame.height
        if after < before * 1.3 {
            attachScreenshot("Hadith pinch")
            print(app.debugDescription)
        }
        XCTAssertGreaterThan(after, before * 1.3, "the pinch did not grow the hadith (\(before) -> \(after))")
        // The tab bar, which any sheet or menu would cover: a hadith grown this much can push every
        // row's ⋯ off the screen, which is what this used to look for.
        let tabReachable = app.tabBars.buttons["Hadith"].firstMatch.isHittable
        if !tabReachable { attachScreenshot("Hadith pinch cover") }
        XCTAssertTrue(tabReachable, "the pinch covered the list with a sheet")
        XCTAssertFalse(app.buttons["Share Hadith"].exists, "the pinch opened the hadith's menu")
    }

    /// The Legend's third page, Signs: the mushaf's stop signs, each row opening to what it asks.
    func testLegendSignsPageListsStopSigns() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        let legend = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Legend")).firstMatch
        XCTAssertTrue(legend.waitForExistence(timeout: 15), "no Legend button")
        legend.tap()
        let signs = app.buttons["Signs"].firstMatch
        XCTAssertTrue(signs.waitForExistence(timeout: 5), "the legend sheet has no Signs segment")
        signs.tap()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Mandatory Stop")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "no Mandatory Stop row")
        row.tap()
        let meaning = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Stop here.")).firstMatch
        let opened = meaning.waitForExistence(timeout: 5)
        if !opened {
            attachScreenshot("Legend signs")
            print(app.debugDescription)
        }
        XCTAssertTrue(opened, "the row did not open to its meaning")
        XCTAssertTrue(app.buttons["Learn About Waqf"].exists, "no door to the Waqf lesson")
    }

    /// A rule of the basic legend opens to its note AND an example ayah (2026-11-01): one ayah of the
    /// Hafs text with only that rule's letters colored, under its reference.
    func testLegendRuleRowShowsExample() {
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0"])
        let legend = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Legend")).firstMatch
        XCTAssertTrue(legend.waitForExistence(timeout: 15), "no Legend button")
        legend.tap()
        // The sheet remembers the page last looked at (the Signs test leaves it on Signs).
        let tajweed = app.buttons["Tajweed"].firstMatch
        XCTAssertTrue(tajweed.waitForExistence(timeout: 5), "the legend sheet has no Tajweed segment")
        tajweed.tap()
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Qalqalah")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "no Qalqalah row")
        row.tap()
        let example = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Example:")).firstMatch
        let shown = example.waitForExistence(timeout: 5)
        if !shown {
            attachScreenshot("Legend rule example")
            print(app.debugDescription)
        }
        XCTAssertTrue(shown, "the open rule shows no example ayah")
        XCTAssertTrue(example.label.contains("85:1"), "Qalqalah's example is not al-Buruj 85:1: \(example.label)")
    }

    /// Relaunches with the default riwayah seeded back: a seeded `displayQiraah` outlives the test on
    /// this simulator, and every other test here reads Hafs.
    private func restoreHafsAfterwards() {
        addTeardownBlock {
            let app = XCUIApplication()
            // `-settingsProbe` applies through the setters a moment after launch; "Hafs" is the default.
            app.launchArguments = ["-skipNotificationPrompt", "-travelingMode", "0", "-launchTabQuran",
                                   "-settingsProbe", "displayQiraah=Hafs@1"]
            app.launch()
            _ = app.wait(for: .runningForeground, timeout: 20)
            Thread.sleep(forTimeInterval: 4)
            app.terminate()
        }
    }

    /// The riwayah picker's Sort By (2026-11-01): Alphabetical lists every riwayah in one list, so
    /// Qalun is a row of the menu itself rather than a row of the Nafi submenu. The list reader shows
    /// its riwayah chip only in comparison mode or in a riwayah other than Hafs, so Warsh is seeded.
    func testRiwayahPickerSortsFlat() {
        restoreHafsAfterwards()
        // The riwayah is a `-settingsProbe` step (applied in-process a second after launch; the
        // launch helper's own wait covers it), not a `-seedBool` key.
        let app = launch(["-launchTabQuran", "-quranListMode", "-lastRead", "1:1",
                          "-seedBool", "simpleMode=0,THEfirstLaunch=0",
                          "-settingsProbe", "showQiraahDetails=1@1,displayQiraah=Warsh an Nafi@2"])
        let chip = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Warsh an Nafi")).firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 15), "no riwayah chip in the reader's bar")
        chip.tap()
        let sortBy = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Sort By")).firstMatch
        XCTAssertTrue(sortBy.waitForExistence(timeout: 5), "the picker has no Sort By")
        // Default: the imams' submenus, Qalun inside Nafi's.
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Qalun an Nafi")).firstMatch.exists,
                       "Qalun is a top-level row in the Default order")
        sortBy.tap()
        let alphabetical = app.buttons["Alphabetical"].firstMatch
        XCTAssertTrue(alphabetical.waitForExistence(timeout: 5), "Sort By has no Alphabetical")
        alphabetical.tap()
        // The menu closes on the pick; reopen it.
        _ = chip.waitForExistence(timeout: 5)
        chip.tap()
        let qalun = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Qalun an Nafi")).firstMatch
        let flat = qalun.waitForExistence(timeout: 5)
        if !flat {
            attachScreenshot("Riwayah picker alphabetical")
            print(app.debugDescription)
        }
        XCTAssertTrue(flat, "Alphabetical did not list Qalun on the menu itself")
        // Back to Default so the simulator's other tests see the menu they expect.
        let sortAgain = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Sort By")).firstMatch
        if sortAgain.waitForExistence(timeout: 3) {
            sortAgain.tap()
            let byDefault = app.buttons["Default"].firstMatch
            if byDefault.waitForExistence(timeout: 3) { byDefault.tap() }
        }
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
