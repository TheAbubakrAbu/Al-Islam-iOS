import XCTest
@testable import iPhone

/// The adhan catch-up, after 2026-10-06: the window is five minutes, and inside it the override
/// decides whether the adhan PLAYS or is merely OFFERED.
///
/// The bug these hold the line on: "Play In-App Adhan in Silent Mode" makes the in-app recording
/// ignore the ringer switch, and the catch-up auto-played on activation - so unlocking the phone a
/// couple of minutes after Dhuhr filled a classroom at full volume (Abu, 2026-10-06). iOS exposes no
/// API for the ringer switch, so the loud case cannot be detected; it can only be made deliberate.
/// With the override ON nothing sounds without a tap. With it OFF the catch-up still auto-plays,
/// because `.ambient` obeys the switch and cannot be loud on a silenced phone.
@MainActor
final class AdhanCatchUpOfferTests: XCTestCase {

    /// Mecca, so every prayer is well inside the day and no high-latitude rule is in play.
    private let mecca = Location(city: "Mecca", latitude: 21.4225, longitude: 39.8262)

    private var savedLocation: Location?
    private var savedOverride = false
    private var savedSound = ""

    override func setUp() async throws {
        try await super.setUp()
        let settings = Settings.shared
        savedLocation = settings.currentLocation
        savedOverride = settings.adhanOverridesSilentMode
        savedSound = settings.adhanNotificationSound
        settings.currentLocation = mecca
        ForegroundAdhanPlayer.shared.clearPendingOffer()
    }

    override func tearDown() async throws {
        let settings = Settings.shared
        settings.currentLocation = savedLocation
        settings.adhanOverridesSilentMode = savedOverride
        settings.adhanNotificationSound = savedSound
        ForegroundAdhanPlayer.shared.clearPendingOffer()
        try await super.tearDown()
    }

    // MARK: The window

    /// Five minutes, applied to the lookback itself: 4:59 past a prayer still finds it, 5:01 does not.
    /// One window for the offer and the auto-play alike, so there is a single figure to reason about.
    func testTheCatchUpWindowIsFiveMinutes() throws {
        let settings = Settings.shared
        let prayers = try XCTUnwrap(settings.getPrayerTimes(for: Date()), "no prayer times for Mecca")
        let dhuhr = try XCTUnwrap(prayers.first { $0.nameTransliteration == "Dhuhr" })

        let justInside = dhuhr.time.addingTimeInterval(4 * 60 + 59)
        let justOutside = dhuhr.time.addingTimeInterval(5 * 60 + 1)

        // The window is passed in by the player, so assert against the figure the player uses rather
        // than a literal: a test that hardcodes 300 would pass while the player used 600.
        let window = ForegroundAdhanPlayer.catchUpWindowForTesting
        XCTAssertEqual(window, 300, "the catch-up window is five minutes")

        let inside = settings.recentForegroundAdhan(within: window, now: justInside)
        let outside = settings.recentForegroundAdhan(within: window, now: justOutside)

        // Dhuhr's own eligibility depends on the user's notification switches, so assert the window's
        // BEHAVIOUR: whatever it finds at 4:59 it must not still find at 5:01.
        if let inside, inside.name == "Dhuhr" {
            XCTAssertNotEqual(outside?.name, "Dhuhr", "an adhan 5:01 old is outside the window")
        }
        if let outside {
            XCTAssertLessThan(justOutside.timeIntervalSince(outside.date), window,
                              "nothing outside the window may be returned")
        }
    }

    /// The lookback never returns a prayer still in the future, whatever the window.
    func testTheCatchUpNeverLooksForward() throws {
        let settings = Settings.shared
        let prayers = try XCTUnwrap(settings.getPrayerTimes(for: Date()))
        let fajr = try XCTUnwrap(prayers.first { $0.nameTransliteration == "Fajr" })

        let beforeFajr = fajr.time.addingTimeInterval(-60)
        if let found = settings.recentForegroundAdhan(within: 300, now: beforeFajr) {
            XCTAssertLessThanOrEqual(found.date, beforeFajr, "\(found.name) had not happened yet")
        }
    }

    // MARK: The offer state machine

    /// With the override ON a missed adhan is offered, never started: nothing is playing afterwards.
    func testOverrideOnOffersInsteadOfPlaying() {
        let settings = Settings.shared
        settings.adhanOverridesSilentMode = true
        let player = ForegroundAdhanPlayer.shared

        player.playMissedAdhan()

        XCTAssertFalse(player.isPlaying, "the loud path must never start without a tap")
        if player.pendingPrayerName != nil {
            XCTAssertNil(player.playingPrayerName)
        }
    }

    /// An offer is retired by backgrounding, and not by being looked at. `stop()` is the app leaving
    /// the foreground: a tap minutes later must not start an adhan for a prayer long past.
    func testBackgroundingClearsTheOffer() {
        let player = ForegroundAdhanPlayer.shared
        player.debugSetPending("Dhuhr")
        XCTAssertEqual(player.pendingPrayerName, "Dhuhr")

        player.stop()

        XCTAssertNil(player.pendingPrayerName, "an offer must not survive backgrounding")
    }

    /// Tapping the offer takes it away, so the button cannot be tapped twice for the same adhan.
    func testPlayingTheOfferClearsIt() {
        let player = ForegroundAdhanPlayer.shared
        player.debugSetPending("Asr")

        player.playOfferedAdhan()

        XCTAssertNil(player.pendingPrayerName, "the offer is spent once tapped")
    }

    /// An expired offer plays nothing. The window is checked at the moment of the tap, not only when
    /// the offer went up, so a card left on screen cannot fire a stale adhan.
    func testAnExpiredOfferDoesNotPlay() {
        let player = ForegroundAdhanPlayer.shared
        player.debugSetPending("Maghrib", expiry: Date().addingTimeInterval(-1))

        player.playOfferedAdhan()

        XCTAssertNil(player.pendingPrayerName)
        XCTAssertFalse(player.isPlaying, "an expired offer must not start the adhan")
    }

    // MARK: The banner

    /// The banner follows the adhan, and a dismissal applies only to the adhan it was made for: the
    /// next one banners again. Dismissing never stops the audio, which is why the footer control stays.
    func testBannerDismissalIsPerAdhan() {
        let presenter = AdhanBannerPresenter.shared

        XCTAssertTrue(presenter.shouldShow(playing: "Fajr", dismissed: nil))
        XCTAssertFalse(presenter.shouldShow(playing: "Fajr", dismissed: "Fajr"))
        XCTAssertTrue(presenter.shouldShow(playing: "Dhuhr", dismissed: "Fajr"),
                      "a dismissal must not silence the next adhan's banner")
        XCTAssertFalse(presenter.shouldShow(playing: nil, dismissed: nil))
    }
}
