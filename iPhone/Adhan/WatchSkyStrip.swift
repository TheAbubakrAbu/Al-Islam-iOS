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

            VStack(spacing: 2) {
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
                    .foregroundStyle(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .transition(.opacity)
                }

                HStack(spacing: 8) {
                    GeometryReader { geo in
                        SunArc(fraction: fraction, color: settings.accentColor.accent1)
                            .frame(height: 22)
                            .contentShape(Rectangle())
                            .gesture(dragGesture(width: geo.size.width, sunrise: sunrise, sunset: sunset, now: now))
                    }
                    .frame(height: 22)
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 1) {
                        MoonPhaseView(date: displayedDate, diameter: 16)

                        Text("\(MoonPhase.on(displayedDate).illuminationPercent)%")
                            .font(.system(size: 8).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .animation(.easeInOut(duration: 0.15), value: scrubber.isScrubbing)
        }
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

    /// 0 at sunrise, 1 at sunset. Clamped, so before dawn and after dusk the sun rests at the horizon rather
    /// than flying off the ends of the arc.
    private func dayFraction(now: Date, sunrise: Date, sunset: Date) -> Double {
        let span = sunset.timeIntervalSince(sunrise)
        guard span > 0 else { return 0 }
        return min(max(now.timeIntervalSince(sunrise) / span, 0), 1)
    }
}

/// A dashed half-arc from sunrise to sunset with the sun sitting on it, plus the horizon line beneath.
private struct SunArc: View {
    let fraction: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let sunSize: CGFloat = 6

            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h))
                    path.addQuadCurve(
                        to: CGPoint(x: w, y: h),
                        control: CGPoint(x: w / 2, y: -h * 0.6)
                    )
                }
                .stroke(color.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: h))
                    path.addLine(to: CGPoint(x: w, y: h))
                }
                .stroke(color.opacity(0.25), lineWidth: 0.5)

                Circle()
                    .fill(color)
                    .frame(width: sunSize, height: sunSize)
                    .position(sunPoint(in: CGSize(width: w, height: h)))
            }
        }
    }

    /// The point on the quadratic Bézier at `fraction`, so the sun sits ON the arc rather than near it.
    private func sunPoint(in size: CGSize) -> CGPoint {
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
