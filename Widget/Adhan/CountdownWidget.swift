import SwiftUI
import WidgetKit

struct CountdownEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: PrayersProvider.Entry
    
    var hijriDate1: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .medium)
    }
    
    var hijriDate2: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .full)
    }

    var body: some View {
        VStack {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .foregroundColor(entry.accentColor.color)
            } else {
                if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                    if widgetFamily == .systemMedium {
                        Spacer()
                        
                        Text(hijriDate2)
                            .foregroundColor(entry.accentColor.color)
                            .font(.caption)
                        
                        Spacer()
                        
                        Divider()
                            .background(entry.accentColor.color)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: currentPrayer.image)
                                    .font(.subheadline)
                                    .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                
                                Text(currentPrayer.displayName)
                                    .font(.headline)
                                    .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                
                                Spacer()
                                
                                Text("Time left: \(nextPrayer.time, style: .timer)")
                                    .font(.caption)
                            }
                            .padding(.leading, 6)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        
                        Spacer()
                    }
                    
                    if widgetFamily == .systemSmall {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(hijriDate1)
                                .foregroundColor(entry.accentColor.color)
                                .font(.caption2)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Spacer()
                            
                            Divider()
                                .background(entry.accentColor.color)
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: currentPrayer.image)
                                    .font(.subheadline)
                                
                                Text(currentPrayer.displayName)
                                    .font(.headline)
                                    .padding(.leading, -2)
                            }
                            .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                            .padding(.bottom, -4)
                            
                            Spacer()
                            
                            HStack {
                                Text("Next:")
                                
                                Image(systemName: nextPrayer.image)
                                    .padding(.horizontal, -6)
                                
                                Text(nextPrayer.displayName)
                            }
                            .font(.caption2)
                            .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                            
                            Text("Starts at \(nextPrayer.time, style: .time)")
                                .font(.caption2)
                            
                            Text("Time left: \(nextPrayer.time, style: .timer)")
                                .font(.caption2)
                            
                            Spacer()
                            
                            if !entry.currentCity.isEmpty && !entry.currentCity.isEmpty {
                                Divider()
                                    .background(entry.accentColor.color)
                                
                                Spacer()
                            
                                HStack {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(entry.accentColor.color)
                                    
                                    Text(entry.currentCity)
                                        .font(.caption)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .trailing) {
                            HStack {
                                Text("Starts at \(nextPrayer.time, style: .time)")
                                    .font(.caption)
                                
                                Text(nextPrayer.displayName)
                                    .font(.headline)
                                    .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                
                                Image(systemName: nextPrayer.image)
                                    .font(.subheadline)
                                    .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 4)
                        
                        Spacer()
                        
                        Divider()
                            .background(entry.accentColor.color)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        
                        Spacer()
                        
                        HStack {
                            if !entry.currentCity.isEmpty && !entry.currentCity.isEmpty {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(entry.accentColor.color)
                                    .padding(.horizontal, 3)
                                
                                Text(entry.currentCity)
                                    .font(.caption)
                            }
                            
                            Spacer()
                            
                            Image(AppIdentifiers.appName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .cornerRadius(4)
                        }
                        .padding(.horizontal, 4)
                        
                        Spacer()
                    }
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
}

struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            CountdownEntryView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Prayer Countdown")
        .description("This widget displays the upcoming prayer time")
    }
}
