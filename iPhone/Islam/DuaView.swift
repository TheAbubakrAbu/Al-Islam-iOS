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
        /// A narration on the app's own shelf (`HadithQuote.swift`): a token range of the row's matn,
        /// and of its translation where the dua says what the shelf's translation says.
        case shelf(link: String, arabic: ClosedRange<Int>, english: ClosedRange<Int>?)
    }

    /// Set when the dua's words are a reference; nil when they are its own text.
    var source: Source? = nil

    /// A dua that is Quran: the words come from the Quran this app ships, never from a copy here.
    /// `translation` is Tilawa's own rendering where it has one, and nil where the reader's own
    /// translation is what the dua says.
    init(quran reference: String, words: ClosedRange<Int>? = nil, transliteration: String,
         translation: String? = nil) {
        self.init(arabicText: "", transliteration: transliteration, translation: translation ?? "",
                  reference: reference)
        source = .quran(reference: reference, words: words)
    }

    /// A dua that is a narration on the app's own shelf. `cite` is the citation the row displays.
    init(hadith link: String, cite: String, arabic: ClosedRange<Int>, english: ClosedRange<Int>? = nil,
         transliteration: String, translation: String? = nil) {
        self.init(arabicText: "", transliteration: transliteration, translation: translation ?? "",
                  reference: cite)
        source = .shelf(link: link, arabic: arabic, english: english)
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
        case let .shelf(link, arabicRange, englishRange):
            guard let parsed = HadithQuoteReference(link), let row = HadithQuoteSource.read(parsed) else { return self }
            arabic = WordRange.words(row.arabic, arabicRange)
            if english.isEmpty, let englishRange { english = WordRange.words(row.text, englishRange) }
        }
        var filled = DuaItem(arabicText: arabic, transliteration: transliteration, translation: english,
                             reference: reference)
        filled.audioURL = audioURL
        filled.identity = id       // the id the unresolved item had, so rows and search keys hold
        filled.source = source
        return filled
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
    let title: String
    let subtitle: String
    let systemImage: String
    let introductionTitle: String
    let introduction: String
    let items: [DuaItem]

    var id: String { title }

    /// The collection with every referenced dua's words filled in from the app's own Quran and shelf.
    func resolved() -> DuaCollection {
        DuaCollection(title: title, subtitle: subtitle, systemImage: systemImage,
                      introductionTitle: introductionTitle, introduction: introduction,
                      items: items.map { $0.resolved() })
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
        Task { [weak self] in
            // The Quran text is what most of these duas are; wait for it rather than resolve to
            // nothing. (Already loaded on any launch that has shown the Quran tab: returns at once.)
            await QuranQuoteSource.waitUntilReady()
            let filled = await Task.detached(priority: .userInitiated) {
                DuaLibrary.authored.map { $0.resolved() }
            }.value
            guard let self else { return }
            self.collections = filled
            self.allItems = filled.flatMap(\.items)
        }
    }
}

struct DuaView: View {
    @ObservedObject var settings = Settings.shared

    @State private var searchText = ""
    #if os(iOS)
    /// The "About" card's single open door (one @State + one destination on the List:
    /// every chip lives in the SAME List row, and two links in one row both fire).
    @State private var aboutDoor: SignsAboutDoor?
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
        return collections.filter {
            $0.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(normalizedQuery)
                || $0.subtitle.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(normalizedQuery)
        }
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
        engine.prepare(corpusID: semanticCorpusID, version: "v1-\(texts.count)", texts: texts, keys: keys)
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
            Section(header: Text("SUPPLICATIONS TO ALLAH")) {
                Text("Short, daily supplications that keep your heart connected to Allah in every situation. \"Call upon Me; I will respond to you.\" (Quran 40:60)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
            }

            #if os(iOS)
            // Hisn al-Muslim: the whole Fortress, and today's dua from it.
            if HisnDuasStore.isBundled {
                if let hisnLibrary, let today = HisnDuasStore.shared.duaOfTheDay() {
                    Section {
                        HisnDuaOfTheDayCard(entry: today, category: hisnLibrary.categories.first { $0.id == today.categoryID }, library: hisnLibrary)
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
                        HStack(spacing: 12) {
                            AccentIconChip(systemImage: "shield.lefthalf.filled")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Fortress of the Muslim")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("268 duas for 132 situations, with references and recitations")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 8)
                            Text("حِصنُ المُسلِمِ")
                                .font(.custom(settings.nonQuranArabicFontName, size: 16))
                                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                                .foregroundStyle(settings.accentColor.color)
                        }
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
                             ? "No duas match your search."
                             : "No keyword matches; see the AI results above.")
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
                            // The Islam tab's resource-row grammar: an accent chip for the icon, the
                            // title and its one-line subtitle, and the collection's size as a count
                            // pill - so the shelf reads as a set of books rather than a plain menu.
                            HStack(spacing: 12) {
                                AccentIconChip(systemImage: collection.systemImage)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(collection.title)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)

                                    Text(collection.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 8)

                                Text("\(collection.items.count)")
                                    .font(.caption.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(settings.accentColor.color)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(settings.accentColor.color.opacity(0.12)))
                            }
                            .padding(.vertical, 3)
                        }
                        .id(Self.collectionRowID(collection))
                        #if os(iOS)
                        .contextMenu {
                            Text(collection.title)
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
                                UIPasteboard.general.string = collection.title
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
                            source: item.reference,
                            onScrollTo: Self.collection(of: item).map { collection in
                                { scrollToCollection(collection) }
                            },
                            scrollLabel: "Scroll To Collection"
                        )
                        .equatable()
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
                        "Dua is worship. (Abu Dawud 1479; Tirmidhi 3247, sahih)",
                        "No Muslim supplicates, so long as it is not for sin or for severing kinship, but Allah gives him one of three: the answer is hastened, it is stored for him in the Hereafter, or an equivalent evil is turned away from him. (Musnad Ahmad 11133, hasan)"
                    ],
                    accent: settings.accentColor.color
                )
            }

                Section {
                    SpeechQualityHint()
                }
            }
                #if os(iOS)
                AboutSignsSection(heading: "About Dua",
                                  systemImage: "text.book.closed",
                                  doors: [.makeDua, .allah, .tawhid],
                                  openDoor: $aboutDoor)
                #endif
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
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
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        #if os(iOS)
        .aboutSignsDestination($aboutDoor)
        #endif
        .navigationTitle("Dua & Supplications")
        #if os(iOS)
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
        scrollTarget = Self.collectionRowID(collection)
    }
}

/// Internal, not private: the Today screen (DailyHub.swift) opens the Dua of the Day's category here.
struct DuaCollectionView: View {
    @ObservedObject var settings = Settings.shared
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
                Section(header: SectionPillHeader(title: "AI MATCHES", count: aiHits.count, icon: "sparkles", accentTitle: true)) {
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
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle(collection.title)
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
            Text(collection.introduction)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    private func duaRows(_ shown: [DuaItem], scrollable: Bool = true) -> some View {
        let searching = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return Section(header: duasHeader(shown)) {
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
                    source: item.reference,
                    rowID: scrollable ? item.id : nil,
                    // Only while searching: with the whole collection showing, the row is already where it lives.
                    onScrollTo: (searching && scrollable) ? {
                        withAnimation { searchText = "" }
                        scrollTarget = item.id
                    } : nil,
                    scrollLabel: "Scroll To Dua"
                )
                .equatable()

                #if os(iOS)
                // The Hisn al-Muslim rows carry a recitation: the play pill sits under the dua.
                if let audio = item.audioURL {
                    HisnDuaAudioButton(url: audio)
                        .padding(.top, -4)
                        .padding(.bottom, 4)
                }
                #endif
            }
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
        introduction: "Short, daily supplications that keep your heart connected to Allah in every situation. \"Call upon Me; I will respond to you.\" (Quran 40:60)",
        items: [
            DuaItem(hadith: "muslim:2739", cite: "Sahih Muslim 2739", arabic: 42...54, transliteration: "Allahumma inni a'udhu bika min zawali ni'matika wa tahawwuli 'afiyatika wa fuja'ati niqmatika wa jamee'i sakhatika", translation: "O Allah, I seek refuge in You from the removal of Your blessings, changing of Your protection, sudden wrath, and all of Your displeasure"),
            DuaItem(hadith: "ibnmajah:3871", cite: "Sunan Ibn Majah 3871", arabic: 44...51, transliteration: "Allahumma inni as'aluka al-'afwa wal-'afiyah fi ad-dunya wal-akhirah", translation: "O Allah, I ask You for forgiveness and well-being in this life and the hereafter"),
            DuaItem(hadith: "muslim:2721a", cite: "Sahih Muslim 2721", arabic: 34...40, transliteration: "Allahumma inni as'aluka al-huda wa at-tuqaa wal-'afaafa wal-ghina", translation: "O Allah, I ask You for guidance, righteousness, chastity, and sufficiency"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الكُفرِ وَالفَقرِ وَأَعُوذُ بِكَ مِن عَذَابِ القَبرِ", transliteration: "Allahumma inni a'udhu bika min al-kufr wal-faqr wa a'udhu bika min 'adhab al-qabr", translation: "O Allah, I seek refuge in You from disbelief, poverty, and the punishment of the grave", reference: "Sunan Abi Dawud 5090"),
            DuaItem(arabicText: "اللَّهُمَّ مَا أَصبَحَ بِي مِن نِعمَةٍ أَو بِأَحَدٍ مِن خَلقِكَ فَمِنكَ وَحدَكَ لَا شَرِيكَ لَكَ فَلَكَ الحَمدُ وَلَكَ الشُّكرُ", transliteration: "Allahumma ma asbaha bi min ni'matin, aw bi ahadin min khalqika, faminka wahdaka la sharika laka, falaka alhamdu wa laka ash-shukr", translation: "O Allah, whatever blessings I or any of Your creatures rose up with, is from You alone, without partner, so for You is all praise and unto You all thanks.", reference: "Sunan Abi Dawud 5073"),
            DuaItem(quran: "20:25-26", words: 1...7, transliteration: "Rabbi ishrah li sadri wa yassir li amri", translation: "O my Lord, expand for me my chest, and ease for me my task."),
            DuaItem(hadith: "abudawud:1522", cite: "Sunan Abi Dawud 1522", arabic: 67...73, transliteration: "Allahumma a'innee ala dhikrika wa shukrika wa husni ibadatika", translation: "O Allah, assist me in remembering You, in thanking You, and in worshipping You in the best manner."),
            DuaItem(quran: "2:201", words: 3...13, transliteration: "Rabbanaa atinaa fid-dunya hasanatan wa fil aakhirati hasanatan wa qinaa 'adhaaban-naar", translation: "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire."),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِن عَجزِ وَالكَسَلِ وَالجُبنِ وَالهَرَمِ وَالبُخلِ وَأَعُوذُ بِكَ مِن عَذَابِ القَبرِ وَمِن فِتنَةِ المَحيَا وَالمَمَاتِ", transliteration: "Allahumma inni a'udhu bika min al-'ajzi wal-kasali wal-jubni wal-harami wal-bukhli, wa a'udhu bika min 'adhab al-qabr, wa min fitnat al-mahya wal-mamat", translation: "O Allah, I seek refuge in You from incapacity and laziness, from cowardice and senility, and from miserliness. And I seek refuge in You from the punishment of the grave, and from the trials of life and death.", reference: "Sahih Muslim 2706"),
            DuaItem(hadith: "ibnmajah:925", cite: "Sunan Ibn Majah 925", arabic: 39...47, transliteration: "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbalan", translation: "O Allah, I ask You for knowledge that is of benefit, a good provision, and deeds that will be accepted."),
            DuaItem(quran: "2:255", transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fi as-samawati wa ma fi al-ard. Man dha allathee yashfa'u 'indahu illa bi-idhnihi? Ya'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bishay'in min 'ilmihi illa bima sha'. Wasi'a kursiyyuhu as-samawati wal-ard, wa la ya'uduhu hifzuhuma, wa Huwal 'Aliyyul-'Azim.", translation: "Allah: there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is [presently] before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.")
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
        introduction: "Remembrances the Prophet ﷺ said at the start and end of every day, seeking Allah's protection, provision, and pleasure before the day makes its own claims. \"And exalt [Allah] with praise of your Lord before the rising of the sun and before its setting.\" (Quran 20:130)",
        items: [
            DuaItem(hadith: "bukhari:6306", cite: "Sahih al-Bukhari 6306", arabic: 39...75, transliteration: "Allahumma anta Rabbi la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika ma istata'tu, a'udhu bika min sharri ma sana'tu, abu'u laka bini'matika 'alayya, wa abu'u laka bidhanbi faghfir li, fa innahu la yaghfiru adh-dhunuba illa anta", translation: "O Allah, You are my Lord; there is no god but You. You created me and I am Your servant, and I keep Your covenant and promise as much as I am able. I seek refuge in You from the evil of what I have done. I acknowledge before You Your blessing upon me, and I acknowledge my sin, so forgive me, for none forgives sins but You. (The master of seeking forgiveness; said morning and evening)"),
            DuaItem(arabicText: "أَمسَينَا وَأَمسَى المُلكُ لِلَّهِ وَالحَمدُ لِلَّهِ لَا إِلَهَ إِلَّا اللَّهُ وَحدَهُ لَا شَرِيكَ لَهُ لَهُ المُلكُ وَلَهُ الحَمدُ وَهُوَ عَلَى كُلِّ شَيءٍ قَدِيرٌ رَبِّ أَسأَلُكَ خَيرَ مَا فِي هَذِهِ اللَّيلَةِ وَخَيرَ مَا بَعدَهَا وَأَعُوذُ بِكَ مِن شَرِّ مَا فِي هَذِهِ اللَّيلَةِ وَشَرِّ مَا بَعدَهَا", transliteration: "Amsayna wa amsal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir. Rabbi as'aluka khayra ma fi hadhihil-laylati wa khayra ma ba'daha, wa a'udhu bika min sharri ma fi hadhihil-laylati wa sharri ma ba'daha", translation: "We have reached evening, and the dominion has reached evening belonging to Allah. Praise be to Allah; there is no god but Allah alone, without partner. His is the dominion and His is the praise, and He is able to do all things. My Lord, I ask You for the good of this night and the good of what follows it, and I seek refuge in You from the evil of this night and the evil of what follows it. (In the morning: 'Asbahna wa asbahal-mulku lillah... I ask You for the good of this day...')", reference: "Sahih Muslim 2723"),
            DuaItem(arabicText: "اللَّهُمَّ بِكَ أَصبَحنَا وَبِكَ أَمسَينَا وَبِكَ نَحيَا وَبِكَ نَمُوتُ وَإِلَيكَ النُّشُورُ", transliteration: "Allahumma bika asbahna wa bika amsayna wa bika nahya wa bika namutu wa ilaykan-nushur", translation: "O Allah, by You we reach the morning and by You we reach the evening; by You we live and by You we die, and to You is the resurrection. (In the evening it ends: '...and to You is the final return')", reference: "Jami' at-Tirmidhi 3391"),
            DuaItem(hadith: "abudawud:5088", cite: "Sunan Abi Dawud 5088", arabic: 34...49, transliteration: "Bismillahil-ladhi la yadurru ma'a ismihi shay'un fil-ardi wa la fis-sama'i wa huwas-Sami'ul-'Alim", translation: "In the name of Allah, with Whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, the All-Knowing. (Three times, morning and evening)"),
            DuaItem(arabicText: "رَضِيتُ بِاللَّهِ رَبًّا وَبِالإِسلَامِ دِينًا وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ نَبِيًّا", transliteration: "Raditu billahi Rabban, wa bil-Islami dinan, wa bi-Muhammadin sallallahu 'alayhi wa sallama nabiyya", translation: "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet. (Three times, morning and evening)", reference: "Sunan Abi Dawud 5072"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ العَافِيَةَ فِي الدُّنيَا وَالآخِرَةِ اللَّهُمَّ إِنِّي أَسأَلُكَ العَفوَ وَالعَافِيَةَ فِي دِينِي وَدُنيَايَ وَأَهلِي وَمَالِي اللَّهُمَّ استُر عَورَاتِي وَآمِن رَوعَاتِي اللَّهُمَّ احفَظنِي مِن بَينِ يَدَيَّ وَمِن خَلفِي وَعَن يَمِينِي وَعَن شِمَالِي وَمِن فَوقِي وَأَعُوذُ بِعَظَمَتِكَ أَن أُغتَالَ مِن تَحتِي", transliteration: "Allahumma inni as'alukal-'afiyata fid-dunya wal-akhirah. Allahumma inni as'alukal-'afwa wal-'afiyata fi dini wa dunyaya wa ahli wa mali. Allahumma-stur 'awrati wa amin raw'ati. Allahumma-hfazni min bayni yadayya wa min khalfi wa 'an yamini wa 'an shimali wa min fawqi, wa a'udhu bi'azamatika an ughtala min tahti", translation: "O Allah, I ask You for well-being in this world and the Hereafter. O Allah, I ask You for pardon and well-being in my religion, my worldly life, my family, and my wealth. O Allah, conceal my faults and calm my fears. O Allah, guard me from in front of me and behind me, from my right and my left, and from above me; and I seek refuge in Your greatness from being seized from beneath me.", reference: "Sunan Abi Dawud 5074"),
            DuaItem(hadith: "muslim:2692", cite: "Sahih Muslim 2692", arabic: 37...39, transliteration: "Subhanallahi wa bihamdih", translation: "Glory be to Allah and praise be to Him. (One hundred times: whoever says it morning and evening, no one brings anything better on the Day of Resurrection except one who said the same or more)"),
            DuaItem(hadith: "muslim:2726a", cite: "Sahih Muslim 2726", arabic: 91...101, transliteration: "Subhanallahi wa bihamdihi 'adada khalqihi wa rida nafsihi wa zinata 'arshihi wa midada kalimatih", translation: "Glory be to Allah and praise be to Him, as many as His creation, as much as pleases Him, as heavy as His Throne, and as much as the ink of His words. (Three times in the morning)"),
            DuaItem(hadith: "abudawud:5081", cite: "Sunan Abi Dawud 5081", arabic: 52...63, transliteration: "Hasbiyallahu la ilaha illa huwa, 'alayhi tawakkaltu, wa huwa Rabbul-'arshil-'azim", translation: "Allah is sufficient for me; there is no god but Him. In Him I put my trust, and He is the Lord of the Mighty Throne. (Seven times, morning and evening)"),
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
            DuaItem(hadith: "bukhari:6324", cite: "Sahih al-Bukhari 6324", arabic: 29...32, transliteration: "Bismika Allahumma amutu wa ahya", translation: "In Your name, O Allah, I die and I live. (Said when going to bed)"),
            DuaItem(hadith: "bukhari:6324", cite: "Sahih al-Bukhari 6324", arabic: 40...48, transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur", translation: "Praise be to Allah, Who gave us life after He caused us to die, and to Him is the resurrection. (Said upon waking)"),
            DuaItem(arabicText: "بِاسمِكَ رَبِّي وَضَعتُ جَنبِي وَبِكَ أَرفَعُهُ إِن أَمسَكتَ نَفسِي فَارحَمهَا وَإِن أَرسَلتَهَا فَاحفَظهَا بِمَا تَحفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ", transliteration: "Bismika Rabbi wada'tu janbi wa bika arfa'uh, in amsakta nafsi farhamha, wa in arsaltaha fahfazha bima tahfazu bihi 'ibadakas-salihin", translation: "In Your name, my Lord, I lay down my side, and by You I raise it. If You take my soul, have mercy on it; and if You release it, protect it with that with which You protect Your righteous servants.", reference: "Sahih al-Bukhari 6320"),
            DuaItem(arabicText: "اللَّهُمَّ أَسلَمتُ نَفسِي إِلَيكَ وَفَوَّضتُ أَمرِي إِلَيكَ وَوَجَّهتُ وَجهِي إِلَيكَ وَأَلجَأتُ ظَهرِي إِلَيكَ رَغبَةً وَرَهبَةً إِلَيكَ لَا مَلجَأَ وَلَا مَنجَا مِنكَ إِلَّا إِلَيكَ آمَنتُ بِكِتَابِكَ الَّذِي أَنزَلتَ وَبِنَبِيِّكَ الَّذِي أَرسَلتَ", transliteration: "Allahumma aslamtu nafsi ilayk, wa fawwadtu amri ilayk, wa wajjahtu wajhi ilayk, wa alja'tu zahri ilayk, raghbatan wa rahbatan ilayk, la malja'a wa la manja minka illa ilayk, amantu bikitabikal-ladhi anzalt, wa binabiyyikal-ladhi arsalt", translation: "O Allah, I surrender my soul to You, I entrust my affairs to You, I turn my face to You, and I rely completely on You, in hope and fear of You. There is no refuge and no escape from You except to You. I believe in Your Book which You revealed and Your Prophet whom You sent. (Whoever says it and dies that night, dies upon the natural faith)", reference: "Sahih al-Bukhari 6311"),
            DuaItem(arabicText: "سُبحَانَ اللَّهِ (ثَلَاثًا وَثَلَاثِينَ) وَالحَمدُ لِلَّهِ (ثَلَاثًا وَثَلَاثِينَ) وَاللَّهُ أَكبَرُ (أَربَعًا وَثَلَاثِينَ)", transliteration: "Subhanallah (33 times), Alhamdulillah (33 times), Allahu Akbar (34 times)", translation: "Glory be to Allah (33 times), praise be to Allah (33 times), Allah is the Greatest (34 times). The Prophet ﷺ taught it to Fatimah and Ali when they asked for a servant, saying it is better for them than a servant.", reference: "Sahih al-Bukhari 5362"),
            DuaItem(hadith: "abudawud:5045", cite: "Sunan Abi Dawud 5045", arabic: 43...48, transliteration: "Allahumma qini 'adhabaka yawma tab'athu 'ibadak", translation: "O Allah, protect me from Your punishment on the Day You resurrect Your servants. (Three times, lying on the right side)"),
            DuaItem(arabicText: "الحَمدُ لِلَّهِ الَّذِي أَطعَمَنَا وَسَقَانَا وَكَفَانَا وَآوَانَا فَكَم مِمَّن لَا كَافِيَ لَهُ وَلَا مُؤوِيَ", transliteration: "Alhamdu lillahil-ladhi at'amana wa saqana wa kafana wa awana, fakam mimman la kafiya lahu wa la mu'wi", translation: "Praise be to Allah, Who has fed us, given us drink, sufficed us, and sheltered us, for how many have none to suffice them or shelter them.", reference: "Sahih Muslim 2715"),
            DuaItem(hadith: "muslim:2712", cite: "Sahih Muslim 2712", arabic: 37...55, transliteration: "Allahumma khalaqta nafsi wa anta tawaffaha, laka mamatuha wa mahyaha, in ahyaytaha fahfazha, wa in amattaha faghfir laha. Allahumma inni as'alukal-'afiyah", translation: "O Allah, You created my soul and You take it back; to You belong its death and its life. If You keep it alive, protect it, and if You cause it to die, forgive it. O Allah, I ask You for well-being.")
        ]
    )

    static let distress = DuaCollection(
        title: "Distress & Anxiety",
        subtitle: "The Prophet's duas for worry, grief, and hardship",
        systemImage: "heart",
        introductionTitle: "Duas for Distress & Anxiety",
        introduction: "Supplications the Prophet ﷺ said (and taught) for the moments when the heart is tight and the way out is hidden. \"Is He not who responds to the desperate one when he calls upon Him, and removes evil?\" (Quran 27:62)",
        items: [
            DuaItem(arabicText: "لَا إِلَهَ إِلَّا اللَّهُ العَظِيمُ الحَلِيمُ لَا إِلَهَ إِلَّا اللَّهُ رَبُّ العَرشِ العَظِيمِ لَا إِلَهَ إِلَّا اللَّهُ رَبُّ السَّمَاوَاتِ وَرَبُّ الأَرضِ وَرَبُّ العَرشِ الكَرِيمِ", transliteration: "La ilaha illallahul-'Azimul-Halim, la ilaha illallahu Rabbul-'arshil-'azim, la ilaha illallahu Rabbus-samawati wa Rabbul-ardi wa Rabbul-'arshil-karim", translation: "There is no god but Allah, the Magnificent, the Forbearing. There is no god but Allah, Lord of the Mighty Throne. There is no god but Allah, Lord of the heavens, Lord of the earth, and Lord of the Noble Throne. (The Prophet's dua at times of distress)", reference: "Sahih al-Bukhari 6346"),
            DuaItem(hadith: "tirmidhi:3524", cite: "Jami' at-Tirmidhi 3524", arabic: 37...42, transliteration: "Ya Hayyu ya Qayyum, bi-rahmatika astaghith", translation: "O Ever-Living, O Sustainer of all, in Your mercy I seek relief. (Said by the Prophet ﷺ when a matter distressed him)"),
            DuaItem(hadith: "tirmidhi:3505", cite: "Jami' at-Tirmidhi 3505", arabic: 42...50, transliteration: "La ilaha illa anta subhanaka inni kuntu minaz-zalimin", translation: "There is no god but You; glory be to You. Indeed, I have been of the wrongdoers. (The dua of Yunus in the belly of the whale; no Muslim supplicates with it for anything except that Allah answers him)"),
            DuaItem(hadith: "bukhari:6369", cite: "Sahih al-Bukhari 6369", arabic: 25...39, transliteration: "Allahumma inni a'udhu bika minal-hammi wal-hazan, wal-'ajzi wal-kasal, wal-jubni wal-bukhl, wa dala'id-dayni wa ghalabatir-rijal", translation: "O Allah, I seek refuge in You from worry and grief, from incapacity and laziness, from cowardice and miserliness, from the burden of debt and from being overpowered by men."),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي عَبدُكَ ابنُ عَبدِكَ ابنُ أَمَتِكَ نَاصِيَتِي بِيَدِكَ مَاضٍ فِيَّ حُكمُكَ عَدلٌ فِيَّ قَضَاؤُكَ أَسأَلُكَ بِكُلِّ اسمٍ هُوَ لَكَ سَمَّيتَ بِهِ نَفسَكَ أَو أَنزَلتَهُ فِي كِتَابِكَ أَو عَلَّمتَهُ أَحَدًا مِن خَلقِكَ أَوِ استَأثَرتَ بِهِ فِي عِلمِ الغَيبِ عِندَكَ أَن تَجعَلَ القُرآنَ رَبِيعَ قَلبِي وَنُورَ صَدرِي وَجِلَاءَ حُزنِي وَذَهَابَ هَمِّي", transliteration: "Allahumma inni 'abduka, ibnu 'abdika, ibnu amatika, nasiyati biyadika, madin fiyya hukmuka, 'adlun fiyya qada'uka, as'aluka bikulli ismin huwa laka, sammayta bihi nafsaka, aw anzaltahu fi kitabika, aw 'allamtahu ahadan min khalqika, aw ista'tharta bihi fi 'ilmil-ghaybi 'indaka, an taj'alal-Qur'ana rabi'a qalbi, wa nura sadri, wa jila'a huzni, wa dhahaba hammi", translation: "O Allah, I am Your servant, son of Your servant, son of Your maidservant. My forelock is in Your hand, Your command over me is ever executed, and Your decree over me is just. I ask You by every name that is Yours (with which You named Yourself, or revealed in Your Book, or taught to any of Your creation, or kept with Yourself in the knowledge of the unseen) that You make the Quran the spring of my heart, the light of my chest, the departure of my sorrow, and the passing of my worry. (Whoever says it, Allah removes his sorrow and grief and replaces them with joy)", reference: "Musnad Ahmad 3712"),
            DuaItem(quran: "3:173", words: 13...16, transliteration: "Hasbunallahu wa ni'mal-wakil", translation: "Sufficient for us is Allah, and He is the best Disposer of affairs. (Said by Ibrahim when cast into the fire, and by the believers when threatened)"),
            DuaItem(hadith: "bukhari:6384", cite: "Sahih al-Bukhari 6384", arabic: 65...70, transliteration: "La hawla wa la quwwata illa billah", translation: "There is no power and no strength except through Allah. (A treasure from the treasures of Paradise)")
        ]
    )

    static let travel = DuaCollection(
        title: "Travel",
        subtitle: "Duas for setting out, the road, and returning home",
        systemImage: "airplane",
        introductionTitle: "Travel Duas",
        introduction: "From mounting the ride to returning home, the Prophet ﷺ wrapped the whole journey in remembrance. \"...that you may settle yourselves upon their backs and then remember the favor of your Lord.\" (Quran 43:13)",
        items: [
            DuaItem(hadith: "muslim:1342", cite: "Sahih Muslim 1342", arabic: 44...56, transliteration: "Subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila Rabbina lamunqalibun", translation: "Glory be to the One who subjected this to us, for we could never have accomplished it ourselves; and indeed, to our Lord we shall return. (Said after Allahu Akbar three times, when mounted for travel)"),
            DuaItem(hadith: "muslim:1342", cite: "Sahih Muslim 1342", arabic: 57...84, transliteration: "Allahumma inna nas'aluka fi safarina hadhal-birra wat-taqwa, wa minal-'amali ma tarda. Allahumma hawwin 'alayna safarana hadha watwi 'anna bu'dah. Allahumma antas-sahibu fis-safari wal-khalifatu fil-ahl", translation: "O Allah, we ask You on this journey of ours for righteousness and taqwa, and for deeds that please You. O Allah, make this journey easy for us and fold up its distance for us. O Allah, You are the Companion on the journey and the Guardian over the family left behind."),
            DuaItem(hadith: "muslim:1342", cite: "Sahih Muslim 1342", arabic: 85...98, transliteration: "Allahumma inni a'udhu bika min wa'tha'is-safari, wa ka'abatil-manzari, wa su'il-munqalabi fil-mali wal-ahl", translation: "O Allah, I seek refuge in You from the hardships of travel, from a grievous sight, and from an ill turn of fortune in wealth and family."),
            DuaItem(hadith: "muslim:1342", cite: "Sahih Muslim 1342", arabic: 108...112, transliteration: "Ayibuna, ta'ibuna, 'abiduna, li-Rabbina hamidun", translation: "We return, repentant, worshipping, and praising our Lord. (Added when returning from the journey)"),
            DuaItem(hadith: "muslim:2708a", cite: "Sahih Muslim 2708", arabic: 63...70, transliteration: "A'udhu bikalimatillahit-tammati min sharri ma khalaq", translation: "I seek refuge in the perfect words of Allah from the evil of what He has created. (Whoever says it when stopping at a place, nothing will harm him until he departs from it)"),
            DuaItem(hadith: "abudawud:2600", cite: "Sunan Abi Dawud 2600", arabic: 35...40, transliteration: "Astawdi'ullaha dinaka wa amanataka wa khawatima 'amalik", translation: "I entrust to Allah your religion, your trusts, and the final outcome of your deeds. (The Prophet's farewell to a departing traveler)")
        ]
    )

    static let homeMosque = DuaCollection(
        title: "Home & Mosque",
        subtitle: "Duas for stepping out, coming home, and the masjid",
        systemImage: "door.left.hand.open",
        introductionTitle: "Home & Mosque Duas",
        introduction: "The Prophet ﷺ marked every threshold with remembrance: leaving in Allah's care, returning with His name, and entering His house asking for His mercy.",
        items: [
            DuaItem(arabicText: "بِسمِ اللَّهِ تَوَكَّلتُ عَلَى اللَّهِ وَلَا حَولَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "Bismillahi tawakkaltu 'alallah, wa la hawla wa la quwwata illa billah", translation: "In the name of Allah, I place my trust in Allah, and there is no power and no strength except through Allah. (On leaving the home, it is said to him: you are guided, sufficed, and protected)", reference: "Sunan Abi Dawud 5095"),
            DuaItem(hadith: "abudawud:5094", cite: "Sunan Abi Dawud 5094", arabic: 32...52, transliteration: "Allahumma inni a'udhu bika an adilla aw udall, aw azilla aw uzall, aw azlima aw uzlam, aw ajhala aw yujhala 'alayy", translation: "O Allah, I seek refuge in You from going astray or being led astray, from slipping or being made to slip, from wronging or being wronged, and from acting ignorantly or being treated with ignorance. (On leaving the home)"),
            DuaItem(hadith: "muslim:713a", cite: "Sahih Muslim 713", arabic: 43...47, transliteration: "Allahumma-ftah li abwaba rahmatik", translation: "O Allah, open for me the doors of Your mercy. (On entering the masjid)"),
            DuaItem(hadith: "muslim:713a", cite: "Sahih Muslim 713", arabic: 52...56, transliteration: "Allahumma inni as'aluka min fadlik", translation: "O Allah, I ask You of Your bounty. (On leaving the masjid)"),
            DuaItem(hadith: "abudawud:466", cite: "Sunan Abi Dawud 466", arabic: 51...60, transliteration: "A'udhu billahil-'Azim, wa biwajhihil-karim, wa sultanihil-qadim, minash-shaytanir-rajim", translation: "I seek refuge in Allah the Magnificent, in His Noble Face and His eternal authority, from the accursed Shaytan. (On entering the masjid, Shaytan says: he is protected from me for the rest of the day)")
        ]
    )

    static let foodDrink = DuaCollection(
        title: "Food & Drink",
        subtitle: "Duas before, during, and after eating and drinking",
        systemImage: "fork.knife",
        introductionTitle: "Food & Drink Duas",
        introduction: "\"O messengers, eat from the good foods and work righteousness.\" (Quran 23:51) The sunnah surrounds every meal with Allah's name and gratitude for His provision.",
        items: [
            DuaItem(arabicText: "بِسمِ اللَّهِ", transliteration: "Bismillah", translation: "In the name of Allah. (Before eating: 'Mention Allah's name, eat with your right hand, and eat from what is nearest to you')", reference: "Sahih al-Bukhari 5376"),
            DuaItem(hadith: "abudawud:3767", cite: "Sunan Abi Dawud 3767", arabic: 64...67, transliteration: "Bismillahi awwalahu wa akhirah", translation: "In the name of Allah, at its beginning and its end. (If one forgot to say Bismillah before starting)"),
            DuaItem(arabicText: "الحَمدُ لِلَّهِ الَّذِي أَطعَمَنِي هَذَا وَرَزَقَنِيهِ مِن غَيرِ حَولٍ مِنِّي وَلَا قُوَّةٍ", transliteration: "Alhamdu lillahil-ladhi at'amani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah", translation: "Praise be to Allah, Who fed me this and provided it for me without any strength or power on my part. (After eating, his past sins are forgiven)", reference: "Sunan Abi Dawud 4023"),
            DuaItem(hadith: "tirmidhi:3455", cite: "Jami' at-Tirmidhi 3455", arabic: 100...105, transliteration: "Allahumma barik lana fihi wa zidna minhu", translation: "O Allah, bless us in it and give us more of it. (On drinking milk, for nothing suffices in place of food and drink except milk)"),
            DuaItem(hadith: "abudawud:2357", cite: "Sunan Abi Dawud 2357", arabic: 51...59, transliteration: "Dhahabaz-zama'u wabtallatil-'uruqu wa thabatal-ajru in sha' Allah", translation: "The thirst is gone, the veins are moistened, and the reward is confirmed, if Allah wills. (When breaking the fast)")
        ]
    )

    static let forgiveness = DuaCollection(
        title: "Forgiveness & Repentance",
        subtitle: "Seeking Allah's pardon, as the Prophet did daily",
        systemImage: "arrow.uturn.backward.circle",
        introductionTitle: "Forgiveness & Repentance Duas",
        introduction: "The Prophet ﷺ, though forgiven, sought Allah's forgiveness dozens of times a day, and taught his companions to do the same. \"And whoever does a wrong or wrongs himself but then seeks forgiveness of Allah will find Allah Forgiving and Merciful.\" (Quran 4:110)",
        items: [
            DuaItem(hadith: "abudawud:1516", cite: "Sunan Abi Dawud 1516", arabic: 37...45, transliteration: "Rabbi-ghfir li wa tub 'alayya, innaka antat-Tawwabur-Rahim", translation: "My Lord, forgive me and accept my repentance; indeed, You are the Accepting of Repentance, the Merciful. (The Prophet ﷺ was counted saying it a hundred times in a single gathering)"),
            DuaItem(hadith: "bukhari:834", cite: "Sahih al-Bukhari 834", arabic: 47...67, transliteration: "Allahumma inni zalamtu nafsi zulman kathiran, wa la yaghfirudh-dhunuba illa anta, faghfir li maghfiratan min 'indika, warhamni, innaka antal-Ghafurur-Rahim", translation: "O Allah, I have greatly wronged myself, and none forgives sins but You; so grant me forgiveness from You and have mercy on me. Indeed, You are the Forgiving, the Merciful. (Taught by the Prophet ﷺ to Abu Bakr to say in prayer)"),
            DuaItem(hadith: "abudawud:1517", cite: "Sunan Abi Dawud 1517", arabic: 46...56, transliteration: "Astaghfirullahal-ladhi la ilaha illa huwal-Hayyul-Qayyumu wa atubu ilayh", translation: "I seek the forgiveness of Allah, besides Whom there is no god, the Ever-Living, the Sustainer of all, and I turn to Him in repentance. (Whoever says it is forgiven, even if he had fled from battle)"),
            DuaItem(hadith: "muslim:483", cite: "Sahih Muslim 483", arabic: 43...53, transliteration: "Allahumma-ghfir li dhanbi kullah, diqqahu wa jillah, wa awwalahu wa akhirah, wa 'alaniyatahu wa sirrah", translation: "O Allah, forgive me all my sins: the small and the great, the first and the last, the open and the hidden. (Said by the Prophet ﷺ in prostration)"),
            DuaItem(hadith: "abudawud:4859", cite: "Sunan Abi Dawud 4859", arabic: 48...59, transliteration: "Subhanakallahumma wa bihamdika, ashhadu an la ilaha illa anta, astaghfiruka wa atubu ilayk", translation: "Glory be to You, O Allah, and praise be to You. I bear witness that there is no god but You; I seek Your forgiveness and turn to You in repentance. (Said on rising from a gathering, an expiation for whatever happened in it)")
        ]
    )

    static let prophets = DuaCollection(
        title: "Duas of the Prophets",
        subtitle: "Supplications of the prophets recorded in the Quran",
        systemImage: "sparkles",
        introductionTitle: "Duas of the Prophets",
        introduction: "The Quran preserves the very words the prophets called upon their Lord with (in illness, loneliness, need, and gratitude), and every one was answered. \"So We responded to him...\" (Quran 21:84)",
        items: [
            DuaItem(quran: "21:83", words: 5...10, transliteration: "Anni massaniyad-durru wa anta arhamur-rahimin", translation: "Indeed, adversity has touched me, and You are the Most Merciful of the merciful. (Ayyub, in his long illness; and Allah removed his affliction)"),
            DuaItem(quran: "21:89", words: 4...10, transliteration: "Rabbi la tadharni fardan wa anta khayrul-warithin", translation: "My Lord, do not leave me alone, and You are the best of inheritors. (Zakariyya, asking for a child; and he was given Yahya)"),
            DuaItem(quran: "27:19", words: 5...23, transliteration: "Rabbi awzi'ni an ashkura ni'matakal-lati an'amta 'alayya wa 'ala walidayya wa an a'mala salihan tardahu wa adkhilni birahmatika fi 'ibadikas-salihin", translation: "My Lord, enable me to be grateful for Your favor which You have bestowed upon me and my parents, and to do righteousness that pleases You, and admit me by Your mercy among Your righteous servants. (Sulayman, on hearing the ant)"),
            DuaItem(quran: "28:24", words: 7...14, transliteration: "Rabbi inni lima anzalta ilayya min khayrin faqir", translation: "My Lord, indeed I am in need of whatever good You send down to me. (Musa, alone and destitute in Madyan; and he was soon given shelter, work, and family)"),
            DuaItem(quran: "71:28", words: 0...9, transliteration: "Rabbi-ghfir li wa liwalidayya wa liman dakhala baytiya mu'minan wa lil-mu'minina wal-mu'minat", translation: "My Lord, forgive me and my parents and whoever enters my house a believer, and the believing men and believing women. (Nuh)"),
            DuaItem(quran: "26:83", transliteration: "Rabbi hab li hukman wa alhiqni bis-salihin", translation: "My Lord, grant me wisdom and join me with the righteous. (Ibrahim)")
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
            DuaItem(quran: "2:127", words: 7...13, transliteration: "Rabbana taqabbal minnaa innaka Antas Samee'ul Aleem", translation: "Our Lord, accept this from us. Indeed, You are the Hearing, the Knowing."),
            DuaItem(quran: "2:128", transliteration: "Rabbana waj'alnaa muslimaini laka wa min zurriyyatinaaa ummatam muslimatal laka wa arinaa manaasikanaa wa tub 'alainaa innaka antat Tawwaabur Raheem", translation: "Our Lord, make us Muslims in submission to You and from our descendants a Muslim nation in submission to You. Show us our rites and accept our repentance. Indeed, You are the Accepting of Repentance, the Merciful."),
            DuaItem(quran: "2:201", words: 3...13, transliteration: "Rabbana atina fid dunyaa hasanatanw wa fil aakhirati hasanatanw wa qinaa azaaban Naar", translation: "Our Lord, give us in this world good and in the Hereafter good and protect us from the punishment of the Fire."),
            DuaItem(quran: "2:250", words: 5...14, transliteration: "Rabbana afrigh 'alainaa sabranw wa sabbit aqdaamanaa wansurnaa 'alal qawmil kaafireen", translation: "Our Lord, pour upon us patience, plant firmly our feet, and give us victory over the disbelieving people."),
            DuaItem(quran: "2:286", words: 12...18, transliteration: "Rabbana laa tu'aakhiznaaa in naseenaaa aw akhtaanaa", translation: "Our Lord, do not impose blame upon us if we have forgotten or erred."),
            DuaItem(quran: "2:286", words: 19...29, transliteration: "Rabbana wa laa tahmil-'alainaaa isran kamaa hamaltahoo 'alal-lazeena min qablinaa", translation: "Our Lord, lay not upon us a burden like that which You laid upon those before us."),
            DuaItem(quran: "2:286", words: 30...48, transliteration: "Rabbana wa laa tuhammilnaa maa laa taaqata lanaa bih; wa'fu 'annaa waghfir lanaa warhamnaa; Anta mawlaanaa fansurnaa 'alal qawmil kaafireen", translation: "Our Lord, burden us not with what we have no ability to bear. Pardon us, forgive us, and have mercy upon us. You are our protector, so give us victory over the disbelieving people."),
            DuaItem(quran: "3:8", transliteration: "Rabbana laa tuzigh quloobanaa ba'da iz hadaitanaa wa hab lanaa mil ladunka rahmah; innaka antal Wahhaab", translation: "Our Lord, let not our hearts deviate after You have guided us and grant us mercy from Yourself. Indeed, You are the Bestower."),
            DuaItem(quran: "3:9", transliteration: "Rabbanaaa innaka jaami 'un-naasil Yawmil laa raibafeeh; innal laaha laa yukhliful mee'aad"),
            DuaItem(quran: "3:16", words: 2...10, transliteration: "Rabbanaaa innanaaa aamannaa faghfir lanaa zunoobanaa wa qinaa 'azaaban Naar", translation: "Our Lord, indeed we have believed, so forgive us our sins and protect us from the punishment of the Fire."),
            DuaItem(quran: "3:53", transliteration: "Rabbanaaa aamannaa bimaaa anzalta wattaba'nar Rasoola faktubnaa ma'ash shaahideen", translation: "Our Lord, we have believed in what You revealed and have followed the messenger, so register us among the witnesses to truth."),
            DuaItem(quran: "3:147", words: 6...18, transliteration: "Rabbanagh fir lanaa zunoobanaa wa israafanaa feee amrinaa wa sabbit aqdaamanaa wansurnaa 'alal qawmil kaafireen", translation: "Our Lord, forgive us our sins and the excess committed in our affairs, plant firmly our feet, and give us victory over the disbelieving people."),
            DuaItem(quran: "3:191", words: 12...20, transliteration: "Rabbanaa maa khalaqta haaza baatilan Subhaanaka faqinaa 'azaaban Naar", translation: "Our Lord, You did not create this aimlessly; exalted are You, so protect us from the punishment of the Fire."),
            DuaItem(quran: "3:192", transliteration: "Rabbanaaa innaka man tudkhilin Naara faqad akhzai tahoo wa maa lizzaalimeena min ansaar"),
            DuaItem(quran: "3:193", words: 0...9, transliteration: "Rabbanaaa innanaa sami'naa munaadiyai yunaadee lil eemaani an aaminoo bi Rabbikum fa aamannaa", translation: "Our Lord, indeed we heard a caller calling to faith, saying, Believe in your Lord, and we have believed."),
            DuaItem(quran: "3:193", words: 10...19, transliteration: "Rabbanaa faghfir lanaa zunoobanaa wa kaffir 'annaa saiyi aatina wa tawaffanaa ma'al abraar", translation: "Our Lord, forgive us our sins, remove from us our misdeeds, and cause us to die among the righteous."),
            DuaItem(quran: "3:194", transliteration: "Rabbanaa wa aatinaa maa wa'attanaa 'alaa Rusulika wa laa tukhzinaa Yawmal Qiyaamah; innaka laa tukhliful mee'aad", translation: "Our Lord, grant us what You promised through Your messengers and do not disgrace us on the Day of Resurrection. Indeed, You do not fail in promise."),
            DuaItem(quran: "5:83", words: 16...20, transliteration: "Rabbanaaa aamannaa faktubnaa ma'ash shaahideen", translation: "Our Lord, we have believed, so register us among the witnesses."),
            DuaItem(quran: "5:114", words: 4...21, transliteration: "Rabbanaaa anzil 'alainaa maaa'idatam minas samaaa'i takoonu lanaa 'eedal li awwalinaa wa aakhirinaa wa Aayatam minka warzuqnaa wa Anta khairur raaziqeen", translation: "O Allah, our Lord, send down to us a table from heaven to be a festival and a sign from You. Provide for us, and You are the best of providers."),
            DuaItem(quran: "7:23", words: 1...11, transliteration: "Rabbanaa zalamnaaa anfusanaa wa illam taghfir lanaa wa tarhamnaa lanakoonanna minal khaasireen", translation: "Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers."),
            DuaItem(quran: "7:47", words: 8...13, transliteration: "Rabbanaa laa taj'alnaa ma'al qawmiz zaalimeen", translation: "Our Lord, do not place us with the wrongdoing people."),
            DuaItem(quran: "7:89", words: 33...41, transliteration: "Rabbanaf-tah bainana wa baina qawmina bil haqqi wa anta Khairul Fatiheen", translation: "Our Lord, decide between us and our people in truth, and You are the best of those who give decision."),
            DuaItem(quran: "7:126", words: 10...15, transliteration: "Rabbanaaa afrigh 'alainaa sabranw wa tawaffanaa muslimeen", translation: "Our Lord, pour upon us patience and let us die as Muslims in submission to You."),
            DuaItem(quran: "10:85-86", words: 4...14, transliteration: "Rabbana la taj'alna fitnatal lil-qawmidh-Dhalimeen; wa najjina bi-Rahmatika minal qawmil kafireen", translation: "Our Lord, make us not objects of trial for the wrongdoing people, and save us by Your mercy from the disbelieving people."),
            DuaItem(quran: "14:38", transliteration: "Rabbanaaa innaka ta'lamu maa nukhfee wa maa nu'lin; wa maa yakhfaa 'alal laahi min shai'in fil ardi wa laa fis samaaa"),
            DuaItem(quran: "14:40", transliteration: "Rabbij 'alnee muqeemas Salaati wa min zurriyyatee Rabbanaa wa taqabbal du'aaa", translation: "My Lord, make me an establisher of prayer, and many from my descendants. Our Lord, accept my supplication."),
            DuaItem(quran: "14:41", transliteration: "Rabbanagh fir lee wa liwaalidaiya wa lilmu'mineena Yawma yaqoomul hisaab"),
            DuaItem(quran: "18:10", words: 6...15, transliteration: "Rabbanaaa aatinaa mil ladunka rahmatanw wa haiyi' lanaa min amrinaa rashadaa", translation: "Our Lord, grant us mercy from Yourself and prepare for us right guidance in our affair."),
            DuaItem(quran: "20:45", words: 1...9, transliteration: "Rabbanaaa innanaa nakhaafu ai yafruta 'alainaaa aw ai yatghaa", translation: "Our Lord, indeed we are afraid that he will hasten punishment against us or that he will transgress."),
            DuaItem(quran: "23:109", words: 6...13, transliteration: "Rabbanaaa aamannaa faghfir lanaa warhamnaa wa Anta khairur raahimeen", translation: "Our Lord, we have believed, so forgive us and have mercy upon us, and You are the best of the merciful."),
            DuaItem(quran: "25:65-66", words: 2...14, transliteration: "Rabbanas rif 'annnaa 'azaaba Jahannama inn 'azaabahaa kaana gharaamaa; innahaa saaa'at mustaqarranw wa muqaamaa", translation: "Our Lord, avert from us the punishment of Hell. Indeed, its punishment is ever adhering; indeed, it is evil as a settlement and residence."),
            DuaItem(quran: "25:74", words: 2...12, transliteration: "Rabbanaa hab lanaa min azwaajinaa wa zurriyaatinaa qurrata a'yuninw waj'alnaa lilmuttaqeena Imaamaa", translation: "Our Lord, grant us from among our spouses and offspring comfort to our eyes and make us an example for the righteous."),
            DuaItem(quran: "35:34", words: 1...10, transliteration: "Inna Rabbanaa la-Ghafoorun Shakoor", translation: "Indeed, our Lord is Forgiving and Appreciative."),
            DuaItem(quran: "40:7", words: 13...26, transliteration: "Rabbanaa wasi'ta kulla shai'ir rahmatanw wa 'ilman faghfir lillazeena taaboo wattaba'oo sabeelaka wa qihim 'azaabal Jaheem", translation: "Our Lord, You have encompassed all things in mercy and knowledge, so forgive those who repent and follow Your way, and protect them from the punishment of Hellfire."),
            DuaItem(quran: "40:8-9", words: 0...17, transliteration: "Rabbana wa adhkhilhum Jannati 'adninil-lati wa'attahum wa man salaha min aba'ihim wa azwajihim wa dhuriyyatihim innaka antal 'Azizul-Hakim, waqihimus saiyi'at", translation: "Our Lord, admit them to gardens of perpetual residence which You promised them, and whoever was righteous among their forefathers, spouses, and offspring. Indeed, You are the Exalted in Might, the Wise. Protect them from evil consequences."),
            DuaItem(quran: "59:10", words: 5...18, transliteration: "Rabbanagh fir lanaa wa li ikhwaani nal lazeena sabqoonaa bil eemaani wa laa taj'al fee quloobinaa ghillalil lazeena aamanoo", translation: "Our Lord, forgive us and our brothers who preceded us in faith, and put not in our hearts resentment toward those who have believed."),
            DuaItem(quran: "59:10", words: 19...22, transliteration: "Rabbannaaa innaka Ra'oofur Raheem", translation: "Our Lord, indeed You are Kind and Merciful."),
            DuaItem(quran: "60:4", words: 45...51, transliteration: "Rabbanaa 'alaika tawakkalnaa wa ilaika anabnaa wa ilaikal maseer", translation: "Our Lord, upon You we have relied, to You we have returned, and to You is the destination."),
            DuaItem(quran: "60:5", transliteration: "Rabbana laa taj'alnaa fitnatal lillazeena kafaroo waghfir lanaa rabbanaaa innaka antal azeezul hakeem", translation: "Our Lord, make us not objects of trial for those who disbelieve and forgive us, our Lord. Indeed, You are the Exalted in Might, the Wise."),
            DuaItem(quran: "66:8", words: 34...44, transliteration: "Rabbanaaa atmim lanaa nooranaa waghfir lana innaka 'alaa kulli shai'in qadeer", translation: "Our Lord, perfect for us our light and forgive us. Indeed, You are over all things competent.")
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
    }

    struct Collection: Identifiable {
        let id: String
        let label: String
        let arabic: String
        let subtitle: String
        let icon: String
        let entryIDs: [String]
        let categoryNumbers: [String]

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

        /// "Recite 3x · Muslim 4/2083": what the row prints under the dua.
        var sourceLine: String {
            var parts: [String] = []
            if repeatCount > 1 { parts.append("Recite \(repeatCount)x") }
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
    @ObservedObject private var settings = Settings.shared
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
                Text(playing ? "Stop" : "Recitation")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(playing ? .white : settings.accentColor.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(playing ? settings.accentColor.color : settings.accentColor.color.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playing ? "Stop the recitation" : "Play the recitation")
    }
}

/// The library's root: the 14 collections of the day, then every situation the book covers.
struct HisnDuaLibraryView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var searchText = ""
    @State private var library: HisnDuasStore.Library?
    /// The situations and duas matching the settled query: from `.onChange` (150 ms after the last
    /// keystroke) and the library's arrival, never from the body, which re-folded every row per evaluation.
    @State private var shownCategories: [HisnDuasStore.Category] = []
    @State private var shownMatches: [HisnDuasStore.Entry] = []
    @State private var filterTask: Task<Void, Never>?

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
            introduction: "\(category.label): \(entries.count == 1 ? "one supplication" : "\(entries.count) supplications") from the Fortress of the Muslim, with the reference each is narrated from. Tap the play pill under a dua to hear it recited.",
            items: entries.map(\.asDuaItem)
        )
    }

    static func collection(for shelf: HisnDuasStore.Collection, library: HisnDuasStore.Library) -> DuaCollection {
        let entries = shelf.entryIDs.compactMap { library.entryByID[$0] }
        return DuaCollection(
            title: shelf.label,
            subtitle: shelf.arabic,
            systemImage: shelf.systemImage,
            introductionTitle: shelf.label,
            introduction: shelf.subtitle.isEmpty ? "\(entries.count) supplications from Hisn al-Muslim." : shelf.subtitle,
            items: entries.map(\.asDuaItem)
        )
    }

    var body: some View {
        let _ = RenderCounter.hit("HisnDuaLibraryView")
        List {
            Group {
                if let library {
                    if query.isEmpty {
                        Section(header: Text("THE FORTRESS OF THE MUSLIM")) {
                            Text("Hisn al-Muslim, the pocket book of supplications compiled by Sa'id ibn Ali ibn Wahf al-Qahtani from the Quran and the authentic Sunnah: \(library.entries.count) duas for \(library.categories.count) situations, each with its reference, and a recitation to follow along with.")
                                .font(.subheadline)
                                .padding(.vertical, 6)
                        }

                        Section(header: SectionPillHeader(title: "THROUGH THE DAY", count: library.collections.count)) {
                            ForEach(library.collections) { shelf in
                                NavigationLink(destination: LazyDestination { DuaCollectionView(collection: Self.collection(for: shelf, library: library)) }) {
                                    HStack(spacing: 12) {
                                        AccentIconChip(systemImage: shelf.systemImage)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(shelf.label)
                                                .font(.body.weight(.medium))
                                            Text(shelf.arabic)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer(minLength: 8)
                                        Text("\(shelf.entryIDs.count)")
                                            .font(.caption.weight(.semibold).monospacedDigit())
                                            .foregroundStyle(accent)
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(accent.opacity(0.12)))
                                    }
                                }
                            }
                        }
                    }

                    let categories = shownCategories
                    let matches = shownMatches

                    if !query.isEmpty, !matches.isEmpty {
                        Section(header: SectionPillHeader(title: "MATCHING DUAS", count: matches.count)) {
                            ForEach(matches.prefix(30)) { entry in
                                NavigationLink(destination: LazyDestination {
                                    DuaCollectionView(collection: Self.collection(for: library.categories.first { $0.id == entry.categoryID } ?? HisnDuasStore.Category(id: entry.categoryID, number: "", label: entry.title, arabic: "", count: 1), library: library))
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(library.categories.first { $0.id == entry.categoryID }?.label ?? entry.title)
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(accent)
                                        HighlightedSnippet(source: entry.translation, term: searchText, font: .subheadline, accent: accent, fg: .primary)
                                            .lineLimit(3)
                                    }
                                }
                            }
                        }
                    }

                    Section(header: SectionPillHeader(title: "EVERY SITUATION", count: categories.count)) {
                        if categories.isEmpty, matches.isEmpty {
                            Text("No duas match your search.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(categories) { category in
                            NavigationLink(destination: LazyDestination { DuaCollectionView(collection: Self.collection(for: category, library: library)) }) {
                                HStack(spacing: 10) {
                                    Text(category.number)
                                        .font(.caption2.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 30, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HighlightedSnippet(source: category.label, term: searchText, font: .subheadline, accent: accent, fg: .primary)
                                        Text(category.arabic)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 8)
                                    Text("\(category.count)")
                                        .font(.caption2.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    if query.isEmpty {
                        Section(footer:
                            Text("Hisn al-Muslim texts and references from the islamic.app Dhikr API; recitations by hisnmuslim.com. Ported from the Tilawa app by Jamil Hammoudeh, with permission.")
                                .font(.caption2)
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
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .compactListSectionSpacing()
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: "Search Hisn al-Muslim")
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        .navigationTitle("Hisn al-Muslim")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchText) { _ in scheduleFilter() }
        .task {
            guard library == nil else { return }
            library = await Task.detached(priority: .userInitiated) { HisnDuasStore.shared.loaded() }.value
            applyFilter()
        }
    }

    private static func filter(_ library: HisnDuasStore.Library?, query: String) -> (categories: [HisnDuasStore.Category], matches: [HisnDuasStore.Entry]) {
        guard let library else { return ([], []) }
        guard !query.isEmpty else { return (library.categories, []) }
        let categories = library.categories.filter { category in
            (category.label + " " + category.arabic).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(query)
        }
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
struct HisnDuaOfTheDayCard: View {
    @ObservedObject private var settings = Settings.shared
    let entry: HisnDuasStore.Entry
    let category: HisnDuasStore.Category?
    let library: HisnDuasStore.Library

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill")
                Text("DUA OF THE DAY")
                Spacer()
                if let category {
                    Text(category.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                // Everything of the day on one screen (2026-09-16): the door every daily card carries,
                // chevron-less so the row keeps its edge clean.
                DailyHubDoorLabel()
                    .chevronlessLink { DailyHubView() }
            }
            .font(.caption2.weight(.bold))
            .foregroundColor(settings.accentColor.color)

            Text(entry.arabic)
                .font(.custom(settings.nonQuranArabicFontName, size: 24))
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .fixedSize(horizontal: false, vertical: true)

            Text(entry.translation)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)

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
                NavigationLink(destination: LazyDestination { DuaCollectionView(collection: HisnDuaLibraryView.collection(for: category, library: library)) }) {
                    Label("More duas for this situation", systemImage: "arrow.right.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }
            }
        }
        .padding(.vertical, 6)
        .textSelection(.enabled)
    }
}
#endif
