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

        // The daily corpora (Reminder of the Day, Word of the Day: 20 + 16 KB of xz, a few ms of parse
        // off-main) start now, before the under-cover tab walk builds the Islam and Quran roots that
        // read them, so neither root ever parses on the main thread (Tilawa Guide, Phase 1 step 1).
        DailyReminderStore.shared.prewarm()
        WordOfDayStore.prewarm()

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
                // iPad and Mac read one Dynamic Type step larger (see `regularIdiomTypeBoost`).
                .regularIdiomTypeBoost()
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
    /// The once-a-day Reminder of the Day sheet; the store publishes once a day at most.
    @ObservedObject private var dailyReminders = DailyReminderStore.shared

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
            // A Sunnah reminder's tap (or its "Open" row anywhere in Settings) lands on the Quran
            // tab; the tab's own `.onReceive` opens the reader from there.
            .onReceive(AppNavigation.shared.$pendingQuran) { target in
                if target != nil { selectedTab = .quran }
            }
            // A Reminder of the Day card's "Open" lands on the Islam tab (or the Hadith tab); the
            // Islam tab's own `.onReceive` pushes the resource from there.
            .onReceive(AppNavigation.shared.$pendingIslam) { target in
                guard let target else { return }
                if case .hadithTab = target {
                    selectedTab = .hadith
                    AppNavigation.shared.pendingIslam = nil
                } else {
                    selectedTab = .islam
                }
            }
            .sheet(item: $dailyReminders.sheetEntry) { entry in
                DailyReminderSheet(entry: entry)
            }
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
            // Shared: the once-a-day Reminder of the Day sheet, after the reveal and a beat for the
            // landing tab to settle. It used to be timed from the end of the walk, which put its
            // slide-up under the finale; and the scene-phase call at launch used to be able to present
            // it under the cover. The store itself refuses while the cover is up, while a prayer nag
            // is pending or while a notification/deep-link destination is, and only stamps the day
            // when it actually presents, so the nag's dismissal below simply asks again.
            .task {
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 600_000_000)
                guard !Task.isCancelled else { return }
                #if DEBUG
                let force = ProcessInfo.processInfo.arguments.contains("-openDailyReminder")
                #else
                let force = false
                #endif
                DailyReminderStore.shared.presentSheetIfDue(force: force)
            }
            .onChange(of: pendingNagQuestion == nil) { nagClosed in
                if nagClosed { DailyReminderStore.shared.presentSheetIfDue() }
            }
            #if DEBUG
            // "-rankedBench <query>": the Quran ranked lane timed in isolation, three runs at reveal
            // + 12 s when the launch's own sweeps are over (the handed-off search at +2.5 s runs
            // beside the AI corpus and index builds, which inflates its "RANKED quran" line).
            .task {
                let arguments = ProcessInfo.processInfo.arguments
                guard let index = arguments.firstIndex(of: "-rankedBench"), arguments.indices.contains(index + 1) else { return }
                let term = arguments[index + 1]
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 12_000_000_000)
                let quranData = QuranData.shared
                quranData.ensureVerseSearchIndex()
                for await ready in quranData.$isVerseSearchReady.values where ready { break }
                guard let snapshot = quranData.verseSearchSnapshot() else { return }
                Task.detached(priority: .userInitiated) {
                    for _ in 0..<3 { _ = QuranRankedSearch.search(term, snapshot: snapshot, limit: 6) }
                    NSLog("RANKED BENCH done %@", term)
                }
            }
            // "-dailyRolloverProbe": the daily boundary as the app computes it and as the widget would
            // from the written Fajr table, side by side in the log (Tilawa Guide, Phase 1 step 11).
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-dailyRolloverProbe") else { return }
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                Settings.shared.logDailyRolloverProbe()
            }
            #endif
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
            // "-exportHadithVocabulary" - walk every book's English search folds for the ranked
            // lane's typo vocabulary and write Documents/hadith-vocabulary.txt (first line: the
            // shelf fingerprint), for Scripts/build_hadith_vocabulary.py ->
            // Resources/Data/Hadith/HadithVocabulary.txt.xz. Re-run after any .hpk changes; the
            // verifier and "-auditPacks" say when the shipped list no longer matches the shelf.
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-exportHadithVocabulary") else { return }
                await AppReveal.waitUntilRevealed()
                var books: [HadithBookData] = []
                for book in HadithCatalogBook.all {
                    if let data = await HadithStore.shared.openOffMain(book, priority: .utility) { books.append(data) }
                }
                let opened = books
                await Task.detached(priority: .utility) { HadithVocabulary.exportList(books: opened) }.value
            }
            // "-duaSlotProbe" - the seeded dua slots (Tilawa Guide, decision D), printed twice;
            // run it twice on the same day with "-extraSeed" and diff the lines.
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-duaSlotProbe") else { return }
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                ExtraRemindersStore.logDuaSlotProbe()
            }
            // "-auditPacks" - fingerprint every bundled pack and loose payload through the app's own
            // readers (see PackAudit); run before and after a repack and diff Documents/packaudit.txt.
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-auditPacks") else { return }
                await Task.detached(priority: .utility) { PackAudit.run() }.value
            }
            // "-exportSemanticPacks" - build (or load) the Quran and all-books hadith AI corpora and
            // write them as bundle packs to Documents/semantic-packs/<id>.svec, for
            // Resources/Data/Semantic (see SemanticPackExport). Re-run after quran.qpk or any .hpk
            // changes; "-auditSemanticPacks" logs VALID or STALE for the shipped packs.
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-exportSemanticPacks") else { return }
                await AppReveal.waitUntilRevealed()
                while QuranData.shared.quran.count < 114 {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                }
                await SemanticPackExport.run()
            }
            // "-exportQiraatPlaces" - compute where every riwayah differs from Hafs (the Qiraat
            // Explorer's index) and write Documents/qiraat-places.json, for
            // Resources/Data/Quran/QiraatPlaces.json.xz (see QiraatPlacesExport). Run with
            // "-seedBool betaQiraatEnabled=1" so the beta riwayat's texts are read too.
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-exportQiraatPlaces") else { return }
                await AppReveal.waitUntilRevealed()
                while QuranData.shared.quran.count < 114 {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                }
                await QiraatPlacesExport.run()
            }
            // "-qiraatBench [places]" - time the Qiraat Explorer's Next tap over the real place
            // list, alignment split from the resolve and diff (see QiraatExplorerBench). Build with
            // SWIFT_OPTIMIZATION_LEVEL=-O first; -Onone reads 2 to 30x slow depending on the phase.
            .task {
                let args = ProcessInfo.processInfo.arguments
                guard let index = args.firstIndex(of: "-qiraatBench") else { return }
                let places = args.indices.contains(index + 1) ? Int(args[index + 1]) ?? 60 : 60
                await AppReveal.waitUntilRevealed()
                while QuranData.shared.quran.count < 114 {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                }
                QiraatExplorerBench.run(places: places)
            }
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-auditSemanticPacks") else { return }
                while QuranData.shared.quran.count < 114 {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                }
                SemanticPackExport.audit()
            }
            // "-selfShot <name>" (+ "-selfShotDelay", "-windowSize WxH") - render the key window to
            // Documents/selfshots/<name>.png and exit; the Mac (Designed for iPad) screenshot path,
            // see DebugSelfShot.
            .task { await DebugSelfShot.handleLaunchArguments() }
            #if DEBUG
            // "-tsanSelfTest": prove a Thread Sanitizer build reports (see SanitizerSelfTest).
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-tsanSelfTest") else { return }
                SanitizerSelfTest.race()
            }
            #endif
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
            //   +1.5 s  the reminders' launch pass (one pending fetch, the adds off-main; ReminderKinds.swift)
            //   +2.0 s  AI-search NLEmbedding probe (detached, utility)
            //   +2.5 s  the broad Quran surah sweep (detached, utility; `QuranLaunchWarmup`)
            //   +2.5 s  achievements catch-up (Achievements.swift)
            //   +3.0 s  the Quran AI corpus build or disk load (QuranView)
            //   +3.5 s  the 6,236-entry ayah search index (utility; full tier only, otherwise on demand)
            //   +4.0 s  the ranked search's corpus lanes, once the index is there (utility; full tier only)
            //   +4.5 s  the hadith typo vocabulary (a file read, or once a walk of the packs; full tier only)
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
            // Al-Quran: the ranked search's corpus lanes (6,236 folds, stems, skeletons), right after
            // the verse index the +3.5 s task builds, so the first ranked query never builds them
            // under the reader's thumb. Full tier only; the reduced tier builds them on the search
            // field's focus (`QuranView.prewarmRankedLanes`).
            .task {
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                guard !Task.isCancelled, !AppPerformance.shouldAvoidBroadPrewarm else { return }
                let quranData = QuranData.shared
                for await ready in quranData.$isVerseSearchReady.values where ready { break }
                guard !Task.isCancelled, let snapshot = quranData.verseSearchSnapshot() else { return }
                Task.detached(priority: .utility) { QuranRankedSearch.prewarmLanes(snapshot: snapshot) }
            }
            // Al-Hadith: the ranked lane's typo vocabulary, off the first search's own path. The
            // shipped list first (decision B of the Tilawa Guide: one small xz inflate, no book
            // opened); the walk of every book's search folds only when that list is missing or was
            // built for other packs. Full tier only; the books are the shelf sweep's, open by now.
            .task {
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 4_500_000_000)
                guard !Task.isCancelled, !AppPerformance.shouldAvoidBroadPrewarm else { return }
                let shipped = await Task.detached(priority: .utility) { HadithVocabulary.shared.prepareFromBundle() }.value
                if shipped { return }
                guard !Task.isCancelled else { return }
                var books: [HadithBookData] = []
                for book in HadithCatalogBook.all {
                    guard !Task.isCancelled else { return }
                    if let data = await HadithStore.shared.openOffMain(book, priority: .utility) { books.append(data) }
                }
                HadithVocabulary.shared.prepare(books: books)
            }
            // Shared: the reminders' one launch pass (the Sunnah presets re-added, the extra kinds
            // rebuilt only when their inputs changed), off the AppDelegate's reveal wait where it
            // used to run twice.
            .task {
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                await ReminderScheduler.rearmAfterLaunch()
            }
            #if DEBUG
            // "-simulateReminderTap surah:67" (or "ayah:2:285", "open", "hadith"): what a reminder's
            // or a daily card's tap does, two seconds after the reveal, from whichever tab the launch
            // landed on (Tilawa Guide, Phase 2 step 9).
            .task {
                let arguments = ProcessInfo.processInfo.arguments
                guard let index = arguments.firstIndex(of: "-simulateReminderTap"),
                      arguments.indices.contains(index + 1) else { return }
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if arguments[index + 1] == "hadith" {
                    AppNavigation.shared.openIslam(.hadithTab)
                } else if let target = QuranOpenTarget(encoded: arguments[index + 1]) {
                    AppNavigation.shared.open(target)
                }
            }
            #endif
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

        // 3) Back on the landing tab; let it become the rendered tab again before the reveal. A
        // launch from a Sunnah reminder's tap lands on the Quran tab instead.
        selectedTab = AppNavigation.shared.pendingQuran != nil ? .quran : launchTab
        // A launch that arrived through a notification or a deep link keeps its own destination and
        // skips the daily sheet for the day; otherwise the post-reveal task in `body` presents it.
        if AppNavigation.shared.pendingQuran != nil || AppNavigation.shared.pendingIslam != nil {
            DailyReminderStore.shared.skipSheetToday()
        }
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

#if DEBUG
import UIKit
/// "-selfShot <name>": renders the key window into Documents/selfshots/<name>.png (plus a .txt with
/// the window size, scale and idiom) and exits. The only screenshot path for the Mac (Designed for
/// iPad) build: `screencapture` needs a Screen Recording grant the build harness does not have, and
/// `simctl io screenshot` is simulator-only. "-selfShotDelay <secs>" (default 6) waits for the reveal
/// and any launch-argument navigation; "-windowSize WxH" pins the window scene to that size first
/// (a Mac window resizes to it; iPhone and iPad ignore it); "-landscape" rotates the interface
/// (iOS 16+), the only way to see an iPad simulator in landscape headlessly.
enum DebugSelfShot {
    static func handleLaunchArguments() async {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-landscape") {
            // "-landscape": rotate the interface (iOS 16+); the simulator has no rotate command.
            await rotateToLandscape(after: 0.3)
        }
        if let i = args.firstIndex(of: "-landscapeAfter"), i + 1 < args.count, let secs = Double(args[i + 1]) {
            // "-landscapeAfter <secs>": rotate once the screen is already up, the headless stand-in for
            // a Mac window being resized after a page has rendered.
            Task { await rotateToLandscape(after: secs) }
        }
        if let i = args.firstIndex(of: "-windowSize"), i + 1 < args.count {
            let parts = args[i + 1].lowercased().split(separator: "x")
            if parts.count == 2, let w = Double(parts[0]), let h = Double(parts[1]) {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run { pinWindowSize(CGSize(width: w, height: h)) }
            }
        }
        guard let i = args.firstIndex(of: "-selfShot"), i + 1 < args.count else { return }
        var delay: Double = 6
        if let d = args.firstIndex(of: "-selfShotDelay"), d + 1 < args.count, let v = Double(args[d + 1]) {
            delay = v
        }
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        await MainActor.run { capture(name: args[i + 1]) }
    }

    /// Waits for a foreground window scene (a cold launch may not have one yet when the root task
    /// starts, which left the earlier fixed 300 ms sleep rotating nothing), then asks for landscape.
    private static func rotateToLandscape(after seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(max(seconds, 0) * 1_000_000_000))
        for _ in 0..<40 {
            let done = await MainActor.run { () -> Bool in
                guard #available(iOS 16.0, *) else { return true }
                let active = scenes().filter { $0.activationState == .foregroundActive }
                guard !active.isEmpty else { return false }
                for scene in active {
                    scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
                }
                return true
            }
            if done { return }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    @MainActor
    private static func scenes() -> [UIWindowScene] {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    }

    @MainActor
    private static func pinWindowSize(_ size: CGSize) {
        for scene in scenes() {
            scene.sizeRestrictions?.minimumSize = size
            scene.sizeRestrictions?.maximumSize = size
        }
    }

    @MainActor
    private static func capture(name: String) {
        let all = scenes()
        guard let scene = all.first(where: { $0.activationState == .foregroundActive }) ?? all.first,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else {
            print("SELFSHOT \(name) no window"); exit(1)
        }
        let bounds = window.bounds
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.screen.scale
        let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in
            window.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("selfshots")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? image.pngData()?.write(to: dir.appendingPathComponent("\(name).png"))
        let info = "bounds=\(Int(bounds.width))x\(Int(bounds.height)) scale=\(format.scale) "
            + "idiom=\(UIDevice.current.userInterfaceIdiom.rawValue) "
            + "mac=\(ProcessInfo.processInfo.isiOSAppOnMac) "
            + "sizeClass=\(window.traitCollection.horizontalSizeClass.rawValue)/\(window.traitCollection.verticalSizeClass.rawValue)"
        try? info.write(to: dir.appendingPathComponent("\(name).txt"), atomically: true, encoding: .utf8)
        print("SELFSHOT \(name) \(info)")
        exit(0)
    }
}
#endif
