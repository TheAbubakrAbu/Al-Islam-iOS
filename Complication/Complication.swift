import SwiftUI
import WidgetKit

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

struct PrayersEntryView: View {
    var entry: PrayersProvider.Entry
    @Environment(\.widgetFamily) private var family

    func accent(for prayer: Prayer) -> Color {
        prayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color
    }

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
        if let nextPrayer = entry.nextPrayer {
            Label {
                Text("\(nextPrayer.displayName) \(nextPrayer.time, style: .time)")
            } icon: {
                Image(systemName: nextPrayer.image)
            }
        } else {
            Label("Open app", systemImage: "moon.stars.fill")
        }
    }

    // Corner: the prayer icon at the tip, and a curved capacity Gauge along the bezel showing how far the
    // day has progressed toward the next prayer - the same "progressive" arc the battery complication uses.
    @ViewBuilder
    var corner: some View {
        if let nextPrayer = entry.nextPrayer {
            Image(systemName: nextPrayer.image)
                .font(.title3)
                .foregroundColor(accent(for: nextPrayer))
                .widgetLabel {
                    Gauge(value: entry.dayProgress) {
                        Text(nextPrayer.displayName)
                    }
                    .tint(accent(for: nextPrayer))
                }
        } else {
            Image(systemName: "moon.stars.fill")
                .foregroundColor(entry.accentColor.color)
                .widgetLabel { Text("Open app") }
        }
    }

    var circular: some View {
        ZStack {
            AccessoryWidgetBackground()

            if let nextPrayer = entry.nextPrayer {
                VStack(spacing: 1) {
                    Image(systemName: nextPrayer.image)
                        .foregroundColor(accent(for: nextPrayer))

                    Text(nextPrayer.time, style: .time)
                        .font(.caption2)
                        .foregroundColor(accent(for: nextPrayer))
                }
            } else {
                Text("Open app")
                    .font(.caption2)
                    .foregroundColor(entry.accentColor.color)
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
                        .foregroundColor(.secondary)
                }
                .foregroundColor(accent(for: currentPrayer))
                    
                Text("\(nextPrayer.displayName) at \(nextPrayer.time, style: .time)")
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(entry.accentColor.color)
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
        }
        .configurationDisplayName("Next Prayer")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular
        ])
    }
}

// MARK: - Countdown complication

/// A complication focused purely on the live countdown to the next prayer. Uses WidgetKit's self-updating
/// `Text(_, style: .timer)` / `ProgressView(timerInterval:)`, so it ticks down on its own between timeline
/// refreshes (the shared `PrayersProvider` refreshes at the next prayer time, when the target prayer rolls).
struct CountdownComplicationView: View {
    var entry: PrayersProvider.Entry
    @Environment(\.widgetFamily) private var family

    private func accent(for prayer: Prayer) -> Color {
        prayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color
    }

    /// `currentPrayer.time ... nextPrayer.time` is always valid (current is the last prayer <= now, next is
    /// the first > now), but fall back to the entry date and clamp defensively so the gauge can never get an
    /// inverted range.
    private func interval(to next: Prayer) -> ClosedRange<Date> {
        let start = entry.currentPrayer?.time ?? entry.date
        return min(start, next.time)...next.time
    }

    var body: some View {
        if let next = entry.nextPrayer {
            switch family {
            case .accessoryInline:
                Label {
                    Text("\(next.displayName) \(next.time, style: .timer)")
                } icon: {
                    Image(systemName: next.image)
                }
            case .accessoryCorner:
                Image(systemName: next.image)
                    .font(.title3)
                    .foregroundColor(accent(for: next))
                    .widgetLabel {
                        // A curved capacity Gauge (battery-style) that fills as the day advances toward the
                        // next prayer, with the live countdown as its label.
                        Gauge(value: entry.dayProgress) {
                            Text(next.time, style: .timer)
                        }
                        .tint(accent(for: next))
                    }
            case .accessoryRectangular:
                rectangular(next: next)
            default:
                circular(next: next)
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

    private func circular(next: Prayer) -> some View {
        // The ring itself is the live, second-by-second countdown. Inside it we show the prayer logo and a
        // `.relative` label (e.g. "3 hr") instead of a ticking `.timer` H:MM:SS, which was too wide and
        // overflowed the small circular face.
        ProgressView(timerInterval: interval(to: next), countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            VStack(spacing: 0) {
                Image(systemName: next.image)
                    .font(.system(size: 12))
                Text(next.time, style: .relative)
                    .font(.system(size: 12, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .progressViewStyle(.circular)
        .tint(accent(for: next))
    }

    private func rectangular(next: Prayer) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: next.image)
                    .font(.subheadline)
                Text(next.displayName)
                    .font(.headline)
            }
            .foregroundColor(accent(for: next))

            // Countdown and target time share one baseline-aligned row so the three lines no longer have
            // the loose vertical gaps they used to.
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(next.time, style: .timer)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(accent(for: next))

                Text("at \(next.time, style: .time)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
        }
        .configurationDisplayName("Prayer Countdown")
        .description("Live countdown to the next prayer.")
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
