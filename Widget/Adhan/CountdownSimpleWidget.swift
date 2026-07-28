import SwiftUI
import WidgetKit

/// The minimal small widget: the current prayer, a big live countdown, its window's progress, and one
/// line saying what's next. Same visual language as Prayer Glance - accent header, prominent
/// monospaced timer - with strictly less on the card.
struct SimpleEntryView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: currentPrayer.image)
                        .font(.subheadline)

                    Text(currentPrayer.displayName)
                        .font(.headline)
                }
                .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)

                Spacer(minLength: 0)

                Text(nextPrayer.time, style: .timer)
                    .font(.title2.weight(.semibold).monospacedDigit())

                PrayerIntervalProgressBar(
                    current: currentPrayer,
                    next: nextPrayer,
                    entryDate: entry.date,
                    tint: entry.accentColor.color
                )

                Text("Next: \(nextPrayer.displayName) at \(Text(nextPrayer.time, style: .time))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        } else {
            PrayerWidgetEmptyState(tint: entry.accentColor.color)
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
