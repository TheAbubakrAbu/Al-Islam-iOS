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
        case credits
    }
}
#endif

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared

    @State private var showingCredits = false
    @State private var selectedDestination: SettingsDestination? = SettingsView.defaultDestination
    @State private var hasSetDefaultSelection = false
    @State private var showResetConfirmation = false
    @State private var confirmEraseEverything = false
    @State private var settingsSearchText = ""
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

    var body: some View {
        navigationContainer
    }

    private var navigationContainer: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    NavigationSplitView {
                        settingsSplitList
                            .onAppear {
                                if !hasSetDefaultSelection {
                                    selectedDestination = Self.defaultDestination
                                    hasSetDefaultSelection = true
                                }
                            }
                    } detail: {
                        // Detail gets its own NavigationStack so the sub-screen NavigationLinks
                        // (e.g. Quran settings → Recitation) push within the detail column instead of
                        // replacing the whole split. `.id` rebuilds it when the sidebar selection changes.
                        NavigationStack {
                            settingsSplitDetail
                        }
                        .id(selectedDestination ?? Self.defaultDestination)
                        .animation(.easeInOut(duration: 0.25), value: selectedDestination)
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

    private var settingsList: some View {
        List {
            Group {
                #if os(iOS)
                if !settingsSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    settingsSearchResultsSection
                } else {
                    standardSettingsSections
                }
                #else
                standardSettingsSections
                #endif
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        // The search bar floats at the bottom, exactly like every other searchable screen: Apple
        // Music-style minimize on scroll-down, restore on scroll-up (or while typing).
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                SearchBar(text: $settingsSearchText.animation(.easeInOut))
                    .padding([.horizontal, .top], -8)
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #endif
        .navigationTitle("Settings")
        .applyConditionalListStyle()
    }

    @ViewBuilder
    private var standardSettingsSections: some View {
        notificationSection
        adhanSection
        quranSection
        #if os(iOS)
        hadithSection
        #endif
        appearanceSection
        resetSection
        creditsSection

        AlIslamAppsSection()
    }

    #if os(iOS)
    @available(iOS 16.0, *)
    private var settingsSplitList: some View {
        List(selection: $selectedDestination) {
            Group {
                notificationSectionSplit
                adhanSectionSplit
                quranSectionSplit
                hadithSectionSplit
                appearanceSection
                resetSection
                creditsSection
                AlIslamAppsSection()
            }
            .themedListRowBackground()
        }
        .navigationTitle("Settings")
        .applyConditionalListStyle()
    }

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
        case .credits: CreditsView()
        }
    }

    private var settingsSearchResults: [SettingsSearchEntry] {
        let query = settingsSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        let terms = query.split(separator: " ").map(String.init)
        return Self.settingsSearchIndex.filter { entry in
            let blob = "\(entry.title) \(entry.path) \(entry.keywords)".lowercased()
            return terms.allSatisfy { blob.contains($0) }
        }
    }

    @ViewBuilder
    private var settingsSearchResultsSection: some View {
        let results = settingsSearchResults
        Section(header: SectionPillHeader(title: "SETTING RESULTS", count: results.count)) {
            if results.isEmpty {
                Text("No settings match your search.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(results) { entry in
                NavigationLink(destination: LazyDestination { searchDestinationView(entry.destination) }) {
                    VStack(alignment: .leading, spacing: 2) {
                        HighlightedSnippet(
                            source: entry.title,
                            term: settingsSearchText,
                            font: .subheadline,
                            accent: settings.accentColor.color,
                            fg: .primary
                        )

                        Text(entry.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    #endif

    private func resourceLink<Destination: View>(
        title: String,
        systemImage: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        // LazyDestination, same as IslamView: building the destination eagerly meant every body pass of this
        // tab constructed the full Adhan/Quran/Notification settings trees - on the watch, where TabView
        // re-evaluates neighbouring tabs on every swipe, that WAS the tab-switch lag into Settings.
        NavigationLink(destination: LazyDestination(build: destination)) {
            toolLabel(title, systemImage: systemImage)
        }
        .tint(settings.accentColor.color)
    }

    private func toolLabel(_ title: String, systemImage: String) -> some View {
        Label(
            title: {
                Text(title)
                    .foregroundColor(.primary)
            },
            icon: {
                Image(systemName: systemImage)
                    .foregroundColor(settings.accentColor.color)
            }
        )
        .padding(.vertical, 4)
    }

    @available(iOS 16.0, *)
    private func splitResourceLink(
        title: String,
        systemImage: String,
        value: SettingsDestination
    ) -> some View {
        NavigationLink(value: value) {
            toolLabel(title, systemImage: systemImage)
        }
        .tint(settings.accentColor.color)
    }

    @ViewBuilder
    private var notificationSection: some View {
        // Shown on watchOS too: watchOS now supports local notifications, so expose the settings instead
        // of hiding them. (The iPad split layout uses notificationSectionSplit instead.)
        Section(header: Text("NOTIFICATIONS")) {
            resourceLink(title: "Notification Settings", systemImage: "bell.badge") {
                NotificationView()
            }
        }
    }

    @available(iOS 16.0, *)
    @ViewBuilder
    private var notificationSectionSplit: some View {
        Section(header: Text("NOTIFICATIONS")) {
            splitResourceLink(title: "Notification Settings", systemImage: "bell.badge", value: .notification)
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
                Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                    .font(.subheadline)
                    .foregroundColor(.red)
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

    private var adhanSection: some View {
        Section(header: Text("AL-ADHAN")) {
            resourceLink(title: "Prayer Settings", systemImage: "safari") {
                SettingsAdhanView(showNotifications: false)
            }
        }
    }

    @available(iOS 16.0, *)
    private var adhanSectionSplit: some View {
        Section(header: Text("AL-ADHAN")) {
            splitResourceLink(title: "Prayer Settings", systemImage: "safari", value: .prayerSettings)
        }
    }

    private var quranSection: some View {
        Section(header: Text("AL-QURAN")) {
            resourceLink(title: "Quran Settings", systemImage: "character.book.closed.ar") {
                SettingsQuranView()
            }
        }
    }
    
    #if os(iOS)
    private var hadithSection: some View {
        Section(header: Text("AL-HADITH")) {
            resourceLink(title: "Hadith Settings", systemImage: "text.book.closed") {
                SettingsHadithView(presentedAsSheet: false)
            }
        }
    }
    #endif

    @available(iOS 16.0, *)
    private var quranSectionSplit: some View {
        Section(header: Text("AL-QURAN")) {
            splitResourceLink(title: "Quran Settings", systemImage: "character.book.closed.ar", value: .quranSettings)
        }
    }
    
    #if os(iOS)
    @available(iOS 16.0, *)
    private var hadithSectionSplit: some View {
        Section(header: Text("AL-HADITH")) {
            splitResourceLink(title: "Hadith Settings", systemImage: "text.book.closed", value: .hadithSettings)
        }
    }
    #endif

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
            Label("View Credits", systemImage: "scroll.fill")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
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
            Label("Leave a Review", systemImage: "star.bubble.fill")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
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
            Label("Open App Settings", systemImage: "gearshape.fill")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
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
