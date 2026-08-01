import SwiftUI
import CoreLocation

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
                // Hold the prompt until the app is actually revealed - otherwise a calc/travel change detected
                // while AdhanView is still building behind the launch screen would pop a dialog over it. The
                // pending `showAlert` (or the standing flag via `nextAlertToPresent`) still presents at reveal.
                get: { showAlert != nil && appRevealed },
                set: { presented in
                    guard !presented else { return }
                    // ANY dismissal counts as seen - the system Cancel button and a tap outside included.
                    // Only the two action buttons used to clear the standing travel/calculation flags, so
                    // cancelling left the flag armed and the same dialog re-presented on every refresh,
                    // forever. Cancelling now means "accept what was auto-detected, silently."
                    // (Clearing again after an action button is a harmless no-op.)
                    switch showAlert {
                    case .travelTurnOnAutomatic, .travelTurnOffAutomatic:
                        settings.resetTravelAutomaticFlags()
                    case .calculationAutomaticChanged:
                        settings.confirmAutomaticCalculationChange()
                    default:
                        break
                    }
                    showAlert = nil
                }
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
                // Date/location and the sky are their own sections again - sharing one made the sky's rounded
                // card fight the rows above it. `compactListSectionSpacing` below closes the gap between them
                // so they still read as one stacked header rather than two floating islands.
                Section {
                    DateAndLocationSection(showBigQibla: $showBigQibla)
                }

                if settings.showSkyView, settings.prayers != nil, settings.currentLocation != nil {
                    Section {
                        SkyView()
                            .listRowBackground(Color.clear)
                    }
                }

                prayersSection

                // The tracker is its own section directly beneath the times: marking prayers is a
                // different activity from reading them, and it carries its own header, streak and
                // history entry point (see PrayerTrackerView.swift).
                PrayerTrackerSection()

                Section(header: Text("AT A GLANCE")) {
                    GlanceCard()
                }
                #else
                // Watch: the countdown and prayer times come first (that's the whole reason you raised your
                // wrist), then one compact card holding the date, the city and the Qibla - three separate
                // full-width rows was most of a screen's worth of scrolling for information you glance at.
                prayersSection

                Section {
                    watchPlaceCard
                }
                #endif
            }
            .themedListRowBackground()
        }
        // Sections stay separate but sit close together, so the header cards stack instead of drifting apart.
        .compactListSectionSpacing()
        .refreshable {
            // A manual refresh means "where am I NOW" - force a fresh fix, not just a re-geocode of the
            // stored coordinates (which, after a flight, faithfully re-resolved the departure city).
            settings.refreshLocationIfStale(olderThan: 30)
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
        // The dialog is presented from ONE place only: the completion of a prayer refresh (see
        // `prayerTimeRefresh`), a beat later. It is deliberately NOT presented from an `.onChange` on the
        // travel/calculation flags. Watching those flags means the dialog fires the instant the flag flips - 
        // from any background path, whether or not this screen is even on screen - which is what made it
        // re-present over and over. The flags are cleared by the dialog's own buttons (`confirmTravelAutomaticChange`
        // / `overrideTravelingMode`), so a change that happens while you're away is still waiting for you the
        // next time the tab refreshes, and is announced exactly once.
        .navigationTitle("Al-Adhan")
        #if os(iOS)
        .toolbar {
            // Leading toolbar is the first accent, trailing is the second - the same split the app uses for
            // sections. With a single-color accent the two are identical, so nothing changes visually there.
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    PrayerCalendarView()
                } label: {
                    Image(systemName: "calendar")
                }
                .simultaneousGesture(TapGesture().onEnded { settings.hapticFeedback() })
                .tint(settings.accentColor.accent1)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "gear")
                }
                .tint(settings.accentColor.accent2)
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
            // sky off, it returns to being its own section - nothing is lost by turning the drawing off.
            if !settings.showSkyView {
                // Equatable-gated: the countdown invalidates itself via its own timer and Settings
                // observation, so re-runs of this body (sheet flags, scroll state) can skip it.
                PrayerCountdown()
                    .equatable()
            }
            PrayerList()
        }
        #else
        if settings.prayers != nil {
            PrayerList()
            PrayerCountdown()
                .equatable()
        }
        #endif
    }

    #if os(watchOS)
    /// Date, city and Qibla in one row: the date and place stacked on the left, the compass on the right. Tap
    /// the compass to blow it up to the full width of the card, which is the only time it needs the room.
    private var watchPlaceCard: some View {
        VStack(spacing: 6) {
            // When the compass is blown up it is the thing you are looking at, so the date and city step back
            // to make room for it rather than competing with it.
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    if let hijriDate = settings.hijriDate {
                        // Two lines before any shrink: a long Hijri date used to compress to 60% on one
                        // line, which read as unreadably tiny on the small screens.
                        Text(hijriDate.english)
                            .font(showBigQibla ? .system(size: 9) : .caption2)
                            .foregroundColor(settings.accentColor.accent1)
                            .lineLimit(showBigQibla ? 1 : 2)
                            .minimumScaleFactor(0.8)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: settings.currentLocation != nil ? "location.fill" : "location.slash")
                            .font(showBigQibla ? .system(size: 9) : .caption2)
                            .foregroundColor(settings.accentColor.accent1)

                        Text((settings.prayers != nil ? settings.currentLocation?.city : nil) ?? "No location")
                            .font(showBigQibla ? .system(size: 10) : .caption)
                            .lineLimit(showBigQibla ? 1 : 2)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !showBigQibla {
                    qiblaCompass(size: 44)
                }
            }

            if showBigQibla {
                qiblaCompass(size: 90)

                // The exact spot the bearing was computed from - useful precisely when you are questioning
                // whether the compass is pointing where it should.
                if let location = settings.currentLocation,
                   location.latitude != 1000, location.longitude != 1000 {
                    Text(formatCoordinates(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ))
                    .font(.system(size: 9))
                    .monospacedDigit()
                    .foregroundColor(settings.accentColor.accent1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                }

                Text("The compass may not be accurate on Apple Watch")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        // The WHOLE card toggles the big compass - the gesture used to live only on the 44pt compass
        // image, leaving the date/city column (most of the row) dead to taps.
        .contentShape(Rectangle())
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation { showBigQibla.toggle() }
        }
        .animation(.easeInOut, value: showBigQibla)
    }

    private func qiblaCompass(size: CGFloat) -> some View {
        QiblaView(size: size)
    }
    #endif

    private func prayerTimeRefresh(force: Bool) {
        settings.requestNotificationAuthorization {
            settings.fetchPrayerTimes(force: force) {
                // The one place the confirmation is raised: after the refresh has actually settled, a beat
                // later so the list isn't still animating. `nextAlertToPresent` reads the standing flags, and
                // the dialog's buttons clear them - so it appears once, when you're looking at this screen.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if showAlert == nil { showAlert = nextAlertToPresent }
                }
            }
        }
    }

    // Keep alert selection in one place so refresh behavior is easy to follow.
    private var nextAlertToPresent: AlertType? {
        // Travel dialogs only on the device that owns the auto-check - never on a paired watch, where
        // the phone decides and these buttons would flip the just-synced value straight back.
        if settings.ownsTravelingModeAutoCheck {
            if settings.travelTurnOnAutomatic {
                return .travelTurnOnAutomatic
            }
            if settings.travelTurnOffAutomatic {
                return .travelTurnOffAutomatic
            }
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
            HStack(spacing: 12) {
                AccentIconChip(systemImage: "calendar", size: 26)

                Text(hijriDate.english)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text(hijriDate.arabic)
                    .font(.footnote)
                    .foregroundColor(settings.accentColor.color)
            }
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

                            // The coordinates were only copyable from the pill that appears when the compass is
                            // enlarged, which is a strange place to have to go looking for them.
                            if let location = settings.currentLocation,
                               location.latitude != 1000, location.longitude != 1000 {
                                Button {
                                    settings.hapticFeedback()
                                    UIPasteboard.general.string = formatCoordinates(
                                        latitude: location.latitude,
                                        longitude: location.longitude
                                    )
                                } label: {
                                    Label("Copy Coordinates", systemImage: "location.circle")
                                }
                            }
                        }
                }
                .padding(12)
                // Clean capsule glass - no .cornerRadius() clip, which previously cut the capsule into a
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
    /// compass is expanded - a precise readout of "where you actually are" beneath the resolved place name.
    @ViewBuilder
    private var coordinatesLabel: some View {
        if showBigQibla,
           let loc = settings.currentLocation,
           loc.latitude != 1000, loc.longitude != 1000 {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(settings.accentColor.color)

                Text(formatCoordinates(latitude: loc.latitude, longitude: loc.longitude))
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

}

/// Formats a coordinate pair as e.g. "21.4225° N, 39.8262° E".
///
/// Free function, not a static on `CurrentLocationRow`: that row is `private` and iOS-only, and the watch's
/// enlarged-compass card needs this too.
func formatCoordinates(latitude: Double, longitude: Double) -> String {
    let latDir = latitude >= 0 ? "N" : "S"
    let lonDir = longitude >= 0 ? "E" : "W"
    return String(format: "%.4f° %@, %.4f° %@", abs(latitude), latDir, abs(longitude), lonDir)
}



#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        AdhanView()
    }
}


