import SwiftUI
import WidgetKit

// Lock-screen date widgets (iOS 16+): the Hijri date alone, in English or in Arabic; the Hijri and Gregorian
// dates together; and the next prayer with the date and city. They ride the prayers provider because the
// Hijri day depends on the same two settings the prayer widgets already carry (the day adjustment and the
// switch-at-Maghrib rule), and its timeline already flips an entry at civil midnight and at Maghrib, the two
// moments the date can change.
//
// Arabic is one kind per layout rather than a setting: a lock-screen widget can't be configured without an
// App Intent, and a separate kind puts both languages in the gallery at once. Only the Hijri-alone widget
// has an Arabic twin. The two-calendar and next-prayer layouts mix the date with English lines, and a
// half-Arabic tile reads worse than either language whole.

// MARK: - Hijri date alone

/// Circular: the day number under the month. Rectangular: weekday, day and month, year. Inline: the
/// day, month and year, with no weekday - the inline slot sits BESIDE the lock screen's own date line
/// rather than replacing it, so the weekday there would be the second one on that row.
@available(iOS 16.0, *)
struct HijriDateLockView: View {
    @Environment(\.widgetFamily) private var systemWidgetFamily
    @Environment(\.previewWidgetFamily) private var previewWidgetFamily
    /// The gallery's override first (see `previewWidgetFamily`), else WidgetKit's.
    private var widgetFamily: WidgetFamily { previewWidgetFamily ?? systemWidgetFamily }

    var entry: PrayersProvider.Entry
    var language: AdhanWidgetDateFormatting.Language

    var body: some View {
        let parts = AdhanWidgetDateFormatting.hijriParts(for: entry, language: language)

        Group {
            switch widgetFamily {
            case .accessoryCircular:
                circular(parts)
            case .accessoryInline:
                // Day, month and year, with no weekday and no symbol: the lock screen's own date line
                // sits beside this slot and already names the weekday, so repeating it ("Wed" +
                // "Wednesday, ...") spent the width that then clipped the month (Abu, 2026-10-07). The
                // year is what earns the room instead - it is the piece the system line never shows.
                Text(parts.dayMonthYear)
            default:
                rectangular(parts)
            }
        }
        // The Arabic tiles lay out right to left, so a stack's leading edge is its right edge and the
        // inline symbol sits at the start of the reading direction.
        .environment(\.layoutDirection, language == .arabic ? .rightToLeft : .leftToRight)
    }

    private func circular(_ parts: AdhanWidgetDateFormatting.HijriDateParts) -> some View {
        VStack(spacing: -2) {
            Text(parts.month)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(parts.day)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 6)
        .multilineTextAlignment(.center)
    }

    private func rectangular(_ parts: AdhanWidgetDateFormatting.HijriDateParts) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(parts.weekday)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(parts.dayMonth)
                .font(.headline)

            Text(parts.year)
                .font(.caption)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 16.0, *)
struct HijriDateLockWidget: Widget {
    let kind: String = AdhanWidgetKind.HijriDateLockWidget.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            HijriDateLockView(entry: entry, language: .english)
                .widgetContainerBackground(accessory: true)
        }
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        .configurationDisplayName("Hijri Date")
        .description("Today's Hijri date on its own; the inline size sits beside the date above the clock")
    }
}

@available(iOS 16.0, *)
struct HijriDateArabicLockWidget: Widget {
    let kind: String = AdhanWidgetKind.HijriDateArabicLockWidget.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            HijriDateLockView(entry: entry, language: .arabic)
                .widgetContainerBackground(accessory: true)
        }
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        .configurationDisplayName("Hijri Date (Arabic)")
        .description("Today's Hijri date in Arabic script and numerals; the inline size sits beside the date above the clock")
    }
}

// MARK: - Hijri and Gregorian together

/// Rectangular: the clock's weekday, the Hijri date, the Gregorian date. Inline: the Hijri date alone
/// ("23 Rabi al-Awwal 1448 AH") - the civil date it is paired with is already on the lock screen's own
/// date line, immediately beside this slot.
@available(iOS 16.0, *)
struct DualCalendarLockView: View {
    @Environment(\.widgetFamily) private var systemWidgetFamily
    @Environment(\.previewWidgetFamily) private var previewWidgetFamily
    private var widgetFamily: WidgetFamily { previewWidgetFamily ?? systemWidgetFamily }

    var entry: PrayersProvider.Entry

    var body: some View {
        let hijri = AdhanWidgetDateFormatting.hijriParts(for: entry, language: .english)

        if widgetFamily == .accessoryInline {
            // The Hijri date ALONE, and no symbol. The inline slot does not stand on its own: it sits
            // beside the lock screen's own date line, which is already showing the civil date ("Wed 7").
            // Printing a Gregorian date here said it twice ("Wed 7  26 Rabi al-Thani · Oct 7", Abu
            // 2026-10-07) and the extra width is what clips the line - the system truncates the pair from
            // the leading edge, so the duplicate pushed the part worth reading off the screen. The Hijri
            // date is the only thing in this widget the system line cannot say, so it gets the whole slot;
            // a symbol would spend 1-2 characters of that width restating "date" next to a visible date.
            Text(hijri.dayMonthYear)
        } else {
            VStack(alignment: .leading, spacing: 1) {
                // The weekday the clock is on (`entry.date`): the Hijri day may already have turned at
                // Maghrib, the civil one has not, and this line sits over both.
                Text(AdhanWidgetDateFormatting.gregorianWeekdayFormatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(hijri.dayMonthYear)
                    .font(.subheadline.weight(.semibold))

                Text(AdhanWidgetDateFormatting.gregorianLongFormatter.string(from: entry.date))
                    .font(.caption)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@available(iOS 16.0, *)
struct DualCalendarLockWidget: Widget {
    let kind: String = AdhanWidgetKind.DualCalendarLockWidget.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            DualCalendarLockView(entry: entry)
                .widgetContainerBackground(accessory: true)
        }
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
        .configurationDisplayName("Hijri & Gregorian")
        .description("Today's date in both calendars; the inline size shows the Hijri date beside the date above the clock")
    }
}

// MARK: - Next prayer with the date and city

/// Rectangular: the next prayer and its time, the Hijri date, the city. Inline: the next prayer and its
/// time with the prayer's symbol.
@available(iOS 16.0, *)
struct NextPrayerDateLockView: View {
    @Environment(\.widgetFamily) private var systemWidgetFamily
    @Environment(\.previewWidgetFamily) private var previewWidgetFamily
    private var widgetFamily: WidgetFamily { previewWidgetFamily ?? systemWidgetFamily }

    var entry: PrayersProvider.Entry

    var body: some View {
        if let next = entry.nextPrayer {
            let headline = "Next: \(next.displayName) at \(AdhanWidgetDateFormatting.shortTimeFormatter.string(from: next.time))"

            if widgetFamily == .accessoryInline {
                Label(headline, systemImage: next.image)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: next.image)
                            .font(.caption)

                        Text(headline)
                            .font(.headline)
                    }

                    Text(AdhanWidgetDateFormatting.hijriParts(for: entry, language: .english).dayMonthYear)
                        .font(.caption)

                    if !entry.currentCity.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")

                            Text(entry.currentCity)
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text("Open app to get prayer times")
                .font(.caption)
        }
    }
}

@available(iOS 16.0, *)
struct NextPrayerDateLockWidget: Widget {
    let kind: String = AdhanWidgetKind.NextPrayerDateLockWidget.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            NextPrayerDateLockView(entry: entry)
                .widgetContainerBackground(accessory: true)
        }
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
        .configurationDisplayName("Next Prayer & Date")
        .description("The next prayer and its time, with today's Hijri date and your city")
    }
}
