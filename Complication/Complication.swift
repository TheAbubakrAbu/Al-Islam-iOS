import SwiftUI
import WidgetKit

/// Whether this render can wear the sky gradient.
///
/// A watch FACE flattens every complication into the face's own tint (`.accented` / `.vibrant`), so a
/// colored background there is either dropped or smeared into one tone - the families that only live on
/// the face (inline, corner) never see it at all. The Smart Stack renders `.fullColor`, and that is the
/// surface that reads as a black card today, so the gradient is drawn exactly there and the face keeps
/// the clear container it always had.
func complicationSkyStyle(_ mode: WidgetRenderingMode) -> Bool {
    guard #available(watchOS 10.0, *) else { return false }
    return mode == .fullColor
}

/// The home-screen widgets' sky treatment, on the watch: the current prayer's two-stop gradient (the
/// user's own palette included - it rides over from the phone via `watchSyncedAppStorageKeys`) under the
/// same bottom-weighted scrim, so white complication text stays legible against a bright midday sky.
/// Mirrors `PrayerSkyBackground` in the Widget target, which the complication can't import.
struct ComplicationSkyGradient: View {
    let entry: PrayersProvider.Entry

    var body: some View {
        LinearGradient(
            colors: Settings.shared.skyGradientColors(forPrayer: entry.currentPrayer?.nameTransliteration),
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            LinearGradient(
                colors: [.black.opacity(0.10), .black.opacity(0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

/// watchOS 10 requires every widget to declare its background via `containerBackground(for:)` - without
/// it, complications built against the newer SDK render as an "adopt containerBackground" placeholder
/// instead of their content. Full-color renders take the sky gradient; everything else stays `.clear` so
/// the system applies its own vibrant treatment. This is also where the app-wide rounded design reaches
/// the complication tree (the watch app's root modifier can't reach a widget extension).
struct ComplicationChrome: ViewModifier {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let entry: PrayersProvider.Entry

    func body(content: Content) -> some View {
        Group {
            if #available(watchOS 10.0, *) {
                if complicationSkyStyle(renderingMode) {
                    content
                        .containerBackground(for: .widget) { ComplicationSkyGradient(entry: entry) }
                        .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1)
                } else {
                    content.containerBackground(.clear, for: .widget)
                }
            } else {
                content
            }
        }
        .appFontDesign()
    }
}

extension View {
    func complicationContainer(entry: PrayersProvider.Entry) -> some View {
        modifier(ComplicationChrome(entry: entry))
    }
}

extension PrayersEntry {
    /// How far the current prayer interval has elapsed, 0...1 - drives the corner capacity gauge. Mirrors
    /// `PrayerCountdown.progressValue()`, including the overnight-boundary wrap, but is evaluated at the
    /// entry's date (a gauge can't self-update, so like the battery gauge it steps at each timeline entry).
    var dayProgress: Double {
        guard var start = currentPrayer?.time, var end = nextPrayer?.time else { return 0 }
        let now = date
        if start > now { start.addTimeInterval(-86_400) }
        if end <= start { end.addTimeInterval(86_400) }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        let remaining = end.timeIntervalSince(now)
        return max(0, min(1, 1 - remaining / total))
    }
}

/// The single-slot families (inline, corner, circular) lead with the CURRENT prayer - the one you are
/// actually in - and express what's next through the countdown or the gauge. Only the rectangular has the
/// room to name both, so only it carries an explicit "Up Next" line.
struct PrayersEntryView: View {
    var entry: PrayersProvider.Entry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    /// Over the sky gradient everything goes white - accent-on-gradient is unreadable there, exactly as
    /// on the home-screen sky widgets.
    private var skyStyle: Bool { complicationSkyStyle(renderingMode) }

    func accent(for prayer: Prayer) -> Color {
        if skyStyle { return .white }
        return prayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color
    }

    private var secondaryColor: Color { skyStyle ? .white.opacity(0.75) : .secondary }

    var body: some View {
        switch family {
        case .accessoryInline:
            inline
        case .accessoryRectangular:
            rectangular
        case .accessoryCorner:
            corner
        default:
            circular
        }
    }

    @ViewBuilder
    var inline: some View {
        if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
            Label {
                Text("\(currentPrayer.displayName) \(nextPrayer.time, style: .timer)")
            } icon: {
                Image(systemName: currentPrayer.image)
            }
        } else {
            Label("Open app", systemImage: "moon.stars.fill")
        }
    }

    // Corner: the current prayer's icon at the tip, and a curved capacity Gauge along the bezel showing how
    // far its window has elapsed - the same "progressive" arc the battery complication uses.
    @ViewBuilder
    var corner: some View {
        if let currentPrayer = entry.currentPrayer {
            Image(systemName: currentPrayer.image)
                .font(.title3)
                .foregroundColor(accent(for: currentPrayer))
                // On tinted faces the icon joins the face's accent group instead of going flat gray.
                .widgetAccentable()
                .widgetLabel {
                    Gauge(value: entry.dayProgress) {
                        Text(currentPrayer.displayName)
                    }
                    .tint(accent(for: currentPrayer))
                }
        } else {
            Image(systemName: "moon.stars.fill")
                .foregroundColor(entry.accentColor.color)
                .widgetLabel { Text("Open app") }
        }
    }

    var circular: some View {
        ZStack {
            // The gradient IS the background in full color; the system's frosted disc only belongs on the
            // tinted watch face.
            if !skyStyle {
                AccessoryWidgetBackground()
            }

            if let currentPrayer = entry.currentPrayer {
                VStack(spacing: 1) {
                    Image(systemName: currentPrayer.image)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(accent(for: currentPrayer))
                        .widgetAccentable()

                    Text(currentPrayer.time, style: .time)
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundColor(accent(for: currentPrayer))
                }
            } else {
                Text("Open app")
                    .font(.caption2)
                    .foregroundColor(skyStyle ? .white : entry.accentColor.color)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .font(.caption)
            } else if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                HStack {
                    if entry.prayers.count == 6 {
                        Image(systemName: currentPrayer.image)
                            .font(.body)
                            .padding(.trailing, -4)
                    }

                    Text(currentPrayer.displayName)
                        .font(.headline)

                    Text("\(nextPrayer.time, style: .timer)")
                        .font(.caption)
                        .foregroundColor(secondaryColor)
                }
                .foregroundColor(accent(for: currentPrayer))
                .widgetAccentable()

                Text("Up Next: \(nextPrayer.displayName) at \(Text(nextPrayer.time, style: .time))")
                    .font(.subheadline)

                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(skyStyle ? .white : entry.accentColor.color)
                        .padding(.trailing, -4)

                    Text(entry.currentCity)
                }
                .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

struct Complication: Widget {
    let kind: String = "Complication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayersEntryView(entry: entry)
                .complicationContainer(entry: entry)
        }
        .configurationDisplayName("Current Prayer")
        .description("The current prayer and when the next one begins.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular
        ])
    }
}

// MARK: - Countdown complication

/// A complication focused purely on the live countdown through the CURRENT prayer's window. Uses WidgetKit's
/// self-updating `Text(_, style: .timer)` / `ProgressView(timerInterval:)`, so it ticks down on its own between
/// timeline refreshes (the shared `PrayersProvider` refreshes at the next prayer time, when the window rolls).
struct CountdownComplicationView: View {
    var entry: PrayersProvider.Entry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var skyStyle: Bool { complicationSkyStyle(renderingMode) }

    private func accent(for prayer: Prayer) -> Color {
        if skyStyle { return .white }
        return prayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color
    }

    /// `currentPrayer.time ... nextPrayer.time` is always valid (current is the last prayer <= now, next is
    /// the first > now), but fall back to the entry date and clamp defensively so the gauge can never get an
    /// inverted range.
    private func interval(to next: Prayer) -> ClosedRange<Date> {
        let start = entry.currentPrayer?.time ?? entry.date
        return min(start, next.time)...next.time
    }

    var body: some View {
        if let current = entry.currentPrayer, let next = entry.nextPrayer {
            switch family {
            case .accessoryInline:
                Label {
                    Text("\(current.displayName) \(next.time, style: .timer)")
                } icon: {
                    Image(systemName: current.image)
                }
            case .accessoryCorner:
                Image(systemName: current.image)
                    .font(.title3)
                    .foregroundColor(accent(for: current))
                    .widgetAccentable()
                    .widgetLabel {
                        // A curved capacity Gauge (battery-style) that fills as the current prayer's window
                        // elapses, with the live countdown as its label.
                        Gauge(value: entry.dayProgress) {
                            Text(next.time, style: .timer)
                        }
                        .tint(accent(for: current))
                    }
            case .accessoryRectangular:
                rectangular(current: current, next: next)
            default:
                circular(current: current, next: next)
            }
        } else {
            switch family {
            case .accessoryCorner:
                Image(systemName: "moon.stars.fill")
                    .widgetLabel { Text("Open app") }
            case .accessoryInline:
                Label("Open app", systemImage: "moon.stars.fill")
            default:
                Text("Open app")
                    .font(.caption2)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    private func circular(current: Prayer, next: Prayer) -> some View {
        // The ring itself is the live, second-by-second countdown. Inside it we show the current prayer's
        // logo and a `.relative` label (e.g. "3 hr") instead of a ticking `.timer` H:MM:SS, which was too
        // wide and overflowed the small circular face.
        ProgressView(timerInterval: interval(to: next), countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            VStack(spacing: 0) {
                Image(systemName: current.image)
                    .font(.system(size: 12, weight: .medium))
                    .widgetAccentable()
                Text(next.time, style: .relative)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .progressViewStyle(.circular)
        .tint(accent(for: current))
    }

    private func rectangular(current: Prayer, next: Prayer) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: current.image)
                    .font(.subheadline)
                Text(current.displayName)
                    .font(.headline)
            }
            .foregroundColor(accent(for: current))
            .widgetAccentable()

            // Countdown and what it lands on share one baseline-aligned row so the three lines no longer
            // have the loose vertical gaps they used to.
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(next.time, style: .timer)
                    .font(.system(.title3, design: .rounded).bold())
                    .monospacedDigit()
                    .foregroundColor(accent(for: current))

                Text("\(next.displayName) \(Text(next.time, style: .time))")
                    .font(.caption2)
                    .foregroundColor(skyStyle ? .white.opacity(0.75) : .secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CountdownComplication: Widget {
    let kind: String = "CountdownComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            CountdownComplicationView(entry: entry)
                .complicationContainer(entry: entry)
        }
        .configurationDisplayName("Prayer Countdown")
        .description("The current prayer with a live countdown through its window.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular
        ])
    }
}

@main
struct AlIslamComplications: WidgetBundle {
    var body: some Widget {
        Complication()
        CountdownComplication()
    }
}
