import SwiftUI
import Foundation
import CoreLocation
import MapKit
import NaturalLanguage
#if HAS_ADHAN
import Adhan
#endif

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
        /// A day's prayer times for a place the question named, or for another day here (Abu,
        /// 2026-11-24: "can it use prayer city times map so it can look at prayer times at other times
        /// and places?"). Opens City Prayer Times on that place and day.
        case cityPrayer(latitude: Double, longitude: Double, city: String, day: Date)
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

        var isAyah: Bool {
            if case .ayah = self { return true }
            return false
        }
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
    /// What else the app holds on this verse or hadith, read with it (AskAIDepth.swift): another
    /// translation, a tafsir, how the readings differ, the hadith's explanation, its other
    /// narrations. Set under the source's line in the prompt, cited by its number, listed on its card.
    var notes: [AskAISourceNote] = []
    /// The answer in the app's own words, when the source IS the answer and every part of it is a
    /// fact the app holds (the reader's Prayer Tracker marks and where a prayer's time stands): set
    /// down as it is, with no model between. Asked to say it, the model kept one half of "Dhuhr's
    /// time ended at 1:13 PM; your tracker has no mark for it" and dropped the other, a different
    /// half each time (2026-11-25). This turn only, like `focusTerms`: never saved.
    var appAnswer: String? = nil

    var id: String { reference }

    /// A verse or a hadith: the sources that are read in depth.
    var isScripture: Bool {
        switch kind {
        case .ayah, .hadith: return true
        default: return false
        }
    }

    private enum CodingKeys: String, CodingKey {
        case kind, reference, title, text, arabic, transliteration, provenance, aliases, maxCharacters, isSubject, notes
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
        // A kind of note a later build added drops the notes, never the source.
        notes = (try? container.decodeIfPresent([AskAISourceNote].self, forKey: .notes)) ?? []
    }

    /// This source with its text cut to `limit` (the saved transcript's form), everything else kept.
    func clippingText(to limit: Int) -> AskAISource {
        guard text.count > limit else { return self }
        var clipped = AskAISource(kind: kind, reference: reference, title: title,
                                  text: AskAISource.clip(text, to: limit),
                                  arabic: arabic, transliteration: transliteration,
                                  provenance: provenance, aliases: aliases,
                                  maxCharacters: maxCharacters, isSubject: isSubject)
        clipped.notes = notes
        return clipped
    }

    /// Scripture-like sources are quoted in the prompt in quotation marks so the model reads them
    /// as wording; the rest (an article, a tip, the timetable) are prose it may restate.
    var isQuotable: Bool {
        switch kind {
        case .ayah, .hadith, .dua, .hisnDua, .name: return true
        case .tafsir, .surah, .article, .prayer, .cityPrayer, .tip, .setting: return false
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
        case .ayah: return String(localized: "Quran")
        case .hadith: return String(localized: "Hadith")
        case .tafsir: return String(localized: "Tafsir")
        case .surah: return String(localized: "Surah")
        // Its own key: "Article" is also the definite article in the tajweed course (لام التعريف).
        case .article: return String(localized: "askai.article", defaultValue: "Article")
        case .prayer, .cityPrayer: return String(localized: "Prayer times")
        case .name: return String(localized: "Name of Allah")
        case .dua, .hisnDua: return String(localized: "Dua")
        case .tip: return String(localized: "App tip")
        case .setting: return String(localized: "Setting")
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
        case .cityPrayer: return "globe.europe.africa.fill"
        case .name: return "sparkle"
        case .dua, .hisnDua: return "hands.and.sparkles.fill"
        case .tip: return "lightbulb.fill"
        case .setting: return "gearshape.fill"
        }
    }

    /// The line the model is given: number, an optional SUBJECT mark, the reference, where it comes
    /// from, then the text clipped to the turn's budget; under it, a line for each note read with it.
    func promptLine(number: Int, characters: Int) -> String {
        let limit = min(maxCharacters, characters)
        let clipped = focusTerms.isEmpty ? Self.clip(text, to: limit) : Self.clip(text, to: limit, around: focusTerms)
        let origin = provenance.isEmpty ? "" : " (" + provenance.joined(separator: "; ") + ")"
        let subject = isSubject ? " SUBJECT OF THE QUESTION:" : ""
        let quoted = wasQuotedBefore ? " (you already quoted this in your previous answer: build on it, do not quote it again)" : ""
        let body = isQuotable ? "\u{201C}\(clipped)\u{201D}" : clipped
        let line = "[\(number)]\(subject) \(reference)\(origin)\(quoted): \(body)"
        return ([line] + notes.map { $0.promptLine(number: number) }).joined(separator: "\n")
    }

    /// What the notes cost the window, in characters.
    var notesCost: Int { notes.reduce(0) { $0 + $1.promptCost } }

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
        // The Tajweed Foundations pages and the course's lessons are no catalog article, but the
        // reference is their home. A Hadith Encyclopedia page is not the app's own writing at all.
        let home = IslamArticleCatalog.all.first(where: { $0.id == article.id })?.home.title
            ?? (TajweedTopic.topic(pageID: article.id) != nil ? "Tajweed Foundations"
                : article.id.hasPrefix(IslamArticle.lessonPrefix) ? "the Tajweed Course" : nil)
        var provenance = article.id.hasPrefix(IslamArticle.encyclopediaPrefix)
            ? ["The Hadith Encyclopedia (hadeethenc.com), its page \u{201C}\(article.title)\u{201D}"]
            : ["\(AppIdentifiers.appName)\u{2019}s own article \u{201C}\(article.title)\u{201D}" + (home.map { " in \($0)" } ?? "")]
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
        var provenance = ["Dua from \(AppIdentifiers.appName)\u{2019}s \u{201C}\(collection.title)\u{201D} collection"]
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
        // English in every interface language (`englishTitle`): the model reads it and the transcript keeps
        // it. The card draws the title in the interface language (`AskAISourceCard.displayTitle`).
        let title = entry.englishTitle
        var text = "The setting \u{201C}\(title)\u{201D} is at: \(entry.path)."
        if !entry.keywords.isEmpty { text += " It covers: \(entry.keywords)." }
        if entry.advanced { text += " It is shown only with Advanced Settings turned on; opening it from Settings search turns them on." }
        return AskAISource(
            kind: .setting(id: entry.id),
            reference: "Setting: \(title)",
            title: title,
            text: text,
            provenance: ["\(AppIdentifiers.appName) Settings, at \(entry.path)"],
            aliases: [title.lowercased()],
            maxCharacters: 400)
    }

    #if HAS_TIPS
    static func tip(_ tip: AppTip) -> AskAISource {
        // The tip's English (`AppTip.english`) in every interface language, as for a setting above.
        let english = tip.english
        return AskAISource(
            kind: .tip(id: tip.id),
            reference: "App tip: \(english.title)",
            title: english.title,
            text: "\(english.detail) Where: \(english.place).",
            provenance: ["\(AppIdentifiers.appName) Tips & Tricks, \(tip.area.englishTitle)", "Where: \(english.place)"],
            aliases: [english.title.lowercased()],
            maxCharacters: 500)
    }

    #endif

    #if HAS_ADHAN
    /// Today's schedule where the reader is, as a source: what a question that only NAMES a prayer
    /// is given beside its other sources ("did I miss Asr"). Nil when there is no location yet.
    static func prayerTimes(asking raw: String? = nil) -> AskAISource? {
        // What the question asks for beside the times (the rakah counts, the night's times), for
        // today and here whatever else it says.
        var request = raw.map { AskAIPrayerRequest.parse($0) } ?? AskAIPrayerRequest()
        request.place = nil
        request.day = nil
        request.dayPhrase = nil
        request.topics.subtract([.week, .events, .hijri, .qibla])
        request.namesPrayer = true
        return prayerSource(for: request, place: nil)
    }

    /// What a prayer-times question asks for, computed by the app so the model copies and never
    /// calculates: the day's times (a named place with the method of its own country, as City Prayer
    /// Times does; the reader's place with the reader's own method; every time in the place's own
    /// clock), how long until each one, and, when the question asks, the night's times, the fast,
    /// a week's timetable, the Hijri date, the coming Islamic dates and the qibla's bearing.
    static func prayerTimes(for request: AskAIPrayerRequest) async -> AskAISource? {
        guard let named = request.place else { return prayerSource(for: request, place: nil) }
        guard let found = await AskAIPrayerRequest.locate(named) else {
            // Said plainly, so the answer says it rather than giving the times of somewhere else.
            return AskAISource(
                kind: .prayer,
                reference: "Prayer times: place not found",
                title: "Prayer times \u{00B7} \(named)",
                text: "The reader asked about \u{201C}\(named)\u{201D}, but this app could not find that place on the map (looking a place up needs an internet connection). Say so, suggest checking the spelling or adding the country, and mention City Prayer Times in the Adhan tab, where any city can be chosen on a map.",
                provenance: ["Looked up by this app on Apple Maps"],
                aliases: ["prayer times", "the prayer times"],
                maxCharacters: 600,
                isSubject: true)
        }
        return prayerSource(for: request, place: found)
    }

    private static func prayerSource(for request: AskAIPrayerRequest, place named: AskAIPrayerRequest.Place?) -> AskAISource? {
        let settings = Settings.shared
        let place: AskAIPrayerRequest.Place
        if let named {
            place = named
        } else {
            guard let here = settings.currentLocation, here.latitude != 1000, here.longitude != 1000 else { return nil }
            // The city is geocoded in the interface language, so outside English it can be an Arabic
            // name with no English one beside it: Apple's model turns away a prompt with much Arabic,
            // and an English answer would quote the name. The card's title keeps the name the reader knows.
            let name = here.city.isMostlyArabicScript || here.city.isEmpty ? "your current location" : here.city
            place = .init(location: here, name: name, timeZone: .current, countryCode: nil, isHere: true)
        }

        let now = Date()
        let day = request.day ?? now
        let topics = request.topics
        // The reader's own method where the reader is; the country's own method elsewhere (the City
        // Prayer Times rule), so Makkah reads Umm al-Qura and London the method used in Britain.
        let method = place.isHere ? nil : place.countryCode.map { settings.recommendedCalculationMethod(forCountryCode: $0) }
        let methodName = method ?? settings.prayerCalculation
        func times(on date: Date) -> [Prayer] {
            settings.getPrayerTimes(for: date, at: place.location, fullPrayers: true, calculationOverride: method) ?? []
        }
        let prayers = times(on: day)
        guard !prayers.isEmpty else { return nil }

        // The model reads English: the prayer names, the times and the dates. In an English interface
        // the clock keeps the reader's own region format (a 24-hour clock stays one); in another
        // language it is pinned to US English (Western digits, English month names).
        let english = Locale(identifier: "en_US")
        let clock = DateFormatter()
        clock.locale = AppLanguage.code.hasPrefix("en") ? .current : english
        clock.timeZone = place.timeZone
        clock.timeStyle = .short
        clock.dateStyle = .none
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = place.timeZone
        func written(_ date: Date, _ style: Date.FormatStyle.DateStyle) -> String {
            date.formatted(Date.FormatStyle(date: style, time: .omitted, locale: english, calendar: calendar, timeZone: place.timeZone))
        }
        func name(_ prayer: Prayer) -> String { prayer.nameCustom ?? prayer.nameTransliteration }
        func time(_ named: String, in list: [Prayer]) -> Date? { list.first { $0.nameTransliteration == named }?.time }
        let isToday = calendar.isDate(day, inSameDayAs: now)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        let at = place.name == "your current location" ? "at" : "in"

        var text = request.wantsTimes ? "Prayer times \(at) \(place.name) for \(written(day, .complete))" : "\(written(day, .complete)) \(at) \(place.name)"
        // Which day the reader's word meant, said as a fact: beside a bare (The reader said "tomorrow")
        // the model counted a day on from the date given.
        if let phrase = request.dayPhrase { text += " (the day the reader calls \u{201C}\(phrase)\u{201D})" }
        if request.wantsTimes {
            text += ", computed by this app with the \(methodName) method" + (place.isHere ? "." : ", in the local time of \(place.name).")
        } else {
            text += "."
        }
        if isToday {
            text += " It is now \(clock.string(from: now))\(place.isHere ? "" : " there")."
        }
        // The answer itself, said first and worked out here: the prayers the question names, each
        // with how far off it is today, else what comes next. ONE countdown on purpose. With "the
        // next one is Asr, in 25 minutes" above a list that gave every prayer its own, "How long
        // until Isha?" was answered "25 minutes"; and left under the list, "What is the next
        // prayer?" got the list's first line (Fajr, at midday).
        if request.wantsTimes, !topics.contains(.week), !(topics.contains(.tracker) && place.isHere) {
            let asked = request.prayers.compactMap { wanted in
                prayers.first { $0.nameTransliteration == wanted }
                    ?? (wanted == "Dhuhr" ? prayers.first { $0.nameTransliteration == "Jumuah" } : nil)
            }
            for prayer in asked.prefix(3) {
                let at = clock.string(from: prayer.time)
                if !isToday {
                    text += " \(name(prayer)) is at \(at)."
                } else if prayer.time > now {
                    text += " \(name(prayer)) is at \(at), in \(span(now, prayer.time))."
                } else {
                    text += " \(name(prayer)) was at \(at), \(span(prayer.time, now)) ago."
                }
            }
            if asked.isEmpty, isToday, !topics.contains(.tracker) {
                if let next = prayers.first(where: { $0.time > now }) {
                    text += " The next one is \(name(next)) at \(clock.string(from: next.time)), in \(span(now, next.time))."
                } else if let fajr = time("Fajr", in: times(on: nextDay)) {
                    text += " Every time for today has come: the next one is Fajr tomorrow at \(clock.string(from: fajr)), in \(span(now, fajr))."
                }
            }
        }

        var trackerAnswer: String?
        // The reader's own record (here only: the tracker is theirs, not a city's), and for a
        // prayer they name, where its time stands. Everything the model could get wrong is worked
        // out: "its time is still on" and "its time ended" are said, never left to be reckoned.
        if topics.contains(.tracker), place.isHere {
            let five = prayers.filter { ["Fajr", "Dhuhr", "Jumuah", "Asr", "Maghrib", "Isha"].contains($0.nameTransliteration) }
            func ends(_ prayer: Prayer) -> (time: Date, what: String)? {
                if prayer.nameTransliteration == "Fajr", let sunrise = time("Shurooq", in: prayers) { return (sunrise, "at sunrise") }
                if let index = five.firstIndex(where: { $0.nameTransliteration == prayer.nameTransliteration }), index + 1 < five.count {
                    return (five[index + 1].time, "when \(name(five[index + 1])) began")
                }
                if let fajr = time("Fajr", in: times(on: nextDay)) { return (fajr, "at Fajr the next morning") }
                return nil
            }
            func record(_ prayer: Prayer) -> String {
                switch settings.prayerMark(for: prayer.nameTransliteration, on: day) {
                case .onTime?: return "marked as prayed on time"
                case .late?: return "marked as prayed late"
                case .missed?: return "marked as missed"
                case nil: return isToday && prayer.time > now ? "not marked (its time has not come yet)" : "not marked"
                }
            }
            let asked = request.prayers.compactMap { wanted in
                five.first { $0.nameTransliteration == wanted } ?? (wanted == "Dhuhr" ? five.first { $0.nameTransliteration == "Jumuah" } : nil)
            }
            // One sentence a prayer, the clock and the record together: given the two apart, "Did I
            // miss Dhuhr?" was answered with the record alone, and whether its time had passed is
            // the half that was asked.
            let trackerStart = text.utf8.count
            for prayer in asked.prefix(3) {
                let began = clock.string(from: prayer.time)
                var sentence: String
                if !isToday {
                    sentence = " \(name(prayer)) is at \(began)"
                } else if prayer.time > now {
                    sentence = " \(name(prayer)) is at \(began), in \(span(now, prayer.time)), so its time has not come yet"
                } else if let end = ends(prayer), end.time > now {
                    sentence = " \(name(prayer)) began at \(began) and its time is still on, until \(clock.string(from: end.time)) (\(span(now, end.time)) from now)"
                } else if let end = ends(prayer) {
                    sentence = " \(name(prayer)) was at \(began) and its time ended at \(clock.string(from: end.time)), \(end.what)"
                } else {
                    sentence = " \(name(prayer)) was at \(began)"
                }
                text += sentence + ". In your Prayer Tracker it is \(record(prayer)) for \(isToday ? "today" : "that day")."
            }
            if asked.isEmpty {
                text += " Your Prayer Tracker for \(isToday ? "today" : written(day, .abbreviated)):\n"
                    + five.map { "\(name($0)): \(record($0))" }.joined(separator: "\n")
            }
            trackerAnswer = String(decoding: text.utf8.dropFirst(trackerStart), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            text += "\n(The tracker holds only what the reader has marked themselves.)"
        }

        var shortSpan = written(day, .abbreviated)
        if request.wantsTimes, topics.contains(.week) {
            // A run of days, one line each: the times alone.
            let count = max(2, min(7, request.days))
            let last = calendar.date(byAdding: .day, value: count - 1, to: day) ?? day
            shortSpan += " to " + written(last, .abbreviated)
            text += " The \(count) days from then:"
            for offset in 0..<count {
                guard let date = calendar.date(byAdding: .day, value: offset, to: day) else { continue }
                let list = offset == 0 ? prayers : times(on: date)
                let weekday = date.formatted(Date.FormatStyle(locale: english, calendar: calendar, timeZone: place.timeZone)
                    .weekday(.abbreviated).month(.abbreviated).day())
                text += "\n\(weekday): " + list.map { "\(name($0)) \(clock.string(from: $0.time))" }.joined(separator: ", ")
            }
        } else if request.wantsTimes, !(topics.contains(.tracker) && place.isHere) {
            // The times alone. The rakah counts ride along only when asked for (beside every time,
            // the model read Fajr's "2 sunnah before" back as "2 sunnah after" and gave Isha's
            // counts to iftar).
            text += "\n" + prayers.map { prayer in
                var line = "\(name(prayer)) \(clock.string(from: prayer.time))"
                var notes: [String] = []
                if topics.contains(.rakahs) {
                    if prayer.rakah != "0" { notes.append("\(prayer.rakah) fard") }
                    if prayer.sunnahBefore != "0" { notes.append("\(prayer.sunnahBefore) sunnah before") }
                    if prayer.sunnahAfter != "0" { notes.append("\(prayer.sunnahAfter) sunnah after") }
                }
                if !notes.isEmpty { line += " (" + notes.joined(separator: "; ") + ")" }
                if topics.contains(.rakahs), let note = prayer.sunnahNote { line += ". " + note }
                return line
            }.joined(separator: "\n")
        }

        if topics.contains(.night) || topics.contains(.duha) {
            let extra = settings.optionalPrayers(for: day, at: place.location, calculationOverride: method,
                                                 duha: true, islamicMidnight: true, lastThird: true)
            if topics.contains(.night), let midnight = time("Islamic Midnight", in: extra), let third = time("Last Third", in: extra) {
                text += "\nThe night: the preferred time of Isha ends at Islamic midnight, \(clock.string(from: midnight)). The last third of the night, the best time for Tahajjud and the night prayer, begins at \(clock.string(from: third))"
                if let fajr = time("Fajr", in: times(on: nextDay)) { text += " and lasts until Fajr the next morning, \(clock.string(from: fajr))" }
                text += "."
            }
            if topics.contains(.duha), let duha = time("Duhaa", in: extra) {
                text += "\nDuha, the forenoon prayer, can be prayed from \(clock.string(from: duha)) until shortly before Dhuhr."
            }
        }
        if topics.contains(.fasting), let fajr = time("Fajr", in: prayers), let maghrib = time("Maghrib", in: prayers) {
            // "Suhoor ends at Fajr" came back as "suhoor begins at Fajr": said as a deadline.
            text += "\nFasting on this day: suhoor, the meal before dawn, must be finished by Fajr at \(clock.string(from: fajr)), when the fast begins. Iftar, breaking the fast, is at Maghrib, \(clock.string(from: maghrib))."
        }
        if topics.contains(.method), place.isHere {
            text += "\nThe reader\u{2019}s prayer settings: the \(methodName) calculation method, and Asr by the \(settings.hanafiMadhab ? "Hanafi" : "standard (Shafi\u{2019}i, Maliki and Hanbali)") shadow rule. Both are changed in the app\u{2019}s prayer settings."
        }
        if topics.contains(.hijri) || topics.contains(.events) {
            // Today's Hijri date as the Adhan tab shows it (it turns at Maghrib when the reader has
            // that on); another day's by the calendar.
            let reference = isToday && place.isHere ? settings.effectiveHijriReferenceDate(now: now) : day
            text += "\nThe Hijri date \(isToday ? "now" : "that day") is \(hijriDate(reference)), on this app\u{2019}s Umm al-Qura calendar"
                + (settings.hijriOffset == 0 ? "." : " with the reader\u{2019}s adjustment of \(settings.hijriOffset) day\(abs(settings.hijriOffset) == 1 ? "" : "s").")
        }
        if topics.contains(.events) {
            let lines = comingEvents(matching: request.eventWords, after: now, year: request.eventYear)
            if !lines.isEmpty {
                text += "\nComing dates on this app\u{2019}s Hijri calendar, soonest first (a month really begins when its crescent is sighted, so a date can fall a day either side):\n"
                    + lines.joined(separator: "\n")
            }
        }
        if topics.contains(.qibla) {
            let bearing = Qibla(coordinates: Coordinates(latitude: place.location.latitude, longitude: place.location.longitude)).direction
            text += "\nThe qiblah from \(place.name): the Ka‘bah lies \(Int(bearing.rounded())) degrees clockwise from true north, to the \(compassPoint(bearing)). The Qiblah compass in the Adhan tab points to it."
        }

        let plainToday = place.isHere && isToday && !topics.contains(.week)
        let cityTitle = place.isHere ? place.location.city : place.name
        // A card of its own name for what is not a timetable: the qibla from a place, the calendar.
        let reference: String
        let title: String
        if !request.wantsTimes, topics.contains(.qibla) {
            reference = "Qiblah direction from \(place.name)"
            title = "Qiblah direction" + (cityTitle.isEmpty ? "" : " \u{00B7} \(cityTitle)")
        } else if !request.wantsTimes {
            reference = "Islamic dates on \(shortSpan)"
            title = "Islamic dates \u{00B7} \(shortSpan)"
        } else if plainToday {
            reference = "Prayer times today"
            title = "Prayer times today" + (cityTitle.isEmpty ? "" : " \u{00B7} \(cityTitle)")
        } else {
            reference = "Prayer times \(at) \(place.name) on \(shortSpan)"
            title = "Prayer times \u{00B7} \(cityTitle) \u{00B7} \(shortSpan)"
        }
        var source = AskAISource(
            kind: plainToday ? .prayer : .cityPrayer(latitude: place.location.latitude, longitude: place.location.longitude,
                                                     city: place.location.city, day: day),
            reference: reference,
            title: title,
            text: text,
            provenance: ["Computed by this app for \(place.name) on \(written(day, .complete))"]
                + (request.wantsTimes ? ["Calculation method: \(methodName)"] : [])
                + (place.isHere ? [] : ["Times in local time (\(place.timeZone.identifier))"]),
            aliases: ["today's prayer times", "the prayer times", "prayer times", "prayer times in \(place.name.lowercased())"],
            maxCharacters: 1_500,
            isSubject: true)
        source.appAnswer = trackerAnswer
        return source
    }

    /// "53 minutes", "1 hour 5 minutes", "2 hours": the whole minutes from one moment to a later one,
    /// counted the way a countdown reads (12:20 to 1:13 is 53 minutes at any second of 12:20).
    private static func span(_ from: Date, _ to: Date) -> String {
        let start = (from.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60
        let minutes = max(0, Int(((to.timeIntervalSinceReferenceDate - start) / 60).rounded(.down)))
        let hours = minutes / 60, rest = minutes % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) hour\(hours == 1 ? "" : "s")") }
        if rest > 0 || hours == 0 { parts.append("\(rest) minute\(rest == 1 ? "" : "s")") }
        return parts.joined(separator: " ")
    }

    /// The Hijri date of `date` in English ("15 Jumada II 1448 AH"), with the reader's adjustment.
    private static func hijriDate(_ date: Date) -> String {
        let settings = Settings.shared
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = .current
        let adjusted = calendar.date(byAdding: .day, value: settings.hijriOffset, to: date) ?? date
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMMM y"
        return formatter.string(from: adjusted) + " AH"
    }

    /// The app's Islamic dates still to come, soonest first, as lines for the model: the next
    /// occurrence of each one the question names ("ramadan", "eid"), or the ones in the civil year it
    /// names ("next year", "2028"), else the next five of any. Few lines on purpose: given six, the
    /// model answered "how many days until Eid" with the last. Placed on the civil calendar as the
    /// Hijri calendar screen places them (`IslamicEventLookup`).
    private static func comingEvents(matching words: [String], after now: Date, year civilYear: Int?) -> [String] {
        let settings = Settings.shared
        let hijri = settings.hijriCalendar
        let civil = Calendar.current
        let today = civil.startOfDay(for: now)
        let adjusted = hijri.date(byAdding: .day, value: settings.hijriOffset, to: now) ?? now
        let year = hijri.component(.year, from: adjusted)
        var found: [(title: String, date: Date, night: Bool)] = []
        for hijriYear in year...(year + 2) {
            for event in Settings.specialEvents(inHijriYear: hijriYear) {
                var components = event.1
                components.year = hijriYear
                guard let unadjusted = hijri.date(from: components) else { continue }
                let placed = civil.startOfDay(for: hijri.date(byAdding: .day, value: -settings.hijriOffset, to: unadjusted) ?? unadjusted)
                if placed >= today { found.append((event.0, placed, Settings.nightEventTitles.contains(event.0))) }
            }
        }
        found.sort { $0.date < $1.date }
        // "eid" names both Eids; "hajj" and "dhul hijjah" the days around it.
        let wanted = words.map { $0 == "arafat" ? "arafah" : $0 == "ramadhan" ? "ramadan" : $0 == "hijjah" || $0 == "dhul" ? "dhul-hijjah" : $0 }
        // "End of Eid Al-Adha" answers no "when is Eid".
        let named = found.filter { event in
            wanted.contains { event.title.lowercased().contains($0) } && !event.title.hasPrefix("End of")
        }
        let inYear = civilYear.map { wanted in named.filter { civil.component(.year, from: $0.date) == wanted } } ?? []
        let chosen: [(title: String, date: Date, night: Bool)]
        if !inYear.isEmpty {
            chosen = Array(inYear.prefix(4))
        } else if named.isEmpty {
            chosen = Array(found.prefix(5))
        } else {
            var seen = Set<String>()
            chosen = Array(named.filter { seen.insert($0.title).inserted }.prefix(4))
        }
        let english = Locale(identifier: "en_US")
        return chosen.map { event in
            let days = civil.dateComponents([.day], from: today, to: event.date).day ?? 0
            let when = days == 0 ? "today" : days == 1 ? "tomorrow" : "in \(days) days"
            let date = event.date.formatted(Date.FormatStyle(date: .complete, time: .omitted, locale: english, calendar: Calendar(identifier: .gregorian)))
            return "\(event.title): \(date) (\(when))" + (event.night ? ", beginning at Maghrib the evening before" : "")
        }
    }

    /// The compass point a bearing falls in ("northeast", "east-northeast").
    private static func compassPoint(_ degrees: Double) -> String {
        let points = ["north", "north-northeast", "northeast", "east-northeast", "east", "east-southeast", "southeast",
                      "south-southeast", "south", "south-southwest", "southwest", "west-southwest", "west",
                      "west-northwest", "northwest", "north-northwest"]
        let turned = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return points[Int((turned / 22.5).rounded()) % 16]
    }
    #endif
}

#if HAS_ADHAN
/// What a prayer-times question asks beyond "today, here": a PLACE ("in London", "for Makkah",
/// "Irvine, CA") and a DAY ("tomorrow", "next Friday", "on December 25", "in 3 days"). The day is read
/// by Foundation's date detector; the place by the language tagger's place names, then by the words
/// after "in", "at", "for" or "of" (the tagger misses a lowercase "cairo"), and is checked on the map.
struct AskAIPrayerRequest: Equatable {
    /// The place as written, nil for where the reader is.
    var place: String?
    /// The day asked about, nil for today.
    var day: Date?
    /// The day's words as written, so the model can say "tomorrow" back.
    var dayPhrase: String?
    /// What the question asks for beside (or instead of) the day's times.
    var topics: Topics = []
    /// The Islamic dates it names ("ramadan", "eid"), for `Topics.events`.
    var eventWords: [String] = []
    /// The civil year it asks about ("next year", "in 2028"), for `Topics.events`.
    var eventYear: Int?
    /// How many days a `Topics.week` timetable runs (2 to 7).
    var days = 7
    /// It names a prayer, or the prayer times as such.
    var namesPrayer = false
    /// The prayers of the day it names, by `Prayer.nameTransliteration` ("Fajr", "Isha").
    var prayers: [String] = []
    /// The other places a question names beside `place` ("Fajr in Makkah and Cairo"), in the order
    /// written: each gets its own timetable, and the app sets the answer down itself.
    var morePlaces: [String] = []

    struct Topics: OptionSet, Equatable {
        let rawValue: Int
        /// The fard and sunnah counts beside each time.
        static let rakahs = Topics(rawValue: 1 << 0)
        /// Islamic midnight (when Isha's preferred time ends) and the last third of the night.
        static let night = Topics(rawValue: 1 << 1)
        /// Suhoor's end and iftar.
        static let fasting = Topics(rawValue: 1 << 2)
        static let duha = Topics(rawValue: 1 << 3)
        /// The calculation method and the Asr rule the reader's times use.
        static let method = Topics(rawValue: 1 << 4)
        /// The Hijri date of the day.
        static let hijri = Topics(rawValue: 1 << 5)
        /// When Ramadan, an Eid, Arafah or another date of the app's Hijri calendar falls.
        static let events = Topics(rawValue: 1 << 6)
        /// The qibla's bearing from the place.
        static let qibla = Topics(rawValue: 1 << 7)
        /// Several days' times at once.
        static let week = Topics(rawValue: 1 << 8)
        /// The reader's own marks in the Prayer Tracker ("did I pray Fajr today?", "did I miss
        /// Dhuhr?"), with whether a named prayer's time has come, is on, or has passed.
        static let tracker = Topics(rawValue: 1 << 9)

        /// What is answered without the day's timetable.
        static let calendarOnly: Topics = [.hijri, .events, .qibla]
    }

    var isPlainToday: Bool { place == nil && day == nil }

    /// The day's times belong in the answer: always, except for a question that is only about the
    /// calendar or the qibla ("When is Ramadan?", "Which way is the qibla?").
    var wantsTimes: Bool { namesPrayer || topics.isEmpty || !topics.subtracting(.calendarOnly).isEmpty }

    /// It carries on a talk about the times: a place, a day, a prayer or one of the topics.
    var continuesPrayerTalk: Bool { place != nil || day != nil || namesPrayer || !topics.isEmpty }

    /// A follow-up's request: what it does not say itself is what the question before it asked
    /// ("Fajr in Makkah tomorrow", then "And in Cairo?", then "What about Maghrib?").
    func inheriting(_ previous: AskAIPrayerRequest) -> AskAIPrayerRequest {
        var merged = self
        if merged.place == nil { merged.place = previous.place }
        if merged.day == nil {
            merged.day = previous.day
            merged.dayPhrase = previous.dayPhrase
        }
        if merged.topics.isEmpty, !merged.namesPrayer {
            merged.topics = previous.topics
            merged.eventWords = previous.eventWords
            merged.eventYear = previous.eventYear
            merged.days = previous.days
            merged.namesPrayer = previous.namesPrayer
            merged.prayers = previous.prayers
        }
        return merged
    }

    /// A place found on the map.
    struct Place {
        let location: Location
        /// In English, for the model: "London, United Kingdom".
        let name: String
        let timeZone: TimeZone
        let countryCode: String?
        let isHere: Bool
    }

    static func parse(_ raw: String, now: Date = Date()) -> AskAIPrayerRequest {
        var request = AskAIPrayerRequest()
        var remainder = raw
        let ns = raw as NSString
        if let match = dateDetector?.matches(in: raw, range: NSRange(location: 0, length: ns.length)).first(where: { $0.date != nil }),
           let date = match.date {
            // "tonight", "now" and "today" are today.
            if !Calendar.current.isDate(date, inSameDayAs: now) {
                request.day = date
                request.dayPhrase = ns.substring(with: match.range)
            }
            remainder = ns.replacingCharacters(in: match.range, with: " ")
        }
        let named = places(in: remainder)
        request.place = named.last
        request.morePlaces = Array(named.dropLast().suffix(2))

        let folded = AskAILexicon.fold(raw)
        let words = Set(folded.split(separator: " ").map(String.init))
        func has(_ list: Set<String>) -> Bool { !words.isDisjoint(with: list) }
        request.namesPrayer = has(AskAILexicon.prayerNames) || folded.contains("prayer time") || folded.contains("salah time")
        // In the day's order; iftar is Maghrib's time and suhoor ends at Fajr's.
        request.prayers = prayerSpellings.filter { has($0.words) }.map(\.name)
        if has(["rakah", "rakahs", "rakat", "rakats", "rakaat", "rakaats", "sunnah", "sunnahs", "fard", "nafl", "units"]) {
            request.topics.insert(.rakahs)
        }
        if has(["midnight", "tahajjud", "tahajud", "qiyam", "third"])
            || (words.contains("isha") && has(["end", "ends", "late", "latest", "last", "deadline", "delay"]))
            || (words.contains("night") && has(["half", "middle", "last"])) {
            request.topics.insert(.night)
        }
        if has(["suhoor", "suhur", "sahur", "sahoor", "sehri", "iftar", "iftaar", "fast", "fasting", "imsak"]) { request.topics.insert(.fasting) }
        if has(["duha", "duhaa", "dhuha", "ishraq", "forenoon"]) { request.topics.insert(.duha) }
        if has(["method", "calculation", "calculated", "calculate", "computed", "madhab", "madhhab", "hanafi", "angle", "angles", "convention"]) {
            request.topics.insert(.method)
        }
        if words.contains("hijri") || ["islamic date", "islamic calendar", "islamic month", "islamic year", "lunar date"].contains(where: folded.contains) {
            request.topics.insert(.hijri)
        }
        request.eventWords = eventWords.filter(words.contains)
        if folded.contains("new year") { request.eventWords.append("new year") }
        let thisYear = Calendar(identifier: .gregorian).component(.year, from: now)
        if let written = words.compactMap({ Int($0) }).first(where: { (2000...2200).contains($0) }) {
            request.eventYear = written
        } else if folded.contains("next year") {
            request.eventYear = thisYear + 1
        } else if folded.contains("this year") {
            request.eventYear = thisYear
        }
        if !request.eventWords.isEmpty, has(["when", "date", "dates", "day", "days", "long", "until", "till", "far", "start", "starts", "begin",
                                              "begins", "end", "ends", "next", "coming", "upcoming", "soon", "left", "countdown", "calendar"]) {
            request.topics.insert(.events)
        }
        if has(["qibla", "qiblah", "qiblat", "kiblat"]) { request.topics.insert(.qibla) }
        // The reader's own record: "did I pray Fajr", "have I missed Asr", "which prayers have I
        // prayed today". A question about the record, not about the clock or what is allowed: "What
        // time should I pray Fajr tomorrow?" and "Can I pray Asr now?" hold the same words and ask
        // for a time.
        if has(["i", "ive", "my", "me"]),
           has(["pray", "prayed", "miss", "missed", "mark", "marked", "log", "logged", "track", "tracked", "tracker", "done", "offered"]),
           request.namesPrayer || has(["prayer", "prayers", "salah", "salat", "namaz", "tracker"]),
           has(["did", "have", "ive", "which", "any", "tracker", "am"]),
           !has(["when", "time", "times", "should", "can", "could", "may", "until", "till", "long", "where", "why"]),
           !words.contains("how") || folded.contains("how many") {
            request.topics.insert(.tracker)
        }
        if has(["week", "weekly", "weeks", "weekend"]) {
            request.topics.insert(.week)
        } else if let match = daysRegex.firstMatch(in: folded, range: NSRange(location: 0, length: (folded as NSString).length)) {
            let written = (folded as NSString).substring(with: match.range(at: 1))
            let count = Int(written) ?? ["two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7][written] ?? 0
            if count >= 2 {
                request.topics.insert(.week)
                request.days = min(7, count)
            }
        }
        return request
    }

    private static let prayerSpellings: [(name: String, words: Set<String>)] = [
        ("Fajr", ["fajr", "suhoor", "suhur", "sahur", "sahoor", "sehri"]), ("Shurooq", ["sunrise", "shuruq", "shurooq"]),
        ("Dhuhr", ["dhuhr", "duhr", "zuhr", "dhur"]), ("Jumuah", ["jumuah", "jumaah", "jummah"]), ("Asr", ["asr"]),
        ("Maghrib", ["maghrib", "iftar", "iftaar"]), ("Isha", ["isha", "ishaa", "esha"]),
    ]

    /// The Islamic dates a question can name, as the app's Hijri calendar lists them.
    private static let eventWords = ["ramadan", "ramadhan", "eid", "arafah", "arafat", "ashura", "hajj", "dhul", "hijjah", "muharram"]
    private static let daysRegex = try! NSRegularExpression(pattern: #"\b(?:next|coming|following) (\d|two|three|four|five|six|seven) days\b"#)

    /// "How many rakahs is Maghrib?": the fard and sunnah counts of the five prayers are the app's own
    /// data, beside each time. Read from the library instead, the answer was "Maghrib is two rakahs",
    /// from a hadith about the two sunnah after it (2026-11-25). A prayer the day's list does not
    /// hold (Tahajjud, Witr, Tarawih) stays with the library.
    static func asksRakahCount(_ raw: String) -> Bool {
        let request = parse(raw)
        guard request.topics.contains(.rakahs), !request.prayers.isEmpty else { return false }
        let words = Set(AskAILexicon.fold(raw).split(separator: " ").map(String.init))
        return !words.isDisjoint(with: ["many", "number", "count", "counts"])
            && words.isDisjoint(with: ["why", "travel", "traveling", "travelling", "traveler", "qasr", "shorten", "missed", "miss", "witr", "tahajjud", "tarawih", "taraweeh", "eid", "janazah"])
    }

    /// "Did I pray Fajr today?", "Did I miss Dhuhr?", "Which prayers have I prayed today?": the
    /// reader's own record and the clock, both the app's. Read as fiqh ("miss" is a fiqh word),
    /// "Did I miss Dhuhr?" was answered with the ruling on making up a missed prayer (2026-11-25).
    /// A question that asks what to DO about it stays with the library ("I missed Fajr, what should I do?").
    static func asksTracker(_ raw: String) -> Bool {
        let request = parse(raw)
        guard request.topics.contains(.tracker) else { return false }
        let folded = AskAILexicon.fold(raw)
        let words = Set(folded.split(separator: " ").map(String.init))
        let asksWhatToDo: Set<String> = ["should", "how", "ruling", "sin", "sinful", "allowed", "permissible", "haram", "qada",
                                         "makeup", "kaffarah", "why", "forgive", "forgiven", "repent", "valid", "count", "counts"]
        guard words.isDisjoint(with: asksWhatToDo), !folded.contains("make up"), !folded.contains("what do i do") else { return false }
        // A question about now: "did I", "have I", "am I", "which", "what" with the reader as its subject.
        return !words.isDisjoint(with: ["did", "have", "ive", "which", "what", "am", "is", "any", "tracker", "show"])
    }

    /// Whether a question asks for something the app computes beside the times: today's Hijri date,
    /// when one of its Islamic dates falls, or the qibla's bearing. A question about their history or
    /// their rulings is left to the library ("why did the qibla change", "when should I fast Arafah").
    static func asksDateOrDirection(_ raw: String) -> Bool {
        let request = parse(raw)
        guard !request.topics.isDisjoint(with: .calendarOnly) else { return false }
        let words = Set(AskAILexicon.fold(raw).split(separator: " ").map(String.init))
        let history: Set<String> = ["why", "was", "were", "did", "history", "story", "revealed", "changed", "change", "originally",
                                    "before", "jerusalem", "compass", "who", "meaning", "virtue", "virtues", "reward"]
        guard words.isDisjoint(with: history), words.isDisjoint(with: AskAILexicon.prayerFiqhWords) else { return false }
        if request.topics.contains(.events) { return true }
        if request.topics.contains(.hijri) {
            return !words.isDisjoint(with: ["date", "today", "todays", "now", "tonight", "tomorrow", "month", "year"])
        }
        return !words.isDisjoint(with: ["direction", "way", "where", "degrees", "degree", "bearing", "face", "facing", "angle", "which"])
    }

    private static let dateDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)

    /// The place the words name, or nil.
    static func place(in text: String) -> String? { places(in: text).last }

    /// Every place the words name, in the order written; the last is the one a single-place
    /// question means ("in Ramadan in Istanbul"). Two or three come of a comparison ("Fajr in Makkah
    /// and Cairo"): only names the tagger knows as places count beyond the first, and a name that
    /// is part of the last one's phrase is that place said more fully ("Irvine, CA"), not another.
    static func places(in text: String) -> [String] {
        let candidates = phraseCandidates(in: text)
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var tagged: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType,
                             options: [.omitPunctuation, .omitWhitespace, .joinNames]) { tag, range in
            if tag == .placeName { tagged.append(String(text[range])) }
            return true
        }
        tagged = tagged.filter { !isNotAPlace($0) }
        // "Irvine, CA": the phrase that holds the tagged name says more than the name alone.
        let last = tagged.last.map { name in candidates.last(where: { $0.localizedCaseInsensitiveContains(name) }) ?? name } ?? candidates.last
        guard let last else { return [] }
        var out: [String] = []
        func add(_ other: String) {
            guard !isNotAPlace(other), !last.localizedCaseInsensitiveContains(other), !other.localizedCaseInsensitiveContains(last),
                  !out.contains(where: { $0.caseInsensitiveCompare(other) == .orderedSame }) else { return }
            out.append(other)
        }
        for other in tagged.dropLast() { add(other) }
        // "in Makkah and Cairo", "in London, Paris and Istanbul": the names joined to a place phrase,
        // which the tagger does not always know (it left Cairo and Istanbul untagged, 2026-11-25).
        // A joined name is written with a capital: "in London and how long until Asr" joins nothing.
        for joined in joinedNames(in: text) { add(joined) }
        func position(_ place: String) -> Int {
            text.range(of: place, options: .caseInsensitive).map { text.distance(from: text.startIndex, to: $0.lowerBound) } ?? Int.max
        }
        return (out + [last]).sorted { position($0) < position($1) }
    }

    /// The capitalised names on either side of an "and", "or", "vs" or a comma, where one side is a
    /// place phrase ("in X"): every name of the run, in the order written.
    private static func joinedNames(in text: String) -> [String] {
        let tokens = text.split(whereSeparator: \.isWhitespace).map(String.init)
        var out: [String] = []
        for (index, token) in tokens.enumerated() where prepositions.contains(bare(token)) {
            var names: [String] = []
            var current: [String] = []
            var sawJoin = false
            func close() {
                if !current.isEmpty { names.append(current.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:!?"))) }
                current = []
            }
            for word in tokens.dropFirst(index + 1) {
                let plain = bare(word)
                if joiners.contains(plain) {
                    close()
                    sawJoin = true
                    continue
                }
                guard word.first?.isUppercase == true, !stopWords.contains(plain), !prepositions.contains(plain) else { break }
                current.append(word)
                if word.hasSuffix(",") {
                    close()
                    sawJoin = true
                } else if word.last.map({ ".?!;:".contains($0) }) == true {
                    break
                }
            }
            close()
            if sawJoin, names.count >= 2 { out += names.filter { !$0.isEmpty } }
        }
        return out
    }

    private static let joiners: Set<String> = ["and", "or", "vs", "versus", "&"]

    /// "in <words>", "at <words>", "for <words>", "of <words>", each cut at the next joining word,
    /// with the words that are never places dropped ("in Ramadan", "for Fajr", "in the morning").
    private static func phraseCandidates(in text: String) -> [String] {
        let tokens = text.split(whereSeparator: \.isWhitespace).map(String.init)
        var out: [String] = []
        for (index, token) in tokens.enumerated() where prepositions.contains(bare(token)) {
            var kept: [String] = []
            for word in tokens.dropFirst(index + 1) {
                let plain = bare(word)
                // Each "in" starts its own phrase: "in Ramadan in Istanbul" is two.
                if plain.isEmpty || stopWords.contains(plain) || prepositions.contains(plain) { break }
                guard word.first?.isLetter == true else { break }
                kept.append(word)
                if word.last.map({ ".?!;:".contains($0) }) == true { break }
            }
            let candidate = kept.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:!?"))
            guard !candidate.isEmpty, kept.count <= 5, !isNotAPlace(candidate) else { continue }
            out.append(candidate)
        }
        return out
    }

    private static func bare(_ word: String) -> String {
        word.lowercased().trimmingCharacters(in: .punctuationCharacters)
    }

    private static let prepositions: Set<String> = ["in", "at", "for", "of", "near"]

    /// Words that end a place phrase: "London on Friday", "Cairo this week".
    private static let stopWords: Set<String> = [
        "on", "this", "next", "last", "and", "or", "please", "today", "tonight", "tomorrow", "yesterday",
        "now", "time", "times", "prayer", "prayers", "salah", "when", "what", "is", "are", "will", "be", "during",
    ]

    /// What follows "in" or "for" but is never a place.
    static func isNotAPlace(_ candidate: String) -> Bool {
        var folded = candidate.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // "the UK" is a place, "the morning" is not: the article is weighed on what follows it.
        if folded.hasPrefix("the ") { folded = String(folded.dropFirst(4)) }
        if folded.count < 2 || folded.first?.isNumber == true { return true }
        let words = folded.split(separator: " ").map(String.init)
        if !Set(words).isDisjoint(with: AskAILexicon.prayerNames) { return true }
        // Filler alone ("When is the last third of the night tonight?" left "the" once the day was
        // taken out, and the map found a village for it), or a word that is never part of a place.
        if words.allSatisfy(AskAILexicon.stopWords.contains) { return true }
        if !Set(words).isDisjoint(with: neverInAPlace) { return true }
        if let first = words.first, ["a", "an", "my", "your", "our", "this", "that", "general", "order", "congregation",
                                     "jamaah", "jamaat", "advance", "case", "sha", "shaa"].contains(first) {
            return true
        }
        return notPlaces.contains(folded)
    }

    private static let neverInAPlace: Set<String> = [
        "qibla", "qiblah", "kaaba", "here", "hijri", "calendar", "date", "direction", "method", "calculation", "night",
        "day", "days", "week", "month", "year", "eid", "ramadan", "ramadhan", "arafah", "ashura", "tahajjud", "suhoor", "iftar",
    ]

    private static let notPlaces: Set<String> = [
        "ramadan", "shaban", "muharram", "dhul hijjah", "dhul-hijjah", "hajj", "umrah", "morning", "evening", "afternoon",
        "night", "masjid", "mosque", "here", "home", "travel", "traveling", "travelling", "winter", "summer", "spring",
        "autumn", "fall", "minutes", "hours", "days", "weeks", "quran", "sunnah", "hadith", "islam", "jumuah", "jummah",
    ]

    /// The place on the map, in English, with its time zone and country (Apple Maps; needs a connection).
    /// The reader's saved cities answer first and offline.
    @MainActor
    static func locate(_ name: String) async -> Place? {
        let folded = name.lowercased()
        let saved = Settings.shared.favoriteLocations.first { location in
            let short = location.city.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces).lowercased() } ?? ""
            return !short.isEmpty && (folded == short || folded.hasPrefix(short + ","))
        }
        let english = Locale(identifier: "en_US")
        let geocoder = CLGeocoder()
        let placemarks: [CLPlacemark] = await withTaskGroup(of: [CLPlacemark]?.self) { group in
            group.addTask {
                // Apple Maps over the whole world first: it ranks by prominence, where the geocoder
                // ranks by nearness, and "cairo" asked in New York came back as Cairo, NY. The place it
                // finds is then named in English, with its zone and country, by a reverse lookup.
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = name
                request.resultTypes = .address
                request.region = MKCoordinateRegion(MKMapRect.world)
                if let found = try? await MKLocalSearch(request: request).start().mapItems.first,
                   let named = try? await geocoder.reverseGeocodeLocation(
                       CLLocation(latitude: found.placemark.coordinate.latitude,
                                  longitude: found.placemark.coordinate.longitude),
                       preferredLocale: english),
                   !named.isEmpty {
                    return named
                }
                return (try? await geocoder.geocodeAddressString(name, in: nil, preferredLocale: english)) ?? []
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            geocoder.cancelGeocode()
            return first ?? []
        }
        if let mark = placemarks.first, let coordinate = mark.location?.coordinate {
            let parts = [mark.locality ?? mark.name, mark.locality == nil ? nil : mark.administrativeArea, mark.country]
                .compactMap { $0 }.filter { !$0.isEmpty }
            var seen = Set<String>()
            let english = parts.filter { seen.insert($0).inserted }.joined(separator: ", ")
            let label = english.isEmpty ? name : english
            return Place(location: saved ?? Location(city: label, latitude: coordinate.latitude, longitude: coordinate.longitude),
                         name: label, timeZone: mark.timeZone ?? .current, countryCode: mark.isoCountryCode, isHere: false)
        }
        if let saved {
            return Place(location: saved, name: saved.city, timeZone: .current, countryCode: nil, isHere: false)
        }
        return nil
    }
}
#endif

#endif
