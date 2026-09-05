import SwiftUI
import WidgetKit

// The sky, on the home screen: the day's solar arc (the same dotted curve as the app's solar
// countdown card), the moon in its real phase (the same Meeus math and lit-limb shape the card
// uses, via MoonPhase.swift), and a large board carrying both. Each layout ships as a no-sky /
// sky twin like every other Adhan widget.
//
// Geometry: a 24-hour window CENTRED ON SOLAR NOON (not midnight), so the arc's peak is the
// middle of the widget and sunrise/sunset land symmetrically - the same choice the app's card
// makes (see SkyView.SolarWindow). The three formulas below are that file's, replicated because
// SkyView.swift is iPhone-only and drags iPhone-only dependencies.

// MARK: - Solar geometry

private struct WidgetSolarDay {
    let windowStart: Date
    let sunriseFraction: Double
    let sunsetFraction: Double

    static let windowLength: TimeInterval = 86_400

    init(entry: PrayersProvider.Entry) {
        // fullPrayers always carries the uncombined six, so Shurooq/Maghrib exist even in
        // traveling mode (the combined display list may not show them).
        let sunrise = entry.fullPrayers.first { $0.nameTransliteration == "Shurooq" }?.time
        let sunset = entry.fullPrayers.first { $0.nameTransliteration == "Maghrib" }?.time

        guard let sunrise, let sunset, sunset > sunrise else {
            windowStart = Calendar.current.startOfDay(for: entry.date)
            sunriseFraction = 0.25
            sunsetFraction = 0.75
            return
        }
        let solarNoon = sunrise.addingTimeInterval(sunset.timeIntervalSince(sunrise) / 2)
        windowStart = solarNoon.addingTimeInterval(-Self.windowLength / 2)
        sunriseFraction = Self.clamp(sunrise.timeIntervalSince(windowStart) / Self.windowLength)
        sunsetFraction = Self.clamp(sunset.timeIntervalSince(windowStart) / Self.windowLength)
    }

    func fraction(of date: Date) -> Double {
        Self.clamp(date.timeIntervalSince(windowStart) / Self.windowLength)
    }

    /// cos peaks at solar noon (fraction 0.5 of this window) and bottoms at the midnights.
    func height(at fraction: Double) -> Double {
        cos(2 * .pi * (fraction - 0.5))
    }

    /// The arc height at which the sun rises/sets - the horizon line.
    var horizon: Double {
        cos(.pi * (sunsetFraction - sunriseFraction))
    }

    func isDaylight(at fraction: Double) -> Bool {
        fraction >= sunriseFraction && fraction <= sunsetFraction
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

/// The sun's color by elevation - the app card's exact formula (SkyView.sunColor): grey below
/// the horizon, warming from amber to near-white toward noon.
private func widgetSunColor(height: Double, horizon: Double) -> Color {
    guard height > horizon else { return Color(white: 0.75) }
    let elevation = (height - horizon) / max(1 - horizon, 0.0001)
    return Color(red: 1.0, green: 0.62 + 0.30 * elevation, blue: 0.25 + 0.60 * elevation)
}

// MARK: - The arc graph

/// The dashed solar curve with the horizon line, a dot per prayer, and the glowing sun at the
/// entry's moment. White over the sky gradient; primary-tier greys on the standard background.
/// Internal (not private): the Next Prayer and Prayer Day boards squeeze it in as a `compact`
/// strip - smaller sun, dots and insets so it reads at ~30pt tall.
struct SolarArcGraph: View {
    let entry: PrayersProvider.Entry
    let skyStyle: Bool
    var compact: Bool = false

    private var lineColor: Color { skyStyle ? .white.opacity(0.30) : .secondary.opacity(0.5) }
    private var horizonColor: Color { skyStyle ? .white.opacity(0.45) : .secondary.opacity(0.35) }
    private var dotColor: Color { skyStyle ? .white.opacity(0.9) : .secondary }

    private var sunDiameter: CGFloat { compact ? 10 : 14 }
    private var dotDiameter: CGFloat { compact ? 4 : 5 }
    private var verticalInset: CGFloat { compact ? 7 : 10 }

    var body: some View {
        let day = WidgetSolarDay(entry: entry)
        let sunFraction = day.fraction(of: entry.date)
        let sunHeight = day.height(at: sunFraction)
        let isUp = day.isDaylight(at: sunFraction)
        let sunFill = widgetSunColor(height: sunHeight, horizon: day.horizon)
        let dots = entry.prayers.filter { Settings.adhanEligiblePrayerNames.contains($0.nameTransliteration) }

        GeometryReader { geo in
            let rect = geo.frame(in: .local)

            // The curve, sampled across the full window.
            Path { path in
                let steps = 72
                for step in 0...steps {
                    let fraction = Double(step) / Double(steps)
                    let point = point(at: fraction, day: day, in: rect)
                    if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
            }
            .stroke(lineColor, style: StrokeStyle(lineWidth: 1.5, dash: [3, 5]))

            // The horizon, edge to edge at rise/set height.
            Path { path in
                let y = yPosition(of: day.horizon, in: rect)
                path.move(to: CGPoint(x: rect.minX, y: y))
                path.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            .stroke(horizonColor, lineWidth: 1)

            ForEach(dots) { prayer in
                let fraction = day.fraction(of: prayer.time)
                Circle()
                    .fill(dotColor)
                    .frame(width: dotDiameter, height: dotDiameter)
                    .position(point(at: fraction, day: day, in: rect))
            }

            Circle()
                .fill(sunFill)
                .frame(width: sunDiameter, height: sunDiameter)
                .shadow(color: sunFill.opacity(isUp ? 0.9 : 0), radius: isUp ? 8 : 0)
                .position(point(at: sunFraction, day: day, in: rect))
                .opacity(isUp ? 1 : 0.45)
        }
    }

    private func point(at fraction: Double, day: WidgetSolarDay, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + CGFloat(fraction) * rect.width,
                y: yPosition(of: day.height(at: fraction), in: rect))
    }

    private func yPosition(of height: Double, in rect: CGRect) -> CGFloat {
        // Vertical inset keeps the sun's glow and the midnight troughs inside the frame.
        let inset = verticalInset
        let usable = rect.height - 2 * inset
        return rect.maxY - inset - CGFloat((height + 1) / 2) * usable
    }
}

// MARK: - Entry views

/// Medium: the current prayer and countdown, then the date and city, over the day's full solar arc,
/// sunrise and sunset times anchoring the corners.
struct SolarArcEntryView: View {
    var entry: PrayersProvider.Entry
    var skyStyle: Bool = false

    private var headerTint: Color {
        if skyStyle { return .white }
        guard let current = entry.currentPrayer else { return entry.accentColor.color }
        return current.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color
    }

    var body: some View {
        if let current = entry.currentPrayer, let next = entry.nextPrayer {
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: current.image)
                        .font(.subheadline)

                    Text(current.displayName)
                        .font(.headline)

                    Spacer(minLength: 4)

                    Text(next.time, style: .timer)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .multilineTextAlignment(.trailing)
                }
                .foregroundColor(headerTint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

                // The date and city under the header: the arc gives up one line, the corners keep
                // sunrise and sunset.
                PrayerWidgetContextRow(entry: entry, skyStyle: skyStyle)

                SolarArcGraph(entry: entry, skyStyle: skyStyle)

                HStack {
                    if let sunrise = entry.fullPrayers.first(where: { $0.nameTransliteration == "Shurooq" }) {
                        Label { Text(sunrise.time, style: .time) } icon: { Image(systemName: "sunrise.fill") }
                    }

                    Spacer()

                    if let sunset = entry.fullPrayers.first(where: { $0.nameTransliteration == "Maghrib" }) {
                        Label { Text(sunset.time, style: .time) } icon: { Image(systemName: "sunset.fill") }
                    }
                }
                .font(.caption2)
                .foregroundColor(skyStyle ? .white.opacity(0.75) : .secondary)
                .lineLimit(1)
            }
        } else {
            PrayerWidgetEmptyState(tint: entry.accentColor.color, skyStyle: skyStyle)
        }
    }
}

/// Small + medium: the moon as it looks tonight. The sky twin draws the real lit-limb moon
/// (white over the gradient); the standard background uses the monochrome glyph so the moon
/// stays visible in light mode.
struct MoonEntryView: View {
    @Environment(\.widgetFamily) private var systemWidgetFamily
    @Environment(\.previewWidgetFamily) private var previewWidgetFamily
    /// The gallery's override first (see `previewWidgetFamily`), else WidgetKit's.
    private var widgetFamily: WidgetFamily { previewWidgetFamily ?? systemWidgetFamily }

    var entry: PrayersProvider.Entry
    var skyStyle: Bool = false

    var body: some View {
        let phase = MoonPhase.on(entry.date)

        if widgetFamily == .systemMedium {
            VStack(spacing: 4) {
                HStack(alignment: .top, spacing: 14) {
                    moonGraphic(phase, diameter: 60)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(phase.name)
                            .font(.headline)
                            .foregroundColor(skyStyle ? .white : entry.accentColor.color)

                        Text("\(phase.illuminationPercent)% illuminated")
                            .font(.caption)
                            .foregroundColor(skyStyle ? .white.opacity(0.75) : .secondary)

                        Text(AdhanWidgetDateFormatting.hijriDate(for: entry, style: .medium))
                            .font(.caption2)
                            .foregroundColor(skyStyle ? .white.opacity(0.75) : .secondary)

                        // The city under the date, in this column rather than the trailing one: that
                        // one is whatever width the phase lines leave, and a long city name truncated
                        // there even at its smallest scale.
                        if !entry.currentCity.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "location.fill")

                                Text(entry.currentCity)
                            }
                            .font(.caption2)
                            .foregroundColor(skyStyle ? .white.opacity(0.75) : .secondary)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                    Spacer(minLength: 4)

                    // The widget's one prayer slot names the prayer you're IN, with the time left in it -
                    // the same current-first framing every other Adhan widget uses.
                    if let current = entry.currentPrayer, let next = entry.nextPrayer {
                        Text("\(current.displayName) \(Text(next.time, style: .timer))")
                            .font(.caption2)
                            .foregroundColor(skyStyle ? .white.opacity(0.9) : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }

                // The day's solar arc along the bottom - the moon row above keeps its layout and
                // just yields the widget's spare bottom height.
                SolarArcGraph(entry: entry, skyStyle: skyStyle, compact: true)
                    .frame(minHeight: 20, maxHeight: .infinity)
            }
        } else {
            VStack(spacing: 6) {
                moonGraphic(phase, diameter: 54)

                Text(phase.name)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(skyStyle ? .white : entry.accentColor.color)

                Text("\(phase.illuminationPercent)% illuminated")
                    .font(.caption2)
                    .foregroundColor(skyStyle ? .white.opacity(0.75) : .secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func moonGraphic(_ phase: MoonPhase, diameter: CGFloat) -> some View {
        if skyStyle {
            MoonPhaseView(date: entry.date, diameter: diameter)
        } else {
            MoonPhaseGlyph(illumination: phase.illumination, isWaxing: phase.isWaxing)
                .frame(width: diameter, height: diameter)
                .foregroundColor(.primary)
        }
    }
}

/// Large: the whole sky - the solar arc up top, the moon beneath it with the date and city, and the
/// day's prayer times along the bottom with the current one accented.
struct SolarMoonBoardEntryView: View {
    var entry: PrayersProvider.Entry
    var skyStyle: Bool = false

    private var headerTint: Color {
        if skyStyle { return .white }
        guard let current = entry.currentPrayer else { return entry.accentColor.color }
        return current.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color
    }

    var body: some View {
        if let current = entry.currentPrayer, let next = entry.nextPrayer {
            let phase = MoonPhase.on(entry.date)

            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: current.image)
                        .font(.subheadline)

                    Text(current.displayName)
                        .font(.headline)

                    Spacer(minLength: 4)

                    Text(next.time, style: .timer)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .multilineTextAlignment(.trailing)
                }
                .foregroundColor(headerTint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

                SolarArcGraph(entry: entry, skyStyle: skyStyle)

                HStack(spacing: 12) {
                    if skyStyle {
                        MoonPhaseView(date: entry.date, diameter: 40)
                    } else {
                        MoonPhaseGlyph(illumination: phase.illumination, isWaxing: phase.isWaxing)
                            .frame(width: 40, height: 40)
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(skyStyle ? .white : entry.accentColor.color)

                        Text("\(phase.illuminationPercent)% illuminated")
                            .font(.caption2)
                            .foregroundColor(skyStyle ? .white.opacity(0.75) : .secondary)
                    }

                    Spacer()

                    // The date and city, stacked against the trailing edge beside the moon.
                    PrayerWidgetContextRow(entry: entry, skyStyle: skyStyle, stacked: true, alignment: .trailing)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)

                // Pinned to both edges: spacers only BETWEEN the columns (the tracker's rule).
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(entry.prayers.enumerated()), id: \.element.id) { index, prayer in
                        if index > 0 { Spacer(minLength: 4) }
                        VStack(spacing: 3) {
                            Text(prayer.displayName)
                                .font(.caption2.weight(.semibold))

                            Text(prayer.time, style: .time)
                                .font(.caption2.monospacedDigit())
                        }
                        .foregroundColor(prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    }
                }
            }
        } else {
            PrayerWidgetEmptyState(tint: entry.accentColor.color, skyStyle: skyStyle)
        }
    }
}

// MARK: - The six widgets (three layouts, each with its sky twin)

struct SolarArcWidget: Widget {
    let kind: String = "SolarArcWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            SolarArcEntryView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .configurationDisplayName("Solar Arc")
        .description("The sun's path across the day with a dot per prayer, and the current prayer's countdown")
        .supportedFamilies([.systemMedium])
    }
}

/// The Solar Arc widget, unchanged, over the current prayer's sky gradient.
struct SolarArcSkyWidget: Widget {
    let kind: String = "SolarArcSkyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            SolarArcEntryView(entry: entry, skyStyle: true)
                .modifier(PrayerSkyChrome(entry: entry))
        }
        .configurationDisplayName("Solar Arc Sky")
        .description("The sun's path across the day, over the current prayer's sky gradient")
        .supportedFamilies([.systemMedium])
    }
}

struct MoonWidget: Widget {
    let kind: String = "MoonWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            MoonEntryView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .configurationDisplayName("Moon Phase")
        .description("Tonight's moon with its phase and illumination; the medium size adds the Hijri date and current prayer")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// The Moon Phase widget, unchanged, over the current prayer's sky gradient.
struct MoonSkyWidget: Widget {
    let kind: String = "MoonSkyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            MoonEntryView(entry: entry, skyStyle: true)
                .modifier(PrayerSkyChrome(entry: entry))
        }
        .configurationDisplayName("Moon Phase Sky")
        .description("Tonight's moon in its real phase, over the current prayer's sky gradient")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SolarMoonWidget: Widget {
    let kind: String = "SolarMoonWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            SolarMoonBoardEntryView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .configurationDisplayName("Day & Night")
        .description("The solar arc, tonight's moon, and every prayer of the day on one board")
        .supportedFamilies([.systemLarge])
    }
}

/// The Day & Night board, unchanged, over the current prayer's sky gradient.
struct SolarMoonSkyWidget: Widget {
    let kind: String = "SolarMoonSkyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            SolarMoonBoardEntryView(entry: entry, skyStyle: true)
                .modifier(PrayerSkyChrome(entry: entry))
        }
        .configurationDisplayName("Day & Night Sky")
        .description("The solar arc, tonight's moon, and every prayer, over the current prayer's sky gradient")
        .supportedFamilies([.systemLarge])
    }
}
