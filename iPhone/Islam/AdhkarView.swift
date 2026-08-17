import SwiftUI

struct CommonDhikr: Identifiable {
    let arabicText: String
    let transliteration: String
    let translation: String
    let searchBlob: String

    var id: String { transliteration }

    init(arabicText: String, transliteration: String, translation: String) {
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.translation = translation
        self.searchBlob = Self.searchBlob(arabicText: arabicText, transliteration: transliteration, translation: translation)
    }

    private static func searchBlob(arabicText: String, transliteration: String, translation: String) -> String {
        [arabicText, transliteration, translation]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

let commonDhikrItems: [CommonDhikr] = [
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ", transliteration: "SubhanAllah", translation: "Glory be to Allah"),
    CommonDhikr(arabicText: "ٱلحَمدُ لِلَّهِ", transliteration: "Alhamdulillah", translation: "Praise be to Allah"),
    CommonDhikr(arabicText: "اللَّهُ أَكبَرُ", transliteration: "Allahu Akbar", translation: "Allah is the Greatest"),
    CommonDhikr(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ", transliteration: "La ilaha illallah", translation: "There is no deity worthy of worship except Allah"),
    CommonDhikr(arabicText: "أَستَغفِرُ اللَّهَ", transliteration: "Astaghfirullah", translation: "I seek forgiveness from Allah"),
    CommonDhikr(arabicText: "لَا حَولَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "La hawla wala quwwata illa billah", translation: "There is no power or might except with Allah"),
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ سُبحَانَ اللَّهِ العَظِيمِ", transliteration: "SubhanAllahi wa bihamdihi, SubhanAllahil Adheem", translation: "Glory be to Allah and praise be to Him; Glory be to Allah, the Most Great"),
    CommonDhikr(arabicText: "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ", transliteration: "Allahumma salli 'ala Muhammad wa 'ala ali Muhammad", translation: "O Allah, send blessings upon Muhammad and his family"),
    CommonDhikr(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ وَحدَهُ لَا شَرِيكَ لَهُ لَهُ ٱلمُلكُ وَلَهُ ٱلحَمدُ وَهُوَ عَلَىٰ كُلِّ شَيءٍ قَدِيرٌ", transliteration: "La ilaha illallah wahdahu la sharika lah, lahul-mulk wa lahul-hamd, wa huwa 'ala kulli shayin qadir", translation: "There is no deity worthy of worship except Allah, alone, without any partner. His is the sovereignty and His is the praise, and He is capable of all things")
]

/// Measured height of the Arabic block, so a dhikr can decide for itself how to sit on the row.
private struct ArabicBlockHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Height of ONE line in the same font, for comparison.
private struct ArabicLineHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// The soft accent wash behind the row being read aloud. Its OWN view because it is the only per-row
/// piece that tracks the speech queue: when AdhkarRow itself observed `ArabicSpeech`, every queue
/// advance during Listen All re-ran every row's body (re-folding all its highlight fields). Now a
/// queue advance re-renders just these washes and the Listen buttons.
private struct SpokenRowWash: View {
    @ObservedObject private var speech = ArabicSpeech.shared
    let text: String
    let color: Color

    var body: some View {
        let active = speech.currentText == text
        RoundedRectangle(cornerRadius: 12)
            .fill(active ? color.opacity(0.12) : .clear)
            .padding(.horizontal, -10)
            .padding(.vertical, -2)
            .animation(.easeInOut(duration: 0.25), value: active)
    }
}

/// The Listen/Stop control - the other speech-reactive piece, split out for the same reason.
private struct AdhkarListenButton: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject private var speech = ArabicSpeech.shared
    let text: String

    var body: some View {
        let isBeingSpoken = speech.currentText == text
        Button {
            settings.hapticFeedback()
            if isBeingSpoken {
                speech.stop()
            } else {
                // speak() cuts off whatever else was playing - one voice at a time.
                speech.speak(text, rate: 0.4)
            }
        } label: {
            Label(isBeingSpoken ? "Stop" : "Listen",
                  systemImage: isBeingSpoken ? "stop.fill" : "speaker.wave.2")
                .font(.caption.weight(.semibold))
                .foregroundColor(settings.accentColor.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .conditionalGlassEffect()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isBeingSpoken ? "Stop the recitation" : "Hear the Arabic read aloud")
    }
}

extension Settings {
    /// Every Settings field `AdhkarRow`'s body reads, folded into one compared input - the Islam-tab
    /// counterpart of `ayahRenderSettingsSignature`/`hadithRenderSettingsSignature`.
    var adhkarRenderSettingsSignature: String {
        [
            nonQuranArabicFontName,
            islamUsesCustomArabicFace ? "1" : "0",
            accentColor.rawValue,
            customAccentColorHex
        ].joined(separator: "|")
    }
}

struct AdhkarRow: View, Equatable {
    @ObservedObject var settings = Settings.shared

    let arabicText: String
    let transliteration: String
    let translation: String
    var useQuranicFont: Bool = false
    var searchQuery: String = ""
    /// Duas are always trailing-aligned, even a one-liner: a dua is a quoted passage of Quran, and a Quranic
    /// line reads as Arabic prose, not as a UI label. A dhikr is a short phrase in a list of short phrases, so
    /// it stays leading until it actually wraps (which is what `arabicWraps` decides).
    var alwaysTrailing: Bool = false
    /// Shows a small "hear it" button that reads the Arabic aloud with the system's Arabic voice. There are
    /// no recordings for adhkar and duas, so this is synthesized - the same best-effort TTS the alphabet
    /// screens use; the button only appears when the device actually has an Arabic voice.
    var speechEnabled: Bool = false
    /// The citation ("Bukhari 6306", "Quran 3:8") shown on the bottom row, leading side - with the Listen
    /// button trailing on the same row.
    var source: String? = nil
    /// Captured at construction; see `Settings.adhkarRenderSettingsSignature`.
    var renderSettingsSignature: String = Settings.shared.adhkarRenderSettingsSignature

    /// The body lays out a full dhikr/dua (Arabic + transliteration + translation) and re-measures the
    /// Arabic's wrap - the expensive rows of the Adhkar and Dua screens, whose parents re-render on every
    /// Settings publish. The spoken-row wash and Listen button are child structs with their OWN speech
    /// subscriptions, so they keep updating during playback even while this body is skipped; the measured
    /// wrap heights are `@State`, which also bypasses `==`.
    static func == (l: Self, r: Self) -> Bool {
        l.arabicText == r.arabicText &&
        l.transliteration == r.transliteration &&
        l.translation == r.translation &&
        l.useQuranicFont == r.useQuranicFont &&
        l.searchQuery == r.searchQuery &&
        l.alwaysTrailing == r.alwaysTrailing &&
        l.speechEnabled == r.speechEnabled &&
        l.source == r.source &&
        l.renderSettingsSignature == r.renderSettingsSignature
    }

    /// The rendered height of the Arabic, and the height of a single line of it. A short dhikr ("سُبحَانَ اللَّهِ")
    /// is one line and reads best leading, like every other row on the screen; a long one wraps, and a wrapped
    /// Arabic paragraph has to be trailing-aligned or its ragged edge lands on the wrong side. So this is
    /// measured rather than declared per-screen - the same dhikr wraps or doesn't depending on the font size,
    /// the device, and Dynamic Type, and no hardcoded flag can know that.
    @State private var arabicHeight: CGFloat = 0
    @State private var arabicLineHeight: CGFloat = 0

    /// True once the Arabic has wrapped at all, i.e. it occupies more than one line.
    private var arabicWraps: Bool {
        guard arabicLineHeight > 0 else { return false }
        // A hair over one line's worth, so a single line doesn't flip on a rounding error.
        return arabicHeight > arabicLineHeight * 1.4
    }

    private var arabicFont: Font {
        useQuranicFont ? Font.arabic(settings.nonQuranArabicFontName, size: 30) : .title2
    }

    /// Whether `arabicFont` resolves to a bundled face, and so must opt out of the app-wide rounded design.
    private var usesCustomArabicFace: Bool {
        useQuranicFont && settings.islamUsesCustomArabicFace
    }

    var body: some View {
        Section {
            rowContent
        }
    }

    /// Folded copies of the row fields, cached by source string. `matches` used to fold each FULL field
    /// (a dua can be a paragraph) on every body pass while a search was active - four fresh folds per
    /// visible row per keystroke. The fields are immutable content, so the fold is computed once ever.
    private static let foldedFieldCache = NSCache<NSString, NSString>()

    private static func folded(_ field: String) -> String {
        if let cached = foldedFieldCache.object(forKey: field as NSString) { return cached as String }
        let folded = field.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        foldedFieldCache.setObject(folded as NSString, forKey: field as NSString)
        return folded
    }

    private var rowContent: some View {
        // Guarantee a highlight only on the field(s) that actually contain the query (folded the same way the
        // dhikr search itself matches), so a match in one field doesn't force-color the other two.
        let normalizedQuery = searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        func matches(_ field: String) -> Bool {
            guard !normalizedQuery.isEmpty else { return false }
            return Self.folded(field).contains(normalizedQuery)
        }
        let trailing = alwaysTrailing || arabicWraps
        return VStack(alignment: .leading, spacing: 10) {
            HighlightedSnippet(
                source: arabicText,
                term: searchQuery,
                font: arabicFont,
                accent: settings.accentColor.color,
                fg: settings.accentColor.color,
                guaranteeMatch: matches(arabicText)
            )
                .arabicFontDesign(custom: usesCustomArabicFace)
                // Only a block that actually wraps gets the trailing treatment; a one-liner stays leading, with
                // no multiline alignment at all (there's nothing to align).
                .multilineTextAlignment(trailing ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)
                .padding(.vertical, useQuranicFont ? -8 : 0)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: ArabicBlockHeightKey.self, value: geo.size.height)
                    }
                )
                // An invisible single line in the same face - the yardstick the block is measured against.
                .background(
                    Text("ب")
                        .font(arabicFont)
                        .arabicFontDesign(custom: usesCustomArabicFace)
                        .hidden()
                        .fixedSize()
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: ArabicLineHeightKey.self, value: geo.size.height)
                            }
                        )
                )
                .onPreferenceChange(ArabicBlockHeightKey.self) { arabicHeight = $0 }
                .onPreferenceChange(ArabicLineHeightKey.self) { arabicLineHeight = $0 }

            HighlightedSnippet(
                source: transliteration,
                term: searchQuery,
                font: .subheadline,
                accent: settings.accentColor.color,
                fg: .primary,
                guaranteeMatch: matches(transliteration)
            )
            .fixedSize(horizontal: false, vertical: true)

            HighlightedSnippet(
                source: translation,
                term: searchQuery,
                font: .subheadline,
                accent: settings.accentColor.color,
                fg: .secondary,
                guaranteeMatch: matches(translation)
            )
            .fixedSize(horizontal: false, vertical: true)

            // The bottom row: the citation sits leading, the Listen button trailing - one row, not two.
            if source != nil || (speechEnabled && ArabicSpeech.shared.isAvailable) {
                HStack(spacing: 8) {
                    if let source {
                        HighlightedSnippet(
                            source: source,
                            term: searchQuery,
                            font: .caption.weight(.semibold),
                            accent: settings.accentColor.color,
                            fg: .secondary,
                            guaranteeMatch: matches(source)
                        )
                    }

                    Spacer(minLength: 8)

                    if speechEnabled, ArabicSpeech.shared.isAvailable {
                        AdhkarListenButton(text: arabicText)
                    }
                }
            }
        }
        // Without this the List is free to hand these rows a height that truncates the long duas to a single
        // ellipsized line; it lets each block claim the height its text actually needs.
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 4)
        // The row being read aloud carries a soft accent wash; during Listen All it walks down the
        // section one row at a time as the queue advances. (Its own observing view - see SpokenRowWash.)
        .background(SpokenRowWash(text: arabicText, color: settings.accentColor.color))
        #if os(iOS)
        .contextMenu {
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = arabicText
            } label: {
                Label("Copy Arabic", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = transliteration
            } label: {
                Label("Copy Transliteration", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = translation
            } label: {
                Label("Copy Translation", systemImage: "doc.on.doc")
            }
        }
        #endif
    }
}

struct AdhkarView: View {
    @ObservedObject var settings = Settings.shared
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false

    #if os(iOS)
    // AI (semantic) dhikr search - the hadith book search's exact grammar, over the remembrances:
    // on-device meaning matching over the English translations, shown automatically above the
    // keyword matches. No mode to enter; the section appears (with one-time build progress the
    // first time) whenever it can help.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var aiHits: [CommonDhikr] = []
    @State private var aiSearchTask: Task<Void, Never>?

    private static let semanticCorpusID = "adhkar-en"

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
        let texts = commonDhikrItems.map { "\($0.transliteration) \($0.translation)" }
        // Keyed by the dhikr's own id, so index -> dhikr resolution survives any reorder of the source.
        let keys = commonDhikrItems.map(\.id)
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
            // Resolve through the corpus KEYS (the dhikr's id), falling back to position only for
            // a corpus persisted before keys existed.
            let keys = await MainActor.run { semanticEngine.corpus(Self.semanticCorpusID)?.itemKeys }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                // Plain apply: an animated section insert racing another async apply is the
                // collection-view assertion crash the Quran search hit.
                aiHits = results.compactMap { result in
                    if let keys, keys.indices.contains(result.index) {
                        let key = keys[result.index]
                        return commonDhikrItems.first(where: { $0.id == key })
                    }
                    return commonDhikrItems.indices.contains(result.index) ? commonDhikrItems[result.index] : nil
                }
            }
        }
    }

    // Ask (the on-device LLM, grounded RAG): question-shaped queries stream an answer card above
    // the matches, drawn strictly from the retrieved adhkar - the hadith book search's exact feature.
    @State private var askAnswer = ""
    @State private var askIsStreaming = false
    @State private var askRanForQuery = ""
    /// A MANUAL ask that found nothing to ground on or errored - the tapped row must answer with
    /// SOMETHING instead of silently restoring the prompt.
    @State private var askNoAnswer = false
    /// Whether the current answer was grounded in retrieved items (drives the card's footer).
    @State private var askGrounded = true
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist. Reset to the
    /// AI list on every new query.
    @State private var showKeywordResults = false
    @State private var askTask: Task<Void, Never>?
    /// The adhkar the answer was grounded on, kept so the answer's citations can resolve back to
    /// REAL rows - the hadith search's `hadithAskSourceHits`, for adhkar.
    @State private var askSourceDhikr: [CommonDhikr] = []

    /// The adhkar the streamed answer actually cited, in citation order - matched against the exact
    /// source references the model was given (the transliteration). Rendered as standard `AdhkarRow`s.
    private var askCitedDhikr: [CommonDhikr] {
        guard !askAnswer.isEmpty else { return [] }
        let answer = askAnswer.lowercased()
        var cited: [(position: Int, dhikr: CommonDhikr)] = []
        var seen = Set<String>()
        for dhikr in askSourceDhikr where seen.insert(dhikr.id).inserted {
            guard let range = answer.range(of: dhikr.transliteration.lowercased()) else { continue }
            cited.append((answer.distance(from: answer.startIndex, to: range.lowerBound), dhikr))
        }
        return cited.sorted { $0.position < $1.position }.prefix(10).map(\.dhikr)
    }

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
            var sourceDhikr: [CommonDhikr] = []
            var seen = Set<String>()
            for dhikr in aiHits.prefix(6) where seen.insert(dhikr.id).inserted {
                sources.append(.init(reference: dhikr.transliteration, text: dhikr.translation))
                sourceDhikr.append(dhikr)
            }
            for dhikr in commonDhikrItems.filter({ matchesSearch($0) }).prefix(6) where seen.insert(dhikr.id).inserted {
                sources.append(.init(reference: dhikr.transliteration, text: dhikr.translation))
                sourceDhikr.append(dhikr)
            }
            // Nothing retrieved is no longer a dead end: the ask still runs, in OPEN mode - a
            // clearly labeled general-knowledge answer with no recreated quotes.
            askGrounded = !sources.isEmpty

            askAnswer = ""; askIsStreaming = true; askRanForQuery = trimmed
            askSourceDhikr = sourceDhikr
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
                askAnswer = ""; askIsStreaming = false; askRanForQuery = ""; askSourceDhikr = []
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

            Text("AI couldn't answer \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D} right now. Try different wording, or try again.")
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
                Section(header: askAIHeader) {
                    AskAnswerCard(answer: askAnswer, isStreaming: askIsStreaming, grounded: askGrounded)

                    // The answer's receipts: the adhkar it actually cited, as the standard rows.
                    ForEach(askCitedDhikr, id: \.id) { dhikr in
                        AdhkarRow(
                            arabicText: dhikr.arabicText,
                            transliteration: dhikr.transliteration,
                            translation: dhikr.translation,
                            useQuranicFont: settings.useFontArabic,
                            searchQuery: searchText,
                            speechEnabled: true
                        )
                        .equatable()
                    }
                }
            } else {
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
                        ForEach(aiHits, id: \.id) { dhikr in
                            AdhkarRow(
                                arabicText: dhikr.arabicText,
                                transliteration: dhikr.transliteration,
                                translation: dhikr.translation,
                                useQuranicFont: settings.useFontArabic,
                                searchQuery: searchText,
                                speechEnabled: true
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
        // Both result kinds landed: ONE segmented switch decides which list fills the page (the
        // hadith book search's rule). With only one kind present, no picker - it just shows.
        #if os(iOS)
        let searchActive = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let keywordMatchesExist = searchActive && commonDhikrItems.contains(where: { matchesSearch($0) })
        let showResultsPicker = !aiHits.isEmpty && keywordMatchesExist
        let keywordVisible = !showResultsPicker || showKeywordResults
        #else
        let keywordVisible = true
        #endif

        return List {
            Group {
                introductionSection
                #if os(iOS)
                if searchActive {
                    askAISection(hasResults: !aiHits.isEmpty || keywordMatchesExist)
                    if showResultsPicker { resultsPickerSection }
                    // AI matches appear AUTOMATICALLY above the keyword results - no mode to enter.
                    if !showResultsPicker || !showKeywordResults { aiMatchesSection }
                }
                #endif
                if keywordVisible {
                    adhkarRows
                }
                etymologySection
                virtuesSection

                Section {
                    SpeechQualityHint()
                }
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
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #elseif os(watchOS)
        .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #endif
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle("Dhikr & Remembrances")
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
        // A running "Listen All" queue must not follow the user out of this screen (it kept speaking -
        // and kept the ducking audio session alive - after navigating away).
        .onDisappear { ArabicSpeech.shared.stop() }
    }

    private func matchesSearch(_ dhikr: CommonDhikr) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let normalizedQuery = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return dhikr.searchBlob.contains(normalizedQuery)
    }

    @ViewBuilder
    private func filteredAdhkarRow(_ dhikr: CommonDhikr) -> some View {
        if matchesSearch(dhikr) {
            AdhkarRow(
                arabicText: dhikr.arabicText,
                transliteration: dhikr.transliteration,
                translation: dhikr.translation,
                useQuranicFont: settings.useFontArabic,
                searchQuery: searchText,
                speechEnabled: true
            )
            .equatable()
        }
    }

    private var introductionSection: some View {
        Section(header: HStack(spacing: 8) {
            Text("REMEMBRANCES OF ALLAH")

            Spacer()

            // Count pill first (the SectionPillHeader rule); the pill plays every dhikr below, in order.
            CountPill(count: commonDhikrItems.count)

            ListenAllPill(texts: commonDhikrItems.map(\.arabicText))
        }) {
             Text("Short remembrances to keep your heart connected to Allah throughout the day.")
                 .font(.subheadline)
                 .foregroundColor(.primary)
                  
             Text("\"Unquestionably, by the remembrance of Allah hearts are assured.\" (Quran 13:28)")
                 .font(.caption)
                 .foregroundColor(.secondary)
        }
    }

    private var etymologySection: some View {
        Section(header: Text("ETYMOLOGY")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Arabic root: ذ ك ر (dh-k-r)")
                    .font(
                        settings.islamUsesCustomArabicFace
                            ? Font.arabic(settings.nonQuranArabicFontName, size: 18, relativeTo: .subheadline)
                            : .subheadline.weight(.semibold)
                    )
                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                    .foregroundColor(settings.accentColor.color)

                Text("Core meaning: to remember, to mention, to be mindful")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text("Dhikr literally means remembrance or mentioning. It includes saying SubhanAllah, Alhamdulillah, Allahu Akbar, reciting the Quran, and keeping Allah always present in the heart and tongue.")
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
    }

    @ViewBuilder
    private var adhkarRows: some View {
        ForEach(commonDhikrItems) { dhikr in
            filteredAdhkarRow(dhikr)
        }

        // The rows above vanish one by one as the query narrows; when they've ALL gone, say so
        // instead of leaving a silent gap.
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !commonDhikrItems.contains(where: { matchesSearch($0) }) {
            #if os(iOS)
            Text(aiHits.isEmpty
                 ? "No remembrances match your search."
                 : "No keyword matches; see the AI results above.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            #else
            Text("No remembrances match your search.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            #endif
        }
    }

    private var virtuesSection: some View {
        Section(header: Text("VIRTUES OF DHIKR")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dhikr is a continuous awareness of Allah. It revives the heart, protects the soul, and keeps a believer steady in trials.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            ReflectionCard(
                title: "Quranic Reminders",
                lines: [
                    "So remember Me; I will remember you. And be grateful to Me and do not deny Me. (Quran 2:152)",
                    "Unquestionably, by the remembrance of Allah hearts are assured. (Quran 13:28)",
                    "O you who have believed, remember Allah with much remembrance. (Quran 33:41)",
                    "Indeed, the Muslim men and Muslim women, the believing men and believing women, the obedient men and obedient women, the truthful men and truthful women, the patient men and patient women, the humble men and humble women, the charitable men and charitable women, the fasting men and fasting women, the men who guard their private parts and the women who do so, and the men who remember Allah often and the women who do so: for them Allah has prepared forgiveness and a great reward. (Quran 33:35)"
                ],
                accent: settings.accentColor.color
            )

            ReflectionCard(
                title: "Prophetic Encouragement",
                lines: [
                    "The best of your deeds, and the purest with your Master, is the remembrance of Allah. (Tirmidhi 3377, sahih)",
                    "Two words are light on the tongue, heavy on the Scale, and beloved to the Most Merciful: SubhanAllahi wa bihamdihi, SubhanAllahil Adheem. (Bukhari 6682; Muslim 2694)",
                    "Keep your tongue moist with the remembrance of Allah. (Tirmidhi 3375, hasan)"
                ],
                accent: settings.accentColor.color
            )

            Text("Make dhikr a daily rhythm: morning, evening, after salah, before sleep, and during ordinary moments. A heart that remembers Allah does not stay empty.")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

private struct ReflectionCard: View {
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
        AdhkarView()
    }
}
