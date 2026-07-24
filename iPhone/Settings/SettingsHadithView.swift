import SwiftUI

#if os(iOS)

// MARK: - Hadith settings

/// What a hadith row shows: Arabic, English, the narrator line, and which Arabic face. Small enough to live
/// in a sheet off the Hadith tab rather than the app settings tree.
struct SettingsHadithView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    /// True when presented as a sheet (its own NavigationView + dismiss X); false when PUSHED from the
    /// Settings tab, where the surrounding navigation already provides the chrome.
    var presentedAsSheet: Bool = true

    /// What's on the device at a glance: every downloaded book with its size and a per-book delete.
    @ViewBuilder
    private var downloadedBooksSection: some View {
        let downloaded = HadithCatalogBook.all.filter { store.downloadedSlugs.contains($0.slug) }
        Section(
            header: SectionPillHeader(title: "DOWNLOADED", count: downloaded.count),
            footer: downloaded.isEmpty
                ? Text("No books are downloaded. Open any book to download it, or read it once without keeping it.")
                : Text("Tap the trash to remove a book from this device. It can be downloaded again anytime.")
        ) {
            ForEach(downloaded) { book in
                HStack(spacing: 8) {
                    Text(book.englishTitle)
                        .font(.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer()

                    Text("~\(book.approximateMegabytes < 1 ? "0.1" : String(format: "%.0f", book.approximateMegabytes)) MB")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { store.deleteDownload(book) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var body: some View {
        if presentedAsSheet {
            NavigationView {
                settingsList
                    .navigationTitle("Hadith Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .sheetDismissToolbar()
            }
        } else {
            settingsList
                .navigationTitle("Hadith Settings")
        }
    }

    /// "Use System Font Size" for the hadith Arabic - pins it to the device's Dynamic Type body size
    /// (+4, the hadith default), the Quran settings' exact pattern.
    private var useSystemArabicFontSize: Binding<Bool> {
        Binding(
            get: {
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                return settings.hadithArabicFontSize == systemBodySize + 4
            },
            set: { newValue in
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                withAnimation {
                    settings.hadithArabicFontSize = newValue ? systemBodySize + 4 : systemBodySize + 5
                }
            }
        )
    }

    /// "Use System Font Size" for the hadith English - pins it to the device's Dynamic Type body size.
    private var useSystemEnglishFontSize: Binding<Bool> {
        Binding(
            get: {
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                return settings.hadithEnglishFontSize == systemBodySize
            },
            set: { newValue in
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                withAnimation {
                    settings.hadithEnglishFontSize = newValue ? systemBodySize : systemBodySize + 1
                }
            }
        )
    }

    /// The root: one link per area, the Al-Quran Settings pattern exactly - the controls live one push
    /// away so this screen reads as a table of contents rather than a wall of toggles.
    private var settingsList: some View {
        List {
            Group {
                Section {
                    hadithSettingsLink(title: "Reading View", systemImage: "book") {
                        readingViewDestination
                    }
                }
                Section {
                    hadithSettingsLink(title: "Arabic Text", systemImage: "textformat.ar") {
                        arabicTextDestination
                    }
                }
                Section {
                    hadithSettingsLink(title: "English Text", systemImage: "textformat") {
                        englishTextDestination
                    }
                }
                Section {
                    hadithSettingsLink(title: "Downloads", systemImage: "arrow.down.circle") {
                        downloadsDestination
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
    }

    private func hadithSettingsLink<Destination: View>(
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

    private var readingViewDestination: some View {
        List {
            Group {
                Section(footer: Text("Summary mode shows Hadith of the Day and your Last Read Hadith as compact tiles, like the Quran tab.")) {
                    Toggle("Summary Mode", isOn: Binding(
                        get: { UserDefaults.standard.object(forKey: "hadithSummaryMode") == nil ? true : UserDefaults.standard.bool(forKey: "hadithSummaryMode") },
                        set: { newValue in
                            settings.hapticFeedback()
                            UserDefaults.standard.set(newValue, forKey: "hadithSummaryMode")
                        }
                    ).animation(.easeInOut))
                }

                // In Reading View - not under Arabic Text - because it colors the name in BOTH scripts:
                // the Arabic الله and "Allah" in the English translation and narrator lines, like the Quran.
                Section {
                    VStack(alignment: .leading) {
                        Toggle("Highlight Allah", isOn: $settings.highlightAllahNamesHadith.animation(.easeInOut))
                            .onChange(of: settings.highlightAllahNamesHadith) { _ in settings.hapticFeedback() }

                        Text("Colors the majestic and glorious name الله (Allah) in red throughout the hadith texts, in both Arabic and English.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Reading View")
    }

    private var arabicTextDestination: some View {
        List {
            Group {
                Section {
                    Toggle("Show Arabic", isOn: Binding(
                        get: { settings.showHadithArabic },
                        set: { newValue in
                            settings.hapticFeedback()
                            settings.showHadithArabic = newValue
                            // Never allow both off - there would be nothing left to read.
                            if !newValue && !settings.showHadithEnglish {
                                settings.showHadithEnglish = true
                            }
                        }
                    ).animation(.easeInOut))

                }

                if settings.showHadithArabic {
                    Section(header: Text("ARABIC FONT"), footer: Text("Uthmani and IndoPak are classical script styles; Basic is the standard system font.")) {
                        IslamArabicFontPicker()

                        // The Quran settings' font controls, one for one: system-size toggle,
                        // stepper, and slider.
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Use System Font Size", isOn: useSystemArabicFontSize.animation(.easeInOut))
                                .font(.subheadline)
                                .padding(.vertical, 2)

                            Stepper(value: $settings.hadithArabicFontSize.animation(.easeInOut), in: 15...40, step: 1) {
                                Text("Arabic Font Size: \(Int(settings.hadithArabicFontSize))")
                                    .font(.subheadline)
                            }

                            Slider(value: $settings.hadithArabicFontSize.animation(.easeInOut), in: 15...40, step: 1)
                        }
                        .onChange(of: settings.hadithArabicFontSize) { _ in settings.hapticFeedback() }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Arabic Text")
    }

    private var englishTextDestination: some View {
        List {
            Group {
                // No separate narrator toggle: the narrator is part of the English text and
                // simply shows whenever English does - one less switch to reason about.
                Section {
                    Toggle("Show English", isOn: Binding(
                        get: { settings.showHadithEnglish },
                        set: { newValue in
                            settings.hapticFeedback()
                            settings.showHadithEnglish = newValue
                            if !newValue && !settings.showHadithArabic {
                                settings.showHadithArabic = true
                            }
                        }
                    ).animation(.easeInOut))
                }

                if settings.showHadithEnglish {
                    Section(header: Text("ENGLISH FONT")) {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Use System Font Size", isOn: useSystemEnglishFontSize.animation(.easeInOut))
                                .font(.subheadline)
                                .padding(.vertical, 2)

                            Stepper(value: $settings.hadithEnglishFontSize.animation(.easeInOut), in: 10...32, step: 1) {
                                Text("English Font Size: \(Int(settings.hadithEnglishFontSize))")
                                    .font(.subheadline)
                            }

                            Slider(value: $settings.hadithEnglishFontSize.animation(.easeInOut), in: 10...32, step: 1)
                        }
                        .onChange(of: settings.hadithEnglishFontSize) { _ in settings.hapticFeedback() }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("English Text")
    }

    // No "Fit Page" toggle anywhere here: hadith pages ALWAYS fit the screen (the pagination packs
    // whole hadiths per page at the chosen sizes) - unlike the mushaf, where fixed text per page
    // makes fitting a real choice.

    private var downloadsDestination: some View {
        List {
            Group {
                downloadedBooksSection
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Downloads")
    }
}

// MARK: - Settings-search entries (kept in THIS file, next to the screens they describe)
extension SettingsSearchEntry {
    static let hadithEntries: [SettingsSearchEntry] = [
        .init(title: "Hadith Settings", path: "Al-Hadith", keywords: "bukhari muslim books", destination: .hadithSettings),
        .init(title: "Show Hadith Arabic / English", path: "Hadith Settings → Arabic / English Text", keywords: "hadith text toggles narrator display", destination: .hadithSettings),
        .init(title: "Hadith Font Sizes", path: "Hadith Settings → Arabic / English Text", keywords: "hadith arabic english font size", destination: .hadithSettings),
        .init(title: "Highlight Allah (Hadith)", path: "Hadith Settings → Reading View", keywords: "highlight name of allah red color hadith arabic english", destination: .hadithSettings),
        .init(title: "Hadith Summary Mode", path: "Hadith Settings → Reading View", keywords: "hadith of the day last read tiles summary", destination: .hadithSettings),
        .init(title: "Hadith Downloads", path: "Hadith Settings → Downloads", keywords: "delete books storage size downloaded remove megabytes", destination: .hadithSettings),
    ]
}

#endif
