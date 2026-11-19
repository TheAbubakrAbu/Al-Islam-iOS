import XCTest
@testable import iPhone

/// The tracker's records beside the marks (prayed in congregation, the Sunnah prayers), the
/// whole-day fill, the make-up list, and the rule that decides when a tap asks "on time or late".
/// These run against the host app's real stores on a day more than a year back, and put every
/// store back byte for byte afterwards.
@MainActor
final class PrayerTrackerExtrasTests: XCTestCase {
    private let mecca = Location(city: "Mecca", latitude: 21.4225, longitude: 39.8262)

    private struct Saved {
        var marks = Data(), exempt = Data(), congregation = Data(), sunnah = Data()
        var location: Location?
        var travelAutomatic = false, travelingMode = false
    }
    private static var saved: Saved?

    /// A Tuesday well inside the five-year retention and far from any live notification.
    private var day: Date {
        let calendar = Calendar.current
        let back = calendar.date(byAdding: .day, value: -400, to: calendar.startOfDay(for: Date()))!
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: back)!
    }

    override func setUp() async throws {
        try await super.setUp()
        let settings = Settings.shared
        if Self.saved == nil {
            Self.saved = Saved(
                marks: settings.prayerTrackerData, exempt: settings.trackerExemptDaysData,
                congregation: settings.trackerCongregationData, sunnah: settings.trackerSunnahData,
                location: settings.currentLocation,
                travelAutomatic: settings.travelAutomatic, travelingMode: settings.travelingMode)
        }
        settings.currentLocation = mecca
        settings.travelAutomatic = false
        settings.travelingMode = false
        settings.setWholeDay(nil, on: day)
        for prayer in SunnahPrayer.allCases { settings.setSunnahPrayed(prayer, on: day, false) }
    }

    override func tearDown() async throws {
        let settings = Settings.shared
        if let saved = Self.saved {
            settings.prayerTrackerData = saved.marks
            settings.trackerExemptDaysData = saved.exempt
            settings.trackerCongregationData = saved.congregation
            settings.trackerSunnahData = saved.sunnah
            Settings.invalidateTrackerCaches()
            settings.travelingMode = saved.travelingMode
            settings.travelAutomatic = saved.travelAutomatic
            settings.currentLocation = saved.location
        }
        try await super.tearDown()
    }

    // MARK: - In congregation

    func testCongregationNeedsAPrayedMarkAndGoesWithIt() {
        let settings = Settings.shared
        // Nothing to describe yet.
        settings.setPrayedInCongregation("Asr", on: day, true)
        XCTAssertFalse(settings.isPrayedInCongregation("Asr", on: day))

        settings.setPrayerMark("Asr", on: day, mark: .onTime)
        settings.setPrayedInCongregation("Asr", on: day, true)
        XCTAssertTrue(settings.isPrayedInCongregation("Asr", on: day))

        // On time to late is still a prayer prayed.
        settings.setPrayerMark("Asr", on: day, mark: .late)
        XCTAssertTrue(settings.isPrayedInCongregation("Asr", on: day))

        // Missed is not, and neither is unmarked.
        settings.setPrayerMark("Asr", on: day, mark: .missed)
        XCTAssertFalse(settings.isPrayedInCongregation("Asr", on: day))
        settings.setPrayerMark("Asr", on: day, mark: .onTime)
        XCTAssertFalse(settings.isPrayedInCongregation("Asr", on: day), "the detail does not come back by itself")
        settings.setPrayedInCongregation("Asr", on: day, true)
        settings.setPrayerMark("Asr", on: day, mark: nil)
        XCTAssertFalse(settings.isPrayedInCongregation("Asr", on: day))
    }

    func testACombinedRowIsInCongregationOnlyWhenBothHalvesAre() {
        let settings = Settings.shared
        settings.setPrayerMark("Dhuhr/Asr", on: day, mark: .onTime)
        settings.setPrayedInCongregation("Dhuhr", on: day, true)
        XCTAssertTrue(settings.isPrayedInCongregation("Dhuhr", on: day))
        XCTAssertTrue(settings.isPrayedInCongregation("Jumuah", on: day), "Jumuah reads the day's Dhuhr")
        XCTAssertFalse(settings.isPrayedInCongregation("Dhuhr/Asr", on: day))
        settings.setPrayedInCongregation("Dhuhr/Asr", on: day, true)
        XCTAssertTrue(settings.isPrayedInCongregation("Dhuhr/Asr", on: day))
        XCTAssertTrue(settings.isPrayedInCongregation("Asr", on: day))
    }

    // MARK: - Sunnah prayers

    func testSunnahPrayersTickAndUntick() {
        let settings = Settings.shared
        XCTAssertEqual(settings.sunnahPrayed(on: day), [])
        settings.setSunnahPrayed(.witr, on: day, true)
        settings.setSunnahPrayed(.fajrBefore, on: day, true)
        XCTAssertEqual(settings.sunnahPrayed(on: day), [.witr, .fajrBefore])
        settings.setSunnahPrayed(.witr, on: day, false)
        XCTAssertEqual(settings.sunnahPrayed(on: day), [.fajrBefore])
        // Never part of the obligatory record.
        XCTAssertNil(settings.prayerMark(for: "Fajr", on: day))
    }

    /// A prayer a later build adds is carried through a save by this one.
    func testUnknownNamesSurviveTheRoundTrip() {
        let record: [String: Set<String>] = ["2026-01-02": ["witr", "somethingLater"], "2026-01-01": ["duha"]]
        let data = Settings.encodeDayNameSets(record)
        XCTAssertEqual(Settings.decodeDayNameSets(data), record)
        XCTAssertEqual(Settings.encodeDayNameSets(Settings.decodeDayNameSets(data)), data, "the same record, the same bytes")
        XCTAssertEqual(Settings.decodeDayNameSets(Data()), [:])
    }

    // MARK: - A whole day

    func testAWholeDayFillKeepsTheAnswersAlreadyGiven() {
        let settings = Settings.shared
        settings.setPrayerMark("Fajr", on: day, mark: .missed)
        settings.setPrayerMark("Asr", on: day, mark: .late)
        settings.setWholeDay(.onTime, on: day)
        XCTAssertEqual(settings.prayerMark(for: "Fajr", on: day), .missed)
        XCTAssertEqual(settings.prayerMark(for: "Asr", on: day), .late)
        for name in ["Dhuhr", "Maghrib", "Isha"] {
            XCTAssertEqual(settings.prayerMark(for: name, on: day), .onTime, name)
        }

        settings.setWholeDay(nil, on: day)
        for name in Settings.canonicalObligatoryPrayers {
            XCTAssertNil(settings.prayerMark(for: name, on: day), name)
        }
    }

    // MARK: - The make-up list

    func testMissedPrayersAreListedNewestFirstInDayOrder() throws {
        let settings = Settings.shared
        let dayBefore = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: day))
        settings.setPrayerMark("Isha", on: day, mark: .missed)
        settings.setPrayerMark("Fajr", on: day, mark: .missed)
        settings.setPrayerMark("Dhuhr", on: day, mark: .late)
        settings.setPrayerMark("Asr", on: dayBefore, mark: .missed)
        defer { settings.setWholeDay(nil, on: dayBefore) }

        let keys = [settings.trackerDayKey(for: day), settings.trackerDayKey(for: dayBefore)]
        let mine = settings.missedPrayers().filter { keys.contains($0.dayKey) }
        XCTAssertEqual(mine.map(\.prayerName), ["Fajr", "Isha", "Asr"])
        XCTAssertEqual(mine.map(\.dayKey), [keys[0], keys[0], keys[1]])

        // Prayed later: off the list, and recorded as prayed late.
        settings.setPrayerMark("Fajr", on: day, mark: .late)
        XCTAssertEqual(settings.missedPrayers().filter { keys.contains($0.dayKey) }.map(\.prayerName), ["Isha", "Asr"])

        // Nothing was owed on an exempt day.
        settings.setTrackerExempt(true, on: day)
        XCTAssertEqual(settings.missedPrayers().filter { keys.contains($0.dayKey) }.map(\.prayerName), ["Asr"])
        settings.setTrackerExempt(false, on: day)
    }

    // MARK: - When a tap asks

    func testEveryPrayerOfAnOlderDayHasEnded() {
        let settings = Settings.shared
        for name in ["Fajr", "Dhuhr", "Jumuah", "Dhuhr/Asr", "Asr", "Maghrib", "Maghrib/Isha", "Isha"] {
            XCTAssertTrue(settings.prayerWindowHasEnded(forSlot: name, on: day), name)
        }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertFalse(settings.prayerWindowHasEnded(forSlot: "Fajr", on: tomorrow))
    }

    func testEachWindowEndsWhereTheNextBegins() throws {
        let settings = Settings.shared
        let today = Date()
        let full = try XCTUnwrap(settings.getPrayerTimes(for: today, fullPrayers: true))
        func time(_ name: String) throws -> Date {
            try XCTUnwrap(full.first { $0.nameTransliteration == name }?.time, "no \(name) today")
        }
        XCTAssertEqual(settings.prayerWindowEnd(forSlot: "Fajr", on: today), try time("Shurooq"))
        XCTAssertEqual(settings.prayerWindowEnd(forSlot: "Dhuhr", on: today), try time("Asr"))
        XCTAssertEqual(settings.prayerWindowEnd(forSlot: "Jumuah", on: today), try time("Asr"))
        XCTAssertEqual(settings.prayerWindowEnd(forSlot: "Asr", on: today), try time("Maghrib"))
        XCTAssertEqual(settings.prayerWindowEnd(forSlot: "Dhuhr/Asr", on: today), try time("Maghrib"))
        XCTAssertEqual(settings.prayerWindowEnd(forSlot: "Maghrib", on: today), try time("Isha"))

        // Isha runs to the middle of the night: after Isha begins, before the next Fajr.
        let ishaEnd = try XCTUnwrap(settings.prayerWindowEnd(forSlot: "Isha", on: today))
        XCTAssertEqual(settings.prayerWindowEnd(forSlot: "Maghrib/Isha", on: today), ishaEnd)
        XCTAssertGreaterThan(ishaEnd, try time("Isha"))
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))
        let nextFajr = try XCTUnwrap(settings.getPrayerTimes(for: tomorrow, fullPrayers: true)?
            .first { $0.nameTransliteration == "Fajr" }?.time)
        XCTAssertLessThan(ishaEnd, nextFajr)

        // The moment before a window ends it is still open, the moment it ends it is over.
        let asr = try time("Asr")
        XCTAssertFalse(settings.prayerWindowHasEnded(forSlot: "Dhuhr", on: today, at: asr.addingTimeInterval(-1)))
        XCTAssertTrue(settings.prayerWindowHasEnded(forSlot: "Dhuhr", on: today, at: asr))
        XCTAssertNil(settings.prayerWindowEnd(forSlot: "Shurooq", on: today), "not a prayer the tracker records")
    }

    // MARK: - iCloud merge

    #if HAS_ICLOUD_BACKUP
    func testAMergeUnitesBothSidesDayByDay() throws {
        let ours: [String: Set<String>] = ["2026-01-01": ["Fajr"], "2026-01-02": ["Asr"]]
        let theirs: [String: Set<String>] = ["2026-01-01": ["Fajr", "Isha"], "2026-01-03": ["Dhuhr"]]
        for key in ["prayerTrackerCongregationData", "prayerTrackerSunnahData"] {
            let merged = CloudMergeRules.merged(local: [key: Settings.encodeDayNameSets(ours)],
                                                incoming: [key: Settings.encodeDayNameSets(theirs)])
            let data = try XCTUnwrap(merged[key] as? Data, key)
            XCTAssertEqual(Settings.decodeDayNameSets(data),
                           ["2026-01-01": ["Fajr", "Isha"], "2026-01-02": ["Asr"], "2026-01-03": ["Dhuhr"]], key)
        }
        // Nothing new on the other side: this device's bytes are left alone.
        let same = CloudMergeRules.merged(local: ["prayerTrackerSunnahData": Settings.encodeDayNameSets(ours)],
                                          incoming: ["prayerTrackerSunnahData": Settings.encodeDayNameSets(["2026-01-02": ["Asr"]])])
        XCTAssertNil(same["prayerTrackerSunnahData"])
    }
    #endif
}
