#if os(iOS)
import SwiftUI

/// "Play Custom Range": a span of one surah's ayahs (or of its mushaf pages), how often each ayah
/// and the whole range repeat, the reciter, and Play.
///
/// One list, top to bottom (Abu, 2026-10-19: the old layered layout, with seven range buttons, a
/// chip row per repeat and a split preview pane, was "too spread out, too hard to read, too
/// confusing"): the range card, the two repeat rows and the forever switch, the reciter, then every
/// ayah the range will play. The count and the play total sit over the Play button, so they stay on
/// screen while the list scrolls.
struct PlayCustomRangeSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var rangeHistory = CustomRangeHistoryStore.shared
    @Environment(\.appearance) private var appearance

    enum SelectionMode: String, CaseIterable {
        case ayahs, pages
        var title: String { self == .ayahs ? String(localized: "Ayahs") : String(localized: "Pages") }
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
    /// Loop the whole range until stopped (Abu, 2026-09-26: "have an infinite option"). The player
    /// fetches each ayah once and replays the file on every pass (`PlaybackAudioCache`).
    @AppStorage("customRangeRepeatForever") private var repeatForever = false
    /// The preview lists every ayah of the range only on request: its first and last ayah stand for
    /// it until the row under them is tapped (Abu, 2026-10-23: "just show the beginning and last
    /// ayah but I would like an option for preview to see all of them... at the very end"). Every
    /// ayah of a long range pushed the Range card a screen or two down.
    @State private var showsEveryAyah = false

    @FocusState private var startAyahFocused: Bool
    @FocusState private var endAyahFocused: Bool
    @FocusState private var repeatPerAyahFocused: Bool
    @FocusState private var repeatSectionFocused: Bool

    /// Per-render memoization for `pageGroups`. The page list only depends on the surah and active
    /// qiraah, but `pageGroups` is read many times per body evaluation; without this the all-ayahs
    /// scan ran every time and caused lag while stepping the range on long surahs. A reference box
    /// lets the computed property cache within a render (and recompute when the qiraah key changes)
    /// while staying always-correct: unlike an @State cache, it can never be transiently empty.
    private final class PageGroupsBox {
        var key: String = "\u{0}unset"
        var value: [(page: Int, firstAyah: Int, lastAyah: Int)] = []
    }
    private let pageGroupsBox = PageGroupsBox()

    private static let repeatMin = 1
    private static let repeatMax = 20
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

    // MARK: - Range model

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
    /// the page annotated with its position within this surah, e.g. "Page 102 (3/12)".
    private func ayahPageLabel(_ ayahID: Int) -> String {
        if hasPageData, let page = pageNumber(forAyah: ayahID) {
            return String(localized: "Ayah \(ayahID) \u{00B7} \(mushafPageDisplayLabel(forAbsolutePage: page, in: surah))")
        }
        return String(localized: "Ayah \(ayahID)")
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

    /// True when we have any page data for this surah (drives whether the Ayahs/Pages picker is shown).
    private var hasPageData: Bool { !pageGroups.isEmpty }

    /// True when this surah spans more than one mushaf page (drives the Whole Page chip in Ayahs mode).
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
    private var pagesInRange: Int { Swift.max(1, toPageIndex - fromPageIndex + 1) }

    /// Mushaf page number that the given ayah falls on, if known.
    private func pageNumber(forAyah ayah: Int) -> Int? {
        guard let idx = pageIndex(containing: ayah) else { return nil }
        return pageGroups[idx].page
    }

    /// True when the start ayah is already the first ayah of its page.
    private var startAtPageStart: Bool {
        guard let idx = pageIndex(containing: startAyah) else { return true }
        return startAyah <= pageGroups[idx].firstAyah
    }

    /// True when the end ayah is already the last ayah of its page.
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

    /// Expands the current ayah range out to whole-page boundaries: the Whole Page chip, and the
    /// switch into Pages mode.
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

    private func selectWholeSurah() {
        withAnimation(.easeInOut(duration: 0.2)) {
            startAyah = 1
            endAyah = maxAyah
            startAyahText = "1"
            endAyahText = "\(maxAyah)"
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
        let pagesInRange = self.pagesInRange
        let ayahs = ayahCount == 1 ? String(localized: "\(ayahCount) ayah") : String(localized: "\(ayahCount) ayahs")
        if hasPageData {
            let pages = pagesInRange == 1 ? String(localized: "\(pagesInRange) page") : String(localized: "\(pagesInRange) pages")
            return "\(ayahs) \u{00B7} \(pages)"
        }
        return ayahs
    }

    /// Total recitations the range will play: each ayah × its per-ayah repeats × the whole-range repeats.
    private var totalPlayCount: Int {
        // Reported, never trapping: the fields are clamped while typing now, but a product of three
        // typed numbers must not be able to crash a render.
        let perAyah = ayahCount.multipliedReportingOverflow(by: repeatPerAyah)
        let total = perAyah.partialValue.multipliedReportingOverflow(by: repeatSection)
        return perAyah.overflow || total.overflow ? Int.max : total.partialValue
    }

    /// "2 ayahs · 1 page · 4 plays", or "... · Repeats forever": the line over the Play button.
    private var playSummary: String {
        if repeatForever {
            return String(localized: "\(rangeCountSummary) \u{00B7} Repeats forever")
        }
        let total = totalPlayCount
        let plays = total == Int.max ? String(localized: "Too many plays") : (total == 1 ? String(localized: "\(total) play") : String(localized: "\(total) plays"))
        return (rangeCountSummary + JoinSeparator.dot + plays).interfaceParagraph
    }

    /// "Ayahs 1–6", or "Ayah 3" for a range of one: the preview section's title.
    private var previewTitle: String {
        startAyah == endAyah ? String(localized: "Ayah \(startAyah)") : String(localized: "Ayahs \(startAyah)\u{2013}\(endAyah)")
    }

    /// Every ayah the chosen range will actually play, in playback order, clamped to the active
    /// qiraah (an ayah absent from the riwayah's text is skipped by playback too).
    private var rangeAyahs: [Ayah] {
        surah.ayahs.filter {
            $0.id >= startAyah && $0.id <= endAyah
                && $0.existsInQiraah(settings.displayQiraahForArabic, surahID: surah.id)
        }
    }

    /// A range longer than this previews as its two ends over a Show All row.
    private static let previewEndsCount = 2

    /// The rows the preview draws from `ayahs`: all of them while the range is short or expanded,
    /// else its first and last ayah.
    private func previewAyahs(of ayahs: [Ayah]) -> [Ayah] {
        guard !showsEveryAyah, ayahs.count > Self.previewEndsCount,
              let first = ayahs.first, let last = ayahs.last else { return ayahs }
        return [first, last]
    }

    // MARK: - Text fields

    /// A number field's text as the reader sees it, in the locale's digits (١٢ in Arabic), while the
    /// state behind it, which every parse reads, keeps Western digits; typed Arabic-Indic digits fold back.
    private func localizedDigitsField(_ text: Binding<String>) -> Binding<String> {
        Binding(
            get: { text.wrappedValue.localizedDigits },
            set: { text.wrappedValue = $0.normalizingArabicIndicDigitsToWestern }
        )
    }

    private func sanitizedNumberText(from value: String) -> String {
        value.filter(\.isNumber)
    }

    private func syncAyahTextInput(value: Binding<Int>, text: Binding<String>, isFocused: Bool) {
        let sanitized = sanitizedNumberText(from: text.wrappedValue)

        if sanitized != text.wrappedValue {
            text.wrappedValue = sanitized
        }

        // While the keyboard is up the TEXT may say anything, but the value is clamped: a long number
        // typed here fed the range's play count unclamped, and its product overflowed on the next
        // render (Quality Guide C2).
        if isFocused {
            if !sanitized.isEmpty, let parsed = Int(sanitized) {
                value.wrappedValue = min(Swift.max(1, parsed), maxAyah)
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

        // While the keyboard is up the text may say anything; the value is clamped (see above).
        if isFocused {
            if !sanitized.isEmpty, let parsed = Int(sanitized) {
                value.wrappedValue = min(Swift.max(Self.repeatMin, parsed), Self.repeatMax)
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

    /// Step the START ayah by `delta`. Reads/writes the `startAyah` @State directly (not through a passed
    /// Binding): the old generic helper computed `value.wrappedValue + delta` through a Binding parameter,
    /// which in this nested helper context did not reflect the current value, so every tap jumped the
    /// range to the surah's last ayah. Direct @State access steps reliably by one.
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

    private var anyFieldFocused: Bool {
        startAyahFocused || endAyahFocused || repeatPerAyahFocused || repeatSectionFocused
    }

    /// The keyboard's Done: dropping focus runs each field's commit through its focus `onChange`.
    private func endEditing() {
        startAyahFocused = false
        endAyahFocused = false
        repeatPerAyahFocused = false
        repeatSectionFocused = false
    }

    // MARK: - Body

    var body: some View {
        SheetNavigationContainer {
            ScrollViewReader { proxy in
                List {
                    // The ayahs lead (Abu, 2026-10-20: "put the preview at the top"): what the range
                    // will play is the first thing on screen, and it follows the fields as they move.
                    previewSection

                    Section {
                        rangeCard
                    } header: {
                        SectionIconHeader(String(localized: "Range"), icon: "arrow.left.and.right")
                    }

                    Section {
                        repeatRow(title: String(localized: "Each Ayah"), value: $repeatPerAyah, text: $repeatPerAyahText, isFocused: $repeatPerAyahFocused)
                        repeatRow(title: String(localized: "Whole Range"), value: $repeatSection, text: $repeatSectionText, isFocused: $repeatSectionFocused)
                            .disabled(repeatForever)
                            .opacity(repeatForever ? 0.45 : 1)
                        foreverRow
                    } header: {
                        SectionIconHeader(String(localized: "Repeat"), icon: "repeat")
                    }

                    Section {
                        reciterRow
                    } header: {
                        SectionIconHeader(String(localized: "Reciter"), icon: "person.wave.2")
                    }

                    // The ranges played from here before, newest first: one tap plays one again.
                    if !rangeHistory.items.isEmpty {
                        Section {
                            ForEach(rangeHistory.items) { item in
                                historyRow(item)
                                    .id(item.id)
                            }
                            .onDelete { offsets in
                                rangeHistory.remove(atOffsets: offsets)
                            }
                        } header: {
                            SectionIconHeader(String(localized: "Recent Ranges"), icon: "clock.arrow.circlepath", accentTitle: true)
                        }
                    }
                }
                .applyConditionalListStyle(disableNowPlayingInset: true)
                .onAppear {
                    #if DEBUG
                    // Headless verification: "-customRangeScrollToEnd" scrolls the list to its last
                    // Recent Ranges row a beat after the sheet opens (nothing can swipe the simulator).
                    if ProcessInfo.processInfo.arguments.contains("-customRangeScrollToEnd"),
                       let last = rangeHistory.items.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                    #endif
                }
                .dismissKeyboardOnScroll()
                .navigationTitle("Custom Range")
                .navigationBarTitleDisplayMode(.inline)
                .sheetDismissToolbar()
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        if anyFieldFocused {
                            Spacer(minLength: 0)
                            Button("Done") { endEditing() }
                        }
                    }
                }
                .adaptiveSafeArea(edge: .bottom) {
                    playBar
                }
            }
        }
        // Full height first: the list is long, and the half height showed the range card alone.
        .smallMediumSheetPresentation(startLarge: true)
        .onAppear {
            clampRangeToMaxAyah()
            clampStoredRepeatValues()
            // Pages mode remembered from last time: the fields show whole pages, so the range the
            // host handed over (one or two ayahs) widens to them at once, as a mode switch does.
            if selectionMode == .pages && hasPageData { snapRangeToPages() }
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

    // MARK: - Range card

    /// Ayahs | Pages, the From → To fields with their page (or ayah span) under each, and the chips
    /// that widen the range to whole pages or the whole surah. One row of the list.
    private var rangeCard: some View {
        VStack(spacing: 14) {
            if hasPageData {
                Picker("Range by", selection: $selectionMode) {
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

            if selectionMode == .pages && hasPageData {
                pageFields
            } else {
                ayahFields
            }

            quickActions
        }
        .padding(.vertical, 4)
        // One animation for the range as a whole, not a separate one per endpoint.
        .animation(.easeInOut, value: [startAyah, endAyah])
    }

    private var arrow: some View {
        Image(systemName: "arrow.forward")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.secondary)
    }

    /// The small line under a From / To field: the page the ayah is on, or the ayahs a page spans.
    private func fieldCaption(_ text: String) -> some View {
        Text(text)
            .font(.caption.monospacedDigit())
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var ayahFields: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                rangeField(title: String(localized: "From"), value: $startAyah, text: $startAyahText, isFocused: $startAyahFocused, onStep: stepStart)
                arrow
                rangeField(title: String(localized: "To"), value: $endAyah, text: $endAyahText, isFocused: $endAyahFocused, onStep: stepEnd)
            }
            .onChange(of: startAyah) { ayah in
                startAyahText = "\(ayah)"
            }
            .onChange(of: endAyah) { ayah in
                endAyahText = "\(ayah)"
            }

            if hasPageData {
                HStack(spacing: 12) {
                    fieldCaption(pageCaption(forAyah: startAyah))
                    arrow.hidden()
                    fieldCaption(pageCaption(forAyah: endAyah))
                }
            }
        }
    }

    private func pageCaption(forAyah ayah: Int) -> String {
        pageNumber(forAyah: ayah).map { mushafPageDisplayLabel(forAbsolutePage: $0, in: surah) } ?? " "
    }

    /// "Ayahs 1–12" (or "Ayah 5") for the page at `index` of `pageGroups`.
    private func ayahSpanCaption(forPageIndex index: Int) -> String {
        let groups = pageGroups
        guard groups.indices.contains(index) else { return " " }
        let group = groups[index]
        if group.firstAyah == group.lastAyah { return String(localized: "Ayah \(group.firstAyah)") }
        return String(localized: "Ayahs \(group.firstAyah)\u{2013}\(group.lastAyah)")
    }

    @ViewBuilder
    private var pageFields: some View {
        let groups = pageGroups
        let fromIdx = fromPageIndex
        let toIdx = toPageIndex

        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                pageField(
                    title: String(localized: "From Page"),
                    pageNumber: groups.indices.contains(fromIdx) ? groups[fromIdx].page : nil,
                    canDecrement: fromIdx > 0,
                    canIncrement: fromIdx < toIdx,
                    onDecrement: { setFromPage(to: fromIdx - 1) },
                    onIncrement: { setFromPage(to: fromIdx + 1) }
                )
                arrow
                pageField(
                    title: String(localized: "To Page"),
                    pageNumber: groups.indices.contains(toIdx) ? groups[toIdx].page : nil,
                    canDecrement: toIdx > fromIdx,
                    canIncrement: toIdx < groups.count - 1,
                    onDecrement: { setToPage(to: toIdx - 1) },
                    onIncrement: { setToPage(to: toIdx + 1) }
                )
            }

            HStack(spacing: 12) {
                fieldCaption(ayahSpanCaption(forPageIndex: fromIdx))
                arrow.hidden()
                fieldCaption(ayahSpanCaption(forPageIndex: toIdx))
            }
        }
    }

    /// Whole Page(s) + Whole Surah in Ayahs mode, All Pages in Pages mode: the one row of shortcuts
    /// (the old Start of page / End of page / Go to start / Go to end pairs folded into these).
    @ViewBuilder
    private var quickActions: some View {
        if selectionMode == .pages && hasPageData {
            let groups = pageGroups
            chip(String(localized: "All Pages (\(groups.count))"), systemImage: "book.closed",
                 enabled: !(fromPageIndex == 0 && toPageIndex == groups.count - 1)) {
                selectWholeSurah()
            }
        } else {
            HStack(spacing: 10) {
                if hasMultiplePages {
                    chip(pagesInRange > 1 ? String(localized: "Whole Pages") : String(localized: "Whole Page"), systemImage: "doc.text",
                         enabled: !(startAtPageStart && endAtPageEnd)) {
                        commitBothAyahFields()
                        withAnimation(.easeInOut(duration: 0.2)) { snapRangeToPages() }
                    }
                }

                chip(String(localized: "Whole Surah"), systemImage: "book.closed",
                     enabled: !(startAyah == 1 && endAyah == maxAyah)) {
                    commitBothAyahFields()
                    selectWholeSurah()
                }
            }
        }
    }

    private func chip(_ title: String, systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        // onTapGesture (not Button): two of these share one List row, and two Buttons in a single row
        // share one tap target. A scoped contentShape keeps them separate.
        let tint = enabled ? settings.accentColor.color : Color(UIColor.tertiaryLabel)
        return Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .foregroundColor(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
            .contentShape(Capsule())
            .onTapGesture {
                guard enabled else { return }
                settings.hapticFeedback()
                action()
            }
            .accessibilityAddTraits(.isButton)
    }

    private func pageField(title: String, pageNumber: Int?, canDecrement: Bool, canIncrement: Bool, onDecrement: @escaping () -> Void, onIncrement: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
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
                    .accessibilityLabel("Previous page")

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
                    .accessibilityLabel("Next page")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
    }

    private func rangeField(title: String, value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding, onStep: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            // onTapGesture (not Button): multiple Buttons inside one List row collapse into a single
            // tap target, so tapping minus could fire plus (and vice-versa). A scoped contentShape +
            // onTapGesture per icon keeps each hit area separate.
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
                    .accessibilityLabel("Previous ayah")

                Spacer()

                TextField("", text: localizedDigitsField(text))
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
                    .accessibilityLabel("\(title) ayah")

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
                    .accessibilityLabel("Next ayah")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Repeat rows

    /// "Each Ayah   [− 2× +]": the title on the left, a stepper you can also type into on the right.
    private func repeatRow(title: String, value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer(minLength: 8)

            repeatStepper(value: value, text: text, isFocused: isFocused)
        }
        .onChange(of: value.wrappedValue) { newValue in
            text.wrappedValue = "\(newValue)"
            persistRepeatValues()
        }
    }

    private func repeatStepper(value: Binding<Int>, text: Binding<String>, isFocused: FocusState<Bool>.Binding) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "minus.circle.fill")
                .font(.title3)
                .foregroundStyle(value.wrappedValue > Self.repeatMin ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                .contentShape(Rectangle())
                .onTapGesture {
                    guard value.wrappedValue > Self.repeatMin else { return }
                    settings.hapticFeedback()
                    adjustRepeatValue(value, text: text, delta: -1)
                }
                .accessibilityLabel("Fewer")

            HStack(spacing: 1) {
                TextField("", text: localizedDigitsField(text))
                    .font(.body.monospacedDigit().weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(width: 30, alignment: .trailing)
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

                Text("\u{00D7}")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(value.wrappedValue) times")

            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(value.wrappedValue < Self.repeatMax ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                .contentShape(Rectangle())
                .onTapGesture {
                    guard value.wrappedValue < Self.repeatMax else { return }
                    settings.hapticFeedback()
                    adjustRepeatValue(value, text: text, delta: 1)
                }
                .accessibilityLabel("More")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(Capsule())
        .contentShape(Capsule())
    }

    private var foreverRow: some View {
        Toggle(isOn: Binding(
            get: { repeatForever },
            set: { newValue in
                settings.hapticFeedback()
                withAnimation(.easeInOut) { repeatForever = newValue }
            }
        )) {
            Label("Repeat Forever", systemImage: "infinity")
                .font(.body)
        }
        .tint(settings.accentColor.color)
    }

    // MARK: - Reciter

    private var reciterRow: some View {
        NavigationLink {
            LazyDestination {
                ReciterListView()
                    .environmentObject(settings)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.wave.2.fill")
                    .font(.body)
                    .foregroundStyle(settings.accentColor.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedRangeReciterName)
                        .font(.body)
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

    // MARK: - Preview

    /// The first and last ayah of the range, or every ayah once the row under them asks for it.
    @ViewBuilder
    private var previewSection: some View {
        let ayahs = rangeAyahs
        Section {
            ForEach(previewAyahs(of: ayahs), id: \.id) { ayah in
                previewRow(ayah)
            }
            if ayahs.count > Self.previewEndsCount {
                previewToggleRow(count: ayahs.count)
            }
        } header: {
            // A plain String here is drawn verbatim, so it goes through the catalog; the Arabic
            // interface names the surah in Arabic.
            SectionIconHeader(
                String(localized: "\(surah.displayName) \u{00B7} \(previewTitle)"),
                icon: "book.closed"
            )
        }
    }

    /// Under the two ends of a longer range: shows every ayah in place, and folds them back.
    private func previewToggleRow(count: Int) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.25)) { showsEveryAyah.toggle() }
        } label: {
            Label(showsEveryAyah ? "Show First and Last Only" : "Show All \(count) Ayahs",
                  systemImage: showsEveryAyah ? "chevron.up" : "chevron.down")
                .font(.subheadline.weight(.medium))
                .foregroundColor(settings.accentColor.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("customRangePreviewToggle")
    }

    /// One ayah the range will play: its label (number + mushaf page) over the full Arabic text.
    private func previewRow(_ ayah: Ayah) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ayahPageLabel(ayah.id))
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            Text(ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic))
                .font(Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.primary)
                // Its ideal height, never a line: a List row sometimes offered the Quran face one
                // line and cut a long ayah off with an ellipsis.
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .trailing)
                // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Recent ranges

    /// One range played from this sheet before: its surah and span over how it repeated, and when.
    /// A tap plays it again exactly as it was and closes the sheet, the one-tap play of the Quran
    /// tab's Last Listened rows; a swipe (or the context menu) forgets it.
    private func historyRow(_ item: CustomRangeHistoryItem) -> some View {
        Button {
            settings.hapticFeedback()
            playHistoryItem(item)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title.localizedDigits)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .lineLimit(1)

                    Text(item.caption)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 8)

                Text(formatCompactHistoryTimestamp(item.timestamp))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(settings.accentColor.color)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play \(item.title.localizedDigits), \(item.caption)")
        .contextMenu {
            Button(role: .destructive) {
                rangeHistory.remove(item)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    /// Plays a remembered range as it was played: its own surah (not necessarily this sheet's),
    /// its span clamped to the riwayah's ayah count, its repeats. Through the player directly, as
    /// the reciter switch above does, since `onPlay` is bound to the sheet's surah.
    private func playHistoryItem(_ item: CustomRangeHistoryItem) {
        guard let target = QuranData.shared.quran.first(where: { $0.id == item.surahNumber }) else { return }
        let maxA = target.numberOfAyahs(for: settings.displayQiraahForArabic)
        let start = min(Swift.max(1, item.startAyah), maxA)
        let end = min(Swift.max(start, item.endAyah), maxA)
        rangeHistory.record(surahNumber: target.id, surahName: target.nameTransliteration,
                            startAyah: start, endAyah: end,
                            repeatPerAyah: item.repeatPerAyah, repeatSection: item.repeatSection)
        QuranPlayer.shared.playCustomRange(
            surahNumber: target.id,
            surahName: target.nameTransliteration,
            startAyah: start,
            endAyah: end,
            repeatPerAyah: item.repeatPerAyah,
            repeatSection: item.repeatSection
        )
        onCancel()
    }

    // MARK: - Play bar

    @ViewBuilder
    private func animatedSummary(_ text: String) -> some View {
        let label = Text(text)
            .font(.subheadline.monospacedDigit())
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)

        if #available(iOS 16.0, *) {
            label.contentTransition(.numericText())
        } else {
            label
        }
    }

    private var playBar: some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            animatedSummary(playSummary)
                .animation(.easeInOut, value: [startAyah, endAyah, repeatPerAyah, repeatSection, repeatForever ? 1 : 0])

            Button {
                settings.hapticFeedback()
                commitBothAyahFields()
                commitAllRepeatFields()
                let section = repeatForever ? QuranPlayer.infiniteRepeat : repeatSection
                rangeHistory.record(surahNumber: surah.id, surahName: surah.nameTransliteration,
                                    startAyah: startAyah, endAyah: endAyah,
                                    repeatPerAyah: repeatPerAyah, repeatSection: section)
                onPlay(startAyah, endAyah, repeatPerAyah, section)
                onCancel()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Play Range")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                // Primary text on the accent glass, the splash screen's CTA exactly: white text on
                // the tinted glass was barely readable over a light ground on iOS 26.
                .foregroundColor(.primary)
                .conditionalGlassEffect(
                    useColor: 0.38,
                    customTint: canPlay ? settings.accentColor.color : .secondary
                )
                .contentShape(Rectangle())
            }
            .disabled(!canPlay)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 12)
        // The reading theme's ground, not the system one: on Sepia the bar was a white band.
        .background(appearance.themeBackground ?? Color(UIColor.systemGroupedBackground))
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

// MARK: - Range history

/// One range played from the sheet (Abu, 2026-10-20: "add custom range history"): what to play
/// again with one tap, and how it repeated.
struct CustomRangeHistoryItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let startAyah: Int
    let endAyah: Int
    let repeatPerAyah: Int
    /// `QuranPlayer.infiniteRepeat` when the whole range repeated forever.
    let repeatSection: Int
    var timestamp: Date = Date()

    /// "Al-Kahf 1-6" (an en dash), or "Al-Kahf 3" for a range of one.
    /// `surahName` is stored (and synced) as the transliteration; the title shows the interface's name.
    var title: String {
        let name = Surah.displayName(id: surahNumber, stored: surahName)
        return startAyah == endAyah ? "\(name) \(startAyah)" : "\(name) \(startAyah)\u{2013}\(endAyah)"
    }

    /// "6 ayahs · Each ×2 · Range ×3", "6 ayahs · Forever", or "6 ayahs · Once".
    var caption: String {
        let count = Swift.max(1, endAyah - startAyah + 1)
        var parts = [count == 1 ? String(localized: "\(count) ayah") : String(localized: "\(count) ayahs")]
        if repeatPerAyah > 1 { parts.append(String(localized: "Each \u{00D7}\(repeatPerAyah)")) }
        if repeatSection == QuranPlayer.infiniteRepeat {
            parts.append(String(localized: "Forever"))
        } else if repeatSection > 1 {
            parts.append(String(localized: "Range \u{00D7}\(repeatSection)"))
        }
        if parts.count == 1 { parts.append(String(localized: "Once")) }
        return parts.joined(separator: " \u{00B7} ")
    }

    /// The same range played the same way, whenever it was played.
    func matches(_ other: CustomRangeHistoryItem) -> Bool {
        surahNumber == other.surahNumber && startAyah == other.startAyah && endAyah == other.endAyah
            && repeatPerAyah == other.repeatPerAyah && repeatSection == other.repeatSection
    }
}

/// The ranges played from the sheet, newest first, capped at ten: playing a range again moves it to
/// the top with a fresh time. Persisted like the Quran tab's histories (`Settings.encoder` under a
/// content key, so a keep-content reset spares it and the iCloud backup carries it), and reread
/// after a restore through `StoredContentObserver`.
@MainActor
final class CustomRangeHistoryStore: ObservableObject {
    static let shared = CustomRangeHistoryStore()
    static let storageKey = "customRangeHistoryData"
    private static let cap = 10

    @Published private(set) var items: [CustomRangeHistoryItem] = []
    private var storageObserver: StoredContentObserver?

    private init() {
        ObjectPublishCounter.attach(self, label: "CustomRangeHistoryStore")
        items = Self.load()
        storageObserver = StoredContentObserver(reload: { [weak self] in
            self?.items = Self.load()
        })
    }

    func record(surahNumber: Int, surahName: String, startAyah: Int, endAyah: Int, repeatPerAyah: Int, repeatSection: Int) {
        let item = CustomRangeHistoryItem(surahNumber: surahNumber, surahName: surahName,
                                          startAyah: startAyah, endAyah: endAyah,
                                          repeatPerAyah: Swift.max(1, repeatPerAyah),
                                          repeatSection: Swift.max(1, repeatSection))
        var updated = items.filter { !$0.matches(item) }
        updated.insert(item, at: 0)
        items = Array(updated.prefix(Self.cap))
        persist()
    }

    func remove(_ item: CustomRangeHistoryItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func remove(atOffsets offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    private static func load() -> [CustomRangeHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = UserDataRescue.decodeList(CustomRangeHistoryItem.self, from: data, key: storageKey,
                                                      decoder: Settings.decoder) else { return [] }
        return Array(decoded.prefix(cap))
    }

    private func persist() {
        if items.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        } else if let data = try? Settings.encoder.encode(items) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
#endif
