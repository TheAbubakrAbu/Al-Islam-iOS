import SwiftUI

// MARK: - The Quran search filters
//
// Everything the Quran tab's search can be told WITHOUT typing syntax (Abu, 2026-09-21: "make them not
// just available via text but also have a row of buttons at the top allowing me to select many").
//
// Two kinds of filter live here:
//
//  1. SHAPING filters compile into the operator grammar the scans read (`QuranBooleanQuery`): Whole
//     Word becomes `=word`, All Words joins with `&`, Without adds `!word`, Go To prepends `page ` /
//     `juz ` / ... That grammar is INTERNAL now (Abu, 2026-09-21: "get rid of the tiny shortcuts
//     through text like ^ = and make it only in the row button"): `compile` strips those symbols
//     from whatever was typed, so the buttons are the only way to ask for them.
//  2. SCOPING filters have no typed twin and travel beside the query as a `QuranSearchScope`:
//     search within chosen surahs or juz, Makkan / Madinan, translation-only or transliteration-only,
//     which result sections show, and mushaf order versus best match.
//
// This file is the MODEL and compiles wherever `QuranData` does (its scan takes a `QuranSearchScope`);
// the bar and the sheet are in QuranSearchFilters.swift, app only.

struct QuranSearchFilters: Equatable {
    /// The result sections, each of which can be switched off.
    enum Kind: String, CaseIterable, Identifiable, Codable {
        case surahs, jumps, topics, ai, ayahs
        var id: String { rawValue }

        var title: String {
            switch self {
            case .surahs: return "Surahs"
            case .jumps: return "Page & Juz"
            case .topics: return "Roots & Topics"
            case .ai: return "AI"
            case .ayahs: return "Ayahs"
            }
        }

        var systemImage: String {
            switch self {
            case .surahs: return "list.bullet"
            case .jumps: return "book.pages"
            case .topics: return "leaf"
            case .ai: return "sparkles"
            case .ayahs: return "text.quote"
            }
        }

        var detail: String {
            switch self {
            case .surahs: return "Surah names, numbers, and size filters"
            case .jumps: return "Page, juz, hizb, ruku and manzil jumps"
            case .topics: return "Arabic roots, dictionary forms, topics and passages"
            case .ai: return "Meaning matches and the Ask AI row"
            case .ayahs: return "Ayah text in Arabic, English and transliteration"
            }
        }
    }

    /// How each typed word has to sit in the ayah.
    enum Match: String, CaseIterable, Identifiable {
        case contains, wholeWord, startsWith, endsWith, exact
        var id: String { rawValue }

        var title: String {
            switch self {
            case .contains: return "Contains"
            case .wholeWord: return "Whole Word"
            case .startsWith: return "Starts With"
            case .endsWith: return "Ends With"
            case .exact: return "Exact"
            }
        }

        var detail: String {
            switch self {
            case .contains: return "Anywhere, even inside a longer word: رب also finds ربهم"
            case .wholeWord: return "Whole words only: رب finds the word رب, not ربهم"
            case .startsWith: return "A word, or the ayah, begins with it"
            case .endsWith: return "A word, or the ayah, ends with it"
            case .exact: return "Letter for letter: tashkeel in Arabic, capitals in English"
            }
        }
    }

    /// How several typed words combine.
    enum Combine: String, CaseIterable, Identifiable {
        case phrase, allWords, anyWord
        var id: String { rawValue }

        var title: String {
            switch self {
            case .phrase: return "As a Phrase"
            case .allWords: return "All Words"
            case .anyWord: return "Any Word"
            }
        }

        var detail: String {
            switch self {
            case .phrase: return "The words together, in the order typed"
            case .allWords: return "Every word, anywhere in the ayah, in any order"
            case .anyWord: return "At least one of the words"
            }
        }
    }

    /// A place to go: the typed number (or name) is read as this, and nothing else.
    enum GoTo: String, CaseIterable, Identifiable {
        case surah, page, juz, hizb, ruku, manzil
        var id: String { rawValue }

        var title: String {
            switch self {
            case .surah: return "Surah"
            case .page: return "Page"
            case .juz: return "Juz"
            case .hizb: return "Hizb"
            case .ruku: return "Ruku"
            case .manzil: return "Manzil"
            }
        }

        var placeholder: String {
            switch self {
            case .surah: return "Surah number or name (-1 is the last)"
            case .page: return "Page number (-1 is the last)"
            case .juz: return "Juz number or name (-1 is the last)"
            case .hizb: return "Hizb number, 1 to 60"
            case .ruku: return "Ruku number"
            case .manzil: return "Manzil number, 1 to 7"
            }
        }
    }

    enum Revelation: String, CaseIterable, Identifiable {
        case makkan, madinan
        var id: String { rawValue }
        var title: String { self == .makkan ? "Makki" : "Madani" }
    }

    /// Which text a Latin-script query is read against. (Arabic script always searches the Arabic.)
    enum Lane: String, CaseIterable, Identifiable {
        case all, translation, transliteration
        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Text"
            case .translation: return "Translation"
            case .transliteration: return "Transliteration"
            }
        }

        var detail: String {
            switch self {
            case .all: return "Arabic, both English translations and the transliteration"
            case .translation: return "English meaning only, so \u{201C}min\u{201D} stops matching the transliteration"
            case .transliteration: return "The Arabic in Latin letters only: \u{201C}rahman\u{201D}, \u{201C}alhamdu\u{201D}"
            }
        }
    }

    enum Sort: String, CaseIterable, Identifiable, Codable {
        case mushaf, relevance
        var id: String { rawValue }

        var title: String { self == .mushaf ? "Mushaf Order" : "Best Match" }

        var detail: String {
            switch self {
            case .mushaf: return "Every match from al-Fatihah to an-Nas, grouped by surah"
            case .relevance: return "Closest matches first: whole words, short ayahs and early matches rank higher, and spelling is forgiven"
            }
        }
    }

    // Session filters: they shape ONE search, and reset with the Reset chip.
    var match: Match = .contains
    var combine: Combine = .phrase
    /// Words no result may carry, separated by spaces or commas.
    var excluded: String = ""
    var goTo: GoTo?
    var revelation: Revelation?
    var surahs: Set<Int> = []
    var juzs: Set<Int> = []
    var lane: Lane = .all

    // Preferences: how results are laid out for EVERY search. Persisted (see `Stored`).
    var hiddenKinds: Set<Kind> = []
    var sort: Sort = .mushaf

    func shows(_ kind: Kind) -> Bool { !hiddenKinds.contains(kind) }

    var excludedWords: [String] {
        excluded
            .split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == "،" })
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "!&|=#^%$")) }
            .filter { !$0.isEmpty }
    }

    /// Any filter that belongs to the search in hand (the Reset chip's trigger, and what keeps the bar
    /// on screen when the field is empty and unfocused).
    var hasSessionFilters: Bool {
        match != .contains || combine != .phrase || !excludedWords.isEmpty || goTo != nil
            || revelation != nil || !surahs.isEmpty || !juzs.isEmpty || lane != .all
    }

    /// Filters that narrow the SURAH LIST on their own, so they show results with nothing typed.
    var narrowsSurahList: Bool {
        revelation != nil || !surahs.isEmpty || !juzs.isEmpty
    }

    var activeCount: Int {
        var count = 0
        if match != .contains { count += 1 }
        if combine != .phrase { count += 1 }
        if !excludedWords.isEmpty { count += 1 }
        if goTo != nil { count += 1 }
        if revelation != nil { count += 1 }
        if !surahs.isEmpty { count += 1 }
        if !juzs.isEmpty { count += 1 }
        if lane != .all { count += 1 }
        if !hiddenKinds.isEmpty { count += 1 }
        if sort != .mushaf { count += 1 }
        return count
    }

    mutating func resetSession() {
        let kept = (hiddenKinds, sort)
        self = QuranSearchFilters()
        (hiddenKinds, sort) = kept
    }

    // MARK: Persistence (preferences only)

    private struct Stored: Codable {
        var hidden: [Kind]
        var sort: Sort
    }

    static let storageKey = "quranSearchFilterPreferences"

    static func restored() -> QuranSearchFilters {
        var filters = QuranSearchFilters()
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let stored = try? JSONDecoder().decode(Stored.self, from: data) {
            filters.hiddenKinds = Set(stored.hidden)
            filters.sort = stored.sort
        }
        #if DEBUG
        filters.applyDebugSeed()
        #endif
        return filters
    }

    /// The filters of a search INSIDE one surah or page (the reader's search bar, page mode's find
    /// bar): only Match, Words, Without and Search In mean anything there, and nothing is persisted.
    static func readerSession() -> QuranSearchFilters {
        var filters = QuranSearchFilters()
        #if DEBUG
        filters.applyDebugSeed()
        filters = QuranSearchFilters(match: filters.match, combine: filters.combine,
                                     excluded: filters.excluded, lane: filters.lane)
        #endif
        return filters
    }

    #if DEBUG
    /// "-quranSearchFilters match=wholeWord,combine=allWords,revelation=makkan,juz=29+30,surah=2+18,
    /// lane=translation,sort=relevance,goTo=page,without=fire,hide=ai+topics": the buttons, pressed
    /// headlessly (pair with "-quranSearch <term>"). DEBUG builds only.
    private mutating func applyDebugSeed() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-quranSearchFilters"), arguments.indices.contains(index + 1) else { return }
        for pair in arguments[index + 1].split(separator: ",") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let values = parts[1].split(separator: "+").map(String.init)
            switch parts[0] {
            case "match": match = Match(rawValue: parts[1]) ?? match
            case "combine": combine = Combine(rawValue: parts[1]) ?? combine
            case "revelation": revelation = Revelation(rawValue: parts[1])
            case "juz": juzs = Set(values.compactMap(Int.init))
            case "surah": surahs = Set(values.compactMap(Int.init))
            case "lane": lane = Lane(rawValue: parts[1]) ?? lane
            case "sort": sort = Sort(rawValue: parts[1]) ?? sort
            case "goTo": goTo = GoTo(rawValue: parts[1])
            case "without": excluded = values.joined(separator: " ")
            case "hide": hiddenKinds = Set(values.compactMap(Kind.init(rawValue:)))
            default: break
            }
        }
    }
    #endif

    func persistPreferences() {
        let stored = Stored(hidden: Array(hiddenKinds).sorted { $0.rawValue < $1.rawValue }, sort: sort)
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    // MARK: Compiling

    /// One search, as each engine wants it.
    struct Compiled: Equatable {
        /// Surah list, references, page / juz / division jumps, count filters: the typed text with the
        /// Go To keyword in front, and no operator shaping (a surah NAME must not be split on `&`).
        let navigation: String
        /// The exact ayah scan: shaping filters folded into the operator grammar.
        let exact: String
        /// The ranked lane reads plain words (it refuses operator syntax), so it runs only when the
        /// shaping is something it already does by itself. Nil = the lane sits this search out.
        let ranked: String?
        /// The semantic lane: the words alone, never the operators.
        let semantic: String
        /// True when the filters changed what the exact scan was asked.
        let isShaped: Bool
    }

    static let operatorCharacters = Set("&|!#^%$=")

    /// What was typed with the operator symbols taken out: typing them does nothing any more.
    static func plainWords(_ text: String) -> String {
        // A space, not nothing: "mercy&patience" is two words.
        String(text.map { operatorCharacters.contains($0) ? " " : $0 })
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    func compile(_ rawText: String) -> Compiled {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let empty = Compiled(navigation: "", exact: "", ranked: nil, semantic: "", isShaped: false)
        guard !text.isEmpty else { return empty }

        if let goTo {
            // "page 5" typed with the Page chip on must not become "page page 5".
            let keyword = goTo.rawValue + " "
            let query = text.lowercased().hasPrefix(keyword) ? text : keyword + text
            return Compiled(navigation: query, exact: "", ranked: nil, semantic: "", isShaped: true)
        }

        let words = Self.plainWords(text)
        guard !words.isEmpty else { return empty }

        // References, counts and numbers ("2:255", ">100 ayahs", "==286 ayahs", "50") are not text to
        // shape, and the count grammar's own `==` has to reach the surah list as typed.
        let hasDigits = text.unicodeScalars.contains { CharacterSet.decimalDigits.contains($0) }
        if hasDigits {
            return Compiled(navigation: text, exact: words, ranked: words, semantic: words, isShaped: false)
        }

        let exact = shapedExactQuery(words)
        // The ranked lane matches word by word already (every word first, then the most of them),
        // which IS All Words and Any Word; a match mode or an exclusion is beyond it.
        let rankedEligible = match == .contains && excludedWords.isEmpty
        return Compiled(navigation: words, exact: exact, ranked: rankedEligible ? words : nil,
                        semantic: words, isShaped: exact != words)
    }

    /// The typed words with Match, Combine and Without folded in as operators: an OR of ANDs, the one
    /// shape `QuranBooleanQuery` reads.
    private func shapedExactQuery(_ words: String) -> String {
        let excludedTerms = excludedWords.map { "!" + $0 }
        guard match != .contains || combine != .phrase || !excludedTerms.isEmpty else { return words }

        let tokens = Self.tokens(of: words)
        let groups: [[String]]
        switch combine {
        case .phrase: groups = [[words]]
        case .allWords: groups = [tokens]
        case .anyWord: groups = tokens.map { [$0] }
        }

        let built = groups
            .map { $0.map(applyingMatch(to:)) + excludedTerms }
            .filter { !$0.isEmpty }
        guard !built.isEmpty else { return words }
        return built.map { $0.joined(separator: " & ") }.joined(separator: " | ")
    }

    /// Words, with a quoted run kept together as one term.
    private static func tokens(of text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var quoted = false
        for character in text {
            if character == "\"" || character == "\u{201C}" || character == "\u{201D}" {
                if quoted, !current.trimmingCharacters(in: .whitespaces).isEmpty {
                    // A quoted run is a phrase of whole words.
                    tokens.append("=" + current.trimmingCharacters(in: .whitespaces))
                    current = ""
                } else if !quoted, !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                quoted.toggle()
            } else if character.isWhitespace, !quoted {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else {
                current.append(character)
            }
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            tokens.append(current.trimmingCharacters(in: .whitespaces))
        }
        return tokens
    }

    /// The Match rule as the highlighter reads it, so the paint follows the rule that chose the ayahs.
    /// Exact is about tashkeel and capitals, not word edges, so it paints like Contains.
    var highlightWordRule: SearchWordRule {
        switch match {
        case .contains, .exact: return .anywhere
        case .wholeWord: return .wholeWord
        case .startsWith: return .startsWith
        case .endsWith: return .endsWith
        }
    }

    /// A quoted run arrives already marked `=phrase` (see `tokens`) and keeps that marking.
    private func applyingMatch(to term: String) -> String {
        if term.hasPrefix("=") { return term }
        switch match {
        case .contains: return term
        case .wholeWord: return "=" + term
        case .startsWith: return "^" + term
        case .endsWith: return term + "%"
        case .exact: return "#" + term
        }
    }

    // MARK: Scope

    /// The scoping filters, resolved against the juz table. Nil when nothing narrows the search.
    func scope(surahs quran: [Surah]) -> QuranSearchScope? {
        guard narrowsSurahList || lane != .all else { return nil }

        var allowed: Set<Int>? = nil
        if let revelation {
            allowed = Set(quran.filter { $0.type == revelation.rawValue }.map(\.id))
        }
        if !surahs.isEmpty {
            allowed = allowed.map { $0.intersection(surahs) } ?? surahs
        }
        let ranges: [ClosedRange<Int>] = QuranData.juzList
            .filter { juzs.contains($0.id) }
            .map { QuranSearchScope.key(surah: $0.startSurah, ayah: $0.startAyah)...QuranSearchScope.key(surah: $0.endSurah, ayah: $0.endAyah) }
        return QuranSearchScope(surahs: allowed, ranges: ranges, lane: lane)
    }
}

/// Where a search may look. Plain values, so it crosses into the detached scans.
struct QuranSearchScope: Equatable, Sendable {
    /// Nil = every surah.
    let surahs: Set<Int>?
    /// Ayah-key ranges (the chosen juz). Empty = no range limit.
    let ranges: [ClosedRange<Int>]
    let lane: QuranSearchFilters.Lane

    static func key(surah: Int, ayah: Int) -> Int { surah * 1000 + ayah }

    func contains(surah: Int, ayah: Int) -> Bool {
        if let surahs, !surahs.contains(surah) { return false }
        guard !ranges.isEmpty else { return true }
        let key = Self.key(surah: surah, ayah: ayah)
        return ranges.contains { $0.contains(key) }
    }

    /// Whether any ayah of the surah is in scope (the surah list's test).
    func contains(surah: Int, ayahCount: Int) -> Bool {
        if let surahs, !surahs.contains(surah) { return false }
        guard !ranges.isEmpty else { return true }
        let span = Self.key(surah: surah, ayah: 1)...Self.key(surah: surah, ayah: max(1, ayahCount))
        return ranges.contains { $0.overlaps(span) }
    }
}

// MARK: - The operator grammar

/// A compiled query, parsed: an OR of AND groups whose terms carry `=word` (whole word), `^word`
/// (starts with), `word%` (ends with), `#word` (letter for letter) and `!word` (without). Only
/// `QuranSearchFilters.compile` writes this grammar; the whole-Quran scan, the reader's in-surah
/// search and page mode's find bar all read it here, so the three can never disagree on a button.
struct QuranBooleanQuery {
    struct Term {
        enum MatchMode {
            case contains, startsWith, endsWith, exact
            /// Whole words, or a run of whole words: "رب" matches the word رب but not "ربهم".
            case wholeWord
        }

        let value: String
        let isNegated: Bool
        let matchMode: MatchMode
        let requiresTashkeelMatch: Bool
        let tashkeelPattern: String
        let requiresExactEnglishMatch: Bool
        let exactEnglishPhrase: String
    }

    /// Empty = a query made of operators alone, which matches nothing.
    let groups: [[Term]]

    /// Nil when the query carries no operator: the caller's plain substring path answers it.
    init?(_ rawQuery: String) {
        let normalized = rawQuery
            .replacingOccurrences(of: "&&", with: "&")
            .replacingOccurrences(of: "||", with: "|")
        guard normalized.contains(where: { QuranSearchFilters.operatorCharacters.contains($0) }) else { return nil }

        groups = normalized
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { part in
                part
                    .split(separator: "&", omittingEmptySubsequences: false)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    .compactMap(Self.term(from:))
            }
            .filter { !$0.isEmpty }
    }

    private static func term(from rawTerm: String) -> Term? {
        var term = rawTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return nil }

        func strip(prefix: Character) -> Bool {
            var found = false
            while term.first == prefix {
                found = true
                term.removeFirst()
                term = term.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return found
        }

        var isNegated = false
        while term.first == "!" {
            isNegated.toggle()
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let letterForLetter = strip(prefix: "#")
        let wholeWord = strip(prefix: "=")

        var startsWith = false
        if term.first == "^" {
            startsWith = true
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        var endsWith = false
        if term.last == "%" || term.last == "$" {
            endsWith = true
            term.removeLast()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !term.isEmpty else { return nil }
        let cleaned = Settings.shared.cleanSearch(term, whitespace: true)
        guard !cleaned.isEmpty else { return nil }

        let matchMode: Term.MatchMode
        if wholeWord {
            matchMode = .wholeWord
        } else if startsWith && endsWith {
            matchMode = .exact
        } else if startsWith {
            matchMode = .startsWith
        } else if endsWith {
            matchMode = .endsWith
        } else {
            matchMode = .contains
        }

        let isArabic = term.containsArabicLetters
        return Term(
            value: cleaned,
            isNegated: isNegated,
            matchMode: matchMode,
            requiresTashkeelMatch: letterForLetter && isArabic,
            tashkeelPattern: tashkeelBlob(term),
            requiresExactEnglishMatch: letterForLetter && !isArabic,
            exactEnglishPhrase: exactPhraseBlob(term)
        )
    }

    /// `haystack` is the ayah's cleaned search text and `tokens` its words. The two closures are paid
    /// for by letter-for-letter terms only: the tashkeel of the raw Arabic, and the lowercased English.
    func matches(haystack: String, tokens: [String], tashkeel: () -> String, exactEnglish: () -> String) -> Bool {
        groups.contains { andTerms in
            andTerms.allSatisfy { term in
                let found: Bool
                if term.requiresTashkeelMatch {
                    found = Self.termMatch(haystack: haystack, tokens: tokens, term: term.value, mode: term.matchMode)
                        && (term.tashkeelPattern.isEmpty || tashkeel().contains(term.tashkeelPattern))
                } else if term.requiresExactEnglishMatch {
                    let english = exactEnglish()
                    found = !term.exactEnglishPhrase.isEmpty && Self.termMatch(
                        haystack: english, tokens: Self.tokens(of: english),
                        term: term.exactEnglishPhrase, mode: term.matchMode)
                } else {
                    found = Self.termMatch(haystack: haystack, tokens: tokens, term: term.value, mode: term.matchMode)
                }
                return term.isNegated ? !found : found
            }
        }
    }

    private static func termMatch(haystack: String, tokens: [String], term: String, mode: Term.MatchMode) -> Bool {
        switch mode {
        case .contains:
            return haystack.contains(term)
        case .startsWith:
            return haystack.hasPrefix(term) || tokens.contains(where: { $0.hasPrefix(term) })
        case .endsWith:
            return haystack.hasSuffix(term) || tokens.contains(where: { $0.hasSuffix(term) })
        case .exact:
            return haystack == term || tokens.contains(term)
        case .wholeWord:
            return consecutiveTokenMatch(tokens, query: Self.tokens(of: term))
        }
    }

    /// True if `query`'s words appear as a consecutive run of whole words in `haystack`.
    private static func consecutiveTokenMatch(_ haystack: [String], query: [String]) -> Bool {
        guard !query.isEmpty, haystack.count >= query.count else { return false }
        for start in 0...(haystack.count - query.count)
        where query.indices.allSatisfy({ haystack[start + $0] == query[$0] }) {
            return true
        }
        return false
    }

    static func tokens(of cleanedText: String) -> [String] {
        cleanedText.split(separator: " ").map(String.init)
    }

    static func exactPhraseBlob(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func tashkeelBlob(_ text: String) -> String {
        String(text.unicodeScalars.filter { tashkeelCharacterSet.contains($0) })
    }

    private static let tashkeelCharacterSet: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "\u{0610}"..."\u{061A}")
        set.insert(charactersIn: "\u{064B}"..."\u{065F}")
        set.insert(charactersIn: "\u{0670}"..."\u{0670}")
        set.insert(charactersIn: "\u{06D6}"..."\u{06ED}")
        return set
    }()
}
