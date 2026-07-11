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
                // The Quran Tab View options (full surah details, summary mode, last-read rows) only affect
                // the iPhone/iPad Quran tab layout, so hide this whole section on watchOS.
                #if os(iOS)
                Section {
                    quranSettingsLink(title: "Quran Tab View", systemImage: "list.bullet.rectangle") {
                        quranTabViewDestination
                    }
                }
                #endif
                Section {
                    quranSettingsLink(title: "Surah Reading View", systemImage: "book") {
                        surahReadingDestination
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
    /// Bulk-management screens for the user's saved items. Only shown from the main Settings entry
    @ViewBuilder
    private var favoritesAndBookmarksSection: some View {
        Section(header: Text("FAVORITES AND BOOKMARKS")) {
            favoritesLink(title: "Edit Favorite Surahs", type: .surah)
            favoritesLink(title: "Edit Bookmarked Ayahs", type: .ayah)
            favoritesLink(title: "Edit Favorite Letters", type: .letter)
            favoritesLink(title: "Edit Khatm Progress", type: .khatm)
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

    private var quranTabViewDestination: some View {
        quranSettingsSubList(title: "Quran Tab View") {
            quranTabViewSection
        }
    }

    private var surahReadingDestination: some View {
        quranSettingsSubList(title: "Surah Reading View") {
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
        #endif
    }

    // Options that affect the main Quran tab / surah list screen.
    private var quranTabViewSection: some View {
        Section(header: Text("QURAN TAB")) {
            VStack(alignment: .leading) {
                Toggle("Show Full Surah Details", isOn: $settings.showFullSurahRow.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.showFullSurahRow) { _ in settings.hapticFeedback() }

                Text("Adds extra details — revelation type, ayah count, page count, and more — beneath each surah in the main Quran list, the screen where all the surahs are shown.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            VStack(alignment: .leading) {
                Toggle("Summary Mode", isOn: $settings.quranSummaryMode.animation(.easeInOut))
                    .font(.subheadline)
                    .onChange(of: settings.quranSummaryMode) { _ in settings.hapticFeedback() }

                Text("Bundles Ayah of the Day, Last Listened, and Last Read into one compact \"Your Summary\" section of tiles at the top of the Quran tab — it's all one thing. Turn it off to show each as its own full-width section instead, which is clearer but takes up a lot more space. (Summary is separate from the grid button, so you can keep this on while everything else stays a list.)")
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

    /// "Use System Font Size" for the Arabic text only — pins the Arabic size to the device's Dynamic Type
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

    /// "Use System Font Size" for the English text only — pins the English size to the device's Dynamic
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

    private var cleanArabicTextGroup: some View {
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
    }

    private var qiraahLinks: some View {
        Group {
            NavigationLink(destination: AhrufView()) {
                Text("The 7 Ahruf (Modes)")
            }
            .font(.caption)

            NavigationLink(destination: QiraatView()) {
                Text("The 10 Qiraat (Recitations)")
            }
            .font(.caption)
        }
    }

    private var qiraahHighlight: some View {
        Text("***Hafs an Asim* is the most common and widespread Qiraah in the world today.**")
            .font(.caption)
            .foregroundColor(.primary)
            .padding(.top, 4)
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
        SearchBar(text: $searchText.animation(.easeInOut))
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
            // Mujawwad/Muallim variant with no true per-ayah recording in that style — confirm the ayah
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

                            Text("Ayah download is not supported, only surah download.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        let downloadedCount = uniqueDownloadedReciterCount
                        Text("Downloaded reciters: \(downloadedCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)

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
                            reciterButtons(filteredReciters(recitersMinshawi))
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
            .searchable(text: $searchText.animation(.easeInOut))
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
        // The three Minshawi variants are always shown together in their own featured section, so they must
        // be excluded from the Mujawwad/Muallim/Murattal style sections in every case — otherwise each shows
        // up twice (the "two reciters" duplication). (Previously only hidden while filtering to downloads.)
        true
    }
    #else
    private var shouldHideDuplicateMinshawiEntries: Bool {
        false
    }
    #endif

    @ViewBuilder
    private func reciterButtons(_ list: [Reciter], qiraah: Bool = false) -> some View {
        ForEach(list) { reciter in
            reciterRow(reciter, qiraah: qiraah)
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
                reciterButtons(section.reciters)
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
        .environmentObject(downloadManager)
        .id(reciter.id)
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
        .id(reciter.id)
        #endif
    }
}

#if os(iOS)
private struct ReciterRow: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var downloadManager = ReciterDownloadManager.shared

    let reciter: Reciter
    let qiraah: Bool
    let isFavorite: Bool
    let isSelected: Bool
    let downloadState: ReciterDownloadManager.DownloadState
    let accentColor: AccentColor
    let searchQuery: String
    let onSelect: () -> Void
    let onScrollToReciter: () -> Void

    @State private var confirmDownload = false

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
                    HighlightedSnippet(
                        source: reciter.name,
                        term: searchQuery,
                        font: .subheadline,
                        accent: accentColor.color,
                        fg: isSelected ? accentColor.color : .primary
                    )
                        .multilineTextAlignment(.leading)

                    if isDownloading {
                        ProgressView(value: overallProgress)
                            .padding(.top, 2)
                    }

                    if !qiraah && reciter.defaultToMinshawi {
                        Text("This reciter supports surahs only. Ayahs default to Minshawi (Murattal).")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
            }

            if hasDownloads {
                Text("Storage used: \(downloadManager.storageText(bytes: downloadState.totalBytes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage = downloadState.errorMessage, !errorMessage.isEmpty {
                Text("Download error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .confirmationDialog("Download \(reciter.name)?", isPresented: $confirmDownload, titleVisibility: .visible) {
            Button("Download All 114 Surahs") {
                settings.hapticFeedback()
                withAnimation {
                    downloadManager.beginDownloadAll(for: reciter)
                }
            }

            Button("Cancel") {}
        } message: {
            Text("This downloads all 114 full-surah recitations for offline playback — it does not download ayah-by-ayah audio. It runs in the background and may use significant data and storage.")
        }
        .onAppear {
            downloadManager.ensureStateLoaded(for: reciter)
        }
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
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

}
#endif

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

/// Bulk editor for the user's saved Quran items — favorite surahs, bookmarked ayahs, favorite letters, and
/// khatm progress — with swipe-to-delete, EditButton, and a "Delete All". Reachable from Quran Settings.
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
