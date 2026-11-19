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
        // The device's zone as it is NOW, not at first use: a mark made after a trip filed under
        // the departure zone's date (Quality Guide P1).
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func compute(for settings: Settings) -> PrayerTrackerStats {
        let snapshot = settings.trackerSnapshot()
        return compute(marks: snapshot.marks, exemptDays: snapshot.exemptDays,
                       activePauseStartKey: snapshot.activePauseStartKey, resumeDays: snapshot.resumeDays,
                       earliestKey: settings.trackerEarliestDayKey(), today: Date(), calendar: .current)
    }

    /// The walk itself, on plain values so it is tested without the stores
    /// (UnitTests/PrayerTrackerPauseTests.swift).
    /// - Parameter resumeDays: the days a pause ended on. Tracked like any other day, except that
    ///   one left incomplete does not end the run (`Settings.isTrackerResumeDay`).
    static func compute(
        marks: [String: [String: PrayerMark]],
        exemptDays: Set<String>,
        activePauseStartKey: String?,
        resumeDays: Set<String> = [],
        earliestKey: String?,
        today: Date,
        calendar: Calendar
    ) -> PrayerTrackerStats {
        var stats = PrayerTrackerStats()
        guard let earliestKey, let firstDay = dayKeyFormatter.date(from: earliestKey) else { return stats }

        let snapshot = (marks: marks, exemptDays: exemptDays, activePauseStartKey: activePauseStartKey)
        let today = calendar.startOfDay(for: today)
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
                } else if day < today, !resumeDays.contains(key) {
                    run = 0
                }
                // An incomplete TODAY falls through without resetting: the streak survives until
                // midnight actually passes without the day being completed. So does the day a
                // pause ended on, for good: its earlier prayers fell inside the period.
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            // Re-anchored every step, like `dayRecords`: where the clocks skip midnight (Cairo,
            // Beirut, Santiago) the running date sat at 01:00 from the change onward, was never
            // `<= today` on the last step, and today dropped out of every total and the streak.
            day = calendar.startOfDay(for: next)
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

    /// What a prayer just marked means to the review prompt (AppReview.swift). A prayed mark that
    /// completes today's last open slot is the app's clearest moment of delight, and asks. Any other
    /// prayed mark is a small win, remembered for the next pause. A prayer just recorded as missed is
    /// no moment to ask for anything, so the prompt keeps quiet for a few minutes. Only today's marks
    /// count: filling in last week's history is bookkeeping. Every rule (spacing between asks, real
    /// use since the last one, the launch cover) is checked again inside the manager, so this is safe
    /// to call on every mark. Called after the mark is stored.
    @MainActor
    func noteReviewMoment(for mark: PrayerMark, on date: Date) {
        guard Calendar.current.isDateInToday(date) else { return }
        guard mark.isPrayed else {
            AppReviewManager.shared.noteSetback(.minor)
            return
        }
        let slots = trackableSlots(for: date)
        if !slots.isEmpty, trackedPrayerCount(slots.map(\.nameTransliteration)) == slots.count {
            AppReviewManager.shared.celebrate(.big)
        } else {
            AppReviewManager.shared.bank(.small)
        }
    }
}

// MARK: - Full history page

/// History & Insights. Top to bottom: today's ring and the streak, the INSIGHTS for a chosen span,
/// the HISTORY by day, week, month and year, the missed prayers still to make up, the two opt-in
/// extras, the menses pause, and how it all works (PrayerTrackerPages.swift holds the sections that
/// are not the history itself).
struct PrayerTrackerView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    private enum Scope: String, CaseIterable, Identifiable {
        case day = "Day", week = "Week", month = "Month", year = "Year"
        var id: String { rawValue }
    }

    @State private var scope: Scope = Self.launchScope
    /// The date the shown period is anchored on - navigation moves it by one day/week/month/year.
    @State private var anchor = Date()
    /// The span the Insights section reports on.
    @State private var range: TrackerRange = Self.launchRange
    /// A week-grid tap on a prayer whose time has ended (`tapTrackerSlot`).
    @State private var asking: TrackerAsk?
    /// Counts the pause switch's flips, so the page can keep the switch in sight (see `body`).
    @State private var pauseFlips = 0

    /// DEBUG launch argument `-trackerScope day|week|month|year`: the scope the page opens on, so each
    /// history view can be screenshotted headlessly (pair with `-openPrayerTracker`).
    private static var launchScope: Scope {
        #if DEBUG
        if let value = launchValue("-trackerScope"),
           let scope = Scope.allCases.first(where: { $0.rawValue.lowercased() == value }) {
            return scope
        }
        #endif
        return .day
    }

    /// DEBUG launch argument `-trackerRange week|month|year|all`: the span Insights opens on.
    private static var launchRange: TrackerRange {
        #if DEBUG
        if let value = launchValue("-trackerRange"), let range = TrackerRange(rawValue: value) { return range }
        #endif
        return .month
    }

    #if DEBUG
    private static func launchValue(_ flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1].lowercased()
    }
    #endif

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
        ScrollViewReader { proxy in
            List {
                heroSection
                TrackerInsightsSection(range: $range)
                historySection
                TrackerMissedSection()
                TrackerAlsoTrackSection()
                mensesSection
                TrackerHelpSection()
            }
            .environment(\.defaultMinListRowHeight, 1)
            .applyConditionalListStyle()
            // The Day view sits above the pause switch and trades five prayer rows for one note
            // when it flips, which threw the switch off the screen under the finger that had just
            // touched it. Brought back once the rows have changed, and not animated.
            .onChange(of: pauseFlips) { _ in
                DispatchQueue.main.async { proxy.scrollTo("pause", anchor: .center) }
            }
            .navigationTitle("Prayer Tracker")
            .navigationBarTitleDisplayMode(.inline)
            #if DEBUG
            // `-trackerScrollTo insights|history|missed|more|help`: brings a section to the top for
            // a headless screenshot (the page is three screens tall).
            .onAppear {
                guard let target = Self.launchValue("-trackerScrollTo") else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    proxy.scrollTo(target, anchor: .top)
                }
            }
            #endif
        }
    }

    // MARK: Hero: today and the streak

    private var heroSection: some View {
        let stats = settings.trackerStats
        let today = settings.currentTrackerDay()
        let exempt = settings.isTrackerExempt(on: today)
        let canonical = settings.canonicalMarks(forDayKey: settings.trackerDayKey(for: today))
        let prayed = canonical.values.filter(\.isPrayed).count
        let total = Settings.canonicalObligatoryPrayers.count
        let onTimePercent = PrayerTrackerInsights.percent(stats.onTimeFraction)

        return Section {
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    TrackerRingBadge(marks: exempt ? PrayerDayRing.empty : PrayerDayRing.marks(from: canonical),
                                     exempt: exempt, size: 86)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(Calendar.current.isDateInToday(today) ? "TODAY" : "YESTERDAY, UNTIL FAJR")
                            .font(.caption2.weight(.bold))
                            .tracking(0.6)
                            .foregroundColor(.secondary)

                        Text(exempt ? String(localized: "Exempt day")
                                    : (prayed == total ? String(localized: "All prayers completed")
                                                       : String(localized: "\(prayed) of \(total) prayed")))
                            .font(.title3.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        streakProgress(stats.currentStreak)
                    }

                    Spacer(minLength: 0)
                }

                // Plain stacks, not a lazy grid: four tiles inside one List row have nothing to be lazy
                // about, and a lazy container's own diffing is one more moving part inside a row.
                VStack(spacing: 10) {
                    // Each pair sized by its taller tile (the tiles fill the row's height).
                    HStack(spacing: 10) {
                        statTile(number: stats.bestStreak.formatted(.number.grouping(.never)),
                                 unit: Self.daysPhrase(stats.bestStreak),
                                 label: String(localized: "Best Streak"), symbol: "trophy.fill")
                        statTile(number: stats.perfectDays.formatted(.number.grouping(.never)),
                                 unit: Self.daysPhrase(stats.perfectDays),
                                 label: String(localized: "Perfect Days"), symbol: "star.fill")
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 10) {
                        statTile(number: stats.totalPrayed.formatted(.number.grouping(.never)),
                                 unit: CountPhrase(AttributedString(localized: "**\(stats.totalPrayed)** prayers",
                                                                    comment: "Prayer Tracker stat tile: the count, drawn large (keep it inside the ** marks), and its unit")),
                                 label: String(localized: "Prayers Logged"), symbol: "checkmark.seal.fill")
                        statTile(number: stats.totalPrayed > 0 ? trackerPercentText(onTimePercent) : "–",
                                 unit: nil,
                                 label: String(localized: "Prayed On Time"), symbol: "clock.badge.checkmark.fill")
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }

                if let since = stats.trackingSince {
                    Text(String(localized: "Tracking since \(Self.longDateFormatter.string(from: since))")
                         + (stats.exemptDayCount > 0 ? JoinSeparator.dot + (stats.exemptDayCount == 1 ? String(localized: "\(stats.exemptDayCount) exempt day") : String(localized: "\(stats.exemptDayCount) exempt days")) : ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)
        }
        .themedListRowBackground()
    }

    /// The streak as a count and as progress to the next length the achievements mark: "14-day
    /// streak", a bar from 14 toward 30, "16 days to a 30-day streak".
    private func streakProgress(_ streak: Int) -> some View {
        let accent = settings.accentColor.accent2
        let milestone = PrayerTrackerStats.streakMilestone(after: streak)
        let span = max(milestone.to - milestone.from, 1)
        let fraction = CGFloat(streak - milestone.from) / CGFloat(span)
        let left = milestone.to - streak

        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                Text(streak > 0 ? String(localized: "\(streak)-day streak") : String(localized: "No streak yet"))
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(streak > 0 ? accent : .secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(accent.opacity(0.16))

                    Capsule()
                        .fill(accent)
                        .frame(width: max(streak > 0 ? 5 : 0, geo.size.width * min(max(fraction, 0), 1)))
                }
            }
            .frame(height: 5)
            .accessibilityHidden(true)

            Text((left == 1 ? String(localized: "\(left) day to a \(milestone.to)-day streak")
                            : String(localized: "\(left) days to a \(milestone.to)-day streak")).localizedDigits)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    /// "**1** day" / "**12** days": the unit is read from a phrase on the count (`CountPhrase`), so Arabic can
    /// make the noun agree with the number through plural variations; English keeps its day / days split.
    private static func daysPhrase(_ count: Int) -> CountPhrase {
        CountPhrase(count == 1
            ? AttributedString(localized: "**\(count)** day",
                               comment: "Prayer Tracker stat tile: the count, drawn large (keep it inside the ** marks), and its unit")
            : AttributedString(localized: "**\(count)** days",
                               comment: "Prayer Tracker stat tile: the count, drawn large (keep it inside the ** marks), and its unit"))
    }

    private func statTile(number: String, unit: CountPhrase?, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                AccentIconChip(systemImage: symbol, tint: settings.accentColor.accent2, size: 20)

                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    // Wraps to a second line at the large text sizes ("CURRENT STR..." before), and
                    // only then scales.
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.7)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let unit, !unit.before.isEmpty {
                    unitText(unit.before)
                }

                // One line whatever the text size: at the accessibility sizes "443 prayers" wrapped
                // INSIDE the number ("44", then "3" beneath it). The number keeps its room and the
                // unit gives way.
                Text(number.localizedDigits)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .layoutPriority(1)

                if let unit, !unit.after.isEmpty {
                    unitText(unit.after)
                }
            }
        }
        // Fills the row's height too, so a wrapped caption never leaves its neighbour a shorter tile.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .conditionalGlassEffect(rectangle: true)
    }

    private func unitText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    // MARK: History section

    private var historySection: some View {
        Section(header: Text("HISTORY")) {
            // PLAIN binding, deliberately: switching scope swaps a data-dependent set of List rows
            // (day content alone is 0-7 rows) - see the note on `body`.
            Picker("", selection: $scope) {
                ForEach(Scope.allCases) { scope in
                    Text(scope.rawValue.localizedDisplay).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            .onChange(of: scope) { _ in settings.hapticFeedback() }
            .id("history")

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
            navButton(symbol: "chevron.backward", enabled: canGoBack) { move(-1) }

            Spacer()

            VStack(spacing: 2) {
                Text(periodTitle.localizedDigits)
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

            navButton(symbol: "chevron.forward", enabled: canGoForward) { move(1) }
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
            trackerNote(String(localized: "This day hasn't arrived yet."), symbol: "hourglass")
        } else if exempt {
            trackerNote(
                settings.canEditExemption(on: day)
                    ? String(localized: "Exempt day: prayers were not obligatory and don't count against your record.")
                    : String(localized: "Exempt day: the menses pause is on. End it below when the period is over."),
                symbol: "moon.zzz.fill"
            )
        } else {
            let slots = settings.trackableSlots(for: day)
            if slots.isEmpty {
                trackerNote(String(localized: "Prayer times aren't available for this day."), symbol: "location.slash")
            } else {
                ForEach(slots, id: \.nameTransliteration) { prayer in
                    dayRow(for: prayer, on: day)
                }

                daySummary(slots: slots, on: day)

                wholeDayRow(day: day)

                if settings.trackerSunnahEnabled {
                    TrackerSunnahDayBlock(day: day)
                }
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
    /// chosen chip again clears the mark. With congregation tracked, that choice has a line of its
    /// own under the three, always there, so the row is the same height whatever is chosen.
    private func dayRow(for prayer: Prayer, on day: Date) -> some View {
        let name = prayer.nameTransliteration
        let mark = settings.prayerMark(for: name, on: day)
        let accent = settings.accentColor.accent2
        let canMark = settings.canMarkPrayer(startingAt: prayer.time, on: day)

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

            if canMark {
                HStack(spacing: 6) {
                    ForEach(PrayerMark.allCases, id: \.self) { option in
                        TrackerMarkChip(mark: option, selected: mark == option) {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut(duration: 0.15)) {
                                settings.recordTrackerMark(mark == option ? nil : option, for: name, on: day)
                            }
                        }
                    }
                }
                .padding(.leading, 36)

                if settings.trackerCongregationEnabled {
                    TrackerCongregationChip(prayerName: name, day: day)
                        .padding(.leading, 36)
                }
            } else {
                // The chips are replaced rather than dimmed here: the Day view has the room to say why,
                // and a row of three greyed answers invites tapping at them.
                Text("Can be marked once \(prayer.displayName) begins.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 36)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(prayer.displayName): \(canMark ? (mark?.spokenTitle ?? String(localized: "not marked")) : String(localized: "not yet"))")
    }

    private func daySummary(slots: [Prayer], on day: Date) -> some View {
        let marks = slots.map { settings.prayerMark(for: $0.nameTransliteration, on: day) }
        let prayed = marks.filter { $0?.isPrayed == true }.count
        let late = marks.filter { $0 == .late }.count
        let missed = marks.filter { $0 == .missed }.count
        let complete = prayed == slots.count

        let text: String
        if complete {
            text = late == 0 ? String(localized: "All prayers prayed on time, a perfect day.") : String(localized: "All prayers prayed, \(late) late.")
        } else {
            var parts = [String(localized: "\(prayed) of \(slots.count) prayed")]
            if late > 0 { parts.append(String(localized: "\(late) late")) }
            if missed > 0 { parts.append(String(localized: "\(missed) missed")) }
            text = parts.joined(separator: JoinSeparator.dot)
        }

        return Text(text)
            .font(.caption)
            .foregroundColor(complete ? settings.accentColor.accent2 : .secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 2)
            .listRowSeparator(.hidden)
    }

    /// The whole day in one visit: a past day that was simply never filled in takes one menu, not
    /// five answers. A fill never overwrites an answer already given (`Settings.setWholeDay`).
    private func wholeDayRow(day: Date) -> some View {
        Menu {
            TrackerWholeDayMenuItems(day: day)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.accent2)
                    .frame(width: 24)

                Text("Mark the Whole Day")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        /// A pause ended on this day (`Settings.isTrackerResumeDay`): only its answered prayers count.
        var resumed = false

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
                                     exempt: exempt, isFuture: day > today,
                                     resumed: snapshot.resumeDays.contains(key)))
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

        /// `since` is the first day with anything recorded ("tracking since"): the days before it
        /// are not days the user failed to pray, and counting them put a first week at 5 of 35.
        init(records: [DayRecord], since earliestKey: String?) {
            guard let earliestKey else { return }
            for record in records where !record.isFuture && record.key >= earliestKey {
                if record.exempt {
                    exempt += 1
                    continue
                }
                prayed += record.tally.prayed
                possible += record.resumed ? record.tally.prayed + record.tally.missed
                                           : Settings.canonicalObligatoryPrayers.count
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
                    weekRow(leading: trackerPrayerLabel(name, settings: settings), records: records) { record in
                        weekCell(prayerName: name, record: record)
                    }
                }
            }
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)
            // On the grid, the one view of the week: a tap on a prayer whose time has ended asks.
            .trackerAskDialog($asking)

            summaryLine(PeriodTotals(records: records, since: settings.trackerEarliestDayKey()))
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
    /// an outline while unmarked. Tap marks or clears (and asks once the prayer's time has ended);
    /// press and hold opens the chooser.
    @ViewBuilder
    private func weekCell(prayerName: String, record: DayRecord) -> some View {
        let mark = record.marks[prayerName]
        let tint = mark?.tint ?? .clear
        let dateLabel = Self.shortDateFormatter.string(from: record.date)
        let hasBegun = hasPrayerBegun(prayerName, on: record.date)

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

        if record.counts && hasBegun {
            GridTileMenu {
                settings.hapticFeedback()
                withAnimation(.easeInOut(duration: 0.15)) {
                    settings.tapTrackerSlot(prayerName, displayName: trackerPrayerLabel(prayerName, settings: settings),
                                            on: record.date) { asking = $0 }
                }
            } menu: {
                TrackerMarkPicker(prayerName: prayerName, date: record.date)
            } label: {
                face
            }
            .accessibilityLabel("\(prayerName.localizedDisplay), \(dateLabel): \(mark?.spokenTitle ?? String(localized: "not marked"))")
            .accessibilityHint("Tap to mark prayed. Press and hold for late or missed.")
        } else {
            face
                .opacity(record.counts && !hasBegun ? 0.4 : 1)
                .accessibilityLabel("\(prayerName.localizedDisplay), \(dateLabel): \(record.exempt ? String(localized: "exempt") : String(localized: "not yet"))")
        }
    }

    /// Whether `prayerName`'s time has come on `date`, for the week grid - which, unlike every other
    /// marking surface, holds only a name and a `DayRecord` and so has to look the time up.
    ///
    /// Cheap in the common case: any day but today answers without a lookup. Only today's row
    /// consults the slots, and those come from the already-decoded `prayers`.
    private func hasPrayerBegun(_ prayerName: String, on date: Date) -> Bool {
        guard calendar.isDateInToday(date) else { return true }
        // By coverage: on a Friday the Dhuhr row's slot is "Jumuah", and while traveling it is
        // "Dhuhr/Asr". Matched by name, neither was found and the row could be marked before its time.
        guard let slot = settings.trackableSlots(for: date)
            .first(where: {
                $0.nameTransliteration == prayerName
                    || Settings.canonicalCoverage(of: $0.nameTransliteration).contains(prayerName)
            })
        else { return true }
        return settings.canMarkPrayer(startingAt: slot.time, on: date)
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
            let weeks = monthWeeks(records: records, leadingBlanks: leadingBlanks(for: interval.start))
            let earliestKey = settings.trackerEarliestDayKey()

            // Rows of seven, laid out by hand: a lazy grid inside a List row buys nothing for at most
            // 42 cells, and its diffing was the one moving part in the crash reports the owner could
            // not reproduce. A plain stack of rows has no diff to get wrong.
            VStack(spacing: 8) {
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
                                    monthCell(record: record, dayNumber: slot.dayNumber,
                                              tracked: earliestKey.map { record.key >= $0 } ?? false)
                                } else {
                                    Color.clear.frame(height: Self.monthRingSize)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                markLegend
            }
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)

            summaryLine(PeriodTotals(records: records, since: earliestKey))
        }
    }

    private func leadingBlanks(for monthStart: Date) -> Int {
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        return max((firstWeekday - calendar.firstWeekday + 7) % 7, 0)
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

    private static let monthRingSize: CGFloat = 36

    /// One day of the month: its day ring with the date inside. The heat cells this replaces said how
    /// many of the five were prayed and carried one dot; the ring says which, and how. A tap opens
    /// the day; press and hold fills it, clears it, or marks it exempt without leaving the month.
    private func monthCell(record: DayRecord, dayNumber: Int, tracked: Bool) -> some View {
        let day = record.date
        let isToday = calendar.isDateInToday(day)
        // A day still to come, and a day before tracking began, have nothing to say yet.
        let quiet = record.isFuture || !tracked
        let ringMarks = (quiet || record.exempt) ? PrayerDayRing.empty : PrayerDayRing.marks(from: record.marks)
        let track = Color.secondary.opacity(quiet ? 0.1 : (record.exempt ? 0.12 : 0.24))

        return GridTileMenu {
            guard !record.isFuture else { return }
            settings.hapticFeedback()
            // Plain writes: month → day swaps the section's row set structurally - see the note on
            // `body`.
            anchor = day
            scope = .day
        } menu: {
            monthDayMenu(record: record)
        } label: {
            ZStack {
                PrayerDayRing(marks: ringMarks, lineWidth: 3.5, track: track)

                if record.exempt {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.75))
                } else {
                    Text("\(dayNumber)".localizedDigits)
                        .font(.system(size: 12, weight: isToday ? .bold : .regular).monospacedDigit())
                        .foregroundColor(isToday ? settings.accentColor.accent2 : (quiet ? .secondary.opacity(0.55) : .primary))
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(width: Self.monthRingSize, height: Self.monthRingSize)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .disabled(record.isFuture)
        .accessibilityLabel(monthCellAccessibilityLabel(record: record, day: day))
    }

    @ViewBuilder
    private func monthDayMenu(record: DayRecord) -> some View {
        let day = record.date

        Button {
            settings.hapticFeedback()
            anchor = day
            scope = .day
        } label: {
            Label("Open Day", systemImage: "calendar")
        }

        if !record.exempt {
            TrackerWholeDayMenuItems(day: day)
        }

        if settings.canEditExemption(on: day) {
            Section {
                // `.automatic`, or the app's padded switch style draws a double-height menu row.
                Toggle(isOn: Binding(
                    get: { settings.isTrackerExempt(on: day) },
                    set: { newValue in
                        settings.hapticFeedback()
                        settings.setTrackerExempt(newValue, on: day)
                    }
                )) {
                    Label("Exempt Day", systemImage: "moon.zzz")
                }
                .toggleStyle(.automatic)
            }
        }
    }

    private func monthCellAccessibilityLabel(record: DayRecord, day: Date) -> String {
        let date = Self.longDateFormatter.string(from: day)
        if record.exempt { return String(localized: "\(date): exempt") }
        let total = Settings.canonicalObligatoryPrayers.count
        var parts = [String(localized: "\(record.tally.prayed) of \(total) prayed")]
        if record.tally.late > 0 { parts.append(String(localized: "\(record.tally.late) late")) }
        if record.tally.missed > 0 { parts.append(String(localized: "\(record.tally.missed) missed")) }
        return "\(date): \(parts.joined(separator: ", "))"
    }

    /// What the ring's colours mean, under the month.
    private var markLegend: some View {
        HStack(spacing: 12) {
            ForEach(PrayerMark.allCases, id: \.self) { mark in
                HStack(spacing: 4) {
                    Circle()
                        .fill(mark.tint)
                        .frame(width: 7, height: 7)
                    Text(mark.shortTitle)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 8))
                Text("exempt")
            }

            Spacer(minLength: 0)
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .padding(.top, 2)
        .accessibilityHidden(true)
    }

    // MARK: Year view

    /// The year as twelve small months, three across: every day a square, green by how much of it
    /// was on time and red where a prayer was missed (`yearCellColor`). Twelve bars said how much
    /// of each month; this shows where in it.
    @ViewBuilder
    private var yearContent: some View {
        let year = calendar.component(.year, from: anchor)
        let earliestKey = settings.trackerEarliestDayKey()
        let months = yearMonthSummaries(year: year, earliestKey: earliestKey)

        VStack(spacing: 14) {
            // Rows of three, by position: a month's place in the year is its identity.
            ForEach(0..<4, id: \.self) { row in
                HStack(alignment: .top, spacing: 14) {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        if months.indices.contains(index) {
                            miniMonth(months[index], year: year, earliestKey: earliestKey)
                        }
                    }
                }
            }

            yearLegend
        }
        .padding(.vertical, 6)
        .listRowSeparator(.hidden)

        summaryLine(months.reduce(PeriodTotals()) { $0 + $1.totals })
    }

    private struct MonthSummary {
        let month: Int
        let totals: PeriodTotals
        /// The month's days in rows of seven, padded (`monthWeeks`), and to six rows so every
        /// month of the year stands the same height.
        let weeks: [[MonthSlot]]
    }

    private func yearMonthSummaries(year: Int, earliestKey: String?) -> [MonthSummary] {
        (1...12).compactMap { month in
            guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return nil }
            let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
            let records = dayRecords(from: start, count: dayCount)
            var weeks = monthWeeks(records: records, leadingBlanks: leadingBlanks(for: start))
            while weeks.count < 6 {
                let base = weeks.count * 7
                weeks.append((0..<7).map { MonthSlot(id: base + $0, record: nil, dayNumber: 0) })
            }
            return MonthSummary(month: month, totals: PeriodTotals(records: records, since: earliestKey), weeks: weeks)
        }
    }

    private func miniMonth(_ summary: MonthSummary, year: Int, earliestKey: String?) -> some View {
        let totals = summary.totals
        let fraction = totals.possible > 0 ? Double(totals.prayed) / Double(totals.possible) : 0
        let hasData = totals.possible > 0 || totals.exempt > 0
        let percent = totals.possible > 0 ? trackerPercentText(Int((fraction * 100).rounded())) : ""

        return Button {
            settings.hapticFeedback()
            // Plain writes: year → month swaps the section's rows structurally - see the note on
            // `body`.
            if let date = calendar.date(from: DateComponents(year: year, month: summary.month, day: 1)) {
                anchor = date
                scope = .month
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 2) {
                    Text(Self.monthSymbol(at: summary.month - 1))
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(hasData ? .primary : .secondary.opacity(0.6))

                    Spacer(minLength: 0)

                    Text(percent.localizedDigits)
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundColor(settings.accentColor.accent2)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)

                VStack(spacing: 2) {
                    ForEach(Array(summary.weeks.enumerated()), id: \.offset) { _, week in
                        HStack(spacing: 2) {
                            ForEach(week) { slot in
                                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                    .fill(yearCellColor(slot.record, earliestKey: earliestKey))
                                    .aspectRatio(1, contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Self.monthSymbol(at: summary.month - 1) + (percent.isEmpty ? "" : ": \(percent)"))
        .accessibilityHint("Opens this month.")
    }

    /// A day as one square. Green, deeper the more of the five were prayed on time (a late prayer
    /// counts half), so a month of mostly-on-time days reads as the green it was; a day with a
    /// missed prayer is red, the one thing the year should let the eye find. The first version
    /// painted a whole day orange for one late prayer, and a 90% month looked like a bad one.
    private func yearCellColor(_ record: DayRecord?, earliestKey: String?) -> Color {
        guard let record else { return .clear }
        let tracked = earliestKey.map { record.key >= $0 } ?? false
        if record.isFuture || !tracked { return Color.secondary.opacity(0.08) }
        if record.exempt { return Color.secondary.opacity(0.2) }
        if record.tally.missed > 0 {
            return PrayerMark.missed.tint.opacity(0.55 + 0.15 * Double(min(record.tally.missed, 3)))
        }
        return Self.yearGreen(Double(record.tally.onTime) + 0.5 * Double(record.tally.late))
    }

    /// The year's green for a day worth `score` of five (nothing answered is the neutral gray).
    private static func yearGreen(_ score: Double) -> Color {
        guard score > 0 else { return Color.secondary.opacity(0.18) }
        let total = Double(Settings.canonicalObligatoryPrayers.count)
        return PrayerMark.onTime.tint.opacity(0.2 + 0.8 * min(score / total, 1))
    }

    /// The year's own key: its squares say how much of a day was on time, not which prayer.
    private var yearLegend: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Self.yearGreen(Double(step)))
                            .frame(width: 9, height: 9)
                    }
                }
                Text(PrayerMark.onTime.shortTitle)
            }

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(PrayerMark.missed.tint)
                    .frame(width: 9, height: 9)
                Text(PrayerMark.missed.shortTitle)
            }

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 9, height: 9)
                Text("exempt")
            }

            Spacer(minLength: 0)
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .padding(.top, 2)
        .accessibilityHidden(true)
    }

    // MARK: Menses pause

    private var mensesSection: some View {
        Section(
            header: Text("MENSTRUATION & POSTPARTUM"),
            footer: Text("During menstruation or postpartum bleeding, the five daily prayers are not obligatory and are not made up afterward; this is Allah's mercy, not a shortfall. While paused, days are marked exempt: they never break a streak or count in any statistic, and \"Did you pray?\" reminders stay silent. Prayer time notifications continue as usual. Past days can be corrected with the exempt toggle in the Day view.")
        ) {
            Toggle(isOn: Binding(
                get: { settings.mensesPauseActive },
                set: { newValue in
                    settings.hapticFeedback()
                    // Plain write: the pause swaps today's rows in the Day view (and the Adhan tab's
                    // card), and that structural change must not animate - see the note on `body`.
                    settings.setMensesPause(newValue)
                    pauseFlips += 1
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
            .id("pause")
        }
        .themedListRowBackground()
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

        // Glyph and text by hand, not `Label`: in a List row a Label takes the row's own label style,
        // which gives the glyph a title-sized column and left "86/..." of the text.
        let prayed = summaryItem("checkmark.circle", String(localized: "\(totals.prayed)/\(totals.possible) prayed"))
        let share = summaryItem("percent", trackerPercentText(percent))
        let perfect = summaryItem("star", String(localized: "\(totals.perfect) perfect"))
        let late = summaryItem("clock", String(localized: "\(totals.late) late"), tint: PrayerMark.late.tint)
        let missed = summaryItem("xmark.circle", String(localized: "\(totals.missed) missed"), tint: PrayerMark.missed.tint)

        // One row where it fits, two where it does not (the large text sizes, a narrow column): the
        // single row scaled down and then cut every item to "86...".
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                prayed
                share
                perfect
                if totals.late > 0 { late }
                if totals.missed > 0 { missed }
            }
            .fixedSize()

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    prayed
                    share
                }
                HStack(spacing: 10) {
                    perfect
                    if totals.late > 0 { late }
                    if totals.missed > 0 { missed }
                }
            }
            .minimumScaleFactor(0.7)
        }
        .font(.caption2.monospacedDigit())
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .listRowSeparator(.hidden)
    }

    private func summaryItem(_ symbol: String, _ text: String, tint: Color = .secondary) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
            Text(text.localizedDigits)
        }
        .foregroundColor(tint)
    }

    /// Every display formatter and symbol table below is pinned to the same localized GREGORIAN
    /// calendar the grid math uses (see `calendar`): month titles, dates, and weekday letters must
    /// name the months the grid is actually drawing, in the user's language.
    private static let displayCalendar: Calendar = {
        var pinned = Calendar(identifier: .gregorian)
        pinned.locale = Locale.current
        pinned.firstWeekday = Calendar.current.firstWeekday
        pinned.timeZone = .autoupdatingCurrent
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
