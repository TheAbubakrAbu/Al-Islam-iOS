#if os(iOS)
import SwiftUI

// A narrator's page, the index of every narrator, and the narrations carried by one chain
// (HadithNarrators.swift), reached from a chain of narrators (Abu, 2026-10-27: "click on each person
// in the chain and see where else they are mentioned and see how many they are in, how many sahih,
// daif, etc and how many Hadiths they narrated and show all of them"; "all chains that are the exact
// same"). The pages read what the pack shipped and list the rows through `HadithResolvedList`.
//
// Since 2026-11-22 (Abu: "when I click on a narrator one theres a progress view that loads", "make it
// look prettier and match the rest of the app ui", "more powerful and useful and stronger and better
// filtering and easy to do things", "instead of filtering being at the top right put it at the bottom
// right with a search bar similar to Arabic or Quran for narrators"): each page is whole on the frame
// it opens (the profile and the list of rows are two lookups in blocks already in memory, and no
// text is read until a row is drawn); each opens on the app's hero card; a narrator's counts are the
// buttons that narrow his list; and the search field sits at the foot with the options beside it.

// MARK: - One narrator

/// What a narrator's page shows, read as the page is made: his profile and the list of every
/// narration naming him, each row knowing where he stands in its chain and how the pack counted its
/// grade.
@MainActor
final class HadithNarratorPage: ObservableObject {
    let profile: HadithNarratorProfile?
    let list: HadithListModel

    /// `scope`: the book or the chapter whose narrators he was opened from. His list then opens
    /// held to it, his narrations there and no others, one tap from all of them: the book through
    /// its own chip in BOOKS, a chapter through the row that says so (`HadithListModel.held`).
    init(narratorID: Int, scope: HadithNarratorScope? = nil) {
        let store = HadithNarratorStore.shared
        let profile = store.profile(id: narratorID)
        self.profile = profile
        let refs = profile == nil ? [] : store.refs(id: narratorID)
        // A row says where he stands when it is an end of the chain; a middle link says nothing.
        let badges = Dictionary(uniqueKeysWithValues: HadithListModel.places.map { ($0.role, $0.title) })
        list = HadithListModel(requests: refs.map { ref in
            HadithListEntry.Request(slug: ref.slug, idInBook: ref.idInBook,
                                    secondaryBadge: ref.role == .link ? nil : badges[ref.role],
                                    role: ref.role, category: ref.grade)
        }, narrator: true)
        guard let scope else { return }
        let slug = scope.book.slug
        if let chapter = scope.chapter {
            list.held = (Set(chapter.rows.map { "\(slug)-\($0)" }),
                         String(localized: "This chapter of \(scope.book.displayTitle)"))
        } else if list.books.count > 1, list.books.contains(where: { $0.book.slug == slug }) {
            list.hiddenBooks = Set(list.books.map(\.book.slug)).subtracting([slug])
        }
    }
}

/// One narrator: his name in both scripts, where he stands in the chains, his counts as the buttons
/// that narrow the list under them, the books he is found in, the other ways the shelf writes him,
/// then every narration naming him.
struct HadithNarratorView: View {
    let narratorID: Int

    @StateObject private var page: HadithNarratorPage

    init(narratorID: Int, scope: HadithNarratorScope? = nil) {
        self.narratorID = narratorID
        _page = StateObject(wrappedValue: HadithNarratorPage(narratorID: narratorID, scope: scope))
    }

    var body: some View {
        ZStack {
            if let profile = page.profile {
                HadithNarratorContent(profile: profile, list: page.list)
            } else {
                Text("This narrator's page could not be opened.")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .navigationTitle(page.profile.map { $0.english.isEmpty ? $0.name : $0.english } ?? String(localized: "Narrator"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The page under its title: watches the list's model, so a count lights while the list is held to it.
private struct HadithNarratorContent: View {
    @Environment(\.appearance) private var appearance
    private let settings = Settings.shared

    let profile: HadithNarratorProfile
    @ObservedObject var list: HadithListModel

    var body: some View {
        HadithResolvedList(
            model: list,
            emptyText: String(localized: "No narration naming this narrator could be read."),
            footnote: String(localized: "Counted ahead of time from the chains the app can read, about two thirds of the narrations in the eleven books that carry them. A narrator is matched by his name as each narration writes it; the written forms of one man are joined only where a title, a case ending, a shorter form of his name under his own student, or a nisba tells them apart and nothing else does, and each joined form is listed above with its count. A name that could be two men is left apart. A grade is the strongest word of each grader's verdict; Sahih al-Bukhari and Sahih Muslim carry no grade line and count as sahih, as the collections are.")
        ) {
            hero
            books
            forms
        }
    }

    // MARK: The hero

    /// "COMPANION" over the name in both scripts, how much he narrates, then his counts.
    private var hero: some View {
        let generation = HadithNarratorGeneration.label(profile.generation)
        let summary = String(localized: "\(profile.narrations) narrations") + " · " + String(localized: "\(profile.books.count) books")
        return ResourceHeroSection(ResourceHero(
            eyebrow: (generation.isEmpty ? String(localized: "Narrator") : generation).localizedUppercase,
            systemImage: "person.text.rectangle.fill",
            headline: profile.english.isEmpty ? profile.name : profile.english,
            arabic: profile.english.isEmpty ? nil : profile.name,
            message: summary
        ) {
            VStack(alignment: .leading, spacing: 10) {
                // Where he stands: the four places of a chain, which between them are every
                // narration naming him. Two to a row, so each name keeps one line.
                let places = HadithListModel.places
                VStack(spacing: 8) {
                    ForEach([0, 2], id: \.self) { start in
                        HStack(spacing: 8) {
                            ForEach(places[start..<start + 2], id: \.role) { entry in
                                place(entry.role, count(entry.role), entry.title)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                let grades = HadithGradeCategory.allCases.filter { profile.count($0) > 0 }
                if !grades.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(grades, id: \.rawValue) { category in
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) { list.grade = list.grade == category ? nil : category }
                            } label: {
                                Text(verbatim: "\(profile.count(category).formatted()) \(category.title)")
                                    .monospacedDigit()
                            }
                            .buttonStyle(.accentChip(filled: list.grade == category))
                            .accessibilityAddTraits(list.grade == category ? .isSelected : [])
                        }
                    }
                }

                Text("Tap a count to see only those narrations. A chain that stops at this narrator, with no one named above, counts under Top of the Chain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)
        })
    }

    /// How many of his narrations stand at a place, as the pack counted them.
    private func count(_ role: HadithNarratorRef.Role) -> Int {
        switch role {
        case .top: return profile.fromProphet
        case .end: return profile.ends
        case .teacher: return profile.teacher
        case .link: return max(0, profile.narrations - profile.fromProphet - profile.ends - profile.teacher)
        }
    }

    /// One place in the chain as a tile: the count over its name, lit while the list is held to it.
    /// A tap holds the list to it, a second tap lets go. A place he never stands in cannot be chosen.
    private func place(_ role: HadithNarratorRef.Role, _ count: Int, _ title: String) -> some View {
        let active = list.role == role
        let accent = appearance.accent
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { list.role = active ? nil : role }
        } label: {
            VStack(alignment: .leading, spacing: 1) {
                Text(count.formatted())
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(active ? .white : accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(active ? Color.white.opacity(0.9) : .secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(active ? AnyShapeStyle(accent) : AnyShapeStyle(Color.primary.opacity(0.05)))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
        .opacity(count == 0 ? 0.5 : 1)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    // MARK: The books

    /// The books he is found in, one chip each with its count, in the shelf's order: a tap shows that
    /// book's narrations alone, a second tap every book's again.
    @ViewBuilder
    private var books: some View {
        if list.books.count > 1 {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(list.books, id: \.book.slug) { entry in
                            let only = isOnly(entry.book.slug)
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    list.hiddenBooks = only ? [] : Set(list.books.map(\.book.slug)).subtracting([entry.book.slug])
                                }
                            } label: {
                                Text(verbatim: "\(entry.book.displayTitle) \(entry.count.formatted())")
                                    .monospacedDigit()
                            }
                            .buttonStyle(.accentChip(filled: only))
                            .accessibilityAddTraits(only ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal, 16)
                }
                // Edge to edge inside the card, so a chip slides out under the card's own edge.
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
            } header: {
                SectionPillHeader(title: String(localized: "Books").localizedUppercase, count: list.books.count)
            }
        }
    }

    /// Whether the list is held to this book alone.
    private func isOnly(_ slug: String) -> Bool {
        list.hiddenBooks.count == list.books.count - 1 && !list.hiddenBooks.contains(slug)
    }

    // MARK: The written forms

    /// The written forms joined into this page (Abu, 2026-10-31: "Aisha has 58?? ... make sure to
    /// normalize"): each with how many narrations write him so, so the join is in plain sight.
    @ViewBuilder
    private var forms: some View {
        if !profile.forms.isEmpty {
            Section {
                FlowLayout(spacing: 6) {
                    ForEach(Array(profile.forms.enumerated()), id: \.offset) { _, form in
                        HStack(spacing: 6) {
                            Text(form.name)
                                .font(appearance.islamArabicFont(base: 17, relativeTo: .footnote))
                                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                                .foregroundStyle(.primary)
                            Text(form.count.formatted())
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundColor(appearance.accent)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .contentSurface(interactive: false, inRow: true)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.vertical, 2)
            } header: {
                SectionPillHeader(title: String(localized: "Also Written As").localizedUppercase, count: profile.forms.count)
            } footer: {
                Text("Joined to this page by the shelf's own writing: a title set aside, the alef of the accusative, a shorter form of the name that only this narrator carries at that place in the chain or under that student, or a nisba dropped. The chain of each narration still shows the name as it writes it.")
            }
        }
    }
}

// MARK: - The narrators of one book, or of one chapter

/// The narrators named in the chains of one book, or of one of its chapters (Abu, 2026-11-23:
/// "Within each book at the bottom have narrators but only include if in the book ... would be nice
/// to have the same thing with each chapter"): who is named there, how often, and at which place of
/// the chain, counted inside that book or chapter alone (`HadithNarratorBookIndex`). The index of
/// narrators opens held to it (`HadithNarratorsIndexView(scope:)`), and a narrator opened from there
/// shows his narrations in it first (`HadithNarratorPage`).
struct HadithNarratorScope {
    struct Chapter {
        /// The chapter's id in its book.
        let id: Int
        /// The chapter's title as the reader sees it.
        let title: String
        /// The numbers (`idInBook`) of its narrations.
        let rows: [Int]
    }

    let book: HadithCatalogBook
    /// The chapter the scope is held to; nil for the whole book.
    let chapter: Chapter?
    /// By narrator id: everyone with a narration here, and no one else.
    let tallies: [Int: HadithNarratorTally]

    var count: Int { tallies.count }
    var isEmpty: Bool { tallies.isEmpty }

    /// The door's title, and the page's headline behind it.
    var title: String {
        chapter == nil ? String(localized: "Narrators in This Book") : String(localized: "Narrators in This Chapter")
    }

    /// How many narrators it holds, as the door's caption and the page's opening line.
    var caption: String { String(localized: "\(count) narrators named in its chains") }

    /// The scope counted, the book's index made first when it is not in hand: off the main thread
    /// (`HadithNarratorStore.bookIndex`). Also reads every profile once, so the page behind the
    /// door opens whole on its first frame (`HadithNarratorStore.allProfiles` keeps them). Empty
    /// for a book whose rows carry no chain the app reads.
    static func make(book: HadithCatalogBook, chapter: Chapter? = nil) -> HadithNarratorScope {
        let index = HadithNarratorStore.shared.bookIndex(slug: book.slug)
        _ = HadithNarratorStore.shared.allProfiles()
        return HadithNarratorScope(book: book, chapter: chapter, index: index)
    }

    /// The scope when the book's index is already made (a chapter opened from its book, a book
    /// come back to), else nil: nothing is walked, so the main thread may ask.
    static func ready(book: HadithCatalogBook, chapter: Chapter? = nil) -> HadithNarratorScope? {
        HadithNarratorStore.shared.cachedBookIndex(slug: book.slug).map {
            HadithNarratorScope(book: book, chapter: chapter, index: $0)
        }
    }

    private init(book: HadithCatalogBook, chapter: Chapter?, index: HadithNarratorBookIndex?) {
        self.book = book
        self.chapter = chapter
        tallies = chapter.map { index?.narrators(rows: $0.rows) ?? [:] } ?? index?.narrators ?? [:]
    }
}

/// The door to a book's or a chapter's narrators, at the foot of its page: the app's door row.
struct HadithScopedNarratorsDoor: View {
    private let settings = Settings.shared

    let scope: HadithNarratorScope
    let open: () -> Void

    var body: some View {
        Button {
            settings.hapticFeedback()
            open()
        } label: {
            SettingsRowLabel(title: scope.title, systemImage: "person.text.rectangle.fill",
                             subtitle: scope.caption, showsChevron: true)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Every narrator

/// What shapes the index of narrators, and the index as shaped: the search, the place in the chain,
/// the generation, the order and the grouping. Everything it reads was counted ahead of time
/// (HadithNarrators.qpk); a change files ten thousand profiles again, a millisecond or two.
@MainActor
final class HadithNarratorsIndexModel: ObservableObject {
    /// Where in the chain: the first narrator (who narrates from the Prophet ﷺ), one of the middle
    /// links, the last (the compiler's own teacher), or anywhere.
    enum Place: String, CaseIterable, Identifiable {
        case all, first, middle, last
        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return String(localized: "Anywhere in the Chain")
            case .first: return String(localized: "First: From the Prophet ﷺ")
            case .middle: return String(localized: "Middle Links")
            case .last: return String(localized: "Last: The Compilers' Teachers")
            }
        }

        /// How many of a narrator's narrations stand at this place: what his row counts, and what
        /// "Most Narrations" orders by, while the index is held to the place.
        func count(_ profile: HadithNarratorProfile) -> Int {
            switch self {
            case .all: return profile.narrations
            case .first: return profile.fromProphet
            case .last: return profile.teacher
            case .middle: return profile.narrations - profile.fromProphet - profile.ends - profile.teacher
            }
        }
    }

    enum Sort: String, CaseIterable, Identifiable {
        case narrations, name
        var id: String { rawValue }

        var title: String {
            switch self {
            case .narrations: return String(localized: "Most Narrations")
            case .name: return String(localized: "Name")
            }
        }
    }

    enum Grouping: String, CaseIterable, Identifiable {
        case generation, none
        var id: String { rawValue }

        var title: String {
            switch self {
            case .generation: return String(localized: "By Generation")
            case .none: return String(localized: "No Groups")
            }
        }
    }

    struct Bucket: Identifiable {
        let id: Int
        let title: String
        let rows: [HadithNarratorProfile]
    }

    let profiles: [HadithNarratorProfile]
    /// The generations the index holds, the Companions first and the unplaced last, with their counts.
    let generations: [(generation: Int, count: Int)]
    /// The book or chapter the index is held to: its narrators alone, each counted inside it. Nil
    /// for the whole shelf.
    let scope: HadithNarratorScope?

    @Published var query = "" { didSet { if query != oldValue { rebuild() } } }
    @Published var place: Place { didSet { if place != oldValue { rebuild() } } }
    /// The index held to one generation; nil shows them all.
    @Published var generation: Int? { didSet { if generation != oldValue { rebuild() } } }
    @Published var sort: Sort = .narrations { didSet { if sort != oldValue { rebuild() } } }
    @Published var grouping: Grouping = .generation { didSet { if grouping != oldValue { rebuild() } } }

    @Published private(set) var buckets: [Bucket] = []
    @Published private(set) var shown = 0

    /// What a typed name is looked for in, by the profile's place in `profiles`: the folded key and
    /// every other written form folded the same way, and the English without its apostrophes. Built
    /// on the first search, once.
    private lazy var haystacks: [(arabic: String, latin: String)] = profiles.map { profile in
        (([profile.key] + profile.forms.map { HadithIsnadEnglish.fold($0.name) }).joined(separator: "\n"),
         Self.latinFold(profile.english))
    }

    init(place: Place = .all, scope: HadithNarratorScope? = nil) {
        let everyone = HadithNarratorStore.shared.allProfiles()
        let profiles = scope.map { scope in everyone.filter { scope.tallies[$0.id] != nil } } ?? everyone
        self.profiles = profiles
        self.scope = scope
        self.place = place
        var counts: [Int: Int] = [:]
        for profile in profiles { counts[profile.generation, default: 0] += 1 }
        generations = counts.keys.sorted(by: Self.generationOrder).map { ($0, counts[$0] ?? 0) }
        rebuild()
    }

    var isNarrowed: Bool {
        place != .all || generation != nil || !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func reset() {
        place = .all
        generation = nil
        if !query.isEmpty { query = "" }
    }

    /// The Companions first, then each generation down, the unplaced last.
    private static func generationOrder(_ lhs: Int, _ rhs: Int) -> Bool {
        if lhs == 0 { return false }
        if rhs == 0 { return true }
        return lhs < rhs
    }

    /// How many of a narrator's narrations stand at a place: on the whole shelf (his profile's own
    /// counts), or inside the book or chapter the index is held to.
    func count(_ profile: HadithNarratorProfile, at place: Place) -> Int {
        guard let scope else { return place.count(profile) }
        guard let tally = scope.tallies[profile.id] else { return 0 }
        switch place {
        case .all: return tally.narrations
        case .first: return tally.fromProphet
        case .last: return tally.teacher
        case .middle: return tally.links
        }
    }

    /// Lower-case, the apostrophes of the hamza and 'ayn out, so "aishah" finds "A'ishah".
    static func latinFold(_ text: String) -> String {
        text.lowercased().filter { $0 != "'" && $0 != "\u{2019}" && $0 != "\u{2018}" && $0 != "-" }
    }

    private func rebuild() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var rows: [HadithNarratorProfile]
        if trimmed.isEmpty {
            rows = profiles
        } else {
            // The query folded as the index is (`HadithIsnadEnglish.fold` for Arabic, lower-case
            // Latin without apostrophes for English), matched against the name, its English and
            // every other written form.
            let arabic = trimmed.unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }
            let needle = arabic ? HadithIsnadEnglish.fold(trimmed) : Self.latinFold(trimmed)
            let haystacks = haystacks
            rows = profiles.indices.compactMap { index in
                (arabic ? haystacks[index].arabic : haystacks[index].latin).contains(needle) ? profiles[index] : nil
            }
        }
        let place = place
        if place != .all { rows = rows.filter { count($0, at: place) > 0 } }
        if let generation { rows = rows.filter { $0.generation == generation } }
        switch sort {
        case .narrations:
            // Counted once each, not once a comparison.
            let counts = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, count($0, at: place)) })
            rows.sort { (counts[$0.id] ?? 0, $1.id) > (counts[$1.id] ?? 0, $0.id) }
        case .name:
            rows.sort { ($0.key, $0.id) < ($1.key, $1.id) }
        }
        shown = rows.count
        guard grouping == .generation else {
            buckets = rows.isEmpty ? [] : [Bucket(id: 0, title: "", rows: rows)]
            return
        }
        var byGeneration: [Int: [HadithNarratorProfile]] = [:]
        for row in rows { byGeneration[row.generation, default: []].append(row) }
        buckets = byGeneration.keys.sorted(by: Self.generationOrder).map {
            Bucket(id: $0, title: HadithNarratorGeneration.title($0), rows: byGeneration[$0] ?? [])
        }
    }
}

/// The index of every narrator of the shelf's chains (Abu, 2026-10-31: "a narrators section ... that
/// shows all the narrators in all the different levels (like first middle or last or all), sort by
/// sahabah, tabieen, etc"), reached from the Hadith tab's NARRATORS section: searched by name in
/// either script from the bar at its foot, held to a generation by the chips of its hero or to a
/// place in the chain from the menu beside the search field, grouped by generation, sorted by how
/// much each narrates or by name.
struct HadithNarratorsIndexView: View {
    typealias Place = HadithNarratorsIndexModel.Place

    @Environment(\.appearance) private var appearance
    private let settings = Settings.shared

    @StateObject private var model: HadithNarratorsIndexModel
    @State private var pushedNarrator: Int?

    /// `initialPlace`: where the page lands, a place in the chain to open on, or anywhere.
    /// `scope`: the book or chapter whose narrators these are; nil lists the whole shelf's.
    init(initialPlace: Place = .all, scope: HadithNarratorScope? = nil) {
        _model = StateObject(wrappedValue: HadithNarratorsIndexModel(place: initialPlace, scope: scope))
    }

    var body: some View {
        List {
            Group {
                hero

                if model.isNarrowed {
                    Section {
                        narrowedRow
                    }
                }

                ForEach(Array(model.buckets.enumerated()), id: \.element.id) { index, bucket in
                    Section {
                        ForEach(bucket.rows) { profile in
                            row(profile)
                        }
                    } header: {
                        if !bucket.title.isEmpty {
                            SectionPillHeader(title: bucket.title.localizedUppercase, count: bucket.rows.count,
                                              countText: bucket.rows.count.formatted())
                        }
                    } footer: {
                        if index == model.buckets.count - 1 {
                            Text("A generation is a narrator's usual distance from the Prophet ﷺ across the chains that reach him, as written: the Companions narrate from him, the Successors from them. A narrator whose chains never name the Prophet ﷺ is not placed. Names are matched as the narrations write them; the written forms of one man are joined only where a title, a case ending or a shorter form of his name tells them apart and nothing else does.")
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
                    SearchBar(text: $model.query, placeholder: String(localized: "Search narrators"))

                    optionsMenu
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
            .background(Color.white.opacity(0.00001))
        }
        .pushDestination(item: $pushedNarrator) { narratorID in
            HadithNarratorView(narratorID: narratorID, scope: model.scope)
        }
        .navigationTitle(String(localized: "Narrators"))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// What the page is, how many it holds, and the generations as the chips that hold the list to
    /// one of them. Held to a book or a chapter, it says which: the book's title (and the
    /// chapter's) over the door's own words.
    private var hero: some View {
        let scope = model.scope
        let eyebrow = scope.map { [$0.book.displayTitle, $0.chapter?.title].compactMap { $0 }.joined(separator: " · ") }
            ?? String(localized: "Narrators of the Hadith")
        return ResourceHeroSection(ResourceHero(
            eyebrow: eyebrow.localizedUppercase,
            systemImage: "person.text.rectangle.fill",
            headline: scope?.title ?? String(localized: "Everyone the chains name"),
            message: scope?.caption
                ?? String(localized: "\(model.profiles.count) narrators of the chains the app can read, from the Companions down to the compilers' own teachers, each with every narration that names him.")
        ) {
            FlowLayout(spacing: 6) {
                ForEach(model.generations, id: \.generation) { entry in
                    let active = model.generation == entry.generation
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { model.generation = active ? nil : entry.generation }
                    } label: {
                        Text(verbatim: "\(HadithNarratorGeneration.title(entry.generation)) \(entry.count.formatted())")
                            .monospacedDigit()
                    }
                    .buttonStyle(.accentChip(filled: active))
                    .accessibilityAddTraits(active ? .isSelected : [])
                }
            }
            .padding(.top, 2)
        })
    }

    /// What the index is held to, in one row: how many narrators are shown, and the way back to all.
    private var narrowedRow: some View {
        HStack(spacing: 10) {
            if model.shown == 0 {
                let query = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
                Text(query.isEmpty ? "No narrator stands at this place in the chain." : "No narrator's name carries \u{201C}\(query)\u{201D}.")
                    .foregroundStyle(.secondary)
            } else {
                Text(String(localized: "Showing \(model.shown) of \(model.profiles.count)"))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) { model.reset() }
            } label: {
                Text("Show All")
            }
            .buttonStyle(.accentChip)
        }
        .font(.subheadline)
    }

    /// One narrator, in the catalog rows' family (a chapter's row): his English name and his count
    /// on the first line, his name as the shelf writes it and where he stands on the second. A
    /// Button through the List's one push door, as every list of these pages.
    private func row(_ profile: HadithNarratorProfile) -> some View {
        Button {
            settings.hapticFeedback()
            pushedNarrator = profile.id
        } label: {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(profile.english.isEmpty ? profile.name : profile.english)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer(minLength: 8)

                        // Grouped digits: Abu Hurairah's 6,922 read "6922" in the pill's own format.
                        let count = model.count(profile, at: model.place)
                        CountPill(count: count, countText: count.formatted())
                    }

                    HStack(alignment: .firstTextBaseline) {
                        if !profile.english.isEmpty {
                            Text(profile.name)
                                .font(appearance.islamArabicFont(base: 17, relativeTo: .footnote))
                                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }

                        Spacer(minLength: 8)

                        // Where he stands, when the sections do not already say it.
                        let generation = model.grouping == .none ? HadithNarratorGeneration.label(profile.generation) : ""
                        let line = [generation, String(localized: "\(profile.books.count) books")].filter { !$0.isEmpty }.joined(separator: " · ")
                        Text(line)
                            .font(.caption2)
                            .foregroundColor(.secondaryOnGlass)
                            .monospacedDigit()
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                }

                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// What shapes the index, as the menu at the search field's far side.
    private var optionsMenu: some View {
        Menu {
            Section("Place in the Chain") {
                Picker("Place in the Chain", selection: Binding(get: { model.place }, set: { pick in
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { model.place = pick }
                })) {
                    ForEach(Place.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
            }
            Section("Sort By") {
                Picker("Sort By", selection: Binding(get: { model.sort }, set: { pick in
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { model.sort = pick }
                })) {
                    ForEach(HadithNarratorsIndexModel.Sort.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
            }
            Section("Group") {
                Picker("Group", selection: Binding(get: { model.grouping }, set: { pick in
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { model.grouping = pick }
                })) {
                    ForEach(HadithNarratorsIndexModel.Grouping.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
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
            Image(systemName: model.place != .all || model.generation != nil
                  ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(appearance.accent)
                .frame(width: 26, height: 26)
                .frame(width: 50, height: 50)
                .contentShape(Rectangle())
                .conditionalGlassEffect()
        }
        .fixedMenuOrder()
        .accessibilityLabel("Narrator list options")
    }
}

/// The door to the index, on the Hadith tab under the books (TabSections.swift): the count and what
/// the page holds, pushed through the tab's one destination.
struct HadithNarratorsDoor: View {
    @Environment(\.appearance) private var appearance
    private let settings = Settings.shared

    let open: () -> Void

    @State private var count: Int?

    var body: some View {
        Button {
            settings.hapticFeedback()
            open()
        } label: {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Narrators of the Hadith")
                            .foregroundColor(.primary)
                        Text(count.map { String(localized: "\($0) narrators, from the Companions to the compilers' teachers") }
                             ?? String(localized: "From the Companions to the compilers' teachers"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "person.text.rectangle.fill")
                        .foregroundColor(appearance.accent)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The pack opens off the main thread; the row reads before the count arrives. The same
        // task reads every profile once, so the index behind this door opens whole on its first
        // frame (`HadithNarratorStore.allProfiles` keeps them).
        .task {
            let found = await Task.detached(priority: .utility) { () -> Int in
                let count = HadithNarratorStore.shared.narratorCount
                _ = HadithNarratorStore.shared.allProfiles()
                return count
            }.value
            if found > 0 { count = found }
        }
    }
}

// MARK: - The same chain

/// What the same-chain page shows, read as the page is made: the other narrations its chain
/// carries, and the tree of every chain of this narration when the pack built one.
@MainActor
final class HadithSameChainPage: ObservableObject {
    let list: HadithListModel
    let tree: HadithIsnadTreesPack.Summary?

    init(group: Int, slug: String, idInBook: Int) {
        let members = HadithNarratorStore.shared.members(group: group).filter { $0.slug != slug || $0.idInBook != idInBook }
        list = HadithListModel(requests: members.map { HadithListEntry.Request(slug: $0.slug, idInBook: $0.idInBook) })
        tree = HadithIsnadTreeStore.shared.summary(slug: slug, idInBook: idInBook)
    }
}

/// The narrations carried by exactly one chain of narrators, the one of the narration this page was
/// opened from left out.
struct HadithSameChainView: View {
    let group: Int
    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    @StateObject private var page: HadithSameChainPage
    @State private var pushTree = false

    init(group: Int, book: HadithCatalogBook, hadith: HadithBookData.Hadith) {
        self.group = group
        self.book = book
        self.hadith = hadith
        _page = StateObject(wrappedValue: HadithSameChainPage(group: group, slug: book.slug, idInBook: hadith.idInBook))
    }

    var body: some View {
        HadithResolvedList(
            model: page.list,
            emptyText: String(localized: "No other narration is carried by this chain."),
            footnote: String(localized: "Found ahead of time: narrations whose chain names the same narrators, generation by generation, as this one's, among the chains the app can read.")
        ) {
            Section {
                Text(String(localized: "Narrated through the same chain as \(book.displayReference(hadith.displayNumber)), narrator for narrator."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let tree = page.tree {
                    HadithIsnadTreeDoor(summary: tree) { pushTree = true }
                }
            }
        }
        .pushDestination(isPresented: $pushTree) {
            if let tree = page.tree {
                HadithIsnadTreeView(book: book, hadith: hadith, summary: tree)
            }
        }
        .navigationTitle(String(localized: "Same Chain"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
