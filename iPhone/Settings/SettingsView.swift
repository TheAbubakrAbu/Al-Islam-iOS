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

    var id: String { path + title }

    enum Destination {
        case notifications
        case notificationReminders
        case prayerSettings
        case travelingMode
        case prayerCalculation
        case skyColors
        case quranSettings
        case reciters
        case hadithSettings
        case appearance
        case credits

        /// The chip icon a search result renders with - derived here so entries never repeat it.
        var icon: String {
            switch self {
            case .notifications: return "bell.badge.fill"
            case .notificationReminders: return "bell.and.waves.left.and.right.fill"
            case .prayerSettings: return "safari.fill"
            case .travelingMode: return "airplane"
            case .prayerCalculation: return "globe.europe.africa.fill"
            case .skyColors: return "sunset.fill"
            case .quranSettings: return "character.book.closed.ar"
            case .reciters: return "headphones"
            case .hadithSettings: return "text.book.closed.fill"
            case .appearance: return "paintpalette.fill"
            case .credits: return "scroll.fill"
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
        let texts = Self.settingsSearchIndex.map { "\($0.title) \($0.path) \($0.keywords)" }
        let keys = Self.settingsSearchIndex.map(\.id)
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
                let byID = Dictionary(uniqueKeysWithValues: Self.settingsSearchIndex.map { ($0.id, $0) })
                settingsAIHits = results.compactMap { result -> SettingsSearchEntry? in
                    if let keys, keys.indices.contains(result.index) { return byID[keys[result.index]] }
                    guard Self.settingsSearchIndex.indices.contains(result.index) else { return nil }
                    return Self.settingsSearchIndex[result.index]
                }
            }
        }
    }
    #endif
    /// Apple Music-style: true while scrolling down, minimizing the floating search bar.
    @State private var barsCollapsed = false

    /// The destination shown when nothing is explicitly selected (single source of truth).
    private static let defaultDestination: SettingsDestination = .quranSettings

    private enum SettingsDestination: Hashable {
        case notification
        case prayerSettings
        case quranSettings
        case hadithSettings
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
    }

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
                .padding([.horizontal, .top], -8)
                .minimizedBarStyle(barsCollapsed)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
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

    private static let settingsSearchIndex: [SettingsSearchEntry] =
        SettingsSearchEntry.notificationEntries
        + SettingsSearchEntry.adhanEntries
        + SettingsSearchEntry.prayerCalculationEntries
        + SettingsSearchEntry.quranEntries
        + SettingsSearchEntry.hadithEntries
        + SettingsSearchEntry.appearanceEntries
        + [
            // About (owned by this file's credits link).
            .init(title: "Credits & Contact", path: "Credits", keywords: "about version website email review", destination: .credits)
        ]

    @ViewBuilder
    private func searchDestinationView(_ destination: SettingsSearchEntry.Destination) -> some View {
        switch destination {
        case .notifications: NotificationView()
        case .notificationReminders: MoreNotificationView()
        case .prayerSettings: SettingsAdhanView(showNotifications: false)
        case .travelingMode: SettingsAdhanView(showNotifications: false, openTravelingMode: true)
        case .prayerCalculation: PrayerCalculationListView()
        case .skyColors: SkyColorsView()
        case .quranSettings: SettingsQuranView()
        case .reciters: ReciterListView()
        case .hadithSettings: SettingsHadithView(presentedAsSheet: false)
        case .appearance: AppearanceSettingsScreen()
        case .credits: CreditsView()
        }
    }

    /// Ranked keyword results: every query term must match somewhere (title, path, or keywords,
    /// diacritic-insensitive), and results order by WHERE they matched - title prefix first, then
    /// title, then path, then keywords-only - so "not" puts Notifications above rows that merely
    /// mention it. Ties keep the index's hand-authored order.
    private var settingsSearchResults: [SettingsSearchEntry] {
        let query = settingsSearchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        guard !query.isEmpty else { return [] }
        let terms = query.split(separator: " ").map(String.init)

        func fold(_ text: String) -> String {
            text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        }

        let scored: [(entry: SettingsSearchEntry, score: Int, order: Int)] = Self.settingsSearchIndex.enumerated().compactMap { order, entry in
            let title = fold(entry.title)
            let path = fold(entry.path)
            let keywords = fold(entry.keywords)
            var score = 0
            for term in terms {
                if title.hasPrefix(term) { score += 40 }
                else if title.split(separator: " ").contains(where: { $0.hasPrefix(Substring(term)) }) { score += 24 }
                else if title.contains(term) { score += 16 }
                else if path.contains(term) { score += 8 }
                else if keywords.contains(term) { score += 4 }
                else { return nil }   // every term must land somewhere
            }
            return (entry, score, order)
        }
        return scored
            .sorted { ($0.score, -$0.order) > ($1.score, -$1.order) }
            .map(\.entry)
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
        NavigationLink(destination: LazyDestination { searchDestinationView(entry.destination) }) {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: entry.destination.icon)

                VStack(alignment: .leading, spacing: 2) {
                    HighlightedSnippet(
                        source: entry.title,
                        term: settingsSearchText,
                        font: .subheadline,
                        accent: settings.accentColor.color,
                        fg: .primary
                    )

                    // The breadcrumb, in the system's "›" grammar rather than the index's "→".
                    Text("Settings › \(entry.path.replacingOccurrences(of: " → ", with: " › "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .padding(.vertical, 2)
        }
    }


    #endif

    private func resourceLink<Destination: View>(
        title: String,
        systemImage: String,
        subtitle: String? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        // LazyDestination, same as IslamView: building the destination eagerly meant every body pass of this
        // tab constructed the full Adhan/Quran/Notification settings trees - on the watch, where TabView
        // re-evaluates neighbouring tabs on every swipe, that WAS the tab-switch lag into Settings.
        NavigationLink(destination: LazyDestination(build: destination)) {
            toolLabel(title, systemImage: systemImage, subtitle: subtitle)
        }
        .tint(settings.accentColor.color)
    }

    /// A settings row in the iOS Settings app's visual grammar, tinted the app's way: the icon on a
    /// small accent-gradient chip, an optional caption under the title. `chipTint` overrides the
    /// accent (the reset row goes red).
    private func toolLabel(_ title: String, systemImage: String, subtitle: String? = nil, chipTint: Color? = nil) -> some View {
        return HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage, tint: chipTint)

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
        value: SettingsDestination
    ) -> some View {
        // A Button (not `NavigationLink(value:)`) so a re-tap of the ALREADY-selected row still
        // responds - it pops that section back to its root via the refresh token. The `.tag` keeps
        // the sidebar highlight driven by `List(selection:)`, the Islam sidebar's exact pattern.
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                if selectedDestination == value {
                    settingsDetailRefreshToken &+= 1
                } else {
                    selectedDestination = value
                }
            }
        } label: {
            toolLabel(title, systemImage: systemImage, subtitle: subtitle)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .tag(value)
        .tint(settings.accentColor.color)
    }

    /// The four settings destinations as ONE card - the old one-row-per-section layout spent most
    /// of the screen on headers. Notifications shown on watchOS too (it supports local notifications).
    @ViewBuilder
    private var settingsHubSection: some View {
        Section(header: Text("SETTINGS")) {
            resourceLink(title: "Notifications", systemImage: "bell.badge.fill",
                         subtitle: "Prayer alerts, adhan sounds, reminders") {
                NotificationView()
            }
            resourceLink(title: "Prayer Settings", systemImage: "safari.fill",
                         subtitle: "Calculation, offsets, traveling mode") {
                SettingsAdhanView(showNotifications: false)
            }
            resourceLink(title: "Quran Settings", systemImage: "character.book.closed.ar",
                         subtitle: "Fonts, translations, tajweed, reciters") {
                SettingsQuranView()
            }
            #if os(iOS)
            resourceLink(title: "Hadith Settings", systemImage: "text.book.closed.fill",
                         subtitle: "Arabic and English text, Hadith of the Day") {
                SettingsHadithView(presentedAsSheet: false)
            }
            #endif
        }
    }

    @available(iOS 16.0, *)
    @ViewBuilder
    private var settingsHubSectionSplit: some View {
        Section(header: Text("SETTINGS")) {
            splitResourceLink(title: "Notifications", systemImage: "bell.badge.fill",
                              subtitle: "Prayer alerts, adhan sounds, reminders", value: .notification)
            splitResourceLink(title: "Prayer Settings", systemImage: "safari.fill",
                              subtitle: "Calculation, offsets, traveling mode", value: .prayerSettings)
            splitResourceLink(title: "Quran Settings", systemImage: "character.book.closed.ar",
                              subtitle: "Fonts, translations, tajweed, reciters", value: .quranSettings)
            splitResourceLink(title: "Hadith Settings", systemImage: "text.book.closed.fill",
                              subtitle: "Arabic and English text, Hadith of the Day", value: .hadithSettings)
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
                Text("Reset restores every setting (appearance, prayer, and Quran options) to its default and keeps your bookmarks, favorites, khatm progress, and saved location.\n\nErase removes those too.")
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
                Text("This deletes your bookmarks, favorite surahs, letters and names, khatm progress, reading and listening positions, search history, and saved locations, leaving the app exactly as it was on a fresh install. This cannot be undone.")
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
            leaveReviewButton
            openAppSettingsButton
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
            toolLabel("View Credits", systemImage: "scroll.fill")
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
            toolLabel("Open App Settings", systemImage: "gearshape.fill")
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
        List {
            Section {
                SettingsAppearanceView()
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Appearance")
    }
}

extension SettingsSearchEntry {
    static let appearanceEntries: [SettingsSearchEntry] = [
        .init(title: "Accent Color", path: "Appearance", keywords: "green color swatch tint custom hex theme", destination: .appearance),
        .init(title: "App Theme (Light / Dark / Sepia / Gray)", path: "Appearance", keywords: "dark mode light mode night reading sepia gray paper background", destination: .appearance),
        .init(title: "Custom Background Color", path: "Appearance", keywords: "custom color background hex picker theme", destination: .appearance),
        .init(title: "Top Accent Glow", path: "Appearance", keywords: "glow wash gradient accent top background flat hide al islam green yellow brand", destination: .appearance),
        .init(title: "Default List View", path: "Appearance", keywords: "list style plain grouped inset layout", destination: .appearance),
        .init(title: "Haptic Feedback", path: "Appearance", keywords: "vibration taptic buzz feedback toggle", destination: .appearance),
    ]
}
#endif

struct SettingsAppearanceView: View {
    @ObservedObject var settings = Settings.shared

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

    var body: some View {
        #if os(iOS)
        VStack(alignment: .leading) {
            Picker("Color Theme", selection: $settings.colorSchemeString.animation(.easeInOut)) {
                Text("System").tag("system")
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
                .padding(.vertical, 2)
        }

        VStack(alignment: .leading) {
            HStack(spacing: 12) {
                ColorPicker("", selection: customBackgroundColorBinding, supportsOpacity: false)
                    .labelsHidden()

                Text("Custom Background")
                    .font(.subheadline)

                Spacer()

                Toggle("", isOn: customBackgroundEnabledBinding.animation(.easeInOut))
                    .labelsHidden()
                    .tint(Color(hex: settings.customBackgroundColorHex) ?? .gray)
            }
            // (Haptic on theme change is already handled by the Color Theme picker's onChange above.)

            Text("Pick any background color for the whole app. Light or dark text is chosen automatically so it stays readable.")
                .font(.caption)
                .foregroundColor(.secondary)
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
            // One line: color well, label, then a toggle tinted with the custom color itself (not the accent).
            HStack(spacing: 12) {
                ColorPicker("", selection: customAccentColorBinding, supportsOpacity: false)
                    .labelsHidden()

                Text("Custom Color")
                    .font(.subheadline)

                Spacer()

                Toggle("", isOn: customColorEnabledBinding.animation(.easeInOut))
                    .labelsHidden()
                    .tint(Color(hex: settings.customAccentColorHex) ?? .green)
            }
            .padding(.horizontal, 24)
            .onChange(of: settings.accentColor) { _ in settings.hapticFeedback() }

            #endif

            #if os(iOS)
            Text("Anas ibn Malik (may Allah be pleased with him) said, “The most beloved of colors to the Messenger of Allah (peace be upon him) was green.”")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
                .padding(.top, 10)
            #endif
        }

        #if os(iOS)
        VStack(alignment: .leading) {
            Toggle("Top Accent Glow", isOn: $settings.showAccentGlow.animation(.easeInOut))
                .font(.subheadline)
                .onChange(of: settings.showAccentGlow) { _ in settings.hapticFeedback() }

            Text("A soft wash of your accent color at the top of each screen. Turn it off for a flat background.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)

            if settings.showAccentGlow {
                Toggle("Al-Islam Glow", isOn: $settings.alIslamGlow.animation(.easeInOut))
                    .font(.subheadline)
                    .padding(.top, 6)
                    .onChange(of: settings.alIslamGlow) { _ in settings.hapticFeedback() }

                Text("Color the glow with Al-Islam's yellow and green - yellow from the left, green from the right - instead of your accent color.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
        }

        VStack(alignment: .leading) {
            Toggle("Default List View", isOn: $settings.defaultView.animation(.easeInOut))
                .font(.subheadline)
                .onChange(of: settings.defaultView) { _ in settings.hapticFeedback() }

            Text("The default list view is the standard interface found in many of Apple's first party apps, including Notes.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
        #endif

        VStack(alignment: .leading) {
            Toggle("Haptic Feedback", isOn: $settings.hapticOn.animation(.easeInOut))
                .font(.subheadline)
                .onChange(of: settings.hapticOn) { _ in settings.hapticFeedback() }
        }
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
