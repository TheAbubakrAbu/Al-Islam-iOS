import SwiftUI
import CoreLocation

struct AdhanView: View {
    @ObservedObject var settings = Settings.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared

    @Environment(\.scenePhase) private var scenePhase
    // False while this view is being built behind the launch/splash cover; holds prompts until we're on screen.
    @Environment(\.appRevealed) private var appRevealed

    #if os(iOS)
    /// The Adhan settings sheet, and which screen it opens on: the gear opens the root, the Prayer
    /// Calculation and Distance From Home glance tiles open their own screens (see `handleGlance`).
    /// An item sheet, not a Bool plus a separate target: the content closure of an `isPresented`
    /// sheet was built with the target still at its old value (logged 2026-09-05), whereas an item
    /// sheet hands the content the exact value that presented it.
    @State private var settingsSheet: SettingsSheetTarget?
    /// The sheet a glance tile opened, if any.
    @State private var glanceSheet: GlanceSheet?
    /// The calendar a glance tile pushed, if any (the two calendars are pushes, like the toolbar's).
    @State private var pushedCalendar: GlancePush?
    #endif
    /// DEBUG launch argument `-showBigQibla`: the location row opens with the 100 pt compass expanded
    /// (a tap toggles it and taps are not scriptable in the simulator), which is the only state that
    /// starts the heading updates and the GPS refinement burst.
    @State private var showBigQibla: Bool = {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-showBigQibla")
        #else
        false
        #endif
    }()
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

    /// DEBUG launch argument `-openPrayerTracker`: the tab's root becomes the tracker's History &
    /// Insights page, which is otherwise only reachable by a tap - the way to screenshot it headlessly
    /// (see the launch-arg notes in Settings.init).
    private var opensPrayerTrackerDirectly: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-openPrayerTracker")
        #else
        return false
        #endif
    }

    private var hoistsTrackerForDebug: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-adhanTrackerFirst")
        #else
        return false
        #endif
    }

    @ViewBuilder
    private var adhanRoot: some View {
        #if os(iOS)
        if opensPrayerTrackerDirectly {
            PrayerTrackerView()
        } else {
            adhanContent
        }
        #else
        adhanContent
        #endif
    }

    var body: some View {
        let _ = RenderCounter.hit("AdhanView")
        let _ = ChangePrinter.hit(Self.self)
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                NavigationStack {
                    adhanRoot
                }
            } else {
                NavigationView {
                    adhanRoot
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

                if settings.showSkyView, live.prayers != nil, live.currentLocation != nil {
                    Section {
                        SkyView()
                            .listRowBackground(Color.clear)
                    }
                }

                // The tracker is its own section directly beneath the times: marking prayers is a
                // different activity from reading them, and it carries its own header, streak and
                // history entry point (see PrayerTrackerView.swift). The DEBUG launch argument
                // `-adhanTrackerFirst` hoists it above the times, so the card can be screenshotted
                // without scrolling (there is no scroll tooling for the simulator).
                Group {
                    if hoistsTrackerForDebug {
                        PrayerTrackerSection()
                        prayersSection
                    } else {
                        prayersSection
                        PrayerTrackerSection()
                    }
                }

                Section(header: Text("AT A GLANCE")) {
                    GlanceCard(onSelect: handleGlance)
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
        // No GPS burst from the tab any more. It used to start a 25 s `kCLLocationAccuracyBest` burst on
        // every appear and activation, and each fix it accepted published `currentLocation` inside an
        // animation. A stale fix gets one cheap one-shot `requestLocation` instead (no-op when the last
        // commit is under five minutes old); only the expanded Qibla compass starts the burst.
        .onAppear {
            if appRevealed {
                prayerTimeRefresh(force: false)
                settings.refreshLocationIfStale()
            } else {
                // Behind the launch cover (this is the initial tab): compute today's list from the
                // stored location so the tab is right when the cover lifts, but no notification
                // round trip or prompt (a system alert over the launch screen) and no location work
                // yet. `.onChange(of: appRevealed)` runs both the moment we are on screen.
                settings.fetchPrayerTimes()
            }
        }
        .onChange(of: appRevealed) { revealed in
            guard revealed else { return }
            prayerTimeRefresh(force: false)
            settings.refreshLocationIfStale()
        }
        .onDisappear {
            settings.endLocationRefinement()
        }
        .onChange(of: scenePhase) { newScenePhase in
            // `AppLifecycle` already refreshes a stale fix on activation.
            if newScenePhase == .active {
                prayerTimeRefresh(force: false)
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
                    settingsSheet = .root
                } label: {
                    Image(systemName: "gear")
                }
                .tint(settings.accentColor.accent2)
            }
        }
        .sheet(item: $settingsSheet) { target in
            // A stack container, so the sheet can open straight onto a sub-screen (see
            // `SheetNavigationContainer`).
            SheetNavigationContainer {
                SettingsAdhanView(
                    showNotifications: true,
                    presentedAsSheet: true,
                    openTravelingMode: target == .travelingMode,
                    openPrayerCalculation: target == .prayerCalculation
                )
            }
            .smallMediumSheetPresentation()
        }
        // On the List, not on the glance row: the row is lazy and sits at the bottom of the tab, so a
        // destination declared there does not exist until the row has scrolled on screen.
        .modifier(GlanceCalendarPushes(pushed: $pushedCalendar))
        .sheet(item: $glanceSheet) { sheet in
            switch sheet {
            case .cityPrayerTimes:
                NavigationView {
                    PrayerTimesMapView()
                        .environmentObject(settings)
                }
                .navigationViewStyle(.stack)
                .smallMediumSheetPresentation()
            case .homeLocation:
                MapView(choosingPrayerTimes: false)
                    .environmentObject(settings)
                    .smallMediumSheetPresentation()
            case let .qibla(bearing, distance):
                QiblaSheet(bearing: bearing, distance: distance)
            }
        }
        #if DEBUG
        // "-glanceAction <name>": fire a glance tile's action after the reveal, since tiles are not
        // tappable from simctl. Names: city, calculation, qibla, prayerCalendar, hijriCalendar,
        // home, traveling.
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            guard let i = args.firstIndex(of: "-glanceAction"), args.indices.contains(i + 1) else { return }
            let action: GlanceAction? = {
                switch args[i + 1] {
                case "city": return .cityPrayerTimes
                case "calculation": return .prayerCalculation
                case "qibla": return .qibla(bearing: "19° NNE", distance: "8,198 mi (13,193 km)")
                case "prayerCalendar": return .prayerCalendar
                case "hijriCalendar": return .hijriCalendar
                case "home": return .homeLocation
                case "traveling": return .travelingMode
                default: return nil
                }
            }()
            guard let action else { return }
            Task { @MainActor in
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 700_000_000)
                handleGlance(action)
            }
        }
        #endif
        #endif
        .applyConditionalListStyle()
    }

    #if os(iOS)
    /// A glance tile was tapped: sheets for the place, compass and settings screens, pushes for the
    /// two calendars (the same destinations the tab's own controls reach, so a tile is a shortcut,
    /// never a second copy of a screen).
    private func handleGlance(_ action: GlanceAction) {
        switch action {
        case .cityPrayerTimes:
            glanceSheet = .cityPrayerTimes
        case .homeLocation:
            glanceSheet = .homeLocation
        case let .qibla(bearing, distance):
            glanceSheet = .qibla(bearing: bearing, distance: distance)
        case .prayerCalendar:
            pushedCalendar = .prayerCalendar
        case .hijriCalendar:
            pushedCalendar = .hijriCalendar
        case .prayerCalculation:
            settingsSheet = .prayerCalculation
        case .travelingMode:
            settingsSheet = .travelingMode
        }
    }

    #endif

    @ViewBuilder
    private var prayersSection: some View {
        #if os(iOS)
        if live.prayers != nil && live.currentLocation != nil {
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
        if live.prayers != nil {
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
                        Image(systemName: live.currentLocation != nil ? "location.fill" : "location.slash")
                            .font(showBigQibla ? .system(size: 9) : .caption2)
                            .foregroundColor(settings.accentColor.accent1)

                        Text((live.prayers != nil ? live.currentLocation?.city : nil) ?? "No location")
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
                if let location = live.currentLocation,
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
        // Likewise the calculation card: only on the device that owns the region detection. A paired watch
        // takes the phone's method, so its buttons would fight the value it was just handed.
        if settings.ownsAutomaticCalculationCheck, settings.calculationAutoChanged {
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
        NavigationLink(destination: LazyDestination { CalendarView() }) {
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
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared

    let showBigQibla: Bool
    @State private var showingPrayerTimesMap = false
    #if DEBUG
    @State private var showingWidgetGallery = false
    private static var widgetGalleryOpened = false

    /// The `-widgetGallery <page>` argument, read when the cover is built rather than held in state: this
    /// row is re-created by the list between its first appearance and the reveal, and a fresh state
    /// presented its default page.
    private static var widgetGalleryPage: String {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-widgetGallery"),
              arguments.indices.contains(index + 1), !arguments[index + 1].hasPrefix("-") else { return "glance" }
        return arguments[index + 1]
    }
    #endif

    var body: some View {
        let _ = RenderCounter.hit("CurrentLocationRow")
        let _ = ChangePrinter.hit(Self.self)
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
        #if DEBUG
        // "-openCityPrayerTimes": open the City Prayer Times sheet on appear (screenshot runs).
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-openCityPrayerTimes") {
                // After the reveal, like a real tap: presenting during the under-cover tab walk
                // presents from a detached NavigationStack (UIKit assert in the log).
                Task { @MainActor in
                    await AppReveal.waitUntilRevealed()
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    showingPrayerTimesMap = true
                }
            }
        }
        // "-widgetGallery <page>": every Adhan widget layout at its real size, for screenshot runs
        // (see WidgetGalleryView for the pages and `-widgetCity`). Presented after the reveal, like
        // the sheet above; once, since this row re-appears as the list scrolls.
        .onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-widgetGallery"), !Self.widgetGalleryOpened else { return }
            Self.widgetGalleryOpened = true
            Task { @MainActor in
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 500_000_000)
                showingWidgetGallery = true
            }
        }
        .fullScreenCover(isPresented: $showingWidgetGallery) {
            if #available(iOS 16.0, *) {
                WidgetGalleryView(page: Self.widgetGalleryPage)
            }
        }
        #endif
        .sheet(isPresented: $showingPrayerTimesMap) {
            NavigationView {
                PrayerTimesMapView()
                    .environmentObject(settings)
            }
            .navigationViewStyle(.stack)
            .smallMediumSheetPresentation()
        }
        #endif
    }

    @ViewBuilder
    private var locationLabel: some View {
        #if os(iOS)
        if let currentLoc = live.currentLocation {
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
                            if let location = live.currentLocation,
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
            if live.prayers != nil, let currentLoc = live.currentLocation {
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
           let loc = live.currentLocation,
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



#if os(iOS)
private enum SettingsSheetTarget: String, Identifiable {
    case root, prayerCalculation, travelingMode

    var id: String { rawValue }
}

private enum GlancePush {
    case prayerCalendar, hijriCalendar
}

/// The two calendar pushes a glance tile can make. `navigationDestination(isPresented:)` on the
/// tab's `NavigationStack` (iOS 16+); hidden `isActive` links for iOS 15's `NavigationView`, where
/// the destination modifier does nothing.
private struct GlanceCalendarPushes: ViewModifier {
    @Binding var pushed: GlancePush?

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .navigationDestination(isPresented: binding(.prayerCalendar)) { PrayerCalendarView() }
                .navigationDestination(isPresented: binding(.hijriCalendar)) { CalendarView() }
        } else {
            content.background(
                ZStack {
                    NavigationLink(isActive: binding(.prayerCalendar)) {
                        PrayerCalendarView()
                    } label: { EmptyView() }
                    NavigationLink(isActive: binding(.hijriCalendar)) {
                        CalendarView()
                    } label: { EmptyView() }
                }
                .hidden()
            )
        }
    }

    private func binding(_ target: GlancePush) -> Binding<Bool> {
        Binding(
            get: { pushed == target },
            set: { active in if !active, pushed == target { pushed = nil } }
        )
    }
}

private enum GlanceSheet: Identifiable {
    case cityPrayerTimes
    case homeLocation
    case qibla(bearing: String?, distance: String?)

    var id: String {
        switch self {
        case .cityPrayerTimes: return "city"
        case .homeLocation: return "home"
        case .qibla: return "qibla"
        }
    }
}

/// The Qibla and Distance to Makkah tiles' sheet: the big compass over the two lines the tiles showed.
/// At this size `QiblaView` starts the heading updates and the GPS refinement burst by itself.
private struct QiblaSheet: View {
    @ObservedObject private var settings = Settings.shared

    let bearing: String?
    let distance: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                QiblaView(size: 220)
                    .padding(.top, 12)

                VStack(spacing: 4) {
                    if let bearing {
                        Text(bearing)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                    }
                    if let distance {
                        Text("\(distance) to the Kaaba")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Hold the phone flat and turn until the arrow points straight up.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Qibla")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
        .smallMediumSheetPresentation()
    }
}
#endif

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        AdhanView()
    }
}


