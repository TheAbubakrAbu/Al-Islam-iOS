import SwiftUI

struct ArabicView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @AppStorage("arabicFilterMode") private var filterModeRaw: String = ArabicFilterMode.normal.rawValue
    /// List of rows, or a grid of tiles - the same choice the 99 Names screen offers. Watch is always a list.

    private enum ArabicFilterMode: String, CaseIterable, Identifiable {
        case normal
        case similarity
        case heavyLight

        var id: String { rawValue }

        var title: String {
            switch self {
            case .normal: return "Normal Grouping"
            case .similarity: return "Similar Letters"
            case .heavyLight: return "Heavy vs Light"
            }
        }

        var icon: String {
            switch self {
            case .normal: return "square.grid.2x2"
            case .similarity: return "square.grid.3x3"
            case .heavyLight: return "circle.lefthalf.filled"
            }
        }
    }

    private var filterMode: ArabicFilterMode {
        get { ArabicFilterMode(rawValue: filterModeRaw) ?? .normal }
        set { filterModeRaw = newValue.rawValue }
    }

    private let similarityGroups: [[String]] = [
        ["ا", "و", "ي"], ["ب", "ت", "ث"], ["ج", "ح", "خ"], ["د", "ذ"],
        ["ر", "ز"], ["س", "ش"], ["ص", "ض"], ["ط", "ظ"], ["ع", "غ"],
        ["ف", "ق"], ["ك", "ل"], ["م", "ن"], ["ه", "ة"]
    ]

    /// What the letters in a similarity group have in COMMON - the shared skeleton, with the dots stripped off.
    /// The letters themselves are right there in the section, so listing them again in the header ("ب - ت - ث")
    /// said nothing; the dotless form is the actual point of the grouping. Where the letters don't merely differ
    /// by dots (kaaf/laam, meem/nuun), there's no shared skeleton to show, so the group falls back to naming them.
    private static let dotlessSkeletons: [String: String] = [
        "بتث": "\u{066E}",   // dotless beh
        "جحخ": "ح",          // the letters are haa + a dot above / below
        "دذ": "د",
        "رز": "ر",
        "سش": "س",
        "صض": "ص",
        "طظ": "ط",
        "عغ": "ع",
        "فق": "\u{066F}",    // dotless qaf
        "هة": "ه",           // taa marbuutah is a haa with two dots
    ]

    private static func similarityHeader(for group: [String]) -> String {
        dotlessSkeletons[group.joined()] ?? group.joined(separator: " - ")
    }

    private var filteredStandard: [LetterData] {
        guard !searchText.isEmpty else { return standardArabicLetters }
        let st = searchText.lowercased()
        return standardArabicLetters.filter { matchesSearch($0, st) }
    }

    private var filteredOther: [LetterData] {
        let allOtherLetters = otherArabicLetters + nonArabicArabicScriptLetters
        guard !searchText.isEmpty else { return allOtherLetters }
        let st = searchText.lowercased()
        return allOtherLetters.filter {
            $0.letter.lowercased().contains(st)
                || $0.name.lowercased().contains(st)
                || $0.transliteration.lowercased().contains(st)
        }
    }

    private func matchesSearch(_ letter: LetterData, _ st: String) -> Bool {
        var parts: [String] = [
            letter.letter.lowercased(),
            letter.name.lowercased(),
            letter.transliteration.lowercased()
        ]

        if let weight = letter.weight {
            switch weight {
            case .followsPrevious:
                parts += ["follows previous", "follows", "previous"]
            case .conditional:
                parts += ["conditional"]
            case .heavy:
                parts += ["heavy", "tafkhim", "istila", "isti'la"]
            case .light:
                parts += ["light", "tarqiq"]
            }
        }

        if let rule = letter.weightRule?.lowercased() {
            parts.append(rule)
        }

        return parts.contains { $0.contains(st) }
    }

    private var filteredStandardForMode: [LetterData] {
        switch filterMode {
        case .normal, .similarity:
            return filteredStandard
        case .heavyLight:
            return filteredStandard.filter { $0.weight != nil }
        }
    }

    #if os(iOS)
    // AI (semantic) letter search - the hadith book search's exact grammar, over the alphabet:
    // on-device meaning matching over each letter's English facts (name, sound, weight rule),
    // shown automatically above the keyword matches. No mode to enter; the section appears (with
    // one-time build progress the first time) whenever it can help.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var aiHits: [LetterData] = []
    @State private var aiSearchTask: Task<Void, Never>?

    private static let semanticCorpusID = "letters-en"
    /// Every letter the keyword search covers, in one stable order - the corpus rows.
    private static let semanticCorpusItems: [LetterData] =
        standardArabicLetters + otherArabicLetters + nonArabicArabicScriptLetters

    /// One English sentence per letter - the corpus text AND the Ask passage (letters carry no
    /// long-form description, so the searchable facts are the name, sound, and weight rule).
    private static func letterEnglishText(_ letter: LetterData) -> String {
        var parts = ["The Arabic letter \(letter.transliteration), pronounced with the sound \"\(letter.sound)\"."]
        switch letter.weight {
        case .heavy: parts.append("A heavy (tafkhim, isti'la) letter.")
        case .light: parts.append("A light (tarqiq) letter.")
        case .conditional: parts.append("Its weight is conditional.")
        case .followsPrevious: parts.append("It follows the previous letter's weight.")
        case nil: break
        }
        if let rule = letter.weightRule { parts.append(rule) }
        return parts.joined(separator: " ")
    }

    /// True when the live query is one the semantic engine can answer (English text, long enough).
    private var aiQueryEligible: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return SemanticSearchEngine.isSupported
            && trimmed.count >= 3
            && !trimmed.containsArabicScript
    }

    private func prepareSemanticCorpus() {
        guard SemanticSearchEngine.isSupported, !semanticEngine.isReady(Self.semanticCorpusID) else { return }
        let texts = Self.semanticCorpusItems.map { Self.letterEnglishText($0) }
        // Keyed by the letter's id, so index -> letter resolution survives any reorder of the source.
        let keys = Self.semanticCorpusItems.map { String($0.id) }
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
            // Resolve through the corpus KEYS (the letter's id), falling back to position only for
            // a corpus persisted before keys existed.
            let keys = await MainActor.run { semanticEngine.corpus(Self.semanticCorpusID)?.itemKeys }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                // Plain apply: an animated section insert racing another async apply is the
                // collection-view assertion crash the Quran search hit.
                aiHits = results.compactMap { result in
                    if let keys, keys.indices.contains(result.index), let id = Int(keys[result.index]) {
                        return Self.semanticCorpusItems.first(where: { $0.id == id })
                    }
                    return Self.semanticCorpusItems.indices.contains(result.index) ? Self.semanticCorpusItems[result.index] : nil
                }
            }
        }
    }

    // Ask (the on-device LLM, grounded RAG): question-shaped queries stream an answer card above
    // the matches, drawn strictly from the retrieved letters - the hadith book search's exact feature.
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
            for letter in aiHits.prefix(6) where seen.insert(letter.id).inserted {
                sources.append(.init(reference: letter.transliteration, text: Self.letterEnglishText(letter)))
            }
            for letter in (filteredStandardForMode + filteredOther).prefix(6) where seen.insert(letter.id).inserted {
                sources.append(.init(reference: letter.transliteration, text: Self.letterEnglishText(letter)))
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
    private var aiMatchesSection: some View {
        if aiQueryEligible {
            if semanticEngine.isReady(Self.semanticCorpusID) {
                if !aiHits.isEmpty {
                    Section(header: SectionPillHeader(title: "AI MATCHES", count: aiHits.count, icon: "sparkles", accentTitle: true)) {
                        letterCollection(aiHits)
                    }
                }
            } else if !semanticEngine.failedCorpora.contains(Self.semanticCorpusID) {
                Section { AISearchStatusRow(progress: semanticEngine.progress(Self.semanticCorpusID), failed: false) }
            }
        }
    }
    #endif

    var body: some View {
        // Both result kinds landed: ONE segmented switch decides which list fills the page (the
        // hadith book search's rule). With only one kind present, no picker - it just shows.
        #if os(iOS)
        let keywordResults = searchText.isEmpty ? [] : filteredStandardForMode + filteredOther
        let showResultsPicker = !searchText.isEmpty && !aiHits.isEmpty && !keywordResults.isEmpty
        let keywordVisible = !showResultsPicker || showKeywordResults
        #else
        let keywordVisible = true
        #endif

        return List {
            Group {
                #if os(watchOS)
                arabicFontPickerSection
                #endif
                favoriteLettersSection
                #if os(iOS)
                if !searchText.isEmpty {
                    askAISection(hasResults: !aiHits.isEmpty || !keywordResults.isEmpty)
                    if showResultsPicker { resultsPickerSection }
                    // AI matches appear AUTOMATICALLY above the keyword results - no mode to enter.
                    if !showResultsPicker || !showKeywordResults { aiMatchesSection }
                }
                #endif
                mainLetterSections
                if keywordVisible {
                    searchResultsSection
                }
            }
            .themedListRowBackground()
        }
        #if os(watchOS)
        .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #else
        .background(gridNavigationLink)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                // No size slider here. It lives on the per-letter detail screen (`ArabicLetterView`), which is
                // where you are actually looking at a letter big enough to want it resized. The size it sets is
                // global (`settings.arabicLetterSizeIndex`), and these rows and tiles already honour it through
                // `arabicLetterDynamicTypeSize`, so the alphabet list still resizes - it just doesn't carry the
                // control, which was crowding the bottom bar alongside the font picker and the search field.
                // The one Islam-tab Arabic face picker, back above the search bar - the same control, on the
                // same setting, that Duas, Dhikr, the 99 Names and the letter detail screens carry. It does
                // NOT fold away on scroll (`collapsibleBarRow` stays off, as on Duas and Dhikr): that was
                // what made it look like a row vanishing mid-scroll. It just rides with the bar.
                arabicFontPicker

                HStack(spacing: 0) {
                    SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))

                    Menu {
                        Text("Arabic Sort")
                            .foregroundStyle(.secondary)

                        ForEach(ArabicFilterMode.allCases) { mode in
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    filterModeRaw = mode.rawValue
                                }
                            } label: {
                                Label(
                                    mode.title,
                                    systemImage: mode == filterMode ? "checkmark" : mode.icon
                                )
                            }
                        }

                        Divider()

                        Text("Display")
                            .foregroundStyle(.secondary)

                        // Lets the marks be practised from the Arabic alone, without reading the answer off the
                        // transliteration underneath.
                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) {
                                settings.hideEnglishInArabicLetters.toggle()
                            }
                        } label: {
                            Label(
                                settings.hideEnglishInArabicLetters ? "Show English" : "Hide English",
                                systemImage: settings.hideEnglishInArabicLetters ? "eye" : "eye.slash"
                            )
                        }
                    } label: {
                        adaptiveMenuButtonLabel {
                            Image(systemName: filterMode.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(settings.accentColor.color)
                                .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 2)
                }
                .padding([.leading, .top], -8)
                .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #endif
        .applyConditionalListStyle()
        .navigationTitle("Arabic Alphabet")
        .onDisappear { ArabicSpeech.shared.stop() }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // The one app-wide grid toggle - flipping it here flips Quran, Names, and Islam too.
                Button {
                    settings.hapticFeedback()
                    withAnimation { settings.arabicGridMode.toggle() }
                } label: {
                    Image(systemName: isGridMode ? "list.bullet" : "square.grid.2x2")
                }
                .accessibilityLabel(isGridMode ? "Show list" : "Show grid")
                .tint(settings.accentColor.accent2)
            }
        }
        #endif
    }

    private func adaptiveMenuButtonLabel<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(width: 27, height: 27)
            .padding()
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .conditionalGlassEffect()
    }

    /// A letter section with the shared counted header. `shuffle` adds the random button (iOS only -
    /// it pushes through the grid's hidden navigation link, which the watch list doesn't have).
    @ViewBuilder
    private func countedLetterSection(_ title: String, _ letters: [LetterData], shuffle: Bool = false) -> some View {
        #if os(iOS)
        Section(header: SectionPillHeader(
            title: title,
            count: letters.count,
            onShuffle: shuffle ? { if let letter = letters.randomElement() { gridSelection = letter } } : nil
        )) {
            letterCollection(letters)
        }
        #else
        Section(header: SectionPillHeader(title: title, count: letters.count)) {
            letterCollection(letters)
        }
        #endif
    }

    @ViewBuilder
    private var favoriteLettersSection: some View {
        if searchText.isEmpty, !settings.favoriteLetters.isEmpty {
            let favorites = settings.favoriteLetters.sorted()
            #if os(iOS)
            Section(header: SectionPillHeader(
                title: "FAVORITES",
                count: favorites.count,
                icon: "star.fill",
                accentTitle: true,
                isExpanded: $showFavoriteLetters,
                onShuffle: { if let letter = favorites.randomElement() { gridSelection = letter } }
            )) {
                if showFavoriteLetters {
                    letterCollection(favorites)
                }
            }
            #else
            Section(header: SectionPillHeader(title: "FAVORITES", count: favorites.count)) {
                letterCollection(favorites)
            }
            #endif
        }
    }

    @ViewBuilder
    private var arabicFontPickerSection: some View {
        Section {
            arabicFontPicker
        } header: {
            Text("ARABIC FONT")
        }
    }

    @ViewBuilder
    private var arabicFontPicker: some View {
        #if os(watchOS)
        // The watch keeps the simple two-way choice; the richer three-way face picker is a phone thing.
        Picker("Arabic Font", selection: $settings.useFontArabic.animation(.easeInOut)) {
            Text("Quranic Font").tag(true)
            Text("Basic Font").tag(false)
        }
        .conditionalGlassEffect(interactive: false)
        .onChange(of: settings.useFontArabic) { _ in settings.hapticFeedback() }
        #else
        IslamArabicFontPicker()
            // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26 hardware.
            .conditionalGlassEffect(interactive: false)
        #endif
    }

    private var isGridMode: Bool {
        #if os(iOS)
        return settings.arabicGridMode
        #else
        return false
        #endif
    }

    #if os(iOS)
    /// The letter a grid tile asked to open. Every grid section shares the one link below, so exactly one
    /// letter is ever pushed.
    @State private var gridSelection: LetterData?

    /// Collapse state for the favorites section, same as the Quran tab's Favorite Surahs.
    @AppStorage("showFavoriteLetters") private var showFavoriteLetters = true

    @ViewBuilder
    private var gridNavigationLink: some View {
        NavigationLink(
            isActive: Binding(
                get: { gridSelection != nil },
                set: { if !$0 { gridSelection = nil } }
            )
        ) {
            if let gridSelection {
                ArabicLetterView(letterData: gridSelection)
            }
        } label: {
            EmptyView()
        }
        .opacity(0)
    }
    #endif

    /// Every letter section renders through here, so list and grid can never fall out of sync on *which*
    /// letters a section contains - only on how they're drawn.
    @ViewBuilder
    private func letterCollection(_ letters: [LetterData]) -> some View {
        #if os(iOS)
        if isGridMode {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(letters) { letter in
                    ArabicLetterGridTile(
                        letterData: letter,
                        isFavorite: settings.isLetterFavorite(letterData: letter),
                        accentColor: settings.accentColor,
                        useFontArabic: settings.useFontArabic,
                        fontArabic: settings.nonQuranArabicFontName,
                        onTap: { gridSelection = letter }
                    )
                    .equatable()
                }
            }
            .padding(.horizontal, -8)
            .padding(.vertical, 2)
        } else {
            ForEach(letters) { letterRow(for: $0) }
        }
        #else
        ForEach(letters) { letterRow(for: $0) }
        #endif
    }

    /// The numbers follow the letters' display mode, so the screen is either all rows or all tiles.
    @ViewBuilder
    private var numberCollection: some View {
        #if os(iOS)
        if isGridMode {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(numbers, id: \.number) { ArabicNumberGridTile(numberData: $0) }
            }
            .padding(.horizontal, -8)
            .padding(.vertical, 2)
        } else {
            ForEach(numbers, id: \.number) { ArabicNumberRow(numberData: $0) }
        }
        #else
        ForEach(numbers, id: \.number) { ArabicNumberRow(numberData: $0) }
        #endif
    }

    private func letterRow(for letterData: LetterData) -> some View {
        ArabicLetterRow(
            letterData: letterData,
            isFavorite: settings.isLetterFavorite(letterData: letterData),
            accentColor: settings.accentColor,
            useFontArabic: settings.useFontArabic,
            fontArabic: settings.nonQuranArabicFontName,
            searchQuery: searchText
        )
        .equatable()
    }

    @ViewBuilder
    private var mainLetterSections: some View {
        if searchText.isEmpty {
            standardLetterSections

            Section("TASHKEEL") {
                NavigationLink {
                    TashkeelLettersView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Letters with Tashkeel")
                                .foregroundColor(.primary)

                            Text("Every letter carrying one harakah at a time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Text("\u{0640}\u{064E}")
                            .foregroundColor(settings.accentColor.color)
                    }
                    .padding(.vertical, 4)
                }
            }

            countedLetterSection("SPECIAL ARABIC LETTERS", otherArabicLetters)

            Section(header: SectionPillHeader(title: "ARABIC NUMBERS", count: numbers.count)) {
                numberCollection
            }

            tajweedSection

            countedLetterSection("NON-ARABIC LETTERS", nonArabicArabicScriptLetters)
        }
    }

    @ViewBuilder
    private var standardLetterSections: some View {
        switch filterMode {
        case .normal:
            countedLetterSection("STANDARD ARABIC LETTERS", standardArabicLetters, shuffle: true)
        case .similarity:
            ForEach(similarityGroups.indices, id: \.self) { idx in
                let group = similarityGroups[idx]
                let header = idx == 0 ? "VOWEL LETTERS" : Self.similarityHeader(for: group)
                countedLetterSection(header, group.compactMap { letterData(for: $0) })
            }
        case .heavyLight:
            countedLetterSection("FOLLOWS PREVIOUS", standardArabicLetters.filter { $0.weight == .followsPrevious })

            countedLetterSection("CONDITIONAL", standardArabicLetters.filter { $0.weight == .conditional })

            countedLetterSection("HEAVY LETTERS", standardArabicLetters.filter { $0.weight == .heavy })

            countedLetterSection("LIGHT LETTERS", (standardArabicLetters + otherArabicLetters).filter {
                $0.weight == .light
                    || $0.transliteration == "taa marbuuTah"
                    || $0.transliteration.lowercased().contains("hamza")
            })
        }
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        if !searchText.isEmpty {
            // ONE scan per pass: the rows and the count pill share the same merged result list -
            // as two separate accesses each computed property re-filtered every letter per keystroke.
            let results = filteredStandardForMode + filteredOther
            Section {
                if results.isEmpty {
                    #if os(iOS)
                    Text(aiHits.isEmpty
                         ? "No letters match your search."
                         : "No keyword matches. See the AI results above.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    #else
                    Text("No letters match your search.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    #endif
                } else {
                    letterCollection(results)
                }
            } header: {
                HStack {
                    Text("ARABIC SEARCH RESULTS")

                    Spacer()

                    CountPill(count: results.count)
                        .opacity(searchText.isEmpty ? 0 : 1)
                }
            }
        }
    }

    private func letterData(for glyph: String) -> LetterData? {
        standardArabicLetters.first { $0.letter == glyph }
            ?? otherArabicLetters.first { $0.letter == glyph }
            ?? nonArabicArabicScriptLetters.first { $0.letter == glyph }
    }

    @ViewBuilder
    private var tajweedSection: some View {
        Section("QURAN SIGNS") {
            QuranSignsSectionContent(accentColor: settings.accentColor.color)
        }
    }
}

/// Bottom size control shared by the Arabic Alphabet list and the per-letter detail. Drives
/// `settings.arabicLetterSizeIndex`, which both screens apply as a Dynamic-Type floor. Position 0 is
/// `.xSmall`, i.e. no floor at all - the alphabet then renders at whatever size the device is set to.
struct ArabicSizeSlider: View {
    @ObservedObject var settings = Settings.shared

    private var maxIndex: Int { Settings.arabicLetterDynamicTypeSizes.count - 1 }

    private var indexBinding: Binding<Double> {
        Binding(
            get: { Double(min(max(settings.arabicLetterSizeIndex, 0), maxIndex)) },
            set: { settings.arabicLetterSizeIndex = min(max(Int($0.rounded()), 0), maxIndex) }
        )
    }

    private func step(by delta: Int) {
        let next = min(max(settings.arabicLetterSizeIndex + delta, 0), maxIndex)
        guard next != settings.arabicLetterSizeIndex else { return }
        settings.hapticFeedback()
        settings.arabicLetterSizeIndex = next
    }

    var body: some View {
        HStack(spacing: 10) {
            sizeStepButton(systemImage: "textformat.size.smaller", delta: -1, enabled: settings.arabicLetterSizeIndex > 0)

            Slider(value: indexBinding, in: 0...Double(maxIndex), step: 1) { editing in
                if !editing { settings.hapticFeedback() }
            }
            .tint(settings.accentColor.color)

            sizeStepButton(systemImage: "textformat.size.larger", delta: 1, enabled: settings.arabicLetterSizeIndex < maxIndex)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .conditionalGlassEffect()
        // Keep the control itself a stable size regardless of the floor it sets for the content.
        .dynamicTypeSize(.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Letter size")
    }

    private func sizeStepButton(systemImage: String, delta: Int, enabled: Bool) -> some View {
        Button {
            step(by: delta)
        } label: {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(enabled ? settings.accentColor.color : Color.secondary)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// The alphabet seen through one harakah at a time - the transpose of the per-letter detail, which shows one
/// letter carrying every harakah. Pick a mark and all 28 letters (plus the hamza) are rendered with it.
///
/// Shaddah is the exception: on its own it only says "double this letter", and in real words it always carries
/// a vowel with it, so selecting it reveals the four readings (bare, then with fatha / damma / kasra) and every
/// letter becomes tappable to see its own three side by side.