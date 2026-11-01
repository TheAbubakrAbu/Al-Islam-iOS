import XCTest
@testable import iPhone

/// The tab tutorials (TabTutorials.swift, 2026-10-31): one per tab, six to ten cards whatever Simple Mode
/// hides, every "Show me" a setting the search already reaches, the house copy rules, and the nudge's
/// seen set, which is written only when it changes.
@MainActor
final class TabTutorialsTests: XCTestCase {
    private var savedSimpleMode: Any?
    private var savedNudges: Any?

    override func setUp() {
        super.setUp()
        savedSimpleMode = UserDefaults.standard.object(forKey: "simpleMode")
        savedNudges = UserDefaults.standard.object(forKey: "tutorialNudgesSeen")
    }

    /// Raw writes on purpose, as SimpleModeTests does: going through `Settings.simpleMode` would run
    /// rule 9's fold again on an off-to-on restore.
    override func tearDown() {
        for (key, value) in [("simpleMode", savedSimpleMode), ("tutorialNudgesSeen", savedNudges)] {
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        super.tearDown()
    }

    func testEveryTabHasATutorial() {
        XCTAssertEqual(TutorialTab.allCases.map(\.rawValue), ["adhan", "quran", "hadith", "islam"])
        for tab in TutorialTab.allCases {
            XCTAssertEqual(TutorialTab(tipsArea: tab.tipsArea), tab)
            XCTAssertEqual(TutorialTab(helpDoorArea: tab.helpDoorArea), tab)
            XCTAssertFalse(tab.title.isEmpty)
            XCTAssertFalse(tab.summary.isEmpty)
        }
        XCTAssertNil(TutorialTab(tipsArea: .notifications), "Notifications is no tab")
        XCTAssertNil(TutorialTab(tipsArea: .app))
    }

    func testStepIDsAreUniqueAndNamedForTheirTab() {
        let ids = TutorialCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        for step in TutorialCatalog.all {
            XCTAssertTrue(step.id.hasPrefix(step.tab.rawValue + "."), step.id)
        }
    }

    func testSixToTenCardsInFullAndSimpleMode() {
        for simple in [false, true] {
            UserDefaults.standard.set(simple, forKey: "simpleMode")
            for tab in TutorialTab.allCases {
                let count = TutorialCatalog.steps(for: tab).count
                XCTAssertTrue((6...10).contains(count), "\(tab) has \(count) cards with Simple Mode \(simple)")
            }
        }
    }

    func testCopyKeepsTheHouseRules() {
        for step in TutorialCatalog.all {
            let texts = [step.title.english, step.detail.english, step.place.english] + step.actions.map(\.label)
            for text in texts {
                XCTAssertFalse(text.contains("\u{2014}"), "an em dash in \(step.id): \(text)")
                XCTAssertFalse(text.contains(" - "), "a spaced hyphen in \(step.id): \(text)")
                XCTAssertFalse(text.isEmpty, step.id)
            }
            XCTAssertLessThanOrEqual(step.actions.count, 2, step.id)
            // At most three sentences of detail (rule 4).
            let sentences = step.detail.english.split(whereSeparator: { ".?!".contains($0) })
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            XCTAssertLessThanOrEqual(sentences.count, 3, "\(step.id): \(step.detail.english)")
        }
    }

    /// A card's setting is one the search or a tip already opens (the Prayer Tracker screen is a tip's
    /// destination, not a search entry's), so a renamed or retired page shows up here.
    func testEverySettingIsOneTheAppAlreadyOpens() {
        let opened = Set(SettingsSearchEntry.all.map { "\($0.destination)" }
                         + TipCatalog.all.compactMap(\.destination).map { "\($0)" })
        for step in TutorialCatalog.all {
            for action in step.actions {
                guard case .setting(let destination, _) = action else { continue }
                XCTAssertTrue(opened.contains("\(destination)"), "\(step.id) opens \(destination), which no search entry or tip opens")
            }
        }
    }

    func testTheHomeCityCardOpensThePickerFirst() {
        guard let step = TutorialCatalog.all.first(where: { $0.id == "adhan.homecity" }) else {
            return XCTFail("no home city card")
        }
        XCTAssertTrue(step.showsHomeCity)
        guard case .homeCity? = step.actions.first else { return XCTFail("Change Home City leads") }
        guard case .setting(.prayerPage(.travelingMode), _)? = step.actions.last else {
            return XCTFail("Traveling Mode Settings follows")
        }
        XCTAssertEqual(step.actions.first?.label, "Change Home City")
    }

    func testEveryTabEndsOnItsTips() {
        for tab in TutorialTab.allCases {
            let actions = TutorialCatalog.steps(for: tab).last?.actions ?? []
            XCTAssertTrue(actions.contains { if case .tips(let area) = $0 { return area == tab.tipsArea } else { return false } },
                          "\(tab)'s last card opens its Tips & Tricks")
        }
    }

    func testTheNudgeIsAnsweredOnceAndRemembered() {
        let settings = Settings.shared
        settings.tutorialNudgesSeenRaw = ""
        XCTAssertFalse(settings.tutorialNudgeSeen(.adhan))
        settings.markTutorialNudgeSeen(.islam)
        settings.markTutorialNudgeSeen(.adhan)
        XCTAssertTrue(settings.tutorialNudgeSeen(.adhan))
        XCTAssertTrue(settings.tutorialNudgeSeen(.islam))
        XCTAssertFalse(settings.tutorialNudgeSeen(.quran))
        XCTAssertEqual(settings.tutorialNudgesSeenRaw, "adhan,islam", "stored in the tabs' own order")
        settings.markTutorialNudgeSeen(.adhan)
        XCTAssertEqual(settings.tutorialNudgesSeenRaw, "adhan,islam")
        XCTAssertTrue(Settings.deviceOnlyStorageKeys.contains("tutorialNudgesSeen"), "a device's onboarding, never backed up")
    }

    /// "New to This Tab?" leads each Need a Hand? run once the tab's nudge is answered; while the nudge
    /// is up it asks the same question right above the section, so the door waits.
    func testEveryDoorLeadsToTheTutorialOnceTheNudgeIsAnswered() {
        let settings = Settings.shared
        settings.tutorialNudgesSeenRaw = ""
        for area in HelpDoorArea.allCases {
            XCTAssertNotEqual(HelpDoorCatalog.doors(for: area, settings: settings).first?.id, "\(area.rawValue).tutorial")
            settings.markTutorialNudgeSeen(TutorialTab(helpDoorArea: area))
            XCTAssertEqual(HelpDoorCatalog.doors(for: area, settings: settings).first?.id, "\(area.rawValue).tutorial")
        }
        XCTAssertEqual(SettingsSearchEntry.tutorialEntries.count, TutorialTab.allCases.count)
        XCTAssertEqual(SettingsSearchEntry.Destination.tutorial(.adhan).scope, .prayer)
        XCTAssertEqual(SettingsSearchEntry.Destination.tutorial(.quran).scope, .quran)
        XCTAssertEqual(SettingsSearchEntry.Destination.tutorial(.hadith).scope, .hadith)
        XCTAssertEqual(SettingsSearchEntry.Destination.tutorial(.islam).scope, .islam)
    }
}
