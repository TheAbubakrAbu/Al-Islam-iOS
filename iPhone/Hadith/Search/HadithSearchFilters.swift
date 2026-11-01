import SwiftUI

// MARK: - The hadith search filters
//
// The Hadith tab's twin of the Quran search's button row (QuranSearchFilterModel.swift): which
// collections to search, which gradings to keep, how several words combine, which result sections
// show, and whether hadiths list in collection order or by best match. None of it could be typed
// before, so there is no grammar to compile into: the filters travel beside the query.

struct HadithSearchFilters: Equatable {
    /// Where the button row is mounted. Inside one book there are no collections to choose (so no
    /// Books menu and no presets), and a chapter has no chapter titles to match; everything else
    /// (grading, words, order) is the same row on all three screens.
    enum Scope {
        case allBooks, oneBook, oneChapter

        var choosesBooks: Bool { self == .allBooks }
        /// The result sections that exist on the screen, in the row's order.
        var kinds: [Kind] { self == .oneChapter ? [.ai, .hadiths] : Kind.allCases }
    }

    enum Kind: String, CaseIterable, Identifiable, Codable {
        case chapters, ai, hadiths
        var id: String { rawValue }

        var title: String {
            switch self {
            case .chapters: return String(localized: "Chapters")
            case .ai: return String(localized: "AI")
            case .hadiths: return String(localized: "Hadiths")
            }
        }

        var systemImage: String {
            switch self {
            case .chapters: return "list.bullet.indent"
            case .ai: return "sparkles"
            case .hadiths: return "text.quote"
            }
        }

        var detail: String {
            switch self {
            case .chapters: return String(localized: "Chapter titles, in Arabic or English")
            case .ai: return String(localized: "Meaning matches and the Ask AI row")
            case .hadiths: return String(localized: "The narration, its narrator line and its Arabic")
            }
        }

        func detail(in scope: Scope) -> String {
            self == .ai && scope == .oneChapter ? String(localized: "Meaning matches from this chapter") : detail
        }
    }

    /// How each typed word has to sit in the hadith: the Quran search's Match button (Abu, 2026-10-31:
    /// "Hadith search should support some things that Quran search supports like exact match").
    /// The first four are word-edge rules the byte sweep applies to the prebuilt fold
    /// (`HadithMatchRule`); Exact is Whole Word plus a letter-for-letter check on the row's own text
    /// (`LetterMatch`), since the fold has already folded hamza forms, taa marbutah and capitals away.
    enum Match: String, CaseIterable, Identifiable {
        case contains, wholeWord, startsWith, endsWith, exact
        var id: String { rawValue }

        var title: String {
            switch self {
            case .contains: return String(localized: "Contains")
            case .wholeWord: return String(localized: "Whole Word")
            case .startsWith: return String(localized: "Starts With")
            case .endsWith: return String(localized: "Ends With")
            case .exact: return String(localized: "Exact")
            }
        }

        var detail: String {
            switch self {
            case .contains: return String(localized: "Anywhere, even inside a longer word: رب also finds ربهم")
            case .wholeWord: return String(localized: "Whole words only: رب finds the word رب, not ربهم")
            case .startsWith: return String(localized: "A word, or the hadith, begins with it")
            case .endsWith: return String(localized: "A word, or the hadith, ends with it")
            case .exact: return String(localized: "Letter for letter: hamza, taa marbutah and alif maqsurah forms in Arabic, capitals in English")
            }
        }

        /// The rule as the byte sweep reads it. Exact is whole words first; its letters are checked
        /// by the row test, on rows that already carry the words.
        var byteRule: HadithMatchRule {
            switch self {
            case .contains: return .contains
            case .wholeWord, .exact: return .wholeWord
            case .startsWith: return .startsWith
            case .endsWith: return .endsWith
            }
        }
    }

    enum Words: String, CaseIterable, Identifiable {
        case phrase, allWords, anyWord
        var id: String { rawValue }

        var title: String {
            switch self {
            case .phrase: return String(localized: "As a Phrase")
            case .allWords: return String(localized: "All Words")
            case .anyWord: return String(localized: "Any Word")
            }
        }

        var detail: String {
            switch self {
            case .phrase: return String(localized: "The words together, in the order typed")
            case .allWords: return String(localized: "Every word, anywhere in the hadith: \u{201C}anger control\u{201D} finds both apart")
            case .anyWord: return String(localized: "At least one of the words")
            }
        }
    }

    /// A grading class. A hadith several scholars graded belongs to every class any of them gave it.
    enum Grade: String, CaseIterable, Identifiable {
        case sahih, hasan, daif
        var id: String { rawValue }

        var title: String {
            switch self {
            case .sahih: return String(localized: "Sahih")
            case .hasan: return String(localized: "Hasan")
            case .daif: return String(localized: "Da'if")
            }
        }

        var detail: String {
            switch self {
            case .sahih: return String(localized: "Graded authentic. Everything in Sahih al-Bukhari and Sahih Muslim counts.")
            case .hasan: return String(localized: "Graded good")
            case .daif: return String(localized: "Graded weak, including munkar and fabricated reports")
            }
        }
    }

    enum Sort: String, CaseIterable, Identifiable, Codable {
        case collection, relevance
        var id: String { rawValue }

        var title: String { self == .collection ? String(localized: "Collection Order") : String(localized: "Best Match") }

        var detail: String {
            switch self {
            case .collection: return String(localized: "Every match, book by book, in the order of the shelf")
            case .relevance: return String(localized: "Closest matches first: chapter titles and whole words rank higher, and spelling is forgiven")
            }
        }

        func detail(in scope: Scope) -> String {
            switch (self, scope) {
            case (.collection, .oneBook): return String(localized: "Every match, in the order of the book")
            case (.collection, .oneChapter): return String(localized: "Every match, in the order of the chapter")
            case (.relevance, .oneChapter): return String(localized: "Closest matches first: whole words rank higher, and spelling is forgiven")
            default: return detail
            }
        }
    }

    // Session filters.
    /// Book slugs. Empty = every collection.
    var books: Set<String> = []
    /// Empty = any grading, and ungraded hadiths too.
    var grades: Set<Grade> = []
    var match: Match = .contains
    var words: Words = .phrase

    // Preferences, persisted.
    var hiddenKinds: Set<Kind> = []
    var sort: Sort = .collection

    func shows(_ kind: Kind) -> Bool { !hiddenKinds.contains(kind) }

    /// `shows` for one screen. The hidden kinds are one shared preference, so the all-books search can
    /// have hidden everything a chapter is able to show; a screen left with nothing shows all of it.
    func shows(_ kind: Kind, in scope: Scope) -> Bool {
        scope.kinds.allSatisfy(hiddenKinds.contains) ? scope.kinds.contains(kind) : !hiddenKinds.contains(kind)
    }

    /// One press of a Show button: at least one of the screen's sections always stays on.
    mutating func toggle(_ kind: Kind, in scope: Scope) {
        if scope.kinds.allSatisfy(hiddenKinds.contains) { hiddenKinds.subtract(scope.kinds) }
        if hiddenKinds.contains(kind) {
            hiddenKinds.remove(kind)
        } else if scope.kinds.filter({ !hiddenKinds.contains($0) }).count > 1 {
            hiddenKinds.insert(kind)
        }
    }
    func includes(_ book: HadithCatalogBook) -> Bool { books.isEmpty || books.contains(book.slug) }

    /// Any filter that belongs to the search in hand (the Reset chip's trigger). Kept, not reset, when
    /// the field empties: the row comes back carrying them the next time the field is focused.
    var hasSessionFilters: Bool { !books.isEmpty || !grades.isEmpty || match != .contains || words != .phrase }

    var activeCount: Int {
        [!books.isEmpty, !grades.isEmpty, match != .contains, words != .phrase, !hiddenKinds.isEmpty, sort != .collection]
            .filter { $0 }.count
    }

    /// `activeCount` for one screen: only the controls that screen carries are counted.
    func activeCount(in scope: Scope) -> Int {
        let hidesSomething = scope.kinds.contains { !shows($0, in: scope) }
        return [scope.choosesBooks && !books.isEmpty, !grades.isEmpty, match != .contains, words != .phrase,
                hidesSomething, sort != .collection]
            .filter { $0 }.count
    }

    mutating func resetSession() {
        books = []
        grades = []
        match = .contains
        words = .phrase
    }

    // MARK: Book presets

    static var sixBooks: Set<String> {
        Set(HadithCatalogBook.all.filter { $0.group == .six }.map(\.slug))
    }
    static let sahihayn: Set<String> = ["bukhari", "muslim"]

    // MARK: Grades

    /// The classes a row's stored verdicts put it in. Verdicts are sunnah.com's strings ("Sahih",
    /// "Hasan Sahih", "Da'if (Darussalam)"), read by the words in them and never adjudicated: where
    /// graders disagree, the hadith sits in both classes. The two Sahihs carry no verdicts by design.
    static func classes(slug: String, grades: [(name: String, grade: String)]) -> Set<Grade> {
        if sahihayn.contains(slug) { return [.sahih] }
        var found: Set<Grade> = []
        for entry in grades {
            let text = entry.grade.lowercased().filter { $0 != "'" && $0 != "\u{2019}" && $0 != "`" }
            if text.contains("sahih") || text.contains("saheeh") { found.insert(.sahih) }
            if text.contains("hasan") { found.insert(.hasan) }
            if text.contains("daif") || text.contains("daeef") || text.contains("weak") || text.contains("munkar")
                || text.contains("mawdu") || text.contains("fabricated") || text.contains("batil") {
                found.insert(.daif)
            }
        }
        return found
    }

    /// The row test the scans run (off main: it reads the row's text block). Nil with no grade filter.
    func gradeTest(for book: HadithCatalogBook, data: HadithBookData) -> (@Sendable (Int) -> Bool)? {
        guard !grades.isEmpty else { return nil }
        let wanted = grades
        let slug = book.slug
        if Self.sahihayn.contains(slug) {
            let passes = wanted.contains(.sahih)
            return { _ in passes }
        }
        let pack = data.pack
        return { row in
            !Self.classes(slug: slug, grades: pack.grades(row: row)).isDisjoint(with: wanted)
        }
    }

    // MARK: Words

    /// The query as the byte sweep reads it: one needle for a phrase, one per word otherwise, and
    /// the Match button's word-edge rule for every needle.
    func needles(for query: String) -> (queries: [HadithFold.Query], requireAll: Bool, rule: HadithMatchRule) {
        let whole = HadithFold.query(query)
        let rule = match.byteRule
        guard words != .phrase else { return ([whole], true, rule) }
        let parts = query.split(whereSeparator: { $0.isWhitespace }).map(String.init).filter { $0.count >= 2 }
        guard parts.count > 1 else { return ([whole], true, rule) }
        return (parts.map { HadithFold.query($0) }, words == .allWords, rule)
    }

    /// The row test the sweeps run on text matches (off main: it reads the row's text block): the
    /// grading, and under Exact the letter-for-letter check of the typed words against the row's own
    /// text. Nil when neither is asked for, so the plain sweep stays the plain sweep.
    func rowTest(for book: HadithCatalogBook, data: HadithBookData, query: String) -> (@Sendable (Int) -> Bool)? {
        let grade = gradeTest(for: book, data: data)
        guard match == .exact else { return grade }
        let letters = LetterMatch(query, words: words)
        let pack = data.pack
        return { row in
            guard grade?(row) ?? true else { return false }
            let strings = pack.strings(row: row)
            return letters.matches(arabic: strings.arabic, english: [strings.narrator, strings.text])
        }
    }

    /// The row test the RANKED lane runs on its hits (off main). That lane ranks stems, the other
    /// spelling and corrected words, so under a Match rule each hit is re-tested against the fold
    /// with the rule's word edges, then put through `rowTest`. Nil when nothing narrows the lane.
    func rankedRowTest(for book: HadithCatalogBook, data: HadithBookData, query: String) -> (@Sendable (Int) -> Bool)? {
        let rows = rowTest(for: book, data: data, query: query)
        let needles = needles(for: query)
        guard needles.rule != .contains else { return rows }
        return { row in
            data.matches(row: row, queries: needles.queries, requireAll: needles.requireAll, rule: needles.rule)
                && (rows?(row) ?? true)
        }
    }

    /// The Match rule as the highlighter reads it, so the paint follows the rule that chose the rows.
    /// Exact is whole words, letter for letter, so it paints like Whole Word.
    var highlightWordRule: SearchWordRule {
        switch match {
        case .contains: return .anywhere
        case .wholeWord, .exact: return .wholeWord
        case .startsWith: return .startsWith
        case .endsWith: return .endsWith
        }
    }

    // MARK: Exact

    /// The letter-for-letter half of Exact: the typed words against a row's own text, both with the
    /// marks removed (tashkeel, Quranic signs, punctuation) but every letter kept as written, so أ and
    /// ا, ة and ه, ى and ي, and a capital and its small letter all stay distinct, as whole words in a
    /// row. Runs only on rows the folded sweep already matched, so it is never the hot path.
    struct LetterMatch {
        /// Groups of consecutive words; the words rule decides whether all groups or one must land.
        private let groups: [[String]]
        private let requireAll: Bool
        let isArabic: Bool

        init(_ query: String, words: Words) {
            isArabic = HadithFold.isArabicScript(query)
            let tokens = Self.tokens(query)
            if words == .phrase || tokens.count < 2 {
                groups = tokens.isEmpty ? [] : [tokens]
                requireAll = true
            } else {
                groups = tokens.map { [$0] }
                requireAll = words == .allWords
            }
        }

        /// The script picks the field: an Arabic query is read against the Arabic, a Latin one against
        /// the English lines together (the narrator line is part of the English text, as in the fold).
        func matches(arabic: String, english: [String]) -> Bool {
            matches(isArabic ? arabic : english.joined(separator: " "))
        }

        func matches(_ text: String) -> Bool {
            guard !groups.isEmpty else { return false }
            let words = Self.tokens(text)
            guard !words.isEmpty else { return false }
            let found: ([String]) -> Bool = { group in
                guard words.count >= group.count else { return false }
                for start in 0...(words.count - group.count)
                where group.indices.allSatisfy({ words[start + $0] == group[$0] }) {
                    return true
                }
                return false
            }
            return requireAll ? groups.allSatisfy(found) : groups.contains(where: found)
        }

        /// Tashkeel, the Quranic annotation signs and the loose marks: the same set the fold strips.
        private static let strippedMarks: Set<UInt32> = {
            var set = Set<UInt32>(0x064B...0x065F)
            set.formUnion(0x06D6...0x06ED)
            set.formUnion([0x0670, 0x0656, 0x0657, 0x0674, 0x0640])
            return set
        }()

        private static let dropped: CharacterSet = CharacterSet.punctuationCharacters.union(.symbols)

        /// The text's words with marks and punctuation gone and letters untouched. Composed first, so
        /// a decomposed accent and its precomposed twin read the same.
        static func tokens(_ text: String) -> [String] {
            var kept = String.UnicodeScalarView()
            for scalar in text.precomposedStringWithCanonicalMapping.unicodeScalars {
                if strippedMarks.contains(scalar.value) || dropped.contains(scalar) { continue }
                kept.append(scalar)
            }
            return String(kept).split(whereSeparator: { $0.isWhitespace || $0.isNewline }).map(String.init)
        }
    }

    // MARK: Persistence (preferences only)

    private struct Stored: Codable {
        var hidden: [Kind]
        var sort: Sort
    }

    static let storageKey = "hadithSearchFilterPreferences"

    /// The remembered preferences, re-read: the three search screens each hold their own filters, so
    /// an order chosen inside a book reaches the screen under it when that screen comes back.
    mutating func adoptStoredPreferences() {
        #if DEBUG
        // The launch argument below outranks the stored preferences for the whole run.
        if ProcessInfo.processInfo.arguments.contains("-hadithSearchFilters") { return }
        #endif
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let stored = try? JSONDecoder().decode(Stored.self, from: data) else { return }
        let hidden = Set(stored.hidden)
        if hiddenKinds != hidden { hiddenKinds = hidden }
        if sort != stored.sort { sort = stored.sort }
    }

    static func restored(scope: Scope = .allBooks) -> HadithSearchFilters {
        var filters = HadithSearchFilters()
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let stored = try? JSONDecoder().decode(Stored.self, from: data) {
            filters.hiddenKinds = Set(stored.hidden)
            filters.sort = stored.sort
        }
        #if DEBUG
        // "-hadithSearchFilters books=bukhari+muslim,grade=sahih+hasan,match=wholeWord,words=allWords,
        // sort=relevance,hide=ai": the buttons, pressed headlessly (pair with "-hadithSearch <term>").
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-hadithSearchFilters"), arguments.indices.contains(index + 1) {
            for pair in arguments[index + 1].split(separator: ",") {
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { continue }
                let values = parts[1].split(separator: "+").map(String.init)
                switch parts[0] {
                case "books": filters.books = Set(values)
                case "grade": filters.grades = Set(values.compactMap(Grade.init(rawValue:)))
                case "match": filters.match = Match(rawValue: parts[1]) ?? .contains
                case "words": filters.words = Words(rawValue: parts[1]) ?? .phrase
                case "sort": filters.sort = Sort(rawValue: parts[1]) ?? .collection
                case "hide": filters.hiddenKinds = Set(values.compactMap(Kind.init(rawValue:)))
                default: break
                }
            }
        }
        #endif
        if !scope.choosesBooks { filters.books = [] }
        return filters
    }

    func persistPreferences() {
        let stored = Stored(hidden: Array(hiddenKinds).sorted { $0.rawValue < $1.rawValue }, sort: sort)
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

// MARK: - The filter bar

struct HadithSearchFilterBar: View {
    @Environment(\.appearance) private var appearance
    /// Shared with the Quran search's row (`SearchFilterBar`): off, the common buttons only.
    @AppStorage(SearchFilterBar.everyButtonKey) private var showsEveryButton = false
    @Binding var filters: HadithSearchFilters
    /// Which screen the row rides on: a book or a chapter drops the collection buttons.
    var scope: HadithSearchFilters.Scope = .allBooks
    let onOpenSheet: () -> Void

    var body: some View {
        let activeCount = filters.activeCount(in: scope)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    Settings.shared.hapticFeedback()
                    onOpenSheet()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "slider.horizontal.3")
                        if activeCount > 0 {
                            Text("\(activeCount)").monospacedDigit()
                        }
                    }
                    .modifier(ChipStyle(isOn: activeCount > 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("All search filters")

                if filters.hasSessionFilters {
                    chipButton(String(localized: "Reset"), systemImage: "xmark", isOn: false) { filters.resetSession() }
                }

                if scope.choosesBooks {
                    divider
                    booksMenu
                    // The short row keeps the one preset most readers want; the other shows once it is on.
                    if showsEveryButton || filters.books == HadithSearchFilters.sixBooks {
                        chipButton(String(localized: "Six Books"), systemImage: nil, isOn: filters.books == HadithSearchFilters.sixBooks) {
                            filters.books = filters.books == HadithSearchFilters.sixBooks ? [] : HadithSearchFilters.sixBooks
                        }
                    }
                    chipButton(String(localized: "Bukhari & Muslim"), systemImage: nil, isOn: filters.books == HadithSearchFilters.sahihayn) {
                        filters.books = filters.books == HadithSearchFilters.sahihayn ? [] : HadithSearchFilters.sahihayn
                    }
                }

                divider
                ForEach(HadithSearchFilters.Grade.allCases) { grade in
                    chipButton(grade.title, systemImage: nil, isOn: filters.grades.contains(grade)) {
                        if filters.grades.contains(grade) { filters.grades.remove(grade) } else { filters.grades.insert(grade) }
                    }
                }

                divider
                if showsEveryButton {
                    matchMenu
                    wordsMenu
                    Menu {
                        Picker("Order", selection: $filters.sort) {
                            ForEach(HadithSearchFilters.Sort.allCases) { Text($0.title).tag($0) }
                        }
                    } label: {
                        chipLabel(filters.sort.title, systemImage: "arrow.up.arrow.down",
                                  isOn: filters.sort != .collection, isMenu: true)
                    }

                    divider
                    ForEach(scope.kinds) { kind in
                        chipButton(kind.title, systemImage: kind.systemImage, isOn: filters.shows(kind, in: scope)) {
                            filters.toggle(kind, in: scope)
                        }
                    }
                } else {
                    // The one ordering choice as a switch, then the Match and Words rules only once set.
                    chipButton(String(localized: "Best Match"), systemImage: "arrow.up.arrow.down", isOn: filters.sort == .relevance) {
                        filters.sort = filters.sort == .relevance ? .collection : .relevance
                    }
                    if filters.match != .contains { matchMenu }
                    if filters.words != .phrase { wordsMenu }
                }

                divider
                chipButton(showsEveryButton ? String(localized: "Fewer") : String(localized: "More"),
                           systemImage: showsEveryButton ? "chevron.backward" : "ellipsis", isOn: false) {
                    showsEveryButton.toggle()
                }
                .accessibilityHint(showsEveryButton ? "Shows only the common filters" : "Shows every filter as a button")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        // The keyboard first: a menu here updated over a live keyboard aborted (`endsEditingOnTouch`).
        .endsEditingOnTouch()
    }

    private var divider: some View {
        Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 1, height: 18)
    }

    private var matchMenu: some View {
        Menu {
            Picker("Match", selection: $filters.match) {
                ForEach(HadithSearchFilters.Match.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            chipLabel(filters.match == .contains ? String(localized: "Match") : filters.match.title,
                      systemImage: "character.cursor.ibeam", isOn: filters.match != .contains, isMenu: true)
        }
    }

    private var wordsMenu: some View {
        Menu {
            Picker("Words", selection: $filters.words) {
                ForEach(HadithSearchFilters.Words.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            chipLabel(filters.words == .phrase ? String(localized: "Words") : filters.words.title,
                      systemImage: "text.word.spacing", isOn: filters.words != .phrase, isMenu: true)
        }
    }

    private var booksTitle: String {
        switch filters.books.count {
        case 0: return String(localized: "Books")
        case 1: return HadithCatalogBook.bySlug[filters.books.first ?? ""]?.displayTitle ?? String(localized: "1 Book")
        default: return String(localized: "\(filters.books.count) Books")
        }
    }

    private var booksMenu: some View {
        Menu {
            if !filters.books.isEmpty {
                Button("Every Collection") { filters.books = [] }
            }
            // One submenu per group of the Hadith tab (the Six Books, the early collections, the
            // forties, the rest), not seventeen rows in one (Abu, 2026-10-21: menus "not too long"). A
            // submenu's label counts what it holds, so a filter set inside it still shows from outside.
            ForEach(HadithCatalogBook.Group.allCases, id: \.self) { group in
                let books = HadithCatalogBook.all.filter { $0.group == group }
                if !books.isEmpty {
                    let picked = books.filter { filters.books.contains($0.slug) }.count
                    Menu {
                        ForEach(books, id: \.slug) { book in
                            Toggle(book.displayTitle, isOn: Binding(
                                get: { filters.books.contains(book.slug) },
                                set: { isOn in
                                    if isOn { filters.books.insert(book.slug) } else { filters.books.remove(book.slug) }
                                }
                            ))
                            // The root PaddedSwitchToggleStyle draws double-height menu rows on iOS 26.
                            .toggleStyle(.automatic)
                        }
                    } label: {
                        let title = group.rawValue.localizedDisplay.capitalized
                        Label(picked > 0 ? "\(title) (\(String(picked).localizedDigits))" : title,
                              systemImage: picked > 0 ? "checkmark" : group.systemImage)
                    }
                }
            }
        } label: {
            chipLabel(booksTitle, systemImage: "books.vertical", isOn: !filters.books.isEmpty, isMenu: true)
        }
        .modifier(KeepMenuOpen())
    }

    private func chipButton(_ title: String, systemImage: String?, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            chipLabel(title, systemImage: systemImage, isOn: isOn, isMenu: false)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func chipLabel(_ title: String, systemImage: String?, isOn: Bool, isMenu: Bool) -> some View {
        HStack(spacing: 5) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title).lineLimit(1)
            if isMenu {
                Image(systemName: "chevron.down").font(.caption2.weight(.bold)).opacity(0.7)
            }
        }
        .modifier(ChipStyle(isOn: isOn))
    }

    private struct ChipStyle: ViewModifier {
        @Environment(\.appearance) private var appearance
        let isOn: Bool

        func body(content: Content) -> some View {
            content
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(isOn ? Color.white : appearance.accent)
                .background(isOn ? Capsule().fill(appearance.accent) : nil)
                .conditionalGlassEffect(useColor: isOn ? nil : 0.25, themeTint: false)
                .contentShape(Capsule())
        }
    }

    private struct KeepMenuOpen: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 16.4, *) {
                content.menuActionDismissBehavior(.disabled)
            } else {
                content
            }
        }
    }
}

// MARK: - The filter sheet

struct HadithSearchFilterSheet: View {
    @Environment(\.appearance) private var appearance
    @AppStorage(SearchFilterBar.everyButtonKey) private var showsEveryButton = false
    @AppStorage(SearchFilterBar.aiFirstKey) private var opensOnAI = false
    @Binding var filters: HadithSearchFilters
    /// Which screen opened the sheet: a book or a chapter has no COLLECTIONS section.
    var scope: HadithSearchFilters.Scope = .allBooks

    var body: some View {
        SheetNavigationContainer {
            List {
                Group {
                    if scope.choosesBooks {
                    Section {
                        optionRow(String(localized: "Every Collection"), detail: String(localized: "All \(HadithCatalogBook.all.count) books on the shelf"),
                                  isOn: filters.books.isEmpty) { filters.books = [] }
                        optionRow(String(localized: "The Six Books"), detail: String(localized: "Bukhari, Muslim, Abu Dawud, at-Tirmidhi, an-Nasa'i, Ibn Majah"),
                                  isOn: filters.books == HadithSearchFilters.sixBooks) { filters.books = HadithSearchFilters.sixBooks }
                        optionRow(String(localized: "Bukhari & Muslim"), detail: String(localized: "The two Sahihs only"),
                                  isOn: filters.books == HadithSearchFilters.sahihayn) { filters.books = HadithSearchFilters.sahihayn }
                        ForEach(HadithCatalogBook.all, id: \.slug) { book in
                            optionRow(book.displayTitle, detail: book.displayAuthor, isOn: filters.books.contains(book.slug)) {
                                if filters.books.contains(book.slug) { filters.books.remove(book.slug) } else { filters.books.insert(book.slug) }
                            }
                        }
                    } header: {
                        header(String(localized: "COLLECTIONS"))
                    } footer: {
                        Text("Chapters, hadiths and AI matches all come from the chosen books only.")
                    }
                    }

                    Section {
                        ForEach(HadithSearchFilters.Grade.allCases) { grade in
                            optionRow(grade.title, detail: grade.detail, isOn: filters.grades.contains(grade)) {
                                if filters.grades.contains(grade) { filters.grades.remove(grade) } else { filters.grades.insert(grade) }
                            }
                        }
                    } header: {
                        header(String(localized: "GRADING"))
                    } footer: {
                        Text((String(localized: "Pick any number. The gradings are the named scholars' own, as the collections record them; where they differ, a hadith counts under each. With a grading chosen, hadiths that carry no grading are left out. ")
                             + (scope.choosesBooks
                                ? String(localized: "A reference such as \u{201C}tirmidhi 2516\u{201D} always answers, whatever is chosen here.")
                                : String(localized: "A hadith looked up by its number always answers, whatever is chosen here."))).localizedDigits)
                    }

                    Section {
                        ForEach(HadithSearchFilters.Match.allCases) { match in
                            optionRow(match.title, detail: match.detail, isOn: filters.match == match) { filters.match = match }
                        }
                    } header: {
                        header(String(localized: "MATCH"))
                    }

                    Section {
                        ForEach(HadithSearchFilters.Words.allCases) { words in
                            optionRow(words.title, detail: words.detail, isOn: filters.words == words) { filters.words = words }
                        }
                    } header: {
                        header(String(localized: "SEVERAL WORDS"))
                    }

                    Section {
                        ForEach(HadithSearchFilters.Sort.allCases) { sort in
                            optionRow(sort.title, detail: sort.detail(in: scope), isOn: filters.sort == sort) { filters.sort = sort }
                        }
                    } header: {
                        header(String(localized: "HADITH ORDER"))
                    } footer: {
                        Text("Remembered between searches.")
                    }

                    Section {
                        ForEach(scope.kinds) { kind in
                            optionRow(kind.title, detail: kind.detail(in: scope), isOn: filters.shows(kind, in: scope)) {
                                filters.toggle(kind, in: scope)
                            }
                        }
                    } header: {
                        header(String(localized: "SHOW"))
                    } footer: {
                        Text("Remembered between searches.")
                    }

                    Section {
                        optionRow(String(localized: "Keyword Results"), detail: String(localized: "The hadiths carrying your words, closest match first"),
                                  isOn: !opensOnAI) { opensOnAI = false }
                        optionRow(String(localized: "AI Results"), detail: String(localized: "The hadiths closest in meaning, found on this device"),
                                  isOn: opensOnAI) { opensOnAI = true }
                    } header: {
                        header(String(localized: "OPEN ON"))
                    } footer: {
                        Text("When both answer a search, one switch chooses between them. This is the side it starts on. For the Quran search too.")
                    }

                    Section {
                        optionRow(String(localized: "Every Filter as a Button"),
                                  detail: String(localized: "The row over the results shows all of these, not only the common ones"),
                                  isOn: showsEveryButton) {
                            showsEveryButton.toggle()
                        }
                    } header: {
                        header(String(localized: "THE ROW OVER THE RESULTS"))
                    } footer: {
                        Text("Off, the row keeps to the collections, the gradings and Best Match, plus any filter set here. The More button in the row does the same. For the Quran search too.")
                    }

                    Section {
                        Button(role: .destructive) {
                            Settings.shared.hapticFeedback()
                            filters = HadithSearchFilters()
                        } label: {
                            Text("Reset All Filters").frame(maxWidth: .infinity)
                        }
                        .disabled(filters.activeCount(in: scope) == 0)
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .tint(appearance.accent)
    }

    private func header(_ text: String) -> some View {
        Text(text).foregroundStyle(appearance.accent)
    }

    private func optionRow(_ title: String, detail: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(.primary)
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? appearance.accent : Color.secondary.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
