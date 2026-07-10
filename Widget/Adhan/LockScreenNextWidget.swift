import SwiftUI
import WidgetKit

struct LockScreen1EntryView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .font(.caption)
            } else if let nextPrayer = entry.nextPrayer {
                HStack {
                    if !nextPrayer.nameTransliteration.contains("/") {
                        Image(systemName: nextPrayer.image)
                            .font(.caption)
                            .padding(.trailing, -4)
                    }
                    
                    Text(nextPrayer.displayName)
                        .font(.headline)
                        .lineLimit(nextPrayer.nameTransliteration.contains("/") ? 2 : 1)
                }
                
                Text(nextPrayer.time, style: .time)
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
            .configurationDisplayName("Next Prayer Time")
            .description("Shows the next upcoming prayer time")
        } else {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen1EntryView(entry: entry)
            }
            .supportedFamilies([.systemSmall])
            .configurationDisplayName("Next Prayer Time")
            .description("Shows the next upcoming prayer time")
        }
        #endif
    }
}
