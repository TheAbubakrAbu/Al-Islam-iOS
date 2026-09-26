import SwiftUI

/// The Moon's illuminated fraction and whether it is waxing, for a given moment.
///
/// This is the `getMoonIllumination` routine from Vladimir Agafonkin's SunCalc, which is itself the low-precision
/// lunar theory from Meeus' *Astronomical Algorithms*. It is accurate to well under a percent of illumination - 
/// far tighter than a moon you can draw at 40 points across. Geocentric, so it ignores the observer's position;
/// the phase is the same everywhere on Earth to within a rounding error.
struct MoonPhase: Equatable {
    /// 0 at new moon, 1 at full moon.
    let illumination: Double
    /// True from new moon through full moon (the lit limb is on the right in the northern hemisphere).
    let isWaxing: Bool

    /// The eight conventional phase names, chosen by illumination and direction.
    var name: String {
        switch illumination {
        case ..<0.04: return "New Moon"
        case ..<0.46: return isWaxing ? "Waxing Crescent" : "Waning Crescent"
        case ..<0.54: return isWaxing ? "First Quarter" : "Last Quarter"
        case ..<0.96: return isWaxing ? "Waxing Gibbous" : "Waning Gibbous"
        default:      return "Full Moon"
        }
    }

    var illuminationPercent: Int { Int((illumination * 100).rounded()) }

    /// One-entry memo. Callers pass hourly-quantized dates (see SkyView's `moonDate`), so the tab's
    /// per-second tick hits this instead of re-running the full ephemeris trig for an identical result.
    /// Main-thread only, like every caller.
    private static var lastComputed: (date: Date, phase: MoonPhase)?

    /// The phase for the hour `date` falls in. The Adhan tab's callers (the sky card, both Glance
    /// tiles) all go through this so they share the one memo entry above instead of evicting each
    /// other's; the moon does not change measurably within an hour.
    static func onCurrentHour(_ date: Date = Date()) -> MoonPhase {
        on(Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 3600).rounded(.down) * 3600))
    }

    static func on(_ date: Date) -> MoonPhase {
        if let cached = lastComputed, cached.date == date { return cached.phase }
        let phase = compute(date)
        lastComputed = (date, phase)
        return phase
    }

    private static func compute(_ date: Date) -> MoonPhase {
        let rad = Double.pi / 180
        // Obliquity of the ecliptic.
        let e = rad * 23.4397
        // Days since the J2000.0 epoch.
        let d = date.timeIntervalSince1970 / 86_400 - 0.5 + 2_440_588 - 2_451_545

        func rightAscension(_ l: Double, _ b: Double) -> Double {
            atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l))
        }
        func declination(_ l: Double, _ b: Double) -> Double {
            asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l))
        }

        // Sun: mean anomaly → ecliptic longitude → equatorial coordinates.
        let solarMeanAnomaly = rad * (357.5291 + 0.98560028 * d)
        let eclipticLongitude = solarMeanAnomaly
            + rad * 1.9148 * sin(solarMeanAnomaly)
            + rad * 0.02 * sin(2 * solarMeanAnomaly)
            + rad * 0.0003 * sin(3 * solarMeanAnomaly)
            + rad * 102.9372
            + .pi
        let sunRA = rightAscension(eclipticLongitude, 0)
        let sunDec = declination(eclipticLongitude, 0)

        // Moon: mean longitude, mean anomaly, mean distance from the ascending node.
        let meanLongitude = rad * (218.316 + 13.176396 * d)
        let meanAnomaly = rad * (134.963 + 13.064993 * d)
        let meanDistance = rad * (93.272 + 13.229350 * d)

        let moonLongitude = meanLongitude + rad * 6.289 * sin(meanAnomaly)
        let moonLatitude = rad * 5.128 * sin(meanDistance)
        let moonDistance = 385_001 - 20_905 * cos(meanAnomaly)   // km
        let moonRA = rightAscension(moonLongitude, moonLatitude)
        let moonDec = declination(moonLongitude, moonLatitude)

        let sunDistance = 149_598_000.0   // km

        // Geocentric elongation of the Moon from the Sun, then the Sun–Moon–Earth (phase) angle.
        let phi = acos(sin(sunDec) * sin(moonDec) + cos(sunDec) * cos(moonDec) * cos(sunRA - moonRA))
        let inc = atan2(sunDistance * sin(phi), moonDistance - sunDistance * cos(phi))
        // Position angle of the bright limb: its sign is what distinguishes waxing from waning.
        let limbAngle = atan2(
            cos(sunDec) * sin(sunRA - moonRA),
            sin(sunDec) * cos(moonDec) - cos(sunDec) * sin(moonDec) * cos(sunRA - moonRA)
        )

        return MoonPhase(illumination: (1 + cos(inc)) / 2, isWaxing: limbAngle < 0)
    }

    /// The Sun-Moon-Earth angle, 0 at full moon and pi at new: the 3D moon (`MoonViewer`) is lit from
    /// this angle, and `illumination` is `(1 + cos i) / 2`, so it is recovered exactly.
    var phaseAngle: Double { acos(min(max(2 * illumination - 1, -1), 1)) }

    /// The moon's cycle around `date`: the new moon that began it, and the next new and full moons.
    /// Found where `isWaxing` flips (it turns at full moon and at new), stepping six hours at a time
    /// and then halving the step down to under a second; the low-precision theory above puts the
    /// instant itself within an hour or two, which is more than a date needs. Nil only if the search
    /// finds no flip, which the 29.5-day month rules out.
    struct Cycle {
        let previousNewMoon: Date
        let nextNewMoon: Date
        let nextFullMoon: Date

        /// Days since the new moon, the moon's "age".
        func age(at date: Date) -> Double { date.timeIntervalSince(previousNewMoon) / 86_400 }
    }

    static func cycle(around date: Date) -> Cycle? {
        let waxing = compute(date).isWaxing
        // Forward: while waxing the next flip is the full moon, while waning the new moon.
        guard let first = nextFlip(from: date, step: 6 * 3600),
              let second = nextFlip(from: first.addingTimeInterval(3600), step: 6 * 3600) else { return nil }
        let nextFull = waxing ? first : second
        let nextNew = waxing ? second : first
        // Backward: while waxing the last flip was the new moon; while waning it was the full moon,
        // and the new moon came before that.
        guard let back = nextFlip(from: date, step: -6 * 3600) else { return nil }
        let previousNew = waxing ? back : nextFlip(from: back.addingTimeInterval(-3600), step: -6 * 3600)
        guard let previousNew else { return nil }
        return Cycle(previousNewMoon: previousNew, nextNewMoon: nextNew, nextFullMoon: nextFull)
    }

    /// The first instant after (or, with a negative `step`, before) `start` at which `isWaxing` is
    /// no longer what it is at `start`.
    private static func nextFlip(from start: Date, step: TimeInterval) -> Date? {
        let state = compute(start).isWaxing
        var near = start
        for _ in 0..<(32 * 86_400 / Int(abs(step))) {
            let far = near.addingTimeInterval(step)
            if compute(far).isWaxing != state {
                var inside = near, outside = far
                for _ in 0..<16 {
                    let mid = Date(timeIntervalSinceReferenceDate: (inside.timeIntervalSinceReferenceDate + outside.timeIntervalSinceReferenceDate) / 2)
                    if compute(mid).isWaxing == state { inside = mid } else { outside = mid }
                }
                return outside
            }
            near = far
        }
        return nil
    }
}

// MARK: - Drawing

/// The lit portion of the Moon's disc, as one closed path: the bright limb (a semicircle) joined to the
/// terminator (a half-ellipse). The terminator's width is `r·|1 − 2f|`, so it collapses to a straight line at
/// the quarters, bulges *into* the lit side for a crescent, and *away* for a gibbous. Building it as a single
/// path avoids CoreGraphics boolean ops, which need iOS 16 - this app still supports iOS 15.
struct MoonLitShape: Shape {
    var illumination: Double
    var isWaxing: Bool

    // Let the phase animate smoothly rather than snapping between days.
    var animatableData: Double {
        get { illumination }
        set { illumination = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // cos of the phase angle: +1 at new, 0 at the quarters, −1 at full.
        let terminator = 1 - 2 * illumination.clamped(to: 0...1)
        // The bright limb is on the right while waxing, on the left while waning.
        let side: CGFloat = isWaxing ? 1 : -1

        let steps = 64
        var path = Path()

        // Down the bright limb, north pole to south pole.
        path.move(to: CGPoint(x: center.x, y: center.y - r))
        for i in 1...steps {
            let theta = Double(i) / Double(steps) * .pi
            path.addLine(to: CGPoint(
                x: center.x + side * r * CGFloat(sin(theta)),
                y: center.y - r * CGFloat(cos(theta))
            ))
        }
        // Back up the terminator, south pole to north pole.
        for i in stride(from: steps - 1, through: 0, by: -1) {
            let theta = Double(i) / Double(steps) * .pi
            path.addLine(to: CGPoint(
                x: center.x + side * r * CGFloat(terminator) * CGFloat(sin(theta)),
                y: center.y - r * CGFloat(cos(theta))
            ))
        }
        path.closeSubpath()
        return path
    }
}

/// The Moon at its true phase for `date`, drawn flat to match the app rather than as a 3D globe.
struct MoonPhaseView: View {
    let date: Date
    var diameter: CGFloat = 44
    /// Draw a full disc whatever the real phase is. The moon that rides the solar arc uses this: there
    /// it is the night's MARKER, the counterpart of the sun on the day's half of the wave, and a
    /// crescent reads at a glance as a sliver of a thing rather than as the marker's position (Abu,
    /// 2026-09-16). The footer's glyph, which exists to show the phase and names it, leaves this off.
    var alwaysFull: Bool = false

    private var phase: MoonPhase { .on(date) }

    var body: some View {
        let phase = self.phase
        let illumination = alwaysFull ? 1 : phase.illumination
        ZStack {
            // The unlit disc: earthshine, not a hole in the sky.
            Circle()
                .fill(Color.white.opacity(0.10))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5))

            MoonLitShape(illumination: illumination, isWaxing: phase.isWaxing)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.98), Color(white: 0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                // A plain `.shadow`, not `.softShadow`: this file is shared with the widget target,
                // which has no appearance environment. One 20 pt glow on the sky card is not worth a
                // second copy of the modifier.
                .shadow(color: .white.opacity(0.35 * illumination), radius: 6)
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeInOut(duration: 0.35), value: illumination)
        .accessibilityElement()
        .accessibilityLabel(alwaysFull ? "Moon" : "\(phase.name), \(phase.illuminationPercent) percent illuminated")
    }
}

/// A tiny monochrome moon that takes the ambient foreground color - for dense contexts like a calendar row,
/// where the full `MoonPhaseView` (with its gradient and glow) would be noise.
struct MoonPhaseGlyph: View {
    let illumination: Double
    let isWaxing: Bool

    var body: some View {
        ZStack {
            Circle().strokeBorder(lineWidth: 0.5).opacity(0.45)
            MoonLitShape(illumination: illumination, isWaxing: isWaxing)
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
