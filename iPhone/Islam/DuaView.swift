import SwiftUI

private struct DuaItem: Identifiable {
    let arabicText: String
    let transliteration: String
    let translation: String
    let reference: String?
    let displayTranslation: String
    let searchBlob: String

    init(arabicText: String, transliteration: String, translation: String, reference: String? = nil) {
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.translation = translation
        self.reference = reference
        self.displayTranslation = reference.map { "\(translation)\n- \($0) -" } ?? translation
        self.searchBlob = [arabicText, transliteration, self.displayTranslation]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    var id: String { "\(reference ?? transliteration)-\(arabicText)" }
}

private struct DuaCollection: Identifiable {
    let title: String
    let subtitle: String
    let systemImage: String
    let introductionTitle: String
    let introduction: String
    let items: [DuaItem]

    var id: String { title }
}

struct DuaView: View {
    @ObservedObject var settings = Settings.shared

    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false

    private static let collections: [DuaCollection] = [
        DuaCollections.common,
        DuaCollections.morningEvening,
        DuaCollections.sleepWaking,
        DuaCollections.distress,
        DuaCollections.travel,
        DuaCollections.homeMosque,
        DuaCollections.foodDrink,
        DuaCollections.forgiveness,
        DuaCollections.prophets,
        DuaCollections.rabbana
    ]

    private var normalizedQuery: String {
        searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// Collection rows filter IN PLACE while searching, the reading lists' rule.
    private func filteredCollections(for normalizedQuery: String) -> [DuaCollection] {
        guard !normalizedQuery.isEmpty else { return Self.collections }
        return Self.collections.filter {
            $0.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(normalizedQuery)
                || $0.subtitle.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(normalizedQuery)
        }
    }

    /// Every dua in EVERY collection matching the query - so a search here finds the supplication
    /// itself, not just the folder it lives in.
    private func matchingDuas(for normalizedQuery: String) -> [DuaItem] {
        guard !normalizedQuery.isEmpty else { return [] }
        return Self.collections.flatMap { collection in
            collection.items.filter { $0.searchBlob.contains(normalizedQuery) }
        }
    }

    #if os(iOS)
    // AI (semantic) dua search - the hadith book search's exact grammar, over every dua in every
    // collection: on-device meaning matching over the English translations, shown automatically
    // above the keyword matches. No mode to enter; the section appears (with one-time build
    // progress the first time) whenever it can help.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var aiHits: [DuaItem] = []
    @State private var aiSearchTask: Task<Void, Never>?

    private static let semanticCorpusID = "duas-en"
    /// One flat list across the collections - the corpus rows, in a stable order.
    private static let allDuaItems: [DuaItem] = collections.flatMap(\.items)

    /// True when the live query is one the semantic engine can answer (English text, long enough).
    private var aiQueryEligible: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return SemanticSearchEngine.isSupported
            && trimmed.count >= 3
            && !trimmed.containsArabicScript
    }

    private func prepareSemanticCorpus() {
        guard SemanticSearchEngine.isSupported, !semanticEngine.isReady(Self.semanticCorpusID) else { return }
        // The transliterated "title" plus the English text; the Arabic embeds to nothing anyway.
        let texts = Self.allDuaItems.map { "\($0.transliteration) \($0.translation)" }
        // Keyed by the dua's own id, so index -> dua resolution survives any reorder of the source.
        let keys = Self.allDuaItems.map(\.id)
        semanticEngine.prepare(corpusID: Self.semanticCorpusID, version: "v1-\(texts.count)", texts: texts, keys: keys)
    }

    private func runAISearch(query: String) {
        aiSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SemanticSearchEngine.isSupported, trimmed.count >= 3, !trimmed.containsArabicScript else {
            if !aiHits.isEmpty { aiHits = [] }
            return
        }
        prepareSemanticCorpus()

        aiSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let results = await semanticEngine.search(corpusID: Self.semanticCorpusID, query: trimmed, limit: 10)
            guard !Task.isCancelled else { return }
            // Resolve through the corpus KEYS (the dua's id), falling back to position only for a
            // corpus persisted before keys existed.
            let keys = await MainActor.run { semanticEngine.corpus(Self.semanticCorpusID)?.itemKeys }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                // Plain apply: an animated section insert racing another async apply is the
                // collection-view assertion crash the Quran search hit.
                aiHits = results.compactMap { result in
                    if let keys, keys.indices.contains(result.index) {
                        let key = keys[result.index]
                        return Self.allDuaItems.first(where: { $0.id == key })
                    }
                    return Self.allDuaItems.indices.contains(result.index) ? Self.allDuaItems[result.index] : nil
                }
            }
        }
    }

    // Ask (the on-device LLM, grounded RAG): question-shaped queries stream an answer card above
    // the matches, drawn strictly from the retrieved duas - the hadith book search's exact feature.
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
            var seen = Set<String>()
            for dua in aiHits.prefix(6) where seen.insert(dua.id).inserted {
                sources.append(.init(reference: dua.reference ?? dua.transliteration, text: dua.translation))
            }
            for dua in matchingDuas(for: normalizedQuery).prefix(6) where seen.insert(dua.id).inserted {
                sources.append(.init(reference: dua.reference ?? dua.transliteration, text: dua.translation))
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
    /// time, then the ranked matches - the same rows the keyword matches use. Deliberately SILENT
    /// otherwise (Arabic query, build failed, no semantic matches): an automatic section must
    /// never nag.
    @ViewBuilder
    private var aiMatchesSection: some View {
        if aiQueryEligible {
            if semanticEngine.isReady(Self.semanticCorpusID) {
                if !aiHits.isEmpty {
                    Section {
                        ForEach(aiHits, id: \.id) { item in
                            AdhkarRow(
                                arabicText: item.arabicText,
                                transliteration: item.transliteration,
                                translation: item.translation,
                                useQuranicFont: settings.useFontArabic,
                                searchQuery: searchText,
                                alwaysTrailing: true,
                                speechEnabled: true,
                                source: item.reference
                            )
                            .equatable()
                        }
                    } header: {
                        SectionPillHeader(title: "AI MATCHES", count: aiHits.count, icon: "sparkles", accentTitle: true)
                    }
                }
            } else if !semanticEngine.failedCorpora.contains(Self.semanticCorpusID) {
                Section { AISearchStatusRow(progress: semanticEngine.progress(Self.semanticCorpusID), failed: false) }
            }
        }
    }
    #endif

    var body: some View {
        // One scan per body pass. As computed properties these were re-evaluated at every access
        // site (the section gate, the ForEach, the listen-all pill, and the count pill) - four full
        // walks over every dua in every collection on each search keystroke.
        let query = normalizedQuery
        let shownCollections = filteredCollections(for: query)
        let matching = matchingDuas(for: query)

        // Both result kinds landed: ONE segmented switch decides which list fills the page (the
        // hadith book search's rule). With only one kind present, no picker - it just shows.
        #if os(iOS)
        let showResultsPicker = !query.isEmpty && !aiHits.isEmpty && (!matching.isEmpty || !shownCollections.isEmpty)
        let keywordVisible = !showResultsPicker || showKeywordResults
        #else
        let keywordVisible = true
        #endif

        return List {
            Group {
            if query.isEmpty {
            Section(header: Text("SUPPLICATIONS TO ALLAH")) {
                Text("Short, daily supplications that keep your heart connected to Allah in every situation. \"Call upon Me; I will respond to you.\" (Quran 40:60)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
            }
            }

            #if os(iOS)
            if !query.isEmpty {
                askAISection(hasResults: !aiHits.isEmpty || !matching.isEmpty || !shownCollections.isEmpty)
                if showResultsPicker { resultsPickerSection }
                // AI matches appear AUTOMATICALLY above the keyword results - no mode to enter.
                if !showResultsPicker || !showKeywordResults { aiMatchesSection }
            }
            #endif

            if keywordVisible {
                Section {
                    if shownCollections.isEmpty, matching.isEmpty {
                        #if os(iOS)
                        Text(aiHits.isEmpty
                             ? "No duas match your search."
                             : "No keyword matches - see the AI results above.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        #else
                        Text("No duas match your search.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        #endif
                    }

                    ForEach(shownCollections) { collection in
                        NavigationLink {
                            DuaCollectionView(collection: collection)
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(collection.title)
                                        .foregroundStyle(.primary)

                                    Text(collection.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: collection.systemImage)
                                    .foregroundStyle(settings.accentColor.color)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("DUA COLLECTIONS")

                        Spacer()

                        Text("\(shownCollections.count)")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(settings.accentColor.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .conditionalGlassEffect()
                            .padding(.vertical, -16)
                    }
                }

            if !matching.isEmpty {
                Section {
                    // Keyed by the dua's own id, not position: positional identity meant a narrowing
                    // query reused row N's measured Arabic height for a DIFFERENT dua for a frame.
                    ForEach(matching, id: \.id) { item in
                        AdhkarRow(
                            arabicText: item.arabicText,
                            transliteration: item.transliteration,
                            translation: item.translation,
                            useQuranicFont: settings.useFontArabic,
                            searchQuery: searchText,
                            alwaysTrailing: true,
                            speechEnabled: true,
                            source: item.reference
                        )
                        .equatable()
                    }
                } header: {
                    HStack(spacing: 8) {
                        Text("MATCHING DUAS")

                        Spacer()

                        ListenAllPill(texts: matching.map(\.arabicText))

                        CountPill(count: matching.count)
                    }
                }
            }
            }

            if query.isEmpty {
            Section(header: Text("ETYMOLOGY")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Arabic root: د ع و (d-ʿ-w)")
                        .font(
                            settings.islamUsesCustomArabicFace
                                ? Font.arabic(settings.nonQuranArabicFontName, size: 18, relativeTo: .subheadline)
                                : .subheadline.weight(.semibold)
                        )
                        .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                        .foregroundColor(settings.accentColor.color)

                    Text("Core meaning: to call, to invite, to summon")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text("Dua literally means calling out, especially calling upon Allah. In Islam it is not just asking for things; it is an act of worship, turning to Him with need, hope, fear, and love.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.secondary.opacity(0.1))
                )
                .padding(-4)
            }

            Section(header: Text("VIRTUES OF DUA")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dua is an act of worship and a direct connection with Allah. No sincere call is lost: it is answered now, delayed for wisdom, or stored as reward.")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }

                DuaReflectionCard(
                    title: "Quranic Promise",
                    lines: [
                        "And your Lord says, \"Call upon Me; I will respond to you.\" (Quran 40:60)",
                        "And when My servants ask you concerning Me, indeed I am near. I respond to the invocation of the supplicant when he calls upon Me. (Quran 2:186)",
                        "Is He not best who responds to the desperate one when he calls upon Him and removes evil and makes you inheritors of the earth? (Quran 27:62)"
                    ],
                    accent: settings.accentColor.color
                )

                DuaReflectionCard(
                    title: "Prophetic Guidance",
                    lines: [
                        "Dua is worship. (Abu Dawud 1479; Tirmidhi 3247 - sahih)",
                        "No Muslim supplicates - so long as it is not for sin or for severing kinship - but Allah gives him one of three: the answer is hastened, it is stored for him in the Hereafter, or an equivalent evil is turned away from him. (Musnad Ahmad 11133 - hasan)"
                    ],
                    accent: settings.accentColor.color
                )
            }

                Section {
                    SpeechQualityHint()
                }
            }
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
                    .padding([.horizontal, .top], -8)
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #else
        .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #endif
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle("Dua & Supplications")
        #if os(iOS)
        .onChange(of: searchText) { text in
            // A new query starts back on the AI list, with any dead-end ask notice cleared.
            showKeywordResults = false
            askNoAnswer = false
            runAISearch(query: text)
            runAsk(query: text, manual: false)
        }
        // The one-time vector build finishing mid-query: surface the results without another keystroke.
        .onChange(of: semanticEngine.readyCorpora) { ready in
            guard ready.contains(Self.semanticCorpusID) else { return }
            runAISearch(query: searchText)
        }
        #endif
        .onDisappear { ArabicSpeech.shared.stop() }
    }
}

private struct DuaCollectionView: View {
    @ObservedObject var settings = Settings.shared
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false

    let collection: DuaCollection

    var body: some View {
        // Fold the query and filter ONCE per body pass: matching used to be re-decided per item at
        // two sites (the rows and the header's count/listen pills), re-folding the query inside
        // every single per-item check.
        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let shown = query.isEmpty
            ? collection.items
            : collection.items.filter { $0.searchBlob.contains(query) }

        return List {
            Group {
            introductionSection
            duaRows(shown)
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                // The floating font picker, back above the search bar. It no longer folds away on
                // scroll (`collapsibleBarRow` stays off) - it just rides with the bar.
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
        #else
        .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #endif
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle(collection.title)
        .onDisappear { ArabicSpeech.shared.stop() }
    }

    private var introductionSection: some View {
        // "ABOUT", not the collection's own name again - the navigation title directly above already says
        // "Sleep & Waking"; a header shouting "SLEEP & WAKING DUAS" right under it was saying it twice.
        Section(header: Text("ABOUT")) {
            Text(collection.introduction)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    private func duaRows(_ shown: [DuaItem]) -> some View {
        Section(header: duasHeader(shown)) {
            ForEach(shown) { item in
                // Duas are always trailing, however short. They are quoted Quran, and a line of Quran
                // should sit where Arabic prose sits - not flush left like a UI label. (Dhikr keeps the
                // measured behavior: leading while it fits on one line, trailing once it wraps.)
                AdhkarRow(
                    arabicText: item.arabicText,
                    transliteration: item.transliteration,
                    translation: item.translation,
                    useQuranicFont: settings.useFontArabic,
                    searchQuery: searchText,
                    alwaysTrailing: true,
                    speechEnabled: true,
                    source: item.reference
                )
                .equatable()
            }
        }
    }

    /// "SUPPLICATIONS" with the count pill the Quran and Arabic screens put on their section headers.
    /// While searching, the pill counts the matches instead.
    private func duasHeader(_ shown: [DuaItem]) -> some View {
        HStack(spacing: 8) {
            Text("SUPPLICATIONS")

            Spacer()

            // Plays every dua currently shown, in order.
            ListenAllPill(texts: shown.map(\.arabicText))

            CountPill(count: shown.count)
        }
    }

    // (The tab-level DuaView carries the ETYMOLOGY and VIRTUES sections; per-collection copies were
    // never referenced from this view's body and were removed as dead code.)
}

private enum DuaCollections {
    static let common = DuaCollection(
        title: "Common Duas",
        subtitle: "Daily supplications for protection, ease, and blessing",
        systemImage: "text.book.closed",
        introductionTitle: "Supplications to Allah",
        introduction: "Short, daily supplications that keep your heart connected to Allah in every situation. \"Call upon Me; I will respond to you.\" (Quran 40:60)",
        items: [
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِن زَوَالِ نِعمَتِكَ وَتَحَوُّلِ عَافِيَتِكَ وَفُجَاءَةِ نِقمَتِكَ وَجَمِيعِ سَخَطِكَ", transliteration: "Allahumma inni a'udhu bika min zawali ni'matika wa tahawwuli 'afiyatika wa fuja'ati niqmatika wa jamee'i sakhatika", translation: "O Allah, I seek refuge in You from the removal of Your blessings, changing of Your protection, sudden wrath, and all of Your displeasure", reference: "Sahih Muslim 2739"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ العَفوَ وَالعَافِيَةَ فِي الدُّنيَا وَالآخِرَةِ", transliteration: "Allahumma inni as'aluka al-'afwa wal-'afiyah fi ad-dunya wal-akhirah", translation: "O Allah, I ask You for forgiveness and well-being in this life and the hereafter", reference: "Sunan Ibn Majah 3871"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ الهُدَى وَالتُّقَى وَالعَفَافَ وَالغِنَى", transliteration: "Allahumma inni as'aluka al-huda wa at-tuqaa wal-'afaafa wal-ghina", translation: "O Allah, I ask You for guidance, righteousness, chastity, and sufficiency", reference: "Sahih Muslim 2721"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الكُفرِ وَالفَقرِ وَأَعُوذُ بِكَ مِن عَذَابِ القَبرِ", transliteration: "Allahumma inni a'udhu bika min al-kufr wal-faqr wa a'udhu bika min 'adhab al-qabr", translation: "O Allah, I seek refuge in You from disbelief, poverty, and the punishment of the grave", reference: "Sunan Abi Dawud 5090"),
            DuaItem(arabicText: "اللَّهُمَّ مَا أَصبَحَ بِي مِن نِعمَةٍ أَو بِأَحَدٍ مِن خَلقِكَ فَمِنكَ وَحدَكَ لَا شَرِيكَ لَكَ فَلَكَ الحَمدُ وَلَكَ الشُّكرُ", transliteration: "Allahumma ma asbaha bi min ni'matin, aw bi ahadin min khalqika, faminka wahdaka la sharika laka, falaka alhamdu wa laka ash-shukr", translation: "O Allah, whatever blessings I or any of Your creatures rose up with, is from You alone, without partner, so for You is all praise and unto You all thanks.", reference: "Sunan Abi Dawud 5073"),
            DuaItem(arabicText: "رَبِّ اشرَح لِي صَدرِي وَيَسِّر لِي أَمرِي", transliteration: "Rabbi ishrah li sadri wa yassir li amri", translation: "O my Lord, expand for me my chest, and ease for me my task.", reference: "20:25-26"),
            DuaItem(arabicText: "اللَّهُمَّ أَعِنِّي عَلَى ذِكرِكَ وَشُكرِكَ وَحُسنِ عِبَادَتِكَ", transliteration: "Allahumma a'innee ala dhikrika wa shukrika wa husni ibadatika", translation: "O Allah, assist me in remembering You, in thanking You, and in worshipping You in the best manner.", reference: "Sunan Abi Dawud 1522"),
            DuaItem(arabicText: "رَبَّنَا آتِنَا فِي الدُّنيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", transliteration: "Rabbanaa atinaa fid-dunya hasanatan wa fil aakhirati hasanatan wa qinaa 'adhaaban-naar", translation: "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.", reference: "2:201"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِن عَجزِ وَالكَسَلِ وَالجُبنِ وَالهَرَمِ وَالبُخلِ وَأَعُوذُ بِكَ مِن عَذَابِ القَبرِ وَمِن فِتنَةِ المَحيَا وَالمَمَاتِ", transliteration: "Allahumma inni a'udhu bika min al-'ajzi wal-kasali wal-jubni wal-harami wal-bukhli, wa a'udhu bika min 'adhab al-qabr, wa min fitnat al-mahya wal-mamat", translation: "O Allah, I seek refuge in You from incapacity and laziness, from cowardice and senility, and from miserliness. And I seek refuge in You from the punishment of the grave, and from the trials of life and death.", reference: "Sahih Muslim 2706"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ عِلمًا نَافِعًا وَرِزقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا", transliteration: "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbalan", translation: "O Allah, I ask You for knowledge that is of benefit, a good provision, and deeds that will be accepted.", reference: "Sunan Ibn Majah 925"),
            DuaItem(arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الحَيُّ القَيُّومُ ۚ لَا تَأخُذُهُ سِنَةٌ وَلَا نَومٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الأَرضِ ۗ مَن ذَا الَّذِي يَشفَعُ عِندَهُ إِلَّا بِإِذنِهِ ۚ يَعلَمُ مَا بَينَ أَيدِيهِم وَمَا خَلفَهُم ۖ وَلَا يُحِيطُونَ بِشَيءٍ مِّن عِلمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرسِيُّهُ السَّمَاوَاتِ وَالأَرضَ ۖ وَلَا يَئُودُهُ حِفظُهُمَا ۚ وَهُوَ العَلِيُّ العَظِيمُ", transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fi as-samawati wa ma fi al-ard. Man dha allathee yashfa'u 'indahu illa bi-idhnihi? Ya'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bishay'in min 'ilmihi illa bima sha'. Wasi'a kursiyyuhu as-samawati wal-ard, wa la ya'uduhu hifzuhuma, wa Huwal 'Aliyyul-'Azim.", translation: "Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is [presently] before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.", reference: "2:255")
        ]
    )

    // Every entry below was checked against its cited source (sunnah.com numbering for hadith; surah:ayah
    // for Quran) before inclusion - references are load-bearing here, not decoration. When adding to these,
    // verify the collection + number actually carries the dua, and prefer Bukhari/Muslim, then the Four
    // Sunan with an explicit sahih/hasan grading.
    static let morningEvening = DuaCollection(
        title: "Morning & Evening",
        subtitle: "The Prophet's daily adhkar for morning and evening",
        systemImage: "sun.horizon",
        introductionTitle: "Morning & Evening Adhkar",
        introduction: "Remembrances the Prophet ﷺ said at the start and end of every day - seeking Allah's protection, provision, and pleasure before the day makes its own claims. \"And exalt [Allah] with praise of your Lord before the rising of the sun and before its setting.\" (Quran 20:130)",
        items: [
            DuaItem(arabicText: "اللَّهُمَّ أَنتَ رَبِّي لَا إِلَهَ إِلَّا أَنتَ خَلَقتَنِي وَأَنَا عَبدُكَ وَأَنَا عَلَى عَهدِكَ وَوَعدِكَ مَا استَطَعتُ أَعُوذُ بِكَ مِن شَرِّ مَا صَنَعتُ أَبُوءُ لَكَ بِنِعمَتِكَ عَلَيَّ وَأَبُوءُ لَكَ بِذَنبِي فَاغفِر لِي فَإِنَّهُ لَا يَغفِرُ الذُّنُوبَ إِلَّا أَنتَ", transliteration: "Allahumma anta Rabbi la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika ma istata'tu, a'udhu bika min sharri ma sana'tu, abu'u laka bini'matika 'alayya, wa abu'u laka bidhanbi faghfir li, fa innahu la yaghfiru adh-dhunuba illa anta", translation: "O Allah, You are my Lord; there is no god but You. You created me and I am Your servant, and I keep Your covenant and promise as much as I am able. I seek refuge in You from the evil of what I have done. I acknowledge before You Your blessing upon me, and I acknowledge my sin, so forgive me - for none forgives sins but You. (The master of seeking forgiveness; said morning and evening)", reference: "Sahih al-Bukhari 6306"),
            DuaItem(arabicText: "أَمسَينَا وَأَمسَى المُلكُ لِلَّهِ وَالحَمدُ لِلَّهِ لَا إِلَهَ إِلَّا اللَّهُ وَحدَهُ لَا شَرِيكَ لَهُ لَهُ المُلكُ وَلَهُ الحَمدُ وَهُوَ عَلَى كُلِّ شَيءٍ قَدِيرٌ رَبِّ أَسأَلُكَ خَيرَ مَا فِي هَذِهِ اللَّيلَةِ وَخَيرَ مَا بَعدَهَا وَأَعُوذُ بِكَ مِن شَرِّ مَا فِي هَذِهِ اللَّيلَةِ وَشَرِّ مَا بَعدَهَا", transliteration: "Amsayna wa amsal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir. Rabbi as'aluka khayra ma fi hadhihil-laylati wa khayra ma ba'daha, wa a'udhu bika min sharri ma fi hadhihil-laylati wa sharri ma ba'daha", translation: "We have reached evening, and the dominion has reached evening belonging to Allah. Praise be to Allah; there is no god but Allah alone, without partner. His is the dominion and His is the praise, and He is able to do all things. My Lord, I ask You for the good of this night and the good of what follows it, and I seek refuge in You from the evil of this night and the evil of what follows it. (In the morning: 'Asbahna wa asbahal-mulku lillah... I ask You for the good of this day...')", reference: "Sahih Muslim 2723"),
            DuaItem(arabicText: "اللَّهُمَّ بِكَ أَصبَحنَا وَبِكَ أَمسَينَا وَبِكَ نَحيَا وَبِكَ نَمُوتُ وَإِلَيكَ النُّشُورُ", transliteration: "Allahumma bika asbahna wa bika amsayna wa bika nahya wa bika namutu wa ilaykan-nushur", translation: "O Allah, by You we reach the morning and by You we reach the evening; by You we live and by You we die, and to You is the resurrection. (In the evening it ends: '...and to You is the final return')", reference: "Jami' at-Tirmidhi 3391"),
            DuaItem(arabicText: "بِسمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسمِهِ شَيءٌ فِي الأَرضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ العَلِيمُ", transliteration: "Bismillahil-ladhi la yadurru ma'a ismihi shay'un fil-ardi wa la fis-sama'i wa huwas-Sami'ul-'Alim", translation: "In the name of Allah, with Whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, the All-Knowing. (Three times, morning and evening)", reference: "Sunan Abi Dawud 5088"),
            DuaItem(arabicText: "رَضِيتُ بِاللَّهِ رَبًّا وَبِالإِسلَامِ دِينًا وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ نَبِيًّا", transliteration: "Raditu billahi Rabban, wa bil-Islami dinan, wa bi-Muhammadin sallallahu 'alayhi wa sallama nabiyya", translation: "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet. (Three times, morning and evening)", reference: "Sunan Abi Dawud 5072"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ العَافِيَةَ فِي الدُّنيَا وَالآخِرَةِ اللَّهُمَّ إِنِّي أَسأَلُكَ العَفوَ وَالعَافِيَةَ فِي دِينِي وَدُنيَايَ وَأَهلِي وَمَالِي اللَّهُمَّ استُر عَورَاتِي وَآمِن رَوعَاتِي اللَّهُمَّ احفَظنِي مِن بَينِ يَدَيَّ وَمِن خَلفِي وَعَن يَمِينِي وَعَن شِمَالِي وَمِن فَوقِي وَأَعُوذُ بِعَظَمَتِكَ أَن أُغتَالَ مِن تَحتِي", transliteration: "Allahumma inni as'alukal-'afiyata fid-dunya wal-akhirah. Allahumma inni as'alukal-'afwa wal-'afiyata fi dini wa dunyaya wa ahli wa mali. Allahumma-stur 'awrati wa amin raw'ati. Allahumma-hfazni min bayni yadayya wa min khalfi wa 'an yamini wa 'an shimali wa min fawqi, wa a'udhu bi'azamatika an ughtala min tahti", translation: "O Allah, I ask You for well-being in this world and the Hereafter. O Allah, I ask You for pardon and well-being in my religion, my worldly life, my family, and my wealth. O Allah, conceal my faults and calm my fears. O Allah, guard me from in front of me and behind me, from my right and my left, and from above me; and I seek refuge in Your greatness from being seized from beneath me.", reference: "Sunan Abi Dawud 5074"),
            DuaItem(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ", transliteration: "Subhanallahi wa bihamdih", translation: "Glory be to Allah and praise be to Him. (One hundred times: whoever says it morning and evening, no one brings anything better on the Day of Resurrection except one who said the same or more)", reference: "Sahih Muslim 2692"),
            DuaItem(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ عَدَدَ خَلقِهِ وَرِضَا نَفسِهِ وَزِنَةَ عَرشِهِ وَمِدَادَ كَلِمَاتِهِ", transliteration: "Subhanallahi wa bihamdihi 'adada khalqihi wa rida nafsihi wa zinata 'arshihi wa midada kalimatih", translation: "Glory be to Allah and praise be to Him, as many as His creation, as much as pleases Him, as heavy as His Throne, and as much as the ink of His words. (Three times in the morning)", reference: "Sahih Muslim 2726"),
            DuaItem(arabicText: "حَسبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيهِ تَوَكَّلتُ وَهُوَ رَبُّ العَرشِ العَظِيمِ", transliteration: "Hasbiyallahu la ilaha illa huwa, 'alayhi tawakkaltu, wa huwa Rabbul-'arshil-'azim", translation: "Allah is sufficient for me; there is no god but Him. In Him I put my trust, and He is the Lord of the Mighty Throne. (Seven times, morning and evening)", reference: "Sunan Abi Dawud 5081"),
            DuaItem(arabicText: "اللَّهُمَّ فَاطِرَ السَّمَاوَاتِ وَالأَرضِ عَالِمَ الغَيبِ وَالشَّهَادَةِ رَبَّ كُلِّ شَيءٍ وَمَلِيكَهُ أَشهَدُ أَن لَا إِلَهَ إِلَّا أَنتَ أَعُوذُ بِكَ مِن شَرِّ نَفسِي وَمِن شَرِّ الشَّيطَانِ وَشِركِهِ", transliteration: "Allahumma fatiras-samawati wal-ard, 'alimal-ghaybi wash-shahadah, Rabba kulli shay'in wa malikah, ashhadu an la ilaha illa anta, a'udhu bika min sharri nafsi wa min sharrish-shaytani wa shirkih", translation: "O Allah, Creator of the heavens and the earth, Knower of the unseen and the seen, Lord and Sovereign of all things: I bear witness that there is no god but You. I seek refuge in You from the evil of my own self and from the evil of Shaytan and his call to associate partners with Allah.", reference: "Jami' at-Tirmidhi 3529")
        ]
    )

    static let sleepWaking = DuaCollection(
        title: "Sleep & Waking",
        subtitle: "What the Prophet said lying down to sleep and on waking",
        systemImage: "moon.zzz",
        introductionTitle: "Sleep & Waking Duas",
        introduction: "The Prophet ﷺ closed each day surrendering his soul to Allah and opened each morning with gratitude for its return. \"And it is He who makes the night a covering for you and sleep a rest.\" (Quran 25:47)",
        items: [
            DuaItem(arabicText: "بِاسمِكَ اللَّهُمَّ أَمُوتُ وَأَحيَا", transliteration: "Bismika Allahumma amutu wa ahya", translation: "In Your name, O Allah, I die and I live. (Said when going to bed)", reference: "Sahih al-Bukhari 6324"),
            DuaItem(arabicText: "الحَمدُ لِلَّهِ الَّذِي أَحيَانَا بَعدَ مَا أَمَاتَنَا وَإِلَيهِ النُّشُورُ", transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur", translation: "Praise be to Allah, Who gave us life after He caused us to die, and to Him is the resurrection. (Said upon waking)", reference: "Sahih al-Bukhari 6324"),
            DuaItem(arabicText: "بِاسمِكَ رَبِّي وَضَعتُ جَنبِي وَبِكَ أَرفَعُهُ إِن أَمسَكتَ نَفسِي فَارحَمهَا وَإِن أَرسَلتَهَا فَاحفَظهَا بِمَا تَحفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ", transliteration: "Bismika Rabbi wada'tu janbi wa bika arfa'uh, in amsakta nafsi farhamha, wa in arsaltaha fahfazha bima tahfazu bihi 'ibadakas-salihin", translation: "In Your name, my Lord, I lay down my side, and by You I raise it. If You take my soul, have mercy on it; and if You release it, protect it with that with which You protect Your righteous servants.", reference: "Sahih al-Bukhari 6320"),
            DuaItem(arabicText: "اللَّهُمَّ أَسلَمتُ نَفسِي إِلَيكَ وَفَوَّضتُ أَمرِي إِلَيكَ وَوَجَّهتُ وَجهِي إِلَيكَ وَأَلجَأتُ ظَهرِي إِلَيكَ رَغبَةً وَرَهبَةً إِلَيكَ لَا مَلجَأَ وَلَا مَنجَا مِنكَ إِلَّا إِلَيكَ آمَنتُ بِكِتَابِكَ الَّذِي أَنزَلتَ وَبِنَبِيِّكَ الَّذِي أَرسَلتَ", transliteration: "Allahumma aslamtu nafsi ilayk, wa fawwadtu amri ilayk, wa wajjahtu wajhi ilayk, wa alja'tu zahri ilayk, raghbatan wa rahbatan ilayk, la malja'a wa la manja minka illa ilayk, amantu bikitabikal-ladhi anzalt, wa binabiyyikal-ladhi arsalt", translation: "O Allah, I surrender my soul to You, I entrust my affairs to You, I turn my face to You, and I rely completely on You, in hope and fear of You. There is no refuge and no escape from You except to You. I believe in Your Book which You revealed and Your Prophet whom You sent. (Whoever says it and dies that night, dies upon the natural faith)", reference: "Sahih al-Bukhari 6311"),
            DuaItem(arabicText: "سُبحَانَ اللَّهِ (ثَلَاثًا وَثَلَاثِينَ) وَالحَمدُ لِلَّهِ (ثَلَاثًا وَثَلَاثِينَ) وَاللَّهُ أَكبَرُ (أَربَعًا وَثَلَاثِينَ)", transliteration: "Subhanallah (33 times), Alhamdulillah (33 times), Allahu Akbar (34 times)", translation: "Glory be to Allah (33 times), praise be to Allah (33 times), Allah is the Greatest (34 times) - the Prophet ﷺ taught it to Fatimah and Ali when they asked for a servant, saying it is better for them than a servant.", reference: "Sahih al-Bukhari 5362"),
            DuaItem(arabicText: "اللَّهُمَّ قِنِي عَذَابَكَ يَومَ تَبعَثُ عِبَادَكَ", transliteration: "Allahumma qini 'adhabaka yawma tab'athu 'ibadak", translation: "O Allah, protect me from Your punishment on the Day You resurrect Your servants. (Three times, lying on the right side)", reference: "Sunan Abi Dawud 5045"),
            DuaItem(arabicText: "الحَمدُ لِلَّهِ الَّذِي أَطعَمَنَا وَسَقَانَا وَكَفَانَا وَآوَانَا فَكَم مِمَّن لَا كَافِيَ لَهُ وَلَا مُؤوِيَ", transliteration: "Alhamdu lillahil-ladhi at'amana wa saqana wa kafana wa awana, fakam mimman la kafiya lahu wa la mu'wi", translation: "Praise be to Allah, Who has fed us, given us drink, sufficed us, and sheltered us - for how many have none to suffice them or shelter them.", reference: "Sahih Muslim 2715"),
            DuaItem(arabicText: "اللَّهُمَّ خَلَقتَ نَفسِي وَأَنتَ تَوَفَّاهَا لَكَ مَمَاتُهَا وَمَحيَاهَا إِن أَحيَيتَهَا فَاحفَظهَا وَإِن أَمَتَّهَا فَاغفِر لَهَا اللَّهُمَّ إِنِّي أَسأَلُكَ العَافِيَةَ", transliteration: "Allahumma khalaqta nafsi wa anta tawaffaha, laka mamatuha wa mahyaha, in ahyaytaha fahfazha, wa in amattaha faghfir laha. Allahumma inni as'alukal-'afiyah", translation: "O Allah, You created my soul and You take it back; to You belong its death and its life. If You keep it alive, protect it, and if You cause it to die, forgive it. O Allah, I ask You for well-being.", reference: "Sahih Muslim 2712")
        ]
    )

    static let distress = DuaCollection(
        title: "Distress & Anxiety",
        subtitle: "The Prophet's duas for worry, grief, and hardship",
        systemImage: "heart",
        introductionTitle: "Duas for Distress & Anxiety",
        introduction: "Supplications the Prophet ﷺ said - and taught - for the moments when the heart is tight and the way out is hidden. \"Is He not who responds to the desperate one when he calls upon Him, and removes evil?\" (Quran 27:62)",
        items: [
            DuaItem(arabicText: "لَا إِلَهَ إِلَّا اللَّهُ العَظِيمُ الحَلِيمُ لَا إِلَهَ إِلَّا اللَّهُ رَبُّ العَرشِ العَظِيمِ لَا إِلَهَ إِلَّا اللَّهُ رَبُّ السَّمَاوَاتِ وَرَبُّ الأَرضِ وَرَبُّ العَرشِ الكَرِيمِ", transliteration: "La ilaha illallahul-'Azimul-Halim, la ilaha illallahu Rabbul-'arshil-'azim, la ilaha illallahu Rabbus-samawati wa Rabbul-ardi wa Rabbul-'arshil-karim", translation: "There is no god but Allah, the Magnificent, the Forbearing. There is no god but Allah, Lord of the Mighty Throne. There is no god but Allah, Lord of the heavens, Lord of the earth, and Lord of the Noble Throne. (The Prophet's dua at times of distress)", reference: "Sahih al-Bukhari 6346"),
            DuaItem(arabicText: "يَا حَيُّ يَا قَيُّومُ بِرَحمَتِكَ أَستَغِيثُ", transliteration: "Ya Hayyu ya Qayyum, bi-rahmatika astaghith", translation: "O Ever-Living, O Sustainer of all, in Your mercy I seek relief. (Said by the Prophet ﷺ when a matter distressed him)", reference: "Jami' at-Tirmidhi 3524"),
            DuaItem(arabicText: "لَا إِلَهَ إِلَّا أَنتَ سُبحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ", transliteration: "La ilaha illa anta subhanaka inni kuntu minaz-zalimin", translation: "There is no god but You; glory be to You. Indeed, I have been of the wrongdoers. (The dua of Yunus in the belly of the whale - no Muslim supplicates with it for anything except that Allah answers him)", reference: "Jami' at-Tirmidhi 3505"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الهَمِّ وَالحَزَنِ وَالعَجزِ وَالكَسَلِ وَالجُبنِ وَالبُخلِ وَضَلَعِ الدَّينِ وَغَلَبَةِ الرِّجَالِ", transliteration: "Allahumma inni a'udhu bika minal-hammi wal-hazan, wal-'ajzi wal-kasal, wal-jubni wal-bukhl, wa dala'id-dayni wa ghalabatir-rijal", translation: "O Allah, I seek refuge in You from worry and grief, from incapacity and laziness, from cowardice and miserliness, from the burden of debt and from being overpowered by men.", reference: "Sahih al-Bukhari 6369"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي عَبدُكَ ابنُ عَبدِكَ ابنُ أَمَتِكَ نَاصِيَتِي بِيَدِكَ مَاضٍ فِيَّ حُكمُكَ عَدلٌ فِيَّ قَضَاؤُكَ أَسأَلُكَ بِكُلِّ اسمٍ هُوَ لَكَ سَمَّيتَ بِهِ نَفسَكَ أَو أَنزَلتَهُ فِي كِتَابِكَ أَو عَلَّمتَهُ أَحَدًا مِن خَلقِكَ أَوِ استَأثَرتَ بِهِ فِي عِلمِ الغَيبِ عِندَكَ أَن تَجعَلَ القُرآنَ رَبِيعَ قَلبِي وَنُورَ صَدرِي وَجِلَاءَ حُزنِي وَذَهَابَ هَمِّي", transliteration: "Allahumma inni 'abduka, ibnu 'abdika, ibnu amatika, nasiyati biyadika, madin fiyya hukmuka, 'adlun fiyya qada'uka, as'aluka bikulli ismin huwa laka, sammayta bihi nafsaka, aw anzaltahu fi kitabika, aw 'allamtahu ahadan min khalqika, aw ista'tharta bihi fi 'ilmil-ghaybi 'indaka, an taj'alal-Qur'ana rabi'a qalbi, wa nura sadri, wa jila'a huzni, wa dhahaba hammi", translation: "O Allah, I am Your servant, son of Your servant, son of Your maidservant. My forelock is in Your hand, Your command over me is ever executed, and Your decree over me is just. I ask You by every name that is Yours - with which You named Yourself, or revealed in Your Book, or taught to any of Your creation, or kept with Yourself in the knowledge of the unseen - that You make the Quran the spring of my heart, the light of my chest, the departure of my sorrow, and the passing of my worry. (Whoever says it, Allah removes his sorrow and grief and replaces them with joy)", reference: "Musnad Ahmad 3712"),
            DuaItem(arabicText: "حَسبُنَا اللَّهُ وَنِعمَ الوَكِيلُ", transliteration: "Hasbunallahu wa ni'mal-wakil", translation: "Sufficient for us is Allah, and He is the best Disposer of affairs. (Said by Ibrahim when cast into the fire, and by the believers when threatened)", reference: "3:173"),
            DuaItem(arabicText: "لَا حَولَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "La hawla wa la quwwata illa billah", translation: "There is no power and no strength except through Allah. (A treasure from the treasures of Paradise)", reference: "Sahih al-Bukhari 6384")
        ]
    )

    static let travel = DuaCollection(
        title: "Travel",
        subtitle: "Duas for setting out, the road, and returning home",
        systemImage: "airplane",
        introductionTitle: "Travel Duas",
        introduction: "From mounting the ride to returning home, the Prophet ﷺ wrapped the whole journey in remembrance. \"...that you may settle yourselves upon their backs and then remember the favor of your Lord.\" (Quran 43:13)",
        items: [
            DuaItem(arabicText: "سُبحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنقَلِبُونَ", transliteration: "Subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila Rabbina lamunqalibun", translation: "Glory be to the One who subjected this to us, for we could never have accomplished it ourselves - and indeed, to our Lord we shall return. (Said after Allahu Akbar three times, when mounted for travel)", reference: "Sahih Muslim 1342"),
            DuaItem(arabicText: "اللَّهُمَّ إِنَّا نَسأَلُكَ فِي سَفَرِنَا هَذَا البِرَّ وَالتَّقوَى وَمِنَ العَمَلِ مَا تَرضَى اللَّهُمَّ هَوِّن عَلَينَا سَفَرَنَا هَذَا وَاطوِ عَنَّا بُعدَهُ اللَّهُمَّ أَنتَ الصَّاحِبُ فِي السَّفَرِ وَالخَلِيفَةُ فِي الأَهلِ", transliteration: "Allahumma inna nas'aluka fi safarina hadhal-birra wat-taqwa, wa minal-'amali ma tarda. Allahumma hawwin 'alayna safarana hadha watwi 'anna bu'dah. Allahumma antas-sahibu fis-safari wal-khalifatu fil-ahl", translation: "O Allah, we ask You on this journey of ours for righteousness and taqwa, and for deeds that please You. O Allah, make this journey easy for us and fold up its distance for us. O Allah, You are the Companion on the journey and the Guardian over the family left behind.", reference: "Sahih Muslim 1342"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِن وَعثَاءِ السَّفَرِ وَكَآبَةِ المَنظَرِ وَسُوءِ المُنقَلَبِ فِي المَالِ وَالأَهلِ", transliteration: "Allahumma inni a'udhu bika min wa'tha'is-safari, wa ka'abatil-manzari, wa su'il-munqalabi fil-mali wal-ahl", translation: "O Allah, I seek refuge in You from the hardships of travel, from a grievous sight, and from an ill turn of fortune in wealth and family.", reference: "Sahih Muslim 1342"),
            DuaItem(arabicText: "آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ", transliteration: "Ayibuna, ta'ibuna, 'abiduna, li-Rabbina hamidun", translation: "We return, repentant, worshipping, and praising our Lord. (Added when returning from the journey)", reference: "Sahih Muslim 1342"),
            DuaItem(arabicText: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِن شَرِّ مَا خَلَقَ", transliteration: "A'udhu bikalimatillahit-tammati min sharri ma khalaq", translation: "I seek refuge in the perfect words of Allah from the evil of what He has created. (Whoever says it when stopping at a place, nothing will harm him until he departs from it)", reference: "Sahih Muslim 2708"),
            DuaItem(arabicText: "أَستَودِعُ اللَّهَ دِينَكَ وَأَمَانَتَكَ وَخَوَاتِيمَ عَمَلِكَ", transliteration: "Astawdi'ullaha dinaka wa amanataka wa khawatima 'amalik", translation: "I entrust to Allah your religion, your trusts, and the final outcome of your deeds. (The Prophet's farewell to a departing traveler)", reference: "Sunan Abi Dawud 2600")
        ]
    )

    static let homeMosque = DuaCollection(
        title: "Home & Mosque",
        subtitle: "Duas for stepping out, coming home, and the masjid",
        systemImage: "door.left.hand.open",
        introductionTitle: "Home & Mosque Duas",
        introduction: "The Prophet ﷺ marked every threshold with remembrance - leaving in Allah's care, returning with His name, and entering His house asking for His mercy.",
        items: [
            DuaItem(arabicText: "بِسمِ اللَّهِ تَوَكَّلتُ عَلَى اللَّهِ وَلَا حَولَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "Bismillahi tawakkaltu 'alallah, wa la hawla wa la quwwata illa billah", translation: "In the name of Allah, I place my trust in Allah, and there is no power and no strength except through Allah. (On leaving the home - it is said to him: you are guided, sufficed, and protected)", reference: "Sunan Abi Dawud 5095"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ أَن أَضِلَّ أَو أُضَلَّ أَو أَزِلَّ أَو أُزَلَّ أَو أَظلِمَ أَو أُظلَمَ أَو أَجهَلَ أَو يُجهَلَ عَلَيَّ", transliteration: "Allahumma inni a'udhu bika an adilla aw udall, aw azilla aw uzall, aw azlima aw uzlam, aw ajhala aw yujhala 'alayy", translation: "O Allah, I seek refuge in You from going astray or being led astray, from slipping or being made to slip, from wronging or being wronged, and from acting ignorantly or being treated with ignorance. (On leaving the home)", reference: "Sunan Abi Dawud 5094"),
            DuaItem(arabicText: "اللَّهُمَّ افتَح لِي أَبوَابَ رَحمَتِكَ", transliteration: "Allahumma-ftah li abwaba rahmatik", translation: "O Allah, open for me the doors of Your mercy. (On entering the masjid)", reference: "Sahih Muslim 713"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ مِن فَضلِكَ", transliteration: "Allahumma inni as'aluka min fadlik", translation: "O Allah, I ask You of Your bounty. (On leaving the masjid)", reference: "Sahih Muslim 713"),
            DuaItem(arabicText: "أَعُوذُ بِاللَّهِ العَظِيمِ وَبِوَجهِهِ الكَرِيمِ وَسُلطَانِهِ القَدِيمِ مِنَ الشَّيطَانِ الرَّجِيمِ", transliteration: "A'udhu billahil-'Azim, wa biwajhihil-karim, wa sultanihil-qadim, minash-shaytanir-rajim", translation: "I seek refuge in Allah the Magnificent, in His Noble Face and His eternal authority, from the accursed Shaytan. (On entering the masjid - Shaytan says: he is protected from me for the rest of the day)", reference: "Sunan Abi Dawud 466")
        ]
    )

    static let foodDrink = DuaCollection(
        title: "Food & Drink",
        subtitle: "Duas before, during, and after eating and drinking",
        systemImage: "fork.knife",
        introductionTitle: "Food & Drink Duas",
        introduction: "\"O messengers, eat from the good foods and work righteousness.\" (Quran 23:51) The sunnah surrounds every meal with Allah's name and gratitude for His provision.",
        items: [
            DuaItem(arabicText: "بِسمِ اللَّهِ", transliteration: "Bismillah", translation: "In the name of Allah. (Before eating - 'Mention Allah's name, eat with your right hand, and eat from what is nearest to you')", reference: "Sahih al-Bukhari 5376"),
            DuaItem(arabicText: "بِسمِ اللَّهِ أَوَّلَهُ وَآخِرَهُ", transliteration: "Bismillahi awwalahu wa akhirah", translation: "In the name of Allah, at its beginning and its end. (If one forgot to say Bismillah before starting)", reference: "Sunan Abi Dawud 3767"),
            DuaItem(arabicText: "الحَمدُ لِلَّهِ الَّذِي أَطعَمَنِي هَذَا وَرَزَقَنِيهِ مِن غَيرِ حَولٍ مِنِّي وَلَا قُوَّةٍ", transliteration: "Alhamdu lillahil-ladhi at'amani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah", translation: "Praise be to Allah, Who fed me this and provided it for me without any strength or power on my part. (After eating - his past sins are forgiven)", reference: "Sunan Abi Dawud 4023"),
            DuaItem(arabicText: "اللَّهُمَّ بَارِك لَنَا فِيهِ وَزِدنَا مِنهُ", transliteration: "Allahumma barik lana fihi wa zidna minhu", translation: "O Allah, bless us in it and give us more of it. (On drinking milk - for nothing suffices in place of food and drink except milk)", reference: "Jami' at-Tirmidhi 3455"),
            DuaItem(arabicText: "ذَهَبَ الظَّمَأُ وَابتَلَّتِ العُرُوقُ وَثَبَتَ الأَجرُ إِن شَاءَ اللَّهُ", transliteration: "Dhahabaz-zama'u wabtallatil-'uruqu wa thabatal-ajru in sha' Allah", translation: "The thirst is gone, the veins are moistened, and the reward is confirmed, if Allah wills. (When breaking the fast)", reference: "Sunan Abi Dawud 2357")
        ]
    )

    static let forgiveness = DuaCollection(
        title: "Forgiveness & Repentance",
        subtitle: "Seeking Allah's pardon, as the Prophet did daily",
        systemImage: "arrow.uturn.backward.circle",
        introductionTitle: "Forgiveness & Repentance Duas",
        introduction: "The Prophet ﷺ - though forgiven - sought Allah's forgiveness dozens of times a day, and taught his companions to do the same. \"And whoever does a wrong or wrongs himself but then seeks forgiveness of Allah will find Allah Forgiving and Merciful.\" (Quran 4:110)",
        items: [
            DuaItem(arabicText: "رَبِّ اغفِر لِي وَتُب عَلَيَّ إِنَّكَ أَنتَ التَّوَّابُ الرَّحِيمُ", transliteration: "Rabbi-ghfir li wa tub 'alayya, innaka antat-Tawwabur-Rahim", translation: "My Lord, forgive me and accept my repentance; indeed, You are the Accepting of Repentance, the Merciful. (The Prophet ﷺ was counted saying it a hundred times in a single gathering)", reference: "Sunan Abi Dawud 1516"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي ظَلَمتُ نَفسِي ظُلمًا كَثِيرًا وَلَا يَغفِرُ الذُّنُوبَ إِلَّا أَنتَ فَاغفِر لِي مَغفِرَةً مِن عِندِكَ وَارحَمنِي إِنَّكَ أَنتَ الغَفُورُ الرَّحِيمُ", transliteration: "Allahumma inni zalamtu nafsi zulman kathiran, wa la yaghfirudh-dhunuba illa anta, faghfir li maghfiratan min 'indika, warhamni, innaka antal-Ghafurur-Rahim", translation: "O Allah, I have greatly wronged myself, and none forgives sins but You; so grant me forgiveness from You and have mercy on me. Indeed, You are the Forgiving, the Merciful. (Taught by the Prophet ﷺ to Abu Bakr to say in prayer)", reference: "Sahih al-Bukhari 834"),
            DuaItem(arabicText: "أَستَغفِرُ اللَّهَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الحَيُّ القَيُّومُ وَأَتُوبُ إِلَيهِ", transliteration: "Astaghfirullahal-ladhi la ilaha illa huwal-Hayyul-Qayyumu wa atubu ilayh", translation: "I seek the forgiveness of Allah, besides Whom there is no god, the Ever-Living, the Sustainer of all, and I turn to Him in repentance. (Whoever says it is forgiven, even if he had fled from battle)", reference: "Sunan Abi Dawud 1517"),
            DuaItem(arabicText: "اللَّهُمَّ اغفِر لِي ذَنبِي كُلَّهُ دِقَّهُ وَجِلَّهُ وَأَوَّلَهُ وَآخِرَهُ وَعَلَانِيَتَهُ وَسِرَّهُ", transliteration: "Allahumma-ghfir li dhanbi kullah, diqqahu wa jillah, wa awwalahu wa akhirah, wa 'alaniyatahu wa sirrah", translation: "O Allah, forgive me all my sins - the small and the great, the first and the last, the open and the hidden. (Said by the Prophet ﷺ in prostration)", reference: "Sahih Muslim 483"),
            DuaItem(arabicText: "سُبحَانَكَ اللَّهُمَّ وَبِحَمدِكَ أَشهَدُ أَن لَا إِلَهَ إِلَّا أَنتَ أَستَغفِرُكَ وَأَتُوبُ إِلَيكَ", transliteration: "Subhanakallahumma wa bihamdika, ashhadu an la ilaha illa anta, astaghfiruka wa atubu ilayk", translation: "Glory be to You, O Allah, and praise be to You. I bear witness that there is no god but You; I seek Your forgiveness and turn to You in repentance. (Said on rising from a gathering - an expiation for whatever happened in it)", reference: "Sunan Abi Dawud 4859")
        ]
    )

    static let prophets = DuaCollection(
        title: "Duas of the Prophets",
        subtitle: "Supplications of the prophets recorded in the Quran",
        systemImage: "sparkles",
        introductionTitle: "Duas of the Prophets",
        introduction: "The Quran preserves the very words the prophets called upon their Lord with - in illness, loneliness, need, and gratitude - and every one was answered. \"So We responded to him...\" (Quran 21:84)",
        items: [
            DuaItem(arabicText: "أَنِّي مَسَّنِيَ ٱلضُّرُّ وَأَنتَ أَرۡحَمُ ٱلرَّٰحِمِينَ", transliteration: "Anni massaniyad-durru wa anta arhamur-rahimin", translation: "Indeed, adversity has touched me, and You are the Most Merciful of the merciful. (Ayyub, in his long illness - and Allah removed his affliction)", reference: "21:83"),
            DuaItem(arabicText: "رَبِّ لَا تَذَرۡنِي فَرۡدٗا وَأَنتَ خَيۡرُ ٱلۡوَٰرِثِينَ", transliteration: "Rabbi la tadharni fardan wa anta khayrul-warithin", translation: "My Lord, do not leave me alone, and You are the best of inheritors. (Zakariyya, asking for a child - and he was given Yahya)", reference: "21:89"),
            DuaItem(arabicText: "رَبِّ أَوۡزِعۡنِيٓ أَنۡ أَشۡكُرَ نِعۡمَتَكَ ٱلَّتِيٓ أَنۡعَمۡتَ عَلَيَّ وَعَلَىٰ وَٰلِدَيَّ وَأَنۡ أَعۡمَلَ صَٰلِحٗا تَرۡضَىٰهُ وَأَدۡخِلۡنِي بِرَحۡمَتِكَ فِي عِبَادِكَ ٱلصَّٰلِحِينَ", transliteration: "Rabbi awzi'ni an ashkura ni'matakal-lati an'amta 'alayya wa 'ala walidayya wa an a'mala salihan tardahu wa adkhilni birahmatika fi 'ibadikas-salihin", translation: "My Lord, enable me to be grateful for Your favor which You have bestowed upon me and my parents, and to do righteousness that pleases You, and admit me by Your mercy among Your righteous servants. (Sulayman, on hearing the ant)", reference: "27:19"),
            DuaItem(arabicText: "رَبِّ إِنِّي لِمَآ أَنزَلۡتَ إِلَيَّ مِنۡ خَيۡرٖ فَقِيرٞ", transliteration: "Rabbi inni lima anzalta ilayya min khayrin faqir", translation: "My Lord, indeed I am in need of whatever good You send down to me. (Musa, alone and destitute in Madyan - and he was soon given shelter, work, and family)", reference: "28:24"),
            DuaItem(arabicText: "رَّبِّ ٱغۡفِرۡ لِي وَلِوَٰلِدَيَّ وَلِمَن دَخَلَ بَيۡتِيَ مُؤۡمِنٗا وَلِلۡمُؤۡمِنِينَ وَٱلۡمُؤۡمِنَٰتِ", transliteration: "Rabbi-ghfir li wa liwalidayya wa liman dakhala baytiya mu'minan wa lil-mu'minina wal-mu'minat", translation: "My Lord, forgive me and my parents and whoever enters my house a believer, and the believing men and believing women. (Nuh)", reference: "71:28"),
            DuaItem(arabicText: "رَبِّ هَبۡ لِي حُكۡمٗا وَأَلۡحِقۡنِي بِٱلصَّٰلِحِينَ", transliteration: "Rabbi hab li hukman wa alhiqni bis-salihin", translation: "My Lord, grant me wisdom and join me with the righteous. (Ibrahim)", reference: "26:83")
        ]
    )

    static let rabbana = DuaCollection(
        title: "40 Rabbana Duas",
        subtitle: "Quranic duas beginning with Rabbana",
        systemImage: "40.circle",
        introductionTitle: "40 Rabbana Duas",
        introduction: "رَبَّنَا (Rabbanaa) means \"Our Lord.\" These Quranic supplications begin by calling on Allah with that intimate address, then ask for forgiveness, guidance, mercy, patience, protection, victory, provision, and success in this life and the Hereafter.",
        // Each entry carries ONLY its own supplication, not the whole ayah it sits in. Many of these duas are a
        // clause inside a longer verse ("and among them are those who say..."), and three ayahs (2:286, 3:193,
        // 59:10) hold more than one dua. Storing the full ayah on every entry made the same Arabic render two or
        // three times in a row, and made the block long enough to be cut off.
        items: [
            DuaItem(arabicText: "رَبَّنَا تَقَبَّلۡ مِنَّآۖ إِنَّكَ أَنتَ ٱلسَّمِيعُ ٱلۡعَلِيمُ", transliteration: "Rabbana taqabbal minnaa innaka Antas Samee'ul Aleem", translation: "Our Lord, accept this from us. Indeed, You are the Hearing, the Knowing.", reference: "2:127"),
            DuaItem(arabicText: "رَبَّنَا وَٱجۡعَلۡنَا مُسۡلِمَيۡنِ لَكَ وَمِن ذُرِّيَّتِنَآ أُمَّةٗ مُّسۡلِمَةٗ لَّكَ وَأَرِنَا مَنَاسِكَنَا وَتُبۡ عَلَيۡنَآۖ إِنَّكَ أَنتَ ٱلتَّوَّابُ ٱلرَّحِيمُ", transliteration: "Rabbana waj'alnaa muslimaini laka wa min zurriyyatinaaa ummatam muslimatal laka wa arinaa manaasikanaa wa tub 'alainaa innaka antat Tawwaabur Raheem", translation: "Our Lord, make us Muslims in submission to You and from our descendants a Muslim nation in submission to You. Show us our rites and accept our repentance. Indeed, You are the Accepting of Repentance, the Merciful.", reference: "2:128"),
            DuaItem(arabicText: "رَبَّنَآ ءَاتِنَا فِي ٱلدُّنۡيَا حَسَنَةٗ وَفِي ٱلۡأٓخِرَةِ حَسَنَةٗ وَقِنَا عَذَابَ ٱلنَّارِ", transliteration: "Rabbana atina fid dunyaa hasanatanw wa fil aakhirati hasanatanw wa qinaa azaaban Naar", translation: "Our Lord, give us in this world good and in the Hereafter good and protect us from the punishment of the Fire.", reference: "2:201"),
            DuaItem(arabicText: "رَبَّنَآ أَفۡرِغۡ عَلَيۡنَا صَبۡرٗا وَثَبِّتۡ أَقۡدَامَنَا وَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbana afrigh 'alainaa sabranw wa sabbit aqdaamanaa wansurnaa 'alal qawmil kaafireen", translation: "Our Lord, pour upon us patience, plant firmly our feet, and give us victory over the disbelieving people.", reference: "2:250"),
            DuaItem(arabicText: "رَبَّنَا لَا تُؤَاخِذۡنَآ إِن نَّسِينَآ أَوۡ أَخۡطَأۡنَاۚ", transliteration: "Rabbana laa tu'aakhiznaaa in naseenaaa aw akhtaanaa", translation: "Our Lord, do not impose blame upon us if we have forgotten or erred.", reference: "2:286"),
            DuaItem(arabicText: "رَبَّنَا وَلَا تَحۡمِلۡ عَلَيۡنَآ إِصۡرٗا كَمَا حَمَلۡتَهُۥ عَلَى ٱلَّذِينَ مِن قَبۡلِنَاۚ", transliteration: "Rabbana wa laa tahmil-'alainaaa isran kamaa hamaltahoo 'alal-lazeena min qablinaa", translation: "Our Lord, lay not upon us a burden like that which You laid upon those before us.", reference: "2:286"),
            DuaItem(arabicText: "رَبَّنَا وَلَا تُحَمِّلۡنَا مَا لَا طَاقَةَ لَنَا بِهِۦۖ وَٱعۡفُ عَنَّا وَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَآۚ أَنتَ مَوۡلَىٰنَا فَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbana wa laa tuhammilnaa maa laa taaqata lanaa bih; wa'fu 'annaa waghfir lanaa warhamnaa; Anta mawlaanaa fansurnaa 'alal qawmil kaafireen", translation: "Our Lord, burden us not with what we have no ability to bear. Pardon us, forgive us, and have mercy upon us. You are our protector, so give us victory over the disbelieving people.", reference: "2:286"),
            DuaItem(arabicText: "رَبَّنَا لَا تُزِغۡ قُلُوبَنَا بَعۡدَ إِذۡ هَدَيۡتَنَا وَهَبۡ لَنَا مِن لَّدُنكَ رَحۡمَةًۚ إِنَّكَ أَنتَ ٱلۡوَهَّابُ", transliteration: "Rabbana laa tuzigh quloobanaa ba'da iz hadaitanaa wa hab lanaa mil ladunka rahmah; innaka antal Wahhaab", translation: "Our Lord, let not our hearts deviate after You have guided us and grant us mercy from Yourself. Indeed, You are the Bestower.", reference: "3:8"),
            DuaItem(arabicText: "رَبَّنَآ إِنَّكَ جَامِعُ ٱلنَّاسِ لِيَوۡمٖ لَّا رَيۡبَ فِيهِۚ إِنَّ ٱللَّهَ لَا يُخۡلِفُ ٱلۡمِيعَادَ", transliteration: "Rabbanaaa innaka jaami 'un-naasil Yawmil laa raibafeeh; innal laaha laa yukhliful mee'aad", translation: "Our Lord, surely You will gather the people for a Day about which there is no doubt. Indeed, Allah does not fail in His promise.", reference: "3:9"),
            DuaItem(arabicText: "رَبَّنَآ إِنَّنَآ ءَامَنَّا فَٱغۡفِرۡ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ ٱلنَّارِ", transliteration: "Rabbanaaa innanaaa aamannaa faghfir lanaa zunoobanaa wa qinaa 'azaaban Naar", translation: "Our Lord, indeed we have believed, so forgive us our sins and protect us from the punishment of the Fire.", reference: "3:16"),
            DuaItem(arabicText: "رَبَّنَآ ءَامَنَّا بِمَآ أَنزَلۡتَ وَٱتَّبَعۡنَا ٱلرَّسُولَ فَٱكۡتُبۡنَا مَعَ ٱلشَّٰهِدِينَ", transliteration: "Rabbanaaa aamannaa bimaaa anzalta wattaba'nar Rasoola faktubnaa ma'ash shaahideen", translation: "Our Lord, we have believed in what You revealed and have followed the messenger, so register us among the witnesses to truth.", reference: "3:53"),
            DuaItem(arabicText: "رَبَّنَا ٱغۡفِرۡ لَنَا ذُنُوبَنَا وَإِسۡرَافَنَا فِيٓ أَمۡرِنَا وَثَبِّتۡ أَقۡدَامَنَا وَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbanagh fir lanaa zunoobanaa wa israafanaa feee amrinaa wa sabbit aqdaamanaa wansurnaa 'alal qawmil kaafireen", translation: "Our Lord, forgive us our sins and the excess committed in our affairs, plant firmly our feet, and give us victory over the disbelieving people.", reference: "3:147"),
            DuaItem(arabicText: "رَبَّنَا مَا خَلَقۡتَ هَٰذَا بَٰطِلٗا سُبۡحَٰنَكَ فَقِنَا عَذَابَ ٱلنَّارِ", transliteration: "Rabbanaa maa khalaqta haaza baatilan Subhaanaka faqinaa 'azaaban Naar", translation: "Our Lord, You did not create this aimlessly; exalted are You, so protect us from the punishment of the Fire.", reference: "3:191"),
            DuaItem(arabicText: "رَبَّنَآ إِنَّكَ مَن تُدۡخِلِ ٱلنَّارَ فَقَدۡ أَخۡزَيۡتَهُۥۖ وَمَا لِلظَّٰلِمِينَ مِنۡ أَنصَارٖ", transliteration: "Rabbanaaa innaka man tudkhilin Naara faqad akhzai tahoo wa maa lizzaalimeena min ansaar", translation: "Our Lord, indeed whoever You admit to the Fire, You have disgraced him, and for the wrongdoers there are no helpers.", reference: "3:192"),
            DuaItem(arabicText: "رَّبَّنَآ إِنَّنَا سَمِعۡنَا مُنَادِيٗا يُنَادِي لِلۡإِيمَٰنِ أَنۡ ءَامِنُواْ بِرَبِّكُمۡ فَـَٔامَنَّاۚ", transliteration: "Rabbanaaa innanaa sami'naa munaadiyai yunaadee lil eemaani an aaminoo bi Rabbikum fa aamannaa", translation: "Our Lord, indeed we heard a caller calling to faith, saying, Believe in your Lord, and we have believed.", reference: "3:193"),
            DuaItem(arabicText: "رَبَّنَا فَٱغۡفِرۡ لَنَا ذُنُوبَنَا وَكَفِّرۡ عَنَّا سَيِّـَٔاتِنَا وَتَوَفَّنَا مَعَ ٱلۡأَبۡرَارِ", transliteration: "Rabbanaa faghfir lanaa zunoobanaa wa kaffir 'annaa saiyi aatina wa tawaffanaa ma'al abraar", translation: "Our Lord, forgive us our sins, remove from us our misdeeds, and cause us to die among the righteous.", reference: "3:193"),
            DuaItem(arabicText: "رَبَّنَا وَءَاتِنَا مَا وَعَدتَّنَا عَلَىٰ رُسُلِكَ وَلَا تُخۡزِنَا يَوۡمَ ٱلۡقِيَٰمَةِۖ إِنَّكَ لَا تُخۡلِفُ ٱلۡمِيعَادَ", transliteration: "Rabbanaa wa aatinaa maa wa'attanaa 'alaa Rusulika wa laa tukhzinaa Yawmal Qiyaamah; innaka laa tukhliful mee'aad", translation: "Our Lord, grant us what You promised through Your messengers and do not disgrace us on the Day of Resurrection. Indeed, You do not fail in promise.", reference: "3:194"),
            DuaItem(arabicText: "رَبَّنَآ ءَامَنَّا فَٱكۡتُبۡنَا مَعَ ٱلشَّٰهِدِينَ", transliteration: "Rabbanaaa aamannaa faktubnaa ma'ash shaahideen", translation: "Our Lord, we have believed, so register us among the witnesses.", reference: "5:83"),
            DuaItem(arabicText: "ٱللَّهُمَّ رَبَّنَآ أَنزِلۡ عَلَيۡنَا مَآئِدَةٗ مِّنَ ٱلسَّمَآءِ تَكُونُ لَنَا عِيدٗا لِّأَوَّلِنَا وَءَاخِرِنَا وَءَايَةٗ مِّنكَۖ وَٱرۡزُقۡنَا وَأَنتَ خَيۡرُ ٱلرَّٰزِقِينَ", transliteration: "Rabbanaaa anzil 'alainaa maaa'idatam minas samaaa'i takoonu lanaa 'eedal li awwalinaa wa aakhirinaa wa Aayatam minka warzuqnaa wa Anta khairur raaziqeen", translation: "O Allah, our Lord, send down to us a table from heaven to be a festival and a sign from You. Provide for us, and You are the best of providers.", reference: "5:114"),
            DuaItem(arabicText: "رَبَّنَا ظَلَمۡنَآ أَنفُسَنَا وَإِن لَّمۡ تَغۡفِرۡ لَنَا وَتَرۡحَمۡنَا لَنَكُونَنَّ مِنَ ٱلۡخَٰسِرِينَ", transliteration: "Rabbanaa zalamnaaa anfusanaa wa illam taghfir lanaa wa tarhamnaa lanakoonanna minal khaasireen", translation: "Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.", reference: "7:23"),
            DuaItem(arabicText: "رَبَّنَا لَا تَجۡعَلۡنَا مَعَ ٱلۡقَوۡمِ ٱلظَّٰلِمِينَ", transliteration: "Rabbanaa laa taj'alnaa ma'al qawmiz zaalimeen", translation: "Our Lord, do not place us with the wrongdoing people.", reference: "7:47"),
            DuaItem(arabicText: "رَبَّنَا ٱفۡتَحۡ بَيۡنَنَا وَبَيۡنَ قَوۡمِنَا بِٱلۡحَقِّ وَأَنتَ خَيۡرُ ٱلۡفَٰتِحِينَ", transliteration: "Rabbanaf-tah bainana wa baina qawmina bil haqqi wa anta Khairul Fatiheen", translation: "Our Lord, decide between us and our people in truth, and You are the best of those who give decision.", reference: "7:89"),
            DuaItem(arabicText: "رَبَّنَآ أَفۡرِغۡ عَلَيۡنَا صَبۡرٗا وَتَوَفَّنَا مُسۡلِمِينَ", transliteration: "Rabbanaaa afrigh 'alainaa sabranw wa tawaffanaa muslimeen", translation: "Our Lord, pour upon us patience and let us die as Muslims in submission to You.", reference: "7:126"),
            DuaItem(arabicText: "رَبَّنَا لَا تَجۡعَلۡنَا فِتۡنَةٗ لِّلۡقَوۡمِ ٱلظَّٰلِمِينَ وَنَجِّنَا بِرَحۡمَتِكَ مِنَ ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbana la taj'alna fitnatal lil-qawmidh-Dhalimeen; wa najjina bi-Rahmatika minal qawmil kafireen", translation: "Our Lord, make us not objects of trial for the wrongdoing people, and save us by Your mercy from the disbelieving people.", reference: "10:85-86"),
            DuaItem(arabicText: "رَبَّنَآ إِنَّكَ تَعۡلَمُ مَا نُخۡفِي وَمَا نُعۡلِنُۗ وَمَا يَخۡفَىٰ عَلَى ٱللَّهِ مِن شَيۡءٖ فِي ٱلۡأَرۡضِ وَلَا فِي ٱلسَّمَآءِ", transliteration: "Rabbanaaa innaka ta'lamu maa nukhfee wa maa nu'lin; wa maa yakhfaa 'alal laahi min shai'in fil ardi wa laa fis samaaa", translation: "Our Lord, indeed You know what we conceal and what we declare, and nothing is hidden from Allah on the earth or in the heaven.", reference: "14:38"),
            DuaItem(arabicText: "رَبِّ ٱجۡعَلۡنِي مُقِيمَ ٱلصَّلَوٰةِ وَمِن ذُرِّيَّتِيۚ رَبَّنَا وَتَقَبَّلۡ دُعَآءِ", transliteration: "Rabbij 'alnee muqeemas Salaati wa min zurriyyatee Rabbanaa wa taqabbal du'aaa", translation: "My Lord, make me an establisher of prayer, and many from my descendants. Our Lord, accept my supplication.", reference: "14:40"),
            DuaItem(arabicText: "رَبَّنَا ٱغۡفِرۡ لِي وَلِوَٰلِدَيَّ وَلِلۡمُؤۡمِنِينَ يَوۡمَ يَقُومُ ٱلۡحِسَابُ", transliteration: "Rabbanagh fir lee wa liwaalidaiya wa lilmu'mineena Yawma yaqoomul hisaab", translation: "Our Lord, forgive me and my parents and the believers the Day the account is established.", reference: "14:41"),
            DuaItem(arabicText: "رَبَّنَآ ءَاتِنَا مِن لَّدُنكَ رَحۡمَةٗ وَهَيِّئۡ لَنَا مِنۡ أَمۡرِنَا رَشَدٗا", transliteration: "Rabbanaaa aatinaa mil ladunka rahmatanw wa haiyi' lanaa min amrinaa rashadaa", translation: "Our Lord, grant us mercy from Yourself and prepare for us right guidance in our affair.", reference: "18:10"),
            DuaItem(arabicText: "رَبَّنَآ إِنَّنَا نَخَافُ أَن يَفۡرُطَ عَلَيۡنَآ أَوۡ أَن يَطۡغَىٰ", transliteration: "Rabbanaaa innanaa nakhaafu ai yafruta 'alainaaa aw ai yatghaa", translation: "Our Lord, indeed we are afraid that he will hasten punishment against us or that he will transgress.", reference: "20:45"),
            DuaItem(arabicText: "رَبَّنَآ ءَامَنَّا فَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَا وَأَنتَ خَيۡرُ ٱلرَّٰحِمِينَ", transliteration: "Rabbanaaa aamannaa faghfir lanaa warhamnaa wa Anta khairur raahimeen", translation: "Our Lord, we have believed, so forgive us and have mercy upon us, and You are the best of the merciful.", reference: "23:109"),
            DuaItem(arabicText: "رَبَّنَا ٱصۡرِفۡ عَنَّا عَذَابَ جَهَنَّمَۖ إِنَّ عَذَابَهَا كَانَ غَرَامًا إِنَّهَا سَآءَتۡ مُسۡتَقَرّٗا وَمُقَامٗا", transliteration: "Rabbanas rif 'annnaa 'azaaba Jahannama inn 'azaabahaa kaana gharaamaa; innahaa saaa'at mustaqarranw wa muqaamaa", translation: "Our Lord, avert from us the punishment of Hell. Indeed, its punishment is ever adhering; indeed, it is evil as a settlement and residence.", reference: "25:65-66"),
            DuaItem(arabicText: "رَبَّنَا هَبۡ لَنَا مِنۡ أَزۡوَٰجِنَا وَذُرِّيَّٰتِنَا قُرَّةَ أَعۡيُنٖ وَٱجۡعَلۡنَا لِلۡمُتَّقِينَ إِمَامًا", transliteration: "Rabbanaa hab lanaa min azwaajinaa wa zurriyaatinaa qurrata a'yuninw waj'alnaa lilmuttaqeena Imaamaa", translation: "Our Lord, grant us from among our spouses and offspring comfort to our eyes and make us an example for the righteous.", reference: "25:74"),
            DuaItem(arabicText: "ٱلۡحَمۡدُ لِلَّهِ ٱلَّذِيٓ أَذۡهَبَ عَنَّا ٱلۡحَزَنَۖ إِنَّ رَبَّنَا لَغَفُورٞ شَكُورٌ", transliteration: "Inna Rabbanaa la-Ghafoorun Shakoor", translation: "Indeed, our Lord is Forgiving and Appreciative.", reference: "35:34"),
            DuaItem(arabicText: "رَبَّنَا وَسِعۡتَ كُلَّ شَيۡءٖ رَّحۡمَةٗ وَعِلۡمٗا فَٱغۡفِرۡ لِلَّذِينَ تَابُواْ وَٱتَّبَعُواْ سَبِيلَكَ وَقِهِمۡ عَذَابَ ٱلۡجَحِيمِ", transliteration: "Rabbanaa wasi'ta kulla shai'ir rahmatanw wa 'ilman faghfir lillazeena taaboo wattaba'oo sabeelaka wa qihim 'azaabal Jaheem", translation: "Our Lord, You have encompassed all things in mercy and knowledge, so forgive those who repent and follow Your way, and protect them from the punishment of Hellfire.", reference: "40:7"),
            DuaItem(arabicText: "رَبَّنَا وَأَدۡخِلۡهُمۡ جَنَّٰتِ عَدۡنٍ ٱلَّتِي وَعَدتَّهُمۡ وَمَن صَلَحَ مِنۡ ءَابَآئِهِمۡ وَأَزۡوَٰجِهِمۡ وَذُرِّيَّٰتِهِمۡۚ إِنَّكَ أَنتَ ٱلۡعَزِيزُ ٱلۡحَكِيمُ وَقِهِمُ ٱلسَّيِّـَٔاتِۚ", transliteration: "Rabbana wa adhkhilhum Jannati 'adninil-lati wa'attahum wa man salaha min aba'ihim wa azwajihim wa dhuriyyatihim innaka antal 'Azizul-Hakim, waqihimus saiyi'at", translation: "Our Lord, admit them to gardens of perpetual residence which You promised them, and whoever was righteous among their forefathers, spouses, and offspring. Indeed, You are the Exalted in Might, the Wise. Protect them from evil consequences.", reference: "40:8-9"),
            DuaItem(arabicText: "رَبَّنَا ٱغۡفِرۡ لَنَا وَلِإِخۡوَٰنِنَا ٱلَّذِينَ سَبَقُونَا بِٱلۡإِيمَٰنِ وَلَا تَجۡعَلۡ فِي قُلُوبِنَا غِلّٗا لِّلَّذِينَ ءَامَنُواْ", transliteration: "Rabbanagh fir lanaa wa li ikhwaani nal lazeena sabqoonaa bil eemaani wa laa taj'al fee quloobinaa ghillalil lazeena aamanoo", translation: "Our Lord, forgive us and our brothers who preceded us in faith, and put not in our hearts resentment toward those who have believed.", reference: "59:10"),
            DuaItem(arabicText: "رَبَّنَآ إِنَّكَ رَءُوفٞ رَّحِيمٌ", transliteration: "Rabbannaaa innaka Ra'oofur Raheem", translation: "Our Lord, indeed You are Kind and Merciful.", reference: "59:10"),
            DuaItem(arabicText: "رَّبَّنَا عَلَيۡكَ تَوَكَّلۡنَا وَإِلَيۡكَ أَنَبۡنَا وَإِلَيۡكَ ٱلۡمَصِيرُ", transliteration: "Rabbanaa 'alaika tawakkalnaa wa ilaika anabnaa wa ilaikal maseer", translation: "Our Lord, upon You we have relied, to You we have returned, and to You is the destination.", reference: "60:4"),
            DuaItem(arabicText: "رَبَّنَا لَا تَجۡعَلۡنَا فِتۡنَةٗ لِّلَّذِينَ كَفَرُواْ وَٱغۡفِرۡ لَنَا رَبَّنَآۖ إِنَّكَ أَنتَ ٱلۡعَزِيزُ ٱلۡحَكِيمُ", transliteration: "Rabbana laa taj'alnaa fitnatal lillazeena kafaroo waghfir lanaa rabbanaaa innaka antal azeezul hakeem", translation: "Our Lord, make us not objects of trial for those who disbelieve and forgive us, our Lord. Indeed, You are the Exalted in Might, the Wise.", reference: "60:5"),
            DuaItem(arabicText: "رَبَّنَآ أَتۡمِمۡ لَنَا نُورَنَا وَٱغۡفِرۡ لَنَآۖ إِنَّكَ عَلَىٰ كُلِّ شَيۡءٖ قَدِيرٞ", transliteration: "Rabbanaaa atmim lanaa nooranaa waghfir lana innaka 'alaa kulli shai'in qadeer", translation: "Our Lord, perfect for us our light and forgive us. Indeed, You are over all things competent.", reference: "66:8")
        ]
    )
}

private struct DuaReflectionCard: View {
    let title: String
    let lines: [String]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(accent)

            ForEach(lines, id: \.self) { line in
                Text("• \(line)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(-4)
    }
}

#Preview {
    AlIslamPreviewContainer {
        DuaView()
    }
}
