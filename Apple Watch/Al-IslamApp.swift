import SwiftUI
import WidgetKit

@main
struct AlIslamApp: App {
    @StateObject private var settings = Settings.shared
    @StateObject private var quranData = QuranData.shared
    @StateObject private var quranPlayer = QuranPlayer.shared
    @StateObject private var namesData = NamesViewModel.shared

    @Environment(\.scenePhase) private var scenePhase
    @State private var isLaunching = true

    init() {
        // Activate WatchConnectivity early so we can tell whether the iPhone app is installed
        // (used to decide if the watch should schedule prayer notifications itself).
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isLaunching {
                    LaunchScreen(isLaunching: $isLaunching)
                } else {
                    TabView {
                        AdhanView()
                        
                        QuranView()
                        
                        IslamView()
                                                
                        SettingsView()
                    }
                }
            }
            .environmentObject(settings)
            .environmentObject(quranData)
            .environmentObject(quranPlayer)
            .environmentObject(namesData)
            .accentColor(settings.accentColor.color)
            .tint(settings.accentColor.color)
            .preferredColorScheme(settings.colorScheme)
            .transition(.opacity)
            .animation(.easeInOut, value: isLaunching)
            .onAppear { settings.fetchPrayerTimes() }
        }
        .onChange(of: settings.accentColor) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
        // No `.onChange` refresh for `prayerCalculation` or `travelingMode`: every path that writes them
        // (the manual setters, the dialog overrides, the auto-checks inside a fetch, a synced snapshot)
        // already performs its own recompute, with auto-checks suppressed where the change was a choice.
        // A blanket refresh here would re-run the automatic detection with checks ON right after a manual
        // change - the exact override/spam bug the old one-shot flags existed to paper over.
        .onChange(of: settings.hanafiMadhab) { _ in
            settings.fetchPrayerTimes(force: true)
        }
        .onChange(of: settings.hijriOffset) { _ in
            settings.updateDates()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                // The watch senses its own location (location is never synced from the phone), but its
                // continuous updates stop the moment the app suspends - so after a flight, raising the wrist
                // showed the departure city indefinitely. One immediate one-shot fix on wake, then the same
                // low-frequency cadence the iPhone uses while frontmost.
                settings.refreshLocationIfStale()
                settings.beginForegroundLocationCadence()
            } else {
                settings.endForegroundLocationCadence()
                // Flush any just-made setting change before suspension so it reliably reaches the iPhone.
                WatchConnectivityManager.shared.flushPendingSync()
            }
        }
    }
}
