import SwiftUI

struct TasbihView: View {
    @ObservedObject var settings = Settings.shared

    @State private var counters: [Int: Int] = Self.initialCounters
    @State private var selectedDhikrIndex: Int = Self.freeDhikrIndex

    /// A free count for dhikr that isn't on the list. Unlike the preset counters — which are per-session
    /// scratch — this one persists, because it's meant to be carried across sittings and run up as high as
    /// the user likes.
    @AppStorage("tasbihFreeCount") private var freeCount = 0
    @AppStorage("tasbihFreeLabel") private var freeLabel = ""
    /// How many counts complete one turn of the ring. Purely cosmetic; the count itself never wraps.
    @AppStorage("tasbihFreeCycle") private var freeCycle = 33

    /// Sentinel for "the free counter is selected" rather than a row of `tasbihData`.
    private static let freeDhikrIndex = -1
    private static let cycleChoices = [33, 99, 100, 500, 1000]

    private let tasbihData = commonDhikrItems
    private static let initialCounters = Dictionary(uniqueKeysWithValues: commonDhikrItems.indices.map { ($0, 0) })

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
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                activeTasbihCard
            }
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
        Section(header: Text("FREE COUNT"), footer: Text("Count any dhikr of your own. The count is kept between visits and has no limit.")) {
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

    /// The ring is the only thing a cycle length changes — a full turn every N counts, as a visual marker.
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

        return ZStack {
            ProgressCircleView(progress: counterBinding.wrappedValue, cycle: selectedDhikr == nil ? freeCycle : 33)
                .scaledToFit()
                .frame(maxWidth: 185, maxHeight: 185)

            VStack(alignment: .center, spacing: 5) {
                Text(selectedDhikr?.arabicText ?? (freeLabel.isEmpty ? "Free Count" : freeLabel))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(settings.accentColor.color)
                    .multilineTextAlignment(.center)

                Text(selectedDhikr?.transliteration ?? "Tap to count")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                CounterView(counter: counterBinding)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .contentShape(Rectangle())
        #if os(iOS)
        .conditionalGlassEffect(rectangle: true, useColor: 0.12)
        #endif
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation {
                counterBinding.wrappedValue += 1
            }
        }
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
                .font(.headline)
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
