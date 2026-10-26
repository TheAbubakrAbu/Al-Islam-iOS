import XCTest
@testable import iPhone

/// The Islamic-date banner on the Adhan tab (`IslamicEventLookup`): which of the app's dates leads
/// on a given day, and how its timing reads. Dates are placed exactly as the Hijri calendar screen
/// places them (Umm al-Qura, moved back by the reader's Hijri adjustment), so every expectation is
/// built from the same calendar rather than from a remembered civil date.
final class IslamicEventBannerTests: XCTestCase {

    private let zone = TimeZone(identifier: "America/Los_Angeles")!

    private var civil: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }

    private var hijri: Calendar {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        calendar.timeZone = zone
        return calendar
    }

    /// Noon on the civil day of a Hijri date, moved by `days`.
    private func noon(_ year: Int, _ month: Int, _ day: Int, plus days: Int = 0) -> Date {
        let date = hijri.date(from: DateComponents(year: year, month: month, day: day))!
        let moved = civil.date(byAdding: .day, value: days, to: date)!
        return civil.date(bySettingHour: 12, minute: 0, second: 0, of: moved)!
    }

    private func lookup(_ now: Date, offset: Int = 0) -> IslamicEventOccurrence? {
        IslamicEventLookup.current(now: now, hijriCalendar: hijri, hijriOffset: offset, calendar: civil)
    }

    private var daysInRamadan1447: Int {
        hijri.range(of: .day, in: .month, for: hijri.date(from: DateComponents(year: 1447, month: 9, day: 1))!)!.count
    }

    // MARK: One-day events

    func testEidAlFitrOnItsDayIsToday() {
        let found = lookup(noon(1447, 10, 1))
        XCTAssertEqual(found?.title, "Eid Al-Fitr")
        XCTAssertEqual(found?.timing, .today)
    }

    func testEidAlFitrTheDayBeforeIsTomorrow() {
        // The last night of Ramadan is still one of the last ten, but Eid tomorrow leads.
        let found = lookup(noon(1447, 10, 1, plus: -1))
        XCTAssertEqual(found?.title, "Eid Al-Fitr")
        XCTAssertEqual(found?.timing, .tomorrow)
    }

    func testDayOfArafahBeatsTheTenDaysAroundIt() {
        let found = lookup(noon(1447, 12, 9))
        XCTAssertEqual(found?.title, "Day of Arafah")
        XCTAssertEqual(found?.timing, .today)
    }

    func testTheLastDayOfEidIsItsOwnDate() {
        let found = lookup(noon(1447, 12, 13))
        XCTAssertEqual(found?.title, "End of Eid Al-Adha")
        XCTAssertEqual(found?.timing, .today)
    }

    // MARK: Spans

    func testRamadanUnderWayCountsItsDays() {
        let found = lookup(noon(1447, 9, 5))
        XCTAssertEqual(found?.title, "Ramadan")
        XCTAssertEqual(found?.timing, .ongoing(day: 5, count: daysInRamadan1447, nights: false))
    }

    func testRamadansFirstDayIsTodayNotDayOne() {
        let found = lookup(noon(1447, 9, 1))
        XCTAssertEqual(found?.title, "First Day of Ramadan")
        XCTAssertEqual(found?.timing, .today)
    }

    func testTheLastTenNightsBeginTomorrowNightOnTheNineteenth() {
        // The 21st night begins at Maghrib on the 20th; on the 19th that is tomorrow night, which
        // leads over Ramadan's own count.
        let found = lookup(noon(1447, 9, 19))
        XCTAssertEqual(found?.title, "Last 10 Nights of Ramadan")
        XCTAssertEqual(found?.timing, .tomorrowNight)
    }

    func testTheLastTenNightsCountTheirNights() {
        // Civil day of the 22nd: the second night opens at its Maghrib.
        let found = lookup(noon(1447, 9, 22))
        XCTAssertEqual(found?.title, "Last 10 Nights of Ramadan")
        XCTAssertEqual(found?.timing, .ongoing(day: 3, count: daysInRamadan1447 - 20, nights: true))
    }

    func testTheTwentySeventhNightIsTonightOnTheTwentySixth() {
        let found = lookup(noon(1447, 9, 26))
        XCTAssertEqual(found?.title, "27th Night of Ramadan")
        XCTAssertEqual(found?.timing, .tonight)
    }

    func testEidAlAdhaCountsItsFourDays() {
        let second = lookup(noon(1447, 12, 11))
        XCTAssertEqual(second?.title, "Eid Al-Adha")
        XCTAssertEqual(second?.timing, .ongoing(day: 2, count: 4, nights: false))

        let first = lookup(noon(1447, 12, 10))
        XCTAssertEqual(first?.title, "Eid Al-Adha")
        XCTAssertEqual(first?.timing, .ongoing(day: 1, count: 4, nights: false),
                       "Eid's first day beats the tenth of the ten days")
    }

    // MARK: The horizon

    func testAWeekAheadIsShownAndEightDaysIsNot() {
        // Late Dhul-Hijjah: everything has passed, the new year is ahead.
        let week = lookup(noon(1448, 1, 1, plus: -7))
        XCTAssertEqual(week?.title, "Islamic New Year")
        XCTAssertEqual(week?.timing, .inDays(7))
        XCTAssertNil(lookup(noon(1448, 1, 1, plus: -8)))
    }

    func testTheHijriAdjustmentMovesTheCivilDay() {
        // With the reader's date one day ahead, the stored Hijri date falls one civil day earlier.
        let found = lookup(noon(1447, 10, 1, plus: -1), offset: 1)
        XCTAssertEqual(found?.title, "Eid Al-Fitr")
        XCTAssertEqual(found?.timing, .today)
    }

    func testTheHijriYearBoundaryIsCrossedFromEitherSide() {
        // The day before the new year is Dhul-Hijjah 29 or 30 of the OLD year: the lookup must still
        // find Islamic New Year tomorrow, from the old year's reading of today.
        let found = lookup(noon(1448, 1, 1, plus: -1))
        XCTAssertEqual(found?.title, "Islamic New Year")
        XCTAssertEqual(found?.timing, .tomorrow)
    }

    func testTitlesAndGlyphsAreNamedForEveryListedEvent() {
        for event in Settings.specialEvents(inHijriYear: 1447) {
            XCTAssertFalse(IslamicEventLookup.displayTitle(for: event.0).isEmpty, event.0)
            XCTAssertFalse(IslamicEventLookup.symbolName(for: event.0).isEmpty, event.0)
        }
        XCTAssertEqual(IslamicEventLookup.symbolName(for: "Ramadan"), "moon.stars.fill")
    }
}
