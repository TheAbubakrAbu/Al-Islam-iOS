#if os(iOS)
import SwiftUI

// MARK: - Statistics engine

/// Everything the tracker UI reports, computed in ONE forward pass over the recorded history and cached
/// against the underlying data (see `Settings.trackerStats`) - the Adhan tab re-renders every countdown
/// tick, and walking years of history per frame is exactly the kind of work that must not happen there.
///
/// All statistics are computed on CANONICAL coverage (`Settings.canonicalMarks(of:)`), so a traveling-day
/// "Dhuhr/Asr" counts as both prayers and a Friday "Jumuah" counts as Dhuhr. Exempt days (menstruation /
/// postpartum) are neutral everywhere: they neither break a streak nor count in any denominator.
///
/// Two grades of a good day: COMPLETE (all five prayed, on time or late - what a streak is made of, and
/// what "prayed" has always meant here) and PERFECT (all five on time). A late prayer keeps the streak
/// alive and costs the perfect day; a missed one costs both.
struct PrayerTrackerStats: Equatable {
    /// Consecutive complete days ending now. Today only joins once complete, but an incomplete today
    /// never breaks the run - the day isn't over.
    var currentStreak = 0
    var bestStreak = 0
    /// Canonical prayers prayed (on time or late) across all recorded history.
    var totalPrayed = 0
    /// Days with all five prayed on time.
    var perfectDays = 0
    /// Days with all five prayed, on time or late.
    var completeDays = 0
    /// Prayers by mark across all recorded history. `onTimeCount + lateCount == totalPrayed`.
    var onTimeCount = 0
    var lateCount = 0
    var missedCount = 0
    /// Countable (non-exempt) days from the first recorded day through today.
    var trackedDays = 0
    var exemptDayCount = 0
    /// The first day anything was recorded, nil until tracking begins.
    var trackingSince: Date?

    /// The share of prayed prayers that were on time, 0...1 (0 until something is prayed).
    var onTimeFraction: Double {
        totalPrayed > 0 ? Double(onTimeCount) / Double(totalPrayed) : 0
    }

    static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Pinned explicitly (the Quran-side dayKey does the same): tracker keys must stay Gregorian
        // "yyyy-MM-dd" even when the iPhone's SYSTEM calendar is Hijri - the grid geometry may
        // follow the system calendar, the storage keys never do.
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func compute(for settings: Settings) -> PrayerTrackerStats {
        var stats = PrayerTrackerStats()
        guard let earliestKey = settings.trackerEarliestDayKey(),
              let firstDay = dayKeyFormatter.date(from: earliestKey) else { return stats }

        let snapshot = settings.trackerSnapshot()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let all = Settings.canonicalObligatoryPrayers.count
        stats.trackingSince = firstDay

        var run = 0
        var day = calendar.startOfDay(for: firstDay)
        // Hard iteration cap: retention prunes at 1850 days, so a walk past ~5.5 years means a
        // corrupt or foreign earliest key slipped in (e.g. one written under a non-Gregorian
        // calendar) - without the cap, one bad key turned this loop into a main-thread hang that
        // read as a crash (watchdog kill) on the affected device.
        var remaining = 2_000
        while day <= today, remaining > 0 {
            remaining -= 1
            let key = dayKeyFormatter.string(from: day)
            let exempt = snapshot.exemptDays.contains(key)
                || (snapshot.activePauseStartKey.map { key >= $0 } ?? false)

            if exempt {
                stats.exemptDayCount += 1
                // Neutral: the run carries straight across an exempt stretch.
            } else {
                stats.trackedDays += 1
                let tally = PrayerDayTally(marks: Settings.canonicalMarks(of: snapshot.marks[key] ?? [:]))
                stats.onTimeCount += tally.onTime
                stats.lateCount += tally.late
                stats.missedCount += tally.missed
                stats.totalPrayed += tally.prayed
                if tally.onTime == all { stats.perfectDays += 1 }
                if tally.prayed == all {
                    stats.completeDays += 1
                    run += 1
                    stats.bestStreak = max(stats.bestStreak, run)
                } else if day < today {
                    run = 0
                }
                // An incomplete TODAY falls through without resetting: the streak survives until
                // midnight actually passes without the day being completed.
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        stats.currentStreak = run
        return stats
    }
}

/// One day's canonical marks counted up - the arithmetic the stats engine, the period summaries and
/// the grids all need, done in one place.
struct PrayerDayTally: Equatable {
    var onTime = 0
    var late = 0
    var missed = 0

    init(marks: [String: PrayerMark]) {
        for mark in marks.values {
            switch mark {
            case .onTime: onTime += 1
            case .late: late += 1
            case .missed: missed += 1
            }
        }
    }

    /// Prayed on time or late.
    var prayed: Int { onTime + late }
    /// All five prayed (the streak's unit).
    var isComplete: Bool { prayed == Settings.canonicalObligatoryPrayers.count }
    /// All five on time.
    var isPerfect: Bool { onTime == Settings.canonicalObligatoryPrayers.count }
}

extension Settings {
    /// Cache slot for `trackerStats`, keyed by a stamp of everything the stats derive from.
    private static var trackerStatsCache: (stamp: Int, stats: PrayerTrackerStats)?

    /// The current statistics, recomputed only when the underlying data actually changed.
    var trackerStats: PrayerTrackerStats {
        var hasher = Hasher()
        // The write counter the four tracker fields bump (see `bumpTrackerGeneration`), instead of
        // hashing years of marks on every render that asks.
        hasher.combine(trackerGeneration)
        // The day rolling over changes today-dependent numbers even with identical data.
        hasher.combine(Calendar.current.startOfDay(for: Date()))
        let stamp = hasher.finalize()

        if let cached = Self.trackerStatsCache, cached.stamp == stamp { return cached.stats }
        let stats = PrayerTrackerStats.compute(for: self)
        Self.trackerStatsCache = (stamp, stats)
        return stats
    }

    /// The trackable prayers of `date` as the list shows them - traveling-aware (combined rows) and
    /// Friday-aware (Jumuah) - i.e. exactly the slots a person actually prays that day.
    func trackableSlots(for date: Date) -> [Prayer] {
        let list: [Prayer]
        if Calendar.current.isDate(date, inSameDayAs: Date()), let prayers = prayers {
            list = prayers.prayers
        } else {
            list = getPrayerTimes(for: date) ?? []
        }
        return list
            .filter { Settings.trackablePrayerNames.contains($0.nameTransliteration) }
            .sorted { $0.time < $1.time }
    }

    /// Records the mark and, when a prayed mark completes today's last open slot, asks for a rating at
    /// the app's clearest moment of delight. Every gate (cooldown, session and usage minimums, yearly
    /// quota) re-checks inside the manager, so this is safe to call on every mark. Main-actor, like
    /// the review manager it calls; every caller is a view action.
    @MainActor
    fileprivate func recordTrackerMark(_ mark: PrayerMark?, for prayerName: String, on date: Date) {
        setPrayerMark(prayerName, on: date, mark: mark)
        guard let mark = mark, mark.isPrayed, Calendar.current.isDateInToday(date) else { return }
        let slots = trackableSlots(for: date)
        if !slots.isEmpty, trackedPrayerCount(slots.map(\.nameTransliteration)) == slots.count {
            AppReviewManager.shared.requestAtMomentOfDelight()
        }
    }
}

// MARK: - Shared bits

private func canonicalLabel(_ name: String, settings: Settings) -> String {
    settings.customPrayerName(for: name) ?? name
}

/// How each mark presents: its words, its symbol, and its color. On time wears the accent (the color a
/// checkmark always wore here); late and missed keep their own fixed colors so they read the same
/// whatever accent is chosen, and so an accent that happens to be orange or red cannot make a late or
/// missed prayer look like an on-time one.
private extension PrayerMark {
    var title: String {
        switch self {
        case .onTime: return "Prayed On Time"
        case .late: return "Prayed Late"
        case .missed: return "Missed"
        }
    }

    var shortTitle: String {
        switch self {
        case .onTime: return "On time"
        case .late: return "Late"
        case .missed: return "Missed"
        }
    }

    var spokenTitle: String {
        switch self {
        case .onTime: return "prayed on time"
        case .late: return "prayed late"
        case .missed: return "missed"
        }
    }

    var symbol: String {
        switch self {
        case .onTime: return "checkmark"
        case .late: return "clock"
        case .missed: return "xmark"
        }
    }

    func tint(accent: Color) -> Color {
        switch self {
        case .onTime: return accent
        case .late: return .orange
        case .missed: return .red
        }
    }
}

/// The chooser inside every press-and-hold menu: a checkmarked picker of the three marks plus
/// "Not marked" to clear. A Picker rather than plain buttons, so the current answer shows its
/// checkmark in the menu.
private struct TrackerMarkPicker: View {
    @ObservedObject private var settings = Settings.shared

    let prayerName: String
    let date: Date

    var body: some View {
        Picker("Status", selection: Binding<PrayerMark?>(
            get: { settings.prayerMark(for: prayerName, on: date) },
            set: { newValue in
                settings.hapticFeedback()
                withAnimation(.easeInOut(duration: 0.15)) {
                    settings.recordTrackerMark(newValue, for: prayerName, on: date)
                }
            }
        )) {
            ForEach(PrayerMark.allCases, id: \.self) { mark in
                Label(mark.title, systemImage: mark.symbol).tag(Optional(mark))
            }
            Label("Not marked", systemImage: "circle").tag(PrayerMark?.none)
        }
    }
}

/// The ring that anchors the tracker section: progress around a fraction label.
private struct TrackerProgressRing: View {
    @ObservedObject private var settings = Settings.shared

    let prayed: Int
    let total: Int
    var size: CGFloat = 46

    private var fraction: CGFloat {
        total > 0 ? CGFloat(prayed) / CGFloat(total) : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(settings.accentColor.accent2.opacity(0.18), lineWidth: 5)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(
                        colors: [settings.accentColor.accent2.opacity(0.55), settings.accentColor.accent2],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * fraction)
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: fraction)

            if prayed == total && total > 0 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.32, weight: .bold))
                    .foregroundColor(settings.accentColor.accent2)
            } else {
                Text("\(prayed)/\(total)")
                    .font(.system(size: size * 0.3, weight: .semibold).monospacedDigit())
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(width: size, height: size)
    }
}

/// One prayer slot on the Adhan tab: icon in a circle that fills with the mark's color, name underneath.
/// Tap marks it prayed on time (tap again to clear); press and hold opens the full chooser - on time,
/// late, missed, or not marked.
private struct TrackerPrayerToggle: View {
    @ObservedObject private var settings = Settings.shared

    let prayer: Prayer
    let date: Date

    var body: some View {
        let mark = settings.prayerMark(for: prayer.nameTransliteration, on: date)
        let tint = mark?.tint(accent: settings.accentColor.accent2) ?? .secondary

        Menu {
            TrackerMarkPicker(prayerName: prayer.nameTransliteration, date: date)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if let mark = mark {
                        // The accent chip gradient, in circle form - marking a prayer should feel
                        // like a win, not a change of outline. Late and missed take their own colors.
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.95), tint.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .softShadow(color: tint.opacity(0.4), radius: 6, x: 0, y: 2)

                        Image(systemName: mark.symbol)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.08))

                        Circle()
                            .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)

                        Image(systemName: prayer.image)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 40, height: 40)

                Text(prayer.displayName)
                    .font(.caption2.weight(mark != nil ? .semibold : .regular))
                    .foregroundColor(mark != nil ? tint : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .contentShape(Rectangle())
        } primaryAction: {
            settings.hapticFeedback()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                settings.recordTrackerMark(mark == nil ? .onTime : nil, for: prayer.nameTransliteration, on: date)
            }
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .accessibilityLabel("\(prayer.displayName): \(mark?.spokenTitle ?? "not marked")")
        .accessibilityHint("Tap to mark prayed on time. Press and hold for late or missed.")
    }
}

// MARK: - The tracker section (Adhan tab, underneath Prayer Times)

/// The prayer tracker as its own section: today's ring + streak, the five tap-to-mark slots, and the
/// doorway into the full history. Standalone struct on purpose - a new Adhan-tab section must never be
/// an inline closure of an already-deep view tree.
struct PrayerTrackerSection: View {
    @ObservedObject private var settings = Settings.shared

    private var todaySlots: [Prayer] {
        settings.trackableSlots(for: Date())
    }

    var body: some View {
        let _ = RenderCounter.hit("PrayerTrackerSection")
        if settings.prayers != nil {
            Section(header: header) {
                if settings.isTrackerExempt(on: Date()) {
                    pausedCard
                } else {
                    trackerCard
                }

                NavigationLink {
                    PrayerTrackerView()
                } label: {
                    HStack(spacing: 12) {
                        AccentIconChip(systemImage: "chart.bar.xaxis", tint: settings.accentColor.accent2, size: 26)

                        Text("History & Insights")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("PRAYER TRACKER")

            Spacer()

            let streak = settings.trackerStats.currentStreak
            if streak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                    Text("\(streak) day\(streak == 1 ? "" : "s")")
                        .monospacedDigit()
                }
                .font(.caption2.weight(.semibold))
                .foregroundColor(settings.accentColor.accent2)
            }
        }
    }

    private var trackerCard: some View {
        let slots = todaySlots
        let names = slots.map(\.nameTransliteration)
        let prayed = settings.trackedPrayerCount(names)
        let complete = !slots.isEmpty && prayed == slots.count
        let allOnTime = complete && names.allSatisfy { settings.prayerMark(for: $0) == .onTime }

        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                TrackerProgressRing(prayed: prayed, total: slots.count)

                VStack(alignment: .leading, spacing: 3) {
                    Text(complete ? "All prayers completed" : "Today")
                        .font(.subheadline.weight(.semibold))

                    Text(complete
                         ? (allOnTime ? "Alhamdulillah, every prayer prayed on time." : "Alhamdulillah, every prayer prayed.")
                         : "\(prayed) of \(slots.count) prayed. Tap to mark on time, hold for late or missed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)
            }

            // Spacers BETWEEN the slots only, so the first circle starts at the row's left edge and
            // the last ends at its right - the equal-columns layout left both floating inset.
            HStack(spacing: 0) {
                ForEach(Array(slots.enumerated()), id: \.element.nameTransliteration) { index, prayer in
                    if index > 0 { Spacer(minLength: 6) }
                    TrackerPrayerToggle(prayer: prayer, date: Date())
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var pausedCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "moon.zzz.fill")
                .font(.title2)
                .foregroundColor(settings.accentColor.accent2)
                .frame(width: 46, height: 46)
                .background(Circle().fill(settings.accentColor.accent2.opacity(0.15)))

            VStack(alignment: .leading, spacing: 3) {
                Text("Tracking paused")
                    .font(.subheadline.weight(.semibold))

                Text(settings.mensesPauseActive
                     ? "Exempt days never count against your streaks. Resume any time in History & Insights."
                     : "Today is marked exempt. It won't count against your streaks.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Full history page

struct PrayerTrackerView: View {
    @ObservedObject private var settings = Settings.shared

    private enum Scope: String, CaseIterable, Identifiable {
        case day = "Day", week = "Week", month = "Month", year = "Year"
        var id: String { rawValue }
    }

    @State private var scope: Scope = Self.launchScope
    /// The date the shown period is anchored on - navigation moves it by one day/week/month/year.
    @State private var anchor = Date()

    /// DEBUG launch argument `-trackerScope day|week|month|year`: the scope the page opens on, so each
    /// history view can be screenshotted headlessly (pair with `-openPrayerTracker`).
    private static var launchScope: Scope {
        #if DEBUG
        if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-trackerScope"),
           ProcessInfo.processInfo.arguments.indices.contains(idx + 1),
           let scope = Scope.allCases.first(where: { $0.rawValue.lowercased() == ProcessInfo.processInfo.arguments[idx + 1].lowercased() }) {
            return scope
        }
        #endif
        return .day
    }

    /// Gregorian with the user's region intact (week start, timezone, localized names): the tracker's
    /// storage keys, pruning, and menses ranges are all Gregorian "yyyy-MM-dd", so the GRID must count
    /// months the same way. Under a system-wide Hijri calendar, plain `Calendar.current` drew
    /// 29/30-cell Hijri months over Gregorian-keyed data and fed Hijri years into the year view - the
    /// Hijri calendar has its own screen (CalendarView), the tracker is a civil-day log. One shared
    /// pinned instance (`displayCalendar`) so grid math and every formatter/symbol agree, built once:
    /// this is read per cell.
    private var calendar: Calendar { Self.displayCalendar }

    /// Every state write on this page is PLAIN (no `withAnimation`, no animated binding): the history
    /// section's rows are data-dependent - the Day view alone swaps between five prayer rows and a
    /// single note across exempt or empty days - and an ANIMATED structural diff of List rows is the
    /// UICollectionView update-assertion crash the search results once hit (see the SearchBar note in
    /// QuranView). Cells animate their own appearance; the row set never animates.
    var body: some View {
        List {
            statsSection
            historySection
            mensesSection
            guidanceSection
        }
        .environment(\.defaultMinListRowHeight, 1)
        .applyConditionalListStyle()
        .navigationTitle("Prayer Tracker")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Stats header

    private var statsSection: some View {
        let stats = settings.trackerStats

        return Section {
            // Plain stacks, not a lazy grid: four tiles inside one List row have nothing to be lazy
            // about, and a lazy container's own diffing is one more moving part inside a row.
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    statTile(value: "\(stats.currentStreak)", unit: stats.currentStreak == 1 ? "day" : "days",
                             label: "Current Streak", symbol: "flame.fill")
                    statTile(value: "\(stats.bestStreak)", unit: stats.bestStreak == 1 ? "day" : "days",
                             label: "Best Streak", symbol: "trophy.fill")
                }
                HStack(spacing: 10) {
                    statTile(value: "\(stats.perfectDays)", unit: stats.perfectDays == 1 ? "day" : "days",
                             label: "Perfect Days", symbol: "star.fill")
                    statTile(value: "\(stats.totalPrayed)", unit: "prayers",
                             label: "Prayers Logged", symbol: "checkmark.seal.fill")
                }
                if stats.onTimeCount + stats.lateCount + stats.missedCount > 0 {
                    markBreakdown(stats)
                }
            }
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)

            if let since = stats.trackingSince {
                Text("Tracking since \(Self.longDateFormatter.string(from: since))"
                     + (stats.exemptDayCount > 0 ? " · \(stats.exemptDayCount) exempt day\(stats.exemptDayCount == 1 ? "" : "s")" : ""))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
            }
        }
        .themedListRowBackground()
    }

    private func statTile(value: String, unit: String, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                AccentIconChip(systemImage: symbol, tint: settings.accentColor.accent2, size: 20)

                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundColor(.primary)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .conditionalGlassEffect(rectangle: true)
    }

    /// The marks in proportion: one bar split into on time / late / missed, with the counts beneath -
    /// the "accurate picture" the three-way marks exist for, in one glance.
    private func markBreakdown(_ stats: PrayerTrackerStats) -> some View {
        let accent = settings.accentColor.accent2
        let parts: [(mark: PrayerMark, count: Int)] = [
            (.onTime, stats.onTimeCount), (.late, stats.lateCount), (.missed, stats.missedCount)
        ].filter { $0.count > 0 }
        let total = parts.reduce(0) { $0 + $1.count }
        let onTimePercent = Int((stats.onTimeFraction * 100).rounded())

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                AccentIconChip(systemImage: "chart.bar.fill", tint: accent, size: 20)

                Text("ON TIME · LATE · MISSED")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 4)

                if stats.totalPrayed > 0 {
                    Text("\(onTimePercent)% on time")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundColor(accent)
                        .lineLimit(1)
                }
            }

            GeometryReader { geo in
                let gaps = CGFloat(max(parts.count - 1, 0)) * 2
                let available = max(geo.size.width - gaps, 0)
                HStack(spacing: 2) {
                    ForEach(parts, id: \.mark) { part in
                        Capsule()
                            .fill(part.mark.tint(accent: accent))
                            .frame(width: max(4, available * CGFloat(part.count) / CGFloat(max(total, 1))))
                    }
                }
            }
            .frame(height: 8)

            HStack(spacing: 12) {
                ForEach(parts, id: \.mark) { part in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(part.mark.tint(accent: accent))
                            .frame(width: 7, height: 7)

                        Text("\(part.count) \(part.mark.shortTitle.lowercased())")
                    }
                }

                Spacer(minLength: 0)
            }
            .font(.caption2.monospacedDigit())
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(12)
        .conditionalGlassEffect(rectangle: true)
    }

    // MARK: History section

    private var historySection: some View {
        Section(header: Text("HISTORY")) {
            // PLAIN binding, deliberately: switching scope swaps a data-dependent set of List rows
            // (day content alone is 0-7 rows) - see the note on `body`.
            Picker("", selection: $scope) {
                ForEach(Scope.allCases) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            .onChange(of: scope) { _ in settings.hapticFeedback() }

            periodNavigator
                .listRowSeparator(.hidden)

            switch scope {
            case .day: dayContent
            case .week: weekContent
            case .month: monthContent
            case .year: yearContent
            }
        }
        .themedListRowBackground()
    }

    // MARK: Period navigation

    private var periodNavigator: some View {
        HStack {
            navButton(symbol: "chevron.left", enabled: canGoBack) { move(-1) }

            Spacer()

            VStack(spacing: 2) {
                Text(periodTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if !isCurrentPeriod {
                    Button {
                        settings.hapticFeedback()
                        anchor = Date()
                    } label: {
                        Text("Back to today")
                            .font(.caption2)
                            .foregroundColor(settings.accentColor.accent2)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            navButton(symbol: "chevron.right", enabled: canGoForward) { move(1) }
        }
        .padding(.vertical, 2)
    }

    private func navButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            // Plain write, no `withAnimation`: moving the period rebuilds data-dependent rows (the Day
            // view swaps between prayer rows and a single note across exempt days), and animating
            // that structural change is the List diff crash the note on `body` describes.
            action()
        } label: {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(enabled ? settings.accentColor.accent2 : .secondary.opacity(0.4))
                .frame(width: 34, height: 34)
                .conditionalGlassEffect()
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var scopeComponent: Calendar.Component {
        switch scope {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }

    private func move(_ delta: Int) {
        if let moved = calendar.date(byAdding: scopeComponent, value: delta, to: anchor) {
            anchor = moved
        }
    }

    private var canGoForward: Bool {
        !calendar.isDate(anchor, equalTo: Date(), toGranularity: scopeComponent) && anchor < Date()
    }

    private var canGoBack: Bool {
        guard let earliest = settings.trackerStats.trackingSince else {
            // Nothing recorded yet: allow browsing back a year, not into the void forever.
            return calendar.dateComponents([.day], from: anchor, to: Date()).day ?? 0 < 366
        }
        guard let lowerBound = calendar.date(byAdding: .year, value: -1, to: earliest) else { return false }
        return anchor > lowerBound
    }

    private var isCurrentPeriod: Bool {
        calendar.isDate(anchor, equalTo: Date(), toGranularity: scopeComponent)
    }

    private var periodTitle: String {
        switch scope {
        case .day:
            return Self.longDateFormatter.string(from: anchor)
        case .week:
            let interval = calendar.dateInterval(of: .weekOfYear, for: anchor)
            guard let interval else { return "" }
            let end = interval.end.addingTimeInterval(-1)
            return "\(Self.shortDateFormatter.string(from: interval.start)) – \(Self.shortDateFormatter.string(from: end))"
        case .month:
            return Self.monthFormatter.string(from: anchor)
        case .year:
            return String(calendar.component(.year, from: anchor))
        }
    }

    // MARK: Day view

    @ViewBuilder
    private var dayContent: some View {
        let day = calendar.startOfDay(for: anchor)
        let isFuture = day > calendar.startOfDay(for: Date())
        let exempt = settings.isTrackerExempt(on: day)

        if isFuture {
            trackerNote("This day hasn't arrived yet.", symbol: "hourglass")
        } else if exempt {
            trackerNote(
                settings.canEditExemption(on: day)
                    ? "Exempt day: prayers were not obligatory and don't count against your record."
                    : "Exempt day: the menses pause is on. End it below when the period is over.",
                symbol: "moon.zzz.fill"
            )
        } else {
            let slots = settings.trackableSlots(for: day)
            if slots.isEmpty {
                trackerNote("Prayer times aren't available for this day.", symbol: "location.slash")
            } else {
                ForEach(slots, id: \.nameTransliteration) { prayer in
                    dayRow(for: prayer, on: day)
                }

                daySummary(slots: slots, on: day)
            }
        }

        if !isFuture, settings.canEditExemption(on: day) {
            Toggle(isOn: Binding(
                get: { settings.isTrackerExempt(on: day) },
                set: { newValue in
                    settings.hapticFeedback()
                    // Plain write: flipping exemption swaps the day's rows (five prayers ↔ one note),
                    // and that structural change must not animate - see the note on `body`.
                    settings.setTrackerExempt(newValue, on: day)
                }
            )) {
                Text("Exempt day (menstruation / postpartum)")
                    .font(.subheadline)
            }
            .tint(settings.accentColor.accent2)
            .padding(.vertical, 2)
        }
    }

    /// One prayer of the day: its name and time, and the three answers as chips underneath. Tapping the
    /// chosen chip again clears the mark.
    private func dayRow(for prayer: Prayer, on day: Date) -> some View {
        let name = prayer.nameTransliteration
        let mark = settings.prayerMark(for: name, on: day)
        let accent = settings.accentColor.accent2

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: prayer.image)
                    .font(.subheadline)
                    .foregroundColor(accent)
                    .frame(width: 24)

                Text(prayer.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Spacer()

                Text(prayer.time, style: .time)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(PrayerMark.allCases, id: \.self) { option in
                    markChip(option, selected: mark == option, accent: accent) {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut(duration: 0.15)) {
                            settings.recordTrackerMark(mark == option ? nil : option, for: name, on: day)
                        }
                    }
                }
            }
            .padding(.leading, 36)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(prayer.displayName): \(mark?.spokenTitle ?? "not marked")")
    }

    private func markChip(_ mark: PrayerMark, selected: Bool, accent: Color, action: @escaping () -> Void) -> some View {
        let tint = mark.tint(accent: accent)

        return Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: mark.symbol)
                    .font(.system(size: 10, weight: .bold))

                Text(mark.shortTitle)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(selected ? .white : tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(selected ? tint : tint.opacity(0.12)))
            .overlay(Capsule().strokeBorder(tint.opacity(selected ? 0 : 0.35), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mark.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func daySummary(slots: [Prayer], on day: Date) -> some View {
        let marks = slots.map { settings.prayerMark(for: $0.nameTransliteration, on: day) }
        let prayed = marks.filter { $0?.isPrayed == true }.count
        let late = marks.filter { $0 == .late }.count
        let missed = marks.filter { $0 == .missed }.count
        let complete = prayed == slots.count

        let text: String
        if complete {
            text = late == 0 ? "All prayers prayed on time, a perfect day." : "All prayers prayed, \(late) late."
        } else {
            var parts = ["\(prayed) of \(slots.count) prayed"]
            if late > 0 { parts.append("\(late) late") }
            if missed > 0 { parts.append("\(missed) missed") }
            text = parts.joined(separator: " · ")
        }

        return Text(text)
            .font(.caption)
            .foregroundColor(complete ? settings.accentColor.accent2 : .secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 2)
            .listRowSeparator(.hidden)
    }

    // MARK: Per-period day index

    /// One day of the shown period, resolved once per render. The week/month/year builders used to call
    /// the accessor methods per CELL, each doing its own formatter + set-union work; one snapshot pass
    /// per period keeps the render cost flat no matter how many cells draw.
    ///
    /// Grid cells are identified by POSITION (the enumerated offset), never by this record's key or
    /// date: a key can only repeat if the display calendar and the storage formatter ever disagree
    /// about a day boundary (a time-zone change between their creation, a DST edge), and a repeated
    /// identity inside a List-hosted grid was a diffing crash on exactly the devices the owner cannot
    /// reproduce on. A position is unique by construction.
    private struct DayRecord {
        /// The Gregorian storage key of this day.
        let key: String
        let date: Date
        /// Canonical prayer → mark, resolved through `Settings.canonicalMarks(of:)`.
        let marks: [String: PrayerMark]
        let tally: PrayerDayTally
        let exempt: Bool
        let isFuture: Bool

        /// Counts toward the period's denominators: a real past-or-present day that isn't exempt.
        var counts: Bool { !isFuture && !exempt }
    }

    /// Memo for `dayRecords`, keyed on the tracker write counter and the civil day. The year view asks
    /// for twelve months of records on every render, and the month and week views for theirs; the
    /// answer changes only when a mark is written or the day rolls over.
    private static var dayRecordsMemo: (generation: Int, day: Date, records: [String: [DayRecord]]) = (-1, .distantPast, [:])

    private func dayRecords(from start: Date, count: Int) -> [DayRecord] {
        let today = calendar.startOfDay(for: Date())
        let generation = settings.trackerGeneration
        if Self.dayRecordsMemo.generation != generation || Self.dayRecordsMemo.day != today {
            Self.dayRecordsMemo = (generation, today, [:])
        }
        let memoKey = "\(start.timeIntervalSinceReferenceDate)-\(count)"
        if let cached = Self.dayRecordsMemo.records[memoKey] { return cached }

        let snapshot = settings.trackerSnapshot()
        let formatter = PrayerTrackerStats.dayKeyFormatter

        var records: [DayRecord] = []
        records.reserveCapacity(max(count, 0))
        var day = calendar.startOfDay(for: start)
        for _ in 0..<max(count, 0) {
            let key = formatter.string(from: day)
            let exempt = snapshot.exemptDays.contains(key)
                || (snapshot.activePauseStartKey.map { key >= $0 } ?? false)
            let marks = Settings.canonicalMarks(of: snapshot.marks[key] ?? [:])
            records.append(DayRecord(key: key, date: day, marks: marks, tally: PrayerDayTally(marks: marks),
                                     exempt: exempt, isFuture: day > today))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            // Re-anchor EVERY step: across a DST transition `byAdding` can leave the running date
            // at 01:00, which then mis-flags today as future and feeds the grids drifting dates.
            day = calendar.startOfDay(for: next)
        }
        Self.dayRecordsMemo.records[memoKey] = records
        return records
    }

    /// The numbers a period summary line reports, from its day records.
    private struct PeriodTotals {
        var prayed = 0
        var possible = 0
        var perfect = 0
        var late = 0
        var missed = 0
        var exempt = 0

        init() {}

        init(records: [DayRecord]) {
            for record in records where !record.isFuture {
                if record.exempt {
                    exempt += 1
                    continue
                }
                prayed += record.tally.prayed
                possible += Settings.canonicalObligatoryPrayers.count
                late += record.tally.late
                missed += record.tally.missed
                if record.tally.isPerfect { perfect += 1 }
            }
        }

        static func + (lhs: PeriodTotals, rhs: PeriodTotals) -> PeriodTotals {
            var sum = PeriodTotals()
            sum.prayed = lhs.prayed + rhs.prayed
            sum.possible = lhs.possible + rhs.possible
            sum.perfect = lhs.perfect + rhs.perfect
            sum.late = lhs.late + rhs.late
            sum.missed = lhs.missed + rhs.missed
            sum.exempt = lhs.exempt + rhs.exempt
            return sum
        }
    }

    // MARK: Week view

    @ViewBuilder
    private var weekContent: some View {
        if let interval = calendar.dateInterval(of: .weekOfYear, for: anchor) {
            let records = dayRecords(from: interval.start, count: 7)

            VStack(spacing: 8) {
                // Header: weekday letters + day numbers.
                weekRow(leading: "", records: records) { record in
                    VStack(spacing: 1) {
                        Text(Self.weekdayLetterFormatter.string(from: record.date))
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)

                        Text("\(calendar.component(.day, from: record.date))")
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(calendar.isDateInToday(record.date) ? settings.accentColor.accent2 : .secondary)
                    }
                }

                ForEach(Settings.canonicalObligatoryPrayers, id: \.self) { name in
                    weekRow(leading: canonicalLabel(name, settings: settings), records: records) { record in
                        weekCell(prayerName: name, record: record)
                    }
                }
            }
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)

            summaryLine(PeriodTotals(records: records))
        }
    }

    private func weekRow<Cell: View>(leading: String, records: [DayRecord], @ViewBuilder cell: @escaping (DayRecord) -> Cell) -> some View {
        HStack(spacing: 4) {
            Text(leading)
                .font(.caption2.weight(.medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(width: 52, alignment: .leading)

            // Positional identity (see DayRecord).
            ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                cell(record)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// One prayer on one day of the week: a filled circle in the mark's color (check, clock, or cross),
    /// an outline while unmarked. Tap marks on time or clears; press and hold opens the chooser.
    @ViewBuilder
    private func weekCell(prayerName: String, record: DayRecord) -> some View {
        let mark = record.marks[prayerName]
        let tint = mark?.tint(accent: settings.accentColor.accent2) ?? .clear
        let dateLabel = Self.shortDateFormatter.string(from: record.date)

        let face = Group {
            if record.exempt {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            } else if record.isFuture {
                Circle()
                    .fill(Color.secondary.opacity(0.06))
            } else if let mark = mark {
                Circle()
                    .fill(tint)
                    .overlay(
                        Image(systemName: mark.symbol)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else {
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1.2)
            }
        }
        .frame(width: 22, height: 22)
        .contentShape(Rectangle())

        if record.counts {
            Menu {
                TrackerMarkPicker(prayerName: prayerName, date: record.date)
            } label: {
                face
            } primaryAction: {
                settings.hapticFeedback()
                withAnimation(.easeInOut(duration: 0.15)) {
                    settings.recordTrackerMark(mark == nil ? .onTime : nil, for: prayerName, on: record.date)
                }
            }
            .menuIndicator(.hidden)
            .buttonStyle(.plain)
            .accessibilityLabel("\(prayerName), \(dateLabel): \(mark?.spokenTitle ?? "not marked")")
            .accessibilityHint("Tap to mark prayed on time. Press and hold for late or missed.")
        } else {
            face
                .accessibilityLabel("\(prayerName), \(dateLabel): \(record.exempt ? "exempt" : "not yet")")
        }
    }

    // MARK: Month view

    /// One cell of the month grid: a day, or the padding that squares the first and last weeks off.
    /// Identified by grid position, which is unique by construction (see DayRecord).
    private struct MonthSlot: Identifiable {
        let id: Int
        let record: DayRecord?
        let dayNumber: Int
    }

    @ViewBuilder
    private var monthContent: some View {
        if let interval = calendar.dateInterval(of: .month, for: anchor) {
            let dayCount = calendar.range(of: .day, in: .month, for: anchor)?.count ?? 30
            let records = dayRecords(from: interval.start, count: dayCount)
            let firstWeekday = calendar.component(.weekday, from: interval.start)
            let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
            let weeks = monthWeeks(records: records, leadingBlanks: max(leadingBlanks, 0))

            // Rows of seven, laid out by hand: a lazy grid inside a List row buys nothing for at most
            // 42 cells, and its diffing was the one moving part in the crash reports the owner could
            // not reproduce. A plain stack of rows has no diff to get wrong.
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        Text(Self.weekdaySymbol(at: (calendar.firstWeekday - 1 + index) % 7))
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 6) {
                        ForEach(week) { slot in
                            Group {
                                if let record = slot.record {
                                    monthCell(record: record, dayNumber: slot.dayNumber)
                                } else {
                                    Color.clear.frame(height: 34)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                monthLegend
            }
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)

            summaryLine(PeriodTotals(records: records))
        }
    }

    /// The month's cells in rows of exactly seven: leading padding for the first week, the days, and
    /// trailing padding to square the last week off.
    private func monthWeeks(records: [DayRecord], leadingBlanks: Int) -> [[MonthSlot]] {
        var slots: [MonthSlot] = []
        slots.reserveCapacity(42)
        for _ in 0..<leadingBlanks {
            slots.append(MonthSlot(id: slots.count, record: nil, dayNumber: 0))
        }
        for (index, record) in records.enumerated() {
            slots.append(MonthSlot(id: slots.count, record: record, dayNumber: index + 1))
        }
        while slots.count % 7 != 0 {
            slots.append(MonthSlot(id: slots.count, record: nil, dayNumber: 0))
        }
        return stride(from: 0, to: slots.count, by: 7).map { Array(slots[$0..<min($0 + 7, slots.count)]) }
    }

    private func monthCell(record: DayRecord, dayNumber: Int) -> some View {
        let day = record.date
        let isFuture = record.isFuture
        let exempt = record.exempt
        let covered = record.tally.prayed
        let total = Settings.canonicalObligatoryPrayers.count
        let isToday = calendar.isDateInToday(day)
        let textColor = monthCellText(covered: covered, total: total, exempt: exempt, isFuture: isFuture)

        return Button {
            guard !isFuture else { return }
            settings.hapticFeedback()
            // Plain writes: month → day swaps the section's row set structurally - see the note on
            // `body`.
            anchor = day
            scope = .day
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(monthCellFill(covered: covered, total: total, exempt: exempt, isFuture: isFuture))

                if isToday {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(settings.accentColor.accent2, lineWidth: 1.5)
                }

                VStack(spacing: 1) {
                    Text("\(dayNumber)")
                        .font(.caption2.monospacedDigit().weight(isToday ? .bold : .regular))
                        .foregroundColor(textColor)

                    if exempt {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 7))
                            .foregroundColor(.secondary)
                    } else if !isFuture && (covered > 0 || record.tally.missed > 0) {
                        HStack(spacing: 2) {
                            Text("\(covered)")
                                .font(.system(size: 8, weight: .semibold).monospacedDigit())
                                .foregroundColor(textColor.opacity(0.85))

                            // A missed prayer outranks a late one for the single dot there is room for.
                            if record.tally.missed > 0 {
                                markDot(.missed)
                            } else if record.tally.late > 0 {
                                markDot(.late)
                            }
                        }
                    }
                }
            }
            .frame(height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(monthCellAccessibilityLabel(record: record, day: day, covered: covered, total: total))
    }

    private func monthCellAccessibilityLabel(record: DayRecord, day: Date, covered: Int, total: Int) -> String {
        let date = Self.longDateFormatter.string(from: day)
        if record.exempt { return "\(date): exempt" }
        var parts = ["\(covered) of \(total) prayed"]
        if record.tally.late > 0 { parts.append("\(record.tally.late) late") }
        if record.tally.missed > 0 { parts.append("\(record.tally.missed) missed") }
        return "\(date): \(parts.joined(separator: ", "))"
    }

    /// The tiny late/missed marker: its own color with a hairline of white, so it stays visible on a
    /// deep accent cell whatever the accent happens to be.
    private func markDot(_ mark: PrayerMark) -> some View {
        Circle()
            .fill(mark.tint(accent: settings.accentColor.accent2))
            .frame(width: 5, height: 5)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: 0.5))
    }

    private func monthCellFill(covered: Int, total: Int, exempt: Bool, isFuture: Bool) -> Color {
        if isFuture { return Color.secondary.opacity(0.05) }
        if exempt { return Color.secondary.opacity(0.12) }
        guard covered > 0 else { return Color.secondary.opacity(0.1) }
        // 1...5 prayed maps to a deepening accent - the heat in the heatmap.
        let intensity = 0.15 + 0.75 * Double(covered) / Double(max(total, 1))
        return settings.accentColor.accent2.opacity(intensity)
    }

    private func monthCellText(covered: Int, total: Int, exempt: Bool, isFuture: Bool) -> Color {
        if isFuture { return .secondary.opacity(0.5) }
        if exempt { return .secondary }
        return covered >= 4 ? Color.white : .primary
    }

    private var monthLegend: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Text("0")
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundColor(.secondary)

                HStack(spacing: 2) {
                    ForEach(0...5, id: \.self) { count in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(count == 0 ? Color.secondary.opacity(0.1)
                                             : settings.accentColor.accent2.opacity(0.15 + 0.75 * Double(count) / 5))
                            .frame(width: 12, height: 12)
                    }
                }

                Text("5 prayed")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 3) {
                markDot(.late)
                Text("late")
                    .font(.system(size: 9))
            }
            .foregroundColor(.secondary)

            HStack(spacing: 3) {
                markDot(.missed)
                Text("missed")
                    .font(.system(size: 9))
            }
            .foregroundColor(.secondary)

            HStack(spacing: 3) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 8))
                Text("exempt")
                    .font(.system(size: 9))
            }
            .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.top, 2)
    }

    // MARK: Year view

    @ViewBuilder
    private var yearContent: some View {
        let year = calendar.component(.year, from: anchor)
        let today = calendar.startOfDay(for: Date())
        let months = yearMonthSummaries(year: year, today: today)

        VStack(spacing: 10) {
            ForEach(months, id: \.month) { summary in
                yearMonthRow(summary: summary, year: year)
            }
        }
        .padding(.vertical, 6)
        .listRowSeparator(.hidden)

        summaryLine(months.reduce(PeriodTotals()) { $0 + $1.totals })
    }

    private struct MonthSummary {
        let month: Int
        let totals: PeriodTotals
    }

    private func yearMonthSummaries(year: Int, today: Date) -> [MonthSummary] {
        (1...12).compactMap { month in
            guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return nil }
            guard start <= today else {
                return MonthSummary(month: month, totals: PeriodTotals())
            }
            let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
            return MonthSummary(month: month, totals: PeriodTotals(records: dayRecords(from: start, count: dayCount)))
        }
    }

    private func yearMonthRow(summary: MonthSummary, year: Int) -> some View {
        let totals = summary.totals
        let fraction = totals.possible > 0 ? Double(totals.prayed) / Double(totals.possible) : 0
        let hasData = totals.possible > 0 || totals.exempt > 0

        return Button {
            guard hasData else { return }
            settings.hapticFeedback()
            // Plain writes: year → month swaps the section's rows structurally - see the note on
            // `body`.
            if let date = calendar.date(from: DateComponents(year: year, month: summary.month, day: 1)) {
                anchor = date
                scope = .month
            }
        } label: {
            HStack(spacing: 10) {
                Text(Self.monthSymbol(at: summary.month - 1))
                    .font(.caption.weight(.medium))
                    .foregroundColor(hasData ? .primary : .secondary.opacity(0.5))
                    .frame(width: 36, alignment: .leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.12))

                        if fraction > 0 {
                            Capsule()
                                .fill(settings.accentColor.accent2.opacity(0.35 + 0.65 * fraction))
                                .frame(width: max(6, geo.size.width * fraction))
                        }
                    }
                }
                .frame(height: 10)

                Text(totals.possible > 0 ? "\(Int((fraction * 100).rounded()))%" : (totals.exempt > 0 ? "exempt" : "–"))
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundColor(totals.possible > 0 ? settings.accentColor.accent2 : .secondary.opacity(0.6))
                    .frame(width: 48, alignment: .trailing)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Menses pause

    private var mensesSection: some View {
        Section(
            header: Text("MENSTRUATION & POSTPARTUM"),
            footer: Text("During menstruation or postpartum bleeding, the five daily prayers are not obligatory and are not made up afterward; this is Allah's mercy, not a shortfall. While paused, days are marked exempt: they never break a streak or count in any statistic, and \"Did you pray?\" reminders stay silent. Prayer time notifications continue as usual. Past days can be corrected with the exempt toggle in the Day view.")
                .font(.caption2)
        ) {
            Toggle(isOn: Binding(
                get: { settings.mensesPauseActive },
                set: { newValue in
                    settings.hapticFeedback()
                    // Plain write: the pause swaps today's rows in the Day view (and the Adhan tab's
                    // card), and that structural change must not animate - see the note on `body`.
                    settings.setMensesPause(newValue)
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pause tracking")
                        .font(.subheadline)

                    if settings.mensesPauseActive, let start = settings.mensesPauseStartDate {
                        Text("Paused since \(Self.longDateFormatter.string(from: start))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(settings.accentColor.accent2)
            .padding(.vertical, 2)
        }
        .themedListRowBackground()
    }

    // MARK: Guidance

    private var guidanceSection: some View {
        Section(header: Text("GOOD TO KNOW")) {
            VStack(alignment: .leading, spacing: 12) {
                guidanceRow(symbol: "hand.tap",
                            text: "Tap a prayer to mark it prayed on time, and tap again to clear it. Press and hold to record it as prayed late or missed; the Day view offers all three directly.")

                guidanceRow(symbol: "person.3",
                            text: "Jumuah (Friday prayer) counts as Dhuhr; marking either one covers that day's noon prayer.")

                guidanceRow(symbol: "airplane",
                            text: "While traveling, the combined Dhuhr/Asr and Maghrib/Isha each count as both of their prayers.")

                guidanceRow(symbol: "clock.arrow.circlepath",
                            text: "Missed a prayer? Pray it as soon as you remember. The Prophet ﷺ said: \"Whoever forgets a prayer, let him pray it when he remembers it\" (Bukhari 597). Then mark it here as prayed late.")

                guidanceRow(symbol: "flame",
                            text: "A streak is a day where all five prayers were prayed, on time or late. A perfect day is all five on time. Exempt days never break a streak; it continues right through them.")
            }
            .padding(.vertical, 8)
        }
        .themedListRowBackground()
    }

    private func guidanceRow(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.footnote)
                .foregroundColor(settings.accentColor.accent2)
                .frame(width: 20)
                .padding(.top, 1)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// A full-width informational row - the Day view's empty/exempt/future states.
    private func trackerNote(_ text: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundColor(settings.accentColor.accent2)
                .frame(width: 22)

            Text(text)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .listRowSeparator(.hidden)
    }

    // MARK: Shared summary line + formatters

    private func summaryLine(_ totals: PeriodTotals) -> some View {
        let percent = totals.possible > 0 ? Int((Double(totals.prayed) / Double(totals.possible) * 100).rounded()) : 0

        return HStack(spacing: 10) {
            Label("\(totals.prayed)/\(totals.possible) prayed", systemImage: "checkmark.circle")
            Label("\(percent)%", systemImage: "percent")
            Label("\(totals.perfect) perfect", systemImage: "star")
            if totals.late > 0 {
                Label("\(totals.late) late", systemImage: "clock")
                    .foregroundColor(.orange)
            }
            if totals.missed > 0 {
                Label("\(totals.missed) missed", systemImage: "xmark.circle")
                    .foregroundColor(.red)
            }
            Spacer()
        }
        .font(.caption2.monospacedDigit())
        .foregroundColor(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .padding(.vertical, 2)
        .listRowSeparator(.hidden)
    }

    /// Every display formatter and symbol table below is pinned to the same localized GREGORIAN
    /// calendar the grid math uses (see `calendar`): month titles, dates, and weekday letters must
    /// name the months the grid is actually drawing, in the user's language.
    private static let displayCalendar: Calendar = {
        var pinned = Calendar(identifier: .gregorian)
        pinned.locale = Locale.current
        pinned.firstWeekday = Calendar.current.firstWeekday
        pinned.timeZone = Calendar.current.timeZone
        return pinned
    }()

    private static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = displayCalendar
        formatter.dateStyle = .medium
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = displayCalendar
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = displayCalendar
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()

    private static let weekdayLetterFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = displayCalendar
        formatter.setLocalizedDateFormatFromTemplate("EEEEE")
        return formatter
    }()

    // Localized Gregorian symbols (matching `displayCalendar`). The safe accessors below stay as
    // the last line of defense: no symbol lookup may ever trap the month grid.
    private static let weekdaySymbols: [String] = displayCalendar.veryShortWeekdaySymbols
    private static let monthSymbols: [String] = displayCalendar.shortMonthSymbols

    private static func weekdaySymbol(at index: Int) -> String {
        weekdaySymbols.indices.contains(index) ? weekdaySymbols[index] : "•"
    }

    private static func monthSymbol(at index: Int) -> String {
        monthSymbols.indices.contains(index) ? monthSymbols[index] : "M\(index + 1)"
    }
}

#Preview {
    AlIslamPreviewContainer {
        PrayerTrackerView()
    }
}
#endif
