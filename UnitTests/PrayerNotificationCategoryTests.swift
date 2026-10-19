import XCTest
import UserNotifications
@testable import iPhone

/// The lock-screen buttons every prayer notification carries since 2026-10-19 (Abu: "make sure all
/// of them, not just nagging mode, have it where if you hold down on the notification you can say
/// yes I prayed"), and the one rule that picks them: "late" only when the asked prayer's window has
/// already closed by the time the notification fires, because iOS fixes a notification's actions at
/// scheduling and cannot add or drop one after delivery.
///
/// Also the tracker gate that became the only behaviour the same day: a slot waits for its adhan.
@MainActor
final class PrayerNotificationCategoryTests: XCTestCase {

    /// Mecca, so every prayer is well inside the day and no high-latitude rule is in play.
    private let mecca = Location(city: "Mecca", latitude: 21.4225, longitude: 39.8262)

    private static var savedLocation: Location?
    private static var savedTravelAutomatic = false
    private static var savedTravelingMode = false
    private static var saved = false

    override func setUp() async throws {
        try await super.setUp()
        let settings = Settings.shared
        if !Self.saved {
            Self.savedLocation = settings.currentLocation
            Self.savedTravelAutomatic = settings.travelAutomatic
            Self.savedTravelingMode = settings.travelingMode
            Self.saved = true
        }
        settings.currentLocation = mecca
        // Mecca is far from whatever home this device has, and `travelAutomatic` defaults to true,
        // so the location alone would flip traveling mode on and condense the day to "Dhuhr/Asr".
        // These tests name the five: pin the full set (see AdhanCatchUpOfferTests for the history).
        settings.travelAutomatic = false
        settings.travelingMode = false
    }

    override func tearDown() async throws {
        let settings = Settings.shared
        settings.travelingMode = Self.savedTravelingMode
        settings.travelAutomatic = Self.savedTravelAutomatic
        settings.currentLocation = Self.savedLocation
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func prayer(_ name: String, dayOffset: Int = 0) throws -> Prayer {
        let day = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()))
        let list = try XCTUnwrap(Settings.shared.getPrayerTimes(for: day, fullPrayers: true))
        return try XCTUnwrap(list.first { $0.nameTransliteration == name }, "no \(name) on day \(dayOffset)")
    }

    /// The category the scheduler gives a notification `minutesBefore` the named time, resolved the
    /// way `makePrayerNotificationRequest` resolves it.
    private func category(for name: String, minutesBefore: Int, dayOffset: Int = 0) throws -> String {
        let time = try prayer(name, dayOffset: dayOffset).time
        let moment = Settings.PrayerNotificationMoment(name: name, minutesBefore: minutesBefore, prayerTime: time)
        let question = try XCTUnwrap(Settings.shared.prayerQuestion(for: moment), "\(name)-\(minutesBefore) asks nothing")
        let fires = time.addingTimeInterval(-Double(minutesBefore) * 60)
        return Settings.prayerCategoryIdentifier(asking: question.prayerName, offersLate: question.allowsLateAnswer(at: fires))
    }

    // MARK: - Which buttons

    /// The adhan asks about the prayer that just began: one "yes", since nothing can be late yet.
    func testTheAdhanOffersOneYes() throws {
        XCTAssertEqual(try category(for: "Dhuhr", minutesBefore: 0), "PRAYER_ASK:Dhuhr")
        XCTAssertEqual(try category(for: "Maghrib", minutesBefore: 0), "PRAYER_ASK:Maghrib")
    }

    /// "30m until Asr" asks about Dhuhr, whose window is still open when it fires.
    func testAReminderBeforeTheNextPrayerAsksAboutThePreviousOneWithoutLate() throws {
        XCTAssertEqual(try category(for: "Asr", minutesBefore: 30), "PRAYER_ASK:Dhuhr")
        XCTAssertEqual(try category(for: "Isha", minutesBefore: 15), "PRAYER_ASK:Maghrib")
    }

    /// Shurooq closes Fajr's window the moment it fires, so its at-time notification offers late.
    func testShuroogOffersLateAboutFajr() throws {
        XCTAssertEqual(try category(for: "Shurooq", minutesBefore: 0), "PRAYER_ASK_LATE:Fajr")
        // Ten minutes before Shurooq, Fajr can still only have been prayed on time.
        XCTAssertEqual(try category(for: "Shurooq", minutesBefore: 10), "PRAYER_ASK:Fajr")
    }

    /// A pre-Fajr reminder asks about last night's Isha, whose window closed at Islamic Midnight.
    func testAPreFajrReminderOffersLateAboutIsha() throws {
        XCTAssertEqual(try category(for: "Fajr", minutesBefore: 30, dayOffset: 1), "PRAYER_ASK_LATE:Isha")
    }

    // MARK: - The registered categories

    /// One category per tracker name and kind, the legacy nag category kept, and the prayer named in
    /// every title with the shared action identifiers the delegate switches on.
    func testTheCategorySetNamesEveryPrayer() {
        let categories = Settings.shared.prayerNotificationCategories()
        let byID = Dictionary(uniqueKeysWithValues: categories.map { ($0.identifier, $0) })
        XCTAssertNotNil(byID[Settings.nagCategoryIdentifier])
        XCTAssertEqual(categories.count, 1 + 2 * Settings.trackablePrayerNames.count)

        let ask = try? XCTUnwrap(byID["PRAYER_ASK:Dhuhr"])
        XCTAssertEqual(ask?.actions.map(\.identifier), [Settings.nagActionMarkPrayedIdentifier])
        XCTAssertEqual(ask?.actions.first?.title, "Yes, I prayed Dhuhr")
        XCTAssertFalse(ask?.actions.first?.options.contains(.foreground) ?? true, "answering must not open the app")

        let late = try? XCTUnwrap(byID["PRAYER_ASK_LATE:Dhuhr/Asr"])
        XCTAssertEqual(late?.actions.map(\.identifier),
                       [Settings.nagActionMarkPrayedIdentifier, Settings.nagActionMarkPrayedLateIdentifier])
        XCTAssertEqual(late?.actions.map(\.title), ["Prayed Dhuhr/Asr on time", "Prayed Dhuhr/Asr late"])
    }

    // MARK: - The tracker gate

    /// Today's slot waits for its time; the past is always editable; the rule has no switch.
    func testTodaysSlotWaitsForItsTime() {
        let now = Date()
        let settings = Settings.shared
        XCTAssertFalse(settings.canMarkPrayer(startingAt: now.addingTimeInterval(3600), on: now, at: now))
        XCTAssertTrue(settings.canMarkPrayer(startingAt: now.addingTimeInterval(-3600), on: now, at: now))
        let yesterday = now.addingTimeInterval(-86_400)
        XCTAssertTrue(settings.canMarkPrayer(startingAt: yesterday.addingTimeInterval(3600), on: yesterday, at: now))
    }
}
