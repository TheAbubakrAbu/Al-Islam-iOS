import SwiftUI
import WidgetKit

struct LockScreen4EntryView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
            } else {
                let prayers = Array(
                    entry.prayers
                        .suffix(Int(floor(Double(
                            entry.prayers.count / 2
                        ))))
                )
                
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
                            .fontWeight(.bold)
                    }
                    .foregroundColor((entry.currentPrayer?.nameTransliteration ?? "").contains(prayer.nameTransliteration) ? .primary : .secondary)
                }
            }
        }
        .font(.caption)
        .multilineTextAlignment(.leading)
        .lineLimit(1)
    }
}

struct LockScreen4Widget: Widget {
    let kind: String = "LockScreen4Widget"

    var body: some WidgetConfiguration {
        #if os(iOS)
        if #available(iOS 16, *) {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen4EntryView(entry: entry)
                    .widgetContainerBackground(accessory: true)
            }
            .supportedFamilies([.accessoryRectangular])
            .configurationDisplayName("Last 3 Prayer Times")
            .description("Shows the last three prayer times of the day")
        } else {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen4EntryView(entry: entry)
            }
            .supportedFamilies([.systemSmall])
            .configurationDisplayName("Last 3 Prayer Times")
            .description("Shows the last three prayer times of the day")
        }
        #endif
    }
}
