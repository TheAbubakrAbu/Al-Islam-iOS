import SwiftUI
import WidgetKit

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

        if #unavailable(iOS 26.0) {
            // Pre-Liquid-Glass, a scroll view resting at its bottom edge flips the tab bar to its
            // scroll-edge appearance - which iOS leaves fully TRANSPARENT by default, so list content
            // (the Adhan date footer, the Quran rows) collided bare with the tab icons (user report:
            // "the bottom is transparent"). Pin the standard blurred bar in that state too. iOS 26's
            // Liquid Glass bar handles its own legibility and must not be overridden.
            let bottomEdge = UITabBarAppearance()
            bottomEdge.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = bottomEdge
        }
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
                // Every Toggle in the app breathes: the standard switch with 2pt of vertical padding
                // (user rule), applied once here so no individual row can forget it.
                .toggleStyle(PaddedSwitchToggleStyle())
                .environmentObject(settings)
                .environmentObject(quranData)
                .environmentObject(quranPlayer)
                .environmentObject(namesData)
                .accentColor(settings.accentColor.color)
                .tint(settings.accentColor.color)
                .preferredColorScheme(settings.colorScheme)
                .appReviewPrompt()
                // Set ABOVE (outside) `.appReviewPrompt()` too, or its `@Environment(\.appRevealed)`
                // reads the key's default (true): the copy inside `rootContent` sits BELOW the review
                // modifier in the tree, and environment only flows down - the launch-cover gate on the
                // review sheet was silently inert without this.
                .environment(\.appRevealed, rootStage == .main)
                // Watches the stores the badges are thresholds on. The banner itself is NOT hosted
                // here - it lives in its own window above the app (see `AchievementBannerPresenter`)
                // so it can still be seen when the thing that earned it happened inside a sheet.
                .achievementTracking()
                .onAppear { settings.fetchPrayerTimes() }
                //.statusBarHidden()
        }
        // No `.onChange` refreshes for settings here: each setting's own didSet performs its side
        // effects (`accentColor` and `hijriOffset` repaint widgets from Settings; `prayerCalculation`,
        // `travelingMode`, and `hanafiMadhab` recompute on every write path already - a blanket refresh
        // here would run a SECOND full forced fetch per flip and re-run the automatic detection with
        // checks ON right after the change, the exact override/spam bug the old one-shot flags papered
        // over). Phase transitions delegate to the one place that orchestrates them.
        .onChange(of: scenePhase) { phase in
            AppLifecycle.scenePhaseChanged(to: phase)
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
        // Seed the LIVE mirror at mount: `onChange` below only fires on transitions, and the mirror
        // defaults to `true` - without this, the launch window would read as revealed.
        .onAppear { AppReveal.revealed = (rootStage == .main) }
        .onChange(of: rootStage) { stage in
            // Keep the LIVE mirror in sync for escaping tasks (see `AppReveal`) - the environment value
            // above only reaches view bodies, and a frozen captured copy is what broke the review prompt.
            AppReveal.revealed = (stage == .main)
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
    // Deliberately NOT observing QuranData/QuranPlayer: this body never reads either, but the old
    // `@ObservedObject` subscriptions re-evaluated the ENTIRE TabView (all five tabs) on every
    // publish of the Quran load pipeline - the 10-property core-load batch, each loadState flip,
    // the verse-index landing - on the main thread, exactly while the under-cover warm needed it.
    // On older hardware those re-evals were a real slice of the launch. The launch screen already
    // shields itself the same way; the tab host must too. `warmUnderCover` reaches the singletons
    // directly.

    /// True while a launch/splash screen still covers the tabs (drives the under-cover warm below).
    let isCovered: Bool

    /// The in-app "Did you pray X?" answer: records the mark (on time or late) in the tracker and
    /// silences the rest of that nag cascade, exactly as the notification's own action buttons do.
    private func answerNagQuestion(mark: PrayerMark) {
        if let question = settings.pendingNagQuestion {
            settings.markPrayerPrayedFromNag(
                asked: question.prayerName,
                cascadePrayerName: question.cascadePrayerName,
                mark: mark
            )
        }
        settings.pendingNagQuestion = nil
    }

    private enum AppTab: String, Hashable { case adhan, quran, hadith, islam, settings }

    #if DEBUG
    /// Headless tab switching for verification runs: `Settings`' `-settingsProbe` posts this with the
    /// tab's raw value ("quran") so a probe can change a setting on one tab and then LOOK at another -
    /// the only way to reproduce cross-tab staleness without tap tooling.
    static let debugSwitchTabNotification = Notification.Name("AlIslamDebugSwitchTab")
    #endif

    // We land the user on Adhan, so Adhan is the initial tab and builds first. The Quran tab is realized during
    // `warmUnderCover()` - briefly selected so `TabView` builds and RETAINS its heavy view tree, then we settle
    // back on Adhan. All of this happens behind the launch cover, and the launch screen waits for it to finish
    // (see `LaunchWarmup`) before it reveals - so the user only ever sees a fully-built Adhan tab, and the first
    // tap on Quran reuses the warm tab instantly. No visible tab flip, no first-tap stall.
    @State private var selectedTab: AppTab = .adhan
    @State private var didWarm = false

    var body: some View {
        tabs
            #if DEBUG
            .onReceive(NotificationCenter.default.publisher(for: Self.debugSwitchTabNotification)) { note in
                if let raw = note.object as? String, let tab = AppTab(rawValue: raw) {
                    selectedTab = tab
                }
            }
            #endif
            // Tapping a nagging notification lands here with the question pending - asked at the TAB
            // level so it appears whichever tab the app reopens on.
            .confirmationDialog(
                "Did you pray \(settings.pendingNagQuestion?.prayerName ?? "this prayer")?",
                isPresented: Binding(
                    get: { settings.pendingNagQuestion != nil },
                    set: { if !$0 { settings.pendingNagQuestion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Yes, on time") { answerNagQuestion(mark: .onTime) }
                Button("Yes, but late") { answerNagQuestion(mark: .late) }
                Button("Not yet", role: .cancel) { settings.pendingNagQuestion = nil }
            } message: {
                Text("Answering yes marks it in the prayer tracker and stops the remaining reminders.")
            }
            // Launch warmups, one .task per app domain (like AppLifecycle's sections): when this
            // root is copied into a companion app, delete the domains it doesn't ship.
            // Shared: the tab walk behind the launch cover.
            .task { await warmUnderCover() }
            #if DEBUG
            // "-auditQiraahAlignment" - print the whole-Quran riwayah alignment audit once the
            // texts are in (see QiraahComparison.auditAlignments).
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-auditQiraahAlignment") else { return }
                while QuranData.shared.quran.count < 114 {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                }
                QiraahComparison.auditAlignments(quranData: QuranData.shared)
            }
            // "-dumpComparison 1:3" - print the qiraah comparison sheet's own rows for one ayah
            // (its copy text, built by the same resolver the rows render), since a sheet cannot be
            // scrolled headlessly.
            .task {
                let args = ProcessInfo.processInfo.arguments
                guard let i = args.firstIndex(of: "-dumpComparison"), i + 1 < args.count else { return }
                let parts = args[i + 1].split(separator: ":")
                guard parts.count == 2, let surah = Int(parts[0]), let ayah = Int(parts[1]) else { return }
                while QuranData.shared.quran.count < 114 {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                }
                print("COMPARISON DUMP \(surah):\(ayah)")
                print(AyahAISources.qiraahComparisonText(surahNumber: surah, ayahNumber: ayah))
                // The display riwayah's ayah map for this surah, compressed to where the offset
                // from Hafs numbering changes (merges, splits, skipped ayahs).
                let tag = Settings.Riwayah.canonicalTag(Settings.shared.displayQiraah)
                if !tag.isEmpty,
                   let alignment = QiraahComparison.alignment(surahID: surah, tag: tag, quranData: QuranData.shared),
                   let last = alignment.hafsRangeForRiwayah.keys.max() {
                    var lines: [String] = []
                    var lastOffset = 0
                    for r in 1...last {
                        guard let span = alignment.hafsRangeForRiwayah[r] else { lines.append("r\(r):none"); continue }
                        let offset = span.lowerBound - r
                        if offset != lastOffset || span.count > 1 || r == 1 {
                            lines.append("r\(r)->h\(span.lowerBound)\(span.count > 1 ? "-\(span.upperBound)" : "")")
                            lastOffset = offset
                        }
                    }
                    let hafsCount = QuranData.shared.surah(surah)?.numberOfAyahs ?? 0
                    let unmapped = hafsCount > 0 ? (1...hafsCount).filter { alignment.riwayahNumberForHafs[$0] == nil } : []
                    print("ALIGNMENT MAP \(tag) surah \(surah): \(lines.joined(separator: " ")) | Hafs ayahs with no ayah here: \(unmapped)")
                }
                print("COMPARISON DUMP done")
                fflush(stdout)
            }
            #endif
            // Al-Quran: the reader's font/page prewarm.
            .task { await QuranLaunchWarmup.prewarmAll() }
            // Al-Quran: the AI-search capability probe loads a disk-backed NLEmbedding model, off-main.
            // Deferred until AFTER the reveal: it's only needed once a search field gains focus, and
            // .utility is the QoS tier Low Power Mode throttles hardest - under the cover it competed
            // with the pack loads for the disk while the launch screen sat waiting.
            .task {
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { return }
                Task.detached(priority: .utility) { SemanticSearchEngine.prewarmOffMain() }
            }
            // Al-Hadith: today's card resolves under the cover (one book, so the Hadith tab realizes
            // with the card already there) - but the 17-book shelf sweep waits for the reveal. Parsing
            // ~51k rows on the main actor was the single heaviest launch item, competing with the tab
            // walk for the exact window the launch screen's reveal waits on; the extra beat also keeps
            // the finale + dissolve running on a free CPU. Books opened before the sweep reaches them
            // load on demand, same as always.
            .task {
                HadithStore.shared.prepareDailyHadith()
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                HadithStore.shared.prewarmBooks()
                // Tafsir ships inside the app now too - delete the pre-pack download cache (up to
                // ~345 MB for a reader who had downloaded every edition), once, off-main.
                TafsirStore.purgeLegacyDownloadCache()
            }
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
        await QuranData.shared.waitUntilCoreLoaded()
        if Task.isCancelled { LaunchWarmup.shared.markWarm(); return }

        // Walk every tab so TabView builds + RETAINS each view tree, heaviest (Quran) first with the longest
        // settle, then return to the Adhan landing tab. First selection of any tab later reuses the warm tree
        // instantly. This whole dance overlaps the launch screen's finale animation (which runs ~1.4s), so
        // warming the extra tabs costs no wall-clock time on the reveal.
        // Page mode gets a longer settle: entering the Quran tab then auto-pushes the mushaf, whose pager
        // (a UIPageViewController wrapping all ~604 page identities) is the single heaviest view realization
        // in the app. 350ms was enough for the surah list but not for the pager, so the leftover work ran at
        // the user's first REAL switch into the tab - the visible lag this hides behind the launch cover.
        selectedTab = .quran
        try? await Task.sleep(nanoseconds: settings.quranPageMode ? 900_000_000 : 350_000_000)
        // Low Power Mode / low-memory devices: walk ONLY the heavy Quran tab, then settle. The other
        // three tabs realize on their first real visit instead - a small first-tap beat there buys
        // ~280ms of fixed settles plus three tab-tree realizations off the throttled launch window,
        // which on old hardware was a visible slice of "loading forever."
        if !AppPerformance.shouldAvoidBroadPrewarm {
            selectedTab = .hadith
            try? await Task.sleep(nanoseconds: 80_000_000)
            selectedTab = .islam
            try? await Task.sleep(nanoseconds: 120_000_000)
            selectedTab = .settings
            try? await Task.sleep(nanoseconds: 80_000_000)
        }
        selectedTab = launchTab
        // Let the landing tab become the rendered tab again before we allow the reveal.
        try? await Task.sleep(nanoseconds: 80_000_000)

        LaunchWarmup.shared.markWarm()
    }

    /// The tab the app lands on after the under-cover warm. Always Adhan for users; a DEBUG launch argument
    /// lets UI automation land straight on a tab it wants to exercise (there is no other way to drive the
    /// simulator's tab bar from a test harness without an XCUITest target).
    private var launchTab: AppTab {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-launchTabQuran") { return .quran }
        if ProcessInfo.processInfo.arguments.contains("-launchTabHadith") { return .hadith }
        if ProcessInfo.processInfo.arguments.contains("-launchTabIslam") { return .islam }
        if ProcessInfo.processInfo.arguments.contains("-launchTabSettings") { return .settings }
        #endif
        return .adhan
    }

    // The broad Quran warm moved to `QuranLaunchWarmup.prewarmAll()` in the Quran module (MushafReader.swift);
    // the `.task` above calls it directly.

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Adhan", systemImage: "mecca", value: AppTab.adhan) {
                    AdhanView()
                }

                Tab("Quran", systemImage: "character.book.closed.ar", value: AppTab.quran) {
                    QuranView(isActiveTab: selectedTab == .quran)
                }

                Tab("Hadith", systemImage: "books.vertical", value: AppTab.hadith) {
                    HadithView()
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

                QuranView(isActiveTab: selectedTab == .quran)
                    .tabItem {
                        Image(systemName: "character.book.closed.ar")
                        Text("Quran")
                    }
                    .tag(AppTab.quran)

                HadithView()
                    .tabItem {
                        Image(systemName: "books.vertical")
                        Text("Hadith")
                    }
                    .tag(AppTab.hadith)

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

