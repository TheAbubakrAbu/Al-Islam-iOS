import SwiftUI
import WidgetKit

struct LockScreen1EntryView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .font(.caption)
            } else if let currentPrayer = entry.currentPrayer {
                HStack {
                    if !currentPrayer.nameTransliteration.contains("/") {
                        Image(systemName: currentPrayer.image)
                            .font(.caption)
                            .padding(.trailing, -4)
                    }

                    Text(currentPrayer.displayName)
                        .font(.headline)
                        .lineLimit(currentPrayer.nameTransliteration.contains("/") ? 2 : 1)
                }

                Text(currentPrayer.time, style: .time)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .minimumScaleFactor(0.5)
        .multilineTextAlignment(.center)
    }
}

struct LockScreen1Widget: Widget {
    let kind: String = "LockScreen1Widget"

    var body: some WidgetConfiguration {
        #if os(iOS)
        if #available(iOS 16, *) {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen1EntryView(entry: entry)
                    .widgetContainerBackground(accessory: true)
            }
            .supportedFamilies([.accessoryCircular])
            .configurationDisplayName("Current Prayer Time")
            .description("Shows the current prayer and when it started")
        } else {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen1EntryView(entry: entry)
            }
            .supportedFamilies([.systemSmall])
            .configurationDisplayName("Current Prayer Time")
            .description("Shows the current prayer and when it started")
        }
        #endif
    }
}
