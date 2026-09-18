import SwiftUI

#if os(iOS)

// MARK: - Hadith settings

/// What a hadith row shows: Arabic, English, the narrator line, and which Arabic face. Small enough to live
/// in a sheet off the Hadith tab rather than the app settings tree.
struct SettingsHadithView: View {
    @ObservedObject private var settings = Settings.shared

    /// True when presented as a sheet (its own NavigationView + dismiss X); false when PUSHED from the
    /// Settings tab, where the surrounding navigation already provides the chrome.
    var presentedAsSheet: Bool = true
    /// A sub-screen to push a beat after the root mounts: what a settings search result lands on.
    var openPage: SettingsHadithPage? = nil
    @State private var openRequestedPage = false
    @State private var deepLinkFired = false

    #if DEBUG
    /// Headless visual verification (no tap access on the dev machine): `-launchHadithSettingsReading`
    /// lands directly on the Reading View subpage. DEBUG builds only.
    @State private var autoOpenReadingView =
        ProcessInfo.processInfo.arguments.contains("-launchHadithSettingsReading")
    #endif

    var body: some View {
        if presentedAsSheet {
            NavigationView {
                settingsList
                    .navigationTitle("Hadith Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .sheetDismissToolbar()
                    #if DEBUG
                    .background(
                        NavigationLink(isActive: $autoOpenReadingView) { readingViewDestination }
                                      label: { EmptyView() }
                            .hidden()
                    )
                    #endif
            }
            .navigationViewStyle(.stack)
        } else {
            settingsList
                .modifier(SettingsDeepLink(isPresented: $openRequestedPage, active: openPage != nil) {
                    if let page = openPage { hadithPageDestination(page) }
                })
                .onAppear {
                    guard !deepLinkFired, openPage != nil else { return }
                    deepLinkFired = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { openRequestedPage = true }
                }
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

    /// The root: one card of links, the Al-Quran Settings pattern exactly - the controls live one push
    /// away so this screen reads as a table of contents rather than a wall of toggles - on the
    /// page-search scaffold, so "font" here finds the size sliders.
    private var settingsList: some View {
        SettingsScopedSearch(scope: .hadith, resolve: resolveSearchDestination) {
            Section(header: Text("READING")) {
                hadithPageLink(.readingView) { readingViewDestination }
                hadithPageLink(.arabicText) { arabicTextDestination }
                hadithPageLink(.englishText) { englishTextDestination }
            }
        }
    }

    private func hadithPageLink<Destination: View>(
        _ page: SettingsHadithPage,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: LazyDestination(build: destination)) {
            SettingsRowLabel(title: page.title, systemImage: page.systemImage, subtitle: page.caption, tint: SettingsTint.hadith)
        }
        .tint(settings.accentColor.color)
    }

    /// The sub-screen behind each root row, for the deep links and the page search.
    @ViewBuilder
    private func hadithPageDestination(_ page: SettingsHadithPage) -> some View {
        switch page {
        case .readingView: readingViewDestination
        case .arabicText: arabicTextDestination
        case .englishText: englishTextDestination
        }
    }

    private func resolveSearchDestination(_ destination: SettingsSearchEntry.Destination) -> AnyView? {
        if case .hadithPage(let page) = destination { return AnyView(hadithPageDestination(page)) }
        return nil
    }

    private var readingViewDestination: some View {
        List {
            Group {

                // In Reading View - not under Arabic Text - because it colors the name in BOTH scripts:
                // the Arabic الله and "Allah" in the English translation and narrator lines, like the Quran.
                Section {
                    VStack(alignment: .leading) {
                        Toggle("Highlight Allah", isOn: $settings.highlightAllahNamesHadith.animation(.easeInOut))
                            .onChange(of: settings.highlightAllahNamesHadith) { _ in settings.hapticFeedback() }

                        Text("Colors the majestic and glorious name اللَّه (Allah) in red throughout the hadith texts, in both Arabic and English.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
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
                    // The footer is the chosen face's own story (same captions as the Quran font picker).
                    Section(header: Text("ARABIC FONT"), footer: Text(settings.islamArabicFace.historyCaption)) {
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

}

// MARK: - Settings-search entries (kept in THIS file, next to the screens they describe)
extension SettingsSearchEntry {
    static let hadithEntries: [SettingsSearchEntry] = [
        .init(title: "Hadith Settings", path: "Al-Hadith", keywords: "bukhari muslim books", destination: .hadithSettings),
        .init(title: "Show Hadith Arabic", path: "Hadith Settings → Arabic Text", keywords: "hadith arabic text toggle display", destination: .hadithPage(.arabicText)),
        .init(title: "Hadith Arabic Font & Size", path: "Hadith Settings → Arabic Text", keywords: "hadith arabic font face size slider system", destination: .hadithPage(.arabicText)),
        .init(title: "Show Hadith English", path: "Hadith Settings → English Text", keywords: "hadith english translation narrator toggle display", destination: .hadithPage(.englishText)),
        .init(title: "Hadith English Font Size", path: "Hadith Settings → English Text", keywords: "hadith english font size slider system", destination: .hadithPage(.englishText)),
        .init(title: "Highlight Allah (Hadith)", path: "Hadith Settings → Reading View", keywords: "highlight name of allah red color hadith arabic english", destination: .hadithPage(.readingView)),
    ]
}

#endif
