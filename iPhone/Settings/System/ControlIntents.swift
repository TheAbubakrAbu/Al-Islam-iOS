#if os(iOS)
import AppIntents
import Foundation
import WidgetKit

// The APP's half of the Control Center controls' intents (the controls themselves are in
// Widget/ControlWidgets.swift, and the extension's do-nothing halves sit beside them).
//
// Same split as `ResumeListeningIntent`: an `AudioPlaybackIntent` runs in the app even when the tap
// happened in Control Center with the app not running, and an `openAppWhenRun` intent opens the app and
// runs here. Either way these bodies only ever execute in the app process, where the player and the
// navigation object exist.

@available(iOS 18.0, *)
extension ToggleRecitationIntent {
    /// Play or pause. Playing reuses `ResumeListeningIntent.resumeListening()` rather than repeating its
    /// rules (already playing is a no-op, paused resumes in place with its ayah range, otherwise the
    /// Last Listened surah once a background launch has the Quran loaded).
    @MainActor
    func setRecitationPlaying(_ playing: Bool) async {
        if playing {
            await ResumeListeningIntent().resumeListening()
        } else {
            QuranPlayer.shared.pause()
        }
        // The toggle reads its state from the App Group, and the control is not a timeline, so it needs
        // its own nudge to redraw. `mirrorPlaybackStateForControls` writes the flag first.
        QuranPlayer.shared.mirrorPlaybackStateForControls()
    }
}

@available(iOS 18.0, *)
extension OpenQiblaIntent {
    @MainActor
    func openQibla() async {
        AppNavigation.shared.openAdhan(.qibla)
    }
}

@available(iOS 18.0, *)
extension OpenPrayerTimesIntent {
    @MainActor
    func openPrayerTimes() async {
        AppNavigation.shared.openAdhan(.tab)
    }
}
#endif
