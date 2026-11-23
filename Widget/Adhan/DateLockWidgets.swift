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
// has an Arabic twin. The two-calendar and next-prayer layouts follow the interface's language instead
// (`Language.interface`): their other lines (the weekday, the Gregorian date, the next prayer) are already
// in it, and a half-English tile in an Arabic interface read worse than either language whole.

// MARK: - Hijri date alone

/// Circular: the day number under the month. Rectangular: weekday, day and month, year. Inline: the
/// day, month and year, with no weekday - the inline slot sits BESIDE the lock screen's own date line
/// rather than replacing it, so the weekday there would be the second one on that row.
@available(iOS 16.0, *)
struct HijriDateLockView: View {
    @Environment(\.widgetFamily) private var systemWidgetFamily
    @Environment(\.previewWidgetFamily) private var previewWidgetFamily
    /// The direction around the widget: the lock screen's, which the inline line has to follow.
    @Environment(\.layoutDirection) private var surroundingDirection
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
                // Day, month and year, with no weekday: the lock screen's own date line sits beside
                // this slot and already names the weekday, so repeating it ("Wed" + "Wednesday, ...")
                // spent the width that then clipped the month (Abu, 2026-10-07). The year is what
                // earns the room instead: it is the piece the system line never shows.
                HijriInlineDate(parts: parts, joinsSystemDate: !entry.isPreview)
            default:
                rectangular(parts)
            }
        }
        // The Arabic tiles lay out right to left, so a stack's leading edge is its right edge. Not the
        // inline line: it continues the lock screen's own, in that line's direction.
        .environment(\.layoutDirection, widgetFamily == .accessoryInline ? surroundingDirection
                     : language == .arabic ? .rightToLeft : .leftToRight)
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

// MARK: - The inline line

/// The inline slot's text, set out like the lock screen's own Calendar line ("Thu Nov 19 · 8 جمادى
/// الآخرة، 1448 هـ"; Abu, 2026-11-23: "i want the lock screen widget for english and arabic to look like
/// calendar"). iOS draws its own date ("Thu 19") just before this slot and joins the two with a gap
/// only, so the line read "Thu 19  10 Jumada al-Thani 1448 AH", two numbers running together. The slot
/// now opens on the middle dot Calendar puts there, and the Arabic takes Calendar's comma after the
/// month ("١٠ جمادى الآخرة، ١٤٤٨ هـ").
///
/// The dot belongs beside the system's date, wherever that sits: it comes first, in a line laid out in
/// the lock screen's direction (a strong mark for that direction opens it), and the date follows inside
/// a first-strong isolate, so an Arabic date keeps its own order in an English line and the reverse.
/// The widget gallery shows the slot on its own, with no date to join, so the preview drops the dot.
///
/// The English line is the one that runs out of room: "Thu 19  10 Jumada al-Thani 1448 AH" already
/// filled a 17 Pro's line, so where the dot does not fit beside the era, the era goes ("Thu 19 · 10
/// Jumada al-Thani 1448"; the month's name already says which calendar), and only a line too tight even
/// for that drops the dot (`ViewThatFits` takes the first text the inline slot can hold, else the last).
@available(iOS 16.0, *)
struct HijriInlineDate: View {
    @Environment(\.layoutDirection) private var lineDirection

    let parts: AdhanWidgetDateFormatting.HijriDateParts
    let joinsSystemDate: Bool

    /// "10 Jumada al-Thani 1448 AH" / "١٠ جمادى الآخرة، ١٤٤٨ هـ"
    private var date: String { written(year: parts.year) }
    /// "10 Jumada al-Thani 1448" / "١٠ جمادى الآخرة، ١٤٤٨"
    private var dateWithoutEra: String { written(year: parts.yearNumber) }

    private func written(year: String) -> String {
        parts.language == .arabic ? "\(parts.dayMonth)، \(year)" : "\(parts.dayMonth) \(year)"
    }

    var body: some View {
        if joinsSystemDate {
            ViewThatFits(in: .horizontal) {
                Text(verbatim: joined(date))
                Text(verbatim: joined(dateWithoutEra))
                Text(verbatim: dateWithoutEra)
            }
        } else {
            Text(verbatim: date)
                .environment(\.layoutDirection, parts.language == .arabic ? .rightToLeft : .leftToRight)
        }
    }

    /// The dot after a strong mark for the line's direction, then the date in a first-strong isolate.
    /// An en space (U+2002) after the dot, not a word space: the gap iOS leaves before the slot is about
    /// half the font size, and Calendar's dot sits evenly between its two dates.
    private func joined(_ date: String) -> String {
        let mark = lineDirection == .rightToLeft ? "\u{200F}" : "\u{200E}"
        return "\(mark)·\u{2002}\u{2068}\(date)\u{2069}"
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
        let hijri = AdhanWidgetDateFormatting.hijriParts(for: entry, language: .interface)

        if widgetFamily == .accessoryInline {
            // The Hijri date ALONE, and no symbol. The inline slot does not stand on its own: it sits
            // beside the lock screen's own date line, which is already showing the civil date ("Wed 7").
            // Printing a Gregorian date here said it twice ("Wed 7  26 Rabi al-Thani · Oct 7", Abu
            // 2026-10-07) and the extra width is what clips the line - the system truncates the pair from
            // the leading edge, so the duplicate pushed the part worth reading off the screen. The Hijri
            // date is the only thing in this widget the system line cannot say, so it gets the whole slot;
            // a symbol would spend 1-2 characters of that width restating "date" next to a visible date.
            // The two calendars still read as a pair: the slot opens on Calendar's middle dot.
            HijriInlineDate(parts: hijri, joinsSystemDate: !entry.isPreview)
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
            let headline = String(localized: "Next: \(next.displayName.localizedDisplay) at \(AdhanWidgetDateFormatting.shortTimeFormatter.string(from: next.time))")

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

                    Text(AdhanWidgetDateFormatting.hijriParts(for: entry, language: .interface).dayMonthYear)
                        .font(.footnote)

                    // The city a size under caption2, so the date above can be a size bigger (Abu,
                    // 2026-10-18), the Current & Next widget's rule.
                    if !entry.currentCity.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")

                            Text(entry.currentCity)
                        }
                        .font(.system(size: 10))
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
