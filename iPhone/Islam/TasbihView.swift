import SwiftUI

/// Every tasbih count, held OUTSIDE the view tree. TasbihView deliberately does NOT observe this
/// object: only the views that actually render a count (the active card and each row's controls)
/// subscribe, so a count tap - the highest-frequency interaction on the screen - re-renders those
/// small views instead of re-running the whole TasbihView List (which is what happened when the
/// counts lived in TasbihView's own @State/@AppStorage).
@MainActor
final class TasbihCounters: ObservableObject {
    static let shared = TasbihCounters()

    /// Sentinel for "the free counter" rather than a row of `commonDhikrItems`.
    static let freeIndex = -1

    /// Counts for the preset dhikr rows, keyed by row index. Persisted like the free counter: these
    /// used to be session-only "scratch" state, which meant a background jetsam mid-count silently
    /// zeroed a dhikr the user was 80 taps into - the one loss a tally counter must never have.
    @Published private var presetCounts: [Int: Int] {
        didSet {
            let stored = Dictionary(uniqueKeysWithValues: presetCounts.map { (String($0.key), $0.value) })
            UserDefaults.standard.set(stored, forKey: "tasbihPresetCounts")
        }
    }

    /// The free count persists (same key the old `@AppStorage("tasbihFreeCount")` used), because it's
    /// meant to be carried across sittings and run up as high as the user likes.
    @Published private var freeCount: Int {
        didSet { UserDefaults.standard.set(freeCount, forKey: "tasbihFreeCount") }
    }

    // MARK: Lifetime and streak

    /// Every count ever tapped, across every counter. Only ever grows: a minus or a reset corrects a
    /// tally, it does not un-remember the dhikr that was said. Seeded from the live counts the first
    /// time this build runs, so nobody's history starts at zero.
    @Published private(set) var lifetimeCount: Int {
        didSet { UserDefaults.standard.set(lifetimeCount, forKey: "tasbihLifetimeCount") }
    }

    /// Counts tapped per local calendar day, keyed "yyyy-MM-dd". The keys ARE the days the tasbih was
    /// used, which is what the streak walks; the values give today's count.
    @Published private(set) var countsByDay: [String: Int] {
        didSet { UserDefaults.standard.set(countsByDay, forKey: "tasbihCountsByDay") }
    }

    private init() {
        freeCount = UserDefaults.standard.integer(forKey: "tasbihFreeCount")
        let stored = UserDefaults.standard.dictionary(forKey: "tasbihPresetCounts") as? [String: Int] ?? [:]
        let presets = Dictionary(uniqueKeysWithValues: stored.compactMap { key, value in
            Int(key).map { ($0, value) }
        })
        presetCounts = presets
        countsByDay = UserDefaults.standard.dictionary(forKey: "tasbihCountsByDay") as? [String: Int] ?? [:]
        if let saved = UserDefaults.standard.object(forKey: "tasbihLifetimeCount") as? Int {
            lifetimeCount = saved
        } else {
            // First run with a lifetime total: what is on the counters right now is the least the
            // user has ever counted, so history begins there rather than at zero.
            lifetimeCount = UserDefaults.standard.integer(forKey: "tasbihFreeCount") + presets.values.reduce(0, +)
        }
    }

    /// Everything currently ON the counters - the free counter plus every preset row. The badges and
    /// the profile read `lifetimeCount` instead, which a reset can no longer take away.
    var totalCount: Int {
        freeCount + presetCounts.values.reduce(0, +)
    }

    /// Local calendar day key. The device's calendar and time zone: a dhikr said at 11 pm belongs to
    /// the day the user was living in, not to UTC's.
    static func dayKey(_ date: Date = Date()) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static func date(fromDayKey key: String) -> Date? {
        let bits = key.split(separator: "-").compactMap { Int($0) }
        guard bits.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: bits[0], month: bits[1], day: bits[2]))
    }

    /// Counts tapped today.
    var todayCount: Int { countsByDay[Self.dayKey()] ?? 0 }

    /// Days on which the tasbih was used at all.
    var activeDayCount: Int { countsByDay.count }

    /// Consecutive days of use ending today - or ending yesterday, so a streak is not shown as broken
    /// before the user has had today's chance to keep it.
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var day = today
        if countsByDay[Self.dayKey(day)] == nil {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  countsByDay[Self.dayKey(yesterday)] != nil else { return 0 }
            day = yesterday
        }
        var streak = 0
        while countsByDay[Self.dayKey(day)] != nil {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    /// The longest run of consecutive days ever.
    var bestStreak: Int {
        let calendar = Calendar.current
        let days = countsByDay.keys.compactMap(Self.date(fromDayKey:)).map { calendar.startOfDay(for: $0) }.sorted()
        var best = 0, run = 0
        var previous: Date?
        for day in days {
            if let previous, let next = calendar.date(byAdding: .day, value: 1, to: previous), calendar.isDate(next, inSameDayAs: day) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return max(best, currentStreak)
    }

    /// A count went UP by `amount`: remember it for life and for today.
    private func record(increment amount: Int) {
        guard amount > 0 else { return }
        lifetimeCount += amount
        countsByDay[Self.dayKey(), default: 0] += amount
    }

    func binding(for index: Int) -> Binding<Int> {
        if index == Self.freeIndex {
            return Binding(
                get: { self.freeCount },
                set: { newValue in
                    let clamped = max(0, newValue)
                    self.record(increment: clamped - self.freeCount)
                    self.freeCount = clamped
                }
            )
        }
        return Binding(
            get: { self.presetCounts[index, default: 0] },
            set: { newValue in
                self.record(increment: newValue - self.presetCounts[index, default: 0])
                self.presetCounts[index] = newValue
            }
        )
    }
}

/// Today, the streak, the best streak and the lifetime total, in one glass strip at the top of the
/// tasbih screen. Its own view so it alone observes `TasbihCounters` - the rest of the screen still
/// skips every count tap.
struct TasbihStatsStrip: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var counts = TasbihCounters.shared

    var body: some View {
        let streak = counts.currentStreak
        HStack(spacing: 8) {
            stat(value: counts.todayCount, label: "Today", systemImage: "sun.max.fill")
            stat(value: streak, label: streak == 1 ? "Day streak" : "Day streak", systemImage: "flame.fill", emphasized: streak > 0)
            stat(value: counts.bestStreak, label: "Best", systemImage: "trophy.fill")
            stat(value: counts.lifetimeCount, label: "Lifetime", systemImage: "infinity")
        }
        .padding(.vertical, 2)
    }

    private func stat(value: Int, label: String, systemImage: String, emphasized: Bool = false) -> some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(emphasized ? Color.orange : settings.accentColor.color)

            Text(value.formatted(.number.notation(.compactName)))
                .font(.headline.weight(.bold).monospacedDigit())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .numericContentTransition()
                .animation(.easeOut(duration: 0.2), value: value)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .conditionalGlassEffect(rectangle: true, interactive: false)
    }
}

struct TasbihView: View {
    @ObservedObject var settings = Settings.shared

    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @State private var selectedDhikrIndex: Int = TasbihCounters.freeIndex

    @AppStorage("tasbihFreeLabel") private var freeLabel = ""
    /// How many counts complete one turn of the ring. Purely cosmetic; the count itself never wraps.
    @AppStorage("tasbihFreeCycle") private var freeCycle = 33

    private static let cycleChoices = [33, 99, 100, 500, 1000]

    /// Computed, not stored: a stored `let` would force `commonDhikrItems` (and its per-item
    /// diacritic-folded search blobs) to initialize the moment the STRUCT was built - and on watchOS
    /// the Islam tab builds this struct eagerly for its NavigationLink on every body pass.
    private var tasbihData: [CommonDhikr] { commonDhikrItems }

    private var isFreeDhikrSelected: Bool { selectedDhikrIndex == TasbihCounters.freeIndex }

    var body: some View {
        List {
            Group {
                statsSection
                freeDhikrSection
                dhikrSelectionSection
                #if os(watchOS)
                activeTasbihSection
                #endif
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        // A plain adaptive inset (safeAreaBar on iOS 26): just the card, no wrapping stack and no solid
        // backdrop, so it floats like every other bottom bar and never shrinks on scroll.
        .adaptiveSafeArea(edge: .bottom) {
            activeTasbihCard
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        #endif
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle("Tasbih Counter")
    }

    /// Today's count, the day streak, the best streak and the lifetime total. Every count on this screen
    /// feeds them; a reset or a minus corrects a tally without touching them.
    private var statsSection: some View {
        Section(header: Text("YOUR DHIKR"), footer: Text("Count on any day to keep the streak. Resets and corrections never lower the lifetime total.")) {
            TasbihStatsStrip()
                #if os(iOS)
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                #endif
        }
    }

    /// A counter with no dhikr attached: name it whatever you're reciting, or nothing at all, and count.
    private var freeDhikrSection: some View {
        Section(header: Text("OTHER DHIKR"), footer: Text("For any other authentic dhikr you are reciting. The count is kept between visits and has no limit.")) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(isFreeDhikrSelected ? settings.accentColor.color.opacity(0.15) : .clear)
                    #if os(iOS)
                    .padding(.horizontal, -12)
                    .padding(.vertical, tasbihSelectionBackgroundVerticalPadding)
                    #else
                    .padding(-7)
                    #endif

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Other dhikr", text: $freeLabel)
                            .font(.headline)
                            .foregroundColor(settings.accentColor.color)
                            #if os(iOS)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            #endif

                        cyclePicker
                    }

                    Spacer()

                    TasbihCounterControls(counterIndex: TasbihCounters.freeIndex)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isFreeDhikrSelected else { return }
                withAnimation {
                    settings.hapticFeedback()
                    selectedDhikrIndex = TasbihCounters.freeIndex
                }
            }
        }
    }

    /// The ring is the only thing a cycle length changes - a full turn every N counts, as a visual marker.
    /// watchOS has no `Menu`, so there the label advances through the choices on tap.
    @ViewBuilder
    private var cyclePicker: some View {
        #if os(iOS)
        Menu {
            ForEach(Self.cycleChoices, id: \.self) { choice in
                Button {
                    settings.hapticFeedback()
                    freeCycle = choice
                } label: {
                    if choice == freeCycle {
                        Label("Ring every \(choice)", systemImage: "checkmark")
                    } else {
                        Text("Ring every \(choice)")
                    }
                }
            }
        } label: {
            cycleLabel
        }
        #else
        Button {
            settings.hapticFeedback()
            let next = Self.cycleChoices.firstIndex(of: freeCycle).map { ($0 + 1) % Self.cycleChoices.count } ?? 0
            freeCycle = Self.cycleChoices[next]
        } label: {
            cycleLabel
        }
        .buttonStyle(.plain)
        #endif
    }

    private var cycleLabel: some View {
        Text("Ring every \(freeCycle)")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    private var dhikrSelectionSection: some View {
        Section(header: Text("DHIKR & REMEMBRANCES")) {
            ForEach(tasbihData.indices, id: \.self) { index in
                tasbihSelectionButton(for: index)
            }
        }
    }

    private func tasbihSelectionButton(for index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(selectedDhikrIndex == index ? settings.accentColor.color.opacity(0.15) : .clear)
                #if os(iOS)
                .padding(.horizontal, -12)
                .padding(.vertical, tasbihSelectionBackgroundVerticalPadding)
                #else
                .padding(-7)
                #endif

            TasbihRow(tasbih: tasbihData[index], counterIndex: index)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            if index != selectedDhikrIndex {
                withAnimation {
                    settings.hapticFeedback()
                    selectedDhikrIndex = index
                }
            }
        }
        #if os(watchOS)
        .padding(.vertical, 12)
        #endif
    }

    #if os(iOS)
    private var tasbihSelectionBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return -11
        }
        return -2
    }
    #endif

    private var activeTasbihSection: some View {
        return Section {
            activeTasbihCard
        }
    }

    /// Thin constructor only - the card itself is a standalone View (see `ActiveTasbihCard`) because its
    /// input (the live count) changes on every tap, far more often than anything else on this screen.
    private var activeTasbihCard: ActiveTasbihCard {
        // `selectedDhikrIndex` is the free-count sentinel or a real row; never an out-of-range index.
        ActiveTasbihCard(
            selectedDhikr: tasbihData.indices.contains(selectedDhikrIndex) ? tasbihData[selectedDhikrIndex] : nil,
            counterIndex: selectedDhikrIndex,
            freeLabel: freeLabel,
            freeCycle: freeCycle
        )
    }
}

/// The active-counter card, extracted into its own View as a real invalidation boundary: it is (with
/// the row controls) the only view observing `TasbihCounters`, so each count tap re-renders just this
/// card - TasbihView itself no longer owns the count and its List is skipped entirely.
struct ActiveTasbihCard: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject private var counts = TasbihCounters.shared

    /// nil means the free counter is active.
    let selectedDhikr: CommonDhikr?
    let counterIndex: Int
    let freeLabel: String
    let freeCycle: Int

    private var usesCustomArabicFace: Bool { settings.islamUsesCustomArabicFace }

    var body: some View {
        let counterBinding = counts.binding(for: counterIndex)
        let cycle = selectedDhikr == nil ? freeCycle : 33
        let count = counterBinding.wrappedValue
        // Which turn of the ring you're on, and how far round it. The count itself never wraps.
        let laps = cycle > 0 ? count / max(cycle, 1) : 0
        let withinLap = cycle > 0 ? count % max(cycle, 1) : count

        return VStack(spacing: 12) {
            // The dhikr sits ABOVE the ring rather than crammed inside it - the Arabic needed room, and the
            // count is what belongs at the centre of a counter.
            VStack(spacing: 2) {
                // The Islam tab's Arabic face, like every other screen that shows this same dhikr text - the
                // one `IslamArabicFontPicker` setting, not the Quran's own font. Only the Arabic gets it: a
                // free-count LABEL the user typed is their own text, not Arabic, so it stays in the UI face.
                // `usesCustomArabicFace` is false when the reader picked the Basic font, in which case the
                // rounded system face is correct and the design opt-out must not fire.
                Text(selectedDhikr?.arabicText ?? (freeLabel.isEmpty ? "Other Dhikr" : freeLabel))
                    .font(
                        selectedDhikr != nil && usesCustomArabicFace
                            ? Font.arabic(settings.nonQuranArabicFontName, size: 26, relativeTo: .title3)
                            : .title3.weight(.bold)
                    )
                    .arabicFontDesign(custom: selectedDhikr != nil && usesCustomArabicFace)
                    .foregroundColor(settings.accentColor.color)
                    // Trailing, not centered: a wrapped Arabic line must rag on the left like Arabic
                    // prose (a single line still sits visually centered - the text hugs its own width).
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)

                Text(selectedDhikr?.transliteration ?? "Tap anywhere to count")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            ZStack {
                ProgressCircleView(progress: count, cycle: cycle, lineWidth: 10)
                    .scaledToFit()
                    .frame(maxWidth: 116, maxHeight: 116)

                VStack(spacing: 0) {
                    Text("\(count)")
                        .font(.system(size: 30, weight: .semibold))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .numericContentTransition()
                        .animation(.easeOut(duration: 0.18), value: count)

                    // Position within the current turn, so a long session still tells you where you are.
                    Text("\(withinLap) / \(cycle)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if laps > 0 {
                        Text(laps == 1 ? "1 round" : "\(laps) rounds")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)
                            .padding(.top, 2)
                    }
                }
            }

            // Explicit controls, so undoing a miscount doesn't mean starting the dhikr over.
            HStack(spacing: 10) {
                counterButton(systemImage: "minus", disabled: count == 0) {
                    counterBinding.wrappedValue = max(0, count - 1)
                }

                counterButton(systemImage: "arrow.counterclockwise", disabled: count == 0) {
                    counterBinding.wrappedValue = 0
                }

                counterButton(systemImage: "plus", prominent: true) {
                    counterBinding.wrappedValue = count + 1
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        // iOS-only: on the watch this card is a LIST ROW, and the system row platter already gives it
        // chrome - glass on top would double-card it. On iOS it floats in a safe-area inset, so the
        // glass IS its only background.
        #if os(iOS)
        .conditionalGlassEffect(rectangle: true, useColor: 0.12)
        #endif
        // The whole card is still the counter - the buttons are for correcting, not for the counting itself.
        .onTapGesture {
            settings.hapticFeedback()
            // No per-tap transaction: the ring animates via its own scoped .animation(value:), and a
            // withAnimation per tap queued overlapping transactions under rapid dhikr tapping.
            counterBinding.wrappedValue += 1
        }
    }

    private func counterButton(systemImage: String, prominent: Bool = false, disabled: Bool = false,
                               action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeOut(duration: 0.15)) { action() }
        } label: {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(prominent ? Color.white : settings.accentColor.color)
                .frame(width: prominent ? 64 : 44, height: 36)
                .background(
                    Capsule().fill(
                        prominent
                            ? settings.accentColor.color.opacity(disabled ? 0.4 : 1)
                            : settings.accentColor.color.opacity(0.15)
                    )
                )
                .opacity(disabled && !prominent ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct ProgressCircleView: View {
    var progress: Int
    /// Counts per full turn of the ring. The count itself is never capped by this.
    var cycle: Int = 33
    var lineWidth: CGFloat = 15
    @ObservedObject var settings = Settings.shared

    var body: some View {
        let turn = max(cycle, 1)
        let progressFraction = CGFloat(progress % turn) / CGFloat(turn)
        return ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(settings.accentColor.color)

            Circle()
                .trim(from: 0.0, to: progressFraction)
                .stroke(settings.accentColor.angularGradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progressFraction)
        }
    }
}

struct CounterView: View {
    @ObservedObject var settings = Settings.shared

    @Binding var counter: Int

    var body: some View {
        VStack(alignment: .center) {
            Text("\(counter)")
                .font(.title)
                .monospacedDigit()
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 2)

            Image(systemName: "plus.circle")
                .font(.title3)
                .foregroundColor(settings.accentColor.color)
        }
    }
}

struct TasbihRow: View {
    @ObservedObject var settings = Settings.shared

    let tasbih: CommonDhikr
    /// An index into `TasbihCounters`, not a Binding: a Binding made fresh each parent pass holds new
    /// closures, which SwiftUI can never prove unchanged - an Int compares, so the row can be skipped.
    let counterIndex: Int

    var body: some View {
        HStack {
            textColumn
            
            Spacer()
            
            counterControls
        }
        .contentShape(Rectangle())
        #if os(iOS)
        .contextMenu {
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = tasbih.arabicText
            } label: {
                Label("Copy Arabic", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = tasbih.transliteration
            } label: {
                Label("Copy Transliteration", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = tasbih.translation
            } label: {
                Label("Copy Translation", systemImage: "doc.on.doc")
            }
        }
        #endif
    }

    private var textColumn: some View {
        VStack(alignment: .leading) {
            Text(tasbih.arabicText)
                // The ISLAM-tab Arabic face, not the Quran glyph font: the Quran faces carry a huge
                // line box (phantom padding above and below) and shape into runs that truncate
                // instead of wrapping in a narrow column.
                .font(
                    settings.islamUsesCustomArabicFace
                        ? Font.arabic(settings.nonQuranArabicFontName, size: 20, relativeTo: .headline)
                        : .headline
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .foregroundColor(settings.accentColor.color)
                // Wrapped Arabic rags on the left like Arabic prose should - never one clipped line.
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)

            Text(tasbih.transliteration)
                .font(.subheadline)
                .foregroundColor(.primary)

            Text(tasbih.translation)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var counterControls: some View {
        TasbihCounterControls(counterIndex: counterIndex)
    }
}

/// The minus / count / plus / reset stack. Shared by the preset dhikr rows and the free-count row so the two
/// can't drift apart on what a tap does. Observes `TasbihCounters` itself (rather than taking a Binding) so
/// a count tap re-renders only this small stack and the active card - never the enclosing List.
struct TasbihCounterControls: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject private var counts = TasbihCounters.shared

    let counterIndex: Int

    var body: some View {
        let counter = counts.binding(for: counterIndex)
        let count = counter.wrappedValue

        // The minus | count | plus capsule with a SMALL reset chip centered underneath - never
        // stretched to the capsule's width, never beside it stealing the text column's room.
        return VStack(spacing: 5) {
            HStack(spacing: 0) {
                Button {
                    guard count > 0 else { return }
                    settings.hapticFeedback()
                    counter.wrappedValue = count - 1
                } label: {
                    Image(systemName: "minus")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(count == 0 ? .secondary : settings.accentColor.color)
                        .frame(width: 32, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(count <= 0)

                Text("\(count)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .frame(minWidth: 34)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Button {
                    settings.hapticFeedback()
                    counter.wrappedValue = count + 1
                } label: {
                    Image(systemName: "plus")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .frame(width: 32, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .conditionalGlassEffect()

            Button {
                guard count > 0 else { return }
                settings.hapticFeedback()
                withAnimation { counter.wrappedValue = 0 }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(count == 0 ? .secondary : settings.accentColor.color)
                    .frame(width: 40, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .conditionalGlassEffect()
            .disabled(count <= 0)
            .opacity(count == 0 ? 0.5 : 1)
            .accessibilityLabel("Reset count")
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        TasbihView()
    }
}

/// `.contentTransition(.numericText())` where the OS has it (iOS 16 / watchOS 9); a plain redraw below.
private struct NumericContentTransition: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, watchOS 9.0, *) {
            content.contentTransition(.numericText())
        } else {
            content
        }
    }
}

extension View {
    func numericContentTransition() -> some View { modifier(NumericContentTransition()) }
}
