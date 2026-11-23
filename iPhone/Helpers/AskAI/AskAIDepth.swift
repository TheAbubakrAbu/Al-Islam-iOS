import Foundation

// Ask AI - DEPTH: what else the app holds about a verse or a hadith, read WITH it.
//
// Abu, 2026-11-22: "whenever ... it's quoting an ayah or a Hadith look at different riwayaat and tafsir
// and translations and explanations to get an all encompassing answer."
//
// A retrieved verse used to reach the model as one translation of it, and a hadith as its English
// alone. Here the best-ranked verses and hadiths of a turn (and always the one the question names)
// gain NOTES, each the app's own data, never the model's memory:
//
//   a verse:    Tafsir Ibn Kathir on it (and a second and third tafsir where the window allows),
//               the app's other translation (The Clear Quran), and how the ten readings differ in
//               it with what each reading means (QiraatVariants, the Qiraat Explorer's table).
//               The readings only while "Show Riwayah / Qiraah" is on (`readsQiraat`): Abu,
//               2026-11-22, "only analyze qiraat if show qiraat is on";
//   a hadith:   the Hadith Encyclopedia's explanation of it (the row's own "Explanation" page) and
//               what is drawn from it, where else it is recorded (the Similar Hadiths pack), and
//               how another collection words it.
//
// A note rides on its source: the prompt sets it under the source's line ("With [2], ...") and it
// is cited by that source's number; the card beneath the answer lists what was read with it and
// shows each note when opened; a quotation is verified against the notes too.
//
// The window decides how much: `AskAIRetriever.Budget.noteCharacters` is shared out by importance.
// The question's subject takes every note it has first; then every chosen source its first note
// (the tafsir, the explanation), then every one its second, and so on, so a short budget gives each
// verse its tafsir before it gives any verse its readings. A commentary note (a tafsir, an
// explanation) on a source the question did not name is attached only when it speaks to the
// question (`speaksToQuestion`): a retrieved verse that turns out to be about something else brings
// no tafsir with it.
//
// Notes fill the room the sources leave. When the window is short `AskAIPrompt.fit` gives up the
// notes of the sources the question did not name BEFORE it gives up any source; only the subject's
// own notes are worth a source, and then only the weakest three (`AskAIPrompt.noteFloor`).

#if os(iOS)

/// One thing read with a verse or a hadith.
struct AskAISourceNote: Identifiable, Equatable, Codable {
    enum Kind: String, Codable {
        /// Another translation of the verse.
        case translation
        /// A tafsir's commentary on the verse.
        case tafsir
        /// How the readings (qiraat) differ in the verse, and what each reading means.
        case readings
        /// A scholar's explanation of the hadith.
        case explanation
        /// What is drawn from the hadith.
        case benefits
        /// Where else the hadith is recorded.
        case narrations
        /// How another collection words the same report.
        case wording
    }

    let kind: Kind
    /// Whose it is, in English, as the model reads it and the transcript keeps it: the translation
    /// ("Clear Quran (Mustafa Khattab)"), the tafsir ("Ibn Kathir"), the explanation's source
    /// ("Hadith Encyclopedia"), the other narration ("Sahih Muslim 1907"). Empty where the kind
    /// says it all.
    let title: String
    /// The English, verbatim from the app's own data, already clipped to what the model is shown:
    /// the card shows exactly this.
    let text: String
    /// The hadiths the note names ("Sahih Muslim 1907"): references an answer may then write out
    /// without their being taken for recalled ones (`AskAIText.policeCitations`).
    var references: [String] = []

    var id: String { kind.rawValue + "|" + title }

    /// What the model is told the note is. A commentary says whose words it is NOT: handed an
    /// explanation with nothing to mark it, the model put it in quotation marks after "He also
    /// explained this as" (the replay of 2026-11-22, on Sahih Muslim 2564a).
    var promptLabel: String {
        switch kind {
        case .translation: return "another translation of this verse, \(title)"
        case .tafsir: return "the tafsir \(title) on this verse (the commentator's words, not the Quran's)"
        case .readings: return "how the readings (qiraat) of this verse differ"
        case .explanation: return "an explanation of this hadith from the \(title) (commentary, not the Prophet's words)"
        case .benefits: return "what is drawn from this hadith, from the \(title) (commentary, not the Prophet's words)"
        case .narrations: return "where else this hadith is recorded"
        case .wording: return "how \(title) words this hadith"
        }
    }

    /// Scripture's own wording goes to the model in quotation marks, like its source's.
    var isQuotable: Bool { kind == .translation || kind == .wording }

    /// What follows a quotation lifted word for word from a commentary note, so that whatever the
    /// sentence around it says, the quotation is never read as the verse's or the hadith's own
    /// words (`AskAIText.policeQuotations`). Nil for the notes that ARE the scripture's wording
    /// (another translation, another collection's wording, and the readings: what a reading
    /// means is the verse as that reader reads it), and for the short notes nobody quotes.
    var quotedAttribution: String? {
        switch kind {
        case .tafsir: return "(from the tafsir \(title), not the verse itself)"
        case .explanation, .benefits: return "(from the \(title)\u{2019}s explanation, not the hadith itself)"
        case .translation, .wording, .readings, .narrations: return nil
        }
    }

    /// The line set under the source's own in the prompt.
    func promptLine(number: Int) -> String {
        "   With [\(number)], \(promptLabel): " + (isQuotable ? "\u{201C}\(text)\u{201D}" : text)
    }

    /// What the note costs the window, in characters.
    var promptCost: Int { text.count + promptLabel.count + 20 }

    /// The note's name on the card, in the interface's language.
    var displayLabel: String {
        switch kind {
        case .translation: return title.localizedDisplay
        case .tafsir: return String(localized: "Tafsir") + ": " + title.localizedDisplay
        case .readings: return String(localized: "OTHER QIRAAT")
        case .explanation: return String(localized: "Explanation")
        case .benefits: return String(localized: "Benefits")
        case .narrations: return String(localized: "Similar Hadiths")
        case .wording: return title
        }
    }

    var systemImage: String {
        switch kind {
        case .translation: return "character.book.closed"
        case .tafsir: return "text.magnifyingglass"
        case .readings: return "waveform"
        case .explanation, .benefits: return "text.book.closed"
        case .narrations, .wording: return "rectangle.on.rectangle"
        }
    }
}

@MainActor
enum AskAIDepth {
    /// Whether the readings (qiraat) are read with a verse at all: only while "Show Riwayah /
    /// Qiraah" is on (Quran settings, off by default), the switch that shows the readings
    /// everywhere else in the app (the ayah sheet's OTHER QIRAAT, the Qiraat Explorer). Off, no
    /// verse carries a readings note, and neither the instructions nor the task line name the
    /// readings (`AskAIPrompt.instructions(readsQiraat:)`), so the model is not led to them.
    /// Abu, 2026-11-22: "only analyze qiraat if show qiraat is on".
    static var readsQiraat: Bool { Settings.shared.showQiraahDetails }

    /// A note's ceiling by kind, in characters: an ordinary source's, and the roomier one of the
    /// source the question names. Both grow with the engine's window (`scale`).
    private struct Cap {
        let plain: Int
        let subject: Int
        func characters(subject isSubject: Bool, scale: Double) -> Int {
            Int(Double(isSubject ? subject : plain) * scale)
        }
    }

    private static let tafsirCap = Cap(plain: 420, subject: 600)
    private static let translationCap = Cap(plain: 260, subject: 340)
    private static let readingsCap = Cap(plain: 320, subject: 460)
    private static let secondTafsirCap = Cap(plain: 300, subject: 380)
    private static let thirdTafsirCap = Cap(plain: 260, subject: 320)
    private static let explanationCap = Cap(plain: 420, subject: 620)
    private static let narrationsCap = Cap(plain: 190, subject: 240)
    private static let wordingCap = Cap(plain: 260, subject: 340)
    private static let benefitsCap = Cap(plain: 220, subject: 320)

    /// A candidate note: `order` is its place among its own source's notes, which is also the round
    /// it is handed out in.
    private struct Candidate {
        let source: Int
        let order: Int
        let note: AskAISourceNote
    }

    /// `sources` with their notes attached, within `budget.noteCharacters`. Every source's notes
    /// are rebuilt here (a source carried from the previous turn drops the ones it came with).
    static func attach(to sources: [AskAISource], question: AskAIQuestion, budget: AskAIRetriever.Budget,
                       readings: Bool? = nil) async -> [AskAISource] {
        // The setting, read once for the turn (a test names the answer itself).
        let withReadings = readings ?? readsQiraat
        var sources = sources.map { source -> AskAISource in
            var bare = source
            bare.notes = []
            return bare
        }
        guard budget.noteCharacters > 0, budget.notedSources > 0 else { return sources }
        let scale = max(1, Double(budget.sourceCharacters) / 500)
        let terms = question.searchTerms
        // Read only where the app ships the Quran or the hadith (an app with neither attaches nothing).
        _ = (scale, terms, withReadings)

        // The verses and hadiths that are read in depth: the one the question names, then the
        // best-ranked.
        var chosen = sources.indices.filter { sources[$0].isSubject && sources[$0].isScripture }
        for index in sources.indices where !sources[index].isSubject && sources[index].isScripture && chosen.count < budget.notedSources {
            chosen.append(index)
        }
        guard !chosen.isEmpty else { return sources }

        var candidates: [Candidate] = []
        var seenTexts = Set<String>()
        for index in chosen {
            if Task.isCancelled { return sources }
            let source = sources[index]
            var found: [AskAISourceNote] = []
            switch source.kind {
            case .ayah(let surah, let ayah):
                #if HAS_QURAN
                // A verse whose Ibn Kathir entry is a source of its own (the subject's, a key
                // evidence verse's) does not carry it twice.
                let hasTafsirSource = sources.contains { other in
                    if case .tafsir(let s, let a, _) = other.kind { return s == surah && a == ayah }
                    return false
                }
                found = await ayahNotes(surah: surah, ayah: ayah, isSubject: source.isSubject,
                                        hasTafsirSource: hasTafsirSource, withReadings: withReadings,
                                        terms: terms, scale: scale)
                #else
                _ = (surah, ayah)
                #endif
            case .hadith(let slug, let idInBook):
                #if HAS_HADITH
                found = await hadithNotes(slug: slug, idInBook: idInBook, isSubject: source.isSubject, terms: terms, scale: scale)
                #else
                _ = (slug, idInBook)
                #endif
            default:
                break
            }
            // A retrieved verse or hadith that turns out to be about something else is read alone:
            // notes go only to a source that holds one of the question's words, in its own text, in
            // its other translation, or in the commentary that made it through `speaksToQuestion`.
            if !source.isSubject {
                let onTheQuestion = speaksToQuestion(source.text, terms: terms)
                    || found.contains { note in
                        switch note.kind {
                        case .tafsir, .explanation: return true
                        case .translation, .wording: return speaksToQuestion(note.text, terms: terms)
                        case .readings, .benefits, .narrations: return false
                        }
                    }
                if !onTheQuestion { found = [] }
            }
            // Two verses of one tafsir passage, or two narrations of one report, would carry the
            // same note twice: the better-ranked one keeps it.
            for (order, note) in found.enumerated() where seenTexts.insert(note.text).inserted {
                candidates.append(Candidate(source: index, order: order, note: note))
            }
        }

        // The subject's notes first, all of them; then round by round across the others.
        let ordered = candidates.sorted { a, b in
            let subjectA = sources[a.source].isSubject, subjectB = sources[b.source].isSubject
            if subjectA != subjectB { return subjectA }
            if !subjectA, a.order != b.order { return a.order < b.order }
            if a.source != b.source { return a.source < b.source }
            return a.order < b.order
        }
        var remaining = budget.noteCharacters
        var taken: [Candidate] = []
        for candidate in ordered where candidate.note.promptCost <= remaining {
            remaining -= candidate.note.promptCost
            taken.append(candidate)
        }
        // Each source's notes in their own order, whatever round they were handed out in.
        for candidate in taken.sorted(by: { $0.order < $1.order }) {
            sources[candidate.source].notes.append(candidate.note)
        }
        return sources
    }

    /// A long text cut to `limit` around the sentence that holds the question's words, or from its
    /// opening when it has none of them.
    nonisolated private static func excerpt(_ text: String, limit: Int, terms: [String]) -> String {
        terms.isEmpty ? AskAISource.clip(text, to: limit) : AskAISource.clip(text, to: limit, around: terms)
    }

    /// Whether a commentary excerpt speaks to the question: it holds one of the question's own
    /// words (or their synonyms). A source the question NAMES is read with its commentary whatever
    /// it says; a retrieved one only when the commentary bears on what was asked. The ranking puts
    /// unrelated verses near the top often enough (2:213 and 90:14 led "what does the Quran say
    /// about backbiting"), and their tafsir is five hundred characters of something else for a
    /// small model to wander into. A question with no words to match (a bare "why?") gates nothing.
    nonisolated static func speaksToQuestion(_ text: String, terms: [String]) -> Bool {
        let wanted = Set(terms.filter { $0.count >= 4 && !$0.contains(" ") })
        guard !wanted.isEmpty else { return true }
        let words = Set(AskAILexicon.fold(text).split(separator: " ").map(String.init))
        return !wanted.isDisjoint(with: words)
    }

    // MARK: - A verse

    #if HAS_QURAN

    /// The English tafsir editions after Ibn Kathir, in the order they are added as the window grows.
    private static let furtherTafsirs: [(author: TafsirAuthor, cap: Cap, needsScale: Double, subjectNeedsScale: Double)] = [
        (.maarifUlQuran, secondTafsirCap, 1.1, 1.0),
        (.tazkirulQuran, thirdTafsirCap, 1.5, 1.1),
    ]

    /// The name the comparison sheet gives the app's second translation (its catalog key too).
    nonisolated static let otherTranslationTitle = "Clear Quran (Mustafa Khattab)"

    private static func ayahNotes(surah: Int, ayah: Int, isSubject: Bool, hasTafsirSource: Bool, withReadings: Bool,
                                  terms: [String], scale: Double) async -> [AskAISourceNote] {
        guard let verse = QuranData.shared.ayah(surah: surah, ayah: ayah) else { return [] }
        var notes: [AskAISourceNote] = []

        if !hasTafsirSource,
           let text = tafsirExcerpt(.ibnKathir, surah: surah, ayah: ayah,
                                    limit: tafsirCap.characters(subject: isSubject, scale: scale), terms: terms,
                                    whateverItSays: isSubject) {
            notes.append(AskAISourceNote(kind: .tafsir, title: TafsirAuthor.ibnKathir.rawValue, text: text))
        }

        let other = verse.textEnglishMustafa.trimmingCharacters(in: .whitespacesAndNewlines)
        if !other.isEmpty, other != verse.textEnglishSaheeh.trimmingCharacters(in: .whitespacesAndNewlines) {
            notes.append(AskAISourceNote(kind: .translation, title: otherTranslationTitle,
                                         text: AskAISource.clip(other, to: translationCap.characters(subject: isSubject, scale: scale))))
        }

        // The readings, only for a reader who has them shown (`readsQiraat`). The table parses from
        // its pack on first use: off the main actor.
        if withReadings {
            let limit = readingsCap.characters(subject: isSubject, scale: scale)
            let readings = await Task.detached(priority: .userInitiated) { () -> String? in
                guard QiraatVariantsStore.isBundled else { return nil }
                let store = QiraatVariantsStore.shared
                return readingsText(junctures: store.junctures(surah: surah, ayah: ayah), everyJuncture: isSubject, limit: limit,
                                    attribution: { store.attribution(for: $0) },
                                    hafsReading: { store.reading(in: $0, followedBy: Settings.Riwayah.hafsTag)?.id })
            }.value
            if let readings {
                notes.append(AskAISourceNote(kind: .readings, title: "", text: readings))
            }
        }

        for further in furtherTafsirs where scale >= (isSubject ? further.subjectNeedsScale : further.needsScale) {
            if let text = tafsirExcerpt(further.author, surah: surah, ayah: ayah,
                                        limit: further.cap.characters(subject: isSubject, scale: scale), terms: terms,
                                        whateverItSays: isSubject) {
                notes.append(AskAISourceNote(kind: .tafsir, title: further.author.rawValue, text: text))
            }
        }
        return notes
    }

    private static func tafsirExcerpt(_ author: TafsirAuthor, surah: Int, ayah: Int, limit: Int, terms: [String],
                                      whateverItSays: Bool) -> String? {
        guard let entry = TafsirStore.shared.entry(author: author, surah: surah, ayah: ayah) else { return nil }
        let plain = AskAIText.plainProse(entry.content)
        guard plain.count >= 40 else { return nil }
        let cut = excerpt(plain, limit: limit, terms: terms)
        return whateverItSays || speaksToQuestion(cut, terms: terms) ? cut : nil
    }

    /// How the readings differ in one verse, as prose the model can read: each place the ten read
    /// differently, every way it is read (transliterated), what that reading means, who reads it
    /// so, and the reference's own note on the difference. `everyJuncture` false keeps only the
    /// places where the readings differ in SENSE (the reference's category A) and come to more than
    /// one meaning: a difference of pronunciation alone says nothing to a question about patience.
    /// Nil when the verse has none to tell.
    nonisolated static func readingsText(junctures: [QiraatVariantsStore.Juncture], everyJuncture: Bool, limit: Int,
                                         attribution: (QiraatVariantsStore.Reading) -> String,
                                         hafsReading: (QiraatVariantsStore.Juncture) -> Int?) -> String? {
        struct Way {
            var english: String
            var transliterations: [String]
            var readers: [String]
            var explanation: String
            var isHafs: Bool
        }
        let quoteMarks = CharacterSet(charactersIn: "\"\u{201C}\u{201D}\u{2018}\u{2019}' ")
        var places: [String] = []
        for juncture in junctures {
            guard everyJuncture || juncture.category.hasPrefix("A") else { continue }
            let hafs = hafsReading(juncture)
            // Readings that come to the same English are one way of reading the place.
            var ways: [Way] = []
            for reading in juncture.readings {
                let english = reading.english.trimmingCharacters(in: quoteMarks)
                // The readers' names in plain letters ("Asim", "al-Kisai"): the table's scholarly
                // spelling ("ʿĀṣim", "al-Kisāʾī") costs the model several tokens a name and reads
                // to it as noise. The readings themselves keep their marks: māliki and maliki
                // differ by exactly one of them.
                let who = attribution(reading).replacingOccurrences(of: " \u{00B7} ", with: ", ")
                    .foldingLatinDiacritics
                    .replacingOccurrences(of: "\u{02BF}", with: "").replacingOccurrences(of: "\u{02BE}", with: "")
                let transliteration = reading.transliteration.trimmingCharacters(in: .whitespaces)
                if let index = ways.firstIndex(where: { !english.isEmpty && $0.english.caseInsensitiveCompare(english) == .orderedSame }) {
                    if !transliteration.isEmpty, !ways[index].transliterations.contains(transliteration) {
                        ways[index].transliterations.append(transliteration)
                    }
                    if !who.isEmpty { ways[index].readers.append(who) }
                    if reading.id == hafs { ways[index].isHafs = true }
                } else {
                    ways.append(Way(english: english, transliterations: transliteration.isEmpty ? [] : [transliteration],
                                    readers: who.isEmpty ? [] : [who], explanation: reading.explanation, isHafs: reading.id == hafs))
                }
            }
            guard ways.count >= 2 || (everyJuncture && !ways.isEmpty) else { continue }
            // The reading the verse is quoted in (Hafs's) first.
            if let index = ways.firstIndex(where: \.isHafs), index > 0 { ways.insert(ways.remove(at: index), at: 0) }
            // One plain sentence a reading, who first: "A, B and C read X, meaning “...”." A small
            // model reads a sentence with a subject and a verb; given "X, “...”, is read by A; Y,
            // “...”, is read by B" it explained 1:4 without a word on Owner and King.
            let said = ways.compactMap { way -> String? in
                let words = way.transliterations.prefix(2).joined(separator: " or ")
                guard !words.isEmpty || !way.english.isEmpty else { return nil }
                var line = way.readers.isEmpty ? "One reading is" : way.readers.joined(separator: ", ") + " read"
                if !words.isEmpty { line += " " + words }
                if !way.english.isEmpty { line += (words.isEmpty ? " " : ", meaning ") + "\u{201C}\(way.english)\u{201D}" }
                if way.isHafs { line += " (the reading quoted above)" }
                if everyJuncture, !way.explanation.isEmpty {
                    line += ": " + way.explanation.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
                }
                return line + "."
            }
            guard !said.isEmpty else { continue }
            var place = said.joined(separator: " ")
            if !juncture.note.isEmpty { place += " " + AskAISource.clip(juncture.note, to: 220) }
            places.append(place)
        }
        guard !places.isEmpty else { return nil }
        return AskAISource.clip(places.joined(separator: " "), to: limit)
    }

    #endif

    // MARK: - A hadith

    #if HAS_HADITH

    /// The collections a parallel narration is named from first, most relied on first.
    private static let collectionOrder = ["bukhari", "muslim", "abudawud", "tirmidhi", "nasai", "ibnmajah", "malik", "ahmad"]

    /// Similar wording counts as the same report in another book from this score up (the pack's
    /// own reading: 60 and above is the same narration elsewhere, below it loosely related words).
    nonisolated static let sameReportScore = 60

    private static func hadithNotes(slug: String, idInBook: Int, isSubject: Bool, terms: [String], scale: Double) async -> [AskAISourceNote] {
        var notes: [AskAISourceNote] = []

        // The Hadith Encyclopedia entry the row's own "Explanation" opens, and the row's matches in
        // the Similar Hadiths pack: both packs are lock-guarded and inflate off the main actor.
        let lookedUp = await Task.detached(priority: .userInitiated) { () -> (HadeethEncHadith?, [SimilarHadithMatch]) in
            let entry = HadithExplanationStore.shared.explanationID(slug: slug, idInBook: idInBook)
                .flatMap { HadeethEncStore.shared.hadith(id: $0) }
            return (entry, SimilarHadithsStore.shared.matches(slug: slug, idInBook: idInBook))
        }.value
        let entry = lookedUp.0
        let matches = lookedUp.1

        if let entry {
            let explanation = AskAIText.plainProse(entry.english.explanation)
            if explanation.count >= 40 {
                let cut = excerpt(explanation, limit: explanationCap.characters(subject: isSubject, scale: scale), terms: terms)
                if isSubject || speaksToQuestion(cut, terms: terms) {
                    notes.append(AskAISourceNote(kind: .explanation, title: "Hadith Encyclopedia", text: cut))
                }
            }
        }

        let parallels = await parallelNarrations(of: slug, matches: matches)
        if let whole = narrationsText(parallels, ownSlug: slug, sameBookCount: matches.filter { $0.slug == slug }.count) {
            let text = AskAISource.clip(whole, to: narrationsCap.characters(subject: isSubject, scale: scale))
            // Only the references the model is actually shown may be written back.
            notes.append(AskAISourceNote(kind: .narrations, title: "", text: text,
                                         references: parallels.map(\.reference).filter { text.contains($0) }))
        }

        if isSubject || scale > 1.1 {
            // The closest narration in another book that says it in other words.
            if let other = parallels.first(where: { $0.match.tier == .similar && !$0.match.sameEnglish }) {
                await AskAIRetriever.prewarmHadithText([(other.data, other.hadith.row)])
                let english = other.hadith.allText.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if english.count >= 40 {
                    notes.append(AskAISourceNote(kind: .wording, title: other.reference,
                                                 text: excerpt(english, limit: wordingCap.characters(subject: isSubject, scale: scale), terms: terms),
                                                 references: [other.reference]))
                }
            }
            if let entry {
                let benefits = entry.english.benefits.map { AskAIText.plainProse($0) }.filter { !$0.isEmpty }.joined(separator: " ")
                if benefits.count >= 40 {
                    notes.append(AskAISourceNote(kind: .benefits, title: "Hadith Encyclopedia",
                                                 text: AskAISource.clip(benefits, to: benefitsCap.characters(subject: isSubject, scale: scale))))
                }
            }
        }
        return notes
    }

    private struct Parallel {
        let match: SimilarHadithMatch
        let book: HadithCatalogBook
        let data: HadithBookData
        let hadith: HadithBookData.Hadith
        var reference: String { "\(book.englishTitle) \(hadith.displayNumber)" }
    }

    /// The same report in OTHER collections: the same text first, then similar wording from
    /// `sameReportScore` up, one narration a collection, the most relied-on collections first.
    private static func parallelNarrations(of slug: String, matches: [SimilarHadithMatch]) async -> [Parallel] {
        let store = HadithStore.shared
        var best: [String: SimilarHadithMatch] = [:]
        for match in matches where match.slug != slug && (match.tier != .similar || match.score >= sameReportScore) {
            if let held = best[match.slug], (held.tier, -held.score) <= (match.tier, -match.score) { continue }
            best[match.slug] = match
        }
        func rank(_ slug: String) -> Int { collectionOrder.firstIndex(of: slug) ?? collectionOrder.count }
        let ordered = best.values.sorted { a, b in
            let sameA = a.tier != .similar, sameB = b.tier != .similar
            if sameA != sameB { return sameA }
            if rank(a.slug) != rank(b.slug) { return rank(a.slug) < rank(b.slug) }
            return a.slug < b.slug
        }
        var out: [Parallel] = []
        for match in ordered.prefix(5) {
            guard let book = HadithCatalogBook.bySlug[match.slug], let data = store.book(book),
                  let hadith = data.hadith(numbered: match.idInBook) else { continue }
            out.append(Parallel(match: match, book: book, data: data, hadith: hadith))
        }
        return out
    }

    /// "The same wording is also recorded in Sahih Muslim 1907 and Sunan Abi Dawud 2201. It is
    /// narrated in similar words in Sunan an-Nasa'i 75." English: the model reads it.
    private static func narrationsText(_ parallels: [Parallel], ownSlug: String, sameBookCount: Int) -> String? {
        func list(_ references: [String]) -> String {
            switch references.count {
            case 0: return ""
            case 1: return references[0]
            default: return references.dropLast().joined(separator: ", ") + " and " + references[references.count - 1]
            }
        }
        let same = parallels.filter { $0.match.tier != .similar }.prefix(3).map(\.reference)
        let similar = parallels.filter { $0.match.tier == .similar }.prefix(same.isEmpty ? 3 : 2).map(\.reference)
        var sentences: [String] = []
        if !same.isEmpty { sentences.append("The same wording is also recorded in \(list(Array(same))).") }
        if !similar.isEmpty { sentences.append("It is narrated in similar words in \(list(Array(similar))).") }
        if sentences.isEmpty, sameBookCount > 0, let book = HadithCatalogBook.bySlug[ownSlug] {
            sentences.append(sameBookCount == 1
                             ? "\(book.englishTitle) records it in one other narration."
                             : "\(book.englishTitle) records it in \(sameBookCount) other narrations.")
        }
        return sentences.isEmpty ? nil : sentences.joined(separator: " ")
    }

    #endif
}

#endif
