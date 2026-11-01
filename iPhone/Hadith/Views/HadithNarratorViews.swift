#if os(iOS)
import SwiftUI

// A narrator's page and the narrations carried by one chain (HadithNarrators.swift), reached from a
// chain of narrators (Abu, 2026-10-27: "click on each person in the chain and see where else they
// are mentioned and see how many they are in, how many sahih, daif, etc and how many Hadiths they
// narrated and show all of them"; "all chains that are the exact same"). Both pages read what the
// pack shipped and list the rows through `HadithResolvedList`, so they sort, group, narrow, bookmark
// and open in the book like the similar narrations do.

/// One narrator: his name as the shelf most often writes it, his counts, then every narration naming him.
struct HadithNarratorView: View {
    @Environment(\.appearance) private var appearance

    let narratorID: Int

    @State private var profile: HadithNarratorProfile?
    @State private var entries: [HadithListEntry]?
    @State private var missing = false

    var body: some View {
        Group {
            if let profile, let entries {
                HadithResolvedList(
                    entries: entries,
                    emptyText: String(localized: "No narration naming this narrator could be read."),
                    footnote: String(localized: "Counted ahead of time from the chains the app can read, about two thirds of the narrations in the eleven books that carry them. A narrator is matched by his name as each narration writes it; the written forms of one man are joined only where a title, a case ending, a shorter form of his name under his own student, or a nisba tells them apart and nothing else does, and each joined form is listed above with its count. A name that could be two men is left apart. A grade is the strongest word of each grader's verdict; Sahih al-Bukhari and Sahih Muslim carry no grade line and count as sahih, as the collections are.")
                ) {
                    header(profile)
                }
            } else if missing {
                Text("This narrator's page could not be opened.")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(profile?.name ?? String(localized: "Narrator"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    /// The name (and its English), where he stands in the chains, the three counts, the grades, and
    /// the other ways the shelf writes him: what the page says before its list.
    @ViewBuilder
    private func header(_ profile: HadithNarratorProfile) -> some View {
        Section {
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(profile.name)
                        .font(appearance.islamArabicFont(base: 28, relativeTo: .title))
                        .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                        .multilineTextAlignment(.center)
                    if !profile.english.isEmpty {
                        Text(profile.english)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    if profile.generation > 0 {
                        Text(HadithNarratorGeneration.title(profile.generation))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(appearance.accent)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(appearance.accent.opacity(0.12)))
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    stat(profile.narrations, String(localized: "Narrations"))
                    stat(profile.fromProphet, String(localized: "From the Prophet ﷺ"))
                    stat(profile.teacher, String(localized: "Taught the compiler"))
                }

                let grades = HadithGradeCategory.allCases.filter { profile.count($0) > 0 }
                if !grades.isEmpty {
                    HadithChipRows(items: grades.map { ($0.title, profile.count($0)) })
                }

                Text(String(localized: "\(profile.books.count) books"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }

        if !profile.forms.isEmpty {
            // The written forms joined into this page (Abu, 2026-10-31: "Aisha has 58?? ... make sure to
            // normalize"): each with how many narrations write him so, so the join is in plain sight.
            Section {
                HadithChipRows(items: profile.forms.map { ($0.name, $0.count) }, arabic: true)
                    .padding(.vertical, 2)
            } header: {
                Text("Also Written As")
            } footer: {
                Text("Joined to this page by the shelf's own writing: a title set aside, the alef of the accusative, a shorter form of the name that only this narrator carries at that place in the chain or under that student, or a nisba dropped. The chain of each narration still shows the name as it writes it.")
            }
        }
    }

    private func stat(_ count: Int, _ title: String) -> some View {
        VStack(spacing: 3) {
            Text(count.formatted())
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundColor(appearance.accent)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(appearance.accent.opacity(0.08)))
    }

    /// The profile and its list, read off the main thread: a binary search each, then the rows
    /// resolved from their books.
    private func load() async {
        let id = narratorID
        let (profile, refs) = await Task.detached(priority: .userInitiated) {
            (HadithNarratorStore.shared.profile(id: id), HadithNarratorStore.shared.refs(id: id))
        }.value
        guard let profile else {
            missing = true
            return
        }
        self.profile = profile
        let requests = refs.map { ref -> HadithListEntry.Request in
            let role: String?
            switch ref.role {
            case .top: role = String(localized: "From the Prophet ﷺ")
            case .teacher: role = String(localized: "Taught the compiler")
            case .link: role = nil
            }
            return HadithListEntry.Request(slug: ref.slug, idInBook: ref.idInBook, secondaryBadge: role)
        }
        entries = await HadithListEntry.resolve(requests)
    }
}

/// Small labelled counts, two to a row, never lazy (a lazy grid in a List row can answer a different
/// height on each self-sizing pass).
struct HadithChipRows: View {
    @Environment(\.appearance) private var appearance

    let items: [(title: String, count: Int)]
    /// The titles are Arabic names: set in the Islam face, a size up, right to left.
    var arabic = false

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { start in
                HStack(spacing: 6) {
                    ForEach(start..<min(start + 2, items.count), id: \.self) { index in
                        chip(items[index])
                    }
                    if start + 1 >= items.count {
                        Spacer(minLength: 0)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func chip(_ item: (title: String, count: Int)) -> some View {
        HStack(spacing: 6) {
            Text(item.count.formatted())
                .font(.footnote.monospacedDigit().weight(.semibold))
                .foregroundColor(appearance.accent)
            if arabic {
                Text(item.title)
                    .font(appearance.islamArabicFont(base: 16, relativeTo: .footnote))
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text(item.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(appearance.accent.opacity(0.1)))
    }
}

// MARK: - Every narrator

/// The index of every narrator of the shelf's chains (Abu, 2026-10-31: "a narrators section ... that
/// shows all the narrators in all the different levels (like first middle or last or all), sort by
/// sahabah, tabieen, etc"), reached from the Hadith tab's NARRATORS section: searched by name in
/// either script, narrowed to where a narrator stands in the chain, grouped by generation, sorted by
/// how much he narrates or by name. Everything here was counted ahead of time (HadithNarrators.qpk);
/// the page reads the profiles once, off the main thread, and filters a list of seven thousand.
struct HadithNarratorsIndexView: View {
    @Environment(\.appearance) private var appearance
    private let settings = Settings.shared

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

        func includes(_ profile: HadithNarratorProfile) -> Bool {
            switch self {
            case .all: return true
            case .first: return profile.fromProphet > 0
            case .last: return profile.teacher > 0
            case .middle: return profile.narrations - profile.fromProphet - profile.teacher > 0
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

    /// Where the page lands: a generation to open on, or nothing.
    var initialPlace: Place = .all

    @State private var profiles: [HadithNarratorProfile]?
    @State private var query = ""
    @State private var place: Place = .all
    @State private var sort: Sort = .narrations
    @State private var grouping: Grouping = .generation
    @State private var pushedNarrator: Int?

    var body: some View {
        Group {
            if let profiles {
                let shown = filtered(profiles)
                let buckets = grouped(shown)
                List {
                    Group {
                        Section {
                            Text(String(localized: "\(profiles.count) narrators of the chains the app can read, from the Companions down to the compilers' own teachers, each with every narration that names him."))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        if shown.isEmpty {
                            Section {
                                Text(query.isEmpty ? "No narrator stands at this place in the chain." : "No narrator's name carries \u{201C}\(query)\u{201D}.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        ForEach(Array(buckets.enumerated()), id: \.element.id) { index, bucket in
                            Section {
                                ForEach(bucket.rows) { profile in
                                    row(profile)
                                }
                            } header: {
                                if !bucket.title.isEmpty {
                                    HStack {
                                        Text(bucket.title)
                                        Spacer()
                                        Text("\(bucket.rows.count)")
                                    }
                                }
                            } footer: {
                                if index == buckets.count - 1 {
                                    Text("A generation is a narrator's usual distance from the Prophet ﷺ across the chains that reach him, as written: the Companions narrate from him, the Successors from them. A narrator whose chains never name the Prophet ﷺ is not placed. Names are matched as the narrations write them; the written forms of one man are joined only where a title, a case ending or a shorter form of his name tells them apart and nothing else does.")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .themedListRowBackground()
                }
                .applyConditionalListStyle()
                .searchable(text: AppPerformance.shouldReduceAnimations ? $query : $query.animation(.easeInOut),
                            prompt: Text("Search narrators"))
                .toolbar {
                    ToolbarItem(placement: .primaryAction) { optionsMenu }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .pushDestination(item: $pushedNarrator) { narratorID in
            HadithNarratorView(narratorID: narratorID)
        }
        .navigationTitle(String(localized: "Narrators"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            place = initialPlace
            profiles = await Task.detached(priority: .userInitiated) { HadithNarratorStore.shared.allProfiles() }.value
        }
    }

    /// One narrator: his name in the Islam face, his English and his place under it, his count at the
    /// trailing edge. A Button through the List's one push door, as every list of these pages.
    private func row(_ profile: HadithNarratorProfile) -> some View {
        Button {
            settings.hapticFeedback()
            pushedNarrator = profile.id
        } label: {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(appearance.islamArabicFont(base: 19, relativeTo: .body))
                        .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    let generation = grouping == .none ? HadithNarratorGeneration.label(profile.generation) : ""
                    let line = [profile.english, generation].filter { !$0.isEmpty }.joined(separator: " · ")
                    if !line.isEmpty {
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Text(profile.narrations.formatted())
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundColor(appearance.accent)
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var optionsMenu: some View {
        Menu {
            Section("Place in the Chain") {
                Picker("Place in the Chain", selection: Binding(get: { place }, set: { place = $0; settings.hapticFeedback() })) {
                    ForEach(Place.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
            }
            Section("Sort By") {
                Picker("Sort By", selection: Binding(get: { sort }, set: { sort = $0; settings.hapticFeedback() })) {
                    ForEach(Sort.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
            }
            Section("Group") {
                Picker("Group", selection: Binding(get: { grouping }, set: { grouping = $0; settings.hapticFeedback() })) {
                    ForEach(Grouping.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .fixedMenuOrder()
        .tint(appearance.accent)
        .accessibilityLabel("Narrator list options")
    }

    /// The query folded as the narrator index is (`HadithIsnadEnglish.fold` for Arabic, lower-case
    /// Latin without apostrophes for English), matched against the name, its English and every other
    /// written form.
    private func filtered(_ profiles: [HadithNarratorProfile]) -> [HadithNarratorProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let byPlace = profiles.filter(place.includes)
        guard !trimmed.isEmpty else { return sorted(byPlace) }
        let arabic = trimmed.unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }
        if arabic {
            let needle = HadithIsnadEnglish.fold(trimmed)
            return sorted(byPlace.filter { profile in
                profile.key.contains(needle) || profile.forms.contains { HadithIsnadEnglish.fold($0.name).contains(needle) }
            })
        }
        let needle = Self.latinFold(trimmed)
        return sorted(byPlace.filter { Self.latinFold($0.english).contains(needle) })
    }

    /// Lower-case, the apostrophes of the hamza and 'ayn out, so "aishah" finds "A'ishah".
    static func latinFold(_ text: String) -> String {
        text.lowercased().filter { $0 != "'" && $0 != "\u{2019}" && $0 != "-" }
    }

    private func sorted(_ rows: [HadithNarratorProfile]) -> [HadithNarratorProfile] {
        switch sort {
        case .narrations: return rows.sorted { ($0.narrations, $1.id) > ($1.narrations, $0.id) }
        case .name: return rows.sorted { ($0.key, $0.id) < ($1.key, $1.id) }
        }
    }

    private func grouped(_ rows: [HadithNarratorProfile]) -> [Bucket] {
        guard grouping == .generation else { return [Bucket(id: 0, title: "", rows: rows)] }
        var byGeneration: [Int: [HadithNarratorProfile]] = [:]
        for row in rows { byGeneration[row.generation, default: []].append(row) }
        // The Companions first, then each generation down, the unplaced last.
        let order = byGeneration.keys.sorted { lhs, rhs in
            if lhs == 0 { return false }
            if rhs == 0 { return true }
            return lhs < rhs
        }
        return order.map { Bucket(id: $0, title: HadithNarratorGeneration.title($0), rows: byGeneration[$0] ?? []) }
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
        // The pack opens off the main thread; the row reads before the count arrives.
        .task {
            let found = await Task.detached(priority: .utility) { HadithNarratorStore.shared.narratorCount }.value
            if found > 0 { count = found }
        }
    }
}

/// The narrations carried by exactly one chain of narrators, the one of the narration this page was
/// opened from left out.
struct HadithSameChainView: View {
    let group: Int
    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    @State private var entries: [HadithListEntry]?
    /// The tree of every chain of this narration (HadithIsnadTreeView.swift), when the pack built one.
    @State private var tree: HadithIsnadTreesPack.Summary?
    @State private var pushTree = false

    var body: some View {
        Group {
            if let entries {
                HadithResolvedList(
                    entries: entries,
                    emptyText: String(localized: "No other narration is carried by this chain."),
                    footnote: String(localized: "Found ahead of time: narrations whose chain names the same narrators, generation by generation, as this one's, among the chains the app can read.")
                ) {
                    Section {
                        Text(String(localized: "Narrated through the same chain as \(book.displayReference(hadith.displayNumber)), narrator for narrator."))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if let tree {
                            HadithIsnadTreeDoor(summary: tree) { pushTree = true }
                        }
                    }
                }
                .pushDestination(isPresented: $pushTree) {
                    if let tree {
                        HadithIsnadTreeView(book: book, hadith: hadith, summary: tree)
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(String(localized: "Same Chain"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        let group = group
        let slug = book.slug
        let idInBook = hadith.idInBook
        let (members, summary) = await Task.detached(priority: .userInitiated) {
            (HadithNarratorStore.shared.members(group: group).filter { $0.slug != slug || $0.idInBook != idInBook },
             HadithIsnadTreeStore.shared.summary(slug: slug, idInBook: idInBook))
        }.value
        tree = summary
        entries = await HadithListEntry.resolve(members.map { HadithListEntry.Request(slug: $0.slug, idInBook: $0.idInBook) })
    }
}
#endif
