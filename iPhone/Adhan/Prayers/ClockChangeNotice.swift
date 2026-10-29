import SwiftUI

#if os(iOS)
/// The row under the prayer times: the glyph, the headline ("Daylight Saving Time ends on Sunday,
/// November 1") and what it does to the clocks and the times. Shown while a change is within the
/// week, and on its day. See `ClockChange` (ClockChange.swift), which also words the scheduler's
/// heads-up notification the evening before.
struct ClockChangeFooter: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared

    let change: ClockChange
    /// The moment the wording is relative to ("today", "tomorrow", "went forward").
    let now: Date

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "clock.arrow.2.circlepath")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(settings.accentColor.accent2)
                .frame(width: 24, alignment: .center)
                .padding(.top, 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(headline)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Wording

    private var calendar: Calendar { Calendar.current }

    /// "Daylight Saving Time begins today" / "ends tomorrow" / "ends on Sunday, November 1"; a change that
    /// is not daylight saving reads "Clocks change ...".
    private var headline: String {
        let days = change.daysAway(from: now, calendar: calendar)
        let day = Self.dayFormatter.string(from: change.date)
        switch (change.beginsDaylightSaving, days) {
        case (true, 0): return String(localized: "Daylight Saving Time begins today")
        case (true, 1): return String(localized: "Daylight Saving Time begins tomorrow")
        case (true, _): return String(localized: "Daylight Saving Time begins on \(day)")
        case (false, 0): return String(localized: "Daylight Saving Time ends today")
        case (false, 1): return String(localized: "Daylight Saving Time ends tomorrow")
        case (false, _): return String(localized: "Daylight Saving Time ends on \(day)")
        case (nil, 0): return String(localized: "Clocks change today")
        case (nil, 1): return String(localized: "Clocks change tomorrow")
        case (nil, _): return String(localized: "Clocks change on \(day)")
        }
    }

    /// What happens to the clocks, and so to the times on the list. Past tense once today's change is
    /// behind us: the list already shows the shifted times, and "will be" would read as one more jump.
    private var detail: String {
        let amount = change.amountText
        let time = change.clockReading(DateFormatter.timeEN)
        let done = change.date <= now
        switch (change.goesForward, done) {
        case (true, false):
            return String(localized: "Clocks go forward \(amount) at \(time). Prayer times will be about \(amount) later.")
        case (false, false):
            return String(localized: "Clocks go back \(amount) at \(time). Prayer times will be about \(amount) earlier.")
        case (true, true):
            return String(localized: "Clocks went forward \(amount) at \(time). Prayer times are about \(amount) later than yesterday.")
        case (false, true):
            return String(localized: "Clocks went back \(amount) at \(time). Prayer times are about \(amount) earlier than yesterday.")
        }
    }

    /// "Sunday, November 1", in the interface's language. The calendar is set explicitly: a device on the
    /// Islamic calendar would otherwise print a Hijri day for a civil clock change.
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return formatter
    }()
}
#endif
