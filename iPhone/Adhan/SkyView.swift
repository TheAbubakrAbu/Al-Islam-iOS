#if os(iOS)
import SwiftUI

// MARK: - Solar geometry

/// The sun's height above the horizon over one day, normalized to −1…1.
///
/// Solar elevation is `sin(alt) = sinφ·sinδ + cosφ·cosδ·cos(H)` — an affine function of the cosine of the hour
/// angle. So the normalized curve is simply `cos(2π·(x − solarNoon))`, and the horizon sits at whatever height
/// that curve has at sunrise. Deriving the horizon from the app's *actual* sunrise and Maghrib times (rather
/// than assuming 6am/6pm) is what makes a long June day show more curve above the line than a short December one.
struct SolarCurve {
    /// Fraction of the day at sunrise and at sunset, in 0…1.
    let sunriseFraction: Double
    let sunsetFraction: Double

    var solarNoonFraction: Double { (sunriseFraction + sunsetFraction) / 2 }

    /// Normalized height of the horizon line, in −1…1.
    var horizon: Double { cos(.pi * (sunsetFraction - sunriseFraction)) }

    /// Normalized sun height at a given fraction of the day.
    func height(at fraction: Double) -> Double {
        cos(2 * .pi * (fraction - solarNoonFraction))
    }

    func isDaylight(at fraction: Double) -> Bool {
        fraction >= sunriseFraction && fraction <= sunsetFraction
    }

    /// Falls back to a nominal quarter-to-three-quarters day when sunrise and sunset don't bracket a sane
    /// daylight span — no prayer times yet, or a polar day/night where the library returns nothing at all.
    init(sunriseFractionOfWindow s: Double?, sunsetFractionOfWindow e: Double?) {
        if let s, let e, e > s, (0...1).contains(s), (0...1).contains(e) {
            sunriseFraction = s
            sunsetFraction = e
        } else {
            sunriseFraction = 0.25
            sunsetFraction = 0.75
        }
    }
}

/// The 24-hour span the arc draws, centred on the location's solar noon.
///
/// Anchoring on solar noon rather than on device-local midnight is what keeps the arc honest when the device's
/// time zone doesn't match the coordinates it is computing for — someone who just landed and whose phone hasn't
/// switched over, or anyone with automatic time off. Prayer times are absolute instants; midnight is not.
/// Centring on the midpoint of sunrise and sunset makes the sun's peak land at the middle of the card by
/// construction, whatever the zone.
struct SolarWindow {
    let start: Date
    let length: TimeInterval

    var end: Date { start.addingTimeInterval(length) }

    func fraction(of date: Date) -> Double {
        guard length > 0 else { return 0 }
        return min(max(date.timeIntervalSince(start) / length, 0), 1)
    }

    func date(atFraction fraction: Double) -> Date {
        start.addingTimeInterval(min(max(fraction, 0), 1) * length)
    }

    /// `sunrise`/`sunset` are today's real Shurooq and Maghrib. Without them we fall back to the device's
    /// calendar day, which is DST-aware and correct whenever the zone does match the location.
    init(sunrise: Date?, sunset: Date?, fallbackDayStart: Date, fallbackDayLength: TimeInterval) {
        if let sunrise, let sunset, sunset > sunrise, sunset.timeIntervalSince(sunrise) < 86_400 {
            let solarNoon = sunrise.addingTimeInterval(sunset.timeIntervalSince(sunrise) / 2)
            start = solarNoon.addingTimeInterval(-43_200)
            length = 86_400
        } else {
            start = fallbackDayStart
            length = fallbackDayLength
        }
    }
}

/// The dashed sun path. Drawn as a polyline of the normalized curve, mapped into the rect with `inset` of
/// vertical padding so the peak and trough don't touch the edges.
private struct SolarArcShape: Shape {
    let curve: SolarCurve
    let inset: CGFloat

    func yPosition(of height: Double, in rect: CGRect) -> CGFloat {
        let usable = rect.height - 2 * inset
        return rect.maxY - inset - CGFloat((height + 1) / 2) * usable
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = 96
        for i in 0...steps {
            let fraction = Double(i) / Double(steps)
            let point = CGPoint(
                x: rect.minX + CGFloat(fraction) * rect.width,
                y: yPosition(of: curve.height(at: fraction), in: rect)
            )
            i == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        return path
    }
}

// MARK: - Stars

/// A field of faint, slowly twinkling stars, faded in over the night prayers.
///
/// Positions are derived from a fixed seed rather than `Math.random`, so the sky doesn't reshuffle itself on
/// every re-render — and the same star keeps the same twinkle phase across state changes.
private struct StarFieldView: View {
    let opacity: Double

    private struct Star {
        let x, y, radius, phase, brightness: Double
    }

    private static let stars: [Star] = {
        // A tiny linear congruential generator: deterministic, and no dependency on the Foundation RNG.
        var seed: UInt64 = 0x5EED_1517
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double((seed >> 33) & 0xFFFF) / Double(0xFFFF)
        }
        return (0..<44).map { _ in
            Star(
                x: next(),
                // Bias toward the top: the lower half of the card is below the horizon.
                y: next() * 0.62,
                radius: 0.6 + next() * 1.1,
                phase: next(),
                brightness: 0.35 + next() * 0.55
            )
        }
    }()

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 6.0, paused: opacity <= 0.01)) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for star in Self.stars {
                        // Each star twinkles on its own cycle, offset by its phase.
                        let twinkle = 0.55 + 0.45 * sin(2 * .pi * (t / 4.0 + star.phase))
                        let alpha = star.brightness * twinkle * opacity
                        let rect = CGRect(
                            x: star.x * size.width - star.radius,
                            y: star.y * size.height - star.radius,
                            width: star.radius * 2,
                            height: star.radius * 2
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Sky view

/// The Adhan tab's one card: the sun on today's arc, the moon at its true phase, the current and upcoming
/// prayers, and the countdown. Drag the sun to scrub the day — the gradient, the clock and the prayer list
/// below all follow.
struct SkyView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var scrubber = DayScrubber.shared
    @ObservedObject private var adhanPlayer = ForegroundAdhanPlayer.shared
    @Environment(\.layoutDirection) private var layoutDirection

    /// Ticks the live sun forward. One minute is finer than the sun visibly moves across ~340 points.
    @State private var now = Date()
    private let tick = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    /// Taller than the old sky, because the card now holds everything: the prayer columns, the arc, the moon
    /// and the countdown. Nothing lives below it any more.
    private let height: CGFloat = 300

    /// Horizontal row inset, measured off the sections around this card rather than assumed. A grouped row
    /// already carries the list's own 20pt margin, so the card adds nothing; a plain row carries none, and
    /// its neighbours (the location pill, the prayer tiles) sit at 19.33pt.
    private var sideInset: CGFloat { settings.defaultView ? 0 : 19.33 }
    /// Vertical padding on the arc, keeping its peak and trough clear of the text bands above and below.
    private let inset: CGFloat = 92

    // MARK: Derived state

    private var fallbackDayStart: Date { Calendar.current.startOfDay(for: now) }

    /// Not always 86,400 — DST transitions make a 23- or 25-hour day, and the arc must still span it.
    private var fallbackDayLength: TimeInterval {
        let calendar = Calendar.current
        guard let next = calendar.date(byAdding: .day, value: 1, to: fallbackDayStart) else { return 86_400 }
        return calendar.startOfDay(for: next).timeIntervalSince(fallbackDayStart)
    }

    /// Always the full six, because the arc needs a real Shurooq and Maghrib to place the horizon.
    private var todaysPrayers: [Prayer] {
        settings.getPrayerTimes(for: now, fullPrayers: true) ?? []
    }

    /// What the *list* is showing — traveling mode combines prayers, and `PrayerList` matches the highlight by
    /// name. Feeding the scrubber the full six would look up "Dhuhr" while the row says "Dhuhr/Asr", and the
    /// highlight would silently vanish for anyone in traveling mode.
    private var highlightTimeline: [Prayer] {
        let displayed = settings.prayers?.prayers ?? todaysPrayers
        return settings.prayersIncludingOptional(displayed, for: now)
    }

    private var sunrise: Date? { todaysPrayers.first { $0.nameTransliteration == "Shurooq" }?.time }
    private var sunset: Date? { todaysPrayers.first { $0.nameTransliteration == "Maghrib" }?.time }

    private var window: SolarWindow {
        SolarWindow(
            sunrise: sunrise,
            sunset: sunset,
            fallbackDayStart: fallbackDayStart,
            fallbackDayLength: fallbackDayLength
        )
    }

    private var curve: SolarCurve {
        let window = self.window
        return SolarCurve(
            sunriseFractionOfWindow: sunrise.map(window.fraction(of:)),
            sunsetFractionOfWindow: sunset.map(window.fraction(of:))
        )
    }

    /// The moment the whole card is describing: the dragged one, or now.
    private var displayedDate: Date { scrubber.scrubbedDate ?? now }

    private var displayedFraction: Double { window.fraction(of: displayedDate) }

    private var displayedPrayer: Prayer? {
        scrubber.previewPrayer ?? settings.currentPrayer
    }

    /// Stars come out at night. Full through Isha and the late-night times, fading in over Maghrib and back
    /// out through Fajr, and gone once the sun is up — which also pauses the twinkle animation.
    private var starOpacity: Double {
        switch displayedPrayer?.nameTransliteration {
        case "Isha", "Islamic Midnight", "Last Third": return 1
        case "Maghrib/Isha":                           return 0.8
        case "Fajr":                                   return 0.5
        case "Maghrib":                                return 0.3
        default:                                       return 0
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: settings.skyGradientColors(forPrayer: displayedPrayer?.nameTransliteration),
                startPoint: .top,
                endPoint: .bottom
            )
            // Re-tint both when the prayer changes and when the user edits that prayer's colors.
            .animation(.easeInOut(duration: 0.4), value: displayedPrayer?.nameTransliteration)
            .animation(.easeInOut(duration: 0.25), value: settings.skyGradientsJSON)

            StarFieldView(opacity: starOpacity)
                .animation(.easeInOut(duration: 0.6), value: starOpacity)

            arc

            // Legibility scrim, weighted to the two text bands. A soft gradient rather than a hard seam: it
            // reads as dusk gathering at the horizon, and it keeps white text readable over whichever two
            // colors the user picked — a pale midday cyan included.
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.32), location: 0.00),
                    .init(color: .black.opacity(0.00), location: 0.26),
                    .init(color: .black.opacity(0.00), location: 0.48),
                    .init(color: .black.opacity(0.66), location: 1.00),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            content
        }
        .frame(height: height)
        // Everything inside draws light-on-dark, whatever the phone's appearance.
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
        // The two list themes give a row different built-in margins, so the card has to make up the
        // difference itself. Grouped rows already carry the list's 20pt margin — adding any more is what
        // made this card sit inset from every other section. Plain rows carry almost none, so without this
        // the card bleeds out past the sections above and below it.
        .listRowInsets(EdgeInsets(top: 6, leading: sideInset, bottom: 6, trailing: sideInset))
        .onReceive(tick) { now = $0 }
        .onAppear { now = Date() }
    }

    /// Everything drawn over the sky: the two prayer columns, the moon and clock, and the countdown.
    private var content: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                prayerColumn(title: "CURRENT", prayer: settings.currentPrayer, alignment: .leading)
                Spacer(minLength: 0)
                prayerColumn(title: "UPCOMING", prayer: settings.nextPrayer, alignment: .trailing)
            }

            Spacer(minLength: 0)

            moonAndClock

            if settings.prayers != nil {
                PrayerCountdown(presentation: .skyFooter)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // Only the stop button is interactive; the rest is decoration over the drag area.
        .allowsHitTesting(adhanPlayer.isPlaying)
    }

    /// One side of the header: the label, the prayer's symbol and name, and when it started or starts.
    /// No Arabic or English subtitle — the prayer list below carries those.
    @ViewBuilder
    private func prayerColumn(title: String, prayer: Prayer?, alignment: HorizontalAlignment) -> some View {
        let trailing = alignment == .trailing
        VStack(alignment: alignment, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))

            if let prayer {
                HStack(spacing: 6) {
                    if trailing { Text(prayer.displayName).font(.title3.weight(.semibold)) }
                    Image(systemName: prayer.image)
                    if !trailing { Text(prayer.displayName).font(.title3.weight(.semibold)) }
                }
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

                Text("\(trailing ? "Starts at" : "Started at") \(settings.formatDate(prayer.time))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    /// Bottom-centre: the moment being shown and the moon's phase. While dragging, the previewed prayer's name
    /// joins them — the columns above always report the *live* prayer, so the scrub would otherwise be mute.
    @ViewBuilder
    private var moonAndClock: some View {
        if let playingPrayerName = adhanPlayer.playingPrayerName {
            adhanStopButton(prayerName: playingPrayerName)
        } else {
            HStack(spacing: 8) {
                if scrubber.isScrubbing, let name = displayedPrayer?.displayName {
                    Text(name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .transition(.opacity)
                }

                Text(settings.formatDate(displayedDate))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white)

                Text(MoonPhase.on(displayedDate).name)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))

                MoonPhaseView(date: displayedDate, diameter: 22)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
        }
    }




    private var arc: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let shape = SolarArcShape(curve: curve, inset: inset)
            let horizonY = shape.yPosition(of: curve.horizon, in: rect)
            let sunHeight = curve.height(at: displayedFraction)
            let sunPoint = CGPoint(
                x: xPosition(forFraction: displayedFraction, in: rect),
                y: shape.yPosition(of: sunHeight, in: rect)
            )
            let isUp = curve.isDaylight(at: displayedFraction)

            ZStack {
                shape
                    .stroke(
                        Color.white.opacity(0.30),
                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 5])
                    )

                Path { path in
                    path.move(to: CGPoint(x: rect.minX + 12, y: horizonY))
                    path.addLine(to: CGPoint(x: rect.maxX - 12, y: horizonY))
                }
                .stroke(Color.white.opacity(0.45), lineWidth: 1)

                // A drop-line to the horizon while dragging, so the sun's height reads as a position.
                if scrubber.isScrubbing {
                    Path { path in
                        path.move(to: sunPoint)
                        path.addLine(to: CGPoint(x: sunPoint.x, y: horizonY))
                    }
                    .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                }

                Circle()
                    .fill(sunColor(height: sunHeight))
                    .frame(width: 20, height: 20)
                    .shadow(color: sunColor(height: sunHeight).opacity(isUp ? 0.9 : 0), radius: isUp ? 12 : 0)
                    .position(sunPoint)
                    .opacity(isUp ? 1 : 0.45)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(in: rect))
        }
    }

    /// Shown only while the adhan is actually sounding in-app. The full recording runs for minutes, so there
    /// has to be a way to stop it without force-quitting.
    private func adhanStopButton(prayerName: String) -> some View {
        Button {
            settings.hapticFeedback()
            adhanPlayer.stopAdhan()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2.fill")
                Text("\(prayerName) adhan · Tap to stop")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: Interaction

    private func dragGesture(in rect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !scrubber.isScrubbing {
                    settings.hapticFeedback()
                    scrubber.begin(timeline: highlightTimeline)
                }
                let fraction = fractionOf(x: value.location.x, in: rect)
                scrubber.scrub(to: window.date(atFraction: fraction))
            }
            .onEnded { _ in
                scrubber.end()
            }
    }

    private func fractionOf(x: CGFloat, in rect: CGRect) -> Double {
        guard rect.width > 0 else { return 0 }
        let raw = Double(x / rect.width)
        let directed = layoutDirection == .rightToLeft ? 1 - raw : raw
        return min(max(directed, 0), 1)
    }

    private func xPosition(forFraction fraction: Double, in rect: CGRect) -> CGFloat {
        let directed = layoutDirection == .rightToLeft ? 1 - fraction : fraction
        return rect.minX + CGFloat(directed) * rect.width
    }

    /// Warm and huge near the horizon, small and white overhead, dim below.
    private func sunColor(height: Double) -> Color {
        let horizon = curve.horizon
        guard height > horizon else { return Color(white: 0.75) }
        // 0 at the horizon, 1 at solar noon.
        let elevation = (height - horizon) / max(1 - horizon, 0.0001)
        return Color(
            red: 1.0,
            green: 0.62 + 0.30 * elevation,
            blue: 0.25 + 0.60 * elevation
        )
    }
}
#endif
