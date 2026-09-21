import SwiftUI

#if os(iOS)

// MARK: - Islam settings

/// The fourth area of the Settings tab: everything that is NOT about the Quran, the prayer times, or the
/// hadith books (Abu, 2026-09-19).
///
/// Those three areas each own a screen already, and each wears one colour. What was left over had no home:
/// the Arabic face used by the duas, the dhikr, the 99 Names and the alphabet lived only as a floating
/// segmented picker repeated on SIX reading screens, all writing one `settings.islamArabicFace`. The
/// alphabet's size slider and its two practice switches were reachable only from the screens they affect.
/// Duplicating a control six times is how the six copies drift; one of them is a setting, not a reading
/// control, so it belongs here and the reading screens are now clean.
///
/// It wears BOTH of Al-Islam's colours (yellow into green, `SettingsTint.islam`) because unlike the other
/// three it is not one tab: it is the whole of the rest of the app.
struct SettingsIslamView: View {
    @ObservedObject private var settings = Settings.shared

    /// True when presented as a sheet (its own NavigationView + dismiss X); false when PUSHED from the
    /// Settings tab, where the surrounding navigation already provides the chrome.
    var presentedAsSheet: Bool = false
    /// A sub-screen to push a beat after the root mounts: what a settings search result lands on.
    var openPage: SettingsIslamPage? = nil
    @State private var openRequestedPage = false
    @State private var deepLinkFired = false

    #if DEBUG
    /// Headless visual verification (no tap access on the dev machine): `-launchIslamSettingsArabic`
    /// lands directly on the Arabic Text subpage. DEBUG builds only.
    @State private var autoOpenArabicText =
        ProcessInfo.processInfo.arguments.contains("-launchIslamSettingsArabic")
    #endif

    var body: some View {
        if presentedAsSheet {
            NavigationView {
                settingsList
                    .navigationTitle("Islam Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .sheetDismissToolbar()
                    #if DEBUG
                    .background(
                        NavigationLink(isActive: $autoOpenArabicText) { arabicTextDestination }
                                      label: { EmptyView() }
                            .hidden()
                    )
                    #endif
            }
            .navigationViewStyle(.stack)
        } else {
            settingsList
                .modifier(SettingsDeepLink(isPresented: $openRequestedPage, active: openPage != nil) {
                    if let page = openPage { islamPageDestination(page) }
                })
                .onAppear {
                    guard !deepLinkFired, openPage != nil else { return }
                    deepLinkFired = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { openRequestedPage = true }
                }
                #if DEBUG
                .background(
                    NavigationLink(isActive: $autoOpenArabicText) { arabicTextDestination }
                                  label: { EmptyView() }
                        .hidden()
                )
                #endif
                .navigationTitle("Islam Settings")
        }
    }

    /// The root: a table of contents, the Quran and Hadith settings pattern exactly - the controls live one
    /// push away - on the page-search scaffold, so "arabic font" typed here finds the face picker.
    private var settingsList: some View {
        SettingsScopedSearch(scope: .islam, resolve: resolveSearchDestination) {
            TipsSection(area: .islam, resolve: resolveSearchDestination)

            Section(header: Text("READING")) {
                islamPageLink(.arabicText) { arabicTextDestination }
                islamPageLink(.alphabet) { alphabetDestination }
            }

            Section(header: Text("THE TAB")) {
                islamPageLink(.libraries) { librariesDestination }
                // The same screen the Settings tab opens from its top card: the welcome's answer,
                // the Start Here guide it switches on at the top of the Islam tab, and the replay.
                AboutYouSettingsRow(tint: SettingsTint.islam, secondaryTint: SettingsTint.islamSecondary)
            }

            // The same screen Quran Settings and Notifications open (Abu, 2026-09-20: "sunnah
            // reminders should also be in islam settings"). The reminders are acts of worship
            // across the whole day, not only Quran reading, so this is a door they were missing,
            // not a copy: one `SunnahRemindersView`, three ways in.
            Section(header: Text("REMINDERS")) {
                islamPageLink(.sunnahReminders) { SunnahRemindersView() }
            }
        }
    }

    private func islamPageLink<Destination: View>(
        _ page: SettingsIslamPage,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: LazyDestination(build: destination)) {
            SettingsRowLabel(title: page.title, systemImage: page.systemImage, subtitle: page.caption,
                             tint: SettingsTint.islam, secondaryTint: SettingsTint.islamSecondary)
        }
        .tint(settings.accentColor.color)
    }

    /// The sub-screen behind each root row, for the deep links and the page search.
    @ViewBuilder
    private func islamPageDestination(_ page: SettingsIslamPage) -> some View {
        switch page {
        case .arabicText: arabicTextDestination
        case .alphabet: alphabetDestination
        case .libraries: librariesDestination
        case .sunnahReminders: SunnahRemindersView()
        }
    }

    private func resolveSearchDestination(_ destination: SettingsSearchEntry.Destination) -> AnyView? {
        if case .islamPage(let page) = destination { return AnyView(islamPageDestination(page)) }
        return nil
    }

    // MARK: Arabic Text

    /// The one Arabic face for every non-Quran, non-hadith Arabic surface. This screen is now the ONLY
    /// place it is set: the six floating pickers that used to ride above those screens' search bars are
    /// gone (Abu, 2026-09-19), so there is one control for one setting.
    private var arabicTextDestination: some View {
        List {
            Group {
                // The footer is the chosen face's own story - the same caption the Quran and hadith
                // font pickers show, from `IslamArabicFace.historyCaption`.
                Section(header: Text("ARABIC FONT"), footer: Text(settings.islamArabicFace.historyCaption)) {
                    IslamArabicFontPicker()

                    Text("The Arabic face used by the duas, the dhikr and remembrances, the 99 Names of Allah, and the Arabic alphabet. The Quran and the hadith books keep their own fonts, in Quran Settings and Hadith Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 2)
                }

                // The Islam tab's own switch (Abu, 2026-09-20), beside the Quran's and the hadith
                // books': each area of the app decides for itself.
                Section(header: Text("HIGHLIGHTS")) {
                    VStack(alignment: .leading) {
                        Toggle("Highlight Allah", isOn: $settings.highlightAllahNamesIslam.animation(.easeInOut))
                            .font(.subheadline)
                            .tint(settings.accentColor.color)
                            .onChange(of: settings.highlightAllahNamesIslam) { _ in settings.hapticFeedback() }

                        Text("Shows the name of Allah in red in the duas, the dhikr and remembrances, the tasbih, the 99 Names, the daily cards, and the quotes in the articles and guides. The Quran and the hadith books have their own switches, in Quran Settings and Hadith Settings.")
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
        .navigationTitle("Arabic Text")
    }

    // MARK: Arabic Alphabet

    /// The alphabet screens' own three controls: the size floor, and the two practice switches. They were
    /// reachable only from the screens they affect, which is fine for the slider (you want to see the
    /// letters grow) and wrong for the other two, which are preferences you set once.
    private var alphabetDestination: some View {
        List {
            Group {
                Section(header: Text("ARABIC SIZE")) {
                    ArabicSizeSlider()
                        .padding(.vertical, 4)

                    Text("How much larger the Arabic reads on the alphabet and letter screens than the rest of the app. The slider raises the size as a floor, so the letters never render smaller than your device's own text size.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 2)
                }

                Section(header: Text("PRACTICE")) {
                    VStack(alignment: .leading) {
                        Toggle("Hide English Readings", isOn: $settings.hideEnglishInArabicLetters.animation(.easeInOut))
                            .onChange(of: settings.hideEnglishInArabicLetters) { _ in settings.hapticFeedback() }

                        Text("Hides the transliterations (\"ba\", \"bi\", \"bu\") under the tashkeel glyphs, so the marks can be practised from the Arabic alone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)
                    }

                    VStack(alignment: .leading) {
                        Toggle("Use Quranic Sukoon", isOn: $settings.quranicSukoonInLetterPractice.animation(.easeInOut))
                            .onChange(of: settings.quranicSukoonInLetterPractice) { _ in settings.hapticFeedback() }

                        Text("Writes the practice syllables with the Uthmani sukoon (\u{06E1}) instead of the plain one (\u{0652}), the exact mark shape the mushaf prints.")
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
        .navigationTitle("Arabic Alphabet")
    }

    // MARK: The tab

    /// How the Al-Islam tab itself presents its libraries. The grid/list choice is per-screen everywhere
    /// in the app (each screen's own toolbar button writes it), so this screen reads the Islam tab's and
    /// says where the others are rather than pretending to own them all.
    private var librariesDestination: some View {
        List {
            Group {
                Section(header: Text("LAYOUT")) {
                    VStack(alignment: .leading) {
                        Toggle("Grid Mode", isOn: Binding(
                            get: { settings.islamGridMode },
                            set: { newValue in
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) { settings.islamGridMode = newValue }
                            }
                        ))

                        Text("Shows the Islamic resources as tiles instead of rows. The 99 Names and the Arabic alphabet keep their own grid switches, in each screen's toolbar.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)
                    }
                }

                Section(header: Text("DAILY")) {
                    VStack(alignment: .leading) {
                        Toggle("Word of the Day", isOn: $settings.showWordOfTheDay.animation(.easeInOut))
                            .onChange(of: settings.showWordOfTheDay) { _ in settings.hapticFeedback() }

                        Text("One Arabic word a day on the Al-Islam tab, with its root and where it appears in the Quran.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)
                    }

                    VStack(alignment: .leading) {
                        Toggle("Turn Over at Fajr", isOn: $settings.dailyRolloverAtFajr.animation(.easeInOut))
                            .onChange(of: settings.dailyRolloverAtFajr) { _ in settings.hapticFeedback() }

                        Text("Every daily feature changes at Fajr rather than at midnight, so the day begins with the prayer. Without a location set, the boundary is midnight.")
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
        .navigationTitle("Libraries")
    }
}

// MARK: - The way in from the Al-Islam tab

/// The Islam Settings gear at the top right of the Al-Islam tab and of every resource it opens (Abu,
/// 2026-09-20), the way the Quran and Hadith tabs carry theirs. Before this the screen could only be
/// reached by leaving for the Settings tab, which is a long way to go to change the face of the dua
/// you are reading.
///
/// One modifier rather than a button per screen: `IslamView` applies it at the single door every
/// resource is opened through, so a new resource gets the gear without being told to. It reads the
/// accent from the appearance snapshot instead of observing `Settings`, because it sits on the
/// article pages too, and those are the trees a Settings publish must not re-diff.
///
/// A screen with a trailing button of its OWN (the alphabet's and the 99 Names' grid toggles, the
/// calculator's Reset) hands that button in as `own` and is skipped at the door
/// (`IslamDestination.placesOwnSettingsGear`). Both then sit in ONE toolbar, own button first, which
/// is the only way to declare their order: an outer `.toolbar`'s items land BEFORE an inner one's, so
/// the door's gear came out on the wrong side of the grid toggle, and with no spacer between them
/// iOS 26 merged the pair into a single capsule (seen on the iPhone 17 Pro, 2026-09-20).
struct IslamSettingsToolbar<Own: View>: ViewModifier {
    @Environment(\.appearance) private var appearance
    @State private var showIslamSettings = false
    /// The screen's own trailing button, nil when it has none.
    let own: (() -> Own)?

    func body(content: Content) -> some View {
        toolbar(on: content)
            .sheet(isPresented: $showIslamSettings) {
                SettingsIslamView(presentedAsSheet: true)
                    .smallMediumSheetPresentation()
            }
    }

    /// Four shapes and no `if` inside the toolbar builder: conditional toolbar content needs iOS 16,
    /// and the spacer needs iOS 26. The spacer is what keeps the gear its own circle beside the
    /// screen's button (the Hadith tab's trailing toolbar has the same one for the same reason).
    @ViewBuilder
    private func toolbar(on content: Content) -> some View {
        if let own {
            if #available(iOS 26.0, *) {
                content.toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) { own() }
                    ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
                    ToolbarItem(placement: .navigationBarTrailing) { gearButton }
                }
            } else {
                content.toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) { own() }
                    ToolbarItem(placement: .navigationBarTrailing) { gearButton }
                }
            }
        } else {
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { gearButton }
            }
        }
    }

    private var gearButton: some View {
        Button {
            Settings.shared.hapticFeedback()
            showIslamSettings = true
        } label: {
            Image(systemName: "gear")
        }
        .accessibilityLabel("Islam settings")
        .tint(appearance.accent)
    }
}

extension View {
    /// The gear alone, for a screen with no trailing button of its own.
    func islamSettingsToolbar() -> some View {
        modifier(IslamSettingsToolbar<EmptyView>(own: nil))
    }

    /// The screen's own trailing button, then the gear.
    func islamSettingsToolbar<Own: View>(@ViewBuilder own: @escaping () -> Own) -> some View {
        modifier(IslamSettingsToolbar(own: own))
    }
}

// MARK: - Settings-search entries (kept in THIS file, next to the screens they describe)
extension SettingsSearchEntry {
    static let islamEntries: [SettingsSearchEntry] = [
        .init(title: "Islam Settings", path: "Al-Islam", keywords: "islam arabic font dua dhikr names alphabet libraries sunnah reminders", destination: .islamSettings),
        .init(title: "Highlight Allah (Islam)", path: "Islam Settings → Arabic Text", keywords: "highlight allah name red color dua dhikr adhkar tasbih articles islam", destination: .islamPage(.arabicText)),
        .init(title: "Arabic Font (Islam)", path: "Islam Settings → Arabic Text", keywords: "arabic font face uthmani indopak hijazi kufi basic dua dhikr adhkar names alphabet islam", destination: .islamPage(.arabicText)),
        .init(title: "Arabic Size (Alphabet)", path: "Islam Settings → Arabic Alphabet", keywords: "arabic size slider letters alphabet bigger larger floor", destination: .islamPage(.alphabet)),
        .init(title: "Hide English Readings", path: "Islam Settings → Arabic Alphabet", keywords: "hide english transliteration readings tashkeel letters practice ba bi bu", destination: .islamPage(.alphabet)),
        .init(title: "Use Quranic Sukoon", path: "Islam Settings → Arabic Alphabet", keywords: "quranic sukoon uthmani jazm letter practice mark", destination: .islamPage(.alphabet)),
        .init(title: "Grid Mode (Al-Islam)", path: "Islam Settings → Libraries", keywords: "grid list tiles rows islam resources layout", destination: .islamPage(.libraries)),
        .init(title: "Word of the Day", path: "Islam Settings → Libraries", keywords: "word of the day arabic daily vocabulary root", destination: .islamPage(.libraries)),
        .init(title: "Turn Over at Fajr", path: "Islam Settings → Libraries", keywords: "daily rollover fajr midnight day boundary of the day", destination: .islamPage(.libraries)),
        .init(title: "Sunnah Reminders (Islam)", path: "Islam Settings → Sunnah Reminders", keywords: "al-kahf friday al-mulk sleep muawwidhat reminder notification dua", destination: .islamPage(.sunnahReminders)),
    ]
}

#endif
