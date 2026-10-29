import XCTest
@testable import iPhone

/// The clock-change notice under the prayer times (`ClockChange`): found within the week before a
/// daylight-saving change and on its day, worded by the size and direction of the jump, absent
/// otherwise; and the notification the evening before it. Los Angeles 2026: clocks go forward at 02:00 on Sunday 8 March (to 03:00 PDT), back at
/// 02:00 PDT on Sunday 1 November (to 01:00 PST).
final class ClockChangeNoticeTests: XCTestCase {

    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
    private let gregorian = Calendar(identifier: .gregorian)

    /// A wall-clock moment in `zone` (the earlier instant when the time occurs twice).
    private func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0,
                        zone: TimeZone? = nil) -> Date {
        var calendar = gregorian
        calendar.timeZone = zone ?? losAngeles
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
        moment(year, month, day, hour, zone: TimeZone(identifier: "UTC")!)
    }

    private func change(at now: Date, zone: TimeZone? = nil) -> ClockChange? {
        ClockChange.next(after: now, in: zone ?? losAngeles, calendar: gregorian)
    }

    private func days(_ change: ClockChange?, from now: Date) -> Int? {
        var calendar = gregorian
        calendar.timeZone = losAngeles
        return change?.daysAway(from: now, calendar: calendar)
    }

    /// The fall change a week ahead: found, the clocks go back an hour, daylight saving ends.
    func testFallChangeIsFoundSevenDaysAhead() throws {
        let now = moment(2026, 10, 25)
        let found = try XCTUnwrap(change(at: now))
        XCTAssertEqual(found.date, utc(2026, 11, 1, 9), "02:00 PDT on 1 November is 09:00 UTC")
        XCTAssertEqual(found.delta, -3600)
        XCTAssertFalse(found.goesForward)
        XCTAssertEqual(found.beginsDaylightSaving, false)
        XCTAssertEqual(days(found, from: now), 7)
    }

    /// Eight days ahead is beyond the week: nothing to say yet.
    func testEightDaysAheadIsTooEarly() {
        XCTAssertNil(change(at: moment(2026, 10, 24)))
    }

    /// The day before: one day away.
    func testTheDayBeforeIsOneDayAway() {
        let now = moment(2026, 10, 31, 22)
        XCTAssertEqual(days(change(at: now), from: now), 1)
    }

    /// On the day, before the change (00:30 PDT): still ahead.
    func testOnTheDayBeforeTheChange() throws {
        let now = moment(2026, 11, 1, 0, 30)
        let found = try XCTUnwrap(change(at: now))
        XCTAssertEqual(days(found, from: now), 0)
        XCTAssertGreaterThan(found.date, now)
    }

    /// On the day, after the change (10:00 PST): still found, now behind us, so the row can say "went back".
    func testOnTheDayAfterTheChange() throws {
        let now = moment(2026, 11, 1, 10)
        let found = try XCTUnwrap(change(at: now))
        XCTAssertEqual(days(found, from: now), 0)
        XCTAssertLessThan(found.date, now)
        XCTAssertEqual(found.delta, -3600)
    }

    /// The day after the change: the next one is in March, far outside the week.
    func testTheDayAfterShowsNothing() {
        XCTAssertNil(change(at: moment(2026, 11, 2)))
    }

    /// The spring change: the clocks go forward an hour and daylight saving begins.
    func testSpringChangeGoesForward() throws {
        let now = moment(2026, 3, 2)
        let found = try XCTUnwrap(change(at: now))
        XCTAssertEqual(found.date, utc(2026, 3, 8, 10), "02:00 PST on 8 March is 10:00 UTC")
        XCTAssertEqual(found.delta, 3600)
        XCTAssertTrue(found.goesForward)
        XCTAssertEqual(found.beginsDaylightSaving, true)
        XCTAssertEqual(days(found, from: now), 6)
    }

    /// A zone without daylight saving never has a change to announce.
    func testZoneWithoutDaylightSavingHasNoChange() {
        let riyadh = TimeZone(identifier: "Asia/Riyadh")!
        XCTAssertNil(change(at: moment(2026, 10, 25, zone: riyadh), zone: riyadh))
        XCTAssertNil(change(at: moment(2026, 3, 2, zone: riyadh), zone: riyadh))
    }

    /// Lord Howe Island moves its clocks by half an hour (forward on the first Sunday of October):
    /// the jump is reported as it is, not rounded to an hour.
    func testHalfHourChangeIsReportedInMinutes() throws {
        let lordHowe = TimeZone(identifier: "Australia/Lord_Howe")!
        let now = moment(2026, 10, 1, zone: lordHowe)
        let found = try XCTUnwrap(ClockChange.next(after: now, in: lordHowe, calendar: gregorian))
        XCTAssertEqual(found.delta, 1800)
        XCTAssertEqual(found.beginsDaylightSaving, true)
        XCTAssertEqual(found.amountText, "30 minutes")
    }

    /// The jump's wording: one hour, two hours.
    func testAmountWording() {
        XCTAssertEqual(ClockChange(date: Date(), delta: 3600, beginsDaylightSaving: true, offsetBefore: 0).amountText, "1 hour")
        XCTAssertEqual(ClockChange(date: Date(), delta: -7200, beginsDaylightSaving: nil, offsetBefore: 0).amountText, "2 hours")
    }

    /// The change is announced on the clock as it read BEFORE the jump: both US changes happen "at
    /// 2:00 AM", though the fall instant already reads 1:00 AM in the zone and the spring one 3:00 AM.
    func testTheTimeIsReadOnTheOldClock() throws {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = gregorian
        formatter.timeZone = losAngeles
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        // Foundation puts a narrow no-break space before AM; compare on plain spaces.
        func plain(_ text: String) -> String {
            text.replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{00A0}", with: " ")
        }

        let fall = try XCTUnwrap(change(at: moment(2026, 10, 31)))
        XCTAssertEqual(fall.offsetBefore, -7 * 3600, "PDT before the fall change")
        XCTAssertEqual(plain(fall.clockReading(formatter)), "2:00 AM")
        XCTAssertEqual(plain(formatter.string(from: fall.date)), "1:00 AM", "the instant itself reads the new clock")

        let spring = try XCTUnwrap(change(at: moment(2026, 3, 7)))
        XCTAssertEqual(spring.offsetBefore, -8 * 3600, "PST before the spring change")
        XCTAssertEqual(plain(spring.clockReading(formatter)), "2:00 AM")
    }

    // MARK: - The evening-before notification

    private func calendar(in zone: TimeZone) -> Calendar {
        var calendar = gregorian
        calendar.timeZone = zone
        return calendar
    }

    private func usFormatter(_ zone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = gregorian
        formatter.timeZone = zone
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }

    private func plain(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{00A0}", with: " ")
    }

    /// The heads-up lands at 6 PM the evening before, like the day-before Islamic date reminders:
    /// Saturday 31 October (PDT) for the fall change, Saturday 7 March (PST) for the spring one.
    func testHeadsUpIsSixInTheEveningTheDayBefore() throws {
        let fall = try XCTUnwrap(change(at: moment(2026, 10, 25)))
        XCTAssertEqual(fall.headsUpDate(calendar: calendar(in: losAngeles)), moment(2026, 10, 31, 18))
        let spring = try XCTUnwrap(change(at: moment(2026, 3, 2)))
        XCTAssertEqual(spring.headsUpDate(calendar: calendar(in: losAngeles)), moment(2026, 3, 7, 18))
    }

    /// Santiago changes at midnight. Its fall change (00:00 on Sunday 5 April 2026, back to 23:00
    /// Saturday) is announced Saturday evening, the day before on the OLD clock, not Friday, which the
    /// instant's new-clock reading would give; the spring one (00:00 Sunday 6 September, forward to
    /// 01:00, so that day has no midnight) on Saturday 5 September.
    func testMidnightChangesAreAnnouncedTheEveningBeforeOnTheOldClock() throws {
        let santiago = TimeZone(identifier: "America/Santiago")!
        let local = calendar(in: santiago)
        let fall = try XCTUnwrap(ClockChange.next(after: moment(2026, 4, 1, zone: santiago), in: santiago, calendar: gregorian))
        XCTAssertEqual(fall.date, utc(2026, 4, 5, 3))
        XCTAssertEqual(fall.headsUpDate(calendar: local), moment(2026, 4, 4, 18, zone: santiago))
        let spring = try XCTUnwrap(ClockChange.next(after: moment(2026, 9, 1, zone: santiago), in: santiago, calendar: gregorian))
        XCTAssertEqual(spring.date, utc(2026, 9, 6, 4))
        XCTAssertEqual(spring.headsUpDate(calendar: local), moment(2026, 9, 5, 18, zone: santiago))
    }

    /// The heads-up's wording, said from the evening before: the event reminder's "X is tomorrow: ..."
    /// shape for daylight saving, the plain direction for any other move of the clocks.
    func testHeadsUpWording() throws {
        let formatter = usFormatter(losAngeles)
        let fall = try XCTUnwrap(change(at: moment(2026, 10, 25)))
        XCTAssertEqual(plain(fall.headsUpBody(timeFormatter: formatter)),
                       "Daylight Saving Time ends tomorrow: clocks go back 1 hour at 2:00 AM. Prayer times will be about 1 hour earlier.")
        let spring = try XCTUnwrap(change(at: moment(2026, 3, 2)))
        XCTAssertEqual(plain(spring.headsUpBody(timeFormatter: formatter)),
                       "Daylight Saving Time begins tomorrow: clocks go forward 1 hour at 2:00 AM. Prayer times will be about 1 hour later.")

        let utcFormatter = usFormatter(TimeZone(identifier: "UTC")!)
        let instant = utc(2026, 6, 1, 0)
        XCTAssertEqual(plain(ClockChange(date: instant, delta: 3600, beginsDaylightSaving: nil, offsetBefore: 0)
                                .headsUpBody(timeFormatter: utcFormatter)),
                       "Clocks go forward 1 hour tomorrow at 12:00 AM. Prayer times will be about 1 hour later.")
        XCTAssertEqual(plain(ClockChange(date: instant, delta: -1800, beginsDaylightSaving: nil, offsetBefore: 0)
                                .headsUpBody(timeFormatter: utcFormatter)),
                       "Clocks go back 30 minutes tomorrow at 12:00 AM. Prayer times will be about 30 minutes earlier.")
    }

    /// The scheduler's request: built only while some prayer notification is on, at the heads-up's
    /// moment in the device's zone, under the "Event-" prefix the prune owns; nil once that evening has
    /// passed. Run in the simulator's own zone; skipped where it has no change ahead.
    func testSchedulerBuildsTheHeadsUpWhilePrayerNotificationsAreOn() throws {
        let zone = TimeZone.current
        let local = calendar(in: zone)
        guard let transition = zone.nextDaylightSavingTimeTransition(after: Date()) else {
            throw XCTSkip("\(zone.identifier) has no clock change ahead")
        }
        let now = transition.addingTimeInterval(-3 * 86_400)
        let change = try XCTUnwrap(ClockChange.next(after: now, in: zone, horizonDays: Settings.adhanHorizonDays, calendar: local))
        let headsUp = try XCTUnwrap(change.headsUpDate(calendar: local))
        let settings = Settings.shared
        let anyOn = [settings.notificationFajr, settings.notificationSunrise, settings.notificationDhuhr,
                     settings.notificationAsr, settings.notificationMaghrib, settings.notificationIsha,
                     settings.notificationDuha, settings.notificationIslamicMidnight, settings.notificationLastThird]
            .contains(true)

        let built = settings.makeClockChangeNotificationRequest(now: now)
        guard anyOn else {
            XCTAssertNil(built, "no prayer notification is on, so no heads-up")
            return
        }
        let request = try XCTUnwrap(built)
        XCTAssertEqual(request.date, headsUp)
        XCTAssertTrue(request.spec.identifier.hasPrefix("Event-ClockChange-"))
        XCTAssertEqual(request.spec.trigger.hour, 18)
        XCTAssertNil(settings.makeClockChangeNotificationRequest(now: headsUp.addingTimeInterval(60)),
                     "the evening has passed: the prayer list's footer says it from then on")
    }
}
