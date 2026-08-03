import SwiftUI
import WidgetKit

/// The minimal small widget: the current prayer, a big live countdown, its window's progress, and one
/// line saying what's next. Same visual language as Prayer Glance - accent header, prominent
/// monospaced timer - with strictly less on the card.
struct SimpleEntryView: View {
    var entry: PrayersProvider.Entry
    /// true = rendered inside the sky-gradient twin: everything recolors to white (accent-on-gradient
    /// is unreadable there). Layout is untouched.
    var skyStyle: Bool = false

    var body: some View {
        if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: currentPrayer.image)
                        .font(.subheadline)

                    Text(currentPrayer.displayName)
                        .font(.headline)
                }
                .foregroundColor(skyStyle ? .white : (currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color))

                Spacer(minLength: 0)

                Text(nextPrayer.time, style: .timer)
                    .font(.title2.weight(.semibold).monospacedDigit())

                PrayerIntervalProgressBar(
                    current: currentPrayer,
                    next: nextPrayer,
                    entryDate: entry.date,
                    tint: skyStyle ? .white : entry.accentColor.color
                )

                Text("Up Next: \(nextPrayer.displayName) at \(Text(nextPrayer.time, style: .time))")
                    .font(.caption2)
                    .foregroundColor(skyStyle ? .white.opacity(0.75) : .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        } else {
            PrayerWidgetEmptyState(tint: entry.accentColor.color, skyStyle: skyStyle)
        }
    }
}

struct SimpleWidget: Widget {
    let kind: String = "SimpleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            SimpleEntryView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Simple Countdown")
        .description("The current prayer and time remaining, nothing else")
    }
}

/// The Simple Countdown widget, unchanged, over the current prayer's sky gradient.
struct SimpleSkyWidget: Widget {
    let kind: String = "SimpleSkyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            SimpleEntryView(entry: entry, skyStyle: true)
                .modifier(PrayerSkyChrome(entry: entry))
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Simple Countdown Sky")
        .description("The current prayer and time remaining, over the current prayer's sky gradient")
    }
}
