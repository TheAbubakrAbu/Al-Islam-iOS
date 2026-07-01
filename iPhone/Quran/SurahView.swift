import SwiftUI

struct SurahView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
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
    @State private var showSurahInfoSheet = false
    @State private var showReciterPickerSheet = false
    @State private var showSurahPickerSheet = false
    @State private var confirmConvertQiraahToHafs = false
    @State private var isAyahSearchFocused = false
    @State private var selectedSurahNavigation: Int? = nil
    @State private var dividerInfo: DividerInfo? = nil
    @State private var surahInfoDialog: SurahInfoDialog? = nil
    @State private var khatmOverviewPercent: Int = 0
    @State private var khatmOverviewLastSignature: Int = 0
    let surah: Surah
    var ayah: Int? = nil
    var onSelectSurah: ((Int) -> Void)? = nil

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
        [
            settings.showArabicText ? "1" : "0",
            settings.highlightAllahNames ? "1" : "0",
            settings.showTajweedColors ? "1" : "0",
            settings.cleanArabicText ? "1" : "0",
            settings.removeArabicDots ? "1" : "0",
            settings.beginnerMode ? "1" : "0",
            settings.showTransliteration ? "1" : "0",
            settings.showEnglishSaheeh ? "1" : "0",
            settings.showEnglishMustafa ? "1" : "0",
            settings.displayQiraah,
            settings.fontArabic,
            "\(settings.fontArabicSize)",
            "\(settings.englishFontSize)"
        ].joined(separator: "|")
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
            case wholeWord   // `=` — matches whole words / a series of whole words (not substrings)
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
            // series of words) — e.g. "=رب" matches the word رب but not "ربهم".
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
                overlayMap[ayah.id] = BoundaryDividerModel(
                    text: boundaryText(for: ayah, in: surah) ?? pageSegment,
                    pageSegment: pageSegment,
                    juzSegment: juzSegment,
                    style: .allAccent
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
    /// in Warsh, 286 in Hafs), so a target may not exist — land on the closest one instead of the top.
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
                // Only remember the current spot in memory here — writing `settings.lastRead*` (@AppStorage)
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

    var body: some View {
        #if os(iOS)
        // The centered title is now a Menu (Surah List / Surah Info / Revelation Info), so the toolbar
        // only carries the principal title and the trailing settings gear.
        applySurahToolbar(to: surahCoreBody)
        .onAppear {
            quranPlayer.recordReadingHistory(surahNumber: surah.id, surahName: surah.nameTransliteration, ayahNumber: ayah ?? 1)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            settingsSheet
                .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showSurahInfoSheet) {
            SurahInfoSheet(surahName: surah.nameTransliteration, surahNumber: surah.id)
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
        // at), so always show it then — regardless of the user's normal show-page/juz-dividers preference,
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
            // divider too — otherwise the "Page X • Juz Y" header is missing for that first page.
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
            // Always-pinned header (safeAreaInset, not overlay): it reserves space so list content — and
            // the search results-count pill — sits below it rather than being hidden behind it.
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
    
    private var surahTitlePickerButton: some View {
        // Tap opens the Surah list; long-press shows Revelation Info (no longer a menu).
        surahTitleLabel
            .onTapGesture {
                settings.hapticFeedback()
                showSurahPickerSheet = true
            }
            .onLongPressGesture(minimumDuration: 0.45) {
                settings.hapticFeedback()
                surahInfoDialog = surahInfoDialog(for: surah)
            }
    }

    private var surahTitleLabel: some View {
        Group {
            VStack(spacing: 0) {
                HStack {
                    HStack {
                        Text("\(surah.id)")
                            .font(.subheadline.bold())
                            .foregroundColor(settings.accentColor.color)
                        
                        Text(surah.nameTransliteration)
                            .font(.subheadline.bold())
                    }
                    
                    Spacer()
                    
                    HStack {
                        Text(surah.nameArabic)
                            .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 2))
                        
                        Text(surah.idArabic)
                            .font(.custom(Settings.hafsUthmaniFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 3))
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                
                Text(surah.nameEnglish)
                    .font(.caption2)
                    .padding(.top, -8)
            }
            .lineLimit(1)
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
    }

    @ViewBuilder
    private func applySurahToolbar(to base: some View) -> some View {
        base.toolbar {
            ToolbarItem(placement: .principal) {
                surahTitlePickerButton
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                surahInfoButton
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                navBarTitle
            }
        }
    }

    private var surahInfoButton: some View {
        Button {
            settings.hapticFeedback()
            showSurahInfoSheet = true
        } label: {
            Image(systemName: "info.circle")
        }
        .tint(settings.accentColor.color)
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

    private func navigateToSurah(_ targetSurah: Surah) {
        guard targetSurah.id != surah.id else { return }
        settings.hapticFeedback()
        if let onSelectSurah {
            searchText = ""
            pendingScrollAfterSearchClear = nil
            scrollDown = nil
            visibleAyahIDs.removeAll()
            visibleBoundaryAyahIDs.removeAll()
            firstVisibleAyahID = nil
            onSelectSurah(targetSurah.id)
        } else {
            selectedSurahNavigation = targetSurah.id
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
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#if os(iOS)
private struct SurahPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData

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
    @EnvironmentObject private var settings: Settings
    
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
    @EnvironmentObject private var settings: Settings

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

#endif

#Preview {
    AlIslamPreviewContainer {
        SurahView(surah: AlIslamPreviewData.surah)
    }
}
