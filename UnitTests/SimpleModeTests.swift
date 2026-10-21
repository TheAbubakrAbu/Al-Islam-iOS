import SwiftUI
import XCTest
@testable import iPhone

/// Simple Mode's pure rules (docs/Simple Mode Guide.md, 2026-10-10): the Adhan tab's tracker gate, the
/// permission dialogs' one-day snooze, and the promise that the switch itself changes no other setting.
@MainActor
final class SimpleModeTests: XCTestCase {
    private var savedSimpleMode: Any?

    override func setUp() {
        super.setUp()
        savedSimpleMode = UserDefaults.standard.object(forKey: "simpleMode")
    }

    override func tearDown() {
        restoreSimpleMode()
        super.tearDown()
    }

    /// Puts the host app's flag back as setUp found it. A raw write on purpose: going through
    /// `Settings.simpleMode` would run rule 9's fold again on an off→on restore.
    private func restoreSimpleMode() {
        if let savedSimpleMode {
            UserDefaults.standard.set(savedSimpleMode, forKey: "simpleMode")
        } else {
            UserDefaults.standard.removeObject(forKey: "simpleMode")
        }
    }

    /// Every screen's Advanced key as stored (nil where it was never written), for a `defer` to put back.
    private static func storedAdvancedKeys() -> [(key: String, value: Any?)] {
        Settings.AdvancedScreen.allCases.map { ($0.storageKey, UserDefaults.standard.object(forKey: $0.storageKey)) }
    }

    private static func restoreAdvancedKeys(_ stored: [(key: String, value: Any?)]) {
        for (key, value) in stored {
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private static let keyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Noon on 2026-10-10, UTC.
    private let today = Date(timeIntervalSince1970: 1_791_633_600)

    private func key(daysBack: Int) -> String {
        Self.keyFormatter.string(from: Self.calendar.date(byAdding: .day, value: -daysBack, to: today)!)
    }

    private func gate(_ tracker: [String: [String: PrayerMark]]) -> Bool {
        SimpleMode.markedRecently(tracker, today: today, calendar: Self.calendar) { Self.keyFormatter.string(from: $0) }
    }

    func testTrackerGateWindow() {
        XCTAssertTrue(gate([key(daysBack: 0): ["Fajr": .onTime]]), "a mark today keeps the tracker")
        XCTAssertTrue(gate([key(daysBack: 13): ["Isha": .missed]]), "13 days back is inside the 14-day window")
        XCTAssertFalse(gate([key(daysBack: 15): ["Dhuhr": .late]]), "15 days back is outside it")
        XCTAssertFalse(gate([:]), "nothing ever marked")
        XCTAssertFalse(gate([key(daysBack: 2): [:]]), "a day whose marks were all cleared does not count")
    }

    func testSnooze() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertTrue(SimpleMode.isSnoozed(until: now.timeIntervalSince1970 + 1, now: now))
        XCTAssertFalse(SimpleMode.isSnoozed(until: now.timeIntervalSince1970 - 1, now: now))
        XCTAssertFalse(SimpleMode.isSnoozed(until: 0, now: now), "never snoozed")
        XCTAssertEqual(SimpleMode.nagSnooze, 86_400, "Abu, 2026-10-10: make it wait a day")
    }

    /// Rule 1: hiding never changes what the app does. Turning Simple Mode on and off again, with the
    /// app's views re-rendering in between, must leave every other stored setting as it was.
    ///
    /// The host app is live while this runs, and its launch writes on its own schedule (a reader the
    /// launch reopens records the visit; UIKit keeps keys of its own). So the launch settles first, an
    /// idle window of the same length records what changes with nobody touching anything, and only a
    /// write beyond that, in a key the app owns, is laid at the switch's door.
    ///
    /// Rule 9's fold is the one write the flip owns: turning Simple Mode on turns every screen's
    /// Advanced switch off, so the `advancedSettings_` keys are expected to change and are put back.
    func testFlippingSimpleModeWritesNothingElse() {
        let defaults = UserDefaults.standard
        let storedAdvanced = Self.storedAdvancedKeys()
        defer { Self.restoreAdvancedKeys(storedAdvanced) }
        RunLoop.main.run(until: Date().addingTimeInterval(4))

        let idleStart = defaults.dictionaryRepresentation()
        RunLoop.main.run(until: Date().addingTimeInterval(2))
        let ambient = Self.changedKeys(idleStart, defaults.dictionaryRepresentation())

        let before = defaults.dictionaryRepresentation()
        Settings.shared.simpleMode = true
        RunLoop.main.run(until: Date().addingTimeInterval(1))
        Settings.shared.simpleMode = false
        RunLoop.main.run(until: Date().addingTimeInterval(1))

        let changed = Self.changedKeys(before, defaults.dictionaryRepresentation())
            .subtracting(ambient)
            .subtracting(["simpleMode"])
            .filter { !$0.hasPrefix("advancedSettings_") }
            .filter { !$0.hasPrefix("NS") && !$0.hasPrefix("Apple") && !$0.hasPrefix("com.apple") }
        XCTAssertTrue(changed.isEmpty, "flipping Simple Mode wrote, beyond rule 9's advancedSettings_ fold: \(changed.sorted())")
    }

    /// Rule 9: turning Simple Mode ON folds every screen's Advanced switch off, once, on the off→on edge.
    /// Turning it off restores nothing, and a switch turned on while Simple Mode is on stays on.
    func testTurningSimpleOnFoldsAdvancedSwitches() {
        let settings = Settings.shared
        let storedAdvanced = Self.storedAdvancedKeys()
        defer {
            restoreSimpleMode()
            Self.restoreAdvancedKeys(storedAdvanced)
        }

        settings.simpleMode = false
        settings.setAdvanced(.prayerCalculation, true)
        settings.setAdvanced(.quranReadingView, true)

        settings.simpleMode = true
        for screen in Settings.AdvancedScreen.allCases {
            XCTAssertFalse(settings.advanced(screen), "turning Simple Mode on left \(screen.rawValue)'s Advanced switch on")
        }

        settings.setAdvanced(.quranReadingView, true)
        settings.simpleMode = false
        XCTAssertTrue(settings.advanced(.quranReadingView), "a switch turned on while Simple Mode was on did not stay on")
        XCTAssertFalse(settings.advanced(.prayerCalculation), "turning Simple Mode off restored a folded switch")
    }

    /// The fold runs on the edge only: search's reveal still turns every switch on while Simple Mode is
    /// on, and nothing (a render, a publish) folds them back afterwards.
    func testRevealAfterFoldStays() {
        let settings = Settings.shared
        let storedAdvanced = Self.storedAdvancedKeys()
        defer {
            restoreSimpleMode()
            Self.restoreAdvancedKeys(storedAdvanced)
        }

        settings.simpleMode = true
        settings.revealAllAdvancedSettings()
        for screen in Settings.AdvancedScreen.allCases {
            XCTAssertTrue(settings.advanced(screen), "revealAllAdvancedSettings() left \(screen.rawValue) off in Simple Mode")
        }

        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        for screen in Settings.AdvancedScreen.allCases {
            XCTAssertTrue(settings.advanced(screen), "\(screen.rawValue)'s Advanced switch folded again after the reveal")
        }
    }

    /// Ignore on a permission dialog quiets it for exactly one day.
    func testSnoozeSetsADay() {
        let settings = Settings.shared
        let savedLocation = settings.locationAlertSnoozedUntil
        let savedNotification = settings.notificationAlertSnoozedUntil
        defer {
            settings.locationAlertSnoozedUntil = savedLocation
            settings.notificationAlertSnoozedUntil = savedNotification
        }
        let now = Date(timeIntervalSince1970: 2_000_000)
        settings.snoozePermissionAlert(location: true, now: now)
        XCTAssertEqual(settings.locationAlertSnoozedUntil, 2_000_000 + 86_400)
        settings.snoozePermissionAlert(location: false, now: now)
        XCTAssertEqual(settings.notificationAlertSnoozedUntil, 2_000_000 + 86_400)
        XCTAssertTrue(SimpleMode.isSnoozed(until: settings.locationAlertSnoozedUntil, now: now.addingTimeInterval(86_399)))
        XCTAssertFalse(SimpleMode.isSnoozed(until: settings.locationAlertSnoozedUntil, now: now.addingTimeInterval(86_401)))
    }

    /// Existing users never see the splash's question, so Settings search has to find the switch by
    /// the words someone overwhelmed would type.
    func testSimpleModeIsSearchable() {
        let entry = SettingsSearchEntry.appearanceEntries.first { $0.title == "Simple Mode" }
        XCTAssertNotNil(entry, "no Simple Mode entry in Settings search")
        XCTAssertTrue(entry?.keywords.contains("overwhelming") == true)
        XCTAssertTrue(entry?.keywords.contains("clutter") == true)
    }

    /// The Simple traveler's door to full prayers is a row on the Traveling Mode page, so search must find it.
    func testShowFullPrayersIsSearchable() {
        let entry = SettingsSearchEntry.adhanEntries.first { $0.title == "Show Full Prayers" }
        XCTAssertNotNil(entry, "no Show Full Prayers entry in Settings search")
        XCTAssertTrue(entry?.keywords.contains("qasr") == true)
        XCTAssertTrue(entry?.keywords.contains("traveling") == true)
    }

    /// The Simple Mode switch and the Show Full Prayers switch bind `$settings.simpleMode` and
    /// `$settings.travelingShowFullPrayers` through an `@ObservedObject`, with `.animation`. Built here
    /// the same way, each binding must run its property's `didSet`: rule 9's fold for the first, the
    /// app-group mirror the widgets read for the second. `testSimpleModeSwitchFoldsAdvanced` (UI) taps
    /// the real Simple Mode switch.
    func testObservedBindingsRunTheDidSets() {
        let settings = Settings.shared
        let storedAdvanced = Self.storedAdvancedKeys()
        let storedFull = settings.travelingShowFullPrayers
        let storedGroupFull = settings.appGroupUserDefaults?.object(forKey: "travelingShowFullPrayers")
        defer {
            restoreSimpleMode()
            Self.restoreAdvancedKeys(storedAdvanced)
            settings.travelingShowFullPrayers = storedFull
            if let storedGroupFull {
                settings.appGroupUserDefaults?.set(storedGroupFull, forKey: "travelingShowFullPrayers")
            } else {
                settings.appGroupUserDefaults?.removeObject(forKey: "travelingShowFullPrayers")
            }
        }
        let bindings = ObservedObject(wrappedValue: settings).projectedValue

        settings.simpleMode = false
        settings.setAdvanced(.prayerCalculation, true)
        settings.setAdvanced(.islamLibraries, true)
        bindings.simpleMode.animation(.easeInOut).wrappedValue = true
        XCTAssertTrue(settings.simpleMode)
        for screen in Settings.AdvancedScreen.allCases {
            XCTAssertFalse(settings.advanced(screen), "the switch's binding skipped rule 9's fold: \(screen.rawValue) stayed on")
        }

        let flipped = !storedFull
        bindings.travelingShowFullPrayers.animation(.easeInOut).wrappedValue = flipped
        XCTAssertEqual(settings.travelingShowFullPrayers, flipped)
        XCTAssertEqual(settings.appGroupUserDefaults?.object(forKey: "travelingShowFullPrayers") as? Bool, flipped,
                       "the Show Full Prayers binding skipped the didSet that mirrors the key for the widgets")
    }

    /// The four "Need a Hand? on the ... Tab" entries land on a section Simple Mode hides, so search must
    /// not offer them while it is on. Flipping Simple folds the Advanced switches (rule 9); put them back.
    func testNeedAHandEntriesLeaveSearchInSimple() {
        let settings = Settings.shared
        let storedAdvanced = Self.storedAdvancedKeys()
        defer { Self.restoreAdvancedKeys(storedAdvanced) }
        let wasSimple = settings.simpleMode
        defer { settings.simpleMode = wasSimple }

        func titles() -> [String] {
            SettingsSearchEntry.rank(SettingsSearchEntry.all, query: "need a hand")
                .map(\.title)
                .filter { $0.hasPrefix("Need a Hand? on the") }
        }

        settings.simpleMode = false
        XCTAssertFalse(titles().isEmpty, "Full Mode: the Need a Hand? entries are searchable")
        settings.simpleMode = true
        XCTAssertTrue(titles().isEmpty, "Simple Mode: they would land on a hidden section: \(titles())")
        // The semantic matches and Ask AI's settings lane read `available()` instead of `rank`.
        XCTAssertFalse(SettingsSearchEntry.available().contains { $0.title.hasPrefix("Need a Hand? on the") },
                       "Simple Mode: the AI paths' collection still holds them")
        settings.simpleMode = false
        XCTAssertTrue(SettingsSearchEntry.available().contains { $0.title.hasPrefix("Need a Hand? on the") })
    }

    private static func changedKeys(_ before: [String: Any], _ after: [String: Any]) -> Set<String> {
        Set(before.keys).union(after.keys).filter { key in
            switch (before[key], after[key]) {
            case (nil, nil): return false
            case let (lhs?, rhs?): return !(lhs as AnyObject).isEqual(rhs)
            default: return true
            }
        }
    }
}
