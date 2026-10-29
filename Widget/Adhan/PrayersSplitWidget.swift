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

    /// One cell of the Prayer Grid: the symbol and name over the time, in the prayer's tier color, with
    /// no well behind it. The tab's tiled grid (a rounded well per cell, the current one filled) was
    /// ported here on 2026-10-05 and taken back out on 2026-10-19 (Abu: those widgets "got turned into
    /// completely different grids and it looked ugly"), so this is the 4.6.4 cell again.
    private func gridCell(_ prayer: Prayer) -> some View {
        let tint = prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle)
        return VStack(alignment: .center, spacing: isMedium ? 2 : nil) {
            HStack {
                Image(systemName: prayer.image)
                    .font(.subheadline)
                    .foregroundColor(tint)
                    .padding(.trailing, -5)

                Text(prayer.displayName.localizedDisplay)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(tint)
            }

            Text(prayer.time, style: .time)
                .font(.subheadline.monospacedDigit())
                .foregroundColor(tint)
        }
    }

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
                            gridCell(prayer)
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
                            gridCell(prayer)
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

                                Text(currentPrayer.displayName.localizedDisplay)
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

                                Text(nextPrayer.displayName.localizedDisplay)
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
    let kind: String = AdhanWidgetKind.PrayersWidget.rawValue

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

/// Prayer Tiles: the day's prayers as rounded tiles, the current one filled with the accent, and nothing
/// else. It is the Prayer Grid medium as 4.6.5 shipped it (the tab's tiled cell) without that version's
/// date-and-city footer (Abu, 2026-10-28, after a user found that footer too small to read): the tiles
/// take the whole widget instead. A widget of its own because Prayer Grid itself went back to the flat
/// 4.6.4 cell on 2026-10-19 and stays that way.
struct PrayerTilesEntryView: View {
    var entry: PrayersProvider.Entry
    /// true = over a sky gradient: white tiers and a white fill for the current tile (`PrayerWidgetCellWell`).
    var skyStyle: Bool = false

    /// The same gap between tiles both ways, so the grid reads as even tiles rather than rows.
    private let gap: CGFloat = 8

    /// Three across for the full day (two rows of three); a traveler's combined four go two by two.
    private var columns: Int { entry.prayers.count > 4 ? 3 : 2 }

    private var rows: [[Prayer]] {
        stride(from: 0, to: entry.prayers.count, by: columns).map {
            Array(entry.prayers[$0..<min($0 + columns, entry.prayers.count)])
        }
    }

    var body: some View {
        if entry.prayers.isEmpty {
            PrayerWidgetEmptyState(tint: skyStyle ? .white : entry.accentColor.color, skyStyle: skyStyle)
        } else {
            // Rows of tiles that each take an equal share of the height, which a LazyVGrid can't do: its
            // rows only ever hug their content.
            VStack(spacing: gap) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: gap) {
                        ForEach(row) { tile($0) }
                        // A short last row keeps every tile the same width.
                        ForEach(row.count..<columns, id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
    }

    /// One tile, as the 4.6.5 Prayer Grid drew it: the symbol and name over the time, in the prayer's tier
    /// color, the name heavy on the current one, on a well that fills for the current prayer.
    private func tile(_ prayer: Prayer) -> some View {
        let tint = prayerTierColor(for: prayer, in: entry.prayers, entry: entry, skyStyle: skyStyle)
        let current = isCurrentPrayer(prayer, entry: entry)
        return VStack(spacing: 2) {
            HStack {
                Image(systemName: prayer.image)
                    .padding(.trailing, -5)

                Text(prayer.displayName.localizedDisplay)
                    .fontWeight(current ? .heavy : .bold)
            }

            Text(prayer.time, style: .time)
                .monospacedDigit()
        }
        .font(.subheadline)
        .foregroundColor(tint)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PrayerWidgetCellWell(
            isCurrent: current,
            accent: entry.accentColor.color,
            cornerRadius: 10,
            skyStyle: skyStyle
        ))
        .accessibilityElement(children: .combine)
    }
}

struct PrayerTilesWidget: Widget {
    let kind: String = AdhanWidgetKind.PrayerTilesWidget.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerTilesEntryView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Prayer Tiles")
        .description("All of today's prayer times as tiles, with the current prayer filled in")
    }
}

/// The Prayer Tiles widget, unchanged, over the current prayer's sky gradient.
struct PrayerTilesSkyWidget: Widget {
    let kind: String = AdhanWidgetKind.PrayerTilesSkyWidget.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerTilesEntryView(entry: entry, skyStyle: true)
                .modifier(PrayerSkyChrome(entry: entry))
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Prayer Tiles Sky")
        .description("All of today's prayer times as tiles, over the current prayer's sky gradient")
    }
}
