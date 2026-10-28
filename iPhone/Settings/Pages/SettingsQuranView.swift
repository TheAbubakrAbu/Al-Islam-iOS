import SwiftUI
import UIKit

struct SettingsQuranView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    @State private var confirmHideQiraahDetails = false
    /// Gates turning ON beta qiraat behind the warning dialog (see `betaQiraatGroup`).
    @State private var confirmEnableBetaQiraat = false
    private let presentedAsSheet: Bool
    /// A sub-screen to push a beat after the root mounts: what a settings search result lands on
    /// (`SettingsDeepLink`).
    private let requestedPage: SettingsQuranPage?
    @State private var openRequestedPage = false
    @State private var deepLinkFired = false
    /// One sub-screen shown ON ITS OWN, as the root of its stack: a Need a Hand? door's sheet
    /// (HelpDoors.swift), which should open on the page the question is about rather than flash this
    /// root and push the page a beat later.
    private let standalonePage: SettingsQuranPage?

    init(presentedAsSheet: Bool = false, openPage: SettingsQuranPage? = nil, standalonePage: SettingsQuranPage? = nil) {
        self.presentedAsSheet = presentedAsSheet
        self.requestedPage = openPage
        self.standalonePage = standalonePage
    }

    private var includeEnglish: Binding<Bool> {
        Binding(
            get: {
                settings.isHafsDisplay && (settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa)
            },
            set: { newValue in
                // If not on Hafs, English settings don't apply (toggle is disabled in UI).
                guard settings.isHafsDisplay else { return }
                if newValue {
                    // Ensure at least one English option is enabled so this toggle can stay on.
                    if !(settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa) {
                        settings.showEnglishSaheeh = true
                    }
                } else {
                    settings.showTransliteration = false
                    settings.showEnglishSaheeh = false
                    settings.showEnglishMustafa = false
                }
            }
        )
    }

    private var pageJuzDividers: Binding<Bool> {
        Binding(
            get: { settings.showPageJuzDividers },
            set: { settings.showPageJuzDividers = $0 }
        )
    }

    
    #if DEBUG && os(iOS)
    /// Headless visual verification (no tap access on the dev machine): `-launchQuranSettingsArabic`
    /// lands directly on the Arabic Text subpage, the Hadith tab's `-launchHadithSettingsReading`
    /// pattern. DEBUG builds only.
    @State private var autoOpenArabicText =
        ProcessInfo.processInfo.arguments.contains("-launchQuranSettingsArabic")
    /// `-launchQuranSettingsEnglish` lands on the English Text subpage. DEBUG builds only.
    @State private var autoOpenEnglishText =
        ProcessInfo.processInfo.arguments.contains("-launchQuranSettingsEnglish")
    /// `-launchQuranSettingsReciters` lands on the reciter list, for verifying the legend dots and
    /// a partial reciter's coverage. DEBUG builds only.
    @State private var autoOpenReciters =
        ProcessInfo.processInfo.arguments.contains("-launchQuranSettingsReciters")
    /// `-launchQuranSettingsSunnah` lands on the Sunnah Reminders screen. DEBUG builds only.
    @State private var autoOpenSunnah =
        ProcessInfo.processInfo.arguments.contains("-launchQuranSettingsSunnah")
    /// `-launchQuranSettingsThemes` lands on the Highlight Themes screen. DEBUG builds only.
    @State private var autoOpenThemes =
        ProcessInfo.processInfo.arguments.contains("-launchQuranSettingsThemes")
    #endif
    #if os(iOS)
    @ObservedObject private var themeHighlights = ThemeHighlights.shared
    #endif

    var body: some View {
        #if os(iOS)
        if let standalonePage {
            quranPageDestination(standalonePage)
        } else {
            rootBody
        }
        #else
        rootBody
        #endif
    }

    private var rootBody: some View {
        rootList
        #if DEBUG && os(iOS)
        // On the List, not a row (a lazy row's destination never fires, see `PushDestination`). The
        // readers' sheets host this page in `SettingsSheetStack`, a `NavigationStack`, so these push
        // there as in the Settings tab.
        .debugPushDestination(isPresented: $autoOpenArabicText) { arabicTextDestination }
        .debugPushDestination(isPresented: $autoOpenEnglishText) { englishTextDestination }
        .debugPushDestination(isPresented: $autoOpenReciters) { ReciterListView().environmentObject(settings) }
        .debugPushDestination(isPresented: $autoOpenSunnah) { SunnahRemindersView() }
        .debugPushDestination(isPresented: $autoOpenThemes) { ThemeHighlightsView() }
        #endif
        #if os(iOS)
        .modifier(SettingsDeepLink(isPresented: $openRequestedPage, active: requestedPage != nil) {
            if let page = requestedPage { quranPageDestination(page) }
        })
        .onAppear {
            guard !deepLinkFired, requestedPage != nil else { return }
            deepLinkFired = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { openRequestedPage = true }
        }
        #endif
        .navigationTitle("Al-Quran Settings")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if presentedAsSheet {
                    Button {
                        settings.hapticFeedback()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)
                }
            }
        }
        #endif
    }

    #if os(iOS)
    /// The same list-vs-pages choice the Quran tab's toolbar book button makes, surfaced here so it can be
    /// found without knowing that button exists. No confirmation dialog on this one: the toolbar asks first
    /// because it's one tap away from a whole-screen change you might not have meant, whereas coming to
    /// Settings and moving a segmented control IS the deliberate act the dialog was guarding.
    private var readingModeSection: some View {
        Section(header: Text("LAYOUT"), footer: Text("List shows a surah as a scrolling list of ayahs. Pages shows it as a mushaf, one page at a time.")) {
            Picker("Reading View", selection: $quranDisplay.quranPageMode) {
                Text("List").tag(false)
                Text("Pages").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: settings.quranPageMode) { _ in settings.hapticFeedback() }
        }
    }
    #endif

    /// The root's sections, on the page-search scaffold (iOS) or a plain list (the watch).
    @ViewBuilder
    private var rootList: some View {
        #if os(iOS)
        SettingsScopedSearch(scope: .quran, resolve: resolveSearchDestination) { rootSections }
        #else
        List {
            Group { rootSections }
                .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        #endif
    }

    /// Two cards (2026-09-16): how the Quran reads and sounds, then the extras; each row with its
    /// caption, so the screen is a table of contents rather than a column of bare names. Sunnah
    /// Reminders sit ABOVE Favorites and Bookmarks (Abu, 2026-09-12).
    @ViewBuilder
    private var rootSections: some View {
        Section(header: Text("READING")) {
            quranPageLink(.recitation) { recitationDestination }
            quranPageLink(.readingView) { readingViewsDestination }
            quranPageLink(.arabicText) { arabicTextDestination }
            quranPageLink(.englishText) { englishTextDestination }
            #if os(iOS)
            quranPageLink(.testMode) { QuranTestModeSettingsView() }
            #endif
        }

        #if os(iOS)
        Section(header: Text("MORE")) {
            // Highlight Themes: the colour-coded passages, the legend, and the lit themes (ported from
            // Tilawa). While anything is lit the caption says what, so "why is my page tinted" has an
            // answer here (a trailing value truncated beside the caption).
            quranPageLink(.highlightThemes,
                          caption: themeHighlights.isEmpty ? nil : themeHighlights.summary) { ThemeHighlightsView() }
            quranPageLink(.sunnahReminders) { SunnahRemindersView() }
            quranPageLink(.favorites) { favoritesAndBookmarksDestination }
        }

        readingModeSection

        // Last on the page (Abu, 2026-10-10): a page opens on its own settings, and the tips and the
        // Need a Hand? switch wait at the foot.
        // They led every page from 2026-09-20 until then, which put the first real setting most of a
        // screen down.
        TipsSection(area: .quran, resolve: resolveSearchDestination)
        // The Quran tab's Need a Hand? questions, named here with their switch (HelpDoors.swift).
        HelpDoorsSettingsSection(area: .quran)
        #endif
    }

    private func quranPageLink<Destination: View>(
        _ page: SettingsQuranPage,
        caption: String? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: LazyDestination(build: destination)) {
            SettingsRowLabel(title: page.title, systemImage: page.systemImage, subtitle: caption ?? page.caption,
                             tint: SettingsTint.quran)
        }
        .tint(settings.accentColor.color)
    }

    #if os(iOS)
    /// The sub-screen behind each root row, for the deep links and the page search.
    @ViewBuilder
    private func quranPageDestination(_ page: SettingsQuranPage) -> some View {
        switch page {
        case .recitation: recitationDestination
        case .readingView: readingViewsDestination
        case .arabicText: arabicTextDestination
        case .englishText: englishTextDestination
        case .testMode: QuranTestModeSettingsView()
        case .highlightThemes: ThemeHighlightsView()
        case .sunnahReminders: SunnahRemindersView()
        case .favorites: favoritesAndBookmarksDestination
        }
    }

    /// The page search's results land on THIS page's sub-screens; the app-wide mapping would push a
    /// second Quran Settings root first.
    private func resolveSearchDestination(_ destination: SettingsSearchEntry.Destination) -> AnyView? {
        switch destination {
        case .quranPage(let page): return AnyView(quranPageDestination(page))
        case .reciters: return AnyView(ReciterListView().environmentObject(settings))
        default: return nil
        }
    }

    /// Bulk-management screens for the user's saved items: the four editors live behind one row
    /// rather than taking four rows of the root list.
    private var favoritesAndBookmarksDestination: some View {
        quranSettingsSubList(title: String(localized: "Favorites and Bookmarks")) {
            Section {
                favoritesLink(title: String(localized: "Edit Favorite Surahs"), systemImage: "star.fill", type: .surah)
                favoritesLink(title: String(localized: "Edit Bookmarked Ayahs"), systemImage: "bookmark.fill", type: .ayah)
                favoritesLink(title: String(localized: "Edit Favorite Letters"), systemImage: "character", type: .letter)
                favoritesLink(title: String(localized: "Edit Khatm Progress"), systemImage: "checkmark.circle.fill", type: .khatm)
            } header: {
                Text("SAVED ITEMS")
            } footer: {
                Text("These are kept when you reset your settings, unless you choose to erase everything.")
            }
        }
    }

    private func favoritesLink(title: String, systemImage: String, type: FavoriteType) -> some View {
        NavigationLink {
            LazyDestination {
                FavoritesView(type: type)
                    .environmentObject(quranData)
                    .environmentObject(settings)
                    .accentColor(settings.accentColor.color)
            }
        } label: {
            SettingsRowLabel(title: title, systemImage: systemImage, tint: SettingsTint.quran)
        }
        .tint(settings.accentColor.color)
    }
    #endif

    /// Shared scaffold for each Quran settings sub-screen: themed list + standard style + title.
    @ViewBuilder
    private func quranSettingsSubList<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        List {
            Group {
                content()
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(title)
    }

    private var recitationDestination: some View {
        quranSettingsSubList(title: String(localized: "Recitation")) {
            recitationSection
        }
    }

    /// The merged Quran Tab + Surah Reading screen: both keep their own sections, one push.
    private var readingViewsDestination: some View {
        quranSettingsSubList(title: String(localized: "Reading View")) {
            #if os(iOS)
            quranTabViewSection
            #endif
            surahReadingSections
        }
    }

    private var englishTextDestination: some View {
        quranSettingsSubList(title: String(localized: "English Text")) {
            englishTextSections
        }
    }

    // Arabic Text keeps Qiraah nested inside it (and owns the qiraah-reset confirmation dialog).
    private var arabicTextDestination: some View {
        List {
            Group {
                arabicTextSections
                // Qiraah/Riwayah details + comparison mode affect on-screen Arabic and ayah playback the
                // watch doesn't offer; hide them on watchOS.
                #if os(iOS)
                qiraahSection
                #endif
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Arabic Text")
        .confirmationDialog("Convert Qiraah to Hafs an Asim?", isPresented: $confirmHideQiraahDetails, titleVisibility: .visible) {
            Button("Yes") {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.displayQiraah = Settings.Riwayah.hafsTag
                    settings.showQiraahDetails = false
                }
            }

            Button("No") {
                settings.hapticFeedback()
                settings.showQiraahDetails = true
            }
        } message: {
            Text("Are you sure? This will convert the qiraah back to Hafs an Asim.")
        }
    }

    private var recitationSection: some View {
        Section {
            reciterSelection
            recitationEndingPicker
        } header: {
            Text("RECITATION")
        } footer: {
            recitationCaption
        }
    }

    /// The door to the reciters, in the row grammar every settings link uses: the chosen reciter is
    /// the row's caption, where the Nagging Mode and Highlight Themes rows put their state.
    private var reciterSelection: some View {
        NavigationLink(destination: LazyDestination { ReciterListView().environmentObject(settings) }) {
            SettingsRowLabel(title: String(localized: "Choose Reciter"), systemImage: "headphones",
                             subtitle: settings.resolvedSelectedReciterIgnoringRandom()?.displayNameWithEnglishQiraah ?? settings.reciter,
                             tint: SettingsTint.quran)
        }
        .tint(settings.accentColor.color)
    }

    private var recitationEndingPicker: some View {
        Picker("After Surah Recitation Ends", selection: $quranDisplay.reciteType) {
            Section {
                Text("Go to Next").tag("Continue to Next")
                Text("Go to Previous").tag("Continue to Previous")
                Text("End Recitation").tag("End Recitation")
            } header: {
                Text("Recitation End")
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: settings.reciteType) { _ in settings.hapticFeedback() }
    }

    /// The section's footer (the watch has no downloads to explain).
    @ViewBuilder
    private var recitationCaption: some View {
        #if os(iOS)
        Text("The Quran recitations are streamed online by default. You can open Choose Reciter to download full surahs per reciter for offline playback and reduced data use.")
        #endif
    }

    // Options that affect the main Quran tab / surah list screen.
    private var quranTabViewSection: some View {
        Section(header: Text("QURAN TAB")) {
            // NOT behind Advanced (Abu, 2026-10-05: "show full surah details should not be in
            // advanced settings"): it changes what every row of the main surah list shows, which is
            // the first screen of the tab, so it belongs with the ordinary options.
            SettingsToggle(String(localized: "Show Full Surah Details"), caption: String(localized: "Adds extra details (revelation type, ayah count, page count, and more) beneath each surah in the main Quran list, the screen where all the surahs are shown."), isOn: $quranDisplay.showFullSurahRow)

            dailyCardsGroup
        }
    }

    // Options that affect the in-surah reading screen. The ayah actions sheet's switches are a
    // section of their own (Abu, 2026-10-25: a long section splits; it was five rows with captions).
    @ViewBuilder
    private var surahReadingSections: some View {
        Section(header: Text("READING")) {
            highlightAllahGroup
            pageAndJuzDividersGroup
        }

        Section(header: Text("AYAH ACTIONS")) {
            keepAyahSheetOpenGroup
        }
    }

    /// The ayah actions sheet's three switches. Keep Sheet Open: whether a sheet opened FROM it stacks
    /// on top of it or replaces it. The other two are also in the sheet itself (Abu, 2026-10-25): whether
    /// playing from it closes it, and whether the screen stays awake while it is up.
    @ViewBuilder
    private var keepAyahSheetOpenGroup: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsToggle(String(localized: "Keep Sheet Open"), caption: String(localized: "Opening Tafsir or another action from an ayah keeps its actions underneath; closing the new sheet returns to them. Off, the actions close as the new sheet opens."), isOn: $quranDisplay.keepAyahSheetOpen)

            #if os(iOS)
            SettingsToggle(String(localized: "Keep Sheet Open While Playing"), caption: String(localized: "Play This Ayah and Repeat Ayah in an ayah's actions leave the sheet up so you can keep reading. Play From Ayah and Play Custom Range still close it."), isOn: $quranDisplay.keepAyahSheetOpenOnPlay)

            SettingsToggle(String(localized: "Keep Screen On"), caption: String(localized: "The screen stays awake while an ayah's actions sheet is open. To keep it awake whenever a surah is open, use Keep Screen On in Appearance, Look and Feel."), isOn: $quranDisplay.ayahSheetKeepsScreenOn)
            #endif
        }
    }

    /// The daily cards. The three Show Last Listened / Last Read switches that followed them are gone
    /// (Abu, 2026-10-25: "get rid of all of those settings, too many things"): the cards are always on,
    /// and each card's own Remove clears it until the next listen or read.
    private var dailyCardsGroup: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsToggle(String(localized: "Show Ayah of the Day"), caption: String(localized: "Shows a different ayah each day at the top of the Quran tab."), isOn: $quranDisplay.showAyahOfTheDay)

            #if os(iOS)
            if WordOfDayStore.isBundled {
                SettingsToggle(String(localized: "Show Word of the Day"), caption: String(localized: "Shows a piece of Quranic vocabulary each day at the top of the Quran tab, with every ayah it appears in."), isOn: $quranDisplay.showWordOfTheDay)
            }

            // Fajr comes from the prayer calculation, which only an app with prayer times has.
            #if HAS_ADHAN
            SettingsToggle(String(localized: "Daily Cards Turn Over at Fajr"), caption: String(localized: "The daily cards change at Fajr from your prayer times instead of at midnight, so the night still belongs to the day before. Off, or without a location, midnight."), isOn: $systemSettings.dailyRolloverAtFajr)
                .onChange(of: settings.dailyRolloverAtFajr) { _ in settings.dailyRolloverSwitchChanged() }
            #endif
            #endif
        }
    }

    private var pageAndJuzDividersGroup: some View {
        SettingsToggle(String(localized: "Show Page and Juz Dividers"), caption: String(localized: "Shows a divider inside a surah wherever a new mushaf page or juz begins, plus a small floating label with the current page and juz while you read."), isOn: pageJuzDividers)
    }

    /// "Use Device Text Size" for the Arabic text only - pins the Arabic size to the device's Dynamic Type
    /// body size (+10, the reading-comfortable default). Split out from the English control so each script
    /// can follow the device size independently.
    private var useSystemArabicFontSize: Binding<Bool> {
        Binding(
            get: {
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                return settings.fontArabicSize == systemBodySize + 10
            },
            set: { newValue in
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                settings.fontArabicSize = newValue ? systemBodySize + 10 : systemBodySize + 11
            }
        )
    }

    /// "Use Device Text Size" for the English text only - pins the English size to the device's Dynamic
    /// Type body size.
    private var useSystemEnglishFontSize: Binding<Bool> {
        Binding(
            get: {
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                return settings.englishFontSize == systemBodySize
            },
            set: { newValue in
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                settings.englishFontSize = newValue ? systemBodySize : systemBodySize + 1
            }
        )
    }

    /// The page, one section per idea (Abu, 2026-10-25: "split up Arabic text into multiple
    /// sections"): it was ten rows under one header. The font, size and letter sections draw only
    /// while the Arabic is shown; hidden, they would be empty headers.
    @ViewBuilder
    private var arabicTextSections: some View {
        Section(header: Text("ARABIC TEXT")) {
            arabicVisibilityToggle
        }

        #if os(iOS)
        Section(header: Text("WORDS")) {
            tapWordGroup
            wordByWordGroup
        }
        #endif

        Section(header: Text("TAJWEED"), footer: tajweedFooter) {
            tajweedSettingsGroup
        }

        if settings.showArabicText {
            Section(header: Text("FONT"), footer: arabicFontFooter) {
                arabicFontPicker
                hijaziMarkStylePicker
                arabicScriptStylePicker
            }

            Section(header: Text("SIZE")) {
                arabicFontSizeControls
            }

            Section(header: Text("LETTERS AND MARKS")) {
                waslSignPicker
                beginnerModeGroup
                // Last on purpose (user rule): Hide Tashkeel is the page's most drastic, least
                // recommended option, so it sits at the bottom of the list rather than leading it.
                cleanArabicTextGroup
            }
        }
    }

    #if os(iOS)
    /// Whether the two word-level features can do anything here. Gated the same way tajweed colors
    /// are: the glosses are indexed against Hafs an Asim's wording, and beginner mode's
    /// letter-spacing breaks the word boundaries they are counted in - so the toggles go dead
    /// (rather than silently doing nothing) in those modes.
    private var wordFeaturesAvailable: Bool {
        settings.showArabicText && settings.isHafsDisplay
            && !settings.beginnerMode && WordByWordStore.isBundled
    }

    /// Tap a word to open its card. Its own row: it shares the gloss pack with the study layout
    /// below, but neither switch turns the other on, so nesting them in one block only suggested a
    /// dependency that is not there.
    private var tapWordGroup: some View {
        VStack(alignment: .leading) {
            let canRenderNow = wordFeaturesAvailable
            let binding = Binding<Bool>(
                get: { settings.wordByWordMeanings && canRenderNow },
                set: { settings.wordByWordMeanings = $0 }
            )

            SettingsToggle(String(localized: "Tap a Word for Its Meaning"),
                           caption: canRenderNow || !settings.showArabicText
                               ? String(localized: "Tap a word twice while reading to study it: its meaning and pronunciation, its grammar and root, and the ayah's themes. With tajweed colors on, the card explains each color too. Works offline.")
                               : String(localized: "Available in Hafs an Asim, with beginner mode off: the meanings are counted word by word against that text."),
                           isOn: binding)
                .disabled(!canRenderNow)
                .onChange(of: settings.wordByWordMeanings) { enabled in
                    // A megabyte of glosses has no business staying resident once the mode is off -
                    // unless the study layout below is still reading from it.
                    if !enabled && !settings.wordByWordInline { WordByWordStore.shared.unload() }
                    // Turning it on parses the pack off-main now, not in the first row's body.
                    if enabled { WordByWordStore.shared.prewarm() }
                }
        }
    }

    /// The study layout, and the two lines it can write under each word.
    private var wordByWordGroup: some View {
        VStack(alignment: .leading) {
            let canRenderNow = wordFeaturesAvailable
            let inlineBinding = Binding<Bool>(
                get: { settings.wordByWordInline && canRenderNow },
                set: { settings.wordByWordInline = $0 }
            )

            SettingsToggle(String(localized: "Word by Word"),
                           caption: canRenderNow || !settings.showArabicText
                               ? String(localized: "Lays the ayah out word by word, each word's meaning and pronunciation beneath it. List mode only: page mode keeps the mushaf layout.")
                               : String(localized: "Available in Hafs an Asim, with beginner mode off: the meanings are counted word by word against that text."),
                           isOn: inlineBinding)
                .disabled(!canRenderNow)
                .onChange(of: settings.wordByWordInline) { enabled in
                    if !enabled && !settings.wordByWordMeanings { WordByWordStore.shared.unload() }
                    if enabled { WordByWordStore.shared.prewarm() }
                }

            if settings.wordByWordInline && canRenderNow {
                wordByWordLineToggles
            }
        }
    }

    /// The two lines the study layout can write under each word. Each is disabled while it is the
    /// only one still on: a word-by-word layout with neither line is the ayah with gaps in it, so
    /// the switch that would empty it does not move.
    private var wordByWordLineToggles: some View {
        VStack(alignment: .leading, spacing: 4) {
            SettingsToggle(String(localized: "Translation"), caption: String(localized: "What each word means on its own, from the Quranic Arabic Corpus via Quran.com. Literal and in place, so it reads differently from the flowing translation of the whole ayah."), isOn: $quranDisplay.wordByWordInlineTranslation)
                .disabled(!settings.wordByWordInlineTransliteration)

            SettingsToggle(String(localized: "Transliteration"), caption: String(localized: "How each word is pronounced, written above its meaning. Independent of the ayah's own transliteration line."), isOn: $quranDisplay.wordByWordInlineTransliteration)
                .disabled(!settings.wordByWordInlineTranslation)
        }
        .settingsDependent()
    }
    #endif

    private var arabicVisibilityToggle: some View {
        SettingsToggle(String(localized: "Show Arabic Quran Text"), isOn: $quranDisplay.showArabicText)
            .disabled(!settings.showTransliteration && !settings.showEnglishSaheeh && !settings.showEnglishMustafa)
    }

    private var highlightAllahGroup: some View {
        SettingsToggle(String(localized: "Highlight Allah"), caption: String(localized: "Colors the majestic and glorius name الله (Allah) in red throughout the Quran."), isOn: $quranDisplay.highlightAllahNames)
            .disabled(!settings.showArabicText)
    }

    private var tajweedSettingsGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hafs paints from the computed rule tree; every other riwayah paints the
            // word colors of its own printed mushaf (QiraahTajweedStore pack).
            let tajweedCanRenderNow = settings.showArabicText
                && (settings.isHafsDisplay || settings.riwayahTajweedPackTag != nil)
            let tajweedToggleBinding = Binding<Bool>(
                get: { settings.showTajweedColors && tajweedCanRenderNow },
                set: { settings.showTajweedColors = $0 }
            )

            SettingsToggle(String(localized: "Show Tajweed Colors"), isOn: tajweedToggleBinding)
                .disabled(!tajweedCanRenderNow)

            #if os(iOS)
            NavigationLink(destination: LazyDestination { TajweedLegendView(showsDismissButton: false) }) {
                SettingsRowLabel(title: String(localized: "Customize Tajweed Colors"), systemImage: "paintpalette.fill", tint: SettingsTint.quran)
            }
            .tint(settings.accentColor.color)
            .disabled(!settings.showTajweedColors)
            #endif
        }
    }

    /// The TAJWEED section's footer: how a riwayah other than Hafs is colored, for readers who have
    /// the riwayat on screen.
    @ViewBuilder
    private var tajweedFooter: some View {
        if settings.showQiraahDetails {
            Text(settings.isHafsDisplay
                 ? String(localized: "Hafs an Asim colors every rule from the tajweed rule engine. The other qiraat and riwayat color words the way their own printed mushaf does, each with its own legend.")
                 : String(localized: "This riwayah colors words the way its printed mushaf does (differences from Hafs, idgham, imalah, ...). See its legend in Customize Tajweed Colors."))
        }
    }

    // The printed-mushaf (PDF) switch used to live here too; it is a reading MODE, so its only
    // home now is the reader's own top menu ("Read as Printed Mushaf (PDF)" / Page Text picker),
    // where the night-mode toggle also lives.

    @ViewBuilder
    private var cleanArabicTextGroup: some View {
        // Clean/no-dots applies to every riwayah now: the skeleton is derived at render time from
        // the fully vocalized text, so the toggles show regardless of the selected reading.
        cleanArabicTextToggles
    }

    // The two switches are INDEPENDENT, and that is the fix (2026-09-11). Hide Dots used to be
    // rendered only `if cleanArabicText || removeArabicDots`, and turning Hide Tashkeel off also
    // force-cleared it, so the pair behaved like nothing else in the app: the second box appeared
    // and disappeared as you touched the first, and switching the first off silently unchecked the
    // second. Between them that made "dots hidden, tashkeel shown" - the closest thing to an early
    // manuscript, which is the whole point of the option - unreachable, with no way to tell that
    // from a bug. They read the same text through two independent transforms, so they belong on
    // screen as two independent switches.
    //
    // No `.disabled(!showArabicText)` on either: the LETTERS AND MARKS section already renders this
    // whole group only while Show Arabic Quran Text is on, so the modifier could never fire and only
    // suggested that a disabled-but-ticked state existed somewhere.
    private var cleanArabicTextToggles: some View {
        VStack(alignment: .leading) {
            SettingsToggle(String(localized: "Hide Arabic Tashkeel (Vowel Diacritics) and Signs"), caption: String(localized: "Removes the tashkeel (fatha, damma, kasra and the rest) and the small signs: madd marks, hamzat al-wasl, tiny vowel letters, stop signs and markers. The vowel letters stay. Not recommended."), isOn: $quranDisplay.cleanArabicText)
            
            // No `.settingsDependent()` rail any more: that indent marks a row as belonging to the
            // one above it, which is exactly the relationship this row no longer has.
            SettingsToggle(String(localized: "Hide Arabic Dots"), caption: String(localized: "Removes the dots, turning ب into ٮ, the way the earliest manuscripts such as the Birmingham folios were written. Hard to read; not for beginners."), isOn: $quranDisplay.removeArabicDots)
        }
    }

    private var arabicFontPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Every Hijazi mark style reads as "Hijazi" here; the style itself is chosen on the row
            // below, which exists only while Hijazi is selected (five segments is all an iPhone
            // width fits). Order: the two printed-mushaf hands, then the two historical scripts
            // oldest first, then the system font.
            //
            // No `.animation` on the selection (app-wide rule for pickers, 2026-09-07): an animated
            // transaction on a segmented control's binding made the indicator slide to the tapped
            // segment, snap back to the old one and slide again, landing ~0.6 s after the tap while
            // the caption below had already changed (frame capture on the iPhone 17 Pro simulator).
            Picker("Arabic Font", selection: Binding(
                get: {
                    #if os(watchOS)
                    // A face this watch cannot draw (a synced Hijazi or Kufi) shows as the Uthmani it falls back to.
                    return Settings.drawableArabicFontName(Settings.pickerFaceName(for: settings.fontArabic))
                    #else
                    return Settings.pickerFaceName(for: settings.fontArabic)
                    #endif
                },
                set: { settings.fontArabic = $0 }
            )) {
                Text("Uthmani").tag(Settings.hafsUthmaniFontName)
                Text("Indopak").tag(Settings.indopakFontName)
                #if !os(watchOS)
                // The hand of the earliest mushafs themselves (Al-Islam Hijazi, built from hijazifont).
                // Not on the watch: its bundle ships neither file (A9).
                Text("Hijazi").tag(Settings.hijaziFontName)
                // The angular script of the early Abbasid mushafs (Noto Kufi Arabic).
                Text("Kufi").tag(Settings.kufiFontName)
                #endif
                Text("Basic").tag(Settings.systemArabicFontName)
            }
            #if os(iOS)
            .pickerStyle(SegmentedPickerStyle())
            #endif
            .disabled(!settings.showArabicText)
            .onChange(of: settings.fontArabic) { _ in settings.hapticFeedback() }

        }
    }

    /// The FONT section's footer: where the chosen hand comes from, then the one thing every face
    /// shares. A footer, as under the hadith and Islam font pickers; the watch has no room for it.
    @ViewBuilder
    private var arabicFontFooter: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 6) {
            if let face = Settings.arabicFace(forQuranFontName: settings.fontArabic) {
                Text(face.historyCaption.localizedDigits)
            }
            Text(Settings.uthmaniRasmCaption.localizedDigits)
        }
        #endif
    }

    /// The Hijazi face's three mark styles (`Settings.HijaziMarkStyle`): one typeface to the picker
    /// above, three builds of it here. Shown only while Hijazi is the Quran face.
    @ViewBuilder
    private var hijaziMarkStylePicker: some View {
        if Settings.isHijaziFontName(settings.fontArabic) {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Hijazi Marks", selection: $quranDisplay.fontArabic) {
                    ForEach(Settings.HijaziMarkStyle.allCases) { style in
                        Text(style.label).tag(style.fontName)
                    }
                }
                #if os(iOS)
                .pickerStyle(SegmentedPickerStyle())
                #endif
                .disabled(!settings.showArabicText)

                #if os(iOS)
                SettingsCaption(String(localized: "Same letters, different vowel marks. Light and Bold are the usual marks at two weights; Dot Vowels is the earliest vocalised mushafs' way: a dot above is fatha, below is kasra, in front is damma, doubled is tanween."))
                    .padding(.vertical, 2)
                #endif
            }
        }
    }

    /// Sits under the Arabic Font picker because it only refines the Uthmani choice - IndoPak
    /// and Basic ignore it entirely, so with either of those selected the row isn't rendered at
    /// all rather than shown dead. It stays for every reader otherwise: the two scripts are a
    /// real choice even for someone reading Hafs alone. What the riwayat gate is the SHAPE of
    /// the choice - with them hidden there is no Automatic to follow, and the captions describe
    /// the scripts without naming a riwayah the reader has never been shown.
    @ViewBuilder
    private var arabicScriptStylePicker: some View {
        if settings.usesUthmaniArabicFont {
            let showQiraah = settings.showQiraahDetails
            VStack(alignment: .leading, spacing: 8) {
                Picker("Uthmani Script", selection: Binding(
                    get: { settings.arabicScriptStyle },
                    set: { newValue in
                        settings.hapticFeedback()
                        settings.arabicScriptStyle = newValue
                    }
                )) {
                    ForEach(Settings.ArabicScriptStyle.options(showQiraah: showQiraah)) { style in
                        Text(style.label).tag(style)
                    }
                }
                #if os(iOS)
                .pickerStyle(SegmentedPickerStyle())
                #endif

                SettingsCaption(settings.arabicScriptStyle.detail(namingRiwayat: showQiraah))

                // Only for readers who have the qiraat on screen: what the script choice is really
                // choosing between, named by the ten rather than the twenty (both riwayat of a
                // qiraah always mark wasl the same way - verified across all twenty texts).
                if showQiraah {
                    SettingsCaption(Settings.waslNotationNote)
                }
            }
            .padding(.vertical, 2)
        }
    }

    /// The size control (`FontSizeSlider`: sample line, small ب to big ب, one write on release), then
    /// the system-size switch. The sample is set in the face the reader will actually draw, cleaned
    /// the way Hide Tashkeel / Hide Dots would clean it.
    private var arabicFontSizeControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            FontSizeSlider(String(localized: "Arabic Font Size"), value: $quranDisplay.fontArabicSize, in: 15...75,
                           sample: settings.cleanedQuranArabic(Settings.arabicSizeSample),
                           fontName: settings.quranArabicFontName(for: settings.displayQiraahForArabic),
                           glyph: settings.cleanedQuranArabic("ب"))

            SettingsToggle(String(localized: "Use Device Text Size"), isOn: useSystemArabicFontSize)

            #if os(iOS)
            fitPageControls
            #endif
        }
    }

    #if os(iOS)
    private var fitPageControls: some View {
        VStack(alignment: .leading) {
            SettingsToggle(String(localized: "Fit Page to Screen"), caption: String(localized: "Each page laid out as this riwayah's printed mushaf is, at the largest size that fits the screen. Off, the size above applies and the page scrolls."), isOn: $quranDisplay.mushafFitPage)

            // An @AppStorage flip that changes the READER's page layout behind this sheet. It used to
            // be the one switch here with NO `.animation` on its binding, because an animated write
            // made every mounted mushaf page re-evaluate INSIDE the animation (the trap recorded in
            // `page-mode-chrome-bands`). Every switch is a `SettingsToggle` now: its write is flagged
            // and the pager strips the animation from it (`ignoresSettingsPageAnimation`), so this
            // row animates the sheet like its neighbours while the reader animates its own spread change.
            SettingsToggle(String(localized: "Two-Page Spread"), caption: String(localized: "Two facing pages, like an open mushaf, whenever the page area is wider than it is tall: landscape, an iPad, a wide Mac window. Portrait shows one."), isOn: $quranDisplay.mushafTwoPageSpread)
        }
    }
    #endif

    /// Hamzat al-wasl: the saad of the Madinah prints or the Maghribi dot, on every riwayah; Follow
    /// the Print keeps each text as its mushaf writes it (Abu, 2026-10-26). The divine name in both
    /// notations, set in the reader's own Quran face, previews the choice. The codes behind it ship
    /// precomputed (WaslSigns.swift), so the picker only changes which splice the rows apply.
    private var waslSignPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Hamzat al-Wasl", selection: Binding(
                get: { settings.waslSignStyle },
                set: { newValue in
                    settings.hapticFeedback()
                    settings.waslSignStyle = newValue
                }
            )) {
                ForEach(Settings.WaslSignStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }
            #if os(iOS)
            .pickerStyle(SegmentedPickerStyle())
            #endif

            HStack(spacing: 28) {
                waslSignPreview("\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650}", label: Settings.WaslSignStyle.saad.label)
                waslSignPreview("\u{0627}\u{0650}\u{06EC}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650}", label: Settings.WaslSignStyle.dot.label)
            }
            .frame(maxWidth: .infinity)

            SettingsCaption(settings.waslSignStyle.detail)
        }
        .disabled(!settings.showArabicText)
    }

    /// One word of the preview: the Quran face the reader has chosen, over a small label.
    private func waslSignPreview(_ word: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(word)
                .font(.custom(settings.quranArabicFontName(for: settings.displayQiraahForArabic), size: 30))
                .environment(\.layoutDirection, .rightToLeft)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var beginnerModeGroup: some View {
        SettingsToggle(String(localized: "Enable Arabic Beginner Mode"), caption: String(localized: "Puts a space between each Arabic letter to make it easier for beginners to read the Quran."), isOn: $quranDisplay.beginnerMode)
            .disabled(!settings.showArabicText)
    }

    /// The page in two sections (2026-10-25): what shows, then how large. The size section exists only
    /// while some English line is on; there is nothing for it to size otherwise.
    @ViewBuilder
    private var englishTextSections: some View {
        Section(header: Text("ENGLISH TEXT"), footer: settings.showQiraahDetails ? Text("Transliteration, translations, and all English text apply only to default Hafs an Asim. For other riwayat, only the Arabic text is shown.") : nil) {
            includeEnglishToggle
            englishDisplayToggles
        }

        if englishSizeApplies {
            Section(header: Text("SIZE")) {
                englishFontSizeControls
            }
        }
    }

    private var englishSizeApplies: Bool {
        settings.isHafsDisplay && includeEnglish.wrappedValue
            && (settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa)
    }

    private var includeEnglishToggle: some View {
        SettingsToggle(String(localized: "Include English"), isOn: includeEnglish)
            .disabled(!settings.isHafsDisplay)
    }

    @ViewBuilder
    private var englishDisplayToggles: some View {
        if settings.isHafsDisplay && includeEnglish.wrappedValue {
            SettingsToggle(String(localized: "Show Transliteration"), isOn: $quranDisplay.showTransliteration)
                .disabled(!settings.showArabicText && !settings.showEnglishSaheeh && !settings.showEnglishMustafa)
                .settingsDependent()

            SettingsToggle(String(localized: "Show English Translation"), caption: String(localized: "Saheeh International"), isOn: $quranDisplay.showEnglishSaheeh)
                .disabled(!settings.showArabicText && !settings.showTransliteration && !settings.showEnglishMustafa)
                .settingsDependent()

            SettingsToggle(String(localized: "Show English Translation"), caption: String(localized: "Clear Quran (Mustafa Khattab)"), isOn: $quranDisplay.showEnglishMustafa)
                .disabled(!settings.showArabicText && !settings.showTransliteration && !settings.showEnglishSaheeh)
                .settingsDependent()
        }
    }

    private var englishFontSizeControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            FontSizeSlider(String(localized: "English Font Size"), value: $quranDisplay.englishFontSize, in: 13...20,
                           sample: Settings.englishSizeSample)

            SettingsToggle(String(localized: "Use Device Text Size"), isOn: useSystemEnglishFontSize)
        }
    }

    private var qiraahSection: some View {
        Section {
            if settings.showQiraahDetails {
                Button {
                    settings.hapticFeedback()
                    hideQiraahDetails()
                } label: {
                    HStack {
                        Label("Hide Riwayah / Qiraah", systemImage: "character.book.closed.fill.ar")
                        Spacer()
                        Image(systemName: "chevron.up")
                    }
                    .foregroundColor(settings.accentColor.color)
                }
                                
                qiraahPicker
                // The beta-TEXT switch only surfaces for comparison users: everyone else reads a beta
                // riwayah through its exact printed mushaf and is never pitched the beta text at all
                // (user rule: "only show the beta toggle if comparison mode is on - otherwise just PDFs").
                if settings.qiraatComparisonMode {
                    betaQiraatGroup
                }
                qiraahExplanation
                qiraahLinks
                qiraahHighlight
                comparisonModeGroup
            } else {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.showQiraahDetails = true
                    }
                } label: {
                    HStack {
                        Label("Show Riwayah / Qiraah", systemImage: "character.book.closed.fill.ar")
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .foregroundColor(settings.accentColor.color)
                }
            }
        } header: {
            // With riwayah/qiraah hidden the header carries no riwayah caption and the footer stays
            // empty: the collapsed section is just the "Show Riwayah / Qiraah" entry point, not a pitch.
            HStack(spacing: 6) {
                Text("RIWAYAH / QIRAAH")
                if settings.showQiraahDetails {
                    Text("- \(settings.displayQiraahArabicCaption)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .padding(.vertical, 2)
                }
                Spacer(minLength: 0)
            }
        } footer: {
            if settings.showQiraahDetails {
                Text(String(localized: "This app supports all 20 riwayat, 12 of them in beta.\n\nThe riwayat printed in the Maghribi script use the official King Fahd Complex Warsh typeface; the others share the Uthmani (Madani) script typeface. You can override this under Arabic Text → Uthmani Script.\n\nPlay Ayahs is unsupported for other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.").localizedDigits)
            }
        }
    }

    private func hideQiraahDetails() {
        if settings.isHafsDisplay {
            withAnimation(.easeInOut) {
                settings.showQiraahDetails = false
            }
        } else {
            settings.showQiraahDetails = true
            confirmHideQiraahDetails = true
        }
    }

    private var qiraahPicker: some View {
        // Menu-row form: `choose(_:)` inside the picker already fires the haptic, so no `.onChange`
        // echo here (the old flat Picker needed one).
        ArabicTextRiwayahPicker(
            selection: $quranDisplay.displayQiraah,
            useMenuRow: true
        )
    }

    /// The beta-TEXT switch. All twenty riwayat are always selectable and their printed
    /// mushafs (facsimiles) always load - this only governs whether the 12 machine-
    /// extracted TEXTS may render (lists, comparison, page text). The same consent is
    /// offered inline where text would appear (`BetaTextConsentCard`); this row is the
    /// settings-side twin and the way to turn beta text back off.
    @ViewBuilder
    private var betaQiraatGroup: some View {
        SettingsToggle(String(localized: "Beta Text (12 Riwayat, 6 Qiraat)"),
                       caption: String(localized: "Selectable text for Ibn Amir, Hamzah, al-Kisai, Abu Jafar, Yaqub and Khalaf al-Ashir. Their printed mushafs are exact and always available in page mode; only this machine-extracted text is beta."),
                       systemImage: "flask",
                       isOn: Binding(
                           get: { settings.betaQiraatEnabled },
                           set: { newValue in
                               if newValue {
                                   confirmEnableBetaQiraat = true      // confirm before unlocking
                               } else {
                                   settings.betaQiraatEnabled = false
                               }
                           }
                       ))
        .confirmationDialog(
            "Turn on beta text?",
            isPresented: $confirmEnableBetaQiraat,
            titleVisibility: .visible
        ) {
            Button("Turn On") {
                settings.hapticFeedback()
                settings.betaQiraatEnabled = true
                settings.acceptedBetaQiraatNotice = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(Settings.betaQiraatNotice)
        }

        if settings.betaQiraatEnabled {
            SettingsCaption(Settings.betaQiraatNotice)
        }
    }

    private var qiraahExplanation: some View {
        Text("""
        The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the Muslims. From these, the 10 Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

        The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

        To learn more about the 7 Ahruf and the 10 Qiraat, see below and in Al-Islam View > Islamic Pillars and Basics.
        """)
            .font(.caption)
            .foregroundColor(.primary)
            .padding(.vertical, 2)
    }

    /// Three doors in the row grammar every settings link uses (they were caption-sized text links).
    private var qiraahLinks: some View {
        Group {
            NavigationLink(destination: LazyDestination { AhrufView() }) {
                SettingsRowLabel(title: String(localized: "The 7 Ahruf (Modes)"), systemImage: "text.book.closed.fill", tint: SettingsTint.quran)
            }
            .tint(settings.accentColor.color)

            NavigationLink(destination: LazyDestination { QiraatView() }) {
                SettingsRowLabel(title: String(localized: "The 10 Qiraat (Recitations)"), systemImage: "books.vertical.fill", tint: SettingsTint.quran)
            }
            .tint(settings.accentColor.color)

            // The explorer beside the two articles it grew out of (Abu, 2026-09-26: "show qiraat
            // explorer in qiraat settings"): every place the riwayat differ, ayah by ayah.
            #if os(iOS)
            NavigationLink(destination: LazyDestination { QiraatExplorerView() }) {
                SettingsRowLabel(title: String(localized: "Qiraat Explorer"), systemImage: "arrow.triangle.branch", tint: SettingsTint.quran)
            }
            .tint(settings.accentColor.color)
            #endif
        }
    }

    private var qiraahHighlight: some View {
        Text("***Hafs an Asim* is the most common and widespread Qiraah in the world today.**")
            .font(.caption)
            .foregroundColor(.primary)
            .padding(.top, 4)
            .padding(.vertical, 2)
    }

    private var comparisonModeGroup: some View {
        SettingsToggle(String(localized: "Comparison mode"), caption: String(localized: "Shows the riwayah picker above the search bar on Hafs too, so you can switch and compare there. Every other riwayah always shows it."), isOn: $quranDisplay.qiraatComparisonMode)
    }

}

/// Section header for qiraat reciter groups: title and Arabic on one row (same idea as `JuzHeader`).

#Preview {
    AlIslamPreviewContainer(embedInNavigation: true) {
        SettingsQuranView()
    }
}

#if os(iOS)
enum FavoriteType: Identifiable {
    case surah, ayah, letter, khatm
    var id: Self { self }
}

/// Bulk editor for the user's saved Quran items - favorite surahs, bookmarked ayahs, favorite letters, and
/// khatm progress - with swipe-to-delete, EditButton, and a "Delete All". Reachable from Quran Settings.
struct FavoritesView: View {
    @ObservedObject var quranData = QuranData.shared
    private let settings = Settings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @State private var editMode: EditMode = .inactive

    let type: FavoriteType

    var body: some View {
        List {
            Group {
            switch type {
            case .surah:
                if settings.favoriteSurahs.isEmpty {
                    Text("No favorite surahs here, long tap a surah to favorite it.")
                } else {
                    ForEach(settings.favoriteSurahs.sorted(), id: \.self) { surahId in
                        if let surah = quranData.surah(surahId) {
                            SurahRow(surah: surah, isFavorite: true).equatable()
                        }
                    }
                    .onDelete(perform: removeSurahs)
                }
            case .ayah:
                if settings.bookmarkedAyahs.isEmpty {
                    Text("No bookmarked ayahs here, long tap an ayah to bookmark it.")
                } else {
                    // Memoized order + indexed lookups: this list re-sorted itself and then walked
                    // all 114 surahs (and the surah's ayahs) for EVERY row on every body pass.
                    ForEach(settings.bookmarkedAyahsInMushafOrder, id: \.id) { bookmarkedAyah in
                        if let surah = quranData.surah(bookmarkedAyah.surah),
                           let ayah = quranData.ayah(surah: bookmarkedAyah.surah, ayah: bookmarkedAyah.ayah) {
                            SurahAyahRow(surah: surah, ayah: ayah)
                                .equatable()
                        }
                    }
                    .onDelete(perform: removeAyahs)
                }
            case .letter:
                if settings.favoriteLetters.isEmpty {
                    Text("No favorite letters here, long tap a letter to favorite it.")
                } else {
                    ForEach(settings.favoriteLetters.sorted(), id: \.id) { favorite in
                        ArabicLetterRow(letterData: favorite).equatable()
                    }
                    .onDelete(perform: removeLetters)
                }
            case .khatm:
                if settings.khatmCompletedAyahCount == 0 {
                    Text("No khatm progress yet. Open a surah while Khatm mode is selected to mark ayahs as viewed.")
                } else {
                    ForEach(quranData.quran.filter { settings.khatmCompletedCount(for: $0) > 0 }, id: \.id) { surah in
                        SurahRow(
                            surah: surah,
                            khatmCompletedAyahs: settings.khatmCompletedCount(for: surah),
                            khatmTotalAyahs: surah.numberOfAyahs
                        )
                        .equatable()
                    }
                    .onDelete(perform: removeKhatmSurahs)
                }
            }

            Section {
                if !isListEmpty {
                    Button("Delete All") {
                        settings.hapticFeedback()
                        withAnimation { deleteAll() }
                    }
                    .foregroundColor(.red)
                }
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(titleForFavoriteType(type))
        .toolbar {
            EditButton()
        }
        .environment(\.editMode, $editMode)
    }

    private var isListEmpty: Bool {
        switch type {
        case .surah: return settings.favoriteSurahs.isEmpty
        case .ayah: return settings.bookmarkedAyahs.isEmpty
        case .letter: return settings.favoriteLetters.isEmpty
        case .khatm: return settings.khatmCompletedAyahCount == 0
        }
    }

    private func deleteAll() {
        switch type {
        case .surah:
            settings.favoriteSurahs.removeAll()
        case .ayah:
            settings.bookmarkedAyahs.removeAll()
        case .letter:
            settings.favoriteLetters.removeAll()
        case .khatm:
            settings.resetAllKhatmProgress()
        }
    }

    private func removeSurahs(at offsets: IndexSet) {
        let sorted = settings.favoriteSurahs.sorted()
        let idsToRemove = offsets.map { sorted[$0] }
        settings.favoriteSurahs.removeAll { idsToRemove.contains($0) }
    }

    private func removeAyahs(at offsets: IndexSet) {
        let sorted = settings.bookmarkedAyahs.sorted {
            $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
        }
        let idsToRemove = Set(offsets.map { sorted[$0].id })
        settings.bookmarkedAyahs.removeAll { idsToRemove.contains($0.id) }
    }

    private func removeLetters(at offsets: IndexSet) {
        let sorted = settings.favoriteLetters.sorted()
        let lettersToRemove = Set(offsets.map { sorted[$0].letter })
        settings.favoriteLetters.removeAll { lettersToRemove.contains($0.letter) }
    }

    private func removeKhatmSurahs(at offsets: IndexSet) {
        let surahsWithProgress = quranData.quran.filter { settings.khatmCompletedCount(for: $0) > 0 }
        for offset in offsets {
            settings.resetKhatmProgress(for: surahsWithProgress[offset])
        }
    }

    private func titleForFavoriteType(_ type: FavoriteType) -> String {
        switch type {
        case .surah:  return String(localized: "Favorite Surahs")
        case .ayah:   return String(localized: "Bookmarked Ayahs")
        case .letter: return String(localized: "Favorite Letters")
        case .khatm:  return String(localized: "Khatm Progress")
        }
    }
}
#endif


#if os(iOS)
// MARK: - Settings-search entries (kept in THIS file, next to the screens they describe)
extension SettingsSearchEntry {
    static let quranEntries: [SettingsSearchEntry] = [
        .init(title: "Keep Sheet Open", path: "Quran Settings → Reading View", keywords: "ayah actions sheet stay open stack tafsir custom range underneath second", destination: .quranPage(.readingView)),
        .init(title: "Keep Sheet Open While Playing", path: "Quran Settings → Reading View", keywords: "ayah actions sheet stay open play this ayah repeat close dismiss read while playing", destination: .quranPage(.readingView)),
        .init(title: "Keep Screen On With Ayah Actions", path: "Quran Settings → Reading View", keywords: "ayah actions sheet screen awake sleep dim lock idle display", destination: .quranPage(.readingView)),
        .init(title: "Ayah Card Size", path: "Ayah actions sheet", keywords: "preview card arabic bigger smaller plus minus percent remember size", destination: .quranSettings),
        .init(title: "Quran Settings", path: "Al-Quran", keywords: "mushaf reading", destination: .quranSettings),
        .init(title: "Need a Hand? on the Quran Tab", path: "Quran Settings", keywords: "need a hand help shortcuts questions show hide quran tab need help reading beginner transliteration kahf friday", destination: .quranSettings, isAvailable: { !Settings.shared.hides(.pageHelpDoors) }),
        .init(title: "Reciter", path: "Quran Settings → Recitation", keywords: "reciters audio download favorite minshawi husary sudais qari listen", destination: .reciters),
        .init(title: "Recitation Type & Random Reciter", path: "Quran Settings → Recitation", keywords: "murattal mujawwad muallim random ayah recitation", destination: .quranPage(.recitation)),
        .init(title: "After Surah Recitation Ends", path: "Quran Settings → Recitation", keywords: "next surah previous end stop continue autoplay recitation end", destination: .quranPage(.recitation)),
        .init(title: "Reading View (List / Pages)", path: "Quran Settings → Reading View", keywords: "page mode mushaf list mode grid last read", destination: .quranPage(.readingView)),
        .init(title: "Show Full Surah Details", path: "Quran Settings → Reading View", keywords: "revelation type ayah count page count surah list details", destination: .quranPage(.readingView)),
        .init(title: "Ayah of the Day & Word of the Day", path: "Quran Settings → Reading View", keywords: "daily ayah word vocabulary quran tab summary tiles", destination: .quranPage(.readingView)),
        .init(title: "Daily Cards Turn Over at Fajr", path: "Quran Settings → Reading View", keywords: "midnight fajr rollover day change hadith dua reminder name", destination: .quranPage(.readingView)),
        .init(title: "Page and Juz Dividers", path: "Quran Settings → Reading View", keywords: "divider juz page label floating reading", destination: .quranPage(.readingView)),
        .init(title: "Arabic Text (Quran)", path: "Quran Settings → Arabic Text", keywords: "font size uthmani indopak script clean dots beginner mode spacing", destination: .quranPage(.arabicText)),
        .init(title: "Arabic Font & Size", path: "Quran Settings → Arabic Text", keywords: "uthmani indopak kufi hijazi face font size slider system device", destination: .quranPage(.arabicText)),
        .init(title: "Hijazi Marks & Uthmani Script Style", path: "Quran Settings → Arabic Text", keywords: "hijazi marks style uthmani script madani maghribi warsh typeface variant", destination: .quranPage(.arabicText)),
        .init(title: "Tajweed Colors", path: "Quran Settings → Arabic Text", keywords: "tajwid rules colors ghunnah qalqalah madd legend", destination: .quranPage(.arabicText)),
        .init(title: "Tap a Word & Word by Word", path: "Quran Settings → Arabic Text", keywords: "word by word gloss meaning pronunciation transliteration inline tap", destination: .quranPage(.arabicText)),
        .init(title: "Hide Tashkeel & Dots", path: "Quran Settings → Arabic Text", keywords: "clean arabic tashkeel harakat diacritics dots beginner spacing", destination: .quranPage(.arabicText)),
        .init(title: "Highlight Allah (Quran)", path: "Quran Settings → Arabic Text", keywords: "highlight name of allah red color quran", destination: .quranPage(.arabicText)),
        .init(title: "Riwayah & Qiraat", path: "Quran Settings → Arabic Text", keywords: "hafs warsh qaloon riwayah qiraat ahruf readings", destination: .quranPage(.arabicText)),
        .init(title: "Test Mode", path: "Quran Settings → Test Mode", keywords: "test memorize memorization hifz hide text recite from memory quiz check reveal tap ayah", destination: .quranPage(.testMode)),
        .init(title: "Transliteration & English Translations", path: "Quran Settings → English Text", keywords: "saheeh international mustafa khattab translation english transliteration", destination: .quranPage(.englishText)),
        .init(title: "English Font Size", path: "Quran Settings → English Text", keywords: "english font size translation slider system device", destination: .quranPage(.englishText)),
        .init(title: "Highlight Themes (Color-Coded Passages)", path: "Quran Settings → Highlight Themes", keywords: "thematic highlighting colors legend passages sections topics wash lit themes browse by theme tilawa", destination: .quranPage(.highlightThemes)),
        .init(title: "Sunnah Reminders", path: "Quran Settings → Sunnah Reminders", keywords: "al-kahf friday al-mulk sleep muawwidhat reminder notification", destination: .quranPage(.sunnahReminders)),
        .init(title: "Favorites and Bookmarks (Quran)", path: "Quran Settings → Favorites and Bookmarks", keywords: "manage favorites bookmarks notes surahs ayahs letters khatm", destination: .quranPage(.favorites)),
    ]
}
#endif

// MARK: - Reciter list (merged from ReciterListView.swift: same file as the Quran settings that link to it)

private struct QiraahReciterSectionHeader: View {
    let title: String
    let arabic: String
    /// Reciters in this riwayah section - shown as the app's standard trailing count pill.
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            // In the Arabic interface the riwayah's Arabic name is the title, so the Latin one and
            // the "- " line beside it are left out.
            if AppLanguage.isArabicScript, !arabic.isEmpty {
                Text(arabic)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            } else {
                Text(title)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text("- \(arabic)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .padding(.vertical, 2)
            }
            Spacer(minLength: 0)

            CountPill(count: count)
        }
    }
}

/// Qiraat-level header above a qiraah's riwayah sections: the imam's name and Arabic, with a
/// riwayat-count pill in the `CountPill` idiom (accent caption on glass; text instead of a bare
/// number because the data distinguishes riwayat from reciters). Accent title marks it as the
/// higher grouping level, the same move `SectionPillHeader`'s `accentTitle` makes.
private struct QiraahGroupSectionHeader: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    let teacher: String
    let teacherArabic: String
    let riwayahCount: Int

    var body: some View {
        HStack(spacing: 6) {
            // The imam's Arabic name in the Arabic interface, which then needs no second line.
            let arabicTitle = AppLanguage.isArabicScript && !teacherArabic.isEmpty
            Text("QIRAAH OF \(arabicTitle ? teacherArabic : teacher.uppercased())")
                .foregroundStyle(settings.accentColor.color)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            if !arabicTitle {
                Text("- \(teacherArabic)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .padding(.vertical, 2)
            }

            Spacer(minLength: 0)

            Text(riwayahCount == 1 ? String(localized: "\(riwayahCount) riwayah") : String(localized: "\(riwayahCount) riwayat"))
                .textCase(nil)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .conditionalGlassEffect()
        }
    }
}

private struct MurattalSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 2)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}

struct ReciterListView: View {
    /// When `true`, dismisses the sheet (or pops navigation) after the user picks a reciter or Random.
    /// Dismissal still waits until any confirmation dialog (qiraah change / Minshawi fallback) is resolved.
    var dismissAfterSelectingReciter = true
    /// When `false`, list opens at top without scrolling to the selected reciter.
    var autoScrollToInitialSelection = true

    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    @ObservedObject private var quranContent = QuranContent.shared

    @ObservedObject private var quranDisplay = QuranDisplay.shared

    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.presentationMode) private var presentationMode
    @State private var didAutoScrollToSelection = false
    @State private var searchText = ""
    @State private var pendingQiraahReciter: Reciter?
    @State private var pendingDisplayQiraahTag: String?
    @State private var pendingMinshawiReciter: Reciter?
    @State private var pendingMurattalStyleReciter: Reciter?
    @State private var pendingScrollToReciterID: String? = nil
    @State private var confirmHideQiraahDetails = false
    @AppStorage("splitMurattalRecitersByGroup") private var splitMurattalRecitersByGroup = false
    #if os(iOS)
    @StateObject private var downloadManager = ReciterDownloadManager.shared
    @State private var showDownloadedOnly = false
    #endif

    private struct MurattalReciterGroup: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let reciters: [Reciter]
    }

    #if os(iOS)
    @State private var showReciterTypeLegendInfo = false

    /// The colored legend that replaced the per-row explanatory captions: one dot per reciter type,
    /// with the full explanation one tap away.
    private var reciterTypeLegend: some View {
        // The dialog is attached to the compact dots cluster - not a full-width row - so on iPad it
        // pops from the legend itself.
        HStack {
            Spacer(minLength: 0)

            Button {
                settings.hapticFeedback()
                showReciterTypeLegendInfo = true
            } label: {
                HStack(spacing: 8) {
                    reciterTypeLegendItem(.blue, String(localized: "Full offline"))
                    reciterTypeLegendItem(.green, String(localized: "Own voice"))
                    reciterTypeLegendItem(.orange, String(localized: "Murattal"))
                    reciterTypeLegendItem(.red, String(localized: "Surahs only"))
                    reciterTypeLegendItem(.purple, String(localized: "Incomplete"))
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .confirmationDialog("Reciter Types", isPresented: $showReciterTypeLegendInfo, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text(String(localized: "Blue: the highest tier; surahs and individual ayahs play in this reciter's own voice, and downloaded surahs also play ayah-by-ayah fully offline. Green: individual ayahs play in this reciter's own voice when streaming. Orange: streamed ayahs play in a Murattal style; download the surah to hear ayahs in this reciter's own voice. Red: full surahs only; individual ayahs default to Minshawi (Murattal). Purple: incomplete; this reciter has not recorded all 114 surahs.").localizedDigits)
        }

            Spacer(minLength: 0)
        }
    }

    private func reciterTypeLegendItem(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
    #endif

    private var qiraahChangeDialogTitle: String {
        pendingRequestedQiraahIsUnsupported ? String(localized: "Qiraah Text Not Supported") : String(localized: "Change Quran Text?")
    }

    private var qiraahChangeDialogMessage: String {
        if pendingRequestedQiraahIsUnsupported {
            let qiraahName = pendingQiraahReciter?.qiraah?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let qiraahName, !qiraahName.isEmpty {
                return String(localized: "This reciter uses \(qiraahName). This qiraah text form is not supported right now. Keep your current Quran text and continue?")
            }
            return String(localized: "This reciter's qiraah text form is not supported right now. Keep your current Quran text and continue?")
        }

        if pendingDisplayQiraahTag == nil {
            return String(localized: "This reciter uses Hafs an Asim (default). Would you like to switch the Quran text to match it?")
        }

        guard let pendingQiraahReciter,
              let qiraah = pendingQiraahReciter.qiraah,
              !qiraah.isEmpty else {
            return String(localized: "This reciter uses a different riwayah. Would you like to switch the Quran text to match it?")
        }

        return String(localized: "This reciter uses \(qiraah). Would you like to switch the Quran text to match it?")
    }

    private func resolvedQiraahTag(for reciter: Reciter) -> String? {
        if let qiraah = reciter.qiraah, !qiraah.isEmpty {
            return qiraah
        }

        // Hafs reciters are represented by nil/empty qiraah in these primary sections.
        return nil
    }

    private func isSupportedQiraahForText(_ qiraahTag: String?) -> Bool {
        guard let qiraahTag, !qiraahTag.isEmpty else { return true }
        return Settings.Riwayah.menuOptions.contains(where: { $0.tag == qiraahTag })
    }

    private var pendingRequestedQiraahIsUnsupported: Bool {
        !isSupportedQiraahForText(pendingDisplayQiraahTag)
    }

    private struct ReciterSectionGroup: Identifiable {
        let id: String
        let title: String
        let arabic: String?
        let reciters: [Reciter]
        let isQiraah: Bool

        func withReciters(_ reciters: [Reciter]) -> ReciterSectionGroup {
            ReciterSectionGroup(id: id, title: title, arabic: arabic, reciters: reciters, isQiraah: isQiraah)
        }
    }

    private static let qiraahSearchKeywords = [
        "qiraah",
        "qiraat",
        "riwayah",
        "riwayaat",
        "recitation",
        "recitations"
    ]

    private static let hafsSearchKeywords = [
        "hafs",
        "asim",
        "aasim",
        "asim",
        "حفص",
        "عاصم"
    ]

    private func isSelectedReciter(_ reciter: Reciter) -> Bool {
        guard settings.reciter != Settings.randomReciterName else { return false }
        if !settings.reciterId.isEmpty {
            return settings.reciterId == reciter.id
        }
        return false
    }

    private var orderedUniqueReciters: [Reciter] {
        var seen = Set<String>()
        return allReciterSections
            .flatMap(\.reciters)
            .filter { seen.insert($0.id).inserted }
    }

    private var favoriteReciters: [Reciter] {
        orderedUniqueReciters.filter { settings.isReciterFavorite(reciterID: $0.id) }
    }

    private static let favoriteRowIDPrefix = "favorite"

    /// Matches row `.id(...)` for `ScrollViewReader.scrollTo`. A favorited reciter lands on its
    /// FAVORITES row: that copy is the one at the top of the list, where the reader keeps it.
    private var reciterListScrollTargetID: String {
        if settings.reciter == Settings.randomReciterName {
            return Settings.randomReciterName
        }
        let id = settings.resolvedSelectedReciterIgnoringRandom()?.id ?? settings.reciterId
        guard !id.isEmpty else { return settings.reciter }
        if settings.isReciterFavorite(reciterID: id) {
            return "\(Self.favoriteRowIDPrefix)|\(id)"
        }
        return id
    }

    private var normalizedSearchText: String {
        normalized(searchText)
    }

    private var isSearchingReciters: Bool {
        !normalizedSearchText.isEmpty
    }

    private var primaryReciterSections: [ReciterSectionGroup] {
        [
            ReciterSectionGroup(
                id: "minshawi",
                title: String(localized: "MUHAMMAD SIDDIQ AL-MINSHAWI"),
                arabic: nil,
                reciters: filteredReciters(recitersMinshawi),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "mujawwad",
                title: String(localized: "SLOW & MELODIC (MUJAWWAD)"),
                arabic: nil,
                reciters: filteredReciters(recitersMujawwad, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "muallim",
                title: String(localized: "TEACHING (MUALLIM)"),
                arabic: nil,
                reciters: filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "murattal",
                title: String(localized: "NORMAL (MURATTAL)"),
                arabic: nil,
                reciters: filteredReciters(recitersMurattal, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            )
        ]
    }

    private var qiraahReciterSections: [ReciterSectionGroup] {
        let sections = [
            // Shubah leads the riwayah sections: it shares Asim with Hafs (the default every other
            // list is implicitly "about"), mirroring `Riwayah.Option.order`. It was missing entirely,
            // which stranded its only reciter in the OTHER GROUP catch-all at the bottom.
            ReciterSectionGroup(
                id: "shubah",
                title: Settings.Riwayah.shubah.uppercased(),
                arabic: Settings.Riwayah.shubahArabic,
                reciters: filteredReciters(recitersShubah),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "khalaf",
                title: Settings.Riwayah.khalaf.uppercased(),
                arabic: Settings.Riwayah.khalafArabic,
                reciters: filteredReciters(recitersKhalaf),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "warsh",
                title: Settings.Riwayah.warsh.uppercased(),
                arabic: Settings.Riwayah.warshArabic,
                reciters: filteredReciters(recitersWarsh),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "qaloon",
                title: Settings.Riwayah.qaloon.uppercased(),
                arabic: Settings.Riwayah.qaloonArabic,
                reciters: filteredReciters(recitersQaloon),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "buzzi",
                title: Settings.Riwayah.buzzi.uppercased(),
                arabic: Settings.Riwayah.buzziArabic,
                reciters: filteredReciters(recitersBuzzi),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "qunbul",
                title: Settings.Riwayah.qunbul.uppercased(),
                arabic: Settings.Riwayah.qunbulArabic,
                reciters: filteredReciters(recitersQunbul),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "duri",
                title: Settings.Riwayah.duri.uppercased(),
                arabic: Settings.Riwayah.duriArabic,
                reciters: filteredReciters(recitersDuri),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "susi",
                title: Settings.Riwayah.susi.uppercased(),
                arabic: Settings.Riwayah.susiArabic,
                reciters: filteredReciters(recitersSusi),
                isQiraah: true
            ),
            // The remaining riwayat of the Ten Qiraat - one verified complete reciter each,
            // so every riwayah the app can display also has full-surah audio.
            ReciterSectionGroup(
                id: "hisham",
                title: Settings.Riwayah.hisham.uppercased(),
                arabic: Settings.Riwayah.hishamArabic,
                reciters: filteredReciters(recitersHisham),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "ibnDhakwan",
                title: Settings.Riwayah.ibnDhakwan.uppercased(),
                arabic: Settings.Riwayah.ibnDhakwanArabic,
                reciters: filteredReciters(recitersIbnDhakwan),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "khallad",
                title: Settings.Riwayah.khallad.uppercased(),
                arabic: Settings.Riwayah.khalladArabic,
                reciters: filteredReciters(recitersKhallad),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "abuHarith",
                title: Settings.Riwayah.abuHarith.uppercased(),
                arabic: Settings.Riwayah.abuHarithArabic,
                reciters: filteredReciters(recitersAbuHarith),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "duriKisai",
                title: Settings.Riwayah.duriKisai.uppercased(),
                arabic: Settings.Riwayah.duriKisaiArabic,
                reciters: filteredReciters(recitersDuriKisai),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "ibnWardan",
                title: Settings.Riwayah.ibnWardan.uppercased(),
                arabic: Settings.Riwayah.ibnWardanArabic,
                reciters: filteredReciters(recitersIbnWardan),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "ibnJammaz",
                title: Settings.Riwayah.ibnJammaz.uppercased(),
                arabic: Settings.Riwayah.ibnJammazArabic,
                reciters: filteredReciters(recitersIbnJammaz),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "ruways",
                title: Settings.Riwayah.ruways.uppercased(),
                arabic: Settings.Riwayah.ruwaysArabic,
                reciters: filteredReciters(recitersRuways),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "rawh",
                title: Settings.Riwayah.rawh.uppercased(),
                arabic: Settings.Riwayah.rawhArabic,
                reciters: filteredReciters(recitersRawh),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "ishaq",
                title: Settings.Riwayah.ishaq.uppercased(),
                arabic: Settings.Riwayah.ishaqArabic,
                reciters: filteredReciters(recitersIshaq),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "idris",
                title: Settings.Riwayah.idris.uppercased(),
                arabic: Settings.Riwayah.idrisArabic,
                reciters: filteredReciters(recitersIdris),
                isQiraah: true
            )
        ]

        if let uncategorizedReciterSection {
            return sections + [uncategorizedReciterSection]
        }

        return sections
    }

    private var categorizedReciterIDs: Set<String> {
        Set((
            recitersMinshawi +
            recitersMurattal +
            recitersMujawwad +
            recitersMuallim +
            recitersShubah +
            recitersKhalaf +
            recitersWarsh +
            recitersQaloon +
            recitersBuzzi +
            recitersQunbul +
            recitersDuri +
            recitersSusi +
            recitersHisham +
            recitersIbnDhakwan +
            recitersKhallad +
            recitersAbuHarith +
            recitersDuriKisai +
            recitersIbnWardan +
            recitersIbnJammaz +
            recitersRuways +
            recitersRawh +
            recitersIshaq +
            recitersIdris
        ).map(\.id))
    }

    private var uncategorizedReciterSection: ReciterSectionGroup? {
        let unmatched = filteredReciters(reciters)
            .filter { !categorizedReciterIDs.contains($0.id) }

        guard !unmatched.isEmpty else { return nil }
        return ReciterSectionGroup(
            id: "other-uncategorized",
            title: String(localized: "OTHER GROUP"),
            arabic: nil,
            reciters: unmatched,
            isQiraah: false
        )
    }

    private var allReciterSections: [ReciterSectionGroup] {
        primaryReciterSections + murattalGroupedSections.map { section in
            ReciterSectionGroup(id: section.id, title: section.title, arabic: nil, reciters: section.reciters, isQiraah: false)
        } + qiraahReciterSections
    }

    private var availableQiraahSections: [ReciterSectionGroup] {
        settings.showQiraahDetails ? qiraahReciterSections : []
    }

    private var searchResultTitle: String {
        isSearchingReciters ? String(localized: "SEARCH RESULTS") : ""
    }

    private var searchableReciterSections: [ReciterSectionGroup] {
        var sections = primaryReciterSections.filter { $0.id != "murattal" }

        sections += murattalGroupedSections.map { group in
            ReciterSectionGroup(id: group.id, title: group.title, arabic: nil, reciters: group.reciters, isQiraah: false)
        }

        sections.append(primaryReciterSections.first { $0.id == "murattal" } ?? ReciterSectionGroup(id: "murattal", title: String(localized: "NORMAL (MURATTAL)"), arabic: nil, reciters: [], isQiraah: false))
        sections += availableQiraahSections
        return sections.filter { !$0.reciters.isEmpty }
    }

    /// Memo for the three grouped-section derivations below. Each was a computed property re-run on every
    /// body pass - and the body reads `searchResultSections` three times per pass - while this view
    /// observes the download manager, whose progress publishes several times a second during a
    /// download: every tick regrouped every reciter. Keyed on the inputs the groupings read; the
    /// download state only enters the key while the "downloaded only" filter is on.
    private final class SectionMemo {
        var key = ""
        var search: [ReciterSectionGroup] = []
        var murattal: [MurattalReciterGroup] = []
        var qiraah: [QiraahSectionCluster] = []
    }
    @State private var sectionMemo = SectionMemo()

    private var sectionMemoKey: String {
        var parts = [
            searchText,
            settings.showQiraahDetails ? "1" : "0",
            settings.betaQiraatEnabled ? "1" : "0",
            settings.reciter,
            settings.reciterId,
            settings.displayQiraah,
            settings.favoriteReciterIDs.joined(separator: ","),
            "\(reciters.count)"
        ]
        #if os(iOS)
        parts.append(showDownloadedOnly ? "1" : "0")
        if showDownloadedOnly {
            parts.append(downloadManager.statesByReciterID.filter { $0.value.completedSurahs > 0 }.keys.sorted().joined(separator: ","))
        }
        #endif
        return parts.joined(separator: "|")
    }

    private func memoizedSections() -> SectionMemo {
        let key = sectionMemoKey
        if sectionMemo.key != key {
            sectionMemo.key = key
            sectionMemo.search = computeSearchResultSections()
            sectionMemo.murattal = computeMurattalGroupedSections()
            sectionMemo.qiraah = computeQiraahGroupedSections()
        }
        return sectionMemo
    }

    private var searchResultSections: [ReciterSectionGroup] { memoizedSections().search }
    private var murattalGroupedSections: [MurattalReciterGroup] { memoizedSections().murattal }
    private var qiraahGroupedSections: [QiraahSectionCluster] { memoizedSections().qiraah }

    private func computeSearchResultSections() -> [ReciterSectionGroup] {
        guard isSearchingReciters else { return [] }

        // The same RECORDING (one reciter id) can live in several browse sections - Minshawi (Murattal)
        // is in his featured section, the Classical Egyptian murattal group, AND the flat Murattal
        // section - and search used to show a row per section, which read as three different reciters
        // (user report). So search DEDUPES by reciter id and names every section the entry belongs to
        // in ONE combined header ("... / ..."). Genuinely different recordings (Mujawwad vs Murattal,
        // another riwayah, the 1387 AH archival mushaf) are distinct ids and keep their own rows.
        struct SearchEntry {
            let reciter: Reciter
            var sections: [ReciterSectionGroup]
        }
        var order: [String] = []
        var entries: [String: SearchEntry] = [:]

        func collect(_ matches: (ReciterSectionGroup) -> [Reciter]) {
            for section in searchableReciterSections {
                for reciter in matches(section) {
                    if entries[reciter.id] == nil {
                        entries[reciter.id] = SearchEntry(reciter: reciter, sections: [])
                        order.append(reciter.id)
                    }
                    if entries[reciter.id]?.sections.contains(where: { $0.id == section.id }) == false {
                        entries[reciter.id]?.sections.append(section)
                    }
                }
            }
        }

        collect { section in
            matchesSectionTitle(section, query: normalizedSearchText)
                ? section.reciters
                : section.reciters.filter { reciterMatchesSearch($0, query: normalizedSearchText) }
        }

        // Nothing spelled that way: ask again with the spelling folded ("ayoub", "ayyoub", "ayub"
        // are all Ayyub). Only ever a fallback, so a query that already works is untouched.
        if order.isEmpty {
            let everyone = searchableReciterSections.flatMap(\.reciters)
            let found = Set(SpellingFold.matches(searchText, in: everyone, entry: ReciterSpelling.entry).map(\.id))
            if !found.isEmpty {
                collect { section in section.reciters.filter { found.contains($0.id) } }
            }
        }

        // Reciters sharing the same section membership share one result section (first-appearance
        // order). A single-membership group keeps its original section verbatim - title, Arabic
        // riwayah header, qiraah styling; only multi-membership entries get a synthesized combined
        // header, joined in the sections' browse order.
        var result: [ReciterSectionGroup] = []
        var indexBySignature: [String: Int] = [:]

        for id in order {
            guard let entry = entries[id] else { continue }
            let signature = entry.sections.map(\.id).joined(separator: "|")
            if let idx = indexBySignature[signature] {
                result[idx] = result[idx].withReciters(result[idx].reciters + [entry.reciter])
                continue
            }
            indexBySignature[signature] = result.count
            if entry.sections.count == 1, let only = entry.sections.first {
                result.append(only.withReciters([entry.reciter]))
            } else {
                result.append(ReciterSectionGroup(
                    id: "search-combined-\(signature)",
                    title: entry.sections.map(\.title).joined(separator: " / "),
                    arabic: nil,
                    reciters: [entry.reciter],
                    isQiraah: entry.sections.allSatisfy(\.isQiraah)
                ))
            }
        }
        return result
    }

    private var searchResultCount: Int {
        searchResultSections.reduce(0) { $0 + $1.reciters.count }
    }

    private func requestScrollToReciter(_ reciter: Reciter) {
        withAnimation {
            searchText = ""
            pendingScrollToReciterID = reciter.id
            endEditing()
        }
    }

    private var murattalRecitersFiltered: [Reciter] {
        filteredReciters(recitersMurattal, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries)
    }

    private func computeMurattalGroupedSections() -> [MurattalReciterGroup] {
        var groups: [MurattalReciterGroup] = []

        let all = murattalRecitersFiltered

        func matches(_ reciter: Reciter, containsAny values: [String]) -> Bool {
            let n = normalized(reciter.name)
            return values.contains { n.contains($0) }
        }

        func group(id: String, title: String, subtitle: String, containsAny values: [String]) -> [Reciter] {
            all.filter { reciter in matches(reciter, containsAny: values) }
        }

        let haramain = group(
            id: "haramain",
            title: "HARAMAIN (MAKKAH & MADINAH)",
            subtitle: "Most recognized globally",
            containsAny: [
                "abdul rahman al-sudais",
                "saud al-shuraim",
                "maher al-muaiqly",
                "abdullah al-juhany",
                "bandar baleela",
                "yasser al-dosari",
                "badr al-turki"
            ]
        )

        let classicalEgyptian = group(
            id: "classical-egypt",
            title: "CLASSICAL EGYPTIAN SCHOOL",
            subtitle: "Deep tajweed and slower murattal",
            containsAny: [
                "abdul basit",
                "mahmoud al-hussary",
                "muhammad al-minshawi",
                "mustafa ismail",
                "mahmoud ali al-banna"
            ]
        )

        let contemporary = group(
            id: "contemporary",
            title: "FAMOUS CONTEMPORARY RECITERS",
            subtitle: "Well-known and widely listened to",
            containsAny: [
                "mishary alafasy",
                "ahmad al-ajmy",
                "saad al-ghamdi",
                "hani al-rifai",
                "abu bakr al-shatri",
                "muhammad al-luhaidan",
                "hazza al-balushi",
                "ahmad al-nufais",
            ]
        )

        let classicHaramain = group(
            id: "classic-haramain",
            title: "CLASSIC HARAMAIN & OLDER IMAMS",
            subtitle: "Older but iconic voices",
            containsAny: [
                "ali jaber",
                "muhammad ayyub"
            ]
        )

        let usedIDs = Set((haramain + classicalEgyptian + contemporary + classicHaramain).map(\.id))
        let other = all.filter { !usedIDs.contains($0.id) }

        if !haramain.isEmpty {
            groups.append(.init(id: "haramain", title: String(localized: "HARAMAIN (MAKKAH & MADINAH)"), subtitle: String(localized: "Most recognized globally"), reciters: haramain))
        }
        if !classicalEgyptian.isEmpty {
            groups.append(.init(id: "classical-egypt", title: String(localized: "CLASSICAL EGYPTIAN SCHOOL"), subtitle: String(localized: "Deep tajweed and slower murattal"), reciters: classicalEgyptian))
        }
        if !contemporary.isEmpty {
            groups.append(.init(id: "contemporary", title: String(localized: "FAMOUS CONTEMPORARY RECITERS"), subtitle: String(localized: "Well-known and widely listened to"), reciters: contemporary))
        }
        if !classicHaramain.isEmpty {
            groups.append(.init(id: "classic-haramain", title: String(localized: "CLASSIC HARAMAIN & OLDER IMAMS"), subtitle: String(localized: "Older but iconic voices"), reciters: classicHaramain))
        }
        if !other.isEmpty {
            groups.append(.init(id: "other", title: String(localized: "OTHER RECITERS"), subtitle: String(localized: "Less mainstream or distinct styles"), reciters: other))
        }

        return groups
    }

    private var searchableQiraahSections: [ReciterSectionGroup] {
        qiraahReciterSections.filter { !$0.reciters.isEmpty }
    }

    /// Riwayah section id -> `Settings.Riwayah` tag, so each riwayah section can be grouped under
    /// its qiraah imam (`Option.teacher`). Ids match `qiraahReciterSections`.
    private static let riwayahTagBySectionID: [String: String] = [
        "shubah": Settings.Riwayah.shubah,
        "khalaf": Settings.Riwayah.khalaf,
        "warsh": Settings.Riwayah.warsh,
        "qaloon": Settings.Riwayah.qaloon,
        "buzzi": Settings.Riwayah.buzzi,
        "qunbul": Settings.Riwayah.qunbul,
        "duri": Settings.Riwayah.duri,
        "susi": Settings.Riwayah.susi,
        "hisham": Settings.Riwayah.hisham,
        "ibnDhakwan": Settings.Riwayah.ibnDhakwan,
        "khallad": Settings.Riwayah.khallad,
        "abuHarith": Settings.Riwayah.abuHarith,
        "duriKisai": Settings.Riwayah.duriKisai,
        "ibnWardan": Settings.Riwayah.ibnWardan,
        "ibnJammaz": Settings.Riwayah.ibnJammaz,
        "ruways": Settings.Riwayah.ruways,
        "rawh": Settings.Riwayah.rawh,
        "ishaq": Settings.Riwayah.ishaq,
        "idris": Settings.Riwayah.idris
    ]

    /// One qiraah imam and the riwayah sections (each with its reciters) the list has for him.
    /// `teacher == nil` is the catch-all bucket (OTHER GROUP), which has no qiraah-level header.
    private struct QiraahSectionCluster: Identifiable {
        let id: String
        let teacher: String?
        let teacherArabic: String?
        var sections: [ReciterSectionGroup]
    }

    /// The qiraat area regrouped two-level: riwayah sections clustered under their qiraah imam,
    /// in the sections' existing order (imams ordered by first appearance, so the visible reciter
    /// order is exactly what the flat list showed).
    private func computeQiraahGroupedSections() -> [QiraahSectionCluster] {
        var clusters: [QiraahSectionCluster] = []
        var indexByTeacher: [String: Int] = [:]

        for section in searchableQiraahSections {
            if section.isQiraah,
               let tag = Self.riwayahTagBySectionID[section.id],
               let option = Settings.Riwayah.allOptions.first(where: { $0.tag == tag }) {
                if let index = indexByTeacher[option.teacher] {
                    clusters[index].sections.append(section)
                } else {
                    indexByTeacher[option.teacher] = clusters.count
                    clusters.append(QiraahSectionCluster(
                        id: "qiraah-group-\(option.teacher)",
                        teacher: option.teacher,
                        teacherArabic: option.teacherArabic,
                        sections: [section]
                    ))
                }
            } else {
                clusters.append(QiraahSectionCluster(id: "qiraah-group-\(section.id)", teacher: nil, teacherArabic: nil, sections: [section]))
            }
        }

        return clusters
    }

    /// The qiraat reciter list, grouped by qiraah: each imam's first riwayah section carries the
    /// qiraah-level header (name + riwayat-count pill) stacked above its own riwayah header, so
    /// the sections, row identities, and scroll targets stay exactly as the flat list had them.
    @ViewBuilder
    private var qiraahGroupedReciterSections: some View {
        ForEach(qiraahGroupedSections) { cluster in
            ForEach(Array(cluster.sections.enumerated()), id: \.element.id) { index, section in
                if section.isQiraah {
                    Section(header: VStack(alignment: .leading, spacing: 10) {
                        if index == 0, let teacher = cluster.teacher {
                            QiraahGroupSectionHeader(
                                teacher: teacher,
                                teacherArabic: cluster.teacherArabic ?? "",
                                riwayahCount: cluster.sections.count
                            )
                        }

                        QiraahReciterSectionHeader(title: section.title, arabic: section.arabic ?? "", count: section.reciters.count)
                    }, footer: Group {
                        // Hafs stays at the top of the list in its own style sections rather than
                        // under this Asim header - this footer is what says so.
                        if section.id == "shubah" {
                            Text("All reciters above are Hafs an 'Asim (default).")
                        }
                    }) {
                        reciterButtons(section.reciters, qiraah: true)
                    }
                    .id("search-qiraah-\(section.id)")
                } else {
                    reciterSection(section)
                }
            }
        }
    }

    private func searchResultsBanner() -> some View {
        HStack(spacing: 10) {
            Text(searchResultTitle)

            Spacer()

            Text("\(searchResultCount)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private var noSearchResultsView: some View {
        Text("No reciters matched your search.")
            .foregroundStyle(.secondary)
    }

    private var reciterSearchControlsInset: some View {
        #if os(iOS)
        SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #else
        EmptyView()
        #endif
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isGeneralQiraahSearch(_ query: String) -> Bool {
        Self.qiraahSearchKeywords.contains { query.contains($0) }
    }

    private func isGeneralHafsSearch(_ query: String) -> Bool {
        Self.hafsSearchKeywords.contains { query.contains($0) }
    }

    private func matchesSectionTitle(_ section: ReciterSectionGroup, query: String) -> Bool {
        guard !query.isEmpty else { return false }
        return normalized(section.title).contains(query)
            || normalized(section.arabic ?? "").contains(query)
    }

    private func reciterMatchesSearch(_ reciter: Reciter, query: String) -> Bool {
        guard !query.isEmpty else { return false }
        if normalized(reciter.name).contains(query) { return true }
        // The other names he is known and searched by (see `ReciterSpelling`).
        return ReciterSpelling.otherNames(for: reciter).contains { normalized($0).contains(query) }
    }

    /// Entry point for a reciter tap. A reciter with no ayah feed (ayahs fall back to Minshawi) is
    /// explained ONCE, here at selection time - never again while playing. Everything else applies
    /// immediately.
    private func handleReciterTap(_ reciter: Reciter) {
        if QuranPlayer.shared.needsMinshawiFallbackNotice(for: reciter) {
            pendingMinshawiReciter = reciter
        } else if reciter.ayahMurattalStyleNote != nil {
            // Mujawwad/Muallim variant with no true per-ayah recording in that style - confirm the ayah
            // audio will be this reciter's own Murattal.
            pendingMurattalStyleReciter = reciter
        } else {
            applyReciterSelection(reciter)
        }
    }

    private func applyReciterSelection(_ reciter: Reciter) {
        withAnimation {
            let selectedImmediately = selectReciter(reciter)
            if selectedImmediately && dismissAfterSelectingReciter {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    @discardableResult
    private func selectReciter(_ reciter: Reciter) -> Bool {
        settings.setSelectedReciter(reciter)

        let targetQiraahTag = resolvedQiraahTag(for: reciter)
        if !isSupportedQiraahForText(targetQiraahTag) {
            pendingQiraahReciter = reciter
            pendingDisplayQiraahTag = targetQiraahTag
            return false
        }

        if settings.displayQiraahForArabic != targetQiraahTag {
            pendingQiraahReciter = reciter
            pendingDisplayQiraahTag = targetQiraahTag
            return false
        }

        pendingQiraahReciter = nil
        pendingDisplayQiraahTag = nil
        return true
    }

    private func confirmPendingQiraahSelection() {
        guard pendingQiraahReciter != nil else { return }

        if pendingRequestedQiraahIsUnsupported {
            self.pendingQiraahReciter = nil
            self.pendingDisplayQiraahTag = nil

            if dismissAfterSelectingReciter {
                presentationMode.wrappedValue.dismiss()
            }
            return
        }

        settings.displayQiraah = pendingDisplayQiraahTag ?? Settings.Riwayah.hafsTag
        self.pendingQiraahReciter = nil
        self.pendingDisplayQiraahTag = nil

        if dismissAfterSelectingReciter {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func declinePendingQiraahSelection() {
        pendingQiraahReciter = nil
        pendingDisplayQiraahTag = nil

        if dismissAfterSelectingReciter {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func hideQiraahDetails() {
        if settings.isHafsDisplay {
            withAnimation(.easeInOut) {
                settings.showQiraahDetails = false
            }
        } else {
            settings.showQiraahDetails = true
            confirmHideQiraahDetails = true
        }
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
                Group {
                #if os(iOS)
                Section {
                    reciterTypeLegend
                }
                #endif
                if isSearchingReciters {
                    searchResultsBanner()

                    if searchResultSections.isEmpty {
                        noSearchResultsView
                    } else {
                        ForEach(searchResultSections) { section in
                            reciterSection(section)
                        }
                    }
                } else {
                    if !favoriteReciters.isEmpty {
                        Section(header: Text("FAVORITES")) {
                            // Prefixed like the featured Minshawi rows: a favorite is ALSO listed in its
                            // own section further down, and two rows sharing one view id is what made
                            // `scrollTo` unreliable for a favorited reciter.
                            reciterButtons(favoriteReciters, idPrefix: Self.favoriteRowIDPrefix)
                        }
                    }

                    Section {
                        randomReciterButton
                    }

                    #if os(iOS)
                    Section(header: Text("DOWNLOADED SURAHS")) {
                        Picker("Reciter Filter", selection: $showDownloadedOnly) {
                            Text("All Reciters").tag(false)
                            Text("Downloaded Only").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: showDownloadedOnly) { _ in settings.hapticFeedback() }

                        VStack(alignment: .leading, spacing: 10) {
                            Text(String(localized: "Downloads are full-reciter packages (all 114 surahs).").localizedDigits)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(.vertical, 2)

                            Text("Ayah download is not supported, only surah download.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 2)
                        }

                        let downloadedCount = uniqueDownloadedReciterCount
                        Text("Downloaded reciters: \(downloadedCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)

                        if downloadedCount > 0 {
                            Button(role: .destructive) {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    downloadManager.deleteAllDownloads()
                                }
                            } label: {
                                Label("Delete All Downloads", systemImage: "trash.fill")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.red)
                                    .tint(.red)
                            }
                            .buttonStyle(.borderless)
                            .font(.caption.weight(.semibold))
                        }
                    }
                    #endif

                    if !filteredReciters(recitersMinshawi).isEmpty {
                        Section(header: Text("MUHAMMAD SIDDIQ AL-MINSHAWI")) {
                            // Prefixed ids: these same reciters also appear in their style sections below, so
                            // the featured copies must carry distinct view identities.
                            reciterButtons(filteredReciters(recitersMinshawi), idPrefix: "featured-minshawi")
                        }
                    }
                    
                    if !filteredReciters(recitersMujawwad, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries).isEmpty {
                        Section(header: Text("SLOW & MELODIC (MUJAWWAD)")) {
                            reciterButtons(filteredReciters(recitersMujawwad, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries))
                        }
                    }

                    if !filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries).isEmpty {
                        Section(header: Text("TEACHING (MUALLIM)")) {
                            reciterButtons(filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries))
                        }
                    }

                    if !murattalRecitersFiltered.isEmpty {
                        Section {
                            Button {
                                settings.hapticFeedback()
                                withAnimation {
                                    splitMurattalRecitersByGroup.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(splitMurattalRecitersByGroup ? String(localized: "Show Murattal as One Section") : String(localized: "Group Murattal Reciters"))

                                    Spacer()

                                    Image(systemName: splitMurattalRecitersByGroup ? "rectangle.grid.1x2" : "square.grid.2x2")
                                }
                                .foregroundColor(settings.accentColor.color)
                            }
                        }

                        if splitMurattalRecitersByGroup {
                            ForEach(murattalGroupedSections) { group in
                                Section(header: MurattalSectionHeader(title: group.title, subtitle: group.subtitle)) {
                                    reciterButtons(group.reciters)
                                }
                            }
                        } else {
                            Section(header: Text("NORMAL (MURATTAL)")) {
                                reciterButtons(murattalRecitersFiltered)
                            }
                        }
                    }
                    
                    #if os(iOS)
                    if !showDownloadedOnly {
                        if settings.showQiraahDetails {
                            Section {
                                Button {
                                    settings.hapticFeedback()
                                    hideQiraahDetails()
                                } label: {
                                    HStack {
                                        Label("Hide Other Qiraat Reciters", systemImage: "character.book.closed.fill.ar")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.up")
                                    }
                                    .foregroundColor(settings.accentColor.color)
                                }
                            }
                            
                            Section(header: Text("ABOUT QIRAAT"), footer: Text("Play Ayahs is unsupported for other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")) {
                                Text("""
                                The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the Muslims. From these, the 10 Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

                                The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

                                To learn more about the 7 Ahruf and the 10 Qiraat, see below and in Al-Islam View > Islamic Pillars and Basics.
                                """)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                                NavigationLink(destination: LazyDestination { AhrufView() }) {
                                    Text("The 7 Ahruf (Modes)")
                                }
                                .font(.subheadline)

                                NavigationLink(destination: LazyDestination { QiraatView() }) {
                                    Text("The 10 Qiraat (Recitations)")
                                }
                                .font(.subheadline)

                                Text("**All recitations above are *Hafs an Asim*, the most common and widespread Qiraah in the world today.**")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .padding(.top, 4)
                                
                                Text("All reciters below are available only for full surahs. Play Ayahs is unsupported for other qiraat.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            
                            qiraahGroupedReciterSections
                        } else {
                            Section {
                                Button {
                                    settings.hapticFeedback()
                                    withAnimation(.easeInOut) {
                                        settings.showQiraahDetails = true
                                    }
                                } label: {
                                    HStack {
                                        Label("Show Other Qiraat Reciters", systemImage: "character.book.closed.fill.ar")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                    }
                                    .foregroundColor(settings.accentColor.color)
                                }
                            }
                        }
                    }
                    #else
                    if settings.showQiraahDetails {
                        Section {
                            Button {
                                settings.hapticFeedback()
                                hideQiraahDetails()
                            } label: {
                                HStack {
                                    Label("Hide Other Qiraat Reciters", systemImage: "character.book.closed.fill.ar")
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up")
                                }
                                .foregroundColor(settings.accentColor.color)
                            }
                        }
                        
                        Section(header: Text("ABOUT QIRAAT"), footer: Text("Play Ayahs is unsupported for other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")) {
                            Text("""
                            The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the Muslims. From these, the 10 Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

                            The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

                            To learn more about the 7 Ahruf and the 10 Qiraat, see below and in Al-Islam View > Islamic Pillars and Basics.
                            """)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                            NavigationLink(destination: LazyDestination { AhrufView() }) {
                                Text("The 7 Ahruf (Modes)")
                            }
                            .font(.subheadline)

                            NavigationLink(destination: LazyDestination { QiraatView() }) {
                                Text("The 10 Qiraat (Recitations)")
                            }
                            .font(.subheadline)

                            Text("**All recitations above are *Hafs an Asim*, the most common and widespread Qiraah in the world today.**")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.top, 4)

                            Text("All reciters below are available only for full surahs. Play Ayahs is unsupported for other qiraat.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        
                        qiraahGroupedReciterSections
                    } else {
                        Section {
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    settings.showQiraahDetails = true
                                }
                            } label: {
                                HStack {
                                    Label("Show Other Qiraat Reciters", systemImage: "character.book.closed.fill.ar")
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                }
                                .foregroundColor(settings.accentColor.color)
                            }
                        }
                    }
            #endif
                }
            }
            .themedListRowBackground()
        }
            .navigationTitle("Select Reciter")
            #if os(iOS)
            // Applied BEFORE the bottom bar below it: bottom safe-area insets stack outward, so the inset
            // added first sits nearest the content and later ones go underneath it. With the bar first, the
            // Now Playing player landed UNDER it (Abu, 2026-10-07). The Quran tab's order is the same.
            .applyConditionalListStyle()
            .adaptiveSafeArea(edge: .bottom) {
                reciterSearchControlsInset
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .background(Color.white.opacity(0.00001))
            }
            #elseif os(watchOS)
            .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
            #endif
            #if os(watchOS)
            // The watch has no floating bottom bar to order against, so it is styled here.
            .applyConditionalListStyle()
            #endif
            .confirmationDialog(qiraahChangeDialogTitle, isPresented: Binding(
                get: { pendingQiraahReciter != nil },
                set: {
                    if !$0 {
                        pendingQiraahReciter = nil
                        pendingDisplayQiraahTag = nil
                    }
                }
            ), titleVisibility: .visible) {
                Button(pendingRequestedQiraahIsUnsupported ? String(localized: "Yes, Keep Current Quran Text") : String(localized: "Confirm and Change")) {
                    settings.hapticFeedback()
                    confirmPendingQiraahSelection()
                }

                Button(pendingRequestedQiraahIsUnsupported ? String(localized: "Cancel Selection") : String(localized: "No, Don't Change Qiraah")) {
                    settings.hapticFeedback()
                    declinePendingQiraahSelection()
                }
            } message: {
                Text(qiraahChangeDialogMessage)
            }
            .confirmationDialog("Ayahs Will Use Minshawi (Murattal)", isPresented: Binding(
                get: { pendingMinshawiReciter != nil },
                set: { if !$0 { pendingMinshawiReciter = nil } }
            ), titleVisibility: .visible) {
                Button("Select This Reciter") {
                    settings.hapticFeedback()
                    if let reciter = pendingMinshawiReciter {
                        pendingMinshawiReciter = nil
                        // Recorded on CONFIRM only - a cancelled pick must ask again next time.
                        QuranPlayer.shared.confirmMinshawiFallbackNotice(for: reciter)
                        applyReciterSelection(reciter)
                    }
                }

                Button("Cancel") {
                    pendingMinshawiReciter = nil
                }
            } message: {
                Text(QuranPlayer.shared.minshawiFallbackNoticeMessage(for: pendingMinshawiReciter))
            }
            .confirmationDialog("Ayahs Play in Murattal", isPresented: Binding(
                get: { pendingMurattalStyleReciter != nil },
                set: { if !$0 { pendingMurattalStyleReciter = nil } }
            ), titleVisibility: .visible) {
                Button("Select This Reciter") {
                    settings.hapticFeedback()
                    if let reciter = pendingMurattalStyleReciter {
                        pendingMurattalStyleReciter = nil
                        applyReciterSelection(reciter)
                    }
                }

                Button("Cancel") {
                    pendingMurattalStyleReciter = nil
                }
            } message: {
                Text("\(pendingMurattalStyleReciter?.name ?? String(localized: "This reciter")) has no separate ayah-by-ayah recording in this style, so individual ayahs and custom ranges will play in \(pendingMurattalStyleReciter?.ayahMurattalStyleNote ?? String(localized: "Murattal")). Full-surah playback is unaffected.")
            }
            .confirmationDialog("Convert Qiraah to Hafs an Asim?", isPresented: $confirmHideQiraahDetails, titleVisibility: .visible) {
                Button("Yes") {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.displayQiraah = Settings.Riwayah.hafsTag
                        settings.showQiraahDetails = false
                    }
                }

                Button("No") {
                    settings.hapticFeedback()
                    settings.showQiraahDetails = true
                }
            } message: {
                Text("Are you sure? This will convert the qiraah back to Hafs an Asim.")
            }
            .onChange(of: pendingScrollToReciterID) { id in
                guard let id else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        scrollProxy.scrollTo(id, anchor: .top)
                        pendingScrollToReciterID = nil
                    }
                }
            }
            .onAppear {
                settings.migrateLegacyReciterIdIfNeeded()

                _ = withAnimation {
                    settings.revertToDefaultReciterIfMissing()
                }

                #if os(iOS)
                downloadManager.ensureStatesLoaded(for: reciters)
                downloadManager.purgeIncompleteReciterDownloads()
                #endif

                if autoScrollToInitialSelection && !didAutoScrollToSelection {
                    let target = reciterListScrollTargetID
                    didAutoScrollToSelection = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollProxy.scrollTo(target, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private func filteredReciters(_ list: [Reciter], excludingFeaturedMinshawi: Bool = false) -> [Reciter] {
        let baseList = excludingFeaturedMinshawi
            ? list.filter { !recitersMinshawi.contains($0) }
            : list

        #if os(iOS)
        guard showDownloadedOnly else { return baseList }
        return baseList.filter { downloadManager.stateSnapshot(for: $0).completedSurahs > 0 }
        #else
        return baseList
        #endif
    }

    #if os(iOS)
    private var uniqueDownloadedReciterCount: Int {
        var seen = Set<String>()
        return reciters.reduce(into: 0) { count, reciter in
            guard downloadManager.stateSnapshot(for: reciter).completedSurahs > 0 else { return }
            guard seen.insert(reciter.id).inserted else { return }
            count += 1
        }
    }

    private var shouldHideDuplicateMinshawiEntries: Bool {
        // Minshawi is shown BOTH in his own featured section AND in the Mujawwad/Muallim/Murattal style
        // section his variant belongs to (each variant naturally lives in exactly one style section). The
        // featured section's rows carry a section-prefixed view id (see `reciterButtons(idPrefix:)`) so the
        // two copies never collide in the List; selection/favorites stay keyed on the bare reciter id, so
        // toggling either instance lights up both.
        false
    }
    #else
    private var shouldHideDuplicateMinshawiEntries: Bool {
        false
    }
    #endif

    /// A reciter tagged with a section-scoped view id. Minshawi appears in his own featured section AND in
    /// his style section, so the two copies must carry distinct SwiftUI identities (`idPrefix`) even though
    /// they wrap the same `Reciter` (selection/favorites stay keyed on the bare `reciter.id`).
    private struct KeyedReciterRow: Identifiable {
        let id: String
        let reciter: Reciter
    }

    @ViewBuilder
    private func reciterButtons(_ list: [Reciter], qiraah: Bool = false, idPrefix: String = "") -> some View {
        ForEach(list.map { KeyedReciterRow(id: idPrefix.isEmpty ? $0.id : "\(idPrefix)|\($0.id)", reciter: $0) }) { item in
            reciterRow(item.reciter, qiraah: qiraah)
                .id(item.id)
        }
    }

    @ViewBuilder
    private func reciterSection(_ section: ReciterSectionGroup) -> some View {
        if section.isQiraah {
            Section(header: QiraahReciterSectionHeader(title: section.title, arabic: section.arabic ?? "", count: section.reciters.count)) {
                reciterButtons(section.reciters, qiraah: true)
            }
            .id("search-qiraah-\(section.id)")
        } else {
            Section(header: Text(section.title)) {
                // The featured Minshawi section's rows are prefixed so they never collide with the same
                // reciters shown in their style sections.
                reciterButtons(section.reciters, idPrefix: section.id == "minshawi" ? "featured-minshawi" : "")
            }
        }
    }

    private var randomReciterButton: some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                settings.setRandomReciterMode()
            }
            #if os(watchOS)
            presentationMode.wrappedValue.dismiss()
            #elseif os(iOS)
            if dismissAfterSelectingReciter {
                presentationMode.wrappedValue.dismiss()
            }
            #endif
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Label(Settings.randomReciterName, systemImage: "shuffle")
                        .foregroundColor(settings.reciter == Settings.randomReciterName ? settings.accentColor.color : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(settings.accentColor.color)
                        .opacity(settings.reciter == Settings.randomReciterName ? 1 : 0)
                }
                .font(.subheadline)
                .padding(.vertical, 4)
                
                Text("A new reciter is chosen at random for every session.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }
        }
        .id(Settings.randomReciterName)
    }

    @ViewBuilder
    private func reciterRow(_ reciter: Reciter, qiraah: Bool) -> some View {
        #if os(iOS)
        ReciterRow(
            reciter: reciter,
            qiraah: qiraah,
            isFavorite: settings.isReciterFavorite(reciterID: reciter.id),
            isSelected: isSelectedReciter(reciter),
            downloadState: downloadManager.stateSnapshot(for: reciter),
            accentColor: settings.accentColor,
            searchQuery: searchText,
            onSelect: {
                settings.hapticFeedback()
                handleReciterTap(reciter)
            },
            onScrollToReciter: {
                settings.hapticFeedback()
                requestScrollToReciter(reciter)
            }
        )
        .equatable()
        #else
        WatchReciterRow(
            reciter: reciter,
            qiraah: qiraah,
            isSelected: isSelectedReciter(reciter),
            accentColor: settings.accentColor,
            onSelect: {
                settings.hapticFeedback()
                withAnimation {
                    let selectedImmediately = selectReciter(reciter)
                    if selectedImmediately {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            },
            onToggleFavorite: {
                settings.hapticFeedback()
                settings.toggleReciterFavorite(reciterID: reciter.id)
            }
        )
        #endif
    }
}

#if os(iOS)
private struct ReciterRow: View, Equatable {
    // Plain references, NOT @ObservedObject: every value this row RENDERS arrives as an input (the
    // `downloadState` snapshot included), and the manager/settings are only touched from tap actions.
    // Observing the manager here meant every progress byte-tick re-rendered every visible row - the
    // Equatable snapshot the parent already passes couldn't skip anything.
    private var settings: Settings { .shared }
    private var downloadManager: ReciterDownloadManager { .shared }

    let reciter: Reciter
    let qiraah: Bool
    let isFavorite: Bool
    let isSelected: Bool
    let downloadState: ReciterDownloadManager.DownloadState
    let accentColor: AccentColor
    /// Compared alongside `accentColor`: for the `.custom` accent, `.color` resolves through this hex,
    /// so an edit to it must fail `==` - this row observes nothing, and comparing only the enum case
    /// left visible rows on the old tint until they scrolled off.
    var customAccentHex: String = Settings.shared.customAccentColorHex
    let searchQuery: String
    let onSelect: () -> Void
    let onScrollToReciter: () -> Void

    @State private var confirmDownload = false
    /// The two dot explanations. Separate flags so tapping one dot never opens the other's dialog.
    @State private var showTypeDotInfo = false
    @State private var showCoverageDotInfo = false

    /// The closures are recreated per parent pass; identity lives in the value inputs. This is what
    /// lets the one row whose snapshot changed re-render while the rest skip their bodies.
    static func == (lhs: ReciterRow, rhs: ReciterRow) -> Bool {
        lhs.reciter.id == rhs.reciter.id
            && lhs.qiraah == rhs.qiraah
            && lhs.isFavorite == rhs.isFavorite
            && lhs.isSelected == rhs.isSelected
            && lhs.downloadState == rhs.downloadState
            && lhs.accentColor == rhs.accentColor
            && lhs.customAccentHex == rhs.customAccentHex
            && lhs.searchQuery == rhs.searchQuery
    }

    /// RECITER-LIST-ONLY display name (user rule: nowhere else - Now Playing, settings rows, and every
    /// other surface keep the bare name). The standard Murattal is both the app's default reciter and
    /// mp3quran's plain "minsh" mushaf - the complete 1381 AH Egyptian-radio murattal-project recording -
    /// so the list marks it apart from the archival "(1387 AH)" sibling entry.
    private var listDisplayName: String {
        reciter.name == Reciter.minshawiAyahFallbackName
            ? String(localized: "\(reciter.name) (Default - 1381 AH)")
            : reciter.name
    }

    var body: some View {
        let hasDownloads = downloadState.completedSurahs > 0
        let isDownloading = downloadState.isDownloading
        let overallProgress = min(
            max((Double(downloadState.completedSurahs) + downloadState.currentSurahProgress) / Double(max(downloadState.totalSurahs, 1)), 0),
            1
        )

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.body.weight(.semibold))
                    .foregroundColor(accentColor.color)
                    .onTapGesture {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.toggleReciterFavorite(reciterID: reciter.id)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        // The type dot the top-of-list legend explains - it replaced the caption note
                        // each row used to carry. Tapping it explains THIS row's dot, so the meaning
                        // is reachable from the reciter you are actually looking at rather than only
                        // from the legend at the top of a 97-row list.
                        if !qiraah {
                            dotButton(color: reciterTypeDotColor) { showTypeDotInfo = true }
                        }

                        // Incomplete coverage is orthogonal to the playback-tier dot, so it gets its
                        // own purple dot - shown in qiraah sections too, where the tier dot is hidden.
                        if reciter.carriedSurahCount < 114 {
                            dotButton(color: .purple) { showCoverageDotInfo = true }
                        }

                        HighlightedSnippet(
                            source: listDisplayName,
                            term: searchQuery,
                            font: .subheadline,
                            accent: accentColor.color,
                            fg: isSelected ? accentColor.color : .primary
                        )
                            .multilineTextAlignment(.leading)
                    }

                    if isDownloading {
                        ProgressView(value: overallProgress)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)

                VStack(alignment: .trailing, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(accentColor.color)
                            .opacity(isSelected ? 1 : 0)

                        if isDownloading {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    withAnimation {
                                        downloadManager.cancelDownload(for: reciter)
                                        downloadManager.deleteDownloads(for: reciter)
                                    }
                                }
                        } else if hasDownloads {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.red)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    withAnimation {
                                        downloadManager.deleteDownloads(for: reciter)
                                    }
                                }
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.secondary)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    confirmDownload = true
                                }
                        }
                    }
                }
                .padding(.top, 4)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            .swipeActions(edge: .trailing) {
                Button {
                    onScrollToReciter()
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .tint(.secondary)
            }
            .contextMenu {
                Text("Reciter Actions")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = reciter.displayNameWithEnglishQiraah
                } label: {
                    Label("Copy Name", systemImage: "doc.on.doc")
                }

                Button {
                    onScrollToReciter()
                } label: {
                    Label("Scroll to Reciter", systemImage: "arrow.down.circle")
                }
            }

            if isDownloading {
                Text("Downloading surah \(downloadState.currentSurahNumber ?? max(downloadState.completedSurahs + 1, 1)) of \(downloadState.totalSurahs) (\(Int(overallProgress * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }

            if hasDownloads {
                Text("Storage used: \(downloadManager.storageText(bytes: downloadState.totalBytes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }

            if let errorMessage = downloadState.errorMessage, !errorMessage.isEmpty {
                Text("Download error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 2)
            }
        }
        .confirmationDialog("Download \(reciter.name)?", isPresented: $confirmDownload, titleVisibility: .visible) {
            Button("Download All \(reciter.carriedSurahCount) Surahs") {
                settings.hapticFeedback()
                withAnimation {
                    downloadManager.beginDownloadAll(for: reciter)
                }
            }

            Button("Cancel") {}
        } message: {
            Text(reciter.supportsAyahSegments
                ? String(localized: "This downloads all \(reciter.carriedSurahCount) full-surah recitations for offline playback. This reciter also supports ayah segments, so individual ayahs and custom ranges then play offline too, cut from the downloaded surah. It runs in the background and may use significant data and storage.")
                : String(localized: "This downloads all \(reciter.carriedSurahCount) full-surah recitations for offline playback; it does not download ayah-by-ayah audio. It runs in the background and may use significant data and storage."))
        }
        .confirmationDialog("Reciter Type", isPresented: $showTypeDotInfo, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text(typeDotExplanation)
        }
        .confirmationDialog("Incomplete Mushaf", isPresented: $showCoverageDotInfo, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text(coverageDotExplanation.localizedDigits)
        }
        .onAppear {
            downloadManager.ensureStateLoaded(for: reciter)
        }
    }

    /// A legend dot, tappable, with a hit area big enough to actually hit. The dot itself stays 8pt
    /// (the legend's size); the padding around it is what the finger lands on, and `.contentShape`
    /// makes that padding count. Without it a bare 8pt Circle is a coin-toss to tap.
    private func dotButton(color: Color, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The row itself selects the reciter; without this the tap would do both.
        .accessibilityLabel("What this dot means")
    }

    /// What THIS row's playback-tier dot means, in the legend's own words.
    private var typeDotExplanation: String {
        if reciter.defaultToMinshawi {
            return String(localized: "Red: full surahs only. Individual ayahs and custom ranges play in Minshawi (Murattal) instead of this reciter's voice.")
        }
        if let style = reciter.ayahMurattalStyleNote {
            return reciter.supportsAyahSegments
                ? String(localized: "Orange: streamed ayahs play in \(style). Download a surah and its ayahs play in this reciter's own voice, cut from the downloaded file.")
                : String(localized: "Orange: individual ayahs and custom ranges play in \(style), not in this reciter's own voice.")
        }
        if reciter.supportsAyahSegments {
            return String(localized: "Blue: the highest tier. Full surahs and individual ayahs play in this reciter's own voice, and once a surah is downloaded its ayahs play offline too.")
        }
        return String(localized: "Green: individual ayahs play in this reciter's own voice while streaming.")
    }

    /// What the purple dot means for THIS reciter, naming the surahs it actually carries.
    private var coverageDotExplanation: String {
        let carried = reciter.carriedSurahCount
        return String(localized: "Purple: incomplete. This reciter has recorded \(carried) of the 114 surahs.\n\nSupports surahs \(reciter.carriedSurahRangesDescription.localizedDigits).")
    }

    /// The legend color for this reciter's ayah-playback type: blue = the highest tier (surahs AND
    /// own-voice ayahs AND offline ayah segments once downloaded), green = own-voice streamed ayahs,
    /// orange = ayahs substitute a Murattal style, red = surahs only (ayahs default to Minshawi).
    private var reciterTypeDotColor: Color {
        if reciter.defaultToMinshawi { return .red }
        if reciter.ayahMurattalStyleNote != nil { return .orange }
        if reciter.supportsAyahSegments { return .blue }
        return .green
    }

    /// The one-line caption under the reciter name explaining how it plays INDIVIDUAL ayahs (segments vs.
    /// a substitute Murattal). Ordered most-specific first. (Replaced in the row by the legend dot;
    /// kept for reference.)
    @ViewBuilder
    private var reciterAyahSupportNote: some View {
        if reciter.defaultToMinshawi {
            reciterNoteText(String(localized: "This reciter supports surahs only. Ayahs default to Minshawi (Murattal)."))
        } else if let style = reciter.ayahMurattalStyleNote {
            if reciter.supportsAyahSegments {
                // Segments, but no own streamed ayahs: the whole surah must be downloaded to hear an ayah
                // in this reciter's own voice.
                reciterNoteText(String(localized: "Streamed ayahs play in \(style). Download the surah to hear ayahs in this reciter's own voice, cut as offline ayah segments."))
            } else {
                reciterNoteText(String(localized: "Individual ayahs and custom ranges play in \(style)."))
            }
        } else if reciter.supportsAyahSegments {
            // Own per-ayah stream AND offline segments.
            reciterNoteText(String(localized: "Downloaded surahs also play ayah-by-ayah offline, cut as precise ayah segments."))
        }
    }

    private func reciterNoteText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 2)
    }

}
#else
private struct WatchReciterRow: View {
    private let settings = Settings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    let reciter: Reciter
    let qiraah: Bool
    let isSelected: Bool
    let accentColor: AccentColor
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Button {
                        settings.hapticFeedback()
                        onToggleFavorite()
                    } label: {
                        Image(systemName: settings.isReciterFavorite(reciterID: reciter.id) ? "star.fill" : "star")
                            .foregroundColor(settings.isReciterFavorite(reciterID: reciter.id) ? .yellow : accentColor.color)
                    }
                    .buttonStyle(.plain)

                    Text(reciter.name)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? accentColor.color : .primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor.color)
                        .opacity(isSelected ? 1 : 0)
                }

                if !qiraah && reciter.defaultToMinshawi {
                    Text("This reciter supports surahs only. Ayahs default to Minshawi (Murattal).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

}
#endif
