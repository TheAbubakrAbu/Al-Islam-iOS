import SwiftUI

#if os(iOS)
/// Interface text that is DATA as well: a tip, a settings search title. It is written once, as the
/// `String.LocalizationValue` literal `String(localized:)` takes (the same catalog key, extracted by the
/// compiler the same way), and resolved twice. A screen shows `display`, in the interface language, as it
/// always has; Ask AI (what a question is matched against, what the model reads, the settings corpus) and
/// anything saved (`SettingsSearchEntry.id`, which Ask AI transcripts keep) read `english`, which no
/// language changes. A String.LocalizationValue rather than a LocalizedStringResource: the companion apps
/// compile these files on iOS 15.
struct InterfaceText {
    /// Which of the two strings a piece of composed text stands for (`init(_ compose:)`).
    enum Language { case display, english }

    let display: String
    let english: String

    init(_ value: String.LocalizationValue) {
        display = String(localized: value)
        english = Self.english(value)
    }

    /// Text resolved elsewhere, one string per language: the app's name is الإسلام on an Arabic screen
    /// and Al-Islam to the model.
    init(display: String, english: String) {
        self.display = display
        self.english = english
    }

    /// A sentence that interpolates other interface text, `InterfaceText { "\(lead[$0]) A single tap
    /// still opens the whole menu." }`: written once and called once per language, with the pieces in that
    /// language, so its catalog key is the one `String(localized:)` gave it (a %@ for each piece).
    init(_ compose: (Language) -> String.LocalizationValue) {
        display = String(localized: compose(.display))
        english = Self.english(compose(.english))
    }

    subscript(language: Language) -> String {
        language == .english ? english : display
    }

    /// The parts joined with `separator` in each language, an empty part left out.
    static func joined(_ parts: [InterfaceText], separator: String) -> InterfaceText {
        InterfaceText(display: parts.map(\.display).filter { !$0.isEmpty }.joined(separator: separator),
                      english: parts.map(\.english).filter { !$0.isEmpty }.joined(separator: separator))
    }

    /// `value` in English in every interface language. It is looked up in the English table alone, which
    /// holds only the keys whose English differs from the key ("weather.clear"), so every other key comes
    /// back as itself: the English it was written in. Arguments are formatted the POSIX way, as a Swift
    /// interpolation writes them ("1000", never "1,000" or "١٬٠٠٠").
    static func english(_ value: String.LocalizationValue) -> String {
        String(localized: value, table: englishLookup.table, bundle: englishLookup.bundle, locale: englishLocale)
    }

    private static let englishLocale = Locale(identifier: "en_US_POSIX")

    /// en.lproj as a bundle of its own, so no other language can answer. A build without an English
    /// table (a companion app before its catalog) asks the main bundle for a table no language carries,
    /// which also returns every key as itself, never a translation.
    private static let englishLookup: (bundle: Bundle, table: String?) = {
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"), let bundle = Bundle(path: path) {
            return (bundle, nil)
        }
        return (.main, "EnglishSourceOnly")
    }()
}

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
    /// The title the screens show and search, in the interface language.
    let title: String
    /// The same title in English in every language (`InterfaceText`): what Ask AI matches and quotes,
    /// the semantic corpus, and `id`.
    let englishTitle: String
    let path: String
    let keywords: String
    let destination: Destination
    /// A control its screen shows only with Advanced Settings on. The result row says so, and
    /// opening it turns the switch on (`revealsAdvancedSettings`), so a search never lands on a
    /// screen that hides the very thing that was searched for.
    var advanced: Bool = false
    /// Whether the entry can be offered right now, as `AppTip.isAvailable` does for tips. The four
    /// "Need a Hand?" entries land on a section Simple Mode hides, so in Simple they would be dead ends.
    /// `rank` drops an unavailable entry from every result list.
    var isAvailable: () -> Bool = { true }

    /// The same in every interface language: Ask AI's saved transcripts keep it (`.setting(id:)`), and
    /// every one saved before the Arabic interface holds an English title.
    var id: String { path + englishTitle }

    /// The entry the per-screen lists write: `title` is the literal `String(localized:)` would take.
    init(title: String.LocalizationValue, path: String, keywords: String, destination: Destination,
         advanced: Bool = false, isAvailable: @escaping () -> Bool = { true }) {
        let text = InterfaceText(title)
        self.init(display: text.display, english: text.english, path: path, keywords: keywords,
                  destination: destination, advanced: advanced, isAvailable: isAvailable)
    }

    /// A title already resolved elsewhere (a credit's `CreditItem.title`), which serves as its own
    /// English. Disfavored, as SwiftUI's `Text` does it, so a bare literal always takes the localized
    /// init above rather than this one.
    @_disfavoredOverload
    init<Title: StringProtocol>(title: Title, path: String, keywords: String, destination: Destination,
                                advanced: Bool = false, isAvailable: @escaping () -> Bool = { true }) {
        self.init(display: String(title), english: String(title), path: path, keywords: keywords,
                  destination: destination, advanced: advanced, isAvailable: isAvailable)
    }

    private init(display: String, english: String, path: String, keywords: String, destination: Destination,
                 advanced: Bool, isAvailable: @escaping () -> Bool) {
        self.title = display
        self.englishTitle = english
        self.path = path
        self.keywords = keywords
        self.destination = destination
        self.advanced = advanced
        self.isAvailable = isAvailable
    }

    /// Each app's own areas: Al-Adhan and Al-Quran share this file.
    enum Destination {
        #if HAS_ADHAN
        case notifications
        case notificationReminders
        case prayerSettings
        /// The Prayer Tracker screen itself (Al-Adhan tab), which owns its own settings since
        /// 2026-09-18 - not a Settings page at all, but the search must still reach the toggle.
        case prayerTracker
        case travelingMode
        case prayerCalculation
        case skyColors
        #endif
        #if HAS_QURAN
        case quranSettings
        case reciters
        #endif
        #if HAS_HADITH
        case hadithSettings
        #endif
        /// Islam Settings: the fourth area, for everything outside the Quran, the prayer times and
        /// the hadith books (the Arabic face, the alphabet controls, the Al-Islam tab itself).
        case islamSettings
        case appearance
        /// About You: who the reader says they are, and the Start Here guide it switches on.
        case aboutYou
        /// Simple Mode's page (`SimpleModeSettingsView`), its switch over the catalog of what it hides:
        /// where its search entry, its tip and the Islam tab's "Too Much on Screen?" door land.
        case simpleMode
        #if HAS_ICLOUD_BACKUP
        /// iCloud Backup: this device's profile, the others in the account, restore. Al-Islam's
        /// alone: the companion apps define no `HAS_ICLOUD_BACKUP` (sync-manifests, FLAG_SKIP).
        case cloudBackup
        #endif
        /// Tips & Tricks: one area's list, or all six behind one door when nil.
        case tips(TipArea?)
        /// Unique Features or Beginner Features: the two settings lists every settings page opens beside
        /// its Tips & Tricks (`FeatureList`, 2026-10-26).
        case featureList(FeatureList)
        case credits
        /// One credited source on the Credits page (`CreditItem.id`): the page opens scrolled to it.
        case credit(String)
        /// A page's own sub-screen, pushed directly (the page enums live in SettingsSearch.swift).
        #if HAS_ADHAN
        case notificationsPage(SettingsNotificationsPage)
        case prayerPage(SettingsAdhanPage)
        #endif
        #if HAS_QURAN
        case quranPage(SettingsQuranPage)
        #endif
        #if HAS_HADITH
        case hadithPage(SettingsHadithPage)
        #endif
        case islamPage(SettingsIslamPage)
        case appearancePage(SettingsAppearancePage)

        /// The chip icon a search result renders with - derived here so entries never repeat it.
        var icon: String {
            switch self {
            #if HAS_ADHAN
            case .notifications: return "bell.badge.fill"
            case .notificationReminders: return "bell.and.waves.left.and.right.fill"
            case .prayerSettings: return "safari.fill"
            case .prayerTracker: return "checklist"
            case .travelingMode: return "airplane"
            case .prayerCalculation: return "globe.europe.africa.fill"
            case .skyColors: return "sunset.fill"
            #endif
            #if HAS_QURAN
            case .quranSettings: return "character.book.closed.ar"
            case .reciters: return "headphones"
            #endif
            #if HAS_HADITH
            case .hadithSettings: return "text.book.closed.fill"
            #endif
            case .islamSettings: return "moon.stars.fill"
            case .appearance: return "paintpalette.fill"
            case .aboutYou: return "person.crop.circle.fill"
            case .simpleMode: return "rectangle.compress.vertical"
            #if HAS_ICLOUD_BACKUP
            case .cloudBackup: return "icloud.fill"
            #endif
            case .tips: return "lightbulb.fill"
            case .featureList(let list): return list.systemImage
            case .credits: return "scroll.fill"
            case .credit: return "link"
            #if HAS_ADHAN
            case .notificationsPage(let page): return page.systemImage
            case .prayerPage(let page): return page.systemImage
            #endif
            #if HAS_QURAN
            case .quranPage(let page): return page.systemImage
            #endif
            #if HAS_HADITH
            case .hadithPage(let page): return page.systemImage
            #endif
            case .islamPage(let page): return page.systemImage
            case .appearancePage(let page): return page.systemImage
            }
        }
    }
}
#endif

struct SettingsView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    #if os(iOS)
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #endif

    @State private var showingCredits = false
    /// The About sheet behind the ⓘ in the toolbar's trailing slot (`aboutButton`).
    @State private var showingAbout = false
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
    /// The spotlight card tapped, and its push: non-nil while the card's page is pushing or pushed.
    @State private var spotlightTarget: AppTip?

    /// The tile tapped on the three-up Your Progress / About You / iCloud Backup row, and its push:
    /// non-nil while that page is pushing or pushed.
    @State private var profileDoor: ProfileTilesSection.Door?

    /// The grid-mode tile that was tapped, and its push (see `SettingsGridTile`): non-nil while its
    /// page is pushing or pushed.
    @State private var gridDoor: SettingsGridDoor?

    /// True while ANY of the three programmatic doors above is pushing or pushed.
    ///
    /// The three `pushDestination(item:)`s are three `navigationDestination(isPresented:)` on ONE
    /// stack. Each tap handler used to set only its own door, so tapping a second tile before the first
    /// push had settled left TWO of them raised at once and asked the stack to push two destinations in
    /// one frame. That is the hazard this file's neighbours already document: the presentation stack
    /// does not recover, the screen goes blank, and the next push can crash inside SwiftUI's navigation
    /// rules (Abu, 2026-10-05: "i go to settings and tap on a bunch and keep switching then it turns
    /// blank for some reason then it just crashes"; same class as the `NavigationLink(isActive:)`
    /// EXC_BAD_ACCESS noted on `PushDestination` in Globals.swift, and the "from then on NOTHING
    /// would present" report on SurahView's picker).
    ///
    /// `openDoor` below is the only way these doors are raised, and it refuses while this is true, so
    /// at most one door is ever open. The second tap is dropped rather than queued: the user is
    /// already travelling to the screen they asked for first, and a queued push would arrive on top
    /// of it as an unexplained extra screen.
    ///
    /// Each door is ONE optional (the target IS the flag), never a Bool beside a target: with the two
    /// apart, the push built its destination before the target's write was readable and the
    /// `EmptyDoor` fallback closed it, four taps in five on 2026-10-11 (Abu: "Look and feel opened a
    /// couple times as a blank tab then after a couple loaded properly"). `PushItemDestination` in
    /// Globals.swift has the account.
    private var anyDoorOpen: Bool {
        spotlightTarget != nil || profileDoor != nil || gridDoor != nil
    }

    /// Raises one door, and only if no other is in flight - see `anyDoorOpen`.
    private func openDoor(_ raise: () -> Void) {
        guard !anyDoorOpen else { return }
        raise()
    }

    /// `pushDestination` is `navigationDestination(isPresented:)`, which needs iOS 16.
    private static var canPushProgrammatically: Bool {
        if #available(iOS 16.0, *) { return true }
        return false
    }

    /// What a grid-mode tile opens: the pages the list's rows push, by name.
    private enum SettingsGridDoor: Hashable {
        #if HAS_ADHAN
        case notifications, prayer
        #endif
        #if HAS_QURAN
        case quran
        #endif
        #if HAS_HADITH
        case hadith
        #endif
        case islam
        case appearance(SettingsAppearancePage)
    }

    @ViewBuilder
    private func gridDestination(_ door: SettingsGridDoor) -> some View {
        switch door {
        #if HAS_ADHAN
        case .notifications: NotificationView()
        case .prayer: SettingsAdhanView(showNotifications: false)
        #endif
        #if HAS_QURAN
        case .quran: SettingsQuranView()
        #endif
        #if HAS_HADITH
        case .hadith: SettingsHadithView(presentedAsSheet: false)
        #endif
        case .islam: SettingsIslamView()
        case .appearance(let page): AppearancePageView(page: page)
        }
    }

    private func openGrid(_ door: SettingsGridDoor) {
        openDoor { gridDoor = door }
    }

    /// Grid mode as a shape draws it: the iPhone stack on iOS 16 and later (the Islam tab's rule). The
    /// iPad/Mac sidebar is a list by nature, and iOS 15 has no programmatic push for the tiles' door.
    private func usesGrid(split: Bool) -> Bool {
        settings.settingsGridMode && !split && Self.canPushProgrammatically
    }

    /// The ⋯ More menu every tab leads with (Abu, 2026-10-11: "for settings and hadith too put it on
    /// the left as a menu"), holding the grid or list switch the trailing edge carried until then: the
    /// same symbols, haptic and wording as the other tabs' items, and hidden while a search is showing
    /// results (the Islam tab's rule).
    @ViewBuilder
    private var settingsMoreMenu: some View {
        if Self.canPushProgrammatically, settingsSearchText.isEmpty {
            TabMoreMenu(hold: MenuShortcut(settings.settingsGridMode ? String(localized: "Show as List") : String(localized: "Show as Grid")) {
                settings.hapticFeedback()
                withAnimation { settings.settingsGridMode.toggle() }
            }) {
                TabMoreMenuItem(settings.settingsGridMode ? String(localized: "Show as List") : String(localized: "Show as Grid"),
                                systemImage: settings.settingsGridMode ? "list.bullet" : "square.grid.2x2") {
                    settings.hapticFeedback()
                    withAnimation { settings.settingsGridMode.toggle() }
                }
            }
        }
    }

    /// The ⓘ in the trailing slot (Abu, 2026-10-25: "top right of settings add an info button that
    /// shows something about Al-Islam"): opens the About sheet. Trailing wears the second accent, as the
    /// gear does on the other tabs; the leading ⋯ menu wears the first.
    private var aboutButton: some View {
        Button {
            settings.hapticFeedback()
            showingAbout = true
        } label: {
            Image(systemName: "info.circle")
        }
        .tint(settings.accentColor.accent2)
        // Its own key: the catalog's "About %@" is the letter families' (حول %@), and a bare الإسلام
        // after it would name the religion, not the app ("تطبيق %@", the Localization Guide's rule).
        .accessibilityLabel(String(localized: "about.app", defaultValue: "About \(AppIdentifiers.displayName)"))
        .accessibilityIdentifier("settingsAboutButton")
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
        // English in every interface language (`englishTitle`, and the `id` built from it): the corpus is
        // one English index whatever the interface shows, so it keeps the version it always had.
        let texts = SettingsSearchEntry.all.map { "\($0.englishTitle) \($0.path) \($0.keywords)" }
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
                // Built from paths and titles: two entries sharing one must not trap.
                let byID = Dictionary(SettingsSearchEntry.all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                settingsAIHits = results.compactMap { result -> SettingsSearchEntry? in
                    if let keys, keys.indices.contains(result.index) { return byID[keys[result.index]] }
                    guard SettingsSearchEntry.all.indices.contains(result.index) else { return nil }
                    return SettingsSearchEntry.all[result.index]
                }
                .filter { $0.isAvailable() }
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
        #if HAS_ADHAN
        case notification
        case prayerSettings
        #endif
        #if HAS_QURAN
        case quranSettings
        #endif
        #if HAS_HADITH
        case hadithSettings
        #endif
        case islamSettings
        /// The Simple Mode page, from the What Moves Where row under the SIMPLE MODE switch: a
        /// selection like the hub rows, so the page fills the detail column rather than pushing inside
        /// the sidebar.
        case simpleMode
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
        #if DEBUG
        let _ = LaunchClock.markOnce("settings root: first body")
        #endif
        navigationContainer
    }

    private var navigationContainer: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                if usesColumnNavigation {
                    NavigationSplitView {
                        settingsSplitList
                            .splitSidebarColumn()
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
        // The iPhone stack only: the iPad/Mac sidebar stays a list (see `usesGrid`).
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { settingsMoreMenu }
        }
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
            .navigationTitle("Settings")
            // The ⓘ keeps the trailing slot on both shapes (the ⋯ More menu leads the iPhone stack only:
            // its grid switch means nothing to the iPad sidebar). One presenter for its sheet, on the
            // list, which the `-showAbout` launch argument raises too.
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { aboutButton }
            }
            .sheet(isPresented: $showingAbout) {
                AboutAppView()
                    .smallMediumSheetPresentation()
            }
            // The Now Playing bar's inset (inside `applyConditionalListStyle`) must be applied BEFORE
            // the search bar's, because bottom safe-area insets stack outward: the one applied first
            // ends up nearest the content, and the one applied last sits below it. With the search bar
            // first, the player landed UNDER it (Abu, 2026-10-07: "ProgressView goes below the search
            // bar in settings"), which is the opposite of the Quran tab, where one inset stacks the
            // player above the search row (`QuranView.nowPlayingInset` then `bottomControls`).
            .applyConditionalListStyle(disableNowPlayingInset: disableNowPlayingInset)
            .adaptiveSafeArea(edge: .bottom) {
                settingsSearchBarInset
            }
            // Each door is pushed from the value that raised it (`pushDestination(item:)`): the target
            // and the flag are one state, so the page can never build without its target. (A flag
            // beside a target did exactly that, see `anyDoorOpen`.) A spotlight tip without a
            // destination is never raised (`openDoor` below checks), so the empty branch there is the
            // same floor `EmptyDoor` is everywhere: it closes rather than leaving a blank page.
            .pushDestination(item: $profileDoor) { door in
                door.destination
            }
            .pushDestination(item: $gridDoor) { door in
                gridDestination(door)
            }
            .pushDestination(item: $spotlightTarget) { tip in
                if let destination = tip.destination {
                    searchDestinationView(destination)
                        .revealsAdvancedSettings(tip.advanced)
                } else {
                    EmptyDoor { spotlightTarget = nil }
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
            // `-showCredits`: the Credits sheet, presented from the root. The tap's own sheet hangs off
            // the CREDITS row, which the lazy list has not built at launch, so setting its flag showed
            // nothing.
            .sheet(isPresented: $debugShowCredits) {
                CreditsView()
                    .smallMediumSheetPresentation()
            }
            .onAppear {
                // `-settingsSearch <query>` seeds the search a moment after the tab appears; `-showCredits`
                // presents the Credits sheet. Typing and tapping are not scriptable in the simulator.
                if let seeded = Self.launchValue("-settingsSearch"), settingsSearchText.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { settingsSearchText = seeded }
                }
                if ProcessInfo.processInfo.arguments.contains("-showCredits") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { debugShowCredits = true }
                }
                // `-showAbout`: the About sheet (the toolbar's ⓘ), presented from the root.
                if ProcessInfo.processInfo.arguments.contains("-showAbout") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showingAbout = true }
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
    @State private var debugShowCredits = false
    @State private var debugOpenProfile = false
    @State private var debugOpenSettingsPage = false

    private static var debugCreditID: String? { launchValue("-openCredit") }

    private static var debugSettingsPage: SettingsSearchEntry.Destination? {
        switch launchValue("-settingsOpen") {
        #if HAS_ADHAN
        case "prayer": return .prayerSettings
        case "prayerSky": return .prayerPage(.sky)
        case "prayerCalculation": return .prayerPage(.prayerCalculation)
        case "prayerOffsets": return .prayerPage(.manualOffsets)
        case "prayerNames": return .prayerPage(.customPrayerNames)
        case "skyColors": return .skyColors
        case "travelingMode": return .prayerPage(.travelingMode)
        case "notifications": return .notifications
        case "prayerReminders": return .notificationsPage(.prayerReminders)
        case "nagging": return .notificationsPage(.naggingMode)
        #endif
        #if HAS_QURAN
        case "quran": return .quranSettings
        // The Quran sub-pages, so each can be screenshotted without a tap.
        case "quranRecitation": return .quranPage(.recitation)
        case "quranReading": return .quranPage(.readingView)
        case "quranArabic": return .quranPage(.arabicText)
        case "quranEnglish": return .quranPage(.englishText)
        case "quranTestMode": return .quranPage(.testMode)
        case "quranFavorites": return .quranPage(.favorites)
        case "islamReminders": return .islamPage(.sunnahReminders)
        #endif
        #if HAS_HADITH
        case "hadith": return .hadithSettings
        #endif
        case "islam": return .islamSettings
        // The Islam sub-pages, so each can be screenshotted without a tap.
        case "islamArabic": return .islamPage(.arabicText)
        case "islamTextSize": return .islamPage(.textSize)
        case "islamAlphabet": return .islamPage(.alphabet)
        case "islamLibraries": return .islamPage(.libraries)
        case "aboutYou": return .aboutYou
        case "simpleMode": return .simpleMode
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
        // The two feature lists every settings page opens (2026-10-26), each screenshotted on its own.
        case "uniqueFeatures": return .featureList(.unique)
        case "beginnerFeatures": return .featureList(.beginner)
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
            openDoor { profileDoor = door }
        }
        #endif

        Group {
            #if os(iOS)
            if split, #available(iOS 16.0, *) {
                settingsHubSectionSplit
            } else if usesGrid(split: split) {
                settingsHubGridSection
            } else {
                settingsHubSection
            }
            #else
            settingsHubSection
            #endif
        }

        // Directly under the settings rows, in both modes (Abu, 2026-10-10): the switch that changes
        // how busy every tab is has to be the first thing found here, and in Simple Mode it is also
        // the way back out (Docs/Product/Simple Mode Guide.md). iPhone, iPad and Mac only: the watch's screens
        // do not read it.
        #if os(iOS)
        if split, #available(iOS 16.0, *) {
            // The split root reaches the Simple Mode page the way it reaches the hub's pages: a
            // selection that fills the detail column (`splitResourceLink`).
            SimpleModeSection(splitCatalogRow: AnyView(splitResourceLink(
                title: SimpleModeSection.catalogRowTitle,
                systemImage: SimpleModeSection.catalogRowImage,
                value: .simpleMode
            )))
        } else {
            SimpleModeSection()
        }
        #endif

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
                // The split's detail column is a SELECTION, not a push: swapping it cannot stack two
                // destinations, so it needs no door guard.
                selectSplitDestination(.spotlight(tip.id))
            } else if tip.destination != nil {
                openDoor { spotlightTarget = tip }
            }
        }
        #endif

        #if os(iOS)
        appearanceSection(grid: usesGrid(split: split))
        #else
        appearanceSection(grid: false)
        #endif
        // Reset stays a row in both modes: a destructive action keeps its explanation and its two
        // confirmations, never a tile's one tap.
        resetSection
        #if os(iOS)
        creditsSection(grid: usesGrid(split: split))
        #else
        creditsSection(grid: false)
        #endif

        AlIslamAppsSection()
    }

    #if os(iOS)
    @ViewBuilder
    private var settingsSplitDetail: some View {
        Group {
            switch selectedDestination ?? Self.defaultDestination {
            #if HAS_ADHAN
            case .notification:
                NotificationView()
            case .prayerSettings:
                SettingsAdhanView(showNotifications: false)
            #endif
            #if HAS_QURAN
            case .quranSettings:
                SettingsQuranView()
            #endif
            #if HAS_HADITH
            case .hadithSettings:
                SettingsHadithView(presentedAsSheet: false)
            #endif
            case .islamSettings:
                SettingsIslamView()
            case .simpleMode:
                SimpleModeSettingsView()
            case .spotlight(let id):
                // Exactly what the card pushes on iPhone (`spotlightTarget`), as the detail's root.
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
            Section(header: SectionPillHeader(title: String(localized: "AI MATCHES"), count: aiOnly.count, icon: "sparkles")) {
                ForEach(aiOnly) { entry in
                    settingsSearchResultRow(entry)
                }
            }
        }

        Section(header: SectionPillHeader(title: String(localized: "SETTING RESULTS"), count: results.count, icon: "magnifyingglass")) {
            if results.isEmpty {
                Text(aiOnly.isEmpty ? String(localized: "No settings match your search.") : String(localized: "No keyword matches. See the AI results above."))
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

                // The caption column is an iPhone luxury: the 40mm screen has no room for it. One
                // line, except at the accessibility sizes, where it cut every hub caption short
                // ("Fonts, translations, tajweed...", see `SettingsRowLabel.stacks`).
                #if os(iOS)
                if let subtitle {
                    let wraps = dynamicTypeSize.isAccessibilitySize
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(wraps ? nil : 1)
                        .minimumScaleFactor(wraps ? 1 : 0.8)
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
        // the row addressable by the selection (keyboard and pointer), the Islam sidebar's pattern.
        //
        // The HIGHLIGHT is drawn here, not left to `List(selection:)` (Abu, 2026-10-05: "sometimes
        // it gets highlighted then it stops sometimes it doesnt highlight at all"). Three separate
        // things were destroying the native selection bed, which is why it looked intermittent:
        //   1. `.buttonStyle(.plain)` consumes the tap, so the List never routes a selection gesture
        //      and never draws a bed - the `.tag` makes the row addressable, not highlighted.
        //   2. `themedListRowBackground()` (applied to this whole list) sets `.listRowBackground`,
        //      which REPLACES the cell background - including the bed - on Sepia, Gray and Custom.
        //   3. "Default List View" off makes every list `.listStyle(.plain)`, which draws no bed at
        //      all, and the style is latched at first appear, so it changes only after a relaunch.
        // The row's own cell background (`rowSelectionHighlight`) survives all three.
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
        .rowSelectionHighlight(selectedDestination == value)
    }

    /// The four settings destinations as ONE card - the old one-row-per-section layout spent most
    /// of the screen on headers. Notifications shown on watchOS too (it supports local notifications).
    /// Each area wears its own fixed colour (`SettingsTint`: prayer yellow, Quran green, hadith blue),
    /// the iOS Settings app's grammar. Every page behind these rows carries its own search bar.
    @ViewBuilder
    private var settingsHubSection: some View {
        Section(header: SectionIconHeader(String(localized: "SETTINGS"), icon: "gearshape.fill")) {
            #if HAS_ADHAN
            resourceLink(title: String(localized: "Notifications"), systemImage: "bell.badge.fill",
                         subtitle: NotificationView.doorSubtitle, tint: SettingsTint.notifications) {
                NotificationView()
            }
            resourceLink(title: String(localized: "Prayer Settings"), systemImage: "safari.fill",
                         subtitle: String(localized: "Calculation, offsets, travel, sky"), tint: SettingsTint.prayer) {
                SettingsAdhanView(showNotifications: false)
            }
            #endif
            #if HAS_QURAN
            resourceLink(title: String(localized: "Quran Settings"), systemImage: "character.book.closed.ar",
                         subtitle: String(localized: "Fonts, tajweed, reciters, themes"), tint: SettingsTint.quran) {
                SettingsQuranView()
            }
            #endif
            #if os(iOS)
            #if HAS_HADITH
            resourceLink(title: String(localized: "Hadith Settings"), systemImage: "text.book.closed.fill",
                         subtitle: String(localized: "Arabic and English, reading view"), tint: SettingsTint.hadith) {
                SettingsHadithView(presentedAsSheet: false)
            }
            #endif
            // The fourth area, for what belongs to none of the three above. It wears BOTH brand
            // colours rather than one of its own, because it is not one tab (see `SettingsTint.islam`).
            resourceLink(title: String(localized: "Islam Settings"), systemImage: "moon.stars.fill",
                         subtitle: String(localized: "Arabic font, libraries, reminders"),
                         tint: SettingsTint.islam, secondaryTint: SettingsTint.islamSecondary) {
                SettingsIslamView()
            }
            #endif
        }
    }

    #if os(iOS)
    /// The hub in grid mode: Notifications across the top as a banner, because it spans every area,
    /// then the four areas two by two in the tab bar's order (Prayer, Quran / Hadith, Islam). The same
    /// five pages as the rows, each keeping its caption: it is how people find where a setting lives.
    /// The captions are short enough for a tile's one line at its 0.75 scale floor (Abu, 2026-10-11:
    /// "line limit 1 looks chopped so shorten the actual text"); the rows say the same words.
    private var settingsHubGridSection: some View {
        Section(header: SectionIconHeader(String(localized: "SETTINGS"), icon: "gearshape.fill")) {
            VStack(spacing: 8) {
                #if HAS_ADHAN
                SettingsGridBanner(title: String(localized: "Notifications"), systemImage: "bell.badge.fill",
                                   caption: String(localized: "Prayer alerts, adhan sounds, reminders"),
                                   tint: SettingsTint.notifications) { openGrid(.notifications) }
                #endif

                #if HAS_ADHAN && HAS_QURAN && HAS_HADITH
                SettingsGridTileRow {
                    prayerGridTile
                    quranGridTile
                }

                SettingsGridTileRow {
                    SettingsGridTile(title: String(localized: "Hadith Settings"), systemImage: "text.book.closed.fill",
                                     caption: String(localized: "Arabic and English, reading view"),
                                     tint: SettingsTint.hadith, prominent: true) { openGrid(.hadith) }
                    islamGridTile
                }
                #else
                // A companion app's one area beside Islam Settings, on one row.
                SettingsGridTileRow {
                    #if HAS_ADHAN
                    prayerGridTile
                    #endif
                    #if HAS_QURAN
                    quranGridTile
                    #endif
                    islamGridTile
                }
                #endif
            }
            .padding(.vertical, 1)
        }
    }

    #if HAS_ADHAN
    private var prayerGridTile: some View {
        SettingsGridTile(title: String(localized: "Prayer Settings"), systemImage: "safari.fill",
                         caption: String(localized: "Calculation, offsets, travel, sky"),
                         tint: SettingsTint.prayer, prominent: true) { openGrid(.prayer) }
    }
    #endif

    #if HAS_QURAN
    private var quranGridTile: some View {
        SettingsGridTile(title: String(localized: "Quran Settings"), systemImage: "character.book.closed.ar",
                         caption: String(localized: "Fonts, tajweed, reciters, themes"),
                         tint: SettingsTint.quran, prominent: true) { openGrid(.quran) }
    }
    #endif

    /// Both brand colours, as on its row (see `SettingsTint.islam`).
    private var islamGridTile: some View {
        SettingsGridTile(title: String(localized: "Islam Settings"), systemImage: "moon.stars.fill",
                         caption: String(localized: "Arabic font, libraries, reminders"),
                         tint: SettingsTint.islam, secondaryTint: SettingsTint.islamSecondary,
                         prominent: true) { openGrid(.islam) }
    }
    #endif

    @available(iOS 16.0, *)
    @ViewBuilder
    private var settingsHubSectionSplit: some View {
        Section(header: SectionIconHeader(String(localized: "SETTINGS"), icon: "gearshape.fill")) {
            #if HAS_ADHAN
            splitResourceLink(title: String(localized: "Notifications"), systemImage: "bell.badge.fill",
                              subtitle: NotificationView.doorSubtitle, tint: SettingsTint.notifications, value: .notification)
            splitResourceLink(title: String(localized: "Prayer Settings"), systemImage: "safari.fill",
                              subtitle: String(localized: "Calculation, offsets, travel, sky"), tint: SettingsTint.prayer, value: .prayerSettings)
            #endif
            #if HAS_QURAN
            splitResourceLink(title: String(localized: "Quran Settings"), systemImage: "character.book.closed.ar",
                              subtitle: String(localized: "Fonts, tajweed, reciters, themes"), tint: SettingsTint.quran, value: .quranSettings)
            #endif
            #if HAS_HADITH
            splitResourceLink(title: String(localized: "Hadith Settings"), systemImage: "text.book.closed.fill",
                              subtitle: String(localized: "Arabic and English, reading view"), tint: SettingsTint.hadith, value: .hadithSettings)
            #endif
            splitResourceLink(title: String(localized: "Islam Settings"), systemImage: "moon.stars.fill",
                              subtitle: String(localized: "Arabic font, libraries, reminders"),
                              tint: SettingsTint.islam, secondaryTint: SettingsTint.islamSecondary, value: .islamSettings)
        }
    }

    @ViewBuilder
    private var resetSection: some View {
        #if os(iOS)
        Section(header: SectionIconHeader(String(localized: "RESET"), icon: "arrow.counterclockwise")) {
            Button(role: .destructive) {
                settings.hapticFeedback()
                showResetConfirmation = true
            } label: {
                toolLabel(String(localized: "Reset All Settings"), systemImage: "arrow.counterclockwise", chipTint: .red)
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

    /// `grid`: the two appearance pages as tiles under the theme and accent controls (which stay).
    private func appearanceSection(grid: Bool) -> some View {
        Section(header: SectionIconHeader(String(localized: "APPEARANCE"), icon: "paintpalette.fill")) {
            #if os(iOS)
            if grid {
                SettingsAppearanceView(openPage: { openGrid(.appearance($0)) })
            } else {
                SettingsAppearanceView()
            }
            languageRow
            #else
            SettingsAppearanceView()
            #endif
        }
    }

    #if os(iOS)
    /// The interface language (Arabic, 2026-10-24). iOS keeps the per-app choice in its own Settings
    /// (Settings > Al-Islam > Language), so this row names the current language and opens that page.
    private var languageRow: some View {
        Button {
            settings.hapticFeedback()
            openAppSettings()
        } label: {
            SettingsRowLabel(
                title: String(localized: "Language"),
                systemImage: "globe",
                subtitle: String(localized: "Chosen in the Settings app"),
                value: Locale(identifier: AppLanguage.code).localizedString(forLanguageCode: AppLanguage.code)?
                    .localizedCapitalized
            )
        }
        .foregroundStyle(.primary)
    }
    #endif

    /// `grid`: the three actions as one row of tiles, the profile row's three-across grammar. The
    /// website and email lines stay rows: they are text to read and copy, not buttons.
    private func creditsSection(grid: Bool) -> some View {
        Section(header: SectionIconHeader(String(localized: "CREDITS"), icon: "scroll.fill")) {
            creditsIntro
            #if os(iOS)
            if grid {
                creditsTiles
            } else {
                viewCreditsButton
                // App Settings first, the review below it (Abu, 2026-09-16).
                openAppSettingsButton
                leaveReviewButton
            }
            #else
            viewCreditsButton
            openAppSettingsButton
            leaveReviewButton
            #endif
            websiteRow
            contactRow
            VersionNumber(width: glyphWidth)
                .font(.subheadline)
        }
    }

    #if os(iOS)
    private var creditsTiles: some View {
        SettingsGridTileRow {
            SettingsGridTile(title: String(localized: "View Credits"), systemImage: "scroll.fill", tint: SettingsTint.credits) {
                showingCredits = true
            }
            SettingsGridTile(title: String(localized: "Open App Settings"), systemImage: "gearshape.fill", tint: SettingsTint.credits,
                             haptic: false) {
                openAppSettings()
            }
            SettingsGridTile(title: String(localized: "Leave a Review"), systemImage: "star.bubble.fill", haptic: false) {
                leaveReview()
            }
        }
        .padding(.vertical, 1)
        // On the row, not a tile: one presenter for the one sheet (the list row's own rule).
        .sheet(isPresented: $showingCredits) {
            CreditsView()
                .smallMediumSheetPresentation()
        }
    }
    #endif

    private var creditsIntro: some View {
        Text(String(localized: "Made by Abubakr Elmallah, who was a 17-year-old high school student when this app was made.\n\nSpecial thanks to my parents and to Mr. Joe Silvey, my English teacher and Muslim Student Association Advisor.").localizedDigits)
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
            toolLabel(String(localized: "View Credits"), systemImage: "scroll.fill", chipTint: SettingsTint.credits)
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
            toolLabel(String(localized: "Leave a Review"), systemImage: "star.bubble.fill")
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
            toolLabel(String(localized: "Open App Settings"), systemImage: "gearshape.fill", chipTint: SettingsTint.credits)
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
        columnWidth(for: .subheadline, extra: 0, sample: String(localized: "Contact: "))
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
            Section(header: Text("APPEARANCE")) {
                SettingsAppearanceView()
            }
        }
        .navigationTitle("Appearance")
    }
}

extension SettingsSearchEntry {
    static let appearanceEntries: [SettingsSearchEntry] = appearanceControlEntries.filter { entry in
        LaunchTab.isOffered || entry.englishTitle != "Open the App On"
    }

    private static let appearanceControlEntries: [SettingsSearchEntry] = [
        .init(title: "Accent Color", path: "Appearance", keywords: "green color swatch tint theme", destination: .appearance),
        .init(title: "Language", path: "Appearance", keywords: "language arabic english interface translate عربي العربية", destination: .appearance),
        .init(title: "App Theme (Light / Dark / Sepia / Gray)", path: "Appearance", keywords: "dark mode light mode night reading sepia gray paper background", destination: .appearance),
        .init(title: "Custom Background Color", path: "Appearance → Custom Colors", keywords: "custom color background hex picker theme", destination: .appearancePage(.customColors)),
        .init(title: "Custom Accent Color", path: "Appearance → Custom Colors", keywords: "custom color accent hex picker tint own", destination: .appearancePage(.customColors)),
        .init(title: "Top Accent Glow", path: "Appearance → Custom Colors", keywords: "glow wash gradient accent top background flat hide al islam green yellow brand", destination: .appearancePage(.customColors)),
        .init(title: "Open the App On", path: "Appearance → Look and Feel", keywords: "launch start first tab open adhan quran hadith islam default home landing", destination: .appearancePage(.lookAndFeel)),
        .init(title: "Default List View", path: "Appearance → Look and Feel", keywords: "list style plain grouped inset layout", destination: .appearancePage(.lookAndFeel)),
        .init(title: "Classic Look (No Liquid Glass)", path: "Appearance → Look and Feel", keywords: "liquid glass classic look performance faster battery low power mode ios 26 old design", destination: .appearancePage(.lookAndFeel)),
        .init(title: "Haptic Feedback", path: "Appearance → Look and Feel", keywords: "vibration taptic buzz feedback toggle", destination: .appearancePage(.lookAndFeel)),
        .init(title: "Simple Mode", path: "Settings", keywords: "simple simpler busy clutter cluttered overwhelming overwhelmed essentials less minimal declutter calm fewer buttons", destination: .simpleMode),
        .init(title: "Need a Hand? on Every Tab", path: "Appearance → Look and Feel", keywords: "help shortcuts need a hand need help praying reading questions rows doors tabs hide show all nagging beginner transliteration", destination: .appearancePage(.lookAndFeel)),
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
        case .adhan: return String(localized: "Adhan")
        case .quran: return String(localized: "Quran")
        case .hadith: return String(localized: "Hadith")
        case .islam: return String(localized: "Islam")
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
    private let settings = Settings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
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

            Picker("Open the App On", selection: selection) {
                ForEach(LaunchTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: settings.launchTabRaw) { _ in settings.hapticFeedback() }
        }
    }

    /// The note under the picker, as its section's footer on Look and Feel.
    static let footer = String(localized: "The tab you land on when the app opens. A notification or a reminder you tap still opens where it points.")
}

// MARK: - Appearance sub-screens

/// One of Appearance's two sub-screens (`SettingsAppearancePage`): the controls that used to run
/// down the Settings tab under the swatches, unchanged, one push away.
struct AppearancePageView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
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
        // Holds the "Default List View" switch, so it restyles live (G3).
        .applyConditionalListStyle(followsListViewLive: page == .lookAndFeel)
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
                settings.accentColor = .custom
            }
        )
    }

    /// On = custom accent is active (color picker enabled). Off = revert to the app's default accent.
    private var customColorEnabledBinding: Binding<Bool> {
        Binding(
            get: { settings.accentColor == .custom },
            set: { isOn in
                settings.accentColor = isOn ? .custom : AppIdentifiers.mainColor
            }
        )
    }

    /// Reads/writes the stored custom background hex; picking a color also switches the active theme to `custom`.
    private var customBackgroundColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: settings.customBackgroundColorHex) ?? .gray },
            set: { newColor in
                settings.customBackgroundColorHex = newColor.hexString
                settings.colorSchemeString = "custom"
            }
        )
    }

    /// On = custom background theme is active. Off = revert to the System theme.
    private var customBackgroundEnabledBinding: Binding<Bool> {
        Binding(
            get: { settings.colorSchemeString == "custom" },
            set: { isOn in
                settings.colorSchemeString = isOn ? "custom" : "system"
            }
        )
    }

    /// One line: color well, label, then a toggle tinted with the custom color itself (not the accent).
    private func colorRow(_ title: String, color: Binding<Color>, enabled: Binding<Bool>, tint: Color) -> some View {
        HStack(spacing: 12) {
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()

            Text(title)

            Spacer()

            Toggle("", isOn: enabled)
                .labelsHidden()
                .tint(tint)
        }
    }

    @ViewBuilder
    private var customColorsSections: some View {
        Section {
            VStack(alignment: .leading) {
                colorRow(String(localized: "Custom Background"), color: customBackgroundColorBinding, enabled: customBackgroundEnabledBinding,
                         tint: Color(hex: settings.customBackgroundColorHex) ?? .gray)
                    .onChange(of: settings.colorSchemeString) { _ in settings.hapticFeedback() }

                SettingsCaption(String(localized: "Pick any background color for the whole app. Light or dark text is chosen automatically so it stays readable."))
                    .padding(.vertical, 2)
            }

            VStack(alignment: .leading) {
                colorRow(String(localized: "Custom Color"), color: customAccentColorBinding, enabled: customColorEnabledBinding,
                         tint: Color(hex: settings.customAccentColorHex) ?? .green)
                    .onChange(of: settings.accentColor) { _ in settings.hapticFeedback() }

                SettingsCaption(String(localized: "An accent of your own in place of the swatches on the Settings tab. Turning it off goes back to the app's green."))
                    .padding(.vertical, 2)
            }
        } header: {
            Text("YOUR OWN COLORS")
        }

        Section {
            VStack(alignment: .leading) {
                SettingsToggle(String(localized: "Top Accent Glow"), caption: String(localized: "A soft wash of your accent color at the top of each screen. Turn it off for a flat background."), isOn: $appearanceSettings.showAccentGlow)

                if settings.showAccentGlow {
                    SettingsToggle(String(localized: "Al-Islam Glow"), caption: String(localized: "Color the glow with Al-Islam's yellow and green (yellow from the left, green from the right) instead of your accent color."), isOn: $appearanceSettings.alIslamGlow)
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
            } footer: {
                Text(LaunchTabPicker.footer)
            }
        }

        Section {
            SettingsToggle(String(localized: "Default List View"), caption: String(localized: "Apple's standard list look, as in Notes. Screens already open switch the next time they open."), isOn: $appearanceSettings.defaultView)

            if #available(iOS 26.0, *) {
                VStack(alignment: .leading) {
                    SettingsToggle(String(localized: "Show Liquid Glass"), caption: String(localized: "Off is the Classic Look from before iOS 26: faster and easier on the battery. iOS's own bars, sheets and search field keep Liquid Glass either way."), isOn: $appearanceSettings.showLiquidGlass)

                    if settings.showLiquidGlass {
                        SettingsToggle(String(localized: "Automatically in Low Power Mode"), caption: String(localized: "Turns Liquid Glass off while Low Power Mode is on and brings it back when Low Power Mode is off."), isOn: $appearanceSettings.classicLookInLowPower)
                        .settingsDependent()
                    }
                }
            }
        } header: {
            Text("HOW IT LOOKS")
        }

        Section {
            SettingsToggle(String(localized: "Haptic Feedback"), isOn: $systemSettings.hapticOn)
        } header: {
            Text("HOW IT FEELS")
        }

        // The Need a Hand? questions on every tab (HelpDoors.swift), all four at once. Each tab's own
        // switch is on its settings page, beside the list of that tab's questions.
        Section {
            SettingsToggle(String(localized: "Show on Every Tab"), caption: helpShortcutsCaption, isOn: helpShortcutsBinding)
        } header: {
            Text("NEED A HAND?")
        }
    }

    /// On while any tab shows its questions. The haptic rides the binding, not an `onChange`: hiding
    /// the last tab's section from its own menu must not tick here too.
    private var helpShortcutsBinding: Binding<Bool> {
        Binding(
            get: { settings.showHelpShortcuts },
            set: { newValue in
                settings.hapticFeedback()
                settings.showHelpShortcuts = newValue
            }
        )
    }

    /// The examples name only the tabs this app has: Al-Adhan and Al-Quran share this file, and a
    /// question about a tab the reader does not have would send them looking for it.
    private var helpShortcutsCaption: String {
        #if HAS_ADHAN && HAS_QURAN
        let intro = String(localized: "A few questions on each tab, each with the setting that answers it: Need Help Praying? on the prayer times opens Nagging Mode, and Need Help Reading? on the Quran answers with Arabic Beginner Mode. Each tab also has its own switch, on its settings page.")
        #elseif HAS_ADHAN
        let intro = String(localized: "A few questions on each tab, each with the setting that answers it: Need Help Praying? on the prayer times opens Nagging Mode. Each tab also has its own switch, on its settings page.")
        #elseif HAS_QURAN
        let intro = String(localized: "A few questions on each tab, each with the setting that answers it: Need Help Reading? on the Quran answers with Arabic Beginner Mode. Each tab also has its own switch, on its settings page.")
        #else
        let intro = String(localized: "A few questions on each tab, each with the setting that answers it. Each tab also has its own switch, on its settings page.")
        #endif
        let hidden = settings.hiddenHelpDoorTabs
        guard !hidden.isEmpty, hidden.count < HelpDoorArea.allCases.count else { return intro }
        let names = hidden.count == 1 ? hidden[0] : hidden.sentenceList { String(localized: "\($0.dropLast().joined(separator: ", ")) and \($0.last!)") }
        return hidden.count == 1 ? String(localized: "\(intro) Hidden now on the \(names) tab.") : String(localized: "\(intro) Hidden now on the \(names) tabs.")
    }
}
#endif

/// The APPEARANCE section of the Settings tab: the two controls people reach for (the theme and the
/// accent swatches), then a door to each sub-screen. The watch has only the swatches and the haptics
/// switch, so it keeps both inline.
struct SettingsAppearanceView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    #if os(iOS)
    /// Grid mode (`SettingsView.usesGrid`): the two pages as tiles that hand their page to the list's
    /// one push. Nil keeps the rows.
    var openPage: ((SettingsAppearancePage) -> Void)? = nil

    /// The iPad sidebar gives the five-segment theme control about 54 pt a segment, and "System"
    /// showed as "Syst..." there (2026-09-06 iPad pass); iPads say "Auto". Keyed on the idiom, not
    /// the size class: a split view's sidebar column reports `.compact` even on a 13-inch iPad.
    private var systemThemeLabel: String {
        UIDevice.current.userInterfaceIdiom != .phone ? String(localized: "Auto") : String(localized: "System")
    }
    #endif

    // Accent-swatch grid metrics. The watch gets fewer, smaller swatches with tighter gutters so each circle
    // actually FITS its column (see the note on the grid below); the phone keeps the roomier original.
    #if os(watchOS)
    private static let swatchColumns = 4
    private static let swatchDiameter: CGFloat = 22
    private static let swatchSpacing: CGFloat = 6
    private static let swatchGridVerticalPadding: CGFloat = 4
    private static let swatchGridMaxWidth: CGFloat = .infinity
    #else
    private static let swatchColumns = 4
    private static let swatchDiameter: CGFloat = 30
    private static let swatchSpacing: CGFloat = 12
    private static let swatchGridVerticalPadding: CGFloat = 16
    /// See the grid's `.frame(maxWidth:)`: four 30 pt swatches about 100 pt apart.
    private static let swatchGridMaxWidth: CGFloat = 400
    #endif

    private func accentSwatch(_ accentColor: AccentColor) -> some View {
        // Every preset is a single colour, so a plain circle is right here.
        Circle()
            // The hue that names the choice, not the deeper shade light mode paints text with.
            .fill(accentColor.swatchColor)
            .frame(width: Self.swatchDiameter, height: Self.swatchDiameter)
            .overlay(
                Circle()
                    .stroke(settings.accentColor == accentColor ? Color.primary : Color.clear, lineWidth: 2)
            )
            .accessibilityLabel(accentColor.displayName)
            // A tap gesture, not a Button: VoiceOver heard "Green" with no word that it is a button
            // or that it is the accent in use.
            .accessibilityAddTraits(settings.accentColor == accentColor ? [.isButton, .isSelected] : .isButton)
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
            Picker("Color Theme", selection: $appearanceSettings.colorSchemeString) {
                Text(systemThemeLabel).tag("system")
                // Its own key: "Light" is also a letter's weight in the tajweed course (مرقّقة).
                Text(String(localized: "appearance.light", defaultValue: "Light")).tag("light")
                Text("Dark").tag("dark")
                Text("Gray").tag("gray")
                Text("Sepia").tag("sepia")
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: settings.colorSchemeString) { _ in settings.hapticFeedback() }

            SettingsCaption(String(localized: "System follows your device. Light theme in Light Mode, Dark theme in Dark Mode. Other themes are ignored."))
                .padding(.vertical, 2)
        }
        #endif

        VStack(alignment: .leading) {
            // Sized per platform. A watch list row is only ~120pt wide, so four fixed-width columns with 12pt
            // gutters gave each cell LESS room than the 30pt circle it had to hold: the swatches overflowed
            // their cells, the grid grew its row heights to compensate, and `.padding(.vertical)` piled 32pt on
            // top - which is the "random huge padding" on the watch. The phone has the width for the original
            // layout, so it keeps it.
            // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different height on
            // each self-sizing pass, which iOS 26 traps on.
            SummaryTileGrid(columns: Self.swatchColumns, spacing: Self.swatchSpacing) {
                ForEach(accentColors, id: \.self) { accentColor in
                    accentSwatch(accentColor)
                }
            }
            // The four columns at an iPhone's spacing, whatever the row's width: an iPad detail column
            // spread the twelve dots over 1,400 pt with 350 pt between them (2026-10-12). Narrower than
            // any iPhone row, so the phone's grid is untouched; wider rows centre the cluster.
            .frame(maxWidth: Self.swatchGridMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Self.swatchGridVerticalPadding)
            #if os(iOS)
            .onChange(of: settings.accentColor) { _ in settings.hapticFeedback() }
            #endif

            #if os(iOS)
            SettingsCaption(String(localized: "Anas ibn Malik (may Allah be pleased with him) said, “The most beloved of colors to the Messenger of Allah (peace be upon him) was green.”"))
                .padding(.vertical, 2)
            #endif
        }

        #if os(iOS)
        if let openPage {
            SettingsGridTileRow {
                ForEach(SettingsAppearancePage.allCases, id: \.self) { page in
                    SettingsGridTile(title: page.title, systemImage: page.systemImage, caption: page.caption,
                                     tint: SettingsTint.appearance, prominent: true) { openPage(page) }
                }
            }
            .padding(.vertical, 1)
        } else {
            // One List row each: a row may hold only one link.
            ForEach(SettingsAppearancePage.allCases, id: \.self) { page in
                NavigationLink(destination: LazyDestination { AppearancePageView(page: page) }) {
                    SettingsRowLabel(title: page.title, systemImage: page.systemImage, subtitle: page.caption,
                                     tint: SettingsTint.appearance)
                }
                .tint(settings.accentColor.color)
            }
        }
        #else
        SettingsToggle(String(localized: "Haptic Feedback"), isOn: $systemSettings.hapticOn)
        #endif
    }
}

#if os(iOS)
// MARK: - Grid mode tiles

/// One tile of the Settings tab's grid mode (2026-09-26, the grid button the Quran, Hadith and Islam
/// tabs already have), drawn the way those tabs draw theirs (Abu, 2026-09-28: "grid mode in settings
/// doesn't look the same as everywhere else. make it consistent liquid glass"). It used to sit on a
/// flat accent wash with a 14 pt curve and a title a size up from every other grid; now it is the
/// Islam resource tile's surface and scale: clear Liquid Glass on the shared `GlassCorner` curve, a
/// 32 pt chip, the title under it, and the caption in the glass's own secondary (`.secondary` reads
/// at 3.1:1 on glass). Always a Button: a grid is one List row, and several NavigationLinks in one row
/// all fire on any tap (`one-link-per-list-row`), so each tile writes one door and the list owns the
/// push. A leaf: it observes nothing.
struct SettingsGridTile: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let systemImage: String
    var caption: String? = nil
    var tint: Color? = nil
    var secondaryTint: Color? = nil
    /// The hub's areas and the appearance pages, two across: a footnote title over a caption that
    /// says what the page holds (how people find where a setting lives). Off, the Islam tile's
    /// caption-sized title for three across.
    var prominent: Bool = false
    /// Off for an action that already taps its own haptic (App Settings, the review), so one tap is
    /// one tick.
    var haptic: Bool = true
    /// Lines the caption may take below the accessibility sizes: one on a tool tile, two on a profile
    /// tile whose caption is an answer the reader gave ("Just getting started").
    var captionLines: Int = 1
    let action: () -> Void

    var body: some View {
        Button {
            if haptic { Settings.shared.hapticFeedback() }
            action()
        } label: {
            VStack(spacing: 6) {
                AccentIconChip(systemImage: systemImage, tint: tint, secondaryTint: secondaryTint, size: 32)

                Text(title.interfaceParagraph)
                    .font(prominent ? .footnote.weight(.semibold) : .caption2.weight(.medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .minimumScaleFactor(0.8)

                if let caption {
                    // One line (Abu, 2026-10-11: "make sure each caption line is line limit 1"), as the
                    // list rows' captions are (`toolLabel`); it scales down to 0.75 before it truncates,
                    // and the captions are written short enough never to (same day: "looks chopped so
                    // shorten the actual text"). The accessibility sizes keep wrapping: the tiles stack
                    // one per row there, and a one-line clamp cut every caption short.
                    Text(caption.interfaceParagraph)
                        .font(.caption2)
                        .foregroundColor(.secondaryOnGlass)
                        .multilineTextAlignment(.center)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : captionLines)
                        .minimumScaleFactor(0.75)
                }
            }
            // Equal heights across a row: the row fixes its own height, and each tile fills it.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
            .conditionalGlassEffect(clear: true, rectangle: true)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption.map { "\(title). \($0)" } ?? title)
        .accessibilityAddTraits(.isButton)
    }
}

/// A full-width grid tile: the chip beside the title and caption, the Islam tab's Ask AI banner. The
/// grid mode's one area that spans every other (Notifications) gets the whole row, as Ask AI does.
struct SettingsGridBanner: View {
    let title: String
    let systemImage: String
    let caption: String
    var tint: Color? = nil
    let action: () -> Void

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: systemImage, tint: tint, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(caption)
                        .font(.caption)
                        .foregroundColor(.secondaryOnGlass)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .conditionalGlassEffect(clear: true, rectangle: true)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(caption)")
        .accessibilityAddTraits(.isButton)
    }
}

/// Tiles side by side, or one per line at the accessibility text sizes (two or three across left each
/// caption a few letters wide). Equal heights in a row: the profile row's `fixedSize` + fill trick.
struct SettingsGridTileRow<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ViewBuilder let content: () -> Content

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 8) { content() }
                .fixedSize(horizontal: false, vertical: true)
        } else {
            HStack(alignment: .center, spacing: 8) { content() }
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

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
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Observed for the same reason `ProfileSettingsRow` observes them: the deferred last-read load
    /// and a badge unlocked elsewhere must both re-render this row's caption.
    #if HAS_QURAN
    @ObservedObject private var quranData = QuranData.shared
    #endif
    #if HAS_HADITH
    @ObservedObject private var hadithStore = HadithStore.shared
    #endif
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
        #if HAS_QURAN
        let stats = ProfileStats.current(settings: settings, quranData: quranData)
        #else
        let stats = ProfileStats.current(settings: settings)
        #endif
        #if HAS_ADHAN
        if stats.prayer.currentStreak > 0 {
            return String(localized: "\(stats.prayer.currentStreak)-day streak")
        }
        #endif
        #if HAS_QURAN
        if stats.khatmCompleted > 0 {
            return String(localized: "\(Int((stats.khatmFraction * 100).rounded()))% read")
        }
        #endif
        let earned = achievements.unlockedCount(stats)
        if earned > 0 {
            return earned == 1 ? String(localized: "1 badge") : String(localized: "\(earned) badges")
        }
        return String(localized: "Nothing yet")
    }

    private var tiles: [Tile] {
        var list = [
            Tile(door: .progress, title: String(localized: "Your Progress"), systemImage: "person.crop.circle.fill",
                 value: progressValue, tint: nil,
                 rowSubtitle: String(localized: "Your prayers, reading, and badges")),
            Tile(door: .aboutYou, title: String(localized: "About You"), systemImage: "sparkles",
                 value: settings.userBackground?.title ?? String(localized: "Not set"),
                 tint: SettingsTint.islam, secondaryTint: SettingsTint.islamSecondary,
                 rowSubtitle: String(localized: "Start Here, welcome tutorial")),
        ]
        // iCloud Backup is Al-Islam's alone: a companion app shows the first two tiles.
        #if HAS_ICLOUD_BACKUP
        list.append(Tile(door: .cloudBackup, title: String(localized: "iCloud Backup"), systemImage: "icloud.fill",
                         value: cloud.isEnabled ? String(localized: "On") : String(localized: "Off"), tint: SettingsTint.hadith,
                         rowSubtitle: String(localized: "Profiles, restore, what's included, backup file")))
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
                // cards of three different heights read as a layout bug. The grid mode's row: at the
                // accessibility sizes the three stack, where three across cut "Your Progr...".
                SettingsGridTileRow {
                    ForEach(tiles, id: \.door.id) { tile in
                        profileTile(tile)
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    /// The Settings grid's own tile (`SettingsGridTile`), in list mode too: these three are tiles in
    /// both modes. Until 2026-10-26 they were a third drawing of the tile with their own type sizes;
    /// the hub's prominent form is theirs now, with a second caption line because the value is an
    /// answer the reader gave ("Just getting started"), unreadable shrunk to one.
    private func profileTile(_ tile: Tile) -> some View {
        SettingsGridTile(title: tile.title, systemImage: tile.systemImage, caption: tile.value,
                         tint: tile.tint, secondaryTint: tile.secondaryTint,
                         prominent: true, captionLines: 2) {
            open(tile.door)
        }
    }
}
#endif

// MARK: - Simple Mode

/// Simple Mode's one switch, directly under the Settings root's hub. The per-screen Advanced switches
/// trim the SETTINGS screens; this trims the app's own chrome (Abu, 2026-10-07: "just make the app
/// look less overwhelming and have a toggle to show more complicated stuff").
///
/// One switch, app-wide, where Advanced is one per screen: Advanced answers "show me the rest of
/// THIS screen", which is a question about the screen in front of you. Simple Mode answers "I find
/// the app busy", which is not: hunting a dozen switches to settle it would be the clutter it is
/// meant to remove.
///
/// On the root the section ends with the What Moves Where row, the door to the Simple Mode page that
/// lists every trim and where it went (Docs/Product/Simple Mode v2 Design.md, section 4.4). The page
/// opens with this same section, without the row.
struct SimpleModeSection: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// The What Moves Where row under the switch: on the Settings root, off on the page it opens.
    var showsCatalogRow = true

    /// The iPad/Mac split root's own copy of the row, a selection that fills the detail column as the
    /// hub's rows do (`SettingsView.splitResourceLink`). Nil on the iPhone's list and grid roots, where
    /// the row pushes the page.
    var splitCatalogRow: AnyView? = nil

    /// The row's title and symbol (the design's section 7), shared with the split root's copy.
    static let catalogRowTitle = String(localized: "What Moves Where")
    static let catalogRowImage = "list.bullet.rectangle"

    var body: some View {
        Section(header: SectionIconHeader(String(localized: "SIMPLE MODE"), icon: "rectangle.compress.vertical")) {
            SettingsToggle(String(localized: "Simple Mode"), caption: caption, isOn: $systemSettings.simpleMode)

            // Its own row, one link per row: inside the switch's row, a tap anywhere there would push.
            if showsCatalogRow {
                if let splitCatalogRow {
                    splitCatalogRow
                } else {
                    NavigationLink(destination: LazyDestination { SimpleModeSettingsView() }) {
                        SettingsRowLabel(title: Self.catalogRowTitle, systemImage: Self.catalogRowImage)
                    }
                    .tint(settings.accentColor.color)
                }
            }
        }
    }

    /// Says what moves and, either way, that nothing stops working: the one worry a switch that
    /// hides parts of the app has to answer before it is turned on. Short since the catalog page
    /// exists: the row under it names every trim, so the caption no longer lists examples.
    private var caption: String {
        if settings.simpleMode {
            // The page itself has no row under the switch, so its caption points at the list below.
            if !showsCatalogRow {
                return String(localized: "Each tab keeps to its essentials. Nothing is turned off; the list below says where everything went.")
            }
            return String(localized: "Each tab keeps to its essentials. Nothing is turned off; What Moves Where says where everything went.")
        }
        return String(localized: "Keeps each tab to its essentials: shortcuts move into the ⋯ menu at the top or into Settings, and the extras step aside. Nothing is turned off.")
    }
}

/// The Simple Mode page: the switch, then the live catalog of what Simple hides and where each thing
/// went, one section per surface in the catalog's order (`SimpleTrim.grouped`, so a new trim lists
/// itself here), then the two rules the catalog cannot show. The root's What Moves Where row, the
/// search entry, the tip and the Islam tab's "Too Much on Screen?" door land here. The same in both
/// modes: it is how someone in Full decides, and how someone in Simple finds a thing again.
struct SimpleModeSettingsView: View {
    var body: some View {
        List {
            Group {
                SimpleModeSection(showsCatalogRow: false)

                ForEach(SimpleTrim.grouped, id: \.surface) { group in
                    Section(header: SectionIconHeader(group.surface.title.uppercased(), icon: group.surface.systemImage)) {
                        ForEach(group.entries) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title.localizedDigits)
                                    .font(.subheadline)

                                Text(entry.door.text)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // Rules 9 and 4 of the design (what Simple does once, and what it never hides): no
                // trim row can carry either.
                Section {
                    Text("Turning Simple Mode on also turns off Show Advanced Settings on Prayer Calculation and Nagging Mode; each screen's ADVANCED switch brings its options back. Sheets, press-and-hold menus, search, play, the gear, the prayer bells and everything you made never change.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 2)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Simple Mode")
    }
}

// MARK: - Advanced Settings

/// The switch a simplified settings screen ends with. ONE PER SCREEN (Abu, 2026-09-22: "dont do one
/// general advanced settings there, do that for each one - if it needs advanced mode then show it
/// there"): the toggle writes `screen`'s own key, so turning the second half on under Nagging Mode
/// leaves Prayer Calculation simple. Off, a screen keeps to its essentials and this section names
/// what it is keeping out of sight (`hides`), so nobody wonders where an option went; the hidden
/// options keep the values they hold. Two screens carry one since 2026-10-25 (Abu: "get rid of it
/// all except for certain places"): Prayer Calculation and Nagging Mode, whose second halves are
/// long and niche; every other screen shows everything it has. Compiles for the watch too (its
/// Nagging Mode page uses it).
struct AdvancedSettingsSection: View {
    private let settings = Settings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Which screen's switch this is.
    let screen: Settings.AdvancedScreen

    /// What THIS screen shows only with the switch on, as a plain list ("the repeat interval, the
    /// last calls and a tone of their own").
    var hides: String? = nil

    /// False while this screen's advanced half would be empty ANYWAY, whatever the switch says
    /// (Abu, 2026-09-22: "only show advanced setting if it applies"). Nagging Mode gates its whole
    /// advanced half on the mode being on, and there a switch promising hidden options that do not
    /// exist is worse than no switch at all.
    ///
    /// The stored value is untouched when the section is away: flipping the gate back on brings the
    /// switch back exactly as it was left.
    var applies: Bool = true

    var body: some View {
        if applies { section }
    }

    private var section: some View {
        // A plain header, like every other section of a pushed settings page: the icon headers
        // belong to the tab roots (Abu, 2026-10-25: "mad consistency between settings").
        Section(header: Text("ADVANCED")) {
            SettingsToggle(String(localized: "Show Advanced Settings"), caption: caption, isOn: settings.advancedBinding(screen))
        }
    }

    private var caption: String {
        // One line where there were three (Abu, 2026-10-19): both screens ended in the same paragraph.
        if settings.advanced(screen) {
            return String(localized: "Everything this screen has is shown. Off keeps it to the essentials; what is set here still applies.")
        }
        let hidden = hides.map { String(localized: "Also here, with this on: \($0).") } ?? String(localized: "Shows every option this screen has.")
        // Rule 9: Simple Mode folded this switch off when it was turned on, so the caption adds one
        // sentence saying so, after the list of what the switch keeps out of sight (design 6.6).
        if settings.simpleModeFoldsAdvanced {
            return String(localized: "\(hidden) Simple Mode turned this off; turn it on to see every option here.")
        }
        return hidden
    }
}

/// Turns Advanced Settings on when a search result or a tip opens a control its screen would
/// otherwise hide. The row said "Advanced" before it was tapped, so the switch flipping is the
/// expected outcome, not a surprise; the screen's own ADVANCED section is there to turn it back off.
///
/// Every screen's switch, not one: a search entry records only THAT the control is advanced, never
/// which of the two screens owns it, and landing on a screen still hiding the very thing that was
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
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    var width: CGFloat?

    var body: some View {
        HStack {
            if let width = width {
                Text("Version:")
                    .frame(width: width)
            } else {
                Text("Version")
            }

            Text((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0").localizedDigits)
                .foregroundColor(settings.accentColor.color)
                .padding(.leading, -4)
        }
        .foregroundColor(.primary)
    }
}

#Preview("Settings") {
    AlIslamPreviewContainer(embedInNavigation: false) {
        SettingsView()
    }
}

#if DEBUG
/// THE regression preview for 2026-10-07: Settings with recitation live. The floating search bar and
/// the Now Playing player are both bottom safe-area insets, and insets stack OUTWARD - whichever is
/// applied first sits nearest the content. Settings used to add its search bar before
/// `applyConditionalListStyle` (which installs the player), so the player rendered UNDERNEATH the
/// search bar instead of above it.
///
/// What correct looks like here: search bar on the bottom, player directly above it, list content
/// above that. If they ever swap, the modifier order in `settingsListChrome` has been changed back.
///
/// The surah and reciter are real (`QuranData.shared`), so the card shows the shipped Arabic name and
/// a title of realistic length rather than a short placeholder that would never reveal a clipping bug.
#if HAS_QURAN
#Preview("Settings - player sits ABOVE the search bar") {
    let surah = AlIslamPreviewData.quranData.quran.first(where: { $0.id == 55 })
        ?? AlIslamPreviewData.surah
    QuranPlayer.shared.nowPlaying.previewSeed { snapshot in
        snapshot.isPlaying = true
        snapshot.isPaused = false
        snapshot.currentSurahNumber = surah.id
        snapshot.currentAyahNumber = 13
        snapshot.isPlayingSurah = true
        snapshot.nowPlayingTitle = "\(surah.nameTransliteration) \(surah.id):13"
        snapshot.nowPlayingReciter = "Mishary Rashid Alafasy"
    }
    PlaybackVisibility.shared.update(showsBar: true)
    return AlIslamPreviewContainer(embedInNavigation: false) {
        SettingsView()
    }
}

/// The same screen with the player EXPANDED. The big card is roughly double the height, so this is
/// where the two insets would overlap first if the order regressed: the list's bottom content must
/// still clear both, and the search bar must stay fully tappable.
#Preview("Settings - expanded player + search bar") {
    let surah = AlIslamPreviewData.quranData.quran.first(where: { $0.id == 2 })
        ?? AlIslamPreviewData.surah
    AlIslamPreviewData.seedPersisted("nowPlayingExpanded", true)
    QuranPlayer.shared.nowPlaying.previewSeed { snapshot in
        snapshot.isPlaying = true
        snapshot.currentSurahNumber = surah.id
        snapshot.currentAyahNumber = 255
        snapshot.isPlayingSurah = true
        snapshot.nowPlayingTitle = "\(surah.nameTransliteration) \(surah.id):255"
        snapshot.nowPlayingReciter = "Mishary Rashid Alafasy"
    }
    PlaybackVisibility.shared.update(showsBar: true)
    return AlIslamPreviewContainer(embedInNavigation: false) {
        SettingsView()
    }
}
#endif
#endif
