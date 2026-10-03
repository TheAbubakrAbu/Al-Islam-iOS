import AppIntents

/// The Last Listened Surah widget's play button: the surah from where it stopped, with its reciter.
/// An audio intent, so the system runs it in the app (launching it in the background when it is not
/// running) and the tap never opens anything, which is what the button needs on the CarPlay dashboard.
/// Compiled into the app and the widget: the widget only names it for its `Button(intent:)`, so each
/// target supplies its own `resumeListening()` (the app's in QuranShortcuts.swift; the widget's does
/// nothing, since an audio intent never runs there).
@available(iOS 17.0, *)
struct ResumeListeningIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Resume Listening"
    static var description = IntentDescription("Plays the last surah you listened to from where you left off.")
    /// Shortcuts already offers "Play Last Listened Surah"; this one exists for the widget's button.
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await resumeListening()
        return .result()
    }
}
