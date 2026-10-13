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
        LaunchClock.mark("app init")
        #if DEBUG
        LaunchClock.installStallWatch()
        #endif
        // Nothing is revealed until the launch cover lifts (`isLaunching` flips in the finale): the
        // Adhan tab's first appearance under the cover then computes today's list from the stored
        // location and asks for nothing, and the location / notification prompts, the audio session
        // and every task parked on `AppReveal` wait for the reveal, the iPhone root's rule. Before
        // this the watch never set the mirror, so `appRevealed` read its default (true) and the two
        // system prompts rose over the launch animation.
        AppReveal.revealed = false
        // Activate WatchConnectivity early so we can tell whether the iPhone app is installed
        // (used to decide if the watch should schedule prayer notifications itself).
        _ = WatchConnectivityManager.shared
        LaunchClock.mark("app init: watch connectivity up")
    }

    private enum WatchTab: Hashable { case adhan, quran, islam, settings }

    @State private var selectedTab: WatchTab = .adhan
    @State private var didWarm = false
    /// The four tabs are placeholders until the launch cover's first frame has committed (see
    /// `tabContent`); flipped by `mountTabsThenWarm`.
    @State private var tabsMounted = false

    var body: some Scene {
        WindowGroup {
            // The tabs mount from the first frame UNDER the launch cover (the same trick as the iPhone's
            // MainTabView), so each tab's view tree can be built and retained while the launch animation
            // plays. Before this, tabs only mounted after the reveal, and the first swipe into a tab paid its
            // whole build cost as a visible hitch - the "huge lag going from Quran to Al-Islam" on the watch.
            // ...but never in the cover's own first transaction (the iPhone's launch rule, Launch first
            // frame memory): the Adhan and Quran tabs (the selected page and its neighbour) used to be
            // built in the same run-loop pass as the cover, which held the first frame back by the cost
            // of both lists. Each tab is a `Color.clear` until `LaunchWarmup` reports the cover up, then
            // all four mount under it and the walk below realizes them one by one.
            ZStack {
                TabView(selection: $selectedTab) {
                    tabContent { AdhanView() }.tag(WatchTab.adhan)

                    tabContent { QuranView() }.tag(WatchTab.quran)

                    tabContent { IslamView() }.tag(WatchTab.islam)

                    tabContent { SettingsView() }.tag(WatchTab.settings)
                }
                .task { await mountTabsThenWarm() }

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
            // The live mirror of `isLaunching` for the views that read it (`AdhanView` gates its
            // prompts and its post-reveal refresh on this) and for the tasks parked on `AppReveal`.
            .environment(\.appRevealed, !isLaunching)
            .onChange(of: isLaunching) { launching in
                AppReveal.revealed = !launching
            }
            // No `.onAppear { settings.fetchPrayerTimes() }` here any more: `AdhanView.onAppear` runs the
            // launch fetch itself (under the cover it computes from the stored location; after the reveal
            // it asks for location first), so this was a second full recompute on the first-paint path -
            // the same duplicate the iPhone root removed.
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

    /// A tab's content, or a clear placeholder while the launch cover's first frame is still pending.
    @ViewBuilder
    private func tabContent<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if tabsMounted {
            content()
        } else {
            Color.clear
        }
    }

    /// Mount the four tabs once the cover's first frame has committed (at once when there is no cover),
    /// give that mount its own run-loop pass, then walk them.
    @MainActor
    private func mountTabsThenWarm() async {
        if isLaunching {
            await LaunchWarmup.shared.waitUntilCoverUp(maxWaitNanos: 1_000_000_000)
        }
        tabsMounted = true
        LaunchClock.mark("tabs mounted")
        // One frame: the mount realizes the selected page (and its neighbour) in the next pass, and the
        // walk's first selection change must not land in that same transaction.
        try? await Task.sleep(nanoseconds: 16_000_000)
        await warmUnderCover()
    }

    /// Walk each tab under the launch cover so its view tree is built and retained before the reveal - Quran
    /// first (heaviest, and the tab most likely opened next), then Islam, then Settings, settling on Adhan.
    /// The whole walk overlaps the finale animation's hold, so the warming costs no visible launch time
    /// (the watch's finale does not wait for `isWarm`; the walk is capped by its own sleeps).
    @MainActor
    private func warmUnderCover() async {
        guard !didWarm else { return }
        didWarm = true
        // The Quran parse starts only once the cover has lifted (or was never up): the reveal used to
        // wait on `waitUntilCoreLoaded()`, which on an S-series CPU WAS the cold launch. The Quran tab
        // shows its loading state for the second or two the parse takes if it is opened at once.
        // At the REVEAL, not at the walk's end: the parse runs off-main but its landing (the surah
        // list and sections publishing) is ~100 ms of main thread on the simulator, and with the walk
        // now ending ~250 ms after the cover is up (2026-10-12), a kick at the walk's end would land it
        // under the finale's hold. Parked on `AppReveal` (set by this root): on the simulator the
        // text is in ~0.6 s later, just after the dissolve; a watch parses slower, so later still. A
        // visit to the Quran tab before then kicks it itself (`QuranView.onAppear`, once warm).
        defer {
            Task { @MainActor in
                await AppReveal.waitUntilRevealed()
                quranData.ensureLoading()
            }
        }

        guard isLaunching else { LaunchWarmup.shared.markWarm(); return }

        // Jumps, not slides: the paging TabView animates a selection change, and the old 300 / 150 / 80 /
        // 80 ms sleeps were there to let each slide land before the next. Nothing is visible under the
        // cover, so the selection moves in a transaction with animations off, and each tab gets two
        // frames to realize (a selection change realizes the page in the next run-loop pass, which is
        // what a sleep's resume waits behind anyway). The walk is ~500 ms shorter, which on an S-series
        // CPU is the difference between finishing under the finale's hold and still realizing tabs
        // while the cover dissolves.
        for tab in [WatchTab.quran, .islam, .settings, launchTab] {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { selectedTab = tab }
            try? await Task.sleep(nanoseconds: 32_000_000)
        }

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
