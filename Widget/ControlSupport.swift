#if os(iOS)
import Foundation

/// The Control Center controls' kinds. Deliberately NOT part of `AdhanWidgetKind`: that enum is the
/// reload table for TIMELINE widgets (`WidgetCenter.reloadTimelines(ofKind:)`), and a control has no
/// timeline - it refreshes through `ControlCenter.shared.reloadControls(ofKind:)` instead. Putting a
/// control in that table would have it silently never reload, which is the exact failure the date lock
/// widgets had (Quality Guide P8).
///
/// Plain strings, and these strings are PERSISTED by the system against every placed control: renaming
/// one orphans the control the user put in Control Center, on their Lock Screen, or on their Action
/// button. They are append-only.
enum ControlWidgetKind {
    static let resumeRecitation = "AlIslamResumeRecitationControl"
    static let qibla = "AlIslamQiblaControl"
    static let prayerTimes = "AlIslamPrayerTimesControl"

    static let all = [resumeRecitation, qibla, prayerTimes]
}

/// The App Group keys the controls read. The app owns the writes; the control process only reads.
extension AppIdentifiers {
    /// Whether recitation is playing right now, mirrored by the app so the Resume Recitation toggle can
    /// show its state without being able to see `QuranPlayer` (a different process).
    static let widgetIsPlayingKey = "widgetQuranIsPlaying"
}
#endif
