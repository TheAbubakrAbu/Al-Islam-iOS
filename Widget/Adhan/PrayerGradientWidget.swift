import SwiftUI
import WidgetKit

// Home-screen widgets wearing the sky card's prayer gradient: the current prayer and the live
// countdown over the SAME two-stop gradient the in-app solar countdown paints for that prayer -
// user-customized palettes included, since both read the shared SkyPalette overrides.

struct PrayerGradientEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: PrayersProvider.Entry

    private var gradientColors: [Color] {
        Settings.shared.skyGradientColors(forPrayer: entry.currentPrayer?.nameTransliteration)
    }

    private var hijriDate: String {
        AdhanWidgetDateFormatting.hijriDate(for: entry, style: .medium)
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
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
        .modifier(PrayerGradientBackground(colors: gradientColors))
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

    private func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// The gradient as the widget's container background (iOS 17's requirement), with white content and a
/// soft legibility shadow - the sky card's own treatment.
private struct PrayerGradientBackground: ViewModifier {
    let colors: [Color]

    private var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    func body(content: Content) -> some View {
        Group {
            if #available(iOS 17.0, *) {
                content
                    .containerBackground(for: .widget) { gradient }
            } else {
                ZStack {
                    gradient
                    content.padding()
                }
            }
        }
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
        .appFontDesign()
    }
}

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
