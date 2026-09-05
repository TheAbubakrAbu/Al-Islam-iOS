import SwiftUI
import WidgetKit

struct CountdownEntryView: View {
    @Environment(\.widgetFamily) private var systemWidgetFamily
    @Environment(\.previewWidgetFamily) private var previewWidgetFamily
    /// The gallery's override first (see `previewWidgetFamily`), else WidgetKit's.
    private var widgetFamily: WidgetFamily { previewWidgetFamily ?? systemWidgetFamily }

    var entry: PrayersProvider.Entry
    /// true = this layout is rendered inside a sky-gradient widget: accent-colored elements go white
    /// (the gradient IS the accent there, and accent-on-gradient was unreadable). Layout is untouched.
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

    var hijriDate1: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .medium)
    }

    var hijriDate2: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .full)
    }

    var body: some View {
        VStack {
            if entry.prayers.isEmpty {
                PrayerWidgetEmptyState(tint: accent)
            } else {
                if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                    if widgetFamily == .systemMedium {
                        Spacer()
                        
                        Text(hijriDate2)
                            .foregroundColor(accent)
                            .font(.caption)
                        
                        Spacer()
                        
                        Divider()
                            .background(dividerTint)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: currentPrayer.image)
                                    .font(.subheadline)
                                    .foregroundColor(prayerTint(currentPrayer))
                                
                                Text(currentPrayer.displayName)
                                    .font(.headline)
                                    .foregroundColor(prayerTint(currentPrayer))
                                
                                Spacer()
                                
                                Text("Time left: \(nextPrayer.time, style: .timer)")
                                    .font(.caption.monospacedDigit())
                            }
                            .padding(.leading, 6)

                            // Fills live across the current prayer's window (its start → the next
                            // prayer), matching the countdown above it.
                            PrayerIntervalProgressBar(
                                current: currentPrayer,
                                next: nextPrayer,
                                entryDate: entry.date,
                                tint: accent
                            )
                            .padding(.leading, 6)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                        Spacer()
                    }
                    
                    if widgetFamily == .systemSmall {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(hijriDate1)
                                .foregroundColor(accent)
                                .font(.caption2)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Spacer()
                            
                            Divider()
                                .background(dividerTint)
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: currentPrayer.image)
                                    .font(.subheadline)
                                
                                Text(currentPrayer.displayName)
                                    .font(.headline)
                                    .padding(.leading, -2)
                            }
                            .foregroundColor(prayerTint(currentPrayer))
                            .padding(.bottom, -4)
                            
                            Spacer()
                            
                            HStack {
                                Text("Next:")

                                Image(systemName: nextPrayer.image)
                                    .padding(.horizontal, -6)
                                
                                Text(nextPrayer.displayName)
                            }
                            .font(.caption2)
                            .foregroundColor(prayerTint(nextPrayer))
                            
                            Text("Starts at \(nextPrayer.time, style: .time)")
                                .font(.caption2)

                            Text("Time left: \(nextPrayer.time, style: .timer)")
                                .font(.caption2.monospacedDigit())

                            PrayerIntervalProgressBar(
                                current: currentPrayer,
                                next: nextPrayer,
                                entryDate: entry.date,
                                tint: accent
                            )

                            Spacer()

                            if !entry.currentCity.isEmpty {
                                Divider()
                                    .background(dividerTint)
                                
                                Spacer()
                            
                                HStack {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(accent)
                                    
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
                                    .foregroundColor(prayerTint(nextPrayer))
                                
                                Image(systemName: nextPrayer.image)
                                    .font(.subheadline)
                                    .foregroundColor(prayerTint(nextPrayer))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 4)
                        
                        Spacer()
                        
                        Divider()
                            .background(dividerTint)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        
                        Spacer()
                        
                        HStack {
                            if !entry.currentCity.isEmpty {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(accent)
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
        .description("The current prayer, its live countdown and progress, and today's Hijri date")
    }
}
