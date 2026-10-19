import XCTest
@testable import iPhone

/// The in-app adhan's one decision, after 2026-10-19: look at Silent Mode. Audible, the adhan PLAYS;
/// silenced, it is OFFERED as a Play button, unless "Play In-App Adhan in Silent Mode" treats the phone
/// as audible. "Play Automatically" off always offers. A tap on the offer always sounds, through Silent
/// Mode. And the moment is spent only by a recording that actually begins.
///
/// The bug these hold the line on: with the override off the adhan used to start on `.ambient` without
/// looking, so a silenced phone ran a three-minute recording inaudibly under an ADHAN PLAYING banner,
/// and because that muted start spent the moment, the Play button (after flipping the override on)
/// found nothing left to play (Abu, 2026-10-19).
///
/// The switch is faked (`SilentSwitch.debugOverride`) and the missed prayer is injected
/// (`ForegroundAdhanPlayer.debugMissedAdhan`), so every test runs at any time of day against a phone
/// in the state it names. The real probe is exercised once, for shape only: the simulator has no switch.
@MainActor
final class AdhanCatchUpOfferTests: XCTestCase {

    /// Mecca, so every prayer is well inside the day and no high-latitude rule is in play.
    private let mecca = Location(city: "Mecca", latitude: 21.4225, longitude: 39.8262)

    /// The real settings these tests move, saved ONCE for the whole class rather than per test.
    ///
    /// Captured per test, the save/restore was a leak rather than a guard: a test that writes
    /// `adhanOverridesSilentMode = true` leaves it true, so the NEXT `setUp` saves `true` as the
    /// "original" and no `tearDown` ever puts it back. Class-level storage restores the values the
    /// device actually had (2026-10-08).
    private static var savedLocation: Location?
    private static var savedOverride = false
    private static var savedAutoPlay = true
    private static var savedSound = ""
    private static var savedTravelAutomatic = false
    private static var savedTravelingMode = false
    private static var savedMoment: String?
    private static var saved = false

    private static let momentKey = "foregroundAdhanLastPlayedMoment"

    override func setUp() async throws {
        try await super.setUp()
        let settings = Settings.shared
        if !Self.saved {
            Self.savedLocation = settings.currentLocation
            Self.savedOverride = settings.adhanOverridesSilentMode
            Self.savedAutoPlay = settings.adhanAutoPlayInApp
            Self.savedSound = settings.adhanNotificationSound
            Self.savedTravelAutomatic = settings.travelAutomatic
            Self.savedTravelingMode = settings.travelingMode
            Self.savedMoment = UserDefaults.standard.string(forKey: Self.momentKey)
            Self.saved = true
        }
        settings.currentLocation = mecca
        // Mecca is a long way from whatever home this device has, and `travelAutomatic` defaults to
        // true - so setting the location above was enough to flip traveling mode on, and traveling
        // mode condenses the day to "Fajr, Shurooq, Dhuhr/Asr, Maghrib/Isha". A lookup for "Dhuhr"
        // then found nothing while "Fajr" still resolved, which is exactly how
        // `testTheCatchUpWindowIsFiveMinutes` failed in the full-class run while passing alone.
        // These tests are about the catch-up window, not about Qasr: pin the full five.
        settings.travelAutomatic = false
        settings.travelingMode = false
        // A real recording, so the decision has something to play or offer ("Default" short-circuits
        // every path before the decision is reached).
        settings.adhanNotificationSound = "minshawi-2"
        settings.adhanAutoPlayInApp = true
        settings.adhanOverridesSilentMode = false
        SilentSwitch.debugOverride = nil
        ForegroundAdhanPlayer.debugMissedAdhan = nil
        await quietThePlayer()
    }

    override func tearDown() async throws {
        await quietThePlayer()
        let settings = Settings.shared
        settings.currentLocation = Self.savedLocation
        settings.adhanOverridesSilentMode = Self.savedOverride
        settings.adhanAutoPlayInApp = Self.savedAutoPlay
        settings.adhanNotificationSound = Self.savedSound
        settings.travelAutomatic = Self.savedTravelAutomatic
        settings.travelingMode = Self.savedTravelingMode
        UserDefaults.standard.set(Self.savedMoment, forKey: Self.momentKey)
        SilentSwitch.debugOverride = nil
        ForegroundAdhanPlayer.debugMissedAdhan = nil
        try await super.tearDown()
    }

    /// The host app shares this player, and inside the five minutes after a prayer its own activation
    /// catch-up may have started the adhan by the time the suite runs. Quiet it first; no test here is
    /// about an adhan the host began, and the fade clears `playingPrayerName` within half a second.
    private func quietThePlayer() async {
        let player = ForegroundAdhanPlayer.shared
        player.stop()
        if player.isPlaying {
            player.stopAdhan()
            let deadline = Date().addingTimeInterval(3)
            while player.isPlaying, Date() < deadline {
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    /// A Dhuhr whose moment passed a minute ago: inside the window, and never the moment last played.
    private func injectMissedDhuhr() -> ForegroundAdhanPlayer.Target {
        let target: ForegroundAdhanPlayer.Target = (
            date: Date().addingTimeInterval(-60),
            name: "Dhuhr",
            notificationID: "Dhuhr-test-\(UUID().uuidString)"
        )
        ForegroundAdhanPlayer.debugMissedAdhan = target
        UserDefaults.standard.removeObject(forKey: Self.momentKey)
        return target
    }

    private func momentKey(_ target: ForegroundAdhanPlayer.Target) -> String {
        "\(target.name)@\(Int(target.date.timeIntervalSince1970 / 60))"
    }

    /// Waits for the decision, which runs off the main thread (the probe, the session activation).
    private func settle(until condition: @MainActor () -> Bool, seconds: TimeInterval = 4) async {
        let deadline = Date().addingTimeInterval(seconds)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    // MARK: The window

    /// Five minutes, applied to the lookback itself: 4:59 past a prayer still finds it, 5:01 does not.
    /// One window for the offer and the auto-play alike, so there is a single figure to reason about.
    func testTheCatchUpWindowIsFiveMinutes() throws {
        let settings = Settings.shared
        let prayers = try XCTUnwrap(settings.getPrayerTimes(for: Date()), "no prayer times for Mecca")
        // "Jumuah" on a Friday, the way the app's own lookups spell it (`_filterTravelingMode` takes
        // the same pair). `setUp` pins traveling mode off, so "Dhuhr/Asr" cannot appear here.
        let dhuhr = try XCTUnwrap(
            prayers.first { $0.nameTransliteration == "Dhuhr" || $0.nameTransliteration == "Jumuah" },
            "no midday prayer in \(prayers.map(\.nameTransliteration))"
        )

        let justInside = dhuhr.time.addingTimeInterval(4 * 60 + 59)
        let justOutside = dhuhr.time.addingTimeInterval(5 * 60 + 1)

        // The window is passed in by the player, so assert against the figure the player uses rather
        // than a literal: a test that hardcodes 300 would pass while the player used 600.
        let window = ForegroundAdhanPlayer.catchUpWindowForTesting
        XCTAssertEqual(window, 300, "the catch-up window is five minutes")

        let inside = settings.recentForegroundAdhan(within: window, now: justInside)
        let outside = settings.recentForegroundAdhan(within: window, now: justOutside)

        // Dhuhr's own eligibility depends on the user's notification switches, so assert the window's
        // BEHAVIOUR: whatever it finds at 4:59 it must not still find at 5:01. Against the RESOLVED
        // name, not the literal "Dhuhr" - on a Friday that literal matched nothing and the assertion
        // quietly skipped instead of testing the window.
        let middayName = dhuhr.nameTransliteration
        if let inside, inside.name == middayName {
            XCTAssertNotEqual(outside?.name, middayName, "an adhan 5:01 old is outside the window")
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

    // MARK: The decision

    /// A silenced phone gets a Play button, never a muted recording: nothing plays, the offer says why,
    /// and the moment is NOT spent, so the button still has something to play.
    func testSilencedPhoneOffersInsteadOfPlaying() async {
        SilentSwitch.debugOverride = .muted
        let target = injectMissedDhuhr()
        let player = ForegroundAdhanPlayer.shared

        player.playMissedAdhan()
        await settle { player.pendingPrayerName != nil || player.isPlaying }

        XCTAssertFalse(player.isPlaying, "a silenced phone must never start the recording")
        XCTAssertEqual(player.pendingPrayerName, "Dhuhr")
        XCTAssertEqual(player.pendingReason, .silenced)
        XCTAssertNotEqual(UserDefaults.standard.string(forKey: Self.momentKey), momentKey(target),
                          "an offer must not spend the moment")
    }

    /// "Play Automatically" off always offers, whatever the switch says, and the offer says so.
    func testAutoPlayOffOffersInsteadOfPlaying() async {
        Settings.shared.adhanAutoPlayInApp = false
        SilentSwitch.debugOverride = .audible
        _ = injectMissedDhuhr()
        let player = ForegroundAdhanPlayer.shared

        player.playMissedAdhan()
        await settle { player.pendingPrayerName != nil || player.isPlaying }

        XCTAssertFalse(player.isPlaying, "with Play Automatically off nothing starts by itself")
        XCTAssertEqual(player.pendingPrayerName, "Dhuhr")
        XCTAssertEqual(player.pendingReason, .manual)
    }

    /// "Play In-App Adhan in Silent Mode" treats a silenced phone as audible: the adhan plays, no offer.
    func testOverrideTreatsASilencedPhoneAsAudible() async {
        Settings.shared.adhanOverridesSilentMode = true
        SilentSwitch.debugOverride = .muted
        _ = injectMissedDhuhr()
        let player = ForegroundAdhanPlayer.shared

        player.playMissedAdhan()
        await settle { player.isPlaying || player.pendingPrayerName != nil }

        XCTAssertNil(player.pendingPrayerName, "the override plays through Silent Mode, it does not offer")
        XCTAssertTrue(player.isPlaying, "the override starts the recording on a silenced phone")
    }

    /// A tap on the offer sounds the adhan through Silent Mode, and only then is the moment spent.
    func testTappingTheOfferPlaysAndSpendsTheMoment() async {
        SilentSwitch.debugOverride = .muted
        let target = injectMissedDhuhr()
        let player = ForegroundAdhanPlayer.shared

        player.playMissedAdhan()
        await settle { player.pendingPrayerName != nil }
        XCTAssertEqual(player.pendingPrayerName, "Dhuhr")

        player.playOfferedAdhan()
        await settle { player.isPlaying && UserDefaults.standard.string(forKey: Self.momentKey) != nil }

        XCTAssertNil(player.pendingPrayerName, "the offer is spent once tapped")
        XCTAssertTrue(player.isPlaying, "a tap sounds the adhan on a silenced phone")
        XCTAssertEqual(UserDefaults.standard.string(forKey: Self.momentKey), momentKey(target),
                       "a recording that began spends the moment")
    }

    /// An offer is retired by backgrounding, and not by being looked at. `stop()` is the app leaving
    /// the foreground: a tap minutes later must not start an adhan for a prayer long past.
    func testBackgroundingClearsTheOffer() {
        let player = ForegroundAdhanPlayer.shared
        player.debugSetPending("Dhuhr")
        XCTAssertEqual(player.pendingPrayerName, "Dhuhr")

        player.stop()

        XCTAssertNil(player.pendingPrayerName, "an offer must not survive backgrounding")
        XCTAssertNil(player.pendingReason)
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

    // MARK: The probe

    /// The real probe answers, and answers promptly. The simulator has no switch, so only the SHAPE is
    /// asserted: a verdict within the timeout, never a hang.
    func testTheSilentSwitchProbeAnswers() async {
        SilentSwitch.debugOverride = nil
        let started = Date()
        let state = await SilentSwitch.probe()
        XCTAssertLessThan(Date().timeIntervalSince(started), 3, "the probe must not hang the adhan")
        XCTAssertTrue([.muted, .audible, .unknown].contains(state))
    }

    // MARK: The banner

    /// The banner follows the player's key, and a dismissal applies only to the state it was made for:
    /// hiding the Play offer never hides the PLAYING card that follows a tap, and the next adhan banners
    /// again. Dismissing never stops the audio, which is why the footer control stays.
    func testBannerDismissalIsPerState() {
        let presenter = AdhanBannerPresenter.shared

        XCTAssertTrue(presenter.shouldShow(key: "playing:Fajr", dismissed: nil))
        XCTAssertFalse(presenter.shouldShow(key: "playing:Fajr", dismissed: "playing:Fajr"))
        XCTAssertTrue(presenter.shouldShow(key: "playing:Dhuhr", dismissed: "pending:Dhuhr"),
                      "dismissing the offer must not hide the adhan that then plays")
        XCTAssertTrue(presenter.shouldShow(key: "playing:Dhuhr", dismissed: "playing:Fajr"),
                      "a dismissal must not silence the next adhan's banner")
        XCTAssertFalse(presenter.shouldShow(key: nil, dismissed: nil))
    }
}
