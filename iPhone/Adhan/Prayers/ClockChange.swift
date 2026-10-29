import Foundation

/// A change of the clock in the prayer times' zone: the start or end of daylight saving time, or a
/// zone moving its offset outright. The prayer list shows the coming one under the times for the week
/// before it and on the day itself, because every time on the list jumps by an hour that morning and
/// a reader who did not expect it takes the jump for a wrong calculation (Abu, 2026-10-25: "add when
/// is daylight savings and when there is a new big change in time ... underneath prayer times"). The
/// prayer scheduler also sends a heads-up the evening before (`headsUpDate`, `headsUpBody`).
///
/// A value, so `ClockChangeNoticeTests` can run it over real zones and dates. Its own file, apart from
/// the footer in ClockChangeNotice.swift, because the scheduler (SettingsAdhan.swift) compiles in the
/// widget and complication targets too, which draw none of the prayer list.
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

    // MARK: - The evening-before notification

    /// When the heads-up goes out: 6 PM on the civil day before the change, the hour the day-before
    /// Islamic date reminders use (`makeEventNotificationRequest`). The day is read on the clock
    /// before the jump, the one the change is announced on: a fall change at 24:00 Saturday (Chile's)
    /// is "tomorrow at 12:00 AM" on Saturday evening, though its instant already reads 23:00 Saturday
    /// on the new clock. `calendar` carries the zone the notification fires in.
    func headsUpDate(calendar: Calendar) -> Date? {
        var announced = calendar
        announced.timeZone = TimeZone(secondsFromGMT: offsetBefore) ?? calendar.timeZone
        var day = announced.dateComponents([.year, .month, .day], from: date)
        // Noon, not midnight: a zone whose change falls at 00:00 has no midnight that day.
        day.hour = 12
        guard let changeDay = calendar.date(from: day),
              let eve = calendar.date(byAdding: .day, value: -1, to: changeDay)
        else { return nil }
        return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: eve)
    }

    /// The heads-up's text, said from the evening before: "Daylight Saving Time ends tomorrow: clocks
    /// go back 1 hour at 2:00 AM. Prayer times will be about 1 hour earlier." The shape of the
    /// day-before Islamic date reminder ("Ramadan is tomorrow: ..."). Whole sentences per case, so each
    /// language can order its own.
    func headsUpBody(timeFormatter: DateFormatter) -> String {
        let amount = amountText
        let time = clockReading(timeFormatter)
        switch (beginsDaylightSaving, goesForward) {
        case (.some(true), true):
            return String(localized: "Daylight Saving Time begins tomorrow: clocks go forward \(amount) at \(time). Prayer times will be about \(amount) later.")
        case (.some(false), false):
            return String(localized: "Daylight Saving Time ends tomorrow: clocks go back \(amount) at \(time). Prayer times will be about \(amount) earlier.")
        case (_, true):
            return String(localized: "Clocks go forward \(amount) tomorrow at \(time). Prayer times will be about \(amount) later.")
        case (_, false):
            return String(localized: "Clocks go back \(amount) tomorrow at \(time). Prayer times will be about \(amount) earlier.")
        }
    }
}
