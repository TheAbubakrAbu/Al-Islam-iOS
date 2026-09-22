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
            case .chapters: return "Chapters"
            case .ai: return "AI"
            case .hadiths: return "Hadiths"
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
            case .chapters: return "Chapter titles, in Arabic or English"
            case .ai: return "Meaning matches and the Ask AI row"
            case .hadiths: return "The narration, its narrator line and its Arabic"
            }
        }

        func detail(in scope: Scope) -> String {
            self == .ai && scope == .oneChapter ? "Meaning matches from this chapter" : detail
        }
    }

    enum Words: String, CaseIterable, Identifiable {
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
            case .allWords: return "Every word, anywhere in the hadith: \u{201C}anger control\u{201D} finds both apart"
            case .anyWord: return "At least one of the words"
            }
        }
    }

    /// A grading class. A hadith several scholars graded belongs to every class any of them gave it.
    enum Grade: String, CaseIterable, Identifiable {
        case sahih, hasan, daif
        var id: String { rawValue }

        var title: String {
            switch self {
            case .sahih: return "Sahih"
            case .hasan: return "Hasan"
            case .daif: return "Da'if"
            }
        }

        var detail: String {
            switch self {
            case .sahih: return "Graded authentic. Everything in Sahih al-Bukhari and Sahih Muslim counts."
            case .hasan: return "Graded good"
            case .daif: return "Graded weak, including munkar and fabricated reports"
            }
        }
    }

    enum Sort: String, CaseIterable, Identifiable, Codable {
        case collection, relevance
        var id: String { rawValue }

        var title: String { self == .collection ? "Collection Order" : "Best Match" }

        var detail: String {
            switch self {
            case .collection: return "Every match, book by book, in the order of the shelf"
            case .relevance: return "Closest matches first: chapter titles and whole words rank higher, and spelling is forgiven"
            }
        }

        func detail(in scope: Scope) -> String {
            switch (self, scope) {
            case (.collection, .oneBook): return "Every match, in the order of the book"
            case (.collection, .oneChapter): return "Every match, in the order of the chapter"
            case (.relevance, .oneChapter): return "Closest matches first: whole words rank higher, and spelling is forgiven"
            default: return detail
            }
        }
    }

    // Session filters.
    /// Book slugs. Empty = every collection.
    var books: Set<String> = []
    /// Empty = any grading, and ungraded hadiths too.
    var grades: Set<Grade> = []
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

    var hasSessionFilters: Bool { !books.isEmpty || !grades.isEmpty || words != .phrase }

    var activeCount: Int {
        [!books.isEmpty, !grades.isEmpty, words != .phrase, !hiddenKinds.isEmpty, sort != .collection]
            .filter { $0 }.count
    }

    /// `activeCount` for one screen: only the controls that screen carries are counted.
    func activeCount(in scope: Scope) -> Int {
        let hidesSomething = scope.kinds.contains { !shows($0, in: scope) }
        return [scope.choosesBooks && !books.isEmpty, !grades.isEmpty, words != .phrase, hidesSomething, sort != .collection]
            .filter { $0 }.count
    }

    mutating func resetSession() {
        books = []
        grades = []
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

    /// The query as the byte sweep reads it: one needle for a phrase, one per word otherwise.
    func needles(for query: String) -> (queries: [HadithFold.Query], requireAll: Bool) {
        let whole = HadithFold.query(query)
        guard words != .phrase else { return ([whole], true) }
        let parts = query.split(whereSeparator: { $0.isWhitespace }).map(String.init).filter { $0.count >= 2 }
        guard parts.count > 1 else { return ([whole], true) }
        return (parts.map { HadithFold.query($0) }, words == .allWords)
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
        // "-hadithSearchFilters books=bukhari+muslim,grade=sahih+hasan,words=allWords,sort=relevance,
        // hide=ai": the buttons, pressed headlessly (pair with "-hadithSearch <term>").
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-hadithSearchFilters"), arguments.indices.contains(index + 1) {
            for pair in arguments[index + 1].split(separator: ",") {
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { continue }
                let values = parts[1].split(separator: "+").map(String.init)
                switch parts[0] {
                case "books": filters.books = Set(values)
                case "grade": filters.grades = Set(values.compactMap(Grade.init(rawValue:)))
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
                    chipButton("Reset", systemImage: "xmark", isOn: false) { filters.resetSession() }
                }

                if scope.choosesBooks {
                    divider
                    booksMenu
                    chipButton("Six Books", systemImage: nil, isOn: filters.books == HadithSearchFilters.sixBooks) {
                        filters.books = filters.books == HadithSearchFilters.sixBooks ? [] : HadithSearchFilters.sixBooks
                    }
                    chipButton("Bukhari & Muslim", systemImage: nil, isOn: filters.books == HadithSearchFilters.sahihayn) {
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
                Menu {
                    Picker("Words", selection: $filters.words) {
                        ForEach(HadithSearchFilters.Words.allCases) { Text($0.title).tag($0) }
                    }
                } label: {
                    chipLabel(filters.words == .phrase ? "Words" : filters.words.title,
                              systemImage: "text.word.spacing", isOn: filters.words != .phrase, isMenu: true)
                }
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private var divider: some View {
        Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 1, height: 18)
    }

    private var booksTitle: String {
        switch filters.books.count {
        case 0: return "Books"
        case 1: return HadithCatalogBook.bySlug[filters.books.first ?? ""]?.englishTitle ?? "1 Book"
        default: return "\(filters.books.count) Books"
        }
    }

    private var booksMenu: some View {
        Menu {
            if !filters.books.isEmpty {
                Button("Every Collection") { filters.books = [] }
            }
            ForEach(HadithCatalogBook.all, id: \.slug) { book in
                Toggle(book.englishTitle, isOn: Binding(
                    get: { filters.books.contains(book.slug) },
                    set: { isOn in
                        if isOn { filters.books.insert(book.slug) } else { filters.books.remove(book.slug) }
                    }
                ))
                // The root PaddedSwitchToggleStyle draws double-height menu rows on iOS 26.
                .toggleStyle(.automatic)
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
    @Binding var filters: HadithSearchFilters
    /// Which screen opened the sheet: a book or a chapter has no COLLECTIONS section.
    var scope: HadithSearchFilters.Scope = .allBooks

    var body: some View {
        SheetNavigationContainer {
            List {
                Group {
                    if scope.choosesBooks {
                    Section {
                        optionRow("Every Collection", detail: "All \(HadithCatalogBook.all.count) books on the shelf",
                                  isOn: filters.books.isEmpty) { filters.books = [] }
                        optionRow("The Six Books", detail: "Bukhari, Muslim, Abu Dawud, at-Tirmidhi, an-Nasa'i, Ibn Majah",
                                  isOn: filters.books == HadithSearchFilters.sixBooks) { filters.books = HadithSearchFilters.sixBooks }
                        optionRow("Bukhari & Muslim", detail: "The two Sahihs only",
                                  isOn: filters.books == HadithSearchFilters.sahihayn) { filters.books = HadithSearchFilters.sahihayn }
                        ForEach(HadithCatalogBook.all, id: \.slug) { book in
                            optionRow(book.englishTitle, detail: book.authorEnglish, isOn: filters.books.contains(book.slug)) {
                                if filters.books.contains(book.slug) { filters.books.remove(book.slug) } else { filters.books.insert(book.slug) }
                            }
                        }
                    } header: {
                        header("COLLECTIONS")
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
                        header("GRADING")
                    } footer: {
                        Text("Pick any number. The gradings are the named scholars' own, as the collections record them; where they differ, a hadith counts under each. With a grading chosen, hadiths that carry no grading are left out. "
                             + (scope.choosesBooks
                                ? "A reference such as \u{201C}tirmidhi 2516\u{201D} always answers, whatever is chosen here."
                                : "A hadith looked up by its number always answers, whatever is chosen here."))
                    }

                    Section {
                        ForEach(HadithSearchFilters.Words.allCases) { words in
                            optionRow(words.title, detail: words.detail, isOn: filters.words == words) { filters.words = words }
                        }
                    } header: {
                        header("SEVERAL WORDS")
                    }

                    Section {
                        ForEach(HadithSearchFilters.Sort.allCases) { sort in
                            optionRow(sort.title, detail: sort.detail(in: scope), isOn: filters.sort == sort) { filters.sort = sort }
                        }
                    } header: {
                        header("HADITH ORDER")
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
                        header("SHOW")
                    } footer: {
                        Text("Remembered between searches.")
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
