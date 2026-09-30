#if os(iOS)
import SwiftUI

/// Miracles of the Prophets: why prophets are given signs at all, the signs given to the prophets
/// before him, and then his own.
///
/// The order is the argument (Abu, 2026-09-19: "use this for both a precursor and for Prophet
/// Muhammad, as it proves why Prophet Muhammad could have miracles then shows his miracles").
/// Someone who accepts that Musa's staff became a serpent and that 'Isa raised the dead has already
/// accepted the category; the question is then only whether this man was given the same.
///
/// The earlier prophets' signs are Quranic and are quoted from the app's own text. The Prophet's own
/// are hadith, every one resolved to a row in our packs and read from there
/// (`Scripts/verify_prophecies.py` - 12 checked, 0 weak, 0 unresolved).
///
/// Each article about an earlier prophet also carries a door to that prophet's full story in Pillars
/// & Beliefs, and every one of those 25 pages carries the door back (`ProphetSignsIndex`, the one
/// table both directions read).
struct ProphetMiraclesView: View {
    @ObservedObject private var settings = Settings.shared

    @State private var searchText = ""
    @State private var openDoor: SignsAboutDoor?
    @State private var barsCollapsed = false
    #if DEBUG
    @State private var debugOpenArticle = false
    private var debugEntry: Entry? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-prophetMiracle"), args.indices.contains(i + 1) else { return nil }
        return Self.entries.first { $0.id == args[i + 1] }
    }
    #endif

    struct Entry: Identifiable {
        let id: String
        let title: String
        let summary: String
        let group: Group
        /// Spellings a searcher will type that the title and summary do not carry.
        var aliases: [String] = []
        /// The article itself, rendered by `SignArticleSections`.
        let sections: [SignSection]

        enum Group: String, CaseIterable, Identifiable {
            case why = "Why prophets are given signs"
            case before = "The prophets before him"
            case his = "His greatest signs"
            case provision = "Food and water multiplied"
            case creation = "Creation answered him"
            case prayers = "Prayers answered"
            case protection = "Healing and protection"

            var id: String { rawValue }
            var systemImage: String {
                switch self {
                case .why:        return "questionmark.circle"
                case .before:     return "person.3"
                case .his:        return "sparkles"
                case .provision:  return "drop"
                case .creation:   return "leaf"
                case .prayers:    return "hands.sparkles"
                case .protection: return "shield"
                }
            }
        }

        /// Title, summary, aliases and the article's own prose, folded for the index's search.
        /// Built once per entry by `searchIndex`, never per keystroke.
        var searchKey: String {
            let prose = sections.flatMap(\.blocks).compactMap { block -> String? in
                if case .text(let text) = block { return text }
                return nil
            }
            return IslamArticles.fold(([title, summary, group.rawValue] + aliases + prose).joined(separator: " "))
        }
    }

    // The articles themselves are in ProphetMiraclesContent.swift: `entries` and `strongestIDs`.

    /// Every entry with its folded search key, built once.
    private static let searchIndex: [(entry: Entry, key: String)] = entries.map { ($0, $0.searchKey) }

    /// `strongestIDs`, in that order, skipping any id no entry carries.
    private static let strongest: [Entry] = strongestIDs.compactMap { id in entries.first { $0.id == id } }

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Every term has to hit, the same rule the Miracles of the Quran index searches by.
    private var results: [Entry] {
        let terms = IslamArticles.fold(query).split(separator: " ").map(String.init)
        guard !terms.isEmpty else { return [] }
        return Self.searchIndex.filter { item in terms.allSatisfy { item.key.contains($0) } }.map(\.entry)
    }

    private var grouped: [(Entry.Group, [Entry])] {
        Entry.Group.allCases.compactMap { group in
            let rows = Self.entries.filter { $0.group == group }
            return rows.isEmpty ? nil : (group, rows)
        }
    }

    @ViewBuilder
    private func row(_ entry: Entry) -> some View {
        NavigationLink(destination: LazyDestination { ProphetMiracleArticleView(entry: entry) }) {
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
        List {
            Group {
                if query.isEmpty {
                    Section {
                        Text(verbatim: "Every prophet was given something his people could not explain away, and it was always chosen to speak to them: sorcery in Egypt, medicine among the people of 'Isa, language among the Arabs. Read in that order, the signs given to Muhammad (peace and blessings be upon him) are not an odd claim to assess on their own. They are the last entry in a pattern Muslims, Jews and Christians already accept, and most of them were seen by crowds and reported by named witnesses.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    StrongestSection(
                        items: Self.strongest,
                        footer: "The signs with the most witnesses and the plainest reports: seen by a crowd or an army, narrated by several Companions, and put in front of people who wanted them to be false. The app's own pick, not the sources'."
                    ) { row($0) }

                    ForEach(grouped, id: \.0.id) { group, rows in
                        Section(header: SectionPillHeader(title: group.rawValue.uppercased(), count: rows.count,
                                                          icon: group.systemImage)) {
                            ForEach(rows) { row($0) }
                        }
                    }

                    AboutSignsSection(heading: "About Miracles & Prophethood",
                                      systemImage: "staroflife",
                                      doors: [.prophets, .prophet, .god, .provingIslam],
                                      openDoor: $openDoor)

                    Section(footer: Text("Suggested by Yaqeen Institute (\u{201C}The Physical Miracles of Prophet Muhammad\u{201D}), islammessage.org and mysalahmat.com, with their permission. The verses and narrations are quoted from the Quran and hadith collections bundled in this app.")) {
                        EmptyView()
                    }
                } else {
                    let matches = results
                    if matches.isEmpty {
                        Section {
                            Text("No articles match \"\(query)\". Try a prophet's name, or a sign.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section(header: SectionPillHeader(title: "ARTICLES", count: matches.count)) {
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
        // `-prophetMiracle <id>`: push that article on appear - a tap cannot be driven headlessly.
        .debugPushDestination(isPresented: $debugOpenArticle) {
            if let debugEntry { ProphetMiracleArticleView(entry: debugEntry) }
        }
        .onAppear {
            guard debugEntry != nil, !debugOpenArticle else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenArticle = true }
        }
        #endif
        .navigationTitle("Miracles of the Prophets")
        .navigationBarTitleDisplayMode(.inline)
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                      placeholder: "Search miracles")
                .minimizedBarStyle(barsCollapsed)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
        }
    }
}

struct ProphetMiracleArticleView: View {
    @ObservedObject private var settings = Settings.shared

    let entry: ProphetMiraclesView.Entry

    /// The door to a prophet's full story. One `@State` + one destination on the List: the stories
    /// section is a single List row, and two NavigationLinks in one row both fire on any tap.
    @State private var openStory: ProphetSigns?

    private var prophets: [ProphetSigns] { ProphetSignsIndex.forEntry(entry.id) }

    var body: some View {
        ScrollViewReader { proxy in
        List {
            Group {
                SignArticleSections(sections: entry.sections, lead: entry.summary)

                storiesSection
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetMiracle-\(entry.id)")
        .pushDestination(isPresented: Binding(
            get: { openStory != nil },
            set: { if !$0 { openStory = nil } }
        )) {
            if let openStory { openStory.storyDestination }
        }
        #if DEBUG
        // `-prophetMiracleScrollToStories`: the stories section sits under the whole article, and
        // there is no scroll tooling in the simulator (MiraclesView's own siblings hook's rule).
        .onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-prophetMiracleScrollToStories") else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { proxy.scrollTo("stories", anchor: .center) }
            }
        }
        #endif
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// "Read their stories": the same prophets' full pages in Pillars & Beliefs. A sign means more
    /// once you know the man it was given to and what his people did with it (Abu, 2026-09-19).
    @ViewBuilder
    private var storiesSection: some View {
        if !prophets.isEmpty {
            Section(header: ArticleHeader(prophets.count == 1 ? "HIS STORY" : "THEIR STORIES"),
                    footer: Text("The full account of each, from the Quran's own telling, in Pillars & Beliefs.")) {
                ForEach(prophets) { prophet in
                    Button {
                        settings.hapticFeedback()
                        openStory = prophet
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(prophet.name)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text(prophet.signs)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 8)

                            Text(prophet.arabic)
                                .font(.body)
                                .foregroundColor(settings.accentColor.color)

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .id(prophet.id == prophets.first?.id ? "stories" : prophet.id)
                }
            }
        }
    }
}
#endif
