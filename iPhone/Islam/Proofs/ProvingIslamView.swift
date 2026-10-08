#if os(iOS)
import SwiftUI

/// Proving Islam: the case that Islam is true, one line of evidence at a time (Abu, 2026-09-29:
/// "incorporate Proving Islam in the app ... actually use a lot of their stuff and link them in the
/// Islam section").
///
/// Two sources, one library:
///   * provingislam.net's "The Complete Case", a long cumulative argument, becomes the seventeen
///     CHAPTERS below. They are ordinary catalog articles (`IslamArticleCatalog.provingGroups`, home
///     `.proving`), so the Islam tab's search, the Ask AI corpus and each page's own search reach them.
///     The wording is the app's own and every quote is held to its rule: ayat from the app's mushaf,
///     hadith from its shelf, sahih or hasan only. Where "The Complete Case" leans on a weak narration
///     or an overclaim, the chapter drops or qualifies it, as that document's own closing note asks.
///   * provingislam.com's proof articles (Mohammad Baqer) are almost all prophecies the app's Prophecies
///     library already carries, so each is a door to the in-app article, with the original a long press
///     away.
struct ProvingIslamView: View {
    /// An article to push on top of the index as it appears: a result on the Islam tab's root.
    var openArticle: IslamArticleOpenRequest?

    init(openArticle: IslamArticleOpenRequest? = nil) {
        self.openArticle = openArticle
    }

    @Environment(\.appearance) private var appearance

    @State private var searchText = ""
    @State private var barsCollapsed = false
    @State private var scrollTarget: String?
    @StateObject private var search = IslamArticleSearchModel()

    var body: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        ScrollViewReader { proxy in
            List {
                Group {
                    if query.isEmpty {
                        ResourceHeroSection(Self.hero)

                        chapterSections

                        ProvingIslamProofsSection()

                        librariesSection

                        goFurtherSection
                    } else {
                        AskAISearchSection(query: query)

                        IslamArticleSearchSections(
                            query: query,
                            homes: [.proving],
                            contentHits: search.contentHits,
                            isSearching: search.isSearching,
                            onScrollTo: { entry in
                                withAnimation { searchText = "" }
                                scrollTarget = entry.listID
                            }
                        )
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .autoOpenArticle(openArticle, home: .proving)
            .islamArticleIndexSearch(searchText: $searchText, barsCollapsed: $barsCollapsed,
                                     scrollTarget: scrollTarget, proxy: proxy)
        }
        .navigationTitle("Proving Islam")
        .onAppear {
            IslamArticleSearchModel.prewarm()
            #if DEBUG
            if let seeded = IslamSearchDebug.launchQuery("-provingSearch"), searchText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { searchText = seeded }
            }
            #endif
        }
        .onChange(of: searchText) { text in
            search.update(query: text, homes: [.proving])
            if !text.isEmpty { scrollTarget = nil }
        }
    }

    // MARK: Chapters

    /// The chapters, numbered straight through the groups the way "The Complete Case" numbers its
    /// sections, so "chapter 9" means the same thing wherever it is said.
    @ViewBuilder
    private var chapterSections: some View {
        let groups = IslamArticleCatalog.provingGroups
        let offsets = groups.indices.map { index in groups[..<index].reduce(0) { $0 + $1.entries.count } }
        ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
            Section(header: Text(group.title)) {
                ForEach(Array(group.entries.enumerated()), id: \.element.id) { position, entry in
                    chapterRow(entry, number: offsets[index] + position + 1)
                }
            }
        }
    }

    private func chapterRow(_ entry: IslamArticleEntry, number: Int) -> some View {
        NavigationLink(destination: LazyDestination { IslamArticleCatalog.destination(entry) }) {
            HStack(alignment: .center, spacing: 12) {
                Text(String(format: "%02d", number))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(LinearGradient(colors: [appearance.accent.opacity(0.95), appearance.accent.opacity(0.65)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .accessibilityLabel("Chapter \(number)")

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let tagline = Self.taglines[entry.id] {
                        Text(tagline)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 3)
        }
        .id(entry.listID)
        .islamArticleRowActions(title: entry.title, copyText: nil, onScrollTo: nil)
    }

    /// One line under each chapter: the question it answers.
    static let taglines: [String: String] = [
        "ProvingCaseView": "No single proof carries it; the question is what explains everything at once",
        "ProvingFingerprintView": "Every human genius left the errors of his age. Where are the Quran\u{2019}s?",
        "ProvingProphetView": "Trusted by his enemies, unmoved by wealth and power, corrected by his own revelation",
        "ProvingContinuationView": "The same call in the mouth of every prophet, and the last brick in the house",
        "ProvingStylometryView": "His own sayings and the Quran do not read like one author",
        "ProvingPreservationView": "A promise made by a persecuted few, kept for fourteen centuries",
        "ProvingIjazView": "The challenge to bring one surah like it, and the poets who went silent",
        "ProvingScienceView": "A seventh-century book that avoided the errors of the seventh century",
        "ProvingProphecyView": "Specific, public claims that could have failed, and did not",
        "ProvingSourcesView": "No Arabic Bible, and a text that corrects what it is accused of copying",
        "ProvingBibleView": "Isma\u{2019}il\u{2019}s nation, a prophet like Musa, and the servant from Kedar",
        "ProvingScriptureView": "Confirming what remained true, adjudicating where the accounts differ",
        "ProvingEthicsView": "Justice against yourself, your family, and people you hate",
        "ProvingJesusView": "What the Gospels themselves say he said about God, and about himself",
        "ProvingGodView": "Created from nothing, self-created, or created by the Uncreated?",
        "ProvingQuestionsView": "The corners any other explanation has to get out of",
        "ProvingClosingView": "Every line of evidence, and the one explanation that fits them all",
    ]

    // MARK: Hero

    /// The library's opening card: the one question the whole case asks, set large. The card every
    /// resource now opens on started here (`ResourceHero`).
    static var hero: ResourceHero<EmptyView> {
        ResourceHero(
            eyebrow: "THE COMPLETE CASE",
            systemImage: "checkmark.shield.fill",
            headline: "If the Quran and the Prophet \u{FDFA} were only human, where are the human fingerprints?",
            message: "No single proof has to carry the weight. A human author leaves errors, a fraud leaves motives, a borrowed text leaves its sources, and a fragile scripture leaves scars. These chapters look for each, and ask what one explanation accounts for all of them at once.",
            stats: [
                ResourceHeroStat("\(IslamArticleCatalog.provingGroups.reduce(0) { $0 + $1.entries.count })", "chapters"),
                ResourceHeroStat("\(IslamArticleCatalog.provingGroups.count)", "parts"),
                ResourceHeroStat("1", "question"),
            ]
        )
    }

    // MARK: The signs libraries

    /// The three libraries the chapters draw on (2026-10-02, Abu: "anything in proving islam not in
    /// the other places ... add it and vice versa"). Every prophecy and every sign of the prophets is
    /// also a door from the chapter it belongs to; Miracles of the Quran through its strongest readings,
    /// since the case keeps to what survives scrutiny.
    private var librariesSection: some View {
        Section(
            header: SectionPillHeader(title: "THE SIGNS LIBRARIES", count: 3, icon: "books.vertical"),
            footer: Text("Every prophecy and every sign of the prophets in these libraries opens from the chapter it belongs to, and the strongest readings in Miracles of the Quran from \u{201C}The Errors It Did Not Make.\u{201D}")
        ) {
            ArticleDoorRow(door: .library(.propheciesOfProphet))
            ArticleDoorRow(door: .library(.miraclesOfQuran))
            ArticleDoorRow(door: .library(.miraclesOfProphets))
        }
    }

    // MARK: Further

    private var goFurtherSection: some View {
        Section(
            header: Text("GO FURTHER"),
            footer: Text("Adapted with credit from Proving Islam: provingislam.net\u{2019}s \u{201C}The Complete Case\u{201D} and the proof articles of provingislam.com by Mohammad Baqer. The wording here is this app\u{2019}s own, and every ayah and hadith is quoted from the Quran and hadith collections bundled with it, sahih or hasan only.")
        ) {
            ArticleDoorRow(door: .link("https://provingislam.net/", title: "The Complete Case",
                                       subtitle: "provingislam.net: the full cumulative argument these chapters adapt"))
            ArticleDoorRow(door: .link("https://provingislam.com/proofs", title: "Proofs of Islam",
                                       subtitle: "provingislam.com: prophecies and historical accuracies"))
            ArticleDoorRow(door: .link("https://www.amazon.com/dp/B0DQHB6VQ9", title: "101 Fulfilled Islamic Prophecies",
                                       subtitle: "The Proving Islam book by Mohammad Baqer"))
            ArticleDoorRow(door: .link("https://twitter.com/ProofsOfIslamPI", title: "@ProofsOfIslamPI",
                                       subtitle: "Proving Islam on X"))
        }
    }
}

/// A Miracles of the Quran article by slug, or the library itself if the pack has no such article:
/// what an article's `.miracle` door opens.
struct MiracleDoorDestination: View {
    let slug: String

    var body: some View {
        if let article = MiraclesStore.shared.article(slug: slug) {
            MiracleArticleView(article: article)
        } else {
            MiraclesView()
        }
    }
}

// MARK: - provingislam.com

/// The proof articles of provingislam.com, each opening the app's own article on the same prophecy or
/// historical point; the original is in the row's menu.
struct ProvingIslamProofsSection: View {
    @Environment(\.appearance) private var appearance

    struct Proof: Identifiable {
        let id: String
        let title: String
        let summary: String
        let kind: String
        let door: ArticleDoor
    }

    static let proofs: [Proof] = [
        Proof(id: "mongols-sack-of-baghdad", title: "The Siege of Baghdad",
              summary: "A city on the Tigris, and the broad-faced people who would come to its river bank",
              kind: "Prophecy", door: .prophecy("basrah-qantura")),
        Proof(id: "the-byzantine-comeback", title: "The Byzantine Comeback",
              summary: "Surah ar-Rum names the losing empire as the winner, within a few years",
              kind: "Prophecy", door: .prophecy("byzantines")),
        Proof(id: "sassanid-destruction", title: "The Fall of the Sassanid Empire",
              summary: "Chosroes tore the letter; his empire was torn apart",
              kind: "Prophecy", door: .prophecy("chosroes-torn")),
        Proof(id: "dhulkhalasa", title: "The Return of Dhul-Khalasa",
              summary: "The idol of Daws, destroyed in his lifetime, would be worshipped again",
              kind: "Prophecy", door: .prophecy("dhul-khalasa")),
        Proof(id: "bedouins-prophecy", title: "The Bedouins and the Towers",
              summary: "Barefoot shepherds competing in tall buildings",
              kind: "Prophecy", door: .prophecy("shepherds-buildings")),
        Proof(id: "green-arabia", title: "Green Arabia",
              summary: "Arabia was meadows and rivers, and will be again",
              kind: "Prophecy", door: .prophecy("arabia-meadows")),
        Proof(id: "fire-of-hijaz", title: "The Fire of the Hijaz",
              summary: "A fire in the Hijaz that would light up the necks of camels in Busra",
              kind: "Prophecy", door: .prophecy("fire-hijaz")),
        Proof(id: "kingorpharaoh", title: "King or Pharaoh?",
              summary: "The Quran calls Yusuf\u{2019}s ruler a king and Musa\u{2019}s a Pharaoh, as history does",
              kind: "History", door: .miracle("pharaoh", title: "King or Pharaoh?")),
        Proof(id: "101-fulfilled-prophecies-1", title: "101 Fulfilled Islamic Prophecies",
              summary: "The whole collection, gathered in this app\u{2019}s Prophecies of the Prophet",
              kind: "Collection", door: .library(.propheciesOfProphet)),
    ]

    var body: some View {
        Section(
            header: SectionPillHeader(title: "FROM PROVINGISLAM.COM", count: Self.proofs.count, icon: "globe"),
            footer: Text("Each opens this app\u{2019}s own article on the same proof, with the narrations quoted from its collections. Press and hold a row to read Mohammad Baqer\u{2019}s original.")
        ) {
            ForEach(Self.proofs) { proof in
                row(proof)
            }
        }
    }

    @ViewBuilder
    private func row(_ proof: Proof) -> some View {
        let original = URL(string: "https://provingislam.com/proofs/\(proof.id)")
        NavigationLink(destination: LazyDestination { destination(proof.door) }) {
            HStack(alignment: .center, spacing: 12) {
                AccentIconChip(systemImage: icon(proof.kind), size: 29)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(proof.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(proof.kind.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundColor(appearance.accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(appearance.accent.opacity(0.14)))
                    }

                    Text(proof.summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 3)
        }
        .contextMenu {
            if let original {
                Link(destination: original) {
                    Label("Read on provingislam.com", systemImage: "safari")
                }
            }
        }
    }

    private func icon(_ kind: String) -> String {
        switch kind {
        case "History": return "building.columns"
        case "Collection": return "books.vertical"
        default: return "checkmark.seal"
        }
    }

    @MainActor
    @ViewBuilder
    private func destination(_ door: ArticleDoor) -> some View {
        switch door {
        case .prophecy(let id):
            if let entry = PropheciesView.entries.first(where: { $0.id == id }) {
                ProphecyArticleView(entry: entry)
            } else {
                PropheciesView()
            }
        case .miracle(let slug, _):
            MiracleDoorDestination(slug: slug)
        case .library:
            PropheciesView()
        default:
            PropheciesView()
        }
    }
}
#endif
