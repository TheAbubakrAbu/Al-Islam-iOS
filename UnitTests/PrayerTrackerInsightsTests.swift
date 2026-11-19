import XCTest
@testable import iPhone

/// The numbers behind the Prayer Tracker's INSIGHTS section (PrayerTrackerInsights.swift), the card's
/// headline and the streak milestones: all pure functions of the stored records.
final class PrayerTrackerInsightsTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Wednesday.
    private var today: Date { formatter.date(from: "2026-11-18")! }

    private func key(daysAgo: Int) -> String {
        formatter.string(from: calendar.date(byAdding: .day, value: -daysAgo, to: today)!)
    }

    private func all(_ mark: PrayerMark) -> [String: PrayerMark] {
        Dictionary(uniqueKeysWithValues: Settings.canonicalObligatoryPrayers.map { ($0, mark) })
    }

    private func insights(
        _ range: TrackerRange,
        marks: [String: [String: PrayerMark]],
        exempt: Set<String> = [],
        pauseStart: String? = nil,
        congregation: [String: Set<String>] = [:],
        sunnah: [String: Set<String>] = [:],
        earliest: String? = nil
    ) -> PrayerTrackerInsights {
        PrayerTrackerInsights.compute(
            range: range, marks: marks, exemptDays: exempt, activePauseStartKey: pauseStart,
            congregation: congregation, sunnah: sunnah,
            earliestKey: earliest ?? marks.keys.min(),
            today: today, calendar: calendar,
            dayKey: { self.formatter.string(from: $0) }
        )
    }

    private func line(_ result: PrayerTrackerInsights, _ name: String) -> PrayerTrackerInsights.PrayerLine {
        result.prayers.first { $0.name == name }!
    }

    // MARK: - Counting

    func testNothingTrackedIsAllZeros() {
        let result = insights(.month, marks: [:])
        XCTAssertEqual(result.countedDays, 0)
        XCTAssertEqual(result.due, 0)
        XCTAssertFalse(result.hasMarks)
        XCTAssertNil(result.previousOnTimeShare)
        XCTAssertNil(result.strongest)
        XCTAssertNil(result.weakest)
    }

    func testEachPrayerIsCountedByItsMark() {
        var two = all(.onTime)
        two["Fajr"] = .late
        var one = all(.onTime)
        one["Fajr"] = .missed
        one["Isha"] = nil
        let result = insights(.week, marks: [key(daysAgo: 2): two, key(daysAgo: 1): one])

        // Two days ago, yesterday, and today (which has no marks and so adds no prayers).
        XCTAssertEqual(result.countedDays, 3)
        XCTAssertEqual(line(result, "Fajr").late, 1)
        XCTAssertEqual(line(result, "Fajr").missed, 1)
        XCTAssertEqual(line(result, "Fajr").onTime, 0)
        XCTAssertEqual(line(result, "Dhuhr").onTime, 2)
        XCTAssertEqual(line(result, "Isha").onTime, 1)
        XCTAssertEqual(line(result, "Isha").unmarked, 1)
        XCTAssertEqual(result.onTime, 7)
        XCTAssertEqual(result.due, 10)
        XCTAssertEqual(result.perfectDays, 0)
        XCTAssertEqual(result.completeDays, 1)
    }

    /// Today is not over: its unanswered prayers are not unanswered yet.
    func testTodaysUnmarkedPrayersAreNotCounted() {
        let result = insights(.week, marks: [key(daysAgo: 0): ["Fajr": .onTime, "Dhuhr": .late]])
        XCTAssertEqual(result.due, 2)
        XCTAssertEqual(result.unmarked, 0)
        XCTAssertEqual(result.onTime, 1)
        XCTAssertEqual(result.countedDays, 1)
    }

    /// The days before the first tracked day are not days the reader failed to pray.
    func testDaysBeforeTrackingBeganAreLeftOut() {
        let result = insights(.month, marks: [key(daysAgo: 3): all(.onTime)])
        // Three days ago, then two unanswered days, then today.
        XCTAssertEqual(result.countedDays, 4)
        XCTAssertEqual(result.onTime, 5)
        XCTAssertEqual(result.unmarked, 10)
    }

    func testExemptDaysAndThePauseAreNeutral() {
        let marks = [key(daysAgo: 6): all(.onTime), key(daysAgo: 4): all(.missed)]
        let result = insights(.week, marks: marks, exempt: [key(daysAgo: 4), key(daysAgo: 5)], pauseStart: key(daysAgo: 1))
        // Six days ago counts, five and four are exempt, three and two count, yesterday and today are paused.
        XCTAssertEqual(result.countedDays, 3)
        XCTAssertEqual(result.exemptDays, 4)
        XCTAssertEqual(result.missed, 0)
        XCTAssertEqual(result.onTime, 5)
        XCTAssertEqual(result.unmarked, 10)
    }

    /// A day recorded while traveling or on a Friday is read through the same coverage as everywhere.
    func testCombinedAndJumuahRecordsCoverTheirPrayers() {
        let stored: [String: PrayerMark] = ["Fajr": .onTime, "Jumuah": .onTime, "Asr": .late, "Maghrib/Isha": .late]
        let result = insights(.week, marks: [key(daysAgo: 1): stored])
        XCTAssertEqual(line(result, "Dhuhr").onTime, 1)
        XCTAssertEqual(line(result, "Maghrib").late, 1)
        XCTAssertEqual(line(result, "Isha").late, 1)
        XCTAssertEqual(result.completeDays, 1)
    }

    // MARK: - The span before

    func testTheSpanBeforeIsComparedDayForDay() {
        var marks: [String: [String: PrayerMark]] = [:]
        // This week: all on time. The week before: all late.
        for back in 0..<7 { marks[key(daysAgo: back)] = all(.onTime) }
        for back in 7..<14 { marks[key(daysAgo: back)] = all(.late) }
        let result = insights(.week, marks: marks)
        XCTAssertEqual(result.onTimeShare, 1)
        XCTAssertEqual(result.previousOnTimeShare, 0)
        XCTAssertEqual(result.changeInPoints, 100)
    }

    func testNoSpanBeforeMeansNoComparison() {
        let marks = [key(daysAgo: 2): all(.onTime)]
        XCTAssertNil(insights(.week, marks: marks).previousOnTimeShare)
        XCTAssertNil(insights(.week, marks: marks).changeInPoints)
        // The whole history has nothing before it, however long it is.
        var long: [String: [String: PrayerMark]] = [:]
        for back in 0..<60 { long[key(daysAgo: back)] = all(.onTime) }
        XCTAssertNil(insights(.all, marks: long).previousOnTimeShare)
        XCTAssertEqual(insights(.all, marks: long).countedDays, 60)
    }

    // MARK: - Strongest and weakest

    func testLevelPrayersNameNoStrongestOrWeakest() {
        var marks: [String: [String: PrayerMark]] = [:]
        for back in 1..<6 { marks[key(daysAgo: back)] = all(.onTime) }
        let result = insights(.week, marks: marks)
        XCTAssertNil(result.strongest)
        XCTAssertNil(result.weakest)
    }

    func testTheWeakestIsTheOneLeastOftenOnTime() {
        var marks: [String: [String: PrayerMark]] = [:]
        for back in 1..<6 {
            var day = all(.onTime)
            if back <= 3 { day["Fajr"] = .late }
            if back == 1 { day["Asr"] = .late }
            marks[key(daysAgo: back)] = day
        }
        let result = insights(.week, marks: marks)
        XCTAssertEqual(result.weakest?.name, "Fajr")
        XCTAssertNotEqual(result.strongest?.name, "Fajr")
        XCTAssertEqual(result.strongest?.onTimeShare, 1)
    }

    /// Level at the bottom: the one missed outranks the one that was only late.
    func testBetweenTwoLevelPrayersTheMissedOneIsWeaker() {
        var day = all(.onTime)
        day["Dhuhr"] = .late
        day["Isha"] = .missed
        let result = insights(.week, marks: [key(daysAgo: 1): day])
        XCTAssertEqual(result.weakest?.name, "Isha")
    }

    // MARK: - Weekdays

    func testAWeekdayIsNamedOnlyWithEnoughWeeks() {
        var marks: [String: [String: PrayerMark]] = [:]
        // Four weeks, every Monday's Fajr late. 2026-11-16 is a Monday (two days ago).
        for back in 1..<29 {
            var day = all(.onTime)
            let date = calendar.date(byAdding: .day, value: -back, to: today)!
            if calendar.component(.weekday, from: date) == 2 { day["Fajr"] = .late }
            marks[key(daysAgo: back)] = day
        }
        XCTAssertEqual(insights(.month, marks: marks).weakestWeekday?.weekday, 2)
        // Seven days hold one of each weekday: nothing to judge a pattern by.
        XCTAssertNil(insights(.week, marks: marks).weakestWeekday)
    }

    // MARK: - Congregation and Sunnah

    func testCongregationCountsOnlyPrayedPrayers() {
        var day = all(.onTime)
        day["Asr"] = .missed
        let dayKey = key(daysAgo: 1)
        let result = insights(.week, marks: [dayKey: day], congregation: [dayKey: ["Fajr", "Asr", "Isha"]])
        XCTAssertEqual(result.congregation, 2)
        XCTAssertEqual(line(result, "Asr").congregation, 0)
        XCTAssertEqual(line(result, "Fajr").congregation, 1)
    }

    func testSunnahDaysAndTheFullTwelve() {
        let full = Set(SunnahPrayer.rawatib.map(\.rawValue))
        let marks = [key(daysAgo: 2): all(.onTime), key(daysAgo: 1): all(.onTime)]
        let sunnah: [String: Set<String>] = [
            key(daysAgo: 2): full.union(["witr"]),
            key(daysAgo: 1): ["fajrBefore", "witr", "somethingLater"],
        ]
        let result = insights(.week, marks: marks, sunnah: sunnah)
        XCTAssertEqual(result.sunnah[.witr], 2)
        XCTAssertEqual(result.sunnah[.fajrBefore], 2)
        XCTAssertEqual(result.sunnah[.dhuhrBefore], 1)
        XCTAssertNil(result.sunnah[.duha])
        XCTAssertEqual(result.fullRawatibDays, 1)
        XCTAssertEqual(SunnahPrayer.regularRakatTotal, 12)
    }

    // MARK: - The card's headline

    func testHeadlineSaysWhatIsWaiting() {
        let now = today.addingTimeInterval(13 * 3600)
        func slot(_ name: String, hour: Double, _ mark: PrayerMark?) -> (name: String, time: Date, mark: PrayerMark?) {
            (name, today.addingTimeInterval(hour * 3600), mark)
        }
        // Fajr answered, Dhuhr begun and waiting, the rest still to come.
        let waiting = [slot("Fajr", hour: 5, .onTime), slot("Dhuhr", hour: 12, nil), slot("Asr", hour: 15, nil)]
        XCTAssertEqual(TrackerDayHeadline.make(slots: waiting, isToday: true, now: now), .waiting(name: "Dhuhr", count: 1))

        let upToDate = [slot("Fajr", hour: 5, .onTime), slot("Dhuhr", hour: 12, .late), slot("Asr", hour: 15, nil)]
        XCTAssertEqual(TrackerDayHeadline.make(slots: upToDate, isToday: true, now: now),
                       .upToDate(next: "Asr", time: today.addingTimeInterval(15 * 3600)))

        // A day that is not today has every slot begun, whatever the clock says.
        XCTAssertEqual(TrackerDayHeadline.make(slots: waiting, isToday: false, now: now), .waiting(name: "Dhuhr", count: 2))

        let perfect = [slot("Fajr", hour: 5, .onTime), slot("Dhuhr", hour: 12, .onTime)]
        XCTAssertEqual(TrackerDayHeadline.make(slots: perfect, isToday: true, now: now), .perfect)
        let complete = [slot("Fajr", hour: 5, .late), slot("Dhuhr", hour: 12, .onTime)]
        XCTAssertEqual(TrackerDayHeadline.make(slots: complete, isToday: true, now: now), .complete)
        // A missed prayer keeps the day from complete, and nothing is left to mark.
        let settled = [slot("Fajr", hour: 5, .missed), slot("Dhuhr", hour: 12, .onTime)]
        XCTAssertEqual(TrackerDayHeadline.make(slots: settled, isToday: true, now: now), .settled)
        XCTAssertEqual(TrackerDayHeadline.make(slots: [], isToday: true, now: now), .empty)
    }

    // MARK: - Milestones

    func testStreakMilestonesFollowTheAchievements() {
        XCTAssertEqual(PrayerTrackerStats.streakMilestone(after: 0).to, 3)
        XCTAssertEqual(PrayerTrackerStats.streakMilestone(after: 3).from, 3)
        XCTAssertEqual(PrayerTrackerStats.streakMilestone(after: 3).to, 7)
        XCTAssertEqual(PrayerTrackerStats.streakMilestone(after: 14).to, 30)
        XCTAssertEqual(PrayerTrackerStats.streakMilestone(after: 364).to, 365)
        // Past the last achievement, every further hundred.
        XCTAssertEqual(PrayerTrackerStats.streakMilestone(after: 365).from, 365)
        XCTAssertEqual(PrayerTrackerStats.streakMilestone(after: 365).to, 400)
        XCTAssertEqual(PrayerTrackerStats.streakMilestone(after: 450).from, 400)
        XCTAssertEqual(PrayerTrackerStats.streakMilestone(after: 450).to, 500)
    }
}
