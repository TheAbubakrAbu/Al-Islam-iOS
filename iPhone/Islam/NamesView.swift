import SwiftUI

struct NameOfAllah: Identifiable, Equatable {
    let number: Int
    let id: String
    let name: String
    let transliteration: String
    let found: String
    let meaning: String
    let otherNames: [String]
    let desc: String
    let numberArabic: String
    let displayArabicName: String
    let searchTokens: [String]
    let firstFoundSurah: Int?
    let firstFoundAyah: Int?

    /// Every stored property that isn't a raw source field is derived here, in the one init.
    init(number: Int, name: String, transliteration: String, found: String,
         meaning: String, otherNames: [String], desc: String) {
        self.number = number
        self.name = name
        self.transliteration = transliteration
        self.found = found
        self.meaning = meaning
        self.otherNames = otherNames
        self.desc = desc

        id = "\(number)"
        numberArabic = arabicNumberString(from: number)
        let deacriticizedName = name.removeDiacriticsFromLastLetter()
        displayArabicName = deacriticizedName.contains(" ")
            ? deacriticizedName.split(separator: " ").joined(separator: "\n")
            : deacriticizedName
        // No Quran references in an app without the Quran domain (`HAS_QURAN` is defined by the
        // projects that ship it; companions define nothing and all of this compiles out): the
        // first-found ayah would be a link to nowhere, so it is never derived - which is also what
        // hides every "First Found" line and "View First Found" button downstream (they key off
        // these). The found string is likewise dropped from search - "(2:255)" should match nothing
        // in an app with no Quran to resolve it in; the empty token keeps the array's index contract.
        #if HAS_QURAN
        let firstFound = Self.parseFirstFound(found)
        let foundToken = Self.clean(found)
        #else
        let firstFound: (surah: Int, ayah: Int)? = nil
        let foundToken = ""
        #endif
        firstFoundSurah = firstFound?.surah
        firstFoundAyah = firstFound?.ayah

        searchTokens = [
            Self.clean(name),
            Self.clean(transliteration),
            Self.clean(meaning),
            otherNames.map(Self.clean).joined(separator: " "),
            Self.clean(desc),
            foundToken,
            "\(number)",
            numberArabic
        ]
    }

    private static func clean(_ s: String) -> String {
        let unwanted: Set<Character> = ["[", "]", "(", ")", "-", "'", "\""]
        let stripped = s
            .normalizingArabicIndicDigitsToWestern
            .filter { !unwanted.contains($0) }
        return (stripped.applyingTransform(.stripDiacritics, reverse: false) ?? stripped).lowercased()
    }

    private static func parseFirstFound(_ found: String) -> (surah: Int, ayah: Int)? {
        let pattern = #"\((\d+)\s*:\s*(\d+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let fullRange = NSRange(found.startIndex..<found.endIndex, in: found)
        guard let match = regex.firstMatch(in: found, range: fullRange), match.numberOfRanges >= 3,
              let surahRange = Range(match.range(at: 1), in: found),
              let ayahRange = Range(match.range(at: 2), in: found),
              let surah = Int(found[surahRange]),
              let ayah = Int(found[ayahRange]) else {
            return nil
        }
        return (surah, ayah)
    }

    var firstFoundShort: String {
        guard let closingParen = found.firstIndex(of: ")") else { return found }
        return String(found[...closingParen])
    }

    /// Which of the three *displayed* fields (Arabic name, transliteration, meaning) actually contain the
    /// query. A name can also match on hidden fields (`desc`, `otherNames`, `found`), in which case all three
    /// are false and the collapsed row shows no highlight - correct, since the match isn't visible. When a
    /// displayed field does match, its flag drives `guaranteeMatch` so that field always shows at least one
    /// highlight even if the highlighter's normalization differs from this search's (e.g. `ḥ` vs `h`).
    /// Indices mirror `searchTokens`: [0] = Arabic name, [1] = transliteration, [2] = meaning.
    /// One-entry memo for the cleaned query: during a search, every visible row cleans the SAME raw
    /// query per keystroke - up to ~99 identical diacritic-strips per character typed. Main-thread only,
    /// like the row bodies that call it.
    private static var cleanedQueryMemo: (raw: String, cleaned: String) = ("", "")

    private static func cleanedQuery(_ raw: String) -> String {
        if cleanedQueryMemo.raw == raw { return cleanedQueryMemo.cleaned }
        let cleaned = clean(raw)
        cleanedQueryMemo = (raw, cleaned)
        return cleaned
    }

    func displayedFieldMatches(query rawQuery: String) -> (arabic: Bool, transliteration: Bool, meaning: Bool) {
        let q = Self.cleanedQuery(rawQuery)
        guard !q.isEmpty, searchTokens.count >= 3 else { return (false, false, false) }
        return (
            arabic: searchTokens[0].contains(q),
            transliteration: searchTokens[1].contains(q),
            meaning: searchTokens[2].contains(q)
        )
    }
}

#if !HAS_QURAN
/// The original NamesOfAllah.json shapes - the data path for apps without the Quran domain's
/// pack reader. Handles both historical layouts: a bare array or the {code, status, data}
/// wrapper, with the translation flat or nested under "en".
private struct JSONNamesRoot: Decodable {
    let code: Int
    let status: String
    let data: [JSONNameRecord]
}

private struct JSONNameRecord: Decodable {
    let number: Int
    let name: String
    let transliteration: String
    let found: String
    let meaning: String
    let desc: String

    private struct Translation: Decodable {
        let meaning: String
        let desc: String
    }

    private enum CodingKeys: String, CodingKey {
        case name, transliteration, number, found, meaning, desc, en
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        number = try c.decode(Int.self, forKey: .number)
        name = try c.decode(String.self, forKey: .name)
        transliteration = try c.decode(String.self, forKey: .transliteration)
        found = try c.decode(String.self, forKey: .found)

        if let flatMeaning = try c.decodeIfPresent(String.self, forKey: .meaning),
           let flatDesc = try c.decodeIfPresent(String.self, forKey: .desc) {
            meaning = flatMeaning
            desc = flatDesc
        } else {
            let en = try c.decode(Translation.self, forKey: .en)
            meaning = en.meaning
            desc = en.desc
        }
    }
}
#endif

final class NamesViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed
    }

    static let shared: NamesViewModel = {
        let model = NamesViewModel()
        model.startLoading()
        return model
    }()

    @Published var namesOfAllah: [NameOfAllah] = []
    @Published private(set) var firstFoundTargetsByNameNumber: [Int: (surahID: Int, ayahID: Int)] = [:]
    @Published private(set) var loadState: LoadState = .idle
    private var filterCache = [String: [NameOfAllah]]()
    private var loadTask: Task<Void, Never>?

    private init() {}

    private func startLoading() {
        guard loadTask == nil else { return }
        loadTask = Task(priority: .utility) { [weak self] in
            await self?.loadNames()
        }
    }

    var isReadyForUI: Bool {
        loadState == .ready
    }

    /// Wall-clock capped: this gates the LAUNCH SCREEN reveal (LaunchScreen awaits it with no cap of
    /// its own), and the uncapped loop had no escape if the load task never ran or wedged before
    /// setting `.ready`/`.failed` - a permanently stranded launch. Eight seconds is far beyond any
    /// real parse of a 100-entry JSON; past it, launching with the names still loading beats a hang.
    func waitUntilLoaded() async {
        for _ in 0..<320 {
            let state = await MainActor.run { self.loadState }
            if state == .ready || state == .failed {
                return
            }
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
    }

    private func loadNames() async {
        await MainActor.run {
            loadState = .loading
        }

        defer {
            Task { @MainActor in
                self.loadTask = nil
            }
        }

        // namesofallah.qpk replaced NamesOfAllah.json (7.6 KB vs 25.9 KB; same container format as
        // the Quran packs, verified field-for-field against the JSON it was built from). The pack
        // reader lives in the Quran domain; apps without it (no `HAS_QURAN`) still bundle the
        // original NamesOfAllah.json and decode that instead - no Quran symbol is even compiled.
        #if HAS_QURAN
        guard let url = QuranPackLoader.url("namesofallah") else {
            logger.debug("❌ namesofallah.qpk not found.")
            await MainActor.run {
                self.loadState = .failed
            }
            return
        }
        #else
        guard let url = Bundle.main.url(forResource: "NamesOfAllah", withExtension: "json") else {
            logger.debug("❌ NamesOfAllah.json not found.")
            await MainActor.run {
                self.loadState = .failed
            }
            return
        }
        #endif

        do {
            #if HAS_QURAN
            guard let pack = NamesPack(url: url) else {
                throw NSError(domain: "NamesOfAllah", code: 1, userInfo: [NSLocalizedDescriptionKey: "namesofallah.qpk unreadable"])
            }
            let records = pack.records.map {
                (number: $0.number, name: $0.name, transliteration: $0.transliteration,
                 found: $0.found, meaning: $0.meaning, otherNames: $0.otherNames, desc: $0.desc)
            }
            #else
            // Either historical JSON shape decodes: a bare array or the {code, status, data}
            // wrapper, with translations flat or nested under "en".
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let decoded: [JSONNameRecord]
            if let array = try? decoder.decode([JSONNameRecord].self, from: data) {
                decoded = array
            } else {
                decoded = try decoder.decode(JSONNamesRoot.self, from: data).data
            }
            let records = decoded.map {
                (number: $0.number, name: $0.name, transliteration: $0.transliteration,
                 found: $0.found, meaning: $0.meaning, otherNames: [String](), desc: $0.desc)
            }
            #endif

            let names = records.map {
                NameOfAllah(number: $0.number, name: $0.name, transliteration: $0.transliteration,
                            found: $0.found, meaning: $0.meaning, otherNames: $0.otherNames, desc: $0.desc)
            }
            var targets = [Int: (surahID: Int, ayahID: Int)]()
            targets.reserveCapacity(names.count)
            for name in names {
                guard let surah = name.firstFoundSurah,
                      let ayah = name.firstFoundAyah else { continue }
                targets[name.number] = (surahID: surah, ayahID: ayah)
            }
            let finalizedTargets = targets

            await MainActor.run {
                self.namesOfAllah = names
                self.firstFoundTargetsByNameNumber = finalizedTargets
                self.filterCache.removeAll(keepingCapacity: true)
                self.loadState = .ready
            }
        } catch {
            logger.debug("❌ JSON decode error: \(error)")
            await MainActor.run {
                self.loadState = .failed
            }
        }
    }

    func filteredNames(cleanedQuery: String) -> [NameOfAllah] {
        guard !cleanedQuery.isEmpty else { return namesOfAllah }

        if let cached = filterCache[cleanedQuery] {
            return cached
        }

        let matches = namesOfAllah.filter { name in
            if cleanedQuery.allSatisfy(\.isNumber), let n = Int(cleanedQuery) {
                return name.number == n
            }
            return name.searchTokens.contains { $0.contains(cleanedQuery) } || Int(cleanedQuery) == name.number
        }
        // Every distinct prefix a user ever types lands here; without a bound the cache grows for the
        // app's lifetime. Recomputing a miss is a filter over 99 names, so wholesale eviction is fine.
        if filterCache.count >= 128 {
            filterCache.removeAll(keepingCapacity: true)
        }
        filterCache[cleanedQuery] = matches
        return matches
    }
}

struct NamesView: View {
    @ObservedObject var settings = Settings.shared
    #if HAS_QURAN
    @ObservedObject var quranData = QuranData.shared
    #endif
    @ObservedObject var namesData = NamesViewModel.shared

    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @State private var expandedNameNumbers = Set<Int>()
    
    /// Cached so the diacritic-stripping `clean()` only runs when the query changes - not on every `body`
    /// re-eval (expand/collapse, favorite toggles, font switches all re-run body but leave the query alone).
    @State private var cleanedSearch = ""

    private static func clean(_ s: String) -> String {
        let unwanted: Set<Character> = ["[", "]", "(", ")", "-", "'", "\""]
        let stripped = s
            .normalizingArabicIndicDigitsToWestern
            .filter { !unwanted.contains($0) }
        return (stripped.applyingTransform(.stripDiacritics, reverse: false) ?? stripped).lowercased()
    }

    private var filteredNames: [NameOfAllah] {
        namesData.filteredNames(cleanedQuery: cleanedSearch)
    }

    /// Collapse state for the favorites section, same as the Quran tab's Favorite Surahs.
    @AppStorage("showFavoriteNames") private var showFavoriteNames = true

    private func favoriteNames(in favoriteSet: Set<Int>) -> [NameOfAllah] {
        namesData.namesOfAllah
            .filter { favoriteSet.contains($0.number) }
            .sorted { $0.number < $1.number }
    }

    #if os(iOS)
    // AI (semantic) name search - the hadith book search's exact grammar, over the 99 names:
    // on-device meaning matching over the transliteration/meaning/description, shown automatically
    // above the keyword matches. No mode to enter; the section appears (with one-time build
    // progress the first time) whenever it can help.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var aiHits: [NameOfAllah] = []
    @State private var aiSearchTask: Task<Void, Never>?

    private static let semanticCorpusID = "names-en"

    /// True when the live query is one the semantic engine can answer (English text, long enough).
    private var aiQueryEligible: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return SemanticSearchEngine.isSupported
            && trimmed.count >= 3
            && !trimmed.containsArabicScript
    }

    private func prepareSemanticCorpus() {
        guard SemanticSearchEngine.isSupported, !semanticEngine.isReady(Self.semanticCorpusID) else { return }
        let names = namesData.namesOfAllah
        guard !names.isEmpty else { return }
        // Every English-meaning field per name; a tiny corpus, so this is cheap to hand over.
        let texts = names.map { "\($0.transliteration) \($0.meaning) \($0.otherNames.joined(separator: " ")) \($0.desc)" }
        // Keyed by the name's number, so index -> name resolution survives any reorder of the source.
        let keys = names.map { String($0.number) }
        semanticEngine.prepare(corpusID: Self.semanticCorpusID, version: "v1-\(texts.count)", texts: texts, keys: keys)
    }

    private func runAISearch(query: String) {
        aiSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SemanticSearchEngine.isSupported, trimmed.count >= 3, !trimmed.containsArabicScript,
              !namesData.namesOfAllah.isEmpty else {
            if !aiHits.isEmpty { aiHits = [] }
            return
        }
        prepareSemanticCorpus()

        aiSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let results = await semanticEngine.search(corpusID: Self.semanticCorpusID, query: trimmed, limit: 10)
            guard !Task.isCancelled else { return }
            // Resolve through the corpus KEYS (the name's number), falling back to position only
            // for a corpus persisted before keys existed.
            let keys = await MainActor.run { semanticEngine.corpus(Self.semanticCorpusID)?.itemKeys }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                let names = namesData.namesOfAllah
                // Plain apply: an animated section insert racing another async apply is the
                // collection-view assertion crash the Quran search hit.
                aiHits = results.compactMap { result in
                    if let keys, keys.indices.contains(result.index), let number = Int(keys[result.index]) {
                        return names.first(where: { $0.number == number })
                    }
                    return names.indices.contains(result.index) ? names[result.index] : nil
                }
            }
        }
    }

    // Ask (the on-device LLM, grounded RAG): question-shaped queries stream an answer card above
    // the matches, drawn strictly from the retrieved names - the hadith book search's exact feature.
    @State private var askAnswer = ""
    @State private var askIsStreaming = false
    @State private var askRanForQuery = ""
    /// A MANUAL ask that found nothing to ground on or errored - the tapped row must answer with
    /// SOMETHING instead of silently restoring the prompt.
    @State private var askNoAnswer = false
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist. Reset to the
    /// AI list on every new query.
    @State private var showKeywordResults = false
    @State private var askTask: Task<Void, Never>?

    /// Auto mode runs only for QUESTION-shaped queries; `manual` (the tapped "Ask AI" row) runs
    /// for anything - the user explicitly asked.
    private func runAsk(query: String, manual: Bool) {
        askTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // Any new run (or keystroke) clears a previous dead-end notice. Plain writes throughout:
        // the Ask card is a List section, and animated section churn racing the async result
        // applies is the collection-view assertion crash the Quran search hit.
        askNoAnswer = false
        guard OnDeviceAsk.isAvailable, trimmed.count >= 3,
              manual || OnDeviceAsk.looksLikeQuestion(trimmed) else {
            if !askRanForQuery.isEmpty {
                askAnswer = ""; askIsStreaming = false; askRanForQuery = ""
            }
            return
        }

        askTask = Task {
            // Auto waits out the search debounce; a manual tap goes immediately.
            try? await Task.sleep(nanoseconds: manual ? 100_000_000 : 900_000_000)
            guard !Task.isCancelled else { return }

            var sources: [OnDeviceAsk.Source] = []
            var seen = Set<Int>()
            for name in aiHits.prefix(6) where seen.insert(name.number).inserted {
                sources.append(.init(reference: name.transliteration, text: "\(name.meaning). \(name.desc)"))
            }
            for name in filteredNames.prefix(6) where seen.insert(name.number).inserted {
                sources.append(.init(reference: name.transliteration, text: "\(name.meaning). \(name.desc)"))
            }
            guard !sources.isEmpty else {
                askAnswer = ""; askIsStreaming = false; askRanForQuery = ""
                // A tapped ask MUST respond: with nothing retrieved to ground on, say so instead
                // of silently restoring the prompt row.
                if manual { askNoAnswer = true }
                return
            }

            askAnswer = ""; askIsStreaming = true; askRanForQuery = trimmed
            guard #available(iOS 26.0, *) else { return }
            do {
                for try await text in OnDeviceAsk.streamAnswer(question: trimmed, sources: sources) {
                    guard !Task.isCancelled else { return }
                    askAnswer = text
                }
                guard !Task.isCancelled else { return }
                askIsStreaming = false
            } catch {
                guard !Task.isCancelled else { return }
                askAnswer = ""; askIsStreaming = false; askRanForQuery = ""
                if manual { askNoAnswer = true }
            }
        }
    }

    /// "ASK AI" with the sparkles glyph, accent-tinted - the Quran search's `askAIHeader`.
    private var askAIHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("ASK AI")

            Spacer()
        }
        .foregroundStyle(settings.accentColor.color)
    }

    /// Shown when a manual ask dead-ends: nothing retrieved matched the query, so there was
    /// nothing to answer from. Editing the query clears it (`runAsk` resets the flag on every run).
    private var askNoAnswerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("AI couldn't find anything matching \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}. Try different wording.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .conditionalGlassEffect(clear: true, rectangle: true)
    }

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

    /// The ASK AI section: the dead-end notice, the streaming answer card, or the one-tap prompt -
    /// the hadith book search's exact grammar. The prompt row shows only once there are results
    /// to ground an answer on.
    @ViewBuilder
    private func askAISection(hasResults: Bool) -> some View {
        if OnDeviceAsk.isAvailable {
            if askNoAnswer {
                Section(header: askAIHeader) { askNoAnswerRow }
            } else if !askRanForQuery.isEmpty {
                Section(header: askAIHeader) { AskAnswerCard(answer: askAnswer, isStreaming: askIsStreaming) }
            } else if hasResults {
                Section(header: askAIHeader) { askPromptRow }
            }
        }
    }

    private var resultsPickerSection: some View {
        Section {
            Picker("Results", selection: $showKeywordResults) {
                Text("AI Results").tag(false)
                Text("Keyword Results").tag(true)
            }
            .pickerStyle(.segmented)
        }
    }

    /// The AI (semantic) matches for the live query, shown automatically: build progress the first
    /// time, then the ranked matches - the same rows/tiles the keyword results use. Deliberately
    /// SILENT otherwise (Arabic query, build failed, no semantic matches): an automatic section
    /// must never nag.
    @ViewBuilder
    private func aiMatchesSection(favoriteSet: Set<Int>, hasActiveSearch: Bool, proxy: ScrollViewProxy) -> some View {
        if aiQueryEligible {
            if semanticEngine.isReady(Self.semanticCorpusID) {
                if !aiHits.isEmpty {
                    Section(header: SectionPillHeader(title: "AI MATCHES", count: aiHits.count, icon: "sparkles", accentTitle: true)) {
                        if settings.namesGridMode {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                ForEach(aiHits, id: \.id) { name in
                                    NameGridTile(
                                        name: name,
                                        isFavorite: favoriteSet.contains(name.number),
                                        accentColor: settings.accentColor,
                                        useFontArabic: settings.useFontArabic,
                                        fontArabic: settings.nonQuranArabicFontName
                                    )
                                    .equatable()
                                }
                            }
                            .padding(.horizontal, -8)
                        } else {
                            ForEach(aiHits, id: \.id) { name in
                                NameRow(
                                    name: name,
                                    firstFoundTarget: namesData.firstFoundTargetsByNameNumber[name.number],
                                    showDescription: settings.showDescription,
                                    isExpanded: expandedNameNumbers.contains(name.number),
                                    isFavorite: favoriteSet.contains(name.number),
                                    accentColor: settings.accentColor,
                                    useFontArabic: settings.useFontArabic,
                                    fontArabic: settings.nonQuranArabicFontName,
                                    searchQuery: searchText
                                ) {
                                    handleNameTap(name: name, hasActiveSearch: hasActiveSearch, proxy: proxy)
                                }
                                .equatable()
                            }
                        }
                    }
                }
            } else if !semanticEngine.failedCorpora.contains(Self.semanticCorpusID) {
                Section { AISearchStatusRow(progress: semanticEngine.progress(Self.semanticCorpusID), failed: false) }
            }
        }
    }
    #endif

    var body: some View {
        let hasActiveSearch = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // One pass per render: the favorite set used to be rebuilt (`Set(...)`) at every row's
        // contains-check - ~100 allocations per body pass - and the favorites list was
        // filtered+sorted three times (gate, count, ForEach).
        let favoriteSet = Set(settings.favoriteNameNumbers)
        let favorites = favoriteNames(in: favoriteSet)
        let names = filteredNames

        // Both result kinds landed: ONE segmented switch decides which list fills the page (the
        // hadith book search's rule). With only one kind present, no picker - it just shows.
        #if os(iOS)
        let showResultsPicker = hasActiveSearch && !aiHits.isEmpty && !names.isEmpty
        let keywordVisible = !showResultsPicker || showKeywordResults
        #else
        let keywordVisible = true
        #endif

        ScrollViewReader { proxy in
            List {
                Group {
                    descriptionSection
                    allahSection(hasActiveSearch: hasActiveSearch)
                    favoriteNamesSection(favorites, hasActiveSearch: hasActiveSearch, proxy: proxy)
                    #if os(iOS)
                    if hasActiveSearch {
                        askAISection(hasResults: !aiHits.isEmpty || !names.isEmpty)
                        if showResultsPicker { resultsPickerSection }
                        // AI matches appear AUTOMATICALLY above the keyword results - no mode to enter.
                        if !showResultsPicker || !showKeywordResults {
                            aiMatchesSection(favoriteSet: favoriteSet, hasActiveSearch: hasActiveSearch, proxy: proxy)
                        }
                    }
                    #endif
                    if keywordVisible {
                        namesHeaderSection(resultCount: names.count, hasActiveSearch: hasActiveSearch, proxy: proxy)
                        namesSections(filteredNames: names, favoriteSet: favoriteSet, hasActiveSearch: hasActiveSearch, proxy: proxy)
                    }
                    finalInvocationSection
                }
                .themedListRowBackground()
            }
        }
        #if os(watchOS)
        .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #else
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                // The one Islam-tab Arabic face picker, above the search bar - identical control and setting
                // on Duas, Dhikr, the Arabic Alphabet and the letter detail screens. It does not fold away
                // on scroll (`collapsibleBarRow` stays off), which is what made it look like a vanishing row.
                IslamArabicFontPicker()
                    // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26 hardware.
                    .conditionalGlassEffect(interactive: false)

                SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
                    .padding([.horizontal, .top], -8)
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #endif
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle("99 Names of Allah")
        .onChange(of: searchText) { newValue in
            cleanedSearch = Self.clean(newValue)
            #if os(iOS)
            // A new query starts back on the AI list, with any dead-end ask notice cleared.
            showKeywordResults = false
            askNoAnswer = false
            runAISearch(query: newValue)
            runAsk(query: newValue, manual: false)
            #endif
        }
        #if os(iOS)
        // The one-time vector build finishing mid-query: surface the results without another keystroke.
        .onChange(of: semanticEngine.readyCorpora) { ready in
            guard ready.contains(Self.semanticCorpusID) else { return }
            runAISearch(query: searchText)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Grid/list toggle lives in the toolbar (same as QuranView) rather than on a section header.
                Button {
                    settings.hapticFeedback()
                    withAnimation { settings.namesGridMode.toggle() }
                } label: {
                    Image(systemName: settings.namesGridMode ? "list.bullet" : "square.grid.2x2")
                }
                .accessibilityLabel(settings.namesGridMode ? "Show list" : "Show grid")
                .tint(settings.accentColor.accent2)
            }
        }
        #endif
    }

    private static var namesDisclaimerText: String {
        var text = "Prophet Muhammad ﷺ said, “Allah has 99 names, and whoever believes in their meanings and acts accordingly, will enter Paradise” (Bukhari 6410). The count is established in Bukhari and Muslim; the enumerated list below is the one narrated in Tirmidhi 3507, which scholars note is an addition by a narrator rather than the Prophet's own listing."
        #if HAS_QURAN
        text += " Names marked as coming from that list do not appear as names in the Quran."
        #endif
        return text
    }

    private var descriptionSection: some View {
        Section(header: Text("DESCRIPTION")) {
            // The closing sentence explains the "First Found" labels, which only exist in apps that
            // ship the Quran - it goes with them.
            Text(Self.namesDisclaimerText)
                .font(.caption)
                .foregroundColor(.secondary)

            // The per-row descriptions only exist in list mode, so hide the toggle in grid mode.
            if !settings.namesGridMode {
                Toggle("Show All Descriptions", isOn: showAllDescriptionsBinding)
                    .font(.caption)
                    .tint(settings.accentColor.color)
                    .onChange(of: settings.showDescription) { _ in settings.hapticFeedback() }
            }
        }
    }

    private var showAllDescriptionsBinding: Binding<Bool> {
        Binding(
            get: { settings.showDescription },
            set: { newValue in
                withAnimation(.easeInOut) {
                    settings.showDescription = newValue
                    if !newValue {
                        // User requested global OFF to force every manual expansion closed.
                        expandedNameNumbers.removeAll()
                    }
                }
            }
        )
    }

    /// The name itself, above the 99: Allah is the proper name the 99 names all describe, so it gets
    /// its own row rather than a place in the enumerated list. Hidden while searching - it is not one
    /// of the searchable names.
    @ViewBuilder
    private func allahSection(hasActiveSearch: Bool) -> some View {
        if !hasActiveSearch {
            Section(header: Text("ALLAH")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Allah")
                                .font(.subheadline.weight(.semibold))

                            Text("The One True God")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // No "First Found" line here, unlike the 99 name rows: the paragraph below says
                            // this name opens the Quran and the button under it goes straight to 1:1, so the
                            // header was stating the same reference a third time.
                        }

                        Spacer(minLength: 8)

                        // Vowelled, and with no case ending on the final haa - the same treatment every one of
                        // the 99 names gets (`displayArabicName` strips only the last letter's diacritic).
                        Text("اللَّه")
                            .font(settings.useFontArabic ? Font.arabic(settings.nonQuranArabicFontName, size: 30) : .title)
                            .arabicFontDesign(custom: settings.useFontArabic && settings.nonQuranArabicFontName != Settings.systemArabicFontName)
                            .foregroundColor(settings.accentColor.color)
                    }

                    // The Quran tail of the paragraph, the 1:1 quote and the link into the mushaf
                    // only exist where the Quran does.
                    Text(Self.allahIntroText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    #if HAS_QURAN
                    Text("“In the name of Allah, the Entirely Merciful, the Especially Merciful.” — Quran 1:1")
                        .font(.footnote.italic())
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("View First Ayah (1:1)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .conditionalGlassEffect(useColor: 0.2)
                        .padding(.top, 2)
                        .background(
                            NavigationLink("", destination: ayahsDestination(for: (surahID: 1, ayahID: 1)))
                                .opacity(0)
                        )
                    #endif
                }
            }
        }
    }

    private static var allahIntroText: String {
        var text = "Allah (اللَّه) is the proper name of the One True God, not one of the 99 names, but the name every one of them describes. Unlike other words, it has no plural and no gender, and it was never used for anything or anyone else."
        #if HAS_QURAN
        text += " It appears in the Quran more than 2,600 times, beginning with the very first ayah:"
        #endif
        return text
    }

    private func namesHeaderSection(resultCount: Int, hasActiveSearch: Bool, proxy: ScrollViewProxy) -> some View {
        Section(header: SectionPillHeader(
            title: hasActiveSearch ? "NAME SEARCH RESULTS" : "NAMES OF ALLAH",
            count: resultCount,
            // Shuffle expands and scrolls to a random name - list rows only; grid tiles carry no ids.
            onShuffle: (hasActiveSearch || settings.namesGridMode) ? nil : { shuffleToRandomName(proxy: proxy) }
        )) { }
        .padding(.bottom, -12)
    }

    /// Expands a random name and scrolls it to the top - the header's shuffle button.
    private func shuffleToRandomName(proxy: ScrollViewProxy) {
        guard let name = namesData.namesOfAllah.randomElement() else { return }
        withAnimation {
            expandedNameNumbers.insert(name.number)
            proxy.scrollTo("name_\(name.number)", anchor: .top)
        }
    }

    @ViewBuilder
    private func favoriteNamesSection(_ favorites: [NameOfAllah], hasActiveSearch: Bool, proxy: ScrollViewProxy) -> some View {
        if !hasActiveSearch && !favorites.isEmpty {
            Section(header: SectionPillHeader(
                title: "FAVORITES",
                count: favorites.count,
                icon: "star.fill",
                accentTitle: true,
                isExpanded: $showFavoriteNames
            )) {
                if !showFavoriteNames {
                    EmptyView()
                } else if settings.namesGridMode {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(favorites, id: \.id) { name in
                            NameGridTile(
                                name: name,
                                isFavorite: true,
                                accentColor: settings.accentColor,
                                useFontArabic: settings.useFontArabic,
                                fontArabic: settings.nonQuranArabicFontName
                            )
                            .equatable()
                        }
                    }
                    .padding(.horizontal, -8)
                } else {
                    ForEach(favorites, id: \.id) { name in
                        NameRow(
                            name: name,
                            firstFoundTarget: namesData.firstFoundTargetsByNameNumber[name.number],
                            showDescription: settings.showDescription,
                            isExpanded: expandedNameNumbers.contains(name.number),
                            isFavorite: true,
                            accentColor: settings.accentColor,
                            useFontArabic: settings.useFontArabic,
                            fontArabic: settings.nonQuranArabicFontName,
                            searchQuery: searchText
                        ) {
                            handleNameTap(name: name, hasActiveSearch: hasActiveSearch, proxy: proxy)
                        }
                        .equatable()
                        .id("favorite_name_\(name.number)")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func namesSections(filteredNames: [NameOfAllah], favoriteSet: Set<Int>, hasActiveSearch: Bool, proxy: ScrollViewProxy) -> some View {
        if settings.namesGridMode {
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(filteredNames, id: \.id) { name in
                        NameGridTile(
                            name: name,
                            isFavorite: favoriteSet.contains(name.number),
                            accentColor: settings.accentColor,
                            useFontArabic: settings.useFontArabic,
                            fontArabic: settings.nonQuranArabicFontName
                        )
                        .equatable()
                    }
                }
                .padding(.horizontal, -8)
            }
        } else if filteredNames.isEmpty, hasActiveSearch {
            Section {
                #if os(iOS)
                Text(aiHits.isEmpty
                     ? "No names match your search."
                     : "No keyword matches; see the AI results above.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                #else
                Text("No names match your search.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                #endif
            }
        } else {
        ForEach(filteredNames, id: \.id) { name in
            Section {
                NameRow(
                    name: name,
                    firstFoundTarget: namesData.firstFoundTargetsByNameNumber[name.number],
                    showDescription: settings.showDescription,
                    isExpanded: expandedNameNumbers.contains(name.number),
                    isFavorite: favoriteSet.contains(name.number),
                    accentColor: settings.accentColor,
                    useFontArabic: settings.useFontArabic,
                    fontArabic: settings.nonQuranArabicFontName,
                    searchQuery: searchText
                ) {
                    handleNameTap(name: name, hasActiveSearch: hasActiveSearch, proxy: proxy)
                }
                .equatable()
            }
            .id("name_\(name.number)")
        }
        }
    }

    #if HAS_QURAN
    @ViewBuilder
    private func ayahsDestination(for target: (surahID: Int, ayahID: Int)) -> some View {
        if let surah = quranData.surah(target.surahID) {
            SurahView(surah: surah, ayah: target.ayahID)
        } else {
            Text("Reference not found")
        }
    }
    #endif

    private func handleNameTap(name: NameOfAllah, hasActiveSearch: Bool, proxy: ScrollViewProxy) {
        if hasActiveSearch {
            let targetID = "name_\(name.number)"
            withAnimation {
                searchText = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation {
                    proxy.scrollTo(targetID, anchor: .top)
                }
            }
        } else {
            withAnimation {
                if expandedNameNumbers.contains(name.number) {
                    expandedNameNumbers.remove(name.number)
                } else {
                    expandedNameNumbers.insert(name.number)
                }
            }
        }
    }

    /// Quranic content wholesale (an ayah and the four Al-Hashr reflections) - it only exists in
    /// apps that ship the Quran.
    @ViewBuilder
    private var finalInvocationSection: some View {
        #if HAS_QURAN
        Section(header: Text("MOST BEAUTIFUL NAMES")) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Call upon Allah or call upon Ar-Rahman (The Entirely Merciful). Whichever Name you call, to Him belong the Most Beautiful Names.")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Surah Al-Isra 17:110")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:21",
                contentText: "If this Quran were sent upon a mountain, it would humble and break from awe of Allah. These examples are given so people reflect."
            )

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:22",
                contentText: "He is Allah, none is worthy of worship except Him. Knower of the seen and unseen, the Most Compassionate, the Most Merciful."
            )

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:23",
                contentText: "He is Allah: the King, the Most Holy, the Source of Peace, the Granter of Security, the Guardian, the Almighty, the Compeller, the Supreme. Exalted is He above all partners."
            )

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:24",
                contentText: "He is Allah, the Creator, the Originator, the Fashioner. To Him belong the Most Beautiful Names; all in the heavens and earth glorify Him."
            )
        }
        #endif
    }
}

private struct NameRow: View, Equatable {
    // Deliberately NOT observing Settings: every input this body reads is passed in and folded into `==`,
    // so with `.equatable()` a Settings publish (favorite toggle, accent change elsewhere) skips every
    // row whose inputs didn't change. Actions reach Settings.shared directly - they don't need observation.
    let name: NameOfAllah
    let firstFoundTarget: (surahID: Int, ayahID: Int)?
    let showDescription: Bool
    let isExpanded: Bool
    let isFavorite: Bool
    let accentColor: AccentColor
    let useFontArabic: Bool
    let fontArabic: String
    let searchQuery: String
    let onTap: () -> Void

    init(
        name: NameOfAllah,
        firstFoundTarget: (surahID: Int, ayahID: Int)? = nil,
        showDescription: Bool,
        isExpanded: Bool,
        isFavorite: Bool,
        accentColor: AccentColor = Settings.shared.accentColor,
        useFontArabic: Bool = Settings.shared.useFontArabic,
        fontArabic: String = Settings.shared.nonQuranArabicFontName,
        searchQuery: String = "",
        onTap: @escaping () -> Void
    ) {
        self.name = name
        self.firstFoundTarget = firstFoundTarget
        self.showDescription = showDescription
        self.isExpanded = isExpanded
        self.isFavorite = isFavorite
        self.accentColor = accentColor
        self.useFontArabic = useFontArabic
        self.fontArabic = fontArabic
        self.searchQuery = searchQuery
        self.onTap = onTap
    }

    var body: some View {
        #if os(iOS)
        content
            // LIST ROWS ONLY. `NameGridTile` deliberately has no menu: the grid is a LazyVGrid inside a single
            // List row, so a context menu there lifts the WHOLE row - every tile at once - as its preview.
            // Favoriting lives on the tile's own star instead (same rule as the Islam tab's resource grid).
            .contextMenu {
                Text("Name Actions")
                    .foregroundStyle(.secondary)

                Button {
                    Settings.shared.hapticFeedback()
                    FocusOverlayPresenter.shared.present(.name(name))
                } label: {
                    Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
                }

                Button {
                    Settings.shared.hapticFeedback()
                    presentSystemShareSheet(items: [FocusItem.name(name).shareText])
                } label: {
                    Label("Share Name", systemImage: "square.and.arrow.up")
                }

                Divider()

                favoriteMenuItem

                Divider()

                copyMenu
            }
            .swipeActions(edge: .leading) {
                Button {
                    Settings.shared.hapticFeedback()
                    withAnimation(.easeInOut) {
                        Settings.shared.toggleNameFavorite(number: name.number)
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .tint(accentColor.color)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    Settings.shared.hapticFeedback()
                    withAnimation(.easeInOut) {
                        Settings.shared.toggleNameFavorite(number: name.number)
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .tint(accentColor.color)
            }
        #else
        content
        #endif
    }

    private var content: some View {
        let fieldMatches = name.displayedFieldMatches(query: searchQuery)
        return Group {
            HStack(alignment: .center, spacing: 12) {
                numberPill

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        HighlightedSnippet(
                            source: name.transliteration,
                            term: searchQuery,
                            font: .subheadline.weight(.semibold),
                            accent: accentColor.color,
                            fg: .primary,
                            guaranteeMatch: fieldMatches.transliteration
                        )
                            .lineLimit(1)

                        HighlightedSnippet(
                            source: name.meaning,
                            term: searchQuery,
                            font: .caption,
                            accent: accentColor.color,
                            fg: .secondary,
                            guaranteeMatch: fieldMatches.meaning
                        )
                            .fixedSize(horizontal: false, vertical: true)

                        // A Quran reference - it only exists in apps that ship the Quran.
                        #if HAS_QURAN
                        Text("First Found: \(name.firstFoundShort)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        #endif
                    }

                    Spacer(minLength: 8)

                    HStack {
                        HighlightedSnippet(
                            source: displayArabicName,
                            term: searchQuery,
                            font: useFontArabic ? Font.arabic(fontArabic, size: 24) : .title3,
                            accent: accentColor.color,
                            fg: .primary,
                            guaranteeMatch: fieldMatches.arabic
                        )
                            .arabicFontDesign(custom: useFontArabic && fontArabic != Settings.systemArabicFontName)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)

                        // Always the Uthmani face: it renders the number as the circled-flower ornament.
                        Text(name.numberArabic)
                            .font(.custom(Settings.qiraatUthmaniFontName, size: 28))
                            .arabicFontDesign(custom: true)
                            .foregroundColor(accentColor.color)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if !showDescription {
                        Settings.shared.hapticFeedback()
                        onTap()
                    }
                }
            }
            
            if showDescription || isExpanded {
                NameRowDetails(
                    name: name,
                    firstFoundTarget: firstFoundTarget,
                    showDescription: showDescription,
                    isExpanded: isExpanded
                )
            }
        }
    }

    private var displayArabicName: String {
        name.displayArabicName
    }

    #if os(iOS)
    // The menu's actions reach `Settings.shared` directly rather than through an `@ObservedObject`: this row
    // deliberately doesn't observe Settings (see the note at the top of the struct), and a menu that only
    // *acts* on Settings needs no subscription - `isFavorite` is already a folded input.
    @ViewBuilder
    private var favoriteMenuItem: some View {
        Button(role: isFavorite ? .destructive : nil) {
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) {
                Settings.shared.toggleNameFavorite(number: name.number)
            }
        } label: {
            Label(isFavorite ? "Unfavorite" : "Favorite", systemImage: isFavorite ? "star.fill" : "star")
        }
    }

    private var copyMenu: some View {
        // The First Found entries are Quran references; apps without the Quran have none.
        #if HAS_QURAN
        let firstFoundLine = "First Found: \(name.firstFoundShort)\n"
        #else
        let firstFoundLine = ""
        #endif
        return Group {
            menuItem("Copy All", text: """
            Arabic: \(name.name.removeDiacriticsFromLastLetter())
            Transliteration: \(name.transliteration)
            Translation: \(name.meaning)
            \(firstFoundLine)Description: \(name.desc)
            """)
            menuItem("Copy Arabic", text: name.name.removeDiacriticsFromLastLetter())
            menuItem("Copy Transliteration", text: name.transliteration)
            menuItem("Copy Translation", text: name.meaning)
            #if HAS_QURAN
            menuItem("Copy First Found", text: name.firstFoundShort)
            #endif
            menuItem("Copy Description", text: name.desc)
        }
    }

    private func menuItem(_ label: String, text: String) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            UIPasteboard.general.string = text
        } label: {
            Label(label, systemImage: "doc.on.doc")
        }
    }
    #endif

    @ViewBuilder
    private var numberPill: some View {
        ZStack(alignment: .topTrailing) {
            Text("\(name.number)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(accentColor.color)
                .frame(minWidth: 40)
                .frame(maxHeight: .infinity)
                .conditionalGlassEffect(
                    useColor: isFavorite ? 0.3 : nil,
                    customTint: isFavorite ? accentColor.color : nil
                )

            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(accentColor.color)
                    .padding(4)
                    .offset(x: 8, y: -6)
            }
        }
        .onTapGesture {
            Settings.shared.hapticFeedback()
            Settings.shared.toggleNameFavorite(number: name.number)
        }
        .padding(.vertical, {
            if #available(iOS 26, *) { 0 } else { 8 }
        }())
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name &&
        lhs.firstFoundTarget?.surahID == rhs.firstFoundTarget?.surahID &&
        lhs.firstFoundTarget?.ayahID == rhs.firstFoundTarget?.ayahID &&
        lhs.showDescription == rhs.showDescription &&
        lhs.isExpanded == rhs.isExpanded &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.accentColor == rhs.accentColor &&
        lhs.useFontArabic == rhs.useFontArabic &&
        lhs.fontArabic == rhs.fontArabic &&
        lhs.searchQuery == rhs.searchQuery
    }
}

private struct NameRowDetails: View {
    @ObservedObject var settings = Settings.shared
    #if HAS_QURAN
    @ObservedObject var quranData = QuranData.shared
    #endif

    let name: NameOfAllah
    let firstFoundTarget: (surahID: Int, ayahID: Int)?
    let showDescription: Bool
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading) {
            if showDescription || isExpanded {
                if !name.otherNames.isEmpty {
                    // Baseline-aligned and free to wrap: a name with many alternates used to clip to
                    // whatever fit on the label's line.
                    HStack(alignment: .firstTextBaseline) {
                        Text("Other Names:")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)

                        Text(name.otherNames.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .transition(.opacity)
                }

                Text(name.desc)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
                    .padding(.top, 2)

                #if HAS_QURAN
                if showDescription || isExpanded, let target = firstFoundTarget {
                    Text("View First Found")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .conditionalGlassEffect(useColor: 0.2)
                        .padding(.top, 6)
                        .background(
                            NavigationLink("", destination: ayahsDestination(for: target))
                                .opacity(0)
                        )
                }
                #endif
            }
        }
    }

    #if HAS_QURAN
    @ViewBuilder
    private func ayahsDestination(for target: (surahID: Int, ayahID: Int)) -> some View {
        if let surah = quranData.surah(target.surahID) {
            SurahView(surah: surah, ayah: target.ayahID)
        } else {
            Text("Reference not found")
        }
    }
    #endif
}

private struct VerseReflectionCard: View {
    @ObservedObject var settings = Settings.shared
    
    let title: String
    let contentText: String

    var body: some View {
        content
    }
    
    var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(settings.accentColor.color)

            Text(contentText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(-4)
    }
}

/// No `contextMenu` here, deliberately - see the note on `NameRow`'s: the whole grid is one List row, so a
/// menu on a tile lifts every tile at once as its preview. The tile's star is the favorite action instead.
private struct NameGridTile: View, Equatable {
    @ObservedObject private var settings = Settings.shared

    let name: NameOfAllah
    let isFavorite: Bool
    let accentColor: AccentColor
    let useFontArabic: Bool
    let fontArabic: String

    /// Every appearance input is a stored value, so equality of the values means the drawn tile is identical.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.accentColor == rhs.accentColor &&
        lhs.useFontArabic == rhs.useFontArabic &&
        lhs.fontArabic == rhs.fontArabic
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(name.displayArabicName)
                .font(useFontArabic ? Font.arabic(fontArabic, size: 20) : .title3)
                .arabicFontDesign(custom: useFontArabic && fontArabic != Settings.systemArabicFontName)
                .foregroundColor(accentColor.color)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(name.transliteration)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("\(name.number)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
        // Only a favorite is tinted; every other tile is clear. A grid where all 99 boxes are filled is just a
        // wall of color, and the favorites disappear into it.
        .conditionalGlassEffect(
            clear: !isFavorite,
            rectangle: true,
            useColor: isFavorite ? 0.25 : nil,
            customTint: isFavorite ? accentColor.color : nil
        )
        .gridFavoriteStar(
            isFavorite: isFavorite,
            accent: accentColor.color,
            accessibilityName: name.transliteration
        ) {
            settings.toggleNameFavorite(number: name.number)
        }
        .onTapGesture {
            settings.hapticFeedback()
            settings.toggleNameFavorite(number: name.number)
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        NamesView()
    }
}
