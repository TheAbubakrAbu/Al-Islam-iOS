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
                Section {
                    quranSettingsLink(title: "Tafsir", systemImage: "text.book.closed") {
                        tafsirDestination
                    }
                }

                favoritesAndBookmarksSection

                readingModeSection
                #endif
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
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

    private var tafsirDestination: some View {
        quranSettingsSubList(title: "Tafsir") {
            TafsirDownloadSection()
        }
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
            NavigationLink(destination: ReciterListView().environmentObject(settings)) {
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

            VStack(alignment: .leading) {
                Toggle("Summary Mode", isOn: $settings.quranSummaryMode.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.quranSummaryMode) { _ in settings.hapticFeedback() }

                Text("Bundles Ayah of the Day, Last Listened, and Last Read into one compact \"Your Summary\" section of tiles at the top of the Quran tab; it's all one thing. Turn it off to show each as its own full-width section instead, which is clearer but takes up a lot more space. (Summary is separate from the grid button, so you can keep this on while everything else stays a list.)")
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
                    settings.englishFontSize = newValue ? systemBodySize : systemBodySize + 1
                }
            }
        )
    }

    private var arabicTextSection: some View {
        Section(header: Text("ARABIC TEXT")) {
            arabicVisibilityToggle
            tajweedSettingsGroup
            arabicDisplayControls
        }
    }

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
            let tajweedCanRenderNow = settings.showArabicText
                && settings.isHafsDisplay
            let tajweedToggleBinding = Binding<Bool>(
                get: { settings.showTajweedColors && tajweedCanRenderNow },
                set: { settings.showTajweedColors = $0 }
            )
            
            Toggle("Show Tajweed Colors", isOn: tajweedToggleBinding.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!tajweedCanRenderNow)
                .onChange(of: settings.showTajweedColors) { _ in settings.hapticFeedback() }

            #if os(iOS)
            NavigationLink(destination: TajweedLegendView(showsDismissButton: false)) {
                Text("Customize Tajweed Colors")
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
            }
            .disabled(!settings.showTajweedColors)
            #endif

            if settings.showQiraahDetails {
                Text("Tajweed colors are currently available only for Hafs an Asim, not the other qiraat or riwayat.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private var arabicDisplayControls: some View {
        if settings.showArabicText {
            cleanArabicTextGroup
            arabicFontPicker
            arabicFontSizeControls
            beginnerModeGroup
        }
    }

    @ViewBuilder
    private var cleanArabicTextGroup: some View {
        // The clean/no-dots text exists only for the Hafs reading - the other qiraat ship as fully
        // vocalized text and the renderer ignores these flags for them - so with another riwayah
        // selected the toggles hide behind a short explanation instead of silently doing nothing.
        if !settings.isHafsDisplay {
            Text("Hide Tashkeel and Hide Dots are available for the Hafs reading only. Switch the Arabic Riwayah back to Hafs to use them.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        } else {
            cleanArabicTextToggles
        }
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
                Toggle("Hide Arabic Dots", isOn: $settings.removeArabicDots.animation(.easeInOut))
                    .font(.subheadline)
                    .disabled(!settings.showArabicText)
                    .onChange(of: settings.removeArabicDots) { _ in settings.hapticFeedback() }

                #if os(iOS)
                Text("This removes Arabic dots, such as turning ب into ٮ. It is very difficult to read and is not recommended for beginners, but it allows you to experience how some of the earliest Muslims read and wrote the Quran in early manuscripts such as the Birmingham Manuscript.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
                #endif
            }
        }
    }

    private var arabicFontPicker: some View {
        Picker("Arabic Font", selection: $settings.fontArabic.animation(.easeInOut)) {
            Text("Uthmani").tag(Settings.hafsUthmaniFontName)
            Text("Indopak").tag(Settings.indopakFontName)
            Text("Basic").tag(Settings.systemArabicFontName)
        }
        #if os(iOS)
        .pickerStyle(SegmentedPickerStyle())
        #endif
        .disabled(!settings.showArabicText)
        .onChange(of: settings.fontArabic) { _ in settings.hapticFeedback() }
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

            Text("In reading mode, shrinks each mushaf page's Arabic just enough that all of its ayahs fit on one screen, the way a printed mushaf sets them. Never larger than your chosen font size. Turn this off to read at exactly the size above and scroll.")
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

            Toggle("Show English Translation\nSaheeh International", isOn: $settings.showEnglishSaheeh.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText && !settings.showTransliteration && !settings.showEnglishMustafa)
                .onChange(of: settings.showEnglishSaheeh) { _ in settings.hapticFeedback() }

            Toggle("Show English Translation\nClear Quran (Mustafa Khattab)", isOn: $settings.showEnglishMustafa.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText && !settings.showTransliteration && !settings.showEnglishSaheeh)
                .onChange(of: settings.showEnglishMustafa) { _ in settings.hapticFeedback() }
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
                betaQiraatGroup
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
            HStack(spacing: 6) {
                Text("RIWAYAH / QIRAAH")
                Text("- \(settings.displayQiraahArabicCaption)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .padding(.vertical, 2)
                Spacer(minLength: 0)
            }
        } footer: {
            if settings.showQiraahDetails {
                Text("Play Ayahs is unsupported for other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")
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
        ArabicTextRiwayahPicker(
            selection: $settings.displayQiraah.animation(.easeInOut),
            useSimpleIOSPicker: true
        )
        .font(.subheadline)
        .onChange(of: settings.displayQiraah) { _ in settings.hapticFeedback() }
    }

    /// The switch that unlocks the twelve machine-extracted riwayat, with the warning
    /// stated up front and confirmed before anything unverified can appear on screen.
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
                Label("Beta Qiraat (12 More Riwayat)", systemImage: "flask")
                Text("Adds Ibn Amir, Hamzah, al-Kisai, Abu Jafar, Yaqub and Khalaf al-Ashir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(settings.accentColor.color)
        .confirmationDialog(
            "Turn on beta qiraat?",
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
            NavigationLink(destination: AhrufView()) {
                Text("The 7 Ahruf (Modes)")
            }
            .font(.caption)
            .padding(.vertical, 2)

            NavigationLink(destination: QiraatView()) {
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

            Text("When on, the ayah view shows a riwayah picker above the search bar so you can switch and compare qiraat in that screen.")
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
                        if let surah = quranData.quran.first(where: { $0.id == surahId }) {
                            SurahRow(surah: surah, isFavorite: true).equatable()
                        }
                    }
                    .onDelete(perform: removeSurahs)
                }
            case .ayah:
                if settings.bookmarkedAyahs.isEmpty {
                    Text("No bookmarked ayahs here, long tap an ayah to bookmark it.")
                } else {
                    ForEach(settings.bookmarkedAyahs.sorted {
                        $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
                    }, id: \.id) { bookmarkedAyah in
                        if let surah = quranData.quran.first(where: { $0.id == bookmarkedAyah.surah }),
                           let ayah = surah.ayahs.first(where: { $0.id == bookmarkedAyah.ayah }) {
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
/// The Tafsir settings screen: choose which tafsir packages to keep offline - each individually, all
/// English, all Arabic, or everything - with live progress and per-package storage management. Individual
/// tafsirs are always cached automatically the first time they're opened; downloading just fills the cache
/// up front.
private struct TafsirDownloadSection: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = TafsirStore.shared

    /// The targets a tapped download button would fetch, pending confirmation.
    @State private var pendingTargets: [TafsirDownloadTarget] = []
    @State private var confirmDownload = false
    @State private var deleteTarget: TafsirDownloadTarget?
    @State private var confirmDelete = false

    private func byteText(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func usage(_ target: TafsirDownloadTarget) -> (files: Int, bytes: Int64) {
        store.diskUsage[target.rawValue] ?? (0, 0)
    }

    private func requestDownload(_ targets: [TafsirDownloadTarget]) {
        settings.hapticFeedback()
        pendingTargets = targets
        confirmDownload = true
    }

    var body: some View {
        Section {
            if store.isDownloading {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.downloadingTargetName)
                        .font(.subheadline.weight(.semibold))

                    ProgressView(
                        value: Double(store.downloadCompleted),
                        total: Double(max(store.downloadTotal, 1))
                    )

                    Text("\(store.downloadCompleted) of \(store.downloadTotal) ayahs (\(byteText(store.downloadBytes)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                        .padding(.vertical, 2)

                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        store.cancelDownload()
                    } label: {
                        Text("Cancel Download")
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 4)
            } else {
                ForEach(TafsirDownloadTarget.allCases) { target in
                    targetRow(target)
                }
            }

            if let error = store.downloadError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 2)
            }
        } header: {
            Text("OFFLINE TAFSIR")
        } footer: {
            Text("Tafsir for any ayah you open is saved automatically. Downloads run while the app is open, can be cancelled, and resume where they left off; already-saved ayahs are skipped. English includes all 3 English tafsirs in one package; each Arabic tafsir downloads separately.")
        }
        .onAppear {
            store.refreshDiskUsage()
        }

        if !store.isDownloading {
            Section {
                bulkButton("Download All English (~\(TafsirDownloadTarget.estimatedTotal(TafsirDownloadTarget.englishTargets)) MB)",
                           targets: TafsirDownloadTarget.englishTargets)
                bulkButton("Download All Arabic (~\(TafsirDownloadTarget.estimatedTotal(TafsirDownloadTarget.arabicTargets)) MB)",
                           targets: TafsirDownloadTarget.arabicTargets)
                bulkButton("Download Everything (~\(TafsirDownloadTarget.estimatedTotal(TafsirDownloadTarget.allCases)) MB)",
                           targets: TafsirDownloadTarget.allCases)
            }
            .confirmationDialog("Download Tafsir?", isPresented: $confirmDownload, titleVisibility: .visible) {
                Button("Download (~\(TafsirDownloadTarget.estimatedTotal(pendingTargets)) MB)") {
                    settings.hapticFeedback()
                    store.startDownload(targets: pendingTargets)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(pendingTargets.count == 1
                     ? "This fetches \(pendingTargets.first?.displayName ?? "the tafsir") for all 6,236 ayahs for offline use. It may use significant data; Wi-Fi is recommended."
                     : "This fetches \(pendingTargets.count) tafsir packages for all 6,236 ayahs each, for offline use. It may use significant data; Wi-Fi is recommended.")
            }
            .confirmationDialog("Delete saved tafsir?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete \(deleteTarget?.displayName ?? "")", role: .destructive) {
                    settings.hapticFeedback()
                    if let deleteTarget {
                        store.deleteDownloads(target: deleteTarget)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("It will be re-downloaded from the Internet as you open ayahs, or you can download it again here.")
            }
        }

    }

    @ViewBuilder
    private func targetRow(_ target: TafsirDownloadTarget) -> some View {
        let usage = usage(target)

        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(target.displayName)
                    .font(.subheadline)

                Text(usage.files > 0
                     ? "Saved: \(usage.files) ayahs (\(byteText(usage.bytes)))"
                     : "Not downloaded (~\(target.estimatedMegabytes) MB)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .padding(.vertical, 2)
            }

            Spacer()

            if usage.files > 0 {
                Button {
                    settings.hapticFeedback()
                    deleteTarget = target
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(target.displayName)")
            }

            Button {
                requestDownload([target])
            } label: {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Download \(target.displayName)")
        }
        .padding(.vertical, 2)
    }

    private func bulkButton(_ title: String, targets: [TafsirDownloadTarget]) -> some View {
        Button {
            requestDownload(targets)
        } label: {
            Label(title, systemImage: "icloud.and.arrow.down")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
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
        .init(title: "Reading Mode (List / Page)", path: "Quran Settings → Reading View", keywords: "page mode mushaf list mode grid summary last read", destination: .quranSettings),
        .init(title: "Tafsir", path: "Quran Settings → Tafsir", keywords: "tafsir commentary ibn kathir download", destination: .quranSettings),
        .init(title: "Favorites and Bookmarks (Quran)", path: "Quran Settings → Favorites and Bookmarks", keywords: "manage favorites bookmarks notes surahs ayahs letters", destination: .quranSettings),
    ]
}
#endif

// MARK: - Reciter list (merged from ReciterListView.swift: same file as the Quran settings that link to it)

private struct QiraahReciterSectionHeader: View {
    let title: String
    let arabic: String

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
                HStack(spacing: 10) {
                    reciterTypeLegendItem(.blue, "Full offline")
                    reciterTypeLegendItem(.green, "Own voice")
                    reciterTypeLegendItem(.orange, "Murattal")
                    reciterTypeLegendItem(.red, "Surahs only")
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .confirmationDialog("Reciter Types", isPresented: $showReciterTypeLegendInfo, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text("Blue: the highest tier; surahs and individual ayahs play in this reciter's own voice, and downloaded surahs also play ayah-by-ayah fully offline. Green: individual ayahs play in this reciter's own voice when streaming. Orange: streamed ayahs play in a Murattal style; download the surah to hear ayahs in this reciter's own voice. Red: full surahs only; individual ayahs default to Minshawi (Murattal).")
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
            recitersKhalaf +
            recitersWarsh +
            recitersQaloon +
            recitersBuzzi +
            recitersQunbul +
            recitersDuri
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

    private var searchResultSections: [ReciterSectionGroup] {
        guard isSearchingReciters else { return [] }

        return searchableReciterSections.compactMap { section in
            let sectionMatchesTitle = matchesSectionTitle(section, query: normalizedSearchText)
            let reciters = sectionMatchesTitle
                ? section.reciters
                : section.reciters.filter { reciterMatchesSearch($0, query: normalizedSearchText) }

            guard !reciters.isEmpty else { return nil }
            return section.withReciters(reciters)
        }
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

    private var murattalGroupedSections: [MurattalReciterGroup] {
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
        .padding([.leading, .top], -8)
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

    /// Entry point for a reciter tap. Reciters with no ayah feed (they fall back to Minshawi for ayahs)
    /// first get a confirmation dialog; everything else applies immediately.
    private func handleReciterTap(_ reciter: Reciter) {
        if reciter.defaultToMinshawi {
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

                                NavigationLink(destination: AhrufView()) {
                                    Text("The 7 Ahruf (Modes)")
                                }
                                .font(.subheadline)

                                NavigationLink(destination: QiraatView()) {
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
                            
                            ForEach(searchableQiraahSections) { section in
                                reciterSection(section)
                            }
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

                            NavigationLink(destination: AhrufView()) {
                                Text("The 7 Ahruf (Modes)")
                            }
                            .font(.subheadline)

                            NavigationLink(destination: QiraatView()) {
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
                        
                        ForEach(searchableQiraahSections) { section in
                            reciterSection(section)
                        }
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
                    .padding(.bottom, 8)
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
                        applyReciterSelection(reciter)
                    }
                }

                Button("Cancel") {
                    pendingMinshawiReciter = nil
                }
            } message: {
                Text("\(pendingMinshawiReciter?.name ?? "This reciter") only has full-surah recitation. Individual ayahs and custom ranges will play in \(Reciter.minshawiAyahFallbackName).")
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
            Section(header: QiraahReciterSectionHeader(title: section.title, arabic: section.arabic ?? "")) {
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
                        // each row used to carry.
                        if !qiraah {
                            Circle()
                                .fill(reciterTypeDotColor)
                                .frame(width: 8, height: 8)
                        }

                        HighlightedSnippet(
                            source: reciter.name,
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
        .onAppear {
            downloadManager.ensureStateLoaded(for: reciter)
        }
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
