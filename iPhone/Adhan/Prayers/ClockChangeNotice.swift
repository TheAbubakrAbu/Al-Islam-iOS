import SwiftUI

/// A change of the clock in the prayer times' zone: the start or end of daylight saving time, or a
/// zone moving its offset outright. The prayer list shows the coming one under the times for the week
/// before it and on the day itself, because every time on the list jumps by an hour that morning and
/// a reader who did not expect it takes the jump for a wrong calculation (Abu, 2026-10-25: "add when
/// is daylight savings and when there is a new big change in time ... underneath prayer times").
///
/// A value, so `ClockChangeNoticeTests` can run it over real zones and dates.
struct ClockChange: Equatable {
    /// The instant the clocks change.
    let date: Date
    /// The zone's offset after the change minus its offset before: positive when the clocks go forward
    /// (every prayer then reads later than the day before), negative when they go back.
    let delta: TimeInterval
    /// true when the change BEGINS daylight saving time, false when it ends it, nil when daylight saving
    /// is not what changes (a government moving the zone's standard offset).
    let beginsDaylightSaving: Bool?
    /// The zone's offset from GMT, in seconds, just before the change: the clock the change is
    /// announced on. "Clocks go back at 2:00 AM" names the reading before the jump; the instant
    /// itself, formatted in the zone, already reads 1:00 AM.
    let offsetBefore: Int

    var goesForward: Bool { delta > 0 }
    var isDaylightSaving: Bool { beginsDaylightSaving != nil }

    /// Whole days from the start of `today` to the change's civil day: 0 on the day itself (whether the
    /// change is still ahead or already behind), 1 for tomorrow.
    func daysAway(from today: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: date)).day ?? 0
    }

    /// The change on or after the civil day of `now` that falls within `horizonDays` days of it, or nil.
    /// Today's change is still found after it has happened (the notice stays up for the day, worded in
    /// the past), which is why the search starts at the start of the day rather than at `now`.
    static func next(after now: Date, in zone: TimeZone = .current, horizonDays: Int = 7,
                     calendar base: Calendar = Calendar(identifier: .gregorian)) -> ClockChange? {
        var calendar = base
        calendar.timeZone = zone
        let startOfToday = calendar.startOfDay(for: now)
        // A transition at the very first second of the day is "after" one second before it.
        guard let transition = zone.nextDaylightSavingTimeTransition(after: startOfToday.addingTimeInterval(-1)),
              let limit = calendar.date(byAdding: .day, value: horizonDays + 1, to: startOfToday),
              transition < limit
        else { return nil }
        let before = transition.addingTimeInterval(-1)
        let offsetBefore = zone.secondsFromGMT(for: before)
        let delta = TimeInterval(zone.secondsFromGMT(for: transition) - offsetBefore)
        guard delta != 0 else { return nil }
        let wasSaving = zone.isDaylightSavingTime(for: before)
        let isSaving = zone.isDaylightSavingTime(for: transition)
        return ClockChange(date: transition, delta: delta,
                           beginsDaylightSaving: wasSaving == isSaving ? nil : isSaving,
                           offsetBefore: offsetBefore)
    }

    /// The change's instant as the clock read it before the jump (see `offsetBefore`), in the app's
    /// time style: "2:00 AM" for both of the US changes.
    func clockReading(_ formatter: DateFormatter) -> String {
        guard let old = formatter.copy() as? DateFormatter else { return formatter.string(from: date) }
        old.timeZone = TimeZone(secondsFromGMT: offsetBefore) ?? formatter.timeZone
        return old.string(from: date)
    }

    /// "1 hour", "2 hours", "30 minutes": the size of the jump, as whole sentences keyed for the catalog.
    var amountText: String {
        let seconds = Int(abs(delta).rounded())
        if seconds % 3600 == 0 {
            let hours = seconds / 3600
            return hours == 1 ? String(localized: "1 hour") : String(localized: "\(hours) hours")
        }
        return String(localized: "\(seconds / 60) minutes")
    }
}

#if os(iOS)
/// The row under the prayer times: the glyph, the headline ("Daylight Saving Time ends on Sunday,
/// November 1") and what it does to the clocks and the times. Shown while a change is within the
/// week, and on its day. See `ClockChange`.
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
