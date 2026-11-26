import XCTest
import CoreLocation
import Adhan
@testable import iPhone

/// Flight Mode (Abu, 2026-11-25: "i want it to be accurate telling u when to pray each prayer ON
/// the plane"): the route as a function of time, the prayers found along it, and the mode's own
/// rules (what counts as an aircraft, how a flight starts and ends, which ground times it replaces).
///
/// The anchor of the whole thing is the first test: where the route stands still on the ground, the
/// solver must give the times the app already shows for that place. Everything in the air is that
/// same sun, followed along a moving point and seen from a height.
@MainActor
final class FlightPrayerTests: XCTestCase {

    private struct Saved {
        let location: Location?
        let country: String
        let calculation: String
        let hanafi: Bool
        let automatic: Bool
        let snoozed: Double
        let planData: Data
        /// The stored Automatic calculation switch, as the store holds it (nil: never written).
        let automaticCalculation: Any?
    }
    private static var saved: Saved?

    /// 10 March 2026, 12:00 UTC: near an equinox, so no latitude here is in a polar season.
    private let day = Date(timeIntervalSince1970: 1_773_144_000)

    override func setUp() async throws {
        try await super.setUp()
        let settings = Settings.shared
        if Self.saved == nil {
            Self.saved = Saved(location: settings.currentLocation, country: settings.currentCountryCode,
                               calculation: settings.prayerCalculation, hanafi: settings.hanafiMadhab,
                               automatic: settings.flightAutomatic, snoozed: settings.flightAskSnoozedUntil,
                               planData: settings.flightPlanData,
                               automaticCalculation: UserDefaults.standard.object(forKey: "calculationAutomatic"))
        }
        // These tests move the location and the country (a flight ends in London; a refresh
        // geocodes wherever the test stands). With Automatic calculation on, the method would follow
        // and the next launch would announce a change nobody made. Off for the test, written to the
        // store itself: the property's didSet forgets which card was answered.
        UserDefaults.standard.set(false, forKey: "calculationAutomatic")
        settings.prayerCalculation = PrayerCalculationCatalog.muslimWorldLeagueID
        settings.hanafiMadhab = false
        settings.flightAutomatic = true
        settings.flightAskSnoozedUntil = 0
        FlightMode.shared.replacePlanForTesting(nil)
    }

    override func tearDown() async throws {
        let settings = Settings.shared
        FlightMode.shared.replacePlanForTesting(nil)
        if let saved = Self.saved {
            settings.prayerCalculation = saved.calculation
            settings.hanafiMadhab = saved.hanafi
            settings.flightAutomatic = saved.automatic
            settings.flightAskSnoozedUntil = saved.snoozed
            settings.flightPlanData = saved.planData
            settings.currentLocation = saved.location
            settings.currentCountryCode = saved.country
            if let automatic = saved.automaticCalculation {
                UserDefaults.standard.set(automatic, forKey: "calculationAutomatic")
            } else {
                UserDefaults.standard.removeObject(forKey: "calculationAutomatic")
            }
        }
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func place(_ code: String) throws -> FlightPlace {
        try XCTUnwrap(Airports.airport(code: code), "no airport \(code)").place
    }

    private func plan(_ from: String, _ to: String, departs: Date, hours: Double) throws -> FlightPlan {
        FlightPlan(origin: try place(from), destination: try place(to), departure: departs,
                   arrival: departs.addingTimeInterval(hours * 3600), anchor: nil, holdUntil: nil, detected: false)
    }

    private func timeline(_ plan: FlightPlan) throws -> FlightTimeline {
        FlightMode.shared.replacePlanForTesting(plan)
        return try XCTUnwrap(FlightMode.shared.currentTimeline())
    }

    private func nearest(_ kind: FlightPrayerKind, to time: Date, in events: [FlightPrayerEvent]) -> FlightPrayerEvent? {
        events.filter { $0.kind == kind }
            .min { abs($0.time.timeIntervalSince(time)) < abs($1.time.timeIntervalSince(time)) }
    }

    // MARK: - The sun on the ground

    /// On the board, a prayer on the ground reads exactly as that city's own table does.
    func testTheBoardsGroundRowsAreTheCitysOwnTimes() throws {
        let settings = Settings.shared
        let line = try timeline(try plan("JFK", "LHR", departs: day, hours: 7))
        var checked = 0
        for (phase, code) in [(FlightState.Phase.beforeTakeoff, "JFK"), (.afterLanding, "LHR")] {
            let here = try place(code)
            let location = Location(city: here.city, latitude: here.latitude, longitude: here.longitude)
            let tables = [-1, 0, 1].compactMap { offset in
                settings.getPrayerTimes(for: day.addingTimeInterval(Double(offset) * 86_400), at: location, fullPrayers: true)
            }.flatMap { $0 }
            for event in line.events where event.phase == phase {
                XCTAssertTrue(tables.contains { event.kind.matches(groundName: $0.nameTransliteration) && $0.time == event.time },
                              "\(code) \(event.kind) at \(event.time)")
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 4)
    }

    /// Standing still at sea level, the route's prayers are the day's table for that place.
    func testARouteThatStandsStillGivesTheGroundTimes() throws {
        let settings = Settings.shared
        let rules = settings.flightPrayerRules(on: day).rules
        var worst: TimeInterval = 0
        for code in ["JED", "LHR", "CGK", "JFK", "CPT", "NRT", "GRU"] {
            let here = try place(code)
            // A flight that leaves two days from now: until then the traveler is at the origin.
            let plan = try plan(code, code == "JED" ? "LHR" : "JED", departs: day.addingTimeInterval(48 * 3600), hours: 6)
            let events = FlightPrayerSolver.events(along: plan.path, rules: rules,
                                                   from: day.addingTimeInterval(-30 * 3600), to: day.addingTimeInterval(30 * 3600))
            let location = Location(city: here.city, latitude: here.latitude, longitude: here.longitude)
            let table = try XCTUnwrap(settings.getPrayerTimes(for: day, at: location, fullPrayers: true))
            XCTAssertEqual(table.count, 6, code)
            for prayer in table {
                let kind = try XCTUnwrap(FlightPrayerKind.allCases.first { $0.matches(groundName: prayer.nameTransliteration) },
                                         prayer.nameTransliteration)
                let found = try XCTUnwrap(nearest(kind, to: prayer.time, in: events), "\(code) \(kind)")
                XCTAssertEqual(found.phase, .beforeTakeoff)
                let off = abs(found.time.timeIntervalSince(prayer.time))
                worst = max(worst, off)
                // The two round to the minute from instants a few seconds apart: never more than one.
                XCTAssertLessThanOrEqual(off, 60, "\(code) \(kind): \(found.time) against \(prayer.time)")
            }
        }
        print("FLIGHT ground agreement: worst \(Int(worst)) s")
    }

    /// The same comparison before any rounding: the instant the solver finds against the instant
    /// the ground engine finds. The two reach the sun's angle by different roads (a search along
    /// the route; Meeus's interpolation from midnight), and must meet within seconds.
    func testTheSolversInstantsAreTheGroundEnginesWithinSeconds() throws {
        let settings = Settings.shared
        let found = settings.flightPrayerRules(on: day)
        var parameters = settings.calculationParameters(forStoredLabel: settings.prayerCalculation)
        parameters.madhab = .shafi
        var worst: TimeInterval = 0
        for code in ["JED", "LHR", "CGK", "JFK", "CPT", "NRT", "GRU", "IST", "KUL", "LAX"] {
            let here = try place(code)
            parameters.highLatitudeRule = settings.resolvedHighLatitudeRule(latitude: here.latitude, parameters: parameters)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .current
            let date = calendar.dateComponents([.year, .month, .day], from: day)
            let ground = try XCTUnwrap(Settings.resolvedPrayerTimes(latitude: here.latitude, longitude: here.longitude,
                                                                    date: date, parameters: parameters), code)
            guard parameters.rounding == Rounding.none else { throw XCTSkip("this method rounds inside the engine") }
            let plan = try plan(code, code == "JED" ? "LHR" : "JED", departs: day.addingTimeInterval(48 * 3600), hours: 6)
            let events = FlightPrayerSolver.events(along: plan.path, rules: found.rules,
                                                   from: day.addingTimeInterval(-30 * 3600), to: day.addingTimeInterval(30 * 3600))
            let pairs: [(FlightPrayerKind, Date)] = [
                (.fajr, ground.fajr), (.sunrise, ground.sunrise), (.dhuhr, ground.dhuhr),
                (.asr, ground.asr), (.maghrib, ground.maghrib), (.isha, ground.isha),
            ]
            for (kind, engine) in pairs {
                let event = try XCTUnwrap(events.filter { $0.kind == kind }
                    .min { abs($0.instant.timeIntervalSince(engine)) < abs($1.instant.timeIntervalSince(engine)) })
                // The engine's instant carries the method's own minutes (Dhuhr +1 for this one).
                let mine = event.instant.addingTimeInterval(found.rules.adjustments[kind] ?? 0)
                    .addingTimeInterval(-Double(manualOffset(kind)) * 60)
                let off = abs(mine.timeIntervalSince(engine))
                // Where the high-latitude rule sets the time from the night's length, the engine
                // measures the night after that dawn and the solver the night the dawn ends: at
                // London in March the two nights differ by four minutes, a seventh of which shows.
                if event.fromNightPortion {
                    XCTAssertLessThanOrEqual(off, 120, "\(code) \(kind), from the night's length: \(off) s")
                    continue
                }
                worst = max(worst, off)
                XCTAssertLessThanOrEqual(off, 20, "\(code) \(kind): \(off) s")
            }
        }
        print("FLIGHT instant agreement: worst \(String(format: "%.1f", worst)) s")
    }

    private func manualOffset(_ kind: FlightPrayerKind) -> Int {
        let settings = Settings.shared
        switch kind {
        case .fajr: return settings.offsetFajr
        case .sunrise: return settings.offsetSunrise
        case .dhuhr: return settings.offsetDhuhr
        case .asr: return settings.offsetAsr
        case .maghrib: return settings.offsetMaghrib
        case .isha: return settings.offsetIsha
        }
    }

    // MARK: - The sun from a height

    func testTheHorizonDropsWithHeight() {
        XCTAssertEqual(FlightPrayerRules.horizonDip(altitude: 0), 0)
        XCTAssertEqual(FlightPrayerRules.horizonDip(altitude: 11_000), 3.63, accuracy: 0.05)
        XCTAssertEqual(FlightPrayerRules.horizonDip(altitude: 828), 1.0, accuracy: 0.05, "the Burj Khalifa's top: a degree")
    }

    /// The same point on the Earth, on the ground and 11 km above it: the sun sets later and rises
    /// earlier for the aircraft, dawn is earlier and nightfall later, and the two prayers read
    /// from the sun's height overhead (Dhuhr, Asr) do not move.
    func testAtCruisingHeightTheDayIsLongerAtBothEnds() throws {
        let settings = Settings.shared
        let rules = settings.flightPrayerRules(on: day).rules
        let cairo = try place("CAI")
        let location = Location(city: cairo.city, latitude: cairo.latitude, longitude: cairo.longitude)
        let table = try XCTUnwrap(settings.getPrayerTimes(for: day, at: location, fullPrayers: true))
        func ground(_ name: String) throws -> Date { try XCTUnwrap(table.first { $0.nameTransliteration == name }).time }

        // "Flying" from Cairo to Cairo for two days: always overhead, always at cruise height.
        let hover = FlightPlan(origin: cairo, destination: cairo, departure: day.addingTimeInterval(-24 * 3600),
                               arrival: day.addingTimeInterval(24 * 3600), anchor: nil, holdUntil: nil, detected: false)
        let events = FlightPrayerSolver.events(along: hover.path, rules: rules,
                                               from: day.addingTimeInterval(-20 * 3600), to: day.addingTimeInterval(20 * 3600))
        func air(_ kind: FlightPrayerKind, _ name: String) throws -> TimeInterval {
            let groundTime = try ground(name)
            let found = try XCTUnwrap(nearest(kind, to: groundTime, in: events))
            XCTAssertEqual(found.phase, .inFlight)
            XCTAssertEqual(found.altitude, 11_000, accuracy: 1)
            return found.time.timeIntervalSince(groundTime) / 60
        }

        let maghrib = try air(.maghrib, "Maghrib")
        XCTAssert((12...22).contains(maghrib), "Maghrib \(maghrib) min later")
        let sunrise = try air(.sunrise, "Shurooq")
        XCTAssert((-22 ... -12).contains(sunrise), "sunrise \(sunrise) min")
        XCTAssert(try air(.fajr, "Fajr") < -10, "dawn is seen earlier from above")
        XCTAssert(try air(.isha, "Isha") > 10, "the afterglow is seen longer from above")
        XCTAssertEqual(try air(.dhuhr, "Dhuhr"), 0, accuracy: 1)
        XCTAssertEqual(try air(.asr, "Asr"), 0, accuracy: 1)
    }

    // MARK: - The sun along a route

    /// Westbound with the sun, noon comes later than it would have at the origin and earlier than
    /// it will at the destination: the aircraft is between the two.
    func testFlyingWestNoonFallsBetweenTheTwoCities() throws {
        // London to New York, off the gate at 10:00 UTC, 8 hours.
        let start = Date(timeIntervalSince1970: (day.timeIntervalSince1970 / 86_400).rounded(.down) * 86_400 + 10 * 3600)
        let line = try timeline(try plan("LHR", "JFK", departs: start, hours: 8))
        let noon = try XCTUnwrap(line.inFlight.first { $0.kind == .dhuhr }, "no Dhuhr aboard")

        let settings = Settings.shared
        /// Noon that day for someone who stays in the city (a flight from it that has not left yet).
        func groundDhuhr(_ code: String) throws -> Date {
            let events = FlightPrayerSolver.events(
                along: try plan(code, code == "LHR" ? "JFK" : "LHR", departs: start.addingTimeInterval(72 * 3600), hours: 8).path,
                rules: settings.flightPrayerRules(on: start).rules,
                from: start.addingTimeInterval(-6 * 3600), to: start.addingTimeInterval(18 * 3600))
            return try XCTUnwrap(events.first { $0.kind == .dhuhr }).time
        }
        XCTAssertGreaterThan(noon.time, try groundDhuhr("LHR"))
        XCTAssertLessThan(noon.time, try groundDhuhr("JFK"))
    }

    /// On ordinary routes every prayer of the journey appears once, in the order a day runs,
    /// whatever the direction and however many time zones are crossed (the date line included).
    func testEveryPrayerOfAJourneyComesOnceAndInOrder() throws {
        let order: [FlightPrayerKind] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
        let midnight = Date(timeIntervalSince1970: (day.timeIntervalSince1970 / 86_400).rounded(.down) * 86_400)
        let routes: [(String, String, Double, Double)] = [
            ("JFK", "LHR", 23, 7), ("LHR", "JFK", 10, 8), ("DXB", "CGK", 3, 8), ("JED", "CAI", 14, 2.2),
            ("LAX", "NRT", 19, 11.5), ("SYD", "LAX", 0, 13.5), ("IST", "GRU", 7, 13), ("DOH", "KUL", 20, 7.5),
        ]
        for (from, to, hour, length) in routes {
            let line = try timeline(try plan(from, to, departs: midnight.addingTimeInterval(hour * 3600), hours: length))
            XCTAssertFalse(line.events.isEmpty, "\(from)-\(to)")
            for (earlier, later) in zip(line.events, line.events.dropFirst()) {
                XCTAssertLessThan(earlier.time, later.time, "\(from)-\(to): \(earlier.kind) then \(later.kind)")
                let expected = order[(order.firstIndex(of: earlier.kind)! + 1) % order.count]
                XCTAssertEqual(later.kind, expected, "\(from)-\(to): \(later.kind) after \(earlier.kind)")
            }
            // Something comes in aboard a flight of two hours or more at these times of day.
            if length > 6 { XCTAssertFalse(line.inFlight.isEmpty, "\(from)-\(to)") }
        }
    }

    /// Over the Arctic the sun can sit on the horizon for hours, or stay under it, and an aircraft
    /// crossing meridians near the pole can see it move backward. Whatever the sky does, the
    /// journey's prayers only ever run forward, and no Dhuhr or Asr comes while the sun is down.
    func testPolarRoutesStillRunForward() throws {
        let order: [FlightPrayerKind] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
        let settings = Settings.shared
        // Midwinter, midsummer and the equinox; both directions over the top of the world.
        for stamp in [1_797_897_600.0, 1_782_000_000.0, day.timeIntervalSince1970] {
            let midnight = Date(timeIntervalSince1970: (stamp / 86_400).rounded(.down) * 86_400)
            for (from, to, hour, length) in [("LAX", "DXB", 0.0, 16.0), ("DXB", "LAX", 5.0, 16.5),
                                             ("JFK", "HND", 16.0, 14.0), ("DOH", "SEA", 4.0, 15.0)] {
                let plan = try plan(from, to, departs: midnight.addingTimeInterval(hour * 3600), hours: length)
                let rules = settings.flightPrayerRules(on: plan.takeoff).rules
                let events = FlightPrayerSolver.events(along: plan.path, rules: rules,
                                                       from: plan.takeoff.addingTimeInterval(-18 * 3600),
                                                       to: plan.landing.addingTimeInterval(18 * 3600))
                XCTAssertFalse(events.isEmpty, "\(from)-\(to)")
                for (earlier, later) in zip(events, events.dropFirst()) {
                    XCTAssertLessThan(earlier.instant, later.instant, "\(from)-\(to)")
                    let steps = (order.firstIndex(of: later.kind)! - order.firstIndex(of: earlier.kind)! + 6) % 6
                    XCTAssert((1...3).contains(steps), "\(from)-\(to) at \(stamp): \(later.kind) after \(earlier.kind)")
                }
                for event in events where event.kind == .dhuhr || event.kind == .asr {
                    let state = try XCTUnwrap(plan.path.state(at: event.instant))
                    let sun = SolarPosition(date: event.instant)
                        .altitude(latitude: state.coordinate.latitude, longitude: state.coordinate.longitude)
                    XCTAssertGreaterThan(sun + FlightPrayerRules.horizonAngle + FlightPrayerRules.horizonDip(altitude: state.altitude),
                                         -0.01, "\(from)-\(to): \(event.kind) with the sun down")
                }
            }
        }
    }

    // MARK: - The route

    func testTheRouteLeavesTheOriginAndReachesTheDestination() throws {
        let plan = try plan("JFK", "LHR", departs: day, hours: 7)
        let path = plan.path
        XCTAssertEqual(plan.takeoff, day.addingTimeInterval(15 * 60), "wheels up after the taxi out")
        XCTAssertEqual(plan.landing, day.addingTimeInterval(7 * 3600 - 8 * 60), "wheels down before the taxi in")

        let start = try XCTUnwrap(path.state(at: plan.takeoff))
        XCTAssertEqual(start.coordinate.latitude, plan.origin!.latitude, accuracy: 0.001)
        XCTAssertEqual(start.altitude, 0, accuracy: 1)
        let end = try XCTUnwrap(path.state(at: plan.landing))
        XCTAssertEqual(end.coordinate.longitude, plan.destination!.longitude, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(path.state(at: day)).phase, .beforeTakeoff)
        XCTAssertEqual(try XCTUnwrap(path.state(at: plan.landing.addingTimeInterval(60))).phase, .afterLanding)

        // Midway: on the great circle (the two parts add up to the whole), at cruise, heading east.
        let middle = try XCTUnwrap(path.state(at: plan.takeoff.addingTimeInterval(plan.landing.timeIntervalSince(plan.takeoff) / 2)))
        let whole = FlightGeometry.distance(from: plan.origin!.coordinate, to: plan.destination!.coordinate)
        let parts = FlightGeometry.distance(from: plan.origin!.coordinate, to: middle.coordinate)
            + FlightGeometry.distance(from: middle.coordinate, to: plan.destination!.coordinate)
        XCTAssertEqual(parts, whole, accuracy: 1_000)
        XCTAssertEqual(whole, 5_540_000, accuracy: 30_000, "JFK to LHR is about 5,540 km")
        XCTAssertEqual(middle.altitude, 11_000, accuracy: 1)
        XCTAssert((40...110).contains(try XCTUnwrap(middle.course)), "course \(String(describing: middle.course))")
        // The North Atlantic track runs well north of both cities.
        XCTAssertGreaterThan(middle.coordinate.latitude, 51)

        var last = -1.0
        for minute in stride(from: 0.0, through: 7 * 60, by: 10) {
            let covered = path.progress(at: day.addingTimeInterval(minute * 60)).covered
            XCTAssertGreaterThanOrEqual(covered, last)
            last = covered
        }
        XCTAssertEqual(last, whole, accuracy: 1_000)
    }

    func testAHoldAtTheGateSlidesTheWholeFlight() throws {
        var plan = try plan("JFK", "LHR", departs: day, hours: 7)
        let length = plan.landing.timeIntervalSince(plan.takeoff)
        plan.holdUntil = day.addingTimeInterval(75 * 60)
        XCTAssertEqual(plan.takeoff, day.addingTimeInterval(75 * 60))
        XCTAssertEqual(plan.landing.timeIntervalSince(plan.takeoff), length, accuracy: 1, "the same flight, an hour later")
    }

    // MARK: - Which ground times a flight replaces

    func testGroundTimesGiveWayInsideTheFlightAndReturnAfterIt() throws {
        let line = try timeline(try plan("JFK", "LHR", departs: day, hours: 7))
        XCTAssertTrue(line.keepsOriginPrayer(named: "Dhuhr", at: line.takeoff.addingTimeInterval(-3 * 3600)))
        XCTAssertFalse(line.keepsOriginPrayer(named: "Asr", at: line.takeoff.addingTimeInterval(3 * 3600)))
        XCTAssertFalse(line.keepsOriginPrayer(named: "Isha", at: line.landing.addingTimeInterval(3 * 3600)),
                       "after landing the destination's list speaks")
        XCTAssertFalse(line.keepsDestinationPrayer(named: "Asr", at: line.landing.addingTimeInterval(-3 * 3600)))
        XCTAssertTrue(line.keepsDestinationPrayer(named: "Isha", at: line.landing.addingTimeInterval(3 * 3600)))

        // At the seam each of the journey's prayers has exactly one owner.
        for event in line.events where abs(event.time.timeIntervalSince(line.takeoff)) < 40 * 60 {
            let origin = line.keepsOriginPrayer(named: event.kind.name, at: event.time)
            XCTAssertEqual(origin, event.phase == .beforeTakeoff, "\(event.kind) at takeoff")
        }
        for event in line.events where abs(event.time.timeIntervalSince(line.landing)) < 40 * 60 {
            let destination = line.keepsDestinationPrayer(named: event.kind.name, at: event.time)
            XCTAssertEqual(destination, event.phase == .afterLanding, "\(event.kind) at landing")
        }
    }

    func testAPrayerWhoseTimeOutlastsTheFlightCanWaitForTheGround() throws {
        // Jeddah to Cairo, two hours and a quarter, leaving a little after noon in Jeddah.
        let midnight = Date(timeIntervalSince1970: (day.timeIntervalSince1970 / 86_400).rounded(.down) * 86_400)
        let line = try timeline(try plan("JED", "CAI", departs: midnight.addingTimeInterval(9 * 3600 + 40 * 60), hours: 2.25))
        for event in line.inFlight where event.kind != .sunrise {
            let end = try XCTUnwrap(line.windowEnd(for: event), "\(event.kind)")
            XCTAssertGreaterThan(end, event.time)
            XCTAssertEqual(line.canWaitForLanding(event), end > line.landing.addingTimeInterval(30 * 60))
        }
        // Dhuhr comes in at Jeddah before this flight or aboard it; either way its time, joined
        // with Asr's, runs to sunset, hours after landing.
        if let dhuhr = line.inFlight.first(where: { $0.kind == .dhuhr }) {
            XCTAssertEqual(line.canWaitForLanding(dhuhr), true)
        }
    }

    // MARK: - The mode

    func testOnlyAnAircraftMovesLikeThis() {
        XCTAssertTrue(FlightMode.isAirborne(speed: 250, altitude: 11_000), "an airliner in cruise")
        XCTAssertTrue(FlightMode.isAirborne(speed: 135, altitude: nil), "faster than any train, height unknown")
        XCTAssertTrue(FlightMode.isAirborne(speed: 90, altitude: 5_000), "a turboprop, or a climb")
        XCTAssertFalse(FlightMode.isAirborne(speed: 90, altitude: 40), "a high-speed train")
        XCTAssertFalse(FlightMode.isAirborne(speed: 40, altitude: 3_600), "a road over a mountain pass")
        XCTAssertFalse(FlightMode.isAirborne(speed: 0, altitude: 2_300), "standing in a high city")
    }

    func testAFixInTheAirRaisesTheQuestionOnceAndNotNowIsRespected() {
        let flight = FlightMode.shared
        let fix = FlightFix(latitude: 50, longitude: -30, altitude: 11_200, speed: 245, course: 80, time: Date())
        flight.note(fix: fix)
        XCTAssertEqual(flight.detection?.fix, fix)
        XCTAssertNil(flight.plan, "asking is not turning on")

        flight.declineDetection()
        XCTAssertNil(flight.detection)
        flight.note(fix: fix)
        XCTAssertNil(flight.detection, "not now means not on the next fix either")

        Settings.shared.flightAskSnoozedUntil = 0
        Settings.shared.flightAutomatic = false
        flight.note(fix: fix)
        XCTAssertNil(flight.detection, "the switch is off")
    }

    func testSayingYesFollowsTheCourseBeingFlown() throws {
        let flight = FlightMode.shared
        // With no last place to start from, the route begins at the fix.
        Settings.shared.currentLocation = nil
        let fix = FlightFix(latitude: 50, longitude: -30, altitude: 11_200, speed: 245, course: 90, time: Date())
        flight.note(fix: fix)
        flight.beginFromDetection()
        let plan = try XCTUnwrap(flight.plan)
        XCTAssertTrue(plan.detected)
        XCTAssertNil(plan.destination)
        XCTAssertEqual(flight.status, .inFlight)

        let line = try XCTUnwrap(flight.currentTimeline())
        let hourOn = try XCTUnwrap(plan.path.state(at: fix.time.addingTimeInterval(3600)))
        XCTAssertEqual(hourOn.phase, .inFlight)
        // An hour at 245 m/s is 882 km, east from 30 W.
        XCTAssertEqual(FlightGeometry.distance(from: fix.coordinate, to: hourOn.coordinate), 882_000, accuracy: 5_000)
        XCTAssertGreaterThan(hourOn.coordinate.longitude, fix.longitude)
        XCTAssertTrue(line.events.allSatisfy { $0.phase == .inFlight })
        XCTAssertTrue(line.keepsOriginPrayer(named: "Isha", at: line.landing.addingTimeInterval(3600)),
                      "with no destination, nothing else speaks for the hours after the horizon")
    }

    func testAFixInTheAirReanchorsATypedFlight() throws {
        let flight = FlightMode.shared
        let departs = Date().addingTimeInterval(-2 * 3600)
        flight.replacePlanForTesting(try plan("JFK", "LHR", departs: departs, hours: 7))
        // Two hours out, somewhere south of the track the timetable assumed.
        let fix = FlightFix(latitude: 44, longitude: -50, altitude: 10_900, speed: 260, course: 70, time: Date())
        flight.note(fix: fix)
        let plan = try XCTUnwrap(flight.plan)
        XCTAssertEqual(plan.anchor, fix)

        let now = try XCTUnwrap(plan.path.state(at: fix.time.addingTimeInterval(1)))
        XCTAssertEqual(now.coordinate.latitude, 44, accuracy: 0.05)
        XCTAssertEqual(now.coordinate.longitude, -50, accuracy: 0.05)
        // The landing follows from the distance left at the speed measured.
        let left = FlightGeometry.distance(from: fix.coordinate, to: plan.destination!.coordinate)
        XCTAssertEqual(plan.landing.timeIntervalSince(fix.time), left / 260 + 8 * 60, accuracy: 1)
        let line = try XCTUnwrap(flight.currentTimeline())
        if let soon = line.inFlight.first(where: { $0.instant > fix.time && $0.instant < fix.time.addingTimeInterval(3600) }) {
            XCTAssertFalse(line.isEstimate(soon), "a prayer within two hours of a fix rests on the fix")
        }
    }

    func testAFixOnTheGroundAwayFromTheOriginEndsTheFlight() throws {
        let flight = FlightMode.shared
        var typed = try plan("JFK", "LHR", departs: Date().addingTimeInterval(-7 * 3600), hours: 7.2)
        typed.anchor = FlightFix(latitude: 52, longitude: -10, altitude: 9_000, speed: 240, course: 100,
                                 time: Date().addingTimeInterval(-3600))
        flight.replacePlanForTesting(typed)
        XCTAssertEqual(flight.status, .inFlight)

        let heathrow = try place("LHR")
        flight.note(fix: FlightFix(latitude: heathrow.latitude, longitude: heathrow.longitude, altitude: 25,
                                   speed: 8, course: nil, time: Date()))
        XCTAssertNil(flight.plan)
        XCTAssertEqual(flight.status, .off)
        XCTAssertEqual(flight.arrival?.place?.code, "LHR")
        XCTAssertEqual(flight.arrival?.adopted, false, "the fix says where the phone is: nothing is taken on trust")
    }

    /// A flight set up and never taken. When its landing time passes the phone is still at home and
    /// says so, and the location must not be moved to the destination.
    func testAFlightNeverTakenLeavesThePhoneWhereItIs() throws {
        let flight = FlightMode.shared
        let settings = Settings.shared
        let home = Location(city: "Irvine, CA", latitude: 33.6846, longitude: -117.8265)
        settings.currentLocation = home
        flight.replacePlanForTesting(try plan("LAX", "LHR", departs: Date().addingTimeInterval(-12 * 3600), hours: 10.5))
        // The phone, sitting at home, reports in (a fix that moves nothing, so nothing is committed).
        flight.note(fix: FlightFix(latitude: home.latitude, longitude: home.longitude, altitude: 20,
                                   speed: 0, course: nil, time: Date()))
        XCTAssertNil(flight.plan, "on the ground far from the origin airport, hours after takeoff: the flight is over")
        XCTAssertNil(flight.arrival?.place, "not at the destination")
        XCTAssertEqual(settings.currentLocation?.city, "Irvine, CA")

        // The same when it is the clock that ends the flight: the phone last spoke from a freeway
        // in California (too fast to be standing at a gate, far too slow to be an aircraft).
        flight.replacePlanForTesting(try plan("JFK", "LHR", departs: Date().addingTimeInterval(-12 * 3600), hours: 7))
        flight.note(fix: FlightFix(latitude: home.latitude, longitude: home.longitude, altitude: 20,
                                   speed: 31, course: 90, time: Date()))
        XCTAssertNotNil(flight.plan)
        flight.end(arrived: true)
        XCTAssertNil(flight.plan)
        XCTAssertEqual(flight.arrival?.adopted, false)
        XCTAssertNil(flight.arrival?.place)
        XCTAssertEqual(settings.currentLocation?.city, "Irvine, CA")

        // And a traveler who lives beside the departure airport and never left: six hours past the
        // printed takeoff the flight stops sliding and ends.
        flight.replacePlanForTesting(try plan("SNA", "LHR", departs: Date().addingTimeInterval(-7 * 3600), hours: 10.5))
        flight.note(fix: FlightFix(latitude: home.latitude, longitude: home.longitude, altitude: 20,
                                   speed: 0, course: nil, time: Date()))
        XCTAssertNil(flight.plan)
        XCTAssertEqual(settings.currentLocation?.city, "Irvine, CA")
    }

    func testStillAtTheGateAfterThePrintedTakeoffHoldsTheFlight() throws {
        let flight = FlightMode.shared
        flight.replacePlanForTesting(try plan("JFK", "LHR", departs: Date().addingTimeInterval(-40 * 60), hours: 7))
        let kennedy = try place("JFK")
        flight.note(fix: FlightFix(latitude: kennedy.latitude, longitude: kennedy.longitude, altitude: 4,
                                   speed: 3, course: nil, time: Date()))
        let plan = try XCTUnwrap(flight.plan, "a fix at the origin is not a landing")
        XCTAssertGreaterThan(plan.takeoff, Date())
        XCTAssertEqual(flight.status, .upcoming)
    }

    // MARK: - Nothing typed (Abu, 2026-11-26: "do we need both airports?")

    private let irvine = Location(city: "Irvine, CA", latitude: 33.6846, longitude: -117.8265)

    /// One tap: the flight starts from where the phone last was and waits. The ground's list
    /// stands until a fix in the air gives it a course to follow.
    func testTurningOnNeedsNothingTyped() throws {
        let flight = FlightMode.shared
        Settings.shared.currentLocation = irvine
        flight.turnOn()
        var plan = try XCTUnwrap(flight.plan)
        XCTAssertTrue(plan.isWaiting)
        XCTAssertEqual(flight.status, .waiting)
        XCTAssertEqual(plan.origin?.code, "SNA", "the airport beside where the phone last was")
        XCTAssertNil(flight.currentTimeline(), "nothing to follow yet: the ground's own times stand")

        // Forty minutes on, a fix in the climb out over the desert.
        let fix = FlightFix(latitude: 35.2, longitude: -114.3, altitude: 10_400, speed: 235, course: 62,
                            time: Date().addingTimeInterval(40 * 60))
        flight.note(fix: fix)
        plan = try XCTUnwrap(flight.plan)
        XCTAssertFalse(plan.isWaiting)
        XCTAssertEqual(plan.anchor, fix)
        XCTAssertEqual(plan.origin?.code, "SNA")
        XCTAssertEqual(plan.everAloft, true)
        XCTAssertLessThan(plan.takeoff, fix.time)
        XCTAssertGreaterThan(plan.takeoff, fix.time.addingTimeInterval(-60 * 60), "360 km at a climb's speed is under an hour")
        let line = try XCTUnwrap(flight.currentTimeline())
        XCTAssertEqual(flight.status(at: fix.time.addingTimeInterval(60)), .inFlight)
        XCTAssertFalse(line.inFlight.isEmpty && line.events.isEmpty)
        // The route passes through the fix and carries on along its course.
        let later = try XCTUnwrap(plan.path.state(at: fix.time.addingTimeInterval(1800)))
        XCTAssertGreaterThan(later.coordinate.longitude, fix.longitude)
    }

    /// The phone's last place is where a flight starts only if the plane could have come from
    /// there: a place it was still at too recently for the distance is dropped.
    func testAnOriginThePlaneCouldNotHaveComeFromIsDropped() throws {
        let now = Date()
        let fix = FlightFix(latitude: 50, longitude: -30, altitude: 11_000, speed: 250, course: 80, time: now)
        // "At Santa Ana ten minutes ago" and "over the Atlantic now" cannot both be this flight.
        var stale = FlightPlan(origin: try place("SNA"), destination: nil, departure: now, arrival: nil, anchor: nil,
                               holdUntil: nil, detected: true, originSeenAt: now.addingTimeInterval(-600))
        FlightMode.takeFirstFix(fix, into: &stale)
        XCTAssertNil(stale.origin)
        XCTAssertEqual(stale.takeoff.timeIntervalSince(fix.time), -60, accuracy: 1)

        // Seen there nine hours ago: that is this flight, and it left no earlier than it was seen.
        var real = FlightPlan(origin: try place("JFK"), destination: nil, departure: now, arrival: nil, anchor: nil,
                              holdUntil: nil, detected: true, originSeenAt: now.addingTimeInterval(-9 * 3600))
        FlightMode.takeFirstFix(fix, into: &real)
        XCTAssertEqual(real.origin?.code, "JFK")
        XCTAssertLessThan(real.takeoff, fix.time.addingTimeInterval(-2 * 3600))
        XCTAssertGreaterThanOrEqual(real.takeoff, now.addingTimeInterval(-9 * 3600))
        XCTAssertEqual(real.anchor, fix)
    }

    /// While it waits, the origin follows the phone on the ground (the drive to the airport), a
    /// day with no fix in the air ends it without a word, and a flight once followed ends at the
    /// first fix on the ground.
    func testAWaitingFlightFollowsThePhoneAndDoesNotWaitForever() throws {
        let flight = FlightMode.shared
        let settings = Settings.shared
        settings.currentLocation = irvine
        flight.turnOn()
        // An hour's drive north, standing at Los Angeles International.
        let lax = try place("LAX")
        flight.note(fix: FlightFix(latitude: lax.latitude, longitude: lax.longitude, altitude: 30, speed: 1,
                                   course: nil, time: Date().addingTimeInterval(3600)))
        XCTAssertEqual(flight.plan?.origin?.code, "LAX")
        XCTAssertEqual(flight.status, .waiting)

        flight.refresh(now: Date().addingTimeInterval(25 * 3600))
        XCTAssertNil(flight.plan, "a day with no fix in the air: not taken, or long over")
        XCTAssertEqual(settings.flightAskSnoozedUntil, 0, "nothing was answered, so nothing is snoozed")

        // Followed, then lost for longer than the course can be trusted, then the ground.
        settings.currentLocation = irvine
        flight.turnOn()
        let fix = FlightFix(latitude: 40, longitude: -100, altitude: 11_000, speed: 240, course: 70,
                            time: Date().addingTimeInterval(2 * 3600))
        flight.note(fix: fix)
        XCTAssertEqual(flight.plan?.everAloft, true)
        flight.refresh(now: fix.time.addingTimeInterval(FlightPlan.openEndedHorizon + 60))
        let lost = try XCTUnwrap(flight.plan, "the fix is too old to follow, but the flight is not over")
        XCTAssertTrue(lost.isWaiting)
        let kennedy = try place("JFK")
        flight.note(fix: FlightFix(latitude: kennedy.latitude, longitude: kennedy.longitude, altitude: 5, speed: 4,
                                   course: nil, time: fix.time.addingTimeInterval(8 * 3600)))
        XCTAssertNil(flight.plan, "it has flown, and this is the ground")
    }

    // MARK: - At the airport (Abu, 2026-11-26: "Send notification if assumed u are on plane")

    func testOnlyATerminalCountsAsBeingAtAnAirport() throws {
        let lax = try place("LAX")
        XCTAssertEqual(FlightMode.airport(around: lax.coordinate, accuracy: 65, home: nil)?.code, "LAX")
        XCTAssertNil(FlightMode.airport(around: lax.coordinate, accuracy: 3_000, home: nil), "a fix that coarse could be the motorway")
        XCTAssertNil(FlightMode.airport(around: lax.coordinate, accuracy: 65,
                                        home: FlightCoordinate(latitude: lax.latitude + 0.02, longitude: lax.longitude)),
                     "the traveler lives beside it")
        let fiveKilometresOff = FlightGeometry.destination(from: lax.coordinate, bearing: 0, distance: 5_000)
        XCTAssertNil(FlightMode.airport(around: fiveKilometresOff, accuracy: 65, home: nil))
        XCTAssertNil(FlightMode.airport(around: FlightCoordinate(latitude: irvine.latitude, longitude: irvine.longitude),
                                        accuracy: 20, home: nil), "a city, not an airport")
    }

    func testSettlingAtAnAirportAsksOnceAndYesStartsFromIt() throws {
        let flight = FlightMode.shared
        let settings = Settings.shared
        let savedHome = settings.homeLocation
        defer { settings.homeLocation = savedHome }
        settings.homeLocation = irvine
        let heathrow = try place("LHR")
        flight.noteArrival(at: heathrow.coordinate, accuracy: 50, inline: true)
        let asked = try XCTUnwrap(flight.detection)
        XCTAssertNil(asked.fix)
        XCTAssertEqual(asked.airport?.code, "LHR")
        XCTAssertNil(flight.plan, "asking is not turning on")

        flight.beginFromDetection()
        let plan = try XCTUnwrap(flight.plan)
        XCTAssertTrue(plan.isWaiting)
        XCTAssertEqual(plan.origin?.code, "LHR")
        XCTAssertNil(flight.detection)

        // A second settling in the same wait at the gate asks nothing more.
        flight.end(arrived: false)
        settings.flightAskSnoozedUntil = 0
        flight.noteArrival(at: heathrow.coordinate, accuracy: 50, inline: true)
        XCTAssertNil(flight.detection)
    }

    // MARK: - Where to pray it (How to Pray on a Plane)

    /// The guide's plan, in its order: on the ground before boarding, joined; on the ground after
    /// landing; on board only when the time would otherwise run out.
    func testTheBoardAdvisesWhatTheGuideSays() throws {
        let midnight = Date(timeIntervalSince1970: (day.timeIntervalSince1970 / 86_400).rounded(.down) * 86_400)
        func hour(_ hours: Double) -> Date { midnight.addingTimeInterval(hours * 3600) }

        // Jeddah to Kuala Lumpur, leaving mid-afternoon and flying into the night. Dhuhr came in
        // two hours before; Asr comes in on board and the sun sets on board.
        let east = try timeline(try plan("JED", "KUL", departs: hour(11.5), hours: 9))
        let dhuhrEast = try XCTUnwrap(nearest(.dhuhr, to: east.takeoff, in: east.events))
        XCTAssertEqual(dhuhrEast.phase, .beforeTakeoff)
        let asrEast = try XCTUnwrap(east.inFlight.first { $0.kind == .asr })
        guard case let .joinBeforeBoarding(with: partner, end: end)? = east.advice(for: asrEast) else {
            return XCTFail("Asr over the Indian Ocean: \(String(describing: east.advice(for: asrEast)))")
        }
        XCTAssertEqual(partner, .dhuhr)
        XCTAssertEqual(end, east.inFlight.first { $0.kind == .maghrib }?.time, "Asr's time ends at the sunset seen from the plane")
        let maghribEast = try XCTUnwrap(east.inFlight.first { $0.kind == .maghrib })
        guard case .onBoard? = east.advice(for: maghribEast) else {
            return XCTFail("Maghrib and Isha both end before a landing at four in the morning")
        }

        // Jeddah to Cairo, two hours and a quarter around noon: Dhuhr comes in on board and
        // Asr is hours after landing.
        let short = try timeline(try plan("JED", "CAI", departs: hour(9.1), hours: 2.25))
        let dhuhrShort = try XCTUnwrap(short.inFlight.first { $0.kind == .dhuhr })
        XCTAssertEqual(short.advice(for: dhuhrShort), .waitsForLanding)

        // Jeddah to New York, thirteen hours westward with the sun: Dhuhr and Asr both come in on
        // board, and the sun sets after landing.
        let west = try timeline(try plan("JED", "JFK", departs: hour(8.5), hours: 13))
        let dhuhrWest = try XCTUnwrap(west.inFlight.first { $0.kind == .dhuhr })
        let asrWest = try XCTUnwrap(west.inFlight.first { $0.kind == .asr })
        XCTAssertEqual(west.advice(for: dhuhrWest), .joinAfterLanding(with: .asr))
        XCTAssertEqual(west.advice(for: asrWest), .waitsForLanding)

        // Fajr is joined to nothing: aboard an overnight flight that lands after sunrise it is
        // prayed on board, and sunrise is when its time ends.
        let night = try timeline(try plan("JFK", "LHR", departs: hour(26.5), hours: 7))
        if let fajr = night.inFlight.first(where: { $0.kind == .fajr }),
           let sunrise = night.inFlight.first(where: { $0.kind == .sunrise && $0.time > fajr.time }) {
            XCTAssertEqual(night.advice(for: fajr), .onBoard(end: sunrise.time))
        }
        // And with no landing known, nothing is claimed about where a time ends.
        var open = FlightPlan(origin: nil, destination: nil, departure: hour(9).addingTimeInterval(-60), arrival: nil,
                              anchor: FlightFix(latitude: 30, longitude: 40, altitude: 11_000, speed: 240, course: 300, time: hour(9)),
                              holdUntil: nil, detected: true)
        open.everAloft = true
        let followed = try timeline(open)
        for event in followed.inFlight { XCTAssertNil(followed.advice(for: event)) }
    }

    // MARK: - The widgets

    /// In the air a widget lists the flight's own day, names the flight, and agrees with the
    /// board on the current and the next prayer; before takeoff it is the ground's.
    func testTheWidgetsFollowTheFlight() throws {
        let departs = Date().addingTimeInterval(-3 * 3600)
        let line = try timeline(try plan("JFK", "LHR", departs: departs, hours: 7))
        let settings = Settings.shared
        XCTAssertNil(line.widgetDay(at: line.takeoff.addingTimeInterval(-600), settings: settings), "the ground's own list stands")

        let now = Date()
        let aloft = try XCTUnwrap(line.widgetDay(at: now, settings: settings))
        XCTAssertEqual(aloft.city, "Flying to London")
        XCTAssertEqual(aloft.current?.time, line.current(at: now)?.time)
        XCTAssertEqual(aloft.next?.time, line.next(after: now)?.time)
        let names = aloft.prayers.map(\.nameTransliteration)
        XCTAssertEqual(Set(names).count, names.count, "each prayer once")
        XCTAssertLessThanOrEqual(names.count, 6)
        XCTAssertTrue(zip(aloft.prayers, aloft.prayers.dropFirst()).allSatisfy { $0.time < $1.time }, "in the order they come")

        let landed = try XCTUnwrap(line.widgetDay(at: line.landing.addingTimeInterval(3600), settings: settings))
        XCTAssertEqual(landed.city, "London")

        // The extension builds the same journey from the plan the app mirrored.
        let suite = "flight-widget-test"
        let store = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { store.removePersistentDomain(forName: suite) }
        FlightWidgetFeed.mirror(try JSONEncoder().encode(line.plan), in: store)
        let mirrored = try XCTUnwrap(FlightWidgetFeed.timeline(in: store, settings: settings))
        XCTAssertEqual(mirrored.events.map(\.time), line.events.map(\.time))
        FlightWidgetFeed.mirror(Data(), in: store)
        XCTAssertNil(FlightWidgetFeed.timeline(in: store, settings: settings))
    }

    /// The widgets fly only while the app does. Their copy of the plan lives in the App Group, which
    /// outlasts the app's own store, and one left there with no flight behind it kept the lock screen
    /// "In the air" on the flight's times (seen 2026-11-26): the app clears it when it comes forward.
    func testAWidgetCopyWithNoFlightBehindItIsCleared() throws {
        let flight = FlightMode.shared
        let store = try XCTUnwrap(Settings.shared.appGroupUserDefaults)
        let saved = store.data(forKey: FlightWidgetFeed.planKey)
        defer { FlightWidgetFeed.mirror(saved ?? Data(), in: store) }

        // A copy in the App Group, and no flight in the app (the helper installs the plan it is given).
        let line = try timeline(try plan("JFK", "LHR", departs: Date().addingTimeInterval(-3600), hours: 7))
        FlightWidgetFeed.mirror(try JSONEncoder().encode(line.plan), in: store)
        flight.replacePlanForTesting(nil)
        XCTAssertNotNil(FlightWidgetFeed.planData(in: store))
        XCTAssertNil(flight.plan)
        flight.refresh()
        XCTAssertNil(FlightWidgetFeed.planData(in: store), "no flight in the app, none in the widgets")

        // A flight that is on keeps its copy through the same call.
        Settings.shared.currentLocation = irvine
        flight.turnOn()
        XCTAssertNotNil(FlightWidgetFeed.planData(in: store))
        flight.refresh()
        XCTAssertNotNil(FlightWidgetFeed.planData(in: store))
    }

    // MARK: - The Qibla from a seat

    func testTheQiblaIsToldFromTheNose() {
        XCTAssertEqual(FlightFormat.qiblaPhrase(relative: 3), "Straight ahead, toward the nose")
        XCTAssertEqual(FlightFormat.qiblaPhrase(relative: 44), "45° to the right of the nose")
        XCTAssertEqual(FlightFormat.qiblaPhrase(relative: -30), "30° to the left of the nose")
        XCTAssertEqual(FlightFormat.qiblaPhrase(relative: -92), "To the left, toward the wing")
        XCTAssertEqual(FlightFormat.qiblaPhrase(relative: 135), "Behind you on the right, 135° from the nose")
        XCTAssertEqual(FlightFormat.qiblaPhrase(relative: -178), "Straight behind, toward the tail")
    }

    func testTheBearingToTheKaabaMatchesTheCompass() throws {
        // London's Qibla is about 119 degrees, Jakarta's about 295.
        XCTAssertEqual(FlightGeometry.bearing(from: try place("LHR").coordinate, to: FlightGeometry.kaaba), 119, accuracy: 1.5)
        XCTAssertEqual(FlightGeometry.bearing(from: try place("CGK").coordinate, to: FlightGeometry.kaaba), 295, accuracy: 1.5)
    }

    // MARK: - The airports

    func testTheAirportListIsWholeAndSearchable() throws {
        XCTAssertGreaterThan(Airports.all.count, 3_500)
        let jeddah = try XCTUnwrap(Airports.airport(code: "jed"))
        XCTAssertEqual(jeddah.timeZoneID, "Asia/Riyadh")
        XCTAssertNotNil(TimeZone(identifier: jeddah.timeZoneID))
        // Every zone in the file is one this system knows: a bad one would silently fall to the phone's.
        let unknown = Set(Airports.all.map(\.timeZoneID)).filter { TimeZone(identifier: $0) == nil }
        XCTAssertTrue(unknown.isEmpty, "\(unknown)")

        XCTAssertEqual(Airports.search("LHR").first?.code, "LHR")
        XCTAssertEqual(Airports.search("jeddah").first?.code, "JED")
        XCTAssertEqual(Airports.search("Sao Paulo").first?.city, "São Paulo")
        let tokyo = Airports.search("tokyo").map(\.code)
        XCTAssertTrue(tokyo.contains("HND") && tokyo.contains("NRT"), "\(tokyo)")
        XCTAssertTrue(Airports.search("   ").isEmpty)

        let kennedy = try place("JFK")
        XCTAssertEqual(Airports.nearest(to: kennedy.coordinate, within: 80_000)?.code, "JFK")
        XCTAssertNil(Airports.nearest(to: FlightCoordinate(latitude: 0, longitude: -30), within: 80_000), "mid-Atlantic")
    }

    /// The airports and their cities are named in every language the app is translated into, and
    /// a search does not tell apart the letters a keyboard writes differently.
    func testAirportsAreNamedInTheInterfacesLanguage() throws {
        XCTAssertTrue(Airports.localNames(language: "en").isEmpty, "English is the list itself")
        for language in ["ar", "ur", "id", "ms", "tr", "fr", "bn", "ru", "hi", "de", "es", "ml", "ta", "nl"] {
            let names = Airports.localNames(language: language)
            XCTAssertGreaterThan(names.count, 300, language)
            XCTAssertTrue(names.keys.allSatisfy { Airports.airport(code: $0) != nil }, "\(language): a code the list does not have")
            XCTAssertFalse(names.values.contains { ($0.name ?? "").contains("\u{2014}") || ($0.city ?? "").contains("\u{2014}") }, language)
        }
        let arabic = Airports.localNames(language: "ar")
        XCTAssertEqual(arabic["JED"]?.city, "جدة")
        XCTAssertEqual(arabic["LHR"]?.city, "لندن")
        XCTAssertEqual(Airports.localNames(language: "fr")["LHR"]?.city, "Londres")
        XCTAssertEqual(Airports.localNames(language: "ru")["CAI"]?.city, "Каир")
        XCTAssertEqual(Airports.localNames(language: "fr-CA")["LHR"]?.city, "Londres", "a regional variant reads its language's file")

        XCTAssertEqual(Airports.fold("جدّة"), Airports.fold("جده"))
        XCTAssertEqual(Airports.fold("إسطنبول"), Airports.fold("اسطنبول"))
        XCTAssertEqual(Airports.fold("کراچی"), Airports.fold("كراچي"), "an Urdu keyboard's kaf and yaa")
        XCTAssertEqual(Airports.fold("São Paulo"), "sao paulo")
    }
}
