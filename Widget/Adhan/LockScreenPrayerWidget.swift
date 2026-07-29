import SwiftUI
import WidgetKit

struct LockScreen2EntryView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .font(.caption)
            } else if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                HStack {
                    if !currentPrayer.nameTransliteration.contains("/") {
                        Image(systemName: currentPrayer.image)
                            .font(.caption)
                            .padding(.trailing, -4)
                    }

                    Text(currentPrayer.displayName)
                        .font(.headline)

                    Text("\(nextPrayer.time, style: .timer)")
                        .foregroundColor(.secondary)
                        .font(.footnote.monospacedDigit())
                }

                Text("\(nextPrayer.displayName) at \(nextPrayer.time, style: .time)")
                    .font(.footnote)

                // How far through the current prayer's window we are, filling live from its start to
                // the next prayer's time.
                PrayerIntervalProgressBar(
                    current: currentPrayer,
                    next: nextPrayer,
                    entryDate: entry.date,
                    tint: .primary
                )

                // The city is context, not the message - kept small and dimmed so the next prayer's
                // line above stays the row the eye lands on.
                HStack {
                    Image(systemName: "location.fill")
                        .padding(.trailing, -4)

                    Text(entry.currentCity)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .multilineTextAlignment(.leading)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

struct LockScreen2Widget: Widget {
    let kind: String = "LockScreen2Widget"

    var body: some WidgetConfiguration {
        #if os(iOS)
        if #available(iOS 16, *) {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen2EntryView(entry: entry)
                    .widgetContainerBackground(accessory: true)
            }
            .supportedFamilies([.accessoryRectangular])
            .configurationDisplayName("Current & Next Prayer")
            .description("The current prayer with its progress, what comes next, and your city")
        } else {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen2EntryView(entry: entry)
            }
            .supportedFamilies([.systemSmall])
            .configurationDisplayName("Current & Next Prayer")
            .description("The current prayer with its progress, what comes next, and your city")
        }
        #endif
    }
}
