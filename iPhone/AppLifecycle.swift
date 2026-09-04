#if os(iOS)
import SwiftUI

/// The one owner of `isIdleTimerDisabled` (Phase 5 step 12): the display stays awake while a Quran
/// reader is on screen (reading, or following a recitation), and only on the full tier. Playback
/// used to own it, which kept the screen on while audio played from any tab.
@MainActor
enum ScreenAwake {
    static var readerVisible = false {
        didSet { apply() }
    }

    static func apply() {
        let wanted = readerVisible && PerformanceProfile.shared.tier != .reduced
        if UIApplication.shared.isIdleTimerDisabled != wanted {
            UIApplication.shared.isIdleTimerDisabled = wanted
        }
    }
}

/// The app's foreground/background orchestration, in one named place.
///
/// This is deliberately NOT in `Settings`: a phase change touches several subsystems (playback
/// persistence, widgets, the in-app adhan player, the fasting Live Activity, Hadith of the Day,
/// location, watch sync), and `Settings` should not know most of them exist.
///
/// ORGANIZED FOR THE COMPANION APPS: every function below is one app domain, whole and
/// self-contained. When this file is copied into Al-Adhan, delete the Al-Quran and Al-Hadith functions
/// (and their calls); into Al-Quran, delete the Adhan and Al-Hadith ones. Nothing in one domain's
/// block depends on another's.
enum AppLifecycle {

    /// Main-actor because it was lifted out of a SwiftUI `.onChange` closure and everything it
    /// touches (players, stores, location) is main-actor state.
    @MainActor
    static func scenePhaseChanged(to phase: ScenePhase) {
        installMemoryWarningPurge()
        adhanScenePhaseChanged(to: phase)
        quranScenePhaseChanged(to: phase)
        hadithScenePhaseChanged(to: phase)
        sharedScenePhaseChanged(to: phase)
    }

    // MARK: - Al-Adhan (prayer times, adhan playback, fasting, location)

    @MainActor
    private static func adhanScenePhaseChanged(to phase: ScenePhase) {
        let settings = Settings.shared

        if phase == .active {
            // Play the adhan in-app on time while open (the scheduled notification covers the closed
            // case and can be delivered late by the system, especially on Mac/Catalyst).
            ForegroundAdhanPlayer.shared.reschedule()
            // A Live Activity can only be requested from the foreground, so this is the one place that
            // can start the fasting countdown. It no-ops outside Ramadan, and outside the hour before
            // Fajr (suhoor) or Maghrib (iftar).
            FastingActivityController.refresh()
            // Coming back to a stale fix (landed, drove, flew) gets one immediate refresh; the cadence
            // then keeps it loosely current (every ~5 min) for as long as the app stays frontmost -
            // significant-change monitoring can't do this without cell coverage, e.g. on a plane.
            settings.refreshLocationIfStale()
            settings.beginForegroundLocationCadence()
        } else {
            ForegroundAdhanPlayer.shared.stop()
            // A high-accuracy burst pins the GPS. `AdhanView.onDisappear` ends it when you navigate away,
            // but backgrounding the app doesn't disappear the view - without this the burst would run to
            // its 25-second timeout with the screen off.
            settings.endLocationRefinement()
            settings.endForegroundLocationCadence()
        }
    }

    // MARK: - Al-Quran (playback persistence, Quran widgets, reading progress)

    @MainActor
    private static func quranScenePhaseChanged(to phase: ScenePhase) {
        let settings = Settings.shared

        QuranPlayer.shared.saveLastListenedSurah()
        // Immediate: a pending 0.8 s settle would be lost to a suspension.
        QuranPlayer.shared.saveLastListenedAyah(immediate: true)

        // Only when LEAVING the foreground: that's when the widgets become visible and need the fresh
        // snapshot. Running this on every transition (including becoming active) paid a JSON encode plus
        // a reload of every widget timeline each time, against WidgetKit's daily reload budget.
        if phase != .active {
            settings.refreshQuranWidgets()
            // A page flip within the last second may still have its last-read write pending.
            settings.flushPendingLastRead()
            // A khatm mark made in the last 250ms is still on the debounce timer; persist it before
            // the system can suspend or kill the process.
            settings.flushPendingKhatmProgress()
        }
    }

    // MARK: - Al-Hadith (daily hadith)

    @MainActor
    private static func hadithScenePhaseChanged(to phase: ScenePhase) {
        guard phase == .active else { return }
        // Re-resolve Hadith of the Day: `.task` fires only when the view tree is rebuilt, so an
        // app foregrounded across midnight (never cold-launched) kept showing yesterday's card.
        // No-ops within the same day.
        HadithStore.shared.prepareDailyHadith()
    }

    // MARK: - Memory pressure (Phase 5 step 13)

    /// The Quran module's session caches that are pure speed-ups and rebuild themselves on demand:
    /// the riwayah alignment and diff tables, the mushaf's fallback renders, the print-line tables,
    /// the highlighter's swatch images, the facsimile's measured crops, and the inflated solidpack
    /// bodies. One observer, installed on the first scene-phase change (the `NSCache`s already shed
    /// on their own).
    private static var memoryWarningObserver: NSObjectProtocol?

    @MainActor
    private static func installMemoryWarningPurge() {
        guard memoryWarningObserver == nil else { return }
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in purgeQuranSessionCaches() }
        }
    }

    @MainActor
    private static func purgeQuranSessionCaches() {
        QiraahComparison.purgeCaches()
        MushafPageRenderCache.purgeFallbackRenders()
        MushafPrintLines.purge()
        AyahHighlightColor.purgeSwatchCache()
        MushafPDFLibrary.purgeMeasuredCrops()
        SolidPack.purgeInflatedBodies()
    }

    // MARK: - Shared (watch sync - keep in every app that ships a watch companion)

    @MainActor
    private static func sharedScenePhaseChanged(to phase: ScenePhase) {
        guard phase != .active else { return }
        // Send any just-made setting change before the app is suspended, so it can't be lost (and
        // can't be reverted by a stale synced value on the next launch).
        WatchConnectivityManager.shared.flushPendingSync()
    }
}

#elseif os(watchOS)
import SwiftUI

/// The watch app's foreground/background orchestration - the iPhone `AppLifecycle`'s little sibling,
/// and the same contract: the app root delegates its scene-phase transition HERE in one line, and
/// this is the only place that knows which subsystems care. Deliberately much smaller than the
/// iPhone's: no adhan player, no Live Activity, no Quran-widget snapshots, no daily hadith on the
/// wrist - add a domain section only when the watch actually ships the feature.
enum AppLifecycle {

    @MainActor
    static func scenePhaseChanged(to phase: ScenePhase) {
        let settings = Settings.shared

        if phase == .active {
            // The watch senses its own location (location is never synced from the phone), but its
            // continuous updates stop the moment the app suspends - so after a flight, raising the
            // wrist showed the departure city indefinitely. One immediate one-shot fix on wake, then
            // the same low-frequency cadence the iPhone uses while frontmost.
            settings.refreshLocationIfStale()
            settings.beginForegroundLocationCadence()
        } else {
            settings.endForegroundLocationCadence()
            // A page flip within the last second may still have its last-read write pending.
            settings.flushPendingLastRead()
            // A khatm mark made in the last 250ms is still on the debounce timer; persist it before
            // the system can suspend or kill the process.
            settings.flushPendingKhatmProgress()
            // Flush any just-made setting change before suspension so it reliably reaches the iPhone.
            WatchConnectivityManager.shared.flushPendingSync()
        }
    }
}
#endif
