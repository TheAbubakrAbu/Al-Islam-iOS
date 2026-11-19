#if os(iOS)
import Foundation

// The numbers behind the tracker's INSIGHTS section (Abu, 2026-11-18: "make prayer tracker so much
// better ui and features"). `PrayerTrackerStats` answers "how am I doing overall" (streaks, totals);
// this answers "where": which of the five prayers slips, on which weekday, and whether the span is
// better or worse than the one before it. Everything is a pure function of the stored records, so
// it is tested without the app (UnitTests/PrayerTrackerInsightsTests.swift).

/// The span the Insights section reports on. Every span ends today.
enum TrackerRange: String, CaseIterable, Identifiable {
    case week, month, year, all

    var id: String { rawValue }

    /// Days counted back from today, today included. Nil for all of the history.
    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .all: return nil
        }
    }
}

struct PrayerTrackerInsights: Equatable {
    /// One of the five prayers across the span.
    struct PrayerLine: Equatable, Identifiable {
        let name: String
        var onTime = 0
        var late = 0
        var missed = 0
        /// Days the prayer was due and carries no answer.
        var unmarked = 0
        /// Of the prayed ones, how many were in congregation.
        var congregation = 0

        var id: String { name }
        var prayed: Int { onTime + late }
        var due: Int { onTime + late + missed + unmarked }
        /// On time out of every time it was due, 0...1.
        var onTimeShare: Double { due > 0 ? Double(onTime) / Double(due) : 0 }
    }

    /// One day of the week across the span, `weekday` as `Calendar` numbers it (1 = Sunday).
    struct WeekdayLine: Equatable, Identifiable {
        let weekday: Int
        var onTime = 0
        var due = 0

        var id: Int { weekday }
        var onTimeShare: Double { due > 0 ? Double(onTime) / Double(due) : 0 }
    }

    var range: TrackerRange = .month
    /// The five, in day order.
    var prayers: [PrayerLine] = Settings.canonicalObligatoryPrayers.map { PrayerLine(name: $0) }
    /// Seven, Sunday first.
    var weekdays: [WeekdayLine] = (1...7).map { WeekdayLine(weekday: $0) }
    /// Days of the span that count: from the first tracked day through today, exempt days left out.
    var countedDays = 0
    var exemptDays = 0
    /// All five on time.
    var perfectDays = 0
    /// All five prayed, on time or late.
    var completeDays = 0
    /// Days each Sunnah prayer was ticked, over `countedDays`.
    var sunnah: [SunnahPrayer: Int] = [:]
    /// Days on which every one of the twelve regular rak'at was ticked.
    var fullRawatibDays = 0
    /// The on-time share of the equal span just before this one. Nil when that span holds no
    /// counted day, and always nil for the whole history (nothing comes before it).
    var previousOnTimeShare: Double?

    var onTime: Int { prayers.reduce(0) { $0 + $1.onTime } }
    var late: Int { prayers.reduce(0) { $0 + $1.late } }
    var missed: Int { prayers.reduce(0) { $0 + $1.missed } }
    var unmarked: Int { prayers.reduce(0) { $0 + $1.unmarked } }
    var prayed: Int { onTime + late }
    var due: Int { onTime + late + missed + unmarked }
    var congregation: Int { prayers.reduce(0) { $0 + $1.congregation } }
    var onTimeShare: Double { due > 0 ? Double(onTime) / Double(due) : 0 }
    /// Whether anything in the span was answered at all.
    var hasMarks: Bool { onTime + late + missed > 0 }

    /// Percentage points between this span and the one before it, rounded as the two are shown
    /// (so "85%" against "79%" never reads "+5").
    var changeInPoints: Int? {
        guard let previous = previousOnTimeShare else { return nil }
        return Self.percent(onTimeShare) - Self.percent(previous)
    }

    /// The prayer most often on time, when one stands above the rest. Nil when the five are level
    /// (a perfect span, or an empty one): naming a "strongest" among equals would be noise.
    var strongest: PrayerLine? {
        guard hasMarks, let best = prayers.max(by: { $0.onTimeShare < $1.onTimeShare }),
              let worst = prayers.min(by: { $0.onTimeShare < $1.onTimeShare }),
              Self.percent(best.onTimeShare) > Self.percent(worst.onTimeShare) else { return nil }
        return best
    }

    /// The prayer least often on time, when one falls below the rest. Between two level at the
    /// bottom, the one missed more, then the one late more.
    var weakest: PrayerLine? {
        guard strongest != nil else { return nil }
        return prayers.min {
            let (a, b) = (Self.percent($0.onTimeShare), Self.percent($1.onTimeShare))
            if a != b { return a < b }
            if $0.missed != $1.missed { return $0.missed > $1.missed }
            return $0.late > $1.late
        }
    }

    /// The weekday least often on time, when the week is uneven and there is more than one week of
    /// it to judge by. Nil in the 7-day span, where each weekday is a single day.
    var weakestWeekday: WeekdayLine? {
        guard range != .week, countedDays >= 14 else { return nil }
        let judged = weekdays.filter { $0.due > 0 }
        guard judged.count == 7,
              let worst = judged.min(by: { $0.onTimeShare < $1.onTimeShare }),
              let best = judged.max(by: { $0.onTimeShare < $1.onTimeShare }),
              Self.percent(best.onTimeShare) - Self.percent(worst.onTimeShare) >= 5 else { return nil }
        return worst
    }

    static func percent(_ share: Double) -> Int { Int((share * 100).rounded()) }

    // MARK: Compute

    /// - Parameters:
    ///   - marks: the stored tracker, day key to recorded name to mark.
    ///   - resumeDays: the days a pause ended on (`Settings.isTrackerResumeDay`). A prayer left
    ///     unanswered on one is not counted as due: it may have fallen inside the period.
    ///   - earliestKey: the first tracked day ("tracking since"). Days before it are not days the
    ///     reader failed to pray, and are never counted.
    ///   - dayKey: the tracker's own key for a date (Gregorian "yyyy-MM-dd").
    static func compute(
        range: TrackerRange,
        marks: [String: [String: PrayerMark]],
        exemptDays: Set<String>,
        activePauseStartKey: String?,
        resumeDays: Set<String> = [],
        congregation: [String: Set<String>] = [:],
        sunnah: [String: Set<String>] = [:],
        earliestKey: String?,
        today: Date,
        calendar: Calendar,
        dayKey: (Date) -> String
    ) -> PrayerTrackerInsights {
        var insights = PrayerTrackerInsights()
        insights.range = range
        guard let earliestKey else { return insights }

        let today = calendar.startOfDay(for: today)
        let todayKey = dayKey(today)
        // The whole history is walked back to the first tracked day, under the stats engine's cap
        // (retention prunes at 1,850 days; a longer walk means a corrupt earliest key).
        let span = range.days ?? 2_000
        let names = Settings.canonicalObligatoryPrayers
        var previousOnTime = 0
        var previousDue = 0

        var day = today
        // Newest first: today, then back through this span, then on through the span before it.
        for offset in 0..<(range.days == nil ? span : span * 2) {
            let key = dayKey(day)
            if key < earliestKey { break }
            let exempt = exemptDays.contains(key) || (activePauseStartKey.map { key >= $0 } ?? false)
            let dayMarks = Settings.canonicalMarks(of: marks[key] ?? [:])
            let inSpan = offset < span

            if exempt {
                if inSpan { insights.exemptDays += 1 }
            } else if inSpan {
                insights.countedDays += 1
                let weekday = calendar.component(.weekday, from: day)
                var onTimeToday = 0
                var prayedToday = 0
                for (index, name) in names.enumerated() {
                    let mark = dayMarks[name]
                    // Today is not over: a prayer of today with no answer yet is not counted as
                    // unanswered, it is simply not in the numbers until it is marked. The same on
                    // the day a pause ended, whatever day that was.
                    if mark == nil, key == todayKey || resumeDays.contains(key) { continue }
                    switch mark {
                    case .onTime:
                        insights.prayers[index].onTime += 1
                        onTimeToday += 1
                        prayedToday += 1
                    case .late:
                        insights.prayers[index].late += 1
                        prayedToday += 1
                    case .missed:
                        insights.prayers[index].missed += 1
                    case nil:
                        insights.prayers[index].unmarked += 1
                    }
                    if mark?.isPrayed == true, congregation[key]?.contains(name) == true {
                        insights.prayers[index].congregation += 1
                    }
                    if (1...7).contains(weekday) {
                        insights.weekdays[weekday - 1].due += 1
                        if mark == .onTime { insights.weekdays[weekday - 1].onTime += 1 }
                    }
                }
                if onTimeToday == names.count { insights.perfectDays += 1 }
                if prayedToday == names.count { insights.completeDays += 1 }

                if let ticked = sunnah[key] {
                    var regular = 0
                    for prayer in SunnahPrayer.allCases where ticked.contains(prayer.rawValue) {
                        insights.sunnah[prayer, default: 0] += 1
                        regular += prayer.regularRakat
                    }
                    if regular == SunnahPrayer.regularRakatTotal { insights.fullRawatibDays += 1 }
                }
            } else {
                for name in names {
                    if dayMarks[name] == nil, resumeDays.contains(key) { continue }
                    previousDue += 1
                    if dayMarks[name] == .onTime { previousOnTime += 1 }
                }
            }

            guard let before = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            // Re-anchored every step, like the stats walk: where the clocks skip midnight the
            // running date would otherwise drift off the start of the day.
            day = calendar.startOfDay(for: before)
        }

        if range.days != nil, previousDue > 0 {
            insights.previousOnTimeShare = Double(previousOnTime) / Double(previousDue)
        }
        return insights
    }
}

// MARK: - Streak milestones

extension PrayerTrackerStats {
    /// The streak lengths the achievements mark (Achievements.swift: 3, 7, 14, 30, 50, 100, 182 and
    /// 365 days), then every further hundred.
    static let streakMilestones = [3, 7, 14, 30, 50, 100, 182, 365]

    /// The next milestone above `streak`, and the one it starts from (0 before the first).
    static func streakMilestone(after streak: Int) -> (from: Int, to: Int) {
        var from = 0
        for milestone in streakMilestones {
            if streak < milestone { return (from, milestone) }
            from = milestone
        }
        let next = (streak / 100 + 1) * 100
        return (max(from, next - 100), next)
    }
}

// MARK: - Cached reads

extension Settings {
    /// Cache for `trackerInsights(for:)`, one entry per span, keyed like `trackerStats`: the tracker's
    /// write counter and the civil day.
    private static var trackerInsightsCache: [TrackerRange: (stamp: Int, value: PrayerTrackerInsights)] = [:]

    /// The insight numbers for `range`, recomputed only when a tracker record changed or the day
    /// rolled over.
    func trackerInsights(for range: TrackerRange) -> PrayerTrackerInsights {
        var hasher = Hasher()
        hasher.combine(trackerGeneration)
        hasher.combine(Calendar.current.startOfDay(for: Date()))
        let stamp = hasher.finalize()
        if let cached = Self.trackerInsightsCache[range], cached.stamp == stamp { return cached.value }

        let snapshot = trackerSnapshot()
        let extras = trackerExtrasSnapshot()
        let value = PrayerTrackerInsights.compute(
            range: range,
            marks: snapshot.marks,
            exemptDays: snapshot.exemptDays,
            activePauseStartKey: snapshot.activePauseStartKey,
            resumeDays: snapshot.resumeDays,
            congregation: extras.congregation,
            sunnah: extras.sunnah,
            earliestKey: trackerEarliestDayKey(),
            today: Date(),
            calendar: .current,
            dayKey: trackerDayKey(for:)
        )
        Self.trackerInsightsCache[range] = (stamp, value)
        return value
    }
}
#endif
