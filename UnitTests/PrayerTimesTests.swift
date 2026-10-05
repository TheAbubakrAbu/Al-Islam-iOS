import XCTest
import Adhan
@testable import iPhone

/// The prayer-time engine and the method catalog in front of it (Quality Guide, Phase 8).
///
/// The catalog carries each method as plain angles, so everything else a publishing body adds to
/// the astronomical instant (Diyanet's precaution minutes, the minute after the transit, MUIS
/// rounding up) has to be carried by hand too. It was not, from 4.6.0 until 2026-10-04, and no
/// test noticed: these pin the catalog to the engine's own table, and the engine to an independent
/// solar-position solver.
final class PrayerTimesTests: XCTestCase {

    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Every 13th day of 2026: all seasons, both equinoxes within a week.
    private var sampleDays: [DateComponents] {
        let start = utc.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        return stride(from: 0, to: 365, by: 13).map {
            utc.dateComponents([.year, .month, .day], from: utc.date(byAdding: .day, value: $0, to: start)!)
        }
    }

    private func times(_ parameters: CalculationParameters, at place: Coordinates, on day: DateComponents,
                       file: StaticString = #filePath, line: UInt = #line) -> [Date] {
        var parameters = parameters
        parameters.madhab = .shafi
        parameters.highLatitudeRule = .middleOfTheNight
        guard let t = PrayerTimes(coordinates: place, date: day, calculationParameters: parameters) else {
            XCTFail("no times on \(day)", file: file, line: line)
            return []
        }
        return [t.fajr, t.sunrise, t.dhuhr, t.asr, t.maghrib, t.isha]
    }

    /// Method catalog: a row gives the same six times as the engine's own definition of that method.
    func testCatalogRowsMatchTheEnginesMethodTable() throws {
        let pairs: [(id: String, engine: CalculationMethod, place: Coordinates)] = [
            ("Muslim World League", .muslimWorldLeague, Coordinates(latitude: 52.52, longitude: 13.405)),
            ("Islamic Society of North America (ISNA)", .northAmerica, Coordinates(latitude: 40.7128, longitude: -74.006)),
            ("Egypt", .egyptian, Coordinates(latitude: 30.0444, longitude: 31.2357)),
            ("Karachi", .karachi, Coordinates(latitude: 24.8607, longitude: 67.0011)),
            ("UAE (General Authority of Islamic Affairs)", .dubai, Coordinates(latitude: 25.2048, longitude: 55.2708)),
            ("Turkey (Diyanet)", .turkey, Coordinates(latitude: 41.0082, longitude: 28.9784)),
            ("Singapore (MUIS)", .singapore, Coordinates(latitude: 1.3521, longitude: 103.8198)),
            ("Kuwait", .kuwait, Coordinates(latitude: 29.3759, longitude: 47.9774)),
            ("Qatar", .qatar, Coordinates(latitude: 25.2854, longitude: 51.531)),
            ("Saudi Arabia (Umm Al-Qura)", .ummAlQura, Coordinates(latitude: 21.4225, longitude: 39.8262)),
            ("Britain (Moonsighting Committee)", .moonsightingCommittee, Coordinates(latitude: 51.5074, longitude: -0.1278)),
        ]
        for pair in pairs {
            let row = try XCTUnwrap(PrayerCalculationCatalog.method(id: pair.id), pair.id)
            // A row leaves the rounding to the app (each time to its safe side) unless its body
            // publishes one, so the engine's table is compared on the row's own rounding.
            var engine = pair.engine.params
            engine.rounding = row.rounding ?? Rounding.none
            XCTAssertEqual(row.parameters.rounding, row.rounding ?? Rounding.none, pair.id)
            for day in sampleDays {
                XCTAssertEqual(times(row.parameters, at: pair.place, on: day),
                               times(engine, at: pair.place, on: day),
                               "\(pair.id) on \(day.year!)-\(day.month!)-\(day.day!)")
            }
        }
        XCTAssertEqual(PrayerCalculationCatalog.method(id: "Singapore (MUIS)")?.rounding, .up)
    }

    /// Method catalog: Malaysia's Subuh is 18 degrees since 2019; Brunei kept 20 and has its own row.
    func testMalaysiaAndBruneiRows() throws {
        let malaysia = try XCTUnwrap(PrayerCalculationCatalog.method(id: "Malaysia (JAKIM)"))
        XCTAssertEqual(malaysia.fajrAngle, 18)
        XCTAssertEqual(malaysia.isha, .angle(18))
        let brunei = try XCTUnwrap(PrayerCalculationCatalog.method(id: "Brunei (Ministry of Religious Affairs)"))
        XCTAssertEqual(brunei.fajrAngle, 20)
        XCTAssertEqual(brunei.isha, .angle(18))
        XCTAssertEqual(PrayerCalculationCatalog.byCountry["MY"], malaysia.id)
        XCTAssertEqual(PrayerCalculationCatalog.byCountry["BN"], brunei.id)
    }

    /// Rounding: a start never shows before the instant, an end never after it, and suhoor always
    /// ends before dawn.
    func testTimesRoundToTheirSafeSide() {
        let base = utc.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 21, minute: 50))!
        for second in [0, 1, 29, 30, 31, 59] {
            let instant = base.addingTimeInterval(TimeInterval(second))
            let start = PrayerMinute.rounded(instant, endsATime: false)
            let end = PrayerMinute.rounded(instant, endsATime: true)
            XCTAssertEqual(utc.component(.second, from: start), 0)
            XCTAssertEqual(utc.component(.second, from: end), 0)
            XCTAssertGreaterThanOrEqual(start, instant, "start at :\(second)")
            XCTAssertLessThan(start.timeIntervalSince(instant), 60)
            XCTAssertLessThanOrEqual(end, instant, "end at :\(second)")
            XCTAssertLessThan(instant.timeIntervalSince(end), 60)
            XCTAssertLessThan(PrayerMinute.suhoorEnd(forFajr: start), instant, "suhoor at :\(second)")
        }
        // 05:50:34 in Kuala Lumpur shows as 05:51, never 05:50.
        let dawn = base.addingTimeInterval(34)
        XCTAssertEqual(PrayerMinute.rounded(dawn, endsATime: false), base.addingTimeInterval(60))
    }

    /// High latitudes: Automatic clamps past the latitude where the method's own angle stops being
    /// reached in summer (66 minus the angle), in either hemisphere. 48 for every 18 degree method,
    /// as Adhan's own recommendation has it.
    func testAutomaticRuleFollowsTheMethodsAngle() throws {
        func rule(_ id: String, _ latitude: Double) throws -> HighLatitudeRule {
            let row = try XCTUnwrap(PrayerCalculationCatalog.method(id: id), id)
            return Settings.highLatitudeRuleUnderAutomatic(latitude: latitude, parameters: row.parameters)
        }
        XCTAssertEqual(try rule("France (Musulmans de France)", 48.8566), .middleOfTheNight)    // Paris, 12
        XCTAssertEqual(try rule("Muslim World League", 48.8566), .seventhOfTheNight)            // Paris, 18
        XCTAssertEqual(try rule("Muslim World League", 47.9), .middleOfTheNight)
        XCTAssertEqual(try rule("Muslim World League", -54.8019), .seventhOfTheNight)           // Ushuaia
        XCTAssertEqual(try rule("Islamic Society of North America (ISNA)", 51.0447), .seventhOfTheNight) // Calgary, 15
        XCTAssertEqual(try rule("Islamic Society of North America (ISNA)", 43.6532), .middleOfTheNight)  // Toronto
        XCTAssertEqual(try rule("Russia (Spiritual Administration)", 55.7558), .seventhOfTheNight) // Moscow, 16
        XCTAssertEqual(try rule("France (Musulmans de France)", 55), .seventhOfTheNight)
        // Umm al-Qura's Isha is an interval: only its 18.5 degree Fajr counts.
        XCTAssertEqual(try rule("Saudi Arabia (Umm Al-Qura)", 47.4), .middleOfTheNight)
        XCTAssertEqual(try rule("Saudi Arabia (Umm Al-Qura)", 47.6), .seventhOfTheNight)
    }

    /// High latitudes: in Paris under Musulmans de France the sun reaches 12 degrees every night, so
    /// Fajr is the method's own dawn, not Seventh of the Night's 36 minutes later. Reference: an
    /// independent solver, 21 June 2026, 12 degrees before sunrise at 02:03:30 UTC.
    func testParisKeepsItsTwelveDegreeDawnInJune() throws {
        var parameters = try XCTUnwrap(PrayerCalculationCatalog.method(id: "France (Musulmans de France)")).parameters
        let latitude = 48.8566
        parameters.highLatitudeRule = Settings.highLatitudeRuleUnderAutomatic(latitude: latitude, parameters: parameters)
        let day = DateComponents(year: 2026, month: 6, day: 21)
        let t = try XCTUnwrap(PrayerTimes(coordinates: Coordinates(latitude: latitude, longitude: 2.3522),
                                          date: day, calculationParameters: parameters))
        XCTAssertEqual(t.fajr.timeIntervalSince1970, 1_782_007_410, accuracy: 30)
    }

    /// Method catalog: Diyanet's Maghrib is seven minutes after sunset, its sunrise seven before.
    func testDiyanetKeepsItsPrecautionMinutes() throws {
        let row = try XCTUnwrap(PrayerCalculationCatalog.method(id: "Turkey (Diyanet)"))
        var bare = row.parameters
        bare.adjustments = PrayerAdjustments()
        let istanbul = Coordinates(latitude: 41.0082, longitude: 28.9784)
        let day = DateComponents(year: 2026, month: 10, day: 4)
        let listed = times(row.parameters, at: istanbul, on: day)
        let plain = times(bare, at: istanbul, on: day)
        XCTAssertEqual(listed[1].timeIntervalSince(plain[1]), -7 * 60)   // sunrise
        XCTAssertEqual(listed[2].timeIntervalSince(plain[2]), 5 * 60)    // Dhuhr
        XCTAssertEqual(listed[3].timeIntervalSince(plain[3]), 4 * 60)    // Asr
        XCTAssertEqual(listed[4].timeIntervalSince(plain[4]), 7 * 60)    // Maghrib
    }

    /// Method catalog: Jordan is 18 and 18 with Maghrib five minutes after sunset.
    func testJordanRow() throws {
        let row = try XCTUnwrap(PrayerCalculationCatalog.method(id: "Jordan (Ministry of Awqaf)"))
        XCTAssertEqual(row.fajrAngle, 18)
        XCTAssertEqual(row.isha, .angle(18))
        var bare = row.parameters
        bare.adjustments = PrayerAdjustments()
        let amman = Coordinates(latitude: 31.9539, longitude: 35.9106)
        let day = DateComponents(year: 2026, month: 10, day: 4)
        XCTAssertEqual(times(row.parameters, at: amman, on: day)[4]
            .timeIntervalSince(times(bare, at: amman, on: day)[4]), 5 * 60)
    }

    /// Engine: Asr lands within five seconds of an independent solver (the sun's position at the
    /// instant itself, crossings by bisection). The engine took the noon shadow from the 0h UT
    /// declination and corrected the crossing once; these days were 24 to 60 seconds out.
    func testAsrMatchesAnIndependentSolarReference() {
        let cases: [(city: String, place: Coordinates, day: DateComponents, shafi: Double, hanafi: Double)] = [
            ("San Francisco", Coordinates(latitude: 37.7749, longitude: -122.4194), DateComponents(year: 2026, month: 9, day: 23), 1_790_206_051.2, 1_790_209_153.9),
            ("San Francisco", Coordinates(latitude: 37.7749, longitude: -122.4194), DateComponents(year: 2027, month: 3, day: 20), 1_805_586_223.8, 1_805_589_341.9),
            ("New York", Coordinates(latitude: 40.7128, longitude: -74.006), DateComponents(year: 2027, month: 3, day: 20), 1_805_574_538.6, 1_805_577_619.4),
            ("Makkah", Coordinates(latitude: 21.4225, longitude: 39.8262), DateComponents(year: 2027, month: 3, day: 20), 1_805_547_184.3, 1_805_550_615.3),
            ("Jakarta", Coordinates(latitude: -6.2088, longitude: 106.8456), DateComponents(year: 2026, month: 9, day: 23), 1_790_150_134.1, 1_790_154_174.9),
        ]
        var parameters = CalculationMethod.other.params
        parameters.fajrAngle = 18
        parameters.ishaAngle = 17
        parameters.rounding = .none
        for item in cases {
            for (madhab, reference) in [(Madhab.shafi, item.shafi), (Madhab.hanafi, item.hanafi)] {
                parameters.madhab = madhab
                guard let t = PrayerTimes(coordinates: item.place, date: item.day, calculationParameters: parameters) else {
                    XCTFail("no times in \(item.city)")
                    continue
                }
                XCTAssertEqual(t.asr.timeIntervalSince1970, reference, accuracy: 5,
                               "\(madhab) Asr in \(item.city), \(item.day.month!)/\(item.day.day!)")
            }
        }
    }

    /// Polar edge: beside polar night the solar math answers with Asr out of order (Tromso,
    /// 9 January 2026: Asr two days early). Those days take the nearest latitude's times.
    func testADayOutOfOrderTakesTheNearestLatitude() throws {
        let (latitude, longitude) = (69.6492, 18.9553)
        let tromso = Coordinates(latitude: latitude, longitude: longitude)
        var parameters = try XCTUnwrap(PrayerCalculationCatalog.method(id: "Muslim World League")).parameters
        parameters.highLatitudeRule = .seventhOfTheNight

        var standIns = 0
        let start = utc.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        for offset in 0..<365 {
            let day = utc.dateComponents([.year, .month, .day], from: utc.date(byAdding: .day, value: offset, to: start)!)
            let own = PrayerTimes(coordinates: tromso, date: day, calculationParameters: parameters)
            let resolved = Settings.resolvedPrayerTimes(latitude: latitude, longitude: longitude, date: day, parameters: parameters)
            let shown = try XCTUnwrap(resolved, "no times on \(day.month!)/\(day.day!)")
            XCTAssertTrue(Settings.isChronological(shown), "out of order on \(day.month!)/\(day.day!)")
            if let own, Settings.isChronological(own) {
                XCTAssertEqual(shown.asr, own.asr, "a usable day keeps its own times")
            } else {
                standIns += 1
            }
        }
        // Polar day and night (no answer at all) plus the weeks beside polar night (a wrong one).
        XCTAssertGreaterThan(standIns, 100)
        XCTAssertLessThan(standIns, 200)
    }

    /// High latitudes: the Automatic rule reads the distance from the equator, in either hemisphere.
    func testAutomaticHighLatitudeRuleCoversTheSouth() {
        XCTAssertEqual(HighLatitudeRule.recommended(for: Coordinates(latitude: -54.8019, longitude: -68.303)), .seventhOfTheNight)
        XCTAssertEqual(HighLatitudeRule.recommended(for: Coordinates(latitude: 59.3293, longitude: 18.0686)), .seventhOfTheNight)
        XCTAssertEqual(HighLatitudeRule.recommended(for: Coordinates(latitude: -33.8688, longitude: 151.2093)), .middleOfTheNight)
        XCTAssertEqual(HighLatitudeRule.recommended(for: Coordinates(latitude: 21.4225, longitude: 39.8262)), .middleOfTheNight)
    }

    /// Islamic dates: a night is reminded on the civil day whose evening begins it (the 27th night
    /// opens at Maghrib on the 26th), a day on its own day, and both in the Gregorian calendar
    /// whatever the device's is.
    func testNightEventsAreRemindedTheDayTheyBegin() throws {
        let settings = Settings.shared
        let gregorian = Calendar(identifier: .gregorian)
        let year = settings.hijriCalendar.component(.year, from: Date()) + 1
        let events = Settings.specialEvents(inHijriYear: year)

        func civilDay(of event: (String, DateComponents, String, String)) throws -> Date {
            let hijri = try XCTUnwrap(settings.hijriCalendar.date(from: event.1))
            let corrected = settings.hijriCalendar.date(byAdding: .day, value: -settings.hijriOffset, to: hijri) ?? hijri
            return gregorian.startOfDay(for: corrected)
        }

        for event in events {
            let built = try XCTUnwrap(settings.makeEventNotificationRequest(for: event), event.0)
            let headsUp = try XCTUnwrap(settings.makeEventNotificationRequest(for: event, dayBefore: true), event.0)
            let day = try civilDay(of: event)
            let isNight = Settings.nightEventTitles.contains(event.0)
            let anchor = isNight ? gregorian.date(byAdding: .day, value: -1, to: day)! : day
            XCTAssertTrue(gregorian.isDate(built.date, inSameDayAs: anchor), "\(event.0) fires \(built.date)")
            XCTAssertTrue(gregorian.isDate(headsUp.date, inSameDayAs: gregorian.date(byAdding: .day, value: -1, to: anchor)!),
                          "\(event.0) heads-up fires \(headsUp.date)")
            XCTAssertEqual(built.spec.trigger.calendar?.identifier, .gregorian)
            XCTAssertEqual(built.spec.body.hasPrefix("Tonight at Maghrib: "), isNight, built.spec.body)
            XCTAssertEqual(headsUp.spec.body.hasPrefix("Tomorrow night: "), isNight, headsUp.spec.body)
        }
        XCTAssertEqual(events.filter { Settings.nightEventTitles.contains($0.0) }.count, 2)
    }
}
