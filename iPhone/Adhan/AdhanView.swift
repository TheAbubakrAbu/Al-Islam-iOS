import SwiftUI
import CoreLocation

/// True once the launch/splash cover has been lifted and the tabs are actually on screen. Views that fire
/// user-facing side effects on appear (e.g. AdhanView's prayer-calculation confirmation dialogs) read this so
/// they don't present while they're only being built behind the launch screen. Defaults to `true`, so anywhere
/// it isn't explicitly set (the Watch app, previews) behaves normally. Defined here because this file is shared
/// by both the iPhone and Watch targets; it's only *set* by the iPhone app root.
struct AppRevealedKey: EnvironmentKey { static let defaultValue = true }
extension EnvironmentValues {
    var appRevealed: Bool {
        get { self[AppRevealedKey.self] }
        set { self[AppRevealedKey.self] = newValue }
    }
}

struct AdhanView: View {
    @ObservedObject var settings = Settings.shared

    @Environment(\.scenePhase) private var scenePhase
    // False while this view is being built behind the launch/splash cover; holds prompts until we're on screen.
    @Environment(\.appRevealed) private var appRevealed

    @State private var showingSettingsSheet = false
    @State private var showBigQibla = false
    @State private var showAlert: AlertType?

    enum AlertType: Identifiable {
        case travelTurnOnAutomatic
        case travelTurnOffAutomatic
        case calculationAutomaticChanged
        case locationAlert
        case notificationAlert

        var id: Int {
            switch self {
            case .travelTurnOnAutomatic: return 1
            case .travelTurnOffAutomatic: return 2
            case .calculationAutomaticChanged: return 3
            case .locationAlert: return 4
            case .notificationAlert: return 5
            }
        }
    }

    var body: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                NavigationStack {
                    adhanContent
                }
            } else {
                NavigationView {
                    adhanContent
                }
                .navigationViewStyle(.stack)
            }
            #else
            NavigationView {
                adhanContent
            }
            #endif
        }
        .confirmationDialog(
            dialogTitle,
            isPresented: Binding(
                // Hold the prompt until the app is actually revealed — otherwise a calc/travel change detected
                // while AdhanView is still building behind the launch screen would pop a dialog over it. The
                // pending `showAlert` (or the standing flag via `nextAlertToPresent`) still presents at reveal.
                get: { showAlert != nil && appRevealed },
                set: { if !$0 { showAlert = nil } }
            ),
            titleVisibility: .visible
        ) {
            alertActions
        } message: {
            alertMessage
        }
    }

    private var adhanContent: some View {
        List {
            Group {
                #if os(iOS)
                // Date, location and Qibla stay where the thumb expects them; the sky sits beneath as the
                // header of the prayer information it now contains.
                DateAndLocationSection(showBigQibla: $showBigQibla)

                if settings.showSkyView, settings.prayers != nil, settings.currentLocation != nil {
                    Section {
                        SkyView()
                    }
                    .listRowBackground(Color.clear)
                }

                prayersSection

                Section(header: Text("AT A GLANCE")) {
                    GlanceCard()
                }
                #else
                // Watch order: prayer times first (2 per row), then countdown, then city, then qibla.
                prayersSection

                watchCityRow
                watchQiblaRow

                if let hijriDate = settings.hijriDate {
                    HijriDateRow(hijriDate: hijriDate)
                }
                #endif
            }
            .themedListRowBackground()
        }
        .refreshable {
            prayerTimeRefresh(force: true)
        }
        .onAppear {
            prayerTimeRefresh(force: false)
            settings.beginLocationRefinement()


        }
        .onDisappear {
            settings.endLocationRefinement()
        }
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .active {
                prayerTimeRefresh(force: false)
                settings.beginLocationRefinement()
            }
        }
        // Present the automatic-change confirmation the moment the flag flips, from ANY code path that runs
        // checkIfTraveling()/the auto-calculation change — not only after a prayer-fetch completion. That
        // gating made the dialog lag (waited for the fetch) and often never appear (when the flag flipped
        // from a fetch not routed through prayerTimeRefresh).
        // Consume each flag the instant it flips: capture it into `showAlert` (which now owns the
        // presentation) and immediately reset the @AppStorage flag. Otherwise the flag stayed set
        // until the user tapped a button — so a tap-outside dismissal, or simply leaving and
        // re-entering this tab (onAppear → fetch → nextAlertToPresent), re-presented the same dialog.
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
        // Belt-and-suspenders for the dialog: when a travel/calculation change is auto-detected while this
        // view isn't actively on screen — in the background, or behind the launch cover — the `.onChange`
        // handlers above can miss the flag flip (their baseline was captured while it was still false). The
        // standing @AppStorage flag persists, so the instant the app is revealed, present it directly instead
        // of depending on a later prayer-fetch completion firing.
        .onChange(of: appRevealed) { revealed in
            if revealed && showAlert == nil {
                showAlert = nextAlertToPresent
            }
        }
        .navigationTitle("Al-Adhan")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    PrayerCalendarView()
                } label: {
                    Image(systemName: "calendar")
                }
                .simultaneousGesture(TapGesture().onEnded { settings.hapticFeedback() })
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            NavigationView {
                SettingsAdhanView(showNotifications: true, presentedAsSheet: true)
            }
            .smallMediumSheetPresentation()
        }
        #endif
        .applyConditionalListStyle()
    }

    @ViewBuilder
    private var prayersSection: some View {
        #if os(iOS)
        if settings.prayers != nil && settings.currentLocation != nil {
            // With the sky on, the countdown rides inside its card (see `SkyView.countdownStrip`). With the
            // sky off, it returns to being its own section — nothing is lost by turning the drawing off.
            if !settings.showSkyView {
                PrayerCountdown()
            }
            PrayerList()
        }
        #else
        if settings.prayers != nil {
            PrayerList()
            PrayerCountdown()
        }
        #endif
    }

    #if os(watchOS)
    private var watchCityRow: some View {
        HStack(spacing: 6) {
            Image(systemName: settings.currentLocation != nil ? "location.fill" : "location.slash")
                .foregroundColor(settings.accentColor.color)
            Text((settings.prayers != nil ? settings.currentLocation?.city : nil) ?? "No location")
                .font(.subheadline)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var watchQiblaRow: some View {
        VStack(spacing: 6) {
            QiblaView(size: showBigQibla ? 100 : 50)
                .animation(.easeInOut, value: showBigQibla)
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation { showBigQibla.toggle() }
                }

            Text("Compass may not be accurate on Apple Watch")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }
    #endif

    private func prayerTimeRefresh(force: Bool) {
        settings.requestNotificationAuthorization {
            settings.fetchPrayerTimes(force: force) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Don't clobber a dialog the .onChange handlers already presented (travel/calc are
                    // now consumed there). This only fills in the location/notification prompts.
                    if showAlert == nil { showAlert = nextAlertToPresent }
                }
            }
        }
    }

    // Keep alert selection in one place so refresh behavior is easy to follow.
    private var nextAlertToPresent: AlertType? {
        if settings.travelTurnOnAutomatic {
            return .travelTurnOnAutomatic
        }
        if settings.travelTurnOffAutomatic {
            return .travelTurnOffAutomatic
        }
        if settings.calculationAutoChanged {
            return .calculationAutomaticChanged
        }
        if !settings.locationNeverAskAgain && settings.showLocationAlert {
            return .locationAlert
        }
        if !settings.notificationNeverAskAgain && settings.showNotificationAlert {
            return .notificationAlert
        }
        return nil
    }

    private var dialogTitle: String {
        switch showAlert {
        case .travelTurnOnAutomatic:
            return "Traveling Mode Detected"
        case .travelTurnOffAutomatic:
            return "Traveling Mode Updated"
        case .calculationAutomaticChanged:
            return "Calculation Method Changed"
        case .locationAlert:
            return "Location Access Needed"
        case .notificationAlert:
            return "Notifications Off"
        case .none:
            return ""
        }
    }

    @ViewBuilder
    private var alertActions: some View {
        switch showAlert {
        case .travelTurnOnAutomatic:
            Button("Override: Turn Off", role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.overrideTravelingMode(keepOn: false)
                }
            }

            Button("Confirm: Keep On") {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.confirmTravelAutomaticChange()
                }
            }

        case .travelTurnOffAutomatic:
            Button("Override: Keep On", role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.overrideTravelingMode(keepOn: true)
                }
            }

            Button("Confirm: Turn Off") {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.confirmTravelAutomaticChange()
                }
            }

        case .calculationAutomaticChanged:
            Button("Override: Keep \(settings.calculationAutoPreviousMethod)", role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.overrideAutomaticCalculationKeepingPrevious()
                }
            }

            Button("Confirm: Use \(settings.calculationAutoDetectedMethod)") {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.confirmAutomaticCalculationChange()
                }
            }

        case .locationAlert:
            Button("Open Settings") {
                settings.hapticFeedback()
                openAppSettings()
            }
            Button("Never Ask Again", role: .destructive) {
                settings.hapticFeedback()
                settings.locationNeverAskAgain = true
            }
            Button("Ignore") {
                settings.hapticFeedback()
            }

        case .notificationAlert:
            Button("Open Settings") {
                settings.hapticFeedback()
                openAppSettings()
            }
            Button("Never Ask Again", role: .destructive) {
                settings.hapticFeedback()
                settings.notificationNeverAskAgain = true
            }
            Button("Ignore") {
                settings.hapticFeedback()
            }

        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var alertMessage: some View {
        switch showAlert {
        case .travelTurnOnAutomatic:
            Text(settings.automaticTravelMessage(turnOn: true))
        case .travelTurnOffAutomatic:
            Text(settings.automaticTravelMessage(turnOn: false))
        case .calculationAutomaticChanged:
            Text(settings.automaticCalculationMessage)
        case .locationAlert:
            Text("Please go to Settings and enable location services to accurately determine prayer times.")
        case .notificationAlert:
            Text("Please go to Settings and enable notifications to be notified of prayer times.")
        case .none:
            EmptyView()
        }
    }

    private func openAppSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #endif
    }
}

private struct DateAndLocationSection: View {
    @ObservedObject private var settings = Settings.shared

    @Binding var showBigQibla: Bool

    var body: some View {
        if let hijriDate = settings.hijriDate {
            HijriDateRow(hijriDate: hijriDate)
        }

        CurrentLocationRow(showBigQibla: showBigQibla)
            .animation(.easeInOut, value: showBigQibla)
            #if os(iOS)
            .onTapGesture {
                withAnimation {
                    settings.hapticFeedback()
                    showBigQibla.toggle()
                }
            }
            #endif
    }
}

private struct HijriDateRow: View {
    @ObservedObject private var settings = Settings.shared

    let hijriDate: HijriDate

    var body: some View {
        #if os(iOS)
        NavigationLink(destination: CalendarView()) {
            HStack {
                Text(hijriDate.english)
                    .multilineTextAlignment(.center)

                Spacer()

                Text(hijriDate.arabic)
            }
            .font(.footnote)
            .foregroundColor(settings.accentColor.color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contextMenu {
                Text("Date Actions")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = hijriDate.english
                } label: {
                    Label("Copy English Date", systemImage: "doc.on.doc")
                }

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = hijriDate.arabic
                } label: {
                    Label("Copy Arabic Date", systemImage: "doc.on.doc")
                }
            }
        }
        #else
        Text(hijriDate.english)
            .font(.footnote)
            .foregroundColor(settings.accentColor.color)
            .frame(maxWidth: .infinity, alignment: .center)
        #endif
    }
}

private struct CurrentLocationRow: View {
    @ObservedObject private var settings = Settings.shared

    let showBigQibla: Bool
    @State private var showingPrayerTimesMap = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    locationLabel
                    coordinatesLabel
                }

                Spacer()

                QiblaView(size: showBigQibla ? 100 : 50)
                    .padding(.leading)
                    .padding(.trailing, 4)
            }
            .foregroundColor(.primary)
            .font(.subheadline)
            .contentShape(Rectangle())

            #if os(watchOS)
            Text("Compass may not be accurate on Apple Watch")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            #endif
        }
        #if os(iOS)
        .sheet(isPresented: $showingPrayerTimesMap) {
            NavigationView {
                PrayerTimesMapView()
                    .environmentObject(settings)
            }
            .smallMediumSheetPresentation()
        }
        #endif
    }

    @ViewBuilder
    private var locationLabel: some View {
        #if os(iOS)
        if let currentLoc = settings.currentLocation {
            let currentCity = currentLoc.city

            Button {
                settings.hapticFeedback()
                showingPrayerTimesMap = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundColor(settings.accentColor.color)
                        .padding(.trailing, 8)

                    Text(currentCity)
                        .font(.subheadline)
                        .lineLimit(nil)
                        .contextMenu {
                            Text("City Actions")
                                .foregroundStyle(.secondary)

                            Button {
                                settings.hapticFeedback()
                                UIPasteboard.general.string = currentCity
                            } label: {
                                Label("Copy City Name", systemImage: "doc.on.doc")
                            }
                        }
                }
                .padding(12)
                // Clean capsule glass — no .cornerRadius() clip, which previously cut the capsule into a
                // hard-edged box that looked wrong in Sepia.
                .conditionalGlassEffect()
            }
            .buttonStyle(.plain)
        } else {
            HStack(spacing: 0) {
                Image(systemName: "location.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(settings.accentColor.color)
                    .padding(.trailing, 8)

                Text("No location")
                    .font(.subheadline)
                    .lineLimit(nil)
            }
        }
        #else
        Group {
            if settings.prayers != nil, let currentLoc = settings.currentLocation {
                Text(currentLoc.city)
            } else {
                Text("No location")
            }
        }
        .font(.subheadline)
        .lineLimit(2)
        #endif
    }

    /// The device's actual latitude/longitude, shown under the location (city) only while the big Qibla
    /// compass is expanded — a precise readout of "where you actually are" beneath the resolved place name.
    @ViewBuilder
    private var coordinatesLabel: some View {
        if showBigQibla,
           let loc = settings.currentLocation,
           loc.latitude != 1000, loc.longitude != 1000 {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(settings.accentColor.color)

                Text(Self.formatCoordinates(latitude: loc.latitude, longitude: loc.longitude))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .conditionalGlassEffect()
            .padding(.leading, 2)
            .padding(.top, 8)
            #if os(iOS)
            .contextMenu {
                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = "\(loc.latitude), \(loc.longitude)"
                } label: {
                    Label("Copy Coordinates", systemImage: "doc.on.doc")
                }
            }
            #endif
            .transition(.opacity)
        }
    }

    /// Formats a coordinate pair as e.g. "21.4225° N, 39.8262° E".
    static func formatCoordinates(latitude: Double, longitude: Double) -> String {
        let latDir = latitude >= 0 ? "N" : "S"
        let lonDir = longitude >= 0 ? "E" : "W"
        return String(format: "%.4f° %@, %.4f° %@", abs(latitude), latDir, abs(longitude), lonDir)
    }
}



#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        AdhanView()
    }
}


