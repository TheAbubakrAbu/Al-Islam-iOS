#if os(iOS)
import Foundation
import Adhan

// Flight Mode, part 2 of 4: when each prayer comes in for someone on that route.
//
// The ground engine (`PrayerTimes`) holds the place still and solves for the time. Here the place
// moves, so the sun's height is evaluated minute by minute along the route (`SolarPosition`, the
// same solar formulas) and each prayer is the instant its angle is crossed:
//
//   Fajr      the sun climbs through the dawn angle           (morning side)
//   Sunrise   the sun's upper edge clears the horizon         (morning side)
//   Dhuhr     the sun crosses the meridian overhead
//   Asr       the sun sinks to the shadow-length height       (afternoon side)
//   Maghrib   the sun's upper edge goes under the horizon     (afternoon side)
//   Isha      the sun sinks through the dusk angle            (afternoon side)
//
// Two things are true in the air that are not true on the ground:
//
// 1. THE HORIZON IS LOWER. From 11 km up the horizon lies about 3.6 degrees below eye level, so the
//    sun is still in sight a quarter of an hour after it has set for the ground underneath. The
//    passenger goes by the sun he can see (the scholars' ruling on breaking the fast in an
//    aircraft), so every horizon-referenced angle is lowered by that dip. The dawn and dusk
//    angles are lowered with it: the light on the horizon the passenger looks at is the light an
//    observer on the ground sees at the point where that line of sight touches the Earth.
// 2. THE DAY IS NOT 24 HOURS. Flying east the prayers come closer together, flying west further
//    apart, and a fast westbound aircraft in high latitudes can hold the sun still or bring it
//    back up after it has set. A prayer is taken at the FIRST time its sign appears: what came
//    in has come in, and the sun returning does not undo it.

enum FlightPrayerKind: String, CaseIterable, Codable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    /// The prayer's canonical name (`Prayer.nameTransliteration`), which notification preferences,
    /// the tracker and the custom names all key on.
    var name: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Shurooq"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }

    /// Whether a ground list's row is this prayer: Friday's Jumuah stands where Dhuhr does, and
    /// Traveling Mode's pairs sit at their first prayer's time.
    func matches(groundName: String) -> Bool {
        switch self {
        case .dhuhr: return ["Dhuhr", "Jumuah", "Dhuhr/Asr"].contains(groundName)
        case .maghrib: return ["Maghrib", "Maghrib/Isha"].contains(groundName)
        default: return groundName == name
        }
    }

    /// Sunrise ends a time (Fajr's); every other one begins a prayer.
    var endsATime: Bool { self == .sunrise }
}

/// The method a flight's prayers are worked out by: the traveler's own calculation settings.
struct FlightPrayerRules {
    var fajrAngle: Double
    var ishaAngle: Double
    /// Seconds after Maghrib, for a method that sets Isha by the clock (Umm al-Qura); 0 = by angle.
    var ishaInterval: TimeInterval = 0
    /// A method that puts Maghrib a few degrees after sunset; nil = at sunset.
    var maghribAngle: Double?
    /// 1, or 2 for the Hanafi Asr.
    var asrShadow: Double = 1
    /// Seconds added to each prayer: what the method's publisher adds, plus the manual offsets.
    var adjustments: [FlightPrayerKind: TimeInterval] = [:]
    /// The share of the night Fajr may come before sunrise, and Isha after sunset, at a latitude:
    /// the high-latitude rule, applied to the night as the passenger lives it.
    var nightPortions: (_ latitude: Double) -> (fajr: Double, isha: Double) = { _ in (0.5, 0.5) }

    /// The sun's upper edge on the horizon with standard refraction, the ground engine's own value.
    static let horizonAngle = 50.0 / 60.0

    /// How far below eye level the horizon lies from `altitude` metres up, in degrees, refraction
    /// included: the standard correction for sunrise and sunset at elevation.
    static func horizonDip(altitude: Double) -> Double {
        altitude > 0 ? 2.076 * altitude.squareRoot() / 60 : 0
    }
}

struct FlightPrayerEvent: Identifiable, Equatable {
    let kind: FlightPrayerKind
    /// The instant the sun reaches the angle.
    let instant: Date
    /// The minute the prayer is shown and announced at: the instant with the adjustments, rounded
    /// to the safe side (a start up, sunrise down), as on the ground. On the ground it is then
    /// set to that place's own table (`FlightMode.matchedToGroundTables`).
    var time: Date
    let phase: FlightState.Phase
    let coordinate: FlightCoordinate
    /// Metres up at that moment.
    let altitude: Double
    /// Set from the night's length (the high-latitude rule), not from an angle the sun reached.
    var fromNightPortion = false
    /// Maghrib only: the sun comes back into view after this sunset (a climb just after sunset, a
    /// fast westbound leg) and sets for good at this time.
    var sunReturnsUntil: Date?

    var id: String { "\(kind.rawValue)-\(Int(instant.timeIntervalSince1970))" }
}

enum FlightPrayerSolver {
    /// One evaluation of the sky from the aircraft.
    private struct Sample {
        let time: Date
        let state: FlightState
        /// The sun's altitude, degrees.
        let sun: Double
        /// The local hour angle, degrees, -180...180.
        let hourAngle: Double
        let dip: Double
        /// The altitude at which Asr begins here.
        let asrAltitude: Double
    }

    private enum Metric: CaseIterable { case horizon, dawn, dusk, lateMaghrib, asr, noon }

    /// Every prayer between `start` and `end` for a traveler following `path`: on the ground at the
    /// origin before takeoff, in the air, on the ground at the destination after landing.
    static func events(along path: FlightPath, rules: FlightPrayerRules, from start: Date, to end: Date) -> [FlightPrayerEvent] {
        guard path.isUsable, end > start else { return [] }

        func sample(_ time: Date) -> Sample? {
            guard let state = path.state(at: time) else { return nil }
            let solar = SolarPosition(date: time)
            return Sample(
                time: time, state: state,
                sun: solar.altitude(latitude: state.coordinate.latitude, longitude: state.coordinate.longitude),
                hourAngle: solar.hourAngle(longitude: state.coordinate.longitude),
                dip: FlightPrayerRules.horizonDip(altitude: state.altitude),
                asrAltitude: solar.asrAltitude(latitude: state.coordinate.latitude, shadowLength: rules.asrShadow))
        }

        func value(_ metric: Metric, _ s: Sample) -> Double? {
            switch metric {
            case .horizon: return s.sun + FlightPrayerRules.horizonAngle + s.dip
            case .dawn: return s.sun + rules.fajrAngle + s.dip
            case .dusk: return rules.ishaInterval > 0 ? nil : s.sun + rules.ishaAngle + s.dip
            case .lateMaghrib: return rules.maghribAngle.map { s.sun + $0 + s.dip }
            case .asr: return s.sun - s.asrAltitude
            case .noon: return s.hourAngle
            }
        }

        /// The instant between two samples at which `metric` passes zero, to the second.
        func crossing(_ metric: Metric, _ a: Sample, _ b: Sample) -> Sample? {
            guard var lowValue = value(metric, a), value(metric, b) != nil else { return nil }
            var low = a, high = b
            for _ in 0..<12 where high.time.timeIntervalSince(low.time) > 1 {
                let midTime = low.time.addingTimeInterval(high.time.timeIntervalSince(low.time) / 2)
                guard let mid = sample(midTime), let midValue = value(metric, mid) else { return nil }
                if (midValue >= 0) == (lowValue >= 0) {
                    low = mid
                    lowValue = midValue
                } else {
                    high = mid
                }
            }
            return high
        }

        struct Raw {
            let kind: FlightPrayerKind?
            let sample: Sample
            /// The sun coming back up on the afternoon side: not a prayer, but it marks a sunset undone.
            var sunReturned = false
        }
        var raws: [Raw] = []

        let step: TimeInterval = 60
        guard var previous = sample(start) else { return [] }
        var time = start.addingTimeInterval(step)
        while time <= end {
            guard let current = sample(time) else { break }
            for metric in Metric.allCases {
                guard let before = value(metric, previous), let after = value(metric, current),
                      (before < 0) != (after < 0) else { continue }
                // The hour angle jumps from +180 to -180 at the far side of the night: not a crossing.
                if metric == .noon, abs(after - before) > 90 { continue }
                guard let at = crossing(metric, previous, current) else { continue }
                let rising = after > before
                let afternoon = at.hourAngle > 0
                // Dhuhr and Asr are read from a sun that is up. Over the Arctic in winter the sun
                // crosses the meridian below the horizon, and an aircraft crossing meridians fast
                // can make it do so in the middle of the night: that is not a noon.
                let sunIsUp = at.sun + FlightPrayerRules.horizonAngle + at.dip > 0
                if metric == .noon || metric == .asr, !sunIsUp { continue }
                switch (metric, rising, afternoon) {
                case (.horizon, true, false): raws.append(Raw(kind: .sunrise, sample: at))
                case (.horizon, false, true):
                    // Sunset is always recorded (the night is measured from it); it is Maghrib
                    // itself unless the method sets Maghrib by an angle.
                    raws.append(Raw(kind: rules.maghribAngle == nil ? .maghrib : nil, sample: at))
                case (.horizon, true, true): raws.append(Raw(kind: nil, sample: at, sunReturned: true))
                case (.dawn, true, false): raws.append(Raw(kind: .fajr, sample: at))
                case (.dusk, false, true): raws.append(Raw(kind: .isha, sample: at))
                case (.lateMaghrib, false, true): raws.append(Raw(kind: .maghrib, sample: at))
                case (.asr, false, true): raws.append(Raw(kind: .asr, sample: at))
                case (.noon, true, _): raws.append(Raw(kind: .dhuhr, sample: at))
                default: break
                }
            }
            previous = current
            time = time.addingTimeInterval(step)
        }
        raws.sort { $0.sample.time < $1.sample.time }

        // The nights, each from a sunset to the sunrise after it: the high-latitude rule's measure.
        let sunsets = raws.filter { $0.kind == .maghrib && rules.maghribAngle == nil || ($0.kind == nil && !$0.sunReturned) }
        let sunrises = raws.filter { $0.kind == .sunrise }

        struct Draft {
            var kind: FlightPrayerKind
            var sample: Sample
            var instant: Date
            var fromNightPortion = false
            var sunReturnsUntil: Date?
        }
        var drafts: [Draft] = raws.compactMap { raw in
            raw.kind.map { Draft(kind: $0, sample: raw.sample, instant: raw.sample.time) }
        }

        for sunset in sunsets {
            guard let sunrise = sunrises.first(where: { $0.sample.time > sunset.sample.time }),
                  // The sunset this sunrise belongs to: a later sunset before it means the sun came
                  // back in between, and the night began at the later one.
                  !sunsets.contains(where: { $0.sample.time > sunset.sample.time && $0.sample.time < sunrise.sample.time })
            else { continue }
            let night = sunrise.sample.time.timeIntervalSince(sunset.sample.time)
            guard night > 0, night < 24 * 60 * 60 else { continue }
            let portions = rules.nightPortions(sunset.sample.state.coordinate.latitude)
            let within: (Draft) -> Bool = { $0.instant > sunset.sample.time && $0.instant < sunrise.sample.time }

            // Fajr no earlier than its share of the night before sunrise.
            let earliestFajr = sunrise.sample.time.addingTimeInterval(-portions.fajr * night)
            if let index = drafts.firstIndex(where: { $0.kind == .fajr && within($0) }) {
                if drafts[index].instant < earliestFajr, let at = sample(earliestFajr) {
                    drafts[index] = Draft(kind: .fajr, sample: at, instant: earliestFajr, fromNightPortion: true)
                }
            } else if let at = sample(earliestFajr) {
                drafts.append(Draft(kind: .fajr, sample: at, instant: earliestFajr, fromNightPortion: true))
            }

            // Isha: by the clock after Maghrib, or by its angle and no later than its share of the night.
            if rules.ishaInterval > 0 {
                let maghrib = drafts.last(where: { $0.kind == .maghrib && $0.instant <= sunrise.sample.time
                                                    && $0.instant >= sunset.sample.time })?.instant ?? sunset.sample.time
                let isha = maghrib.addingTimeInterval(rules.ishaInterval)
                if let at = sample(isha) { drafts.append(Draft(kind: .isha, sample: at, instant: isha)) }
            } else {
                let latestIsha = sunset.sample.time.addingTimeInterval(portions.isha * night)
                if let index = drafts.firstIndex(where: { $0.kind == .isha && within($0) }) {
                    if drafts[index].instant > latestIsha, let at = sample(latestIsha) {
                        drafts[index] = Draft(kind: .isha, sample: at, instant: latestIsha, fromNightPortion: true)
                    }
                } else if let at = sample(latestIsha) {
                    drafts.append(Draft(kind: .isha, sample: at, instant: latestIsha, fromNightPortion: true))
                }
            }
        }
        // A method that sets Isha by the clock still needs one after a sunset whose sunrise lies
        // past the window (the last night of the journey).
        if rules.ishaInterval > 0 {
            for maghrib in drafts where maghrib.kind == .maghrib {
                let isha = maghrib.instant.addingTimeInterval(rules.ishaInterval)
                guard isha <= end,
                      !drafts.contains(where: { $0.kind == .isha && abs($0.instant.timeIntervalSince(isha)) < 60 }),
                      let at = sample(isha) else { continue }
                drafts.append(Draft(kind: .isha, sample: at, instant: isha))
            }
        }
        drafts.sort { $0.instant < $1.instant }

        // First sign wins, and a day only runs forward. A prayer whose sign appears again before
        // the next prayer has come (the sun back in view after a sunset, the Asr height passed
        // twice) is the same prayer, and the first Maghrib remembers when the sun finally goes.
        // A sign that belongs EARLIER in the day than the last prayer (a second noon after Asr,
        // which an aircraft crossing the pole against the sun can be shown) is that same day's
        // prayer seen again, not a new one: what has come in has come in. Where the sun does not
        // rise or set at all for a stretch (polar night, polar day) nothing changes in the sky, so
        // no prayer is invented for it: the traveler is still in the time he was in.
        let order = FlightPrayerKind.allCases
        var kept: [Draft] = []
        for draft in drafts {
            guard let last = kept.last else {
                kept.append(draft)
                continue
            }
            let steps = (order.firstIndex(of: draft.kind)! - order.firstIndex(of: last.kind)! + order.count) % order.count
            if steps == 0 {
                if draft.kind == .maghrib { kept[kept.count - 1].sunReturnsUntil = draft.instant }
                continue
            }
            // Forward by up to half a day: further than that is a step backward.
            if steps > order.count / 2 { continue }
            kept.append(draft)
        }

        return kept.map { draft in
            let adjusted = draft.instant.addingTimeInterval(rules.adjustments[draft.kind] ?? 0)
            return FlightPrayerEvent(
                kind: draft.kind,
                instant: draft.instant,
                time: PrayerMinute.rounded(adjusted, endsATime: draft.kind.endsATime),
                phase: draft.sample.state.phase,
                coordinate: draft.sample.state.coordinate,
                altitude: draft.sample.state.altitude,
                fromNightPortion: draft.fromNightPortion,
                sunReturnsUntil: draft.sunReturnsUntil)
        }
    }
}
#endif
