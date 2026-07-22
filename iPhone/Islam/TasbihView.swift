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

    /// Per-app-session scratch counts for the preset dhikr rows, keyed by row index.
    @Published private var presetCounts: [Int: Int] = [:]

    /// The free count persists (same key the old `@AppStorage("tasbihFreeCount")` used), because it's
    /// meant to be carried across sittings and run up as high as the user likes.
    @Published private var freeCount: Int {
        didSet { UserDefaults.standard.set(freeCount, forKey: "tasbihFreeCount") }
    }

    private init() {
        freeCount = UserDefaults.standard.integer(forKey: "tasbihFreeCount")
    }

    func binding(for index: Int) -> Binding<Int> {
        if index == Self.freeIndex {
            return Binding(
                get: { self.freeCount },
                set: { self.freeCount = max(0, $0) }
            )
        }
        return Binding(
            get: { self.presetCounts[index, default: 0] },
            set: { self.presetCounts[index] = $0 }
        )
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
                // The Quranic face, like every other screen that shows this same dhikr text. Only the Arabic
                // gets it: a free-count LABEL the user typed is their own text, not Arabic, so it stays in the
                // UI face. `usesCustomArabicFace` is false when the reader picked the Basic font, in which case
                // the rounded system face is correct and the design opt-out must not fire.
                Text(selectedDhikr?.arabicText ?? (freeLabel.isEmpty ? "Other Dhikr" : freeLabel))
                    .font(
                        selectedDhikr != nil && usesCustomArabicFace
                            ? Font.arabic(settings.fontArabic, size: 26, relativeTo: .title3)
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
        #if os(iOS)
        .conditionalGlassEffect(rectangle: true, useColor: 0.12)
        #endif
        // The whole card is still the counter - the buttons are for correcting, not for the counting itself.
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation(.easeOut(duration: 0.15)) {
                counterBinding.wrappedValue += 1
            }
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
                    withAnimation { counter.wrappedValue = count - 1 }
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
                    withAnimation { counter.wrappedValue = count + 1 }
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
