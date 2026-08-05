#if os(iOS)
import SwiftUI

// MARK: - Statistics engine

/// Everything the tracker UI reports, computed in ONE forward pass over the recorded history and cached
/// against the underlying data (see `Settings.trackerStats`) - the Adhan tab re-renders every countdown
/// tick, and walking years of history per frame is exactly the kind of work that must not happen there.
///
/// All statistics are computed on CANONICAL coverage (`Settings.canonicalCoverage`), so a traveling-day
/// "Dhuhr/Asr" counts as both prayers and a Friday "Jumuah" counts as Dhuhr. Exempt days (menstruation /
/// postpartum) are neutral everywhere: they neither break a streak nor count in any denominator.
struct PrayerTrackerStats: Equatable {
    /// Consecutive complete days ending now. Today only joins once complete, but an incomplete today
    /// never breaks the run - the day isn't over.
    var currentStreak = 0
    var bestStreak = 0
    /// Canonical prayers covered across all recorded history.
    var totalPrayed = 0
    /// Days with all five covered.
    var perfectDays = 0
    /// Countable (non-exempt) days from the first recorded day through today.
    var trackedDays = 0
    var exemptDayCount = 0
    /// The first day anything was recorded, nil until tracking begins.
    var trackingSince: Date?

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
                let covered = (snapshot.marks[key] ?? []).reduce(into: Set<String>()) {
                    $0.formUnion(Settings.canonicalCoverage(of: $1))
                }
                stats.totalPrayed += covered.count
                if covered.count == Settings.canonicalObligatoryPrayers.count {
                    stats.perfectDays += 1
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

extension Settings {
    /// Cache slot for `trackerStats`, keyed by a stamp of everything the stats derive from.
    private static var trackerStatsCache: (stamp: Int, stats: PrayerTrackerStats)?

    /// The current statistics, recomputed only when the underlying data actually changed.
    var trackerStats: PrayerTrackerStats {
        var hasher = Hasher()
        hasher.combine(prayerTrackerData)
        hasher.combine(trackerExemptDaysData)
        hasher.combine(mensesPauseActive)
        hasher.combine(mensesPauseStartStamp)
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
}

// MARK: - Shared bits

private let canonicalPrayerImages: [String: String] = [
    "Fajr": "sunrise", "Dhuhr": "sun.max", "Asr": "sun.min",
    "Maghrib": "sunset", "Isha": "moon"
]

private func canonicalLabel(_ name: String, settings: Settings) -> String {
    settings.customPrayerName(for: name) ?? name
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

/// One tappable prayer slot: icon in a circle that fills when prayed, name underneath.
private struct TrackerPrayerToggle: View {
    @ObservedObject private var settings = Settings.shared

    let prayer: Prayer
    let date: Date

    var body: some View {
        let prayed = settings.isPrayerMarkedPrayed(prayer.nameTransliteration, on: date)

        Button {
            settings.hapticFeedback()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                settings.setPrayerPrayed(prayer.nameTransliteration, on: date, prayed: !prayed)
            }

            // Marking the day's last unprayed slot is the app's clearest moment of delight - the one
            // point where asking for a rating lands on a "win". Every gate (cooldown, session and usage
            // minimums, yearly quota) re-checks inside the manager, so this is safe to call every time.
            if !prayed, Calendar.current.isDateInToday(date) {
                let slots = settings.trackableSlots(for: date)
                if !slots.isEmpty, settings.trackedPrayerCount(slots.map(\.nameTransliteration)) == slots.count {
                    AppReviewManager.shared.requestAtMomentOfDelight()
                }
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if prayed {
                        // The accent chip gradient, in circle form - marking a prayer should feel
                        // like a win, not a change of outline.
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [settings.accentColor.accent2.opacity(0.95), settings.accentColor.accent2.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: settings.accentColor.accent2.opacity(0.4), radius: 6, x: 0, y: 2)
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.08))

                        Circle()
                            .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)
                    }

                    Image(systemName: prayed ? "checkmark" : prayer.image)
                        .font(.subheadline.weight(prayed ? .bold : .regular))
                        .foregroundColor(prayed ? .white : .secondary)
                }
                .frame(width: 40, height: 40)

                Text(prayer.compactTrackerName)
                    .font(.caption2.weight(prayed ? .semibold : .regular))
                    .foregroundColor(prayed ? settings.accentColor.accent2 : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(prayer.displayName): \(prayed ? "prayed" : "not marked")")
    }
}

private extension Prayer {
    /// Short label under a tracker circle - the user's custom spelling, compacted for the tight grid.
    var compactTrackerName: String {
        displayName
    }
}

// MARK: - The tracker section (Adhan tab, underneath Prayer Times)

/// The prayer tracker as its own section: today's ring + streak, the five tap-to-toggle slots, and the
/// doorway into the full history. Standalone struct on purpose - a new Adhan-tab section must never be
/// an inline closure of an already-deep view tree.
struct PrayerTrackerSection: View {
    @ObservedObject private var settings = Settings.shared

    private var todaySlots: [Prayer] {
        settings.trackableSlots(for: Date())
    }

    var body: some View {
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
        let prayed = settings.trackedPrayerCount(slots.map(\.nameTransliteration))

        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                TrackerProgressRing(prayed: prayed, total: slots.count)

                VStack(alignment: .leading, spacing: 3) {
                    Text(prayed == slots.count && !slots.isEmpty ? "All prayers completed" : "Today")
                        .font(.subheadline.weight(.semibold))

                    Text(prayed == slots.count && !slots.isEmpty
                         ? "Alhamdulillah, every prayer prayed."
                         : "\(prayed) of \(slots.count) prayed. Tap a prayer to mark it.")
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

    @State private var scope: Scope = .day
    /// The date the shown period is anchored on - navigation moves it by one day/week/month/year.
    @State private var anchor = Date()

    /// Gregorian with the user's region intact (week start, timezone, localized names): the tracker's
    /// storage keys, pruning, and menses ranges are all Gregorian "yyyy-MM-dd", so the GRID must count
    /// months the same way. Under a system-wide Hijri calendar, plain `Calendar.current` drew
    /// 29/30-cell Hijri months over Gregorian-keyed data and fed Hijri years into the year view - the
    /// Hijri calendar has its own screen (CalendarView), the tracker is a civil-day log. One shared
    /// pinned instance (`displayCalendar`) so grid math and every formatter/symbol agree, built once:
    /// this is read per cell.
    private var calendar: Calendar { Self.displayCalendar }

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
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                statTile(value: "\(stats.currentStreak)", unit: stats.currentStreak == 1 ? "day" : "days",
                         label: "Current Streak", symbol: "flame.fill")
                statTile(value: "\(stats.bestStreak)", unit: stats.bestStreak == 1 ? "day" : "days",
                         label: "Best Streak", symbol: "trophy.fill")
                statTile(value: "\(stats.perfectDays)", unit: stats.perfectDays == 1 ? "day" : "days",
                         label: "Perfect Days", symbol: "star.fill")
                statTile(value: "\(stats.totalPrayed)", unit: "prayers",
                         label: "Prayers Logged", symbol: "checkmark.seal.fill")
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

    // MARK: History section

    private var historySection: some View {
        Section(header: Text("HISTORY")) {
            // PLAIN binding, deliberately: switching scope swaps a data-dependent set of List rows
            // (day content alone is 0-7 rows), and an ANIMATED structural diff of List rows is the
            // same UICollectionView update-assertion crash the search results hit (see the
            // SearchBar note in QuranView). Same rule for every anchor/scope write below.
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
            withAnimation { action() }
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

                let prayed = settings.trackedPrayerCount(slots.map(\.nameTransliteration), on: day)
                Text(prayed == slots.count
                     ? "All prayers prayed, a perfect day."
                     : "\(prayed) of \(slots.count) prayed")
                    .font(.caption)
                    .foregroundColor(prayed == slots.count ? settings.accentColor.accent2 : .secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
                    .listRowSeparator(.hidden)
            }
        }

        if !isFuture, settings.canEditExemption(on: day) {
            Toggle(isOn: Binding(
                get: { settings.isTrackerExempt(on: day) },
                set: { newValue in
                    settings.hapticFeedback()
                    withAnimation { settings.setTrackerExempt(newValue, on: day) }
                }
            ).animation(.easeInOut)) {
                Text("Exempt day (menstruation / postpartum)")
                    .font(.subheadline)
            }
            .tint(settings.accentColor.accent2)
            .padding(.vertical, 2)
        }
    }

    private func dayRow(for prayer: Prayer, on day: Date) -> some View {
        let prayed = settings.isPrayerMarkedPrayed(prayer.nameTransliteration, on: day)

        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.15)) {
                settings.setPrayerPrayed(prayer.nameTransliteration, on: day, prayed: !prayed)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: prayer.image)
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.accent2)
                    .frame(width: 24)

                Text(prayer.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Spacer()

                Text(prayer.time, style: .time)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)

                Image(systemName: prayed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(prayed ? settings.accentColor.accent2 : .secondary.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(prayer.displayName): \(prayed ? "prayed" : "not marked")")
    }

    // MARK: Per-period day index

    /// One day of the shown period, resolved once per render. The week/month/year builders used to call
    /// `coveredCanonicalPrayers`/`isTrackerExempt` per CELL, each doing its own formatter + set-union
    /// work; one snapshot pass per period keeps the render cost flat no matter how many cells draw.
    private struct DayRecord: Identifiable {
        /// The Gregorian storage key doubles as the ForEach identity. A raw `Date` id could go
        /// DUPLICATE or drift when a DST transition leaves consecutive "days" an hour apart -
        /// duplicate ids in a List-hosted grid is a diffing crash on exactly the devices/timezones
        /// the owner can't reproduce on. The key is unique and stable by construction.
        let key: String
        let date: Date
        let covered: Set<String>
        let exempt: Bool
        let isFuture: Bool

        var id: String { key }
    }

    private func dayRecords(from start: Date, count: Int) -> [DayRecord] {
        let snapshot = settings.trackerSnapshot()
        let today = calendar.startOfDay(for: Date())
        let formatter = PrayerTrackerStats.dayKeyFormatter

        var records: [DayRecord] = []
        records.reserveCapacity(max(count, 0))
        var day = calendar.startOfDay(for: start)
        for _ in 0..<max(count, 0) {
            let key = formatter.string(from: day)
            let exempt = snapshot.exemptDays.contains(key)
                || (snapshot.activePauseStartKey.map { key >= $0 } ?? false)
            let covered = (snapshot.marks[key] ?? []).reduce(into: Set<String>()) {
                $0.formUnion(Settings.canonicalCoverage(of: $1))
            }
            records.append(DayRecord(key: key, date: day, covered: covered, exempt: exempt, isFuture: day > today))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            // Re-anchor EVERY step: across a DST transition `byAdding` can leave the running date
            // at 01:00, which then mis-flags today as future and feeds the grids drifting dates.
            day = calendar.startOfDay(for: next)
        }
        return records
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

            weekSummary(records: records)
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

            ForEach(records) { record in
                cell(record)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func weekCell(prayerName: String, record: DayRecord) -> some View {
        let covered = record.covered.contains(prayerName)

        Button {
            guard !record.isFuture, !record.exempt else { return }
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.15)) {
                settings.setPrayerPrayed(prayerName, on: record.date, prayed: !covered)
            }
        } label: {
            Group {
                if record.exempt {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                } else if record.isFuture {
                    Circle()
                        .fill(Color.secondary.opacity(0.06))
                } else if covered {
                    Circle()
                        .fill(settings.accentColor.accent2)
                        .overlay(
                            Image(systemName: "checkmark")
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
        }
        .buttonStyle(.plain)
        .disabled(record.isFuture || record.exempt)
        .accessibilityLabel("\(prayerName), \(Self.shortDateFormatter.string(from: record.date)): \(record.exempt ? "exempt" : covered ? "prayed" : "not marked")")
    }

    private func weekSummary(records: [DayRecord]) -> some View {
        var prayed = 0, possible = 0, perfect = 0
        for record in records where !record.isFuture && !record.exempt {
            prayed += record.covered.count
            possible += Settings.canonicalObligatoryPrayers.count
            if record.covered.count == Settings.canonicalObligatoryPrayers.count { perfect += 1 }
        }

        return summaryLine(prayed: prayed, possible: possible, perfect: perfect)
    }

    // MARK: Month view

    @ViewBuilder
    private var monthContent: some View {
        if let interval = calendar.dateInterval(of: .month, for: anchor) {
            let dayCount = calendar.range(of: .day, in: .month, for: anchor)?.count ?? 30
            let records = dayRecords(from: interval.start, count: dayCount)
            let firstWeekday = calendar.component(.weekday, from: interval.start)
            let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

            VStack(spacing: 8) {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        Text(Self.weekdaySymbol(at: (calendar.firstWeekday - 1 + index) % 7))
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    ForEach(0..<max(leadingBlanks, 0), id: \.self) { _ in
                        Color.clear.frame(height: 34)
                    }

                    // Identity = the record's Gregorian day KEY (see DayRecord): raw Dates could
                    // duplicate across a DST transition and crash the grid's diff.
                    ForEach(Array(records.enumerated()), id: \.element.key) { index, record in
                        monthCell(record: record, dayNumber: index + 1)
                    }
                }

                monthLegend
            }
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)

            monthSummary(records: records)
        }
    }

    @ViewBuilder
    private func monthCell(record: DayRecord, dayNumber: Int) -> some View {
        let day = record.date
        let isFuture = record.isFuture
        let exempt = record.exempt
        let covered = record.covered.count
        let total = Settings.canonicalObligatoryPrayers.count
        let isToday = calendar.isDateInToday(day)

        Button {
            guard !isFuture else { return }
            settings.hapticFeedback()
            // Plain writes: month → day swaps the section's row set structurally (see the scope
            // picker note) - animating that swap is the List diff crash.
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
                        .foregroundColor(monthCellText(covered: covered, total: total, exempt: exempt, isFuture: isFuture))

                    if exempt {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 7))
                            .foregroundColor(.secondary)
                    } else if !isFuture && covered > 0 {
                        Text("\(covered)")
                            .font(.system(size: 8, weight: .semibold).monospacedDigit())
                            .foregroundColor(monthCellText(covered: covered, total: total, exempt: exempt, isFuture: isFuture).opacity(0.85))
                    }
                }
            }
            .frame(height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel("\(Self.longDateFormatter.string(from: day)): \(exempt ? "exempt" : "\(covered) of \(total) prayed")")
    }

    private func monthCellFill(covered: Int, total: Int, exempt: Bool, isFuture: Bool) -> Color {
        if isFuture { return Color.secondary.opacity(0.05) }
        if exempt { return Color.secondary.opacity(0.12) }
        guard covered > 0 else { return Color.secondary.opacity(0.1) }
        // 1...5 prayed maps to a deepening accent - the heat in the heatmap.
        let intensity = 0.15 + 0.75 * Double(covered) / Double(total)
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

    private func monthSummary(records: [DayRecord]) -> some View {
        var prayed = 0, possible = 0, perfect = 0
        for record in records where !record.isFuture && !record.exempt {
            prayed += record.covered.count
            possible += Settings.canonicalObligatoryPrayers.count
            if record.covered.count == Settings.canonicalObligatoryPrayers.count { perfect += 1 }
        }

        return summaryLine(prayed: prayed, possible: possible, perfect: perfect)
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

        let prayed = months.reduce(0) { $0 + $1.prayed }
        let possible = months.reduce(0) { $0 + $1.possible }
        let perfect = months.reduce(0) { $0 + $1.perfect }
        summaryLine(prayed: prayed, possible: possible, perfect: perfect)
    }

    private struct MonthSummary {
        let month: Int
        let prayed: Int
        let possible: Int
        let perfect: Int
        let exempt: Int
    }

    private func yearMonthSummaries(year: Int, today: Date) -> [MonthSummary] {
        (1...12).compactMap { month in
            guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return nil }
            guard start <= today else {
                return MonthSummary(month: month, prayed: 0, possible: 0, perfect: 0, exempt: 0)
            }
            let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 30

            var prayed = 0, possible = 0, perfect = 0, exempt = 0
            for record in dayRecords(from: start, count: dayCount) where !record.isFuture {
                if record.exempt {
                    exempt += 1
                    continue
                }
                prayed += record.covered.count
                possible += Settings.canonicalObligatoryPrayers.count
                if record.covered.count == Settings.canonicalObligatoryPrayers.count { perfect += 1 }
            }
            return MonthSummary(month: month, prayed: prayed, possible: possible, perfect: perfect, exempt: exempt)
        }
    }

    private func yearMonthRow(summary: MonthSummary, year: Int) -> some View {
        let fraction = summary.possible > 0 ? Double(summary.prayed) / Double(summary.possible) : 0
        let hasData = summary.possible > 0 || summary.exempt > 0

        return Button {
            guard hasData || summary.possible > 0 else { return }
            settings.hapticFeedback()
            // Plain writes: year → month swaps the section's rows structurally (see the scope
            // picker note) - animating that swap is the List diff crash.
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

                Text(summary.possible > 0 ? "\(Int((fraction * 100).rounded()))%" : (summary.exempt > 0 ? "exempt" : "–"))
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundColor(summary.possible > 0 ? settings.accentColor.accent2 : .secondary.opacity(0.6))
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
                    withAnimation { settings.setMensesPause(newValue) }
                }
            ).animation(.easeInOut)) {
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
                guidanceRow(symbol: "person.3",
                            text: "Jumuah (Friday prayer) counts as Dhuhr; marking either one covers that day's noon prayer.")

                guidanceRow(symbol: "airplane",
                            text: "While traveling, the combined Dhuhr/Asr and Maghrib/Isha each count as both of their prayers.")

                guidanceRow(symbol: "clock.arrow.circlepath",
                            text: "Missed a prayer? Pray it as soon as you remember. The Prophet ﷺ said: \"Whoever forgets a prayer, let him pray it when he remembers it\" (Bukhari 597). Then mark it here.")

                guidanceRow(symbol: "flame",
                            text: "A streak is a day where all five prayers were prayed. Exempt days never break a streak; it continues right through them.")
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

    private func summaryLine(prayed: Int, possible: Int, perfect: Int) -> some View {
        let percent = possible > 0 ? Int((Double(prayed) / Double(possible) * 100).rounded()) : 0

        return HStack(spacing: 12) {
            Label("\(prayed)/\(possible) prayed", systemImage: "checkmark.circle")
            Label("\(percent)%", systemImage: "percent")
            Label("\(perfect) perfect", systemImage: "star")
            Spacer()
        }
        .font(.caption2.monospacedDigit())
        .foregroundColor(.secondary)
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
