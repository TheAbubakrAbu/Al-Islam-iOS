import SwiftUI
import WidgetKit

struct Prayers2EntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: PrayersProvider.Entry

    func getPrayerColor(for prayer: Prayer, in prayers: [Prayer]) -> Color {
        guard let currentIndex = prayers.firstIndex(where: { $0.id == prayer.id }) else {
            return .secondary
        }

        guard let currentPrayerIndex = prayers.firstIndex(where: { $0.nameTransliteration == entry.currentPrayer?.nameTransliteration }) else {
            return .secondary
        }

        if currentIndex < currentPrayerIndex {
            return .secondary
        } else if currentIndex == currentPrayerIndex {
            return entry.accentColor.color
        } else {
            return .primary
        }
    }
    
    var hijriDate: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .full)
    }
    
    var body: some View {
        VStack {
            if entry.prayers.isEmpty {
                PrayerWidgetEmptyState(tint: entry.accentColor.color)
            } else {
                if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                    HStack {
                        Image(systemName: currentPrayer.image)
                            .foregroundColor(entry.accentColor.color)
                        
                        Text(currentPrayer.displayName)
                            .foregroundColor(entry.accentColor.color)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Text("Time left: \(nextPrayer.time, style: .timer)")
                                .font(.subheadline.monospacedDigit())
                                .frame(alignment: .trailing)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .font(.headline)
                    .padding(.vertical, 4)

                    PrayerIntervalProgressBar(
                        current: currentPrayer,
                        next: nextPrayer,
                        entryDate: entry.date,
                        tint: entry.accentColor.color
                    )
                    .padding(.bottom, 2)
                }
                
                Spacer()
                
                HStack {
                    let first3Prayers = Array(entry.prayers
                        .prefix(Int(floor(Double(
                            entry.prayers.count / 2
                        )))))
                    
                    VStack(spacing: 4) {
                        ForEach(first3Prayers) { prayer in
                            HStack {
                                Image(systemName: prayer.image)
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
                            .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                            .font(.caption)
                        }
                    }
                    
                    Divider()
                        .background(entry.accentColor.color)
                        .frame(height: 65)
                        .padding(.horizontal, 4)
                    
                    let last3Prayers = Array(entry.prayers
                        .suffix(Int(floor(Double(
                            entry.prayers.count / 2
                        )))))
                    
                    VStack(spacing: 4) {
                        ForEach(last3Prayers) { prayer in
                            HStack {
                                Image(systemName: prayer.image)
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
                            .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                            .font(.caption)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                
                Spacer()
                
                HStack {
                    if !entry.currentCity.isEmpty {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(entry.accentColor.color)
                            .padding(.horizontal, 3)
                        
                        Text(entry.currentCity)
                            .font(.caption2)
                    }
                    
                    Spacer()
                    
                    Image(AppIdentifiers.appName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .cornerRadius(2)
                }
                .padding(.vertical, 4)
            }
        }
        .lineLimit(1)
    }
}

struct Prayers2Widget: Widget {
    let kind: String = "Prayers2Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            Prayers2EntryView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Prayer Split")
        .description("Today's prayer times in two columns, with the current prayer's live countdown")
    }
}
