import SwiftUI
import WidgetKit

@main
struct AlIslamApp: App {
    // Plain references, NOT `@StateObject`: the root used to observe all four stores, so every publish
    // of any of them - each of Settings' ~236 fields, every QuranPlayer progress tick, every step of the
    // Quran load pipeline - re-evaluated this body, the window, the tab host and all five mounted tab
    // roots. The stores are still handed down as environment objects for the views that want them;
    // what the root itself reads (accent, color scheme, first launch) comes from `RootAppearance`,
    // which publishes only when one of those changes.
    private let settings = Settings.shared
    private let quranData = QuranData.shared
    private let quranPlayer = QuranPlayer.shared
    private let namesData = NamesViewModel.shared
    @ObservedObject private var appearance = RootAppearance.shared

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @State private var isLaunching = true
    // Keeps the splash mounted through its fade-out (see `rootContent`).
    @State private var splashPresented = false

    init() {
        LaunchClock.mark("app init")
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
        return appearance.firstLaunch ? .splash : .main
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
                // Accent, tint, preferred color scheme and the `AppearanceEnvironment` every shared
                // chrome modifier reads - one live snapshot instead of ~400 per-view Settings subscribers.
                .appearanceEnvironment()
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
                // No `.onAppear { settings.fetchPrayerTimes() }` here: `AdhanView.onAppear` runs the launch
                // fetch a frame later (it is the initial tab), so this was a second full recompute on
                // the first-paint path.
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
    // Deliberately NOT observing Settings, QuranData or QuranPlayer: this body reads none of them, but
    // an `@ObservedObject` subscription re-evaluated the ENTIRE TabView (all five tabs) on every
    // publish - Settings alone publishes on every page turn, GPS fix and countdown tick, and the
    // Quran load pipeline's 10-property core-load batch landed exactly while the under-cover warm
    // needed the main thread. The one Settings field this body reads (`pendingNagQuestion`) arrives
    // through its own publisher below. `warmUnderCover` reaches the singletons directly.
    private let settings = Settings.shared
    @State private var pendingNagQuestion: Settings.PendingNagQuestion?

    /// True while a launch/splash screen still covers the tabs (drives the under-cover warm below).
    let isCovered: Bool

    /// The in-app "Did you pray X?" answer: records the mark (on time or late) in the tracker and
    /// silences the rest of that nag cascade, exactly as the notification's own action buttons do.
    private func answerNagQuestion(mark: PrayerMark) {
        if let question = pendingNagQuestion {
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
            .onReceive(settings.$pendingNagQuestion) { pendingNagQuestion = $0 }
            .confirmationDialog(
                "Did you pray \(pendingNagQuestion?.prayerName ?? "this prayer")?",
                isPresented: Binding(
                    get: { pendingNagQuestion != nil },
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
            // "-dumpPrintTokens" - write every riwayah's per-page ayah token counts (the printed-line
            // tables' ground truth, see MushafPagination.dumpPrintTokens) once the texts are in.
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-dumpPrintTokens") else { return }
                while QuranData.shared.quran.count < 114 {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                }
                MushafPagination.dumpPrintTokens(quranData: QuranData.shared)
            }
            // "-auditPrintLines" - compose every page of the displayed riwayah on its printed-line
            // table and report any page whose lines don't hold (see MushafPageRenderCache.auditPrintLines).
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-auditPrintLines") else { return }
                while QuranData.shared.quran.count < 114 {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                }
                let pages = MushafPagination.pages(quran: QuranData.shared.quran,
                                                   qiraah: Settings.shared.displayQiraahForArabic)
                MushafPageRenderCache.auditPrintLines(pages: pages)
            }
            // "-auditTajweedLegends" - print the tajweed legend's by-rule comparison index (the
            // compare screen is only reachable by tapping; see TajweedLegendView.auditRuleSections).
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-auditTajweedLegends") else { return }
                await Task.detached(priority: .utility) { TajweedLegendView.auditRuleSections() }.value
            }
            // "-auditPacks" - fingerprint every bundled pack and loose payload through the app's own
            // readers (see PackAudit); run before and after a repack and diff Documents/packaudit.txt.
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-auditPacks") else { return }
                await Task.detached(priority: .utility) { PackAudit.run() }.value
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
            // POST-REVEAL SCHEDULE. Everything below waits for the cover to lift and then takes its own
            // slot, so the sweeps never collide with each other or with the user's first taps (they used
            // to fire at 1.2 / 1.5 / 2.0 / 2.0 s and overlap). Keep the slots apart when adding one:
            //   +1.0 s  Hadith shelf sweep (main-actor slices, one book per runloop turn)
            //   +1.5 s  cross-language lexicon + Islam article corpus (detached, utility)
            //   +2.0 s  AI-search NLEmbedding probe (detached, utility)
            //   +2.5 s  the broad Quran surah sweep (detached, utility; `QuranLaunchWarmup`)
            //   +2.5 s  achievements catch-up (Achievements.swift)
            //   +3.0 s  the Quran AI corpus build or disk load (QuranView)
            //   +3.5 s  the 6,236-entry ayah search index (utility; full tier only, otherwise on demand)
            //
            // Al-Quran: the AI-search capability probe loads a disk-backed NLEmbedding model, off-main.
            // Deferred until AFTER the reveal: it's only needed once a search field gains focus, and
            // .utility is the QoS tier Low Power Mode throttles hardest - under the cover it competed
            // with the pack loads for the disk while the launch screen sat waiting.
            // Full tier only (Phase 5 step 2): on the reduced tier the model loads on the first search
            // field focus instead (`QuranSemanticCorpus.prepare` resolves it off-main before building).
            .task {
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled, !AppPerformance.shouldAvoidBroadPrewarm else { return }
                Task.detached(priority: .utility) { SemanticSearchEngine.prewarmOffMain() }
            }
            // Al-Quran: the ayah search index. Built ahead of the first search on the full tier so the
            // "Preparing ayah search" row never shows; on the reduced tier (Low Power Mode, a 3 GB
            // device) it is built on demand when the search field gains focus instead, because 300-800 ms
            // of CPU and ~10 MB for a search most sessions never run is exactly the launch work the
            // complaints are about. Skipped while the Quran is still loading; `ensureVerseSearchIndex`
            // re-checks.
            .task {
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 3_500_000_000)
                guard !Task.isCancelled, !AppPerformance.shouldAvoidBroadPrewarm else { return }
                await QuranData.shared.waitUntilCoreLoaded()
                guard !Task.isCancelled else { return }
                QuranData.shared.ensureVerseSearchIndex(priority: .utility)
            }
            // Shared: the cross-language highlight's lexicon (Quran-derived; the hadith and semantic
            // result rows read it) and the Islam article corpus, inflated off-main after the reveal.
            // These fired from the Quran, Hadith and Islam tab roots' own tasks, and the under-cover
            // walk realizes all three, so they landed inside the launch window every time.
            .task {
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                await QuranData.shared.waitUntilCoreLoaded()
                guard !Task.isCancelled else { return }
                // The ~18k-key lexicon is a full-tier luxury (Phase 5 step 1): on the reduced tier the
                // first cross-language query builds it itself (`lexiconIfReady` kicks the build once).
                if !AppPerformance.shouldAvoidBroadPrewarm {
                    Task.detached(priority: .utility) { CrossLanguageWordHighlight.prewarmLexicon() }
                }
                IslamArticleSearchModel.prewarm()
            }
            // Al-Hadith: today's card resolves under the cover (one book, so the Hadith tab realizes
            // with the card already there) - but the 17-book shelf sweep waits for the reveal. Parsing
            // ~51k rows on the main actor was the single heaviest launch item, competing with the tab
            // walk for the exact window the launch screen's reveal waits on; the extra beat also keeps
            // the finale + dissolve running on a free CPU. Books opened before the sweep reaches them
            // load on demand, same as always. This is the ONLY caller of `prewarmBooks` (the Hadith
            // tab's own copy ran un-gated during the walk).
            .task {
                HadithStore.shared.prepareDailyHadith()
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                HadithStore.shared.prewarmBooks()
                // Tafsir ships inside the app now too - delete the pre-pack download cache (up to
                // ~345 MB for a reader who had downloaded every edition), once, off-main.
                TafsirStore.purgeLegacyDownloadCache()
            }
    }

    /// Build + retain every tab behind the launch cover, settle back on Adhan, then signal `LaunchWarmup`
    /// that the UI is ready to reveal. Runs once. If we were mounted already-uncovered (not a cold launch),
    /// there's nothing to hide, so we just mark warm immediately.
    ///
    /// The walk runs in FRONT of the finale, never under it. It was tried under the finale (2026-09-04):
    /// SwiftUI drives the finale's springs, blur and shimmer from the main thread, so a 300 ms tab build
    /// under them froze the bloom and then jumped it - exactly the finale change that is not allowed. What
    /// the walk can overlap instead is the Quran text decode: the three light tabs are realized while that
    /// runs on a background thread and the main thread would otherwise idle, and only the Quran tab waits
    /// for the text. Together with dropping the old 80-120 ms settles between tabs this takes ~700 ms off
    /// a cold launch on the 17 Pro simulator with the finale untouched.
    @MainActor
    private func warmUnderCover() async {
        guard !didWarm else { return }
        didWarm = true

        guard isCovered else { LaunchWarmup.shared.markWarm(); return }

        // Never before the cover's own first frame: a tab build in the same run-loop pass would sit
        // between the window and the icon.
        await LaunchWarmup.shared.waitUntilCoverUp(maxWaitNanos: 1_000_000_000)
        try? await Task.sleep(nanoseconds: 16_000_000)
        if Task.isCancelled { LaunchWarmup.shared.markWarm(); return }

        // 1) The light tabs, while the Quran text is still decoding off-main. One frame between tabs,
        //    not a settle: a selection change realizes the tab synchronously in the next run-loop pass
        //    (which is what a sleep's resume waits behind anyway), so the old settles were pure waiting.
        //    Low Power Mode / low-memory devices: walk ONLY the heavy Quran tab. The other three realize
        //    on their first real visit instead - a small first-tap beat there buys three tab-tree
        //    realizations off the throttled launch window, which on old hardware was a visible slice of
        //    "loading forever."
        if !AppPerformance.shouldAvoidBroadPrewarm {
            for tab in [AppTab.hadith, .islam, .settings] {
                selectedTab = tab
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
        LaunchClock.mark("light tabs walked")

        // 2) The heavy Quran tab, once the real surah list can be built (not the empty loading state).
        await QuranData.shared.waitUntilCoreLoaded()
        LaunchClock.mark("quran core loaded")
        if Task.isCancelled { LaunchWarmup.shared.markWarm(); return }

        // Readiness, not a fixed settle: the tab reports its first body (list mode) or its pushed reader
        // (page mode, where the pager wrapping ~604 page identities is the single heaviest view
        // realization in the app) through `LaunchWarmup.markQuranTabLaidOut`, and the old sleeps
        // (350 ms list / 900 ms page mode) are now only the cap for a tab that never reports. One more
        // frame after the report lets that layout commit before the tab is left.
        selectedTab = .quran
        await LaunchWarmup.shared.waitUntilQuranTabLaidOut(
            maxWaitNanos: settings.quranPageMode ? 900_000_000 : 350_000_000
        )
        try? await Task.sleep(nanoseconds: 32_000_000)
        LaunchClock.mark("quran tab settled")

        // 3) Back on the landing tab; let it become the rendered tab again before the reveal.
        selectedTab = launchTab
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

