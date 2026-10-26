import XCTest
@testable import iPhone

/// The clock-change notice under the prayer times (`ClockChange`): found within the week before a
/// daylight-saving change and on its day, worded by the size and direction of the jump, absent
/// otherwise. Los Angeles 2026: clocks go forward at 02:00 on Sunday 8 March (to 03:00 PDT), back at
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
}
