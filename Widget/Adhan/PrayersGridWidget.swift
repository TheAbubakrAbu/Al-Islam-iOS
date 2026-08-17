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
                    // Header and bar grouped at an explicit 6pt rather than left to the outer
                    // stack's default spacing plus two separate paddings.
                    VStack(spacing: 6) {
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

                        PrayerIntervalProgressBar(
                            current: currentPrayer,
                            next: nextPrayer,
                            entryDate: entry.date,
                            tint: accent
                        )
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                HStack {
                    // Rounded UP, and the second column takes the remainder. The old
                    // `prefix(count/2)` + `suffix(count/2)` silently DROPPED the middle prayer on an
                    // odd count - which traveling mode produces (Dhuhr/Asr and Maghrib/Isha combine
                    // to five slots) - and left the two columns unequal heights on top of that.
                    let split = (entry.prayers.count + 1) / 2
                    let leftColumn = Array(entry.prayers.prefix(split))
                    let rightColumn = Array(entry.prayers.dropFirst(split))

                    prayerColumn(leftColumn)

                    // Stretches to the columns beside it instead of being pinned to 65pt, which was
                    // right for exactly three default-sized rows and wrong for every other case
                    // (larger Dynamic Type, or a two-row column).
                    Divider()
                        .background(skyStyle ? Color.white.opacity(0.7) : entry.accentColor.color)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 4)

                    prayerColumn(rightColumn)
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

    /// One half of the split list. Flexible gaps between rows so a 3-row column and a 2-row column
    /// still span the same height either side of the divider - but ONLY for the full six-prayer list.
    /// Traveling mode's combined list is 4 rows (2+2), and spreading those across the tile read as
    /// rows adrift in empty space (user rule: don't equalize heights for traveling mode) - a short
    /// list keeps a plain fixed-spacing stack centered in the band instead.
    private func prayerColumn(_ prayers: [Prayer]) -> some View {
        let spread = entry.prayers.count >= 5
        return VStack(spacing: spread ? 0 : 4) {
            ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                if spread, index > 0 { Spacer(minLength: 2) }

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
        .frame(maxHeight: spread ? .infinity : nil)
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
