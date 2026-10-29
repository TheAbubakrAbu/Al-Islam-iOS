#if os(iOS)
import SwiftUI

// The list the hadith study sheets share (Abu, 2026-10-27): the similar narrations of one hadith, the
// narrations carried by the same chain, and every narration naming a narrator are all lists of rows
// resolved from their books, read in place, sorted and grouped by match, book or grade from the
// toolbar menu, narrowed to chosen books, each row bookmarkable and openable in its book.

/// One narration resolved from its book, with everything its row draws.
struct HadithListEntry: Identifiable {
    let book: HadithCatalogBook
    /// The book's place on the shelf (`HadithCatalogBook.all`), for the book order and grouping.
    let bookOrder: Int
    let hadith: HadithBookData.Hadith
    let text: (arabic: String, narrator: String, text: String)
    let grades: [(name: String, grade: String)]
    /// The grade line as the row prints it ("Sahih (Al-Albani)"); "" when the book records none.
    let gradeLine: String
    /// The match tier, in the similar sheet; nil in the lists that have no tiers.
    let tier: SimilarHadithMatch.Tier?
    /// The match score (100 outside the similar sheet), for the closest-match order.
    let score: Int
    /// The row's badge ("82% similar", "Same text"), and a second, quieter one ("Same English").
    let badge: String?
    let secondaryBadge: String?
    /// What to tint in `text.arabic`, as UTF-16 ranges the pack shipped; empty for no tint.
    let sharedRanges: [NSRange]

    var id: String { "\(book.slug)-\(hadith.idInBook)" }

    /// What a list asks for: a row by its key, with the decoration the list wants on it.
    struct Request {
        let slug: String
        let idInBook: Int
        var tier: SimilarHadithMatch.Tier? = nil
        var score: Int = 100
        var badge: String? = nil
        var secondaryBadge: String? = nil
        var sharedRanges: [NSRange] = []
    }

    /// Every request resolved to its row: the books opened off the main thread when they are not open
    /// yet, then one block lookup per row for its text and grades, as the reader's rows do. A request
    /// whose row is not on the shelf is left out.
    static func resolve(_ requests: [Request]) async -> [HadithListEntry] {
        var opened: [String: HadithBookData] = [:]
        for request in requests where opened[request.slug] == nil {
            guard let catalog = HadithCatalogBook.bySlug[request.slug] else { continue }
            if let data = await HadithStore.shared.openOffMain(catalog) { opened[request.slug] = data }
        }
        let order = Dictionary(HadithCatalogBook.all.enumerated().map { ($0.element.slug, $0.offset) },
                               uniquingKeysWith: { first, _ in first })
        let books = opened
        return await Task.detached(priority: .userInitiated) { () -> [HadithListEntry] in
            requests.compactMap { request in
                guard let catalog = HadithCatalogBook.bySlug[request.slug], let data = books[request.slug],
                      let found = data.hadith(numbered: request.idInBook) else { return nil }
                let grades = found.grades
                return HadithListEntry(book: catalog, bookOrder: order[request.slug] ?? order.count, hadith: found,
                                       text: found.allText, grades: grades, gradeLine: HadithGradeLine.joined(grades),
                                       tier: request.tier, score: request.score, badge: request.badge,
                                       secondaryBadge: request.secondaryBadge, sharedRanges: request.sharedRanges)
            }
        }.value
    }
}

/// The list of resolved rows under a sheet's own sections, with the toolbar options menu that orders,
/// groups and narrows it. `tiered` lists (the similar sheet's) offer the match order and grouping too.
struct HadithResolvedList<Header: View>: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var hadithSettings = HadithSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared

    /// The order within a group: the closest match first (the pack's own order), the shelf's order, or
    /// the grade line alphabetically. The verdicts are never ranked (see `HadithBookData.Hadith.grades`):
    /// the grade sort only keeps equal verdicts together.
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
        case match, book, grade, none

        var id: String { rawValue }

        var title: String {
            switch self {
            case .match: return String(localized: "By Match")
            case .book: return String(localized: "By Book")
            case .grade: return String(localized: "By Grade")
            case .none: return String(localized: "No Groups")
            }
        }
    }

    private struct Bucket: Identifiable {
        let id: String
        let title: String
        let rows: [HadithListEntry]
    }

    let entries: [HadithListEntry]
    /// The similar sheet's list: match order and grouping on offer, and the default.
    var tiered = false
    /// What an empty list says.
    let emptyText: String
    /// The last section's footnote: where the list came from.
    let footnote: String
    @ViewBuilder let header: () -> Header

    @State private var sort: Sort?
    @State private var grouping: Grouping?
    /// The books taken out through the Books menu; empty shows every book.
    @State private var hiddenBooks: Set<String> = []

    private var currentSort: Sort { sort ?? (tiered ? .match : .book) }
    private var currentGrouping: Grouping { grouping ?? (tiered ? .match : .book) }

    var body: some View {
        let visible = entries.filter { !hiddenBooks.contains($0.book.slug) }
        let sections = grouped(sorted(visible))
        List {
            Group {
                header()

                if entries.isEmpty {
                    Text(emptyText)
                        .foregroundStyle(.secondary)
                } else if visible.isEmpty {
                    Text("Every book is hidden. Show one from the Books menu.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        Section {
                            ForEach(section.rows) { row in
                                HadithListRow(entry: row)
                            }
                        } header: {
                            if !section.title.isEmpty {
                                HStack {
                                    Text(section.title)
                                    Spacer()
                                    Text("\(section.rows.count)")
                                }
                            }
                        } footer: {
                            if index == sections.count - 1 {
                                Text(footnote)
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) { optionsMenu }
        }
    }

    private func sorted(_ rows: [HadithListEntry]) -> [HadithListEntry] {
        switch currentSort {
        case .match:
            return rows.sorted {
                ($0.tier?.rawValue ?? 0, -$0.score, $0.bookOrder, $0.hadith.idInBook)
                    < ($1.tier?.rawValue ?? 0, -$1.score, $1.bookOrder, $1.hadith.idInBook)
            }
        case .book:
            return rows.sorted { ($0.bookOrder, $0.hadith.idInBook) < ($1.bookOrder, $1.hadith.idInBook) }
        case .grade:
            // Graded rows first, alphabetically by their line; within a line, the shelf's order.
            return rows.sorted {
                ($0.gradeLine.isEmpty ? 1 : 0, $0.gradeLine, $0.tier?.rawValue ?? 0, -$0.score, $0.bookOrder, $0.hadith.idInBook)
                    < ($1.gradeLine.isEmpty ? 1 : 0, $1.gradeLine, $1.tier?.rawValue ?? 0, -$1.score, $1.bookOrder, $1.hadith.idInBook)
            }
        }
    }

    /// The sorted rows cut into sections (buckets); each keeps the rows' order.
    private func grouped(_ rows: [HadithListEntry]) -> [Bucket] {
        switch currentGrouping {
        case .none:
            return [Bucket(id: "all", title: "", rows: rows)]
        case .match:
            return SimilarHadithMatch.Tier.allCases.compactMap { tier in
                let members = rows.filter { $0.tier == tier }
                return members.isEmpty ? nil : Bucket(id: "tier-\(tier.rawValue)", title: Self.title(for: tier), rows: members)
            }
        case .book:
            var order: [String] = []
            var byBook: [String: [HadithListEntry]] = [:]
            for row in rows {
                if byBook[row.book.slug] == nil { order.append(row.book.slug) }
                byBook[row.book.slug, default: []].append(row)
            }
            return order
                .sorted { (byBook[$0]?.first?.bookOrder ?? 0) < (byBook[$1]?.first?.bookOrder ?? 0) }
                .compactMap { slug in
                    guard let members = byBook[slug], let first = members.first else { return nil }
                    return Bucket(id: "book-\(slug)", title: first.book.displayTitle, rows: members)
                }
        case .grade:
            var order: [String] = []
            var byGrade: [String: [HadithListEntry]] = [:]
            for row in rows {
                if byGrade[row.gradeLine] == nil { order.append(row.gradeLine) }
                byGrade[row.gradeLine, default: []].append(row)
            }
            // The largest groups first; the rows whose book records no grade (al-Bukhari and Muslim,
            // by design) last.
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

    // MARK: The options menu

    /// What shapes the list, as the toolbar options menu: the order, the grouping, and the books shown.
    private var optionsMenu: some View {
        Menu {
            // Inline pickers under their own headers, the Ask AI menu's shape.
            Section("Sort By") {
                Picker("Sort By", selection: Binding(get: { currentSort }, set: { sort = $0; settings.hapticFeedback() })) {
                    ForEach(Sort.allCases.filter { tiered || $0 != .match }) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Group") {
                Picker("Group", selection: Binding(get: { currentGrouping }, set: { grouping = $0; settings.hapticFeedback() })) {
                    ForEach(Grouping.allCases.filter { tiered || $0 != .match }) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
                .pickerStyle(.inline)
            }

            if booksShown.count > 1 {
                Section {
                    Menu {
                        ForEach(booksShown, id: \.book.slug) { entry in
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
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .fixedMenuOrder()
        .tint(settings.accentColor.color)
        .accessibilityLabel("Sort and group options")
    }

    /// The books the rows come from, in the shelf's order, with how many rows each has here.
    private var booksShown: [(book: HadithCatalogBook, count: Int)] {
        var counts: [String: Int] = [:]
        var books: [String: (HadithCatalogBook, Int)] = [:]
        for row in entries {
            counts[row.book.slug, default: 0] += 1
            books[row.book.slug] = (row.book, row.bookOrder)
        }
        return books.values
            .sorted { $0.1 < $1.1 }
            .map { (book: $0.0, count: counts[$0.0.slug] ?? 0) }
    }

    private func binding(for slug: String) -> Binding<Bool> {
        Binding(
            get: { !hiddenBooks.contains(slug) },
            set: { shown in
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    if shown { hiddenBooks.remove(slug) } else { hiddenBooks.insert(slug) }
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
        // Both toggles off still shows the Arabic: a row with nothing on it answers nothing.
        let showsArabic = (settings.showHadithArabic || !settings.showHadithEnglish) && !entry.text.arabic.isEmpty
        let showsEnglish = settings.showHadithEnglish && !(entry.text.narrator.isEmpty && entry.text.text.isEmpty)
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
                        .conditionalGlassEffect()
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Hadith Actions")
            }

            if !entry.grades.isEmpty {
                HadithGradeLine(grades: entry.grades, font: .footnote)
            }

            if showsArabic { arabicBlock }
            if showsEnglish { englishBlock }
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
        .conditionalGlassEffect(
            useColor: isBookmarked ? 0.3 : nil,
            customTint: isBookmarked ? accent : nil,
            interactive: false
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
            Text(badge)
                .font(.caption2.weight(.semibold))
                .foregroundColor(accent)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(accent.opacity(0.14)))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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

    private var arabicBlock: some View {
        let custom = settings.hadithArabicWantsCustomFace
        let size = CGFloat(settings.hadithArabicFontSize)
        let font: Font = custom ? Font.arabic(settings.nonQuranArabicFontName, size: size) : .system(size: size)
        return Group {
            if HadithArabicChunks.needed(entry.text.arabic) {
                // The longest narrations, in the chosen face: sentence-bounded chunks (`HadithArabicChunks`).
                HadithArabicText(
                    text: entry.text.arabic,
                    term: "",
                    font: font,
                    lineSpacing: 6,
                    extraHighlightRanges: entry.sharedRanges
                )
            } else {
                HighlightedSnippet(
                    source: entry.text.arabic,
                    term: "",
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
    private var englishBlock: some View {
        let size = CGFloat(settings.hadithEnglishFontSize)
        if !entry.text.narrator.isEmpty {
            Text(entry.text.narrator)
                .font(.system(size: size).italic())
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                // The English reads left to right in the Arabic interface too.
                .leftToRightContent()
        }

        if !entry.text.text.isEmpty {
            HighlightedSnippet(
                source: entry.text.text,
                term: "",
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
