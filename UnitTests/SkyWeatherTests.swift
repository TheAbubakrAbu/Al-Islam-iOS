import XCTest
@testable import iPhone

/// The sky's weather (SkyWeather.swift, 2026-10-11): the look a condition maps to, how it greys a
/// prayer's gradient, when a reading is fresh, and what a widget redraws for. Plus the two other
/// pure pieces that landed with it: the automatic-change cards' copy and the permissions sheet's
/// rule for when it stands in front of the system prompts.
final class SkyWeatherTests: XCTestCase {
    private func reading(condition: String, cover: Double, fetchedAt: Date = Date(), latitude: Double = 33.7,
                         longitude: Double = -117.8, tempC: Double = 20) -> SkyWeather {
        SkyWeather(fetchedAt: fetchedAt, latitude: latitude, longitude: longitude,
                   temperatureC: tempC, apparentC: tempC, highC: nil, lowC: nil, humidity: 0.5, dewPointC: 10,
                   uvIndex: 3, uvCategory: "Moderate", cloudCover: cover, condition: condition,
                   conditionText: condition, symbolName: "cloud", windKph: 10, windDirection: "N",
                   visibilityKm: 10, pressureHPa: 1013, pressureTrend: "Steady", precipitationChance: nil,
                   precipitationMm: 0, isDaylight: true)
    }

    // MARK: The look

    func testClearSkyIsClear() {
        XCTAssertTrue(SkyWeatherLook(condition: "clear", cloudCover: 0.02).isClear)
        XCTAssertTrue(SkyWeatherLook(condition: "mostlyClear", cloudCover: 0.0).isClear)
        XCTAssertFalse(SkyWeatherLook(condition: "cloudy", cloudCover: 0.9).isClear)
        XCTAssertFalse(SkyWeatherLook(condition: "foggy", cloudCover: 0.0).isClear, "fog veils a cloudless sky")
    }

    func testConditionsMapToPrecipitationAndStorms() {
        XCTAssertEqual(SkyWeatherLook(condition: "rain", cloudCover: 0.5).precipitation, .rain(0.6))
        XCTAssertEqual(SkyWeatherLook(condition: "heavySnow", cloudCover: 0.5).precipitation, .snow(1.0))
        let storm = SkyWeatherLook(condition: "thunderstorms", cloudCover: 0.3)
        XCTAssertTrue(storm.storm)
        XCTAssertGreaterThanOrEqual(storm.overcast, 0.95, "a storm is overcast whatever the cover says")
        XCTAssertEqual(SkyWeatherLook(condition: "foggy", cloudCover: 0.1).fog, 1.0)
        XCTAssertEqual(SkyWeatherLook(condition: "haze", cloudCover: 0.1).fog, 0.5)
    }

    func testRainIsOvercastEvenWithLittleCover() {
        let drizzle = SkyWeatherLook(condition: "drizzle", cloudCover: 0.2)
        XCTAssertGreaterThanOrEqual(drizzle.overcast, 0.6)
    }

    func testStarsHideBehindClouds() {
        XCTAssertEqual(SkyWeatherLook(condition: "clear", cloudCover: 0).starFactor, 1)
        XCTAssertEqual(SkyWeatherLook(condition: "cloudy", cloudCover: 1).starFactor, 0)
        XCTAssertEqual(SkyWeatherLook(condition: "partlyCloudy", cloudCover: 0.5).starFactor, 0.5, accuracy: 0.001)
    }

    // MARK: The tint

    func testClearLookLeavesTheGradientAlone() {
        let blue = SkyRGB(hex: "2B7FC4")!
        XCTAssertEqual(SkyWeatherTint.tint(blue, look: .clear), blue)
    }

    func testOvercastGreysADaySkyAndDarkensANightSky() {
        let overcast = SkyWeatherLook(condition: "cloudy", cloudCover: 1.0)
        let dhuhr = SkyRGB(hex: "2B7FC4")!
        let tintedDay = SkyWeatherTint.tint(dhuhr, look: overcast)
        // Toward grey: the blue's channels close up on each other.
        XCTAssertLessThan(abs(tintedDay.blue - tintedDay.red), abs(dhuhr.blue - dhuhr.red))
        XCTAssertNotEqual(tintedDay, dhuhr)
        // Never flattened: still bluer than it is red.
        XCTAssertGreaterThan(tintedDay.blue, tintedDay.red)

        let isha = SkyRGB(hex: "0C1330")!
        let tintedNight = SkyWeatherTint.tint(isha, look: overcast)
        XCTAssertLessThan(tintedNight.luminance, 0.2, "a night sky greys toward charcoal, never toward silver")
    }

    func testFogVeilsLighter() {
        let fog = SkyWeatherLook(condition: "foggy", cloudCover: 0.2)
        let dhuhr = SkyRGB(hex: "2B7FC4")!
        let cloudyOnly = SkyWeatherTint.tint(dhuhr, look: SkyWeatherLook(overcast: fog.overcast, fog: 0,
                                                                          cloudCover: 0.2, precipitation: .none, storm: false))
        let foggy = SkyWeatherTint.tint(dhuhr, look: fog)
        XCTAssertGreaterThan(foggy.luminance, cloudyOnly.luminance)
    }

    func testTintedColorsKeepStopCount() {
        let colors = SkyWeatherTint.colors(hexes: ["C2582C", "4B2B63"], look: SkyWeatherLook(condition: "rain", cloudCover: 0.9))
        XCTAssertEqual(colors.count, 2)
    }

    // MARK: Freshness and place

    func testFreshnessWindows() {
        let now = Date()
        XCTAssertTrue(reading(condition: "clear", cover: 0, fetchedAt: now).isFresh(at: now))
        XCTAssertFalse(reading(condition: "clear", cover: 0, fetchedAt: now.addingTimeInterval(-4 * 3600)).isFresh(at: now))
        XCTAssertFalse(reading(condition: "clear", cover: 0, fetchedAt: now.addingTimeInterval(-10 * 60)).needsRefresh(at: now))
        XCTAssertTrue(reading(condition: "clear", cover: 0, fetchedAt: now.addingTimeInterval(-31 * 60)).needsRefresh(at: now))
    }

    func testAReadingDescribesItsOwnPlaceButNotTheNextCity() {
        let here = reading(condition: "clear", cover: 0)
        XCTAssertTrue(here.describes(latitude: 33.71, longitude: -117.79))
        XCTAssertFalse(here.describes(latitude: 34.05, longitude: -118.24), "Los Angeles is 60 km away")
    }

    func testCacheRoundTrip() {
        let suite = UserDefaults(suiteName: "SkyWeatherTests.\(UUID().uuidString)")!
        let now = Date()
        let original = reading(condition: "partlyCloudy", cover: 0.4, fetchedAt: now)
        suite.set(try! JSONEncoder().encode(original), forKey: SkyWeather.storageKey)
        let back = SkyWeather.freshCached(in: suite, at: now)
        XCTAssertEqual(back?.condition, "partlyCloudy")
        XCTAssertEqual(back?.cloudCover ?? 0, 0.4, accuracy: 0.0001)
        XCTAssertNil(SkyWeather.freshCached(in: suite, at: now.addingTimeInterval(5 * 3600)), "stale readings are not served")
    }

    // MARK: The widgets

    func testWidgetSignatureIgnoresSmallChanges() {
        let a = reading(condition: "partlyCloudy", cover: 0.41)
        let b = reading(condition: "partlyCloudy", cover: 0.44)
        XCTAssertEqual(a.widgetSignature, b.widgetSignature)
        let c = reading(condition: "partlyCloudy", cover: 0.41, tempC: 27)
        XCTAssertNotEqual(a.widgetSignature, c.widgetSignature, "a different temperature redraws")
    }

    // MARK: The automatic-change cards

    func testTravelCardsAreShortAndNameTheOutcomes() {
        let on = Settings.AutoChangeCard.travel(turnOn: true, homeCity: "Irvine")
        XCTAssertEqual(on.title, "Traveling Mode On")
        XCTAssertTrue(on.message.contains("Irvine"))
        XCTAssertEqual(on.confirmTitle, "Keep On")
        XCTAssertEqual(on.overrideTitle, "Turn Off")
        XCTAssertLessThan(on.message.count, 90)

        let off = Settings.AutoChangeCard.travel(turnOn: false, homeCity: nil)
        XCTAssertEqual(off.title, "Traveling Mode Off")
        XCTAssertEqual(off.confirmTitle, "OK")
        XCTAssertEqual(off.overrideTitle, "Keep On")
    }

    func testCalculationCardNamesTheCountry() {
        let card = Settings.AutoChangeCard.calculation(previous: "Muslim World League", detected: "Umm al-Qura", regionCode: "SA")
        XCTAssertEqual(card.title, "Calculation Method Updated")
        XCTAssertTrue(card.message.contains("Umm al-Qura"))
        XCTAssertFalse(card.message.contains(" SA"), "the raw region code never shows")
        XCTAssertEqual(card.confirmTitle, "Use Umm al-Qura")
        XCTAssertEqual(card.overrideTitle, "Keep Muslim World League")
        let unknown = Settings.AutoChangeCard.calculation(previous: "A", detected: "B", regionCode: "")
        XCTAssertTrue(unknown.message.contains("this region"))
    }

    // MARK: The permissions sheet

    func testPermissionsSheetStandsOnlyForAnUnansweredUnsnoozedPermission() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        func due(location: Bool = false, notifications: Bool = false, locationSnoozedUntil: Double = 0,
                 notificationSnoozedUntil: Double = 0, locationNever: Bool = false, notificationNever: Bool = false) -> Bool {
            PermissionsSheet.shouldPresent(locationUndetermined: location, notificationsUndetermined: notifications,
                                           locationSnoozedUntil: locationSnoozedUntil, notificationSnoozedUntil: notificationSnoozedUntil,
                                           locationNeverAskAgain: locationNever, notificationNeverAskAgain: notificationNever, now: now)
        }
        XCTAssertFalse(due(), "both answered")
        XCTAssertTrue(due(location: true))
        XCTAssertTrue(due(notifications: true))
        XCTAssertFalse(due(location: true, locationSnoozedUntil: now.timeIntervalSince1970 + 60), "Not Now holds for a day")
        XCTAssertTrue(due(location: true, locationSnoozedUntil: now.timeIntervalSince1970 - 60), "and then it returns")
        XCTAssertFalse(due(location: true, locationNever: true))
        XCTAssertTrue(due(location: true, notifications: true, locationNever: true), "the other permission still asks")
    }
}
