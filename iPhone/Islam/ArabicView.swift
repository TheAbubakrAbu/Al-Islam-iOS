import SwiftUI

struct ArabicView: View {
    @ObservedObject private var settings = Settings.shared
    #if DEBUG
    /// `-arabicSearch <text>`: start with the search field filled, the only headless way to reach a
    /// section below the fold (the simulator cannot be scrolled from a script).
    @State private var searchText = ProcessInfo.processInfo.arguments.firstIndex(of: "-arabicSearch")
        .flatMap { ProcessInfo.processInfo.arguments.indices.contains($0 + 1) ? ProcessInfo.processInfo.arguments[$0 + 1] : nil } ?? ""
    #else
    @State private var searchText = ""
    #endif
    #if os(iOS)
    /// The "About" card's single open door (one @State + one destination on the List:
    /// every chip lives in the SAME List row, and two links in one row both fire).
    @State private var aboutDoor: SignsAboutDoor?
    #endif
    /// The letter a result asked to scroll to ("Scroll To Letter"), consumed once the search clears.
    @State private var scrollTarget: String?
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @AppStorage("arabicFilterMode") private var filterModeRaw: String = "normal"
    /// The ONE family the active grouping is narrowed to (a chip in the banner), nil for all of them.
    /// Not stored: it belongs to the grouping it was picked under, and resets with it.
    @State private var focusedFamilyID: String?
    /// Where a tile or chip on this screen leads: the Explore row, the banner's About link, a family
    /// header's info button. One state and one destination, because they share List rows.
    @State private var door: ArabicDoor?

    /// How the 28 letters are laid out: in order, by shared shape, or by one of the tajweed axes
    /// (`LetterAxis`: where letters are made, how they sound, what they do to their neighbours).
    ///
    /// Stored as a string. "normal", "similarity" and "heavyLight" are the three raw values this
    /// screen has always written, so an existing choice survives; an axis stores its own raw value.
    private enum Grouping: Equatable {
        case alphabetical
        case shape
        case axis(LetterAxis)

        init(raw: String) {
            switch raw {
            case "similarity": self = .shape
            case "heavyLight": self = .axis(.weight)
            default: self = LetterAxis(rawValue: raw).map(Grouping.axis) ?? .alphabetical
            }
        }

        var raw: String {
            switch self {
            case .alphabetical: return "normal"
            case .shape: return "similarity"
            case .axis(let axis): return axis.rawValue
            }
        }

        var title: String {
            switch self {
            case .alphabetical: return "Alphabetical Order"
            case .shape: return "Similar Shapes"
            case .axis(let axis): return axis.title
            }
        }

        var icon: String {
            switch self {
            case .alphabetical: return "square.grid.2x2"
            case .shape: return "square.grid.3x3"
            case .axis(let axis): return axis.systemImage
            }
        }

        var axis: LetterAxis? {
            if case .axis(let axis) = self { return axis }
            return nil
        }
    }

    private var grouping: Grouping { Grouping(raw: filterModeRaw) }

    private func setGrouping(_ option: Grouping) {
        settings.hapticFeedback()
        withAnimation(.easeInOut) {
            filterModeRaw = option.raw
            focusedFamilyID = nil
        }
        if let axis = option.axis { remember(axis) }
    }

    /// The axes a shelf's chips offer. Heavy or Light is the exception: it is one of the rules, but
    /// it was a grouping of its own before the shelves existed and keeps its own menu button
    /// (Abu, 2026-09-22: "alphabetical order, similar shapes and heavy versus light"), so the Ahkaam
    /// shelf does not list it a second time.
    private static func shelfAxes(_ shelf: LetterAxis.Shelf) -> [LetterAxis] {
        shelf.axes.filter { $0 != .weight }
    }

    /// True when the active grouping is one of `shelf`'s own axes (its menu button then shows a check).
    private func isOnShelf(_ shelf: LetterAxis.Shelf) -> Bool {
        guard let axis = grouping.axis else { return false }
        return Self.shelfAxes(shelf).contains(axis)
    }

    /// The last axis chosen on each shelf, so the shelf's menu button lands where the reader left it
    /// (the shelf's first axis until then). Two shelves have more than one axis; the makharij shelf
    /// has only its own.
    @AppStorage("arabicShelfAxisQualities") private var rememberedQualitiesAxis: String = ""
    @AppStorage("arabicShelfAxisRules") private var rememberedRulesAxis: String = ""

    private func preferredAxis(of shelf: LetterAxis.Shelf) -> LetterAxis {
        let axes = Self.shelfAxes(shelf)
        let remembered: String
        switch shelf {
        case .place: remembered = ""
        case .qualities: remembered = rememberedQualitiesAxis
        case .rules: remembered = rememberedRulesAxis
        }
        if let axis = LetterAxis(rawValue: remembered), axes.contains(axis) { return axis }
        return axes.first ?? .makhraj
    }

    private func remember(_ axis: LetterAxis) {
        guard Self.shelfAxes(axis.shelf).contains(axis) else { return }
        switch axis.shelf {
        case .place: break
        case .qualities: rememberedQualitiesAxis = axis.rawValue
        case .rules: rememberedRulesAxis = axis.rawValue
        }
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

        // The alphabet spells this letter "nuun", and every tajweed page in the app calls it "noon"
        // (noon sakinah): either spelling has to find it.
        if letter.transliteration == "nuun" { parts += ["noon", "nun"] }

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

        // Every family the letter belongs to: "whistling", "safeer", "hams", "throat", "sun",
        // "ikhfaa"... so the search doubles as a filter by tajweed trait.
        parts += LetterTraits.searchTerms(for: letter.letter)

        return parts.contains { $0.contains(st) }
    }

    /// Families whose own name matches the query, offered above the letters: typing "safeer" should
    /// lead to the whistling family itself, not only to its three letters.
    private var matchingFamilies: [LetterFamily] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard query.count >= 3 else { return [] }
        return LetterTraits.allFamilies.filter { family in
            family.name.lowercased().contains(query)
                || family.meaning.lowercased().contains(query)
                || family.arabic.contains(query)
                || family.keywords.contains { $0.contains(query) }
        }
    }

    private var filteredStandardForMode: [LetterData] { filteredStandard }

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
        if let glyph = LetterTraits.profileLetter(for: letter) {
            if let zone = LetterTraits.makharij(of: glyph).last.flatMap({ LetterTraits.family(id: $0.zoneID) }) {
                parts.append("It is made at \(zone.meaning.lowercased()) (\(zone.name)).")
            }
            let qualities = LetterTraits.sifaat(of: glyph).map { "\($0.name) (\($0.meaning.lowercased()))" }
            if !qualities.isEmpty { parts.append("Its qualities: \(qualities.joined(separator: ", ")).") }
            if let rule = LetterTraits.family(of: glyph, on: .noonSakinah) {
                parts.append("After noon sakinah or tanween it causes \(rule.name) (\(rule.meaning.lowercased())).")
            }
            if let lam = LetterTraits.family(of: glyph, on: .lamOfAl) {
                parts.append("It is one of the \(lam.meaning.lowercased()).")
            }
        }
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
        semanticEngine.prepare(corpusID: Self.semanticCorpusID, version: "v2-\(texts.count)", texts: texts, keys: keys)
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

    // Ask AI: the on-device chat (`AskAIChatView`), opened from the ASK AI row above the matches
    // with the typed query as its first question - the Quran search's rule. Exists only on Apple
    // Intelligence devices (`OnDeviceAsk.isAvailable`).
    @State private var showAskAI = false
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist. Reset to the
    /// AI list on every new query.
    @State private var showKeywordResults = false

    /// "ASK AI" with the sparkles glyph, accent-tinted - the Quran search's `askAIHeader`.
    private var askAIHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("ASK AI")

            Spacer()
        }
        .foregroundStyle(settings.accentColor.color)
    }

    private var askPromptRow: some View {
        Button {
            settings.hapticFeedback()
            showAskAI = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)

                Text("Ask AI about \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                    .font(.caption.weight(.semibold))

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

    /// The ASK AI section: the one-tap row that opens the chat with the query as its first question.
    @ViewBuilder
    private func askAISection(hasResults: Bool) -> some View {
        if OnDeviceAsk.isAvailable {
            Section(header: askAIHeader) { askPromptRow }
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
                Section { AISearchStatusRow(corpusID: Self.semanticCorpusID, failed: false) }
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

        return ScrollViewReader { proxy in
        List {
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
                #if os(iOS)
                AboutSignsSection(heading: "About Arabic & the Quran",
                                  systemImage: "textformat.size.ar",
                                  doors: [.quran, .tajweed],
                                  openDoor: $aboutDoor)
                #endif
            }
            .themedListRowBackground()

        }
        #if os(watchOS)
        .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #else
        .background(gridNavigationLink)
        #if DEBUG
        // "-islamOpenLetter <letter>": push that letter's detail screen once the list is up. The grid's
        // hidden link is the only way into `ArabicLetterView` and a tile tap cannot be scripted, so
        // without this the letter page has no headless route at all - and it is where the size slider
        // and the two practice toggles live. Pair it with "-settingsProbe arabicLetterSizeIndex=6@8".
        .onAppear {
            guard let letter = Self.debugOpenLetter,
                  let match = (standardArabicLetters + otherArabicLetters + nonArabicArabicScriptLetters)
                    .first(where: { $0.letter == letter }) else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { gridSelection = match }
        }
        // "-arabicTopic tashkeel|defaultTashkeel|baaHaa|laamAlif|basics|families|soundAlikes|quiz|readingTest|family:<id>",
        // and "-arabicGrouping <axis raw value>" to land on a grouping: push one of the topic pages. Their
        // rows sit below the fold of a list that cannot be scrolled from a script.
        .background(debugTopicLink)
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            if let idx = arguments.firstIndex(of: "-arabicGrouping"), arguments.indices.contains(idx + 1) {
                filterModeRaw = arguments[idx + 1]
                if let idx = arguments.firstIndex(of: "-arabicFamily"), arguments.indices.contains(idx + 1) {
                    focusedFamilyID = arguments[idx + 1]
                }
            }
            guard Self.debugTopic != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { debugTopicOpen = true }
        }
        #endif
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                // No size slider here. It lives on the per-letter detail screen (`ArabicLetterView`), which is
                // where you are actually looking at a letter big enough to want it resized. The size it sets is
                // global (`settings.arabicLetterSizeIndex`), and these rows and tiles already honour it through
                // `arabicLetterTypeFloor(steps:)`, so the alphabet list still resizes - it just doesn't carry the
                // control, which was crowding the bottom bar alongside the font picker and the search field.
                //
                // The Arabic face picker is gone from here too (Abu, 2026-09-19): the same control on six
                // screens, all writing one `settings.islamArabicFace`, is a SETTING. It lives once now, in
                // Settings -> Islam Settings -> Arabic Text. The watch keeps its own in-list section
                // (`arabicFontPickerSection`, above) - it has no Settings page to move it to.
                HStack(spacing: 8) {
                    SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))

                    Menu {
                        groupingMenuItems
                    } label: {
                        adaptiveMenuButtonLabel {
                            Image(systemName: grouping.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(settings.accentColor.color)
                                .transition(.opacity)
                        }
                    }
                    .fixedMenuOrder()
                    .accessibilityLabel("Group the alphabet")
                }
                .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
            .background(Color.white.opacity(0.00001))
        }
        #endif
        .applyConditionalListStyle()
        .arabicDoorDestination($door)
        #if os(iOS)
        .aboutSignsDestination($aboutDoor)
        #endif
        .navigationTitle("Arabic Alphabet")
        .onDisappear {
            ArabicSpeech.shared.stop()
            ArabicPracticeSelection.shared.clear()
        }
        .onChange(of: scrollTarget) { target in
            guard let target else { return }
            // The result rows are still animating out; scroll once the alphabet is back.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { proxy.scrollTo(target, anchor: .top) }
            }
        }
        #if os(iOS)
        .onChange(of: searchText) { text in
            // A new query starts back on the AI list.
            showKeywordResults = false
            runAISearch(query: text)
        }
        .sheet(isPresented: $showAskAI) {
            if #available(iOS 16.0, *) {
                AskAIChatSheet(initialQuestion: searchText)
            }
        }
        // The one-time vector build finishing mid-query: surface the results without another keystroke.
        .onChange(of: semanticEngine.readyCorpora) { ready in
            guard ready.contains(Self.semanticCorpusID) else { return }
            runAISearch(query: searchText)
        }
        // The grid toggle, then the Islam Settings gear at the far right, in ONE toolbar (see
        // `IslamSettingsToolbar` for why this screen places the gear itself).
        .islamSettingsToolbar {
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
        #endif
        }
    }

    private func adaptiveMenuButtonLabel<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(width: 26, height: 26)
            .frame(width: 50, height: 50)
            .contentShape(Rectangle())
            .conditionalGlassEffect()
    }

    /// A letter section with the shared counted header. `shuffle` adds the random button (iOS only -
    /// it pushes through the grid's hidden navigation link, which the watch list doesn't have).
    @ViewBuilder
    private func countedLetterSection(_ title: String, _ letters: [LetterData], shuffle: Bool = false, footer: String? = nil) -> some View {
        #if os(iOS)
        Section {
            letterCollection(letters)
        } header: {
            SectionPillHeader(
                title: title,
                count: letters.count,
                onShuffle: shuffle ? { if let letter = letters.randomElement() { gridSelection = letter } } : nil
            )
        } footer: {
            if let footer { Text(footer) }
        }
        #else
        Section {
            letterCollection(letters)
        } header: {
            SectionPillHeader(title: title, count: letters.count)
        } footer: {
            if let footer { Text(footer) }
        }
        #endif
    }

    /// Which languages the six letters belong to, right under them: "non-Arabic" alone named nobody (user
    /// rule, 2026-09-15). Each letter's page says the same in full (`nonArabicLetterOrigins`).
    private static let nonArabicLettersFooter =
        "Not Arabic letters: other languages added them to the Arabic script for sounds Arabic does not have. پ, چ, گ and ژ come from Persian, Urdu, Kurdish and Pashto (p, ch, g, zh); ڤ from Kurdish and Arabic dialect writing (v); ڭ from Uyghur, Kazakh and Ottoman Turkish (ng). Open a letter for where it is used."

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
        Picker("Arabic Font", selection: $settings.useFontArabic) {
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

    #if DEBUG
    /// "-islamOpenLetter <letter>" - see the `.onAppear` that consumes it.
    private static var debugOpenLetter: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let idx = arguments.firstIndex(of: "-islamOpenLetter"), arguments.indices.contains(idx + 1) else { return nil }
        return arguments[idx + 1]
    }
    #endif

    #if DEBUG
    /// "-arabicTopic <name>" - see the `.onAppear` that consumes it.
    private static var debugTopic: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let idx = arguments.firstIndex(of: "-arabicTopic"), arguments.indices.contains(idx + 1) else { return nil }
        return arguments[idx + 1]
    }

    @State private var debugTopicOpen = false

    @ViewBuilder
    private var debugTopicLink: some View {
        NavigationLink(isActive: $debugTopicOpen) {
            switch Self.debugTopic {
            case "tashkeel": TashkeelLettersView()
            case "defaultTashkeel": DefaultTashkeelView()
            case "baaHaa": BaaHaaShapesView()
            case "laamAlif": LaamAlifShapesView()
            case "families": LetterFamiliesView()
            case "soundAlikes": SoundAlikeLettersView()
            case "quiz": LetterQuizView()
            case "readingTest": ReadingTestView()
            case let topic? where topic.hasPrefix("family:"):
                // "-arabicTopic family:safeer": one family's page.
                if let family = LetterTraits.family(id: String(topic.dropFirst("family:".count))) {
                    LetterFamilyView(family: family)
                }
            default: ArabicBasicsView()
            }
        } label: {
            EmptyView()
        }
        .opacity(0)
    }
    #endif

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
            // Negative for the same reason the horizontal inset is: the row's own vertical inset
            // is ~15pt, which put the tiles 17pt below the container's top edge against the 9pt
            // the -8 leaves at the sides. -6 squares all four up at 9pt.
            .padding(.vertical, -6)
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
            // Negative for the same reason the horizontal inset is: the row's own vertical inset
            // is ~15pt, which put the tiles 17pt below the container's top edge against the 9pt
            // the -8 leaves at the sides. -6 squares all four up at 9pt.
            .padding(.vertical, -6)
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
            searchQuery: searchText,
            // Only search-result rows scroll: with the alphabet showing, the row is where it lives.
            onScrollTo: searchText.isEmpty ? nil : {
                withAnimation { searchText = "" }
                scrollTarget = Self.letterRowID(letterData)
            }
        )
        .equatable()
        .id(Self.letterRowID(letterData))
    }

    private static func letterRowID(_ letterData: LetterData) -> String { "letter_\(letterData.letter)" }

    @ViewBuilder
    private var mainLetterSections: some View {
        if searchText.isEmpty {
            exploreSection

            standardLetterSections

            countedLetterSection("SPECIAL ARABIC LETTERS", otherArabicLetters)

            // The reading topics (Tashkeel, the stacked ٮحـ, laam alif, Basic Grammar) used to be a
            // section of link rows here, between the letters and the numbers. They are Explore tiles
            // at the top now (Abu, 2026-09-22), so everything there is to study is in one place.
            Section(header: SectionPillHeader(title: "ARABIC NUMBERS", count: numbers.count)) {
                numberCollection
            }

            tajweedSection

            countedLetterSection("NON-ARABIC LETTERS", nonArabicArabicScriptLetters, footer: Self.nonArabicLettersFooter)
        }
    }

    /// One study tool on the Explore shelf.
    private struct ExploreTile: Identifiable {
        let id: String
        let title: String
        let caption: String
        /// An Arabic specimen, or a symbol for a tool with no Arabic to show.
        var specimen: String? = nil
        var systemImage: String? = nil
        /// Which face draws the specimen: the reader's, or the Uthmani hand for a shape only it draws.
        var face: ArabicTopicLinkLabel.Face = .reader
        let door: ArabicDoor
    }

    #if os(iOS)
    /// The Reading Test tile's caption shows the ladder's progress once there is some.
    @ObservedObject private var readingProgress = ReadingTestProgress.shared

    private var readingTestCaption: String {
        let total = ReadingTier.all.count
        let passed = readingProgress.passedCount
        return passed > 0 ? "\(passed) of \(total) tiers passed" : "\(total) tiers \u{00B7} letter quiz"
    }
    #endif

    /// Every study tool, in the order they are met: the letters' families and look-alikes, the
    /// test, then the script's own topics, and grammar last.
    private var exploreTiles: [ExploreTile] {
        var tiles: [ExploreTile] = [
            ExploreTile(id: "families", title: "Letter Families", caption: "Makharij, sifaat, rules",
                        specimen: "ص س ز", door: .families),
            ExploreTile(id: "soundAlikes", title: "Sound-Alikes", caption: "Pairs people mix up",
                        specimen: "س ص", door: .soundAlikes),
        ]
        #if os(iOS)
        // The Letter Quiz lives on the test's page (one tile opens both); the watch has neither.
        tiles.append(ExploreTile(id: "readingTest", title: "Reading Test", caption: readingTestCaption,
                                 systemImage: "text.book.closed.fill", door: .readingTest))
        #endif
        tiles += [
            ExploreTile(id: "tashkeel", title: "Tashkeel", caption: "Every mark on every letter",
                        specimen: "\u{0628}\u{064E}", door: .tashkeel),
            ExploreTile(id: "baaHaa", title: "Baa on Haa", caption: "One shape, fifteen pairs",
                        specimen: BaaHaaShapesView.skeleton, face: .uthmani, door: .baaHaa),
            ExploreTile(id: "laamAlif", title: "Laam Alif", caption: "The compulsory ligature",
                        specimen: LaamAlifShapesView.skeleton, door: .laamAlif),
            ExploreTile(id: "basics", title: "Basic Grammar", caption: "Gender, duals, plurals, and the three case endings",
                        specimen: "ال", door: .basics),
        ]
        return tiles
    }

    /// Three to a row on the phone, two on the watch. A row left with a single tile draws it wide.
    private var exploreRows: [[ExploreTile]] {
        #if os(watchOS)
        return exploreTiles.chunked(into: 2)
        #else
        return exploreTiles.chunked(into: 3)
        #endif
    }

    /// The study tools, as tiles at the very top: below twenty-eight letters nobody would find them,
    /// and ALL of them are here now (Abu, 2026-09-22: "put them all with basic grammar at the top in
    /// explore"), where the reading topics used to be a section of link rows further down. Two pairs
    /// were merged the same day so the shelf stays two rows of three and one wide tile: the Letter
    /// Quiz is on the Reading Test's page, Default Tashkeel on the Tashkeel table's. Buttons writing
    /// the one `door`, not links: the tiles of a row share a List row.
    private var exploreSection: some View {
        Section {
            ForEach(Array(exploreRows.enumerated()), id: \.offset) { _, row in
                if row.count == 1, let tile = row.first {
                    wideExploreTile(tile)
                } else {
                    HStack(alignment: .top, spacing: 8) {
                        ForEach(row) { tile in
                            exploreTile(tile)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            Text("EXPLORE")
        }
    }

    private func exploreTile(_ tile: ExploreTile) -> some View {
        Button {
            settings.hapticFeedback()
            door = tile.door
        } label: {
            VStack(spacing: 3) {
                exploreSpecimen(tile, base: 22, relativeTo: .title3)
                    .frame(height: 30)

                Text(tile.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(tile.caption)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(settings.accentColor.color.opacity(0.09))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tile.title). \(tile.caption)")
        .accessibilityAddTraits(.isButton)
    }

    /// A tile on a row of its own, laid out sideways so the width is used: the specimen in its box,
    /// the title and the caption beside it, a chevron at the end.
    private func wideExploreTile(_ tile: ExploreTile) -> some View {
        Button {
            settings.hapticFeedback()
            door = tile.door
        } label: {
            HStack(alignment: .center, spacing: 12) {
                exploreSpecimen(tile, base: 24, relativeTo: .title2)
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(settings.accentColor.color.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(tile.title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(tile.caption)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color.secondary.opacity(0.6))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(settings.accentColor.color.opacity(0.09))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tile.title). \(tile.caption)")
        .accessibilityAddTraits(.isButton)
    }

    /// The tile's specimen (or symbol), accent-tinted, in the face the tile asks for.
    private func exploreSpecimen(_ tile: ExploreTile, base: CGFloat, relativeTo style: Font.TextStyle) -> some View {
        Group {
            if let specimen = tile.specimen {
                Text(specimen)
                    .font(exploreFont(tile.face, base: base, relativeTo: style))
                    .arabicFontDesign(custom: exploreUsesCustomFace(tile.face))
            } else if let systemImage = tile.systemImage {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
            }
        }
        .foregroundColor(settings.accentColor.color)
        .lineLimit(1)
        .minimumScaleFactor(0.4)
    }

    private func exploreFont(_ face: ArabicTopicLinkLabel.Face, base: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        switch face {
        case .uthmani: return Font.arabic(Settings.hafsUthmaniFontName, size: base, relativeTo: style)
        case .reader where settings.useFontArabic: return settings.scalableIslamArabicFont(base: base, relativeTo: style)
        case .reader, .plain: return .system(style)
        }
    }

    private func exploreUsesCustomFace(_ face: ArabicTopicLinkLabel.Face) -> Bool {
        switch face {
        case .uthmani: return true
        case .reader: return settings.useFontArabic && settings.islamUsesCustomArabicFace
        case .plain: return false
        }
    }

    @ViewBuilder
    private var standardLetterSections: some View {
        switch grouping {
        case .alphabetical:
            countedLetterSection("STANDARD ARABIC LETTERS", standardArabicLetters, shuffle: true)
        case .shape:
            ForEach(similarityGroups.indices, id: \.self) { idx in
                let group = similarityGroups[idx]
                let header = idx == 0 ? "VOWEL LETTERS" : Self.similarityHeader(for: group)
                countedLetterSection(header, group.compactMap { letterData(for: $0) })
            }
        case .axis(let axis):
            axisBanner(axis)

            ForEach(shownFamilies(of: axis)) { family in
                familySection(family)
            }

            // The letters no family of this axis claims, so the alphabet is always all there.
            if focusedFamilyID == nil {
                let rest = LetterTraits.unclaimedLetters(of: axis).compactMap { letterData(for: $0) }
                if !rest.isEmpty {
                    countedLetterSection(axis.restTitle.uppercased(), rest, footer: axis.restNote)
                }
            }
        }
    }

    /// The families of `axis` on show: all of them, or the one a banner chip narrowed it to.
    private func shownFamilies(of axis: LetterAxis) -> [LetterFamily] {
        guard let focusedFamilyID, axis.families.contains(where: { $0.id == focusedFamilyID }) else {
            return axis.families
        }
        return axis.families.filter { $0.id == focusedFamilyID }
    }

    /// One family of the active grouping: its name in both languages over its letters, with what
    /// the letters share underneath and an info button that opens the family's own page.
    private func familySection(_ family: LetterFamily) -> some View {
        Section {
            letterCollection(family.letters.compactMap { letterData(for: $0) })
        } header: {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(family.name.uppercased()) \u{00B7} \(family.meaning.uppercased())")

                    Text(family.arabic)
                        .font(.footnote)
                        .foregroundColor(family.legendColor ?? settings.accentColor.color)
                        .textCase(nil)
                }

                Spacer(minLength: 8)

                CountPill(count: family.letters.count)

                Image(systemName: "info")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: SectionPillHeader.pillHeight, height: SectionPillHeader.pillHeight)
                    .conditionalGlassEffect(circle: true)
                    .onTapGesture {
                        settings.hapticFeedback()
                        door = .family(family)
                    }
                    .accessibilityLabel("About \(family.name)")
                    .accessibilityAddTraits(.isButton)
            }
        } footer: {
            Text(family.summary)
        }
    }

    /// What the active grouping IS, above the letters it regroups: the question it asks in both
    /// languages, a chip per family to narrow the alphabet to just that one, and the way back.
    private func axisBanner(_ axis: LetterAxis) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    AccentIconChip(systemImage: axis.systemImage, size: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(axis.title)
                            .font(.headline)

                        Text(axis.transliteration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 0)
                }

                // Its own line: beside the title, a long Arabic name (the noon sakinah's) squeezed
                // the English into a two-word column.
                Text(axis.arabic)
                    .font(settings.useFontArabic ? settings.scalableIslamArabicFont(base: 21, relativeTo: .title3) : .title3)
                    .arabicFontDesign(custom: settings.useFontArabic && settings.islamUsesCustomArabicFace)
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                // The shelf's other axes, as chips (Abu, 2026-09-22: the menu names the shelf, the
                // page picks the axis, "one can customize it in that row"). Heavy or Light has its
                // own menu button and no siblings here.
                let siblings = Self.shelfAxes(axis.shelf)
                if siblings.count > 1, siblings.contains(axis) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(siblings) { sibling in
                                axisChip(sibling, isOn: sibling == axis) {
                                    setGrouping(.axis(sibling))
                                }
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }

                Text(axis.question)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        familyChip(title: "All", systemImage: "square.grid.2x2", isOn: focusedFamilyID == nil, tint: nil) {
                            focusedFamilyID = nil
                        }

                        ForEach(axis.families) { family in
                            familyChip(title: family.name, systemImage: family.systemImage,
                                       isOn: focusedFamilyID == family.id, tint: family.legendColor) {
                                focusedFamilyID = focusedFamilyID == family.id ? nil : family.id
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }

                // Inside the banner, not rows of their own: as two more rows the banner was taller
                // than the letters it introduces.
                HStack(spacing: 8) {
                    bannerAction("About These Families", systemImage: "book") {
                        door = .axes(title: axis.title, axes: [axis])
                    }

                    bannerAction("Alphabetical", systemImage: "arrow.uturn.backward") {
                        setGrouping(.alphabetical)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            // The shelf's name joins the heading when the banner carries its chips ("GROUPED BY ·
            // SIFAAT"); a lone axis keeps the plain heading.
            let siblings = Self.shelfAxes(axis.shelf)
            Text(siblings.count > 1 && siblings.contains(axis)
                 ? "GROUPED BY \u{00B7} \(axis.shelf.transliteration.uppercased())"
                 : "GROUPED BY")
        }
    }

    private func bannerAction(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(settings.accentColor.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .conditionalGlassEffect(clear: true, rectangle: true)
        }
        .buttonStyle(.plain)
    }

    private func familyChip(title: String, systemImage: String, isOn: Bool, tint: Color?, action: @escaping () -> Void) -> some View {
        let color = tint ?? settings.accentColor.color
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { action() }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundColor(isOn ? .white : color)
                .background(Capsule().fill(isOn ? color : color.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    /// A chip for one axis of the active shelf: outlined, unlike the tinted family chips under it,
    /// because the two rows ask different questions (which axis, then which family).
    private func axisChip(_ axis: LetterAxis, isOn: Bool, action: @escaping () -> Void) -> some View {
        let color = settings.accentColor.color
        return Button {
            action()
        } label: {
            Label(axis.title, systemImage: axis.systemImage)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundColor(isOn ? .white : color)
                .background(Capsule().fill(isOn ? color : Color.clear))
                .overlay(Capsule().strokeBorder(color.opacity(isOn ? 0 : 0.45), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    #if os(iOS)
    /// The grouping menu, FLAT (Abu, 2026-09-22: "don't make them a menu in a menu"): the three
    /// groupings this screen has always had, alphabetical, similar shapes and heavy or light, then
    /// one button per tajweed shelf. A shelf button lands on the shelf's remembered axis, and the
    /// banner above the letters carries a chip for each axis on that shelf, so the choice inside a
    /// shelf is made on the page, not in a submenu. Every tajweed grouping is named in English AND
    /// Arabic (Abu, 2026-09-20): the Arabic term is the one a teacher will use.
    @ViewBuilder
    private var groupingMenuItems: some View {
        Text("Group the Alphabet")
            .foregroundStyle(.secondary)

        groupingButton(.alphabetical)
        groupingButton(.shape)
        groupingButton(.axis(.weight))

        Divider()

        ForEach(LetterAxis.Shelf.allCases) { shelf in
            shelfButton(shelf)
        }
    }

    private func shelfButton(_ shelf: LetterAxis.Shelf) -> some View {
        Button {
            setGrouping(.axis(preferredAxis(of: shelf)))
        } label: {
            Label("\(shelf.transliteration) \u{00B7} \(shelf.arabic)",
                  systemImage: isOnShelf(shelf) ? "checkmark" : shelfIcon(shelf))
        }
    }

    private func shelfIcon(_ shelf: LetterAxis.Shelf) -> String {
        switch shelf {
        case .place: return "mouth"
        case .qualities: return "waveform"
        case .rules: return "text.book.closed"
        }
    }

    private func groupingButton(_ option: Grouping) -> some View {
        Button {
            setGrouping(option)
        } label: {
            Label(
                option.axis.map { "\($0.title) \u{00B7} \($0.arabic)" } ?? option.title,
                systemImage: option == grouping ? "checkmark" : option.icon
            )
        }
    }
    #endif

    @ViewBuilder
    private var searchResultsSection: some View {
        if !searchText.isEmpty {
            // ONE scan per pass: the rows and the count pill share the same merged result list -
            // as two separate accesses each computed property re-filtered every letter per keystroke.
            let results = filteredStandardForMode + filteredOther
            let families = matchingFamilies
            if !families.isEmpty {
                Section(header: SectionPillHeader(title: "LETTER FAMILIES", count: families.count)) {
                    ForEach(families) { family in
                        LetterFamilyLink(family: family) {
                            LetterTraitRow(
                                systemImage: family.systemImage,
                                tint: family.legendColor,
                                title: family.title,
                                arabic: family.arabic,
                                caption: family.summary,
                                letters: family.letters
                            )
                        }
                    }
                }
            }
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
/// `settings.arabicLetterSizeIndex`, which both screens apply as a Dynamic-Type floor that many steps ABOVE
/// the size they already read at (`arabicLetterTypeFloor(steps:)`). Position 0 is no floor at all - the
/// alphabet then renders at whatever size the device is set to.
struct ArabicSizeSlider: View {
    @ObservedObject var settings = Settings.shared

    private var maxIndex: Int { Settings.arabicLetterSizeSteps }

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