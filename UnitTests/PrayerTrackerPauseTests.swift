import XCTest
@testable import iPhone

/// The menstruation pause (Settings.setMensesPause): what it leaves behind once it is switched off.
/// Two reports shaped it. A reader on 4.6.5: switched on and off on the same day, the pause kept
/// that day exempt, so the Adhan tab read "Tracking paused" until the next day. Abu, 2026-11-18: a
/// pause begun on an earlier day left the day it ended exempt too, so the five prayers stayed hidden
/// behind "Today is exempt" with the switch already off ("if I turn it off, the tracking does not
/// come back").
final class PrayerTrackerPauseTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    // MARK: - What the end of a pause records

    /// No period is shorter than a day: a pause switched off the day it began was a mistaken tap or a
    /// look, and leaves nothing behind.
    func testAPauseEndedTheDayItBeganLeavesNothing() {
        let end = Settings.pauseEnd(from: date(2026, 10, 28, 0), openDay: date(2026, 10, 28, 20), calendar: calendar)
        XCTAssertEqual(end.exempt, [])
        XCTAssertNil(end.resumeDay)
    }

    /// A pause over several days leaves each of them exempt EXCEPT the day it ends on: that day is
    /// tracked again at once, and recorded as the day tracking resumed.
    func testALongerPauseLeavesTheDayItEndsTracked() {
        let end = Settings.pauseEnd(from: date(2026, 10, 22, 0), openDay: date(2026, 10, 28, 15), calendar: calendar)
        XCTAssertEqual(end.exempt.count, 6)
        XCTAssertEqual(end.exempt.first, calendar.startOfDay(for: date(2026, 10, 22)))
        XCTAssertEqual(end.exempt.last, calendar.startOfDay(for: date(2026, 10, 27)))
        XCTAssertEqual(end.resumeDay, calendar.startOfDay(for: date(2026, 10, 28)))
    }

    /// Ended after midnight and before Fajr, the day being tracked is still yesterday: that is the
    /// day that comes back, and the days before it are the exempt ones.
    func testEndedBeforeFajrTheOpenDayIsYesterday() {
        // 01:00 on the 28th; the card is still on the 27th.
        let end = Settings.pauseEnd(from: date(2026, 10, 22, 0), openDay: date(2026, 10, 27, 12), calendar: calendar)
        XCTAssertEqual(end.exempt.last, calendar.startOfDay(for: date(2026, 10, 26)))
        XCTAssertEqual(end.resumeDay, calendar.startOfDay(for: date(2026, 10, 27)))
    }

    /// Switched on after midnight and off again before Fajr: the pause began on a day later than the
    /// one being tracked, and leaves nothing.
    func testAPauseThatBeganAfterTheOpenDayLeavesNothing() {
        let end = Settings.pauseEnd(from: date(2026, 10, 28, 0), openDay: date(2026, 10, 27, 12), calendar: calendar)
        XCTAssertEqual(end.exempt, [])
        XCTAssertNil(end.resumeDay)
    }

    /// Across the night the clocks change, every day is still reached, each at its own start.
    func testEveryDayIsReachedAcrossAClockChange() {
        let end = Settings.pauseEnd(from: date(2026, 10, 30, 0), openDay: date(2026, 11, 2, 9), calendar: calendar)
        XCTAssertEqual(end.exempt.map { calendar.component(.day, from: $0) }, [30, 31, 1])
        XCTAssertEqual(end.exempt.map { calendar.component(.hour, from: $0) }, [0, 0, 0])
        XCTAssertEqual(end.resumeDay, calendar.startOfDay(for: date(2026, 11, 2)))
    }

    // MARK: - The streak across the day a pause ended

    /// The stats engine keys days with its own formatter, in the device's zone, so these walks do too.
    private let deviceCalendar = Calendar.current
    private var today: Date { deviceCalendar.startOfDay(for: Date()) }

    private func key(daysAgo: Int) -> String {
        PrayerTrackerStats.dayKeyFormatter.string(from: deviceCalendar.date(byAdding: .day, value: -daysAgo, to: today)!)
    }

    private func marks(_ prayed: Int) -> [String: PrayerMark] {
        Dictionary(uniqueKeysWithValues: Settings.canonicalObligatoryPrayers.suffix(prayed).map { ($0, PrayerMark.onTime) })
    }

    private func stats(_ marks: [String: [String: PrayerMark]], exempt: Set<String>, resumed: Set<String>) -> PrayerTrackerStats {
        PrayerTrackerStats.compute(marks: marks, exemptDays: exempt, activePauseStartKey: nil, resumeDays: resumed,
                                   earliestKey: marks.keys.min(), today: Date(), calendar: deviceCalendar)
    }

    /// Three complete days, a five-day pause, then the day it ended with only its last three prayers
    /// (the first two fell inside the period), then two complete days.
    private var afterAPause: (marks: [String: [String: PrayerMark]], exempt: Set<String>) {
        var record: [String: [String: PrayerMark]] = [:]
        for daysAgo in [10, 9, 8, 1, 0] { record[key(daysAgo: daysAgo)] = marks(5) }
        record[key(daysAgo: 2)] = marks(3)
        return (record, Set((3...7).map(key(daysAgo:))))
    }

    /// The day a pause ended does not end the streak it carried across the pause.
    func testTheDayAPauseEndedDoesNotEndTheStreak() {
        let record = afterAPause
        let result = stats(record.marks, exempt: record.exempt, resumed: [key(daysAgo: 2)])
        XCTAssertEqual(result.currentStreak, 5, "three days before the pause, two after, the resume day neutral")
        XCTAssertEqual(result.bestStreak, 5)
        XCTAssertEqual(result.completeDays, 5)
        XCTAssertEqual(result.totalPrayed, 28, "its three prayers are counted")
    }

    /// Without the record of where the pause ended, that same incomplete day does end it: the rule
    /// is the resume day's, not a looser streak.
    func testAnOrdinaryIncompleteDayStillEndsTheStreak() {
        let record = afterAPause
        let result = stats(record.marks, exempt: record.exempt, resumed: [])
        XCTAssertEqual(result.currentStreak, 2)
        XCTAssertEqual(result.bestStreak, 3)
    }

    /// Prayed in full, the day a pause ended is a complete day like any other.
    func testACompleteResumeDayCounts() {
        var record = afterAPause
        record.marks[key(daysAgo: 2)] = marks(5)
        let result = stats(record.marks, exempt: record.exempt, resumed: [key(daysAgo: 2)])
        XCTAssertEqual(result.currentStreak, 6)
        XCTAssertEqual(result.perfectDays, 6)
    }

    // MARK: - Insights

    /// A prayer left unanswered on the day a pause ended is not counted as due: it may have fallen
    /// inside the period.
    func testInsightsDoNotCountTheResumeDaysUnansweredPrayers() {
        let record = afterAPause
        func insights(resumed: Set<String>) -> PrayerTrackerInsights {
            PrayerTrackerInsights.compute(
                range: .month, marks: record.marks, exemptDays: record.exempt, activePauseStartKey: nil,
                resumeDays: resumed, earliestKey: record.marks.keys.min(), today: Date(), calendar: deviceCalendar,
                dayKey: { PrayerTrackerStats.dayKeyFormatter.string(from: $0) }
            )
        }
        let lenient = insights(resumed: [key(daysAgo: 2)])
        XCTAssertEqual(lenient.unmarked, 0)
        XCTAssertEqual(lenient.due, 28)
        XCTAssertEqual(lenient.onTimeShare, 1)

        let strict = insights(resumed: [])
        XCTAssertEqual(strict.unmarked, 2)
        XCTAssertEqual(strict.due, 30)
    }

    // MARK: - The card's line on the day a pause ended

    private func slot(_ name: String, hour: Double, _ mark: PrayerMark?) -> (name: String, time: Date, mark: PrayerMark?) {
        (name, today.addingTimeInterval(hour * 3600), mark)
    }

    private func day(_ fajr: PrayerMark?, _ dhuhr: PrayerMark?, _ asr: PrayerMark?, _ maghrib: PrayerMark?, _ isha: PrayerMark?)
        -> [(name: String, time: Date, mark: PrayerMark?)] {
        [slot("Fajr", hour: 5, fajr), slot("Dhuhr", hour: 12, dhuhr), slot("Asr", hour: 15, asr),
         slot("Maghrib", hour: 18, maghrib), slot("Isha", hour: 19.5, isha)]
    }

    /// The pause ended in the afternoon. Fajr and Dhuhr are over and unanswered: the line asks only
    /// for the prayer whose time it is, where an ordinary day would ask for all three.
    func testTheLineAsksOnlyForThePrayerWhoseTimeItIs() {
        let now = today.addingTimeInterval(16 * 3600)
        let slots = day(nil, nil, nil, nil, nil)
        XCTAssertEqual(TrackerDayHeadline.make(slots: slots, isToday: true, now: now), .waiting(name: "Fajr", count: 3))
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: slots, isToday: true, now: now), .waiting(name: "Asr", count: 1))

        let asrPrayed = day(nil, nil, .onTime, nil, nil)
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: asrPrayed, isToday: true, now: now),
                       .upToDate(next: "Maghrib", time: today.addingTimeInterval(18 * 3600)))
    }

    /// The app knows when a prayer's time ends (Fajr at sunrise, not when Dhuhr begins) and says so
    /// through `ended`: at ten in the morning Fajr is over, though no later prayer has begun.
    func testTheLineTakesTheAppsWordForWhenATimeIsOver() {
        let now = today.addingTimeInterval(10 * 3600)
        let slots = day(nil, nil, nil, nil, nil)
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: slots, isToday: true, now: now), .waiting(name: "Fajr", count: 1))
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: slots, isToday: true, now: now) { $0 == 0 },
                       .upToDate(next: "Dhuhr", time: today.addingTimeInterval(12 * 3600)))
    }

    /// Everything still asked for is prayed, but not all five were: the day is done, not "complete",
    /// which the ring beside the line would contradict. The line says the rest is not counted.
    func testAPartDayIsResumedNotComplete() {
        let night = today.addingTimeInterval(22 * 3600)
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: day(nil, nil, .onTime, .onTime, .onTime), isToday: true, now: night), .resumed)
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: day(nil, nil, .missed, .onTime, .onTime), isToday: true, now: night), .resumed)
        XCTAssertEqual(TrackerDayHeadline.resumed.line(), "Tracking resumed. Unmarked prayers on this day are not counted.")
        // All five prayed is still all five prayed.
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: day(.onTime, .onTime, .onTime, .onTime, .onTime), isToday: true, now: night), .perfect)
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: day(.late, .onTime, .onTime, .onTime, .onTime), isToday: true, now: night), .complete)
    }

    /// Looked back on from a later day, nothing of it is waiting.
    func testALaterDayAsksNothingOfIt() {
        let now = today.addingTimeInterval(16 * 3600)
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: day(nil, nil, nil, nil, nil), isToday: false, now: now), .resumed)
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: day(nil, nil, .onTime, nil, nil), isToday: false, now: now), .resumed)
        XCTAssertEqual(TrackerDayHeadline.makeResumed(slots: [], isToday: true, now: now), .empty)
    }
}
