import SwiftUI
import WidgetKit

struct Prayers2EntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: PrayersProvider.Entry
    /// true = this layout is rendered inside a sky-gradient widget: everything recolors to white tiers
    /// (accent-on-gradient was unreadable), past prayers dimmest, the current prayer brightest. Layout
    /// is untouched.
    var skyStyle: Bool = false

    private var accent: Color {
        skyStyle ? .white : entry.accentColor.color
    }

    
    var hijriDate: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .full)
    }
    
    var body: some View {
        VStack {
            if entry.prayers.isEmpty {
                PrayerWidgetEmptyState(tint: accent, skyStyle: skyStyle)
            } else {
                if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                    HStack {
                        Image(systemName: currentPrayer.image)
                            .foregroundColor(accent)
                        
                        Text(currentPrayer.displayName)
                            .foregroundColor(accent)
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
                        tint: accent
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
                            .foregroundColor(prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle))
                            .font(.caption)
                        }
                    }
                    
                    Divider()
                        .background(skyStyle ? Color.white.opacity(0.7) : entry.accentColor.color)
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
                            .foregroundColor(prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle))
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
                            .foregroundColor(accent)
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

/// The Prayer Split widget, unchanged, over the current prayer's sky gradient.
struct Prayers2SkyWidget: Widget {
    let kind: String = "Prayers2SkyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            Prayers2EntryView(entry: entry, skyStyle: true)
                .modifier(PrayerSkyChrome(entry: entry))
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Prayer Split Sky")
        .description("Today's prayer times in two columns, over the current prayer's sky gradient")
    }
}
