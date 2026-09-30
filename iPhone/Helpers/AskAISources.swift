import SwiftUI
import Foundation

// Ask AI - the SOURCES an answer is built on, and where each one comes from.
//
// Every question runs the app's own retrieval (AskAIRetrieval.swift), and what it finds becomes a
// numbered list of `AskAISource`s: a verse, a hadith, a tafsir excerpt, a surah's background, one of
// the app's articles, a dua, a Name of Allah, an app tip, or today's prayer times. The model is shown
// each source's English text with its origin ("Quran 2:153 in Surah Al-Baqarah, Saheeh International
// translation"; "Sahih al-Bukhari 6114, narrated by Abu Hurairah, grade sahih") and cites by number.
// The reader is shown the same text VERBATIM as a quote card, with the Arabic where there is one and
// the provenance facts as a footer, and a tap opens the real screen. That is how "quote the sources
// and say where each comes from" is kept honest: the model never writes scripture from memory, the
// app quotes it from its own packs.

#if os(iOS)

struct AskAISource: Identifiable, Equatable, Codable {
    enum Kind: Equatable, Codable {
        case ayah(surah: Int, ayah: Int)
        case hadith(slug: String, idInBook: Int)
        /// A tafsir excerpt on the ayah the question named; the reader opens at that ayah.
        case tafsir(surah: Int, ayah: Int, author: String)
        /// A surah's background prose ("About this surah"); the reader opens the surah.
        case surah(Int)
        /// A section of an Islam-tab article (Pillars & Beliefs, How-to Guides, Answers...).
        case article(id: String, heading: String)
        /// Today's prayer schedule as THIS app computed it. Not a link: there is no screen for a time.
        case prayer
        /// One of the 99 Names of Allah, by its number.
        case name(number: Int)
        /// A dua of the app's authored collections (collection title + the item's identity).
        case dua(collection: String, identity: String)
        /// A supplication of Hisn al-Muslim, by its entry id.
        case hisnDua(id: String)
        /// A Tips & Tricks entry: how to do something in THIS app.
        case tip(id: String)
        /// A settings search entry: where a setting lives in THIS app (`SettingsSearchEntry.id`).
        case setting(id: String)
    }

    let kind: Kind
    /// The citation the app matches when the model writes it out in words ("2:153",
    /// "Sahih al-Bukhari 6114", "Tafsir Ibn Kathir on 2:255", an article's title). Unique per turn.
    let reference: String
    /// The quote card's title line ("Al-Baqarah 2:153", "Sahih al-Bukhari 6114", "Al-Wadud").
    let title: String
    /// The English, VERBATIM from the app's own data: what the model reads and what the card quotes.
    let text: String
    /// The Arabic original, for the card only. It never reaches the model (Apple's model rejects a
    /// prompt with substantial Arabic, see `OnDeviceAsk.supportsArabic`).
    var arabic: String? = nil
    /// A transliteration, for duas (what the reader would actually recite).
    var transliteration: String? = nil
    /// Where it comes from, as facts a reader can check: the surah and translation; the collection,
    /// its compiler, the chapter, the narrator and the grade; the tafsir's author and edition; the
    /// article's home; the dua's collection and its own reference.
    var provenance: [String] = []
    /// Other spellings of the reference the model might write ("bukhari 6114", "quran 2:153"),
    /// lowercased, for matching citations written in words rather than by number.
    var aliases: [String] = []
    /// How much of `text` a prompt carries: a retrieved ayah or hadith keeps a few hundred
    /// characters, a tafsir excerpt or a surah's background more, because it IS the answer.
    var maxCharacters: Int = 500
    /// The verse, surah, hadith or Name the question itself NAMED: labelled SUBJECT in the prompt,
    /// and its card always shows beneath the answer whether or not the model cited it.
    var isSubject = false
    /// Carried into a follow-up from the previous answer, which already quoted it: the prompt says
    /// so, and asks the model to build on it rather than quote it again (a bare "why?" used to come
    /// back with the same two verses re-quoted). Set per turn and never persisted: it is left out
    /// of `CodingKeys`, so transcripts saved before it existed still decode.
    var wasQuotedBefore = false
    /// The words the retrieval matched this source on (folded), for this turn's prompt only: a
    /// long hadith is clipped around the sentence that holds them instead of from its opening.
    var focusTerms: [String] = []

    var id: String { reference }

    private enum CodingKeys: String, CodingKey {
        case kind, reference, title, text, arabic, transliteration, provenance, aliases, maxCharacters, isSubject
    }

    init(kind: Kind, reference: String, title: String, text: String, arabic: String? = nil,
         transliteration: String? = nil, provenance: [String] = [], aliases: [String] = [],
         maxCharacters: Int = 500, isSubject: Bool = false) {
        self.kind = kind
        self.reference = reference
        self.title = title
        self.text = text
        self.arabic = arabic
        self.transliteration = transliteration
        self.provenance = provenance
        self.aliases = aliases
        self.maxCharacters = maxCharacters
        self.isSubject = isSubject
    }

    /// Lenient: a field a later build added (or an earlier one dropped) takes its default instead
    /// of failing the whole transcript, which the next save would then have overwritten.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(Kind.self, forKey: .kind)
        reference = try container.decode(String.self, forKey: .reference)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? reference
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        arabic = try container.decodeIfPresent(String.self, forKey: .arabic)
        transliteration = try container.decodeIfPresent(String.self, forKey: .transliteration)
        provenance = try container.decodeIfPresent([String].self, forKey: .provenance) ?? []
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        maxCharacters = try container.decodeIfPresent(Int.self, forKey: .maxCharacters) ?? 500
        isSubject = try container.decodeIfPresent(Bool.self, forKey: .isSubject) ?? false
    }

    /// Scripture-like sources are quoted in the prompt in quotation marks so the model reads them
    /// as wording; the rest (an article, a tip, the timetable) are prose it may restate.
    var isQuotable: Bool {
        switch kind {
        case .ayah, .hadith, .dua, .hisnDua, .name: return true
        case .tafsir, .surah, .article, .prayer, .tip, .setting: return false
        }
    }

    /// The family, for keeping a turn's sources varied (no more than a share of the budget from
    /// one family when others have something to say).
    enum Family: String { case quran, hadith, other }
    var family: Family {
        switch kind {
        case .ayah, .tafsir, .surah: return .quran
        case .hadith: return .hadith
        default: return .other
        }
    }

    /// The card's kind label and glyph ("Quran", "book.closed.fill").
    var kindLabel: String {
        switch kind {
        case .ayah: return "Quran"
        case .hadith: return "Hadith"
        case .tafsir: return "Tafsir"
        case .surah: return "Surah"
        case .article: return "Article"
        case .prayer: return "Prayer times"
        case .name: return "Name of Allah"
        case .dua, .hisnDua: return "Dua"
        case .tip: return "App tip"
        case .setting: return "Setting"
        }
    }

    var systemImage: String {
        switch kind {
        case .ayah: return "book.closed.fill"
        case .hadith: return "text.book.closed.fill"
        case .tafsir: return "text.magnifyingglass"
        case .surah: return "book.pages.fill"
        case .article: return "doc.text.fill"
        case .prayer: return "clock.fill"
        case .name: return "sparkle"
        case .dua, .hisnDua: return "hands.and.sparkles.fill"
        case .tip: return "lightbulb.fill"
        case .setting: return "gearshape.fill"
        }
    }

    /// The line the model is given: number, an optional SUBJECT mark, the reference, where it comes
    /// from, then the text clipped to the turn's budget.
    func promptLine(number: Int, characters: Int) -> String {
        let limit = min(maxCharacters, characters)
        let clipped = focusTerms.isEmpty ? Self.clip(text, to: limit) : Self.clip(text, to: limit, around: focusTerms)
        let origin = provenance.isEmpty ? "" : " (" + provenance.joined(separator: "; ") + ")"
        let subject = isSubject ? " SUBJECT OF THE QUESTION:" : ""
        let quoted = wasQuotedBefore ? " (you already quoted this in your previous answer: build on it, do not quote it again)" : ""
        let body = isQuotable ? "\u{201C}\(clipped)\u{201D}" : clipped
        return "[\(number)]\(subject) \(reference)\(origin)\(quoted): \(body)"
    }

    /// Clipped at a sentence end when one falls in the last two fifths of the window (so a
    /// source never hands the model a cut-off sentence to copy), else at a word boundary with an
    /// ellipsis.
    static func clip(_ text: String, to limit: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        let head = String(trimmed.prefix(limit))
        let floor = limit * 3 / 5
        if let end = head.lastIndex(where: { $0 == "." || $0 == "!" || $0 == "?" }),
           head.distance(from: head.startIndex, to: end) >= floor {
            let next = head.index(after: end)
            if next == head.endIndex || head[next] == " " || head[next] == "\n" || head[next] == "\u{201D}" || head[next] == "\"" {
                let cut = next < head.endIndex && (head[next] == "\u{201D}" || head[next] == "\"") ? head.index(after: next) : next
                return String(head[..<cut]).trimmingCharacters(in: .whitespaces)
            }
        }
        if let space = head.lastIndex(of: " "), head.distance(from: head.startIndex, to: space) > limit * 2 / 3 {
            return String(head[..<space]) + "\u{2026}"
        }
        return head + "\u{2026}"
    }

    /// Clipped around the sentence that holds the most of `terms` (folded words the retrieval
    /// matched on) when that sentence lies past the plain clip: a long narration's matching passage
    /// sits deep in it, and a clip from the opening handed the model the wrong part to quote (a
    /// question on patience got Bukhari 4750's opening about drawing lots). The opening stays when
    /// it holds as many of the terms as any later sentence.
    static func clip(_ text: String, to limit: Int, around terms: [String]) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        let wanted = Set(terms.filter { $0.count >= 3 && !$0.contains(" ") })
        guard !wanted.isEmpty else { return clip(trimmed, to: limit) }
        func score(_ range: Range<String.Index>) -> Int {
            let words = Set(AskAILexicon.fold(String(trimmed[range])).split(separator: " ").map(String.init))
            return wanted.intersection(words).count
        }
        // Sentence starts: after ". ", "! " or "? ".
        var starts: [String.Index] = [trimmed.startIndex]
        var index = trimmed.startIndex
        while index < trimmed.endIndex {
            let next = trimmed.index(after: index)
            if ".!?".contains(trimmed[index]), next < trimmed.endIndex, trimmed[next] == " " {
                let start = trimmed.index(after: next)
                if start < trimmed.endIndex { starts.append(start) }
            }
            index = next
        }
        var best: (score: Int, start: String.Index)?
        for (n, start) in starts.enumerated() {
            let end = n + 1 < starts.count ? starts[n + 1] : trimmed.endIndex
            let s = score(start..<end)
            if s > (best?.score ?? 0) { best = (s, start) }
        }
        let openingEnd = trimmed.index(trimmed.startIndex, offsetBy: limit)
        guard let best, best.start >= openingEnd || trimmed.distance(from: trimmed.startIndex, to: best.start) > limit * 3 / 5,
              score(trimmed.startIndex..<openingEnd) < best.score else {
            return clip(trimmed, to: limit)
        }
        return "\u{2026} " + clip(String(trimmed[best.start...]), to: max(80, limit - 2))
    }

    /// The provenance as one footer line ("Surah Al-Baqarah (The Cow) · Saheeh International").
    var provenanceLine: String { provenance.joined(separator: " \u{00B7} ") }
}

// MARK: - Building sources from the app's data

/// Where each kind of source is assembled from the app's own packs, with its provenance. Main actor:
/// the Quran, the hadith store, the names and the duas all live there.
@MainActor
enum AskAISourceFactory {
    /// How much of a tafsir excerpt or a surah's background the model is shown - more than a
    /// retrieved ayah, because when the question names the verse this text IS the answer.
    nonisolated static let subjectCharacterLimit = 1_400

    #if HAS_QURAN
    static func ayah(surah surahID: Int, ayah ayahID: Int, quranData: QuranData,
                     isSubject: Bool = false, maxCharacters: Int = 500) -> AskAISource? {
        guard let surah = quranData.surah(surahID), let ayah = quranData.ayah(surah: surahID, ayah: ayahID) else { return nil }
        let reference = "\(surahID):\(ayahID)"
        let revelation = surah.type.lowercased().hasPrefix("mec") || surah.type.lowercased().hasPrefix("mak") ? "Makki" : (surah.type.lowercased().hasPrefix("med") || surah.type.lowercased().hasPrefix("mad") ? "Madani" : surah.type)
        return AskAISource(
            kind: .ayah(surah: surahID, ayah: ayahID),
            reference: reference,
            title: "\(surah.nameTransliteration) \(reference)",
            text: ayah.textEnglishSaheeh,
            arabic: ayah.textHafs,
            provenance: ["Quran, Surah \(surah.nameTransliteration) (\(surah.nameEnglish)), \(revelation), ayah \(ayahID) of \(surah.numberOfAyahs)",
                         "Saheeh International translation"],
            aliases: ["quran \(reference)", "qur'an \(reference)", "\(surah.nameTransliteration.lowercased()) \(reference)",
                      "surah \(surah.nameTransliteration.lowercased()) \(ayahID)", "\(surah.nameTransliteration.lowercased()) \(ayahID)"],
            maxCharacters: maxCharacters,
            isSubject: isSubject)
    }

    #endif

    #if HAS_HADITH
    static func hadith(book: HadithCatalogBook, data: HadithBookData, hadith: HadithBookData.Hadith,
                       maxCharacters: Int = 600, isSubject: Bool = false) -> AskAISource? {
        let all = hadith.allText
        guard !all.text.isEmpty else { return nil }
        let reference = "\(book.englishTitle) \(hadith.displayNumber)"
        var provenance = ["\(book.englishTitle), compiled by \(book.authorEnglish) (\(book.era))"]
        if let chapter = data.chapter(of: hadith), !chapter.english.isEmpty {
            provenance.append("Chapter: " + AskAISource.clip(chapter.english, to: 90))
        }
        let narrator = all.narrator.trimmingCharacters(in: CharacterSet(charactersIn: ": \n"))
        if !narrator.isEmpty { provenance.append(AskAISource.clip(narrator, to: 90)) }
        let grades = hadith.grades
        if !grades.isEmpty {
            provenance.append("Grade: " + HadithGradeLine.joined(grades))
        } else if book.slug == "bukhari" || book.slug == "muslim" {
            provenance.append("Grade: sahih (the whole collection is graded sahih)")
        }
        // The narrator line is part of what the model should read ("Narrated Anas:" is who is
        // speaking), and the card shows it the same way.
        let text = narrator.isEmpty ? all.text : "\(all.narrator.trimmingCharacters(in: .whitespaces)) \(all.text)"
        let number = hadith.displayNumber.lowercased()
        var aliases = book.aliases.map { "\($0) \(number)" }
        aliases += [book.englishTitle.lowercased() + " " + number, "hadith \(number)"]
        return AskAISource(
            kind: .hadith(slug: book.slug, idInBook: hadith.idInBook),
            reference: reference,
            title: reference,
            text: text,
            arabic: all.arabic,
            provenance: provenance,
            aliases: aliases,
            maxCharacters: maxCharacters,
            isSubject: isSubject)
    }

    #endif

    #if HAS_QURAN
    static func tafsir(surah surahID: Int, ayah ayahID: Int, quranData: QuranData,
                       maxCharacters: Int = subjectCharacterLimit) -> AskAISource? {
        guard let surah = quranData.surah(surahID),
              let entry = TafsirStore.shared.entry(author: .ibnKathir, surah: surahID, ayah: ayahID) else { return nil }
        let plain = AskAIText.plainProse(entry.content)
        guard !plain.isEmpty else { return nil }
        let reference = "Tafsir Ibn Kathir on \(surahID):\(ayahID)"
        return AskAISource(
            kind: .tafsir(surah: surahID, ayah: ayahID, author: TafsirAuthor.ibnKathir.rawValue),
            reference: reference,
            title: reference,
            text: plain,
            provenance: ["Tafsir Ibn Kathir, English edition, commentary on Surah \(surah.nameTransliteration) \(surahID):\(ayahID)"],
            aliases: ["ibn kathir", "tafsir ibn kathir", "ibn kathir on \(surahID):\(ayahID)"],
            maxCharacters: maxCharacters)
    }

    /// The prose that says what a surah is ABOUT. The bundled surah notes open with the period of
    /// revelation (dates, the boycott, who died that year), which answered "what is this surah
    /// about" with history; the theme/subject section, when a source has one, is what the question
    /// means. Returns the text and the note's author.
    private static let themeHeadingRegex = try! NSRegularExpression(
        pattern: #"(?im)^\s*#*\s*(?:theme|subject|subject matter|central theme|summary|contents|topics)\b[^\n]*$"#)

    private static func surahBackground(_ sources: [SurahInfoSource]) -> (text: String, noteAuthor: String)? {
        for source in sources {
            let ns = source.contents as NSString
            if let match = themeHeadingRegex.firstMatch(in: source.contents, range: NSRange(location: 0, length: ns.length)) {
                let plain = AskAIText.plainProse(ns.substring(from: match.range.location))
                if plain.count >= 200 { return (plain, source.name) }
            }
        }
        guard let first = sources.first else { return nil }
        let plain = AskAIText.plainProse(first.contents)
        return plain.isEmpty ? nil : (plain, first.name)
    }

    static func surah(_ surahID: Int, quranData: QuranData, isSubject: Bool = true,
                      maxCharacters: Int = subjectCharacterLimit) -> AskAISource? {
        guard let surah = quranData.surah(surahID) else { return nil }
        let reference = "Surah \(surahID) \(surah.nameTransliteration)"
        let facts = "\(surah.nameTransliteration) (\(surah.nameEnglish)) is surah \(surahID) of the Quran, \(surah.type), with \(surah.numberOfAyahs) ayahs."
        let background = surahBackground(quranData.surahInfoSources(for: surahID))
        let text = background.map { facts + " " + $0.text } ?? facts
        var provenance = ["The Quran, surah \(surahID): \(surah.nameTransliteration) (\(surah.nameEnglish)), \(surah.type), \(surah.numberOfAyahs) ayahs"]
        if let noteAuthor = background?.noteAuthor { provenance.append("About this surah, from \(noteAuthor)") }
        return AskAISource(
            kind: .surah(surahID),
            reference: reference,
            title: "Surah \(surahID) \u{00B7} \(surah.nameTransliteration) (\(surah.nameEnglish))",
            text: text,
            provenance: provenance,
            aliases: ["surah \(surah.nameTransliteration.lowercased())", "surat \(surah.nameTransliteration.lowercased())",
                      surah.nameTransliteration.lowercased(), "surah \(surahID)", "chapter \(surahID)"],
            maxCharacters: maxCharacters,
            isSubject: isSubject)
    }

    #endif

    static func article(_ article: IslamArticle, section: IslamArticle.Section, maxCharacters: Int = 700) -> AskAISource {
        let home = IslamArticleCatalog.all.first(where: { $0.id == article.id })?.home.title
        var provenance = ["Al-Islam\u{2019}s own article \u{201C}\(article.title)\u{201D}" + (home.map { " in \($0)" } ?? "")]
        if !section.heading.isEmpty { provenance.append("Section: \(section.heading.capitalized)") }
        let text = section.heading.isEmpty ? section.text : "\(section.heading.capitalized): \(section.text)"
        // The reference names the SECTION too: two sections of one guide ("Nisab" and "Calculate
        // 2.5%") are two sources, where one reference per article collapsed them into whichever
        // came first.
        let reference = section.heading.isEmpty ? article.title : "\(article.title) \u{203A} \(section.heading.capitalized)"
        // The bare title is an alias only when it is more than one word: "Salah", "Hajj" or
        // "Shirk" appears in any answer on the subject, and claimed every pooled section of that
        // article as cited (41 of the 121 titles are one word).
        let title = article.title.lowercased()
        var aliases = ["the article on \(title)", "the app's article on \(title)"]
        if title.split(separator: " ").count > 1 { aliases.insert(title, at: 0) }
        return AskAISource(
            kind: .article(id: article.id, heading: section.heading),
            reference: reference,
            title: article.title,
            text: text,
            provenance: provenance,
            aliases: aliases,
            maxCharacters: maxCharacters)
    }

    static func name(_ name: NameOfAllah, isSubject: Bool = false) -> AskAISource {
        var text = "\(name.transliteration): \(name.meaning)."
        if !name.desc.isEmpty { text += " " + name.desc }
        if !name.found.isEmpty { text += " Found in the Quran at \(name.found)." }
        var provenance = ["One of the 99 Names of Allah (number \(name.number))"]
        if !name.found.isEmpty { provenance.append("In the Quran: \(name.found)") }
        return AskAISource(
            kind: .name(number: name.number),
            reference: name.transliteration,
            title: "\(name.transliteration) \u{00B7} \(name.meaning)",
            text: text,
            arabic: name.name,
            provenance: provenance,
            aliases: [name.transliteration.lowercased(), name.transliteration.lowercased().replacingOccurrences(of: "-", with: " ")]
                + name.otherNames.map { $0.lowercased() },
            maxCharacters: 600,
            isSubject: isSubject)
    }

    static func dua(_ item: DuaItem, collection: DuaCollection) -> AskAISource? {
        let translation = item.translation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !translation.isEmpty else { return nil }
        let identity = item.identity ?? item.id
        let occasion = collection.title
        var provenance = ["Dua from Al-Islam\u{2019}s \u{201C}\(collection.title)\u{201D} collection"]
        if let reference = item.reference, !reference.isEmpty { provenance.append(reference) }
        return AskAISource(
            kind: .dua(collection: collection.title, identity: identity),
            reference: "Dua (\(occasion)): \(AskAISource.clip(translation, to: 48))",
            title: "Dua \u{00B7} \(occasion)",
            text: translation,
            arabic: item.arabicText.isEmpty ? nil : item.arabicText,
            transliteration: item.transliteration.isEmpty ? nil : item.transliteration,
            provenance: provenance,
            maxCharacters: 400)
    }

    static func hisn(_ entry: HisnDuasStore.Entry, category: String) -> AskAISource? {
        let translation = entry.translation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !translation.isEmpty else { return nil }
        var provenance = ["Hisn al-Muslim (Fortress of the Muslim), \(category)"]
        if !entry.reference.isEmpty { provenance.append(entry.reference) }
        if entry.repeatCount > 1 { provenance.append("Recited \(entry.repeatCount) times") }
        let title = entry.title.isEmpty ? category : entry.title
        return AskAISource(
            kind: .hisnDua(id: entry.id),
            reference: "Hisn al-Muslim \(entry.number): \(AskAISource.clip(title, to: 40))",
            title: "Dua \u{00B7} \(title)",
            text: translation,
            arabic: entry.arabic.isEmpty ? nil : entry.arabic,
            transliteration: entry.transliteration.isEmpty ? nil : entry.transliteration,
            provenance: provenance,
            aliases: ["hisn al-muslim \(entry.number)"],
            maxCharacters: 400)
    }

    /// A setting's place in the app, from the settings search index ("Reciter" at "Quran Settings
    /// → Recitation"): the one source that can answer "how do I change the reciter".
    static func setting(_ entry: SettingsSearchEntry) -> AskAISource {
        var text = "The setting \u{201C}\(entry.title)\u{201D} is at: \(entry.path)."
        if !entry.keywords.isEmpty { text += " It covers: \(entry.keywords)." }
        if entry.advanced { text += " It is shown only with Advanced Settings turned on; opening it from Settings search turns them on." }
        return AskAISource(
            kind: .setting(id: entry.id),
            reference: "Setting: \(entry.title)",
            title: entry.title,
            text: text,
            provenance: ["Al-Islam Settings, at \(entry.path)"],
            aliases: [entry.title.lowercased()],
            maxCharacters: 400)
    }

    #if HAS_TIPS
    static func tip(_ tip: AppTip) -> AskAISource {
        AskAISource(
            kind: .tip(id: tip.id),
            reference: "App tip: \(tip.title)",
            title: tip.title,
            text: "\(tip.detail) Where: \(tip.place).",
            provenance: ["Al-Islam Tips & Tricks, \(tip.area.title)", "Where: \(tip.place)"],
            aliases: [tip.title.lowercased()],
            maxCharacters: 500)
    }

    #endif

    #if HAS_ADHAN
    /// Today's schedule as a source: the times this app computed for this location, with each
    /// prayer's fard count and its sunnah rakahs. Nil when no times have been computed yet.
    static func prayerTimes() -> AskAISource? {
        guard let today = Settings.shared.prayers, !today.fullPrayers.isEmpty else { return nil }
        let clock = DateFormatter()
        clock.timeStyle = .short
        clock.dateStyle = .none
        var lines: [String] = []
        for prayer in today.fullPrayers {
            var line = "\(prayer.displayName) \(clock.string(from: prayer.time))"
            var counts: [String] = []
            if prayer.rakah != "0" { counts.append("\(prayer.rakah) fard") }
            if prayer.sunnahBefore != "0" { counts.append("\(prayer.sunnahBefore) sunnah before") }
            if prayer.sunnahAfter != "0" { counts.append("\(prayer.sunnahAfter) sunnah after") }
            if !counts.isEmpty { line += " (" + counts.joined(separator: ", ") + ")" }
            if let note = prayer.sunnahNote { line += ". " + note }
            lines.append(line)
        }
        let day = today.day.formatted(date: .abbreviated, time: .omitted)
        let place = today.city.isEmpty ? "" : " in \(today.city)"
        // Told the current time too: "how long until Asr" is arithmetic the model can only do if it
        // knows where the day stands.
        let text = "Prayer times\(place) for \(day), computed by this app. It is now \(clock.string(from: Date())).\n"
            + lines.joined(separator: "\n")
        return AskAISource(
            kind: .prayer,
            reference: "Prayer times today",
            title: "Prayer times today" + (today.city.isEmpty ? "" : " \u{00B7} \(today.city)"),
            text: text,
            provenance: ["Computed by this app for \(today.city.isEmpty ? "your location" : today.city) on \(day)"],
            aliases: ["today's prayer times", "the prayer times", "prayer times"],
            maxCharacters: 900,
            isSubject: true)
    }
    #endif
}

#endif
