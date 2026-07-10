import SwiftUI
import WidgetKit

struct SimpleEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: PrayersProvider.Entry
    
    var hijriDate: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .medium)
    }

    var body: some View {
        VStack {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .foregroundColor(entry.accentColor.color)
            } else {
                if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                    VStack(alignment: .leading) {
                        Text("Time left: \(nextPrayer.time, style: .timer)")
                            .font(.caption2)
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Image(systemName: currentPrayer.image)
                                .font(.title2)
                            
                            Text(currentPrayer.displayName)
                                .font(.headline)
                                .padding(.vertical, 1)
                        }
                        .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                        .padding(.bottom, -4)
                        
                        HStack {
                            Text("Next:")
                            
                            Image(systemName: nextPrayer.image)
                                .padding(.horizontal, -6)
                            
                            Text(nextPrayer.displayName)
                        }
                        .font(.caption2)
                        .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                        .padding(.vertical, 1)
                        
                        Text("Starts at \(nextPrayer.time, style: .time)")
                            .font(.caption2)
                    }
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.85)
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
        .configurationDisplayName("Simple Prayer Countdown")
        .description("This widget displays the upcoming prayer time in a simple way")
    }
}
