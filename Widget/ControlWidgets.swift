#if os(iOS)
import AppIntents
import SwiftUI
import WidgetKit

// Control Center controls (iOS 18+), which are also the Lock Screen's bottom-corner buttons and can be
// bound to the Action button (Abu, 2026-10-07: "Add control center widget").
//
// WHAT EARNS A CONTROL. A control is a single tap from the Lock Screen with the phone still in hand, so
// the set here is the things this app is opened FOR in that moment and nothing else:
//   - Resume Recitation: the only one that does its work without opening the app at all.
//   - Qibla: the one thing a traveller needs before praying, pointed at a wall in a hotel room.
//   - Prayer Times: the glanceable answer, with the next prayer's time written on the control itself.
// Everything else the app does (reading, hadith, the libraries) is a session, not a tap, and a control
// that just opens a tab is a worse app icon.
//
// VALUE PROVIDERS, NOT TIMELINES. A control has no timeline: `ControlValueProvider` is read when the
// system refreshes the control, and `ControlCenter.shared.reloadControls` nudges it. The prayer control
// reads the SAME App Group snapshot the home-screen widgets do (`AppIdentifiers.appGroupSuiteName`), so
// it can never disagree with them about the next prayer.

// MARK: - Resume Recitation

/// The one control that does not open anything: `AudioPlaybackIntent` runs in the app, launching it in
/// the background if it is not running, exactly as the Last Listened Surah widget's play button does
/// (`ResumeListeningIntent`). Written as a toggle rather than a button so the control shows its state -
/// a control that only ever plays would read as "did that work?" with the app still in the background.
@available(iOS 18.0, *)
struct ResumeRecitationControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: ControlWidgetKind.resumeRecitation) {
            ControlWidgetToggle(
                "Recitation",
                isOn: QuranPlaybackStateProvider.isPlaying,
                action: ToggleRecitationIntent()
            ) { isPlaying in
                Label(isPlaying ? "Playing" : "Resume", systemImage: isPlaying ? "pause.fill" : "play.fill")
            }
            .tint(.green)
        }
        .displayName("Resume Recitation")
        .description("Plays the last surah you were listening to, from where you left off.")
    }
}

/// Reads whether recitation is playing from the App Group, which the app keeps current. The control
/// process is NOT the app process, so it cannot ask `QuranPlayer` directly.
@available(iOS 18.0, *)
enum QuranPlaybackStateProvider {
    static var isPlaying: Bool {
        UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)?
            .bool(forKey: AppIdentifiers.widgetIsPlayingKey) ?? false
    }
}

/// Play if stopped, pause if playing. `AudioPlaybackIntent` is what lets this run without the app coming
/// to the front; `perform()` is supplied per target the way `ResumeListeningIntent` is (the app's does
/// the work, the extension's is never run).
@available(iOS 18.0, *)
struct ToggleRecitationIntent: SetValueIntent, AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Toggle Recitation"
    static var description = IntentDescription("Plays or pauses the last surah you were listening to.")

    @Parameter(title: "Playing")
    var value: Bool

    init() {}
    init(value: Bool) { self.value = value }

    func perform() async throws -> some IntentResult {
        await setRecitationPlaying(value)
        return .result()
    }
}

// MARK: - Qibla

/// Opens the Qibla compass. An `OpenIntent`-style control: finding the direction is inherently a look at
/// the screen, so unlike recitation there is nothing to be gained by staying in the background.
@available(iOS 18.0, *)
struct QiblaControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: ControlWidgetKind.qibla) {
            ControlWidgetButton(action: OpenQiblaIntent()) {
                Label("Qibla", systemImage: "location.north.line.fill")
            }
        }
        .displayName("Qibla")
        .description("Opens the compass pointing to the Kaaba.")
    }
}

@available(iOS 18.0, *)
struct OpenQiblaIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Qibla"
    static var description = IntentDescription("Opens the Qibla compass.")
    static var openAppWhenRun = true
    /// Shortcuts has its own prayer intents; this one exists for the control.
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await openQibla()
        return .result()
    }
}

// MARK: - Prayer times

/// The next prayer's name and time ON the control, so the common case needs no tap at all. Tapping opens
/// the Adhan tab for the rest of the day's times.
@available(iOS 18.0, *)
struct PrayerTimesControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        // `StaticControlConfiguration`, not the `AppIntent` one: that variant is for a control the user
        // CONFIGURES (it takes a configuration intent, and its provider must be an
        // `AppIntentControlValueProvider`). This control has nothing to configure - it always shows the
        // next prayer - it just has a value that changes, which is what a value provider is for.
        StaticControlConfiguration(
            kind: ControlWidgetKind.prayerTimes,
            provider: NextPrayerValueProvider()
        ) { value in
            ControlWidgetButton(action: OpenPrayerTimesIntent()) {
                // The time as the control's own value line; the name is the label. With no times yet
                // (a fresh install, or location off) it falls back to the app's name rather than an
                // empty control.
                Label(value.name, systemImage: value.symbol)
                if let time = value.time {
                    Text(time, style: .time)
                }
            }
        }
        .displayName("Prayer Times")
        .description("The next prayer and its time; opens today's times.")
    }
}

@available(iOS 18.0, *)
struct NextPrayerValueProvider: ControlValueProvider {
    struct Value {
        let name: String
        let symbol: String
        let time: Date?
    }

    /// What the gallery shows before the control is placed.
    var previewValue: Value { Value(name: "Dhuhr", symbol: "sun.max.fill", time: nil) }

    func currentValue() async throws -> Value {
        // `Settings.shared` is what the prayer widgets' own provider reads in this same extension
        // process (`PrayersProvider.settings`), so the control can never disagree with the tiles beside
        // it. `fetchPrayerTimes()` first for the same reason the provider calls it: the times are
        // computed from the stored location, and a control may be read long after the app last ran.
        let settings = await MainActor.run { () -> (name: String, symbol: String, time: Date)? in
            let settings = Settings.shared
            settings.fetchPrayerTimes()
            guard let next = settings.nextPrayer else { return nil }
            return (next.displayName, next.image, next.time)
        }
        guard let settings else { return Value(name: "Prayer Times", symbol: "mecca", time: nil) }
        return Value(name: settings.name, symbol: settings.symbol, time: settings.time)
    }
}

@available(iOS 18.0, *)
struct OpenPrayerTimesIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Prayer Times"
    static var description = IntentDescription("Opens today's prayer times.")
    static var openAppWhenRun = true
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await openPrayerTimes()
        return .result()
    }
}
#endif
