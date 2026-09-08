#if os(iOS)
import SwiftUI

// The profile's activity surfaces, fed by ActivityLog: today's three rings (read, listen, dhikr),
// the streak with its monthly freeze, the last seven days as stacked bars, twelve weeks as a grid,
// the milestone ladder, and an analytics screen that filters every chart by day, week, month, year
// or lifetime. Every number is derived from what the reader actually did; nothing is padded.
// Apple-Activity-leaning, one accent, per-kind opacity steps. After Tilawa's profile (Jamil
// Hammoudeh).

private enum ActivityGoal {
    /// Today's targets the rings fill toward: the reading plan's own daily amount when a plan is
    /// running, otherwise a modest default; one surah listened; a hundred counts of dhikr. The plan
    /// is read unobserved: the card refreshes it on appear and on every summary publish, which is
    /// enough for a value that changes from the planner screen.
    @MainActor
    static func read() -> Int {
        if let plan = Settings.shared.quranPlan {
            let total = QuranPlannerMath.totalAyahs(quran: QuranData.shared.quran)
            let target = QuranPlannerMath.todayTarget(plan: plan, totalAyahs: total, dayStartCompleted: plan.dayStartCompleted)
            if target > 0 { return target }
        }
        return 10
    }
    static let listen = 1
    static let dhikr = 100
}

private extension ActivityKind {
    /// The one accent, stepped by kind so a stacked bar still reads.
    func tint(_ accent: Color) -> Color {
        switch self {
        case .read: return accent
        case .listen: return accent.opacity(0.7)
        case .dhikr: return accent.opacity(0.45)
        case .hadith: return accent.opacity(0.28)
        }
    }
}

// MARK: - The card on the profile

/// Reads the log's maintained `Summary` and the appearance snapshot, nothing else: it used to walk
/// the streak and allocate formatters per body, and observe Settings and QuranData for an accent
/// and a surah count.
struct ActivityDashboardCard: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var log = ActivityLog.shared

    /// The rings fill from zero once per screen visit, never again on a scroll back into view, and
    /// not at all when animations are reduced.
    @State private var animatedIn = false

    private var accent: Color { appearance.accent }

    var body: some View {
        let _ = RenderCounter.hit("ActivityDashboardCard")
        let summary = log.summary
        let streak = summary.streak
        let readGoal = ActivityGoal.read()
        let rings: [(kind: ActivityKind, done: Int, goal: Int)] = [
            (.read, summary.today[.read] ?? 0, readGoal),
            (.listen, summary.today[.listen] ?? 0, ActivityGoal.listen),
            (.dhikr, summary.today[.dhikr] ?? 0, ActivityGoal.dhikr),
        ]
        let animated = !appearance.reduceAnimations
        let filled = animatedIn || !animated

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                AccentIconChip(systemImage: "chart.bar.fill", size: 24)
                Text("Activity")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: LazyDestination { ActivityAnalyticsView() }) {
                    HStack(spacing: 3) {
                        Text("Analytics")
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(accent)
                }
                .buttonStyle(.plain)
            }

            // Today: three rings, and what they stand for.
            HStack(spacing: 16) {
                ZStack {
                    ForEach(Array(rings.enumerated()), id: \.offset) { index, ring in
                        let fraction = ring.goal > 0 ? min(1, Double(ring.done) / Double(ring.goal)) : 0
                        ActivityRing(fraction: filled ? fraction : 0, color: ring.kind.tint(accent), lineWidth: 9, animated: animated)
                            .padding(CGFloat(index) * 13)
                    }
                }
                .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(rings.enumerated()), id: \.offset) { _, ring in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(ring.kind.tint(accent))
                                .frame(width: 8, height: 8)
                            Text(ring.kind.title)
                                .font(.caption.weight(.semibold))
                            Spacer(minLength: 4)
                            Text("\(ring.done) / \(ring.goal)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(Self.todayLine(summary.today))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
            }
            .onAppear {
                log.refreshSummaryIfDayChanged()
                if !animatedIn { animatedIn = true }
            }

            // The streak.
            HStack(spacing: 10) {
                streakStat("\(streak.current)", "Streak", systemImage: "flame.fill")
                streakStat("\(streak.longest)", "Longest", systemImage: "trophy.fill")
                streakStat(streak.freezeUsed ? "Used" : "1", "Freeze", systemImage: "snowflake")
            }

            WeekBars(week: summary.week, accent: accent)
                .equatable()

            HeatmapGrid(totals: summary.recentTotals, todayWeekday: summary.todayWeekday,
                        weeks: appearance.isReducedTier ? 6 : 12, accent: accent)
                .equatable()

            MilestoneLadder(current: streak.current, accent: accent)
                .equatable()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .conditionalGlassEffect(rectangle: true, interactive: false)
    }

    private static func todayLine(_ today: [ActivityKind: Int]) -> String {
        let parts = ActivityKind.allCases.compactMap { kind -> String? in
            let n = today[kind] ?? 0
            return n > 0 ? kind.amount(n) : nil
        }
        return parts.isEmpty ? "Nothing logged yet today." : "Today: " + parts.joined(separator: ", ") + "."
    }

    private func streakStat(_ value: String, _ label: String, systemImage: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
                Text(value)
                    .font(.subheadline.weight(.bold).monospacedDigit())
            }
            .foregroundColor(accent)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(accent.opacity(0.08)))
    }
}

struct ActivityRing: View {
    let fraction: Double
    let color: Color
    var lineWidth: CGFloat = 9
    /// Off under reduced animations: the ring is drawn at its fraction, no sweep.
    var animated = true

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: lineWidth)
            if fraction > 0 {
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(animated ? .easeOut(duration: 0.55) : nil, value: fraction)
            }
        }
    }
}

/// The last seven days, one stacked bar each, kinds stepped in opacity. Plain values in, Equatable,
/// wrapped in `.equatable()`: the card's other rows re-render without touching it.
private struct WeekBars: View, Equatable {
    let week: [ActivityLog.DayCounts]
    let accent: Color

    var body: some View {
        let peak = max(1, week.map(\.total).max() ?? 1)
        VStack(alignment: .leading, spacing: 6) {
            Text("THIS WEEK")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(week, id: \.key) { day in
                    VStack(spacing: 4) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            ForEach(ActivityKind.allCases.reversed(), id: \.self) { kind in
                                let n = day.counts[kind] ?? 0
                                if n > 0 {
                                    Rectangle()
                                        .fill(kind.tint(accent))
                                        .frame(height: max(2, 56 * CGFloat(n) / CGFloat(peak)))
                                }
                            }
                        }
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.05)))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        Text(day.weekdayLetter)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

/// Twelve weeks of days (six on the reduced tier), Sunday at the top of each column, shaded by how
/// much was done. Takes the summary's recent totals and pads back to the Sunday that begins the
/// earliest week, so columns are whole weeks.
private struct HeatmapGrid: View, Equatable {
    /// Totals oldest first, ending today (`ActivityLog.Summary.recentTotals`).
    let totals: [Int]
    let todayWeekday: Int
    let weeks: Int
    let accent: Color

    var body: some View {
        let daysBack = (weeks - 1) * 7 + (todayWeekday - 1)
        let shown = Array(totals.suffix(daysBack + 1))
        let columns = stride(from: 0, to: shown.count, by: 7).map { Array(shown[$0..<min($0 + 7, shown.count)]) }
        let peak = max(1, shown.max() ?? 1)

        VStack(alignment: .leading, spacing: 6) {
            Text(weeks == 6 ? "LAST SIX WEEKS" : "LAST TWELVE WEEKS")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 3) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    VStack(spacing: 3) {
                        ForEach(Array(column.enumerated()), id: \.offset) { _, n in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(n == 0 ? Color.primary.opacity(0.06)
                                      : accent.opacity(0.25 + 0.75 * min(1, Double(n) / Double(peak))))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }
}

/// 3, 7, 14, 30, 50, 100: where the streak stands and what comes next.
private struct MilestoneLadder: View, Equatable {
    let current: Int
    let accent: Color

    private static let steps = [3, 7, 14, 30, 50, 100]

    var body: some View {
        let next = Self.steps.first { $0 > current }
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("MILESTONES")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let next {
                    Text("\(next - current) day\(next - current == 1 ? "" : "s") to \(next)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 6) {
                ForEach(Self.steps, id: \.self) { step in
                    let reached = current >= step
                    let isNext = step == next
                    Text("\(step)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundColor(reached ? .white : (isNext ? accent : .secondary))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(reached ? accent : accent.opacity(isNext ? 0.15 : 0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isNext ? accent : .clear, lineWidth: 1.5)
                        )
                }
            }
        }
    }
}

// MARK: - Analytics

struct ActivityAnalyticsView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var log = ActivityLog.shared

    private enum Range: String, CaseIterable, Identifiable {
        case day = "Day", week = "Week", month = "Month", year = "Year", lifetime = "All"
        var id: String { rawValue }

        var days: Int? {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            case .year: return 365
            case .lifetime: return nil
            }
        }
    }

    @State private var range: Range = .week

    /// Everything the screen derives from the range and the log, computed once per range switch
    /// and per summary publish (the lifetime range walks up to 400 days), never in the body.
    private struct Derived: Equatable {
        var keys: [String] = []
        var actions = 0
        var activeDays = 0
        var best = 0
        var byKind: [ActivityKind: Int] = [:]
        var trend: [Int] = []
        var bin = 1
    }
    @State private var derived = Derived()

    private var accent: Color { appearance.accent }

    var body: some View {
        let _ = RenderCounter.hit("ActivityAnalyticsView")
        let streak = log.summary.streak
        let actions = derived.actions

        List {
            Group {
                Section {
                    // The range and what it derives change in one transaction (one body per switch);
                    // a plain binding, never animated (the segmented indicator bounced under one).
                    Picker("Range", selection: Binding(
                        get: { range },
                        set: { next in
                            range = next
                            derived = Self.derive(range: next, log: log)
                        }
                    )) {
                        ForEach(Range.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("AT A GLANCE")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        tile("\(actions)", "Actions")
                        tile("\(derived.activeDays)", "Active days")
                        tile(derived.activeDays > 0 ? "\(actions / derived.activeDays)" : "0", "Per active day")
                        tile("\(derived.best)", "Best day")
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("TREND")) {
                    TrendBars(totals: derived.trend, bin: derived.bin, accent: accent)
                        .equatable()
                        .padding(.vertical, 4)
                }

                Section(header: Text("BY KIND")) {
                    ForEach(ActivityKind.allCases, id: \.self) { kind in
                        let n = derived.byKind[kind] ?? 0
                        HStack(spacing: 10) {
                            Image(systemName: kind.systemImage)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(accent)
                                .frame(width: 20)
                            Text(kind.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(kind.amount(n))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(actions > 0 ? "\(Int((Double(n) / Double(actions) * 100).rounded()))%" : "0%")
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundColor(accent)
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section(header: Text("STREAK")) {
                    HStack(spacing: 10) {
                        tile("\(streak.current)", "Current")
                        tile("\(streak.longest)", "Longest")
                        tile(streak.freezeUsed ? "0" : "1", "Freeze left")
                    }
                    .padding(.vertical, 4)
                }

                Section(footer:
                    Text("One action is one ayah marked read, one surah played, one count of dhikr, or one hadith opened. Days turn over with the daily features (at Fajr by default). One missed day a month is forgiven by the streak. Reading and listening on your Apple Watch count too, once it syncs.")
                        .font(.caption2)
                ) { EmptyView() }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(log.$summary) { _ in
            let next = Self.derive(range: range, log: log)
            if next != derived { derived = next }
        }
    }

    private static func bin(for days: Int) -> Int {
        if days <= 14 { return 1 }
        if days <= 90 { return 7 }
        return 30
    }

    /// The keys of the chosen range, oldest first: the last n days, or from the first recorded day
    /// to today (capped at the log's own 400-day retention) so gaps show as gaps.
    private static func rangeKeys(_ range: Range, log: ActivityLog) -> [String] {
        if let days = range.days { return log.recentDayKeys(days) }
        let recorded = log.days.keys.sorted()
        guard let first = recorded.first, let start = ActivityLog.date(fromKey: first) else { return log.recentDayKeys(1) }
        let span = (Calendar.current.dateComponents([.day], from: start, to: Settings.shared.dailyAnchor()).day ?? 0) + 1
        return log.recentDayKeys(max(1, min(400, span)))
    }

    private static func derive(range: Range, log: ActivityLog) -> Derived {
        let keys = rangeKeys(range, log: log)
        let totals = keys.map { log.total(on: $0) }
        var next = Derived()
        next.keys = keys
        next.actions = totals.reduce(0, +)
        next.activeDays = totals.filter { $0 > 0 }.count
        next.best = totals.max() ?? 0
        for kind in ActivityKind.allCases {
            next.byKind[kind] = keys.reduce(0) { $0 + log.count(kind, on: $1) }
        }
        next.bin = Self.bin(for: keys.count)
        next.trend = stride(from: 0, to: totals.count, by: next.bin).map { start in
            totals[start..<min(start + next.bin, totals.count)].reduce(0, +)
        }
        return next
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundColor(accent)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(accent.opacity(0.08)))
    }
}

/// Totals binned by day, week or month across the range, as plain bars.
private struct TrendBars: View, Equatable {
    let totals: [Int]
    let bin: Int
    let accent: Color

    var body: some View {
        let peak = max(1, totals.max() ?? 1)
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: totals.count > 40 ? 1 : 3) {
                ForEach(Array(totals.enumerated()), id: \.offset) { _, total in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(total > 0 ? accent : Color.primary.opacity(0.06))
                        .frame(height: max(2, 64 * CGFloat(total) / CGFloat(peak)))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 64, alignment: .bottom)
            Text(bin == 1 ? "One bar per day" : bin == 7 ? "One bar per week" : "One bar per month")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
#endif
