import XCTest
@testable import iPhone

/// Traveling Mode joins Asr to Dhuhr and Isha to Maghrib, with ONE notification for each pair at the
/// first prayer's time. Turned on between the two, that notification is already behind, so the
/// second prayer keeps its own that one time (Abu, 2026-11-25: someone who does not know the mode
/// "will wait for the next prayer just for it to never come"). Also the first-time explanation:
/// the long turn-on banner and the card's third button.
@MainActor
final class TravelingGapTests: XCTestCase {

    /// Mecca, so every prayer is well inside the day and no high-latitude rule is in play.
    private let mecca = Location(city: "Mecca", latitude: 21.4225, longitude: 39.8262)

    private struct Saved {
        let location: Location?
        let travelAutomatic: Bool
        let travelingMode: Bool
        let onSince: Date?
        let introNotified: Bool
        let explained: Bool
        let turnOnFlag: Bool
        let country: String
        let calculation: String
        /// The stored Automatic calculation switch, as the store holds it (nil: never written).
        let automaticCalculation: Any?
    }
    private static var saved: Saved?

    override func setUp() async throws {
        try await super.setUp()
        let settings = Settings.shared
        if Self.saved == nil {
            Self.saved = Saved(location: settings.currentLocation, travelAutomatic: settings.travelAutomatic,
                               travelingMode: settings.travelingMode, onSince: settings.travelingModeOnSince,
                               introNotified: settings.travelingIntroNotified, explained: settings.travelingModeExplained,
                               turnOnFlag: settings.travelTurnOnAutomatic,
                               country: settings.currentCountryCode, calculation: settings.prayerCalculation,
                               automaticCalculation: UserDefaults.standard.object(forKey: "calculationAutomatic"))
        }
        // Standing in Mecca for the test, a refresh geocodes Mecca, the stored country becomes SA,
        // and with Automatic calculation on the method follows it: the next launch then announced
        // "Calculation Method Updated" in Irvine (met 2026-11-25). Off for the test, written to the
        // store itself (the property's didSet forgets which card was answered); country and method
        // are put back with the rest.
        UserDefaults.standard.set(false, forKey: "calculationAutomatic")
        settings.currentLocation = mecca
        settings.travelAutomatic = false
        settings.travelingMode = false
    }

    override func tearDown() async throws {
        let settings = Settings.shared
        if let saved = Self.saved {
            settings.travelingMode = saved.travelingMode
            settings.travelingModeOnSince = saved.onSince
            settings.travelAutomatic = saved.travelAutomatic
            settings.travelingIntroNotified = saved.introNotified
            settings.travelingModeExplained = saved.explained
            settings.travelTurnOnAutomatic = saved.turnOnFlag
            settings.currentLocation = saved.location
            settings.currentCountryCode = saved.country
            if settings.prayerCalculation != saved.calculation { settings.prayerCalculation = saved.calculation }
            if let automatic = saved.automaticCalculation {
                UserDefaults.standard.set(automatic, forKey: "calculationAutomatic")
            } else {
                UserDefaults.standard.removeObject(forKey: "calculationAutomatic")
            }
        }
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func fullDay() throws -> [Prayer] {
        try XCTUnwrap(Settings.shared.getPrayerTimes(for: Date(), fullPrayers: true))
    }

    private func time(_ names: String..., in day: [Prayer]) throws -> Date {
        try XCTUnwrap(day.first { names.contains($0.nameTransliteration) }, "no \(names) today").time
    }

    // MARK: - Which prayer a turn-on leaves unannounced

    func testBetweenDhuhrAndAsrTheGapIsAsr() throws {
        let day = try fullDay()
        let midday = try time("Dhuhr", "Jumuah", in: day)
        let found = try XCTUnwrap(Settings.travelingGapPrayer(turnedOnAt: midday.addingTimeInterval(60), in: day))
        XCTAssertEqual(found.gap.nameTransliteration, "Asr")
        XCTAssertTrue(["Dhuhr", "Jumuah"].contains(found.first.nameTransliteration))
    }

    func testBetweenMaghribAndIshaTheGapIsIsha() throws {
        let day = try fullDay()
        let maghrib = try time("Maghrib", in: day)
        let found = try XCTUnwrap(Settings.travelingGapPrayer(turnedOnAt: maghrib.addingTimeInterval(60), in: day))
        XCTAssertEqual(found.gap.nameTransliteration, "Isha")
        XCTAssertEqual(found.first.nameTransliteration, "Maghrib")
    }

    /// The very minute the first prayer comes in counts: its own notification is the home list's.
    func testTheFirstPrayersOwnMinuteIsInsideTheGap() throws {
        let day = try fullDay()
        let maghrib = try time("Maghrib", in: day)
        XCTAssertEqual(Settings.travelingGapPrayer(turnedOnAt: maghrib, in: day)?.gap.nameTransliteration, "Isha")
    }

    func testOutsideAPairThereIsNoGap() throws {
        let day = try fullDay()
        let fajr = try time("Fajr", in: day)
        let midday = try time("Dhuhr", "Jumuah", in: day)
        let asr = try time("Asr", in: day)
        let maghrib = try time("Maghrib", in: day)
        let isha = try time("Isha", in: day)
        for (label, stamp) in [
            ("before Fajr", fajr.addingTimeInterval(-600)),
            ("morning", midday.addingTimeInterval(-600)),
            ("at Asr", asr),
            ("after Asr", asr.addingTimeInterval(600)),
            ("just before Maghrib", maghrib.addingTimeInterval(-60)),
            ("at Isha", isha),
            ("after Isha", isha.addingTimeInterval(600)),
        ] {
            XCTAssertNil(Settings.travelingGapPrayer(turnedOnAt: stamp, in: day), label)
        }
    }

    // MARK: - The mode as it stands

    func testTheGapLastsUntilThatPrayerComesAndOnlyWhileTraveling() throws {
        let settings = Settings.shared
        let day = try fullDay()
        let midday = try time("Dhuhr", "Jumuah", in: day)
        let asr = try time("Asr", in: day)
        let stamp = midday.addingTimeInterval(120)

        settings.travelingMode = true
        settings.travelingModeOnSince = stamp
        XCTAssertEqual(settings.travelingGapPrayer(now: stamp.addingTimeInterval(60))?.gap.nameTransliteration, "Asr")
        XCTAssertNil(settings.travelingGapPrayer(now: asr.addingTimeInterval(1)), "once Asr has come there is nothing left to announce")
        XCTAssertNil(settings.travelingGapPrayer(now: stamp.addingTimeInterval(-60)), "a stamp in the future is not trusted")

        settings.travelingMode = false
        XCTAssertNil(settings.travelingModeOnSince, "turning the mode off clears the stamp")
        XCTAssertNil(settings.travelingGapPrayer(now: stamp.addingTimeInterval(60)))
    }

    func testTurningTheModeOnStampsTheMoment() {
        let settings = Settings.shared
        let before = Date()
        settings.travelingMode = true
        let stamp = settings.travelingModeOnSince
        XCTAssertNotNil(stamp)
        XCTAssertGreaterThanOrEqual(stamp ?? .distantPast, before.addingTimeInterval(-1))
        // Set again while on: the stamp is the moment it CAME on, not the last write.
        settings.travelingModeOnSince = before.addingTimeInterval(-3600)
        settings.travelingMode = true
        XCTAssertEqual(settings.travelingModeOnSince?.timeIntervalSince1970 ?? 0,
                       before.addingTimeInterval(-3600).timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - What the turn-on banner says

    func testTheFirstBannerTellsTheWholeStoryAndLaterOnesDoNot() {
        let settings = Settings.shared
        settings.travelingIntroNotified = false
        let first = settings.travelingTurnOnAnnouncement(hereName: "Las Vegas", homeName: "your home city of Irvine")
        XCTAssertTrue(first.hasPrefix("Traveling mode automatically turned on at Las Vegas, away from your home city of Irvine"))
        XCTAssertTrue(first.contains("first opened the app"), first)
        XCTAssertTrue(first.contains("one notification"), first)

        settings.travelingIntroNotified = true
        let later = settings.travelingTurnOnAnnouncement(hereName: "Las Vegas", homeName: "your home city of Irvine")
        XCTAssertEqual(later, "Traveling mode automatically turned on at Las Vegas, away from your home city of Irvine")
    }

    func testABannerInsideAPairSaysTheSecondPrayerStillComes() throws {
        let settings = Settings.shared
        let day = try fullDay()
        let maghrib = try time("Maghrib", in: day)
        settings.travelingIntroNotified = true
        settings.travelingMode = true
        settings.travelingModeOnSince = maghrib.addingTimeInterval(60)

        let body = settings.travelingTurnOnAnnouncement(hereName: "Las Vegas", homeName: "your home",
                                                        now: maghrib.addingTimeInterval(90))
        let lines = body.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2, body)
        XCTAssertTrue(lines[1].hasPrefix("Isha still gets its own notification this time, at "), body)
    }

    // MARK: - The card's third button

    func testOnlyTheFirstTravelingModeOnCardOffersTheExplanation() {
        let settings = Settings.shared
        settings.travelingModeExplained = false
        XCTAssertEqual(settings.autoChangeCard(.travelOn).explainTitle, "How Traveling Mode Works")
        XCTAssertNil(settings.autoChangeCard(.travelOff).explainTitle)

        // Answering the standing card, by either button or by dismissing it, is what retires it.
        settings.travelTurnOnAutomatic = true
        settings.confirmTravelAutomaticChange()
        XCTAssertTrue(settings.travelingModeExplained)
        XCTAssertFalse(settings.travelTurnOnAutomatic)
        XCTAssertNil(settings.autoChangeCard(.travelOn).explainTitle)
    }

    func testAnsweringTheTurnedOffCardDoesNotRetireTheExplanation() {
        let settings = Settings.shared
        settings.travelingModeExplained = false
        settings.travelTurnOnAutomatic = false
        settings.travelTurnOffAutomatic = true
        settings.confirmTravelAutomaticChange()
        XCTAssertFalse(settings.travelingModeExplained)
        XCTAssertFalse(settings.travelTurnOffAutomatic)
    }
}
