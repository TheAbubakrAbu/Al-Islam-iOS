import XCTest
@testable import iPhone

/// `DailyRollover` across the 2026 US daylight-saving changes (Los Angeles: clocks go forward at
/// 02:00 on Sunday 8 March, back at 02:00 on Sunday 1 November). The Fajr table is keyed by
/// `Settings.dayKey`, which reads the process time zone, so the process zone is pinned too.
final class DailyRolloverTests: XCTestCase {

    private let zone = TimeZone(identifier: "America/Los_Angeles")!
    private var savedZone: TimeZone!
    private var calendar = Calendar(identifier: .gregorian)

    override func setUp() {
        super.setUp()
        savedZone = NSTimeZone.default
        NSTimeZone.default = zone
        calendar.timeZone = zone
    }

    override func tearDown() {
        NSTimeZone.default = savedZone
        super.tearDown()
    }

    /// A wall-clock time in Los Angeles (the earlier instant when the time occurs twice).
    private func la(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func dayIndex(_ date: Date, _ table: [String: TimeInterval]?) -> Int {
        DailyRollover.dayIndex(for: date, fajrByDay: table, calendar: calendar)
    }

    private func index(ofDay date: Date) -> Int {
        DailyRollover.index(ofDay: calendar.startOfDay(for: date), calendar: calendar)
    }

    /// Plausible Fajr times around both changes; the tests only need them to fall after the 02:00 change.
    private var fajrTable: [String: TimeInterval] {
        [
            "2026-03-07": la(2026, 3, 7, 5, 29).timeIntervalSince1970,
            "2026-03-08": la(2026, 3, 8, 6, 27).timeIntervalSince1970,   // first day of PDT
            "2026-03-09": la(2026, 3, 9, 6, 26).timeIntervalSince1970,
            "2026-10-31": la(2026, 10, 31, 6, 2).timeIntervalSince1970,
            "2026-11-01": la(2026, 11, 1, 5, 3).timeIntervalSince1970,   // first day of PST
            "2026-11-02": la(2026, 11, 2, 5, 4).timeIntervalSince1970,
        ]
    }

    /// Daily rollover: the day key the Fajr table uses follows the pinned zone (a precondition for the rest).
    func testDayKeyUsesThePinnedZone() {
        // 20:00 on 8 March in Los Angeles is already 9 March in UTC.
        XCTAssertEqual(Settings.dayKey(la(2026, 3, 8, 20)), "2026-03-08")
        XCTAssertEqual(Settings.dayKey(la(2026, 11, 1, 23, 30)), "2026-11-01")
    }

    /// Daily rollover: the day index advances by exactly one per calendar day through spring forward.
    func testIndexAdvancesByOneThroughSpringForward() {
        var previous = index(ofDay: la(2026, 2, 28, 12))
        for day in 1...15 {
            let current = index(ofDay: la(2026, 3, day, 12))
            XCTAssertEqual(current, previous + 1, "March \(day)")
            previous = current
        }
    }

    /// Daily rollover: the day index advances by exactly one per calendar day through fall back.
    func testIndexAdvancesByOneThroughFallBack() {
        var previous = index(ofDay: la(2026, 10, 24, 12))
        for day in 25...38 {
            let date = calendar.date(byAdding: .day, value: day - 25, to: la(2026, 10, 25, 12))!
            let current = index(ofDay: date)
            XCTAssertEqual(current, previous + 1, "day \(day - 24) after 24 October")
            previous = current
        }
    }

    /// Daily rollover: with the midnight boundary, every instant of the 23-hour and 25-hour days is that day.
    func testMidnightBoundaryHoldsThroughTheShortAndLongDays() {
        for start in [la(2026, 3, 8), la(2026, 11, 1)] {
            let next = calendar.date(byAdding: .day, value: 1, to: start)!
            let expected = index(ofDay: start)
            var t = start
            while t < next {
                XCTAssertEqual(dayIndex(t, nil), expected, "\(t)")
                t += 15 * 60
            }
            XCTAssertEqual(dayIndex(next, nil), expected + 1)
        }
        // The short day is 23 hours long, the long day 25.
        XCTAssertEqual(DailyRollover.nextRollover(after: la(2026, 3, 8), fajrByDay: nil, calendar: calendar)
                        .timeIntervalSince(la(2026, 3, 8)), 23 * 3600)
        XCTAssertEqual(DailyRollover.nextRollover(after: la(2026, 11, 1), fajrByDay: nil, calendar: calendar)
                        .timeIntervalSince(la(2026, 11, 1)), 25 * 3600)
    }

    /// Daily rollover: on the spring-forward night, before Fajr is still yesterday, after Fajr is today.
    func testFajrBoundaryOnSpringForward() {
        let table = fajrTable
        let saturday = index(ofDay: la(2026, 3, 7, 12))
        XCTAssertEqual(dayIndex(la(2026, 3, 8, 1, 30), table), saturday)           // 01:30 PST
        XCTAssertEqual(dayIndex(la(2026, 3, 8, 3, 30), table), saturday)           // 03:30 PDT, the hour after the jump
        XCTAssertEqual(dayIndex(la(2026, 3, 8, 6, 26), table), saturday)
        XCTAssertEqual(dayIndex(la(2026, 3, 8, 6, 27), table), saturday + 1)       // Fajr itself turns the day
        XCTAssertEqual(dayIndex(la(2026, 3, 8, 23, 59), table), saturday + 1)
        XCTAssertEqual(DailyRollover.nextRollover(after: la(2026, 3, 8, 3, 30), fajrByDay: table, calendar: calendar),
                       la(2026, 3, 8, 6, 27))
        XCTAssertEqual(DailyRollover.nextRollover(after: la(2026, 3, 8, 7), fajrByDay: table, calendar: calendar),
                       la(2026, 3, 9, 6, 26))
    }

    /// Daily rollover: on the fall-back night, both 01:30s come before Fajr and belong to yesterday.
    func testFajrBoundaryOnFallBack() {
        let table = fajrTable
        let saturday = index(ofDay: la(2026, 10, 31, 12))
        let firstOneThirty = la(2026, 11, 1, 0, 30).addingTimeInterval(3600)   // 01:30 PDT
        let secondOneThirty = firstOneThirty.addingTimeInterval(3600)         // 01:30 PST
        XCTAssertEqual(calendar.component(.hour, from: firstOneThirty), 1)
        XCTAssertEqual(calendar.component(.hour, from: secondOneThirty), 1)
        XCTAssertEqual(dayIndex(firstOneThirty, table), saturday)
        XCTAssertEqual(dayIndex(secondOneThirty, table), saturday)
        XCTAssertEqual(dayIndex(la(2026, 11, 1, 5, 2), table), saturday)
        XCTAssertEqual(dayIndex(la(2026, 11, 1, 5, 3), table), saturday + 1)
        XCTAssertEqual(DailyRollover.nextRollover(after: secondOneThirty, fajrByDay: table, calendar: calendar),
                       la(2026, 11, 1, 5, 3))
        XCTAssertEqual(DailyRollover.nextRollover(after: la(2026, 11, 1, 12), fajrByDay: table, calendar: calendar),
                       la(2026, 11, 2, 5, 4))
    }

    /// Daily rollover: the widget path (Fajr table) and the app path (`anchoredDay` with that Fajr) agree all through both nights.
    func testWidgetTableAgreesWithAppAnchor() {
        let table = fajrTable
        for day in [la(2026, 3, 8), la(2026, 11, 1)] {
            let fajr = Date(timeIntervalSince1970: table[Settings.dayKey(day)]!)
            let end = calendar.date(byAdding: .day, value: 1, to: day)!
            var t = day
            while t < end {
                let app = DailyRollover.index(ofDay: DailyRollover.anchoredDay(for: t, fajr: fajr, calendar: calendar), calendar: calendar)
                XCTAssertEqual(dayIndex(t, table), app, "\(t)")
                t += 10 * 60
            }
        }
    }

    /// Daily rollover: a day missing from the table falls back to midnight.
    func testMissingTableDayFallsBackToMidnight() {
        let table = fajrTable
        XCTAssertEqual(dayIndex(la(2026, 3, 10, 1), table), index(ofDay: la(2026, 3, 10, 12)))
        XCTAssertEqual(DailyRollover.nextRollover(after: la(2026, 3, 9, 12), fajrByDay: table, calendar: calendar),
                       la(2026, 3, 10))
    }
}
