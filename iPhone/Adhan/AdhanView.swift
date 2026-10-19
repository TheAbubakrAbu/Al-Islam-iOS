import SwiftUI
import CoreLocation
import UserNotifications

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
    /// Whether the list is in front (between `onAppear` and `onDisappear`): the flag-driven presentation
    /// in `autoChangeFlagsDidChange` only fires while it is.
    @State private var isOnScreen = false
    #if os(iOS)
    /// The permissions sheet (PermissionsSheet.swift): location and notifications, explained and asked
    /// for from one place, before either system prompt. Presented once this tab is in front after the
    /// welcome; its dismissal runs the refresh the bare prompts used to lead into.
    @State private var showPermissionsSheet = false
    @State private var permissionsSheetChecked = false
    /// The scheme the list's content keeps while the sky does not fill the tab (`skyPageContent`).
    @Environment(\.colorScheme) private var colorScheme
    #endif

    enum AlertType: Identifiable {
        case travelTurnOnAutomatic
        case travelTurnOffAutomatic
        case calculationAutomaticChanged
        case locationAlert
        case notificationAlert

        /// The cards that answer a standing auto-change flag (as opposed to the permission nags).
        var isAutoChangeCard: Bool {
            switch self {
            case .travelTurnOnAutomatic, .travelTurnOffAutomatic, .calculationAutomaticChanged: return true
            case .locationAlert, .notificationAlert: return false
            }
        }

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
        #if DEBUG
        let _ = LaunchClock.markOnce("adhan root: first body")
        #endif
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
                    // Ignore, Open Settings or a tap outside: quiet for a day, not until the next
                    // app open. Never Ask Again has already set its permanent flag.
                    case .locationAlert:
                        settings.snoozePermissionAlert(location: true)
                    case .notificationAlert:
                        settings.snoozePermissionAlert(location: false)
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

    /// Simple Mode shows the tracker to someone who tracks: any prayer marked in the last
    /// `SimpleMode.trackerWindowDays` (Docs/Product/Simple Mode Guide.md). Marking one from a prayer's detail
    /// brings it back. At most fourteen lookups into the cached tracker, so the countdown tick can ask.
    private var showsTracker: Bool {
        !settings.simpleMode || settings.trackerMarkedRecently()
    }

    #if os(iOS)
    /// The sky under the whole tab (`Settings.skyFillsAdhanTab`, SkyPageBackground.swift): only with
    /// the sky on and something to paint it from, like the card itself.
    private var fillsSky: Bool {
        settings.showSkyView && settings.skyFillsAdhanTab && live.prayers != nil && live.currentLocation != nil
    }

    /// The prayer list's layout: the key `PrayerList` draws from and Prayer Settings' Prayer Times Layout
    /// row writes. The watch always draws tiles, so the choice is the phone's alone.
    @AppStorage("prayerDisplayModeV2") private var prayerDisplayModeRawValue: String = PrayerList.PrayerDisplayMode.tiles.rawValue

    /// The tab's ⋯ More menu: the Prayer and Hijri calendars (pushed through `GlanceCalendarPushes`,
    /// the same doors the glance tiles use, so the menu and the tiles can never stack two pushes), then
    /// the prayer list's layout as a submenu (Abu, 2026-10-11: "have it be a menu that opens the
    /// other"), the current one ticked inside it and named under the row.
    @ViewBuilder
    private var adhanMoreItems: some View {
        TabMoreMenuItem("Prayer Calendar", systemImage: "calendar") {
            settings.hapticFeedback()
            if pushedCalendar == nil { pushedCalendar = .prayerCalendar }
        }
        TabMoreMenuItem("Hijri Calendar", systemImage: "moon.stars") {
            settings.hapticFeedback()
            if pushedCalendar == nil { pushedCalendar = .hijriCalendar }
        }

        Divider()

        let layout = PrayerList.PrayerDisplayMode(rawValue: prayerDisplayModeRawValue) ?? .tiles
        Menu {
            Picker("Prayer Times Layout", selection: prayerLayoutSelection) {
                ForEach(PrayerList.PrayerDisplayMode.allCases) { mode in
                    Label(mode.displayName.capitalized, systemImage: mode.menuSymbol).tag(mode.rawValue)
                }
            }
            .pickerStyle(.inline)
        } label: {
            // The second Text is the row's subtitle (the Files app's Sort By): which layout is on,
            // without opening the submenu.
            Label("Prayer Times Layout", systemImage: layout.menuSymbol)
            Text(layout.displayName.capitalized)
        }
    }

    /// The picker's binding, with the haptic the header picker's `onChange` used to give: a modifier on
    /// a view inside a menu is not reliably alive, so the binding's setter taps instead.
    private var prayerLayoutSelection: Binding<String> {
        Binding(
            get: { prayerDisplayModeRawValue },
            set: { newValue in
                guard newValue != prayerDisplayModeRawValue else { return }
                settings.hapticFeedback()
                prayerDisplayModeRawValue = newValue
            }
        )
    }
    #endif

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
                        SkyView(pageSky: fillsSky)
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
                        if showsTracker { PrayerTrackerSection() }
                        prayersSection
                    } else {
                        prayersSection
                        if showsTracker { PrayerTrackerSection() }
                    }
                }

                // Need a Hand?: the questions this tab's readers ask (praying on time, traveling),
                // each with the setting that answers it, between the tracker and the glance wall.
                // See HelpDoors.swift.
                HelpDoorsSection(area: .adhan)

                // Simple Mode leaves the glance wall out: each tile is a shortcut to a door the tab
                // already has (the calendar button, the compass, the city pill, the sky's moon).
                if !settings.simpleMode {
                    Section(header: SectionIconHeader("AT A GLANCE", icon: "rectangle.grid.2x2.fill")) {
                        GlanceCard(onSelect: handleGlance)
                    }
                }
                #else
                // Watch: the countdown and prayer times come first (that's the whole reason you raised your
                // wrist), then one compact card holding the date, the city and the Qibla - three separate
                // full-width rows was most of a screen's worth of scrolling for information you glance at.
                // Traveling mode leads here too, as a filled accent row: the four combined prayers
                // below it need their reason in sight.
                if settings.travelingMode {
                    watchTravelingRow
                }

                prayersSection

                Section {
                    watchPlaceCard
                }
                #endif
            }
            .themedListRowBackground()
            #if os(iOS)
            // Under the whole-tab sky the rows are its glass and the content draws light-on-dark. On
            // the content, never the List: the sheets below would inherit the dark scheme otherwise.
            .skyPageContent(active: fillsSky, scheme: colorScheme)
            #endif
        }
        #if os(iOS)
        .skyPageFill(active: fillsSky, paused: !isOnScreen)
        #endif
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
            isOnScreen = true
            if appRevealed {
                #if os(iOS)
                openPendingQiblaIfAny()
                #endif
                askLocationThenRefresh()
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
            LaunchClock.mark("adhan root: reveal refresh")
            // The location question waits for this tab to be in front (a learner's welcome lands on
            // the Islam tab); the refresh runs either way, as it always has.
            if isOnScreen {
                #if os(iOS)
                openPendingQiblaIfAny()
                #endif
                askLocationThenRefresh()
            } else {
                // Off screen (a learner's welcome lands on the Islam tab): the times refresh, but no
                // system prompt. The permissions sheet is the one door to both prompts since
                // 2026-10-11, and it is offered the first time this tab comes in front.
                prayerTimeRefresh(force: false, askNotifications: false)
            }
            settings.refreshLocationIfStale()
        }
        .onDisappear {
            isOnScreen = false
            settings.endLocationRefinement()
        }
        .onChange(of: scenePhase) { newScenePhase in
            // `AppLifecycle` already refreshes a stale fix on activation.
            if newScenePhase == .active {
                prayerTimeRefresh(force: false)
            }
        }
        // The dialog is presented from two places: the completion of a prayer refresh (see
        // `prayerTimeRefresh`), a beat later, and - only while this list is in front - a change of the
        // standing travel/calculation flags (`autoChangeFlagsDidChange`). The second catches the common
        // case: the launch refresh completes on the STORED location, and the fresh fix that flips the
        // verdict lands a second later. Without it the card waited for the next refresh, and a card
        // already up kept showing the previous verdict (a "returned home" card in Las Vegas, reproduced
        // 2026-09-13). An earlier blanket `.onChange` re-presented forever because Cancel left the flag
        // armed; every dismissal clears the flags now, so a flag only ever changes on a real verdict, and
        // a change that happens while you're away still waits for the next refresh, announced once.
        .onChange(of: settings.travelTurnOnAutomatic) { _ in autoChangeFlagsDidChange() }
        .onChange(of: settings.travelTurnOffAutomatic) { _ in autoChangeFlagsDidChange() }
        .onChange(of: settings.calculationAutoChanged) { _ in autoChangeFlagsDidChange() }
        .navigationTitle("Al-Adhan")
        #if os(iOS)
        .toolbar {
            // The leading slot is the ⋯ More menu, in both modes (Abu, 2026-10-11: "for prayer have it
            // contain a menu to switch between tiles and grid and whatnot"): the two calendars, then the
            // prayer list's layout, which until then was a picker in the PRAYER TIMES header. The gear
            // keeps the trailing slot. Leading tints the first accent, trailing the second, the same
            // split the app uses for sections.
            ToolbarItem(placement: .navigationBarLeading) {
                TabMoreMenu { adhanMoreItems }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    // One sheet at a time: the glance sheets and this one are two `.sheet` bridges on
                    // the same List, and raising this one while the Qibla sheet was coming up (a
                    // Control Center tap, then the gear within a second) left SwiftUI holding a second
                    // sheet it could never show ("only presenting a single sheet is supported", logged
                    // on every update for the rest of the session; the stress walk, 2026-10-12).
                    guard glanceSheet == nil, !showPermissionsSheet else { return }
                    settingsSheet = .root
                } label: {
                    Image(systemName: "gear")
                }
                .tint(settings.accentColor.accent2)
                .accessibilityLabel("Adhan Settings")
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
        // The Control Center Qibla control, on the List for the same reason (`openQiblaFromControl`).
        .onReceive(AppNavigation.shared.$pendingAdhan) { target in
            guard case .qibla = target else { return }
            // The tab switch (MainTabView) and this publish land in one update: with the tab not in
            // the window yet, a sheet raised now is deferred by SwiftUI with a fault ("A sheet was
            // presented but its presenter is not yet in the window"; the stress walk, 2026-10-13).
            // The target stays pending, and `onAppear` opens it once the tab is in front (behind the
            // launch cover, the reveal does).
            guard isOnScreen, appRevealed else { return }
            openQiblaFromControl()
        }
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
            case .weather:
                #if HAS_WEATHER
                WeatherDetailSheet()
                #else
                EmptyView()
                #endif
            }
        }
        .sheet(isPresented: $showPermissionsSheet, onDismiss: permissionsSheetDismissed) {
            PermissionsSheet()
        }
        #if DEBUG
        // "-glanceAction <name>": fire a glance tile's action after the reveal, since tiles are not
        // tappable from simctl. Names: city, calculation, qibla, prayerCalendar, hijriCalendar,
        // home, traveling, weather.
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
                case "weather": return .weather
                default: return nil
                }
            }()
            guard let action else { return }
            Task { @MainActor in
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 700_000_000)
                // A launch dialog (the calculation or traveling card, a permission question) can be up
                // for the first second or two after the reveal, and a sheet raised under it is refused
                // by UIKit ("Attempt to present ... which is already presenting"): wait for the screen
                // to be free, as the real tap on a tile always is.
                for _ in 0..<40 where ModalPresence.isPresenting {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
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
    /// A Control Center Qibla request that arrived while this tab was off screen or behind the launch
    /// cover (see the `.onReceive` on the List): opened the moment the tab is in front.
    private func openPendingQiblaIfAny() {
        guard case .qibla = AppNavigation.shared.pendingAdhan else { return }
        openQiblaFromControl()
    }

    /// The Control Center "Open Qibla" control (ControlIntents), answered on this always-mounted list:
    /// the glance card that used to answer it is not on screen in Simple Mode, and as the last row of a
    /// lazy list it was not always built in Full Mode either. Cleared on arrival, so the control works
    /// a second time.
    private func openQiblaFromControl() {
        AppNavigation.shared.pendingAdhan = nil
        let values = live.currentLocation.map {
            GlanceCard.qiblaValues(latitude: $0.latitude, longitude: $0.longitude)
        }
        handleGlance(.qibla(bearing: values?.bearing, distance: values?.distance))
    }

    private func handleGlance(_ action: GlanceAction) {
        // One sheet at a time (see the gear button): a second request while one is up is dropped,
        // the way a second tap on a door is dropped everywhere else in the app.
        let sheetIsUp = glanceSheet != nil || settingsSheet != nil || showPermissionsSheet
        switch action {
        case .cityPrayerTimes:
            if !sheetIsUp { glanceSheet = .cityPrayerTimes }
        case .homeLocation:
            if !sheetIsUp { glanceSheet = .homeLocation }
        case let .qibla(bearing, distance):
            if !sheetIsUp { glanceSheet = .qibla(bearing: bearing, distance: distance) }
        // One calendar at a time: flipping to the other mid-push swaps two isPresented flags on one stack.
        case .prayerCalendar:
            if pushedCalendar == nil { pushedCalendar = .prayerCalendar }
        case .hijriCalendar:
            if pushedCalendar == nil { pushedCalendar = .hijriCalendar }
        case .prayerCalculation:
            if !sheetIsUp { settingsSheet = .prayerCalculation }
        case .travelingMode:
            if !sheetIsUp { settingsSheet = .travelingMode }
        case .weather:
            if !sheetIsUp { glanceSheet = .weather }
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
            // Traveling mode sits right under the countdown, above the list it explains - one compact
            // row (Abu, 2026-10-19: "smaller and simpler ... before or after prayer countdown"; it was
            // a loud card leading the whole tab). With the sky on, the countdown rides in the sky
            // card, so this is the first row beneath it either way.
            travelingSection
            PrayerList()
        } else {
            travelingSection
        }
        #else
        if live.prayers != nil {
            PrayerList()
            PrayerCountdown()
                .equatable()
        }
        #endif
    }

    #if os(iOS)
    /// The traveling-mode row: what Qasr changed, how far from home, and the door to Travel Settings
    /// (see TravelingModeBanner.swift). "View Full Prayers" stays in the footer under the list.
    @ViewBuilder
    private var travelingSection: some View {
        if settings.travelingMode {
            Section {
                TravelingModeBanner(openTravelSettings: { settingsSheet = .travelingMode })
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    #endif

    #if os(watchOS)
    /// The watch's traveling-mode lead: plane, the mode's name and what it does, on a solid accent row.
    private var watchTravelingRow: some View {
        Section {
            HStack(spacing: 8) {
                Image(systemName: "airplane")
                    .font(.system(size: 16, weight: .bold))
                    .rotationEffect(.degrees(-30))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Traveling Mode")
                        .font(.footnote.weight(.bold))
                    Text(settings.travelingShowFullPrayers ? "Showing full prayers" : "Qasr: shortened, combined")
                        .font(.caption2)
                        .opacity(0.9)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(settings.accentColor.color)
            )
        }
    }

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

    /// Location first, then the refresh, which is where the notification question is asked: one system
    /// prompt at a time, and neither over the welcome (launch no longer asks for location).
    ///
    /// Since 2026-10-11 the permissions sheet stands in front of both prompts (PermissionsSheet.swift):
    /// while a permission is unanswered and the sheet is due, it is presented instead and the refresh
    /// runs when it closes; while its Not Now stands (a day), the tab refreshes WITHOUT raising either
    /// system prompt, so the sheet is the one door to them. Snoozed is also what "-skipNotificationPrompt"
    /// runs look like for notifications, which the existing DEBUG gate inside already handles.
    private func askLocationThenRefresh() {
        #if os(iOS)
        if !permissionsSheetChecked {
            permissionsSheetChecked = true
            Task { @MainActor in
                let due = await PermissionsSheet.shouldPresent(settings)
                #if DEBUG
                NSLog("PERMISSIONS SHEET due=%d onScreen=%d revealed=%d", due ? 1 : 0, isOnScreen ? 1 : 0, AppReveal.revealed ? 1 : 0)
                #endif
                if due {
                    // A beat after the reveal, so the sheet rises over a settled tab rather than
                    // mid-dissolve; the refresh follows its dismissal. `AppReveal.revealed` is the
                    // live mirror of `appRevealed`: a captured environment value would be stale here.
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    guard isOnScreen, AppReveal.revealed, !showPermissionsSheet,
                          glanceSheet == nil, settingsSheet == nil else {
                        // The tab left the screen in that beat (or the cover is still up, or another
                        // sheet of this tab is up: a glance tile or a deep link in that beat raised one,
                        // and two sheets on one List is the fault the gear button describes): the sheet
                        // is offered again the next time the tab asks, and nothing prompts meanwhile.
                        // Falling through to the refresh here raised the two bare system prompts over
                        // whatever tab the user had gone to, and the sheet never came (checked once).
                        permissionsSheetChecked = false
                        return
                    }
                    showPermissionsSheet = true
                } else {
                    askLocationThenRefresh()
                }
            }
            return
        }
        let now = Date()
        let locationSnoozed = SimpleMode.isSnoozed(until: settings.locationAlertSnoozedUntil, now: now)
        let notificationsSnoozed = SimpleMode.isSnoozed(until: settings.notificationAlertSnoozedUntil, now: now)
        if locationSnoozed {
            prayerTimeRefresh(force: false, askNotifications: !notificationsSnoozed)
        } else {
            settings.requestLocationIfUndetermined {
                prayerTimeRefresh(force: false, askNotifications: !notificationsSnoozed)
            }
        }
        #else
        settings.requestLocationIfUndetermined {
            prayerTimeRefresh(force: false)
        }
        #endif
    }

    #if os(iOS)
    /// The permissions sheet closed, by its Done, its Not Now, or a swipe. Whatever is still unanswered
    /// waits a day (the dialogs' snooze), then the usual refresh, which asks nothing while it waits.
    private func permissionsSheetDismissed() {
        let center = UNUserNotificationCenter.current()
        Task { @MainActor in
            let notifications = await center.notificationSettings().authorizationStatus
            if Settings.locationManager.authorizationStatus == .notDetermined {
                settings.snoozePermissionAlert(location: true)
            }
            if notifications == .notDetermined {
                settings.snoozePermissionAlert(location: false)
            }
            askLocationThenRefresh()
        }
    }
    #endif

    private func prayerTimeRefresh(force: Bool, askNotifications: Bool = true) {
        settings.requestNotificationAuthorization(askIfUndetermined: askNotifications) {
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

    /// A standing auto-change flag changed: keep `showAlert` in step with the flags. A card not yet chosen
    /// is presented now, but only while this list is in front. A card already chosen but not yet visible
    /// (behind the launch cover - the launch refresh picks from the stored location, and the fresh fix
    /// that flips the verdict lands before the cover lifts) is simply swapped. A card already on screen
    /// is dismissed and re-presented a beat later, because a presented confirmation dialog does not
    /// re-render its title and buttons in place. Flags cleared under a card (its own button, or the
    /// retirement in `checkIfTraveling`) take the card down. Permission nags are never presented from here.
    private func autoChangeFlagsDidChange() {
        let next = nextAlertToPresent.flatMap { $0.isAutoChangeCard ? $0 : nil }
        switch showAlert {
        case nil:
            guard isOnScreen, appRevealed, scenePhase == .active, let next else { return }
            showAlert = next
        case .travelTurnOnAutomatic, .travelTurnOffAutomatic, .calculationAutomaticChanged:
            guard next?.id != showAlert?.id else { return }
            guard appRevealed else {
                showAlert = next
                return
            }
            showAlert = nil
            guard next != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                guard showAlert == nil, let again = nextAlertToPresent, again.isAutoChangeCard else { return }
                showAlert = again
            }
        default:
            break
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
        // A dismissed permission dialog waits a day before it asks again (`snoozePermissionAlert`).
        let now = Date()
        if !settings.locationNeverAskAgain && settings.showLocationAlert
            && !SimpleMode.isSnoozed(until: settings.locationAlertSnoozedUntil, now: now) {
            return .locationAlert
        }
        if !settings.notificationNeverAskAgain && settings.showNotificationAlert
            && !SimpleMode.isSnoozed(until: settings.notificationAlertSnoozedUntil, now: now) {
            return .notificationAlert
        }
        return nil
    }

    /// The automatic-change cards' copy lives in `Settings.AutoChangeCard`, shared with the settings
    /// sheet's copy of these dialogs.
    private var autoChangeCard: Settings.AutoChangeCard? {
        switch showAlert {
        case .travelTurnOnAutomatic: return settings.autoChangeCard(.travelOn)
        case .travelTurnOffAutomatic: return settings.autoChangeCard(.travelOff)
        case .calculationAutomaticChanged: return settings.autoChangeCard(.calculation)
        default: return nil
        }
    }

    private var dialogTitle: String {
        if let card = autoChangeCard { return card.title }
        switch showAlert {
        case .locationAlert:
            return "Location Access Needed"
        case .notificationAlert:
            return "Notifications Off"
        default:
            return ""
        }
    }

    @ViewBuilder
    private var alertActions: some View {
        switch showAlert {
        // Accept first, put back second, no destructive red (see `AutoChangeCard`).
        case .travelTurnOnAutomatic:
            Button(settings.autoChangeCard(.travelOn).confirmTitle) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.confirmTravelAutomaticChange()
                }
            }

            Button(settings.autoChangeCard(.travelOn).overrideTitle) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.overrideTravelingMode(keepOn: false)
                }
            }

        case .travelTurnOffAutomatic:
            Button(settings.autoChangeCard(.travelOff).confirmTitle) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.confirmTravelAutomaticChange()
                }
            }

            Button(settings.autoChangeCard(.travelOff).overrideTitle) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.overrideTravelingMode(keepOn: true)
                }
            }

        case .calculationAutomaticChanged:
            Button(settings.autoChangeCard(.calculation).confirmTitle) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.confirmAutomaticCalculationChange()
                }
            }

            Button(settings.autoChangeCard(.calculation).overrideTitle) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.overrideAutomaticCalculationKeepingPrevious()
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
        case .travelTurnOnAutomatic, .travelTurnOffAutomatic, .calculationAutomaticChanged:
            Text(autoChangeCard?.message ?? "")
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

        CurrentLocationRow(showBigQibla: showBigQibla, toggleQibla: toggleQibla)
            .animation(.easeInOut, value: showBigQibla)
            #if os(iOS)
            .onTapGesture(perform: toggleQibla)
            #endif
    }

    private func toggleQibla() {
        withAnimation {
            settings.hapticFeedback()
            showBigQibla.toggle()
        }
    }
}

private struct HijriDateRow: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let hijriDate: HijriDate

    var body: some View {
        #if os(iOS)
        NavigationLink(destination: LazyDestination { CalendarView() }) {
            Group {
                // Side by side the two dates share one line, which at the accessibility sizes cut the
                // English one to "Rabiʿ II 15, 1448..." and shrank the Arabic by half. There they stack.
                if dynamicTypeSize.isAccessibilitySize {
                    HStack(alignment: .top, spacing: 12) {
                        AccentIconChip(systemImage: "calendar", size: 26)

                        VStack(alignment: .leading, spacing: 4) {
                            englishDate
                            arabicDate
                        }
                        .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                } else {
                    HStack(spacing: 12) {
                        AccentIconChip(systemImage: "calendar", size: 26)

                        englishDate

                        Spacer()

                        arabicDate
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                }
            }
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

    #if os(iOS)
    private var englishDate: some View {
        Text(hijriDate.english)
            .font(.footnote.weight(.semibold))
            .foregroundColor(.primary)
    }

    private var arabicDate: some View {
        Text(hijriDate.arabic)
            .font(.footnote)
            .foregroundColor(settings.accentColor.color)
    }
    #endif
}

private struct CurrentLocationRow: View {
    @ObservedObject private var settings = Settings.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared

    let showBigQibla: Bool
    /// The row's tap (big compass on and off), handed down so VoiceOver can reach it from the compass.
    var toggleQibla: () -> Void = {}
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
                    // The whole row toggles the big compass, which VoiceOver could not find: the
                    // compass is the control it announces.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Qibla Compass")
                    .accessibilityValue(showBigQibla ? "Expanded" : "Collapsed")
                    .accessibilityHint(showBigQibla ? "Shows the small compass" : "Shows the large compass and your coordinates")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { toggleQibla() }
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

    /// The altitude the row draws: the live fix, or in DEBUG the `-fakeAltitude <metres>` override.
    /// CoreLocation in the simulator reports no vertical accuracy, so the real reading never arrives
    /// there and the row could not otherwise be screenshotted.
    private var displayedAltitude: (metres: Double, accuracy: Double)? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-fakeAltitude"), args.indices.contains(index + 1),
           let metres = Double(args[index + 1]) {
            return (metres, 10)
        }
        #endif
        return live.currentAltitude
    }

    /// The device's actual latitude/longitude, and its elevation when the fix carries one, shown under
    /// the location (city) only while the big Qibla compass is expanded - a precise readout of "where
    /// you actually are" beneath the resolved place name.
    ///
    /// The elevation is a SECOND line rather than a third item on the first: the coordinate pair already
    /// fills the row's width at `caption2`, and appending to it pushed the whole thing into
    /// `minimumScaleFactor` territory. It appears only when CoreLocation reports a usable vertical
    /// reading (Abu, 2026-09-19) - see `LiveState.currentAltitude`.
    @ViewBuilder
    private var coordinatesLabel: some View {
        if showBigQibla,
           let loc = live.currentLocation,
           loc.latitude != 1000, loc.longitude != 1000 {
            VStack(alignment: .leading, spacing: 4) {
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

                if let altitude = displayedAltitude {
                    HStack(spacing: 6) {
                        Image(systemName: "mountain.2.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(settings.accentColor.color)

                        Text(formatElevation(metres: altitude.metres))
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
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

                if let altitude = displayedAltitude {
                    Button {
                        settings.hapticFeedback()
                        UIPasteboard.general.string = formatElevation(metres: altitude.metres)
                    } label: {
                        Label("Copy Elevation", systemImage: "mountain.2")
                    }
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

/// An altitude in metres as e.g. "1,204 ft · 367 m above sea level". Both units, feet first: the one
/// other distance this app prints (the Kaaba, in `QiblaView`) is in miles, so feet is the unit that
/// matches it, and the metric value is what CoreLocation actually measured.
///
/// Rounded to whole units - GPS altitude is good to some tens of metres at best, so decimals here
/// would be invented precision. A negative reading (below sea level, the Dead Sea and the like) is
/// printed as "below sea level" rather than with a minus sign.
private let elevationNumberFormatter: NumberFormatter = {
    let number = NumberFormatter()
    number.numberStyle = .decimal
    number.maximumFractionDigits = 0
    return number
}()

func formatElevation(metres: Double) -> String {
    let feet = metres * 3.280839895
    // One formatter (Phase 10.8): this ran per render of the expanded compass's location row, where
    // the GPS burst publishes a fix about once a second.
    let number = elevationNumberFormatter
    let feetText = number.string(from: NSNumber(value: abs(feet).rounded())) ?? "0"
    let metresText = number.string(from: NSNumber(value: abs(metres).rounded())) ?? "0"
    let suffix = metres < 0 ? "below sea level" : "above sea level"
    return "\(feetText) ft · \(metresText) m \(suffix)"
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
            // Lazy (see `PushDestination`): built eagerly, both calendars were constructed on every
            // pass of the Adhan tab and laid out at launch, though neither is on screen until a tap.
            content
                .navigationDestination(isPresented: binding(.prayerCalendar)) { LazyDestination { PrayerCalendarView() } }
                .navigationDestination(isPresented: binding(.hijriCalendar)) { LazyDestination { CalendarView() } }
        } else {
            content.background(GlanceCalendarLegacyLinks(pushed: $pushed))
        }
    }

    private func binding(_ target: GlancePush) -> Binding<Bool> {
        GlancePush.binding(target, in: $pushed)
    }
}

private extension GlancePush {
    /// True while `target` is the pushed calendar; a pop clears it, only if it is still the one shown.
    static func binding(_ target: GlancePush, in pushed: Binding<GlancePush?>) -> Binding<Bool> {
        Binding(
            get: { pushed.wrappedValue == target },
            set: { active in if !active, pushed.wrappedValue == target { pushed.wrappedValue = nil } }
        )
    }
}

/// The iOS 15 half of `GlanceCalendarPushes`: hidden `isActive` links, since a `NavigationView` ignores
/// `navigationDestination`. Its own view rather than a `ZStack` in the modifier's `else`, because a
/// several-child builder in that dead branch warned once Al-Islam's floor moved to iOS 16 (2026-10-09),
/// and marked deprecated there so the links' own iOS 16 deprecation stays inside it. Kept because
/// Al-Adhan still ships this file on iOS 15.
@available(iOS, deprecated: 16.0, message: "iOS 15 only; iOS 16 pushes through navigationDestination")
private struct GlanceCalendarLegacyLinks: View {
    @Binding var pushed: GlancePush?

    var body: some View {
        ZStack {
            NavigationLink(isActive: GlancePush.binding(.prayerCalendar, in: $pushed)) {
                PrayerCalendarView()
            } label: { EmptyView() }
            NavigationLink(isActive: GlancePush.binding(.hijriCalendar, in: $pushed)) {
                CalendarView()
            } label: { EmptyView() }
        }
        .hidden()
    }
}

private enum GlanceSheet: Identifiable {
    case cityPrayerTimes
    case homeLocation
    case qibla(bearing: String?, distance: String?)
    case weather

    var id: String {
        switch self {
        case .cityPrayerTimes: return "city"
        case .homeLocation: return "home"
        case .qibla: return "qibla"
        case .weather: return "weather"
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
            // The reading theme's ground (the system grouped color was white on Sepia).
            .accentWashedBackground()
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


