import SwiftUI
import Adhan
import UserNotifications
#if os(iOS)
import AVFoundation
#endif

struct SettingsAdhanView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// The Adhan tab's prayer layout (TILES / GRID / LIST / SPLIT), the same key the PRAYER TIMES
    /// header's picker writes. That header picker was its only home until Simple Mode hid it there.
    @AppStorage("prayerDisplayModeV2") private var prayerDisplayModeRawValue: String = PrayerList.PrayerDisplayMode.tiles.rawValue
    @Environment(\.dismiss) private var dismiss

    @State private var showingMap = false

    @State private var showAlert: AlertType?
    enum AlertType: Identifiable {
        case travelTurnOnAutomatic, travelTurnOffAutomatic, calculationAutomaticChanged

        var id: Int {
            switch self {
            case .travelTurnOnAutomatic: return 1
            case .travelTurnOffAutomatic: return 2
            case .calculationAutomaticChanged: return 3
            }
        }
    }

    @State var showNotifications: Bool
    private let presentedAsSheet: Bool
    /// The programmatic entrances: Traveling Mode (its dialog, the prayer list's row, the Distance
    /// From Home glance tile), Prayer Calculation (its glance tile), and any sub-screen a settings
    /// search result names. The request is remembered and the push is raised a beat after appear
    /// (`SettingsDeepLink`): iOS 16+ pushes through `navigationDestination(isPresented:)`, iOS 15
    /// through a hidden `isActive` link, and either one set true before the container has mounted
    /// never pushes (2026-09-05, seen on iOS 26).
    private let requestedPage: SettingsAdhanPage?
    @State private var openRequestedPage = false
    @State private var deepLinkFired = false
    /// One sub-screen shown ON ITS OWN, as the root of its stack: a Need a Hand? door's sheet
    /// (HelpDoors.swift). The dialogs and the change handlers below stay attached, so Traveling
    /// Mode's confirmation still presents from there.
    private let standalonePage: SettingsAdhanPage?

    init(showNotifications: Bool, presentedAsSheet: Bool = false, openTravelingMode: Bool = false,
         openPrayerCalculation: Bool = false, openPage: SettingsAdhanPage? = nil,
         standalonePage: SettingsAdhanPage? = nil) {
        self._showNotifications = State(initialValue: showNotifications)
        self.presentedAsSheet = presentedAsSheet
        self.requestedPage = openTravelingMode ? .travelingMode : (openPrayerCalculation ? .prayerCalculation : openPage)
        self.standalonePage = standalonePage
    }

    /// The card's copy, shared with the Adhan tab's copy of these dialogs (`Settings.AutoChangeCard`).
    private var autoChangeCard: Settings.AutoChangeCard? {
        switch showAlert {
        case .travelTurnOnAutomatic: return settings.autoChangeCard(.travelOn)
        case .travelTurnOffAutomatic: return settings.autoChangeCard(.travelOff)
        case .calculationAutomaticChanged: return settings.autoChangeCard(.calculation)
        case .none: return nil
        }
    }

    private var dialogTitle: String {
        autoChangeCard?.title ?? ""
    }

    var body: some View {
        Group {
            if let standalonePage {
                adhanPageDestination(standalonePage)
            } else {
                rootList
            }
        }
        #if os(iOS)
        .modifier(SettingsDeepLink(isPresented: $openRequestedPage, active: requestedPage != nil) {
            if let page = requestedPage { adhanPageDestination(page) }
        })
        .onAppear {
            guard !deepLinkFired, requestedPage != nil else { return }
            deepLinkFired = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { openRequestedPage = true }
        }
        #endif
        .navigationTitle(standalonePage?.title ?? String(localized: "Al-Adhan Settings"))
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
        // The confirmation is raised only in response to something the USER just did here - changing the home
        // location, or switching one of the automatic modes on - and only once the resulting refresh has
        // settled. It is deliberately NOT driven by an `.onChange` on the travel/calculation flags themselves:
        // watching those means the dialog fires the moment a background location update flips one, over and
        // over, whether or not this screen is on screen. The dialog's buttons clear the flags.
        .onChange(of: settings.homeLocation) { _ in
            settings.fetchPrayerTimes {
                presentAutoChangeDialogIfPending()
            }
        }
        .onChange(of: settings.travelAutomatic) { newValue in
            guard newValue else { return }
            settings.fetchPrayerTimes {
                if settings.homeLocation == nil {
                    settings.setTravelingModeManually(false)
                } else {
                    presentAutoChangeDialogIfPending()
                }
            }
        }
        .onChange(of: settings.calculationAutomatic) { newValue in
            guard newValue else { return }
            settings.fetchPrayerTimes(force: true) {
                presentAutoChangeDialogIfPending()
            }
        }
        .onChange(of: settings.prayerCalculation) { _ in
            guard settings.calculationAutoChanged else { return }
            presentAutoChangeDialogIfPending()
        }
        // NOTE: Confirmation-dialog buttons intentionally avoid `role: .cancel`. On iOS 26+ a `.cancel`
        // button is hidden from the action sheet (the system expects you to cancel by tapping outside / the
        // dim background instead), so a meaningful "Confirm: Keep On"-style choice would silently disappear.
        // Plain buttons always render; tapping outside still cancels. Applies to all confirmation dialogs.
        .confirmationDialog(dialogTitle, isPresented: autoChangeDialogBinding, titleVisibility: .visible) {
            autoChangeDialogButtons
        } message: {
            autoChangeDialogMessage
        }
    }

    /// A dialog anchored only to the root list cannot present while the user is on a *pushed* sub-screen - 
    /// which is exactly why the Traveling Mode confirmation never appeared (the toggle lives on the pushed
    /// "Traveling Mode" screen). The binding and content are shared so the same dialog can also be attached
    /// to the sub-screens, and whichever one is actually on screen presents it.
    private var autoChangeDialogBinding: Binding<Bool> {
        Binding(
            get: { showAlert != nil },
            set: { if !$0 { showAlert = nil } }
        )
    }

    /// Raise the auto-change confirmation if one is pending. Deferred a beat, so the dialog doesn't try to
    /// present while the toggle that triggered it is still animating - presenting into a mid-flight layout is
    /// how a confirmation ends up silently dropped.
    private func presentAutoChangeDialogIfPending() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard showAlert == nil else { return }
            // Travel dialogs only on the device that owns the auto-check - never on a paired watch, where
            // the phone decides and these buttons would flip the just-synced value straight back.
            if settings.ownsTravelingModeAutoCheck, settings.travelTurnOnAutomatic {
                showAlert = .travelTurnOnAutomatic
            } else if settings.ownsTravelingModeAutoCheck, settings.travelTurnOffAutomatic {
                showAlert = .travelTurnOffAutomatic
            } else if settings.ownsAutomaticCalculationCheck, settings.calculationAutoChanged {
                // Same rule for the calculation card: a paired watch takes the phone's method, so its
                // buttons would fight the value it was just handed.
                showAlert = .calculationAutomaticChanged
            }
        }
    }

    /// Accept first, put back second, no destructive red (see `AutoChangeCard`).
    @ViewBuilder
    private var autoChangeDialogButtons: some View {
        switch showAlert {
        case .travelTurnOnAutomatic:
            Button(settings.autoChangeCard(.travelOn).confirmTitle) {
                settings.hapticFeedback()
                settings.confirmTravelAutomaticChange()
            }

            Button(settings.autoChangeCard(.travelOn).overrideTitle) {
                settings.hapticFeedback()
                settings.overrideTravelingMode(keepOn: false)
            }

        case .travelTurnOffAutomatic:
            Button(settings.autoChangeCard(.travelOff).confirmTitle) {
                settings.hapticFeedback()
                settings.confirmTravelAutomaticChange()
            }

            Button(settings.autoChangeCard(.travelOff).overrideTitle) {
                settings.hapticFeedback()
                settings.overrideTravelingMode(keepOn: true)
            }

        case .calculationAutomaticChanged:
            Button(settings.autoChangeCard(.calculation).confirmTitle) {
                settings.hapticFeedback()
                settings.confirmAutomaticCalculationChange()
            }

            Button(settings.autoChangeCard(.calculation).overrideTitle) {
                settings.hapticFeedback()
                settings.overrideAutomaticCalculationKeepingPrevious()
            }

        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var autoChangeDialogMessage: some View {
        if let card = autoChangeCard {
            Text(card.message)
        } else {
            EmptyView()
        }
    }

    /// Shared scaffold for each Adhan settings sub-screen: themed list + standard style + title.
    @ViewBuilder
    private func adhanSettingsSubList<Content: View>(
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

    // The confirmation is attached to these pushed screens as well as the root list. The toggles that trigger
    // it live *here*, and a dialog anchored only to the (now off-screen) root list could never present - 
    // which is why the Traveling Mode confirmation appeared to do nothing.
    private var prayerCalculationDestination: some View {
        PrayerCalculationListView()
            .confirmationDialog(dialogTitle, isPresented: autoChangeDialogBinding, titleVisibility: .visible) {
                autoChangeDialogButtons
            } message: {
                autoChangeDialogMessage
            }
    }

    private var travelingModeDestination: some View {
        adhanSettingsSubList(title: String(localized: "Traveling Mode")) {
            travelingModeSection
        }
        .confirmationDialog(dialogTitle, isPresented: autoChangeDialogBinding, titleVisibility: .visible) {
            autoChangeDialogButtons
        } message: {
            autoChangeDialogMessage
        }
    }

    private var optionalTimesDestination: some View {
        adhanSettingsSubList(title: String(localized: "Optional Prayers")) {
            optionalTimesSection
        }
    }

    private var prayerOffsetsDestination: some View {
        adhanSettingsSubList(title: String(localized: "Manual Offsets")) {
            prayerOffsetsSection
        }
    }

    private var customPrayerNamesDestination: some View {
        adhanSettingsSubList(title: String(localized: "Custom Prayer Names")) {
            CustomPrayerNamesSection()
        }
    }

    /// The root's sections, on the page-search scaffold (iOS) or a plain list (the watch).
    @ViewBuilder
    private var rootList: some View {
        #if os(iOS)
        SettingsScopedSearch(scope: .prayer, resolve: resolveSearchDestination) { rootSections }
        #else
        List {
            Group { rootSections }
                .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        #endif
    }

    /// One card per area (2026-09-16): the door to Notifications, the five prayer-time screens, and
    /// the sky. Every row carries its caption, so the screen reads as a table of contents.
    @ViewBuilder
    private var rootSections: some View {
        notificationsSection

        Section(header: Text("PRAYER TIMES")) {
            #if os(iOS)
            // The watch always draws tiles, so the choice is the phone's alone.
            Picker(selection: $prayerDisplayModeRawValue) {
                ForEach(PrayerList.PrayerDisplayMode.allCases) { mode in
                    Text(mode.displayName.capitalized).tag(mode.rawValue)
                }
            } label: {
                Text("Prayer Times Layout")
            }
            .tint(settings.accentColor.color)
            .onChange(of: prayerDisplayModeRawValue) { _ in settings.hapticFeedback() }
            #endif

            adhanPageLink(.prayerCalculation) { prayerCalculationDestination }
            #if os(iOS)
            // The tracker's own page (History & Insights). Simple Mode shows the tab's tracker only to
            // someone who marked a prayer in the last fourteen days, and ON THE ADHAN TAB below can put
            // it away in either mode, so this is its door the rest of the time (Docs/Product/Simple Mode
            // Guide.md, rule 3); with the tracker on the tab it is a second way in.
            NavigationLink(destination: LazyDestination { PrayerTrackerView() }) {
                SettingsRowLabel(title: String(localized: "Prayer Tracker"), systemImage: "checklist",
                                 subtitle: String(localized: "History, streaks and insights"), tint: SettingsTint.prayer)
            }
            .tint(settings.accentColor.color)
            #endif
            adhanPageLink(.travelingMode) { travelingModeDestination }
            adhanPageLink(.optionalPrayers) { optionalTimesDestination }
            adhanPageLink(.manualOffsets) { prayerOffsetsDestination }
            adhanPageLink(.customPrayerNames) { customPrayerNamesDestination }
        }

        #if os(iOS)
        // One row, like every other area on this page (Abu, 2026-09-20): the sky's switches were the
        // only controls sitting loose on a screen that is otherwise a table of contents.
        Section(header: Text("SKY")) {
            adhanPageLink(.sky, tint: SettingsTint.sky) { skyDestination }
        }

        // The tab's foldable sections, a switch each (TabSections.swift): PRAYER TRACKER and AT A
        // GLANCE. In Simple Mode too, where this is the way At a Glance comes back.
        TabSectionsSettingsSection(area: .adhan)

        // No PRAYER TRACKER section here: the tracker's one switch ("Mark Only After the Time
        // Begins") moved onto the tracker itself in September 2026 and became its only behaviour on
        // 2026-10-19 (see `Settings.canMarkPrayer`); the tracker explains itself on its history page.
        #endif

        // Last on every settings page (Abu, 2026-10-10): a page opens on its own settings, and the
        // tips and the Need a Hand? switch wait at the foot. They led every page from 2026-09-20
        // until then, which put the first real setting most of a screen down. No ADVANCED switch
        // since 2026-10-25: it hid one row, the Custom Prayer Names link.
        #if os(iOS)
        TipsSection(area: .adhan, resolve: resolveSearchDestination)
        // The Adhan tab's Need a Hand? questions, named here with their switch (HelpDoors.swift).
        HelpDoorsSettingsSection(area: .adhan)
        #endif
    }

    /// The Skyline row's one value: "off" while the skyline is hidden, else the style's raw value.
    /// Picking a style also turns the skyline on, so one menu covers both settings.
    private var skylineChoice: Binding<String> {
        Binding(
            get: { settings.showSkyScene ? settings.skySceneStyle : "off" },
            set: { choice in
                if choice == "off" {
                    settings.showSkyScene = false
                } else {
                    settings.skySceneStyle = choice
                    if !settings.showSkyScene {
                        settings.showSkyScene = true
                    }
                }
            }
        )
    }

    private func adhanPageLink<Destination: View>(
        _ page: SettingsAdhanPage,
        tint: Color? = SettingsTint.prayer,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: LazyDestination(build: destination)) {
            SettingsRowLabel(title: page.title, systemImage: page.systemImage, subtitle: page.caption, tint: tint)
        }
        .tint(settings.accentColor.color)
    }

    #if os(iOS)
    /// The Sky Fills the Screen caption; the weather is Al-Islam's alone (`HAS_WEATHER`).
    private static var skyFillsCaption: String {
        #if HAS_WEATHER
        return String(localized: "The whole Adhan tab wears the sky: its colors, stars and weather behind the prayer times and everything under them, with the rows turned to glass.")
        #else
        return String(localized: "The whole Adhan tab wears the sky: its colors and stars behind the prayer times and everything under them, with the rows turned to glass.")
        #endif
    }

    /// Sky: whether the Adhan tab draws it, its skyline, and the door to its colors.
    private var skyDestination: some View {
        List {
            Group {
                Section(header: Text("SKY")) {
                    SettingsToggle(String(localized: "Show Sky"), caption: String(localized: "The sun on today's arc, the moon at its true phase, and the stars at night. Drag the sun to see any moment of the day. Turn it off for a plain Current/Upcoming card."), isOn: $adhanSettings.showSkyView)

                    if settings.showSkyView {
                        SettingsToggle(String(localized: "Sky Fills the Screen"), caption: Self.skyFillsCaption, isOn: $adhanSettings.skyFillsAdhanTab)
                    }
                }

                // Nothing to color, and no ground for a skyline, when the sky isn't drawn.
                if settings.showSkyView {
                    #if HAS_WEATHER
                    Section(header: Text("WEATHER")) {
                        SettingsToggle(String(localized: "Weather"), caption: String(localized: "Clouds, rain, snow and fog on the sky; temperature, UV, humidity and wind on the card and the widgets. Sends your location to Apple Weather about twice an hour while the tab is open; off, it never leaves your device."), isOn: $adhanSettings.skyShowsWeather)

                        if settings.skyShowsWeather {
                            weatherAttributionRow
                        }
                    }
                    #endif
                    Section(header: Text("HORIZON"),
                            footer: Text("Pyramids to the west, a mosque to the east, the sun by day and the moon by night. Choose the pair, only pyramids, or only mosques. Also on the sky widgets.")) {
                        // One row for off / which structures: "off" is the old Skyline switch,
                        // the three styles set it on and pick the shapes (Abu, 2026-09-21).
                        // Plain binding, never animated: see the picker rule.
                        Picker("Skyline", selection: skylineChoice) {
                            Text("Off").tag("off")
                            ForEach(SkySceneStyle.allCases) { style in
                                Text(style.title).tag(style.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(settings.accentColor.color)
                        .onChange(of: settings.showSkyScene) { _ in settings.hapticFeedback() }
                        .onChange(of: settings.skySceneStyle) { _ in settings.hapticFeedback() }
                    }

                    Section(header: Text("COLORS")) {
                        adhanPageLink(.skyColors, tint: SettingsTint.sky) { SkyColorsView() }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Sky")
    }
    #endif

    #if os(iOS) && HAS_WEATHER
    /// Apple's mark and legal link, as the WeatherKit terms require wherever its data shows.
    private var weatherAttributionRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "apple.logo")
                .accessibilityHidden(true)
            Text("Weather")
            Spacer()
            Link("Legal", destination: SkyWeatherStore.shared.legalURL)
                .foregroundColor(settings.accentColor.color)
        }
        .font(.footnote)
        .foregroundColor(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weather data by Apple Weather. Legal attribution.")
    }
    #endif

    /// The sub-screen behind each root row, for the deep links and the page search.
    @ViewBuilder
    private func adhanPageDestination(_ page: SettingsAdhanPage) -> some View {
        switch page {
        case .prayerCalculation: prayerCalculationDestination
        case .travelingMode: travelingModeDestination
        case .optionalPrayers: optionalTimesDestination
        case .manualOffsets: prayerOffsetsDestination
        case .customPrayerNames: customPrayerNamesDestination
        case .sky:
            #if os(iOS)
            skyDestination
            #else
            EmptyView()
            #endif
        case .skyColors:
            #if os(iOS)
            SkyColorsView()
            #else
            EmptyView()
            #endif
        }
    }

    #if os(iOS)
    /// The page search's results land on THIS page's sub-screens; the app-wide mapping would push a
    /// second Prayer Settings root first.
    private func resolveSearchDestination(_ destination: SettingsSearchEntry.Destination) -> AnyView? {
        switch destination {
        case .prayerPage(let page): return AnyView(adhanPageDestination(page))
        case .travelingMode: return AnyView(travelingModeDestination)
        case .prayerCalculation: return AnyView(prayerCalculationDestination)
        case .skyColors: return AnyView(SkyColorsView())
        case .notifications: return AnyView(NotificationView())
        default: return nil
        }
    }
    #endif

    @ViewBuilder
    private var notificationsSection: some View {
        #if os(iOS)
        Section(header: Text("NOTIFICATIONS")) {
            NavigationLink(destination: LazyDestination { NotificationView() }) {
                SettingsRowLabel(title: String(localized: "Notification Settings"), systemImage: "bell.badge.fill",
                                 subtitle: NotificationView.doorSubtitle, tint: SettingsTint.notifications)
            }
            .tint(settings.accentColor.color)
        }
        #endif
    }

    @ViewBuilder
    private var optionalTimesSection: some View {
        Section(header: Text("OPTIONAL PRAYERS")) {
            optionalPrayerToggle(
                title: String(localized: "Duhaa"),
                subtitle: String(localized: "A voluntary forenoon prayer after sunrise and before Dhuhr."),
                icon: "sun.haze.fill",
                isOn: $adhanSettings.showDuha
            )

            optionalPrayerToggle(
                title: String(localized: "Islamic Midnight"),
                subtitle: String(localized: "Halfway between Maghrib and the next Fajr. It marks the end of Isha."),
                icon: "moon.fill",
                isOn: $adhanSettings.showIslamicMidnight
            )

            optionalPrayerToggle(
                title: String(localized: "Last Third of Night"),
                subtitle: String(localized: "The final third before Fajr is a blessed time for dua and forgiveness."),
                icon: "moon.stars.fill",
                isOn: $adhanSettings.showLastThird
            )
        }
    }

    private func optionalPrayerToggle(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        SettingsToggle(title, caption: subtitle, systemImage: icon, isOn: isOn)
    }

    // The madhab + high-latitude controls moved INTO PrayerCalculationListView (they are calculation
    // choices; inline on this root they read as a stray orphan section). Kept nowhere else - the
    // settings-search index deep-links both to that screen.

    private var travelingModeSection: some View {
        // The fiqh of the choice is the section's footer, not the switch's caption: eight lines
        // beside a switch read as a wall (2026-10-21 settings pass).
        Section(header: Text("TRAVELING MODE"), footer: Text(Self.travelingFooter.localizedDigits)) {
            homeCityButton
            automaticTravelToggle
            travelingModeGroup
        }
    }

    private static let travelingFooter = String(localized: "More than 48 mi (77.25 km) from home, it is obligatory to pray Qasr: Dhuhr and Asr combined at 2 rakahs each, Maghrib and Isha at 3 and 2. Allah said in the Quran, \u{201C}When you travel through the land, it is permissible for you to shorten the prayer\u{201D} [Quran 4:101].")

    @ViewBuilder
    private var homeCityButton: some View {
        #if os(iOS)
        HStack(spacing: 8) {
            Text("Set Home City")
                .foregroundColor(settings.accentColor.color)

            Spacer(minLength: 8)

            if let city = settings.homeLocation?.displayCity, !city.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                        .padding(.vertical, 2)

                    Text(city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                // Mirrors the current-city capsule in AdhanView.
                .conditionalGlassEffect()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            settings.hapticFeedback()
            showingMap = true
        }
        .sheet(isPresented: $showingMap) {
            MapView(choosingPrayerTimes: false)
                .environmentObject(settings)
                .smallMediumSheetPresentation()
        }
        #endif
    }

    @ViewBuilder
    private var automaticTravelToggle: some View {
        #if os(iOS)
        SettingsToggle(String(localized: "Automatic Traveling Mode"), isOn: $adhanSettings.travelAutomatic)
        #endif
    }

    private var travelingModeGroup: some View {
        VStack(alignment: .leading) {
            SettingsToggle(String(localized: "Traveling Mode"),
                           caption: settings.travelAutomatic
                               ? String(localized: "Shortens and combines the prayers while you are away from home. Turns on and off by itself; you can also set it here.")
                               : String(localized: "Shortens and combines the prayers while you are away from home."),
                           isOn: travelingModeBinding)
                .disabled(settings.travelAutomatic && !isWatch)

            // The only door to full prayers for a Simple traveler: Simple hides the prayer list's travel
            // footer, which held the View Full / View Qasr button. Same key the footer writes.
            #if os(iOS)
            if settings.travelingMode {
                SettingsToggle(String(localized: "Show Full Prayers"), caption: String(localized: "Every prayer at its full time while traveling, instead of the shortened and combined Qasr list. You may still shorten and combine."), isOn: $adhanSettings.travelingShowFullPrayers)
            }
            #endif
        }
    }

    private var travelingModeBinding: Binding<Bool> {
        Binding(
            get: { settings.travelingMode },
            set: {
                settings.setTravelingModeManually($0)
            }
        )
    }

    // Not iOS-only. The whole body used to sit inside `#if os(iOS)`, but the "Manual Offsets" link that pushes
    // it (see `adhanSettingsLink` above) was never guarded - so on the watch the link pushed a List with a
    // title and zero rows. Both the Hijri stepper and `PrayerOffsetsView` are plain Steppers that work fine on
    // watchOS, so the fix is to actually show them rather than to hide the link.
    /// The Hijri offset as "+2 days", "-1 day" or "0 days" (the watch writes "+0 days"). One key per sign
    /// with the count as its only argument, so a plural key can make Arabic's noun agree with the number:
    /// "%@%lld days" carried the sign as an argument of its own.
    private func hijriOffsetText(plusAtZero: Bool) -> String {
        let offset = settings.hijriOffset
        let count = abs(offset)
        if offset > 0 || (offset == 0 && plusAtZero) {
            return count == 1 ? String(localized: "+\(count) day") : String(localized: "+\(count) days")
        }
        if offset < 0 {
            return count == 1 ? String(localized: "-\(count) day") : String(localized: "-\(count) days")
        }
        return String(localized: "\(count) days")
    }

    @ViewBuilder
    private var prayerOffsetsSection: some View {
        // The Hijri day offset used to live in its own top-level "Manual Offsets" screen; it now sits here
        // alongside the prayer-time offsets so every manual adjustment is in one place.
        Section(header: Text("HIJRI OFFSET")) {
            #if os(watchOS)
            // Watch: one short line ("+2 days") in small type - the phone's "Hijri Offset: X days" row
            // truncated to a couple of letters on the small screen.
            Stepper(value: $adhanSettings.hijriOffset, in: -3...3) {
                Text(hijriOffsetText(plusAtZero: true))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(.footnote)

            if let hijriDate = settings.hijriDate {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hijriDate.companionLine)
                    Text(hijriDate.arabic.localizedDigits)
                }
                .font(.caption2)
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.vertical, 2)
            }
            #else
            Stepper(value: $adhanSettings.hijriOffset, in: -3...3) {
                HStack {
                    Text("Hijri Offset")
                        .foregroundColor(.primary)

                    Spacer()

                    Text(hijriOffsetText(plusAtZero: false))
                        .foregroundColor(settings.accentColor.color)
                        .monospacedDigit()
                }
            }

            // Today's date as the offset leaves it, in both scripts, so the stepper's effect is
            // visible right under it. (An Arabic interface pairs the Arabic date with the Gregorian one.)
            if let hijriDate = settings.hijriDate {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hijriDate.companionLine)
                    Text(hijriDate.arabic.localizedDigits)
                }
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
            }
            #endif
        }
        .onAppear {
            settings.fetchPrayerTimes()
        }

        PrayerOffsetsView()
    }

    private var isWatch: Bool {
        #if os(iOS)
        false
        #else
        true
        #endif
    }
}


struct PrayerOffsetsView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ViewBuilder
    private func offsetStepper(title: String, icon: String, value: Binding<Int>) -> some View {
        // Wide enough to follow a local mosque that runs well off the calculated time, not just to nudge it.
        #if os(watchOS)
        // Watch: prayer name over the minutes, small type - the phone's single wide row truncated badly.
        Stepper(value: value, in: -190...190) {
            VStack(alignment: .leading, spacing: 1) {
                Label(title, systemImage: icon)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .padding(.vertical, 2)

                Text("\(value.wrappedValue) min")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .font(.footnote)
        #else
        Stepper(value: value, in: -190...190) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 22, alignment: .center)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(value.wrappedValue) min")
                    .foregroundColor(settings.accentColor.color)
            }
            .tint(settings.accentColor.color)
            .foregroundColor(settings.accentColor.color)
        }
        #endif
    }

    private func travelOffsetCaption(for prayerName: String) -> String? {
        switch prayerName {
        case "Dhuhr":
            return String(localized: "Also affects the combined traveling Dhuhr/Asr prayer.")
        case "Maghrib":
            return String(localized: "Also affects the combined traveling Maghrib/Isha prayer.")
        default:
            return nil
        }
    }

    var body: some View {
        Section(header: Text("HIJRI DATE"),
                footer: Text("In Islam, the day begins at sunset (Maghrib). Keeping this on follows that Islamic tradition, while turning it off matches the usual midnight-to-midnight day.")) {
            SettingsToggle(String(localized: "Switch Hijri Date at Maghrib"), caption: String(localized: "When enabled, the displayed Hijri date changes at the calculated Maghrib time instead of at midnight. Off by default."), isOn: $adhanSettings.switchHijriDateAtMaghrib)
        }

        Section(header: Text("PRAYER OFFSETS"), footer: offsetsFooter) {
            offsetStepper(title: String(localized: "Fajr"), icon: "sunrise", value: $adhanSettings.offsetFajr)
            offsetStepper(title: String(localized: "Sunrise"), icon: "sunrise.fill", value: $adhanSettings.offsetSunrise)
            offsetStepper(title: String(localized: "Dhuhr"), icon: "sun.max", value: $adhanSettings.offsetDhuhr)
            offsetStepper(title: String(localized: "Asr"), icon: "sun.min", value: $adhanSettings.offsetAsr)
            offsetStepper(title: String(localized: "Maghrib"), icon: "sunset", value: $adhanSettings.offsetMaghrib)
            offsetStepper(title: String(localized: "Isha"), icon: "moon", value: $adhanSettings.offsetIsha)
        }
    }

    /// The two notes under the steppers, as the section's footer (one grammar, 2026-10-25).
    private var offsetsFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Use these offsets to shift the calculated prayer times earlier or later. Negative values move the time earlier, positive values move it later.")
            Text("In traveling mode, Dhuhr offset also affects the combined Dhuhr/Asr prayer, and Maghrib offset also affects the combined Maghrib/Isha prayer.")
        }
    }
}

struct NotificationView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.appearance) private var appearance
    #if os(iOS)
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #endif

    @Environment(\.scenePhase) private var scenePhase

    @State private var showAlert: Bool = false
    @State private var notifSettings: UNNotificationSettings?
    @State private var requestAccessAlertMessage: String?
    #if os(iOS)
    @State private var previewPlayer: AVAudioPlayer?
    @State private var isPreviewingAdhan = false
    #endif

    private var notificationSoundsDisabled: Bool {
        notifSettings?.soundSetting == .disabled
    }

    /// A sub-screen to push a beat after the root mounts: what a settings search result lands on.
    var openPage: SettingsNotificationsPage? = nil
    @State private var openRequestedPage = false
    @State private var deepLinkFired = false

    var body: some View {
        notificationList
        #if os(iOS)
        .modifier(SettingsDeepLink(isPresented: $openRequestedPage, active: openPage != nil) {
            if let page = openPage { notificationPageDestination(page) }
        })
        #endif
        .task { await refresh() }
        .onAppear {
            settings.normalizeAdhanSoundSelection()
            requestAuthorizationAndFetchPrayerTimes()
            #if os(iOS)
            if openPage != nil, !deepLinkFired {
                deepLinkFired = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { openRequestedPage = true }
            }
            #endif
        }
        .onDisappear {
            #if os(iOS)
            stopAdhanPreview()
            #endif
        }
        // Only on becoming ACTIVE (the return from the system Settings app after turning notifications
        // on, which is what this exists for). It used to run on every phase change, so a pulled-down
        // Control Center (`.inactive`) and the backgrounding itself each re-requested authorization,
        // re-fetched the prayer times and could re-present the "Notifications Off" dialog.
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            requestAuthorizationAndFetchPrayerTimes()
        }
        .confirmationDialog("Notifications Off", isPresented: $showAlert, titleVisibility: .visible) {
            Button("Open Settings") {
                settings.hapticFeedback()
                openSystemSettings()
            }
            Button("Ignore") { }
        } message: {
            Text("Please go to Settings and enable notifications to be notified of prayer times.")
        }
        .confirmationDialog("Notifications", isPresented: Binding(
            get: { requestAccessAlertMessage != nil },
            set: { if !$0 { requestAccessAlertMessage = nil } }
        ), titleVisibility: .visible) {
            Button("OK") { requestAccessAlertMessage = nil }
            Button("Open Settings") {
                settings.hapticFeedback()
                requestAccessAlertMessage = nil
                openSystemSettings()
            }
        } message: {
            if let msg = requestAccessAlertMessage {
                Text(msg)
            }
        }
        #if !os(iOS)
        .applyConditionalListStyle()
        #endif
        .navigationTitle("Notification Settings")
    }

    /// The sections on the page-search scaffold (iOS) or a plain list (the watch).
    @ViewBuilder
    private var notificationList: some View {
        #if os(iOS)
        SettingsScopedSearch(scope: .notifications, resolve: resolveSearchDestination) { notificationSections }
        #else
        List {
            Group { notificationSections }
                .themedListRowBackground()
        }
        #endif
    }

    /// The master switch first, then everything it governs. Off, the page is the switch and its note
    /// alone (the iOS Settings app's own Allow Notifications grammar) and every choice under it is kept.
    @ViewBuilder
    private var notificationSections: some View {
        Section(header: Text("ALL NOTIFICATIONS"), footer: Text(allNotificationsFooter)) {
            SettingsToggle(String(localized: "Allow Notifications"), isOn: $adhanSettings.notificationsEnabled)
        }
        if adhanSettings.notificationsEnabled {
            enabledNotificationSections
        }
    }

    private var allNotificationsFooter: String {
        adhanSettings.notificationsEnabled
            ? String(localized: "Off, the app sends nothing: no prayer alerts or adhan, no nagging, no Islamic dates, and no reminders of any kind. Every choice below is kept for when it comes back on.")
            : String(localized: "Every notification from the app is off. Your choices are kept; turn this on to bring them back.")
    }

    /// The door rows' caption (Settings, Prayer Settings): what the page holds, or that it is all off.
    static var doorSubtitle: String {
        Settings.shared.notificationsEnabled
            ? String(localized: "Prayer alerts, adhan sounds, reminders")
            : String(localized: "All notifications are off")
    }

    @ViewBuilder
    private var enabledNotificationSections: some View {
                #if os(iOS)
                Section(header: Text("PERMISSION")) {
                    permissionCard
                }
                #else
                // watchOS has no detailed permission card UI; offer a simple request-access row instead.
                Section(header: Text("PERMISSION")) {
                    Label("Request Access", systemImage: "checkmark.seal")
                        .font(.subheadline)
                        .foregroundColor(settings.accentColor.color)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settings.hapticFeedback()
                            Task { @MainActor in await onRequestAccessTapped() }
                        }
                }
                #endif

                // The two doors first: they are what most people come here for. Each row says
                // where it stands, so the common check needs no push.
                Section(header: Text("PRAYERS")) {
                    NavigationLink(destination: LazyDestination { MoreNotificationView() }) {
                        SettingsRowLabel(title: String(localized: "Prayer Notifications"), systemImage: "bell.fill",
                                         subtitle: prayerNotificationsSummary.localizedDigits, tint: SettingsTint.notifications)
                    }
                    .tint(settings.accentColor.color)

                    // The mode is the app's most unusual notification feature and was its hardest to
                    // find; a row of its own here, beside the prayers it reminds about.
                    NavigationLink(destination: LazyDestination { NaggingModeView() }) {
                        SettingsRowLabel(title: String(localized: "Nagging Mode"),
                                         systemImage: SettingsNotificationsPage.naggingMode.systemImage,
                                         subtitle: SettingsNotificationsPage.naggingMode.caption,
                                         tint: SettingsTint.notifications,
                                         value: NaggingModeView.statusValue(settings))
                    }
                    .tint(settings.accentColor.color)
                }

                #if os(iOS)
                Section(header: Text("ADHAN"),
                        footer: Text("A notification can play 30 seconds of the adhan; the app plays it in full.")) {
                    Picker("Adhan Sound", selection: $adhanSettings.adhanNotificationSound) {
                        // Two groups, not one run of nineteen names: the tones (with Default, the same
                        // six the ALERT TONE picker offers) and then the calls to prayer.
                        Section {
                            ForEach(Settings.supportedAlertTones) { option in
                                Text(option.title).tag(option.id)
                            }
                        } header: {
                            Text("Tones")
                                .foregroundStyle(.secondary)
                        }
                        Section {
                            ForEach(Settings.supportedAdhanRecordings) { option in
                                Text(option.title.localizedDigits).tag(option.id)
                            }
                        } header: {
                            Text("Adhans")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: settings.adhanNotificationSound) { _ in
                        settings.hapticFeedback()
                        stopAdhanPreview()
                    }

                    if notificationSoundsDisabled {
                        Label {
                            SettingsCaption(String(localized: "Notification sounds are off in iPhone Settings, so the adhan will be silent."))
                        } icon: {
                            Image(systemName: "speaker.slash.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    if settings.adhanNotificationSound != "default" {
                        Label(isPreviewingAdhan ? String(localized: "Stop Preview") : String(localized: "Preview Sound"),
                              systemImage: isPreviewingAdhan ? "stop.circle.fill" : "play.circle.fill")
                            .foregroundColor(settings.accentColor.color)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                settings.hapticFeedback()
                                if isPreviewingAdhan {
                                    stopAdhanPreview()
                                } else {
                                    playAdhanPreview()
                                }
                            }

                        // The in-app adhan's two switches, together and in plain sight (Abu,
                        // 2026-10-19). With "Default" chosen there is no recording for either to
                        // act on, so they stay out of the way.
                        SettingsToggle(String(localized: "Play Automatically"), caption: String(localized: "Starts the full adhan when the app is open at prayer time, or opened within five minutes of it. Off, a Play button appears instead."), isOn: $adhanSettings.adhanAutoPlayInApp)

                        if settings.adhanAutoPlayInApp {
                            SettingsToggle(String(localized: "Play in Silent Mode"), caption: String(localized: "Plays even with the phone silenced. Off, a silenced phone gets a Play button instead."), isOn: $adhanSettings.adhanOverridesSilentMode)
                            .settingsDependent()
                        }
                    }
                }

                Section(header: Text("ALERT TONE"),
                        footer: Text("For prenotifications, the optional times and any prayer with the adhan off. Chime, Ring and Alarm carry through noise.")) {
                    Picker("Alert Tone", selection: $adhanSettings.alertToneSound) {
                        Section {
                            // Tones only, no adhans: this sound plays exactly where the adhan was
                            // declined (prenotifications, optional times, adhan-off prayers).
                            ForEach(Settings.supportedAlertTones) { option in
                                Text(option.title).tag(option.id)
                            }
                        } header: {
                            Text("Alert Tone")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: settings.alertToneSound) { _ in
                        settings.hapticFeedback()
                        stopAdhanPreview()
                    }

                    if settings.alertToneSound != "default" {
                        Label(isPreviewingAdhan ? String(localized: "Stop Preview") : String(localized: "Preview Tone"),
                              systemImage: isPreviewingAdhan ? "stop.circle.fill" : "play.circle.fill")
                            .foregroundColor(settings.accentColor.color)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                settings.hapticFeedback()
                                if isPreviewingAdhan {
                                    stopAdhanPreview()
                                } else {
                                    playAlertTonePreview()
                                }
                            }
                    }
                }
                #endif

                Section(header: Text("MORE REMINDERS")) {
                    SettingsToggle(String(localized: "Islamic Calendar Notifications"), isOn: $adhanSettings.dateNotifications)

                    if settings.dateNotifications {
                        SettingsToggle(String(localized: "Remind a Day Before"), caption: String(localized: "A heads-up the evening before each Islamic date."), isOn: $adhanSettings.dateNotificationsDayBefore)
                        .settingsDependent()
                    }

                    #if os(iOS) && HAS_QURAN
                    // The Sunnah Reminders schedule recitations in the Quran reader, so they ship with it.
                    NavigationLink(destination: LazyDestination { SunnahRemindersView() }) {
                        SettingsRowLabel(title: String(localized: "Sunnah Reminders"), systemImage: "bell.and.waves.left.and.right.fill",
                                         subtitle: String(localized: "Al-Kahf on Friday, al-Mulk before sleep, and more"), tint: SettingsTint.notifications)
                    }
                    .tint(settings.accentColor.color)
                    #endif
                }

                #if os(iOS)
                // Last on the page (Abu, 2026-10-10): see Prayer Settings. No ADVANCED switch since
                // 2026-10-25: it hid the alert tone and the day-before reminder, three rows.
                TipsSection(area: .notifications, resolve: resolveSearchDestination)
                #endif
    }

    /// What the Prayer Notifications door leads to, at a glance: "All 5 prayers \u{00B7} 10 min before",
    /// "3 of 5 prayers", or "Off".
    private var prayerNotificationsSummary: String {
        let switches = [settings.notificationFajr, settings.notificationDhuhr, settings.notificationAsr,
                        settings.notificationMaghrib, settings.notificationIsha]
        let on = switches.filter { $0 }.count
        guard on > 0 else { return String(localized: "Off") }
        let prayers = on == 5 ? String(localized: "All 5 prayers") : String(localized: "\(on) of 5 prayers")
        let leads = Set([settings.preNotificationFajr, settings.preNotificationDhuhr, settings.preNotificationAsr,
                         settings.preNotificationMaghrib, settings.preNotificationIsha])
        if leads.count == 1, let lead = leads.first, lead > 0 {
            return String(localized: "\(prayers) \u{00B7} \(lead) min before")
        }
        return prayers
    }

    #if os(iOS)
    @ViewBuilder
    private func notificationPageDestination(_ page: SettingsNotificationsPage) -> some View {
        switch page {
        case .prayerReminders: MoreNotificationView()
        case .naggingMode: NaggingModeView()
        #if HAS_QURAN
        case .sunnahReminders: SunnahRemindersView()
        #endif
        }
    }

    private func resolveSearchDestination(_ destination: SettingsSearchEntry.Destination) -> AnyView? {
        switch destination {
        case .notificationsPage(let page): return AnyView(notificationPageDestination(page))
        case .notificationReminders: return AnyView(MoreNotificationView())
        default: return nil
        }
    }
    #endif

    #if os(iOS)
    /// At the accessibility sizes the card stacks: side by side, the pill hyphenated the title
    /// ("Per-mission") and the two buttons shrank their text to "Request A..." and "Open Sett...".
    private var permissionCardStacks: Bool { dynamicTypeSize.isAccessibilitySize }

    /// One quiet row while everything is as it should be, the full card only when something is wrong
    /// (Abu, 2026-10-10: the card's status rows and buttons led the page even when all was well).
    /// Before the status arrives the row stands in, redacted, so the page opens at its usual height and
    /// grows only in the case that needs the card.
    private var permissionCard: some View {
        Group {
            if notifSettings == nil || notificationsFullyAllowed {
                allowedRow
            } else {
                fullPermissionCard
            }
        }
        .animation(.easeInOut(duration: 0.25), value: notifSettings?.authorizationStatus.rawValue)
    }

    /// Allowed, with alerts and sounds on. Provisional or quiet delivery still gets the full card.
    private var notificationsFullyAllowed: Bool {
        guard let notifSettings else { return false }
        return notifSettings.authorizationStatus == .authorized
            && notifSettings.alertSetting == .enabled
            && notifSettings.soundSetting == .enabled
    }

    /// The card's Open Settings, as the whole row.
    private var allowedRow: some View {
        Button {
            settings.hapticFeedback()
            openSystemSettings()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(settings.accentColor.color)
                    .accessibilityHidden(true)

                Text("Notifications Allowed")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.forward.app")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .redacted(reason: notifSettings == nil ? .placeholder : [])
        .accessibilityHint("Opens this app's notification settings")
    }

    private var fullPermissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if permissionCardStacks {
                    VStack(alignment: .leading, spacing: 8) {
                        permissionTitle
                        permissionPill
                    }
                } else {
                    HStack {
                        permissionTitle

                        Spacer()

                        permissionPill
                            .padding(.trailing, -6)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: permissionPillText)

            // Always present - not gated on the async fetch - so the card renders at its final
            // height from the FIRST frame. The rows used to appear only once the notification
            // settings arrived, which visibly grew the card (and the sheet around it) right after
            // opening. Redacted placeholders hold the exact space while the fetch is in flight.
            VStack(spacing: 8) {
                infoRow(String(localized: "Status"), notifSettings.map { statusText($0.authorizationStatus) } ?? String(localized: "Allowed"))
                infoRow(String(localized: "Alerts"), notifSettings.map { notificationSettingText($0.alertSetting) } ?? String(localized: "On"))
                infoRow(String(localized: "Sounds"), notifSettings.map { notificationSettingText($0.soundSetting) } ?? String(localized: "On"))
            }
            .font(.footnote)
            .redacted(reason: notifSettings == nil ? .placeholder : [])

            if permissionCardStacks {
                VStack(spacing: 10) {
                    requestAccessButton
                    openSettingsButton
                }
            } else {
                HStack(spacing: 10) {
                    requestAccessButton
                    openSettingsButton
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                // The reading theme's card color when there is one (the system card was white on Sepia).
                .fill(appearance.themeRowBackground ?? Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.25), value: notifSettings?.authorizationStatus.rawValue)
    }

    private var permissionTitle: some View {
        Label("Permission", systemImage: "bell.badge")
            .font(.headline)
            .foregroundColor(settings.accentColor.color)
    }

    private var permissionPill: some View {
        Text(permissionPillText)
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Capsule().fill(permissionPillColor))
            .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 1))
    }

    // Plain-style Buttons, which a List row lets each answer its own taps (default-style ones in one
    // row all fire together). They were tap gestures, which VoiceOver read as the symbol's name
    // ("Verified") and a caption rather than as a button.
    private var requestAccessButton: some View {
        Button {
            settings.hapticFeedback()
            Task { @MainActor in
                await onRequestAccessTapped()
            }
        } label: {
            smallButton(String(localized: "Request Access"), systemImage: "checkmark.seal")
        }
        .buttonStyle(.plain)
    }

    private var openSettingsButton: some View {
        Button {
            settings.hapticFeedback()
            openSystemSettings()
        } label: {
            smallButton(String(localized: "Open Settings"), systemImage: "gear")
        }
        .buttonStyle(.plain)
    }
    #endif

    private var permissionPillText: String {
        statusText(notifSettings?.authorizationStatus ?? .notDetermined)
    }

    private var permissionPillColor: Color {
        guard let status = notifSettings?.authorizationStatus else { return .secondary }
        switch status {
        case .authorized, .provisional, .ephemeral:
            return settings.accentColor.color
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .secondary
        }
    }

    private func infoRow(_ left: String, _ right: String) -> some View {
        HStack {
            Text(left)
                .foregroundColor(.secondary)

            Spacer()

            Text(right)
                .foregroundColor(.primary)
        }
        // "Status, Not asked": one stop, not the label and the value apart.
        .accessibilityElement(children: .combine)
    }

    private func statusText(_ s: UNAuthorizationStatus) -> String {
        switch s {
        case .notDetermined: return String(localized: "Not asked")
        case .denied: return String(localized: "Denied")
        case .authorized: return String(localized: "Allowed")
        case .provisional: return String(localized: "Provisional")
        case .ephemeral: return String(localized: "Ephemeral")
        @unknown default: return String(localized: "Unknown")
        }
    }

    private func notificationSettingText(_ s: UNNotificationSetting) -> String {
        switch s {
        case .enabled: return String(localized: "On")
        case .disabled: return String(localized: "Off")
        case .notSupported: return String(localized: "N/A")
        @unknown default: return String(localized: "Unknown")
        }
    }

    /// The watch never stacks these. A function rather than the literal `false`: with the literal,
    /// the watchOS compile of this shared file warned "will never be executed" (Quality Guide T1).
    private var smallButtonsStack: Bool {
        #if os(iOS)
        return permissionCardStacks
        #else
        return false
        #endif
    }

    private func smallButton(_ title: String, systemImage: String) -> some View {
        let stacks = smallButtonsStack
        return HStack(spacing: 6) {
            // Hidden: SF Symbols carry their own traits, and checkmark.seal made the button
            // "Request Access, selected".
            Image(systemName: systemImage)
                .accessibilityHidden(true)

            Text(title)
                .font(.footnote.weight(.semibold))
                .lineLimit(stacks ? nil : 1)
                .minimumScaleFactor(stacks ? 1 : 0.5)
        }
        // Full width once the buttons stack, so the pair reads as one column of equal targets.
        .frame(maxWidth: stacks ? .infinity : nil, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(settings.accentColor.color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(settings.accentColor.color.opacity(0.35), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func openSystemSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #endif
    }

    @MainActor
    private func refresh() async {
        let center = UNUserNotificationCenter.current()
        notifSettings = await center.notificationSettings()
    }

    private func requestAuthorizationAndFetchPrayerTimes() {
        settings.requestNotificationAuthorization {
            settings.fetchPrayerTimes {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if settings.showNotificationAlert {
                        showAlert = true
                    }
                }
            }
        }
    }

    @MainActor
    private func onRequestAccessTapped() async {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()
        switch current.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            requestAccessAlertMessage = String(localized: "Notifications are already turned on.")
        case .denied:
            requestAccessAlertMessage = String(localized: "Notifications are turned off. Open Settings to enable them.")
        case .notDetermined:
            _ = await settings.requestNotificationAuthorization()
            await refresh()
        @unknown default:
            requestAccessAlertMessage = String(localized: "Unable to change notification settings.")
        }
    }

    #if os(iOS)
    /// Previews the full adhan rather than the 30-second notification cut, so it can run for several
    /// minutes - hence the stop control instead of a fire-and-forget tap.
    private func playAdhanPreview() {
        playPreview(resource: settings.adhanFullSoundResource(for: settings.adhanNotificationSound))
    }

    /// Previews the alert tone, using the same `-short` cut a notification actually plays rather than the
    /// full recording - the point of the preview is to hear what the notification will sound like.
    private func playAlertTonePreview() {
        let filename = settings.alertToneSoundFilename(for: settings.alertToneSound)
        playPreview(resource: filename.map { String($0.dropLast(4)) })   // strip ".caf"
    }

    private func playPreview(resource: String?) {
        stopAdhanPreview()

        guard let resource,
              let path = Bundle.main.path(forResource: resource, ofType: "caf") else { return }

        do {
            // Decoding the file touches no audio hardware, so the player is made here; it is prepared
            // on the lane below, because `prepareToPlay()` activates the session itself when nothing
            // has yet (AVAudioSession_iOS.mm:978), the same hang risk as the activation (2026-10-12).
            let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            previewPlayer = player
            isPreviewingAdhan = true

            let duration = player.duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.25) {
                if previewPlayer === player {
                    stopAdhanPreview()
                }
            }

            // Configuring and activating the session blocks the caller for hundreds of milliseconds -
            // a visible hang on the main thread (Xcode's "AVAudioSession Hang Risk"). It runs on the
            // shared serial lane and the preview starts in its completion, so the order (category,
            // activation, play) is unchanged; the identity check drops the start if the preview was
            // stopped while we were activating.
            AudioSessionLane.queue.async {
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playback, mode: .default, options: [.duckOthers])
                    try session.setActive(true)
                } catch {
                    // Still play: a failed activation usually means another app holds the session,
                    // and a quiet preview beats a swallowed one.
                    logger.error("Adhan preview session failed: \(error.localizedDescription)")
                }
                // Preload the buffers here, off the main thread, with the session already active.
                player.prepareToPlay()
                DispatchQueue.main.async {
                    guard previewPlayer === player else { return }   // stopped while we activated
                    player.play()
                }
            }
        } catch {
            logger.error("Adhan preview playback failed: \(error.localizedDescription)")
        }
    }

    private func stopAdhanPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        isPreviewingAdhan = false
        // Same lane as the activation, so a stop that lands while the preview is still activating is
        // applied after it rather than racing ahead of it and leaving the session live.
        AudioSessionLane.queue.async {
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }
    #endif
}

struct MoreNotificationView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var showAlert: Bool = false

    /// A prayer with a row on this screen: its switch and its lead time, by key path, so one list
    /// serves the five prayers, Shurooq and whichever optional times the Adhan tab shows.
    private struct PrayerRow: Identifiable {
        let name: String
        let notification: ReferenceWritableKeyPath<Settings, Bool>
        let lead: ReferenceWritableKeyPath<Settings, Int>
        var id: String { name }
    }

    /// In the day's order. The optional times appear only while they are shown on the Adhan tab,
    /// since a notification for a time the app does not display would be a surprise.
    private var rows: [PrayerRow] {
        var list: [PrayerRow] = [
            .init(name: "Fajr", notification: \.notificationFajr, lead: \.preNotificationFajr),
            .init(name: "Shurooq", notification: \.notificationSunrise, lead: \.preNotificationSunrise),
        ]
        if settings.showDuha {
            list.append(.init(name: "Duhaa", notification: \.notificationDuha, lead: \.preNotificationDuha))
        }
        list += [
            .init(name: "Dhuhr", notification: \.notificationDhuhr, lead: \.preNotificationDhuhr),
            .init(name: "Asr", notification: \.notificationAsr, lead: \.preNotificationAsr),
            .init(name: "Maghrib", notification: \.notificationMaghrib, lead: \.preNotificationMaghrib),
            .init(name: "Isha", notification: \.notificationIsha, lead: \.preNotificationIsha),
        ]
        if settings.showIslamicMidnight {
            list.append(.init(name: "Islamic Midnight", notification: \.notificationIslamicMidnight, lead: \.preNotificationIslamicMidnight))
        }
        if settings.showLastThird {
            list.append(.init(name: "Last Third", notification: \.notificationLastThird, lead: \.preNotificationLastThird))
        }
        return list
    }

    /// The five obligatory prayers, which the All Prayers switch and lead govern. Shurooq and the
    /// optional times keep their own rows: nobody wants a Shurooq alert because they wanted Fajr's.
    private static let obligatory = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    private var obligatoryRows: [PrayerRow] { rows.filter { Self.obligatory.contains($0.name) } }

    private var allPrayersOn: Bool { obligatoryRows.allSatisfy { settings[keyPath: $0.notification] } }

    private var allPrayersBinding: Binding<Bool> {
        Binding(
            get: { allPrayersOn },
            set: { newValue in
                withAnimation {
                    for row in obligatoryRows { settings[keyPath: row.notification] = newValue }
                }
            }
        )
    }

    /// The lead every obligatory prayer shares, or Fajr's when they differ (the stepper then moves
    /// them all onto one value, which is what a stepper on an "all" row means).
    private var allLeadsBinding: Binding<Int> {
        Binding(
            get: { settings.preNotificationFajr },
            set: { newValue in
                withAnimation {
                    for row in obligatoryRows { settings[keyPath: row.lead] = newValue }
                }
            }
        )
    }

    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<Settings, T>) -> Binding<T> {
        Binding(get: { settings[keyPath: keyPath] }, set: { settings[keyPath: keyPath] = $0 })
    }

    static func leadText(_ minutes: Int) -> String {
        minutes == 0 ? String(localized: "At the time") : String(localized: "\(minutes) min before")
    }

    /// The symbol each prayer's row wears: the Manual Offsets steppers' for the daily prayers, the
    /// Optional Prayers switches' for the optional times.
    private static func symbol(for prayer: String) -> String {
        switch prayer {
        case "Fajr": return "sunrise"
        case "Shurooq": return "sunrise.fill"
        case "Duhaa": return "sun.haze.fill"
        case "Dhuhr": return "sun.max"
        case "Asr": return "sun.min"
        case "Maghrib": return "sunset"
        case "Isha": return "moon"
        case "Islamic Midnight": return "moon.fill"
        case "Last Third": return "moon.stars.fill"
        default: return "bell.fill"
        }
    }

    /// The row's trailing read-out: "10 min before \u{00B7} Adhan", "At the time \u{00B7} Tone", "Off".
    private func summary(for row: PrayerRow) -> String {
        guard settings[keyPath: row.notification] else { return String(localized: "Off") }
        var parts = [Self.leadText(settings[keyPath: row.lead])]
        if Settings.adhanEligiblePrayerNames.contains(row.name), settings.adhanNotificationSound != "default" {
            if settings.playsAdhanSound(forPrayer: row.name) {
                parts.append(settings.adhanClipLength(forPrayer: row.name) == .short ? String(localized: "Short adhan") : String(localized: "Adhan"))
            } else {
                parts.append(String(localized: "Tone"))
            }
        }
        return parts.joined(separator: JoinSeparator.dot)
    }

    var body: some View {
        #if DEBUG && os(iOS)
        ScrollViewReader { proxy in
            notificationBody
                // "-scrollToEnglishMeanings": the WORDING section sits below the fold, and a simulator
                // screenshot cannot scroll.
                .onAppear {
                    guard ProcessInfo.processInfo.arguments.contains("-scrollToEnglishMeanings") else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { proxy.scrollTo("englishMeanings", anchor: .center) }
                    }
                }
        }
        #else
        notificationBody
        #endif
    }

    // Revamped 2026-10-19 (Abu: "too complicated and ugly"). It was a Nagging Mode door (its third),
    // a wording switch, an all-prayers switch that read OFF while five of six were on (Shurooq counted),
    // and then nine identical four-control blocks behind Advanced Settings, five of which vanished
    // whenever a nagging deadline was on, so Isha's adhan could not be turned off while Isha was being
    // nagged about. Now: the all-prayers controls, one row per prayer with its state as the value and
    // its own page behind it, and the wording switch. Nothing hides, so no Advanced switch.
    private var notificationBody: some View {
        List {
            Group {
            Section(header: Text("ALL PRAYERS"), footer: Text("Sets the five prayers at once. Each one can differ below.")) {
                SettingsToggle(String(localized: "All Prayers"), isOn: allPrayersBinding)

                Stepper(value: allLeadsBinding, in: 0...120, step: 1) {
                    HStack {
                        Text("Remind Before")
                        Spacer()
                        Text(Self.leadText(settings.preNotificationFajr))
                            .foregroundColor(settings.accentColor.color)
                            .monospacedDigit()
                    }
                }
            }

            Section(header: Text("EACH PRAYER")) {
                ForEach(rows) { row in
                    NavigationLink(destination: LazyDestination {
                        PrayerNotificationDetailView(prayerName: row.name,
                                                     preNotificationTime: binding(row.lead),
                                                     isNotificationOn: binding(row.notification))
                    }) {
                        // The row grammar every settings link uses (chip, title, value), with the
                        // Manual Offsets page's symbol for each prayer.
                        SettingsRowLabel(title: row.name.localizedDisplay, systemImage: Self.symbol(for: row.name),
                                         tint: SettingsTint.notifications, value: summary(for: row))
                    }
                    .tint(settings.accentColor.color)
                }
            }

            // The gloss is part of every prayer notification's wording, and a nag body names the
            // prayer too, so this applies whatever else is on.
            Section(header: Text("WORDING")) {
                SettingsToggle(String(localized: "Show English Meanings"), caption: String(localized: "\u{201C}Time for Maghrib (sunset)\u{201D}. Shurooq and Jumuah always name theirs."), isOn: $adhanSettings.prayerNotificationEnglishNames)
                #if DEBUG
                // On the ROW, not on the Toggle nested inside the VStack: `scrollTo` targets a list
                // row, and an id buried in a row's subview is not one.
                .id("englishMeanings")
                #endif
            }
            }
            .themedListRowBackground()
        }
        .onAppear {
            settings.requestNotificationAuthorization {
                settings.fetchPrayerTimes() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if settings.showNotificationAlert {
                            showAlert = true
                        }
                    }
                }
            }
        }
        // Same rule as the notifications root above: on becoming active only, never on `.inactive`
        // (Control Center, a banner) or on the way to the background.
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            settings.requestNotificationAuthorization {
                settings.fetchPrayerTimes() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if settings.showNotificationAlert {
                            showAlert = true
                        }
                    }
                }
            }
        }
        .onDisappear {
            settings.fetchPrayerTimes(notification: true)
        }
        .confirmationDialog("Notifications Off", isPresented: $showAlert, titleVisibility: .visible) {
            Button("Open Settings") {
                settings.hapticFeedback()
                #if os(iOS)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                #endif
            }
            Button("Ignore") { }
        } message: {
            Text("Please go to Settings and enable notifications to be notified of prayer times.")
        }
        .applyConditionalListStyle()
        .navigationTitle("Prayer Notifications")
    }
}

/// One prayer's page: its switch, its lead time, and (for the five prayers, with a recording chosen)
/// whether its notification calls the adhan, in full or short. What used to be one of nine identical
/// blocks stacked on Prayer Notifications.
struct PrayerNotificationDetailView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    let prayerName: String

    @Binding var preNotificationTime: Int
    @Binding var isNotificationOn: Bool

    private var travelNotificationCaption: String? {
        switch prayerName {
        case "Dhuhr":
            return String(localized: "Also the combined traveling Dhuhr/Asr prayer.")
        case "Maghrib":
            return String(localized: "Also the combined traveling Maghrib/Isha prayer.")
        default:
            return nil
        }
    }

    /// Only the five daily prayers carry an adhan. Shurooq and the optional times always use the alert
    /// tone (see `prayerNotificationSound`), so they get no adhan controls at all.
    private var adhanSound: ReferenceWritableKeyPath<Settings, Bool>? {
        switch prayerName {
        case "Fajr":    return \.adhanSoundFajr
        case "Dhuhr":   return \.adhanSoundDhuhr
        case "Asr":     return \.adhanSoundAsr
        case "Maghrib": return \.adhanSoundMaghrib
        case "Isha":    return \.adhanSoundIsha
        default:        return nil
        }
    }

    private var shortAdhan: ReferenceWritableKeyPath<Settings, Bool>? {
        switch prayerName {
        case "Fajr":    return \.shortAdhanFajr
        case "Dhuhr":   return \.shortAdhanDhuhr
        case "Asr":     return \.shortAdhanAsr
        case "Maghrib": return \.shortAdhanMaghrib
        case "Isha":    return \.shortAdhanIsha
        default:        return nil
        }
    }

    /// With "Default" chosen there is no recording to play or shorten, so the adhan controls have
    /// nothing to act on and are hidden rather than shown doing nothing.
    private var hasAdhanRecording: Bool { settings.adhanNotificationSound != "default" }

    private func binding(_ keyPath: ReferenceWritableKeyPath<Settings, Bool>) -> Binding<Bool> {
        Binding(get: { settings[keyPath: keyPath] }, set: { settings[keyPath: keyPath] = $0 })
    }

    var body: some View {
        List {
            Group {
                Section {
                    SettingsToggle(String(localized: "Notification"), isOn: $isNotificationOn)

                    if isNotificationOn {
                        Stepper(value: $preNotificationTime, in: 0...120, step: 1) {
                            HStack {
                                Text("Remind Before")
                                Spacer()
                                Text(MoreNotificationView.leadText(preNotificationTime))
                                    .foregroundColor(settings.accentColor.color)
                                    .monospacedDigit()
                            }
                        }
                    }
                } header: {
                    Text("NOTIFICATION")
                } footer: {
                    if let travelNotificationCaption {
                        Text(travelNotificationCaption)
                    }
                }

                if isNotificationOn, hasAdhanRecording, let adhanSound {
                    Section(header: Text("SOUND")) {
                        SettingsToggle(String(localized: "Play Adhan"), caption: String(localized: "Off, this prayer gets the alert tone while the others still call the adhan."), isOn: binding(adhanSound))

                        // Nothing to shorten once the adhan itself is off.
                        if settings[keyPath: adhanSound], let shortAdhan {
                            SettingsToggle(String(localized: "Short Adhan"), caption: String(localized: "A brief excerpt instead of the adhan's first 30 seconds."), isOn: binding(shortAdhan))
                            .settingsDependent()
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(prayerName.localizedDisplay)
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: true) {
        SettingsAdhanView(showNotifications: true)
    }
}

#if os(iOS)
// MARK: - Settings-search entries (kept in THIS file, next to the screens they describe)
extension SettingsSearchEntry {
    static let notificationEntries: [SettingsSearchEntry] = sunnahReminderEntries + [
        .init(title: "Notification Settings", path: "Notifications", keywords: "alerts permission bell", destination: .notifications),
        .init(title: "Allow Notifications", path: "Notifications", keywords: "all notifications off on master switch mute silence everything turn off disable stop none", destination: .notifications),
        .init(title: "Notification Permission", path: "Notifications", keywords: "allow access permission status sounds badges denied", destination: .notifications),
        .init(title: "Adhan Sound", path: "Notifications", keywords: "athan azan sound mecca madinah preview", destination: .notifications),
        .init(title: "Play Adhan Automatically", path: "Notifications", keywords: "automatic auto play in-app adhan full recording open app five minutes play button offer", destination: .notifications),
        .init(title: "Play in Silent Mode", path: "Notifications", keywords: "silent mode ringer switch mute action button in-app adhan sound", destination: .notifications),
        .init(title: "Alert Tone", path: "Notifications", keywords: "tone chime ding sound reminder alert", destination: .notifications),
        .init(title: "Hijri Calendar Notifications", path: "Notifications", keywords: "islamic events eid ramadan reminders", destination: .notifications),
        .init(title: "Remind a Day Before", path: "Notifications", keywords: "islamic dates day before tomorrow ramadan eid heads up early", destination: .notifications),
        .init(title: "Prayer Reminders & Pre-Notifications", path: "Notifications → Prayer Notifications", keywords: "before minutes early alert all prayers prenotification remind", destination: .notificationsPage(.prayerReminders)),
        .init(title: "Per-Prayer Notifications & Adhan", path: "Notifications → Prayer Notifications", keywords: "per prayer each fajr dhuhr asr maghrib isha own sound short adhan play adhan prenotification duhaa midnight last third", destination: .notificationsPage(.prayerReminders)),
        .init(title: "Nagging Mode", path: "Notifications → Nagging Mode", keywords: "nag repeat reminders pray on time cascade did you pray tracker deadline window closes midnight isha fajr shurooq struggle lazy miss prayers accountability", destination: .notificationsPage(.naggingMode)),
        .init(title: "Nagging Start Time & Repeat Interval", path: "Notifications → Nagging Mode", keywords: "nag lead start minutes before hour repeat every interval spacing how often frequency last calls final reminders 10 5", destination: .notificationsPage(.naggingMode), advanced: true),
        .init(title: "Different Nagging Start for Each Prayer", path: "Notifications → Nagging Mode", keywords: "nag per prayer custom lead fajr shurooq asr maghrib isha midnight individual", destination: .notificationsPage(.naggingMode), advanced: true),
        .init(title: "Check In After the Adhan", path: "Notifications → Nagging Mode", keywords: "nag follow up after adhan have you prayed yet early start of time beginning reminder later", destination: .notificationsPage(.naggingMode), advanced: true),
        .init(title: "Nag Tone & Louder Last Call", path: "Notifications → Nagging Mode", keywords: "nag sound tone alarm loud louder final last call escalate chime ring echo takbir", destination: .notificationsPage(.naggingMode), advanced: true),
        .init(title: "Add a Verse to the Last Call", path: "Notifications → Nagging Mode", keywords: "nag ayah verse quran wording reminder motivation last call", destination: .notificationsPage(.naggingMode), advanced: true),
        .init(title: "Pause Nagging", path: "Notifications → Nagging Mode", keywords: "pause snooze silence hold sick travel flight day week resume nag", destination: .notificationsPage(.naggingMode)),
        .init(title: "Show English Meanings", path: "Notifications → Prayer Notifications", keywords: "english translation meaning sunset dawn midday afternoon night maghrib notification wording name", destination: .notificationsPage(.prayerReminders)),
    ]

    /// The Sunnah Reminders' entry, where the Quran reader ships (`HAS_QURAN`): Al-Adhan has no such page.
    private static var sunnahReminderEntries: [SettingsSearchEntry] {
        #if HAS_QURAN
        return [.init(title: "Sunnah Reminders (Notifications)", path: "Notifications → Sunnah Reminders", keywords: "al-kahf friday al-mulk sleep muawwidhat hadith reminder", destination: .notificationsPage(.sunnahReminders))]
        #else
        return []
        #endif
    }

    /// The weather's entry, in Al-Islam alone (`HAS_WEATHER`): the companion apps have no switch to find.
    private static var weatherEntries: [SettingsSearchEntry] {
        #if HAS_WEATHER
        return [.init(title: "Weather on the Sky", path: "Prayer Settings → Sky", keywords: "weather temperature temp uv index humidity wind clouds rain snow fog forecast apple weather conditions feels like degrees", destination: .prayerPage(.sky))]
        #else
        return []
        #endif
    }

    static let adhanEntries: [SettingsSearchEntry] = weatherEntries + [
        .init(title: "Prayer Settings", path: "Al-Adhan", keywords: "salah salat times adhan", destination: .prayerSettings),
        .init(title: "Prayer Tracker on the Adhan Tab", path: "Prayer Settings", keywords: "prayer tracker show hide remove collapse fold put away card streak checklist marks adhan tab", destination: .prayerSettings),
        .init(title: "At a Glance on the Adhan Tab", path: "Prayer Settings", keywords: "at a glance tiles show hide remove collapse fold put away qibla daylight fasting moon distance simple mode adhan tab", destination: .prayerSettings),
        .init(title: "Need a Hand? on the Adhan Tab", path: "Prayer Settings", keywords: "need a hand help shortcuts questions show hide adhan tab need help praying traveling sky nagging", destination: .prayerSettings, isAvailable: { !Settings.shared.hides(.pageHelpDoors) }),
        .init(title: "Prayer Times Layout", path: "Prayer Settings", keywords: "tiles grid list split layout columns prayer times view display", destination: .prayerSettings),
        .init(title: "Traveling Mode (Qasr)", path: "Prayer Settings → Traveling Mode", keywords: "travel shorten combine journey safar 48 miles automatic", destination: .prayerPage(.travelingMode)),
        .init(title: "Show Full Prayers", path: "Prayer Settings → Traveling Mode", keywords: "full prayers qasr shorten combine traveling travel", destination: .prayerPage(.travelingMode)),
        .init(title: "Optional Prayer Times", path: "Prayer Settings → Optional Prayers", keywords: "duha duhaa islamic midnight last third night tahajjud suhoor", destination: .prayerPage(.optionalPrayers)),
        .init(title: "Manual Prayer Offsets", path: "Prayer Settings → Manual Offsets", keywords: "adjust minutes plus minus tune offset", destination: .prayerPage(.manualOffsets)),
        .init(title: "Hijri Date Offset", path: "Prayer Settings → Manual Offsets", keywords: "hijri adjust day moon date calendar", destination: .prayerPage(.manualOffsets)),
        .init(title: "Switch Hijri Date at Maghrib", path: "Prayer Settings → Manual Offsets", keywords: "hijri date sunset maghrib midnight islamic day", destination: .prayerPage(.manualOffsets)),
        .init(title: "Custom Prayer Names", path: "Prayer Settings → Custom Prayer Names", keywords: "rename spelling fadjr salah names", destination: .prayerPage(.customPrayerNames)),
        .init(title: "Show Sky (Sun Arc, Moon, Stars)", path: "Prayer Settings → Sky", keywords: "sky card sun arc moon phase stars countdown adhan tab", destination: .prayerPage(.sky)),
        .init(title: "Sky Fills the Screen", path: "Prayer Settings → Sky", keywords: "sky whole tab background full screen fill page gradient behind everything glass rows adhan tab color", destination: .prayerPage(.sky)),
        .init(title: "Skyline (Mosque, Pyramids, Palms)", path: "Prayer Settings → Sky", keywords: "skyline scene silhouette mosque pyramids palm trees sun moon horizon widgets", destination: .prayerPage(.sky)),
        .init(title: "Sky Colors", path: "Prayer Settings → Sky → Sky Colors", keywords: "background gradient sunrise sunset theme sky colors", destination: .prayerPage(.skyColors)),
    ]
}
#endif

// MARK: - Prayer calculation picker (merged from PrayerCalculationListView.swift; PrayerCalculationMethods.swift stays standalone - widgets compile it too)

/// The calculation-method picker: a searchable list, one row per method, each showing the angles it actually
/// uses. Built like `ReciterListView` on purpose - it is the same shape of problem (a long list of named
/// options where the user is hunting for one), and it deserves the same affordances.
///
/// It replaced a wheel `Picker`, which could show neither the angles nor a search field, and which offered
/// only the dozen methods the Adhan package's enum happened to contain.
struct PrayerCalculationListView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared

    @State private var searchText = ""

    private var customMethod: PrayerCalculationMethod {
        PrayerCalculationCatalog.custom(
            fajrAngle: settings.customFajrAngle,
            ishaAngle: settings.customIshaAngle
        )
    }

    private var selectedID: String {
        settings.canonicalPrayerCalculationMethod(settings.prayerCalculation)
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var query: String { normalized(searchText) }
    private var isSearching: Bool { !query.isEmpty }

    /// Name, region and angles are all searchable: people look for "Karachi", for "Malaysia", and for "18".
    private func matches(_ method: PrayerCalculationMethod) -> Bool {
        guard isSearching else { return true }
        let haystack = [method.name, method.region ?? "", method.angleSummary, method.id]
            .map(normalized)
            .joined(separator: " ")
        return haystack.contains(query)
    }

    private var results: [PrayerCalculationMethod] {
        PrayerCalculationCatalog.methods.filter(matches)
    }

    var body: some View {
        List {
            Group {
                automaticSection

                if isSearching {
                    searchResultsBanner

                    if results.isEmpty && !matches(customMethod) {
                        Text("No calculation methods matched your search.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(results) { methodRow($0) }
                        if matches(customMethod) { customSection }
                    }
                } else {
                    Section(header: Text("METHODS")) {
                        ForEach(PrayerCalculationCatalog.methods) { methodRow($0) }
                    }

                    // Custom angles stay on screen while they are the method in use, whatever the
                    // switch says: a method the screen cannot show is a method nobody can change.
                    if settings.advanced(.prayerCalculation) || selectedID == PrayerCalculationCatalog.customID {
                        customSection
                    }
                    madhabAndHighLatitudeSection
                    if settings.advanced(.prayerCalculation) {
                        explanationSection
                    }
                    // The custom angles drop out of the caption while custom IS the method in use:
                    // they are on screen already, so naming them as hidden reads as a lie.
                    AdvancedSettingsSection(
                        screen: .prayerCalculation,
                        hides: selectedID == PrayerCalculationCatalog.customID
                            ? String(localized: "the high latitude rule and the notes on angles")
                            : String(localized: "the custom method with its own Fajr and Isha angles, the high latitude rule and the notes on angles"))
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Prayer Calculation")
        #if os(iOS)
        // Applied BEFORE the bottom bar below it: bottom safe-area insets stack outward, so the inset
        // added first sits nearest the content and later ones go underneath it. With the bar first, the
        // Now Playing player landed UNDER it (Abu, 2026-10-07). The Quran tab's order is the same.
        .applyConditionalListStyle()
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: $searchText.animation(.easeInOut))
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        #elseif os(watchOS)
        .searchable(text: $searchText.animation(.easeInOut))
        #endif
        #if os(watchOS)
        // The watch has no floating bottom bar to order against, so it is styled here.
        .applyConditionalListStyle()
        #endif
    }

    private var automaticSection: some View {
        Section(header: Text("AUTOMATIC")) {
            SettingsToggle(String(localized: "Choose Automatically"), caption: String(localized: "Picks the method customary in the country you are in. Choosing a method by hand below turns this off."), isOn: $adhanSettings.calculationAutomatic)
        }
    }

    private var searchResultsBanner: some View {
        HStack(spacing: 10) {
            Text("Search Results")
            Spacer()
            Text("\(results.count + (matches(customMethod) ? 1 : 0))")
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

    private func methodRow(_ method: PrayerCalculationMethod) -> some View {
        let isSelected = selectedID == method.id

        return VStack(alignment: .leading, spacing: 4) {
            // The angles lead: they are the thing that actually differs between two methods, and the reason
            // someone is on this screen at all.
            Text(method.angleSummary)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                )

            HStack {
                HighlightedSnippet(
                    source: method.name,
                    term: searchText,
                    font: .subheadline.weight(.semibold),
                    accent: settings.accentColor.color,
                    fg: isSelected ? settings.accentColor.color : .primary
                )

                Spacer(minLength: 8)

                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .opacity(isSelected ? 1 : 0)
            }

            if let region = method.region {
                SettingsCaption(region)
                    .padding(.vertical, 2)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.setPrayerCalculationManually(method.id)
            }
        }
    }

    @ViewBuilder
    private var customSection: some View {
        Section {
            methodRow(customMethod)

            // Only editable while the custom method is the one in use - otherwise these steppers would be
            // silently adjusting angles that nothing is computing with.
            if selectedID == PrayerCalculationCatalog.customID {
                Stepper(value: $adhanSettings.customFajrAngle, in: 8...25, step: 0.5) {
                    HStack {
                        Text("Fajr Angle")
                        Spacer()
                        Text(verbatim: IshaRule.degrees(settings.customFajrAngle))
                            .monospacedDigit()
                            .foregroundColor(settings.accentColor.color)
                    }
                }

                Stepper(value: $adhanSettings.customIshaAngle, in: 8...25, step: 0.5) {
                    HStack {
                        Text("Isha Angle")
                        Spacer()
                        Text(verbatim: IshaRule.degrees(settings.customIshaAngle))
                            .monospacedDigit()
                            .foregroundColor(settings.accentColor.color)
                    }
                }
            }
        } header: {
            Text("CUSTOM")
        } footer: {
            if selectedID == PrayerCalculationCatalog.customID {
                Text("Only set your own angles if you know the values your local mosque uses. A wrong angle means praying at the wrong time.")
            }
        }
    }

    /// The madhab + high-latitude controls. They lived inline on the PARENT settings screen (twice
    /// orphaned in refactors); they belong here with the rest of the calculation choices - and the
    /// settings-search index deep-links "hanafi"/"high latitude" to this screen.
    private var madhabAndHighLatitudeSection: some View {
        Section {
            SettingsToggle(String(localized: "Hanafi Calculation for Asr"), caption: String(localized: "The Hanafi madhab uses the shadow ratio of 2 to 1 for Asr, while many other schools use 1 to 1. Enable this only if you follow the Hanafi method."), isOn: $adhanSettings.hanafiMadhab)

            if settings.advanced(.prayerCalculation) {
                Picker("High Latitude Rule", selection: $adhanSettings.highLatitudeRule) {
                    Section {
                        ForEach(Settings.highLatitudeRuleOptions, id: \.self) { option in
                            Text(option.localizedDisplay).tag(option)
                        }
                    } header: {
                        Text("High Latitude Rule")
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: settings.highLatitudeRule) { _ in settings.hapticFeedback() }
            }
        } header: {
            Text(settings.advanced(.prayerCalculation) ? String(localized: "MADHAB & HIGH LATITUDE") : String(localized: "MADHAB"))
        } footer: {
            if settings.advanced(.prayerCalculation) {
                Text(highLatitudeRuleCaption)
            }
        }
    }

    private var highLatitudeRuleCaption: String {
        // Not merely a high-latitude concern: on a short summer night the rule can shift Fajr and Isha as far
        // south as Cairo (~30°N). Only in winter, or near the equator, does the choice make no difference.
        var caption = String(localized: "When the night is short, the sun never sinks low enough for the twilight that defines Fajr and Isha, so they are estimated. This matters most far from the equator, but can shift summer times at any latitude.")
        if let location = live.currentLocation, location.latitude != 1000, location.longitude != 1000 {
            caption = String(localized: "\(caption) Automatic uses \(settings.recommendedHighLatitudeRuleLabel(atLatitude: location.latitude)) in \(location.displayCity).")
        }
        return caption
    }

    private var explanationSection: some View {
        Section(header: Text("ABOUT THESE ANGLES")) {
            SettingsCaption(String(localized: "Fajr begins at true dawn and Isha at nightfall. Neither is a clock time: both are defined by how far the sun has sunk below the horizon, and the bodies below differ on where exactly to draw that line. A larger angle means an earlier Fajr and a later Isha."))
                .padding(.vertical, 2)

            SettingsCaption(String(localized: "Umm Al-Qura and Qatar use a fixed interval after Maghrib for Isha instead of an angle, because at their latitude the twilight is consistent enough for a clock to be reliable."))
                .padding(.vertical, 2)

            SettingsCaption(String(localized: "Use the method your local mosque uses. If you do not know it, leave this on automatic."))
                .padding(.vertical, 2)
        }
    }
}

#if os(iOS)
// MARK: - Settings-search entries (kept in THIS file, next to the screen they describe)
extension SettingsSearchEntry {
    static let prayerCalculationEntries: [SettingsSearchEntry] = [
        .init(title: "Prayer Calculation Method", path: "Prayer Settings → Prayer Calculation", keywords: "method angles isna mwl muslim world league egypt karachi umm al-qura makkah moonsighting jakim malaysia brunei singapore indonesia turkey diyanet automatic country", destination: .prayerPage(.prayerCalculation)),
        .init(title: "Custom Calculation Angles", path: "Prayer Settings → Prayer Calculation", keywords: "fajr angle isha angle degrees custom", destination: .prayerPage(.prayerCalculation), advanced: true),
        .init(title: "High Latitude Rule", path: "Prayer Settings → Prayer Calculation", keywords: "midnight seventh night twilight northern latitude", destination: .prayerPage(.prayerCalculation), advanced: true),
        .init(title: "Hanafi Madhab (Asr Time)", path: "Prayer Settings → Prayer Calculation", keywords: "asr later shadow madhhab school shafi", destination: .prayerPage(.prayerCalculation)),
    ]
}
#endif

