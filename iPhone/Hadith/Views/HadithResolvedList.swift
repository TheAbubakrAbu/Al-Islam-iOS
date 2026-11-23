#if os(iOS)
import SwiftUI

// The list the hadith study screens share (Abu, 2026-10-27): the similar narrations of one hadith, the
// narrations carried by the same chain, a road of a tree, and every narration naming a narrator are
// all lists of rows read in place from their books, bookmarkable and openable in the book.
//
// Since 2026-11-22 (Abu: "when I click on a narrator one theres a progress view that loads", "make it
// more powerful and useful and stronger and better filtering", "instead of filtering being at the top
// right put it at the bottom right with a search bar"):
// - A list is ready on the frame its screen opens. An entry holds its row's place in its book and
//   nothing of its text; the row reads its words when it is drawn, one block lookup, as the reader's
//   rows do. Every list used to read all of its text first, behind a spinner: about a second for a
//   narrator of six thousand narrations.
// - What shapes it lives in `HadithListModel`: the order, the groups, the books shown, where the
//   narrator stands in the chain, the grade, and a search of the narrations' own words. The screen
//   that owns the list owns the model, so its header can narrow the list too (a narrator's counts
//   are buttons).
// - The search field sits at the foot of the screen with the options menu at its far side, the
//   Quran and Arabic screens' bar.

/// One narration of a list: where it stands on the shelf, and what its list decorates it with.
struct HadithListEntry: Identifiable {
    let book: HadithCatalogBook
    /// The book's place on the shelf (`HadithCatalogBook.all`), for the book order and grouping.
    let bookOrder: Int
    let hadith: HadithBookData.Hadith
    /// The match tier, in the similar sheet; nil in the lists that have no tiers.
    let tier: SimilarHadithMatch.Tier?
    /// The match score (100 outside the similar sheet), for the closest-match order.
    let score: Int
    /// The row's badge ("82% similar", "Same text"), and a second, quieter one ("Same English").
    let badge: String?
    let secondaryBadge: String?
    /// What to tint in the row's Arabic, as UTF-16 ranges the pack shipped; empty for no tint.
    let sharedRanges: [NSRange]
    /// A narrator's list: where he stands in this narration's chain, and the grade the pack counted
    /// it under. Nil in the other lists.
    let role: HadithNarratorRef.Role?
    let category: HadithGradeCategory?

    var id: String { "\(book.slug)-\(hadith.idInBook)" }

    /// The row's words, read from its book where they stand: one block lookup, on the row's own
    /// draw. Never kept on the entry, so a list of thousands costs its text only as it is scrolled.
    var text: (arabic: String, narrator: String, text: String) { hadith.allText }

    var grades: [(name: String, grade: String)] { hadith.grades }

    /// The grade line as the row prints it ("Sahih (Al-Albani)"); "" when the book records none.
    var gradeLine: String { HadithGradeLine.joined(grades) }

    /// The line the Grade sort and the Grade grouping file the row under: its verdicts as printed, and
    /// "Sahih" for the two Sahihs. They carry no grade line by design, because the collections are
    /// sahih, so their narrations never stand under "No Grade Recorded" (Abu, 2026-11-22: "when it
    /// says no grade reported if it's sahih Bukhari or Muslim that means sahih"). The search filters
    /// (`HadithSearchFilters.classes`) and the narrators' counts already read them so.
    var gradeGroup: String {
        let line = gradeLine
        return line.isEmpty && HadithSearchFilters.sahihayn.contains(book.slug) ? String(localized: "Sahih") : line
    }

    /// What a list asks for: a row by its key, with the decoration the list wants on it.
    struct Request {
        let slug: String
        let idInBook: Int
        var tier: SimilarHadithMatch.Tier? = nil
        var score: Int = 100
        var badge: String? = nil
        var secondaryBadge: String? = nil
        var sharedRanges: [NSRange] = []
        var role: HadithNarratorRef.Role? = nil
        var category: HadithGradeCategory? = nil
    }

    /// Every request as its entry, at once: the shelf's books are open from launch
    /// (`HadithStore.prewarmBooks`, a map and an id table each), and one that is not is opened here,
    /// two or three milliseconds. No text is read. A request whose row is not on the shelf is left out.
    @MainActor
    static func make(_ requests: [Request]) -> [HadithListEntry] {
        var books: [String: (HadithCatalogBook, HadithBookData, Int)] = [:]
        var missing: Set<String> = []
        let order = Dictionary(HadithCatalogBook.all.enumerated().map { ($0.element.slug, $0.offset) },
                               uniquingKeysWith: { first, _ in first })
        var out: [HadithListEntry] = []
        out.reserveCapacity(requests.count)
        for request in requests {
            if books[request.slug] == nil, !missing.contains(request.slug) {
                if let catalog = HadithCatalogBook.bySlug[request.slug],
                   let data = HadithStore.shared.cachedBook(request.slug) ?? HadithStore.shared.book(catalog) {
                    books[request.slug] = (catalog, data, order[request.slug] ?? order.count)
                } else {
                    missing.insert(request.slug)
                }
            }
            guard let (catalog, data, bookOrder) = books[request.slug],
                  let found = data.hadith(numbered: request.idInBook) else { continue }
            out.append(HadithListEntry(book: catalog, bookOrder: bookOrder, hadith: found, tier: request.tier,
                                       score: request.score, badge: request.badge, secondaryBadge: request.secondaryBadge,
                                       sharedRanges: request.sharedRanges, role: request.role, category: request.category))
        }
        return out
    }
}

// MARK: - The model

/// What shapes one list, and the list as shaped: the screen that shows the list makes one, hands it
/// to `HadithResolvedList`, and may narrow the list from its own header through it.
@MainActor
final class HadithListModel: ObservableObject {
    /// The order within a group: the closest match first (the pack's own order), the shelf's order, or
    /// by grade. The verdicts are never ranked (see `HadithBookData.Hadith.grades`): the grade sort only
    /// keeps equal verdicts together.
    enum Sort: String, CaseIterable, Identifiable {
        case match, book, grade

        var id: String { rawValue }

        var title: String {
            switch self {
            case .match: return String(localized: "Closest Match")
            case .book: return String(localized: "Book Order")
            case .grade: return String(localized: "Grade")
            }
        }
    }

    enum Grouping: String, CaseIterable, Identifiable {
        case match, book, grade, place, none

        var id: String { rawValue }

        var title: String {
            switch self {
            case .match: return String(localized: "By Match")
            case .book: return String(localized: "By Book")
            case .grade: return String(localized: "By Grade")
            case .place: return String(localized: "By Place in the Chain")
            case .none: return String(localized: "No Groups")
            }
        }
    }

    struct Bucket: Identifiable {
        let id: String
        let title: String
        let rows: [HadithListEntry]
    }

    let entries: [HadithListEntry]
    /// The similar sheet's list: the match order and grouping are on offer, and the default.
    let tiered: Bool
    /// A narrator's list: its rows know their place in the chain and their grade, so the list can
    /// be narrowed and grouped by both.
    let narrator: Bool

    @Published var sort: Sort { didSet { if sort != oldValue { rebuild() } } }
    @Published var grouping: Grouping { didSet { if grouping != oldValue { rebuild() } } }
    /// The books taken out through the Books menu; empty shows every book.
    @Published var hiddenBooks: Set<String> = [] { didSet { if hiddenBooks != oldValue { rebuild() } } }
    /// A narrator's list held to one place in the chain; nil shows every place.
    @Published var role: HadithNarratorRef.Role? { didSet { if role != oldValue { rebuild() } } }
    /// A narrator's list held to one grade; nil shows every grade.
    @Published var grade: HadithGradeCategory? { didSet { if grade != oldValue { rebuild() } } }
    /// The search field's text: the list is held to the narrations whose words carry every word of it.
    @Published var query = "" { didSet { if query != oldValue { search() } } }

    /// The list as shaped, a section a group.
    @Published private(set) var sections: [Bucket] = []
    /// How many rows the sections hold between them.
    @Published private(set) var shown = 0
    /// A search of the narrations' words is under way (a long list's takes a moment).
    @Published private(set) var searching = false

    /// The rows the search matched, by `HadithListEntry.id`; nil while nothing is searched for.
    private var matched: Set<String>?
    /// The query `matched` answers.
    private(set) var matchedQuery = ""
    private var searchTask: Task<Void, Never>?

    init(entries: [HadithListEntry], tiered: Bool = false, narrator: Bool = false) {
        self.entries = entries
        self.tiered = tiered
        self.narrator = narrator
        sort = tiered ? .match : .book
        grouping = tiered ? .match : .book
        rebuild()
    }

    /// The model of a list of rows by their keys (`HadithListEntry.make`).
    convenience init(requests: [HadithListEntry.Request], tiered: Bool = false, narrator: Bool = false) {
        self.init(entries: HadithListEntry.make(requests), tiered: tiered, narrator: narrator)
    }

    var sorts: [Sort] { Sort.allCases.filter { tiered || $0 != .match } }

    var groupings: [Grouping] {
        Grouping.allCases.filter { ($0 != .match || tiered) && ($0 != .place || narrator) }
    }

    /// Whether anything narrows the list: a hidden book, a place, a grade, a search.
    var isNarrowed: Bool {
        !hiddenBooks.isEmpty || role != nil || grade != nil || matched != nil
    }

    /// Everything shown again: the books, every place and grade, the search field emptied.
    func reset() {
        hiddenBooks = []
        role = nil
        grade = nil
        if !query.isEmpty { query = "" }
    }

    /// The books the rows come from, in the shelf's order, with how many rows each has here.
    private(set) lazy var books: [(book: HadithCatalogBook, count: Int)] = {
        var counts: [String: Int] = [:]
        var found: [String: (HadithCatalogBook, Int)] = [:]
        for row in entries {
            counts[row.book.slug, default: 0] += 1
            found[row.book.slug] = (row.book, row.bookOrder)
        }
        return found.values
            .sorted { $0.1 < $1.1 }
            .map { (book: $0.0, count: counts[$0.0.slug] ?? 0) }
    }()

    /// The four places a narrator can stand in a chain, from the Prophet ﷺ down to the compiler,
    /// with what the page calls each: its tiles, its badges, the groups and the menu.
    static var places: [(role: HadithNarratorRef.Role, title: String)] {
        [(.top, String(localized: "From the Prophet ﷺ")),
         (.end, String(localized: "Top of the Chain")),
         (.link, String(localized: "Middle Links")),
         (.teacher, String(localized: "Taught the compiler"))]
    }

    /// How many of a narrator's rows stand at a place in the chain, for the menu's counts.
    func count(role: HadithNarratorRef.Role) -> Int { entries.reduce(0) { $0 + ($1.role == role ? 1 : 0) } }

    func count(grade: HadithGradeCategory) -> Int { entries.reduce(0) { $0 + ($1.category == grade ? 1 : 0) } }

    // MARK: Shaping

    private func rebuild() {
        var rows = entries
        if !hiddenBooks.isEmpty { rows = rows.filter { !hiddenBooks.contains($0.book.slug) } }
        if let role { rows = rows.filter { $0.role == role } }
        if let grade { rows = rows.filter { $0.category == grade } }
        if let matched { rows = rows.filter { matched.contains($0.id) } }
        shown = rows.count
        sections = grouped(sorted(rows))
    }

    private func sorted(_ rows: [HadithListEntry]) -> [HadithListEntry] {
        switch sort {
        case .match:
            return rows.sorted {
                ($0.tier?.rawValue ?? 0, -$0.score, $0.bookOrder, $0.hadith.idInBook)
                    < ($1.tier?.rawValue ?? 0, -$1.score, $1.bookOrder, $1.hadith.idInBook)
            }
        case .book:
            return rows.sorted { ($0.bookOrder, $0.hadith.idInBook) < ($1.bookOrder, $1.hadith.idInBook) }
        case .grade:
            if narrator {
                // The pack's own counts: sahih, hasan, da'if, then the rest, in the shelf's order within.
                return rows.sorted {
                    ($0.category?.rawValue ?? 9, $0.bookOrder, $0.hadith.idInBook)
                        < ($1.category?.rawValue ?? 9, $1.bookOrder, $1.hadith.idInBook)
                }
            }
            // Graded rows first, alphabetically by their line (the two Sahihs under "Sahih"); within a
            // line, the shelf's order. The lines are read once, here.
            let keyed = rows.map { (row: $0, line: $0.gradeGroup) }
            return keyed.sorted {
                ($0.line.isEmpty ? 1 : 0, $0.line, $0.row.tier?.rawValue ?? 0, -$0.row.score, $0.row.bookOrder, $0.row.hadith.idInBook)
                    < ($1.line.isEmpty ? 1 : 0, $1.line, $1.row.tier?.rawValue ?? 0, -$1.row.score, $1.row.bookOrder, $1.row.hadith.idInBook)
            }.map(\.row)
        }
    }

    /// The sorted rows cut into sections; each keeps the rows' order.
    private func grouped(_ rows: [HadithListEntry]) -> [Bucket] {
        guard !rows.isEmpty else { return [] }
        switch grouping {
        case .none:
            return [Bucket(id: "all", title: "", rows: rows)]
        case .match:
            return SimilarHadithMatch.Tier.allCases.compactMap { tier in
                let members = rows.filter { $0.tier == tier }
                return members.isEmpty ? nil : Bucket(id: "tier-\(tier.rawValue)", title: Self.title(for: tier), rows: members)
            }
        case .book:
            var byBook: [String: [HadithListEntry]] = [:]
            for row in rows { byBook[row.book.slug, default: []].append(row) }
            return byBook.values
                .sorted { ($0.first?.bookOrder ?? 0) < ($1.first?.bookOrder ?? 0) }
                .compactMap { members in
                    members.first.map { Bucket(id: "book-\($0.book.slug)", title: $0.book.displayTitle, rows: members) }
                }
        case .place:
            // From the Prophet ﷺ down to the compiler: the chain's own order.
            return Self.places.compactMap { place in
                let members = rows.filter { $0.role == place.role }
                return members.isEmpty ? nil : Bucket(id: "place-\(place.role.rawValue)", title: place.title, rows: members)
            }
        case .grade:
            if narrator {
                return HadithGradeCategory.allCases.compactMap { category in
                    let members = rows.filter { $0.category == category }
                    return members.isEmpty ? nil : Bucket(id: "grade-\(category.rawValue)", title: category.title, rows: members)
                }
            }
            var order: [String] = []
            var byGrade: [String: [HadithListEntry]] = [:]
            for row in rows {
                let line = row.gradeGroup
                if byGrade[line] == nil { order.append(line) }
                byGrade[line, default: []].append(row)
            }
            // The largest groups first; the rows whose book records no grade last. Al-Bukhari's and
            // Muslim's are not among those: they stand under "Sahih" (`gradeGroup`).
            return order
                .sorted { a, b in
                    if a.isEmpty != b.isEmpty { return b.isEmpty }
                    let countA = byGrade[a]?.count ?? 0, countB = byGrade[b]?.count ?? 0
                    return countA != countB ? countA > countB : a < b
                }
                .compactMap { line in
                    guard let members = byGrade[line] else { return nil }
                    return Bucket(id: "grade-\(line)", title: line.isEmpty ? String(localized: "No Grade Recorded") : line, rows: members)
                }
        }
    }

    static func title(for tier: SimilarHadithMatch.Tier) -> String {
        switch tier {
        case .sameTextAndChain: return String(localized: "Same Text and Chain")
        case .sameText: return String(localized: "Same Text, Different Chain")
        case .similar: return String(localized: "Similar Wording")
        }
    }

    // MARK: Search

    /// The typed words looked for in the rows' own text, off the main thread, a beat after the last
    /// keystroke: each word folded as the packs fold their text (`HadithFold`) and matched as bytes
    /// in the search blocks the books ship, so nothing is decoded into Strings. A number alone finds
    /// the narration of that number. An emptied field shows the list whole again at once.
    private func search() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searching = false
            matchedQuery = ""
            if matched != nil {
                matched = nil
                rebuild()
            }
            return
        }
        searching = true
        let rows = entries
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }
            let found = await Task.detached(priority: .userInitiated) { Self.matches(trimmed, in: rows) }.value
            guard !Task.isCancelled, let self else { return }
            self.matched = found
            self.matchedQuery = trimmed
            self.searching = false
            self.rebuild()
        }
    }

    nonisolated private static func matches(_ raw: String, in rows: [HadithListEntry]) -> Set<String> {
        let words = raw.split(whereSeparator: \.isWhitespace).map { HadithFold.query(String($0)) }.filter { !$0.isEmpty }
        let number = raw.allSatisfy(\.isNumber) ? Int(raw) : nil
        var out: Set<String> = []
        for (index, row) in rows.enumerated() {
            if index % 512 == 0, Task.isCancelled { return out }
            if let number, row.hadith.idInBook == number || HadithCatalogBook.displayNumber(row.hadith.displayNumber) == raw {
                out.insert(row.id)
            } else if !words.isEmpty, words.allSatisfy({ row.hadith.matches($0) }) {
                out.insert(row.id)
            }
        }
        return out
    }
}

// MARK: - The list

/// The rows of a `HadithListModel` under a screen's own sections, with the bar at the foot that
/// searches and shapes them.
struct HadithResolvedList<Header: View>: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var hadithSettings = HadithSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared

    @ObservedObject var model: HadithListModel
    /// What an empty list says.
    let emptyText: String
    /// The last section's footnote: where the list came from.
    let footnote: String
    /// The search field's prompt.
    var prompt = String(localized: "Search these narrations")
    @ViewBuilder let header: () -> Header

    var body: some View {
        List {
            Group {
                header()

                if model.entries.isEmpty {
                    Section {
                        Text(emptyText)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    if model.isNarrowed || model.searching {
                        Section {
                            narrowedRow
                        }
                    }

                    ForEach(Array(model.sections.enumerated()), id: \.element.id) { index, section in
                        Section {
                            ForEach(section.rows) { row in
                                HadithListRow(entry: row, term: model.matchedQuery)
                            }
                        } header: {
                            // The app's section header: capitals and the count in its pill.
                            if !section.title.isEmpty {
                                SectionPillHeader(title: section.title.localizedUppercase, count: section.rows.count,
                                                  countText: section.rows.count.formatted())
                            }
                        } footer: {
                            if index == model.sections.count - 1 {
                                Text(footnote)
                            }
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                HStack(spacing: 8) {
                    SearchBar(text: $model.query, placeholder: prompt)

                    optionsMenu
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
            .background(Color.white.opacity(0.00001))
        }
        #if DEBUG
        // "-narrationsQuery <words>": the list searched for them as it appears. Headless
        // verification only (a search field cannot be typed into from a script).
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            if model.query.isEmpty, let index = arguments.firstIndex(of: "-narrationsQuery"), arguments.indices.contains(index + 1) {
                model.query = arguments[index + 1]
            }
        }
        #endif
    }

    /// What the list is held to, in one row: how many of its narrations are shown, and the way back
    /// to all of them. While a search runs, that it does.
    private var narrowedRow: some View {
        HStack(spacing: 10) {
            if model.searching {
                ProgressView()
                Text("Searching")
                    .foregroundStyle(.secondary)
            } else if model.shown == 0 {
                Text(model.matchedQuery.isEmpty
                     ? String(localized: "No narration fits these filters.")
                     : String(localized: "No narration here carries \u{201C}\(model.matchedQuery)\u{201D}."))
                    .foregroundStyle(.secondary)
            } else {
                Text(String(localized: "Showing \(model.shown) of \(model.entries.count)"))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if model.isNarrowed {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { model.reset() }
                } label: {
                    Text("Show All")
                }
                .buttonStyle(.accentChip)
            }
        }
        .font(.subheadline)
    }

    // MARK: The options menu

    /// What shapes the list, as the menu at the search field's far side: the place in the chain and
    /// the grade (a narrator's list), the order, the grouping, and the books shown.
    private var optionsMenu: some View {
        Menu {
            if model.narrator {
                Section("Place in the Chain") {
                    Picker("Place in the Chain", selection: Binding(get: { model.role }, set: { pick in
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { model.role = pick }
                    })) {
                        Text("Anywhere in the Chain").tag(HadithNarratorRef.Role?.none)
                        ForEach(HadithListModel.places.filter { model.count(role: $0.role) > 0 }, id: \.role) { place in
                            Text(place.title).tag(Optional(place.role))
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    Picker(selection: Binding(get: { model.grade }, set: { pick in
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { model.grade = pick }
                    })) {
                        Text("All").tag(HadithGradeCategory?.none)
                        ForEach(HadithGradeCategory.allCases.filter { model.count(grade: $0) > 0 }, id: \.rawValue) { category in
                            Text(category.title).tag(Optional(category))
                        }
                    } label: {
                        Label("Grade", systemImage: "checkmark.seal")
                    }
                    .pickerStyle(.menu)
                }
            }

            // Inline pickers under their own headers, the Ask AI menu's shape.
            Section("Sort By") {
                Picker("Sort By", selection: Binding(get: { model.sort }, set: { pick in
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { model.sort = pick }
                })) {
                    ForEach(model.sorts) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Group") {
                Picker("Group", selection: Binding(get: { model.grouping }, set: { pick in
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { model.grouping = pick }
                })) {
                    ForEach(model.groupings) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
                .pickerStyle(.inline)
            }

            if model.books.count > 1 {
                Section {
                    Menu {
                        ForEach(model.books, id: \.book.slug) { entry in
                            Toggle(isOn: binding(for: entry.book.slug)) {
                                Text(entry.book.displayTitle)
                                Text(String(localized: "\(entry.count) narrations"))
                            }
                            // `.automatic`, not the app's padded switch: inside a menu that style draws
                            // double-height rows with stray checkmarks (the menu toggle memory note).
                            .toggleStyle(.automatic)
                        }
                    } label: {
                        Label("Books", systemImage: "books.vertical")
                    }
                }
            }

            if model.isNarrowed {
                Section {
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { model.reset() }
                    } label: {
                        Label("Reset All Filters", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        } label: {
            // The Arabic screen's menu button: a glass circle the search field's height, filled in
            // while something narrows the list.
            Image(systemName: model.isNarrowed ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(settings.accentColor.color)
                .frame(width: 26, height: 26)
                .frame(width: 50, height: 50)
                .contentShape(Rectangle())
                .conditionalGlassEffect()
        }
        .fixedMenuOrder()
        .accessibilityLabel("Sort and group options")
    }

    private func binding(for slug: String) -> Binding<Bool> {
        Binding(
            get: { !model.hiddenBooks.contains(slug) },
            set: { shown in
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    if shown { model.hiddenBooks.remove(slug) } else { model.hiddenBooks.insert(slug) }
                }
            }
        )
    }
}

// MARK: - Open in Book

/// What a sheet does when a row asks to be opened in its book: the sheet closes itself and hands the
/// narration to the Hadith tab (`AppNavigation.openHadith`), which lands in its chapter. Set by the
/// sheet's root; a row shows "Open in Book" only where it is set.
private struct HadithOpenInBookKey: EnvironmentKey {
    static let defaultValue: ((String, Int) -> Void)? = nil
}

extension EnvironmentValues {
    var hadithOpenInBook: ((String, Int) -> Void)? {
        get { self[HadithOpenInBookKey.self] }
        set { self[HadithOpenInBookKey.self] = newValue }
    }
}

extension View {
    /// The sheet's root: rows beneath it can close it and open their narration in its book. The push
    /// waits for the sheet to be gone, so it lands on the tab's stack, not on a container on its way out.
    func hadithOpenInBook(dismiss: DismissAction) -> some View {
        modifier(HadithOpenInBookRoot(dismiss: dismiss))
    }
}

/// See `hadithOpenInBook(dismiss:)`.
private struct HadithOpenInBookRoot: ViewModifier {
    /// The request of the study sheet this one was opened over (a chain sheet raised from a row of
    /// the similar sheet), nil for the first sheet.
    @Environment(\.hadithOpenInBook) private var outer
    let dismiss: DismissAction

    func body(content: Content) -> some View {
        content.environment(\.hadithOpenInBook) { slug, idInBook in
            // Over another study sheet, the request goes to that one: closing it closes this one too.
            // Closing only this one left the first sheet standing over the book it opened.
            if let outer {
                outer(slug, idInBook)
                return
            }
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                AppNavigation.shared.openHadith(slug: slug, idInBook: idInBook)
            }
        }
    }
}

// MARK: - One row

/// One resolved narration: its reference pill (bookmarkable, like the reader's), its badges, the grade
/// line, then the Arabic with the shared words tinted and the English, following the reader's show
/// toggles. The menu (ellipsis and long press alike) bookmarks, opens in the book, opens the chain,
/// copies, shares.
struct HadithListRow: View {
    private var settings: Settings { .shared }
    /// Snapshotted at creation (the `HadithRow` rule): this view observes no settings, so it only redraws
    /// when a field it holds changes. The signature folds every hadith display setting its body reads
    /// (Arabic/English shown, sizes, face, accent, Allah highlight); without it a size or accent change
    /// left the visible rows as they were (2026-10-28).
    var renderSettingsSignature: String = Settings.shared.hadithRenderSettingsSignature
    @ObservedObject private var userData = HadithUserData.shared
    @Environment(\.hadithOpenInBook) private var openInBook

    let entry: HadithListEntry
    /// The words the list was searched for, painted where the row carries them; "" paints nothing.
    var term = ""

    @State private var showShareSheet = false
    @State private var showChainSheet = false

    private var accent: Color { settings.accentColor.color }

    private var isBookmarked: Bool {
        userData.isBookmarked(slug: entry.book.slug, idInBook: entry.hadith.idInBook)
    }

    private var hasChain: Bool {
        HadithChainStore.shared.hasChain(slug: entry.book.slug, idInBook: entry.hadith.idInBook)
    }

    var body: some View {
        // The row's words and verdicts, read here from the book's own blocks (one lookup each): the
        // list keeps none of them, so it opens without reading any.
        let text = entry.text
        let grades = entry.grades
        // Both toggles off still shows the Arabic: a row with nothing on it answers nothing.
        let showsArabic = (settings.showHadithArabic || !settings.showHadithEnglish) && !text.arabic.isEmpty
        let showsEnglish = settings.showHadithEnglish && !(text.narrator.isEmpty && text.text.isEmpty)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                pill
                badges
                Spacer(minLength: 0)
                Menu {
                    menuItems
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                        .foregroundColor(accent)
                        // The glass at the pill's 28pt height, as every row's (2026-11-16).
                        .frame(width: 28, height: 28)
                        .contentSurface(inRow: true)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Hadith Actions")
            }

            if !grades.isEmpty {
                HadithGradeLine(grades: grades, font: .footnote)
            }

            if showsArabic { arabicBlock(text.arabic) }
            if showsEnglish { englishBlock(narrator: text.narrator, body: text.text) }
        }
        .padding(.vertical, 4)
        .contextMenu { menuItems }
        .sheet(isPresented: $showShareSheet) {
            HadithShareSheet(book: entry.book, hadith: entry.hadith)
                .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showChainSheet) {
            HadithChainSheet(book: entry.book, hadith: entry.hadith)
        }
    }

    /// The reader's pill: number, book, tinted when bookmarked, and a tap toggles the bookmark.
    private var pill: some View {
        HStack(spacing: 5) {
            Text(HadithCatalogBook.displayNumber(entry.hadith.displayNumber))
                .font(.subheadline.monospacedDigit().weight(.semibold))

            Text(entry.book.displayTitle)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(accent)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, 8)
        .frame(height: 28)
        .contentSurface(
            useColor: isBookmarked ? 0.3 : nil,
            customTint: isBookmarked ? accent : nil,
            interactive: false,
            inRow: true
        )
        .contentShape(Rectangle())
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { userData.toggleBookmarkOrConfirm(book: entry.book, hadith: entry.hadith) }
        }
        .overlay(alignment: .topTrailing) {
            if isBookmarked {
                Image(systemName: "bookmark.fill")
                    .font(.caption2)
                    .foregroundStyle(accent)
                    .padding(4)
                    .offset(x: 8, y: -6)
            }
        }
    }

    @ViewBuilder
    private var badges: some View {
        if let badge = entry.badge {
            // The match at a glance: a ring filled to the score for similar wording, a seal for the
            // same text, then the words.
            HStack(spacing: 4) {
                if let tier = entry.tier {
                    if tier == .similar, entry.score < 100 {
                        ZStack {
                            Circle()
                                .stroke(accent.opacity(0.25), lineWidth: 2)
                            Circle()
                                .trim(from: 0, to: CGFloat(max(0, min(100, entry.score))) / 100)
                                .stroke(accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 11, height: 11)
                        .accessibilityHidden(true)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .accessibilityHidden(true)
                    }
                }

                Text(badge)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(accent)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(accent.opacity(0.14)))
        }

        if let secondary = entry.secondaryBadge {
            Text(secondary)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.primary.opacity(0.08)))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func arabicBlock(_ arabic: String) -> some View {
        let custom = settings.hadithArabicWantsCustomFace
        let size = CGFloat(settings.hadithArabicFontSize)
        let font: Font = custom ? Font.arabic(settings.nonQuranArabicFontName, size: size) : .system(size: size)
        return Group {
            if HadithArabicChunks.needed(arabic) {
                // The longest narrations, in the chosen face: sentence-bounded chunks (`HadithArabicChunks`).
                HadithArabicText(
                    text: arabic,
                    term: term,
                    font: font,
                    lineSpacing: 6,
                    extraHighlightRanges: entry.sharedRanges
                )
            } else {
                HighlightedSnippet(
                    source: arabic,
                    term: term,
                    font: font,
                    accent: accent,
                    fg: .primary,
                    highlightAllahNames: settings.highlightAllahNamesHadith,
                    extraHighlightRanges: entry.sharedRanges
                )
                .arabicFontDesign(custom: custom)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                // `.trailing` is the RIGHT edge only left to right: the Arabic hugs the right edge in
                // the Arabic interface too.
                .environment(\.layoutDirection, .leftToRight)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func englishBlock(narrator: String, body: String) -> some View {
        let size = CGFloat(settings.hadithEnglishFontSize)
        if !narrator.isEmpty {
            Text(narrator)
                .font(.system(size: size).italic())
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                // The English reads left to right in the Arabic interface too.
                .leftToRightContent()
        }

        if !body.isEmpty {
            HighlightedSnippet(
                source: body,
                term: term,
                font: .system(size: size),
                accent: accent,
                fg: .primary,
                highlightAllahNames: settings.highlightAllahNamesHadith
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .leftToRightContent()
        }
    }

    /// The reader's menu grammar, for a listed row: reference, bookmark | open in book, chain, copy, share.
    @ViewBuilder
    private var menuItems: some View {
        Text(entry.book.displayReference(entry.hadith.displayNumber))
            .foregroundStyle(.secondary)

        if isBookmarked {
            Button(role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) { userData.toggleBookmarkOrConfirm(book: entry.book, hadith: entry.hadith) }
            } label: {
                Label("Remove Bookmark", systemImage: "bookmark.fill")
            }
        } else {
            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) { userData.toggleBookmarkOrConfirm(book: entry.book, hadith: entry.hadith) }
            } label: {
                Label("Bookmark Hadith", systemImage: "bookmark")
            }
        }

        Divider()

        if let openInBook {
            Button {
                settings.hapticFeedback()
                openInBook(entry.book.slug, entry.hadith.idInBook)
            } label: {
                Label("Open in Book", systemImage: "book")
            }
        }

        if hasChain {
            Button {
                settings.hapticFeedback()
                showChainSheet = true
            } label: {
                Label("Chain of Narrators", systemImage: "point.3.connected.trianglepath.dotted")
            }
        }

        // Where it opens, then the text out: the reader's menu groups.
        if openInBook != nil || hasChain {
            Divider()
        }

        Button {
            settings.hapticFeedback()
            UIPasteboard.general.string = HadithShareSheet.composedText(book: entry.book, hadith: entry.hadith)
            CopyConfirmation.shared.show()
        } label: {
            Label("Copy Hadith", systemImage: "doc.on.doc")
        }

        Button {
            settings.hapticFeedback()
            showShareSheet = true
        } label: {
            Label("Share Hadith", systemImage: "square.and.arrow.up")
        }
    }
}
#endif
