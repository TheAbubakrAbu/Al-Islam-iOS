import SwiftUI

struct TasbihView: View {
    @ObservedObject var settings = Settings.shared

    // Empty by default with `counters[i, default: 0]` reads everywhere, so constructing this view touches no
    // data at all. The old `Self.initialCounters` default forced the `commonDhikrItems` global (and its
    // per-item diacritic-folded search blobs) to initialize the moment the STRUCT was built - and on watchOS
    // the Islam tab builds this struct eagerly for its NavigationLink on every body pass.
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @State private var counters: [Int: Int] = [:]
    @State private var selectedDhikrIndex: Int = Self.freeDhikrIndex

    /// A free count for dhikr that isn't on the list. Unlike the preset counters - which are per-session
    /// scratch - this one persists, because it's meant to be carried across sittings and run up as high as
    /// the user likes.
    @AppStorage("tasbihFreeCount") private var freeCount = 0
    @AppStorage("tasbihFreeLabel") private var freeLabel = ""
    /// How many counts complete one turn of the ring. Purely cosmetic; the count itself never wraps.
    @AppStorage("tasbihFreeCycle") private var freeCycle = 33

    /// Sentinel for "the free counter is selected" rather than a row of `tasbihData`.
    private static let freeDhikrIndex = -1
    private static let cycleChoices = [33, 99, 100, 500, 1000]

    /// Computed, not stored: a stored `let` would also force `commonDhikrItems` at struct-construction time.
    private var tasbihData: [CommonDhikr] { commonDhikrItems }

    private var usesCustomArabicFace: Bool { settings.islamUsesCustomArabicFace }

    private var isFreeDhikrSelected: Bool { selectedDhikrIndex == Self.freeDhikrIndex }

    private func binding(for index: Int) -> Binding<Int> {
        if index == Self.freeDhikrIndex {
            return Binding(get: { freeCount }, set: { freeCount = max(0, $0) })
        }
        return Binding(
            get: { counters[index, default: 0] },
            set: { counters[index] = $0 }
        )
    }

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
        // Apple Music-style: the tasbih card minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                activeTasbihCard
            }
            .minimizedBarStyle(barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGroupedBackground))
        }
        #endif
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle("Tasbih Counter")
    }

    /// A counter with no dhikr attached: name it whatever you're reciting, or nothing at all, and count.
    private var freeDhikrSection: some View {
        Section(header: Text("FREE COUNT"), footer: Text("The count is kept between visits and has no limit.")) {
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
                        TextField("Your own dhikr", text: $freeLabel)
                            .font(.headline)
                            .foregroundColor(settings.accentColor.color)
                            #if os(iOS)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            #endif

                        cyclePicker
                    }

                    Spacer()

                    TasbihCounterControls(counter: binding(for: Self.freeDhikrIndex))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isFreeDhikrSelected else { return }
                withAnimation {
                    settings.hapticFeedback()
                    selectedDhikrIndex = Self.freeDhikrIndex
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

            TasbihRow(tasbih: tasbihData[index], counter: binding(for: index))
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

    private var activeTasbihCard: some View {
        // `selectedDhikrIndex` is the free-count sentinel or a real row; never an out-of-range index.
        let selectedDhikr = tasbihData.indices.contains(selectedDhikrIndex) ? tasbihData[selectedDhikrIndex] : nil
        let counterBinding = binding(for: selectedDhikrIndex)
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
                Text(selectedDhikr?.arabicText ?? (freeLabel.isEmpty ? "Free Count" : freeLabel))
                    .font(
                        selectedDhikr != nil && usesCustomArabicFace
                            ? .custom(settings.fontArabic, size: 26, relativeTo: .title3)
                            : .title3.weight(.bold)
                    )
                    .arabicFontDesign(custom: selectedDhikr != nil && usesCustomArabicFace)
                    .foregroundColor(settings.accentColor.color)
                    .multilineTextAlignment(.center)
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
                ProgressCircleView(progress: count, cycle: cycle)
                    .scaledToFit()
                    .frame(maxWidth: 170, maxHeight: 170)

                VStack(spacing: 0) {
                    Text("\(count)")
                        .font(.system(size: 44, weight: .semibold))
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
        .padding(.vertical, 14)
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
    @ObservedObject var settings = Settings.shared

    var body: some View {
        let turn = max(cycle, 1)
        let progressFraction = CGFloat(progress % turn) / CGFloat(turn)
        return ZStack {
            Circle()
                .stroke(lineWidth: 15)
                .opacity(0.3)
                .foregroundColor(settings.accentColor.color)

            Circle()
                .trim(from: 0.0, to: progressFraction)
                .stroke(settings.accentColor.angularGradient,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
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
    @Binding var counter: Int

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
                .font(
                    settings.islamUsesCustomArabicFace
                        ? .custom(settings.fontArabic, size: 20, relativeTo: .headline)
                        : .headline
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .foregroundColor(settings.accentColor.color)

            Text(tasbih.transliteration)
                .font(.subheadline)
                .foregroundColor(.primary)

            Text(tasbih.translation)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var counterControls: some View {
        TasbihCounterControls(counter: $counter)
    }
}

/// The minus / count / plus / reset stack. Shared by the preset dhikr rows and the free-count row so the two
/// can't drift apart on what a tap does.
struct TasbihCounterControls: View {
    @ObservedObject var settings = Settings.shared

    @Binding var counter: Int

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "minus.circle")
                    .foregroundColor(counter == 0 ? .secondary : settings.accentColor.color)
                    .padding(6)
                    .conditionalGlassEffect()
                    .onTapGesture {
                        if counter > 0 {
                            settings.hapticFeedback()
                            withAnimation { counter -= 1 }
                        }
                    }
                    .disabled(counter <= 0)

                Text("\(counter)")
                    .font(.subheadline)
                    .monospacedDigit()

                Image(systemName: "plus.circle")
                    .foregroundColor(settings.accentColor.color)
                    .padding(6)
                    .conditionalGlassEffect()
                    .onTapGesture {
                        settings.hapticFeedback()
                        withAnimation { counter += 1 }
                    }
            }

            Text("Reset")
                .font(.subheadline)
                .padding(6)
                .conditionalGlassEffect()
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation { counter = 0 }
                }
                .disabled(counter <= 0)
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        TasbihView()
    }
}
