#if os(iOS)
import Foundation
import CoreLocation

// Flight Mode, part 1 of 4: where the aircraft is.
//
// A prayer time is the moment the sun reaches an angle FOR AN OBSERVER. On the ground the observer
// stands still and a day's table can be computed once. In an aircraft the observer covers fifteen
// degrees of longitude an hour, so "Asr at the point below us now" is not when Asr will come: by
// then the plane is somewhere else. The times have to be found along the route (FlightPrayerSolver),
// and that needs the aircraft's place at every minute of the flight, which is this file:
//
//   FlightPlan   what is known about the flight: at the least where the phone last was, at the
//                most two airports, the two times on the ticket and a GPS fix in the air
//   FlightPath   the plan as a function of time: latitude, longitude, height, course
//
// Abu, 2026-11-25: "i want it to be accurate telling u when to pray each prayer ON the plane".
// Abu, 2026-11-26: "do we need both airports? ... shouldn't u be able to still tell? Without
// knowing where I start and where I end you could also base it off last known location for
// starting airport". So nothing has to be typed: a plan may hold only the place the phone last
// was (`isWaiting`), and the first fix in the air turns it into a route.

/// One end of a flight: an airport from the bundled list (Airports.swift), copied by value so a stored
/// plan does not depend on the list.
struct FlightPlace: Codable, Equatable {
    var code: String
    var name: String
    var city: String
    var country: String
    var latitude: Double
    var longitude: Double
    var timeZoneID: String

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }
    var coordinate: FlightCoordinate { FlightCoordinate(latitude: latitude, longitude: longitude) }
    /// The city as a sentence names it; the airport's own name when the list has no city for it.
    var spokenCity: String { city.isEmpty ? name : city }
    /// Whether this is an airport from the list, or only a place the phone was (no code).
    var isAirport: Bool { !code.isEmpty }

    /// A place that is not an airport: where the phone last was, under the name the app shows for it.
    static func place(named city: String, latitude: Double, longitude: Double, country: String) -> FlightPlace {
        FlightPlace(code: "", name: city, city: city, country: country, latitude: latitude, longitude: longitude,
                    timeZoneID: TimeZone.current.identifier)
    }
}

/// A GPS fix taken in the air. The newest one re-anchors the rest of the route: from here on the
/// aircraft is known to be HERE, not where the timetable put it.
struct FlightFix: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    /// Metres above sea level; nil when the fix carried no usable height.
    var altitude: Double?
    /// Metres per second over the ground.
    var speed: Double
    /// Degrees from true north the aircraft is moving along; nil when the fix carried none.
    var course: Double?
    var time: Date

    var coordinate: FlightCoordinate { FlightCoordinate(latitude: latitude, longitude: longitude) }
}

struct FlightPlan: Codable, Equatable {
    /// Nil for a flight Flight Mode noticed in the air: nobody typed where it left from.
    var origin: FlightPlace?
    /// Nil until the traveler says where the flight lands; the route then follows the course flown.
    var destination: FlightPlace?
    /// Leaving the gate, as a ticket prints it, or the moment Flight Mode came on in the air.
    var departure: Date
    /// Reaching the gate, as a ticket prints it. Nil with no destination.
    var arrival: Date?
    var anchor: FlightFix?
    /// Still on the ground at the origin after the printed takeoff (a GPS fix said so): the whole
    /// flight slides to start no earlier than this.
    var holdUntil: Date?
    /// Noticed from speed and height, as opposed to typed in before boarding.
    var detected: Bool = false
    /// When the phone was last known to be on the ground at the origin. Optional, like the two
    /// below, so a plan stored by the build before them still decodes.
    var originSeenAt: Date?
    /// A fix has shown this flight in the air at least once.
    var everAloft: Bool?
    /// Since when the plan has been waiting for a fix (`isWaiting`): turned on with nothing typed,
    /// or its last fix grew too old to follow.
    var waitingSince: Date?

    /// Flight Mode is on and nothing says where the aircraft is: no destination to fly a route to,
    /// and no fix to follow a course from. The ground's own times stand until a fix arrives.
    var isWaiting: Bool { destination == nil && anchor == nil }

    /// From the gate to the runway and back again. Ticket times are gate times, and at 14 km a
    /// minute a quarter of an hour of taxi is 200 km of route.
    static let taxiOut: TimeInterval = 15 * 60
    static let taxiIn: TimeInterval = 8 * 60
    /// How far ahead a flight with no destination is followed along its course.
    static let openEndedHorizon: TimeInterval = 6 * 60 * 60

    /// Wheels up.
    var takeoff: Date {
        let printed = detected ? departure : departure.addingTimeInterval(Self.taxiOut)
        return max(printed, holdUntil ?? .distantPast)
    }

    /// Wheels down. With a fix in cruise the arrival is worked out from the distance left and the
    /// speed over the ground, which already carries today's wind and any delay; otherwise it is the
    /// printed arrival less the taxi in, moved by whatever the takeoff moved.
    var landing: Date {
        if let anchor, let destination, anchor.speed >= 150 {
            let left = FlightGeometry.distance(from: anchor.coordinate, to: destination.coordinate)
            // The last stretch is flown slower than cruise: about eight minutes more than the
            // cruise speed alone would give.
            return anchor.time.addingTimeInterval(left / anchor.speed + 8 * 60)
        }
        guard let arrival else {
            return (anchor?.time ?? takeoff).addingTimeInterval(Self.openEndedHorizon)
        }
        let printedTakeoff = detected ? departure : departure.addingTimeInterval(Self.taxiOut)
        let slide = takeoff.timeIntervalSince(printedTakeoff)
        return max(arrival.addingTimeInterval(-Self.taxiIn + slide), takeoff.addingTimeInterval(10 * 60))
    }

    /// Whether the landing is known (a destination was given) or only a horizon.
    var hasDestination: Bool { destination != nil }

    var path: FlightPath { FlightPath(plan: self) }
}

struct FlightCoordinate: Equatable {
    var latitude: Double
    var longitude: Double
}

/// Great circles on a sphere. The Earth's flattening moves a route by a fifth of a degree at most,
/// under a minute of sun; the timetable is far coarser than that.
enum FlightGeometry {
    static let earthRadius = 6_371_000.0

    private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
    private static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }

    /// The angle between two points as seen from the Earth's centre, in radians.
    static func angle(from a: FlightCoordinate, to b: FlightCoordinate) -> Double {
        let lat1 = radians(a.latitude), lat2 = radians(b.latitude)
        let dLat = lat2 - lat1, dLon = radians(b.longitude - a.longitude)
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * asin(min(1, sqrt(h)))
    }

    static func distance(from a: FlightCoordinate, to b: FlightCoordinate) -> Double {
        angle(from: a, to: b) * earthRadius
    }

    /// The point a fraction of the way along the great circle from `a` to `b`.
    static func interpolate(from a: FlightCoordinate, to b: FlightCoordinate, fraction: Double) -> FlightCoordinate {
        let d = angle(from: a, to: b)
        guard d > 1e-9 else { return a }
        let f = min(max(fraction, 0), 1)
        let lat1 = radians(a.latitude), lon1 = radians(a.longitude)
        let lat2 = radians(b.latitude), lon2 = radians(b.longitude)
        let wa = sin((1 - f) * d) / sin(d), wb = sin(f * d) / sin(d)
        let x = wa * cos(lat1) * cos(lon1) + wb * cos(lat2) * cos(lon2)
        let y = wa * cos(lat1) * sin(lon1) + wb * cos(lat2) * sin(lon2)
        let z = wa * sin(lat1) + wb * sin(lat2)
        return FlightCoordinate(latitude: degrees(atan2(z, sqrt(x * x + y * y))), longitude: degrees(atan2(y, x)))
    }

    /// The compass bearing to set out on from `a` to reach `b` along the great circle, 0..<360.
    static func bearing(from a: FlightCoordinate, to b: FlightCoordinate) -> Double {
        let lat1 = radians(a.latitude), lat2 = radians(b.latitude)
        let dLon = radians(b.longitude - a.longitude)
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = degrees(atan2(y, x))
        return bearing < 0 ? bearing + 360 : bearing
    }

    /// The point reached by leaving `a` on `bearing` and covering `distance` metres.
    static func destination(from a: FlightCoordinate, bearing: Double, distance: Double) -> FlightCoordinate {
        let d = distance / earthRadius, brng = radians(bearing)
        let lat1 = radians(a.latitude), lon1 = radians(a.longitude)
        let lat2 = asin(sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(brng))
        let lon2 = lon1 + atan2(sin(brng) * sin(d) * cos(lat1), cos(d) - sin(lat1) * sin(lat2))
        var longitude = degrees(lon2)
        if longitude > 180 { longitude -= 360 }
        if longitude < -180 { longitude += 360 }
        return FlightCoordinate(latitude: degrees(lat2), longitude: longitude)
    }

    /// The Kaaba, the same point the Qibla compass uses (`QiblaView.kaabaCoordinate`).
    static let kaaba = FlightCoordinate(latitude: 21.4225241, longitude: 39.8261818)
}

/// Where the aircraft is at an instant, and which part of the journey that instant falls in.
struct FlightState: Equatable {
    enum Phase: Equatable { case beforeTakeoff, inFlight, afterLanding }
    var phase: Phase
    var coordinate: FlightCoordinate
    /// Metres above the ground the sun's horizon is measured from: 0 on the ground.
    var altitude: Double
    /// Degrees from true north the aircraft is moving along; nil on the ground.
    var course: Double?
}

/// A `FlightPlan` as a function of time.
///
/// On the ground before takeoff the traveler is at the origin; after landing, at the destination.
/// Between the two the aircraft follows the great circle, in one leg (origin to destination) or, once
/// a GPS fix has re-anchored it, in two (origin to the fix, the fix to the destination). The speed is
/// taken as steady along a leg, eased at the two ends where an aircraft climbs and descends slower
/// than it cruises.
struct FlightPath {
    let takeoff: Date
    let landing: Date
    let cruiseAltitude: Double
    private let legs: [Leg]
    private let origin: FlightCoordinate?
    private let destination: FlightCoordinate?

    private struct Leg {
        let from: FlightCoordinate
        let to: FlightCoordinate
        let start: Date
        let end: Date
        /// Seconds at the leg's start and end flown at reduced speed (climb, descent).
        let easeIn: TimeInterval
        let easeOut: TimeInterval
    }

    /// Climb and descent, for the height and for the slower ground covered meanwhile.
    static let climbTime: TimeInterval = 20 * 60
    static let descentTime: TimeInterval = 25 * 60
    /// The height an airliner cruises at when no fix says otherwise: 36,000 ft.
    static let typicalCruiseAltitude = 11_000.0

    init(plan: FlightPlan) {
        let takeoff = plan.takeoff
        let landing = plan.landing
        self.takeoff = takeoff
        self.landing = landing
        self.origin = plan.origin?.coordinate
        self.destination = plan.destination?.coordinate

        let duration = max(landing.timeIntervalSince(takeoff), 60)
        if let altitude = plan.anchor?.altitude, altitude > 6_000 {
            cruiseAltitude = altitude
        } else {
            // A hop of under an hour and a half never reaches a long flight's height.
            cruiseAltitude = max(3_000, min(1, duration / (90 * 60)) * Self.typicalCruiseAltitude)
        }

        var legs: [Leg] = []
        if let anchor = plan.anchor, anchor.time > takeoff, anchor.time < landing {
            if let origin = plan.origin {
                legs.append(Leg(from: origin.coordinate, to: anchor.coordinate, start: takeoff, end: anchor.time,
                                easeIn: Self.climbTime, easeOut: 0))
            }
            let end: FlightCoordinate
            if let destination = plan.destination {
                end = destination.coordinate
            } else {
                // No destination: the course being flown, held. An aircraft on a great circle keeps
                // the circle, not the compass bearing, and this follows the circle the bearing starts.
                let speed = max(anchor.speed, 180)
                end = FlightGeometry.destination(from: anchor.coordinate, bearing: anchor.course ?? 0,
                                                 distance: speed * landing.timeIntervalSince(anchor.time))
            }
            legs.append(Leg(from: anchor.coordinate, to: end, start: anchor.time, end: landing,
                            easeIn: 0, easeOut: plan.destination == nil ? 0 : Self.descentTime))
        } else if let origin = plan.origin, let destination = plan.destination {
            legs.append(Leg(from: origin.coordinate, to: destination.coordinate, start: takeoff, end: landing,
                            easeIn: Self.climbTime, easeOut: Self.descentTime))
        }
        self.legs = legs
    }

    /// Whether the route can be followed at all (two ends, or a fix to start from).
    var isUsable: Bool { !legs.isEmpty }

    func state(at time: Date) -> FlightState? {
        guard let first = legs.first, let last = legs.last else { return nil }
        if time < takeoff {
            return FlightState(phase: .beforeTakeoff, coordinate: origin ?? first.from, altitude: 0, course: nil)
        }
        if time > landing {
            return FlightState(phase: .afterLanding, coordinate: destination ?? last.to, altitude: 0, course: nil)
        }
        let leg = legs.first { time <= $0.end } ?? last
        let fraction = Self.fraction(of: leg, at: time)
        let here = FlightGeometry.interpolate(from: leg.from, to: leg.to, fraction: fraction)
        // The course is the direction of the next small step along the leg (at the very end, of the last).
        let ahead = FlightGeometry.interpolate(from: leg.from, to: leg.to, fraction: min(1, fraction + 0.002))
        let behind = FlightGeometry.interpolate(from: leg.from, to: leg.to, fraction: max(0, fraction - 0.002))
        let course = fraction < 0.998
            ? FlightGeometry.bearing(from: here, to: ahead)
            : FlightGeometry.bearing(from: behind, to: here)
        return FlightState(phase: .inFlight, coordinate: here, altitude: altitude(at: time), course: course)
    }

    /// Height above the ground: a steady climb to the cruise, the cruise, a steady descent.
    func altitude(at time: Date) -> Double {
        guard time > takeoff, time < landing else { return 0 }
        let up = time.timeIntervalSince(takeoff) / Self.climbTime
        let down = landing.timeIntervalSince(time) / Self.descentTime
        return cruiseAltitude * max(0, min(1, up, down))
    }

    /// Metres of route in all, and how far along it the aircraft is at `time`.
    func progress(at time: Date) -> (covered: Double, total: Double) {
        var covered = 0.0, total = 0.0
        for leg in legs {
            let length = FlightGeometry.distance(from: leg.from, to: leg.to)
            total += length
            if time >= leg.end {
                covered += length
            } else if time > leg.start {
                covered += length * Self.fraction(of: leg, at: time)
            }
        }
        return (covered, total)
    }

    /// The fraction of a leg's DISTANCE covered at `time`. Speed rises from half the cruise to the
    /// cruise over `easeIn`, and falls back to half over `easeOut`: the area under that curve.
    private static func fraction(of leg: Leg, at time: Date) -> Double {
        let duration = leg.end.timeIntervalSince(leg.start)
        guard duration > 0 else { return 1 }
        let elapsed = min(max(time.timeIntervalSince(leg.start), 0), duration)
        // Short leg: the two ramps cannot both fit, so scale them down together.
        let scale = min(1, duration / max(leg.easeIn + leg.easeOut, 1))
        let easeIn = leg.easeIn * scale, easeOut = leg.easeOut * scale

        func covered(upTo t: TimeInterval) -> Double {
            var area = 0.0
            // Climb: speed 0.5 -> 1 over easeIn.
            if easeIn > 0 {
                let x = min(t, easeIn)
                area += 0.5 * x + 0.25 * x * x / easeIn
            }
            // Cruise at 1.
            let cruiseEnd = duration - easeOut
            if t > easeIn { area += min(t, cruiseEnd) - easeIn }
            // Descent: speed 1 -> 0.5 over easeOut.
            if easeOut > 0, t > cruiseEnd {
                let x = t - cruiseEnd
                area += x - 0.25 * x * x / easeOut
            }
            return area
        }
        let whole = covered(upTo: duration)
        return whole > 0 ? covered(upTo: elapsed) / whole : 1
    }
}
#endif
