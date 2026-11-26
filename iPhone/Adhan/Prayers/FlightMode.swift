#if os(iOS)
import Foundation
import CoreLocation
import Combine

// Flight Mode, part 4 of 4: the mode itself.
//
// One flight at a time (`plan`), typed in before boarding or noticed in the air, and the prayers
// along it (`timeline`). Everything else reads these two:
//
//   the Adhan tab        swaps its sky and prayer list for the flight's board while in the air
//   the scheduler        announces the flight's prayers, drops the ground list's times that fall
//                        inside the flight, and uses the destination's list after landing
//                        (`Settings.schedulePrayerTimeNotifications`)
//   the foreground adhan stays quiet for a ground time the flight replaces
//
// How a flight starts (Abu, 2026-11-26: "do we need both airports? ... shouldn't u be able to
// still tell? ... you could also base it off last known location for starting airport"):
//   one tap   Flight Mode > Turn On Flight Mode, with nothing typed. The flight starts from where
//             the phone last was and waits (`Status.waiting`) for a fix in the air; from then on it
//             follows the course being flown.
//   by GPS    a fix shows airliner speed and height (`note(fix:)`), and the Adhan tab asks, with a
//             notification behind it (Abu, 2026-11-25: "be able to tell automatically and ask").
//   at the    the phone settles at an airport (`noteArrival`), and the same card asks before the
//   airport   flight, while there is still a signal to ask with.
//   in full   Add Your Flight: where it lands, and the ticket's two times if wanted. That is what
//             lets the times be worked out for the whole flight before boarding, so they arrive
//             even where GPS never reaches the seat.
// How it ends: a fix on the ground away from the origin, the landing time passing, or by hand.
//
// A GPS fix in the air is the best evidence there is, so each one re-anchors the route (window
// seats get them even in airplane mode; aisle seats mostly do not, and the timetable carries on).

/// A flight and the prayers along it, worked out once and read many times.
struct FlightTimeline: Equatable {
    let plan: FlightPlan
    let takeoff: Date
    let landing: Date
    /// Every prayer from the evening before the flight to the day after it, in order: on the ground
    /// at the origin, in the air, on the ground at the destination.
    let events: [FlightPrayerEvent]
    /// The calculation settings these were worked out with (`Settings.flightPrayerRules`).
    let rulesSignature: String

    var inFlight: [FlightPrayerEvent] { events.filter { $0.phase == .inFlight } }

    /// The last prayer to have come in by `now`, and the next one, across the whole journey.
    func current(at now: Date) -> FlightPrayerEvent? { events.last { $0.time <= now } }
    func next(after now: Date) -> FlightPrayerEvent? { events.first { $0.time > now } }

    /// How close to takeoff or landing the ground list and the flight can both claim one prayer.
    private static let seam: TimeInterval = 45 * 60

    /// Whether a prayer from the list of the place being LEFT still stands. Well before takeoff it
    /// does; inside the flight it does not (the flight's own time replaces it); after landing it
    /// does not either once a destination is known (that place's list takes over). At the seam the
    /// solver decides which side the prayer's sign fell on, so a Maghrib two minutes either side of
    /// wheels-up is announced exactly once.
    func keepsOriginPrayer(named name: String, at time: Date) -> Bool {
        if time < takeoff.addingTimeInterval(-Self.seam) { return true }
        if time > landing { return !plan.hasDestination }
        if time > takeoff.addingTimeInterval(Self.seam) { return false }
        if let match = nearestEvent(toGroundPrayer: name, at: time) { return match.phase == .beforeTakeoff }
        return time < takeoff
    }

    /// The same for a prayer from the destination's list: it stands once the aircraft is down.
    func keepsDestinationPrayer(named name: String, at time: Date) -> Bool {
        guard plan.hasDestination else { return false }
        if time > landing.addingTimeInterval(Self.seam) { return true }
        if time < landing.addingTimeInterval(-Self.seam) { return false }
        if let match = nearestEvent(toGroundPrayer: name, at: time) { return match.phase == .afterLanding }
        return time > landing
    }

    private func nearestEvent(toGroundPrayer name: String, at time: Date) -> FlightPrayerEvent? {
        events
            .filter { $0.kind.matches(groundName: name) && abs($0.time.timeIntervalSince(time)) < Self.seam }
            .min { abs($0.time.timeIntervalSince(time)) < abs($1.time.timeIntervalSince(time)) }
    }

    /// When an in-flight prayer's time runs out for a traveler, who may join Dhuhr with Asr and
    /// Maghrib with Isha: Fajr at sunrise; Dhuhr and Asr at sunset; Maghrib and Isha at the middle
    /// of the night (from that sunset to the next dawn). Nil for sunrise, and when the board does
    /// not reach far enough to say.
    func windowEnd(for event: FlightPrayerEvent) -> Date? {
        func next(_ kind: FlightPrayerKind) -> Date? {
            events.first { $0.kind == kind && $0.time > event.time }?.time
        }
        switch event.kind {
        case .sunrise: return nil
        case .fajr: return next(.sunrise)
        case .dhuhr, .asr: return next(.maghrib)
        case .maghrib, .isha:
            let sunset = event.kind == .maghrib
                ? event.time
                : events.last { $0.kind == .maghrib && $0.time <= event.time }?.time
            guard let sunset, let dawn = next(.fajr) else { return nil }
            return sunset.addingTimeInterval(dawn.timeIntervalSince(sunset) / 2)
        }
    }

    /// Whether that time is still running half an hour after wheels-down, so the prayer can wait
    /// for the ground (standing, facing the Qibla) if it cannot be prayed properly aboard. Nil
    /// when there is no landing to wait for, or no end to compare.
    func canWaitForLanding(_ event: FlightPrayerEvent) -> Bool? {
        guard plan.hasDestination, event.phase == .inFlight, let end = windowEnd(for: event) else { return nil }
        return end > landing.addingTimeInterval(30 * 60)
    }

    /// Whether an event's time rests on a recent fix (within two hours of it) or on the timetable.
    func isEstimate(_ event: FlightPrayerEvent) -> Bool {
        guard event.phase == .inFlight else { return false }
        guard let anchor = plan.anchor else { return true }
        return event.instant.timeIntervalSince(anchor.time) > 2 * 60 * 60 || event.instant < anchor.time
    }

    // MARK: Where to pray it (How to Pray on a Plane, "PLAN BEFORE YOU FLY" and "COMMON QUESTIONS")

    /// What the guide's plan says of a prayer that comes in on board. In its order of preference:
    /// on the ground before boarding, joined to the prayer already in; on the ground after landing,
    /// if its time (or its pair's) lasts that long; otherwise on board, before the time ends.
    enum Advice: Equatable {
        /// Asr with a Dhuhr that came in before takeoff, Isha with such a Maghrib: the pair may be
        /// prayed together on the ground before boarding. `end` is when its time ends if it is not.
        case joinBeforeBoarding(with: FlightPrayerKind, end: Date?)
        /// Its own time is still running half an hour after landing.
        case waitsForLanding
        /// Its own time ends in the air, but joined to the next of its pair it lasts until after landing.
        case joinAfterLanding(with: FlightPrayerKind)
        /// The time ends in the air (or too soon after landing): prayed on board.
        case onBoard(end: Date)
    }

    /// Half an hour on the ground at either end is the least in which a prayer can be found a place.
    private static let groundMargin: TimeInterval = 30 * 60

    func advice(for event: FlightPrayerEvent) -> Advice? {
        guard event.phase == .inFlight, event.kind != .sunrise, plan.hasDestination else { return nil }
        let end = windowEnd(for: event)

        // The second of a pair, whose first came in on the ground with time to pray before boarding.
        let partner: FlightPrayerKind? = event.kind == .asr ? .dhuhr : event.kind == .isha ? .maghrib : nil
        if let partner,
           let first = events.last(where: { $0.kind == partner && $0.time < event.time }),
           first.phase == .beforeTakeoff,
           first.time <= takeoff.addingTimeInterval(-(FlightPlan.taxiOut + Self.groundMargin)) {
            // Only worth saying when the alternative is praying it in a seat.
            if let end, end > landing.addingTimeInterval(Self.groundMargin) { return .waitsForLanding }
            return .joinBeforeBoarding(with: partner, end: end)
        }

        // No landing to wait for (the course is being followed): nothing can be said of where
        // its time ends.
        guard plan.hasDestination, let end else { return nil }
        let ground = landing.addingTimeInterval(Self.groundMargin)
        // The first of a pair has a time of its own (until the second comes in) and a joined one.
        let follower: FlightPrayerKind? = event.kind == .dhuhr ? .asr : event.kind == .maghrib ? .isha : nil
        if let follower {
            let ownEnd = events.first { $0.kind == follower && $0.time > event.time }?.time ?? end
            if min(ownEnd, end) > ground { return .waitsForLanding }
            return end > ground ? .joinAfterLanding(with: follower) : .onBoard(end: end)
        }
        return end > ground ? .waitsForLanding : .onBoard(end: end)
    }

    // MARK: Building

    /// The journey's prayers for a plan, or nil while the plan cannot be followed (`isWaiting`).
    /// One function for the app and for the widget extension, which reads the same stored plan
    /// (`FlightWidgetFeed`), so the two can never show different times.
    static func build(plan: FlightPlan, settings: Settings) -> FlightTimeline? {
        let path = plan.path
        guard path.isUsable else { return nil }
        let rules = settings.flightPrayerRules(on: plan.takeoff)
        // The evening before and the day after: the night either side of the flight is measured
        // whole, and the first prayers at the destination are on the board before landing.
        let start = plan.origin == nil ? path.takeoff : path.takeoff.addingTimeInterval(-18 * 60 * 60)
        let end = plan.destination == nil ? path.landing : path.landing.addingTimeInterval(18 * 60 * 60)
        let events = FlightPrayerSolver.events(along: path, rules: rules.rules, from: start, to: end)
        return FlightTimeline(
            plan: plan, takeoff: path.takeoff, landing: path.landing,
            events: matchedToGroundTables(events, plan: plan, settings: settings),
            rulesSignature: rules.signature)
    }

    /// The journey's prayers on the ground, set to the minute the app's own table gives for that
    /// city, so the board's "before takeoff" and "after you land" read exactly as the Adhan tab
    /// will there. The solver and the ground engine reach the same sun by different roads and
    /// agree within seconds (`FlightPrayerTests`), which can still fall either side of a minute;
    /// and where the high-latitude rule sets Fajr from the night's length, the engine measures the
    /// night after it and the solver the night it is in. One place, one time.
    private static func matchedToGroundTables(_ events: [FlightPrayerEvent], plan: FlightPlan,
                                              settings: Settings) -> [FlightPrayerEvent] {
        func table(for place: FlightPlace?, around time: Date) -> [Prayer] {
            guard let place else { return [] }
            let location = Location(city: place.spokenCity, latitude: place.latitude, longitude: place.longitude)
            return [-1, 0, 1].flatMap { offset -> [Prayer] in
                guard let day = Calendar.current.date(byAdding: .day, value: offset, to: time) else { return [] }
                return settings.getPrayerTimes(for: day, at: location, fullPrayers: true) ?? []
            }
        }
        return events.map { event in
            let place: FlightPlace?
            switch event.phase {
            case .beforeTakeoff: place = plan.origin
            case .afterLanding: place = plan.destination
            case .inFlight: return event
            }
            let own = table(for: place, around: event.time)
                .filter { event.kind.matches(groundName: $0.nameTransliteration)
                          && abs($0.time.timeIntervalSince(event.time)) < 20 * 60 }
                .min { abs($0.time.timeIntervalSince(event.time)) < abs($1.time.timeIntervalSince(event.time)) }
            guard let own else { return event }
            var matched = event
            matched.time = own.time
            return matched
        }
    }

    // MARK: The day, for a surface that shows one (the widgets)

    /// The day as the traveler lives it around `moment`: from its Fajr to the Isha that follows,
    /// each prayer once. A flight has no calendar day of its own (eastbound, two dawns can fall
    /// inside one date on the phone's clock), so the day is counted the way it is prayed. Past the
    /// middle of the night it is the coming day, as a timetable turns over after midnight.
    func day(around moment: Date) -> [FlightPrayerEvent] {
        guard !events.isEmpty else { return [] }
        var start = events.lastIndex { $0.kind == .fajr && $0.time <= moment } ?? 0
        if let nextFajr = events.indices.first(where: { $0 > start && events[$0].kind == .fajr }) {
            let last = events[nextFajr - 1].time
            if moment > last.addingTimeInterval(events[nextFajr].time.timeIntervalSince(last) / 2) { start = nextFajr }
        }
        var day: [FlightPrayerEvent] = []
        for event in events[start...] {
            if event.kind == .fajr, !day.isEmpty { break }
            if day.contains(where: { $0.kind == event.kind }) { continue }
            day.append(event)
        }
        return day
    }

    /// What a widget shows at `moment` while this flight replaces the ground's list: nil before
    /// takeoff (the ground's own list stands), and nil once the journey's list runs out.
    func widgetDay(at moment: Date, settings: Settings) -> FlightWidgetDay? {
        guard moment >= takeoff, let lastEvent = events.last, moment < lastEvent.time else { return nil }
        // After landing the phone's own place rules as soon as the app hears of it, and the flight
        // ends. Until then the arrival city's list, which the journey already holds; with no
        // destination there is nothing to stand in.
        if moment > landing, !plan.hasDestination { return nil }
        let day = self.day(around: moment)
        guard !day.isEmpty else { return nil }
        let prayers = day.map { settings.flightPrayer(for: $0) }
        func prayer(for event: FlightPrayerEvent?) -> Prayer? {
            guard let event else { return nil }
            if let index = day.firstIndex(where: { $0.id == event.id }) { return prayers[index] }
            return settings.flightPrayer(for: event)
        }
        let city: String
        if let destination = plan.destination {
            city = moment > landing ? destination.spokenCity
                                    : String(localized: "Flying to \(destination.spokenCity)")
        } else {
            city = String(localized: "In the air")
        }
        let current = prayer(for: self.current(at: moment))
        return FlightWidgetDay(city: city, prayers: prayers, current: current,
                               next: prayer(for: next(after: moment)), skyPeriod: current?.nameTransliteration)
    }
}

/// A flight's day as the widgets draw one: in place of the ground's list, city, current and next.
struct FlightWidgetDay {
    var city: String
    var prayers: [Prayer]
    var current: Prayer?
    var next: Prayer?
    var skyPeriod: String?
}

/// The flight as the widget extension sees it. The app mirrors the stored plan into the App Group
/// (`FlightMode.store`), and the extension builds the same timeline from it with its own copy of
/// the calculation settings, which `PrayersProvider.seedSettingsFromAppGroup` keeps the app's.
enum FlightWidgetFeed {
    static let planKey = "flightPlanData"
    private static var memo: (data: Data, signature: String, timeline: FlightTimeline?)?

    static func mirror(_ data: Data, in store: UserDefaults?) {
        guard let store else { return }
        if data.isEmpty {
            if store.object(forKey: planKey) != nil { store.removeObject(forKey: planKey) }
        } else if store.data(forKey: planKey) != data {
            store.set(data, forKey: planKey)
        }
    }

    /// The mirrored plan's bytes: part of what a widget timeline is keyed on (`PrayersProvider.Inputs`).
    static func planData(in store: UserDefaults?) -> Data? {
        guard let data = store?.data(forKey: planKey), !data.isEmpty else { return nil }
        return data
    }

    static func timeline(in store: UserDefaults?, settings: Settings) -> FlightTimeline? {
        guard let data = planData(in: store), let plan = try? JSONDecoder().decode(FlightPlan.self, from: data),
              plan.landing.timeIntervalSinceNow > -24 * 60 * 60 else { return nil }
        let signature = settings.flightPrayerRules(on: plan.takeoff).signature
        if let memo, memo.data == data, memo.signature == signature { return memo.timeline }
        let built = FlightTimeline.build(plan: plan, settings: settings)
        memo = (data, signature, built)
        return built
    }
}

final class FlightMode: ObservableObject {
    static let shared = FlightMode()

    enum Status: Equatable {
        case off
        /// On, and nothing yet says where the aircraft is (`FlightPlan.isWaiting`): the ground's
        /// own list stands, and the first fix in the air starts the board.
        case waiting
        /// A flight is set up and has not taken off.
        case upcoming
        case inFlight
    }

    /// Why Flight Mode thinks there is a flight, which is what the card says and the banner behind it.
    struct Detection: Equatable {
        /// A fix with an aircraft's speed and height. Nil: the phone has settled at `airport`.
        var fix: FlightFix?
        /// The airport the phone is at, for the question asked before the flight.
        var airport: FlightPlace?
        /// Where the phone last was on the ground when the question came up, and when: the origin
        /// a flight started from this card is given.
        var origin: FlightPlace?
        var originSeenAt: Date?
    }

    /// The flight that just ended, for the "you have landed" line. Not persisted: it is news once.
    struct Arrival: Equatable {
        /// The destination, when that is where the flight ended (nil: ended somewhere else).
        var place: FlightPlace?
        /// No fix had arrived, so the destination was taken as the phone's place until one does.
        var adopted = false
        var at: Date
    }

    private enum Ending {
        case byHand
        /// Waiting for a fix for a whole day: the flight was not taken, or is long over.
        case expired
        /// The landing time passed.
        case clock
        /// A fix on the ground, away from the origin.
        case fix(FlightFix)
    }

    @Published private(set) var plan: FlightPlan?
    @Published private(set) var timeline: FlightTimeline?
    /// Published so the Adhan tab swaps its list for the board the minute the aircraft takes off:
    /// a status computed on demand would change with the clock and tell nobody.
    @Published private(set) var status: Status = .off
    @Published var detection: Detection?
    @Published var arrival: Arrival?

    private var settings: Settings { Settings.shared }
    private var statusTimer: Timer?
    /// The newest fix of any kind, in the air or not: where the phone itself last said it was.
    private var lastFix: FlightFix?
    /// Where the phone last was on the ground, caught as the first fix in the air arrives (the
    /// location pipeline commits that fix a moment later, and the place is the sky from then on).
    private var lastGroundPlace: FlightPlace?
    private var lastGroundSeenAt: Date?

    private init() {
        plan = Self.storedPlan()
        if plan == nil { detection = Self.pendingAirportQuestion() }
        #if DEBUG
        if let demo = Self.demoPlan() { plan = demo }
        let arguments = ProcessInfo.processInfo.arguments
        // "-flightDetected": the question as a fix in cruise would raise it, for a simulator that
        // reports no speed.
        if arguments.contains("-flightDetected") {
            detection = Detection(fix: FlightFix(latitude: 50, longitude: -30, altitude: 11_200, speed: 245,
                                                 course: 80, time: Date()))
        }
        // "-flightAtAirport LAX": the question as settling at that airport raises it.
        if let index = arguments.firstIndex(of: "-flightAtAirport"), arguments.indices.contains(index + 1),
           let airport = Airports.airport(code: arguments[index + 1]) {
            detection = Detection(fix: nil, airport: airport.place, origin: airport.place, originSeenAt: Date())
        }
        // "-flightWaiting": on with nothing typed, as the one-tap start leaves it.
        if arguments.contains("-flightWaiting") {
            plan = FlightPlan(origin: nil, destination: nil, departure: Date(), arrival: nil, anchor: nil,
                              holdUntil: nil, detected: true, waitingSince: Date())
        }
        #endif
        status = status(at: Date())
    }

    private func updateStatus(now: Date = Date()) {
        let current = status(at: now)
        if current != status { status = current }
    }

    // MARK: - Reading

    func status(at now: Date = Date()) -> Status {
        guard let plan else { return .off }
        if plan.isWaiting { return .waiting }
        if now < plan.takeoff { return .upcoming }
        return .inFlight
    }

    /// The timeline, rebuilt first if the plan or the calculation settings moved under it. The
    /// scheduler and the screens both come through here, so they can never disagree.
    @discardableResult
    func currentTimeline() -> FlightTimeline? {
        guard let plan, !plan.isWaiting else {
            if timeline != nil { timeline = nil }
            return nil
        }
        let signature = settings.flightPrayerRules(on: plan.takeoff).signature
        if let timeline, timeline.plan == plan, timeline.rulesSignature == signature { return timeline }
        let built = FlightTimeline.build(plan: plan, settings: settings)
        if timeline != built { timeline = built }
        return built
    }

    /// Where the phone last was on the ground, as a flight's origin: the airport it was at or near
    /// (within 60 km, which takes in the drive from the terminal's city), or failing one the place
    /// itself under the app's own name for it. Nil with no location at all.
    func lastKnownPlace() -> FlightPlace? {
        guard let here = settings.currentLocation, here.latitude != 1000, here.longitude != 1000 else { return nil }
        let point = FlightCoordinate(latitude: here.latitude, longitude: here.longitude)
        if let airport = Airports.nearest(to: point, within: 60_000) { return airport.place }
        return FlightPlace.place(named: here.displayCity, latitude: here.latitude, longitude: here.longitude,
                                 country: settings.currentCountryCode)
    }

    // MARK: - Starting, changing, ending

    /// A flight typed into the form, or the form's changes to the one under way (the form starts
    /// from the plan it is changing, so a fix already taken in the air travels with it).
    func begin(_ newPlan: FlightPlan) {
        clearQuestion()
        arrival = nil
        store(newPlan)
    }

    /// "Turn On Flight Mode", with nothing typed. If the phone already knows it is in the air the
    /// flight follows that fix at once; otherwise it starts from where the phone last was and
    /// waits for the first fix in the air.
    func turnOn(now: Date = Date()) {
        if let fix = lastFix, Self.isAirborne(speed: fix.speed, altitude: fix.altitude),
           now.timeIntervalSince(fix.time) < 5 * 60 {
            detection = Detection(fix: fix, airport: nil, origin: lastGroundPlace, originSeenAt: lastGroundSeenAt)
            beginFromDetection()
            return
        }
        clearQuestion()
        arrival = nil
        store(FlightPlan(origin: lastKnownPlace(), destination: nil, departure: now, arrival: nil, anchor: nil,
                         holdUntil: nil, detected: true,
                         originSeenAt: Settings.lastLocationFixAt ?? now, waitingSince: now))
        // The sooner a fix arrives, the sooner there is a board.
        settings.refreshLocationIfStale(olderThan: 60)
    }

    /// "Turn On" on the card. From a fix in the air: a flight that starts where the phone last was
    /// on the ground, passes through the fix and follows the course being flown. From an airport:
    /// a flight that starts there and waits for the first fix. Either way the page offers the
    /// destination.
    func beginFromDetection() {
        guard let found = detection else { return }
        clearQuestion()
        arrival = nil
        guard let fix = found.fix else {
            let now = Date()
            store(FlightPlan(origin: found.airport ?? found.origin, destination: nil, departure: now, arrival: nil,
                             anchor: nil, holdUntil: nil, detected: true, originSeenAt: now, waitingSince: now))
            return
        }
        var plan = FlightPlan(origin: found.origin, destination: nil, departure: fix.time, arrival: nil,
                              anchor: nil, holdUntil: nil, detected: true, originSeenAt: found.originSeenAt)
        Self.takeFirstFix(fix, into: &plan)
        store(plan)
    }

    /// "Not Now" on the card: the question waits twelve hours, longer than any flight's leg. An
    /// airport turned down twice is not asked about again (someone works there, or lives beside it).
    func declineDetection() {
        if let airport = detection?.airport, detection?.fix == nil {
            var declined = Self.declinedAirports()
            declined[airport.code, default: 0] += 1
            UserDefaults.standard.set(declined, forKey: Self.declinedAirportsKey)
        }
        clearQuestion()
        settings.flightAskSnoozedUntil = Date().addingTimeInterval(12 * 60 * 60).timeIntervalSince1970
    }

    private func clearQuestion() {
        detection = nil
        UserDefaults.standard.removeObject(forKey: Self.pendingAirportKey)
    }

    /// The first fix in the air of a flight nobody typed: it becomes the anchor, and the takeoff
    /// is worked back from how far the fix is from the origin. An origin the aircraft could not
    /// have come from in the time (the phone's last place was stale) is dropped, and the route
    /// then starts at the fix.
    static func takeFirstFix(_ fix: FlightFix, into plan: inout FlightPlan) {
        plan.anchor = fix
        plan.everAloft = true
        plan.waitingSince = nil
        plan.detected = true
        plan.holdUntil = nil
        var takeoff = fix.time.addingTimeInterval(-60)
        if let origin = plan.origin {
            let distance = FlightGeometry.distance(from: origin.coordinate, to: fix.coordinate)
            // A climb covers ground slower than the cruise the fix was taken in.
            takeoff = fix.time.addingTimeInterval(-max(60, distance / max(fix.speed * 0.9, 150)))
            if let seen = plan.originSeenAt, seen > takeoff {
                // The phone was still on the ground there later than that: either the flight was
                // quicker (it left at `seen` at the earliest), or this is not where it came from.
                let fastest = distance / 330
                if fix.time.timeIntervalSince(seen) < fastest {
                    plan.origin = nil
                    takeoff = fix.time.addingTimeInterval(-60)
                } else {
                    takeoff = min(seen, fix.time.addingTimeInterval(-60))
                }
            }
        }
        plan.departure = takeoff
    }

    /// Ends the flight: by hand (`arrived` false), or because its landing time has passed.
    func end(arrived: Bool) {
        finish(arrived ? .clock : .byHand)
    }

    private func finish(_ ending: Ending) {
        guard let finished = plan else { return }
        plan = nil
        timeline = nil
        settings.flightPlanData = Data()
        FlightWidgetFeed.mirror(Data(), in: settings.appGroupUserDefaults)
        settings.reloadWidgets(deferred: true)
        stopStatusTimer()
        updateStatus()
        switch ending {
        case .expired:
            // On for a day with no fix in the air: nothing to say, and nothing was changed.
            return
        case .byHand:
            // Ended by hand in the air, the question would come straight back on the next fix.
            settings.flightAskSnoozedUntil = Date().addingTimeInterval(12 * 60 * 60).timeIntervalSince1970
        case let .fix(fix):
            // The phone knows where it is, and the location pipeline commits that fix next.
            arrival = Arrival(place: isNear(fix, finished.destination) ? finished.destination : nil, at: Date())
        case .clock:
            settleByClock(finished)
        }
        settings.fetchPrayerTimes(force: true, notification: true)
    }

    private func isNear(_ fix: FlightFix, _ place: FlightPlace?) -> Bool {
        guard let place else { return false }
        return FlightGeometry.distance(from: fix.coordinate, to: place.coordinate) < 150_000
    }

    /// The landing time has passed and no fix on the ground has said so. Where is the phone?
    ///
    /// Its own word comes first: a fix since the landing means the phone is wherever that fix put
    /// it, the destination or not (a flight set up and never taken ends here, still at home, and
    /// must not be moved to another continent). Only with no fix at all, which is the passenger
    /// who opens the app in airplane mode on the taxiway, does the destination stand in, so the
    /// list and the notifications are the arrival city's from the first minute. One is asked for
    /// first, and given a few seconds.
    private func settleByClock(_ finished: FlightPlan) {
        guard let destination = finished.destination else { return }
        let landing = finished.landing
        let decide = { [weak self] in
            guard let self, self.plan == nil else { return }
            if let fix = self.lastFix, fix.time > landing.addingTimeInterval(-10 * 60) {
                self.arrival = Arrival(place: self.isNear(fix, destination) ? destination : nil, at: Date())
                return
            }
            self.settings.adoptFlightDestination(destination)
            self.arrival = Arrival(place: destination, adopted: true, at: Date())
            self.settings.fetchPrayerTimes(force: true, notification: true)
        }
        if let fix = lastFix, fix.time > landing.addingTimeInterval(-10 * 60) {
            decide()
            return
        }
        settings.refreshLocationIfStale(olderThan: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: decide)
    }

    private func store(_ newPlan: FlightPlan) {
        plan = newPlan
        let data = (try? JSONEncoder().encode(newPlan)) ?? Data()
        settings.flightPlanData = data
        // The widgets read the same plan (`FlightWidgetFeed`), so their list is the board's.
        FlightWidgetFeed.mirror(data, in: settings.appGroupUserDefaults)
        currentTimeline()
        updateStatus()
        startStatusTimer()
        // The schedule changes whenever the flight does: its prayers in, the ground's out.
        settings.scheduleNotifications(deferred: true)
        settings.reloadWidgets(deferred: true)
    }

    /// A change that moves no prayer (a waiting plan's origin following the phone): saved, and
    /// nothing rescheduled.
    private func storeQuietly(_ newPlan: FlightPlan) {
        plan = newPlan
        let data = (try? JSONEncoder().encode(newPlan)) ?? Data()
        settings.flightPlanData = data
        FlightWidgetFeed.mirror(data, in: settings.appGroupUserDefaults)
    }

    private static func storedPlan() -> FlightPlan? {
        // Read from the store itself, not through `Settings.shared` (the same key, `flightPlanData`):
        // this runs in `init`, and must not be what first builds `Settings` or be built from inside it.
        guard let data = UserDefaults.standard.data(forKey: "flightPlanData"), !data.isEmpty,
              let plan = try? JSONDecoder().decode(FlightPlan.self, from: data) else { return nil }
        // A flight whose landing is more than a day behind is over, whatever became of it.
        return plan.landing.timeIntervalSinceNow < -24 * 60 * 60 ? nil : plan
    }

    // The question asked at an airport outlives the process that asked it: the app is woken in the
    // background to ask, and may be gone by the time the notification is tapped. Kept in the
    // standard defaults under keys of its own (this device only, like the plan).
    private static let pendingAirportKey = "flightPendingAirport"
    private static let lastAirportQuestionKey = "flightLastAirportQuestionAt"
    private static let declinedAirportsKey = "flightDeclinedAirports"
    /// How long the question stands: about as long as anyone waits at a gate.
    private static let airportQuestionLife: TimeInterval = 4 * 60 * 60

    private static func declinedAirports() -> [String: Int] {
        (UserDefaults.standard.dictionary(forKey: declinedAirportsKey) as? [String: Int]) ?? [:]
    }

    private static func pendingAirportQuestion(now: Date = Date()) -> Detection? {
        let defaults = UserDefaults.standard
        guard let code = defaults.string(forKey: pendingAirportKey),
              now.timeIntervalSince1970 - defaults.double(forKey: lastAirportQuestionKey) < airportQuestionLife,
              now.timeIntervalSince1970 > defaults.double(forKey: "flightAskSnoozedUntil"),
              let airport = Airports.airport(code: code) else { return nil }
        return Detection(fix: nil, airport: airport.place, origin: airport.place,
                         originSeenAt: Date(timeIntervalSince1970: defaults.double(forKey: lastAirportQuestionKey)))
    }

    // MARK: - The clock

    /// Called when the app comes forward and once a minute while a flight is on: a flight whose
    /// landing time has passed is over.
    func refresh(now: Date = Date()) {
        guard var plan else {
            // No flight here means no flight in the widgets: their copy of the plan lives in the App
            // Group, which outlasts this app's own store (a restore, a reinstall beside a sibling
            // app, a launch that cleared the plan), and a copy left there kept the lock screen "In
            // the air" with the flight's times while the app showed the ground's (seen 2026-11-26).
            // Only the app: the extension keeps no plan of its own, and must never clear the app's.
            if Settings.isAppProcess, FlightWidgetFeed.planData(in: settings.appGroupUserDefaults) != nil {
                FlightWidgetFeed.mirror(Data(), in: settings.appGroupUserDefaults)
                settings.reloadWidgets(deferred: true)
            }
            // A question asked at an airport hours ago is no longer a question.
            if let found = detection, found.fix == nil, Self.pendingAirportQuestion(now: now) == nil {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-flightAtAirport") { return }
                #endif
                clearQuestion()
            }
            return
        }
        startStatusTimer()
        if plan.isWaiting {
            // On for a day with no fix in the air: not taken, or long over.
            if now.timeIntervalSince(plan.waitingSince ?? plan.departure) > 24 * 60 * 60 {
                finish(.expired)
                return
            }
            updateStatus(now: now)
            askForFix(olderThan: 90)
            return
        }
        if !plan.hasDestination {
            // No destination: the horizon is only how far ahead the course was followed. Past it
            // the fix is too old to say where the aircraft is, and the flight waits for another.
            if now > plan.landing {
                plan.anchor = nil
                plan.waitingSince = now
                store(plan)
                askForFix(olderThan: 90)
                return
            }
        } else if now > plan.landing.addingTimeInterval(20 * 60) {
            // Twenty minutes past wheels-down the traveler is at the gate.
            end(arrived: true)
            return
        }
        // In the air, a fix older than ten minutes (or none yet) is worth replacing: a course held
        // for hours drifts from the route, and a timetable is only a timetable.
        if now >= plan.takeoff, now <= plan.landing,
           plan.anchor.map({ now.timeIntervalSince($0.time) > 10 * 60 }) ?? true {
            askForFix(olderThan: 120)
        }
        currentTimeline()
        updateStatus(now: now)
    }

    /// A fix, asked for while the app is running (`refresh` is called as it comes forward and by a
    /// timer that only runs then): what turns a waiting flight into a board and keeps a followed
    /// course honest. In airplane mode this is the GPS alone, which needs a view
    /// of the sky (`Settings.refreshLocationIfStale` runs its longer offline acquisition then).
    private func askForFix(olderThan age: TimeInterval) {
        guard Settings.isAppProcess else { return }
        if let fix = lastFix, Date().timeIntervalSince(fix.time) < age { return }
        settings.refreshLocationIfStale(olderThan: age)
    }

    private func startStatusTimer() {
        guard statusTimer == nil, Settings.isAppProcess else { return }
        let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
        RunLoop.main.add(timer, forMode: .common)
        statusTimer = timer
    }

    private func stopStatusTimer() {
        statusTimer?.invalidate()
        statusTimer = nil
    }

    // MARK: - GPS

    /// Whether a speed and height can only be an aircraft's. Faster than any train (130 m/s is
    /// 470 km/h), or fast AND high: a turboprop or a climb, where no road or railway runs at
    /// 215 km/h two and a half kilometres up.
    static func isAirborne(speed: Double, altitude: Double?) -> Bool {
        if speed >= 130 { return true }
        return speed >= 60 && (altitude ?? 0) >= 2_500
    }

    /// Every fix the location manager delivers comes through here before it is committed
    /// (`Settings.locationManager(_:didUpdateLocations:)`).
    func note(fix location: CLLocation) {
        guard Settings.isAppProcess,
              location.horizontalAccuracy > 0, location.horizontalAccuracy <= 5_000,
              location.speed >= 0, abs(location.timestamp.timeIntervalSinceNow) <= 120 else { return }
        let altitude = location.verticalAccuracy > 0 ? location.altitude : nil
        let fix = FlightFix(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude,
                            altitude: altitude, speed: location.speed,
                            course: location.course >= 0 ? location.course : nil, time: location.timestamp)
        note(fix: fix)
    }

    func note(fix: FlightFix) {
        // Where the phone was before this fix, while that is still the ground's word: the origin
        // of a flight this fix turns out to begin.
        let airborne = Self.isAirborne(speed: fix.speed, altitude: fix.altitude)
        if !airborne, fix.speed < 30 {
            lastGroundSeenAt = fix.time
            lastGroundPlace = nil
        } else if airborne, lastGroundPlace == nil, lastFix.map({ !Self.isAirborne(speed: $0.speed, altitude: $0.altitude) }) ?? true {
            lastGroundPlace = lastKnownPlace()
            if lastGroundSeenAt == nil { lastGroundSeenAt = Settings.lastLocationFixAt }
        }
        lastFix = fix

        guard var plan else {
            // An airport's question gives way to the fact of being in the air.
            guard airborne, settings.flightAutomatic, detection?.fix == nil,
                  fix.time.timeIntervalSince1970 > settings.flightAskSnoozedUntil else { return }
            UserDefaults.standard.removeObject(forKey: Self.pendingAirportKey)
            detection = Detection(fix: fix, airport: nil, origin: lastGroundPlace, originSeenAt: lastGroundSeenAt)
            settings.notifyFlightDetected()
            return
        }

        if plan.isWaiting {
            if airborne {
                if plan.everAloft == true {
                    // Followed before, lost, found again: the takeoff it was given stands.
                    plan.anchor = fix
                    plan.waitingSince = nil
                } else {
                    if plan.origin == nil {
                        plan.origin = lastGroundPlace
                        plan.originSeenAt = lastGroundSeenAt
                    }
                    Self.takeFirstFix(fix, into: &plan)
                }
                store(plan)
                return
            }
            guard fix.speed < 30 else { return }
            if plan.everAloft == true {
                // It has flown, and this is the ground: wherever this is, the flight is over.
                finish(.fix(fix))
                return
            }
            // Not flown yet. The origin is wherever the phone is on the ground (the drive to the
            // airport moves it); a jump no road covers means the flight went by unseen.
            if let origin = plan.origin {
                let moved = FlightGeometry.distance(from: origin.coordinate, to: fix.coordinate)
                let elapsed = fix.time.timeIntervalSince(plan.originSeenAt ?? plan.departure)
                if moved > 700_000, elapsed > 0, moved / elapsed > 25 {
                    finish(.fix(fix))
                    return
                }
                guard moved > 5_000 || elapsed > 30 * 60 else { return }
            }
            plan.origin = Self.groundPlace(at: fix, named: settings.currentLocation?.displayCity,
                                           country: settings.currentCountryCode) ?? plan.origin
            plan.originSeenAt = fix.time
            storeQuietly(plan)
            return
        }

        if airborne {
            // Not this flight: a fix in the air hours before a flight typed for tomorrow.
            guard fix.time > plan.departure.addingTimeInterval(-45 * 60) else { return }
            // One anchor a minute is plenty; each one rebuilds the timeline and the schedule.
            if let last = plan.anchor, fix.time.timeIntervalSince(last.time) < 60 { return }
            if fix.time <= plan.takeoff {
                // In the air before the timetable said so: the flight left early.
                plan.holdUntil = nil
                plan.departure = plan.departure.addingTimeInterval(fix.time.timeIntervalSince(plan.takeoff) - 120)
            }
            plan.anchor = fix
            store(plan)
            return
        }

        guard fix.speed < 30 else { return }
        let here = fix.coordinate
        let atOrigin = plan.origin.map { FlightGeometry.distance(from: here, to: $0.coordinate) < 40_000 } ?? false
        if atOrigin, plan.anchor == nil {
            let printedTakeoff = plan.departure.addingTimeInterval(FlightPlan.taxiOut)
            if fix.time > printedTakeoff.addingTimeInterval(6 * 60 * 60) {
                // Six hours on, still at the origin: that is not a delay, the flight was not taken.
                // (Held any longer, a traveler who lives beside the airport would have his own
                // city's prayers kept quiet behind a flight that slides forever.)
                finish(.fix(fix))
            } else if fix.time > plan.takeoff.addingTimeInterval(-60) {
                // Still at the gate or on the taxiway after the printed takeoff: the flight slides.
                plan.holdUntil = fix.time.addingTimeInterval(5 * 60)
                store(plan)
            }
            return
        }
        // On the ground and not at the origin, once the flight has been in the air: it has landed
        // (at the destination or somewhere else; the fix itself now says where).
        let wasFlying = plan.anchor != nil || fix.time > plan.takeoff.addingTimeInterval(20 * 60)
        if wasFlying, fix.time > plan.takeoff {
            finish(.fix(fix))
        }
    }

    /// The place a ground fix is at, as an origin: its airport if it is at or near one, else the
    /// point itself under the name the app last had for the phone's place.
    private static func groundPlace(at fix: FlightFix, named city: String?, country: String) -> FlightPlace? {
        if let airport = Airports.nearest(to: fix.coordinate, within: 60_000) { return airport.place }
        guard let city, !city.isEmpty else { return nil }
        return FlightPlace.place(named: city, latitude: fix.latitude, longitude: fix.longitude, country: country)
    }

    // MARK: - At the airport

    /// The airport a settled phone is at, if it is one worth asking about: a large or medium one
    /// (an airstrip sits inside its village), near enough to be the terminal and not the motorway
    /// past it, and not the one the traveler lives beside.
    static func airport(around point: FlightCoordinate, accuracy: Double, home: FlightCoordinate?) -> Airport? {
        guard accuracy > 0, accuracy <= 1_500 else { return nil }
        guard let airport = Airports.nearest(to: point, within: 3_000), airport.size != "S" else { return nil }
        let away = FlightGeometry.distance(from: point, to: FlightCoordinate(latitude: airport.latitude, longitude: airport.longitude))
        guard away <= (airport.size == "L" ? 2_500 : 1_500) else { return nil }
        if let home, FlightGeometry.distance(from: home, to: FlightCoordinate(latitude: airport.latitude, longitude: airport.longitude)) < 5_000 {
            return nil
        }
        return airport
    }

    /// The phone has settled somewhere (a visit, `Settings.locationManager(_:didVisit:)`, or a
    /// still, sharp fix with the app open). At an airport, with no flight on, Flight Mode asks
    /// before the flight (Abu, 2026-11-26: "Send notification if assumed u are on plane"): this is
    /// the one moment iOS will run the app for it. In the air in airplane mode nothing wakes an
    /// app, so a question left for the cruise reaches only someone who opens the app there.
    func noteArrival(at point: FlightCoordinate, accuracy: Double, time: Date = Date(), inline: Bool = false) {
        guard mayAskAtAnAirport(at: time) else { return }
        let home = settings.homeLocation.map { FlightCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
        // The airport list is unpacked the first time it is read (a few milliseconds), and a fix
        // standing still arrives at every launch: off the main thread, so no launch pays for it.
        // (`inline` is for tests, which read the answer on the next line.)
        let look = { Self.airport(around: point, accuracy: accuracy, home: home) }
        if inline {
            if let airport = look() { ask(at: airport, time: time) }
            return
        }
        DispatchQueue.global(qos: .utility).async {
            guard let airport = look() else { return }
            DispatchQueue.main.async { [weak self] in self?.ask(at: airport, time: time) }
        }
    }

    /// Whether a question at an airport may be raised at all: the cheap half, checked before the
    /// airport list is touched, and again when its answer comes back.
    private func mayAskAtAnAirport(at time: Date) -> Bool {
        guard Settings.isAppProcess, plan == nil, detection == nil, settings.flightAutomatic,
              abs(time.timeIntervalSinceNow) < 60 * 60,
              time.timeIntervalSince1970 > settings.flightAskSnoozedUntil else { return false }
        // Once a visit: a second settling inside the same wait at the gate asks nothing.
        return time.timeIntervalSince1970 - UserDefaults.standard.double(forKey: Self.lastAirportQuestionKey) > 12 * 60 * 60
    }

    private func ask(at airport: Airport, time: Date) {
        guard mayAskAtAnAirport(at: time), Self.declinedAirports()[airport.code, default: 0] < 2 else { return }
        let defaults = UserDefaults.standard
        defaults.set(airport.code, forKey: Self.pendingAirportKey)
        defaults.set(time.timeIntervalSince1970, forKey: Self.lastAirportQuestionKey)
        detection = Detection(fix: nil, airport: airport.place, origin: airport.place, originSeenAt: time)
        settings.notifyFlightSuggested(at: airport.place)
    }

    // MARK: - Screenshots and tests

    #if DEBUG
    /// "-flightDemo JFK,LHR,-120,300": a flight from JFK to LHR that left the gate 120 minutes ago
    /// and reaches the gate in 300, so the board can be opened on a simulator that never flies.
    /// A positive first number is a flight still to leave.
    private static func demoPlan() -> FlightPlan? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-flightDemo"), arguments.indices.contains(index + 1) else { return nil }
        let parts = arguments[index + 1].split(separator: ",").map(String.init)
        guard parts.count == 4, let from = Airports.airport(code: parts[0]), let to = Airports.airport(code: parts[1]),
              let left = Double(parts[2]), let arrives = Double(parts[3]) else { return nil }
        let now = Date()
        return FlightPlan(origin: from.place, destination: to.place,
                          departure: now.addingTimeInterval(left * 60), arrival: now.addingTimeInterval(arrives * 60),
                          anchor: nil, holdUntil: nil, detected: false)
    }
    #endif

    /// For tests: a plan put in place without touching the stored one or the schedule.
    func replacePlanForTesting(_ newPlan: FlightPlan?) {
        plan = newPlan
        timeline = nil
        detection = nil
        arrival = nil
        lastFix = nil
        lastGroundPlace = nil
        lastGroundSeenAt = nil
        for key in [Self.pendingAirportKey, Self.lastAirportQuestionKey, Self.declinedAirportsKey] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        updateStatus()
        if newPlan == nil { stopStatusTimer() }
    }
}
#endif
