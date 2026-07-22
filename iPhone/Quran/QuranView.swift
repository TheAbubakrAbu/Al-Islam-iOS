import SwiftUI

/// A search a reader asked the Quran tab to run on its behalf.
///
/// Both readers (the ayah list and the mushaf) are pushed ON TOP of the Quran tab, and the tab is where the
/// whole-Quran search already lives - the verse index, the page/juz queries, the history chips, all of it.
/// Rather than grow a second search engine inside the readers, a reader just hands its query up here; the tab
/// pops back to the surah list, fills its search bar and focuses it. One search, reachable from everywhere.
#if os(iOS)
/// The Quran tab's trailing toolbar buttons (grid toggle, khatm edit, settings gear), declared twice: on
/// iOS 26 with `ToolbarSpacer`s so each button gets its OWN Liquid Glass capsule instead of all merging
/// into one pill, and plain on earlier OSes (which never merged them).
private struct QuranTrailingToolbar: ViewModifier {
    @ObservedObject var settings = Settings.shared
    @Binding var khatmEditMode: Bool
    @Binding var showingSettingsSheet: Bool
    let usesColumnNavigation: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { gridButton }
                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
                ToolbarItem(placement: .navigationBarTrailing) { khatmButton }
                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
                ToolbarItem(placement: .navigationBarTrailing) { gearButton }
            }
        } else {
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { gridButton }
                ToolbarItem(placement: .navigationBarTrailing) { khatmButton }
                ToolbarItem(placement: .navigationBarTrailing) { gearButton }
            }
        }
    }

    private var gridButton: some View {
        Button {
            settings.hapticFeedback()
            withAnimation { settings.gridMode.toggle() }
        } label: {
            Image(systemName: settings.gridMode ? "list.bullet" : "square.grid.2x2")
        }
        .accessibilityLabel(settings.gridMode ? "Show lists" : "Show grids")
        .tint(settings.accentColor.accent2)
    }

    @ViewBuilder
    private var khatmButton: some View {
        if settings.quranSortMode == .khatm {
            Button {
                settings.hapticFeedback()
                withAnimation {
                    khatmEditMode.toggle()
                }
            } label: {
                Image(systemName: khatmEditMode ? "checkmark" : "square.and.pencil")
            }
            .accessibilityLabel(khatmEditMode ? "Done" : "Edit")
            .tint(settings.accentColor.accent2)
        }
    }

    @ViewBuilder
    private var gearButton: some View {
        // On iPad/Mac the open-surah (detail) pane provides the settings gear; avoid a duplicate gear in the
        // sidebar list when using side-by-side column navigation. (The condition lives inside the
        // ToolbarItem so the toolbar content stays non-optional, keeping pre-iOS 16 support.)
        if !usesColumnNavigation {
            Button {
                settings.hapticFeedback()
                showingSettingsSheet = true
            } label: {
                Image(systemName: "gear")
            }
            .tint(settings.accentColor.accent2)
        }
    }
}
#endif

@MainActor
final class QuranSearchHandoff: ObservableObject {
    static let shared = QuranSearchHandoff()
    private init() {}

    /// Non-nil means "a reader asked for the Quran search". Empty string is a legitimate request - it means
    /// "open the search with nothing typed yet".
    @Published var pendingQuery: String?

    func request(_ query: String = "") {
        pendingQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func clear() { pendingQuery = nil }
}

struct QuranView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared
    @ObservedObject private var searchHandoff = QuranSearchHandoff.shared
    @Environment(\.dismiss) private var dismiss

    /// Whether the Quran tab is the one on screen. Page mode means "the Quran tab IS the mushaf", so every time
    /// the tab is entered it should land in the mushaf again - not just the first time. Keying this on the tab
    /// (rather than on `onAppear`) is deliberate: `onAppear` also fires when the reader pops BACK to the surah
    /// list, and re-opening the mushaf there would trap the user in it.
    var isActiveTab: Bool = true

    @State private var searchText = ""
    @State private var isQuranSearchFocused = false
    @State private var scrollToSurahID: Int = -1
    @State private var showingSettingsSheet = false
    @State private var showReciterPickerSheet = false
    @State private var showListeningHistory = false
    @State private var showReadingHistory = false
    @State private var showAyahListeningHistory = false

    #if os(iOS)
    /// Which summary tile's recents are unfolded BELOW the tile grid. The rows can't unfold inside a
    /// half-width grid cell, so they open as ordinary list rows under the summary - and because this is one
    /// value rather than four booleans, opening a tile's recents closes whichever was open before.
    @State private var summaryHistoryExpansion: SummaryHistoryKind?

    enum SummaryHistoryKind: String, Identifiable {
        case ayahOfTheDay, reading, listenedAyah, listenedSurah
        var id: String { rawValue }

        var title: String {
            switch self {
            case .ayahOfTheDay: return "Recent Ayahs of the Day"
            case .reading: return "Recent Read Ayahs"
            case .listenedAyah: return "Recent Listened Ayahs"
            case .listenedSurah: return "Recent Listened Surahs"
            }
        }
    }

    /// Toggle a tile's recents: same tile collapses, a different tile takes over the one expansion slot.
    private func toggleSummaryExpansion(_ kind: SummaryHistoryKind) {
        withAnimation(.easeInOut) {
            summaryHistoryExpansion = summaryHistoryExpansion == kind ? nil : kind
        }
    }
    #endif
    @State private var searchTextAtFocusStart = ""
    @State private var lastSavedSearchQuery = ""
    @State private var isListMoving = false
    @State private var listMotionIdleTask: Task<Void, Never>?
    @State private var ayahSearchTask: Task<Void, Never>?
    @State private var showAyahSearchLearnMore = false
    @State private var khatmEditMode = false
    @State private var showKhatmExtraDetails = false
    @State private var khatmExtraTotals: (words: Int, letters: Int, totalWords: Int, totalLetters: Int)? = nil
    @State private var khatmExtraLoading = false
    @State private var khatmPageStats: [Int: (completed: Int, total: Int)] = [:]
    @State private var khatmJuzStats: [Int: (completed: Int, total: Int)] = [:]
    @State private var khatmLastTotalSignature: Int = 0

    @State private var verseHits: [VerseIndexEntry] = []
    @State private var hasMoreHits = true
    private let hitPageSize = 5
    /// When AI results land, the exhaustive keyword sections collapse behind one "Show keyword matches"
    /// row (three stacked long lists read as noise under good AI hits). Reset per query. Declared in
    /// SHARED scope: the collapse branch is shared code (the flag is simply never true on watchOS).
    @State private var showKeywordResults = false

    #if os(iOS)
    // AI (semantic) ayah search: on-device meaning-based results, shown automatically ABOVE the keyword
    // sections - no mode to enter. "Patience in hardship" finds ayahs about sabr whether or not either
    // word appears; the keyword sections below stay exhaustive.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var aiHits: [AISearchHit] = []
    @State private var aiSearchTask: Task<Void, Never>?

    struct AISearchHit: Identifiable {
        let surah: Int
        let ayah: Int
        let score: Float
        var id: String { "\(surah)-\(ayah)" }
    }

    /// Positional (surah, ayah) map matching the semantic corpus's build order - mushaf order over the
    /// full Hafs ayah set, independent of the display qiraah so the corpus never rebuilds on a riwayah
    /// switch. Rebuilt cheaply each launch (the vectors themselves load from disk).
    @MainActor private static var semanticAyahMap: [(surah: Int, ayah: Int)] = []

    private var quranSemanticCorpusID: String { "quran-en" }

    /// Resolve the corpus texts (both bundled translations per ayah, so either's phrasing matches) and
    /// hand them to the engine. No-ops once ready; cheap when the vectors are already on disk.
    private func prepareQuranSemanticCorpus() {
        guard SemanticSearchEngine.isSupported, !quranData.quran.isEmpty else { return }
        if Self.semanticAyahMap.isEmpty {
            var map: [(Int, Int)] = []
            map.reserveCapacity(6236)
            for surah in quranData.quran {
                for ayah in surah.ayahs {
                    map.append((surah.id, ayah.id))
                }
            }
            Self.semanticAyahMap = map
        }
        guard !semanticEngine.isReady(quranSemanticCorpusID) else { return }
        var texts: [String] = []
        texts.reserveCapacity(Self.semanticAyahMap.count)
        for surah in quranData.quran {
            for ayah in surah.ayahs {
                texts.append("\(ayah.textEnglishSaheeh) \(ayah.textEnglishMustafa)")
            }
        }
        semanticEngine.prepare(corpusID: quranSemanticCorpusID, version: "en2-\(texts.count)", texts: texts)
    }

    /// True when the live query is one the semantic engine can answer (English text, not a reference).
    private var aiQueryEligible: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return SemanticSearchEngine.isSupported
            && trimmed.count >= 3
            && !trimmed.containsArabicLetters
            && getSurahAndAyah(from: trimmed).surah == nil
    }

    // Ask (the on-device LLM, grounded RAG): auto-runs for QUESTION-shaped queries only, streaming an
    // answer card above the AI results - drawn strictly from the retrieved ayahs, cited, never invented.
    // Exists only on Apple Intelligence devices (`OnDeviceAsk.isAvailable`); elsewhere nothing renders.
    @State private var askAnswer = ""
    @State private var askIsStreaming = false
    @State private var askRanForQuery = ""
    @State private var askTask: Task<Void, Never>?

    private func runAskIfNeeded(query: String) {
        runAsk(query: query, manual: false)
    }

    /// Auto mode runs only for QUESTION-shaped queries; `manual` (the tapped "Ask AI" row) runs for
    /// anything - the user explicitly asked, so the query IS the question.
    private func runAsk(query: String, manual: Bool) {
        askTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard OnDeviceAsk.isAvailable, trimmed.count >= 3,
              manual || OnDeviceAsk.looksLikeQuestion(trimmed) else {
            if !askRanForQuery.isEmpty {
                withAnimation { askAnswer = ""; askIsStreaming = false; askRanForQuery = "" }
            }
            return
        }

        askTask = Task {
            // Auto waits out the search debounces so the retrieval this answer is GROUNDED on has
            // settled; a manual tap means the results are already on screen - go immediately.
            try? await Task.sleep(nanoseconds: manual ? 100_000_000 : 900_000_000)
            guard !Task.isCancelled else { return }

            var sources: [OnDeviceAsk.Source] = []
            var seen = Set<String>()
            for hit in aiHits.prefix(6) {
                let reference = "\(hit.surah):\(hit.ayah)"
                if seen.insert(reference).inserted,
                   let ayah = quranData.ayah(surah: hit.surah, ayah: hit.ayah) {
                    sources.append(.init(reference: reference, text: ayah.textEnglishSaheeh))
                }
            }
            for hit in verseHits.prefix(6) {
                let reference = "\(hit.surah):\(hit.ayah)"
                if seen.insert(reference).inserted,
                   let ayah = quranData.ayah(surah: hit.surah, ayah: hit.ayah) {
                    sources.append(.init(reference: reference, text: ayah.textEnglishSaheeh))
                }
            }
            // A "5:6"-style reference has no text hits, but it names its passage outright - asking
            // about it grounds the answer on that exact ayah.
            if sources.isEmpty {
                let exact = getSurahAndAyah(from: trimmed)
                if let surah = exact.surah, let ayah = exact.ayah {
                    sources.append(.init(reference: "\(surah.id):\(ayah.id)", text: ayah.textEnglishSaheeh))
                }
            }
            guard !sources.isEmpty else {
                withAnimation { askAnswer = ""; askIsStreaming = false; askRanForQuery = "" }
                return
            }

            withAnimation { askAnswer = ""; askIsStreaming = true; askRanForQuery = trimmed }
            guard #available(iOS 26.0, *) else { return }
            do {
                for try await text in OnDeviceAsk.streamAnswer(question: trimmed, sources: sources) {
                    guard !Task.isCancelled else { return }
                    askAnswer = text
                }
                guard !Task.isCancelled else { return }
                withAnimation { askIsStreaming = false }
            } catch {
                // Declined or errored: the card simply goes away - keyword and AI results still stand.
                guard !Task.isCancelled else { return }
                withAnimation { askAnswer = ""; askIsStreaming = false; askRanForQuery = "" }
            }
        }
    }

    /// "(46:15)"-style references parsed out of the streamed answer, resolved against the Quran and
    /// deduped in citation order - the model names the verses, these rows OPEN them. Parsing the live
    /// text keeps the rows in lockstep with whatever the answer actually cites.
    private static let askCitationRegex = try! NSRegularExpression(pattern: #"\b(\d{1,3}):(\d{1,3})\b"#)

    private var askCitedAyahs: [(surah: Surah, ayah: Ayah)] {
        guard !askAnswer.isEmpty else { return [] }
        let text = askAnswer as NSString
        var seen = Set<Int>()
        var cited: [(surah: Surah, ayah: Ayah)] = []
        for match in Self.askCitationRegex.matches(in: askAnswer, range: NSRange(location: 0, length: text.length)) {
            guard let surahID = Int(text.substring(with: match.range(at: 1))),
                  let ayahID = Int(text.substring(with: match.range(at: 2))),
                  seen.insert(surahID * 1000 + ayahID).inserted,
                  let surah = quranData.surah(surahID),
                  let ayah = quranData.ayah(surah: surahID, ayah: ayahID)
            else { continue }
            cited.append((surah, ayah))
            if cited.count == 10 { break }
        }
        return cited
    }

    /// "ASK AI" with the sparkles glyph; the pill counts the answer's cited ayahs once they exist.
    private func askAIHeader(citedCount: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            
            Text("ASK AI")

            Spacer()

            if citedCount > 0 {
                Text(String(citedCount))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .conditionalGlassEffect()
                    .padding(.vertical, -16)
            }
        }
        .foregroundStyle(settings.accentColor.color)
    }

    /// The grounded Ask experience as ONE section pinned ABOVE the surah results: the one-tap prompt
    /// row before it runs, the streamed answer WITH its cited ayahs (real tappable rows) after - the
    /// citations are the answer's receipts, so they live in the same section, not a separate one.
    /// ALWAYS present while searching (even for "5:6" references and zero-result queries) - the ask is
    /// an invitation, not a result.
    @ViewBuilder
    private func askAISection(context: SearchDisplayContext) -> some View {
        if context.isSearching,
           quranData.isVerseSearchReady,
           OnDeviceAsk.isAvailable {
            if !askRanForQuery.isEmpty {
                let cited = askCitedAyahs
                Section(header: askAIHeader(citedCount: cited.count)) {
                    AskAnswerCard(answer: askAnswer, isStreaming: askIsStreaming)

                    ForEach(Array(cited.enumerated()), id: \.offset) { _, item in
                        pageJuzAyahRow(item: item)
                    }
                }
            } else {
                Section(header: askAIHeader(citedCount: 0)) {
                    askPromptRow
                }
            }
        }
    }

    /// Debounced semantic query - runs alongside (never instead of) the keyword pipeline, so AI results
    /// sit at the top while the exhaustive keyword sections stay below them.
    private func runAISearch(query: String) {
        aiSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SemanticSearchEngine.isSupported,
              trimmed.count >= 3, !trimmed.containsArabicLetters,
              getSurahAndAyah(from: trimmed).surah == nil else {
            if !aiHits.isEmpty { withAnimation { aiHits = [] } }
            return
        }
        prepareQuranSemanticCorpus()
        let corpusID = quranSemanticCorpusID

        aiSearchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            let results = await semanticEngine.search(corpusID: corpusID, query: trimmed, limit: 12)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                withAnimation {
                    aiHits = results.compactMap { result in
                        guard Self.semanticAyahMap.indices.contains(result.index) else { return nil }
                        let ref = Self.semanticAyahMap[result.index]
                        return AISearchHit(surah: ref.surah, ayah: ref.ayah, score: result.score)
                    }
                }
            }
        }
    }
    #endif

    private static let arFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ar")
        return f
    }()

    func arabicToEnglishNumber(_ arabicNumber: String) -> Int? {
        QuranView.arFormatter.number(from: arabicNumber)?.intValue
    }

    var lastReadSurah: Surah? {
        quranData.surah(settings.lastReadSurah)
    }

    var lastReadAyah: Ayah? {
        lastReadSurah?.ayahs.first(where: { $0.id == settings.lastReadAyah })
    }

    /// The (surah, ayah) for the last individually-listened ayah, resolved against loaded Quran data.
    var lastListenedAyahPair: (surah: Surah, ayah: Ayah)? {
        guard let saved = settings.lastListenedAyah,
              let surah = quranData.surah(saved.surahNumber),
              let ayah = surah.ayahs.first(where: { $0.id == saved.ayahNumber })
        else { return nil }
        return (surah, ayah)
    }

    /// The deterministic (surah, ayah) for today's Ayah of the Day, resolved against loaded Quran data.
    var ayahOfTheDayPair: (surah: Surah, ayah: Ayah)? {
        guard let ref = settings.ayahOfTheDayReference(),
              let surah = quranData.surah(ref.surahID),
              let ayah = surah.ayahs.first(where: { $0.id == ref.ayahID })
        else { return nil }
        return (surah, ayah)
    }

    func getSurahAndAyah(from searchText: String) -> (surah: Surah?, ayah: Ayah?) {
        let surahAyahPair = searchText.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":").map(String.init)
        var surahNumber: Int? = nil
        var ayahNumber: Int? = nil

        if surahAyahPair.count == 2 {
            if let resolvedByName = quranData.resolveSurahIdentifier(surahAyahPair[0]) {
                surahNumber = resolvedByName.id
            } else if let s = Int(surahAyahPair[0]), (1...114).contains(s) {
                surahNumber = s
            } else if let s = arabicToEnglishNumber(surahAyahPair[0]), (1...114).contains(s) {
                surahNumber = s
            }

            ayahNumber = Int(surahAyahPair[1]) ?? arabicToEnglishNumber(surahAyahPair[1])
        }

        if let sNum = surahNumber,
           let aNum = ayahNumber,
           let surah = quranData.surah(sNum),
           let ayah = quranData.ayah(surah: sNum, ayah: aNum) {
            return (surah, ayah)
        }
        return (nil, nil)
    }

    /// Verse hits sorted by surah, then ayah (search results are always grouped by surah).
    /// Deduped by entry id as the last line of defense: a duplicate id inside a `ForEach` is undefined
    /// behavior, and during an ANIMATED List update (results apply with `withAnimation`) it hard-crashes
    /// the diff - the ayah-search crash that survived the off-main-read fix.
    private var verseHitsGroupedBySurah: [(surahId: Int, hits: [VerseIndexEntry])] {
        var grouped = [Int: [VerseIndexEntry]]()
        var orderedSurahIDs: [Int] = []
        var seenIDs = Set<String>()

        for hit in verseHits {
            guard seenIDs.insert(hit.id).inserted else { continue }
            if grouped[hit.surah] == nil {
                grouped[hit.surah] = []
                orderedSurahIDs.append(hit.surah)
            }
            grouped[hit.surah, default: []].append(hit)
        }

        return orderedSurahIDs.compactMap { sid in
            guard let hits = grouped[sid] else { return nil }
            return (sid, hits)
        }
    }

    /// Removes duplicate entries (same id) while keeping order. Duplicates arise when offset-paginated
    /// pages are fetched against an index that was rebuilt in between (qiraah/translation/settings
    /// change), so page N+1 can re-contain entries already shown - and duplicate ForEach ids crash
    /// animated List diffs. Applied at every point that writes `verseHits`.
    private func dedupedHits(_ hits: [VerseIndexEntry]) -> [VerseIndexEntry] {
        var seen = Set<String>()
        return hits.filter { seen.insert($0.id).inserted }
    }

    private struct PageJuzQuery {
        let page: Int?
        let juz: Int?
        let isExplicitPage: Bool
        let isExplicitJuz: Bool
    }

    private struct SearchDisplayContext {
        let isSearching: Bool
        let favoriteSurahs: Set<Int>
        let bookmarkedAyahs: Set<String>
        let pageJuzQuery: PageJuzQuery
        let juzSurahs: [Surah]
        let explicitPageOrJuzMode: Bool
        let pageSearchResult: (surah: Surah, ayah: Ayah)?
        let juzSearchResult: (surah: Surah, ayah: Ayah)?
        let exactMatch: (surah: Surah?, ayah: Ayah?)
        let isExactAyahReference: Bool
        let surahCountQuery: SurahCountQuery?
        let filteredSurahs: [Surah]
        let canShowMoreAyahHits: Bool
        let ayahCountDisplayText: String
    }

    private struct SurahCountQuery {
        let ayahs: QuranData.CountFilter?
        let pages: QuranData.CountFilter?

        var hasAny: Bool { ayahs != nil || pages != nil }
    }

    /// The last page number of the bundled mushaf (≈604), used as the upper bound and the anchor for
    /// "page from the end" (`page -1` → the last page).
    private var totalMushafPages: Int {
        quranData.surah(114)?.pageEnd ?? 604
    }

    /// Resolve a 1-based positional value that may be written *from the end* with a leading "-".
    /// "5" → 5; "-1" → `count` (the last item); "-2" → `count - 1` … Returns nil outside 1...count.
    /// Accepts Arabic-Indic digits too. Shared by surah / juz / page resolution.
    private func resolvePositional(_ valueText: String, count: Int) -> Int? {
        let t = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }

        if t.hasPrefix("-") {
            let v = String(t.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let n = Int(v) ?? arabicToEnglishNumber(v), (1...count).contains(n) else { return nil }
            return count + 1 - n
        }

        guard let n = Int(t) ?? arabicToEnglishNumber(t), (1...count).contains(n) else { return nil }
        return n
    }

    private func parsePageJuzQuery(from raw: String) -> PageJuzQuery {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return PageJuzQuery(page: nil, juz: nil, isExplicitPage: false, isExplicitJuz: false)
        }

        let lowered = trimmed.lowercased()

        // "page X" / "page -X": -X counts from the end of the mushaf ("page -1" → the last page).
        if lowered.hasPrefix("page ") {
            let valueText = String(trimmed.dropFirst(5))
            let validPage = resolvePositional(valueText, count: totalMushafPages)
            return PageJuzQuery(page: validPage, juz: nil, isExplicitPage: true, isExplicitJuz: false)
        }

        // "juz X" / "juz -X": a juz name, a number, or "-X" counting from the end ("juz -1" → juz 30).
        if lowered.hasPrefix("juz ") {
            let valueText = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            let validJuz = quranData.resolveJuzIdentifier(valueText) ?? resolvePositional(valueText, count: 30)
            return PageJuzQuery(page: nil, juz: validJuz, isExplicitPage: false, isExplicitJuz: true)
        }

        // "surah X" / "surah -X" is resolved in the surah list (filteredSurahs), not as a page/juz.
        if lowered.hasPrefix("surah ") {
            return PageJuzQuery(page: nil, juz: nil, isExplicitPage: false, isExplicitJuz: false)
        }

        // A bare leading "-" counts from the end of the Quran and, like a plain number, offers surah +
        // page + juz candidates (non-explicit): "-1" → surah 114, page \(totalMushafPages), juz 30.
        if trimmed.hasPrefix("-") {
            let page = resolvePositional(trimmed, count: totalMushafPages)
            let juz = resolvePositional(trimmed, count: 30)
            return PageJuzQuery(page: page, juz: juz, isExplicitPage: false, isExplicitJuz: false)
        }

        // Plain number (no "page"/"juz"/"surah" prefix): offer it as both a page and a juz candidate so a
        // bare number like "50" surfaces page 50 (and juz, when in range) alongside surah 50. Kept
        // non-explicit so the surah results still show too.
        if let n = Int(trimmed) ?? arabicToEnglishNumber(trimmed) {
            let validPage = (1...totalMushafPages).contains(n) ? n : nil
            let validJuz = (1...30).contains(n) ? n : nil
            return PageJuzQuery(page: validPage, juz: validJuz, isExplicitPage: false, isExplicitJuz: false)
        }

        return PageJuzQuery(page: nil, juz: nil, isExplicitPage: false, isExplicitJuz: false)
    }

    private func firstAyahResult(page: Int? = nil, juz: Int? = nil) -> (surah: Surah, ayah: Ayah)? {
        quranData.firstAyahResult(page: page, juz: juz)
    }

    private func parseCountOperator(_ symbol: String?) -> QuranData.CountOperator {
        switch symbol {
        case "<": return .lessThan
        case "<=": return .lessThanOrEqual
        case ">": return .greaterThan
        case ">=": return .greaterThanOrEqual
        case "==": return .equal
        default: return .equal
        }
    }

    /// Compiled once: this is reached from a computed property evaluated on every body pass, and
    /// `NSRegularExpression` construction is not cheap enough to redo per render.
    private static let surahCountQueryRegex = try? NSRegularExpression(
        pattern: #"(?:^|\s)(<=|>=|==|<|>)?\s*([0-9٠-٩]+)\s*(ayah|ayahs|aayah|aayahs|ay|page|pages|pg|pgs)\b"#,
        options: [.caseInsensitive]
    )

    private func parseSurahCountQuery(from raw: String) -> SurahCountQuery? {
        guard let regex = Self.surahCountQueryRegex else { return nil }

        let nsRange = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        let matches = regex.matches(in: raw, options: [], range: nsRange)
        guard !matches.isEmpty else { return nil }

        var ayahs: QuranData.CountFilter? = nil
        var pages: QuranData.CountFilter? = nil

        for match in matches {
            guard let numberRange = Range(match.range(at: 2), in: raw),
                  let unitRange = Range(match.range(at: 3), in: raw) else { continue }

            let numberToken = String(raw[numberRange])
            let unit = String(raw[unitRange]).lowercased()
            guard let value = Int(numberToken) ?? arabicToEnglishNumber(numberToken), value >= 1 else { continue }

            let opToken: String? = {
                guard let r = Range(match.range(at: 1), in: raw) else { return nil }
                return String(raw[r])
            }()

            let filter = QuranData.CountFilter(op: parseCountOperator(opToken), value: value)
            if ["ayah", "ayahs", "aayah", "aayahs", "ay"].contains(unit) {
                ayahs = filter
            } else {
                pages = filter
            }
        }

        let query = SurahCountQuery(ayahs: ayahs, pages: pages)
        return query.hasAny ? query : nil
    }

    private func filteredSurahs(for query: String, countQuery: SurahCountQuery?) -> [Surah] {
        if let countQuery {
            return quranData.surahsMatchingCount(ayahFilter: countQuery.ayahs, pageFilter: countQuery.pages)
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // "surah X" / "surah -X": jump straight to one surah (negative counts from the end: "surah -1" →
        // An-Nas). Fall back to a name search on the remainder so "surah baqarah" still works.
        if trimmed.lowercased().hasPrefix("surah ") {
            let valueText = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            if let n = resolvePositional(valueText, count: 114), let surah = quranData.surah(n) {
                return [surah]
            }
            return quranData.filteredSurahs(query: valueText)
        }

        // A bare leading "-" counts surahs from the end: "-1" → An-Nas (114), "-2" → Al-Falaq … alongside
        // the page/juz candidates from parsePageJuzQuery.
        if trimmed.hasPrefix("-"), let n = resolvePositional(trimmed, count: 114), let surah = quranData.surah(n) {
            return [surah]
        }

        // An "X:Y" reference offers BOTH surah readings: "2:50" shows Surah 2 and Surah 50 (Y only when
        // it is itself a valid surah number - "2:280" shows just Surah 2). The exact-ayah 2:50 row still
        // renders separately above.
        let referenceParts = trimmed.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
        if referenceParts.count == 2,
           let first = Int(referenceParts[0]) ?? arabicToEnglishNumber(referenceParts[0]),
           let second = Int(referenceParts[1]) ?? arabicToEnglishNumber(referenceParts[1]) {
            var results: [Surah] = []
            if (1...114).contains(first), let surah = quranData.surah(first) { results.append(surah) }
            if (1...114).contains(second), second != first, let surah = quranData.surah(second) { results.append(surah) }
            if !results.isEmpty { return results }
        }

        return quranData.filteredSurahs(query: query)
    }

    private var sajdahAyahs: [(surah: Surah, ayah: Ayah)] {
        quranData.sajdahAyahResults()
    }

    private var muqattaatAyahs: [(surah: Surah, ayah: Ayah)] {
        quranData.muqattaatAyahResults()
    }

    private func persistQuranSearchHistoryIfNeeded(_ rawQuery: String, requireMinLength: Bool = false) {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if requireMinLength && trimmed.count < 3 { return }

        // Avoid repeatedly writing the same query while user is editing.
        if lastSavedSearchQuery.caseInsensitiveCompare(trimmed) == .orderedSame { return }

        settings.addQuranSearchHistory(trimmed)
        lastSavedSearchQuery = trimmed
    }

    enum QuranRoute: Hashable {
        case ayahs(surahID: Int, ayah: Int?)

        var surahID: Int {
            switch self {
            case .ayahs(let surahID, _):
                return surahID
            }
        }
    }

    @State private var path: [QuranRoute] = []
    /// Guards the once-per-appearance auto-open of the mushaf when page mode is already on.
    @State private var didAutoOpenMushaf = false
    @State private var selectedRoute: QuranRoute?
    /// Bumped to move the keyboard into the search bar - see `QuranSearchHandoff`.
    @State private var searchFocusRequestID = 0
    /// True while the page-mode toggle is paginating in the background (the button shows a spinner).
    @State private var isPreparingPageMode = false
    /// Drives the "Switch to Page/List View?" confirmation before the reading mode actually flips.
    @State private var showReadingModeConfirm = false
    /// Apple Music-style bar minimization: true while the user scrolls down (see `collapseBarsOnScroll`).
    @State private var barsCollapsed = false

    /// Flip between the list reader and the mushaf. Opening the mushaf cold paginates all ~6,236 ayahs, so
    /// that runs off-main with the toolbar button showing a spinner; the mode flips the moment the pages
    /// exist. Confirmed via `showReadingModeConfirm` before this runs.
    private func performReadingModeToggle() {
        #if os(iOS)
        let openingMushaf = !settings.quranPageMode
        if openingMushaf, !MushafPagination.isBuilt(quran: quranData.quran, qiraah: settings.displayQiraahForArabic) {
            guard !isPreparingPageMode else { return }
            isPreparingPageMode = true
            Task {
                await MushafPagination.buildInBackground(quran: quranData.quran, qiraah: settings.displayQiraahForArabic)
                isPreparingPageMode = false
                withAnimation { settings.quranPageMode = true }
                openMushafWhereLeftOff()
            }
        } else {
            withAnimation { settings.quranPageMode.toggle() }
            if openingMushaf { openMushafWhereLeftOff() }
        }
        #else
        withAnimation { settings.quranPageMode.toggle() }
        #endif
    }

    /// A reader asked for the Quran search: come back out to the surah list, carry its query into the search
    /// bar and open the keyboard on it. From there the hit rows navigate straight back into whichever reader
    /// the user has on (list or mushaf), so this is a round trip, not a dead end.
    #if os(iOS)
    /// When a push targets a specific ayah while a text query is typed, hand the query to the arriving
    /// reader (AyahArrivalTerm ignores reference queries like "5:5" itself).
    private func stashArrivalTerm(for route: QuranRoute?) {
        guard case let .ayahs(surahID, ayahID?) = route else { return }
        AyahArrivalTerm.shared.set(term: searchText, surahID: surahID, ayahID: ayahID)
    }
    #endif

    private func runHandedOffSearch(_ query: String) {
        #if os(iOS)
        path.removeAll()
        selectedRoute = nil
        #endif
        searchText = query
        searchFocusRequestID += 1
        searchHandoff.clear()
    }

    func push(surahID: Int, ayahID: Int? = nil) {
        #if os(iOS)
        if usesColumnNavigation {
            selectedRoute = QuranRoute.ayahs(surahID: surahID, ayah: ayahID)
            return
        }

        if #available(iOS 16.0, *) {
            path.append(QuranRoute.ayahs(surahID: surahID, ayah: ayahID))
        }
        #endif
    }

    /// Turning reading mode on opens the mushaf where you stopped: the reader resolves the page from the
    /// last-read ayah, so the page and the ayah can't drift apart. Nothing read yet means Al-Fatiha.
    private func openMushafWhereLeftOff() {
        #if os(iOS)
        guard usesColumnNavigation || path.isEmpty else { return }

        if settings.lastReadSurah > 0,
           settings.lastReadAyah > 0,
           quranData.surah(settings.lastReadSurah) != nil {
            push(surahID: settings.lastReadSurah, ayahID: settings.lastReadAyah)
        } else {
            push(surahID: 1)
        }
        #endif
    }

    // Both fetchers split the work by thread-safety, not by cost: the snapshot HANDOFF happens on the main
    // actor (it reads live index arrays whose writers publish on main - reading them from this Task's
    // background thread was the search crash), and the actual scan runs detached on the snapshot's immutable
    // copies, so typing never blocks on it.
    private func fetchHitsOffMain(query: String, limit: Int, offset: Int) async -> ([VerseIndexEntry], Bool) {
        let quranData = self.quranData
        guard let snapshot = await MainActor.run(body: { quranData.verseSearchSnapshot() }) else {
            return ([], false)
        }

        return await Task.detached(priority: .userInitiated) {
            let page = snapshot.search(term: query, limit: limit + 1, offset: offset)
            let more = page.count > limit
            return (Array(page.prefix(limit)), more)
        }.value
    }

    private func fetchAllHitsOffMain(query: String) async -> [VerseIndexEntry] {
        let quranData = self.quranData
        guard let snapshot = await MainActor.run(body: { quranData.verseSearchSnapshot() }) else {
            return []
        }

        return await Task.detached(priority: .userInitiated) {
            snapshot.search(term: query, limit: .max, offset: 0)
        }.value
    }

    /// Folds the exact strings the result rows are about to render, off the main thread, so each row's first
    /// body evaluation hits the highlight cache instead of paying the fold during scrolling. The strings are
    /// resolved HERE (on main - they come from published Quran data); only the folding leaves the main thread.
    private func prewarmHighlightCaches(for hits: [VerseIndexEntry]) {
        var sources: [String] = []
        sources.reserveCapacity(hits.count * 4)
        for hit in hits {
            guard quranData.surah(hit.surah) != nil,
                  let ayah = quranData.ayah(surah: hit.surah, ayah: hit.ayah) else { continue }
            sources.append(ayah.displayArabicText(surahId: hit.surah, clean: settings.cleanArabicText))
            sources.append(ayah.textTransliteration)
            sources.append(ayah.textEnglishSaheeh)
            sources.append(ayah.textEnglishMustafa)
        }
        guard !sources.isEmpty else { return }
        let list = sources
        Task.detached(priority: .userInitiated) {
            HighlightedSnippet.prewarmNormalization(of: list)
        }
    }

    private func clearAyahSearchState() {
        withAnimation {
            verseHits = []
            hasMoreHits = false
        }
    }

    private var shouldShowSearchHelpOverlay: Bool {
        isQuranSearchFocused
            && !isListMoving
            && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func markListMoving() {
        listMotionIdleTask?.cancel()
        if !isListMoving {
            isListMoving = true
        }
    }

    private func markListStaticSoon() {
        listMotionIdleTask?.cancel()
        listMotionIdleTask = Task {
            try? await Task.sleep(nanoseconds: 220_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                isListMoving = false
            }
        }
    }

    @ViewBuilder
    private var searchHelpOverlay: some View {
        if shouldShowSearchHelpOverlay {
            searchHelpOverlayCard
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: shouldShowSearchHelpOverlay)
        }
    }

    private var searchHelpOverlayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Search Help")
                .font(.subheadline.bold())
                .foregroundStyle(settings.accentColor.color)

            VStack(alignment: .leading, spacing: 4) {
                Text("• Surah: number, Arabic, English, transliteration, or 'surah X'")
                Text("• Ayah: X:Y or text (Arabic/English/transliteration)")
                Text("• Page/Juz: 'page X', 'juz X', or plain numbers")
                Text("• From the end with '-': '-1' is the last surah, page, and juz 30")
                Text("• Works after a keyword too: 'surah -1', 'page -1', 'juz -1'")
                Text("• Counts: '286 ayahs' or '48 pages'")
            }
            .font(.caption)
            .foregroundStyle(.primary)

            Button {
                settings.hapticFeedback()
                withAnimation {
                    showAyahSearchLearnMore.toggle()
                }
            } label: {
                Label(showAyahSearchLearnMore ? "Hide Ayah Search Guide" : "Ayah Search Guide", systemImage: "text.magnifyingglass")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
            }
            .buttonStyle(.plain)

            if showAyahSearchLearnMore {
                // Scrollable and capped: the full guide is taller than what's left of the screen under
                // the search bar, so the expanded part scrolls within the card instead of clipping.
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Plain text matches anywhere (substring): 'رب' also finds 'ربهم'")
                        Text("Use =term for whole words / a phrase: '=رب' finds the word رب, not ربهم")
                        Text("Use #term for an exact substring (case- and tashkeel-sensitive)")
                        Text("Use ^term for starts-with and term% for ends-with")
                        Text("Boolean operators: & (AND), | (OR), ! (NOT)")
                        Text("Count filters: 'X ayahs/pages', '<X', '>X', '<=X', '>=X', '==X'")
                        Text("Juz names work too: Arabic or transliteration")
                        Text("Example: =Allah & mercy%")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 180)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var loadingFallbackView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading Quran...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var body: some View {
        navigationContainer
        .confirmationDialog(
            quranPlayer.playbackAlertTitle,
            isPresented: $quranPlayer.showInternetAlert,
            titleVisibility: .visible
        ) {
            if let offer = quranPlayer.offlineReciterSwitch {
                Button("Play \(offer.suggested.name)") { quranPlayer.acceptOfflineReciterSwitch() }
            }
            Button("OK") { quranPlayer.offlineReciterSwitch = nil }
        } message: {
            Text(quranPlayer.playbackAlertMessage)
        }
        .task {
            prewarmQuranDestinations()
            #if os(iOS)
            // Build (or disk-load) the AI search index AHEAD of the first search - by the time anyone
            // types, it's ready and the "Preparing" row never shows.
            Task {
                await quranData.waitUntilCoreLoaded()
                prepareQuranSemanticCorpus()
            }
            #endif
            #if os(iOS)
            // If the reader is already in page mode when the Quran tab is first built, resume in the mushaf at
            // the last-read ayah's page. Guarded so backing out to the list doesn't immediately re-open it.
            // The pagination is awaited OFF-main first: this task races the launch prewarm, and whichever
            // loses used to pay the full 6,236-ayah build synchronously inside the reader's first body -
            // main-thread work that landed exactly on the first switch into this tab.
            if settings.quranPageMode, !didAutoOpenMushaf {
                didAutoOpenMushaf = true
                await MushafPagination.buildInBackground(quran: quranData.quran, qiraah: settings.displayQiraahForArabic)
                openMushafWhereLeftOff()
            }
            #endif
        }
        // Coming BACK to the Quran tab (from Adhan, Settings, ...) while page mode is on re-opens the mushaf -
        // but only when the tab was left sitting on the surah list with no reader open. `openMushafWhereLeftOff`
        // can't make that call itself: on iPad it deliberately re-points the detail column whatever is in it,
        // which would throw an iPad user off whatever they had open every time they came back to the tab.
        .onChange(of: isActiveTab) { active in
            #if os(iOS)
            guard active, settings.quranPageMode, path.isEmpty, selectedRoute == nil else { return }
            openMushafWhereLeftOff()
            #endif
        }
        .onChange(of: searchHandoff.pendingQuery) { query in
            guard let query else { return }
            runHandedOffSearch(query)
        }
        .onDisappear {
            ayahSearchTask?.cancel()
            listMotionIdleTask?.cancel()
        }
    }

    private func prewarmQuranDestinations() {
        let priorityRoutes = [
            defaultDetailRoute,
            QuranRoute.ayahs(
                surahID: settings.lastReadSurah,
                ayah: settings.lastReadAyah > 0 ? settings.lastReadAyah : nil
            ),
            settings.bookmarkedAyahs.first.map { QuranRoute.ayahs(surahID: $0.surah, ayah: $0.ayah) },
            settings.favoriteSurahs.first.map { QuranRoute.ayahs(surahID: $0, ayah: nil) }
        ].compactMap { $0 }

        // Prewarm off the initial render entirely (with yields between each) so opening the Quran tab isn't
        // blocked by building surah caches. Priority routes (default/last-read/first bookmark/favorite) warm
        // first so the most likely next tap is ready, then the rest fill in slowly in the background.
        Task(priority: .utility) { @MainActor in
            // This whole prewarm runs on the main actor (it reads `settings`/builds caches), so doing it the
            // instant the tab appears stalls the FIRST render - the main cause of "opening Quran feels slow".
            // Wait for the first render to settle before warming anything, so the list paints immediately and
            // caches fill in afterward. (Cancelled automatically if the user leaves the tab.)
            try? await Task.sleep(nanoseconds: 450_000_000)
            if Task.isCancelled { return }

            var seen = Set<Int>()
            for route in priorityRoutes {
                if case let .ayahs(surahID, _) = route,
                   seen.insert(surahID).inserted,
                   let surah = quranData.surah(surahID) {
                    SurahView.prewarm(surah: surah, settings: settings)
                    await Task.yield()
                }
            }

            // The broad prewarm scans all 114 surahs. This `Task` is unstructured (not tied to `.task`), so
            // leaving and re-entering the Quran tab - common on iPad/Mac split view - would otherwise spawn
            // overlapping full prewarm passes. Run it at most once per session; caches are rebuilt lazily on
            // demand afterward, so correctness is unaffected.
            // Shared with the app-root prewarm that fires when the Adhan tab appears - whichever finishes the
            // full sweep first sets the flag, and the other skips it (no duplicate pass).
            guard shouldPrewarmAllQuranDestinations, !QuranData.didBroadPrewarm else { return }

            for surah in quranData.quran {
                guard seen.insert(surah.id).inserted else { continue }
                SurahView.prewarm(surah: surah, settings: settings)
                await Task.yield()
                try? await Task.sleep(nanoseconds: 18_000_000)
            }
            QuranData.didBroadPrewarm = true
        }
    }

    private var shouldPrewarmAllQuranDestinations: Bool {
        !AppPerformance.shouldAvoidBroadPrewarm
    }

    private var navigationContainer: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *), usesColumnNavigation {
                NavigationSplitView {
                    content
                } detail: {
                    // Detail needs its own NavigationStack so NavigationLinks inside a surah push within
                    // the detail column instead of hijacking the split. `.id` resets it when the selected
                    // surah changes.
                    NavigationStack {
                        quranSelectedDetail
                    }
                    .id((selectedRoute ?? defaultDetailRoute).surahID)
                }
            } else if #available(iOS 16.0, *) {
                pathNavigation
            } else {
                NavigationView { content }
            }
            #else
            NavigationView { content }
            #endif
        }
    }

    #if os(iOS)
    private var usesColumnNavigation: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac
    }
    #endif

    @available(iOS 16.0, *)
    private var pathNavigation: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: QuranRoute.self) { route in
                    routeDestination(route)
                }
        }
    }

    private var quranColumnPlaceholder: some View {
        Color.clear
            .navigationTitle("Al-Quran")
    }

    @ViewBuilder
    private var quranSelectedDetail: some View {
        let route = selectedRoute ?? defaultDetailRoute
        // Key by the full route (surah + ayah) so picking a different ayah in the same surah recreates the
        // detail and scrolls to that ayah, rather than reusing the view at its previous scroll position.
        routeDestination(route)
            .id(route)
    }

    private var defaultDetailRoute: QuranRoute {
        if settings.lastReadSurah > 0,
           settings.lastReadAyah > 0,
           quranData.surah(settings.lastReadSurah) != nil {
            return .ayahs(surahID: settings.lastReadSurah, ayah: settings.lastReadAyah)
        }

        if let bookmark = settings.bookmarkedAyahs.first,
           quranData.surah(bookmark.surah) != nil {
            return .ayahs(surahID: bookmark.surah, ayah: bookmark.ayah)
        }

        if let favoriteSurahID = settings.favoriteSurahs.first,
           quranData.surah(favoriteSurahID) != nil {
            return .ayahs(surahID: favoriteSurahID, ayah: nil)
        }

        return .ayahs(surahID: 1, ayah: nil)
    }

    /// UNIVERSAL now, not column-only: on iPhone this pushes through the same `push` every other row
    /// uses. It used to return nil there, which dropped rows into their internal legacy
    /// `NavigationLink(destination:)` fallback - dead inside this NavigationStack container, which is
    /// exactly why the one-verse exact match "wouldn't open".
    private var columnAyahSelectionHandler: ((Int, Int) -> Void)? {
        #if os(iOS)
        if usesColumnNavigation {
            return { surahID, ayahID in
                selectedRoute = .ayahs(surahID: surahID, ayah: ayahID)
            }
        }
        return { surahID, ayahID in
            push(surahID: surahID, ayahID: ayahID)
        }
        #else
        return nil
        #endif
    }

    @ViewBuilder
    private func quranNavigationLink<Label: View>(
        route: QuranRoute,
        @ViewBuilder label: () -> Label
    ) -> some View {
        #if os(iOS)
        if usesColumnNavigation {
            Button {
                settings.hapticFeedback()
                selectedRoute = route
            } label: {
                HStack(spacing: 8) {
                    label()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        } else if #available(iOS 16.0, *) {
            NavigationLink(value: route) {
                label()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .contentShape(Rectangle())
        } else {
            NavigationLink(destination: routeDestination(route)) {
                label()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .contentShape(Rectangle())
        }
        #else
        NavigationLink(destination: routeDestination(route)) {
            label()
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .contentShape(Rectangle())
        #endif
    }

    @ViewBuilder
    private func routeDestination(_ route: QuranRoute) -> some View {
        switch route {
        case let .ayahs(surahID, ayah):
            if let surah = quranData.surah(surahID) {
                ayahsDestination(surah: surah, ayah: ayah)
            } else {
                loadingFallbackView
            }
        }
    }

    @ViewBuilder
    private func ayahsDestination(surah: Surah, ayah: Int? = nil) -> some View {
        if let ayah {
            SurahView(
                surah: surah,
                ayah: ayah
            )
        } else {
            SurahView(
                surah: surah
            )
        }
    }

    /// Heap-box a section subtree. `content` is ONE expression: without boxing, every section's ENTIRE
    /// generic view value materializes together on `content.getter`'s single stack frame - which
    /// overflowed the device main thread's 1MB stack (EXC_BAD_ACCESS code=2 at a guard-page address)
    /// the moment the tab built under the launch cover. The simulator's 8MB main stack hid it entirely.
    /// AnyView stores the subtree on the heap, so the frame holds pointers instead of megabyte values;
    /// each wrapped position keeps a stable underlying type, so List diffing is unaffected.
    private func boxed<V: View>(_ view: V) -> AnyView { AnyView(view) }

    var content: some View {
        ScrollViewReader { scrollProxy in
            let context = searchDisplayContext

            List {
                Group {
                    boxed(primaryHistorySections(context: context))
                    boxed(bookmarkSection(context: context))
                    boxed(favoriteSection(context: context))
                    // Only hoist page/juz above the surah list for EXPLICIT "page X" / "juz Y" queries
                    // (where surahContentSections is empty anyway). For a bare number, the surah match
                    // comes first and the compact page/juz results follow below (in searchResultSections).
                    if context.explicitPageOrJuzMode && context.isSearching {
                        boxed(pageSearchSection(context: context))
                        boxed(juzSearchSection(context: context))
                    }
                    // Ask AI sits ABOVE the surah results: the question (and its answer + cited ayahs)
                    // is the most deliberate thing on the page when it's there at all.
                    #if os(iOS)
                    boxed(askAISection(context: context))
                    #endif
                    // Surah matches first, ayah results below - always the same order, so the eye
                    // never has to re-learn the page.
                    boxed(surahContentSections(context: context))
                    boxed(searchResultSections(context: context))
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle(disableNowPlayingInset: true)
            .compactListSectionSpacing()
            .listSectionIndexVisibilityWhenAvailable(visible: settings.quranSortMode == .juz && searchText.isEmpty)
            // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
            .collapseBarsOnScroll($barsCollapsed)
            // No list-level `.animation(...)` here - it makes lazily-loaded rows stutter while scrolling
            // (SurahView has none). The sort-change transition is already animated at the toggle sites via
            // `withAnimation` in `sortModeButton` / the sort-direction picker.
            #if os(watchOS)
            .searchable(text: $searchText.animation(.easeInOut))
            #endif
            .onChange(of: searchText) { txt in
                handleAyahSearchChange(txt)
                #if os(iOS)
                runAISearch(query: txt)
                runAskIfNeeded(query: txt)
                #endif
            }
            #if os(iOS)
            // Focusing the search field starts the one-time AI vector build (or its disk load) EARLY, so
            // by the time a query is typed the semantic results usually appear with the keyword ones.
            .onChange(of: isQuranSearchFocused) { focused in
                if focused { prepareQuranSemanticCorpus() }
            }
            // The one-time vector build finishing mid-query: re-run the pending AI search so the results
            // appear the moment the corpus is ready, without another keystroke.
            .onChange(of: semanticEngine.readyCorpora) { ready in
                guard ready.contains(quranSemanticCorpusID) else { return }
                runAISearch(query: searchText)
            }
            #endif
            #if os(iOS)
            // The moment an ayah push happens while a TEXT search is live, the query travels with it so
            // the destination colors the matched snippet. Route-level, not gesture-level: a tap gesture
            // on the row (even simultaneous) blocked the NavigationLink from firing at all.
            .onChange(of: path) { newPath in
                stashArrivalTerm(for: newPath.last)
            }
            .onChange(of: selectedRoute) { newRoute in
                stashArrivalTerm(for: newRoute)
            }
            #endif
            .onChange(of: quranData.isVerseSearchReady) { isReady in
                guard isReady else { return }
                handleAyahSearchChange(searchText, debounce: false)
            }
            .onChange(of: settings.quranSortMode) { mode in
                guard !supportsSurahSortDirection(mode),
                      settings.quranSortDirection == .surahOrder else { return }
                settings.quranSortDirection = .ascending
            }
            .onChange(of: scrollToSurahID) { id in
                guard id > 0 else { return }
                // Grid mode (a LazyVGrid added after 4.4.4) can't scroll to off-screen tiles, so flip to list
                // first. Otherwise this is exactly the Version 4.4.4 scroll, which felt right: one delayed,
                // animated scrollTo - no retry loop, no settle attempts.
                if settings.gridMode { settings.gridMode = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        scrollProxy.scrollTo("surah_\(id)", anchor: .top)
                    }
                }
            }

        }
        .navigationTitle("Al-Quran")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    settings.hapticFeedback()
                    // Switching reading mode is a big context change (the whole surah list becomes a mushaf
                    // and vice-versa), so confirm first rather than flipping on an accidental tap.
                    showReadingModeConfirm = true
                } label: {
                    if isPreparingPageMode {
                        ProgressView()
                    } else {
                        Image(systemName: settings.quranPageMode ? "list.bullet.rectangle" : "book")
                    }
                }
                .accessibilityLabel(settings.quranPageMode ? "Read surahs as a list" : "Read surahs as pages")
                .tint(settings.accentColor.accent1)
                // Attached to the BUTTON, not the whole view, so the dialog anchors to it (iPad popover
                // arrows point at the button instead of floating mid-screen).
                .confirmationDialog(
                    settings.quranPageMode ? "Switch to List View?" : "Switch to Page View?",
                    isPresented: $showReadingModeConfirm,
                    titleVisibility: .visible
                ) {
                    Button(settings.quranPageMode ? "Read as List" : "Read as Pages") {
                        performReadingModeToggle()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(settings.quranPageMode
                         ? "Surahs will be shown as a scrolling list of ayahs."
                         : "Surahs will be shown as a mushaf, one page at a time.")
                }
            }

        }
        // The trailing buttons live in their own modifier so iOS 26 can interleave ToolbarSpacers between
        // them - without spacers, Liquid Glass merges adjacent trailing items into ONE capsule. (A separate
        // view-level branch because ToolbarContentBuilder can't branch on availability while the app deploys
        // to iOS 15.)
        .modifier(QuranTrailingToolbar(
            khatmEditMode: $khatmEditMode,
            showingSettingsSheet: $showingSettingsSheet,
            usesColumnNavigation: usesColumnNavigation
        ))
        .sheet(isPresented: $showingSettingsSheet) {
            NavigationView { SettingsQuranView(presentedAsSheet: true) }
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
            .smallMediumSheetPresentation()
        }
        .onDisappear {
            withAnimation {
                persistQuranSearchHistoryIfNeeded(searchText)
            }
        }
        .onChange(of: settings.showOtherQiraatReciters) { enabled in
            // Qiraat overlays are skipped at launch when off; load them in the background once enabled.
            if enabled { quranData.reloadForQiraahAvailabilityChange() }
        }
        .overlay(alignment: .top) {
            searchHelpOverlay
        }
        .safeAreaInset(edge: .bottom) {
            nowPlayingInset
        }
        .adaptiveSafeArea(edge: .bottom) {
            bottomControls
        }
        #endif
    }

    @ViewBuilder
    private var nowPlayingInset: some View {
        #if os(iOS)
        // On iPad/Mac the open-surah (detail) pane shows its own Now Playing bar; don't duplicate it in
        // the sidebar list when using side-by-side column navigation.
        if !usesColumnNavigation {
            let active = quranPlayer.isPlaying || quranPlayer.isPaused
            // Insert/remove the bar on isPlaying||isPaused with `.animation` so SwiftUI animates BOTH the fade
            // (the bar's `.transition`) and the height collapse natively. The bar keeps its content while
            // fading out via `retainedContext`, and "Stop Playing" defers `stop()`, so closing still works.
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                if active {
                    if #available(iOS 16.0, *) {
                        NowPlayingView(quranView: true, scrollDown: $scrollToSurahID, searchText: $searchText) { context in
                            push(surahID: context.surah.id, ayahID: quranPlayer.isPlayingSurah ? nil : context.ayahNumber)
                        }
                    } else {
                        NowPlayingView(quranView: true, scrollDown: $scrollToSurahID, searchText: $searchText)
                    }
                }
            }
            // The mini player minimizes with the rest of the bars.
            .minimizedBarStyle(barsCollapsed && !isQuranSearchFocused)
            .padding(.horizontal, 24)
            .padding(.bottom, active ? 8 : 0)
            .background(Color.white.opacity(0.00001))
            .animation(.easeInOut, value: active)
        }
        #endif
    }

    @ViewBuilder
    private var bottomControls: some View {
        #if os(iOS)
        // Apple Music-style: while scrolling down, the secondary rows fold away and the search row shrinks;
        // scrolling up (or typing) brings everything back. Never minimized mid-search. The rows STAY MOUNTED
        // and collapse via height+opacity - `if` insertion/removal snapshots their glass as hard black boxes.
        // Scroll-collapse is OFF: the sort row stays put while scrolling.
        // (Was: `!barsCollapsed || isQuranSearchFocused` - restore to fold it away again.)
        let secondaryVisible = true
        let chipsVisible = secondaryVisible && isQuranSearchFocused && !settings.quranSearchHistory.isEmpty

        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            searchHistoryChips
                .frame(height: chipsVisible ? nil : 0)
                .clipped()
                .opacity(chipsVisible ? 1 : 0)
                .allowsHitTesting(chipsVisible)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: chipsVisible)
            sortControls
                .frame(height: secondaryVisible ? nil : 0)
                .clipped()
                .opacity(secondaryVisible ? 1 : 0)
                .allowsHitTesting(secondaryVisible)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: secondaryVisible)
            searchAndPlaybackRow
                .minimizedBarStyle(barsCollapsed && !isQuranSearchFocused)
        }
        // Value-gated spring, INSIDE the keyboard transaction-strip below (inner modifiers win): without it
        // the strip also swallowed the collapse animation and the sort row popped in and out as a hard box.
        // Being value-gated, it never touches the keyboard-driven position changes the strip exists for.
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .background(Color.white.opacity(0.00001))
        // Strip the inherited animation transaction so this bottom bar SNAPS to its keyboard-driven position
        // instead of easing on its own curve. Dismissing the keyboard on scroll fires onFocusChanged →
        // `withAnimation { isQuranSearchFocused = … }`, whose easeInOut then collides with the keyboard's own
        // frame animation on the same bar - the "weird" lurch. Same `.transaction { $0.animation = nil }` fix
        // as NowPlayingView's progress bar; the keyboard supplies the motion, so the bar tracks it cleanly.
        .transaction { $0.animation = nil }
        #else
        EmptyView()
        #endif
    }

    /// Always mounted; visibility is driven by the caller via height+opacity. An `if` insertion/removal
    /// snapshots the glass chips as hard black boxes - Liquid Glass can't participate in view transitions.
    @ViewBuilder
    private var searchHistoryChips: some View {
        #if os(iOS)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(settings.quranSearchHistory, id: \.self) { query in
                    searchHistoryChip(query: query)
                }
            }
        }
        #endif
    }

    private func searchHistoryChip(query: String) -> some View {
        HStack(spacing: 4) {
            Button {
                settings.hapticFeedback()
                withAnimation {
                    searchText = query
                    settings.addQuranSearchHistory(query)
                    self.endEditing()
                }
            } label: {
                Text(query)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.removeQuranSearchHistory(query)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
                    .padding(.trailing, 8)
            }
        }
        .foregroundStyle(settings.accentColor.color)
        .conditionalGlassEffect(useColor: 0.25)
    }

    private var sortControls: some View {
        #if os(iOS)
        HStack(spacing: 8) {
            sortDirectionPicker
            sortModeMenu
                .frame(minWidth: 150, maxWidth: 180)
        }
        .frame(maxWidth: .infinity)
        #else
        EmptyView()
        #endif
    }

    @ViewBuilder
    private var sortDirectionPicker: some View {
        #if os(iOS)
        // Khatm mode reuses this slot for a Surah/Juz grouping toggle instead of Asc/Desc.
        if settings.quranSortMode == .khatm {
            khatmGroupingPicker
        } else {
            // Bind to the stored @AppStorage raw via its projected binding (like SettingsView's color-theme
            // picker). A hand-rolled Binding(get:set:) closure over `settings` does NOT drive a segmented
            // Picker's selection here - the segment never commits - which is why this used to refuse to switch.
            Picker("Sort Direction", selection: $settings.quranSortDirectionRaw.animation(.easeInOut)) {
                ForEach(sortDirectionOptions) { direction in
                    Text(direction.title)
                        .accessibilityLabel(direction.accessibilityTitle)
                        .tag(direction.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26
            // hardware (works in the simulator, freezes on device), so keep it decorative only.
            .conditionalGlassEffect(interactive: false)
            .frame(maxWidth: .infinity)
            .onChange(of: settings.quranSortDirectionRaw) { _ in settings.hapticFeedback() }
        }
        #else
        EmptyView()
        #endif
    }

    private var khatmGroupingPicker: some View {
        #if os(iOS)
        // Projected @AppStorage binding (like ArabicView's font picker). A custom Binding(get:set:) closure
        // wouldn't commit the segment here - that was the "can't switch to Juz" bug.
        Picker("Khatm Grouping", selection: $settings.khatmGroupByJuz.animation(.easeInOut)) {
            Text("Surah")
                .accessibilityLabel("Group by Surah")
                .tag(false)
            Text("Juz")
                .accessibilityLabel("Group by Juz")
                .tag(true)
        }
        .pickerStyle(SegmentedPickerStyle())
        // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26 hardware
        // (works in the simulator, freezes on device), so keep it decorative only.
        .conditionalGlassEffect(interactive: false)
        .frame(maxWidth: .infinity)
        .onChange(of: settings.khatmGroupByJuz) { _ in settings.hapticFeedback() }
        #else
        EmptyView()
        #endif
    }

    private var sortDirectionOptions: [Settings.QuranSortDirection] {
        if supportsSurahSortDirection(settings.quranSortMode) {
            return [.surahOrder, .ascending, .descending]
        }
        return [.ascending, .descending]
    }

    private func supportsSurahSortDirection(_ mode: Settings.QuranSortMode) -> Bool {
        switch mode {
        case .revelation, .page, .ayahs, .words, .letters:
            return true
        case .surah, .juz, .khatm, .sajdah, .muqattaat, .pages:
            return false
        }
    }

    private var sortModeMenu: some View {
        #if os(iOS)
        Menu {
            Text("Quran Sort")
                .foregroundStyle(.secondary)

            Divider()

            ForEach([Settings.QuranSortMode.surah, .juz, .khatm]) { mode in
                sortModeButton(mode)
            }

            Divider()

            ForEach([Settings.QuranSortMode.revelation, .page, .ayahs, .words, .letters]) { mode in
                sortModeButton(mode)
            }

            Divider()

            ForEach([Settings.QuranSortMode.muqattaat, .pages, .sajdah]) { mode in
                sortModeButton(mode)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: settings.quranSortMode.systemImage)
                    .imageScale(.medium)
                Text(settings.quranSortMode.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 32)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .conditionalGlassEffect()
        #else
        EmptyView()
        #endif
    }

    private func sortModeButton(_ mode: Settings.QuranSortMode) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.22)) {
                settings.quranSortMode = mode
                if !supportsSurahSortDirection(mode), settings.quranSortDirection == .surahOrder {
                    settings.quranSortDirection = .ascending
                }
            }
        } label: {
            Label(
                mode.title,
                systemImage: mode == settings.quranSortMode ? "checkmark" : mode.systemImage
            )
        }
    }

    private var searchAndPlaybackRow: some View {
        #if os(iOS)
        HStack(spacing: 0) {
            quranSearchBar

            // While the search field is focused, the playback menu slides away so the field takes the whole
            // width - you're searching, not reaching for playback.
            if !isQuranSearchFocused {
                playbackMenuButton
                    .padding(.bottom, 2)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.leading, -8)
        .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 0 : -8)
        #else
        EmptyView()
        #endif
    }

    private var quranSearchBar: some View {
        #if os(iOS)
        SearchBar(
            // NOT an animated binding: with `.animation()` every keystroke wrapped the state write in
            // withAnimation, which animated a diff of the ENTIRE Quran list (114 surah rows + verse hits
            // + highlight work) per character. Under Low Power Mode's throttled CPU those per-keystroke
            // animated diffs stacked up until the watchdog killed the app - the type-delete-retype
            // "search crash". Result changes still animate where they're APPLIED (handleAyahSearchChange
            // wraps its updates in withAnimation); typing itself must be free.
            text: $searchText,
            focusRequestID: searchFocusRequestID,
            onSearchButtonClicked: {
                self.endEditing()
            },
            onFocusChanged: { focused in
                withAnimation {
                    isQuranSearchFocused = focused
                }
                if focused {
                    searchTextAtFocusStart = searchText
                }
                if !focused {
                    if searchTextAtFocusStart.caseInsensitiveCompare(searchText) != .orderedSame {
                        persistQuranSearchHistoryIfNeeded(searchText, requireMinLength: true)
                    }
                }
            }
        )
        #else
        EmptyView()
        #endif
    }

    private var playbackMenuButton: some View {
        #if os(iOS)
        VStack {
            if quranPlayer.isLoading || quranPlayer.isPlaying || quranPlayer.isPaused {
                Button {
                    settings.hapticFeedback()
                    // Fully stop whether loading or playing - a loading tap used to only pause the in-flight
                    // load, which could then resume on its own.
                    quranPlayer.stop()
                } label: {
                    playbackMenuControlLabel {
                        if quranPlayer.isLoading {
                            RotatingGearView().transition(.opacity)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(settings.accentColor.color)
                                .transition(.opacity)
                        }
                    }
                }
            } else {
                Menu {
                    Text("Quran Playback")
                        .foregroundColor(.secondary)

                    playbackMenuContent
                } label: {
                    playbackMenuControlLabel {
                        Image(systemName: "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(settings.accentColor.color)
                            .transition(.opacity)
                    }
                }
            }
        }
        #else
        EmptyView()
        #endif
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

    @ViewBuilder
    private var playbackMenuContent: some View {
        #if os(iOS)
        if let last = settings.lastListenedSurah,
              let surah = quranData.surah(last.surahNumber) {
            Button {
                settings.hapticFeedback()
                quranPlayer.playSurah(
                    surahNumber: last.surahNumber,
                    surahName: last.surahName,
                    certainReciter: true
                )
            } label: {
                Label("Play Last Listened Surah (\(surah.nameTransliteration))", systemImage: "play.fill")
            }
        }

        Button {
            settings.hapticFeedback()
            if let randomSurah = quranData.quran.randomElement() {
                quranPlayer.playSurah(surahNumber: randomSurah.id, surahName: randomSurah.nameTransliteration)
            } else {
                let randomID = Int.random(in: 1...114)
                let surahName = quranData.surah(randomID)?.nameTransliteration ?? "Random Surah"
                quranPlayer.playSurah(surahNumber: randomID, surahName: surahName)
            }
        } label: {
            Label("Play Random Surah", systemImage: "shuffle")
        }

        Button {
            settings.hapticFeedback()
            if let randomSurah = quranData.quran.randomElement(),
               let randomAyah = randomSurah.ayahs.randomElement() {
                quranPlayer.playAyah(
                    surahNumber: randomSurah.id,
                    ayahNumber: randomAyah.id,
                    continueRecitation: true
                )
            }
        } label: {
            Label("Play Random Ayah", systemImage: "shuffle.circle")
        }

        Button {
            settings.hapticFeedback()
            showReciterPickerSheet = true
        } label: {
            Label("Choose Reciter", systemImage: "headphones")
        }
        #endif
    }

    @ViewBuilder
    private func primaryHistorySections(context: SearchDisplayContext) -> some View {
        #if os(iOS)
        if settings.quranSummaryMode {
            if context.isSearching == false {
                boxed(summaryTilesSection(context: context))
            }
        } else {
            // Order: Ayah of the Day · Last Listened Surah · Last Listened Ayah · Last Read Ayah.
            if context.isSearching == false,
               settings.showAyahOfTheDay,
               settings.isAyahOfTheDayHiddenToday == false,
               let pair = ayahOfTheDayPair {
                AyahOfTheDayRow(
                    surah: pair.surah,
                    ayah: pair.ayah,
                    favoriteSurahs: context.favoriteSurahs,
                    bookmarkedAyahs: context.bookmarkedAyahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    onSelectAyah: columnAyahSelectionHandler
                )
                // One animation (combined surah+ayah key) rather than a stack of two.
                .animation(.easeInOut, value: pair.surah.id * 1000 + pair.ayah.id)
            }

            if context.isSearching == false, settings.saveLastListenedSurah, let surah = settings.lastListenedSurah {
                LastListenedSurahRow(
                    lastListenedSurah: surah,
                    favoriteSurahs: context.favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    showListeningHistory: $showListeningHistory,
                    onSelectSurah: usesColumnNavigation ? { surahID in
                        selectedRoute = .ayahs(surahID: surahID, ayah: nil)
                    } : nil
                )
                .animation(.easeInOut, value: surah.surahNumber)
            }

            if context.isSearching == false,
               settings.saveLastListenedAyah,
               let pair = lastListenedAyahPair {
                LastListenedAyahRow(
                    surah: pair.surah,
                    ayah: pair.ayah,
                    favoriteSurahs: context.favoriteSurahs,
                    bookmarkedAyahs: context.bookmarkedAyahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    showAyahListeningHistory: $showAyahListeningHistory,
                    onSelectAyah: columnAyahSelectionHandler
                )
                .animation(.easeInOut, value: pair.surah.id * 1000 + pair.ayah.id)
            }

            if context.isSearching == false,
               settings.saveLastReadAyah,
               let lastReadSurah,
               let lastReadAyah {
                LastReadAyahRow(
                    surah: lastReadSurah,
                    ayah: lastReadAyah,
                    favoriteSurahs: context.favoriteSurahs,
                    bookmarkedAyahs: context.bookmarkedAyahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    showReadingHistory: $showReadingHistory,
                    onSelectAyah: columnAyahSelectionHandler
                )
                .animation(.easeInOut, value: settings.lastReadSurah * 1000 + settings.lastReadAyah)
            }
        }
        #else
        NowPlayingView(quranView: true)

        if context.isSearching == false,
           settings.saveLastReadAyah,
           let lastReadSurah,
           let lastReadAyah {
            LastReadAyahRow(
                surah: lastReadSurah,
                ayah: lastReadAyah,
                favoriteSurahs: context.favoriteSurahs,
                bookmarkedAyahs: context.bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                showReadingHistory: $showReadingHistory,
                onSelectAyah: columnAyahSelectionHandler
            )
        }
        #endif
    }

    #if os(iOS)
    /// The last ten Ayahs of the Day: today first, then back through the previous days. The picker is a pure
    /// function of the date, so "history" needs no storage - earlier days are simply recomputed.
    private var recentAyahsOfTheDay: [(dayLabel: String, surah: Surah, ayah: Ayah)] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true

        return (0..<10).compactMap { daysBack in
            guard let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()),
                  let ref = settings.ayahOfTheDayReference(for: date),
                  let surah = quranData.surah(ref.surahID),
                  let ayah = surah.ayahs.first(where: { $0.id == ref.ayahID })
            else { return nil }
            return (formatter.string(from: date), surah, ayah)
        }
    }

    /// The rows a summary tile's plus unfolds, rendered as ordinary list rows directly below the tile grid -
    /// the summary-mode analogue of the inline expansion the full-size rows have.
    @ViewBuilder
    private func summaryHistoryRows(kind: SummaryHistoryKind) -> some View {
        switch kind {
        case .ayahOfTheDay:
            // Keyed by the day, not the ayah: the hash can land two days on the same ayah, and
            // duplicate ForEach ids are undefined behavior. "Today" keeps full brightness - it IS the
            // current ayah, not history.
            ForEach(Array(recentAyahsOfTheDay.enumerated()), id: \.element.dayLabel) { index, entry in
                if index == 0 {
                    // The "Today" row IS the current ayah - full brightness, and it carries the shuffle
                    // that replaces today's pick with a fresh random one.
                    HStack(spacing: 8) {
                        summaryHistoryRow(surah: entry.surah, ayah: entry.ayah, caption: entry.dayLabel, dimmed: false)

                        Image(systemName: "shuffle")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                            .frame(width: SectionPillHeader.pillHeight, height: SectionPillHeader.pillHeight)
                            .conditionalGlassEffect(circle: true)
                            .onTapGesture {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) { settings.shuffleAyahOfTheDay() }
                            }
                            .accessibilityLabel("Shuffle the Ayah of the Day")
                    }
                } else {
                    summaryHistoryRow(surah: entry.surah, ayah: entry.ayah, caption: entry.dayLabel)
                }
            }
        case .reading:
            ForEach(quranPlayer.readingHistory) { item in
                if let surah = quranData.surah(item.surahNumber),
                   let ayah = surah.ayahs.first(where: { $0.id == max(1, item.ayahNumber) }) {
                    summaryHistoryRow(surah: surah, ayah: ayah, caption: nil)
                }
            }
        case .listenedAyah:
            ForEach(quranPlayer.ayahListeningHistory) { item in
                if let surah = quranData.surah(item.surahNumber),
                   let ayah = surah.ayahs.first(where: { $0.id == item.ayahNumber }) {
                    summaryHistoryRow(surah: surah, ayah: ayah, caption: item.reciter.displayNameWithEnglishQiraah)
                }
            }
        case .listenedSurah:
            ForEach(quranPlayer.listeningHistory) { item in
                if let surah = quranData.surah(item.surahNumber) {
                    Button {
                        settings.hapticFeedback()
                        push(surahID: surah.id, ayahID: nil)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(surah.id) - \(surah.nameTransliteration)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(settings.accentColor.color)

                            Text(item.reciter.displayNameWithEnglishQiraah)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .opacity(0.75)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func summaryHistoryRow(surah: Surah, ayah: Ayah, caption: String?, dimmed: Bool = true) -> some View {
        Button {
            settings.hapticFeedback()
            push(surahID: surah.id, ayahID: ayah.id)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                if let caption {
                    Text(caption)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                SurahAyahRow(surah: surah, ayah: ayah)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            // Same dimming the full-size rows give their unfolded history, so "current" reads brighter.
            // (The Ayah of the Day's "Today" row passes dimmed: false - it IS the current ayah.)
            .opacity(dimmed ? 0.75 : 1)
        }
        .buttonStyle(.plain)
    }

    /// Compact "summary mode": all enabled history items as tappable tiles in a single section.
    /// Order: Last Read Ayah · Ayah of the Day, then Last Listened Ayah · Last Listened Surah.
    @ViewBuilder
    private func summaryTilesSection(context: SearchDisplayContext) -> some View {
        let showAyah = settings.showAyahOfTheDay && settings.isAyahOfTheDayHiddenToday == false
        Section(header:
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(settings.accentColor.color)
                Text("YOUR SUMMARY")
                    .foregroundStyle(settings.accentColor.color)
            }
        ) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                if settings.saveLastReadAyah, let lastReadSurah, let lastReadAyah {
                    SummaryAyahTile(title: "Last Read Ayah", icon: "book", surah: lastReadSurah, ayah: lastReadAyah, titleColor: settings.accentColor.color,
                                    isExpanded: summaryHistoryExpansion == .reading,
                                    onExpand: quranPlayer.readingHistory.isEmpty ? nil : { toggleSummaryExpansion(.reading) }) {
                        push(surahID: lastReadSurah.id, ayahID: lastReadAyah.id)
                    }
                    .animation(.easeInOut, value: settings.lastReadSurah * 1000 + settings.lastReadAyah)
                }
                if showAyah, let pair = ayahOfTheDayPair {
                    SummaryAyahTile(title: "Ayah of the Day", icon: "sparkles", surah: pair.surah, ayah: pair.ayah, titleColor: settings.accentColor.color,
                                    isExpanded: summaryHistoryExpansion == .ayahOfTheDay,
                                    onExpand: { toggleSummaryExpansion(.ayahOfTheDay) }) {
                        push(surahID: pair.surah.id, ayahID: pair.ayah.id)
                    }
                    .animation(.easeInOut, value: pair.surah.id * 1000 + pair.ayah.id)
                }
                if settings.saveLastListenedAyah, let pair = lastListenedAyahPair {
                    SummaryAyahTile(title: "Last Listened Ayah", icon: "headphones.circle", surah: pair.surah, ayah: pair.ayah, titleColor: settings.accentColor.color,
                                    isExpanded: summaryHistoryExpansion == .listenedAyah,
                                    onExpand: quranPlayer.ayahListeningHistory.isEmpty ? nil : { toggleSummaryExpansion(.listenedAyah) }) {
                        push(surahID: pair.surah.id, ayahID: pair.ayah.id)
                    }
                    .animation(.easeInOut, value: pair.surah.id * 1000 + pair.ayah.id)
                }
                if settings.saveLastListenedSurah,
                   let last = settings.lastListenedSurah,
                   let surah = quranData.surah(last.surahNumber) {
                    SummarySurahTile(title: "Last Listened Surah", icon: "headphones", surah: surah, lastListenedSurah: last, titleColor: settings.accentColor.color,
                                     isExpanded: summaryHistoryExpansion == .listenedSurah,
                                     onExpand: quranPlayer.listeningHistory.isEmpty ? nil : { toggleSummaryExpansion(.listenedSurah) }) {
                        push(surahID: surah.id, ayahID: nil)
                    }
                    .animation(.easeInOut, value: last.surahNumber)
                }
            }
            .padding(.vertical, 4)

            // The one open expansion, unfolded as plain rows right under the tiles.
            if let kind = summaryHistoryExpansion {
                summaryHistoryRows(kind: kind)
                    .transition(.opacity)
            }
        }
    }
    #endif

    @ViewBuilder
    private func bookmarkSection(context: SearchDisplayContext) -> some View {
        if !settings.bookmarkedAyahs.isEmpty && !context.isSearching {
            let sortedBookmarks = settings.bookmarkedAyahs.sorted {
                $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
            }
            Section(header: bookmarkHeader(count: sortedBookmarks.count)) {
                if settings.showBookmarks {
                    if settings.gridMode {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                            alignment: .leading,
                            spacing: 10
                        ) {
                            ForEach(sortedBookmarks, id: \.id) { bookmarkedAyah in
                                bookmarkGridTile(bookmarkedAyah, context: context)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(sortedBookmarks, id: \.id) { bookmarkedAyah in
                            bookmarkRow(bookmarkedAyah, context: context)
                        }
                    }
                }
            }
        }
    }

    /// The SHARED pill header (the Hadith tab's exact control), so bookmarks read identically across
    /// the app - with the shuffle the hadith headers carry: open a random bookmarked ayah.
    private func bookmarkHeader(count: Int) -> some View {
        SectionPillHeader(
            title: "BOOKMARKS",
            count: count,
            icon: "bookmark.fill",
            accentTitle: true,
            isExpanded: $settings.showBookmarks,
            onShuffle: {
                if let random = settings.bookmarkedAyahs.randomElement() {
                    push(surahID: random.surah, ayahID: random.ayah)
                }
            }
        )
    }

    @ViewBuilder
    private func bookmarkGridTile(_ bookmarkedAyah: BookmarkedAyah, context: SearchDisplayContext) -> some View {
        if let surah = quranData.surah(bookmarkedAyah.surah),
           let ayah = quranData.ayah(surah: bookmarkedAyah.surah, ayah: bookmarkedAyah.ayah) {
            #if os(iOS)
            let noteText = bookmarkedAyah.note?.trimmingCharacters(in: .whitespacesAndNewlines)
            let noteToShow = (noteText?.isEmpty == false) ? noteText : nil
            Button {
                settings.hapticFeedback()
                push(surahID: surah.id, ayahID: ayah.id)
            } label: {
                SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow, grid: true)
            }
            .buttonStyle(.plain)
            #else
            Button {
                settings.hapticFeedback()
                push(surahID: surah.id, ayahID: ayah.id)
            } label: {
                ZStack(alignment: .topTrailing) {
                    Text("\(surah.id):\(ayah.id)")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .conditionalGlassEffect(
                            useColor: 0.3,
                            customTint: settings.accentColor.color,
                            interactive: false
                        )

                    Image(systemName: "bookmark.fill")
                        .font(.caption2)
                        .foregroundStyle(settings.accentColor.color)
                        .padding(4)
                        .offset(x: 6, y: -6)
                }
                .padding(.top, 4)
                .padding(.trailing, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            #endif
        }
    }

    @ViewBuilder
    private func bookmarkRow(_ bookmarkedAyah: BookmarkedAyah, context: SearchDisplayContext) -> some View {
          if let surah = quranData.surah(bookmarkedAyah.surah),
              let ayah = quranData.ayah(surah: bookmarkedAyah.surah, ayah: bookmarkedAyah.ayah) {
            let noteText = bookmarkedAyah.note?.trimmingCharacters(in: .whitespacesAndNewlines)
            let noteToShow = (noteText?.isEmpty == false) ? noteText : nil

            quranNavigationLink(route: .ayahs(surahID: surah.id, ayah: ayah.id)) {
                SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow)
            }
            .tag(surah.id)
            .rightSwipeActions(
                surahID: surah.id,
                surahName: surah.nameTransliteration,
                ayahID: ayah.id,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(
                surah: surah.id,
                favoriteSurahs: context.favoriteSurahs,
                bookmarkedAyahs: context.bookmarkedAyahs,
                bookmarkedSurah: bookmarkedAyah.surah,
                bookmarkedAyah: bookmarkedAyah.ayah
            )
            .ayahContextMenuModifier(
                surah: surah.id,
                ayah: ayah.id,
                favoriteSurahs: context.favoriteSurahs,
                bookmarkedAyahs: context.bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        }
    }

    @ViewBuilder
    private func favoriteSection(context: SearchDisplayContext) -> some View {
        if !settings.favoriteSurahs.isEmpty && !context.isSearching {
            let sortedFavorites = settings.favoriteSurahs.sorted()
            Section(header: favoriteHeader(count: sortedFavorites.count)) {
                if settings.showFavorites {
                    if settings.gridMode {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                            alignment: .leading,
                            spacing: 10
                        ) {
                            ForEach(sortedFavorites, id: \.self) { surahID in
                                favoriteGridTile(surahID: surahID, context: context)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(sortedFavorites, id: \.self) { surahID in
                            favoriteRow(surahID: surahID, context: context)
                        }
                    }
                }
            }
        }
    }

    /// The shared pill header, for favorites - with the shuffle: open a random favorite surah.
    private func favoriteHeader(count: Int) -> some View {
        SectionPillHeader(
            title: "FAVORITES",
            count: count,
            icon: "star.fill",
            accentTitle: true,
            isExpanded: $settings.showFavorites,
            onShuffle: {
                if let random = settings.favoriteSurahs.randomElement() {
                    push(surahID: random, ayahID: nil)
                }
            }
        )
    }

    @ViewBuilder
    private func favoriteGridTile(surahID: Int, context: SearchDisplayContext) -> some View {
        if let surah = quranData.surah(surahID) {
            #if os(iOS)
            Button {
                settings.hapticFeedback()
                push(surahID: surah.id, ayahID: nil)
            } label: {
                SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id), grid: true)
            }
            .buttonStyle(.plain)
            // The single tappable corner star, matching the main surah grid (SurahRow no longer draws its
            // own inline star).
            .gridFavoriteStar(
                isFavorite: context.favoriteSurahs.contains(surah.id),
                accent: settings.accentColor.color,
                accessibilityName: surah.nameTransliteration
            ) {
                settings.toggleSurahFavorite(surah: surah.id)
            }
            #else
            Button {
                settings.hapticFeedback()
                push(surahID: surah.id, ayahID: nil)
            } label: {
                ZStack(alignment: .topTrailing) {
                    Text("\(surah.id)")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .conditionalGlassEffect(
                            useColor: 0.3,
                            customTint: settings.accentColor.color,
                            interactive: false
                        )

                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(settings.accentColor.color)
                        .padding(4)
                        .offset(x: 6, y: -6)
                }
                .padding(.top, 4)
                .padding(.trailing, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            #endif
        }
    }

    @ViewBuilder
    private func favoriteRow(surahID: Int, context: SearchDisplayContext) -> some View {
        if let surah = quranData.surah(surahID) {
            quranNavigationLink(route: .ayahs(surahID: surah.id, ayah: nil)) {
                SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id)).equatable()
            }
            .rightSwipeActions(
                surahID: surahID,
                surahName: surah.nameTransliteration,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
            #if os(iOS)
            .contextMenu {
                SurahContextMenu(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    favoriteSurahs: context.favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            } /*preview: {
                SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id), hideInfo: false)
            }*/
            #endif
        }
    }

    private var usesDescendingQuranSort: Bool {
        settings.quranSortDirection == .descending
    }

    private func orderedQuranSurahs(showsRevelationOrder: Bool) -> [Surah] {
        // Khatm's Surah grouping is always natural surah order - it reuses the Asc/Desc slot for the
        // Surah/Juz toggle, so `quranSortDirection` (left over from another mode) must not reorder it.
        if settings.quranSortMode == .khatm {
            return quranData.quran
        }

        if settings.quranSortDirection == .surahOrder {
            return quranData.quran
        }

        let surahs: [Surah]

        if showsRevelationOrder {
            surahs = quranData.quran.sorted {
                let left = $0.revelationOrder ?? Int.max
                let right = $1.revelationOrder ?? Int.max
                if left == right { return $0.id < $1.id }
                return left < right
            }
        } else if settings.quranSortMode == .ayahs {
            surahs = quranData.quran.sorted {
                if $0.numberOfAyahs == $1.numberOfAyahs { return $0.id < $1.id }
                return $0.numberOfAyahs < $1.numberOfAyahs
            }
        } else if settings.quranSortMode == .page {
            surahs = quranData.quran.sorted {
                let l = $0.numberOfPages ?? 0
                let r = $1.numberOfPages ?? 0
                if l == r { return $0.id < $1.id }
                return l < r
            }
        } else if settings.quranSortMode == .words {
            surahs = quranData.quran.sorted {
                if $0.wordCount == $1.wordCount { return $0.id < $1.id }
                return $0.wordCount < $1.wordCount
            }
        } else if settings.quranSortMode == .letters {
            surahs = quranData.quran.sorted {
                if $0.letterCount == $1.letterCount { return $0.id < $1.id }
                return $0.letterCount < $1.letterCount
            }
        } else {
            surahs = quranData.quran
        }

        return usesDescendingQuranSort ? Array(surahs.reversed()) : surahs
    }

    private func orderedSearchSurahs(_ surahs: [Surah]) -> [Surah] {
        if settings.quranSortDirection == .surahOrder {
            return surahs
        }

        return usesDescendingQuranSort ? Array(surahs.reversed()) : surahs
    }

    @ViewBuilder
    private func surahContentSections(context: SearchDisplayContext) -> some View {
        // Full browse list only when browsing. Never stack it under explicit page/juz queries.
        if quranData.quran.isEmpty {
            Section {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Loading…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            }
        } else if context.explicitPageOrJuzMode && context.isSearching {
            EmptyView()
        } else if context.isSearching {
            if settings.searchForSurahs {
                boxed(surahSearchSection(context: context))
            }
        } else {
            // Every branch boxed for the same stack-size reason as `content` - see `boxed`.
            switch settings.quranSortMode {
            case .surah:
                boxed(surahBrowseSection(context: context, showsRevelationOrder: false))
            case .ayahs:
                boxed(surahBrowseSection(context: context, showsRevelationOrder: false))
            case .juz:
                boxed(juzSections(context: context))
            case .page:
                boxed(surahBrowseSection(context: context, showsRevelationOrder: false))
            case .revelation:
                boxed(surahBrowseSection(context: context, showsRevelationOrder: true))
            case .khatm:
                boxed(khatmProgressSection())
                boxed(khatmExtraDetailsSection())
                if settings.khatmGroupByJuz {
                    boxed(khatmJuzSections(context: context))
                } else {
                    boxed(surahBrowseSection(context: context, showsRevelationOrder: false))
                }
            case .pages:
                boxed(pagesBrowseSection(context: context))
            case .sajdah:
                boxed(sajdahBrowseSection(context: context))
            case .muqattaat:
                boxed(muqattaatBrowseSection(context: context))
            case .words, .letters:
                boxed(surahBrowseSection(context: context, showsRevelationOrder: false))
            }
        }
    }

    @ViewBuilder
    private func pagesBrowseSection(context: SearchDisplayContext) -> some View {
        let all = quranData.pageAyahResults()
        let rows = usesDescendingQuranSort ? Array(all.reversed()) : all
        if !rows.isEmpty {
            Section(header: pagesHeader(count: rows.count)) {
                specialAyahCollection(rows.map { (surah: $0.surah, ayah: $0.ayah) }, context: context)
            }
        }
    }

    private func pagesHeader(count: Int) -> some View {
        HStack {
            Text("QURAN PAGES")

            Spacer()

            Text("\(count)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
    }

    @ViewBuilder
    private func sajdahBrowseSection(context: SearchDisplayContext) -> some View {
        let rows = usesDescendingQuranSort ? Array(sajdahAyahs.reversed()) : sajdahAyahs
        if !rows.isEmpty {
            Section(header: sajdahHeader(count: rows.count)) {
                specialAyahCollection(rows, context: context)
            }
        }
    }

    private func sajdahHeader(count: Int) -> some View {
        HStack {
            Text("SAJDAH AYAHS")

            Spacer()

            Text("\(count) ۩")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
    }

    @ViewBuilder
    private func muqattaatBrowseSection(context: SearchDisplayContext) -> some View {
        let rows = usesDescendingQuranSort ? Array(muqattaatAyahs.reversed()) : muqattaatAyahs
        if !rows.isEmpty {
            Section(header: muqattaatHeader(count: rows.count)) {
                specialAyahCollection(rows, context: context)
            }
        }
    }

    /// Renders an ayah list (pages / sajdah / muqatta'at) as a 2-column grid or a list, matching the
    /// Bookmarked Ayahs section so grid mode is supported everywhere ayahs are listed.
    @ViewBuilder
    private func specialAyahCollection(_ rows: [(surah: Surah, ayah: Ayah)], context: SearchDisplayContext) -> some View {
        #if os(iOS)
        if settings.gridMode {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, item in
                    specialAyahGridTile(item: item)
                }
            }
            .padding(.vertical, 4)
        } else {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, item in
                specialAyahRow(item: item, context: context)
            }
        }
        #else
        ForEach(Array(rows.enumerated()), id: \.offset) { _, item in
            specialAyahRow(item: item, context: context)
        }
        #endif
    }

    private func specialAyahGridTile(item: (surah: Surah, ayah: Ayah)) -> some View {
        Button {
            settings.hapticFeedback()
            push(surahID: item.surah.id, ayahID: item.ayah.id)
        } label: {
            SurahAyahRow(surah: item.surah, ayah: item.ayah, grid: true)
        }
        .buttonStyle(.plain)
    }

    private func specialAyahRow(item: (surah: Surah, ayah: Ayah), context: SearchDisplayContext) -> some View {
        AyahSearchResultRow(
            surah: item.surah,
            ayah: item.ayah,
            favoriteSurahs: context.favoriteSurahs,
            bookmarkedAyahs: context.bookmarkedAyahs,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID,
            compactArabic: true,
            onSelectAyah: columnAyahSelectionHandler
        )
    }

    private func muqattaatHeader(count: Int) -> some View {
        HStack {
            Text("MUQATTA'AT AYAHS")

            Spacer()

            Text("\(count) حروف")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
    }

    private var khatmTotalAyahs: Int {
        quranData.quran.reduce(0) { $0 + $1.numberOfAyahs }
    }

    private var khatmCompletedAyahs: Int {
        settings.khatmTotalCompleted(in: quranData.quran)
    }

    private var khatmPercent: Int {
        guard khatmTotalAyahs > 0 else { return 0 }
        return Int((Double(khatmCompletedAyahs) / Double(khatmTotalAyahs) * 100).rounded())
    }

    @ViewBuilder
    private func khatmProgressSection() -> some View {
        Section {
            Text("Khatm mode tracks your progress through a complete reading of the Quran. As you read, ayahs are marked as completed so you can see how much of the Quran you have finished by ayah, page, and juz.")
                .font(.caption)
                .foregroundColor(.secondary)

            if !settings.isHafsDisplay {
                // Khatm progress is Hafs-only (marking/completion are guarded by `isHafsDisplay`), so the
                // stats below sit at 0 on any other riwayah. Say why rather than leave it unexplained.
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(settings.accentColor.color)

                    Text("Khatm progress is only tracked on Hafs an Asim. Switch back to the default riwayah in Quran settings to track your reading.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Automatically Mark Ayahs", isOn: $settings.automaticKhatmCompletion.animation(.easeInOut))
                    .font(.subheadline)

                Text("When on, ayahs are marked as completed as soon as they appear while you read. Turn this off to mark ayahs only when you tap them.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            VStack {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(khatmPercent)% completed")
                        .font(.headline)
                        .foregroundStyle(settings.accentColor.color)

                    Spacer()

                    Text("\(khatmCompletedAyahs)/\(khatmTotalAyahs) ayahs")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(khatmCompletedAyahs), total: Double(max(khatmTotalAyahs, 1)))
                    .tint(settings.accentColor.color)
            }

            // Juz / Pages / Ayahs metrics using cached stats
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    let totalJuz = quranData.juzSections.count
                    let completedJuz = khatmJuzStats.values.reduce(0) { $0 + ($1.completed == $1.total ? 1 : 0) }
                    let juzPercent = totalJuz > 0 ? Int((Double(completedJuz) / Double(totalJuz) * 100).rounded()) : 0

                    // The actual mushaf page range: the last surah's end page IS the max page in
                    // mushaf order (canonical 604 fallback) - O(1), where this used to flatMap all
                    // 6,236 ayahs on every render of the khatm section.
                    let totalPages = totalMushafPages
                    let completedPages = khatmPageStats.keys.filter { page in
                        if let stats = khatmPageStats[page] { return stats.completed == stats.total }
                        return false
                    }.count
                    let pagePercent = totalPages > 0 ? Int((Double(completedPages) / Double(totalPages) * 100).rounded()) : 0

                    Text("Juz: \(completedJuz)/\(totalJuz) (\(juzPercent)%)")
                        .font(.subheadline.monospacedDigit())
                    Text("Pages: \(completedPages)/\(totalPages) (\(pagePercent)%)")
                        .font(.subheadline.monospacedDigit())
                }

                Spacer()

                Button("Extra") {
                    settings.hapticFeedback()
                    withAnimation {
                        showKhatmExtraDetails.toggle()
                    }
                    if showKhatmExtraDetails && khatmExtraTotals == nil {
                        loadKhatmExtraTotalsIfNeeded()
                    }
                }
                .font(.subheadline)

                if khatmEditMode {
                    Divider()

                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.resetAllKhatmProgress()
                        }
                    } label: {
                        Label("Reset Khatm Progress", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        } header: {
            Text("KHATM PROGRESS")
        }
        .onChange(of: settings.automaticKhatmCompletion) { _ in
            settings.hapticFeedback()
        }
        .onReceive(settings.objectWillChange) { _ in
            computeKhatmStatsIfNeeded(force: false)
        }
        .onAppear {
            computeKhatmStatsIfNeeded(force: false)
        }
    }

    @ViewBuilder
    private func khatmExtraDetailsSection() -> some View {
        if showKhatmExtraDetails {
            let totals = khatmExtraTotals
            let isLoading = khatmExtraLoading

            Section {
                VStack {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Spacer()
                            Text("Calculating…")
                                .foregroundStyle(.secondary)
                        }
                    } else if let totals {
                        HStack {
                            Text("Words: \(totals.words)/\(totals.totalWords)")

                            Spacer()

                            Text("\(Int((Double(totals.words)/Double(max(totals.totalWords,1))*100)).description)%")
                                .monospacedDigit()
                        }

                        HStack {
                            Text("Letters: \(totals.letters)/\(totals.totalLetters)")

                            Spacer()

                            Text("\(Int((Double(totals.letters)/Double(max(totals.totalLetters,1))*100)).description)%")
                                .monospacedDigit()
                        }
                    } else {
                        HStack {
                            Text("No data")
                            Spacer()
                        }
                    }
                }
                .font(.caption)
            }
        }
    }

    private func loadKhatmExtraTotalsIfNeeded() {
        guard khatmExtraTotals == nil && !khatmExtraLoading else { return }
        khatmExtraLoading = true

        // Capture snapshot and completed set on main actor to avoid threading issues.
        let quranSnapshot = quranData.quran
        let displayQiraah = settings.displayQiraahForArabic
        var completedSet = Set<String>()
        for surah in quranSnapshot {
            for ayah in surah.ayahs {
                if settings.isKhatmAyahComplete(surah: surah.id, ayah: ayah.id) {
                    completedSet.insert("\(surah.id)-\(ayah.id)")
                }
            }
        }

        Task.detached(priority: .utility) { [quranSnapshot, displayQiraah, completedSet] in
            var wordsCompleted = 0
            var lettersCompleted = 0
            var totalWords = 0
            var totalLetters = 0

            for surah in quranSnapshot {
                for ayah in surah.ayahs {
                    let text = ayah.textCleanArabic(for: displayQiraah)
                    let cleaned = text.replacingOccurrences(of: "\u{200F}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let wordCount = cleaned.split { $0.isWhitespace }.count
                    let letterCount = cleaned.filter { !$0.isWhitespace }.count

                    totalWords += wordCount
                    totalLetters += letterCount

                    if completedSet.contains("\(surah.id)-\(ayah.id)") {
                        wordsCompleted += wordCount
                        lettersCompleted += letterCount
                    }
                }
            }

            let totals = (wordsCompleted: wordsCompleted, lettersCompleted: lettersCompleted, totalWords: totalWords, totalLetters: totalLetters)
            await MainActor.run {
                khatmExtraTotals = (totals.wordsCompleted, totals.lettersCompleted, totals.totalWords, totals.totalLetters)
                khatmExtraLoading = false
            }
        }
    }

    private func computeKhatmStatsIfNeeded(force: Bool = false) {
        let totalCompleted = settings.khatmTotalCompleted(in: quranData.quran)
        guard force || totalCompleted != khatmLastTotalSignature else { return }
        khatmLastTotalSignature = totalCompleted

        var pageMap: [Int: (completed: Int, total: Int)] = [:]
        var juzMap: [Int: (completed: Int, total: Int)] = [:]

        for surah in quranData.quran {
            for ayah in surah.ayahs {
                guard let page = ayah.page else { continue }
                let juz = ayah.juz ?? -1

                pageMap[page, default: (0,0)].total += 1
                juzMap[juz, default: (0,0)].total += 1

                if settings.isKhatmAyahComplete(surah: surah.id, ayah: ayah.id) {
                    pageMap[page, default: (0,0)].completed += 1
                    juzMap[juz, default: (0,0)].completed += 1
                }
            }
        }

        khatmPageStats = pageMap
        khatmJuzStats = juzMap
    }


    @ViewBuilder
    private func surahBrowseSection(context: SearchDisplayContext, showsRevelationOrder: Bool) -> some View {
        let browsedSurahs = orderedQuranSurahs(showsRevelationOrder: showsRevelationOrder)

        #if os(iOS)
        Section(header: surahBrowseHeader(showsRevelationOrder: showsRevelationOrder)) { }
            .padding(.bottom, -12)

        if settings.gridMode {
            Section {
                surahGrid(browsedSurahs, context: context)
            }
        } else {
            ForEach(browsedSurahs, id: \.id) { surah in
                Section {
                    surahRow(surah: surah, context: context, showsRevelationOrder: showsRevelationOrder)
                }
            }
        }
        #else
        // watchOS: keep the rows inside the header's own section. An empty `Section(header:) {}` followed
        // by loose rows (the iOS pattern) leaves a large blank gap under the "SURAHS" title on watchOS.
        Section(header: surahBrowseHeader(showsRevelationOrder: showsRevelationOrder)) {
            ForEach(browsedSurahs, id: \.id) { surah in
                surahRow(surah: surah, context: context, showsRevelationOrder: showsRevelationOrder)
            }
        }
        #endif
    }

    #if os(iOS)
    private var surahGridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    @ViewBuilder
    private func surahGrid(_ surahs: [Surah], context: SearchDisplayContext) -> some View {
        LazyVGrid(columns: surahGridColumns, alignment: .leading, spacing: 10) {
            ForEach(surahs, id: \.id) { surah in
                surahGridTile(surah: surah, context: context)
            }
        }
        .padding(.vertical, 4)
    }

    private func surahGridTile(surah: Surah, context: SearchDisplayContext) -> some View {
        Button {
            settings.hapticFeedback()
            push(surahID: surah.id, ayahID: nil)
        } label: {
            SurahRow(
                surah: surah,
                isFavorite: context.favoriteSurahs.contains(surah.id),
                khatmCompletedAyahs: settings.quranSortMode == .khatm ? settings.khatmCompletedCount(for: surah) : nil,
                khatmTotalAyahs: settings.quranSortMode == .khatm ? surah.numberOfAyahs : nil,
                searchQuery: searchText,
                grid: true
            )
        }
        .buttonStyle(.plain)
        // The same corner star every grid tile carries - context menus inside a grid-in-a-list-row lift the
        // whole row, so the star is the grid's tap-to-favorite.
        .gridFavoriteStar(
            isFavorite: context.favoriteSurahs.contains(surah.id),
            accent: settings.accentColor.color,
            accessibilityName: surah.nameTransliteration
        ) {
            settings.toggleSurahFavorite(surah: surah.id)
        }
        .id("surah_\(surah.id)")
        .onAppear {
            if surah.id == scrollToSurahID {
                scrollToSurahID = -1
            }
        }
    }
    #endif

    @ViewBuilder
    private func surahBrowseHeader(showsRevelationOrder: Bool) -> some View {
        if showsRevelationOrder {
            SurahsHeader(text: "REVELATION ORDER")
        } else {
            SurahsHeader()
        }
    }

    @ViewBuilder
    private func surahSearchSection(context: SearchDisplayContext) -> some View {
        let filteredSurahs = orderedSearchSurahs(context.filteredSurahs)

        Group {
            Section(header: surahSectionHeader(context: context)) { }
                .padding(.bottom, -12)

            // Surah-NAME results honor grid mode, the same as browsing. Ayah-TEXT results (searchResultSections)
            // always stay a list - grid tiles can't show the matched ayah text.
            #if os(iOS)
            if settings.gridMode {
                if !filteredSurahs.isEmpty {
                    Section {
                        surahGrid(filteredSurahs, context: context)
                    }
                }
            } else {
                surahSearchListRows(filteredSurahs, context: context)
            }
            #else
            surahSearchListRows(filteredSurahs, context: context)
            #endif

            // A bare "0" pill reads as broken; say it outright.
            if filteredSurahs.isEmpty, context.isSearching {
                Section {
                    Text("No surahs match your search.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func surahSearchListRows(_ filteredSurahs: [Surah], context: SearchDisplayContext) -> some View {
        ForEach(filteredSurahs, id: \.id) { surah in
            Section {
                quranNavigationLink(route: .ayahs(surahID: surah.id, ayah: nil)) {
                    surahSearchRow(surah: surah, context: context)
                }
                .id("surah_\(surah.id)")
                .onAppear {
                    if surah.id == scrollToSurahID {
                        scrollToSurahID = -1
                    }
                }
                .rightSwipeActions(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
                .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
                #if os(iOS)
                .contextMenu {
                    SurahContextMenu(
                        surahID: surah.id,
                        surahName: surah.nameTransliteration,
                        favoriteSurahs: context.favoriteSurahs,
                        searchText: $searchText,
                        scrollToSurahID: $scrollToSurahID
                    )
                }
                #endif
                .animation(.easeInOut, value: searchText)
            }
        }
    }

    @ViewBuilder
    private func surahSearchRow(surah: Surah, context: SearchDisplayContext) -> some View {
        if settings.quranSortMode == .revelation {
            HStack(spacing: 10) {
                revelationOrderBadge(surah.revelationOrder ?? 0)

                SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id), searchQuery: searchText).equatable()
            }
        } else {
            SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id), searchQuery: searchText).equatable()
        }
    }

    private var revelationBadgeWidth: CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let text = "#114" as NSString
        let size = text.size(withAttributes: [.font: font])
        return size.width + 8
    }

    private func revelationOrderBadge(_ order: Int) -> some View {
        Text("#\(order)")
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(settings.accentColor.color)
            .frame(width: revelationBadgeWidth, alignment: .center)
            .accessibilityLabel("Revelation order \(order)")
    }

    @ViewBuilder
    private func surahSectionHeader(context: SearchDisplayContext) -> some View {
        if context.isSearching {
            HStack {
                Text("SURAH SEARCH RESULTS")

                Spacer()

                Text("\(context.filteredSurahs.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .conditionalGlassEffect()
                    .padding(.vertical, -16)
            }
        } else {
            SurahsHeader()
        }
    }

    @ViewBuilder
    private func juzSections(context: SearchDisplayContext) -> some View {
        // Descending must reverse both the juz order *and* the surah rows within each juz, so the list
        // reads as a true reverse of ascending (e.g. juz 30 first, and inside it An-Nas before An-Naba').
        let sections = usesDescendingQuranSort
            ? quranData.juzSections.reversed().map { section in
                QuranData.JuzSectionData(
                    juz: section.juz,
                    surahIDs: Array(section.surahIDs.reversed()),
                    rows: Array(section.rows.reversed())
                )
            }
            : quranData.juzSections

        ForEach(sections) { sectionData in
            let juz = sectionData.juz
            Section(header: JuzHeader(juz: juz)) {
                #if os(iOS)
                if settings.gridMode {
                    LazyVGrid(columns: surahGridColumns, alignment: .leading, spacing: 10) {
                        ForEach(sectionData.rows) { row in
                            juzGridTile(row: row, context: context)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(sectionData.rows) { row in
                        preprocessedJuzRow(row: row, context: context)
                    }
                }
                #else
                ForEach(sectionData.rows) { row in
                    preprocessedJuzRow(row: row, context: context)
                }
                #endif
            }
            .sectionIndexLabelWhenAvailable("\(juz.id)")
        }
    }

    /// Khatm-mode Juz grouping: each surah is listed once, under the juz it *starts* in (via `firstJuz`),
    /// so a surah that merely continues into later juz isn't repeated. Every juz header is still shown, so
    /// juz that no surah opens (e.g. juz 2, 5) render empty. Rows carry the same khatm progress as the Surah
    /// grouping because `surahRow`/`surahGridTile` read `quranSortMode == .khatm`.
    @ViewBuilder
    private func khatmJuzSections(context: SearchDisplayContext) -> some View {
        ForEach(QuranData.juzList, id: \.id) { juz in
            let surahs = quranData.quran.filter { ($0.firstJuz ?? $0.ayahs.first?.juz) == juz.id }
            Section(header: JuzHeader(juz: juz)) {
                #if os(iOS)
                if settings.gridMode {
                    surahGrid(surahs, context: context)
                } else {
                    ForEach(surahs, id: \.id) { surah in
                        surahRow(surah: surah, context: context)
                    }
                }
                #else
                ForEach(surahs, id: \.id) { surah in
                    surahRow(surah: surah, context: context)
                }
                #endif
            }
            .sectionIndexLabelWhenAvailable("\(juz.id)")
        }
    }

    #if os(iOS)
    @ViewBuilder
    private func juzGridTile(row: QuranData.JuzSectionData.Row, context: SearchDisplayContext) -> some View {
        if let surah = quranData.surah(row.surahID) {
            let route = preprocessedJuzRoute(row: row, surah: surah)
            let ayahID: Int? = { if case let .ayahs(_, ayah) = route { return ayah } else { return nil } }()
            Button {
                settings.hapticFeedback()
                push(surahID: surah.id, ayahID: ayahID)
            } label: {
                juzGridLabel(row: row, surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id))
            }
            .buttonStyle(.plain)
            // The single tappable corner star, matching the main surah grid.
            .gridFavoriteStar(
                isFavorite: context.favoriteSurahs.contains(surah.id),
                accent: settings.accentColor.color,
                accessibilityName: surah.nameTransliteration
            ) {
                settings.toggleSurahFavorite(surah: surah.id)
            }
        }
    }

    @ViewBuilder
    private func juzGridLabel(row: QuranData.JuzSectionData.Row, surah: Surah, isFavorite: Bool) -> some View {
        switch row.kind {
        case .plain:
            SurahRow(surah: surah, isFavorite: isFavorite, grid: true)
        case .start(let ayah):
            SurahRow(surah: surah, ayah: ayah, isFavorite: isFavorite, grid: true)
        case .end(let ayah):
            SurahRow(surah: surah, ayah: ayah, end: true, isFavorite: isFavorite, grid: true)
        }
    }
    #endif

    @ViewBuilder
    private func preprocessedJuzRow(row: QuranData.JuzSectionData.Row, context: SearchDisplayContext) -> some View {
        if let surah = quranData.surah(row.surahID) {
            quranNavigationLink(route: preprocessedJuzRoute(row: row, surah: surah)) {
                preprocessedJuzLabel(row: row, surah: surah, favoriteSurahs: context.favoriteSurahs)
            }
            #if os(iOS)
            .rightSwipeActions(
                surahID: surah.id,
                surahName: surah.nameTransliteration,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
            .contextMenu {
                SurahContextMenu(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    favoriteSurahs: context.favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            }
            #endif
        }
    }

    @ViewBuilder
    private func pageSections(context: SearchDisplayContext) -> some View {
        let sections = usesDescendingQuranSort ? Array(quranData.pageSections.reversed()) : quranData.pageSections

        ForEach(sections) { pageGroup in
            Section(header: PageHeader(page: pageGroup.page)) {
                ForEach(pageGroup.surahIDs, id: \.self) { surahID in
                    if let surah = quranData.surah(surahID) {
                        surahRow(surah: surah, context: context)
                    }
                }
            }
            .sectionIndexLabelWhenAvailable("\(pageGroup.surahIDs.first ?? pageGroup.page)")
        }
    }

    @ViewBuilder
    private func preprocessedJuzDestination(row: QuranData.JuzSectionData.Row, surah: Surah) -> some View {
        routeDestination(preprocessedJuzRoute(row: row, surah: surah))
    }

    private func preprocessedJuzRoute(row: QuranData.JuzSectionData.Row, surah: Surah) -> QuranRoute {
        let ayah: Int?

        switch row.kind {
        case .plain:
            ayah = nil
        case .start(let startAyah):
            ayah = startAyah > 1 ? startAyah : nil
        case .end(let endAyah):
            ayah = endAyah < surah.numberOfAyahs ? endAyah : nil
        }

        return .ayahs(surahID: surah.id, ayah: ayah)
    }

    @ViewBuilder
    private func preprocessedJuzLabel(
        row: QuranData.JuzSectionData.Row,
        surah: Surah,
        favoriteSurahs: Set<Int>
    ) -> some View {
        switch row.kind {
        case .plain:
            SurahRow(surah: surah, isFavorite: favoriteSurahs.contains(surah.id)).equatable()
        case .start(let ayah):
            SurahRow(surah: surah, ayah: ayah, isFavorite: favoriteSurahs.contains(surah.id)).equatable()
        case .end(let ayah):
            SurahRow(surah: surah, ayah: ayah, end: true, isFavorite: favoriteSurahs.contains(surah.id)).equatable()
        }
    }

    @ViewBuilder
    private func revelationSections(context: SearchDisplayContext) -> some View {
        Section(header: SurahsHeader(text: "REVELATION ORDER")) {
            ForEach(quranData.revelationOrderSurahIDs, id: \.self) { surahID in
                if let surah = quranData.surah(surahID) {
                    Group {
                        quranNavigationLink(route: .ayahs(surahID: surah.id, ayah: nil)) {
                            HStack(spacing: 10) {
                                revelationOrderBadge(surah.revelationOrder ?? 0)

                                SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id)).equatable()
                            }
                        }
                    }
                    .id("surah_\(surah.id)")
                    #if os(iOS)
                    .rightSwipeActions(
                        surahID: surah.id,
                        surahName: surah.nameTransliteration,
                        searchText: $searchText,
                        scrollToSurahID: $scrollToSurahID
                    )
                    .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
                    .contextMenu {
                        SurahContextMenu(
                            surahID: surah.id,
                            surahName: surah.nameTransliteration,
                            favoriteSurahs: context.favoriteSurahs,
                            searchText: $searchText,
                            scrollToSurahID: $scrollToSurahID
                        )
                    }
                    #endif
                }
            }
        }
    }

    @ViewBuilder
    private func surahRow(surah: Surah, context: SearchDisplayContext, showsRevelationOrder: Bool = false) -> some View {
        let khatmCompleted = settings.quranSortMode == .khatm ? settings.khatmCompletedCount(for: surah) : nil
        let khatmTotal = settings.quranSortMode == .khatm ? surah.numberOfAyahs : nil

        quranNavigationLink(route: .ayahs(surahID: surah.id, ayah: nil)) {
            if showsRevelationOrder {
                HStack(spacing: 10) {
                    revelationOrderBadge(surah.revelationOrder ?? 0)

                    khatmSurahRowLabel(surah: surah, context: context, completed: khatmCompleted, total: khatmTotal)
                }
            } else {
                khatmSurahRowLabel(surah: surah, context: context, completed: khatmCompleted, total: khatmTotal)
            }
        }
        .id("surah_\(surah.id)")
        #if os(iOS)
        .rightSwipeActions(
            surahID: surah.id,
            surahName: surah.nameTransliteration,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
        .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
        .contextMenu {
            SurahContextMenu(
                surahID: surah.id,
                surahName: surah.nameTransliteration,
                favoriteSurahs: context.favoriteSurahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        }
        #endif
    }

    private func khatmSurahRowLabel(
        surah: Surah,
        context: SearchDisplayContext,
        completed: Int?,
        total: Int?
    ) -> some View {
        HStack(spacing: 8) {
            SurahRow(
                surah: surah,
                isFavorite: context.favoriteSurahs.contains(surah.id),
                khatmCompletedAyahs: completed,
                khatmTotalAyahs: total,
                searchQuery: context.isSearching ? searchText : ""
            )
            .equatable()
            .frame(maxWidth: .infinity, alignment: .leading)

            if khatmEditMode, settings.quranSortMode == .khatm, (completed ?? 0) > 0 {
                Button(role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.resetKhatmProgress(for: surah)
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func searchResultSections(context: SearchDisplayContext) -> some View {
        if context.isSearching {
            // Page/juz rows for explicit queries are inserted above surahContentSections. For a bare number
            // they go here, BELOW the surah match (juz before page). Each shows the range's Start/End ayah.
            // Boxed for the same stack-size reason as `content` - see `boxed`.
            if !context.explicitPageOrJuzMode {
                boxed(juzSearchSection(context: context))
                boxed(pageSearchSection(context: context))
            }

            if !context.explicitPageOrJuzMode {
                boxed(ayahSearchSection(context: context))
            }
        }
    }

    @ViewBuilder
    private func pageSearchSection(context: SearchDisplayContext) -> some View {
        if let page = context.pageJuzQuery.page {
            let ayahs = quranData.ayahs(onPage: page)
            if let first = ayahs.first {
                Section(header: pageSearchHeader(title: "PAGE SEARCH RESULT", valueText: "Page \(page) • \(ayahs.count) Ayahs")) {
                    pageJuzRangeRows(first: first, last: ayahs.last, count: ayahs.count)
                }
            }
        }
    }

    @ViewBuilder
    private func juzSearchSection(context: SearchDisplayContext) -> some View {
        if let juz = context.pageJuzQuery.juz {
            let ayahs = quranData.ayahs(inJuz: juz)
            if let first = ayahs.first {
                Section(header: pageSearchHeader(title: "JUZ SEARCH RESULT", valueText: "Juz \(juz) • \(ayahs.count) Ayahs")) {
                    pageJuzRangeRows(first: first, last: ayahs.last, count: ayahs.count)
                }
            }
        }
    }

    /// A page/juz search result shows the range's FIRST and LAST ayah (labeled Start / End) rather than
    /// every ayah - like Juz View marks where a section begins and ends. The header's count pill conveys
    /// the total. A single-ayah range shows just the one row (unlabeled).
    @ViewBuilder
    private func pageJuzRangeRows(first: (surah: Surah, ayah: Ayah), last: (surah: Surah, ayah: Ayah)?, count: Int) -> some View {
        if count > 1, let last {
            pageJuzAyahRow(item: first, leadingLabel: "Start")
            pageJuzAyahRow(item: last, leadingLabel: "End")
        } else {
            pageJuzAyahRow(item: first)
        }
    }

    @ViewBuilder
    private func pageJuzAyahRow(item: (surah: Surah, ayah: Ayah), leadingLabel: String? = nil) -> some View {
        quranNavigationLink(route: .ayahs(surahID: item.surah.id, ayah: item.ayah.id)) {
            VStack(alignment: .leading, spacing: 4) {
                if let leadingLabel {
                    Text(leadingLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                // Full ayah row (same font/tajweed/beginner mode/highlight as the reading view); already
                // single-line internally.
                SurahAyahRow(surah: item.surah, ayah: item.ayah)
            }
        }
    }

    private func pageSearchHeader(title: String, valueText: String) -> some View {
        HStack {
            Text(title)

            Spacer()

            Text(valueText)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
    }

    @ViewBuilder
    private func ayahSearchSection(context: SearchDisplayContext) -> some View {
        if context.isExactAyahReference {
            Section(header: ayahSearchHeader(context: context)) {
                ayahExactMatchRows(context: context)
            }
        } else if !quranData.isVerseSearchReady {
            Section {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Preparing ayah search…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            }
        } else {
            #if os(iOS)
            // (The Ask AI block - prompt row, streamed answer, cited ayahs - now renders in
            // `askAISection`, hoisted ABOVE the surah results in `content`.)

            // Both result kinds landed: ONE segmented switch decides which list fills the page - the
            // AI's ranked meaning matches or the exhaustive keyword lists - never both stacked. With
            // only one kind present there is nothing to choose, so no picker: it just shows.
            let showResultsPicker = !aiHits.isEmpty && !verseHits.isEmpty
            if showResultsPicker {
                Section {
                    Picker("Results", selection: $showKeywordResults.animation(.easeInOut)) {
                        Text("AI Results").tag(false)
                        Text("Keyword Results").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }

            if !showResultsPicker || !showKeywordResults {
                // AI results appear AUTOMATICALLY at the top - no mode to enter. The section shows the
                // one-time build progress the first time, then the ranked semantic matches.
                boxed(aiResultsSection)
            }

            let keywordVisible = !showResultsPicker || showKeywordResults
            #else
            let keywordVisible = true
            #endif

            if keywordVisible {
                // Computed HERE, not at the top of the section: the filter+sort over every verse hit
                // is dead weight on the exact-reference path and while the AI list is on screen.
                let bestHits = bestAyahHitsForCurrentQuery()
                // "Top" picks only matter when the AI list isn't the one on screen.
                #if os(iOS)
                let showBest = !bestHits.isEmpty && (aiHits.isEmpty || showKeywordResults)
                #else
                let showBest = !bestHits.isEmpty
                #endif
                if showBest {
                    Section(header: bestAyahHeader(count: bestHits.count)) {
                        ForEach(bestHits) { hit in
                            ayahHitRow(hit: hit, context: context, section: "best")
                        }
                    }
                }

                Section(header: ayahSearchHeader(context: context)) {
                    ayahExactMatchRows(context: context)

                    // Nothing exact and nothing from the keyword sweep: say so instead of a bare header.
                    if context.exactMatch.surah == nil || context.exactMatch.ayah == nil,
                       verseHitsGroupedBySurah.isEmpty {
                        Text("No ayahs match your search.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(verseHitsGroupedBySurah, id: \.surahId) { group in
                    Section {
                        ForEach(group.hits) { hit in
                            ayahHitRow(hit: hit, context: context, section: "grouped")
                        }
                    } header: {
                        surahSearchSectionHeader(surahId: group.surahId, matchCount: group.hits.count)
                    }
                }

                Section {
                    ayahLoadMoreControls(context: context)
                }
            }
        }
    }

    #if os(iOS)
    /// The semantic results block, shown automatically for any eligible (English text) query: the
    /// one-time build progress first, then the ranked matches - each the standard ayah search row.
    /// Deliberately SILENT otherwise (Arabic query, build failed, no semantic matches): an automatic
    /// section must never nag - the keyword results below always carry the search.
    @ViewBuilder
    private var aiResultsSection: some View {
        if aiQueryEligible {
            if semanticEngine.isReady(quranSemanticCorpusID) {
                if !aiHits.isEmpty {
                    Section(header: aiResultsHeader(count: aiHits.count)) {
                        ForEach(aiHits) { hit in
                            aiHitRow(hit)
                        }
                    }
                }
            } else if !semanticEngine.failedCorpora.contains(quranSemanticCorpusID) {
                Section { AISearchStatusRow(progress: semanticEngine.progress(quranSemanticCorpusID), failed: false) }
            }
        }
    }

    /// The one-tap Ask entry for non-question queries: press to run the grounded on-device answer for
    /// exactly what's typed.
    private var askPromptRow: some View {
        Button {
            settings.hapticFeedback()
            runAsk(query: searchText, manual: true)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)

                Text("Ask AI about \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundColor(settings.accentColor.color)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .conditionalGlassEffect(clear: true, rectangle: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func aiResultsHeader(count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("AI RESULTS")

            Spacer()

            Text(String(count))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
    }

    /// One semantic match - the standard compact ayah search row (same fonts, tajweed-off rule, arrival
    /// term travel) so AI results read exactly like every other ayah result.
    @ViewBuilder
    private func aiHitRow(_ hit: AISearchHit) -> some View {
        if let surah = quranData.surah(hit.surah),
           let ayah = quranData.ayah(surah: hit.surah, ayah: hit.ayah) {
            quranNavigationLink(route: .ayahs(surahID: surah.id, ayah: ayah.id)) {
                AyahSearchRow(
                    surahName: surah.nameTransliteration,
                    surah: hit.surah,
                    ayah: hit.ayah,
                    query: searchText,
                    arabic: ayah.displayArabicText(surahId: hit.surah, clean: settings.cleanArabicText),
                    transliteration: ayah.textTransliteration,
                    englishSaheeh: ayah.textEnglishSaheeh,
                    englishMustafa: ayah.textEnglishMustafa,
                    page: ayah.page,
                    juz: ayah.juz,
                    favoriteSurahs: Set(settings.favoriteSurahs),
                    bookmarkedAyahs: Set(settings.bookmarkedAyahs.map(\.id)),
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    qiraahRefreshKey: settings.displayQiraah,
                    compact: true,
                    disableTajweedColors: true
                )
                .id("ayah-results-ai-\(surah.id)-\(ayah.id)")
            }
        }
    }
    #endif

    private func bestAyahHeader(count: Int) -> some View {
        HStack {
            Text("TOP AYAH RESULTS")

            Spacer()

            Text(String(count))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
    }

    private func bestAyahHitsForCurrentQuery(maxResults: Int = 3) -> [VerseIndexEntry] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 4, !verseHits.isEmpty else { return [] }

        let normalizedQuery = normalizedBestMatchText(trimmed)
        guard !normalizedQuery.isEmpty else { return [] }

        func sources(_ hit: VerseIndexEntry) -> [String] {
            [hit.arabicBlob, hit.englishBlob, hit.englishExactBlob]
        }

        // An "exact" hit contains the full query phrase contiguously, not just its tokens scattered around.
        func isExactPhraseHit(_ hit: VerseIndexEntry) -> Bool {
            sources(hit).contains { $0.contains(normalizedQuery) }
        }

        let exactHits = verseHits.filter(isExactPhraseHit)

        // Only worth a separate "Top Ayah Results" section when there's a real contrast: some loaded hits
        // contain the exact phrase and others only matched loosely. If every hit (or no hit) is an exact
        // phrase match, the section just duplicates the list below - so suppress it instead of showing a
        // redundant "top" that's no better than the rest.
        guard !exactHits.isEmpty, exactHits.count < verseHits.count else { return [] }

        // Rank the exact hits so the strongest phrasing (whole-blob equality, then prefix) leads.
        func rank(_ hit: VerseIndexEntry) -> Int {
            let s = sources(hit)
            if s.contains(where: { $0 == normalizedQuery }) { return 3 }
            if s.contains(where: { $0.hasPrefix(normalizedQuery) }) { return 2 }
            return 1
        }

        let ordered = exactHits.sorted {
            let r0 = rank($0), r1 = rank($1)
            if r0 != r1 { return r0 > r1 }
            if $0.surah != $1.surah { return $0.surah < $1.surah }
            return $0.ayah < $1.ayah
        }

        var selected: [VerseIndexEntry] = []
        var seen = Set<String>()
        for hit in ordered {
            let key = "\(hit.surah)-\(hit.ayah)"
            if seen.insert(key).inserted {
                selected.append(hit)
            }
            if selected.count >= maxResults { break }
        }

        return selected
    }

    private func normalizedBestMatchText(_ text: String) -> String {
        settings.cleanSearch(text, whitespace: true)
            .removingArabicDiacriticsAndSigns
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private func surahSearchSectionHeader(surahId: Int, matchCount: Int? = nil) -> some View {
        Group {
            if let s = quranData.surah(surahId) {
                let latinHeader1 = "\(s.id). \(s.nameTransliteration)".uppercased()

                let latinHeader2 = "(\(s.nameEnglish)) - ".uppercased()

                HStack(spacing: 6) {
                    Text(latinHeader1)

                    Text(latinHeader2)
                        .font(.caption)

                    Text(settings.cleanedQuranArabic(s.nameArabic))
                        .font(.caption)

                    // How many of the ayah matches live in THIS surah - the total pill sits up top.
                    if let matchCount {
                        Spacer()

                        CountPill(count: matchCount)
                    }
                }
            } else {
                Text("SURAH \(surahId)")
            }
        }
    }

    @ViewBuilder
    private func ayahExactMatchRows(context: SearchDisplayContext) -> some View {
        if let surah = context.exactMatch.surah,
           let ayah = context.exactMatch.ayah {
            AyahSearchResultRow(
                surah: surah,
                ayah: ayah,
                favoriteSurahs: context.favoriteSurahs,
                bookmarkedAyahs: context.bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                // Exact "S:A" match is a single row with no search-term highlight to conflict, so show
                // tajweed colors here (text-search hits keep them off for the term highlight + perf).
                disableTajweedColors: false,
                onSelectAyah: columnAyahSelectionHandler
            )
        }
    }

    private func ayahSearchHeader(context: SearchDisplayContext) -> some View {
        HStack {
            Text("AYAH SEARCH RESULTS")

            Spacer()

            Text(context.ayahCountDisplayText)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
    }

    @ViewBuilder
    private func ayahHitRow(hit: VerseIndexEntry, context: SearchDisplayContext, section: String) -> some View {
        if let surah = quranData.surah(hit.surah),
           let ayah = quranData.ayah(surah: hit.surah, ayah: hit.ayah) {
            let row = AyahSearchRow(
                surahName: surah.nameTransliteration,
                surah: hit.surah,
                ayah: hit.ayah,
                query: searchText,
                arabic: ayah.displayArabicText(surahId: hit.surah, clean: settings.cleanArabicText),
                transliteration: ayah.textTransliteration,
                englishSaheeh: ayah.textEnglishSaheeh,
                englishMustafa: ayah.textEnglishMustafa,
                page: ayah.page,
                juz: ayah.juz,
                favoriteSurahs: context.favoriteSurahs,
                bookmarkedAyahs: context.bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                qiraahRefreshKey: settings.displayQiraah,
                compact: true,
                disableTajweedColors: true
            )
            // Section-scoped id: the same ayah can appear in both "best" and "grouped" sections, and
            // duplicate List identities cause scroll jank. No per-row .animation here - that previously
            // re-animated every visible row whenever verseHits.count changed (e.g. while loading more
            // results during scroll), which is what made scrolling feel laggy versus SurahView.
            .id("ayah-results-\(section)-\(surah.id)-\(ayah.id)")

            quranNavigationLink(route: .ayahs(surahID: surah.id, ayah: ayah.id)) {
                row
            }
            // The search term rides along via the route-change hooks on the navigation state (see
            // `stashArrivalTerm`) - a gesture here, even a simultaneous one, swallowed the
            // NavigationLink's own tap and made the hit rows dead.
        }
    }

    @ViewBuilder
    private func ayahLoadMoreControls(context: SearchDisplayContext) -> some View {
        if context.canShowMoreAyahHits && quranData.isVerseSearchReady {
            #if os(iOS)
            Menu {
                Text("Load More")
                    .foregroundStyle(.secondary)

                ForEach([5, 10, 20], id: \.self) { amount in
                    Button {
                        settings.hapticFeedback()
                        loadMoreAyahMatches(amount)
                    } label: {
                        Label("Load \(amount)", systemImage: "\(amount).circle")
                    }
                }
            } label: {
                Text("Load more ayah matches")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .conditionalGlassEffect()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .listRowSeparator(.hidden, edges: .bottom)
            .padding(.bottom, -8)
            #else
            Button("Load \(hitPageSize) ayah matches") {
                loadMoreAyahMatches(hitPageSize)
            }
            .foregroundColor(settings.accentColor.color)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(8)
            .conditionalGlassEffect()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            #endif

            Button {
                settings.hapticFeedback()
                ayahSearchTask?.cancel()
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                ayahSearchTask = Task {
                    let allHits = await fetchAllHitsOffMain(query: query)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                        verseHits = dedupedHits(allHits)
                        hasMoreHits = false
                    }
                }
            } label: {
                Text("Load all ayah matches")
            }
            .foregroundColor(settings.accentColor.color)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(8)
            .conditionalGlassEffect()
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            #if os(iOS)
            .padding(.top, -8)
            .listRowSeparator(.hidden)
            #endif
        }
    }

    private func handleAyahSearchChange(_ txt: String) {
        handleAyahSearchChange(txt, debounce: true)
    }

    private func loadMoreAyahMatches(_ amount: Int) {
        ayahSearchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let offset = verseHits.count

        ayahSearchTask = Task {
            let (moreHits, moreAvail) = await fetchHitsOffMain(query: query, limit: amount, offset: offset)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                // Append only entries not already shown - the index can be rebuilt between pages, which
                // shifts offsets and lets a page overlap the last one (duplicate ids crash the List diff).
                let existing = Set(verseHits.map(\.id))
                verseHits.append(contentsOf: moreHits.filter { !existing.contains($0.id) })
                hasMoreHits = moreAvail
            }
        }
    }

    private func handleAyahSearchChange(_ txt: String, debounce: Bool) {
        ayahSearchTask?.cancel()
        #if os(iOS)
        // Every new query starts with the keyword lists collapsed again (when AI results are present).
        showKeywordResults = false
        #endif

        let query = txt.trimmingCharacters(in: .whitespacesAndNewlines)

        if parseSurahCountQuery(from: query) != nil {
            clearAyahSearchState()
            return
        }

        guard !query.isEmpty else {
            clearAyahSearchState()
            return
        }

        if getSurahAndAyah(from: query).surah != nil {
            clearAyahSearchState()
            return
        }

        guard quranData.isVerseSearchReady else {
            clearAyahSearchState()
            return
        }

        ayahSearchTask = Task {
            if debounce {
                #if os(watchOS)
                try? await Task.sleep(nanoseconds: 400_000_000)
                #else
                try? await Task.sleep(nanoseconds: 150_000_000)
                #endif
            }
            guard !Task.isCancelled else { return }
            let shouldContinue = await MainActor.run {
                query == searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard shouldContinue else { return }

            let (first, more) = await fetchHitsOffMain(query: query, limit: hitPageSize, offset: 0)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                // Animate the initial appearance of results so it matches `clearAyahSearchState()` (which
                // animates) - that mismatch is why search felt "sometimes animated, sometimes not". Only the
                // first page animates; `loadMoreAyahMatches` / "load all" stay un-animated on purpose so
                // appending rows mid-scroll doesn't re-animate the whole list (see the `.id(...)` note above).
                prewarmHighlightCaches(for: first)
                withAnimation {
                    verseHits = dedupedHits(first)
                    hasMoreHits = more
                }
            }
        }
    }

    private var searchDisplayContext: SearchDisplayContext {
        let pageJuzQuery = parsePageJuzQuery(from: searchText)
        let exactMatch = getSurahAndAyah(from: searchText)
        let surahCountQuery = parseSurahCountQuery(from: searchText)
        let filteredSurahs = filteredSurahs(for: searchText, countQuery: surahCountQuery)

        return SearchDisplayContext(
            isSearching: !searchText.isEmpty,
            favoriteSurahs: Set(settings.favoriteSurahs),
            bookmarkedAyahs: Set(settings.bookmarkedAyahs.map(\.id)),
            pageJuzQuery: pageJuzQuery,
            juzSurahs: quranData.surahs(inJuz: pageJuzQuery.juz),
            explicitPageOrJuzMode: pageJuzQuery.isExplicitPage || pageJuzQuery.isExplicitJuz,
            pageSearchResult: firstAyahResult(page: pageJuzQuery.page),
            juzSearchResult: firstAyahResult(juz: pageJuzQuery.juz),
            exactMatch: exactMatch,
            isExactAyahReference: exactMatch.surah != nil && exactMatch.ayah != nil,
            surahCountQuery: surahCountQuery,
            filteredSurahs: filteredSurahs,
            canShowMoreAyahHits: hasMoreHits && !verseHits.isEmpty,
            ayahCountDisplayText: {
                let exactMatchBump = (exactMatch.surah != nil && exactMatch.ayah != nil) ? 1 : 0
                let ayahCount = verseHits.count + exactMatchBump
                return "\(ayahCount)\((hasMoreHits && !verseHits.isEmpty) ? "+" : "")"
            }()
        )
    }
}

// MARK: - iOS 26+ Section index for Juz fast-scroll
private extension View {
    @ViewBuilder
    func sectionIndexLabelWhenAvailable(_ label: String) -> some View {
        if #available(iOS 26.0, watchOS 26.0, *) {
            sectionIndexLabel(label)
        } else {
            self
        }
    }

    @ViewBuilder
    func listSectionIndexVisibilityWhenAvailable(visible: Bool) -> some View {
        if #available(iOS 26.0, watchOS 26.0, *) {
            listSectionIndexVisibility(visible ? .visible : .hidden)
        } else {
            self
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        QuranView()
    }
}
