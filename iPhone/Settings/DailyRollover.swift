import Foundation

// The day boundary every "of the day" feature shares: the Ayah, Hadith, Dua, Word, Name and
// Reminder of the Day all turn over together. With `dailyRolloverAtFajr` (the default) the boundary
// is that day's Fajr from the app's own prayer calculation, so a card read at 3 AM is still
// yesterday's, the way the Islamic day is lived; with the setting off, or with no location to
// calculate from, the boundary is local midnight. Tilawa (Jamil Hammoudeh) rolls its daily
// surfaces over at a fixed hour as a stand-in for Fajr; this app has the real time.
//
// Compiled into every target: the widget extension applies the same rule to the Fajr table the
// app writes into the shared snapshot, so the two never disagree about which day it is.
enum DailyRollover {
    /// The calendar day `date` belongs to once the boundary is applied: the start of its own day,
    /// or of the day before when `date` falls earlier than that day's Fajr.
    static func anchoredDay(for date: Date, fajr: Date?, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        if let fajr, date < fajr, let previous = calendar.date(byAdding: .day, value: -1, to: start) {
            return previous
        }
        return start
    }

    /// Whole days from the epoch to the (anchored) day, in the local calendar.
    static func index(ofDay day: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: day).day ?? 0
    }

    /// The rule applied with a table of Fajr times keyed by calendar day ("yyyy-MM-dd"), which is
    /// what the widget extension has instead of the prayer calculation.
    static func dayIndex(for date: Date, fajrByDay: [String: TimeInterval]?, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let fajr = fajrByDay?[Settings.dayKey(start)].map { Date(timeIntervalSince1970: $0) }
        return index(ofDay: anchoredDay(for: date, fajr: fajr, calendar: calendar), calendar: calendar)
    }

    /// The next moment the day turns over after `date`, from the same table.
    static func nextRollover(after date: Date, fajrByDay: [String: TimeInterval]?, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        let todayFajr = fajrByDay?[Settings.dayKey(start)].map { Date(timeIntervalSince1970: $0) }
        if let todayFajr, date < todayFajr { return todayFajr }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? date.addingTimeInterval(86_400)
        let tomorrowFajr = fajrByDay?[Settings.dayKey(tomorrow)].map { Date(timeIntervalSince1970: $0) }
        return tomorrowFajr ?? tomorrow
    }
}

extension Settings {
    /// `date`'s Fajr from the prayer calculation, or nil when the boundary is midnight (setting off,
    /// or no location yet). Memoized per (day, prayer inputs): the daily indices are read from body
    /// paths, and the prayer calculation behind them is not free. Main thread only, like the
    /// calculation itself (`_computeRawPrayers` asserts it): every caller is a view body, a
    /// main-actor store or a lifecycle hook, and the memo is a plain instance var on `Settings`.
    func dailyFajr(for date: Date = Date()) -> Date? {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
        guard dailyRolloverAtFajr else { return nil }
        let day = Calendar.current.startOfDay(for: date)
        let signature = dailyBoundarySignature
        if let memo = dailyFajrMemo, memo.day == day, memo.signature == signature { return memo.fajr }
        let fajr = getPrayerTimes(for: day, fullPrayers: true)?
            .first { $0.nameTransliteration == "Fajr" }?.time
        dailyFajrMemo = (day, signature, fajr)
        return fajr
    }

    /// Everything the Fajr time depends on, so a changed location, method, rule or offset invalidates
    /// the memos the same day (the raw prayer cache keys on the same fields).
    private var dailyBoundarySignature: String {
        let latitude = currentLocation?.latitude ?? 1000
        let longitude = currentLocation?.longitude ?? 1000
        return "\(latitude),\(longitude)|\(prayerCalculation)|\(highLatitudeRule)|\(offsetFajr)|\(customFajrAngle)"
    }

    /// The day `date` belongs to under the daily boundary (start of that day).
    func dailyAnchor(for date: Date = Date()) -> Date {
        DailyRollover.anchoredDay(for: date, fajr: dailyFajr(for: date))
    }

    /// The daily features' day counter: every "of the day" pick is `corpus[dailyDayIndex % count]`.
    func dailyDayIndex(for date: Date = Date()) -> Int {
        DailyRollover.index(ofDay: dailyAnchor(for: date))
    }

    /// "yyyy-MM-dd" of the day `date` belongs to under the daily boundary.
    func dailyDayKey(for date: Date = Date()) -> String {
        Self.dayKey(dailyAnchor(for: date))
    }

    /// When the daily features next turn over: tomorrow's Fajr (or today's, before dawn), else midnight.
    func nextDailyRollover(after date: Date = Date()) -> Date {
        let anchor = dailyAnchor(for: date)
        let next = Calendar.current.date(byAdding: .day, value: 1, to: anchor) ?? date.addingTimeInterval(86_400)
        if let fajr = dailyFajr(for: next), fajr > date { return fajr }
        if dailyRolloverAtFajr, let todayFajr = dailyFajr(for: date), todayFajr > date { return todayFajr }
        return next
    }

    /// Fajr for the next `days` calendar days keyed by day, for the widget extension, which cannot
    /// run the prayer calculation itself. Empty when the boundary is midnight. Memoized per (day,
    /// prayer inputs): both widget writers ask for it, the Quran one on every settled last-read.
    func fajrTable(days: Int = 30) -> [String: TimeInterval] {
        guard dailyRolloverAtFajr else { return [:] }
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let signature = dailyBoundarySignature
        if let memo = fajrTableMemo, memo.day == today, memo.days == days, memo.signature == signature {
            return memo.table
        }
        var table: [String: TimeInterval] = [:]
        for offset in -1..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fajr = getPrayerTimes(for: day, fullPrayers: true)?
                    .first(where: { $0.nameTransliteration == "Fajr" })?.time else { continue }
            table[Self.dayKey(day)] = fajr.timeIntervalSince1970
        }
        fajrTableMemo = (today, days, signature, table)
        return table
    }

    #if DEBUG
    /// "-dailyRolloverProbe": today's boundary as the app computes it and as the widget extension
    /// would from the written Fajr table, side by side, so their agreement is a grep and not a
    /// 4 AM test. Run once with "Daily Cards Turn Over at Fajr" on and once with it off
    /// (`-seedBool dailyRolloverAtFajr=0`).
    func logDailyRolloverProbe() {
        let now = Date()
        let table = fajrTable()
        let appIndex = dailyDayIndex(for: now)
        let tableIndex = DailyRollover.dayIndex(for: now, fajrByDay: table)
        let appNext = nextDailyRollover(after: now)
        let tableNext = DailyRollover.nextRollover(after: now, fajrByDay: table)
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        formatter.formatOptions = [.withInternetDateTime]
        let agree = appIndex == tableIndex && abs(appNext.timeIntervalSince(tableNext)) < 1
        NSLog("DAILY ROLLOVER atFajr=%d now=%@ anchor=%@ appIndex=%d tableIndex=%d appNext=%@ tableNext=%@ tableRows=%d agree=%d",
              dailyRolloverAtFajr ? 1 : 0, formatter.string(from: now), formatter.string(from: dailyAnchor(for: now)),
              appIndex, tableIndex, formatter.string(from: appNext), formatter.string(from: tableNext), table.count, agree ? 1 : 0)
        let calendar = Calendar.current
        for offset in -1...1 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else { continue }
            let key = Self.dayKey(day)
            let fromApp = dailyFajr(for: day).map { formatter.string(from: $0) } ?? "nil"
            let fromTable = table[key].map { formatter.string(from: Date(timeIntervalSince1970: $0)) } ?? "nil"
            NSLog("DAILY ROLLOVER %@ app=%@ table=%@ %@", key, fromApp, fromTable, fromApp == fromTable ? "same" : "DIFFER")
        }
    }
    #endif
}
