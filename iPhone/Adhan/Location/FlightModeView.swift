#if os(iOS)
import SwiftUI
import CoreLocation

// Flight Mode's screens.
//
//   FlightModeView        the page: Prayer Settings > Flight Mode, and the sheet the Adhan tab raises
//   FlightBoardSections   the flight's prayers as List sections; the page shows them, and in the
//                         air the Adhan tab shows them in place of its own sky and prayer list
//   FlightModeBanner      the Adhan tab's one row for a flight waiting for its first fix, for one
//                         still to leave, and for the landing
//   FlightSetupView       the optional part: where the flight lands, and the ticket's two times
//   AirportPickerView     the bundled airport list, searched in English and the interface's language
//
// The model is FlightMode.swift; nothing here computes a prayer time.

// MARK: - Words and numbers

enum FlightFormat {
    /// "3:42 PM", on this phone's clock or another place's.
    static func time(_ date: Date, in zone: TimeZone? = nil) -> String {
        Settings.shared.formatDate(date, in: zone).localizedDigits
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    /// "3h 12m" as the locale abbreviates it; under a minute is a minute.
    static func duration(_ interval: TimeInterval) -> String {
        (durationFormatter.string(from: max(60, interval)) ?? "").localizedDigits
    }

    static func distance(_ meters: Double) -> String {
        TravelingModeBanner.distanceText(meters).localizedDigits
    }

    private static let measure: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    private static var usesMetric: Bool {
        if #available(iOS 16, *) { return Locale.current.measurementSystem == .metric }
        return Locale.current.usesMetricSystem
    }

    /// Height the way a cabin announcement gives it: metres, or feet where feet are used, to the
    /// nearest hundred (the GPS's last digits are noise).
    static func altitude(_ meters: Double) -> String {
        let value = usesMetric
            ? Measurement(value: (meters / 100).rounded() * 100, unit: UnitLength.meters)
            : Measurement(value: (meters * 3.28084 / 100).rounded() * 100, unit: UnitLength.feet)
        return measure.string(from: value).localizedDigits
    }

    static func speed(_ metersPerSecond: Double) -> String {
        let value = usesMetric
            ? Measurement(value: (metersPerSecond * 3.6).rounded(), unit: UnitSpeed.kilometersPerHour)
            : Measurement(value: (metersPerSecond * 2.23694).rounded(), unit: UnitSpeed.milesPerHour)
        return measure.string(from: value).localizedDigits
    }

    /// Fragments of a status line with the dot between them that the language uses (the catalog's
    /// "%@ · %@", which Arabic and Urdu write with a bullet), never a dot typed here.
    static func dotted(_ parts: [String]) -> String {
        guard let first = parts.first else { return "" }
        return parts.dropFirst().reduce(first) { String(localized: "\($0) · \($1)") }
    }

    /// "Santa Ana (SNA)" for an airport, the city alone for a place that is not one.
    static func placeName(_ place: FlightPlace) -> String {
        let city = place.spokenCity.cityDisplay
        return place.isAirport ? "\(city) (\(place.code))" : city
    }

    /// "London time": a zone by its place, which is how a traveler thinks of it.
    static func zoneName(_ zone: TimeZone) -> String {
        zone.localizedName(for: .generic, locale: .current) ?? zone.identifier
    }

    /// Where the Qibla lies from a seat facing the nose. `relative` is degrees clockwise from the
    /// direction of travel, -180...180.
    static func qiblaPhrase(relative: Double) -> String {
        let side = relative >= 0
        // To the nearest five: the route's course is an estimate, and so is the nose.
        let angle = Int((abs(relative) / 5).rounded() * 5)
        switch angle {
        case ..<10:
            return String(localized: "Straight ahead, toward the nose")
        case ..<80:
            return (side ? String(localized: "\(angle)° to the right of the nose")
                         : String(localized: "\(angle)° to the left of the nose")).localizedDigits
        case ...100:
            return side ? String(localized: "To the right, toward the wing") : String(localized: "To the left, toward the wing")
        case ..<170:
            return (side ? String(localized: "Behind you on the right, \(angle)° from the nose")
                         : String(localized: "Behind you on the left, \(angle)° from the nose")).localizedDigits
        default:
            return String(localized: "Straight behind, toward the tail")
        }
    }
}

// MARK: - The page

/// Flight Mode's one page. Off: what the mode is, the one button that turns it on, the optional
/// door to the flight's details, the switch for the automatic question. On and waiting for a fix:
/// what it is waiting for. With a board: the board, and the ways to change or end it.
struct FlightModeView: View {
    private let settings = Settings.shared
    @ObservedObject private var flight = FlightMode.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// The place the flight would start from, and the city whose times stand while it waits.
    @ObservedObject private var live = LiveState.shared
    @State private var confirmsEnd = false

    var body: some View {
        List {
            Group {
                if let timeline = flight.timeline {
                    FlightBoardSections(timeline: timeline)
                    manageSection(timeline.plan)
                } else if let plan = flight.plan {
                    waitingSection(plan)
                    manageSection(plan)
                } else {
                    // The button first: turning it on takes one tap, and the reading is for
                    // whoever wants it.
                    startSection
                    detailsSection
                    introSection
                }
                detectionSection
                TravelingGuideDoors()
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(String(localized: "Flight Mode"))
        .onAppear { flight.refresh() }
        .confirmationDialog(String(localized: "End Flight Mode?"), isPresented: $confirmsEnd, titleVisibility: .visible) {
            Button(String(localized: "End Flight Mode")) {
                settings.hapticFeedback()
                withAnimation { flight.end(arrived: false) }
            }
        } message: {
            Text("Prayer times and notifications go back to the place your phone last found.")
        }
    }

    private var introSection: some View {
        Section(header: Text("PRAYER TIMES IN THE AIR")) {
            FlightIntroRow(systemImage: "airplane",
                           title: String(localized: "Each prayer at the plane's own time"),
                           text: String(localized: "A plane covers a time zone an hour, so the times for the city you left, or for the ground beneath you, are not when a prayer comes in for you. Flight Mode follows the plane and gives the time each prayer will reach it."))
            FlightIntroRow(systemImage: "sun.horizon.fill",
                           title: String(localized: "By the sun you can see"),
                           text: String(localized: "From cruising height the sun sets about a quarter of an hour later than on the ground below, and dawn comes earlier. You pray, and break a fast, by the sky outside your own window, so the times allow for the height."))
            FlightIntroRow(systemImage: "bell.fill",
                           title: String(localized: "A notification for each one"),
                           text: String(localized: "Once the plane's course is known, from GPS or from where you land, a notification is set for each prayer. They need no signal, so they arrive in airplane mode, with the phone's short tone instead of the adhan. After landing, the times are the arrival city's."))
        }
    }

    /// The one thing needed to start: a button. Nothing is typed (Abu, 2026-11-26: "do we need
    /// both airports? ... shouldn't u be able to still tell?").
    private var startSection: some View {
        Section(footer: Text(startFooter.localizedDigits)) {
            Button {
                settings.hapticFeedback()
                withAnimation { flight.turnOn() }
            } label: {
                Text("Turn On Flight Mode")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .tint(settings.accentColor.color)
        }
    }

    private var startFooter: String {
        var sentences: [String] = []
        if let place = flight.lastKnownPlace() {
            sentences.append(String(localized: "Nothing to type: the flight starts from where your phone last was, \(FlightFormat.placeName(place))."))
        } else {
            sentences.append(String(localized: "Nothing to type: the flight starts from where your phone last was."))
        }
        sentences.append(String(localized: "In the air your phone's GPS follows the plane, even in airplane mode. It reaches a phone best beside a window, with the app open."))
        return sentences.joined(separator: " ")
    }

    /// The secondary part: what makes the times surer, and is never required.
    private var detailsSection: some View {
        Section(header: Text("OPTIONAL"),
                footer: Text("With where you land, every prayer of the flight is worked out before you board and its notification is set, so the times reach you even if GPS never reaches your seat.")) {
            NavigationLink(destination: LazyDestination { FlightSetupView(existing: nil) }) {
                SettingsRowLabel(title: String(localized: "Add Your Flight"), systemImage: "airplane.arrival",
                                 subtitle: String(localized: "Where you land, and your ticket's times"),
                                 tint: SettingsTint.prayer)
            }
            .tint(settings.accentColor.color)
        }
    }

    /// On, with nothing yet to follow: what Flight Mode is waiting for and what brings it.
    private func waitingSection(_ plan: FlightPlan) -> some View {
        Section(footer: Text(waitingFooter(plan).localizedDigits)) {
            FlightWaitingCard(plan: plan, open: nil)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
    }

    private func waitingFooter(_ plan: FlightPlan) -> String {
        var sentences = [String(localized: "In the air, open the app beside a window. GPS works in airplane mode, and its first fix starts the board: each prayer's time for where the plane will be.")]
        if let here = settings.currentLocation?.displayCity, !here.isEmpty, plan.everAloft != true {
            sentences.append(String(localized: "Until then the prayer times stay those of \(here)."))
        }
        sentences.append(String(localized: "No window? Choose where you land below, and the times are worked out without GPS."))
        return sentences.joined(separator: " ")
    }

    /// A door and a button, each in its own card (Design Grammar, section 8: a card holds doors or
    /// controls, never both).
    @ViewBuilder
    private func manageSection(_ plan: FlightPlan) -> some View {
        Section(header: Text("THIS FLIGHT")) {
            NavigationLink(destination: LazyDestination { FlightSetupView(existing: plan) }) {
                SettingsRowLabel(
                    title: plan.hasDestination ? String(localized: "Change Flight") : String(localized: "Choose Where You Land"),
                    systemImage: plan.hasDestination ? "pencil" : "airplane.arrival",
                    subtitle: plan.hasDestination ? String(localized: "Airports, times, a delay")
                        : plan.isWaiting ? String(localized: "Works without GPS, for the whole flight")
                                         : String(localized: "For the rest of the flight's prayers"),
                    tint: SettingsTint.prayer)
            }
            .tint(settings.accentColor.color)
        }

        Section {
            Button {
                settings.hapticFeedback()
                confirmsEnd = true
            } label: {
                Text("End Flight Mode")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .tint(settings.accentColor.color)
        }
    }

    private var detectionSection: some View {
        Section(header: Text("AUTOMATIC")) {
            SettingsToggle(String(localized: "Ask When I Am Flying"),
                           caption: String(localized: "When your phone settles at an airport, or its GPS shows a plane's speed and height, a notification and the Adhan tab ask whether to turn Flight Mode on. Nothing changes until you answer."),
                           isOn: $adhanSettings.flightAutomatic)
        }
    }
}

/// The door to Flight Mode from a page outside the settings: the plane guide's own section on it.
struct FlightModeDoorRow: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    var body: some View {
        NavigationLink(destination: LazyDestination { FlightModeView() }) {
            SettingsRowLabel(title: SettingsAdhanPage.flightMode.title, systemImage: SettingsAdhanPage.flightMode.systemImage,
                             subtitle: SettingsAdhanPage.flightMode.caption, tint: SettingsTint.prayer)
        }
        .tint(settings.accentColor.color)
    }
}

/// One point of the introduction: a chip, what it is, and the sentences that say it.
private struct FlightIntroRow: View {
    let systemImage: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AccentIconChip(systemImage: systemImage, tint: SettingsTint.prayer)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title.localizedDigits)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                Text(text.localizedDigits)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - The board

/// A flight's prayers, as List sections: the flight itself, what comes in before takeoff, what
/// comes in on board, where the Qibla is from the seat, and the first prayers after landing.
/// Each row keeps its own clock (a `TimelineView`), so the host never re-renders to count down.
struct FlightBoardSections: View {
    let timeline: FlightTimeline
    /// On the Adhan tab the flight's card opens the Flight Mode page; on that page it is nil.
    var open: (() -> Void)? = nil

    @ObservedObject private var flight = FlightMode.shared

    private var plan: FlightPlan { timeline.plan }

    var body: some View {
        let now = Date()
        let aloft = flight.status == .inFlight

        Section {
            FlightCard(timeline: timeline, open: open)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }

        if !aloft {
            let ahead = timeline.events.filter { $0.phase == .beforeTakeoff && $0.time > now.addingTimeInterval(-30 * 60) }
            if !ahead.isEmpty {
                Section(header: Text("BEFORE TAKEOFF"), footer: originFooter) {
                    ForEach(ahead) { FlightPrayerRow(event: $0, timeline: timeline, zone: nil) }
                }
            }
        }

        Section(header: Text("ON THIS FLIGHT"), footer: Text(onBoardFooter.localizedDigits)) {
            let onBoard = timeline.inFlight
            if onBoard.isEmpty {
                Text("No prayer comes in during this flight.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(onBoard) { FlightPrayerRow(event: $0, timeline: timeline, zone: nil) }
            }
        }

        if aloft {
            Section(header: Text("QIBLA FROM YOUR SEAT"),
                    footer: Text("A phone's compass cannot be trusted inside an aircraft, so this comes from the route. Face it if you can stand and turn; if you cannot, pray as you are able.")) {
                FlightQiblaRow(timeline: timeline)
            }
        }

        if let destination = plan.destination {
            let landed = Array(timeline.events.filter { $0.phase == .afterLanding }.prefix(4))
            if !landed.isEmpty {
                Section(header: Text("AFTER YOU LAND"),
                        footer: Text("In \(destination.spokenCity.cityDisplay), on its own clock (\(FlightFormat.zoneName(destination.timeZone))).")) {
                    ForEach(landed) { FlightPrayerRow(event: $0, timeline: timeline, zone: destination.timeZone) }
                }
            }
        }
    }

    @ViewBuilder
    private var originFooter: some View {
        if let origin = plan.origin {
            Text("In \(origin.spokenCity.cityDisplay), before the plane leaves the ground.")
        }
    }

    /// Whose clock, how sure, and what a traveler prays.
    private var onBoardFooter: String {
        var sentences = [String(localized: "On your phone's clock (\(FlightFormat.zoneName(.current))).")]
        if plan.anchor == nil {
            sentences.append(String(localized: "Estimated from your flight's times: allow about 10 minutes either way, and go by the sky you can see. Maghrib has not come while the sun is in sight."))
        } else {
            sentences.append(String(localized: "Corrected by GPS. A prayer more than two hours ahead still rests on the route the plane is expected to keep."))
        }
        sentences.append(String(localized: "As a traveler, Dhuhr, Asr and Isha are 2 rakahs, and Dhuhr may be joined with Asr, Maghrib with Isha."))
        return sentences.joined(separator: " ")
    }
}

/// The flight: where from and to, how far along, when it lands, and how the times are known.
private struct FlightCard: View {
    let timeline: FlightTimeline
    let open: (() -> Void)?

    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.colorScheme) private var colorScheme

    private var plan: FlightPlan { timeline.plan }

    var body: some View {
        let fill = TravelingModeBanner.fill(for: settings.accentColor.color, dark: colorScheme == .dark)
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        TimelineView(.periodic(from: .now, by: 30)) { context in
            let now = context.date
            let aloft = now >= timeline.takeoff
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: aloft ? "airplane" : "airplane.departure")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.22)))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        routeTitle
                            .font(.headline.weight(.bold))
                        Text(routeCaption)
                            .font(.caption)
                            .opacity(0.9)
                    }

                    Spacer(minLength: 8)

                    if open != nil {
                        Image(systemName: "chevron.forward")
                            .font(.footnote.weight(.semibold))
                            .opacity(0.8)
                            .accessibilityHidden(true)
                    }
                }

                if aloft, plan.hasDestination {
                    FlightProgressBar(fraction: fraction(at: now))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(statusLine(at: now).localizedDigits)
                        .font(.subheadline.weight(.semibold))
                    if let next = nextLine(at: now) {
                        Text(next.localizedDigits)
                            .font(.subheadline.weight(.semibold))
                    }
                    Text(detailLine(at: now).localizedDigits)
                        .font(.caption)
                        .opacity(0.9)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(fill))
            .contentShape(shape)
            .onTapGesture {
                guard let open else { return }
                settings.hapticFeedback()
                open()
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(open == nil ? [] : .isButton)
        }
    }

    /// "JFK → LHR", the arrow pointing the way the row reads.
    @ViewBuilder
    private var routeTitle: some View {
        if let destination = plan.destination {
            HStack(spacing: 6) {
                if let origin = plan.origin {
                    // An origin that is not an airport (where the phone last was) goes by its name.
                    Text(verbatim: origin.isAirport ? origin.code : origin.spokenCity.cityDisplay)
                    Image(systemName: "arrow.forward")
                        .font(.subheadline.weight(.bold))
                        .accessibilityHidden(true)
                }
                Text(verbatim: plan.origin == nil ? destination.spokenCity.cityDisplay : destination.code)
            }
        } else {
            Text("Flight Mode")
        }
    }

    private var routeCaption: String {
        switch (plan.origin, plan.destination) {
        case let (origin?, destination?):
            return String(localized: "\(origin.spokenCity.cityDisplay) to \(destination.spokenCity.cityDisplay)")
        case let (nil, destination?):
            return String(localized: "Flying to \(destination.name)")
        case let (origin?, nil):
            return String(localized: "From \(origin.spokenCity.cityDisplay), following the course the plane is flying")
        default:
            return String(localized: "Following the course the plane is flying")
        }
    }

    private func fraction(at now: Date) -> Double {
        let progress = plan.path.progress(at: now)
        return progress.total > 0 ? min(1, max(0, progress.covered / progress.total)) : 0
    }

    private func statusLine(at now: Date) -> String {
        if now < timeline.takeoff {
            return String(localized: "Takes off in \(FlightFormat.duration(timeline.takeoff.timeIntervalSince(now)))")
        }
        guard plan.hasDestination else { return String(localized: "In the air") }
        if now >= timeline.landing { return String(localized: "Landing") }
        return String(localized: "In the air · lands in \(FlightFormat.duration(timeline.landing.timeIntervalSince(now)))")
    }

    /// "Next: Fajr in 2h 37m": the one thing the card is opened for, wherever on the journey it falls.
    private func nextLine(at now: Date) -> String? {
        guard let next = timeline.next(after: now) else { return nil }
        let name = Settings.shared.flightPrayer(for: next).displayName
        return String(localized: "Next: \(name) in \(FlightFormat.duration(next.time.timeIntervalSince(now)))")
    }

    /// How the times are known, and what the GPS said.
    private func detailLine(at now: Date) -> String {
        guard let anchor = plan.anchor else {
            return now < timeline.takeoff
                ? String(localized: "Flight Mode starts by itself at takeoff")
                : String(localized: "Estimated from your flight's times · no GPS fix yet")
        }
        var parts = [String(localized: "GPS \(FlightFormat.duration(now.timeIntervalSince(anchor.time))) ago")]
        parts.append(FlightFormat.speed(anchor.speed))
        if let altitude = anchor.altitude { parts.append(FlightFormat.altitude(altitude)) }
        if !plan.hasDestination { parts.append(String(localized: "add where you land")) }
        return FlightFormat.dotted(parts)
    }
}

/// A track with the plane on it. Drawn left to right in every language: it is a route, and its
/// card names the origin first on whichever side the language starts from, so the bar mirrors.
private struct FlightProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.25)).frame(height: 4)
                Capsule().fill(Color.white).frame(width: max(4, width * fraction), height: 4)
                Image(systemName: "airplane")
                    .font(.system(size: 13, weight: .bold))
                    .flipsForRightToLeftLayoutDirection(true)
                    .offset(x: min(max(0, width * fraction - 8), width - 16))
            }
            .frame(height: 16)
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }
}

/// One prayer of the journey: its symbol and name, its time, and how long until it (or that it has
/// come). Aboard, a second line says whether its time outlasts the flight.
private struct FlightPrayerRow: View {
    let event: FlightPrayerEvent
    let timeline: FlightTimeline
    /// The clock the time is printed on: nil is the phone's.
    let zone: TimeZone?

    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    var body: some View {
        let prayer = settings.flightPrayer(for: event)
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let now = context.date
            let isCurrent = timeline.current(at: now)?.id == event.id
            let isPast = event.time <= now && !isCurrent
            HStack(alignment: .center, spacing: 12) {
                AccentIconChip(systemImage: prayer.image,
                               tint: isCurrent ? settings.accentColor.color : SettingsTint.prayer)
                    .opacity(isPast ? 0.5 : 1)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(prayer.displayName)
                        .font(.body.weight(isCurrent ? .bold : .semibold))
                        .foregroundColor(isPast ? .secondary : .primary)
                    if let note = note(at: now) {
                        Text(note.localizedDigits)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(FlightFormat.time(event.time, in: zone))
                        .font(.body.weight(.semibold).monospacedDigit())
                        .foregroundColor(isPast ? .secondary : .primary)
                    Text(relative(at: now, isCurrent: isCurrent))
                        .font(.caption)
                        .foregroundColor(isCurrent ? settings.accentColor.color : .secondary)
                }
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
        }
    }

    private func relative(at now: Date, isCurrent: Bool) -> String {
        if isCurrent { return String(localized: "Now") }
        if event.time > now { return String(localized: "in \(FlightFormat.duration(event.time.timeIntervalSince(now)))") }
        return String(localized: "\(FlightFormat.duration(now.timeIntervalSince(event.time))) ago")
    }

    /// The second line: what a traveler needs to decide where to pray this one.
    private func note(at now: Date) -> String? {
        if event.kind == .sunrise { return String(localized: "Fajr's time ends") }
        if event.kind == .maghrib, let until = event.sunReturnsUntil, event.phase == .beforeTakeoff {
            return String(localized: "The sun comes back into view as the plane climbs, until \(FlightFormat.time(until)). Maghrib has already come in.")
        }
        guard event.phase == .inFlight else { return nil }
        if event.fromNightPortion {
            return String(localized: "Set from the length of the night: the sky does not get dark enough on this route")
        }
        // Where to pray it, in the order the guide gives (How to Pray on a Plane): on the ground
        // before boarding, on the ground after landing, and on board only when the time would
        // otherwise run out.
        func name(_ kind: FlightPrayerKind) -> String { kind.name.localizedDisplay }
        switch timeline.advice(for: event) {
        case let .joinBeforeBoarding(with: partner, end?):
            return String(localized: "May be joined with \(name(partner)) on the ground before you board. Otherwise pray it on board: its time ends in the air, at \(FlightFormat.time(end)).")
        case let .joinBeforeBoarding(with: partner, nil):
            return String(localized: "May be joined with \(name(partner)) on the ground before you board")
        case .waitsForLanding:
            return String(localized: "Its time lasts until after you land")
        case let .joinAfterLanding(with: follower):
            return String(localized: "May wait for the ground, joined with \(name(follower)) after you land")
        case let .onBoard(end):
            return String(localized: "Its time ends in the air, at \(FlightFormat.time(end)): pray it on board")
        case nil:
            return nil
        }
    }
}

/// Where the Qibla is from a seat: a plane seen from above, nose up, with the Qibla on its rim.
private struct FlightQiblaRow: View {
    let timeline: FlightTimeline

    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            if let reading = reading(at: context.date) {
                HStack(spacing: 14) {
                    dial(relative: reading.relative)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(FlightFormat.qiblaPhrase(relative: reading.relative))
                            .font(.body.weight(.semibold))
                        Text(String(localized: "Qibla \(Int(reading.qibla.rounded()))°, the plane is flying \(Int(reading.course.rounded()))°").localizedDigits)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            } else {
                Text("The Qibla from your seat shows once the plane is in the air.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func reading(at now: Date) -> (relative: Double, qibla: Double, course: Double)? {
        guard let state = timeline.plan.path.state(at: now), state.phase == .inFlight else { return nil }
        // A fix from the last few minutes knows the course actually flown; otherwise the route's.
        var course = state.course ?? 0
        if let anchor = timeline.plan.anchor, let measured = anchor.course, now.timeIntervalSince(anchor.time) < 180 {
            course = measured
        }
        let qibla = FlightGeometry.bearing(from: state.coordinate, to: FlightGeometry.kaaba)
        var relative = (qibla - course).truncatingRemainder(dividingBy: 360)
        if relative > 180 { relative -= 360 }
        if relative < -180 { relative += 360 }
        return (relative, qibla, course)
    }

    /// Left to right whatever the language: a right-to-left layout mirrors rotations, and the
    /// Qibla would point to the wrong wing (the compass's own rule, `QiblaView`).
    private func dial(relative: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.35), lineWidth: 1.5)
            Image(systemName: "airplane")
                .font(.system(size: 22, weight: .semibold))
                .rotationEffect(.degrees(-90))
                .foregroundColor(.secondary)
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(settings.accentColor.color)
                .offset(y: -31)
                .rotationEffect(.degrees(relative))
        }
        .frame(width: 72, height: 72)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }
}

// MARK: - Waiting for the first fix

/// Flight Mode on with nothing typed, before a fix has found the plane: where it starts from and
/// what it is waiting for. The page shows it in place of the board.
struct FlightWaitingCard: View {
    let plan: FlightPlan
    let open: (() -> Void)?

    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.colorScheme) private var colorScheme

    /// One line of state, shared with the Adhan tab's banner.
    static func status(for plan: FlightPlan) -> String {
        plan.everAloft == true
            ? String(localized: "Looking for GPS: hold your phone beside a window")
            : String(localized: "Waiting for takeoff: open the app in the air, beside a window")
    }

    var body: some View {
        let fill = TravelingModeBanner.fill(for: settings.accentColor.color, dark: colorScheme == .dark)
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.22)))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Flight Mode is on")
                        .font(.headline.weight(.bold))
                    if let origin = plan.origin {
                        Text("From \(FlightFormat.placeName(origin))")
                            .font(.caption)
                            .opacity(0.9)
                    }
                }
            }

            Text(Self.status(for: plan).localizedDigits)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(fill))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - The Adhan tab's row

/// The Adhan tab's one row for Flight Mode outside the flight itself: a flight set up and still to
/// leave (opens the page), and the landing (a tap puts it away). In the air the tab shows the whole
/// board instead (`FlightBoardSections`).
struct FlightModeBanner: View {
    enum Kind: Equatable {
        /// On, with nothing yet to follow (`FlightPlan.isWaiting`).
        case waiting(FlightPlan)
        case upcoming(FlightTimeline)
        case arrived(FlightMode.Arrival)
    }

    let kind: Kind
    let action: () -> Void

    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let fill = TravelingModeBanner.fill(for: settings.accentColor.color, dark: colorScheme == .dark)
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        Button {
            settings.hapticFeedback()
            action()
        } label: {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                HStack(spacing: 12) {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.22)))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.weight(.bold))
                        Text(detail(at: context.date).localizedDigits)
                            .font(.caption)
                            .opacity(0.9)
                    }
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    Image(systemName: trailingSymbol)
                        .font(.footnote.weight(.semibold))
                        .opacity(0.8)
                        .accessibilityHidden(true)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(shape.fill(fill))
                .contentShape(shape)
            }
        }
        .buttonStyle(.plain)
    }

    private var symbol: String {
        if case .arrived = kind { return "airplane.arrival" }
        return "airplane.departure"
    }

    private var trailingSymbol: String {
        if case .arrived = kind { return "xmark" }
        return "chevron.forward"
    }

    private var title: String {
        switch kind {
        case .waiting:
            return String(localized: "Flight Mode is on")
        case let .upcoming(timeline):
            if let city = timeline.plan.destination?.spokenCity.cityDisplay {
                return String(localized: "Flight Mode · to \(city)")
            }
            return String(localized: "Flight Mode")
        case .arrived:
            return String(localized: "Flight Mode has ended")
        }
    }

    private func detail(at now: Date) -> String {
        switch kind {
        case let .waiting(plan):
            return FlightWaitingCard.status(for: plan)
        case let .upcoming(timeline):
            let leaves = String(localized: "Takes off in \(FlightFormat.duration(timeline.takeoff.timeIntervalSince(now)))")
            let count = timeline.inFlight.filter { $0.kind != .sunrise }.count
            let onBoard = count == 0 ? String(localized: "no prayer comes in on board")
                                     : String(localized: "prayers on board: \(count)")
            return FlightFormat.dotted([leaves, onBoard])
        case let .arrived(arrival):
            // Only when the destination was taken on trust: with a fix, the phone's own place rules.
            if arrival.adopted, let city = arrival.place?.spokenCity.cityDisplay {
                return String(localized: "Prayer times are for \(city) now, until your phone finds where you are")
            }
            return String(localized: "Prayer times follow your phone's location again")
        }
    }
}

// MARK: - Setting up a flight

/// The optional form: where the flight lands, and the two times printed on the ticket, each on its
/// own airport's clock. Where it leaves from is filled in from where the phone last was. For a
/// flight already being followed in the air, only where it lands.
struct FlightSetupView: View {
    /// The flight being changed; nil for a new one.
    let existing: FlightPlan?

    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var live = LiveState.shared
    @Environment(\.dismiss) private var dismiss

    @State private var origin: FlightPlace?
    @State private var destination: FlightPlace?
    @State private var departure: Date
    @State private var arrival: Date
    /// Once the traveler has set the arrival, the estimate stops overwriting it.
    @State private var arrivalIsTheirs: Bool

    init(existing: FlightPlan?) {
        self.existing = existing
        // A flight turned on with nothing typed left about when it was turned on; a new one is
        // most likely the next departure on the board.
        let start: Date
        if let existing, existing.isWaiting {
            start = Self.fiveMinutes(before: existing.waitingSince ?? existing.departure)
        } else {
            start = existing?.departure ?? Self.nextQuarterHour()
        }
        _origin = State(initialValue: existing?.origin)
        _destination = State(initialValue: existing?.destination)
        _departure = State(initialValue: start)
        _arrival = State(initialValue: existing?.arrival ?? start.addingTimeInterval(3 * 60 * 60))
        _arrivalIsTheirs = State(initialValue: existing?.arrival != nil)
    }

    /// A flight being followed in the air from a fix: there is no gate time to type, only where it lands.
    private var isAloft: Bool { existing?.detected == true && existing?.anchor != nil }

    var body: some View {
        List {
            Group {
                if !isAloft {
                    Section(header: Text("FROM")) {
                        airportLink(title: String(localized: "Departure Airport"), place: origin, picks: $origin, nearby: true)
                        if let origin {
                            DatePicker(selection: $departure, displayedComponents: [.date, .hourAndMinute]) {
                                FlightFormLabel(title: String(localized: "Departs"),
                                                caption: FlightFormat.zoneName(origin.timeZone))
                            }
                            .environment(\.timeZone, origin.timeZone)
                            .tint(settings.accentColor.color)
                        }
                    }
                }

                Section(header: Text("TO"), footer: Text(arrivalFooter.localizedDigits)) {
                    airportLink(title: String(localized: "Arrival Airport"), place: destination, picks: $destination, nearby: false)
                    if let destination {
                        DatePicker(selection: arrivalBinding, displayedComponents: [.date, .hourAndMinute]) {
                            FlightFormLabel(title: String(localized: "Arrives"),
                                            caption: FlightFormat.zoneName(destination.timeZone))
                        }
                        .environment(\.timeZone, destination.timeZone)
                        .tint(settings.accentColor.color)
                    }
                }

                Section(footer: Text(problem ?? "").foregroundColor(.red)) {
                    Button {
                        settings.hapticFeedback()
                        save()
                    } label: {
                        Text(existing == nil ? String(localized: "Start Flight Mode") : String(localized: "Save"))
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                    }
                    .tint(settings.accentColor.color)
                    .disabled(!canSave)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(pageTitle)
        .onAppear(perform: offerOrigin)
        .onChange(of: origin) { _ in estimateArrival() }
        .onChange(of: destination) { _ in estimateArrival() }
        .onChange(of: departure) { _ in estimateArrival() }
    }

    /// The page under the name of the door that opened it.
    private var pageTitle: String {
        guard let existing else { return String(localized: "Add Your Flight") }
        return existing.hasDestination ? String(localized: "Change Flight") : String(localized: "Choose Where You Land")
    }

    private func airportLink(title: String, place: FlightPlace?, picks: Binding<FlightPlace?>, nearby: Bool) -> some View {
        NavigationLink(destination: LazyDestination { AirportPickerView(title: title, showsNearby: nearby, selection: picks) }) {
            HStack(spacing: 10) {
                Text(title)
                    .foregroundColor(.primary)
                Spacer(minLength: 8)
                if let place {
                    Text(verbatim: FlightFormat.placeName(place))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Choose")
                        .foregroundColor(settings.accentColor.color)
                }
            }
        }
    }

    private var arrivalBinding: Binding<Date> {
        Binding(get: { arrival }, set: {
            arrival = $0
            arrivalIsTheirs = true
        })
    }

    // MARK: Values

    private static func nextQuarterHour() -> Date {
        let quarter: TimeInterval = 15 * 60
        return Date(timeIntervalSinceReferenceDate: (Date().timeIntervalSinceReferenceDate / quarter).rounded(.up) * quarter)
    }

    private static func fiveMinutes(before date: Date) -> Date {
        let step: TimeInterval = 5 * 60
        return Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / step).rounded(.down) * step)
    }

    /// From where this flight is measured: the origin, or for a flight in the air the last fix.
    private var startPoint: FlightCoordinate? {
        isAloft ? existing?.anchor?.coordinate : origin?.coordinate
    }

    private var distance: Double? {
        guard let startPoint, let destination else { return nil }
        return FlightGeometry.distance(from: startPoint, to: destination.coordinate)
    }

    /// Gate to gate for a new flight: the distance at an airliner's cruise, plus the taxi and the
    /// slower climb and descent. In the air: what is left, at the speed the GPS gave.
    private var estimatedArrival: Date? {
        guard let distance else { return nil }
        if isAloft, let anchor = existing?.anchor {
            return anchor.time.addingTimeInterval(distance / max(anchor.speed, 180) + 8 * 60 + FlightPlan.taxiIn)
        }
        return departure.addingTimeInterval(distance / 230 + 35 * 60)
    }

    private func estimateArrival() {
        guard !arrivalIsTheirs, let estimatedArrival else { return }
        arrival = estimatedArrival
    }

    /// Where the flight leaves from, filled in once from where the phone last was: its airport,
    /// or the place itself where no airport is near (Abu, 2026-11-26: "base it off last known
    /// location for starting airport"). It can still be changed.
    private func offerOrigin() {
        guard !isAloft, origin == nil else { return }
        origin = FlightMode.shared.lastKnownPlace()
    }

    private var arrivalFooter: String {
        guard destination != nil, let distance else {
            return String(localized: "Each time is on its own airport's clock, as your ticket prints it.")
        }
        var sentences: [String] = []
        if isAloft {
            sentences.append(String(localized: "\(FlightFormat.distance(distance)) to go."))
        } else {
            sentences.append(String(localized: "\(FlightFormat.distance(distance)), \(FlightFormat.duration(arrival.timeIntervalSince(departure))) gate to gate."))
        }
        if !arrivalIsTheirs {
            sentences.append(String(localized: "The arrival is an estimate from the distance: set it to your ticket's."))
        }
        return sentences.joined(separator: " ")
    }

    /// What stops the flight from being saved, in words; nil when it can be.
    private var problem: String? {
        guard let destination else { return nil }
        if !isAloft {
            guard let origin else { return nil }
            if origin.isAirport, origin.code == destination.code {
                return String(localized: "The two airports are the same.")
            }
            let hours = arrival.timeIntervalSince(departure) / 3600
            if hours <= 0 {
                return String(localized: "The arrival is before the departure. Each time is on its own airport's clock.")
            }
            // Slower than a light aircraft or faster than an airliner: one of the two times is wrong.
            if let distance {
                let airborne = max(arrival.timeIntervalSince(departure) - FlightPlan.taxiOut - FlightPlan.taxiIn, 60)
                let speed = distance / airborne
                if speed > 330 {
                    return String(localized: "That is too fast for \(FlightFormat.distance(distance)). Check the two times: each is on its own airport's clock.")
                }
                if speed < 45, distance > 150_000 {
                    return String(localized: "That is too slow for \(FlightFormat.distance(distance)). Check the two times: each is on its own airport's clock.")
                }
            }
        } else if arrival <= Date() {
            return String(localized: "The arrival has already passed.")
        }
        return nil
    }

    private var canSave: Bool {
        guard destination != nil, problem == nil else { return false }
        return isAloft || origin != nil
    }

    private func save() {
        guard canSave, let destination else { return }
        var plan = existing ?? FlightPlan(origin: origin, destination: destination, departure: departure,
                                          arrival: arrival, anchor: nil, holdUntil: nil, detected: false)
        plan.destination = destination
        plan.arrival = arrival
        if !isAloft {
            // From here on the flight runs to a timetable (a gate time, a taxi, a route), whether
            // it was first turned on with nothing typed or not.
            plan.detected = false
            plan.waitingSince = nil
            plan.origin = origin
            // A new departure is a new timetable: an old hold at the gate belonged to the old one.
            if plan.departure != departure { plan.holdUntil = nil }
            plan.departure = departure
        }
        withAnimation { FlightMode.shared.begin(plan) }
        dismiss()
    }
}

/// A form row's label: what the row is, and under it the clock it is on.
private struct FlightFormLabel: View {
    let title: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(caption)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// The airport list, searched by city, name or code. Before anything is typed, the departure's
/// picker lists the airports around the phone, which is where most flights start; the arrival's
/// lists nothing (nobody flies to where they are).
struct AirportPickerView: View {
    let title: String
    var showsNearby = true
    @Binding var selection: FlightPlace?

    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var live = LiveState.shared
    @Environment(\.dismiss) private var dismiss
    /// DEBUG launch argument `-airportQuery <text>`: the search as typed, for a simulator whose
    /// keyboard is in another script.
    @State private var query: String = {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-airportQuery"), arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }
        #endif
        return ""
    }()

    var body: some View {
        let typed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let results = typed.isEmpty ? (showsNearby ? nearby : []) : Airports.search(typed)
        List {
            Group {
                if results.isEmpty {
                    Section {
                        // Names are matched in the interface's language and in English; the code is
                        // the same in every script.
                        Text(typed.isEmpty ? String(localized: "Type a city, an airport or its three-letter code.")
                                           : String(localized: "No airport matches. Try the three-letter code on your ticket, or the name of the country."))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section(header: Text(typed.isEmpty ? String(localized: "NEAR YOU") : String(localized: "AIRPORTS"))) {
                        ForEach(results) { airport in
                            Button {
                                settings.hapticFeedback()
                                selection = airport.place
                                dismiss()
                            } label: {
                                AirportRow(airport: airport, isChosen: selection?.code == airport.code)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(title)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text("City, airport or code"))
        .autocorrectionDisabled()
    }

    private var nearby: [Airport] {
        guard let here = live.currentLocation, here.latitude != 1000, here.longitude != 1000 else { return [] }
        return Airports.near(FlightCoordinate(latitude: here.latitude, longitude: here.longitude),
                             within: 250_000, limit: 8)
    }
}

private struct AirportRow: View {
    let airport: Airport
    let isChosen: Bool

    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // The accent darkened until white reads on it, as on the flight's card.
            Text(verbatim: airport.code)
                .font(.subheadline.weight(.bold).monospaced())
                .foregroundColor(.white)
                .frame(width: 50, height: 30)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(TravelingModeBanner.fill(for: settings.accentColor.color, dark: colorScheme == .dark)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: airport.displayName)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(verbatim: airport.cityAndCountry)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isChosen {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(airport.displayName), \(airport.cityAndCountry), \(airport.code)")
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}
#endif
