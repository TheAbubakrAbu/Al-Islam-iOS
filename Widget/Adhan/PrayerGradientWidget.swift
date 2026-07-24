import SwiftUI
import WidgetKit

// Home-screen widgets wearing the sky card's prayer gradient: the current prayer and the live
// countdown over the SAME two-stop gradient the in-app solar countdown paints for that prayer -
// user-customized palettes included, since both read the shared SkyPalette overrides.
//
// Three widgets wear the sky (this one plus sky twins of Prayer Countdown and Prayer Times, below),
// and the layout here is also offered on the standard widget background as "Prayer Glance".

struct PrayerGradientEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: PrayersProvider.Entry
    /// false = the identical layout on the standard widget background with accent coloring ("Prayer Glance").
    var showsSky: Bool = true

    private var hijriDate: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .medium)
    }

    /// The header color for the current prayer's icon and name. Over the sky everything stays white;
    /// on the standard background it takes the accent, matching the other prayer widgets (Shurooq keeps
    /// primary there, exactly as they do).
    private func headerColor(_ prayer: Prayer) -> Color {
        if showsSky { return .white }
        return prayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color
    }

    var body: some View {
        Group {
            if let current = entry.currentPrayer, let next = entry.nextPrayer {
                if widgetFamily == .systemMedium {
                    mediumBody(current: current, next: next)
                } else {
                    smallBody(current: current, next: next)
                }
            } else {
                Text("Open app to get prayer times")
                    .font(.caption)
                    .foregroundColor(showsSky ? .white.opacity(0.9) : entry.accentColor.color)
                    .multilineTextAlignment(.center)
            }
        }
        .modifier(PrayerSkyChrome(entry: entry, showsSky: showsSky))
    }

    private func smallBody(current: Prayer, next: Prayer) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: current.image)
                    .font(.subheadline)

                Text(current.displayName)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundColor(headerColor(current))

            Spacer(minLength: 0)

            Text(next.time, style: .timer)
                .font(.title2.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("\(next.displayName) \(shortTime(next.time))")
                .font(.caption)
                .opacity(0.9)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(hijriDate)
                .font(.caption2)
                .opacity(0.75)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func mediumBody(current: Prayer, next: Prayer) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: current.image)
                        .font(.headline)

                    Text(current.displayName)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .foregroundColor(headerColor(current))

                Text(next.time, style: .timer)
                    .font(.title.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text("Next: \(next.displayName)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(shortTime(next.time))
                    .font(.subheadline)
                    .opacity(0.9)

                Text(hijriDate)
                    .font(.caption2)
                    .opacity(0.75)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Static: this was the one per-render DateFormatter allocation in the widget set.
    private static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private func shortTime(_ date: Date) -> String {
        Self.shortTimeFormatter.string(from: date)
    }
}

// MARK: - Shared sky treatment

/// One switch for both looks: the sky gradient with white content, or the standard widget background.
/// Kept as a modifier so every sky widget resolves its gradient the same way (from the entry's current
/// prayer, through the user's SkyPalette overrides).
struct PrayerSkyChrome: ViewModifier {
    let entry: PrayersProvider.Entry
    var showsSky: Bool = true

    func body(content: Content) -> some View {
        if showsSky {
            content.modifier(PrayerSkyBackground(
                colors: Settings.shared.skyGradientColors(forPrayer: entry.currentPrayer?.nameTransliteration)
            ))
        } else {
            content.widgetContainerBackground(legacyPadding: true)
        }
    }
}

/// The gradient as the widget's container background (iOS 17's requirement), with white content and a
/// legibility treatment: a soft bottom-weighted scrim under the content plus a slightly stronger text
/// shadow - the sky keeps its colors, but white text no longer washes out against the bright daytime stops.
struct PrayerSkyBackground: ViewModifier {
    let colors: [Color]

    private var background: some View {
        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            .overlay(
                LinearGradient(
                    colors: [.black.opacity(0.10), .black.opacity(0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    func body(content: Content) -> some View {
        Group {
            if #available(iOS 17.0, *) {
                content
                    .containerBackground(for: .widget) { background }
            } else {
                ZStack {
                    background
                    content.padding()
                }
            }
        }
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1)
        .appFontDesign()
    }
}

// MARK: - The three sky widgets + the normal-background twin

struct PrayerGradientWidget: Widget {
    let kind: String = "PrayerGradientWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerGradientEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Sky")
        .description("The current prayer and time remaining, over that prayer's sky gradient - the same colors as the app's solar countdown.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// The Prayer Sky layout on the standard widget background - for anyone who loves the layout but wants
/// it to match the rest of their home screen.
struct PrayerGlanceWidget: Widget {
    let kind: String = "PrayerGlanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerGradientEntryView(entry: entry, showsSky: false)
        }
        .configurationDisplayName("Prayer Glance")
        .description("The current prayer and time remaining - the Prayer Sky layout on the standard widget background.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// The Prayer Countdown widget, unchanged, over the current prayer's sky gradient.
struct CountdownSkyWidget: Widget {
    let kind: String = "CountdownSkyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            CountdownEntryView(entry: entry, skyStyle: true)
                .modifier(PrayerSkyChrome(entry: entry))
        }
        .configurationDisplayName("Prayer Countdown Sky")
        .description("The upcoming prayer time, over the current prayer's sky gradient.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// The Prayer Times widget, unchanged, over the current prayer's sky gradient.
struct PrayersSkyWidget: Widget {
    let kind: String = "PrayersSkyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayersEntryView(entry: entry, skyStyle: true)
                .modifier(PrayerSkyChrome(entry: entry))
        }
        .configurationDisplayName("Prayer Times Sky")
        .description("All of today's prayer times, over the current prayer's sky gradient.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
