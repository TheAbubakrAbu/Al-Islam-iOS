import SwiftUI

@main
struct AlIslamApp: App {
    // Plain references, not `@StateObject` - the iPhone root's rule: observing the stores here re-ran
    // this body (and the whole TabView under it) on every publish of any of them. What the root reads
    // comes from `RootAppearance` through `.appearanceEnvironment()`.
    private let settings = Settings.shared
    private let quranData = QuranData.shared
    private let quranPlayer = QuranPlayer.shared
    private let namesData = NamesViewModel.shared

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
            // Accent, tint, color scheme and the shared chrome's `AppearanceEnvironment`, live.
            .appearanceEnvironment()
            // The app-wide SF Rounded design, same as the iPhone root - covers every system-font Text on
            // the watch, styled or not (watchOS 9.1+; a visual no-op earlier).
            .appFontDesign()
            // Every Toggle breathes: the standard switch with 2pt of vertical padding (user rule),
            // applied once at the root exactly like the iPhone app.
            .toggleStyle(PaddedSwitchToggleStyle())
            .transition(.opacity)
            .animation(.easeInOut, value: isLaunching)
            .onAppear { settings.fetchPrayerTimes() }
        }
        // No `.onChange` refreshes for settings here (the iPhone root's exact rule): each setting's
        // own didSet performs its side effects - `accentColor` and `hijriOffset` recompute dates and
        // repaint widgets from Settings on every write path (pickers, a synced snapshot, a reset), so
        // duplicates here paid a SECOND timeline reload per flip. And no refresh for
        // `prayerCalculation`, `travelingMode`, or `hanafiMadhab` either: every path that writes them
        // already performs its own recompute - a blanket refresh would re-run the automatic detection
        // with checks ON right after the change, the exact override/spam bug the old one-shot flags
        // papered over. Phase transitions delegate to the one place that orchestrates them.
        .onChange(of: scenePhase) { phase in
            AppLifecycle.scenePhaseChanged(to: phase)
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
        // The Quran parse starts only once the cover is lifting (or was never up): the reveal used to
        // wait on `waitUntilCoreLoaded()`, which on an S-series CPU WAS the cold launch. The Quran tab
        // shows its loading state for the second or two the parse takes if it is opened at once.
        defer { quranData.ensureLoading() }

        guard isLaunching else { LaunchWarmup.shared.markWarm(); return }

        selectedTab = .quran
        try? await Task.sleep(nanoseconds: 300_000_000)
        selectedTab = .islam
        try? await Task.sleep(nanoseconds: 150_000_000)
        selectedTab = .settings
        try? await Task.sleep(nanoseconds: 80_000_000)
        selectedTab = launchTab
        try? await Task.sleep(nanoseconds: 80_000_000)

        LaunchWarmup.shared.markWarm()
    }

    /// The tab the watch lands on after the under-cover warm. Always Adhan for users; a DEBUG launch
    /// argument lets automation land straight on a tab it wants to exercise - the same escape hatch
    /// the iPhone's MainTabView has, because nothing else can drive the simulator's tabs from a harness.
    private var launchTab: WatchTab {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-launchTabQuran") { return .quran }
        if ProcessInfo.processInfo.arguments.contains("-launchTabIslam") { return .islam }
        if ProcessInfo.processInfo.arguments.contains("-launchTabSettings") { return .settings }
        #endif
        return .adhan
    }
}
