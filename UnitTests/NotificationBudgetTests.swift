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

    // MARK: A simulator stays quiet

    /// A simulator's sound comes out of the Mac it runs on: one left booted rang two weeks of
    /// scheduled adhans through it at its own location's times, San Francisco's, ten to twenty
    /// minutes after Irvine's (Abu, 2026-11-16). So a request built in a simulator carries no sound
    /// unless `simulatorAdhanSound` asks for it, and its text and identifier are untouched.
    func testASimulatorSchedulesPrayerNotificationsWithoutSound() {
        #if targetEnvironment(simulator)
        let key = Settings.simulatorAdhanSoundKey
        let saved = UserDefaults.standard.object(forKey: key)
        defer { UserDefaults.standard.set(saved, forKey: key) }

        let spec = Settings.PendingNotificationSpec(
            identifier: "Isha-0-2026-11-16", body: "Time for Isha", soundFile: "minshawi-2-30.caf",
            categoryIdentifier: nil, intendedFireDate: Date(timeIntervalSince1970: 1_794_880_800),
            trigger: DateComponents(year: 2026, month: 11, day: 16, hour: 18, minute: 0)
        )

        UserDefaults.standard.removeObject(forKey: key)
        XCTAssertTrue(Settings.mutesAdhanInSimulator, "quiet is the default in a simulator")
        let quiet = Settings.buildNotificationRequest(from: spec)
        XCTAssertNil(quiet.content.sound, "a simulator's adhan must not ring through the Mac")
        XCTAssertEqual(quiet.content.body, "Time for Isha")
        XCTAssertEqual(quiet.identifier, "Isha-0-2026-11-16")

        UserDefaults.standard.set(true, forKey: key)
        XCTAssertFalse(Settings.mutesAdhanInSimulator)
        XCTAssertNotNil(Settings.buildNotificationRequest(from: spec).content.sound, "asked for, it sounds")
        #else
        XCTAssertFalse(Settings.mutesAdhanInSimulator, "a device is never muted")
        #endif
    }

    /// A schedule built under the other answer is rebuilt once: without that, a simulator already
    /// holding two weeks of adhans kept them (a plain launch reschedules nothing the same day).
    func testASimulatorRebuildsAScheduleBuiltUnderTheOtherAnswer() {
        #if targetEnvironment(simulator)
        let soundKey = Settings.simulatorAdhanSoundKey
        let builtKey = Settings.simulatorScheduleSoundKey
        let savedSound = UserDefaults.standard.object(forKey: soundKey)
        let savedBuilt = UserDefaults.standard.object(forKey: builtKey)
        defer {
            UserDefaults.standard.set(savedSound, forKey: soundKey)
            UserDefaults.standard.set(savedBuilt, forKey: builtKey)
        }

        UserDefaults.standard.removeObject(forKey: soundKey)
        UserDefaults.standard.removeObject(forKey: builtKey)
        XCTAssertTrue(Settings.simulatorScheduleIsStale, "a schedule from before the rule is rebuilt")

        Settings.noteSimulatorScheduleBuilt()
        XCTAssertFalse(Settings.simulatorScheduleIsStale, "and only once")

        UserDefaults.standard.set(true, forKey: soundKey)
        XCTAssertTrue(Settings.simulatorScheduleIsStale, "asking for sound rebuilds it with sound")
        Settings.noteSimulatorScheduleBuilt()
        XCTAssertFalse(Settings.simulatorScheduleIsStale)
        #else
        XCTAssertFalse(Settings.simulatorScheduleIsStale, "a device never owes this rebuild")
        #endif
    }

    /// P2: the default nag cascade is 30, 15, 10, 5, and a cascade never spends two slots on one offset.
    func testNagCascadeIsDeduplicated() {
        XCTAssertEqual(Settings.naggingCascade(start: 30, interval: 15, lastCalls: .both), [30, 15, 10, 5])
        // A start of 20 walks down to 5 and the last calls re-add 10 and 5: still four slots.
        XCTAssertEqual(Settings.naggingCascade(start: 20, interval: 5, lastCalls: .both), [20, 15, 10, 5])
        XCTAssertEqual(Settings.naggingCascade(start: 0, interval: 5, lastCalls: .both), [])
    }
}
