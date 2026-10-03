#if os(iOS)
import SwiftUI

/// The Prophecies of the Prophet (peace and blessings be upon him): things he foretold, and what
/// history did with them.
///
/// EVERY narration here was resolved to a row in the app's OWN hadith packs and is quoted from there
/// by token range, never retyped from a website. The articles are data (PropheciesContent.swift),
/// and `Scripts/verify_prophecies.py` reads every quote back out of the packs: sahih or hasan by the
/// weight of the graders, ranges inside the row, no em dashes. `Scripts/prophecy_ranges.py` finds a
/// phrase's token range. A claim the shelf cannot carry soundly does not ship.
///
/// The sources that suggested the list (islamreligion.com, Yaqeen Institute's "The Prophecies of
/// Prophet Muhammad" by Sh. Mohammad Elshinawy, and Proving Islam's "101 Fulfilled Prophecies") gave
/// permission to draw on them (Abu, 2026-09-19). The first version shipped 8 of the 43 the old
/// verifier had checked; Abu, 2026-09-25: "there's barely any in there! the real source had way
/// more". The wording is this app's own; the hadith text is the shelf's.
struct PropheciesView: View {
    @ObservedObject private var settings = Settings.shared

    @State private var searchText = ""
    @State private var openDoor: SignsAboutDoor?
    @State private var barsCollapsed = false
    #if DEBUG
    @State private var debugOpenArticle = false
    private var debugEntry: Entry? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-prophecy"), args.indices.contains(i + 1) else { return nil }
        return Self.entries.first { $0.id == args[i + 1] }
    }
    #endif

    /// One prophecy, as the index lists it.
    struct Entry: Identifiable {
        let id: String
        let title: String
        /// What a row shows under the title: the claim in one line.
        let summary: String
        let group: Group
        /// Spellings a searcher will type that the title and summary do not carry.
        var aliases: [String] = []
        /// The article itself, rendered by `SignArticleSections`.
        let sections: [SignSection]

        /// Title, summary, group, aliases and the article's own prose, folded for the index's search.
        /// Built once per entry by `searchIndex`, never per keystroke.
        var searchKey: String {
            let prose = sections.flatMap(\.blocks).compactMap { block -> String? in
                if case .text(let text) = block { return text }
                return nil
            }
            return IslamArticles.fold(([title, summary, group.rawValue] + aliases + prose).joined(separator: " "))
        }

        enum Group: String, CaseIterable, Identifiable {
            case quran = "Foretold in the Quran"
            case empires = "Empires and conquests"
            case companions = "The Companions and his household"
            case ummah = "The ummah after him"
            case endTimes = "Signs before the Hour"

            var id: String { rawValue }
            var systemImage: String {
                switch self {
                case .quran:      return "book"
                case .empires:    return "crown"
                case .companions: return "person.2"
                case .ummah:      return "building.columns"
                case .endTimes:   return "hourglass"
                }
            }
        }
    }

    // The articles themselves are in PropheciesContent.swift: `entries` and `strongestIDs`.

    /// Every entry with its folded search key, built once.
    private static let searchIndex: [(entry: Entry, key: String)] = entries.map { ($0, $0.searchKey) }

    private var grouped: [(Entry.Group, [Entry])] {
        Entry.Group.allCases.compactMap { group in
            let rows = Self.entries.filter { $0.group == group }
            return rows.isEmpty ? nil : (group, rows)
        }
    }

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Every term has to hit, the same rule the Miracles of the Quran index searches by.
    private var results: [Entry] {
        let terms = IslamArticles.fold(query).split(separator: " ").map(String.init)
        guard !terms.isEmpty else { return [] }
        let matched = Self.searchIndex.filter { item in terms.allSatisfy { item.key.contains($0) } }.map(\.entry)
        return SearchRank.sorted(matched, by: query) { [$0.title] + $0.aliases }
    }

    /// `strongestIDs`, in that order, skipping any id no entry carries.
    private static let strongest: [Entry] = strongestIDs.compactMap { id in entries.first { $0.id == id } }

    @ViewBuilder
    private func row(_ entry: Entry) -> some View {
        NavigationLink(destination: LazyDestination { ProphecyArticleView(entry: entry) }) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(entry.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
        List {
            Group {
                if query.isEmpty {
                    ResourceHeroSection(ResourceHero(
                        eyebrow: "FORETOLD, AND FULFILLED",
                        systemImage: "checkmark.seal.fill",
                        headline: "Nor does he speak from [his own] inclination. It is not but a revelation revealed.",
                        source: "Quran 53:3\u{2013}4",
                        message: "He foretold things no one could have known, and he said them in front of people who wrote them down and lived to see them happen. This library gathers \(Self.entries.count) of them, each with what the Quran or the narration says and what history did with it. Every hadith is quoted from this app's own collections and is sahih or hasan; anything our copies grade weak was left out.",
                        stats: [
                            ResourceHeroStat("\(Self.entries.count)", "prophecies"),
                            ResourceHeroStat("\(grouped.count)", "groups"),
                            ResourceHeroStat("\(Self.strongest.count)", "strongest"),
                        ]
                    ))

                    StrongestSection(
                        items: Self.strongest,
                        footer: "Where the words were most specific, could most easily have failed, and were checked by people who wanted them to fail. The app's own pick, not the sources'."
                    ) { row($0) }

                    ForEach(grouped, id: \.0.id) { group, rows in
                        Section(header: SectionPillHeader(title: group.rawValue.uppercased(), count: rows.count,
                                                          icon: group.systemImage)) {
                            ForEach(rows) { row($0) }
                        }
                    }

                    // Proving Islam's two chapters on prophecy (2026-10-02): the case it makes from what he
                    // foretold, and what was foretold OF him, which this library does not carry.
                    Section(
                        header: SectionPillHeader(title: "FROM PROVING ISLAM", count: 2, icon: "checkmark.shield"),
                        footer: Text("The case from prophecy, weighed by what makes a prediction count, and the passages of the Bible that Muslim scholars read as foretelling him.")
                    ) {
                        ArticleDoorRow(door: .article("ProvingProphecyView"))
                        ArticleDoorRow(door: .article("ProvingBibleView"))
                    }

                    AboutSignsSection(heading: "About Prophecy & Prophethood",
                                      systemImage: "checkmark.seal",
                                      doors: [.prophet, .sunnah, .hadith, .provingIslam],
                                      openDoor: $openDoor)

                    Section(footer: Text("Suggested by islamreligion.com, Yaqeen Institute (Sh. Mohammad Elshinawy, \u{201C}The Prophecies of Prophet Muhammad\u{201D}) and Proving Islam, with their permission. The narrations themselves are quoted from the collections bundled in this app.")) {
                        EmptyView()
                    }
                } else {
                    let matches = results
                    if matches.isEmpty {
                        Section {
                            Text("No prophecies match \"\(query)\". Try an empire, a Companion, or a place.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section(header: SectionPillHeader(title: "PROPHECIES", count: matches.count)) {
                            ForEach(matches) { row($0) }
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        // NO `article:` here: that adds the per-page "Search this article" bar, and this screen
        // is an INDEX with its own library search below - two stacked search bars.
        .selectableArticleList()
        .aboutSignsDestination($openDoor)
        #if DEBUG
        // `-prophecy <id>`: push that article on appear - a tap cannot be driven headlessly.
        .debugPushDestination(isPresented: $debugOpenArticle) {
            if let debugEntry { ProphecyArticleView(entry: debugEntry) }
        }
        .onAppear {
            guard debugEntry != nil, !debugOpenArticle else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenArticle = true }
        }
        #endif
        .navigationTitle("Prophecies of the Prophet")
        .navigationBarTitleDisplayMode(.inline)
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                      placeholder: "Search prophecies")
                .minimizedBarStyle(barsCollapsed)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
        }
        #if DEBUG
        // `-scrollToAbout`: the About card sits under the whole index, unreachable headlessly.
        .onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-scrollToAbout") else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation { proxy.scrollTo("aboutSigns", anchor: .center) }
            }
        }
        #endif
        }
    }
}

/// One prophecy: what was said, the narration itself, and what happened.
struct ProphecyArticleView: View {
    let entry: PropheciesView.Entry

    var body: some View {
        List {
            Group {
                SignArticleSections(sections: entry.sections, lead: entry.summary)
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "Prophecy-\(entry.id)")
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
