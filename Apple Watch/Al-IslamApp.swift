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

    private enum WatchTab: Hashable { case adhan, quran, islam, settings }

    @State private var selectedTab: WatchTab = .adhan
    @State private var didWarm = false

    var body: some Scene {
        WindowGroup {
            // The tabs mount from the first frame UNDER the launch cover (the same trick as the iPhone's
            // MainTabView), so each tab's view tree can be built and retained while the launch animation
            // plays. Before this, tabs only mounted after the reveal, and the first swipe into a tab paid its
            // whole build cost as a visible hitch - the "huge lag going from Quran to Al-Islam" on the watch.
            ZStack {
                TabView(selection: $selectedTab) {
                    AdhanView().tag(WatchTab.adhan)

                    QuranView().tag(WatchTab.quran)

                    IslamView().tag(WatchTab.islam)

                    SettingsView().tag(WatchTab.settings)
                }
                .task { await warmUnderCover() }

                if isLaunching {
                    LaunchScreen(isLaunching: $isLaunching)
                        .zIndex(1)
                        .transition(.opacity)
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

    /// Walk each tab under the launch cover so its view tree is built and retained before the reveal - Quran
    /// first (heaviest, and the tab most likely opened next), then Islam, then Settings, settling on Adhan.
    /// The launch screen's finale gates its hand-off on `LaunchWarmup.isWarm`, and the whole walk overlaps
    /// the finale animation, so the warming costs no visible launch time.
    @MainActor
    private func warmUnderCover() async {
        guard !didWarm else { return }
        didWarm = true

        guard isLaunching else { LaunchWarmup.shared.markWarm(); return }

        // Build the real surah list, not the empty loading state.
        await quranData.waitUntilCoreLoaded()
        if Task.isCancelled { LaunchWarmup.shared.markWarm(); return }

        selectedTab = .quran
        try? await Task.sleep(nanoseconds: 300_000_000)
        selectedTab = .islam
        try? await Task.sleep(nanoseconds: 150_000_000)
        selectedTab = .settings
        try? await Task.sleep(nanoseconds: 80_000_000)
        selectedTab = .adhan
        try? await Task.sleep(nanoseconds: 80_000_000)

        LaunchWarmup.shared.markWarm()
    }
}
