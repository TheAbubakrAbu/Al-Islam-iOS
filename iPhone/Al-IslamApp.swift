import SwiftUI
import WidgetKit

/// Coordinates the "warm the main UI behind the launch screen, then reveal" hand-off.
///
/// The launch screen already has a quiet "hold on the logo and wait for init" phase; it now also waits for
/// `isWarm` before it plays its finale and hands off. `MainTabView` sets `isWarm` once it has built + retained
/// the heavy Quran tab and settled back on the Adhan landing tab - all behind the launch cover. Net effect: the
/// reveal happens only when everything is already built and on the right tab, so there's no tab flip and no
/// first-tap stall the user can see.
@MainActor
final class LaunchWarmup: ObservableObject {
    static let shared = LaunchWarmup()
    private init() {}

    @Published private(set) var isWarm = false

    func markWarm() { isWarm = true }

    /// Await `isWarm`, but never block the launch longer than `maxWaitNanos` (a safety cap so a failed warm can
    /// never strand the user on the launch screen).
    func waitUntilWarm(maxWaitNanos: UInt64) async {
        var waited: UInt64 = 0
        let step: UInt64 = 20_000_000
        while !isWarm && waited < maxWaitNanos {
            try? await Task.sleep(nanoseconds: step)
            waited += step
        }
    }
}

@main
struct AlIslamApp: App {
    @StateObject private var settings = Settings.shared
    @StateObject private var quranData = QuranData.shared
    @StateObject private var quranPlayer = QuranPlayer.shared
    @StateObject private var namesData = NamesViewModel.shared

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @State private var isLaunching = true
    // Keeps the splash mounted through its fade-out (see `rootContent`).
    @State private var splashPresented = false

    init() {
        // Activate WatchConnectivity so settings sync (and watch app-installed detection) work both ways.
        _ = WatchConnectivityManager.shared
    }

    private enum RootStage: Equatable {
        case launch
        case splash
        case main
    }

    private var rootStage: RootStage {
        if isLaunching {
            return .launch
        }
        return settings.firstLaunch ? .splash : .main
    }

    private var rootTransitionAnimation: Animation {
        .easeInOut(duration: 0.5)
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                // Every system font in the app is SF Rounded. Views that render a bundled Arabic face opt back
                // out with `arabicFontDesign(custom:)` - see the note in `Globals.swift`.
                .appFontDesign()
                .environmentObject(settings)
                .environmentObject(quranData)
                .environmentObject(quranPlayer)
                .environmentObject(namesData)
                .accentColor(settings.accentColor.color)
                .tint(settings.accentColor.color)
                .preferredColorScheme(settings.colorScheme)
                .appReviewPrompt()
                .onAppear { settings.fetchPrayerTimes() }
                //.statusBarHidden()
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
            quranPlayer.saveLastListenedSurah()
            quranPlayer.saveLastListenedAyah()
            settings.refreshQuranWidgets()
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
                // Send any just-made setting change before the app is suspended, so it can't be lost (and
                // can't be reverted by a stale synced value on the next launch).
                WatchConnectivityManager.shared.flushPendingSync()
            }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        ZStack {
            // Keep the tabs mounted from the very first frame - even while the launch/splash screen still covers
            // the screen - so the Quran tab can realize its (heavy) view tree behind that cover instead of on
            // the first visible tap. Al-Quran never lags here because Quran is its default tab and realizes
            // under the splash; mounting early gives Al-Islam the same head start while still landing the user
            // on the Adhan tab (see `MainTabView`, which sits on Quran while covered then flips to Adhan on
            // reveal). The launch/splash screens overlay on top and fade out to reveal it.
            MainTabView(isCovered: rootStage != .main)
                // Always opaque underneath the covers. The launch/splash screens are opaque and simply fade
                // themselves out (below) to reveal it - a clean single-layer dissolve, no mid-transition dip.
                .zIndex(1)

            // Above the tabs but below the covers: a letter / surah / name blown up to fill the screen. It
            // lives here (rather than on the row that opened it) so it can sit over the tab bar and fade in
            // as a plain overlay instead of a system sheet.
            FocusOverlayHost()
                .zIndex(1.5)

            if rootStage == .launch {
                LaunchScreen(isLaunching: $isLaunching)
                    .zIndex(3)
                    .transition(.opacity)
            }

            // The splash fades via an explicit `.opacity` (kept mounted through the fade), NOT a removal
            // `.transition`: SplashScreen wraps a NavigationView, which doesn't animate SwiftUI removal
            // transitions - it just snaps. A plain opacity animation on the hosted content works, giving the
            // splash → main hand-off a real cross-fade. It's unmounted a beat after the fade completes.
            if splashPresented {
                SplashScreen()
                    .opacity(rootStage == .splash ? 1 : 0)
                    .allowsHitTesting(rootStage == .splash)
                    .zIndex(2)
            }
        }
        .animation(rootTransitionAnimation, value: rootStage)
        // The tabs are mounted (and side-effecting views like AdhanView build) before the cover lifts; let them
        // hold user-facing prompts until we're actually on screen.
        .environment(\.appRevealed, rootStage == .main)
        .onChange(of: rootStage) { stage in
            if stage == .splash {
                splashPresented = true
            } else if splashPresented {
                // Leaving the splash: its opacity is animating to 0 above - unmount once that fade is done.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if rootStage != .splash { splashPresented = false }
                }
            }
        }
    }
}

private struct MainTabView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared

    /// True while a launch/splash screen still covers the tabs (drives the under-cover warm below).
    let isCovered: Bool

    private enum AppTab: Hashable { case adhan, quran, islam, settings }

    // We land the user on Adhan, so Adhan is the initial tab and builds first. The Quran tab is realized during
    // `warmUnderCover()` - briefly selected so `TabView` builds and RETAINS its heavy view tree, then we settle
    // back on Adhan. All of this happens behind the launch cover, and the launch screen waits for it to finish
    // (see `LaunchWarmup`) before it reveals - so the user only ever sees a fully-built Adhan tab, and the first
    // tap on Quran reuses the warm tab instantly. No visible tab flip, no first-tap stall.
    @State private var selectedTab: AppTab = .adhan
    @State private var didWarm = false

    var body: some View {
        tabs
            .task { await warmUnderCover() }
            .task { await prewarmAllQuran() }
    }

    /// Build + retain the Quran tab behind the launch cover, settle back on Adhan, then signal `LaunchWarmup`
    /// that the UI is ready to reveal. Runs once. If we were mounted already-uncovered (not a cold launch),
    /// there's nothing to hide, so we just mark warm immediately.
    @MainActor
    private func warmUnderCover() async {
        guard !didWarm else { return }
        didWarm = true

        guard isCovered else { LaunchWarmup.shared.markWarm(); return }

        // Build the real surah list, not the empty loading state.
        await quranData.waitUntilCoreLoaded()
        if Task.isCancelled { LaunchWarmup.shared.markWarm(); return }

        // Select Quran so TabView builds + retains QuranView, give it a couple runloop turns to lay out its
        // first screen, then return to the Adhan landing tab.
        selectedTab = .quran
        try? await Task.sleep(nanoseconds: 350_000_000)
        selectedTab = .adhan
        // Let Adhan become the rendered tab again before we allow the reveal, so the hand-off shows Adhan.
        try? await Task.sleep(nanoseconds: 80_000_000)

        LaunchWarmup.shared.markWarm()
    }

    /// As soon as the main UI (the Adhan tab) is on screen, warm EVERY surah's Arabic text / tajweed caches - 
    /// and with them the shared Arabic font's CoreText glyph cache - in the background, so the first switch to
    /// the Quran tab is already fully warm. Runs on the main actor (it reads `settings`) but yields + sleeps
    /// between surahs so the Adhan tab stays responsive while it fills in. Runs once per session (shared flag).
    @MainActor
    private func prewarmAllQuran() async {
        await quranData.waitUntilCoreLoaded()
        if Task.isCancelled || QuranData.didBroadPrewarm { return }

        // Warm the most-likely-first surahs (reading position, a bookmark, a favorite, al-Fatihah/al-Baqarah)
        // before the rest, so the surah a user is most likely to open is ready first.
        let priority = [
            settings.lastReadSurah > 0 ? settings.lastReadSurah : 1,
            settings.bookmarkedAyahs.first?.surah,
            settings.favoriteSurahs.first,
            1, 2
        ].compactMap { $0 }

        var seen = Set<Int>()
        for id in priority where seen.insert(id).inserted {
            if Task.isCancelled { return }
            if let surah = quranData.surah(id) {
                SurahView.prewarm(surah: surah, settings: settings)
                await Task.yield()
            }
        }

        // Skip the full sweep on memory-constrained devices (same gate the Quran tab uses) - priority warming
        // above still ran.
        guard !AppPerformance.shouldAvoidBroadPrewarm else { return }

        for surah in quranData.quran where seen.insert(surah.id).inserted {
            if Task.isCancelled { return }
            SurahView.prewarm(surah: surah, settings: settings)
            await Task.yield()
            try? await Task.sleep(nanoseconds: 12_000_000)   // throttle: keep the Adhan tab responsive
        }
        QuranData.didBroadPrewarm = true
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Adhan", systemImage: "mecca", value: AppTab.adhan) {
                    AdhanView()
                }

                Tab("Quran", systemImage: "character.book.closed.ar", value: AppTab.quran) {
                    QuranView()
                }

                Tab("Islam", systemImage: "moon.stars", value: AppTab.islam) {
                    IslamView()
                }

                Tab("Settings", systemImage: "gearshape", value: AppTab.settings, role: .search) {
                    SettingsView()
                }
            }
        } else {
            TabView(selection: $selectedTab) {
                AdhanView()
                    .tabItem {
                        Image(systemName: "safari")
                        Text("Adhan")
                    }
                    .tag(AppTab.adhan)

                QuranView()
                    .tabItem {
                        Image(systemName: "character.book.closed.ar")
                        Text("Quran")
                    }
                    .tag(AppTab.quran)

                IslamView()
                    .tabItem {
                        Image(systemName: "moon.stars")
                        Text("Islam")
                    }
                    .tag(AppTab.islam)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .tag(AppTab.settings)
            }
        }
    }
}
