#if os(iOS)
import SwiftUI

struct PlayCustomRangeSheet: View {
    @ObservedObject var settings = Settings.shared

    enum SelectionMode: String, CaseIterable {
        case ayahs, pages
        var title: String { self == .ayahs ? "Ayahs" : "Pages" }
    }

    let surah: Surah
    let initialStartAyah: Int
    let initialEndAyah: Int
    let onPlay: (Int, Int, Int, Int) -> Void
    let onCancel: () -> Void

    @AppStorage("customRangeSelectionMode") private var selectionMode: SelectionMode = .ayahs
    @State private var startAyah: Int
    @State private var endAyah: Int
    @State private var startAyahText: String
    @State private var endAyahText: String
    @State private var repeatPerAyah: Int
    @State private var repeatSection: Int
    @State private var repeatPerAyahText: String
    @State private var repeatSectionText: String
    @AppStorage("customRangeRepeatPerAyah") private var storedRepeatPerAyah = 1
    @AppStorage("customRangeRepeatSection") private var storedRepeatSection = 1
    
    @FocusState private var startAyahFocused: Bool
    @FocusState private var endAyahFocused: Bool
    @FocusState private var repeatPerAyahFocused: Bool
    @FocusState private var repeatSectionFocused: Bool

    /// Per-render memoization for `pageGroups`. The page list only depends on the surah and active
    /// qiraah, but `pageGroups` is read ~12× per body evaluation; without this the all-ayahs scan ran
    /// every time and caused lag while stepping the range on long surahs. A reference box lets the
    /// computed property cache within a render (and recompute when the qiraah key changes) while
    /// staying always-correct - unlike an @State cache, it can never be transiently empty.
    private final class PageGroupsBox {
        var key: String = "\u{0}unset"
        var value: [(page: Int, firstAyah: Int, lastAyah: Int)] = []
    }
    private let pageGroupsBox = PageGroupsBox()

    private static let repeatMin = 1
    private static let repeatMax = 20
    private static let repeatOptions = [1, 2, 3, 5, 10, 15, 20]
    private static let repeatPerAyahStorageKey = "customRangeRepeatPerAyah"
    private static let repeatSectionStorageKey = "customRangeRepeatSection"

    /// End ayah defaults to the ayah after `startAyah` (one-ayah range when possible); if `startAyah` is the last ayah, end matches start.
    static func defaultEndAyah(startAyah: Int, surah: Surah, displayQiraah: String?) -> Int {
        let maxA = surah.numberOfAyahs(for: displayQiraah)
        return min(max(startAyah + 1, 1), maxA)
    }

    private static func storedRepeatValue(for key: String) -> Int {
        let saved = UserDefaults.standard.object(forKey: key) as? Int ?? repeatMin
        return min(Swift.max(repeatMin, saved), repeatMax)
    }

    private var maxAyah: Int { surah.numberOfAyahs(for: settings.displayQiraahForArabic) }

    init(
        surah: Surah,
        initialStartAyah: Int,
        initialEndAyah: Int,
        onPlay: @escaping (Int, Int, Int, Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.surah = surah
        self.initialStartAyah = initialStartAyah
        self.initialEndAyah = initialEndAyah
        self.onPlay = onPlay
        self.onCancel = onCancel
        _startAyah = State(initialValue: initialStartAyah)
        _endAyah = State(initialValue: initialEndAyah)
        _startAyahText = State(initialValue: "\(initialStartAyah)")
        _endAyahText = State(initialValue: "\(initialEndAyah)")
        let savedRepeatPerAyah = Self.storedRepeatValue(for: Self.repeatPerAyahStorageKey)
        let savedRepeatSection = Self.storedRepeatValue(for: Self.repeatSectionStorageKey)
        _repeatPerAyah = State(initialValue: savedRepeatPerAyah)
        _repeatSection = State(initialValue: savedRepeatSection)
        _repeatPerAyahText = State(initialValue: "\(savedRepeatPerAyah)")
        _repeatSectionText = State(initialValue: "\(savedRepeatSection)")
    }

    private var canPlay: Bool {
        startAyah >= 1 && endAyah <= maxAyah && startAyah <= endAyah
    }

    private func clampRangeToMaxAyah() {
        let m = maxAyah
        if endAyah > m { endAyah = m; endAyahText = "\(m)" }
        if startAyah > m { startAyah = m; startAyahText = "\(m)" }
        if startAyah < 1 { startAyah = 1; startAyahText = "1" }
        if endAyah < 1 { endAyah = 1; endAyahText = "1" }
        if startAyah > endAyah { endAyah = startAyah; endAyahText = "\(startAyah)" }
    }

    private var ayahCount: Int {
        max(0, endAyah - startAyah + 1)
    }

    /// "Ayah N" plus the mushaf page it falls on (when page data is available),
    /// the page annotated with its position within this surah, e.g. "Page 102 (3)".
    private func ayahPageLabel(_ ayahID: Int) -> String {
        if hasPageData, let page = pageNumber(forAyah: ayahID) {
            return "Ayah \(ayahID) · \(mushafPageLabel(forAbsolutePage: page, in: surah))"
        }
        return "Ayah \(ayahID)"
    }

    /// Mushaf pages within this surah (clamped to the active qiraah), each mapped to its first/last ayah.
    /// Ordered by page number. Memoized per render via `pageGroupsBox`, keyed on the active qiraah.
    private var pageGroups: [(page: Int, firstAyah: Int, lastAyah: Int)] {
        let key = settings.displayQiraahForArabic ?? ""
        if pageGroupsBox.key == key { return pageGroupsBox.value }

        var bounds: [Int: (first: Int, last: Int)] = [:]
        var order: [Int] = []
        let m = maxAyah
        for ayah in surah.ayahs where ayah.id <= m {
            guard let page = ayah.page else { continue }
            if let existing = bounds[page] {
                bounds[page] = (first: Swift.min(existing.first, ayah.id), last: Swift.max(existing.last, ayah.id))
            } else {
                bounds[page] = (first: ayah.id, last: ayah.id)
                order.append(page)
            }
        }
        let groups = order.sorted().compactMap { page -> (page: Int, firstAyah: Int, lastAyah: Int)? in
            guard let b = bounds[page] else { return nil }
            return (page: page, firstAyah: b.first, lastAyah: b.last)
        }
        pageGroupsBox.key = key
        pageGroupsBox.value = groups
        return groups
    }

    /// True when we have any page data for this surah (drives whether the Ayahs/Pages toggle is shown).
    private var hasPageData: Bool { !pageGroups.isEmpty }

    /// True when this surah spans more than one mushaf page (drives the page-snap helpers in Ayahs mode).
    private var hasMultiplePages: Bool { pageGroups.count > 1 }

    /// Index into `pageGroups` of the page containing the given ayah (falls back to the nearest preceding page).
    private func pageIndex(containing ayah: Int) -> Int? {
        let groups = pageGroups
        if let idx = groups.firstIndex(where: { ayah >= $0.firstAyah && ayah <= $0.lastAyah }) {
            return idx
        }
        return groups.lastIndex(where: { $0.firstAyah <= ayah }) ?? (groups.isEmpty ? nil : 0)
    }

    private var fromPageIndex: Int { pageIndex(containing: startAyah) ?? 0 }
    private var toPageIndex: Int { pageIndex(containing: endAyah) ?? fromPageIndex }

    /// Mushaf page number that the given ayah falls on, if known.
    private func pageNumber(forAyah ayah: Int) -> Int? {
        guard let idx = pageIndex(containing: ayah) else { return nil }
        return pageGroups[idx].page
    }

    /// True when the start ayah is already the first ayah of its page (so "Start of page" would be a no-op).
    private var startAtPageStart: Bool {
        guard let idx = pageIndex(containing: startAyah) else { return true }
        return startAyah <= pageGroups[idx].firstAyah
    }

    /// True when the end ayah is already the last ayah of its page (so "End of page" would be a no-op).
    private var endAtPageEnd: Bool {
        guard let idx = pageIndex(containing: endAyah) else { return true }
        return endAyah >= pageGroups[idx].lastAyah
    }

    /// Sets the start of the range to the first ayah of `pageGroups[index]` (clamped so start never passes the end page).
    private func setFromPage(to index: Int) {
        let groups = pageGroups
        let clamped = min(Swift.max(0, index), toPageIndex)
        guard groups.indices.contains(clamped) else { return }
        let a = groups[clamped].firstAyah
        withAnimation(.easeInOut(duration: 0.2)) {
            startAyah = a
            startAyahText = "\(a)"
        }
    }

    /// Sets the end of the range to the last ayah of `pageGroups[index]` (clamped so end never passes the start page).
    private func setToPage(to index: Int) {
        let groups = pageGroups
        let clamped = min(Swift.max(fromPageIndex, index), groups.count - 1)
        guard groups.indices.contains(clamped) else { return }
        let a = groups[clamped].lastAyah
        withAnimation(.easeInOut(duration: 0.2)) {
            endAyah = a
            endAyahText = "\(a)"
        }
    }

    /// Expands the current ayah range out to whole-page boundaries - used when switching into Pages mode.
    private func snapRangeToPages() {
        let groups = pageGroups
        guard !groups.isEmpty else { return }
        let lo = min(fromPageIndex, toPageIndex)
        let hi = Swift.max(fromPageIndex, toPageIndex)
        let a = groups[lo].firstAyah
        let b = groups[hi].lastAyah
        startAyah = a; startAyahText = "\(a)"
        endAyah = b; endAyahText = "\(b)"
    }

    /// In Ayahs mode: move the start back to the first ayah of its page.
    private func snapStartToPageStart() {
        guard let idx = pageIndex(containing: startAyah) else { return }
        commitBothAyahFields()
        let a = pageGroups[idx].firstAyah
        withAnimation(.easeInOut(duration: 0.2)) {
            startAyah = a
            startAyahText = "\(a)"
            if endAyah < a { endAyah = a; endAyahText = "\(a)" }
        }
    }

    /// In Ayahs mode: extend the end out to the last ayah of its page.
    private func snapEndToPageEnd() {
        guard let idx = pageIndex(containing: endAyah) else { return }
        commitBothAyahFields()
        let a = pageGroups[idx].lastAyah
        withAnimation(.easeInOut(duration: 0.2)) {
            endAyah = a
            endAyahText = "\(a)"
        }
    }

    private var availableAyahReciters: [Reciter] {
        reciters.filter { $0.qiraah == nil && !$0.ayahIdentifier.isEmpty }
    }

    private var selectedRangeReciter: Reciter? {
        settings.resolvedSelectedReciterIgnoringRandom() ?? availableAyahReciters.first
    }

    private var selectedRangeReciterName: String {
        selectedRangeReciter?.displayNameWithEnglishQiraah ?? settings.reciter
    }

    /// "X ayahs · Y pages" describing the current selection (pages dropped when no page data).
    private var rangeCountSummary: String {
        let pagesInRange = Swift.max(1, toPageIndex - fromPageIndex + 1)
        if hasPageData {
            return "\(ayahCount) ayah\(ayahCount == 1 ? "" : "s") · \(pagesInRange) page\(pagesInRange == 1 ? "" : "s")"
        }
        return "\(ayahCount) ayah\(ayahCount == 1 ? "" : "s")"
    }

    /// Total recitations the range will play: each ayah × its per-ayah repeats × the whole-section repeats.
    private var totalPlayCount: Int {
        ayahCount * repeatPerAyah * repeatSection
    }

    @ViewBuilder
    private func animatedCaption(_ text: String) -> some View {
        let label = Text(text)
            .font(.caption.monospacedDigit())
            .foregroundColor(.secondary)

        if #available(iOS 16.0, watchOS 9.0, *) {
            label.contentTransition(.numericText())
        } else {
            label
        }
    }

    private func sanitizedNumberText(from value: String) -> String {
        value.filter(\.isNumber)
    }

    private func syncAyahTextInput(value: Binding<Int>, text: Binding<String>, isFocused: Bool) {
        let sanitized = sanitizedNumberText(from: text.wrappedValue)
        
        if sanitized != text.wrappedValue {
            text.wrappedValue = sanitized
        }
        
        // While keyboard is active, allow any value (even empty or invalid)
        if isFocused {
            if !sanitized.isEmpty, let parsed = Int(sanitized) {
                value.wrappedValue = parsed
            }
            return
        }
        
        // When keyboard is dismissed, validate and clamp
        guard !sanitized.isEmpty else {
            text.wrappedValue = "\(value.wrappedValue)"
            value.wrappedValue = 1
            return
        }
        
        let parsed = Int(sanitized) ?? 1
        let clamped = min(Swift.max(1, parsed), maxAyah)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
    }

    private func syncRepeatTextInput(value: Binding<Int>, text: Binding<String>, isFocused: Bool) {
        let sanitized = sanitizedNumberText(from: text.wrappedValue)

        if sanitized != text.wrappedValue {
            text.wrappedValue = sanitized
        }

        // While keyboard is active, allow any value (even empty or invalid)
        if isFocused {
            if !sanitized.isEmpty, let parsed = Int(sanitized) {
                value.wrappedValue = parsed
            }
            return
        }
        
        // When keyboard is dismissed, validate and clamp
        guard !sanitized.isEmpty else {
            text.wrappedValue = "\(value.wrappedValue)"
            value.wrappedValue = Self.repeatMin
            return
        }

        let parsed = Int(sanitized) ?? Self.repeatMin
        let clamped = min(Swift.max(Self.repeatMin, parsed), Self.repeatMax)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
    }

    /// Step the START ayah by `delta`. Reads/writes the `startAyah` @State *directly* (not through a passed
    /// Binding). The old generic helper computed `value.wrappedValue + delta` through a Binding parameter,
    /// which in this nested helper context did not reflect the current value - so every tap jumped the range
    /// to the surah's last ayah. Direct @State access steps reliably by one.
    private func stepStart(_ delta: Int) {
        let newValue = min(Swift.max(1, startAyah + delta), maxAyah)
        withAnimation(.easeInOut(duration: 0.15)) {
            startAyah = newValue
            startAyahText = "\(newValue)"
            if endAyah < newValue {
                endAyah = newValue
                endAyahText = "\(newValue)"
            }
        }
    }

    /// Step the END ayah by `delta`. See `stepStart` for why this reads `endAyah` directly.
    private func stepEnd(_ delta: Int) {
        let newValue = min(Swift.max(1, endAyah + delta), maxAyah)
        withAnimation(.easeInOut(duration: 0.15)) {
            endAyah = newValue
            endAyahText = "\(newValue)"
            if startAyah > newValue {
                startAyah = newValue
                startAyahText = "\(newValue)"
            }
        }
    }

    private func adjustRepeatValue(_ value: Binding<Int>, text: Binding<String>, delta: Int) {
        commitRepeatInput(value: value, text: text)

        let newValue = min(Swift.max(Self.repeatMin, value.wrappedValue + delta), Self.repeatMax)
        withAnimation(.easeInOut(duration: 0.15)) {
            value.wrappedValue = newValue
            text.wrappedValue = "\(newValue)"
        }
        persistRepeatValues()
    }

    private func syncRepeatTextInput(value: Binding<Int>, text: Binding<String>) {
        let sanitized = sanitizedNumberText(from: text.wrappedValue)

        if sanitized != text.wrappedValue {
            text.wrappedValue = sanitized
        }

        guard !sanitized.isEmpty else { return }

        let parsed = Int(sanitized) ?? value.wrappedValue
        let clamped = min(Swift.max(Self.repeatMin, parsed), Self.repeatMax)

        if parsed != clamped {
            text.wrappedValue = "\(clamped)"
        }

        if value.wrappedValue != clamped {
            withAnimation(.easeInOut(duration: 0.18)) {
                value.wrappedValue = clamped
            }
        }
    }

    private func clampStoredRepeatValues() {
        let perAyah = min(Swift.max(Self.repeatMin, storedRepeatPerAyah), Self.repeatMax)
        let section = min(Swift.max(Self.repeatMin, storedRepeatSection), Self.repeatMax)
        storedRepeatPerAyah = perAyah
        storedRepeatSection = section
        repeatPerAyah = perAyah
        repeatSection = section
        repeatPerAyahText = "\(perAyah)"
        repeatSectionText = "\(section)"
    }

    private func persistRepeatValues() {
        storedRepeatPerAyah = min(Swift.max(Self.repeatMin, repeatPerAyah), Self.repeatMax)
        storedRepeatSection = min(Swift.max(Self.repeatMin, repeatSection), Self.repeatMax)
    }

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Top: settings-style List. Ayah Range first, then reciter / surah / repeats.
                    List {
                        Section {
                            rangeSectionContent
                        } header: {
                            if selectionMode == .pages && hasPageData {
                                Label("Page Range", systemImage: "doc.text")
                            } else {
                                Label("Ayah Range", systemImage: "number")
                            }
                        }

                        Section {
                            SurahRow(surah: surah, hideInfo: false)
                        }

                        Section {
                            reciterRow
                        } header: {
                            Label("Reciter", systemImage: "person.wave.2.fill")
                        }

                        Section {
                            repeatRow(title: "Each ayah", value: $repeatPerAyah, text: $repeatPerAyahText, isFocused: $repeatPerAyahFocused)
                            repeatRow(title: "Whole section", value: $repeatSection, text: $repeatSectionText, isFocused: $repeatSectionFocused)
                        } header: {
                            Label("Repeats", systemImage: "repeat")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .applyConditionalListStyle(disableNowPlayingInset: true)

                    Divider()

                    // Bottom: compact, read-only first & last ayah preview. Capped at a third of the
                    // height so the top section keeps priority.
                    List {
                        arabicVersesPreview
                    }
                    .applyConditionalListStyle(disableNowPlayingInset: true)
                    .frame(height: geo.size.height / 3)
                }
            }
            .navigationTitle("Custom Ayah Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        settings.hapticFeedback()
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .adaptiveSafeArea(edge: .bottom) {
                playButtonBar
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            clampRangeToMaxAyah()
            clampStoredRepeatValues()
        }
        .onChange(of: settings.displayQiraahForArabic) { _ in
            clampRangeToMaxAyah()
        }
        .onChange(of: settings.reciter) { _ in
            // Let the user switch reciter mid-range: rebuild the running queue from the current ayah.
            if QuranPlayer.shared.isPlayingCustomRange {
                QuranPlayer.shared.reloadCustomRangeWithCurrentReciter()
            }
        }
        .id("\(initialStartAyah)-\(initialEndAyah)")
    }

    private var reciterRow: some View {
        NavigationLink {
            ReciterListView()
                .environmentObject(settings)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.wave.2.fill")
                    .font(.title3)
                    .foregroundStyle(settings.accentColor.color)

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedRangeReciterName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if selectedRangeReciter?.defaultToMinshawi == true {
                        Text("Ayahs default to \(Reciter.minshawiAyahFallbackName).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if let note = selectedRangeReciter?.ayahMurattalStyleNote {
                        Text("Ayahs play in \(note).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var rangeSectionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if selectionMode == .pages && hasPageData {
                pageSelectionSection
            } else {
                ayahSelectionSection
            }

            if hasPageData {
                Picker("Selection mode", selection: $selectionMode.animation(.easeInOut)) {
                    ForEach(SelectionMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectionMode) { mode in
                    settings.hapticFeedback()
                    if mode == .pages { snapRangeToPages() }
                }
            }
        }
        // One animation for the range as a whole, not a separate one per endpoint.
        .animation(.easeInOut, value: [startAyah, endAyah])
    }

    private var ayahSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                rangeField(title: "From", value: $startAyah, text: $startAyahText, isFocused: $startAyahFocused, onStep: stepStart)

                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color(.tertiaryLabel))

                rangeField(title: "To", value: $endAyah, text: $endAyahText, isFocused: $endAyahFocused, onStep: stepEnd)
            }
            .onChange(of: startAyah) { ayah in
                startAyahText = "\(ayah)"
            }
            .onChange(of: endAyah) { ayah in
                endAyahText = "\(endAyah)"
            }

            if hasPageData {
                HStack(spacing: 10) {
                    quickActionButton(title: "Start of page", systemImage: "arrow.up.to.line", enabled: hasMultiplePages && !startAtPageStart) {
                        snapStartToPageStart()
                    }

                    quickActionButton(title: "End of page", systemImage: "arrow.down.to.line", enabled: hasMultiplePages && !endAtPageEnd) {
                        snapEndToPageEnd()
                    }
                }

                perFieldPageLabels
            }

            HStack(spacing: 10) {
                quickActionButton(title: "Go to start", systemImage: "arrow.left.to.line", enabled: startAyah > 1) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        startAyah = 1
                        startAyahText = "1"
                    }
                }

                quickActionButton(title: "Go to end", systemImage: "arrow.right.to.line", enabled: endAyah < maxAyah) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        endAyah = maxAyah
                        endAyahText = "\(maxAyah)"
                    }
                }
            }

            quickActionButton(title: "Whole surah (1–\(maxAyah))", systemImage: "doc.text.fill", prominent: true, enabled: !(startAyah == 1 && endAyah == maxAyah)) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    startAyah = 1
                    endAyah = maxAyah
                    startAyahText = "1"
                    endAyahText = "\(maxAyah)"
                }
            }
        }
    }

    /// The mushaf page of the From / To ayah, centered directly under each big ayah field.
    private var perFieldPageLabels: some View {
        HStack(spacing: 12) {
            pageLabelColumn(forAyah: startAyah)

            Image(systemName: "arrow.right")
                .font(.subheadline.weight(.medium))
                .hidden()

            pageLabelColumn(forAyah: endAyah)
        }
    }

    private func pageLabelColumn(forAyah ayah: Int) -> some View {
        Text(pageNumber(forAyah: ayah).map { mushafPageLabel(forAbsolutePage: $0, in: surah) } ?? " ")
            .font(.caption)
            .foregroundColor(Color(.tertiaryLabel))
            .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var pageSelectionSection: some View {
        let groups = pageGroups
        let fromIdx = fromPageIndex
        let toIdx = toPageIndex

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                pageField(
                    title: "From page",
                    pageNumber: groups.indices.contains(fromIdx) ? groups[fromIdx].page : nil,
                    canDecrement: fromIdx > 0,
                    canIncrement: fromIdx < toIdx,
                    onDecrement: { setFromPage(to: fromIdx - 1) },
                    onIncrement: { setFromPage(to: fromIdx + 1) }
                )

                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color(.tertiaryLabel))

                pageField(
                    title: "To page",
                    pageNumber: groups.indices.contains(toIdx) ? groups[toIdx].page : nil,
                    canDecrement: toIdx > fromIdx,
                    canIncrement: toIdx < groups.count - 1,
                    onDecrement: { setToPage(to: toIdx - 1) },
                    onIncrement: { setToPage(to: toIdx + 1) }
                )
            }

            HStack(spacing: 10) {
                quickActionButton(title: "First page", systemImage: "arrow.left.to.line", enabled: fromIdx > 0) {
                    setFromPage(to: 0)
                }

                quickActionButton(title: "Last page", systemImage: "arrow.right.to.line", enabled: toIdx < groups.count - 1) {
                    setToPage(to: groups.count - 1)
                }
            }

            quickActionButton(title: "All pages (\(groups.count))", systemImage: "doc.text.fill", prominent: true, enabled: !(fromIdx == 0 && toIdx == groups.count - 1)) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    startAyah = 1
                    endAyah = maxAyah
                    startAyahText = "1"
                    endAyahText = "\(maxAyah)"
                }
            }
        }
    }

    private func quickActionButton(title: String, systemImage: String, prominent: Bool = false, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        // onTapGesture (not Button): these are used in pairs within one List row (e.g. Go to start / Go to
        // end), and two Buttons in a single row share one tap target. Scoped contentShape keeps them separate.
        let tint = enabled ? settings.accentColor.color : Color(UIColor.tertiaryLabel)
        return Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, prominent ? 12 : 10)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: prominent ? 16 : 14, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture {
                guard enabled else { return }
                settings.hapticFeedback()
                action()
            }
    }

    private func pageField(title: String, pageNumber: Int?, canDecrement: Bool, canIncrement: Bool, onDecrement: @escaping () -> Void, onIncrement: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            // onTapGesture (not Button) so the two steppers in this single row don't share one tap target.
            HStack(spacing: 0) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canDecrement ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard canDecrement else { return }
                        settings.hapticFeedback()
                        onDecrement()
                    }

                Spacer()

                Text(pageNumber.map { "\($0)" } ?? "- ")
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(minWidth: 44, alignment: .center)

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canIncrement ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard canIncrement else { return }
                        settings.hapticFeedback()
                        onIncrement()
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
    }

    private func rangeField(title: String, value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding, onStep: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            // onTapGesture (not Button): multiple Buttons inside one List/Form row collapse into a single
            // tap target, so tapping minus could fire plus (and vice-versa) - the "it's touching everything"
            // bug. A scoped contentShape + onTapGesture per icon keeps each hit area separate.
            HStack(spacing: 0) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(value.wrappedValue > 1 ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard value.wrappedValue > 1 else { return }
                        settings.hapticFeedback()
                        onStep(-1)
                    }

                Spacer()

                TextField("", text: text)
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 44, alignment: .center)
                    .focused(isFocused)
                    .onChange(of: text.wrappedValue) { _ in
                        syncAyahTextInput(value: value, text: text, isFocused: isFocused.wrappedValue)
                    }
                    .onChange(of: isFocused.wrappedValue) { newValue in
                        // When keyboard dismisses (newValue = false), validate both fields together
                        if !newValue {
                            commitBothAyahFields()
                        }
                    }
                    .onSubmit {
                        commitBothAyahFields()
                    }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(value.wrappedValue < maxAyah ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard value.wrappedValue < maxAyah else { return }
                        settings.hapticFeedback()
                        onStep(1)
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
    }

    private func commitAyahInput(value: Binding<Int>, text: Binding<String>, max: Int, onChange: @escaping (Int) -> Void) {
        let parsed = Int(text.wrappedValue.trimmingCharacters(in: .whitespaces)) ?? value.wrappedValue
        let clamped = min(Swift.max(1, parsed), max)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
        onChange(clamped)
    }

    private func commitBothAyahFields() {
        let s = Int(startAyahText.trimmingCharacters(in: .whitespaces)) ?? startAyah
        let e = Int(endAyahText.trimmingCharacters(in: .whitespaces)) ?? endAyah
        
        // Clamp to 1...maxAyah (handles negatives and out-of-range)
        let clampedStart = min(Swift.max(1, s), maxAyah)
        let clampedEnd = min(Swift.max(1, e), maxAyah)
        
        // Ensure start <= end (if not, swap to make valid range)
        let from = min(clampedStart, clampedEnd)
        let to = Swift.max(clampedStart, clampedEnd)
        
        startAyah = from
        endAyah = to
        startAyahText = "\(from)"
        endAyahText = "\(to)"
        
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    /// Compact, read-only preview card pinned above the Play button: a summary line (count, repeats,
    /// total plays) followed by the first & last ayah. Line-limited (no minimum scale factor) so it
    /// stays small regardless of ayah length.
    private var arabicVersesPreview: some View {
        Group {
            if let first = surah.ayahs.first(where: { $0.id == startAyah }),
               let last = surah.ayahs.first(where: { $0.id == endAyah }) {
                VStack(alignment: .leading, spacing: 12) {
                    versePreviewRow(label: ayahPageLabel(startAyah), ayah: first)

                    if startAyah != endAyah {
                        versePreviewRow(label: ayahPageLabel(endAyah), ayah: last)
                    }
                }
                
                previewSummaryHeader
            }
        }
        // One animation keyed on the whole selection, not four stacked modifiers.
        .animation(.easeInOut, value: [startAyah, endAyah, repeatPerAyah, repeatSection])
    }

    /// Range count + repeats on the left, a bold "total plays" badge on the right.
    private var previewSummaryHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                animatedCaption(rangeCountSummary)
                animatedCaption("Each ayah ×\(repeatPerAyah) · Section ×\(repeatSection)")
            }

            Spacer(minLength: 8)

            VStack(spacing: 0) {
                totalPlaysText
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundColor(.white)
                
                Text("plays")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(settings.accentColor.color)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private var totalPlaysText: some View {
        let label = Text("\(totalPlayCount)×")
        if #available(iOS 16.0, watchOS 9.0, *) {
            label.contentTransition(.numericText())
        } else {
            label
        }
    }

    private func versePreviewRow(label: String, ayah: Ayah) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(Color(.tertiaryLabel))

            Text(ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic))
                .font(Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func repeatRow(title: String, value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.repeatOptions, id: \.self) { n in
                            Text("\(n)×")
                                .font(.subheadline.weight(value.wrappedValue == n ? .semibold : .regular))
                                .foregroundColor(value.wrappedValue == n ? .white : .primary)
                                .padding(8)
                                .background(
                                    value.wrappedValue == n
                                        ? settings.accentColor.color
                                        : Color(UIColor.tertiarySystemFill)
                                )
                                .clipShape(Capsule())
                                .contentShape(Capsule())
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    withAnimation {
                                        value.wrappedValue = n
                                        text.wrappedValue = "\(n)"
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity)

                repeatStepper(value: value, text: text, isFocused: isFocused)
            }
        }
        .onChange(of: value.wrappedValue) { newValue in
            text.wrappedValue = "\(newValue)"
            persistRepeatValues()
        }
    }

    private func repeatStepper(value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "minus.circle.fill")
                .font(.body)
                .foregroundStyle(value.wrappedValue > Self.repeatMin ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                .contentShape(Rectangle())
                .onTapGesture {
                    guard value.wrappedValue > Self.repeatMin else { return }
                    settings.hapticFeedback()
                    adjustRepeatValue(value, text: text, delta: -1)
                }

            TextField("", text: text)
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 32, alignment: .center)
                .focused(isFocused)
                .onChange(of: text.wrappedValue) { _ in
                    syncRepeatTextInput(value: value, text: text, isFocused: isFocused.wrappedValue)
                }
                .onChange(of: isFocused.wrappedValue) { newValue in
                    // When keyboard dismisses (newValue = false), validate
                    if !newValue {
                        commitAllRepeatFields()
                    }
                }
                .onSubmit { commitAllRepeatFields() }

            Image(systemName: "plus.circle.fill")
                .font(.body)
                .foregroundStyle(value.wrappedValue < Self.repeatMax ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                .contentShape(Rectangle())
                .onTapGesture {
                    guard value.wrappedValue < Self.repeatMax else { return }
                    settings.hapticFeedback()
                    adjustRepeatValue(value, text: text, delta: 1)
                }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }

    private func commitRepeatInput(value: Binding<Int>, text: Binding<String>) {
        let parsed = Int(text.wrappedValue.trimmingCharacters(in: .whitespaces)) ?? value.wrappedValue
        let clamped = min(Swift.max(Self.repeatMin, parsed), Self.repeatMax)
        value.wrappedValue = clamped
        text.wrappedValue = "\(clamped)"
        persistRepeatValues()
    }

    private func commitAllRepeatFields() {
        commitRepeatInput(value: $repeatPerAyah, text: $repeatPerAyahText)
        commitRepeatInput(value: $repeatSection, text: $repeatSectionText)
    }

    private var playButtonBar: some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            Button {
                settings.hapticFeedback()
                commitBothAyahFields()
                commitAllRepeatFields()
                onPlay(startAyah, endAyah, repeatPerAyah, repeatSection)
                onCancel()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Play range")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundColor(.white)
                .conditionalGlassEffect(
                    useColor: 0.35,
                    customTint: canPlay ? settings.accentColor.color : .secondary
                )
                .contentShape(Rectangle())
            }
            .disabled(!canPlay)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        PlayCustomRangeSheet(
            surah: AlIslamPreviewData.surah,
            initialStartAyah: 1,
            initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                startAyah: 1,
                surah: AlIslamPreviewData.surah,
                displayQiraah: AlIslamPreviewData.settings.displayQiraahForArabic
            ),
            onPlay: { _, _, _, _ in },
            onCancel: {}
        )
    }
}
#endif
