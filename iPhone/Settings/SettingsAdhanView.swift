import SwiftUI
import Adhan
import UserNotifications
#if os(iOS)
import AVFoundation
#endif

struct SettingsAdhanView: View {
    @ObservedObject var settings = Settings.shared
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

    init(showNotifications: Bool, presentedAsSheet: Bool = false, openTravelingMode: Bool = false,
         openPrayerCalculation: Bool = false, openPage: SettingsAdhanPage? = nil) {
        self._showNotifications = State(initialValue: showNotifications)
        self.presentedAsSheet = presentedAsSheet
        self.requestedPage = openTravelingMode ? .travelingMode : (openPrayerCalculation ? .prayerCalculation : openPage)
    }

    private var dialogTitle: String {
        switch showAlert {
        case .travelTurnOnAutomatic:
            return "Traveling Mode Detected"
        case .travelTurnOffAutomatic:
            return "Traveling Mode Updated"
        case .calculationAutomaticChanged:
            return "Calculation Method Changed"
        case .none:
            return ""
        }
    }

    var body: some View {
        rootList
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
        .navigationTitle("Al-Adhan Settings")
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

    @ViewBuilder
    private var autoChangeDialogButtons: some View {
        switch showAlert {
        case .travelTurnOnAutomatic:
            Button("Override: Turn Off", role: .destructive) {
                settings.hapticFeedback()
                settings.overrideTravelingMode(keepOn: false)
            }

            Button("Confirm: Keep On") {
                settings.hapticFeedback()
                settings.confirmTravelAutomaticChange()
            }

        case .travelTurnOffAutomatic:
            Button("Override: Keep On", role: .destructive) {
                settings.hapticFeedback()
                settings.overrideTravelingMode(keepOn: true)
            }

            Button("Confirm: Turn Off") {
                settings.hapticFeedback()
                settings.confirmTravelAutomaticChange()
            }

        case .calculationAutomaticChanged:
            Button("Override: Keep \(settings.calculationAutoPreviousMethod)", role: .destructive) {
                settings.hapticFeedback()
                settings.overrideAutomaticCalculationKeepingPrevious()
            }

            Button("Confirm: Use \(settings.calculationAutoDetectedMethod)") {
                settings.hapticFeedback()
                settings.confirmAutomaticCalculationChange()
            }

        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var autoChangeDialogMessage: some View {
        switch showAlert {
        case .travelTurnOnAutomatic:
            Text(settings.automaticTravelMessage(turnOn: true))
        case .travelTurnOffAutomatic:
            Text(settings.automaticTravelMessage(turnOn: false))
        case .calculationAutomaticChanged:
            Text(settings.automaticCalculationMessage)
        case .none:
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
        adhanSettingsSubList(title: "Traveling Mode") {
            travelingModeSection
        }
        .confirmationDialog(dialogTitle, isPresented: autoChangeDialogBinding, titleVisibility: .visible) {
            autoChangeDialogButtons
        } message: {
            autoChangeDialogMessage
        }
    }

    private var optionalTimesDestination: some View {
        adhanSettingsSubList(title: "Optional Prayers") {
            optionalTimesSection
        }
    }

    private var prayerOffsetsDestination: some View {
        adhanSettingsSubList(title: "Manual Offsets") {
            prayerOffsetsSection
        }
    }

    private var customPrayerNamesDestination: some View {
        adhanSettingsSubList(title: "Custom Prayer Names") {
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
        // First on every settings page (Abu, 2026-09-20): what this side of the app can do that
        // nothing on screen announces. See TipsAndTricks.swift.
        #if os(iOS)
        TipsSection(area: .adhan, resolve: resolveSearchDestination)
        #endif

        notificationsSection

        Section(header: Text("PRAYER TIMES")) {
            adhanPageLink(.prayerCalculation) { prayerCalculationDestination }
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

        // No PRAYER TRACKER section here: "Mark Only After the Time Begins" moved onto the tracker
        // itself, beneath the marks it governs (Abu, 2026-09-18). See
        // `PrayerTrackerView.settingsSection`.
        #endif
    }

    /// The Skyline row's one value: "off" while the skyline is hidden, else the style's raw value.
    /// Picking a style also turns the skyline on, so one menu covers both settings.
    private var skylineChoice: Binding<String> {
        Binding(
            get: { settings.showSkyScene ? settings.skySceneStyle : "off" },
            set: { choice in
                if choice == "off" {
                    withAnimation(.easeInOut) { settings.showSkyScene = false }
                } else {
                    settings.skySceneStyle = choice
                    if !settings.showSkyScene {
                        withAnimation(.easeInOut) { settings.showSkyScene = true }
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
    /// Sky: whether the Adhan tab draws it, its skyline, and the door to its colors.
    private var skyDestination: some View {
        List {
            Group {
                Section(header: Text("SKY")) {
                    VStack(alignment: .leading) {
                        Toggle("Show Sky", isOn: $settings.showSkyView.animation(.easeInOut))
                            .font(.subheadline)
                            .tint(settings.accentColor.color)
                            .onChange(of: settings.showSkyView) { _ in settings.hapticFeedback() }

                        Text("The sun on today's arc, the moon at its true phase, and the stars at night. Drag the sun to see any moment of the day. Turn it off for a plain Current/Upcoming card.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)
                    }
                }

                // Nothing to color, and no ground for a skyline, when the sky isn't drawn.
                if settings.showSkyView {
                    Section(header: Text("HORIZON")) {
                        VStack(alignment: .leading) {
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
                            .font(.subheadline)
                            .tint(settings.accentColor.color)
                            .onChange(of: settings.showSkyScene) { _ in settings.hapticFeedback() }
                            .onChange(of: settings.skySceneStyle) { _ in settings.hapticFeedback() }

                            Text("Pyramids to the west and a mosque to the east along the horizon, with the sun crossing by day and the moon by night. Choose the pair, only pyramids, or only mosques. Also on the Solar Arc and Day & Night widgets.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 2)
                        }
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
        Section {
            NavigationLink(destination: LazyDestination { NotificationView() }) {
                SettingsRowLabel(title: "Notification Settings", systemImage: "bell.badge.fill",
                                 subtitle: "Prayer alerts, adhan sounds, reminders", tint: SettingsTint.notifications)
            }
            .tint(settings.accentColor.color)
        }
        #endif
    }

    @ViewBuilder
    private var optionalTimesSection: some View {
        Section(header: Text("OPTIONAL PRAYERS")) {
            optionalPrayerToggle(
                title: "Duhaa",
                subtitle: "A voluntary forenoon prayer after sunrise and before Dhuhr.",
                icon: "sun.haze.fill",
                isOn: $settings.showDuha
            )

            optionalPrayerToggle(
                title: "Islamic Midnight",
                subtitle: "Halfway between Maghrib and the next Fajr. It marks the end of Isha.",
                icon: "moon.fill",
                isOn: $settings.showIslamicMidnight
            )

            optionalPrayerToggle(
                title: "Last Third of Night",
                subtitle: "The final third before Fajr is a blessed time for dua and forgiveness.",
                icon: "moon.stars.fill",
                isOn: $settings.showLastThird
            )
        }
    }

    private func optionalPrayerToggle(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn.animation(.easeInOut)) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 22, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 2)
                }
            }
        }
        .font(.subheadline)
        .tint(settings.accentColor.color)
        .onChange(of: isOn.wrappedValue) { _ in settings.hapticFeedback() }
    }

    // The madhab + high-latitude controls moved INTO PrayerCalculationListView (they are calculation
    // choices; inline on this root they read as a stray orphan section). Kept nowhere else - the
    // settings-search index deep-links both to that screen.

    private var travelingModeSection: some View {
        Section(header: Text("TRAVELING MODE")) {
            homeCityButton
            automaticTravelToggle
            travelingModeGroup
        }
    }

    @ViewBuilder
    private var homeCityButton: some View {
        #if os(iOS)
        HStack(spacing: 8) {
            Text("Set Home City")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)

            Spacer(minLength: 8)

            if let city = settings.homeLocation?.city, !city.isEmpty {
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
        Toggle("Automatic Traveling Mode", isOn: $settings.travelAutomatic.animation(.easeInOut))
            .font(.subheadline)
            .tint(settings.accentColor.color)
            .onChange(of: settings.travelAutomatic) { _ in settings.hapticFeedback() }
        #endif
    }

    private var travelingModeGroup: some View {
        VStack(alignment: .leading) {
            Toggle("Traveling Mode", isOn: travelingModeBinding.animation(.easeInOut))
                .font(.subheadline)
                .tint(settings.accentColor.color)
                .disabled(settings.travelAutomatic && !isWatch)
                .onChange(of: settings.travelingMode) { _ in settings.hapticFeedback() }

            #if os(iOS)
            Text("If you are traveling more than 48 mi (77.25 km), then it is obligatory to pray Qasr, where you combine Dhuhr and Asr (2 rakahs each) and Maghrib and Isha (3 and 2 rakahs). Allah said in the Quran, “When you travel through the land, it is permissible for you to shorten the prayer” [Quran 4:101]. \(settings.travelAutomatic ? "This feature turns on and off automatically, but you can also control it manually here." : "You can control traveling mode manually here.")")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
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
    @ViewBuilder
    private var prayerOffsetsSection: some View {
        // The Hijri day offset used to live in its own top-level "Manual Offsets" screen; it now sits here
        // alongside the prayer-time offsets so every manual adjustment is in one place.
        Section(header: Text("HIJRI OFFSET")) {
            #if os(watchOS)
            // Watch: one short line ("+2 days") in small type - the phone's "Hijri Offset: X days" row
            // truncated to a couple of letters on the small screen.
            Stepper(value: $settings.hijriOffset, in: -3...3) {
                Text("\(settings.hijriOffset >= 0 ? "+" : "")\(settings.hijriOffset) \(abs(settings.hijriOffset) == 1 ? "day" : "days")")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(.footnote)

            if let hijriDate = settings.hijriDate {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hijriDate.english)
                    Text(hijriDate.arabic)
                }
                .font(.caption2)
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.vertical, 2)
            }
            #else
            Stepper(value: $settings.hijriOffset, in: -3...3) {
                HStack {
                    Text("Hijri Offset:")
                        .foregroundColor(.primary)

                    Text("\(settings.hijriOffset) days")
                        .foregroundColor(settings.accentColor.color)
                }
            }
            .font(.subheadline)

            if let hijriDate = settings.hijriDate {
                HStack {
                    Text("English:")
                        .foregroundColor(.primary)

                    Text(hijriDate.english)
                        .foregroundColor(settings.accentColor.color)
                }
                .font(.subheadline)

                HStack {
                    Text("Arabic: ")
                        .foregroundColor(.primary)

                    Text(hijriDate.arabic)
                        .foregroundColor(settings.accentColor.color)
                }
                .font(.subheadline)
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
    @ObservedObject var settings = Settings.shared

    @ViewBuilder
    private func offsetStepper(title: String, icon: String, value: Binding<Int>) -> some View {
        // Wide enough to follow a local mosque that runs well off the calculated time, not just to nudge it.
        #if os(watchOS)
        // Watch: prayer name over the minutes, small type - the phone's single wide row truncated badly.
        Stepper(value: value.animation(.easeInOut), in: -190...190) {
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
        Stepper(value: value.animation(.easeInOut), in: -190...190) {
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
        .font(.subheadline)
        #endif
    }

    private func travelOffsetCaption(for prayerName: String) -> String? {
        switch prayerName {
        case "Dhuhr":
            return "Also affects the combined traveling Dhuhr/Asr prayer."
        case "Maghrib":
            return "Also affects the combined traveling Maghrib/Isha prayer."
        default:
            return nil
        }
    }

    var body: some View {
        Section(header: Text("HIJRI DATE")) {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("Switch Hijri Date at Maghrib", isOn: $settings.switchHijriDateAtMaghrib.animation(.easeInOut))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)
                    .onChange(of: settings.switchHijriDateAtMaghrib) { _ in settings.hapticFeedback() }

                Text("When enabled, the displayed Hijri date changes at the calculated Maghrib time instead of at midnight. Off by default.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)

                Text("In Islam, the day begins at sunset (Maghrib). Keeping this on follows that Islamic tradition, while turning it off matches the usual midnight-to-midnight day.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }
        }

        Section(header: Text("PRAYER OFFSETS")) {
            offsetStepper(title: "Fajr", icon: "sunrise", value: $settings.offsetFajr)
            offsetStepper(title: "Sunrise", icon: "sunrise.fill", value: $settings.offsetSunrise)
            offsetStepper(title: "Dhuhr", icon: "sun.max", value: $settings.offsetDhuhr)
            offsetStepper(title: "Asr", icon: "sun.min", value: $settings.offsetAsr)
            offsetStepper(title: "Maghrib", icon: "sunset", value: $settings.offsetMaghrib)
            offsetStepper(title: "Isha", icon: "moon", value: $settings.offsetIsha)

            Text("In traveling mode, Dhuhr offset also affects the combined Dhuhr/Asr prayer, and Maghrib offset also affects the combined Maghrib/Isha prayer.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)

            Text("Use these offsets to shift the calculated prayer times earlier or later. Negative values move the time earlier, positive values move it later.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
        }
    }
}

struct NotificationView: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.appearance) private var appearance

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
        .onChange(of: scenePhase) { _ in requestAuthorizationAndFetchPrayerTimes() }
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

    @ViewBuilder
    private var notificationSections: some View {
                #if os(iOS)
                Section {
                    permissionCard
                }

                TipsSection(area: .notifications, resolve: resolveSearchDestination)
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

                Section(header: Text("HIJRI CALENDAR")) {
                    Toggle("Islamic Calendar Notifications", isOn: $settings.dateNotifications.animation(.easeInOut))
                        .font(.subheadline)
                        .onChange(of: settings.dateNotifications) { _ in settings.hapticFeedback() }

                    if settings.dateNotifications {
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Remind a Day Before", isOn: $settings.dateNotificationsDayBefore.animation(.easeInOut))
                                .font(.subheadline)
                                .onChange(of: settings.dateNotificationsDayBefore) { _ in settings.hapticFeedback() }

                            Text("Also sends a heads-up the evening before each Islamic date, so Ramadan, Eid, and the days of fasting never arrive unannounced.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .settingsDependent()
                    }
                }

                #if os(iOS)
                Section(header: Text("QURAN AND SUNNAH")) {
                    NavigationLink(destination: LazyDestination { SunnahRemindersView() }) {
                        SettingsRowLabel(title: "Sunnah Reminders", systemImage: "bell.and.waves.left.and.right.fill",
                                         subtitle: "Al-Kahf on Friday, al-Mulk before sleep, and more", tint: SettingsTint.notifications)
                    }
                    .tint(settings.accentColor.color)
                }

                Section(header: Text("ADHAN SOUND")) {
                    Picker("Adhan Sound", selection: $settings.adhanNotificationSound) {
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
                                Text(option.title).tag(option.id)
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
                        Label("Notification sounds are off in iPhone Settings, so the adhan will be silent.", systemImage: "speaker.slash.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)
                    }

                    if settings.adhanNotificationSound != "default" {
                        Label(isPreviewingAdhan ? "Stop Preview" : "Preview Sound",
                              systemImage: isPreviewingAdhan ? "stop.circle.fill" : "play.circle.fill")
                            .font(.subheadline)
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
                    }

                    Text("The notification plays the adhan's first 30 seconds; iOS won't play a longer notification sound. Previewing, or having the app open when the prayer comes in, plays it in full. Prenotifications, the optional times, and prayers with the adhan switched off use the alert tone below.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 2)
                }

                Section(header: Text("ALERT TONE")) {
                    Picker("Alert Tone", selection: $settings.alertToneSound) {
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
                        Label(isPreviewingAdhan ? "Stop Preview" : "Preview Tone",
                              systemImage: isPreviewingAdhan ? "stop.circle.fill" : "play.circle.fill")
                            .font(.subheadline)
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

                    Text("Used for prenotifications, the optional times (Shurooq, Duhaa, Islamic Midnight, Last Third), and any prayer whose adhan is switched off, so you can tell a prayer notification from every other alert on your phone. None of these is a call to prayer. Echo and Takbir are soft; Chime, Ring, and Alarm are pitched to carry through background noise, Alarm the most of all. Choose Default to go back to the iPhone's own alert sound.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 2)
                }

                Section(footer: Text("With this on, the adhan that plays inside the app at prayer time sounds even when the ringer switch is set to silent. Notifications outside the app still follow your system sound settings.")) {
                    Toggle("Play In-App Adhan in Silent Mode", isOn: $settings.adhanOverridesSilentMode.animation(.easeInOut))
                        .font(.subheadline)
                        .onChange(of: settings.adhanOverridesSilentMode) { _ in settings.hapticFeedback() }
                }
                #endif

                Section(header: Text("PRAYER REMINDERS")) {
                    NavigationLink(destination: LazyDestination { MoreNotificationView() }) {
                        SettingsRowLabel(title: "Prayer Notifications", systemImage: "bell.fill",
                                         subtitle: SettingsNotificationsPage.prayerReminders.caption, tint: SettingsTint.notifications)
                    }
                    .tint(settings.accentColor.color)

                    // Its own row here, not only a section inside Prayer Notifications: the mode is
                    // the app's most unusual notification feature and was its hardest to find.
                    NavigationLink(destination: LazyDestination { NaggingModeView() }) {
                        SettingsRowLabel(title: "Nagging Mode",
                                         systemImage: SettingsNotificationsPage.naggingMode.systemImage,
                                         subtitle: SettingsNotificationsPage.naggingMode.caption,
                                         tint: SettingsTint.notifications,
                                         value: NaggingModeView.statusValue(settings))
                    }
                    .tint(settings.accentColor.color)
                }
    }

    #if os(iOS)
    @ViewBuilder
    private func notificationPageDestination(_ page: SettingsNotificationsPage) -> some View {
        switch page {
        case .prayerReminders: MoreNotificationView()
        case .naggingMode: NaggingModeView()
        case .sunnahReminders: SunnahRemindersView()
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
    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Permission", systemImage: "bell.badge")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Spacer()

                Text(permissionPillText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(permissionPillColor))
                    .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    .padding(.trailing, -6)
            }
            .animation(.easeInOut(duration: 0.25), value: permissionPillText)

            // Always present - not gated on the async fetch - so the card renders at its final
            // height from the FIRST frame. The rows used to appear only once the notification
            // settings arrived, which visibly grew the card (and the sheet around it) right after
            // opening. Redacted placeholders hold the exact space while the fetch is in flight.
            VStack(spacing: 8) {
                infoRow("Status", notifSettings.map { statusText($0.authorizationStatus) } ?? "Allowed")
                infoRow("Alerts", notifSettings.map { notificationSettingText($0.alertSetting) } ?? "On")
                infoRow("Sounds", notifSettings.map { notificationSettingText($0.soundSetting) } ?? "On")
            }
            .font(.footnote)
            .redacted(reason: notifSettings == nil ? .placeholder : [])

            HStack(spacing: 10) {
                smallButton("Request Access", systemImage: "checkmark.seal")
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.hapticFeedback()
                        Task { @MainActor in
                            await onRequestAccessTapped()
                        }
                    }

                smallButton("Open Settings", systemImage: "gear")
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.hapticFeedback()
                        openSystemSettings()
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
    }

    private func statusText(_ s: UNAuthorizationStatus) -> String {
        switch s {
        case .notDetermined: return "Not asked"
        case .denied: return "Denied"
        case .authorized: return "Allowed"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    private func notificationSettingText(_ s: UNNotificationSetting) -> String {
        switch s {
        case .enabled: return "On"
        case .disabled: return "Off"
        case .notSupported: return "N/A"
        @unknown default: return "Unknown"
        }
    }

    private func smallButton(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)

            Text(title)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(settings.accentColor.color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(settings.accentColor.color.opacity(0.35), lineWidth: 1)
        )
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
            requestAccessAlertMessage = "Notifications are already turned on."
        case .denied:
            requestAccessAlertMessage = "Notifications are turned off. Open Settings to enable them."
        case .notDetermined:
            _ = await settings.requestNotificationAuthorization()
            await refresh()
        @unknown default:
            requestAccessAlertMessage = "Unable to change notification settings."
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
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            player.prepareToPlay()
            player.play()
            previewPlayer = player
            isPreviewingAdhan = true

            let duration = player.duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.25) {
                if previewPlayer === player {
                    stopAdhanPreview()
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
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
    #endif
}

struct MoreNotificationView: View {
    @ObservedObject var settings = Settings.shared

    @Environment(\.scenePhase) private var scenePhase

    @State private var showAlert: Bool = false

    var body: some View {
        #if DEBUG && os(iOS)
        ScrollViewReader { proxy in
            notificationBody
                // "-scrollToEnglishMeanings": the WHAT THEY SAY section sits below the fold (further
                // still in nagging mode), and a simulator screenshot cannot scroll.
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

    private var notificationBody: some View {
        List {
            Group {
            // Nagging mode has a screen of its own now (Abu, 2026-09-20: "make nagging mode more
            // customizable... front and center"): it outgrew a section, and as a section it sat
            // three pushes deep where nobody found it. This is one of its three doors; the
            // Notifications root and the Settings tab's featured cards are the other two.
            Section(header: Text("NAGGING MODE")) {
                NavigationLink(destination: LazyDestination { NaggingModeView() }) {
                    SettingsRowLabel(title: "Nagging Mode",
                                     systemImage: SettingsNotificationsPage.naggingMode.systemImage,
                                     subtitle: SettingsNotificationsPage.naggingMode.caption,
                                     tint: SettingsTint.notifications,
                                     value: NaggingModeView.statusValue(settings))
                }
                .tint(settings.accentColor.color)
            }

            // OUTSIDE the `!naggingMode` branch: the gloss is part of every prayer notification's
            // wording, and a nag body names the prayer too, so hiding this control in nagging mode
            // would hide a setting that is still in effect.
            Section(header: Text("WHAT THEY SAY")) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Show English Meanings", isOn: $settings.prayerNotificationEnglishNames.animation(.easeInOut))
                        .font(.subheadline)
                        .onChange(of: settings.prayerNotificationEnglishNames) { _ in settings.hapticFeedback() }

                    Text("Adds each prayer's meaning to its notification, like \u{201C}Time for Maghrib (sunset)\u{201D}. Shurooq and Jumuah always name theirs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                #if DEBUG
                // On the ROW, not on the Toggle nested inside the VStack: `scrollTo` targets a list
                // row, and an id buried in a row's subview is not one.
                .id("englishMeanings")
                #endif
            }

            if !settings.naggingMode {
                Section(header: Text("ALL PRAYER NOTIFICATIONS")) {
                    Toggle("Turn On All Prayer Notifications", isOn: Binding(
                        get: {
                            settings.notificationFajr &&
                            settings.notificationSunrise &&
                            settings.notificationDhuhr &&
                            settings.notificationAsr &&
                            settings.notificationMaghrib &&
                            settings.notificationIsha
                        },
                        set: { newValue in
                            withAnimation {
                                settings.notificationFajr = newValue
                                settings.notificationSunrise = newValue
                                settings.notificationDhuhr = newValue
                                settings.notificationAsr = newValue
                                settings.notificationMaghrib = newValue
                                settings.notificationIsha = newValue
                            }
                        }
                    ).animation(.easeInOut))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)
                    .onChange(of: settings.notificationFajr) { _ in settings.hapticFeedback() }

                    Stepper(value: Binding(
                        get: { settings.preNotificationFajr },
                        set: { newValue in
                            withAnimation {
                                settings.preNotificationFajr = newValue
                                settings.preNotificationSunrise = newValue
                                settings.preNotificationDhuhr = newValue
                                settings.preNotificationAsr = newValue
                                settings.preNotificationMaghrib = newValue
                                settings.preNotificationIsha = newValue
                            }
                        }
                    ), in: 0...120, step: 1) {
                        Text("All Prayer Prenotifications:")
                            .font(.subheadline)
                        Text("\(settings.preNotificationFajr) minute\(settings.preNotificationFajr != 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                    }
                }
            }

            if !settings.naggingMode {
                NotificationSettingsSection(prayerName: "Fajr", preNotificationTime: $settings.preNotificationFajr, isNotificationOn: $settings.notificationFajr)
                NotificationSettingsSection(prayerName: "Shurooq", preNotificationTime: $settings.preNotificationSunrise, isNotificationOn: $settings.notificationSunrise)
                NotificationSettingsSection(prayerName: "Dhuhr", preNotificationTime: $settings.preNotificationDhuhr, isNotificationOn: $settings.notificationDhuhr)
                NotificationSettingsSection(prayerName: "Asr", preNotificationTime: $settings.preNotificationAsr, isNotificationOn: $settings.notificationAsr)
                NotificationSettingsSection(prayerName: "Maghrib", preNotificationTime: $settings.preNotificationMaghrib, isNotificationOn: $settings.notificationMaghrib)
                NotificationSettingsSection(prayerName: "Isha", preNotificationTime: $settings.preNotificationIsha, isNotificationOn: $settings.notificationIsha)

                if settings.showDuha {
                    NotificationSettingsSection(prayerName: "Duhaa", preNotificationTime: $settings.preNotificationDuha, isNotificationOn: $settings.notificationDuha)
                }
                if settings.showIslamicMidnight {
                    NotificationSettingsSection(prayerName: "Islamic Midnight", preNotificationTime: $settings.preNotificationIslamicMidnight, isNotificationOn: $settings.notificationIslamicMidnight)
                }
                if settings.showLastThird {
                    NotificationSettingsSection(prayerName: "Last Third", preNotificationTime: $settings.preNotificationLastThird, isNotificationOn: $settings.notificationLastThird)
                }
            } else {
                if !settings.naggingFajr {
                    NotificationSettingsSection(prayerName: "Fajr", preNotificationTime: $settings.preNotificationFajr, isNotificationOn: $settings.notificationFajr)
                }
                if !settings.naggingSunrise {
                    NotificationSettingsSection(prayerName: "Shurooq", preNotificationTime: $settings.preNotificationSunrise, isNotificationOn: $settings.notificationSunrise)
                }
                // Always shown: "before Dhuhr" is no longer a nagging deadline (it asked about Fajr,
                // whose window had already closed at sunrise), so nothing else owns this slot.
                NotificationSettingsSection(prayerName: "Dhuhr", preNotificationTime: $settings.preNotificationDhuhr, isNotificationOn: $settings.notificationDhuhr)
                if !settings.naggingAsr {
                    NotificationSettingsSection(prayerName: "Asr", preNotificationTime: $settings.preNotificationAsr, isNotificationOn: $settings.notificationAsr)
                }
                if !settings.naggingMaghrib {
                    NotificationSettingsSection(prayerName: "Maghrib", preNotificationTime: $settings.preNotificationMaghrib, isNotificationOn: $settings.notificationMaghrib)
                }
                if !settings.naggingIsha {
                    NotificationSettingsSection(prayerName: "Isha", preNotificationTime: $settings.preNotificationIsha, isNotificationOn: $settings.notificationIsha)
                }
                if settings.showDuha {
                    NotificationSettingsSection(prayerName: "Duhaa", preNotificationTime: $settings.preNotificationDuha, isNotificationOn: $settings.notificationDuha)
                }
                if settings.showIslamicMidnight {
                    NotificationSettingsSection(prayerName: "Islamic Midnight", preNotificationTime: $settings.preNotificationIslamicMidnight, isNotificationOn: $settings.notificationIslamicMidnight)
                }
                if settings.showLastThird {
                    NotificationSettingsSection(prayerName: "Last Third", preNotificationTime: $settings.preNotificationLastThird, isNotificationOn: $settings.notificationLastThird)
                }
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
        .onChange(of: scenePhase) { _ in
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

struct NotificationSettingsSection: View {
    @ObservedObject var settings = Settings.shared

    let prayerName: String

    @Binding var preNotificationTime: Int
    @Binding var isNotificationOn: Bool

    private var travelNotificationCaption: String? {
        switch prayerName {
        case "Dhuhr":
            return "Also affects the combined traveling Dhuhr/Asr prayer."
        case "Maghrib":
            return "Also affects the combined traveling Maghrib/Isha prayer."
        default:
            return nil
        }
    }

    /// Only the five daily prayers carry an adhan. Shurooq and the optional times always use the default
    /// notification sound (see `prayerNotificationSound`), so they get no adhan controls at all.
    private var shortAdhan: Binding<Bool>? {
        switch prayerName {
        case "Fajr":    return $settings.shortAdhanFajr
        case "Dhuhr":   return $settings.shortAdhanDhuhr
        case "Asr":     return $settings.shortAdhanAsr
        case "Maghrib": return $settings.shortAdhanMaghrib
        case "Isha":    return $settings.shortAdhanIsha
        default:        return nil
        }
    }

    private var adhanSound: Binding<Bool>? {
        switch prayerName {
        case "Fajr":    return $settings.adhanSoundFajr
        case "Dhuhr":   return $settings.adhanSoundDhuhr
        case "Asr":     return $settings.adhanSoundAsr
        case "Maghrib": return $settings.adhanSoundMaghrib
        case "Isha":    return $settings.adhanSoundIsha
        default:        return nil
        }
    }

    /// With "Default" chosen there is no recording to play or shorten, so the per-prayer adhan controls have
    /// nothing to act on and are hidden rather than shown doing nothing.
    private var hasAdhanRecording: Bool { settings.adhanNotificationSound != "default" }

    var body: some View {
        Section(header: Text(prayerName.uppercased())) {
            Toggle("Notification", isOn: $isNotificationOn.animation(.easeInOut))
                .font(.subheadline)
                .onChange(of: isNotificationOn) { _ in settings.hapticFeedback() }

            if isNotificationOn {
                Stepper(value: $preNotificationTime.animation(.easeInOut), in: 0...120, step: 1) {
                    Text("Prenotification Time:")
                        .font(.subheadline)

                    Text("\(preNotificationTime) minute\(preNotificationTime != 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(settings.accentColor.color)
                }

                if let adhanSound, hasAdhanRecording {
                    VStack(alignment: .leading) {
                        Toggle("Play Adhan", isOn: adhanSound.animation(.easeInOut))
                            .font(.subheadline)
                            .onChange(of: adhanSound.wrappedValue) { _ in settings.hapticFeedback() }

                        Text("Turn off to get an ordinary notification sound for this prayer, while the others still call the adhan.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)
                    }

                    // Nothing to shorten once the adhan itself is off.
                    if let shortAdhan, adhanSound.wrappedValue {
                        VStack(alignment: .leading) {
                            Toggle("Short Adhan", isOn: shortAdhan.animation(.easeInOut))
                                .font(.subheadline)
                                .onChange(of: shortAdhan.wrappedValue) { _ in settings.hapticFeedback() }

                            Text("Plays a brief excerpt instead of the adhan's first 30 seconds.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 2)
                        }
                    }
                }
            }

            if let travelNotificationCaption {
                Text(travelNotificationCaption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }
        }
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
    static let notificationEntries: [SettingsSearchEntry] = [
        .init(title: "Notification Settings", path: "Notifications", keywords: "alerts permission bell", destination: .notifications),
        .init(title: "Notification Permission", path: "Notifications", keywords: "allow access permission status sounds badges denied", destination: .notifications),
        .init(title: "Adhan Sound", path: "Notifications", keywords: "athan azan sound mecca madinah silent mode ringer", destination: .notifications),
        .init(title: "Alert Tone", path: "Notifications", keywords: "tone chime ding sound reminder alert", destination: .notifications),
        .init(title: "Hijri Calendar Notifications", path: "Notifications", keywords: "islamic events eid ramadan reminders", destination: .notifications),
        .init(title: "Remind a Day Before", path: "Notifications", keywords: "islamic dates day before tomorrow ramadan eid heads up early", destination: .notifications),
        .init(title: "Sunnah Reminders (Notifications)", path: "Notifications → Sunnah Reminders", keywords: "al-kahf friday al-mulk sleep muawwidhat hadith reminder", destination: .notificationsPage(.sunnahReminders)),
        .init(title: "Prayer Reminders & Pre-Notifications", path: "Notifications → Prayer Reminders", keywords: "before minutes early alert per prayer fajr dhuhr asr maghrib isha", destination: .notificationsPage(.prayerReminders)),
        .init(title: "Nagging Mode", path: "Notifications → Nagging Mode", keywords: "nag repeat reminders pray on time cascade did you pray tracker deadline window closes midnight isha fajr shurooq struggle lazy miss prayers accountability", destination: .notificationsPage(.naggingMode)),
        .init(title: "Nagging Start Time & Repeat Interval", path: "Notifications → Nagging Mode", keywords: "nag lead start minutes before hour repeat every interval spacing how often frequency last calls final reminders 10 5", destination: .notificationsPage(.naggingMode)),
        .init(title: "Different Nagging Start for Each Prayer", path: "Notifications → Nagging Mode", keywords: "nag per prayer custom lead fajr shurooq asr maghrib isha midnight individual", destination: .notificationsPage(.naggingMode)),
        .init(title: "Check In After the Adhan", path: "Notifications → Nagging Mode", keywords: "nag follow up after adhan have you prayed yet early start of time beginning reminder later", destination: .notificationsPage(.naggingMode)),
        .init(title: "Nag Tone & Louder Last Call", path: "Notifications → Nagging Mode", keywords: "nag sound tone alarm loud louder final last call escalate chime ring echo takbir", destination: .notificationsPage(.naggingMode)),
        .init(title: "Add a Verse to the Last Call", path: "Notifications → Nagging Mode", keywords: "nag ayah verse quran wording reminder motivation last call", destination: .notificationsPage(.naggingMode)),
        .init(title: "Pause Nagging", path: "Notifications → Nagging Mode", keywords: "pause snooze silence hold sick travel flight day week resume nag", destination: .notificationsPage(.naggingMode)),
        .init(title: "Show English Meanings", path: "Notifications → Prayer Reminders", keywords: "english translation meaning sunset dawn midday afternoon night maghrib notification wording name", destination: .notificationsPage(.prayerReminders)),
    ]

    static let adhanEntries: [SettingsSearchEntry] = [
        .init(title: "Prayer Settings", path: "Al-Adhan", keywords: "salah salat times adhan", destination: .prayerSettings),
        .init(title: "Traveling Mode (Qasr)", path: "Prayer Settings → Traveling Mode", keywords: "travel shorten combine journey safar 48 miles automatic", destination: .prayerPage(.travelingMode)),
        .init(title: "Optional Prayer Times", path: "Prayer Settings → Optional Prayers", keywords: "duha duhaa islamic midnight last third night tahajjud suhoor", destination: .prayerPage(.optionalPrayers)),
        .init(title: "Manual Prayer Offsets", path: "Prayer Settings → Manual Offsets", keywords: "adjust minutes plus minus tune offset", destination: .prayerPage(.manualOffsets)),
        .init(title: "Hijri Date Offset", path: "Prayer Settings → Manual Offsets", keywords: "hijri adjust day moon date calendar", destination: .prayerPage(.manualOffsets)),
        .init(title: "Switch Hijri Date at Maghrib", path: "Prayer Settings → Manual Offsets", keywords: "hijri date sunset maghrib midnight islamic day", destination: .prayerPage(.manualOffsets)),
        .init(title: "Custom Prayer Names", path: "Prayer Settings → Custom Prayer Names", keywords: "rename spelling fadjr salah names", destination: .prayerPage(.customPrayerNames)),
        .init(title: "Mark Only After the Time Begins", path: "Al-Adhan → Prayer Tracker", keywords: "prayer tracker mark time begins lock gate future prayers order only after adhan", destination: .prayerTracker),
        .init(title: "Show Sky (Sun Arc, Moon, Stars)", path: "Prayer Settings → Sky", keywords: "sky card sun arc moon phase stars countdown adhan tab", destination: .prayerPage(.sky)),
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
    @ObservedObject var settings = Settings.shared
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

                    customSection
                    madhabAndHighLatitudeSection
                    explanationSection
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Prayer Calculation")
        #if os(iOS)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: $searchText.animation(.easeInOut))
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        #elseif os(watchOS)
        .searchable(text: $searchText.animation(.easeInOut))
        #endif
        .applyConditionalListStyle()
    }

    private var automaticSection: some View {
        Section(header: Text("AUTOMATIC")) {
            Toggle("Choose Automatically", isOn: $settings.calculationAutomatic.animation(.easeInOut))
                .font(.subheadline)
                .tint(settings.accentColor.color)
                .onChange(of: settings.calculationAutomatic) { _ in settings.hapticFeedback() }

            Text("Picks the method customary in the country you are in. Choosing a method by hand below turns this off.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
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
                Text(region)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
        Section(header: Text("CUSTOM")) {
            methodRow(customMethod)

            // Only editable while the custom method is the one in use - otherwise these steppers would be
            // silently adjusting angles that nothing is computing with.
            if selectedID == PrayerCalculationCatalog.customID {
                Stepper(value: $settings.customFajrAngle, in: 8...25, step: 0.5) {
                    HStack {
                        Text("Fajr Angle")
                        Spacer()
                        Text("\(IshaRule.format(settings.customFajrAngle))°")
                            .monospacedDigit()
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                .font(.subheadline)

                Stepper(value: $settings.customIshaAngle, in: 8...25, step: 0.5) {
                    HStack {
                        Text("Isha Angle")
                        Spacer()
                        Text("\(IshaRule.format(settings.customIshaAngle))°")
                            .monospacedDigit()
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                .font(.subheadline)

                Text("Only set your own angles if you know the values your local mosque uses. A wrong angle means praying at the wrong time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }
        }
    }

    /// The madhab + high-latitude controls. They lived inline on the PARENT settings screen (twice
    /// orphaned in refactors); they belong here with the rest of the calculation choices - and the
    /// settings-search index deep-links "hanafi"/"high latitude" to this screen.
    private var madhabAndHighLatitudeSection: some View {
        Section(header: Text("MADHAB & HIGH LATITUDE")) {
            VStack(alignment: .leading) {
                Toggle("Hanafi Calculation for Asr", isOn: $settings.hanafiMadhab.animation(.easeInOut))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)
                    .onChange(of: settings.hanafiMadhab) { _ in settings.hapticFeedback() }

                Text("The Hanafi madhab uses the shadow ratio of 2 to 1 for Asr, while many other schools use 1 to 1. Enable this only if you follow the Hanafi method.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }

            VStack(alignment: .leading) {
                Picker("High Latitude Rule", selection: $settings.highLatitudeRule) {
                    Section {
                        ForEach(Settings.highLatitudeRuleOptions, id: \.self) { option in
                            Text(option).tag(option)
                                .font(.subheadline)
                        }
                    } header: {
                        Text("High Latitude Rule")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                .onChange(of: settings.highLatitudeRule) { _ in settings.hapticFeedback() }

                Text(highLatitudeRuleCaption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }
        }
    }

    private var highLatitudeRuleCaption: String {
        // Not merely a high-latitude concern: on a short summer night the rule can shift Fajr and Isha as far
        // south as Cairo (~30°N). Only in winter, or near the equator, does the choice make no difference.
        var caption = "When the night is short, the sun never sinks low enough for the twilight that defines "
            + "Fajr and Isha, so they are estimated. This matters most far from the equator, but can shift "
            + "summer times at any latitude."
        if let location = live.currentLocation, location.latitude != 1000, location.longitude != 1000 {
            let coordinates = Coordinates(latitude: location.latitude, longitude: location.longitude)
            caption += " Automatic uses \(settings.recommendedHighLatitudeRuleLabel(at: coordinates)) in \(location.city)."
        }
        return caption
    }

    private var explanationSection: some View {
        Section(header: Text("ABOUT THESE ANGLES")) {
            Text("Fajr begins at true dawn and Isha at nightfall. Neither is a clock time: both are defined by how far the sun has sunk below the horizon, and the bodies below differ on where exactly to draw that line. A larger angle means an earlier Fajr and a later Isha.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)

            Text("Umm Al-Qura and Qatar use a fixed interval after Maghrib for Isha instead of an angle, because at their latitude the twilight is consistent enough for a clock to be reliable.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)

            Text("Use the method your local mosque uses. If you do not know it, leave this on automatic.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
        }
    }
}

#if os(iOS)
// MARK: - Settings-search entries (kept in THIS file, next to the screen they describe)
extension SettingsSearchEntry {
    static let prayerCalculationEntries: [SettingsSearchEntry] = [
        .init(title: "Prayer Calculation Method", path: "Prayer Settings → Prayer Calculation", keywords: "method angles isna mwl muslim world league egypt karachi umm al-qura makkah moonsighting jakim malaysia singapore indonesia turkey diyanet automatic country", destination: .prayerPage(.prayerCalculation)),
        .init(title: "Custom Calculation Angles", path: "Prayer Settings → Prayer Calculation", keywords: "fajr angle isha angle degrees custom", destination: .prayerPage(.prayerCalculation)),
        .init(title: "High Latitude Rule", path: "Prayer Settings → Prayer Calculation", keywords: "midnight seventh night twilight northern latitude", destination: .prayerPage(.prayerCalculation)),
        .init(title: "Hanafi Madhab (Asr Time)", path: "Prayer Settings → Prayer Calculation", keywords: "asr later shadow madhhab school shafi", destination: .prayerPage(.prayerCalculation)),
    ]
}
#endif

