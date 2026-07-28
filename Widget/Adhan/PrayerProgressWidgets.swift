import SwiftUI
import WidgetKit

// The progress additions: a shared auto-filling bar showing how far the CURRENT prayer's window has
// elapsed (from its own start to the next prayer's time), plus the new progress-centric widgets -
// a lock-screen ring, a lock-screen countdown, the solar-wave rectangular, the "Prayer Day" medium
// board, and a fasting countdown. All ride the existing PrayersProvider; the bar and ring use
// `ProgressView(timerInterval:)` (iOS 16+), which WidgetKit animates continuously WITHOUT timeline
// reloads - the same mechanism as `Text(style: .timer)`.

// MARK: - Shared progress bar

/// A thin linear progress bar spanning the current prayer's window. On iOS 16+ it fills in real time;
/// on iOS 15 it falls back to a static fill computed at the entry's own date (entries are pre-built at
/// every prayer boundary, so even the static bar is never wildly stale).
struct PrayerIntervalProgressBar: View {
    let current: Prayer
    let next: Prayer
    /// The entry's date - NOT Date(): WidgetKit archives views when the timeline is built, so Date()
    /// would be the build time for every pre-built future entry.
    let entryDate: Date
    var tint: Color

    private var fallbackFraction: Double {
        let total = next.time.timeIntervalSince(current.time)
        guard total > 0 else { return 0 }
        return min(max(entryDate.timeIntervalSince(current.time) / total, 0), 1)
    }

    var body: some View {
        if current.time < next.time {
            Group {
                if #available(iOS 16.0, watchOS 9.0, *) {
                    ProgressView(timerInterval: current.time...next.time, countsDown: false,
                                 label: { EmptyView() }, currentValueLabel: { EmptyView() })
                } else {
                    ProgressView(value: fallbackFraction)
                }
            }
            .progressViewStyle(.linear)
            .tint(tint)
        }
    }
}

/// The one "no data yet" state every home-screen prayer widget shows, so an empty gallery of them
/// reads as one app rather than a scatter of bare strings. Lock-screen widgets keep plain text - the
/// system's vibrant rendering does their styling.
struct PrayerWidgetEmptyState: View {
    var tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.stars")
                .font(.title3)
                .foregroundColor(tint)

            Text("Open app to get prayer times")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Three-ish letters so a prayer name survives tiny lock-screen surfaces; combined traveling rows keep
/// only their first member's abbreviation.
func prayerAbbreviation(_ prayer: Prayer) -> String {
    switch prayer.nameTransliteration {
    case "Fajr":                    return "FJR"
    case "Shurooq":                 return "SHQ"
    case "Duhaa":                   return "DUH"
    case "Dhuhr", "Dhuhr/Asr":      return "DHR"
    case "Jumuah":                  return "JUM"
    case "Asr":                     return "ASR"
    case "Maghrib", "Maghrib/Isha": return "MGB"
    case "Isha":                    return "ISH"
    default:                        return String(prayer.displayName.prefix(3)).uppercased()
    }
}

// MARK: - Lock screen: progress ring

/// An accessoryCircular ring that fills as the current prayer's window elapses, with the prayer's
/// symbol and a compact name in the middle.
@available(iOS 16.0, *)
struct PrayerProgressRingView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        if let current = entry.currentPrayer, let next = entry.nextPrayer, current.time < next.time {
            ZStack {
                ProgressView(timerInterval: current.time...next.time, countsDown: false,
                             label: { EmptyView() }, currentValueLabel: { EmptyView() })
                    .progressViewStyle(.circular)

                VStack(spacing: 0) {
                    Image(systemName: current.image)
                        .font(.caption2)

                    Text(prayerAbbreviation(current))
                        .font(.system(size: 9, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(10)
            }
        } else {
            Image(systemName: "moon.stars")
                .font(.title3)
        }
    }
}

@available(iOS 16.0, *)
struct PrayerProgressRingWidget: Widget {
    let kind: String = "PrayerProgressRingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerProgressRingView(entry: entry)
                .widgetContainerBackground(accessory: true)
        }
        .supportedFamilies([.accessoryCircular])
        .configurationDisplayName("Prayer Progress Ring")
        .description("A ring that fills as the current prayer time passes")
    }
}

// MARK: - Lock screen: current prayer countdown

/// An accessoryCircular live countdown: the current prayer's symbol and name with the time remaining
/// until the next prayer, ticking down. (The existing circular widget shows the NEXT prayer's clock
/// time; this one answers "how long do I have left".)
@available(iOS 16.0, *)
struct PrayerCountdownCircularView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        VStack(spacing: 0) {
            if let current = entry.currentPrayer, let next = entry.nextPrayer {
                if !current.nameTransliteration.contains("/") {
                    Image(systemName: current.image)
                        .font(.system(size: 10))
                }

                Text(current.displayName)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)

                Text(next.time, style: .timer)
                    .font(.caption2.monospacedDigit())
                    .lineLimit(1)
            } else {
                Text("Open app")
                    .font(.caption2)
            }
        }
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.6)
    }
}

@available(iOS 16.0, *)
struct PrayerCountdownCircularWidget: Widget {
    let kind: String = "PrayerCountdownCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerCountdownCircularView(entry: entry)
                .widgetContainerBackground(accessory: true)
        }
        .supportedFamilies([.accessoryCircular])
        .configurationDisplayName("Current Prayer Countdown")
        .description("The current prayer and the time remaining in it")
    }
}

// MARK: - Lock screen: solar wave

/// The day's solar curve in miniature - the same cosine arc as the app's sky card - with a dot at each
/// mandatory prayer and the sun at the entry's moment, over the current prayer's name and countdown.
@available(iOS 16.0, *)
struct PrayerWaveView: View {
    var entry: PrayersProvider.Entry

    /// Fraction of the civil day (midnight → midnight) for a time. The in-app card centers its window on
    /// solar noon; at this size the difference is under a pixel, so the simpler window wins.
    private func dayFraction(of date: Date) -> Double {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        let length = end.timeIntervalSince(start)
        guard length > 0 else { return 0 }
        return min(max(date.timeIntervalSince(start) / length, 0), 1)
    }

    /// Solar-noon fraction: midpoint of Shurooq and Maghrib when both exist, else clock noon.
    private var noonFraction: Double {
        let full = entry.fullPrayers
        guard let sunrise = full.first(where: { $0.nameTransliteration == "Shurooq" })?.time,
              let sunset = full.first(where: { $0.nameTransliteration == "Maghrib" })?.time
        else { return 0.5 }
        return (dayFraction(of: sunrise) + dayFraction(of: sunset)) / 2
    }

    /// Normalized -1…1 curve height, mapped so the peak lands at solar noon (see SkyView's SolarCurve).
    private func height(at fraction: Double) -> Double {
        cos(2 * .pi * (fraction - noonFraction))
    }

    private var dotPrayers: [Prayer] {
        entry.prayers.filter { Settings.adhanEligiblePrayerNames.contains($0.nameTransliteration) }
    }

    var body: some View {
        VStack(spacing: 2) {
            if let current = entry.currentPrayer, let next = entry.nextPrayer {
                WaveGraph(
                    noonFraction: noonFraction,
                    dotFractions: dotPrayers.map { dayFraction(of: $0.time) },
                    sunFraction: dayFraction(of: entry.date)
                )

                HStack {
                    Text(current.displayName)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Spacer()

                    Text(next.time, style: .timer)
                        .font(.subheadline.monospacedDigit())
                        .multilineTextAlignment(.trailing)
                }
            } else {
                Text("Open app to get prayer times")
                    .font(.caption)
            }
        }
    }

    /// The arc itself: the dashed cosine curve, one dot per mandatory prayer, and the sun at the
    /// entry's moment. All positions are precomputed fractions - the graph only maps them into its rect.
    private struct WaveGraph: View {
        let noonFraction: Double
        let dotFractions: [Double]
        let sunFraction: Double

        private func point(at fraction: Double, in rect: CGRect) -> CGPoint {
            let inset: CGFloat = 4
            let usable = rect.height - 2 * inset
            let height = cos(2 * .pi * (fraction - noonFraction))
            return CGPoint(
                x: rect.minX + CGFloat(fraction) * rect.width,
                y: rect.maxY - inset - CGFloat((height + 1) / 2) * usable
            )
        }

        var body: some View {
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)

                ZStack {
                    Path { path in
                        let steps = 48
                        for i in 0...steps {
                            let p = point(at: Double(i) / Double(steps), in: rect)
                            i == 0 ? path.move(to: p) : path.addLine(to: p)
                        }
                    }
                    .stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [2, 3]))

                    ForEach(dotFractions, id: \.self) { fraction in
                        Circle()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 3.5, height: 3.5)
                            .position(point(at: fraction, in: rect))
                    }

                    Circle()
                        .fill(Color.white)
                        .frame(width: 7, height: 7)
                        .position(point(at: sunFraction, in: rect))
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct PrayerWaveWidget: Widget {
    let kind: String = "PrayerWaveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerWaveView(entry: entry)
                .widgetContainerBackground(accessory: true)
        }
        .supportedFamilies([.accessoryRectangular])
        .configurationDisplayName("Prayer Wave")
        .description("The day's prayers on the solar arc, with the current prayer's countdown")
    }
}

// MARK: - Home screen: Prayer Day board

/// The whole day on one medium widget: the current prayer and its live countdown up top, the
/// auto-filling progress bar across the middle, and every prayer of the day along the bottom with the
/// current one accented and underlined.
struct PrayerDayView: View {
    var entry: PrayersProvider.Entry

    private var hijriDate: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .medium)
    }

    private func tint(_ prayer: Prayer) -> Color {
        prayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color
    }

    private func isCurrent(_ prayer: Prayer) -> Bool {
        entry.currentPrayer?.nameTransliteration == prayer.nameTransliteration
    }

    var body: some View {
        if let current = entry.currentPrayer, let next = entry.nextPrayer {
            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: current.image)
                            .font(.subheadline)

                        Text(current.displayName)
                            .font(.headline)
                    }
                    .foregroundColor(tint(current))

                    Spacer()

                    Text(hijriDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(next.time, style: .timer)
                        .font(.subheadline.monospacedDigit())
                        .multilineTextAlignment(.trailing)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)

                PrayerIntervalProgressBar(
                    current: current,
                    next: next,
                    entryDate: entry.date,
                    tint: entry.accentColor.color
                )

                HStack(alignment: .top, spacing: 4) {
                    ForEach(entry.prayers) { prayer in
                        VStack(spacing: 3) {
                            Text(prayer.displayName)
                                .font(.caption2.weight(isCurrent(prayer) ? .bold : .semibold))

                            Text(prayer.time, style: .time)
                                .font(.caption2.monospacedDigit())

                            // The underline marking the current prayer, mirrored from the row highlight
                            // the app's list uses; a clear twin under the others keeps the row heights even.
                            Capsule()
                                .fill(isCurrent(prayer) ? entry.accentColor.color : .clear)
                                .frame(width: 24, height: 2)
                        }
                        .foregroundColor(isCurrent(prayer) ? entry.accentColor.color : .primary)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    }
                }
            }
        } else {
            PrayerWidgetEmptyState(tint: entry.accentColor.color)
        }
    }
}

struct PrayerDayWidget: Widget {
    let kind: String = "PrayerDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerDayView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Prayer Day")
        .description("Every prayer of the day, with the current prayer's live countdown and progress")
    }
}

// MARK: - Home screen: fasting countdown

/// Suhoor/iftar countdown for anyone fasting - Ramadan or a voluntary fast. During fasting hours
/// (Fajr → Maghrib) it counts down to iftar with the day's progress filling behind it; outside them it
/// counts down to Fajr, when the next fast would begin.
struct FastingCountdownView: View {
    var entry: PrayersProvider.Entry

    private var hijriDate: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .full)
    }

    /// (label, deadline, windowStart): iftar with the Fajr→Maghrib window while fasting, otherwise the
    /// next Fajr with the Maghrib→Fajr night window. Tomorrow's Fajr is approximated by adding a day -
    /// the minute or two of seasonal drift doesn't matter to a countdown this long.
    private var phase: (label: String, deadline: Date, windowStart: Date)? {
        let full = entry.fullPrayers
        guard let fajr = full.first(where: { $0.nameTransliteration == "Fajr" })?.time,
              let maghrib = full.first(where: { $0.nameTransliteration == "Maghrib" })?.time,
              fajr < maghrib else { return nil }

        let now = entry.date
        if now < fajr {
            let lastMaghrib = Calendar.current.date(byAdding: .day, value: -1, to: maghrib) ?? maghrib
            return ("Suhoor ends in", fajr, lastMaghrib)
        }
        if now < maghrib {
            return ("Iftar in", maghrib, fajr)
        }
        let nextFajr = Calendar.current.date(byAdding: .day, value: 1, to: fajr) ?? fajr
        return ("Suhoor ends in", nextFajr, maghrib)
    }

    var body: some View {
        if let phase {
            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: phase.label == "Iftar in" ? "sunset.fill" : "sunrise.fill")
                            .font(.subheadline)

                        Text("\(phase.label) \(Text(phase.deadline, style: .timer))")
                            .font(.headline)
                    }
                    .foregroundColor(entry.accentColor.color)

                    Spacer()

                    Text(phase.deadline, style: .time)
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)

                Group {
                    if #available(iOS 16.0, *), phase.windowStart < phase.deadline {
                        ProgressView(timerInterval: phase.windowStart...phase.deadline, countsDown: false,
                                     label: { EmptyView() }, currentValueLabel: { EmptyView() })
                    } else {
                        ProgressView(value: staticFraction(for: phase))
                    }
                }
                .progressViewStyle(.linear)
                .tint(entry.accentColor.color)

                HStack {
                    if !entry.currentCity.isEmpty {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(entry.accentColor.color)

                        Text(entry.currentCity)
                            .font(.caption2)
                    }

                    Spacer()

                    Text(hijriDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
        } else {
            PrayerWidgetEmptyState(tint: entry.accentColor.color)
        }
    }

    private func staticFraction(for phase: (label: String, deadline: Date, windowStart: Date)) -> Double {
        let total = phase.deadline.timeIntervalSince(phase.windowStart)
        guard total > 0 else { return 0 }
        return min(max(entry.date.timeIntervalSince(phase.windowStart) / total, 0), 1)
    }
}

struct FastingCountdownWidget: Widget {
    let kind: String = "FastingCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            FastingCountdownView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Fasting Countdown")
        .description("Counts down to iftar while fasting, and to suhoor's end overnight")
    }
}

// MARK: - Lock screen: prayer row

/// The whole day in one accessoryRectangular strip: a column per mandatory prayer - abbreviation, its
/// symbol, and its time - with the current one at full strength and the rest dimmed.
@available(iOS 16.0, *)
struct PrayerRowLockView: View {
    var entry: PrayersProvider.Entry

    private var rowPrayers: [Prayer] {
        entry.prayers.filter { Settings.adhanEligiblePrayerNames.contains($0.nameTransliteration) }
    }

    var body: some View {
        if rowPrayers.isEmpty {
            Text("Open app to get prayer times")
                .font(.caption)
        } else {
            HStack(alignment: .center, spacing: 4) {
                ForEach(rowPrayers, id: \.nameTransliteration) { prayer in
                    let isCurrent = entry.currentPrayer?.nameTransliteration == prayer.nameTransliteration

                    VStack(spacing: 2) {
                        Text(prayerAbbreviation(prayer))
                            .font(.system(size: 10, weight: isCurrent ? .bold : .semibold))

                        Image(systemName: prayer.image)
                            .font(.system(size: 10))

                        Text(prayer.time, style: .time)
                            .font(.system(size: 9).monospacedDigit())
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(isCurrent ? 1 : 0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct PrayerRowLockWidget: Widget {
    let kind: String = "PrayerRowLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerRowLockView(entry: entry)
                .widgetContainerBackground(accessory: true)
        }
        .supportedFamilies([.accessoryRectangular])
        .configurationDisplayName("Prayer Row")
        .description("All of today's prayers in one row, with the current one highlighted")
    }
}

// MARK: - Lock screen: next prayer progress

/// The next prayer's name over the current window's auto-filling bar, with the live countdown beneath -
/// "what's next and how long until it".
@available(iOS 16.0, *)
struct NextPrayerProgressView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let current = entry.currentPrayer, let next = entry.nextPrayer {
                HStack {
                    if !next.nameTransliteration.contains("/") {
                        Image(systemName: next.image)
                            .font(.caption)
                            .padding(.trailing, -4)
                    }

                    Text(next.displayName)
                        .font(.headline)

                    Spacer()

                    Text(next.time, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                PrayerIntervalProgressBar(
                    current: current,
                    next: next,
                    entryDate: entry.date,
                    tint: .primary
                )

                Text(next.time, style: .timer)
                    .font(.caption.monospacedDigit())
            } else {
                Text("Open app to get prayer times")
                    .font(.caption)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

@available(iOS 16.0, *)
struct NextPrayerProgressWidget: Widget {
    let kind: String = "NextPrayerProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            NextPrayerProgressView(entry: entry)
                .widgetContainerBackground(accessory: true)
        }
        .supportedFamilies([.accessoryRectangular])
        .configurationDisplayName("Next Prayer Progress")
        .description("The next prayer with a live countdown and progress bar")
    }
}

// MARK: - Home screen: small prayer list

/// Every prayer of the day as compact rows in a small widget - the whole schedule at a glance where
/// only the grid layouts existed before, and those start at medium.
struct PrayerListSmallView: View {
    var entry: PrayersProvider.Entry

    private func rowColor(for prayer: Prayer) -> Color {
        guard let currentIndex = entry.prayers.firstIndex(where: { $0.id == prayer.id }),
              let currentPrayerIndex = entry.prayers.firstIndex(where: {
                  $0.nameTransliteration == entry.currentPrayer?.nameTransliteration
              }) else { return .secondary }

        if currentIndex < currentPrayerIndex { return .secondary }
        if currentIndex == currentPrayerIndex { return entry.accentColor.color }
        return .primary
    }

    var body: some View {
        if entry.prayers.isEmpty {
            PrayerWidgetEmptyState(tint: entry.accentColor.color)
        } else {
            VStack(spacing: 4) {
                ForEach(entry.prayers) { prayer in
                    HStack {
                        Image(systemName: prayer.image)
                            .font(.caption2)
                            .frame(width: 12, alignment: .center)

                        Text(prayer.displayName)
                            .font(.caption.weight(.semibold))

                        Spacer(minLength: 4)

                        Text(prayer.time, style: .time)
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundColor(rowColor(for: prayer))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                }
            }
        }
    }
}

struct PrayerListSmallWidget: Widget {
    let kind: String = "PrayerListSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerListSmallView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Prayer List")
        .description("All of today's prayer times as a compact list")
    }
}

// MARK: - Home screen: next prayer board

/// A medium split: the NEXT prayer with its clock time, a live relative countdown and the window's
/// progress on the left; the full day's list on the right with the current prayer accented.
struct NextPrayerBoardView: View {
    var entry: PrayersProvider.Entry

    private func rowColor(for prayer: Prayer) -> Color {
        guard let currentIndex = entry.prayers.firstIndex(where: { $0.id == prayer.id }),
              let currentPrayerIndex = entry.prayers.firstIndex(where: {
                  $0.nameTransliteration == entry.currentPrayer?.nameTransliteration
              }) else { return .secondary }

        if currentIndex < currentPrayerIndex { return .secondary }
        if currentIndex == currentPrayerIndex { return entry.accentColor.color }
        return .primary
    }

    var body: some View {
        if let current = entry.currentPrayer, let next = entry.nextPrayer {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NEXT")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 5) {
                        Image(systemName: next.image)
                            .font(.subheadline)

                        Text(next.displayName)
                            .font(.headline)
                    }
                    .foregroundColor(next.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)

                    Text(next.time, style: .time)
                        .font(.title2.weight(.semibold).monospacedDigit())

                    Text(next.time, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer(minLength: 4)

                    PrayerIntervalProgressBar(
                        current: current,
                        next: next,
                        entryDate: entry.date,
                        tint: entry.accentColor.color
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .background(entry.accentColor.color)

                VStack(spacing: 3) {
                    ForEach(entry.prayers) { prayer in
                        HStack {
                            Image(systemName: prayer.image)
                                .font(.caption2)
                                .frame(width: 12, alignment: .center)

                            Text(prayer.displayName)
                                .font(.caption2.weight(.semibold))

                            Spacer(minLength: 4)

                            Text(prayer.time, style: .time)
                                .font(.caption2.monospacedDigit())
                        }
                        .foregroundColor(rowColor(for: prayer))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        } else {
            PrayerWidgetEmptyState(tint: entry.accentColor.color)
        }
    }
}

struct NextPrayerBoardWidget: Widget {
    let kind: String = "NextPrayerBoardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            NextPrayerBoardView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Next Prayer")
        .description("The next prayer with a live countdown beside the full day's times")
    }
}
