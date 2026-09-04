import SwiftUI
import UIKit

struct SettingsQuranView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    @State private var confirmHideQiraahDetails = false
    /// Gates turning ON beta qiraat behind the warning dialog (see `betaQiraatGroup`).
    @State private var confirmEnableBetaQiraat = false
    private let presentedAsSheet: Bool

    init(presentedAsSheet: Bool = false) {
        self.presentedAsSheet = presentedAsSheet
    }

    private var includeEnglish: Binding<Bool> {
        Binding(
            get: {
                settings.isHafsDisplay && (settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa)
            },
            set: { newValue in
                // If not on Hafs, English settings don't apply (toggle is disabled in UI).
                guard settings.isHafsDisplay else { return }
                withAnimation {
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
            }
        )
    }

    private var pageJuzDividers: Binding<Bool> {
        Binding(
            get: { settings.showPageJuzDividers },
            set: { newValue in
                withAnimation {
                    settings.showPageJuzDividers = newValue
                }
            }
        )
    }

    private var cleanArabicTextBinding: Binding<Bool> {
        Binding(
            get: { settings.cleanArabicText },
            set: { newValue in
                settings.cleanArabicText = newValue
                if !newValue {
                    settings.removeArabicDots = false
                }
            }
        )
    }
    
    #if DEBUG && os(iOS)
    /// Headless visual verification (no tap access on the dev machine): `-launchQuranSettingsArabic`
    /// lands directly on the Arabic Text subpage, the Hadith tab's `-launchHadithSettingsReading`
    /// pattern. DEBUG builds only.
    @State private var autoOpenArabicText =
        ProcessInfo.processInfo.arguments.contains("-launchQuranSettingsArabic")
    /// `-launchQuranSettingsReciters` lands on the reciter list, for verifying the legend dots and
    /// a partial reciter's coverage. DEBUG builds only.
    @State private var autoOpenReciters =
        ProcessInfo.processInfo.arguments.contains("-launchQuranSettingsReciters")
    #endif

    var body: some View {
        List {
            Group {
                Section {
                    quranSettingsLink(title: "Recitation", systemImage: "headphones") {
                        recitationDestination
                    }
                }
                // One merged screen for how the Quran LOOKS: the tab layout options and the surah
                // reading options live as separate sections inside it. (The tab options only affect the
                // iPhone/iPad Quran tab, so the watch shows just the reading half.)
                Section {
                    quranSettingsLink(title: "Reading View", systemImage: "book") {
                        readingViewsDestination
                    }
                }
                Section {
                    quranSettingsLink(title: "Arabic Text", systemImage: "textformat.ar") {
                        arabicTextDestination
                    }
                }
                Section {
                    quranSettingsLink(title: "English Text", systemImage: "textformat") {
                        englishTextDestination
                    }
                }
                #if os(iOS)
                favoritesAndBookmarksSection

                readingModeSection
                #endif
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        #if DEBUG && os(iOS)
        .background(
            NavigationLink(isActive: $autoOpenArabicText) { arabicTextDestination }
                          label: { EmptyView() }
                .hidden()
        )
        // In `.background`, not the List: a hidden link placed as a row still draws that row's
        // background and separators.
        .background(
            NavigationLink(isActive: $autoOpenReciters) { ReciterListView().environmentObject(settings) }
                          label: { EmptyView() }
                .hidden()
        )
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
        Section(footer: Text("List shows a surah as a scrolling list of ayahs. Pages shows it as a mushaf, one page at a time.")) {
            Picker("Reading View", selection: $settings.quranPageMode.animation(.easeInOut)) {
                Text("List").tag(false)
                Text("Pages").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: settings.quranPageMode) { _ in settings.hapticFeedback() }
        }
    }
    #endif

    private func quranSettingsLink<Destination: View>(
        title: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            Label(title, systemImage: systemImage)
                .padding(.vertical, 4)
        }
        .tint(settings.accentColor.color)
    }

    #if os(iOS)
    /// Bulk-management screens for the user's saved items. One row like every other setting on this screen - 
    /// the four editors live behind it rather than taking four rows of the root list.
    @ViewBuilder
    private var favoritesAndBookmarksSection: some View {
        Section {
            quranSettingsLink(title: "Favorites and Bookmarks", systemImage: "star") {
                favoritesAndBookmarksDestination
            }
        }
    }

    private var favoritesAndBookmarksDestination: some View {
        quranSettingsSubList(title: "Favorites and Bookmarks") {
            Section {
                favoritesLink(title: "Edit Favorite Surahs", type: .surah)
                favoritesLink(title: "Edit Bookmarked Ayahs", type: .ayah)
                favoritesLink(title: "Edit Favorite Letters", type: .letter)
                favoritesLink(title: "Edit Khatm Progress", type: .khatm)
            } footer: {
                Text("These are kept when you reset your settings, unless you choose to erase everything.")
            }
        }
    }

    private func favoritesLink(title: String, type: FavoriteType) -> some View {
        NavigationLink {
            FavoritesView(type: type)
                .environmentObject(quranData)
                .environmentObject(settings)
                .accentColor(settings.accentColor.color)
        } label: {
            Label(title, systemImage: "pencil")
                .padding(.vertical, 4)
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
        quranSettingsSubList(title: "Recitation") {
            recitationSection
        }
    }

    /// The merged Quran Tab + Surah Reading screen: both keep their own sections, one push.
    private var readingViewsDestination: some View {
        quranSettingsSubList(title: "Reading View") {
            #if os(iOS)
            quranTabViewSection
            #endif
            surahReadingSection
        }
    }

    private var englishTextDestination: some View {
        quranSettingsSubList(title: "English Text") {
            englishTextSection
        }
    }

    // Arabic Text keeps Qiraah nested inside it (and owns the qiraah-reset confirmation dialog).
    private var arabicTextDestination: some View {
        List {
            Group {
                arabicTextSection
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
        Section(header: Text("RECITATION")) {
            reciterSelection
            recitationEndingPicker
            recitationCaption
        }
    }

    private var reciterSelection: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(destination: LazyDestination { ReciterListView().environmentObject(settings) }) {
                Label("Choose Reciter", systemImage: "headphones")
            }

            Text(settings.resolvedSelectedReciterIgnoringRandom()?.displayNameWithEnglishQiraah ?? settings.reciter)
                .foregroundColor(settings.accentColor.color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accentColor(settings.accentColor.color)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recitationEndingPicker: some View {
        Picker("After Surah Recitation Ends", selection: $settings.reciteType.animation(.easeInOut)) {
            Section {
                Text("Go to Next").tag("Continue to Next")
                Text("Go to Previous").tag("Continue to Previous")
                Text("End Recitation").tag("End Recitation")
            } header: {
                Text("Recitation End")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
        .onChange(of: settings.reciteType) { _ in settings.hapticFeedback() }
    }

    @ViewBuilder
    private var recitationCaption: some View {
        #if os(iOS)
        Text("The Quran recitations are streamed online by default. You can open Choose Reciter to download full surahs per reciter for offline playback and reduced data use.")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 2)
        #endif
    }

    // Options that affect the main Quran tab / surah list screen.
    private var quranTabViewSection: some View {
        Section(header: Text("QURAN TAB")) {
            VStack(alignment: .leading) {
                Toggle("Show Full Surah Details", isOn: $settings.showFullSurahRow.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.showFullSurahRow) { _ in settings.hapticFeedback() }

                Text("Adds extra details (revelation type, ayah count, page count, and more) beneath each surah in the main Quran list, the screen where all the surahs are shown.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            lastReadAndListenedGroup
        }
    }

    // Options that affect the in-surah reading screen.
    private var surahReadingSection: some View {
        Section(header: Text("READING")) {
            pageAndJuzDividersGroup

            highlightAllahGroup
        }
    }

    private var lastReadAndListenedGroup: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Show Ayah of the Day", isOn: $settings.showAyahOfTheDay.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.showAyahOfTheDay) { _ in settings.hapticFeedback() }

                Text("Shows a different ayah each day at the top of the Quran tab.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Show Last Listened Surah", isOn: $settings.saveLastListenedSurah.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.saveLastListenedSurah) { _ in settings.hapticFeedback() }

                Text("Remembers and shows the last surah you were listening to at the top of the Quran tab.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Show Last Listened Ayah", isOn: $settings.saveLastListenedAyah.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.saveLastListenedAyah) { _ in settings.hapticFeedback() }

                Text("Remembers and shows the last single ayah or custom range you were listening to at the top of the Quran tab.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Show Last Read Ayah", isOn: $settings.saveLastReadAyah.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.saveLastReadAyah) { _ in settings.hapticFeedback() }

                Text("Remembers and shows the last ayah you were reading at the top of the Quran tab.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
        }
    }

    private var pageAndJuzDividersGroup: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Show Page and Juz Dividers", isOn: pageJuzDividers.animation(.easeInOut))
                .font(.subheadline)
                .onChange(of: settings.showPageJuzDividers) { _ in settings.hapticFeedback() }

            Text("Shows a divider inside a surah wherever a new mushaf page or juz begins, plus a small floating label with the current page and juz while you read.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
    }

    /// "Use System Font Size" for the Arabic text only - pins the Arabic size to the device's Dynamic Type
    /// body size (+10, the reading-comfortable default). Split out from the English control so each script
    /// can follow the system size independently.
    private var useSystemArabicFontSize: Binding<Bool> {
        Binding(
            get: {
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                return settings.fontArabicSize == systemBodySize + 10
            },
            set: { newValue in
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                withAnimation {
                    // Explicit publish: this is a direct assignment through a hand-rolled Binding, not the
                    // `$settings` projection, and an @AppStorage write from here was observed NOT reaching
                    // observers reliably - leaving every equatable row on the old size until scrolled off.
                    settings.objectWillChange.send()
                    settings.fontArabicSize = newValue ? systemBodySize + 10 : systemBodySize + 11
                }
            }
        )
    }

    /// "Use System Font Size" for the English text only - pins the English size to the device's Dynamic
    /// Type body size.
    private var useSystemEnglishFontSize: Binding<Bool> {
        Binding(
            get: {
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                return settings.englishFontSize == systemBodySize
            },
            set: { newValue in
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                withAnimation {
                    // Explicit publish - see `useSystemArabicFontSize`.
                    settings.objectWillChange.send()
                    settings.englishFontSize = newValue ? systemBodySize : systemBodySize + 1
                }
            }
        )
    }

    private var arabicTextSection: some View {
        Section(header: Text("ARABIC TEXT")) {
            arabicVisibilityToggle
            #if os(iOS)
            tapWordGroup
            wordByWordGroup
            #endif
            tajweedSettingsGroup
            arabicDisplayControls
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

            Toggle("Tap a Word for Its Meaning", isOn: binding.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!canRenderNow)
                .onChange(of: settings.wordByWordMeanings) { enabled in
                    settings.hapticFeedback()
                    // A megabyte of glosses has no business staying resident once the mode is off -
                    // unless the study layout below is still reading from it.
                    if !enabled && !settings.wordByWordInline { WordByWordStore.shared.unload() }
                }

            Text(canRenderNow || !settings.showArabicText
                 ? "Tap any word while reading to see what that word means on its own, and how it is pronounced. With tajweed colors on, the word's card also explains every tajweed color painted on it. Works offline."
                 : "Available in Hafs an Asim, with beginner mode off - the meanings are counted word by word against that text.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
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

            Toggle("Word by Word", isOn: inlineBinding.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!canRenderNow)
                .onChange(of: settings.wordByWordInline) { enabled in
                    settings.hapticFeedback()
                    if !enabled && !settings.wordByWordMeanings { WordByWordStore.shared.unload() }
                }

            Text(canRenderNow || !settings.showArabicText
                 ? "Lays the ayah out word by word, with each word's meaning and pronunciation written directly beneath it. List mode only: page mode keeps the mushaf layout, so this has no effect there."
                 : "Available in Hafs an Asim, with beginner mode off - the meanings are counted word by word against that text.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)

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
            Toggle("Translation", isOn: $settings.wordByWordInlineTranslation.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.wordByWordInlineTransliteration)
                .onChange(of: settings.wordByWordInlineTranslation) { _ in settings.hapticFeedback() }

            Text("What each word means on its own, from the Quranic Arabic Corpus via Quran.com. Literal and in place, so it reads differently from the flowing translation of the whole ayah.")
                .font(.caption)
                .foregroundColor(.secondary)

            Toggle("Transliteration", isOn: $settings.wordByWordInlineTransliteration.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.wordByWordInlineTranslation)
                .onChange(of: settings.wordByWordInlineTransliteration) { _ in settings.hapticFeedback() }

            Text("How each word is pronounced, written above its meaning. Independent of the ayah's own transliteration line.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .settingsDependent()
    }
    #endif

    private var arabicVisibilityToggle: some View {
        Toggle("Show Arabic Quran Text", isOn: $settings.showArabicText.animation(.easeInOut))
            .font(.subheadline)
            .disabled(!settings.showTransliteration && !settings.showEnglishSaheeh && !settings.showEnglishMustafa)
            .onChange(of: settings.showArabicText) { _ in settings.hapticFeedback() }
    }

    private var highlightAllahGroup: some View {
        VStack(alignment: .leading) {
            Toggle("Highlight Allah", isOn: $settings.highlightAllahNames.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText)
                .onChange(of: settings.highlightAllahNames) { _ in settings.hapticFeedback() }

            Text("Colors the majestic and glorius name الله (Allah) in red throughout the Quran.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
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

            Toggle("Show Tajweed Colors", isOn: tajweedToggleBinding.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!tajweedCanRenderNow)
                .onChange(of: settings.showTajweedColors) { _ in settings.hapticFeedback() }

            #if os(iOS)
            NavigationLink(destination: LazyDestination { TajweedLegendView(showsDismissButton: false) }) {
                Text("Customize Tajweed Colors")
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
            }
            .disabled(!settings.showTajweedColors)
            #endif

            if settings.showQiraahDetails {
                Text(settings.isHafsDisplay
                     ? "Hafs an Asim colors every rule from the tajweed rule engine. The other qiraat and riwayat color words the way their own printed mushaf does - each with its own legend."
                     : "This riwayah colors words the way its printed mushaf does (differences from Hafs, idgham, imalah, ...). See its legend in Customize Tajweed Colors.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private var arabicDisplayControls: some View {
        if settings.showArabicText {
            arabicFontPicker
            hijaziMarkStylePicker
            arabicScriptStylePicker
            arabicFontSizeControls
            beginnerModeGroup
            // Last on purpose (user rule): Hide Tashkeel is the section's most drastic, least
            // recommended option, so it sits at the bottom of the list rather than leading it.
            cleanArabicTextGroup
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

    private var cleanArabicTextToggles: some View {
        VStack(alignment: .leading) {
            Toggle("Hide Arabic Tashkeel (Vowel Diacritics) and Signs", isOn: cleanArabicTextBinding.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText)
                .onChange(of: settings.cleanArabicText) { _ in settings.hapticFeedback() }

            #if os(iOS)
            Text("This option removes Tashkeel (like Fatha, Damma, Kasra, and others), while keeping vowel letters like Alif, Yaa, and Waw. It also adjusts \"Mad\" letters and the \"Hamzatul Wasl,\" and removes tiny vowel letters, stopping signs, chapter markers, and prayer indicators. This option is not recommended.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
            #endif
            
            if settings.cleanArabicText || settings.removeArabicDots {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Hide Arabic Dots", isOn: $settings.removeArabicDots.animation(.easeInOut))
                        .font(.subheadline)
                        .disabled(!settings.showArabicText)
                        .onChange(of: settings.removeArabicDots) { _ in settings.hapticFeedback() }

                    #if os(iOS)
                    Text("This removes Arabic dots, such as turning ب into ٮ. It is very difficult to read and is not recommended for beginners, but it allows you to experience how some of the earliest Muslims read and wrote the Quran in early manuscripts such as the Birmingham Manuscript.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    #endif
                }
                .settingsDependent()
            }
        }
    }

    private var arabicFontPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Every Hijazi mark style reads as "Hijazi" here; the style itself is chosen on the row
            // below, which exists only while Hijazi is selected (five segments is all an iPhone
            // width fits). Order: the two printed-mushaf hands, then the two historical scripts
            // oldest first, then the system font.
            Picker("Arabic Font", selection: Binding(
                get: { Settings.pickerFaceName(for: settings.fontArabic) },
                set: { settings.fontArabic = $0 }
            ).animation(.easeInOut)) {
                Text("Uthmani").tag(Settings.hafsUthmaniFontName)
                Text("Indopak").tag(Settings.indopakFontName)
                // The hand of the earliest mushafs themselves (Al-Islam Hijazi, built from hijazifont).
                Text("Hijazi").tag(Settings.hijaziFontName)
                // The angular script of the early Abbasid mushafs (Noto Kufi Arabic).
                Text("Kufi").tag(Settings.kufiFontName)
                Text("Basic").tag(Settings.systemArabicFontName)
            }
            #if os(iOS)
            .pickerStyle(SegmentedPickerStyle())
            #endif
            .disabled(!settings.showArabicText)
            .onChange(of: settings.fontArabic) { _ in settings.hapticFeedback() }

            #if os(iOS)
            // Where the chosen hand comes from, then the one thing every face shares.
            if let face = Settings.arabicFace(forQuranFontName: settings.fontArabic) {
                Text(face.historyCaption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            Text(Settings.uthmaniRasmCaption)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
            #endif
        }
    }

    /// The Hijazi face's three mark styles (`Settings.HijaziMarkStyle`): one typeface to the picker
    /// above, three builds of it here. Shown only while Hijazi is the Quran face.
    @ViewBuilder
    private var hijaziMarkStylePicker: some View {
        if Settings.isHijaziFontName(settings.fontArabic) {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Hijazi Marks", selection: $settings.fontArabic.animation(.easeInOut)) {
                    ForEach(Settings.HijaziMarkStyle.allCases) { style in
                        Text(style.label).tag(style.fontName)
                    }
                }
                #if os(iOS)
                .pickerStyle(SegmentedPickerStyle())
                #endif
                .disabled(!settings.showArabicText)

                #if os(iOS)
                Text("The letters are the same in all three; only the vowel marks change. Light and Bold are the usual marks at two weights. Dot Vowels writes them the way the earliest vocalised mushafs did: a dot above the letter is fatha, below it is kasra, in front of it is damma, and doubled dots are tanween.")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                        withAnimation(.easeInOut) { settings.arabicScriptStyle = newValue }
                    }
                )) {
                    ForEach(Settings.ArabicScriptStyle.options(showQiraah: showQiraah)) { style in
                        Text(style.label).tag(style)
                    }
                }
                #if os(iOS)
                .pickerStyle(SegmentedPickerStyle())
                #endif

                Text(settings.arabicScriptStyle.detail(namingRiwayat: showQiraah))
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Only for readers who have the qiraat on screen: what the script choice is really
                // choosing between, named by the ten rather than the twenty (both riwayat of a
                // qiraah always mark wasl the same way - verified across all twenty texts).
                if showQiraah {
                    Text(Settings.waslNotationNote)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var arabicFontSizeControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Use System Font Size", isOn: useSystemArabicFontSize.animation(.easeInOut))
                .font(.subheadline)
                .padding(.vertical, 2)

            Stepper(value: $settings.fontArabicSize.animation(.easeInOut), in: 15...75, step: 1) {
                Text("Arabic Font Size: \(Int(settings.fontArabicSize))")
                    .font(.subheadline)
            }

            Slider(value: $settings.fontArabicSize.animation(.easeInOut), in: 15...75, step: 1)

            #if os(iOS)
            fitPageControls
            #endif
        }
    }

    #if os(iOS)
    private var fitPageControls: some View {
        VStack(alignment: .leading) {
            Toggle("Fit Page to Screen", isOn: $settings.mushafFitPage.animation(.easeInOut))
                .font(.subheadline)
                .onChange(of: settings.mushafFitPage) { _ in settings.hapticFeedback() }

            Text("In reading mode, sets each mushaf page the way this riwayah's printed mushaf sets it: the same lines, broken at the same words, at the largest size that fits on one screen - larger or smaller than the size above, whatever the page allows - in your own font and colors. Turn this off to read at exactly the size above and scroll.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
    }
    #endif

    private var beginnerModeGroup: some View {
        VStack(alignment: .leading) {
            Toggle("Enable Arabic Beginner Mode", isOn: $settings.beginnerMode.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText)
                .onChange(of: settings.beginnerMode) { _ in settings.hapticFeedback() }

            Text("Puts a space between each Arabic letter to make it easier for beginners to read the Quran.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
    }

    private var englishTextSection: some View {
        Section(header: Text("ENGLISH TEXT"), footer: settings.showQiraahDetails ? Text("Transliteration, translations, and all English text apply only to default Hafs an Asim. For other riwayat, only the Arabic text is shown.") : nil) {
            includeEnglishToggle
            englishDisplayToggles
            englishFontSizeControls
        }
    }

    private var includeEnglishToggle: some View {
        Toggle("Include English", isOn: includeEnglish.animation(.easeInOut))
            .font(.subheadline)
            .disabled(!settings.isHafsDisplay)
    }

    @ViewBuilder
    private var englishDisplayToggles: some View {
        if settings.isHafsDisplay && includeEnglish.wrappedValue {
            Toggle("Show Transliteration", isOn: $settings.showTransliteration.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText && !settings.showEnglishSaheeh && !settings.showEnglishMustafa)
                .onChange(of: settings.showTransliteration) { _ in settings.hapticFeedback() }
                .settingsDependent()

            Toggle("Show English Translation\nSaheeh International", isOn: $settings.showEnglishSaheeh.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText && !settings.showTransliteration && !settings.showEnglishMustafa)
                .onChange(of: settings.showEnglishSaheeh) { _ in settings.hapticFeedback() }
                .settingsDependent()

            Toggle("Show English Translation\nClear Quran (Mustafa Khattab)", isOn: $settings.showEnglishMustafa.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText && !settings.showTransliteration && !settings.showEnglishSaheeh)
                .onChange(of: settings.showEnglishMustafa) { _ in settings.hapticFeedback() }
                .settingsDependent()
        }
    }

    @ViewBuilder
    private var englishFontSizeControls: some View {
        if settings.isHafsDisplay && includeEnglish.wrappedValue && (settings.showTransliteration || settings.showEnglishSaheeh || settings.showEnglishMustafa) {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Use System Font Size", isOn: useSystemEnglishFontSize.animation(.easeInOut))
                    .font(.subheadline)
                    .padding(.vertical, 2)

                Stepper(value: $settings.englishFontSize.animation(.easeInOut), in: 13...20, step: 1) {
                    Text("English Font Size: \(Int(settings.englishFontSize))")
                        .font(.subheadline)
                }
                Slider(value: $settings.englishFontSize.animation(.easeInOut), in: 13...20, step: 1)
            }
            .settingsDependent()
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
                Text("This app supports all 20 riwayat — 12 are in beta.\n\nThe riwayat printed in the Maghribi script use the official King Fahd Complex Warsh typeface; the others share the Uthmani (Madani) script typeface. You can override this under Arabic Text → Uthmani Script.\n\nPlay Ayahs is unsupported for other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")
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
            selection: $settings.displayQiraah.animation(.easeInOut),
            useMenuRow: true
        )
        .font(.subheadline)
    }

    /// The beta-TEXT switch. All twenty riwayat are always selectable and their printed
    /// mushafs (facsimiles) always load - this only governs whether the 12 machine-
    /// extracted TEXTS may render (lists, comparison, page text). The same consent is
    /// offered inline where text would appear (`BetaTextConsentCard`); this row is the
    /// settings-side twin and the way to turn beta text back off.
    @ViewBuilder
    private var betaQiraatGroup: some View {
        Toggle(isOn: Binding(
            get: { settings.betaQiraatEnabled },
            set: { newValue in
                settings.hapticFeedback()
                if newValue {
                    confirmEnableBetaQiraat = true      // confirm before unlocking
                } else {
                    withAnimation(.easeInOut) { settings.betaQiraatEnabled = false }
                }
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Label("Beta Text (12 Riwayat)", systemImage: "flask")
                Text("Selectable text for Ibn Amir, Hamzah, al-Kisai, Abu Jafar, Yaqub and Khalaf al-Ashir. Their printed mushafs are exact and always available in page mode - only this machine-extracted text is beta.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(settings.accentColor.color)
        .confirmationDialog(
            "Turn on beta text?",
            isPresented: $confirmEnableBetaQiraat,
            titleVisibility: .visible
        ) {
            Button("Turn On") {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.betaQiraatEnabled = true
                    settings.acceptedBetaQiraatNotice = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(Settings.betaQiraatNotice)
        }

        if settings.betaQiraatEnabled {
            Text(Settings.betaQiraatNotice)
                .font(.caption)
                .foregroundStyle(.secondary)
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

    private var qiraahLinks: some View {
        Group {
            NavigationLink(destination: LazyDestination { AhrufView() }) {
                Text("The 7 Ahruf (Modes)")
            }
            .font(.caption)
            .padding(.vertical, 2)

            NavigationLink(destination: LazyDestination { QiraatView() }) {
                Text("The 10 Qiraat (Recitations)")
            }
            .font(.caption)
            .padding(.vertical, 2)
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
        VStack(alignment: .leading) {
            Toggle("Comparison mode", isOn: $settings.qiraatComparisonMode.animation(.easeInOut))
                .font(.subheadline)
                .onChange(of: settings.qiraatComparisonMode) { _ in settings.hapticFeedback() }

            Text("When on, the ayah view shows a riwayah picker above the search bar even on Hafs, so you can switch and compare qiraat in that screen. In any other riwayah the picker is always there.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)

        }
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
    @ObservedObject var settings = Settings.shared

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
                if settings.khatmCompletedAyahs.isEmpty {
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
        case .khatm: return settings.khatmCompletedAyahs.isEmpty
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
        let idsToRemove = Set(offsets.map { sorted[$0].id })
        settings.favoriteLetters.removeAll { idsToRemove.contains($0.id) }
    }

    private func removeKhatmSurahs(at offsets: IndexSet) {
        let surahsWithProgress = quranData.quran.filter { settings.khatmCompletedCount(for: $0) > 0 }
        for offset in offsets {
            settings.resetKhatmProgress(for: surahsWithProgress[offset])
        }
    }

    private func titleForFavoriteType(_ type: FavoriteType) -> String {
        switch type {
        case .surah:  return "Favorite Surahs"
        case .ayah:   return "Bookmarked Ayahs"
        case .letter: return "Favorite Letters"
        case .khatm:  return "Khatm Progress"
        }
    }
}
#endif


#if os(iOS)
// MARK: - Settings-search entries (kept in THIS file, next to the screens they describe)
extension SettingsSearchEntry {
    static let quranEntries: [SettingsSearchEntry] = [
        .init(title: "Quran Settings", path: "Al-Quran", keywords: "mushaf reading", destination: .quranSettings),
        .init(title: "Reciter", path: "Quran Settings → Recitation", keywords: "reciters audio download favorite minshawi husary sudais qari listen", destination: .reciters),
        .init(title: "Recitation Type & Random Reciter", path: "Quran Settings → Recitation", keywords: "murattal mujawwad muallim random ayah recitation", destination: .quranSettings),
        .init(title: "Arabic Text (Quran)", path: "Quran Settings → Arabic Text", keywords: "font size uthmani indopak script clean dots beginner mode spacing", destination: .quranSettings),
        .init(title: "Tajweed Colors", path: "Quran Settings → Arabic Text", keywords: "tajwid rules colors ghunnah qalqalah madd legend", destination: .quranSettings),
        .init(title: "Highlight Allah (Quran)", path: "Quran Settings → Arabic Text", keywords: "highlight name of allah red color quran", destination: .quranSettings),
        .init(title: "Riwayah & Qiraat", path: "Quran Settings → Arabic Text", keywords: "hafs warsh qaloon riwayah qiraat ahruf readings", destination: .quranSettings),
        .init(title: "Transliteration & English Translations", path: "Quran Settings → English Text", keywords: "saheeh international mustafa khattab translation english transliteration", destination: .quranSettings),
        .init(title: "Reading Mode (List / Page)", path: "Quran Settings → Reading View", keywords: "page mode mushaf list mode grid last read", destination: .quranSettings),
        .init(title: "Favorites and Bookmarks (Quran)", path: "Quran Settings → Favorites and Bookmarks", keywords: "manage favorites bookmarks notes surahs ayahs letters", destination: .quranSettings),
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
            Text(title)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text("- \(arabic)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
                .padding(.vertical, 2)
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
    @ObservedObject private var settings = Settings.shared

    let teacher: String
    let teacherArabic: String
    let riwayahCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("QIRAAH OF \(teacher.uppercased())")
                .foregroundStyle(settings.accentColor.color)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text("- \(teacherArabic)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .padding(.vertical, 2)

            Spacer(minLength: 0)

            Text("\(riwayahCount) \(riwayahCount == 1 ? "riwayah" : "riwayat")")
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

    @ObservedObject var settings = Settings.shared
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
                    reciterTypeLegendItem(.blue, "Full offline")
                    reciterTypeLegendItem(.green, "Own voice")
                    reciterTypeLegendItem(.orange, "Murattal")
                    reciterTypeLegendItem(.red, "Surahs only")
                    reciterTypeLegendItem(.purple, "Incomplete")
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .confirmationDialog("Reciter Types", isPresented: $showReciterTypeLegendInfo, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text("Blue: the highest tier; surahs and individual ayahs play in this reciter's own voice, and downloaded surahs also play ayah-by-ayah fully offline. Green: individual ayahs play in this reciter's own voice when streaming. Orange: streamed ayahs play in a Murattal style; download the surah to hear ayahs in this reciter's own voice. Red: full surahs only; individual ayahs default to Minshawi (Murattal). Purple: incomplete; this reciter has not recorded all 114 surahs.")
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
        pendingRequestedQiraahIsUnsupported ? "Qiraah Text Not Supported" : "Change Quran Text?"
    }

    private var qiraahChangeDialogMessage: String {
        if pendingRequestedQiraahIsUnsupported {
            let qiraahName = pendingQiraahReciter?.qiraah?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let qiraahName, !qiraahName.isEmpty {
                return "This reciter uses \(qiraahName). This qiraah text form is not supported right now. Keep your current Quran text and continue?"
            }
            return "This reciter's qiraah text form is not supported right now. Keep your current Quran text and continue?"
        }

        if pendingDisplayQiraahTag == nil {
            return "This reciter uses Hafs an Asim (default). Would you like to switch the Quran text to match it?"
        }

        guard let pendingQiraahReciter,
              let qiraah = pendingQiraahReciter.qiraah,
              !qiraah.isEmpty else {
            return "This reciter uses a different riwayah. Would you like to switch the Quran text to match it?"
        }

        return "This reciter uses \(qiraah). Would you like to switch the Quran text to match it?"
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

    /// Matches row `.id(...)` for `ScrollViewReader.scrollTo`.
    private var reciterListScrollTargetID: String {
        if settings.reciter == Settings.randomReciterName {
            return Settings.randomReciterName
        }
        if !settings.reciterId.isEmpty {
            return settings.reciterId
        }
        return settings.resolvedSelectedReciterIgnoringRandom()?.id ?? settings.reciter
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
                title: "MUHAMMAD SIDDIQ AL-MINSHAWI",
                arabic: nil,
                reciters: filteredReciters(recitersMinshawi),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "mujawwad",
                title: "SLOW & MELODIC (MUJAWWAD)",
                arabic: nil,
                reciters: filteredReciters(recitersMujawwad, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "muallim",
                title: "TEACHING (MUALLIM)",
                arabic: nil,
                reciters: filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "murattal",
                title: "NORMAL (MURATTAL)",
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
            title: "OTHER GROUP",
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
        isSearchingReciters ? "SEARCH RESULTS" : ""
    }

    private var searchableReciterSections: [ReciterSectionGroup] {
        var sections = primaryReciterSections.filter { $0.id != "murattal" }

        sections += murattalGroupedSections.map { group in
            ReciterSectionGroup(id: group.id, title: group.title, arabic: nil, reciters: group.reciters, isQiraah: false)
        }

        sections.append(primaryReciterSections.first { $0.id == "murattal" } ?? ReciterSectionGroup(id: "murattal", title: "NORMAL (MURATTAL)", arabic: nil, reciters: [], isQiraah: false))
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

        for section in searchableReciterSections {
            let sectionMatchesTitle = matchesSectionTitle(section, query: normalizedSearchText)
            let matched = sectionMatchesTitle
                ? section.reciters
                : section.reciters.filter { reciterMatchesSearch($0, query: normalizedSearchText) }

            for reciter in matched {
                if entries[reciter.id] == nil {
                    entries[reciter.id] = SearchEntry(reciter: reciter, sections: [])
                    order.append(reciter.id)
                }
                if entries[reciter.id]?.sections.contains(where: { $0.id == section.id }) == false {
                    entries[reciter.id]?.sections.append(section)
                }
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
            groups.append(.init(id: "haramain", title: "HARAMAIN (MAKKAH & MADINAH)", subtitle: "Most recognized globally", reciters: haramain))
        }
        if !classicalEgyptian.isEmpty {
            groups.append(.init(id: "classical-egypt", title: "CLASSICAL EGYPTIAN SCHOOL", subtitle: "Deep tajweed and slower murattal", reciters: classicalEgyptian))
        }
        if !contemporary.isEmpty {
            groups.append(.init(id: "contemporary", title: "FAMOUS CONTEMPORARY RECITERS", subtitle: "Well-known and widely listened to", reciters: contemporary))
        }
        if !classicHaramain.isEmpty {
            groups.append(.init(id: "classic-haramain", title: "CLASSIC HARAMAIN & OLDER IMAMS", subtitle: "Older but iconic voices", reciters: classicHaramain))
        }
        if !other.isEmpty {
            groups.append(.init(id: "other", title: "OTHER RECITERS", subtitle: "Less mainstream or distinct styles", reciters: other))
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
        return normalized(reciter.name).contains(query)
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
                            reciterButtons(favoriteReciters)
                        }
                    }

                    Section {
                        randomReciterButton
                    }

                    #if os(iOS)
                    Section(header: Text("DOWNLOADED SURAHS")) {
                        Picker("Reciter Filter", selection: $showDownloadedOnly.animation(.easeInOut)) {
                            Text("All Reciters").tag(false)
                            Text("Downloaded Only").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: showDownloadedOnly) { _ in settings.hapticFeedback() }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Downloads are full-reciter packages (all 114 surahs).")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(.vertical, 2)

                            Text("Ayah download is not supported, only surah download.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)
                        }

                        let downloadedCount = uniqueDownloadedReciterCount
                        Text("Downloaded reciters: \(downloadedCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                                    Text(splitMurattalRecitersByGroup ? "Show Murattal as One Section" : "Group Murattal Reciters")

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
            .adaptiveSafeArea(edge: .bottom) {
                reciterSearchControlsInset
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .background(Color.white.opacity(0.00001))
            }
            #elseif os(watchOS)
            .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
            #endif
            .applyConditionalListStyle()
            .confirmationDialog(qiraahChangeDialogTitle, isPresented: Binding(
                get: { pendingQiraahReciter != nil },
                set: {
                    if !$0 {
                        pendingQiraahReciter = nil
                        pendingDisplayQiraahTag = nil
                    }
                }
            ), titleVisibility: .visible) {
                Button(pendingRequestedQiraahIsUnsupported ? "Yes, Keep Current Quran Text" : "Confirm and Change") {
                    settings.hapticFeedback()
                    confirmPendingQiraahSelection()
                }

                Button(pendingRequestedQiraahIsUnsupported ? "Cancel Selection" : "No, Don't Change Qiraah") {
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
                Text("\(pendingMurattalStyleReciter?.name ?? "This reciter") has no separate ayah-by-ayah recording in this style, so individual ayahs and custom ranges will play in \(pendingMurattalStyleReciter?.ayahMurattalStyleNote ?? "Murattal"). Full-surah playback is unaffected.")
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

                if settings.reciter.isEmpty
                    || (settings.reciter != Settings.randomReciterName && settings.resolvedSelectedReciterIgnoringRandom() == nil) {
                    withAnimation {
                        settings.applyDefaultReciterSelection()
                    }
                }

                #if os(iOS)
                reciters.forEach { downloadManager.ensureStateLoaded(for: $0) }
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
            ? "\(reciter.name) (Default - 1381 AH)"
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
                    .padding(.vertical, 2)
            }

            if hasDownloads {
                Text("Storage used: \(downloadManager.storageText(bytes: downloadState.totalBytes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                ? "This downloads all \(reciter.carriedSurahCount) full-surah recitations for offline playback. This reciter also supports ayah segments, so individual ayahs and custom ranges then play offline too, cut from the downloaded surah. It runs in the background and may use significant data and storage."
                : "This downloads all \(reciter.carriedSurahCount) full-surah recitations for offline playback; it does not download ayah-by-ayah audio. It runs in the background and may use significant data and storage.")
        }
        .confirmationDialog("Reciter Type", isPresented: $showTypeDotInfo, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text(typeDotExplanation)
        }
        .confirmationDialog("Incomplete Mushaf", isPresented: $showCoverageDotInfo, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text(coverageDotExplanation)
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
            return "Red: full surahs only. Individual ayahs and custom ranges play in Minshawi (Murattal) instead of this reciter's voice."
        }
        if let style = reciter.ayahMurattalStyleNote {
            return reciter.supportsAyahSegments
                ? "Orange: streamed ayahs play in \(style). Download a surah and its ayahs play in this reciter's own voice, cut from the downloaded file."
                : "Orange: individual ayahs and custom ranges play in \(style), not in this reciter's own voice."
        }
        if reciter.supportsAyahSegments {
            return "Blue: the highest tier. Full surahs and individual ayahs play in this reciter's own voice, and once a surah is downloaded its ayahs play offline too."
        }
        return "Green: individual ayahs play in this reciter's own voice while streaming."
    }

    /// What the purple dot means for THIS reciter, naming the surahs it actually carries.
    private var coverageDotExplanation: String {
        let carried = reciter.carriedSurahCount
        return "Purple: incomplete. This reciter has recorded \(carried) of the 114 surahs.\n\nSupports surahs \(reciter.carriedSurahRangesDescription)."
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
            reciterNoteText("This reciter supports surahs only. Ayahs default to Minshawi (Murattal).")
        } else if let style = reciter.ayahMurattalStyleNote {
            if reciter.supportsAyahSegments {
                // Segments, but no own streamed ayahs: the whole surah must be downloaded to hear an ayah
                // in this reciter's own voice.
                reciterNoteText("Streamed ayahs play in \(style). Download the surah to hear ayahs in this reciter's own voice, cut as offline ayah segments.")
            } else {
                reciterNoteText("Individual ayahs and custom ranges play in \(style).")
            }
        } else if reciter.supportsAyahSegments {
            // Own per-ayah stream AND offline segments.
            reciterNoteText("Downloaded surahs also play ayah-by-ayah offline, cut as precise ayah segments.")
        }
    }

    private func reciterNoteText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 2)
    }

}
#else
private struct WatchReciterRow: View {
    @ObservedObject private var settings = Settings.shared

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
                        .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

}
#endif
