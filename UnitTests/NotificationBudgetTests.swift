import XCTest
@testable import iPhone

/// The prayer notification budget (iOS keeps 64 pending; the scheduler caps itself at 60). The cap,
/// the floor and the event horizon are applied inline in `schedulePrayerTimeNotifications`, so these
/// tests pin the pure inputs to that arithmetic.
final class NotificationBudgetTests: XCTestCase {

    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "UnitTests.NotificationBudget.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func store(_ object: Any, forKey key: String) throws {
        defaults.set(try JSONSerialization.data(withJSONObject: object), forKey: key)
    }

    /// P2: Hijri events and at-time adhans share a 14-day horizon, and prayers keep at least 20 slots (D4).
    func testHorizonAndFloorConstants() {
        XCTAssertEqual(Settings.adhanHorizonDays, 14)
        XCTAssertEqual(Settings.minimumPrayerNotificationBudget, 20)
    }

    /// P2: an empty store takes nothing from the prayers' budget.
    func testNothingEnabledCountsZero() {
        XCTAssertEqual(Settings.SunnahReminderBudget.enabledCount(in: defaults), 0)
    }

    /// P2: each reminder kind is counted: enabled custom rows, 8 duas, 3 last-read nudges, 3 streak nudges, Sunnah presets.
    func testEveryReminderKindIsCounted() throws {
        typealias Budget = Settings.SunnahReminderBudget
        try store([["enabled": true], ["enabled": true], ["enabled": false], [:]], forKey: Budget.customKey)
        try store(["duaEnabled": true, "lastReadEnabled": true, "streakEnabled": true], forKey: Budget.extraKey)
        try store(["monday": ["enabled": true], "friday": ["enabled": false], "duha": ["enabled": true]], forKey: Budget.defaultsKey)
        XCTAssertEqual(Budget.duaCap, 8)
        XCTAssertEqual(Budget.nudgeDays, 3)
        XCTAssertEqual(Budget.extraCount(in: defaults), 2 + 8 + 3 + 3)
        XCTAssertEqual(Budget.enabledCount(in: defaults), 2 + 8 + 3 + 3 + 2)
    }

    /// P2: custom reminders are uncapped, so the other reminders alone can reach the whole 60, which is why the floor exists.
    func testCustomRemindersCanExhaustTheCap() throws {
        typealias Budget = Settings.SunnahReminderBudget
        try store(Array(repeating: ["enabled": true], count: 70), forKey: Budget.customKey)
        let others = Budget.enabledCount(in: defaults)
        XCTAssertEqual(others, 70)
        // The scheduler's own arithmetic (SettingsAdhan.swift, `maxPending`): 60 minus the others, floored.
        XCTAssertLessThanOrEqual(60 - others, 0)
        XCTAssertEqual(max(Settings.minimumPrayerNotificationBudget, 60 - others), 20)
    }

    /// P2: undecodable reminder data counts as nothing rather than breaking the count.
    func testGarbageCountsZero() {
        typealias Budget = Settings.SunnahReminderBudget
        defaults.set(Data("not json".utf8), forKey: Budget.customKey)
        defaults.set(Data("[1,2".utf8), forKey: Budget.extraKey)
        defaults.set("a string", forKey: Budget.defaultsKey)
        XCTAssertEqual(Budget.enabledCount(in: defaults), 0)
    }

    /// P2: the default nag cascade is 30, 15, 10, 5, and a cascade never spends two slots on one offset.
    func testNagCascadeIsDeduplicated() {
        XCTAssertEqual(Settings.naggingCascade(start: 30, interval: 15, lastCalls: .both), [30, 15, 10, 5])
        // A start of 20 walks down to 5 and the last calls re-add 10 and 5: still four slots.
        XCTAssertEqual(Settings.naggingCascade(start: 20, interval: 5, lastCalls: .both), [20, 15, 10, 5])
        XCTAssertEqual(Settings.naggingCascade(start: 0, interval: 5, lastCalls: .both), [])
    }
}
