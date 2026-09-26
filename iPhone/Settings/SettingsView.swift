import SwiftUI

#if os(iOS)
/// One row of the Settings tab's search index. Each entry deep-links to the SCREEN that owns the
/// setting; the path caption shows where the row will land, so "highlight allah" finds both the Quran
/// and the Hadith toggles.
///
/// The index is COMPOSED from per-screen entry lists declared as extensions of this type AT THE BOTTOM
/// OF THE FILE THAT OWNS EACH SCREEN (`quranEntries` in SettingsQuranView.swift, `hadithEntries` in
/// SettingsHadithView.swift, `adhanEntries`/`notificationEntries`/`prayerCalculationEntries` in
/// SettingsAdhanView.swift). Adding or removing a setting means editing the list in the SAME file as
/// the control - there is no central registry to remember.
struct SettingsSearchEntry: Identifiable {
    let title: String
    let path: String
    let keywords: String
    let destination: Destination
    /// A control its screen shows only with Advanced Settings on. The result row says so, and
    /// opening it turns the switch on (`revealsAdvancedSettings`), so a search never lands on a
    /// screen that hides the very thing that was searched for.
    var advanced: Bool = false

    var id: String { path + title }

    enum Destination {
        case notifications
        case notificationReminders
        case prayerSettings
        /// The Prayer Tracker screen itself (Al-Adhan tab), which owns its own settings since
        /// 2026-09-18 - not a Settings page at all, but the search must still reach the toggle.
        case prayerTracker
        case travelingMode
        case prayerCalculation
        case skyColors
        case quranSettings
        case reciters
        case hadithSettings
        /// Islam Settings: the fourth area, for everything outside the Quran, the prayer times and
        /// the hadith books (the Arabic face, the alphabet controls, the Al-Islam tab itself).
        case islamSettings
        case appearance
        /// About You: who the reader says they are, and the Start Here guide it switches on.
        case aboutYou
        #if HAS_ICLOUD_BACKUP
        /// iCloud Backup: this device's profile, the others in the account, restore. Al-Islam's
        /// alone: the companion apps define no `HAS_ICLOUD_BACKUP` (sync-manifests, FLAG_SKIP).
        case cloudBackup
        #endif
        /// Tips & Tricks: one area's list, or all six behind one door when nil.
        case tips(TipArea?)
        case credits
        /// One credited source on the Credits page (`CreditItem.id`): the page opens scrolled to it.
        case credit(String)
        /// A page's own sub-screen, pushed directly (the page enums live in SettingsSearch.swift).
        case notificationsPage(SettingsNotificationsPage)
        case prayerPage(SettingsAdhanPage)
        case quranPage(SettingsQuranPage)
        case hadithPage(SettingsHadithPage)
        case islamPage(SettingsIslamPage)
        case appearancePage(SettingsAppearancePage)

        /// The chip icon a search result renders with - derived here so entries never repeat it.
        var icon: String {
            switch self {
            case .notifications: return "bell.badge.fill"
            case .notificationReminders: return "bell.and.waves.left.and.right.fill"
            case .prayerSettings: return "safari.fill"
            case .prayerTracker: return "checklist"
            case .travelingMode: return "airplane"
            case .prayerCalculation: return "globe.europe.africa.fill"
            case .skyColors: return "sunset.fill"
            case .quranSettings: return "character.book.closed.ar"
            case .reciters: return "headphones"
            case .hadithSettings: return "text.book.closed.fill"
            case .islamSettings: return "moon.stars.fill"
            case .appearance: return "paintpalette.fill"
            case .aboutYou: return "person.crop.circle.fill"
            #if HAS_ICLOUD_BACKUP
            case .cloudBackup: return "icloud.fill"
            #endif
            case .tips: return "lightbulb.fill"
            case .credits: return "scroll.fill"
            case .credit: return "link"
            case .notificationsPage(let page): return page.systemImage
            case .prayerPage(let page): return page.systemImage
            case .quranPage(let page): return page.systemImage
            case .hadithPage(let page): return page.systemImage
            case .islamPage(let page): return page.systemImage
            case .appearancePage(let page): return page.systemImage
            }
        }
    }
}
#endif

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared

    @State private var showingCredits = false
    @State private var selectedDestination: SettingsDestination? = SettingsView.defaultDestination
    /// Bumped when the SAME sidebar row is re-tapped: the detail stack is keyed on it, so the tap
    /// always lands (pops the section back to its root) instead of dying against unchanged state.
    @State private var settingsDetailRefreshToken = 0
    @State private var showResetConfirmation = false
    @State private var confirmEraseEverything = false
    @State private var settingsSearchText = ""

    #if os(iOS)
    /// The featured card that was tapped. ONE programmatic push serves every card, because several
    /// links inside one List row all fire on any tap (see `SettingsSpotlightSection`).
    @State private var spotlightTarget: AppTip?
    @State private var openSpotlight = false

    /// The tile tapped on the three-up Your Progress / About You / iCloud Backup row, and its push.
    @State private var profileDoor: ProfileTilesSection.Door?
    @State private var openProfileDoor = false

    /// `pushDestination` is `navigationDestination(isPresented:)`, which needs iOS 16.
    private static var canPushProgrammatically: Bool {
        if #available(iOS 16.0, *) { return true }
        return false
    }
    #endif

    #if os(iOS)
    // Split-view multitasking (Slide Over, 1/3 Split View, narrow Stage Manager windows) makes an iPad
    // window compact - the sidebar/detail layout must collapse to the iPhone shape there, or the split
    // collapses onto the pre-selected detail with no way back to the list.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Two side-by-side columns only when the window is actually wide enough - the Hadith tab's rule.
    private var usesColumnNavigation: Bool {
        guard #available(iOS 16.0, *) else { return false }
        guard horizontalSizeClass == .regular else { return false }
        return UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac
    }
    #endif

    #if os(iOS)
    // Semantic settings search: "make text bigger" finds the font-size controls even though no
    // entry contains those words. Tiny corpus (the hand-authored index), same engine + UX grammar
    // as every other AI search surface.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var settingsAIHits: [SettingsSearchEntry] = []
    @State private var settingsAISearchTask: Task<Void, Never>?

    private static let settingsSemanticCorpusID = "settings-en"

    private func prepareSettingsSemanticCorpus() {
        guard SemanticSearchEngine.isSupported, !semanticEngine.isReady(Self.settingsSemanticCorpusID) else { return }
        let texts = SettingsSearchEntry.all.map { "\($0.title) \($0.path) \($0.keywords)" }
        let keys = SettingsSearchEntry.all.map(\.id)
        semanticEngine.prepare(corpusID: Self.settingsSemanticCorpusID, version: "v1-\(texts.count)", texts: texts, keys: keys)
    }

    private func runSettingsAISearch(query: String) {
        settingsAISearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SemanticSearchEngine.isSupported, trimmed.count >= 3, !trimmed.containsArabicScript else {
            if !settingsAIHits.isEmpty { settingsAIHits = [] }
            return
        }
        prepareSettingsSemanticCorpus()

        settingsAISearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let results = await semanticEngine.search(corpusID: Self.settingsSemanticCorpusID, query: trimmed, limit: 8)
            guard !Task.isCancelled else { return }
            let keys = await MainActor.run { semanticEngine.corpus(Self.settingsSemanticCorpusID)?.itemKeys }
            await MainActor.run {
                guard trimmed == settingsSearchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                let byID = Dictionary(uniqueKeysWithValues: SettingsSearchEntry.all.map { ($0.id, $0) })
                settingsAIHits = results.compactMap { result -> SettingsSearchEntry? in
                    if let keys, keys.indices.contains(result.index) { return byID[keys[result.index]] }
                    guard SettingsSearchEntry.all.indices.contains(result.index) else { return nil }
                    return SettingsSearchEntry.all[result.index]
                }
            }
        }
    }
    #endif
    /// Apple Music-style: true while scrolling down, minimizing the floating search bar.
    @State private var barsCollapsed = false

    /// The destination shown when nothing is explicitly selected (single source of truth). Only the
    /// iPad/Mac split view opens on a pre-selected section, and it opens on Islam Settings, the one
    /// area that covers the whole app rather than one tab (Abu, 2026-09-25).
    private static let defaultDestination: SettingsDestination = .islamSettings

    private enum SettingsDestination: Hashable {
        case notification
        case prayerSettings
        case quranSettings
        case hadithSettings
        case islamSettings
        /// A spotlight card's screen in the iPad/Mac detail column, by tip id. A SELECTION like the
        /// rows, deliberately: no row is tagged with it, so the hub rows show no highlight while a
        /// card fills the detail (the card wears the ring instead), and every card-to-card switch is
        /// a selection change, the one thing that resets the detail column's stack. Held as separate
        /// state, only the detail's `.id` moved, and the previous card's pushed page (Nagging Mode,
        /// opened a beat after its root) stayed on screen over the new card's.
        case spotlight(String)
    }

    /// What re-identifies the iPad detail stack: the selected destination, or a re-tap of the same
    /// row (the token). One value drives both `.id` and the swap animation.
    private struct SettingsDetailIdentity: Hashable {
        let destination: SettingsDestination
        let token: Int
    }

    private var settingsDetailIdentity: SettingsDetailIdentity {
        SettingsDetailIdentity(
            destination: selectedDestination ?? Self.defaultDestination,
            token: settingsDetailRefreshToken
        )
    }

    /// Selecting a split destination, shared by the hub rows and the spotlight cards: re-tapping what
    /// is already selected bumps the token instead of doing nothing.
    private func selectSplitDestination(_ value: SettingsDestination) {
        withAnimation(.easeInOut) {
            if selectedDestination == value {
                settingsDetailRefreshToken &+= 1
            } else {
                selectedDestination = value
            }
        }
    }

    #if os(iOS)
    /// The spotlight card filling the split detail, if one is (see `SettingsDestination.spotlight`).
    private var splitSpotlightID: String? {
        if case let .spotlight(id) = selectedDestination { return id }
        return nil
    }
    #endif

    var body: some View {
        navigationContainer
    }

    private var navigationContainer: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                if usesColumnNavigation {
                    NavigationSplitView {
                        settingsSplitList
                    } detail: {
                        // Detail gets its own NavigationStack so the sub-screen NavigationLinks
                        // (e.g. Quran settings → Recitation) push within the detail column instead of
                        // replacing the whole split. `.id` rebuilds it when the sidebar selection changes.
                        NavigationStack {
                            settingsSplitDetail
                        }
                        .id(settingsDetailIdentity)
                        .animation(.easeInOut(duration: 0.25), value: settingsDetailIdentity)
                    }
                } else {
                    NavigationStack {
                        settingsList
                    }
                }
            } else {
                NavigationView {
                    settingsList
                }
                .navigationViewStyle(.stack)
            }
            #else
            NavigationView {
                settingsList
            }
            .navigationViewStyle(.stack)
            #endif
        }
    }

    // ONE list body + ONE chrome for both shapes (iPhone stack and iPad sidebar). The `List`
    // wrappers must differ (the sidebar needs `List(selection:)` for its highlight), but everything
    // inside and around them is shared - so an edit here can never fork between iPhone and iPad.

    private var settingsList: some View {
        #if os(iOS)
        // (The Classic Look switch used to be scrolled to here by "-scrollToClassicLook". It lives on
        // Appearance's Look and Feel page now: "-settingsOpen appearanceLook" lands on it.)
        settingsListChrome(
            List { settingsListContent(split: false) },
            disableNowPlayingInset: false
        )
        #else
        List { settingsListContent(split: false) }
            .navigationTitle("Settings")
            .applyConditionalListStyle()
        #endif
    }

    #if os(iOS)
    @available(iOS 16.0, *)
    private var settingsSplitList: some View {
        settingsListChrome(
            // The detail column's screens show the Now Playing bar; suppress the sidebar's copy or
            // recitation puts one identical bar in EACH column (the Quran tab's rule).
            List(selection: $selectedDestination) { settingsListContent(split: true) },
            disableNowPlayingInset: true
        )
    }

    /// The floating search bar, scroll-minimize, title, and wash - applied identically to both shapes.
    private func settingsListChrome<L: View>(_ list: L, disableNowPlayingInset: Bool) -> some View {
        list
            .collapseBarsOnScroll($barsCollapsed)
            .adaptiveSafeArea(edge: .bottom) {
                settingsSearchBarInset
            }
            .navigationTitle("Settings")
            .applyConditionalListStyle(disableNowPlayingInset: disableNowPlayingInset)
            .pushDestination(isPresented: $openProfileDoor) {
                if let profileDoor { profileDoor.destination }
            }
            .pushDestination(isPresented: $openSpotlight) {
                if let tip = spotlightTarget, let destination = tip.destination {
                    searchDestinationView(destination)
                        .revealsAdvancedSettings(tip.advanced)
                }
            }
            #if DEBUG
            // `-openCredit <CreditItem.id>`: what a credit row in the search results does, headlessly.
            .debugPushDestination(isPresented: $debugOpenProfile) { ProfileView() }
            .debugPushDestination(isPresented: $debugOpenCredit) {
                if let id = Self.debugCreditID { CreditsView(presentedAsSheet: false, scrollTo: id) }
            }
            // `-settingsOpen prayer|notifications|quran|hadith|appearance`: that settings page pushed on
            // launch, so a page's own search bar ("-settingsPageSearch <q>") and rows can be screenshotted.
            .debugPushDestination(isPresented: $debugOpenSettingsPage) {
                if let destination = Self.debugSettingsPage { searchDestinationView(destination) }
            }
            .onAppear {
                // `-settingsSearch <query>` seeds the search a moment after the tab appears; `-showCredits`
                // presents the Credits sheet. Typing and tapping are not scriptable in the simulator.
                if let seeded = Self.launchValue("-settingsSearch"), settingsSearchText.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { settingsSearchText = seeded }
                }
                if ProcessInfo.processInfo.arguments.contains("-showCredits") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showingCredits = true }
                }
                if Self.debugCreditID != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { debugOpenCredit = true }
                }
                if ProcessInfo.processInfo.arguments.contains("-openProfile") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenProfile = true }
                }
                if Self.debugSettingsPage != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenSettingsPage = true }
                }
            }
            #endif
    }

    #if DEBUG
    @State private var debugOpenCredit = false
    @State private var debugOpenProfile = false
    @State private var debugOpenSettingsPage = false

    private static var debugCreditID: String? { launchValue("-openCredit") }

    private static var debugSettingsPage: SettingsSearchEntry.Destination? {
        switch launchValue("-settingsOpen") {
        case "prayer": return .prayerSettings
        case "prayerSky": return .prayerPage(.sky)
        case "notifications": return .notifications
        case "quran": return .quranSettings
        case "hadith": return .hadithSettings
        case "islam": return .islamSettings
        // The Islam sub-pages, so each can be screenshotted without a tap.
        case "islamArabic": return .islamPage(.arabicText)
        case "islamAlphabet": return .islamPage(.alphabet)
        case "islamLibraries": return .islamPage(.libraries)
        case "islamReminders": return .islamPage(.sunnahReminders)
        case "prayerReminders": return .notificationsPage(.prayerReminders)
        case "nagging": return .notificationsPage(.naggingMode)
        case "aboutYou": return .aboutYou
        #if HAS_ICLOUD_BACKUP
        case "cloudBackup": return .cloudBackup
        #endif
        case "tips": return .tips(nil)
        case "tipsAdhan": return .tips(.adhan)
        case "tipsNotifications": return .tips(.notifications)
        case "tipsQuran": return .tips(.quran)
        case "tipsHadith": return .tips(.hadith)
        case "tipsIslam": return .tips(.islam)
        case "tipsApp": return .tips(.app)
        case "appearance": return .appearance
        case "appearanceColors": return .appearancePage(.customColors)
        case "appearanceLook": return .appearancePage(.lookAndFeel)
        default: return nil
        }
    }

    private static func launchValue(_ argument: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let idx = arguments.firstIndex(of: argument), arguments.indices.contains(idx + 1) else { return nil }
        return arguments[idx + 1]
    }
    #endif

    /// The floating bottom search bar, shared by the iPhone list and the iPad sidebar so settings
    /// search works identically in both shapes.
    private var settingsSearchBarInset: some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            SearchBar(text: $settingsSearchText.animation(.easeInOut))
                .onChange(of: settingsSearchText) { text in
                    runSettingsAISearch(query: text)
                }
                .onChange(of: semanticEngine.readyCorpora) { ready in
                    guard ready.contains(Self.settingsSemanticCorpusID), !settingsSearchText.isEmpty else { return }
                    runSettingsAISearch(query: settingsSearchText)
                }
                .minimizedBarStyle(barsCollapsed)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
        .padding(.horizontal, 24)
        .padding(.bottom, BottomBarCushion.standard)
        .background(Color.white.opacity(0.00001))
    }
    #endif

    /// The list body both shapes share. On iOS, search results replace the sections while a query is
    /// typed - in the iPad sidebar each hit's legacy `NavigationLink(destination:)` opens in the
    /// DETAIL column (that is where a split view routes destination links from its first column).
    @ViewBuilder
    private func settingsListContent(split: Bool) -> some View {
        Group {
            #if os(iOS)
            if !settingsSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                settingsSearchResultsSection
            } else {
                settingsSections(split: split)
            }
            #else
            settingsSections(split: split)
            #endif
        }
        .themedListRowBackground()
    }

    /// Every Settings section, once. Only the hub swaps its link grammar per shape; everything after
    /// it is literally the same views on iPhone, iPad, and the watch.
    @ViewBuilder
    private func settingsSections(split: Bool) -> some View {
        // Above the settings themselves, because it is not a setting: it is the one place the app tells
        // you what you have done rather than asking what you want. iPhone/iPad only - the watch has
        // neither the room for the rings nor the stores (hadith, tasbih) the profile reads.
        #if os(iOS)
        // Three tiles across one row (Abu, 2026-09-22: "about you and icloud backup should be on the
        // same row as your progress as 3 grids"). Three NavigationLinks in one List row would all
        // fire on any tap (see `one-link-per-list-row`), so the tiles are Buttons writing ONE door
        // and the list owns the push; the iPad sidebar and iOS 15 fall back to three rows.
        ProfileTilesSection(rows: split || !Self.canPushProgrammatically) { door in
            profileDoor = door
            openProfileDoor = true
        }
        #endif

        Group {
            #if os(iOS)
            if split, #available(iOS 16.0, *) {
                settingsHubSectionSplit
            } else {
                settingsHubSection
            }
            #else
            settingsHubSection
            #endif
        }

        // No ADVANCED section here (Abu, 2026-09-22: "dont do one general advanced settings there,
        // do that for each one"): the hub hides nothing of its own, and each page below owns the
        // switch for its own second half.

        // Front and center (Abu, 2026-09-20): the app's unusual settings as cards, directly under the
        // hub, each opening the screen that owns it, with every Tips & Tricks list one row below.
        // The iPad/Mac sidebar keeps the card strip too, opening each card in the DETAIL column: its
        // fallback of one row per card was a tall column of twelve rows (Abu, 2026-09-25: "this looks
        // awful on mac/ipad while it looks great on phone"). Only iOS 15, with no programmatic push
        // and no split, still gets rows.
        #if os(iOS)
        SettingsSpotlightSection(
            rows: !Self.canPushProgrammatically,
            selectedTipID: split ? splitSpotlightID : nil
        ) { tip in
            if split {
                selectSplitDestination(.spotlight(tip.id))
            } else {
                spotlightTarget = tip
                openSpotlight = true
            }
        }
        #endif

        appearanceSection
        resetSection
        creditsSection

        AlIslamAppsSection()
    }

    #if os(iOS)
    @ViewBuilder
    private var settingsSplitDetail: some View {
        Group {
            switch selectedDestination ?? Self.defaultDestination {
            case .notification:
                NotificationView()
            case .prayerSettings:
                SettingsAdhanView(showNotifications: false)
            case .quranSettings:
                SettingsQuranView()
            case .hadithSettings:
                SettingsHadithView(presentedAsSheet: false)
            case .islamSettings:
                SettingsIslamView()
            case .spotlight(let id):
                // Exactly what the card pushes on iPhone (`openSpotlight`), as the detail's root.
                if let tip = TipCatalog.spotlight.first(where: { $0.id == id }), let destination = tip.destination {
                    searchDestinationView(destination)
                        .revealsAdvancedSettings(tip.advanced)
                }
            }
        }
    }
    #endif

    #if os(iOS)
    // MARK: - Settings search
    //
    // The index is COMPOSED from per-screen entry lists that live NEXT TO the screens they describe
    // (see `SettingsSearchEntry`) - this file only concatenates them. To add/remove a setting's entry,
    // edit the `SettingsSearchEntry` extension at the bottom of the file that owns the control.

    // The whole index is `SettingsSearchEntry.all`, the ranking `SettingsSearchEntry.rank`, and the
    // destination mapping `SettingsSearchDestinationView` (SettingsSearch.swift): the per-page search
    // bars share all three with this root search.

    @ViewBuilder
    private func searchDestinationView(_ destination: SettingsSearchEntry.Destination) -> some View {
        SettingsSearchDestinationView.view(for: destination)
    }

    private var settingsSearchResults: [SettingsSearchEntry] {
        SettingsSearchEntry.rank(SettingsSearchEntry.all, query: settingsSearchText)
    }

    @ViewBuilder
    private var settingsSearchResultsSection: some View {
        let results = settingsSearchResults
        // AI hits the keyword pass also found would render twice - keep them keyword-side (they
        // carry the match highlight there) and let the AI section surface only the extras.
        let keywordIDs = Set(results.map(\.id))
        let aiOnly = settingsAIHits.filter { !keywordIDs.contains($0.id) }

        if !aiOnly.isEmpty {
            Section(header: SectionPillHeader(title: "AI MATCHES", count: aiOnly.count, icon: "sparkles", accentTitle: true)) {
                ForEach(aiOnly) { entry in
                    settingsSearchResultRow(entry)
                }
            }
        }

        Section(header: SectionPillHeader(title: "SETTING RESULTS", count: results.count)) {
            if results.isEmpty {
                Text(aiOnly.isEmpty ? "No settings match your search." : "No keyword matches. See the AI results above.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(results) { entry in
                settingsSearchResultRow(entry)
            }
        }
    }

    private func settingsSearchResultRow(_ entry: SettingsSearchEntry) -> some View {
        NavigationLink(destination: LazyDestination {
            searchDestinationView(entry.destination)
                .revealsAdvancedSettings(entry.advanced)
        }) {
            SettingsSearchResultRow(entry: entry, query: settingsSearchText)
        }
    }


    #endif

    private func resourceLink<Destination: View>(
        title: String,
        systemImage: String,
        subtitle: String? = nil,
        tint: Color? = nil,
        secondaryTint: Color? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        // LazyDestination, same as IslamView: building the destination eagerly meant every body pass of this
        // tab constructed the full Adhan/Quran/Notification settings trees - on the watch, where TabView
        // re-evaluates neighbouring tabs on every swipe, that WAS the tab-switch lag into Settings.
        NavigationLink(destination: LazyDestination(build: destination)) {
            toolLabel(title, systemImage: systemImage, subtitle: subtitle, chipTint: tint, chipSecondaryTint: secondaryTint)
        }
        .tint(settings.accentColor.color)
    }

    /// A settings row in the iOS Settings app's visual grammar, tinted the app's way: the icon on a
    /// small accent-gradient chip, an optional caption under the title. `chipTint` overrides the
    /// accent (the reset row goes red).
    /// `chipSecondaryTint` gives the chip a SECOND colour, corner to corner - Islam Settings wears both
    /// brand colours because it is not one tab's area (see `AccentIconChip`).
    private func toolLabel(_ title: String, systemImage: String, subtitle: String? = nil, chipTint: Color? = nil, chipSecondaryTint: Color? = nil) -> some View {
        return HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage, tint: chipTint, secondaryTint: chipSecondaryTint)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .foregroundColor(.primary)

                // The caption column is an iPhone luxury - the 40mm screen has no room for it.
                #if os(iOS)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                #endif
            }
        }
        .padding(.vertical, 3)
    }

    @available(iOS 16.0, *)
    private func splitResourceLink(
        title: String,
        systemImage: String,
        subtitle: String? = nil,
        tint: Color? = nil,
        secondaryTint: Color? = nil,
        value: SettingsDestination
    ) -> some View {
        // A Button (not `NavigationLink(value:)`) so a re-tap of the ALREADY-selected row still
        // responds - it pops that section back to its root via the refresh token. The `.tag` keeps
        // the sidebar highlight driven by `List(selection:)`, the Islam sidebar's exact pattern.
        Button {
            settings.hapticFeedback()
            selectSplitDestination(value)
        } label: {
            toolLabel(title, systemImage: systemImage, subtitle: subtitle, chipTint: tint, chipSecondaryTint: secondaryTint)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .tag(value)
        .tint(settings.accentColor.color)
    }

    /// The four settings destinations as ONE card - the old one-row-per-section layout spent most
    /// of the screen on headers. Notifications shown on watchOS too (it supports local notifications).
    /// Each area wears its own fixed colour (`SettingsTint`: prayer yellow, Quran green, hadith blue),
    /// the iOS Settings app's grammar. Every page behind these rows carries its own search bar.
    @ViewBuilder
    private var settingsHubSection: some View {
        Section(header: Text("SETTINGS")) {
            resourceLink(title: "Notifications", systemImage: "bell.badge.fill",
                         subtitle: "Prayer alerts, adhan sounds, reminders", tint: SettingsTint.notifications) {
                NotificationView()
            }
            resourceLink(title: "Prayer Settings", systemImage: "safari.fill",
                         subtitle: "Calculation, offsets, traveling mode, sky", tint: SettingsTint.prayer) {
                SettingsAdhanView(showNotifications: false)
            }
            resourceLink(title: "Quran Settings", systemImage: "character.book.closed.ar",
                         subtitle: "Fonts, translations, tajweed, reciters, themes", tint: SettingsTint.quran) {
                SettingsQuranView()
            }
            #if os(iOS)
            resourceLink(title: "Hadith Settings", systemImage: "text.book.closed.fill",
                         subtitle: "Arabic and English text, reading view", tint: SettingsTint.hadith) {
                SettingsHadithView(presentedAsSheet: false)
            }
            // The fourth area, for what belongs to none of the three above. It wears BOTH brand
            // colours rather than one of its own, because it is not one tab (see `SettingsTint.islam`).
            resourceLink(title: "Islam Settings", systemImage: "moon.stars.fill",
                         subtitle: "Arabic font, alphabet, libraries, reminders",
                         tint: SettingsTint.islam, secondaryTint: SettingsTint.islamSecondary) {
                SettingsIslamView()
            }
            #endif
        }
    }

    @available(iOS 16.0, *)
    @ViewBuilder
    private var settingsHubSectionSplit: some View {
        Section(header: Text("SETTINGS")) {
            splitResourceLink(title: "Notifications", systemImage: "bell.badge.fill",
                              subtitle: "Prayer alerts, adhan sounds, reminders", tint: SettingsTint.notifications, value: .notification)
            splitResourceLink(title: "Prayer Settings", systemImage: "safari.fill",
                              subtitle: "Calculation, offsets, traveling mode, sky", tint: SettingsTint.prayer, value: .prayerSettings)
            splitResourceLink(title: "Quran Settings", systemImage: "character.book.closed.ar",
                              subtitle: "Fonts, translations, tajweed, reciters, themes", tint: SettingsTint.quran, value: .quranSettings)
            splitResourceLink(title: "Hadith Settings", systemImage: "text.book.closed.fill",
                              subtitle: "Arabic and English text, reading view", tint: SettingsTint.hadith, value: .hadithSettings)
            splitResourceLink(title: "Islam Settings", systemImage: "moon.stars.fill",
                              subtitle: "Arabic font, alphabet, libraries, reminders",
                              tint: SettingsTint.islam, secondaryTint: SettingsTint.islamSecondary, value: .islamSettings)
        }
    }

    @ViewBuilder
    private var resetSection: some View {
        #if os(iOS)
        Section(header: Text("RESET")) {
            Button(role: .destructive) {
                settings.hapticFeedback()
                showResetConfirmation = true
            } label: {
                toolLabel("Reset All Settings", systemImage: "arrow.counterclockwise", chipTint: .red)
            }
            // Two very different things, so they're two buttons rather than one that quietly picks for you:
            // the everyday "put the options back" and the "make it as if I'd never installed this".
            .confirmationDialog(
                "Reset All Settings?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Settings, Keep My Content") {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.resetAllSettings(keepingContent: true)
                    }
                }

                Button("Erase Everything", role: .destructive) {
                    settings.hapticFeedback()
                    confirmEraseEverything = true
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                #if HAS_ICLOUD_BACKUP
                // Generated from the same table the iCloud page's What's Included reads, so a new
                // kind of content is named here without a second edit.
                Text("Reset puts every setting back to its default (appearance, prayer, notification, Quran, hadith and Islam options) and keeps everything you made: \(ContentCategory.listSentence). It also keeps your saved location and this \(CloudDevice.kind)'s iCloud Backup.\n\nErase removes all of that too.")
                #else
                // A companion app has no iCloud Backup and no content table (ContentCategories measures
                // a backup, so it is Al-Islam's too): the sentence is written out.
                Text("Reset puts every setting back to its default and keeps everything you made, like bookmarks, favorites, progress and counters, and your saved location.\n\nErase removes all of that too.")
                #endif
            }
            // A second confirmation, because this one cannot be undone.
            .confirmationDialog(
                "Erase Everything?",
                isPresented: $confirmEraseEverything,
                titleVisibility: .visible
            ) {
                Button("Erase Everything", role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.resetAllSettings(keepingContent: false)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                #if HAS_ICLOUD_BACKUP
                Text("This deletes everything you made on this \(CloudDevice.kind): \(ContentCategory.listSentence), plus your search history and saved locations. The app is left as it was on a fresh install, and this \(CloudDevice.kind) forgets its iCloud Backup profile (the backup already in iCloud stays until you delete it there). This cannot be undone.")
                #else
                Text("This deletes everything you made on this device, like bookmarks, favorites, progress and counters, plus your search history and saved locations. The app is left as it was on a fresh install. This cannot be undone.")
                #endif
            }
        }
        #endif
    }

    private var appearanceSection: some View {
        Section(header: Text("APPEARANCE")) {
            SettingsAppearanceView()
        }
    }

    private var creditsSection: some View {
        Section(header: Text("CREDITS")) {
            creditsIntro
            viewCreditsButton
            // App Settings first, the review below it (Abu, 2026-09-16).
            openAppSettingsButton
            leaveReviewButton
            websiteRow
            contactRow
            VersionNumber(width: glyphWidth)
                .font(.subheadline)
        }
    }

    private var creditsIntro: some View {
        Text("Made by Abubakr Elmallah, who was a 17-year-old high school student when this app was made.\n\nSpecial thanks to my parents and to Mr. Joe Silvey, my English teacher and Muslim Student Association Advisor.")
            .font(.footnote)
            .foregroundColor(.primary)
    }

    @ViewBuilder
    private var viewCreditsButton: some View {
        #if os(iOS)
        Button {
            settings.hapticFeedback()
            showingCredits = true
        } label: {
            toolLabel("View Credits", systemImage: "scroll.fill", chipTint: SettingsTint.credits)
        }
        .sheet(isPresented: $showingCredits) {
            CreditsView()
                .smallMediumSheetPresentation()
        }
        #endif
    }

    @ViewBuilder
    private var leaveReviewButton: some View {
        #if os(iOS)
        Button {
            leaveReview()
        } label: {
            toolLabel("Leave a Review", systemImage: "star.bubble.fill")
        }
        .contextMenu {
            Text("Review")
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = "itms-apps://itunes.apple.com/app/id6449729655?action=write-review"
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Website")
                }
            }
        }
        #endif
    }

    @ViewBuilder
    private var openAppSettingsButton: some View {
        #if os(iOS)
        Button {
            settings.hapticFeedback()
            openAppSettings()
        } label: {
            toolLabel("Open App Settings", systemImage: "gearshape.fill", chipTint: SettingsTint.credits)
        }
        #endif
    }

    private var websiteRow: some View {
        HStack {
            // The watch drops the "Website:" label - the 40mm screen has no room for a label column, and the
            // URL names itself.
            #if os(iOS)
            Text("Website: ")
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .frame(width: glyphWidth)
            #endif

            if let url = URL(string: "https://abubakrelmallah.com/") {
                Link("abubakrelmallah.com", destination: url)
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
                    .multilineTextAlignment(.leading)
                    #if os(iOS)
                    .padding(.leading, -4)
                    #endif
            }
        }
        #if os(iOS)
        .contextMenu {
            Text("Website")
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = "abubakrelmallah.com"
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Website")
                }
            }
        }
        #endif
    }

    private var contactRow: some View {
        HStack {
            // Same as the website row: no "Contact:" label on the watch, the address speaks for itself.
            #if os(iOS)
            Text("Contact: ")
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .frame(width: glyphWidth)
            #endif

            Text("ammelmallah@icloud.com")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
                .multilineTextAlignment(.leading)
                #if os(iOS)
                .padding(.leading, -4)
                #endif
        }
        #if os(iOS)
        .contextMenu {
            Text("Email")
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = "ammelmallah@icloud.com"
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Email")
                }
            }
        }
        #endif
    }

    #if os(iOS)
    private func leaveReview() {
        settings.hapticFeedback()

        // No withAnimation: opening a URL animates nothing, and the empty transaction leaked a
        // .smooth() curve onto any incidental state change on the same runloop tick.
        do {
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6449729655?action=write-review") {
                UIApplication.shared.open(url)
            }
        }
    }

    private func openAppSettings() {
        settings.hapticFeedback()

        do {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    #endif

    private func columnWidth(for textStyle: UIFont.TextStyle, extra: CGFloat = 4, sample: String? = nil, fontName: String? = nil) -> CGFloat {
        let sampleString = (sample ?? "M") as NSString
        let font: UIFont

        if let fontName = fontName, let customFont = UIFont(name: fontName, size: UIFont.preferredFont(forTextStyle: textStyle).pointSize) {
            font = customFont
        } else {
            font = UIFont.preferredFont(forTextStyle: textStyle)
        }

        return ceil(sampleString.size(withAttributes: [.font: font]).width) + extra
    }

    private var glyphWidth: CGFloat {
        columnWidth(for: .subheadline, extra: 0, sample: "Contact: ")
    }
}

#if os(iOS)
/// The appearance section as its own pushable screen - search results need a destination, and the
/// section otherwise lives inline on the Settings tab with nothing to navigate to.
struct AppearanceSettingsScreen: View {
    var body: some View {
        SettingsScopedSearch(scope: .appearance, resolve: { destination in
            if case .appearancePage(let page) = destination { return AnyView(AppearancePageView(page: page)) }
            return nil
        }) {
            Section {
                SettingsAppearanceView()
            }
        }
        .navigationTitle("Appearance")
    }
}

extension SettingsSearchEntry {
    static let appearanceEntries: [SettingsSearchEntry] = appearanceControlEntries.filter { entry in
        LaunchTab.isOffered || entry.title != "Open the App On"
    }

    private static let appearanceControlEntries: [SettingsSearchEntry] = [
        .init(title: "Accent Color", path: "Appearance", keywords: "green color swatch tint theme", destination: .appearance),
        .init(title: "App Theme (Light / Dark / Sepia / Gray)", path: "Appearance", keywords: "dark mode light mode night reading sepia gray paper background", destination: .appearance),
        .init(title: "Custom Background Color", path: "Appearance → Custom Colors", keywords: "custom color background hex picker theme", destination: .appearancePage(.customColors)),
        .init(title: "Custom Accent Color", path: "Appearance → Custom Colors", keywords: "custom color accent hex picker tint own", destination: .appearancePage(.customColors)),
        .init(title: "Top Accent Glow", path: "Appearance → Custom Colors", keywords: "glow wash gradient accent top background flat hide al islam green yellow brand", destination: .appearancePage(.customColors)),
        .init(title: "Open the App On", path: "Appearance → Look and Feel", keywords: "launch start first tab open adhan quran hadith islam default home landing", destination: .appearancePage(.lookAndFeel)),
        .init(title: "Default List View", path: "Appearance → Look and Feel", keywords: "list style plain grouped inset layout", destination: .appearancePage(.lookAndFeel)),
        .init(title: "Classic Look (No Liquid Glass)", path: "Appearance → Look and Feel", keywords: "liquid glass classic look performance faster battery low power mode ios 26 old design", destination: .appearancePage(.lookAndFeel)),
        .init(title: "Haptic Feedback", path: "Appearance → Look and Feel", keywords: "vibration taptic buzz feedback toggle", destination: .appearancePage(.lookAndFeel)),
    ]
}

// MARK: - The tab the app opens on

/// The four tabs the app can open on (`Settings.launchTabRaw`). Settings itself is not offered:
/// nobody opens an app to change it.
enum LaunchTab: String, CaseIterable, Identifiable {
    case adhan, quran, hadith, islam

    var id: String { rawValue }

    /// See `SettingsAppearancePage.offersLaunchTab`: Al-Islam only.
    static var isOffered: Bool { SettingsAppearancePage.offersLaunchTab }

    var title: String {
        switch self {
        case .adhan: return "Adhan"
        case .quran: return "Quran"
        case .hadith: return "Hadith"
        case .islam: return "Islam"
        }
    }
}

extension Settings {
    var launchTab: LaunchTab {
        get { LaunchTab(rawValue: launchTabRaw) ?? .adhan }
        set { launchTabRaw = newValue.rawValue }
    }
}

/// "Open the App On": one control, on Appearance's Look and Feel page only. About You carried a
/// second copy (where Abu first went looking for it, under a toggle whose name read as if it did
/// this) until he asked for it to live on Look and Feel alone (2026-09-25).
struct LaunchTabPicker: View {
    @ObservedObject private var settings = Settings.shared

    /// Plain, never animated: an animated selection binding makes the segmented indicator slide,
    /// snap back and slide again.
    private var selection: Binding<LaunchTab> {
        Binding(
            get: { settings.launchTab },
            set: { newValue in
                settings.launchTab = newValue
                settings.launchTabChosen = true
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Open the App On")
                .font(.subheadline)

            Picker("Open the App On", selection: selection) {
                ForEach(LaunchTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: settings.launchTabRaw) { _ in settings.hapticFeedback() }

            Text("The tab you land on when the app opens. A notification or a reminder you tap still opens where it points.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
        }
    }
}

// MARK: - Appearance sub-screens

/// One of Appearance's two sub-screens (`SettingsAppearancePage`): the controls that used to run
/// down the Settings tab under the swatches, unchanged, one push away.
struct AppearancePageView: View {
    @ObservedObject private var settings = Settings.shared

    let page: SettingsAppearancePage

    var body: some View {
        List {
            Group {
                switch page {
                case .customColors: customColorsSections
                case .lookAndFeel: lookAndFeelSections
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(page.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Custom Colors

    /// Reads/writes the stored custom hex; picking a color also switches the active accent to `.custom`.
    private var customAccentColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: settings.customAccentColorHex) ?? .green },
            set: { newColor in
                settings.customAccentColorHex = newColor.hexString
                withAnimation { settings.accentColor = .custom }
            }
        )
    }

    /// On = custom accent is active (color picker enabled). Off = revert to the app's default accent.
    private var customColorEnabledBinding: Binding<Bool> {
        Binding(
            get: { settings.accentColor == .custom },
            set: { isOn in
                withAnimation {
                    settings.accentColor = isOn ? .custom : AppIdentifiers.mainColor
                }
            }
        )
    }

    /// Reads/writes the stored custom background hex; picking a color also switches the active theme to `custom`.
    private var customBackgroundColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: settings.customBackgroundColorHex) ?? .gray },
            set: { newColor in
                settings.customBackgroundColorHex = newColor.hexString
                withAnimation { settings.colorSchemeString = "custom" }
            }
        )
    }

    /// On = custom background theme is active. Off = revert to the System theme.
    private var customBackgroundEnabledBinding: Binding<Bool> {
        Binding(
            get: { settings.colorSchemeString == "custom" },
            set: { isOn in
                withAnimation {
                    settings.colorSchemeString = isOn ? "custom" : "system"
                }
            }
        )
    }

    /// One line: color well, label, then a toggle tinted with the custom color itself (not the accent).
    private func colorRow(_ title: String, color: Binding<Color>, enabled: Binding<Bool>, tint: Color) -> some View {
        HStack(spacing: 12) {
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()

            Text(title)
                .font(.subheadline)

            Spacer()

            Toggle("", isOn: enabled.animation(.easeInOut))
                .labelsHidden()
                .tint(tint)
        }
    }

    @ViewBuilder
    private var customColorsSections: some View {
        Section {
            VStack(alignment: .leading) {
                colorRow("Custom Background", color: customBackgroundColorBinding, enabled: customBackgroundEnabledBinding,
                         tint: Color(hex: settings.customBackgroundColorHex) ?? .gray)
                    .onChange(of: settings.colorSchemeString) { _ in settings.hapticFeedback() }

                Text("Pick any background color for the whole app. Light or dark text is chosen automatically so it stays readable.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }

            VStack(alignment: .leading) {
                colorRow("Custom Color", color: customAccentColorBinding, enabled: customColorEnabledBinding,
                         tint: Color(hex: settings.customAccentColorHex) ?? .green)
                    .onChange(of: settings.accentColor) { _ in settings.hapticFeedback() }

                Text("An accent of your own in place of the swatches on the Settings tab. Turning it off goes back to the app's green.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }
        } header: {
            Text("YOUR OWN COLORS")
        }

        Section {
            VStack(alignment: .leading) {
                Toggle("Top Accent Glow", isOn: $settings.showAccentGlow.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.showAccentGlow) { _ in settings.hapticFeedback() }

                Text("A soft wash of your accent color at the top of each screen. Turn it off for a flat background.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)

                if settings.showAccentGlow {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Al-Islam Glow", isOn: $settings.alIslamGlow.animation(.easeInOut))
                            .font(.subheadline)
                            .onChange(of: settings.alIslamGlow) { _ in settings.hapticFeedback() }

                        Text("Color the glow with Al-Islam's yellow and green (yellow from the left, green from the right) instead of your accent color.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .settingsDependent()
                }
            }
        } header: {
            Text("THE GLOW")
        }
    }

    // MARK: Look and Feel

    @ViewBuilder
    private var lookAndFeelSections: some View {
        if LaunchTab.isOffered {
            Section {
                LaunchTabPicker()
            } header: {
                Text("WHEN THE APP OPENS")
            }
        }

        Section {
            VStack(alignment: .leading) {
                Toggle("Default List View", isOn: $settings.defaultView.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.defaultView) { _ in settings.hapticFeedback() }

                Text("The default list view is the standard interface found in many of Apple's first party apps, including Notes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }

            if #available(iOS 26.0, *) {
                VStack(alignment: .leading) {
                    Toggle("Classic Look (No Liquid Glass)", isOn: $settings.classicLook.animation(.easeInOut))
                        .font(.subheadline)
                        .onChange(of: settings.classicLook) { _ in settings.hapticFeedback() }

                    Text("Turns off Liquid Glass so the app looks the way it did before iOS 26. Faster and easier on the battery. The search bar keeps its Liquid Glass.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 2)

                    if !settings.classicLook {
                        VStack(alignment: .leading) {
                            Toggle("Automatically in Low Power Mode", isOn: $settings.classicLookInLowPower.animation(.easeInOut))
                                .font(.subheadline)
                                .onChange(of: settings.classicLookInLowPower) { _ in settings.hapticFeedback() }

                            Text("Uses the Classic Look while Low Power Mode is on and brings Liquid Glass back when it is off.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 2)
                        }
                        .settingsDependent()
                    }
                }
            }
        } header: {
            Text("HOW IT LOOKS")
        }

        Section {
            Toggle("Haptic Feedback", isOn: $settings.hapticOn.animation(.easeInOut))
                .font(.subheadline)
                .onChange(of: settings.hapticOn) { _ in settings.hapticFeedback() }
        } header: {
            Text("HOW IT FEELS")
        }
    }
}
#endif

/// The APPEARANCE section of the Settings tab: the two controls people reach for (the theme and the
/// accent swatches), then a door to each sub-screen. The watch has only the swatches and the haptics
/// switch, so it keeps both inline.
struct SettingsAppearanceView: View {
    @ObservedObject var settings = Settings.shared

    #if os(iOS)
    /// The iPad sidebar gives the five-segment theme control about 54 pt a segment, and "System"
    /// showed as "Syst..." there (2026-09-06 iPad pass); iPads say "Auto". Keyed on the idiom, not
    /// the size class: a split view's sidebar column reports `.compact` even on a 13-inch iPad.
    private var systemThemeLabel: String {
        UIDevice.current.userInterfaceIdiom != .phone ? "Auto" : "System"
    }
    #endif

    // Accent-swatch grid metrics. The watch gets fewer, smaller swatches with tighter gutters so each circle
    // actually FITS its column (see the note on the grid below); the phone keeps the roomier original.
    #if os(watchOS)
    private static let swatchColumns = 4
    private static let swatchDiameter: CGFloat = 22
    private static let swatchSpacing: CGFloat = 6
    private static let swatchGridVerticalPadding: CGFloat = 4
    #else
    private static let swatchColumns = 4
    private static let swatchDiameter: CGFloat = 30
    private static let swatchSpacing: CGFloat = 12
    private static let swatchGridVerticalPadding: CGFloat = 16
    #endif

    private func accentSwatch(_ accentColor: AccentColor) -> some View {
        // Every preset is a single colour, so a plain circle is right here.
        Circle()
            .fill(accentColor.color)
            .frame(width: Self.swatchDiameter, height: Self.swatchDiameter)
            .overlay(
                Circle()
                    .stroke(settings.accentColor == accentColor ? Color.primary : Color.clear, lineWidth: 2)
            )
            .accessibilityLabel(accentColor.displayName)
            .onTapGesture {
                settings.hapticFeedback()

                withAnimation {
                    settings.accentColor = accentColor
                }
            }
    }

    var body: some View {
        #if os(iOS)
        VStack(alignment: .leading) {
            Picker("Color Theme", selection: $settings.colorSchemeString) {
                Text(systemThemeLabel).tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
                Text("Gray").tag("gray")
                Text("Sepia").tag("sepia")
            }
            .font(.subheadline)
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: settings.colorSchemeString) { _ in settings.hapticFeedback() }

            Text("System follows your device. Light theme in Light Mode, Dark theme in Dark Mode. Other themes are ignored.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
        }
        #endif

        VStack(alignment: .leading) {
            // Sized per platform. A watch list row is only ~120pt wide, so four fixed-width columns with 12pt
            // gutters gave each cell LESS room than the 30pt circle it had to hold: the swatches overflowed
            // their cells, the grid grew its row heights to compensate, and `.padding(.vertical)` piled 32pt on
            // top - which is the "random huge padding" on the watch. The phone has the width for the original
            // layout, so it keeps it.
            LazyVGrid(columns: Array(
                repeating: GridItem(.flexible(), spacing: Self.swatchSpacing),
                count: Self.swatchColumns
            ), spacing: Self.swatchSpacing) {
                ForEach(accentColors, id: \.self) { accentColor in
                    accentSwatch(accentColor)
                }
            }
            .padding(.vertical, Self.swatchGridVerticalPadding)
            #if os(iOS)
            .onChange(of: settings.accentColor) { _ in settings.hapticFeedback() }
            #endif

            #if os(iOS)
            Text("Anas ibn Malik (may Allah be pleased with him) said, “The most beloved of colors to the Messenger of Allah (peace be upon him) was green.”")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
            #endif
        }

        #if os(iOS)
        // One List row each: a row may hold only one link.
        ForEach(SettingsAppearancePage.allCases, id: \.self) { page in
            NavigationLink(destination: LazyDestination { AppearancePageView(page: page) }) {
                SettingsRowLabel(title: page.title, systemImage: page.systemImage, subtitle: page.caption,
                                 tint: SettingsTint.appearance)
            }
            .tint(settings.accentColor.color)
        }
        #else
        VStack(alignment: .leading) {
            Toggle("Haptic Feedback", isOn: $settings.hapticOn.animation(.easeInOut))
                .font(.subheadline)
                .onChange(of: settings.hapticOn) { _ in settings.hapticFeedback() }
        }
        #endif
    }
}

#if os(iOS)
// MARK: - Your Progress / About You / iCloud Backup

/// The three personal screens, as tiles across ONE row (Abu, 2026-09-22: "about you and icloud
/// backup should either be on the same row as your progress as 3 grids"). They were three stacked
/// settings rows before, which read as three unrelated settings rather than as one place the app
/// tells you who you are and how you are doing.
///
/// Buttons, not links: three NavigationLinks inside a single List row all fire on any tap (see
/// `one-link-per-list-row`), so each tile writes one `Door` and `SettingsView`'s list owns the push.
/// `rows: true` is the fallback where that push is unavailable (iOS 15) or wrong (the iPad sidebar,
/// where it would push inside the narrow column): the same three screens as ordinary rows.
struct ProfileTilesSection: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    /// Observed for the same reason `ProfileSettingsRow` observes them: the deferred last-read load
    /// and a badge unlocked elsewhere must both re-render this row's caption.
    @ObservedObject private var hadithStore = HadithStore.shared
    @ObservedObject private var achievements = AchievementsStore.shared
    #if HAS_ICLOUD_BACKUP
    @ObservedObject private var cloud = CloudBackupManager.shared
    #endif

    /// True for the fallback shape: one settings row per screen.
    let rows: Bool
    /// The iPhone stack's programmatic push (`SettingsView.profileDoor`).
    var open: (Door) -> Void = { _ in }

    enum Door: String, Identifiable {
        case progress
        case aboutYou
        #if HAS_ICLOUD_BACKUP
        case cloudBackup
        #endif

        var id: String { rawValue }

        @ViewBuilder
        var destination: some View {
            switch self {
            case .progress: ProfileView()
            case .aboutYou: AboutYouSettingsView()
            #if HAS_ICLOUD_BACKUP
            case .cloudBackup: CloudBackupSettingsView()
            #endif
            }
        }
    }

    private struct Tile {
        let door: Door
        let title: String
        let systemImage: String
        /// The live read-out under the title - a streak, an answer, On/Off.
        let value: String
        let tint: Color?
        var secondaryTint: Color? = nil
        /// The longer caption the fallback ROW shows beside the title; the tile has no room for it.
        let rowSubtitle: String
    }

    /// Your Progress' one live number, short enough for a third of a screen: the streak first, then
    /// the khatm, then badges, and the invitation when there is nothing recorded yet.
    private var progressValue: String {
        let stats = ProfileStats.current(settings: settings, quranData: quranData)
        if stats.prayer.currentStreak > 0 {
            return "\(stats.prayer.currentStreak)-day streak"
        }
        if stats.khatmCompleted > 0 {
            return "\(Int((stats.khatmFraction * 100).rounded()))% read"
        }
        let earned = achievements.unlockedCount(stats)
        if earned > 0 {
            return "\(earned) badge\(earned == 1 ? "" : "s")"
        }
        return "Nothing yet"
    }

    private var tiles: [Tile] {
        var list = [
            Tile(door: .progress, title: "Your Progress", systemImage: "person.crop.circle.fill",
                 value: progressValue, tint: nil,
                 rowSubtitle: "Your prayers, reading, and badges"),
            Tile(door: .aboutYou, title: "About You", systemImage: "sparkles",
                 value: settings.userBackground?.title ?? "Not set",
                 tint: SettingsTint.islam, secondaryTint: SettingsTint.islamSecondary,
                 rowSubtitle: "Start Here, welcome tutorial"),
        ]
        // iCloud Backup is Al-Islam's alone: a companion app shows the first two tiles.
        #if HAS_ICLOUD_BACKUP
        list.append(Tile(door: .cloudBackup, title: "iCloud Backup", systemImage: "icloud.fill",
                         value: cloud.isEnabled ? "On" : "Off", tint: SettingsTint.hadith,
                         rowSubtitle: "Profiles, restore, what's included, backup file"))
        #endif
        return list
    }

    var body: some View {
        Section {
            if rows {
                ForEach(tiles, id: \.door.id) { tile in
                    NavigationLink(destination: LazyDestination { tile.door.destination }) {
                        SettingsRowLabel(title: tile.title, systemImage: tile.systemImage,
                                         subtitle: tile.rowSubtitle,
                                         tint: tile.tint, secondaryTint: tile.secondaryTint,
                                         value: tile.value)
                    }
                    .tint(settings.accentColor.color)
                }
            } else {
                // `.center`, not `.top`, so each tile's `maxHeight: .infinity` stretches it to the
                // tallest: "Learning about Islam" wraps to two lines and "Off" does not, and three
                // cards of three different heights read as a layout bug.
                HStack(alignment: .center, spacing: 8) {
                    ForEach(tiles, id: \.door.id) { tile in
                        profileTile(tile)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
            }
        }
    }

    private func profileTile(_ tile: Tile) -> some View {
        Button {
            settings.hapticFeedback()
            open(tile.door)
        } label: {
            VStack(spacing: 5) {
                AccentIconChip(systemImage: tile.systemImage, tint: tile.tint,
                               secondaryTint: tile.secondaryTint, size: 34)

                Text(tile.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                // Two lines, unlike the Explore tiles' one: "Just getting started" is an answer the
                // reader gave, and shrinking it to a single scaled-down line made it unreadable.
                Text(tile.value)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(settings.accentColor.color.opacity(0.09))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tile.title). \(tile.value)")
        .accessibilityAddTraits(.isButton)
    }
}
#endif

// MARK: - Advanced Settings

/// The switch a simplified settings screen ends with. ONE PER SCREEN (Abu, 2026-09-22: "dont do one
/// general advanced settings there, do that for each one - if it needs advanced mode then show it
/// there"): the toggle writes `screen`'s own key, so turning the second half on under Nagging Mode
/// leaves Arabic Text simple. Off, a screen keeps to its essentials and this section names what it is
/// keeping out of sight (`hides`), so nobody wonders where an option went; the hidden options keep
/// the values they hold. A screen that hides nothing carries no ADVANCED section at all - which is
/// why the Settings tab's own hub no longer has one. Compiles for the watch too (its Notifications
/// and Nagging Mode pages use it).
struct AdvancedSettingsSection: View {
    @ObservedObject private var settings = Settings.shared

    /// Which screen's switch this is.
    let screen: Settings.AdvancedScreen

    /// What THIS screen shows only with the switch on, as a plain list ("the repeat interval, the
    /// last calls and a tone of their own").
    var hides: String? = nil

    /// False while this screen's advanced half would be empty ANYWAY, whatever the switch says
    /// (Abu, 2026-09-22: "only show advanced setting if it applies"). Three screens gate their own
    /// advanced content on something else first - Nagging Mode on the mode being on, Arabic Text on
    /// Arabic being shown, the watch's Notifications on the Islamic-calendar switch - and on those a
    /// switch promising hidden options that do not exist is worse than no switch at all.
    ///
    /// The stored value is untouched when the section is away: flipping the gate back on brings the
    /// switch back exactly as it was left.
    var applies: Bool = true

    var body: some View {
        if applies { section }
    }

    private var section: some View {
        Section(header: Text("ADVANCED")) {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Show Advanced Settings", isOn: settings.advancedBinding(screen).animation(.easeInOut))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)
                    .onChange(of: settings.advanced(screen)) { _ in settings.hapticFeedback() }

                #if os(iOS)
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
                #endif
            }
        }
    }

    private var caption: String {
        if settings.advanced(screen) {
            return "Every option on this screen is shown. Turn this off to keep it to its essentials; what you set in the advanced options still applies. Each screen has its own switch."
        }
        if let hides {
            return "Hidden on this screen: \(hides). Turn this on to see every option here. It changes this screen only, and anything set here before still applies."
        }
        return "This screen keeps to its essentials. Turn this on to see every option it has."
    }
}

/// Turns Advanced Settings on when a search result or a tip opens a control its screen would
/// otherwise hide. The row said "Advanced" before it was tapped, so the switch flipping is the
/// expected outcome, not a surprise; the screen's own ADVANCED section is there to turn it back off.
///
/// Every screen's switch, not one: a search entry records only THAT the control is advanced, never
/// which of the eleven screens owns it, and landing on a screen still hiding the very thing that was
/// searched for is the failure this exists to prevent.
struct AdvancedSettingsReveal: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        content.onAppear {
            guard active else { return }
            Settings.shared.revealAllAdvancedSettings()
        }
    }
}

extension View {
    func revealsAdvancedSettings(_ active: Bool) -> some View {
        modifier(AdvancedSettingsReveal(active: active))
    }
}

struct VersionNumber: View {
    @ObservedObject var settings = Settings.shared

    var width: CGFloat?

    var body: some View {
        HStack {
            if let width = width {
                Text("Version:")
                    .frame(width: width)
            } else {
                Text("Version")
            }

            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                .foregroundColor(settings.accentColor.color)
                .padding(.leading, -4)
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        SettingsView()
    }
}
