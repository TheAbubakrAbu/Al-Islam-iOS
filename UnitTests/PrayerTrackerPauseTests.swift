import XCTest
@testable import iPhone

/// The menstruation pause (Settings.setMensesPause): which days it leaves exempt once it is switched
/// off. A reader's 4.6.5 report: switched on and off on the same day, the pause kept that day exempt,
/// so the Adhan tab read "Tracking paused" until the next day.
final class PrayerTrackerPauseTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// No period is shorter than a day: a pause switched off the day it began was a mistaken tap or a
    /// look, and leaves nothing behind.
    func testAPauseEndedTheDayItBeganLeavesNothing() {
        let days = Settings.pauseDaysToRecord(from: date(2026, 10, 28, 0), endingAt: date(2026, 10, 28, 20), calendar: calendar)
        XCTAssertEqual(days, [])
    }

    /// A pause over several days records each of them, the day it ends included: that day's earlier
    /// prayers fell inside the period.
    func testALongerPauseRecordsEveryDayThroughTheLast() {
        let days = Settings.pauseDaysToRecord(from: date(2026, 10, 22, 0), endingAt: date(2026, 10, 28, 15), calendar: calendar)
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.first, calendar.startOfDay(for: date(2026, 10, 22)))
        XCTAssertEqual(days.last, calendar.startOfDay(for: date(2026, 10, 28)))
    }

    /// Across the night the clocks change, the last day is still reached.
    func testTheLastDayIsReachedAcrossAClockChange() {
        let days = Settings.pauseDaysToRecord(from: date(2026, 10, 30, 0), endingAt: date(2026, 11, 2, 9), calendar: calendar)
        XCTAssertEqual(days.map { calendar.component(.day, from: $0) }, [30, 31, 1, 2])
    }
}
