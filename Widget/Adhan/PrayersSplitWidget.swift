import SwiftUI
import WidgetKit

struct PrayersEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: PrayersProvider.Entry
    /// true = this layout is rendered inside a sky-gradient widget: everything recolors to white tiers
    /// (accent-on-gradient was unreadable), past prayers dimmest, the current prayer brightest. Layout
    /// is untouched.
    var skyStyle: Bool = false

    private var accent: Color {
        skyStyle ? .white : entry.accentColor.color
    }

    private var dividerTint: Color {
        skyStyle ? .white.opacity(0.7) : entry.accentColor.color
    }

    private func prayerTint(_ prayer: Prayer) -> Color {
        if skyStyle { return .white }
        return prayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color
    }

    func getPrayerColor(for prayer: Prayer, in prayers: [Prayer]) -> Color {
        guard let currentIndex = prayers.firstIndex(where: { $0.id == prayer.id }) else {
            return skyStyle ? .white.opacity(0.45) : .secondary
        }

        guard let currentPrayerIndex = prayers.firstIndex(where: { $0.nameTransliteration == entry.currentPrayer?.nameTransliteration }) else {
            return skyStyle ? .white.opacity(0.45) : .secondary
        }

        if currentIndex < currentPrayerIndex {
            return skyStyle ? .white.opacity(0.45) : .secondary
        } else if currentIndex == currentPrayerIndex {
            return accent
        } else {
            return skyStyle ? .white.opacity(0.8) : .primary
        }
    }
    
    var hijriDate: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .full)
    }
    
    var body: some View {
        VStack {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .foregroundColor(accent)
            } else {
                if widgetFamily == .systemLarge {
                    Text(hijriDate)
                        .foregroundColor(accent)
                        .font(.caption)
                        .padding(.vertical, 4)
                    
                    Spacer()
                    
                    Divider()
                        .background(dividerTint)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                }
                
                Spacer()
                
                if entry.prayers.count == 6 {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ], spacing: 12) {
                        ForEach(entry.prayers) { prayer in
                            VStack(alignment: .center) {
                                HStack {
                                    Image(systemName: prayer.image)
                                        .font(.subheadline)
                                        .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                                        .padding(.trailing, -5)
                                    
                                    Text(prayer.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                                }
                                
                                Text(prayer.time, style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                            }
                        }
                    }
                    .padding(4)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ], spacing: 12) {
                        ForEach(entry.prayers) { prayer in
                            VStack(alignment: .center) {
                                HStack {
                                    Image(systemName: prayer.image)
                                        .font(.subheadline)
                                        .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                                        .padding(.trailing, -5)
                                    
                                    Text(prayer.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                                }
                                
                                Text(prayer.time, style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                            }
                        }
                    }
                    .padding(4)
                }
                
                Spacer()
                
                if widgetFamily == .systemLarge {
                    Divider()
                        .background(dividerTint)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                    
                    Spacer()
                    
                    VStack {
                        if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: currentPrayer.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(prayerTint(currentPrayer))
                                    
                                    Text(currentPrayer.displayName)
                                        .font(.title3)
                                        .foregroundColor(prayerTint(currentPrayer))
                                    
                                    Spacer()
                                    
                                    Text("Time left: \(nextPrayer.time, style: .timer)")
                                        .font(.caption)
                                        .padding(.trailing, 2)
                                }
                                .padding(.leading, 4)
                            }
                            
                            VStack(alignment: .trailing) {
                                HStack {
                                    Text("Starts at \(nextPrayer.time, style: .time)")
                                        .font(.caption)
                                    
                                    Text(nextPrayer.displayName)
                                        .font(.title3)
                                        .foregroundColor(prayerTint(nextPrayer))
                                    
                                    Image(systemName: nextPrayer.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(prayerTint(nextPrayer))
                                }
                                .padding(.top, -8)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(4)
                    
                    Spacer()
                    
                    Divider()
                        .background(dividerTint)
                        .padding(.bottom, 2)
                        .padding(.horizontal, 4)
                    
                    HStack {
                        if !entry.currentCity.isEmpty && !entry.currentCity.isEmpty {
                            Image(systemName: "location.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15, height: 15)
                                .foregroundColor(accent)
                                .padding(.horizontal, 3)
                            
                            Text(entry.currentCity)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Image(AppIdentifiers.appName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .cornerRadius(4)
                    }
                    .padding(4)
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

struct PrayersWidget: Widget {
    let kind: String = "PrayersWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayersEntryView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName("Prayer Times")
        .description("This widget displays the prayer times")
    }
}
