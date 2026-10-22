#if os(iOS)
import SwiftUI

// The Revision plan, the Quran Planner's second plan (2026-10-12): a part of the Quran the reader
// already knows (a juz range, or chosen surahs) gone through in full every N days. Each day hands out
// the next portion of the set, recomputed from what is left of the cycle, so a missed day spreads
// over the days that remain; when the whole set has been revised the cycle closes and the next one
// starts from the top. Progress is its own per-cycle set of ayahs, never the khatm marks: an ayah
// counts as revised when it is read in the app (any sort mode) or marked from the planner, and a new
// cycle clears it while the khatm stays as it was. Hafs only, like the khatm plan: the keys are Hafs
// ayah numbers.

// MARK: - Model

struct QuranRevisionPlan: Codable, Equatable {
    /// Which ayahs are revised.
    enum Scope: Codable, Equatable {
        /// Whole juz, `from` through `to` inclusive (1...30).
        case juzRange(from: Int, to: Int)
        /// Chosen surahs by number, in mushaf order whatever order they were picked in.
        case surahs([Int])

        var isEmpty: Bool {
            switch self {
            case .juzRange(let from, let to): return from > to
            case .surahs(let ids): return ids.isEmpty
            }
        }
    }

    var scope: Scope
    /// How many days one pass through the set takes (1...90).
    var cycleDays: Int
    /// The day the plan began (start-of-day).
    var startDate: Date
    /// The first day of the current cycle (start-of-day). Day 1 of the cycle is this day.
    var cycleStartDate: Date
    var cyclesCompleted: Int
    /// Which day the two counters below belong to ("yyyy-MM-dd", `QuranPlan.dayKey`).
    var dayKey: String
    /// The revised-set count when `dayKey` began, so "revised today" is a subtraction.
    var dayStartRevised: Int
    /// Ayahs revised earlier today in a cycle that then closed (the set emptied), carried so the day's
    /// count survives the reset.
    var carriedToday: Int
    /// Ayahs revised per past day, pruned to the most recent 30 (streak and week strip).
    var history: [String: Int]?

    /// Days into the cycle, day 1 = the cycle's first day.
    func cycleDay(on date: Date = Date()) -> Int {
        QuranPlannerMath.daysElapsed(since: cycleStartDate, to: date) + 1
    }

    /// Days left in the cycle, today included, never below 1: the denominator that spreads what is
    /// left over the time that remains.
    func daysLeftInCycle(on date: Date = Date()) -> Int {
        max(1, cycleDays - QuranPlannerMath.daysElapsed(since: cycleStartDate, to: date))
    }

    /// Days past the cycle's length with the set still unfinished (0 while on time).
    func daysOverdue(on date: Date = Date()) -> Int {
        max(0, QuranPlannerMath.daysElapsed(since: cycleStartDate, to: date) + 1 - cycleDays)
    }
}

// MARK: - Persistence (the plan as one blob; the revised set khatm-style, debounced)
//
// The set's load, read, reset and flush live in SettingsQuran.swift (every target that compiles
// Settings compiles them; `flushAllPendingWrites` calls the flush). This iOS-only file holds the plan
// itself and everything that needs the Quran: marking, pruning, settling.

extension Settings {
    private static var quranRevisionPlanCache: (data: Data, value: QuranRevisionPlan?)?

    var quranRevisionPlan: QuranRevisionPlan? {
        get {
            if let cached = Self.quranRevisionPlanCache, cached.data == quranRevisionPlanData { return cached.value }
            let decoded = UserDataRescue.decode(QuranRevisionPlan.self, from: quranRevisionPlanData,
                                                key: "quranRevisionPlanData", decoder: Self.decoder)
            Self.quranRevisionPlanCache = (quranRevisionPlanData, decoded)
            return decoded
        }
        set {
            let encoded = newValue.flatMap { try? Self.encoder.encode($0) } ?? Data()
            Self.quranRevisionPlanCache = (encoded, newValue)
            quranRevisionPlanData = encoded
        }
    }

    /// The reader's hook: an ayah that just came on screen. Cheap when there is no revision plan (one
    /// decoded-plan read), and a no-op outside the plan's set.
    func noteRevisionAyahRead(surah: Int, ayah: Int) {
        guard isHafsDisplay, let plan = quranRevisionPlan else { return }
        guard QuranRevisionMath.scope(plan.scope, contains: surah, ayah: ayah) else { return }
        markRevisionAyahRevised(surah: surah, ayah: ayah)
    }

    /// - Parameter immediate: a deliberate tap publishes at once; automatic marking while scrolling
    ///   rides the debounced save and publishes with it, so the scroll never stutters.
    func markRevisionAyahRevised(surah: Int, ayah: Int, immediate: Bool = false) {
        guard isHafsDisplay else { return }
        ensureRevisionCacheLoaded()
        guard revisionRevisedCache.insert(Self.revisionKey(surah: surah, ayah: ayah)).inserted else { return }
        if immediate { objectWillChange.send() }
        scheduleRevisionProgressSave(refresh: !immediate)
    }

    /// Drops marks outside the given scope (the scope was adjusted mid-cycle); keeps the rest.
    func pruneRevisionProgress(to scope: QuranRevisionPlan.Scope) {
        ensureRevisionCacheLoaded()
        let before = revisionRevisedCache.count
        revisionRevisedCache = revisionRevisedCache.filter {
            QuranRevisionMath.scope(scope, contains: $0 / 1000, ayah: $0 % 1000)
        }
        guard revisionRevisedCache.count != before else { return }
        persistRevisionProgressNow()
        objectWillChange.send()
    }

    /// The khatm set's debounce, one task re-armed by a generation counter: a burst of auto-marks
    /// while scrolling lands as one disk write once the scroll settles.
    private func scheduleRevisionProgressSave(refresh: Bool) {
        if refresh { revisionRefreshPending = true }
        revisionSaveGeneration &+= 1
        guard revisionSaveTask == nil else { return }
        revisionSaveTask = Task { @MainActor [weak self] in
            var lastSeen = -1
            while true {
                guard let self else { return }
                if Task.isCancelled { return }
                if self.revisionSaveGeneration == lastSeen { break }
                lastSeen = self.revisionSaveGeneration
                try? await Task.sleep(nanoseconds: PerformanceProfile.shared.tier == .reduced ? 1_000_000_000 : 250_000_000)
            }
            guard let self else { return }
            self.revisionSaveTask = nil
            self.persistRevisionProgressNow()
            if self.revisionRefreshPending {
                self.revisionRefreshPending = false
                self.objectWillChange.send()
            }
        }
    }

    /// Rolls the plan's "today" forward on a new day and closes the cycle once the whole set is
    /// revised (the set empties, the next cycle starts today). Only writes when something changed, so
    /// it is safe from onAppear / onReceive as often as the khatm settle runs.
    @MainActor
    func settleQuranRevisionPlan(quran: [Surah]) {
        guard var plan = quranRevisionPlan else { return }
        ensureRevisionCacheLoaded()
        var changed = false
        let revised = revisionRevisedCount

        let todayKey = QuranPlan.dayKey(for: Date())
        if plan.dayKey != todayKey {
            var history = plan.history ?? [:]
            history[plan.dayKey] = QuranRevisionMath.doneToday(plan: plan, revisedCount: revised)
            if history.count > 30 {
                for key in history.keys.sorted().dropLast(30) { history[key] = nil }
            }
            plan.history = history
            plan.dayKey = todayKey
            plan.dayStartRevised = revised
            plan.carriedToday = 0
            changed = true
        }

        let scopeCount = QuranRevisionMath.ayahs(in: plan.scope, quran: quran).count
        if scopeCount > 0, revised >= scopeCount {
            // The set is done: bank today's share of it, close the cycle, start the next one today.
            plan.carriedToday += max(0, revised - plan.dayStartRevised)
            plan.dayStartRevised = 0
            plan.cyclesCompleted += 1
            plan.cycleStartDate = Calendar.current.startOfDay(for: Date())
            resetRevisionProgress()
            changed = true
        }

        if changed { quranRevisionPlan = plan }
    }
}

// MARK: - Math

enum QuranRevisionMath {
    /// One ayah of the set, enough to open the reader and describe a span without the full model.
    struct AyahRef: Equatable {
        let surahID: Int
        let surahName: String
        let ayahID: Int
        let page: Int?
        var key: Int { Settings.revisionKey(surah: surahID, ayah: ayahID) }
    }

    private static var ayahsCache: (scope: QuranRevisionPlan.Scope, surahCount: Int, refs: [AyahRef])?

    /// The set in mushaf order, memoized on (scope, surah count): a juz range walks every ayah's `juz`,
    /// a surah list takes whole surahs.
    static func ayahs(in scope: QuranRevisionPlan.Scope, quran: [Surah]) -> [AyahRef] {
        if let cached = ayahsCache, cached.scope == scope, cached.surahCount == quran.count { return cached.refs }
        var refs: [AyahRef] = []
        switch scope {
        // `Surah.ayahs` carries 50 slots that exist only in another riwayah's numbering (2:287, 112:5...),
        // with no Hafs text; the set is Hafs ayahs only, as the reader shows them.
        case .juzRange(let from, let to):
            for surah in quran {
                for ayah in surah.ayahs where ayah.existsInQiraah(nil, surahID: surah.id) {
                    guard let juz = ayah.juz, juz >= from, juz <= to else { continue }
                    refs.append(AyahRef(surahID: surah.id, surahName: surah.nameTransliteration, ayahID: ayah.id, page: ayah.page))
                }
            }
        case .surahs(let ids):
            let wanted = Set(ids)
            for surah in quran where wanted.contains(surah.id) {
                for ayah in surah.ayahs where ayah.existsInQiraah(nil, surahID: surah.id) {
                    refs.append(AyahRef(surahID: surah.id, surahName: surah.nameTransliteration, ayahID: ayah.id, page: ayah.page))
                }
            }
        }
        ayahsCache = (scope, quran.count, refs)
        return refs
    }

    /// Whether one ayah is in the set, without building the set: the reader asks per ayah.
    static func scope(_ scope: QuranRevisionPlan.Scope, contains surah: Int, ayah: Int) -> Bool {
        switch scope {
        case .surahs(let ids):
            return ids.contains(surah)
        case .juzRange(let from, let to):
            guard let juz = QuranData.shared.ayah(surah: surah, ayah: ayah)?.juz else { return false }
            return juz >= from && juz <= to
        }
    }

    /// Distinct mushaf pages the refs touch.
    static func pageCount(of refs: [AyahRef]) -> Int {
        Set(refs.compactMap(\.page)).count
    }

    /// A short name for the set: "Juz 30", "Juz 28 to 30", "Al-Mulk", "3 surahs".
    static func scopeLabel(_ scope: QuranRevisionPlan.Scope, quran: [Surah]) -> String {
        switch scope {
        case .juzRange(let from, let to):
            return from == to ? "Juz \(from)" : "Juz \(from) to \(to)"
        case .surahs(let ids):
            let names = quran.filter { ids.contains($0.id) }.map(\.nameTransliteration)
            switch names.count {
            case 0: return "No surahs"
            case 1: return names[0]
            case 2: return "\(names[0]) and \(names[1])"
            default: return "\(names.count) surahs"
            }
        }
    }

    /// Today's portion, from what was left when today began: remaining / days left in the cycle,
    /// rounded up. Zero once the set is done.
    static func todayTarget(plan: QuranRevisionPlan, scopeCount: Int, dayStartRevised: Int, on date: Date = Date()) -> Int {
        let remaining = max(0, scopeCount - dayStartRevised)
        guard remaining > 0 else { return 0 }
        return Int((Double(remaining) / Double(plan.daysLeftInCycle(on: date))).rounded(.up))
    }

    /// Ayahs revised today: what a closed cycle carried plus the set's growth since the day began.
    static func doneToday(plan: QuranRevisionPlan, revisedCount: Int) -> Int {
        plan.carriedToday + max(0, revisedCount - plan.dayStartRevised)
    }

    private static var spanCache: (progressRevision: Int, scope: QuranRevisionPlan.Scope, count: Int, span: QuranPlannerMath.TodaySpan?)?

    /// The next `count` unrevised ayahs of the set in mushaf order, memoized on the set's revision.
    static func todaySpan(refs: [AyahRef], scope: QuranRevisionPlan.Scope, settings: Settings, count: Int) -> QuranPlannerMath.TodaySpan? {
        settings.ensureRevisionCacheLoaded()
        let progressRevision = settings.revisionProgressRevision
        if let cached = spanCache, cached.progressRevision == progressRevision, cached.scope == scope, cached.count == count {
            return cached.span
        }
        var remaining = max(1, count)
        var start: AyahRef?
        var last: AyahRef?
        for ref in refs where !settings.isRevisionAyahRevised(surah: ref.surahID, ayah: ref.ayahID) {
            if start == nil { start = ref }
            last = ref
            remaining -= 1
            if remaining <= 0 { break }
        }
        var span: QuranPlannerMath.TodaySpan?
        if let start, let last {
            span = QuranPlannerMath.TodaySpan(
                startSurahID: start.surahID, startSurahName: start.surahName, startAyah: start.ayahID, startPage: start.page,
                endSurahName: last.surahName, endAyah: last.ayahID, endPage: last.page
            )
        }
        spanCache = (progressRevision, scope, count, span)
        return span
    }

    /// Marks the next `count` unrevised ayahs of the set (revised away from the app).
    static func markNextUnrevisedAyahs(refs: [AyahRef], settings: Settings, count: Int) {
        let targets = Array(refs.lazy
            .filter { !settings.isRevisionAyahRevised(surah: $0.surahID, ayah: $0.ayahID) }
            .prefix(max(0, count)))
        // The last mark is `immediate` so the UI snaps to the new state now; the earlier ones ride the
        // debounced save (one disk write for the batch). The last of what is LEFT, not the count-th:
        // with fewer unrevised ayahs than the amount asked for, the batch used to end without an
        // immediate mark and the ring stayed stale for the debounce.
        for (index, ref) in targets.enumerated() {
            settings.markRevisionAyahRevised(surah: ref.surahID, ayah: ref.ayahID,
                                             immediate: index == targets.count - 1)
        }
        spanCache = nil
    }
}

// MARK: - Surah picker

/// The multi-select list behind the Revision plan's "Surahs" scope: every surah with a checkmark,
/// a search field, and a menu to take the favorites, everything, or nothing.
struct RevisionSurahPicker: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var quranData = QuranData.shared
    @Binding var selection: Set<Int>
    @State private var searchText = ""

    private var accent: Color { settings.accentColor.color }

    private var surahs: [Surah] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return quranData.quran }
        if let number = Int(trimmed) { return quranData.quran.filter { $0.id == number } }
        return quranData.quran.filter { surah in
            surah.nameTransliteration.localizedCaseInsensitiveContains(trimmed)
                || surah.nameEnglish.localizedCaseInsensitiveContains(trimmed)
                || surah.nameArabic.contains(trimmed)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(surahs) { surah in
                    let chosen = selection.contains(surah.id)
                    Button {
                        settings.hapticFeedback()
                        if chosen { selection.remove(surah.id) } else { selection.insert(surah.id) }
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(surah.id)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(.secondary)
                                .frame(width: 32, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(surah.nameTransliteration)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("\(surah.ayahCountLabel()) · \(surah.pageCountLabel)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(surah.nameArabic)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Image(systemName: chosen ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(chosen ? accent : .secondary.opacity(0.5))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(chosen ? [.isSelected] : [])
                }
            } header: {
                Text(selection.count == 1 ? "1 SURAH CHOSEN" : "\(selection.count) SURAHS CHOSEN")
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .searchable(text: $searchText, prompt: "Surah name or number")
        .navigationTitle("Choose Surahs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if !settings.favoriteSurahs.isEmpty {
                        Button {
                            settings.hapticFeedback()
                            selection = Set(settings.favoriteSurahs)
                        } label: {
                            Label("Favorite Surahs", systemImage: "star.fill")
                        }
                    }
                    Button {
                        settings.hapticFeedback()
                        selection = Set(quranData.quran.map(\.id))
                    } label: {
                        Label("Select All", systemImage: "checkmark.circle")
                    }
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        selection.removeAll()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Selection options")
            }
        }
    }
}
#endif
