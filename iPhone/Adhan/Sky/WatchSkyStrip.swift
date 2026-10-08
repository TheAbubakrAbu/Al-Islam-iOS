#if os(watchOS)
import SwiftUI

/// A one-line sky for the watch: where the sun is between today's sunrise and sunset, and tonight's moon.
///
/// The iPhone's `SkyView` is a 212pt canvas with a star field, a scrubbable solar arc, a gradient keyed to the
/// current prayer, and its own countdown. None of that fits on a wrist, and most of it is not what you raise
/// your wrist to find out. This keeps the two facts that survive the shrink - how much daylight is left, and
/// what the moon is doing - and draws them in a single strip under the countdown.
struct WatchSkyStrip: View {
    @ObservedObject private var settings = Settings.shared
    /// The shared scrub model (also drives the iPhone SkyView). On the watch this is a separate process, so
    /// there is no conflict. Dragging the arc previews a time of day; `previewPrayer` is the prayer then.
    @ObservedObject private var scrubber = DayScrubber.shared

    /// Re-drawn every minute. The sun's position across a whole day moves far too slowly to justify anything
    /// faster, and the watch is the last place to spend a redraw budget on invisible motion.
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(now: context.date)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if let sunrise = prayerTime("Shurooq", on: now), let sunset = prayerTime("Maghrib", on: now) {
            // Drag the arc to preview any daytime moment; otherwise it tracks the live sun.
            let displayedDate = scrubber.scrubbedDate ?? now
            let fraction = dayFraction(now: displayedDate, sunrise: sunrise, sunset: sunset)
            let prayerDots = mandatoryPrayerFractions(on: now, sunrise: sunrise, sunset: sunset)
            let skyPeriod = skyPeriodName(at: displayedDate, now: now)
            let moonPhase = MoonPhase.on(displayedDate)

            VStack(spacing: 3) {
                // Only appears while scrubbing: the prayer in effect at the previewed moment, and that time.
                // No prayer-times table - just "which prayer, and when", exactly like the iPhone sky readout.
                if scrubber.isScrubbing {
                    HStack(spacing: 5) {
                        if let name = scrubber.previewPrayer?.displayName {
                            Text(name)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        Text(settings.formatDate(displayedDate))
                            .font(.system(size: 11).monospacedDigit())
                    }
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .transition(.opacity)
                }

                // The arc takes the whole width now - the moon moved to its own line below (user rule).
                GeometryReader { geo in
                    SunArc(fraction: fraction, color: .white, dotFractions: prayerDots)
                        .frame(height: 22)
                        .contentShape(Rectangle())
                        .gesture(dragGesture(width: geo.size.width, sunrise: sunrise, sunset: sunset, now: now))
                }
                .frame(height: 22)
                .frame(maxWidth: .infinity)

                // The moon's own line: glyph, phase name, and how lit it is - the iPhone sky card's row.
                HStack(spacing: 5) {
                    MoonPhaseView(date: displayedDate, diameter: 14)

                    Text(moonPhase.name)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.75))

                    Text("\(moonPhase.illuminationPercent)% lit")
                        .font(.system(size: 8, weight: .medium).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.55))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            // The solar background the iPhone card has (user rule): the user's own sky palette, keyed to
            // the TRUE full-set period - past Isha wears Isha's colors even while the list shows the
            // traveling "Maghrib/Isha" pair - with the complication's legibility scrim over it.
            .background(
                ZStack {
                    LinearGradient(
                        colors: settings.skyGradientColors(forPrayer: skyPeriod),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    LinearGradient(
                        colors: [.black.opacity(0.10), .black.opacity(0.28)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .environment(\.colorScheme, .dark)
            .animation(.easeInOut(duration: 0.15), value: scrubber.isScrubbing)
            .animation(.easeInOut(duration: 0.4), value: skyPeriod)
        }
    }

    /// The TRUE prayer period at `date`, resolved against the FULL prayer set (never the traveling
    /// combined pairs) - what the gradient is keyed to. Before today's Fajr, the previous night's
    /// period still holds, so the pre-dawn strip stays in Isha's colors.
    private func skyPeriodName(at date: Date, now: Date) -> String? {
        if let today = settings.getPrayerTimes(for: now, fullPrayers: true),
           let current = today.last(where: { $0.time <= date }) {
            return current.nameTransliteration
        }
        let calendar = Calendar.current
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           let previous = settings.getPrayerTimes(for: yesterday, fullPrayers: true) {
            return previous.last(where: { $0.time <= date })?.nameTransliteration
        }
        return nil
    }

    /// Scrub the sun along the daylight arc: x → fraction → a time between sunrise and sunset. The scrubber's
    /// `previewPrayer` then names the prayer in effect at that moment.
    private func dragGesture(width: CGFloat, sunrise: Date, sunset: Date, now: Date) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !scrubber.isScrubbing {
                    settings.hapticFeedback()
                    scrubber.begin(timeline: settings.getPrayerTimes(for: now, fullPrayers: true) ?? [])
                }
                let f = min(max(value.location.x / max(width, 1), 0), 1)
                scrubber.scrub(to: sunrise.addingTimeInterval(f * sunset.timeIntervalSince(sunrise)))
            }
            .onEnded { _ in scrubber.end() }
    }

    private func prayerTime(_ name: String, on date: Date) -> Date? {
        // The full (uncombined) list: while traveling, the filtered one has no separate Maghrib row.
        settings.getPrayerTimes(for: date, fullPrayers: true)?
            .first { $0.nameTransliteration == name }?
            .time
    }

    /// The mandatory prayers as fractions along the sunrise→sunset arc - the same dots the lock-screen
    /// Prayer Wave widget draws. Only those inside the daylight span appear: Fajr and Isha fall while the
    /// sun is below the horizon, and clamping them onto the arc's ends would overlap Maghrib and lie about
    /// when they are. Dhuhr (or Jumuah), Asr, and Maghrib (at the sunset end) are the ones that land here.
    private func mandatoryPrayerFractions(on date: Date, sunrise: Date, sunset: Date) -> [Double] {
        let span = sunset.timeIntervalSince(sunrise)
        guard span > 0, let timeline = settings.getPrayerTimes(for: date, fullPrayers: true) else { return [] }
        return timeline
            .filter { Settings.adhanEligiblePrayerNames.contains($0.nameTransliteration) }
            .map { $0.time.timeIntervalSince(sunrise) / span }
            .filter { $0 >= 0 && $0 <= 1 }
    }

    /// 0 at sunrise, 1 at sunset. Clamped, so before dawn and after dusk the sun rests at the horizon rather
    /// than flying off the ends of the arc.
    private func dayFraction(now: Date, sunrise: Date, sunset: Date) -> Double {
        let span = sunset.timeIntervalSince(sunrise)
        guard span > 0 else { return 0 }
        return min(max(now.timeIntervalSince(sunrise) / span, 0), 1)
    }
}

/// A dashed half-arc from sunrise to sunset with the sun sitting on it, plus the horizon line beneath.
/// The sun is colored like the iPhone sky's (warm at the horizon, near-white overhead), and each mandatory
/// prayer inside the daylight span gets a small accent dot on the arc, mirroring the Prayer Wave widget.
private struct SunArc: View {
    let fraction: Double
    let color: Color
    let dotFractions: [Double]

    var body: some View {
        GeometryReader { geo in
            let size = CGSize(width: geo.size.width, height: geo.size.height)
            let sunSize: CGFloat = 6

            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: size.height))
                    path.addQuadCurve(
                        to: CGPoint(x: size.width, y: size.height),
                        control: CGPoint(x: size.width / 2, y: -size.height * 0.6)
                    )
                }
                .stroke(color.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: size.height))
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                }
                .stroke(color.opacity(0.25), lineWidth: 0.5)

                // Dots under the sun in draw order, so when the sun reaches a prayer it covers its dot.
                ForEach(dotFractions.indices, id: \.self) { idx in
                    Circle()
                        .fill(color.opacity(0.9))
                        .frame(width: 3.5, height: 3.5)
                        .position(point(at: dotFractions[idx], in: size))
                }

                Circle()
                    .fill(sunColor)
                    .frame(width: sunSize, height: sunSize)
                    .position(point(at: fraction, in: size))
            }
        }
    }

    /// `SkyView.sunColor`'s formula on the arc's own elevation: 4t(1-t) is 0 at both horizon ends and 1 at
    /// the peak, so the sun rises orange, whitens toward midday, and warms again into sunset.
    private var sunColor: Color {
        let t = min(max(fraction, 0), 1)
        let elevation = 4 * t * (1 - t)
        return Color(
            red: 1.0,
            green: 0.62 + 0.30 * elevation,
            blue: 0.25 + 0.60 * elevation
        )
    }

    /// The point on the quadratic Bézier at a fraction, so the sun and dots sit ON the arc rather than near it.
    private func point(at fraction: Double, in size: CGSize) -> CGPoint {
        let t = min(max(fraction, 0), 1)
        let start = CGPoint(x: 0, y: size.height)
        let control = CGPoint(x: size.width / 2, y: -size.height * 0.6)
        let end = CGPoint(x: size.width, y: size.height)

        let mt = 1 - t
        let x = mt * mt * start.x + 2 * mt * t * control.x + t * t * end.x
        let y = mt * mt * start.y + 2 * mt * t * control.y + t * t * end.y
        return CGPoint(x: x, y: y)
    }
}
#endif
