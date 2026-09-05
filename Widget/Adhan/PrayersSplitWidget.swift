import SwiftUI
import WidgetKit

struct PrayersEntryView: View {
    @Environment(\.widgetFamily) private var systemWidgetFamily
    @Environment(\.previewWidgetFamily) private var previewWidgetFamily
    /// The gallery's override first (see `previewWidgetFamily`), else WidgetKit's.
    private var widgetFamily: WidgetFamily { previewWidgetFamily ?? systemWidgetFamily }

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

    
    var hijriDate: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .full)
    }
    
    /// The medium tile has 126pt for two grid rows plus the date-and-city line: the stack's default
    /// gaps and the cells' default text spacing cost 30pt between them and squeezed that line to half
    /// size, so the medium size runs tight and the large keeps the defaults.
    private var isMedium: Bool { widgetFamily == .systemMedium }

    var body: some View {
        VStack(spacing: isMedium ? 2 : nil) {
            if entry.prayers.isEmpty {
                PrayerWidgetEmptyState(tint: accent, skyStyle: skyStyle)
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
                    ], spacing: isMedium ? 6 : 12) {
                        ForEach(entry.prayers) { prayer in
                            VStack(alignment: .center, spacing: isMedium ? 2 : nil) {
                                HStack {
                                    Image(systemName: prayer.image)
                                        .font(.subheadline)
                                        .foregroundColor(prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle))
                                        .padding(.trailing, -5)
                                    
                                    Text(prayer.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle))
                                }
                                
                                Text(prayer.time, style: .time)
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundColor(prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, isMedium ? 0 : 4)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ], spacing: isMedium ? 6 : 12) {
                        ForEach(entry.prayers) { prayer in
                            VStack(alignment: .center, spacing: isMedium ? 2 : nil) {
                                HStack {
                                    Image(systemName: prayer.image)
                                        .font(.subheadline)
                                        .foregroundColor(prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle))
                                        .padding(.trailing, -5)
                                    
                                    Text(prayer.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle))
                                }
                                
                                Text(prayer.time, style: .time)
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundColor(prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, isMedium ? 0 : 4)
                }
                
                Spacer()

                if isMedium {
                    // The medium grid's one line of context, the date and city along the bottom (the
                    // large size carries them in its own header and footer).
                    PrayerWidgetContextRow(entry: entry, skyStyle: skyStyle)
                        .padding(.horizontal, 4)
                }

                if widgetFamily == .systemLarge {
                    Divider()
                        .background(dividerTint)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                    
                    Spacer()
                    
                    // ONE stack with an explicit spacing, so the gap above the bar and the gap below
                    // it are the same 6pt by construction. It used to be two nested VStacks at their
                    // DEFAULT spacing with the bar carrying its own vertical padding and the next-
                    // prayer row carrying a `.padding(.top, -8)` to claw some of it back - three
                    // numbers that never agreed, which is why the bar sat visibly closer to the row
                    // above it than the one below.
                    VStack(spacing: 6) {
                        if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
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
                                    .font(.caption.monospacedDigit())
                                    .padding(.trailing, 2)
                            }
                            .padding(.leading, 4)

                            // The current prayer's window filling live, bridging the current row
                            // above and the next row below.
                            PrayerIntervalProgressBar(
                                current: currentPrayer,
                                next: nextPrayer,
                                entryDate: entry.date,
                                tint: skyStyle ? .white : entry.accentColor.color
                            )
                            .padding(.horizontal, 4)

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
                        if !entry.currentCity.isEmpty {
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
        .configurationDisplayName("Prayer Grid")
        .description("All of today's prayer times in a grid; the large size adds the current and next prayer")
    }
}
