import SwiftUI
import Foundation

// The Islam tab's search filters (2026-11-24, Abu: "Support similar searching and filtering search stuff
// in Islam as there is in Quran", and "Searching up Arabic or for verses and Hadiths in Islam shows
// nothing"). The Quran tab's grammar, for the articles: a row of buttons over the results (Search In,
// Topics, Match, Words, Without, Best Match, Show) and a sheet with every filter and a line on what it
// does. The model and the matcher are here; the screens that search (the Islam tab's root, Pillars &
// Beliefs, the How-To Guides, Proving Islam) own a `IslamSearchFilters` and hand it to the search.
//
// A query that names an ayah ("2:255", "Quran 42:11") or a hadith ("bukhari 1", "Sahih Muslim 867",
// "مسلم ٨٦٧") is a REFERENCE: the results are the passages that cite exactly it, and a row opens it in
// its tab. Before, "bukhari 1" listed every passage that held "bukhari" and any number with a 1 in it.

// MARK: - The filters

extension IslamArticleHome {
    /// The library's name on a search button: translated on the Islam tab's root (the resource tiles'
    /// own words), English beside the English articles.
    func searchTitle(translated: Bool) -> String {
        guard translated else { return AppLanguage.article(title) }
        switch self {
        case .pillars: return String(localized: "Pillars & Beliefs")
        case .guides: return String(localized: "How-To Guides")
        case .proving: return String(localized: "Proving Islam")
        case .stories: return String(localized: "Stories of the Prophets")
        case .companions: return String(localized: "Sahabah, Ahlul Bayt & Salaf")
        case .religions: return String(localized: "Refuting Religions")
        case .preservation: return String(localized: "Preservation of the Quran")
        case .hadithScience: return String(localized: "Science of Hadith")
        case .domino: return String(localized: "The Domino Process")
        }
    }
}

struct IslamSearchFilters: Equatable {
    /// Where a word must sit, the Quran search's Match without Ends With and Exact (the articles are
    /// folded prose: no tashkeel or capitals left to be exact about).
    enum Match: String, CaseIterable, Identifiable {
        case contains, wholeWord, startsWith

        var id: String { rawValue }

        var title: String {
            switch self {
            case .contains: return String(localized: "Contains")
            case .wholeWord: return String(localized: "Whole Word")
            case .startsWith: return String(localized: "Starts With")
            }
        }

        var detail: String {
            switch self {
            case .contains: return String(localized: "Anywhere, even inside a longer word: pray also finds prayer")
            case .wholeWord: return String(localized: "Whole words only: pray finds pray, not prayer")
            case .startsWith: return String(localized: "A word begins with it: pray finds prayer, not spray")
            }
        }

        /// The highlight's rule, so the coloured letters follow the button.
        var wordRule: SearchWordRule {
            switch self {
            case .contains: return .anywhere
            case .wholeWord: return .wholeWord
            case .startsWith: return .startsWith
            }
        }
    }

    enum Combine: String, CaseIterable, Identifiable {
        case allWords, anyWord, phrase

        var id: String { rawValue }

        var title: String {
            switch self {
            case .allWords: return String(localized: "All Words")
            case .anyWord: return String(localized: "Any Word")
            case .phrase: return String(localized: "As a Phrase")
            }
        }

        var detail: String {
            switch self {
            case .allWords: return String(localized: "Every word, anywhere in the passage, in any order")
            case .anyWord: return String(localized: "At least one of the words")
            case .phrase: return String(localized: "The words together, in the order typed")
            }
        }
    }

    enum Sort: String, CaseIterable, Identifiable {
        case index, relevance

        var id: String { rawValue }

        var title: String {
            switch self {
            case .index: return String(localized: "Index Order")
            case .relevance: return String(localized: "Best Match")
            }
        }

        var detail: String {
            switch self {
            case .index: return String(localized: "The order the articles are listed in, up to three passages from each")
            case .relevance: return String(localized: "The passages that use the words most come first")
            }
        }
    }

    /// The kinds of result a search lists.
    enum Kind: String, CaseIterable, Identifiable {
        case scripture, resources, articles, passages, askAI

        var id: String { rawValue }

        var title: String {
            switch self {
            case .scripture: return String(localized: "Verses & Hadith")
            case .resources: return String(localized: "Resources")
            case .articles: return String(localized: "Articles")
            case .passages: return String(localized: "Passages")
            case .askAI: return String(localized: "Ask AI")
            }
        }

        var systemImage: String {
            switch self {
            case .scripture: return "text.book.closed"
            case .resources: return "square.grid.2x2"
            case .articles: return "doc.text"
            case .passages: return "text.alignleft"
            case .askAI: return "sparkles"
            }
        }

        var detail: String {
            switch self {
            case .scripture: return String(localized: "The ayah or hadith a reference names, to open in its tab")
            case .resources: return String(localized: "The Islam tab's own resources")
            case .articles: return String(localized: "Article titles and the names they are known by")
            case .passages: return String(localized: "The sections of the articles that carry the words, Arabic included")
            case .askAI: return String(localized: "The Ask AI row")
            }
        }
    }

    // Session filters: set for this search, never remembered.
    /// The libraries searched; empty is every one the screen searches.
    var homes: Set<IslamArticleHome> = []
    /// Index sections ("pillars/THE 5 PILLARS OF ISLAM", an `IslamArticleGroup.id`); empty is all.
    var groups: Set<String> = []
    var match: Match = .contains
    var combine: Combine = .allWords
    /// Words no result may carry, typed in the sheet.
    var excluded: String = ""

    // Preferences: remembered between searches, as the Quran tab remembers its own.
    var sort: Sort = .index
    var hiddenKinds: Set<Kind> = []

    var excludedWords: [String] {
        excluded.split(whereSeparator: { $0.isWhitespace || $0 == "," }).map(String.init).filter { !$0.isEmpty }
    }

    func shows(_ kind: Kind) -> Bool { !hiddenKinds.contains(kind) }

    var hasSessionFilters: Bool {
        !homes.isEmpty || !groups.isEmpty || match != .contains || combine != .allWords || !excludedWords.isEmpty
    }

    /// The count on the All Filters button: every filter set away from its default.
    var activeCount: Int {
        (homes.isEmpty ? 0 : 1) + (groups.isEmpty ? 0 : 1) + (match == .contains ? 0 : 1) + (combine == .allWords ? 0 : 1)
            + (excludedWords.isEmpty ? 0 : 1) + (sort == .index ? 0 : 1) + (hiddenKinds.isEmpty ? 0 : 1)
    }

    mutating func resetSession() {
        homes = []
        groups = []
        match = .contains
        combine = .allWords
        excluded = ""
    }

    /// The libraries a screen that searches `available` should search now.
    func searchedHomes(_ available: Set<IslamArticleHome>) -> Set<IslamArticleHome> {
        let chosen = homes.intersection(available)
        return chosen.isEmpty ? available : chosen
    }

    /// Whether an article passes the Topics filter.
    func admits(_ entry: IslamArticleEntry) -> Bool {
        // By membership, not by the entry's own group: a library lists Pillars & Beliefs pages in its
        // groups too, and choosing that group must admit them (`IslamArticleCatalog.groupMembers`).
        groups.isEmpty || groups.contains { IslamArticleCatalog.groupMembers[$0]?.contains(entry.id) == true }
    }

    // MARK: Remembered

    private static let preferencesKey = "islamSearchFilterPreferences"

    /// A screen's filters as it opens: the remembered sort and shown kinds, nothing else.
    static func remembered() -> IslamSearchFilters {
        var filters = IslamSearchFilters()
        if let stored = UserDefaults.standard.dictionary(forKey: preferencesKey) {
            if let sort = (stored["sort"] as? String).flatMap(Sort.init(rawValue:)) { filters.sort = sort }
            if let hidden = stored["hidden"] as? [String] { filters.hiddenKinds = Set(hidden.compactMap(Kind.init(rawValue:))) }
        }
        #if DEBUG
        filters.applyDebugSeed()
        #endif
        return filters
    }

    func rememberPreferences() {
        UserDefaults.standard.set(["sort": sort.rawValue, "hidden": hiddenKinds.map(\.rawValue).sorted()], forKey: Self.preferencesKey)
    }

    #if DEBUG
    /// `-islamSearchFilters match=wholeWord,combine=phrase,homes=pillars+guides,sort=relevance,
    /// without=fire,hide=askAI+resources,groups=pillars/THE 5 PILLARS OF ISLAM` for screenshots.
    private mutating func applyDebugSeed() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-islamSearchFilters"), arguments.indices.contains(index + 1) else { return }
        for pair in arguments[index + 1].split(separator: ",") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let values = parts[1].split(separator: "+").map(String.init)
            switch parts[0] {
            case "match": match = Match(rawValue: parts[1]) ?? match
            case "combine": combine = Combine(rawValue: parts[1]) ?? combine
            case "sort": sort = Sort(rawValue: parts[1]) ?? sort
            case "without": excluded = values.joined(separator: " ")
            case "homes": homes = Set(values.compactMap(IslamArticleHome.init(rawValue:)))
            case "hide": hiddenKinds = Set(values.compactMap(Kind.init(rawValue:)))
            case "groups": groups = Set(values)
            default: break
            }
        }
    }
    #endif
}

// MARK: - The query

/// A typed query compiled against the filters once, then asked about many folded texts. Everything is
/// compared FOLDED (`IslamArticles.fold`): lowercased, punctuation to spaces, Arabic marks gone.
struct IslamSearchQuery: Sendable {
    let raw: String
    /// The folded words, in the order typed.
    let words: [String]
    let excluded: [String]
    let match: IslamSearchFilters.Match
    let combine: IslamSearchFilters.Combine
    /// The ayah or hadith the query names, when it names one. It replaces the word match for passages.
    let reference: IslamScriptureReference?

    init(_ raw: String, filters: IslamSearchFilters = IslamSearchFilters()) {
        self.raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        words = IslamArticles.fold(self.raw).split(separator: " ").map(String.init)
        excluded = filters.excludedWords.flatMap { IslamArticles.fold($0).split(separator: " ").map(String.init) }
        match = filters.match
        combine = filters.combine
        reference = IslamScriptureReference.parse(self.raw)
    }

    var isEmpty: Bool { words.isEmpty && reference == nil }

    /// How strongly the query matches the folded texts (a passage's English and its quotes' Arabic):
    /// the number of word occurrences, or nil when it does not match at all.
    func score(_ folded: String, _ also: String = "") -> Int? {
        guard !words.isEmpty else { return nil }
        for word in excluded where Self.count(word, in: folded, rule: match) > 0 || Self.count(word, in: also, rule: match) > 0 {
            return nil
        }
        switch combine {
        case .phrase:
            let count = Self.phraseCount(words, in: folded, rule: match) + Self.phraseCount(words, in: also, rule: match)
            return count > 0 ? count : nil
        case .allWords:
            var total = 0
            for word in words {
                let count = Self.count(word, in: folded, rule: match) + Self.count(word, in: also, rule: match)
                if count == 0 { return nil }
                total += count
            }
            return total
        case .anyWord:
            var total = 0
            for word in words {
                total += Self.count(word, in: folded, rule: match) + Self.count(word, in: also, rule: match)
            }
            return total > 0 ? total : nil
        }
    }

    /// True when the query matches the text at all (`score` without the counting cost mattering).
    func matches(_ folded: String, _ also: String = "") -> Bool { score(folded, also) != nil }

    // MARK: Word edges in folded text

    /// In folded text the only things between words are spaces (and the newline that joins two lanes).
    @inline(__always)
    private static func isSeparator(_ scalar: Unicode.Scalar) -> Bool { scalar == " " || scalar == "\n" }

    private static func startsWord(_ index: String.Index, in text: String) -> Bool {
        index == text.startIndex || isSeparator(text.unicodeScalars[text.unicodeScalars.index(before: index)])
    }

    private static func endsWord(_ index: String.Index, in text: String) -> Bool {
        index == text.endIndex || isSeparator(text.unicodeScalars[index])
    }

    /// A number is always matched whole: "1" must not find 1385, nor "25" find 2501.
    private static func isNumber(_ word: String) -> Bool {
        !word.isEmpty && word.utf8.allSatisfy { $0 >= 0x30 && $0 <= 0x39 }
    }

    private static func accepts(_ range: Range<String.Index>, in text: String, rule: IslamSearchFilters.Match, word: String) -> Bool {
        let rule: IslamSearchFilters.Match = isNumber(word) ? .wholeWord : rule
        switch rule {
        case .contains: return true
        case .startsWith: return startsWord(range.lowerBound, in: text)
        case .wholeWord: return startsWord(range.lowerBound, in: text) && endsWord(range.upperBound, in: text)
        }
    }

    /// Occurrences of one folded word in folded text, under the Match rule.
    static func count(_ word: String, in text: String, rule: IslamSearchFilters.Match) -> Int {
        guard !word.isEmpty, !text.isEmpty else { return 0 }
        var count = 0
        var start = text.startIndex
        while start < text.endIndex, let range = text.range(of: word, options: .literal, range: start..<text.endIndex) {
            if accepts(range, in: text, rule: rule, word: word) {
                count += 1
                start = range.upperBound
            } else {
                start = text.unicodeScalars.index(after: range.lowerBound)
            }
        }
        return count
    }

    /// The first place one folded word sits in folded text under the rule, for the snippet.
    static func firstRange(of word: String, in text: String, rule: IslamSearchFilters.Match) -> Range<String.Index>? {
        guard !word.isEmpty else { return nil }
        var start = text.startIndex
        while start < text.endIndex, let range = text.range(of: word, options: .literal, range: start..<text.endIndex) {
            if accepts(range, in: text, rule: rule, word: word) { return range }
            start = text.unicodeScalars.index(after: range.lowerBound)
        }
        return nil
    }

    /// The words in a row, one or more spaces apart (the fold leaves a run of spaces where punctuation
    /// was). The first word's start and the last word's end follow the rule; the words between are
    /// whole words.
    static func phraseRanges(_ words: [String], in text: String, rule: IslamSearchFilters.Match, limit: Int = .max) -> [Range<String.Index>] {
        guard let first = words.first, !text.isEmpty else { return [] }
        guard words.count > 1 else {
            var found: [Range<String.Index>] = []
            var start = text.startIndex
            while found.count < limit, start < text.endIndex,
                  let range = text.range(of: first, options: .literal, range: start..<text.endIndex) {
                if accepts(range, in: text, rule: rule, word: first) {
                    found.append(range)
                    start = range.upperBound
                } else {
                    start = text.unicodeScalars.index(after: range.lowerBound)
                }
            }
            return found
        }
        let scalars = text.unicodeScalars
        var found: [Range<String.Index>] = []
        var start = text.startIndex
        while found.count < limit, start < text.endIndex,
              let head = text.range(of: first, options: .literal, range: start..<text.endIndex) {
            defer { start = scalars.index(after: head.lowerBound) }
            // The first word may sit inside a longer one only at its START ("Contains" finds "llah the"
            // in "allah the"), and must end where its word ends, since another word follows it.
            let firstOK: Bool
            switch rule {
            case .contains: firstOK = true
            case .startsWith, .wholeWord: firstOK = startsWord(head.lowerBound, in: text)
            }
            guard firstOK, endsWord(head.upperBound, in: text) else { continue }
            var cursor = head.upperBound
            var ok = true
            for (offset, word) in words.dropFirst().enumerated() {
                // At least one space, then the word.
                guard cursor < text.endIndex, isSeparator(scalars[cursor]) else { ok = false; break }
                while cursor < text.endIndex, isSeparator(scalars[cursor]) { cursor = scalars.index(after: cursor) }
                guard text[cursor...].hasPrefix(word) else { ok = false; break }
                let end = scalars.index(cursor, offsetBy: word.unicodeScalars.count)
                let isLast = offset == words.count - 2
                let needsEdge = !isLast || rule == .wholeWord || isNumber(word)
                if needsEdge, !endsWord(end, in: text) { ok = false; break }
                cursor = end
            }
            if ok { found.append(head.lowerBound..<cursor) }
        }
        return found
    }

    static func phraseCount(_ words: [String], in text: String, rule: IslamSearchFilters.Match) -> Int {
        phraseRanges(words, in: text, rule: rule).count
    }

    /// Where the query first sits in folded text: the words together as typed when they are there
    /// ("al-Fiqh al-Akbar", not the first lone "fiqh"), else the first typed word found.
    func firstRange(in folded: String) -> Range<String.Index>? {
        if let phrase = Self.phraseRanges(words, in: folded, rule: match, limit: 1).first { return phrase }
        if combine == .phrase { return nil }
        for word in words {
            if let range = Self.firstRange(of: word, in: folded, rule: match) { return range }
        }
        return nil
    }
}

// MARK: - References

/// An ayah or a hadith a query names, and the passages of the articles that cite it.
enum IslamScriptureReference: Equatable, Sendable {
    case ayahs(surah: Int, first: Int, last: Int)
    case hadith(slug: String, number: Int, title: String)

    /// The keys a passage's citations are filed under (`citationIndex`).
    var keys: [String] {
        switch self {
        case let .ayahs(surah, first, last): return (first...last).map { "q:\(surah):\($0)" }
        case let .hadith(slug, number, _): return ["h:\(slug):\(number)"]
        }
    }

    /// What the row calls it: "Quran 2:255", "Sahih al-Bukhari 1".
    var title: String {
        switch self {
        case let .ayahs(surah, first, last):
            return first == last ? "Quran \(surah):\(first)" : "Quran \(surah):\(first)-\(last)"
        case let .hadith(_, _, title): return title
        }
    }

    #if os(iOS)
    /// The link that opens it in its tab.
    var link: AppLink? {
        switch self {
        case let .ayahs(surah, first, _): return AppLink(key: "quran", value: "\(surah):\(first)")
        case let .hadith(slug, number, _): return AppLink(key: "hadith", value: "\(slug):\(number)")
        }
    }
    #endif

    /// "2:255", "Quran 2:255", "Qur'an 52:35-36", "سورة ٢:٢٥٥".
    private static let quranRegex = try? NSRegularExpression(
        pattern: #"^\s*(?:(?:the\s+)?(?:quran|qur['’]?an|koran|q|surah|sura|القرآن|القران|سورة)\s*)?(\d{1,3})\s*:\s*(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?\s*$"#,
        options: .caseInsensitive)

    /// The reference a query is, or nil. A hadith reference goes through the Hadith tab's own reader of
    /// them (`HadithReferenceParser`: "bukhari 1", "Sahih Muslim 867", "صحيح البخاري ١"), so the two
    /// tabs read the same queries the same way.
    static func parse(_ raw: String) -> IslamScriptureReference? {
        // The Watch has neither the citation reader nor a tab to open one in.
        #if os(iOS)
        let text = raw.normalizingArabicIndicDigitsToWestern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.contains(where: \.isNumber), text.count <= 60 else { return nil }
        if let quranRegex,
           let match = quranRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            func number(_ group: Int) -> Int? {
                Range(match.range(at: group), in: text).flatMap { Int(text[$0]) }
            }
            guard let surah = number(1), let first = number(2),
                  ScriptureCitations.ayahCounts.indices.contains(surah - 1) else { return nil }
            let count = ScriptureCitations.ayahCounts[surah - 1]
            let last = number(3) ?? first
            guard (1...count).contains(first), (first...count).contains(last) else { return nil }
            return .ayahs(surah: surah, first: first, last: last)
        }
        #if HAS_HADITH
        if let reference = HadithReferenceParser.parse(text), reference.chapter == nil, !reference.introduction {
            return .hadith(slug: reference.book.slug, number: reference.hadith,
                           title: "\(reference.book.englishTitle) \(reference.hadith)\(reference.suffix ?? "")")
        }
        #endif
        #endif
        return nil
    }

    // MARK: The citation index

    /// Where each ayah and hadith is cited in the corpus: key -> (article id, section index, where in
    /// the section's text). Built once, off the main actor, the first time a reference is searched.
    struct Citation: Sendable {
        let article: String
        let section: Int
        let location: Int
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var built: [String: [Citation]]?

    static func citations(for keys: [String]) -> [Citation] {
        let index = citationIndex()
        var seen = Set<String>()
        var out: [Citation] = []
        for key in keys {
            for citation in index[key] ?? [] where seen.insert("\(citation.article)#\(citation.section)").inserted {
                out.append(citation)
            }
        }
        return out
    }

    private static func citationIndex() -> [String: [Citation]] {
        #if os(iOS)
        lock.lock()
        if let built { lock.unlock(); return built }
        lock.unlock()
        var index: [String: [Citation]] = [:]
        /// "52:35-36" (the end of a citation's words): the range's last ayah.
        let rangeEnd = try? NSRegularExpression(pattern: #"(\d{1,3})\s*[-–]\s*(\d{1,3})\s*$"#)
        for article in IslamArticles.all {
            for (sectionIndex, section) in article.sections.enumerated() {
                let ns = section.text as NSString
                for hit in ScriptureCitations.uncachedHits(in: section.text) {
                    let citation = Citation(article: article.id, section: sectionIndex, location: hit.range.location)
                    switch hit.link {
                    case let .ayah(surah, ayah):
                        var last = ayah
                        let words = ns.substring(with: hit.range)
                        if let rangeEnd,
                           let match = rangeEnd.firstMatch(in: words, range: NSRange(location: 0, length: (words as NSString).length)),
                           let end = Int((words as NSString).substring(with: match.range(at: 2))), end > ayah, end - ayah < 40 {
                            last = end
                        }
                        for number in ayah...last { index["q:\(surah):\(number)", default: []].append(citation) }
                    case let .hadith(slug, reference):
                        // "831", "8a": the number, without the variant letter ("muslim 8" finds 8a).
                        // An Introduction's numbering is its own and is left out.
                        guard !reference.hasPrefix("intro"), !reference.hasPrefix("id-") else { continue }
                        let digits = reference.prefix(while: { $0.isNumber })
                        guard let number = Int(digits) else { continue }
                        index["h:\(slug):\(number)", default: []].append(citation)
                    default:
                        continue
                    }
                }
            }
        }
        lock.lock(); built = index; lock.unlock()
        return index
        #else
        return [:]
        #endif
    }
}

#if os(iOS)
// MARK: - The filter bar

/// The row of filter buttons over the Islam search's results: the few most reached for (the libraries,
/// Topics, Best Match) plus any filter that is set; with More, every filter one tap away.
struct IslamSearchFilterBar: View {
    @Environment(\.appearance) private var appearance
    @AppStorage(SearchFilterBar.everyButtonKey) private var showsEveryButton = false
    @Binding var filters: IslamSearchFilters
    /// The libraries this screen searches: all three on the Islam tab's root, one on an index.
    let homes: [IslamArticleHome]
    /// The kinds of result this screen can list (the root has resources and the Ask AI row).
    let kinds: [IslamSearchFilters.Kind]
    /// True on the Islam tab's root, the one translated screen; the indexes read English.
    var translated = false
    /// One page's own search (an article, a tajweed page): only the filters that shape the words,
    /// Match, Words and Without, as the Quran reader's own bar has.
    var inPage = false
    let onOpenSheet: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                allFiltersChip

                if filters.hasSessionFilters {
                    chipButton(title: String(localized: "Reset"), systemImage: "xmark", isOn: false) {
                        filters.resetSession()
                    }
                }

                if inPage {
                    divider
                    matchMenu
                    combineMenu
                    withoutChip
                } else if showsEveryButton {
                    divider
                    matchMenu
                    combineMenu
                    withoutChip
                    divider
                    homeChips
                    topicsMenu
                    divider
                    sortMenu
                    divider
                    ForEach(kinds) { kind in
                        chipButton(title: kind.title, systemImage: kind.systemImage, isOn: filters.shows(kind)) {
                            toggle(kind)
                        }
                    }
                } else {
                    divider
                    homeChips
                    topicsMenu
                    divider
                    chipButton(title: String(localized: "Best Match"), systemImage: "arrow.up.arrow.down", isOn: filters.sort == .relevance) {
                        filters.sort = filters.sort == .relevance ? .index : .relevance
                    }
                    if filters.match != .contains { matchMenu }
                    if filters.combine != .allWords { combineMenu }
                    if !filters.excludedWords.isEmpty { withoutChip }
                }

                if !inPage {
                    divider
                    chipButton(title: showsEveryButton ? String(localized: "Fewer") : String(localized: "More"),
                               systemImage: showsEveryButton ? "chevron.backward" : "ellipsis", isOn: false) {
                        showsEveryButton.toggle()
                    }
                    .accessibilityHint(showsEveryButton ? String(localized: "Shows only the common filters") : String(localized: "Shows every filter as a button"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        // The keyboard first: a menu here updated over a live keyboard aborted (`endsEditingOnTouch`).
        .endsEditingOnTouch()
        .onChange(of: filters.sort) { _ in filters.rememberPreferences() }
        .onChange(of: filters.hiddenKinds) { _ in filters.rememberPreferences() }
    }

    private func toggle(_ kind: IslamSearchFilters.Kind) {
        if filters.hiddenKinds.contains(kind) {
            filters.hiddenKinds.remove(kind)
        } else if filters.hiddenKinds.intersection(kinds).count < kinds.count - 1 {
            // Never the last one: a search that shows nothing reads as broken.
            filters.hiddenKinds.insert(kind)
        }
    }

    /// One chip per library, on a screen that searches more than one.
    @ViewBuilder
    private var homeChips: some View {
        if homes.count > 1 {
            ForEach(homes, id: \.self) { home in
                chipButton(title: homeTitle(home), systemImage: home.systemImage, isOn: filters.homes.contains(home)) {
                    if filters.homes.contains(home) {
                        filters.homes.remove(home)
                    } else {
                        filters.homes.insert(home)
                    }
                    // A topic of a library no longer searched would hide everything.
                    let searched = filters.searchedHomes(Set(homes))
                    filters.groups = filters.groups.filter { id in searched.contains { id.hasPrefix("\($0.rawValue)/") } }
                }
            }
        }
    }

    private func homeTitle(_ home: IslamArticleHome) -> String {
        home.searchTitle(translated: translated)
    }

    /// The index sections of the libraries searched, a submenu per library when there are several.
    private var topicsMenu: some View {
        let searched = homes.filter { filters.searchedHomes(Set(homes)).contains($0) }
        return Menu {
            if !filters.groups.isEmpty {
                Button(String(localized: "Every Topic")) { filters.groups = [] }
            }
            if searched.count == 1, let home = searched.first {
                groupToggles(home)
            } else {
                ForEach(searched, id: \.self) { home in
                    let picked = IslamArticleCatalog.groups(for: home).filter { filters.groups.contains($0.id) }.count
                    Menu {
                        groupToggles(home)
                    } label: {
                        Label(picked > 0 ? "\(homeTitle(home)) (\(picked))" : homeTitle(home),
                              systemImage: picked > 0 ? "checkmark" : home.systemImage)
                    }
                }
            }
        } label: {
            chipLabel(title: topicsTitle, systemImage: "list.bullet.indent", isOn: !filters.groups.isEmpty, isMenu: true)
        }
        .keepingIslamMenuOpen()
    }

    private var topicsTitle: String {
        switch filters.groups.count {
        case 0: return String(localized: "Topics")
        case 1: return Self.groupName(filters.groups.first ?? "")
        default: return String(localized: "\(filters.groups.count) Topics")
        }
    }

    /// "pillars/THE 5 PILLARS OF ISLAM" -> "The 5 Pillars of Islam": the index heading in title case,
    /// its small words lowered except after a colon ("Salafiyyah: The Way of the Salaf").
    static func groupName(_ id: String) -> String {
        let title = id.split(separator: "/", maxSplits: 1).last.map(String.init) ?? id
        var words = title.capitalized.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        for index in words.indices.dropFirst() where ["Of", "The", "In", "As", "And", "Its", "To", "On"].contains(words[index]) {
            if !words[index - 1].hasSuffix(":") { words[index] = words[index].lowercased() }
        }
        return AppLanguage.article(words.joined(separator: " "))
    }

    private func groupToggles(_ home: IslamArticleHome) -> some View {
        ForEach(IslamArticleCatalog.groups(for: home)) { group in
            Toggle(Self.groupName(group.id), isOn: Binding(
                get: { filters.groups.contains(group.id) },
                set: { isOn in
                    if isOn { filters.groups.insert(group.id) } else { filters.groups.remove(group.id) }
                }
            ))
            // The root PaddedSwitchToggleStyle draws double-height menu rows on iOS 26.
            .toggleStyle(.automatic)
        }
    }

    private var withoutChip: some View {
        chipButton(title: filters.excludedWords.isEmpty ? String(localized: "Without") : String(localized: "Without: \(filters.excludedWords.joined(separator: ", "))"),
                   systemImage: "minus.circle", isOn: !filters.excludedWords.isEmpty, action: onOpenSheet)
    }

    private var matchMenu: some View {
        Menu {
            Picker("Match", selection: $filters.match) {
                ForEach(IslamSearchFilters.Match.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            chipLabel(title: filters.match == .contains ? String(localized: "Match") : filters.match.title,
                      systemImage: "character.cursor.ibeam", isOn: filters.match != .contains, isMenu: true)
        }
    }

    private var combineMenu: some View {
        Menu {
            Picker("Words", selection: $filters.combine) {
                ForEach(IslamSearchFilters.Combine.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            chipLabel(title: filters.combine == .allWords ? String(localized: "Words") : filters.combine.title,
                      systemImage: "text.word.spacing", isOn: filters.combine != .allWords, isMenu: true)
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Order", selection: $filters.sort) {
                ForEach(IslamSearchFilters.Sort.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            chipLabel(title: filters.sort.title, systemImage: "arrow.up.arrow.down", isOn: filters.sort != .index, isMenu: true)
        }
    }

    private var divider: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 1, height: 18)
    }

    private var allFiltersChip: some View {
        Button {
            Settings.shared.hapticFeedback()
            onOpenSheet()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "slider.horizontal.3")
                if filters.activeCount > 0 {
                    Text("\(filters.activeCount)")
                        .monospacedDigit()
                }
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(filters.activeCount > 0 ? Color.white : appearance.accent)
            .background(filters.activeCount > 0 ? Capsule().fill(appearance.accent) : nil)
            .conditionalGlassEffect(useColor: filters.activeCount > 0 ? nil : 0.25, themeTint: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("All search filters")
    }

    private func chipButton(title: String, systemImage: String?, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            chipLabel(title: title, systemImage: systemImage, isOn: isOn, isMenu: false)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func chipLabel(title: String, systemImage: String?, isOn: Bool, isMenu: Bool) -> some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .lineLimit(1)
            if isMenu {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .opacity(0.7)
            }
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundStyle(isOn ? Color.white : appearance.accent)
        .background(isOn ? Capsule().fill(appearance.accent) : nil)
        .conditionalGlassEffect(useColor: isOn ? nil : 0.25, themeTint: false)
        .contentShape(Capsule())
    }
}

private extension View {
    /// A multi-select menu stays open between taps where the system allows it (iOS 16.4).
    @ViewBuilder
    func keepingIslamMenuOpen() -> some View {
        if #available(iOS 16.4, *) {
            menuActionDismissBehavior(.disabled)
        } else {
            self
        }
    }
}

// MARK: - The filter sheet

/// Every filter on one page, each with a line saying what it does.
struct IslamSearchFilterSheet: View {
    @Environment(\.appearance) private var appearance
    @Binding var filters: IslamSearchFilters
    let homes: [IslamArticleHome]
    let kinds: [IslamSearchFilters.Kind]
    var translated = false
    var inPage = false

    var body: some View {
        SheetNavigationContainer {
            List {
                Group {
                    if !inPage {
                        showSection
                        orderSection
                    }
                    matchSection
                    combineSection
                    withoutSection
                    if !inPage {
                        if homes.count > 1 { homesSection }
                        topicsSections
                    }
                    resetSection
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .tint(appearance.accent)
        .onChange(of: filters.sort) { _ in filters.rememberPreferences() }
        .onChange(of: filters.hiddenKinds) { _ in filters.rememberPreferences() }
    }

    private func header(_ text: String) -> some View {
        Text(text).foregroundStyle(appearance.accent)
    }

    private func optionRow(title: String, detail: String?, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)
                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? appearance.accent : Color.secondary.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var showSection: some View {
        Section {
            ForEach(kinds) { kind in
                optionRow(title: kind.title, detail: kind.detail, isOn: filters.shows(kind)) {
                    if filters.hiddenKinds.contains(kind) {
                        filters.hiddenKinds.remove(kind)
                    } else if filters.hiddenKinds.intersection(kinds).count < kinds.count - 1 {
                        filters.hiddenKinds.insert(kind)
                    }
                }
            }
        } header: {
            header(String(localized: "SHOW"))
        } footer: {
            Text("Which kinds of result a search lists. Remembered between searches.")
        }
    }

    private var orderSection: some View {
        Section {
            ForEach(IslamSearchFilters.Sort.allCases) { sort in
                optionRow(title: sort.title, detail: sort.detail, isOn: filters.sort == sort) {
                    filters.sort = sort
                }
            }
        } header: {
            header(String(localized: "PASSAGE ORDER"))
        } footer: {
            Text("Remembered between searches.")
        }
    }

    private var matchSection: some View {
        Section {
            ForEach(IslamSearchFilters.Match.allCases) { match in
                optionRow(title: match.title, detail: match.detail, isOn: filters.match == match) {
                    filters.match = match
                }
            }
        } header: {
            header(String(localized: "MATCH"))
        } footer: {
            Text("Arabic is matched without its harakat, so توحيد finds تَوحِيد.")
        }
    }

    private var combineSection: some View {
        Section {
            ForEach(IslamSearchFilters.Combine.allCases) { combine in
                optionRow(title: combine.title, detail: combine.detail, isOn: filters.combine == combine) {
                    filters.combine = combine
                }
            }
        } header: {
            header(String(localized: "SEVERAL WORDS"))
        }
    }

    private var withoutSection: some View {
        Section {
            TextField("Words to leave out", text: $filters.excluded)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
        } header: {
            header(String(localized: "WITHOUT"))
        } footer: {
            Text("No result carries any of these words. Separate several with spaces.")
        }
    }

    private var homesSection: some View {
        Section {
            ForEach(homes, id: \.self) { home in
                optionRow(title: home.searchTitle(translated: translated),
                          detail: nil, isOn: filters.homes.contains(home)) {
                    if filters.homes.contains(home) { filters.homes.remove(home) } else { filters.homes.insert(home) }
                }
            }
        } header: {
            header(String(localized: "SEARCH IN"))
        } footer: {
            Text("None chosen searches every one.")
        }
    }

    @ViewBuilder
    private var topicsSections: some View {
        ForEach(homes.filter { filters.searchedHomes(Set(homes)).contains($0) }, id: \.self) { home in
            Section {
                ForEach(IslamArticleCatalog.groups(for: home)) { group in
                    optionRow(title: IslamSearchFilterBar.groupName(group.id),
                              detail: group.entries.count == 1 ? AppLanguage.article("1 article") : AppLanguage.article("\(group.entries.count) articles"),
                              isOn: filters.groups.contains(group.id)) {
                        if filters.groups.contains(group.id) { filters.groups.remove(group.id) } else { filters.groups.insert(group.id) }
                    }
                }
            } header: {
                header(homes.count > 1 ? String(localized: "TOPICS: \(home.searchTitle(translated: translated).uppercased())")
                                       : String(localized: "TOPICS"))
            } footer: {
                Text("Only the articles under these headings. None chosen searches them all.")
            }
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                Settings.shared.hapticFeedback()
                filters.resetSession()
            } label: {
                Text("Reset Filters")
            }
            .disabled(!filters.hasSessionFilters)
        }
    }
}

// MARK: - Mounting

/// The filter row over a searching Islam screen's results and the sheet behind its All Filters
/// button, the way the Quran tab mounts its own: the row rides the top edge while a query is typed.
struct IslamSearchFilterChrome: ViewModifier {
    @Binding var filters: IslamSearchFilters
    let isSearching: Bool
    let homes: [IslamArticleHome]
    let kinds: [IslamSearchFilters.Kind]
    var translated = false
    var inPage = false
    @State private var showsSheet = false

    func body(content: Content) -> some View {
        content
            // `adaptiveSafeArea`: the system's scroll-edge treatment under the row on iOS 26, so results
            // dissolve as they pass beneath the buttons instead of showing through them.
            .adaptiveSafeArea(edge: .top, spacing: 0) {
                if isSearching {
                    IslamSearchFilterBar(filters: $filters, homes: homes, kinds: kinds, translated: translated, inPage: inPage) {
                        showsSheet = true
                    }
                    // Before iOS 26 nothing dissolves the rows passing under the buttons, so the row
                    // carries the bar material the navigation bar above it has.
                    .background {
                        if #unavailable(iOS 26.0) {
                            Rectangle().fill(.bar).ignoresSafeArea(edges: .top)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showsSheet) {
                IslamSearchFilterSheet(filters: $filters, homes: homes, kinds: kinds, translated: translated, inPage: inPage)
                    .smallMediumSheetPresentation()
            }
    }
}

extension View {
    func islamSearchFilterChrome(_ filters: Binding<IslamSearchFilters>, isSearching: Bool, homes: [IslamArticleHome],
                                 kinds: [IslamSearchFilters.Kind], translated: Bool = false, inPage: Bool = false) -> some View {
        modifier(IslamSearchFilterChrome(filters: filters, isSearching: isSearching, homes: homes, kinds: kinds,
                                         translated: translated, inPage: inPage))
    }
}

// MARK: - The reference row

/// The ayah or hadith a query names, as one row that opens it in its tab ("Quran 2:255 · Open in Quran").
struct IslamScriptureReferenceSection: View {
    @Environment(\.appearance) private var appearance
    let reference: IslamScriptureReference
    var translated = false

    var body: some View {
        if let link = reference.link, link.opensInThisApp {
            Section(header: SectionIconHeader(translated ? String(localized: "VERSES & HADITH") : AppLanguage.article("VERSES & HADITH"),
                                              icon: link.openSystemImage)) {
                Button {
                    Settings.shared.hapticFeedback()
                    AppLinkRouter.open(link)
                } label: {
                    HStack(spacing: 12) {
                        AccentIconChip(systemImage: link.openSystemImage)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: reference.title)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(verbatim: subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 8)
                        Label(link.openTitle, systemImage: "arrow.up.forward")
                            .labelStyle(.iconOnly)
                            .font(.caption.weight(.bold))
                            .foregroundColor(appearance.accent)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(link.openTitle)
            }
        }
    }

    private var subtitle: String {
        switch reference {
        case let .ayahs(surah, _, _):
            #if HAS_QURAN
            if let name = QuranData.shared.surah(surah)?.nameTransliteration {
                return "\(name) · \(reference.link?.openTitle ?? "")"
            }
            #endif
            return reference.link?.openTitle ?? ""
        case .hadith:
            return reference.link?.openTitle ?? ""
        }
    }
}
#endif
