#if os(iOS)
import SwiftUI

// The Quran Planner: set a finish goal ("finish in 2 months") and get a daily ayah amount that
// recomputes every day from what is ACTUALLY left - miss a day and tomorrow's amount grows to absorb
// it, read ahead and it shrinks. Progress is the khatm store itself: ayahs auto-mark as you read in
// the app (or can be marked in bulk here for reading done outside the app), so the plan advances
// without any separate check-in.

// MARK: - Model

struct QuranPlan: Codable, Equatable {
    /// The day the plan began (start-of-day; drives pace/average stats).
    var startDate: Date
    /// Date-goal mode: the day the khatm should be finished, inclusive. nil = fixed-pace mode.
    var endDate: Date?
    /// Fixed-pace mode: ayahs per day. nil = date-goal mode.
    var ayahsPerDay: Int?
    /// Which day `dayStartCompleted` belongs to ("yyyy-MM-dd"). Together they make "read today" a pure
    /// subtraction from the khatm total - no per-mark bookkeeping anywhere else.
    var dayKey: String
    /// The khatm total when `dayKey` began.
    var dayStartCompleted: Int
    /// The khatm total when the plan began.
    var startCompleted: Int
    var completedDate: Date?
    /// Ayahs read per past day ("yyyy-MM-dd" → count), recorded when the day rolls over and pruned to
    /// the most recent 30. Optional so plans saved before the field existed still decode.
    var history: [String: Int]?

    static func dayKey(for date: Date) -> String {
        Self.dayKeyFormatter.string(from: date)
    }

    static func dayKey(daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return dayKey(for: date)
    }

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Persistence (khatm-style: one @AppStorage Data blob + memoized Codable value)

extension Settings {
    private static var quranPlanCache: (data: Data, value: QuranPlan?)?

    var quranPlan: QuranPlan? {
        get {
            if let cached = Self.quranPlanCache, cached.data == quranPlanData { return cached.value }
            let decoded = try? Self.decoder.decode(QuranPlan.self, from: quranPlanData)
            Self.quranPlanCache = (quranPlanData, decoded)
            return decoded
        }
        set {
            let encoded = newValue.flatMap { try? Self.encoder.encode($0) } ?? Data()
            Self.quranPlanCache = (encoded, newValue)
            quranPlanData = encoded
        }
    }

    /// Rolls the plan's "today" forward when a new day has begun, so "read today" restarts at zero.
    /// Also stamps completion (once) when the khatm total reaches the full Quran. Safe to call from
    /// onAppear/onReceive as often as needed - it only writes when something actually changed.
    @MainActor
    func settleQuranPlan(totalCompleted: Int, totalAyahs: Int) {
        guard var plan = quranPlan else { return }
        var changed = false

        let todayKey = QuranPlan.dayKey(for: Date())
        if plan.dayKey != todayKey {
            // Bank the outgoing day into history before rolling. (Reading done after midnight but before
            // this settle runs lands on the old day - the tab's onAppear and the midnight notification
            // both call settle, so in practice the skew is at most one uninterrupted overnight session.)
            var history = plan.history ?? [:]
            history[plan.dayKey] = max(0, totalCompleted - plan.dayStartCompleted)
            if history.count > 30 {
                for key in history.keys.sorted().dropLast(30) { history[key] = nil }
            }
            plan.history = history

            plan.dayKey = todayKey
            plan.dayStartCompleted = totalCompleted
            changed = true
        }

        if totalAyahs > 0, totalCompleted >= totalAyahs {
            if plan.completedDate == nil {
                plan.completedDate = Date()
                changed = true
                // A finished khatm is the single best moment this app will ever have to ask for a
                // rating. Every gate (cooldown, quota, engagement) re-checks inside the manager.
                AppReviewManager.shared.requestAtMomentOfDelight()
            }
        } else if plan.completedDate != nil {
            // Khatm progress was reset (or marks removed) mid-plan - un-complete so the plan resumes.
            plan.completedDate = nil
            changed = true
        }

        if changed { quranPlan = plan }
    }
}

// MARK: - Plan math

enum QuranPlannerMath {
    private static var totalAyahsCache: (surahCount: Int, total: Int)?

    /// Total ayah count of the loaded quran, memoized on the surah count (114 once loaded, 0 before).
    static func totalAyahs(quran: [Surah]) -> Int {
        if let cached = totalAyahsCache, cached.surahCount == quran.count { return cached.total }
        let total = quran.reduce(0) { $0 + $1.ayahs.count }
        totalAyahsCache = (quran.count, total)
        return total
    }

    /// Consecutive days with any reading, counting back from today (or yesterday, so an unread morning
    /// doesn't zero an unbroken run).
    static func streak(plan: QuranPlan, doneToday: Int) -> Int {
        let history = plan.history ?? [:]
        var streak = doneToday > 0 ? 1 : 0
        var daysAgo = 1
        while daysAgo <= 30, (history[QuranPlan.dayKey(daysAgo: daysAgo)] ?? 0) > 0 {
            streak += 1
            daysAgo += 1
        }
        return streak
    }

    /// The last 7 days' read counts, oldest first, today (live) last.
    static func lastSevenDays(plan: QuranPlan, doneToday: Int) -> [(label: String, count: Int, isToday: Bool)] {
        let history = plan.history ?? [:]
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols

        return (0...6).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let label = symbols[calendar.component(.weekday, from: date) - 1]
            let count = daysAgo == 0 ? doneToday : (history[QuranPlan.dayKey(for: date)] ?? 0)
            return (label, count, daysAgo == 0)
        }
    }

    /// Days from today through `end`, inclusive, never below 1 - the denominator that redistributes
    /// missed days across whatever time is left.
    static func daysLeft(until end: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDay = calendar.startOfDay(for: end)
        let days = calendar.dateComponents([.day], from: today, to: endDay).day ?? 0
        return max(1, days + 1)
    }

    static func daysElapsed(since start: Date) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let today = calendar.startOfDay(for: Date())
        return max(0, calendar.dateComponents([.day], from: startDay, to: today).day ?? 0)
    }

    /// Today's quota, computed from what was left when today began. Date mode: remaining / days left,
    /// rounded up. Fixed mode: the chosen amount, clamped to what's left.
    static func todayTarget(plan: QuranPlan, totalAyahs: Int, dayStartCompleted: Int) -> Int {
        let remaining = max(0, totalAyahs - dayStartCompleted)
        guard remaining > 0 else { return 0 }

        if let perDay = plan.ayahsPerDay {
            return min(perDay, remaining)
        }
        guard let end = plan.endDate else { return remaining }
        return Int((Double(remaining) / Double(daysLeft(until: end))).rounded(.up))
    }

    /// Date mode only: how far ahead (+) or behind (-) the original straight-line schedule the reader
    /// is right now. Purely informational - the daily target above already self-corrects.
    static func paceDelta(plan: QuranPlan, totalAyahs: Int, totalCompleted: Int) -> Int? {
        guard let end = plan.endDate else { return nil }
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: plan.startDate)
        let endDay = calendar.startOfDay(for: end)
        let totalDays = max(1, (calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0) + 1)
        let elapsed = min(daysElapsed(since: plan.startDate), totalDays)

        let span = max(0, totalAyahs - plan.startCompleted)
        let expected = plan.startCompleted + Int((Double(span) * Double(elapsed) / Double(totalDays)).rounded())
        return totalCompleted - expected
    }

    /// Fixed-pace mode: the day the khatm lands if the pace holds.
    static func projectedFinish(plan: QuranPlan, remaining: Int) -> Date? {
        guard let perDay = plan.ayahsPerDay, perDay > 0, remaining > 0 else { return nil }
        let days = Int((Double(remaining) / Double(perDay)).rounded(.up))
        return Calendar.current.date(byAdding: .day, value: max(0, days - 1), to: Calendar.current.startOfDay(for: Date()))
    }

    // MARK: Today's reading span

    struct TodaySpan {
        let startSurahID: Int
        let startSurahName: String
        let startAyah: Int
        let startPage: Int?
        let endSurahName: String
        let endAyah: Int
        let endPage: Int?
    }

    private static var spanCache: (khatmCount: Int, count: Int, span: TodaySpan?)?

    /// The next `count` unread ayahs in mushaf order, starting at the first gap in khatm progress.
    /// Memoized on (khatm total, count): the walk is ~6k set lookups and QuranView re-renders often.
    static func todaySpan(quran: [Surah], settings: Settings, count: Int) -> TodaySpan? {
        let khatmCount = settings.khatmCompletedAyahSetCache.count
        if let cached = spanCache, cached.khatmCount == khatmCount, cached.count == count {
            return cached.span
        }

        var remaining = max(1, count)
        var start: (surah: Surah, ayah: Ayah)?
        var last: (surah: Surah, ayah: Ayah)?

        outer: for surah in quran {
            for ayah in surah.ayahs {
                guard !settings.isKhatmAyahComplete(surah: surah.id, ayah: ayah.id) else { continue }
                if start == nil { start = (surah, ayah) }
                last = (surah, ayah)
                remaining -= 1
                if remaining <= 0 { break outer }
            }
        }

        var span: TodaySpan?
        if let start, let last {
            span = TodaySpan(
                startSurahID: start.surah.id,
                startSurahName: start.surah.nameTransliteration,
                startAyah: start.ayah.id,
                startPage: start.ayah.page,
                endSurahName: last.surah.nameTransliteration,
                endAyah: last.ayah.id,
                endPage: last.ayah.page
            )
        }
        spanCache = (khatmCount, count, span)
        return span
    }

    /// Marks the next `count` unread ayahs complete - for reading done outside the app (a physical
    /// mushaf, another app). Rides the khatm store's debounced save.
    static func markNextUnreadAyahs(quran: [Surah], settings: Settings, count: Int) {
        var remaining = count
        outer: for surah in quran {
            for ayah in surah.ayahs {
                guard !settings.isKhatmAyahComplete(surah: surah.id, ayah: ayah.id) else { continue }
                // The last mark is `immediate` so the UI snaps to the new state now; the earlier ones
                // ride the debounced save (one disk write for the whole batch).
                settings.markKhatmAyahComplete(surah: surah.id, ayah: ayah.id, immediate: remaining == 1)
                remaining -= 1
                if remaining <= 0 { break outer }
            }
        }
        spanCache = nil
    }
}

// MARK: - Toolbar entry point

/// The planner in the Quran tab's leading toolbar - always one tap away, even when the card is
/// scrolled off-screen. Owns its own sheet so QuranView needs no extra state.
struct QuranPlannerToolbarButton: View {
    @ObservedObject private var settings = Settings.shared

    let openReader: (Int, Int) -> Void

    @State private var showingPlanner = false
    @State private var pendingRead: QuranPlannerSection.PendingRead?

    var body: some View {
        Button {
            settings.hapticFeedback()
            showingPlanner = true
        } label: {
            Image(systemName: "calendar.badge.clock")
        }
        .accessibilityLabel("Quran Planner")
        .tint(settings.accentColor.accent1)
        .sheet(isPresented: $showingPlanner, onDismiss: {
            guard let pending = pendingRead else { return }
            pendingRead = nil
            openReader(pending.surah, pending.ayah)
        }) {
            QuranPlannerView(pendingRead: $pendingRead)
        }
    }
}

// MARK: - QuranView section

/// The planner's card on the Quran tab. Standalone struct on purpose - a new QuranView section must
/// never be an inline closure of an already-deep view tree (see `boxed` in QuranView).
struct QuranPlannerSection: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    /// Pushes the reader at (surah, ayah) - wired to QuranView's `push`.
    let openReader: (Int, Int) -> Void

    @State private var showingPlanner = false
    @State private var pendingRead: PendingRead?

    struct PendingRead: Equatable {
        let surah: Int
        let ayah: Int
    }

    private var totalAyahs: Int {
        QuranPlannerMath.totalAyahs(quran: quranData.quran)
    }

    private var totalCompleted: Int {
        settings.khatmCompletedAyahSetCache.count
    }

    var body: some View {
        // Khatm marking is Hafs-only; without it the planner has no progress source. Stay out of the
        // way entirely (the khatm section already explains the riwayah limitation).
        if settings.isHafsDisplay, totalAyahs > 0 {
            Section(header: sectionHeader) {
                if let plan = settings.quranPlan {
                    activeCard(plan: plan)
                } else {
                    setupRow
                }
            }
            .onAppear {
                settings.settleQuranPlan(totalCompleted: totalCompleted, totalAyahs: totalAyahs)
            }
            // Midnight rollover while the app stays open: the system posts a significant-time-change at
            // day boundaries, so "today" resets without waiting for the next onAppear.
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                settings.settleQuranPlan(totalCompleted: totalCompleted, totalAyahs: totalAyahs)
            }
            // Completion stamping right when the final ayah is marked (settle no-ops otherwise). Async
            // hop: settle may write settings, which must not publish from inside a view update.
            .onReceive(settings.objectWillChange) { _ in
                DispatchQueue.main.async {
                    settings.settleQuranPlan(totalCompleted: totalCompleted, totalAyahs: totalAyahs)
                }
            }
            .sheet(isPresented: $showingPlanner, onDismiss: handleSheetDismiss) {
                QuranPlannerView(pendingRead: $pendingRead)
            }
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text("QURAN PLANNER")

            Spacer()

            if let plan = settings.quranPlan {
                let todayKey = QuranPlan.dayKey(for: Date())
                let dayStart = plan.dayKey == todayKey ? min(plan.dayStartCompleted, totalCompleted) : totalCompleted
                let streak = QuranPlannerMath.streak(plan: plan, doneToday: max(0, totalCompleted - dayStart))
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
    }

    private func handleSheetDismiss() {
        guard let pending = pendingRead else { return }
        pendingRead = nil
        openReader(pending.surah, pending.ayah)
    }

    private var setupRow: some View {
        Button {
            settings.hapticFeedback()
            showingPlanner = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Set a Reading Goal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text("Finish the Quran by a date - get a daily amount that adjusts if you miss a day.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func activeCard(plan: QuranPlan) -> some View {
        let todayKey = QuranPlan.dayKey(for: Date())
        // Stale dayKey (first render after midnight, before settle lands): treat the day as fresh.
        let dayStart = plan.dayKey == todayKey ? min(plan.dayStartCompleted, totalCompleted) : totalCompleted
        let target = QuranPlannerMath.todayTarget(plan: plan, totalAyahs: totalAyahs, dayStartCompleted: dayStart)
        let doneToday = max(0, totalCompleted - dayStart)
        let finished = plan.completedDate != nil || totalCompleted >= totalAyahs
        // One walk serves both the card label and the Continue button (same frontier) - two different
        // `count` values would thrash the single-entry span memo on every render.
        let span = finished ? nil : QuranPlannerMath.todaySpan(quran: quranData.quran, settings: settings, count: max(1, target - doneToday))

        Button {
            settings.hapticFeedback()
            showingPlanner = true
        } label: {
            HStack(spacing: 14) {
                PlannerRing(
                    progress: finished ? 1 : (target > 0 ? min(1, Double(doneToday) / Double(target)) : 1),
                    accent: settings.accentColor.color
                )
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    if finished {
                        Text("Khatm complete")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)

                        Text("Alhamdulillah - may Allah accept it.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if doneToday >= target {
                        Text("Done for today")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)

                        Text("\(doneToday) ayah\(doneToday == 1 ? "" : "s") read - keep going or rest.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Today: \(doneToday) of \(target) ayahs")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundColor(.primary)

                        if let span {
                            Text(spanLabel(span))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if !finished, doneToday < target, let span {
            Button {
                settings.hapticFeedback()
                openReader(span.startSurahID, span.startAyah)
            } label: {
                Label("Continue Reading", systemImage: "book.fill")
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.accent2)
            }
        }
    }

    private func spanLabel(_ span: QuranPlannerMath.TodaySpan) -> String {
        var label = "\(span.startSurahName) \(span.startAyah) to \(span.endSurahName) \(span.endAyah)"
        if let startPage = span.startPage, let endPage = span.endPage {
            label += startPage == endPage ? " - page \(startPage)" : " - pages \(startPage)-\(endPage)"
        }
        return label
    }
}

/// Small determinate ring, checkmark at full.
struct PlannerRing: View {
    let progress: Double
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.18), lineWidth: 5)

            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if progress >= 1 {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(accent)
            } else {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundColor(accent)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: progress)
    }
}

// MARK: - Full planner sheet

struct QuranPlannerView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @Environment(\.presentationMode) private var presentationMode

    /// Set (instead of navigating directly) so the reader push happens AFTER the sheet dismisses.
    @Binding var pendingRead: QuranPlannerSection.PendingRead?

    @State private var editingGoal = false

    // Setup state
    @State private var goalMode: GoalMode = .byDate
    @State private var targetDate = Calendar.current.date(byAdding: .day, value: 59, to: Date()) ?? Date()
    @State private var ayahsPerDay = 104

    @State private var showingEndPlanConfirmation = false
    @State private var showingRestartConfirmation = false

    private enum GoalMode: String, CaseIterable, Identifiable {
        case byDate = "Finish by Date"
        case fixedPace = "Daily Amount"
        var id: String { rawValue }
    }

    private var totalAyahs: Int {
        QuranPlannerMath.totalAyahs(quran: quranData.quran)
    }

    private var totalCompleted: Int {
        settings.khatmCompletedAyahSetCache.count
    }

    /// Rough mushaf-page equivalent for an ayah count (604 pages / 6236 ayahs).
    private func pagesEquivalent(_ ayahs: Int) -> Int {
        guard totalAyahs > 0 else { return 0 }
        let totalPages = quranData.surah(114)?.pageEnd ?? 604
        return max(1, Int((Double(ayahs) * Double(totalPages) / Double(totalAyahs)).rounded()))
    }

    var body: some View {
        NavigationView {
            List {
                if !settings.isHafsDisplay {
                    riwayahNotice
                } else if let plan = settings.quranPlan, !editingGoal {
                    if plan.completedDate != nil || totalCompleted >= totalAyahs {
                        completedSections(plan: plan)
                    } else {
                        dashboardSections(plan: plan)
                    }
                } else {
                    setupSections
                }
            }
            .applyConditionalListStyle()
            .navigationTitle("Quran Planner")
            .sheetDismissToolbar()
        }
        .onAppear {
            settings.settleQuranPlan(totalCompleted: totalCompleted, totalAyahs: totalAyahs)
            if let plan = settings.quranPlan {
                prefillSetup(from: plan)
            }
        }
    }

    private var riwayahNotice: some View {
        Section {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(settings.accentColor.color)

                Text("The planner tracks progress through khatm marking, which is only available on Hafs an Asim. Switch back to the default riwayah in Quran settings to use it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: Setup

    private func prefillSetup(from plan: QuranPlan) {
        if let perDay = plan.ayahsPerDay {
            goalMode = .fixedPace
            ayahsPerDay = perDay
        } else if let end = plan.endDate {
            goalMode = .byDate
            targetDate = end
        }
    }

    @ViewBuilder
    private var setupSections: some View {
        Section {
            Picker("Goal", selection: $goalMode.animation(.easeInOut)) {
                ForEach(GoalMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if goalMode == .byDate {
                HStack(spacing: 8) {
                    presetButton("1 Month", days: 30)
                    presetButton("2 Months", days: 60)
                    presetButton("3 Months", days: 90)
                }
                .padding(.vertical, 2)

                DatePicker(
                    "Finish by",
                    selection: $targetDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .font(.subheadline)

                let remaining = max(1, totalAyahs - totalCompleted)
                let perDay = Int((Double(remaining) / Double(QuranPlannerMath.daysLeft(until: targetDate))).rounded(.up))
                Text("About \(perDay) ayahs (~\(pagesEquivalent(perDay)) pages) a day to finish by \(Self.mediumDate.string(from: targetDate)).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Stepper(value: $ayahsPerDay, in: 5...600, step: 5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(ayahsPerDay) ayahs a day")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()

                        Text("about \(pagesEquivalent(ayahsPerDay)) pages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                let remaining = max(1, totalAyahs - totalCompleted)
                let days = Int((Double(remaining) / Double(max(1, ayahsPerDay))).rounded(.up))
                Text("Finishes in about \(days) day\(days == 1 ? "" : "s").")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text(editingGoal ? "ADJUST GOAL" : "SET A GOAL")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                if totalCompleted > 0 {
                    Text("Your existing khatm progress (\(totalCompleted) ayahs) counts toward the finish.")
                }
                Text("Ayahs are marked as read automatically while you read in the app. Miss a day and the daily amount adjusts so you still finish on time.")
            }
            .font(.caption)
        }

        Section {
            Button {
                settings.hapticFeedback()
                startPlan()
            } label: {
                Text(editingGoal ? "Save Goal" : "Start Plan")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .foregroundColor(settings.accentColor.color)

            if editingGoal {
                Button {
                    settings.hapticFeedback()
                    withAnimation { editingGoal = false }
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func presetButton(_ label: String, days: Int) -> some View {
        Button {
            settings.hapticFeedback()
            targetDate = Calendar.current.date(byAdding: .day, value: days - 1, to: Date()) ?? Date()
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(settings.accentColor.color)
    }

    private func startPlan() {
        let todayKey = QuranPlan.dayKey(for: Date())

        if editingGoal, var plan = settings.quranPlan {
            // Adjusting keeps history (start date, today's progress) and only changes the goal.
            plan.endDate = goalMode == .byDate ? targetDate : nil
            plan.ayahsPerDay = goalMode == .fixedPace ? ayahsPerDay : nil
            settings.quranPlan = plan
            withAnimation { editingGoal = false }
            return
        }

        settings.quranPlan = QuranPlan(
            startDate: Date(),
            endDate: goalMode == .byDate ? targetDate : nil,
            ayahsPerDay: goalMode == .fixedPace ? ayahsPerDay : nil,
            dayKey: todayKey,
            dayStartCompleted: totalCompleted,
            startCompleted: totalCompleted,
            completedDate: nil
        )
    }

    // MARK: Dashboard

    @ViewBuilder
    private func dashboardSections(plan: QuranPlan) -> some View {
        let todayKey = QuranPlan.dayKey(for: Date())
        let dayStart = plan.dayKey == todayKey ? min(plan.dayStartCompleted, totalCompleted) : totalCompleted
        let target = QuranPlannerMath.todayTarget(plan: plan, totalAyahs: totalAyahs, dayStartCompleted: dayStart)
        let doneToday = max(0, totalCompleted - dayStart)
        let leftToday = max(0, target - doneToday)
        let span = leftToday > 0 ? QuranPlannerMath.todaySpan(quran: quranData.quran, settings: settings, count: leftToday) : nil

        Section(header: Text("TODAY")) {
            HStack(spacing: 16) {
                PlannerRing(
                    progress: target > 0 ? min(1, Double(doneToday) / Double(target)) : 1,
                    accent: settings.accentColor.color
                )
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 3) {
                    Text(doneToday >= target ? "Done for today" : "\(doneToday) of \(target) ayahs")
                        .font(.headline)
                        .monospacedDigit()

                    if doneToday >= target {
                        Text("\(doneToday) read - anything more is a head start on tomorrow.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if let span {
                        Text(fullSpanLabel(span))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)

            weekStrip(plan: plan, doneToday: doneToday)

            if leftToday > 0, let span {
                Button {
                    settings.hapticFeedback()
                    pendingRead = .init(surah: span.startSurahID, ayah: span.startAyah)
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Label("Continue Reading", systemImage: "book.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }

                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        QuranPlannerMath.markNextUnreadAyahs(quran: quranData.quran, settings: settings, count: leftToday)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Mark Today as Read", systemImage: "checkmark.circle")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.accent2)

                        Text("For reading done outside the app - marks the next \(leftToday) ayah\(leftToday == 1 ? "" : "s").")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }

        Section(header: Text("PLAN")) {
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    let percent = totalAyahs > 0 ? Int((Double(totalCompleted) / Double(totalAyahs) * 100).rounded()) : 0
                    Text("\(percent)% of the Quran")
                        .font(.headline)
                        .foregroundStyle(settings.accentColor.color)

                    Spacer()

                    Text("\(totalCompleted)/\(totalAyahs) ayahs")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(totalCompleted), total: Double(max(totalAyahs, 1)))
                    .tint(settings.accentColor.color)
            }
            .padding(.vertical, 2)

            if let end = plan.endDate {
                if Calendar.current.startOfDay(for: end) < Calendar.current.startOfDay(for: Date()) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)

                        Text("Your finish date has passed. Adjust the goal to spread what's left over more days.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                }

                plannerStatRow("Finish by", value: Self.mediumDate.string(from: end))
                plannerStatRow("Days left", value: "\(QuranPlannerMath.daysLeft(until: end))")

                if let delta = QuranPlannerMath.paceDelta(plan: plan, totalAyahs: totalAyahs, totalCompleted: totalCompleted) {
                    if delta >= -5 && delta <= 5 {
                        plannerStatRow("Pace", value: "On track")
                    } else if delta > 0 {
                        plannerStatRow("Pace", value: "\(delta) ayahs ahead")
                    } else {
                        plannerStatRow("Pace", value: "\(-delta) ayahs behind - today's amount absorbs it")
                    }
                }
            } else if let perDay = plan.ayahsPerDay {
                plannerStatRow("Daily amount", value: "\(perDay) ayahs (~\(pagesEquivalent(perDay)) pages)")

                if let projected = QuranPlannerMath.projectedFinish(plan: plan, remaining: max(0, totalAyahs - totalCompleted)) {
                    plannerStatRow("Projected finish", value: Self.mediumDate.string(from: projected))
                }
            }

            let elapsed = QuranPlannerMath.daysElapsed(since: plan.startDate) + 1
            let readSinceStart = max(0, totalCompleted - plan.startCompleted)
            plannerStatRow("Since \(Self.mediumDate.string(from: plan.startDate))", value: "\(readSinceStart) ayahs in \(elapsed) day\(elapsed == 1 ? "" : "s")")

            let streak = QuranPlannerMath.streak(plan: plan, doneToday: doneToday)
            if streak > 1 {
                plannerStatRow("Reading streak", value: "\(streak) days")
            }
        }

        manageSection
    }

    private var manageSection: some View {
        Section {
            Button {
                settings.hapticFeedback()
                if let plan = settings.quranPlan { prefillSetup(from: plan) }
                withAnimation { editingGoal = true }
            } label: {
                Label("Adjust Goal", systemImage: "slider.horizontal.3")
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
            }

            Button(role: .destructive) {
                settings.hapticFeedback()
                showingEndPlanConfirmation = true
            } label: {
                Label("End Plan", systemImage: "xmark.circle")
                    .font(.subheadline)
            }
            .confirmationDialog(
                "End this plan?",
                isPresented: $showingEndPlanConfirmation,
                titleVisibility: .visible
            ) {
                Button("End Plan", role: .destructive) {
                    withAnimation { settings.quranPlan = nil }
                }
            } message: {
                Text("Your khatm progress is kept - only the goal and daily amounts are removed.")
            }
        } footer: {
            Text("Progress comes from khatm marking: ayahs are marked as you read in the app, and you can review or reset them in Khatm mode on the Quran tab.")
                .font(.caption)
        }
    }

    /// The last 7 days as mini bars - a glanceable "did I keep up this week".
    private func weekStrip(plan: QuranPlan, doneToday: Int) -> some View {
        let days = QuranPlannerMath.lastSevenDays(plan: plan, doneToday: doneToday)
        let peak = max(1, days.map(\.count).max() ?? 1)

        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(day.count > 0 ? settings.accentColor.color.opacity(day.isToday ? 1 : 0.65) : Color.secondary.opacity(0.18))
                        .frame(height: day.count > 0 ? max(6, 28 * CGFloat(day.count) / CGFloat(peak)) : 4)
                        .frame(maxWidth: .infinity)

                    Text(day.label)
                        .font(.system(size: 9, weight: day.isToday ? .bold : .regular))
                        .foregroundColor(day.isToday ? settings.accentColor.color : .secondary)
                }
                .accessibilityLabel("\(day.label): \(day.count) ayahs")
            }
        }
        .frame(height: 44, alignment: .bottom)
        .padding(.vertical, 4)
    }

    private func plannerStatRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: Completed

    @ViewBuilder
    private func completedSections(plan: QuranPlan) -> some View {
        Section {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundColor(settings.accentColor.color)

                Text("Khatm Complete")
                    .font(.title3.weight(.semibold))

                let days = QuranPlannerMath.daysElapsed(since: plan.startDate) + 1
                Text("Alhamdulillah - you finished the Quran\(plan.startCompleted == 0 ? "" : " from where you began") over \(days) day\(days == 1 ? "" : "s"). May Allah accept it and make it a witness for you.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }

        Section {
            Button {
                settings.hapticFeedback()
                showingRestartConfirmation = true
            } label: {
                Label("Start a New Khatm", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
            }
            .confirmationDialog(
                "Start a new khatm?",
                isPresented: $showingRestartConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Progress and Start Again", role: .destructive) {
                    withAnimation {
                        settings.resetAllKhatmProgress()
                        settings.quranPlan = nil
                        editingGoal = false
                    }
                }
            } message: {
                Text("This resets khatm progress to zero so a fresh plan can begin.")
            }

            Button(role: .destructive) {
                settings.hapticFeedback()
                withAnimation { settings.quranPlan = nil }
            } label: {
                Label("End Plan", systemImage: "xmark.circle")
                    .font(.subheadline)
            }
        } footer: {
            Text("Ending the plan keeps your completed khatm progress.")
                .font(.caption)
        }
    }

    private func fullSpanLabel(_ span: QuranPlannerMath.TodaySpan) -> String {
        var label = "\(span.startSurahName) \(span.startAyah) to \(span.endSurahName) \(span.endAyah)"
        if let startPage = span.startPage, let endPage = span.endPage {
            label += startPage == endPage ? " (page \(startPage))" : " (pages \(startPage)-\(endPage))"
        }
        return label
    }

    private static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
#endif
