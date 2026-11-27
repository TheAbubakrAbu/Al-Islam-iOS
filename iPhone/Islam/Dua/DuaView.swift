import SwiftUI
import AVFoundation

struct DuaItem: Identifiable, Sendable {
    let arabicText: String
    let transliteration: String
    let translation: String
    let reference: String?
    let displayTranslation: String
    let searchBlob: String
    /// A recitation to stream (the Hisn al-Muslim entries), shown as a play pill under the row.
    var audioURL: URL? = nil
    /// A stable id for entries that have one (Hisn's "hisn-12"); the text-derived id otherwise.
    var identity: String? = nil

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

    /// Where a referenced dua's words come from, when it is one: resolved as the screen builds its
    /// rows (`DuaCollection.resolved()`), never stored here, so a dua written as a reference cannot
    /// be baked in empty by a list built before the Quran finished loading.
    enum Source: Equatable {
        /// The Quran this app ships (`QuranQuote.swift`): the cited ayahs, narrowed to the dua's own
        /// words by a 0-based inclusive token range (nil = the whole ayah).
        case quran(reference: String, words: ClosedRange<Int>?)
        /// A narration on the app's own shelf (`HadithQuote.swift`): token ranges of the row's matn
        /// and of its translation. More than one range skips a narrator's aside in the middle of the
        /// dua; the pieces are read in order and joined by an ellipsis.
        case shelf(link: String, arabic: [ClosedRange<Int>], english: [ClosedRange<Int>])
    }

    /// Set when the dua's words are a reference; nil when they are its own text.
    var source: Source? = nil
    /// The app's own line about when or how often the dua is said ("Three times, morning and
    /// evening"), shown after the translation in parentheses. Kept apart from `translation` so a
    /// referenced dua's English stays exactly the shelf's or the Quran's words.
    var note: String? = nil

    /// A dua that is Quran: the words come from the Quran this app ships, never from a copy here.
    /// `translation` is Tilawa's own rendering where it has one, and nil where the reader's own
    /// translation is what the dua says.
    init(quran reference: String, words: ClosedRange<Int>? = nil, transliteration: String,
         translation: String? = nil, note: String? = nil) {
        self.init(arabicText: "", transliteration: transliteration, translation: translation ?? "",
                  reference: reference)
        source = .quran(reference: reference, words: words)
        self.note = note
    }

    /// A dua that is a narration on the app's own shelf. `cite` is the citation the row displays;
    /// the Arabic and the English are both the shelf's words, read by token range.
    init(hadith link: String, cite: String, arabic: ClosedRange<Int>, english: ClosedRange<Int>,
         transliteration: String, note: String? = nil) {
        self.init(hadith: link, cite: cite, arabic: [arabic], english: [english],
                  transliteration: transliteration, note: note)
    }

    /// The same, for a dua the narration interrupts (a narrator's "I think he said" mid-dua).
    init(hadith link: String, cite: String, arabic: [ClosedRange<Int>], english: [ClosedRange<Int>],
         transliteration: String, note: String? = nil) {
        self.init(arabicText: "", transliteration: transliteration, translation: "", reference: cite)
        source = .shelf(link: link, arabic: arabic, english: english)
        self.note = note
    }


    /// The same dua with its referenced words filled in from the app's own Quran and shelf. Called
    /// off the main actor: reading a narration decompresses a block of its pack.
    func resolved() -> DuaItem {
        guard let source else { return self }
        var arabic = arabicText
        var english = translation
        switch source {
        case let .quran(reference, words):
            guard let parsed = QuranQuoteReference(reference), let text = QuranQuoteSource.resolve(parsed) else { return self }
            arabic = words.map { WordRange.words(text.arabic, $0) } ?? text.arabic
            if english.isEmpty { english = text.english }
        case let .shelf(link, arabicRanges, englishRanges):
            guard let parsed = HadithQuoteReference(link), let row = HadithQuoteSource.read(parsed) else { return self }
            // A dua is recited from the page: a narrator's aside in the middle of it ("or he said ...",
            // which the shelf sets between dashes) goes in parentheses, so the reader knows those
            // words are not theirs to say. The words themselves are the shelf's, untouched.
            arabic = WordRange.parenthesizingAsides(WordRange.words(row.arabic, arabicRanges))
            english = englishRanges.map { WordRange.tidiedSentence(WordRange.words(row.text, $0)) }
                .filter { !$0.isEmpty }
                .joined(separator: " \u{2026} ")
        }
        if let note, !english.isEmpty { english += " (\(note))" }
        var filled = DuaItem(arabicText: arabic, transliteration: transliteration, translation: english,
                             reference: reference)
        filled.audioURL = audioURL
        filled.identity = id       // the id the unresolved item had, so rows and search keys hold
        filled.source = source      // the note is in `translation` now, so `filled.note` stays nil
        return filled
    }

    /// The citation as the reader sees it. `reference` stays the English it is stored as (it is part
    /// of the row's id, its search text and the on-device model's provenance); the Arabic interface
    /// shows a Quran reference in its own digits, and a single narration ("Sahih Muslim 2739") under
    /// the book's Arabic title. A citation carrying a grading or a second source reads as written.
    var displayReference: String? {
        guard let reference else { return nil }
        switch source {
        case .quran?:
            return reference.localizedDigits
        case let .shelf(link, _, _)?:
            #if os(iOS) && HAS_HADITH
            guard !reference.contains(";"), let slug = link.split(separator: ":").first else { return reference }
            return HadithCatalogBook.displayReference(stored: reference, slug: String(slug))
            #else
            _ = link
            return reference
            #endif
        case nil:
            return reference
        }
    }

    /// Stable whether or not the words have been filled in: a reference names itself by its
    /// reference and transliteration, never by text that arrives later.
    var id: String {
        if let identity { return identity }
        if source != nil { return "\(reference ?? "")-\(transliteration)" }
        return "\(reference ?? transliteration)-\(arabicText)"
    }
}

struct DuaCollection: Identifiable, Sendable {
    /// English DATA, like `subtitle`: the id, the resume key, the search text, the Ask AI match and
    /// source line all read it. Screens show `displayTitle`.
    let title: String
    let subtitle: String
    let systemImage: String
    let introductionTitle: String
    let introduction: String
    let items: [DuaItem]
    /// The title in the reader's language when the source carries one (Hisn al-Muslim's own Arabic
    /// chapter titles); nil looks `title` up in the catalog.
    var localTitle: String? = nil

    var id: String { title }

    /// The title as the screens show it.
    var displayTitle: String { localTitle ?? title.localizedDisplay }

    /// The collection with every referenced dua's words filled in from the app's own Quran and shelf.
    func resolved() -> DuaCollection {
        DuaCollection(title: title, subtitle: subtitle, systemImage: systemImage,
                      introductionTitle: introductionTitle, introduction: introduction,
                      items: items.map { $0.resolved() }, localTitle: localTitle)
    }
}

/// Fills the Dua screen's referenced duas with their words, once, off the main thread.
///
/// The collections below are written as references (`DuaItem(quran:)`, `DuaItem(hadith:)`): the dua
/// screen carries no copy of an ayah or of a narration the app already ships. Resolving them reads
/// `QuranData` and decompresses a block of a hadith pack, so it happens in one detached pass and the
/// filled collections are published; until it finishes (a moment on a cold launch, nothing at all
/// once the Quran is warm) the screen shows the same rows with their words still empty.
@MainActor
final class DuaLibrary: ObservableObject {
    static let shared = DuaLibrary()

    /// The collections as the screen shows them: the authored ones until the referenced words land.
    @Published private(set) var collections: [DuaCollection]
    /// One flat list across the collections, in the collections' own order.
    @Published private(set) var allItems: [DuaItem]

    private var resolving = false

    private init(_ source: [DuaCollection] = DuaLibrary.authored) {
        collections = source
        allItems = source.flatMap(\.items)
    }

    /// The collections exactly as written: the source of truth for ids and ordering.
    ///
    /// `nonisolated` because it is read from off the main actor (the detached pass that resolves the
    /// referenced duas) and from a nonisolated static (`DuaView.collection(of:)`). That is safe here
    /// and not merely silenced: this is a `let` of immutable value types, written once at first use
    /// and never mutated, so there is nothing to race. Without it this is a warning today and an
    /// error under the Swift 6 language mode. Both types are `Sendable` (plain values), so this is
    /// a plain `nonisolated`, checked by the compiler rather than asserted.
    nonisolated static let authored: [DuaCollection] = [
        DuaCollections.common,
        DuaCollections.morningEvening,
        DuaCollections.sleepWaking,
        DuaCollections.distress,
        DuaCollections.travel,
        DuaCollections.homeMosque,
        DuaCollections.foodDrink,
        DuaCollections.forgiveness,
        DuaCollections.prophets,
        DuaCollections.rabbana,
    ]

    /// Resolve once. Safe to call from every appearance: a second call while one is in flight, or
    /// after one finished, does nothing.
    func load() {
        guard !resolving else { return }
        resolving = true
        Task { @MainActor [weak self] in
            // The Quran text is what most of these duas are; wait for it rather than resolve to
            // nothing. (Already loaded on any launch that has shown the Quran tab: returns at once.)
            await QuranQuoteSource.waitUntilReady()
            // On the main actor: the resolution reads `QuranData`'s arrays and Settings, which the
            // main actor reassigns, and a detached read of them raced those writes (Quality Guide
            // C5). It is a few dozen dictionary lookups, not worth a thread.
            let filled = DuaLibrary.authored.map { $0.resolved() }
            guard let self else { return }
            self.collections = filled
            self.allItems = filled.flatMap(\.items)
        }
    }
}

struct DuaView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @State private var searchText = ""
    #if os(iOS)
    /// The "About" card's single open door (one @State + one destination on the List:
    /// every chip lives in the SAME List row, and two links in one row both fire).
    @State private var aboutDoor: SignsAboutDoor?
    /// The Dua of the Day card's two doors (the Today pill, "More duas for this situation"): one
    /// state and one destination on the List. Two links in the card's one row both fired on any tap,
    /// and Back revealed the second screen (Quality Guide G1).
    @State private var hisnCardDoor: HisnDuaCardDoor?
    #endif
    #if os(iOS)
    /// Hisn al-Muslim, loaded off the main thread for the front page's dua of the day.
    @State private var hisnLibrary: HisnDuasStore.Library?
    #if DEBUG
    /// "-openHisnLibrary": push the Fortress at launch.
    @State private var debugOpenHisn = false
    #endif
    #endif
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The collection row a result asked to scroll to ("Scroll To Collection"), consumed once the search clears.
    @State private var scrollTarget: String?
    #if os(iOS)
    /// The collections as tiles or as rows: this screen's own choice, a grid until it is changed
    /// (Abu, 2026-11-26: "Support grid mode for dua and Hisn al Muslim"; 2026-11-15: "Use grid mode
    /// everywhere default"). The duas themselves are passages and stay rows in both.
    @AppStorage("duaGridMode") private var gridMode = true
    #endif

    /// The collections with their referenced duas' words filled in (`DuaLibrary`). The screen reads
    /// them through the library, never from the authored literals, so a dua written as a reference
    /// shows the app's own text.
    @ObservedObject private var library = DuaLibrary.shared

    private var collections: [DuaCollection] { library.collections }

    private var normalizedQuery: String {
        searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// Collection rows filter IN PLACE while searching, the reading lists' rule.
    private func filteredCollections(for normalizedQuery: String) -> [DuaCollection] {
        guard !normalizedQuery.isEmpty else { return collections }
        let matched = collections.filter {
            $0.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(normalizedQuery)
                || $0.subtitle.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(normalizedQuery)
                || Self.translatedNames($0).contains { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(normalizedQuery) }
        }
        // The collection named for the query leads the ones whose subtitle mentions it.
        return SearchRank.sorted(matched, by: normalizedQuery) { [$0.title, $0.subtitle] + Self.translatedNames($0) }
    }

    /// The title and subtitle as a translated interface shows them, after the English, where they differ.
    private static func translatedNames(_ collection: DuaCollection) -> [String] {
        [collection.displayTitle, collection.subtitle.localizedDisplay]
            .filter { $0 != collection.title && $0 != collection.subtitle }
    }

    /// Every dua in EVERY collection matching the query - so a search here finds the supplication
    /// itself, not just the folder it lives in.
    private func matchingDuas(for normalizedQuery: String) -> [DuaItem] {
        guard !normalizedQuery.isEmpty else { return [] }
        return collections.flatMap { collection in
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

    fileprivate static let semanticCorpusID = "duas-en"
    /// One flat list across the collections - the corpus rows, in a stable order.
    /// One flat list across the collections, in a stable order (the library's, resolved).
    static var allDuaItems: [DuaItem] { DuaLibrary.shared.allItems }

    /// True when the live query is one the semantic engine can answer (English text, long enough).
    private var aiQueryEligible: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return SemanticSearchEngine.isSupported
            && trimmed.count >= 3
            && !trimmed.containsArabicScript
    }

    fileprivate static func prepareSemanticCorpus(_ engine: SemanticSearchEngine) {
        guard SemanticSearchEngine.isSupported, !engine.isReady(semanticCorpusID) else { return }
        // The transliterated "title" plus the English text; the Arabic embeds to nothing anyway.
        let texts = allDuaItems.map { "\($0.transliteration) \($0.translation)" }
        // Keyed by the dua's own id, so index -> dua resolution survives any reorder of the source.
        let keys = allDuaItems.map(\.id)
        // v3 (2026-11-26): the transliterations were respelled to the house style, long vowels doubled
        // (Scripts/transliteration.py), so an earlier build in Caches holds stale texts and keys.
        engine.prepare(corpusID: semanticCorpusID, version: "v3-\(texts.count)", texts: texts, keys: keys)
    }

    private func prepareSemanticCorpus() {
        Self.prepareSemanticCorpus(semanticEngine)
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

    // Ask AI: the on-device chat (`AskAIChatView`), opened from the ASK AI row above the matches
    // with the typed query as its first question - the Quran search's rule. Exists only on Apple
    // Intelligence devices (`OnDeviceAsk.isAvailable`).
    @State private var showAskAI = false
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist. Reset to the
    /// AI list on every new query.
    @State private var showKeywordResults = false

    /// "ASK AI" with the sparkles glyph in the header gray, as the Quran search's `askAIHeader` draws it.
    private var askAIHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("ASK AI")

            Spacer()
        }
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

                Image(systemName: "chevron.forward")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundColor(settings.accentColor.color)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentSurface(clear: true, rectangle: true)
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
                                source: item.displayReference
                            )
                            .equatable()
                            .spokenRowWash(item.arabicText)
                        }
                    } header: {
                        SectionPillHeader(title: String(localized: "AI MATCHES"), count: aiHits.count, icon: "sparkles")
                    }
                }
            } else if !semanticEngine.failedCorpora.contains(Self.semanticCorpusID) {
                Section { AISearchStatusRow(corpusID: Self.semanticCorpusID, failed: false) }
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

        return ScrollViewReader { proxy in
        List {
            Group {
            if query.isEmpty {
            #if os(iOS)
            ResourceHeroSection(ResourceHero(
                eyebrow: String(localized: "SUPPLICATION"),
                systemImage: "text.book.closed.fill",
                headline: String(localized: "Call upon Me; I will respond to you."),
                source: String(localized: "Quran 40:60"),
                message: HisnDuasStore.isBundled
                    ? String(localized: "Short, daily supplications that keep your heart connected to Allah in every situation, each with its source, and the whole of Hisn al-Muslim beside them.")
                    : String(localized: "Short, daily supplications that keep your heart connected to Allah in every situation, each with its source."),
                stats: [
                    ResourceHeroStat("\(DuaLibrary.shared.allItems.count)".localizedDigits, String(localized: "duas")),
                    ResourceHeroStat("\(DuaLibrary.shared.collections.count)".localizedDigits, String(localized: "collections")),
                ] + (hisnLibrary.map { [ResourceHeroStat("\($0.entries.count)".localizedDigits, String(localized: "in Hisn al-Muslim"))] } ?? [])
            ) {
                DuaAnswerHoursArt()
            })
            #else
            Section(header: Text("SUPPLICATIONS TO ALLAH")) {
                ArticleLead(String(localized: "Short, daily supplications that keep your heart connected to Allah in every situation. \"Call upon Me; I will respond to you.\" (Quran 40:60)"),
                            eyebrow: String(localized: "IN SHORT"))
            }
            #endif

            #if os(iOS)
            // Hisn al-Muslim: the whole Fortress, and today's dua from it.
            if HisnDuasStore.isBundled {
                if let hisnLibrary, let today = HisnDuasStore.shared.duaOfTheDay() {
                    Section {
                        HisnDuaOfTheDayCard(entry: today, category: hisnLibrary.categories.first { $0.id == today.categoryID },
                                            library: hisnLibrary) { door in
                            // One door at a time: the About card's push is the List's other destination.
                            if aboutDoor == nil { hisnCardDoor = door }
                        }
                    }
                }
                // The two libraries DO overlap, and the footer says so rather than leaving a reader to
                // wonder why a dua they just read turns up again (Abu asked, 2026-09-19; measured:
                // about two thirds of the hadith-sourced duas in the collections above are also
                // somewhere in Hisn's 268). They are different cuts of the same sunnah, so the overlap
                // is not a defect: the collections are a short curated set arranged by SITUATION, and
                // Hisn is al-Qahtani's complete book arranged by his own 132 chapters, with audio.
                Section(header: Text("HISN AL-MUSLIM"),
                        footer: Text("Many of the duas above also appear here. The collections are a short set for everyday situations; Hisn al-Muslim is the complete book, with its own chapters, references and recitations.")) {
                    NavigationLink(destination: LazyDestination { HisnDuaLibraryView() }) {
                        SettingsRowLabel(
                            title: String(localized: "Fortress of the Muslim"),
                            systemImage: "shield.lefthalf.filled",
                            subtitle: String(localized: "268 duas for 132 situations").localizedDigits,
                            accessory: AnyView(
                                Text("حِصنُ المُسلِمِ")
                                    .font(.custom(settings.nonQuranArabicFontName, size: 16))
                                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                                    .foregroundStyle(settings.accentColor.color)
                            )
                        )
                    }
                }
            }
            #endif
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
                             ? String(localized: "No duas match your search.")
                             : String(localized: "No keyword matches; see the AI results above."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        #else
                        Text("No duas match your search.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        #endif
                    }

                    #if os(iOS)
                    // Tiles while nothing is typed; a search filters ROWS in place, as search
                    // results are rows everywhere.
                    if gridMode, query.isEmpty {
                        collectionTiles(shownCollections)
                    } else {
                        collectionRows(shownCollections, query: query)
                    }
                    #else
                    collectionRows(shownCollections, query: query)
                    #endif
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
                            .contentSurface()
                            .padding(.vertical, -16)
                            .hiddenInSimple(.sectionCounts)
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
                            source: item.displayReference,
                            onScrollTo: Self.collection(of: item).map { collection in
                                { scrollToCollection(collection) }
                            },
                            scrollLabel: String(localized: "Scroll To Collection")
                        )
                        .equatable()
                        .spokenRowWash(item.arabicText)
                    }
                } header: {
                    HStack(spacing: 8) {
                        Text("MATCHING DUAS")

                        Spacer()

                        // Count pill first: it sits at the far left of every trailing cluster
                        // (the SectionPillHeader rule).
                        CountPill(count: matching.count)

                        ListenAllPill(texts: matching.map(\.arabicText))
                    }
                }
            }
            }

            if query.isEmpty {
            // The article kit's cards (Abu, 2026-10-03: "make it pretty like pillars and beliefs"): the
            // word and its root as an etymology card, the virtues as a lead and two quoted callouts.
            Section(header: Text("ETYMOLOGY")) {
                ArticleEtymologyCard("Dua", arabic: "دُعَاء", root: "د ع و", rootLatin: "d-‘-w",
                                     coreMeaning: String(localized: "to call, to invite, to summon"),
                                     text: String(localized: "Dua literally means calling out, especially calling upon Allah. In Islam it is not just asking for things; it is an act of worship, turning to Him with need, hope, fear, and love."))
            }

            Section(header: Text("VIRTUES OF DUA")) {
                ArticleLead(String(localized: "Dua is an act of worship and a direct connection with Allah. No sincere call is lost: it is answered soon, stored as reward in the Hereafter, or an equal harm is turned away by it."),
                            eyebrow: String(localized: "IN SHORT"))

                ArticleCallout(
                    bullets: [
                        String(localized: "And your Lord says, \"Call upon Me; I will respond to you.\" (Quran 40:60)"),
                        String(localized: "And when My servants ask you concerning Me, indeed I am near. I respond to the invocation of the supplicant when he calls upon Me. (Quran 2:186)"),
                        String(localized: "Is He [not best] who responds to the desperate one when he calls upon Him and removes evil and makes you inheritors of the earth? (Quran 27:62)")
                    ],
                    title: String(localized: "Quranic Promise"),
                    systemImage: "book.closed.fill"
                )
                .articleCardRow()

                ArticleCallout(
                    bullets: [
                        String(localized: "Dua is worship. (Abu Daawood 1479; Tirmidhi 3247, saheeh)"),
                        String(localized: "No Muslim supplicates, so long as it is not for sin or for severing kinship, but Allah gives him one of three: the answer is hastened, it is stored for him in the Hereafter, or an equivalent evil is turned away from him. (Musnad Ahmad 11133, hasan)")
                    ],
                    title: String(localized: "Prophetic Guidance"),
                    systemImage: "quote.bubble.fill"
                )
                .articleCardRow()
            }

                Section {
                    SpeechQualityHint()
                }
            }
                #if os(iOS)
                AboutSignsSection(heading: String(localized: "About Dua"),
                                  systemImage: "text.book.closed",
                                  doors: [.makeDua, .allah, .tawhid],
                                  openDoor: Binding(get: { aboutDoor },
                                                    set: { new in if new == nil || hisnCardDoor == nil { aboutDoor = new } }))
                #endif
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        // Applied BEFORE the bottom bar below it: bottom safe-area insets stack outward, so the inset
        // added first sits nearest the content and later ones go underneath it. With the bar first, the
        // Now Playing player landed UNDER it (Abu, 2026-10-07). The Quran tab's order is the same.
        .applyConditionalListStyle()
        .adaptiveSafeArea(edge: .bottom) {
            // The Arabic face picker used to float here, above the search bar. One control on six
            // screens writing one `settings.islamArabicFace` is a SETTING, not a reading control: it
            // now lives once, in Settings -> Islam Settings -> Arabic Text (Abu, 2026-09-19).
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
            .background(Color.white.opacity(0.00001))
        }
        #else
        .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #endif
        #if os(watchOS)
        // The watch has no floating bottom bar to order against, so it is styled here.
        .applyConditionalListStyle()
        #endif
        .compactListSectionSpacing()
        #if os(iOS)
        .aboutSignsDestination($aboutDoor)
        .pushDestination(isPresented: Binding(get: { hisnCardDoor != nil }, set: { if !$0 { hisnCardDoor = nil } })) {
            switch hisnCardDoor {
            case .dailyHub: DailyHubView()
            case .collection(let collection): DuaCollectionView(collection: collection)
            case nil: EmptyView()
            }
        }
        #endif
        .navigationTitle("Dua & Supplications")
        #if os(iOS)
        // The grid toggle, then the Islam Settings gear, in ONE toolbar (see `IslamSettingsToolbar`
        // for why a screen with a button of its own places the gear itself).
        .islamSettingsToolbar { DuaGridModeButton(gridMode: $gridMode) }
        .task {
            // The referenced duas' words, from the app's own Quran and hadith shelf.
            library.load()
            guard hisnLibrary == nil, HisnDuasStore.isBundled else { return }
            hisnLibrary = await Task.detached(priority: .userInitiated) { HisnDuasStore.shared.loaded() }.value
        }
        #if DEBUG
        .debugPushDestination(isPresented: $debugOpenHisn) { HisnDuaLibraryView() }
        .onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-openHisnLibrary") else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenHisn = true }
        }
        #endif
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
        #endif
        .onDisappear { ArabicSpeech.shared.stop() }
        .onChange(of: scrollTarget) { target in
            guard let target else { return }
            // The search rows are still animating out; scroll once the collection rows are back.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { proxy.scrollTo(target, anchor: .top) }
            }
        }
        }
    }

    /// The collections as the door rows they have always been.
    @ViewBuilder
    private func collectionRows(_ shown: [DuaCollection], query: String) -> some View {
        ForEach(shown) { collection in
            NavigationLink {
                LazyDestination {
                    DuaCollectionView(collection: collection)
                }
            } label: {
                // The app's door row: an accent chip for the icon, the title and its
                // subtitle, and the collection's size as the count pill every counted row
                // wears - so the shelf reads as a set of books rather than a plain menu.
                // Title and subtitle are the collection's English DATA (its id, its search
                // text, the on-device model's source line): translated here only.
                SettingsRowLabel(
                    title: collection.displayTitle,
                    systemImage: collection.systemImage,
                    subtitle: collection.subtitle.localizedDisplay,
                    // Its own width, always: beside a two-line caption the row squeezed the
                    // pill until a two-figure count stood one figure over the other ("1 / 1").
                    accessory: AnyView(CountPill(count: collection.items.count).fixedSize()),
                    subtitleLineLimit: 2
                )
            }
            .id(Self.collectionRowID(collection))
            #if os(iOS)
            .contextMenu {
                Text(collection.displayTitle)
                    .foregroundStyle(.secondary)

                if !query.isEmpty {
                    Button {
                        settings.hapticFeedback()
                        scrollToCollection(collection)
                    } label: {
                        Label("Scroll To Collection", systemImage: "arrow.down.circle")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = collection.displayTitle
                } label: {
                    Label("Copy Title", systemImage: "doc.on.doc")
                }
            }
            .swipeActions(edge: .trailing) {
                if !query.isEmpty {
                    Button {
                        settings.hapticFeedback()
                        scrollToCollection(collection)
                    } label: {
                        Image(systemName: "arrow.down.circle")
                    }
                    .tint(.secondary)
                }
            }
            #endif
        }
    }

    #if os(iOS)
    /// The collection grid's columns, on every width.
    private static let collectionGridColumns = 2

    /// A collection grid row's id: the index of its first tile.
    private static func collectionGridRowID(_ start: Int) -> String { "collection_row_\(start)" }

    /// The collections as tiles, one grid row per List row (`tileGridChunk`), each with an id
    /// "Scroll To Collection" can land on. A tile pushes through the screen's one door state: a link
    /// per tile would push every tile of its row at once.
    @ViewBuilder
    private func collectionTiles(_ shown: [DuaCollection]) -> some View {
        let chunk = tileGridChunk(columns: Self.collectionGridColumns)
        ForEach(Array(stride(from: 0, to: shown.count, by: chunk)), id: \.self) { start in
            SummaryTileGrid(columns: Self.collectionGridColumns) {
                ForEach(shown[start..<min(start + chunk, shown.count)]) { collection in
                    DuaShelfTile(title: collection.displayTitle,
                                 systemImage: collection.systemImage,
                                 caption: collection.subtitle.localizedDisplay,
                                 count: collection.items.count) {
                        // One door at a time: the About card's push is the List's other destination.
                        if aboutDoor == nil, hisnCardDoor == nil { hisnCardDoor = .collection(collection) }
                    }
                }
            }
            .tileGridChunkRow(start: start, count: shown.count, chunk: chunk)
            .id(Self.collectionGridRowID(start))
        }
    }
    #endif

    /// The row id of a collection in the root list.
    private static func collectionRowID(_ collection: DuaCollection) -> String { "collection_\(collection.id)" }

    /// The collection a dua belongs to - a matching dua's home on this screen, since the duas
    /// themselves are listed only inside their collections.
    private static func collection(of item: DuaItem) -> DuaCollection? {
        // Membership is by id, and a referenced dua's id does not change when its words arrive, so
        // the authored collections answer this without waiting for the library to resolve.
        DuaLibrary.authored.first { $0.items.contains { $0.id == item.id } }
    }

    private func scrollToCollection(_ collection: DuaCollection) {
        withAnimation { searchText = "" }
        #if os(iOS)
        // With the search cleared the collections are tiles again in grid mode: land on the grid
        // row that holds this one.
        if gridMode, let index = collections.firstIndex(where: { $0.id == collection.id }) {
            let chunk = tileGridChunk(columns: Self.collectionGridColumns)
            scrollTarget = Self.collectionGridRowID(index - index % chunk)
            return
        }
        #endif
        scrollTarget = Self.collectionRowID(collection)
    }
}

/// Internal, not private: the Today screen (DailyHub.swift) opens the Dua of the Day's category here.
struct DuaCollectionView: View {
    private let settings = Settings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The dua a result asked to scroll to ("Scroll To Dua"), consumed once the search clears.
    @State private var scrollTarget: String?

    let collection: DuaCollection

    #if os(iOS)
    // The root Dua screen's AI search, scoped to this collection: same "duas-en" corpus (one vector
    // cache), hits filtered to the collection's own items.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var aiHits: [DuaItem] = []
    @State private var aiSearchTask: Task<Void, Never>?

    private func runAISearch(query: String) {
        aiSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SemanticSearchEngine.isSupported, trimmed.count >= 3, !trimmed.containsArabicScript else {
            if !aiHits.isEmpty { aiHits = [] }
            return
        }
        DuaView.prepareSemanticCorpus(semanticEngine)

        aiSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let results = await semanticEngine.search(corpusID: DuaView.semanticCorpusID, query: trimmed, limit: 24)
            guard !Task.isCancelled else { return }
            let keys = await MainActor.run { semanticEngine.corpus(DuaView.semanticCorpusID)?.itemKeys }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                let byID = Dictionary(uniqueKeysWithValues: collection.items.map { ($0.id, $0) })
                aiHits = results.compactMap { result -> DuaItem? in
                    if let keys, keys.indices.contains(result.index) { return byID[keys[result.index]] }
                    guard DuaView.allDuaItems.indices.contains(result.index) else { return nil }
                    return byID[DuaView.allDuaItems[result.index].id]
                }
                .prefix(8).map { $0 }
            }
        }
    }
    #endif

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

        return ScrollViewReader { proxy in
        List {
            Group {
            #if os(iOS)
            // Above the introduction, and only when not searching: a search is a lookup, and the last
            // thing a lookup wants is an invitation to start a twelve-step walkthrough.
            if query.isEmpty, !collection.items.isEmpty {
                Section {
                    DuaSessionStartButton(collection: collection)
                }
            }
            #endif
            introductionSection
            #if os(iOS)
            if !query.isEmpty, !aiHits.isEmpty {
                Section(header: SectionPillHeader(title: String(localized: "AI MATCHES"), count: aiHits.count, icon: "sparkles")) {
                    duaRows(aiHits, scrollable: false)
                }
            }
            #endif
            duaRows(shown)
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        .onChange(of: searchText) { text in
            runAISearch(query: text)
        }
        .onChange(of: semanticEngine.readyCorpora) { ready in
            guard ready.contains(DuaView.semanticCorpusID), !searchText.isEmpty else { return }
            runAISearch(query: searchText)
        }
        #endif
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        // Applied BEFORE the bottom bar below it: bottom safe-area insets stack outward, so the inset
        // added first sits nearest the content and later ones go underneath it. With the bar first, the
        // Now Playing player landed UNDER it (Abu, 2026-10-07). The Quran tab's order is the same.
        .applyConditionalListStyle()
        .adaptiveSafeArea(edge: .bottom) {
            // The Arabic face picker used to float here, above the search bar. One control on six
            // screens writing one `settings.islamArabicFace` is a SETTING, not a reading control: it
            // now lives once, in Settings -> Islam Settings -> Arabic Text (Abu, 2026-09-19).
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
            .background(Color.white.opacity(0.00001))
        }
        #else
        .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #endif
        #if os(watchOS)
        // The watch has no floating bottom bar to order against, so it is styled here.
        .applyConditionalListStyle()
        #endif
        .compactListSectionSpacing()
        .navigationTitle(collection.displayTitle)
        .onDisappear { ArabicSpeech.shared.stop() }
        .onChange(of: scrollTarget) { target in
            guard let target else { return }
            // The filtered rows are still animating out; scroll once the whole collection is back.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { proxy.scrollTo(target, anchor: .top) }
            }
        }
        }
    }

    private var introductionSection: some View {
        // "ABOUT", not the collection's own name again - the navigation title directly above already says
        // "Sleep & Waking"; a header shouting "SLEEP & WAKING DUAS" right under it was saying it twice.
        Section(header: Text("ABOUT")) {
            ArticleLead(collection.introduction, eyebrow: String(localized: "IN SHORT"))
        }
    }

    private func duaRows(_ shown: [DuaItem], scrollable: Bool = true) -> some View {
        let searching = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return Section(header: duasHeader(shown)) {
            // One ForEach element is one row, of one type (`DuaListRow`, `OneRow`). It used to be the
            // dua and, for some, a second row for its play pill: one or two views, which the List
            // could only count by building every dua of the collection each time this screen's body
            // ran, and it re-inserted the rows above and below after every scroll (see `OneRow`).
            ForEach(DuaListRow.rows(for: shown)) { row in
                OneRow {
                    switch row {
                    case .dua(let item):
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
                            source: item.displayReference,
                            rowID: scrollable ? item.id : nil,
                            // Only while searching: with the whole collection showing, the row is already where it lives.
                            onScrollTo: (searching && scrollable) ? {
                                withAnimation { searchText = "" }
                                scrollTarget = item.id
                            } : nil,
                            scrollLabel: String(localized: "Scroll To Dua")
                        )
                        .equatable()
                    #if os(iOS)
                    case .recitation(_, let audio):
                        // The Hisn al-Muslim rows carry a recitation: the play pill sits under the dua.
                        HisnDuaAudioButton(url: audio)
                            .padding(.top, -4)
                            .padding(.bottom, 4)
                    #endif
                    }
                }
                // On the row, where the List holds it. The pill's row passes no text, so it is never
                // the one being read aloud and keeps the plain cell.
                .spokenRowWash(row.spokenText)
            }
        }
    }

    /// One row of a collection's list: a dua, or the play pill under a dua that has a recitation.
    private enum DuaListRow: Identifiable {
        case dua(DuaItem)
        #if os(iOS)
        case recitation(of: DuaItem.ID, URL)
        #endif

        var id: String {
            switch self {
            case .dua(let item): return "dua:\(item.id)"
            #if os(iOS)
            case .recitation(let dua, _): return "recitation:\(dua)"
            #endif
            }
        }

        /// What `spokenRowWash` matches against the text being read aloud: the dua's own words, and
        /// nothing for the pill's row.
        var spokenText: String {
            if case .dua(let item) = self { return item.arabicText }
            return ""
        }

        static func rows(for items: [DuaItem]) -> [DuaListRow] {
            var rows: [DuaListRow] = []
            rows.reserveCapacity(items.count)
            for item in items {
                rows.append(.dua(item))
                #if os(iOS)
                if let audio = item.audioURL { rows.append(.recitation(of: item.id, audio)) }
                #endif
            }
            return rows
        }
    }

    /// "SUPPLICATIONS" with the count pill the Quran and Arabic screens put on their section headers.
    /// While searching, the pill counts the matches instead.
    private func duasHeader(_ shown: [DuaItem]) -> some View {
        HStack(spacing: 8) {
            Text("SUPPLICATIONS")

            Spacer()

            // Count pill first (the SectionPillHeader rule); the pill plays every dua shown, in order.
            CountPill(count: shown.count)

            ListenAllPill(texts: shown.map(\.arabicText))
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
        introduction: String(localized: "Short, daily supplications that keep your heart connected to Allah in every situation. \"Call upon Me; I will respond to you.\" (Quran 40:60)"),
        items: [
            DuaItem(hadith: "muslim:2739", cite: "Saheeh Muslim 2739", arabic: 42...54, english: 1...34, transliteration: "Allahumma inni a‘oodhu bika min zawaali ni‘matika wa tahawwuli ‘aafiyatika wa fujaa’ati niqmatika wa jamee‘i sakhatika"),
            DuaItem(hadith: "ibnmajah:3871", cite: "Sunan Ibn Maajah 3871", arabic: 44...51, english: 59...74, transliteration: "Allahumma inni as’aluka al-‘afwa wal-‘aafiyah fi ad-dunya wal-aakhirah"),
            DuaItem(hadith: "muslim:2721a", cite: "Saheeh Muslim 2721", arabic: 34...40, english: 1...17, transliteration: "Allahumma inni as’aluka al-huda wa at-tuqa wal-‘afaafa wal-ghina"),
            DuaItem(hadith: "abudawud:5090", cite: "Sunan Abi Daawood 5090; its chain graded hasan by al-Albaani", arabic: 85...102, english: 90...118, transliteration: "Allahumma inni a‘oodhu bika minal-kufri wal-faqr, Allahumma inni a‘oodhu bika min ‘adhaabil-qabr, la ilaaha illa ant", note: "Three times in the morning and three times in the evening"),
            DuaItem(quran: "20:25-26", words: 1...7, transliteration: "Rabbi ishrah li sadri wa yassir li amri", translation: "My Lord, expand for me my breast [with assurance] And ease for me my task"),
            DuaItem(hadith: "abudawud:1522", cite: "Sunan Abi Daawood 1522", arabic: 67...73, english: 22...36, transliteration: "Allahumma a‘inni ala dhikrika wa shukrika wa husni ibaadatika", note: "Taught to Mu‘aadh to say after every prayer"),
            DuaItem(quran: "2:201", words: 3...13, transliteration: "Rabbana aatina fid-dunya hasanatan wa fil-aakhirati hasanatan wa qina ‘adhaaban-naar", translation: "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire."),
            DuaItem(hadith: "muslim:2706a", cite: "Saheeh Muslim 2706", arabic: 26...44, english: 1...37, transliteration: "Allahumma inni a‘oodhu bika minal-‘ajzi wal-kasal, wal-jubni wal-haram, wal-bukhl, wa a‘oodhu bika min ‘adhaabil-qabr, wa min fitnatil-mahya wal-mamaat"),
            DuaItem(hadith: "ibnmajah:925", cite: "Sunan Ibn Maajah 925; graded saheeh by al-Albaani", arabic: 39...47, english: 11...23, transliteration: "Allahumma inni as’aluka ‘ilman naafi‘an, wa rizqan tayyiban, wa ‘amalan mutaqabbalan", note: "Said after the salaam of the Fajr prayer"),
            DuaItem(hadith: "abudawud:1529", cite: "Sunan Abi Daawood 1529", arabic: 42...48, english: 3...19, transliteration: "Radeetu billahi Rabban, wa bil-Islaami deenan, wa bi-Muhammadin rasoola", note: "Whoever says it, Paradise is his due"),
            DuaItem(quran: "2:255", transliteration: "Allahu la ilaaha illa Huwa, Al-Hayyul-Qayyoom. La ta’khudhuhu sinatun wa la nawm. Lahu ma fi as-samaawaati wa ma fi al-ard. Man dhal-ladhi yashfa‘u ‘indahu illa bi-idhnihi? Ya‘lamu ma bayna aydeehim wa ma khalfahum, wa la yuheetoona bishay’in min ‘ilmihi illa bima shaa’. Wasi‘a kursiyyuhu as-samaawaati wal-ard, wa la ya’ooduhu hifzuhuma, wa Huwal ‘Aliyyul-‘Azeem.")
        ]
    )

    // Every entry below was checked against its cited source (sunnah.com numbering for hadith; surah:ayah
    // for Quran) before inclusion - references are load-bearing here, not decoration. When adding to these,
    // verify the collection + number actually carries the dua, and prefer Bukhari/Muslim, then the Four
    // Sunan with an explicit sahih/hasan grading.
    static let morningEvening = DuaCollection(
        title: "Morning & Evening",
        subtitle: "The Prophet's daily adhkaar for morning and evening",
        systemImage: "sun.horizon",
        introductionTitle: "Morning & Evening Adhkaar",
        introduction: String(localized: "Remembrances the Prophet ﷺ said at the start and end of every day, seeking Allah's protection, provision, and pleasure before the day makes its own claims. \"And exalt [Allah] with praise of your Lord before the rising of the sun and before its setting.\" (Quran 20:130)"),
        items: [
            DuaItem(hadith: "bukhari:6306", cite: "Saheeh al-Bukhaari 6306", arabic: 39...75, english: 15...84, transliteration: "Allahumma anta Rabbi la ilaaha illa anta, khalaqtani wa ana ‘abduka, wa ana ‘ala ‘ahdika wa wa‘dika ma istata‘tu, a‘oodhu bika min sharri ma sana‘tu, aboo’u laka bini‘matika ‘alayya, wa aboo’u laka bidhanbi faghfir li, fa innahu la yaghfiru adh-dhunooba illa anta", note: "The best way of seeking forgiveness; said in the morning and in the evening"),
            DuaItem(hadith: "tirmidhi:3390", cite: "Jaami‘ at-Tirmidhi 3390; Saheeh Muslim 2723", arabic: [34...47, 51...90], english: [11...44, 66...152], transliteration: "Amsayna wa amsal-mulku lillah, walhamdu lillah, la ilaaha illallahu wahdahu la shareeka lah, lahul-mulku wa lahul-hamdu wa huwa ‘ala kulli shay’in qadeer. Rabbi as’aluka khayra ma fi haadhihil-laylati wa khayra ma ba‘daha, wa a‘oodhu bika min sharri ma fi haadhihil-laylati wa sharri ma ba‘daha", note: "In the evening; in the morning it begins: Asbahna wa asbahal-mulku lillah"),
            DuaItem(hadith: "tirmidhi:3391", cite: "Jaami‘ at-Tirmidhi 3391", arabic: [36...46, 51...61], english: [22...52, 76...106], transliteration: "Allahumma bika asbahna wa bika amsayna wa bika nahya wa bika namootu wa ilaykal-maseer … Allahumma bika amsayna wa bika asbahna wa bika nahya wa bika namootu wa ilaykan-nushoor", note: "The first in the morning, the second in the evening"),
            DuaItem(hadith: "abudawud:5088", cite: "Sunan Abi Daawood 5088", arabic: 34...49, english: 25...50, transliteration: "Bismillahil-ladhi la yadurru ma‘a ismihi shay’un fil-ardi wa la fis-samaa’i wa huwas-Samee‘ul-‘Aleem", note: "Three times, morning and evening"),
            DuaItem(hadith: "ibnmajah:3871", cite: "Sunan Ibn Maajah 3871; Sunan Abi Daawood 5074", arabic: 44...84, english: 59...130, transliteration: "Allahumma inni as’alukal-‘aafiyata fid-dunya wal-aakhirah. Allahumma inni as’alukal-‘afwa wal-‘aafiyata fi deeni wa dunyaaya wa ahli wa maali. Allahumma-stur ‘awraati wa aamin raw‘aati. Allahumma-hfazni min bayni yadayya wa min khalfi wa ‘an yameeni wa ‘an shimaali wa min fawqi, wa a‘oodhu bi‘azamatika an ughtaala min tahti", note: "Every morning and evening; the Prophet ﷺ never left these words"),
            DuaItem(hadith: "muslim:2692", cite: "Saheeh Muslim 2692", arabic: 37...39, english: 12...25, transliteration: "SubhaanAllahi wa bihamdih", note: "One hundred times, morning and evening"),
            DuaItem(hadith: "muslim:2726a", cite: "Saheeh Muslim 2726", arabic: 91...101, english: 51...94, transliteration: "SubhaanAllahi wa bihamdihi ‘adada khalqihi wa rida nafsihi wa zinata ‘arshihi wa midaada kalimaatih", note: "Three times"),
            DuaItem(hadith: "tirmidhi:3529", cite: "Jaami‘ at-Tirmidhi 3529", arabic: 82...114, english: 85...149, transliteration: "Allahumma faatiras-samaawaati wal-ard, ‘aalimal-ghaybi wash-shahaadah, la ilaaha illa ant, rabba kulli shay’in wa maleekah, a‘oodhu bika min sharri nafsi wa min sharrish-shaytaani wa shirkih, wa an aqtarifa ‘ala nafsi soo’an aw ajurrahu ila Muslim", note: "Taught to Abu Bakr for the morning and the evening")
        ]
    )

    static let sleepWaking = DuaCollection(
        title: "Sleep & Waking",
        subtitle: "What the Prophet said lying down to sleep and on waking",
        systemImage: "moon.zzz",
        introductionTitle: "Sleep & Waking Duas",
        introduction: String(localized: "The Prophet ﷺ closed each day surrendering his soul to Allah and opened each morning with gratitude for its return. \"And it is He who has made the night for you as clothing and sleep [a means for] rest.\" (Quran 25:47)"),
        items: [
            DuaItem(hadith: "bukhari:6324", cite: "Saheeh al-Bukhaari 6324", arabic: 29...32, english: 17...26, transliteration: "Bismika Allahumma amootu wa ahya", note: "When going to bed"),
            DuaItem(hadith: "bukhari:6324", cite: "Saheeh al-Bukhaari 6324", arabic: 40...48, english: 47...69, transliteration: "Alhamdu lillahil-ladhi ahyaana ba‘da ma amaatana wa ilayhin-nushoor", note: "On waking"),
            DuaItem(hadith: "muslim:2714a", cite: "Saheeh Muslim 2714; Saheeh al-Bukhaari 6320", arabic: 63...83, english: 71...145, transliteration: "Subhaanaka Allahumma Rabbi, bika wada‘tu janbi wa bika arfa‘uh, in amsakta nafsi faghfir laha, wa in arsaltaha fahfazha bima tahfazu bihi ‘ibaadakas-saaliheen", note: "Lying down on the right side, after dusting the bed"),
            DuaItem(hadith: "muslim:2710a", cite: "Saheeh Muslim 2710; Saheeh al-Bukhaari 6311", arabic: 51...78, english: 21...77, transliteration: "Allahumma inni aslamtu wajhi ilayk, wa fawwadtu amri ilayk, wa aljaa’tu zahri ilayk, raghbatan wa rahbatan ilayk, la malja’a wa la manja minka illa ilayk, aamantu bi-kitaabikal-ladhi anzalt, wa bi-nabiyyikal-ladhi arsalt", note: "The last words before sleep; whoever dies that night dies upon the fitrah"),
            DuaItem(hadith: "muslim:2727a", cite: "Saheeh Muslim 2727; Saheeh al-Bukhaari 5362", arabic: 96...119, english: 38...85, transliteration: "Allahu Akbar (34 times), SubhaanAllah (33 times), Alhamdulillah (33 times)", note: "Taught to Ali and Faatimah at bedtime, in place of the servant they asked for"),
            DuaItem(hadith: "abudawud:5045", cite: "Sunan Abi Daawood 5045", arabic: 43...48, english: 25...40, transliteration: "Allahumma qini ‘adhaabaka yawma tab‘athu ‘ibaadak", note: "Three times, with the right hand under the cheek"),
            DuaItem(hadith: "muslim:2715", cite: "Saheeh Muslim 2715", arabic: 33...46, english: 6...37, transliteration: "Alhamdu lillahil-ladhi at‘amana wa saqaana wa kafaana wa aawaana, fakam mimman la kaafiya lahu wa la mu’wi", note: "On going to bed"),
            DuaItem(hadith: "muslim:2712", cite: "Saheeh Muslim 2712", arabic: 37...55, english: 1...50, transliteration: "Allahumma khalaqta nafsi wa anta tawaffaaha, laka mamaatuha wa mahyaaha, in ahyaytaha fahfazha, wa in amattaha faghfir laha. Allahumma inni as’alukal-‘aafiyah", note: "On going to bed")
        ]
    )

    static let distress = DuaCollection(
        title: "Distress & Anxiety",
        subtitle: "The Prophet's duas for worry, grief, and hardship",
        systemImage: "heart",
        introductionTitle: "Duas for Distress & Anxiety",
        introduction: String(localized: "Supplications the Prophet ﷺ said (and taught) for the moments when the heart is tight and the way out is hidden. \"Is He [not best] who responds to the desperate one when he calls upon Him and removes evil?\" (Quran 27:62)"),
        items: [
            DuaItem(hadith: "muslim:2730a", cite: "Saheeh Muslim 2730; Saheeh al-Bukhaari 6346", arabic: 43...66, english: 1...42, transliteration: "La ilaaha illallahul-‘Azeemul-Haleem, la ilaaha illallahu Rabbul-‘arshil-‘azeem, la ilaaha illallahu Rabbus-samaawaati wa Rabbul-ardi wa Rabbul-‘arshil-kareem", note: "The Prophet's dua at times of distress"),
            DuaItem(hadith: "tirmidhi:3524", cite: "Jaami‘ at-Tirmidhi 3524", arabic: 37...42, english: 11...22, transliteration: "Ya Hayyu ya Qayyoom, bi-rahmatika astagheeth", note: "Said by the Prophet ﷺ whenever a matter distressed him"),
            DuaItem(hadith: "tirmidhi:3505", cite: "Jaami‘ at-Tirmidhi 3505", arabic: 42...50, english: 17...34, transliteration: "La ilaaha illa anta subhaanaka inni kuntu minaz-zaalimeen", note: "The dua of Yoonus in the belly of the whale; no Muslim asks with it for anything except that Allah answers him"),
            DuaItem(hadith: "bukhari:6369", cite: "Saheeh al-Bukhaari 6369", arabic: 25...39, english: 6...36, transliteration: "Allahumma inni a‘oodhu bika minal-hammi wal-hazan, wal-‘ajzi wal-kasal, wal-jubni wal-bukhl, wa dala‘id-dayni wa ghalabatir-rijaal"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي عَبدُكَ ابنُ عَبدِكَ ابنُ أَمَتِكَ نَاصِيَتِي بِيَدِكَ مَاضٍ فِيَّ حُكمُكَ عَدلٌ فِيَّ قَضَاؤُكَ أَسأَلُكَ بِكُلِّ اسمٍ هُوَ لَكَ سَمَّيتَ بِهِ نَفسَكَ أَو أَنزَلتَهُ فِي كِتَابِكَ أَو عَلَّمتَهُ أَحَدًا مِن خَلقِكَ أَوِ استَأثَرتَ بِهِ فِي عِلمِ الغَيبِ عِندَكَ أَن تَجعَلَ القُرآنَ رَبِيعَ قَلبِي وَنُورَ صَدرِي وَجِلَاءَ حُزنِي وَذَهَابَ هَمِّي", transliteration: "Allahumma inni ‘abduka, ibnu ‘abdika, ibnu amatika, naasiyati biyadika, maadin fiyya hukmuka, ‘adlun fiyya qadaa’uka, as’aluka bikulli ismin huwa laka, sammayta bihi nafsaka, aw anzaltahu fi kitaabika, aw ‘allamtahu ahadan min khalqika, aw ista’tharta bihi fi ‘ilmil-ghaybi ‘indaka, an taj‘alal-Qur’aana rabee‘a qalbi, wa noora sadri, wa jilaa’a huzni, wa dhahaaba hammi", translation: "O Allah, I am Your servant, son of Your servant, son of Your maidservant. My forelock is in Your hand, Your command over me is ever executed, and Your decree over me is just. I ask You by every name that is Yours (with which You named Yourself, or revealed in Your Book, or taught to any of Your creation, or kept with Yourself in the knowledge of the unseen) that You make the Quran the spring of my heart, the light of my chest, the departure of my sorrow, and the passing of my worry. (Whoever says it, Allah removes his sorrow and grief and replaces them with joy)", reference: "Musnad Ahmad 3712; graded saheeh by al-Albaani, as-Silsilah as-Saheehah 199"),
            DuaItem(quran: "3:173", words: 13...16, transliteration: "Hasbunallahu wa ni‘mal-wakeel", translation: "Sufficient for us is Allah, and [He is] the best Disposer of affairs.", note: "Said by Ibraaheem when he was thrown into the fire, and by Muhammad ﷺ when told that the people had gathered against him (Saheeh al-Bukhaari 4563)"),
            DuaItem(hadith: "muslim:2704a", cite: "Saheeh Muslim 2704; Saheeh al-Bukhaari 6384", arabic: 96...101, english: 124...134, transliteration: "La hawla wa la quwwata illa billah", note: "A treasure from the treasures of Paradise")
        ]
    )

    static let travel = DuaCollection(
        title: "Travel",
        subtitle: "Duas for setting out, the road, and returning home",
        systemImage: "airplane",
        introductionTitle: "Travel Duas",
        introduction: String(localized: "From mounting the ride to returning home, the Prophet ﷺ wrapped the whole journey in remembrance. \"...that you may settle yourselves upon their backs and then remember the favor of your Lord.\" (Quran 43:13)"),
        items: [
            DuaItem(hadith: "muslim:1342", cite: "Saheeh Muslim 1342", arabic: 44...56, english: 0...30, transliteration: "Subhaanal-ladhi sakhkhara lana haadha wa ma kunna lahu muqrineen, wa inna ila Rabbina lamunqaliboon", note: "Said after Allahu Akbar three times, when mounted for travel"),
            DuaItem(hadith: "muslim:1342", cite: "Saheeh Muslim 1342", arabic: 57...84, english: 31...78, transliteration: "Allahumma inna nas’aluka fi safarina haadhal-birra wat-taqwa, wa minal-‘amali ma tarda. Allahumma hawwin ‘alayna safarana haadha watwi ‘anna bu‘dah. Allahumma antas-saahibu fis-safari wal-khaleefatu fil-ahl"),
            DuaItem(hadith: "muslim:1342", cite: "Saheeh Muslim 1342", arabic: 85...98, english: 79...105, transliteration: "Allahumma inni a‘oodhu bika min wa‘thaa’is-safari, wa ka’aabatil-manzari, wa soo’il-munqalabi fil-maali wal-ahl"),
            DuaItem(hadith: "muslim:1342", cite: "Saheeh Muslim 1342", arabic: 108...112, english: 120...129, transliteration: "Aayiboona, taa’iboona, ‘aabidoona, li-Rabbina haamidoon", note: "Added when returning from the journey"),
            DuaItem(hadith: "muslim:2708a", cite: "Saheeh Muslim 2708", arabic: 63...70, english: 16...32, transliteration: "A‘oodhu bikalimaatillahit-taammaati min sharri ma khalaq", note: "Whoever says it when stopping at a place, nothing will harm him until he moves on"),
            DuaItem(hadith: "abudawud:2600", cite: "Sunan Abi Daawood 2600", arabic: 35...40, english: 19...33, transliteration: "Astawdi‘ullaha deenaka wa amaanataka wa khawaateema ‘amalik", note: "The Prophet's farewell to a departing traveler")
        ]
    )

    static let homeMosque = DuaCollection(
        title: "Home & Mosque",
        subtitle: "Duas for stepping out, coming home, and the masjid",
        systemImage: "door.left.hand.open",
        introductionTitle: "Home & Mosque Duas",
        introduction: String(localized: "The Prophet ﷺ marked every threshold with remembrance: leaving in Allah's care, returning with His name, and entering His house asking for His mercy."),
        items: [
            DuaItem(hadith: "abudawud:5095", cite: "Sunan Abi Daawood 5095", arabic: 38...48, english: 14...32, transliteration: "Bismillah, tawakkaltu ‘alallah, la hawla wa la quwwata illa billah", note: "On leaving the home; it is said to him: you are guided, defended and protected"),
            DuaItem(hadith: "abudawud:5094", cite: "Sunan Abi Daawood 5094; graded saheeh by al-Albaani", arabic: 32...52, english: 20...54, transliteration: "Allahumma inni a‘oodhu bika an adilla aw udall, aw azilla aw uzall, aw azlima aw uzlam, aw ajhala aw yujhala ‘alayy", note: "On leaving the home"),
            DuaItem(hadith: "muslim:713a", cite: "Saheeh Muslim 713", arabic: 43...47, english: 11...20, transliteration: "Allahumma-ftah li abwaaba rahmatik", note: "On entering the masjid"),
            DuaItem(hadith: "muslim:713a", cite: "Saheeh Muslim 713", arabic: 52...56, english: 29...36, transliteration: "Allahumma inni as’aluka min fadlik", note: "On leaving the masjid"),
            DuaItem(hadith: "abudawud:466", cite: "Sunan Abi Daawood 466", arabic: 51...60, english: 34...54, transliteration: "A‘oodhu billahil-‘Azeem, wa biwajhihil-kareem, wa sultaanihil-qadeem, minash-shaytaanir-rajeem", note: "On entering the masjid; the devil says: he is protected from me all the day long")
        ]
    )

    static let foodDrink = DuaCollection(
        title: "Food & Drink",
        subtitle: "Duas before, during, and after eating and drinking",
        systemImage: "fork.knife",
        introductionTitle: "Food & Drink Duas",
        introduction: String(localized: "\"O messengers, eat from the good foods and work righteousness.\" (Quran 23:51) The sunnah surrounds every meal with Allah's name and gratitude for His provision."),
        items: [
            DuaItem(hadith: "bukhari:5376", cite: "Saheeh al-Bukhaari 5376", arabic: 49...57, english: 31...53, transliteration: "Ya ghulaam, sammi Allah, wa kul bi-yameenik, wa kul mimma yaleek", note: "Before eating: say Bismillah"),
            DuaItem(hadith: "abudawud:3767", cite: "Sunan Abi Daawood 3767", arabic: 64...67, english: 29...42, transliteration: "Bismillahi awwalahu wa aakhirah", note: "If one forgot to say Bismillah before starting"),
            DuaItem(hadith: "abudawud:4023", cite: "Sunan Abi Daawood 4023", arabic: 43...55, english: 11...34, transliteration: "Alhamdu lillahil-ladhi at‘amani haadhat-ta‘aama wa razaqaneehi min ghayri hawlin minni wa la quwwah", note: "After eating"),
            DuaItem(hadith: "tirmidhi:3455", cite: "Jaami‘ at-Tirmidhi 3455; graded hasan by al-Albaani", arabic: 100...105, english: 125...136, transliteration: "Allahumma baarik lana feehi wa zidna minhu", note: "On drinking milk"),
            DuaItem(hadith: "abudawud:2357", cite: "Sunan Abi Daawood 2357", arabic: 51...59, english: 32...46, transliteration: "Dhahabaz-zama’u wabtallatil-‘urooqu wa thabatal-ajru in shaa’ Allah", note: "When breaking the fast")
        ]
    )

    static let forgiveness = DuaCollection(
        title: "Forgiveness & Repentance",
        subtitle: "Seeking Allah's pardon, as the Prophet did daily",
        systemImage: "arrow.uturn.backward.circle",
        introductionTitle: "Forgiveness & Repentance Duas",
        introduction: String(localized: "The Prophet ﷺ, though forgiven, sought Allah's forgiveness dozens of times a day, and taught his companions to do the same. \"And whoever does a wrong or wrongs himself but then seeks forgiveness of Allah will find Allah Forgiving and Merciful.\" (Quran 4:110)"),
        items: [
            DuaItem(hadith: "abudawud:1516", cite: "Sunan Abi Daawood 1516", arabic: 37...45, english: 16...29, transliteration: "Rabbi-ghfir li wa tub ‘alayya, innaka antat-Tawwaabur-Raheem", note: "The Prophet ﷺ was counted saying it a hundred times in a single gathering"),
            DuaItem(hadith: "bukhari:834", cite: "Saheeh al-Bukhaari 834", arabic: 47...67, english: 49...82, transliteration: "Allahumma inni zalamtu nafsi zulman katheeran, wa la yaghfirudh-dhunooba illa anta, faghfir li maghfiratan min ‘indika, warhamni, innaka antal-Ghafoorur-Raheem", note: "Taught by the Prophet ﷺ to Abu Bakr to say in prayer"),
            DuaItem(hadith: "abudawud:1517", cite: "Sunan Abi Daawood 1517", arabic: 46...56, english: 7...28, transliteration: "Astaghfirullahal-ladhi la ilaaha illa huwal-Hayyul-Qayyoomu wa atoobu ilayh", note: "Whoever says it is forgiven, even if he had fled from battle"),
            DuaItem(hadith: "muslim:483", cite: "Saheeh Muslim 483", arabic: 43...53, english: 11...26, transliteration: "Allahumma-ghfir li dhanbi kullah, diqqahu wa jillah, wa awwalahu wa aakhirah, wa ‘alaaniyatahu wa sirrah", note: "Said by the Prophet ﷺ in prostration"),
            DuaItem(hadith: "abudawud:4859", cite: "Sunan Abi Daawood 4859", arabic: 48...59, english: 20...51, transliteration: "Subhaanakallahumma wa bihamdika, ashhadu an la ilaaha illa anta, astaghfiruka wa atoobu ilayk", note: "Said on rising from a gathering, an expiation for whatever happened in it")
        ]
    )

    static let prophets = DuaCollection(
        title: "Duas of the Prophets",
        subtitle: "Supplications of the prophets recorded in the Quran",
        systemImage: "sparkles",
        introductionTitle: "Duas of the Prophets",
        introduction: String(localized: "The Quran preserves the very words the prophets called upon their Lord with (in illness, loneliness, need, and gratitude), and every one was answered. \"So We responded to him...\" (Quran 21:84)"),
        items: [
            DuaItem(quran: "21:83", words: 5...10, transliteration: "Anni massaniyad-durru wa anta arhamur-raahimeen", translation: "Indeed, adversity has touched me, and you are the Most Merciful of the merciful.", note: "Ayyoob, in his affliction; Allah answered him and removed it"),
            DuaItem(quran: "21:89", words: 4...10, transliteration: "Rabbi la tadharni fardan wa anta khayrul-waaritheen", translation: "My Lord, do not leave me alone [with no heir], while you are the best of inheritors.", note: "Zakariyya, asking for a child; and he was given Yahya"),
            DuaItem(quran: "27:19", words: 5...23, transliteration: "Rabbi awzi‘ni an ashkura ni‘matakal-lati an‘amta ‘alayya wa ‘ala waalidayya wa an a‘mala saalihan tardaahu wa adkhilni birahmatika fi ‘ibaadikas-saaliheen", translation: "My Lord, enable me to be grateful for Your favor which You have bestowed upon me and upon my parents and to do righteousness of which You approve. And admit me by Your mercy into [the ranks of] Your righteous servants.", note: "Sulaymaan, on hearing the ant"),
            DuaItem(quran: "28:24", words: 7...14, transliteration: "Rabbi inni lima anzalta ilayya min khayrin faqeer", translation: "My Lord, indeed I am, for whatever good You would send down to me, in need.", note: "Moosa, alone and destitute in Madyan; and he was soon given shelter, work, and family"),
            DuaItem(quran: "71:28", words: 0...9, transliteration: "Rabbi-ghfir li wa liwaalidayya wa liman dakhala baytiya mu’minan wa lil-mu’mineena wal-mu’minaat", translation: "My Lord, forgive me and my parents and whoever enters my house a believer and the believing men and believing women.", note: "Nooh"),
            DuaItem(quran: "26:83", transliteration: "Rabbi hab li hukman wa alhiqni bis-saaliheen", note: "Ibraaheem")
        ]
    )

    static let rabbana = DuaCollection(
        title: "40 Rabbana Duas",
        subtitle: "Quranic duas beginning with Rabbana",
        systemImage: "40.circle",
        introductionTitle: "40 Rabbana Duas",
        introduction: String(localized: "رَبَّنَا (Rabbana) means \"Our Lord.\" These Quranic supplications begin by calling on Allah with that intimate address, then ask for forgiveness, guidance, mercy, patience, protection, victory, provision, and success in this life and the Hereafter."),
        // Each entry carries ONLY its own supplication, not the whole ayah it sits in. Many of these duas are a
        // clause inside a longer verse ("and among them are those who say..."), and three ayahs (2:286, 3:193,
        // 59:10) hold more than one dua. Storing the full ayah on every entry made the same Arabic render two or
        // three times in a row, and made the block long enough to be cut off.
        items: [
            DuaItem(quran: "2:127", words: 7...13, transliteration: "Rabbana taqabbal minna innaka antas-Samee‘ul-‘Aleem", translation: "Our Lord, accept [this] from us. Indeed You are the Hearing, the Knowing."),
            DuaItem(quran: "2:128", transliteration: "Rabbana waj‘alna muslimayni laka wa min dhurriyyaatina ummatan muslimatan laka wa arina manaasikana wa tub ‘alayna innaka antat-Tawwaabur-Raheem"),
            // The same ayah as Common Duas' 2:201, in the same words: its own identity keeps the two rows apart
            // wherever every dua is listed at once (search).
            { var dua = DuaItem(quran: "2:201", words: 3...13, transliteration: "Rabbana aatina fid-dunya hasanatan wa fil-aakhirati hasanatan wa qina ‘adhaaban-naar", translation: "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire."); dua.identity = "rabbana-2:201"; return dua }(),
            DuaItem(quran: "2:250", words: 5...14, transliteration: "Rabbana afrigh ‘alayna sabran wa thabbit aqdaamana wansurna ‘alal-qawmil-kaafireen", translation: "Our Lord, pour upon us patience and plant firmly our feet and give us victory over the disbelieving people."),
            DuaItem(quran: "2:286", words: 12...18, transliteration: "Rabbana la tu’aakhidhna in naseena aw akhta’na", translation: "Our Lord, do not impose blame upon us if we have forgotten or erred."),
            DuaItem(quran: "2:286", words: 19...29, transliteration: "Rabbana wa la tahmil ‘alayna isran kama hamaltahu ‘alal-ladheena min qablina", translation: "Our Lord, and lay not upon us a burden like that which You laid upon those before us."),
            DuaItem(quran: "2:286", words: 30...48, transliteration: "Rabbana wa la tuhammilna ma la taaqata lana bih; wa‘fu ‘anna waghfir lana warhamna; anta mawlaana fansurna ‘alal-qawmil-kaafireen", translation: "Our Lord, and burden us not with that which we have no ability to bear. And pardon us; and forgive us; and have mercy upon us. You are our protector, so give us victory over the disbelieving people."),
            DuaItem(quran: "3:8", transliteration: "Rabbana la tuzigh quloobana ba‘da idh hadaytana wa hab lana min ladunka rahmah; innaka antal-Wahhaab"),
            DuaItem(quran: "3:9", transliteration: "Rabbana innaka jaami‘un-nasi liyawmin la rayba feeh; innallaha la yukhliful-mee‘aad"),
            DuaItem(quran: "3:16", words: 2...10, transliteration: "Rabbana innana aamanna faghfir lana dhunoobana wa qina ‘adhaaban-naar", translation: "Our Lord, indeed we have believed, so forgive us our sins and protect us from the punishment of the Fire"),
            DuaItem(quran: "3:53", transliteration: "Rabbana aamanna bima anzalta wattaba‘nar-rasoola faktubna ma‘ash-shaahideen"),
            DuaItem(quran: "3:147", words: 6...18, transliteration: "Rabbanagh-fir lana dhunoobana wa israafana fi amrina wa thabbit aqdaamana wansurna ‘alal-qawmil-kaafireen", translation: "Our Lord, forgive us our sins and the excess [committed] in our affairs and plant firmly our feet and give us victory over the disbelieving people."),
            DuaItem(quran: "3:191", words: 12...20, transliteration: "Rabbana ma khalaqta haadha baatilan subhaanaka faqina ‘adhaaban-naar", translation: "Our Lord, You did not create this aimlessly; exalted are You [above such a thing]; then protect us from the punishment of the Fire."),
            DuaItem(quran: "3:192", transliteration: "Rabbana innaka man tudkhilin-naara faqad akhzaytah; wa ma liz-zaalimeena min ansaar"),
            DuaItem(quran: "3:193", words: 0...9, transliteration: "Rabbana innana sami‘na munaadiyan yunaadi lil-eemaani an aaminu bi-Rabbikum fa-aamanna", translation: "Our Lord, indeed we have heard a caller calling to faith, [saying], 'Believe in your Lord,' and we have believed."),
            DuaItem(quran: "3:193", words: 10...19, transliteration: "Rabbana faghfir lana dhunoobana wa kaffir ‘anna sayyi’aatina wa tawaffana ma‘al-abraar", translation: "Our Lord, so forgive us our sins and remove from us our misdeeds and cause us to die with the righteous."),
            DuaItem(quran: "3:194", transliteration: "Rabbana wa aatina ma wa‘adtana ‘ala rusulika wa la tukhzina yawmal-qiyaamah; innaka la tukhliful-mee‘aad"),
            DuaItem(quran: "5:83", words: 16...20, transliteration: "Rabbana aamanna faktubna ma‘ash-shaahideen", translation: "Our Lord, we have believed, so register us among the witnesses."),
            DuaItem(quran: "5:114", words: 4...21, transliteration: "Allahumma Rabbana anzil ‘alayna maa’idatan minas-samaa’i takoonu lana ‘eedan li-awwalina wa aakhirina wa aayatan minka warzuqna wa anta khayrur-raaziqeen", translation: "O Allah, our Lord, send down to us a table [spread with food] from the heaven to be for us a festival for the first of us and the last of us and a sign from You. And provide for us, and You are the best of providers."),
            DuaItem(quran: "7:23", words: 1...11, transliteration: "Rabbana zalamna anfusana wa in lam taghfir lana wa tarhamna lanakoonanna minal-khaasireen", translation: "Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers."),
            DuaItem(quran: "7:47", words: 8...13, transliteration: "Rabbana la taj‘alna ma‘al-qawmiz-zaalimeen", translation: "Our Lord, do not place us with the wrongdoing people."),
            DuaItem(quran: "7:89", words: 33...41, transliteration: "Rabbanaf-tah baynana wa bayna qawmina bil-haqqi wa anta khayrul-faatiheen", translation: "Our Lord, decide between us and our people in truth, and You are the best of those who give decision."),
            DuaItem(quran: "7:126", words: 10...15, transliteration: "Rabbana afrigh ‘alayna sabran wa tawaffana muslimeen", translation: "Our Lord, pour upon us patience and let us die as Muslims [in submission to You]."),
            DuaItem(quran: "10:85-86", words: 4...14, transliteration: "Rabbana la taj‘alna fitnatan lil-qawmiz-zaalimeen; wa najjina birahmatika minal-qawmil-kaafireen", translation: "Our Lord, make us not [objects of] trial for the wrongdoing people And save us by Your mercy from the disbelieving people."),
            DuaItem(quran: "14:38", transliteration: "Rabbana innaka ta‘lamu ma nukhfi wa ma nu‘lin; wa ma yakhfa ‘alallahi min shay’in fil-ardi wa la fis-samaa’"),
            DuaItem(quran: "14:40", transliteration: "Rabbij-‘alni muqeemas-salaati wa min dhurriyyati, Rabbana wa taqabbal du‘aa’"),
            DuaItem(quran: "14:41", transliteration: "Rabbanagh-fir li wa liwaalidayya wa lil-mu’mineena yawma yaqoomul-hisaab"),
            DuaItem(quran: "18:10", words: 6...15, transliteration: "Rabbana aatina min ladunka rahmatan wa hayyi’ lana min amrina rashada", translation: "Our Lord, grant us from Yourself mercy and prepare for us from our affair right guidance."),
            DuaItem(quran: "20:45", words: 1...9, transliteration: "Rabbana innana nakhaafu an yafruta ‘alayna aw an yatgha", translation: "Our Lord, indeed we are afraid that he will hasten [punishment] against us or that he will transgress."),
            DuaItem(quran: "23:109", words: 6...13, transliteration: "Rabbana aamanna faghfir lana warhamna wa anta khayrur-raahimeen", translation: "Our Lord, we have believed, so forgive us and have mercy upon us, and You are the best of the merciful."),
            DuaItem(quran: "25:65-66", words: 2...14, transliteration: "Rabbanas-rif ‘anna ‘adhaaba jahannam; inna ‘adhaabaha kaana gharaama; innaha saa’at mustaqarran wa muqaama", translation: "Our Lord, avert from us the punishment of Hell. Indeed, its punishment is ever adhering; Indeed, it is evil as a settlement and residence."),
            DuaItem(quran: "25:74", words: 2...12, transliteration: "Rabbana hab lana min azwaajina wa dhurriyyaatina qurrata a‘yunin waj‘alna lil-muttaqeena imaama", translation: "Our Lord, grant us from among our wives and offspring comfort to our eyes and make us an example for the righteous."),
            DuaItem(quran: "35:34", words: 7...10, transliteration: "Inna Rabbana la-Ghafoorun Shakoor", translation: "Indeed, our Lord is Forgiving and Appreciative"),
            DuaItem(quran: "40:7", words: 13...26, transliteration: "Rabbana wasi‘ta kulla shay’in rahmatan wa ‘ilman faghfir lilladheena taabu wattaba‘u sabeelaka wa qihim ‘adhaabal-jaheem", translation: "Our Lord, You have encompassed all things in mercy and knowledge, so forgive those who have repented and followed Your way and protect them from the punishment of Hellfire."),
            DuaItem(quran: "40:8-9", words: 0...17, transliteration: "Rabbana wa adkhilhum jannaati ‘adninil-lati wa‘adtahum wa man salaha min aabaa’ihim wa azwaajihim wa dhurriyyaatihim, innaka antal-‘Azeezul-Hakeem, wa qihimus-sayyi’aat", translation: "Our Lord, and admit them to gardens of perpetual residence which You have promised them and whoever was righteous among their fathers, their spouses and their offspring. Indeed, it is You who is the Exalted in Might, the Wise. And protect them from the evil consequences [of their deeds]."),
            DuaItem(quran: "59:10", words: 5...18, transliteration: "Rabbanagh-fir lana wa li-ikhwaaninal-ladheena sabaqoona bil-eemaani wa la taj‘al fi quloobina ghillan lilladheena aamanu", translation: "Our Lord, forgive us and our brothers who preceded us in faith and put not in our hearts [any] resentment toward those who have believed."),
            DuaItem(quran: "59:10", words: 19...22, transliteration: "Rabbana innaka Ra’oofur-Raheem", translation: "Our Lord, indeed You are Kind and Merciful."),
            DuaItem(quran: "60:4", words: 45...51, transliteration: "Rabbana ‘alayka tawakkalna wa ilayka anabna wa ilaykal-maseer", translation: "Our Lord, upon You we have relied, and to You we have returned, and to You is the destination."),
            DuaItem(quran: "60:5", transliteration: "Rabbana la taj‘alna fitnatan lilladheena kafaru waghfir lana Rabbana, innaka antal-‘Azeezul-Hakeem"),
            DuaItem(quran: "66:8", words: 34...44, transliteration: "Rabbana atmim lana noorana waghfir lana, innaka ‘ala kulli shay’in qadeer", translation: "Our Lord, perfect for us our light and forgive us. Indeed, You are over all things competent.")
        ]
    )
}

#Preview {
    AlIslamPreviewContainer {
        DuaView()
    }
}

// MARK: - Hisn al-Muslim

#if os(iOS)
/// The Fortress of the Muslim (Hisn al-Muslim, Sa'id ibn Ali ibn Wahf al-Qahtani): 268 supplications
/// in 132 situations, with the 14 collections the day is read by (morning, evening, after salah,
/// before sleep, travel, food...). From `Resources/Data/Islam/HisnDuas.json.xz`
/// (Scripts/build_hisn_duas.py), the islamic.app Dhikr API import Tilawa ships, with hisnmuslim.com
/// recitations. Ported from Tilawa (Jamil Hammoudeh, with permission).
final class HisnDuasStore: @unchecked Sendable {
    static let shared = HisnDuasStore()
    private init() {}

    struct Category: Identifiable {
        let id: String
        let number: String
        let label: String
        let arabic: String
        let count: Int

        /// The label as the reader sees it: the book's own Arabic chapter title in the Arabic
        /// interface (as the Today screen shows it). `label` stays the English data.
        var displayLabel: String { AppLanguage.isArabicScript && !arabic.isEmpty ? arabic : label.localizedDisplay }
        /// The situation's row id in the library's list, where the situation rail jumps.
        var railRowID: String { "hisn-situation-\(id)" }
    }

    struct Collection: Identifiable {
        let id: String
        let label: String
        let arabic: String
        let subtitle: String
        let icon: String
        let entryIDs: [String]
        let categoryNumbers: [String]

        /// The label as the reader sees it (`Category.displayLabel`'s rule).
        var displayLabel: String { AppLanguage.isArabicScript && !arabic.isEmpty ? arabic : label.localizedDisplay }

        /// The shelf's SF symbol (the pack carries Tilawa's icon keys).
        var systemImage: String {
            switch icon {
            case "sunrise": return "sunrise.fill"
            case "sunset": return "sunset.fill"
            case "prayer": return "hands.and.sparkles.fill"
            case "moon": return "moon.stars.fill"
            case "book": return "book.fill"
            case "landmark": return "building.columns.fill"
            case "travel": return "airplane"
            case "food": return "fork.knife"
            case "home": return "house.fill"
            case "heart": return "heart.fill"
            case "shield": return "shield.fill"
            case "hand": return "hand.raised.fill"
            case "compass": return "location.north.circle.fill"
            default: return "text.book.closed.fill"
            }
        }
    }

    struct Entry: Identifiable {
        let id: String
        let number: String
        let categoryID: String
        let title: String
        let arabic: String
        let transliteration: String
        let translation: String
        let notes: String
        let benefits: String
        let repeatCount: Int
        let reference: String
        let audio: URL?

        /// "Recite 3x · Muslim 4/2083": what the row prints under the dua. Display only (the pack's
        /// `reference` stays as written).
        var sourceLine: String {
            var parts: [String] = []
            if repeatCount > 1 { parts.append(String(localized: "Recite \(repeatCount)x")) }
            else if !notes.isEmpty, notes != "Recite 1x" { parts.append(notes) }
            if !reference.isEmpty { parts.append(reference) }
            return parts.joined(separator: " · ")
        }

        var asDuaItem: DuaItem {
            var item = DuaItem(arabicText: arabic, transliteration: transliteration, translation: translation,
                               reference: sourceLine.isEmpty ? nil : sourceLine)
            item.audioURL = audio
            item.identity = id
            return item
        }
    }

    struct Library {
        let categories: [Category]
        let collections: [Collection]
        let entries: [Entry]
        let entriesByCategory: [String: [Entry]]
        let entryByID: [String: Entry]
    }

    private let lock = NSLock()
    private var library: Library?
    private var loadFailed = false

    /// The pack lands flat in the bundle (Xcode copies loose resources without their folder), so the
    /// lookup falls through the same chain the Miracles pack uses.
    static var packURL: URL? {
        Bundle.main.url(forResource: "HisnDuas", withExtension: "json.xz", subdirectory: "Data/Islam")
            ?? Bundle.main.url(forResource: "HisnDuas", withExtension: "json.xz", subdirectory: "Islam")
            ?? Bundle.main.url(forResource: "HisnDuas", withExtension: "json.xz")
    }

    static let isBundled: Bool = packURL != nil

    /// The library if it is in memory, else nil: for the main thread, which must never parse (the
    /// Reminder of the Day resolver kicks the parse off-main itself and asks again when it lands).
    var libraryIfLoaded: Library? {
        lock.lock(); defer { lock.unlock() }
        return library
    }

    func loaded() -> Library? {
        lock.lock()
        if let library { lock.unlock(); return library }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()
        let parsed = Self.load()
        lock.lock(); defer { lock.unlock() }
        if let library { return library }
        if let parsed { library = parsed } else { loadFailed = true }
        return parsed
    }

    /// The day's dua, rotating through the whole book.
    func duaOfTheDay() -> Entry? {
        guard let library = loaded(), !library.entries.isEmpty else { return nil }
        // The daily-rollover day (Fajr by default), shared with every other "of the day" feature.
        let day = Settings.shared.dailyDayIndex()
        return library.entries[((day * 7) % library.entries.count + library.entries.count) % library.entries.count]
    }

    private static func load() -> Library? {
        PackTrace.measure("HisnDuas") { () -> (result: Library?, bytes: Int) in
            guard let url = packURL,
                  let blob = try? Data(contentsOf: url),
                  let json = SolidPack.xzDecompress(blob) else { return (nil, 0) }
            return (parse(json), json.count)
        }
    }

    /// The source's "transliteration" is, for some twenty of the 268 entries, not a transliteration
    /// at all but a second English rendering with the Arabic phrases transliterated inline ("The most
    /// excellent invocation is: Alhamdulillah and the most excellent words of remembrance are: La
    /// ilaha illallah"), so the Dua screen and the Reminder of the Day showed the same text twice
    /// (Abu, 2026-09-16: "why are there 2 of the same texts?"). One is dropped when, bracketed notes
    /// aside, it carries English function words and most of its words also appear in the translation.
    static func genuineTransliteration(_ transliteration: String, translation: String) -> String {
        let bare = transliteration.replacingOccurrences(of: #"\[[^\]]*\]"#, with: " ", options: .regularExpression)
        let words = bare.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { $0.count >= 3 }
        guard !words.isEmpty else { return transliteration }
        let english: Set<String> = ["the", "and", "for", "you", "who", "when", "whoever", "said", "say",
                                    "then", "should", "his", "him", "will", "that", "this", "one", "any",
                                    "with", "from", "are", "was", "used", "not", "your"]
        let functionWords = words.filter { english.contains($0) }.count
        guard functionWords >= 3 else { return transliteration }
        let translated = Set(translation.lowercased().components(separatedBy: CharacterSet.letters.inverted))
        let shared = words.filter { translated.contains($0) }.count
        return Double(shared) / Double(words.count) > 0.5 ? "" : transliteration
    }

    private static func parse(_ json: Data) -> Library? {
        guard let root = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any] else { return nil }
        let categories = (root["categories"] as? [[String: Any]] ?? []).compactMap { row -> Category? in
            guard let id = row["id"] as? String, let label = row["label"] as? String else { return nil }
            return Category(id: id, number: row["number"] as? String ?? "", label: label,
                            arabic: row["arabic"] as? String ?? "", count: row["count"] as? Int ?? 0)
        }
        let collections = (root["collections"] as? [[String: Any]] ?? []).compactMap { row -> Collection? in
            guard let id = row["id"] as? String, let label = row["label"] as? String else { return nil }
            return Collection(id: id, label: label, arabic: row["arabic"] as? String ?? "",
                              subtitle: row["subtitle"] as? String ?? "", icon: row["icon"] as? String ?? "",
                              entryIDs: row["entryIds"] as? [String] ?? [],
                              categoryNumbers: row["categoryNumbers"] as? [String] ?? [])
        }
        let entries = (root["entries"] as? [[String: Any]] ?? []).compactMap { row -> Entry? in
            guard let id = row["id"] as? String, let arabic = row["arabic"] as? String, !arabic.isEmpty else { return nil }
            return Entry(id: id, number: row["number"] as? String ?? "", categoryID: row["category"] as? String ?? "",
                         title: row["title"] as? String ?? "", arabic: arabic,
                         transliteration: Self.genuineTransliteration(row["transliteration"] as? String ?? "",
                                                                     translation: row["translation"] as? String ?? ""),
                         translation: row["translation"] as? String ?? "", notes: row["notes"] as? String ?? "",
                         benefits: row["benefits"] as? String ?? "", repeatCount: row["repeat"] as? Int ?? 1,
                         reference: row["reference"] as? String ?? "",
                         audio: (row["audio"] as? String).flatMap { $0.isEmpty ? nil : URL(string: $0) })
        }
        guard !entries.isEmpty else { return nil }
        var byCategory: [String: [Entry]] = [:]
        for entry in entries { byCategory[entry.categoryID, default: []].append(entry) }
        return Library(categories: categories, collections: collections, entries: entries,
                       entriesByCategory: byCategory,
                       entryByID: Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }))
    }
}

/// One recitation at a time, streamed from hisnmuslim.com; the play button on a dua row.
@MainActor
final class HisnDuaPlayer: ObservableObject {
    static let shared = HisnDuaPlayer()
    @Published private(set) var playingURL: URL?
    @Published private(set) var isLoading = false
    private var player: AVPlayer?
    private var endObserver: Any?
    private var statusObservation: NSKeyValueObservation?

    private init() {
        ObjectPublishCounter.attach(self, label: "HisnDuaPlayer")
    }

    func toggle(_ url: URL) {
        if playingURL == url {
            stop()
            return
        }
        stop()
        // A playing surah pauses and the qiraat clip stops first (`AuxiliaryAudio`); a dua is short.
        AuxiliaryAudio.prepareToPlay(stopping: { QiraatClipPlayer.shared.stop() })
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        playingURL = url
        isLoading = true
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.stop() }
        }
        // The spinner follows the item's status (a fixed 0.8 s used to clear it while a slow stream
        // was still buffering, and hold it after a fast one had begun).
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self, self.player?.currentItem === item else { return }
                if item.status == .failed { self.stop() }
                if item.status == .readyToPlay { self.isLoading = false }
            }
        }
        player.play()
    }

    func stop() {
        player?.pause()
        player = nil
        playingURL = nil
        isLoading = false
        statusObservation = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
    }
}

/// The play control under a Hisn dua: the recitation from hisnmuslim.com, streamed on demand.
struct HisnDuaAudioButton: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var player = HisnDuaPlayer.shared
    let url: URL

    var body: some View {
        let playing = player.playingURL == url
        Button {
            settings.hapticFeedback()
            player.toggle(url)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: playing ? "stop.fill" : "play.fill")
                    .font(.caption2)
                Text(playing ? String(localized: "Stop") : String(localized: "Recitation"))
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(playing ? .white : settings.accentColor.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(playing ? settings.accentColor.color : settings.accentColor.color.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playing ? String(localized: "Stop the recitation") : String(localized: "Play the recitation"))
    }
}

// MARK: - Grid mode

/// The grid / list button the Dua screens put in their toolbar, before the Islam Settings gear: the
/// one the 99 Names, the Alphabet and a hadith book carry (Abu, 2026-11-26: "Support grid mode for
/// dua and Hisn al Muslim"). Each screen owns its choice, a grid until it is changed, as everywhere.
struct DuaGridModeButton: View {
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @Binding var gridMode: Bool

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            withAnimation { gridMode.toggle() }
        } label: {
            Image(systemName: gridMode ? "list.bullet" : "square.grid.2x2")
        }
        .accessibilityLabel(gridMode ? String(localized: "Show list") : String(localized: "Show grid"))
        .tint(Settings.shared.accentColor.accent2)
    }
}

/// A shelf of duas as a grid tile (a collection on the Dua screen, one of Hisn al-Muslim's shelves of
/// the day): the row's own chip, title, caption and count, stacked and centred like every tile that
/// is not a passage. A tap opens it, a hold offers the row's menu.
struct DuaShelfTile: View {
    let title: String
    let systemImage: String
    let caption: String?
    let count: Int
    /// Lines the caption may take: a collection's is a sentence, a shelf's its name in Arabic.
    var captionLines = 3
    let open: () -> Void

    var body: some View {
        GridTileMenu {
            Settings.shared.hapticFeedback()
            open()
        } menu: {
            DuaTileMenuItems(title: title)
        } label: {
            VStack(spacing: 5) {
                AccentIconChip(systemImage: systemImage, size: 32)

                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                if let caption, !caption.isEmpty {
                    Text(caption)
                        .font(.caption2)
                        .foregroundColor(.secondaryOnGlass)
                        .lineLimit(captionLines)
                }
            }
            .multilineTextAlignment(.center)
            // Its lines are the tile's height: a row of tiles is as tall as its tallest (the grid's
            // own rule) and each fills it from the top, so a caption is never squeezed to fit a
            // fixed box and the chips of a row stand level whatever their captions run to.
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            // The count in the trailing corner, where the row keeps it. A bare figure, as a tile
            // writes its counts (a hadith chapter's): three across, the row's pill sat on the chip.
            .overlay(alignment: .topTrailing) {
                Text("\(count)")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundColor(.secondaryOnGlass)
                    .padding(.top, 9)
                    .padding(.trailing, 11)
                    .hiddenInSimple(.sectionCounts)
            }
            .contentShape(Rectangle())
        }
        .contentSurface(clear: true, rectangle: true, inRow: true)
    }
}

/// One of Hisn al-Muslim's 132 situations as a grid tile: its number and its count in the corners
/// the row keeps them at, the title on as many lines as it needs (half of them run past thirty
/// letters), the book's own Arabic chapter title beneath.
struct HisnSituationTile: View {
    @Environment(\.appearance) private var appearance
    let category: HisnDuasStore.Category
    let open: () -> Void

    var body: some View {
        GridTileMenu {
            Settings.shared.hapticFeedback()
            open()
        } menu: {
            DuaTileMenuItems(title: category.displayLabel)
        } label: {
            VStack(spacing: 3) {
                HStack {
                    Text(category.number.localizedDigits)
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundColor(appearance.accent)

                    Spacer(minLength: 4)

                    Text("\(category.count)")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundColor(.secondaryOnGlass)
                        .hiddenInSimple(.sectionCounts)
                }

                Spacer(minLength: 0)

                Text(category.displayLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(4)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                // The Arabic title once: in the Arabic interface it IS the title.
                if category.displayLabel != category.arabic, !category.arabic.isEmpty {
                    Text(category.arabic)
                        .font(.caption)
                        .foregroundColor(.secondaryOnGlass)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: 78)
            .contentShape(Rectangle())
        }
        .contentSurface(clear: true, rectangle: true, inRow: true)
    }
}

/// What a dua tile's hold offers: its name, and the name to copy (the collection row's own menu).
private struct DuaTileMenuItems: View {
    let title: String

    var body: some View {
        Text(title)
            .foregroundStyle(.secondary)

        Button {
            Settings.shared.hapticFeedback()
            UIPasteboard.general.string = title
        } label: {
            Label("Copy Title", systemImage: "doc.on.doc")
        }
    }
}

/// The library's root: the 14 collections of the day, then every situation the book covers.
struct HisnDuaLibraryView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @State private var searchText = ""
    /// The book, from the first frame when it is in memory, which it is by the time the Dua page's
    /// row can be tapped (that page loads it to show the row at all). It used to start nil and be
    /// fetched from `.task` regardless, so every open drew a spinner first (Abu, 2026-11-13: "When
    /// page first opens there's a progress view I don't want"). Only a door that reaches this page
    /// before the Dua page ever loaded (Ask AI's) still waits on the parse, off the main thread.
    @State private var library: HisnDuasStore.Library? = HisnDuasStore.shared.libraryIfLoaded
    /// The situations and duas matching the settled query: from `.onChange` (150 ms after the last
    /// keystroke) and the library's arrival, never from the body, which re-folded every row per evaluation.
    @State private var shownCategories: [HisnDuasStore.Category] = HisnDuasStore.shared.libraryIfLoaded?.categories ?? []
    @State private var shownMatches: [HisnDuasStore.Entry] = []
    @State private var filterTask: Task<Void, Never>?
    /// The shelves and the situations as tiles or as rows: this screen's own choice, a grid until
    /// it is changed (Abu, 2026-11-26: "Support grid mode for dua and Hisn al Muslim").
    @AppStorage("hisnGridMode") private var gridMode = true
    /// The shelf or situation a tile opened. One door for the whole grid: a link per tile would
    /// push every tile of its row at once.
    @State private var pushedCollection: DuaCollection?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Tiles while nothing is typed; a search shows ROWS, as search results are everywhere.
    private var showsGrid: Bool { gridMode && query.isEmpty }
    /// The shelves of the day run three across like the Islam tab's resources (their names are a
    /// word or two), two at the accessibility sizes.
    private var shelfColumns: Int { dynamicTypeSize.isAccessibilitySize ? 2 : 3 }
    /// The situations' columns, on every width: their names are sentences.
    private static let situationColumns = 2
    /// A situation grid row's id, where the situation rail lands in grid mode: the index of its
    /// first tile.
    private static func situationGridRowID(_ start: Int) -> String { "hisn-situation-row-\(start)" }

    private var accent: Color { settings.accentColor.color }
    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// A category as one of the dua screen's collections, so its page is the same page every other
    /// collection opens (rows, search, listen-all, the walkthrough).
    static func collection(for category: HisnDuasStore.Category, library: HisnDuasStore.Library) -> DuaCollection {
        let entries = library.entriesByCategory[category.id] ?? []
        return DuaCollection(
            title: category.label,
            subtitle: category.arabic,
            systemImage: "text.book.closed.fill",
            introductionTitle: "From Hisn al-Muslim",
            // The situation's label is the pack's English (the collection's title and id): shown in
            // the reader's language, the sentence around it as a whole.
            introduction: entries.count == 1
                ? String(localized: "\(category.displayLabel): one supplication from the Fortress of the Muslim, with the reference each is narrated from. Tap the play pill under a dua to hear it recited.")
                : String(localized: "\(category.displayLabel): \(entries.count) supplications from the Fortress of the Muslim, with the reference each is narrated from. Tap the play pill under a dua to hear it recited."),
            items: entries.map(\.asDuaItem),
            localTitle: category.displayLabel
        )
    }

    static func collection(for shelf: HisnDuasStore.Collection, library: HisnDuasStore.Library) -> DuaCollection {
        let entries = shelf.entryIDs.compactMap { library.entryByID[$0] }
        return DuaCollection(
            title: shelf.label,
            subtitle: shelf.arabic,
            systemImage: shelf.systemImage,
            introductionTitle: shelf.label,
            introduction: shelf.subtitle.isEmpty
                ? String(localized: "\(entries.count) supplications from Hisn al-Muslim.")
                : shelf.subtitle.localizedDisplay,
            items: entries.map(\.asDuaItem),
            localTitle: shelf.displayLabel
        )
    }

    var body: some View {
        let _ = RenderCounter.hit("HisnDuaLibraryView")
        #if os(iOS)
        // The situations' numbers down the edge (1, 5, 10 ... 130, 132); not while searching.
        let railItems = query.isEmpty ? Self.situationRailItems(shownCategories) : []
        #endif
        ScrollViewReader { proxy in
        List {
            Group {
                if let library {
                    if query.isEmpty {
                        Section(header: Text("THE FORTRESS OF THE MUSLIM")) {
                            ArticleLead(String(localized: "Hisn al-Muslim, the pocket book of supplications compiled by Sa‘eed ibn Ali ibn Wahf al-Qahtaani from the Quran and the authentic Sunnah: \(library.entries.count) duas for \(library.categories.count) situations, each with its reference, and a recitation to follow along with."),
                                        eyebrow: String(localized: "IN SHORT"))
                        }

                        Section(header: SectionPillHeader(title: String(localized: "THROUGH THE DAY"), count: library.collections.count)) {
                            if showsGrid {
                                shelfTiles(library)
                            } else {
                                ForEach(library.collections) { shelf in
                                    NavigationLink(destination: LazyDestination { DuaCollectionView(collection: Self.collection(for: shelf, library: library)) }) {
                                        // The Arabic title once: in the Arabic interface it IS the title.
                                        SettingsRowLabel(
                                            title: shelf.displayLabel,
                                            systemImage: shelf.systemImage,
                                            subtitle: shelf.displayLabel != shelf.arabic ? shelf.arabic : nil,
                                            accessory: AnyView(CountPill(count: shelf.entryIDs.count))
                                        )
                                    }
                                }
                            }
                        }
                    }

                    let categories = shownCategories
                    let matches = shownMatches

                    if !query.isEmpty, !matches.isEmpty {
                        Section(header: SectionPillHeader(title: String(localized: "MATCHING DUAS"), count: matches.count)) {
                            ForEach(matches.prefix(30)) { entry in
                                NavigationLink(destination: LazyDestination {
                                    DuaCollectionView(collection: Self.collection(for: library.categories.first { $0.id == entry.categoryID } ?? HisnDuasStore.Category(id: entry.categoryID, number: "", label: entry.title, arabic: "", count: 1), library: library))
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(library.categories.first { $0.id == entry.categoryID }?.displayLabel ?? entry.title)
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(accent)
                                        HighlightedSnippet(source: entry.translation, term: searchText, font: .subheadline, accent: accent, fg: .primary)
                                            .lineLimit(3)
                                            .leftToRightContent()
                                    }
                                }
                            }
                        }
                    }

                    Section(header: SectionPillHeader(title: String(localized: "EVERY SITUATION"), count: categories.count)) {
                        if categories.isEmpty, matches.isEmpty {
                            Text("No duas match your search.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if showsGrid {
                            situationTiles(categories, library: library)
                        } else {
                            // Identified by the rail's row id: an `.id` on the link itself never
                            // reached the List, so a jump to it did nothing.
                            ForEach(categories, id: \.railRowID) { category in
                                NavigationLink(destination: LazyDestination { DuaCollectionView(collection: Self.collection(for: category, library: library)) }) {
                                    HStack(spacing: 10) {
                                        Text(category.number.localizedDigits)
                                            .font(.caption2.weight(.semibold).monospacedDigit())
                                            .foregroundStyle(.secondary)
                                            .frame(width: 30, alignment: .leading)
                                        VStack(alignment: .leading, spacing: 2) {
                                            HighlightedSnippet(source: category.displayLabel, term: searchText, font: .subheadline, accent: accent, fg: .primary)
                                            // The Arabic title once, in the Arabic interface.
                                            if category.displayLabel != category.arabic {
                                                Text(category.arabic)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer(minLength: 8)
                                        Text("\(category.count)")
                                            .font(.caption2.weight(.semibold).monospacedDigit())
                                            .foregroundStyle(.secondary)
                                            .hiddenInSimple(.sectionCounts)
                                    }
                                }
                            }
                        }
                    }

                    if query.isEmpty {
                        Section(footer:
                            Text("Hisn al-Muslim texts and references from the islamic.app Dhikr API; recitations by hisnmuslim.com. Ported from the Tilawa app by Jamil Hammoudeh, with permission.")
                        ) { EmptyView() }
                    }
                } else {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        .jumpIndexRailRoom(railItems)
        #endif
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .compactListSectionSpacing()
        #if os(iOS)
        .jumpIndexRail(railItems, accessibilityName: String(localized: "Situation index"), proxy: proxy) { item -> String? in
            guard shownCategories.indices.contains(item.id) else { return nil }
            let chunk = tileGridChunk(columns: Self.situationColumns)
            return showsGrid
                ? Self.situationGridRowID(item.id - item.id % chunk)
                : shownCategories[item.id].railRowID
        }
        #endif
        }
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: String(localized: "Search Hisn al-Muslim"))
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        .navigationTitle("Hisn al-Muslim")
        .navigationBarTitleDisplayMode(.inline)
        // The grid toggle, then the Islam Settings gear: a hadith book's chapters carry the same pair.
        .islamSettingsToolbar { DuaGridModeButton(gridMode: $gridMode) }
        .pushDestination(item: $pushedCollection) { DuaCollectionView(collection: $0) }
        .onChange(of: searchText) { _ in scheduleFilter() }
        .task {
            guard library == nil else { return }
            library = await Task.detached(priority: .userInitiated) { HisnDuasStore.shared.loaded() }.value
            applyFilter()
        }
    }

    /// The shelves of the day as tiles, one grid row per List row (`tileGridChunk`).
    @ViewBuilder
    private func shelfTiles(_ library: HisnDuasStore.Library) -> some View {
        let shelves = library.collections
        let columns = shelfColumns
        let chunk = tileGridChunk(columns: columns)
        ForEach(Array(stride(from: 0, to: shelves.count, by: chunk)), id: \.self) { start in
            SummaryTileGrid(columns: columns) {
                ForEach(shelves[start..<min(start + chunk, shelves.count)]) { shelf in
                    DuaShelfTile(title: shelf.displayLabel,
                                 systemImage: shelf.systemImage,
                                 // The Arabic title once: in the Arabic interface it IS the title.
                                 caption: shelf.displayLabel != shelf.arabic ? shelf.arabic : nil,
                                 count: shelf.entryIDs.count,
                                 captionLines: 1) {
                        if pushedCollection == nil { pushedCollection = Self.collection(for: shelf, library: library) }
                    }
                }
            }
            .tileGridChunkRow(start: start, count: shelves.count, chunk: chunk)
        }
    }

    /// Every situation as a tile, one grid row per List row, each row with an id the situation
    /// rail lands on (a tile's own id is unknown to the List until its row is built).
    @ViewBuilder
    private func situationTiles(_ categories: [HisnDuasStore.Category], library: HisnDuasStore.Library) -> some View {
        let chunk = tileGridChunk(columns: Self.situationColumns)
        ForEach(Array(stride(from: 0, to: categories.count, by: chunk)), id: \.self) { start in
            SummaryTileGrid(columns: Self.situationColumns) {
                ForEach(categories[start..<min(start + chunk, categories.count)]) { category in
                    HisnSituationTile(category: category) {
                        if pushedCollection == nil { pushedCollection = Self.collection(for: category, library: library) }
                    }
                }
            }
            .tileGridChunkRow(start: start, count: categories.count, chunk: chunk)
            .id(Self.situationGridRowID(start))
        }
    }

    #if os(iOS)
    /// The situation rail's stops by al-Qahtani's chapter numbers, for 40 situations or more. Counted
    /// by place instead should a number ever be missing or out of order.
    private static func situationRailItems(_ categories: [HisnDuasStore.Category]) -> [JumpIndexItem] {
        guard categories.count >= 40 else { return [] }
        let printed = categories.compactMap { Int($0.number) }
        let numbers = printed.count == categories.count && printed == printed.sorted() ? printed : Array(1...categories.count)
        return JumpIndexItem.numberedStops(numbers) { categories[$0].displayLabel }
    }
    #endif

    private static func filter(_ library: HisnDuasStore.Library?, query: String) -> (categories: [HisnDuasStore.Category], matches: [HisnDuasStore.Entry]) {
        guard let library else { return ([], []) }
        guard !query.isEmpty else { return (library.categories, []) }
        let categories = SearchRank.sorted(library.categories.filter { category in
            (category.label + " " + category.arabic).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(query)
        }, by: query) { [$0.label, $0.arabic] }
        let matches = library.entries.filter { entry in
            (entry.translation + " " + entry.transliteration + " " + entry.arabic)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(query)
        }
        return (categories, matches)
    }

    private func applyFilter() {
        let result = Self.filter(library, query: query)
        shownCategories = result.categories
        shownMatches = result.matches
    }

    private func scheduleFilter() {
        filterTask?.cancel()
        filterTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            applyFilter()
        }
    }
}

/// The day's dua from Hisn al-Muslim, on the dua screen's front page.
/// Where the Dua of the Day card's buttons lead; the host List pushes it (one destination per List).
enum HisnDuaCardDoor {
    case dailyHub
    case collection(DuaCollection)
}

struct HisnDuaOfTheDayCard: View {
    private let settings = Settings.shared
    @Environment(\.layoutDirection) private var layoutDirection
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    let entry: HisnDuasStore.Entry
    let category: HisnDuasStore.Category?
    let library: HisnDuasStore.Library
    /// Opens a door; the card holds no links of its own (a List row may hold one at most).
    let open: (HisnDuaCardDoor) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill")
                Text("DUA OF THE DAY")
                Spacer()
                if let category {
                    Text(category.displayLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                // Everything of the day on one screen (2026-09-16): the door every daily card carries,
                // chevron-less so the row keeps its edge clean.
                Button {
                    settings.hapticFeedback()
                    open(.dailyHub)
                } label: {
                    DailyHubDoorLabel()
                }
                .buttonStyle(.borderless)
                .hiddenInSimple(.cardTodayPills)
            }
            .font(.caption2.weight(.bold))
            .foregroundColor(settings.accentColor.color)

            Text.islamArabic(entry.arabic, highlightAllah: settings.highlightAllahNamesIslam)
                .font(.custom(settings.nonQuranArabicFontName, size: 24))
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                // The Arabic sits on the right in both interfaces: there the leading edge is the right.
                .multilineTextAlignment(layoutDirection == .rightToLeft ? .leading : .trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: layoutDirection == .rightToLeft ? .leading : .trailing)
                .fixedSize(horizontal: false, vertical: true)

            Text(entry.translation)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
                .leftToRightContent()

            HStack {
                if !entry.sourceLine.isEmpty {
                    Text(entry.sourceLine)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if let audio = entry.audio {
                    HisnDuaAudioButton(url: audio)
                }
            }

            if let category {
                Button {
                    settings.hapticFeedback()
                    open(.collection(HisnDuaLibraryView.collection(for: category, library: library)))
                } label: {
                    Label("More duas for this situation", systemImage: "arrow.forward.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 6)
        .textSelection(.enabled)
    }
}
#endif
