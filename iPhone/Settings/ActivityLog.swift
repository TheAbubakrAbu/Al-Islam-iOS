import Foundation
import Combine

// What the reader actually did, day by day: ayahs marked read, surahs played, dhikr counted, hadiths
// opened. One small day-bucketed log feeds the profile's activity card (today's rings, the week,
// the twelve-week grid), the analytics screen, the unified streak, and the streak nudge. Nothing
// here is a second copy of a store: the khatm set, the play counters, the tasbih and the hadith
// last-read remain the truth for their own screens; this only remembers WHEN.
//
// Days are the daily-rollover days (Fajr-anchored by default), so a 4 AM tahajjud session lands
// in the night it belongs to. Modelled on Tilawa's activity store (Jamil Hammoudeh), including
// the streak's monthly freeze: one missed day per calendar month is forgiven.

enum ActivityKind: String, CaseIterable, Codable {
    case read, listen, dhikr, hadith

    var title: String {
        switch self {
        case .read: return "Read"
        case .listen: return "Listen"
        case .dhikr: return "Dhikr"
        case .hadith: return "Hadith"
        }
    }

    var systemImage: String {
        switch self {
        case .read: return "book.fill"
        case .listen: return "headphones"
        case .dhikr: return "circles.hexagonpath.fill"
        case .hadith: return "text.book.closed.fill"
        }
    }

    /// "12 ayahs", "1 surah", "100 counts", "3 hadiths".
    func amount(_ n: Int) -> String {
        switch self {
        case .read: return "\(n) ayah\(n == 1 ? "" : "s")"
        case .listen: return "\(n) surah\(n == 1 ? "" : "s")"
        case .dhikr: return "\(n) count\(n == 1 ? "" : "s")"
        case .hadith: return "\(n) hadith\(n == 1 ? "" : "s")"
        }
    }
}

final class ActivityLog: ObservableObject {
    static let shared = ActivityLog()

    struct Streak: Equatable {
        var current = 0
        var longest = 0
        /// Whether this month's one freeze has been spent covering a missed day.
        var freezeUsed = false
        var activeToday = false
    }

    /// One day of the summary's week strip.
    struct DayCounts: Equatable {
        let key: String
        let counts: [ActivityKind: Int]
        /// "S", "M", ... for the bar's label, resolved here so no body needs a formatter.
        let weekdayLetter: String
        var total: Int { counts.values.reduce(0, +) }
    }

    /// What the dashboard reads: today's counts, the streak, the last thirteen weeks of totals and
    /// the last seven days by kind, maintained by the log itself (one recompute per `apply` batch
    /// and per day change) instead of walked out of `days` by every body evaluation (the streak
    /// alone is a 400-day walk, and the card ran it per body).
    struct Summary: Equatable {
        var todayKey = ""
        var today: [ActivityKind: Int] = [:]
        var streak = Streak()
        /// Totals of the last `recentDays` days, oldest first, ending today.
        var recentTotals: [Int] = []
        /// Calendar weekday of today (1 = Sunday), so the heatmap can pad back to a Sunday.
        var todayWeekday = 1
        var week: [DayCounts] = []
        var activeDayCount = 0
    }

    /// Thirteen weeks: twelve for the heatmap plus the partial week it pads back to a Sunday with.
    static let recentDays = 91

    /// Day key ("yyyy-MM-dd", rollover-anchored) -> kind raw value -> count. Not published: the
    /// summary is, once per batch; the analytics screen reads this when the summary publishes.
    private(set) var days: [String: [String: Int]] = [:]

    /// The maintained summary. The only publisher of this object.
    @Published private(set) var summary = Summary()

    /// Posted on the main thread after a batch of marks lands (the watch's sync listens: a surah
    /// read on the wrist reaches the phone's streak through `mirrorPayload`, decision C of the
    /// Tilawa Guide, 2026-09-07).
    static let didChangeNotification = Notification.Name("ActivityLogDidChange")

    /// The paired watch's own days, as it last sent them (the phone only). Kept apart from `days`
    /// so a resend replaces rather than doubles; every read below sums the two.
    private var watchDays: [String: [String: Int]] = [:]

    private static let fileName = "activity-log.json"
    private static let watchFileName = "activity-log-watch.json"
    private static let keepDays = 400
    private var saveWork: DispatchWorkItem?
    private var storageObserver: StoredContentObserver?

    /// Every file write of this log, in order. A global queue ran them in no order at all, which
    /// was harmless while the only writer was this object and is not once a restore can replace
    /// the file: `flushSynchronously` and `reloadFromStorage` wait here for the writes ahead of
    /// them, so an older write still in flight can never land on top of a restored file.
    private static let ioQueue = DispatchQueue(label: "ActivityLog.io", qos: .utility)

    private init() {
        load()
        storageObserver = StoredContentObserver(
            flush: { ActivityLog.shared.flushSynchronously() },
            reload: { ActivityLog.shared.reloadFromStorage() }
        )
        #if DEBUG
        // "-activitySeed": six weeks of plausible days (with a few gaps), for screenshots of the
        // profile's activity card and the analytics screen. In memory only; nothing is written.
        if ProcessInfo.processInfo.arguments.contains("-activitySeed") {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            var seeded: [String: [String: Int]] = [:]
            for back in 0..<45 where back % 9 != 4 {
                guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { continue }
                seeded[Settings.dayKey(day)] = [
                    ActivityKind.read.rawValue: Int.random(in: 3...40),
                    ActivityKind.listen.rawValue: Int.random(in: 0...2),
                    ActivityKind.dhikr.rawValue: Int.random(in: 0...150),
                    ActivityKind.hadith.rawValue: Int.random(in: 0...4),
                ]
            }
            days = seeded
        }
        #endif
        ObjectPublishCounter.attach(self, label: "ActivityLog")
        #if DEBUG
        // "-activityBatchProbe": fifteen read marks in one run-loop turn, three seconds after the
        // reveal (a page turn's worth), to prove they land as ONE publish ("OBJECT PUBLISH ActivityLog 1").
        if ProcessInfo.processInfo.arguments.contains("-activityBatchProbe") {
            Task { @MainActor in
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                for _ in 0..<15 { self.record(.read) }
            }
        }
        #endif
        // The summary reads the daily boundary, which is main-only; a first touch from another
        // thread (a hadith opened off-main) defers it one main-queue turn.
        if Thread.isMainThread {
            refreshSummary()
        } else {
            DispatchQueue.main.async { self.refreshSummary() }
        }
    }

    // MARK: Recording

    private var pending: [ActivityKind: Int] = [:]
    private var applyScheduled = false

    /// Adds `count` of `kind` to today. Safe from any thread; the marks of one run-loop turn (a
    /// page turn's fifteen khatm marks) land together on the next turn: one write, one summary,
    /// one publish, one save schedule.
    func record(_ kind: ActivityKind, count: Int = 1) {
        guard count > 0 else { return }
        if Thread.isMainThread {
            enqueue(kind, count: count)
        } else {
            DispatchQueue.main.async { self.enqueue(kind, count: count) }
        }
    }

    private func enqueue(_ kind: ActivityKind, count: Int) {
        pending[kind, default: 0] += count
        guard !applyScheduled else { return }
        applyScheduled = true
        DispatchQueue.main.async { self.applyPending() }
    }

    private func applyPending() {
        applyScheduled = false
        let batch = pending
        pending.removeAll()
        guard !batch.isEmpty else { return }
        let key = Settings.shared.dailyDayKey()
        var day = days[key] ?? [:]
        for (kind, count) in batch {
            day[kind.rawValue, default: 0] += count
        }
        days[key] = day
        refreshSummary()
        scheduleSave()
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    // MARK: The watch

    /// This device's last thirty active days, for the watch to send the phone: small enough to ride
    /// in every application context, whole enough that a resend is idempotent.
    func mirrorPayload(limit: Int = 30) -> [String: [String: Int]] {
        var out: [String: [String: Int]] = [:]
        for key in days.keys.sorted().suffix(limit) {
            guard let counts = days[key], counts.values.reduce(0, +) > 0 else { continue }
            out[key] = counts
        }
        return out
    }

    /// The watch's days as it last sent them, replacing what it sent before, day by day. Main
    /// thread only (the summary is). Returns whether anything changed.
    @discardableResult
    func mergeWatchDays(_ incoming: [String: [String: Int]]) -> Bool {
        var changed = false
        for (key, counts) in incoming where watchDays[key] != counts {
            watchDays[key] = counts
            changed = true
        }
        guard changed else { return false }
        refreshSummary()
        if let url = Self.watchFileURL {
            let snapshot = watchDays
            Self.ioQueue.async {
                guard let data = try? JSONEncoder().encode(snapshot) else { return }
                try? data.write(to: url, options: .atomic)
            }
        }
        return true
    }

    // MARK: Reading

    func count(_ kind: ActivityKind, on key: String) -> Int {
        (days[key]?[kind.rawValue] ?? 0) + (watchDays[key]?[kind.rawValue] ?? 0)
    }

    /// Every kind's count for the day, in `ActivityKind.allCases` order.
    func counts(on key: String) -> [ActivityKind: Int] {
        var result: [ActivityKind: Int] = [:]
        for kind in ActivityKind.allCases {
            result[kind] = count(kind, on: key)
        }
        return result
    }

    /// One "action" per counted unit, summed over the kinds: the number the heatmap shades by.
    func total(on key: String) -> Int {
        (days[key]?.values.reduce(0, +) ?? 0) + (watchDays[key]?.values.reduce(0, +) ?? 0)
    }

    func isActive(on key: String) -> Bool { total(on: key) > 0 }

    var todayKey: String { Settings.shared.dailyDayKey() }

    /// The keys of the last `n` rollover days, oldest first, ending today.
    func recentDayKeys(_ n: Int) -> [String] {
        let anchor = Settings.shared.dailyAnchor()
        let calendar = Calendar.current
        return (0..<n).reversed().compactMap { back in
            calendar.date(byAdding: .day, value: -back, to: anchor).map(Settings.dayKey)
        }
    }

    var activeDayCount: Int { activeKeys.count }

    /// Every day with an action on either device, oldest first.
    private var activeKeys: [String] {
        Set(days.keys).union(watchDays.keys).filter { total(on: $0) > 0 }.sorted()
    }

    // MARK: The summary

    /// Recomputes the summary and publishes it if anything changed. Main thread only (the daily
    /// boundary is).
    func refreshSummary() {
        let next = makeSummary()
        if next != summary { summary = next }
    }

    /// The day may have turned over since the last recompute (the app slept past Fajr): called on
    /// foreground and when the dashboard appears.
    func refreshSummaryIfDayChanged() {
        guard summary.todayKey != Settings.shared.dailyDayKey() else { return }
        refreshSummary()
    }

    private func makeSummary() -> Summary {
        let calendar = Calendar.current
        let anchor = Settings.shared.dailyAnchor()
        let today = Settings.dayKey(anchor)
        var out = Summary()
        out.todayKey = today
        out.today = counts(on: today)
        out.streak = streak()
        out.todayWeekday = calendar.component(.weekday, from: anchor)
        let keys = recentDayKeys(Self.recentDays)
        out.recentTotals = keys.map { total(on: $0) }
        out.week = keys.suffix(7).map { key in
            DayCounts(key: key, counts: counts(on: key), weekdayLetter: Self.weekdayLetter(of: key, calendar: calendar))
        }
        out.activeDayCount = activeDayCount
        return out
    }

    private static func weekdayLetter(of key: String, calendar: Calendar) -> String {
        guard let date = date(fromKey: key) else { return "" }
        let weekday = calendar.component(.weekday, from: date)
        let symbols = calendar.veryShortWeekdaySymbols
        return symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : ""
    }

    // MARK: Streak

    /// Consecutive active days ending today (or yesterday: a day is not missed until it is over),
    /// with one missed day per calendar month forgiven, and the longest such run ever. A walk over
    /// up to 400 days: read it from `summary.streak`, which the log maintains, rather than per body.
    func streak() -> Streak {
        let calendar = Calendar.current
        let anchor = Settings.shared.dailyAnchor()
        let today = Settings.dayKey(anchor)
        var result = Streak()
        result.activeToday = isActive(on: today)

        // Current: walk back from today (or yesterday when today is still open and empty).
        var cursor = anchor
        if !result.activeToday {
            cursor = calendar.date(byAdding: .day, value: -1, to: anchor) ?? anchor
        }
        var usedFreezeMonths = Set<String>()
        var current = 0
        while true {
            let key = Settings.dayKey(cursor)
            if isActive(on: key) {
                current += 1
            } else {
                let month = String(key.prefix(7))
                // A freeze covers exactly one missed day in its month, and only inside a run.
                guard current > 0 || result.activeToday, !usedFreezeMonths.contains(month) else { break }
                usedFreezeMonths.insert(month)
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
            if current > Self.keepDays { break }
        }
        result.current = current
        result.freezeUsed = usedFreezeMonths.contains(String(today.prefix(7)))

        // Longest: the same walk forward over every recorded day.
        let activeKeys = self.activeKeys
        if let first = activeKeys.first, let firstDay = Self.date(fromKey: first) {
            var run = 0
            var best = 0
            var freezes = Set<String>()
            var day = firstDay
            let last = activeKeys.last.flatMap(Self.date(fromKey:)) ?? firstDay
            while day <= last {
                let key = Settings.dayKey(day)
                if isActive(on: key) {
                    run += 1
                } else {
                    let month = String(key.prefix(7))
                    if run > 0, !freezes.contains(month) {
                        freezes.insert(month)
                    } else {
                        run = 0
                        freezes.removeAll()
                    }
                }
                best = max(best, run)
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            result.longest = max(best, current)
        } else {
            result.longest = current
        }
        return result
    }

    private static let keyCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    /// The start of the day a key names ("yyyy-MM-dd", the Gregorian day `Settings.dayKey` writes),
    /// parsed as three integers: a `DateFormatter` per key was the dashboard's per-body cost.
    static func date(fromKey key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3, let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        return keyCalendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    // MARK: Persistence

    private static var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName, isDirectory: false)
    }

    private static var watchFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(watchFileName, isDirectory: false)
    }

    private func load() {
        if let url = Self.fileURL, let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data) {
            days = decoded
        }
        if let url = Self.watchFileURL, let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data) {
            watchDays = decoded
        }
    }

    private func scheduleSave() {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.save() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    /// Writes now (the app is about to background), after landing anything still queued.
    func flush() {
        applyPending()
        saveWork?.cancel()
        saveWork = nil
        save()
    }

    /// `flush()`, and both files are on disk when it returns (`Settings.flushPendingWritesNotification`).
    private func flushSynchronously() {
        flush()
        Self.ioQueue.sync {}
    }

    /// The files changed underneath this object (a restore): read them again, once every write
    /// this object had queued is out of the way.
    private func reloadFromStorage() {
        Self.ioQueue.sync {}
        saveWork?.cancel()
        saveWork = nil
        pending.removeAll()
        days = [:]
        watchDays = [:]
        load()
        refreshSummary()
    }

    private func save() {
        guard let url = Self.fileURL else { return }
        var trimmed = days
        if trimmed.count > Self.keepDays {
            for key in trimmed.keys.sorted().prefix(trimmed.count - Self.keepDays) {
                trimmed.removeValue(forKey: key)
            }
        }
        let snapshot = trimmed
        Self.ioQueue.async {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }
}
