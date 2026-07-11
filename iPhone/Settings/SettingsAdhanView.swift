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

    init(showNotifications: Bool, presentedAsSheet: Bool = false) {
        self._showNotifications = State(initialValue: showNotifications)
        self.presentedAsSheet = presentedAsSheet
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
        List {
            Group {
                notificationsSection
                Section {
                    adhanSettingsLink(title: "Prayer Calculation", systemImage: "function") {
                        prayerCalculationDestination
                    }
                }
                Section {
                    adhanSettingsLink(title: "Traveling Mode", systemImage: "airplane") {
                        travelingModeDestination
                    }
                }
                Section {
                    adhanSettingsLink(title: "Optional Prayers", systemImage: "moon.stars") {
                        optionalTimesDestination
                    }
                }
                Section {
                    adhanSettingsLink(title: "Manual Offsets", systemImage: "slider.horizontal.3") {
                        prayerOffsetsDestination
                    }
                }
                Section {
                    adhanSettingsLink(title: "Custom Prayer Names", systemImage: "character.cursor.ibeam") {
                        customPrayerNamesDestination
                    }
                }
                #if os(iOS)
                Section {
                    VStack(alignment: .leading) {
                        Toggle("Show Sky", isOn: $settings.showSkyView.animation(.easeInOut))
                            .font(.subheadline)
                            .tint(settings.accentColor.color)
                            .onChange(of: settings.showSkyView) { _ in settings.hapticFeedback() }

                        Text("The sun on today's arc, the moon at its true phase, and the stars at night. Drag the sun to see any moment of the day. Turn it off for a plain Current/Upcoming card.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)
                    }

                    // Nothing to color when the sky isn't drawn.
                    if settings.showSkyView {
                        adhanSettingsLink(title: "Sky Colors", systemImage: "paintpalette") {
                            SkyColorsView()
                        }
                    }
                }
                #endif
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
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
        .onChange(of: settings.homeLocation) { _ in
            settings.fetchPrayerTimes()
        }
        .onChange(of: settings.travelAutomatic) { newValue in
            guard newValue else { return }
            settings.fetchPrayerTimes() {
                if settings.homeLocation == nil {
                    withAnimation { settings.travelingMode = false }
                }
            }
        }
        .onChange(of: settings.calculationAutomatic) { newValue in
            guard newValue else { return }
            settings.fetchPrayerTimes(force: true)
        }
        // Present the automatic-change confirmation the moment the flag flips, from ANY code path that runs
        // checkIfTraveling()/the auto-calculation change (location updates, scene changes, background
        // refresh) — not gated behind a specific prayer-fetch completion. The old approach only checked the
        // flag inside a couple of fetch completions, so the dialog lagged (waited for the fetch) and often
        // never appeared (when the flag flipped from a fetch not triggered here).
        // Consume each flag the instant it flips (see AdhanView for the full rationale): capture it into
        // `showAlert` and reset the @AppStorage flag so the dialog can't re-present on re-entry or after a
        // tap-outside dismissal.
        .onChange(of: settings.travelTurnOnAutomatic) { on in
            if on {
                showAlert = .travelTurnOnAutomatic
                settings.travelTurnOnAutomatic = false
            }
        }
        .onChange(of: settings.travelTurnOffAutomatic) { off in
            if off {
                showAlert = .travelTurnOffAutomatic
                settings.travelTurnOffAutomatic = false
            }
        }
        .onChange(of: settings.calculationAutoChanged) { changed in
            if changed {
                showAlert = .calculationAutomaticChanged
                settings.calculationAutoChanged = false
            }
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

    /// A dialog anchored only to the root list cannot present while the user is on a *pushed* sub-screen —
    /// which is exactly why the Traveling Mode confirmation never appeared (the toggle lives on the pushed
    /// "Traveling Mode" screen). The binding and content are shared so the same dialog can also be attached
    /// to the sub-screens, and whichever one is actually on screen presents it.
    private var autoChangeDialogBinding: Binding<Bool> {
        Binding(
            get: { showAlert != nil },
            set: { if !$0 { showAlert = nil } }
        )
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

    private func adhanSettingsLink<Destination: View>(
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
    // it live *here*, and a dialog anchored only to the (now off-screen) root list could never present —
    // which is why the Traveling Mode confirmation appeared to do nothing.
    private var prayerCalculationDestination: some View {
        adhanSettingsSubList(title: "Prayer Calculation") {
            prayerCalculationSection
        }
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

    @ViewBuilder
    private var notificationsSection: some View {
        #if os(iOS)
        Section {
            NavigationLink(destination: NotificationView()) {
                Label("Notification Settings", systemImage: "bell.badge")
            }
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
                }
            }
        }
        .font(.subheadline)
        .tint(settings.accentColor.color)
        .onChange(of: isOn.wrappedValue) { _ in settings.hapticFeedback() }
    }

    private var prayerCalculationSection: some View {
        Section(header: Text("PRAYER CALCULATION")) {
            automaticCalculationToggle
            calculationPickerGroup
            hanafiCalculationGroup
            highLatitudeRuleGroup
        }
    }

    /// Above roughly 48° the sun never dips far enough below the horizon for the twilight angles that define
    /// Fajr and Isha, so those two have to be approximated. Below that latitude the rule changes nothing.
    private var highLatitudeRuleGroup: some View {
        VStack(alignment: .leading) {
            Picker("High Latitude Rule", selection: $settings.highLatitudeRule.animation(.easeInOut)) {
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
                .padding(.vertical, 2)
        }
    }

    private var highLatitudeRuleCaption: String {
        // Not merely a high-latitude concern: on a short summer night the rule can shift Fajr and Isha as far
        // south as Cairo (~30°N). Only in winter, or near the equator, does the choice make no difference.
        var caption = "When the night is short, the sun never sinks low enough for the twilight that defines "
            + "Fajr and Isha, so they are estimated. This matters most far from the equator, but can shift "
            + "summer times at any latitude."
        if let location = settings.currentLocation, location.latitude != 1000, location.longitude != 1000 {
            let coordinates = Coordinates(latitude: location.latitude, longitude: location.longitude)
            caption += " Automatic uses \(settings.recommendedHighLatitudeRuleLabel(at: coordinates)) in \(location.city)."
        }
        return caption
    }

    private var automaticCalculationToggle: some View {
        Toggle("Automatic Prayer Calculation", isOn: $settings.calculationAutomatic.animation(.easeInOut))
            .font(.subheadline)
            .tint(settings.accentColor.color)
            .onChange(of: settings.calculationAutomatic) { _ in settings.hapticFeedback() }
    }

    private var calculationPickerGroup: some View {
        VStack(alignment: .leading) {
            Picker("Calculation", selection: calculationSelection.animation(.easeInOut)) {
                Section {
                    ForEach(calculationOptions, id: \.self) { option in
                        Text(option).tag(option)
                            .font(.subheadline)
                    }
                } header: {
                    Text("Calculation")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .disabled(settings.calculationAutomatic)
            .onChange(of: settings.prayerCalculation) { _ in settings.hapticFeedback() }

            Text("Fajr and Isha timings vary by calculation method, as they are based on twilight. If automatic mode is on, \(AppIdentifiers.appName) picks a method based on your location (for example, North America or Turkey). If your country is not mapped, it defaults to Muslim World League.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
    }

    private var calculationSelection: Binding<String> {
        Binding(
            get: { settings.prayerCalculation },
            set: { newValue in
                settings.calculationManuallyToggled = true
                if settings.calculationAutomatic {
                    settings.calculationAutomatic = false
                }
                settings.prayerCalculation = newValue
            }
        )
    }

    private var hanafiCalculationGroup: some View {
        VStack(alignment: .leading) {
            Toggle("Hanafi Calculation for Asr", isOn: $settings.hanafiMadhab.animation(.easeInOut))
                .font(.subheadline)
                .tint(settings.accentColor.color)
                .onChange(of: settings.hanafiMadhab) { _ in settings.hapticFeedback() }

            Text("The Hanafi madhab uses the shadow ratio of 2 to 1 for Asr, while many other schools use 1 to 1. Enable this only if you follow the Hanafi method.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
    }

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
                .padding(.vertical, 2)
            #endif
        }
    }

    private var travelingModeBinding: Binding<Bool> {
        Binding(
            get: { settings.travelingMode },
            set: {
                settings.travelingModeManuallyToggled = true
                settings.travelingMode = $0
            }
        )
    }

    @ViewBuilder
    private var prayerOffsetsSection: some View {
        #if os(iOS)
        // The Hijri day offset used to live in its own top-level "Manual Offsets" screen; it now sits here
        // alongside the prayer-time offsets so every manual adjustment is in one place.
        Section(header: Text("HIJRI OFFSET")) {
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
        }
        .onAppear {
            settings.fetchPrayerTimes()
        }

        PrayerOffsetsView()
        #endif
    }

    private var isWatch: Bool {
        #if os(iOS)
        false
        #else
        true
        #endif
    }
}

let calculationOptions: [String] = {
    let preferred = "Muslim World League"
    let rest = [
        "Britain (Moonsighting Committee)",
        "Saudi Arabia (Umm Al-Qura)",
        "Egypt",
        "Dubai",
        "Kuwait",
        "Qatar",
        "Turkey",
        "Tehran",
        "Karachi",
        "Singapore",
        "North America"
    ].sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    return [preferred] + rest
}()

struct PrayerOffsetsView: View {
    @ObservedObject var settings = Settings.shared

    @ViewBuilder
    private func offsetStepper(title: String, icon: String, value: Binding<Int>) -> some View {
        // Wide enough to follow a local mosque that runs well off the calculated time, not just to nudge it.
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
                    .padding(.vertical, 2)

                Text("In Islam, the day begins at sunset (Maghrib). Keeping this on follows that Islamic tradition, while turning it off matches the usual midnight-to-midnight day.")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                .padding(.vertical, 2)

            Text("Use these offsets to shift the calculated prayer times earlier or later. Negative values move the time earlier, positive values move it later.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
    }
}

struct NotificationView: View {
    @ObservedObject var settings = Settings.shared

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

    var body: some View {
        List {
            Group {
                #if os(iOS)
                Section {
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

                Section(header: Text("HIJRI CALENDAR")) {
                    Toggle("Islamic Calendar Notifications", isOn: $settings.dateNotifications.animation(.easeInOut))
                        .font(.subheadline)
                        .onChange(of: settings.dateNotifications) { _ in settings.hapticFeedback() }
                }

                #if os(iOS)
                Section(header: Text("ADHAN SOUND")) {
                    Picker("Adhan Sound", selection: $settings.adhanNotificationSound.animation(.easeInOut)) {
                        Section {
                            ForEach(Settings.supportedAdhanSounds) { option in
                                Text(option.title).tag(option.id)
                            }
                        } header: {
                            Text("Adhan Sound")
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

                    Text("The notification plays the adhan's first 30 seconds — iOS won't play a longer notification sound. Previewing, or having the app open when the prayer comes in, plays it in full. Prenotifications and nagging reminders still use the default sound.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                #endif

                Section(header: Text("PRAYER REMINDERS")) {
                    NavigationLink(destination: MoreNotificationView()) {
                        Label("Prayer Notifications", systemImage: "bell.fill")
                            .font(.subheadline)
                    }
                }
            }
            .themedListRowBackground()
        }
        .task { await refresh() }
        .onAppear {
            settings.normalizeAdhanSoundSelection()
            requestAuthorizationAndFetchPrayerTimes()
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
        .applyConditionalListStyle()
        .navigationTitle("Notification Settings")
    }

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

            if let s = notifSettings {
                VStack(spacing: 8) {
                    infoRow("Status", statusText(s.authorizationStatus))
                    infoRow("Alerts", notificationSettingText(s.alertSetting))
                    infoRow("Sounds", notificationSettingText(s.soundSetting))
                }
                .font(.footnote)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

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
                .fill(Color(UIColor.secondarySystemBackground))
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
    /// minutes — hence the stop control instead of a fire-and-forget tap.
    private func playAdhanPreview() {
        stopAdhanPreview()

        guard let resource = settings.adhanFullSoundResource(for: settings.adhanNotificationSound),
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

    private func turnOffNaggingModeIfAllOff() {
        if !settings.naggingFajr &&
           !settings.naggingSunrise &&
           !settings.naggingDhuhr &&
           !settings.naggingAsr &&
           !settings.naggingMaghrib &&
           !settings.naggingIsha {

            withAnimation {
                settings.naggingMode = false
            }
        }
    }

    var body: some View {
        List {
            Group {
            Section(header: Text("NAGGING MODE")) {
                Text("Nagging mode helps those who struggle to pray on time. Once enabled, you'll get a notification at the chosen start time before each prayer, then another every 15 minutes, plus final reminders at 10 and 5 minutes remaining.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Turn on Nagging Mode", isOn: Binding(
                    get: { settings.naggingMode },
                    set: { newValue in
                        withAnimation {
                            settings.naggingMode = newValue

                            if newValue {
                                settings.notificationFajr = true
                                settings.notificationSunrise = true
                                settings.notificationDhuhr = true
                                settings.notificationAsr = true
                                settings.notificationMaghrib = true
                                settings.notificationIsha = true

                                settings.naggingFajr = true
                                settings.naggingSunrise = true
                                settings.naggingDhuhr = true
                                settings.naggingAsr = true
                                settings.naggingMaghrib = true
                                settings.naggingIsha = true
                            } else {
                                settings.naggingFajr = false
                                settings.naggingSunrise = false
                                settings.naggingDhuhr = false
                                settings.naggingAsr = false
                                settings.naggingMaghrib = false
                                settings.naggingIsha = false
                            }
                        }
                    }
                ).animation(.easeInOut))
                .font(.subheadline)
                .tint(settings.accentColor.color)
                .onChange(of: settings.naggingMode) { _ in settings.hapticFeedback() }

                if settings.naggingMode {
                    Picker("Starting Time", selection: $settings.naggingStartOffset.animation(.easeInOut)) {
                        Text("45 mins").tag(45)
                        Text("30 mins").tag(30)
                        Text("15 mins").tag(15)
                        Text("10 mins").tag(10)
                    }
                    #if os(iOS)
                    .pickerStyle(.segmented)
                    #endif
                    .onChange(of: settings.naggingStartOffset) { _ in settings.hapticFeedback() }

                    Group {
                        Toggle("Nagging before Fajr", isOn: Binding(
                            get: { settings.naggingFajr },
                            set: { newValue in
                                settings.naggingFajr = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        .onChange(of: settings.naggingFajr) { _ in settings.hapticFeedback() }

                        Toggle("Nagging before Sunrise", isOn: Binding(
                            get: { settings.naggingSunrise },
                            set: { newValue in
                                settings.naggingSunrise = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        .onChange(of: settings.naggingSunrise) { _ in settings.hapticFeedback() }

                        Toggle("Nagging before Dhuhr", isOn: Binding(
                            get: { settings.naggingDhuhr },
                            set: { newValue in
                                settings.naggingDhuhr = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        .onChange(of: settings.naggingDhuhr) { _ in settings.hapticFeedback() }

                        Toggle("Nagging before Asr", isOn: Binding(
                            get: { settings.naggingAsr },
                            set: { newValue in
                                settings.naggingAsr = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        .onChange(of: settings.naggingAsr) { _ in settings.hapticFeedback() }

                        Toggle("Nagging before Maghrib", isOn: Binding(
                            get: { settings.naggingMaghrib },
                            set: { newValue in
                                settings.naggingMaghrib = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        .onChange(of: settings.naggingMaghrib) { _ in settings.hapticFeedback() }

                        Toggle("Nagging before Isha", isOn: Binding(
                            get: { settings.naggingIsha },
                            set: { newValue in
                                settings.naggingIsha = newValue
                                turnOffNaggingModeIfAllOff()
                            }
                        ).animation(.easeInOut))
                        .onChange(of: settings.naggingIsha) { _ in settings.hapticFeedback() }
                    }
                    .tint(settings.accentColor.color)
                }
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
                if !settings.naggingDhuhr {
                    NotificationSettingsSection(prayerName: "Dhuhr", preNotificationTime: $settings.preNotificationDhuhr, isNotificationOn: $settings.notificationDhuhr)
                }
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
                                .padding(.vertical, 2)
                        }
                    }
                }
            }

            if let travelNotificationCaption {
                Text(travelNotificationCaption)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
