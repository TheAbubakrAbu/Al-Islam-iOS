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
        if let savedSimpleMode {
            UserDefaults.standard.set(savedSimpleMode, forKey: "simpleMode")
        } else {
            UserDefaults.standard.removeObject(forKey: "simpleMode")
        }
        super.tearDown()
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
    func testFlippingSimpleModeWritesNothingElse() {
        let defaults = UserDefaults.standard
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
            .filter { !$0.hasPrefix("NS") && !$0.hasPrefix("Apple") && !$0.hasPrefix("com.apple") }
        XCTAssertTrue(changed.isEmpty, "flipping Simple Mode wrote: \(changed.sorted())")
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
