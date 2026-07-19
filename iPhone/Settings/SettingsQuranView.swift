import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SettingsQuranView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    @State private var confirmHideQiraahDetails = false
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

                Text("Adds extra details - revelation type, ayah count, page count, and more - beneath each surah in the main Quran list, the screen where all the surahs are shown.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            VStack(alignment: .leading) {
                Toggle("Summary Mode", isOn: $settings.quranSummaryMode.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.quranSummaryMode) { _ in settings.hapticFeedback() }

                Text("Bundles Ayah of the Day, Last Listened, and Last Read into one compact \"Your Summary\" section of tiles at the top of the Quran tab - it's all one thing. Turn it off to show each as its own full-width section instead, which is clearer but takes up a lot more space. (Summary is separate from the grid button, so you can keep this on while everything else stays a list.)")
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

    private var searchSection: some View {
        Section(header: Text("SEARCH")) {
            VStack(alignment: .leading) {
                Toggle("Ignore Silent Letters in Ayah Search", isOn: $settings.ignoreSilentLettersInQuranSearch.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.ignoreSilentLettersInQuranSearch) { _ in settings.hapticFeedback() }

                Text("Arabic ayah search also checks a recitation-style version with silent letters removed, such as hamzatul wasl and silent alif, waw, ya, or lam.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
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
            Text("Tafsir for any ayah you open is saved automatically. Downloads run while the app is open, can be cancelled, and resume where they left off - already-saved ayahs are skipped. English includes all 3 English tafsirs in one package; each Arabic tafsir downloads separately.")
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
                     ? "This fetches \(pendingTargets.first?.displayName ?? "the tafsir") for all 6,236 ayahs for offline use. It may use significant data - Wi-Fi is recommended."
                     : "This fetches \(pendingTargets.count) tafsir packages for all 6,236 ayahs each, for offline use. It may use significant data - Wi-Fi is recommended.")
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
