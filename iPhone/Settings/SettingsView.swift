import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared

    @State private var showingCredits = false
    @State private var selectedDestination: SettingsDestination? = SettingsView.defaultDestination
    @State private var hasSetDefaultSelection = false
    @State private var showResetConfirmation = false

    /// The destination shown when nothing is explicitly selected (single source of truth).
    private static let defaultDestination: SettingsDestination = .quranSettings

    private enum SettingsDestination: Hashable {
        case notification
        case prayerSettings
        case quranSettings
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
                notificationSection
                adhanSection
                quranSection
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

    #if os(iOS)
    @available(iOS 16.0, *)
    private var settingsSplitList: some View {
        List(selection: $selectedDestination) {
            Group {
                notificationSectionSplit
                adhanSectionSplit
                quranSectionSplit
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
            }
        }
    }
    #endif

    private func resourceLink<Destination: View>(
        title: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
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
            .confirmationDialog(
                "Reset All Settings?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset All Settings", role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.resetAllSettings()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This restores every setting (appearance, prayer, and Quran options) to its default. Your bookmarks, favorites, khatm progress, and saved location are kept.")
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

    @available(iOS 16.0, *)
    private var quranSectionSplit: some View {
        Section(header: Text("AL-QURAN")) {
            splitResourceLink(title: "Quran Settings", systemImage: "character.book.closed.ar", value: .quranSettings)
        }
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
            Text("Website: ")
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .frame(width: glyphWidth)

            if let url = URL(string: "https://abubakrelmallah.com/") {
                Link("abubakrelmallah.com", destination: url)
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, -4)
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
            Text("Contact: ")
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .frame(width: glyphWidth)

            Text("ammelmallah@icloud.com")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
                .multilineTextAlignment(.leading)
                .padding(.leading, -4)
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

        withAnimation(.smooth()) {
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6449729655?action=write-review") {
                UIApplication.shared.open(url)
            }
        }
    }

    private func openAppSettings() {
        settings.hapticFeedback()

        withAnimation(.smooth()) {
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

    #if os(iOS)
    /// The second stop of a custom accent, plus a preview of the resulting gradient.
    @ViewBuilder
    private var customGradientRow: some View {
        HStack(spacing: 12) {
            ColorPicker("", selection: customSecondColorBinding, supportsOpacity: false)
                .labelsHidden()
                .disabled(Color(hex: settings.customAccentColorHex2) == nil)

            Text("Second Color")
                .font(.subheadline)
                .foregroundColor(Color(hex: settings.customAccentColorHex2) == nil ? .secondary : .primary)

            Spacer()

            Toggle("", isOn: customSecondColorEnabledBinding)
                .labelsHidden()
                .tint(Color(hex: settings.customAccentColorHex2) ?? .green)
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)

        if Color(hex: settings.customAccentColorHex2) != nil {
            Capsule()
                .fill(AccentColor.custom.gradient(from: .leading, to: .trailing))
                .frame(height: 12)
                .padding(.horizontal, 24)
                .padding(.top, 6)
        }

        Text("Turn on a second color to make your accent a two-color gradient. With it off, your accent is the single color above.")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 24)
            .padding(.top, 6)
    }
    #endif

    /// The second stop of a custom accent. Off — an empty stored hex — means one color, and both stops of the
    /// gradient resolve to the primary.
    private var customSecondColorEnabledBinding: Binding<Bool> {
        Binding(
            get: { Color(hex: settings.customAccentColorHex2) != nil },
            set: { isOn in
                withAnimation {
                    settings.customAccentColorHex2 = isOn ? AccentColor.alIslamSecondaryHex : ""
                    settings.accentColor = .custom
                }
            }
        )
    }

    private var customSecondColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: settings.customAccentColorHex2) ?? (Color(hex: settings.customAccentColorHex) ?? .green) },
            set: { newColor in
                settings.customAccentColorHex2 = newColor.hexString
                withAnimation { settings.accentColor = .custom }
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
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(accentColors, id: \.self) { accentColor in
                    // Filled with the accent's gradient, which for a single-color preset is that color twice.
                    Circle()
                        .fill(accentColor.gradient())
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(settings.accentColor == accentColor ? Color.primary : Color.clear, lineWidth: 1)
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
            .padding(.vertical)

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

            customGradientRow
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
