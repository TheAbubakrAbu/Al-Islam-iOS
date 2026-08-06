#if os(iOS)
import SwiftUI
import UserNotifications

// The Quran Planner: set a finish goal ("finish in 2 months") and get a daily ayah amount that
// recomputes every day from what is ACTUALLY left - miss a day and tomorrow's amount grows to absorb
// it, read ahead and it shrinks. Progress is the khatm store itself: ayahs auto-mark as you read in
// the app (or can be marked in bulk here for reading done outside the app), so the plan advances
// without any separate check-in. Lives behind the calendar button in the Quran tab's leading toolbar.

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

/// A "continue reading here" request captured while the planner sheet is up, honored after it
/// dismisses (pushing the reader mid-dismissal drops the navigation).
struct QuranPlannerPendingRead: Equatable {
    let surah: Int
    let ayah: Int
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
            // this settle runs lands on the old day - the toolbar button's onAppear and the midnight
            // notification both call settle, so the skew is at most one uninterrupted overnight session.)
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
                // The khatm is done - no more daily amounts to nag about.
                QuranPlannerReminder.cancel()
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
    /// Memoized on (khatm total, count): the walk is ~6k set lookups and callers render often.
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

    static func spanLabel(_ span: TodaySpan) -> String {
        var label = "\(span.startSurahName) \(span.startAyah) to \(span.endSurahName) \(span.endAyah)"
        if let startPage = span.startPage, let endPage = span.endPage {
            label += startPage == endPage ? " · page \(startPage)" : " · pages \(startPage)-\(endPage)"
        }
        return label
    }
}

// MARK: - Daily reminder

/// The planner's single repeating daily notification. One stable identifier means every schedule
/// call REPLACES the pending request (same id in `UNUserNotificationCenter.add`), so re-scheduling
/// on toggle/time/goal changes never stacks duplicates.
enum QuranPlannerReminder {
    static let identifier = "quran-planner-daily"
    /// 6:00 PM, stored as minutes past midnight (matches the @AppStorage key's Int encoding).
    static let defaultMinutes = 18 * 60

    /// Schedules (replacing any pending) the daily reminder at `minutes` past midnight. The body is
    /// frozen at schedule time: today's target when computable (quran loaded), else a generic line
    /// built from the plan's stored pace/finish date.
    static func schedule(plan: QuranPlan, minutes: Int, todayTarget: Int?, pagesEquivalent: Int?) {
        let content = UNMutableNotificationContent()
        content.title = "Quran Planner"
        content.body = body(plan: plan, todayTarget: todayTarget, pagesEquivalent: pagesEquivalent)
        content.sound = .default

        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        )
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static func body(plan: QuranPlan, todayTarget: Int?, pagesEquivalent: Int?) -> String {
        if let target = todayTarget, target > 0 {
            var line = "Time for today's Quran reading — \(target) ayahs"
            if let pages = pagesEquivalent { line += " (~\(pages) page\(pages == 1 ? "" : "s"))" }
            if let end = plan.endDate { line += " to finish by \(mediumDate.string(from: end))." } else { line += "." }
            return line
        }
        if let end = plan.endDate {
            return "Time for today's Quran reading — keep your pace to finish by \(mediumDate.string(from: end))."
        }
        if let perDay = plan.ayahsPerDay {
            return "Time for today's Quran reading — \(perDay) ayahs a day at your chosen pace."
        }
        return "Time for today's Quran reading."
    }

    private static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - Toolbar entry point

/// The planner's only entry point: the calendar button in the Quran tab's leading toolbar. Owns the
/// sheet and - since it is always mounted while the tab is up - the plan's day-rollover lifecycle.
struct QuranPlannerToolbarButton: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    let openReader: (Int, Int) -> Void

    @State private var showingPlanner = false
    @State private var pendingRead: QuranPlannerPendingRead?

    private var totalAyahs: Int {
        QuranPlannerMath.totalAyahs(quran: quranData.quran)
    }

    var body: some View {
        Button {
            settings.hapticFeedback()
            showingPlanner = true
        } label: {
            Image(systemName: "calendar.badge.clock")
        }
        .accessibilityLabel("Quran Planner")
        .tint(settings.accentColor.accent1)
        .onAppear {
            settings.settleQuranPlan(totalCompleted: settings.khatmCompletedAyahSetCache.count, totalAyahs: totalAyahs)
        }
        // Midnight rollover while the app stays open: the system posts a significant-time-change at
        // day boundaries, so "today" resets without waiting for the next onAppear.
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            settings.settleQuranPlan(totalCompleted: settings.khatmCompletedAyahSetCache.count, totalAyahs: totalAyahs)
        }
        // Completion stamping right when the final ayah is marked (settle no-ops otherwise). Async
        // hop: settle may write settings, which must not publish from inside a view update.
        .onReceive(settings.objectWillChange) { _ in
            DispatchQueue.main.async {
                settings.settleQuranPlan(totalCompleted: settings.khatmCompletedAyahSetCache.count, totalAyahs: totalAyahs)
            }
        }
        .sheet(isPresented: $showingPlanner, onDismiss: {
            guard let pending = pendingRead else { return }
            pendingRead = nil
            openReader(pending.surah, pending.ayah)
        }) {
            QuranPlannerView(pendingRead: $pendingRead)
                .smallMediumSheetPresentation()
        }
    }
}

// MARK: - Ring

/// Determinate progress ring with a two-tone gradient sweep; checkmark at full.
struct PlannerRing: View {
    let progress: Double
    let accent1: Color
    let accent2: Color
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent1.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.003, min(1, progress)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [accent1, accent2, accent1]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if progress >= 1 {
                Image(systemName: "checkmark")
                    .font(.headline.weight(.bold))
                    .foregroundColor(accent1)
            } else {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.footnote.weight(.bold).monospacedDigit())
                    .foregroundColor(accent1)
                    .minimumScaleFactor(0.6)
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
    @Binding var pendingRead: QuranPlannerPendingRead?

    @State private var editingGoal = false

    // Setup state
    @State private var goalMode: GoalMode = .byDate
    @State private var targetDate = Calendar.current.date(byAdding: .day, value: 59, to: Date()) ?? Date()
    @State private var ayahsPerDay = 104

    @State private var showingEndPlanConfirmation = false
    @State private var showingRestartConfirmation = false

    // Daily reminder (local to the planner - Settings is owned elsewhere, so plain @AppStorage keys)
    @AppStorage("quranPlannerReminderEnabled") private var reminderEnabled = false
    @AppStorage("quranPlannerReminderMinutes") private var reminderMinutes = QuranPlannerReminder.defaultMinutes
    @State private var showingReminderDeniedAlert = false

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

    private var accent: Color { settings.accentColor.color }
    private var accent2: Color { settings.accentColor.accent2 }

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
        .navigationViewStyle(.stack)
        .onAppear {
            settings.settleQuranPlan(totalCompleted: totalCompleted, totalAyahs: totalAyahs)
            if let plan = settings.quranPlan {
                prefillSetup(from: plan)
            }
            // The notification body is frozen at schedule time; refresh it each visit so "today's
            // target" tracks the plan's self-correcting amount (also cancels if the plan is gone).
            if reminderEnabled { rescheduleReminder() }
        }
    }

    private var riwayahNotice: some View {
        Section {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(accent)

                Text("The planner tracks progress through khatm marking, which is only available on Hafs an Asim. Switch back to the default riwayah in Quran settings to use it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)
        }
        .themedListRowBackground()
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
            VStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 30))
                    .foregroundColor(accent)
                    .frame(width: 64, height: 64)
                    .conditionalGlassEffect(circle: true)

                Text(editingGoal ? "Adjust Your Goal" : "Plan Your Khatm")
                    .font(.title3.weight(.semibold))

                Text("Pick a goal and get a daily reading amount that adjusts itself whenever you miss a day; you still finish on time.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowSeparator(.hidden)
        }
        .themedListRowBackground()

        Section {
            Picker("Goal", selection: $goalMode.animation(.easeInOut)) {
                ForEach(GoalMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)

            if goalMode == .byDate {
                HStack(spacing: 8) {
                    presetButton("1 Month", days: 30)
                    presetButton("2 Months", days: 60)
                    presetButton("3 Months", days: 90)
                }
                .padding(.vertical, 2)
                .listRowSeparator(.hidden)

                DatePicker(
                    "Finish by",
                    selection: $targetDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .font(.subheadline)
                .listRowSeparator(.hidden)

                let remaining = max(1, totalAyahs - totalCompleted)
                let perDay = Int((Double(remaining) / Double(QuranPlannerMath.daysLeft(until: targetDate))).rounded(.up))
                summaryLine("About \(perDay) ayahs (~\(pagesEquivalent(perDay)) pages) a day to finish by \(Self.mediumDate.string(from: targetDate)).")
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
                .listRowSeparator(.hidden)

                let remaining = max(1, totalAyahs - totalCompleted)
                let days = Int((Double(remaining) / Double(max(1, ayahsPerDay))).rounded(.up))
                summaryLine("Finishes in about \(days) day\(days == 1 ? "" : "s").")
            }
        } header: {
            Text("GOAL")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                if totalCompleted > 0 {
                    Text("Your existing khatm progress (\(totalCompleted) ayahs) counts toward the finish.")
                }
                Text("Ayahs are marked as read automatically while you read in the app.")
            }
            .font(.caption)
        }
        .themedListRowBackground()

        Section {
            Button {
                settings.hapticFeedback()
                startPlan()
            } label: {
                Text(editingGoal ? "Save Goal" : "Start Plan")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .conditionalGlassEffect(useColor: 0.25)
            .listRowSeparator(.hidden)

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
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
            }
        }
        .themedListRowBackground()
    }

    private func summaryLine(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundColor(accent2)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .listRowSeparator(.hidden)
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
        .tint(accent)
    }

    private func startPlan() {
        let todayKey = QuranPlan.dayKey(for: Date())

        if editingGoal, var plan = settings.quranPlan {
            // Adjusting keeps history (start date, today's progress) and only changes the goal.
            plan.endDate = goalMode == .byDate ? targetDate : nil
            plan.ayahsPerDay = goalMode == .fixedPace ? ayahsPerDay : nil
            settings.quranPlan = plan
            withAnimation { editingGoal = false }
            rescheduleReminder()
            return
        }

        withAnimation {
            settings.quranPlan = QuranPlan(
                startDate: Date(),
                endDate: goalMode == .byDate ? targetDate : nil,
                ayahsPerDay: goalMode == .fixedPace ? ayahsPerDay : nil,
                dayKey: todayKey,
                dayStartCompleted: totalCompleted,
                startCompleted: totalCompleted,
                completedDate: nil,
                history: [:]
            )
        }
        rescheduleReminder()
    }

    // MARK: Dashboard

    @ViewBuilder
    private func dashboardSections(plan: QuranPlan) -> some View {
        let todayKey = QuranPlan.dayKey(for: Date())
        // Stale dayKey (first render after midnight, before settle lands): treat the day as fresh.
        let dayStart = plan.dayKey == todayKey ? min(plan.dayStartCompleted, totalCompleted) : totalCompleted
        let target = QuranPlannerMath.todayTarget(plan: plan, totalAyahs: totalAyahs, dayStartCompleted: dayStart)
        let doneToday = max(0, totalCompleted - dayStart)
        let leftToday = max(0, target - doneToday)
        // One walk serves the label and both buttons (same frontier) - different `count` values would
        // thrash the single-entry span memo on every render.
        let span = leftToday > 0 ? QuranPlannerMath.todaySpan(quran: quranData.quran, settings: settings, count: leftToday) : nil

        Section(header: Text("TODAY")) {
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    PlannerRing(
                        progress: target > 0 ? min(1, Double(doneToday) / Double(target)) : 1,
                        accent1: accent,
                        accent2: accent2
                    )
                    .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 3) {
                        if doneToday >= target {
                            Text("Done for today")
                                .font(.title3.weight(.bold))

                            Text("\(doneToday) read; anything more is a head start on tomorrow.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            HStack(alignment: .firstTextBaseline, spacing: 5) {
                                Text("\(doneToday)")
                                    .font(.title.weight(.bold).monospacedDigit())
                                    .foregroundColor(accent)

                                Text("of \(target) ayahs")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }

                            if let span {
                                Text(QuranPlannerMath.spanLabel(span))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }

                weekStrip(plan: plan, doneToday: doneToday)
            }
            .padding(.vertical, 8)
            .listRowSeparator(.hidden)

            if leftToday > 0, let span {
                HStack(spacing: 10) {
                    actionTile(
                        title: "Continue Reading",
                        subtitle: "from \(span.startSurahName) \(span.startAyah)",
                        symbol: "book.fill"
                    ) {
                        pendingRead = QuranPlannerPendingRead(surah: span.startSurahID, ayah: span.startAyah)
                        presentationMode.wrappedValue.dismiss()
                    }

                    actionTile(
                        title: "Mark as Read",
                        subtitle: "read outside the app",
                        symbol: "checkmark.circle.fill"
                    ) {
                        withAnimation {
                            QuranPlannerMath.markNextUnreadAyahs(quran: quranData.quran, settings: settings, count: leftToday)
                        }
                    }
                }
                .padding(.vertical, 2)
                .listRowSeparator(.hidden)
            }
        }
        .themedListRowBackground()

        Section(header: Text("PLAN")) {
            if let end = plan.endDate, Calendar.current.startOfDay(for: end) < Calendar.current.startOfDay(for: Date()) {
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
                .listRowSeparator(.hidden)
            }

            statsGrid(plan: plan, doneToday: doneToday)
                .padding(.vertical, 6)
                .listRowSeparator(.hidden)

            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    let percent = totalAyahs > 0 ? Int((Double(totalCompleted) / Double(totalAyahs) * 100).rounded()) : 0
                    Text("\(percent)% of the Quran")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accent)

                    Spacer()

                    Text("\(totalCompleted)/\(totalAyahs)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(totalCompleted), total: Double(max(totalAyahs, 1)))
                    .tint(accent)

                let elapsed = QuranPlannerMath.daysElapsed(since: plan.startDate) + 1
                let readSinceStart = max(0, totalCompleted - plan.startCompleted)
                Text("\(readSinceStart) ayahs since \(Self.mediumDate.string(from: plan.startDate)) · \(elapsed) day\(elapsed == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
            }
            .padding(.vertical, 4)
            .listRowSeparator(.hidden)
        }
        .themedListRowBackground()

        reminderSection

        manageSection
    }

    // MARK: Daily reminder

    /// Toggle + time picker for the repeating daily reminder. Only rendered while a plan is active
    /// (this lives in `dashboardSections`), so there is never a reminder without a plan behind it.
    private var reminderSection: some View {
        Section {
            Toggle("Daily Reminder", isOn: reminderToggleBinding.animation(.easeInOut))
                .font(.subheadline)
                .listRowSeparator(.hidden)

            if reminderEnabled {
                DatePicker(
                    "Time",
                    selection: reminderTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .font(.subheadline)
                .listRowSeparator(.hidden)
            }
        } header: {
            Text("REMINDER")
        } footer: {
            Text("A daily notification at the chosen time with your reading amount. It re-schedules whenever the goal or time changes, and stops when the plan ends.")
                .font(.caption)
        }
        .themedListRowBackground()
        .alert("Notifications Off", isPresented: $showingReminderDeniedAlert) {
            Button("Open Settings") {
                settings.hapticFeedback()
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Notifications are turned off for this app. Allow them in Settings to get a daily reading reminder.")
        }
    }

    /// Enabling routes through notification authorization first: the toggle only lands in the ON
    /// position once permission is actually granted; a denial bounces it back and points at Settings.
    private var reminderToggleBinding: Binding<Bool> {
        Binding(
            get: { reminderEnabled },
            set: { enabled in
                settings.hapticFeedback()
                guard enabled else {
                    reminderEnabled = false
                    QuranPlannerReminder.cancel()
                    return
                }
                Task { @MainActor in
                    if await settings.requestNotificationAuthorization() {
                        withAnimation { reminderEnabled = true }
                        rescheduleReminder()
                    } else {
                        withAnimation { reminderEnabled = false }
                        showingReminderDeniedAlert = true
                    }
                }
            }
        )
    }

    /// The stored minutes-past-midnight as a Date for `DatePicker`, and back.
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                let startOfDay = Calendar.current.startOfDay(for: Date())
                return Calendar.current.date(byAdding: .minute, value: reminderMinutes, to: startOfDay) ?? startOfDay
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderMinutes = (components.hour ?? 18) * 60 + (components.minute ?? 0)
                rescheduleReminder()
            }
        )
    }

    /// Replaces (never stacks - stable identifier) the pending reminder with one matching the plan's
    /// current pace and the chosen time. No-op cancel when the reminder is off or the plan is gone.
    private func rescheduleReminder() {
        guard reminderEnabled, let plan = settings.quranPlan, plan.completedDate == nil else {
            QuranPlannerReminder.cancel()
            return
        }
        var target: Int?
        if totalAyahs > 0 {
            let todayKey = QuranPlan.dayKey(for: Date())
            let dayStart = plan.dayKey == todayKey ? min(plan.dayStartCompleted, totalCompleted) : totalCompleted
            target = QuranPlannerMath.todayTarget(plan: plan, totalAyahs: totalAyahs, dayStartCompleted: dayStart)
        }
        QuranPlannerReminder.schedule(
            plan: plan,
            minutes: reminderMinutes,
            todayTarget: target,
            pagesEquivalent: target.map(pagesEquivalent)
        )
    }

    /// Four stat tiles in the Prayer Tracker's visual language - the two features should feel like
    /// siblings.
    private func statsGrid(plan: QuranPlan, doneToday: Int) -> some View {
        let streak = QuranPlannerMath.streak(plan: plan, doneToday: doneToday)

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            if let end = plan.endDate {
                let daysLeft = QuranPlannerMath.daysLeft(until: end)
                statTile(value: "\(daysLeft)", unit: daysLeft == 1 ? "day" : "days",
                         label: "Days Left", symbol: "calendar")
                statTile(value: Self.shortDate.string(from: end), unit: "",
                         label: "Finish By", symbol: "flag.checkered")
            } else if let perDay = plan.ayahsPerDay {
                statTile(value: "\(perDay)", unit: "ayahs",
                         label: "Daily Amount", symbol: "book")
                statTile(
                    value: QuranPlannerMath.projectedFinish(plan: plan, remaining: max(0, totalAyahs - totalCompleted))
                        .map { Self.shortDate.string(from: $0) } ?? "-",
                    unit: "",
                    label: "Projected", symbol: "flag.checkered"
                )
            }

            statTile(value: "\(streak)", unit: streak == 1 ? "day" : "days",
                     label: "Streak", symbol: "flame.fill")

            if let delta = QuranPlannerMath.paceDelta(plan: plan, totalAyahs: totalAyahs, totalCompleted: totalCompleted) {
                if delta >= -5 && delta <= 5 {
                    statTile(value: "On track", unit: "", label: "Pace", symbol: "checkmark.circle.fill")
                } else if delta > 0 {
                    statTile(value: "+\(delta)", unit: "ayahs", label: "Ahead", symbol: "hare.fill")
                } else {
                    statTile(value: "\(delta)", unit: "ayahs", label: "Behind", symbol: "tortoise.fill")
                }
            } else {
                statTile(value: "\(doneToday)", unit: "ayahs", label: "Read Today", symbol: "text.book.closed.fill")
            }
        }
    }

    private func statTile(value: String, unit: String, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.caption)
                    .foregroundColor(accent2)

                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .conditionalGlassEffect(rectangle: true)
    }

    private func actionTile(title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundColor(accent)

                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .conditionalGlassEffect(rectangle: true)
    }

    /// The last 7 days as mini bars - a glanceable "did I keep up this week".
    private func weekStrip(plan: QuranPlan, doneToday: Int) -> some View {
        let days = QuranPlannerMath.lastSevenDays(plan: plan, doneToday: doneToday)
        let peak = max(1, days.map(\.count).max() ?? 1)

        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(day.count > 0 ? accent.opacity(day.isToday ? 1 : 0.6) : Color.secondary.opacity(0.16))
                        .frame(height: day.count > 0 ? max(6, 28 * CGFloat(day.count) / CGFloat(peak)) : 4)
                        .frame(maxWidth: .infinity)

                    Text(day.label)
                        .font(.system(size: 9, weight: day.isToday ? .bold : .regular))
                        .foregroundColor(day.isToday ? accent : .secondary)
                }
                .accessibilityLabel("\(day.label): \(day.count) ayahs")
            }
        }
        .frame(height: 44, alignment: .bottom)
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
                    .foregroundColor(accent)
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
                    reminderEnabled = false
                    QuranPlannerReminder.cancel()
                }
            } message: {
                Text("Your khatm progress is kept; only the goal and daily amounts are removed.")
            }
        } footer: {
            Text("Progress comes from khatm marking: ayahs are marked as you read in the app, and you can review or reset them in Khatm mode on the Quran tab.")
                .font(.caption)
        }
        .themedListRowBackground()
    }

    // MARK: Completed

    @ViewBuilder
    private func completedSections(plan: QuranPlan) -> some View {
        Section {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 76, height: 76)
                    .conditionalGlassEffect(circle: true)

                Text("Khatm Complete")
                    .font(.title2.weight(.bold))

                let days = QuranPlannerMath.daysElapsed(since: plan.startDate) + 1
                Text("Alhamdulillah, you finished the Quran over \(days) day\(days == 1 ? "" : "s"). May Allah accept it and make it a witness for you.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .listRowSeparator(.hidden)
        }
        .themedListRowBackground()

        Section {
            Button {
                settings.hapticFeedback()
                showingRestartConfirmation = true
            } label: {
                Label("Start a New Khatm", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(accent)
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
                    reminderEnabled = false
                    QuranPlannerReminder.cancel()
                }
            } message: {
                Text("This resets khatm progress to zero so a fresh plan can begin.")
            }

            Button(role: .destructive) {
                settings.hapticFeedback()
                withAnimation { settings.quranPlan = nil }
                reminderEnabled = false
                QuranPlannerReminder.cancel()
            } label: {
                Label("End Plan", systemImage: "xmark.circle")
                    .font(.subheadline)
            }
        } footer: {
            Text("Ending the plan keeps your completed khatm progress.")
                .font(.caption)
        }
        .themedListRowBackground()
    }

    private static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()
}
#endif
