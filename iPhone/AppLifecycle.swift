import SwiftUI

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
        QuranPlayer.shared.saveLastListenedAyah()

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

    // MARK: - Shared (watch sync - keep in every app that ships a watch companion)

    @MainActor
    private static func sharedScenePhaseChanged(to phase: ScenePhase) {
        guard phase != .active else { return }
        // Send any just-made setting change before the app is suspended, so it can't be lost (and
        // can't be reverted by a stale synced value on the next launch).
        WatchConnectivityManager.shared.flushPendingSync()
    }
}
