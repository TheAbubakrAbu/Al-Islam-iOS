#if os(iOS)
import SwiftUI

/// Sunnahs of the Prophet (peace and blessings be upon him): what he did each day, from waking to
/// sleeping, each with the narration it rests on and how to keep it.
///
/// Built 2026-10-26 (Abu: "add common sunnahs as an Islamic resource"). The fourth data-backed
/// library after the prophecies and the two miracles libraries, and it reads the same way: the
/// articles are data (SunnahContent.swift, `SignSection` / `SignBlock`), EVERY narration is a
/// reference into the app's own hadith shelf quoted by token range, never retyped, and
/// `Scripts/verify_prophecies.py` reads every quote back out of the packs: sahih or hasan by the
/// weight of the graders, ranges inside the row, no em dashes. A sunnah the shelf cannot carry
/// soundly does not ship.
///
/// The list follows what the scholars of the Sunnah count as his daily practice (Khalid
/// al-Husainan's "More than a Thousand Sunnahs in Every Day and Night", and the rulings of IslamQA,
/// Ibn Baz and Ibn 'Uthaymin); the wording is this app's own and the hadith text is the shelf's.
/// The index runs through the day: waking, purification, dress and home, prayer, eating, company,
/// the remembrances that belong to no hour, the week, the occasions (travel, Eid, family) and the
/// night, so a reader can follow it from one end to the other.
struct SunnahView: View {
    private let settings = Settings.shared
    @State private var searchText = ""
    @State private var openDoor: SignsAboutDoor?
    @State private var barsCollapsed = false
    #if DEBUG
    @State private var debugOpenArticle = false
    private var debugEntry: Entry? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-sunnah"), args.indices.contains(i + 1) else { return nil }
        return Self.entries.first { $0.id == args[i + 1] }
    }
    #endif

    /// One sunnah, as the index lists it.
    struct Entry: Identifiable {
        let id: String
        let title: String
        /// What a row shows under the title: the practice in one line.
        let summary: String
        let group: Group
        /// Spellings a searcher will type that the title and summary do not carry.
        var aliases: [String] = []
        /// The article itself, rendered by `SignArticleSections`: WHAT HE DID (the narration),
        /// HOW TO KEEP IT (the steps, on the rail), WHY IT MATTERS and A NOTE (cards).
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

        /// The day's order, which is the index's order.
        enum Group: String, CaseIterable, Identifiable {
            case waking = "On waking"
            case purification = "Wudu and cleanliness"
            case home = "Dress, home and going out"
            case prayer = "Prayer and the masjid"
            case food = "Eating and drinking"
            case company = "Speech and company"
            /// The remembrances and responses that belong to no fixed hour (2026-10-26): the hundred
            /// tahlil, the words on anger, rain, a calamity, the market.
            case day = "Through the day"
            case week = "Fasting, charity and Friday"
            /// The sunnahs of a journey, the two Eids, a wedding, a birth and a death (2026-10-26).
            case occasions = "Travel, Eid and family"
            case night = "Evening and sleep"

            var id: String { rawValue }
            var systemImage: String {
                switch self {
                case .waking:       return "sunrise"
                case .purification: return "drop"
                case .home:         return "house"
                case .prayer:       return "moon.stars"
                case .food:         return "fork.knife"
                case .company:      return "bubble.left.and.bubble.right"
                case .day:          return "sun.max"
                case .week:         return "calendar"
                case .occasions:    return "suitcase"
                case .night:        return "moon.zzz"
                }
            }
        }
    }

    // The articles themselves are in SunnahContent.swift: `entries` and `emphasisedIDs`.

    /// Every entry with its folded search key, built once.
    private static let searchIndex: [(entry: Entry, key: String)] = entries.map { ($0, $0.searchKey) }

    /// `emphasisedIDs`, in that order, skipping any id no entry carries.
    private static let emphasised: [Entry] = emphasisedIDs.compactMap { id in entries.first { $0.id == id } }

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Every term has to hit, the same rule the other libraries' indexes search by.
    private var results: [Entry] {
        let terms = IslamArticles.fold(query).split(separator: " ").map(String.init)
        guard !terms.isEmpty else { return [] }
        let matched = Self.searchIndex.filter { item in terms.allSatisfy { item.key.contains($0) } }.map(\.entry)
        return SearchRank.sorted(matched, by: query) { [$0.title] + $0.aliases }
    }

    private var grouped: [(Entry.Group, [Entry])] {
        Entry.Group.allCases.compactMap { group in
            let rows = Self.entries.filter { $0.group == group }
            return rows.isEmpty ? nil : (group, rows)
        }
    }

    @ViewBuilder
    private func row(_ entry: Entry) -> some View {
        NavigationLink(destination: LazyDestination { SunnahArticleView(entry: entry) }) {
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
                    ResourceHeroSection(ResourceHero(
                        eyebrow: "HIS DAILY PATTERN",
                        systemImage: "sun.horizon.fill",
                        headline: "There has certainly been for you in the Messenger of Allah an excellent pattern for anyone whose hope is in Allah and the Last Day and [who] remembers Allah often.",
                        source: "Quran 33:21",
                        message: "A sunnah is something he did, said or approved, and most of his daily ones cost nothing: a few words on waking, the right hand at a meal, two rak'ahs before Fajr, the siwak. This library gathers \(Self.entries.count) of them in the order of a day, each with the narration it rests on and how to keep it. Every hadith is quoted from this app's own collections and is sahih or hasan; where the graders differ, the citation names the grader followed.",
                        stats: [
                            ResourceHeroStat("\(Self.entries.count)", "sunnahs"),
                            ResourceHeroStat("\(grouped.count)", "groups"),
                            ResourceHeroStat("\(Self.emphasised.count)", "emphasised"),
                        ]
                    ))

                    StrongestSection(
                        title: "MOST EMPHASISED",
                        icon: "star.fill",
                        items: Self.emphasised,
                        footer: "The sunnahs he kept to most closely and urged most, as the scholars count them: the regular prayers around the obligatory ones, Witr, the siwak, the words said on lying down and on waking. The app's own pick."
                    ) { row($0) }

                    ForEach(grouped, id: \.0.id) { group, rows in
                        Section(header: SectionPillHeader(title: group.rawValue.uppercased(), count: rows.count,
                                                          icon: group.systemImage)) {
                            ForEach(rows) { row($0) }
                        }
                    }

                    AboutSignsSection(heading: "About the Sunnah",
                                      systemImage: "sun.horizon",
                                      doors: [.sunnah, .hadith, .prophet, .islam],
                                      openDoor: $openDoor)

                    Section(footer: Text("The list follows what the scholars of the Sunnah count as his daily practice: Khalid al-Husainan\u{2019}s \u{201C}More than a Thousand Sunnahs in Every Day and Night\u{201D} and the rulings of IslamQA, Ibn Baz and Ibn \u{2018}Uthaymin. The wording is this app\u{2019}s own, and every narration is quoted from the hadith collections bundled in it, sahih or hasan only.")) {
                        EmptyView()
                    }
                } else {
                    let matches = results
                    if matches.isEmpty {
                        Section {
                            Text("No sunnahs match \"\(query)\". Try a time of day, or an action.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section(header: SectionPillHeader(title: "SUNNAHS", count: matches.count)) {
                            ForEach(matches) { row($0) }
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        // NO `article:` here: that adds the per-page "Search this article" bar, and this screen
        // is an INDEX with its own library search below - two stacked search bars.
        .englishArticle().selectableArticleList()
        .aboutSignsDestination($openDoor)
        #if DEBUG
        // `-sunnah <id>`: push that article on appear - a tap cannot be driven headlessly.
        .debugPushDestination(isPresented: $debugOpenArticle) {
            if let debugEntry { SunnahArticleView(entry: debugEntry) }
        }
        .onAppear {
            guard debugEntry != nil, !debugOpenArticle else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenArticle = true }
        }
        #endif
        .navigationTitle("Sunnahs of the Prophet")
        .navigationBarTitleDisplayMode(.inline)
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                      placeholder: "Search sunnahs")
                .minimizedBarStyle(barsCollapsed)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
        }
    }
}

struct SunnahArticleView: View {
    let entry: SunnahView.Entry
    /// The page's sections as its search bar scans them: the corpus has no row for a generated page.
    /// Folded once here, not per body pass.
    private let searchArticle: IslamArticle

    init(entry: SunnahView.Entry) {
        self.entry = entry
        searchArticle = .generated(id: "Sunnah-\(entry.id)", title: entry.title, sections: entry.sections)
    }

    var body: some View {
        List {
            Group {
                SignArticleSections(sections: entry.sections, lead: entry.summary)
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: searchArticle.id, fallback: searchArticle)
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
