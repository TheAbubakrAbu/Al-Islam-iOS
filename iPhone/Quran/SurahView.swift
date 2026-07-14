import SwiftUI
#if canImport(UIKit)
import UIKit

/// A slim capsule progress bar. Shared so the mushaf page footer and the list-mode floating header draw the
/// same indicator: both are answering "how far through this are you", and they should look identical.
struct TrackedBar: View {
    let fraction: CGFloat
    let height: CGFloat
    let color: Color

    var body: some View {
        let clamped = min(max(fraction, 0), 1)
        return GeometryReader { geo in
            Capsule()
                .fill(color.opacity(0.20))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(color)
                        .frame(width: max(geo.size.width * clamped, clamped > 0 ? height : 0))
                }
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }
}
#endif

struct SurahView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

    @Environment(\.scenePhase) private var scenePhase

    @State private var searchText = ""
    @State private var firstVisibleAyahID: Int? = nil
    @State private var visibleAyahIDs = Set<Int>()
    @State private var visibleBoundaryAyahIDs = Set<Int>()
    @State private var cachedAyahsForQiraah: [Ayah] = []
    @State private var cachedAyahByID: [Int: Ayah] = [:]
    @State private var cachedSearchBlobByAyahID: [Int: String] = [:]
    @State private var searchBlobPrewarmKey: String? = nil
    @State private var overlayDividerByAyahID: [Int: BoundaryDividerModel] = [:]
    @State private var cacheQiraahKey: String = ""
    @State private var qiraahCacheSurahID: Int? = nil
    @State private var scrollDown: Int? = nil
    @State private var pendingScrollAfterSearchClear: Int? = nil
    @State private var didScrollDown = false
    /// True while the surah's first page/juz divider is on screen. The pinned floating header then drops
    /// its page/juz line (redundant with the visible divider) and shows it only once that divider scrolls off.
    @State private var firstBoundaryDividerOnScreen = false
    @State private var showingSettingsSheet = false
    @State private var showAlert = false
    @State private var showCustomRangeSheet = false
    /// In page mode the reader crosses surah boundaries, so the toolbar must follow the page rather than the
    /// surah this view was opened with. `nil` in list mode, where `surah` never changes.
    @State private var pageSurah: Surah?
    private var displayedSurah: Surah { pageSurah ?? surah }

    @State private var showSurahInfoSheet = false
    @State private var showReciterPickerSheet = false
    @State private var showSurahPickerSheet = false
    @State private var confirmConvertQiraahToHafs = false
    @State private var isAyahSearchFocused = false
    @State private var selectedSurahNavigation: Int? = nil
    @State private var dividerInfo: DividerInfo? = nil
    @State private var surahInfoDialog: SurahInfoDialog? = nil
    /// Drives the title-tap chooser (Surah Picker / Surah Info / Revelation Info / page ↔ list).
    @State private var showTitleMenu = false
    /// Counts one "surah opened" per view instance (re-appearing after a pushed sub-view doesn't re-count).
    @State private var didRecordOpen = false
    @State private var khatmOverviewPercent: Int = 0
    @State private var khatmOverviewLastSignature: Int = 0
    /// The surah this view was opened with. `surah` below may differ once the user moves to another surah.
    let initialSurah: Surah
    let initialAyah: Int?
    var onSelectSurah: ((Int) -> Void)? = nil

    /// Set when the user goes to the previous/next surah or picks one - the view swaps the surah **in place**
    /// instead of pushing another `SurahView` onto the stack. `onChange(of: surah.id)` already rebuilds the
    /// caches and resets the scroll, so everything downstream refreshes for free.
    /// (Only ever used in stack navigation; the column-navigation path goes through `onSelectSurah`, which
    /// lets the parent swap the detail, so the two never fight.)
    @State private var swappedSurah: Surah?

    /// Where to land after flipping between list and page mode: the ayah that was at the top of the screen
    /// (list → page) or the first ayah of the page you were on (page → list). Set by `toggleReadingMode()` and
    /// consumed by whichever reader mounts next, so the switch keeps your place instead of jumping to the top
    /// of the surah. Cleared on a surah swap, which has its own target.
    @State private var modeSwitchAyah: Int?

    /// The first surah + ayah of the mushaf page currently on screen, reported by `SurahPageReader`. This is
    /// what "top of the page" means when leaving page mode.
    @State private var pageAnchor: (surahID: Int, ayahID: Int)?

    var surah: Surah { swappedSurah ?? initialSurah }
    /// The requested ayah only applies to the surah we were opened with - after a swap we open at the top - 
    /// unless a mode switch just named an ayah to land on, which wins over both.
    var ayah: Int? { modeSwitchAyah ?? (swappedSurah == nil ? initialAyah : nil) }

    init(surah: Surah, ayah: Int? = nil, onSelectSurah: ((Int) -> Void)? = nil) {
        self.initialSurah = surah
        self.initialAyah = ayah
        self.onSelectSurah = onSelectSurah
    }

    private final class PreparedSurahCache {
        let ayahs: [Ayah]
        let ayahByID: [Int: Ayah]
        let overlayDividerByAyahID: [Int: BoundaryDividerModel]

        init(
            ayahs: [Ayah],
            ayahByID: [Int: Ayah],
            overlayDividerByAyahID: [Int: BoundaryDividerModel]
        ) {
            self.ayahs = ayahs
            self.ayahByID = ayahByID
            self.overlayDividerByAyahID = overlayDividerByAyahID
        }
    }

    private final class PreparedSurahSearchCache {
        let searchBlobByAyahID: [Int: String]

        init(searchBlobByAyahID: [Int: String]) {
            self.searchBlobByAyahID = searchBlobByAyahID
        }
    }

    private static let preparedSurahCache: NSCache<NSString, PreparedSurahCache> = {
        let cache = NSCache<NSString, PreparedSurahCache>()
        cache.countLimit = AppPerformance.preparedSurahCacheLimit
        return cache
    }()

    private static let preparedSurahSearchCache: NSCache<NSString, PreparedSurahSearchCache> = {
        let cache = NSCache<NSString, PreparedSurahSearchCache>()
        cache.countLimit = AppPerformance.preparedSurahCacheLimit
        return cache
    }()

    @MainActor private static var visibleAyahMemoryByRoute: [String: Int] = [:]

    private struct DividerInfo: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private struct SurahInfoDialog: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private static let arFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ar")
        return f
    }()

    private func arabicToEnglishNumber(_ arabicNumber: String) -> Int? {
        SurahView.arFormatter.number(from: arabicNumber)?.intValue
    }

    private var isSearchingAyahs: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var ayahRowRenderSettingsSignature: String {
        settings.ayahRenderSettingsSignature
    }

    private func markKhatmViewedIfNeeded(_ ayahID: Int) {
        guard settings.quranSortMode == .khatm,
              settings.automaticKhatmCompletion,
              !isSearchingAyahs else { return }
        settings.markKhatmAyahComplete(surah: surah.id, ayah: ayahID)
    }

    private var shouldShowKhatmProgress: Bool {
        settings.quranSortMode == .khatm && !isSearchingAyahs
    }

    private var khatmCompletedAyahCount: Int {
        settings.khatmCompletedCount(for: surah)
    }

    private var khatmCompletionPercent: Int {
        guard surah.numberOfAyahs > 0 else { return 0 }
        return Int((Double(khatmCompletedAyahCount) / Double(surah.numberOfAyahs) * 100).rounded())
    }

    private struct PageJuzQuery {
        let page: Int?
        let juz: Int?
    }

    private enum DividerKeywordMode {
        case page
        case juz
    }

    private func boundaryDividerStyleEquals(_ lhs: BoundaryDividerStyle, _ rhs: BoundaryDividerStyle) -> Bool {
        switch (lhs, rhs) {
        case (.allGreen, .allGreen),
             (.allSecondary, .allSecondary),
             (.pageAccentJuzSecondary, .pageAccentJuzSecondary),
             (.allAccent, .allAccent):
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private func listBoundaryDivider(model: BoundaryDividerModel, nextAyahID: Int? = nil, showAyahPreview: Bool = false, showAyahLabel: Bool = true) -> some View {
        if settings.defaultView {
            boundaryDivider(model: model, nextAyahID: nextAyahID, showAyahPreview: showAyahPreview, showAyahLabel: showAyahLabel)
        } else {
            VStack {
                boundaryDivider(model: model, nextAyahID: nextAyahID, showAyahPreview: showAyahPreview, showAyahLabel: showAyahLabel)

                Divider()
                    .padding(.top, 7)
            }
            #if os(iOS)
            .listRowSeparator(.hidden)
            #endif
        }
    }
    private func boundaryDividerEquals(_ lhs: BoundaryDividerModel?, _ rhs: BoundaryDividerModel?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (l?, r?):
            return l.text == r.text &&
                l.pageSegment == r.pageSegment &&
                l.juzSegment == r.juzSegment &&
                boundaryDividerStyleEquals(l.style, r.style)
        default:
            return false
        }
    }

    private func boundaryDividerID(_ model: BoundaryDividerModel) -> String {
        let juz = model.juzSegment ?? ""
        let style: String
        switch model.style {
        case .allGreen: style = "allGreen"
        case .allSecondary: style = "allSecondary"
        case .pageAccentJuzSecondary: style = "pageAccentJuzSecondary"
        case .allAccent: style = "allAccent"
        }
        return "\(model.text)|\(model.pageSegment)|\(juz)|\(style)"
    }

    private func boundaryDividerInfo(for model: BoundaryDividerModel) -> DividerInfo {
        let title: String
        var message: String

        switch model.style {
        case .allGreen:
            title = "Highlighted divider"
            message = "\(model.text)\n\nThis divider is highlighted because it marks a surah start or end. It is mostly a visual marker, not a page or juz change."
        case .allSecondary:
            title = "Surah boundary"
            message = "\(model.text)\n\nGray means the page and juz do not change here. It is mainly showing a surah start or end."
        case .pageAccentJuzSecondary:
            title = "Page boundary"
            message = "\(model.text)\n\nThe color change means the page changes here. The juz stays the same."
        case .allAccent:
            title = "Page and juz boundary"
            message = "\(model.text)\n\nThe color change means both the page and the juz change here."
        }

        // Same-surah page dividers annotate the absolute page with its position within this surah,
        // e.g. "Page 102 (3)". Translate the bare "(N)" into its plain meaning: the Nth page of this surah.
        if let relative = pageWithinSurah(fromSegment: model.pageSegment) {
            message += "\n\n(\(relative)) means you're on the \(ordinal(relative)) page of this surah."
        }

        return DividerInfo(title: title, message: message)
    }

    /// Pull the "(N)" position-within-surah value out of a page segment like "Page 102 (3)".
    private func pageWithinSurah(fromSegment segment: String) -> Int? {
        guard let open = segment.firstIndex(of: "("),
              let close = segment.firstIndex(of: ")"),
              open < close else { return nil }
        let inner = segment[segment.index(after: open)..<close].trimmingCharacters(in: .whitespaces)
        return Int(inner)
    }

    /// "1st", "2nd", "3rd", "5th"… for short, human divider text.
    private func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)th"
    }

    private func surahInfoDialog(for surah: Surah) -> SurahInfoDialog {
        let revelationOrderText = surah.revelationOrder.map(String.init) ?? "Unknown"
        var message = "Revelation order: #\(revelationOrderText)"

        if let exceptions = surah.revelationExceptions?.trimmingCharacters(in: .whitespacesAndNewlines), !exceptions.isEmpty {
            message += "\n\nExceptions: \(exceptions)"
        }

        return SurahInfoDialog(title: "Revelation Info", message: message)
    }

    /// Ayah row id to scroll to after clearing search (first ayah following this boundary).
    private func scrollTargetAyahID(
        forDivider model: BoundaryDividerModel,
        boundaryModel: SurahBoundaryModel,
        ayahsForQiraah: [Ayah]
    ) -> Int? {
        if let start = boundaryModel.startDivider, boundaryDividerEquals(start, model) {
            return ayahsForQiraah.first?.id
        }
        for ayah in ayahsForQiraah {
            if let d = boundaryModel.dividerBeforeAyah[ayah.id], boundaryDividerEquals(d, model) {
                return ayah.id
            }
        }
        if let end = boundaryModel.endOfSurahDivider, boundaryDividerEquals(end, model) {
            return ayahsForQiraah.last?.id
        }
        if let end = boundaryModel.endDivider, boundaryDividerEquals(end, model) {
            return ayahsForQiraah.last?.id
        }
        return nil
    }

    private func boundaryText(for ayah: Ayah) -> String? {
        if let page = ayah.page, let juz = ayah.juz {
            return "\(mushafPageLabel(forAbsolutePage: page, in: surah)) • Juz \(juz)"
        }
        if let page = ayah.page {
            return mushafPageLabel(forAbsolutePage: page, in: surah)
        }
        if let juz = ayah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func parsePageJuzQuery(from raw: String) -> PageJuzQuery {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return PageJuzQuery(page: nil, juz: nil) }

        let lowered = trimmed.lowercased()

        if lowered.hasPrefix("page ") {
            let valueText = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            let n = Int(valueText) ?? arabicToEnglishNumber(valueText)
            if let n, (1...630).contains(n) { return PageJuzQuery(page: n, juz: nil) }
            return PageJuzQuery(page: nil, juz: nil)
        }

        if lowered.hasPrefix("juz ") {
            let valueText = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            // Accept a juz name (Arabic or transliteration) as well as a number, matching QuranView.
            let n = quranData.resolveJuzIdentifier(valueText) ?? Int(valueText) ?? arabicToEnglishNumber(valueText)
            if let n, (1...30).contains(n) { return PageJuzQuery(page: nil, juz: n) }
            return PageJuzQuery(page: nil, juz: nil)
        }

        return PageJuzQuery(page: nil, juz: nil)
    }

    private func parseAyahNumberQuery(from raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lowered = trimmed.lowercased()
        let prefixes = ["ayah ", "ayahs ", "aayah ", "aayahs ", "verse ", "verses "]
        for prefix in prefixes where lowered.hasPrefix(prefix) {
            let valueText = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if let n = Int(valueText) ?? arabicToEnglishNumber(valueText), n >= 1 {
                return n
            }
        }

        return nil
    }

    private func booleanAyahSearchGroups(from rawQuery: String) -> [[BooleanAyahTerm]]? {
        let normalized = rawQuery
            .replacingOccurrences(of: "&&", with: "&")
            .replacingOccurrences(of: "||", with: "|")

        guard normalized.contains("&") || normalized.contains("|") || normalized.contains("!") || normalized.contains("#") || normalized.contains("^") || normalized.contains("%") || normalized.contains("$") || normalized.contains("=") else {
            return nil
        }

        return normalized
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { part in
                part
                    .split(separator: "&", omittingEmptySubsequences: false)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    .compactMap(booleanAyahSearchTerm(from:))
            }
            .filter { !$0.isEmpty }
    }

    private struct BooleanAyahTerm {
        enum MatchMode {
            case contains
            case startsWith
            case endsWith
            case exact
            case wholeWord   // `=` - matches whole words / a series of whole words (not substrings)
        }

        let value: String
        let isNegated: Bool
        let matchMode: MatchMode
        let requiresTashkeelMatch: Bool
        let tashkeelPattern: String
        let requiresExactEnglishMatch: Bool
        let exactEnglishPhrase: String
    }

    private static let arabicTashkeelCharacterSet: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "\u{0610}"..."\u{061A}")
        set.insert(charactersIn: "\u{064B}"..."\u{065F}")
        set.insert(charactersIn: "\u{0670}"..."\u{0670}")
        set.insert(charactersIn: "\u{06D6}"..."\u{06ED}")
        return set
    }()

    private func arabicTashkeelBlob(_ text: String) -> String {
        String(text.unicodeScalars.filter { Self.arabicTashkeelCharacterSet.contains($0) })
    }

    private func exactPhraseBlob(_ text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func booleanAyahSearchTerm(from rawTerm: String) -> BooleanAyahTerm? {
        var term = rawTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return nil }

        var isNegated = false
        while term.hasPrefix("!") {
            isNegated.toggle()
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var requiresTashkeelMatch = false
        while term.hasPrefix("#") {
            requiresTashkeelMatch = true
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var wholeWordMatch = false
        while term.hasPrefix("=") {
            wholeWordMatch = true
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var startsWithMatch = false
        if term.hasPrefix("^") {
            startsWithMatch = true
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var endsWithMatch = false
        if term.hasSuffix("%") || term.hasSuffix("$") {
            endsWithMatch = true
            term.removeLast()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !term.isEmpty else { return nil }
        let cleaned = settings.cleanSearch(term, whitespace: true)
        guard !cleaned.isEmpty else { return nil }

        let matchMode: BooleanAyahTerm.MatchMode
        if wholeWordMatch {
            matchMode = .wholeWord
        } else if startsWithMatch && endsWithMatch {
            matchMode = .exact
        } else if startsWithMatch {
            matchMode = .startsWith
        } else if endsWithMatch {
            matchMode = .endsWith
        } else {
            matchMode = .contains
        }

        return BooleanAyahTerm(
            value: cleaned,
            isNegated: isNegated,
            matchMode: matchMode,
            requiresTashkeelMatch: requiresTashkeelMatch && term.containsArabicLetters,
            tashkeelPattern: arabicTashkeelBlob(term),
            requiresExactEnglishMatch: requiresTashkeelMatch && !term.containsArabicLetters,
            exactEnglishPhrase: exactPhraseBlob(term)
        )
    }

    private func searchTokens(from cleanedText: String) -> [String] {
        cleanedText.split(separator: " ").map(String.init).filter { !$0.isEmpty }
    }

    private func ayahTermMatch(haystack: String, tokens: [String], term: String, mode: BooleanAyahTerm.MatchMode) -> Bool {
        switch mode {
        case .contains:
            return haystack.contains(term)
        case .startsWith:
            return haystack.hasPrefix(term) || tokens.contains(where: { $0.hasPrefix(term) })
        case .endsWith:
            return haystack.hasSuffix(term) || tokens.contains(where: { $0.hasSuffix(term) })
        case .exact:
            return haystack == term || tokens.contains(term)
        case .wholeWord:
            // The query's words must appear as a consecutive run of whole words (a full word, or a full
            // series of words) - e.g. "=رب" matches the word رب but not "ربهم".
            return consecutiveTokenMatch(tokens, query: searchTokens(from: term), lastMustBeExact: true)
        }
    }

    /// True if `query`'s tokens appear as a consecutive run of whole words in `haystack`.
    private func consecutiveTokenMatch(_ haystack: [String], query: [String], lastMustBeExact: Bool) -> Bool {
        guard !query.isEmpty, haystack.count >= query.count else { return false }
        for start in 0...(haystack.count - query.count) {
            var matched = true
            for offset in query.indices {
                let word = haystack[start + offset]
                let term = query[offset]
                if offset == query.count - 1 && !lastMustBeExact {
                    if !word.hasPrefix(term) { matched = false; break }
                } else if word != term {
                    matched = false
                    break
                }
            }
            if matched { return true }
        }
        return false
    }

    private func matchesBooleanAyahSearch(ayah: Ayah, haystack: String, groups: [[BooleanAyahTerm]]) -> Bool {
        let haystackTokens = searchTokens(from: haystack)
        return groups.contains { andTerms in
            andTerms.allSatisfy { term in
                let containsTerm: Bool
                if term.requiresTashkeelMatch {
                    let lettersMatch = ayahTermMatch(haystack: haystack, tokens: haystackTokens, term: term.value, mode: term.matchMode)
                    let tashkeelHaystack = arabicTashkeelBlob(ayah.textArabic(for: settings.displayQiraahForArabic))
                    let tashkeelMatch = term.tashkeelPattern.isEmpty || tashkeelHaystack.contains(term.tashkeelPattern)
                    containsTerm = lettersMatch && tashkeelMatch
                } else if term.requiresExactEnglishMatch {
                    let englishExactHaystack = exactPhraseBlob([
                        ayah.textTransliteration,
                        ayah.textEnglishSaheeh,
                        ayah.textEnglishMustafa
                    ].joined(separator: " "))
                    containsTerm = !term.exactEnglishPhrase.isEmpty && ayahTermMatch(
                        haystack: englishExactHaystack,
                        tokens: searchTokens(from: englishExactHaystack),
                        term: term.exactEnglishPhrase,
                        mode: term.matchMode
                    )
                } else {
                    containsTerm = ayahTermMatch(haystack: haystack, tokens: haystackTokens, term: term.value, mode: term.matchMode)
                }
                return term.isNegated ? !containsTerm : containsTerm
            }
        }
    }

    static func prewarm(surah: Surah, settings: Settings) {
        _ = preparedCache(for: surah, settings: settings)
        AyahRow.prewarmArabicDisplay(
            surah: surah,
            settings: settings,
            limit: AppPerformance.prewarmArabicAyahLimit
        )
    }

    private static func preparedCache(for surah: Surah, settings: Settings) -> PreparedSurahCache {
        let qiraahKey = settings.displayQiraahForArabic ?? ""
        let cacheKey = "\(surah.id)|\(qiraahKey)" as NSString
        if let cached = preparedSurahCache.object(forKey: cacheKey) {
            return cached
        }

        let ayahs = surah.ayahs.filter { $0.existsInQiraah(settings.displayQiraahForArabic) }
        let ayahByID = Dictionary(uniqueKeysWithValues: ayahs.map { ($0.id, $0) })
        let shouldBuildFullOverlayMap = surah.pageOrJuzChangesWithinSurah

        var overlayMap: [Int: BoundaryDividerModel] = [:]

        if shouldBuildFullOverlayMap {
            overlayMap.reserveCapacity(ayahs.count)
        }

        for (index, ayah) in ayahs.enumerated() {
            if shouldBuildFullOverlayMap || index == 0 {
                let pageSegment: String
                if let page = ayah.page {
                    pageSegment = mushafPageLabel(forAbsolutePage: page, in: surah)
                } else if let juz = ayah.juz {
                    pageSegment = "Juz \(juz)"
                } else {
                    continue
                }

                let juzSegment = (ayah.page != nil) ? ayah.juz.map { "Juz \($0)" } : nil
                let pageInSurah = ayah.page.flatMap { surah.pageWithinSurah($0) }
                overlayMap[ayah.id] = BoundaryDividerModel(
                    text: boundaryText(for: ayah, in: surah) ?? pageSegment,
                    pageSegment: pageSegment,
                    juzSegment: juzSegment,
                    style: .allAccent,
                    pageInSurah: pageInSurah,
                    surahPageCount: pageInSurah.map { max(surah.pageCount, $0) }
                )
            }
        }

        let prepared = PreparedSurahCache(
            ayahs: ayahs,
            ayahByID: ayahByID,
            overlayDividerByAyahID: overlayMap
        )
        preparedSurahCache.setObject(prepared, forKey: cacheKey)
        return prepared
    }

    private static func preparedSearchCache(
        for surah: Surah,
        settings: Settings,
        ayahs: [Ayah]
    ) -> PreparedSurahSearchCache {
        let qiraahKey = settings.displayQiraahForArabic ?? ""
        let ignoreSilent = settings.ignoreSilentLettersInQuranSearch
        let cacheKey = "\(surah.id)|\(qiraahKey)|s\(ignoreSilent ? 1 : 0)" as NSString
        if let cached = preparedSurahSearchCache.object(forKey: cacheKey) {
            return cached
        }

        let searchBlobMap = buildSearchBlobMap(ayahs: ayahs, displayQiraah: settings.displayQiraahForArabic, ignoreSilent: ignoreSilent)
        let prepared = PreparedSurahSearchCache(searchBlobByAyahID: searchBlobMap)
        preparedSurahSearchCache.setObject(prepared, forKey: cacheKey)
        return prepared
    }

    private static func boundaryText(for ayah: Ayah, in surah: Surah) -> String? {
        if let page = ayah.page, let juz = ayah.juz {
            return "\(mushafPageLabel(forAbsolutePage: page, in: surah)) • Juz \(juz)"
        }
        if let page = ayah.page {
            return mushafPageLabel(forAbsolutePage: page, in: surah)
        }
        if let juz = ayah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func rebuildQiraahCaches() {
        let key = settings.displayQiraahForArabic ?? ""
        if qiraahCacheSurahID == surah.id, key == cacheQiraahKey, !cachedAyahsForQiraah.isEmpty {
            return
        }

        let prepared = Self.preparedCache(for: surah, settings: settings)
        let ayahs = prepared.ayahs

        cachedAyahsForQiraah = ayahs
        cachedAyahByID = prepared.ayahByID
        overlayDividerByAyahID = prepared.overlayDividerByAyahID
        cachedSearchBlobByAyahID = [:]
        searchBlobPrewarmKey = nil
        cacheQiraahKey = key
        qiraahCacheSurahID = surah.id

        let fallbackID = ayahs.first?.id
        if let firstVisibleAyahID {
            if cachedAyahByID[firstVisibleAyahID] == nil {
                self.firstVisibleAyahID = fallbackID
            }
        } else {
            self.firstVisibleAyahID = fallbackID
        }

        prewarmSearchBlobs()
    }

    /// Builds the per-ayah search blobs for the active surah/qiraah on a background queue and
    /// publishes them to `cachedSearchBlobByAyahID`. This moves the expensive normalization work
    /// (thousands of `cleanSearch` calls) off the main thread so the first ayah-search keystroke
    /// never has to build the blob map synchronously while the user is typing.
    private func prewarmSearchBlobs() {
        let qiraahKey = settings.displayQiraahForArabic ?? ""
        let ignoreSilent = settings.ignoreSilentLettersInQuranSearch
        let key = "\(surah.id)|\(qiraahKey)|s\(ignoreSilent ? 1 : 0)"
        if searchBlobPrewarmKey == key, !cachedSearchBlobByAyahID.isEmpty { return }

        let surah = self.surah
        let settings = self.settings
        let displayQiraah = settings.displayQiraahForArabic
        let ayahs = cachedAyahsForQiraah.isEmpty
            ? Self.preparedCache(for: surah, settings: settings).ayahs
            : cachedAyahsForQiraah

        Task.detached(priority: .utility) {
            let blobMap = Self.buildSearchBlobMap(ayahs: ayahs, displayQiraah: displayQiraah, ignoreSilent: ignoreSilent)
            await MainActor.run {
                // Discard if the user moved to another surah/qiraah, or toggled silent search, mid-build.
                let currentKey = "\(self.surah.id)|\(self.settings.displayQiraahForArabic ?? "")|s\(self.settings.ignoreSilentLettersInQuranSearch ? 1 : 0)"
                guard currentKey == key else { return }
                self.cachedSearchBlobByAyahID = blobMap
                self.searchBlobPrewarmKey = key
            }
        }
    }

    /// Pure, actor-agnostic builder for the per-ayah search-blob map. Marked `nonisolated` so it can run
    /// on a background task without hopping back to the main actor (SurahView, being a `View`, is otherwise
    /// `@MainActor`-isolated). It only touches `Settings.shared` config and immutable ayah text.
    nonisolated private static func buildSearchBlobMap(ayahs: [Ayah], displayQiraah: String?, ignoreSilent: Bool) -> [Int: String] {
        let settings = Settings.shared
        var searchBlobMap: [Int: String] = [:]
        searchBlobMap.reserveCapacity(ayahs.count)
        for ayah in ayahs {
            var parts = [
                ayah.textArabic(for: displayQiraah),
                ayah.textCleanArabic(for: displayQiraah),
                ayah.textTransliteration,
                ayah.textEnglishSaheeh,
                ayah.textEnglishMustafa,
                String(ayah.id),
                ayah.idArabic
            ]
            .map { settings.cleanSearch($0) }

            if ignoreSilent {
                // Mirror QuranView's silent-letter search: also index the silent-letter-stripped Arabic so a
                // query that omits silent letters still matches. Gated by the setting (and the cache key) so
                // it doesn't loosen matching when the user has the option off.
                parts.append(settings.cleanSearchIgnoringSilentArabicLetters(ayah.textArabic(for: displayQiraah)))
                parts.append(settings.cleanSearchIgnoringSilentArabicLetters(ayah.textCleanArabic(for: displayQiraah)))
            }

            searchBlobMap[ayah.id] = parts.joined(separator: " ")
        }
        return searchBlobMap
    }

    private var visibleAyahMemoryRouteKey: String {
        "\(surah.id)|\(ayah ?? 0)|\(settings.displayQiraahForArabic ?? "")"
    }

    @MainActor
    private func rememberVisibleAyahID(_ ayahID: Int) {
        Self.visibleAyahMemoryByRoute[visibleAyahMemoryRouteKey] = ayahID
    }

    /// Clamps a requested ayah to the nearest verse that actually exists in the active qiraah. Bookmarks /
    /// deep links are stored in Hafs numbering, but qiraat merge/omit some ayahs (e.g. Baqarah ends at 285
    /// in Warsh, 286 in Hafs), so a target may not exist - land on the closest one instead of the top.
    private func nearestExistingAyahID(_ requested: Int, in ids: [Int]) -> Int? {
        ids.min(by: { abs($0 - requested) < abs($1 - requested) })
    }

    private func scrollToAyah(_ ayahID: Int, proxy: ScrollViewProxy, animated: Bool = false) {
        // Lazy list cells for the target may not exist on the first pass (especially right after the view
        // appears or is reconfigured), so a single scrollTo can silently miss and leave the old position.
        // Retry across a few runloop ticks so the target reliably lands.
        func attempt(_ remaining: Int) {
            if animated {
                withAnimation { proxy.scrollTo(ayahID, anchor: .top) }
            } else {
                proxy.scrollTo(ayahID, anchor: .top)
            }
            guard remaining > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                attempt(remaining - 1)
            }
        }
        DispatchQueue.main.async { attempt(2) }
    }

    private func boundaryDivider(model: BoundaryDividerModel, isOverlay: Bool = false, nextAyahID: Int? = nil, showAyahPreview: Bool = false, showAyahLabel: Bool = true) -> some View {
        let accent = settings.accentColor.color

        let dividerColor: Color = {
            if isOverlay { return settings.accentColor.color }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()
        let pageColor: Color = {
            if isOverlay { return accent }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()
        let juzColor: Color = {
            if isOverlay { return settings.accentColor.color }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary: return .secondary
            case .allAccent: return accent
            }
        }()
        let separatorColor: Color = {
            if isOverlay { return settings.accentColor.color }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()

        let dividerContent = HStack(spacing: isOverlay ? 8 : 10) {
            #if os(iOS)
            Group {
                if isOverlay {
                    Rectangle()
                        .fill(dividerColor.opacity(0.55))
                        .frame(maxHeight: 1)
                } else {
                    Rectangle()
                        .fill(dividerColor.opacity(0.45))
                        .frame(maxHeight: 1)
                }
            }
            #else
            Spacer()
            #endif

            (
                Text(model.pageSegment)
                    .foregroundColor(pageColor)
                +
                (model.juzSegment.map {
                    Text(" • ").foregroundColor(separatorColor)
                    + Text($0).foregroundColor(juzColor)
                } ?? Text(""))
            )
            .font((isOverlay ? Font.caption : Font.caption).weight(.semibold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(isOverlay ? 0.5 : 0.6)
            .allowsTightening(!isOverlay)
            .layoutPriority(2)
            .fixedSize(horizontal: isOverlay, vertical: true)

            #if os(iOS)
            Group {
                if isOverlay {
                    Rectangle()
                        .fill(dividerColor.opacity(0.55))
                        .frame(maxHeight: 1)
                } else {
                    Rectangle()
                        .fill(dividerColor.opacity(0.45))
                        .frame(maxHeight: 1)
                }
            }
            #else
            Spacer()
            #endif
        }
        .padding(.vertical, isOverlay ? 4 : 6)
        .padding(.horizontal, 0)
        .frame(maxWidth: isOverlay ? .infinity : nil)
        .contentShape(Rectangle())

        #if os(iOS)
        // While searching, dividers double as jump targets: a tap navigates to the ayah and the info
        // dialog is reserved for a long-press. When not searching there is nothing to jump to, so a plain
        // tap opens the info dialog and there is no long-press.
        if !searchText.isEmpty {
            if let ayahID = nextAyahID {
                let labeledContent = VStack(spacing: 2) {
                    dividerContent
                    if showAyahLabel {
                        Text("Ayah \(ayahID)")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    // For a bare "page"/"juz" keyword search we only list dividers (no ayah rows), so show a
                    // small Arabic preview of the start of the divider's first ayah. Rendered with the same
                    // pipeline as a real ayah row (font, tajweed, beginner mode, Allah highlight), just smaller
                    // and single-line so only the beginning of the ayah shows.
                    if showAyahPreview, settings.showArabicText,
                       let previewAyah = surah.ayahs.first(where: { $0.id == ayahID }) {
                        AyahArabicSnippet(surah: surah, ayah: previewAyah, scale: 0.7, lineLimit: 1)
                    }
                }
                return AnyView(
                    labeledContent
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settings.hapticFeedback()
                            scrollDown = ayahID
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.45)
                                .onEnded { _ in
                                    settings.hapticFeedback()
                                    dividerInfo = boundaryDividerInfo(for: model)
                                }
                        )
                )
            }

            return AnyView(
                dividerContent
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.45)
                            .onEnded { _ in
                                settings.hapticFeedback()
                                dividerInfo = boundaryDividerInfo(for: model)
                            }
                    )
            )
        }

        return AnyView(
            dividerContent
                .onTapGesture {
                    settings.hapticFeedback()
                    dividerInfo = boundaryDividerInfo(for: model)
                }
        )
        #else
        return AnyView(
            dividerContent
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.45)
                        .onEnded { _ in
                            settings.hapticFeedback()
                            dividerInfo = boundaryDividerInfo(for: model)
                        }
                )
        )
        #endif
    }

    // Extracted from `body` so the large modifier chain stays under the Swift type-checker limit.
    private var surahCoreBody: some View {
        ScrollViewReader { proxy in
            ayahListScreen(proxy: proxy)
        }
        .environmentObject(quranPlayer)
        .onDisappear(perform: saveLastRead)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .inactive:
                // Pulling Control Center / Notification Center down briefly flips the scene to `.inactive`.
                // Only remember the current spot in memory here - writing `settings.lastRead*` (@AppStorage)
                // republishes the view tree and can reconstruct this screen mid-scroll, jumping the user
                // away from where they were. The in-memory anchor is enough to restore on re-appear.
                rememberCurrentVisibleAyah()
            case .background:
                saveLastRead()
            default:
                break
            }
        }
    }

    /// Page mode swaps the ayah list for the swipeable mushaf pages; everything wrapped around it (toolbar,
    /// sheets, dialogs) is shared by both.
    @ViewBuilder
    private var surahReadingBody: some View {
        #if os(iOS)
        if settings.quranPageMode {
            // The reader owns the bottom stack: these controls sit ABOVE its page-navigation footer, which
            // stays pinned at the very bottom.
            SurahPageReader(
                surah: surah,
                initialAyah: ayah,
                onSurahChange: { pageSurah = $0 },
                onPageAnchor: { surahID, ayahID in pageAnchor = (surahID, ayahID) }
            ) {
                let active = quranPlayer.isPlaying || quranPlayer.isPaused
                VStack(spacing: 0) {
                    qiraatAndTajweedControls

                    if active {
                        NowPlayingView(quranView: false)
                            .padding(.horizontal, 24)
                            .padding(.top, SafeAreaInsetVStackSpacing.standard)
                            .transition(.opacity)
                    }
                }
                // Same breathing room the list reader gives this bar - and here the bottom padding is also what
                // separates it from the page-navigation footer pinned underneath, which it was crowding.
                .padding(.top, SafeAreaInsetVStackSpacing.standard)
                .padding(.bottom, SafeAreaInsetVStackSpacing.standard)
                .background(Color.white.opacity(0.00001))
                .animation(.easeInOut, value: active)
            }
            // The reader seeds its starting page once (`didSetInitialPage`), so swapping the surah in
            // place must give it a fresh identity - otherwise it would stay on the old surah's page.
            .id(surah.id)
        } else {
            surahCoreBody
                // Back in list mode the title is fixed to this view's own surah again.
                .onAppear { pageSurah = nil }
        }
        #else
        surahCoreBody
        #endif
    }

    var body: some View {
        #if os(iOS)
        // The centered title is now a Menu (Surah List / Surah Info / Revelation Info), so the toolbar
        // only carries the principal title and the trailing settings gear.
        applySurahToolbar(to: surahReadingBody)
        .onAppear {
            quranPlayer.recordReadingHistory(surahNumber: surah.id, surahName: surah.nameTransliteration, ayahNumber: ayah ?? 1)
            if !didRecordOpen {
                didRecordOpen = true
                settings.recordSurahOpened(surah.id)
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            settingsSheet
                .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showSurahInfoSheet) {
            SurahInfoSheet(surahName: displayedSurah.nameTransliteration, surahNumber: displayedSurah.id)
                .environmentObject(settings)
                .environmentObject(quranData)
        }
        .sheet(isPresented: $showSurahPickerSheet) {
            SurahPickerSheet(currentSurahID: surah.id) { selectedSurah in
                settings.hapticFeedback()
                showSurahPickerSheet = false

                guard selectedSurah.id != surah.id else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    navigateToSurah(selectedSurah)
                }
            }
            .environmentObject(settings)
            .environmentObject(quranData)
            .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showCustomRangeSheet) {
            PlayCustomRangeSheet(
                surah: surah,
                initialStartAyah: 1,
                initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                    startAyah: 1,
                    surah: surah,
                    displayQiraah: settings.displayQiraahForArabic
                ),
                onPlay: { start, end, repAyah, repSec in
                    quranPlayer.playCustomRange(
                        surahNumber: surah.id,
                        surahName: surah.nameTransliteration,
                        startAyah: start,
                        endAyah: end,
                        repeatPerAyah: repAyah,
                        repeatSection: repSec
                    )
                },
                onCancel: { showCustomRangeSheet = false }
            )
            .environmentObject(settings)
            .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showReciterPickerSheet) {
            NavigationView {
                ReciterListView(dismissAfterSelectingReciter: true, autoScrollToInitialSelection: false)
                    .environmentObject(settings)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                settings.hapticFeedback()
                                showReciterPickerSheet = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.body.weight(.semibold))
                            }
                            .tint(settings.accentColor.color)
                        }
                    }
            }
            .navigationViewStyle(.stack)
            .smallMediumSheetPresentation()
        }
        .confirmationDialog(
            dividerInfo?.title ?? "Boundary",
            isPresented: Binding(
                get: { dividerInfo != nil },
                set: { if !$0 { dividerInfo = nil } }
            ),
            presenting: dividerInfo
        ) { _ in
            Button("OK") {
                dividerInfo = nil
            }
        } message: { info in
            Text(info.message)
        }
        .confirmationDialog(
            surahInfoDialog?.title ?? "Surah Info",
            isPresented: Binding(
                get: { surahInfoDialog != nil },
                set: { if !$0 { surahInfoDialog = nil } }
            ),
            presenting: surahInfoDialog
        ) { _ in
            Button("OK") {
                surahInfoDialog = nil
            }
        } message: { info in
            Text(info.message)
        }
        .onChange(of: quranPlayer.showInternetAlert) { if $0 { showAlert = true; quranPlayer.showInternetAlert = false } }
        .confirmationDialog(quranPlayer.playbackAlertTitle, isPresented: $showAlert, titleVisibility: .visible) {
            Button("OK") { }
        } message: {
            Text(quranPlayer.playbackAlertMessage)
        }
        .background(
            NavigationLink(
                destination: selectedSurahNavigationDestination,
                isActive: Binding(
                    get: { selectedSurahNavigation != nil },
                    set: { isActive in
                        if !isActive {
                            selectedSurahNavigation = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        )
        #else
        surahCoreBody
            .navigationTitle("\(surah.id) - \(surah.nameTransliteration)")
        #endif
    }

    private func ayahListScreen(proxy: ScrollViewProxy) -> some View {
        let cleanQuery = settings.cleanSearch(searchText, whitespace: true)
        // Mirror QuranView: when the option is on and the query is Arabic, also match the silent-letter
        // stripped form (the matching silent forms are folded into the search blob above).
        let silentQuery: String? = (settings.ignoreSilentLettersInQuranSearch && searchText.containsArabicLetters)
            ? settings.cleanSearchIgnoringSilentArabicLetters(searchText, whitespace: true)
            : nil
        let booleanGroups = booleanAyahSearchGroups(from: searchText)
        let pageJuzQuery = parsePageJuzQuery(from: searchText)
        let ayahNumberQuery = parseAyahNumberQuery(from: searchText)
        let trimmedLowerSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let dividerKeywordMode: DividerKeywordMode? = {
            if trimmedLowerSearch == "page" || trimmedLowerSearch == "pages" { return .page }
            if trimmedLowerSearch == "juz" { return .juz }
            return nil
        }()
        let isDividerKeywordSearch = dividerKeywordMode != nil
        let isPageOrJuzSearch = pageJuzQuery.page != nil || pageJuzQuery.juz != nil
        // During a page/juz search the divider IS the context (it tells you which page/juz you're looking
        // at), so always show it then - regardless of the user's normal show-page/juz-dividers preference,
        // which only governs reading (searchText empty).
        let showBoundaryDividers = isPageOrJuzSearch || isDividerKeywordSearch || (settings.showPageJuzDividers && searchText.isEmpty)
        let prepared = cachedAyahsForQiraah.isEmpty ? Self.preparedCache(for: surah, settings: settings) : nil
        let ayahsForQiraah = cachedAyahsForQiraah.isEmpty
            ? (prepared?.ayahs ?? [])
            : cachedAyahsForQiraah
        let ayahByID = cachedAyahByID.isEmpty
            ? (prepared?.ayahByID ?? [:])
            : cachedAyahByID
        let shouldUseTextSearchBlobs = !cleanQuery.isEmpty
            && !isDividerKeywordSearch
            && !isPageOrJuzSearch
            && ayahNumberQuery == nil
        let searchBlobByAyahID = shouldUseTextSearchBlobs
            ? (cachedSearchBlobByAyahID.isEmpty
                ? Self.preparedSearchCache(for: surah, settings: settings, ayahs: ayahsForQiraah).searchBlobByAyahID
                : cachedSearchBlobByAyahID)
            : [:]
        let filteredAyahs: [Ayah] = {
            guard !cleanQuery.isEmpty else { return ayahsForQiraah }
            if isDividerKeywordSearch { return [] }

            return ayahsForQiraah.filter { a in
                if isPageOrJuzSearch {
                    let pageMatch = pageJuzQuery.page != nil && a.page == pageJuzQuery.page
                    let juzMatch = pageJuzQuery.juz != nil && a.juz == pageJuzQuery.juz
                    return pageMatch || juzMatch
                }

                if let ayahNumberQuery {
                    return a.id == ayahNumberQuery
                }

                if let blob = searchBlobByAyahID[a.id] {
                    if let booleanGroups {
                        if booleanGroups.isEmpty { return false }
                        return matchesBooleanAyahSearch(ayah: a, haystack: blob, groups: booleanGroups)
                    }
                    if blob.contains(cleanQuery) { return true }
                    return silentQuery.map { !$0.isEmpty && blob.contains($0) } ?? false
                }

                var fallbackParts = [
                    settings.cleanSearch(a.textArabic),
                    settings.cleanSearch(a.textCleanArabic),
                    settings.cleanSearch(a.textTransliteration),
                    settings.cleanSearch(a.textEnglishSaheeh),
                    settings.cleanSearch(a.textEnglishMustafa),
                    settings.cleanSearch(String(a.id)),
                    settings.cleanSearch(a.idArabic)
                ]
                if silentQuery != nil {
                    fallbackParts.append(settings.cleanSearchIgnoringSilentArabicLetters(a.textArabic))
                    fallbackParts.append(settings.cleanSearchIgnoringSilentArabicLetters(a.textCleanArabic))
                }
                let fallbackBlob = fallbackParts.joined(separator: " ")

                if let booleanGroups {
                    if booleanGroups.isEmpty { return false }
                    return matchesBooleanAyahSearch(ayah: a, haystack: fallbackBlob, groups: booleanGroups)
                }

                if fallbackBlob.contains(cleanQuery) { return true }
                return silentQuery.map { !$0.isEmpty && fallbackBlob.contains($0) } ?? false
            }
        }()
        let boundaryModel = showBoundaryDividers ? quranData.boundaryModel(forSurah: surah.id) : nil
        let trailingSearchBoundaryDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers, isPageOrJuzSearch, !isDividerKeywordSearch else { return nil }
            guard let boundaryModel else { return nil }
            guard let lastFilteredAyahID = filteredAyahs.last?.id else { return nil }

            if let idx = ayahsForQiraah.firstIndex(where: { $0.id == lastFilteredAyahID }) {
                let nextIndex = ayahsForQiraah.index(after: idx)
                if nextIndex < ayahsForQiraah.endIndex {
                    let nextAyah = ayahsForQiraah[nextIndex]
                    return boundaryModel.dividerBeforeAyah[nextAyah.id]
                }
            }

            return boundaryModel.endDivider
        }()
        let trailingSearchBoundaryScrollTarget: Int? = {
            guard showBoundaryDividers, isPageOrJuzSearch, !isDividerKeywordSearch else { return nil }
            guard let boundaryModel else { return nil }
            guard let lastFilteredAyahID = filteredAyahs.last?.id else { return nil }

            if let idx = ayahsForQiraah.firstIndex(where: { $0.id == lastFilteredAyahID }) {
                let nextIndex = ayahsForQiraah.index(after: idx)
                if nextIndex < ayahsForQiraah.endIndex {
                    let nextAyah = ayahsForQiraah[nextIndex]
                    if boundaryModel.dividerBeforeAyah[nextAyah.id] != nil {
                        return nextAyah.id
                    }
                }
            }
            if boundaryModel.endDivider != nil {
                return ayahsForQiraah.last?.id
            }
            return nil
        }()
        let startOfSurahDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers else { return nil }
            if searchText.isEmpty { return boundaryModel?.startDivider }
            // Page/juz search: the surah's first ayah has no `dividerBeforeAyah` entry, so when the searched
            // page/juz is the one the surah begins on (first ayah is in the results), surface the start
            // divider too - otherwise the "Page X • Juz Y" header is missing for that first page.
            if isPageOrJuzSearch,
               let firstID = ayahsForQiraah.first?.id,
               filteredAyahs.contains(where: { $0.id == firstID }) {
                return boundaryModel?.startDivider
            }
            return nil
        }()
        let endOfSurahDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers, searchText.isEmpty else { return nil }
            return boundaryModel?.endOfSurahDivider
        }()
        let previousSurah = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? neighboringSurah(before: surah.id) : nil
        let nextSurah = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? neighboringSurah(after: surah.id) : nil
        // The floating page/juz overlay is always shown when boundary dividers exist; there is no
        // separate opt-in setting for it anymore.
        let shouldShowFloatingPageJuzOverlay = showBoundaryDividers && searchText.isEmpty
        let shouldUpdateFloatingPageJuzOverlay = shouldShowFloatingPageJuzOverlay && surah.pageOrJuzChangesWithinSurah
        let currentFloatingAyah = shouldUpdateFloatingPageJuzOverlay
            ? (firstVisibleAyahID
                .flatMap { visibleID in ayahByID[visibleID] }
                ?? ayahsForQiraah.first)
            : ayahsForQiraah.first
        let floatingDividerModel: BoundaryDividerModel? = {
            guard shouldShowFloatingPageJuzOverlay else { return nil }
            guard let currentFloatingAyah else { return nil }
            return overlayDividerByAyahID[currentFloatingAyah.id]
                ?? ayahsForQiraah.first.flatMap { overlayDividerByAyahID[$0.id] }
        }()
        let floatingDividerAnimationKey = floatingDividerModel.map(boundaryDividerID) ?? "none"
        let keywordDividerModels: [BoundaryDividerModel] = {
            guard let mode = dividerKeywordMode else { return [] }
            guard let boundaryModel else { return [] }

            var allDividerModels: [BoundaryDividerModel] = []

            if let start = boundaryModel.startDivider {
                allDividerModels.append(start)
            }

            for ayah in ayahsForQiraah {
                if let model = boundaryModel.dividerBeforeAyah[ayah.id] {
                    allDividerModels.append(model)
                }
            }

            if let end = boundaryModel.endDivider {
                allDividerModels.append(end)
            }

            var seen = Set<String>()
            return allDividerModels.filter { model in
                let matches: Bool
                let dedupeKey: String
                switch mode {
                case .page:
                    matches = model.text.localizedCaseInsensitiveContains("Page")
                    dedupeKey = model.text
                case .juz:
                    matches = model.text.localizedCaseInsensitiveContains("Juz")
                    dedupeKey = model.juzSegment
                        ?? (model.pageSegment.localizedCaseInsensitiveContains("Juz") ? model.pageSegment : model.text)
                }
                guard matches else { return false }
                return seen.insert(dedupeKey).inserted
            }
        }()
        let searchCount = isDividerKeywordSearch ? keywordDividerModels.count : filteredAyahs.count
        let syncVisibleAyahAnchor: () -> Void = {
            guard let nextVisibleAyahID = (visibleAyahIDs.union(visibleBoundaryAyahIDs)).min() else {
                return
            }

            guard nextVisibleAyahID != firstVisibleAyahID else { return }
            firstVisibleAyahID = nextVisibleAyahID
        }

        return
            List {
                Group {
                khatmProgressSection()
                qiraahNoticeSection()

                Section {
                    /*SurahRow(surah: surah, hideInfo: true).equatable()
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 0.45) {
                            settings.hapticFeedback()
                            surahInfoDialog = surahInfoDialog(for: surah)
                        }*/
                } header: {
                    // The surah header now lives in the always-pinned top safeAreaInset, so this section
                    // header only carries the search results-count pill (trailing, visible while searching).
                    if !searchText.isEmpty {
                        HStack {
                            Spacer()

                            Text(String(searchCount))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .conditionalGlassEffect()
                        }
                        .animation(.easeInOut, value: searchText)
                        .transition(.opacity)
                        .padding(.vertical, -12)
                    }
                }

                #if !os(watchOS)
                if let previousSurah {
                    Section {
                        surahNavigationButton(title: "Go to Previous Surah", surah: previousSurah, systemImage: "chevron.up")
                    }
                }
                #endif

                Section {
                    VStack {
                        let firstAyahClean = ayahsForQiraah.first?.textCleanArabic.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let showTaawwudh = (surah.id == 9) || (surah.id == 1 && firstAyahClean.hasPrefix("بسم"))
                        if showTaawwudh {
                            HeaderRow(
                                arabicText: "أَعُوذُ بِٱللَّهِ مِنَ ٱلشَّيۡطَانِ ٱلرَّجِيمِ",
                                englishTransliteration: "Audhu billahi minashaitanir rajeem",
                                englishTranslation: "I seek refuge in Allah from the accursed Satan."
                            )
                        } else {
                            HeaderRow(
                                arabicText: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِِ",
                                englishTransliteration: "Bismi Allahi alrrahmani alrraheemi",
                                englishTranslation: "In the name of Allah, the Compassionate, the Merciful."
                            )
                        }
                    }
                }

                if isDividerKeywordSearch {
                    ForEach(Array(keywordDividerModels.enumerated()), id: \.offset) { _, dividerModel in
                        Section {
                            if let bm = boundaryModel {
                                listBoundaryDivider(
                                    model: dividerModel,
                                    nextAyahID: scrollTargetAyahID(
                                        forDivider: dividerModel,
                                        boundaryModel: bm,
                                        ayahsForQiraah: ayahsForQiraah
                                    ),
                                    showAyahPreview: true
                                )
                            } else {
                                listBoundaryDivider(model: dividerModel, nextAyahID: nil)
                            }
                        }
                    }
                } else {
                    if let startOfSurahDivider {
                        Section {
                            listBoundaryDivider(model: startOfSurahDivider, nextAyahID: ayahsForQiraah.first?.id, showAyahLabel: false)
                        }
                        .onAppear {
                            firstBoundaryDividerOnScreen = true
                            if shouldUpdateFloatingPageJuzOverlay, let nextID = filteredAyahs.first?.id {
                                visibleBoundaryAyahIDs.insert(nextID)
                                syncVisibleAyahAnchor()
                            }
                        }
                        .onDisappear {
                            firstBoundaryDividerOnScreen = false
                            if shouldUpdateFloatingPageJuzOverlay, let nextID = filteredAyahs.first?.id {
                                visibleBoundaryAyahIDs.remove(nextID)
                                syncVisibleAyahAnchor()
                            }
                        }
                    }

                    ForEach(filteredAyahs, id: \.id) { ayah in
                        let dividerBefore = showBoundaryDividers ? boundaryModel?.dividerBeforeAyah[ayah.id] : nil

                        if let dividerBefore {
                            Section {
                                listBoundaryDivider(model: dividerBefore, nextAyahID: ayah.id, showAyahLabel: false)
                            }
                            .onAppear {
                                if shouldUpdateFloatingPageJuzOverlay {
                                    visibleBoundaryAyahIDs.insert(ayah.id)
                                    syncVisibleAyahAnchor()
                                }
                            }
                            .onDisappear {
                                if shouldUpdateFloatingPageJuzOverlay {
                                    visibleBoundaryAyahIDs.remove(ayah.id)
                                    syncVisibleAyahAnchor()
                                }
                            }
                        }

                        Group {
                            #if os(iOS)
                            Section {
                                AyahRow(
                                    surah: surah,
                                    ayah: ayah,
                                    renderSettingsSignature: ayahRowRenderSettingsSignature,
                                    scrollDown: $scrollDown,
                                    searchText: $searchText,
                                    onAyahTextAppear: {
                                        visibleAyahIDs.insert(ayah.id)
                                        markKhatmViewedIfNeeded(ayah.id)
                                        syncVisibleAyahAnchor()
                                    },
                                    onAyahTextDisappear: {
                                        visibleAyahIDs.remove(ayah.id)
                                        syncVisibleAyahAnchor()
                                    }
                                )
                                .equatable()
                            }
                            #else
                            AyahRow(
                                surah: surah,
                                ayah: ayah,
                                renderSettingsSignature: ayahRowRenderSettingsSignature,
                                scrollDown: $scrollDown,
                                searchText: $searchText,
                                onAyahTextAppear: {
                                    visibleAyahIDs.insert(ayah.id)
                                    markKhatmViewedIfNeeded(ayah.id)
                                    syncVisibleAyahAnchor()
                                },
                                onAyahTextDisappear: {
                                    visibleAyahIDs.remove(ayah.id)
                                    syncVisibleAyahAnchor()
                                }
                            )
                            .equatable()
                            #endif
                        }
                        .id(ayah.id)
                        #if os(watchOS)
                        .padding(.vertical)
                        #endif
                    }

                    if let endOfSurahDivider {
                        Section {
                            listBoundaryDivider(model: endOfSurahDivider, nextAyahID: nil)
                        }
                    }

                    #if !os(watchOS)
                    if let nextSurah {
                        Section {
                            surahNavigationButton(title: "Go to Next Surah", surah: nextSurah, systemImage: "chevron.down")
                        }
                    }
                    #endif

                    if let trailingSearchBoundaryDivider {
                        Section {
                            listBoundaryDivider(
                                model: trailingSearchBoundaryDivider,
                                nextAyahID: trailingSearchBoundaryScrollTarget,
                                showAyahLabel: false
                            )
                        }
                    }
                }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle(disableNowPlayingInset: true, topContentMargin: 11)
            .compactListSectionSpacing()
            #if os(iOS)
            .onChange(of: scrollDown) { value in
                guard let target = value else { return }
                if !searchText.isEmpty {
                    settings.hapticFeedback()
                    pendingScrollAfterSearchClear = target
                    withAnimation {
                        searchText = ""
                        self.endEditing()
                    }
                } else {
                    DispatchQueue.main.async {
                        withAnimation { proxy.scrollTo(target, anchor: .top) }
                    }
                }
                scrollDown = nil
            }
            .onChange(of: searchText) { newValue in
                guard newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let target = pendingScrollAfterSearchClear else { return }
                pendingScrollAfterSearchClear = nil
                DispatchQueue.main.async {
                    withAnimation { proxy.scrollTo(target, anchor: .top) }
                }
            }
            #endif
            .onAppear {
                rebuildQiraahCaches()
                // Always open at the requested ayah (or the top for a whole-surah open). Navigating to a
                // surah/ayah should refresh to that target rather than restoring wherever the user last
                // scrolled on a previous visit.
                let target = ayah.flatMap { nearestExistingAyahID($0, in: ayahsForQiraah.map { $0.id }) }
                if let target {
                    firstVisibleAyahID = target
                    if !didScrollDown {
                        didScrollDown = true
                        scrollToAyah(target, proxy: proxy)
                    }
                } else if firstVisibleAyahID == nil {
                    firstVisibleAyahID = ayahsForQiraah.first?.id
                }
            }
            .onChange(of: quranPlayer.currentAyahNumber) { newVal in
                if let id = newVal, surah.id == quranPlayer.currentSurahNumber {
                    withAnimation { proxy.scrollTo(id, anchor: .top) }
                }
            }
            .onChange(of: settings.displayQiraah) { _ in
                cacheQiraahKey = ""
                qiraahCacheSurahID = nil
                rebuildQiraahCaches()
                visibleAyahIDs.removeAll()
                visibleBoundaryAyahIDs.removeAll()
            }
            .onChange(of: surah.id) { _ in
                rebuildQiraahCaches()
                visibleAyahIDs.removeAll()
                visibleBoundaryAyahIDs.removeAll()
                didScrollDown = false
                let prepared = Self.preparedCache(for: surah, settings: settings)
                if let sel = ayah, let target = nearestExistingAyahID(sel, in: prepared.ayahs.map { $0.id }) {
                    firstVisibleAyahID = target
                    scrollToAyah(target, proxy: proxy)
                } else if let top = prepared.ayahs.first?.id {
                    firstVisibleAyahID = top
                    scrollToAyah(top, proxy: proxy)
                }
            }
            .onChange(of: ayah) { newValue in
                guard let newValue,
                      let target = nearestExistingAyahID(newValue, in: cachedAyahsForQiraah.map { $0.id }) else { return }
                firstVisibleAyahID = target
                didScrollDown = true
                scrollToAyah(target, proxy: proxy)
            }
            #if os(iOS)
            // Always-pinned header (safeAreaInset, not overlay): it reserves space so list content - and
            // the search results-count pill - sits below it rather than being hidden behind it.
            .safeAreaInset(edge: .top, spacing: 0) {
                // Drop the page/juz line from the pinned header while the surah's first divider is on screen
                // (it would just duplicate what's visible); it returns once that divider scrolls away.
                floatingHeaderOverlay(
                    floatingDividerModel: firstBoundaryDividerOnScreen ? nil : floatingDividerModel,
                    floatingDividerAnimationKey: firstBoundaryDividerOnScreen ? "none" : floatingDividerAnimationKey
                )
            }
            .safeAreaInset(edge: .bottom) {
                let active = quranPlayer.isPlaying || quranPlayer.isPaused
                // Insert/remove the bar on isPlaying||isPaused with `.animation` so SwiftUI animates BOTH the
                // fade (the bar's `.transition`) and the height collapse natively. The bar keeps its content
                // while fading out via `retainedContext`, and "Stop Playing" defers `stop()`, so closing works.
                VStack(spacing: 0) {
                    qiraatAndTajweedControls

                    if active {
                        nowPlayingInset(proxy: proxy)
                            .padding(.horizontal, 24)
                            .padding(.top, SafeAreaInsetVStackSpacing.standard)
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 7)
                .background(Color.white.opacity(0.00001))
                .animation(.easeInOut, value: active)
            }
            .adaptiveSafeArea(edge: .bottom) {
                bottomInsetContent(proxy: proxy)
            }
            .confirmationDialog("Convert Qiraah to Hafs an Asim?", isPresented: $confirmConvertQiraahToHafs, titleVisibility: .visible) {
                Button("Yes") {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.displayQiraah = Settings.Riwayah.hafsTag
                    }
                }

                Button("No") {
                    settings.hapticFeedback()
                }
            } message: {
                Text("Are you sure? This will convert the qiraah back to Hafs an Asim.")
            }
            #else
            .confirmationDialog("Convert Qiraah to Hafs an Asim?", isPresented: $confirmConvertQiraahToHafs, titleVisibility: .visible) {
                Button("Yes") {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.displayQiraah = Settings.Riwayah.hafsTag
                    }
                }

                Button("No") {
                    settings.hapticFeedback()
                }
            } message: {
                Text("Are you sure? This will convert the qiraah back to Hafs an Asim.")
            }
            #endif
    }

    @ViewBuilder
    private func khatmProgressSection() -> some View {
        if shouldShowKhatmProgress {
            Section {
                if settings.isHafsDisplay {
                    VStack(alignment: .leading, spacing: 10) {
                        Color.clear.frame(height: 0).onAppear { computeKhatmOverviewIfNeeded(force: false) }

                        HStack(alignment: .firstTextBaseline) {
                            Label("\(khatmCompletedAyahCount)/\(surah.numberOfAyahs) ayahs", systemImage: khatmCompletedAyahCount >= surah.numberOfAyahs ? "checkmark.circle.fill" : "circle.dashed")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color.opacity(khatmCompletedAyahCount > 0 ? 1 : 0.65))

                            Spacer()

                            Text("\(khatmCompletionPercent)%")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: Double(khatmCompletedAyahCount), total: Double(max(surah.numberOfAyahs, 1)))
                            .tint(settings.accentColor.color)

                        HStack {
                            Text("Overall: \(khatmOverviewPercent)% completed")
                                .font(.subheadline)
                                .foregroundStyle(settings.accentColor.color)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    // Khatm tracking is Hafs-only (see `markKhatmAyahComplete` / `isKhatmAyahComplete`, both
                    // guarded by `isHafsDisplay`). On any other riwayah the bar would just sit at 0, so say
                    // why instead of showing a dead progress bar. The riwayah notice below has the switch button.
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(settings.accentColor.color)

                        Text("Khatm progress is only tracked on Hafs an Asim. Switch back to the default riwayah below to track this reading.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("KHATM PROGRESS")
            }
            .onReceive(settings.objectWillChange) { _ in computeKhatmOverviewIfNeeded(force: false) }
        }
    }

    @ViewBuilder
    private func qiraahNoticeSection() -> some View {
        if !settings.isHafsDisplay {
            let option = Settings.Riwayah.option(for: settings.displayQiraah)
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "character.book.closed.fill.ar")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(settings.accentColor.color)
                            .frame(width: 34, height: 34)
                            .background(settings.accentColor.color.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Current Riwayah")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            HStack {
                                Text(option.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text(option.arabic)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                            }
                        }

                        Spacer(minLength: 0)
                    }

                    Button {
                        settings.hapticFeedback()
                        confirmConvertQiraahToHafs = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Use Default Hafs an Asim")
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(settings.accentColor.color.opacity(0.11), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func computeKhatmOverviewIfNeeded(force: Bool = false) {
        let totalCompleted = settings.khatmTotalCompleted(in: quranData.quran)
        guard force || totalCompleted != khatmOverviewLastSignature else { return }
        khatmOverviewLastSignature = totalCompleted

        let totalAyahs = quranData.quran.reduce(0) { $0 + $1.numberOfAyahs }
        khatmOverviewPercent = totalAyahs > 0 ? Int((Double(totalCompleted) / Double(totalAyahs) * 100).rounded()) : 0
    }



    private func floatingHeaderOverlay(
        floatingDividerModel: BoundaryDividerModel?,
        floatingDividerAnimationKey: String
    ) -> some View {
        VStack(spacing: 2) {
            SurahSectionHeader(surah: surah)

            if let floatingDividerModel {
                boundaryDivider(model: floatingDividerModel, isOverlay: true)
                    .id(boundaryDividerID(floatingDividerModel))
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .animation(.easeInOut(duration: 0.18), value: floatingDividerAnimationKey)

                // The label already says "(3/10)"; this makes that fraction legible at a glance, so you can
                // see how far through the surah's pages you are without reading the numbers. Same meter the
                // mushaf page footer uses, so the two reading modes agree.
                if let position = floatingDividerModel.pageInSurah,
                   let total = floatingDividerModel.surahPageCount,
                   total > 1 {
                    TrackedBar(
                        fraction: CGFloat(position) / CGFloat(total),
                        height: 3,
                        color: settings.accentColor.color
                    )
                    .padding(.horizontal, 2)
                    .padding(.bottom, 2)
                    .transition(.opacity)
                }
            }
        }
        // Animate the page/juz line appearing/disappearing (it shows once the first divider scrolls off,
        // and updates as you move between pages) using the transition above.
        .animation(.easeInOut(duration: 0.2), value: floatingDividerModel != nil)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 0)
        // When both the surah header and the page/juz divider are stacked, use a rounded rectangle;
        // a lone header reads better as a capsule.
        .conditionalGlassEffect(rectangle: true)
        .padding(.top, 4)
        .padding(.horizontal, settings.defaultView ? 20 : 16)
        .zIndex(1)
    }

    #if os(iOS)
    private func bottomInsetContent(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            playbackAndSearchControls(proxy: proxy)
        }
    }

    @ViewBuilder
    private var qiraatAndTajweedControls: some View {
        let tajweedCanRenderNow = settings.showTajweedColors
            && settings.showArabicText
            && settings.isHafsDisplay

        if settings.qiraatComparisonMode || tajweedCanRenderNow {
            HStack(alignment: .bottom, spacing: 8) {
                if tajweedCanRenderNow {
                    TajweedLegendMenu()
                }

                Spacer()

                if settings.qiraatComparisonMode {
                    ArabicTextRiwayahPicker(selection: $settings.displayQiraah.animation(.easeInOut))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func playbackAndSearchControls(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            HStack(spacing: 0) {
                SearchBar(
                    // Animate the filtered results only when the user types (binding-scoped), so the
                    // list transition eases without the List-level animation that breaks scroll restoration.
                    text: $searchText.animation(.easeInOut),
                    onFocusChanged: { focused in
                        withAnimation {
                            isAyahSearchFocused = focused
                        }
                    }
                )

                playButton(proxy: proxy)
                    .padding(.bottom, 2)
            }
            .padding([.leading, .top], -8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .background(Color.white.opacity(0.00001))
        .animation(.easeInOut, value: quranPlayer.isPlaying)
    }
    #endif

    @ViewBuilder
    private func nowPlayingInset(proxy: ScrollViewProxy) -> some View {
        NowPlayingView(quranView: false)
            .onTapGesture {
                guard
                    let curSurah = quranPlayer.currentSurahNumber,
                    let curAyah = quranPlayer.currentAyahNumber,
                    curSurah == surah.id
                else { return }

                settings.hapticFeedback()

                if !searchText.isEmpty {
                    withAnimation {
                        searchText = ""
                        self.endEditing()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation { proxy.scrollTo(curAyah, anchor: .top) }
                    }
                } else {
                    withAnimation { proxy.scrollTo(curAyah, anchor: .top) }
                }
            }
    }

    #if os(iOS)
    @ViewBuilder
    private func playButton(proxy: ScrollViewProxy) -> some View {
        let playerIdle = !quranPlayer.isLoading && !quranPlayer.isPlaying && !quranPlayer.isPaused
        let canResumeLast = settings.lastListenedSurah?.surahNumber == surah.id
        let repeatCounts  = [20, 15, 10, 5, 3, 2]

        if playerIdle {
            Menu {
                Text("Surah Playback")
                    .foregroundStyle(.secondary)

                if canResumeLast, let last = settings.lastListenedSurah {
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playSurah(
                            surahNumber: last.surahNumber,
                            surahName: last.surahName,
                            certainReciter: true
                        )
                    } label: {
                        Label("Play Last Listened", systemImage: "play.fill")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: surah.id,
                        surahName: surah.nameTransliteration
                    )
                } label: {
                    Label(canResumeLast ? "Play from Beginning" : "Play Surah", systemImage: "memories")
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(
                        surahNumber: surah.id,
                        ayahNumber: 1,
                        continueRecitation: true
                    )
                } label: {
                    Label("Play Ayah by Ayah", systemImage: "list.number")
                }

                Button {
                    settings.hapticFeedback()
                    showReciterPickerSheet = true
                } label: {
                    Label("Choose Reciter", systemImage: "headphones")
                }

                Menu {
                    Text("More Playback")
                        .foregroundStyle(.secondary)

                    Button {
                        settings.hapticFeedback()
                        showCustomRangeSheet = true
                    } label: {
                        Label("Play Custom Range", systemImage: "slider.horizontal.3")
                    }

                    Button {
                        settings.hapticFeedback()
                        let ayahsForQiraah = surah.ayahs.filter { $0.existsInQiraah(settings.displayQiraahForArabic) }
                        if let randomAyah = ayahsForQiraah.randomElement() {
                            quranPlayer.playAyah(
                                surahNumber: surah.id,
                                ayahNumber: randomAyah.id,
                                continueRecitation: true
                            )
                        }
                    } label: {
                        Label("Play Random Ayah", systemImage: "shuffle.circle")
                    }

                    Button {
                        settings.hapticFeedback()
                        playRandomReciterForCurrentSurah()
                    } label: {
                        Label("Play Random Reciter", systemImage: "person.wave.2")
                    }

                    Menu {
                        Text("Repeat Count")
                            .foregroundStyle(.secondary)

                        ForEach(repeatCounts, id: \.self) { n in
                            Button {
                                settings.hapticFeedback()
                                quranPlayer.playSurah(
                                    surahNumber: surah.id,
                                    surahName: surah.nameTransliteration,
                                    repeatCount: n
                                )
                            } label: {
                                Label("Repeat \(n)×", systemImage: "\(n).circle")
                            }
                        }
                    } label: {
                        Label("Repeat Surah", systemImage: "repeat")
                    }
                } label: {
                    Label("Other Options", systemImage: "ellipsis.circle")
                }
            } label: {
                playbackMenuControlLabel {
                    playIcon()
                }
            }
        } else {
            Button {
                settings.hapticFeedback()
                // A tap while loading OR playing fully stops playback. Previously a loading tap only paused
                // the in-flight load, which could resume once the item became ready (so it "did nothing").
                quranPlayer.stop()
            } label: {
                playbackMenuControlLabel {
                    playIcon()
                }
            }
        }
    }

    private func playbackMenuControlLabel<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(width: 27, height: 27)
            .padding()
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .conditionalGlassEffect()
    }

    private func playRandomReciterForCurrentSurah() {
        guard let randomReciter = reciters.randomElement() else { return }
        settings.setSelectedReciter(randomReciter)
        quranPlayer.playSurah(
            surahNumber: surah.id,
            surahName: surah.nameTransliteration
        )
    }

    @ViewBuilder
    private func playIcon() -> some View {
        if quranPlayer.isLoading {
            RotatingGearView().transition(.opacity)
        } else if quranPlayer.isPlaying || quranPlayer.isPaused {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(settings.accentColor.color)
                .transition(.opacity)
        } else {
            Image(systemName: "play.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(settings.accentColor.color)
                .transition(.opacity)
        }
    }

    /// The title is a `Menu`. Note that a Menu sizes its label to the label's *intrinsic* width, so
    /// `surahTitleLabel` must stay intrinsically sized - an expanding `Spacer()` in there collapses to nothing
    /// and squeezes the whole title into a pill.
    private var surahTitlePickerButton: some View {
        Menu {
            Button {
                settings.hapticFeedback()
                showSurahPickerSheet = true
            } label: {
                Label("Choose Surah", systemImage: "list.bullet")
            }

            Button {
                settings.hapticFeedback()
                showSurahInfoSheet = true
            } label: {
                Label("Surah Info", systemImage: "info.circle")
            }

            Button {
                settings.hapticFeedback()
                surahInfoDialog = surahInfoDialog(for: displayedSurah)
            } label: {
                Label("Revelation Info", systemImage: "book.closed")
            }

            Divider()

            // Playback lives on the play control in the footer, not up here.
            Button {
                toggleReadingMode()
            } label: {
                Label(settings.quranPageMode ? "Read as List" : "Read as Pages",
                      systemImage: settings.quranPageMode ? "list.bullet.rectangle" : "book")
            }

            // Page mode only: what the page's BODY text is. Arabic is the mushaf itself; the English options
            // replace the page wholesale (same page boundaries, same fit-to-page) for a reader following
            // along in Latin script. Headings follow the page's language automatically.
            if settings.quranPageMode {
                Menu {
                    Picker("Page Text", selection: $settings.mushafPageLanguage) {
                        ForEach(MushafPageLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                } label: {
                    Label("Page Text: \(settings.resolvedMushafPageLanguage.displayName)",
                          systemImage: "character.book.closed")
                }
            }
        } label: {
            surahTitleLabel
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private var surahTitleLabel: some View {
        let surah = displayedSurah
        return Group {
            VStack(spacing: 0) {
                // A fixed gap, NOT a `Spacer()`: the Menu wrapping this label sizes it to its intrinsic width,
                // and an expanding Spacer collapses to zero there - which is what shrank the title to a pill.
                HStack(spacing: 10) {
                    HStack {
                        // The Latin side never shrinks - a scaled-down transliteration next to full-size
                        // Arabic reads as a mistake. It truncates instead.
                        Text("\(surah.id)")
                            .font(.subheadline.bold())
                            .foregroundColor(settings.accentColor.color)
                            .lineLimit(1)

                        Text(surah.nameTransliteration)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                    }

                    HStack {
                        // Arabic scales down rather than truncating: a clipped Arabic name is unreadable,
                        // where a smaller one is not.
                        Text(surah.nameArabic)
                            .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 2))
                            .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                            .lineLimit(1)

                        Text(surah.idArabic)
                            .font(.custom(Settings.hafsUthmaniFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 3))
                            .arabicFontDesign(custom: true)
                            .foregroundColor(settings.accentColor.color)
                            .lineLimit(1)
                    }
                }

                Text(surah.nameEnglish)
                    .font(.caption2)
                    .lineLimit(1)
                    .padding(.top, -8)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.primary)
            .contentShape(Rectangle())
            .padding(.horizontal)
            .padding(.bottom, 6)
            .conditionalGlassEffect()
        }
    }

    private var navBarTitle: some View {
        Button {
            settings.hapticFeedback()
            showingSettingsSheet = true
        } label: {
            Image(systemName: "gear")
        }
        .tint(settings.accentColor.accent2)
    }

    /// Hands the search off to the Quran tab, which owns the whole-Quran search (see `QuranSearchHandoff`).
    ///
    /// This is the mushaf's ONLY search - it has no search bar of its own and there is nowhere sensible to put
    /// one on a fixed-size page. In the list reader it sits alongside the in-surah search bar and answers the
    /// other question: "not in this surah - find it anywhere." Either way the hit rows navigate straight back
    /// into the reading mode the user is already in.
    private var searchQuranButton: some View {
        Button {
            settings.hapticFeedback()
            // The list reader carries whatever is already typed into the surah search over with it; the mushaf
            // has nothing typed, so it opens the search empty.
            QuranSearchHandoff.shared.request(settings.quranPageMode ? "" : searchText)
        } label: {
            Image(systemName: "magnifyingglass")
        }
        .accessibilityLabel("Search the whole Quran")
        .tint(settings.accentColor.accent1)
    }

    @ViewBuilder
    private func applySurahToolbar(to base: some View) -> some View {
        base.toolbar {
            ToolbarItem(placement: .principal) {
                surahTitlePickerButton
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                searchQuranButton
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                navBarTitle
            }
        }
    }

    @ViewBuilder
    private var selectedSurahNavigationDestination: some View {
        if let targetID = selectedSurahNavigation,
           let targetSurah = quranData.surah(targetID) {
            SurahView(surah: targetSurah)
        } else {
            EmptyView()
        }
    }

    private var settingsSheet: some View {
        NavigationView { SettingsQuranView(presentedAsSheet: true) }
    }
    #endif

    /// The ayah currently anchored at the top of the screen (falling back through the last known anchor).
    private func currentReadingAyahID() -> Int? {
        visibleAyahIDs.min()
            ?? firstVisibleAyahID
            ?? ayah
            ?? cachedAyahsForQiraah.first?.id
    }

    /// Cheap, in-memory only: records where the user is so a re-appear (e.g. after Control Center) can
    /// restore the spot without the expensive `settings` write that `saveLastRead()` performs.
    private func rememberCurrentVisibleAyah() {
        guard let targetAyah = currentReadingAyahID() else { return }
        rememberVisibleAyahID(targetAyah)
    }

    private func saveLastRead() {
        guard let targetAyah = currentReadingAyahID() else { return }
        rememberVisibleAyahID(targetAyah)

        guard settings.saveLastReadAyah else { return }

        if settings.lastReadSurah == surah.id, settings.lastReadAyah == targetAyah {
            return
        }

        settings.lastReadSurah = surah.id
        settings.lastReadAyah = targetAyah
        settings.refreshQuranWidgets()
    }

    private func neighboringSurah(before currentSurahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == currentSurahID }), index > 0 else { return nil }
        return quranData.quran[index - 1]
    }

    private func neighboringSurah(after currentSurahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == currentSurahID }), index + 1 < quranData.quran.count else { return nil }
        return quranData.quran[index + 1]
    }

    /// Flips between the ayah list and the mushaf, landing on the same place in the text rather than at the
    /// top of the surah:
    ///
    /// * list → page: opens the page that holds the ayah currently at the top of the screen. Reading ayah 40
    ///   of a surah that starts on page 95 opens page 100, not 95.
    /// * page → list: opens at the first ayah of the page you were on - and swaps the surah in place when that
    ///   page belongs to a different one (mushaf pages run across surah boundaries).
    private func toggleReadingMode() {
        settings.hapticFeedback()

        if settings.quranPageMode {
            if let anchor = pageAnchor {
                if anchor.surahID != surah.id, let anchorSurah = quranData.surah(anchor.surahID) {
                    searchText = ""
                    pendingScrollAfterSearchClear = nil
                    scrollDown = nil
                    visibleAyahIDs.removeAll()
                    visibleBoundaryAyahIDs.removeAll()
                    settings.recordSurahOpened(anchorSurah.id)
                    swappedSurah = anchorSurah
                }
                firstVisibleAyahID = anchor.ayahID
                modeSwitchAyah = anchor.ayahID
                // The list reader only performs its opening scroll once per surah; this is a fresh open.
                didScrollDown = false
            }
            pageSurah = nil
        } else {
            modeSwitchAyah = currentReadingAyahID()
        }

        withAnimation { settings.quranPageMode.toggle() }
    }

    private func navigateToSurah(_ targetSurah: Surah) {
        guard targetSurah.id != surah.id else { return }
        settings.hapticFeedback()

        // Reset the per-surah reading state either way.
        searchText = ""
        pendingScrollAfterSearchClear = nil
        scrollDown = nil
        visibleAyahIDs.removeAll()
        visibleBoundaryAyahIDs.removeAll()
        firstVisibleAyahID = nil
        // A surah swap opens at its own target (the top), so a stale mode-switch anchor must not win.
        modeSwitchAyah = nil

        if let onSelectSurah {
            // Column navigation: the parent owns the detail, so let it swap the surah.
            onSelectSurah(targetSurah.id)
        } else {
            // Stack navigation: swap the surah in place rather than pushing a whole new SurahView.
            pageSurah = nil
            settings.recordSurahOpened(targetSurah.id)
            withAnimation(.easeInOut) {
                swappedSurah = targetSurah
            }
        }
    }

    @ViewBuilder
    private func surahNavigationButton(title: String, surah targetSurah: Surah, systemImage: String) -> some View {
        Button {
            navigateToSurah(targetSurah)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 22)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(targetSurah.id) - \(targetSurah.nameTransliteration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .contentShape(Rectangle())
        }
    }
}

struct RotatingGearView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "gear")
            #if os(iOS)
            .font(.title3)
            #else
            .font(.subheadline)
            #endif
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                // Decorative spinner: skipped in Low Power Mode (renders as a static glyph).
                guard !AppPerformance.isLowPowerMode else { return }
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#if os(iOS)
private struct SurahPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    @State private var searchText = ""
    let currentSurahID: Int
    let onSelect: (Surah) -> Void

    private var filteredSurahs: [Surah] {
        let query = normalized(searchText)
        guard !query.isEmpty else { return quranData.quran }

        return quranData.quran.filter { surah in
            let tokens = [
                "\(surah.id)",
                normalized(surah.nameEnglish),
                normalized(surah.nameTransliteration),
                normalized(surah.nameArabic)
            ]
            return tokens.contains { $0.contains(query) }
        }
    }

    private func adjacentSurah(before surahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == surahID }), index > 0 else { return nil }
        return quranData.quran[index - 1]
    }

    private func adjacentSurah(after surahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == surahID }), index + 1 < quranData.quran.count else { return nil }
        return quranData.quran[index + 1]
    }

    private func select(_ surah: Surah) {
        onSelect(surah)
        dismiss()
    }

    private func scrollToCurrentSurah(_ proxy: ScrollViewProxy) {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard filteredSurahs.contains(where: { $0.id == currentSurahID }) else { return }

        let requestScroll = {
            withAnimation(.easeInOut) {
                proxy.scrollTo(currentSurahID, anchor: .center)
            }
        }

        DispatchQueue.main.async {
            requestScroll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                requestScroll()
            }
        }
    }

    private var ayahHighlightBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, watchOS 26.0, *) {
            return -11
        }
        return -2
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                List {
                    Group {
                        ForEach(filteredSurahs, id: \.id) { surah in
                            Section {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(
                                            surah.id == currentSurahID
                                            ? settings.accentColor.color.opacity(0.15)
                                            : .clear
                                        )
                                        .padding(.horizontal, -12)
                                        .padding(.vertical, ayahHighlightBackgroundVerticalPadding)

                                    Button {
                                        settings.hapticFeedback()
                                        withAnimation {
                                            select(surah)
                                        }
                                    } label: {
                                        SurahRow(surah: surah, hideInfo: settings.showSurahInformation)
                                            .contentShape(Rectangle())
                                    }
                                    .id(surah.id)
                                }
                            }
                        }
                    }
                    .themedListRowBackground()
                }
                .applyConditionalListStyle()
                .compactListSectionSpacing()
                .searchable(text: $searchText.animation(.easeInOut), prompt: "Search surah")
                .navigationTitle("Choose Surah")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            settings.hapticFeedback()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                        }
                        .tint(settings.accentColor.color)
                    }
                }
                .onAppear {
                    scrollToCurrentSurah(proxy)
                }
                .onChange(of: searchText) { _ in
                    guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    scrollToCurrentSurah(proxy)
                }
                .onChange(of: filteredSurahs.count) { _ in scrollToCurrentSurah(proxy) }
            }
        }
    }

    private func normalized(_ text: String) -> String {
        settings.cleanSearch(text, whitespace: true)
    }
}
#endif

struct ArabicTextRiwayahPicker: View {
    @ObservedObject private var settings = Settings.shared

    @Binding var selection: String
    var useSimpleIOSPicker: Bool = false

    private static let options: [Settings.Riwayah.Option] = Settings.Riwayah.options

    private var currentLabel: String {
        let tag = Settings.normalizeLegacyRiwayahTag(selection)
        return Self.options.first(where: { $0.tag == tag })?.label ?? "Arabic Riwayah"
    }

    var body: some View {
        #if os(iOS)
        if useSimpleIOSPicker {
            Picker("Arabic Riwayah", selection: $selection.animation(.easeInOut)) {
                ForEach(Settings.Riwayah.groups) { group in
                    Section {
                        ForEach(group.options, id: \.tag) { option in
                            Text(option.label).tag(option.tag)
                        }
                    } header: {
                        Text("\(group.teacher) - \(group.teacherArabic)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: selection) { _ in settings.hapticFeedback() }
        } else {
            Menu {
                Text("Arabic Riwayah")
                    .foregroundStyle(.secondary)

                ForEach(Settings.Riwayah.groups) { group in
                    ForEach(group.options, id: \.tag) { option in
                        qiraahButton(option)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(currentLabel)
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(settings.accentColor.color.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 0)
                .conditionalGlassEffect()
            }
        }
        #else
        Picker("Arabic Riwayah", selection: $selection.animation(.easeInOut)) {
            ForEach(Settings.Riwayah.groups) { group in
                Section {
                    ForEach(group.options, id: \.tag) { option in
                        Text(option.label).tag(option.tag)
                    }
                } header: {
                    Text("\(group.teacher) - \(group.teacherArabic)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: selection) { _ in settings.hapticFeedback() }
        #endif
    }

    @ViewBuilder
    private func qiraahButton(_ option: Settings.Riwayah.Option) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                selection = option.tag
            }
        } label: {
            HStack {
                if option.tag == Settings.normalizeLegacyRiwayahTag(selection) {
                    Image(systemName: "checkmark")
                }

                Text(option.label)
            }
            .font(.caption)
        }
    }
}

#if os(iOS)
private struct TajweedLegendMenu: View {
    @ObservedObject private var settings = Settings.shared

    @State private var showingSheet = false

    var expandsToFillRow: Bool = false

    var body: some View {
        Button {
            settings.hapticFeedback()
            showingSheet = true
        } label: {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach([Color.red, .orange, .yellow, .green, .blue], id: \.self) { item in
                        Circle()
                            .fill(item)
                            .frame(width: 5, height: 5)
                    }
                }

                Text("Legend")
                    .font(.caption)
                    .foregroundColor(settings.accentColor.color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .shadow(color: .primary.opacity(0.25), radius: 2, x: 0, y: 0)
            .conditionalGlassEffect()
        }
        .sheet(isPresented: $showingSheet) {
            NavigationView {
                TajweedLegendView()
            }
            .smallMediumSheetPresentation()
        }
    }
}

// MARK: - Page mode

/// A mushaf page: every ayah printed on absolute page `page`, grouped into runs by surah so a page that
/// straddles a surah boundary can draw a divider where the surah changes.
struct MushafPage: Identifiable {
    struct Segment: Identifiable {
        let surah: Surah
        let ayahs: [Ayah]

        var id: Int { surah.id }
    }

    let page: Int
    let segments: [Segment]

    var id: Int { page }

    var firstSurah: Surah? { segments.first?.surah }
    var firstAyah: Ayah? { segments.first?.ayahs.first }
    var juz: Int? { firstAyah?.juz }

    /// The surah a page is labelled with (toolbar title, pinned header, footer meter): always the **top**
    /// surah on the page - the one the page opens with. On a page holding Al-Ikhlas, Al-Falaq and An-Nas,
    /// that is Al-Ikhlas (112), not whichever happens to have the most ayahs.
    var displayedSurah: Surah? { firstSurah }
}

/// The whole mushaf as swipeable pages: each page holds every ayah printed on it - across surah boundaries - 
/// as one continuous block of Arabic, the way a printed mushaf sets them. Shown in place of the ayah list
/// when `settings.quranPageMode` is on. Swiping left/right moves through the mushaf continuously; reaching the
/// end of a surah simply carries you into the next one.
/// Mushaf pagination, kept OUTSIDE the (generic) reader: a generic type cannot hold static stored properties,
/// and the page cache must be shared across every instantiation anyway.
@MainActor
enum MushafPagination {
    /// Paginating all 6,236 ayahs is not free, so do it once per (qiraah, quran-size) and reuse. Keyed by
    /// qiraah because ayahs missing from a qiraah are dropped, which changes what lands on each page.
    private static var pageCache: (key: String, pages: [MushafPage])?

    static func pages(quran: [Surah], qiraah: String?) -> [MushafPage] {
        let key = "\(qiraah ?? "Hafs")|\(quran.count)"
        if let cached = pageCache, cached.key == key { return cached.pages }

        var pages: [MushafPage] = []
        // Surahs and their ayahs are already in mushaf order, so a page's segments accumulate in order too:
        // extend the trailing segment when the surah repeats, else start a new one.
        for surah in quran {
            for ayah in surah.ayahs where ayah.existsInQiraah(qiraah) {
                guard let page = ayah.page else { continue }

                if var last = pages.last, last.page == page {
                    var segments = last.segments
                    if let lastSegment = segments.last, lastSegment.surah.id == surah.id {
                        segments[segments.count - 1] = MushafPage.Segment(surah: surah, ayahs: lastSegment.ayahs + [ayah])
                    } else {
                        segments.append(MushafPage.Segment(surah: surah, ayahs: [ayah]))
                    }
                    last = MushafPage(page: page, segments: segments)
                    pages[pages.count - 1] = last
                } else {
                    pages.append(MushafPage(page: page, segments: [MushafPage.Segment(surah: surah, ayahs: [ayah])]))
                }
            }
        }

        pageCache = (key, pages)
        return pages
    }

    /// For each juz, the ordinal of its first page and how many pages it spans, so a page can show its
    /// position within the current juz. Pages are in mushaf order, so the first occurrence is the start.
    static func juzRanges(_ pages: [MushafPage]) -> [Int: (start: Int, count: Int)] {
        var map: [Int: (start: Int, count: Int)] = [:]
        for (index, page) in pages.enumerated() {
            guard let juz = page.juz else { continue }
            if let existing = map[juz] {
                map[juz] = (existing.start, existing.count + 1)
            } else {
                map[juz] = (index, 1)
            }
        }
        return map
    }
}

struct SurahPageReader<Controls: View>: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared

    /// The surah the reader was opened from, and the ayah within it (a bookmark, a search hit, last-read).
    /// Together they decide the starting page; after that the reader is no longer bound to this surah.
    let surah: Surah
    var initialAyah: Int?
    /// Fires whenever the visible page belongs to a different surah, so the navigation title can follow the
    /// reader across surah boundaries instead of naming the surah it was opened from forever.
    var onSurahChange: ((Surah) -> Void)?
    /// Fires with the first surah + ayah of the page on screen. That's the anchor the list reader opens at
    /// when the user switches back out of page mode.
    var onPageAnchor: ((Int, Int) -> Void)?
    /// The optional tajweed/qiraah controls and the mini player. The reader owns the ordering: these sit
    /// ABOVE the page-navigation footer, which is applied last so it stays pinned at the very bottom.
    @ViewBuilder var bottomControls: () -> Controls

    @Environment(\.layoutDirection) private var layoutDirection

    /// Which jump-to picker is unfolded above the footer, if any.
    enum PickerTarget { case page, juz }

    @State private var pageIndex = 0
    @State private var didSetInitialPage = false
    @State private var activePicker: PickerTarget?
    @State private var pagePickerSelection = 0
    @State private var juzPickerSelection = 1

    /// Where to land when the reader opens: the page holding `initialAyah` of the surah we came from, else
    /// the page holding the last-read ayah, else that surah's first page.
    private func startingPageIndex(in pages: [MushafPage]) -> Int {
        let targetAyah = initialAyah
            ?? (settings.lastReadSurah == surah.id && settings.lastReadAyah > 0 ? settings.lastReadAyah : nil)

        if let targetAyah,
           let index = pages.firstIndex(where: { page in
               page.segments.contains { $0.surah.id == surah.id && $0.ayahs.contains { $0.id == targetAyah } }
           }) {
            return index
        }

        return pages.firstIndex { $0.segments.contains { $0.surah.id == surah.id } } ?? 0
    }

    var body: some View {
        let pages = MushafPagination.pages(quran: quranData.quran, qiraah: settings.displayQiraahForArabic)

        Group {
            if pages.isEmpty {
                Text("No ayahs to display")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // A mushaf is bound on the right: page 1 sits at the far RIGHT, and you turn leftward through it.
                // This reverses the DATA rather than flipping `layoutDirection` on the TabView. The RTL environment is
                // not reliably honoured by the UIPageViewController behind `.page` style - on an English (LTR) device
                // it mirrored each page's CONTENT while still starting index 0 on the LEFT, which is exactly backwards.
                // Reversing the emission puts index 0 on the right in a plain LTR pager, and every index-based path
                // (selection, prewarm, jump-to-page) is untouched because `.tag(index)` still carries the real index.
                TabView(selection: $pageIndex) {
                    // `MushafPageContent` is a view struct, not an inline builder, so SwiftUI only evaluates
                    // a page's (expensive) Arabic body when that page is actually on screen - otherwise all
                    // ~600 pages would render up front.
                    ForEach(Array(pages.enumerated()).reversed(), id: \.offset) { index, page in
                        MushafPageContent(page: page)
                            // Each page's own contents keep the app's reading direction; only the *paging* is
                            // flipped below.
                            .environment(\.layoutDirection, layoutDirection)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        // Order matters: the first inset applied sits closest to the content (higher), the last sits lowest.
        // So the tajweed/qiraah controls + mini player go ABOVE, and the page-navigation footer is pinned to
        // the very bottom.
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomControls() }
        .safeAreaInset(edge: .bottom, spacing: 0) { pageFooter(pages: pages) }
        .onAppear {
            // Seed the index once. Re-deriving it on every render (font change, qiraah switch) would yank the
            // reader back to the page it was opened at.
            guard !didSetInitialPage else { return }
            didSetInitialPage = true
            pageIndex = startingPageIndex(in: pages)
            reportSurah(on: pageIndex, in: pages)
            reportAnchor(on: pageIndex, in: pages)
            MushafPageRenderCache.prewarm(pages: pages, around: pageIndex)
        }
        .onChange(of: pageIndex) { index in
            reportSurah(on: index, in: pages)
            reportAnchor(on: index, in: pages)
            MushafPageRenderCache.prewarm(pages: pages, around: index)
            guard pages.indices.contains(index),
                  let surah = pages[index].firstSurah,
                  let ayah = pages[index].firstAyah else { return }
            saveLastRead(surahID: surah.id, ayahID: ayah.id)
        }
    }

    private func reportSurah(on index: Int, in pages: [MushafPage]) {
        guard pages.indices.contains(index), let surah = pages[index].displayedSurah else { return }
        onSurahChange?(surah)
    }

    private func reportAnchor(on index: Int, in pages: [MushafPage]) {
        guard pages.indices.contains(index),
              let surah = pages[index].firstSurah,
              let ayah = pages[index].firstAyah else { return }
        onPageAnchor?(surah.id, ayah.id)
    }

    private func saveLastRead(surahID: Int, ayahID: Int) {
        // Debounced: the AppStorage write + widget snapshot + reloadAllTimelines ran inline on every page
        // turn, which was the single biggest per-swipe cost in page mode. Only where the flipping STOPS
        // matters, so page turns just note the position and the write settles ~0.8s after the last one.
        settings.noteLastRead(surah: surahID, ayah: ayahID)
    }

    // MARK: - Bottom page-navigation footer (pinned below the tajweed/qiraah controls and the mini player)

    @ViewBuilder
    private func pageFooter(pages: [MushafPage]) -> some View {
        if pages.indices.contains(pageIndex) {
            let page = pages[pageIndex]
            let ranges = MushafPagination.juzRanges(pages)
            let jr = page.juz.flatMap { ranges[$0] }
            let juzPosition = jr.map { pageIndex - $0.start + 1 } ?? 0
            let juzTotal = jr?.count ?? 0

            let footerSurah = page.displayedSurah
            let surahTotal = max(footerSurah?.pageCount ?? 1, 1)
            let surahPosition = min(
                max((page.page - (footerSurah?.pageStart ?? page.page)) + 1, 1),
                surahTotal
            )

            VStack(spacing: 8) {
                if let target = activePicker {
                    inlinePicker(target: target, pages: pages)
                }

                HStack(spacing: 8) {
                    pageInfoPill(page: page, surah: footerSurah, pages: pages,
                                 surahPosition: surahPosition, surahTotal: surahTotal,
                                 juzPosition: juzPosition, juzTotal: juzTotal)

                    if let footerSurah {
                        pageFooterPlayButton(surah: footerSurah)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    /// The footer row's height. The info panel and the play control both take it, so the two read as one bar
    /// rather than a tall block next to a small button. (A computed property, not a `static let`: a generic type
    /// can't hold static stored properties.)
    private var footerHeight: CGFloat { 62 }

    /// Only what the toolbar title doesn't already say. The surah's name is up top, so this is purely position:
    /// how big the surah is, how far into it and into the juz this page sits, and the two jump-to pickers.
    private func pageInfoPill(page: MushafPage, surah footerSurah: Surah?, pages: [MushafPage],
                              surahPosition: Int, surahTotal: Int,
                              juzPosition: Int, juzTotal: Int) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    // The ayah count and revelation place live in the pinned header now - the footer is purely
                    // where you are and where you can jump to.
                    meter(label: "Surah", position: surahPosition, total: surahTotal,
                          color: settings.accentColor.accent1)

                    if juzTotal > 0 {
                        meter(label: "Juz", position: juzPosition, total: juzTotal,
                              color: settings.accentColor.accent2)
                    }
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 4) {
                    jumpButton(
                        title: "Page \(page.page) / \(pages.count)  \(percent(page.page, of: pages.count))",
                        target: .page,
                        color: settings.accentColor.accent1,
                        seed: { pagePickerSelection = pageIndex }
                    )

                    jumpButton(
                        title: "Juz \(page.juz ?? 1) / 30  \(percent(page.juz ?? 1, of: 30))",
                        target: .juz,
                        color: settings.accentColor.accent2,
                        seed: { juzPickerSelection = page.juz ?? 1 }
                    )
                }
            }

            // Progress through the whole mushaf. A track behind the fill is what makes it legible - the old
            // hairline had nothing to read against, so it just looked like a stray line.
            trackedBar(
                fraction: pages.count > 0 ? CGFloat(page.page) / CGFloat(pages.count) : 0,
                height: 5,
                color: settings.accentColor.accent2
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: footerHeight)
        .frame(maxWidth: .infinity)
        .conditionalGlassEffect(rectangle: true)
    }

    /// "43%" - how far through the mushaf (or through the 30 juz) this page sits.
    private func percent(_ position: Int, of total: Int) -> String {
        guard total > 0 else { return "" }
        return "\(Int((Double(position) / Double(total) * 100).rounded()))%"
    }

    /// "Surah 12/48" with its own little bar - the two positions the reader actually cares about.
    private func meter(label: String, position: Int, total: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(label) \(position)/\(total)")
                .font(.system(size: 10, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)

            trackedBar(
                fraction: total > 0 ? CGFloat(position) / CGFloat(total) : 0,
                height: 3,
                color: color
            )
            .frame(width: 44)
        }
    }

    /// A fill over a visible track, so a low value still reads as "a little way in" rather than as nothing.
    private func trackedBar(fraction: CGFloat, height: CGFloat, color: Color) -> some View {
        TrackedBar(fraction: fraction, height: height, color: color)
    }

    /// The page / juz readouts double as the buttons that open their picker. `seed` sets the wheel to where you
    /// currently are, so opening it and confirming without touching it is a no-op.
    private func jumpButton(title: String, target: PickerTarget, color: Color, seed: @escaping () -> Void) -> some View {
        let isOpen = activePicker == target

        return Button {
            settings.hapticFeedback()
            if !isOpen { seed() }
            withAnimation(.easeInOut) {
                activePicker = isOpen ? nil : target
            }
        } label: {
            HStack(spacing: 3) {
                Text(title)
                Image(systemName: isOpen ? "chevron.down" : "chevron.up.chevron.down")
                    .font(.system(size: 6))
            }
            .font(.system(size: 10, weight: .semibold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color.opacity(isOpen ? 0.22 : 0.12))
            )
            .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .accessibilityLabel("\(title). Jump to")
    }

    /// The page and juz pickers, in place rather than as a sheet - jumping somewhere shouldn't cost a modal.
    /// Both use the same chrome; only what's being picked differs.
    private func inlinePicker(target: PickerTarget, pages: [MushafPage]) -> some View {
        let ranges = MushafPagination.juzRanges(pages)
        let juzList = ranges.keys.sorted()

        return VStack(spacing: 0) {
            HStack {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { activePicker = nil }
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(target == .page ? "Go to Page" : "Go to Juz")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    settings.hapticFeedback()
                    switch target {
                    case .page:
                        pageIndex = pagePickerSelection
                    case .juz:
                        // A juz is picked by number, but the reader navigates by page - jump to the page the
                        // juz opens on.
                        if let start = ranges[juzPickerSelection]?.start { pageIndex = start }
                    }
                    withAnimation(.easeInOut) { activePicker = nil }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(settings.accentColor.accent2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            Group {
                switch target {
                case .page:
                    Picker("Page", selection: $pagePickerSelection) {
                        ForEach(Array(0..<max(pages.count, 1)), id: \.self) { i in
                            Text("Page \(pages.indices.contains(i) ? pages[i].page : i + 1)").tag(i)
                        }
                    }
                case .juz:
                    Picker("Juz", selection: $juzPickerSelection) {
                        ForEach(juzList, id: \.self) { juz in
                            Text("Juz \(juz)").tag(juz)
                        }
                    }
                }
            }
            .labelsHidden()
            .pickerStyle(.wheel)
            .frame(height: 110)
            .clipped()
        }
        .frame(maxWidth: .infinity)
        .conditionalGlassEffect(rectangle: true)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// The same playback menu the list reader offers - play the surah, play it ayah by ayah, repeat it, pick a
    /// reciter - rather than a lone play/stop button that could only do one of those.
    private func pageFooterPlayButton(surah: Surah) -> some View {
        let idle = !quranPlayer.isLoading && !quranPlayer.isPlaying && !quranPlayer.isPaused

        return Group {
            if idle {
                Menu {
                    Text("Surah Playback")
                        .foregroundStyle(.secondary)

                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                    } label: {
                        Label("Play Surah", systemImage: "memories")
                    }

                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: 1, continueRecitation: true)
                    } label: {
                        Label("Play Ayah by Ayah", systemImage: "list.number")
                    }

                    Menu {
                        Text("Repeat Count")
                            .foregroundStyle(.secondary)

                        ForEach([20, 15, 10, 5, 3, 2], id: \.self) { n in
                            Button {
                                settings.hapticFeedback()
                                quranPlayer.playSurah(
                                    surahNumber: surah.id,
                                    surahName: surah.nameTransliteration,
                                    repeatCount: n
                                )
                            } label: {
                                Label("Repeat \(n)×", systemImage: "\(n).circle")
                            }
                        }
                    } label: {
                        Label("Repeat Surah", systemImage: "repeat")
                    }
                } label: {
                    playControlLabel
                }
            } else {
                Button {
                    settings.hapticFeedback()
                    quranPlayer.stop()
                } label: {
                    playControlLabel
                }
            }
        }
        .animation(.easeInOut, value: quranPlayer.isPlaying)
    }

    private var playControlLabel: some View {
        Group {
            if quranPlayer.isLoading {
                RotatingGearView()
                    .transition(.opacity)
            } else {
                Image(systemName: quranPlayer.isPlaying || quranPlayer.isPaused ? "xmark.circle.fill" : "play.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(settings.accentColor.accent2)
                    .transition(.opacity)
            }
        }
        .frame(width: 22, height: 22)
        // Square, and exactly as tall as the info panel it sits beside.
        .frame(width: footerHeight, height: footerHeight)
        .contentShape(Rectangle())
        .conditionalGlassEffect(rectangle: true)
    }
}

/// One page of the mushaf. Its body is only built when the page scrolls into view.
private struct MushafPageContent: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared

    let page: MushafPage

    /// Padding around the ayah block; the composer measures fit against the same text width and height.
    private static let textPadding: CGFloat = 20
    private static let verticalPadding: CGFloat = 16
    /// The TextKit slack `MushafPageRenderCache` adds to the measured height, kept out of the fit budget so a
    /// page fitted to the very limit still can't overflow by those few points.
    private static let fitSlack: CGFloat = 8

    /// The ayah the reader has marked by tapping it - it stays lit until tapped again. This is a reading aid
    /// (keeping your place, isolating an ayah on a dense page), so it is deliberately sticky and NOT tied to
    /// the sheet.
    @State private var selectedAyah: SelectedAyah?

    /// The ayah a long press landed on, driving the actions sheet.
    @State private var sheetAyah: TappedAyahRef?

    private struct SelectedAyah: Equatable {
        let surahID: Int
        let ayahID: Int
    }

    private struct TappedAyahRef: Identifiable {
        let surah: Surah
        let ayah: Ayah
        var id: String { "\(surah.id).\(ayah.id)" }
    }

    /// A sheet the actions sheet asked for, presented from here once the actions sheet has closed.
    @State private var secondarySheet: SecondarySheetRequest?

    private struct SecondarySheetRequest: Identifiable {
        let kind: AyahSecondarySheet
        let surah: Surah
        let ayah: Ayah
        var id: String { "\(kind.rawValue).\(surah.id).\(ayah.id)" }
    }

    private func ayahRef(surahID: Int, ayahID: Int) -> (Surah, Ayah)? {
        for segment in page.segments where segment.surah.id == surahID {
            if let ayah = segment.ayahs.first(where: { $0.id == ayahID }) {
                return (segment.surah, ayah)
            }
        }
        return nil
    }

    /// The ayah being recited right now, if it's on this page - it gets a tinted background in the text.
    private var playingAyah: (surahID: Int, ayahID: Int)? {
        guard let surahID = quranPlayer.currentSurahNumber,
              let ayahID = quranPlayer.currentAyahNumber,
              ayahRef(surahID: surahID, ayahID: ayahID) != nil else { return nil }
        return (surahID, ayahID)
    }

    /// The recited ayah, tinted in the accent. This is the follow-along, and it keeps working while an ayah is
    /// marked - the mark is a separate, quieter tint (below), so marking an ayah never costs you the ability to
    /// see where the reciter is.
    private var highlightedAyah: (surahID: Int, ayahID: Int)? {
        playingAyah
    }

    /// The ayah the reader marked by tapping it, tinted grey. Suppressed while it IS the recited ayah, so the
    /// two tints can't fight over the same range.
    private var markedAyah: (surahID: Int, ayahID: Int)? {
        guard let selectedAyah else { return nil }
        let marked = (surahID: selectedAyah.surahID, ayahID: selectedAyah.ayahID)
        if let playingAyah, playingAyah == marked { return nil }
        return marked
    }

    /// Tap an ayah to mark it, tap it again to clear it. Tapping a different ayah moves the mark.
    private func toggleHighlight(surahID: Int, ayahID: Int) {
        settings.hapticFeedback()
        let tapped = SelectedAyah(surahID: surahID, ayahID: ayahID)
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedAyah = selectedAyah == tapped ? nil : tapped
        }
    }

    /// A printed mushaf is a spread, and the spine rule marks the inner edge so you can tell at a glance
    /// which side of the spread you're on. The book opens right-to-left: page 1 carries its rule on the
    /// RIGHT (the edge you turn from), even pages on the left.
    private var spineIsLeading: Bool { page.page % 2 == 0 }

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width - Self.textPadding * 2, 1)
            // The height the page can actually SHOW, not the height of its frame. Anything the pager hands down
            // as a safe-area inset rather than as a smaller frame - the tajweed/qiraah bar most of all, which
            // only exists in comparison mode - is covered by chrome: text fitted into it is text hidden behind
            // the bar. Budgeting against the frame is what cost a comparison-mode page its last line.
            let visibleHeight = max(geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom, 1)
            // The height the TEXT actually gets - not the height of the region. The block sits inside vertical
            // padding, and the rendered height carries a few points of TextKit slack on top of the measurement;
            // handing the fitter the full region made it fit against a budget that didn't exist, so it settled
            // on a smaller size than the page had room for.
            let textHeight = max(visibleHeight - Self.verticalPadding * 2 - Self.fitSlack, 1)
            // Composed + measured once per (page, size, settings) - see `MushafPageRenderCache`. Doing this
            // inline made every swipe re-fit the page on the main thread.
            let rendered = MushafPageRenderCache.rendered(page: page, width: width, height: textHeight)

            ScrollView {
                MushafPageTextView(
                    attributed: rendered.text,
                    ranges: rendered.ranges,
                    width: width,
                    highlight: highlightedAyah,
                    highlightColor: settings.accentColor.color,
                    mark: markedAyah
                ) { surahID, ayahID in
                    guard ayahRef(surahID: surahID, ayahID: ayahID) != nil else { return }
                    toggleHighlight(surahID: surahID, ayahID: ayahID)
                } onLongPressAyah: { surahID, ayahID in
                    guard let ref = ayahRef(surahID: surahID, ayahID: ayahID) else { return }
                    settings.hapticFeedback()
                    sheetAyah = TappedAyahRef(surah: ref.0, ayah: ref.1)
                }
                .frame(width: width, height: rendered.height)
                .padding(.horizontal, Self.textPadding)
                .padding(.vertical, Self.verticalPadding)
                // Fill the visible region so a page that fits sits centered in what the reader can SEE (balanced
                // top/bottom spacing); a page that overflows stays its natural height and scrolls.
                .frame(maxWidth: .infinity, minHeight: visibleHeight, alignment: .center)
            }
        }
        .overlay(alignment: spineIsLeading ? .leading : .trailing) { spineRule }
        // The same pinned surah header the list reader uses, so the two reading modes are titled identically:
        // revelation symbol, ayah/page summary, favourite star. It names the page's TOP surah.
        .safeAreaInset(edge: .top, spacing: 0) { topHeader }
        // A mushaf page is fixed-size: the Arabic uses absolute point sizes, and the chrome must not grow with
        // Dynamic Type either, or it would eat the space the text was fitted into.
        .dynamicTypeSize(.large)
        .sheet(item: $sheetAyah) { ref in
            AyahActionsSheet(
                surah: ref.surah,
                ayah: ref.ayah,
                onRequestSheet: { kind in requestSecondarySheet(kind, for: ref) }
            )
            .smallMediumSheetPresentation()
        }
        .sheet(item: $secondarySheet) { request in
            secondarySheetContent(request)
        }
    }

    /// Close the actions sheet, THEN open the one it asked for. UIKit can't present a second sheet while the
    /// first is still animating away, and stacking sheets is what we're avoiding anyway - so the new sheet is
    /// queued for just after the dismissal finishes.
    private func requestSecondarySheet(_ kind: AyahSecondarySheet, for ref: TappedAyahRef) {
        sheetAyah = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            secondarySheet = SecondarySheetRequest(kind: kind, surah: ref.surah, ayah: ref.ayah)
        }
    }

    @ViewBuilder
    private func secondarySheetContent(_ request: SecondarySheetRequest) -> some View {
        let surah = request.surah
        let ayah = request.ayah

        Group {
            switch request.kind {
            case .tafsir:
                AyahTafsirSheet(surahName: surah.nameTransliteration, surahNumber: surah.id, ayahNumber: ayah.id)

            case .qiraah:
                AyahQiraahComparisonSheet(surahNumber: surah.id, ayahNumber: ayah.id)
                    .environmentObject(settings)
                    .environmentObject(quranData)

            case .translations:
                AyahEnglishComparisonSheet(surahNumber: surah.id, ayahNumber: ayah.id)
                    .environmentObject(settings)
                    .environmentObject(quranData)

            case .customRange:
                // Seeded at the ayah you tapped - that's the whole reason you'd open a range from there.
                PlayCustomRangeSheet(
                    surah: surah,
                    initialStartAyah: ayah.id,
                    initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                        startAyah: ayah.id,
                        surah: surah,
                        displayQiraah: settings.displayQiraahForArabic
                    ),
                    onPlay: { start, end, repAyah, repSec in
                        quranPlayer.playCustomRange(
                            surahNumber: surah.id,
                            surahName: surah.nameTransliteration,
                            startAyah: start,
                            endAyah: end,
                            repeatPerAyah: repAyah,
                            repeatSection: repSec
                        )
                        secondarySheet = nil
                    },
                    onCancel: { secondarySheet = nil }
                )
                .environmentObject(settings)

            case .note:
                AyahNoteSheet(surah: surah, ayah: ayah)

            case .share:
                ShareAyahSheet(surahNumber: surah.id, ayahNumber: ayah.id)
            }
        }
        .smallMediumSheetPresentation()
    }

    @ViewBuilder
    private var topHeader: some View {
        if let surah = page.firstSurah {
            SurahSectionHeader(surah: surah)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 0)
                .conditionalGlassEffect(rectangle: true)
                .padding(.top, 4)
                .padding(.horizontal, settings.defaultView ? 20 : 16)
        }
    }

    /// The spine: a hairline that fades out at both ends, drawn down the inner edge of the leaf.
    private var spineRule: some View {
        LinearGradient(
            colors: [
                settings.accentColor.color.opacity(0),
                settings.accentColor.color.opacity(0.55),
                settings.accentColor.color.opacity(0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: 2)
        .padding(.vertical, 24)
        .allowsHitTesting(false)
        .accessibilityLabel(spineIsLeading ? "Right-hand page" : "Left-hand page")
    }
}

// MARK: - Page mode: tappable text rendering + per-ayah actions

/// A single ayah's character range within the composed page text, so a tap can be mapped back to an ayah.
struct MushafAyahRange {
    let range: NSRange
    let surahID: Int
    let ayahID: Int
}

/// Everything the composer reads, captured on the main actor in one place. The composer used to read
/// `Settings.shared` live from inside every pass, which pinned all ~12 fit/measure passes per page to the
/// main thread; with the snapshot they are pure functions of their inputs, so the prewarm can run them on
/// a background queue. Only the tajweed-colored final pass still requires the main thread (TajweedStore).
struct MushafComposeConfig {
    let pageLanguage: MushafPageLanguage
    let removeArabicDots: Bool
    let quranUsesSystemArabicFont: Bool
    let arabicFontName: String
    /// nil means Hafs. Threaded into `displayArabicText(qiraahOverride:)` so the compose never falls back
    /// to reading Settings off-main.
    let displayQiraah: String?
    let cleanArabicText: Bool
    let beginnerMode: Bool
    /// Already folded: tajweed toggles AND the page being Arabic. English pages never paint tajweed.
    let showTajweed: Bool
    let fontSize: CGFloat
    let fitPage: Bool
    let accent: UIColor

    @MainActor
    static func current() -> MushafComposeConfig {
        let s = Settings.shared
        let language = s.resolvedMushafPageLanguage
        return MushafComposeConfig(
            pageLanguage: language,
            removeArabicDots: s.removeArabicDots,
            quranUsesSystemArabicFont: s.quranUsesSystemArabicFont,
            arabicFontName: s.quranArabicFontName(for: s.displayQiraahForArabic),
            displayQiraah: s.displayQiraahForArabic,
            cleanArabicText: s.cleanArabicText,
            beginnerMode: s.beginnerMode,
            showTajweed: s.showTajweedColors && s.showArabicText && s.isHafsDisplay && language == .arabic,
            fontSize: CGFloat(s.fontArabicSize),
            fitPage: s.mushafFitPage,
            accent: UIColor(s.accentColor.color)
        )
    }
}

/// Builds the whole mushaf page as one `NSAttributedString` - honouring clean text, beginner letter-spacing,
/// the chosen Arabic font (including the Basic/system font), and tajweed colours - and measures it so the page
/// can be shrunk to fit. Rendering through UIKit (rather than a merged SwiftUI `Text`) is what lets individual
/// ayahs be tapped, and lets the fit be measured against exactly what is drawn.
///
/// With an English `pageLanguage`, the page's body is the transliteration / Clear Quran / Saheeh text instead
/// of the Arabic - same canonical page boundaries, same fit-to-page, ayah markers kept - set left-to-right in
/// the system face.
struct MushafPageComposer {
    let page: MushafPage
    let config: MushafComposeConfig

    private var isEnglish: Bool { config.pageLanguage.isEnglish }

    /// Dots-removed text is built from substitution glyphs (ٮ ٯ ڡ) that the Quranic faces do not carry, so it
    /// has to fall back to the system face - the same rule `AyahRow` and `SurahHeaders` already apply. Page mode
    /// was the one reader that ignored it, which is why "Hide Arabic Dots" appeared to do nothing here.
    private var usesSystemFont: Bool { isEnglish || config.removeArabicDots || config.quranUsesSystemArabicFont }
    private var arabicFontName: String { config.arabicFontName }
    private var shouldShowTajweed: Bool { config.showTajweed }

    private func arabicFont(_ size: CGFloat) -> UIFont {
        usesSystemFont ? .roundedSystemFont(ofSize: size)
                       : (UIFont(name: arabicFontName, size: size) ?? .roundedSystemFont(ofSize: size))
    }

    /// Always the Uthmani face, even when the reader picked "Basic": that font is what draws the ayah number as the
    /// circled-flower ornament, so the system fallback would print bare digits mid-page.
    private func markerFont(_ size: CGFloat) -> UIFont {
        UIFont(name: Settings.qiraatUthmaniFontName, size: size) ?? .roundedSystemFont(ofSize: size)
    }

    /// Mushaf pages 1 and 2 (al-Fatihah, and the opening of al-Baqarah) are set centered in a printed mushaf - 
    /// they're short, framed pages, not columns of running text. Every other page is a full block.
    private var isOpeningSpread: Bool { page.page <= 2 }

    /// Justified everywhere except the opening spread, so every line reaches BOTH margins - that's what makes a
    /// trailing-aligned page look set rather than ragged.
    ///
    /// NOT justified when the text is in the system face. Justifying Arabic works by elongating the glyphs
    /// (kashida), and only the Quranic faces carry the elongation forms; with the system face the layout engine
    /// has nothing to stretch, so it dumps ALL the slack into the word gaps instead - which is the "weird spaces
    /// between words" in Basic/no-dots mode. Trailing-aligned with natural spacing is the honest rendering there.
    private func paragraph(_ size: CGFloat, extraLineSpacing: CGFloat = 0, centered: Bool? = nil) -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        if centered ?? isOpeningSpread {
            p.alignment = .center
        } else {
            // English pages are set natural (left-aligned): justified Latin text without hyphenation
            // opens rivers of whitespace, the very artifact the Arabic justification rule below avoids.
            p.alignment = usesSystemFont ? .natural : .justified
        }
        p.baseWritingDirection = isEnglish ? .leftToRight : .rightToLeft
        p.lineSpacing = MushafPageFitter.lineSpacing(for: size, baseSize: config.fontSize)
            + extraLineSpacing
        return p
    }

    /// The English body text for an ayah under the current page language.
    private func englishText(for ayah: Ayah) -> String {
        switch config.pageLanguage {
        case .transliteration: return ayah.textTransliteration
        case .clearQuran:      return ayah.textEnglishMustafa
        case .saheeh:          return ayah.textEnglishSaheeh
        case .arabic:          return ""
        }
    }

    private func ayahText(_ ayah: Ayah, surah: Surah, size: CGFloat, colored: Bool,
                          extraLineSpacing: CGFloat = 0) -> NSAttributedString {
        let para = paragraph(size, extraLineSpacing: extraLineSpacing)

        if isEnglish {
            // No tajweed, no beginner letter-spacing - both are Arabic-script concepts.
            return NSAttributedString(
                string: englishText(for: ayah),
                attributes: [
                    .font: UIFont.roundedSystemFont(ofSize: size),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: para,
                ]
            )
        }

        let clean = config.cleanArabicText
        let beginner = config.beginnerMode
        let qiraahOverride = config.displayQiraah ?? "Hafs"
        let base = ayah.displayArabicText(surahId: surah.id, clean: clean, qiraahOverride: qiraahOverride)
        let display = beginner ? base.map { String($0) }.joined(separator: " ") : base
        let font = arabicFont(size)

        if colored, shouldShowTajweed,
           let styled = TajweedStore.shared.attributedText(
               surah: surah.id,
               ayah: ayah.id,
               text: ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: qiraahOverride),
               displayText: display,
               cleanDisplayText: clean,
               beginnerSpacing: beginner
           ) {
            // The tajweed colours are already UIColor; overlay the font/paragraph without touching them.
            let ns = NSMutableAttributedString(attributedString: NSAttributedString(styled))
            ns.addAttributes([.font: font, .paragraphStyle: para], range: NSRange(location: 0, length: ns.length))
            return ns
        }

        return NSAttributedString(
            string: display,
            attributes: [.font: font, .foregroundColor: UIColor.label, .paragraphStyle: para]
        )
    }

    /// The header a surah gets where it BEGINS, mid-page: a rule, then ONE line carrying the bracketed name
    /// (number included, inside the brackets) followed by the bismillah ornament, then a closing rule. Always
    /// centered, whatever the rest of the page does.
    ///
    /// The name and the bismillah shared a line's worth of height each before, which is a lot of a page to give
    /// up on a mushaf that already fits its text exactly. Al-Fatihah counts its basmala as ayah 1 and at-Tawbah
    /// has none, so neither gets the ornament.
    /// How many box-drawing glyphs it takes to span `width` at `ruleSize`. The rule used to be a hardcoded 10
    /// glyphs, so it was a short dash floating in the middle of the column no matter how wide the page was.
    private func ruleString(width: CGFloat, ruleSize: CGFloat) -> String {
        let glyph = "\u{2500}"   // ─
        let glyphWidth = (glyph as NSString)
            .size(withAttributes: [.font: UIFont.systemFont(ofSize: ruleSize, weight: .light)])
            .width
        guard glyphWidth > 0 else { return String(repeating: glyph, count: 10) }
        return String(repeating: glyph, count: max(Int((width / glyphWidth).rounded(.down)), 8))
    }

    private func surahOpeningHeading(_ surah: Surah, size: CGFloat, width: CGFloat,
                                     extraLineSpacing: CGFloat, leadingBreak: Bool) -> NSAttributedString {
        let accent = config.accent
        let heading = NSMutableAttributedString()

        // The heading gets its OWN paragraph style, and deliberately not the page's. The page's carries the
        // fit's `extraLineSpacing` - the leftover height spread between lines - and a heading of three short
        // lines was being handed three helpings of it, which is why the rules ended up marooned so far from the
        // name. Here the spacing is a fixed hair, so the block is as tall as its content and no taller.
        //
        // Direction follows the heading's language: an English heading ("1. Al-Fatihah - The Opener") in an
        // RTL paragraph gets bidi-reordered - the leading "1." migrated to the far end and rendered as
        // "Al-Fatihah - The Opener .1".
        let tight = NSMutableParagraphStyle()
        tight.alignment = .center
        tight.baseWritingDirection = isEnglish ? .leftToRight : .rightToLeft
        tight.lineSpacing = 1

        // One rule, spanning the full column, ABOVE the name only. Two short rules (above and below) cost two
        // extra line boxes on a page whose whole job is to fit - and a surah opening reads perfectly well as a
        // line drawn across the page with the name beneath it.
        let ruleSize = max(size * 0.3, 8)
        let rule = ruleString(width: width, ruleSize: ruleSize)
        let ruleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: ruleSize, weight: .light),
            .foregroundColor: accent.withAlphaComponent(0.4),
            .paragraphStyle: tight,
        ]

        heading.append(NSAttributedString(string: (leadingBreak ? "\n" : "") + rule + "\n",
                                          attributes: ruleAttributes))

        let nameSize = size * 0.8
        let arabicAttributes: [NSAttributedString.Key: Any] = [
            .font: arabicFont(nameSize),
            .foregroundColor: accent,
            .paragraphStyle: tight,
        ]

        if isEnglish {
            // English headings: number, transliterated name, and its meaning. No ornate brackets - those are
            // Arabic typography and read as debris around Latin text.
            heading.append(NSAttributedString(
                string: "\(surah.id). \(surah.nameTransliteration) - \(surah.nameEnglish)",
                attributes: [
                    .font: UIFont.systemFont(ofSize: nameSize * 0.62, weight: .semibold),
                    .foregroundColor: accent,
                    .paragraphStyle: tight,
                ]
            ))
        } else {
            // The whole thing sits inside the ornate brackets - number and name together, not just the name.
            heading.append(NSAttributedString(string: "\u{FD3F} ", attributes: arabicAttributes))

            // The Arabic-Indic numeral in the SYSTEM face, not the Quranic one: the Quranic fonts draw their
            // digits as ayah-marker ornaments, which is the wrong thing entirely for a surah number.
            heading.append(NSAttributedString(string: surah.idArabic, attributes: [
                .font: UIFont.systemFont(ofSize: nameSize * 0.8, weight: .semibold),
                .foregroundColor: accent,
                .paragraphStyle: tight,
            ]))

            heading.append(NSAttributedString(string: " \(surah.nameArabic) \u{FD3E}", attributes: arabicAttributes))
        }

        if surah.id != 1, surah.id != 9 {
            // On the SAME line as the name. Em quads (not spaces): a run of ordinary spaces between two Arabic
            // runs collapses to almost nothing, which is why the ornament was sitting right up against the name.
            let bismillahFont = UIFont(name: QuranGlyphFont.commonName, size: nameSize)
            heading.append(NSAttributedString(
                string: "\u{2001}\u{2001}\u{2001}" + (bismillahFont != nil ? QuranGlyphFont.bismillahOrnament : Self.basmalaText),
                attributes: [
                    .font: bismillahFont ?? arabicFont(nameSize * 0.85),
                    .foregroundColor: accent,
                    .paragraphStyle: tight,
                ]
            ))
        }

        heading.append(NSAttributedString(string: "\n", attributes: ruleAttributes))
        return heading
    }

    /// Fallback only - used if `QuranCommon` isn't installed and the ornament can't be drawn.
    private static let basmalaText = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"

    /// The composed page text plus each ayah's character range for hit-testing.
    /// `width` is the column width, needed only so a surah heading's rule can span the full page. It is
    /// optional because the measurement passes don't have a meaningful one yet and don't care.
    func attributed(size: CGFloat, colored: Bool = true, extraLineSpacing: CGFloat = 0,
                    width: CGFloat = 0) -> (text: NSAttributedString, ranges: [MushafAyahRange]) {
        let result = NSMutableAttributedString()
        var ranges: [MushafAyahRange] = []
        let accent = config.accent
        let para = paragraph(size, extraLineSpacing: extraLineSpacing)

        for (i, segment) in page.segments.enumerated() {
            // A surah OPENING on this page gets the printed treatment: a full-width rule, the name line, and
            // the basmala. A surah merely *continuing* onto the page after another one ends gets just its name -
            // and the page's own opening surah is titled by the pinned header, so it gets nothing.
            if segment.ayahs.first?.id == 1 {
                result.append(surahOpeningHeading(segment.surah, size: size, width: width,
                                                  extraLineSpacing: extraLineSpacing, leadingBreak: i > 0))
            } else if i > 0 {
                let name = isEnglish
                    ? "\n\(segment.surah.id). \(segment.surah.nameTransliteration)\n"
                    : "\n﴿ \(segment.surah.nameTransliteration) ﴾\n"
                result.append(NSAttributedString(string: name, attributes: [
                    .font: UIFont.systemFont(ofSize: max(size * 0.5, 12), weight: .semibold),
                    .foregroundColor: accent,
                    .paragraphStyle: paragraph(size, extraLineSpacing: extraLineSpacing, centered: true)
                ]))
            }

            for ayah in segment.ayahs {
                let start = result.length
                result.append(ayahText(ayah, surah: segment.surah, size: size, colored: colored,
                                       extraLineSpacing: extraLineSpacing))
                result.append(NSAttributedString(string: " \(ayah.idArabic) ", attributes: [
                    .font: markerFont(size),
                    .foregroundColor: accent,
                    .paragraphStyle: para
                ]))
                ranges.append(MushafAyahRange(
                    range: NSRange(location: start, length: result.length - start),
                    surahID: segment.surah.id,
                    ayahID: ayah.id
                ))
            }
        }

        return (result, ranges)
    }

    private func height(of text: NSAttributedString, width: CGFloat) -> CGFloat {
        ceil(text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height)
    }

    /// Rendered height of the page at `size` and `width`. Colours don't affect layout, so the cheaper plain
    /// string is measured.
    func measuredHeight(size: CGFloat, width: CGFloat, extraLineSpacing: CGFloat = 0) -> CGFloat {
        height(of: attributed(size: size, colored: false, extraLineSpacing: extraLineSpacing).text, width: width)
    }

    /// The height an already-composed page actually lays out to, measured with the SAME TextKit stack the
    /// `UITextView` uses (a real `NSLayoutManager`, `lineFragmentPadding = 0`), rather than with
    /// `boundingRect`. The two disagree on justified right-to-left text that mixes fonts, and the text view
    /// clips anything past the height it was given - so this is what stops a dense page from silently losing
    /// its last line.
    static func layoutHeight(of text: NSAttributedString, width: CGFloat) -> CGFloat {
        let storage = NSTextStorage(attributedString: text)
        let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        let manager = NSLayoutManager()
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        manager.ensureLayout(for: container)
        return ceil(manager.usedRect(for: container).height)
    }

    /// How many lines the page wraps into at `size`. Needed to spread leftover height across the gaps between
    /// lines - see `MushafPageRenderCache`.
    func lineCount(size: CGFloat, width: CGFloat) -> Int {
        let storage = NSTextStorage(attributedString: attributed(size: size, colored: false).text)
        let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        let manager = NSLayoutManager()
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        manager.ensureLayout(for: container)

        var lines = 0
        var glyph = 0
        while glyph < manager.numberOfGlyphs {
            var lineRange = NSRange()
            manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: &lineRange)
            glyph = NSMaxRange(lineRange)
            lines += 1
        }
        return lines
    }

    /// The largest size a mushaf page can be set at without overflowing. Hard ceiling so a short page (a few
    /// ayahs of a late surah) doesn't blow up to absurd glyphs just because it has the room.
    private var fitCeiling: CGFloat { min(config.fontSize * 2.5, 64) }

    /// The font size the page renders at. With "Fit Page to Screen" on, the page takes up as much of the height
    /// as it can WITHOUT overflowing - it grows into empty space as readily as it shrinks out of an overflow.
    /// (It used to search only *downwards* from the user's chosen size, so a page that had room to spare simply
    /// kept the small size and left the rest of the screen empty.) With the setting off, the chosen size stands.
    func fittedSize(availableWidth: CGFloat, availableHeight: CGFloat) -> CGFloat {
        let base = config.fontSize
        guard config.fitPage, availableWidth > 1, availableHeight > 1 else { return base }

        let budget = availableHeight

        // Already as big as we allow and still fitting: take the ceiling.
        let ceiling = fitCeiling
        if measuredHeight(size: ceiling, width: availableWidth) <= budget { return ceiling }

        // Otherwise binary-search the whole range for the biggest size that fits. The floor is a legibility
        // limit - a page that can't fit even at 9pt keeps 9pt and scrolls.
        //
        // 16 iterations, and the result is floored to a HUNDREDTH of a point rather than to a half point. That
        // sounds absurdly fine-grained, but it isn't: rounding down to the nearest 0.5pt threw away up to half a
        // point of size on every page, and half a point across ~15 lines is a visibly smaller page. Take every
        // fraction we're entitled to.
        // The lower bound is a bound, not a promise: a very dense page may not fit even at 9pt. The binary
        // search below would still return ~9 and the page would overflow its budget - so record that the fit
        // failed, and let the caller give the page the height it actually needs instead of clipping it.
        var low: CGFloat = 9
        var high = ceiling
        // 9 iterations resolve a ~30pt range to under 0.06pt - already finer than the 0.01pt rounding below
        // can express. The previous 16 iterations bought precision no one could see, at the price of 7 more
        // full-page compose+measure passes per cold page, on the main thread, mid-swipe.
        for _ in 0..<9 {
            let mid = (low + high) / 2
            if measuredHeight(size: mid, width: availableWidth) <= budget {
                low = mid
            } else {
                high = mid
            }
        }
        return (low * 100).rounded(.down) / 100
    }
}

/// One page, composed and measured. Reference type so it can live in an `NSCache`.
final class MushafRenderedPage {
    let fontSize: CGFloat
    let text: NSAttributedString
    let ranges: [MushafAyahRange]
    /// Laid-out height, with the slack `MushafPageContent` needs so TextKit never clips the final line.
    let height: CGFloat

    init(fontSize: CGFloat, text: NSAttributedString, ranges: [MushafAyahRange], height: CGFloat) {
        self.fontSize = fontSize
        self.text = text
        self.ranges = ranges
        self.height = height
    }
}

/// Composing a page is expensive - fitting it alone measures the whole page up to nine times - and SwiftUI
/// re-evaluates a page's body on every swipe (its own, and its two neighbours'). Doing that work on the main
/// thread mid-gesture is what made paging stutter. Keyed by page + geometry + everything that changes what is
/// drawn, so a page is composed once and every later visit is a dictionary hit.
@MainActor
enum MushafPageRenderCache {
    private static let cache: NSCache<NSString, MushafRenderedPage> = {
        let c = NSCache<NSString, MushafRenderedPage>()
        // Comfortably more than the pages held live by the pager, small enough to stay cheap in memory.
        c.countLimit = 24
        return c
    }()

    /// Everything that changes the rendering but isn't the page or the geometry.
    private static var settingsSignature: String {
        let s = Settings.shared
        return [
            s.fontArabic,
            String(Int(s.fontArabicSize)),
            s.displayQiraahForArabic ?? "Hafs",
            s.showTajweedColors ? "t" : "-",
            s.showArabicText ? "a" : "-",
            s.cleanArabicText ? "c" : "-",
            // Was missing: toggling "Hide Arabic Dots" did not change the key, so every already-composed page
            // kept serving its dotted text until the 24-entry cache happened to evict it.
            s.removeArabicDots ? "d" : "-",
            s.beginnerMode ? "b" : "-",
            s.mushafFitPage ? "f" : "-",
            s.mushafPageLanguage,
            s.accentColor.rawValue,
            s.customAccentColorHex,
        ].joined(separator: "|")
    }

    /// The geometry the visible page was last laid out at, so neighbouring pages can be composed ahead of time
    /// without a `GeometryReader` of their own.
    private static var lastGeometry: (width: CGFloat, height: CGFloat)?

    /// The fit numbers for a page - everything the heavy passes produce. Computing these is ~12 full
    /// compose+layout passes and is PURE given a `MushafComposeConfig`, so the prewarm runs it off-main.
    private struct FitMetrics {
        let size: CGFloat
        let extraSpacing: CGFloat
        let measured: CGFloat
    }

    /// The serial queue the prewarm fits pages on. Serial on purpose: TextKit objects are safe off the main
    /// thread only when confined to one thread at a time, and a single lane keeps the background CPU cost
    /// bounded no matter how fast the user flips.
    private static let prewarmQueue = DispatchQueue(label: "mushaf.page.prewarm", qos: .userInitiated)

    /// Compose the pages on either side of `index` before they're swiped to, so a page turn is a cache hit
    /// even the first time you reach it.
    ///
    /// The expensive part - fitting the font size, ~12 full compose+measure passes - runs on a background
    /// queue with a settings snapshot; only the final tajweed-colored compose (TajweedStore is main-thread
    /// state) and the cache insert hop back to main, one short block per page. The previous design ran the
    /// ENTIRE fit on the main thread (one page per runloop hop), and swiping faster than it drained meant
    /// the swipe itself paid for a cold page - the page-turn lag.
    private static var prewarmGeneration = 0

    static func prewarm(pages: [MushafPage], around index: Int, radius: Int = 3) {
        guard let geometry = lastGeometry, !pages.isEmpty else { return }
        // The background fit is nearly free for the main thread, but each warmed page still costs a colored
        // compose on main - in Low Power Mode keep that to the immediate neighbours.
        let radius = AppPerformance.isLowPowerMode ? min(radius, 1) : radius

        prewarmGeneration &+= 1
        let generation = prewarmGeneration
        let config = MushafComposeConfig.current()
        let signature = settingsSignature

        // Nearest neighbours first (the pages a swipe reaches next), then the outer ring.
        let ordered = (1...radius).flatMap { [index + $0, index - $0] }
            .filter { pages.indices.contains($0) && $0 != index }

        for i in ordered {
            let page = pages[i]
            let key = cacheKey(page: page, width: geometry.width, height: geometry.height, signature: signature)
            guard cache.object(forKey: key) == nil else { continue }

            prewarmQueue.async {
                let composer = MushafPageComposer(page: page, config: config)
                let metrics = fitMetrics(composer: composer, width: geometry.width, height: geometry.height)
                DispatchQueue.main.async {
                    // A newer sweep (another swipe) or a settings change makes this result stale - drop it.
                    guard generation == prewarmGeneration, cache.object(forKey: key) == nil else { return }
                    let rendered = finalize(composer: composer, metrics: metrics, width: geometry.width)
                    cache.setObject(rendered, forKey: key)
                }
            }
        }
    }

    private static func cacheKey(page: MushafPage, width: CGFloat, height: CGFloat, signature: String) -> NSString {
        // Geometry is rounded so a sub-point layout jitter can't miss the cache on every frame.
        "\(page.page)|\(Int(width.rounded()))|\(Int(height.rounded()))|\(signature)" as NSString
    }

    /// The pure, heavy part: fit the size, spread the leftover height, measure. Runs on the prewarm queue
    /// for neighbours and inline on main for the visible page. `nonisolated`: it touches nothing of the
    /// main actor - the composer carries its own settings snapshot.
    private nonisolated static func fitMetrics(composer: MushafPageComposer, width: CGFloat, height: CGFloat) -> FitMetrics {
        let size = composer.fittedSize(availableWidth: width, availableHeight: height)

        // Sizing alone can never fill the page exactly: line wrapping is quantized, so one point more font
        // pushes a whole extra line and overflows. The biggest size that fits therefore leaves up to a line of
        // slack - the empty band at the top and bottom. A printed mushaf closes it by spreading the lines, so
        // that's what we do: fit the size first, then hand the leftover height to the gaps between the lines.
        var extraSpacing: CGFloat = 0
        var measured = composer.measuredHeight(size: size, width: width)

        if composer.config.fitPage, measured < height {
            let lines = composer.lineCount(size: size, width: width)
            if lines > 1 {
                // Capped: on a page with very few lines the leftover per gap would otherwise be enormous and
                // the lines would drift apart instead of looking set.
                let perGap = (height - measured) / CGFloat(lines - 1)
                extraSpacing = min(perGap, size * 0.75)
                measured = composer.measuredHeight(size: size, width: width, extraLineSpacing: extraSpacing)
            }
        }

        return FitMetrics(size: size, extraSpacing: extraSpacing, measured: measured)
    }

    /// The main-thread tail: the tajweed-colored compose (TajweedStore has main-confined state) and the
    /// drawn-string height check.
    private static func finalize(composer: MushafPageComposer, metrics: FitMetrics, width: CGFloat) -> MushafRenderedPage {
        let built = composer.attributed(size: metrics.size, extraLineSpacing: metrics.extraSpacing, width: width)

        // Measure the string that will ACTUALLY be drawn, with the same TextKit configuration the text view
        // uses. `measured` above came from `boundingRect` on the uncolored string; the two disagree on
        // justified RTL text with mixed fonts (the Uthmani marker font's line height differs from the body's),
        // and every point of disagreement was silently clipped by the UITextView - which is how a page could
        // lose its final line entirely with no way to scroll to it.
        let laidOut = MushafPageComposer.layoutHeight(of: built.text, width: width)

        return MushafRenderedPage(
            fontSize: metrics.size,
            text: built.text,
            ranges: built.ranges,
            height: max(metrics.measured, laidOut) + 6
        )
    }

    static func rendered(page: MushafPage, width: CGFloat, height: CGFloat) -> MushafRenderedPage {
        lastGeometry = (width, height)

        let key = cacheKey(page: page, width: width, height: height, signature: settingsSignature)
        if let hit = cache.object(forKey: key) { return hit }

        // Cold visible page: nothing to hand off - the caller needs the result this frame.
        let composer = MushafPageComposer(page: page, config: .current())
        let rendered = finalize(
            composer: composer,
            metrics: fitMetrics(composer: composer, width: width, height: height),
            width: width
        )
        cache.setObject(rendered, forKey: key)
        return rendered
    }
}

/// The composed page in a non-scrolling `UITextView`. A merged SwiftUI `Text` can't hit-test an individual
/// run, so the mushaf page uses UIKit and maps a tap to the ayah whose range contains the tapped character.
struct MushafPageTextView: UIViewRepresentable {
    let attributed: NSAttributedString
    let ranges: [MushafAyahRange]
    /// The wrap width. A non-scrolling `UITextView` whose text container isn't pinned to a width lays the
    /// whole page out on ONE infinitely-wide line (SwiftUI then sizes it from that intrinsic width), so the
    /// container width must be set explicitly - this is what makes the page wrap into lines at all.
    let width: CGFloat
    /// The ayah currently being recited, if it is on this page.
    /// The ayah being recited, if it is on this page - tinted in the accent.
    var highlight: (surahID: Int, ayahID: Int)?
    var highlightColor: Color = .accentColor
    /// The ayah the reader marked by tapping it - tinted grey, and independent of the recitation highlight so
    /// both can be on screen at once.
    var mark: (surahID: Int, ayahID: Int)?
    let onTapAyah: (Int, Int) -> Void
    let onLongPressAyah: (Int, Int) -> Void

    private func range(of ayah: (surahID: Int, ayahID: Int)?) -> NSRange? {
        guard let ayah else { return nil }
        return ranges.first { $0.surahID == ayah.surahID && $0.ayahID == ayah.ayahID }?.range
    }

    /// The tints are painted on top of the cached, composed page rather than recomposing it - a background
    /// attribute doesn't change layout, so nothing has to be re-measured as playback moves down the page.
    private func highlighted(_ text: NSAttributedString) -> NSAttributedString {
        let tints: [(NSRange, Color)] = [
            (range(of: mark), Color.secondary),
            (range(of: highlight), highlightColor),
        ].compactMap { r, color in r.map { ($0, color) } }

        guard !tints.isEmpty else { return text }

        let mutable = NSMutableAttributedString(attributedString: text)
        for (range, color) in tints {
            mutable.addAttribute(.backgroundColor, value: UIColor(color).withAlphaComponent(0.22), range: range)
        }
        return mutable
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.adjustsFontForContentSizeCategory = false
        tv.textContainer.widthTracksTextView = false
        tv.textContainer.size = CGSize(width: width, height: .greatestFiniteMagnitude)
        // Don't let the text view's (single-line) intrinsic width fight the SwiftUI frame.
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // Touch the TextKit-1 layout manager so hit-testing is consistent on iOS 16+ (which defaults to TextKit 2).
        _ = tv.layoutManager

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tv.addGestureRecognizer(tap)

        // A tap only marks an ayah; the actions sheet is the deliberate gesture, so it takes a press. The tap
        // must not also fire when the press wins, hence the dependency.
        let press = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        tv.addGestureRecognizer(press)
        tap.require(toFail: press)

        context.coordinator.textView = tv
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.ranges = ranges
        context.coordinator.onTapAyah = onTapAyah
        context.coordinator.onLongPressAyah = onLongPressAyah

        // Reassigning `attributedText` forces a full TextKit relayout of the page. This view's parent observes
        // the player, so during recitation EVERY tick re-runs this update for every mounted page - three page
        // relayouts per tick, competing with swipe gestures for the main thread. The composed page is a cached
        // immutable instance and the highlight is a value pair, so "did anything actually change" is an
        // identity + equality check; skip the relayout when nothing did.
        let key: ((surahID: Int, ayahID: Int)?) -> String = { $0.map { "\($0.surahID):\($0.ayahID)" } ?? "" }
        let highlightKey = "\(key(highlight))|\(key(mark))"
        if context.coordinator.lastAssignedText === attributed,
           context.coordinator.lastHighlightKey == highlightKey,
           context.coordinator.lastWidth == width {
            return
        }
        context.coordinator.lastAssignedText = attributed
        context.coordinator.lastHighlightKey = highlightKey
        context.coordinator.lastWidth = width

        // Re-pin on every real update: the width changes on rotation / size-class changes.
        tv.textContainer.widthTracksTextView = false
        tv.textContainer.size = CGSize(width: width, height: .greatestFiniteMagnitude)
        tv.attributedText = highlighted(attributed)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        weak var textView: UITextView?
        var ranges: [MushafAyahRange] = []
        var onTapAyah: ((Int, Int) -> Void)?
        var onLongPressAyah: ((Int, Int) -> Void)?

        // What the text view currently displays, so `updateUIView` can skip the full TextKit relayout when
        // nothing visible changed (see the note there).
        var lastAssignedText: NSAttributedString?
        var lastHighlightKey = ""
        var lastWidth: CGFloat = 0

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let (surahID, ayahID) = ayah(at: gesture.location(in: textView)) else { return }
            onTapAyah?(surahID, ayahID)
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            // Fire once, when the press is recognized - not on every move that follows.
            guard gesture.state == .began else { return }
            guard let (surahID, ayahID) = ayah(at: gesture.location(in: textView)) else { return }
            onLongPressAyah?(surahID, ayahID)
        }

        /// The ayah whose glyphs sit under `point`, in the text view's coordinates.
        private func ayah(at point: CGPoint) -> (surahID: Int, ayahID: Int)? {
            guard let tv = textView, tv.textStorage.length > 0 else { return nil }
            let location = CGPoint(x: point.x - tv.textContainerInset.left, y: point.y - tv.textContainerInset.top)
            var fraction: CGFloat = 0
            let index = tv.layoutManager.characterIndex(
                for: location,
                in: tv.textContainer,
                fractionOfDistanceBetweenInsertionPoints: &fraction
            )
            guard index >= 0, index < tv.textStorage.length else { return nil }
            for entry in ranges where NSLocationInRange(index, entry.range) {
                return (entry.surahID, entry.ayahID)
            }
            return nil
        }
    }
}

/// A sheet the actions sheet hands OFF to its parent rather than presenting itself - see `AyahActionsSheet`.
enum AyahSecondarySheet: String, Identifiable {
    case tafsir, qiraah, translations, customRange, note, share
    var id: String { rawValue }
}

/// The note editor plus the draft it edits. A small view of its own so the *parent* can present the editor
/// without owning the draft text and the profanity check.
struct AyahNoteSheet: View {
    @ObservedObject private var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah

    @State private var draftNote = ""
    @State private var showRespectAlert = false

    private func isNoteAllowed(_ text: String) -> Bool {
        !textContainsProfanity(text)
    }

    var body: some View {
        NoteEditorSheet(
            title: "Note for \(surah.nameTransliteration) \(surah.id):\(ayah.id)",
            text: $draftNote,
            onAttemptSave: { text in
                if isNoteAllowed(text) {
                    settings.setBookmarkNote(surah: surah.id, ayah: ayah.id, note: text)
                    return true
                } else {
                    showRespectAlert = true
                    return false
                }
            },
            onCancel: {},
            onSave: { settings.setBookmarkNote(surah: surah.id, ayah: ayah.id, note: draftNote) }
        )
        .onAppear { draftNote = settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id) }
        .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text("Please keep notes Islamic and respectful.")
        }
    }
}

/// The same actions the list view offers on an ayah - bookmark, note, tafsir, compare, playback, copy, share - 
/// reconstructed from `(surah, ayah)` and presented as a sheet when an ayah is tapped in page mode.
///
/// Anything that opens ANOTHER sheet is not presented from here. It's reported through `onRequestSheet`, and the
/// parent closes this sheet first and then presents the new one, so you never end up with a sheet stacked on a
/// sheet.
struct AyahActionsSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared
    @Environment(\.dismiss) private var dismiss

    let surah: Surah
    let ayah: Ayah
    var onRequestSheet: ((AyahSecondarySheet) -> Void)?

    @State private var confirmRemoveNote = false

    private var isBookmarked: Bool { settings.bookmarkIndex(surah: surah.id, ayah: ayah.id) != nil }
    private var currentNote: String { settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id) }
    private var canShowTafsir: Bool { settings.isHafsDisplay }
    /// The comparison tile is worth showing as soon as either comparison is available.
    private var canCompare: Bool { settings.showQiraahDetails || settings.isHafsDisplay }

    /// The ayah itself, so the sheet says what you tapped rather than only naming it. Tajweed-coloured when
    /// that's on, and it carries the Arabic ayah marker the page does.
    @ViewBuilder
    private var ayahPreview: some View {
        let arabic = ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText)
        let showsTajweed = settings.showTajweedColors && settings.showArabicText && settings.isHafsDisplay

        VStack(spacing: 6) {
            Group {
                if showsTajweed,
                   let styled = TajweedStore.shared.attributedText(
                       surah: surah.id,
                       ayah: ayah.id,
                       text: ayah.displayArabicText(surahId: surah.id, clean: false),
                       displayText: arabic,
                       cleanDisplayText: settings.cleanArabicText,
                       beginnerSpacing: false
                   ) {
                    Text(styled) + Text(" \(ayah.idArabic)").foregroundColor(settings.accentColor.accent1)
                } else {
                    Text(arabic) + Text(" \(ayah.idArabic)").foregroundColor(settings.accentColor.accent1)
                }
            }
            // Deliberately smaller than the reader's own size: this is a reminder of which ayah you tapped,
            // not a place to read from, and at full size it pushed every action off the sheet.
            .font(.custom(settings.fontArabic, size: min(settings.fontArabicSize * 0.55, 20)))
            .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
            .multilineTextAlignment(.trailing)
            .lineSpacing(4)
            .environment(\.layoutDirection, .rightToLeft)
            .frame(maxWidth: .infinity)

            Text("\(surah.nameTransliteration) \(surah.id):\(ayah.id)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    /// One action. A compact square rather than a full-width list row: the actions are icons with a word under
    /// them, so a dozen of them fit a small sheet with no scrolling.
    private func actionTile(_ title: String, systemImage: String, destructive: Bool = false,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionTileLabel(title, systemImage: systemImage, destructive: destructive)
        }
        .buttonStyle(.plain)
    }

    private func actionTileLabel(_ title: String, systemImage: String, destructive: Bool = false) -> some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))

            Text(title)
                .font(.caption2.weight(.medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(destructive ? Color.red : settings.accentColor.accent1)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill((destructive ? Color.red : settings.accentColor.accent1).opacity(0.10))
        )
    }

    /// One entry in the grid. `repeatMenu` is the odd one out - it opens a menu rather than firing an action - 
    /// so it carries no `action`.
    private struct AyahAction: Identifiable {
        /// The two tiles that open a menu instead of firing an action: the repeat count and the comparison
        /// (qiraah vs translation) both need a choice before anything happens.
        enum Kind { case button, repeatMenu, comparisonMenu }

        let id: String
        let title: String
        let systemImage: String
        var kind: Kind = .button
        var destructive = false
        var action: () -> Void = {}
    }

    /// Which tiles exist depends on the qiraah and on whether the ayah has a note, so the set is built first and
    /// the column count is chosen from its size - see `columnCount`.
    private var actions: [AyahAction] {
        var list: [AyahAction] = [
            AyahAction(
                id: "bookmark",
                title: isBookmarked ? "Unbookmark" : "Bookmark",
                systemImage: isBookmarked ? "bookmark.fill" : "bookmark",
                action: {
                    settings.hapticFeedback()
                    if !settings.toggleBookmarkIfNoNoteLoss(surah: surah.id, ayah: ayah.id) {
                        confirmRemoveNote = true
                    }
                }
            ),
            AyahAction(
                id: "note",
                title: currentNote.isEmpty ? "Add Note" : "Edit Note",
                systemImage: "note.text",
                action: {
                    settings.hapticFeedback()
                    if !isBookmarked { settings.ensureBookmarkExists(surah: surah.id, ayah: ayah.id) }
                    onRequestSheet?(.note)
                }
            ),
        ]

        if !currentNote.isEmpty {
            list.append(AyahAction(
                id: "removeNote",
                title: "Remove Note",
                systemImage: "minus.circle",
                destructive: true,
                action: {
                    settings.hapticFeedback()
                    settings.removeBookmarkNote(surah: surah.id, ayah: ayah.id)
                }
            ))
        }

        if canShowTafsir {
            list.append(AyahAction(id: "tafsir", title: "Tafsir", systemImage: "text.book.closed", action: {
                settings.hapticFeedback()
                onRequestSheet?(.tafsir)
            }))
        }

        // Qiraah and translation are the same idea - see this ayah rendered another way - so they're one tile
        // holding both, rather than two that look like unrelated features.
        if canCompare {
            list.append(AyahAction(
                id: "comparison",
                title: "Comparison",
                systemImage: "arrow.left.arrow.right.square",
                kind: .comparisonMenu
            ))
        }

        if settings.isHafsDisplay {
            // Playback actions close the sheet: once the recitation starts you want to be looking at the page
            // (where the ayah is highlighted), not at the menu you started it from.
            list.append(AyahAction(id: "play", title: "Play Ayah", systemImage: "play.circle", action: {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                dismiss()
            }))

            list.append(AyahAction(id: "playFrom", title: "Play From Here", systemImage: "play.circle.fill", action: {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
                dismiss()
            }))

            list.append(AyahAction(id: "repeat", title: "Repeat", systemImage: "repeat", kind: .repeatMenu))

            list.append(AyahAction(id: "customRange", title: "Custom Range", systemImage: "slider.horizontal.3", action: {
                settings.hapticFeedback()
                onRequestSheet?(.customRange)
            }))
        }

        list.append(AyahAction(id: "copy", title: "Copy", systemImage: "doc.on.doc", action: {
            settings.hapticFeedback()
            ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah.id, ayahNumber: ayah.id,
                                                settings: settings, quranData: quranData)
            dismiss()
        }))

        list.append(AyahAction(id: "share", title: "Share", systemImage: "square.and.arrow.up", action: {
            settings.hapticFeedback()
            onRequestSheet?(.share)
        }))

        return list
    }

    /// Three across, unless that would leave a last row holding a single tile - a 10th tile stranded on its own
    /// row reads as a mistake. In that case two across (which divides evenly), else four.
    private var columnCount: Int {
        let count = actions.count
        for candidate in [3, 2, 4] where count % candidate != 1 {
            return candidate
        }
        return 3
    }

    private var actionGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount),
            spacing: 10
        ) {
            ForEach(actions) { item in
                switch item.kind {
                case .repeatMenu:
                    Menu {
                        ForEach([2, 3, 5, 10, 15, 20], id: \.self) { count in
                            Button {
                                settings.hapticFeedback()
                                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: count)
                                dismiss()
                            } label: {
                                Label("Repeat \(count)×", systemImage: "\(count).circle")
                            }
                        }
                    } label: {
                        actionTileLabel(item.title, systemImage: item.systemImage)
                    }

                case .comparisonMenu:
                    Menu {
                        if settings.showQiraahDetails {
                            Button {
                                settings.hapticFeedback()
                                onRequestSheet?(.qiraah)
                            } label: {
                                Label("Qiraah Comparison", systemImage: "character.book.closed.fill.ar")
                            }
                        }
                        if settings.isHafsDisplay {
                            Button {
                                settings.hapticFeedback()
                                onRequestSheet?(.translations)
                            } label: {
                                Label("Translation Comparison", systemImage: "character.book.closed")
                            }
                        }
                    } label: {
                        actionTileLabel(item.title, systemImage: item.systemImage)
                    }

                case .button:
                    actionTile(item.title, systemImage: item.systemImage, destructive: item.destructive, action: item.action)
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    ayahPreview
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        )

                    actionGrid
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .navigationTitle("\(surah.nameTransliteration) \(surah.id):\(ayah.id)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        settings.hapticFeedback()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                    }
                    .tint(settings.accentColor.accent1)
                }
            }
        }
        .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(Settings.bookmarkNoteRemovalDialogMessage)
        }
    }
}

#endif

#Preview {
    AlIslamPreviewContainer {
        SurahView(surah: AlIslamPreviewData.surah)
    }
}

