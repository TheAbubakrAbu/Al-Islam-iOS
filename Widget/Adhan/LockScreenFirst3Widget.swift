import SwiftUI
import WidgetKit

struct LockScreen3EntryView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
            } else {
                // Rounded UP so this widget and its "last" twin partition the day between them. The
                // old `count / 2` dropped the middle prayer from BOTH halves on an odd count, which
                // traveling mode produces (five slots once Dhuhr/Asr and Maghrib/Isha combine).
                let prayers = Array(entry.prayers.prefix((entry.prayers.count + 1) / 2))
                
                ForEach(prayers) { prayer in
                    HStack {
                        Image(systemName: prayer.image)
                            .font(.caption)
                            .frame(width: 10, alignment: .center)
                        
                        Text(prayer.displayName)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        
                        Spacer()
                        
                        Text(prayer.time, style: .time)
                            .monospacedDigit()
                            .fontWeight(.bold)
                    }
                    .foregroundColor((entry.currentPrayer?.nameTransliteration ?? "") == prayer.nameTransliteration ? .primary : .secondary)
                }
            }
        }
        .font(.caption)
        .multilineTextAlignment(.leading)
        .lineLimit(1)
    }
}

struct LockScreen3Widget: Widget {
    let kind: String = "LockScreen3Widget"

    var body: some WidgetConfiguration {
        #if os(iOS)
        if #available(iOS 16, *) {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen3EntryView(entry: entry)
                    .widgetContainerBackground(accessory: true)
            }
            .supportedFamilies([.accessoryRectangular])
            .configurationDisplayName("First 3 Prayer Times")
            .description("Shows the first three prayer times of the day")
        } else {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen3EntryView(entry: entry)
            }
            .supportedFamilies([.systemSmall])
            .configurationDisplayName("First 3 Prayer Times")
            .description("Shows the first three prayer times of the day")
        }
        #endif
    }
}
